; ModuleID = 'pattern1_direct_streams.c'
source_filename = "pattern1_direct_streams.c"
target datalayout = "e-m:e-p:64:64-i64:64-i128:128-n32:64-S128"
target triple = "riscv64-unknown-linux-gnu"

@GlobalArray = dso_local global [200 x i32] zeroinitializer, align 4

; Function Attrs: nounwind uwtable
define dso_local void @pattern1_direct_streams(ptr noundef %A, i32 noundef signext %N) #0 {
entry:
  %A.addr = alloca ptr, align 8
  %N.addr = alloca i32, align 4
  %i = alloca i32, align 4
  store ptr %A, ptr %A.addr, align 8, !tbaa !13
  store i32 %N, ptr %N.addr, align 4, !tbaa !16
  call void @llvm.lifetime.start.p0(ptr %i) #2
  store i32 0, ptr %i, align 4, !tbaa !16
  br label %for.cond

for.cond:                                         ; preds = %for.inc, %entry
  %0 = load i32, ptr %i, align 4, !tbaa !16
  %1 = load i32, ptr %N.addr, align 4, !tbaa !16
  %cmp = icmp slt i32 %0, %1
  br i1 %cmp, label %for.body, label %for.cond.cleanup

for.cond.cleanup:                                 ; preds = %for.cond
  call void @llvm.lifetime.end.p0(ptr %i) #2
  br label %for.end

for.body:                                         ; preds = %for.cond
  %2 = load ptr, ptr %A.addr, align 8, !tbaa !13
  %3 = load i32, ptr %i, align 4, !tbaa !16
  %idxprom = sext i32 %3 to i64
  %arrayidx = getelementptr inbounds i32, ptr %2, i64 %idxprom
  %4 = load i32, ptr %arrayidx, align 4, !tbaa !16
  %inc = add nsw i32 %4, 1
  store i32 %inc, ptr %arrayidx, align 4, !tbaa !16
  %5 = load i32, ptr %i, align 4, !tbaa !16
  %add = add nsw i32 %5, 2
  %6 = load i32, ptr %N.addr, align 4, !tbaa !16
  %cmp1 = icmp slt i32 %add, %6
  br i1 %cmp1, label %if.then, label %if.end

if.then:                                          ; preds = %for.body
  %7 = load ptr, ptr %A.addr, align 8, !tbaa !13
  %8 = load i32, ptr %i, align 4, !tbaa !16
  %add2 = add nsw i32 %8, 2
  %idxprom3 = sext i32 %add2 to i64
  %arrayidx4 = getelementptr inbounds i32, ptr %7, i64 %idxprom3
  %9 = load i32, ptr %arrayidx4, align 4, !tbaa !16
  %inc5 = add nsw i32 %9, 1
  store i32 %inc5, ptr %arrayidx4, align 4, !tbaa !16
  br label %if.end

if.end:                                           ; preds = %if.then, %for.body
  %10 = load i32, ptr %i, align 4, !tbaa !16
  %mul = mul nsw i32 %10, 2
  %11 = load i32, ptr %N.addr, align 4, !tbaa !16
  %cmp6 = icmp slt i32 %mul, %11
  br i1 %cmp6, label %if.then7, label %if.end12

if.then7:                                         ; preds = %if.end
  %12 = load ptr, ptr %A.addr, align 8, !tbaa !13
  %13 = load i32, ptr %i, align 4, !tbaa !16
  %mul8 = mul nsw i32 %13, 2
  %idxprom9 = sext i32 %mul8 to i64
  %arrayidx10 = getelementptr inbounds i32, ptr %12, i64 %idxprom9
  %14 = load i32, ptr %arrayidx10, align 4, !tbaa !16
  %inc11 = add nsw i32 %14, 1
  store i32 %inc11, ptr %arrayidx10, align 4, !tbaa !16
  br label %if.end12

if.end12:                                         ; preds = %if.then7, %if.end
  %15 = load i32, ptr %i, align 4, !tbaa !16
  %mul13 = mul nsw i32 %15, 3
  %add14 = add nsw i32 %mul13, 3
  %16 = load i32, ptr %N.addr, align 4, !tbaa !16
  %cmp15 = icmp slt i32 %add14, %16
  br i1 %cmp15, label %if.then16, label %if.end22

if.then16:                                        ; preds = %if.end12
  %17 = load ptr, ptr %A.addr, align 8, !tbaa !13
  %18 = load i32, ptr %i, align 4, !tbaa !16
  %mul17 = mul nsw i32 %18, 3
  %add18 = add nsw i32 %mul17, 3
  %idxprom19 = sext i32 %add18 to i64
  %arrayidx20 = getelementptr inbounds i32, ptr %17, i64 %idxprom19
  %19 = load i32, ptr %arrayidx20, align 4, !tbaa !16
  %inc21 = add nsw i32 %19, 1
  store i32 %inc21, ptr %arrayidx20, align 4, !tbaa !16
  br label %if.end22

if.end22:                                         ; preds = %if.then16, %if.end12
  br label %for.inc

for.inc:                                          ; preds = %if.end22
  %20 = load i32, ptr %i, align 4, !tbaa !16
  %inc23 = add nsw i32 %20, 1
  store i32 %inc23, ptr %i, align 4, !tbaa !16
  br label %for.cond, !llvm.loop !17

for.end:                                          ; preds = %for.cond.cleanup
  ret void
}

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(ptr captures(none)) #1

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(ptr captures(none)) #1

