; ModuleID = 'pattern9_mixed.c'
source_filename = "pattern9_mixed.c"
target datalayout = "e-m:e-p:64:64-i64:64-i128:128-n32:64-S128"
target triple = "riscv64-unknown-linux-gnu"

%struct.Point = type { i32, i32, i32 }

; Function Attrs: nounwind uwtable
define dso_local void @pattern9_mixed(ptr noundef %A, ptr noundef %B, ptr noundef %points, ptr noundef %D2B, i32 noundef signext %N) #0 {
entry:
  %A.addr = alloca ptr, align 8
  %B.addr = alloca ptr, align 8
  %points.addr = alloca ptr, align 8
  %D2B.addr = alloca ptr, align 8
  %N.addr = alloca i32, align 4
  %i = alloca i32, align 4
  %cleanup.dest.slot = alloca i32, align 4
  %idx = alloca i32, align 4
  %j = alloca i32, align 4
  store ptr %A, ptr %A.addr, align 8, !tbaa !13
  store ptr %B, ptr %B.addr, align 8, !tbaa !13
  store ptr %points, ptr %points.addr, align 8, !tbaa !16
  store ptr %D2B, ptr %D2B.addr, align 8, !tbaa !13
  store i32 %N, ptr %N.addr, align 4, !tbaa !18
  call void @llvm.lifetime.start.p0(ptr %i) #4
  store i32 0, ptr %i, align 4, !tbaa !18
  br label %for.cond

for.cond:                                         ; preds = %for.inc42, %entry
  %0 = load i32, ptr %i, align 4, !tbaa !18
  %1 = load i32, ptr %N.addr, align 4, !tbaa !18
  %cmp = icmp slt i32 %0, %1
  br i1 %cmp, label %land.rhs, label %land.end

land.rhs:                                         ; preds = %for.cond
  %2 = load i32, ptr %i, align 4, !tbaa !18
  %cmp1 = icmp slt i32 %2, 10
  br label %land.end

land.end:                                         ; preds = %land.rhs, %for.cond
  %3 = phi i1 [ false, %for.cond ], [ %cmp1, %land.rhs ]
  br i1 %3, label %for.body, label %for.cond.cleanup

for.cond.cleanup:                                 ; preds = %land.end
  store i32 2, ptr %cleanup.dest.slot, align 4
  call void @llvm.lifetime.end.p0(ptr %i) #4
  br label %for.end44

for.body:                                         ; preds = %land.end
  call void @llvm.lifetime.start.p0(ptr %idx) #4
  %4 = load ptr, ptr %A.addr, align 8, !tbaa !13
  %5 = load i32, ptr %i, align 4, !tbaa !18
  %idxprom = sext i32 %5 to i64
  %arrayidx = getelementptr inbounds i32, ptr %4, i64 %idxprom
  %6 = load i32, ptr %arrayidx, align 4, !tbaa !18
  %7 = load i32, ptr %N.addr, align 4, !tbaa !18
  %rem = srem i32 %6, %7
  store i32 %rem, ptr %idx, align 4, !tbaa !18
  %8 = load ptr, ptr %A.addr, align 8, !tbaa !13
  %9 = load i32, ptr %i, align 4, !tbaa !18
  %idxprom2 = sext i32 %9 to i64
  %arrayidx3 = getelementptr inbounds i32, ptr %8, i64 %idxprom2
  %10 = load i32, ptr %arrayidx3, align 4, !tbaa !18
  %add = add nsw i32 %10, 100
  %11 = load ptr, ptr %B.addr, align 8, !tbaa !13
  %12 = load i32, ptr %idx, align 4, !tbaa !18
  %idxprom4 = sext i32 %12 to i64
  %arrayidx5 = getelementptr inbounds i32, ptr %11, i64 %idxprom4
  store i32 %add, ptr %arrayidx5, align 4, !tbaa !18
  %13 = load ptr, ptr %B.addr, align 8, !tbaa !13
  %14 = load i32, ptr %idx, align 4, !tbaa !18
  %idxprom6 = sext i32 %14 to i64
  %arrayidx7 = getelementptr inbounds i32, ptr %13, i64 %idxprom6
  %15 = load i32, ptr %arrayidx7, align 4, !tbaa !18
  %16 = load ptr, ptr %points.addr, align 8, !tbaa !16
  %17 = load i32, ptr %i, align 4, !tbaa !18
  %idxprom8 = sext i32 %17 to i64
  %arrayidx9 = getelementptr inbounds %struct.Point, ptr %16, i64 %idxprom8
  %x = getelementptr inbounds nuw %struct.Point, ptr %arrayidx9, i32 0, i32 0
  store i32 %15, ptr %x, align 4, !tbaa !19
  %18 = load ptr, ptr %A.addr, align 8, !tbaa !13
  %19 = load i32, ptr %i, align 4, !tbaa !18
  %idxprom10 = sext i32 %19 to i64
  %arrayidx11 = getelementptr inbounds i32, ptr %18, i64 %idxprom10
  %20 = load i32, ptr %arrayidx11, align 4, !tbaa !18
  %21 = load ptr, ptr %points.addr, align 8, !tbaa !16
  %22 = load i32, ptr %idx, align 4, !tbaa !18
  %idxprom12 = sext i32 %22 to i64
  %arrayidx13 = getelementptr inbounds %struct.Point, ptr %21, i64 %idxprom12
  %y = getelementptr inbounds nuw %struct.Point, ptr %arrayidx13, i32 0, i32 1
  store i32 %20, ptr %y, align 4, !tbaa !21
  call void @llvm.lifetime.start.p0(ptr %j) #4
  store i32 0, ptr %j, align 4, !tbaa !18
  br label %for.cond14

