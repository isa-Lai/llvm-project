#!/bin/bash
set -e

echo "=========================================="
echo "Compiling InterStellar Test with Full Pipeline"
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
echo "Step 3: Count InterStellar intrinsics..."
INTRINSIC_COUNT=$(grep -c "llvm.interstellar" test_analyzed.ll || echo "0")
echo "✅ Found $INTRINSIC_COUNT InterStellar intrinsics"

echo ""
echo "Step 4: Generate RISC-V assembly with backend pass..."
/home/laiy24/interstelar/llvm-project/build/bin/llc \
    -march=riscv64 \
    -mattr=+m,+a,+f,+d \
    test_analyzed.ll -o test_final.s 2>&1
echo "✅ Generated test_final.s"

echo ""
echo "Step 5: Verify CSR writes in assembly..."
CSR_COUNT=$(grep -c "csrw" test_final.s || echo "0")
echo "✅ Found $CSR_COUNT CSR write instructions"

if [ $CSR_COUNT -gt 0 ]; then
    echo "Sample CSR writes:"
    grep "csrw" test_final.s | head -5
fi

echo ""
echo "Step 6: Compile to RISC-V executable (static)..."
/home/laiy24/interstelar/llvm-project/build/bin/clang \
    --target=riscv64-unknown-linux-gnu \
    -march=rv64gc \
    -static \
    test_final.s -o $OUTPUT_FILE 2>&1
echo "✅ Generated $OUTPUT_FILE"

echo ""
echo "Step 7: Verify binary..."
file $OUTPUT_FILE
echo "Binary size: $(stat -c%s $OUTPUT_FILE) bytes"

echo ""
echo "=========================================="
echo "✅ COMPLETE: InterStellar binary ready!"
echo "=========================================="
echo "Output: $OUTPUT_FILE"
echo "InterStellar CSR writes: $CSR_COUNT"
echo "Ready to run with gem5 InterStellar"
