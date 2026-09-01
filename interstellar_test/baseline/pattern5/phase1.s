	.attribute	4, 16
	.attribute	5, "rv64i2p1_m2p0_a2p1_f2p2_d2p2_c2p0_zicsr2p0_zifencei2p0_zmmul1p0_zaamo1p0_zalrsc1p0_zca1p0_zcd1p0"
	.file	"pattern5_2d_pointer.c"
	.option	push
	.option	arch, +a, +c, +d, +f, +m, +zaamo, +zalrsc, +zca, +zcd, +zicsr, +zifencei, +zmmul
	.text
	.globl	pattern5_2d_pointer             # -- Begin function pattern5_2d_pointer
	.p2align	1
	.type	pattern5_2d_pointer,@function
pattern5_2d_pointer:                    # @pattern5_2d_pointer
	.cfi_startproc
# %bb.0:                                # %entry
	li	a5, 0
	li	a6, 0
	mul	a7, a4, a3
	slli	t0, a4, 32
	slli	t1, a3, 32
	srli	t0, t0, 32
	lui	t0, 80
	addi	t0, t0, 195
	csrw	2050, t0
	li	t1, 4
	csrw	2051, t1
	srli	t0, t1, 32
	li	t0, 195
	csrw	2052, t0
	li	t1, 8
	csrw	2053, t1
	slli	a7, a7, 32
	lui	t0, 16
	addi	t0, t0, 195
	csrw	2054, t0
	li	t1, 8
	csrw	2055, t1
	srli	a7, a7, 32
	lui	t0, 80
	addi	t0, t0, 195
	csrw	2048, t0
	li	t1, 4
	csrw	2049, t1
	lui	t0, 112
	addi	t0, t0, 195
	csrw	2056, t0
	li	t1, 4
	csrw	2057, t1
	lui	t0, 8
	addi	t0, t0, 192
	csrw	2058, t0
	lui	t1, 16
	csrw	2059, t1
	li	t0, 1
	slli	t0, t0, 42
	addi	t0, t0, 515
	slli	t0, t0, 6
	csrw	2060, t0
	csrw	2061, t1
	li	t0, 1
	slli	t0, t0, 44
	addi	t0, t0, 515
	slli	t0, t0, 6
	csrw	2062, t0
	csrw	2063, t1
	lui	t0, 20
	addi	t0, t0, 1985
	csrw	2064, t0
	li	t1, 4
	csrw	2065, t1
	lui	t0, 36
	addi	t0, t0, 1473
	csrw	2066, t0
	li	t1, 4
	csrw	2067, t1
	lui	t0, 20
	addi	t0, t0, 1729
	csrw	2068, t0
	li	t1, 4
	csrw	2069, t1
	lui	t0, 36
	addi	t0, t0, 1729
	csrw	2070, t0
	li	t1, 4
	csrw	2071, t1
	lui	t0, 53
	addi	t0, t0, -1086
	csrw	2072, t0
	li	t1, 4
	csrw	2073, t1
	j	.LBB0_2
.LBB0_1:                                # %for.cond.cleanup3
                                        #   in Loop: Header=BB0_2 Depth=1
	addiw	a6, a6, 1
	add	a5, a5, a4
.LBB0_2:                                # %for.cond
                                        # =>This Loop Header: Depth=1
                                        #     Child Loop BB0_5 Depth 2
	bge	a6, a3, .LBB0_8
# %bb.3:                                # %for.body
                                        #   in Loop: Header=BB0_2 Depth=1
	li	a7, 0
	li	t0, 0
	mul	t1, a6, a4
	slli	t2, a6, 2
	add	t2, t2, a0
	mv	t3, a0
	j	.LBB0_5
.LBB0_4:                                # %if.end
                                        #   in Loop: Header=BB0_5 Depth=2
	addiw	t0, t0, 1
	addi	t3, t3, 4
	addi	a7, a7, 1
.LBB0_5:                                # %for.cond1
                                        #   Parent Loop BB0_2 Depth=1
                                        # =>  This Inner Loop Header: Depth=2
	bge	t0, a4, .LBB0_1
# %bb.6:                                # %for.body4
                                        #   in Loop: Header=BB0_5 Depth=2
	addw	t4, a5, t0
	slli	t4, t4, 2
	add	t4, t4, a1
	lw	t5, 0(t4)
	addi	t5, t5, 1
	sw	t5, 0(t4)
	bge	a6, a2, .LBB0_4
# %bb.7:                                # %if.then
                                        #   in Loop: Header=BB0_5 Depth=2
	lw	t4, 0(t2)
	remw	t4, t4, a3
	mulw	t4, t4, a4
	add	t4, t4, a7
	slli	t4, t4, 2
	add	t4, t4, a1
	lw	t5, 0(t4)
	addi	t5, t5, 1
	sw	t5, 0(t4)
	lw	t4, 0(t3)
	remw	t4, t4, a4
	addw	t4, t1, t4
	slli	t4, t4, 2
	add	t4, t4, a1
	lw	t5, 0(t4)
	addi	t5, t5, 1
	sw	t5, 0(t4)
	j	.LBB0_4
