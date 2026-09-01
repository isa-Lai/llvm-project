; ModuleID = 'patternB_4level_nesting.c'
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
  %A.addr = alloca ptr, align 8
  %B.addr = alloca ptr, align 8
  %C.addr = alloca ptr, align 8
  %D.addr = alloca ptr, align 8
  %E.addr = alloca ptr, align 8
  %N.addr = alloca i32, align 4
  %M.addr = alloca i32, align 4
  %P.addr = alloca i32, align 4
  %Q.addr = alloca i32, align 4
  %i = alloca i32, align 4
  %cleanup.dest.slot = alloca i32, align 4
  %j = alloca i32, align 4
  %k = alloca i32, align 4
  %m = alloca i32, align 4
  store ptr %A, ptr %A.addr, align 8, !tbaa !13
  store ptr %B, ptr %B.addr, align 8, !tbaa !13
  store ptr %C, ptr %C.addr, align 8, !tbaa !13
  store ptr %D, ptr %D.addr, align 8, !tbaa !13
  store ptr %E, ptr %E.addr, align 8, !tbaa !13
  store i32 %N, ptr %N.addr, align 4, !tbaa !16
  store i32 %M, ptr %M.addr, align 4, !tbaa !16
  store i32 %P, ptr %P.addr, align 4, !tbaa !16
  store i32 %Q, ptr %Q.addr, align 4, !tbaa !16
  call void @llvm.lifetime.start.p0(ptr %i) #5
  store i32 0, ptr %i, align 4, !tbaa !16
  br label %for.cond

for.cond:                                         ; preds = %for.inc39, %entry
  %0 = load i32, ptr %i, align 4, !tbaa !16
  %1 = load i32, ptr %N.addr, align 4, !tbaa !16
  %cmp = icmp slt i32 %0, %1
  br i1 %cmp, label %for.body, label %for.cond.cleanup

for.cond.cleanup:                                 ; preds = %for.cond
  store i32 2, ptr %cleanup.dest.slot, align 4
  call void @llvm.lifetime.end.p0(ptr %i) #5
  br label %for.end41

for.body:                                         ; preds = %for.cond
  call void @llvm.lifetime.start.p0(ptr %j) #5
  store i32 0, ptr %j, align 4, !tbaa !16
  br label %for.cond1

for.cond1:                                        ; preds = %for.inc36, %for.body
  %2 = load i32, ptr %j, align 4, !tbaa !16
  %3 = load i32, ptr %M.addr, align 4, !tbaa !16
  %cmp2 = icmp slt i32 %2, %3
  br i1 %cmp2, label %for.body4, label %for.cond.cleanup3

for.cond.cleanup3:                                ; preds = %for.cond1
  store i32 5, ptr %cleanup.dest.slot, align 4
  call void @llvm.lifetime.end.p0(ptr %j) #5
  br label %for.end38

for.body4:                                        ; preds = %for.cond1
  call void @llvm.lifetime.start.p0(ptr %k) #5
  store i32 0, ptr %k, align 4, !tbaa !16
  br label %for.cond5

for.cond5:                                        ; preds = %for.inc33, %for.body4
  %4 = load i32, ptr %k, align 4, !tbaa !16
  %5 = load i32, ptr %P.addr, align 4, !tbaa !16
  %cmp6 = icmp slt i32 %4, %5
  br i1 %cmp6, label %for.body8, label %for.cond.cleanup7

for.cond.cleanup7:                                ; preds = %for.cond5
  store i32 8, ptr %cleanup.dest.slot, align 4
  call void @llvm.lifetime.end.p0(ptr %k) #5
  br label %for.end35

for.body8:                                        ; preds = %for.cond5
  call void @llvm.lifetime.start.p0(ptr %m) #5
  store i32 0, ptr %m, align 4, !tbaa !16
  br label %for.cond9

for.cond9:                                        ; preds = %for.inc, %for.body8
  %6 = load i32, ptr %m, align 4, !tbaa !16
  %7 = load i32, ptr %Q.addr, align 4, !tbaa !16
  %cmp10 = icmp slt i32 %6, %7
  br i1 %cmp10, label %for.body12, label %for.cond.cleanup11

for.cond.cleanup11:                               ; preds = %for.cond9
  store i32 11, ptr %cleanup.dest.slot, align 4
  call void @llvm.lifetime.end.p0(ptr %m) #5
  br label %for.end

for.body12:                                       ; preds = %for.cond9
  %8 = load ptr, ptr %A.addr, align 8, !tbaa !13
  %9 = load i32, ptr %i, align 4, !tbaa !16
  %idxprom = sext i32 %9 to i64
  %arrayidx = getelementptr inbounds i32, ptr %8, i64 %idxprom
  %10 = load i32, ptr %arrayidx, align 4, !tbaa !16
  %inc = add nsw i32 %10, 1
  store i32 %inc, ptr %arrayidx, align 4, !tbaa !16
  %11 = load ptr, ptr %B.addr, align 8, !tbaa !13
  %12 = load i32, ptr %j, align 4, !tbaa !16
  %idxprom13 = sext i32 %12 to i64
  %arrayidx14 = getelementptr inbounds i32, ptr %11, i64 %idxprom13
  %13 = load i32, ptr %arrayidx14, align 4, !tbaa !16
  %inc15 = add nsw i32 %13, 1
  store i32 %inc15, ptr %arrayidx14, align 4, !tbaa !16
  %14 = load ptr, ptr %C.addr, align 8, !tbaa !13
  %15 = load i32, ptr %k, align 4, !tbaa !16
  %idxprom16 = sext i32 %15 to i64
  %arrayidx17 = getelementptr inbounds i32, ptr %14, i64 %idxprom16
  %16 = load i32, ptr %arrayidx17, align 4, !tbaa !16
  %inc18 = add nsw i32 %16, 1
  store i32 %inc18, ptr %arrayidx17, align 4, !tbaa !16
  %17 = load ptr, ptr %D.addr, align 8, !tbaa !13
  %18 = load i32, ptr %m, align 4, !tbaa !16
  %idxprom19 = sext i32 %18 to i64
  %arrayidx20 = getelementptr inbounds i32, ptr %17, i64 %idxprom19
  %19 = load i32, ptr %arrayidx20, align 4, !tbaa !16
  %inc21 = add nsw i32 %19, 1
  store i32 %inc21, ptr %arrayidx20, align 4, !tbaa !16
  %20 = load ptr, ptr %E.addr, align 8, !tbaa !13
  %21 = load i32, ptr %i, align 4, !tbaa !16
  %22 = load i32, ptr %M.addr, align 4, !tbaa !16
  %mul = mul nsw i32 %21, %22
  %23 = load i32, ptr %P.addr, align 4, !tbaa !16
  %mul22 = mul nsw i32 %mul, %23
  %24 = load i32, ptr %Q.addr, align 4, !tbaa !16
  %mul23 = mul nsw i32 %mul22, %24
  %25 = load i32, ptr %j, align 4, !tbaa !16
  %26 = load i32, ptr %P.addr, align 4, !tbaa !16
  %mul24 = mul nsw i32 %25, %26
  %27 = load i32, ptr %Q.addr, align 4, !tbaa !16
  %mul25 = mul nsw i32 %mul24, %27
  %add = add nsw i32 %mul23, %mul25
  %28 = load i32, ptr %k, align 4, !tbaa !16
  %29 = load i32, ptr %Q.addr, align 4, !tbaa !16
  %mul26 = mul nsw i32 %28, %29
  %add27 = add nsw i32 %add, %mul26
  %30 = load i32, ptr %m, align 4, !tbaa !16
  %add28 = add nsw i32 %add27, %30
  %idxprom29 = sext i32 %add28 to i64
  %arrayidx30 = getelementptr inbounds i32, ptr %20, i64 %idxprom29
  %31 = load i32, ptr %arrayidx30, align 4, !tbaa !16
  %inc31 = add nsw i32 %31, 1
  store i32 %inc31, ptr %arrayidx30, align 4, !tbaa !16
  br label %for.inc

