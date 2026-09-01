	.attribute	4, 16
	.attribute	5, "rv64i2p1_m2p0_a2p1_f2p2_d2p2_c2p0_zicsr2p0_zifencei2p0_zmmul1p0_zaamo1p0_zalrsc1p0_zca1p0_zcd1p0"
	.file	"pattern6_3d_pointer.c"
	.option	push
	.option	arch, +a, +c, +d, +f, +m, +zaamo, +zalrsc, +zca, +zcd, +zicsr, +zifencei, +zmmul
	.text
	.globl	pattern6_3d_pointer             # -- Begin function pattern6_3d_pointer
	.p2align	1
	.type	pattern6_3d_pointer,@function
pattern6_3d_pointer:                    # @pattern6_3d_pointer
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
	mv	s0, a5
	mv	s2, a3
	sd	a2, 48(sp)                      # 8-byte Folded Spill
	mv	s4, a1
	sd	zero, 16(sp)                    # 8-byte Folded Spill
	li	a3, 0
	mul	a1, a5, a4
	sd	a1, 56(sp)                      # 8-byte Folded Spill
	mul	a2, a1, s2
	sd	a4, 64(sp)                      # 8-byte Folded Spill
	slli	a1, a4, 32
	srli	a1, a1, 32
	lui	t0, 16
	addi	t0, t0, 195
	csrw	2050, t0
	li	t1, 4
	csrw	2051, t1
	slli	a1, a5, 32
	srli	a1, a1, 32
	sd	a0, 8(sp)                       # 8-byte Folded Spill
	li	t0, 195
	csrw	2054, t0
	li	t1, 8
	csrw	2055, t1
	lui	t0, 16
	addi	t0, t0, 195
	csrw	2052, t0
	li	t1, 4
	csrw	2053, t1
	slli	a1, s2, 32
	srli	a1, a1, 32
	slli	a0, a2, 32
	lui	t0, 320
	addi	t0, t0, 195
	csrw	2056, t0
	li	t1, 8
	csrw	2057, t1
	srli	a0, a0, 32
	lui	t0, 16
	addi	t0, t0, 195
	csrw	2048, t0
	li	t1, 4
	csrw	2049, t1
	li	t0, 195
	csrw	2058, t0
	li	t1, 4
	csrw	2059, t1
	lui	t0, 8
	addi	t0, t0, 192
	csrw	2060, t0
	lui	t1, 16
	csrw	2061, t1
	li	t0, 1
	slli	t0, t0, 42
	addi	t0, t0, 515
	slli	t0, t0, 6
	csrw	2062, t0
	csrw	2063, t1
	li	t0, 1
	slli	t0, t0, 43
	addi	t0, t0, 543
	slli	t0, t0, 6
	csrw	2064, t0
	csrw	2065, t1
	li	t0, 5
	slli	t0, t0, 42
	addi	t0, t0, 515
	slli	t0, t0, 6
	csrw	2066, t0
	csrw	2067, t1
	lui	t0, 21
	addi	t0, t0, -1599
	csrw	2068, t0
	li	t1, 4
	csrw	2069, t1
	lui	t0, 52
	addi	t0, t0, 1729
	csrw	2070, t0
	li	t1, 4
	csrw	2071, t1
	lui	t0, 21
	addi	t0, t0, -1855
	csrw	2072, t0
	li	t1, 4
	csrw	2073, t1
	lui	t0, 52
	addi	t0, t0, 1985
	csrw	2074, t0
	li	t1, 4
	csrw	2075, t1
	lui	t0, 37
	addi	t0, t0, -1855
	csrw	2076, t0
	li	t1, 4
	csrw	2077, t1
	lui	t0, 53
	addi	t0, t0, -1855
	csrw	2078, t0
	li	t1, 4
	csrw	2079, t1
	lui	t0, 69
	addi	t0, t0, -62
	csrw	2080, t0
	li	t1, 4
	csrw	2081, t1
	lui	t0, 68
	addi	t0, t0, 194
	csrw	2082, t0
	li	t1, 4
	csrw	2083, t1
	j	.LBB0_2
.LBB0_1:                                # %for.cond.cleanup3
                                        #   in Loop: Header=BB0_2 Depth=1
	addiw	a3, a3, 1
	ld	a0, 16(sp)                      # 8-byte Folded Reload
	ld	a1, 56(sp)                      # 8-byte Folded Reload
	add	a0, a0, a1
	sd	a0, 16(sp)                      # 8-byte Folded Spill
.LBB0_2:                                # %for.cond
                                        # =>This Loop Header: Depth=1
                                        #     Child Loop BB0_5 Depth 2
                                        #       Child Loop BB0_8 Depth 3
	bge	a3, s2, .LBB0_13
