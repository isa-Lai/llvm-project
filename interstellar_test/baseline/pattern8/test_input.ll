; ModuleID = 'pattern8_3d_fixed.c'
source_filename = "pattern8_3d_fixed.c"
target datalayout = "e-m:e-p:64:64-i64:64-i128:128-n32:64-S128"
target triple = "riscv64-unknown-linux-gnu"

; Function Attrs: nounwind uwtable
define dso_local void @pattern8_3d_fixed(ptr noundef %A, ptr noundef %D3B, i32 noundef signext %N) #0 {
entry:
  %A.addr = alloca ptr, align 8
  %D3B.addr = alloca ptr, align 8
  %N.addr = alloca i32, align 4
  %D3B_dim1 = alloca i32, align 4
  %D3B_dim2 = alloca i32, align 4
  %i = alloca i32, align 4
  %cleanup.dest.slot = alloca i32, align 4
  %j = alloca i32, align 4
  %k = alloca i32, align 4
  %idx_i = alloca i32, align 4
  %idx_j = alloca i32, align 4
  %idx_k = alloca i32, align 4
  %rand_i = alloca i32, align 4
  %rand_j = alloca i32, align 4
  %rand_k = alloca i32, align 4
  store ptr %A, ptr %A.addr, align 8, !tbaa !13
  store ptr %D3B, ptr %D3B.addr, align 8, !tbaa !13
  store i32 %N, ptr %N.addr, align 4, !tbaa !16
  call void @llvm.lifetime.start.p0(ptr %D3B_dim1) #4
  store i32 10, ptr %D3B_dim1, align 4, !tbaa !16
  call void @llvm.lifetime.start.p0(ptr %D3B_dim2) #4
  store i32 10, ptr %D3B_dim2, align 4, !tbaa !16
  call void @llvm.lifetime.start.p0(ptr %i) #4
  store i32 0, ptr %i, align 4, !tbaa !16
  br label %for.cond

for.cond:                                         ; preds = %for.inc73, %entry
  %0 = load i32, ptr %i, align 4, !tbaa !16
  %1 = load i32, ptr %D3B_dim2, align 4, !tbaa !16
  %cmp = icmp slt i32 %0, %1
  br i1 %cmp, label %for.body, label %for.cond.cleanup

for.cond.cleanup:                                 ; preds = %for.cond
  store i32 2, ptr %cleanup.dest.slot, align 4
  call void @llvm.lifetime.end.p0(ptr %i) #4
  br label %for.end75

for.body:                                         ; preds = %for.cond
  call void @llvm.lifetime.start.p0(ptr %j) #4
  store i32 0, ptr %j, align 4, !tbaa !16
  br label %for.cond1

for.cond1:                                        ; preds = %for.inc70, %for.body
  %2 = load i32, ptr %j, align 4, !tbaa !16
  %cmp2 = icmp slt i32 %2, 10
  br i1 %cmp2, label %for.body4, label %for.cond.cleanup3

for.cond.cleanup3:                                ; preds = %for.cond1
  store i32 5, ptr %cleanup.dest.slot, align 4
  call void @llvm.lifetime.end.p0(ptr %j) #4
  br label %for.end72

for.body4:                                        ; preds = %for.cond1
  call void @llvm.lifetime.start.p0(ptr %k) #4
  store i32 0, ptr %k, align 4, !tbaa !16
  br label %for.cond5

for.cond5:                                        ; preds = %for.inc, %for.body4
  %3 = load i32, ptr %k, align 4, !tbaa !16
  %cmp6 = icmp slt i32 %3, 10
  br i1 %cmp6, label %for.body8, label %for.cond.cleanup7

for.cond.cleanup7:                                ; preds = %for.cond5
  store i32 8, ptr %cleanup.dest.slot, align 4
  call void @llvm.lifetime.end.p0(ptr %k) #4
  br label %for.end

for.body8:                                        ; preds = %for.cond5
  %4 = load ptr, ptr %D3B.addr, align 8, !tbaa !13
  %5 = load i32, ptr %i, align 4, !tbaa !16
  %idxprom = sext i32 %5 to i64
  %arrayidx = getelementptr inbounds [10 x [10 x i32]], ptr %4, i64 %idxprom
  %6 = load i32, ptr %j, align 4, !tbaa !16
  %idxprom9 = sext i32 %6 to i64
  %arrayidx10 = getelementptr inbounds [10 x [10 x i32]], ptr %arrayidx, i64 0, i64 %idxprom9
  %7 = load i32, ptr %k, align 4, !tbaa !16
  %idxprom11 = sext i32 %7 to i64
  %arrayidx12 = getelementptr inbounds [10 x i32], ptr %arrayidx10, i64 0, i64 %idxprom11
  %8 = load i32, ptr %arrayidx12, align 4, !tbaa !16
  %inc = add nsw i32 %8, 1
  store i32 %inc, ptr %arrayidx12, align 4, !tbaa !16
  %9 = load i32, ptr %i, align 4, !tbaa !16
  %10 = load i32, ptr %N.addr, align 4, !tbaa !16
  %cmp13 = icmp slt i32 %9, %10
  br i1 %cmp13, label %if.then, label %if.end