for.cond14:                                       ; preds = %for.inc, %for.body
  %23 = load i32, ptr %j, align 4, !tbaa !18
  %cmp15 = icmp slt i32 %23, 10
  br i1 %cmp15, label %for.body17, label %for.cond.cleanup16

for.cond.cleanup16:                               ; preds = %for.cond14
  store i32 5, ptr %cleanup.dest.slot, align 4
  call void @llvm.lifetime.end.p0(ptr %j) #4
  br label %for.end

for.body17:                                       ; preds = %for.cond14
  %24 = load ptr, ptr %A.addr, align 8, !tbaa !13
  %25 = load i32, ptr %i, align 4, !tbaa !18
  %idxprom18 = sext i32 %25 to i64
  %arrayidx19 = getelementptr inbounds i32, ptr %24, i64 %idxprom18
  %26 = load i32, ptr %arrayidx19, align 4, !tbaa !18
  %27 = load i32, ptr %j, align 4, !tbaa !18
  %add20 = add nsw i32 %26, %27
  %28 = load ptr, ptr %D2B.addr, align 8, !tbaa !13
  %29 = load i32, ptr %i, align 4, !tbaa !18
  %idxprom21 = sext i32 %29 to i64
  %arrayidx22 = getelementptr inbounds [10 x i32], ptr %28, i64 %idxprom21
  %30 = load i32, ptr %j, align 4, !tbaa !18
  %idxprom23 = sext i32 %30 to i64
  %arrayidx24 = getelementptr inbounds [10 x i32], ptr %arrayidx22, i64 0, i64 %idxprom23
  store i32 %add20, ptr %arrayidx24, align 4, !tbaa !18
  %31 = load ptr, ptr %B.addr, align 8, !tbaa !13
  %32 = load i32, ptr %idx, align 4, !tbaa !18
  %idxprom25 = sext i32 %32 to i64
  %arrayidx26 = getelementptr inbounds i32, ptr %31, i64 %idxprom25
  %33 = load i32, ptr %arrayidx26, align 4, !tbaa !18
  %34 = load i32, ptr %j, align 4, !tbaa !18
  %sub = sub nsw i32 %33, %34
  %35 = load ptr, ptr %D2B.addr, align 8, !tbaa !13
  %36 = load i32, ptr %idx, align 4, !tbaa !18
  %rem27 = srem i32 %36, 10
  %idxprom28 = sext i32 %rem27 to i64
  %arrayidx29 = getelementptr inbounds [10 x i32], ptr %35, i64 %idxprom28
  %37 = load i32, ptr %j, align 4, !tbaa !18
  %idxprom30 = sext i32 %37 to i64
  %arrayidx31 = getelementptr inbounds [10 x i32], ptr %arrayidx29, i64 0, i64 %idxprom30
  store i32 %sub, ptr %arrayidx31, align 4, !tbaa !18
  %38 = load ptr, ptr %B.addr, align 8, !tbaa !13
  %39 = load i32, ptr %idx, align 4, !tbaa !18
  %40 = load i32, ptr %j, align 4, !tbaa !18
  %add32 = add nsw i32 %39, %40
  %idxprom33 = sext i32 %add32 to i64
  %arrayidx34 = getelementptr inbounds i32, ptr %38, i64 %idxprom33
  %41 = load i32, ptr %arrayidx34, align 4, !tbaa !18
  %42 = load i32, ptr %j, align 4, !tbaa !18
  %sub35 = sub nsw i32 %41, %42
  %43 = load ptr, ptr %D2B.addr, align 8, !tbaa !13
  %44 = load i32, ptr %idx, align 4, !tbaa !18
  %rem36 = srem i32 %44, 10
  %idxprom37 = sext i32 %rem36 to i64
  %arrayidx38 = getelementptr inbounds [10 x i32], ptr %43, i64 %idxprom37
  %45 = load i32, ptr %j, align 4, !tbaa !18
  %add39 = add nsw i32 %45, 1
  %idxprom40 = sext i32 %add39 to i64
  %arrayidx41 = getelementptr inbounds [10 x i32], ptr %arrayidx38, i64 0, i64 %idxprom40
  store i32 %sub35, ptr %arrayidx41, align 4, !tbaa !18
  br label %for.inc