# %bb.3:                                # %for.body
                                        #   in Loop: Header=BB0_2 Depth=1
	sd	zero, 40(sp)                    # 8-byte Folded Spill
	li	a1, 0
	ld	a0, 64(sp)                      # 8-byte Folded Reload
	mul	a0, a3, a0
	mul	a0, a0, s0
	sd	a0, 0(sp)                       # 8-byte Folded Spill
	slli	s5, a3, 2
	ld	a0, 8(sp)                       # 8-byte Folded Reload
	add	s5, s5, a0
	ld	s11, 16(sp)                     # 8-byte Folded Reload
	j	.LBB0_5
.LBB0_4:                                # %for.cond.cleanup7
                                        #   in Loop: Header=BB0_5 Depth=2
	ld	a1, 24(sp)                      # 8-byte Folded Reload
	addiw	a1, a1, 1
	ld	a0, 40(sp)                      # 8-byte Folded Reload
	add	a0, a0, s0
	sd	a0, 40(sp)                      # 8-byte Folded Spill
	add	s11, s11, s0
.LBB0_5:                                # %for.cond1
                                        #   Parent Loop BB0_2 Depth=1
                                        # =>  This Loop Header: Depth=2
                                        #       Child Loop BB0_8 Depth 3
	ld	a0, 64(sp)                      # 8-byte Folded Reload
	bge	a1, a0, .LBB0_1
# %bb.6:                                # %for.body4
                                        #   in Loop: Header=BB0_5 Depth=2
	li	s6, 0
	mul	s9, a1, s0
	sd	a1, 24(sp)                      # 8-byte Folded Spill
	slli	a0, a1, 2
	ld	s10, 8(sp)                      # 8-byte Folded Reload
	add	a0, a0, s10
	sd	a0, 32(sp)                      # 8-byte Folded Spill
	ld	a0, 0(sp)                       # 8-byte Folded Reload
	add	s9, s9, a0
	ld	s3, 16(sp)                      # 8-byte Folded Reload
	j	.LBB0_8
.LBB0_7:                                # %if.end
                                        #   in Loop: Header=BB0_8 Depth=3
	call	rand
	remw	s7, a0, s2
	call	rand
	ld	a1, 64(sp)                      # 8-byte Folded Reload
	remw	s1, a0, a1
	call	rand
	remw	a0, a0, s0
	ld	a1, 56(sp)                      # 8-byte Folded Reload
	mul	a1, s7, a1
	mul	a2, s1, s0
	add	a1, a1, a2
	addw	a1, a1, a0
	slli	a1, a1, 2
	add	a1, a1, s4
	lw	a3, 0(a1)
	addw	a2, s3, a2
	slli	a2, a2, 2
	addi	a3, a3, 1
	add	a2, a2, s4
	sw	a3, 0(a1)
	lw	a1, 0(a2)
	addw	a0, s9, a0
	slli	a0, a0, 2
	addi	a1, a1, 1
	add	a0, a0, s4
	sw	a1, 0(a2)
	lw	a1, 0(a0)
	addi	a1, a1, 1
	addiw	s6, s6, 1
	sw	a1, 0(a0)
	addi	s3, s3, 1
	addi	s10, s10, 4
	mv	a3, s8
.LBB0_8:                                # %for.cond5
                                        #   Parent Loop BB0_2 Depth=1
                                        #     Parent Loop BB0_5 Depth=2
                                        # =>    This Inner Loop Header: Depth=3
	bge	s6, s0, .LBB0_4
# %bb.9:                                # %for.body8
                                        #   in Loop: Header=BB0_8 Depth=3
	addw	a0, s11, s6
	slli	a0, a0, 2
	add	a0, a0, s4
	lw	a1, 0(a0)
	addi	a1, a1, 1
	sw	a1, 0(a0)
	ld	a0, 48(sp)                      # 8-byte Folded Reload
	mv	s8, a3
	bge	a3, a0, .LBB0_7
# %bb.10:                               # %land.lhs.true
                                        #   in Loop: Header=BB0_8 Depth=3
	lw	a0, 0(s5)
	bltz	a0, .LBB0_7
# %bb.11:                               # %land.lhs.true16
                                        #   in Loop: Header=BB0_8 Depth=3
	lw	a0, 0(s5)
	bge	a0, s2, .LBB0_7
# %bb.12:                               # %if.then
                                        #   in Loop: Header=BB0_8 Depth=3
	lw	a0, 0(s5)
	ld	a1, 56(sp)                      # 8-byte Folded Reload
	mul	a0, a0, a1
	ld	a1, 40(sp)                      # 8-byte Folded Reload
	add	a1, a1, s6
	addw	a0, a0, a1
	slli	a0, a0, 2
	add	a0, a0, s4
	lw	a1, 0(a0)
	addi	a1, a1, 1
	sw	a1, 0(a0)
	ld	a0, 32(sp)                      # 8-byte Folded Reload
	lw	a0, 0(a0)
	ld	a1, 64(sp)                      # 8-byte Folded Reload
	remw	a0, a0, a1
	mul	a0, a0, s0
	addw	a0, s3, a0
	slli	a0, a0, 2
	add	a0, a0, s4
	lw	a1, 0(a0)
	addi	a1, a1, 1
	sw	a1, 0(a0)
	lw	a0, 0(s10)
	remw	a0, a0, s0
	addw	a0, s9, a0
	slli	a0, a0, 2
	add	a0, a0, s4
	lw	a1, 0(a0)
	addi	a1, a1, 1
	sw	a1, 0(a0)
	j	.LBB0_7
