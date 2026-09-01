	.attribute	4, 16
	.attribute	5, "rv64i2p1_m2p0_a2p1_f2p2_d2p2_c2p0_zicsr2p0_zifencei2p0_zmmul1p0_zaamo1p0_zalrsc1p0_zca1p0_zcd1p0"
	.file	"patternB_4level_nesting.c"
	.option	push
	.option	arch, +a, +c, +d, +f, +m, +zaamo, +zalrsc, +zca, +zcd, +zicsr, +zifencei, +zmmul
	.text
	.globl	patternB_4level_nesting         # -- Begin function patternB_4level_nesting
	.p2align	1
	.type	patternB_4level_nesting,@function
patternB_4level_nesting:                # @patternB_4level_nesting
	.cfi_startproc
# %bb.0:                                # %entry
	addi	sp, sp, -80
	.cfi_def_cfa_offset 80
	sd	s0, 72(sp)                      # 8-byte Folded Spill
	sd	s1, 64(sp)                      # 8-byte Folded Spill
	sd	s2, 56(sp)                      # 8-byte Folded Spill
	sd	s3, 48(sp)                      # 8-byte Folded Spill
	sd	s4, 40(sp)                      # 8-byte Folded Spill
	sd	s5, 32(sp)                      # 8-byte Folded Spill
	sd	s6, 24(sp)                      # 8-byte Folded Spill
	sd	s7, 16(sp)                      # 8-byte Folded Spill
	sd	s8, 8(sp)                       # 8-byte Folded Spill
	sd	s9, 0(sp)                       # 8-byte Folded Spill
	.cfi_offset s0, -8
	.cfi_offset s1, -16
	.cfi_offset s2, -24
	.cfi_offset s3, -32
	.cfi_offset s4, -40
	.cfi_offset s5, -48
	.cfi_offset s6, -56
	.cfi_offset s7, -64
	.cfi_offset s8, -72
	.cfi_offset s9, -80
	ld	t2, 80(sp)
	mul	t3, t2, a7
	mul	t4, t3, a6
	li	t0, 195
	csrw	2056, t0
	li	t1, 8
	csrw	2057, t1
	lui	t0, 16
	addi	t0, t0, 195
	csrw	2058, t0
	li	t1, 8
	csrw	2059, t1
	lui	t0, 32
	addi	t0, t0, 195
	csrw	2060, t0
	li	t1, 8
	csrw	2061, t1
	mul	t5, t4, a5
	lui	t0, 48
	addi	t0, t0, 195
	csrw	2062, t0
	li	t1, 8
	csrw	2063, t1
	slli	t6, a6, 32
	slli	s0, a5, 32
	srli	t6, t6, 32
	lui	t0, 496
	addi	t0, t0, 195
	csrw	2050, t0
	li	t1, 4
	csrw	2051, t1
	slli	t6, a7, 32
	srli	s0, s0, 32
	srli	t6, t6, 32
	lui	t0, 128
	addi	t0, t0, 195
	csrw	2048, t0
	li	t1, 4
	csrw	2049, t1
	lui	t0, 496
	addi	t0, t0, 195
	csrw	2052, t0
	li	t1, 4
	csrw	2053, t1
	slli	t6, t2, 32
	slli	t5, t5, 32
	srli	t6, t6, 32
	srli	t5, t5, 32
	lui	t0, 496
	addi	t0, t0, 195
	csrw	2054, t0
	li	t1, 4
	csrw	2055, t1
	lui	t0, 480
	addi	t0, t0, 195
	csrw	2064, t0
	li	t1, 4
	csrw	2065, t1
	lui	t0, 8
	addi	t0, t0, 192
	csrw	2066, t0
	lui	t1, 16
	csrw	2067, t1
	li	t0, 1
	slli	t0, t0, 42
	addi	t0, t0, 515
	slli	t0, t0, 6
	csrw	2068, t0
	csrw	2069, t1
	li	t0, 1
	slli	t0, t0, 43
	addi	t0, t0, 555
	slli	t0, t0, 6
	csrw	2070, t0
	csrw	2071, t1
	li	t0, 3
	slli	t0, t0, 42
	addi	t0, t0, 559
	slli	t0, t0, 6
	csrw	2072, t0
	csrw	2073, t1
	li	t0, 1
	slli	t0, t0, 45
	addi	t0, t0, 515
	slli	t0, t0, 6
	csrw	2074, t0
	csrw	2075, t1
	lui	t0, 69
	addi	t0, t0, -1599
	csrw	2076, t0
	li	t1, 4
	csrw	2077, t1
	lui	t0, 85
	addi	t0, t0, -1343
	csrw	2078, t0
	li	t1, 4
	csrw	2079, t1
	lui	t0, 101
	addi	t0, t0, -1087
	csrw	2080, t0
	li	t1, 4
	csrw	2081, t1
	lui	t0, 117
	addi	t0, t0, -831
	csrw	2082, t0
	li	t1, 4
	csrw	2083, t1
	lui	t0, 21
	addi	t0, t0, -575
	csrw	2084, t0
	li	t1, 4
	csrw	2085, t1
	j	.LBB0_2