if.then:                                          ; preds = %for.body8
  call void @llvm.lifetime.start.p0(ptr %idx_i) #4
  %11 = load ptr, ptr %A.addr, align 8, !tbaa !13
  %12 = load i32, ptr %i, align 4, !tbaa !16
  %idxprom14 = sext i32 %12 to i64
  %arrayidx15 = getelementptr inbounds i32, ptr %11, i64 %idxprom14
  %13 = load i32, ptr %arrayidx15, align 4, !tbaa !16
  %14 = load i32, ptr %D3B_dim1, align 4, !tbaa !16
  %rem = srem i32 %13, %14
  store i32 %rem, ptr %idx_i, align 4, !tbaa !16
  %15 = load ptr, ptr %D3B.addr, align 8, !tbaa !13
  %16 = load i32, ptr %idx_i, align 4, !tbaa !16
  %idxprom16 = sext i32 %16 to i64
  %arrayidx17 = getelementptr inbounds [10 x [10 x i32]], ptr %15, i64 %idxprom16
  %17 = load i32, ptr %j, align 4, !tbaa !16
  %idxprom18 = sext i32 %17 to i64
  %arrayidx19 = getelementptr inbounds [10 x [10 x i32]], ptr %arrayidx17, i64 0, i64 %idxprom18
  %18 = load i32, ptr %k, align 4, !tbaa !16
  %idxprom20 = sext i32 %18 to i64
  %arrayidx21 = getelementptr inbounds [10 x i32], ptr %arrayidx19, i64 0, i64 %idxprom20
  %19 = load i32, ptr %arrayidx21, align 4, !tbaa !16
  %inc22 = add nsw i32 %19, 1
  store i32 %inc22, ptr %arrayidx21, align 4, !tbaa !16
  call void @llvm.lifetime.start.p0(ptr %idx_j) #4
  %20 = load ptr, ptr %A.addr, align 8, !tbaa !13
  %21 = load i32, ptr %j, align 4, !tbaa !16
  %idxprom23 = sext i32 %21 to i64
  %arrayidx24 = getelementptr inbounds i32, ptr %20, i64 %idxprom23
  %22 = load i32, ptr %arrayidx24, align 4, !tbaa !16
  %rem25 = srem i32 %22, 10
  store i32 %rem25, ptr %idx_j, align 4, !tbaa !16
  %23 = load ptr, ptr %D3B.addr, align 8, !tbaa !13
  %24 = load i32, ptr %i, align 4, !tbaa !16
  %idxprom26 = sext i32 %24 to i64
  %arrayidx27 = getelementptr inbounds [10 x [10 x i32]], ptr %23, i64 %idxprom26
  %25 = load i32, ptr %idx_j, align 4, !tbaa !16
  %idxprom28 = sext i32 %25 to i64
  %arrayidx29 = getelementptr inbounds [10 x [10 x i32]], ptr %arrayidx27, i64 0, i64 %idxprom28
  %26 = load i32, ptr %k, align 4, !tbaa !16
  %idxprom30 = sext i32 %26 to i64
  %arrayidx31 = getelementptr inbounds [10 x i32], ptr %arrayidx29, i64 0, i64 %idxprom30
  %27 = load i32, ptr %arrayidx31, align 4, !tbaa !16
  %inc32 = add nsw i32 %27, 1
  store i32 %inc32, ptr %arrayidx31, align 4, !tbaa !16
  call void @llvm.lifetime.start.p0(ptr %idx_k) #4
  %28 = load ptr, ptr %A.addr, align 8, !tbaa !13
  %29 = load i32, ptr %k, align 4, !tbaa !16
  %idxprom33 = sext i32 %29 to i64
  %arrayidx34 = getelementptr inbounds i32, ptr %28, i64 %idxprom33
  %30 = load i32, ptr %arrayidx34, align 4, !tbaa !16
  %rem35 = srem i32 %30, 10
  store i32 %rem35, ptr %idx_k, align 4, !tbaa !16
  %31 = load ptr, ptr %D3B.addr, align 8, !tbaa !13
  %32 = load i32, ptr %i, align 4, !tbaa !16
  %idxprom36 = sext i32 %32 to i64
  %arrayidx37 = getelementptr inbounds [10 x [10 x i32]], ptr %31, i64 %idxprom36
  %33 = load i32, ptr %j, align 4, !tbaa !16
  %idxprom38 = sext i32 %33 to i64
  %arrayidx39 = getelementptr inbounds [10 x [10 x i32]], ptr %arrayidx37, i64 0, i64 %idxprom38
  %34 = load i32, ptr %idx_k, align 4, !tbaa !16
  %idxprom40 = sext i32 %34 to i64
  %arrayidx41 = getelementptr inbounds [10 x i32], ptr %arrayidx39, i64 0, i64 %idxprom40
  %35 = load i32, ptr %arrayidx41, align 4, !tbaa !16
  %inc42 = add nsw i32 %35, 1
  store i32 %inc42, ptr %arrayidx41, align 4, !tbaa !16
  call void @llvm.lifetime.end.p0(ptr %idx_k) #4
  call void @llvm.lifetime.end.p0(ptr %idx_j) #4
  call void @llvm.lifetime.end.p0(ptr %idx_i) #4
  br label %if.end

