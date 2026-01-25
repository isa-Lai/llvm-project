# InterStellar RISC-V Compiler Implementation Plan

**Author:** Senior LLVM Engineer
**Target Audience:** Junior Compiler Developer
**Objective:** Implement a stream-aware compilation flow that analyzes memory access patterns and annotates them into the RISC-V binary using CSRs.

---

## 0. High-Level Architecture & Concepts

We are building a pipeline that transforms **Implicit Control Flow** (C code loops) into **Explicit Data Flow Metadata** (RISC-V CSRs). This metadata is consumed by the **InterStellar Nucleus** (a hardware unit at the LLC) to optimize memory controller behavior.

### Key Concepts

* **Direct Stream:** A memory access pattern with a constant stride.
    * *Example:* A[i] where i increments by 1.
    * *Definition:* Defined by Base Address, Stride, and associated Loop ID.
* **Indirect Stream:** A memory access derived from another stream.
    * *Example:* A[B[i]]. Here, B[i] is a stream that provides indices for A.
    * *Definition:* Defined by Base Address and the *Stream ID* of the index source.
* **Loop Context:** Streams exist within loops. We must define the loop boundaries (Start, End, Step) and their Nesting (Parent Loop).
* **Linked Variables (Dynamic Data):**
    * Sometimes Loop Bounds (N) or Base Addresses (ptr) are not known at compile time (i.e., they are in registers).
    * We use a **Link Variable Descriptor** to tell the hardware: *"The value you need is in Physical Register X."*
    * **Flags:** `SL` (Start Linked), `EL` (End Linked), and `BL` (Base Linked) are bits in the main descriptors that tell the hardware to look up a Link Descriptor.

---

## Part 1: Continuous Direct Memory Access Analysis (Direct Streams)

*Goal: Identify patterns like A[i] and handle dynamic base addresses.*

### 1.1 The Pass Structure

Implement a **Function Pass** via `InterStellarAnalysisPass`. Acquire `LoopInfo`, `ScalarEvolution`, and `DominatorTree`.

### 1.2 The Algorithm (Detailed Logic)

**Step 1: Iterate Loops**
Focus on innermost loops: 
    if (L->empty()) analyzeLoop(L, SE);

**Step 2: SCEV Analysis**
For every memory instruction pointer `Ptr`:

1.  **Get SCEV:** const SCEV *S = SE.getSCEV(Ptr);

2.  **Check AddRec:**
    > auto *AR = dyn_cast<SCEVAddRecExpr>(S);
    > if (!AR || AR->getLoop() != L || !AR->isAffine()) return;

3.  **Extract Components:**
    * **Base Address:** const SCEV *Start = AR->getStart();
    * **Stride:** const SCEV *Step = AR->getStepRecurrence(SE);

4.  **Dynamic Value Handling:**
    * **Stride:** Must be constant (dyn_cast<SCEVConstant>). If not, ignore (complex stride).
    * **Base Address:**
        * If `dyn_cast<SCEVConstant>(Start)`: It's a static address (e.g., Global Variable). **Link not needed.**
        * If `dyn_cast<SCEVUnknown>(Start)` (or other non-constant): It is a **Dynamic Value**.
            * **Action:** Mark this stream as **Base Linked (BL)**.
            * **Store:** Capture the `Value*` representing this dynamic base. You will need to generate a `LinkConfig` for it.

### 1.3 Handling Nested Loops (Loop-Inside-Loop)

*Goal: Handle for (i) { for (j) { ... } }.*

LLVM's `LoopInfo` provides a tree structure (`Loop->getParentLoop()`).

1.  **Parent ID Assignment:**
    * When analyzing Loop `L`, check `L->getParentLoop()`.
    * If it exists, retrieve its `LoopID`. Store this in the `Parent Loop ID` field of the Loop Descriptor.

2.  **Dynamic Bounds (Triangular Loops):**
    * *Case:* `for (int j = 0; j < i; j++)` (Inner loop bound depends on outer loop var `i`).
    * *Analysis:* The `End Value` of loop `j` is the Scalar Evolution of `i`.
    * *Action:* Since `i` is a variable in a register, treat this exactly like a **Linked Variable**. Assign a `LinkID` to `i`, set `End Linked (EL) = 1`, and map `i` to a Link Descriptor.

---

## Part 2: Indirect & Chained Memory Access Analysis

