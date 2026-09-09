//===- InterStellarAnalysis.cpp - Loop Stream Analysis for InterStellar --===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
///
/// \file
/// Implements the InterStellar stream analysis pass that identifies memory
/// access patterns in loops for hardware-accelerated prefetching.
///
/// Analysis capabilities:
/// 1. Direct streams: Affine memory accesses with constant stride (e.g., A[i])
/// 2. Indirect streams: Index-based accesses (e.g., A[B[i]], A[B[C[i]]])
/// 3. Dynamic values: Runtime-determined bases and loop bounds (link variables)
/// 4. Loop nesting: Parent-child loop relationships
///
//===----------------------------------------------------------------------===//

#include "llvm/Transforms/Scalar/InterStellarAnalysis.h"
#include "llvm/ADT/Statistic.h"
#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/Analysis/LoopInfo.h"
#include "llvm/Analysis/MemoryBuiltins.h"
#include "llvm/Analysis/IVDescriptors.h"
#include "llvm/Analysis/ScalarEvolution.h"
#include "llvm/Analysis/ScalarEvolutionExpressions.h"
#include "llvm/Analysis/ValueTracking.h"
#include "llvm/Transforms/Utils/ScalarEvolutionExpander.h"
#include "llvm/IR/DataLayout.h"
#include "llvm/IR/Dominators.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Intrinsics.h"
#include "llvm/InitializePasses.h"
#include "llvm/Passes/PassBuilder.h"
#include "llvm/Support/Debug.h"
#include "llvm/Support/raw_ostream.h"
#include <functional>

#define DEBUG_TYPE "interstellar-analysis"

using namespace llvm;

STATISTIC(NumDirectStreams, "Number of direct streams identified");
STATISTIC(NumDynamicBases, "Number of dynamic base addresses detected");
STATISTIC(NumLoopsAnalyzed, "Number of loops analyzed");

namespace {

// Descriptor data structures (internal to this pass; no external users).
/// Data structure to represent a direct stream descriptor
struct DirectStreamDescriptor {
  unsigned StreamID = 0;
  unsigned LoopID = 0;
  const SCEV *BaseAddress = nullptr;
  Value *BaseAddressValue = nullptr;
  int64_t Stride = 0;
  bool IsBaseLinked = false;  // Base Linked (BL) flag
  unsigned LinkID = 0;        // ID of the Link Variable Descriptor if base is dynamic
  Instruction *MemInst = nullptr;
  DebugLoc Loc;               // Source location of the memory access
};

/// Data structure to represent an indirect stream descriptor
struct IndirectStreamDescriptor {
  unsigned StreamID = 0;
  unsigned LoopID = 0;
  unsigned BaseStreamID = 0;  // The stream that provides indices (0 if computed/random)
  const SCEV *BaseAddress = nullptr;  // Base address of the indirectly accessed array
  Value *BaseAddressValue = nullptr;  // IR Value if base is dynamic
  int64_t ElementSize = 0;    // Size of elements being accessed (in bytes)
  uint64_t StreamSize = 0;    // Total memory footprint of the target array (bytes), 0 = unknown
  bool IsBaseLinked = false;  // Base Linked (BL) flag
  unsigned LinkID = 0;  // Link Descriptor ID if base is dynamic
  Instruction *MemInst = nullptr;  // Source load/store instruction
  bool IsIndexComputed = false;  // True if index is computed (not from a stream)
  DebugLoc Loc;               // Source location of the memory access
};

/// Data structure to represent a loop descriptor
struct LoopDescriptor {
  unsigned LoopID = 0;
  unsigned ParentLoopID = 0;
  Loop *L = nullptr;
  const SCEV *StartValue = nullptr;
  const SCEV *EndValue = nullptr;
  const SCEV *StepValue = nullptr;
  Value *StartValueDynamic = nullptr;  // IR Value if start is dynamic
  Value *EndValueDynamic = nullptr;    // IR Value if end is dynamic
  bool IsStartLinked = false;          // Start Linked (SL) flag
  bool IsEndLinked = false;            // End Linked (EL) flag
  unsigned StartLinkID = 0;            // Link Descriptor ID if SL=1
  unsigned EndLinkID = 0;              // Link Descriptor ID if EL=1
  DebugLoc Loc;                        // Source location of the loop
  
  // Virtual loop metadata (for merged loops)
  bool IsVirtual = false;              // True if this is a virtual merged loop
  unsigned MergedFromInnerLoop = 0;    // Original inner loop ID (if virtual)
  unsigned MergedToOuterLoop = 0;      // Original outer loop ID (if virtual)
  SmallVector<unsigned, 2> MergedDimensions; // Link IDs of merged dimensions
};

/// Data structure to represent a link variable descriptor
struct LinkVariableDescriptor {
  unsigned LinkID = 0;
  Value *DynamicValue = nullptr;
  unsigned SizeInBytes = 0;
};

/// Strip wrapping sext/zext/trunc casts from a SCEV.
static const SCEV *stripSCEVCasts(const SCEV *S) {
  while (const SCEVCastExpr *Cast = dyn_cast<SCEVCastExpr>(S))
    S = Cast->getOperand();
  return S;
}

/// Last index operand of a GEP (the innermost subscript).
static Value *getLastGEPIndex(GetElementPtrInst *GEP) {
  Value *Index = nullptr;
  for (auto IdxIt = GEP->idx_begin(); IdxIt != GEP->idx_end(); ++IdxIt)
    Index = IdxIt->get();
  return Index;
}

/// Allocated size of a GEP's pointee element: peel one array level off the
/// source type (array parameters decay, e.g. int A[][10] -> int).
static int64_t getPointeeElementSize(GetElementPtrInst *GEP,
                                     const DataLayout &DL) {
  Type *ElementType = GEP->getSourceElementType();
  if (ArrayType *ArrTy = dyn_cast<ArrayType>(ElementType))
    ElementType = ArrTy->getElementType();
  return DL.getTypeAllocSize(ElementType);
}

/// Byte size recorded for a link variable: pointers count as 8.
static unsigned sizeInBytesForLink(Type *Ty, const DataLayout &DL) {
  return Ty->isPointerTy() ? 8u : (unsigned)DL.getTypeAllocSize(Ty);
}

/// Which loop owns this AddRec as a stream when analyzed from L: L itself,
/// an ancestor of L, or null (an inner/unrelated loop - caller rejects).
static Loop *resolveOwningLoop(const SCEVAddRecExpr *AR, Loop *L) {
  const Loop *ARLoop = AR->getLoop();
  if (ARLoop == L)
    return L;
  if (L->contains(ARLoop))
    return nullptr; // inner-loop recurrence, not this loop's stream
  for (Loop *Parent = L->getParentLoop(); Parent;
       Parent = Parent->getParentLoop())
    if (ARLoop == Parent)
      return Parent; // outer-loop stream
  return nullptr;    // unrelated loop
}

/// True if S contains an AddRec of an ancestor loop of L. Such a base varies
/// with outer-loop iterations and cannot be materialized at L's preheader;
/// the runtime base GEP serves as its link variable instead. SCEV keeps a
/// non-affine term (e.g. 400 * sext(idx_i)) as a separate AddExpr operand
/// beside the outer AddRec, so the AddExpr case must be searched too.
static bool containsOuterLoopAddRec(const SCEV *S, Loop *L) {
  S = stripSCEVCasts(S);
  if (const SCEVAddRecExpr *AR = dyn_cast<SCEVAddRecExpr>(S))
    return AR->getLoop() != L && AR->getLoop()->contains(L);
  if (const SCEVAddExpr *Add = dyn_cast<SCEVAddExpr>(S))
    for (const SCEV *Op : Add->operands())
      if (containsOuterLoopAddRec(Op, L))
        return true;
  return false;
}

/// One exit-guard comparison, normalized to "IV <pred> bound".
struct ExitBoundCandidate {
  const SCEV *BoundSCEV;
  Value *BoundIR;            // IR value of the bound operand (link source)
  ICmpInst::Predicate Pred;  // with the IV on the left
};

/// Collect the comparisons that guard L's exits, following short-circuit
/// `&&` chains. Clang lowers `for (i = 0; i < N && i < C; ++i)` into a chain
/// of compares connected by a condition PHI: each chain compare appears
/// either as an incoming value of that PHI or as the branch condition of the
/// block behind a constant-false incoming edge (the "first test failed, try
/// the next" edge of an AND chain). `||` chains enter via constant-true edges
/// and are deliberately not followed — their folds need max, not min.
/// Cycles are cut with Visited.
static void collectExitBoundCandidates(Value *Cond, ScalarEvolution &SE,
                                       const SCEV *IndVarSCEV,
                                       SmallVectorImpl<ExitBoundCandidate> &Out,
                                       SmallPtrSetImpl<BasicBlock *> &Visited) {
  auto AddCandidate = [&](ICmpInst *Cmp) {
    Value *IVSide = Cmp->getOperand(0);
    Value *BoundSide = Cmp->getOperand(1);
    ICmpInst::Predicate Pred = Cmp->getPredicate();
    if (SE.getSCEV(BoundSide) == IndVarSCEV &&
        SE.getSCEV(IVSide) != IndVarSCEV) {
      std::swap(IVSide, BoundSide);
      Pred = ICmpInst::getSwappedPredicate(Pred);
    }
    if (SE.getSCEV(IVSide) != IndVarSCEV)
      return; // neither side is the induction variable (e.g. an early break)
    Out.push_back({SE.getSCEV(BoundSide), BoundSide, Pred});
  };

  if (auto *Cmp = dyn_cast<ICmpInst>(Cond)) {
    AddCandidate(Cmp);
    return;
  }

  auto *PN = dyn_cast<PHINode>(Cond);
  if (!PN)
    return;
  for (unsigned I = 0; I < PN->getNumIncomingValues(); ++I) {
    Value *In = PN->getIncomingValue(I);
    if (auto *Cmp = dyn_cast<ICmpInst>(In)) {
      AddCandidate(Cmp);
      continue;
    }
    // Constant-false incoming: AND chain, so the compare lives in the branch
    // of the incoming block.
    auto *CI = dyn_cast<ConstantInt>(In);
    if (!CI || !CI->isZero())
      continue;
    BasicBlock *FromBB = PN->getIncomingBlock(I);
    if (!FromBB || !Visited.insert(FromBB).second)
      continue;
    if (auto *BI = dyn_cast<CondBrInst>(FromBB->getTerminator()))
      collectExitBoundCandidates(BI->getCondition(), SE, IndVarSCEV, Out,
                                 Visited);
  }
}

/// Shared per-descriptor dump; defined below. Both the analyzer's Pass-1
/// summary and the pass's final summary render through it.
void printAllDescriptors(raw_ostream &OS,
                         const SmallVectorImpl<LoopDescriptor> &Loops,
                         const SmallVectorImpl<DirectStreamDescriptor> &Streams,
                         const SmallVectorImpl<IndirectStreamDescriptor> &IndirectStreams,
                         const SmallVectorImpl<LinkVariableDescriptor> &LinkVars);

/// Core stream analyzer - identifies memory access patterns and generates
/// hardware descriptors for direct/indirect streams, loops, and link variables.
class InterStellarStreamAnalyzer {
public:
  InterStellarStreamAnalyzer(Function &F, LoopInfo &LI, ScalarEvolution &SE)
      : F(F), LI(LI), SE(SE), NextStreamID(0), NextLoopID(0), NextLinkID(0) {}

  /// Run the analysis on the function
  bool analyze();
  
  /// Print the analysis results
  void print(raw_ostream &OS) const;
  
  // Accessors for results
  const SmallVector<DirectStreamDescriptor, 8> &getDirectStreams() const {
    return DirectStreams;
  }
  
  const SmallVector<IndirectStreamDescriptor, 4> &getIndirectStreams() const {
    return IndirectStreams;
  }
  
  const SmallVector<LoopDescriptor, 4> &getLoopDescriptors() const {
    return LoopDescriptors;
  }
  
  const SmallVector<LinkVariableDescriptor, 4> &getLinkVariables() const {
    return LinkVariables;
  }

private:
  // Analysis target
  Function &F;
  LoopInfo &LI;
  ScalarEvolution &SE;
  
  // Analysis results
  SmallVector<DirectStreamDescriptor, 8> DirectStreams;
  SmallVector<IndirectStreamDescriptor, 4> IndirectStreams;
  SmallVector<LoopDescriptor, 4> LoopDescriptors;
  SmallVector<LinkVariableDescriptor, 4> LinkVariables;
  
  // Tracking maps
  DenseMap<Loop *, unsigned> LoopToIDMap;
  DenseMap<Value *, unsigned> ValueToLinkIDMap;
  DenseMap<Instruction *, unsigned> InstToStreamIDMap;
  
  // ID generators
  unsigned NextStreamID;
  unsigned NextLoopID;
  unsigned NextLinkID;
  
