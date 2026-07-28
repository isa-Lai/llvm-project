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
//   All descriptors:
//     [5:0]=Type, [1]=Valid, [0]=Active, [119:8+]=Type-specific fields
//   Link (Type=0x03):
//     [5:0]=Type(3), [119:112]=Reserved, [111:48]=Address,
//     [47:32]=Size, [31:0]=Reserved
//   Loop (Type=0x00):
//     [5:0]=Type(0), [119:114]=Parent, [113]=SL, [112]=EL,
//     [111:80]=Start, [79:48]=End, [47:32]=Step, [31:0]=PCOffset
//   DirectStream (Type=0x01):
//     [5:0]=Type(1), [119:114]=LoopID, [113]=BL, [112]=S,
//     [111:48]=Base, [47:32]=Stride, [31:0]=R/V
//   IndirectStream (Type=0x02):
//     [5:0]=Type(2), [119:114]=SourceStreamID, [113]=BL, [112]=S,
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
  //   base + 0 : bits [63:0]   (becomes desc_word[0], contains type at bits [5:0])
  //   base + 1 : bits [127:64] (becomes desc_word[1])
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

  // Hardware Link descriptor layout:
  // MISA_Desc_t structure: uint8_t type:6, valid:1, active:1 (LSB to MSB)
  // First byte of desc_word[0]: [5:0]=Type(3), [6]=Valid(1), [7]=Active(1)
  // So the byte value = Type | (Valid << 6) | (Active << 7)
  const uint64_t Address = maskN(static_cast<uint64_t>(RegNum), 64);
  const uint64_t Size16 = maskN(static_cast<uint64_t>(Size), 16);

  const uint64_t DescriptorLow = ((0x03ULL & 0x3FULL) << 0) |  // Type=3, shift to bits [5:0]
                                  (0x1ULL << 6) |                 // Valid=1 in bit [1]
                                  (0x1ULL << 7) |                 // Active=1 in bit [0]
                                  (0x0ULL << 8) |                 // Reserved in bits [13:8]
                                  (maskN(Address, 64) << 16);      // Address in bits [79:16]

  const uint64_t DescriptorHigh = (Size16 << 0) |              // Size in bits [15:0]
                                   (0x0ULL << 16);               // Reserved in bits [63:16]

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

  // Hardware loop descriptor layout:
  // DescriptorLow (becomes desc_word[0]): [5:0]=Type(0), [6]=Valid(1), [7]=Active(1),
  //                                      [13:8]=Parent(6), [14]=SL, [15]=EL,
  //                                      [47:16]=Start(32), [79:48]=End[15:0](16)
  // DescriptorHigh (becomes desc_word[1]): [15:0]=End[31:16](16), [31:16]=Step(16),
  //                                       [63:32]=PCOffset(32)
  uint64_t DescriptorLow = ((0x00ULL & 0x3FULL) << 0) |  // Type=0 in bits [5:0]
                           (0x1ULL << 6) |                 // Valid in bit [1]
                           (0x1ULL << 7) |                 // Active in bit [0]
                           (maskN(Parent, 6) << 8) |       // Parent in bits [13:8]
                           (maskN(StartLinked, 1) << 14) | // SL in bit [14]
                           (maskN(EndLinked, 1) << 15) |   // EL in bit [15]
                           (maskN(StartValue, 32) << 16) | // Start in bits [47:16]
                           (maskN(EndValue & 0xFFFF, 16) << 48); // End[15:0] in bits [63:48]

  uint64_t DescriptorHigh = (maskN((EndValue >> 16) & 0xFFFF, 16) << 0) | // End[31:16] in bits [15:0]
                            (maskN(Step, 16) << 16) |       // Step in bits [31:16]
                            (0x0ULL << 32);                  // PCOffset in bits [63:32] (currently 0)

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

  // Hardware directstream descriptor layout:
  // DescriptorLow (becomes desc_word[0]): [5:0]=Type(1), [6]=Valid(1), [7]=Active(1),
  //                                      [13:8]=LoopID(6), [14]=BL, [15]=S(0),
  //                                      [79:16]=BaseAddress(64)
  // DescriptorHigh (becomes desc_word[1]): [15:0]=Stride(16), [63:16]=Reserved(0)
  uint64_t DescriptorLow = ((0x01ULL & 0x3FULL) << 0) |  // Type=1 in bits [5:0]
                           (0x1ULL << 6) |                 // Valid in bit [1]
                           (0x1ULL << 7) |                 // Active in bit [0]
                           (maskN(LoopID, 6) << 8) |       // LoopID in bits [13:8]
                           (maskN(BaseLinked, 1) << 14) |  // BL in bit [14]
                           (0x0ULL << 15) |                // S in bit [15] (unsupported)
                           (maskN(BaseAddress, 64) << 16); // BaseAddress in bits [79:16]

  uint64_t DescriptorHigh = maskN(Stride, 16) |   // Stride in bits [15:0]
                           (0x0ULL << 16);       // Reserved in bits [63:16]

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

  // Hardware indirectstream descriptor layout:
  // DescriptorLow (becomes desc_word[0]): [5:0]=Type(2), [6]=Valid(1), [7]=Active(1),
  //                                      [13:8]=SourceStreamID(6), [14]=BL, [15]=S(0),
  //                                      [79:16]=BaseAddress(64)
  // DescriptorHigh (becomes desc_word[1]): [15:0]=ElementSize(16), [47:16]=StreamSize(32),
  //                                       [63:48]=Reserved(0)
  uint64_t DescriptorLow = ((0x02ULL & 0x3FULL) << 0) |  // Type=2 in bits [5:0]
                           (0x1ULL << 6) |                 // Valid in bit [1]
                           (0x1ULL << 7) |                 // Active in bit [0]
                           (maskN(SourceStreamID, 6) << 8) | // SourceStreamID in bits [13:8]
                           (maskN(BaseLinked, 1) << 14) |  // BL in bit [14]
                           (0x0ULL << 15) |                // S in bit [15] (unsupported)
                           (maskN(BaseAddress, 64) << 16); // BaseAddress in bits [79:16]

  uint64_t DescriptorHigh = maskN(ElementSize, 16) |   // ElementSize in bits [15:0]
                            (maskN(StreamSize, 32) << 16) | // StreamSize in bits [47:16]
                            (0x0ULL << 48);                 // Reserved in bits [63:48]

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
