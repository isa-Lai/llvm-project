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
#include "llvm/Analysis/ScalarEvolution.h"
#include "llvm/Analysis/ScalarEvolutionExpressions.h"
#include "llvm/IR/DataLayout.h"
#include "llvm/IR/Dominators.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/Module.h"
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
  void extractAllDynamicValues(const SCEV *S, SmallVectorImpl<Value *> &Values);
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
    
    // Extract step value
    if (Value *StepVal = Bounds->getStepValue()) {
      LD.StepValue = SE.getSCEV(StepVal);
    }
    
    FoundBounds = true;
  } else {
    // Fallback: Try getInductionVariable() + analyze PHI directly
    LLVM_DEBUG(dbgs() << "  getBounds() failed, trying getInductionVariable()\n");
    
    PHINode *IndVar = L->getInductionVariable(SE);
    
    // If getInductionVariable() fails, try to find any PHI in the header that looks like an IV
    if (!IndVar) {
      LLVM_DEBUG(dbgs() << "  getInductionVariable() returned null, scanning header PHIs\n");
      BasicBlock *Header = L->getHeader();
      for (PHINode &Phi : Header->phis()) {
        // Only analyze PHI nodes with SCEVable types (integer types)
        if (!SE.isSCEVable(Phi.getType())) {
          LLVM_DEBUG(dbgs() << "    Skipping non-SCEVable PHI: " << Phi << "\n");
          continue;
        }
        
        const SCEV *PhiSCEV = SE.getSCEV(&Phi);
        if (const SCEVAddRecExpr *AR = dyn_cast<SCEVAddRecExpr>(PhiSCEV)) {
          if (AR->getLoop() == L && AR->isAffine()) {
            IndVar = &Phi;
            LLVM_DEBUG(dbgs() << "  Found affine PHI: " << Phi << "\n");
            break;
          }
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
          
          // For end value, we need to analyze the exit condition
          // Get backedge-taken count
          const SCEV *BTC = SE.getBackedgeTakenCount(L);
          if (!isa<SCEVCouldNotCompute>(BTC)) {
            // End = Start + BTC * Step (for the last iteration)
            // But we actually want the upper bound from the comparison
            // Let's try to get it from the loop exit condition
            
            // Check both the header and latch for the exit comparison
            // After loop-simplify, the comparison is usually in the header
            BasicBlock *Header = L->getHeader();
            BasicBlock *Latch = L->getLoopLatch();
            
            auto extractBoundFromBlock = [&](BasicBlock *BB) -> bool {
              if (!BB) return false;
              BranchInst *BI = dyn_cast<BranchInst>(BB->getTerminator());
              if (BI && BI->isConditional()) {
                if (ICmpInst *Cmp = dyn_cast<ICmpInst>(BI->getCondition())) {
                  // Check which operand is the induction variable
                  Value *Op0 = Cmp->getOperand(0);
                  Value *Op1 = Cmp->getOperand(1);
                  
                  const SCEV *Op0SCEV = SE.getSCEV(Op0);
                  const SCEV *Op1SCEV = SE.getSCEV(Op1);
                  
                  // Find the non-IV operand - that's the bound value
                  // Save both the SCEV and the actual IR Value
                  if (Op0SCEV == IndVarSCEV) {
                    LD.EndValue = Op1SCEV;
                    LD.EndValueDynamic = Op1;  // Save the actual IR value
                    LLVM_DEBUG(dbgs() << "    Captured end bound from comparison Op1: " << *Op1 << "\n");
                    return true;
                  } else if (Op1SCEV == IndVarSCEV) {
                    LD.EndValue = Op0SCEV;
                    LD.EndValueDynamic = Op0;  // Save the actual IR value
                    LLVM_DEBUG(dbgs() << "    Captured end bound from comparison Op0: " << *Op0 << "\n");
                    return true;
                  }
                }
              }
              return false;
            };
            
            // Try header first (most common after loop-simplify), then latch
            if (!extractBoundFromBlock(Header)) {
              extractBoundFromBlock(Latch);
            }
            
            // If we still don't have end value, compute it from backedge-taken count
            if (!LD.EndValue) {
              // For "for (i=start; i<end; i+=step)", BTC = (end - start) / step
              // So end = start + (BTC * step)
              // For unit step (step=1), this simplifies to: end = start + BTC
              if (LD.StepValue) {
                // end = start + (BTC * step)
                const SCEV *BTCTimesStep = SE.getMulExpr(BTC, LD.StepValue);
                LD.EndValue = SE.getAddExpr(LD.StartValue, BTCTimesStep);
              } else {
                // No step value found, assume step=1
                LD.EndValue = SE.getAddExpr(LD.StartValue, BTC);
              }
            }
            
            FoundBounds = true;
          }
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
    LLVM_DEBUG(dbgs() << "  Could not extract loop bounds\n");
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
    const Loop *ARLoop = AR->getLoop();
    Loop *StreamLoop = nullptr;
    
    if (ARLoop == L) {
      // Direct AddRec case: belongs to current loop (simple pattern like A[i])
      StreamLoop = L;
    } else if (L->contains(ARLoop)) {
      // AddRec belongs to an inner loop (nested inside current loop)
      // This shouldn't happen when analyzing memory accesses in current loop
      LLVM_DEBUG(dbgs() << "  AddRec belongs to inner loop, skipping\n");
      return false;
    } else {
      // Check if AddRec belongs to any parent loop
      Loop *ParentLoop = L->getParentLoop();
      while (ParentLoop) {
        if (ARLoop == ParentLoop) {
          StreamLoop = ParentLoop;
          LLVM_DEBUG(dbgs() << "  AddRec belongs to parent loop (outer loop stream)\n");
          break;
        }
        ParentLoop = ParentLoop->getParentLoop();
      }
      
      if (!StreamLoop) {
        // AddRec belongs to unrelated loop
        LLVM_DEBUG(dbgs() << "  AddRec belongs to unrelated loop\n");
        return false;
      }
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
  for (auto IdxIt = GEP->idx_begin(); IdxIt != GEP->idx_end(); ++IdxIt) {
    Index = IdxIt->get(); // Get the last index
  }
  
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
  while (const SCEVCastExpr *Cast = dyn_cast<SCEVCastExpr>(UnwrappedIndexSCEV)) {
    UnwrappedIndexSCEV = Cast->getOperand();
  }
  
  // Check if the index is a sum of loop-invariant and loop-variant parts
  if (const SCEVAddExpr *AddExpr = dyn_cast<SCEVAddExpr>(UnwrappedIndexSCEV)) {
    SmallVector<const SCEV *, 4> InvariantOps;
    
    for (const SCEV *Op : AddExpr->operands()) {
      // Unwrap casts on operands
      const SCEV *UnwrappedOp = Op;
      while (const SCEVCastExpr *Cast = dyn_cast<SCEVCastExpr>(UnwrappedOp)) {
        UnwrappedOp = Cast->getOperand();
      }
      
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
        LoopInvariantPart = SE.getAddExpr(InvariantOps);
      }
      
      // Calculate memory stride: affine_step * element_size
      const SCEV *AffineStep = AffinePartAR->getStepRecurrence(SE);
      const SCEVConstant *StepConst = dyn_cast<SCEVConstant>(AffineStep);
      
      if (!StepConst) {
        LLVM_DEBUG(dbgs() << "  Affine step is not constant, cannot create direct stream\n");
        return false;
      }
      
      Type *ElementType = GEP->getSourceElementType();
      if (ArrayType *ArrTy = dyn_cast<ArrayType>(ElementType)) {
        ElementType = ArrTy->getElementType();
      }
      int64_t ElementSize = getTypeSizeInBytes(ElementType);
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
  while (const SCEVCastExpr *Cast = dyn_cast<SCEVCastExpr>(IndVarSCEV)) {
    IndVarSCEV = Cast->getOperand();
  }
  
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
      while (const SCEVCastExpr *Cast = dyn_cast<SCEVCastExpr>(UnwrappedOp)) {
        UnwrappedOp = Cast->getOperand();
      }
      
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
            ConstantOffset = SE.getAddExpr(OtherOperands);
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
  const Loop *ARLoop = AR->getLoop();
  Loop *StreamLoop = nullptr;
  
  if (ARLoop == L) {
    // Direct case: AddRec belongs to current loop (e.g., inner loop analyzing B[j])
    StreamLoop = L;
  } else if (L->contains(ARLoop)) {
    // AddRec belongs to an inner loop - not applicable for this analysis context
    LLVM_DEBUG(dbgs() << "  AddRec belongs to inner loop, skipping\n");
    return false;
  } else {
    // Check if AddRec belongs to any parent loop
    // For nested loops: A[i] analyzed from inner loop, where i is outer loop variable
    Loop *ParentLoop = L->getParentLoop();
    while (ParentLoop) {
      if (ARLoop == ParentLoop) {
        // Found it! This stream belongs to the parent loop
        StreamLoop = ParentLoop;
        LLVM_DEBUG(dbgs() << "  AddRec belongs to parent loop (outer loop stream)\n");
        break;
      }
      ParentLoop = ParentLoop->getParentLoop();
    }
    
    if (!StreamLoop) {
      // AddRec belongs to unrelated loop
      LLVM_DEBUG(dbgs() << "  AddRec belongs to unrelated loop\n");
      return false;
    }
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
  Type *ElementType = GEP->getSourceElementType();
  // For array types like [1000 x i32], get the actual element type
  if (ArrayType *ArrTy = dyn_cast<ArrayType>(ElementType)) {
    ElementType = ArrTy->getElementType();
  }
  int64_t ElementSize = getTypeSizeInBytes(ElementType);
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
  if (const SCEVAddRecExpr *BaseAR = dyn_cast<SCEVAddRecExpr>(BasePtrSCEV)) {
    if (BaseAR->getLoop() != L && BaseAR->getLoop()->contains(L)) {
      // Base contains an AddRecExpr from an outer loop
      // Use BasePtr (e.g., %invariant.gep) as the dynamic value
      OuterLoopBaseValue = BasePtr;
      LLVM_DEBUG(dbgs() << "  Base contains outer-loop AddRecExpr, using BasePtr as link variable: " 
                        << *BasePtr << "\n");
    }
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
  createDirectStream(BaseSCEV, MemoryStride, StreamLoop, MemInst, AccumulatedOffset, OuterLoopBaseValue);
  
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
  if (AllConstantIndices) {
    if (GetElementPtrInst *ParentGEP = dyn_cast<GetElementPtrInst>(GEP->getPointerOperand())) {
      // Found a parent GEP - use it as the root for indirect analysis
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
  for (auto IdxIt = RootGEP->idx_begin(); IdxIt != RootGEP->idx_end(); ++IdxIt) {
    Index = IdxIt->get(); // Get the last index
  }
  
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
  
  // Calculate element size from the root GEP (the one with the indirect index)
  Type *ElementType = RootGEP->getSourceElementType();
  if (ArrayType *ArrTy = dyn_cast<ArrayType>(ElementType)) {
    ElementType = ArrTy->getElementType();
  }
  int64_t ElemSize = getTypeSizeInBytes(ElementType);
  
  LLVM_DEBUG(dbgs() << "    Base pointer: " << *BasePtr << "\n");
  LLVM_DEBUG(dbgs() << "    Element type: " << *ElementType << "\n");
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
  
  // Handle dynamic base address (e.g., A is a function parameter)
  if (IDS.IsBaseLinked) {
    IDS.BaseAddressValue = extractDynamicValue(BaseSCEV, L);
    if (IDS.BaseAddressValue) {
      Type *BaseTy = IDS.BaseAddressValue->getType();
      unsigned Size = BaseTy->isPointerTy() ? 8 : getTypeSizeInBytes(BaseTy);
      IDS.LinkID = getOrCreateLinkID(IDS.BaseAddressValue, Size);
    }
  }
  
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
        for (auto IdxIt = GEP->idx_begin(); IdxIt != GEP->idx_end(); ++IdxIt) {
          Index = IdxIt->get();
        }
        
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
  
  // First, check the standard case
  if (SE.isLoopInvariant(S, L)) {
    return true;
  }
  
  // Unwrap casts
  const SCEV *Unwrapped = S;
  while (const SCEVCastExpr *Cast = dyn_cast<SCEVCastExpr>(Unwrapped)) {
    Unwrapped = Cast->getOperand();
  }
  
  // Check for AddRecExpr from parent loops (loop-invariant for current loop)
  if (const SCEVAddRecExpr *AR = dyn_cast<SCEVAddRecExpr>(Unwrapped)) {
    const Loop *ARLoop = AR->getLoop();
    
    // If AddRec is for the current loop, it's NOT invariant
    if (ARLoop == L) {
      return false;
    }
    
    // If AddRec is for a parent loop, it's effectively invariant for current loop
    Loop *ParentLoop = L->getParentLoop();
    while (ParentLoop) {
      if (ARLoop == ParentLoop) {
        return true;  // Depends on outer loop, invariant for current loop
      }
      ParentLoop = ParentLoop->getParentLoop();
    }
    
    // AddRec for unrelated loop or inner loop - not invariant
    return false;
  }
  
  // Check composite expressions recursively
  if (const SCEVNAryExpr *NAry = dyn_cast<SCEVNAryExpr>(Unwrapped)) {
    // All operands must be effectively invariant
    for (const SCEV *Op : NAry->operands()) {
      if (!isEffectivelyLoopInvariant(Op, L)) {
        return false;
      }
    }
    return true;
  }
  
  if (const SCEVUDivExpr *UDiv = dyn_cast<SCEVUDivExpr>(Unwrapped)) {
    return isEffectivelyLoopInvariant(UDiv->getLHS(), L) &&
           isEffectivelyLoopInvariant(UDiv->getRHS(), L);
  }
  
  // SCEVUnknown: Check if it's based on values from outer loops or constants
  if (const SCEVUnknown *Unknown = dyn_cast<SCEVUnknown>(Unwrapped)) {
    Value *V = Unknown->getValue();
    
    // Constants and globals are invariant
    if (isa<Constant>(V) || isa<GlobalVariable>(V)) {
      return true;
    }
    
    // Function arguments are loop-invariant for all loops
    if (isa<Argument>(V)) {
      return true;
    }
    
    // Check if this value is defined outside the loop
    if (Instruction *I = dyn_cast<Instruction>(V)) {
      // If defined outside loop, it's invariant
      if (!L->contains(I->getParent())) {
        return true;
      }
      
      // CRITICAL: If instruction is a call, it's NOT effectively invariant
      // Example: rand() returns different values each iteration
      if (isa<CallInst>(I) || isa<InvokeInst>(I)) {
        LLVM_DEBUG(dbgs() << "  Value is a call instruction inside loop, NOT invariant: " << *I << "\n");
        return false;
      }
      
      // CRITICAL: If instruction may have side effects or may read/write memory,
      // it cannot be considered loop-invariant
      if (I->mayHaveSideEffects() || I->mayReadFromMemory()) {
        // Exception: LoadInst from loop-invariant address is okay
        // Example: A[i] where i is outer loop variable
        if (LoadInst *Load = dyn_cast<LoadInst>(I)) {
          Value *Ptr = Load->getPointerOperand();
          const SCEV *PtrSCEV = SE.getSCEV(Ptr);
          
          // Check if the load address is effectively invariant
          if (isEffectivelyLoopInvariant(PtrSCEV, L)) {
            LLVM_DEBUG(dbgs() << "  Load from effectively invariant address: " << *Load << "\n");
            return true;
          }
        }
        
        LLVM_DEBUG(dbgs() << "  Instruction has side effects or reads memory, NOT invariant: " << *I << "\n");
        return false;
      }
      
      // If defined inside loop, check if it only depends on loop-invariant values
      // This handles cases like: idx_i = A[i] % D2_rows where A[i] depends on outer loop
      for (Use &U : I->operands()) {
        Value *Operand = U.get();
        const SCEV *OpSCEV = SE.getSCEV(Operand);
        
        if (!isEffectivelyLoopInvariant(OpSCEV, L)) {
          return false;  // Depends on loop-varying value
        }
      }
      
      // All operands are effectively invariant and no side effects
      return true;
    }
    
    // Unknown case - conservatively return false
    return false;
  }
  
  // Default: not invariant
  return false;
}

Value *InterStellarStreamAnalyzer::extractDynamicValue(const SCEV *S, Loop *L) {
  // Strategy: For a dynamic SCEV expression like (N+M), find the instruction
  // that computes this value. This instruction will be materialized into a
  // register during code generation.
  
  // Unwrap any cast expressions
  while (const SCEVCastExpr *Cast = dyn_cast<SCEVCastExpr>(S)) {
    S = Cast->getOperand();
  }
  
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
      while (const SCEVCastExpr *Cast = dyn_cast<SCEVCastExpr>(InstSCEV)) {
        InstSCEV = Cast->getOperand();
      }
      
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
  
  // Recursively search for SCEVAddExpr or SCEVMulExpr containing only dynamic values
  std::function<const SCEV*(const SCEV*)> findDynamicCore = [&](const SCEV *Current) -> const SCEV* {
    // If it's a simple unknown, that's a dynamic value
    if (isa<SCEVUnknown>(Current))
      return Current;
    
    // For Add/Mul expressions, check if they contain multiple dynamic operands
    if (const SCEVAddExpr *Add = dyn_cast<SCEVAddExpr>(Current)) {
      // Count dynamic operands
      SmallVector<const SCEV *, 4> DynamicOps;
      for (const SCEV *Op : Add->operands()) {
        while (const SCEVCastExpr *Cast = dyn_cast<SCEVCastExpr>(Op))
          Op = Cast->getOperand();
        if (isa<SCEVUnknown>(Op))
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
        if (const SCEV *Core = findDynamicCore(Op))
          return Core;
      }
    } else if (const SCEVCastExpr *Cast = dyn_cast<SCEVCastExpr>(Current)) {
      return findDynamicCore(Cast->getOperand());
    } else if (const SCEVUDivExpr *UDiv = dyn_cast<SCEVUDivExpr>(Current)) {
      if (const SCEV *Core = findDynamicCore(UDiv->getLHS()))
        return Core;
      if (const SCEV *Core = findDynamicCore(UDiv->getRHS()))
        return Core;
    }
    
    return nullptr;
  };
  
  // Try to find the core dynamic expression
  if (const SCEV *Core = findDynamicCore(S)) {
    if (const SCEVUnknown *U = dyn_cast<SCEVUnknown>(Core))
      return U->getValue();
    
    // Try to find an instruction computing this core expression
    if (Value *V = findMatchingInstruction(Preheader, Core))
      return V;
    if (Value *V = findMatchingInstruction(Header, Core))
      return V;
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

void InterStellarStreamAnalyzer::extractAllDynamicValues(const SCEV *S, 
                                                         SmallVectorImpl<Value *> &Values) {
  // Extract SCEVUnknown values
  if (const SCEVUnknown *Unknown = dyn_cast<SCEVUnknown>(S)) {
    Value *V = Unknown->getValue();
    // Avoid duplicates and only add if not already in the list
    if (V && !is_contained(Values, V)) {
      Values.push_back(V);
    }
    return;
  }
  
  // Recursively process composite expressions
  if (const SCEVNAryExpr *NAry = dyn_cast<SCEVNAryExpr>(S)) {
    for (const SCEV *Op : NAry->operands()) {
      extractAllDynamicValues(Op, Values);
    }
  } else if (const SCEVCastExpr *Cast = dyn_cast<SCEVCastExpr>(S)) {
    extractAllDynamicValues(Cast->getOperand(), Values);
  } else if (const SCEVUDivExpr *UDiv = dyn_cast<SCEVUDivExpr>(S)) {
    extractAllDynamicValues(UDiv->getLHS(), Values);
    extractAllDynamicValues(UDiv->getRHS(), Values);
  }
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
      BaseVal = extractDynamicValue(AdjustedBase, L);
    }
    
    if (BaseVal) {
      Type *BaseTy = BaseVal->getType();
      unsigned Size = BaseTy->isPointerTy() ? 8 : getTypeSizeInBytes(BaseTy);
      DS.LinkID = getOrCreateLinkID(BaseVal, Size);
      ++NumDynamicBases;
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
  OS << "   • Link variables: " << LinkVariables.size() << "\n\n";
  
  if (!LoopDescriptors.empty()) {
    OS << " Loop Descriptors (Hardware CSR Format):\n";
    OS << "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n";
    for (const auto &LD : LoopDescriptors) {
      OS << "Loop ID: " << LD.LoopID;
      // Check if this loop actually has a parent (not just ParentLoopID value)
      bool hasParent = LD.L && LD.L->getParentLoop();
      if (hasParent) {
        OS << " (nested inside Loop " << LD.ParentLoopID << ")";
      }
      OS << "\n";
      
      // Print loop source location
      if (LD.Loc) {
        OS << "  ├─ Source Location: ";
        LD.Loc.print(OS);
        OS << "\n";
      }
      
      // Parent Loop ID (if nested)
      if (hasParent) {
        OS << "  ├─ Parent Loop: " << LD.ParentLoopID << " [Nesting Level]\n";
      }
      
      // Start Value
      OS << "  ├─ Start Value: ";
      if (LD.StartValue) {
        OS << *LD.StartValue;
        if (LD.IsStartLinked) {
          OS << "   [SL=1, Dynamic, LinkID=" << LD.StartLinkID << "]";
          if (LD.StartValueDynamic) {
            OS << "\n  │              = " << *LD.StartValueDynamic;
          }
        } else {
          OS << "  [SL=0, Constant]";
        }
      } else {
        OS << "(unknown)";
      }
      OS << "\n";
      
      // End Value
      OS << "  ├─ End Value:   ";
      if (LD.EndValue) {
        OS << *LD.EndValue;
        if (LD.IsEndLinked) {
          OS << "   [EL=1, Dynamic, LinkID=" << LD.EndLinkID << "]";
          if (LD.EndValueDynamic) {
            OS << "\n  │              = " << *LD.EndValueDynamic;
          }
        } else {
          OS << "  [EL=0, Constant]";
        }
      } else {
        OS << "(unknown)";
      }
      OS << "\n";
      
      // Step Value
      OS << "  └─ Step Value:  ";
      if (LD.StepValue) {
        OS << *LD.StepValue;
      } else {
        OS << "(unknown)";
      }
      OS << "\n\n";
    }
  }
  
  if (!DirectStreams.empty()) {
    OS << "  Direct Streams (Constant Stride Patterns):\n";
    OS << "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n";
    for (const auto &DS : DirectStreams) {
      OS << "Stream ID: " << DS.StreamID << " (Loop " << DS.LoopID << ")\n";
      
      // Source location
      if (DS.Loc) {
        OS << "  ├─ Source Location: ";
        DS.Loc.print(OS);
        OS << "\n";
      }
      
      // Base Address
      OS << "  ├─ Base Address: " << *DS.BaseAddress;
      if (DS.IsBaseLinked) {
        OS << "   [BL=1, Dynamic, LinkID=" << DS.LinkID << "]";
        if (DS.BaseAddressValue) {
          OS << "\n  │              = " << *DS.BaseAddressValue;
        }
      } else {
        OS << "  [BL=0, Static]";
      }
      OS << "\n";
      
      // Stride
      OS << "  ├─ Stride:       " << DS.Stride << " bytes\n";
      
      // Source instruction
      if (DS.MemInst) {
        OS << "  └─ Source:       " << *DS.MemInst << "\n";
      }
      OS << "\n";
    }
  }
  
  if (!IndirectStreams.empty()) {
    OS << "  Indirect Streams (Index-Based Access Patterns like A[B[i]]):\n";
    OS << "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n";
    for (const auto &IDS : IndirectStreams) {
      OS << "Stream ID: " << IDS.StreamID << " (Loop " << IDS.LoopID << ")\n";
      
      // Source location
      if (IDS.Loc) {
        OS << "  ├─ Source Location: ";
        IDS.Loc.print(OS);
        OS << "\n";
      }
      
      // Base Address
      OS << "  ├─ Base Address:   " << *IDS.BaseAddress;
      if (IDS.IsBaseLinked) {
        OS << "   [BL=1, Dynamic, LinkID=" << IDS.LinkID << "]";
        if (IDS.BaseAddressValue) {
          OS << "\n  │                = " << *IDS.BaseAddressValue;
        }
      } else {
        OS << "  [BL=0, Static]";
      }
      OS << "\n";
      
      // Element Size
      OS << "  ├─ Element Size:   " << IDS.ElementSize << " bytes\n";
      
      // Index Source Stream or Computed
      if (IDS.IsIndexComputed) {
        OS << "  ├─ Index Type:     COMPUTED/RANDOM (no stream dependency)\n";
      } else {
        OS << "  ├─ Index Stream:   Stream #" << IDS.BaseStreamID 
           << " (indices provided by this stream)\n";
      }
      
      // Source instruction
      if (IDS.MemInst) {
        OS << "  └─ Source:         " << *IDS.MemInst << "\n";
      }
      OS << "\n";
    }
  }
  
  if (!LinkVariables.empty()) {
    OS << "  Link Variable Descriptors (Dynamic Runtime Values):\n";
    OS << "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n";
    for (const auto &LV : LinkVariables) {
      OS << "Link ID: " << LV.LinkID << "\n";
      OS << "  ├─ IR Value:  " << *LV.DynamicValue << "\n";
      OS << "  └─ Size:      " << LV.SizeInBytes << " bytes\n";
    }
  }
  
  OS << "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n";
}

} // anonymous namespace

//===----------------------------------------------------------------------===//
// Pass 2: Global Stream Optimization (Module-Level Transformation)
//===----------------------------------------------------------------------===//

namespace {

/// Signature for direct stream deduplication (Stage 1.1)
struct StreamSignature {
  unsigned LoopID;
  const SCEV *BaseAddress;
  int64_t Stride;
  
  bool operator==(const StreamSignature &Other) const {
    return LoopID == Other.LoopID && 
           BaseAddress == Other.BaseAddress &&
           Stride == Other.Stride;
  }
};

/// Signature for indirect stream deduplication (Stage 1.1)
/// Indirect streams are considered duplicates if they access the same base address
/// with the same element size and the same index source (either a stream ID or computed)
struct IndirectStreamSignature {
  unsigned LoopID;
  const SCEV *BaseAddress;
  int64_t ElementSize;
  bool IsIndexComputed;     // True if index is computed (not from stream)
  unsigned BaseStreamID;    // Index stream ID (only relevant if !IsIndexComputed)
  
  bool operator==(const IndirectStreamSignature &Other) const {
    return LoopID == Other.LoopID && 
           BaseAddress == Other.BaseAddress &&
           ElementSize == Other.ElementSize &&
           IsIndexComputed == Other.IsIndexComputed &&
           (IsIndexComputed || BaseStreamID == Other.BaseStreamID);
  }
};

/// Merge candidate from linearization analysis (Stage 1.2)
struct StreamMergeCandidate {
  unsigned StreamID;           // Stream that may be linearized
  unsigned InnerLoopID;        // Loop containing the stream
  unsigned OuterLoopID;        // Parent loop for potential merge
  Value *RequiredBound;        // Runtime value that must match physical dimension
  const SCEV *ExpectedStride;  // Expected outer loop stride (for verification)
  SmallVector<unsigned, 2> RequiredDimensions; // For multi-dimensional arrays
};

/// Pass 2 Optimizer - Performs interprocedural analysis and stream optimization
/// 
/// This class implements the three-stage global optimization pipeline:
/// Stage 1: Intraprocedural optimization (local CFG analysis)
/// Stage 2: Interprocedural validation (call graph analysis)
/// Stage 3: Transformation & realization (function specialization)
///
/// The goal is to maximize memory-level parallelism by:
/// - Eliminating redundant stream descriptors
/// - Merging nested loops into virtual loops when safe
/// - Specializing functions based on calling context
class InterStellarGlobalOptimizer {
public:
  //===--------------------------------------------------------------------===//
  // Helper Data Structures for Pass 2
  //===--------------------------------------------------------------------===//
  
  /// Allocation information from interprocedural tracing (Stage 2.1)
  struct AllocationInfo {
    enum class Kind {
      StaticArray,    // Stack alloca with known dimensions
      GlobalArray,    // Global variable with known dimensions
      HeapAllocation, // malloc/new with possibly-known size
      Opaque          // Unknown (parameter, complex computation)
    };
    
    Kind AllocKind;
    SmallVector<uint64_t, 4> Dimensions; // Physical dimensions (if known)
    Value *AllocationSite;                // Instruction defining allocation
  };
  
  /// Call site classification result (Stage 2.2)
  struct CallSiteClassification {
    SmallVector<CallBase *, 4> SafeCallSites;   // Bounds match physical layout
    SmallVector<CallBase *, 4> UnsafeCallSites; // Bounds mismatch or unknown
  };
  
  /// Function specialization result (Stage 3.1)
  struct SpecializationResult {
    enum class Action {
      InPlaceOptimization,  // All call sites safe
      FunctionCloning,      // Mixed safe/unsafe sites
      NoOptimization        // All call sites unsafe
    };
    
    Action SpecializationAction;
    Function *OptimizedFunction;   // F_linear clone (if cloning applied)
    Function *OriginalFunction;    // Original F (unchanged)
  };

  InterStellarGlobalOptimizer(Module &M, ModuleAnalysisManager &MAM)
      : M(M), MAM(MAM) {}
  
  /// Run the global optimization pipeline
  /// Returns true if the module was modified
  // bool optimize();  // Commented out - not currently used
  
private:
  Module &M;
  ModuleAnalysisManager &MAM;
  
  //===--------------------------------------------------------------------===//
  // Stage 1: Intraprocedural Optimization (Local CFG Analysis)
  //===--------------------------------------------------------------------===//
  
  // Methods commented out - functionality moved to InterStellarAnalysisPass::run()
  // for simpler integration. Full module-level optimization requires separate
  // module pass infrastructure.
  
  /*
  /// Stage 1.1: Stream Redundancy Elimination
  void eliminateRedundantStreams(Function &F,
                                 SmallVectorImpl<DirectStreamDescriptor> &Streams,
                                 DominatorTree &DT);
  
  /// Stage 1.2: Linearization Feasibility Analysis
  SmallVector<StreamMergeCandidate, 4> 
  analyzeMergeFeasibility(Function &F,
                         const SmallVectorImpl<DirectStreamDescriptor> &Streams,
                         const SmallVectorImpl<LoopDescriptor> &Loops,
                         ScalarEvolution &SE,
                         LoopInfo &LI);
  */
  
  //===--------------------------------------------------------------------===//
  // Stage 2: Interprocedural Validation (Call Graph Analysis)
  //===--------------------------------------------------------------------===//
  
  /// Stage 2.1: Allocation Site Tracing
  ///
  /// Traces pointer arguments back to their allocation sites to determine
  /// the physical memory layout. This validates the "Contract" from Stage 1.
  ///
  /// For function: void foo(int *A, int M, int N)
  /// At call site:  foo(buffer, 100, 200)
  ///
  /// This function answers: "What are the physical dimensions of buffer?"
  ///
  /// Algorithm (Backward Def-Use Traversal):
  /// 1. For each CallSite calling Function F:
  ///    a. Get actual pointer argument passed to F
  ///    b. Trace backward through Use-Def chain in Caller's CFG
  ///    c. Handle GetElementPtr: accumulate offsets, track base operand
  ///    d. Termination cases:
  ///       - AllocaInst: Extract ArrayType dimensions → KNOWN
  ///       - GlobalVariable: Extract ConstantData dimensions → KNOWN
  ///       - CallInst (malloc): Analyze size parameter if constant → MAYBE KNOWN
  ///       - Another function parameter: → OPAQUE (unknown)
  ///
  /// Example traces:
  ///   buffer = alloca [100 x [200 x i32]] → Dim = {100, 200}
  ///   buffer = @global_array → Extract from GlobalVariable type
  ///   buffer = malloc(N * M * 4) → Opaque (size is computed)
  ///   buffer = received from caller → Opaque (recursive parameter passing)
  ///
  /// Precondition: Call graph available
  /// Postcondition: Each call site annotated with allocation info
  ///
  /// @param CS Call site to analyze
  /// @param ArgIndex Index of pointer argument in callee signature
  /// @return Allocation info (dimensions if known, OPAQUE otherwise)
  AllocationInfo traceAllocationSite(CallBase *CS, unsigned ArgIndex);
  
  /// Stage 2.2: Bound Verification Check
  ///
  /// Verifies the "Contract" from Stage 1 by comparing:
  ///   - Physical memory layout (from Stage 2.1)
  ///   - Runtime loop bound values (from call site arguments)
  ///
  /// For merge candidate: "for (j in M) { A[i][j]... }" where M is parameter
  /// This function checks at each call site:
  ///   Does actual M match physical row size of actual A?
  ///
  /// Classification:
  ///   SAFE:   Constant M matches physical dimension exactly
  ///   UNSAFE: M is smaller (partial row), M is symbolic, or allocation is OPAQUE
  ///
  /// Algorithm:
  /// 1. For each MergeCandidate C:
  ///    a. Get RequiredBound B (e.g., loop bound M)
  ///    b. For each call site CS of function containing C:
  ///       i.   Extract Dim_phys from traceAllocationSite()
  ///       ii.  Extract Val_bound from call site actual arguments
  ///       iii. Compare:
  ///            - If Val_bound is ConstantInt: Safe ⟺ Val == Dim_phys
  ///            - If Val_bound is symbolic: Check if derived from same dimension
  ///            - If allocation is OPAQUE: Unsafe
  ///    c. Partition call sites: Set_Safe, Set_Unsafe
  ///
  /// Precondition: Allocation sites traced for all call sites
  /// Postcondition: Each call site classified as SAFE or UNSAFE for merging
  ///
  /// @param Candidate Merge candidate from Stage 1.2
  /// @param CallSites All call sites invoking the function containing the candidate
  /// @return Classification {Set_Safe, Set_Unsafe}
  CallSiteClassification verifyBoundsAtCallSites(
      const StreamMergeCandidate &Candidate,
      ArrayRef<CallBase *> CallSites);
  
  //===--------------------------------------------------------------------===//
  // Stage 3: Transformation & Realization (Function Specialization)
  //===--------------------------------------------------------------------===//
  
  /// Stage 3.1: Function Specialization Strategy
  ///
  /// Based on call site classification from Stage 2, decides whether to:
  /// A. Apply optimization in-place (all call sites safe)
  /// B. Clone function and specialize (mixed safe/unsafe call sites)
  /// C. Abort optimization (all call sites unsafe)
  ///
  /// Transformation decision tree:
  ///   Set_Unsafe == ∅ → Scenario A: In-place linearization
  ///   Set_Safe ≠ ∅ AND Set_Unsafe ≠ ∅ → Scenario B: Function cloning
  ///   Set_Safe == ∅ → Scenario C: Abort (emit nested descriptors)
  ///
  /// Scenario B (Function Cloning):
  /// 1. Clone function F → F_linear
  /// 2. Update Set_Safe call sites to invoke F_linear
  /// 3. Apply loop linearization to F_linear only
  /// 4. Leave original F unchanged (handles Set_Unsafe)
  ///
  /// This preserves correctness: unsafe contexts use nested streams,
  /// safe contexts benefit from flattened streams.
  ///
  /// Precondition: Call sites classified into Safe/Unsafe sets
  /// Postcondition: Module IR transformed (clones created, calls redirected)
  ///
  /// @param F Original function containing merge candidate
  /// @param Classification Call site safety classification
  /// @param Candidate Merge candidate to realize
  /// @return SpecializationResult {OptimizedFunction, TransformationType}
  SpecializationResult specializeFunction(
      Function &F,
      const CallSiteClassification &Classification,
      const StreamMergeCandidate &Candidate);
  
  /// Stage 3.2: Loop Linearization Transformation
  ///
  /// Transforms nested physical loops into virtual loops for hardware prefetch:
  ///   Before: for (i in N) { for (j in M) { A[i*M + j]... } }
  ///   After:  for (virt in N*M) { A[virt]... } [VIRTUAL LOOP - no branch in ASM]
  ///
  /// This transformation ONLY affects metadata generation, NOT the actual IR loops.
  /// The physical loops remain in code; we create a "Virtual Loop Descriptor"
  /// that tells hardware to treat nested accesses as one linear stream.
  ///
  /// Steps:
  /// 1. Preheader Injection:
  ///    - Locate preheader of outer loop L_outer
  ///    - IR Builder: NewMul = CreateMul(Bound_outer, Bound_inner)
  ///    - Create LinkVariableDescriptor for NewMul
  ///
  /// 2. Virtual Loop Descriptor Creation:
  ///    - Loop_virt.Bound = LinkID(NewMul)
  ///    - Loop_virt.Step = 1
  ///    - Loop_virt.Parent = ParentOf(L_outer) [skips nested structure]
  ///
  /// 3. Stream Promotion:
  ///    - Update stream S to reference Loop_virt (not L_inner)
  ///    - Recalculate BaseAddress SCEV relative to L_outer
  ///    - Stride remains element size (e.g., 4 bytes for int)
  ///
  /// Example metadata transformation:
  ///   Before: Loop[0]: for i in N, Loop[1]: for j in M (parent=0)
  ///           Stream: base=A[i*M], stride=4, loop=1
  ///   After:  Loop[0]: for i in N, Loop[VIRT]: for v in N*M
  ///           Stream: base=A, stride=4, loop=VIRT
  ///
  /// Precondition: Function is safe for linearization (verified in Stage 2)
  /// Postcondition: Stream descriptors updated to reference virtual loop
  ///
  /// @param F Function to transform
  /// @param Candidate Merge candidate with verified safety
  /// @param Streams Stream descriptors to update (modified in-place)
  /// @param Loops Loop descriptors to update (modified in-place)
  void applyLoopLinearization(
      Function &F,
      const StreamMergeCandidate &Candidate,
      SmallVectorImpl<DirectStreamDescriptor> &Streams,
      SmallVectorImpl<LoopDescriptor> &Loops);
  
  /// Stage 3.3: Multi-Dimensional Loop Collapsing
  ///
  /// Handles multi-layer nested loops (3D+ arrays) by progressively merging
  /// dimensions that satisfy the continuity equation.
  ///
  /// Example: for (i in N) { for (j in M) { for (k in P) { A[i][j][k]... } } }
  ///
  /// Analysis results:
  ///   - P matches innermost dimension of A: OK
  ///   - M matches middle dimension of A: OK
  ///   - Can merge to: for (i in N) { for (virt in M*P) { A[i][virt]... } }
  ///   - Or fully merge to: for (virt in N*M*P) { A[virt]... }
  ///
  /// Progressive merging strategy:
  ///   1. Start from innermost loop (k)
  ///   2. Check if next outer loop (j) can merge with k
  ///      - Verify: Stride_j == Span_k
  ///      - Verify: Bound_k matches physical dimension
  ///   3. If yes, create virtual loop for (j*k)
  ///   4. Repeat with next outer loop (i) and virtual (j*k)
  ///   5. Stop when continuity breaks or reach outermost loop
  ///
  /// Partial merges are valid:
  ///   - If only k-dimension matches: merge k, keep i and j separate
  ///   - If k and j match: merge (j*k), keep i separate
  ///   - If all match: fully flatten to (i*j*k)
  ///
  /// Precondition: Single merge candidate validated
  /// Postcondition: Maximum safe merging applied (innermost-first strategy)
  ///
  /// @param F Function containing nested loops
  /// @param InnerCandidate Innermost merge candidate (verified safe)
  /// @param Streams Stream descriptors to update
  /// @param Loops Loop descriptors to update
  /// @return Number of dimensions successfully merged
  unsigned collapseMultiDimensionalLoops(
      Function &F,
      const StreamMergeCandidate &InnerCandidate,
      SmallVectorImpl<DirectStreamDescriptor> &Streams,
      SmallVectorImpl<LoopDescriptor> &Loops);
};

} // anonymous namespace

//===----------------------------------------------------------------------===//
// Pass 2 Implementation
// NOTE: optimize() and helper methods are currently not used.
// Stage 1 functionality (redundancy elimination and linearization analysis)
// has been integrated directly into InterStellarAnalysisPass::run() for simpler
// implementation. Full module-level optimization would require separate module pass.
//===----------------------------------------------------------------------===//

namespace {

/*
bool InterStellarGlobalOptimizer::optimize() {
  LLVM_DEBUG(dbgs() << "\n"
                    << "╔═══════════════════════════════════════════════════╗\n"
                    << "║  InterStellar Pass 2: Global Stream Optimization  ║\n"
                    << "╚═══════════════════════════════════════════════════╝\n");
  
  // NOTE: Full implementation of Pass 2 requires:
  // 1. Module-level pass infrastructure (not function-level)
  // 2. Call graph analysis for interprocedural optimization
  // 3. Function cloning capabilities for specialization
  //
  // Current implementation provides:
  // - Stage 1.1: Stream redundancy elimination (deduplication)
  // - Stage 1.2: Linearization feasibility analysis (SCEV-based)
  //
  // Interprocedural analysis (Stage 2) and transformation (Stage 3)
  // require architectural changes to integrate as a proper module pass.
  
  bool ModuleModified = false;
  
  // Process each function in the module
  for (Function &F : M) {
    if (F.isDeclaration())
      continue;
    
    LLVM_DEBUG(dbgs() << "\n" << "Processing function: " << F.getName() << "\n");
    
    // Get required analyses for this function
    FunctionAnalysisManager &FAM = MAM.getResult<FunctionAnalysisManagerModuleProxy>(M).getManager();
    
    auto &LI = FAM.getResult<LoopAnalysis>(F);
    auto &SE = FAM.getResult<ScalarEvolutionAnalysis>(F);
    auto &DT = FAM.getResult<DominatorTreeAnalysis>(F);
    
    // Skip functions with no loops
    if (LI.empty()) {
      LLVM_DEBUG(dbgs() << "  No loops found - skipping\n");
      continue;
    }
    
    // Run Pass 1 analysis to get stream descriptors
    InterStellarStreamAnalyzer Analyzer(F, LI, SE);
    if (!Analyzer.analyze()) {
      LLVM_DEBUG(dbgs() << "  No streams detected - skipping\n");
      continue;
    }
    
    // Get analysis results
    SmallVector<DirectStreamDescriptor, 8> Streams = Analyzer.getDirectStreams();
    SmallVector<LoopDescriptor, 4> Loops = Analyzer.getLoopDescriptors();
    
    LLVM_DEBUG(dbgs() << "  Pass 1 found " << Streams.size() << " streams in " 
                      << Loops.size() << " loops\n");
    
    // Stage 1.1: Stream Redundancy Elimination
    if (!Streams.empty()) {
      eliminateRedundantStreams(F, Streams, DT);
    }
    
    // Stage 1.2: Linearization Feasibility Analysis
    if (!Streams.empty() && !Loops.empty()) {
      SmallVector<StreamMergeCandidate, 4> MergeCandidates = 
          analyzeMergeFeasibility(F, Streams, Loops, SE, LI);
      
      if (!MergeCandidates.empty()) {
        LLVM_DEBUG(dbgs() << "\n" << "═══ Merge Candidates Summary ═══\n");
        for (const auto &Candidate : MergeCandidates) {
          LLVM_DEBUG(dbgs() << "  Stream #" << Candidate.StreamID 
                            << ": Loop #" << Candidate.InnerLoopID
                            << " → Loop #" << Candidate.OuterLoopID);
          if (!Candidate.RequiredDimensions.empty()) {
            LLVM_DEBUG(dbgs() << " (requires " << Candidate.RequiredDimensions.size() 
                              << " dimension(s))");
          }
          LLVM_DEBUG(dbgs() << "\n");
        }
      }
    }
    
    // Stage 2: Interprocedural Validation (not yet implemented)
    // Would require call graph traversal and allocation site tracing
    
    // Stage 3: Transformation (not yet implemented)
    // Would require IR modification and function cloning
  }
  
  return ModuleModified;
}
*/

// Methods below are commented out - functionality integrated into function pass
/*
void InterStellarGlobalOptimizer::eliminateRedundantStreams(
    Function &F,
    SmallVectorImpl<DirectStreamDescriptor> &Streams,
    DominatorTree &DT) {
  
  LLVM_DEBUG(dbgs() << "\n[Stage 1.1] Analyzing stream redundancy in function: "
                    << F.getName() << "\n");
  
  // Build signature map: Σ = {LoopID, SCEV_BaseAddress, Stride}
  DenseMap<StreamSignature, SmallVector<unsigned, 4>> SignatureToStreams;
  
  for (const auto &DS : Streams) {
    StreamSignature Sig{DS.LoopID, DS.BaseAddress, DS.Stride};
    SignatureToStreams[Sig].push_back(DS.StreamID);
  }
  
  // For each signature with multiple streams
  for (auto &Entry : SignatureToStreams) {
    SmallVector<unsigned, 4> &StreamIDs = Entry.second;
    
    if (StreamIDs.size() <= 1)
      continue;  // No duplicates
    
    // Find the dominating instruction (first in topological order)
    Instruction *DominatingInst = nullptr;
    unsigned PrimaryStreamID = 0;
    bool PreferLoad = false;
    
    for (unsigned ID : StreamIDs) {
      DirectStreamDescriptor &DS = Streams[ID];
      Instruction *CurrentInst = DS.MemInst;
      
      if (!CurrentInst)
        continue;
      
      if (!DominatingInst) {
        DominatingInst = CurrentInst;
        PrimaryStreamID = ID;
        PreferLoad = isa<LoadInst>(CurrentInst);
      } else if (DT.dominates(CurrentInst, DominatingInst)) {
        // This instruction dominates the current primary
        DominatingInst = CurrentInst;
        PrimaryStreamID = ID;
        PreferLoad = isa<LoadInst>(CurrentInst);
      } else if (DT.dominates(DominatingInst, CurrentInst)) {
        // Current primary dominates this one - no change
        continue;
      } else {
        // No dominance relationship - prefer LoadInst
        if (!PreferLoad && isa<LoadInst>(CurrentInst)) {
          DominatingInst = CurrentInst;
          PrimaryStreamID = ID;
          PreferLoad = true;
        }
      }
    }
    
    // Mark all non-primary streams with matching signature as pruned
    // Note: In practice, we would mark these streams as "pruned" or remove them.
    // For now, we just log them. The CSR generation code should skip duplicates.
    for (unsigned ID : StreamIDs) {
      if (ID != PrimaryStreamID) {
        LLVM_DEBUG(dbgs() << "  Pruned stream #" << ID 
                          << " (duplicate of stream #" << PrimaryStreamID << ")\n");
        // TODO: Add a pruned flag to DirectStreamDescriptor or filter in CSR generation
      }
    }
  }
}

SmallVector<InterStellarGlobalOptimizer::StreamMergeCandidate, 4>
InterStellarGlobalOptimizer::analyzeMergeFeasibility(
    Function &F,
    const SmallVectorImpl<DirectStreamDescriptor> &Streams,
    const SmallVectorImpl<LoopDescriptor> &Loops,
    ScalarEvolution &SE,
    LoopInfo &LI) {
  
  LLVM_DEBUG(dbgs() << "\n[Stage 1.2] Analyzing merge feasibility for nested loops\n");
  
  SmallVector<StreamMergeCandidate, 4> Candidates;
  
  // Build mapping from LoopID to Loop descriptor for quick lookup
  DenseMap<unsigned, const LoopDescriptor *> LoopIDToDescriptor;
  for (const auto &LD : Loops) {
    LoopIDToDescriptor[LD.LoopID] = &LD;
  }
  
  // Analyze each stream to check if it can be linearized with outer loops
  for (const auto &DS : Streams) {
    // Find the loop descriptor for this stream
    auto LoopIt = LoopIDToDescriptor.find(DS.LoopID);
    if (LoopIt == LoopIDToDescriptor.end())
      continue;
    
    const LoopDescriptor *InnerLD = LoopIt->second;
    Loop *InnerLoop = InnerLD->L;
    
    if (!InnerLoop)
      continue;
    
    LLVM_DEBUG(dbgs() << "  Analyzing Stream #" << DS.StreamID 
                      << " in Loop #" << DS.LoopID << "\n");
    
    // Check if this loop has a parent (nested structure)
    Loop *OuterLoop = InnerLoop->getParentLoop();
    if (!OuterLoop) {
      LLVM_DEBUG(dbgs() << "    No parent loop - cannot linearize\n");
      continue;
    }
    
    unsigned OuterLoopID = InnerLD->ParentLoopID;
    auto OuterLDIt = LoopIDToDescriptor.find(OuterLoopID);
    if (OuterLDIt == LoopIDToDescriptor.end())
      continue;
    
    const LoopDescriptor *OuterLD = OuterLDIt->second;
    
    // Calculate inner loop span: TripCount_inner * Stride
    // TripCount is the end value (backedge-taken count)
    const SCEV *InnerTripCount = InnerLD->EndValue;
    if (!InnerTripCount) {
      LLVM_DEBUG(dbgs() << "    Inner loop trip count unknown\n");
      continue;
    }
    
    // Inner span = TripCount * Stride (in bytes)
    const SCEV *InnerStrideSCEV = SE.getConstant(
        APInt(64, DS.Stride, true));
    const SCEV *InnerSpan = SE.getMulExpr(InnerTripCount, InnerStrideSCEV);
    
    LLVM_DEBUG(dbgs() << "    Inner loop span SCEV: " << *InnerSpan << "\n");
    
    // Analyze how the base address evolves in the outer loop
    // For base address patterns, we need to extract the AddRec with respect to outer loop
    // Example: For A[i][j], the base in j-loop is {A + i*row_size, +, elem_size}<j-loop>
    //          The i-component is {A, +, row_size}<i-loop>
    
    const SCEV *BaseStep = nullptr;
    
    // Check if base address is an AddRec with respect to the outer loop
    if (const SCEVAddRecExpr *BaseAR = dyn_cast<SCEVAddRecExpr>(DS.BaseAddress)) {
      Loop *BaseARLoop = const_cast<Loop *>(BaseAR->getLoop());
      
      // Check if the AddRec belongs to outer loop or any ancestor
      bool IsOuterLoopRelated = false;
      Loop *CurrentLoop = OuterLoop;
      while (CurrentLoop) {
        if (CurrentLoop == BaseARLoop) {
          IsOuterLoopRelated = true;
          break;
        }
        CurrentLoop = CurrentLoop->getParentLoop();
      }
      
      if (IsOuterLoopRelated && BaseAR->isAffine()) {
        // Extract the step (stride) of the outer loop AddRec
        BaseStep = BaseAR->getStepRecurrence(SE);
        LLVM_DEBUG(dbgs() << "    Outer loop base step (from AddRec): " 
                          << *BaseStep << "\n");
      }
    }
    
    // Alternative: Check if base contains nested AddRecs
    // For nested loops, the base might be: {start, +, step}<outer> where
    // step itself contains information about inner loop span
    if (!BaseStep) {
      // Try to find AddRec components that relate to outer loop
      // This is a simplified heuristic for now
      LLVM_DEBUG(dbgs() << "    Could not extract outer loop step from base\n");
      continue;
    }
    
    // Check if the base step matches the inner span
    // They should be equal for perfect linearization
    bool IsPotentiallyLinearizable = false;
    
    // Case 1: Both are constant and equal
    if (isa<SCEVConstant>(InnerSpan) && isa<SCEVConstant>(BaseStep)) {
      const SCEVConstant *SpanConst = cast<SCEVConstant>(InnerSpan);
      const SCEVConstant *StepConst = cast<SCEVConstant>(BaseStep);
      
      if (SpanConst->getAPInt() == StepConst->getAPInt()) {
        IsPotentiallyLinearizable = true;
        LLVM_DEBUG(dbgs() << "    ✓ Constant span matches step - linearizable!\n");
      }
    }
    // Case 2: Both contain the same dynamic values (structural match)
    else if (InnerSpan == BaseStep) {
      IsPotentiallyLinearizable = true;
      LLVM_DEBUG(dbgs() << "    ✓ Symbolic span matches step - linearizable!\n");
    }
    // Case 3: Check if BaseStep is a multiple of Stride
    else if (const SCEVMulExpr *StepMul = dyn_cast<SCEVMulExpr>(BaseStep)) {
      // BaseStep might be: InnerTripCount * Stride
      // Check if one operand is Stride and another is TripCount
      for (const SCEV *Op : StepMul->operands()) {
        if (Op == InnerStrideSCEV || Op == InnerTripCount) {
          // Potential match - compute the full product and compare
          const SCEV *ExpectedStep = SE.getMulExpr(InnerTripCount, InnerStrideSCEV);
          if (ExpectedStep == BaseStep) {
            IsPotentiallyLinearizable = true;
            LLVM_DEBUG(dbgs() << "    ✓ Base step matches stride×tripcount - linearizable!\n");
            break;
          }
        }
      }
    }
    
    if (!IsPotentiallyLinearizable) {
      LLVM_DEBUG(dbgs() << "    ✗ Span/step mismatch - not linearizable\n");
      continue;
    }
    
    // Create merge candidate
    StreamMergeCandidate Candidate;
    Candidate.StreamID = DS.StreamID;
    Candidate.InnerLoopID = DS.LoopID;
    Candidate.OuterLoopID = OuterLoopID;
    Candidate.RequiredBound = InnerLD->EndValueDynamic;
    Candidate.ExpectedStride = BaseStep;
    
    // Record required dimension (the inner trip count)
    if (InnerLD->IsEndLinked) {
      Candidate.RequiredDimensions.push_back(InnerLD->EndLinkID);
    }
    
    Candidates.push_back(Candidate);
    
    LLVM_DEBUG(dbgs() << "    → Created merge candidate: Stream #" 
                      << Candidate.StreamID 
                      << " (Inner Loop #" << Candidate.InnerLoopID
                      << " → Outer Loop #" << Candidate.OuterLoopID << ")\n");
    
    // Recursively check if the outer loop can also be merged with its parent
    // This handles 3+ level nesting like A[i][j][k]
    Loop *GrandparentLoop = OuterLoop->getParentLoop();
    if (GrandparentLoop && OuterLD->ParentLoopID != 0) {
      LLVM_DEBUG(dbgs() << "    Checking grandparent loop for further merging...\n");
      
      unsigned GrandparentLoopID = OuterLD->ParentLoopID;
      auto GrandparentLDIt = LoopIDToDescriptor.find(GrandparentLoopID);
      
      if (GrandparentLDIt != LoopIDToDescriptor.end()) {
        // For grandparent merging, we need to check if the outer loop's base evolution
        // matches the combined span of inner loops
        const SCEV *OuterTripCount = OuterLD->EndValue;
        if (OuterTripCount) {
          // Combined span = OuterTripCount * InnerSpan
          const SCEV *CombinedSpan = SE.getMulExpr(OuterTripCount, InnerSpan);
          
          LLVM_DEBUG(dbgs() << "      Combined span: " << *CombinedSpan << "\n");
          
          // This is a simplified check - full implementation would need
          // to recursively analyze the base address evolution at grandparent level
          // For now, we just record that this dimension could also be merged
          if (OuterLD->IsEndLinked) {
            Candidate.RequiredDimensions.push_back(OuterLD->EndLinkID);
            LLVM_DEBUG(dbgs() << "      Marked outer dimension as mergeable\n");
          }
        }
      }
    }
  }
  
  LLVM_DEBUG(dbgs() << "\n  Total merge candidates identified: " 
                    << Candidates.size() << "\n");
  
  return Candidates;
}

InterStellarGlobalOptimizer::AllocationInfo
InterStellarGlobalOptimizer::traceAllocationSite(CallBase *CS, unsigned ArgIndex) {
  
  LLVM_DEBUG(dbgs() << "\n[Stage 2.1] Tracing allocation site for argument "
                    << ArgIndex << "\n");
  
  AllocationInfo Info;
  Info.AllocKind = AllocationInfo::Kind::Opaque;
  
  // TODO: Full implementation requires backward def-use traversal
  // through GEPs, casts, and PHIs to identify allocation sites
  
  (void)CS;  // Suppress unused parameter warning
  return Info;
}

LLVM_ATTRIBUTE_UNUSED
InterStellarGlobalOptimizer::CallSiteClassification
InterStellarGlobalOptimizer::verifyBoundsAtCallSites(
    const StreamMergeCandidate &Candidate,
    ArrayRef<CallBase *> CallSites) {
  
  LLVM_DEBUG(dbgs() << "\n[Stage 2.2] Verifying bounds at call sites\n");
  
  CallSiteClassification Classification;
  
  // TODO: Full implementation requires comparing allocation dimensions
  // with runtime bound arguments to validate linearization safety
  
  // Conservative: classify all as unsafe
  for (CallBase *CS : CallSites) {
    Classification.UnsafeCallSites.push_back(CS);
  }
  
  (void)Candidate;  // Suppress unused parameter warning
  return Classification;
}

LLVM_ATTRIBUTE_UNUSED
InterStellarGlobalOptimizer::SpecializationResult
InterStellarGlobalOptimizer::specializeFunction(
    Function &F,
    const CallSiteClassification &Classification,
    const StreamMergeCandidate &Candidate) {
  
  LLVM_DEBUG(dbgs() << "\n[Stage 3.1] Determining specialization strategy\n");
  
  SpecializationResult Result;
  Result.OriginalFunction = &F;
  Result.OptimizedFunction = nullptr;
  
  bool AllSafe = Classification.UnsafeCallSites.empty();
  bool NoneSafe = Classification.SafeCallSites.empty();
  
  if (AllSafe) {
    Result.SpecializationAction = SpecializationResult::Action::InPlaceOptimization;
    Result.OptimizedFunction = &F;
  } else if (NoneSafe) {
    Result.SpecializationAction = SpecializationResult::Action::NoOptimization;
  } else {
    // Mixed: would require function cloning
    Result.SpecializationAction = SpecializationResult::Action::FunctionCloning;
    // TODO: Implement CloneFunction() and call site patching
  }
  
  (void)Candidate;  // Suppress unused parameter warning
  return Result;
}

LLVM_ATTRIBUTE_UNUSED
void InterStellarGlobalOptimizer::applyLoopLinearization(
    Function &F,
    const StreamMergeCandidate &Candidate,
    SmallVectorImpl<DirectStreamDescriptor> &Streams,
    SmallVectorImpl<LoopDescriptor> &Loops) {
  
  LLVM_DEBUG(dbgs() << "\n[Stage 3.2] Applying loop linearization\n");
  
  // TODO: Full implementation requires IR modification to inject
  // multiplication instruction and create virtual loop descriptors
  
  (void)F;
  (void)Candidate;
  (void)Streams;
  (void)Loops;
}

LLVM_ATTRIBUTE_UNUSED
unsigned InterStellarGlobalOptimizer::collapseMultiDimensionalLoops(
    Function &F,
    const StreamMergeCandidate &InnerCandidate,
    SmallVectorImpl<DirectStreamDescriptor> &Streams,
    SmallVectorImpl<LoopDescriptor> &Loops) {
  
  LLVM_DEBUG(dbgs() << "\n[Stage 3.3] Analyzing multi-dimensional loop collapsing\n");
  
  unsigned DimensionsMerged = 0;
  
  // TODO: Full implementation requires progressive merging across
  // multiple nesting levels with SCEV continuity verification
  
  (void)F;
  (void)InnerCandidate;
  (void)Streams;
  (void)Loops;
  return DimensionsMerged;
}
*/

} // anonymous namespace

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
  
  // ============================================================
  // PASS 1: LOCAL STREAM ANALYSIS
  // ============================================================
  // Identifies raw memory access patterns within each function:
  // - Direct streams (affine patterns like A[i])
  // - Indirect streams (index-based patterns like A[B[i]])
  // - Loop contexts (bounds, nesting, induction variables)
  // - Dynamic values (link variables for runtime values)
  //
  // Output: Raw stream descriptors (may contain duplicates)
  // ============================================================
  
  // Create analyzer and run Pass 1 analysis
  InterStellarStreamAnalyzer Analyzer(F, LI, SE);
  Analyzer.analyze();
  
  // Print Pass 1 results
  LLVM_DEBUG(Analyzer.print(dbgs()));
  
  // ============================================================
  // PASS 2: INTRAPROCEDURAL OPTIMIZATION (Stage 1 only)
  // ============================================================
  // We can run Stage 1 of Pass 2 here (intraprocedural analysis).
  // Stages 2 & 3 require module-level infrastructure.
  //
  // Stage 1.1: Stream redundancy elimination (dominance analysis)
  // Stage 1.2: Linearization feasibility analysis (SCEV-based)
  // ============================================================
  
  SmallVector<DirectStreamDescriptor, 8> Streams = Analyzer.getDirectStreams();
  SmallVector<LoopDescriptor, 4> Loops = Analyzer.getLoopDescriptors();
  
  if (!Streams.empty() && !Loops.empty()) {
    auto &DT = AM.getResult<DominatorTreeAnalysis>(F);
    
    LLVM_DEBUG(dbgs() << "\n"
                      << "╔═══════════════════════════════════════════════════╗\n"
                      << "║  InterStellar Pass 2: Stage 1 (Intraprocedural)   ║\n"
                      << "╚═══════════════════════════════════════════════════╝\n");
    
    // Stage 1.1: Eliminate redundant streams using dominance analysis
    // Group streams by signature (LoopID, BaseAddress, Stride)
    LLVM_DEBUG(dbgs() << "\n[Stage 1.1] Direct Stream Redundancy Analysis\n");
    
    SmallVector<SmallVector<unsigned, 2>, 4> StreamGroups;
    SmallVector<bool, 8> Processed(Streams.size(), false);
    
    for (size_t i = 0; i < Streams.size(); ++i) {
      if (Processed[i])
        continue;
      
      const auto &DS_i = Streams[i];
      SmallVector<unsigned, 2> Group;
      Group.push_back(i);
      Processed[i] = true;
      
      // Find all streams with matching signature
      for (size_t j = i + 1; j < Streams.size(); ++j) {
        if (Processed[j])
          continue;
        
        const auto &DS_j = Streams[j];
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
    
    for (const auto &Group : StreamGroups) {
      LLVM_DEBUG(dbgs() << "  Found " << Group.size() 
                        << " duplicate streams:\n");
      
      // Find dominating instruction
      Instruction *DominatingInst = nullptr;
      unsigned PrimaryIdx = Group[0];
      
      for (unsigned Idx : Group) {
        LLVM_DEBUG(dbgs() << "    Stream #" << Streams[Idx].StreamID);
        // Print source location if available
        if (Streams[Idx].Loc) {
          LLVM_DEBUG(dbgs() << " at ");
          LLVM_DEBUG(Streams[Idx].Loc.print(dbgs()));
        }
        LLVM_DEBUG(dbgs() << "\n");
        
        Instruction *CurrentInst = Streams[Idx].MemInst;
        if (!CurrentInst)
          continue;
        
        if (!DominatingInst || DT.dominates(CurrentInst, DominatingInst)) {
          DominatingInst = CurrentInst;
          PrimaryIdx = Idx;
        }
      }
      
      LLVM_DEBUG(dbgs() << "    → Primary stream: #" << Streams[PrimaryIdx].StreamID);
      if (Streams[PrimaryIdx].Loc) {
        LLVM_DEBUG(dbgs() << " at ");
        LLVM_DEBUG(Streams[PrimaryIdx].Loc.print(dbgs()));
      }
      LLVM_DEBUG(dbgs() << "\n");
      
      // Mark all non-primary streams for removal
      for (unsigned Idx : Group) {
        if (Idx != PrimaryIdx) {
          StreamsToRemove.insert(&Streams[Idx]);
        }
      }
    }
    
    // Filter out redundant streams - keep only primary streams
    SmallVector<DirectStreamDescriptor, 8> FilteredStreams;
    for (const auto &DS : Streams) {
      if (!StreamsToRemove.count(&DS)) {
        FilteredStreams.push_back(DS);
      }
    }
    
    // Replace Streams with the filtered list for subsequent stages
    Streams = std::move(FilteredStreams);
    
    // Stage 1.1: Also analyze indirect stream redundancy
    // Indirect streams should be deduplicated based on base address, element size,
    // and index source (either a specific stream ID or computed/random)
    SmallVector<IndirectStreamDescriptor, 4> IndirectStreams = Analyzer.getIndirectStreams();
    
    if (!IndirectStreams.empty()) {
      LLVM_DEBUG(dbgs() << "\n[Stage 1.1] Indirect Stream Redundancy Analysis\n");
      
      SmallVector<SmallVector<unsigned, 2>, 4> IndirectStreamGroups;
      SmallVector<bool, 8> IndirectProcessed(IndirectStreams.size(), false);
      
      // Track which indirect streams should be removed (redundant streams)
      SmallPtrSet<const IndirectStreamDescriptor *, 8> IndirectStreamsToRemove;
      
      for (size_t i = 0; i < IndirectStreams.size(); ++i) {
        if (IndirectProcessed[i])
          continue;
        
        const auto &IDS_i = IndirectStreams[i];
        SmallVector<unsigned, 2> Group;
        Group.push_back(i);
        IndirectProcessed[i] = true;
        
        // Find all indirect streams with matching signature
        // Signature: {LoopID, BaseAddress, ElementSize, IsIndexComputed, BaseStreamID}
        for (size_t j = i + 1; j < IndirectStreams.size(); ++j) {
          if (IndirectProcessed[j])
            continue;
          
          const auto &IDS_j = IndirectStreams[j];
          
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
          LLVM_DEBUG(dbgs() << "    Indirect Stream #" << IndirectStreams[Idx].StreamID);
          // Print source location if available
          if (IndirectStreams[Idx].Loc) {
            LLVM_DEBUG(dbgs() << " at ");
            LLVM_DEBUG(IndirectStreams[Idx].Loc.print(dbgs()));
          }
          LLVM_DEBUG(dbgs() << "\n");
          
          Instruction *CurrentInst = IndirectStreams[Idx].MemInst;
          if (!CurrentInst)
            continue;
          
          if (!DominatingInst) {
            DominatingInst = CurrentInst;
            PrimaryIdx = Idx;
            PreferLoad = isa<LoadInst>(CurrentInst);
          } else if (DT.dominates(CurrentInst, DominatingInst)) {
            // This instruction dominates the current primary
            DominatingInst = CurrentInst;
            PrimaryIdx = Idx;
            PreferLoad = isa<LoadInst>(CurrentInst);
          } else if (DT.dominates(DominatingInst, CurrentInst)) {
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
                          << IndirectStreams[PrimaryIdx].StreamID);
        if (IndirectStreams[PrimaryIdx].Loc) {
          LLVM_DEBUG(dbgs() << " at ");
          LLVM_DEBUG(IndirectStreams[PrimaryIdx].Loc.print(dbgs()));
        }
        LLVM_DEBUG(dbgs() << "\n");
        
        // Mark all non-primary indirect streams for removal
        for (unsigned Idx : Group) {
          if (Idx != PrimaryIdx) {
            IndirectStreamsToRemove.insert(&IndirectStreams[Idx]);
          }
        }
      }
      
      // Filter out redundant indirect streams - keep only primary streams
      SmallVector<IndirectStreamDescriptor, 4> FilteredIndirectStreams;
      for (const auto &IDS : IndirectStreams) {
        if (!IndirectStreamsToRemove.count(&IDS)) {
          FilteredIndirectStreams.push_back(IDS);
        }
      }
      
      // Replace IndirectStreams with the filtered list for subsequent stages
      IndirectStreams = std::move(FilteredIndirectStreams);
    }
    
    // Helper function to extract AddRecExpr for a specific loop from complex SCEV
    // Recursively searches through SCEV tree (AddExpr, MulExpr, CastExpr, etc.)
    std::function<const SCEVAddRecExpr *(const SCEV *, const Loop *)> FindAddRecForLoop = 
        [&](const SCEV *S, const Loop *TargetLoop) -> const SCEVAddRecExpr * {
      if (!S || !TargetLoop)
        return nullptr;
      
      // Direct match: top-level is AddRecExpr for target loop
      if (const SCEVAddRecExpr *AR = dyn_cast<SCEVAddRecExpr>(S)) {
        if (AR->getLoop() == TargetLoop)
          return AR;
        // For nested AddRecs, search the start value (base)
        // Example: {{%base,+,400}<%Loop0>,+,40}<%Loop1>
        // When searching for Loop0, we need to look inside the outer AddRec's start value
        if (auto *Found = FindAddRecForLoop(AR->getStart(), TargetLoop))
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
          if (auto *Found = FindAddRecForLoop(Op, TargetLoop))
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
          if (auto *Found = FindAddRecForLoop(Op, TargetLoop))
            return Found;
        }
      }
      
      // Search through type casts (sext, zext, trunc)
      if (const SCEVCastExpr *Cast = dyn_cast<SCEVCastExpr>(S)) {
        return FindAddRecForLoop(Cast->getOperand(), TargetLoop);
      }
      
      return nullptr;
    };
    
    // Stage 1.2: Analyze merge feasibility for nested loops
    LLVM_DEBUG(dbgs() << "\n[Stage 1.2] Linearization Feasibility Analysis\n");
    
    // Build mapping from LoopID to Loop descriptor
    DenseMap<unsigned, const LoopDescriptor *> LoopIDToDescriptor;
    for (const auto &LD : Loops) {
      LoopIDToDescriptor[LD.LoopID] = &LD;
    }
    
    // Analyze each stream for potential linearization
    // For deep nested loops (3+), we need to recursively check all parent loops
    // to identify all possible merge opportunities at each nesting level
    SmallVector<StreamMergeCandidate, 4> MergeCandidates;
    
    for (const auto &DS : Streams) {
      auto LoopIt = LoopIDToDescriptor.find(DS.LoopID);
      if (LoopIt == LoopIDToDescriptor.end())
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
        const SCEV *DynamicSCEV = SE.getSCEV(ChildLD->EndValueDynamic);
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
        const SCEV *InnerStrideSCEV = SE.getConstant(TripCountType, DS.Stride);
        
        if (!CumulativeSpan) {
          // First level: Span = TripCount * Stride
          CumulativeSpan = SE.getMulExpr(InnerTripCount, InnerStrideSCEV);
        } else {
          // Deeper level: Span = PreviousSpan * CurrentTripCount
          // Need to ensure types match
          if (CumulativeSpan->getType() != TripCountType) {
            CumulativeSpan = SE.getSignExtendExpr(CumulativeSpan, TripCountType);
          }
          CumulativeSpan = SE.getMulExpr(CumulativeSpan, InnerTripCount);
        }
        
        LLVM_DEBUG(dbgs() << "    Cumulative span at this level: " << *CumulativeSpan << "\n");
        
        // Extract parent loop step from base address using helper function
        LLVM_DEBUG(dbgs() << "    Analyzing SCEV structure...\n");
        
        const SCEV *BaseStep = nullptr;
        const SCEVAddRecExpr *ParentAddRec = FindAddRecForLoop(DS.BaseAddress, ParentLoop);
        
        if (ParentAddRec && ParentAddRec->isAffine()) {
          // Found an AddRec for the parent loop - extract its step
          const SCEV *RawStep = ParentAddRec->getStepRecurrence(SE);
          
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
            const SCEV *ElementSizeSCEV = SE.getConstant(StepType, DS.Stride);
            BaseStep = SE.getMulExpr(RawStep, ElementSizeSCEV);
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
              const SCEV *ExpectedStep = SE.getMulExpr(InnerTripCount, InnerStrideSCEV);
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
          Candidate.RequiredBound = ChildLD->EndValueDynamic;  // Runtime bound (Value*)
          Candidate.ExpectedStride = BaseStep;
          Candidate.RequiredDimensions = std::move(RequiredDimensions);
          
          MergeCandidates.push_back(Candidate);
          
          LLVM_DEBUG(dbgs() << "    → Merge candidate created (level " 
                            << MergeCandidates.size() << ")\n");
          
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
        auto ParentLDIt = LoopIDToDescriptor.find(ParentLoopID);
        if (ParentLDIt != LoopIDToDescriptor.end()) {
          ChildLD = ParentLDIt->second;
          InnerTripCount = ChildLD->EndValue;
          
          // Apply the same EndValueDynamic normalization as we do initially
          // This ensures we use clean symbolic expressions without backedge adjustments
          if (ChildLD->EndValueDynamic && ChildLD->IsEndLinked) {
            const SCEV *DynamicSCEV = SE.getSCEV(ChildLD->EndValueDynamic);
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
    
    if (!MergeCandidates.empty()) {
      LLVM_DEBUG(dbgs() << "\n═══ Merge Candidates Summary ═══\n");
      LLVM_DEBUG(dbgs() << "Total candidates: " << MergeCandidates.size() << "\n");
      for (const auto &Candidate : MergeCandidates) {
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
      // STAGE 2: MERGE PATTERN CLASSIFICATION
      // ============================================================
      // For each merge candidate, determine which pattern it matches:
      // - Pattern A: Fixed-Size Array Types (type-based verification)
      // - Pattern B: Linearized Index Arithmetic (arithmetic-based verification)
      // - Pattern C: Unsafe (cannot verify contiguity)
      //
      // This stage prepares for actual loop linearization transformation
      // by classifying the access patterns and determining safety.
      // ============================================================
      
      LLVM_DEBUG(dbgs() << "\n[Stage 2] Merge Pattern Classification\n");
      
      // For each merge candidate, analyze the memory access pattern
      for (const auto &Candidate : MergeCandidates) {
        // Find the stream descriptor
        const DirectStreamDescriptor *CandidateStream = nullptr;
        for (const auto &DS : Streams) {
          if (DS.StreamID == Candidate.StreamID) {
            CandidateStream = &DS;
            break;
          }
        }
        
        if (!CandidateStream || !CandidateStream->MemInst) {
          LLVM_DEBUG(dbgs() << "  Stream #" << Candidate.StreamID 
                            << ": No memory instruction found\n");
          continue;
        }
        
        LLVM_DEBUG(dbgs() << "\n  Stream #" << Candidate.StreamID 
                          << " (Loop #" << Candidate.InnerLoopID 
                          << " → Loop #" << Candidate.OuterLoopID << ")");
        if (CandidateStream->Loc) {
          LLVM_DEBUG(dbgs() << " at ");
          LLVM_DEBUG(CandidateStream->Loc.print(dbgs()));
        }
        LLVM_DEBUG(dbgs() << "\n");
        
        // Get the pointer operand from the memory instruction
        Value *Ptr = nullptr;
        if (LoadInst *LI = dyn_cast<LoadInst>(CandidateStream->MemInst)) {
          Ptr = LI->getPointerOperand();
        } else if (StoreInst *SI = dyn_cast<StoreInst>(CandidateStream->MemInst)) {
          Ptr = SI->getPointerOperand();
        }
        
        if (!Ptr) {
          LLVM_DEBUG(dbgs() << "    Pattern: UNKNOWN (no pointer operand)\n");
          continue;
        }
        
        // Trace back to the GEP instruction
        GetElementPtrInst *GEP = dyn_cast<GetElementPtrInst>(Ptr);
        if (!GEP) {
          LLVM_DEBUG(dbgs() << "    Pattern: UNKNOWN (not a GEP)\n");
          continue;
        }
        
        LLVM_DEBUG(dbgs() << "    GEP: " << *GEP << "\n");
        
        // Get the base pointer and check its type
        Value *BasePtr = GEP->getPointerOperand();
        Type *BasePtrType = BasePtr->getType();
        
        LLVM_DEBUG(dbgs() << "    Base pointer: " << *BasePtr << "\n");
        LLVM_DEBUG(dbgs() << "    Base type: " << *BasePtrType << "\n");
        
        // ========================================
        // PATTERN A: Fixed-Size Array Types
        // ========================================
        // Check if the base pointer has a fixed-size array type
        // Example: D3B[][10][10] or int A[10][20]
        
        // For modern LLVM, use GEP's source element type instead
        Type *SourceElementType = GEP->getSourceElementType();
        
        LLVM_DEBUG(dbgs() << "    Source element type: " << *SourceElementType << "\n");
        
        // Check if it's an array type with fixed dimensions
        if (ArrayType *ArrTy = dyn_cast<ArrayType>(SourceElementType)) {
          LLVM_DEBUG(dbgs() << "    ✓ Pattern A: Fixed-Size Array Type\n");
          
          // Extract dimensions from the array type
          SmallVector<uint64_t, 4> ArrayDimensions;
          Type *CurrentType = ArrTy;
          
          while (ArrayType *SubArrTy = dyn_cast<ArrayType>(CurrentType)) {
            uint64_t NumElements = SubArrTy->getNumElements();
            ArrayDimensions.push_back(NumElements);
            CurrentType = SubArrTy->getElementType();
            
            LLVM_DEBUG(dbgs() << "      Dimension: " << NumElements << "\n");
          }
          
          LLVM_DEBUG(dbgs() << "    Total dimensions found: " << ArrayDimensions.size() << "\n");
          
          // Get the inner loop descriptor to check loop bounds
          auto InnerLDIt = LoopIDToDescriptor.find(Candidate.InnerLoopID);
          if (InnerLDIt != LoopIDToDescriptor.end()) {
            const LoopDescriptor *InnerLD = InnerLDIt->second;
            
            // Check if loop bound matches array dimension
            // For Pattern A, we verify that the loop bound equals the physical dimension
            if (InnerLD->EndValue) {
              LLVM_DEBUG(dbgs() << "    Inner loop bound: " << *InnerLD->EndValue << "\n");
              
              // Check if it's a constant that matches a dimension
              if (const SCEVConstant *BoundConst = dyn_cast<SCEVConstant>(InnerLD->EndValue)) {
                uint64_t BoundValue = BoundConst->getAPInt().getZExtValue();
                
                // Check if this bound matches any of the array dimensions
                bool MatchesArrayDimension = false;
                for (size_t i = 0; i < ArrayDimensions.size(); ++i) {
                  if (BoundValue == ArrayDimensions[i]) {
                    LLVM_DEBUG(dbgs() << "    ✓ Loop bound (" << BoundValue 
                                      << ") matches array dimension[" << i << "]\n");
                    MatchesArrayDimension = true;
                    break;
                  }
                }
                
                if (MatchesArrayDimension) {
                  LLVM_DEBUG(dbgs() << "    ✓ SAFE TO MERGE (Pattern A): "
                                    << "Type-based verification successful\n");
                } else {
                  LLVM_DEBUG(dbgs() << "    ✗ UNSAFE: Loop bound does not match array dimensions\n");
                }
              } else {
                LLVM_DEBUG(dbgs() << "    ⚠ Loop bound is symbolic - requires runtime verification\n");
              }
            }
          }
          
          continue;  // Pattern A identified, move to next candidate
        }
        
        // Pattern B: Check if outer loop coefficient matches inner loop bound
        const SCEV *FullAddressSCEV = CandidateStream->BaseAddress;
        
        // Get loop descriptors for inner and outer loops
        auto InnerLDIt = LoopIDToDescriptor.find(Candidate.InnerLoopID);
        auto OuterLDIt = LoopIDToDescriptor.find(Candidate.OuterLoopID);
        
        if (InnerLDIt == LoopIDToDescriptor.end() || OuterLDIt == LoopIDToDescriptor.end()) {
          LLVM_DEBUG(dbgs() << "    Cannot find loop descriptors\n");
          continue;
        }
        
        const LoopDescriptor *InnerLD = InnerLDIt->second;
        const LoopDescriptor *OuterLD = OuterLDIt->second;
        
        // Normalize the inner loop bound using EndValueDynamic for cleaner comparisons
        const SCEV *InnerLoopBound = InnerLD->EndValue;
        if (InnerLD->EndValueDynamic && InnerLD->IsEndLinked) {
          const SCEV *DynamicSCEV = SE.getSCEV(InnerLD->EndValueDynamic);
          if (DynamicSCEV) {
            InnerLoopBound = DynamicSCEV;
          }
        }
        
        // CRITICAL: For multi-dimensional arrays, we need to find the coefficient
        // of the OUTER loop variable in the full address expression.
        //
        // The address SCEV from the inner loop's perspective contains the outer
        // loop variable as an AddRec. We extract its step coefficient and compare
        // with the inner loop's bound.
        
        const SCEVAddRecExpr *OuterAddRecInAddress = FindAddRecForLoop(FullAddressSCEV, OuterLD->L);
        
        if (OuterAddRecInAddress && OuterAddRecInAddress->isAffine()) {
          const SCEV *OuterCoefficient = OuterAddRecInAddress->getStepRecurrence(SE);
          
          const SCEV *NormalizedCoefficient = OuterCoefficient;
          
          // Normalize byte stride to element count if needed
          const DataLayout &DL = GEP->getModule()->getDataLayout();
          uint64_t ElementSize = DL.getTypeStoreSize(SourceElementType);
          
          if (ElementSize > 1) {
            if (const SCEVConstant *CoeffConst = dyn_cast<SCEVConstant>(OuterCoefficient)) {
              uint64_t CoeffValue = CoeffConst->getAPInt().getZExtValue();
              if (CoeffValue % ElementSize == 0) {
                uint64_t ElementCount = CoeffValue / ElementSize;
                Type *BoundType = InnerLoopBound->getType();
                NormalizedCoefficient = SE.getConstant(BoundType, ElementCount);
              }
            }
            else if (const SCEVMulExpr *MulExpr = dyn_cast<SCEVMulExpr>(OuterCoefficient)) {
              const SCEV *RemainingPart = nullptr;
              for (const SCEV *Op : MulExpr->operands()) {
                if (const SCEVConstant *OpConst = dyn_cast<SCEVConstant>(Op)) {
                  if (OpConst->getAPInt().getZExtValue() == ElementSize) {
                    SmallVector<const SCEV *, 4> OtherOps;
                    for (const SCEV *Other : MulExpr->operands()) {
                      if (Other != Op) OtherOps.push_back(Other);
                    }
                    if (OtherOps.size() == 1) {
                      RemainingPart = OtherOps[0];
                    } else if (OtherOps.size() > 1) {
                      RemainingPart = SE.getMulExpr(OtherOps);
                    }
                    break;
                  }
                }
              }
              if (RemainingPart) {
                NormalizedCoefficient = RemainingPart;
              }
            }
          }
          
          // Compare outer coefficient with inner bound
          
          bool IsMatch = false;
          
          if (NormalizedCoefficient == InnerLoopBound) {
            IsMatch = true;
          }
          else if (const SCEVConstant *CoeffConst = dyn_cast<SCEVConstant>(NormalizedCoefficient)) {
            if (const SCEVConstant *BoundConst = dyn_cast<SCEVConstant>(InnerLoopBound)) {
              if (CoeffConst->getAPInt() == BoundConst->getAPInt()) {
                IsMatch = true;
              }
            }
          }
          else if (InnerLD->EndValueDynamic) {
            if (const SCEVUnknown *CoeffUnknown = dyn_cast<SCEVUnknown>(NormalizedCoefficient)) {
              if (CoeffUnknown->getValue() == InnerLD->EndValueDynamic) {
                IsMatch = true;
              }
            }
          }
          
          if (IsMatch) {
            LLVM_DEBUG(dbgs() << "    ✓ SAFE\n");
          } else {
            LLVM_DEBUG(dbgs() << "    ✗ UNSAFE\n");
          }
        } else {
          // Fallback: Old 2D detection logic (may not be needed with full address SCEV)
          LLVM_DEBUG(dbgs() << "    No outer loop AddRec found in address\n");
          
          // Unwrap casts
          const SCEV *UnwrappedSCEV = FullAddressSCEV;
          while (const SCEVCastExpr *Cast = dyn_cast<SCEVCastExpr>(UnwrappedSCEV)) {
            UnwrappedSCEV = Cast->getOperand();
          }
          
          // Check if it's an AddExpr (base + offset pattern)
          if (const SCEVAddExpr *AddExpr = dyn_cast<SCEVAddExpr>(UnwrappedSCEV)) {
            LLVM_DEBUG(dbgs() << "    Address is an AddExpr (checking for nested structure)\n");
            
            // Look for a MulExpr or loop-invariant operand that represents the multiplier
            const SCEV *MultiplierSCEV = nullptr;
            
            for (const SCEV *Op : AddExpr->operands()) {
              // Unwrap casts on operands
              const SCEV *UnwrappedOp = Op;
              while (const SCEVCastExpr *Cast = dyn_cast<SCEVCastExpr>(UnwrappedOp)) {
                UnwrappedOp = Cast->getOperand();
              }
              
              // Skip the inner loop AddRec (that's the j variable)
              if (const SCEVAddRecExpr *AR = dyn_cast<SCEVAddRecExpr>(UnwrappedOp)) {
                if (AR->getLoop() == InnerLD->L) {
                  LLVM_DEBUG(dbgs() << "      Found inner loop variable: " << *AR << "\n");
                  continue;
                }
              }
              
              // Check if this is a MulExpr containing the multiplier
              if (const SCEVMulExpr *Mul = dyn_cast<SCEVMulExpr>(UnwrappedOp)) {
                // Look for non-constant, non-AddRec operands (the multiplier)
                for (const SCEV *MulOp : Mul->operands()) {
                  if (!isa<SCEVConstant>(MulOp) && !isa<SCEVAddRecExpr>(MulOp)) {
                    MultiplierSCEV = MulOp;
                    LLVM_DEBUG(dbgs() << "      Found multiplier in MulExpr: " << *MulOp << "\n");
                    break;
                  }
                }
              }
              // Check if this operand itself is the multiplier (loop-invariant)
              else if (SE.isLoopInvariant(Op, InnerLD->L) && !isa<SCEVConstant>(Op)) {
                MultiplierSCEV = Op;
                LLVM_DEBUG(dbgs() << "      Found loop-invariant multiplier: " << *Op << "\n");
              }
            }
            
            // Compare multiplier with inner loop bound
            if (MultiplierSCEV && InnerLD->EndValue) {
              LLVM_DEBUG(dbgs() << "    Comparing 2D multiplier with inner loop bound:\n");
              LLVM_DEBUG(dbgs() << "      Multiplier: " << *MultiplierSCEV << "\n");
              LLVM_DEBUG(dbgs() << "      Loop bound: " << *InnerLD->EndValue << "\n");
              
              // Check for exact SCEV match
              if (MultiplierSCEV == InnerLD->EndValue) {
                LLVM_DEBUG(dbgs() << "    ✓ Pattern B (2D): Multiplier matches loop bound (SCEV match)\n");
                LLVM_DEBUG(dbgs() << "    ✓ SAFE TO MERGE (Pattern B): "
                                  << "2D array linearization verified\n");
              }
              // Check constant value match
              else if (const SCEVConstant *MultConst = dyn_cast<SCEVConstant>(MultiplierSCEV)) {
                if (const SCEVConstant *BoundConst = dyn_cast<SCEVConstant>(InnerLD->EndValue)) {
                  if (MultConst->getAPInt() == BoundConst->getAPInt()) {
                    LLVM_DEBUG(dbgs() << "    ✓ Pattern B (2D): Multiplier matches loop bound (constant: " 
                                      << MultConst->getAPInt() << ")\n");
                    LLVM_DEBUG(dbgs() << "    ✓ SAFE TO MERGE (Pattern B): "
                                      << "2D array linearization verified\n");
                  } else {
                    LLVM_DEBUG(dbgs() << "    ✗ UNSAFE: Multiplier (" << MultConst->getAPInt() 
                                      << ") != Loop bound (" << BoundConst->getAPInt() << ")\n");
                  }
                }
              }
              // Check IR Value match (for symbolic bounds)
              else if (InnerLD->EndValueDynamic) {
                if (const SCEVUnknown *MultUnknown = dyn_cast<SCEVUnknown>(MultiplierSCEV)) {
                  if (MultUnknown->getValue() == InnerLD->EndValueDynamic) {
                    LLVM_DEBUG(dbgs() << "    ✓ Pattern B (2D): Multiplier matches loop bound (IR Value match)\n");
                    LLVM_DEBUG(dbgs() << "    ✓ SAFE TO MERGE (Pattern B): "
                                      << "2D array linearization verified\n");
                  }
                }
              }
            } else {
              LLVM_DEBUG(dbgs() << "    ⚠ Could not extract multiplier from 2D index formula\n");
            }
          } else {
            LLVM_DEBUG(dbgs() << "    ⚠ Index is not an AddExpr - may be simple sequential pattern\n");
          }
        }
      }
    }
  }
  
  // This is an analysis pass, it doesn't modify the IR
  return PreservedAnalyses::all();
}

void InterStellarAnalysisPass::printResults(raw_ostream &OS) const {
  OS << "InterStellar Analysis Pass\n";
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