for.inc:                                          ; preds = %for.body12
  %32 = load i32, ptr %m, align 4, !tbaa !16
  %inc32 = add nsw i32 %32, 1
  store i32 %inc32, ptr %m, align 4, !tbaa !16
  br label %for.cond9, !llvm.loop !17

for.end:                                          ; preds = %for.cond.cleanup11
  br label %for.inc33

for.inc33:                                        ; preds = %for.end
  %33 = load i32, ptr %k, align 4, !tbaa !16
  %inc34 = add nsw i32 %33, 1
  store i32 %inc34, ptr %k, align 4, !tbaa !16
  br label %for.cond5, !llvm.loop !20

for.end35:                                        ; preds = %for.cond.cleanup7
  br label %for.inc36

for.inc36:                                        ; preds = %for.end35
  %34 = load i32, ptr %j, align 4, !tbaa !16
  %inc37 = add nsw i32 %34, 1
  store i32 %inc37, ptr %j, align 4, !tbaa !16
  br label %for.cond1, !llvm.loop !21

for.end38:                                        ; preds = %for.cond.cleanup3
  br label %for.inc39

for.inc39:                                        ; preds = %for.end38
  %35 = load i32, ptr %i, align 4, !tbaa !16
  %inc40 = add nsw i32 %35, 1
  store i32 %inc40, ptr %i, align 4, !tbaa !16
  br label %for.cond, !llvm.loop !22

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
  %A.addr = alloca ptr, align 8
  %N.addr = alloca i32, align 4
  %i = alloca i32, align 4
  %cleanup.dest.slot = alloca i32, align 4
  %j = alloca i32, align 4
  %k = alloca i32, align 4
  %m = alloca i32, align 4
  store ptr %A, ptr %A.addr, align 8, !tbaa !13
  store i32 %N, ptr %N.addr, align 4, !tbaa !16
  call void @llvm.lifetime.start.p0(ptr %i) #5
  store i32 0, ptr %i, align 4, !tbaa !16
  br label %for.cond

for.cond:                                         ; preds = %for.inc26, %entry
  %0 = load i32, ptr %i, align 4, !tbaa !16
  %1 = load i32, ptr %N.addr, align 4, !tbaa !16
  %cmp = icmp slt i32 %0, %1
  br i1 %cmp, label %for.body, label %for.cond.cleanup

for.cond.cleanup:                                 ; preds = %for.cond
  store i32 2, ptr %cleanup.dest.slot, align 4
  call void @llvm.lifetime.end.p0(ptr %i) #5
  br label %for.end28

for.body:                                         ; preds = %for.cond
  call void @llvm.lifetime.start.p0(ptr %j) #5
  store i32 0, ptr %j, align 4, !tbaa !16
  br label %for.cond1

for.cond1:                                        ; preds = %for.inc23, %for.body
  %2 = load i32, ptr %j, align 4, !tbaa !16
  %cmp2 = icmp slt i32 %2, 10
  br i1 %cmp2, label %for.body4, label %for.cond.cleanup3

for.cond.cleanup3:                                ; preds = %for.cond1
  store i32 5, ptr %cleanup.dest.slot, align 4
  call void @llvm.lifetime.end.p0(ptr %j) #5
  br label %for.end25

for.body4:                                        ; preds = %for.cond1
  call void @llvm.lifetime.start.p0(ptr %k) #5
  store i32 0, ptr %k, align 4, !tbaa !16
  br label %for.cond5

for.cond5:                                        ; preds = %for.inc20, %for.body4
  %3 = load i32, ptr %k, align 4, !tbaa !16
  %cmp6 = icmp slt i32 %3, 9
  br i1 %cmp6, label %for.body8, label %for.cond.cleanup7

for.cond.cleanup7:                                ; preds = %for.cond5
  store i32 8, ptr %cleanup.dest.slot, align 4
  call void @llvm.lifetime.end.p0(ptr %k) #5
  br label %for.end22

for.body8:                                        ; preds = %for.cond5
  call void @llvm.lifetime.start.p0(ptr %m) #5
  store i32 0, ptr %m, align 4, !tbaa !16
  br label %for.cond9

for.cond9:                                        ; preds = %for.inc, %for.body8
  %4 = load i32, ptr %m, align 4, !tbaa !16
  %cmp10 = icmp slt i32 %4, 10
  br i1 %cmp10, label %for.body12, label %for.cond.cleanup11

for.cond.cleanup11:                               ; preds = %for.cond9
  store i32 11, ptr %cleanup.dest.slot, align 4
  call void @llvm.lifetime.end.p0(ptr %m) #5
  br label %for.end

