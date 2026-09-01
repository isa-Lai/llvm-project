	.attribute	4, 16
	.attribute	5, "rv64i2p1_m2p0_a2p1_f2p2_d2p2_c2p0_zicsr2p0_zifencei2p0_zmmul1p0_zaamo1p0_zalrsc1p0_zca1p0_zcd1p0"
	.file	"pattern8_3d_fixed.c"
	.option	push
	.option	arch, +a, +c, +d, +f, +m, +zaamo, +zalrsc, +zca, +zcd, +zicsr, +zifencei, +zmmul
	.text
	.globl	pattern8_3d_fixed               # -- Begin function pattern8_3d_fixed
	.p2align	1
	.type	pattern8_3d_fixed,@function
pattern8_3d_fixed:                      # @pattern8_3d_fixed
	.cfi_startproc
# %bb.0:                                # %entry
	addi	sp, sp, -176
	.cfi_def_cfa_offset 176
	sd	ra, 168(sp)                     # 8-byte Folded Spill
	sd	s0, 160(sp)                     # 8-byte Folded Spill
	sd	s1, 152(sp)                     # 8-byte Folded Spill
	sd	s2, 144(sp)                     # 8-byte Folded Spill
	sd	s3, 136(sp)                     # 8-byte Folded Spill
	sd	s4, 128(sp)                     # 8-byte Folded Spill
	sd	s5, 120(sp)                     # 8-byte Folded Spill
	sd	s6, 112(sp)                     # 8-byte Folded Spill
	sd	s7, 104(sp)                     # 8-byte Folded Spill
	sd	s8, 96(sp)                      # 8-byte Folded Spill
	sd	s9, 88(sp)                      # 8-byte Folded Spill
	sd	s10, 80(sp)                     # 8-byte Folded Spill
	sd	s11, 72(sp)                     # 8-byte Folded Spill
	.cfi_offset ra, -8
	.cfi_offset s0, -16
	.cfi_offset s1, -24
	.cfi_offset s2, -32
	.cfi_offset s3, -40
	.cfi_offset s4, -48
	.cfi_offset s5, -56
	.cfi_offset s6, -64
	.cfi_offset s7, -72
	.cfi_offset s8, -80
	.cfi_offset s9, -88
	.cfi_offset s10, -96
	.cfi_offset s11, -104
	mv	s0, a2
	mv	s1, a1
	li	s3, 0
	sd	a0, 8(sp)                       # 8-byte Folded Spill
	li	t0, 195
	csrw	2050, t0
	li	t1, 8
	csrw	2051, t1
	li	t0, 5
	slli	t0, t0, 49
	addi	t0, t0, 192
	csrw	2060, t0
	lui	t1, 16
	csrw	2061, t1
	li	t0, 5
	slli	t0, t0, 49
	addi	t0, t0, 192
	csrw	2062, t0
	csrw	2063, t1
	li	t0, 5
	slli	t0, t0, 49
	addi	t0, t0, 1984
	csrw	2064, t0
	csrw	2065, t1
	li	t0, 125
	slli	t0, t0, 51
	addi	t0, t0, 192
	csrw	2066, t0
	csrw	2067, t1
	li	t0, 25
	slli	t0, t0, 50
	addi	t0, t0, 192
	csrw	2068, t0
	csrw	2069, t1
	lui	t0, 20
	addi	t0, t0, 1729
	csrw	2072, t0
	li	t1, 4
	csrw	2073, t1
	lui	t0, 20
	addi	t0, t0, 1985
	csrw	2076, t0
	li	t1, 4
	csrw	2077, t1
	lui	t0, 21
	addi	t0, t0, -1855
	csrw	2080, t0
	li	t1, 4
	csrw	2081, t1
	lui	t0, 1
	addi	t0, t0, 194
	csrw	2082, t0
	li	t1, 4
	csrw	2083, t1
	li	t0, 194
	csrw	2088, t0
	li	t1, 4
	csrw	2089, t1
	lui	a0, 419430
	addi	s5, a0, 1639
	li	s6, 400
	sd	a1, 16(sp)                      # 8-byte Folded Spill
	j	.LBB0_2
