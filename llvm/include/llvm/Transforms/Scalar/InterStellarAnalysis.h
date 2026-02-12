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
#include "llvm/IR/DebugLoc.h"

namespace llvm {

class Function;
class FunctionPass;
class Loop;
class ScalarEvolution;
class SCEV;
class DominatorTree;
class Instruction;
class Value;

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
  
  InterStellarAnalysisLegacyPass();
  
  bool runOnFunction(Function &F) override;
  
  void getAnalysisUsage(AnalysisUsage &AU) const override;
  
  void print(raw_ostream &OS, const Module *M) const override;
};

/// Factory function for creating the legacy pass
FunctionPass *createInterStellarAnalysisPass();

} // namespace llvm

#endif // LLVM_TRANSFORMS_SCALAR_INTERSTELLARANALYSIS_H
