; ModuleID = 'test_backend_input.ll'
source_filename = "pattern6_3d_pointer.c"
target datalayout = "e-m:e-p:64:64-i64:64-i128:128-n32:64-S128"
target triple = "riscv64-unknown-linux-gnu"

; Function Attrs: nounwind uwtable
define dso_local void @pattern6_3d_pointer(ptr noundef %A, ptr noundef %D3A, i32 noundef signext %N, i32 noundef signext %D3_dim1, i32 noundef signext %D3_dim2, i32 noundef signext %D3_dim3) #0 {
entry:
  %merged_loop_bound = mul i32 %D3_dim3, %D3_dim2
  %merged_loop_bound2 = mul i32 %merged_loop_bound, %D3_dim1
  %0 = inttoptr i32 %D3_dim2 to ptr
  call void @llvm.interstellar.configure.link(i32 1, ptr %0, i32 4)
  call void @llvm.interstellar.configure.link(i32 3, ptr %A, i32 8)
  %1 = inttoptr i32 %D3_dim3 to ptr
  call void @llvm.interstellar.configure.link(i32 2, ptr %1, i32 4)
  call void @llvm.interstellar.configure.link(i32 4, ptr %D3A, i32 8)
  %2 = inttoptr i32 %D3_dim1 to ptr
  call void @llvm.interstellar.configure.link(i32 0, ptr %2, i32 4)
  %3 = inttoptr i32 %merged_loop_bound2 to ptr
  call void @llvm.interstellar.configure.link(i32 5, ptr %3, i32 4)
  call void @llvm.interstellar.configure.loop(i32 6, i32 0, i1 false, i1 true, i32 0, i32 0, i32 1)
  call void @llvm.interstellar.configure.loop(i32 7, i32 0, i1 false, i1 true, i32 0, i32 1, i32 1)
  call void @llvm.interstellar.configure.loop(i32 8, i32 7, i1 false, i1 true, i32 0, i32 2, i32 1)
  call void @llvm.interstellar.configure.loop(i32 9, i32 0, i1 false, i1 true, i32 0, i32 5, i32 1)
  call void @llvm.interstellar.configure.directstream(i32 10, i32 9, i1 true, ptr inttoptr (i64 1 to ptr), i32 4)
  call void @llvm.interstellar.configure.directstream(i32 11, i32 6, i1 true, ptr inttoptr (i64 3 to ptr), i32 4)
  call void @llvm.interstellar.configure.directstream(i32 12, i32 8, i1 true, ptr inttoptr (i64 1 to ptr), i32 4)
  call void @llvm.interstellar.configure.directstream(i32 13, i32 7, i1 true, ptr inttoptr (i64 3 to ptr), i32 4)
  call void @llvm.interstellar.configure.directstream(i32 14, i32 8, i1 true, ptr inttoptr (i64 2 to ptr), i32 4)
  call void @llvm.interstellar.configure.directstream(i32 15, i32 8, i1 true, ptr inttoptr (i64 3 to ptr), i32 4)
  call void @llvm.interstellar.configure.indirectstream(i32 16, i32 15, i1 true, ptr inttoptr (i64 4 to ptr), i32 4, i32 0)
  call void @llvm.interstellar.configure.indirectstream(i32 17, i32 0, i1 true, ptr inttoptr (i64 4 to ptr), i32 4, i32 0)
  br label %for.cond

for.cond:                                         ; preds = %for.inc87, %entry
  %i.0 = phi i32 [ 0, %entry ], [ %inc88, %for.inc87 ]
  %cmp = icmp slt i32 %i.0, %D3_dim1
  br i1 %cmp, label %for.body, label %for.cond.cleanup

for.cond.cleanup:                                 ; preds = %for.cond
  br label %for.end89

for.body:                                         ; preds = %for.cond
  br label %for.cond1

for.cond1:                                        ; preds = %for.inc84, %for.body
  %j.0 = phi i32 [ 0, %for.body ], [ %inc85, %for.inc84 ]
  %cmp2 = icmp slt i32 %j.0, %D3_dim2
  br i1 %cmp2, label %for.body4, label %for.cond.cleanup3

for.cond.cleanup3:                                ; preds = %for.cond1
  br label %for.end86

for.body4:                                        ; preds = %for.cond1
  br label %for.cond5

for.cond5:                                        ; preds = %for.inc, %for.body4
  %k.0 = phi i32 [ 0, %for.body4 ], [ %inc83, %for.inc ]
  %cmp6 = icmp slt i32 %k.0, %D3_dim3
  br i1 %cmp6, label %for.body8, label %for.cond.cleanup7

