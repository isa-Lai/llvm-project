	.attribute	4, 16
	.attribute	5, "rv64i2p1_m2p0_a2p1_f2p2_d2p2_c2p0_zicsr2p0_zifencei2p0_zmmul1p0_zaamo1p0_zalrsc1p0_zca1p0_zcd1p0"
	.file	"patternC_array_bounded_indirect.c"
	.option	push
	.option	arch, +a, +c, +d, +f, +m, +zaamo, +zalrsc, +zca, +zcd, +zicsr, +zifencei, +zmmul
	.text
	.globl	gather                          # -- Begin function gather
	.p2align	1
	.type	gather,@function
gather:                                 # @gather
	.cfi_startproc
# %bb.0:                                # %entry
	li	a0, 0
	li	t0, 1
	slli	t0, t0, 58
	addi	t0, t0, 192
	csrw	2048, t0
	lui	t1, 16
	csrw	2049, t1
	lui	a1, %hi(B)
	addi	a1, a1, %lo(B)
	lui	t0, 16
	addi	t0, t0, 193
	csrw	2050, t0
	li	t1, 4
	csrw	2051, t1
	lui	a2, %hi(Out)
	addi	a2, a2, %lo(Out)
	lui	t0, 32
	addi	t0, t0, 193
	csrw	2052, t0
	li	t1, 4
	csrw	2053, t1
	lui	a3, %hi(A)
	addi	a3, a3, %lo(A)
	lui	t0, 48
	addi	t0, t0, 194
	csrw	2054, t0
	lui	t1, 65536
	addi	t1, t1, 4
	csrw	2055, t1
	li	a4, 1024
	blez	a4, .LBB0_2
.LBB0_1:                                # %for.body
                                        # =>This Inner Loop Header: Depth=1
	lw	a5, 0(a1)
	slli	a5, a5, 2
	add	a5, a5, a3
	lw	a5, 0(a5)
	addiw	a0, a0, 1
	sw	a5, 0(a2)
	addi	a2, a2, 4
	addi	a1, a1, 4
	blt	a0, a4, .LBB0_1
.LBB0_2:                                # %for.cond.cleanup
	ret
.Lfunc_end0:
	.size	gather, .Lfunc_end0-gather
	.cfi_endproc
                                        # -- End function
	.option	pop
	.type	A,@object                       # @A
	.bss
	.globl	A
	.p2align	2, 0x0
A:
	.zero	4096
	.size	A, 4096

	.type	B,@object                       # @B
	.globl	B
	.p2align	2, 0x0
B:
	.zero	4096
	.size	B, 4096

	.type	Out,@object                     # @Out
	.globl	Out
	.p2align	2, 0x0
Out:
	.zero	4096
	.size	Out, 4096

	.ident	"clang version 24.0.0git (git@github.com:isa-Lai/llvm-project.git 0ccca49fbdf066b1df3977840d128c8872a444c6)"
	.section	".note.GNU-stack","",@progbits
