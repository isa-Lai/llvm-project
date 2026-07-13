#!/usr/bin/env python3
"""
Parse and display InterStellar descriptors from LLVM IR.
Reads IR file with InterStellar intrinsics and prints detailed descriptor information.
"""

import sys
import re
from collections import defaultdict

def parse_metadata(md_string):
    """Parse LLVM metadata string into a dictionary."""
    result = {}
    
    # Match patterns like !{!"key", i32 value}
    simple_pattern = r'!\{!"(\w+)",\s*i32\s+(\d+)\}'
    for match in re.finditer(simple_pattern, md_string):
        key, value = match.groups()
        result[key] = int(value)
    
    # Match patterns like !{!"key", i64 value}
    i64_pattern = r'!\{!"(\w+)",\s*i64\s+(\d+)\}'
    for match in re.finditer(i64_pattern, md_string):
        key, value = match.groups()
        result[key] = int(value)
    
    return result

def parse_intrinsic_call(line):
    """Parse an InterStellar intrinsic call and extract all fields."""
    # Skip declare statements
    if 'declare' in line:
        return None
        
    # Match intrinsic name - handles both llvm.riscv.interstellar and llvm.interstellar
    intrinsic_match = re.search(r'llvm\.(?:riscv\.)?interstellar\.configure\.(\w+)', line)
    if not intrinsic_match:
        return None
    
    descriptor_type = intrinsic_match.group(1)
    
    # Extract arguments based on descriptor type
    args = {}
    
    # Find all integer arguments in order
    int_args = []
    for match in re.finditer(r'i(?:32|64)\s+(\d+)', line):
        int_args.append(int(match.group(1)))
    
    if descriptor_type == 'link':
        # link(i32 GlobalID, ptr base, i32 element_size)
        if len(int_args) >= 2:
            args['GlobalID'] = int_args[0]
            args['ElementSize'] = int_args[1]
    
    elif descriptor_type == 'loop':
        # loop(i32 GlobalID, i32 ParentLoopID, i1 is_inner, i1 is_sequential, 
        #      i32 trip_count_known, i32 trip_count, i32 unroll_factor)
        if len(int_args) >= 5:
            args['GlobalID'] = int_args[0]
            args['ParentLoopID'] = int_args[1]
            # Extract boolean values
            bool_matches = list(re.finditer(r'i1\s+(true|false)', line))
            if len(bool_matches) >= 2:
                args['IsInner'] = bool_matches[0].group(1) == 'true'
                args['IsSequential'] = bool_matches[1].group(1) == 'true'
            args['TripCountKnown'] = int_args[2]
            args['TripCount'] = int_args[3]
            args['UnrollFactor'] = int_args[4]
    
    elif descriptor_type == 'directstream':
        # directstream(i32 GlobalID, i32 ParentLoopID, i1 is_load, ptr stride, i32 LinkID)
        if len(int_args) >= 3:
            args['GlobalID'] = int_args[0]
            args['ParentLoopID'] = int_args[1]
            # Extract boolean value
            bool_match = re.search(r'i1\s+(true|false)', line)
            if bool_match:
                args['IsLoad'] = bool_match.group(1) == 'true'
            # stride is in ptr inttoptr format
            stride_match = re.search(r'inttoptr\s+\(i64\s+(\d+)', line)
            if stride_match:
                args['Stride'] = int(stride_match.group(1))
            if len(int_args) >= 4:
                args['LinkID'] = int_args[3]
    
    elif descriptor_type == 'indirectstream':
        # indirectstream(i32 GlobalID, i32 ParentLoopID, i1 is_load, ptr stride, i32 LinkID, i32 IndexLinkID)
        if len(int_args) >= 4:
            args['GlobalID'] = int_args[0]
            args['ParentLoopID'] = int_args[1]
            # Extract boolean value
            bool_match = re.search(r'i1\s+(true|false)', line)
            if bool_match:
                args['IsLoad'] = bool_match.group(1) == 'true'
            stride_match = re.search(r'inttoptr\s+\(i64\s+(\d+)', line)
            if stride_match:
                args['Stride'] = int(stride_match.group(1))
            if len(int_args) >= 5:
                args['LinkID'] = int_args[3]
                args['IndexLinkID'] = int_args[4]
    
    return {
        'type': descriptor_type,
        'line': line.strip(),
        'args': args
    }