.LBB0_1:                                # %for.cond.cleanup3
                                        #   in Loop: Header=BB0_2 Depth=1
	addiw	s3, s3, 1
	ld	a0, 16(sp)                      # 8-byte Folded Reload
	addi	a0, a0, 400
	sd	a0, 16(sp)                      # 8-byte Folded Spill
.LBB0_2:                                # %for.cond
                                        # =>This Loop Header: Depth=1
                                        #     Child Loop BB0_5 Depth 2
                                        #       Child Loop BB0_8 Depth 3
	li	a0, 10
	bge	s3, a0, .LBB0_11
# %bb.3:                                # %for.body
                                        #   in Loop: Header=BB0_2 Depth=1
	li	a2, 0
	mul	s9, s3, s6
	slli	a0, s3, 2
	ld	a1, 8(sp)                       # 8-byte Folded Reload
	add	a0, a0, a1
	sd	a0, 48(sp)                      # 8-byte Folded Spill
	add	a0, s1, s9
	sd	a0, 0(sp)                       # 8-byte Folded Spill
	ld	s4, 16(sp)                      # 8-byte Folded Reload
	mv	s11, s1
	j	.LBB0_5
.LBB0_4:                                # %for.cond.cleanup7
                                        #   in Loop: Header=BB0_5 Depth=2
	ld	a2, 40(sp)                      # 8-byte Folded Reload
	addiw	a2, a2, 1
	ld	s11, 24(sp)                     # 8-byte Folded Reload
	addi	s11, s11, 40
	ld	s4, 32(sp)                      # 8-byte Folded Reload
	addi	s4, s4, 40
.LBB0_5:                                # %for.cond1
                                        #   Parent Loop BB0_2 Depth=1
                                        # =>  This Loop Header: Depth=2
                                        #       Child Loop BB0_8 Depth 3
	li	a0, 10
	bge	a2, a0, .LBB0_1
# %bb.6:                                # %for.body4
                                        #   in Loop: Header=BB0_5 Depth=2
	li	s2, 0
	slli	s7, a2, 3
	slli	a0, a2, 5
	sd	a2, 40(sp)                      # 8-byte Folded Spill
	slli	a1, a2, 2
	add	s7, s7, a0
	ld	s10, 8(sp)                      # 8-byte Folded Reload
	add	a1, a1, s10
	sd	a1, 64(sp)                      # 8-byte Folded Spill
	ld	a0, 0(sp)                       # 8-byte Folded Reload
	add	a0, a0, s7
	sd	a0, 56(sp)                      # 8-byte Folded Spill
	sd	s4, 32(sp)                      # 8-byte Folded Spill
	sd	s11, 24(sp)                     # 8-byte Folded Spill
	ld	s8, 16(sp)                      # 8-byte Folded Reload
	j	.LBB0_8
.LBB0_7:                                # %if.end
                                        #   in Loop: Header=BB0_8 Depth=3
	call	rand
	mul	a1, a0, s5
	srli	a2, a1, 63
	srai	a1, a1, 34
	add	a1, a1, a2
	slli	a2, a1, 1
	slli	a1, a1, 3
	add	a1, a1, a2
	subw	a0, a0, a1
	mul	a0, a0, s6
	add	a0, a0, s11
	lw	a1, 0(a0)
	addi	a1, a1, 1
	sw	a1, 0(a0)
	call	rand
	mul	a1, a0, s5
	srli	a2, a1, 63
	srai	a1, a1, 34
	add	a1, a1, a2
	slli	a2, a1, 1
	slli	a1, a1, 3
	add	a1, a1, a2
	subw	a0, a0, a1
	slli	a1, a0, 3
	slli	a0, a0, 5
	add	a0, a0, a1
	add	a0, a0, s8
	lw	a1, 0(a0)
	addi	a1, a1, 1
	sw	a1, 0(a0)
	call	rand
	add	a1, s1, s7
	mul	a2, a0, s5
	srli	a3, a2, 63
	srai	a2, a2, 34
	add	a2, a2, a3
	slli	a3, a2, 1
	slli	a2, a2, 3
	add	a2, a2, a3
	subw	a0, a0, a2
	add	a1, a1, s9
	slli	a0, a0, 2
	add	a0, a0, a1
	lw	a1, 0(a0)
	addiw	s2, s2, 1
	addi	s8, s8, 4
	addi	a1, a1, 1
	addi	s11, s11, 4
	sw	a1, 0(a0)
	addi	s10, s10, 4
	addi	s4, s4, 4
