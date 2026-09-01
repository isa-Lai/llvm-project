; ModuleID = 'test_backend_input.ll'
source_filename = "pattern8_3d_fixed.c"
target datalayout = "e-m:e-p:64:64-i64:64-i128:128-n32:64-S128"
target triple = "riscv64-unknown-linux-gnu"

; Function Attrs: nounwind uwtable
define dso_local void @pattern8_3d_fixed(ptr noundef %A, ptr noundef %D3B, i32 noundef signext %N) #0 {
entry:
  call void @llvm.interstellar.configure.link(i32 1, ptr %A, i32 8)
  call void @llvm.interstellar.configure.loop(i32 6, i32 0, i1 false, i1 false, i32 0, i32 10, i32 1)
  call void @llvm.interstellar.configure.loop(i32 7, i32 0, i1 false, i1 false, i32 0, i32 10, i32 1)
  call void @llvm.interstellar.configure.loop(i32 8, i32 7, i1 false, i1 false, i32 0, i32 10, i32 1)
  call void @llvm.interstellar.configure.loop(i32 9, i32 0, i1 false, i1 false, i32 0, i32 1000, i32 1)
  call void @llvm.interstellar.configure.loop(i32 10, i32 0, i1 false, i1 false, i32 0, i32 100, i32 1)
  call void @llvm.interstellar.configure.directstream(i32 12, i32 6, i1 true, ptr inttoptr (i64 1 to ptr), i32 4)
  call void @llvm.interstellar.configure.directstream(i32 14, i32 7, i1 true, ptr inttoptr (i64 1 to ptr), i32 4)
  call void @llvm.interstellar.configure.directstream(i32 16, i32 8, i1 true, ptr inttoptr (i64 1 to ptr), i32 4)
  call void @llvm.interstellar.configure.indirectstream(i32 17, i32 16, i1 false, ptr null, i32 4, i32 0)
  call void @llvm.interstellar.configure.indirectstream(i32 20, i32 0, i1 false, ptr null, i32 4, i32 0)
  br label %for.cond

for.cond:                                         ; preds = %for.inc73, %entry
  %i.0 = phi i32 [ 0, %entry ], [ %inc74, %for.inc73 ]
  %cmp = icmp slt i32 %i.0, 10
  br i1 %cmp, label %for.body, label %for.cond.cleanup

for.cond.cleanup:                                 ; preds = %for.cond
  br label %for.end75

for.body:                                         ; preds = %for.cond
  br label %for.cond1

for.cond1:                                        ; preds = %for.inc70, %for.body
  %j.0 = phi i32 [ 0, %for.body ], [ %inc71, %for.inc70 ]
  %cmp2 = icmp slt i32 %j.0, 10
  br i1 %cmp2, label %for.body4, label %for.cond.cleanup3

for.cond.cleanup3:                                ; preds = %for.cond1
  br label %for.end72

for.body4:                                        ; preds = %for.cond1
  br label %for.cond5

for.cond5:                                        ; preds = %for.inc, %for.body4
  %k.0 = phi i32 [ 0, %for.body4 ], [ %inc69, %for.inc ]
  %cmp6 = icmp slt i32 %k.0, 10
  br i1 %cmp6, label %for.body8, label %for.cond.cleanup7

for.cond.cleanup7:                                ; preds = %for.cond5
  br label %for.end

for.body8:                                        ; preds = %for.cond5
  %idxprom = sext i32 %i.0 to i64
  %arrayidx = getelementptr inbounds [10 x [10 x i32]], ptr %D3B, i64 %idxprom
  %idxprom9 = sext i32 %j.0 to i64
  %arrayidx10 = getelementptr inbounds [10 x [10 x i32]], ptr %arrayidx, i64 0, i64 %idxprom9
  %idxprom11 = sext i32 %k.0 to i64
  %arrayidx12 = getelementptr inbounds [10 x i32], ptr %arrayidx10, i64 0, i64 %idxprom11
  %0 = load i32, ptr %arrayidx12, align 4, !tbaa !13
  %inc = add nsw i32 %0, 1
  store i32 %inc, ptr %arrayidx12, align 4, !tbaa !13
  %cmp13 = icmp slt i32 %i.0, %N
  br i1 %cmp13, label %if.then, label %if.end

