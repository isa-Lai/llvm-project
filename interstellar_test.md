# 1. Compile the C file to LLVM IR
./build/bin/clang -O0 -S -emit-llvm test_interstellar.c -o test.ll

# 2. Run the InterStellar analysis pass (basic output)
./build/bin/opt -passes="interstellar-analysis" test.ll -o /dev/null

# 3. Run with detailed debug output (recommended)
./build/bin/opt -passes="interstellar-analysis" test.ll -o /dev/null -debug-only=interstellar-analysis

# 4. Alternative: Run with legacy pass manager
./build/bin/opt -interstellar-analysis test.ll -o /dev/null