.LBB0_1:                                # %for.cond.cleanup3
                                        #   in Loop: Header=BB0_2 Depth=1
	addiw	t1, t1, 1
	addw	t0, t0, t4
.LBB0_2:                                # %for.cond
                                        # =>This Loop Header: Depth=1
                                        #     Child Loop BB0_5 Depth 2
                                        #       Child Loop BB0_8 Depth 3
                                        #         Child Loop BB0_10 Depth 4
	bge	t1, a5, .LBB0_11
# %bb.3:                                # %for.body
                                        #   in Loop: Header=BB0_2 Depth=1
	li	t5, 0
	slli	t6, t1, 2
	add	t6, t6, a0
	mv	s0, t0
	j	.LBB0_5
.LBB0_4:                                # %for.cond.cleanup7
                                        #   in Loop: Header=BB0_5 Depth=2
	addiw	t5, t5, 1
	addw	s0, s0, t3
.LBB0_5:                                # %for.cond1
                                        #   Parent Loop BB0_2 Depth=1
                                        # =>  This Loop Header: Depth=2
                                        #       Child Loop BB0_8 Depth 3
                                        #         Child Loop BB0_10 Depth 4
	bge	t5, a6, .LBB0_1
# %bb.6:                                # %for.body4
                                        #   in Loop: Header=BB0_5 Depth=2
	li	s1, 0
	slli	s2, t5, 2
	add	s2, s2, a1
	mv	s3, s0
	j	.LBB0_8
.LBB0_7:                                # %for.cond.cleanup11
                                        #   in Loop: Header=BB0_8 Depth=3
	addiw	s1, s1, 1
	addw	s3, s3, t2
.LBB0_8:                                # %for.cond5
                                        #   Parent Loop BB0_2 Depth=1
                                        #     Parent Loop BB0_5 Depth=2
                                        # =>    This Loop Header: Depth=3
                                        #         Child Loop BB0_10 Depth 4
	bge	s1, a7, .LBB0_4
# %bb.9:                                # %for.body8
                                        #   in Loop: Header=BB0_8 Depth=3
	li	s4, 0
	slli	s5, s1, 2
	add	s5, s5, a2
	mv	s6, a3
	mv	s7, s3
	blez	t2, .LBB0_7
.LBB0_10:                               # %for.body12
                                        #   Parent Loop BB0_2 Depth=1
                                        #     Parent Loop BB0_5 Depth=2
                                        #       Parent Loop BB0_8 Depth=3
                                        # =>      This Inner Loop Header: Depth=4
	lw	s8, 0(t6)
	addi	s8, s8, 1
	sw	s8, 0(t6)
	lw	s8, 0(s2)
	addi	s8, s8, 1
	sw	s8, 0(s2)
	lw	s8, 0(s5)
	addi	s8, s8, 1
	sw	s8, 0(s5)
	lw	s8, 0(s6)
	slli	s9, s7, 2
	addi	s8, s8, 1
	add	s9, s9, a4
	sw	s8, 0(s6)
	lw	s8, 0(s9)
	addi	s8, s8, 1
	addiw	s4, s4, 1
	sw	s8, 0(s9)
	addiw	s7, s7, 1
	addi	s6, s6, 4
	blt	s4, t2, .LBB0_10
	j	.LBB0_7
.LBB0_11:                               # %for.cond.cleanup
	ld	s0, 72(sp)                      # 8-byte Folded Reload
	ld	s1, 64(sp)                      # 8-byte Folded Reload
	ld	s2, 56(sp)                      # 8-byte Folded Reload
	ld	s3, 48(sp)                      # 8-byte Folded Reload
	ld	s4, 40(sp)                      # 8-byte Folded Reload
	ld	s5, 32(sp)                      # 8-byte Folded Reload
	ld	s6, 24(sp)                      # 8-byte Folded Reload
	ld	s7, 16(sp)                      # 8-byte Folded Reload
	ld	s8, 8(sp)                       # 8-byte Folded Reload
	ld	s9, 0(sp)                       # 8-byte Folded Reload
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
	addi	sp, sp, 80
	.cfi_def_cfa_offset 0
	ret
