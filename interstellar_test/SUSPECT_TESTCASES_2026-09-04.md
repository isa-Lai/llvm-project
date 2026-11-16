# Descriptor Audit — 2026-09-04 — Suspect Testcases

> **FIX STATUS (2026-09-04, same day): all three suspects FIXED** in
> `InterStellarAnalysis.cpp` (uncommitted). Regression checker:
> `check_descriptor_fixes.sh` — 54/54 green on the full 13-pattern suite
> (re-run from scratch); 0 poison; verify/llc clean everywhere; the 8 clean
> patterns' descriptor dumps byte-identical to the pre-fix snapshot
> (`audit_2026-09-04/prefix_snapshot/`).
>
> - **S1 fixed** — new gate in `tryAnalyzeIndirectStream`: a stream-driven
>   index must be the index's only loop-varying component (no nested
>   `SCEVAddRecExpr` anywhere in the index SCEV), else the stream drops.
>   p5/p6 truncated indirects gone; their now-unused `%D2A` link is purged by
>   Stage 3.2 (p5 f1 12→10 descriptors; p6 f1 16→15).
> - **S2 fixed** — merged-bound builder now gives every dimension a concrete
>   IR value (constants become `ConstantInt`), so a const-inner × dynamic-outer
>   product materializes: p9 emits `%merged_loop_bound = mul i32 10, %smin2`,
>   linked, and the merged loop emits `EL=1 End=Link<mul>`.
> - **S3 fixed** — new post-emission sweep `eraseOrphanConfigs` applies Stage
>   3.1's activity criterion to what was *actually emitted* and erases orphan
>   `configure.loop` calls plus links only they referenced (p8: 1 loop; p9:
>   1 vestigial j-loop; pB f2: 3 loops + 1 link → the function now emits a
>   clean zero). Emitted-config summary counts are post-sweep.
>
> Note: gem5 pins in `baseline/` (G3) are unaffected — `complete_test` /
> `simple_test` build from pattern0/simple_test code, whose descriptors are
> unchanged. `check_gate.sh` G1 remains stale for 5,6,7,8,9,B as documented.

Re-run of the full `test_summary.sh` suite (patterns 0–9, A, B, C) against the current
uncommitted `InterStellarAnalysis.cpp` (build newer than last source edit, 2026-09-02
17:20), verifying every emitted descriptor for wrong merges, base addresses, link IR,
strides, and bounds. Evidence per pattern: `audit_2026-09-04/pattern<p>/`
(`analyzed.ll`, `debug.log`, `descriptors.txt`, `verify.log`, `llc.log`, `summary_run.log`).

**Suite health:** all 13 patterns ran; `llc` clean on all; `verify_descriptors.py` exit 0
on all except patternA (0 intrinsics, by design). 0 poison, 0 genuinely-null bases.

## Verdict summary

| Pattern | Verdict | Notes |
|---|---|---|
| 0 | ✅ correct | links `%A`/`%B`/`inttoptr(N)`; loop `0..N` (End=Link0, exclusive); A/B streams stride 4 |
| 1 | ✅ correct | f1 strides 4/4/8/12 with `+8`/`+12` gep bases; f2 `smin(N,200)` linked end, `[i+5]` base = `gep @GlobalArray, +20` |
| 2 | ✅ correct | indirect `B[A[i]]` Source=4 (the A[i] stream); `B[rand()]` Source=0 (by design) |
| 3 | ✅ correct | .x/.y/.z = `points`/`+4`/`+8` links, stride 12 |
| 4 | ✅ correct | .x/.y/.z indirects: bases `points`/`+4`/`+8`, sources 6/6/0, ElemSize=12 (by design) |
| 5 | ❌ **S1** | col-indirect emitted with base truncated to array start |
| 6 | ❌ **S1** | inner-indirect emitted with base truncated to array start |
| 7 | ✅ correct | merged stream on virtual loop End=100 ✓; A-reads' `ptr null` = folded `inttoptr(Link0=%A)` ✓ |
| 8 | ⚠️ **S3** (+known-open) | orphan merged loop End=100; outer-variant drops are the documented open issue |
| 9 | ❌ **S2** | merged virtual loop emitted **End=0** (true bound `10*smin(N,10)`) |
| A | ✅ correct | 0 intrinsics by design |
| B | ⚠️ **S3** | f2 4D-fixed stream dropped (known-open) leaving orphan merged loop End=90; f1/f3 correct incl. `N*M*P*Q` product link |
| C | ✅ correct | Source=1, StreamSize=4096 |

