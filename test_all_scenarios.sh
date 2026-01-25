#!/bin/bash
# Comprehensive test script for all loop scenarios

echo "=========================================="
echo "InterStellar Loop Scenarios Test"
echo "=========================================="
echo ""

# Compile to unoptimized LLVM IR
echo "Step 1: Compiling C to LLVM IR (unoptimized)..."
./build/bin/clang -O1 -Xclang -disable-llvm-passes -S -emit-llvm test_all_loop_scenarios.c -o test_opt.ll
if [ $? -ne 0 ]; then
    echo "ERROR: Compilation failed"
    exit 1
fi


echo ""
echo "=========================================="
./build/bin/opt -passes="mem2reg,loop-simplify,interstellar-analysis" test_opt.ll -S -o test_all_analyzed.ll -debug-only=interstellar-analysis 2>&1 | tee interstellar_all_debug.log
echo "Test Complete!"
echo "=========================================="
echo "Output files:"
echo "  - test_all_opt.ll (Optimized IR)"
echo "  - test_all_analyzed.ll (After analysis)"
echo "  - interstellar_all_debug.log (Debug output)"
