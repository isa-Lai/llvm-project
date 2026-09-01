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
