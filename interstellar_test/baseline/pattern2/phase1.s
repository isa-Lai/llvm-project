	.attribute	4, 16
	.attribute	5, "rv64i2p1_m2p0_a2p1_f2p2_d2p2_c2p0_zicsr2p0_zifencei2p0_zmmul1p0_zaamo1p0_zalrsc1p0_zca1p0_zcd1p0"
	.file	"pattern2_indirect_streams.c"
	.option	push
	.option	arch, +a, +c, +d, +f, +m, +zaamo, +zalrsc, +zca, +zcd, +zicsr, +zifencei, +zmmul
	.text
	.globl	pattern2_indirect_streams       # -- Begin function pattern2_indirect_streams
	.p2align	1
	.type	pattern2_indirect_streams,@function
pattern2_indirect_streams:              # @pattern2_indirect_streams
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
	mv	s0, a2
	mv	s1, a1
	mv	s2, a0
	li	s3, 0
	slli	a0, a2, 32
	lui	t0, 288
	addi	t0, t0, 195
	csrw	2050, t0
	li	t1, 8
	csrw	2051, t1
	srli	a0, a0, 32
	lui	t0, 16
	addi	t0, t0, 195
	csrw	2052, t0
	li	t1, 8
	csrw	2053, t1
	li	t0, 195
	csrw	2048, t0
	li	t1, 4
	csrw	2049, t1
	lui	t0, 8
	addi	t0, t0, 192
	csrw	2054, t0
	lui	t1, 16
	csrw	2055, t1
	lui	t0, 20
	addi	t0, t0, 961
	csrw	2056, t0
	li	t1, 4
	csrw	2057, t1
	lui	t0, 36
	addi	t0, t0, 194
	csrw	2058, t0
	li	t1, 4
	csrw	2059, t1
	lui	t0, 36
	addi	t0, t0, 194
	csrw	2060, t0
	li	t1, 4
	csrw	2061, t1
	j	.LBB0_2
.LBB0_1:                                # %if.end
                                        #   in Loop: Header=BB0_2 Depth=1
	call	rand
	addiw	s3, s3, 1
	remw	a0, a0, s0
	slli	a0, a0, 2
	add	a0, a0, s1
	lw	a1, 0(a0)
	addi	a1, a1, 1
	sw	a1, 0(a0)
	addi	s2, s2, 4
.LBB0_2:                                # %for.cond
                                        # =>This Inner Loop Header: Depth=1
	bge	s3, s0, .LBB0_6
# %bb.3:                                # %for.body
                                        #   in Loop: Header=BB0_2 Depth=1
	lw	a0, 0(s2)
	bltz	a0, .LBB0_1
# %bb.4:                                # %land.lhs.true
                                        #   in Loop: Header=BB0_2 Depth=1
	bge	a0, s0, .LBB0_1
# %bb.5:                                # %if.then
                                        #   in Loop: Header=BB0_2 Depth=1
	slli	a0, a0, 2
	add	a0, a0, s1
	lw	a1, 0(a0)
	addi	a1, a1, 1
	sw	a1, 0(a0)
	j	.LBB0_1
.LBB0_6:                                # %for.cond.cleanup
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
.Lfunc_end0:
	.size	pattern2_indirect_streams, .Lfunc_end0-pattern2_indirect_streams
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
	li	a0, 50
	li	a1, 4
	call	calloc
	mv	s1, a0
	li	a2, 50
	mv	a0, s0
	mv	a1, s1
	call	pattern2_indirect_streams
	mv	a0, s0
	call	free
	mv	a0, s1
	call	free
	li	a0, 100
	li	a1, 4
	call	calloc
	mv	s0, a0
	li	a0, 100
	li	a1, 4
	call	calloc
	mv	s1, a0
	li	a2, 100
	mv	a0, s0
	mv	a1, s1
	call	pattern2_indirect_streams
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
.Lfunc_end1:
	.size	main, .Lfunc_end1-main
	.cfi_endproc
                                        # -- End function
	.option	pop
	.ident	"clang version 24.0.0git (git@github.com:isa-Lai/llvm-project.git 0ccca49fbdf066b1df3977840d128c8872a444c6)"
	.section	".note.GNU-stack","",@progbits
