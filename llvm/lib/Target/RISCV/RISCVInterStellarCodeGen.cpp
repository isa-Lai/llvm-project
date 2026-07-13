//===-- RISCVInterStellarCodeGen.cpp - InterStellar CSR Generation --------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This pass runs after register allocation and converts InterStellar
// configuration intrinsics into CSR write instructions. At this point,
// all virtual registers have been allocated to physical registers, so we
// can extract the actual register numbers needed for the binary descriptors.
//
// Binary Descriptor Format (128-bit, stored in two 64-bit CSRs):
//   Link (Type=0x03):
//     [127:120]=Type, [119:112]=Reserved, [111:48]=Address,
//     [47:32]=Size, [31:0]=Reserved
//   Loop (Type=0x00):
//     [127:120]=Type, [119:114]=Parent, [113]=SL, [112]=EL,
//     [111:80]=Start, [79:48]=End, [47:32]=Step, [31:0]=PCOffset
//   DirectStream (Type=0x01):
//     [127:120]=Type, [119:114]=LoopID, [113]=BL, [112]=S,
//     [111:48]=Base, [47:32]=Stride, [31:0]=R/V
//   IndirectStream (Type=0x02):
//     [127:120]=Type, [119:114]=SourceStreamID, [113]=BL, [112]=S,
//     [111:48]=Base, [47:32]=ElementSize, [31:0]=StreamSize
//
//===----------------------------------------------------------------------===//

#include "RISCV.h"
#include "RISCVInstrInfo.h"
#include "RISCVSubtarget.h"
#include "llvm/CodeGen/MachineFunctionPass.h"
#include "llvm/CodeGen/MachineInstrBuilder.h"
#include "llvm/CodeGen/MachineRegisterInfo.h"
#include "llvm/CodeGen/TargetInstrInfo.h"
#include "llvm/IR/IntrinsicsRISCV.h"
#include "llvm/Support/Debug.h"

using namespace llvm;

#define DEBUG_TYPE "riscv-interstellar-codegen"

static uint64_t maskN(uint64_t V, unsigned Bits) {
  if (Bits >= 64)
    return V;
  return V & ((1ULL << Bits) - 1);
}

namespace {

class RISCVInterStellarCodeGen : public MachineFunctionPass {
public:
  static char ID;

  RISCVInterStellarCodeGen() : MachineFunctionPass(ID) {}

  bool runOnMachineFunction(MachineFunction &MF) override;

  StringRef getPassName() const override {
    return "RISC-V InterStellar Code Generation";
  }

private:
  const RISCVInstrInfo *TII = nullptr;
  const RISCVRegisterInfo *TRI = nullptr;
  MachineRegisterInfo *MRI = nullptr;

  /// Extract physical register number from a machine operand
  unsigned getPhysRegNumber(const MachineOperand &MO);

  /// Generate CSR write instructions for a binary descriptor
  void emitDescriptorCSRWrites(MachineBasicBlock &MBB,
                               MachineBasicBlock::iterator MBBI,
                               const DebugLoc &DL,
                               unsigned GlobalID,
                               uint64_t DescriptorHigh,
                               uint64_t DescriptorLow);

  /// Process pseudo-instructions (post-RA)
  bool processLinkPseudo(MachineBasicBlock &MBB, MachineInstr &MI);
  bool processLoopPseudo(MachineBasicBlock &MBB, MachineInstr &MI);
  bool processDirectStreamPseudo(MachineBasicBlock &MBB, MachineInstr &MI);
  bool processIndirectStreamPseudo(MachineBasicBlock &MBB, MachineInstr &MI);
};

} // end anonymous namespace

char RISCVInterStellarCodeGen::ID = 0;

INITIALIZE_PASS(RISCVInterStellarCodeGen, DEBUG_TYPE,
                "RISC-V InterStellar Code Generation", false, false)

FunctionPass *llvm::createRISCVInterStellarCodeGenPass() {
  return new RISCVInterStellarCodeGen();
}

unsigned RISCVInterStellarCodeGen::getPhysRegNumber(const MachineOperand &MO) {
  if (!MO.isReg())
    return 0;
  
  Register Reg = MO.getReg();
  if (!Reg.isPhysical())
    return 0;

  unsigned Enc = TRI->getEncodingValue(Reg);

  // Use compact argument-register indexing for link payload compatibility:
  // a0..a7 -> 0..7.
  if (Enc >= 10 && Enc <= 17)
    return Enc - 10;

  // Fallback to architectural register index.
  return Enc;
}

