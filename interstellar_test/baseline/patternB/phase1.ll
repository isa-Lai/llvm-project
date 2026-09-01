; ModuleID = 'test_backend_input.ll'
source_filename = "patternB_4level_nesting.c"
target datalayout = "e-m:e-p:64:64-i64:64-i128:128-n32:64-S128"
target triple = "riscv64-unknown-linux-gnu"

@.str = private unnamed_addr constant [26 x i8] c"A[0] = %d (expected: %d)\0A\00", align 1
@.str.1 = private unnamed_addr constant [26 x i8] c"B[0] = %d (expected: %d)\0A\00", align 1
@.str.2 = private unnamed_addr constant [26 x i8] c"C[0] = %d (expected: %d)\0A\00", align 1
@.str.3 = private unnamed_addr constant [26 x i8] c"D[0] = %d (expected: %d)\0A\00", align 1

; Function Attrs: nounwind uwtable
define dso_local void @patternB_4level_nesting(ptr noundef %A, ptr noundef %B, ptr noundef %C, ptr noundef %D, ptr noundef %E, i32 noundef signext %N, i32 noundef signext %M, i32 noundef signext %P, i32 noundef signext %Q) #0 {
entry:
  %merged_loop_bound = mul i32 %Q, %P
  %merged_loop_bound2 = mul i32 %merged_loop_bound, %M
  %merged_loop_bound3 = mul i32 %merged_loop_bound2, %N
  call void @llvm.interstellar.configure.link(i32 4, ptr %A, i32 8)
  call void @llvm.interstellar.configure.link(i32 5, ptr %B, i32 8)
  call void @llvm.interstellar.configure.link(i32 6, ptr %C, i32 8)
  call void @llvm.interstellar.configure.link(i32 7, ptr %D, i32 8)
  %0 = inttoptr i32 %M to ptr
  call void @llvm.interstellar.configure.link(i32 1, ptr %0, i32 4)
  %1 = inttoptr i32 %N to ptr
  call void @llvm.interstellar.configure.link(i32 0, ptr %1, i32 4)
  %2 = inttoptr i32 %P to ptr
  call void @llvm.interstellar.configure.link(i32 2, ptr %2, i32 4)
  %3 = inttoptr i32 %Q to ptr
  call void @llvm.interstellar.configure.link(i32 3, ptr %3, i32 4)
  %4 = inttoptr i32 %merged_loop_bound3 to ptr
  call void @llvm.interstellar.configure.link(i32 8, ptr %4, i32 4)
  call void @llvm.interstellar.configure.loop(i32 9, i32 0, i1 false, i1 true, i32 0, i32 0, i32 1)
  call void @llvm.interstellar.configure.loop(i32 10, i32 0, i1 false, i1 true, i32 0, i32 1, i32 1)
  call void @llvm.interstellar.configure.loop(i32 11, i32 10, i1 false, i1 true, i32 0, i32 2, i32 1)
  call void @llvm.interstellar.configure.loop(i32 12, i32 11, i1 false, i1 true, i32 0, i32 3, i32 1)
  call void @llvm.interstellar.configure.loop(i32 13, i32 0, i1 false, i1 true, i32 0, i32 8, i32 1)
  call void @llvm.interstellar.configure.directstream(i32 14, i32 9, i1 true, ptr inttoptr (i64 4 to ptr), i32 4)
  call void @llvm.interstellar.configure.directstream(i32 15, i32 10, i1 true, ptr inttoptr (i64 5 to ptr), i32 4)
  call void @llvm.interstellar.configure.directstream(i32 16, i32 11, i1 true, ptr inttoptr (i64 6 to ptr), i32 4)
  call void @llvm.interstellar.configure.directstream(i32 17, i32 12, i1 true, ptr inttoptr (i64 7 to ptr), i32 4)
  call void @llvm.interstellar.configure.directstream(i32 18, i32 13, i1 true, ptr inttoptr (i64 1 to ptr), i32 4)
  br label %for.cond

for.cond:                                         ; preds = %for.inc39, %entry
  %i.0 = phi i32 [ 0, %entry ], [ %inc40, %for.inc39 ]
  %cmp = icmp slt i32 %i.0, %N
  br i1 %cmp, label %for.body, label %for.cond.cleanup

for.cond.cleanup:                                 ; preds = %for.cond
  br label %for.end41

for.body:                                         ; preds = %for.cond
  br label %for.cond1

for.cond1:                                        ; preds = %for.inc36, %for.body
  %j.0 = phi i32 [ 0, %for.body ], [ %inc37, %for.inc36 ]
  %cmp2 = icmp slt i32 %j.0, %M
  br i1 %cmp2, label %for.body4, label %for.cond.cleanup3

for.cond.cleanup3:                                ; preds = %for.cond1
  br label %for.end38

for.body4:                                        ; preds = %for.cond1
  br label %for.cond5

for.cond5:                                        ; preds = %for.inc33, %for.body4
  %k.0 = phi i32 [ 0, %for.body4 ], [ %inc34, %for.inc33 ]
  %cmp6 = icmp slt i32 %k.0, %P
  br i1 %cmp6, label %for.body8, label %for.cond.cleanup7

for.cond.cleanup7:                                ; preds = %for.cond5
  br label %for.end35

for.body8:                                        ; preds = %for.cond5
  br label %for.cond9

