//===- InterStellarAnalysis.cpp - Loop Stream Analysis for InterStellar --===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
///
/// \file
/// This file implements the InterStellar stream analysis pass that identifies
/// memory access patterns in loops for hardware-accelerated prefetching.
///
/// The pass performs the following analyses:
/// 1. Identifies direct streams: affine memory accesses with constant stride
///    (e.g., A[i] where i increments by 1)
/// 2. Detects dynamic base addresses that require link variable descriptors
/// 3. Analyzes loop bounds and nesting structure
/// 4. Future: Indirect streams and chained memory accesses
///
/// Implementation Strategy:
/// - Use LoopInfo to iterate through loops (innermost first for precision)
/// - Use ScalarEvolution to analyze memory access patterns via SCEV
/// - Identify SCEVAddRecExpr for affine recurrences (base + i * stride)
/// - Distinguish between static (compile-time) and dynamic (runtime) values
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

/// InterStellar Stream Analyzer Implementation
/// This class contains the actual analysis logic and maintains state
/// for stream and loop descriptors across the function analysis.
class InterStellarStreamAnalyzer {
public:
  InterStellarStreamAnalyzer(Function &F, LoopInfo &LI, ScalarEvolution &SE,
                             DominatorTree &DT)
      : F(F), LI(LI), SE(SE), DT(DT), NextStreamID(0), NextLoopID(0),
        NextLinkID(0) {}
  
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
  DominatorTree &DT;
  
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
  Value *traceIndexThroughLoads(Value *Index, Loop *L);
  unsigned getOrCreateLoopID(Loop *L);
  unsigned getOrCreateLinkID(Value *V, unsigned SizeInBytes);
  bool isValueDynamic(const SCEV *S);
  Value *extractDynamicValue(const SCEV *S);
  void extractAllDynamicValues(const SCEV *S, SmallVectorImpl<Value *> &Values);
  int64_t getTypeSizeInBytes(Type *Ty);
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
  
  // Create loop descriptor
  unsigned LoopID = getOrCreateLoopID(L);
  
  // Strategy: Try multiple approaches to extract loop bounds
  // 1. Use getBounds() if available (works for well-formed loops)
  // 2. Fall back to getInductionVariable() + manual SCEV analysis
  
  LoopDescriptor LD;  // All fields auto-initialized to defaults
  LD.LoopID = LoopID;
  LD.L = L;
  
  // Get parent loop ID if it exists
  Loop *ParentLoop = L->getParentLoop();
  if (ParentLoop) {
    LD.ParentLoopID = getOrCreateLoopID(ParentLoop);
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
            
            BasicBlock *Latch = L->getLoopLatch();
            if (Latch) {
              BranchInst *BI = dyn_cast<BranchInst>(Latch->getTerminator());
              if (BI && BI->isConditional()) {
                if (ICmpInst *Cmp = dyn_cast<ICmpInst>(BI->getCondition())) {
                  // Check which operand is the induction variable
                  Value *Op0 = Cmp->getOperand(0);
                  Value *Op1 = Cmp->getOperand(1);
                  
                  const SCEV *Op0SCEV = SE.getSCEV(Op0);
                  const SCEV *Op1SCEV = SE.getSCEV(Op1);
                  
                  // Find the non-IV operand - that's likely the bound
                  if (Op0SCEV == IndVarSCEV) {
                    LD.EndValue = Op1SCEV;
                  } else if (Op1SCEV == IndVarSCEV) {
                    LD.EndValue = Op0SCEV;
                  }
                }
              }
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
      LD.StartValueDynamic = extractDynamicValue(LD.StartValue);
      if (LD.StartValueDynamic) {
        LD.StartLinkID = getOrCreateLinkID(LD.StartValueDynamic, 
                                            getTypeSizeInBytes(LD.StartValueDynamic->getType()));
      }
    }
    
    // Check if end value is dynamic
    if (isValueDynamic(LD.EndValue)) {
      LD.IsEndLinked = true;
      
      // Extract ALL dynamic values from the end expression
      SmallVector<Value *, 4> DynamicValues;
      extractAllDynamicValues(LD.EndValue, DynamicValues);
      
      // Create link variables for all dynamic values
      for (Value *V : DynamicValues) {
        getOrCreateLinkID(V, getTypeSizeInBytes(V->getType()));
      }
      
      // Choose the primary bound for the Loop Descriptor
      // Strategy: Prefer the value that's NOT the start value
      Value *PrimaryBound = nullptr;
      for (Value *V : DynamicValues) {
        if (V != LD.StartValueDynamic) {
          PrimaryBound = V;
          break;
        }
      }
      
      // If all values are the same as start (edge case), use the first one
      if (!PrimaryBound && !DynamicValues.empty()) {
        PrimaryBound = DynamicValues[0];
      }
      
      if (PrimaryBound) {
        LD.EndValueDynamic = PrimaryBound;
        LD.EndLinkID = getOrCreateLinkID(PrimaryBound, 
                                          getTypeSizeInBytes(PrimaryBound->getType()));
      }
    }
    
    LoopDescriptors.push_back(LD);
  } else {
    LLVM_DEBUG(dbgs() << "  Could not extract loop bounds\n");
  }
  