for.body12:                                       ; preds = %for.cond9
  %5 = load ptr, ptr %A.addr, align 8, !tbaa !13
  %6 = load i32, ptr %i, align 4, !tbaa !16
  %idxprom = sext i32 %6 to i64
  %arrayidx = getelementptr inbounds [10 x [10 x [10 x i32]]], ptr %5, i64 %idxprom
  %7 = load i32, ptr %j, align 4, !tbaa !16
  %idxprom13 = sext i32 %7 to i64
  %arrayidx14 = getelementptr inbounds [10 x [10 x [10 x i32]]], ptr %arrayidx, i64 0, i64 %idxprom13
  %8 = load i32, ptr %k, align 4, !tbaa !16
  %idxprom15 = sext i32 %8 to i64
  %arrayidx16 = getelementptr inbounds [10 x [10 x i32]], ptr %arrayidx14, i64 0, i64 %idxprom15
  %9 = load i32, ptr %m, align 4, !tbaa !16
  %idxprom17 = sext i32 %9 to i64
  %arrayidx18 = getelementptr inbounds [10 x i32], ptr %arrayidx16, i64 0, i64 %idxprom17
  %10 = load i32, ptr %arrayidx18, align 4, !tbaa !16
  %inc = add nsw i32 %10, 1
  store i32 %inc, ptr %arrayidx18, align 4, !tbaa !16
  br label %for.inc

for.inc:                                          ; preds = %for.body12
  %11 = load i32, ptr %m, align 4, !tbaa !16
  %inc19 = add nsw i32 %11, 1
  store i32 %inc19, ptr %m, align 4, !tbaa !16
  br label %for.cond9, !llvm.loop !23

for.end:                                          ; preds = %for.cond.cleanup11
  br label %for.inc20

for.inc20:                                        ; preds = %for.end
  %12 = load i32, ptr %k, align 4, !tbaa !16
  %inc21 = add nsw i32 %12, 1
  store i32 %inc21, ptr %k, align 4, !tbaa !16
  br label %for.cond5, !llvm.loop !24

for.end22:                                        ; preds = %for.cond.cleanup7
  br label %for.inc23

for.inc23:                                        ; preds = %for.end22
  %13 = load i32, ptr %j, align 4, !tbaa !16
  %inc24 = add nsw i32 %13, 1
  store i32 %inc24, ptr %j, align 4, !tbaa !16
  br label %for.cond1, !llvm.loop !25

for.end25:                                        ; preds = %for.cond.cleanup3
  br label %for.inc26

for.inc26:                                        ; preds = %for.end25
  %14 = load i32, ptr %i, align 4, !tbaa !16
  %inc27 = add nsw i32 %14, 1
  store i32 %inc27, ptr %i, align 4, !tbaa !16
  br label %for.cond, !llvm.loop !26

for.end28:                                        ; preds = %for.cond.cleanup
  ret void
}

; Function Attrs: nounwind uwtable
define dso_local void @patternB_4d_array_pointer(ptr noundef %A, i32 noundef signext %N, i32 noundef signext %M, i32 noundef signext %P, i32 noundef signext %Q) #0 {
entry:
  %A.addr = alloca ptr, align 8
  %N.addr = alloca i32, align 4
  %M.addr = alloca i32, align 4
  %P.addr = alloca i32, align 4
  %Q.addr = alloca i32, align 4
  %i = alloca i32, align 4
  %cleanup.dest.slot = alloca i32, align 4
  %j = alloca i32, align 4
  %k = alloca i32, align 4
  %m = alloca i32, align 4
  store ptr %A, ptr %A.addr, align 8, !tbaa !13
  store i32 %N, ptr %N.addr, align 4, !tbaa !16
  store i32 %M, ptr %M.addr, align 4, !tbaa !16
  store i32 %P, ptr %P.addr, align 4, !tbaa !16
  store i32 %Q, ptr %Q.addr, align 4, !tbaa !16
  call void @llvm.lifetime.start.p0(ptr %i) #5
  store i32 0, ptr %i, align 4, !tbaa !16
  br label %for.cond

for.cond:                                         ; preds = %for.inc27, %entry
  %0 = load i32, ptr %i, align 4, !tbaa !16
  %1 = load i32, ptr %N.addr, align 4, !tbaa !16
  %cmp = icmp slt i32 %0, %1
  br i1 %cmp, label %for.body, label %for.cond.cleanup

for.cond.cleanup:                                 ; preds = %for.cond
  store i32 2, ptr %cleanup.dest.slot, align 4
  call void @llvm.lifetime.end.p0(ptr %i) #5
  br label %for.end29

for.body:                                         ; preds = %for.cond
  call void @llvm.lifetime.start.p0(ptr %j) #5
  store i32 0, ptr %j, align 4, !tbaa !16
  br label %for.cond1

for.cond1:                                        ; preds = %for.inc24, %for.body
  %2 = load i32, ptr %j, align 4, !tbaa !16
  %3 = load i32, ptr %M.addr, align 4, !tbaa !16
  %cmp2 = icmp slt i32 %2, %3
  br i1 %cmp2, label %for.body4, label %for.cond.cleanup3

for.cond.cleanup3:                                ; preds = %for.cond1
  store i32 5, ptr %cleanup.dest.slot, align 4
  call void @llvm.lifetime.end.p0(ptr %j) #5
  br label %for.end26

for.body4:                                        ; preds = %for.cond1
  call void @llvm.lifetime.start.p0(ptr %k) #5
  store i32 0, ptr %k, align 4, !tbaa !16
  br label %for.cond5

for.cond5:                                        ; preds = %for.inc21, %for.body4
  %4 = load i32, ptr %k, align 4, !tbaa !16
  %5 = load i32, ptr %P.addr, align 4, !tbaa !16
  %cmp6 = icmp slt i32 %4, %5
  br i1 %cmp6, label %for.body8, label %for.cond.cleanup7

for.cond.cleanup7:                                ; preds = %for.cond5
  store i32 8, ptr %cleanup.dest.slot, align 4
  call void @llvm.lifetime.end.p0(ptr %k) #5
  br label %for.end23

for.body8:                                        ; preds = %for.cond5
  call void @llvm.lifetime.start.p0(ptr %m) #5
  store i32 0, ptr %m, align 4, !tbaa !16
  br label %for.cond9

for.cond9:                                        ; preds = %for.inc, %for.body8
  %6 = load i32, ptr %m, align 4, !tbaa !16
  %7 = load i32, ptr %Q.addr, align 4, !tbaa !16
  %cmp10 = icmp slt i32 %6, %7
  br i1 %cmp10, label %for.body12, label %for.cond.cleanup11

for.cond.cleanup11:                               ; preds = %for.cond9
  store i32 11, ptr %cleanup.dest.slot, align 4
  call void @llvm.lifetime.end.p0(ptr %m) #5
  br label %for.end

