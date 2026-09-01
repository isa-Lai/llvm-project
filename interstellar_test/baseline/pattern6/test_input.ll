; ModuleID = 'pattern6_3d_pointer.c'
source_filename = "pattern6_3d_pointer.c"
target datalayout = "e-m:e-p:64:64-i64:64-i128:128-n32:64-S128"
target triple = "riscv64-unknown-linux-gnu"

; Function Attrs: nounwind uwtable
define dso_local void @pattern6_3d_pointer(ptr noundef %A, ptr noundef %D3A, i32 noundef signext %N, i32 noundef signext %D3_dim1, i32 noundef signext %D3_dim2, i32 noundef signext %D3_dim3) #0 {
entry:
  %A.addr = alloca ptr, align 8
  %D3A.addr = alloca ptr, align 8
  %N.addr = alloca i32, align 4
  %D3_dim1.addr = alloca i32, align 4
  %D3_dim2.addr = alloca i32, align 4
  %D3_dim3.addr = alloca i32, align 4
  %i = alloca i32, align 4
  %cleanup.dest.slot = alloca i32, align 4
  %j = alloca i32, align 4
  %k = alloca i32, align 4
  %idx = alloca i32, align 4
  %idx_i = alloca i32, align 4
  %indirect_idx = alloca i32, align 4
  %idx_j = alloca i32, align 4
  %idx_k = alloca i32, align 4
  %rand_i = alloca i32, align 4
  %rand_j = alloca i32, align 4
  %rand_k = alloca i32, align 4
  %rand_idx = alloca i32, align 4
  store ptr %A, ptr %A.addr, align 8, !tbaa !13
  store ptr %D3A, ptr %D3A.addr, align 8, !tbaa !13
  store i32 %N, ptr %N.addr, align 4, !tbaa !16
  store i32 %D3_dim1, ptr %D3_dim1.addr, align 4, !tbaa !16
  store i32 %D3_dim2, ptr %D3_dim2.addr, align 4, !tbaa !16
  store i32 %D3_dim3, ptr %D3_dim3.addr, align 4, !tbaa !16
  call void @llvm.lifetime.start.p0(ptr %i) #4
  store i32 0, ptr %i, align 4, !tbaa !16
  br label %for.cond

for.cond:                                         ; preds = %for.inc87, %entry
  %0 = load i32, ptr %i, align 4, !tbaa !16
  %1 = load i32, ptr %D3_dim1.addr, align 4, !tbaa !16
  %cmp = icmp slt i32 %0, %1
  br i1 %cmp, label %for.body, label %for.cond.cleanup

for.cond.cleanup:                                 ; preds = %for.cond
  store i32 2, ptr %cleanup.dest.slot, align 4
  call void @llvm.lifetime.end.p0(ptr %i) #4
  br label %for.end89

for.body:                                         ; preds = %for.cond
  call void @llvm.lifetime.start.p0(ptr %j) #4
  store i32 0, ptr %j, align 4, !tbaa !16
  br label %for.cond1

for.cond1:                                        ; preds = %for.inc84, %for.body
  %2 = load i32, ptr %j, align 4, !tbaa !16
  %3 = load i32, ptr %D3_dim2.addr, align 4, !tbaa !16
  %cmp2 = icmp slt i32 %2, %3
  br i1 %cmp2, label %for.body4, label %for.cond.cleanup3

for.cond.cleanup3:                                ; preds = %for.cond1
  store i32 5, ptr %cleanup.dest.slot, align 4
  call void @llvm.lifetime.end.p0(ptr %j) #4
  br label %for.end86

for.body4:                                        ; preds = %for.cond1
  call void @llvm.lifetime.start.p0(ptr %k) #4
  store i32 0, ptr %k, align 4, !tbaa !16
  br label %for.cond5

for.cond5:                                        ; preds = %for.inc, %for.body4
  %4 = load i32, ptr %k, align 4, !tbaa !16
  %5 = load i32, ptr %D3_dim3.addr, align 4, !tbaa !16
  %cmp6 = icmp slt i32 %4, %5
  br i1 %cmp6, label %for.body8, label %for.cond.cleanup7