  // Analyze memory accesses in the loop
  for (BasicBlock *BB : L->blocks()) {
    for (Instruction &I : *BB) {
      if (isa<LoadInst>(&I) || isa<StoreInst>(&I)) {
        analyzeMemoryAccess(&I, L);
      }
    }
  }
}

void InterStellarStreamAnalyzer::analyzeMemoryAccess(Instruction *I, Loop *L) {
  Value *Ptr = nullptr;
  
  if (LoadInst *LI = dyn_cast<LoadInst>(I)) {
    Ptr = LI->getPointerOperand();
  } else if (StoreInst *SI = dyn_cast<StoreInst>(I)) {
    Ptr = SI->getPointerOperand();
  }
  
  if (!Ptr)
    return;
  
  // Try to analyze as a direct stream
  tryAnalyzeDirectStream(Ptr, I, L);
}

bool InterStellarStreamAnalyzer::tryAnalyzeDirectStream(Value *Ptr,
                                                         Instruction *MemInst,
                                                         Loop *L) {
  // Strategy: Handle both optimized and unoptimized IR
  // 1. Check if Ptr is a GEP instruction - this is the array indexing
  // 2. If so, analyze the index operand
  // 3. Trace the index through loads to find the actual induction variable
  // 4. Get SCEV of the induction variable to check for AddRec pattern
  
  GetElementPtrInst *GEP = dyn_cast<GetElementPtrInst>(Ptr);
  if (!GEP) {
    // Ptr might be the result of a GEP that's already computed
    // Try to get SCEV directly (optimized code path)
    const SCEV *PtrSCEV = SE.getSCEV(Ptr);
    const SCEVAddRecExpr *AR = dyn_cast<SCEVAddRecExpr>(PtrSCEV);
    
    if (!AR) {
      LLVM_DEBUG(dbgs() << "  Not a GEP and not an AddRec: " << *Ptr << "\n");
      return false;
    }
    
    // Direct AddRec case (optimized code)
    if (AR->getLoop() != L || !AR->isAffine()) {
      return false;
    }
    
    const SCEV *Base = AR->getStart();
    const SCEV *Step = AR->getStepRecurrence(SE);
    const SCEVConstant *StepConst = dyn_cast<SCEVConstant>(Step);
    
    if (!StepConst) {
      return false;
    }
    
    int64_t Stride = StepConst->getAPInt().getSExtValue();
    
    // Create direct stream descriptor
    DirectStreamDescriptor DS;  // All fields auto-initialized to defaults
    DS.StreamID = NextStreamID++;
    DS.LoopID = getOrCreateLoopID(L);
    DS.BaseAddress = Base;
    DS.Stride = Stride;
    DS.IsBaseLinked = isValueDynamic(Base);
    DS.MemInst = MemInst;
    
    if (DS.IsBaseLinked) {
      if (Value *BaseVal = extractDynamicValue(Base)) {
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
      dbgs() << "  Found Direct Stream (optimized path):\n";
      dbgs() << "    Stream ID: " << DS.StreamID << "\n";
      dbgs() << "    Loop ID: " << DS.LoopID << "\n";
      dbgs() << "    Base: " << *Base << "\n";
      dbgs() << "    Stride: " << Stride << " bytes\n";
    });
    
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
  
  // Trace through loads to find the actual induction variable
  Value *IndVar = traceIndexThroughLoads(Index, L);
  if (!IndVar) {
    LLVM_DEBUG(dbgs() << "  Could not trace index to induction variable\n");
    return false;
  }
  
  // Now get the SCEV of the induction variable
  const SCEV *IndVarSCEV = SE.getSCEV(IndVar);
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
  
  // Calculate memory stride: index_step * element_size
  Type *ElementType = GEP->getSourceElementType();
  // For array types like [1000 x i32], get the actual element type
  if (ArrayType *ArrTy = dyn_cast<ArrayType>(ElementType)) {
    ElementType = ArrTy->getElementType();
  }
  int64_t ElementSize = getTypeSizeInBytes(ElementType);
  int64_t IndexStepVal = IndexStepConst->getAPInt().getSExtValue();
  int64_t MemoryStride = IndexStepVal * ElementSize;
  
  // Get base address SCEV
  const SCEV *BaseSCEV = SE.getSCEV(BasePtr);
  
  // Create direct stream descriptor
  DirectStreamDescriptor DS;  // All fields auto-initialized to defaults
  DS.StreamID = NextStreamID++;
  DS.LoopID = getOrCreateLoopID(L);
  DS.BaseAddress = BaseSCEV;
  DS.Stride = MemoryStride;
  DS.IsBaseLinked = isValueDynamic(BaseSCEV);
  DS.MemInst = MemInst;
  
  // Check if base is dynamic
  if (DS.IsBaseLinked) {
    DS.BaseAddressValue = extractDynamicValue(BaseSCEV);
    if (DS.BaseAddressValue) {
      Type *BaseTy = DS.BaseAddressValue->getType();
      unsigned Size = BaseTy->isPointerTy() ? 8 : getTypeSizeInBytes(BaseTy);
      DS.LinkID = getOrCreateLinkID(DS.BaseAddressValue, Size);
      ++NumDynamicBases;
    }
  }
  
  DirectStreams.push_back(DS);
  InstToStreamIDMap[MemInst] = DS.StreamID;
  ++NumDirectStreams;
  
  LLVM_DEBUG({
    dbgs() << "  Found Direct Stream (GEP path):\n";
    dbgs() << "    Stream ID: " << DS.StreamID << "\n";
    dbgs() << "    Loop ID: " << DS.LoopID << "\n";
    dbgs() << "    Base: " << *BaseSCEV << "\n";
    dbgs() << "    Element Size: " << ElementSize << " bytes\n";
    dbgs() << "    Index Step: " << IndexStepVal << "\n";
    dbgs() << "    Memory Stride: " << MemoryStride << " bytes\n";
    dbgs() << "    Base Linked: " << DS.IsBaseLinked << "\n";
  });
  
  return true;
}

Value *InterStellarStreamAnalyzer::traceIndexThroughLoads(Value *Index, Loop *L) {
  // Trace through loads, casts, and sign extensions to find the underlying
  // induction variable (PHI node)
  // This handles unoptimized IR where loop variables are in stack slots
  
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
  }
  
  return HasDynamic;
}