for.body12:                                       ; preds = %for.cond9
  %8 = load ptr, ptr %A.addr, align 8, !tbaa !13
  %9 = load i32, ptr %i, align 4, !tbaa !16
  %10 = load i32, ptr %M.addr, align 4, !tbaa !16
  %mul = mul nsw i32 %9, %10
  %11 = load i32, ptr %P.addr, align 4, !tbaa !16
  %mul13 = mul nsw i32 %mul, %11
  %12 = load i32, ptr %Q.addr, align 4, !tbaa !16
  %mul14 = mul nsw i32 %mul13, %12
  %13 = load i32, ptr %j, align 4, !tbaa !16
  %14 = load i32, ptr %P.addr, align 4, !tbaa !16
  %mul15 = mul nsw i32 %13, %14
  %15 = load i32, ptr %Q.addr, align 4, !tbaa !16
  %mul16 = mul nsw i32 %mul15, %15
  %add = add nsw i32 %mul14, %mul16
  %16 = load i32, ptr %k, align 4, !tbaa !16
  %17 = load i32, ptr %Q.addr, align 4, !tbaa !16
  %mul17 = mul nsw i32 %16, %17
  %add18 = add nsw i32 %add, %mul17
  %18 = load i32, ptr %m, align 4, !tbaa !16
  %add19 = add nsw i32 %add18, %18
  %idxprom = sext i32 %add19 to i64
  %arrayidx = getelementptr inbounds i32, ptr %8, i64 %idxprom
  %19 = load i32, ptr %arrayidx, align 4, !tbaa !16
  %inc = add nsw i32 %19, 1
  store i32 %inc, ptr %arrayidx, align 4, !tbaa !16
  br label %for.inc

for.inc:                                          ; preds = %for.body12
  %20 = load i32, ptr %m, align 4, !tbaa !16
  %inc20 = add nsw i32 %20, 1
  store i32 %inc20, ptr %m, align 4, !tbaa !16
  br label %for.cond9, !llvm.loop !27

for.end:                                          ; preds = %for.cond.cleanup11
  br label %for.inc21

for.inc21:                                        ; preds = %for.end
  %21 = load i32, ptr %k, align 4, !tbaa !16
  %inc22 = add nsw i32 %21, 1
  store i32 %inc22, ptr %k, align 4, !tbaa !16
  br label %for.cond5, !llvm.loop !28

for.end23:                                        ; preds = %for.cond.cleanup7
  br label %for.inc24

for.inc24:                                        ; preds = %for.end23
  %22 = load i32, ptr %j, align 4, !tbaa !16
  %inc25 = add nsw i32 %22, 1
  store i32 %inc25, ptr %j, align 4, !tbaa !16
  br label %for.cond1, !llvm.loop !29

for.end26:                                        ; preds = %for.cond.cleanup3
  br label %for.inc27

for.inc27:                                        ; preds = %for.end26
  %23 = load i32, ptr %i, align 4, !tbaa !16
  %inc28 = add nsw i32 %23, 1
  store i32 %inc28, ptr %i, align 4, !tbaa !16
  br label %for.cond, !llvm.loop !30

for.end29:                                        ; preds = %for.cond.cleanup
  ret void
}

