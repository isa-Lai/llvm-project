//===-- RISCVInstrInfoInterStellar.td - InterStellar Instr -*- tablegen -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file describes the RISC-V InterStellar hardware prefetch configuration
// pseudo-instructions.
//
//===----------------------------------------------------------------------===//

//===----------------------------------------------------------------------===//
// Pseudo-instructions for InterStellar configuration
//
// These pseudo-instructions carry the configuration information through
// instruction selection and register allocation. They are expanded to actual
// CSR write instructions in a post-RA pass when physical register numbers
// are known.
//
// Note: i1 types are automatically legalized to i32 by SelectionDAG, so we
// use GPR for all operands.
//===----------------------------------------------------------------------===//

let hasSideEffects = 1, mayLoad = 0, mayStore = 0, isCodeGenOnly = 1 in {

// InterStellar Link Configuration
// configure.link(GlobalID, ptr, Size)
def PseudoInterStellarLink : Pseudo<(outs), 
                                    (ins uimm8:$globalid, GPR:$ptr,
                                         uimm32:$size),
                                    []>, 
                             Sched<[]>;

// InterStellar Loop Configuration
// configure.loop(GlobalID, Parent, IsParallel, IsReduction, Start, End, Step)
def PseudoInterStellarLoop : Pseudo<(outs),
                                    (ins uimm8:$globalid, uimm16:$parent,
                                         uimm1:$isparallel, uimm1:$isreduction,
                                         uimm32:$start, uimm32:$end,
                                         uimm32:$step),
                                    []>, 
                             Sched<[]>;

// InterStellar Direct Stream Configuration
// configure.directstream(GlobalID, LoopID, IsLinked, ptr, Stride)
// If IsLinked=1, baseid carries the remapped Link GlobalID.
def PseudoInterStellarDirectStream : Pseudo<(outs),
                                            (ins uimm8:$globalid,
                                                 uimm16:$loopid,
                                                 uimm1:$islinked,
                                                 GPR:$ptr,
                                                 uimm32:$baseid,
                                                 uimm32:$stride),
                                            []>, 
                                     Sched<[]>;

// InterStellar Indirect Stream Configuration
// configure.indirectstream(GlobalID, LoopID, IsLinked, BasePtr, ElementSize, IndexArraySize)
// If IsLinked=1, baseid carries the remapped Link GlobalID.
def PseudoInterStellarIndirectStream : Pseudo<(outs),
                                              (ins uimm8:$globalid,
                                                   uimm16:$loopid,
                                                   uimm1:$islinked,
                                                   GPR:$baseptr,
                                                   uimm32:$baseid,
                                                   uimm32:$elementsize,
                                                   uimm32:$indexarraysize),
                                              []>, 
                                       Sched<[]>;

} // hasSideEffects = 1, mayLoad = 0, mayStore = 0, isCodeGenOnly = 1