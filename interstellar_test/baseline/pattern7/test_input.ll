; ModuleID = 'pattern7_2d_fixed.c'
source_filename = "pattern7_2d_fixed.c"
target datalayout = "e-m:e-p:64:64-i64:64-i128:128-n32:64-S128"
target triple = "riscv64-unknown-linux-gnu"

; Function Attrs: nounwind uwtable
define dso_local void @pattern7_2d_fixed(ptr noundef %A, ptr noundef %D2B, i32 noundef signext %N) #0 {
entry:
  %A.addr = alloca ptr, align 8
  %D2B.addr = alloca ptr, align 8
  %N.addr = alloca i32, align 4
  %D2B_rows = alloca i32, align 4
  %i = alloca i32, align 4
  %cleanup.dest.slot = alloca i32, align 4
  %j = alloca i32, align 4
  %idx_i = alloca i32, align 4
  %idx_j = alloca i32, align 4
  store ptr %A, ptr %A.addr, align 8, !tbaa !13
  store ptr %D2B, ptr %D2B.addr, align 8, !tbaa !13
  store i32 %N, ptr %N.addr, align 4, !tbaa !16
  call void @llvm.lifetime.start.p0(ptr %D2B_rows) #4
  store i32 10, ptr %D2B_rows, align 4, !tbaa !16
  call void @llvm.lifetime.start.p0(ptr %i) #4
  store i32 0, ptr %i, align 4, !tbaa !16
  br label %for.cond

for.cond:                                         ; preds = %for.inc24, %entry
  %0 = load i32, ptr %i, align 4, !tbaa !16
  %1 = load i32, ptr %D2B_rows, align 4, !tbaa !16
  %cmp = icmp slt i32 %0, %1
  br i1 %cmp, label %for.body, label %for.cond.cleanup

for.cond.cleanup:                                 ; preds = %for.cond
  store i32 2, ptr %cleanup.dest.slot, align 4
  call void @llvm.lifetime.end.p0(ptr %i) #4
  br label %for.end26

for.body:                                         ; preds = %for.cond
  call void @llvm.lifetime.start.p0(ptr %j) #4
  store i32 0, ptr %j, align 4, !tbaa !16
  br label %for.cond1

for.cond1:                                        ; preds = %for.inc, %for.body
  %2 = load i32, ptr %j, align 4, !tbaa !16
  %cmp2 = icmp slt i32 %2, 10
  br i1 %cmp2, label %for.body4, label %for.cond.cleanup3

for.cond.cleanup3:                                ; preds = %for.cond1
  store i32 5, ptr %cleanup.dest.slot, align 4
  call void @llvm.lifetime.end.p0(ptr %j) #4
  br label %for.end

for.body4:                                        ; preds = %for.cond1
  %3 = load ptr, ptr %D2B.addr, align 8, !tbaa !13
  %4 = load i32, ptr %i, align 4, !tbaa !16
  %idxprom = sext i32 %4 to i64
  %arrayidx = getelementptr inbounds [10 x i32], ptr %3, i64 %idxprom
  %5 = load i32, ptr %j, align 4, !tbaa !16
  %idxprom5 = sext i32 %5 to i64
  %arrayidx6 = getelementptr inbounds [10 x i32], ptr %arrayidx, i64 0, i64 %idxprom5
  %6 = load i32, ptr %arrayidx6, align 4, !tbaa !16
  %inc = add nsw i32 %6, 1
  store i32 %inc, ptr %arrayidx6, align 4, !tbaa !16
  %7 = load i32, ptr %i, align 4, !tbaa !16
  %8 = load i32, ptr %N.addr, align 4, !tbaa !16
  %cmp7 = icmp slt i32 %7, %8
  br i1 %cmp7, label %if.then, label %if.end