for.cond9:                                        ; preds = %for.inc, %for.body8
  %m.0 = phi i32 [ 0, %for.body8 ], [ %inc32, %for.inc ]
  %cmp10 = icmp slt i32 %m.0, %Q
  br i1 %cmp10, label %for.body12, label %for.cond.cleanup11

for.cond.cleanup11:                               ; preds = %for.cond9
  br label %for.end

for.body12:                                       ; preds = %for.cond9
  %idxprom = sext i32 %i.0 to i64
  %arrayidx = getelementptr inbounds i32, ptr %A, i64 %idxprom
  %5 = load i32, ptr %arrayidx, align 4, !tbaa !13
  %inc = add nsw i32 %5, 1
  store i32 %inc, ptr %arrayidx, align 4, !tbaa !13
  %idxprom13 = sext i32 %j.0 to i64
  %arrayidx14 = getelementptr inbounds i32, ptr %B, i64 %idxprom13
  %6 = load i32, ptr %arrayidx14, align 4, !tbaa !13
  %inc15 = add nsw i32 %6, 1
  store i32 %inc15, ptr %arrayidx14, align 4, !tbaa !13
  %idxprom16 = sext i32 %k.0 to i64
  %arrayidx17 = getelementptr inbounds i32, ptr %C, i64 %idxprom16
  %7 = load i32, ptr %arrayidx17, align 4, !tbaa !13
  %inc18 = add nsw i32 %7, 1
  store i32 %inc18, ptr %arrayidx17, align 4, !tbaa !13
  %idxprom19 = sext i32 %m.0 to i64
  %arrayidx20 = getelementptr inbounds i32, ptr %D, i64 %idxprom19
  %8 = load i32, ptr %arrayidx20, align 4, !tbaa !13
  %inc21 = add nsw i32 %8, 1
  store i32 %inc21, ptr %arrayidx20, align 4, !tbaa !13
  %mul = mul nsw i32 %i.0, %M
  %mul22 = mul nsw i32 %mul, %P
  %mul23 = mul nsw i32 %mul22, %Q
  %mul24 = mul nsw i32 %j.0, %P
  %mul25 = mul nsw i32 %mul24, %Q
  %add = add nsw i32 %mul23, %mul25
  %mul26 = mul nsw i32 %k.0, %Q
  %add27 = add nsw i32 %add, %mul26
  %add28 = add nsw i32 %add27, %m.0
  %idxprom29 = sext i32 %add28 to i64
  %arrayidx30 = getelementptr inbounds i32, ptr %E, i64 %idxprom29
  %9 = load i32, ptr %arrayidx30, align 4, !tbaa !13
  %inc31 = add nsw i32 %9, 1
  store i32 %inc31, ptr %arrayidx30, align 4, !tbaa !13
  br label %for.inc

for.inc:                                          ; preds = %for.body12
  %inc32 = add nsw i32 %m.0, 1
  br label %for.cond9, !llvm.loop !14

for.end:                                          ; preds = %for.cond.cleanup11
  br label %for.inc33

for.inc33:                                        ; preds = %for.end
  %inc34 = add nsw i32 %k.0, 1
  br label %for.cond5, !llvm.loop !17

for.end35:                                        ; preds = %for.cond.cleanup7
  br label %for.inc36

for.inc36:                                        ; preds = %for.end35
  %inc37 = add nsw i32 %j.0, 1
  br label %for.cond1, !llvm.loop !18

for.end38:                                        ; preds = %for.cond.cleanup3
  br label %for.inc39

for.inc39:                                        ; preds = %for.end38
  %inc40 = add nsw i32 %i.0, 1
  br label %for.cond, !llvm.loop !19

for.end41:                                        ; preds = %for.cond.cleanup
  ret void
}

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(ptr captures(none)) #1

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(ptr captures(none)) #1

; Function Attrs: nounwind uwtable
define dso_local void @patternB_4d_array(ptr noundef %A, i32 noundef signext %N) #0 {
entry:
  %0 = inttoptr i32 %N to ptr
  call void @llvm.interstellar.configure.link(i32 0, ptr %0, i32 4)
  call void @llvm.interstellar.configure.loop(i32 2, i32 0, i1 false, i1 true, i32 0, i32 0, i32 1)
  call void @llvm.interstellar.configure.loop(i32 3, i32 0, i1 false, i1 false, i32 0, i32 10, i32 1)
  call void @llvm.interstellar.configure.loop(i32 4, i32 3, i1 false, i1 false, i32 0, i32 90, i32 1)
  br label %for.cond

for.cond:                                         ; preds = %for.inc26, %entry
  %i.0 = phi i32 [ 0, %entry ], [ %inc27, %for.inc26 ]
  %cmp = icmp slt i32 %i.0, %N
  br i1 %cmp, label %for.body, label %for.cond.cleanup

for.cond.cleanup:                                 ; preds = %for.cond
  br label %for.end28

for.body:                                         ; preds = %for.cond
  br label %for.cond1

for.cond1:                                        ; preds = %for.inc23, %for.body
  %j.0 = phi i32 [ 0, %for.body ], [ %inc24, %for.inc23 ]
  %cmp2 = icmp slt i32 %j.0, 10
  br i1 %cmp2, label %for.body4, label %for.cond.cleanup3

for.cond.cleanup3:                                ; preds = %for.cond1
  br label %for.end25

for.body4:                                        ; preds = %for.cond1
  br label %for.cond5