def format_descriptor(desc):
    """Format a descriptor for pretty printing."""
    desc_type = desc['type']
    args = desc['args']
    
    lines = []
    # Format type name for display
    type_display = desc_type.upper()
    if desc_type == 'directstream':
        type_display = 'DIRECT STREAM'
    elif desc_type == 'indirectstream':
        type_display = 'INDIRECT STREAM'
    
    lines.append(f"  Type: {type_display}")
    lines.append(f"  GlobalID: {args.get('GlobalID', 'N/A')}")
    
    if desc_type == 'link':
        lines.append(f"  ElementSize: {args.get('ElementSize', 'N/A')} bytes")
    
    elif desc_type == 'loop':
        lines.append(f"  ParentLoopID: {args.get('ParentLoopID', 'N/A')}")
        lines.append(f"  IsInner: {args.get('IsInner', 'N/A')}")
        lines.append(f"  IsSequential: {args.get('IsSequential', 'N/A')}")
        lines.append(f"  TripCountKnown: {args.get('TripCountKnown', 'N/A')}")
        lines.append(f"  TripCount: {args.get('TripCount', 'N/A')}")
        lines.append(f"  UnrollFactor: {args.get('UnrollFactor', 'N/A')}")
    
    elif desc_type == 'directstream':
        lines.append(f"  ParentLoopID: {args.get('ParentLoopID', 'N/A')}")
        lines.append(f"  IsLoad: {args.get('IsLoad', 'N/A')}")
        lines.append(f"  Stride: {args.get('Stride', 'N/A')}")
        lines.append(f"  LinkID: {args.get('LinkID', 'N/A')}")
    
    elif desc_type == 'indirectstream':
        lines.append(f"  ParentLoopID: {args.get('ParentLoopID', 'N/A')}")
        lines.append(f"  IsLoad: {args.get('IsLoad', 'N/A')}")
        lines.append(f"  Stride: {args.get('Stride', 'N/A')}")
        lines.append(f"  LinkID: {args.get('LinkID', 'N/A')}")
        lines.append(f"  IndexLinkID: {args.get('IndexLinkID', 'N/A')}")
    
    return '\n'.join(lines)

def main():
    if len(sys.argv) != 2:
        print("Usage: parse_descriptors.py <ir_file>")
        sys.exit(1)
    
    ir_file = sys.argv[1]
    
    try:
        with open(ir_file, 'r') as f:
            content = f.read()
    except FileNotFoundError:
        print(f"❌ Error: File {ir_file} not found")
        sys.exit(1)
    
    # Find all InterStellar intrinsic calls - handle wrapped lines
    descriptors = []
    lines = content.split('\n')
    
    i = 0
    while i < len(lines):
        line = lines[i]
        
        # Check if this is an intrinsic call
        if ('call void @llvm.interstellar.configure' in line or 
            'call void @llvm.riscv.interstellar.configure' in line):
            
            # If line doesn't end with a closing paren, it's wrapped - join next lines
            while i < len(lines) - 1 and ')' not in line:
                i += 1
                line += " " + lines[i].strip()
            
            # Now parse the complete line
            desc = parse_intrinsic_call(line)
            if desc:
                descriptors.append(desc)
        
        i += 1
    
    if not descriptors:
        print("❌ No InterStellar descriptors found in IR")
        sys.exit(1)
    
    # Group by type
    by_type = defaultdict(list)
    for desc in descriptors:
        by_type[desc['type']].append(desc)
    
    # Print summary
    print("\n" + "="*60)
    print("INTERSTELLAR DESCRIPTOR ANALYSIS")
    print("="*60)
    print(f"\nTotal Descriptors: {len(descriptors)}")
    print(f"  - Link:           {len(by_type['link'])}")
    print(f"  - Loop:           {len(by_type['loop'])}")
    print(f"  - Direct Stream:  {len(by_type['directstream'])}")
    print(f"  - Indirect Stream: {len(by_type['indirectstream'])}")
    
    # Print detailed information for each descriptor
    print("\n" + "="*60)
    print("DETAILED DESCRIPTOR INFORMATION")
    print("="*60)
    
    descriptor_num = 1
    for desc_type in ['link', 'loop', 'directstream', 'indirectstream']:
        if desc_type in by_type:
            print(f"\n{desc_type.upper().replace('STREAM', ' STREAM')} DESCRIPTORS:")
            print("-"*60)
            for desc in by_type[desc_type]:
                print(f"\nDescriptor #{descriptor_num}:")
                print(format_descriptor(desc))
                descriptor_num += 1
    
    # Print GlobalID usage map
    print("\n" + "="*60)
    print("GLOBALID USAGE MAP")
    print("="*60)
    global_ids = {}
    for desc in descriptors:
        gid = desc['args'].get('GlobalID')
        if gid is not None:
            global_ids[gid] = desc['type']
    
    print(f"\nUsed GlobalIDs: {sorted(global_ids.keys())}")
    print(f"Total Unique: {len(global_ids)}")
    print(f"Hardware Limit: 32 CSRs (0x800-0x81F)")
    print(f"Available: {32 - len(global_ids)} CSRs remaining")
    
    if len(global_ids) > 32:
        print("\n⚠️  WARNING: Exceeds hardware limit of 32 CSRs!")
    else:
        print("\n✅ Within hardware CSR limit")
    
    # Print relationship graph
    print("\n" + "="*60)
    print("DESCRIPTOR RELATIONSHIPS")
    print("="*60)
    
    # Build parent-child map
    children = defaultdict(list)
    for desc in descriptors:
        parent_id = desc['args'].get('ParentLoopID')
        gid = desc['args'].get('GlobalID')
        if parent_id is not None and gid is not None:
            children[parent_id].append((gid, desc['type']))
    
    print("\nLoop → Stream Hierarchy:")
    for desc in by_type.get('loop', []):
        gid = desc['args'].get('GlobalID')
        print(f"\n  Loop GlobalID={gid}")
        if gid in children:
            for child_gid, child_type in children[gid]:
                print(f"    └─> {child_type.upper()} GlobalID={child_gid}")
        else:
            print(f"    └─> (no streams)")
    
    print("\n" + "="*60)
    print("✅ Descriptor parsing complete")
    print("="*60 + "\n")

if __name__ == '__main__':
    main()