void RISCVInterStellarCodeGen::emitDescriptorCSRWrites(
    MachineBasicBlock &MBB, MachineBasicBlock::iterator MBBI,
    const DebugLoc &DL, unsigned GlobalID, uint64_t DescriptorHigh,
    uint64_t DescriptorLow) {
  
  // InterStellar CSRs use RV64 pair mapping per GlobalID:
  //   base = 0x800 + (2 * GlobalID)
  //   base + 0 : bits [63:0]   (low)
  //   base + 1 : bits [127:64] (high, contains type header at [127:120])
  unsigned CSR_LOW = 0x800 + (2 * GlobalID);
  unsigned CSR_HIGH = CSR_LOW + 1;

  LLVM_DEBUG(dbgs() << "Emitting CSR writes for GlobalID=" << GlobalID << "\n");
  LLVM_DEBUG(dbgs() << "  Descriptor[127:64] = 0x" << utohexstr(DescriptorHigh) << "\n");
  LLVM_DEBUG(dbgs() << "  Descriptor[63:0]   = 0x" << utohexstr(DescriptorLow) << "\n");

    // Use dedicated scratch registers for post-RA emission.
    // FIXME: Replace fixed registers with register scavenging.
    Register TempRegLow = RISCV::X5;
    Register TempRegHigh = RISCV::X6;

    // Materialize and write low 64 bits first.
    TII->movImm(MBB, MBBI, DL, TempRegLow, DescriptorLow);
  BuildMI(MBB, MBBI, DL, TII->get(RISCV::CSRRW))
      .addReg(RISCV::X0, RegState::Define)
      .addImm(CSR_LOW)
      .addReg(TempRegLow);

    // Materialize and write high 64 bits.
    TII->movImm(MBB, MBBI, DL, TempRegHigh, DescriptorHigh);
  BuildMI(MBB, MBBI, DL, TII->get(RISCV::CSRRW))
      .addReg(RISCV::X0, RegState::Define)
      .addImm(CSR_HIGH)
      .addReg(TempRegHigh);
}

// Post-RA pseudo-instruction processing functions
// These extract physical register numbers and emit actual CSR writes

bool RISCVInterStellarCodeGen::processLinkPseudo(MachineBasicBlock &MBB, 
                                                  MachineInstr &MI) {
  DebugLoc DL = MI.getDebugLoc();
  
  // PseudoInterStellarLink operands: GlobalID, Ptr, Size
  const MachineOperand &GlobalIDOp = MI.getOperand(0);
  const MachineOperand &PtrOp = MI.getOperand(1);
  const MachineOperand &SizeOp = MI.getOperand(2);

  if (!GlobalIDOp.isImm() || !SizeOp.isImm()) {
    LLVM_DEBUG(dbgs() << "Warning: Link pseudo has non-constant immediate operands\n");
    return false;
  }

  unsigned GlobalID = GlobalIDOp.getImm();
  unsigned Size = SizeOp.getImm();

  // Extract physical register number from Ptr operand
  unsigned RegNum = getPhysRegNumber(PtrOp);

  LLVM_DEBUG(dbgs() << "Processing Link Pseudo: GlobalID=" << GlobalID 
                    << ", RegNum=" << RegNum << ", Size=" << Size << "\n");

  // Link descriptor layout:
  // [127:120]=0x03, [119:112]=0, [111:48]=Address, [47:32]=Size, [31:0]=0.
  const uint64_t Address = maskN(static_cast<uint64_t>(RegNum), 64);
  const uint64_t AddressHigh48 = maskN(Address >> 16, 48);
  const uint64_t AddressLow16 = maskN(Address, 16);
  const uint64_t Size16 = maskN(static_cast<uint64_t>(Size), 16);

  const uint64_t DescriptorHigh = (0x03ULL << 56) | AddressHigh48;
  const uint64_t DescriptorLow = (AddressLow16 << 48) | (Size16 << 32);

  auto MBBI = MachineBasicBlock::iterator(MI);
  emitDescriptorCSRWrites(MBB, MBBI, DL, GlobalID, DescriptorHigh, DescriptorLow);
  
  return true;
}

