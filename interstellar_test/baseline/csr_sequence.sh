#!/bin/bash
# Extract the ordered CSR-write sequence (the hardware contract) from RISC-V
# assembly or an objdump disassembly.
#
# The hardware parses ordered (CSR address, source register) pairs written with
# csrrw: even/odd address pairs 0x800+2*GlobalID form each 128-bit descriptor.
# If a simplification changes the .s but this sequence and the surrounding
# kernel code are unchanged, that is a cosmetic IR change; anything else is a
# contract violation.
#
# Usage: baseline/csr_sequence.sh <file.s | disassembly.txt>

FILE=${1:?usage: csr_sequence.sh <file.s | disassembly.txt>}

grep -nE '\bcsrrw\b|\bcsrw\b' "$FILE" \
| sed -E 's/^[0-9]+[[:space:]]*//' \
| awk '{
    # Normalise "csrw csr, rs1" -> "csrrw zero, csr, rs1"
    line = $0
    if (line ~ /csrw/) { sub(/csrw/, "csrrw zero,", line) }
    print line
  }'