for.cond.cleanup7:                                ; preds = %for.cond5
  store i32 8, ptr %cleanup.dest.slot, align 4
  call void @llvm.lifetime.end.p0(ptr %k) #4
  br label %for.end

for.body8:                                        ; preds = %for.cond5
  call void @llvm.lifetime.start.p0(ptr %idx) #4
  %6 = load i32, ptr %i, align 4, !tbaa !16
  %7 = load i32, ptr %D3_dim2.addr, align 4, !tbaa !16
  %mul = mul nsw i32 %6, %7
  %8 = load i32, ptr %D3_dim3.addr, align 4, !tbaa !16
  %mul9 = mul nsw i32 %mul, %8
  %9 = load i32, ptr %j, align 4, !tbaa !16
  %10 = load i32, ptr %D3_dim3.addr, align 4, !tbaa !16
  %mul10 = mul nsw i32 %9, %10
  %add = add nsw i32 %mul9, %mul10
  %11 = load i32, ptr %k, align 4, !tbaa !16
  %add11 = add nsw i32 %add, %11
  store i32 %add11, ptr %idx, align 4, !tbaa !16
  %12 = load ptr, ptr %D3A.addr, align 8, !tbaa !13
  %13 = load i32, ptr %idx, align 4, !tbaa !16
  %idxprom = sext i32 %13 to i64
  %arrayidx = getelementptr inbounds i32, ptr %12, i64 %idxprom
  %14 = load i32, ptr %arrayidx, align 4, !tbaa !16
  %inc = add nsw i32 %14, 1
  store i32 %inc, ptr %arrayidx, align 4, !tbaa !16
  %15 = load i32, ptr %i, align 4, !tbaa !16
  %16 = load i32, ptr %N.addr, align 4, !tbaa !16
  %cmp12 = icmp slt i32 %15, %16
  br i1 %cmp12, label %land.lhs.true, label %if.end

land.lhs.true:                                    ; preds = %for.body8
  %17 = load ptr, ptr %A.addr, align 8, !tbaa !13
  %18 = load i32, ptr %i, align 4, !tbaa !16
  %idxprom13 = sext i32 %18 to i64
  %arrayidx14 = getelementptr inbounds i32, ptr %17, i64 %idxprom13
  %19 = load i32, ptr %arrayidx14, align 4, !tbaa !16
  %cmp15 = icmp sge i32 %19, 0
  br i1 %cmp15, label %land.lhs.true16, label %if.end

land.lhs.true16:                                  ; preds = %land.lhs.true
  %20 = load ptr, ptr %A.addr, align 8, !tbaa !13
  %21 = load i32, ptr %i, align 4, !tbaa !16
  %idxprom17 = sext i32 %21 to i64
  %arrayidx18 = getelementptr inbounds i32, ptr %20, i64 %idxprom17
  %22 = load i32, ptr %arrayidx18, align 4, !tbaa !16
  %23 = load i32, ptr %D3_dim1.addr, align 4, !tbaa !16
  %cmp19 = icmp slt i32 %22, %23
  br i1 %cmp19, label %if.then, label %if.end