.LBB0_8:                                # %for.cond.cleanup
	ret
.Lfunc_end0:
	.size	pattern5_2d_pointer, .Lfunc_end0-pattern5_2d_pointer
	.cfi_endproc
                                        # -- End function
	.option	pop
	.option	push
	.option	arch, +a, +c, +d, +f, +m, +zaamo, +zalrsc, +zca, +zcd, +zicsr, +zifencei, +zmmul
	.globl	pattern5_2d_pointerB            # -- Begin function pattern5_2d_pointerB
	.p2align	1
	.type	pattern5_2d_pointerB,@function
pattern5_2d_pointerB:                   # @pattern5_2d_pointerB
	.cfi_startproc
# %bb.0:                                # %entry
	li	a0, 0
	li	a2, 0
	mul	a5, a4, a3
	slli	a6, a4, 32
	slli	a5, a5, 32
	srli	a6, a6, 32
	srli	a5, a5, 32
	lui	t0, 96
	addi	t0, t0, 195
	csrw	2050, t0
	li	t1, 4
	csrw	2051, t1
	lui	t0, 80
	addi	t0, t0, 195
	csrw	2052, t0
	li	t1, 4
	csrw	2053, t1
	li	t0, 1
	slli	t0, t0, 43
	addi	t0, t0, 515
	slli	t0, t0, 6
	csrw	2054, t0
	lui	t1, 16
	csrw	2055, t1
	lui	t0, 20
	addi	t0, t0, 961
	csrw	2056, t0
	li	t1, 4
	csrw	2057, t1
	j	.LBB1_2
.LBB1_1:                                # %for.cond.cleanup3
                                        #   in Loop: Header=BB1_2 Depth=1
	addiw	a2, a2, 1
	addw	a0, a0, a4
.LBB1_2:                                # %for.cond
                                        # =>This Loop Header: Depth=1
                                        #     Child Loop BB1_4 Depth 2
	bge	a2, a3, .LBB1_5
# %bb.3:                                # %for.body
                                        #   in Loop: Header=BB1_2 Depth=1
	li	a5, 0
	mv	a6, a0
	blez	a4, .LBB1_1
.LBB1_4:                                # %for.body4
                                        #   Parent Loop BB1_2 Depth=1
                                        # =>  This Inner Loop Header: Depth=2
	slli	a7, a6, 2
	add	a7, a7, a1
	lw	t0, 0(a7)
	addi	t0, t0, 1
	sw	t0, 0(a7)
	addiw	a5, a5, 1
	addiw	a6, a6, 1
	blt	a5, a4, .LBB1_4
	j	.LBB1_1
.LBB1_5:                                # %for.cond.cleanup
	ret
.Lfunc_end1:
	.size	pattern5_2d_pointerB, .Lfunc_end1-pattern5_2d_pointerB
	.cfi_endproc
                                        # -- End function
	.option	pop
	.option	push
	.option	arch, +a, +c, +d, +f, +m, +zaamo, +zalrsc, +zca, +zcd, +zicsr, +zifencei, +zmmul
	.globl	main                            # -- Begin function main
	.p2align	1
	.type	main,@function
main:                                   # @main
	.cfi_startproc
# %bb.0:                                # %entry
	addi	sp, sp, -32
	.cfi_def_cfa_offset 32
	sd	ra, 24(sp)                      # 8-byte Folded Spill
	sd	s0, 16(sp)                      # 8-byte Folded Spill
	sd	s1, 8(sp)                       # 8-byte Folded Spill
	.cfi_offset ra, -8
	.cfi_offset s0, -16
	.cfi_offset s1, -24
	li	a0, 30
	li	a1, 4
	call	calloc
	mv	s0, a0
	li	a0, 300
	li	a1, 4
	call	calloc
	mv	s1, a0
	li	a2, 30
	li	a3, 15
	li	a4, 20
	mv	a0, s0
	mv	a1, s1
	call	pattern5_2d_pointer
	mv	a0, s0
	call	free
	mv	a0, s1
	call	free
	li	a0, 50
	li	a1, 4
	call	calloc
	mv	s0, a0
	li	a0, 600
	li	a1, 4
	call	calloc
	mv	s1, a0
	li	a2, 50
	li	a3, 20
	li	a4, 30
	mv	a0, s0
	mv	a1, s1
	call	pattern5_2d_pointer
	mv	a0, s0
	call	free
	mv	a0, s1
	call	free
	li	a0, 0
	ld	ra, 24(sp)                      # 8-byte Folded Reload
	ld	s0, 16(sp)                      # 8-byte Folded Reload
	ld	s1, 8(sp)                       # 8-byte Folded Reload
	.cfi_restore ra
	.cfi_restore s0
	.cfi_restore s1
	addi	sp, sp, 32
	.cfi_def_cfa_offset 0
	ret
.Lfunc_end2:
	.size	main, .Lfunc_end2-main
	.cfi_endproc
                                        # -- End function
	.option	pop
	.ident	"clang version 24.0.0git (git@github.com:isa-Lai/llvm-project.git 0ccca49fbdf066b1df3977840d128c8872a444c6)"
	.section	".note.GNU-stack","",@progbits
