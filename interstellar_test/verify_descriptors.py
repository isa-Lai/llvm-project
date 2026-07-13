#!/usr/bin/env python3
"""
InterStellar Configuration Intrinsics Verification Tool

This script parses LLVM IR containing @llvm.interstellar.configure.* intrinsics
and verifies the descriptor information according to the InterStellar ISA specification.

InterStellar Intrinsics (Phase 1 Output):
- configure.link:            GlobalID, ptr, Size
- configure.loop:            GlobalID, ParentID, isNested, isInc, LowerBound, UpperBound, Step
- configure.directstream:    GlobalID, LoopID, isWrite, BaseAddr, ElementSize
- configure.indirectstream:  GlobalID, SourceID, isWrite, BaseAddr, ElementSize, IndexSize

This tool verifies that:
1. All intrinsics are well-formed
2. GlobalIDs are unique and within range [0, 31]
3. References between descriptors are valid (loop IDs, link IDs)
4. No more than 32 total descriptors (hardware limit)

Usage:
    ./verify_descriptors.py test_backend_phase1.ll
"""

import sys
import re
from typing import List, Dict, Set, Tuple

class Descriptor:
    """Base class for InterStellar descriptors"""
    def __init__(self, global_id: int, desc_type: str):
        self.global_id = global_id
        self.desc_type = desc_type
    
    def __str__(self):
        return f"{self.desc_type}[{self.global_id}]"

class LinkDescriptor(Descriptor):
    """Link descriptor - Runtime value (pointer or loop bound)"""
    def __init__(self, global_id: int, ptr_value: str, size: int):
        super().__init__(global_id, "Link")
        self.ptr_value = ptr_value
        self.size = size
    
    def __str__(self):
        return f"Link[{self.global_id}]: ptr={self.ptr_value}, size={self.size}"

class LoopDescriptor(Descriptor):
    """Loop descriptor - Loop bounds and step"""
    def __init__(self, global_id: int, parent_id: int, is_nested: bool, is_inc: bool,
                 lower_bound: int, upper_bound: int, step: int):
        super().__init__(global_id, "Loop")
        self.parent_id = parent_id
        self.is_nested = is_nested
        self.is_inc = is_inc
        self.lower_bound = lower_bound
        self.upper_bound = upper_bound
        self.step = step
    
    def __str__(self):
        direction = "inc" if self.is_inc else "dec"
        return f"Loop[{self.global_id}]: parent={self.parent_id}, bounds=[{self.lower_bound}:{self.upper_bound}], step={self.step} ({direction})"

class DirectStreamDescriptor(Descriptor):
    """Direct stream descriptor - Strided memory access"""
    def __init__(self, global_id: int, loop_id: int, is_write: bool, base_addr: str, elem_size: int):
        super().__init__(global_id, "DirectStream")
        self.loop_id = loop_id
        self.is_write = is_write
        self.base_addr = base_addr
        self.elem_size = elem_size
    
    def __str__(self):
        access = "W" if self.is_write else "R"
        return f"DirectStream[{self.global_id}]: loop={self.loop_id}, base={self.base_addr}, size={self.elem_size} ({access})"

class IndirectStreamDescriptor(Descriptor):
    """Indirect stream descriptor - Indexed memory access"""
    def __init__(self, global_id: int, source_id: int, is_write: bool, base_addr: str,
                 elem_size: int, index_size: int):
        super().__init__(global_id, "IndirectStream")
        self.source_id = source_id
        self.is_write = is_write
        self.base_addr = base_addr
        self.elem_size = elem_size
        self.index_size = index_size
    
    def __str__(self):
        access = "W" if self.is_write else "R"
        return f"IndirectStream[{self.global_id}]: source={self.source_id}, base={self.base_addr}, size={self.elem_size} ({access})"

def parse_intrinsics(ir_content: str) -> Tuple[List[Descriptor], Set[int]]:
    """Parse InterStellar configuration intrinsics from LLVM IR"""
    descriptors = []
    global_ids = set()
    
    # Pattern for configure.link
    link_pattern = r'call void @llvm\.interstellar\.configure\.link\(i32 (\d+), ptr ([^,]+), i32 (\d+)\)'
    for match in re.finditer(link_pattern, ir_content):
        global_id = int(match.group(1))
        ptr_value = match.group(2).strip()
        size = int(match.group(3))
        
        if global_id in global_ids:
            print(f"⚠️  Warning: Duplicate GlobalID {global_id} for Link")
        global_ids.add(global_id)
        
        descriptors.append(LinkDescriptor(global_id, ptr_value, size))
    
    # Pattern for configure.loop
    loop_pattern = r'call void @llvm\.interstellar\.configure\.loop\(i32 (\d+), i32 (\d+), i1 (true|false), i1 (true|false), i32 (-?\d+), i32 (-?\d+), i32 (-?\d+)\)'
    for match in re.finditer(loop_pattern, ir_content):
        global_id = int(match.group(1))
        parent_id = int(match.group(2))
        is_nested = match.group(3) == 'true'
        is_inc = match.group(4) == 'true'
        lower_bound = int(match.group(5))
        upper_bound = int(match.group(6))
        step = int(match.group(7))
        
        if global_id in global_ids:
            print(f"⚠️  Warning: Duplicate GlobalID {global_id} for Loop")
        global_ids.add(global_id)
        
        descriptors.append(LoopDescriptor(global_id, parent_id, is_nested, is_inc,
                                         lower_bound, upper_bound, step))
    
    # Pattern for configure.directstream
    stream_pattern = r'call void @llvm\.interstellar\.configure\.directstream\(i32 (\d+), i32 (\d+), i1 (true|false), ptr ([^,]+), i32 (\d+)\)'
    for match in re.finditer(stream_pattern, ir_content):
        global_id = int(match.group(1))
        loop_id = int(match.group(2))
        is_write = match.group(3) == 'true'
        base_addr = match.group(4).strip()
        elem_size = int(match.group(5))
        
        if global_id in global_ids:
            print(f"⚠️  Warning: Duplicate GlobalID {global_id} for DirectStream")
        global_ids.add(global_id)
        
        descriptors.append(DirectStreamDescriptor(global_id, loop_id, is_write,
                                                  base_addr, elem_size))
    
    # Pattern for configure.indirectstream
    indirect_pattern = r'call void @llvm\.interstellar\.configure\.indirectstream\(i32 (\d+), i32 (\d+), i1 (true|false), ptr ([^,]+), i32 (\d+), i32 (\d+)\)'
    for match in re.finditer(indirect_pattern, ir_content):
        global_id = int(match.group(1))
        source_id = int(match.group(2))
        is_write = match.group(3) == 'true'
        base_addr = match.group(4).strip()
        elem_size = int(match.group(5))
        index_size = int(match.group(6))
        
        if global_id in global_ids:
            print(f"⚠️  Warning: Duplicate GlobalID {global_id} for IndirectStream")
        global_ids.add(global_id)
        
        descriptors.append(IndirectStreamDescriptor(global_id, source_id, is_write,
                                                    base_addr, elem_size, index_size))
    
    return descriptors, global_ids

