	.attribute	4, 16
	.attribute	5, "rv64i2p1_m2p0_a2p1_f2p2_d2p2_c2p0_zicsr2p0_zifencei2p0_zmmul1p0_zaamo1p0_zalrsc1p0_zca1p0_zcd1p0"
	.file	"pattern1_direct_streams.c"
	.option	push
	.option	arch, +a, +c, +d, +f, +m, +zaamo, +zalrsc, +zca, +zcd, +zicsr, +zifencei, +zmmul
	.text
	.globl	pattern1_direct_streams         # -- Begin function pattern1_direct_streams
	.p2align	1
	.type	pattern1_direct_streams,@function
pattern1_direct_streams:                # @pattern1_direct_streams
	.cfi_startproc
# %bb.0:                                # %entry
	li	a2, 0
	li	a5, 0
	addi	a3, a0, 8
	addi	a4, a0, 12
	li	t0, 195
	csrw	2050, t0
	li	t1, 8
	csrw	2051, t1
	lui	t0, 48
	addi	t0, t0, 195
	csrw	2052, t0
	li	t1, 8
	csrw	2053, t1
	slli	a3, a1, 32
	lui	t0, 64
	addi	t0, t0, 195
	csrw	2054, t0
	li	t1, 8
	csrw	2055, t1
	srli	a3, a3, 32
	lui	t0, 48
	addi	t0, t0, 195
	csrw	2048, t0
	li	t1, 4
	csrw	2049, t1
	lui	t0, 8
	addi	t0, t0, 192
	csrw	2056, t0
	lui	t1, 16
	csrw	2057, t1
	lui	t0, 20
	addi	t0, t0, 1217
	csrw	2058, t0
	li	t1, 4
	csrw	2059, t1
	lui	t0, 36
	addi	t0, t0, 1217
	csrw	2060, t0
	li	t1, 4
	csrw	2061, t1
	lui	t0, 20
	addi	t0, t0, 1217
	csrw	2062, t0
	li	t1, 8
	csrw	2063, t1
	lui	t0, 52
	addi	t0, t0, 1217
	csrw	2064, t0
	li	t1, 12
	csrw	2065, t1
	li	a3, 3
	mv	a4, a0
	j	.LBB0_2
.LBB0_1:                                # %if.end22
                                        #   in Loop: Header=BB0_2 Depth=1
	addiw	a3, a3, 3
	addiw	a2, a2, 2
	addi	a4, a4, 4
	addiw	a5, a5, -1
.LBB0_2:                                # %for.cond
                                        # =>This Inner Loop Header: Depth=1
	bge	a5, a1, .LBB0_9
# %bb.3:                                # %for.body
                                        #   in Loop: Header=BB0_2 Depth=1
	lw	a6, 0(a4)
	addi	a6, a6, 1
	addiw	a5, a5, 2
	sw	a6, 0(a4)
	blt	a5, a1, .LBB0_6
# %bb.4:                                # %if.end
                                        #   in Loop: Header=BB0_2 Depth=1
	blt	a2, a1, .LBB0_7
.LBB0_5:                                # %if.end12
                                        #   in Loop: Header=BB0_2 Depth=1
	bge	a3, a1, .LBB0_1
	j	.LBB0_8
.LBB0_6:                                # %if.then
                                        #   in Loop: Header=BB0_2 Depth=1
	slli	a6, a5, 2
	add	a6, a6, a0
	lw	a7, 0(a6)
	addi	a7, a7, 1
	sw	a7, 0(a6)
	bge	a2, a1, .LBB0_5
.LBB0_7:                                # %if.then7
                                        #   in Loop: Header=BB0_2 Depth=1
	slli	a6, a2, 2
	add	a6, a6, a0
	lw	a7, 0(a6)
	addi	a7, a7, 1
	sw	a7, 0(a6)
	bge	a3, a1, .LBB0_1
.LBB0_8:                                # %if.then16
                                        #   in Loop: Header=BB0_2 Depth=1
	slli	a6, a3, 2
	add	a6, a6, a0
	lw	a7, 0(a6)
	addi	a7, a7, 1
	sw	a7, 0(a6)
	j	.LBB0_1
.LBB0_9:                                # %for.cond.cleanup
	ret
