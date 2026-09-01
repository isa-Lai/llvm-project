	.attribute	4, 16
	.attribute	5, "rv64i2p1_m2p0_a2p1_f2p2_d2p2_c2p0_zicsr2p0_zifencei2p0_zmmul1p0_zaamo1p0_zalrsc1p0_zca1p0_zcd1p0"
	.file	"pattern9_mixed.c"
	.option	push
	.option	arch, +a, +c, +d, +f, +m, +zaamo, +zalrsc, +zca, +zcd, +zicsr, +zifencei, +zmmul
	.text
	.globl	pattern9_mixed                  # -- Begin function pattern9_mixed
	.p2align	1
	.type	pattern9_mixed,@function
pattern9_mixed:                         # @pattern9_mixed
	.cfi_startproc
# %bb.0:                                # %entry
	addi	sp, sp, -32
	.cfi_def_cfa_offset 32
	sd	s0, 24(sp)                      # 8-byte Folded Spill
	sd	s1, 16(sp)                      # 8-byte Folded Spill
	sd	s2, 8(sp)                       # 8-byte Folded Spill
	sd	s3, 0(sp)                       # 8-byte Folded Spill
	.cfi_offset s0, -8
	.cfi_offset s1, -16
	.cfi_offset s2, -24
	.cfi_offset s3, -32
	li	a5, 0
	li	a6, 0
	li	t0, 195
	csrw	2048, t0
	li	t1, 8
	csrw	2049, t1
	lui	t0, 32
	addi	t0, t0, 195
	csrw	2052, t0
	li	t1, 8
	csrw	2053, t1
	li	t0, 195
	csrw	2060, t0
	li	t1, 8
	csrw	2061, t1
	lui	t0, 16
	addi	t0, t0, 195
	csrw	2050, t0
	li	t1, 8
	csrw	2051, t1
	li	t0, 192
	csrw	2062, t0
	lui	t1, 16
	csrw	2063, t1
	li	t0, 5
	slli	t0, t0, 49
	addi	t0, t0, 192
	csrw	2064, t0
	csrw	2065, t1
	li	t0, 5
	slli	t0, t0, 49
	addi	t0, t0, 192
	csrw	2066, t0
	csrw	2067, t1
	lui	t0, 4
	addi	t0, t0, 1985
	csrw	2068, t0
	li	t1, 4
	csrw	2069, t1
	lui	t0, 36
	addi	t0, t0, 1985
	csrw	2070, t0
	li	t1, 12
	csrw	2071, t1
	lui	t0, 101
	addi	t0, t0, -1855
	csrw	2078, t0
	li	t1, 4
	csrw	2079, t1
	lui	t0, 20
	addi	t0, t0, 194
	csrw	2080, t0
	li	t1, 4
	csrw	2081, t1
	lui	t0, 36
	addi	t0, t0, 194
	csrw	2082, t0
	li	t1, 12
	csrw	2083, t1
	lui	t0, 419430
	li	a7, 10
	addi	t0, t0, 1639
	j	.LBB0_2
.LBB0_1:                                # %for.cond.cleanup16
                                        #   in Loop: Header=BB0_2 Depth=1
	addiw	a6, a6, 1
	addi	a5, a5, 40
.LBB0_2:                                # %for.cond
                                        # =>This Loop Header: Depth=1
                                        #     Child Loop BB0_6 Depth 2
	bge	a6, a4, .LBB0_4
# %bb.3:                                # %land.rhs
                                        #   in Loop: Header=BB0_2 Depth=1
	slti	t1, a6, 10
	bnez	t1, .LBB0_5
	j	.LBB0_7
.LBB0_4:
	j	.LBB0_7
.LBB0_5:                                # %for.body
                                        #   in Loop: Header=BB0_2 Depth=1
	li	t1, 0
	li	t2, 0
	slli	t5, a6, 2
	add	t3, a0, t5
	lw	t6, 0(t3)
	remw	t4, t6, a4
	mul	s0, t4, t0
	addi	t6, t6, 100
	slli	s1, a6, 3
	slli	s2, t4, 2
	add	s1, s1, t5
	add	t5, a1, s2
	add	s1, s1, a2
	sw	t6, 0(t5)
	sw	t6, 0(s1)
	lw	t6, 0(t3)
	slli	s1, t4, 3
	srli	s3, s0, 63
	srai	s0, s0, 34
	add	s1, s1, s2
	add	s0, s0, s3
	slli	s2, s0, 1
	slli	s0, s0, 3
	add	s0, s0, s2
	add	s1, s1, a2
	sw	t6, 4(s1)
	subw	t6, t4, s0
	slli	s0, t6, 3
	slli	t6, t6, 5
	add	t6, t6, s0
	mv	s0, a3
	blez	a7, .LBB0_1