if.end:                                           ; preds = %if.then, %for.body8
  call void @llvm.lifetime.start.p0(ptr %rand_i) #4
  %call = call signext i32 @rand() #4
  %36 = load i32, ptr %D3B_dim1, align 4, !tbaa !16
  %rem43 = srem i32 %call, %36
  store i32 %rem43, ptr %rand_i, align 4, !tbaa !16
  %37 = load ptr, ptr %D3B.addr, align 8, !tbaa !13
  %38 = load i32, ptr %rand_i, align 4, !tbaa !16
  %idxprom44 = sext i32 %38 to i64
  %arrayidx45 = getelementptr inbounds [10 x [10 x i32]], ptr %37, i64 %idxprom44
  %39 = load i32, ptr %j, align 4, !tbaa !16
  %idxprom46 = sext i32 %39 to i64
  %arrayidx47 = getelementptr inbounds [10 x [10 x i32]], ptr %arrayidx45, i64 0, i64 %idxprom46
  %40 = load i32, ptr %k, align 4, !tbaa !16
  %idxprom48 = sext i32 %40 to i64
  %arrayidx49 = getelementptr inbounds [10 x i32], ptr %arrayidx47, i64 0, i64 %idxprom48
  %41 = load i32, ptr %arrayidx49, align 4, !tbaa !16
  %inc50 = add nsw i32 %41, 1
  store i32 %inc50, ptr %arrayidx49, align 4, !tbaa !16
  call void @llvm.lifetime.start.p0(ptr %rand_j) #4
  %call51 = call signext i32 @rand() #4
  %rem52 = srem i32 %call51, 10
  store i32 %rem52, ptr %rand_j, align 4, !tbaa !16
  %42 = load ptr, ptr %D3B.addr, align 8, !tbaa !13
  %43 = load i32, ptr %i, align 4, !tbaa !16
  %idxprom53 = sext i32 %43 to i64
  %arrayidx54 = getelementptr inbounds [10 x [10 x i32]], ptr %42, i64 %idxprom53
  %44 = load i32, ptr %rand_j, align 4, !tbaa !16
  %idxprom55 = sext i32 %44 to i64
  %arrayidx56 = getelementptr inbounds [10 x [10 x i32]], ptr %arrayidx54, i64 0, i64 %idxprom55
  %45 = load i32, ptr %k, align 4, !tbaa !16
  %idxprom57 = sext i32 %45 to i64
  %arrayidx58 = getelementptr inbounds [10 x i32], ptr %arrayidx56, i64 0, i64 %idxprom57
  %46 = load i32, ptr %arrayidx58, align 4, !tbaa !16
  %inc59 = add nsw i32 %46, 1
  store i32 %inc59, ptr %arrayidx58, align 4, !tbaa !16
  call void @llvm.lifetime.start.p0(ptr %rand_k) #4
  %call60 = call signext i32 @rand() #4
  %rem61 = srem i32 %call60, 10
  store i32 %rem61, ptr %rand_k, align 4, !tbaa !16
  %47 = load ptr, ptr %D3B.addr, align 8, !tbaa !13
  %48 = load i32, ptr %i, align 4, !tbaa !16
  %idxprom62 = sext i32 %48 to i64
  %arrayidx63 = getelementptr inbounds [10 x [10 x i32]], ptr %47, i64 %idxprom62
  %49 = load i32, ptr %j, align 4, !tbaa !16
  %idxprom64 = sext i32 %49 to i64
  %arrayidx65 = getelementptr inbounds [10 x [10 x i32]], ptr %arrayidx63, i64 0, i64 %idxprom64
  %50 = load i32, ptr %rand_k, align 4, !tbaa !16
  %idxprom66 = sext i32 %50 to i64
  %arrayidx67 = getelementptr inbounds [10 x i32], ptr %arrayidx65, i64 0, i64 %idxprom66
  %51 = load i32, ptr %arrayidx67, align 4, !tbaa !16
  %inc68 = add nsw i32 %51, 1
  store i32 %inc68, ptr %arrayidx67, align 4, !tbaa !16
  call void @llvm.lifetime.end.p0(ptr %rand_k) #4
  call void @llvm.lifetime.end.p0(ptr %rand_j) #4
  call void @llvm.lifetime.end.p0(ptr %rand_i) #4
  br label %for.inc

for.inc:                                          ; preds = %if.end
  %52 = load i32, ptr %k, align 4, !tbaa !16
  %inc69 = add nsw i32 %52, 1
  store i32 %inc69, ptr %k, align 4, !tbaa !16
  br label %for.cond5, !llvm.loop !17

for.end:                                          ; preds = %for.cond.cleanup7
  br label %for.inc70

for.inc70:                                        ; preds = %for.end
  %53 = load i32, ptr %j, align 4, !tbaa !16
  %inc71 = add nsw i32 %53, 1
  store i32 %inc71, ptr %j, align 4, !tbaa !16
  br label %for.cond1, !llvm.loop !20

