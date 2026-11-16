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

#include "llvm/IR/PassManager.h"
#include "llvm/Pass.h"

namespace llvm {

class Function;
class FunctionPass;
class Loop;
class ScalarEvolution;
class SCEV;
class DominatorTree;
class Instruction;
class Value;

/// InterStellar Analysis Pass for New Pass Manager
class InterStellarAnalysisPass
    : public RequiredPassInfoMixin<InterStellarAnalysisPass> {
public:
  PreservedAnalyses run(Function &F, FunctionAnalysisManager &AM);
};

/// InterStellar Analysis Pass for Legacy Pass Manager
class InterStellarAnalysisLegacyPass : public FunctionPass {
public:
  static char ID;
  
  InterStellarAnalysisLegacyPass();
  
  bool runOnFunction(Function &F) override;
  
  void getAnalysisUsage(AnalysisUsage &AU) const override;
  
  void print(raw_ostream &OS, const Module *M) const override;
};

/// Factory function for creating the legacy pass
FunctionPass *createInterStellarAnalysisPass();

} // namespace llvm

#endif // LLVM_TRANSFORMS_SCALAR_INTERSTELLARANALYSIS_H