.LBB0_6:                                # %for.body17
                                        #   Parent Loop BB0_2 Depth=1
                                        # =>  This Inner Loop Header: Depth=2
	lw	s1, 0(t3)
	add	s2, s0, a5
	add	s1, s1, t2
	sw	s1, 0(s2)
	lw	s1, 0(t5)
	add	s2, s0, t6
	addw	s3, t4, t2
	slli	s3, s3, 2
	add	s1, s1, t1
	sw	s1, 0(s2)
	add	s3, s3, a1
	lw	s1, 0(s3)
	add	s1, s1, t1
	addiw	t2, t2, 1
	sw	s1, 4(s2)
	addi	s0, s0, 4
	addi	t1, t1, -1
	blt	t2, a7, .LBB0_6
	j	.LBB0_1
.LBB0_7:                                # %for.cond.cleanup
	ld	s0, 24(sp)                      # 8-byte Folded Reload
	ld	s1, 16(sp)                      # 8-byte Folded Reload
	ld	s2, 8(sp)                       # 8-byte Folded Reload
	ld	s3, 0(sp)                       # 8-byte Folded Reload
	.cfi_restore s0
	.cfi_restore s1
	.cfi_restore s2
	.cfi_restore s3
	addi	sp, sp, 32
	.cfi_def_cfa_offset 0
	ret
.Lfunc_end0:
	.size	pattern9_mixed, .Lfunc_end0-pattern9_mixed
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
	addi	sp, sp, -48
	.cfi_def_cfa_offset 48
	sd	ra, 40(sp)                      # 8-byte Folded Spill
	sd	s0, 32(sp)                      # 8-byte Folded Spill
	sd	s1, 24(sp)                      # 8-byte Folded Spill
	sd	s2, 16(sp)                      # 8-byte Folded Spill
	sd	s3, 8(sp)                       # 8-byte Folded Spill
	.cfi_offset ra, -8
	.cfi_offset s0, -16
	.cfi_offset s1, -24
	.cfi_offset s2, -32
	.cfi_offset s3, -40
	li	a0, 50
	li	a1, 4
	call	calloc
	mv	s0, a0
	li	a0, 50
	li	a1, 4
	call	calloc
	mv	s1, a0
	li	a0, 50
	li	a1, 12
	call	calloc
	mv	s2, a0
	li	a0, 10
	li	a1, 40
	call	calloc
	mv	s3, a0
	li	a4, 50
	mv	a0, s0
	mv	a1, s1
	mv	a2, s2
	mv	a3, s3
	call	pattern9_mixed
	mv	a0, s0
	call	free
	mv	a0, s1
	call	free
	mv	a0, s2
	call	free
	mv	a0, s3
	call	free
	li	a0, 100
	li	a1, 4
	call	calloc
	mv	s0, a0
	li	a0, 100
	li	a1, 4
	call	calloc
	mv	s1, a0
	li	a0, 100
	li	a1, 12
	call	calloc
	mv	s2, a0
	li	a0, 10
	li	a1, 40
	call	calloc
	mv	s3, a0
	li	a4, 100
	mv	a0, s0
	mv	a1, s1
	mv	a2, s2
	mv	a3, s3
	call	pattern9_mixed
	mv	a0, s0
	call	free
	mv	a0, s1
	call	free
	mv	a0, s2
	call	free
	mv	a0, s3
	call	free
	li	a0, 0
	ld	ra, 40(sp)                      # 8-byte Folded Reload
	ld	s0, 32(sp)                      # 8-byte Folded Reload
	ld	s1, 24(sp)                      # 8-byte Folded Reload
	ld	s2, 16(sp)                      # 8-byte Folded Reload
	ld	s3, 8(sp)                       # 8-byte Folded Reload
	.cfi_restore ra
	.cfi_restore s0
	.cfi_restore s1
	.cfi_restore s2
	.cfi_restore s3
	addi	sp, sp, 48
	.cfi_def_cfa_offset 0
	ret
.Lfunc_end1:
	.size	main, .Lfunc_end1-main
	.cfi_endproc
                                        # -- End function
	.option	pop
	.ident	"clang version 24.0.0git (git@github.com:isa-Lai/llvm-project.git 0ccca49fbdf066b1df3977840d128c8872a444c6)"
	.section	".note.GNU-stack","",@progbits