for.cond5:                                        ; preds = %for.inc20, %for.body4
  %k.0 = phi i32 [ 0, %for.body4 ], [ %inc21, %for.inc20 ]
  %cmp6 = icmp slt i32 %k.0, 9
  br i1 %cmp6, label %for.body8, label %for.cond.cleanup7

for.cond.cleanup7:                                ; preds = %for.cond5
  br label %for.end22

for.body8:                                        ; preds = %for.cond5
  br label %for.cond9

for.cond9:                                        ; preds = %for.inc, %for.body8
  %m.0 = phi i32 [ 0, %for.body8 ], [ %inc19, %for.inc ]
  %cmp10 = icmp slt i32 %m.0, 10
  br i1 %cmp10, label %for.body12, label %for.cond.cleanup11

for.cond.cleanup11:                               ; preds = %for.cond9
  br label %for.end

for.body12:                                       ; preds = %for.cond9
  %idxprom = sext i32 %i.0 to i64
  %arrayidx = getelementptr inbounds [10 x [10 x [10 x i32]]], ptr %A, i64 %idxprom
  %idxprom13 = sext i32 %j.0 to i64
  %arrayidx14 = getelementptr inbounds [10 x [10 x [10 x i32]]], ptr %arrayidx, i64 0, i64 %idxprom13
  %idxprom15 = sext i32 %k.0 to i64
  %arrayidx16 = getelementptr inbounds [10 x [10 x i32]], ptr %arrayidx14, i64 0, i64 %idxprom15
  %idxprom17 = sext i32 %m.0 to i64
  %arrayidx18 = getelementptr inbounds [10 x i32], ptr %arrayidx16, i64 0, i64 %idxprom17
  %1 = load i32, ptr %arrayidx18, align 4, !tbaa !13
  %inc = add nsw i32 %1, 1
  store i32 %inc, ptr %arrayidx18, align 4, !tbaa !13
  br label %for.inc

for.inc:                                          ; preds = %for.body12
  %inc19 = add nsw i32 %m.0, 1
  br label %for.cond9, !llvm.loop !20

for.end:                                          ; preds = %for.cond.cleanup11
  br label %for.inc20

for.inc20:                                        ; preds = %for.end
  %inc21 = add nsw i32 %k.0, 1
  br label %for.cond5, !llvm.loop !21

for.end22:                                        ; preds = %for.cond.cleanup7
  br label %for.inc23

for.inc23:                                        ; preds = %for.end22
  %inc24 = add nsw i32 %j.0, 1
  br label %for.cond1, !llvm.loop !22

for.end25:                                        ; preds = %for.cond.cleanup3
  br label %for.inc26

for.inc26:                                        ; preds = %for.end25
  %inc27 = add nsw i32 %i.0, 1
  br label %for.cond, !llvm.loop !23

for.end28:                                        ; preds = %for.cond.cleanup
  ret void
}

; Function Attrs: nounwind uwtable
define dso_local void @patternB_4d_array_pointer(ptr noundef %A, i32 noundef signext %N, i32 noundef signext %M, i32 noundef signext %P, i32 noundef signext %Q) #0 {
entry:
  %merged_loop_bound = mul i32 %Q, %P
  %merged_loop_bound2 = mul i32 %merged_loop_bound, %M
  %merged_loop_bound3 = mul i32 %merged_loop_bound2, %N
  %0 = inttoptr i32 %M to ptr
  call void @llvm.interstellar.configure.link(i32 1, ptr %0, i32 4)
  %1 = inttoptr i32 %merged_loop_bound3 to ptr
  call void @llvm.interstellar.configure.link(i32 4, ptr %1, i32 4)
  call void @llvm.interstellar.configure.loop(i32 5, i32 0, i1 false, i1 true, i32 0, i32 4, i32 1)
  call void @llvm.interstellar.configure.directstream(i32 6, i32 5, i1 true, ptr inttoptr (i64 1 to ptr), i32 4)
  br label %for.cond

for.cond:                                         ; preds = %for.inc27, %entry
  %i.0 = phi i32 [ 0, %entry ], [ %inc28, %for.inc27 ]
  %cmp = icmp slt i32 %i.0, %N
  br i1 %cmp, label %for.body, label %for.cond.cleanup

for.cond.cleanup:                                 ; preds = %for.cond
  br label %for.end29

for.body:                                         ; preds = %for.cond
  br label %for.cond1

for.cond1:                                        ; preds = %for.inc24, %for.body
  %j.0 = phi i32 [ 0, %for.body ], [ %inc25, %for.inc24 ]
  %cmp2 = icmp slt i32 %j.0, %M
  br i1 %cmp2, label %for.body4, label %for.cond.cleanup3

for.cond.cleanup3:                                ; preds = %for.cond1
  br label %for.end26

for.body4:                                        ; preds = %for.cond1
  br label %for.cond5

for.cond5:                                        ; preds = %for.inc21, %for.body4
  %k.0 = phi i32 [ 0, %for.body4 ], [ %inc22, %for.inc21 ]
  %cmp6 = icmp slt i32 %k.0, %P
  br i1 %cmp6, label %for.body8, label %for.cond.cleanup7

for.cond.cleanup7:                                ; preds = %for.cond5
  br label %for.end23

for.body8:                                        ; preds = %for.cond5
  br label %for.cond9

for.cond9:                                        ; preds = %for.inc, %for.body8
  %m.0 = phi i32 [ 0, %for.body8 ], [ %inc20, %for.inc ]
  %cmp10 = icmp slt i32 %m.0, %Q
  br i1 %cmp10, label %for.body12, label %for.cond.cleanup11