bool RISCVInterStellarCodeGen::processLoopPseudo(MachineBasicBlock &MBB,
                                                  MachineInstr &MI) {
  DebugLoc DL = MI.getDebugLoc();
  
  // PseudoInterStellarLoop operands: GlobalID, Parent, IsParallel, IsReduction,
  //                                   Start, End, Step
  const MachineOperand &GlobalIDOp = MI.getOperand(0);
  const MachineOperand &ParentOp = MI.getOperand(1);
  const MachineOperand &IsParallelOp = MI.getOperand(2);
  const MachineOperand &IsReductionOp = MI.getOperand(3);
  const MachineOperand &StartOp = MI.getOperand(4);
  const MachineOperand &EndOp = MI.getOperand(5);
  const MachineOperand &StepOp = MI.getOperand(6);

  if (!GlobalIDOp.isImm() || !ParentOp.isImm() || !IsParallelOp.isImm() ||
      !IsReductionOp.isImm() || !StartOp.isImm() || !EndOp.isImm() ||
      !StepOp.isImm()) {
    LLVM_DEBUG(dbgs() << "Warning: Loop pseudo has non-constant immediate operands\n");
    return false;
  }

  unsigned GlobalID = GlobalIDOp.getImm();
  unsigned Parent = ParentOp.getImm();
  unsigned StartLinked = IsParallelOp.getImm();
  unsigned EndLinked = IsReductionOp.getImm();
  unsigned StartValue = StartOp.getImm();
  unsigned EndValue = EndOp.getImm();
  unsigned Step = StepOp.getImm();

  // be.md loop descriptor layout:
  // [127:120] Type=0x00, [119:114] Parent(6), [113] SL, [112] EL,
  // [111:80] Start(32), [79:48] End(32), [47:32] Step(16), [31:0] PCOffset
  // where PCOffset is currently encoded as 0.
  uint64_t DescriptorHigh = (0x00ULL << 56) |
                            (maskN(Parent, 6) << 50) |
                            (maskN(StartLinked, 1) << 49) |
                            (maskN(EndLinked, 1) << 48) |
                            (maskN(StartValue, 32) << 16) |
                            maskN((uint64_t)EndValue >> 16, 16);

  uint64_t DescriptorLow = (maskN(EndValue, 16) << 48) |
                           (maskN(Step, 16) << 32);

  auto MBBI = MachineBasicBlock::iterator(MI);
  emitDescriptorCSRWrites(MBB, MBBI, DL, GlobalID, DescriptorHigh, DescriptorLow);
  
  return true;
}

bool RISCVInterStellarCodeGen::processDirectStreamPseudo(MachineBasicBlock &MBB,
                                                          MachineInstr &MI) {
  DebugLoc DL = MI.getDebugLoc();
  
  // PseudoInterStellarDirectStream operands: GlobalID, LoopID, IsLinked,
  //                                           Ptr, BaseID, Stride
  const MachineOperand &GlobalIDOp = MI.getOperand(0);
  const MachineOperand &LoopIDOp = MI.getOperand(1);
  const MachineOperand &IsLinkedOp = MI.getOperand(2);
  const MachineOperand &PtrOp = MI.getOperand(3);
  const MachineOperand &BaseIDOp = MI.getOperand(4);
  const MachineOperand &StrideOp = MI.getOperand(5);

  if (!GlobalIDOp.isImm() || !LoopIDOp.isImm() || !IsLinkedOp.isImm() ||
      !BaseIDOp.isImm() || !StrideOp.isImm()) {
    LLVM_DEBUG(dbgs() << "Warning: DirectStream pseudo has non-constant immediate operands\n");
    return false;
  }

  unsigned GlobalID = GlobalIDOp.getImm();
  unsigned LoopID = LoopIDOp.getImm();
  unsigned BaseLinked = IsLinkedOp.getImm();
  unsigned BaseID = BaseIDOp.getImm();
  unsigned Stride = StrideOp.getImm();

  uint64_t BaseAddress = BaseLinked ? BaseID : getPhysRegNumber(PtrOp);

  // be.md directstream descriptor layout:
  // [127:120] Type=0x01, [119:114] LoopID(6), [113] BL, [112] S,
  // [111:48] BaseAddress(64), [47:32] Stride(16), [31:0] R/V(0)
  // S (stream active) is currently unsupported and defaults to 0.
  uint64_t DescriptorHigh = (0x01ULL << 56) |
                            (maskN(LoopID, 6) << 50) |
                            (maskN(BaseLinked, 1) << 49) |
                            maskN(BaseAddress >> 16, 48);

  uint64_t DescriptorLow = (maskN(BaseAddress, 16) << 48) |
                           (maskN(Stride, 16) << 32);

  auto MBBI = MachineBasicBlock::iterator(MI);
  emitDescriptorCSRWrites(MBB, MBBI, DL, GlobalID, DescriptorHigh, DescriptorLow);
  
  return true;
}