*Goal: Identify patterns like A[B[i]] (Simple Indirect) and A[B[C[i]]] (Chained/Nested Indirect).*

### 2.1 Basic Indirect Analysis

**Step 1: Trace Origin**
If `Ptr` is not affine, check if it is a GEP where the index comes from a `LoadInst`.

**Step 2: Match to Direct Stream**
If that `LoadInst` was already identified as a Direct Stream:
* Create an Indirect Stream Descriptor.
* **Base Address Check:** Check if the Base Address of `A` is constant or dynamic (use BL flag if dynamic).

### 2.2 Advanced Chaining Analysis (Recursive)

*Goal: Handle A[B[C[i]]] where C is Direct, B is Indirect (on C), and A is Indirect (on B).*

**Algorithm: Recursive Back-Slicing**

    // Returns the StreamID if the instruction is part of a known stream
    Optional<int> getStreamSource(Instruction *I) {
        if (DirectStreams.count(I)) return DirectStreams[I].ID;
        if (IndirectStreams.count(I)) return IndirectStreams[I].ID;
        
        // If it's a Load, check its pointer origin
        if (auto *Load = dyn_cast<LoadInst>(I)) {
           Value *Ptr = Load->getPointerOperand();
           // Recursively find if the Ptr is calculated by a stream
           if (auto *GEP = dyn_cast<GetElementPtrInst>(Ptr)) {
               Value *Index = GEP->getOperand(1);
               // RECURSION: Does the Index come from a stream?
               if (auto *IndexInst = dyn_cast<Instruction>(Index)) {
                   auto SourceStreamID = getStreamSource(IndexInst);
                   if (SourceStreamID) {
                       // FOUND CHAIN: This Load is an Indirect Stream
                       // driven by SourceStreamID.
                       int NewID = createIndirectStream(Load, *SourceStreamID);
                       return NewID;
                   }
               }
           }
        }
        return None;
    }

* **Logic:**
    1.  Compiler identifies `C[i]` as Direct Stream #1.
    2.  Compiler analyzes `B[...]`. It sees the index is `Load(C[i])`. It identifies `B` as Indirect Stream #2 (linked to #1).
    3.  Compiler analyzes `A[...]`. It sees the index is `Load(B[...])`. It identifies `A` as Indirect Stream #3 (linked to #2).

---

## Part 3: IR Design (Intrinsics Definitions)

We need a new intrinsic for Linked Variables.

**File:** llvm/include/llvm/IR/IntrinsicsRISCV.td

    // 1. Link Variable Configuration Intrinsic (NEW)
    // Args: LinkID, Value (The dynamic runtime value), Size (in bytes)
    // The Backend will map 'Value' to a Physical Register ID.
    def int_riscv_interstellar_link_config : Intrinsic<[],
        [llvm_i32_ty, llvm_anyint_ty, llvm_i32_ty],
        [IntrHasSideEffects]>;
    
    // 2. Loop Configuration Intrinsic
    // Args: LoopID, ParentLoopID, StartValue, EndValue, Step
    // NOTE: If Start/End are linked, pass the LinkID in StartValue/EndValue args.
    def int_riscv_interstellar_loop_config : Intrinsic<[],
        [llvm_i32_ty, llvm_i32_ty, llvm_anyint_ty, llvm_anyint_ty, llvm_i32_ty],
        [IntrHasSideEffects]>;
    
    // 3. Direct Stream Config (Updated for BL flag)
    // Args: StreamID, LoopID, BaseAddr (Ptr or LinkID), Stride, Flags (Bitmask for BL)
    def int_riscv_interstellar_direct_config : Intrinsic<[],
        [llvm_i32_ty, llvm_i32_ty, llvm_anyint_ty, llvm_i32_ty, llvm_i32_ty],
        [IntrHasSideEffects]>;
    
    // 4. Indirect Stream Config
    def int_riscv_interstellar_indirect_config : Intrinsic<[],
        [llvm_i32_ty, llvm_anyint_ty, llvm_i32_ty, llvm_i32_ty, llvm_i32_ty],
        [IntrHasSideEffects]>;

### Insertion Logic (IRBuilder)

In `LoopPreheader`:

