	.attribute	4, 16
	.attribute	5, "rv64i2p1_m2p0_a2p1_f2p2_d2p2_c2p0_zicsr2p0_zifencei2p0_zmmul1p0_zaamo1p0_zalrsc1p0_zca1p0_zcd1p0"
	.file	"pattern3_struct_direct.c"
	.option	push
	.option	arch, +a, +c, +d, +f, +m, +zaamo, +zalrsc, +zca, +zcd, +zicsr, +zifencei, +zmmul
	.text
	.globl	pattern3_struct_direct          # -- Begin function pattern3_struct_direct
	.p2align	1
	.type	pattern3_struct_direct,@function
pattern3_struct_direct:                 # @pattern3_struct_direct
	.cfi_startproc
# %bb.0:                                # %entry
	li	a2, 0
	addi	a3, a0, 8
	addi	a4, a0, 16
	li	t0, 195
	csrw	2050, t0
	li	t1, 8
	csrw	2051, t1
	slli	a0, a1, 32
	lui	t0, 48
	addi	t0, t0, 195
	csrw	2052, t0
	li	t1, 8
	csrw	2053, t1
	srli	a0, a0, 32
	lui	t0, 64
	addi	t0, t0, 195
	csrw	2054, t0
	li	t1, 8
	csrw	2055, t1
	li	t0, 195
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
	li	t1, 12
	csrw	2059, t1
	lui	t0, 36
	addi	t0, t0, 1217
	csrw	2060, t0
	li	t1, 12
	csrw	2061, t1
	lui	t0, 52
	addi	t0, t0, 1217
	csrw	2062, t0
	li	t1, 12
	csrw	2063, t1
	blez	a1, .LBB0_2
.LBB0_1:                                # %for.body
                                        # =>This Inner Loop Header: Depth=1
	lw	a0, -8(a3)
	lw	a4, -4(a3)
	lw	a5, 0(a3)
	addi	a0, a0, 1
	addi	a4, a4, 2
	addi	a5, a5, 3
	sw	a0, -8(a3)
	sw	a4, -4(a3)
	sw	a5, 0(a3)
	addiw	a2, a2, 1
	addi	a3, a3, 12
	blt	a2, a1, .LBB0_1
.LBB0_2:                                # %for.cond.cleanup
	ret
.Lfunc_end0:
	.size	pattern3_struct_direct, .Lfunc_end0-pattern3_struct_direct
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
	addi	sp, sp, -16
	.cfi_def_cfa_offset 16
	sd	ra, 8(sp)                       # 8-byte Folded Spill
	sd	s0, 0(sp)                       # 8-byte Folded Spill
	.cfi_offset ra, -8
	.cfi_offset s0, -16
	li	a0, 50
	li	a1, 12
	call	calloc
	mv	s0, a0
	li	a1, 50
	call	pattern3_struct_direct
	mv	a0, s0
	call	free
	li	a0, 100
	li	a1, 12
	call	calloc
	mv	s0, a0
	li	a1, 100
	call	pattern3_struct_direct
	mv	a0, s0
	call	free
	li	a0, 0
	ld	ra, 8(sp)                       # 8-byte Folded Reload
	ld	s0, 0(sp)                       # 8-byte Folded Reload
	.cfi_restore ra
	.cfi_restore s0
	addi	sp, sp, 16
	.cfi_def_cfa_offset 0
	ret
.Lfunc_end1:
	.size	main, .Lfunc_end1-main
	.cfi_endproc
                                        # -- End function
	.option	pop
	.ident	"clang version 24.0.0git (git@github.com:isa-Lai/llvm-project.git 0ccca49fbdf066b1df3977840d128c8872a444c6)"
	.section	".note.GNU-stack","",@progbits