bool RISCVInterStellarCodeGen::processIndirectStreamPseudo(MachineBasicBlock &MBB,
                                                            MachineInstr &MI) {
  DebugLoc DL = MI.getDebugLoc();
  
  // PseudoInterStellarIndirectStream operands: GlobalID, LoopID, IsLinked,
  //                                             BasePtr, BaseID, ElementSize,
  //                                             IndexArraySize
  const MachineOperand &GlobalIDOp = MI.getOperand(0);
  const MachineOperand &LoopIDOp = MI.getOperand(1);
  const MachineOperand &IsLinkedOp = MI.getOperand(2);
  const MachineOperand &BasePtrOp = MI.getOperand(3);
  const MachineOperand &BaseIDOp = MI.getOperand(4);
  const MachineOperand &ElementSizeOp = MI.getOperand(5);
  const MachineOperand &IndexArraySizeOp = MI.getOperand(6);

  if (!GlobalIDOp.isImm() || !LoopIDOp.isImm() || !IsLinkedOp.isImm() ||
      !BaseIDOp.isImm() || !ElementSizeOp.isImm() ||
      !IndexArraySizeOp.isImm()) {
    LLVM_DEBUG(dbgs() << "Warning: IndirectStream pseudo has non-constant immediate operands\n");
    return false;
  }

  unsigned GlobalID = GlobalIDOp.getImm();
  unsigned SourceStreamID = LoopIDOp.getImm();
  unsigned BaseLinked = IsLinkedOp.getImm();
  unsigned BaseID = BaseIDOp.getImm();
  unsigned ElementSize = ElementSizeOp.getImm();
  unsigned StreamSize = IndexArraySizeOp.getImm();

  uint64_t BaseAddress = BaseLinked ? BaseID : getPhysRegNumber(BasePtrOp);

  // be.md indirectstream descriptor layout:
  // [127:120] Type=0x02, [119:114] SourceStreamID(6), [113] BL, [112] S,
  // [111:48] BaseAddress(64), [47:32] ElementSize(16), [31:0] StreamSize(32)
  // S (stream active) is currently unsupported and defaults to 0.
  uint64_t DescriptorHigh = (0x02ULL << 56) |
                            (maskN(SourceStreamID, 6) << 50) |
                            (maskN(BaseLinked, 1) << 49) |
                            maskN(BaseAddress >> 16, 48);

  uint64_t DescriptorLow = (maskN(BaseAddress, 16) << 48) |
                           (maskN(ElementSize, 16) << 32) |
                           maskN(StreamSize, 32);

  auto MBBI = MachineBasicBlock::iterator(MI);
  emitDescriptorCSRWrites(MBB, MBBI, DL, GlobalID, DescriptorHigh, DescriptorLow);
  
  return true;
}

bool RISCVInterStellarCodeGen::runOnMachineFunction(MachineFunction &MF) {
  LLVM_DEBUG(dbgs() << "Running RISCVInterStellarCodeGen on " 
                    << MF.getName() << "\n");

  const auto &STI = MF.getSubtarget<RISCVSubtarget>();
  TII = STI.getInstrInfo();
  TRI = STI.getRegisterInfo();
  MRI = &MF.getRegInfo();

  bool Modified = false;
  SmallVector<MachineInstr*, 8> ToErase;

  for (MachineBasicBlock &MBB : MF) {
    for (MachineBasicBlock::iterator MBBI = MBB.begin(); MBBI != MBB.end(); ) {
      MachineInstr &MI = *MBBI;
      ++MBBI; // Advance before potentially erasing

      // Process InterStellar pseudo-instructions
      unsigned Opcode = MI.getOpcode();
      bool Processed = false;
      
      switch (Opcode) {
      case RISCV::PseudoInterStellarLink:
        Processed = processLinkPseudo(MBB, MI);
        break;
      case RISCV::PseudoInterStellarLoop:
        Processed = processLoopPseudo(MBB, MI);
        break;
      case RISCV::PseudoInterStellarDirectStream:
        Processed = processDirectStreamPseudo(MBB, MI);
        break;
      case RISCV::PseudoInterStellarIndirectStream:
        Processed = processIndirectStreamPseudo(MBB, MI);
        break;
      default:
        break;
      }
      
      if (Processed) {
        ToErase.push_back(&MI);
        Modified = true;
      }
    }
  }

  // Erase processed pseudo-instructions
  for (MachineInstr *MI : ToErase) {
    MI->eraseFromParent();
  }

  if (Modified) {
    LLVM_DEBUG(dbgs() << "InterStellarCodeGen: Processed " << ToErase.size() 
                      << " pseudo-instructions\n");
  }

  return Modified;
}
