# 1. Wipe the old configuration cache so CMake registers the change
rm -rf build/CMakeCache.txt build/CMakeFiles

# 2. Re-configure LLVM with Assertions explicitly enabled
cmake -S llvm -B build -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DLLVM_ENABLE_ASSERTIONS=ON \
  -DLLVM_ENABLE_PROJECTS="clang" \
  -DLLVM_TARGETS_TO_BUILD="Native;RISCV" \
  -DLLVM_DEFAULT_TARGET_TRIPLE="riscv64-unknown-linux-gnu"

# 3. Recompile the project 
# (This will take longer than previous ninja runs because turning on assertions 
# changes core header files, requiring many files to be recompiled).
ninja -C build