for.end72:                                        ; preds = %for.cond.cleanup3
  br label %for.inc73

for.inc73:                                        ; preds = %for.end72
  %54 = load i32, ptr %i, align 4, !tbaa !16
  %inc74 = add nsw i32 %54, 1
  store i32 %inc74, ptr %i, align 4, !tbaa !16
  br label %for.cond, !llvm.loop !21

for.end75:                                        ; preds = %for.cond.cleanup
  call void @llvm.lifetime.end.p0(ptr %D3B_dim2) #4
  call void @llvm.lifetime.end.p0(ptr %D3B_dim1) #4
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
  %A.addr = alloca ptr, align 8
  %D3B.addr = alloca ptr, align 8
  %N.addr = alloca i32, align 4
  %D3B_dim1 = alloca i32, align 4
  %D3B_dim2 = alloca i32, align 4
  %i = alloca i32, align 4
  %cleanup.dest.slot = alloca i32, align 4
  %j = alloca i32, align 4
  %k = alloca i32, align 4
  store ptr %A, ptr %A.addr, align 8, !tbaa !13
  store ptr %D3B, ptr %D3B.addr, align 8, !tbaa !13
  store i32 %N, ptr %N.addr, align 4, !tbaa !16
  call void @llvm.lifetime.start.p0(ptr %D3B_dim1) #4
  store i32 10, ptr %D3B_dim1, align 4, !tbaa !16
  call void @llvm.lifetime.start.p0(ptr %D3B_dim2) #4
  store i32 10, ptr %D3B_dim2, align 4, !tbaa !16
  call void @llvm.lifetime.start.p0(ptr %i) #4
  store i32 0, ptr %i, align 4, !tbaa !16
  br label %for.cond

for.cond:                                         ; preds = %for.inc17, %entry
  %0 = load i32, ptr %i, align 4, !tbaa !16
  %1 = load i32, ptr %D3B_dim2, align 4, !tbaa !16
  %cmp = icmp slt i32 %0, %1
  br i1 %cmp, label %for.body, label %for.cond.cleanup

for.cond.cleanup:                                 ; preds = %for.cond
  store i32 2, ptr %cleanup.dest.slot, align 4
  call void @llvm.lifetime.end.p0(ptr %i) #4
  br label %for.end19

for.body:                                         ; preds = %for.cond
  call void @llvm.lifetime.start.p0(ptr %j) #4
  store i32 0, ptr %j, align 4, !tbaa !16
  br label %for.cond1

for.cond1:                                        ; preds = %for.inc14, %for.body
  %2 = load i32, ptr %j, align 4, !tbaa !16
  %cmp2 = icmp slt i32 %2, 10
  br i1 %cmp2, label %for.body4, label %for.cond.cleanup3

for.cond.cleanup3:                                ; preds = %for.cond1
  store i32 5, ptr %cleanup.dest.slot, align 4
  call void @llvm.lifetime.end.p0(ptr %j) #4
  br label %for.end16

for.body4:                                        ; preds = %for.cond1
  call void @llvm.lifetime.start.p0(ptr %k) #4
  store i32 0, ptr %k, align 4, !tbaa !16
  br label %for.cond5

for.cond5:                                        ; preds = %for.inc, %for.body4
  %3 = load i32, ptr %k, align 4, !tbaa !16
  %cmp6 = icmp slt i32 %3, 10
  br i1 %cmp6, label %for.body8, label %for.cond.cleanup7

for.cond.cleanup7:                                ; preds = %for.cond5
  store i32 8, ptr %cleanup.dest.slot, align 4
  call void @llvm.lifetime.end.p0(ptr %k) #4
  br label %for.end

for.body8:                                        ; preds = %for.cond5
  %4 = load ptr, ptr %D3B.addr, align 8, !tbaa !13
  %5 = load i32, ptr %i, align 4, !tbaa !16
  %idxprom = sext i32 %5 to i64
  %arrayidx = getelementptr inbounds [10 x [10 x i32]], ptr %4, i64 %idxprom
  %6 = load i32, ptr %j, align 4, !tbaa !16
  %idxprom9 = sext i32 %6 to i64
  %arrayidx10 = getelementptr inbounds [10 x [10 x i32]], ptr %arrayidx, i64 0, i64 %idxprom9
  %7 = load i32, ptr %k, align 4, !tbaa !16
  %idxprom11 = sext i32 %7 to i64
  %arrayidx12 = getelementptr inbounds [10 x i32], ptr %arrayidx10, i64 0, i64 %idxprom11
  %8 = load i32, ptr %arrayidx12, align 4, !tbaa !16
  %inc = add nsw i32 %8, 1
  store i32 %inc, ptr %arrayidx12, align 4, !tbaa !16
  br label %for.inc

for.inc:                                          ; preds = %for.body8
  %9 = load i32, ptr %k, align 4, !tbaa !16
  %inc13 = add nsw i32 %9, 1
  store i32 %inc13, ptr %k, align 4, !tbaa !16
  br label %for.cond5, !llvm.loop !22