if.then:                                          ; preds = %for.body8
  %idxprom14 = sext i32 %i.0 to i64
  %arrayidx15 = getelementptr inbounds i32, ptr %A, i64 %idxprom14
  %1 = load i32, ptr %arrayidx15, align 4, !tbaa !13
  %rem = srem i32 %1, 10
  %idxprom16 = sext i32 %rem to i64
  %arrayidx17 = getelementptr inbounds [10 x [10 x i32]], ptr %D3B, i64 %idxprom16
  %idxprom18 = sext i32 %j.0 to i64
  %arrayidx19 = getelementptr inbounds [10 x [10 x i32]], ptr %arrayidx17, i64 0, i64 %idxprom18
  %idxprom20 = sext i32 %k.0 to i64
  %arrayidx21 = getelementptr inbounds [10 x i32], ptr %arrayidx19, i64 0, i64 %idxprom20
  %2 = load i32, ptr %arrayidx21, align 4, !tbaa !13
  %inc22 = add nsw i32 %2, 1
  store i32 %inc22, ptr %arrayidx21, align 4, !tbaa !13
  %idxprom23 = sext i32 %j.0 to i64
  %arrayidx24 = getelementptr inbounds i32, ptr %A, i64 %idxprom23
  %3 = load i32, ptr %arrayidx24, align 4, !tbaa !13
  %rem25 = srem i32 %3, 10
  %idxprom26 = sext i32 %i.0 to i64
  %arrayidx27 = getelementptr inbounds [10 x [10 x i32]], ptr %D3B, i64 %idxprom26
  %idxprom28 = sext i32 %rem25 to i64
  %arrayidx29 = getelementptr inbounds [10 x [10 x i32]], ptr %arrayidx27, i64 0, i64 %idxprom28
  %idxprom30 = sext i32 %k.0 to i64
  %arrayidx31 = getelementptr inbounds [10 x i32], ptr %arrayidx29, i64 0, i64 %idxprom30
  %4 = load i32, ptr %arrayidx31, align 4, !tbaa !13
  %inc32 = add nsw i32 %4, 1
  store i32 %inc32, ptr %arrayidx31, align 4, !tbaa !13
  %idxprom33 = sext i32 %k.0 to i64
  %arrayidx34 = getelementptr inbounds i32, ptr %A, i64 %idxprom33
  %5 = load i32, ptr %arrayidx34, align 4, !tbaa !13
  %rem35 = srem i32 %5, 10
  %idxprom36 = sext i32 %i.0 to i64
  %arrayidx37 = getelementptr inbounds [10 x [10 x i32]], ptr %D3B, i64 %idxprom36
  %idxprom38 = sext i32 %j.0 to i64
  %arrayidx39 = getelementptr inbounds [10 x [10 x i32]], ptr %arrayidx37, i64 0, i64 %idxprom38
  %idxprom40 = sext i32 %rem35 to i64
  %arrayidx41 = getelementptr inbounds [10 x i32], ptr %arrayidx39, i64 0, i64 %idxprom40
  %6 = load i32, ptr %arrayidx41, align 4, !tbaa !13
  %inc42 = add nsw i32 %6, 1
  store i32 %inc42, ptr %arrayidx41, align 4, !tbaa !13
  br label %if.end