if.then:                                          ; preds = %land.lhs.true16
  call void @llvm.lifetime.start.p0(ptr %idx_i) #4
  %24 = load ptr, ptr %A.addr, align 8, !tbaa !13
  %25 = load i32, ptr %i, align 4, !tbaa !16
  %idxprom20 = sext i32 %25 to i64
  %arrayidx21 = getelementptr inbounds i32, ptr %24, i64 %idxprom20
  %26 = load i32, ptr %arrayidx21, align 4, !tbaa !16
  store i32 %26, ptr %idx_i, align 4, !tbaa !16
  call void @llvm.lifetime.start.p0(ptr %indirect_idx) #4
  %27 = load i32, ptr %idx_i, align 4, !tbaa !16
  %28 = load i32, ptr %D3_dim2.addr, align 4, !tbaa !16
  %mul22 = mul nsw i32 %27, %28
  %29 = load i32, ptr %D3_dim3.addr, align 4, !tbaa !16
  %mul23 = mul nsw i32 %mul22, %29
  %30 = load i32, ptr %j, align 4, !tbaa !16
  %31 = load i32, ptr %D3_dim3.addr, align 4, !tbaa !16
  %mul24 = mul nsw i32 %30, %31
  %add25 = add nsw i32 %mul23, %mul24
  %32 = load i32, ptr %k, align 4, !tbaa !16
  %add26 = add nsw i32 %add25, %32
  store i32 %add26, ptr %indirect_idx, align 4, !tbaa !16
  %33 = load ptr, ptr %D3A.addr, align 8, !tbaa !13
  %34 = load i32, ptr %indirect_idx, align 4, !tbaa !16
  %idxprom27 = sext i32 %34 to i64
  %arrayidx28 = getelementptr inbounds i32, ptr %33, i64 %idxprom27
  %35 = load i32, ptr %arrayidx28, align 4, !tbaa !16
  %inc29 = add nsw i32 %35, 1
  store i32 %inc29, ptr %arrayidx28, align 4, !tbaa !16
  call void @llvm.lifetime.start.p0(ptr %idx_j) #4
  %36 = load ptr, ptr %A.addr, align 8, !tbaa !13
  %37 = load i32, ptr %j, align 4, !tbaa !16
  %idxprom30 = sext i32 %37 to i64
  %arrayidx31 = getelementptr inbounds i32, ptr %36, i64 %idxprom30
  %38 = load i32, ptr %arrayidx31, align 4, !tbaa !16
  %39 = load i32, ptr %D3_dim2.addr, align 4, !tbaa !16
  %rem = srem i32 %38, %39
  store i32 %rem, ptr %idx_j, align 4, !tbaa !16
  %40 = load i32, ptr %i, align 4, !tbaa !16
  %41 = load i32, ptr %D3_dim2.addr, align 4, !tbaa !16
  %mul32 = mul nsw i32 %40, %41
  %42 = load i32, ptr %D3_dim3.addr, align 4, !tbaa !16
  %mul33 = mul nsw i32 %mul32, %42
  %43 = load i32, ptr %idx_j, align 4, !tbaa !16
  %44 = load i32, ptr %D3_dim3.addr, align 4, !tbaa !16
  %mul34 = mul nsw i32 %43, %44
  %add35 = add nsw i32 %mul33, %mul34
  %45 = load i32, ptr %k, align 4, !tbaa !16
  %add36 = add nsw i32 %add35, %45
  store i32 %add36, ptr %indirect_idx, align 4, !tbaa !16
  %46 = load ptr, ptr %D3A.addr, align 8, !tbaa !13
  %47 = load i32, ptr %indirect_idx, align 4, !tbaa !16
  %idxprom37 = sext i32 %47 to i64
  %arrayidx38 = getelementptr inbounds i32, ptr %46, i64 %idxprom37
  %48 = load i32, ptr %arrayidx38, align 4, !tbaa !16
  %inc39 = add nsw i32 %48, 1
  store i32 %inc39, ptr %arrayidx38, align 4, !tbaa !16
  call void @llvm.lifetime.start.p0(ptr %idx_k) #4
  %49 = load ptr, ptr %A.addr, align 8, !tbaa !13
  %50 = load i32, ptr %k, align 4, !tbaa !16
  %idxprom40 = sext i32 %50 to i64
  %arrayidx41 = getelementptr inbounds i32, ptr %49, i64 %idxprom40
  %51 = load i32, ptr %arrayidx41, align 4, !tbaa !16
  %52 = load i32, ptr %D3_dim3.addr, align 4, !tbaa !16
  %rem42 = srem i32 %51, %52
  store i32 %rem42, ptr %idx_k, align 4, !tbaa !16
  %53 = load i32, ptr %i, align 4, !tbaa !16
  %54 = load i32, ptr %D3_dim2.addr, align 4, !tbaa !16
  %mul43 = mul nsw i32 %53, %54
  %55 = load i32, ptr %D3_dim3.addr, align 4, !tbaa !16
  %mul44 = mul nsw i32 %mul43, %55
  %56 = load i32, ptr %j, align 4, !tbaa !16
  %57 = load i32, ptr %D3_dim3.addr, align 4, !tbaa !16
  %mul45 = mul nsw i32 %56, %57
  %add46 = add nsw i32 %mul44, %mul45
  %58 = load i32, ptr %idx_k, align 4, !tbaa !16
  %add47 = add nsw i32 %add46, %58
  store i32 %add47, ptr %indirect_idx, align 4, !tbaa !16
  %59 = load ptr, ptr %D3A.addr, align 8, !tbaa !13
  %60 = load i32, ptr %indirect_idx, align 4, !tbaa !16
  %idxprom48 = sext i32 %60 to i64
  %arrayidx49 = getelementptr inbounds i32, ptr %59, i64 %idxprom48
  %61 = load i32, ptr %arrayidx49, align 4, !tbaa !16
  %inc50 = add nsw i32 %61, 1
  store i32 %inc50, ptr %arrayidx49, align 4, !tbaa !16
  call void @llvm.lifetime.end.p0(ptr %idx_k) #4
  call void @llvm.lifetime.end.p0(ptr %idx_j) #4
  call void @llvm.lifetime.end.p0(ptr %indirect_idx) #4
  call void @llvm.lifetime.end.p0(ptr %idx_i) #4
  br label %if.end