.Lfunc_end0:
	.size	patternB_4level_nesting, .Lfunc_end0-patternB_4level_nesting
	.cfi_endproc
                                        # -- End function
	.option	pop
	.option	push
	.option	arch, +a, +c, +d, +f, +m, +zaamo, +zalrsc, +zca, +zcd, +zicsr, +zifencei, +zmmul
	.globl	patternB_4d_array               # -- Begin function patternB_4d_array
	.p2align	1
	.type	patternB_4d_array,@function
patternB_4d_array:                      # @patternB_4d_array
	.cfi_startproc
# %bb.0:                                # %entry
	li	a2, 0
	slli	a3, a1, 32
	srli	a3, a3, 32
	lui	t0, 48
	addi	t0, t0, 195
	csrw	2048, t0
	li	t1, 4
	csrw	2049, t1
	lui	t0, 8
	addi	t0, t0, 192
	csrw	2052, t0
	lui	t1, 16
	csrw	2053, t1
	li	t0, 5
	slli	t0, t0, 49
	addi	t0, t0, 192
	csrw	2054, t0
	csrw	2055, t1
	li	t0, 45
	slli	t0, t0, 49
	addi	t0, t0, 960
	csrw	2056, t0
	csrw	2057, t1
	li	a3, 10
	li	a4, 9
	j	.LBB1_2
.LBB1_1:                                # %for.cond.cleanup3
                                        #   in Loop: Header=BB1_2 Depth=1
	addi	a0, a0, 2047
	addiw	a2, a2, 1
	addi	a0, a0, 1953
.LBB1_2:                                # %for.cond
                                        # =>This Loop Header: Depth=1
                                        #     Child Loop BB1_5 Depth 2
                                        #       Child Loop BB1_8 Depth 3
                                        #         Child Loop BB1_10 Depth 4
	bge	a2, a1, .LBB1_11
# %bb.3:                                # %for.body
                                        #   in Loop: Header=BB1_2 Depth=1
	li	a5, 0
	mv	a6, a0
	j	.LBB1_5
.LBB1_4:                                # %for.cond.cleanup7
                                        #   in Loop: Header=BB1_5 Depth=2
	addiw	a5, a5, 1
	addi	a6, a6, 400
.LBB1_5:                                # %for.cond1
                                        #   Parent Loop BB1_2 Depth=1
                                        # =>  This Loop Header: Depth=2
                                        #       Child Loop BB1_8 Depth 3
                                        #         Child Loop BB1_10 Depth 4
	bge	a5, a3, .LBB1_1
# %bb.6:                                # %for.body4
                                        #   in Loop: Header=BB1_5 Depth=2
	li	a7, 0
	mv	t0, a6
	j	.LBB1_8
.LBB1_7:                                # %for.cond.cleanup11
                                        #   in Loop: Header=BB1_8 Depth=3
	addiw	a7, a7, 1
	addi	t0, t0, 40
.LBB1_8:                                # %for.cond5
                                        #   Parent Loop BB1_2 Depth=1
                                        #     Parent Loop BB1_5 Depth=2
                                        # =>    This Loop Header: Depth=3
                                        #         Child Loop BB1_10 Depth 4
	bge	a7, a4, .LBB1_4
# %bb.9:                                # %for.body8
                                        #   in Loop: Header=BB1_8 Depth=3
	li	t1, 0
	mv	t2, t0
	blez	a3, .LBB1_7
.LBB1_10:                               # %for.body12
                                        #   Parent Loop BB1_2 Depth=1
                                        #     Parent Loop BB1_5 Depth=2
                                        #       Parent Loop BB1_8 Depth=3
                                        # =>      This Inner Loop Header: Depth=4
	lw	t3, 0(t2)
	addi	t3, t3, 1
	sw	t3, 0(t2)
	addiw	t1, t1, 1
	addi	t2, t2, 4
	blt	t1, a3, .LBB1_10
	j	.LBB1_7
.LBB1_11:                               # %for.cond.cleanup
	ret
