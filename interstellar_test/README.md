# InterStellar Test Suite

## Test Files

### Pattern 0: Simple Test (pattern0_simple.c)
**Description:** Single loop with two arrays
```c
void test(int *A, int *B, int N) {
  for (int i = 0; i < N; i++) {
    A[i] = B[i] * 2;
  }
}
```
**Expected Descriptors:** 6 total (3 links, 1 loop, 2 direct streams)

### Pattern 1: Direct Streams (pattern1_direct_streams.c)
**Description:** Multiple direct stream patterns
- `A[i]` - unit stride
- `A[i+2]` - offset access
- `A[i*2]` - stride-2 access
- `A[i*3+3]` - stride-3 with offset
- Global array access

**Expected Descriptors:** 15 unique (5 links, 4 loops, 9 direct streams, 1 indirect)

**Note:** This is a nostdio version that doesn't require RISC-V libc headers. Original version backed up as `pattern1_direct_streams_original.c.bak`.

### Pattern D: Stream Base-Address Resolvability (patternD_base_resolvability.c)
**Description:** Reduced unit test for the study-binary failure where pass-emitted
descriptors carried stub bases and no LLC miss ever matched. Three cases:
- `direct_static` — static global accessed directly → base emitted via `%hi/%lo(G)` (WORKS)
- `direct_malloc` — malloc'd base → constant stub base 0x206000, pointer never fed to a csrw
- `direct_param` — pointer parameter (atax/bicg shape) → same stub, param never fed to a csrw

Run: `./test_backend.sh D`. Oracle is in the .s/.o (relocation feeding the csrw in case 1,
constant stubs in cases 2-3) and end-to-end in gem5 (case 1 matches, cases 2-3 never).

### Pattern E: Outer-Variant (Row-Walking) Stream Bases (patternE_outer_variant_base.c)
**Description:** Reduced unit test for the atax `A[i][j]` gap: the inner loop's base
`A + i*N*8` varies with the outer induction variable, so a single entry-time bind
cannot cover the matrix. Four cases:
- `rows_static` — 2D static global → flat constant-base stream (base `@G2`, stride 8,
  merged loop M×N) — **works today**, matches the manual's linearized descriptor
- `rows_param` — 2D pointer parameter → pass linearizes (merged loop `64*n` via a
  bound link) but ships the base **BL=0 symbolic**; the backend lowers it to the
  base register's *number* (x11 → `0xB`), which the engine reads as an address → inert
- `rows_malloc` — `double **A` → base is a loop-variant row-pointer **load**; the IR
  generator skips loop-variant links (entry-only emission) → **0 descriptors emitted**
- `rows_flat_malloc` — flat `A[i*N+j]` form (commented out; see 2026-09-16 session notes)

**Hardware contract (gem5 link-base-resolution):** a Link's register is re-snapshotted
at *every* execution of its L-word instruction, and every BL=1 stream insert re-binds
BASEVA to the latest snapshot. A **loop-variant link is therefore a valid descriptor**
provided the link instruction executes where the register holds the current base.
Placing the link+stream pair inside the outer loop gives: base = A[i] re-bound per
row, stride 8, N iterations — the hardware walks each row. Cost: 4 serialized csrw
per outer iteration. The manual's alternative is flat linearization (base = A,
span M×N, one-time).

Run: `./test_backend.sh E` (asm oracle) and `sh test_summary.sh E` (pass decision
log). Oracle: `rows_param` must ship BL=1 link delivery (flat M×N or per-row),
`rows_malloc` must emit the per-row link+stream pair; end-to-end in gem5 shows
INSERT lines with advancing BaseVA and per-row matches.

## Running Tests

```bash
# Test pattern 0 (simple)
./test_backend.sh 0

# Test pattern 1 (complex)
./test_backend.sh 1
```

## Test Pipeline

Each test runs through:
1. **C → IR**: Compile with clang for RISC-V target
2. **InterStellarAnalysis**: Generate configuration intrinsics
3. **Verification**: Python script validates descriptors
4. **Descriptor Parsing**: Parse and display all descriptor details from IR
5. **Assembly Generation**: llc produces RISC-V assembly
6. **Object File**: Assemble to ELF64 RISC-V relocatable object
7. **Verification**: Check object file structure with llvm-readelf/objdump