if.end:                                           ; preds = %if.then, %land.lhs.true16, %land.lhs.true, %for.body8
  call void @llvm.lifetime.start.p0(ptr %rand_i) #4
  %call = call signext i32 @rand() #4
  %62 = load i32, ptr %D3_dim1.addr, align 4, !tbaa !16
  %rem51 = srem i32 %call, %62
  store i32 %rem51, ptr %rand_i, align 4, !tbaa !16
  call void @llvm.lifetime.start.p0(ptr %rand_j) #4
  %call52 = call signext i32 @rand() #4
  %63 = load i32, ptr %D3_dim2.addr, align 4, !tbaa !16
  %rem53 = srem i32 %call52, %63
  store i32 %rem53, ptr %rand_j, align 4, !tbaa !16
  call void @llvm.lifetime.start.p0(ptr %rand_k) #4
  %call54 = call signext i32 @rand() #4
  %64 = load i32, ptr %D3_dim3.addr, align 4, !tbaa !16
  %rem55 = srem i32 %call54, %64
  store i32 %rem55, ptr %rand_k, align 4, !tbaa !16
  call void @llvm.lifetime.start.p0(ptr %rand_idx) #4
  %65 = load i32, ptr %rand_i, align 4, !tbaa !16
  %66 = load i32, ptr %D3_dim2.addr, align 4, !tbaa !16
  %mul56 = mul nsw i32 %65, %66
  %67 = load i32, ptr %D3_dim3.addr, align 4, !tbaa !16
  %mul57 = mul nsw i32 %mul56, %67
  %68 = load i32, ptr %rand_j, align 4, !tbaa !16
  %69 = load i32, ptr %D3_dim3.addr, align 4, !tbaa !16
  %mul58 = mul nsw i32 %68, %69
  %add59 = add nsw i32 %mul57, %mul58
  %70 = load i32, ptr %rand_k, align 4, !tbaa !16
  %add60 = add nsw i32 %add59, %70
  store i32 %add60, ptr %rand_idx, align 4, !tbaa !16
  %71 = load ptr, ptr %D3A.addr, align 8, !tbaa !13
  %72 = load i32, ptr %rand_idx, align 4, !tbaa !16
  %inc61 = add nsw i32 %72, 1
  store i32 %inc61, ptr %rand_idx, align 4, !tbaa !16
  %idxprom62 = sext i32 %72 to i64
  %arrayidx63 = getelementptr inbounds i32, ptr %71, i64 %idxprom62
  %73 = load i32, ptr %arrayidx63, align 4, !tbaa !16
  %inc64 = add nsw i32 %73, 1
  store i32 %inc64, ptr %arrayidx63, align 4, !tbaa !16
  %74 = load i32, ptr %i, align 4, !tbaa !16
  %75 = load i32, ptr %D3_dim2.addr, align 4, !tbaa !16
  %mul65 = mul nsw i32 %74, %75
  %76 = load i32, ptr %D3_dim3.addr, align 4, !tbaa !16
  %mul66 = mul nsw i32 %mul65, %76
  %77 = load i32, ptr %rand_j, align 4, !tbaa !16
  %78 = load i32, ptr %D3_dim3.addr, align 4, !tbaa !16
  %mul67 = mul nsw i32 %77, %78
  %add68 = add nsw i32 %mul66, %mul67
  %79 = load i32, ptr %k, align 4, !tbaa !16
  %add69 = add nsw i32 %add68, %79
  store i32 %add69, ptr %rand_idx, align 4, !tbaa !16
  %80 = load ptr, ptr %D3A.addr, align 8, !tbaa !13
  %81 = load i32, ptr %rand_idx, align 4, !tbaa !16
  %inc70 = add nsw i32 %81, 1
  store i32 %inc70, ptr %rand_idx, align 4, !tbaa !16
  %idxprom71 = sext i32 %81 to i64
  %arrayidx72 = getelementptr inbounds i32, ptr %80, i64 %idxprom71
  %82 = load i32, ptr %arrayidx72, align 4, !tbaa !16
  %inc73 = add nsw i32 %82, 1
  store i32 %inc73, ptr %arrayidx72, align 4, !tbaa !16
  %83 = load i32, ptr %i, align 4, !tbaa !16
  %84 = load i32, ptr %D3_dim2.addr, align 4, !tbaa !16
  %mul74 = mul nsw i32 %83, %84
  %85 = load i32, ptr %D3_dim3.addr, align 4, !tbaa !16
  %mul75 = mul nsw i32 %mul74, %85
  %86 = load i32, ptr %j, align 4, !tbaa !16
  %87 = load i32, ptr %D3_dim3.addr, align 4, !tbaa !16
  %mul76 = mul nsw i32 %86, %87
  %add77 = add nsw i32 %mul75, %mul76
  %88 = load i32, ptr %rand_k, align 4, !tbaa !16
  %add78 = add nsw i32 %add77, %88
  store i32 %add78, ptr %rand_idx, align 4, !tbaa !16
  %89 = load ptr, ptr %D3A.addr, align 8, !tbaa !13
  %90 = load i32, ptr %rand_idx, align 4, !tbaa !16
  %inc79 = add nsw i32 %90, 1
  store i32 %inc79, ptr %rand_idx, align 4, !tbaa !16
  %idxprom80 = sext i32 %90 to i64
  %arrayidx81 = getelementptr inbounds i32, ptr %89, i64 %idxprom80
  %91 = load i32, ptr %arrayidx81, align 4, !tbaa !16
  %inc82 = add nsw i32 %91, 1
  store i32 %inc82, ptr %arrayidx81, align 4, !tbaa !16
  call void @llvm.lifetime.end.p0(ptr %rand_idx) #4
  call void @llvm.lifetime.end.p0(ptr %rand_k) #4
  call void @llvm.lifetime.end.p0(ptr %rand_j) #4
  call void @llvm.lifetime.end.p0(ptr %rand_i) #4
  call void @llvm.lifetime.end.p0(ptr %idx) #4
  br label %for.inc