; Function Attrs: nounwind uwtable
define dso_local signext i32 @main() #0 {
entry:
  %retval = alloca i32, align 4
  %N = alloca i32, align 4
  %M = alloca i32, align 4
  %P = alloca i32, align 4
  %Q = alloca i32, align 4
  %A = alloca ptr, align 8
  %B = alloca ptr, align 8
  %C = alloca ptr, align 8
  %D = alloca ptr, align 8
  %E = alloca ptr, align 8
  store i32 0, ptr %retval, align 4
  call void @llvm.lifetime.start.p0(ptr %N) #5
  store i32 4, ptr %N, align 4, !tbaa !16
  call void @llvm.lifetime.start.p0(ptr %M) #5
  store i32 5, ptr %M, align 4, !tbaa !16
  call void @llvm.lifetime.start.p0(ptr %P) #5
  store i32 6, ptr %P, align 4, !tbaa !16
  call void @llvm.lifetime.start.p0(ptr %Q) #5
  store i32 7, ptr %Q, align 4, !tbaa !16
  call void @llvm.lifetime.start.p0(ptr %A) #5
  %0 = load i32, ptr %N, align 4, !tbaa !16
  %conv = sext i32 %0 to i64
  %call = call noalias ptr @calloc(i64 noundef %conv, i64 noundef 4) #6
  store ptr %call, ptr %A, align 8, !tbaa !13
  call void @llvm.lifetime.start.p0(ptr %B) #5
  %1 = load i32, ptr %M, align 4, !tbaa !16
  %conv1 = sext i32 %1 to i64
  %call2 = call noalias ptr @calloc(i64 noundef %conv1, i64 noundef 4) #6
  store ptr %call2, ptr %B, align 8, !tbaa !13
  call void @llvm.lifetime.start.p0(ptr %C) #5
  %2 = load i32, ptr %P, align 4, !tbaa !16
  %conv3 = sext i32 %2 to i64
  %call4 = call noalias ptr @calloc(i64 noundef %conv3, i64 noundef 4) #6
  store ptr %call4, ptr %C, align 8, !tbaa !13
  call void @llvm.lifetime.start.p0(ptr %D) #5
  %3 = load i32, ptr %Q, align 4, !tbaa !16
  %conv5 = sext i32 %3 to i64
  %call6 = call noalias ptr @calloc(i64 noundef %conv5, i64 noundef 4) #6
  store ptr %call6, ptr %D, align 8, !tbaa !13
  call void @llvm.lifetime.start.p0(ptr %E) #5
  %4 = load i32, ptr %N, align 4, !tbaa !16
  %5 = load i32, ptr %M, align 4, !tbaa !16
  %mul = mul nsw i32 %4, %5
  %6 = load i32, ptr %P, align 4, !tbaa !16
  %mul7 = mul nsw i32 %mul, %6
  %7 = load i32, ptr %Q, align 4, !tbaa !16
  %mul8 = mul nsw i32 %mul7, %7
  %conv9 = sext i32 %mul8 to i64
  %call10 = call noalias ptr @calloc(i64 noundef %conv9, i64 noundef 4) #6
  store ptr %call10, ptr %E, align 8, !tbaa !13
  %8 = load ptr, ptr %A, align 8, !tbaa !13
  %9 = load ptr, ptr %B, align 8, !tbaa !13
  %10 = load ptr, ptr %C, align 8, !tbaa !13
  %11 = load ptr, ptr %D, align 8, !tbaa !13
  %12 = load ptr, ptr %E, align 8, !tbaa !13
  %13 = load i32, ptr %N, align 4, !tbaa !16
  %14 = load i32, ptr %M, align 4, !tbaa !16
  %15 = load i32, ptr %P, align 4, !tbaa !16
  %16 = load i32, ptr %Q, align 4, !tbaa !16
  call void @patternB_4level_nesting(ptr noundef %8, ptr noundef %9, ptr noundef %10, ptr noundef %11, ptr noundef %12, i32 noundef signext %13, i32 noundef signext %14, i32 noundef signext %15, i32 noundef signext %16)
  %17 = load ptr, ptr %A, align 8, !tbaa !13
  %arrayidx = getelementptr inbounds i32, ptr %17, i64 0
  %18 = load i32, ptr %arrayidx, align 4, !tbaa !16
  %19 = load i32, ptr %M, align 4, !tbaa !16
  %20 = load i32, ptr %P, align 4, !tbaa !16
  %mul11 = mul nsw i32 %19, %20
  %21 = load i32, ptr %Q, align 4, !tbaa !16
  %mul12 = mul nsw i32 %mul11, %21
  %call13 = call signext i32 (ptr, ...) @printf(ptr noundef @.str, i32 noundef signext %18, i32 noundef signext %mul12)
  %22 = load ptr, ptr %B, align 8, !tbaa !13
  %arrayidx14 = getelementptr inbounds i32, ptr %22, i64 0
  %23 = load i32, ptr %arrayidx14, align 4, !tbaa !16
  %24 = load i32, ptr %N, align 4, !tbaa !16
  %25 = load i32, ptr %P, align 4, !tbaa !16
  %mul15 = mul nsw i32 %24, %25
  %26 = load i32, ptr %Q, align 4, !tbaa !16
  %mul16 = mul nsw i32 %mul15, %26
  %call17 = call signext i32 (ptr, ...) @printf(ptr noundef @.str.1, i32 noundef signext %23, i32 noundef signext %mul16)
  %27 = load ptr, ptr %C, align 8, !tbaa !13
  %arrayidx18 = getelementptr inbounds i32, ptr %27, i64 0
  %28 = load i32, ptr %arrayidx18, align 4, !tbaa !16
  %29 = load i32, ptr %N, align 4, !tbaa !16
  %30 = load i32, ptr %M, align 4, !tbaa !16
  %mul19 = mul nsw i32 %29, %30
  %31 = load i32, ptr %Q, align 4, !tbaa !16
  %mul20 = mul nsw i32 %mul19, %31
  %call21 = call signext i32 (ptr, ...) @printf(ptr noundef @.str.2, i32 noundef signext %28, i32 noundef signext %mul20)
  %32 = load ptr, ptr %D, align 8, !tbaa !13
  %arrayidx22 = getelementptr inbounds i32, ptr %32, i64 0
  %33 = load i32, ptr %arrayidx22, align 4, !tbaa !16
  %34 = load i32, ptr %N, align 4, !tbaa !16
  %35 = load i32, ptr %M, align 4, !tbaa !16
  %mul23 = mul nsw i32 %34, %35
  %36 = load i32, ptr %P, align 4, !tbaa !16
  %mul24 = mul nsw i32 %mul23, %36
  %call25 = call signext i32 (ptr, ...) @printf(ptr noundef @.str.3, i32 noundef signext %33, i32 noundef signext %mul24)
  %37 = load ptr, ptr %A, align 8, !tbaa !13
  call void @free(ptr noundef %37) #5
  %38 = load ptr, ptr %B, align 8, !tbaa !13
  call void @free(ptr noundef %38) #5
  %39 = load ptr, ptr %C, align 8, !tbaa !13
  call void @free(ptr noundef %39) #5
  %40 = load ptr, ptr %D, align 8, !tbaa !13
  call void @free(ptr noundef %40) #5
  %41 = load ptr, ptr %E, align 8, !tbaa !13
  call void @free(ptr noundef %41) #5
  call void @llvm.lifetime.end.p0(ptr %E) #5
  call void @llvm.lifetime.end.p0(ptr %D) #5
  call void @llvm.lifetime.end.p0(ptr %C) #5
  call void @llvm.lifetime.end.p0(ptr %B) #5
  call void @llvm.lifetime.end.p0(ptr %A) #5
  call void @llvm.lifetime.end.p0(ptr %Q) #5
  call void @llvm.lifetime.end.p0(ptr %P) #5
  call void @llvm.lifetime.end.p0(ptr %M) #5
  call void @llvm.lifetime.end.p0(ptr %N) #5
  ret i32 0
}

; Function Attrs: nounwind allocsize(0,1)
declare noalias ptr @calloc(i64 noundef, i64 noundef) #2

declare signext i32 @printf(ptr noundef, ...) #3

; Function Attrs: nounwind
declare void @free(ptr noundef) #4