for.cond.cleanup7:                                ; preds = %for.cond5
  br label %for.end

for.body8:                                        ; preds = %for.cond5
  %mul = mul nsw i32 %i.0, %D3_dim2
  %mul9 = mul nsw i32 %mul, %D3_dim3
  %mul10 = mul nsw i32 %j.0, %D3_dim3
  %add = add nsw i32 %mul9, %mul10
  %add11 = add nsw i32 %add, %k.0
  %idxprom = sext i32 %add11 to i64
  %arrayidx = getelementptr inbounds i32, ptr %D3A, i64 %idxprom
  %4 = load i32, ptr %arrayidx, align 4, !tbaa !13
  %inc = add nsw i32 %4, 1
  store i32 %inc, ptr %arrayidx, align 4, !tbaa !13
  %cmp12 = icmp slt i32 %i.0, %N
  br i1 %cmp12, label %land.lhs.true, label %if.end

land.lhs.true:                                    ; preds = %for.body8
  %idxprom13 = sext i32 %i.0 to i64
  %arrayidx14 = getelementptr inbounds i32, ptr %A, i64 %idxprom13
  %5 = load i32, ptr %arrayidx14, align 4, !tbaa !13
  %cmp15 = icmp sge i32 %5, 0
  br i1 %cmp15, label %land.lhs.true16, label %if.end

land.lhs.true16:                                  ; preds = %land.lhs.true
  %idxprom17 = sext i32 %i.0 to i64
  %arrayidx18 = getelementptr inbounds i32, ptr %A, i64 %idxprom17
  %6 = load i32, ptr %arrayidx18, align 4, !tbaa !13
  %cmp19 = icmp slt i32 %6, %D3_dim1
  br i1 %cmp19, label %if.then, label %if.end

if.then:                                          ; preds = %land.lhs.true16
  %idxprom20 = sext i32 %i.0 to i64
  %arrayidx21 = getelementptr inbounds i32, ptr %A, i64 %idxprom20
  %7 = load i32, ptr %arrayidx21, align 4, !tbaa !13
  %mul22 = mul nsw i32 %7, %D3_dim2
  %mul23 = mul nsw i32 %mul22, %D3_dim3
  %mul24 = mul nsw i32 %j.0, %D3_dim3
  %add25 = add nsw i32 %mul23, %mul24
  %add26 = add nsw i32 %add25, %k.0
  %idxprom27 = sext i32 %add26 to i64
  %arrayidx28 = getelementptr inbounds i32, ptr %D3A, i64 %idxprom27
  %8 = load i32, ptr %arrayidx28, align 4, !tbaa !13
  %inc29 = add nsw i32 %8, 1
  store i32 %inc29, ptr %arrayidx28, align 4, !tbaa !13
  %idxprom30 = sext i32 %j.0 to i64
  %arrayidx31 = getelementptr inbounds i32, ptr %A, i64 %idxprom30
  %9 = load i32, ptr %arrayidx31, align 4, !tbaa !13
  %rem = srem i32 %9, %D3_dim2
  %mul32 = mul nsw i32 %i.0, %D3_dim2
  %mul33 = mul nsw i32 %mul32, %D3_dim3
  %mul34 = mul nsw i32 %rem, %D3_dim3
  %add35 = add nsw i32 %mul33, %mul34
  %add36 = add nsw i32 %add35, %k.0
  %idxprom37 = sext i32 %add36 to i64
  %arrayidx38 = getelementptr inbounds i32, ptr %D3A, i64 %idxprom37
  %10 = load i32, ptr %arrayidx38, align 4, !tbaa !13
  %inc39 = add nsw i32 %10, 1
  store i32 %inc39, ptr %arrayidx38, align 4, !tbaa !13
  %idxprom40 = sext i32 %k.0 to i64
  %arrayidx41 = getelementptr inbounds i32, ptr %A, i64 %idxprom40
  %11 = load i32, ptr %arrayidx41, align 4, !tbaa !13
  %rem42 = srem i32 %11, %D3_dim3
  %mul43 = mul nsw i32 %i.0, %D3_dim2
  %mul44 = mul nsw i32 %mul43, %D3_dim3
  %mul45 = mul nsw i32 %j.0, %D3_dim3
  %add46 = add nsw i32 %mul44, %mul45
  %add47 = add nsw i32 %add46, %rem42
  %idxprom48 = sext i32 %add47 to i64
  %arrayidx49 = getelementptr inbounds i32, ptr %D3A, i64 %idxprom48
  %12 = load i32, ptr %arrayidx49, align 4, !tbaa !13
  %inc50 = add nsw i32 %12, 1
  store i32 %inc50, ptr %arrayidx49, align 4, !tbaa !13
  br label %if.end