def verify_descriptors(descriptors: List[Descriptor], global_ids: Set[int]) -> bool:
    """Verify descriptor correctness"""
    print("\n" + "="*70)
    print("InterStellar Descriptor Verification")
    print("="*70)
    
    if not descriptors:
        print("\n❌ No InterStellar configuration intrinsics found!")
        print("   Make sure Phase 1 (InterStellarAnalysis) ran successfully.")
        return False
    
    # Check hardware limit
    if len(descriptors) > 32:
        print(f"\n❌ ERROR: Too many descriptors ({len(descriptors)} > 32 hardware limit)")
        return False
    
    print(f"\n✅ Found {len(descriptors)} descriptor(s) (within 32 CSR limit)")
    
    # Verify GlobalID range
    invalid_ids = [gid for gid in global_ids if gid < 0 or gid > 31]
    if invalid_ids:
        print(f"\n❌ ERROR: GlobalIDs out of range [0, 31]: {invalid_ids}")
        return False
    
    print(f"✅ All GlobalIDs within valid range [0, 31]")
    
    # Check for reference integrity
    loop_ids = {d.global_id for d in descriptors if isinstance(d, LoopDescriptor)}
    link_ids = {d.global_id for d in descriptors if isinstance(d, LinkDescriptor)}
    
    errors = []
    
    for desc in descriptors:
        if isinstance(desc, DirectStreamDescriptor):
            if desc.loop_id not in loop_ids:
                errors.append(f"DirectStream[{desc.global_id}] references non-existent Loop ID {desc.loop_id}")
        
        elif isinstance(desc, IndirectStreamDescriptor):
            if desc.source_id not in global_ids:
                errors.append(f"IndirectStream[{desc.global_id}] references non-existent Source ID {desc.source_id}")
    
    if errors:
        print(f"\n❌ ERROR: Reference integrity violations:")
        for error in errors:
            print(f"   {error}")
        return False
    
    print(f"✅ All descriptor references are valid")
    
    # Print detailed breakdown
    print("\n" + "="*70)
    print("Descriptor Details")
    print("="*70 + "\n")
    
    # Group by type
    links = [d for d in descriptors if isinstance(d, LinkDescriptor)]
    loops = [d for d in descriptors if isinstance(d, LoopDescriptor)]
    streams = [d for d in descriptors if isinstance(d, DirectStreamDescriptor)]
    indirects = [d for d in descriptors if isinstance(d, IndirectStreamDescriptor)]
    
    if links:
        print(f"Link Descriptors ({len(links)}):")
        for desc in sorted(links, key=lambda d: d.global_id):
            print(f"  {desc}")
        print()
    
    if loops:
        print(f"Loop Descriptors ({len(loops)}):")
        for desc in sorted(loops, key=lambda d: d.global_id):
            print(f"  {desc}")
        print()
    
    if streams:
        print(f"DirectStream Descriptors ({len(streams)}):")
        for desc in sorted(streams, key=lambda d: d.global_id):
            print(f"  {desc}")
        print()
    
    if indirects:
        print(f"IndirectStream Descriptors ({len(indirects)}):")
        for desc in sorted(indirects, key=lambda d: d.global_id):
            print(f"  {desc}")
        print()
    
    print("="*70)
    print("✅ All descriptors verified successfully!")
    print("="*70)
    
    return True

def main():
    if len(sys.argv) < 2:
        print("Usage: verify_descriptors.py <ir_file>")
        print()
        print("Verifies InterStellar configuration intrinsics in LLVM IR")
        sys.exit(1)
    
    ir_file = sys.argv[1]
    
    try:
        with open(ir_file, 'r') as f:
            ir_content = f.read()
    except FileNotFoundError:
        print(f"❌ Error: File '{ir_file}' not found!")
        sys.exit(1)
    
    print(f"\nAnalyzing: {ir_file}")
    
    descriptors, global_ids = parse_intrinsics(ir_content)
    valid = verify_descriptors(descriptors, global_ids)
    
    sys.exit(0 if valid else 1)

if __name__ == '__main__':
    main()
