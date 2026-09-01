; ModuleID = 'pattern4_struct_indirect.c'
source_filename = "pattern4_struct_indirect.c"
target datalayout = "e-m:e-p:64:64-i64:64-i128:128-n32:64-S128"
target triple = "riscv64-unknown-linux-gnu"

%struct.Point = type { i32, i32, i32 }

; Function Attrs: nounwind uwtable
define dso_local void @pattern4_struct_indirect(ptr noundef %A, ptr noundef %points, i32 noundef signext %N) #0 {
entry:
  %A.addr = alloca ptr, align 8
  %points.addr = alloca ptr, align 8
  %N.addr = alloca i32, align 4
  %state = alloca i32, align 4
  %i = alloca i32, align 4
  %idx = alloca i32, align 4
  %rand_idx = alloca i32, align 4
  store ptr %A, ptr %A.addr, align 8, !tbaa !13
  store ptr %points, ptr %points.addr, align 8, !tbaa !16
  store i32 %N, ptr %N.addr, align 4, !tbaa !18
  call void @llvm.lifetime.start.p0(ptr %state) #2
  store i32 305419896, ptr %state, align 4, !tbaa !18
  call void @llvm.lifetime.start.p0(ptr %i) #2
  store i32 0, ptr %i, align 4, !tbaa !18
  br label %for.cond

for.cond:                                         ; preds = %for.inc, %entry
  %0 = load i32, ptr %i, align 4, !tbaa !18
  %1 = load i32, ptr %N.addr, align 4, !tbaa !18
  %cmp = icmp slt i32 %0, %1
  br i1 %cmp, label %for.body, label %for.cond.cleanup

for.cond.cleanup:                                 ; preds = %for.cond
  call void @llvm.lifetime.end.p0(ptr %i) #2
  br label %for.end

for.body:                                         ; preds = %for.cond
  call void @llvm.lifetime.start.p0(ptr %idx) #2
  %2 = load ptr, ptr %A.addr, align 8, !tbaa !13
  %3 = load i32, ptr %i, align 4, !tbaa !18
  %idxprom = sext i32 %3 to i64
  %arrayidx = getelementptr inbounds i32, ptr %2, i64 %idxprom
  %4 = load i32, ptr %arrayidx, align 4, !tbaa !18
  store i32 %4, ptr %idx, align 4, !tbaa !18
  %5 = load i32, ptr %idx, align 4, !tbaa !18
  %cmp1 = icmp sge i32 %5, 0
  br i1 %cmp1, label %land.lhs.true, label %if.end

land.lhs.true:                                    ; preds = %for.body
  %6 = load i32, ptr %idx, align 4, !tbaa !18
  %7 = load i32, ptr %N.addr, align 4, !tbaa !18
  %cmp2 = icmp slt i32 %6, %7
  br i1 %cmp2, label %if.then, label %if.end

if.then:                                          ; preds = %land.lhs.true
  %8 = load ptr, ptr %points.addr, align 8, !tbaa !16
  %9 = load i32, ptr %idx, align 4, !tbaa !18
  %idxprom3 = sext i32 %9 to i64
  %arrayidx4 = getelementptr inbounds %struct.Point, ptr %8, i64 %idxprom3
  %x = getelementptr inbounds nuw %struct.Point, ptr %arrayidx4, i32 0, i32 0
  %10 = load i32, ptr %x, align 4, !tbaa !19
  %add = add nsw i32 %10, 10
  store i32 %add, ptr %x, align 4, !tbaa !19
  %11 = load ptr, ptr %points.addr, align 8, !tbaa !16
  %12 = load i32, ptr %idx, align 4, !tbaa !18
  %idxprom5 = sext i32 %12 to i64
  %arrayidx6 = getelementptr inbounds %struct.Point, ptr %11, i64 %idxprom5
  %y = getelementptr inbounds nuw %struct.Point, ptr %arrayidx6, i32 0, i32 1
  %13 = load i32, ptr %y, align 4, !tbaa !21
  %add7 = add nsw i32 %13, 20
  store i32 %add7, ptr %y, align 4, !tbaa !21
  br label %if.end