  // Analysis methods
  void analyzeLoop(Loop *L);
  void analyzeMemoryAccess(Instruction *I, Loop *L);
  bool tryAnalyzeDirectStream(Value *Ptr, Instruction *MemInst, Loop *L);
  bool tryAnalyzeIndirectStream(Value *Ptr, Instruction *MemInst, Loop *L);
  std::optional<unsigned> getStreamSource(Value *V, Loop *L);
  Value *traceIndexThroughLoads(Value *Index, Loop *L);
  unsigned getOrCreateLoopID(Loop *L);
  unsigned getOrCreateLinkID(Value *V, unsigned SizeInBytes);
  bool isValueDynamic(const SCEV *S);
  bool isEffectivelyLoopInvariant(const SCEV *S, Loop *L);
  Value *extractDynamicValue(const SCEV *S, Loop *L);
  int64_t getTypeSizeInBytes(Type *Ty);
  void createDirectStream(const SCEV *Base, int64_t Stride, Loop *L, 
                         Instruction *MemInst, int64_t ConstantOffset = 0,
                         Value *ExplicitBaseValue = nullptr);
};

bool InterStellarStreamAnalyzer::analyze() {
  // Process loops in post-order (innermost first)
  // This ensures we analyze the most precise loop contexts first
  SmallVector<Loop *, 8> Worklist;
  
  // Collect all loops in post-order
  for (Loop *L : LI) {
    // Use depth-first post-order traversal
    for (Loop *SubL : depth_first(L)) {
      Worklist.push_back(SubL);
    }
  }
  
  // Analyze each loop
  for (Loop *L : Worklist) {
    analyzeLoop(L);
  }
  
  return !DirectStreams.empty();
}

void InterStellarStreamAnalyzer::analyzeLoop(Loop *L) {
  LLVM_DEBUG(dbgs() << "Analyzing loop: " << *L->getHeader() << "\n");
  ++NumLoopsAnalyzed;
  
  unsigned LoopID = getOrCreateLoopID(L);
  
  // Try multiple approaches to extract loop bounds:
  // 1. getBounds() API (works for well-formed loops)
  // 2. Fallback to getInductionVariable() + manual SCEV analysis
  
  LoopDescriptor LD;  // All fields auto-initialized to defaults
  LD.LoopID = LoopID;
  LD.L = L;
  
  // Capture loop source location from loop header
  // Try multiple sources: latch terminator (back-edge), then first non-PHI instruction
  if (BasicBlock *Header = L->getHeader()) {
    // Try latch terminator first (usually has the loop condition)
    if (BasicBlock *Latch = L->getLoopLatch()) {
      if (Instruction *Term = Latch->getTerminator()) {
        LD.Loc = Term->getDebugLoc();
      }
    }
    // If no location yet, try first non-PHI instruction in header
    if (!LD.Loc) {
      for (Instruction &I : *Header) {
        if (!isa<PHINode>(I)) {
          LD.Loc = I.getDebugLoc();
          if (LD.Loc) break;
        }
      }
    }
  }
  
  // Get parent loop ID if it exists
  Loop *ParentLoop = L->getParentLoop();
  if (ParentLoop) {
    LD.ParentLoopID = getOrCreateLoopID(ParentLoop);
    LLVM_DEBUG(dbgs() << "  Loop is nested in parent Loop ID: " << LD.ParentLoopID << "\n");
  }
  
  bool FoundBounds = false;
  
  // Try getBounds() first
  std::optional<Loop::LoopBounds> Bounds = L->getBounds(SE);
  
  if (Bounds) {
    LLVM_DEBUG(dbgs() << "  Using getBounds() API\n");
    
    // Extract start value (initial IV value)
    Value &InitialIV = Bounds->getInitialIVValue();
    LD.StartValue = SE.getSCEV(&InitialIV);
    
    // Extract final value (upper/lower bound)
    Value &FinalIV = Bounds->getFinalIVValue();
    LD.EndValue = SE.getSCEV(&FinalIV);
    // The bound IR value is exactly what the compare uses at runtime — keep
    // it for the link-variable path (the former code re-derived it via
    // extractDynamicValue with the same result for these shapes).
    LD.EndValueDynamic = &FinalIV;

    // Extract step value
    if (Value *StepVal = Bounds->getStepValue()) {
      LD.StepValue = SE.getSCEV(StepVal);
    }

    FoundBounds = true;
  } else {
    // Fallback: Try getInductionVariable() + analyze PHI directly
    LLVM_DEBUG(dbgs() << "  getBounds() failed, trying getInductionVariable()\n");
    
    PHINode *IndVar = L->getInductionVariable(SE);
    
    // If getInductionVariable() fails, scan header PHIs with the canonical
    // InductionDescriptor recognition (the former hand-rolled "first affine
    // PHI" scan could bind to the wrong IV in multi-induction loops).
    if (!IndVar) {
      LLVM_DEBUG(dbgs() << "  getInductionVariable() returned null, scanning header PHIs\n");
      InductionDescriptor ID;
      for (PHINode &Phi : L->getHeader()->phis()) {
        if (InductionDescriptor::isInductionPHI(&Phi, L, &SE, ID)) {
          IndVar = &Phi;
          LLVM_DEBUG(dbgs() << "  Found induction PHI: " << Phi << "\n");
          break;
        }
      }
    }
    
    if (IndVar) {
      LLVM_DEBUG(dbgs() << "  Found induction variable: " << *IndVar << "\n");
      
      // Get the SCEV for the induction variable
      const SCEV *IndVarSCEV = SE.getSCEV(IndVar);
      
      if (const SCEVAddRecExpr *AR = dyn_cast<SCEVAddRecExpr>(IndVarSCEV)) {
        if (AR->isAffine()) {
          // Start value is the first operand of the AddRec
          LD.StartValue = AR->getStart();
          
          // Step value
          LD.StepValue = AR->getStepRecurrence(SE);
          
          // End value: capture it from the compares that guard the loop's
          // exits. This runs before the backedge-taken-count fallback because
          // the compares survive shapes SCEV cannot count, e.g. the
          // short-circuit chain of `for (i = 0; i < N && i < C; ++i)`.
          const SCEV *BTC = SE.getBackedgeTakenCount(L);

          SmallVector<ExitBoundCandidate, 2> Candidates;
          SmallVector<BasicBlock *, 4> ExitingBlocks;
          L->getExitingBlocks(ExitingBlocks);
          for (BasicBlock *Exiting : ExitingBlocks) {
            SmallPtrSet<BasicBlock *, 8> Visited;
            if (auto *BI = dyn_cast<CondBrInst>(Exiting->getTerminator()))
              collectExitBoundCandidates(BI->getCondition(), SE, IndVarSCEV,
                                         Candidates, Visited);
          }

          if (!Candidates.empty()) {
            // Every candidate bounds the IV from above (or pins it with an
            // equality), so the loop bound is the tightest of them:
            // `i < N && i < C` is min(N, C). Mixed signedness or a non-upper
            // direction (e.g. i > C) is not folded — the first captured
            // compare stays the bound.
            auto IsSignedUpper = [](ICmpInst::Predicate P) {
              return P == ICmpInst::ICMP_SLT || P == ICmpInst::ICMP_SLE ||
                     P == ICmpInst::ICMP_EQ;
            };
            auto IsUnsignedUpper = [](ICmpInst::Predicate P) {
              return P == ICmpInst::ICMP_ULT || P == ICmpInst::ICMP_ULE ||
                     P == ICmpInst::ICMP_EQ;
            };
            bool AllSigned =
                llvm::all_of(Candidates, [&](const ExitBoundCandidate &C) {
                  return IsSignedUpper(C.Pred);
                });
            bool AllUnsigned =
                llvm::all_of(Candidates, [&](const ExitBoundCandidate &C) {
                  return IsUnsignedUpper(C.Pred);
                });
            Type *BoundTy = Candidates[0].BoundSCEV->getType();
            bool SameType =
                llvm::all_of(Candidates, [&](const ExitBoundCandidate &C) {
                  return C.BoundSCEV->getType() == BoundTy;
                });

            if (Candidates.size() > 1 && (AllSigned || AllUnsigned) &&
                SameType) {
              const SCEV *Min = Candidates[0].BoundSCEV;
              for (const ExitBoundCandidate &C :
                   ArrayRef<ExitBoundCandidate>(Candidates).drop_front())
                Min = AllSigned ? SE.getSMinExpr(Min, C.BoundSCEV)
                                : SE.getUMinExpr(Min, C.BoundSCEV);
              LD.EndValue = Min;
              LLVM_DEBUG(dbgs() << "    Captured end bound as minimum of "
                                << Candidates.size() << " exit compares: "
                                << *LD.EndValue << "\n");
              if (BasicBlock *Preheader = L->getLoopPreheader()) {
                SCEVExpander Expander(SE, "interstellar");
                Expander.setInsertPoint(Preheader->getTerminator());
                LD.EndValueDynamic = Expander.expandCodeFor(
                    LD.EndValue,
                    SE.getEffectiveSCEVType(IndVarSCEV->getType()),
                    Preheader->getTerminator());
              }
            } else {
              LD.EndValue = Candidates[0].BoundSCEV;
              LD.EndValueDynamic = Candidates[0].BoundIR;
              LLVM_DEBUG(dbgs() << "    Captured end bound from exit compare: "
                                << *Candidates[0].BoundIR << "\n");
            }
          } else if (!isa<SCEVCouldNotCompute>(BTC)) {
            // No compare captured; derive End = Start + BTC * Step.
            if (LD.StepValue)
              LD.EndValue = SE.getAddExpr(
                  LD.StartValue, SE.getMulExpr(BTC, LD.StepValue));
            else
              LD.EndValue = SE.getAddExpr(LD.StartValue, BTC);
          }

          FoundBounds = LD.EndValue != nullptr;
        }
      }
    }
  }
  
  if (FoundBounds) {
    LLVM_DEBUG({
      dbgs() << "  Loop Bounds Analysis:\n";
      dbgs() << "    Start: " << *LD.StartValue << "\n";
      dbgs() << "    End: " << *LD.EndValue << "\n";
      if (LD.StepValue) {
        dbgs() << "    Step: " << *LD.StepValue << "\n";
      }
      dbgs() << "    Is Start Dynamic: " << isValueDynamic(LD.StartValue) << "\n";
      dbgs() << "    Is End Dynamic: " << isValueDynamic(LD.EndValue) << "\n";
    });
    
    // Check if start value is dynamic (e.g., function parameter, outer loop variable)
    if (isValueDynamic(LD.StartValue)) {
      LD.IsStartLinked = true;
      LD.StartValueDynamic = extractDynamicValue(LD.StartValue, L);
      if (LD.StartValueDynamic) {
        LD.StartLinkID = getOrCreateLinkID(LD.StartValueDynamic, 
                                            getTypeSizeInBytes(LD.StartValueDynamic->getType()));
      }
    }
    
    // Check if end value is dynamic
    if (isValueDynamic(LD.EndValue)) {
      LD.IsEndLinked = true;
      
      // Use the IR value directly if we captured it from the comparison
      // This is the actual value used at runtime (e.g., the result of N-M computation)
      Value *EndVal = LD.EndValueDynamic;
      
      // If we didn't capture it from comparison, try to extract it from SCEV
      if (!EndVal) {
        EndVal = extractDynamicValue(LD.EndValue, L);
      }
      
      if (EndVal) {
        LD.EndValueDynamic = EndVal;
        LD.EndLinkID = getOrCreateLinkID(EndVal, 
                                          getTypeSizeInBytes(EndVal->getType()));
      }
    }
    
    LoopDescriptors.push_back(LD);
  } else {
    // Could not extract loop bounds, but still create a descriptor
    // to preserve loop hierarchy (parent-child relationships)
    LLVM_DEBUG(dbgs() << "  Could not extract loop bounds, creating descriptor with unknown bounds\n");
    LoopDescriptors.push_back(LD);
  }
  
  // Analyze memory accesses in the loop
  // CRITICAL: Only analyze blocks that DIRECTLY belong to this loop, not nested sub-loops
  // For nested loops, L->blocks() returns ALL blocks including nested loops' blocks
  // This would cause instructions in nested loops to be analyzed multiple times
  // We use L->getBlocksVector() and filter out blocks that belong to sub-loops
  for (BasicBlock *BB : L->blocks()) {
    // Skip blocks that belong to a nested sub-loop
    // Those will be analyzed when we process the nested loop itself
    Loop *BBLoop = LI.getLoopFor(BB);
    if (BBLoop != L) {
      // This block belongs to a more deeply nested loop, skip it
      continue;
    }
    
    for (Instruction &I : *BB) {
      if (isa<LoadInst>(&I) || isa<StoreInst>(&I)) {
        analyzeMemoryAccess(&I, L);
      }
    }
  }
}

void InterStellarStreamAnalyzer::analyzeMemoryAccess(Instruction *I, Loop *L) {
  // Prevent duplicate stream entries - each instruction maps to exactly one stream
  if (InstToStreamIDMap.count(I)) {
    LLVM_DEBUG(dbgs() << "  Instruction already assigned to stream "
                      << InstToStreamIDMap[I] << ", skipping: " << *I << "\n");
    return;
  }
  
  Value *Ptr = nullptr;
  
  if (LoadInst *LI = dyn_cast<LoadInst>(I)) {
    Ptr = LI->getPointerOperand();
  } else if (StoreInst *SI = dyn_cast<StoreInst>(I)) {
    Ptr = SI->getPointerOperand();
  }
  
  if (!Ptr)
    return;
  
  // Try to analyze as a direct stream first
  if (tryAnalyzeDirectStream(Ptr, I, L)) {
    return;  // Successfully identified as direct stream
  }
  
  // If not a direct stream, try indirect stream analysis
  tryAnalyzeIndirectStream(Ptr, I, L);
}

bool InterStellarStreamAnalyzer::tryAnalyzeDirectStream(Value *Ptr,
                                                         Instruction *MemInst,
                                                         Loop *L) {
  // Detect affine memory access patterns (e.g., A[i] where i increments linearly)
  //
  // Approach:
  // 1. Trace through GEP chains to handle constant offsets (e.g., C[i+2])
  // 2. Check for AddRecExpr in SCEV (optimized code path)
  // 3. Analyze GEP indices for induction variables (unoptimized code path)
  //
  // Nested loops: For A[i*M + j], the inner loop sees a direct stream with:
  //   - Base: outer AddRec {0,+,M}<%outer> (becomes link variable)
  //   - Stride: 1 * element_size
  
  LLVM_DEBUG({
    dbgs() << "Start analyzeDirectStream on instruction: ";
    if (MemInst) {
      dbgs() << *MemInst << "\n";
    } else {
      dbgs() << "(null)\n";
    }
  });
  
  // Trace through GEP chains to find AddRec with constant offsets
  // Handles cases like C[i+2] where optimizer generates chained GEPs
  Value *CurrentPtr = Ptr;
  int64_t AccumulatedOffset = 0;
  
  // Trace back through constant-offset GEPs
  while (GetElementPtrInst *GEP = dyn_cast<GetElementPtrInst>(CurrentPtr)) {
    // Check if this GEP has constant indices
    int64_t ThisGEPOffset = 0;
    
    // Calculate offset for this GEP
    APInt OffsetAPInt(64, 0, true);
    if (GEP->accumulateConstantOffset(F.getDataLayout(), OffsetAPInt)) {
      // All indices are constant
      ThisGEPOffset = OffsetAPInt.getSExtValue();
      AccumulatedOffset += ThisGEPOffset;
      
      LLVM_DEBUG(dbgs() << "  Found constant-offset GEP: " << *GEP 
                        << ", offset=" << ThisGEPOffset << " bytes\n");
      
      // Move to the base pointer of this GEP
      CurrentPtr = GEP->getPointerOperand();
    } else {
      // This GEP has non-constant indices - stop tracing
      break;
    }
  }
  
  // Now check if CurrentPtr (after tracing) is or contains an AddRec
  GetElementPtrInst *GEP = dyn_cast<GetElementPtrInst>(CurrentPtr);
  if (!GEP) {
    // Ptr might be the result of a GEP that's already computed
    // Try to get SCEV directly (optimized code path)
    const SCEV *PtrSCEV = SE.getSCEV(CurrentPtr);
    const SCEVAddRecExpr *AR = dyn_cast<SCEVAddRecExpr>(PtrSCEV);
    
    if (!AR) {
      LLVM_DEBUG(dbgs() << "  Not a GEP and not an AddRec: " << *CurrentPtr << "\n");
      return false;
    }
    
    // Check if AddRec belongs to this loop or an outer loop
    // For nested loops like A[i*M + j]:
    //   - Inner loop sees AddRec {A,+,M*4}<%outer> for base (outer loop induction)
    //   - This outer-loop AddRec is loop-invariant for inner loop
    //   - It should be used as the base address, not rejected
    Loop *StreamLoop = resolveOwningLoop(AR, L);
    if (!StreamLoop) {
      // AddRec belongs to an inner or unrelated loop
      LLVM_DEBUG(dbgs() << "  AddRec belongs to inner or unrelated loop, skipping\n");
      return false;
    }
    
    // Verify it's affine
    if (!AR->isAffine()) {
      LLVM_DEBUG(dbgs() << "  AddRec not affine\n");
      return false;
    }
    
    const SCEV *Base = AR->getStart();
    const SCEV *Step = AR->getStepRecurrence(SE);
    const SCEVConstant *StepConst = dyn_cast<SCEVConstant>(Step);
    
    if (!StepConst) {
      return false;
    }
    
    // CRITICAL: Verify that the base address is effectively loop-invariant
    // Example: D3B[rand()][j][k] where rand() is called every iteration
    // The base address depends on rand(), which is NOT loop-invariant
    if (!isEffectivelyLoopInvariant(Base, L)) {
      LLVM_DEBUG(dbgs() << "  Base address is not effectively loop-invariant: " << *Base << "\n");
      return false;
    }
    
    int64_t Stride = StepConst->getAPInt().getSExtValue();
    
    // Use helper method to create stream with accumulated offset
    // Use StreamLoop (may be outer loop) instead of L
    createDirectStream(Base, Stride, StreamLoop, MemInst, AccumulatedOffset);
    return true;
  }
  
  // GEP-based analysis (handles unoptimized IR)
  // GEP format: getelementptr base_type, ptr base, indices...
  // For array access A[i], we have: getelementptr i32, ptr %A, i64 %index
  
  // Get the base pointer
  Value *BasePtr = GEP->getPointerOperand();
  
  // Get the last index (for simple 1D array access)
  if (GEP->getNumIndices() == 0) {
    return false;
  }
  
  // For 1D arrays: GEP has 1 index
  // For multi-dim or complex: GEP might have multiple indices
  // We focus on the last index which represents the actual array subscript
  Value *Index = nullptr;
  Index = getLastGEPIndex(GEP);
  
  if (!Index) {
    return false;
  }
  
  // CRITICAL FIX: Analyze index SCEV first to detect compound indices
  // Pattern: array[idx_i * M + j] where idx_i = load(A[i])
  // In the inner j-loop, idx_i is loop-invariant, so this should be a direct stream!
  //
  // Example from pattern5_2d_pointer.c:
  //   int idx_i = A[i] % D2_rows;         // Outer loop, i
  //   D2A[idx_i * D2_cols + j]++;         // Inner loop, j
  //
  // For the j-loop, idx_i * D2_cols is loop-invariant (constant for each iteration of j).
  // The SCEV is: (idx_i * D2_cols) + {0,+,1}<j-loop>
  //             = loop_invariant_part + affine_part
  //
  // This should be recognized as a direct stream with:
  //   - Base: array + (idx_i * D2_cols) * element_size
  //   - Stride: 1 * element_size
  //
  // Compare with pattern7_2d_fixed.c where D2B[idx_i][j] generates TWO GEPs:
  //   - First GEP: selects row (includes indirect index)
  //   - Second GEP: selects column (direct stream)
  // Both patterns are semantically equivalent and should produce the same stream type!
  
  const SCEV *IndexSCEV = SE.getSCEV(Index);
  LLVM_DEBUG(dbgs() << "  Index SCEV: " << *IndexSCEV << "\n");
  
  // Try to decompose index SCEV into: loop_invariant_part + affine_loop_variant_part
  const SCEV *LoopInvariantPart = nullptr;
  const SCEVAddRecExpr *AffinePartAR = nullptr;
  
  // Unwrap casts first
  const SCEV *UnwrappedIndexSCEV = IndexSCEV;
  UnwrappedIndexSCEV = stripSCEVCasts(UnwrappedIndexSCEV);
  
  // Check if the index is a sum of loop-invariant and loop-variant parts
  if (const SCEVAddExpr *AddExpr = dyn_cast<SCEVAddExpr>(UnwrappedIndexSCEV)) {
    SmallVector<const SCEV *, 4> InvariantOps;
    
    for (const SCEV *Op : AddExpr->operands()) {
      // Unwrap casts on operands
      const SCEV *UnwrappedOp = Op;
      UnwrappedOp = stripSCEVCasts(UnwrappedOp);
      
      // Check if this operand is an affine AddRec for the current loop
      if (const SCEVAddRecExpr *OpAR = dyn_cast<SCEVAddRecExpr>(UnwrappedOp)) {
        if (OpAR->getLoop() == L && OpAR->isAffine()) {
          // Found the affine part! Only accept one affine AddRec
          if (!AffinePartAR) {
            AffinePartAR = OpAR;
          } else {
            // Multiple AddRecs for this loop - too complex
            AffinePartAR = nullptr;
            break;
          }
        } else {
          // AddRec for a different loop - part of loop-invariant base
          InvariantOps.push_back(Op);
        }
      } else if (SE.isLoopInvariant(Op, L)) {
        // This operand is loop-invariant for current loop
        InvariantOps.push_back(Op);
      } else {
        // Check if this operand, while not strictly loop-invariant,
        // is based on values from outer loops (e.g., A[i] in inner j-loop)
        // This handles the case: D2A[idx_i * D2_cols + j] where idx_i = A[i]
        // Even though idx_i is recomputed inside j-loop, its value only depends
        // on the outer i-loop variable, making it effectively loop-invariant
        // for the j-loop in terms of access pattern.
        
        // Try to find if all contributing values are loop-invariant or from outer loops
        bool IsEffectivelyInvariant = isEffectivelyLoopInvariant(Op, L);
        
        if (IsEffectivelyInvariant) {
          LLVM_DEBUG(dbgs() << "  Operand is effectively loop-invariant (depends on outer loops): " << *Op << "\n");
          InvariantOps.push_back(Op);
        } else {
          // Loop-varying non-affine component (e.g., rand())
          LLVM_DEBUG(dbgs() << "  Index has loop-varying non-affine operand: " << *Op << "\n");
          AffinePartAR = nullptr;
          break;
        }
      }
    }
    
    // If we successfully decomposed the index into invariant + affine parts
    if (AffinePartAR && !InvariantOps.empty()) {
      LLVM_DEBUG({
        dbgs() << "  Successfully decomposed index into:\n";
        dbgs() << "    Affine part (loop-variant): " << *AffinePartAR << "\n";
        dbgs() << "    Loop-invariant part: ";
        for (const SCEV *Op : InvariantOps) {
          dbgs() << *Op << " ";
        }
        dbgs() << "\n";
        dbgs() << "  This is a DIRECT stream with loop-invariant base offset!\n";
      });
      
      // Compute the loop-invariant offset
      if (InvariantOps.size() == 1) {
        LoopInvariantPart = InvariantOps[0];
      } else {
        SmallVector<SCEVUse, 4> InvariantOpsUse;
        InvariantOpsUse.reserve(InvariantOps.size());
        for (const SCEV *Op : InvariantOps)
          InvariantOpsUse.push_back(Op);
        LoopInvariantPart = SE.getAddExpr(InvariantOpsUse);
      }
      
      // Calculate memory stride: affine_step * element_size
      const SCEV *AffineStep = AffinePartAR->getStepRecurrence(SE);
      const SCEVConstant *StepConst = dyn_cast<SCEVConstant>(AffineStep);
      
      if (!StepConst) {
        LLVM_DEBUG(dbgs() << "  Affine step is not constant, cannot create direct stream\n");
        return false;
      }
      
      int64_t ElementSize = getPointeeElementSize(GEP, F.getDataLayout());
      int64_t StepValue = StepConst->getAPInt().getSExtValue();
      int64_t MemoryStride = StepValue * ElementSize;
      
      // Get base address and incorporate the loop-invariant offset
      const SCEV *BasePtrSCEV = SE.getSCEV(BasePtr);
      const SCEV *BaseSCEV = BasePtrSCEV;
      
      // Apply accumulated GEP chain offset first
      if (AccumulatedOffset != 0) {
        Type *PtrTy = SE.getEffectiveSCEVType(BaseSCEV->getType());
        const SCEV *OffsetSCEV = SE.getConstant(PtrTy, AccumulatedOffset);
        BaseSCEV = SE.getAddExpr(BaseSCEV, OffsetSCEV);
      }
      
      // Apply the loop-invariant index offset (e.g., idx_i * D2_cols)
      // Scale by element size: base = array + (loop_invariant_offset) * element_size
      Type *PtrTy = SE.getEffectiveSCEVType(BaseSCEV->getType());
      
      // Cast loop-invariant part to pointer type if needed
      const SCEV *CastedInvariant = LoopInvariantPart;
      Type *InvariantTy = LoopInvariantPart->getType();
      if (InvariantTy != PtrTy) {
        CastedInvariant = SE.getSignExtendExpr(LoopInvariantPart, PtrTy);
      }
      
      const SCEV *ElemSizeSCEV = SE.getConstant(PtrTy, ElementSize);
      const SCEV *ScaledInvariant = SE.getMulExpr(CastedInvariant, ElemSizeSCEV);
      BaseSCEV = SE.getAddExpr(BaseSCEV, ScaledInvariant);
      
      LLVM_DEBUG(dbgs() << "  Resulting base SCEV: " << *BaseSCEV << "\n");
      LLVM_DEBUG(dbgs() << "  Memory stride: " << MemoryStride << " bytes\n");
      
      // Create the direct stream
      createDirectStream(BaseSCEV, MemoryStride, L, MemInst, 0);
      return true;
    }
  }
  
  // If we reach here, standard analysis applies: trace through loads
  Value *IndVar = traceIndexThroughLoads(Index, L);
  if (!IndVar) {
    LLVM_DEBUG(dbgs() << "  Could not trace index to induction variable\n");
    return false;
  }
  
  // Now get the SCEV of the induction variable
  const SCEV *IndVarSCEV = SE.getSCEV(IndVar);
  
  // Handle cast expressions (sext, zext, etc.) - unwrap to get the underlying AddRec
  IndVarSCEV = stripSCEVCasts(IndVarSCEV);
  
  // Handle add expressions with offsets (e.g., i+2 becomes {start+2, +, step})
  // CRITICAL: Verify all non-AddRec operands are loop-invariant.
  // For array[i + rand()], the SCEV is (rand_result + {0,+,1}).
  // Since rand_result is loop-varying, this is NOT a direct stream.
  const SCEV *ConstantOffset = nullptr;
  if (const SCEVAddExpr *AddExpr = dyn_cast<SCEVAddExpr>(IndVarSCEV)) {
    // Try to find an AddRec operand in the add expression
    const SCEVAddRecExpr *FoundAR = nullptr;
    SmallVector<const SCEV *, 4> OtherOperands;
    
    for (const SCEV *Op : AddExpr->operands()) {
      // Unwrap casts on operands
      const SCEV *UnwrappedOp = Op;
      UnwrappedOp = stripSCEVCasts(UnwrappedOp);
      
      if (const SCEVAddRecExpr *OpAR = dyn_cast<SCEVAddRecExpr>(UnwrappedOp)) {
        if (!FoundAR) {
          FoundAR = OpAR;
        } else {
          // Multiple AddRecs in the same expression - too complex
          FoundAR = nullptr;
          break;
        }
      } else {
        OtherOperands.push_back(Op);
      }
    }
    
    if (FoundAR) {
      // CRITICAL CHECK: Verify that all non-AddRec operands are loop-invariant
      // If any operand is loop-varying, this is NOT a simple direct stream
      // Example: array[i + rand()] has SCEV: (rand() + {0,+,1})
      // rand() is loop-varying, so this is a computed/random indirect access
      bool AllOperandsInvariant = true;
      for (const SCEV *Op : OtherOperands) {
        if (!SE.isLoopInvariant(Op, L)) {
          AllOperandsInvariant = false;
          LLVM_DEBUG({
            dbgs() << "  Index has loop-varying non-affine component: " << *Op << "\n";
            dbgs() << "  This is NOT a direct stream (computed/random access)\n";
          });
          break;
        }
      }
      
      if (AllOperandsInvariant) {
        IndVarSCEV = FoundAR;
        // Compute the constant offset from other operands
        if (!OtherOperands.empty()) {
          if (OtherOperands.size() == 1) {
            ConstantOffset = OtherOperands[0];
          } else {
            SmallVector<SCEVUse, 4> OtherOperandsUse;
            OtherOperandsUse.reserve(OtherOperands.size());
            for (const SCEV *Op : OtherOperands)
              OtherOperandsUse.push_back(Op);
            ConstantOffset = SE.getAddExpr(OtherOperandsUse);
          }
        }
      } else {
        // Loop-varying non-affine component detected
        // Do NOT treat as direct stream - return false so indirect analysis can handle it
        return false;
      }
    }
  }
  
  const SCEVAddRecExpr *AR = dyn_cast<SCEVAddRecExpr>(IndVarSCEV);
  
  if (!AR) {
    LLVM_DEBUG(dbgs() << "  Index not an AddRec: " << *IndVarSCEV << "\n");
    return false;
  }
  
  // Check if AddRec belongs to this loop or any parent loop
  // For nested loops, A[i] where i is the outer loop variable should be
  // detected as a direct stream of the outer loop, even when analyzed from inner loop
  Loop *StreamLoop = resolveOwningLoop(AR, L);
  if (!StreamLoop) {
    // AddRec belongs to an inner or unrelated loop
    LLVM_DEBUG(dbgs() << "  AddRec belongs to inner or unrelated loop, skipping\n");
    return false;
  }
  
  // Check if it's affine (linear: start + stride * i)
  if (!AR->isAffine()) {
    LLVM_DEBUG(dbgs() << "  AddRec not affine\n");
    return false;
  }
  
  // Extract step for the index (start not used for stride calculation)
  const SCEV *IndexStep = AR->getStepRecurrence(SE);
  
  // Index step must be constant (e.g., i += 1)
  const SCEVConstant *IndexStepConst = dyn_cast<SCEVConstant>(IndexStep);
  if (!IndexStepConst) {
    LLVM_DEBUG(dbgs() << "  Non-constant index step\n");
    return false;
  }
  
  // Check if AddRec has a non-zero start value (e.g., {1,+,1} for i+1, or {i*M,+,1} for nested loops)
  // The start value represents the loop-invariant offset for the current loop
  const SCEV *IndexStart = AR->getStart();
  
  // For nested loops like A[i*M + j], IndexStart = i*M (loop-invariant for inner loop)
  // We need to incorporate this into the base address calculation
  const SCEV *DynamicIndexOffset = nullptr;
  
  if (!ConstantOffset) {
    if (const SCEVConstant *StartConst = dyn_cast<SCEVConstant>(IndexStart)) {
      // Constant start (e.g., {2,+,1} for array[i+2])
      if (!StartConst->isZero()) {
        ConstantOffset = IndexStart;
        LLVM_DEBUG(dbgs() << "  AddRec start is non-zero constant: " 
                          << *ConstantOffset << "\n");
      }
    } else if (!isa<SCEVConstant>(IndexStart) && !IndexStart->isZero()) {
      // Dynamic start (e.g., {i*M,+,1} for nested loops A[i*M + j])
      // This is loop-invariant for current loop but varies with outer loop
      DynamicIndexOffset = IndexStart;
      LLVM_DEBUG(dbgs() << "  AddRec start is dynamic (outer-loop dependent): " 
                        << *IndexStart << "\n");
    }
  }
  
  // Calculate memory stride: index_step * element_size
  int64_t ElementSize = getPointeeElementSize(GEP, F.getDataLayout());
  int64_t IndexStepVal = IndexStepConst->getAPInt().getSExtValue();
  int64_t MemoryStride = IndexStepVal * ElementSize;
  
  // Get base address SCEV - this is the pointer to the array
  const SCEV *BasePtrSCEV = SE.getSCEV(BasePtr);
  
  // Apply constant index offset to base address
  // For array[i+2], the constant offset 2 means we start at array + 2*element_size
  // For row_ptr[i+1], the offset 1 means we start at row_ptr + 1*sizeof(int)
  // For A[i*M + j], the dynamic offset i*M means base = A + i*M*element_size
  const SCEV *BaseSCEV = BasePtrSCEV;
  
  // First, apply any accumulated offset from GEP chain tracing
  if (AccumulatedOffset != 0) {
    LLVM_DEBUG(dbgs() << "  Applying accumulated GEP chain offset: " 
                      << AccumulatedOffset << " bytes to base\n");
    Type *PtrTy = SE.getEffectiveSCEVType(BaseSCEV->getType());
    const SCEV *OffsetSCEV = SE.getConstant(PtrTy, AccumulatedOffset);
    BaseSCEV = SE.getAddExpr(BaseSCEV, OffsetSCEV);
  }
  
  // Second, apply constant index offset (e.g., +2 in C[i+2])
  if (ConstantOffset) {
    // Check if offset is truly constant (not loop-varying)
    if (const SCEVConstant *ConstOffsetConst = dyn_cast<SCEVConstant>(ConstantOffset)) {
      int64_t OffsetValue = ConstOffsetConst->getAPInt().getSExtValue();
      int64_t MemoryOffset = OffsetValue * ElementSize;
      
      LLVM_DEBUG(dbgs() << "  Applying constant index offset: " << OffsetValue 
                        << " indices = " << MemoryOffset << " bytes to base\n");
      
      Type *PtrTy = SE.getEffectiveSCEVType(BaseSCEV->getType());
      const SCEV *MemOffsetSCEV = SE.getConstant(PtrTy, MemoryOffset);
      BaseSCEV = SE.getAddExpr(BaseSCEV, MemOffsetSCEV);
    }
  }
  
  // Third, apply dynamic index offset (e.g., i*M in A[i*M + j] for nested loops)
  // This creates a base address that depends on outer loop variables
  if (DynamicIndexOffset) {
    // Scale the dynamic offset by element size: base = A + (i*M) * element_size
    // CRITICAL: Ensure type consistency - both operands must have same type
    Type *PtrTy = SE.getEffectiveSCEVType(BaseSCEV->getType());
    
    // Cast DynamicIndexOffset to pointer-sized type if needed
    const SCEV *CastedOffset = DynamicIndexOffset;
    Type *OffsetTy = DynamicIndexOffset->getType();
    if (OffsetTy != PtrTy) {
      // Sign-extend or zero-extend to pointer type
      CastedOffset = SE.getSignExtendExpr(DynamicIndexOffset, PtrTy);
      LLVM_DEBUG(dbgs() << "  Type cast: " << *DynamicIndexOffset 
                        << " from " << *OffsetTy << " to " << *PtrTy << "\n");
    }
    
    const SCEV *ElemSizeSCEV = SE.getConstant(PtrTy, ElementSize);
    const SCEV *ScaledOffset = SE.getMulExpr(CastedOffset, ElemSizeSCEV);
    BaseSCEV = SE.getAddExpr(BaseSCEV, ScaledOffset);
    
    LLVM_DEBUG(dbgs() << "  Applying dynamic index offset: " << *DynamicIndexOffset
                      << " * " << ElementSize << " bytes to base\n");
    LLVM_DEBUG(dbgs() << "  Resulting base SCEV: " << *BaseSCEV << "\n");
    
    // Try to extract the dynamic value for the offset (for link variable creation)
    // For i*M, this might be a computed value in the loop preheader
    if (Value *OffsetVal = extractDynamicValue(DynamicIndexOffset, L)) {
      LLVM_DEBUG(dbgs() << "  Found dynamic offset value: " << *OffsetVal << "\n");
      // Note: We pass the offset value, not the full base, because createDirectStream
      // will need to compute: base_link_value = A_ptr + offset_value * element_size
      // For now, we rely on extractDynamicValue to find the materialized address
    }
  }
  
  // Check if base pointer contains an outer-loop AddRecExpr (optimized code path)
  // For optimized code, compiler creates %invariant.gep = A + i*M before inner loop
  Value *OuterLoopBaseValue = nullptr;
  if (containsOuterLoopAddRec(BasePtrSCEV, L)) {
    // Base varies with outer-loop iterations, so it cannot be expanded at this
    // loop's preheader — use BasePtr (the GEP computing the row base at
    // runtime) as the dynamic value. The isEffectivelyLoopInvariant check
    // below still rejects bases recomputed per-iteration (rand() and friends).
    OuterLoopBaseValue = BasePtr;
    LLVM_DEBUG(dbgs() << "  Base contains outer-loop AddRecExpr, using BasePtr as link variable: "
                      << *BasePtr << "\n");
  }
  
  // CRITICAL: Verify that the final base address is effectively loop-invariant
  // Example: D3B[rand()][j][k] where rand() is called every iteration
  // The base address depends on rand(), which is NOT loop-invariant
  // This check catches cases where BasePtrSCEV or DynamicIndexOffset contains
  // calls to rand() or other loop-varying non-affine computations
  if (!isEffectivelyLoopInvariant(BaseSCEV, L)) {
    LLVM_DEBUG(dbgs() << "  Base address is not effectively loop-invariant: " << *BaseSCEV << "\n");
    return false;
  }
  
  // Use helper method to create stream, passing the outer loop base value if available
  // Use StreamLoop (which may be an outer loop) instead of L (current loop being analyzed)
  // BaseSCEV already includes AccumulatedOffset (applied above), so pass 0 —
  // createDirectStream applies its ConstantOffset argument to the base itself.
  createDirectStream(BaseSCEV, MemoryStride, StreamLoop, MemInst, 0, OuterLoopBaseValue);
  
  LLVM_DEBUG({
    dbgs() << "    Element Size: " << ElementSize << " bytes\n";
    dbgs() << "    Index Step: " << IndexStepVal << "\n";
    if (ConstantOffset) {
      dbgs() << "    Constant Index Offset Applied: " << *ConstantOffset << "\n";
    }
    if (StreamLoop != L) {
      dbgs() << "    Stream associated with outer loop (not current loop)\n";
    }
  });
  
  return true;
}

/// Compute the allocated byte size of the target array for an indirect stream.
/// Returns 0 if the size cannot be statically determined (e.g., pointer parameters).
static uint64_t computeArrayFootprint(const SCEV *BaseSCEV,
                                      Value *BaseAddressValue,
                                      const DataLayout &DL) {
  // Prefer the BaseAddressValue if available (set when base is linked/dynamic)
  Value *BaseV = BaseAddressValue;
  if (!BaseV) {
    // For constant/global bases, BaseAddressValue may be null; extract from SCEV
    if (const auto *U = dyn_cast_or_null<SCEVUnknown>(BaseSCEV))
      BaseV = U->getValue();
  }
  if (!BaseV)
    return 0;

  // Strip through GEPs/casts to the underlying allocation
  Value *Underlying = getUnderlyingObject(BaseV);
  if (!Underlying)
    return 0;

  // getObjectSize requires a pointer. extractDynamicValue's leaf fallback can
  // hand back non-pointer values (e.g., an i32 index), and
  // DataLayout::getIndexTypeSizeInBits asserts on non-pointer types.
  if (!Underlying->getType()->isPointerTy())
    return 0;

  uint64_t Size = 0;
  // Try LLVM's object size analysis (handles allocas, globals, some mallocs)
  // Pass nullptr for TargetLibraryInfo - we'll fall back to direct type analysis
  if (getObjectSize(Underlying, Size, DL, /*TLI=*/nullptr))
    return Size;

  // Fallback: directly query AllocaInst or GlobalVariable type sizes
  if (const auto *AI = dyn_cast<AllocaInst>(Underlying))
    return DL.getTypeAllocSize(AI->getAllocatedType());
  if (const auto *GV = dyn_cast<GlobalVariable>(Underlying))
    return DL.getTypeAllocSize(GV->getValueType());

  return 0;  // Unknown size (e.g., pointer parameter)
}

bool InterStellarStreamAnalyzer::tryAnalyzeIndirectStream(Value *Ptr,
                                                           Instruction *MemInst,
                                                           Loop *L) {
  // Detect indirect access patterns: A[B[i]], A[B[C[i]]], or computed indices
  //
  // Algorithm:
  // 1. Extract GEP index operand (handle chained GEPs for struct field accesses)
  // 2. Search for LoadInst providing the index (recursively through casts/ops)
  // 3. Check if LoadInst is from a known stream (enables chaining)
  // 4. Create indirect stream descriptor with stream dependency
  
  LLVM_DEBUG(dbgs() << "  Trying indirect stream analysis for: " << *MemInst << "\n");
  
  // Step 1: Check if Ptr is a GEP
  GetElementPtrInst *GEP = dyn_cast<GetElementPtrInst>(Ptr);
  if (!GEP) {
    LLVM_DEBUG(dbgs() << "    Not a GEP instruction\n");
    return false;
  }
  
  // Step 1.5: Handle chained GEPs for struct field accesses
  // Pattern: struct_array[indirect_idx].field
  // IR: %field_gep = gep i8, ptr %struct_gep, i64 <field_offset>
  //     %struct_gep = gep %struct, ptr %base, i64 %indirect_idx
  // 
  // When we see a GEP with constant indices (field offsets), check if its
  // pointer operand is another GEP with a loop-varying index (the actual indirect access)
  GetElementPtrInst *RootGEP = GEP;
  
  // Check if this GEP has only constant indices (indicates field offset GEP)
  bool AllConstantIndices = true;
  for (auto IdxIt = GEP->idx_begin(); IdxIt != GEP->idx_end(); ++IdxIt) {
    if (!isa<ConstantInt>(IdxIt->get())) {
      AllConstantIndices = false;
      break;
    }
  }
  
  // If all indices are constant, this might be a field-offset GEP
  // Check if the pointer operand is another GEP with loop-varying indices
  int64_t FieldOffset = 0; // byte offset of the peeled field GEP, if any
  if (AllConstantIndices) {
    if (GetElementPtrInst *ParentGEP = dyn_cast<GetElementPtrInst>(GEP->getPointerOperand())) {
      // Found a parent GEP - use it as the root for indirect analysis
      APInt OffsetAPInt(64, 0, true);
      if (GEP->accumulateConstantOffset(F.getDataLayout(), OffsetAPInt))
        FieldOffset = OffsetAPInt.getSExtValue();
      RootGEP = ParentGEP;
      LLVM_DEBUG(dbgs() << "    Found chained GEP for struct field access, using parent GEP as root\n");
      LLVM_DEBUG(dbgs() << "    Parent GEP: " << *ParentGEP << "\n");
    }
  }
  
  // Step 2: Extract the index operand(s) from the root GEP
  // For simple arrays: GEP has one index
  // For multi-dimensional: GEP might have multiple indices
  // We focus on the last index which represents the actual array subscript
  if (RootGEP->getNumIndices() == 0) {
    LLVM_DEBUG(dbgs() << "    Root GEP has no indices\n");
    return false;
  }
  
  Value *Index = nullptr;
  Index = getLastGEPIndex(RootGEP);
  
  if (!Index) {
    return false;
  }
  
  LLVM_DEBUG(dbgs() << "    Root GEP Index: " << *Index << "\n");
  
  // Search for LoadInst providing the index value
  // Trace through casts, arithmetic ops, selects, and PHIs
  Value *IndexSource = Index;
  LoadInst *IndexLoad = nullptr;
  SmallPtrSet<Value *, 8> Visited;
  
  // Recursive search for LoadInst in index computation tree
  std::function<LoadInst*(Value*)> findIndexLoad = [&](Value *V) -> LoadInst* {
    if (!V || !Visited.insert(V).second) {
      return nullptr;  // Already visited or null
    }
    
    // Found a load - this is our index source
    if (LoadInst *Load = dyn_cast<LoadInst>(V)) {
      return Load;
    }
    
    // Unwrap casts
    if (CastInst *Cast = dyn_cast<CastInst>(V)) {
      return findIndexLoad(Cast->getOperand(0));
    }
    
    // Unwrap binary operations (add, mul, sub, etc.)
    // For operations like (C[i] + 1) or (B[idx1] * 2), we want to find
    // the load instruction that provides the dynamic index value
    if (BinaryOperator *BinOp = dyn_cast<BinaryOperator>(V)) {
      // Try both operands - prioritize non-constant operands
      for (unsigned i = 0; i < BinOp->getNumOperands(); ++i) {
        Value *Operand = BinOp->getOperand(i);
        
        // Skip constants - they don't provide index streams
        if (isa<Constant>(Operand)) {
          continue;
        }
        
        // Recursively search this operand
        if (LoadInst *Load = findIndexLoad(Operand)) {
          return Load;
        }
      }
    }
    
    // Unwrap select instructions (for conditional indexing)
    if (SelectInst *Select = dyn_cast<SelectInst>(V)) {
      // Try the true value first, then false value
      if (LoadInst *Load = findIndexLoad(Select->getTrueValue())) {
        return Load;
      }
      return findIndexLoad(Select->getFalseValue());
    }
    
    // Unwrap phi nodes (for complex control flow)
    if (PHINode *Phi = dyn_cast<PHINode>(V)) {
      // Try all incoming values
      for (unsigned i = 0; i < Phi->getNumIncomingValues(); ++i) {
        if (LoadInst *Load = findIndexLoad(Phi->getIncomingValue(i))) {
          return Load;
        }
      }
    }
    
    return nullptr;
  };
  
  IndexLoad = findIndexLoad(IndexSource);
  
  // Step 4: Determine index source type
  // Case 1: Index comes from a LoadInst (stream-based indirect)
  // Case 2: Index is computed/random (computed indirect)
  
  bool IsIndexFromStream = false;
  unsigned SourceStreamID = 0;
  
  if (IndexLoad) {
    // Found a load - check if it's from a known stream
    LLVM_DEBUG(dbgs() << "    Found index load: " << *IndexLoad << "\n");
    
    std::optional<unsigned> StreamID = getStreamSource(IndexLoad, L);
    if (StreamID) {
      IsIndexFromStream = true;
      SourceStreamID = *StreamID;
      LLVM_DEBUG(dbgs() << "    Index comes from Stream ID: " << SourceStreamID << "\n");
    } else {
      LLVM_DEBUG(dbgs() << "    Index load is not from a known stream\n");
    }
  }
  
  // A stream-driven index must be the index's ONLY loop-varying component.
  // When the subscript mixes the stream value with an affine term — for
  // D2A[i * D2_cols + A[j] % D2_cols] the outer i * D2_cols part — the
  // descriptor can only encode base + source stream and would silently
  // describe the wrong addresses (row 0 of the array). Such a stream is
  // unencodable: drop it, like the row-variant siblings that fail base
  // extraction below.
  if (IsIndexFromStream) {
    const SCEV *IndexSCEV = SE.getSCEV(Index);
    bool HasLoopVaryingTerm = false;
    std::function<void(const SCEV *)> FindAddRec = [&](const SCEV *S) {
      if (HasLoopVaryingTerm || isa<SCEVUnknown>(S) || isa<SCEVConstant>(S))
        return;
      if (isa<SCEVAddRecExpr>(S)) {
        HasLoopVaryingTerm = true;
        return;
      }
      for (const SCEV *Op : S->operands())
        FindAddRec(Op);
    };
    FindAddRec(IndexSCEV);
    if (HasLoopVaryingTerm) {
      LLVM_DEBUG(dbgs() << "  Dropping stream: index mixes the source-stream "
                           "value with loop-varying terms the descriptor "
                           "cannot encode\n");
      return false;
    }
  }

  // If we didn't find a stream-based index, check if it's a computed/irregular index
  // This handles cases like: array[rand()], array[f(i)], array[i + rand()], etc.
  if (!IsIndexFromStream) {
    // Check if the index is NOT affine (i.e., not a direct stream pattern)
    const SCEV *IndexSCEV = SE.getSCEV(Index);
    
    // Special case: If the index is affine, normally it would be a direct stream.
    // However, if the BASE ADDRESS is not loop-invariant (contains rand(), function calls, etc.),
    // then even with an affine index, this is still an irregular/computed access pattern.
    // Example: D3B[rand_i][j][k] where k is sequential but rand_i makes the base random.
    if (const SCEVAddRecExpr *AR = dyn_cast<SCEVAddRecExpr>(IndexSCEV)) {
      if (AR->getLoop() == L && AR->isAffine()) {
        // Check if the base address is loop-invariant
        // If it's not, then this is a computed/random indirect stream
        Value *BasePtr = RootGEP->getPointerOperand();
        const SCEV *BaseSCEV = SE.getSCEV(BasePtr);
        
        if (isEffectivelyLoopInvariant(BaseSCEV, L)) {
          // Base is invariant and index is affine - this should have been a direct stream
          LLVM_DEBUG(dbgs() << "    Index is affine AddRec with invariant base, should be direct stream\n");
          return false;
        } else {
          // Base is NOT invariant (e.g., contains rand(), function calls)
          // Even though index is affine, the overall pattern is irregular/computed
          LLVM_DEBUG(dbgs() << "    Index is affine but base address is not loop-invariant (computed/random base)\n");
          // Continue to classify as computed indirect stream
        }
      }
    }
    
    // Check if the index has loop-varying components (i.e., depends on loop variable)
    // If it's loop-invariant, it's just a constant index access, not interesting
    if (!SE.isLoopInvariant(IndexSCEV, L)) {
      // Index is loop-varying but not affine and not from a stream
      // This is a computed/irregular indirect access!
      LLVM_DEBUG(dbgs() << "    Index is computed/irregular (loop-varying, non-affine, no stream)\n");
      IsIndexFromStream = false;  // Mark as computed indirect
      SourceStreamID = 0;  // No source stream
    } else {
      // Loop-invariant index - probably a constant or parameter
      // Not an interesting indirect pattern
      LLVM_DEBUG(dbgs() << "    Index is loop-invariant, not an indirect stream\n");
      return false;
    }
  }
  
  // Step 5: Create indirect stream descriptor
  // Use the root GEP to extract base pointer and element size
  Value *BasePtr = RootGEP->getPointerOperand();
  const SCEV *BaseSCEV = SE.getSCEV(BasePtr);

  // Fold the peeled field offset into the base so struct-field accesses
  // describe distinct streams (points+0 / points+4 / ...), matching the
  // direct-stream encoding where the offset lives in the base. ElementSize
  // stays the struct size: it is the stride between consecutive elements.
  if (FieldOffset != 0) {
    Type *PtrTy = SE.getEffectiveSCEVType(BaseSCEV->getType());
    BaseSCEV = SE.getAddExpr(BaseSCEV, SE.getConstant(PtrTy, FieldOffset));
    LLVM_DEBUG(dbgs() << "    Folded field offset " << FieldOffset
                      << " bytes into base\n");
  }

  // Calculate element size from the root GEP (the one with the indirect index)
  int64_t ElemSize = getPointeeElementSize(RootGEP, F.getDataLayout());
  
  LLVM_DEBUG(dbgs() << "    Base pointer: " << *BasePtr << "\n");
  LLVM_DEBUG(dbgs() << "    Element size: " << ElemSize << " bytes\n");
  
  // Determine the correct loop ID for this indirect stream
  // If the index comes from another stream, use that stream's loop ID
  // Otherwise, use the current loop being analyzed
  unsigned IndirectLoopID = getOrCreateLoopID(L);
  
  LLVM_DEBUG(dbgs() << "    IsIndexFromStream: " << IsIndexFromStream 
                    << ", SourceStreamID: " << SourceStreamID << "\n");
  
  if (IsIndexFromStream) {
    // Index comes from a stream - use that stream's loop ID
    LLVM_DEBUG(dbgs() << "    Searching for loop ID of source stream #" << SourceStreamID << "\n");
    // Find the loop ID of the source stream
    // Check DirectStreams first
    bool FoundSource = false;
    for (const auto &DS : DirectStreams) {
      if (DS.StreamID == SourceStreamID) {
        IndirectLoopID = DS.LoopID;
        FoundSource = true;
        LLVM_DEBUG(dbgs() << "    Using Loop ID " << IndirectLoopID 
                          << " from direct index stream #" << SourceStreamID << "\n");
        break;
      }
    }
    
    // If not found in DirectStreams, check IndirectStreams
    if (!FoundSource) {
      for (const auto &IDS_source : IndirectStreams) {
        if (IDS_source.StreamID == SourceStreamID) {
          IndirectLoopID = IDS_source.LoopID;
          FoundSource = true;
          LLVM_DEBUG(dbgs() << "    Using Loop ID " << IndirectLoopID 
                            << " from indirect index stream #" << SourceStreamID << "\n");
          break;
        }
      }
    }
    
    if (!FoundSource) {
      LLVM_DEBUG(dbgs() << "    WARNING: Source stream #" << SourceStreamID << " not found!\n");
    }
  }
  
  IndirectStreamDescriptor IDS;
  IDS.StreamID = NextStreamID++;
  IDS.LoopID = IndirectLoopID;  // Use the correct loop ID
  IDS.BaseStreamID = SourceStreamID;  // 0 if computed/random index
  IDS.BaseAddress = BaseSCEV;
  IDS.ElementSize = ElemSize;
  IDS.IsBaseLinked = isValueDynamic(BaseSCEV);
  IDS.MemInst = MemInst;
  IDS.IsIndexComputed = !IsIndexFromStream;  // True for computed/random indices
  IDS.Loc = MemInst->getDebugLoc();

  // Handle dynamic base address (e.g., A is a function parameter).
  // Same rules as createDirectStream: composite bases are materialized at the
  // preheader (an unexpandable one drops the stream), and a link must hold an
  // address — a non-pointer or missing base value emits no descriptor.
  if (IDS.IsBaseLinked) {
    Value *BaseVal = nullptr;
    BasicBlock *Preheader = L->getLoopPreheader();
    if (isa<SCEVAddExpr>(BaseSCEV)) {
      if (Preheader) {
        SCEVExpander Expander(SE, "interstellar");
        Expander.setInsertPoint(Preheader->getTerminator());
        if (!Expander.isSafeToExpandAt(BaseSCEV, Preheader->getTerminator())) {
          LLVM_DEBUG(dbgs() << "  Base is not expandable at the preheader "
                               "(loop-variant parts), dropping stream\n");
          return false;
        }
        BaseVal = Expander.expandCodeFor(
            BaseSCEV, PointerType::getUnqual(F.getContext()),
            Preheader->getTerminator());
        LLVM_DEBUG(dbgs() << "  Materialized offset-adjusted base: " << *BaseVal
                          << "\n");
      } else {
        LLVM_DEBUG(dbgs() << "  Warning: Loop has no preheader, cannot "
                             "materialize base\n");
      }
    }
    if (!BaseVal)
      BaseVal = extractDynamicValue(BaseSCEV, L);

    if (!BaseVal) {
      // A base that varies with outer loops (e.g. &D3B[i][j] for the indirect
      // D3B[i][j][idx_k]) is computed by no instruction inside this loop, so
      // extraction fails. As in the direct path's outer-loop handling, the
      // runtime base GEP itself is the link value. Requiring a stream-backed
      // index and an effectively loop-invariant base keeps computed/random
      // indices (rand()-style bases) dropped.
      if (IsIndexFromStream && isa<GetElementPtrInst>(BasePtr) &&
          isEffectivelyLoopInvariant(BaseSCEV, L))
        BaseVal = BasePtr;
    }

    if (!BaseVal || !BaseVal->getType()->isPointerTy()) {
      LLVM_DEBUG(dbgs() << "  Dropping stream: base value "
                        << (BaseVal ? "is not a pointer" : "not found")
                        << "\n");
      return false;
    }

    IDS.BaseAddressValue = BaseVal;
    unsigned Size = sizeInBytesForLink(BaseVal->getType(), F.getDataLayout());
    IDS.LinkID = getOrCreateLinkID(BaseVal, Size);
  } else if (isa<SCEVAddExpr>(BaseSCEV)) {
    // A non-linked composite base still needs a concrete IR value for
    // emission; materialize it where links live.
    if (BasicBlock *Preheader = L->getLoopPreheader()) {
      SCEVExpander Expander(SE, "interstellar");
      Expander.setInsertPoint(Preheader->getTerminator());
      if (Expander.isSafeToExpandAt(BaseSCEV, Preheader->getTerminator()))
        IDS.BaseAddressValue = Expander.expandCodeFor(
            BaseSCEV, PointerType::getUnqual(F.getContext()),
            Preheader->getTerminator());
    }
  }

  // Compute target array's allocated byte extent when statically known
  // (After IsBaseLinked handling so BaseAddressValue is available if needed)
  IDS.StreamSize = computeArrayFootprint(BaseSCEV, IDS.BaseAddressValue, F.getDataLayout());

  IndirectStreams.push_back(IDS);
  InstToStreamIDMap[MemInst] = IDS.StreamID;
  
  // IMPORTANT: Do NOT map IndexLoad here!
  // The IndexLoad is already mapped to its own stream (either direct or indirect).
  // Overwriting it would break shared-index patterns like:
  //   A[B[i]] and C[B[i]] - both should use the same B[i] stream
  // And would also break nested patterns like:
  //   A[B[C[i]]] - C[i] should stay mapped to its direct stream, not B's indirect stream
  //
  // The recursive chaining works because:
  // 1. Each load instruction gets analyzed and mapped to its own stream
  // 2. When analyzing a dependent access, we look up the load's existing mapping
  // 3. We don't need to (and shouldn't) overwrite that mapping
  
  LLVM_DEBUG({
    dbgs() << "  Found Indirect Stream:\n";
    dbgs() << "    Stream ID: " << IDS.StreamID << "\n";
    dbgs() << "    Loop ID: " << IDS.LoopID << "\n";
    dbgs() << "    Base Address: " << *BaseSCEV << "\n";
    dbgs() << "    Element Size: " << IDS.ElementSize << " bytes\n";
    dbgs() << "    Stream Size: " << IDS.StreamSize << " bytes\n";
    dbgs() << "    Base Linked: " << IDS.IsBaseLinked << "\n";
    if (IDS.IsIndexComputed) {
      dbgs() << "    Index Type: Computed/Random (no stream dependency)\n";
    } else {
      dbgs() << "    Driven by Stream: " << IDS.BaseStreamID << "\n";
    }
    dbgs() << "    Source Instruction: " << *MemInst << "\n";
  });
  
  return true;
}

std::optional<unsigned> InterStellarStreamAnalyzer::getStreamSource(Value *V, Loop *L) {
  // Check if an instruction is part of a known stream (enables recursive chaining)
  // Direct check: Is instruction in InstToStreamIDMap?
  // Recursive: If LoadInst, is its pointer from a stream?
  
  if (!V || !isa<Instruction>(V)) {
    return std::nullopt;
  }
  
  Instruction *I = cast<Instruction>(V);
  
  // Direct check: Is this instruction already mapped to a stream?
  auto It = InstToStreamIDMap.find(I);
  if (It != InstToStreamIDMap.end()) {
    return It->second;
  }
  
  // Recursive check: If this is a LoadInst, check if its pointer comes from a stream
  if (LoadInst *Load = dyn_cast<LoadInst>(I)) {
    Value *Ptr = Load->getPointerOperand();
    
    // Check if the pointer is a GEP
    if (GetElementPtrInst *GEP = dyn_cast<GetElementPtrInst>(Ptr)) {
      // Get the index of this GEP
      if (GEP->getNumIndices() > 0) {
        Value *Index = nullptr;
        Index = getLastGEPIndex(GEP);
        
        if (Index) {
          // Unwrap casts
          while (CastInst *Cast = dyn_cast<CastInst>(Index)) {
            Index = Cast->getOperand(0);
          }
          
          // Check if the index is from another load (indirect pattern)
          if (Instruction *IndexInst = dyn_cast<Instruction>(Index)) {
            // Recursively check if this index instruction is from a stream
            std::optional<unsigned> SourceStreamID = getStreamSource(IndexInst, L);
            if (SourceStreamID) {
              // This load is indirectly accessing via another stream
              // We should create an indirect stream descriptor for it
              // But we're in a query function, so just return that we found a source
              return SourceStreamID;
            }
          }
        }
      }
    }
  }
  
  return std::nullopt;
}

Value *InterStellarStreamAnalyzer::traceIndexThroughLoads(Value *Index, Loop *L) {
  // Trace through loads, casts, and extensions to find the PHI induction variable
  // Handles unoptimized IR where loop variables are stored in stack slots
  
  Value *Current = Index;
  SmallPtrSet<Value *, 8> Visited;
  
  while (Current && Visited.insert(Current).second) {
    // If we found a PHI node in this loop, that's our induction variable
    if (PHINode *PHI = dyn_cast<PHINode>(Current)) {
      if (L->contains(PHI->getParent())) {
        return PHI;
      }
    }
    
    // Trace through casts (sext, zext, trunc, bitcast)
    if (CastInst *Cast = dyn_cast<CastInst>(Current)) {
      Current = Cast->getOperand(0);
      continue;
    }
    
    // Trace through loads (for unoptimized code: load from alloca)
    if (LoadInst *Load = dyn_cast<LoadInst>(Current)) {
      Value *Ptr = Load->getPointerOperand();
      
      // Check if this load is loading from an alloca that's updated in the loop
      // We need to find the store that updates it
      if (AllocaInst *Alloca = dyn_cast<AllocaInst>(Ptr)) {
        // Look for PHI-like pattern: load, increment, store
        // Find all stores to this alloca in the loop
        for (User *U : Alloca->users()) {
          if (StoreInst *Store = dyn_cast<StoreInst>(U)) {
            if (L->contains(Store->getParent())) {
              Value *StoredVal = Store->getValueOperand();
              // Check if the stored value is an increment (add)
              if (BinaryOperator *BinOp = dyn_cast<BinaryOperator>(StoredVal)) {
                if (BinOp->getOpcode() == Instruction::Add) {
                  // Check if one operand is a load from the same alloca
                  for (unsigned i = 0; i < BinOp->getNumOperands(); ++i) {
                    if (LoadInst *OpLoad = dyn_cast<LoadInst>(BinOp->getOperand(i))) {
                      if (OpLoad->getPointerOperand() == Alloca) {
                        // This is an induction pattern: i = i + step
                        // Create a pseudo-value representing this induction
                        // For now, return the Load instruction itself
                        // SCEV can analyze simple patterns even from loads
                        return Load;
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
      
      // If we can't find the pattern, try the loaded value
      Current = Ptr;
      continue;
    }
    
    // Can't trace further
    break;
  }
  
  // If we couldn't find a PHI, return the original value
  // Sometimes SCEV can still analyze it
  return Index;
}

unsigned InterStellarStreamAnalyzer::getOrCreateLoopID(Loop *L) {
  auto It = LoopToIDMap.find(L);
  if (It != LoopToIDMap.end()) {
    return It->second;
  }
  
  unsigned ID = NextLoopID++;
  LoopToIDMap[L] = ID;
  return ID;
}

unsigned InterStellarStreamAnalyzer::getOrCreateLinkID(Value *V,
                                                        unsigned SizeInBytes) {
  auto It = ValueToLinkIDMap.find(V);
  if (It != ValueToLinkIDMap.end()) {
    return It->second;
  }
  
  LinkVariableDescriptor LVD;
  LVD.LinkID = NextLinkID++;
  LVD.DynamicValue = V;
  LVD.SizeInBytes = SizeInBytes;
  
  LinkVariables.push_back(LVD);
  ValueToLinkIDMap[V] = LVD.LinkID;
  
  LLVM_DEBUG({
    dbgs() << "  Created Link Variable:\n";
    dbgs() << "    Link ID: " << LVD.LinkID << "\n";
    dbgs() << "    Value: " << *V << "\n";
    dbgs() << "    Size: " << SizeInBytes << " bytes\n";
  });
  
  return LVD.LinkID;
}

bool InterStellarStreamAnalyzer::isValueDynamic(const SCEV *S) {
  // A value is dynamic if it's not a constant
  // SCEVUnknown represents values that SCEV couldn't analyze further,
  // which typically includes function arguments, loads, etc.
  if (isa<SCEVConstant>(S)) {
    return false;
  }
  
  // AddRecExpr represents induction variables - these are dynamic
  // For nested loops, an outer-loop AddRecExpr is a dynamic value
  // from the perspective of the inner loop (e.g., i*M in A[i*M + j])
  if (isa<SCEVAddRecExpr>(S)) {
    return true;
  }
  
  // If it contains any SCEVUnknown, it's potentially dynamic
  if (const SCEVUnknown *Unknown = dyn_cast<SCEVUnknown>(S)) {
    Value *V = Unknown->getValue();
    // Global variables and constants are not dynamic
    if (isa<GlobalVariable>(V) || isa<Constant>(V)) {
      return false;
    }
    return true;
  }
  
  // Check operands recursively for composite SCEV expressions
  bool HasDynamic = false;
  if (const SCEVNAryExpr *NAry = dyn_cast<SCEVNAryExpr>(S)) {
    for (const SCEV *Op : NAry->operands()) {
      if (isValueDynamic(Op)) {
        HasDynamic = true;
        break;
      }
    }
  } else if (const SCEVCastExpr *Cast = dyn_cast<SCEVCastExpr>(S)) {
    HasDynamic = isValueDynamic(Cast->getOperand());
  } else if (const SCEVUDivExpr *UDiv = dyn_cast<SCEVUDivExpr>(S)) {
    // Check UDiv operands (e.g., "X /u 2" in the bound calculation)
    HasDynamic = isValueDynamic(UDiv->getLHS()) || isValueDynamic(UDiv->getRHS());
  }
  
  return HasDynamic;
}

bool InterStellarStreamAnalyzer::isEffectivelyLoopInvariant(const SCEV *S, Loop *L) {
  // Check if a SCEV expression is effectively loop-invariant for loop L.
  // This is more permissive than SE.isLoopInvariant() because it accepts:
  // 1. Truly loop-invariant values (standard case)
  // 2. Values computed from outer loop variables (e.g., A[i] in inner j-loop)
  //
  // Use case: D2A[idx_i * D2_cols + j] where idx_i = A[i]
  // Even though idx_i is recomputed in j-loop, its value only depends on i,
  // so the access pattern is a direct stream in the j-loop.

  // Guard against cyclic SCEV/value graphs (e.g., self-referential PHI patterns)
  // to avoid unbounded recursion.
  SmallPtrSet<const SCEV *, 32> VisitingSCEVs;
  SmallPtrSet<const Value *, 32> VisitingValues;

  std::function<bool(const SCEV *)> IsInvariant = [&](const SCEV *CurS) -> bool {
    if (!CurS)
      return false;

    if (!VisitingSCEVs.insert(CurS).second)
      return true; // already on recursion stack; treat as invariant to break cycle

    // First, check the standard case. SE.isLoopInvariant already accepts
    // AddRecs of any loop containing L (outer-loop IVs are invariant here),
    // so only expressions it rejects reach the code below.
    if (SE.isLoopInvariant(CurS, L)) {
      VisitingSCEVs.erase(CurS);
      return true;
    }

    // Unwrap casts.
    const SCEV *Unwrapped = CurS;
    Unwrapped = stripSCEVCasts(Unwrapped);

    // An AddRec that SE.isLoopInvariant rejected is either this loop's own
    // IV or an unrelated/inner loop recurrence — never effectively invariant.
    // (Everything else falls through to the permissive value recursion.)
    if (isa<SCEVAddRecExpr>(Unwrapped)) {
      VisitingSCEVs.erase(CurS);
      return false;
    }

    // Check composite expressions recursively.
    if (const SCEVNAryExpr *NAry = dyn_cast<SCEVNAryExpr>(Unwrapped)) {
      for (const SCEV *Op : NAry->operands()) {
        if (!IsInvariant(Op)) {
          VisitingSCEVs.erase(CurS);
          return false;
        }
      }
      VisitingSCEVs.erase(CurS);
      return true;
    }

    if (const SCEVUDivExpr *UDiv = dyn_cast<SCEVUDivExpr>(Unwrapped)) {
      bool Res = IsInvariant(UDiv->getLHS()) && IsInvariant(UDiv->getRHS());
      VisitingSCEVs.erase(CurS);
      return Res;
    }

    // SCEVUnknown: Check if it's based on values from outer loops or constants.
    if (const SCEVUnknown *Unknown = dyn_cast<SCEVUnknown>(Unwrapped)) {
      Value *V = Unknown->getValue();

      // Constants and globals are invariant.
      if (isa<Constant>(V) || isa<GlobalVariable>(V)) {
        VisitingSCEVs.erase(CurS);
        return true;
      }

      // Function arguments are loop-invariant for all loops.
      if (isa<Argument>(V)) {
        VisitingSCEVs.erase(CurS);
        return true;
      }

      if (!VisitingValues.insert(V).second) {
        VisitingSCEVs.erase(CurS);
        return true; // break value-level cycle conservatively
      }

      // Check if this value is defined outside the loop.
      if (Instruction *I = dyn_cast<Instruction>(V)) {
        if (!L->contains(I->getParent())) {
          VisitingValues.erase(V);
          VisitingSCEVs.erase(CurS);
          return true;
        }

        // Calls inside loop are not effectively invariant.
        if (isa<CallInst>(I) || isa<InvokeInst>(I)) {
          LLVM_DEBUG(dbgs() << "  Value is a call instruction inside loop, NOT invariant: "
                            << *I << "\n");
          VisitingValues.erase(V);
          VisitingSCEVs.erase(CurS);
          return false;
        }

        // Instructions with side effects/memory reads are not invariant,
        // except loads from effectively invariant addresses.
        if (I->mayHaveSideEffects() || I->mayReadFromMemory()) {
          if (LoadInst *Load = dyn_cast<LoadInst>(I)) {
            Value *Ptr = Load->getPointerOperand();
            const SCEV *PtrSCEV = SE.getSCEV(Ptr);

            if (IsInvariant(PtrSCEV)) {
              LLVM_DEBUG(dbgs() << "  Load from effectively invariant address: "
                                << *Load << "\n");
              VisitingValues.erase(V);
              VisitingSCEVs.erase(CurS);
              return true;
            }
          }

          LLVM_DEBUG(dbgs() << "  Instruction has side effects or reads memory, NOT invariant: "
                            << *I << "\n");
          VisitingValues.erase(V);
          VisitingSCEVs.erase(CurS);
          return false;
        }

        // If defined inside loop, check if it only depends on loop-invariant values.
        for (Use &U : I->operands()) {
          Value *Operand = U.get();
          const SCEV *OpSCEV = SE.getSCEV(Operand);
          if (!IsInvariant(OpSCEV)) {
            VisitingValues.erase(V);
            VisitingSCEVs.erase(CurS);
            return false;
          }
        }

        VisitingValues.erase(V);
        VisitingSCEVs.erase(CurS);
        return true;
      }

      VisitingValues.erase(V);
      VisitingSCEVs.erase(CurS);
      return false;
    }

    VisitingSCEVs.erase(CurS);
    return false;
  };

  return IsInvariant(S);
}

Value *InterStellarStreamAnalyzer::extractDynamicValue(const SCEV *S, Loop *L) {
  // Strategy: For a dynamic SCEV expression like (N+M), find the instruction
  // that computes this value. This instruction will be materialized into a
  // register during code generation.
  
  // Unwrap any cast expressions
  S = stripSCEVCasts(S);
  
  // If it's a simple unknown (single variable), return it directly
  if (const SCEVUnknown *Unknown = dyn_cast<SCEVUnknown>(S)) {
    return Unknown->getValue();
  }
  
  // For AddRecExpr (induction variables), find the PHI or computed value
  // For nested loops, outer-loop AddRecExprs represent loop-invariant base addresses
  // For A[i*M + j], the base is {A,+,M*4}<%outer> which is computed once per outer iteration
  if (const SCEVAddRecExpr *AR = dyn_cast<SCEVAddRecExpr>(S)) {
    const Loop *ARLoop = AR->getLoop();
    
    // Search for the value computing this AddRecExpr
    // In optimized code, this is often stored in an invariant GEP instruction
    BasicBlock *Preheader = L->getLoopPreheader();
    BasicBlock *Header = L->getHeader();
    
    // Lambda to find an instruction computing the AddRecExpr value
    auto findARValue = [&](BasicBlock *BB) -> Value * {
      if (!BB) return nullptr;
      for (Instruction &I : *BB) {
        // Skip void-type instructions
        if (!SE.isSCEVable(I.getType()))
          continue;
        
        const SCEV *InstSCEV = SE.getSCEV(&I);
        
        // Direct match
        if (InstSCEV == S) {
          LLVM_DEBUG(dbgs() << "  Found instruction for AddRecExpr: " << I << "\n");
          return &I;
        }
        
        // For GEP instructions, check if they compute the address we need
        if (GetElementPtrInst *GEP = dyn_cast<GetElementPtrInst>(&I)) {
          // GEP might be the invariant base pointer
          if (InstSCEV == S) {
            return GEP;
          }
        }
      }
      return nullptr;
    };
    
    // Try preheader first (where loop-invariant values are hoisted)
    if (Value *V = findARValue(Preheader))
      return V;
    
    // Try header (where PHI nodes live)
    if (Value *V = findARValue(Header))
      return V;
    
    // If we can't find a specific instruction, try to find the PHI node
    // that represents the induction variable for this AddRecExpr
    if (ARLoop) {
      BasicBlock *ARHeader = ARLoop->getHeader();
      if (ARHeader) {
        for (PHINode &PHI : ARHeader->phis()) {
          const SCEV *PhiSCEV = SE.getSCEV(&PHI);
          if (PhiSCEV == S) {
            LLVM_DEBUG(dbgs() << "  Found PHI for AddRecExpr: " << PHI << "\n");
            return &PHI;
          }
        }
      }
    }
    
    // Fallback: create a symbolic representation
    // The SCEV expander can materialize this value if needed
    LLVM_DEBUG(dbgs() << "  Could not find concrete value for AddRecExpr: " << *S << "\n");
    // Return nullptr and let the caller handle it
    return nullptr;
  }
  
  // For composite expressions (e.g., N+M, i*j), we need to find the instruction
  // that computes this expression. Search in loop preheader and header.
  BasicBlock *Preheader = L->getLoopPreheader();
  BasicBlock *Header = L->getHeader();
  
  // Lambda to search for an instruction whose SCEV matches or contains the target
  auto findMatchingInstruction = [&](BasicBlock *BB, const SCEV *Target) -> Value * {
    if (!BB) return nullptr;
    for (Instruction &I : *BB) {
      // Skip PHI nodes in header (they're induction variables)
      if (isa<PHINode>(I) && BB == Header)
        continue;
      
      // Skip instructions with non-SCEVable types (void, i1, etc.)
      if (!SE.isSCEVable(I.getType()))
        continue;
      
      const SCEV *InstSCEV = SE.getSCEV(&I);
      
      // Unwrap casts from InstSCEV for comparison
      InstSCEV = stripSCEVCasts(InstSCEV);
      
      if (InstSCEV == Target) {
        LLVM_DEBUG(dbgs() << "  Found instruction for SCEV: " << I << "\n");
        return &I;
      }
    }
    return nullptr;
  };
  
  // Try to find an instruction computing the exact SCEV
  if (Value *V = findMatchingInstruction(Preheader, S))
    return V;
  if (Value *V = findMatchingInstruction(Header, S))
    return V;
  
  // If the SCEV is complex (contains constants, casts, etc.), try to find
  // the "core" dynamic expression within it.
  // For example, from "(1 + (2 * ((1 smax (N+M)) /u 2)))", extract "(N+M)"
  
  // Recursively search for SCEVAddExpr or SCEVMulExpr containing only dynamic values.
  // With WantPointer, only pointer-typed leaves qualify: a stream base is an
  // address, so a composite like (row_offset + array_start) must yield the
  // pointer leaf rather than an i32 dimension living in the offset term.
  std::function<const SCEV*(const SCEV*, bool)> findDynamicCore =
      [&](const SCEV *Current, bool WantPointer) -> const SCEV* {
    // If it's a simple unknown, that's a dynamic value
    if (isa<SCEVUnknown>(Current)) {
      if (WantPointer && !Current->getType()->isPointerTy())
        return nullptr;
      return Current;
    }

    // For Add/Mul expressions, check if they contain multiple dynamic operands
    if (const SCEVAddExpr *Add = dyn_cast<SCEVAddExpr>(Current)) {
      // Count dynamic operands
      SmallVector<const SCEV *, 4> DynamicOps;
      for (const SCEV *Op : Add->operands()) {
        Op = stripSCEVCasts(Op);
        if (isa<SCEVUnknown>(Op) &&
            (!WantPointer || Op->getType()->isPointerTy()))
          DynamicOps.push_back(Op);
      }

      // If we have multiple dynamic operands (e.g., N+M), this is our target
      if (DynamicOps.size() >= 2) {
        // Try to find an instruction computing this Add expression
        if (Value *V = findMatchingInstruction(Preheader, Add))
          return SE.getSCEV(V);
        if (Value *V = findMatchingInstruction(Header, Add))
          return SE.getSCEV(V);
      }
    }

    // Recursively search operands
    if (const SCEVNAryExpr *NAry = dyn_cast<SCEVNAryExpr>(Current)) {
      for (const SCEV *Op : NAry->operands()) {
        if (const SCEV *Core = findDynamicCore(Op, WantPointer))
          return Core;
      }
    } else if (const SCEVCastExpr *Cast = dyn_cast<SCEVCastExpr>(Current)) {
      return findDynamicCore(Cast->getOperand(), WantPointer);
    } else if (const SCEVUDivExpr *UDiv = dyn_cast<SCEVUDivExpr>(Current)) {
      if (const SCEV *Core = findDynamicCore(UDiv->getLHS(), WantPointer))
        return Core;
      if (const SCEV *Core = findDynamicCore(UDiv->getRHS(), WantPointer))
        return Core;
    }

    return nullptr;
  };

  // Try to find the core dynamic expression, preferring pointer leaves.
  for (bool WantPointer : {true, false}) {
    if (const SCEV *Core = findDynamicCore(S, WantPointer)) {
      if (const SCEVUnknown *U = dyn_cast<SCEVUnknown>(Core))
        return U->getValue();

      // Try to find an instruction computing this core expression
      if (Value *V = findMatchingInstruction(Preheader, Core))
        return V;
      if (Value *V = findMatchingInstruction(Header, Core))
        return V;
    }
  }
  
  // If we still can't find it, fall back to extracting the first
  // dynamic operand (leaf value). This is suboptimal but prevents crashes.
  LLVM_DEBUG(dbgs() << "  Warning: Could not find instruction for SCEV, "
                    << "falling back to leaf value extraction\n");
  
  if (const SCEVAddExpr *Add = dyn_cast<SCEVAddExpr>(S)) {
    for (const SCEV *Op : Add->operands()) {
      if (Value *V = extractDynamicValue(Op, L))
        return V;
    }
  } else if (const SCEVMulExpr *Mul = dyn_cast<SCEVMulExpr>(S)) {
    for (const SCEV *Op : Mul->operands()) {
      if (Value *V = extractDynamicValue(Op, L))
        return V;
    }
  } else if (const SCEVSMaxExpr *SMax = dyn_cast<SCEVSMaxExpr>(S)) {
    for (const SCEV *Op : SMax->operands()) {
      if (Value *V = extractDynamicValue(Op, L))
        return V;
    }
  } else if (const SCEVUMaxExpr *UMax = dyn_cast<SCEVUMaxExpr>(S)) {
    for (const SCEV *Op : UMax->operands()) {
      if (Value *V = extractDynamicValue(Op, L))
        return V;
    }
  }
  
  return nullptr;
}

int64_t InterStellarStreamAnalyzer::getTypeSizeInBytes(Type *Ty) {
  const DataLayout &DL = F.getDataLayout();
  return DL.getTypeStoreSize(Ty).getFixedValue();
}

void InterStellarStreamAnalyzer::createDirectStream(const SCEV *Base, 
                                                    int64_t Stride, Loop *L,
                                                    Instruction *MemInst,
                                                    int64_t ConstantOffset,
                                                    Value *ExplicitBaseValue) {
  // Apply constant offset if present
  const SCEV *AdjustedBase = Base;
  if (ConstantOffset != 0) {
    LLVM_DEBUG(dbgs() << "  Applying constant offset: " << ConstantOffset 
                      << " bytes to base\n");
    Type *PtrTy = SE.getEffectiveSCEVType(Base->getType());
    const SCEV *OffsetSCEV = SE.getConstant(PtrTy, ConstantOffset);
    AdjustedBase = SE.getAddExpr(Base, OffsetSCEV);
  }
  
  // Create stream descriptor
  DirectStreamDescriptor DS;
  DS.StreamID = NextStreamID++;
  DS.LoopID = getOrCreateLoopID(L);
  DS.BaseAddress = AdjustedBase;
  DS.Stride = Stride;
  DS.IsBaseLinked = isValueDynamic(AdjustedBase);
  DS.MemInst = MemInst;
  DS.Loc = MemInst->getDebugLoc();
  
  // Handle dynamic base address
  if (DS.IsBaseLinked) {
    // If an explicit base value is provided (e.g., %invariant.gep for nested loops),
    // use it directly instead of trying to extract from SCEV
    Value *BaseVal = ExplicitBaseValue;
    if (!BaseVal) {
      // A composite base — any AddExpr, e.g. (8 + %A) or a row-variant
      // (row_offset + %D2A) — is materialized so the link holds the exact
      // address instead of one operand of the sum. Expanding an expression
      // whose values are not defined above the preheader would yield poison,
      // so an unexpandable base drops the stream: its address cannot be
      // named at the anchor point where links are configured.
      BasicBlock *Preheader = L->getLoopPreheader();
      if (isa<SCEVAddExpr>(AdjustedBase)) {
        if (Preheader) {
          SCEVExpander Expander(SE, "interstellar");
          Expander.setInsertPoint(Preheader->getTerminator());
          if (!Expander.isSafeToExpandAt(AdjustedBase,
                                         Preheader->getTerminator())) {
            LLVM_DEBUG(dbgs()
                       << "  Base is not expandable at the preheader "
                          "(loop-variant parts), dropping stream\n");
            return;
          }
          BaseVal = Expander.expandCodeFor(
              AdjustedBase, PointerType::getUnqual(F.getContext()),
              Preheader->getTerminator());
          LLVM_DEBUG(dbgs() << "  Materialized offset-adjusted base: "
                            << *BaseVal << "\n");
        } else {
          LLVM_DEBUG(dbgs()
                     << "  Warning: Loop has no preheader, cannot materialize "
                        "base\n");
        }
      }
      if (!BaseVal)
        BaseVal = extractDynamicValue(AdjustedBase, L);
    }

    // A link must hold an address. A non-pointer "base" (e.g. an i32
    // dimension that leaked out of the offset term) or a missing one cannot
    // back a stream — emit no descriptor rather than a bogus one.
    if (!BaseVal || !BaseVal->getType()->isPointerTy()) {
      LLVM_DEBUG(dbgs() << "  Dropping stream: base value "
                        << (BaseVal ? "is not a pointer" : "not found")
                        << "\n");
      return;
    }

    DS.BaseAddressValue = BaseVal;
    unsigned Size = sizeInBytesForLink(BaseVal->getType(), F.getDataLayout());
    DS.LinkID = getOrCreateLinkID(BaseVal, Size);
    ++NumDynamicBases;
  } else if (isa<SCEVAddExpr>(AdjustedBase)) {
    // A non-linked composite base such as (20 + @GlobalArray) still needs a
    // concrete IR value for emission; materialize it where links live.
    if (BasicBlock *Preheader = L->getLoopPreheader()) {
      SCEVExpander Expander(SE, "interstellar");
      Expander.setInsertPoint(Preheader->getTerminator());
      if (Expander.isSafeToExpandAt(AdjustedBase, Preheader->getTerminator()))
        DS.BaseAddressValue = Expander.expandCodeFor(
            AdjustedBase, PointerType::getUnqual(F.getContext()),
            Preheader->getTerminator());
    }
  }
  
  DirectStreams.push_back(DS);
  InstToStreamIDMap[MemInst] = DS.StreamID;
  ++NumDirectStreams;
  
  LLVM_DEBUG({
    dbgs() << "  Created Direct Stream:\n";
    dbgs() << "    Stream ID: " << DS.StreamID << "\n";
    dbgs() << "    Loop ID: " << DS.LoopID << "\n";
    dbgs() << "    Base: " << *AdjustedBase << "\n";
    if (ConstantOffset != 0) {
      dbgs() << "    Constant Offset: " << ConstantOffset << " bytes\n";
    }
    if (ExplicitBaseValue) {
      dbgs() << "    Explicit Base Value: " << *ExplicitBaseValue << "\n";
    }
    dbgs() << "    Stride: " << Stride << " bytes\n";
    dbgs() << "    Base Linked: " << DS.IsBaseLinked << "\n";
  });
}

void InterStellarStreamAnalyzer::print(raw_ostream &OS) const {
  OS << "\n";
  OS << "╔═══════════════════════════════════════════════════════════════╗\n";
  OS << "║     InterStellar Stream Analysis Results for Function: " << F.getName() << " ║\n";
  OS << "╚═══════════════════════════════════════════════════════════════╝\n\n";

  OS << " Statistics:\n";
  OS << "   • Loops analyzed: " << LoopDescriptors.size() << "\n";
  OS << "   • Direct streams: " << DirectStreams.size() << "\n";
  OS << "   • Indirect streams: " << IndirectStreams.size() << "\n";
  OS << "   • Link variables: " << LinkVariables.size() << "\n";

  // Reuse the shared per-descriptor dump (defined below) so the Pass-1
  // summary and the final summary render identically.
  printAllDescriptors(OS, LoopDescriptors, DirectStreams, IndirectStreams,
                      LinkVariables);
}

} // anonymous namespace

//===----------------------------------------------------------------------===//
// Pass 2 Structures
//===----------------------------------------------------------------------===//

namespace {

/// Merge candidate from linearization analysis (Stage 1.2)
struct StreamMergeCandidate {
  unsigned StreamID;           // Stream that may be linearized
  unsigned InnerLoopID;        // Loop containing the stream
  unsigned OuterLoopID;        // Parent loop for potential merge
  SmallVector<unsigned, 2> RequiredDimensions; // For multi-dimensional arrays
};

} // anonymous namespace

//===----------------------------------------------------------------------===//
// Helper Functions for Descriptor Printing
//===----------------------------------------------------------------------===//

namespace {

/// Whether a loop descriptor should be shown as nested under a parent.
///
/// ParentLoopID == 0 is ambiguous in the descriptor encoding: it means "no
/// parent" only for Loop #0 itself (and for fully-merged virtual loops); for
/// every other regular loop it means the parent is Loop #0.
static bool loopHasVisibleParent(const LoopDescriptor &LD) {
  if (LD.ParentLoopID > 0)
    return true;
  if (LD.ParentLoopID == 0 && LD.LoopID != 0 && !LD.IsVirtual)
    return true; // Regular loop: parent is Loop #0
  if (LD.ParentLoopID == 0 && LD.IsVirtual && LD.MergedToOuterLoop > 0)
    return true; // Partially merged virtual loop: parent is Loop #0
  return false;
}

static void printLoopDescriptor(raw_ostream &OS, const LoopDescriptor &LD) {
  OS << "Loop ID: " << LD.LoopID << "\n";

  if (LD.Loc) {
    OS << "  ├─ Source Location: ";
    LD.Loc.print(OS);
    OS << "\n";
  }

  if (loopHasVisibleParent(LD))
    OS << "  ├─ Parent Loop: " << LD.ParentLoopID << " [Nesting Level]\n";

  OS << "  ├─ Start Value: ";
  if (LD.StartValue)
    OS << *LD.StartValue;
  else
    OS << "unknown";
  if (LD.IsStartLinked)
    OS << "  [SL=1, LinkID=" << LD.StartLinkID << "]";
  else
    OS << "  [SL=0, Constant]";
  OS << "\n";

  OS << "  ├─ End Value:   ";
  // Prefer the SCEV form: for merged (virtual) loops it renders the folded
  // product, e.g. (%N * %M * %P * %Q), instead of the materialized IR mul
  // chain (%merged_loop_bound3 = mul i32 %merged_loop_bound2, %N).
  if (LD.EndValue)
    OS << *LD.EndValue;
  else if (LD.EndValueDynamic && LD.IsEndLinked)
    OS << *LD.EndValueDynamic;
  else
    OS << "unknown";
  if (LD.IsEndLinked)
    OS << "   [EL=1, Dynamic, LinkID=" << LD.EndLinkID << "]";
  else
    OS << "  [EL=0, Constant]";
  OS << "\n";

  OS << "  └─ Step Value:  ";
  if (LD.StepValue)
    OS << *LD.StepValue;
  else
    OS << "unknown";
  OS << "\n\n";
}

static void printDirectStreamDescriptor(raw_ostream &OS,
                                        const DirectStreamDescriptor &DS) {
  OS << "Stream ID: " << DS.StreamID << " (Loop " << DS.LoopID << ")\n";

  if (DS.Loc) {
    OS << "  ├─ Source Location: ";
    DS.Loc.print(OS);
    OS << "\n";
  }

  OS << "  ├─ Base Address: ";
  if (DS.BaseAddress)
    OS << *DS.BaseAddress;
  else
    OS << "unknown";
  if (DS.IsBaseLinked)
    OS << "   [BL=1, Dynamic, LinkID=" << DS.LinkID << "]";
  OS << "\n";

  OS << "  ├─ Stride:       " << DS.Stride << " bytes\n";

  if (DS.MemInst)
    OS << "  └─ Source:       " << *DS.MemInst << "\n";

  OS << "\n";
}

static void printIndirectStreamDescriptor(raw_ostream &OS,
                                          const IndirectStreamDescriptor &IS) {
  OS << "Stream ID: " << IS.StreamID << " (Loop " << IS.LoopID << ")\n";

  if (IS.Loc) {
    OS << "  ├─ Source Location: ";
    IS.Loc.print(OS);
    OS << "\n";
  }

  // Print the SCEV base (like the direct-stream printer): BaseAddressValue is
  // only populated for linked/dynamic bases, so static globals would print
  // blank if we preferred it.
  OS << "  ├─ Base Address:   ";
  if (IS.BaseAddress)
    OS << *IS.BaseAddress;
  else
    OS << "unknown";
  if (IS.IsBaseLinked)
    OS << "   [BL=1, Dynamic, LinkID=" << IS.LinkID << "]";
  OS << "\n";

  OS << "  ├─ Element Size:   " << IS.ElementSize << " bytes\n";

  // Statically-known extent of the target array (0 = unknown, e.g. pointer
  // parameter). Report it in elements when it divides evenly.
  OS << "  ├─ Array Bounds:   ";
  if (IS.StreamSize != 0) {
    if (IS.ElementSize > 0 && IS.StreamSize % IS.ElementSize == 0)
      OS << IS.StreamSize / IS.ElementSize << " elements";
    else
      OS << IS.StreamSize << " bytes";
    OS << " (" << IS.StreamSize << " bytes)";
  } else {
    OS << "unknown";
  }
  OS << "\n";

  if (IS.IsIndexComputed)
    OS << "  ├─ Index Type:     COMPUTED/RANDOM (no stream dependency)\n";
  else
    OS << "  ├─ Index Stream:   Stream #" << IS.BaseStreamID
       << " (indices provided by this stream)\n";

  if (IS.MemInst)
    OS << "  └─ Source:         " << *IS.MemInst << "\n";

  OS << "\n";
}

static void printLinkVariable(raw_ostream &OS, const LinkVariableDescriptor &LV) {
  OS << "Link ID: " << LV.LinkID << "\n";
  OS << "  ├─ IR Value:  ";
  if (LV.DynamicValue)
    OS << *LV.DynamicValue;
  else
    OS << "unknown";
  OS << "\n";
  OS << "  └─ Size:      " << LV.SizeInBytes << " bytes\n";
  OS << "\n";
}

/// Print all loop and stream descriptors (Pass-1 summary and final summary).
void printAllDescriptors(raw_ostream &OS,
                        const SmallVectorImpl<LoopDescriptor> &Loops,
                        const SmallVectorImpl<DirectStreamDescriptor> &Streams,
                        const SmallVectorImpl<IndirectStreamDescriptor> &IndirectStreams,
                        const SmallVectorImpl<LinkVariableDescriptor> &LinkVars) {
  OS << "\n╔═══════════════════════════════════════════════════════════════╗\n";
  OS << "║     Final Stream and Loop Descriptors                          ║\n";
  OS << "╚═══════════════════════════════════════════════════════════════╝\n";

  if (!Loops.empty()) {
    OS << "\n Loop Descriptors:\n";
    OS << "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n";
    // Virtual loops are presented as normal loops (no special marking).
    for (const auto &LD : Loops)
      printLoopDescriptor(OS, LD);
  }

  if (!Streams.empty()) {
    OS << "  Direct Streams:\n";
    OS << "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n";
    for (const auto &DS : Streams)
      printDirectStreamDescriptor(OS, DS);
  }

  if (!IndirectStreams.empty()) {
    OS << "  Indirect Streams:\n";
    OS << "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n";
    for (const auto &IS : IndirectStreams)
      printIndirectStreamDescriptor(OS, IS);
  }

  if (!LinkVars.empty()) {
    OS << "  Link Variable Descriptors:\n";
    OS << "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n";
    for (const auto &LV : LinkVars)
      printLinkVariable(OS, LV);
  }

  OS << "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n";
}

} // anonymous namespace

//===----------------------------------------------------------------------===//
// Forward Declarations
//===----------------------------------------------------------------------===//

static void generateHardwareDescriptorIR(
    Function &F,
    const SmallVectorImpl<LoopDescriptor> &Loops,
    const SmallVectorImpl<DirectStreamDescriptor> &DirectStreams,
    const SmallVectorImpl<IndirectStreamDescriptor> &IndirectStreams,
    const SmallVectorImpl<LinkVariableDescriptor> &LinkVars);

//===----------------------------------------------------------------------===//
// InterStellarAnalysisPass Implementation (New Pass Manager)
//===----------------------------------------------------------------------===//

//===----------------------------------------------------------------------===//
// Pipeline stage functions
//===----------------------------------------------------------------------===//
//
// InterStellarAnalysisPass::run() is a thin driver over these stages, executed
// in order:
//
//   deduplicateDirectStreams / deduplicateIndirectStreams   (Stage 1.1)
//   analyzeLinearizationFeasibility                         (Stage 1.2)
//   removeStreamLessLoops                                   (Stage 1.5)
//   applyLoopMerges                                         (Stage 3)
//   removeUnusedLoops                                       (Stage 3.1)
//
// All stage state lives in InterstellarPipelineContext so code motion from the
// former monolithic run() stays literal.

/// Shared state for the intraprocedural pipeline stages of the pass.
struct InterstellarPipelineContext {
  Function &F;
  ScalarEvolution &SE;
  DominatorTree &DT;

  SmallVector<DirectStreamDescriptor, 8> Streams;
  SmallVector<IndirectStreamDescriptor, 4> IndirectStreams;
  SmallVector<LoopDescriptor, 4> Loops;
  SmallVector<LinkVariableDescriptor, 4> LinkVars;
  SmallVector<StreamMergeCandidate, 4> MergeCandidates;
  DenseMap<unsigned, const LoopDescriptor *> LoopIDToDescriptor;
  unsigned NextLinkID = 0;
  SmallVector<unsigned, 4> AppliedMerges;

  InterstellarPipelineContext(Function &F, ScalarEvolution &SE, DominatorTree &DT)
      : F(F), SE(SE), DT(DT) {}
};

static const SCEVAddRecExpr *findAddRecForLoop(const SCEV *S,
                                            const Loop *TargetLoop) {
  if (!S || !TargetLoop)
    return nullptr;

  // Direct match: top-level is AddRecExpr for target loop
  if (const SCEVAddRecExpr *AR = dyn_cast<SCEVAddRecExpr>(S)) {
    if (AR->getLoop() == TargetLoop)
      return AR;
    // For nested AddRecs, search the start value (base)
    // Example: {{%base,+,400}<%Loop0>,+,40}<%Loop1>
    // When searching for Loop0, we need to look inside the outer AddRec's start value
    if (auto *Found = findAddRecForLoop(AR->getStart(), TargetLoop))
      return Found;
  }

  // Search within AddExpr operands (e.g., "base + offset")
  if (const SCEVAddExpr *Add = dyn_cast<SCEVAddExpr>(S)) {
    for (const SCEV *Op : Add->operands()) {
      if (const SCEVAddRecExpr *AR = dyn_cast<SCEVAddRecExpr>(Op)) {
        if (AR->getLoop() == TargetLoop)
          return AR;
      }
      // Recurse into complex operands
      if (auto *Found = findAddRecForLoop(Op, TargetLoop))
        return Found;
    }
  }

  // Search within MulExpr operands (e.g., "4 * {0,+,stride}")
  if (const SCEVMulExpr *Mul = dyn_cast<SCEVMulExpr>(S)) {
    for (const SCEV *Op : Mul->operands()) {
      if (const SCEVAddRecExpr *AR = dyn_cast<SCEVAddRecExpr>(Op)) {
        if (AR->getLoop() == TargetLoop)
          return AR;
      }
      // Recurse into complex operands
      if (auto *Found = findAddRecForLoop(Op, TargetLoop))
        return Found;
    }
  }

  // Search through type casts (sext, zext, trunc)
  if (const SCEVCastExpr *Cast = dyn_cast<SCEVCastExpr>(S)) {
    return findAddRecForLoop(Cast->getOperand(), TargetLoop);
  }

  return nullptr;
}

/// Stage 1.1 (direct): group same-signature streams (LoopID, base SCEV,
/// stride) and keep only the dominating instruction's stream.
static void deduplicateDirectStreams(InterstellarPipelineContext &Ctx) {
  LLVM_DEBUG(dbgs() << "\n[Stage 1.1] Direct Stream Redundancy Analysis\n");

  SmallVector<SmallVector<unsigned, 2>, 4> StreamGroups;
  SmallVector<bool, 8> Processed(Ctx.Streams.size(), false);

for (size_t i = 0; i < Ctx.Streams.size(); ++i) {
  if (Processed[i])
    continue;

  const auto &DS_i = Ctx.Streams[i];
  SmallVector<unsigned, 2> Group;
  Group.push_back(i);
  Processed[i] = true;

  // Find all streams with matching signature
  for (size_t j = i + 1; j < Ctx.Streams.size(); ++j) {
    if (Processed[j])
      continue;

    const auto &DS_j = Ctx.Streams[j];
    if (DS_i.LoopID == DS_j.LoopID &&
        DS_i.BaseAddress == DS_j.BaseAddress &&
        DS_i.Stride == DS_j.Stride) {
      Group.push_back(j);
      Processed[j] = true;
    }
  }

  if (Group.size() > 1) {
    StreamGroups.push_back(std::move(Group));
  }
}

// Track which streams should be removed (redundant streams)
SmallPtrSet<const DirectStreamDescriptor *, 8> StreamsToRemove;
DenseMap<unsigned, unsigned> RemovedToPrimary; // duplicate StreamID -> primary

for (const auto &Group : StreamGroups) {
  LLVM_DEBUG(dbgs() << "  Found " << Group.size() 
                    << " duplicate streams:\n");

  // Find dominating instruction
  Instruction *DominatingInst = nullptr;
  unsigned PrimaryIdx = Group[0];

  for (unsigned Idx : Group) {
    LLVM_DEBUG(dbgs() << "    Stream #" << Ctx.Streams[Idx].StreamID);
    // Print source location if available
    if (Ctx.Streams[Idx].Loc) {
      LLVM_DEBUG(dbgs() << " at ");
      LLVM_DEBUG(Ctx.Streams[Idx].Loc.print(dbgs()));
    }
    LLVM_DEBUG(dbgs() << "\n");

    Instruction *CurrentInst = Ctx.Streams[Idx].MemInst;
    if (!CurrentInst)
      continue;

    if (!DominatingInst || Ctx.DT.dominates(CurrentInst, DominatingInst)) {
      DominatingInst = CurrentInst;
      PrimaryIdx = Idx;
    }
  }

  LLVM_DEBUG(dbgs() << "    → Primary stream: #" << Ctx.Streams[PrimaryIdx].StreamID);
  if (Ctx.Streams[PrimaryIdx].Loc) {
    LLVM_DEBUG(dbgs() << " at ");
    LLVM_DEBUG(Ctx.Streams[PrimaryIdx].Loc.print(dbgs()));
  }
  LLVM_DEBUG(dbgs() << "\n");

  // Mark all non-primary streams for removal
  for (unsigned Idx : Group) {
    if (Idx != PrimaryIdx) {
      StreamsToRemove.insert(&Ctx.Streams[Idx]);
      RemovedToPrimary[Ctx.Streams[Idx].StreamID] =
          Ctx.Streams[PrimaryIdx].StreamID;
    }
  }
}

// Filter out redundant streams - keep only primary streams
SmallVector<DirectStreamDescriptor, 8> FilteredStreams;
for (const auto &DS : Ctx.Streams) {
  if (!StreamsToRemove.count(&DS)) {
    FilteredStreams.push_back(DS);
  }
}

// Replace Ctx.Streams with the filtered list for subsequent stages
Ctx.Streams = std::move(FilteredStreams);

// Indirect streams cite their index source by StreamID. A removed duplicate
// fed the same indices as its primary, so citations follow the primary —
// otherwise emission cannot translate them and leaks SourceID=0.
for (auto &IDS : Ctx.IndirectStreams) {
  auto It = RemovedToPrimary.find(IDS.BaseStreamID);
  if (It != RemovedToPrimary.end())
    IDS.BaseStreamID = It->second;
}
}

/// Stage 1.1 (indirect): same-signature grouping with load-over-store
/// preference for the primary. Runs only when direct streams exist —
/// call sites keep it nested in the !Streams.empty() guard (pre-existing).
static void deduplicateIndirectStreams(InterstellarPipelineContext &Ctx) {
// Stage 1.1: Also analyze indirect stream redundancy
// Indirect streams should be deduplicated based on base address, element size,
// and index source (either a specific stream ID or computed/random)

if (!Ctx.IndirectStreams.empty()) {
  LLVM_DEBUG(dbgs() << "\n[Stage 1.1] Indirect Stream Redundancy Analysis\n");

  SmallVector<SmallVector<unsigned, 2>, 4> IndirectStreamGroups;
  SmallVector<bool, 8> IndirectProcessed(Ctx.IndirectStreams.size(), false);

  // Track which indirect streams should be removed (redundant streams)
  SmallPtrSet<const IndirectStreamDescriptor *, 8> IndirectStreamsToRemove;
  DenseMap<unsigned, unsigned> RemovedIndirectToPrimary; // dup StreamID -> primary

  for (size_t i = 0; i < Ctx.IndirectStreams.size(); ++i) {
    if (IndirectProcessed[i])
      continue;

    const auto &IDS_i = Ctx.IndirectStreams[i];
    SmallVector<unsigned, 2> Group;
    Group.push_back(i);
    IndirectProcessed[i] = true;

    // Find all indirect streams with matching signature
    // Signature: {LoopID, BaseAddress, ElementSize, IsIndexComputed, BaseStreamID}
    for (size_t j = i + 1; j < Ctx.IndirectStreams.size(); ++j) {
      if (IndirectProcessed[j])
        continue;

      const auto &IDS_j = Ctx.IndirectStreams[j];

      // Check if signatures match
      if (IDS_i.LoopID == IDS_j.LoopID &&
          IDS_i.BaseAddress == IDS_j.BaseAddress &&
          IDS_i.ElementSize == IDS_j.ElementSize &&
          IDS_i.IsIndexComputed == IDS_j.IsIndexComputed &&
          (IDS_i.IsIndexComputed || IDS_i.BaseStreamID == IDS_j.BaseStreamID)) {
        Group.push_back(j);
        IndirectProcessed[j] = true;
      }
    }

    if (Group.size() > 1) {
      IndirectStreamGroups.push_back(std::move(Group));
    }
  }

  for (const auto &Group : IndirectStreamGroups) {
    LLVM_DEBUG(dbgs() << "  Found " << Group.size() 
                      << " duplicate indirect streams:\n");

    // Find dominating instruction (prefer LoadInst as primary)
    Instruction *DominatingInst = nullptr;
    unsigned PrimaryIdx = Group[0];
    bool PreferLoad = false;

    for (unsigned Idx : Group) {
      LLVM_DEBUG(dbgs() << "    Indirect Stream #" << Ctx.IndirectStreams[Idx].StreamID);
      // Print source location if available
      if (Ctx.IndirectStreams[Idx].Loc) {
        LLVM_DEBUG(dbgs() << " at ");
        LLVM_DEBUG(Ctx.IndirectStreams[Idx].Loc.print(dbgs()));
      }
      LLVM_DEBUG(dbgs() << "\n");

      Instruction *CurrentInst = Ctx.IndirectStreams[Idx].MemInst;
      if (!CurrentInst)
        continue;

      if (!DominatingInst) {
        DominatingInst = CurrentInst;
        PrimaryIdx = Idx;
        PreferLoad = isa<LoadInst>(CurrentInst);
      } else if (Ctx.DT.dominates(CurrentInst, DominatingInst)) {
        // This instruction dominates the current primary
        DominatingInst = CurrentInst;
        PrimaryIdx = Idx;
        PreferLoad = isa<LoadInst>(CurrentInst);
      } else if (Ctx.DT.dominates(DominatingInst, CurrentInst)) {
        // Current primary dominates this one - keep primary unless we prefer loads
        if (!PreferLoad && isa<LoadInst>(CurrentInst)) {
          // Same dominance level, but prefer load over store
          DominatingInst = CurrentInst;
          PrimaryIdx = Idx;
          PreferLoad = true;
        }
      } else {
        // No dominance relationship - prefer LoadInst as primary
        if (!PreferLoad && isa<LoadInst>(CurrentInst)) {
          DominatingInst = CurrentInst;
          PrimaryIdx = Idx;
          PreferLoad = true;
        }
      }
    }

    LLVM_DEBUG(dbgs() << "    → Primary indirect stream: #" 
                      << Ctx.IndirectStreams[PrimaryIdx].StreamID);
    if (Ctx.IndirectStreams[PrimaryIdx].Loc) {
      LLVM_DEBUG(dbgs() << " at ");
      LLVM_DEBUG(Ctx.IndirectStreams[PrimaryIdx].Loc.print(dbgs()));
    }
    LLVM_DEBUG(dbgs() << "\n");

    // Mark all non-primary indirect streams for removal
    for (unsigned Idx : Group) {
      if (Idx != PrimaryIdx) {
        IndirectStreamsToRemove.insert(&Ctx.IndirectStreams[Idx]);
        RemovedIndirectToPrimary[Ctx.IndirectStreams[Idx].StreamID] =
            Ctx.IndirectStreams[PrimaryIdx].StreamID;
      }
    }
  }

  // Filter out redundant indirect streams - keep only primary streams
  SmallVector<IndirectStreamDescriptor, 4> FilteredIndirectStreams;
  for (const auto &IDS : Ctx.IndirectStreams) {
    if (!IndirectStreamsToRemove.count(&IDS)) {
      FilteredIndirectStreams.push_back(IDS);
    }
  }

  // Replace Ctx.IndirectStreams with the filtered list for subsequent stages
  Ctx.IndirectStreams = std::move(FilteredIndirectStreams);

  // Chained indirects cite their source indirect by StreamID; follow removals
  // to the retained primary so emission can translate the citation.
  for (auto &IDS : Ctx.IndirectStreams) {
    auto It = RemovedIndirectToPrimary.find(IDS.BaseStreamID);
    if (It != RemovedIndirectToPrimary.end())
      IDS.BaseStreamID = It->second;
  }
}

}

/// Stage 1.2: walk streams upward through parent loops and record merge
/// candidates where multi-level linearization looks feasible.
static void analyzeLinearizationFeasibility(InterstellarPipelineContext &Ctx) {
// Stage 1.2: Analyze merge feasibility for nested loops
// Only run if there are streams to analyze
if (!Ctx.Streams.empty()) {
  LLVM_DEBUG(dbgs() << "\n[Stage 1.2] Linearization Feasibility Analysis\n");

for (const auto &DS : Ctx.Streams) {
  auto LoopIt = Ctx.LoopIDToDescriptor.find(DS.LoopID);
  if (LoopIt == Ctx.LoopIDToDescriptor.end())
    continue;

  const LoopDescriptor *CurrentLD = LoopIt->second;
  Loop *CurrentLoop = CurrentLD->L;

  if (!CurrentLoop)
    continue;

  if (!CurrentLoop->getParentLoop())
    continue;  // No parent loop, nothing to merge

  // Recursive multi-level analysis: Walk up the loop nest
  // For each parent loop, check if we can linearize at that level
  // Example: for i { for j { for k { A[i][j][k] } } }
  //   - Level 1: k→j (if P matches dimension)
  //   - Level 2: k-j→i (if M*P or just M matches dimension)

  Loop *ChildLoop = CurrentLoop;
  const LoopDescriptor *ChildLD = CurrentLD;
  const SCEV *CumulativeSpan = nullptr;
  SmallVector<unsigned, 4> RequiredDimensions;

  // Start with the innermost loop's trip count and stride
  // CRITICAL: Use the actual loop bound (EndValueDynamic) for symbolic comparison,
  // not the SCEV (EndValue) which might be a backedge-taken count.
  // For loop: for (k = 0; k < D3_dim3; k++)
  //   - EndValue SCEV might be: (zext %D3_dim3 to i64) or (%D3_dim3 - 1) 
  //   - EndValueDynamic is: %D3_dim3 (the actual IR value)
  //   - We want to use %D3_dim3 for comparisons
  const SCEV *InnerTripCount = ChildLD->EndValue;

  // If we have the dynamic value, create a SCEV from it for cleaner comparisons
  if (ChildLD->EndValueDynamic && ChildLD->IsEndLinked) {
    // Use the SCEV of the actual end value (the IR Value)
    // This gives us the clean symbolic expression without backedge adjustments
    const SCEV *DynamicSCEV = Ctx.SE.getSCEV(ChildLD->EndValueDynamic);
    if (DynamicSCEV) {
      InnerTripCount = DynamicSCEV;
      LLVM_DEBUG(dbgs() << "    Using dynamic end value for trip count: " 
                        << *InnerTripCount << "\n");
    }
  }

  if (!InnerTripCount)
    continue;

  // Track dimensions for this stream (used in Stage 2 interprocedural analysis)
  if (ChildLD->IsEndLinked) {
    RequiredDimensions.push_back(ChildLD->EndLinkID);
  }

  // Iterate through all parent loops (from immediate parent upward)
  while (ChildLoop->getParentLoop()) {
    Loop *ParentLoop = ChildLoop->getParentLoop();
    unsigned ParentLoopID = ChildLD->ParentLoopID;

    LLVM_DEBUG(dbgs() << "  Analyzing Stream #" << DS.StreamID 
                      << " (Loop #" << DS.LoopID << " → Loop #" 
                      << ParentLoopID << ")");
    if (DS.Loc) {
      LLVM_DEBUG(dbgs() << " at ");
      LLVM_DEBUG(DS.Loc.print(dbgs()));
    }
    LLVM_DEBUG(dbgs() << "\n");

    // Print full pointer SCEV for debugging
    LLVM_DEBUG(dbgs() << "    Full pointer SCEV: " << *DS.BaseAddress << "\n");

    // Calculate cumulative span for this nesting level
    // For first iteration: span = inner_trip_count * stride
    // For subsequent iterations: span = previous_span * current_trip_count
    LLVM_DEBUG(dbgs() << "    Inner stride: " << DS.Stride << " bytes\n");
    LLVM_DEBUG(dbgs() << "    Child trip count: " << *InnerTripCount << "\n");

    // Ensure both operands have the same type to avoid SCEV assertion failure
    Type *TripCountType = InnerTripCount->getType();
    const SCEV *InnerStrideSCEV = Ctx.SE.getConstant(TripCountType, DS.Stride);

    if (!CumulativeSpan) {
      // First level: Span = TripCount * Stride
      CumulativeSpan = Ctx.SE.getMulExpr(InnerTripCount, InnerStrideSCEV);
    } else {
      // Deeper level: Span = PreviousSpan * CurrentTripCount
      // Need to ensure types match
      if (CumulativeSpan->getType() != TripCountType) {
        CumulativeSpan = Ctx.SE.getSignExtendExpr(CumulativeSpan, TripCountType);
      }
      CumulativeSpan = Ctx.SE.getMulExpr(CumulativeSpan, InnerTripCount);
    }

    LLVM_DEBUG(dbgs() << "    Cumulative span at this level: " << *CumulativeSpan << "\n");

    // Extract parent loop step from base address using helper function
    LLVM_DEBUG(dbgs() << "    Analyzing SCEV structure...\n");

    const SCEV *BaseStep = nullptr;
    const SCEVAddRecExpr *ParentAddRec = findAddRecForLoop(DS.BaseAddress, ParentLoop);

    if (ParentAddRec && ParentAddRec->isAffine()) {
      // Found an AddRec for the parent loop - extract its step
      const SCEV *RawStep = ParentAddRec->getStepRecurrence(Ctx.SE);

      // Determine if step is already in bytes (pointer arithmetic) or index units
      // If the AddRec type is a pointer type, step is already in bytes
      // If the AddRec type is an integer type, step is in index units
      bool StepIsAlreadyInBytes = ParentAddRec->getType()->isPointerTy();

      LLVM_DEBUG(dbgs() << "      Parent step (raw): " << *RawStep << "\n");

      if (StepIsAlreadyInBytes) {
        // Step is already in bytes (e.g., {%ptr,+,40} for pointer arithmetic)
        BaseStep = RawStep;
        LLVM_DEBUG(dbgs() << "      Step is in bytes (pointer arithmetic)\n");
      } else {
        // Step is in index units (e.g., {0,+,%dim} for array indexing)
        // Need to multiply by element size to get byte step
        LLVM_DEBUG(dbgs() << "      Step is in index units (array indexing)\n");
        LLVM_DEBUG(dbgs() << "      Element size: " << DS.Stride << " bytes\n");

        Type *StepType = RawStep->getType();
        const SCEV *ElementSizeSCEV = Ctx.SE.getConstant(StepType, DS.Stride);
        BaseStep = Ctx.SE.getMulExpr(RawStep, ElementSizeSCEV);
      }

      LLVM_DEBUG(dbgs() << "      ✓ Found parent loop AddRec step\n");
      LLVM_DEBUG(dbgs() << "    Parent step: " << *BaseStep << "\n");
    }

    if (!BaseStep) {
      LLVM_DEBUG(dbgs() << "    ✗ Could not extract parent loop step - dimension not contiguous\n");
      LLVM_DEBUG(dbgs() << "    ✗ STOPPING merge analysis: intermediate dimension is non-contiguous\n");
      // CRITICAL: Stop here! We can only merge contiguous dimensions in order.
      // If dimension j is non-contiguous (e.g., A[i][idx_j][k] where idx_j is data-dependent),
      // we CANNOT merge k→i even if i is contiguous, because j breaks the continuity.
      // Example: D3B[i][A[j]%10][k] - cannot merge k→j→i even though i is contiguous
      // because the j dimension uses indirect indexing.
      break;
    }

    // Check if linearizable at this nesting level
    // For a stream to be linearizable, the cumulative span must equal the parent step
    bool IsPotentiallyLinearizable = false;

    // First try SCEV pointer equality (works for symbolic expressions)
    if (CumulativeSpan == BaseStep) {
      IsPotentiallyLinearizable = true;
      LLVM_DEBUG(dbgs() << "    ✓ Symbolic match - linearizable!\n");
    }
    // For constants, compare values (handle different bit widths safely)
    else if (isa<SCEVConstant>(CumulativeSpan) && isa<SCEVConstant>(BaseStep)) {
      const SCEVConstant *SpanConst = cast<SCEVConstant>(CumulativeSpan);
      const SCEVConstant *StepConst = cast<SCEVConstant>(BaseStep);

      // Use sign-extended comparison to handle different bit widths
      const APInt &SpanVal = SpanConst->getAPInt();
      const APInt &StepVal = StepConst->getAPInt();

      // Extend both to the maximum bit width before comparing
      unsigned MaxWidth = std::max(SpanVal.getBitWidth(), StepVal.getBitWidth());
      APInt SpanExtended = SpanVal.sext(MaxWidth);
      APInt StepExtended = StepVal.sext(MaxWidth);

      if (SpanExtended == StepExtended) {
        IsPotentiallyLinearizable = true;
        LLVM_DEBUG(dbgs() << "    ✓ Constants match - linearizable!\n");
      }
    }
    // Try matching against stride×tripcount pattern
    else if (const SCEVMulExpr *StepMul = dyn_cast<SCEVMulExpr>(BaseStep)) {
      for (const SCEV *Op : StepMul->operands()) {
        if (Op == InnerStrideSCEV || Op == InnerTripCount) {
          const SCEV *ExpectedStep = Ctx.SE.getMulExpr(InnerTripCount, InnerStrideSCEV);
          if (ExpectedStep == BaseStep) {
            IsPotentiallyLinearizable = true;
            LLVM_DEBUG(dbgs() << "    ✓ Stride×tripcount match - linearizable!\n");
            break;
          }
        }
      }
    }

    if (IsPotentiallyLinearizable) {
      StreamMergeCandidate Candidate;
      Candidate.StreamID = DS.StreamID;
      Candidate.InnerLoopID = DS.LoopID;
      Candidate.OuterLoopID = ParentLoopID;
      Candidate.RequiredDimensions = std::move(RequiredDimensions);

      Ctx.MergeCandidates.push_back(Candidate);

      LLVM_DEBUG(dbgs() << "    → Merge candidate created (level " 
                        << Ctx.MergeCandidates.size() << ")\n");

      // Reset RequiredDimensions for next iteration
      RequiredDimensions.clear();
      // Re-add dimensions we've accumulated so far for next level
      if (ChildLD->IsEndLinked) {
        RequiredDimensions.push_back(ChildLD->EndLinkID);
      }
    } else {
      LLVM_DEBUG(dbgs() << "    ✗ Span/step mismatch - not linearizable at this level\n");
    }

    // Move to next parent loop (if any)
    ChildLoop = ParentLoop;

    // Find the parent loop's descriptor to get its trip count for next iteration
    auto ParentLDIt = Ctx.LoopIDToDescriptor.find(ParentLoopID);
    if (ParentLDIt != Ctx.LoopIDToDescriptor.end()) {
      ChildLD = ParentLDIt->second;
      InnerTripCount = ChildLD->EndValue;

      // Apply the same EndValueDynamic normalization as we do initially
      // This ensures we use clean symbolic expressions without backedge adjustments
      if (ChildLD->EndValueDynamic && ChildLD->IsEndLinked) {
        const SCEV *DynamicSCEV = Ctx.SE.getSCEV(ChildLD->EndValueDynamic);
        if (DynamicSCEV) {
          InnerTripCount = DynamicSCEV;
          LLVM_DEBUG(dbgs() << "    Using dynamic end value for trip count: " 
                            << *InnerTripCount << "\n");
        }
      }

      if (ChildLD->IsEndLinked && InnerTripCount) {
        RequiredDimensions.push_back(ChildLD->EndLinkID);
      }
    } else {
      // No descriptor for parent loop, can't continue walking up
      break;
    }
  }  // End while (walking up parent loops)
}  // End for (each stream)

} // End: if (!Ctx.Streams.empty()) - Stage 1.2
}

/// Stage 1.5: drop loops that carry no streams, keeping parents of kept
/// loops. Returns true if any loops remain.
static bool removeStreamLessLoops(InterstellarPipelineContext &Ctx) {
// ============================================================
// STAGE 1.5: EARLY CLEANUP - REMOVE EMPTY LOOPS
// ============================================================
// Remove loops with no associated streams BEFORE merge analysis
// This optimization saves analysis time when loops have no streams
// (e.g., pure computation loops without memory accesses)
// This stage ALWAYS runs if there are any loops, even if no streams
//
// IMPORTANT: We must keep parent loops of loops with streams,
// as they may be needed for merge analysis in Stage 2.
// ============================================================

LLVM_DEBUG(dbgs() << "\n[Stage 1.5] Early cleanup: Removing loops with no streams\n");

// Count streams per loop (direct and indirect — a loop hosting only
// indirect streams is just as live)
DenseMap<unsigned, unsigned> StreamCountPerLoop;
for (const auto &DS : Ctx.Streams) {
  StreamCountPerLoop[DS.LoopID]++;
}
for (const auto &IDS : Ctx.IndirectStreams) {
  StreamCountPerLoop[IDS.LoopID]++;
}

// Mark loops with streams as active (Stage 1.5 early cleanup)
DenseSet<unsigned> KeepLoopIDs;
for (const auto &LD : Ctx.Loops) {
  if (StreamCountPerLoop.lookup(LD.LoopID) > 0) {
    KeepLoopIDs.insert(LD.LoopID);
  }
}

// Recursively mark parent loops as active
// (they may be needed for merge analysis)
bool FoundNewParent = true;
while (FoundNewParent) {
  FoundNewParent = false;
  for (const auto &LD : Ctx.Loops) {
    if (KeepLoopIDs.count(LD.LoopID)) {
      continue;  // Already active
    }

    // Check if this loop is a parent of any active loop
    for (const auto &ChildLD : Ctx.Loops) {
      if (KeepLoopIDs.count(ChildLD.LoopID) && 
          ChildLD.ParentLoopID == LD.LoopID) {
        KeepLoopIDs.insert(LD.LoopID);
        FoundNewParent = true;
        break;
      }
    }
  }
}

// Filter out loops with no streams and no active children
SmallVector<LoopDescriptor, 4> FilteredLoops;
unsigned RemovedCount = 0;

for (const auto &LD : Ctx.Loops) {
  if (KeepLoopIDs.count(LD.LoopID)) {
    FilteredLoops.push_back(LD);
  } else {
    RemovedCount++;
    LLVM_DEBUG(dbgs() << "  ✗ Removed Loop #" << LD.LoopID 
                      << " (no streams, not a parent)\n");
  }
}

if (RemovedCount > 0) {
  Ctx.Loops = std::move(FilteredLoops);
  LLVM_DEBUG(dbgs() << "  Removed " << RemovedCount 
                    << " empty loop(s), " << Ctx.Loops.size() 
                    << " loop(s) remaining\n");
} else {
  LLVM_DEBUG(dbgs() << "  No empty loops to remove\n");
}

  return !Ctx.Loops.empty();
}

/// Rewrites AddRecExprs over a set of merged loops to their start values,
/// recursing through casts and n-ary expressions with SCEV folding. Used to
/// flatten a stream base after loop merging: the merge proved every merged
/// dimension contiguous, so the address terms carried by those loops vanish
/// and the base collapses toward the invariant array start. AddRecs over
/// unmerged loops are preserved (their start/step cannot reference the
/// merged inner loops, so rewriting operands is a no-op for them).
class MergedLoopStartRewriter
    : public SCEVRewriteVisitor<MergedLoopStartRewriter> {
public:
  MergedLoopStartRewriter(ScalarEvolution &SE,
                          const SmallPtrSetImpl<Loop *> &MergedLoops)
      : SCEVRewriteVisitor(SE), MergedLoops(MergedLoops) {}

  const SCEV *visitAddRecExpr(const SCEVAddRecExpr *AR) {
    if (MergedLoops.contains(AR->getLoop()))
      return visit(AR->getStart());
    return SCEVRewriteVisitor<MergedLoopStartRewriter>::visitAddRecExpr(AR);
  }

private:
  const SmallPtrSetImpl<Loop *> &MergedLoops;
};

/// Stage 3: apply the largest merge candidate per stream — create virtual
/// merged loop descriptors (bounds multiplied at the entry block) and
/// reassign the owning stream. ALL candidates are applied: there is no
/// safety gating (pre-existing behavior, preserved).
static void applyLoopMerges(InterstellarPipelineContext &Ctx) {
if (!Ctx.MergeCandidates.empty()) {
  LLVM_DEBUG(dbgs() << "\n═══ Merge Candidates Summary ═══\n");
  LLVM_DEBUG(dbgs() << "Total candidates: " << Ctx.MergeCandidates.size() << "\n");
  for (const auto &Candidate : Ctx.MergeCandidates) {
    LLVM_DEBUG(dbgs() << "  Stream #" << Candidate.StreamID 
                      << ": Loop #" << Candidate.InnerLoopID
                      << " → Loop #" << Candidate.OuterLoopID);
    if (!Candidate.RequiredDimensions.empty()) {
      LLVM_DEBUG(dbgs() << " (requires " << Candidate.RequiredDimensions.size() 
                        << " dimension(s))");
    }
    LLVM_DEBUG(dbgs() << "\n");
  }


  // ============================================================
  // STAGE 3: LOOP MERGE TRANSFORMATION
  // ============================================================
  // For each verified merge candidate, create virtual loop descriptors
  // and update stream associations.
  // ============================================================

  if (!Ctx.MergeCandidates.empty()) {
    LLVM_DEBUG(dbgs() << "\n[Stage 3] Loop Merge Transformation\n");
    LLVM_DEBUG(dbgs() << "Creating virtual loop descriptors for safe merges...\n");

    // Group merge candidates by stream ID and select largest merge for each stream
    // When multiple merges exist (e.g., Loop #2→#1 and Loop #2→#0), only apply
    // the largest one (Loop #2→#0) as it encompasses more loops.
    DenseMap<unsigned, const StreamMergeCandidate *> LargestMergePerStream;
    for (const auto &Candidate : Ctx.MergeCandidates) {
      auto It = LargestMergePerStream.find(Candidate.StreamID);
      if (It == LargestMergePerStream.end()) {
        // First candidate for this stream
        LargestMergePerStream[Candidate.StreamID] = &Candidate;
      } else {
        // Compare with existing candidate - prefer outer loop (Loop #0 > Loop #1)
        // Outer loop ID is SMALLER (Loop #0 is outermost), so prefer SMALLER OuterLoopID
        if (Candidate.OuterLoopID < It->second->OuterLoopID) {
          LargestMergePerStream[Candidate.StreamID] = &Candidate;
          LLVM_DEBUG(dbgs() << "  Replacing merge candidate for Stream #" 
                            << Candidate.StreamID << ": Loop #" 
                            << It->second->OuterLoopID << " → Loop #" 
                            << Candidate.OuterLoopID << " (larger scope)\n");
        }
      }
    }

    // Track next available loop ID for virtual loops. Original IDs come from
    // a monotonically increasing counter and are not dense (Stage 1.5 may
    // have removed some), so continue past the largest one to avoid
    // colliding with a surviving original descriptor.
    unsigned NextVirtualLoopID = 0;
    for (const auto &LD : Ctx.Loops)
      if (LD.LoopID >= NextVirtualLoopID)
        NextVirtualLoopID = LD.LoopID + 1;

    // Apply only the largest merge for each stream
    for (const auto &Entry : LargestMergePerStream) {
      const StreamMergeCandidate &Candidate = *Entry.second;

      // Find inner and outer loop descriptors
      const LoopDescriptor *InnerLD = nullptr;
      const LoopDescriptor *OuterLD = nullptr;

      for (const auto &LD : Ctx.Loops) {
        if (LD.LoopID == Candidate.InnerLoopID) {
          InnerLD = &LD;
        }
        if (LD.LoopID == Candidate.OuterLoopID) {
          OuterLD = &LD;
        }
      }

      if (!InnerLD || !OuterLD) {
        LLVM_DEBUG(dbgs() << "  ⚠ Stream #" << Candidate.StreamID 
                          << ": Could not find loop descriptors\n");
        continue;
      }

      // Create virtual merged loop descriptor
      // Note: candidates come straight from Stage 1.2 and ALL are applied
      // (pre-existing behavior, preserved). No safety classification gates
      // the merge.
      // The loop bounds can be any SCEV expression (constant, variable, or arithmetic)
      // We multiply them as SCEV expressions and use EndValueDynamic for IR values
      LoopDescriptor VirtualLoop;
      VirtualLoop.LoopID = NextVirtualLoopID++;
      VirtualLoop.ParentLoopID = OuterLD->ParentLoopID;  // Inherit grandparent if any
      VirtualLoop.L = OuterLD->L;  // Use outer loop's Loop* (for context)
      VirtualLoop.Loc = OuterLD->Loc;  // Use outer loop's location (outermost, line 8 for 2D)

      // Virtual loop always starts at 0
      VirtualLoop.StartValue = Ctx.SE.getConstant(APInt(64, 0, true));
      VirtualLoop.IsStartLinked = false;
      VirtualLoop.StartLinkID = 0;

      // End value is the product of all merged loop bounds
      // For example: rows * cols for 2D, or dim1 * dim2 * dim3 for 3D
      // Collect all dimensions from innermost to outermost (INCLUSIVE)
      const SCEV *VirtualEndValue = nullptr;
      Value *VirtualEndValueIR = nullptr;
      SmallVector<unsigned, 4> MergedLinkIDs;

      // Build list of all loops from inner to outer (inclusive)
      SmallVector<const LoopDescriptor *, 4> LoopChain;
      unsigned CurrentLoopID = Candidate.InnerLoopID;

      LLVM_DEBUG(dbgs() << "  Building loop chain from Inner #" << Candidate.InnerLoopID 
                        << " to Outer #" << Candidate.OuterLoopID << "\n");

      while (true) {
        const LoopDescriptor *CurrentLD = nullptr;
        for (const auto &LD : Ctx.Loops) {
          if (LD.LoopID == CurrentLoopID) {
            CurrentLD = &LD;
            break;
          }
        }

        if (!CurrentLD) {
          LLVM_DEBUG(dbgs() << "    ! Loop #" << CurrentLoopID << " not found\n");
          break;
        }

        LoopChain.push_back(CurrentLD);
        LLVM_DEBUG(dbgs() << "    + Added Loop #" << CurrentLoopID << "\n");

        // Check if we've reached the outer loop (inclusive)
        if (CurrentLoopID == Candidate.OuterLoopID) {
          LLVM_DEBUG(dbgs() << "    ✓ Reached outer loop #" << Candidate.OuterLoopID << "\n");
          break;
        }

        // Move to parent loop
        CurrentLoopID = CurrentLD->ParentLoopID;
        LLVM_DEBUG(dbgs() << "    → Moving to parent Loop #" << CurrentLoopID << "\n");
      }

      LLVM_DEBUG(dbgs() << "  Loop chain size: " << LoopChain.size() << "\n");

      // Create IRBuilder once for all multiplications
      // It will insert instructions sequentially at entry block
      BasicBlock &EntryBB = Ctx.F.getEntryBlock();
      IRBuilder<> Builder(&EntryBB, EntryBB.getFirstInsertionPt());

      // Create SCEVExpander to materialize SCEV expressions at entry block
      // This ensures instructions like %sub (from N-1) are properly placed
      SCEVExpander Expander(Ctx.SE, "interstellar");

      // Now multiply all dimensions: innermost * ... * outermost
      unsigned MulCount = 0;  // Counter for unique mul instruction names
      for (const LoopDescriptor *LD : LoopChain) {
        const SCEV *Bound = LD->EndValue;
        Value *BoundIR = nullptr;

        // Use EndValueDynamic for cleaner symbolic expression
        if (LD->EndValueDynamic && LD->IsEndLinked) {
          const SCEV *DynamicSCEV = Ctx.SE.getSCEV(LD->EndValueDynamic);
          if (DynamicSCEV) {
            Bound = DynamicSCEV;
          }
          MergedLinkIDs.push_back(LD->EndLinkID);
        }

        if (Bound) {
          // Every dimension contributes a concrete IR value so the product
          // below can chain. Constants become ConstantInts; this matters when
          // the innermost dimension is constant: VirtualEndValueIR starts as
          // that constant and a later dynamic bound (10 * smin(N, 10)) still
          // gets multiplied in and linked. Previously the leading constant left
          // VirtualEndValueIR null and the merged loop silently emitted End=0.
          if (auto *CC = dyn_cast<SCEVConstant>(Bound)) {
            BoundIR = ConstantInt::get(Ctx.F.getContext(), CC->getAPInt());
          } else {
            // Materialize the bound value at entry block using SCEVExpander
            // This handles cases like N-1 where %sub instruction needs to be created
            BoundIR = Expander.expandCodeFor(Bound, Bound->getType(),
                                              &*EntryBB.getFirstInsertionPt());
          }

          if (!VirtualEndValue) {
            VirtualEndValue = Bound;
            VirtualEndValueIR = BoundIR;
          } else {
            VirtualEndValue = Ctx.SE.getMulExpr(VirtualEndValue, Bound);
            // Need to create IR multiplication if we have dynamic values
            if (VirtualEndValueIR && BoundIR) {
              // Use unique name for each multiplication to avoid conflicts
              // For 2D: %merged_loop_bound = mul i32 %dim2, %dim1
              // For 3D: %merged_loop_bound = mul i32 %dim3, %dim2
              //         %merged_loop_bound2 = mul i32 %merged_loop_bound, %dim1
              std::string MulName = MulCount == 0 ? "merged_loop_bound" 
                                                   : "merged_loop_bound" + std::to_string(MulCount + 1);
              VirtualEndValueIR = Builder.CreateMul(VirtualEndValueIR, BoundIR, MulName);
              MulCount++;
            }
          }
        }
      }

      VirtualLoop.EndValue = VirtualEndValue;
      VirtualLoop.EndValueDynamic = VirtualEndValueIR;

      // Check if the result is a constant
      // If all loop bounds are constants, the product is also constant (no LinkVariable needed)
      bool IsConstantBound = isa<SCEVConstant>(VirtualEndValue);
      VirtualLoop.IsEndLinked = (VirtualEndValueIR != nullptr) && !IsConstantBound;

      // Create new link variable for the merged bound value (only if dynamic)
      if (VirtualEndValueIR && !IsConstantBound) {
        // The merged bound is a new value (mul instruction), needs its own LinkID
        LinkVariableDescriptor NewLinkVar;
        NewLinkVar.LinkID = Ctx.NextLinkID++;
        NewLinkVar.DynamicValue = VirtualEndValueIR;
        NewLinkVar.SizeInBytes = 4;  // 4 bytes for i32
        Ctx.LinkVars.push_back(NewLinkVar);

        VirtualLoop.EndLinkID = NewLinkVar.LinkID;

        LLVM_DEBUG(dbgs() << "      Created Link Variable for merged bound:\n");
        LLVM_DEBUG(dbgs() << "        Link ID: " << NewLinkVar.LinkID << "\n");
        LLVM_DEBUG(dbgs() << "        Value: " << *VirtualEndValueIR << "\n");
      } else {
        VirtualLoop.EndLinkID = 0; // No link for constants
        if (IsConstantBound) {
          LLVM_DEBUG(dbgs() << "      Merged bound is constant: " << *VirtualEndValue << "\n");
        }
      }

      // Step is always 1 for virtual flat loops
      VirtualLoop.StepValue = Ctx.SE.getConstant(APInt(64, 1, true));

      // Mark as virtual and record merge info (for internal tracking)
      VirtualLoop.IsVirtual = true;
      VirtualLoop.MergedFromInnerLoop = Candidate.InnerLoopID;
      VirtualLoop.MergedToOuterLoop = Candidate.OuterLoopID;
      VirtualLoop.MergedDimensions = std::move(MergedLinkIDs);

      // Add to loops collection
      Ctx.Loops.push_back(VirtualLoop);
      Ctx.AppliedMerges.push_back(Candidate.StreamID);

      LLVM_DEBUG(dbgs() << "\n  ✓ Created Virtual Loop #" << VirtualLoop.LoopID 
                        << " (merges Loop #" << Candidate.InnerLoopID 
                        << " → Loop #" << Candidate.OuterLoopID << ")\n");
      LLVM_DEBUG(dbgs() << "      Start: 0\n");
      LLVM_DEBUG(dbgs() << "      End:   " << *VirtualEndValue << "\n");
      LLVM_DEBUG(dbgs() << "      Step:  1\n");
      LLVM_DEBUG(dbgs() << "      Merged dimensions: " << MergedLinkIDs.size() << "\n");

      // Update stream to use virtual loop
      for (auto &DS : Ctx.Streams) {
        if (DS.StreamID == Candidate.StreamID) {
          unsigned OldLoopID = DS.LoopID;
          DS.LoopID = VirtualLoop.LoopID;

          // Flatten the base for the dimensions this merge absorbed. The
          // linearization proof (parent step == child trip count x inner
          // stride) holds only for the loops in the merge chain, so rewrite
          // AddRecs over those loops to their starts — wherever they appear
          // in the base expression, including nested inside casts and index
          // arithmetic (e.g. (4 * sext({{{0,+,M*P*Q},+,P*Q},+,%Q}) + %E) from
          // E[i*M*P*Q+...]). Levels over unmerged outer loops still describe
          // real per-iteration variation and must stay.
          SmallPtrSet<Loop *, 4> MergedLoops;
          for (unsigned ID = Candidate.InnerLoopID;;) {
            auto It = find_if(Ctx.Loops, [&](const LoopDescriptor &LD) {
              return LD.LoopID == ID;
            });
            if (It == Ctx.Loops.end() || !It->L)
              break;
            MergedLoops.insert(It->L);
            if (ID == Candidate.OuterLoopID)
              break;
            ID = It->ParentLoopID;
          }
          const SCEV *Flat =
              DS.BaseAddress
                  ? MergedLoopStartRewriter(Ctx.SE, MergedLoops)
                        .visit(DS.BaseAddress)
                  : nullptr;
          if (Flat && Flat != DS.BaseAddress) {
            DS.BaseAddress = Flat;
            // A fully flattened base is the invariant array start (SCEVUnknown
            // such as %D2B or %E); the link that carried the outer-variant
            // address is no longer needed and may not even correspond to the
            // flattened base. Partially flattened bases keep their link.
            if (isa<SCEVUnknown>(Flat)) {
              DS.BaseAddressValue = nullptr; // re-derive from SCEV in IR-gen
              DS.IsBaseLinked = false;
              DS.LinkID = 0;
            }
            LLVM_DEBUG(dbgs() << "      → Base flattened to " << *Flat << "\n");
          }

          LLVM_DEBUG(dbgs() << "      → Stream #" << DS.StreamID
                            << " reassigned: Loop #" << OldLoopID
                            << " → Virtual Loop #" << VirtualLoop.LoopID << "\n");
          break;
        }
      }
    }
  }
} // End: if (!Ctx.MergeCandidates.empty()) - Pattern Classification & Merge Application
}

/// Stage 3.1: drop loop descriptors not reachable as "active" (streams or
/// virtual) or as parents of active loops.
static void removeUnusedLoops(InterstellarPipelineContext &Ctx) {
  // ============================================================
  // STAGE 3.1: CLEANUP UNUSED LOOP DESCRIPTORS
  // ============================================================
  // This stage ALWAYS runs, even if no merges were applied
  // Remove loop descriptors that have no streams associated with them
  // UNLESS they are parents of loops that will be kept
  //
  // Algorithm: Two-pass approach to handle transitive parent relationships
  // Pass 1: Mark loops with streams or virtual loops as "active"
  // Pass 2: Recursively mark parents of active loops as "active"
  // ============================================================

  LLVM_DEBUG(dbgs() << "\n[Stage 3.1] Cleaning up unused loop descriptors\n");

  // Count streams per loop (both direct and indirect streams)
  DenseMap<unsigned, unsigned> StreamsPerLoop;
  for (const auto &DS : Ctx.Streams) {
    StreamsPerLoop[DS.LoopID]++;
  }
  for (const auto &IDS : Ctx.IndirectStreams) {
    StreamsPerLoop[IDS.LoopID]++;
  }

  // Pass 1: Mark loops that are directly active (have streams or are virtual)
  DenseSet<unsigned> ActiveLoopIDs;
  for (const auto &LD : Ctx.Loops) {
    if (StreamsPerLoop.lookup(LD.LoopID) > 0 || LD.IsVirtual) {
      ActiveLoopIDs.insert(LD.LoopID);
    }
  }

  // Pass 2: Recursively mark parent loops as active
  // Continue until no new parents are marked (fixed-point iteration)
  bool Changed = true;
  while (Changed) {
    Changed = false;
    for (const auto &LD : Ctx.Loops) {
      // Skip if already marked active
      if (ActiveLoopIDs.count(LD.LoopID)) {
        continue;
      }

      // Check if this loop is a parent of any active loop
      bool IsParentOfActive = false;
      for (const auto &OtherLD : Ctx.Loops) {
        // Only consider active loops
        if (!ActiveLoopIDs.count(OtherLD.LoopID)) {
          continue;
        }

        // Check if current loop is the parent of OtherLD
        bool IsParentOfThis = (OtherLD.ParentLoopID == LD.LoopID);

        // Special case for Loop #0 virtual loops only:
        // Root-level virtual: ParentLoopID=0 AND MergedToOuterLoop=0 (fully merged to top)
        // These should NOT be considered children of Loop #0 for preservation
        if (LD.LoopID == 0 && OtherLD.IsVirtual && IsParentOfThis) {
          if (OtherLD.MergedToOuterLoop == 0) {
            continue;  // Don't keep Loop #0 for root-level virtual loops
          }
        }

        if (IsParentOfThis) {
          IsParentOfActive = true;
          break;
        }
      }

      if (IsParentOfActive) {
        ActiveLoopIDs.insert(LD.LoopID);
        Changed = true;  // Continue iteration to mark grandparents
      }
    }
  }

  // Build filtered loop list and track removed loops (Stage 3.1)
  SmallVector<LoopDescriptor, 4> ActiveLoops;
  SmallPtrSet<const LoopDescriptor *, 4> RemovedLoops;

  for (const auto &LD : Ctx.Loops) {
    if (ActiveLoopIDs.count(LD.LoopID)) {
      ActiveLoops.push_back(LD);
    } else {
      RemovedLoops.insert(&LD);
      LLVM_DEBUG(dbgs() << "  ✗ Removed Loop #" << LD.LoopID 
                        << " (no streams, not a parent of active loops)\n");
    }
  }

  // Update loops collection
  if (RemovedLoops.size() > 0) {
    Ctx.Loops = std::move(ActiveLoops);
    LLVM_DEBUG(dbgs() << "  Removed " << RemovedLoops.size()
                      << " unused loop descriptor(s)\n");
  } else {
    LLVM_DEBUG(dbgs() << "  No unused loops to remove\n");
  }
}

/// Stage 3.2: drop link variables no longer referenced by any surviving
/// stream or loop. Links lose their owners when dedup removes a duplicate
/// stream, a merge consumes a loop's bound, or cleanup drops a loop; the
/// survivors would otherwise burn GlobalID slots in the descriptor table.
/// Runs after all descriptor removals so the ID remap covers only links that
/// reach the hardware.
static void removeUnusedLinkVars(InterstellarPipelineContext &Ctx) {
  LLVM_DEBUG(dbgs() << "\n[Stage 3.2] Cleaning up unreferenced link variables\n");

  DenseSet<unsigned> Referenced;
  for (const auto &DS : Ctx.Streams)
    if (DS.IsBaseLinked)
      Referenced.insert(DS.LinkID);
  for (const auto &IDS : Ctx.IndirectStreams)
    if (IDS.IsBaseLinked)
      Referenced.insert(IDS.LinkID);
  for (const auto &LD : Ctx.Loops) {
    if (LD.IsStartLinked)
      Referenced.insert(LD.StartLinkID);
    if (LD.IsEndLinked)
      Referenced.insert(LD.EndLinkID);
  }

  SmallVector<LinkVariableDescriptor, 8> KeptLinks;
  for (const auto &LV : Ctx.LinkVars) {
    if (Referenced.count(LV.LinkID))
      KeptLinks.push_back(LV);
    else
      LLVM_DEBUG(dbgs() << "  ✗ Removed Link #" << LV.LinkID
                        << " (not referenced by any stream or loop)\n");
  }

  if (KeptLinks.size() != Ctx.LinkVars.size()) {
    LLVM_DEBUG(dbgs() << "  Removed " << Ctx.LinkVars.size() - KeptLinks.size()
                      << " unreferenced link descriptor(s)\n");
    Ctx.LinkVars = std::move(KeptLinks);
  } else {
    LLVM_DEBUG(dbgs() << "  No unreferenced links to remove\n");
  }
}

//===----------------------------------------------------------------------===//
// InterStellarAnalysisPass Implementation (New Pass Manager)
//===----------------------------------------------------------------------===//

PreservedAnalyses InterStellarAnalysisPass::run(Function &F,
                                                 FunctionAnalysisManager &AM) {
  auto &LI = AM.getResult<LoopAnalysis>(F);
  auto &SE = AM.getResult<ScalarEvolutionAnalysis>(F);

  // Early exit if no loops
  if (LI.empty()) {
    return PreservedAnalyses::all();
  }

  LLVM_DEBUG(dbgs() << "\n"
                    << "╔═══════════════════════════════════════════════════╗\n"
                    << "║  InterStellar Pass 1: Local Stream Analysis       ║\n"
                    << "╚═══════════════════════════════════════════════════╝\n");

  LLVM_DEBUG(dbgs() << "Running InterStellar Pass 1 on function: "
                    << F.getName() << "\n");

  // PASS 1: LOCAL STREAM ANALYSIS
  // Identifies raw memory access patterns within each function:
  // - Direct streams (affine patterns like A[i])
  // - Indirect streams (index-based patterns like A[B[i]])
  // - Loop contexts (bounds, nesting, induction variables)
  // - Dynamic values (link variables for runtime values)
  InterStellarStreamAnalyzer Analyzer(F, LI, SE);
  Analyzer.analyze();

  LLVM_DEBUG(Analyzer.print(dbgs()));

  SmallVector<DirectStreamDescriptor, 8> Streams = Analyzer.getDirectStreams();
  SmallVector<LoopDescriptor, 4> Loops = Analyzer.getLoopDescriptors();
  SmallVector<IndirectStreamDescriptor, 4> IndirectStreams = Analyzer.getIndirectStreams();
  SmallVector<LinkVariableDescriptor, 4> LinkVars = Analyzer.getLinkVariables();

  // Run Pass 2 only if there are any loops (even without streams)
  if (Loops.empty())
    return PreservedAnalyses::none();

  InterstellarPipelineContext Ctx(F, SE, AM.getResult<DominatorTreeAnalysis>(F));
  Ctx.Streams = std::move(Streams);
  Ctx.Loops = std::move(Loops);
  Ctx.IndirectStreams = std::move(IndirectStreams);
  Ctx.LinkVars = std::move(LinkVars);
  // LinkVars only grow (Stage 3 appends), so the starting ID computed here is
  // the value the former inline code used at the same point in the pipeline.
  Ctx.NextLinkID = Ctx.LinkVars.empty() ? 0 : Ctx.LinkVars.back().LinkID + 1;

  LLVM_DEBUG(dbgs() << "\n"
                    << "╔═══════════════════════════════════════════════════╗\n"
                    << "║  InterStellar Pass 2: Stage 1 (Intraprocedural)   ║\n"
                    << "╚═══════════════════════════════════════════════════╝\n");

  // Stage 1.1: dominance-based stream dedup. The indirect pass stays nested
  // inside the !Streams.empty() guard — pre-existing structure, preserved.
  if (!Ctx.Streams.empty()) {
    deduplicateDirectStreams(Ctx);
    deduplicateIndirectStreams(Ctx);
  }

  // LoopID -> descriptor map. Points into Ctx.Loops; every read happens
  // before Stage 1.5 reassigns Ctx.Loops, so do not rebuild it afterwards.
  for (const auto &LD : Ctx.Loops)
    Ctx.LoopIDToDescriptor[LD.LoopID] = &LD;

  // Stage 1.2: linearization feasibility -> merge candidates
  analyzeLinearizationFeasibility(Ctx);

  // Stage 1.5: remove stream-less loops; early-out when nothing remains
  if (!removeStreamLessLoops(Ctx)) {
    LLVM_DEBUG(dbgs() << "\n[Stage 1.5] No loops remaining after cleanup\n");
    LLVM_DEBUG(dbgs() << "Skipping Stage 2 (Pattern Classification)\n");
    LLVM_DEBUG(dbgs() << "Skipping Stage 3 (Loop Merge Transformation)\n");
    removeUnusedLinkVars(Ctx);
    LLVM_DEBUG(printAllDescriptors(dbgs(), Ctx.Loops, Ctx.Streams,
                                   Ctx.IndirectStreams, Ctx.LinkVars));
    return PreservedAnalyses::all();
  }

  // Stage 3: merge transformation; Stage 3.1: unused-loop cleanup;
  // Stage 3.2: unreferenced-link cleanup
  applyLoopMerges(Ctx);
  removeUnusedLoops(Ctx);
  removeUnusedLinkVars(Ctx);

  LLVM_DEBUG(dbgs() << "\n[Stage 3] Summary:\n");
  LLVM_DEBUG(dbgs() << "  Applied " << Ctx.AppliedMerges.size() << " merge(s)\n");
  LLVM_DEBUG(dbgs() << "  Active loops: " << Ctx.Loops.size() << "\n");
  LLVM_DEBUG(dbgs() << "  Active streams: " << Ctx.Streams.size() << "\n");

  LLVM_DEBUG(printAllDescriptors(dbgs(), Ctx.Loops, Ctx.Streams,
                                 Ctx.IndirectStreams, Ctx.LinkVars));

  // PHASE 1: IR GENERATION
  // Assign unified GlobalIDs (Links -> Loops -> Direct -> Indirect) and emit
  // the llvm.interstellar.configure.* intrinsic calls the backend lowers to
  // CSR writes.
  LLVM_DEBUG(dbgs() << "\n"
                    << "╔═══════════════════════════════════════════════════╗\n"
                    << "║  Phase 1: IR Generation                            ║\n"
                    << "╚═══════════════════════════════════════════════════╝\n");

  if (!Ctx.LinkVars.empty() || !Ctx.Loops.empty() ||
      !Ctx.Streams.empty() || !Ctx.IndirectStreams.empty()) {
    generateHardwareDescriptorIR(F, Ctx.Loops, Ctx.Streams,
                                 Ctx.IndirectStreams, Ctx.LinkVars);
  } else {
    LLVM_DEBUG(dbgs() << "No descriptors to generate IR for\n");
  }

  // IR was modified (intrinsic calls injected).
  return PreservedAnalyses::none();
}

//===----------------------------------------------------------------------===//
// IR Generation Helper Functions
//===----------------------------------------------------------------------===//

namespace {

/// Build ID remapping tables: Analysis IDs → Unified GlobalIDs
/// Assigns sequential GlobalIDs starting from 0 across all descriptor types.
/// Order: Links → Loops → DirectStreams → IndirectStreams
void buildIDRemappingTables(
    const SmallVectorImpl<LinkVariableDescriptor> &LinkVars,
    const SmallVectorImpl<LoopDescriptor> &Loops,
    const SmallVectorImpl<DirectStreamDescriptor> &DirectStreams,
    const SmallVectorImpl<IndirectStreamDescriptor> &IndirectStreams,
    DenseMap<unsigned, unsigned> &LinkIDMap,
    DenseMap<unsigned, unsigned> &LoopIDMap,
    DenseMap<unsigned, unsigned> &StreamIDMap,
    DenseMap<unsigned, unsigned> &IndirectIDMap,
    unsigned &TotalDescriptorCount) {
  
  unsigned NextGlobalID = 0;  // Single global counter starting from 0
  
  LLVM_DEBUG(dbgs() << "\n[ID Remapping] Assigning unified GlobalIDs:\n");
  
  // 1. Assign GlobalIDs to Link Variables first (they are referenced by others)
  for (const auto &Link : LinkVars) {
    LinkIDMap[Link.LinkID] = NextGlobalID;
    LLVM_DEBUG(dbgs() << "  Link Analysis ID " << Link.LinkID 
                      << " → GlobalID " << NextGlobalID << "\n");
    NextGlobalID++;
  }
  
  // 2. Assign GlobalIDs to Loop Descriptors
  for (const auto &Loop : Loops) {
    LoopIDMap[Loop.LoopID] = NextGlobalID;
    LLVM_DEBUG(dbgs() << "  Loop Analysis ID " << Loop.LoopID 
                      << " → GlobalID " << NextGlobalID << "\n");
    NextGlobalID++;
  }
  
  // 3. Assign GlobalIDs to Direct Stream Descriptors
  for (const auto &Stream : DirectStreams) {
    StreamIDMap[Stream.StreamID] = NextGlobalID;
    LLVM_DEBUG(dbgs() << "  DirectStream Analysis ID " << Stream.StreamID 
                      << " → GlobalID " << NextGlobalID << "\n");
    NextGlobalID++;
  }
  
  // 4. Assign GlobalIDs to Indirect Stream Descriptors
  for (const auto &Indirect : IndirectStreams) {
    IndirectIDMap[Indirect.StreamID] = NextGlobalID;
    LLVM_DEBUG(dbgs() << "  IndirectStream Analysis ID " << Indirect.StreamID 
                      << " → GlobalID " << NextGlobalID << "\n");
    NextGlobalID++;
  }
  
  TotalDescriptorCount = NextGlobalID;
  LLVM_DEBUG(dbgs() << "\nTotal descriptors: " << TotalDescriptorCount << "\n");
  
  // Validate: Must not exceed hardware limit (32 CSRs: 0x800-0x81F)
  if (TotalDescriptorCount > 32) {
    report_fatal_error("InterStellar: Total descriptors (" + 
                       Twine(TotalDescriptorCount) + 
                       ") exceeds hardware limit (32)");
  }
}

/// Inject intrinsic calls into loop preheaders
/// Emits configuration intrinsics in dependency order:
/// Links → Loops → DirectStreams → IndirectStreams
/// The referenced link may have been skipped (loop-variant); such streams
/// fall back to non-linked mode.
static bool resolveActuallyLinked(bool IsBaseLinked, unsigned LinkID,
                                  const DenseSet<unsigned> &EmittedLinkIDs,
                                  unsigned StreamIDForDebug,
                                  const char *Kind) {
  if (IsBaseLinked && !EmittedLinkIDs.count(LinkID)) {
    LLVM_DEBUG(dbgs() << "    Warning: " << Kind << " " << StreamIDForDebug
                      << " references skipped link " << LinkID
                      << ", using non-linked mode\n");
    return false;
  }
  return IsBaseLinked;
}

/// Prepare the base-address operand of a stream configure intrinsic.
/// Linked bases encode the link's GlobalID as a pointer (the backend extracts
/// it); constant bases pass the actual pointer. Returns nullopt when the
/// stream must be skipped: a base computed inside the loop cannot be hoisted
/// into the preheader.
static std::optional<Value *>
prepareStreamBaseArg(IRBuilder<> &Builder, Loop *L, bool ActuallyLinked,
                     unsigned LinkID,
                     const DenseMap<unsigned, unsigned> &LinkIDMap,
                     Value *BaseAddressValue, const SCEV *BaseAddress,
                     unsigned StreamIDForDebug) {
  if (ActuallyLinked) {
    unsigned LinkGlobalID = LinkIDMap.lookup(LinkID);
    return Builder.CreateIntToPtr(Builder.getInt64(LinkGlobalID),
                                  PointerType::getUnqual(Builder.getContext()));
  }

  Value *BaseArg = BaseAddressValue;
  if (!BaseArg) {
    // Fallback: try to extract from SCEV if BaseAddressValue is not set
    if (const SCEVUnknown *U = dyn_cast<SCEVUnknown>(BaseAddress))
      BaseArg = U->getValue();
  }

  // A base computed inside the loop can't be used in the preheader.
  if (BaseArg) {
    if (Instruction *BaseInst = dyn_cast<Instruction>(BaseArg)) {
      if (L->contains(BaseInst->getParent())) {
        LLVM_DEBUG(dbgs() << "    Warning: Stream " << StreamIDForDebug
                          << " has loop-variant base, skipping\n");
        return std::nullopt;
      }
    }
  }

  // If still null, use a null pointer as safe fallback.
  if (!BaseArg)
    BaseArg =
        ConstantPointerNull::get(PointerType::getUnqual(Builder.getContext()));
  return BaseArg;
}

/// Post-emission sweep. Stage 3.1 removes stream-less loops before IR
/// generation, but streams can still be skipped at emission (loop-variant
/// bases, skipped links). Such late drops leave orphan configure.loop calls
/// — and, cascading, link configs only those loops referenced. Apply the
/// Stage 3.1 activity criterion to what was actually emitted and erase the
/// rest: a loop survives if an emitted direct stream runs on it or if it is
/// the parent (transitively) of a loop that does. Virtual loops do not keep
/// themselves alive here — a virtual loop with no surviving stream is
/// precisely the orphan this sweep removes. Indirect descriptors carry no
/// loop field in the ABI, so they keep no loop alive either.
struct ErasedOrphanCounts {
  unsigned Loops = 0;
  unsigned Links = 0;
};
static ErasedOrphanCounts eraseOrphanConfigs(
    SmallVectorImpl<std::pair<CallInst *, unsigned>> &LoopCalls,
    SmallVectorImpl<std::pair<CallInst *, unsigned>> &LinkCalls,
    const SmallVectorImpl<LoopDescriptor> &Loops,
    const SmallVectorImpl<DirectStreamDescriptor> &DirectStreams,
    const SmallVectorImpl<IndirectStreamDescriptor> &IndirectStreams,
    const DenseSet<unsigned> &EmittedStreamIDs,
    const DenseSet<unsigned> &EmittedIndirectIDs) {
  ErasedOrphanCounts Erased;

  DenseSet<unsigned> KnownLoopIDs;
  for (const auto &LD : Loops)
    KnownLoopIDs.insert(LD.LoopID);

  // Pass 1: loops hosting an emitted direct stream are active.
  DenseSet<unsigned> ActiveLoopIDs;
  for (const auto &DS : DirectStreams) {
    if (EmittedStreamIDs.count(DS.StreamID) && KnownLoopIDs.count(DS.LoopID))
      ActiveLoopIDs.insert(DS.LoopID);
  }

  // Pass 2: mark parents of active loops active (fixed point), mirroring
  // Stage 3.1's root-level-virtual exception.
  bool Changed = true;
  while (Changed) {
    Changed = false;
    for (const auto &LD : Loops) {
      if (ActiveLoopIDs.count(LD.LoopID))
        continue;
      // Is any active loop a child of LD?
      bool IsParentOfActive = false;
      for (const auto &OtherLD : Loops) {
        if (!ActiveLoopIDs.count(OtherLD.LoopID) ||
            OtherLD.ParentLoopID != LD.LoopID)
          continue;
        // A fully-merged root-level virtual child must not keep Loop #0.
        if (LD.LoopID == 0 && OtherLD.IsVirtual && OtherLD.MergedToOuterLoop == 0)
          continue;
        IsParentOfActive = true;
        break;
      }
      if (IsParentOfActive) {
        ActiveLoopIDs.insert(LD.LoopID);
        Changed = true;
      }
    }
  }

  // Erase loop configs that describe no emitted activity.
  for (auto &LC : LoopCalls) {
    if (!ActiveLoopIDs.count(LC.second)) {
      LLVM_DEBUG(dbgs() << "  [Post-emission] Erased orphan loop config "
                        << LC.second << " (no emitted streams)\n");
      LC.first->eraseFromParent();
      ++Erased.Loops;
    }
  }

  // Links still referenced by surviving loops or emitted streams stay; the
  // rest would dangle now that their only consumer is gone.
  DenseSet<unsigned> ReferencedLinkIDs;
  for (const auto &LD : Loops) {
    if (!ActiveLoopIDs.count(LD.LoopID))
      continue;
    if (LD.IsStartLinked)
      ReferencedLinkIDs.insert(LD.StartLinkID);
    if (LD.IsEndLinked)
      ReferencedLinkIDs.insert(LD.EndLinkID);
  }
  for (const auto &DS : DirectStreams) {
    if (EmittedStreamIDs.count(DS.StreamID) && DS.IsBaseLinked)
      ReferencedLinkIDs.insert(DS.LinkID);
  }
  for (const auto &IDS : IndirectStreams) {
    if (EmittedIndirectIDs.count(IDS.StreamID) && IDS.IsBaseLinked)
      ReferencedLinkIDs.insert(IDS.LinkID);
  }
  for (auto &LC : LinkCalls) {
    if (!ReferencedLinkIDs.count(LC.second)) {
      LLVM_DEBUG(dbgs() << "  [Post-emission] Erased unreferenced link config "
                        << LC.second << "\n");
      LC.first->eraseFromParent();
      ++Erased.Links;
    }
  }
  return Erased;
}

/// Analysis IDs of indirect streams that must not be lowered to descriptors.
/// A stream whose target array has no statically-known bound (StreamSize == 0)
/// would leave the hardware unable to bound the addresses it touches, so it is
/// not emitted. Any indirect stream that consumes indices from a dropped
/// stream is dropped too — its SourceStreamID would otherwise name a
/// descriptor that is never emitted (A[B[C[i]]] chains).
static DenseSet<unsigned>
computeUnboundedIndirectDrops(
    const SmallVectorImpl<IndirectStreamDescriptor> &IndirectStreams) {
  DenseSet<unsigned> Dropped;
  for (const auto &IDS : IndirectStreams)
    if (IDS.StreamSize == 0)
      Dropped.insert(IDS.StreamID);

  // Fixpoint: consumers of dropped index providers drop as well. Computed /
  // random indices name no source stream (BaseStreamID is meaningless).
  bool Changed = true;
  while (Changed) {
    Changed = false;
    for (const auto &IDS : IndirectStreams) {
      if (IDS.IsIndexComputed || Dropped.count(IDS.StreamID))
        continue;
      if (Dropped.count(IDS.BaseStreamID)) {
        Dropped.insert(IDS.StreamID);
        Changed = true;
      }
    }
  }
  return Dropped;
}

void injectDescriptorIR(
    Function &F,
    const SmallVectorImpl<LoopDescriptor> &Loops,
    const SmallVectorImpl<DirectStreamDescriptor> &DirectStreams,
    const SmallVectorImpl<IndirectStreamDescriptor> &IndirectStreams,
    const SmallVectorImpl<LinkVariableDescriptor> &LinkVars,
    const DenseMap<unsigned, unsigned> &LoopIDMap,
    const DenseMap<unsigned, unsigned> &StreamIDMap,
    const DenseMap<unsigned, unsigned> &IndirectIDMap,
    const DenseMap<unsigned, unsigned> &LinkIDMap) {
  
  Module *M = F.getParent();
  LLVMContext &Ctx = M->getContext();
  
  // Get intrinsic function declarations
  Function *ConfigLinkFn = Intrinsic::getOrInsertDeclaration(
      M, Intrinsic::interstellar_configure_link);
  Function *ConfigLoopFn = Intrinsic::getOrInsertDeclaration(
      M, Intrinsic::interstellar_configure_loop);
  Function *ConfigDirectStreamFn = Intrinsic::getOrInsertDeclaration(
      M, Intrinsic::interstellar_configure_directstream);
  Function *ConfigIndirectStreamFn = Intrinsic::getOrInsertDeclaration(
      M, Intrinsic::interstellar_configure_indirectstream);
  
  LLVM_DEBUG(dbgs() << "\n[IR Generation] Emitting intrinsic calls:\n");

  // Unbounded indirect streams (StreamSize == 0) and their chained consumers
  // are never lowered; they must not reach the grouping below, or their link
  // variables would be emitted as orphans.
  DenseSet<unsigned> DroppedIndirectIDs =
      computeUnboundedIndirectDrops(IndirectStreams);

  // Precompute lookup tables to avoid repeated O(N^2) scans.
  DenseMap<unsigned, const LoopDescriptor *> LoopDescByID;
  for (const auto &LD : Loops)
    LoopDescByID[LD.LoopID] = &LD;

  DenseMap<unsigned, const LinkVariableDescriptor *> LinkVarByID;
  for (const auto &LV : LinkVars)
    LinkVarByID[LV.LinkID] = &LV;

  // Cache topmost anchor loop for each loop node.
  DenseMap<Loop *, Loop *> TopmostAnchorCache;
  auto getTopmostAnchorLoop = [&](Loop *L) -> Loop * {
    if (!L)
      return nullptr;

    auto It = TopmostAnchorCache.find(L);
    if (It != TopmostAnchorCache.end())
      return It->second;

    SmallVector<Loop *, 8> Chain;
    Loop *Cur = L;
    while (Cur) {
      Chain.push_back(Cur);
      if (!Cur->getParentLoop())
        break;
      Cur = Cur->getParentLoop();
    }

    Loop *Anchor = Chain.back(); // topmost loop in this chain
    if (!Anchor->getLoopPreheader()) {
      // Conservative fallback: choose nearest ancestor with a preheader.
      Anchor = nullptr;
      for (auto RI = Chain.rbegin(), RE = Chain.rend(); RI != RE; ++RI) {
        if ((*RI)->getLoopPreheader()) {
          Anchor = *RI;
          break;
        }
      }
    }

    for (Loop *Node : Chain)
      TopmostAnchorCache[Node] = Anchor;

    return Anchor;
  };
  
  // Group descriptors by anchor loop preheader (topmost loop in nest).
  // Map: AnchorLoop* -> {Links, Loops, Streams, IndirectStreams}
  DenseMap<Loop*, SmallVector<const LinkVariableDescriptor*, 4>> LinksByLoop;
  DenseMap<Loop*, SmallVector<const LoopDescriptor*, 4>> LoopsByLoop;
  DenseMap<Loop*, SmallVector<const DirectStreamDescriptor*, 4>> StreamsByLoop;
  DenseMap<Loop*, SmallVector<const IndirectStreamDescriptor*, 4>> IndirectByLoop;
  
  // Collect loop descriptors per anchor loop.
  for (const auto &LD : Loops) {
    Loop *Anchor = getTopmostAnchorLoop(LD.L);
    if (!Anchor)
      continue;
    LoopsByLoop[Anchor].push_back(&LD);
  }
  
  // Collect direct stream descriptors per anchor loop.
  for (const auto &DS : DirectStreams) {
    auto LDIt = LoopDescByID.find(DS.LoopID);
    if (LDIt == LoopDescByID.end())
      continue;

    Loop *Anchor = getTopmostAnchorLoop(LDIt->second->L);
    if (!Anchor)
      continue;

    StreamsByLoop[Anchor].push_back(&DS);

    // If stream uses a link variable, add it too.
    if (DS.IsBaseLinked) {
      auto LVIt = LinkVarByID.find(DS.LinkID);
      if (LVIt != LinkVarByID.end())
        LinksByLoop[Anchor].push_back(LVIt->second);
    }
  }
  
  // Collect indirect stream descriptors per anchor loop.
  for (const auto &IDS : IndirectStreams) {
    if (DroppedIndirectIDs.count(IDS.StreamID)) {
      LLVM_DEBUG(dbgs() << "    Skipping Indirect Stream #" << IDS.StreamID
                        << ": unknown array bound (StreamSize=0)\n");
      continue;
    }
    auto LDIt = LoopDescByID.find(IDS.LoopID);
    if (LDIt == LoopDescByID.end())
      continue;

    Loop *Anchor = getTopmostAnchorLoop(LDIt->second->L);
    if (!Anchor)
      continue;

    IndirectByLoop[Anchor].push_back(&IDS);

    // If stream uses a link variable, add it too.
    if (IDS.IsBaseLinked) {
      auto LVIt = LinkVarByID.find(IDS.LinkID);
      if (LVIt != LinkVarByID.end())
        LinksByLoop[Anchor].push_back(LVIt->second);
    }
  }
  
  // Also collect link variables used by loop bounds at anchor loop.
  for (const auto &LD : Loops) {
    Loop *Anchor = getTopmostAnchorLoop(LD.L);
    if (!Anchor)
      continue;

    if (LD.IsStartLinked) {
      auto LVIt = LinkVarByID.find(LD.StartLinkID);
      if (LVIt != LinkVarByID.end())
        LinksByLoop[Anchor].push_back(LVIt->second);
    }
    if (LD.IsEndLinked) {
      auto LVIt = LinkVarByID.find(LD.EndLinkID);
      if (LVIt != LinkVarByID.end())
        LinksByLoop[Anchor].push_back(LVIt->second);
    }
  }
  
  // Track which descriptors we've already emitted (to avoid duplicates)
  DenseSet<unsigned> EmittedLinkIDs;
  DenseSet<unsigned> EmittedLoopIDs;
  DenseSet<unsigned> EmittedStreamIDs;
  DenseSet<unsigned> EmittedIndirectIDs;

  // Emitted config calls, kept so the post-emission sweep can erase orphans.
  SmallVector<std::pair<CallInst *, unsigned>, 8> LinkCalls;
  SmallVector<std::pair<CallInst *, unsigned>, 8> LoopCalls;
  
  // Emit intrinsics for each loop's preheader
  for (const auto &Entry : LoopsByLoop) {
    Loop *L = Entry.first;
    BasicBlock *Preheader = L->getLoopPreheader();
    
    if (!Preheader) {
      LLVM_DEBUG(dbgs() << "  Warning: Loop has no preheader, skipping\n");
      continue;
    }
    
    LLVM_DEBUG(dbgs() << "\n  Emitting for loop in BB: " 
                      << Preheader->getName() << "\n");
    
    // Create IRBuilder positioned at the end of preheader (before terminator)
    IRBuilder<> Builder(Preheader->getTerminator());
    
    // 1. Emit Link Variable configurations first (they're referenced by others)
    for (const auto *LV : LinksByLoop[L]) {
      if (EmittedLinkIDs.count(LV->LinkID)) continue;  // Skip duplicates
      
      unsigned GlobalID = LinkIDMap.lookup(LV->LinkID);
      
      // Check if the dynamic value dominates the preheader insertion point
      // This is critical: the value must be available before we use it
      Value *ValueArg = LV->DynamicValue;
      if (Instruction *ValueInst = dyn_cast<Instruction>(ValueArg)) {
        // Check if instruction is in the loop (not preheader)
        if (L->contains(ValueInst->getParent())) {
          // The instruction is inside the loop, so it doesn't dominate the preheader
          // We need to materialize a loop-invariant version
          LLVM_DEBUG(dbgs() << "    Warning: Link value is loop-variant, skipping: " 
                            << *ValueArg << "\n");
          // Skip this link - the stream should use non-linked mode
          continue;
        }
      }
      
      LLVM_DEBUG(dbgs() << "    Link GlobalID=" << GlobalID 
                        << " (Analysis ID=" << LV->LinkID << ")\n");
      
      // Prepare the value argument - must be a pointer type
      if (!ValueArg->getType()->isPointerTy()) {
        // If not already a pointer, cast it to pointer
        ValueArg = Builder.CreateIntToPtr(ValueArg, PointerType::getUnqual(Ctx));
      }
      
      // Emit: call void @llvm.interstellar.configure.link(i32 GlobalID, ptr value, i32 size)
      CallInst *LinkCall = Builder.CreateCall(ConfigLinkFn, {
        Builder.getInt32(GlobalID),
        ValueArg,
        Builder.getInt32(LV->SizeInBytes)
      });
      LinkCalls.push_back({LinkCall, LV->LinkID});

      EmittedLinkIDs.insert(LV->LinkID);
    }
    
    // 2. Emit Loop Descriptor configuration
    for (const auto *LD : LoopsByLoop[L]) {
      if (EmittedLoopIDs.count(LD->LoopID)) continue;  // Skip duplicates
      
      unsigned GlobalID = LoopIDMap.lookup(LD->LoopID);

      // Encode the parent per the engine ABI (ParentloopsIDs): NO_PARENT
      // (63) for a top-level loop, otherwise the parent's GlobalID — where 0
      // legitimately means "parent is the root loop" (PARENT_IS_LOOP1) and
      // must not be confused with "no parent". The loop's own chain decides
      // whether a parent exists because ParentLoopID 0 doubles as the root
      // loop's analysis ID.
      unsigned ParentGlobalID = 63; // NO_PARENT
      if (LD->L && LD->L->getParentLoop() && LoopIDMap.count(LD->ParentLoopID))
        ParentGlobalID = LoopIDMap.lookup(LD->ParentLoopID);
      
      // Extract start/end values (constant or link GlobalID)
      unsigned StartVal = 0;
      unsigned EndVal = 0;
      
      if (LD->IsStartLinked) {
        StartVal = LinkIDMap.lookup(LD->StartLinkID);
      } else if (LD->StartValue) {
        if (auto *C = dyn_cast<SCEVConstant>(LD->StartValue)) {
          StartVal = C->getValue()->getZExtValue();
        }
      }
      
      if (LD->IsEndLinked) {
        EndVal = LinkIDMap.lookup(LD->EndLinkID);
      } else if (LD->EndValue) {
        if (auto *C = dyn_cast<SCEVConstant>(LD->EndValue)) {
          EndVal = C->getValue()->getZExtValue();
        }
      }
      
      unsigned StepVal = 1;  // Default step
      if (LD->StepValue) {
        if (auto *C = dyn_cast<SCEVConstant>(LD->StepValue)) {
          StepVal = C->getValue()->getZExtValue();
        }
      }
      
      LLVM_DEBUG(dbgs() << "    Loop GlobalID=" << GlobalID 
                        << " (Analysis ID=" << LD->LoopID << ")"
                        << " Parent=" << ParentGlobalID
                        << " SL=" << LD->IsStartLinked
                        << " EL=" << LD->IsEndLinked << "\n");
      
      // Emit: call void @llvm.interstellar.configure.loop(...)
      CallInst *LoopCall = Builder.CreateCall(ConfigLoopFn, {
        Builder.getInt32(GlobalID),
        Builder.getInt32(ParentGlobalID),
        Builder.getInt1(LD->IsStartLinked),
        Builder.getInt1(LD->IsEndLinked),
        Builder.getInt32(StartVal),
        Builder.getInt32(EndVal),
        Builder.getInt32(StepVal)
      });
      LoopCalls.push_back({LoopCall, LD->LoopID});

      EmittedLoopIDs.insert(LD->LoopID);
    }
    
    // 3. Emit Direct Stream Descriptor configurations
    for (const auto *DS : StreamsByLoop[L]) {
      if (EmittedStreamIDs.count(DS->StreamID)) continue;  // Skip duplicates
      
      unsigned GlobalID = StreamIDMap.lookup(DS->StreamID);
      unsigned LoopGlobalID = LoopIDMap.lookup(DS->LoopID);
      
      // Check if this stream references a link that wasn't emitted (loop-variant)
      bool ActuallyLinked = resolveActuallyLinked(DS->IsBaseLinked, DS->LinkID,
                                                  EmittedLinkIDs, DS->StreamID,
                                                  "Stream");

      std::optional<Value *> BaseArg = prepareStreamBaseArg(
          Builder, L, ActuallyLinked, DS->LinkID, LinkIDMap,
          DS->BaseAddressValue, DS->BaseAddress, DS->StreamID);
      if (!BaseArg)
        continue; // loop-variant base - skip this stream entirely
      
      LLVM_DEBUG(dbgs() << "    DirectStream GlobalID=" << GlobalID 
                        << " (Analysis ID=" << DS->StreamID << ")"
                        << " Loop=" << LoopGlobalID
                        << " BL=" << ActuallyLinked
                        << " BaseAddr=" << **BaseArg
                        << " Stride=" << DS->Stride << "\n");
      
      // Emit: call void @llvm.interstellar.configure.directstream(globalid, loop, BL, base, stride)
      Builder.CreateCall(ConfigDirectStreamFn, {
        Builder.getInt32(GlobalID),
        Builder.getInt32(LoopGlobalID),
        Builder.getInt1(ActuallyLinked),
        *BaseArg,
        Builder.getInt32(DS->Stride)
      });
      
      EmittedStreamIDs.insert(DS->StreamID);
    }
    
    // 4. Emit Indirect Stream Descriptor configurations
    for (const auto *IDS : IndirectByLoop[L]) {
      if (EmittedIndirectIDs.count(IDS->StreamID)) continue;  // Skip duplicates
      
      unsigned GlobalID = IndirectIDMap.lookup(IDS->StreamID);
      unsigned SourceStreamGlobalID = 0;
      
      // Remap the index source to its GlobalID. A computed/random index has
      // no source stream (SourceID stays 0); otherwise BaseStreamID is the
      // analysis ID of the source stream — which may legitimately be 0 — and
      // may name a direct or an indirect stream (chained A[B[C[i]]]).
      if (!IDS->IsIndexComputed) {
        if (StreamIDMap.count(IDS->BaseStreamID))
          SourceStreamGlobalID = StreamIDMap.lookup(IDS->BaseStreamID);
        else if (IndirectIDMap.count(IDS->BaseStreamID))
          SourceStreamGlobalID = IndirectIDMap.lookup(IDS->BaseStreamID);
      }
      
      // Check if this stream references a link that wasn't emitted (loop-variant)
      bool ActuallyLinked = resolveActuallyLinked(IDS->IsBaseLinked, IDS->LinkID,
                                                  EmittedLinkIDs, IDS->StreamID,
                                                  "Indirect stream");

      std::optional<Value *> BaseArg = prepareStreamBaseArg(
          Builder, L, ActuallyLinked, IDS->LinkID, LinkIDMap,
          IDS->BaseAddressValue, IDS->BaseAddress, IDS->StreamID);
      if (!BaseArg)
        continue; // loop-variant base - skip this stream entirely
      
      LLVM_DEBUG(dbgs() << "    IndirectStream GlobalID=" << GlobalID 
                        << " (Analysis ID=" << IDS->StreamID << ")"
                        << " SourceStream=" << SourceStreamGlobalID
                        << " BL=" << ActuallyLinked
                        << " BaseAddr=" << **BaseArg
                        << " ElemSize=" << IDS->ElementSize << "\n");
      
      // Emit: call void @llvm.interstellar.configure.indirectstream(globalid, source, BL, base, elemsize, streamsize)
      Builder.CreateCall(ConfigIndirectStreamFn, {
        Builder.getInt32(GlobalID),
        Builder.getInt32(SourceStreamGlobalID),
        Builder.getInt1(ActuallyLinked),
        *BaseArg,
        Builder.getInt32(IDS->ElementSize),
        Builder.getInt32(IDS->StreamSize)  // Stream size (0 = unknown)
      });
      
      EmittedIndirectIDs.insert(IDS->StreamID);
    }
  }
  
  ErasedOrphanCounts Erased = eraseOrphanConfigs(
      LoopCalls, LinkCalls, Loops, DirectStreams, IndirectStreams,
      EmittedStreamIDs, EmittedIndirectIDs);

  LLVM_DEBUG(dbgs() << "\n[IR Generation] Complete:\n");
  LLVM_DEBUG(dbgs() << "  Emitted " << EmittedLinkIDs.size() - Erased.Links
                    << " link configs\n");
  LLVM_DEBUG(dbgs() << "  Emitted " << EmittedLoopIDs.size() - Erased.Loops
                    << " loop configs\n");
  LLVM_DEBUG(dbgs() << "  Emitted " << EmittedStreamIDs.size() << " direct stream configs\n");
  LLVM_DEBUG(dbgs() << "  Emitted " << EmittedIndirectIDs.size() << " indirect stream configs\n");
}

} // end anonymous namespace

/// Main IR generation entry point
/// Builds ID remapping tables and injects intrinsic calls
static void generateHardwareDescriptorIR(
    Function &F,
    const SmallVectorImpl<LoopDescriptor> &Loops,
    const SmallVectorImpl<DirectStreamDescriptor> &DirectStreams,
    const SmallVectorImpl<IndirectStreamDescriptor> &IndirectStreams,
    const SmallVectorImpl<LinkVariableDescriptor> &LinkVars) {
  
  // Step 1: Build ID remapping tables (Analysis IDs → GlobalIDs)
  DenseMap<unsigned, unsigned> LinkIDMap;
  DenseMap<unsigned, unsigned> LoopIDMap;
  DenseMap<unsigned, unsigned> StreamIDMap;
  DenseMap<unsigned, unsigned> IndirectIDMap;
  unsigned TotalDescriptorCount = 0;
  
  buildIDRemappingTables(LinkVars, Loops, DirectStreams, IndirectStreams,
                        LinkIDMap, LoopIDMap, StreamIDMap, IndirectIDMap,
                        TotalDescriptorCount);
  
  // Step 2: Inject intrinsic calls into loop preheaders
  injectDescriptorIR(F, Loops, DirectStreams, IndirectStreams, LinkVars,
                    LoopIDMap, StreamIDMap, IndirectIDMap, LinkIDMap);
}

//===----------------------------------------------------------------------===//
// Legacy Pass Manager Implementation
//===----------------------------------------------------------------------===//

char InterStellarAnalysisLegacyPass::ID = 0;

InterStellarAnalysisLegacyPass::InterStellarAnalysisLegacyPass()
    : FunctionPass(ID) {
  initializeInterStellarAnalysisLegacyPassPass(*PassRegistry::getPassRegistry());
}

bool InterStellarAnalysisLegacyPass::runOnFunction(Function &F) {
  auto &LI = getAnalysis<LoopInfoWrapperPass>().getLoopInfo();
  auto &SE = getAnalysis<ScalarEvolutionWrapperPass>().getSE();
  
  if (LI.empty()) {
    return false;
  }
  
  InterStellarStreamAnalyzer Analyzer(F, LI, SE);
  Analyzer.analyze();
  
  LLVM_DEBUG(Analyzer.print(dbgs()));
  
  
  // Analysis pass doesn't modify IR
  return false;
}

void InterStellarAnalysisLegacyPass::getAnalysisUsage(AnalysisUsage &AU) const {
  AU.setPreservesAll();
  AU.addRequired<LoopInfoWrapperPass>();
  AU.addRequired<ScalarEvolutionWrapperPass>();
}

void InterStellarAnalysisLegacyPass::print(raw_ostream &OS,
                                            const Module *M) const {
  OS << "InterStellar Analysis (Legacy Pass)\n";
}

INITIALIZE_PASS_BEGIN(InterStellarAnalysisLegacyPass, "interstellar-analysis",
                      "InterStellar Stream Analysis", false, true)
INITIALIZE_PASS_DEPENDENCY(LoopInfoWrapperPass)
INITIALIZE_PASS_DEPENDENCY(ScalarEvolutionWrapperPass)
INITIALIZE_PASS_END(InterStellarAnalysisLegacyPass, "interstellar-analysis",
                    "InterStellar Stream Analysis", false, true)

// Factory function for legacy pass manager
FunctionPass *createInterStellarAnalysisPass() {
  return new InterStellarAnalysisLegacyPass();
}