if.end:                                           ; preds = %if.then, %land.lhs.true16, %land.lhs.true, %for.body8
  %call = call signext i32 @rand() #5
  %rem51 = srem i32 %call, %D3_dim1
  %call52 = call signext i32 @rand() #5
  %rem53 = srem i32 %call52, %D3_dim2
  %call54 = call signext i32 @rand() #5
  %rem55 = srem i32 %call54, %D3_dim3
  %mul56 = mul nsw i32 %rem51, %D3_dim2
  %mul57 = mul nsw i32 %mul56, %D3_dim3
  %mul58 = mul nsw i32 %rem53, %D3_dim3
  %add59 = add nsw i32 %mul57, %mul58
  %add60 = add nsw i32 %add59, %rem55
  %inc61 = add nsw i32 %add60, 1
  %idxprom62 = sext i32 %add60 to i64
  %arrayidx63 = getelementptr inbounds i32, ptr %D3A, i64 %idxprom62
  %13 = load i32, ptr %arrayidx63, align 4, !tbaa !13
  %inc64 = add nsw i32 %13, 1
  store i32 %inc64, ptr %arrayidx63, align 4, !tbaa !13
  %mul65 = mul nsw i32 %i.0, %D3_dim2
  %mul66 = mul nsw i32 %mul65, %D3_dim3
  %mul67 = mul nsw i32 %rem53, %D3_dim3
  %add68 = add nsw i32 %mul66, %mul67
  %add69 = add nsw i32 %add68, %k.0
  %inc70 = add nsw i32 %add69, 1
  %idxprom71 = sext i32 %add69 to i64
  %arrayidx72 = getelementptr inbounds i32, ptr %D3A, i64 %idxprom71
  %14 = load i32, ptr %arrayidx72, align 4, !tbaa !13
  %inc73 = add nsw i32 %14, 1
  store i32 %inc73, ptr %arrayidx72, align 4, !tbaa !13
  %mul74 = mul nsw i32 %i.0, %D3_dim2
  %mul75 = mul nsw i32 %mul74, %D3_dim3
  %mul76 = mul nsw i32 %j.0, %D3_dim3
  %add77 = add nsw i32 %mul75, %mul76
  %add78 = add nsw i32 %add77, %rem55
  %inc79 = add nsw i32 %add78, 1
  %idxprom80 = sext i32 %add78 to i64
  %arrayidx81 = getelementptr inbounds i32, ptr %D3A, i64 %idxprom80
  %15 = load i32, ptr %arrayidx81, align 4, !tbaa !13
  %inc82 = add nsw i32 %15, 1
  store i32 %inc82, ptr %arrayidx81, align 4, !tbaa !13
  br label %for.inc

for.inc:                                          ; preds = %if.end
  %inc83 = add nsw i32 %k.0, 1
  br label %for.cond5, !llvm.loop !14

for.end:                                          ; preds = %for.cond.cleanup7
  br label %for.inc84

for.inc84:                                        ; preds = %for.end
  %inc85 = add nsw i32 %j.0, 1
  br label %for.cond1, !llvm.loop !17

for.end86:                                        ; preds = %for.cond.cleanup3
  br label %for.inc87

for.inc87:                                        ; preds = %for.end86
  %inc88 = add nsw i32 %i.0, 1
  br label %for.cond, !llvm.loop !18

for.end89:                                        ; preds = %for.cond.cleanup
  ret void
}

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(ptr captures(none)) #1

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(ptr captures(none)) #1

; Function Attrs: nounwind
declare signext i32 @rand() #2

; Function Attrs: nounwind uwtable
define dso_local void @pattern6_3d_pointerB(ptr noundef %A, ptr noundef %D3A, i32 noundef signext %N, i32 noundef signext %D3_dim1, i32 noundef signext %D3_dim2, i32 noundef signext %D3_dim3) #0 {
entry:
  %0 = add i32 %D3_dim2, -1
  %merged_loop_bound = mul i32 %D3_dim3, %0
  %1 = inttoptr i32 %D3_dim2 to ptr
  call void @llvm.interstellar.configure.link(i32 3, ptr %1, i32 4)
  %2 = inttoptr i32 %D3_dim1 to ptr
  call void @llvm.interstellar.configure.link(i32 0, ptr %2, i32 4)
  %3 = inttoptr i32 %merged_loop_bound to ptr
  call void @llvm.interstellar.configure.link(i32 4, ptr %3, i32 4)
  call void @llvm.interstellar.configure.loop(i32 5, i32 0, i1 false, i1 true, i32 0, i32 0, i32 1)
  call void @llvm.interstellar.configure.loop(i32 6, i32 0, i1 false, i1 true, i32 0, i32 4, i32 1)
  call void @llvm.interstellar.configure.directstream(i32 7, i32 6, i1 true, ptr inttoptr (i64 3 to ptr), i32 4)
  br label %for.cond