if.end:                                           ; preds = %if.then, %for.body8
  %call = call signext i32 @rand() #5
  %rem43 = srem i32 %call, 10
  %idxprom44 = sext i32 %rem43 to i64
  %arrayidx45 = getelementptr inbounds [10 x [10 x i32]], ptr %D3B, i64 %idxprom44
  %idxprom46 = sext i32 %j.0 to i64
  %arrayidx47 = getelementptr inbounds [10 x [10 x i32]], ptr %arrayidx45, i64 0, i64 %idxprom46
  %idxprom48 = sext i32 %k.0 to i64
  %arrayidx49 = getelementptr inbounds [10 x i32], ptr %arrayidx47, i64 0, i64 %idxprom48
  %7 = load i32, ptr %arrayidx49, align 4, !tbaa !13
  %inc50 = add nsw i32 %7, 1
  store i32 %inc50, ptr %arrayidx49, align 4, !tbaa !13
  %call51 = call signext i32 @rand() #5
  %rem52 = srem i32 %call51, 10
  %idxprom53 = sext i32 %i.0 to i64
  %arrayidx54 = getelementptr inbounds [10 x [10 x i32]], ptr %D3B, i64 %idxprom53
  %idxprom55 = sext i32 %rem52 to i64
  %arrayidx56 = getelementptr inbounds [10 x [10 x i32]], ptr %arrayidx54, i64 0, i64 %idxprom55
  %idxprom57 = sext i32 %k.0 to i64
  %arrayidx58 = getelementptr inbounds [10 x i32], ptr %arrayidx56, i64 0, i64 %idxprom57
  %8 = load i32, ptr %arrayidx58, align 4, !tbaa !13
  %inc59 = add nsw i32 %8, 1
  store i32 %inc59, ptr %arrayidx58, align 4, !tbaa !13
  %call60 = call signext i32 @rand() #5
  %rem61 = srem i32 %call60, 10
  %idxprom62 = sext i32 %i.0 to i64
  %arrayidx63 = getelementptr inbounds [10 x [10 x i32]], ptr %D3B, i64 %idxprom62
  %idxprom64 = sext i32 %j.0 to i64
  %arrayidx65 = getelementptr inbounds [10 x [10 x i32]], ptr %arrayidx63, i64 0, i64 %idxprom64
  %idxprom66 = sext i32 %rem61 to i64
  %arrayidx67 = getelementptr inbounds [10 x i32], ptr %arrayidx65, i64 0, i64 %idxprom66
  %9 = load i32, ptr %arrayidx67, align 4, !tbaa !13
  %inc68 = add nsw i32 %9, 1
  store i32 %inc68, ptr %arrayidx67, align 4, !tbaa !13
  br label %for.inc

for.inc:                                          ; preds = %if.end
  %inc69 = add nsw i32 %k.0, 1
  br label %for.cond5, !llvm.loop !14

for.end:                                          ; preds = %for.cond.cleanup7
  br label %for.inc70

for.inc70:                                        ; preds = %for.end
  %inc71 = add nsw i32 %j.0, 1
  br label %for.cond1, !llvm.loop !17

for.end72:                                        ; preds = %for.cond.cleanup3
  br label %for.inc73

for.inc73:                                        ; preds = %for.end72
  %inc74 = add nsw i32 %i.0, 1
  br label %for.cond, !llvm.loop !18

for.end75:                                        ; preds = %for.cond.cleanup
  ret void
}

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(ptr captures(none)) #1

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(ptr captures(none)) #1

; Function Attrs: nounwind
declare signext i32 @rand() #2

; Function Attrs: nounwind uwtable
define dso_local void @pattern8_3d_fixedB(ptr noundef %A, ptr noundef %D3B, i32 noundef signext %N) #0 {
entry:
  call void @llvm.interstellar.configure.loop(i32 1, i32 0, i1 false, i1 false, i32 0, i32 1000, i32 1)
  br label %for.cond

for.cond:                                         ; preds = %for.inc17, %entry
  %i.0 = phi i32 [ 0, %entry ], [ %inc18, %for.inc17 ]
  %cmp = icmp slt i32 %i.0, 10
  br i1 %cmp, label %for.body, label %for.cond.cleanup

for.cond.cleanup:                                 ; preds = %for.cond
  br label %for.end19

for.body:                                         ; preds = %for.cond
  br label %for.cond1

for.cond1:                                        ; preds = %for.inc14, %for.body
  %j.0 = phi i32 [ 0, %for.body ], [ %inc15, %for.inc14 ]
  %cmp2 = icmp slt i32 %j.0, 10
  br i1 %cmp2, label %for.body4, label %for.cond.cleanup3