for.end:                                          ; preds = %for.cond.cleanup7
  br label %for.inc14

for.inc14:                                        ; preds = %for.end
  %10 = load i32, ptr %j, align 4, !tbaa !16
  %inc15 = add nsw i32 %10, 1
  store i32 %inc15, ptr %j, align 4, !tbaa !16
  br label %for.cond1, !llvm.loop !23

for.end16:                                        ; preds = %for.cond.cleanup3
  br label %for.inc17

for.inc17:                                        ; preds = %for.end16
  %11 = load i32, ptr %i, align 4, !tbaa !16
  %inc18 = add nsw i32 %11, 1
  store i32 %inc18, ptr %i, align 4, !tbaa !16
  br label %for.cond, !llvm.loop !24

for.end19:                                        ; preds = %for.cond.cleanup
  call void @llvm.lifetime.end.p0(ptr %D3B_dim2) #4
  call void @llvm.lifetime.end.p0(ptr %D3B_dim1) #4
  ret void
}

; Function Attrs: nounwind uwtable
define dso_local signext i32 @main() #0 {
entry:
  %retval = alloca i32, align 4
  %N1 = alloca i32, align 4
  %A1 = alloca ptr, align 8
  %D3B1 = alloca ptr, align 8
  %N2 = alloca i32, align 4
  %A2 = alloca ptr, align 8
  %D3B2 = alloca ptr, align 8
  store i32 0, ptr %retval, align 4
  call void @llvm.lifetime.start.p0(ptr %N1) #4
  store i32 50, ptr %N1, align 4, !tbaa !16
  call void @llvm.lifetime.start.p0(ptr %A1) #4
  %0 = load i32, ptr %N1, align 4, !tbaa !16
  %conv = sext i32 %0 to i64
  %call = call noalias ptr @calloc(i64 noundef %conv, i64 noundef 4) #5
  store ptr %call, ptr %A1, align 8, !tbaa !13
  call void @llvm.lifetime.start.p0(ptr %D3B1) #4
  %call1 = call noalias ptr @calloc(i64 noundef 10, i64 noundef 400) #5
  store ptr %call1, ptr %D3B1, align 8, !tbaa !13
  %1 = load ptr, ptr %A1, align 8, !tbaa !13
  %2 = load ptr, ptr %D3B1, align 8, !tbaa !13
  %3 = load i32, ptr %N1, align 4, !tbaa !16
  call void @pattern8_3d_fixed(ptr noundef %1, ptr noundef %2, i32 noundef signext %3)
  %4 = load ptr, ptr %A1, align 8, !tbaa !13
  call void @free(ptr noundef %4) #4
  %5 = load ptr, ptr %D3B1, align 8, !tbaa !13
  call void @free(ptr noundef %5) #4
  call void @llvm.lifetime.start.p0(ptr %N2) #4
  store i32 100, ptr %N2, align 4, !tbaa !16
  call void @llvm.lifetime.start.p0(ptr %A2) #4
  %6 = load i32, ptr %N2, align 4, !tbaa !16
  %conv2 = sext i32 %6 to i64
  %call3 = call noalias ptr @calloc(i64 noundef %conv2, i64 noundef 4) #5
  store ptr %call3, ptr %A2, align 8, !tbaa !13
  call void @llvm.lifetime.start.p0(ptr %D3B2) #4
  %call4 = call noalias ptr @calloc(i64 noundef 10, i64 noundef 400) #5
  store ptr %call4, ptr %D3B2, align 8, !tbaa !13
  %7 = load ptr, ptr %A2, align 8, !tbaa !13
  %8 = load ptr, ptr %D3B2, align 8, !tbaa !13
  %9 = load i32, ptr %N2, align 4, !tbaa !16
  call void @pattern8_3d_fixed(ptr noundef %7, ptr noundef %8, i32 noundef signext %9)
  %10 = load ptr, ptr %A2, align 8, !tbaa !13
  call void @free(ptr noundef %10) #4
  %11 = load ptr, ptr %D3B2, align 8, !tbaa !13
  call void @free(ptr noundef %11) #4
  call void @llvm.lifetime.end.p0(ptr %D3B2) #4
  call void @llvm.lifetime.end.p0(ptr %A2) #4
  call void @llvm.lifetime.end.p0(ptr %N2) #4
  call void @llvm.lifetime.end.p0(ptr %D3B1) #4
  call void @llvm.lifetime.end.p0(ptr %A1) #4
  call void @llvm.lifetime.end.p0(ptr %N1) #4
  ret i32 0
}

; Function Attrs: nounwind allocsize(0,1)
declare noalias ptr @calloc(i64 noundef, i64 noundef) #3

; Function Attrs: nounwind
declare void @free(ptr noundef) #2