for.cond.cleanup11:                               ; preds = %for.cond9
  br label %for.end

for.body12:                                       ; preds = %for.cond9
  %mul = mul nsw i32 %i.0, %M
  %mul13 = mul nsw i32 %mul, %P
  %mul14 = mul nsw i32 %mul13, %Q
  %mul15 = mul nsw i32 %j.0, %P
  %mul16 = mul nsw i32 %mul15, %Q
  %add = add nsw i32 %mul14, %mul16
  %mul17 = mul nsw i32 %k.0, %Q
  %add18 = add nsw i32 %add, %mul17
  %add19 = add nsw i32 %add18, %m.0
  %idxprom = sext i32 %add19 to i64
  %arrayidx = getelementptr inbounds i32, ptr %A, i64 %idxprom
  %2 = load i32, ptr %arrayidx, align 4, !tbaa !13
  %inc = add nsw i32 %2, 1
  store i32 %inc, ptr %arrayidx, align 4, !tbaa !13
  br label %for.inc

for.inc:                                          ; preds = %for.body12
  %inc20 = add nsw i32 %m.0, 1
  br label %for.cond9, !llvm.loop !24

for.end:                                          ; preds = %for.cond.cleanup11
  br label %for.inc21

for.inc21:                                        ; preds = %for.end
  %inc22 = add nsw i32 %k.0, 1
  br label %for.cond5, !llvm.loop !25

for.end23:                                        ; preds = %for.cond.cleanup7
  br label %for.inc24

for.inc24:                                        ; preds = %for.end23
  %inc25 = add nsw i32 %j.0, 1
  br label %for.cond1, !llvm.loop !26

for.end26:                                        ; preds = %for.cond.cleanup3
  br label %for.inc27

for.inc27:                                        ; preds = %for.end26
  %inc28 = add nsw i32 %i.0, 1
  br label %for.cond, !llvm.loop !27

for.end29:                                        ; preds = %for.cond.cleanup
  ret void
}

; Function Attrs: nounwind uwtable
define dso_local signext i32 @main() #0 {
entry:
  %conv = sext i32 4 to i64
  %call = call noalias ptr @calloc(i64 noundef %conv, i64 noundef 4) #6
  %conv1 = sext i32 5 to i64
  %call2 = call noalias ptr @calloc(i64 noundef %conv1, i64 noundef 4) #6
  %conv3 = sext i32 6 to i64
  %call4 = call noalias ptr @calloc(i64 noundef %conv3, i64 noundef 4) #6
  %conv5 = sext i32 7 to i64
  %call6 = call noalias ptr @calloc(i64 noundef %conv5, i64 noundef 4) #6
  %mul = mul nsw i32 4, 5
  %mul7 = mul nsw i32 %mul, 6
  %mul8 = mul nsw i32 %mul7, 7
  %conv9 = sext i32 %mul8 to i64
  %call10 = call noalias ptr @calloc(i64 noundef %conv9, i64 noundef 4) #6
  call void @patternB_4level_nesting(ptr noundef %call, ptr noundef %call2, ptr noundef %call4, ptr noundef %call6, ptr noundef %call10, i32 noundef signext 4, i32 noundef signext 5, i32 noundef signext 6, i32 noundef signext 7)
  %arrayidx = getelementptr inbounds i32, ptr %call, i64 0
  %0 = load i32, ptr %arrayidx, align 4, !tbaa !13
  %mul11 = mul nsw i32 5, 6
  %mul12 = mul nsw i32 %mul11, 7
  %call13 = call signext i32 (ptr, ...) @printf(ptr noundef @.str, i32 noundef signext %0, i32 noundef signext %mul12)
  %arrayidx14 = getelementptr inbounds i32, ptr %call2, i64 0
  %1 = load i32, ptr %arrayidx14, align 4, !tbaa !13
  %mul15 = mul nsw i32 4, 6
  %mul16 = mul nsw i32 %mul15, 7
  %call17 = call signext i32 (ptr, ...) @printf(ptr noundef @.str.1, i32 noundef signext %1, i32 noundef signext %mul16)
  %arrayidx18 = getelementptr inbounds i32, ptr %call4, i64 0
  %2 = load i32, ptr %arrayidx18, align 4, !tbaa !13
  %mul19 = mul nsw i32 4, 5
  %mul20 = mul nsw i32 %mul19, 7
  %call21 = call signext i32 (ptr, ...) @printf(ptr noundef @.str.2, i32 noundef signext %2, i32 noundef signext %mul20)
  %arrayidx22 = getelementptr inbounds i32, ptr %call6, i64 0
  %3 = load i32, ptr %arrayidx22, align 4, !tbaa !13
  %mul23 = mul nsw i32 4, 5
  %mul24 = mul nsw i32 %mul23, 6
  %call25 = call signext i32 (ptr, ...) @printf(ptr noundef @.str.3, i32 noundef signext %3, i32 noundef signext %mul24)
  call void @free(ptr noundef %call) #7
  call void @free(ptr noundef %call2) #7
  call void @free(ptr noundef %call4) #7
  call void @free(ptr noundef %call6) #7
  call void @free(ptr noundef %call10) #7
  ret i32 0
}

; Function Attrs: nounwind allocsize(0,1)
declare noalias ptr @calloc(i64 noundef, i64 noundef) #2

declare signext i32 @printf(ptr noundef, ...) #3

; Function Attrs: nounwind
declare void @free(ptr noundef) #4