for.inc:                                          ; preds = %for.body17
  %46 = load i32, ptr %j, align 4, !tbaa !18
  %inc = add nsw i32 %46, 1
  store i32 %inc, ptr %j, align 4, !tbaa !18
  br label %for.cond14, !llvm.loop !22

for.end:                                          ; preds = %for.cond.cleanup16
  call void @llvm.lifetime.end.p0(ptr %idx) #4
  br label %for.inc42

for.inc42:                                        ; preds = %for.end
  %47 = load i32, ptr %i, align 4, !tbaa !18
  %inc43 = add nsw i32 %47, 1
  store i32 %inc43, ptr %i, align 4, !tbaa !18
  br label %for.cond, !llvm.loop !25

for.end44:                                        ; preds = %for.cond.cleanup
  ret void
}

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(ptr captures(none)) #1

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(ptr captures(none)) #1

; Function Attrs: nounwind uwtable
define dso_local signext i32 @main() #0 {
entry:
  %retval = alloca i32, align 4
  %N1 = alloca i32, align 4
  %A1 = alloca ptr, align 8
  %B1 = alloca ptr, align 8
  %points1 = alloca ptr, align 8
  %D2B1 = alloca ptr, align 8
  %N2 = alloca i32, align 4
  %A2 = alloca ptr, align 8
  %B2 = alloca ptr, align 8
  %points2 = alloca ptr, align 8
  %D2B2 = alloca ptr, align 8
  store i32 0, ptr %retval, align 4
  call void @llvm.lifetime.start.p0(ptr %N1) #4
  store i32 50, ptr %N1, align 4, !tbaa !18
  call void @llvm.lifetime.start.p0(ptr %A1) #4
  %0 = load i32, ptr %N1, align 4, !tbaa !18
  %conv = sext i32 %0 to i64
  %call = call noalias ptr @calloc(i64 noundef %conv, i64 noundef 4) #5
  store ptr %call, ptr %A1, align 8, !tbaa !13
  call void @llvm.lifetime.start.p0(ptr %B1) #4
  %1 = load i32, ptr %N1, align 4, !tbaa !18
  %conv1 = sext i32 %1 to i64
  %call2 = call noalias ptr @calloc(i64 noundef %conv1, i64 noundef 4) #5
  store ptr %call2, ptr %B1, align 8, !tbaa !13
  call void @llvm.lifetime.start.p0(ptr %points1) #4
  %2 = load i32, ptr %N1, align 4, !tbaa !18
  %conv3 = sext i32 %2 to i64
  %call4 = call noalias ptr @calloc(i64 noundef %conv3, i64 noundef 12) #5
  store ptr %call4, ptr %points1, align 8, !tbaa !16
  call void @llvm.lifetime.start.p0(ptr %D2B1) #4
  %call5 = call noalias ptr @calloc(i64 noundef 10, i64 noundef 40) #5
  store ptr %call5, ptr %D2B1, align 8, !tbaa !13
  %3 = load ptr, ptr %A1, align 8, !tbaa !13
  %4 = load ptr, ptr %B1, align 8, !tbaa !13
  %5 = load ptr, ptr %points1, align 8, !tbaa !16
  %6 = load ptr, ptr %D2B1, align 8, !tbaa !13
  %7 = load i32, ptr %N1, align 4, !tbaa !18
  call void @pattern9_mixed(ptr noundef %3, ptr noundef %4, ptr noundef %5, ptr noundef %6, i32 noundef signext %7)
  %8 = load ptr, ptr %A1, align 8, !tbaa !13
  call void @free(ptr noundef %8) #4
  %9 = load ptr, ptr %B1, align 8, !tbaa !13
  call void @free(ptr noundef %9) #4
  %10 = load ptr, ptr %points1, align 8, !tbaa !16
  call void @free(ptr noundef %10) #4
  %11 = load ptr, ptr %D2B1, align 8, !tbaa !13
  call void @free(ptr noundef %11) #4
  call void @llvm.lifetime.start.p0(ptr %N2) #4
  store i32 100, ptr %N2, align 4, !tbaa !18
  call void @llvm.lifetime.start.p0(ptr %A2) #4
  %12 = load i32, ptr %N2, align 4, !tbaa !18
  %conv6 = sext i32 %12 to i64
  %call7 = call noalias ptr @calloc(i64 noundef %conv6, i64 noundef 4) #5
  store ptr %call7, ptr %A2, align 8, !tbaa !13
  call void @llvm.lifetime.start.p0(ptr %B2) #4
  %13 = load i32, ptr %N2, align 4, !tbaa !18
  %conv8 = sext i32 %13 to i64
  %call9 = call noalias ptr @calloc(i64 noundef %conv8, i64 noundef 4) #5
  store ptr %call9, ptr %B2, align 8, !tbaa !13
  call void @llvm.lifetime.start.p0(ptr %points2) #4
  %14 = load i32, ptr %N2, align 4, !tbaa !18
  %conv10 = sext i32 %14 to i64
  %call11 = call noalias ptr @calloc(i64 noundef %conv10, i64 noundef 12) #5
  store ptr %call11, ptr %points2, align 8, !tbaa !16
  call void @llvm.lifetime.start.p0(ptr %D2B2) #4
  %call12 = call noalias ptr @calloc(i64 noundef 10, i64 noundef 40) #5
  store ptr %call12, ptr %D2B2, align 8, !tbaa !13
  %15 = load ptr, ptr %A2, align 8, !tbaa !13
  %16 = load ptr, ptr %B2, align 8, !tbaa !13
  %17 = load ptr, ptr %points2, align 8, !tbaa !16
  %18 = load ptr, ptr %D2B2, align 8, !tbaa !13
  %19 = load i32, ptr %N2, align 4, !tbaa !18
  call void @pattern9_mixed(ptr noundef %15, ptr noundef %16, ptr noundef %17, ptr noundef %18, i32 noundef signext %19)
  %20 = load ptr, ptr %A2, align 8, !tbaa !13
  call void @free(ptr noundef %20) #4
  %21 = load ptr, ptr %B2, align 8, !tbaa !13
  call void @free(ptr noundef %21) #4
  %22 = load ptr, ptr %points2, align 8, !tbaa !16
  call void @free(ptr noundef %22) #4
  %23 = load ptr, ptr %D2B2, align 8, !tbaa !13
  call void @free(ptr noundef %23) #4
  call void @llvm.lifetime.end.p0(ptr %D2B2) #4
  call void @llvm.lifetime.end.p0(ptr %points2) #4
  call void @llvm.lifetime.end.p0(ptr %B2) #4
  call void @llvm.lifetime.end.p0(ptr %A2) #4
  call void @llvm.lifetime.end.p0(ptr %N2) #4
  call void @llvm.lifetime.end.p0(ptr %D2B1) #4
  call void @llvm.lifetime.end.p0(ptr %points1) #4
  call void @llvm.lifetime.end.p0(ptr %B1) #4
  call void @llvm.lifetime.end.p0(ptr %A1) #4
  call void @llvm.lifetime.end.p0(ptr %N1) #4
  ret i32 0
}

