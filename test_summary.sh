#!/bin/bash
echo "=========================================="
echo "InterStellar Direct Stream Analysis Test"
echo "=========================================="
echo ""
echo "Compiling test_interstellar.c..."
./build/bin/clang -O1 -Xclang -disable-llvm-passes -S -emit-llvm test_interstellar.c -o test_opt.ll

echo ""
echo "Running InterStellar Analysis Pass..."
echo ""
./build/bin/opt -passes="mem2reg,loop-simplify,interstellar-analysis" test_opt.ll -S -o test_interstellar_analyzed.ll -debug-only=interstellar-analysis 2>&1 | tee interstellar_debug.log

echo ""
echo "Output files generated:"
echo "  - test_interstellar_analyzed.ll (LLVM IR after analysis)"
echo "  - interstellar_debug.log (Debug information)"
echo ""
echo "=========================================="
echo "Test Complete!"
echo "=========================================="
