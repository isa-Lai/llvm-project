#!/bin/bash
# Gate check: rerun all pattern tests and compare against captured baselines.
#
#   Gate G1 (default): llc .s output + assembled .o must be byte-identical
#                      (instruction identity).
#   -v                 : also report intrinsic-count and phase1.ll drift
#                      (diagnostic; phase1.ll is expected to change in Stage 4+).
#
# Usage: baseline/check_gate.sh [-v] [pattern ...]

set -u
cd "$(dirname "$0")/.."   # interstellar_test/

VERBOSE=0
if [ "${1:-}" = "-v" ]; then VERBOSE=1; shift; fi

PATTERNS=("$@")
if [ ${#PATTERNS[@]} -eq 0 ]; then
    PATTERNS=(0 1 2 3 4 5 6 7 8 9 A B C)
fi

FAIL=0
for p in "${PATTERNS[@]}"; do
    base="baseline/pattern$p"
    # Clear working-dir artifacts: a pattern that aborts mid-script (e.g. the
    # verifier rejecting a legitimate descriptor shape) must not let the
    # previous pattern's test_backend.s/.o stand in for this one's.
    rm -f test_backend_input.ll test_backend_phase1.ll test_backend.s test_backend.o disassembly.txt
    bash test_backend.sh "$p" >/dev/null 2>&1
    for f in phase1.s phase1.o; do
        if [ -f "$base/$f" ] || [ -f "$f" ]; then
            if ! cmp -s "$base/$f" "$f"; then
                echo "GATE FAIL pattern$p: $f differs"
                FAIL=1
            fi
        fi   # both missing (patternA) = match
    done
    if [ $VERBOSE -eq 1 ]; then
        if ! diff -q "$base/intrinsics.txt" \
             <(grep -c "@llvm.interstellar.configure.link" test_backend_phase1.ll 2>/dev/null | xargs -I{} echo "link:      {}"; \
               grep -c "@llvm.interstellar.configure.loop" test_backend_phase1.ll 2>/dev/null | xargs -I{} echo "loop:      {}"; \
               grep -c "@llvm.interstellar.configure.directstream" test_backend_phase1.ll 2>/dev/null | xargs -I{} echo "direct:    {}"; \
               grep -c "@llvm.interstellar.configure.indirectstream" test_backend_phase1.ll 2>/dev/null | xargs -I{} echo "indirect:  {}") >/dev/null; then
            echo "note pattern$p: intrinsic counts changed (diagnostic)"
        fi
        if ! cmp -s "$base/phase1.ll" test_backend_phase1.ll; then
            echo "note pattern$p: phase1.ll differs (expected from Stage 4)"
        fi
    fi
done

if [ $FAIL -eq 0 ]; then
    echo "GATE OK: all ${#PATTERNS[@]} patterns instruction-identical"
else
    echo "GATE FAILED"
fi
exit $FAIL
