#!/bin/bash
set -e

# If invoked with `sh test_backend.sh ...`, restart under bash.
if [ -z "${BASH_VERSION:-}" ]; then
    exec bash "$0" "$@"
fi

echo "=========================================="
echo "InterStellar Backend Pipeline Test"
echo "=========================================="
echo ""

if [ -z "$1" ]; then
    echo "Usage: $0 <pattern_number>"
    echo "Example: $0 1    # Test pattern 1"
    echo "         $0 B    # Test pattern B"
    exit 1
fi

PATTERN_NUM=$1
PATTERN_GLOB="pattern${PATTERN_NUM}_*.c"

# Find matching files and select the first one
PATTERN_FILE=$(ls $PATTERN_GLOB 2>/dev/null | head -1)

# Check if pattern file exists
if [ -z "$PATTERN_FILE" ]; then
    echo "❌ Error: No pattern file matching $PATTERN_GLOB found"
    exit 1
fi

# Count matching files and warn if multiple
FILE_COUNT=$(ls $PATTERN_GLOB 2>/dev/null | wc -l)
if [ $FILE_COUNT -gt 1 ]; then
    echo "⚠️  Note: Found $FILE_COUNT files matching $PATTERN_GLOB"
    echo "          Using: $PATTERN_FILE"
    echo ""
fi

echo "Testing with: $PATTERN_FILE"
echo ""

echo "Step 1: Compile C to LLVM IR (RISC-V target)..."
../build/bin/clang --target=riscv64-unknown-linux-gnu -march=rv64gc -O1 -Xclang -disable-llvm-passes -S -emit-llvm $PATTERN_FILE -o test_backend_input.ll 2>&1
if [ $? -ne 0 ]; then
    echo "❌ Clang compilation failed"
    exit 1
fi
echo "✅ Generated test_backend_input.ll"

echo ""
echo "Step 2: Run Phase 1 (InterStellarAnalysis)..."
../build/bin/opt -passes="mem2reg,loop-simplify,interstellar-analysis" test_backend_input.ll -S -o test_backend_phase1.ll 2>&1 | grep -E "Emitted|Total" || true
if [ ${PIPESTATUS[0]} -ne 0 ]; then
    echo "❌ Phase 1 failed"
    exit 1
fi
echo "✅ Generated test_backend_phase1.ll with @llvm.interstellar.configure.* intrinsics"

echo ""
echo "Step 3: Verify InterStellar intrinsics in IR..."
LINK_COUNT=$(grep -c "@llvm.interstellar.configure.link" test_backend_phase1.ll || true)
LOOP_COUNT=$(grep -c "@llvm.interstellar.configure.loop" test_backend_phase1.ll || true)
STREAM_COUNT=$(grep -c "@llvm.interstellar.configure.directstream" test_backend_phase1.ll || true)
INDIRECT_COUNT=$(grep -c "@llvm.interstellar.configure.indirectstream" test_backend_phase1.ll || true)

echo "  Found $LINK_COUNT link intrinsics"
echo "  Found $LOOP_COUNT loop intrinsics"
echo "  Found $STREAM_COUNT direct stream intrinsics"
echo "  Found $INDIRECT_COUNT indirect stream intrinsics"

TOTAL_INTRINSICS=$((LINK_COUNT + LOOP_COUNT + STREAM_COUNT + INDIRECT_COUNT))
echo "✅ Total: $TOTAL_INTRINSICS InterStellar configuration intrinsics"

if [ $TOTAL_INTRINSICS -eq 0 ]; then
    echo "⚠️  Warning: No InterStellar intrinsics generated!"
fi

echo ""
echo "Step 4: Run Python verification script..."
python3 verify_descriptors.py test_backend_phase1.ll
VERIFY_EXIT=$?

echo ""
echo "Step 5: Parse and display all descriptors..."
python3 parse_descriptors.py test_backend_phase1.ll
if [ $? -ne 0 ]; then
    echo "❌ Descriptor parsing failed"
    exit 1
fi

echo ""
echo "Step 6: Generate RISC-V assembly..."
../build/bin/llc test_backend_phase1.ll -o test_backend.s 2>&1
if [ $? -ne 0 ]; then
    echo "❌ Assembly generation failed"
    exit 1
fi
echo "✅ Generated test_backend.s ($(wc -l < test_backend.s) lines)"

echo ""
echo "Step 7: Assemble to object file..."
# Extract the main function name from the C file
FUNC_NAME=$(grep -oP 'void\s+\K\w+(?=\s*\()' $PATTERN_FILE | head -1)
if [ -z "$FUNC_NAME" ]; then
    FUNC_NAME="kernel"
fi

# Create a simple wrapper for linking
cat > test_wrapper.c << EOF
extern void $FUNC_NAME();
int main() { return 0; }
EOF

../build/bin/clang --target=riscv64-unknown-linux-gnu -march=rv64gc -c test_backend.s -o test_backend.o 2>&1
if [ $? -ne 0 ]; then
    echo "❌ Assembly failed"
    exit 1
fi
echo "✅ Generated test_backend.o ($(stat -c%s test_backend.o) bytes)"

echo ""
echo "Step 8: Verify object file structure..."
file test_backend.o
echo ""
echo "Object file sections:"
../build/bin/llvm-readelf -S test_backend.o | grep -E "Name|\.text"
../build/bin/llvm-readelf -S test_backend.o > sections.txt

echo ""
echo "Disassemble compiled function (first 30 instructions):"
../build/bin/llvm-objdump -d test_backend.o | head -50
../build/bin/llvm-objdump -d test_backend.o > disassembly.txt

echo ""
echo "=========================================="
echo "Output Files Generated:"
echo "=========================================="
echo "  test_backend_input.ll   - Initial LLVM IR from Clang"
echo "  test_backend_phase1.ll  - After InterStellarAnalysis (with intrinsics)"
echo "  test_backend.s          - RISC-V assembly output"
echo "  test_backend.o          - RISC-V object file"

echo ""
echo "=========================================="
if [ $VERIFY_EXIT -eq 0 ] && [ $TOTAL_INTRINSICS -gt 0 ] && [ -f test_backend.o ]; then
    echo "Backend Test: COMPLETE ✅"
else
    echo "Backend Test: PARTIAL ⚠️"
fi

