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
  unsigned getOrCreateLoopID(Loop *L);
  unsigned getOrCreateLinkID(Value *V, unsigned SizeInBytes);
  bool isValueDynamic(const SCEV *S);
  Value *extractDynamicValue(const SCEV *S);
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
  
  // Get loop bounds if possible
  // For now, we focus on simple canonical loops
  if (PHINode *IndVar = L->getCanonicalInductionVariable()) {
    LoopDescriptor LD;
    LD.LoopID = LoopID;
    LD.L = L;
    
    // Get parent loop ID if it exists
    Loop *ParentLoop = L->getParentLoop();
    if (ParentLoop) {
      LD.ParentLoopID = getOrCreateLoopID(ParentLoop);
    }
    
    // Try to extract loop bounds using SCEV
    const SCEV *BackedgeTakenCount = SE.getBackedgeTakenCount(L);
    if (!isa<SCEVCouldNotCompute>(BackedgeTakenCount)) {
      // We have trip count information
      LD.StartValue = SE.getConstant(IndVar->getType(), 0);
      LD.EndValue = BackedgeTakenCount;
      
      // Check if end value is dynamic
      if (isValueDynamic(BackedgeTakenCount)) {
        LD.IsEndLinked = true;
        LD.EndValueDynamic = extractDynamicValue(BackedgeTakenCount);
        if (LD.EndValueDynamic) {
          getOrCreateLinkID(LD.EndValueDynamic, 
                           getTypeSizeInBytes(LD.EndValueDynamic->getType()));
        }
      }
      
      // Get step value
      const SCEV *IndVarSCEV = SE.getSCEV(IndVar);
      if (const SCEVAddRecExpr *AR = dyn_cast<SCEVAddRecExpr>(IndVarSCEV)) {
        LD.StepValue = AR->getStepRecurrence(SE);
      }
      
      LoopDescriptors.push_back(LD);
    }
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
  // Get the SCEV for the pointer
  const SCEV *PtrSCEV = SE.getSCEV(Ptr);
  
  // Check if it's an AddRecExpr (affine recurrence)
  const SCEVAddRecExpr *AR = dyn_cast<SCEVAddRecExpr>(PtrSCEV);
  
  if (!AR) {
    LLVM_DEBUG(dbgs() << "  Not an AddRec: " << *PtrSCEV << "\n");
    return false;
  }
  
  // Check if it belongs to this loop
  if (AR->getLoop() != L) {
    LLVM_DEBUG(dbgs() << "  AddRec for different loop\n");
    return false;
  }
  
  // Check if it's affine (linear: base + stride * i)
  if (!AR->isAffine()) {
    LLVM_DEBUG(dbgs() << "  Not affine (non-linear recurrence)\n");
    return false;
  }
  
  // Extract base and stride
  const SCEV *Base = AR->getStart();
  const SCEV *Step = AR->getStepRecurrence(SE);
  
  // Stride must be constant
  const SCEVConstant *StepConst = dyn_cast<SCEVConstant>(Step);
  if (!StepConst) {
    LLVM_DEBUG(dbgs() << "  Non-constant stride\n");
    return false;
  }
  
  int64_t Stride = StepConst->getAPInt().getSExtValue();
  
  // Create direct stream descriptor
  DirectStreamDescriptor DS;
  DS.StreamID = NextStreamID++;
  DS.LoopID = getOrCreateLoopID(L);
  DS.BaseAddress = Base;
  DS.Stride = Stride;
  DS.MemInst = MemInst;
  
  // Check if base is dynamic (runtime variable)
  DS.IsBaseLinked = isValueDynamic(Base);
  if (DS.IsBaseLinked) {
    DS.BaseAddressValue = extractDynamicValue(Base);
    if (DS.BaseAddressValue) {
      Type *PtrTy = Ptr->getType();
      unsigned PtrSize = getTypeSizeInBytes(PtrTy);
      getOrCreateLinkID(DS.BaseAddressValue, PtrSize);
      ++NumDynamicBases;
    }
  }
  
  DirectStreams.push_back(DS);
  InstToStreamIDMap[MemInst] = DS.StreamID;
  ++NumDirectStreams;
  
  LLVM_DEBUG({
    dbgs() << "  Direct Stream found:\n";
    dbgs() << "    Stream ID: " << DS.StreamID << "\n";
    dbgs() << "    Loop ID: " << DS.LoopID << "\n";
    dbgs() << "    Base: " << *Base << "\n";
    dbgs() << "    Stride: " << Stride << "\n";
    dbgs() << "    Base Linked: " << (DS.IsBaseLinked ? "Yes" : "No") << "\n";
    if (DS.BaseAddressValue) {
      dbgs() << "    Base Value: " << *DS.BaseAddressValue << "\n";
    }
  });
  
  return true;
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
  if (isa<SCEVUnknown>(S)) {
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
  } else if (const SCEVCastExpr *Cast = dyn_cast<SCEVCastExpr>(S)) {
    return extractDynamicValue(Cast->getOperand());
  }
  
  return nullptr;
}