1.  **Analyze Loop Bounds:**
    * If `LoopStart` is dynamic (Variable `N`), assign it a unique `LinkID` (e.g., 1).
    * Emit `Builder.CreateCall(LinkConfigFunc, {1, N, 8})`.
    * When emitting `LoopConfig`, set the `SL` (Start Linked) bit and pass `1` as the Start Value.

2.  **Analyze Stream Bases:**
    * If Stream 0 has dynamic base `%ptr`, assign it `LinkID` 2.
    * Emit `Builder.CreateCall(LinkConfigFunc, {2, %ptr, 8})`.
    * When emitting `DirectConfig`, set the `BL` (Base Linked) bit and pass `2` as the Base Address.

---

## Part 4: RISC-V ISA & Backend Implementation (Strict Descriptor Design)

*Goal: Pack the IR arguments into the specific 128-bit descriptors defined below and write them to CSRs.*

You must implement the bit-packing logic in the RISC-V Backend. Since RISC-V CSRs are 64-bit, **each 128-bit descriptor is split into two 64-bit writes.**

### 4.1 Descriptor Layouts & Semantic Definitions

The bit-fields below are strictly defined. The backend must respect these boundaries exactly.

#### 1. Loop Descriptor
**Purpose:** Defines loop boundaries (Start, End, Step).
* **Linking (SL/EL):** If start or end values are variables (e.g., Start=j, End <= k), the `SL` or `EL` bit is set to 1. The Start/End Value field then stores the **Link Descriptor ID** instead of the immediate value.

| Bits | Field Name | Definition & Semantics |
| :--- | :--- | :--- |
| **127-120** | **Header** | **Descriptor Type & Activation.** Set to `0x00`. Writing this activates the loop context. |
| **119-114** | **Parent Loop ID** | **Nesting.** Stores the outer loop's ID in nested loops; or `0` if outermost. |
| **113** | **Start Linked (SL)** | **Dynamic Flag.** 1 = `Start Value` is a Link ID. 0 = `Start Value` is an Immediate. |
| **112** | **End Linked (EL)** | **Dynamic Flag.** 1 = `End Value` is a Link ID. 0 = `End Value` is an Immediate. |
| **111-80** | **Start Value** | **Loop Lower Bound.** 32-bit immediate or Link ID (if SL=1). |
| **79-48** | **End Value** | **Loop Upper Bound.** 32-bit immediate or Link ID (if EL=1). |
| **47-32** | **Step** | **Induction Increment.** The amount the loop variable increases per iteration. |
| **31-0** | **Offset PC Header** | **Debug/PC.** Offset of the loop start instruction. |

#### 2. Direct Stream Descriptor
**Purpose:** Defines `A[i]` streams with constant stride.
* **Linking (BL):** If Base Address (BA) connects to a variable, `BL` is set to 1, and BA stores the **Link Descriptor ID**.

| Bits | Field Name | Definition & Semantics |
| :--- | :--- | :--- |
| **127-120** | **Header** | **Descriptor Type.** Set to `0x01` for Direct Stream. |
| **119-114** | **Loop Desc ID** | **Context.** The ID of the innermost Loop driving this stream. |
| **113** | **Base Linked (BL)** | **Dynamic Flag.** 1 = `Base Address` is a Link ID. 0 = `Base Address` is a Virtual Address. |
| **112** | **Shared (S)** | **Multi-core.** 1 = Shared stream between threads. 0 = Private. |
| **111-48** | **Base Address** | **Virtual Base.** The pointer to the array start. If BL=1, this holds the Link ID. |
| **47-32** | **Stride** | **Access Step.** Byte difference between two consecutive stream elements. |
| **31-0** | **R/V** | **Reserved/Value.** Set to `0`. |

#### 3. Indirect Stream Descriptor
**Purpose:** Defines `A[B[i]]` streams (random access).
* **Linking (BL):** Same usage as Direct Stream (1 if Base Address is dynamic).

| Bits | Field Name | Definition & Semantics |
| :--- | :--- | :--- |
| **127-120** | **Header** | **Descriptor Type.** Set to `0x02` for Indirect Stream. |
| **119-114** | **Loop Desc ID** | **Context.** The ID of the associated Loop. |
| **113** | **Base Linked (BL)** | **Dynamic Flag.** 1 = Base Address is Link ID. |
| **112** | **Shared (S)** | **Multi-core.** 1 = Shared stream. |
| **111-48** | **Base Address** | **Virtual Base.** The pointer to the array start. |
| **47-32** | **Element Size** | **Data Width.** Size of the target element (e.g., 8 bytes). Replaces Stride field. |
| **31-0** | **Stream Size** | **Total Size.** Defines the total memory footprint of the indirect stream. |

