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
#include "llvm/InitializePasses.h"
#include "llvm/Support/Debug.h"
#include "llvm/Support/raw_ostream.h"

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
    if (AR->getLoop() == L) {
      // Direct AddRec case: belongs to current loop (simple pattern like A[i])
      if (!AR->isAffine()) {
        return false;
      }
      
      const SCEV *Base = AR->getStart();
      const SCEV *Step = AR->getStepRecurrence(SE);
      const SCEVConstant *StepConst = dyn_cast<SCEVConstant>(Step);
      
      if (!StepConst) {
        return false;
      }
      
      int64_t Stride = StepConst->getAPInt().getSExtValue();
      
      // Use helper method to create stream with accumulated offset
      createDirectStream(Base, Stride, L, MemInst, AccumulatedOffset);
      return true;
    } else if (AR->getLoop()->contains(L)) {
      // AddRec belongs to outer loop - this is loop-invariant base for current loop
      // Nested loop case: A[i*M + j] where i*M is outer loop induction (base for inner)
      // Fall through to GEP analysis to extract inner loop stride from index
      LLVM_DEBUG(dbgs() << "  AddRec belongs to outer loop, treating as invariant base\n");
      // Note: We don't return false here, but we also can't analyze further without a GEP
      // This case typically won't happen because optimized IR will have GEP instructions
      return false;
    } else {
      // AddRec belongs to unrelated loop
      return false;
    }
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
  
  // Trace through loads to find the actual induction variable
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
  
  // Check if it belongs to this loop
  if (AR->getLoop() != L) {
    LLVM_DEBUG(dbgs() << "  AddRec not for this loop\n");
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
  
  // Use helper method to create stream, passing the outer loop base value if available
  createDirectStream(BaseSCEV, MemoryStride, L, MemInst, AccumulatedOffset, OuterLoopBaseValue);
  
  LLVM_DEBUG({
    dbgs() << "    Element Size: " << ElementSize << " bytes\n";
    dbgs() << "    Index Step: " << IndexStepVal << "\n";
    if (ConstantOffset) {
      dbgs() << "    Constant Index Offset Applied: " << *ConstantOffset << "\n";
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
  // 1. Extract GEP index operand
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
  
  // Step 2: Extract the index operand(s)
  // For simple arrays: GEP has one index
  // For multi-dimensional: GEP might have multiple indices
  // We focus on the last index which represents the actual array subscript
  if (GEP->getNumIndices() == 0) {
    LLVM_DEBUG(dbgs() << "    GEP has no indices\n");
    return false;
  }
  
  Value *Index = nullptr;
  for (auto IdxIt = GEP->idx_begin(); IdxIt != GEP->idx_end(); ++IdxIt) {
    Index = IdxIt->get(); // Get the last index
  }
  
  if (!Index) {
    return false;
  }
  
  LLVM_DEBUG(dbgs() << "    GEP Index: " << *Index << "\n");
  
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
    
    // If it's an AddRec for this loop, it would have been detected as direct stream
    // So if we're here and it's not affine, it's a computed/irregular access
    if (const SCEVAddRecExpr *AR = dyn_cast<SCEVAddRecExpr>(IndexSCEV)) {
      if (AR->getLoop() == L && AR->isAffine()) {
        // This should have been caught as direct stream, skip
        LLVM_DEBUG(dbgs() << "    Index is affine AddRec, should be direct stream\n");
        return false;
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
  Value *BasePtr = GEP->getPointerOperand();
  const SCEV *BaseSCEV = SE.getSCEV(BasePtr);
  
  // Calculate element size from GEP
  Type *ElementType = GEP->getSourceElementType();
  if (ArrayType *ArrTy = dyn_cast<ArrayType>(ElementType)) {
    ElementType = ArrTy->getElementType();
  }
  int64_t ElemSize = getTypeSizeInBytes(ElementType);
  
  IndirectStreamDescriptor IDS;
  IDS.StreamID = NextStreamID++;
  IDS.LoopID = getOrCreateLoopID(L);
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
  
  LLVM_DEBUG(dbgs() << "Running InterStellar analysis on function: "
                    << F.getName() << "\n");
  
  // Create analyzer and run analysis
  InterStellarStreamAnalyzer Analyzer(F, LI, SE);
  Analyzer.analyze();
  
  // Print results only in LLVM debugger
  LLVM_DEBUG(Analyzer.print(dbgs()));
  
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