Value *InterStellarStreamAnalyzer::extractDynamicValue(const SCEV *S) {
  // Extract the underlying IR Value from SCEVUnknown
  if (const SCEVUnknown *Unknown = dyn_cast<SCEVUnknown>(S)) {
    return Unknown->getValue();
  }
  
  // For composite expressions, try to find the base unknown value
  if (const SCEVAddExpr *Add = dyn_cast<SCEVAddExpr>(S)) {
    for (const SCEV *Op : Add->operands()) {
      if (Value *V = extractDynamicValue(Op)) {
        return V;
      }
    }
  } else if (const SCEVMulExpr *Mul = dyn_cast<SCEVMulExpr>(S)) {
    for (const SCEV *Op : Mul->operands()) {
      if (Value *V = extractDynamicValue(Op)) {
        return V;
      }
    }
  } else if (const SCEVSMaxExpr *SMax = dyn_cast<SCEVSMaxExpr>(S)) {
    // For smax(a, b), extract the dynamic operand
    for (const SCEV *Op : SMax->operands()) {
      if (Value *V = extractDynamicValue(Op)) {
        return V;
      }
    }
  } else if (const SCEVUMaxExpr *UMax = dyn_cast<SCEVUMaxExpr>(S)) {
    // For umax(a, b), extract the dynamic operand
    for (const SCEV *Op : UMax->operands()) {
      if (Value *V = extractDynamicValue(Op)) {
        return V;
      }
    }
  } else if (const SCEVCastExpr *Cast = dyn_cast<SCEVCastExpr>(S)) {
    return extractDynamicValue(Cast->getOperand());
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

void InterStellarStreamAnalyzer::print(raw_ostream &OS) const {
  OS << "\n";
  OS << "╔═══════════════════════════════════════════════════════════════╗\n";
  OS << "║     InterStellar Stream Analysis Results                     ║\n";
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
      if (LD.ParentLoopID > 0) {
        OS << " (nested in Loop " << LD.ParentLoopID << ")";
      }
      OS << "\n";
      
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
      
      // Shared flag
      OS << "  ├─ Shared:       " << (DS.IsShared ? "Yes [S=1]" : "No [S=0]") << "\n";
      
      // Source instruction
      if (DS.MemInst) {
        OS << "  └─ Source:       " << *DS.MemInst << "\n";
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
  auto &DT = AM.getResult<DominatorTreeAnalysis>(F);
  
  // Early exit if no loops
  if (LI.empty()) {
    return PreservedAnalyses::all();
  }
  
  LLVM_DEBUG(dbgs() << "Running InterStellar analysis on function: "
                    << F.getName() << "\n");
  
  // Create analyzer and run analysis
  InterStellarStreamAnalyzer Analyzer(F, LI, SE, DT);
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
  auto &DT = getAnalysis<DominatorTreeWrapperPass>().getDomTree();
  
  if (LI.empty()) {
    return false;
  }
  
  InterStellarStreamAnalyzer Analyzer(F, LI, SE, DT);
  Analyzer.analyze();
  
  LLVM_DEBUG(Analyzer.print(dbgs()));
  
  // Analysis pass doesn't modify IR
  return false;
}

void InterStellarAnalysisLegacyPass::getAnalysisUsage(AnalysisUsage &AU) const {
  AU.setPreservesAll();
  AU.addRequired<LoopInfoWrapperPass>();
  AU.addRequired<ScalarEvolutionWrapperPass>();
  AU.addRequired<DominatorTreeWrapperPass>();
}

void InterStellarAnalysisLegacyPass::print(raw_ostream &OS,
                                            const Module *M) const {
  OS << "InterStellar Analysis (Legacy Pass)\n";
}

INITIALIZE_PASS_BEGIN(InterStellarAnalysisLegacyPass, "interstellar-analysis",
                      "InterStellar Stream Analysis", false, true)
INITIALIZE_PASS_DEPENDENCY(LoopInfoWrapperPass)
INITIALIZE_PASS_DEPENDENCY(ScalarEvolutionWrapperPass)
INITIALIZE_PASS_DEPENDENCY(DominatorTreeWrapperPass)
INITIALIZE_PASS_END(InterStellarAnalysisLegacyPass, "interstellar-analysis",
                    "InterStellar Stream Analysis", false, true)

// Factory function for legacy pass manager
FunctionPass *createInterStellarAnalysisPass() {
  return new InterStellarAnalysisLegacyPass();
}