#### 4. Link Variable Descriptor
**Purpose:** Points to a register containing a runtime value (e.g., N).

| Bits | Field Name | Definition & Semantics |
| :--- | :--- | :--- |
| **127-120** | **Header** | **Descriptor Type.** Set to `0x04` (Link). |
| **119-112** | **R/V** | **Reserved.** Set to `0`. |
| **111-48** | **Address / RegID** | **Source.** Holds the **Physical Register ID** (e.g., index of register `a0`) or Memory Address. |
| **47-32** | **Size** | **Data Width.** Size of the variable in bytes. |
| **31-0** | **R/V** | **Reserved.** Set to `0`. |

### 4.2 Backend Lowering Logic (Packing Strategy)

To write a 128-bit descriptor to 64-bit CSRs, you must split the fields at bit 64.

**Example: Loop Descriptor Splitting**
* **CSR_HIGH (Bits 127-64):**
    * [63:56] = Header (from 127-120)
    * [55:50] = Parent Loop ID (from 119-114)
    * [49]    = SL (from 113)
    * [48]    = EL (from 112)
    * [47:16] = Start Value (from 111-80)
    * [15:0]  = End Value **High** 16 bits (from 79-64)
* **CSR_LOW (Bits 63-0):**
    * [63:48] = End Value **Low** 16 bits (from 63-48)
    * [47:32] = Step
    * [31:0]  = Offset PC

*Implementation Note:* The Backend `PseudoExpansion` must generate `SLLI`, `SRLI`, `OR`, and `AND` instructions to split the 32-bit "End Value" across these two registers.

---

## Part 5: Hardware Context (The "Nucleus" & Memory Controller)

*Goal: Understand how the hardware consumes your metadata to ensure correctness.*

The **InterStellar Nucleus** sits at the Last Level Cache (LLC) and intercepts your descriptors. It uses the conveyed knowledge from CSRs to infer further information.

### 5.1 Derived Hardware Calculations (Equations)

The Nucleus performs immediate math on the descriptors. If your compiler provides incorrect `Step` or `Start/End` values, these calculations will fail.

1.  **Iteration Count:**
    The hardware calculates total loop iterations ($loop\_iterations_i$) using the Start ($S_i$), End ($E_i$), and Step ($I_i$):
    $$loop\_iterations_i = (E_i - S_i) / I_i$$
    *Compiler Note:* Ensure $I_i$ matches the loop increment logic exactly.

2.  **Virtual Address (VA) Range:**
    The Nucleus computes the memory range to identify which cache misses belong to which stream.

    * **Direct Stream ($i$):**
        The Start VA ($start\_VA_i$) and End VA ($end\_VA_i$) are calculated using Base VA ($base\_VA_i$), Stride ($stride_i$), and the associated loop's Start ($S_{Loop\_ID[i]}$) and End ($E_{Loop\_ID[i]}$) values:
        $$start\_VA_i = base\_VA_i + S_{Loop\_ID[i]} * stride_i \quad (1)$$
        $$end\_VA_i = base\_VA_i + E_{Loop\_ID[i]} * stride_i \quad (2)$$

    * **Indirect Stream ($i$):**
        Since accesses can be random, the range is defined by the stream size ($size_i$):
        $$start\_VA_i = base\_VA_i \quad (3)$$
        $$end\_VA_i = base\_VA_i + size_i \quad (4)$$

### 5.2 Flow of Execution (How the HW uses your CSRs)

1.  **Unique Identification:** Computing base and end VAs helps in identifying unique streams even if the same page frame contains multiple streams.
2.  **Storage:** This information is stored in the **Desc Table** (Figure 10 in paper), indexed by Descriptor ID (Did), Core ID (Cid), Thread ID (Tid), and Descriptor Type (DType).
3.  **LLC Request Filter:** At runtime, the hardware checks whether an LLC request matches a stream in the Desc Table.
4.  **Appender:** If the demand miss belongs to one of the streams, the **LLC Request Appender** appends the demand miss packet with extra information (Stream ID, Loop ID) to be used in the Memory Controller.