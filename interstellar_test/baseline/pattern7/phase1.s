	.attribute	4, 16
	.attribute	5, "rv64i2p1_m2p0_a2p1_f2p2_d2p2_c2p0_zicsr2p0_zifencei2p0_zmmul1p0_zaamo1p0_zalrsc1p0_zca1p0_zcd1p0"
	.file	"pattern7_2d_fixed.c"
	.option	push
	.option	arch, +a, +c, +d, +f, +m, +zaamo, +zalrsc, +zca, +zcd, +zicsr, +zifencei, +zmmul
	.text
	.globl	pattern7_2d_fixed               # -- Begin function pattern7_2d_fixed
	.p2align	1
	.type	pattern7_2d_fixed,@function
pattern7_2d_fixed:                      # @pattern7_2d_fixed
	.cfi_startproc
# %bb.0:                                # %entry
	li	a3, 0
	li	a4, 0
	li	t0, 195
	csrw	2050, t0
	li	t1, 8
	csrw	2051, t1
	li	t0, 5
	slli	t0, t0, 49
	addi	t0, t0, 192
	csrw	2054, t0
	lui	t1, 16
	csrw	2055, t1
	li	t0, 5
	slli	t0, t0, 49
	addi	t0, t0, 192
	csrw	2056, t0
	csrw	2057, t1
	li	t0, 25
	slli	t0, t0, 50
	addi	t0, t0, 192
	csrw	2058, t0
	csrw	2059, t1
	lui	t0, 20
	addi	t0, t0, 961
	csrw	2062, t0
	li	t1, 4
	csrw	2063, t1
	lui	t0, 20
	addi	t0, t0, 1217
	csrw	2066, t0
	li	t1, 4
	csrw	2067, t1
	lui	t0, 1
	addi	t0, t0, -1598
	csrw	2068, t0
	li	t1, 4
	csrw	2069, t1
	lui	a6, 419430
	li	a5, 10
	addi	a6, a6, 1639
	j	.LBB0_2
.LBB0_1:                                # %for.cond.cleanup3
                                        #   in Loop: Header=BB0_2 Depth=1
	addiw	a4, a4, 1
	addi	a3, a3, 40
.LBB0_2:                                # %for.cond
                                        # =>This Loop Header: Depth=1
                                        #     Child Loop BB0_5 Depth 2
	bge	a4, a5, .LBB0_8
# %bb.3:                                # %for.body
                                        #   in Loop: Header=BB0_2 Depth=1
	li	a7, 0
	slli	t0, a4, 3
	slli	t1, a4, 5
	slli	t2, a4, 2
	add	t1, t1, t0
	add	t0, a0, t2
	add	t1, t1, a1
	mv	t2, a1
	mv	t3, a0
	j	.LBB0_5
.LBB0_4:                                # %if.end
                                        #   in Loop: Header=BB0_5 Depth=2
	addiw	a7, a7, 1
	addi	t3, t3, 4
	addi	t2, t2, 4
.LBB0_5:                                # %for.cond1
                                        #   Parent Loop BB0_2 Depth=1
                                        # =>  This Inner Loop Header: Depth=2
	bge	a7, a5, .LBB0_1
# %bb.6:                                # %for.body4
                                        #   in Loop: Header=BB0_5 Depth=2
	add	t4, t2, a3
	lw	t5, 0(t4)
	addi	t5, t5, 1
	sw	t5, 0(t4)
	bge	a4, a2, .LBB0_4
# %bb.7:                                # %if.then
                                        #   in Loop: Header=BB0_5 Depth=2
	lw	t4, 0(t0)
	mul	t5, t4, a6
	srli	t6, t5, 63
	srai	t5, t5, 34
	add	t5, t5, t6
	slli	t6, t5, 1
	slli	t5, t5, 3
	add	t5, t5, t6
	subw	t4, t4, t5
	slli	t5, t4, 3
	slli	t4, t4, 5
	add	t4, t4, t5
	add	t4, t4, t2
	lw	t5, 0(t4)
	addi	t5, t5, 1
	sw	t5, 0(t4)
	lw	t4, 0(t3)
	mul	t5, t4, a6
	srli	t6, t5, 63
	srai	t5, t5, 34
	add	t5, t5, t6
	slli	t6, t5, 1
	slli	t5, t5, 3
	add	t5, t5, t6
	subw	t4, t4, t5
	slli	t4, t4, 2
	add	t4, t4, t1
	lw	t5, 0(t4)
	addi	t5, t5, 1
	sw	t5, 0(t4)
	j	.LBB0_4
.LBB0_8:                                # %for.cond.cleanup
	ret
.Lfunc_end0:
	.size	pattern7_2d_fixed, .Lfunc_end0-pattern7_2d_fixed
	.cfi_endproc
                                        # -- End function
	.option	pop
	.option	push
	.option	arch, +a, +c, +d, +f, +m, +zaamo, +zalrsc, +zca, +zcd, +zicsr, +zifencei, +zmmul
	.globl	pattern7_2d_fixedB              # -- Begin function pattern7_2d_fixedB
	.p2align	1
	.type	pattern7_2d_fixedB,@function
pattern7_2d_fixedB:                     # @pattern7_2d_fixedB
	.cfi_startproc
# %bb.0:                                # %entry
	li	a0, 0
	li	t0, 25
	slli	t0, t0, 50
	addi	t0, t0, 192
	csrw	2050, t0
	lui	t1, 16
	csrw	2051, t1
	li	a2, 10
	j	.LBB1_2
.LBB1_1:                                # %for.cond.cleanup3
                                        #   in Loop: Header=BB1_2 Depth=1
	addiw	a0, a0, 1
	addi	a1, a1, 40
.LBB1_2:                                # %for.cond
                                        # =>This Loop Header: Depth=1
                                        #     Child Loop BB1_4 Depth 2
	bge	a0, a2, .LBB1_5
# %bb.3:                                # %for.body
                                        #   in Loop: Header=BB1_2 Depth=1
	li	a3, 0
	mv	a4, a1
	blez	a2, .LBB1_1
.LBB1_4:                                # %for.body4
                                        #   Parent Loop BB1_2 Depth=1
                                        # =>  This Inner Loop Header: Depth=2
	lw	a5, 0(a4)
	addi	a5, a5, 1
	sw	a5, 0(a4)
	addiw	a3, a3, 1
	addi	a4, a4, 4
	blt	a3, a2, .LBB1_4
	j	.LBB1_1
.LBB1_5:                                # %for.cond.cleanup
	ret
.Lfunc_end1:
	.size	pattern7_2d_fixedB, .Lfunc_end1-pattern7_2d_fixedB
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
	li	a0, 50
	li	a1, 4
	call	calloc
	mv	s0, a0
	li	a0, 10
	li	a1, 40
	call	calloc
	mv	s1, a0
	li	a2, 50
	mv	a0, s0
	mv	a1, s1
	call	pattern7_2d_fixed
	mv	a0, s0
	call	free
	mv	a0, s1
	call	free
	li	a0, 100
	li	a1, 4
	call	calloc
	mv	s0, a0
	li	a0, 10
	li	a1, 40
	call	calloc
	mv	s1, a0
	li	a2, 100
	mv	a0, s0
	mv	a1, s1
	call	pattern7_2d_fixed
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