.Lfunc_end0:
	.size	pattern1_direct_streams, .Lfunc_end0-pattern1_direct_streams
	.cfi_endproc
                                        # -- End function
	.option	pop
	.option	push
	.option	arch, +a, +c, +d, +f, +m, +zaamo, +zalrsc, +zca, +zcd, +zicsr, +zifencei, +zmmul
	.globl	pattern1_global_array           # -- Begin function pattern1_global_array
	.p2align	1
	.type	pattern1_global_array,@function
pattern1_global_array:                  # @pattern1_global_array
	.cfi_startproc
# %bb.0:                                # %entry
	li	a1, 0
	li	t0, 25
	slli	t0, t0, 51
	addi	t0, t0, 192
	csrw	2050, t0
	lui	t1, 16
	csrw	2051, t1
	lui	a2, %hi(GlobalArray)
	addi	a2, a2, %lo(GlobalArray)
	lui	t0, 32
	addi	t0, t0, 449
	csrw	2058, t0
	li	t1, 4
	csrw	2059, t1
	li	a3, 200
	blez	a3, .LBB1_2
.LBB1_1:                                # %for.body
                                        # =>This Inner Loop Header: Depth=1
	sw	zero, 0(a2)
	addiw	a1, a1, 1
	addi	a2, a2, 4
	blt	a1, a3, .LBB1_1
.LBB1_2:                                # %for.cond.cleanup
	li	a1, 0
	li	a2, 0
	lui	a3, %hi(GlobalArray)
	addi	a3, a3, %lo(GlobalArray)
	li	t0, 192
	csrw	2048, t0
	lui	t1, 16
	csrw	2049, t1
	lui	t0, 48
	addi	t0, t0, 193
	csrw	2052, t0
	li	t1, 4
	csrw	2053, t1
	li	t0, 193
	csrw	2054, t0
	li	t1, 4
	csrw	2055, t1
	lui	t0, 48
	addi	t0, t0, 193
	csrw	2056, t0
	li	t1, 8
	csrw	2057, t1
	li	a4, 199
	mv	a5, a3
	j	.LBB1_4
.LBB1_3:                                # %if.end21
                                        #   in Loop: Header=BB1_4 Depth=1
	addiw	a2, a2, 1
	addiw	a1, a1, 2
	addi	a5, a5, 4
.LBB1_4:                                # %for.cond2
                                        # =>This Inner Loop Header: Depth=1
	bge	a2, a0, .LBB1_6
# %bb.5:                                # %land.rhs
                                        #   in Loop: Header=BB1_4 Depth=1
	slti	a6, a2, 200
	bnez	a6, .LBB1_7
	j	.LBB1_11
.LBB1_6:
	j	.LBB1_11
.LBB1_7:                                # %for.body6
                                        #   in Loop: Header=BB1_4 Depth=1
	lw	a6, 0(a5)
	addi	a7, a6, 1
	addiw	a6, a2, 5
	sw	a7, 0(a5)
	blt	a4, a6, .LBB1_9
# %bb.8:                                # %if.then
                                        #   in Loop: Header=BB1_4 Depth=1
	slli	a6, a6, 2
	add	a6, a6, a3
	lw	a7, 0(a6)
	addi	a7, a7, 1
	sw	a7, 0(a6)
.LBB1_9:                                # %if.end
                                        #   in Loop: Header=BB1_4 Depth=1
	blt	a4, a1, .LBB1_3
# %bb.10:                               # %if.then16
                                        #   in Loop: Header=BB1_4 Depth=1
	slli	a6, a1, 2
	add	a6, a6, a3
	lw	a7, 0(a6)
	addi	a7, a7, 1
	sw	a7, 0(a6)
	j	.LBB1_3
.LBB1_11:                               # %for.cond.cleanup5
	ret
.Lfunc_end1:
	.size	pattern1_global_array, .Lfunc_end1-pattern1_global_array
	.cfi_endproc
                                        # -- End function
	.option	pop
	.type	GlobalArray,@object             # @GlobalArray
	.bss
	.globl	GlobalArray
	.p2align	2, 0x0
GlobalArray:
	.zero	800
	.size	GlobalArray, 800

	.ident	"clang version 24.0.0git (git@github.com:isa-Lai/llvm-project.git 0ccca49fbdf066b1df3977840d128c8872a444c6)"
	.section	".note.GNU-stack","",@progbits
