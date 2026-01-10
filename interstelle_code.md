# InterStellar Compiler Pass: Design Documentation

**Author:** Senior LLVM Compiler Developer  
**Date:** January 4, 2026  
**Target:** Junior Developers and Future Maintainers  

---

## Table of Contents

1. [Overview](#overview)
2. [Architecture Understanding](#architecture-understanding)
3. [LLVM Infrastructure Integration](#llvm-infrastructure-integration)
4. [Implementation Design](#implementation-design)
5. [Key Design Decisions](#key-design-decisions)
6. [Code Walkthrough](#code-walkthrough)
7. [Usage Guide](#usage-guide)
8. [Testing Strategy](#testing-strategy)
9. [Future Extensions](#future-extensions)

---

## 1. Overview

### What is InterStellar?

InterStellar is a hardware accelerator designed to optimize memory controller behavior by identifying and prefetching memory access patterns. The compiler's role is to analyze code and provide metadata (via RISC-V CSR registers) that tells the hardware:

1. **What patterns exist** (Direct streams: `A[i]`, Indirect streams: `A[B[i]]`)
2. **Loop contexts** (bounds, nesting structure)
3. **Dynamic runtime values** (pointers, loop bounds that aren't compile-time constants)

### Goal of This Pass

**Primary Objective:** Identify direct memory access streams in loops (e.g., `A[i]` where `i` increments by a constant stride).

**Deliverable:** Console output showing:
- Stream ID
- Loop ID  
- Base Address (and whether it's dynamic)
- Stride (in bytes)

---

## 2. Architecture Understanding

### Key Concepts from `interstelle.md`

#### 2.1 Direct Stream
A memory access with a **constant stride**.

**Example:**
```c
for (int i = 0; i < N; i++) {
    A[i] = B[i] + 1;  // Two direct streams: A and B
}
```

**Mathematical Model:**  
`Address = Base + i * Stride`

Where:
- **Base:** Starting address (could be static or dynamic)
- **Stride:** Constant increment (e.g., 4 bytes for `int`)
- **i:** Loop induction variable

#### 2.2 Link Variables (Dynamic Values)

Sometimes values aren't known at compile time:
- Base address from function argument: `void foo(int *A)`
- Loop bound from variable: `for (i = 0; i < N; i++)`

**Solution:** Create a "Link Descriptor" that tells hardware: *"The value you need is in Physical Register X"*.

**Flags:**
- `BL` (Base Linked): Base address is dynamic
- `SL` (Start Linked): Loop start is dynamic
- `EL` (End Linked): Loop end is dynamic

#### 2.3 Why This Matters

The hardware (InterStellar Nucleus) uses this metadata to:
1. **Identify cache misses** that belong to known streams
2. **Prefetch ahead** for direct streams
3. **Optimize memory controller scheduling** for indirect streams

---

## 3. LLVM Infrastructure Integration

### 3.1 Why Function Pass?

We chose a **Function Pass** (not a Loop Pass) for several reasons:

1. **Flexibility:** Need to analyze all loops in a function together
2. **Cross-loop dependencies:** Future indirect stream analysis may need to correlate loads across different loops
3. **Standard LLVM pattern:** Most analysis passes operate at function granularity

### 3.2 Required Analyses

Our pass depends on three core LLVM analyses:

#### LoopInfo
- **Purpose:** Provides the loop tree structure
- **Usage:** Iterate through loops, check nesting (via `getParentLoop()`)
- **Why needed:** We need to know which loops exist and their hierarchy

#### ScalarEvolution (SE)
- **Purpose:** Analyzes how values evolve across loop iterations
- **Usage:** Detect affine recurrences (`Base + i * Stride`)
- **Why needed:** The *heart* of stream detection

#### DominatorTree
- **Purpose:** Control flow dominance relationships
- **Usage:** Helps SE with value analysis
- **Why needed:** Required dependency for ScalarEvolution

### 3.3 Pass Registration

To make our pass visible to LLVM, we register it in multiple places:

1. **CMakeLists.txt:** Build system must compile our `.cpp` file
2. **PassRegistry.def:** Registers pass name `"interstellar-analysis"`
3. **PassBuilder.cpp:** Include header for new pass manager
4. **Scalar.h:** Export factory function for legacy pass manager
5. **Scalar.cpp:** Initialize legacy pass in pass registry

---

## 4. Implementation Design

### 4.1 Class Hierarchy

```
InterStellarAnalysisPass (New PM)
    ├─ run(Function&, FunctionAnalysisManager&)
    └─ Creates InterStellarStreamAnalyzer

InterStellarAnalysisLegacyPass (Old PM)
    ├─ runOnFunction(Function&)
    └─ Creates InterStellarStreamAnalyzer

InterStellarStreamAnalyzer (Core Logic)
    ├─ analyze()
    ├─ analyzeLoop(Loop*)
    ├─ analyzeMemoryAccess(Instruction*, Loop*)
    └─ tryAnalyzeDirectStream(Value*, Instruction*, Loop*)
```

**Design Pattern:** Separation of concerns
- **Pass classes:** Handle LLVM pass infrastructure
- **Analyzer class:** Contains actual analysis logic (reusable)

### 4.2 Data Structures

#### DirectStreamDescriptor
```cpp
struct DirectStreamDescriptor {
    unsigned StreamID;           // Unique identifier
    unsigned LoopID;             // Which loop drives this stream
    const SCEV *BaseAddress;     // SCEV expression for base
    Value *BaseAddressValue;     // IR Value if dynamic
    bool IsBaseLinked;           // Dynamic base flag
    int64_t Stride;              // Constant stride in bytes
    Instruction *MemInst;        // Source load/store
};
```

**Why these fields?**
- `StreamID`: Hardware needs unique IDs
- `LoopID`: Associate stream with loop context
- `BaseAddress` (SCEV): Full compile-time expression
- `BaseAddressValue`: The runtime variable (e.g., function arg)
- `IsBaseLinked`: Tells hardware to use Link Descriptor
- `Stride`: Hardware needs this for prefetch distance
- `MemInst`: Debugging and future IR instrumentation

#### LoopDescriptor
```cpp
struct LoopDescriptor {
    unsigned LoopID;
    unsigned ParentLoopID;       // Nesting
    const SCEV *StartValue;
    const SCEV *EndValue;
    const SCEV *StepValue;
    bool IsStartLinked;          // Dynamic start
    bool IsEndLinked;            // Dynamic end
    Value *StartValueDynamic;
    Value *EndValueDynamic;
    Loop *L;
};
```

#### LinkVariableDescriptor
```cpp
struct LinkVariableDescriptor {
    unsigned LinkID;
    Value *DynamicValue;         // The IR Value
    unsigned SizeInBytes;        // Size of the value
};
```

---

## 5. Key Design Decisions

### 5.1 Why Innermost-First Loop Traversal?

**Decision:** Process loops in **post-order** (innermost first).

**Rationale:**
```c
for (i = 0; i < N; i++) {           // Outer loop
    for (j = 0; j < M; j++) {       // Inner loop
        A[j] = B[j];                // Stream driven by j (inner)
    }
}
```

If we analyze outer loop first, we might incorrectly associate the `A[j]` stream with loop `i` instead of loop `j`. Post-order ensures precision.

**Implementation:**
```cpp
for (Loop *L : LI) {
    for (Loop *SubL : depth_first(L)) {
        Worklist.push_back(SubL);
    }
}
```

### 5.2 SCEV-Based Detection Strategy

**Decision:** Use `ScalarEvolution::getSCEV()` on pointer operands.

**Why SCEV?**

LLVM's ScalarEvolution is the gold standard for analyzing induction variables. It automatically:
- Recognizes canonical induction patterns
- Handles pointer arithmetic
- Normalizes different coding styles to the same SCEV

**Example:**
```c
// Style 1
for (i = 0; i < N; i++)
    A[i] = 0;

// Style 2
int *p = A;
for (i = 0; i < N; i++, p++)
    *p = 0;
```

Both produce the **same SCEV**: `{A,+,4}` (base A, stride 4 bytes).

### 5.3 Dynamic Value Detection

**Problem:** How do we know if a base address is compile-time constant vs. runtime variable?

**Solution:** Check SCEV type hierarchy.

```cpp
bool isValueDynamic(const SCEV *S) {
    if (isa<SCEVConstant>(S))
        return false;  // It's a constant (e.g., global variable address)
    
    if (isa<SCEVUnknown>(S))
        return true;   // Unknown = value SCEV can't reduce (likely runtime)
    
    // Recursively check composite expressions
}
```

**Key Insight:** `SCEVUnknown` represents values that ScalarEvolution couldn't analyze further. These are typically:
- Function arguments
- Load results
- Values from other functions

### 5.4 Stride Requirement: Must Be Constant

**Decision:** Reject streams with non-constant strides.

**Rationale:**
- Hardware prefetcher needs predictable patterns
- Non-constant stride = complex access (handle in future with indirect streams)

**Example of rejected case:**
```c
for (i = 0; i < N; i++)
    A[i * rand()] = 0;  // Stride depends on rand() - not constant
```

### 5.5 Why Separate Analyzer Class?

**Decision:** Core logic in `InterStellarStreamAnalyzer`, not in pass classes.

**Benefits:**
1. **Testability:** Can unit test analyzer without pass infrastructure
2. **Reusability:** Same analyzer works for both new and legacy PM
3. **Maintainability:** Clear separation of concerns
4. **Future-proofing:** Easy to add new analysis methods without touching pass boilerplate

---

## 6. Code Walkthrough

### 6.1 Entry Point: `analyze()`

```cpp
bool InterStellarStreamAnalyzer::analyze() {
    // Collect loops in post-order
    SmallVector<Loop *, 8> Worklist;
    for (Loop *L : LI) {
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
```

**Flow:**
1. Build worklist of all loops (innermost first via depth-first)
2. Analyze each loop
3. Return true if we found any streams

### 6.2 Loop Analysis: `analyzeLoop()`

```cpp
void InterStellarStreamAnalyzer::analyzeLoop(Loop *L) {
    // Create loop descriptor
    unsigned LoopID = getOrCreateLoopID(L);
    
    // Extract loop bounds using SCEV
    if (PHINode *IndVar = L->getCanonicalInductionVariable()) {
        const SCEV *BackedgeTakenCount = SE.getBackedgeTakenCount(L);
        // ... store bounds in LoopDescriptor
    }
    
    // Analyze all memory instructions in loop
    for (BasicBlock *BB : L->blocks()) {
        for (Instruction &I : *BB) {
            if (isa<LoadInst>(&I) || isa<StoreInst>(&I)) {
                analyzeMemoryAccess(&I, L);
            }
        }
    }
}
```

**Key Steps:**
1. Assign unique Loop ID
2. Try to extract loop bounds from canonical induction variable
3. Iterate all basic blocks in loop
4. Find all load/store instructions
5. Analyze each memory access

### 6.3 Direct Stream Detection: `tryAnalyzeDirectStream()`

This is the **core algorithm**:

```cpp
bool tryAnalyzeDirectStream(Value *Ptr, Instruction *MemInst, Loop *L) {
    // Step 1: Get SCEV for the pointer
    const SCEV *PtrSCEV = SE.getSCEV(Ptr);
    
    // Step 2: Check if it's an AddRecExpr
    const SCEVAddRecExpr *AR = dyn_cast<SCEVAddRecExpr>(PtrSCEV);
    if (!AR) return false;
    
    // Step 3: Verify it belongs to this loop
    if (AR->getLoop() != L) return false;
    
    // Step 4: Check if it's affine (Base + Stride * i)
    if (!AR->isAffine()) return false;
    
    // Step 5: Extract base and stride
    const SCEV *Base = AR->getStart();
    const SCEV *Step = AR->getStepRecurrence(SE);
    
    // Step 6: Stride MUST be constant
    const SCEVConstant *StepConst = dyn_cast<SCEVConstant>(Step);
    if (!StepConst) return false;
    
    // Step 7: Create descriptor
    DirectStreamDescriptor DS;
    DS.StreamID = NextStreamID++;
    DS.LoopID = getOrCreateLoopID(L);
    DS.BaseAddress = Base;
    DS.Stride = StepConst->getAPInt().getSExtValue();
    DS.MemInst = MemInst;
    
    // Step 8: Check if base is dynamic
    DS.IsBaseLinked = isValueDynamic(Base);
    if (DS.IsBaseLinked) {
        DS.BaseAddressValue = extractDynamicValue(Base);
        getOrCreateLinkID(DS.BaseAddressValue, ...);
    }
    
    DirectStreams.push_back(DS);
    return true;
}
```

**Detailed Explanation:**

**Step 1:** Ask ScalarEvolution to analyze the pointer's evolution across iterations.

**Step 2:** Check if it's a `SCEVAddRecExpr`. This SCEV node type represents *Add Recurrence*, which models: `{Start, +, Step}` = `Start + i * Step`.

**Step 3:** Ensure the AddRec is for *this* loop, not an outer/inner loop.

**Step 4:** `isAffine()` checks if it's linear (degree 1 polynomial). Non-affine would be `i^2`, `i^3`, etc.

**Step 5:** 
- `getStart()`: Returns the initial value (our base address)
- `getStepRecurrence()`: Returns how much it changes per iteration (our stride)

**Step 6:** We require constant stride. Hardware can't prefetch variable strides.

**Step 7-8:** Create descriptor and check if base is dynamic (function argument, etc.).

### 6.4 Dynamic Value Detection

```cpp
bool isValueDynamic(const SCEV *S) {
    // Constants are not dynamic
    if (isa<SCEVConstant>(S))
        return false;
    
    // Unknown values are dynamic
    if (isa<SCEVUnknown>(S))
        return true;
    
    // Check operands recursively
    if (const SCEVNAryExpr *NAry = dyn_cast<SCEVNAryExpr>(S)) {
        for (const SCEV *Op : NAry->operands()) {
            if (isValueDynamic(Op))
                return true;
        }
    }
    
    return false;
}
```

**Why recursive?**

SCEV expressions can be composite:
- `{(%arg + 8), +, 4}`: Base is `%arg + 8` (contains unknown `%arg`)
- Need to recursively check all operands

```cpp
Value *extractDynamicValue(const SCEV *S) {
    if (const SCEVUnknown *Unknown = dyn_cast<SCEVUnknown>(S)) {
        return Unknown->getValue();  // Get the IR Value
    }
    
    // Recursively search composite expressions
    if (const SCEVAddExpr *Add = dyn_cast<SCEVAddExpr>(S)) {
        for (const SCEV *Op : Add->operands()) {
            if (Value *V = extractDynamicValue(Op))
                return V;
        }
    }
    
    return nullptr;
}
```

**Purpose:** Extract the actual `Value*` from SCEV so we can:
1. Create a Link Descriptor pointing to this value
2. Future: Generate intrinsic calls to pass value to hardware

---

## 7. Usage Guide

### 7.1 Building LLVM with InterStellar Pass

```bash
# From llvm-project root
cd build
cmake -G Ninja ../llvm -DCMAKE_BUILD_TYPE=Release \
    -DLLVM_ENABLE_PROJECTS="clang" \
    -DLLVM_TARGETS_TO_BUILD="RISCV;X86"
ninja
```

### 7.2 Running the Pass

#### Option 1: New Pass Manager (Recommended)
```bash
# Compile to IR
clang -O0 -S -emit-llvm test.c -o test.ll

# Run our pass
opt -passes="interstellar-analysis" test.ll -o /dev/null
```

#### Option 2: Legacy Pass Manager
```bash
opt -interstellar-analysis test.ll -o /dev/null
```

#### Option 3: Enable Debug Output
```bash
opt -passes="interstellar-analysis" test.ll -o /dev/null \
    -debug-only=interstellar-analysis
```

### 7.3 Example Test Case

**test.c:**
```c
void simple_loop(int *A, int N) {
    for (int i = 0; i < N; i++) {
        A[i] = i;
    }
}
```

**Expected Output:**
```
InterStellar Stream Analysis Results:
=====================================

Statistics:
  Loops analyzed: 1
  Direct streams: 1
  Link variables: 1

Loop Descriptors:
-----------------
Loop ID: 0
  Parent Loop ID: 0
  End: %N (Linked)

Direct Streams:
---------------
Stream ID: 0
  Loop ID: 0
  Base: %A (Linked: %A)
  Stride: 4 bytes
  Instruction: store i32 %i, ptr %arrayidx
```

**Interpretation:**
- Found 1 direct stream (the `A[i]` access)
- Base address `%A` is dynamic (function argument)
- Stride is 4 bytes (`sizeof(int)`)
- Loop end bound `%N` is also dynamic

### 7.4 Testing with opt Pipeline

```bash
# Run with full optimization pipeline
opt -passes="loop-simplify,scalar-evolution,interstellar-analysis" \
    test.ll -o /dev/null

# Dump SCEV info alongside our analysis
opt -passes="print<scalar-evolution>,interstellar-analysis" \
    test.ll -disable-output
```

---

## 8. Testing Strategy

### 8.1 Unit Test Cases

Create these test files in `llvm/test/Transforms/InterStellar/`:

#### Test 1: Simple Direct Stream
```c
// simple-stream.c
void foo(int *A, int N) {
    for (int i = 0; i < N; i++)
        A[i] = 0;
}
// CHECK: Direct Stream found
// CHECK: Stride: 4
```

#### Test 2: Multiple Streams
```c
// multi-stream.c
void bar(int *A, int *B, int N) {
    for (int i = 0; i < N; i++)
        A[i] = B[i];
}
// CHECK: Direct streams: 2
```

#### Test 3: Nested Loops
```c
// nested.c
void nested(int *A, int N, int M) {
    for (int i = 0; i < N; i++)
        for (int j = 0; j < M; j++)
            A[i * M + j] = 0;
}
// CHECK: Loop ID: 0
// CHECK: Parent Loop ID: 0
// CHECK: Loop ID: 1
// CHECK: Parent Loop ID: 0
```

#### Test 4: Non-constant Stride (Should Reject)
```c
// variable-stride.c
void bad(int *A, int stride, int N) {
    for (int i = 0; i < N; i++)
        A[i * stride] = 0;
}
// CHECK-NOT: Direct Stream found
```

#### Test 5: Static Array (No Link)
```c
// static-array.c
int global[1000];
void static_base(int N) {
    for (int i = 0; i < N; i++)
        global[i] = 0;
}
// CHECK: Base Linked: No
```

### 8.2 FileCheck Tests

Create `.ll` test files with FileCheck directives:

```llvm
; RUN: opt -passes=interstellar-analysis -S < %s 2>&1 | FileCheck %s

define void @test(ptr %A, i32 %N) {
entry:
  br label %loop

loop:
  %i = phi i32 [ 0, %entry ], [ %i.next, %loop ]
  %gep = getelementptr i32, ptr %A, i32 %i
  store i32 %i, ptr %gep
  %i.next = add i32 %i, 1
  %cmp = icmp slt i32 %i.next, %N
  br i1 %cmp, label %loop, label %exit

exit:
  ret void
}

; CHECK: Direct Stream found
; CHECK: Stream ID: 0
; CHECK: Stride: 4
; CHECK: Base Linked: Yes
```

### 8.3 Regression Tests

Add to existing loop analysis tests:
- `llvm/test/Analysis/ScalarEvolution/` (verify we don't break SCEV)
- `llvm/test/Transforms/LoopSimplify/` (ensure compatibility)

---

## 9. Future Extensions

### 9.1 Indirect Stream Analysis (Phase 2)

**Goal:** Detect `A[B[i]]` patterns.

**Strategy:**
```cpp
bool tryAnalyzeIndirectStream(Value *Ptr, Instruction *MemInst, Loop *L) {
    // Check if index comes from a load
    if (GetElementPtrInst *GEP = dyn_cast<GetElementPtrInst>(Ptr)) {
        Value *Index = GEP->getOperand(1);
        if (LoadInst *IndexLoad = dyn_cast<LoadInst>(Index)) {
            // Check if IndexLoad is a known stream
            if (InstToStreamIDMap.count(IndexLoad)) {
                unsigned SourceStreamID = InstToStreamIDMap[IndexLoad];
                // Create indirect stream descriptor
            }
        }
    }
}
```

### 9.2 IR Instrumentation (Phase 3)

**Goal:** Insert intrinsic calls to configure hardware at runtime.

**Example:**
```llvm
; Before loop
call void @llvm.riscv.interstellar.link_config(i32 %LinkID, ptr %A, i32 8)
call void @llvm.riscv.interstellar.direct_config(i32 %StreamID, i32 %LoopID, 
                                                  i32 %LinkID, i32 4, i32 %BL_flag)

; Loop body
for.body:
  ; ... original code ...
```

**Implementation Location:**
- New file: `InterStellarInstrumentation.cpp`
- Depends on: `InterStellarAnalysis` (use analysis results)
- Insert calls in: Loop preheader (before loop starts)

### 9.3 Backend CSR Lowering (Phase 4)

**Goal:** Lower intrinsics to RISC-V CSR writes.

**Files to modify:**
- `llvm/lib/Target/RISCV/RISCVInstrInfo.td`: Define pseudo-instructions
- `llvm/lib/Target/RISCV/RISCVISelLowering.cpp`: Lower intrinsics
- `llvm/lib/Target/RISCV/RISCVExpandPseudoInsts.cpp`: Expand to CSR instructions

**Example:**
```asm
# Lower to actual CSR writes
li t0, <LinkID>
csrw csr_link_id, t0
mv t1, a0              # Move pointer value
csrw csr_link_value, t1
```

### 9.4 Triangular Loop Support

**Challenge:** Loop bound depends on outer loop variable.

```c
for (int i = 0; i < N; i++)
    for (int j = 0; j < i; j++)  // j's bound is i (dynamic)
        A[j] = 0;
```

**Solution:** Already designed for in `LoopDescriptor`:
- Set `IsEndLinked = true`
- `EndValueDynamic = %i`
- Create Link Descriptor for `%i`

### 9.5 Multi-threaded/SIMD Analysis

**Goal:** Detect shared streams across threads.

**Example:**
```c
#pragma omp parallel for
for (int i = 0; i < N; i++)
    A[i] = 0;  // Shared stream
```

**Implementation:**
- Check for OpenMP/SIMD attributes
- Set `Shared` flag in descriptor
- Hardware uses this for coherence decisions

---

## 10. Debugging Tips

### 10.1 Enable LLVM Debug Output

```bash
# See what SCEV computed
opt -passes=interstellar-analysis test.ll -debug-only=scalar-evolution

# See our pass's debug output
opt -passes=interstellar-analysis test.ll -debug-only=interstellar-analysis

# See both
opt -passes=interstellar-analysis test.ll \
    -debug-only=scalar-evolution,interstellar-analysis
```

### 10.2 Visualize SCEV

```bash
# Dump SCEV expressions
opt -passes=print-scev test.ll -disable-output

# See loop info
opt -passes=print-loops test.ll -disable-output
```

### 10.3 Check IR Structure

```bash
# Ensure loops are in canonical form
opt -passes=loop-simplify test.ll -S -o test.simplified.ll

# View CFG
opt -passes=dot-cfg test.ll -disable-output
dot -Tpng .test.dot -o cfg.png
```

### 10.4 Common Issues

**Problem:** "Not an AddRec"  
**Solution:** Loop might not be in canonical form. Run `loop-simplify` first.

**Problem:** "Non-constant stride"  
**Solution:** Stride calculation involves runtime values. Check if you can hoist invariant computations.

**Problem:** No streams detected  
**Solution:** Check if memory operations are in the loop. Use `-debug-only=interstellar-analysis` to see what's being analyzed.

---

## 11. Key Takeaways for Junior Developers

### 11.1 LLVM Best Practices We Followed

1. **Use existing analyses:** Don't reinvent ScalarEvolution
2. **Separation of concerns:** Pass boilerplate vs. analysis logic
3. **Support both PMs:** New and legacy pass managers
4. **Debug output:** Use `LLVM_DEBUG` and `dbgs()`
5. **Statistics:** Use `STATISTIC` macro for metrics
6. **Type safety:** Use `dyn_cast` instead of C-style casts

### 11.2 Understanding SCEV

**Mental Model:**
- SCEV is a *symbolic* representation of how values change
- Think of it as "compile-time simulation" of loop iterations
- Key types:
  - `SCEVConstant`: Compile-time constant
  - `SCEVUnknown`: Value we can't analyze further (often runtime)
  - `SCEVAddRecExpr`: The magic type for loops (`{start, +, step}`)

**Example Mapping:**
```c
int *p = A;
for (i = 0; i < 10; i++)
    p++;

// SCEV of p: {%A, +, 4}
//            (start at A, step by 4 bytes per iteration)
```

### 11.3 Debugging Workflow

1. **Write simple test case** (3-5 lines of C)
2. **Compile to IR:** `clang -O0 -S -emit-llvm test.c`
3. **Run pass:** `opt -passes=interstellar-analysis test.ll`
4. **Enable debug:** Add `-debug-only=interstellar-analysis`
5. **Check SCEV:** Add `-debug-only=scalar-evolution`
6. **Iterate:** Adjust code, repeat

### 11.4 Code Review Checklist

Before submitting changes:
- [ ] Code compiles without warnings
- [ ] All existing tests pass
- [ ] Added test case for new feature
- [ ] Debug output is helpful
- [ ] Comments explain *why*, not just *what*
- [ ] Handled edge cases (null pointers, empty loops)

---

## 12. References

### LLVM Documentation
- [Writing an LLVM Pass](https://llvm.org/docs/WritingAnLLVMPass.html)
- [Scalar Evolution](https://llvm.org/docs/ScalarEvolution.html)
- [Loop Terminology](https://llvm.org/docs/LoopTerminology.html)
- [Pass Manager](https://llvm.org/docs/NewPassManager.html)

### Our Codebase
- `interstelle.md`: Architecture specification
- `llvm/include/llvm/Transforms/Scalar/InterStellarAnalysis.h`: Public interface
- `llvm/lib/Transforms/Scalar/InterStellarAnalysis.cpp`: Implementation

### Similar Passes to Study
- `LoopDataPrefetch.cpp`: Similar goal (prefetching)
- `LoopAccessAnalysis.cpp`: Advanced SCEV usage
- `LoopDistribute.cpp`: Complex loop transformations

---

## Conclusion

This implementation provides a **solid foundation** for InterStellar compiler support:

✅ **Achieved:**
- Direct stream detection working
- Dynamic base address handling (Link Variables)
- Loop context extraction
- Clean, maintainable code structure

🔄 **Next Steps:**
- Indirect stream analysis (Phase 2)
- IR instrumentation with intrinsics (Phase 3)
- RISC-V backend lowering (Phase 4)

**Remember:** This is a **research project**. Iterate, experiment, and improve based on hardware feedback!

---

**Questions?** Contact the LLVM team or refer to the LLVM Discord/Discourse.

**Last Updated:** January 4, 2026