attributes #0 = { nounwind uwtable "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="generic-rv64" "target-features"="+64bit,+a,+c,+d,+f,+i,+m,+relax,+zaamo,+zalrsc,+zca,+zcd,+zicsr,+zifencei,+zmmul,-b,-e,-experimental-p,-experimental-smpmpmt,-experimental-svukte,-experimental-xqccmt,-experimental-xsfmclic,-experimental-xsfsclic,-experimental-y,-experimental-zibi,-experimental-zicfilp,-experimental-zicfiss,-experimental-zvabd,-experimental-zvbc32e,-experimental-zvdot4a8i,-experimental-zvfbdota32f,-experimental-zvfbfa,-experimental-zvfofp8min,-experimental-zvfqwbdota8f,-experimental-zvfqwdota8f,-experimental-zvfwbdota16bf,-experimental-zvfwdota16bf,-experimental-zvkgs,-experimental-zvqwbdota16i,-experimental-zvqwbdota8i,-experimental-zvqwdota16i,-experimental-zvqwdota8i,-experimental-zvvfmm,-experimental-zvvmm,-experimental-zvvmtls,-experimental-zvvmttls,-experimental-zvzip,-h,-q,-sdext,-sdtrig,-sha,-shcounterenw,-shgatpa,-shlcofideleg,-shtvala,-shvsatpa,-shvstvala,-shvstvecd,-smaia,-smcdeleg,-smcntrpmf,-smcsrind,-smctr,-smdbltrp,-smepmp,-smmpm,-smnpm,-smrnmi,-smstateen,-ssaia,-ssccfg,-ssccptr,-sscofpmf,-sscounterenw,-sscsrind,-ssctr,-ssdbltrp,-ssnpm,-sspm,-ssqosid,-ssstateen,-ssstrict,-sstc,-sstvala,-sstvecd,-ssu64xl,-supm,-svade,-svadu,-svbare,-svinval,-svnapot,-svpbmt,-svrsw60t59b,-svvptc,-v,-xaifet,-xandesbfhcvt,-xandesperf,-xandesvbfhcvt,-xandesvdot,-xandesvpackfph,-xandesvsinth,-xandesvsintload,-xcheriot,-xcvalu,-xcvbi,-xcvbitmanip,-xcvelw,-xcvmac,-xcvmem,-xcvsimd,-xmipscbop,-xmipscmov,-xmipsexectl,-xmipslsp,-xqccmp,-xqci,-xqcia,-xqciac,-xqcibi,-xqcibm,-xqcicli,-xqcicm,-xqcics,-xqcicsr,-xqciint,-xqciio,-xqcilb,-xqcili,-xqcilia,-xqcilo,-xqcilsm,-xqcisim,-xqcisls,-xqcisync,-xsfcease,-xsfmm128t,-xsfmm16t,-xsfmm32a,-xsfmm32a16f,-xsfmm32a32f,-xsfmm32a8f,-xsfmm32a8i,-xsfmm32t,-xsfmm64a64f,-xsfmm64t,-xsfmmbase,-xsfvcp,-xsfvfbfexp16e,-xsfvfexp16e,-xsfvfexp32e,-xsfvfexpa,-xsfvfexpa64e,-xsfvfnrclipxfqf,-xsfvfwmaccqqq,-xsfvqmaccdod,-xsfvqmaccqoq,-xsifivecdiscarddlone,-xsifivecflushdlone,-xsmtvdot,-xsmtvdotii,-xtheadba,-xtheadbb,-xtheadbs,-xtheadcmo,-xtheadcondmov,-xtheadfmemidx,-xtheadmac,-xtheadmemidx,-xtheadmempair,-xtheadsync,-xtheadvdot,-xventanacondops,-xwchc,-za128rs,-za64rs,-zabha,-zacas,-zalasr,-zama16b,-zawrs,-zba,-zbb,-zbc,-zbkb,-zbkc,-zbkx,-zbs,-zcb,-zce,-zcf,-zclsd,-zcmop,-zcmp,-zcmt,-zdinx,-zfa,-zfbfmin,-zfh,-zfhmin,-zfinx,-zhinx,-zhinxmin,-zic64b,-zicbom,-zicbop,-zicboz,-ziccamoa,-ziccamoc,-ziccid,-ziccif,-zicclsm,-ziccrse,-zicntr,-zicond,-zihintntl,-zihintpause,-zihpm,-zilsd,-zimop,-zk,-zkn,-zknd,-zkne,-zknh,-zkr,-zks,-zksed,-zksh,-zkt,-ztso,-zvbb,-zvbc,-zve32f,-zve32x,-zve64d,-zve64f,-zve64x,-zvfbfmin,-zvfbfwma,-zvfh,-zvfhmin,-zvkb,-zvkg,-zvkn,-zvknc,-zvkned,-zvkng,-zvknha,-zvknhb,-zvks,-zvksc,-zvksed,-zvksg,-zvksh,-zvkt,-zvl1024b,-zvl128b,-zvl16384b,-zvl2048b,-zvl256b,-zvl32768b,-zvl32b,-zvl4096b,-zvl512b,-zvl64b,-zvl65536b,-zvl8192b" }
attributes #1 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { nounwind allocsize(0,1) "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="generic-rv64" "target-features"="+64bit,+a,+c,+d,+f,+i,+m,+relax,+zaamo,+zalrsc,+zca,+zcd,+zicsr,+zifencei,+zmmul,-b,-e,-experimental-p,-experimental-smpmpmt,-experimental-svukte,-experimental-xqccmt,-experimental-xsfmclic,-experimental-xsfsclic,-experimental-y,-experimental-zibi,-experimental-zicfilp,-experimental-zicfiss,-experimental-zvabd,-experimental-zvbc32e,-experimental-zvdot4a8i,-experimental-zvfbdota32f,-experimental-zvfbfa,-experimental-zvfofp8min,-experimental-zvfqwbdota8f,-experimental-zvfqwdota8f,-experimental-zvfwbdota16bf,-experimental-zvfwdota16bf,-experimental-zvkgs,-experimental-zvqwbdota16i,-experimental-zvqwbdota8i,-experimental-zvqwdota16i,-experimental-zvqwdota8i,-experimental-zvvfmm,-experimental-zvvmm,-experimental-zvvmtls,-experimental-zvvmttls,-experimental-zvzip,-h,-q,-sdext,-sdtrig,-sha,-shcounterenw,-shgatpa,-shlcofideleg,-shtvala,-shvsatpa,-shvstvala,-shvstvecd,-smaia,-smcdeleg,-smcntrpmf,-smcsrind,-smctr,-smdbltrp,-smepmp,-smmpm,-smnpm,-smrnmi,-smstateen,-ssaia,-ssccfg,-ssccptr,-sscofpmf,-sscounterenw,-sscsrind,-ssctr,-ssdbltrp,-ssnpm,-sspm,-ssqosid,-ssstateen,-ssstrict,-sstc,-sstvala,-sstvecd,-ssu64xl,-supm,-svade,-svadu,-svbare,-svinval,-svnapot,-svpbmt,-svrsw60t59b,-svvptc,-v,-xaifet,-xandesbfhcvt,-xandesperf,-xandesvbfhcvt,-xandesvdot,-xandesvpackfph,-xandesvsinth,-xandesvsintload,-xcheriot,-xcvalu,-xcvbi,-xcvbitmanip,-xcvelw,-xcvmac,-xcvmem,-xcvsimd,-xmipscbop,-xmipscmov,-xmipsexectl,-xmipslsp,-xqccmp,-xqci,-xqcia,-xqciac,-xqcibi,-xqcibm,-xqcicli,-xqcicm,-xqcics,-xqcicsr,-xqciint,-xqciio,-xqcilb,-xqcili,-xqcilia,-xqcilo,-xqcilsm,-xqcisim,-xqcisls,-xqcisync,-xsfcease,-xsfmm128t,-xsfmm16t,-xsfmm32a,-xsfmm32a16f,-xsfmm32a32f,-xsfmm32a8f,-xsfmm32a8i,-xsfmm32t,-xsfmm64a64f,-xsfmm64t,-xsfmmbase,-xsfvcp,-xsfvfbfexp16e,-xsfvfexp16e,-xsfvfexp32e,-xsfvfexpa,-xsfvfexpa64e,-xsfvfnrclipxfqf,-xsfvfwmaccqqq,-xsfvqmaccdod,-xsfvqmaccqoq,-xsifivecdiscarddlone,-xsifivecflushdlone,-xsmtvdot,-xsmtvdotii,-xtheadba,-xtheadbb,-xtheadbs,-xtheadcmo,-xtheadcondmov,-xtheadfmemidx,-xtheadmac,-xtheadmemidx,-xtheadmempair,-xtheadsync,-xtheadvdot,-xventanacondops,-xwchc,-za128rs,-za64rs,-zabha,-zacas,-zalasr,-zama16b,-zawrs,-zba,-zbb,-zbc,-zbkb,-zbkc,-zbkx,-zbs,-zcb,-zce,-zcf,-zclsd,-zcmop,-zcmp,-zcmt,-zdinx,-zfa,-zfbfmin,-zfh,-zfhmin,-zfinx,-zhinx,-zhinxmin,-zic64b,-zicbom,-zicbop,-zicboz,-ziccamoa,-ziccamoc,-ziccid,-ziccif,-zicclsm,-ziccrse,-zicntr,-zicond,-zihintntl,-zihintpause,-zihpm,-zilsd,-zimop,-zk,-zkn,-zknd,-zkne,-zknh,-zkr,-zks,-zksed,-zksh,-zkt,-ztso,-zvbb,-zvbc,-zve32f,-zve32x,-zve64d,-zve64f,-zve64x,-zvfbfmin,-zvfbfwma,-zvfh,-zvfhmin,-zvkb,-zvkg,-zvkn,-zvknc,-zvkned,-zvkng,-zvknha,-zvknhb,-zvks,-zvksc,-zvksed,-zvksg,-zvksh,-zvkt,-zvl1024b,-zvl128b,-zvl16384b,-zvl2048b,-zvl256b,-zvl32768b,-zvl32b,-zvl4096b,-zvl512b,-zvl64b,-zvl65536b,-zvl8192b" }
attributes #3 = { "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="generic-rv64" "target-features"="+64bit,+a,+c,+d,+f,+i,+m,+relax,+zaamo,+zalrsc,+zca,+zcd,+zicsr,+zifencei,+zmmul,-b,-e,-experimental-p,-experimental-smpmpmt,-experimental-svukte,-experimental-xqccmt,-experimental-xsfmclic,-experimental-xsfsclic,-experimental-y,-experimental-zibi,-experimental-zicfilp,-experimental-zicfiss,-experimental-zvabd,-experimental-zvbc32e,-experimental-zvdot4a8i,-experimental-zvfbdota32f,-experimental-zvfbfa,-experimental-zvfofp8min,-experimental-zvfqwbdota8f,-experimental-zvfqwdota8f,-experimental-zvfwbdota16bf,-experimental-zvfwdota16bf,-experimental-zvkgs,-experimental-zvqwbdota16i,-experimental-zvqwbdota8i,-experimental-zvqwdota16i,-experimental-zvqwdota8i,-experimental-zvvfmm,-experimental-zvvmm,-experimental-zvvmtls,-experimental-zvvmttls,-experimental-zvzip,-h,-q,-sdext,-sdtrig,-sha,-shcounterenw,-shgatpa,-shlcofideleg,-shtvala,-shvsatpa,-shvstvala,-shvstvecd,-smaia,-smcdeleg,-smcntrpmf,-smcsrind,-smctr,-smdbltrp,-smepmp,-smmpm,-smnpm,-smrnmi,-smstateen,-ssaia,-ssccfg,-ssccptr,-sscofpmf,-sscounterenw,-sscsrind,-ssctr,-ssdbltrp,-ssnpm,-sspm,-ssqosid,-ssstateen,-ssstrict,-sstc,-sstvala,-sstvecd,-ssu64xl,-supm,-svade,-svadu,-svbare,-svinval,-svnapot,-svpbmt,-svrsw60t59b,-svvptc,-v,-xaifet,-xandesbfhcvt,-xandesperf,-xandesvbfhcvt,-xandesvdot,-xandesvpackfph,-xandesvsinth,-xandesvsintload,-xcheriot,-xcvalu,-xcvbi,-xcvbitmanip,-xcvelw,-xcvmac,-xcvmem,-xcvsimd,-xmipscbop,-xmipscmov,-xmipsexectl,-xmipslsp,-xqccmp,-xqci,-xqcia,-xqciac,-xqcibi,-xqcibm,-xqcicli,-xqcicm,-xqcics,-xqcicsr,-xqciint,-xqciio,-xqcilb,-xqcili,-xqcilia,-xqcilo,-xqcilsm,-xqcisim,-xqcisls,-xqcisync,-xsfcease,-xsfmm128t,-xsfmm16t,-xsfmm32a,-xsfmm32a16f,-xsfmm32a32f,-xsfmm32a8f,-xsfmm32a8i,-xsfmm32t,-xsfmm64a64f,-xsfmm64t,-xsfmmbase,-xsfvcp,-xsfvfbfexp16e,-xsfvfexp16e,-xsfvfexp32e,-xsfvfexpa,-xsfvfexpa64e,-xsfvfnrclipxfqf,-xsfvfwmaccqqq,-xsfvqmaccdod,-xsfvqmaccqoq,-xsifivecdiscarddlone,-xsifivecflushdlone,-xsmtvdot,-xsmtvdotii,-xtheadba,-xtheadbb,-xtheadbs,-xtheadcmo,-xtheadcondmov,-xtheadfmemidx,-xtheadmac,-xtheadmemidx,-xtheadmempair,-xtheadsync,-xtheadvdot,-xventanacondops,-xwchc,-za128rs,-za64rs,-zabha,-zacas,-zalasr,-zama16b,-zawrs,-zba,-zbb,-zbc,-zbkb,-zbkc,-zbkx,-zbs,-zcb,-zce,-zcf,-zclsd,-zcmop,-zcmp,-zcmt,-zdinx,-zfa,-zfbfmin,-zfh,-zfhmin,-zfinx,-zhinx,-zhinxmin,-zic64b,-zicbom,-zicbop,-zicboz,-ziccamoa,-ziccamoc,-ziccid,-ziccif,-zicclsm,-ziccrse,-zicntr,-zicond,-zihintntl,-zihintpause,-zihpm,-zilsd,-zimop,-zk,-zkn,-zknd,-zkne,-zknh,-zkr,-zks,-zksed,-zksh,-zkt,-ztso,-zvbb,-zvbc,-zve32f,-zve32x,-zve64d,-zve64f,-zve64x,-zvfbfmin,-zvfbfwma,-zvfh,-zvfhmin,-zvkb,-zvkg,-zvkn,-zvknc,-zvkned,-zvkng,-zvknha,-zvknhb,-zvks,-zvksc,-zvksed,-zvksg,-zvksh,-zvkt,-zvl1024b,-zvl128b,-zvl16384b,-zvl2048b,-zvl256b,-zvl32768b,-zvl32b,-zvl4096b,-zvl512b,-zvl64b,-zvl65536b,-zvl8192b" }
attributes #4 = { nounwind "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="generic-rv64" "target-features"="+64bit,+a,+c,+d,+f,+i,+m,+relax,+zaamo,+zalrsc,+zca,+zcd,+zicsr,+zifencei,+zmmul,-b,-e,-experimental-p,-experimental-smpmpmt,-experimental-svukte,-experimental-xqccmt,-experimental-xsfmclic,-experimental-xsfsclic,-experimental-y,-experimental-zibi,-experimental-zicfilp,-experimental-zicfiss,-experimental-zvabd,-experimental-zvbc32e,-experimental-zvdot4a8i,-experimental-zvfbdota32f,-experimental-zvfbfa,-experimental-zvfofp8min,-experimental-zvfqwbdota8f,-experimental-zvfqwdota8f,-experimental-zvfwbdota16bf,-experimental-zvfwdota16bf,-experimental-zvkgs,-experimental-zvqwbdota16i,-experimental-zvqwbdota8i,-experimental-zvqwdota16i,-experimental-zvqwdota8i,-experimental-zvvfmm,-experimental-zvvmm,-experimental-zvvmtls,-experimental-zvvmttls,-experimental-zvzip,-h,-q,-sdext,-sdtrig,-sha,-shcounterenw,-shgatpa,-shlcofideleg,-shtvala,-shvsatpa,-shvstvala,-shvstvecd,-smaia,-smcdeleg,-smcntrpmf,-smcsrind,-smctr,-smdbltrp,-smepmp,-smmpm,-smnpm,-smrnmi,-smstateen,-ssaia,-ssccfg,-ssccptr,-sscofpmf,-sscounterenw,-sscsrind,-ssctr,-ssdbltrp,-ssnpm,-sspm,-ssqosid,-ssstateen,-ssstrict,-sstc,-sstvala,-sstvecd,-ssu64xl,-supm,-svade,-svadu,-svbare,-svinval,-svnapot,-svpbmt,-svrsw60t59b,-svvptc,-v,-xaifet,-xandesbfhcvt,-xandesperf,-xandesvbfhcvt,-xandesvdot,-xandesvpackfph,-xandesvsinth,-xandesvsintload,-xcheriot,-xcvalu,-xcvbi,-xcvbitmanip,-xcvelw,-xcvmac,-xcvmem,-xcvsimd,-xmipscbop,-xmipscmov,-xmipsexectl,-xmipslsp,-xqccmp,-xqci,-xqcia,-xqciac,-xqcibi,-xqcibm,-xqcicli,-xqcicm,-xqcics,-xqcicsr,-xqciint,-xqciio,-xqcilb,-xqcili,-xqcilia,-xqcilo,-xqcilsm,-xqcisim,-xqcisls,-xqcisync,-xsfcease,-xsfmm128t,-xsfmm16t,-xsfmm32a,-xsfmm32a16f,-xsfmm32a32f,-xsfmm32a8f,-xsfmm32a8i,-xsfmm32t,-xsfmm64a64f,-xsfmm64t,-xsfmmbase,-xsfvcp,-xsfvfbfexp16e,-xsfvfexp16e,-xsfvfexp32e,-xsfvfexpa,-xsfvfexpa64e,-xsfvfnrclipxfqf,-xsfvfwmaccqqq,-xsfvqmaccdod,-xsfvqmaccqoq,-xsifivecdiscarddlone,-xsifivecflushdlone,-xsmtvdot,-xsmtvdotii,-xtheadba,-xtheadbb,-xtheadbs,-xtheadcmo,-xtheadcondmov,-xtheadfmemidx,-xtheadmac,-xtheadmemidx,-xtheadmempair,-xtheadsync,-xtheadvdot,-xventanacondops,-xwchc,-za128rs,-za64rs,-zabha,-zacas,-zalasr,-zama16b,-zawrs,-zba,-zbb,-zbc,-zbkb,-zbkc,-zbkx,-zbs,-zcb,-zce,-zcf,-zclsd,-zcmop,-zcmp,-zcmt,-zdinx,-zfa,-zfbfmin,-zfh,-zfhmin,-zfinx,-zhinx,-zhinxmin,-zic64b,-zicbom,-zicbop,-zicboz,-ziccamoa,-ziccamoc,-ziccid,-ziccif,-zicclsm,-ziccrse,-zicntr,-zicond,-zihintntl,-zihintpause,-zihpm,-zilsd,-zimop,-zk,-zkn,-zknd,-zkne,-zknh,-zkr,-zks,-zksed,-zksh,-zkt,-ztso,-zvbb,-zvbc,-zve32f,-zve32x,-zve64d,-zve64f,-zve64x,-zvfbfmin,-zvfbfwma,-zvfh,-zvfhmin,-zvkb,-zvkg,-zvkn,-zvknc,-zvkned,-zvkng,-zvknha,-zvknhb,-zvks,-zvksc,-zvksed,-zvksg,-zvksh,-zvkt,-zvl1024b,-zvl128b,-zvl16384b,-zvl2048b,-zvl256b,-zvl32768b,-zvl32b,-zvl4096b,-zvl512b,-zvl64b,-zvl65536b,-zvl8192b" }
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
!23 = distinct !{!23, !18, !19}
!24 = distinct !{!24, !18, !19}
!25 = distinct !{!25, !18, !19}
!26 = distinct !{!26, !18, !19}
!27 = distinct !{!27, !18, !19}
!28 = distinct !{!28, !18, !19}
!29 = distinct !{!29, !18, !19}
!30 = distinct !{!30, !18, !19}