for.inc:                                          ; preds = %if.end
  %92 = load i32, ptr %k, align 4, !tbaa !16
  %inc83 = add nsw i32 %92, 1
  store i32 %inc83, ptr %k, align 4, !tbaa !16
  br label %for.cond5, !llvm.loop !17

for.end:                                          ; preds = %for.cond.cleanup7
  br label %for.inc84

for.inc84:                                        ; preds = %for.end
  %93 = load i32, ptr %j, align 4, !tbaa !16
  %inc85 = add nsw i32 %93, 1
  store i32 %inc85, ptr %j, align 4, !tbaa !16
  br label %for.cond1, !llvm.loop !20

for.end86:                                        ; preds = %for.cond.cleanup3
  br label %for.inc87

for.inc87:                                        ; preds = %for.end86
  %94 = load i32, ptr %i, align 4, !tbaa !16
  %inc88 = add nsw i32 %94, 1
  store i32 %inc88, ptr %i, align 4, !tbaa !16
  br label %for.cond, !llvm.loop !21

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
  %A.addr = alloca ptr, align 8
  %D3A.addr = alloca ptr, align 8
  %N.addr = alloca i32, align 4
  %D3_dim1.addr = alloca i32, align 4
  %D3_dim2.addr = alloca i32, align 4
  %D3_dim3.addr = alloca i32, align 4
  %i = alloca i32, align 4
  %cleanup.dest.slot = alloca i32, align 4
  %j = alloca i32, align 4
  %k = alloca i32, align 4
  %idx = alloca i32, align 4
  store ptr %A, ptr %A.addr, align 8, !tbaa !13
  store ptr %D3A, ptr %D3A.addr, align 8, !tbaa !13
  store i32 %N, ptr %N.addr, align 4, !tbaa !16
  store i32 %D3_dim1, ptr %D3_dim1.addr, align 4, !tbaa !16
  store i32 %D3_dim2, ptr %D3_dim2.addr, align 4, !tbaa !16
  store i32 %D3_dim3, ptr %D3_dim3.addr, align 4, !tbaa !16
  call void @llvm.lifetime.start.p0(ptr %i) #4
  store i32 0, ptr %i, align 4, !tbaa !16
  br label %for.cond

