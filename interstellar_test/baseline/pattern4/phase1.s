	.attribute	4, 16
	.attribute	5, "rv64i2p1_m2p0_a2p1_f2p2_d2p2_c2p0_zicsr2p0_zifencei2p0_zmmul1p0_zaamo1p0_zalrsc1p0_zca1p0_zcd1p0"
	.file	"pattern4_struct_indirect.c"
	.option	push
	.option	arch, +a, +c, +d, +f, +m, +zaamo, +zalrsc, +zca, +zcd, +zicsr, +zifencei, +zmmul
	.text
	.globl	pattern4_struct_indirect        # -- Begin function pattern4_struct_indirect
	.p2align	1
	.type	pattern4_struct_indirect,@function
pattern4_struct_indirect:               # @pattern4_struct_indirect
	.cfi_startproc
# %bb.0:                                # %entry
	li	a3, 0
	slli	a4, a2, 32
	li	t0, 195
	csrw	2050, t0
	li	t1, 8
	csrw	2051, t1
	srli	a4, a4, 32
	lui	t0, 16
	addi	t0, t0, 195
	csrw	2052, t0
	li	t1, 8
	csrw	2053, t1
	lui	t0, 64
	addi	t0, t0, 195
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
	li	t1, 12
	csrw	2059, t1
	lui	a4, 74565
	lui	t0, 36
	addi	t0, t0, 194
	csrw	2060, t0
	li	t1, 12
	csrw	2061, t1
	addi	a4, a4, 1656
	lui	a5, 406
	lui	a6, 247535
	addi	a5, a5, 1549
	addi	a6, a6, 863
	j	.LBB0_2
.LBB0_1:                                # %if.end
                                        #   in Loop: Header=BB0_2 Depth=1
	mul	a4, a4, a5
	add	a4, a4, a6
	remuw	a7, a4, a2
	slli	t0, a7, 2
	slli	a7, a7, 3
	add	a7, a7, t0
	add	a7, a7, a1
	lw	t0, 8(a7)
	addi	t0, t0, 100
	sw	t0, 8(a7)
	addiw	a3, a3, 1
	addi	a0, a0, 4
.LBB0_2:                                # %for.cond
                                        # =>This Inner Loop Header: Depth=1
	bge	a3, a2, .LBB0_6
# %bb.3:                                # %for.body
                                        #   in Loop: Header=BB0_2 Depth=1
	lw	a7, 0(a0)
	bltz	a7, .LBB0_1
# %bb.4:                                # %land.lhs.true
                                        #   in Loop: Header=BB0_2 Depth=1
	bge	a7, a2, .LBB0_1
# %bb.5:                                # %if.then
                                        #   in Loop: Header=BB0_2 Depth=1
	slli	t0, a7, 2
	slli	a7, a7, 3
	add	a7, a7, t0
	add	a7, a7, a1
	lw	t0, 0(a7)
	lw	t1, 4(a7)
	addi	t0, t0, 10
	addi	t1, t1, 20
	sw	t0, 0(a7)
	sw	t1, 4(a7)
	j	.LBB0_1
.LBB0_6:                                # %for.cond.cleanup
	ret
.Lfunc_end0:
	.size	pattern4_struct_indirect, .Lfunc_end0-pattern4_struct_indirect
	.cfi_endproc
                                        # -- End function
	.option	pop
	.ident	"clang version 24.0.0git (git@github.com:isa-Lai/llvm-project.git 0ccca49fbdf066b1df3977840d128c8872a444c6)"
	.section	".note.GNU-stack","",@progbits