if.end:                                           ; preds = %if.then, %land.lhs.true, %for.body
  %14 = load i32, ptr %state, align 4, !tbaa !18
  %mul = mul i32 %14, 1664525
  %add8 = add i32 %mul, 1013904223
  store i32 %add8, ptr %state, align 4, !tbaa !18
  call void @llvm.lifetime.start.p0(ptr %rand_idx) #2
  %15 = load i32, ptr %state, align 4, !tbaa !18
  %16 = load i32, ptr %N.addr, align 4, !tbaa !18
  %rem = urem i32 %15, %16
  store i32 %rem, ptr %rand_idx, align 4, !tbaa !18
  %17 = load ptr, ptr %points.addr, align 8, !tbaa !16
  %18 = load i32, ptr %rand_idx, align 4, !tbaa !18
  %idxprom9 = sext i32 %18 to i64
  %arrayidx10 = getelementptr inbounds %struct.Point, ptr %17, i64 %idxprom9
  %z = getelementptr inbounds nuw %struct.Point, ptr %arrayidx10, i32 0, i32 2
  %19 = load i32, ptr %z, align 4, !tbaa !22
  %add11 = add nsw i32 %19, 100
  store i32 %add11, ptr %z, align 4, !tbaa !22
  call void @llvm.lifetime.end.p0(ptr %rand_idx) #2
  call void @llvm.lifetime.end.p0(ptr %idx) #2
  br label %for.inc

for.inc:                                          ; preds = %if.end
  %20 = load i32, ptr %i, align 4, !tbaa !18
  %inc = add nsw i32 %20, 1
  store i32 %inc, ptr %i, align 4, !tbaa !18
  br label %for.cond, !llvm.loop !23

for.end:                                          ; preds = %for.cond.cleanup
  call void @llvm.lifetime.end.p0(ptr %state) #2
  ret void
}

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(ptr captures(none)) #1

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(ptr captures(none)) #1

attributes #0 = { nounwind uwtable "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="generic-rv64" "target-features"="+64bit,+a,+c,+d,+f,+i,+m,+relax,+zaamo,+zalrsc,+zca,+zcd,+zicsr,+zifencei,+zmmul,-b,-e,-experimental-p,-experimental-smpmpmt,-experimental-svukte,-experimental-xqccmt,-experimental-xsfmclic,-experimental-xsfsclic,-experimental-y,-experimental-zibi,-experimental-zicfilp,-experimental-zicfiss,-experimental-zvabd,-experimental-zvbc32e,-experimental-zvdot4a8i,-experimental-zvfbdota32f,-experimental-zvfbfa,-experimental-zvfofp8min,-experimental-zvfqwbdota8f,-experimental-zvfqwdota8f,-experimental-zvfwbdota16bf,-experimental-zvfwdota16bf,-experimental-zvkgs,-experimental-zvqwbdota16i,-experimental-zvqwbdota8i,-experimental-zvqwdota16i,-experimental-zvqwdota8i,-experimental-zvvfmm,-experimental-zvvmm,-experimental-zvvmtls,-experimental-zvvmttls,-experimental-zvzip,-h,-q,-sdext,-sdtrig,-sha,-shcounterenw,-shgatpa,-shlcofideleg,-shtvala,-shvsatpa,-shvstvala,-shvstvecd,-smaia,-smcdeleg,-smcntrpmf,-smcsrind,-smctr,-smdbltrp,-smepmp,-smmpm,-smnpm,-smrnmi,-smstateen,-ssaia,-ssccfg,-ssccptr,-sscofpmf,-sscounterenw,-sscsrind,-ssctr,-ssdbltrp,-ssnpm,-sspm,-ssqosid,-ssstateen,-ssstrict,-sstc,-sstvala,-sstvecd,-ssu64xl,-supm,-svade,-svadu,-svbare,-svinval,-svnapot,-svpbmt,-svrsw60t59b,-svvptc,-v,-xaifet,-xandesbfhcvt,-xandesperf,-xandesvbfhcvt,-xandesvdot,-xandesvpackfph,-xandesvsinth,-xandesvsintload,-xcheriot,-xcvalu,-xcvbi,-xcvbitmanip,-xcvelw,-xcvmac,-xcvmem,-xcvsimd,-xmipscbop,-xmipscmov,-xmipsexectl,-xmipslsp,-xqccmp,-xqci,-xqcia,-xqciac,-xqcibi,-xqcibm,-xqcicli,-xqcicm,-xqcics,-xqcicsr,-xqciint,-xqciio,-xqcilb,-xqcili,-xqcilia,-xqcilo,-xqcilsm,-xqcisim,-xqcisls,-xqcisync,-xsfcease,-xsfmm128t,-xsfmm16t,-xsfmm32a,-xsfmm32a16f,-xsfmm32a32f,-xsfmm32a8f,-xsfmm32a8i,-xsfmm32t,-xsfmm64a64f,-xsfmm64t,-xsfmmbase,-xsfvcp,-xsfvfbfexp16e,-xsfvfexp16e,-xsfvfexp32e,-xsfvfexpa,-xsfvfexpa64e,-xsfvfnrclipxfqf,-xsfvfwmaccqqq,-xsfvqmaccdod,-xsfvqmaccqoq,-xsifivecdiscarddlone,-xsifivecflushdlone,-xsmtvdot,-xsmtvdotii,-xtheadba,-xtheadbb,-xtheadbs,-xtheadcmo,-xtheadcondmov,-xtheadfmemidx,-xtheadmac,-xtheadmemidx,-xtheadmempair,-xtheadsync,-xtheadvdot,-xventanacondops,-xwchc,-za128rs,-za64rs,-zabha,-zacas,-zalasr,-zama16b,-zawrs,-zba,-zbb,-zbc,-zbkb,-zbkc,-zbkx,-zbs,-zcb,-zce,-zcf,-zclsd,-zcmop,-zcmp,-zcmt,-zdinx,-zfa,-zfbfmin,-zfh,-zfhmin,-zfinx,-zhinx,-zhinxmin,-zic64b,-zicbom,-zicbop,-zicboz,-ziccamoa,-ziccamoc,-ziccid,-ziccif,-zicclsm,-ziccrse,-zicntr,-zicond,-zihintntl,-zihintpause,-zihpm,-zilsd,-zimop,-zk,-zkn,-zknd,-zkne,-zknh,-zkr,-zks,-zksed,-zksh,-zkt,-ztso,-zvbb,-zvbc,-zve32f,-zve32x,-zve64d,-zve64f,-zve64x,-zvfbfmin,-zvfbfwma,-zvfh,-zvfhmin,-zvkb,-zvkg,-zvkn,-zvknc,-zvkned,-zvkng,-zvknha,-zvknhb,-zvks,-zvksc,-zvksed,-zvksg,-zvksh,-zvkt,-zvl1024b,-zvl128b,-zvl16384b,-zvl2048b,-zvl256b,-zvl32768b,-zvl32b,-zvl4096b,-zvl512b,-zvl64b,-zvl65536b,-zvl8192b" }
attributes #1 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { nounwind }

