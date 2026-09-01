#!/bin/bash
# Capture instruction-identity baselines for all pattern tests.
#
# For each pattern {0..9,A,B,C}: run test_backend.sh and save the artifacts the
# simplification gates compare against:
#   input.ll        - clang -O0 IR (diagnostic only)
#   phase1.ll       - after InterStellarAnalysis (diagnostic; expected to change)
#   phase1.s        - llc RISC-V assembly          <-- GATE (instruction identity)
#   phase1.o        - assembled object             <-- GATE (instruction identity)
#   intrinsics.txt  - per-type intrinsic counts
#   run.log         - full test_backend.sh output
#
# patternA (loop-only code) legitimately emits zero intrinsics, so
# verify_descriptors.py aborts the run at step 4 and phase1.s is never produced.
# That outcome (run.log saying PARTIAL, no .s) is part of the golden.
#
# Usage: bash baseline/capture.sh [pattern ...]   (default: all 13)

set -u
cd "$(dirname "$0")/.."   # interstellar_test/

PATTERNS=("$@")
if [ ${#PATTERNS[@]} -eq 0 ]; then
    PATTERNS=(0 1 2 3 4 5 6 7 8 9 A B C)
fi

mkdir -p baseline
for p in "${PATTERNS[@]}"; do
    out="baseline/pattern$p"
    mkdir -p "$out"
    echo "=== pattern $p ==="
    # Remove working-dir artifacts first: a pattern that aborts mid-script must
    # not leave the previous pattern's test_backend.s/.o to be copied as ours.
    rm -f test_backend_input.ll test_backend_phase1.ll test_backend.s test_backend.o disassembly.txt
    bash test_backend.sh "$p" > "$out/run.log" 2>&1
    echo "  exit=$? (recorded; nonzero expected for patternA)"
    for f in test_backend_input.ll:test_input.ll \
             test_backend_phase1.ll:phase1.ll \
             test_backend.s:phase1.s \
             test_backend.o:phase1.o \
             disassembly.txt:disassembly.txt; do
        src="${f%%:*}"; dst="${f##*:}"
        [ -f "$src" ] && cp "$src" "$out/$dst"
    done
    {
        echo "link:      $(grep -c '@llvm.interstellar.configure.link' test_backend_phase1.ll 2>/dev/null || echo 0)"
        echo "loop:      $(grep -c '@llvm.interstellar.configure.loop' test_backend_phase1.ll 2>/dev/null || echo 0)"
        echo "direct:    $(grep -c '@llvm.interstellar.configure.directstream' test_backend_phase1.ll 2>/dev/null || echo 0)"
        echo "indirect:  $(grep -c '@llvm.interstellar.configure.indirectstream' test_backend_phase1.ll 2>/dev/null || echo 0)"
    } > "$out/intrinsics.txt"
done
echo "Baselines captured under baseline/pattern*/"