for.cond.cleanup3:                                ; preds = %for.cond1
  br label %for.end16

for.body4:                                        ; preds = %for.cond1
  br label %for.cond5

for.cond5:                                        ; preds = %for.inc, %for.body4
  %k.0 = phi i32 [ 0, %for.body4 ], [ %inc13, %for.inc ]
  %cmp6 = icmp slt i32 %k.0, 10
  br i1 %cmp6, label %for.body8, label %for.cond.cleanup7

for.cond.cleanup7:                                ; preds = %for.cond5
  br label %for.end

for.body8:                                        ; preds = %for.cond5
  %idxprom = sext i32 %i.0 to i64
  %arrayidx = getelementptr inbounds [10 x [10 x i32]], ptr %D3B, i64 %idxprom
  %idxprom9 = sext i32 %j.0 to i64
  %arrayidx10 = getelementptr inbounds [10 x [10 x i32]], ptr %arrayidx, i64 0, i64 %idxprom9
  %idxprom11 = sext i32 %k.0 to i64
  %arrayidx12 = getelementptr inbounds [10 x i32], ptr %arrayidx10, i64 0, i64 %idxprom11
  %0 = load i32, ptr %arrayidx12, align 4, !tbaa !13
  %inc = add nsw i32 %0, 1
  store i32 %inc, ptr %arrayidx12, align 4, !tbaa !13
  br label %for.inc

for.inc:                                          ; preds = %for.body8
  %inc13 = add nsw i32 %k.0, 1
  br label %for.cond5, !llvm.loop !19

for.end:                                          ; preds = %for.cond.cleanup7
  br label %for.inc14

for.inc14:                                        ; preds = %for.end
  %inc15 = add nsw i32 %j.0, 1
  br label %for.cond1, !llvm.loop !20

for.end16:                                        ; preds = %for.cond.cleanup3
  br label %for.inc17

for.inc17:                                        ; preds = %for.end16
  %inc18 = add nsw i32 %i.0, 1
  br label %for.cond, !llvm.loop !21

for.end19:                                        ; preds = %for.cond.cleanup
  ret void
}

; Function Attrs: nounwind uwtable
define dso_local signext i32 @main() #0 {
entry:
  %conv = sext i32 50 to i64
  %call = call noalias ptr @calloc(i64 noundef %conv, i64 noundef 4) #6
  %call1 = call noalias ptr @calloc(i64 noundef 10, i64 noundef 400) #6
  call void @pattern8_3d_fixed(ptr noundef %call, ptr noundef %call1, i32 noundef signext 50)
  call void @free(ptr noundef %call) #5
  call void @free(ptr noundef %call1) #5
  %conv2 = sext i32 100 to i64
  %call3 = call noalias ptr @calloc(i64 noundef %conv2, i64 noundef 4) #6
  %call4 = call noalias ptr @calloc(i64 noundef 10, i64 noundef 400) #6
  call void @pattern8_3d_fixed(ptr noundef %call3, ptr noundef %call4, i32 noundef signext 100)
  call void @free(ptr noundef %call3) #5
  call void @free(ptr noundef %call4) #5
  ret i32 0
}

; Function Attrs: nounwind allocsize(0,1)
declare noalias ptr @calloc(i64 noundef, i64 noundef) #3

; Function Attrs: nounwind
declare void @free(ptr noundef) #2

; Function Attrs: nocallback nofree nosync nounwind willreturn
declare void @llvm.interstellar.configure.link(i32, ptr, i32) #4

; Function Attrs: nocallback nofree nosync nounwind willreturn
declare void @llvm.interstellar.configure.loop(i32, i32, i1, i1, i32, i32, i32) #4

; Function Attrs: nocallback nofree nosync nounwind willreturn
declare void @llvm.interstellar.configure.directstream(i32, i32, i1, ptr, i32) #4

; Function Attrs: nocallback nofree nosync nounwind willreturn
declare void @llvm.interstellar.configure.indirectstream(i32, i32, i1, ptr, i32, i32) #4