for.cond:                                         ; preds = %for.inc16, %entry
  %i.0 = phi i32 [ 0, %entry ], [ %inc17, %for.inc16 ]
  %cmp = icmp slt i32 %i.0, %D3_dim1
  br i1 %cmp, label %for.body, label %for.cond.cleanup

for.cond.cleanup:                                 ; preds = %for.cond
  br label %for.end18

for.body:                                         ; preds = %for.cond
  br label %for.cond1

for.cond1:                                        ; preds = %for.inc13, %for.body
  %j.0 = phi i32 [ 0, %for.body ], [ %inc14, %for.inc13 ]
  %sub = sub nsw i32 %D3_dim2, 1
  %cmp2 = icmp slt i32 %j.0, %sub
  br i1 %cmp2, label %for.body4, label %for.cond.cleanup3

for.cond.cleanup3:                                ; preds = %for.cond1
  br label %for.end15

for.body4:                                        ; preds = %for.cond1
  br label %for.cond5

for.cond5:                                        ; preds = %for.inc, %for.body4
  %k.0 = phi i32 [ 0, %for.body4 ], [ %inc12, %for.inc ]
  %cmp6 = icmp slt i32 %k.0, %D3_dim3
  br i1 %cmp6, label %for.body8, label %for.cond.cleanup7

for.cond.cleanup7:                                ; preds = %for.cond5
  br label %for.end

for.body8:                                        ; preds = %for.cond5
  %mul = mul nsw i32 %i.0, %D3_dim2
  %mul9 = mul nsw i32 %mul, %D3_dim3
  %mul10 = mul nsw i32 %j.0, %D3_dim3
  %add = add nsw i32 %mul9, %mul10
  %add11 = add nsw i32 %add, %k.0
  %idxprom = sext i32 %add11 to i64
  %arrayidx = getelementptr inbounds i32, ptr %D3A, i64 %idxprom
  %4 = load i32, ptr %arrayidx, align 4, !tbaa !13
  %inc = add nsw i32 %4, 1
  store i32 %inc, ptr %arrayidx, align 4, !tbaa !13
  br label %for.inc

for.inc:                                          ; preds = %for.body8
  %inc12 = add nsw i32 %k.0, 1
  br label %for.cond5, !llvm.loop !19

for.end:                                          ; preds = %for.cond.cleanup7
  br label %for.inc13

for.inc13:                                        ; preds = %for.end
  %inc14 = add nsw i32 %j.0, 1
  br label %for.cond1, !llvm.loop !20

for.end15:                                        ; preds = %for.cond.cleanup3
  br label %for.inc16

for.inc16:                                        ; preds = %for.end15
  %inc17 = add nsw i32 %i.0, 1
  br label %for.cond, !llvm.loop !21

for.end18:                                        ; preds = %for.cond.cleanup
  ret void
}

; Function Attrs: nounwind uwtable
define dso_local signext i32 @main() #0 {
entry:
  %conv = sext i32 15 to i64
  %call = call noalias ptr @calloc(i64 noundef %conv, i64 noundef 4) #6
  %mul = mul nsw i32 8, 10
  %mul1 = mul nsw i32 %mul, 12
  %conv2 = sext i32 %mul1 to i64
  %call3 = call noalias ptr @calloc(i64 noundef %conv2, i64 noundef 4) #6
  call void @pattern6_3d_pointer(ptr noundef %call, ptr noundef %call3, i32 noundef signext 15, i32 noundef signext 8, i32 noundef signext 10, i32 noundef signext 12)
  call void @free(ptr noundef %call) #5
  call void @free(ptr noundef %call3) #5
  %conv4 = sext i32 20 to i64
  %call5 = call noalias ptr @calloc(i64 noundef %conv4, i64 noundef 4) #6
  %mul6 = mul nsw i32 10, 12
  %mul7 = mul nsw i32 %mul6, 15
  %conv8 = sext i32 %mul7 to i64
  %call9 = call noalias ptr @calloc(i64 noundef %conv8, i64 noundef 4) #6
  call void @pattern6_3d_pointer(ptr noundef %call5, ptr noundef %call9, i32 noundef signext 20, i32 noundef signext 10, i32 noundef signext 12, i32 noundef signext 15)
  call void @free(ptr noundef %call5) #5
  call void @free(ptr noundef %call9) #5
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