.Lfunc_end1:
	.size	patternB_4d_array, .Lfunc_end1-patternB_4d_array
	.cfi_endproc
                                        # -- End function
	.option	pop
	.option	push
	.option	arch, +a, +c, +d, +f, +m, +zaamo, +zalrsc, +zca, +zcd, +zicsr, +zifencei, +zmmul
	.globl	patternB_4d_array_pointer       # -- Begin function patternB_4d_array_pointer
	.p2align	1
	.type	patternB_4d_array_pointer,@function
patternB_4d_array_pointer:              # @patternB_4d_array_pointer
	.cfi_startproc
# %bb.0:                                # %entry
	addi	sp, sp, -16
	.cfi_def_cfa_offset 16
	sd	s0, 8(sp)                       # 8-byte Folded Spill
	sd	s1, 0(sp)                       # 8-byte Folded Spill
	.cfi_offset s0, -8
	.cfi_offset s1, -16
	li	a5, 0
	li	a6, 0
	mul	a7, a4, a3
	mul	t0, a7, a2
	mul	t1, t0, a1
	slli	t2, a2, 32
	slli	t1, t1, 32
	srli	t2, t2, 32
	srli	t1, t1, 32
	lui	t0, 112
	addi	t0, t0, 195
	csrw	2050, t0
	li	t1, 4
	csrw	2051, t1
	lui	t0, 96
	addi	t0, t0, 195
	csrw	2056, t0
	li	t1, 4
	csrw	2057, t1
	li	t0, 1
	slli	t0, t0, 44
	addi	t0, t0, 515
	slli	t0, t0, 6
	csrw	2058, t0
	lui	t1, 16
	csrw	2059, t1
	lui	t0, 20
	addi	t0, t0, 1473
	csrw	2060, t0
	li	t1, 4
	csrw	2061, t1
	j	.LBB2_2
.LBB2_1:                                # %for.cond.cleanup3
                                        #   in Loop: Header=BB2_2 Depth=1
	addiw	a6, a6, 1
	addw	a5, a5, t0
.LBB2_2:                                # %for.cond
                                        # =>This Loop Header: Depth=1
                                        #     Child Loop BB2_5 Depth 2
                                        #       Child Loop BB2_8 Depth 3
                                        #         Child Loop BB2_10 Depth 4
	bge	a6, a1, .LBB2_11
# %bb.3:                                # %for.body
                                        #   in Loop: Header=BB2_2 Depth=1
	li	t1, 0
	mv	t2, a5
	j	.LBB2_5
.LBB2_4:                                # %for.cond.cleanup7
                                        #   in Loop: Header=BB2_5 Depth=2
	addiw	t1, t1, 1
	addw	t2, t2, a7
.LBB2_5:                                # %for.cond1
                                        #   Parent Loop BB2_2 Depth=1
                                        # =>  This Loop Header: Depth=2
                                        #       Child Loop BB2_8 Depth 3
                                        #         Child Loop BB2_10 Depth 4
	bge	t1, a2, .LBB2_1
# %bb.6:                                # %for.body4
                                        #   in Loop: Header=BB2_5 Depth=2
	li	t3, 0
	mv	t4, t2
	j	.LBB2_8
.LBB2_7:                                # %for.cond.cleanup11
                                        #   in Loop: Header=BB2_8 Depth=3
	addiw	t3, t3, 1
	addw	t4, t4, a4
.LBB2_8:                                # %for.cond5
                                        #   Parent Loop BB2_2 Depth=1
                                        #     Parent Loop BB2_5 Depth=2
                                        # =>    This Loop Header: Depth=3
                                        #         Child Loop BB2_10 Depth 4
	bge	t3, a3, .LBB2_4
# %bb.9:                                # %for.body8
                                        #   in Loop: Header=BB2_8 Depth=3
	li	t5, 0
	mv	t6, t4
	blez	a4, .LBB2_7
.LBB2_10:                               # %for.body12
                                        #   Parent Loop BB2_2 Depth=1
                                        #     Parent Loop BB2_5 Depth=2
                                        #       Parent Loop BB2_8 Depth=3
                                        # =>      This Inner Loop Header: Depth=4
	slli	s0, t6, 2
	add	s0, s0, a0
	lw	s1, 0(s0)
	addi	s1, s1, 1
	sw	s1, 0(s0)
	addiw	t5, t5, 1
	addiw	t6, t6, 1
	blt	t5, a4, .LBB2_10
	j	.LBB2_7
.LBB2_11:                               # %for.cond.cleanup
	ld	s0, 8(sp)                       # 8-byte Folded Reload
	ld	s1, 0(sp)                       # 8-byte Folded Reload
	.cfi_restore s0
	.cfi_restore s1
	addi	sp, sp, 16
	.cfi_def_cfa_offset 0
	ret
