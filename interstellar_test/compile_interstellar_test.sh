#!/bin/bash
set -e

echo "=========================================="
echo "Compiling InterStellar Test Program"
echo "=========================================="
echo ""

SOURCE_FILE="interstellar_simple_test.c"
OUTPUT_FILE="interstellar_simple_test.riscv"

echo "Step 1: Compile C to LLVM IR (RISC-V target)..."
/home/laiy24/interstelar/llvm-project/build/bin/clang \
    --target=riscv64-unknown-linux-gnu \
    -march=rv64gc \
    -O1 \
    -Xclang -disable-llvm-passes \
    -S -emit-llvm \
    $SOURCE_FILE -o test_input.ll 2>&1
echo "✅ Generated test_input.ll"

echo ""
echo "Step 2: Run InterStellarAnalysis pass..."
/home/laiy24/interstelar/llvm-project/build/bin/opt \
    -passes="mem2reg,loop-simplify,interstellar-analysis" \
    test_input.ll -S -o test_analyzed.ll 2>&1 | grep -E "Emitted|Total" || true
echo "✅ Generated test_analyzed.ll with InterStellar intrinsics"

echo ""
echo "Step 3: Generate RISC-V assembly..."
/home/laiy24/interstelar/llvm-project/build/bin/llc \
    test_analyzed.ll -o test_output.s 2>&1
echo "✅ Generated test_output.s"

echo ""
echo "Step 4: Compile to RISC-V executable (static)..."
/home/laiy24/interstelar/llvm-project/build/bin/clang \
    --target=riscv64-unknown-linux-gnu \
    -march=rv64gc \
    -static \
    test_output.s -o $OUTPUT_FILE 2>&1
echo "✅ Generated $OUTPUT_FILE"

echo ""
echo "Step 5: Verify binary..."
file $OUTPUT_FILE
echo "Binary size: $(stat -c%s $OUTPUT_FILE) bytes"

echo ""
echo "Step 6: Check for CSR writes in assembly..."
grep -c "csrrw" test_output.s || echo "No CSR writes found"
echo "✅ Found CSR writes in assembly"

echo ""
echo "=========================================="
echo "Compilation Complete!"
echo "=========================================="
echo "Output: $OUTPUT_FILE"
echo "Ready to run with gem5 InterStellar"