attributes #0 = { nounwind uwtable "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="generic-rv64" "target-features"="+64bit,+a,+c,+d,+f,+i,+m,+relax,+zaamo,+zalrsc,+zca,+zcd,+zicsr,+zifencei,+zmmul,-b,-e,-experimental-p,-experimental-smpmpmt,-experimental-svukte,-experimental-xqccmt,-experimental-xsfmclic,-experimental-xsfsclic,-experimental-y,-experimental-zibi,-experimental-zicfilp,-experimental-zicfiss,-experimental-zvabd,-experimental-zvbc32e,-experimental-zvdot4a8i,-experimental-zvfbdota32f,-experimental-zvfbfa,-experimental-zvfofp8min,-experimental-zvfqwbdota8f,-experimental-zvfqwdota8f,-experimental-zvfwbdota16bf,-experimental-zvfwdota16bf,-experimental-zvkgs,-experimental-zvqwbdota16i,-experimental-zvqwbdota8i,-experimental-zvqwdota16i,-experimental-zvqwdota8i,-experimental-zvvfmm,-experimental-zvvmm,-experimental-zvvmtls,-experimental-zvvmttls,-experimental-zvzip,-h,-q,-sdext,-sdtrig,-sha,-shcounterenw,-shgatpa,-shlcofideleg,-shtvala,-shvsatpa,-shvstvala,-shvstvecd,-smaia,-smcdeleg,-smcntrpmf,-smcsrind,-smctr,-smdbltrp,-smepmp,-smmpm,-smnpm,-smrnmi,-smstateen,-ssaia,-ssccfg,-ssccptr,-sscofpmf,-sscounterenw,-sscsrind,-ssctr,-ssdbltrp,-ssnpm,-sspm,-ssqosid,-ssstateen,-ssstrict,-sstc,-sstvala,-sstvecd,-ssu64xl,-supm,-svade,-svadu,-svbare,-svinval,-svnapot,-svpbmt,-svrsw60t59b,-svvptc,-v,-xaifet,-xandesbfhcvt,-xandesperf,-xandesvbfhcvt,-xandesvdot,-xandesvpackfph,-xandesvsinth,-xandesvsintload,-xcheriot,-xcvalu,-xcvbi,-xcvbitmanip,-xcvelw,-xcvmac,-xcvmem,-xcvsimd,-xmipscbop,-xmipscmov,-xmipsexectl,-xmipslsp,-xqccmp,-xqci,-xqcia,-xqciac,-xqcibi,-xqcibm,-xqcicli,-xqcicm,-xqcics,-xqcicsr,-xqciint,-xqciio,-xqcilb,-xqcili,-xqcilia,-xqcilo,-xqcilsm,-xqcisim,-xqcisls,-xqcisync,-xsfcease,-xsfmm128t,-xsfmm16t,-xsfmm32a,-xsfmm32a16f,-xsfmm32a32f,-xsfmm32a8f,-xsfmm32a8i,-xsfmm32t,-xsfmm64a64f,-xsfmm64t,-xsfmmbase,-xsfvcp,-xsfvfbfexp16e,-xsfvfexp16e,-xsfvfexp32e,-xsfvfexpa,-xsfvfexpa64e,-xsfvfnrclipxfqf,-xsfvfwmaccqqq,-xsfvqmaccdod,-xsfvqmaccqoq,-xsifivecdiscarddlone,-xsifivecflushdlone,-xsmtvdot,-xsmtvdotii,-xtheadba,-xtheadbb,-xtheadbs,-xtheadcmo,-xtheadcondmov,-xtheadfmemidx,-xtheadmac,-xtheadmemidx,-xtheadmempair,-xtheadsync,-xtheadvdot,-xventanacondops,-xwchc,-za128rs,-za64rs,-zabha,-zacas,-zalasr,-zama16b,-zawrs,-zba,-zbb,-zbc,-zbkb,-zbkc,-zbkx,-zbs,-zcb,-zce,-zcf,-zclsd,-zcmop,-zcmp,-zcmt,-zdinx,-zfa,-zfbfmin,-zfh,-zfhmin,-zfinx,-zhinx,-zhinxmin,-zic64b,-zicbom,-zicbop,-zicboz,-ziccamoa,-ziccamoc,-ziccid,-ziccif,-zicclsm,-ziccrse,-zicntr,-zicond,-zihintntl,-zihintpause,-zihpm,-zilsd,-zimop,-zk,-zkn,-zknd,-zkne,-zknh,-zkr,-zks,-zksed,-zksh,-zkt,-ztso,-zvbb,-zvbc,-zve32f,-zve32x,-zve64d,-zve64f,-zve64x,-zvfbfmin,-zvfbfwma,-zvfh,-zvfhmin,-zvkb,-zvkg,-zvkn,-zvknc,-zvkned,-zvkng,-zvknha,-zvknhb,-zvks,-zvksc,-zvksed,-zvksg,-zvksh,-zvkt,-zvl1024b,-zvl128b,-zvl16384b,-zvl2048b,-zvl256b,-zvl32768b,-zvl32b,-zvl4096b,-zvl512b,-zvl64b,-zvl65536b,-zvl8192b" }
attributes #1 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { nounwind "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="generic-rv64" "target-features"="+64bit,+a,+c,+d,+f,+i,+m,+relax,+zaamo,+zalrsc,+zca,+zcd,+zicsr,+zifencei,+zmmul,-b,-e,-experimental-p,-experimental-smpmpmt,-experimental-svukte,-experimental-xqccmt,-experimental-xsfmclic,-experimental-xsfsclic,-experimental-y,-experimental-zibi,-experimental-zicfilp,-experimental-zicfiss,-experimental-zvabd,-experimental-zvbc32e,-experimental-zvdot4a8i,-experimental-zvfbdota32f,-experimental-zvfbfa,-experimental-zvfofp8min,-experimental-zvfqwbdota8f,-experimental-zvfqwdota8f,-experimental-zvfwbdota16bf,-experimental-zvfwdota16bf,-experimental-zvkgs,-experimental-zvqwbdota16i,-experimental-zvqwbdota8i,-experimental-zvqwdota16i,-experimental-zvqwdota8i,-experimental-zvvfmm,-experimental-zvvmm,-experimental-zvvmtls,-experimental-zvvmttls,-experimental-zvzip,-h,-q,-sdext,-sdtrig,-sha,-shcounterenw,-shgatpa,-shlcofideleg,-shtvala,-shvsatpa,-shvstvala,-shvstvecd,-smaia,-smcdeleg,-smcntrpmf,-smcsrind,-smctr,-smdbltrp,-smepmp,-smmpm,-smnpm,-smrnmi,-smstateen,-ssaia,-ssccfg,-ssccptr,-sscofpmf,-sscounterenw,-sscsrind,-ssctr,-ssdbltrp,-ssnpm,-sspm,-ssqosid,-ssstateen,-ssstrict,-sstc,-sstvala,-sstvecd,-ssu64xl,-supm,-svade,-svadu,-svbare,-svinval,-svnapot,-svpbmt,-svrsw60t59b,-svvptc,-v,-xaifet,-xandesbfhcvt,-xandesperf,-xandesvbfhcvt,-xandesvdot,-xandesvpackfph,-xandesvsinth,-xandesvsintload,-xcheriot,-xcvalu,-xcvbi,-xcvbitmanip,-xcvelw,-xcvmac,-xcvmem,-xcvsimd,-xmipscbop,-xmipscmov,-xmipsexectl,-xmipslsp,-xqccmp,-xqci,-xqcia,-xqciac,-xqcibi,-xqcibm,-xqcicli,-xqcicm,-xqcics,-xqcicsr,-xqciint,-xqciio,-xqcilb,-xqcili,-xqcilia,-xqcilo,-xqcilsm,-xqcisim,-xqcisls,-xqcisync,-xsfcease,-xsfmm128t,-xsfmm16t,-xsfmm32a,-xsfmm32a16f,-xsfmm32a32f,-xsfmm32a8f,-xsfmm32a8i,-xsfmm32t,-xsfmm64a64f,-xsfmm64t,-xsfmmbase,-xsfvcp,-xsfvfbfexp16e,-xsfvfexp16e,-xsfvfexp32e,-xsfvfexpa,-xsfvfexpa64e,-xsfvfnrclipxfqf,-xsfvfwmaccqqq,-xsfvqmaccdod,-xsfvqmaccqoq,-xsifivecdiscarddlone,-xsifivecflushdlone,-xsmtvdot,-xsmtvdotii,-xtheadba,-xtheadbb,-xtheadbs,-xtheadcmo,-xtheadcondmov,-xtheadfmemidx,-xtheadmac,-xtheadmemidx,-xtheadmempair,-xtheadsync,-xtheadvdot,-xventanacondops,-xwchc,-za128rs,-za64rs,-zabha,-zacas,-zalasr,-zama16b,-zawrs,-zba,-zbb,-zbc,-zbkb,-zbkc,-zbkx,-zbs,-zcb,-zce,-zcf,-zclsd,-zcmop,-zcmp,-zcmt,-zdinx,-zfa,-zfbfmin,-zfh,-zfhmin,-zfinx,-zhinx,-zhinxmin,-zic64b,-zicbom,-zicbop,-zicboz,-ziccamoa,-ziccamoc,-ziccid,-ziccif,-zicclsm,-ziccrse,-zicntr,-zicond,-zihintntl,-zihintpause,-zihpm,-zilsd,-zimop,-zk,-zkn,-zknd,-zkne,-zknh,-zkr,-zks,-zksed,-zksh,-zkt,-ztso,-zvbb,-zvbc,-zve32f,-zve32x,-zve64d,-zve64f,-zve64x,-zvfbfmin,-zvfbfwma,-zvfh,-zvfhmin,-zvkb,-zvkg,-zvkn,-zvknc,-zvkned,-zvkng,-zvknha,-zvknhb,-zvks,-zvksc,-zvksed,-zvksg,-zvksh,-zvkt,-zvl1024b,-zvl128b,-zvl16384b,-zvl2048b,-zvl256b,-zvl32768b,-zvl32b,-zvl4096b,-zvl512b,-zvl64b,-zvl65536b,-zvl8192b" }
attributes #3 = { nounwind allocsize(0,1) "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="generic-rv64" "target-features"="+64bit,+a,+c,+d,+f,+i,+m,+relax,+zaamo,+zalrsc,+zca,+zcd,+zicsr,+zifencei,+zmmul,-b,-e,-experimental-p,-experimental-smpmpmt,-experimental-svukte,-experimental-xqccmt,-experimental-xsfmclic,-experimental-xsfsclic,-experimental-y,-experimental-zibi,-experimental-zicfilp,-experimental-zicfiss,-experimental-zvabd,-experimental-zvbc32e,-experimental-zvdot4a8i,-experimental-zvfbdota32f,-experimental-zvfbfa,-experimental-zvfofp8min,-experimental-zvfqwbdota8f,-experimental-zvfqwdota8f,-experimental-zvfwbdota16bf,-experimental-zvfwdota16bf,-experimental-zvkgs,-experimental-zvqwbdota16i,-experimental-zvqwbdota8i,-experimental-zvqwdota16i,-experimental-zvqwdota8i,-experimental-zvvfmm,-experimental-zvvmm,-experimental-zvvmtls,-experimental-zvvmttls,-experimental-zvzip,-h,-q,-sdext,-sdtrig,-sha,-shcounterenw,-shgatpa,-shlcofideleg,-shtvala,-shvsatpa,-shvstvala,-shvstvecd,-smaia,-smcdeleg,-smcntrpmf,-smcsrind,-smctr,-smdbltrp,-smepmp,-smmpm,-smnpm,-smrnmi,-smstateen,-ssaia,-ssccfg,-ssccptr,-sscofpmf,-sscounterenw,-sscsrind,-ssctr,-ssdbltrp,-ssnpm,-sspm,-ssqosid,-ssstateen,-ssstrict,-sstc,-sstvala,-sstvecd,-ssu64xl,-supm,-svade,-svadu,-svbare,-svinval,-svnapot,-svpbmt,-svrsw60t59b,-svvptc,-v,-xaifet,-xandesbfhcvt,-xandesperf,-xandesvbfhcvt,-xandesvdot,-xandesvpackfph,-xandesvsinth,-xandesvsintload,-xcheriot,-xcvalu,-xcvbi,-xcvbitmanip,-xcvelw,-xcvmac,-xcvmem,-xcvsimd,-xmipscbop,-xmipscmov,-xmipsexectl,-xmipslsp,-xqccmp,-xqci,-xqcia,-xqciac,-xqcibi,-xqcibm,-xqcicli,-xqcicm,-xqcics,-xqcicsr,-xqciint,-xqciio,-xqcilb,-xqcili,-xqcilia,-xqcilo,-xqcilsm,-xqcisim,-xqcisls,-xqcisync,-xsfcease,-xsfmm128t,-xsfmm16t,-xsfmm32a,-xsfmm32a16f,-xsfmm32a32f,-xsfmm32a8f,-xsfmm32a8i,-xsfmm32t,-xsfmm64a64f,-xsfmm64t,-xsfmmbase,-xsfvcp,-xsfvfbfexp16e,-xsfvfexp16e,-xsfvfexp32e,-xsfvfexpa,-xsfvfexpa64e,-xsfvfnrclipxfqf,-xsfvfwmaccqqq,-xsfvqmaccdod,-xsfvqmaccqoq,-xsifivecdiscarddlone,-xsifivecflushdlone,-xsmtvdot,-xsmtvdotii,-xtheadba,-xtheadbb,-xtheadbs,-xtheadcmo,-xtheadcondmov,-xtheadfmemidx,-xtheadmac,-xtheadmemidx,-xtheadmempair,-xtheadsync,-xtheadvdot,-xventanacondops,-xwchc,-za128rs,-za64rs,-zabha,-zacas,-zalasr,-zama16b,-zawrs,-zba,-zbb,-zbc,-zbkb,-zbkc,-zbkx,-zbs,-zcb,-zce,-zcf,-zclsd,-zcmop,-zcmp,-zcmt,-zdinx,-zfa,-zfbfmin,-zfh,-zfhmin,-zfinx,-zhinx,-zhinxmin,-zic64b,-zicbom,-zicbop,-zicboz,-ziccamoa,-ziccamoc,-ziccid,-ziccif,-zicclsm,-ziccrse,-zicntr,-zicond,-zihintntl,-zihintpause,-zihpm,-zilsd,-zimop,-zk,-zkn,-zknd,-zkne,-zknh,-zkr,-zks,-zksed,-zksh,-zkt,-ztso,-zvbb,-zvbc,-zve32f,-zve32x,-zve64d,-zve64f,-zve64x,-zvfbfmin,-zvfbfwma,-zvfh,-zvfhmin,-zvkb,-zvkg,-zvkn,-zvknc,-zvkned,-zvkng,-zvknha,-zvknhb,-zvks,-zvksc,-zvksed,-zvksg,-zvksh,-zvkt,-zvl1024b,-zvl128b,-zvl16384b,-zvl2048b,-zvl256b,-zvl32768b,-zvl32b,-zvl4096b,-zvl512b,-zvl64b,-zvl65536b,-zvl8192b" }
attributes #4 = { nocallback nofree nosync nounwind willreturn }
attributes #5 = { nounwind }
attributes #6 = { nounwind allocsize(0,1) }

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
!13 = !{!10, !10, i64 0}
!14 = distinct !{!14, !15, !16}
!15 = !{!"llvm.loop.mustprogress"}
!16 = !{!"llvm.loop.unroll.disable"}
!17 = distinct !{!17, !15, !16}
!18 = distinct !{!18, !15, !16}
!19 = distinct !{!19, !15, !16}
!20 = distinct !{!20, !15, !16}
!21 = distinct !{!21, !15, !16}