for.cond:                                         ; preds = %for.inc16, %entry
  %0 = load i32, ptr %i, align 4, !tbaa !16
  %1 = load i32, ptr %D3_dim1.addr, align 4, !tbaa !16
  %cmp = icmp slt i32 %0, %1
  br i1 %cmp, label %for.body, label %for.cond.cleanup

for.cond.cleanup:                                 ; preds = %for.cond
  store i32 2, ptr %cleanup.dest.slot, align 4
  call void @llvm.lifetime.end.p0(ptr %i) #4
  br label %for.end18

for.body:                                         ; preds = %for.cond
  call void @llvm.lifetime.start.p0(ptr %j) #4
  store i32 0, ptr %j, align 4, !tbaa !16
  br label %for.cond1

for.cond1:                                        ; preds = %for.inc13, %for.body
  %2 = load i32, ptr %j, align 4, !tbaa !16
  %3 = load i32, ptr %D3_dim2.addr, align 4, !tbaa !16
  %sub = sub nsw i32 %3, 1
  %cmp2 = icmp slt i32 %2, %sub
  br i1 %cmp2, label %for.body4, label %for.cond.cleanup3

for.cond.cleanup3:                                ; preds = %for.cond1
  store i32 5, ptr %cleanup.dest.slot, align 4
  call void @llvm.lifetime.end.p0(ptr %j) #4
  br label %for.end15

for.body4:                                        ; preds = %for.cond1
  call void @llvm.lifetime.start.p0(ptr %k) #4
  store i32 0, ptr %k, align 4, !tbaa !16
  br label %for.cond5

for.cond5:                                        ; preds = %for.inc, %for.body4
  %4 = load i32, ptr %k, align 4, !tbaa !16
  %5 = load i32, ptr %D3_dim3.addr, align 4, !tbaa !16
  %cmp6 = icmp slt i32 %4, %5
  br i1 %cmp6, label %for.body8, label %for.cond.cleanup7

for.cond.cleanup7:                                ; preds = %for.cond5
  store i32 8, ptr %cleanup.dest.slot, align 4
  call void @llvm.lifetime.end.p0(ptr %k) #4
  br label %for.end

for.body8:                                        ; preds = %for.cond5
  call void @llvm.lifetime.start.p0(ptr %idx) #4
  %6 = load i32, ptr %i, align 4, !tbaa !16
  %7 = load i32, ptr %D3_dim2.addr, align 4, !tbaa !16
  %mul = mul nsw i32 %6, %7
  %8 = load i32, ptr %D3_dim3.addr, align 4, !tbaa !16
  %mul9 = mul nsw i32 %mul, %8
  %9 = load i32, ptr %j, align 4, !tbaa !16
  %10 = load i32, ptr %D3_dim3.addr, align 4, !tbaa !16
  %mul10 = mul nsw i32 %9, %10
  %add = add nsw i32 %mul9, %mul10
  %11 = load i32, ptr %k, align 4, !tbaa !16
  %add11 = add nsw i32 %add, %11
  store i32 %add11, ptr %idx, align 4, !tbaa !16
  %12 = load ptr, ptr %D3A.addr, align 8, !tbaa !13
  %13 = load i32, ptr %idx, align 4, !tbaa !16
  %idxprom = sext i32 %13 to i64
  %arrayidx = getelementptr inbounds i32, ptr %12, i64 %idxprom
  %14 = load i32, ptr %arrayidx, align 4, !tbaa !16
  %inc = add nsw i32 %14, 1
  store i32 %inc, ptr %arrayidx, align 4, !tbaa !16
  call void @llvm.lifetime.end.p0(ptr %idx) #4
  br label %for.inc