int64_t InterStellarStreamAnalyzer::getTypeSizeInBytes(Type *Ty) {
  const DataLayout &DL = F.getDataLayout();
  return DL.getTypeStoreSize(Ty).getFixedValue();
}

void InterStellarStreamAnalyzer::print(raw_ostream &OS) const {
  OS << "InterStellar Stream Analysis Results:\n";
  OS << "=====================================\n\n";
  
  OS << "Statistics:\n";
  OS << "  Loops analyzed: " << LoopDescriptors.size() << "\n";
  OS << "  Direct streams: " << DirectStreams.size() << "\n";
  OS << "  Link variables: " << LinkVariables.size() << "\n\n";
  
  if (!LoopDescriptors.empty()) {
    OS << "Loop Descriptors:\n";
    OS << "-----------------\n";
    for (const auto &LD : LoopDescriptors) {
      OS << "Loop ID: " << LD.LoopID << "\n";
      OS << "  Parent Loop ID: " << LD.ParentLoopID << "\n";
      if (LD.StartValue) {
        OS << "  Start: " << *LD.StartValue << "\n";
      }
      if (LD.EndValue) {
        OS << "  End: " << *LD.EndValue;
        if (LD.IsEndLinked) {
          OS << " (Linked)";
        }
        OS << "\n";
      }
      if (LD.StepValue) {
        OS << "  Step: " << *LD.StepValue << "\n";
      }
      OS << "\n";
    }
  }
  
  if (!DirectStreams.empty()) {
    OS << "Direct Streams:\n";
    OS << "---------------\n";
    for (const auto &DS : DirectStreams) {
      OS << "Stream ID: " << DS.StreamID << "\n";
      OS << "  Loop ID: " << DS.LoopID << "\n";
      OS << "  Base: " << *DS.BaseAddress;
      if (DS.IsBaseLinked) {
        OS << " (Linked: ";
        if (DS.BaseAddressValue) {
          OS << *DS.BaseAddressValue;
        }
        OS << ")";
      }
      OS << "\n";
      OS << "  Stride: " << DS.Stride << " bytes\n";
      if (DS.MemInst) {
        OS << "  Instruction: " << *DS.MemInst << "\n";
      }
      OS << "\n";
    }
  }
  
  if (!LinkVariables.empty()) {
    OS << "Link Variables:\n";
    OS << "---------------\n";
    for (const auto &LV : LinkVariables) {
      OS << "Link ID: " << LV.LinkID << "\n";
      OS << "  Value: " << *LV.DynamicValue << "\n";
      OS << "  Size: " << LV.SizeInBytes << " bytes\n\n";
    }
  }
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
  
  // Print results to stderr (always visible)
  Analyzer.print(errs());
  
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