if.then:                                          ; preds = %for.body4
  call void @llvm.lifetime.start.p0(ptr %idx_i) #4
  %9 = load ptr, ptr %A.addr, align 8, !tbaa !13
  %10 = load i32, ptr %i, align 4, !tbaa !16
  %idxprom8 = sext i32 %10 to i64
  %arrayidx9 = getelementptr inbounds i32, ptr %9, i64 %idxprom8
  %11 = load i32, ptr %arrayidx9, align 4, !tbaa !16
  %12 = load i32, ptr %D2B_rows, align 4, !tbaa !16
  %rem = srem i32 %11, %12
  store i32 %rem, ptr %idx_i, align 4, !tbaa !16
  %13 = load ptr, ptr %D2B.addr, align 8, !tbaa !13
  %14 = load i32, ptr %idx_i, align 4, !tbaa !16
  %idxprom10 = sext i32 %14 to i64
  %arrayidx11 = getelementptr inbounds [10 x i32], ptr %13, i64 %idxprom10
  %15 = load i32, ptr %j, align 4, !tbaa !16
  %idxprom12 = sext i32 %15 to i64
  %arrayidx13 = getelementptr inbounds [10 x i32], ptr %arrayidx11, i64 0, i64 %idxprom12
  %16 = load i32, ptr %arrayidx13, align 4, !tbaa !16
  %inc14 = add nsw i32 %16, 1
  store i32 %inc14, ptr %arrayidx13, align 4, !tbaa !16
  call void @llvm.lifetime.start.p0(ptr %idx_j) #4
  %17 = load ptr, ptr %A.addr, align 8, !tbaa !13
  %18 = load i32, ptr %j, align 4, !tbaa !16
  %idxprom15 = sext i32 %18 to i64
  %arrayidx16 = getelementptr inbounds i32, ptr %17, i64 %idxprom15
  %19 = load i32, ptr %arrayidx16, align 4, !tbaa !16
  %rem17 = srem i32 %19, 10
  store i32 %rem17, ptr %idx_j, align 4, !tbaa !16
  %20 = load ptr, ptr %D2B.addr, align 8, !tbaa !13
  %21 = load i32, ptr %i, align 4, !tbaa !16
  %idxprom18 = sext i32 %21 to i64
  %arrayidx19 = getelementptr inbounds [10 x i32], ptr %20, i64 %idxprom18
  %22 = load i32, ptr %idx_j, align 4, !tbaa !16
  %idxprom20 = sext i32 %22 to i64
  %arrayidx21 = getelementptr inbounds [10 x i32], ptr %arrayidx19, i64 0, i64 %idxprom20
  %23 = load i32, ptr %arrayidx21, align 4, !tbaa !16
  %inc22 = add nsw i32 %23, 1
  store i32 %inc22, ptr %arrayidx21, align 4, !tbaa !16
  call void @llvm.lifetime.end.p0(ptr %idx_j) #4
  call void @llvm.lifetime.end.p0(ptr %idx_i) #4
  br label %if.end

if.end:                                           ; preds = %if.then, %for.body4
  br label %for.inc

for.inc:                                          ; preds = %if.end
  %24 = load i32, ptr %j, align 4, !tbaa !16
  %inc23 = add nsw i32 %24, 1
  store i32 %inc23, ptr %j, align 4, !tbaa !16
  br label %for.cond1, !llvm.loop !17

for.end:                                          ; preds = %for.cond.cleanup3
  br label %for.inc24

for.inc24:                                        ; preds = %for.end
  %25 = load i32, ptr %i, align 4, !tbaa !16
  %inc25 = add nsw i32 %25, 1
  store i32 %inc25, ptr %i, align 4, !tbaa !16
  br label %for.cond, !llvm.loop !20

for.end26:                                        ; preds = %for.cond.cleanup
  call void @llvm.lifetime.end.p0(ptr %D2B_rows) #4
  ret void
}

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(ptr captures(none)) #1

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(ptr captures(none)) #1

; Function Attrs: nounwind uwtable
define dso_local void @pattern7_2d_fixedB(ptr noundef %B, ptr noundef %D2B, i32 noundef signext %N) #0 {
entry:
  %B.addr = alloca ptr, align 8
  %D2B.addr = alloca ptr, align 8
  %N.addr = alloca i32, align 4
  %D2B_rows = alloca i32, align 4
  %i = alloca i32, align 4
  %cleanup.dest.slot = alloca i32, align 4
  %j = alloca i32, align 4
  store ptr %B, ptr %B.addr, align 8, !tbaa !13
  store ptr %D2B, ptr %D2B.addr, align 8, !tbaa !13
  store i32 %N, ptr %N.addr, align 4, !tbaa !16
  call void @llvm.lifetime.start.p0(ptr %D2B_rows) #4
  store i32 10, ptr %D2B_rows, align 4, !tbaa !16
  call void @llvm.lifetime.start.p0(ptr %i) #4
  store i32 0, ptr %i, align 4, !tbaa !16
  br label %for.cond

for.cond:                                         ; preds = %for.inc8, %entry
  %0 = load i32, ptr %i, align 4, !tbaa !16
  %1 = load i32, ptr %D2B_rows, align 4, !tbaa !16
  %cmp = icmp slt i32 %0, %1
  br i1 %cmp, label %for.body, label %for.cond.cleanup

for.cond.cleanup:                                 ; preds = %for.cond
  store i32 2, ptr %cleanup.dest.slot, align 4
  call void @llvm.lifetime.end.p0(ptr %i) #4
  br label %for.end10

for.body:                                         ; preds = %for.cond
  call void @llvm.lifetime.start.p0(ptr %j) #4
  store i32 0, ptr %j, align 4, !tbaa !16
  br label %for.cond1

for.cond1:                                        ; preds = %for.inc, %for.body
  %2 = load i32, ptr %j, align 4, !tbaa !16
  %cmp2 = icmp slt i32 %2, 10
  br i1 %cmp2, label %for.body4, label %for.cond.cleanup3

for.cond.cleanup3:                                ; preds = %for.cond1
  store i32 5, ptr %cleanup.dest.slot, align 4
  call void @llvm.lifetime.end.p0(ptr %j) #4
  br label %for.end