.LBB0_13:                               # %for.cond.cleanup
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
	.size	pattern6_3d_pointer, .Lfunc_end0-pattern6_3d_pointer
	.cfi_endproc
                                        # -- End function
	.option	pop
	.option	push
	.option	arch, +a, +c, +d, +f, +m, +zaamo, +zalrsc, +zca, +zcd, +zicsr, +zifencei, +zmmul
	.globl	pattern6_3d_pointerB            # -- Begin function pattern6_3d_pointerB
	.p2align	1
	.type	pattern6_3d_pointerB,@function
pattern6_3d_pointerB:                   # @pattern6_3d_pointerB
	.cfi_startproc
# %bb.0:                                # %entry
	li	a0, 0
	li	a2, 0
	addiw	a6, a4, -1
	mul	a7, a5, a6
	slli	t0, a4, 32
	mul	a4, a5, a4
	srli	t0, t0, 32
	lui	t0, 80
	addi	t0, t0, 195
	csrw	2054, t0
	li	t1, 4
	csrw	2055, t1
	slli	t0, a3, 32
	srli	t0, t0, 32
	slli	a7, a7, 32
	lui	t0, 80
	addi	t0, t0, 195
	csrw	2048, t0
	li	t1, 4
	csrw	2049, t1
	srli	a7, a7, 32
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
	slli	t0, t0, 44
	addi	t0, t0, 515
	slli	t0, t0, 6
	csrw	2060, t0
	csrw	2061, t1
	lui	t0, 52
	addi	t0, t0, 1729
	csrw	2062, t0
	li	t1, 4
	csrw	2063, t1
	j	.LBB1_2
.LBB1_1:                                # %for.cond.cleanup3
                                        #   in Loop: Header=BB1_2 Depth=1
	addiw	a2, a2, 1
	addw	a0, a0, a4
.LBB1_2:                                # %for.cond
                                        # =>This Loop Header: Depth=1
                                        #     Child Loop BB1_5 Depth 2
                                        #       Child Loop BB1_7 Depth 3
	bge	a2, a3, .LBB1_8
# %bb.3:                                # %for.body
                                        #   in Loop: Header=BB1_2 Depth=1
	li	a7, 0
	mv	t0, a0
	j	.LBB1_5
.LBB1_4:                                # %for.cond.cleanup7
                                        #   in Loop: Header=BB1_5 Depth=2
	addiw	a7, a7, 1
	addw	t0, t0, a5
.LBB1_5:                                # %for.cond1
                                        #   Parent Loop BB1_2 Depth=1
                                        # =>  This Loop Header: Depth=2
                                        #       Child Loop BB1_7 Depth 3
	bge	a7, a6, .LBB1_1
# %bb.6:                                # %for.body4
                                        #   in Loop: Header=BB1_5 Depth=2
	li	t1, 0
	mv	t2, t0
	blez	a5, .LBB1_4
.LBB1_7:                                # %for.body8
                                        #   Parent Loop BB1_2 Depth=1
                                        #     Parent Loop BB1_5 Depth=2
                                        # =>    This Inner Loop Header: Depth=3
	slli	t3, t2, 2
	add	t3, t3, a1
	lw	t4, 0(t3)
	addi	t4, t4, 1
	sw	t4, 0(t3)
	addiw	t1, t1, 1
	addiw	t2, t2, 1
	blt	t1, a5, .LBB1_7
	j	.LBB1_4
.LBB1_8:                                # %for.cond.cleanup
	ret
.Lfunc_end1:
	.size	pattern6_3d_pointerB, .Lfunc_end1-pattern6_3d_pointerB
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
	li	a0, 15
	li	a1, 4
	call	calloc
	mv	s0, a0
	li	a0, 960
	li	a1, 4
	call	calloc
	mv	s1, a0
	li	a2, 15
	li	a3, 8
	li	a4, 10
	li	a5, 12
	mv	a0, s0
	mv	a1, s1
	call	pattern6_3d_pointer
	mv	a0, s0
	call	free
	mv	a0, s1
	call	free
	li	a0, 20
	li	a1, 4
	call	calloc
	mv	s0, a0
	li	a0, 1800
	li	a1, 4
	call	calloc
	mv	s1, a0
	li	a2, 20
	li	a3, 10
	li	a4, 12
	li	a5, 15
	mv	a0, s0
	mv	a1, s1
	call	pattern6_3d_pointer
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
