	.attribute	4, 16
	.attribute	5, "rv64i2p1_m2p0_a2p1_f2p2_d2p2_c2p0_zicsr2p0_zifencei2p0_zmmul1p0_zaamo1p0_zalrsc1p0_zca1p0_zcd1p0"
	.file	"pattern0_simple.c"
	.option	push
	.option	arch, +a, +c, +d, +f, +m, +zaamo, +zalrsc, +zca, +zcd, +zicsr, +zifencei, +zmmul
	.text
	.globl	test                            # -- Begin function test
	.p2align	1
	.type	test,@function
test:                                   # @test
	.cfi_startproc
# %bb.0:                                # %entry
	li	a3, 0
	lui	t0, 16
	addi	t0, t0, 195
	csrw	2050, t0
	li	t1, 8
	csrw	2051, t1
	slli	a4, a2, 32
	li	t0, 195
	csrw	2052, t0
	li	t1, 8
	csrw	2053, t1
	srli	a4, a4, 32
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
	addi	t0, t0, 961
	csrw	2058, t0
	li	t1, 4
	csrw	2059, t1
	blez	a2, .LBB0_2
.LBB0_1:                                # %for.body
                                        # =>This Inner Loop Header: Depth=1
	lw	a4, 0(a1)
	slli	a4, a4, 1
	addiw	a3, a3, 1
	sw	a4, 0(a0)
	addi	a0, a0, 4
	addi	a1, a1, 4
	blt	a3, a2, .LBB0_1
.LBB0_2:                                # %for.cond.cleanup
	ret
.Lfunc_end0:
	.size	test, .Lfunc_end0-test
	.cfi_endproc
                                        # -- End function
	.option	pop
	.ident	"clang version 24.0.0git (git@github.com:isa-Lai/llvm-project.git 0ccca49fbdf066b1df3977840d128c8872a444c6)"
	.section	".note.GNU-stack","",@progbits
