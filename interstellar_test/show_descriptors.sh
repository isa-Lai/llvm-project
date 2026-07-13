#!/bin/bash
# Display actual binary descriptors from Phase 2 output

if [ -z "$1" ]; then
    echo "Usage: $0 <phase2_ll_file>"
    exit 1
fi

FILE=$1

echo "=========================================="
echo "InterStellar Binary Descriptors"
echo "=========================================="
echo ""

# Extract CSR writes
grep "@llvm.riscv.interstellar.write.csr" "$FILE" | while read line; do
    # Extract CSR address and value
    csr_addr=$(echo "$line" | grep -oP 'i32 \K\d+')
    value=$(echo "$line" | grep -oP 'i128 [%0-9]+' | cut -d' ' -f2)
    
    if [[ "$value" == %* ]]; then
        echo "CSR 0x$(printf '%x' $csr_addr) (GlobalID $((csr_addr - 2048))): RUNTIME"
    else
        global_id=$((csr_addr - 2048))
        echo "CSR 0x$(printf '%x' $csr_addr) (GlobalID $global_id): $value"
        # Try to decode type
        type_byte=$((value & 0xFF))
        type_code=$(( (value >> 8) & 0xF ))
        case $type_code in
            0) echo "  → Type: Loop (0x00)" ;;
            1) echo "  → Type: DirectStream (0x01)" ;;
            2) echo "  → Type: IndirectStream (0x02)" ;;
            3) echo "  → Type: Link (0x03)" ;;
            *) echo "  → Type: Unknown (0x$type_code)" ;;
        esac
    fi
done

echo ""
echo "=========================================="
echo "Total CSR writes: $(grep -c "@llvm.riscv.interstellar.write.csr" "$FILE")"
echo "=========================================="