---

## Suspect list

### S1 — pattern5 f1 + pattern6 f1: indirect stream emitted with base truncated to array start (HIGH)

**What the source says vs. what is emitted**

| Case | Access | Emitted descriptor | Missing from base |
|---|---|---|---|
| pattern5 `pattern5_2d_pointer.c:18` | `D2A[i*D2_cols + A[j]%D2_cols]` | `indirectstream(GID=11, Source=10, BL=1, Base=Link(%D2A), 4, 0)` | `i*D2_cols*4` row term |
| pattern6 `pattern6_3d_pointer.c:25` | `D3A[i*dim2*dim3 + j*dim3 + A[k]%dim3]` | `indirectstream(GID=14, Source=13, BL=1, Base=Link(%D3A), 4, 0)` | `i*dim2*dim3 + j*dim3` terms |

The descriptors describe row-0 gathers (`D2A[A[j]%D2_cols]`, `D3A[A[k]%dim3]`) instead of
row-`i` accesses. Inconsistent with sibling variants: the row-variant indirects
(`D2A[A[i]%D2_rows * D2_cols + j]`, `D3A[A[i]][j][k]`, `D3A[i][A[j]%dim2][k]`) and the
partial-rand variants **drop** at emission ("Stream N has loop-variant base, skipping")
— the safe behavior. Whether an inner-index variant drops or emits a wrong base depends
only on whether its base *pointer expression* happens to be loop-invariant
(function-argument array vs. in-loop row GEP).

**Root cause (analysis level, not emission):** the indirect analyzer's BasePtr-as-link
fallback reduces the composite base to the bare array pointer before the outer-variant
terms are checked. Debug log, pattern5 final dump:

```
Stream ID: 6 (Loop 1)   pattern5_2d_pointer.c:18:41
  ├─ Base Address:   ptr %D2A   [BL=1, Dynamic, LinkID=5]     ← i*D2_cols term already gone
  ├─ Index Stream:   Stream #5
```

Same for pattern6 line 25 (`Base Address: ptr %D3A [BL=1, LinkID=6]`). Locus: the
`tryAnalyzeIndirectStream` link fallback (gated on `IsIndexFromStream &&
isEffectivelyLoopInvariant` — the gate tests the base *value's* invariance, never that
the discarded outer AddRec terms are zero). Adjacent to, but distinct from, the
documented known-open anchor-emission issue (which drops such streams at emission).

**Fix direction:** in the indirect link fallback, only accept when the non-index terms of
the base AddExpr fold to a constant that is preserved (add to base as GEP, like the
direct path does for `A[i+5]`), otherwise drop the stream like the emission path does.

### S2 — pattern9: merged-loop bound emitted as End=0 (HIGH)

`for (i<N && i<10) { … for (j<10) { D2B[i][j] … } }` — the Stage-3 merge flattens i×j
into a virtual loop and the merged `D2B[i][j]` stream (`GID=11`, base `%D2B`, stride 4,
✓) is attached to it. The bound is computed correctly at analysis:

```
✓ Created Virtual Loop #2 (merges Loop #1 → Loop #0)
      End:   (10 * (10 smin %N))
```