## Expected Output

```
==========================================
InterStellar Backend Pipeline Test
==========================================

Step 1: Compile C to LLVM IR (RISC-V target)...
✅ Generated test_backend_input.ll

Step 2: Run Phase 1 (InterStellarAnalysis)...
✅ Generated test_backend_phase1.ll with intrinsics

Step 3: Verify InterStellar intrinsics in IR...
✅ Total: N InterStellar configuration intrinsics

Step 4: Run Python verification script...
✅ Found M descriptors (within 32 CSR limit)
✅ All GlobalIDs valid
✅ All references verified

Step 5: Parse and display all descriptors...
============================================================
INTERSTELLAR DESCRIPTOR ANALYSIS
============================================================
Total Descriptors: M
  - Link:           X
  - Loop:           Y
  - Direct Stream:  Z
  - Indirect Stream: W

[Detailed descriptor information for each descriptor...]

Step 6: Generate RISC-V assembly...
✅ Generated test_backend.s

Step 7: Assemble to object file...
✅ Generated test_backend.o

Step 8: Verify object file structure...
[ELF file information and disassembly]

Backend Test: COMPLETE ✅
```

## Known Issues

1. **Duplicate GlobalIDs**: When multiple functions are analyzed, GlobalIDs may be reused across functions. This is expected behavior - GlobalIDs are function-local.

2. **CSR Writes Not Generated**: Phase 3 (CSR write generation) is not yet implemented. Intrinsics are currently removed before codegen. See TODO in output.

3. **Stream bases must be static globals at the annotation point**: the pass emits
   a real base only for static globals accessed directly in the annotated
   function. Malloc'd pointers and pointer-parameter bases get a constant stub
   (0x206000) and the engine can never match those streams — see Pattern D. This
   is why all 8 study auto-binaries were stream-inert (2026-09-13).

## File Naming

- **Wildcard Matching**: Test script uses `pattern<N>_*.c` to find pattern files
- **Multiple Matches**: If multiple files match (e.g., `pattern1_direct_streams.c` and `pattern1_nostdio_direct_streams.c`), the script selects the first alphabetically and warns you
- **Best Practice**: Use descriptive names like `pattern1_direct_streams.c` (default working version) and `pattern1_direct_streams_original.c.bak` (backup with stdio.h)

## Verification Scripts

### verify_descriptors.py
Validates descriptor correctness:
- ✅ GlobalID uniqueness within range [0, 31]
- ✅ Total descriptor count ≤ 32 (hardware limit)
- ✅ Reference integrity (parent loops, link IDs)
- ✅ Valid descriptor types
- ✅ Proper descriptor structure

### parse_descriptors.py
Parses and displays all descriptor details from LLVM IR:
- **Summary**: Total count and breakdown by type (Link, Loop, Direct Stream, Indirect Stream)
- **Detailed Info**: All fields for each descriptor including GlobalID, ParentLoopID, Stride, etc.
- **GlobalID Map**: Shows which CSRs are used and how many remain available
- **Relationship Graph**: Displays loop → stream hierarchy

Example output:
```
DESCRIPTOR ANALYSIS
Total Descriptors: 6
  - Link:           3
  - Loop:           1
  - Direct Stream:  2

Descriptor #1:
  Type: LINK
  GlobalID: 1
  ElementSize: 8 bytes
...
```

## Adding New Test Patterns

1. Create `pattern<N>_<description>.c` file
2. Avoid including system headers (use `-nostdinc` compatible code)
3. Run `./test_backend.sh <N>` to test
4. Check verification output for descriptor details

## Output Files

Each test generates:
- `test_backend_input.ll` - Original IR from Clang
- `test_backend_phase1.ll` - After InterStellarAnalysis (with intrinsics)
- `test_backend.s` - RISC-V assembly
- `test_backend.o` - RISC-V ELF object file