; Function Attrs: nounwind allocsize(0,1)
declare noalias ptr @calloc(i64 noundef, i64 noundef) #2

; Function Attrs: nounwind
declare void @free(ptr noundef) #3

attributes #0 = { nounwind uwtable "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="generic-rv64" "target-features"="+64bit,+a,+c,+d,+f,+i,+m,+relax,+zaamo,+zalrsc,+zca,+zcd,+zicsr,+zifencei,+zmmul,-b,-e,-experimental-p,-experimental-smpmpmt,-experimental-svukte,-experimental-xqccmt,-experimental-xsfmclic,-experimental-xsfsclic,-experimental-y,-experimental-zibi,-experimental-zicfilp,-experimental-zicfiss,-experimental-zvabd,-experimental-zvbc32e,-experimental-zvdot4a8i,-experimental-zvfbdota32f,-experimental-zvfbfa,-experimental-zvfofp8min,-experimental-zvfqwbdota8f,-experimental-zvfqwdota8f,-experimental-zvfwbdota16bf,-experimental-zvfwdota16bf,-experimental-zvkgs,-experimental-zvqwbdota16i,-experimental-zvqwbdota8i,-experimental-zvqwdota16i,-experimental-zvqwdota8i,-experimental-zvvfmm,-experimental-zvvmm,-experimental-zvvmtls,-experimental-zvvmttls,-experimental-zvzip,-h,-q,-sdext,-sdtrig,-sha,-shcounterenw,-shgatpa,-shlcofideleg,-shtvala,-shvsatpa,-shvstvala,-shvstvecd,-smaia,-smcdeleg,-smcntrpmf,-smcsrind,-smctr,-smdbltrp,-smepmp,-smmpm,-smnpm,-smrnmi,-smstateen,-ssaia,-ssccfg,-ssccptr,-sscofpmf,-sscounterenw,-sscsrind,-ssctr,-ssdbltrp,-ssnpm,-sspm,-ssqosid,-ssstateen,-ssstrict,-sstc,-sstvala,-sstvecd,-ssu64xl,-supm,-svade,-svadu,-svbare,-svinval,-svnapot,-svpbmt,-svrsw60t59b,-svvptc,-v,-xaifet,-xandesbfhcvt,-xandesperf,-xandesvbfhcvt,-xandesvdot,-xandesvpackfph,-xandesvsinth,-xandesvsintload,-xcheriot,-xcvalu,-xcvbi,-xcvbitmanip,-xcvelw,-xcvmac,-xcvmem,-xcvsimd,-xmipscbop,-xmipscmov,-xmipsexectl,-xmipslsp,-xqccmp,-xqci,-xqcia,-xqciac,-xqcibi,-xqcibm,-xqcicli,-xqcicm,-xqcics,-xqcicsr,-xqciint,-xqciio,-xqcilb,-xqcili,-xqcilia,-xqcilo,-xqcilsm,-xqcisim,-xqcisls,-xqcisync,-xsfcease,-xsfmm128t,-xsfmm16t,-xsfmm32a,-xsfmm32a16f,-xsfmm32a32f,-xsfmm32a8f,-xsfmm32a8i,-xsfmm32t,-xsfmm64a64f,-xsfmm64t,-xsfmmbase,-xsfvcp,-xsfvfbfexp16e,-xsfvfexp16e,-xsfvfexp32e,-xsfvfexpa,-xsfvfexpa64e,-xsfvfnrclipxfqf,-xsfvfwmaccqqq,-xsfvqmaccdod,-xsfvqmaccqoq,-xsifivecdiscarddlone,-xsifivecflushdlone,-xsmtvdot,-xsmtvdotii,-xtheadba,-xtheadbb,-xtheadbs,-xtheadcmo,-xtheadcondmov,-xtheadfmemidx,-xtheadmac,-xtheadmemidx,-xtheadmempair,-xtheadsync,-xtheadvdot,-xventanacondops,-xwchc,-za128rs,-za64rs,-zabha,-zacas,-zalasr,-zama16b,-zawrs,-zba,-zbb,-zbc,-zbkb,-zbkc,-zbkx,-zbs,-zcb,-zce,-zcf,-zclsd,-zcmop,-zcmp,-zcmt,-zdinx,-zfa,-zfbfmin,-zfh,-zfhmin,-zfinx,-zhinx,-zhinxmin,-zic64b,-zicbom,-zicbop,-zicboz,-ziccamoa,-ziccamoc,-ziccid,-ziccif,-zicclsm,-ziccrse,-zicntr,-zicond,-zihintntl,-zihintpause,-zihpm,-zilsd,-zimop,-zk,-zkn,-zknd,-zkne,-zknh,-zkr,-zks,-zksed,-zksh,-zkt,-ztso,-zvbb,-zvbc,-zve32f,-zve32x,-zve64d,-zve64f,-zve64x,-zvfbfmin,-zvfbfwma,-zvfh,-zvfhmin,-zvkb,-zvkg,-zvkn,-zvknc,-zvkned,-zvkng,-zvknha,-zvknhb,-zvks,-zvksc,-zvksed,-zvksg,-zvksh,-zvkt,-zvl1024b,-zvl128b,-zvl16384b,-zvl2048b,-zvl256b,-zvl32768b,-zvl32b,-zvl4096b,-zvl512b,-zvl64b,-zvl65536b,-zvl8192b" }
attributes #1 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { nounwind allocsize(0,1) "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="generic-rv64" "target-features"="+64bit,+a,+c,+d,+f,+i,+m,+relax,+zaamo,+zalrsc,+zca,+zcd,+zicsr,+zifencei,+zmmul,-b,-e,-experimental-p,-experimental-smpmpmt,-experimental-svukte,-experimental-xqccmt,-experimental-xsfmclic,-experimental-xsfsclic,-experimental-y,-experimental-zibi,-experimental-zicfilp,-experimental-zicfiss,-experimental-zvabd,-experimental-zvbc32e,-experimental-zvdot4a8i,-experimental-zvfbdota32f,-experimental-zvfbfa,-experimental-zvfofp8min,-experimental-zvfqwbdota8f,-experimental-zvfqwdota8f,-experimental-zvfwbdota16bf,-experimental-zvfwdota16bf,-experimental-zvkgs,-experimental-zvqwbdota16i,-experimental-zvqwbdota8i,-experimental-zvqwdota16i,-experimental-zvqwdota8i,-experimental-zvvfmm,-experimental-zvvmm,-experimental-zvvmtls,-experimental-zvvmttls,-experimental-zvzip,-h,-q,-sdext,-sdtrig,-sha,-shcounterenw,-shgatpa,-shlcofideleg,-shtvala,-shvsatpa,-shvstvala,-shvstvecd,-smaia,-smcdeleg,-smcntrpmf,-smcsrind,-smctr,-smdbltrp,-smepmp,-smmpm,-smnpm,-smrnmi,-smstateen,-ssaia,-ssccfg,-ssccptr,-sscofpmf,-sscounterenw,-sscsrind,-ssctr,-ssdbltrp,-ssnpm,-sspm,-ssqosid,-ssstateen,-ssstrict,-sstc,-sstvala,-sstvecd,-ssu64xl,-supm,-svade,-svadu,-svbare,-svinval,-svnapot,-svpbmt,-svrsw60t59b,-svvptc,-v,-xaifet,-xandesbfhcvt,-xandesperf,-xandesvbfhcvt,-xandesvdot,-xandesvpackfph,-xandesvsinth,-xandesvsintload,-xcheriot,-xcvalu,-xcvbi,-xcvbitmanip,-xcvelw,-xcvmac,-xcvmem,-xcvsimd,-xmipscbop,-xmipscmov,-xmipsexectl,-xmipslsp,-xqccmp,-xqci,-xqcia,-xqciac,-xqcibi,-xqcibm,-xqcicli,-xqcicm,-xqcics,-xqcicsr,-xqciint,-xqciio,-xqcilb,-xqcili,-xqcilia,-xqcilo,-xqcilsm,-xqcisim,-xqcisls,-xqcisync,-xsfcease,-xsfmm128t,-xsfmm16t,-xsfmm32a,-xsfmm32a16f,-xsfmm32a32f,-xsfmm32a8f,-xsfmm32a8i,-xsfmm32t,-xsfmm64a64f,-xsfmm64t,-xsfmmbase,-xsfvcp,-xsfvfbfexp16e,-xsfvfexp16e,-xsfvfexp32e,-xsfvfexpa,-xsfvfexpa64e,-xsfvfnrclipxfqf,-xsfvfwmaccqqq,-xsfvqmaccdod,-xsfvqmaccqoq,-xsifivecdiscarddlone,-xsifivecflushdlone,-xsmtvdot,-xsmtvdotii,-xtheadba,-xtheadbb,-xtheadbs,-xtheadcmo,-xtheadcondmov,-xtheadfmemidx,-xtheadmac,-xtheadmemidx,-xtheadmempair,-xtheadsync,-xtheadvdot,-xventanacondops,-xwchc,-za128rs,-za64rs,-zabha,-zacas,-zalasr,-zama16b,-zawrs,-zba,-zbb,-zbc,-zbkb,-zbkc,-zbkx,-zbs,-zcb,-zce,-zcf,-zclsd,-zcmop,-zcmp,-zcmt,-zdinx,-zfa,-zfbfmin,-zfh,-zfhmin,-zfinx,-zhinx,-zhinxmin,-zic64b,-zicbom,-zicbop,-zicboz,-ziccamoa,-ziccamoc,-ziccid,-ziccif,-zicclsm,-ziccrse,-zicntr,-zicond,-zihintntl,-zihintpause,-zihpm,-zilsd,-zimop,-zk,-zkn,-zknd,-zkne,-zknh,-zkr,-zks,-zksed,-zksh,-zkt,-ztso,-zvbb,-zvbc,-zve32f,-zve32x,-zve64d,-zve64f,-zve64x,-zvfbfmin,-zvfbfwma,-zvfh,-zvfhmin,-zvkb,-zvkg,-zvkn,-zvknc,-zvkned,-zvkng,-zvknha,-zvknhb,-zvks,-zvksc,-zvksed,-zvksg,-zvksh,-zvkt,-zvl1024b,-zvl128b,-zvl16384b,-zvl2048b,-zvl256b,-zvl32768b,-zvl32b,-zvl4096b,-zvl512b,-zvl64b,-zvl65536b,-zvl8192b" }
attributes #3 = { nounwind "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="generic-rv64" "target-features"="+64bit,+a,+c,+d,+f,+i,+m,+relax,+zaamo,+zalrsc,+zca,+zcd,+zicsr,+zifencei,+zmmul,-b,-e,-experimental-p,-experimental-smpmpmt,-experimental-svukte,-experimental-xqccmt,-experimental-xsfmclic,-experimental-xsfsclic,-experimental-y,-experimental-zibi,-experimental-zicfilp,-experimental-zicfiss,-experimental-zvabd,-experimental-zvbc32e,-experimental-zvdot4a8i,-experimental-zvfbdota32f,-experimental-zvfbfa,-experimental-zvfofp8min,-experimental-zvfqwbdota8f,-experimental-zvfqwdota8f,-experimental-zvfwbdota16bf,-experimental-zvfwdota16bf,-experimental-zvkgs,-experimental-zvqwbdota16i,-experimental-zvqwbdota8i,-experimental-zvqwdota16i,-experimental-zvqwdota8i,-experimental-zvvfmm,-experimental-zvvmm,-experimental-zvvmtls,-experimental-zvvmttls,-experimental-zvzip,-h,-q,-sdext,-sdtrig,-sha,-shcounterenw,-shgatpa,-shlcofideleg,-shtvala,-shvsatpa,-shvstvala,-shvstvecd,-smaia,-smcdeleg,-smcntrpmf,-smcsrind,-smctr,-smdbltrp,-smepmp,-smmpm,-smnpm,-smrnmi,-smstateen,-ssaia,-ssccfg,-ssccptr,-sscofpmf,-sscounterenw,-sscsrind,-ssctr,-ssdbltrp,-ssnpm,-sspm,-ssqosid,-ssstateen,-ssstrict,-sstc,-sstvala,-sstvecd,-ssu64xl,-supm,-svade,-svadu,-svbare,-svinval,-svnapot,-svpbmt,-svrsw60t59b,-svvptc,-v,-xaifet,-xandesbfhcvt,-xandesperf,-xandesvbfhcvt,-xandesvdot,-xandesvpackfph,-xandesvsinth,-xandesvsintload,-xcheriot,-xcvalu,-xcvbi,-xcvbitmanip,-xcvelw,-xcvmac,-xcvmem,-xcvsimd,-xmipscbop,-xmipscmov,-xmipsexectl,-xmipslsp,-xqccmp,-xqci,-xqcia,-xqciac,-xqcibi,-xqcibm,-xqcicli,-xqcicm,-xqcics,-xqcicsr,-xqciint,-xqciio,-xqcilb,-xqcili,-xqcilia,-xqcilo,-xqcilsm,-xqcisim,-xqcisls,-xqcisync,-xsfcease,-xsfmm128t,-xsfmm16t,-xsfmm32a,-xsfmm32a16f,-xsfmm32a32f,-xsfmm32a8f,-xsfmm32a8i,-xsfmm32t,-xsfmm64a64f,-xsfmm64t,-xsfmmbase,-xsfvcp,-xsfvfbfexp16e,-xsfvfexp16e,-xsfvfexp32e,-xsfvfexpa,-xsfvfexpa64e,-xsfvfnrclipxfqf,-xsfvfwmaccqqq,-xsfvqmaccdod,-xsfvqmaccqoq,-xsifivecdiscarddlone,-xsifivecflushdlone,-xsmtvdot,-xsmtvdotii,-xtheadba,-xtheadbb,-xtheadbs,-xtheadcmo,-xtheadcondmov,-xtheadfmemidx,-xtheadmac,-xtheadmemidx,-xtheadmempair,-xtheadsync,-xtheadvdot,-xventanacondops,-xwchc,-za128rs,-za64rs,-zabha,-zacas,-zalasr,-zama16b,-zawrs,-zba,-zbb,-zbc,-zbkb,-zbkc,-zbkx,-zbs,-zcb,-zce,-zcf,-zclsd,-zcmop,-zcmp,-zcmt,-zdinx,-zfa,-zfbfmin,-zfh,-zfhmin,-zfinx,-zhinx,-zhinxmin,-zic64b,-zicbom,-zicbop,-zicboz,-ziccamoa,-ziccamoc,-ziccid,-ziccif,-zicclsm,-ziccrse,-zicntr,-zicond,-zihintntl,-zihintpause,-zihpm,-zilsd,-zimop,-zk,-zkn,-zknd,-zkne,-zknh,-zkr,-zks,-zksed,-zksh,-zkt,-ztso,-zvbb,-zvbc,-zve32f,-zve32x,-zve64d,-zve64f,-zve64x,-zvfbfmin,-zvfbfwma,-zvfh,-zvfhmin,-zvkb,-zvkg,-zvkn,-zvknc,-zvkned,-zvkng,-zvknha,-zvknhb,-zvks,-zvksc,-zvksed,-zvksg,-zvksh,-zvkt,-zvl1024b,-zvl128b,-zvl16384b,-zvl2048b,-zvl256b,-zvl32768b,-zvl32b,-zvl4096b,-zvl512b,-zvl64b,-zvl65536b,-zvl8192b" }
attributes #4 = { nounwind }
attributes #5 = { nounwind allocsize(0,1) }

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
!22 = distinct !{!22, !23, !24}
!23 = !{!"llvm.loop.mustprogress"}
!24 = !{!"llvm.loop.unroll.disable"}
!25 = distinct !{!25, !23, !24}