for.body4:                                        ; preds = %for.cond1
  %3 = load ptr, ptr %D2B.addr, align 8, !tbaa !13
  %4 = load i32, ptr %i, align 4, !tbaa !16
  %idxprom = sext i32 %4 to i64
  %arrayidx = getelementptr inbounds [10 x i32], ptr %3, i64 %idxprom
  %5 = load i32, ptr %j, align 4, !tbaa !16
  %idxprom5 = sext i32 %5 to i64
  %arrayidx6 = getelementptr inbounds [10 x i32], ptr %arrayidx, i64 0, i64 %idxprom5
  %6 = load i32, ptr %arrayidx6, align 4, !tbaa !16
  %inc = add nsw i32 %6, 1
  store i32 %inc, ptr %arrayidx6, align 4, !tbaa !16
  br label %for.inc

for.inc:                                          ; preds = %for.body4
  %7 = load i32, ptr %j, align 4, !tbaa !16
  %inc7 = add nsw i32 %7, 1
  store i32 %inc7, ptr %j, align 4, !tbaa !16
  br label %for.cond1, !llvm.loop !21

for.end:                                          ; preds = %for.cond.cleanup3
  br label %for.inc8

for.inc8:                                         ; preds = %for.end
  %8 = load i32, ptr %i, align 4, !tbaa !16
  %inc9 = add nsw i32 %8, 1
  store i32 %inc9, ptr %i, align 4, !tbaa !16
  br label %for.cond, !llvm.loop !22

for.end10:                                        ; preds = %for.cond.cleanup
  call void @llvm.lifetime.end.p0(ptr %D2B_rows) #4
  ret void
}

; Function Attrs: nounwind uwtable
define dso_local signext i32 @main() #0 {
entry:
  %retval = alloca i32, align 4
  %N1 = alloca i32, align 4
  %A1 = alloca ptr, align 8
  %D2B1 = alloca ptr, align 8
  %N2 = alloca i32, align 4
  %A2 = alloca ptr, align 8
  %D2B2 = alloca ptr, align 8
  store i32 0, ptr %retval, align 4
  call void @llvm.lifetime.start.p0(ptr %N1) #4
  store i32 50, ptr %N1, align 4, !tbaa !16
  call void @llvm.lifetime.start.p0(ptr %A1) #4
  %0 = load i32, ptr %N1, align 4, !tbaa !16
  %conv = sext i32 %0 to i64
  %call = call noalias ptr @calloc(i64 noundef %conv, i64 noundef 4) #5
  store ptr %call, ptr %A1, align 8, !tbaa !13
  call void @llvm.lifetime.start.p0(ptr %D2B1) #4
  %call1 = call noalias ptr @calloc(i64 noundef 10, i64 noundef 40) #5
  store ptr %call1, ptr %D2B1, align 8, !tbaa !13
  %1 = load ptr, ptr %A1, align 8, !tbaa !13
  %2 = load ptr, ptr %D2B1, align 8, !tbaa !13
  %3 = load i32, ptr %N1, align 4, !tbaa !16
  call void @pattern7_2d_fixed(ptr noundef %1, ptr noundef %2, i32 noundef signext %3)
  %4 = load ptr, ptr %A1, align 8, !tbaa !13
  call void @free(ptr noundef %4) #4
  %5 = load ptr, ptr %D2B1, align 8, !tbaa !13
  call void @free(ptr noundef %5) #4
  call void @llvm.lifetime.start.p0(ptr %N2) #4
  store i32 100, ptr %N2, align 4, !tbaa !16
  call void @llvm.lifetime.start.p0(ptr %A2) #4
  %6 = load i32, ptr %N2, align 4, !tbaa !16
  %conv2 = sext i32 %6 to i64
  %call3 = call noalias ptr @calloc(i64 noundef %conv2, i64 noundef 4) #5
  store ptr %call3, ptr %A2, align 8, !tbaa !13
  call void @llvm.lifetime.start.p0(ptr %D2B2) #4
  %call4 = call noalias ptr @calloc(i64 noundef 10, i64 noundef 40) #5
  store ptr %call4, ptr %D2B2, align 8, !tbaa !13
  %7 = load ptr, ptr %A2, align 8, !tbaa !13
  %8 = load ptr, ptr %D2B2, align 8, !tbaa !13
  %9 = load i32, ptr %N2, align 4, !tbaa !16
  call void @pattern7_2d_fixed(ptr noundef %7, ptr noundef %8, i32 noundef signext %9)
  %10 = load ptr, ptr %A2, align 8, !tbaa !13
  call void @free(ptr noundef %10) #4
  %11 = load ptr, ptr %D2B2, align 8, !tbaa !13
  call void @free(ptr noundef %11) #4
  call void @llvm.lifetime.end.p0(ptr %D2B2) #4
  call void @llvm.lifetime.end.p0(ptr %A2) #4
  call void @llvm.lifetime.end.p0(ptr %N2) #4
  call void @llvm.lifetime.end.p0(ptr %D2B1) #4
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
!16 = !{!10, !10, i64 0}
!17 = distinct !{!17, !18, !19}
!18 = !{!"llvm.loop.mustprogress"}
!19 = !{!"llvm.loop.unroll.disable"}
!20 = distinct !{!20, !18, !19}
!21 = distinct !{!21, !18, !19}
!22 = distinct !{!22, !18, !19}