attributes #0 = { nounwind uwtable "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="generic-rv64" "target-features"="+64bit,+a,+c,+d,+f,+i,+m,+relax,+zaamo,+zalrsc,+zca,+zcd,+zicsr,+zifencei,+zmmul,-b,-e,-experimental-p,-experimental-smpmpmt,-experimental-svukte,-experimental-xqccmt,-experimental-xsfmclic,-experimental-xsfsclic,-experimental-y,-experimental-zibi,-experimental-zicfilp,-experimental-zicfiss,-experimental-zvabd,-experimental-zvbc32e,-experimental-zvdot4a8i,-experimental-zvfbdota32f,-experimental-zvfbfa,-experimental-zvfofp8min,-experimental-zvfqwbdota8f,-experimental-zvfqwdota8f,-experimental-zvfwbdota16bf,-experimental-zvfwdota16bf,-experimental-zvkgs,-experimental-zvqwbdota16i,-experimental-zvqwbdota8i,-experimental-zvqwdota16i,-experimental-zvqwdota8i,-experimental-zvvfmm,-experimental-zvvmm,-experimental-zvvmtls,-experimental-zvvmttls,-experimental-zvzip,-h,-q,-sdext,-sdtrig,-sha,-shcounterenw,-shgatpa,-shlcofideleg,-shtvala,-shvsatpa,-shvstvala,-shvstvecd,-smaia,-smcdeleg,-smcntrpmf,-smcsrind,-smctr,-smdbltrp,-smepmp,-smmpm,-smnpm,-smrnmi,-smstateen,-ssaia,-ssccfg,-ssccptr,-sscofpmf,-sscounterenw,-sscsrind,-ssctr,-ssdbltrp,-ssnpm,-sspm,-ssqosid,-ssstateen,-ssstrict,-sstc,-sstvala,-sstvecd,-ssu64xl,-supm,-svade,-svadu,-svbare,-svinval,-svnapot,-svpbmt,-svrsw60t59b,-svvptc,-v,-xaifet,-xandesbfhcvt,-xandesperf,-xandesvbfhcvt,-xandesvdot,-xandesvpackfph,-xandesvsinth,-xandesvsintload,-xcheriot,-xcvalu,-xcvbi,-xcvbitmanip,-xcvelw,-xcvmac,-xcvmem,-xcvsimd,-xmipscbop,-xmipscmov,-xmipsexectl,-xmipslsp,-xqccmp,-xqci,-xqcia,-xqciac,-xqcibi,-xqcibm,-xqcicli,-xqcicm,-xqcics,-xqcicsr,-xqciint,-xqciio,-xqcilb,-xqcili,-xqcilia,-xqcilo,-xqcilsm,-xqcisim,-xqcisls,-xqcisync,-xsfcease,-xsfmm128t,-xsfmm16t,-xsfmm32a,-xsfmm32a16f,-xsfmm32a32f,-xsfmm32a8f,-xsfmm32a8i,-xsfmm32t,-xsfmm64a64f,-xsfmm64t,-xsfmmbase,-xsfvcp,-xsfvfbfexp16e,-xsfvfexp16e,-xsfvfexp32e,-xsfvfexpa,-xsfvfexpa64e,-xsfvfnrclipxfqf,-xsfvfwmaccqqq,-xsfvqmaccdod,-xsfvqmaccqoq,-xsifivecdiscarddlone,-xsifivecflushdlone,-xsmtvdot,-xsmtvdotii,-xtheadba,-xtheadbb,-xtheadbs,-xtheadcmo,-xtheadcondmov,-xtheadfmemidx,-xtheadmac,-xtheadmemidx,-xtheadmempair,-xtheadsync,-xtheadvdot,-xventanacondops,-xwchc,-za128rs,-za64rs,-zabha,-zacas,-zalasr,-zama16b,-zawrs,-zba,-zbb,-zbc,-zbkb,-zbkc,-zbkx,-zbs,-zcb,-zce,-zcf,-zclsd,-zcmop,-zcmp,-zcmt,-zdinx,-zfa,-zfbfmin,-zfh,-zfhmin,-zfinx,-zhinx,-zhinxmin,-zic64b,-zicbom,-zicbop,-zicboz,-ziccamoa,-ziccamoc,-ziccid,-ziccif,-zicclsm,-ziccrse,-zicntr,-zicond,-zihintntl,-zihintpause,-zihpm,-zilsd,-zimop,-zk,-zkn,-zknd,-zkne,-zknh,-zkr,-zks,-zksed,-zksh,-zkt,-ztso,-zvbb,-zvbc,-zve32f,-zve32x,-zve64d,-zve64f,-zve64x,-zvfbfmin,-zvfbfwma,-zvfh,-zvfhmin,-zvkb,-zvkg,-zvkn,-zvknc,-zvkned,-zvkng,-zvknha,-zvknhb,-zvks,-zvksc,-zvksed,-zvksg,-zvksh,-zvkt,-zvl1024b,-zvl128b,-zvl16384b,-zvl2048b,-zvl256b,-zvl32768b,-zvl32b,-zvl4096b,-zvl512b,-zvl64b,-zvl65536b,-zvl8192b" }
attributes #1 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { nounwind "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="generic-rv64" "target-features"="+64bit,+a,+c,+d,+f,+i,+m,+relax,+zaamo,+zalrsc,+zca,+zcd,+zicsr,+zifencei,+zmmul,-b,-e,-experimental-p,-experimental-smpmpmt,-experimental-svukte,-experimental-xqccmt,-experimental-xsfmclic,-experimental-xsfsclic,-experimental-y,-experimental-zibi,-experimental-zicfilp,-experimental-zicfiss,-experimental-zvabd,-experimental-zvbc32e,-experimental-zvdot4a8i,-experimental-zvfbdota32f,-experimental-zvfbfa,-experimental-zvfofp8min,-experimental-zvfqwbdota8f,-experimental-zvfqwdota8f,-experimental-zvfwbdota16bf,-experimental-zvfwdota16bf,-experimental-zvkgs,-experimental-zvqwbdota16i,-experimental-zvqwbdota8i,-experimental-zvqwdota16i,-experimental-zvqwdota8i,-experimental-zvvfmm,-experimental-zvvmm,-experimental-zvvmtls,-experimental-zvvmttls,-experimental-zvzip,-h,-q,-sdext,-sdtrig,-sha,-shcounterenw,-shgatpa,-shlcofideleg,-shtvala,-shvsatpa,-shvstvala,-shvstvecd,-smaia,-smcdeleg,-smcntrpmf,-smcsrind,-smctr,-smdbltrp,-smepmp,-smmpm,-smnpm,-smrnmi,-smstateen,-ssaia,-ssccfg,-ssccptr,-sscofpmf,-sscounterenw,-sscsrind,-ssctr,-ssdbltrp,-ssnpm,-sspm,-ssqosid,-ssstateen,-ssstrict,-sstc,-sstvala,-sstvecd,-ssu64xl,-supm,-svade,-svadu,-svbare,-svinval,-svnapot,-svpbmt,-svrsw60t59b,-svvptc,-v,-xaifet,-xandesbfhcvt,-xandesperf,-xandesvbfhcvt,-xandesvdot,-xandesvpackfph,-xandesvsinth,-xandesvsintload,-xcheriot,-xcvalu,-xcvbi,-xcvbitmanip,-xcvelw,-xcvmac,-xcvmem,-xcvsimd,-xmipscbop,-xmipscmov,-xmipsexectl,-xmipslsp,-xqccmp,-xqci,-xqcia,-xqciac,-xqcibi,-xqcibm,-xqcicli,-xqcicm,-xqcics,-xqcicsr,-xqciint,-xqciio,-xqcilb,-xqcili,-xqcilia,-xqcilo,-xqcilsm,-xqcisim,-xqcisls,-xqcisync,-xsfcease,-xsfmm128t,-xsfmm16t,-xsfmm32a,-xsfmm32a16f,-xsfmm32a32f,-xsfmm32a8f,-xsfmm32a8i,-xsfmm32t,-xsfmm64a64f,-xsfmm64t,-xsfmmbase,-xsfvcp,-xsfvfbfexp16e,-xsfvfexp16e,-xsfvfexp32e,-xsfvfexpa,-xsfvfexpa64e,-xsfvfnrclipxfqf,-xsfvfwmaccqqq,-xsfvqmaccdod,-xsfvqmaccqoq,-xsifivecdiscarddlone,-xsifivecflushdlone,-xsmtvdot,-xsmtvdotii,-xtheadba,-xtheadbb,-xtheadbs,-xtheadcmo,-xtheadcondmov,-xtheadfmemidx,-xtheadmac,-xtheadmemidx,-xtheadmempair,-xtheadsync,-xtheadvdot,-xventanacondops,-xwchc,-za128rs,-za64rs,-zabha,-zacas,-zalasr,-zama16b,-zawrs,-zba,-zbb,-zbc,-zbkb,-zbkc,-zbkx,-zbs,-zcb,-zce,-zcf,-zclsd,-zcmop,-zcmp,-zcmt,-zdinx,-zfa,-zfbfmin,-zfh,-zfhmin,-zfinx,-zhinx,-zhinxmin,-zic64b,-zicbom,-zicbop,-zicboz,-ziccamoa,-ziccamoc,-ziccid,-ziccif,-zicclsm,-ziccrse,-zicntr,-zicond,-zihintntl,-zihintpause,-zihpm,-zilsd,-zimop,-zk,-zkn,-zknd,-zkne,-zknh,-zkr,-zks,-zksed,-zksh,-zkt,-ztso,-zvbb,-zvbc,-zve32f,-zve32x,-zve64d,-zve64f,-zve64x,-zvfbfmin,-zvfbfwma,-zvfh,-zvfhmin,-zvkb,-zvkg,-zvkn,-zvknc,-zvkned,-zvkng,-zvknha,-zvknhb,-zvks,-zvksc,-zvksed,-zvksg,-zvksh,-zvkt,-zvl1024b,-zvl128b,-zvl16384b,-zvl2048b,-zvl256b,-zvl32768b,-zvl32b,-zvl4096b,-zvl512b,-zvl64b,-zvl65536b,-zvl8192b" }
attributes #3 = { nounwind allocsize(0,1) "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="generic-rv64" "target-features"="+64bit,+a,+c,+d,+f,+i,+m,+relax,+zaamo,+zalrsc,+zca,+zcd,+zicsr,+zifencei,+zmmul,-b,-e,-experimental-p,-experimental-smpmpmt,-experimental-svukte,-experimental-xqccmt,-experimental-xsfmclic,-experimental-xsfsclic,-experimental-y,-experimental-zibi,-experimental-zicfilp,-experimental-zicfiss,-experimental-zvabd,-experimental-zvbc32e,-experimental-zvdot4a8i,-experimental-zvfbdota32f,-experimental-zvfbfa,-experimental-zvfofp8min,-experimental-zvfqwbdota8f,-experimental-zvfqwdota8f,-experimental-zvfwbdota16bf,-experimental-zvfwdota16bf,-experimental-zvkgs,-experimental-zvqwbdota16i,-experimental-zvqwbdota8i,-experimental-zvqwdota16i,-experimental-zvqwdota8i,-experimental-zvvfmm,-experimental-zvvmm,-experimental-zvvmtls,-experimental-zvvmttls,-experimental-zvzip,-h,-q,-sdext,-sdtrig,-sha,-shcounterenw,-shgatpa,-shlcofideleg,-shtvala,-shvsatpa,-shvstvala,-shvstvecd,-smaia,-smcdeleg,-smcntrpmf,-smcsrind,-smctr,-smdbltrp,-smepmp,-smmpm,-smnpm,-smrnmi,-smstateen,-ssaia,-ssccfg,-ssccptr,-sscofpmf,-sscounterenw,-sscsrind,-ssctr,-ssdbltrp,-ssnpm,-sspm,-ssqosid,-ssstateen,-ssstrict,-sstc,-sstvala,-sstvecd,-ssu64xl,-supm,-svade,-svadu,-svbare,-svinval,-svnapot,-svpbmt,-svrsw60t59b,-svvptc,-v,-xaifet,-xandesbfhcvt,-xandesperf,-xandesvbfhcvt,-xandesvdot,-xandesvpackfph,-xandesvsinth,-xandesvsintload,-xcheriot,-xcvalu,-xcvbi,-xcvbitmanip,-xcvelw,-xcvmac,-xcvmem,-xcvsimd,-xmipscbop,-xmipscmov,-xmipsexectl,-xmipslsp,-xqccmp,-xqci,-xqcia,-xqciac,-xqcibi,-xqcibm,-xqcicli,-xqcicm,-xqcics,-xqcicsr,-xqciint,-xqciio,-xqcilb,-xqcili,-xqcilia,-xqcilo,-xqcilsm,-xqcisim,-xqcisls,-xqcisync,-xsfcease,-xsfmm128t,-xsfmm16t,-xsfmm32a,-xsfmm32a16f,-xsfmm32a32f,-xsfmm32a8f,-xsfmm32a8i,-xsfmm32t,-xsfmm64a64f,-xsfmm64t,-xsfmmbase,-xsfvcp,-xsfvfbfexp16e,-xsfvfexp16e,-xsfvfexp32e,-xsfvfexpa,-xsfvfexpa64e,-xsfvfnrclipxfqf,-xsfvfwmaccqqq,-xsfvqmaccdod,-xsfvqmaccqoq,-xsifivecdiscarddlone,-xsifivecflushdlone,-xsmtvdot,-xsmtvdotii,-xtheadba,-xtheadbb,-xtheadbs,-xtheadcmo,-xtheadcondmov,-xtheadfmemidx,-xtheadmac,-xtheadmemidx,-xtheadmempair,-xtheadsync,-xtheadvdot,-xventanacondops,-xwchc,-za128rs,-za64rs,-zabha,-zacas,-zalasr,-zama16b,-zawrs,-zba,-zbb,-zbc,-zbkb,-zbkc,-zbkx,-zbs,-zcb,-zce,-zcf,-zclsd,-zcmop,-zcmp,-zcmt,-zdinx,-zfa,-zfbfmin,-zfh,-zfhmin,-zfinx,-zhinx,-zhinxmin,-zic64b,-zicbom,-zicbop,-zicboz,-ziccamoa,-ziccamoc,-ziccid,-ziccif,-zicclsm,-ziccrse,-zicntr,-zicond,-zihintntl,-zihintpause,-zihpm,-zilsd,-zimop,-zk,-zkn,-zknd,-zkne,-zknh,-zkr,-zks,-zksed,-zksh,-zkt,-ztso,-zvbb,-zvbc,-zve32f,-zve32x,-zve64d,-zve64f,-zve64x,-zvfbfmin,-zvfbfwma,-zvfh,-zvfhmin,-zvkb,-zvkg,-zvkn,-zvknc,-zvkned,-zvkng,-zvknha,-zvknhb,-zvks,-zvksc,-zvksed,-zvksg,-zvksh,-zvkt,-zvl1024b,-zvl128b,-zvl16384b,-zvl2048b,-zvl256b,-zvl32768b,-zvl32b,-zvl4096b,-zvl512b,-zvl64b,-zvl65536b,-zvl8192b" }
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
!23 = distinct !{!23, !18, !19}
!24 = distinct !{!24, !18, !19}