.LBB0_8:                                # %for.cond5
                                        #   Parent Loop BB0_2 Depth=1
                                        #     Parent Loop BB0_5 Depth=2
                                        # =>    This Inner Loop Header: Depth=3
	li	a0, 10
	bge	s2, a0, .LBB0_4
# %bb.9:                                # %for.body8
                                        #   in Loop: Header=BB0_8 Depth=3
	lw	a0, 0(s4)
	addi	a0, a0, 1
	sw	a0, 0(s4)
	bge	s3, s0, .LBB0_7
# %bb.10:                               # %if.then
                                        #   in Loop: Header=BB0_8 Depth=3
	ld	a0, 48(sp)                      # 8-byte Folded Reload
	lw	a0, 0(a0)
	mul	a1, a0, s5
	srli	a2, a1, 63
	srai	a1, a1, 34
	add	a1, a1, a2
	slli	a2, a1, 1
	slli	a1, a1, 3
	add	a1, a1, a2
	subw	a0, a0, a1
	mul	a0, a0, s6
	add	a0, a0, s11
	lw	a1, 0(a0)
	addi	a1, a1, 1
	sw	a1, 0(a0)
	ld	a0, 64(sp)                      # 8-byte Folded Reload
	lw	a0, 0(a0)
	mul	a1, a0, s5
	srli	a2, a1, 63
	srai	a1, a1, 34
	add	a1, a1, a2
	slli	a2, a1, 1
	slli	a1, a1, 3
	add	a1, a1, a2
	subw	a0, a0, a1
	slli	a1, a0, 3
	slli	a0, a0, 5
	add	a0, a0, a1
	add	a0, a0, s8
	lw	a1, 0(a0)
	addi	a1, a1, 1
	sw	a1, 0(a0)
	lw	a0, 0(s10)
	mul	a1, a0, s5
	srli	a2, a1, 63
	srai	a1, a1, 34
	add	a1, a1, a2
	slli	a2, a1, 1
	slli	a1, a1, 3
	add	a1, a1, a2
	subw	a0, a0, a1
	slli	a0, a0, 2
	ld	a1, 56(sp)                      # 8-byte Folded Reload
	add	a0, a0, a1
	lw	a1, 0(a0)
	addi	a1, a1, 1
	sw	a1, 0(a0)
	j	.LBB0_7
.LBB0_11:                               # %for.cond.cleanup
	ld	ra, 168(sp)                     # 8-byte Folded Reload
	ld	s0, 160(sp)                     # 8-byte Folded Reload
	ld	s1, 152(sp)                     # 8-byte Folded Reload
	ld	s2, 144(sp)                     # 8-byte Folded Reload
	ld	s3, 136(sp)                     # 8-byte Folded Reload
	ld	s4, 128(sp)                     # 8-byte Folded Reload
	ld	s5, 120(sp)                     # 8-byte Folded Reload
	ld	s6, 112(sp)                     # 8-byte Folded Reload
	ld	s7, 104(sp)                     # 8-byte Folded Reload
	ld	s8, 96(sp)                      # 8-byte Folded Reload
	ld	s9, 88(sp)                      # 8-byte Folded Reload
	ld	s10, 80(sp)                     # 8-byte Folded Reload
	ld	s11, 72(sp)                     # 8-byte Folded Reload
	.cfi_restore ra
	.cfi_restore s0
	.cfi_restore s1
	.cfi_restore s2
	.cfi_restore s3
	.cfi_restore s4
	.cfi_restore s5
	.cfi_restore s6
	.cfi_restore s7
	.cfi_restore s8
	.cfi_restore s9
	.cfi_restore s10
	.cfi_restore s11
	addi	sp, sp, 176
	.cfi_def_cfa_offset 0
	ret