for.inc:                                          ; preds = %for.body8
  %15 = load i32, ptr %k, align 4, !tbaa !16
  %inc12 = add nsw i32 %15, 1
  store i32 %inc12, ptr %k, align 4, !tbaa !16
  br label %for.cond5, !llvm.loop !22

for.end:                                          ; preds = %for.cond.cleanup7
  br label %for.inc13

for.inc13:                                        ; preds = %for.end
  %16 = load i32, ptr %j, align 4, !tbaa !16
  %inc14 = add nsw i32 %16, 1
  store i32 %inc14, ptr %j, align 4, !tbaa !16
  br label %for.cond1, !llvm.loop !23

for.end15:                                        ; preds = %for.cond.cleanup3
  br label %for.inc16

for.inc16:                                        ; preds = %for.end15
  %17 = load i32, ptr %i, align 4, !tbaa !16
  %inc17 = add nsw i32 %17, 1
  store i32 %inc17, ptr %i, align 4, !tbaa !16
  br label %for.cond, !llvm.loop !24

for.end18:                                        ; preds = %for.cond.cleanup
  ret void
}

; Function Attrs: nounwind uwtable
define dso_local signext i32 @main() #0 {
entry:
  %retval = alloca i32, align 4
  %N1 = alloca i32, align 4
  %D3_dim1_1 = alloca i32, align 4
  %D3_dim2_1 = alloca i32, align 4
  %D3_dim3_1 = alloca i32, align 4
  %A1 = alloca ptr, align 8
  %D3A1 = alloca ptr, align 8
  %N2 = alloca i32, align 4
  %D3_dim1_2 = alloca i32, align 4
  %D3_dim2_2 = alloca i32, align 4
  %D3_dim3_2 = alloca i32, align 4
  %A2 = alloca ptr, align 8
  %D3A2 = alloca ptr, align 8
  store i32 0, ptr %retval, align 4
  call void @llvm.lifetime.start.p0(ptr %N1) #4
  store i32 15, ptr %N1, align 4, !tbaa !16
  call void @llvm.lifetime.start.p0(ptr %D3_dim1_1) #4
  store i32 8, ptr %D3_dim1_1, align 4, !tbaa !16
  call void @llvm.lifetime.start.p0(ptr %D3_dim2_1) #4
  store i32 10, ptr %D3_dim2_1, align 4, !tbaa !16
  call void @llvm.lifetime.start.p0(ptr %D3_dim3_1) #4
  store i32 12, ptr %D3_dim3_1, align 4, !tbaa !16
  call void @llvm.lifetime.start.p0(ptr %A1) #4
  %0 = load i32, ptr %N1, align 4, !tbaa !16
  %conv = sext i32 %0 to i64
  %call = call noalias ptr @calloc(i64 noundef %conv, i64 noundef 4) #5
  store ptr %call, ptr %A1, align 8, !tbaa !13
  call void @llvm.lifetime.start.p0(ptr %D3A1) #4
  %1 = load i32, ptr %D3_dim1_1, align 4, !tbaa !16
  %2 = load i32, ptr %D3_dim2_1, align 4, !tbaa !16
  %mul = mul nsw i32 %1, %2
  %3 = load i32, ptr %D3_dim3_1, align 4, !tbaa !16
  %mul1 = mul nsw i32 %mul, %3
  %conv2 = sext i32 %mul1 to i64
  %call3 = call noalias ptr @calloc(i64 noundef %conv2, i64 noundef 4) #5
  store ptr %call3, ptr %D3A1, align 8, !tbaa !13
  %4 = load ptr, ptr %A1, align 8, !tbaa !13
  %5 = load ptr, ptr %D3A1, align 8, !tbaa !13
  %6 = load i32, ptr %N1, align 4, !tbaa !16
  %7 = load i32, ptr %D3_dim1_1, align 4, !tbaa !16
  %8 = load i32, ptr %D3_dim2_1, align 4, !tbaa !16
  %9 = load i32, ptr %D3_dim3_1, align 4, !tbaa !16
  call void @pattern6_3d_pointer(ptr noundef %4, ptr noundef %5, i32 noundef signext %6, i32 noundef signext %7, i32 noundef signext %8, i32 noundef signext %9)
  %10 = load ptr, ptr %A1, align 8, !tbaa !13
  call void @free(ptr noundef %10) #4
  %11 = load ptr, ptr %D3A1, align 8, !tbaa !13
  call void @free(ptr noundef %11) #4
  call void @llvm.lifetime.start.p0(ptr %N2) #4
  store i32 20, ptr %N2, align 4, !tbaa !16
  call void @llvm.lifetime.start.p0(ptr %D3_dim1_2) #4
  store i32 10, ptr %D3_dim1_2, align 4, !tbaa !16
  call void @llvm.lifetime.start.p0(ptr %D3_dim2_2) #4
  store i32 12, ptr %D3_dim2_2, align 4, !tbaa !16
  call void @llvm.lifetime.start.p0(ptr %D3_dim3_2) #4
  store i32 15, ptr %D3_dim3_2, align 4, !tbaa !16
  call void @llvm.lifetime.start.p0(ptr %A2) #4
  %12 = load i32, ptr %N2, align 4, !tbaa !16
  %conv4 = sext i32 %12 to i64
  %call5 = call noalias ptr @calloc(i64 noundef %conv4, i64 noundef 4) #5
  store ptr %call5, ptr %A2, align 8, !tbaa !13
  call void @llvm.lifetime.start.p0(ptr %D3A2) #4
  %13 = load i32, ptr %D3_dim1_2, align 4, !tbaa !16
  %14 = load i32, ptr %D3_dim2_2, align 4, !tbaa !16
  %mul6 = mul nsw i32 %13, %14
  %15 = load i32, ptr %D3_dim3_2, align 4, !tbaa !16
  %mul7 = mul nsw i32 %mul6, %15
  %conv8 = sext i32 %mul7 to i64
  %call9 = call noalias ptr @calloc(i64 noundef %conv8, i64 noundef 4) #5
  store ptr %call9, ptr %D3A2, align 8, !tbaa !13
  %16 = load ptr, ptr %A2, align 8, !tbaa !13
  %17 = load ptr, ptr %D3A2, align 8, !tbaa !13
  %18 = load i32, ptr %N2, align 4, !tbaa !16
  %19 = load i32, ptr %D3_dim1_2, align 4, !tbaa !16
  %20 = load i32, ptr %D3_dim2_2, align 4, !tbaa !16
  %21 = load i32, ptr %D3_dim3_2, align 4, !tbaa !16
  call void @pattern6_3d_pointer(ptr noundef %16, ptr noundef %17, i32 noundef signext %18, i32 noundef signext %19, i32 noundef signext %20, i32 noundef signext %21)
  %22 = load ptr, ptr %A2, align 8, !tbaa !13
  call void @free(ptr noundef %22) #4
  %23 = load ptr, ptr %D3A2, align 8, !tbaa !13
  call void @free(ptr noundef %23) #4
  call void @llvm.lifetime.end.p0(ptr %D3A2) #4
  call void @llvm.lifetime.end.p0(ptr %A2) #4
  call void @llvm.lifetime.end.p0(ptr %D3_dim3_2) #4
  call void @llvm.lifetime.end.p0(ptr %D3_dim2_2) #4
  call void @llvm.lifetime.end.p0(ptr %D3_dim1_2) #4
  call void @llvm.lifetime.end.p0(ptr %N2) #4
  call void @llvm.lifetime.end.p0(ptr %D3A1) #4
  call void @llvm.lifetime.end.p0(ptr %A1) #4
  call void @llvm.lifetime.end.p0(ptr %D3_dim3_1) #4
  call void @llvm.lifetime.end.p0(ptr %D3_dim2_1) #4
  call void @llvm.lifetime.end.p0(ptr %D3_dim1_1) #4
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