; Function Attrs: nounwind uwtable
define dso_local void @pattern1_global_array(i32 noundef signext %N) #0 {
entry:
  %N.addr = alloca i32, align 4
  %i = alloca i32, align 4
  %i1 = alloca i32, align 4
  store i32 %N, ptr %N.addr, align 4, !tbaa !16
  call void @llvm.lifetime.start.p0(ptr %i) #2
  store i32 0, ptr %i, align 4, !tbaa !16
  br label %for.cond

for.cond:                                         ; preds = %for.inc, %entry
  %0 = load i32, ptr %i, align 4, !tbaa !16
  %cmp = icmp slt i32 %0, 200
  br i1 %cmp, label %for.body, label %for.cond.cleanup

for.cond.cleanup:                                 ; preds = %for.cond
  call void @llvm.lifetime.end.p0(ptr %i) #2
  br label %for.end

for.body:                                         ; preds = %for.cond
  %1 = load i32, ptr %i, align 4, !tbaa !16
  %idxprom = sext i32 %1 to i64
  %arrayidx = getelementptr inbounds [200 x i32], ptr @GlobalArray, i64 0, i64 %idxprom
  store i32 0, ptr %arrayidx, align 4, !tbaa !16
  br label %for.inc

for.inc:                                          ; preds = %for.body
  %2 = load i32, ptr %i, align 4, !tbaa !16
  %inc = add nsw i32 %2, 1
  store i32 %inc, ptr %i, align 4, !tbaa !16
  br label %for.cond, !llvm.loop !20

for.end:                                          ; preds = %for.cond.cleanup
  call void @llvm.lifetime.start.p0(ptr %i1) #2
  store i32 0, ptr %i1, align 4, !tbaa !16
  br label %for.cond2

for.cond2:                                        ; preds = %for.inc22, %for.end
  %3 = load i32, ptr %i1, align 4, !tbaa !16
  %4 = load i32, ptr %N.addr, align 4, !tbaa !16
  %cmp3 = icmp slt i32 %3, %4
  br i1 %cmp3, label %land.rhs, label %land.end

land.rhs:                                         ; preds = %for.cond2
  %5 = load i32, ptr %i1, align 4, !tbaa !16
  %cmp4 = icmp slt i32 %5, 200
  br label %land.end

land.end:                                         ; preds = %land.rhs, %for.cond2
  %6 = phi i1 [ false, %for.cond2 ], [ %cmp4, %land.rhs ]
  br i1 %6, label %for.body6, label %for.cond.cleanup5

for.cond.cleanup5:                                ; preds = %land.end
  call void @llvm.lifetime.end.p0(ptr %i1) #2
  br label %for.end24

for.body6:                                        ; preds = %land.end
  %7 = load i32, ptr %i1, align 4, !tbaa !16
  %idxprom7 = sext i32 %7 to i64
  %arrayidx8 = getelementptr inbounds [200 x i32], ptr @GlobalArray, i64 0, i64 %idxprom7
  %8 = load i32, ptr %arrayidx8, align 4, !tbaa !16
  %inc9 = add nsw i32 %8, 1
  store i32 %inc9, ptr %arrayidx8, align 4, !tbaa !16
  %9 = load i32, ptr %i1, align 4, !tbaa !16
  %add = add nsw i32 %9, 5
  %cmp10 = icmp slt i32 %add, 200
  br i1 %cmp10, label %if.then, label %if.end

if.then:                                          ; preds = %for.body6
  %10 = load i32, ptr %i1, align 4, !tbaa !16
  %add11 = add nsw i32 %10, 5
  %idxprom12 = sext i32 %add11 to i64
  %arrayidx13 = getelementptr inbounds [200 x i32], ptr @GlobalArray, i64 0, i64 %idxprom12
  %11 = load i32, ptr %arrayidx13, align 4, !tbaa !16
  %inc14 = add nsw i32 %11, 1
  store i32 %inc14, ptr %arrayidx13, align 4, !tbaa !16
  br label %if.end

if.end:                                           ; preds = %if.then, %for.body6
  %12 = load i32, ptr %i1, align 4, !tbaa !16
  %mul = mul nsw i32 %12, 2
  %cmp15 = icmp slt i32 %mul, 200
  br i1 %cmp15, label %if.then16, label %if.end21

if.then16:                                        ; preds = %if.end
  %13 = load i32, ptr %i1, align 4, !tbaa !16
  %mul17 = mul nsw i32 %13, 2
  %idxprom18 = sext i32 %mul17 to i64
  %arrayidx19 = getelementptr inbounds [200 x i32], ptr @GlobalArray, i64 0, i64 %idxprom18
  %14 = load i32, ptr %arrayidx19, align 4, !tbaa !16
  %inc20 = add nsw i32 %14, 1
  store i32 %inc20, ptr %arrayidx19, align 4, !tbaa !16
  br label %if.end21

if.end21:                                         ; preds = %if.then16, %if.end
  br label %for.inc22

for.inc22:                                        ; preds = %if.end21
  %15 = load i32, ptr %i1, align 4, !tbaa !16
  %inc23 = add nsw i32 %15, 1
  store i32 %inc23, ptr %i1, align 4, !tbaa !16
  br label %for.cond2, !llvm.loop !21

for.end24:                                        ; preds = %for.cond.cleanup5
  ret void
}

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
!16 = !{!10, !10, i64 0}
!17 = distinct !{!17, !18, !19}
!18 = !{!"llvm.loop.mustprogress"}
!19 = !{!"llvm.loop.unroll.disable"}
!20 = distinct !{!20, !18, !19}
!21 = distinct !{!21, !18, !19}