.Lfunc_end0:
	.size	pattern8_3d_fixed, .Lfunc_end0-pattern8_3d_fixed
	.cfi_endproc
                                        # -- End function
	.option	pop
	.option	push
	.option	arch, +a, +c, +d, +f, +m, +zaamo, +zalrsc, +zca, +zcd, +zicsr, +zifencei, +zmmul
	.globl	pattern8_3d_fixedB              # -- Begin function pattern8_3d_fixedB
	.p2align	1
	.type	pattern8_3d_fixedB,@function
pattern8_3d_fixedB:                     # @pattern8_3d_fixedB
	.cfi_startproc
# %bb.0:                                # %entry
	li	a0, 0
	li	t0, 125
	slli	t0, t0, 51
	addi	t0, t0, 192
	csrw	2050, t0
	lui	t1, 16
	csrw	2051, t1
	li	a2, 10
	j	.LBB1_2
.LBB1_1:                                # %for.cond.cleanup3
                                        #   in Loop: Header=BB1_2 Depth=1
	addiw	a0, a0, 1
	addi	a1, a1, 400
.LBB1_2:                                # %for.cond
                                        # =>This Loop Header: Depth=1
                                        #     Child Loop BB1_5 Depth 2
                                        #       Child Loop BB1_7 Depth 3
	bge	a0, a2, .LBB1_8
# %bb.3:                                # %for.body
                                        #   in Loop: Header=BB1_2 Depth=1
	li	a3, 0
	mv	a4, a1
	j	.LBB1_5
.LBB1_4:                                # %for.cond.cleanup7
                                        #   in Loop: Header=BB1_5 Depth=2
	addiw	a3, a3, 1
	addi	a4, a4, 40
.LBB1_5:                                # %for.cond1
                                        #   Parent Loop BB1_2 Depth=1
                                        # =>  This Loop Header: Depth=2
                                        #       Child Loop BB1_7 Depth 3
	bge	a3, a2, .LBB1_1
# %bb.6:                                # %for.body4
                                        #   in Loop: Header=BB1_5 Depth=2
	li	a5, 0
	mv	a6, a4
	blez	a2, .LBB1_4
.LBB1_7:                                # %for.body8
                                        #   Parent Loop BB1_2 Depth=1
                                        #     Parent Loop BB1_5 Depth=2
                                        # =>    This Inner Loop Header: Depth=3
	lw	a7, 0(a6)
	addi	a7, a7, 1
	sw	a7, 0(a6)
	addiw	a5, a5, 1
	addi	a6, a6, 4
	blt	a5, a2, .LBB1_7
	j	.LBB1_4
.LBB1_8:                                # %for.cond.cleanup
	ret
.Lfunc_end1:
	.size	pattern8_3d_fixedB, .Lfunc_end1-pattern8_3d_fixedB
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
	li	a1, 400
	call	calloc
	mv	s1, a0
	li	a2, 50
	mv	a0, s0
	mv	a1, s1
	call	pattern8_3d_fixed
	mv	a0, s0
	call	free
	mv	a0, s1
	call	free
	li	a0, 100
	li	a1, 4
	call	calloc
	mv	s0, a0
	li	a0, 10
	li	a1, 400
	call	calloc
	mv	s1, a0
	li	a2, 100
	mv	a0, s0
	mv	a1, s1
	call	pattern8_3d_fixed
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