; Function Attrs: nocallback nofree nosync nounwind willreturn
declare void @llvm.interstellar.configure.link(i32, ptr, i32) #5

; Function Attrs: nocallback nofree nosync nounwind willreturn
declare void @llvm.interstellar.configure.loop(i32, i32, i1, i1, i32, i32, i32) #5

; Function Attrs: nocallback nofree nosync nounwind willreturn
declare void @llvm.interstellar.configure.directstream(i32, i32, i1, ptr, i32) #5

; Function Attrs: nocallback nofree nosync nounwind willreturn
declare void @llvm.interstellar.configure.indirectstream(i32, i32, i1, ptr, i32, i32) #5

attributes #0 = { nounwind uwtable "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="generic-rv64" "target-features"="+64bit,+a,+c,+d,+f,+i,+m,+relax,+zaamo,+zalrsc,+zca,+zcd,+zicsr,+zifencei,+zmmul,-b,-e,-experimental-p,-experimental-smpmpmt,-experimental-svukte,-experimental-xqccmt,-experimental-xsfmclic,-experimental-xsfsclic,-experimental-y,-experimental-zibi,-experimental-zicfilp,-experimental-zicfiss,-experimental-zvabd,-experimental-zvbc32e,-experimental-zvdot4a8i,-experimental-zvfbdota32f,-experimental-zvfbfa,-experimental-zvfofp8min,-experimental-zvfqwbdota8f,-experimental-zvfqwdota8f,-experimental-zvfwbdota16bf,-experimental-zvfwdota16bf,-experimental-zvkgs,-experimental-zvqwbdota16i,-experimental-zvqwbdota8i,-experimental-zvqwdota16i,-experimental-zvqwdota8i,-experimental-zvvfmm,-experimental-zvvmm,-experimental-zvvmtls,-experimental-zvvmttls,-experimental-zvzip,-h,-q,-sdext,-sdtrig,-sha,-shcounterenw,-shgatpa,-shlcofideleg,-shtvala,-shvsatpa,-shvstvala,-shvstvecd,-smaia,-smcdeleg,-smcntrpmf,-smcsrind,-smctr,-smdbltrp,-smepmp,-smmpm,-smnpm,-smrnmi,-smstateen,-ssaia,-ssccfg,-ssccptr,-sscofpmf,-sscounterenw,-sscsrind,-ssctr,-ssdbltrp,-ssnpm,-sspm,-ssqosid,-ssstateen,-ssstrict,-sstc,-sstvala,-sstvecd,-ssu64xl,-supm,-svade,-svadu,-svbare,-svinval,-svnapot,-svpbmt,-svrsw60t59b,-svvptc,-v,-xaifet,-xandesbfhcvt,-xandesperf,-xandesvbfhcvt,-xandesvdot,-xandesvpackfph,-xandesvsinth,-xandesvsintload,-xcheriot,-xcvalu,-xcvbi,-xcvbitmanip,-xcvelw,-xcvmac,-xcvmem,-xcvsimd,-xmipscbop,-xmipscmov,-xmipsexectl,-xmipslsp,-xqccmp,-xqci,-xqcia,-xqciac,-xqcibi,-xqcibm,-xqcicli,-xqcicm,-xqcics,-xqcicsr,-xqciint,-xqciio,-xqcilb,-xqcili,-xqcilia,-xqcilo,-xqcilsm,-xqcisim,-xqcisls,-xqcisync,-xsfcease,-xsfmm128t,-xsfmm16t,-xsfmm32a,-xsfmm32a16f,-xsfmm32a32f,-xsfmm32a8f,-xsfmm32a8i,-xsfmm32t,-xsfmm64a64f,-xsfmm64t,-xsfmmbase,-xsfvcp,-xsfvfbfexp16e,-xsfvfexp16e,-xsfvfexp32e,-xsfvfexpa,-xsfvfexpa64e,-xsfvfnrclipxfqf,-xsfvfwmaccqqq,-xsfvqmaccdod,-xsfvqmaccqoq,-xsifivecdiscarddlone,-xsifivecflushdlone,-xsmtvdot,-xsmtvdotii,-xtheadba,-xtheadbb,-xtheadbs,-xtheadcmo,-xtheadcondmov,-xtheadfmemidx,-xtheadmac,-xtheadmemidx,-xtheadmempair,-xtheadsync,-xtheadvdot,-xventanacondops,-xwchc,-za128rs,-za64rs,-zabha,-zacas,-zalasr,-zama16b,-zawrs,-zba,-zbb,-zbc,-zbkb,-zbkc,-zbkx,-zbs,-zcb,-zce,-zcf,-zclsd,-zcmop,-zcmp,-zcmt,-zdinx,-zfa,-zfbfmin,-zfh,-zfhmin,-zfinx,-zhinx,-zhinxmin,-zic64b,-zicbom,-zicbop,-zicboz,-ziccamoa,-ziccamoc,-ziccid,-ziccif,-zicclsm,-ziccrse,-zicntr,-zicond,-zihintntl,-zihintpause,-zihpm,-zilsd,-zimop,-zk,-zkn,-zknd,-zkne,-zknh,-zkr,-zks,-zksed,-zksh,-zkt,-ztso,-zvbb,-zvbc,-zve32f,-zve32x,-zve64d,-zve64f,-zve64x,-zvfbfmin,-zvfbfwma,-zvfh,-zvfhmin,-zvkb,-zvkg,-zvkn,-zvknc,-zvkned,-zvkng,-zvknha,-zvknhb,-zvks,-zvksc,-zvksed,-zvksg,-zvksh,-zvkt,-zvl1024b,-zvl128b,-zvl16384b,-zvl2048b,-zvl256b,-zvl32768b,-zvl32b,-zvl4096b,-zvl512b,-zvl64b,-zvl65536b,-zvl8192b" }
attributes #1 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { nounwind allocsize(0,1) "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="generic-rv64" "target-features"="+64bit,+a,+c,+d,+f,+i,+m,+relax,+zaamo,+zalrsc,+zca,+zcd,+zicsr,+zifencei,+zmmul,-b,-e,-experimental-p,-experimental-smpmpmt,-experimental-svukte,-experimental-xqccmt,-experimental-xsfmclic,-experimental-xsfsclic,-experimental-y,-experimental-zibi,-experimental-zicfilp,-experimental-zicfiss,-experimental-zvabd,-experimental-zvbc32e,-experimental-zvdot4a8i,-experimental-zvfbdota32f,-experimental-zvfbfa,-experimental-zvfofp8min,-experimental-zvfqwbdota8f,-experimental-zvfqwdota8f,-experimental-zvfwbdota16bf,-experimental-zvfwdota16bf,-experimental-zvkgs,-experimental-zvqwbdota16i,-experimental-zvqwbdota8i,-experimental-zvqwdota16i,-experimental-zvqwdota8i,-experimental-zvvfmm,-experimental-zvvmm,-experimental-zvvmtls,-experimental-zvvmttls,-experimental-zvzip,-h,-q,-sdext,-sdtrig,-sha,-shcounterenw,-shgatpa,-shlcofideleg,-shtvala,-shvsatpa,-shvstvala,-shvstvecd,-smaia,-smcdeleg,-smcntrpmf,-smcsrind,-smctr,-smdbltrp,-smepmp,-smmpm,-smnpm,-smrnmi,-smstateen,-ssaia,-ssccfg,-ssccptr,-sscofpmf,-sscounterenw,-sscsrind,-ssctr,-ssdbltrp,-ssnpm,-sspm,-ssqosid,-ssstateen,-ssstrict,-sstc,-sstvala,-sstvecd,-ssu64xl,-supm,-svade,-svadu,-svbare,-svinval,-svnapot,-svpbmt,-svrsw60t59b,-svvptc,-v,-xaifet,-xandesbfhcvt,-xandesperf,-xandesvbfhcvt,-xandesvdot,-xandesvpackfph,-xandesvsinth,-xandesvsintload,-xcheriot,-xcvalu,-xcvbi,-xcvbitmanip,-xcvelw,-xcvmac,-xcvmem,-xcvsimd,-xmipscbop,-xmipscmov,-xmipsexectl,-xmipslsp,-xqccmp,-xqci,-xqcia,-xqciac,-xqcibi,-xqcibm,-xqcicli,-xqcicm,-xqcics,-xqcicsr,-xqciint,-xqciio,-xqcilb,-xqcili,-xqcilia,-xqcilo,-xqcilsm,-xqcisim,-xqcisls,-xqcisync,-xsfcease,-xsfmm128t,-xsfmm16t,-xsfmm32a,-xsfmm32a16f,-xsfmm32a32f,-xsfmm32a8f,-xsfmm32a8i,-xsfmm32t,-xsfmm64a64f,-xsfmm64t,-xsfmmbase,-xsfvcp,-xsfvfbfexp16e,-xsfvfexp16e,-xsfvfexp32e,-xsfvfexpa,-xsfvfexpa64e,-xsfvfnrclipxfqf,-xsfvfwmaccqqq,-xsfvqmaccdod,-xsfvqmaccqoq,-xsifivecdiscarddlone,-xsifivecflushdlone,-xsmtvdot,-xsmtvdotii,-xtheadba,-xtheadbb,-xtheadbs,-xtheadcmo,-xtheadcondmov,-xtheadfmemidx,-xtheadmac,-xtheadmemidx,-xtheadmempair,-xtheadsync,-xtheadvdot,-xventanacondops,-xwchc,-za128rs,-za64rs,-zabha,-zacas,-zalasr,-zama16b,-zawrs,-zba,-zbb,-zbc,-zbkb,-zbkc,-zbkx,-zbs,-zcb,-zce,-zcf,-zclsd,-zcmop,-zcmp,-zcmt,-zdinx,-zfa,-zfbfmin,-zfh,-zfhmin,-zfinx,-zhinx,-zhinxmin,-zic64b,-zicbom,-zicbop,-zicboz,-ziccamoa,-ziccamoc,-ziccid,-ziccif,-zicclsm,-ziccrse,-zicntr,-zicond,-zihintntl,-zihintpause,-zihpm,-zilsd,-zimop,-zk,-zkn,-zknd,-zkne,-zknh,-zkr,-zks,-zksed,-zksh,-zkt,-ztso,-zvbb,-zvbc,-zve32f,-zve32x,-zve64d,-zve64f,-zve64x,-zvfbfmin,-zvfbfwma,-zvfh,-zvfhmin,-zvkb,-zvkg,-zvkn,-zvknc,-zvkned,-zvkng,-zvknha,-zvknhb,-zvks,-zvksc,-zvksed,-zvksg,-zvksh,-zvkt,-zvl1024b,-zvl128b,-zvl16384b,-zvl2048b,-zvl256b,-zvl32768b,-zvl32b,-zvl4096b,-zvl512b,-zvl64b,-zvl65536b,-zvl8192b" }
attributes #3 = { "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="generic-rv64" "target-features"="+64bit,+a,+c,+d,+f,+i,+m,+relax,+zaamo,+zalrsc,+zca,+zcd,+zicsr,+zifencei,+zmmul,-b,-e,-experimental-p,-experimental-smpmpmt,-experimental-svukte,-experimental-xqccmt,-experimental-xsfmclic,-experimental-xsfsclic,-experimental-y,-experimental-zibi,-experimental-zicfilp,-experimental-zicfiss,-experimental-zvabd,-experimental-zvbc32e,-experimental-zvdot4a8i,-experimental-zvfbdota32f,-experimental-zvfbfa,-experimental-zvfofp8min,-experimental-zvfqwbdota8f,-experimental-zvfqwdota8f,-experimental-zvfwbdota16bf,-experimental-zvfwdota16bf,-experimental-zvkgs,-experimental-zvqwbdota16i,-experimental-zvqwbdota8i,-experimental-zvqwdota16i,-experimental-zvqwdota8i,-experimental-zvvfmm,-experimental-zvvmm,-experimental-zvvmtls,-experimental-zvvmttls,-experimental-zvzip,-h,-q,-sdext,-sdtrig,-sha,-shcounterenw,-shgatpa,-shlcofideleg,-shtvala,-shvsatpa,-shvstvala,-shvstvecd,-smaia,-smcdeleg,-smcntrpmf,-smcsrind,-smctr,-smdbltrp,-smepmp,-smmpm,-smnpm,-smrnmi,-smstateen,-ssaia,-ssccfg,-ssccptr,-sscofpmf,-sscounterenw,-sscsrind,-ssctr,-ssdbltrp,-ssnpm,-sspm,-ssqosid,-ssstateen,-ssstrict,-sstc,-sstvala,-sstvecd,-ssu64xl,-supm,-svade,-svadu,-svbare,-svinval,-svnapot,-svpbmt,-svrsw60t59b,-svvptc,-v,-xaifet,-xandesbfhcvt,-xandesperf,-xandesvbfhcvt,-xandesvdot,-xandesvpackfph,-xandesvsinth,-xandesvsintload,-xcheriot,-xcvalu,-xcvbi,-xcvbitmanip,-xcvelw,-xcvmac,-xcvmem,-xcvsimd,-xmipscbop,-xmipscmov,-xmipsexectl,-xmipslsp,-xqccmp,-xqci,-xqcia,-xqciac,-xqcibi,-xqcibm,-xqcicli,-xqcicm,-xqcics,-xqcicsr,-xqciint,-xqciio,-xqcilb,-xqcili,-xqcilia,-xqcilo,-xqcilsm,-xqcisim,-xqcisls,-xqcisync,-xsfcease,-xsfmm128t,-xsfmm16t,-xsfmm32a,-xsfmm32a16f,-xsfmm32a32f,-xsfmm32a8f,-xsfmm32a8i,-xsfmm32t,-xsfmm64a64f,-xsfmm64t,-xsfmmbase,-xsfvcp,-xsfvfbfexp16e,-xsfvfexp16e,-xsfvfexp32e,-xsfvfexpa,-xsfvfexpa64e,-xsfvfnrclipxfqf,-xsfvfwmaccqqq,-xsfvqmaccdod,-xsfvqmaccqoq,-xsifivecdiscarddlone,-xsifivecflushdlone,-xsmtvdot,-xsmtvdotii,-xtheadba,-xtheadbb,-xtheadbs,-xtheadcmo,-xtheadcondmov,-xtheadfmemidx,-xtheadmac,-xtheadmemidx,-xtheadmempair,-xtheadsync,-xtheadvdot,-xventanacondops,-xwchc,-za128rs,-za64rs,-zabha,-zacas,-zalasr,-zama16b,-zawrs,-zba,-zbb,-zbc,-zbkb,-zbkc,-zbkx,-zbs,-zcb,-zce,-zcf,-zclsd,-zcmop,-zcmp,-zcmt,-zdinx,-zfa,-zfbfmin,-zfh,-zfhmin,-zfinx,-zhinx,-zhinxmin,-zic64b,-zicbom,-zicbop,-zicboz,-ziccamoa,-ziccamoc,-ziccid,-ziccif,-zicclsm,-ziccrse,-zicntr,-zicond,-zihintntl,-zihintpause,-zihpm,-zilsd,-zimop,-zk,-zkn,-zknd,-zkne,-zknh,-zkr,-zks,-zksed,-zksh,-zkt,-ztso,-zvbb,-zvbc,-zve32f,-zve32x,-zve64d,-zve64f,-zve64x,-zvfbfmin,-zvfbfwma,-zvfh,-zvfhmin,-zvkb,-zvkg,-zvkn,-zvknc,-zvkned,-zvkng,-zvknha,-zvknhb,-zvks,-zvksc,-zvksed,-zvksg,-zvksh,-zvkt,-zvl1024b,-zvl128b,-zvl16384b,-zvl2048b,-zvl256b,-zvl32768b,-zvl32b,-zvl4096b,-zvl512b,-zvl64b,-zvl65536b,-zvl8192b" }
attributes #4 = { nounwind "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="generic-rv64" "target-features"="+64bit,+a,+c,+d,+f,+i,+m,+relax,+zaamo,+zalrsc,+zca,+zcd,+zicsr,+zifencei,+zmmul,-b,-e,-experimental-p,-experimental-smpmpmt,-experimental-svukte,-experimental-xqccmt,-experimental-xsfmclic,-experimental-xsfsclic,-experimental-y,-experimental-zibi,-experimental-zicfilp,-experimental-zicfiss,-experimental-zvabd,-experimental-zvbc32e,-experimental-zvdot4a8i,-experimental-zvfbdota32f,-experimental-zvfbfa,-experimental-zvfofp8min,-experimental-zvfqwbdota8f,-experimental-zvfqwdota8f,-experimental-zvfwbdota16bf,-experimental-zvfwdota16bf,-experimental-zvkgs,-experimental-zvqwbdota16i,-experimental-zvqwbdota8i,-experimental-zvqwdota16i,-experimental-zvqwdota8i,-experimental-zvvfmm,-experimental-zvvmm,-experimental-zvvmtls,-experimental-zvvmttls,-experimental-zvzip,-h,-q,-sdext,-sdtrig,-sha,-shcounterenw,-shgatpa,-shlcofideleg,-shtvala,-shvsatpa,-shvstvala,-shvstvecd,-smaia,-smcdeleg,-smcntrpmf,-smcsrind,-smctr,-smdbltrp,-smepmp,-smmpm,-smnpm,-smrnmi,-smstateen,-ssaia,-ssccfg,-ssccptr,-sscofpmf,-sscounterenw,-sscsrind,-ssctr,-ssdbltrp,-ssnpm,-sspm,-ssqosid,-ssstateen,-ssstrict,-sstc,-sstvala,-sstvecd,-ssu64xl,-supm,-svade,-svadu,-svbare,-svinval,-svnapot,-svpbmt,-svrsw60t59b,-svvptc,-v,-xaifet,-xandesbfhcvt,-xandesperf,-xandesvbfhcvt,-xandesvdot,-xandesvpackfph,-xandesvsinth,-xandesvsintload,-xcheriot,-xcvalu,-xcvbi,-xcvbitmanip,-xcvelw,-xcvmac,-xcvmem,-xcvsimd,-xmipscbop,-xmipscmov,-xmipsexectl,-xmipslsp,-xqccmp,-xqci,-xqcia,-xqciac,-xqcibi,-xqcibm,-xqcicli,-xqcicm,-xqcics,-xqcicsr,-xqciint,-xqciio,-xqcilb,-xqcili,-xqcilia,-xqcilo,-xqcilsm,-xqcisim,-xqcisls,-xqcisync,-xsfcease,-xsfmm128t,-xsfmm16t,-xsfmm32a,-xsfmm32a16f,-xsfmm32a32f,-xsfmm32a8f,-xsfmm32a8i,-xsfmm32t,-xsfmm64a64f,-xsfmm64t,-xsfmmbase,-xsfvcp,-xsfvfbfexp16e,-xsfvfexp16e,-xsfvfexp32e,-xsfvfexpa,-xsfvfexpa64e,-xsfvfnrclipxfqf,-xsfvfwmaccqqq,-xsfvqmaccdod,-xsfvqmaccqoq,-xsifivecdiscarddlone,-xsifivecflushdlone,-xsmtvdot,-xsmtvdotii,-xtheadba,-xtheadbb,-xtheadbs,-xtheadcmo,-xtheadcondmov,-xtheadfmemidx,-xtheadmac,-xtheadmemidx,-xtheadmempair,-xtheadsync,-xtheadvdot,-xventanacondops,-xwchc,-za128rs,-za64rs,-zabha,-zacas,-zalasr,-zama16b,-zawrs,-zba,-zbb,-zbc,-zbkb,-zbkc,-zbkx,-zbs,-zcb,-zce,-zcf,-zclsd,-zcmop,-zcmp,-zcmt,-zdinx,-zfa,-zfbfmin,-zfh,-zfhmin,-zfinx,-zhinx,-zhinxmin,-zic64b,-zicbom,-zicbop,-zicboz,-ziccamoa,-ziccamoc,-ziccid,-ziccif,-zicclsm,-ziccrse,-zicntr,-zicond,-zihintntl,-zihintpause,-zihpm,-zilsd,-zimop,-zk,-zkn,-zknd,-zkne,-zknh,-zkr,-zks,-zksed,-zksh,-zkt,-ztso,-zvbb,-zvbc,-zve32f,-zve32x,-zve64d,-zve64f,-zve64x,-zvfbfmin,-zvfbfwma,-zvfh,-zvfhmin,-zvkb,-zvkg,-zvkn,-zvknc,-zvkned,-zvkng,-zvknha,-zvknhb,-zvks,-zvksc,-zvksed,-zvksg,-zvksh,-zvkt,-zvl1024b,-zvl128b,-zvl16384b,-zvl2048b,-zvl256b,-zvl32768b,-zvl32b,-zvl4096b,-zvl512b,-zvl64b,-zvl65536b,-zvl8192b" }
attributes #5 = { nocallback nofree nosync nounwind willreturn }
attributes #6 = { nounwind allocsize(0,1) }
attributes #7 = { nounwind }

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
!22 = distinct !{!22, !15, !16}
!23 = distinct !{!23, !15, !16}
!24 = distinct !{!24, !15, !16}
!25 = distinct !{!25, !15, !16}
!26 = distinct !{!26, !15, !16}
!27 = distinct !{!27, !15, !16}
