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
    # Patterns whose run aborts before llc (pattern8: verifier rejects its
    # legitimate descriptor shapes) still have baselines generated directly
    # from phase1.ll — reproduce that fallback identically so the gate stays
    # apples-to-apples. Only when the baseline has a .s; patternA's golden is
    # precisely "nothing was produced".
    if [ ! -f test_backend.s ] && [ -f "$base/phase1.s" ] && [ -f test_backend_phase1.ll ]; then
        ../build/bin/llc test_backend_phase1.ll -o test_backend.s 2>/dev/null
        [ -f test_backend.s ] && \
            ../build/bin/clang --target=riscv64-unknown-linux-gnu -march=rv64gc \
                -c test_backend.s -o test_backend.o 2>/dev/null
    fi
    # Version-stamp normalization: clang embeds the build-tree git hash in
    # `.ident` (.s) and the .comment section (.o), so those bytes change with
    # every commit even when the code is identical. Compare .s without .ident
    # lines, and .o via instruction disassembly (excludes .comment).
    for f in test_backend.s:phase1.s test_backend.o:phase1.o; do
        fresh="${f%%:*}"; golden="${f##*:}"
        if [ ! -f "$base/$golden" ] && [ ! -f "$fresh" ]; then
            continue   # both missing (patternA) = match
        fi
        case "$golden" in
            phase1.s)
                diff <(grep -v '^[[:space:]]*\.ident' "$base/$golden" 2>/dev/null) \
                     <(grep -v '^[[:space:]]*\.ident' "$fresh" 2>/dev/null) >/dev/null ;;
            phase1.o)
                diff <(../build/bin/llvm-objdump -d "$base/$golden" 2>/dev/null | grep -v 'file format') \
                     <(../build/bin/llvm-objdump -d "$fresh" 2>/dev/null | grep -v 'file format') >/dev/null ;;
        esac
        if [ $? -ne 0 ]; then
            echo "GATE FAIL pattern$p: $golden differs"
            FAIL=1
        fi
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