but the emitted descriptor is `loop(GID=8, Parent=NO_PARENT, SL=0, EL=0, 0, 0, 1)` —
**End=0, unlinked** (true bound is a 0-trip loop). The outer loop's `smin(N,10)` bound
*does* link correctly (End=Link0), and pattern5/6/B all emit merged products fine
(`merged_loop_bound*` muls, e.g. patternB's `End=Link8` = `((Q*P)*M)*N`) — pattern9 is
the only const-inner × dynamic-outer case in the suite.

**Root cause:** [InterStellarAnalysis.cpp:3360-3376](llvm-project/llvm/lib/Transforms/Scalar/InterStellarAnalysis.cpp#L3360-L3376)
— the IR mul is created only when **both** the accumulated `VirtualEndValueIR` and the
new `BoundIR` exist. Chain order is innermost-first; here the inner dim (j=10) is
constant ⇒ `VirtualEndValueIR` stays null ⇒ multiplying by `%smin` keeps IR null ⇒
`IsEndLinked=false`, no bound link created (Stage 3.2 then purges the orphaned bound
link), and emission defaults `EndVal=0`. Secondary: the descriptor printer labels this
dynamic end `[EL=0, Constant]` (mislabel in the same code path).

**Fix direction:** seed/convert through `BoundIR` when either side has IR (constant ×
dynamic ⇒ materialize the constant too), or fall back to expanding the final
`VirtualEndValue` SCEV via `SCEVExpander` when `VirtualEndValueIR` is null.

### S3 — pattern8 + patternB f2: orphan merged-loop descriptors (LOW)

Streams that die at emission (loop-variant base, the documented known-open limitation)
leave their **virtual host loops** in the output, because loop cleanup (Stage 3.1) runs
before emission:

| Case | Orphan emitted | Evidence |
|---|---|---|
| pattern8 (j×k merge) | `loop(GID=8, Parent=4, End=100)` — no streams | `pattern8/debug.log:574-582,740-747` |
| patternB f2 (k×m merge) | `loop(GID=4, Parent=3, End=90)` — no streams; whole function emits 0 stream configs | `patternB/debug.log:945-957,1036-1043` |

Harmless today (engine ignores these descriptors), but the engine would allocate a loop
slot with no streams; a post-emission sweep (or moving the drop decision before Stage
3.1) would keep the ABI output clean.

---

## False alarms investigated and cleared

- **pattern7/pattern8 A-read streams with `Base=ptr null`, BL=1** (`A[i]`, `A[j]`,
  `A[k]` index reads): this is `inttoptr(i64 0)` constant-folded to `ptr null` — i.e.
  Base = **Link GlobalID 0 = `%A`**, which is emitted. Verified via
  `resolveActuallyLinked`/`prepareStreamBaseArg`
  ([InterStellarAnalysis.cpp:3818-3871](llvm-project/llvm/lib/Transforms/Scalar/InterStellarAnalysis.cpp#L3818-L3871)):
  a `BL=1` stream is only emitted after its link was emitted, and the base is then
  `inttoptr(LinkGID)`; GID 0 folds to null in IR. Not a defect — but a tooling trap
  (below).
- **pattern1 `GlobalArray[i+5]` base**: emits `gep inbounds nuw (i8, ptr @GlobalArray,
  i64 20)` — the +20 IS folded into the base (constant-index-offset path works).
- **pattern9 dedup of `B[idx]` at line 26 into primary #3 (line 20)**: both are the same
  `B[A[i]%N]` load; dedup is correct.
- **pattern6 `GID15` (full-rand indirect, base=Link(%D3A), Source=0)**: correct
  representation of a computed/random index over the whole array.

## Known-open, not new (documented 2026-09-01/02, confirmed unchanged)

- Outer-variant-base streams drop at emission (anchor-once link design): pattern7
  `D2B[A[i]%10][j]` / `D2B[i][A[j]%10]`, pattern8's `D3B[A[i]%10][j][k]` family + 2
  presented-but-dropped indirects, pattern9 `D2B[idx%10][j]`, `[idx%10][j+1]`,
  `B[idx+j]`, patternB f2's only stream. Consequence: patternB f2 emits **zero** stream
  descriptors for its function.
- `ElemSize` = struct size (12) on struct indirects — by design (stride semantics).
- `StreamSize=0` for heap-based indirect targets (unknown size); static case works
  (patternC = 4096).
- Engine-side latency: `SourceID`/`parentLoopId`/linked bases are not yet consumed by
  the engine, so S1/S2 are latent in sim today.

## Tooling caveats for the next auditor

1. `parse_descriptors.py` field labels are **stale** (Stride slot = Base; TripCount slot
   = Start/End). Use `audit_dump_descriptors.py` (authoritative map from
   `Intrinsics.td:3211-3244` + `RISCVISelLowering.cpp:12855+`).
2. `ptr null` in an emitted stream base with `BL=1` usually means **`inttoptr(LinkID 0)`
   folded**, not a missing base — cross-check the emission section of `debug.log`.
3. `verify_descriptors.py` checks structure (GlobalID range/reference integrity), not
   semantics — S1/S2 pass it.