!llvm.module.flags = !{!0, !1, !3, !4, !5, !6}
!llvm.ident = !{!7}
!llvm.errno.tbaa = !{!8}

!0 = !{i32 1, !"target-abi", !"lp64d"}
!1 = !{i32 6, !"riscv-isa", !2}
!2 = !{!"rv64i2p1_m2p0_a2p1_f2p2_d2p2_c2p0_zicsr2p0_zifencei2p0_zmmul1p0_zaamo1p0_zalrsc1p0_zca1p0_zcd1p0"}
!3 = !{i32 8, !"PIC Level", i32 2}
!4 = !{i32 7, !"PIE Level", i32 2}
!5 = !{i32 7, !"uwtable", i32 2}
!6 = !{i32 8, !"SmallDataLimit", i32 0}
!7 = !{!"clang version 24.0.0git (git@github.com:isa-Lai/llvm-project.git 0ccca49fbdf066b1df3977840d128c8872a444c6)"}
!8 = !{!9, !10, i64 0}
!9 = !{!"__libc_errno", !10, i64 0}
!10 = !{!"int", !11, i64 0}
!11 = !{!"omnipotent char", !12, i64 0}
!12 = !{!"Simple C/C++ TBAA"}
!13 = !{!14, !14, i64 0}
!14 = !{!"p1 int", !15, i64 0}
!15 = !{!"any pointer", !11, i64 0}
!16 = !{!17, !17, i64 0}
!17 = !{!"p1 _ZTS5Point", !15, i64 0}
!18 = !{!10, !10, i64 0}
!19 = !{!20, !10, i64 0}
!20 = !{!"Point", !10, i64 0, !10, i64 4, !10, i64 8}
!21 = !{!20, !10, i64 4}
!22 = !{!20, !10, i64 8}
!23 = distinct !{!23, !24, !25}
!24 = !{!"llvm.loop.mustprogress"}
!25 = !{!"llvm.loop.unroll.disable"}