.Lfunc_end2:
	.size	patternB_4d_array_pointer, .Lfunc_end2-patternB_4d_array_pointer
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
	addi	sp, sp, -64
	.cfi_def_cfa_offset 64
	sd	ra, 56(sp)                      # 8-byte Folded Spill
	sd	s0, 48(sp)                      # 8-byte Folded Spill
	sd	s1, 40(sp)                      # 8-byte Folded Spill
	sd	s2, 32(sp)                      # 8-byte Folded Spill
	sd	s3, 24(sp)                      # 8-byte Folded Spill
	sd	s4, 16(sp)                      # 8-byte Folded Spill
	sd	s5, 8(sp)                       # 8-byte Folded Spill
	.cfi_offset ra, -8
	.cfi_offset s0, -16
	.cfi_offset s1, -24
	.cfi_offset s2, -32
	.cfi_offset s3, -40
	.cfi_offset s4, -48
	.cfi_offset s5, -56
	li	a0, 4
	li	a1, 4
	call	calloc
	mv	s0, a0
	li	a0, 5
	li	a1, 4
	call	calloc
	mv	s1, a0
	li	a0, 6
	li	a1, 4
	call	calloc
	mv	s2, a0
	li	a0, 7
	li	a1, 4
	li	s5, 7
	call	calloc
	mv	s3, a0
	li	a0, 840
	li	a1, 4
	call	calloc
	mv	s4, a0
	li	a5, 4
	li	a6, 5
	li	a7, 6
	mv	a0, s0
	mv	a1, s1
	mv	a2, s2
	mv	a3, s3
	mv	a4, s4
	sd	s5, 0(sp)
	call	patternB_4level_nesting
	lw	a1, 0(s0)
	lui	a0, %hi(.L.str)
	addi	a0, a0, %lo(.L.str)
	li	a2, 210
	call	printf
	lw	a1, 0(s1)
	lui	a0, %hi(.L.str.1)
	addi	a0, a0, %lo(.L.str.1)
	li	a2, 168
	call	printf
	lw	a1, 0(s2)
	lui	a0, %hi(.L.str.2)
	addi	a0, a0, %lo(.L.str.2)
	li	a2, 140
	call	printf
	lw	a1, 0(s3)
	lui	a0, %hi(.L.str.3)
	addi	a0, a0, %lo(.L.str.3)
	li	a2, 120
	call	printf
	mv	a0, s0
	call	free
	mv	a0, s1
	call	free
	mv	a0, s2
	call	free
	mv	a0, s3
	call	free
	mv	a0, s4
	call	free
	li	a0, 0
	ld	ra, 56(sp)                      # 8-byte Folded Reload
	ld	s0, 48(sp)                      # 8-byte Folded Reload
	ld	s1, 40(sp)                      # 8-byte Folded Reload
	ld	s2, 32(sp)                      # 8-byte Folded Reload
	ld	s3, 24(sp)                      # 8-byte Folded Reload
	ld	s4, 16(sp)                      # 8-byte Folded Reload
	ld	s5, 8(sp)                       # 8-byte Folded Reload
	.cfi_restore ra
	.cfi_restore s0
	.cfi_restore s1
	.cfi_restore s2
	.cfi_restore s3
	.cfi_restore s4
	.cfi_restore s5
	addi	sp, sp, 64
	.cfi_def_cfa_offset 0
	ret
.Lfunc_end3:
	.size	main, .Lfunc_end3-main
	.cfi_endproc
                                        # -- End function
	.option	pop
	.type	.L.str,@object                  # @.str
	.section	.rodata.str1.1,"aMS",@progbits,1
.L.str:
	.asciz	"A[0] = %d (expected: %d)\n"
	.size	.L.str, 26

	.type	.L.str.1,@object                # @.str.1
.L.str.1:
	.asciz	"B[0] = %d (expected: %d)\n"
	.size	.L.str.1, 26

	.type	.L.str.2,@object                # @.str.2
.L.str.2:
	.asciz	"C[0] = %d (expected: %d)\n"
	.size	.L.str.2, 26

	.type	.L.str.3,@object                # @.str.3
.L.str.3:
	.asciz	"D[0] = %d (expected: %d)\n"
	.size	.L.str.3, 26

	.ident	"clang version 24.0.0git (git@github.com:isa-Lai/llvm-project.git 0ccca49fbdf066b1df3977840d128c8872a444c6)"
	.section	".note.GNU-stack","",@progbits
