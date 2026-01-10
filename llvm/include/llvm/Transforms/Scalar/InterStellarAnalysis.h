//===- InterStellarAnalysis.h - Loop Stream Analysis ------------*- C++ -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
///
/// \file
/// This file defines the InterStellar stream analysis pass that identifies
/// memory access patterns in loops for hardware-accelerated prefetching.
///
//===----------------------------------------------------------------------===//

#ifndef LLVM_TRANSFORMS_SCALAR_INTERSTELLARANALYSIS_H
#define LLVM_TRANSFORMS_SCALAR_INTERSTELLARANALYSIS_H

#include "llvm/Analysis/LoopInfo.h"
#include "llvm/IR/PassManager.h"

namespace llvm {

class Function;
class FunctionPass;
class Loop;
class ScalarEvolution;
class DominatorTree;
class Instruction;
class Value;

/// Data structure to represent a direct stream descriptor
struct DirectStreamDescriptor {
  unsigned StreamID;
  unsigned LoopID;
  const SCEV *BaseAddress;
  Value *BaseAddressValue;
  int64_t Stride;
  bool IsBaseLinked;
  Instruction *MemInst;
};

/// Data structure to represent an indirect stream descriptor
struct IndirectStreamDescriptor {
  unsigned StreamID;
  unsigned LoopID;
  unsigned BaseStreamID;
  const SCEV *IndexExpression;
};

/// Data structure to represent a loop descriptor
struct LoopDescriptor {
  unsigned LoopID;
  unsigned ParentLoopID;
  Loop *L;
  const SCEV *StartValue;
  const SCEV *EndValue;
  const SCEV *StepValue;
  Value *EndValueDynamic;
  bool IsEndLinked;
};

/// Data structure to represent a link variable descriptor
struct LinkVariableDescriptor {
  unsigned LinkID;
  Value *DynamicValue;
  unsigned SizeInBytes;
};

/// InterStellar Analysis Pass for New Pass Manager
class InterStellarAnalysisPass : public PassInfoMixin<InterStellarAnalysisPass> {
public:
  PreservedAnalyses run(Function &F, FunctionAnalysisManager &AM);
  
  void printResults(raw_ostream &OS) const;
  
  static bool isRequired() { return true; }
};

/// InterStellar Analysis Pass for Legacy Pass Manager
class InterStellarAnalysisLegacyPass : public FunctionPass {
public:
  static char ID;
  
  InterStellarAnalysisLegacyPass() : FunctionPass(ID) {
    initializeInterStellarAnalysisLegacyPassPass(
        *PassRegistry::getPassRegistry());
  }
  
  bool runOnFunction(Function &F) override;
  
  void getAnalysisUsage(AnalysisUsage &AU) const override;
  
  void print(raw_ostream &OS, const Module *M) const override;
};

/// Factory function for creating the legacy pass
FunctionPass *createInterStellarAnalysisPass();

} // namespace llvm

#endif // LLVM_TRANSFORMS_SCALAR_INTERSTELLARANALYSIS_H
