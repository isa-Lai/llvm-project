; ModuleID = 'patternA_loop_types.c'
source_filename = "patternA_loop_types.c"
target datalayout = "e-m:e-p:64:64-i64:64-i128:128-n32:64-S128"
target triple = "riscv64-unknown-linux-gnu"

@.str = private unnamed_addr constant [46 x i8] c"Final results: sum=%d, result=%d, counter=%d\0A\00", align 1

; Function Attrs: nounwind uwtable
define dso_local signext i32 @main(i32 noundef signext %argc, ptr noundef %argv) #0 {
entry:
  %retval = alloca i32, align 4
  %argc.addr = alloca i32, align 4
  %argv.addr = alloca ptr, align 8
  %seed = alloca i32, align 4
  %sum = alloca i32, align 4
  %result = alloca i32, align 4
  %counter = alloca i32, align 4
  %bound1 = alloca i32, align 4
  %bound2 = alloca i32, align 4
  %bound3 = alloca i32, align 4
  %i = alloca i32, align 4
  %i16 = alloca i32, align 4
  %j = alloca i32, align 4
  %bound_j = alloca i32, align 4
  %outer_bound = alloca i32, align 4
  %i39 = alloca i32, align 4
  %cleanup.dest.slot = alloca i32, align 4
  %inner_bound1 = alloca i32, align 4
  %j47 = alloca i32, align 4
  %k = alloca i32, align 4
  %i78 = alloca i32, align 4
  %bound_j84 = alloca i32, align 4
  %j87 = alloca i32, align 4
  %k93 = alloca i32, align 4
  %outer = alloca i32, align 4
  %while_bound = alloca i32, align 4
  %inner_bound = alloca i32, align 4
  %inner = alloca i32, align 4
  %p = alloca i32, align 4
  %q = alloca i32, align 4
  %i162 = alloca i32, align 4
  %m = alloca i32, align 4
  %i184 = alloca i32, align 4
  %j190 = alloca i32, align 4
  %k195 = alloca i32, align 4
  %i214 = alloca i32, align 4
  %bound_j220 = alloca i32, align 4
  %j223 = alloca i32, align 4
  %k236 = alloca i32, align 4
  %bound_m = alloca i32, align 4
  %m253 = alloca i32, align 4
  %break_bound = alloca i32, align 4
  %i273 = alloca i32, align 4
  %x = alloca i32, align 4
  %y = alloca i32, align 4
  %z = alloca i32, align 4
  %i326 = alloca i32, align 4
  %bound_j332 = alloca i32, align 4
  %j335 = alloca i32, align 4
  %k341 = alloca i32, align 4
  %m347 = alloca i32, align 4
  %i383 = alloca i32, align 4
  %j384 = alloca i32, align 4
  %bound_i = alloca i32, align 4
  %i403 = alloca i32, align 4
  %calc_i = alloca i32, align 4
  %bound_j411 = alloca i32, align 4
  %j414 = alloca i32, align 4
  %calc_j = alloca i32, align 4
  %outer2 = alloca i32, align 4
  %mid = alloca i32, align 4
  %inner2 = alloca i32, align 4
  %a = alloca i32, align 4
  %b = alloca i32, align 4
  %bound_c = alloca i32, align 4
  %c = alloca i32, align 4
  %d = alloca i32, align 4
  %e = alloca i32, align 4
  %w = alloca i32, align 4
  %v = alloca i32, align 4
  %u = alloca i32, align 4
  %start_offset = alloca i32, align 4
  %i560 = alloca i32, align 4
  %i575 = alloca i32, align 4
  %j581 = alloca i32, align 4
  %i603 = alloca i32, align 4
  %start_k = alloca i32, align 4
  %k610 = alloca i32, align 4
  %outer_limit = alloca i32, align 4
  %i631 = alloca i32, align 4
  %inner_start = alloca i32, align 4
  %inner_limit = alloca i32, align 4
  %j638 = alloca i32, align 4
  store i32 0, ptr %retval, align 4
  store i32 %argc, ptr %argc.addr, align 4, !tbaa !13
  store ptr %argv, ptr %argv.addr, align 8, !tbaa !14
  call void @llvm.lifetime.start.p0(ptr %seed) #5
  %0 = load i32, ptr %argc.addr, align 4, !tbaa !13
  %cmp = icmp sgt i32 %0, 1
  br i1 %cmp, label %cond.true, label %cond.false

cond.true:                                        ; preds = %entry
  %1 = load ptr, ptr %argv.addr, align 8, !tbaa !14
  %arrayidx = getelementptr inbounds ptr, ptr %1, i64 1
  %2 = load ptr, ptr %arrayidx, align 8, !tbaa !18
  %call = call signext i32 @atoi(ptr noundef %2) #6
  br label %cond.end

cond.false:                                       ; preds = %entry
  %call1 = call i64 @time(ptr noundef null) #5
  %conv = trunc i64 %call1 to i32
  br label %cond.end

cond.end:                                         ; preds = %cond.false, %cond.true
  %cond = phi i32 [ %call, %cond.true ], [ %conv, %cond.false ]
  store volatile i32 %cond, ptr %seed, align 4, !tbaa !13
  call void @llvm.lifetime.start.p0(ptr %sum) #5
  %3 = load volatile i32, ptr %seed, align 4, !tbaa !13
  store i32 %3, ptr %sum, align 4, !tbaa !13
  call void @llvm.lifetime.start.p0(ptr %result) #5
  %4 = load volatile i32, ptr %seed, align 4, !tbaa !13
  %rem = srem i32 %4, 100
  store i32 %rem, ptr %result, align 4, !tbaa !13
  call void @llvm.lifetime.start.p0(ptr %counter) #5
  %5 = load volatile i32, ptr %seed, align 4, !tbaa !13
  %rem2 = srem i32 %5, 50
  store i32 %rem2, ptr %counter, align 4, !tbaa !13
  call void @llvm.lifetime.start.p0(ptr %bound1) #5
  %6 = load volatile i32, ptr %seed, align 4, !tbaa !13
  %rem3 = srem i32 %6, 40
  %add = add nsw i32 80, %rem3
  store i32 %add, ptr %bound1, align 4, !tbaa !13
  call void @llvm.lifetime.start.p0(ptr %bound2) #5
  %7 = load volatile i32, ptr %seed, align 4, !tbaa !13
  %rem4 = srem i32 %7, 30
  %add5 = add nsw i32 50, %rem4
  store i32 %add5, ptr %bound2, align 4, !tbaa !13
  call void @llvm.lifetime.start.p0(ptr %bound3) #5
  %8 = load volatile i32, ptr %seed, align 4, !tbaa !13
  %rem6 = srem i32 %8, 20
  %add7 = add nsw i32 10, %rem6
  store i32 %add7, ptr %bound3, align 4, !tbaa !13
  call void @llvm.lifetime.start.p0(ptr %i) #5
  store i32 0, ptr %i, align 4, !tbaa !13
  br label %for.cond

for.cond:                                         ; preds = %for.inc, %cond.end
  %9 = load i32, ptr %i, align 4, !tbaa !13
  %10 = load i32, ptr %bound1, align 4, !tbaa !13
  %cmp8 = icmp slt i32 %9, %10
  br i1 %cmp8, label %for.body, label %for.cond.cleanup

for.cond.cleanup:                                 ; preds = %for.cond
  call void @llvm.lifetime.end.p0(ptr %i) #5
  br label %for.end

for.body:                                         ; preds = %for.cond
  %11 = load i32, ptr %i, align 4, !tbaa !13
  %12 = load i32, ptr %result, align 4, !tbaa !13
  %add10 = add nsw i32 %11, %12
  %13 = load i32, ptr %sum, align 4, !tbaa !13
  %add11 = add nsw i32 %13, %add10
  store i32 %add11, ptr %sum, align 4, !tbaa !13
  %14 = load i32, ptr %i, align 4, !tbaa !13
  %mul = mul nsw i32 %14, 2
  %add12 = add nsw i32 %mul, 3
  %15 = load i32, ptr %sum, align 4, !tbaa !13
  %add13 = add nsw i32 %add12, %15
  %rem14 = srem i32 %add13, 1000
  %16 = load i32, ptr %result, align 4, !tbaa !13
  %add15 = add nsw i32 %16, %rem14
  store i32 %add15, ptr %result, align 4, !tbaa !13
  br label %for.inc

for.inc:                                          ; preds = %for.body
  %17 = load i32, ptr %i, align 4, !tbaa !13
  %inc = add nsw i32 %17, 1
  store i32 %inc, ptr %i, align 4, !tbaa !13
  br label %for.cond, !llvm.loop !20

for.end:                                          ; preds = %for.cond.cleanup
  call void @llvm.lifetime.start.p0(ptr %i16) #5
  store i32 0, ptr %i16, align 4, !tbaa !13
  br label %while.cond

while.cond:                                       ; preds = %while.body, %for.end
  %18 = load i32, ptr %i16, align 4, !tbaa !13
  %19 = load i32, ptr %bound2, align 4, !tbaa !13
  %cmp17 = icmp slt i32 %18, %19
  br i1 %cmp17, label %while.body, label %while.end

while.body:                                       ; preds = %while.cond
  %20 = load i32, ptr %i16, align 4, !tbaa !13
  %mul19 = mul nsw i32 %20, 3
  %21 = load i32, ptr %result, align 4, !tbaa !13
  %add20 = add nsw i32 %mul19, %21
  %22 = load i32, ptr %counter, align 4, !tbaa !13
  %add21 = add nsw i32 %22, %add20
  store i32 %add21, ptr %counter, align 4, !tbaa !13
  %23 = load i32, ptr %counter, align 4, !tbaa !13
  %24 = load i32, ptr %sum, align 4, !tbaa !13
  %add22 = add nsw i32 %23, %24
  %rem23 = srem i32 %add22, 100
  %25 = load i32, ptr %result, align 4, !tbaa !13
  %add24 = add nsw i32 %25, %rem23
  store i32 %add24, ptr %result, align 4, !tbaa !13
  %26 = load i32, ptr %i16, align 4, !tbaa !13
  %add25 = add nsw i32 %26, 2
  store i32 %add25, ptr %i16, align 4, !tbaa !13
  br label %while.cond, !llvm.loop !23

while.end:                                        ; preds = %while.cond
  call void @llvm.lifetime.start.p0(ptr %j) #5
  store i32 0, ptr %j, align 4, !tbaa !13
  call void @llvm.lifetime.start.p0(ptr %bound_j) #5
  %27 = load i32, ptr %result, align 4, !tbaa !13
  %rem26 = srem i32 %27, 30
  %add27 = add nsw i32 60, %rem26
  store i32 %add27, ptr %bound_j, align 4, !tbaa !13
  br label %do.body

do.body:                                          ; preds = %do.cond, %while.end
  %28 = load i32, ptr %sum, align 4, !tbaa !13
  %29 = load i32, ptr %j, align 4, !tbaa !13
  %30 = load i32, ptr %j, align 4, !tbaa !13
  %mul28 = mul nsw i32 %29, %30
  %add29 = add nsw i32 %28, %mul28
  %31 = load i32, ptr %counter, align 4, !tbaa !13
  %add30 = add nsw i32 %add29, %31
  store i32 %add30, ptr %sum, align 4, !tbaa !13
  %32 = load i32, ptr %counter, align 4, !tbaa !13
  %33 = load i32, ptr %j, align 4, !tbaa !13
  %add31 = add nsw i32 %32, %33
  %34 = load i32, ptr %result, align 4, !tbaa !13
  %add32 = add nsw i32 %add31, %34
  %rem33 = srem i32 %add32, 200
  store i32 %rem33, ptr %counter, align 4, !tbaa !13
  %35 = load i32, ptr %j, align 4, !tbaa !13
  %add34 = add nsw i32 %35, 3
  store i32 %add34, ptr %j, align 4, !tbaa !13
  br label %do.cond

do.cond:                                          ; preds = %do.body
  %36 = load i32, ptr %j, align 4, !tbaa !13
  %37 = load i32, ptr %bound_j, align 4, !tbaa !13
  %cmp35 = icmp slt i32 %36, %37
  br i1 %cmp35, label %do.body, label %do.end, !llvm.loop !24

do.end:                                           ; preds = %do.cond
  call void @llvm.lifetime.start.p0(ptr %outer_bound) #5
  %38 = load i32, ptr %counter, align 4, !tbaa !13
  %rem37 = srem i32 %38, 10
  %add38 = add nsw i32 15, %rem37
  store i32 %add38, ptr %outer_bound, align 4, !tbaa !13
  call void @llvm.lifetime.start.p0(ptr %i39) #5
  store i32 0, ptr %i39, align 4, !tbaa !13
  br label %for.cond40

for.cond40:                                       ; preds = %for.inc75, %do.end
  %39 = load i32, ptr %i39, align 4, !tbaa !13
  %40 = load i32, ptr %outer_bound, align 4, !tbaa !13
  %cmp41 = icmp slt i32 %39, %40
  br i1 %cmp41, label %for.body44, label %for.cond.cleanup43

for.cond.cleanup43:                               ; preds = %for.cond40
  store i32 9, ptr %cleanup.dest.slot, align 4
  call void @llvm.lifetime.end.p0(ptr %i39) #5
  br label %for.end77

for.body44:                                       ; preds = %for.cond40
  call void @llvm.lifetime.start.p0(ptr %inner_bound1) #5
  %41 = load i32, ptr %i39, align 4, !tbaa !13
  %rem45 = srem i32 %41, 10
  %add46 = add nsw i32 15, %rem45
  store i32 %add46, ptr %inner_bound1, align 4, !tbaa !13
  call void @llvm.lifetime.start.p0(ptr %j47) #5
  store i32 0, ptr %j47, align 4, !tbaa !13
  br label %for.cond48

for.cond48:                                       ; preds = %for.inc57, %for.body44
  %42 = load i32, ptr %j47, align 4, !tbaa !13
  %43 = load i32, ptr %inner_bound1, align 4, !tbaa !13
  %cmp49 = icmp slt i32 %42, %43
  br i1 %cmp49, label %for.body52, label %for.cond.cleanup51

for.cond.cleanup51:                               ; preds = %for.cond48
  store i32 12, ptr %cleanup.dest.slot, align 4
  call void @llvm.lifetime.end.p0(ptr %j47) #5
  br label %for.end59

for.body52:                                       ; preds = %for.cond48
  %44 = load i32, ptr %i39, align 4, !tbaa !13
  %45 = load i32, ptr %j47, align 4, !tbaa !13
  %add53 = add nsw i32 %44, %45
  %46 = load i32, ptr %counter, align 4, !tbaa !13
  %add54 = add nsw i32 %add53, %46
  %47 = load i32, ptr %result, align 4, !tbaa !13
  %add55 = add nsw i32 %47, %add54
  store i32 %add55, ptr %result, align 4, !tbaa !13
  %48 = load i32, ptr %result, align 4, !tbaa !13
  %49 = load i32, ptr %sum, align 4, !tbaa !13
  %add56 = add nsw i32 %49, %48
  store i32 %add56, ptr %sum, align 4, !tbaa !13
  br label %for.inc57

for.inc57:                                        ; preds = %for.body52
  %50 = load i32, ptr %j47, align 4, !tbaa !13
  %inc58 = add nsw i32 %50, 1
  store i32 %inc58, ptr %j47, align 4, !tbaa !13
  br label %for.cond48, !llvm.loop !25

for.end59:                                        ; preds = %for.cond.cleanup51
  call void @llvm.lifetime.start.p0(ptr %k) #5
  store i32 0, ptr %k, align 4, !tbaa !13
  br label %for.cond60

for.cond60:                                       ; preds = %for.inc72, %for.end59
  %51 = load i32, ptr %k, align 4, !tbaa !13
  %cmp61 = icmp slt i32 %51, 15
  br i1 %cmp61, label %for.body64, label %for.cond.cleanup63

for.cond.cleanup63:                               ; preds = %for.cond60
  store i32 15, ptr %cleanup.dest.slot, align 4
  call void @llvm.lifetime.end.p0(ptr %k) #5
  br label %for.end74

for.body64:                                       ; preds = %for.cond60
  %52 = load i32, ptr %k, align 4, !tbaa !13
  %mul65 = mul nsw i32 %52, 2
  %53 = load i32, ptr %result, align 4, !tbaa !13
  %add66 = add nsw i32 %mul65, %53
  %54 = load i32, ptr %counter, align 4, !tbaa !13
  %add67 = add nsw i32 %54, %add66
  store i32 %add67, ptr %counter, align 4, !tbaa !13
  %55 = load i32, ptr %i39, align 4, !tbaa !13
  %56 = load i32, ptr %k, align 4, !tbaa !13
  %mul68 = mul nsw i32 %55, %56
  %57 = load i32, ptr %sum, align 4, !tbaa !13
  %add69 = add nsw i32 %mul68, %57
  %rem70 = srem i32 %add69, 500
  %58 = load i32, ptr %result, align 4, !tbaa !13
  %add71 = add nsw i32 %58, %rem70
  store i32 %add71, ptr %result, align 4, !tbaa !13
  br label %for.inc72

for.inc72:                                        ; preds = %for.body64
  %59 = load i32, ptr %k, align 4, !tbaa !13
  %add73 = add nsw i32 %59, 3
  store i32 %add73, ptr %k, align 4, !tbaa !13
  br label %for.cond60, !llvm.loop !26

for.end74:                                        ; preds = %for.cond.cleanup63
  call void @llvm.lifetime.end.p0(ptr %inner_bound1) #5
  br label %for.inc75

for.inc75:                                        ; preds = %for.end74
  %60 = load i32, ptr %i39, align 4, !tbaa !13
  %add76 = add nsw i32 %60, 2
  store i32 %add76, ptr %i39, align 4, !tbaa !13
  br label %for.cond40, !llvm.loop !27

for.end77:                                        ; preds = %for.cond.cleanup43
  call void @llvm.lifetime.start.p0(ptr %i78) #5
  store i32 0, ptr %i78, align 4, !tbaa !13
  br label %for.cond79

for.cond79:                                       ; preds = %for.inc117, %for.end77
  %61 = load i32, ptr %i78, align 4, !tbaa !13
  %cmp80 = icmp slt i32 %61, 10
  br i1 %cmp80, label %for.body83, label %for.cond.cleanup82

for.cond.cleanup82:                               ; preds = %for.cond79
  store i32 18, ptr %cleanup.dest.slot, align 4
  call void @llvm.lifetime.end.p0(ptr %i78) #5
  br label %for.end119

for.body83:                                       ; preds = %for.cond79
  call void @llvm.lifetime.start.p0(ptr %bound_j84) #5
  %62 = load i32, ptr %i78, align 4, !tbaa !13
  %rem85 = srem i32 %62, 5
  %add86 = add nsw i32 8, %rem85
  store i32 %add86, ptr %bound_j84, align 4, !tbaa !13
  call void @llvm.lifetime.start.p0(ptr %j87) #5
  store i32 0, ptr %j87, align 4, !tbaa !13
  br label %for.cond88

for.cond88:                                       ; preds = %for.inc114, %for.body83
  %63 = load i32, ptr %j87, align 4, !tbaa !13
  %64 = load i32, ptr %bound_j84, align 4, !tbaa !13
  %cmp89 = icmp slt i32 %63, %64
  br i1 %cmp89, label %for.body92, label %for.cond.cleanup91

for.cond.cleanup91:                               ; preds = %for.cond88
  store i32 21, ptr %cleanup.dest.slot, align 4
  call void @llvm.lifetime.end.p0(ptr %j87) #5
  br label %for.end116

for.body92:                                       ; preds = %for.cond88
  call void @llvm.lifetime.start.p0(ptr %k93) #5
  store i32 0, ptr %k93, align 4, !tbaa !13
  br label %for.cond94

for.cond94:                                       ; preds = %for.inc111, %for.body92
  %65 = load i32, ptr %k93, align 4, !tbaa !13
  %cmp95 = icmp slt i32 %65, 10
  br i1 %cmp95, label %for.body98, label %for.cond.cleanup97

for.cond.cleanup97:                               ; preds = %for.cond94
  store i32 24, ptr %cleanup.dest.slot, align 4
  call void @llvm.lifetime.end.p0(ptr %k93) #5
  br label %for.end113

for.body98:                                       ; preds = %for.cond94
  %66 = load i32, ptr %i78, align 4, !tbaa !13
  %mul99 = mul nsw i32 %66, 100
  %67 = load i32, ptr %j87, align 4, !tbaa !13
  %mul100 = mul nsw i32 %67, 10
  %add101 = add nsw i32 %mul99, %mul100
  %68 = load i32, ptr %k93, align 4, !tbaa !13
  %add102 = add nsw i32 %add101, %68
  %69 = load i32, ptr %sum, align 4, !tbaa !13
  %rem103 = srem i32 %69, 37
  %add104 = add nsw i32 %add102, %rem103
  %70 = load i32, ptr %result, align 4, !tbaa !13
  %add105 = add nsw i32 %70, %add104
  store i32 %add105, ptr %result, align 4, !tbaa !13
  %71 = load i32, ptr %sum, align 4, !tbaa !13
  %72 = load i32, ptr %result, align 4, !tbaa !13
  %add106 = add nsw i32 %71, %72
  %73 = load i32, ptr %counter, align 4, !tbaa !13
  %add107 = add nsw i32 %add106, %73
  %rem108 = srem i32 %add107, 10000
  store i32 %rem108, ptr %sum, align 4, !tbaa !13
  %74 = load i32, ptr %result, align 4, !tbaa !13
  %rem109 = srem i32 %74, 13
  %75 = load i32, ptr %counter, align 4, !tbaa !13
  %add110 = add nsw i32 %75, %rem109
  store i32 %add110, ptr %counter, align 4, !tbaa !13
  br label %for.inc111

for.inc111:                                       ; preds = %for.body98
  %76 = load i32, ptr %k93, align 4, !tbaa !13
  %add112 = add nsw i32 %76, 3
  store i32 %add112, ptr %k93, align 4, !tbaa !13
  br label %for.cond94, !llvm.loop !28

for.end113:                                       ; preds = %for.cond.cleanup97
  br label %for.inc114

for.inc114:                                       ; preds = %for.end113
  %77 = load i32, ptr %j87, align 4, !tbaa !13
  %add115 = add nsw i32 %77, 2
  store i32 %add115, ptr %j87, align 4, !tbaa !13
  br label %for.cond88, !llvm.loop !29

for.end116:                                       ; preds = %for.cond.cleanup91
  call void @llvm.lifetime.end.p0(ptr %bound_j84) #5
  br label %for.inc117

for.inc117:                                       ; preds = %for.end116
  %78 = load i32, ptr %i78, align 4, !tbaa !13
  %add118 = add nsw i32 %78, 1
  store i32 %add118, ptr %i78, align 4, !tbaa !13
  br label %for.cond79, !llvm.loop !30

for.end119:                                       ; preds = %for.cond.cleanup82
  call void @llvm.lifetime.start.p0(ptr %outer) #5
  store i32 0, ptr %outer, align 4, !tbaa !13
  call void @llvm.lifetime.start.p0(ptr %while_bound) #5
  %79 = load i32, ptr %sum, align 4, !tbaa !13
  %rem120 = srem i32 %79, 8
  %add121 = add nsw i32 12, %rem120
  store i32 %add121, ptr %while_bound, align 4, !tbaa !13
  br label %while.cond122

while.cond122:                                    ; preds = %for.end141, %for.end119
  %80 = load i32, ptr %outer, align 4, !tbaa !13
  %81 = load i32, ptr %while_bound, align 4, !tbaa !13
  %cmp123 = icmp slt i32 %80, %81
  br i1 %cmp123, label %while.body125, label %while.end143

while.body125:                                    ; preds = %while.cond122
  call void @llvm.lifetime.start.p0(ptr %inner_bound) #5
  %82 = load i32, ptr %outer, align 4, !tbaa !13
  %rem126 = srem i32 %82, 8
  %add127 = add nsw i32 10, %rem126
  store i32 %add127, ptr %inner_bound, align 4, !tbaa !13
  call void @llvm.lifetime.start.p0(ptr %inner) #5
  store i32 0, ptr %inner, align 4, !tbaa !13
  br label %for.cond128

for.cond128:                                      ; preds = %for.inc139, %while.body125
  %83 = load i32, ptr %inner, align 4, !tbaa !13
  %84 = load i32, ptr %inner_bound, align 4, !tbaa !13
  %cmp129 = icmp slt i32 %83, %84
  br i1 %cmp129, label %for.body132, label %for.cond.cleanup131

for.cond.cleanup131:                              ; preds = %for.cond128
  store i32 29, ptr %cleanup.dest.slot, align 4
  call void @llvm.lifetime.end.p0(ptr %inner) #5
  br label %for.end141

for.body132:                                      ; preds = %for.cond128
  %85 = load i32, ptr %outer, align 4, !tbaa !13
  %86 = load i32, ptr %inner, align 4, !tbaa !13
  %mul133 = mul nsw i32 %85, %86
  %87 = load i32, ptr %result, align 4, !tbaa !13
  %add134 = add nsw i32 %87, %mul133
  store i32 %add134, ptr %result, align 4, !tbaa !13
  %88 = load i32, ptr %result, align 4, !tbaa !13
  %89 = load i32, ptr %sum, align 4, !tbaa !13
  %add135 = add nsw i32 %89, %88
  store i32 %add135, ptr %sum, align 4, !tbaa !13
  %90 = load i32, ptr %counter, align 4, !tbaa !13
  %91 = load i32, ptr %outer, align 4, !tbaa !13
  %add136 = add nsw i32 %90, %91
  %92 = load i32, ptr %inner, align 4, !tbaa !13
  %add137 = add nsw i32 %add136, %92
  %rem138 = srem i32 %add137, 500
  store i32 %rem138, ptr %counter, align 4, !tbaa !13
  br label %for.inc139

for.inc139:                                       ; preds = %for.body132
  %93 = load i32, ptr %inner, align 4, !tbaa !13
  %add140 = add nsw i32 %93, 2
  store i32 %add140, ptr %inner, align 4, !tbaa !13
  br label %for.cond128, !llvm.loop !31

for.end141:                                       ; preds = %for.cond.cleanup131
  %94 = load i32, ptr %outer, align 4, !tbaa !13
  %add142 = add nsw i32 %94, 4
  store i32 %add142, ptr %outer, align 4, !tbaa !13
  call void @llvm.lifetime.end.p0(ptr %inner_bound) #5
  br label %while.cond122, !llvm.loop !32

while.end143:                                     ; preds = %while.cond122
  call void @llvm.lifetime.start.p0(ptr %p) #5
  store i32 0, ptr %p, align 4, !tbaa !13
  br label %do.body144

do.body144:                                       ; preds = %do.cond158, %while.end143
  call void @llvm.lifetime.start.p0(ptr %q) #5
  store i32 0, ptr %q, align 4, !tbaa !13
  br label %while.cond145

while.cond145:                                    ; preds = %while.body148, %do.body144
  %95 = load i32, ptr %q, align 4, !tbaa !13
  %cmp146 = icmp slt i32 %95, 10
  br i1 %cmp146, label %while.body148, label %while.end156

while.body148:                                    ; preds = %while.cond145
  %96 = load i32, ptr %p, align 4, !tbaa !13
  %97 = load i32, ptr %q, align 4, !tbaa !13
  %mul149 = mul nsw i32 %96, %97
  %98 = load i32, ptr %p, align 4, !tbaa !13
  %add150 = add nsw i32 %mul149, %98
  %99 = load i32, ptr %q, align 4, !tbaa !13
  %add151 = add nsw i32 %add150, %99
  %100 = load i32, ptr %result, align 4, !tbaa !13
  %add152 = add nsw i32 %100, %add151
  store i32 %add152, ptr %result, align 4, !tbaa !13
  %101 = load i32, ptr %sum, align 4, !tbaa !13
  %102 = load i32, ptr %result, align 4, !tbaa !13
  %add153 = add nsw i32 %101, %102
  %rem154 = srem i32 %add153, 1000
  store i32 %rem154, ptr %sum, align 4, !tbaa !13
  %103 = load i32, ptr %q, align 4, !tbaa !13
  %inc155 = add nsw i32 %103, 1
  store i32 %inc155, ptr %q, align 4, !tbaa !13
  br label %while.cond145, !llvm.loop !33

while.end156:                                     ; preds = %while.cond145
  %104 = load i32, ptr %p, align 4, !tbaa !13
  %inc157 = add nsw i32 %104, 1
  store i32 %inc157, ptr %p, align 4, !tbaa !13
  call void @llvm.lifetime.end.p0(ptr %q) #5
  br label %do.cond158

do.cond158:                                       ; preds = %while.end156
  %105 = load i32, ptr %p, align 4, !tbaa !13
  %cmp159 = icmp slt i32 %105, 20
  br i1 %cmp159, label %do.body144, label %do.end161, !llvm.loop !34

do.end161:                                        ; preds = %do.cond158
  call void @llvm.lifetime.start.p0(ptr %i162) #5
  store i32 0, ptr %i162, align 4, !tbaa !13
  br label %for.cond163

for.cond163:                                      ; preds = %for.inc181, %do.end161
  %106 = load i32, ptr %i162, align 4, !tbaa !13
  %cmp164 = icmp slt i32 %106, 30
  br i1 %cmp164, label %for.body167, label %for.cond.cleanup166

for.cond.cleanup166:                              ; preds = %for.cond163
  store i32 36, ptr %cleanup.dest.slot, align 4
  call void @llvm.lifetime.end.p0(ptr %i162) #5
  br label %for.end183

for.body167:                                      ; preds = %for.cond163
  call void @llvm.lifetime.start.p0(ptr %m) #5
  store i32 0, ptr %m, align 4, !tbaa !13
  br label %do.body168

do.body168:                                       ; preds = %do.cond177, %for.body167
  %107 = load i32, ptr %i162, align 4, !tbaa !13
  %108 = load i32, ptr %m, align 4, !tbaa !13
  %add169 = add nsw i32 %107, %108
  %109 = load i32, ptr %counter, align 4, !tbaa !13
  %add170 = add nsw i32 %109, %add169
  store i32 %add170, ptr %counter, align 4, !tbaa !13
  %110 = load i32, ptr %i162, align 4, !tbaa !13
  %111 = load i32, ptr %m, align 4, !tbaa !13
  %mul171 = mul nsw i32 %110, %111
  %112 = load i32, ptr %m, align 4, !tbaa !13
  %mul172 = mul nsw i32 %mul171, %112
  %113 = load i32, ptr %result, align 4, !tbaa !13
  %add173 = add nsw i32 %113, %mul172
  store i32 %add173, ptr %result, align 4, !tbaa !13
  %114 = load i32, ptr %sum, align 4, !tbaa !13
  %115 = load i32, ptr %result, align 4, !tbaa !13
  %add174 = add nsw i32 %114, %115
  %rem175 = srem i32 %add174, 2000
  store i32 %rem175, ptr %sum, align 4, !tbaa !13
  %116 = load i32, ptr %m, align 4, !tbaa !13
  %inc176 = add nsw i32 %116, 1
  store i32 %inc176, ptr %m, align 4, !tbaa !13
  br label %do.cond177

do.cond177:                                       ; preds = %do.body168
  %117 = load i32, ptr %m, align 4, !tbaa !13
  %cmp178 = icmp slt i32 %117, 8
  br i1 %cmp178, label %do.body168, label %do.end180, !llvm.loop !35

do.end180:                                        ; preds = %do.cond177
  call void @llvm.lifetime.end.p0(ptr %m) #5
  br label %for.inc181

for.inc181:                                       ; preds = %do.end180
  %118 = load i32, ptr %i162, align 4, !tbaa !13
  %inc182 = add nsw i32 %118, 1
  store i32 %inc182, ptr %i162, align 4, !tbaa !13
  br label %for.cond163, !llvm.loop !36

for.end183:                                       ; preds = %for.cond.cleanup166
  call void @llvm.lifetime.start.p0(ptr %i184) #5
  store i32 0, ptr %i184, align 4, !tbaa !13
  br label %for.cond185

for.cond185:                                      ; preds = %for.inc211, %for.end183
  %119 = load i32, ptr %i184, align 4, !tbaa !13
  %cmp186 = icmp slt i32 %119, 10
  br i1 %cmp186, label %for.body189, label %for.cond.cleanup188

for.cond.cleanup188:                              ; preds = %for.cond185
  store i32 41, ptr %cleanup.dest.slot, align 4
  call void @llvm.lifetime.end.p0(ptr %i184) #5
  br label %for.end213

for.body189:                                      ; preds = %for.cond185
  call void @llvm.lifetime.start.p0(ptr %j190) #5
  store i32 0, ptr %j190, align 4, !tbaa !13
  br label %while.cond191

while.cond191:                                    ; preds = %do.end208, %for.body189
  %120 = load i32, ptr %j190, align 4, !tbaa !13
  %cmp192 = icmp slt i32 %120, 10
  br i1 %cmp192, label %while.body194, label %while.end210

while.body194:                                    ; preds = %while.cond191
  call void @llvm.lifetime.start.p0(ptr %k195) #5
  store i32 0, ptr %k195, align 4, !tbaa !13
  br label %do.body196

do.body196:                                       ; preds = %do.cond205, %while.body194
  %121 = load i32, ptr %i184, align 4, !tbaa !13
  %122 = load i32, ptr %j190, align 4, !tbaa !13
  %add197 = add nsw i32 %121, %122
  %123 = load i32, ptr %k195, align 4, !tbaa !13
  %add198 = add nsw i32 %add197, %123
  %124 = load i32, ptr %result, align 4, !tbaa !13
  %add199 = add nsw i32 %124, %add198
  store i32 %add199, ptr %result, align 4, !tbaa !13
  %125 = load i32, ptr %result, align 4, !tbaa !13
  %126 = load i32, ptr %result, align 4, !tbaa !13
  %mul200 = mul nsw i32 %125, %126
  %127 = load i32, ptr %sum, align 4, !tbaa !13
  %add201 = add nsw i32 %127, %mul200
  store i32 %add201, ptr %sum, align 4, !tbaa !13
  %128 = load i32, ptr %counter, align 4, !tbaa !13
  %129 = load i32, ptr %result, align 4, !tbaa !13
  %add202 = add nsw i32 %128, %129
  %rem203 = srem i32 %add202, 300
  store i32 %rem203, ptr %counter, align 4, !tbaa !13
  %130 = load i32, ptr %k195, align 4, !tbaa !13
  %inc204 = add nsw i32 %130, 1
  store i32 %inc204, ptr %k195, align 4, !tbaa !13
  br label %do.cond205

do.cond205:                                       ; preds = %do.body196
  %131 = load i32, ptr %k195, align 4, !tbaa !13
  %cmp206 = icmp slt i32 %131, 5
  br i1 %cmp206, label %do.body196, label %do.end208, !llvm.loop !37

do.end208:                                        ; preds = %do.cond205
  %132 = load i32, ptr %j190, align 4, !tbaa !13
  %inc209 = add nsw i32 %132, 1
  store i32 %inc209, ptr %j190, align 4, !tbaa !13
  call void @llvm.lifetime.end.p0(ptr %k195) #5
  br label %while.cond191, !llvm.loop !38

while.end210:                                     ; preds = %while.cond191
  call void @llvm.lifetime.end.p0(ptr %j190) #5
  br label %for.inc211

for.inc211:                                       ; preds = %while.end210
  %133 = load i32, ptr %i184, align 4, !tbaa !13
  %inc212 = add nsw i32 %133, 1
  store i32 %inc212, ptr %i184, align 4, !tbaa !13
  br label %for.cond185, !llvm.loop !39

for.end213:                                       ; preds = %for.cond.cleanup188
  call void @llvm.lifetime.start.p0(ptr %i214) #5
  store i32 0, ptr %i214, align 4, !tbaa !13
  br label %for.cond215

for.cond215:                                      ; preds = %for.inc268, %for.end213
  %134 = load i32, ptr %i214, align 4, !tbaa !13
  %cmp216 = icmp slt i32 %134, 15
  br i1 %cmp216, label %for.body219, label %for.cond.cleanup218

for.cond.cleanup218:                              ; preds = %for.cond215
  store i32 48, ptr %cleanup.dest.slot, align 4
  call void @llvm.lifetime.end.p0(ptr %i214) #5
  br label %for.end270

for.body219:                                      ; preds = %for.cond215
  call void @llvm.lifetime.start.p0(ptr %bound_j220) #5
  %135 = load i32, ptr %i214, align 4, !tbaa !13
  %rem221 = srem i32 %135, 10
  %add222 = add nsw i32 15, %rem221
  store i32 %add222, ptr %bound_j220, align 4, !tbaa !13
  call void @llvm.lifetime.start.p0(ptr %j223) #5
  store i32 0, ptr %j223, align 4, !tbaa !13
  br label %for.cond224

for.cond224:                                      ; preds = %for.inc233, %for.body219
  %136 = load i32, ptr %j223, align 4, !tbaa !13
  %137 = load i32, ptr %bound_j220, align 4, !tbaa !13
  %cmp225 = icmp slt i32 %136, %137
  br i1 %cmp225, label %for.body228, label %for.cond.cleanup227

for.cond.cleanup227:                              ; preds = %for.cond224
  store i32 51, ptr %cleanup.dest.slot, align 4
  call void @llvm.lifetime.end.p0(ptr %j223) #5
  br label %for.end235

for.body228:                                      ; preds = %for.cond224
  %138 = load i32, ptr %i214, align 4, !tbaa !13
  %139 = load i32, ptr %j223, align 4, !tbaa !13
  %mul229 = mul nsw i32 %138, %139
  %140 = load i32, ptr %result, align 4, !tbaa !13
  %add230 = add nsw i32 %140, %mul229
  store i32 %add230, ptr %result, align 4, !tbaa !13
  %141 = load i32, ptr %sum, align 4, !tbaa !13
  %142 = load i32, ptr %result, align 4, !tbaa !13
  %add231 = add nsw i32 %141, %142
  %rem232 = srem i32 %add231, 5000
  store i32 %rem232, ptr %sum, align 4, !tbaa !13
  br label %for.inc233

for.inc233:                                       ; preds = %for.body228
  %143 = load i32, ptr %j223, align 4, !tbaa !13
  %add234 = add nsw i32 %143, 5
  store i32 %add234, ptr %j223, align 4, !tbaa !13
  br label %for.cond224, !llvm.loop !40

for.end235:                                       ; preds = %for.cond.cleanup227
  call void @llvm.lifetime.start.p0(ptr %k236) #5
  store i32 0, ptr %k236, align 4, !tbaa !13
  br label %for.cond237

for.cond237:                                      ; preds = %for.inc248, %for.end235
  %144 = load i32, ptr %k236, align 4, !tbaa !13
  %cmp238 = icmp slt i32 %144, 25
  br i1 %cmp238, label %for.body241, label %for.cond.cleanup240

for.cond.cleanup240:                              ; preds = %for.cond237
  store i32 54, ptr %cleanup.dest.slot, align 4
  call void @llvm.lifetime.end.p0(ptr %k236) #5
  br label %for.end250

for.body241:                                      ; preds = %for.cond237
  %145 = load i32, ptr %i214, align 4, !tbaa !13
  %146 = load i32, ptr %k236, align 4, !tbaa !13
  %add242 = add nsw i32 %145, %146
  %147 = load i32, ptr %counter, align 4, !tbaa !13
  %add243 = add nsw i32 %147, %add242
  store i32 %add243, ptr %counter, align 4, !tbaa !13
  %148 = load i32, ptr %i214, align 4, !tbaa !13
  %149 = load i32, ptr %k236, align 4, !tbaa !13
  %add244 = add nsw i32 %148, %149
  %150 = load i32, ptr %i214, align 4, !tbaa !13
  %151 = load i32, ptr %k236, align 4, !tbaa !13
  %sub = sub nsw i32 %150, %151
  %add245 = add nsw i32 %sub, 10
  %mul246 = mul nsw i32 %add244, %add245
  %152 = load i32, ptr %result, align 4, !tbaa !13
  %add247 = add nsw i32 %152, %mul246
  store i32 %add247, ptr %result, align 4, !tbaa !13
  br label %for.inc248

for.inc248:                                       ; preds = %for.body241
  %153 = load i32, ptr %k236, align 4, !tbaa !13
  %add249 = add nsw i32 %153, 7
  store i32 %add249, ptr %k236, align 4, !tbaa !13
  br label %for.cond237, !llvm.loop !41

for.end250:                                       ; preds = %for.cond.cleanup240
  call void @llvm.lifetime.start.p0(ptr %bound_m) #5
  %154 = load i32, ptr %counter, align 4, !tbaa !13
  %rem251 = srem i32 %154, 6
  %add252 = add nsw i32 8, %rem251
  store i32 %add252, ptr %bound_m, align 4, !tbaa !13
  call void @llvm.lifetime.start.p0(ptr %m253) #5
  store i32 0, ptr %m253, align 4, !tbaa !13
  br label %for.cond254

for.cond254:                                      ; preds = %for.inc265, %for.end250
  %155 = load i32, ptr %m253, align 4, !tbaa !13
  %156 = load i32, ptr %bound_m, align 4, !tbaa !13
  %cmp255 = icmp slt i32 %155, %156
  br i1 %cmp255, label %for.body258, label %for.cond.cleanup257

for.cond.cleanup257:                              ; preds = %for.cond254
  store i32 57, ptr %cleanup.dest.slot, align 4
  call void @llvm.lifetime.end.p0(ptr %m253) #5
  br label %for.end267

for.body258:                                      ; preds = %for.cond254
  %157 = load i32, ptr %i214, align 4, !tbaa !13
  %158 = load i32, ptr %m253, align 4, !tbaa !13
  %add259 = add nsw i32 %157, %158
  %159 = load i32, ptr %sum, align 4, !tbaa !13
  %add260 = add nsw i32 %159, %add259
  store i32 %add260, ptr %sum, align 4, !tbaa !13
  %160 = load i32, ptr %i214, align 4, !tbaa !13
  %161 = load i32, ptr %i214, align 4, !tbaa !13
  %mul261 = mul nsw i32 %160, %161
  %162 = load i32, ptr %m253, align 4, !tbaa !13
  %163 = load i32, ptr %m253, align 4, !tbaa !13
  %mul262 = mul nsw i32 %162, %163
  %add263 = add nsw i32 %mul261, %mul262
  %164 = load i32, ptr %result, align 4, !tbaa !13
  %add264 = add nsw i32 %164, %add263
  store i32 %add264, ptr %result, align 4, !tbaa !13
  br label %for.inc265

for.inc265:                                       ; preds = %for.body258
  %165 = load i32, ptr %m253, align 4, !tbaa !13
  %add266 = add nsw i32 %165, 2
  store i32 %add266, ptr %m253, align 4, !tbaa !13
  br label %for.cond254, !llvm.loop !42

for.end267:                                       ; preds = %for.cond.cleanup257
  call void @llvm.lifetime.end.p0(ptr %bound_m) #5
  call void @llvm.lifetime.end.p0(ptr %bound_j220) #5
  br label %for.inc268

for.inc268:                                       ; preds = %for.end267
  %166 = load i32, ptr %i214, align 4, !tbaa !13
  %inc269 = add nsw i32 %166, 1
  store i32 %inc269, ptr %i214, align 4, !tbaa !13
  br label %for.cond215, !llvm.loop !43

for.end270:                                       ; preds = %for.cond.cleanup218
  call void @llvm.lifetime.start.p0(ptr %break_bound) #5
  %167 = load i32, ptr %result, align 4, !tbaa !13
  %rem271 = srem i32 %167, 30
  %add272 = add nsw i32 50, %rem271
  store i32 %add272, ptr %break_bound, align 4, !tbaa !13
  call void @llvm.lifetime.start.p0(ptr %i273) #5
  store i32 0, ptr %i273, align 4, !tbaa !13
  br label %for.cond274

for.cond274:                                      ; preds = %for.inc290, %for.end270
  %168 = load i32, ptr %i273, align 4, !tbaa !13
  %cmp275 = icmp slt i32 %168, 100
  br i1 %cmp275, label %for.body278, label %for.cond.cleanup277

for.cond.cleanup277:                              ; preds = %for.cond274
  store i32 60, ptr %cleanup.dest.slot, align 4
  br label %cleanup

for.body278:                                      ; preds = %for.cond274
  %169 = load i32, ptr %i273, align 4, !tbaa !13
  %rem279 = srem i32 %169, 3
  %cmp280 = icmp eq i32 %rem279, 0
  br i1 %cmp280, label %if.then, label %if.end

if.then:                                          ; preds = %for.body278
  br label %for.inc290

if.end:                                           ; preds = %for.body278
  %170 = load i32, ptr %i273, align 4, !tbaa !13
  %mul282 = mul nsw i32 %170, 2
  %171 = load i32, ptr %result, align 4, !tbaa !13
  %add283 = add nsw i32 %171, %mul282
  store i32 %add283, ptr %result, align 4, !tbaa !13
  %172 = load i32, ptr %result, align 4, !tbaa !13
  %173 = load i32, ptr %sum, align 4, !tbaa !13
  %add284 = add nsw i32 %173, %172
  store i32 %add284, ptr %sum, align 4, !tbaa !13
  %174 = load i32, ptr %i273, align 4, !tbaa !13
  %175 = load i32, ptr %break_bound, align 4, !tbaa !13
  %cmp285 = icmp sgt i32 %174, %175
  br i1 %cmp285, label %if.then287, label %if.end288

if.then287:                                       ; preds = %if.end
  store i32 60, ptr %cleanup.dest.slot, align 4
  br label %cleanup

if.end288:                                        ; preds = %if.end
  %176 = load i32, ptr %counter, align 4, !tbaa !13
  %inc289 = add nsw i32 %176, 1
  store i32 %inc289, ptr %counter, align 4, !tbaa !13
  br label %for.inc290

for.inc290:                                       ; preds = %if.end288, %if.then
  %177 = load i32, ptr %i273, align 4, !tbaa !13
  %add291 = add nsw i32 %177, 6
  store i32 %add291, ptr %i273, align 4, !tbaa !13
  br label %for.cond274, !llvm.loop !44

cleanup:                                          ; preds = %if.then287, %for.cond.cleanup277
  call void @llvm.lifetime.end.p0(ptr %i273) #5
  br label %for.end292

for.end292:                                       ; preds = %cleanup
  call void @llvm.lifetime.start.p0(ptr %x) #5
  store i32 0, ptr %x, align 4, !tbaa !13
  br label %while.cond293

while.cond293:                                    ; preds = %while.end323, %for.end292
  %178 = load i32, ptr %x, align 4, !tbaa !13
  %cmp294 = icmp slt i32 %178, 30
  br i1 %cmp294, label %while.body296, label %while.end325

while.body296:                                    ; preds = %while.cond293
  call void @llvm.lifetime.start.p0(ptr %y) #5
  store i32 0, ptr %y, align 4, !tbaa !13
  br label %while.cond297

while.cond297:                                    ; preds = %for.end321, %while.body296
  %179 = load i32, ptr %y, align 4, !tbaa !13
  %cmp298 = icmp slt i32 %179, 30
  br i1 %cmp298, label %while.body300, label %while.end323

while.body300:                                    ; preds = %while.cond297
  %180 = load i32, ptr %x, align 4, !tbaa !13
  %mul301 = mul nsw i32 %180, 30
  %181 = load i32, ptr %y, align 4, !tbaa !13
  %add302 = add nsw i32 %mul301, %181
  %182 = load i32, ptr %result, align 4, !tbaa !13
  %add303 = add nsw i32 %182, %add302
  store i32 %add303, ptr %result, align 4, !tbaa !13
  %183 = load i32, ptr %sum, align 4, !tbaa !13
  %184 = load i32, ptr %result, align 4, !tbaa !13
  %add304 = add nsw i32 %183, %184
  %rem305 = srem i32 %add304, 3000
  store i32 %rem305, ptr %sum, align 4, !tbaa !13
  call void @llvm.lifetime.start.p0(ptr %z) #5
  store i32 0, ptr %z, align 4, !tbaa !13
  br label %for.cond306

for.cond306:                                      ; preds = %for.inc318, %while.body300
  %185 = load i32, ptr %z, align 4, !tbaa !13
  %cmp307 = icmp slt i32 %185, 5
  br i1 %cmp307, label %for.body310, label %for.cond.cleanup309

for.cond.cleanup309:                              ; preds = %for.cond306
  store i32 67, ptr %cleanup.dest.slot, align 4
  call void @llvm.lifetime.end.p0(ptr %z) #5
  br label %for.end321

for.body310:                                      ; preds = %for.cond306
  %186 = load i32, ptr %x, align 4, !tbaa !13
  %187 = load i32, ptr %y, align 4, !tbaa !13
  %add311 = add nsw i32 %186, %187
  %188 = load i32, ptr %z, align 4, !tbaa !13
  %add312 = add nsw i32 %add311, %188
  %189 = load i32, ptr %counter, align 4, !tbaa !13
  %add313 = add nsw i32 %189, %add312
  store i32 %add313, ptr %counter, align 4, !tbaa !13
  %190 = load i32, ptr %x, align 4, !tbaa !13
  %191 = load i32, ptr %y, align 4, !tbaa !13
  %mul314 = mul nsw i32 %190, %191
  %192 = load i32, ptr %z, align 4, !tbaa !13
  %mul315 = mul nsw i32 %mul314, %192
  %add316 = add nsw i32 %mul315, 1
  %193 = load i32, ptr %result, align 4, !tbaa !13
  %add317 = add nsw i32 %193, %add316
  store i32 %add317, ptr %result, align 4, !tbaa !13
  br label %for.inc318

for.inc318:                                       ; preds = %for.body310
  %194 = load i32, ptr %z, align 4, !tbaa !13
  %inc319 = add nsw i32 %194, 1
  store i32 %inc319, ptr %z, align 4, !tbaa !13
  br label %for.cond306, !llvm.loop !45

for.end321:                                       ; preds = %for.cond.cleanup309
  %195 = load i32, ptr %y, align 4, !tbaa !13
  %inc322 = add nsw i32 %195, 1
  store i32 %inc322, ptr %y, align 4, !tbaa !13
  br label %while.cond297, !llvm.loop !46

while.end323:                                     ; preds = %while.cond297
  %196 = load i32, ptr %x, align 4, !tbaa !13
  %inc324 = add nsw i32 %196, 1
  store i32 %inc324, ptr %x, align 4, !tbaa !13
  call void @llvm.lifetime.end.p0(ptr %y) #5
  br label %while.cond293, !llvm.loop !47

while.end325:                                     ; preds = %while.cond293
  call void @llvm.lifetime.start.p0(ptr %i326) #5
  store i32 0, ptr %i326, align 4, !tbaa !13
  br label %for.cond327

for.cond327:                                      ; preds = %for.inc379, %while.end325
  %197 = load i32, ptr %i326, align 4, !tbaa !13
  %cmp328 = icmp slt i32 %197, 5
  br i1 %cmp328, label %for.body331, label %for.cond.cleanup330

for.cond.cleanup330:                              ; preds = %for.cond327
  store i32 70, ptr %cleanup.dest.slot, align 4
  call void @llvm.lifetime.end.p0(ptr %i326) #5
  br label %for.end382

for.body331:                                      ; preds = %for.cond327
  call void @llvm.lifetime.start.p0(ptr %bound_j332) #5
  %198 = load i32, ptr %i326, align 4, !tbaa !13
  %rem333 = srem i32 %198, 3
  %add334 = add nsw i32 4, %rem333
  store i32 %add334, ptr %bound_j332, align 4, !tbaa !13
  call void @llvm.lifetime.start.p0(ptr %j335) #5
  store i32 0, ptr %j335, align 4, !tbaa !13
  br label %for.cond336

for.cond336:                                      ; preds = %for.inc375, %for.body331
  %199 = load i32, ptr %j335, align 4, !tbaa !13
  %200 = load i32, ptr %bound_j332, align 4, !tbaa !13
  %cmp337 = icmp slt i32 %199, %200
  br i1 %cmp337, label %for.body340, label %for.cond.cleanup339

for.cond.cleanup339:                              ; preds = %for.cond336
  store i32 73, ptr %cleanup.dest.slot, align 4
  call void @llvm.lifetime.end.p0(ptr %j335) #5
  br label %for.end378

for.body340:                                      ; preds = %for.cond336
  call void @llvm.lifetime.start.p0(ptr %k341) #5
  store i32 0, ptr %k341, align 4, !tbaa !13
  br label %for.cond342

for.cond342:                                      ; preds = %for.inc371, %for.body340
  %201 = load i32, ptr %k341, align 4, !tbaa !13
  %cmp343 = icmp slt i32 %201, 5
  br i1 %cmp343, label %for.body346, label %for.cond.cleanup345

for.cond.cleanup345:                              ; preds = %for.cond342
  store i32 76, ptr %cleanup.dest.slot, align 4
  call void @llvm.lifetime.end.p0(ptr %k341) #5
  br label %for.end374

for.body346:                                      ; preds = %for.cond342
  call void @llvm.lifetime.start.p0(ptr %m347) #5
  store i32 0, ptr %m347, align 4, !tbaa !13
  br label %for.cond348

for.cond348:                                      ; preds = %for.inc367, %for.body346
  %202 = load i32, ptr %m347, align 4, !tbaa !13
  %cmp349 = icmp slt i32 %202, 5
  br i1 %cmp349, label %for.body352, label %for.cond.cleanup351

for.cond.cleanup351:                              ; preds = %for.cond348
  store i32 79, ptr %cleanup.dest.slot, align 4
  call void @llvm.lifetime.end.p0(ptr %m347) #5
  br label %for.end370

for.body352:                                      ; preds = %for.cond348
  %203 = load i32, ptr %i326, align 4, !tbaa !13
  %mul353 = mul nsw i32 %203, 125
  %204 = load i32, ptr %j335, align 4, !tbaa !13
  %mul354 = mul nsw i32 %204, 25
  %add355 = add nsw i32 %mul353, %mul354
  %205 = load i32, ptr %k341, align 4, !tbaa !13
  %mul356 = mul nsw i32 %205, 5
  %add357 = add nsw i32 %add355, %mul356
  %206 = load i32, ptr %m347, align 4, !tbaa !13
  %add358 = add nsw i32 %add357, %206
  %207 = load i32, ptr %result, align 4, !tbaa !13
  %add359 = add nsw i32 %207, %add358
  store i32 %add359, ptr %result, align 4, !tbaa !13
  %208 = load i32, ptr %sum, align 4, !tbaa !13
  %209 = load i32, ptr %i326, align 4, !tbaa !13
  %add360 = add nsw i32 %208, %209
  %210 = load i32, ptr %j335, align 4, !tbaa !13
  %add361 = add nsw i32 %add360, %210
  %211 = load i32, ptr %k341, align 4, !tbaa !13
  %add362 = add nsw i32 %add361, %211
  %212 = load i32, ptr %m347, align 4, !tbaa !13
  %add363 = add nsw i32 %add362, %212
  %rem364 = srem i32 %add363, 4000
  store i32 %rem364, ptr %sum, align 4, !tbaa !13
  %213 = load i32, ptr %result, align 4, !tbaa !13
  %rem365 = srem i32 %213, 100
  %214 = load i32, ptr %counter, align 4, !tbaa !13
  %add366 = add nsw i32 %214, %rem365
  store i32 %add366, ptr %counter, align 4, !tbaa !13
  br label %for.inc367

for.inc367:                                       ; preds = %for.body352
  %215 = load i32, ptr %m347, align 4, !tbaa !13
  %add368 = add nsw i32 %215, 2
  store i32 %add368, ptr %m347, align 4, !tbaa !13
  br label %for.cond348, !llvm.loop !48

for.end370:                                       ; preds = %for.cond.cleanup351
  br label %for.inc371

for.inc371:                                       ; preds = %for.end370
  %216 = load i32, ptr %k341, align 4, !tbaa !13
  %inc372 = add nsw i32 %216, 1
  store i32 %inc372, ptr %k341, align 4, !tbaa !13
  br label %for.cond342, !llvm.loop !49

for.end374:                                       ; preds = %for.cond.cleanup345
  br label %for.inc375

for.inc375:                                       ; preds = %for.end374
  %217 = load i32, ptr %j335, align 4, !tbaa !13
  %add376 = add nsw i32 %217, 2
  store i32 %add376, ptr %j335, align 4, !tbaa !13
  br label %for.cond336, !llvm.loop !50

for.end378:                                       ; preds = %for.cond.cleanup339
  call void @llvm.lifetime.end.p0(ptr %bound_j332) #5
  br label %for.inc379

for.inc379:                                       ; preds = %for.end378
  %218 = load i32, ptr %i326, align 4, !tbaa !13
  %inc380 = add nsw i32 %218, 1
  store i32 %inc380, ptr %i326, align 4, !tbaa !13
  br label %for.cond327, !llvm.loop !51

for.end382:                                       ; preds = %for.cond.cleanup330
  call void @llvm.lifetime.start.p0(ptr %i383) #5
  store i32 0, ptr %i383, align 4, !tbaa !13
  call void @llvm.lifetime.start.p0(ptr %j384) #5
  store i32 100, ptr %j384, align 4, !tbaa !13
  br label %for.cond385

for.cond385:                                      ; preds = %for.inc396, %for.end382
  %219 = load i32, ptr %i383, align 4, !tbaa !13
  %220 = load i32, ptr %j384, align 4, !tbaa !13
  %cmp386 = icmp slt i32 %219, %220
  br i1 %cmp386, label %for.body389, label %for.cond.cleanup388

for.cond.cleanup388:                              ; preds = %for.cond385
  store i32 82, ptr %cleanup.dest.slot, align 4
  call void @llvm.lifetime.end.p0(ptr %j384) #5
  call void @llvm.lifetime.end.p0(ptr %i383) #5
  br label %for.end400

for.body389:                                      ; preds = %for.cond385
  %221 = load i32, ptr %i383, align 4, !tbaa !13
  %222 = load i32, ptr %j384, align 4, !tbaa !13
  %add390 = add nsw i32 %221, %222
  %223 = load i32, ptr %result, align 4, !tbaa !13
  %add391 = add nsw i32 %223, %add390
  store i32 %add391, ptr %result, align 4, !tbaa !13
  %224 = load i32, ptr %result, align 4, !tbaa !13
  %225 = load i32, ptr %sum, align 4, !tbaa !13
  %add392 = add nsw i32 %225, %224
  store i32 %add392, ptr %sum, align 4, !tbaa !13
  %226 = load i32, ptr %counter, align 4, !tbaa !13
  %227 = load i32, ptr %i383, align 4, !tbaa !13
  %add393 = add nsw i32 %226, %227
  %228 = load i32, ptr %j384, align 4, !tbaa !13
  %sub394 = sub nsw i32 %add393, %228
  %rem395 = srem i32 %sub394, 600
  store i32 %rem395, ptr %counter, align 4, !tbaa !13
  br label %for.inc396

for.inc396:                                       ; preds = %for.body389
  %229 = load i32, ptr %i383, align 4, !tbaa !13
  %inc397 = add nsw i32 %229, 1
  store i32 %inc397, ptr %i383, align 4, !tbaa !13
  %230 = load i32, ptr %j384, align 4, !tbaa !13
  %dec = add nsw i32 %230, -1
  store i32 %dec, ptr %j384, align 4, !tbaa !13
  br label %for.cond385, !llvm.loop !52

for.end400:                                       ; preds = %for.cond.cleanup388
  call void @llvm.lifetime.start.p0(ptr %bound_i) #5
  %231 = load i32, ptr %counter, align 4, !tbaa !13
  %rem401 = srem i32 %231, 10
  %add402 = add nsw i32 15, %rem401
  store i32 %add402, ptr %bound_i, align 4, !tbaa !13
  call void @llvm.lifetime.start.p0(ptr %i403) #5
  store i32 0, ptr %i403, align 4, !tbaa !13
  br label %for.cond404

for.cond404:                                      ; preds = %for.inc432, %for.end400
  %232 = load i32, ptr %i403, align 4, !tbaa !13
  %233 = load i32, ptr %bound_i, align 4, !tbaa !13
  %cmp405 = icmp slt i32 %232, %233
  br i1 %cmp405, label %for.body408, label %for.cond.cleanup407

for.cond.cleanup407:                              ; preds = %for.cond404
  store i32 85, ptr %cleanup.dest.slot, align 4
  call void @llvm.lifetime.end.p0(ptr %i403) #5
  br label %for.end435

for.body408:                                      ; preds = %for.cond404
  call void @llvm.lifetime.start.p0(ptr %calc_i) #5
  %234 = load i32, ptr %i403, align 4, !tbaa !13
  %mul409 = mul nsw i32 %234, 7
  %rem410 = srem i32 %mul409, 30
  store i32 %rem410, ptr %calc_i, align 4, !tbaa !13
  call void @llvm.lifetime.start.p0(ptr %bound_j411) #5
  %235 = load i32, ptr %i403, align 4, !tbaa !13
  %rem412 = srem i32 %235, 12
  %add413 = add nsw i32 12, %rem412
  store i32 %add413, ptr %bound_j411, align 4, !tbaa !13
  call void @llvm.lifetime.start.p0(ptr %j414) #5
  store i32 0, ptr %j414, align 4, !tbaa !13
  br label %for.cond415

for.cond415:                                      ; preds = %for.inc428, %for.body408
  %236 = load i32, ptr %j414, align 4, !tbaa !13
  %237 = load i32, ptr %bound_j411, align 4, !tbaa !13
  %cmp416 = icmp slt i32 %236, %237
  br i1 %cmp416, label %for.body419, label %for.cond.cleanup418

for.cond.cleanup418:                              ; preds = %for.cond415
  store i32 88, ptr %cleanup.dest.slot, align 4
  call void @llvm.lifetime.end.p0(ptr %j414) #5
  br label %for.end431

for.body419:                                      ; preds = %for.cond415
  call void @llvm.lifetime.start.p0(ptr %calc_j) #5
  %238 = load i32, ptr %j414, align 4, !tbaa !13
  %mul420 = mul nsw i32 %238, 11
  %rem421 = srem i32 %mul420, 30
  store i32 %rem421, ptr %calc_j, align 4, !tbaa !13
  %239 = load i32, ptr %calc_i, align 4, !tbaa !13
  %240 = load i32, ptr %calc_j, align 4, !tbaa !13
  %mul422 = mul nsw i32 %239, %240
  %241 = load i32, ptr %result, align 4, !tbaa !13
  %add423 = add nsw i32 %241, %mul422
  store i32 %add423, ptr %result, align 4, !tbaa !13
  %242 = load i32, ptr %sum, align 4, !tbaa !13
  %243 = load i32, ptr %result, align 4, !tbaa !13
  %add424 = add nsw i32 %242, %243
  %rem425 = srem i32 %add424, 8000
  store i32 %rem425, ptr %sum, align 4, !tbaa !13
  %244 = load i32, ptr %calc_i, align 4, !tbaa !13
  %245 = load i32, ptr %calc_j, align 4, !tbaa !13
  %add426 = add nsw i32 %244, %245
  %246 = load i32, ptr %counter, align 4, !tbaa !13
  %add427 = add nsw i32 %246, %add426
  store i32 %add427, ptr %counter, align 4, !tbaa !13
  call void @llvm.lifetime.end.p0(ptr %calc_j) #5
  br label %for.inc428

for.inc428:                                       ; preds = %for.body419
  %247 = load i32, ptr %j414, align 4, !tbaa !13
  %add429 = add nsw i32 %247, 4
  store i32 %add429, ptr %j414, align 4, !tbaa !13
  br label %for.cond415, !llvm.loop !53

for.end431:                                       ; preds = %for.cond.cleanup418
  call void @llvm.lifetime.end.p0(ptr %bound_j411) #5
  call void @llvm.lifetime.end.p0(ptr %calc_i) #5
  br label %for.inc432

for.inc432:                                       ; preds = %for.end431
  %248 = load i32, ptr %i403, align 4, !tbaa !13
  %add433 = add nsw i32 %248, 3
  store i32 %add433, ptr %i403, align 4, !tbaa !13
  br label %for.cond404, !llvm.loop !54

for.end435:                                       ; preds = %for.cond.cleanup407
  call void @llvm.lifetime.start.p0(ptr %outer2) #5
  store i32 0, ptr %outer2, align 4, !tbaa !13
  br label %do.body436

do.body436:                                       ; preds = %do.cond460, %for.end435
  call void @llvm.lifetime.start.p0(ptr %mid) #5
  store i32 0, ptr %mid, align 4, !tbaa !13
  br label %for.cond437

for.cond437:                                      ; preds = %for.inc455, %do.body436
  %249 = load i32, ptr %mid, align 4, !tbaa !13
  %cmp438 = icmp slt i32 %249, 10
  br i1 %cmp438, label %for.body441, label %for.cond.cleanup440

for.cond.cleanup440:                              ; preds = %for.cond437
  store i32 93, ptr %cleanup.dest.slot, align 4
  call void @llvm.lifetime.end.p0(ptr %mid) #5
  br label %for.end458

for.body441:                                      ; preds = %for.cond437
  call void @llvm.lifetime.start.p0(ptr %inner2) #5
  store i32 0, ptr %inner2, align 4, !tbaa !13
  br label %while.cond442

while.cond442:                                    ; preds = %while.body445, %for.body441
  %250 = load i32, ptr %inner2, align 4, !tbaa !13
  %cmp443 = icmp slt i32 %250, 10
  br i1 %cmp443, label %while.body445, label %while.end454

while.body445:                                    ; preds = %while.cond442
  %251 = load i32, ptr %outer2, align 4, !tbaa !13
  %252 = load i32, ptr %mid, align 4, !tbaa !13
  %add446 = add nsw i32 %251, %252
  %253 = load i32, ptr %inner2, align 4, !tbaa !13
  %add447 = add nsw i32 %add446, %253
  %254 = load i32, ptr %result, align 4, !tbaa !13
  %add448 = add nsw i32 %254, %add447
  store i32 %add448, ptr %result, align 4, !tbaa !13
  %255 = load i32, ptr %result, align 4, !tbaa !13
  %256 = load i32, ptr %sum, align 4, !tbaa !13
  %add449 = add nsw i32 %256, %255
  store i32 %add449, ptr %sum, align 4, !tbaa !13
  %257 = load i32, ptr %counter, align 4, !tbaa !13
  %258 = load i32, ptr %result, align 4, !tbaa !13
  %259 = load i32, ptr %result, align 4, !tbaa !13
  %mul450 = mul nsw i32 %258, %259
  %add451 = add nsw i32 %257, %mul450
  %rem452 = srem i32 %add451, 1500
  store i32 %rem452, ptr %counter, align 4, !tbaa !13
  %260 = load i32, ptr %inner2, align 4, !tbaa !13
  %inc453 = add nsw i32 %260, 1
  store i32 %inc453, ptr %inner2, align 4, !tbaa !13
  br label %while.cond442, !llvm.loop !55

while.end454:                                     ; preds = %while.cond442
  call void @llvm.lifetime.end.p0(ptr %inner2) #5
  br label %for.inc455

for.inc455:                                       ; preds = %while.end454
  %261 = load i32, ptr %mid, align 4, !tbaa !13
  %inc456 = add nsw i32 %261, 1
  store i32 %inc456, ptr %mid, align 4, !tbaa !13
  br label %for.cond437, !llvm.loop !56

for.end458:                                       ; preds = %for.cond.cleanup440
  %262 = load i32, ptr %outer2, align 4, !tbaa !13
  %inc459 = add nsw i32 %262, 1
  store i32 %inc459, ptr %outer2, align 4, !tbaa !13
  br label %do.cond460

do.cond460:                                       ; preds = %for.end458
  %263 = load i32, ptr %outer2, align 4, !tbaa !13
  %cmp461 = icmp slt i32 %263, 50
  br i1 %cmp461, label %do.body436, label %do.end463, !llvm.loop !57

do.end463:                                        ; preds = %do.cond460
  call void @llvm.lifetime.start.p0(ptr %a) #5
  store i32 0, ptr %a, align 4, !tbaa !13
  br label %for.cond464

for.cond464:                                      ; preds = %for.inc520, %do.end463
  %264 = load i32, ptr %a, align 4, !tbaa !13
  %cmp465 = icmp slt i32 %264, 3
  br i1 %cmp465, label %for.body468, label %for.cond.cleanup467

for.cond.cleanup467:                              ; preds = %for.cond464
  store i32 98, ptr %cleanup.dest.slot, align 4
  call void @llvm.lifetime.end.p0(ptr %a) #5
  br label %for.end523

for.body468:                                      ; preds = %for.cond464
  call void @llvm.lifetime.start.p0(ptr %b) #5
  store i32 0, ptr %b, align 4, !tbaa !13
  br label %for.cond469

for.cond469:                                      ; preds = %for.inc516, %for.body468
  %265 = load i32, ptr %b, align 4, !tbaa !13
  %cmp470 = icmp slt i32 %265, 3
  br i1 %cmp470, label %for.body473, label %for.cond.cleanup472

for.cond.cleanup472:                              ; preds = %for.cond469
  store i32 101, ptr %cleanup.dest.slot, align 4
  call void @llvm.lifetime.end.p0(ptr %b) #5
  br label %for.end519

for.body473:                                      ; preds = %for.cond469
  call void @llvm.lifetime.start.p0(ptr %bound_c) #5
  %266 = load i32, ptr %a, align 4, !tbaa !13
  %rem474 = srem i32 %266, 2
  %add475 = add nsw i32 2, %rem474
  store i32 %add475, ptr %bound_c, align 4, !tbaa !13
  call void @llvm.lifetime.start.p0(ptr %c) #5
  store i32 0, ptr %c, align 4, !tbaa !13
  br label %for.cond476

for.cond476:                                      ; preds = %for.inc512, %for.body473
  %267 = load i32, ptr %c, align 4, !tbaa !13
  %268 = load i32, ptr %bound_c, align 4, !tbaa !13
  %cmp477 = icmp slt i32 %267, %268
  br i1 %cmp477, label %for.body480, label %for.cond.cleanup479

for.cond.cleanup479:                              ; preds = %for.cond476
  store i32 104, ptr %cleanup.dest.slot, align 4
  call void @llvm.lifetime.end.p0(ptr %c) #5
  br label %for.end515

for.body480:                                      ; preds = %for.cond476
  call void @llvm.lifetime.start.p0(ptr %d) #5
  store i32 0, ptr %d, align 4, !tbaa !13
  br label %for.cond481

for.cond481:                                      ; preds = %for.inc508, %for.body480
  %269 = load i32, ptr %d, align 4, !tbaa !13
  %cmp482 = icmp slt i32 %269, 3
  br i1 %cmp482, label %for.body485, label %for.cond.cleanup484

for.cond.cleanup484:                              ; preds = %for.cond481
  store i32 107, ptr %cleanup.dest.slot, align 4
  call void @llvm.lifetime.end.p0(ptr %d) #5
  br label %for.end511

for.body485:                                      ; preds = %for.cond481
  call void @llvm.lifetime.start.p0(ptr %e) #5
  store i32 0, ptr %e, align 4, !tbaa !13
  br label %for.cond486

for.cond486:                                      ; preds = %for.inc504, %for.body485
  %270 = load i32, ptr %e, align 4, !tbaa !13
  %cmp487 = icmp slt i32 %270, 3
  br i1 %cmp487, label %for.body490, label %for.cond.cleanup489

for.cond.cleanup489:                              ; preds = %for.cond486
  store i32 110, ptr %cleanup.dest.slot, align 4
  call void @llvm.lifetime.end.p0(ptr %e) #5
  br label %for.end507

for.body490:                                      ; preds = %for.cond486
  %271 = load i32, ptr %a, align 4, !tbaa !13
  %272 = load i32, ptr %b, align 4, !tbaa !13
  %add491 = add nsw i32 %271, %272
  %273 = load i32, ptr %c, align 4, !tbaa !13
  %add492 = add nsw i32 %add491, %273
  %274 = load i32, ptr %d, align 4, !tbaa !13
  %add493 = add nsw i32 %add492, %274
  %275 = load i32, ptr %e, align 4, !tbaa !13
  %add494 = add nsw i32 %add493, %275
  %276 = load i32, ptr %result, align 4, !tbaa !13
  %add495 = add nsw i32 %276, %add494
  store i32 %add495, ptr %result, align 4, !tbaa !13
  %277 = load i32, ptr %sum, align 4, !tbaa !13
  %278 = load i32, ptr %result, align 4, !tbaa !13
  %add496 = add nsw i32 %277, %278
  %rem497 = srem i32 %add496, 6000
  store i32 %rem497, ptr %sum, align 4, !tbaa !13
  %279 = load i32, ptr %a, align 4, !tbaa !13
  %280 = load i32, ptr %b, align 4, !tbaa !13
  %mul498 = mul nsw i32 %279, %280
  %281 = load i32, ptr %c, align 4, !tbaa !13
  %mul499 = mul nsw i32 %mul498, %281
  %282 = load i32, ptr %d, align 4, !tbaa !13
  %mul500 = mul nsw i32 %mul499, %282
  %283 = load i32, ptr %e, align 4, !tbaa !13
  %mul501 = mul nsw i32 %mul500, %283
  %add502 = add nsw i32 %mul501, 1
  %284 = load i32, ptr %counter, align 4, !tbaa !13
  %add503 = add nsw i32 %284, %add502
  store i32 %add503, ptr %counter, align 4, !tbaa !13
  br label %for.inc504

for.inc504:                                       ; preds = %for.body490
  %285 = load i32, ptr %e, align 4, !tbaa !13
  %inc505 = add nsw i32 %285, 1
  store i32 %inc505, ptr %e, align 4, !tbaa !13
  br label %for.cond486, !llvm.loop !58

for.end507:                                       ; preds = %for.cond.cleanup489
  br label %for.inc508

for.inc508:                                       ; preds = %for.end507
  %286 = load i32, ptr %d, align 4, !tbaa !13
  %inc509 = add nsw i32 %286, 1
  store i32 %inc509, ptr %d, align 4, !tbaa !13
  br label %for.cond481, !llvm.loop !59

for.end511:                                       ; preds = %for.cond.cleanup484
  br label %for.inc512

for.inc512:                                       ; preds = %for.end511
  %287 = load i32, ptr %c, align 4, !tbaa !13
  %inc513 = add nsw i32 %287, 1
  store i32 %inc513, ptr %c, align 4, !tbaa !13
  br label %for.cond476, !llvm.loop !60

for.end515:                                       ; preds = %for.cond.cleanup479
  call void @llvm.lifetime.end.p0(ptr %bound_c) #5
  br label %for.inc516

for.inc516:                                       ; preds = %for.end515
  %288 = load i32, ptr %b, align 4, !tbaa !13
  %inc517 = add nsw i32 %288, 1
  store i32 %inc517, ptr %b, align 4, !tbaa !13
  br label %for.cond469, !llvm.loop !61

for.end519:                                       ; preds = %for.cond.cleanup472
  br label %for.inc520

for.inc520:                                       ; preds = %for.end519
  %289 = load i32, ptr %a, align 4, !tbaa !13
  %inc521 = add nsw i32 %289, 1
  store i32 %inc521, ptr %a, align 4, !tbaa !13
  br label %for.cond464, !llvm.loop !62

for.end523:                                       ; preds = %for.cond.cleanup467
  call void @llvm.lifetime.start.p0(ptr %w) #5
  store i32 0, ptr %w, align 4, !tbaa !13
  br label %while.cond524

while.cond524:                                    ; preds = %do.end555, %for.end523
  %290 = load i32, ptr %w, align 4, !tbaa !13
  %cmp525 = icmp slt i32 %290, 20
  br i1 %cmp525, label %while.body527, label %while.end557

while.body527:                                    ; preds = %while.cond524
  call void @llvm.lifetime.start.p0(ptr %v) #5
  store i32 0, ptr %v, align 4, !tbaa !13
  br label %do.body528

do.body528:                                       ; preds = %do.cond552, %while.body527
  call void @llvm.lifetime.start.p0(ptr %u) #5
  store i32 0, ptr %u, align 4, !tbaa !13
  br label %for.cond529

for.cond529:                                      ; preds = %for.inc547, %do.body528
  %291 = load i32, ptr %u, align 4, !tbaa !13
  %cmp530 = icmp slt i32 %291, 8
  br i1 %cmp530, label %for.body533, label %for.cond.cleanup532

for.cond.cleanup532:                              ; preds = %for.cond529
  store i32 117, ptr %cleanup.dest.slot, align 4
  call void @llvm.lifetime.end.p0(ptr %u) #5
  br label %for.end550

for.body533:                                      ; preds = %for.cond529
  %292 = load i32, ptr %w, align 4, !tbaa !13
  %293 = load i32, ptr %v, align 4, !tbaa !13
  %mul534 = mul nsw i32 %292, %293
  %294 = load i32, ptr %u, align 4, !tbaa !13
  %mul535 = mul nsw i32 %mul534, %294
  %295 = load i32, ptr %sum, align 4, !tbaa !13
  %add536 = add nsw i32 %mul535, %295
  %rem537 = srem i32 %add536, 1000
  %296 = load i32, ptr %result, align 4, !tbaa !13
  %add538 = add nsw i32 %296, %rem537
  store i32 %add538, ptr %result, align 4, !tbaa !13
  %297 = load i32, ptr %result, align 4, !tbaa !13
  %rem539 = srem i32 %297, 100
  %298 = load i32, ptr %counter, align 4, !tbaa !13
  %add540 = add nsw i32 %rem539, %298
  %299 = load i32, ptr %sum, align 4, !tbaa !13
  %add541 = add nsw i32 %299, %add540
  store i32 %add541, ptr %sum, align 4, !tbaa !13
  %300 = load i32, ptr %counter, align 4, !tbaa !13
  %301 = load i32, ptr %w, align 4, !tbaa !13
  %add542 = add nsw i32 %300, %301
  %302 = load i32, ptr %v, align 4, !tbaa !13
  %add543 = add nsw i32 %add542, %302
  %303 = load i32, ptr %u, align 4, !tbaa !13
  %add544 = add nsw i32 %add543, %303
  %304 = load i32, ptr %result, align 4, !tbaa !13
  %add545 = add nsw i32 %add544, %304
  %rem546 = srem i32 %add545, 2500
  store i32 %rem546, ptr %counter, align 4, !tbaa !13
  br label %for.inc547

for.inc547:                                       ; preds = %for.body533
  %305 = load i32, ptr %u, align 4, !tbaa !13
  %inc548 = add nsw i32 %305, 1
  store i32 %inc548, ptr %u, align 4, !tbaa !13
  br label %for.cond529, !llvm.loop !63

for.end550:                                       ; preds = %for.cond.cleanup532
  %306 = load i32, ptr %v, align 4, !tbaa !13
  %inc551 = add nsw i32 %306, 1
  store i32 %inc551, ptr %v, align 4, !tbaa !13
  br label %do.cond552

do.cond552:                                       ; preds = %for.end550
  %307 = load i32, ptr %v, align 4, !tbaa !13
  %cmp553 = icmp slt i32 %307, 12
  br i1 %cmp553, label %do.body528, label %do.end555, !llvm.loop !64

do.end555:                                        ; preds = %do.cond552
  %308 = load i32, ptr %w, align 4, !tbaa !13
  %inc556 = add nsw i32 %308, 1
  store i32 %inc556, ptr %w, align 4, !tbaa !13
  call void @llvm.lifetime.end.p0(ptr %v) #5
  br label %while.cond524, !llvm.loop !65

while.end557:                                     ; preds = %while.cond524
  call void @llvm.lifetime.start.p0(ptr %start_offset) #5
  %309 = load i32, ptr %counter, align 4, !tbaa !13
  %rem558 = srem i32 %309, 15
  %add559 = add nsw i32 5, %rem558
  store i32 %add559, ptr %start_offset, align 4, !tbaa !13
  call void @llvm.lifetime.start.p0(ptr %i560) #5
  %310 = load i32, ptr %start_offset, align 4, !tbaa !13
  store i32 %310, ptr %i560, align 4, !tbaa !13
  br label %for.cond561

for.cond561:                                      ; preds = %for.inc571, %while.end557
  %311 = load i32, ptr %i560, align 4, !tbaa !13
  %cmp562 = icmp slt i32 %311, 50
  br i1 %cmp562, label %for.body565, label %for.cond.cleanup564

for.cond.cleanup564:                              ; preds = %for.cond561
  store i32 120, ptr %cleanup.dest.slot, align 4
  call void @llvm.lifetime.end.p0(ptr %i560) #5
  br label %for.end574

for.body565:                                      ; preds = %for.cond561
  %312 = load i32, ptr %i560, align 4, !tbaa !13
  %mul566 = mul nsw i32 %312, 3
  %313 = load i32, ptr %result, align 4, !tbaa !13
  %add567 = add nsw i32 %313, %mul566
  store i32 %add567, ptr %result, align 4, !tbaa !13
  %314 = load i32, ptr %sum, align 4, !tbaa !13
  %315 = load i32, ptr %result, align 4, !tbaa !13
  %add568 = add nsw i32 %314, %315
  %rem569 = srem i32 %add568, 7000
  store i32 %rem569, ptr %sum, align 4, !tbaa !13
  %316 = load i32, ptr %i560, align 4, !tbaa !13
  %317 = load i32, ptr %counter, align 4, !tbaa !13
  %add570 = add nsw i32 %317, %316
  store i32 %add570, ptr %counter, align 4, !tbaa !13
  br label %for.inc571

for.inc571:                                       ; preds = %for.body565
  %318 = load i32, ptr %i560, align 4, !tbaa !13
  %inc572 = add nsw i32 %318, 1
  store i32 %inc572, ptr %i560, align 4, !tbaa !13
  br label %for.cond561, !llvm.loop !66

for.end574:                                       ; preds = %for.cond.cleanup564
  call void @llvm.lifetime.start.p0(ptr %i575) #5
  store i32 0, ptr %i575, align 4, !tbaa !13
  br label %for.cond576

for.cond576:                                      ; preds = %for.inc599, %for.end574
  %319 = load i32, ptr %i575, align 4, !tbaa !13
  %cmp577 = icmp slt i32 %319, 10
  br i1 %cmp577, label %for.body580, label %for.cond.cleanup579

for.cond.cleanup579:                              ; preds = %for.cond576
  store i32 123, ptr %cleanup.dest.slot, align 4
  call void @llvm.lifetime.end.p0(ptr %i575) #5
  br label %for.end602

for.body580:                                      ; preds = %for.cond576
  call void @llvm.lifetime.start.p0(ptr %j581) #5
  %320 = load i32, ptr %i575, align 4, !tbaa !13
  store i32 %320, ptr %j581, align 4, !tbaa !13
  br label %for.cond582

for.cond582:                                      ; preds = %for.inc595, %for.body580
  %321 = load i32, ptr %j581, align 4, !tbaa !13
  %cmp583 = icmp slt i32 %321, 15
  br i1 %cmp583, label %for.body586, label %for.cond.cleanup585

for.cond.cleanup585:                              ; preds = %for.cond582
  store i32 126, ptr %cleanup.dest.slot, align 4
  call void @llvm.lifetime.end.p0(ptr %j581) #5
  br label %for.end598

for.body586:                                      ; preds = %for.cond582
  %322 = load i32, ptr %i575, align 4, !tbaa !13
  %mul587 = mul nsw i32 %322, 10
  %323 = load i32, ptr %j581, align 4, !tbaa !13
  %add588 = add nsw i32 %mul587, %323
  %324 = load i32, ptr %result, align 4, !tbaa !13
  %add589 = add nsw i32 %324, %add588
  store i32 %add589, ptr %result, align 4, !tbaa !13
  %325 = load i32, ptr %sum, align 4, !tbaa !13
  %326 = load i32, ptr %result, align 4, !tbaa !13
  %add590 = add nsw i32 %325, %326
  %rem591 = srem i32 %add590, 9000
  store i32 %rem591, ptr %sum, align 4, !tbaa !13
  %327 = load i32, ptr %i575, align 4, !tbaa !13
  %328 = load i32, ptr %j581, align 4, !tbaa !13
  %add592 = add nsw i32 %327, %328
  %rem593 = srem i32 %add592, 100
  %329 = load i32, ptr %counter, align 4, !tbaa !13
  %add594 = add nsw i32 %329, %rem593
  store i32 %add594, ptr %counter, align 4, !tbaa !13
  br label %for.inc595

for.inc595:                                       ; preds = %for.body586
  %330 = load i32, ptr %j581, align 4, !tbaa !13
  %inc596 = add nsw i32 %330, 1
  store i32 %inc596, ptr %j581, align 4, !tbaa !13
  br label %for.cond582, !llvm.loop !67

for.end598:                                       ; preds = %for.cond.cleanup585
  br label %for.inc599

for.inc599:                                       ; preds = %for.end598
  %331 = load i32, ptr %i575, align 4, !tbaa !13
  %inc600 = add nsw i32 %331, 1
  store i32 %inc600, ptr %i575, align 4, !tbaa !13
  br label %for.cond576, !llvm.loop !68

for.end602:                                       ; preds = %for.cond.cleanup579
  call void @llvm.lifetime.start.p0(ptr %i603) #5
  store i32 0, ptr %i603, align 4, !tbaa !13
  br label %for.cond604

for.cond604:                                      ; preds = %for.inc625, %for.end602
  %332 = load i32, ptr %i603, align 4, !tbaa !13
  %cmp605 = icmp slt i32 %332, 8
  br i1 %cmp605, label %for.body608, label %for.cond.cleanup607

for.cond.cleanup607:                              ; preds = %for.cond604
  store i32 129, ptr %cleanup.dest.slot, align 4
  call void @llvm.lifetime.end.p0(ptr %i603) #5
  br label %for.end628

for.body608:                                      ; preds = %for.cond604
  call void @llvm.lifetime.start.p0(ptr %start_k) #5
  %333 = load i32, ptr %i603, align 4, !tbaa !13
  %mul609 = mul nsw i32 %333, 2
  store i32 %mul609, ptr %start_k, align 4, !tbaa !13
  call void @llvm.lifetime.start.p0(ptr %k610) #5
  %334 = load i32, ptr %start_k, align 4, !tbaa !13
  store i32 %334, ptr %k610, align 4, !tbaa !13
  br label %for.cond611

for.cond611:                                      ; preds = %for.inc621, %for.body608
  %335 = load i32, ptr %k610, align 4, !tbaa !13
  %cmp612 = icmp slt i32 %335, 30
  br i1 %cmp612, label %for.body615, label %for.cond.cleanup614

for.cond.cleanup614:                              ; preds = %for.cond611
  store i32 132, ptr %cleanup.dest.slot, align 4
  call void @llvm.lifetime.end.p0(ptr %k610) #5
  br label %for.end624

for.body615:                                      ; preds = %for.cond611
  %336 = load i32, ptr %i603, align 4, !tbaa !13
  %337 = load i32, ptr %k610, align 4, !tbaa !13
  %mul616 = mul nsw i32 %336, %337
  %338 = load i32, ptr %result, align 4, !tbaa !13
  %add617 = add nsw i32 %338, %mul616
  store i32 %add617, ptr %result, align 4, !tbaa !13
  %339 = load i32, ptr %result, align 4, !tbaa !13
  %340 = load i32, ptr %sum, align 4, !tbaa !13
  %add618 = add nsw i32 %340, %339
  store i32 %add618, ptr %sum, align 4, !tbaa !13
  %341 = load i32, ptr %counter, align 4, !tbaa !13
  %342 = load i32, ptr %k610, align 4, !tbaa !13
  %add619 = add nsw i32 %341, %342
  %rem620 = srem i32 %add619, 800
  store i32 %rem620, ptr %counter, align 4, !tbaa !13
  br label %for.inc621

for.inc621:                                       ; preds = %for.body615
  %343 = load i32, ptr %k610, align 4, !tbaa !13
  %add622 = add nsw i32 %343, 2
  store i32 %add622, ptr %k610, align 4, !tbaa !13
  br label %for.cond611, !llvm.loop !69

for.end624:                                       ; preds = %for.cond.cleanup614
  call void @llvm.lifetime.end.p0(ptr %start_k) #5
  br label %for.inc625

for.inc625:                                       ; preds = %for.end624
  %344 = load i32, ptr %i603, align 4, !tbaa !13
  %inc626 = add nsw i32 %344, 1
  store i32 %inc626, ptr %i603, align 4, !tbaa !13
  br label %for.cond604, !llvm.loop !70

for.end628:                                       ; preds = %for.cond.cleanup607
  call void @llvm.lifetime.start.p0(ptr %outer_limit) #5
  %345 = load i32, ptr %sum, align 4, !tbaa !13
  %rem629 = srem i32 %345, 8
  %add630 = add nsw i32 12, %rem629
  store i32 %add630, ptr %outer_limit, align 4, !tbaa !13
  call void @llvm.lifetime.start.p0(ptr %i631) #5
  store i32 0, ptr %i631, align 4, !tbaa !13
  br label %for.cond632

for.cond632:                                      ; preds = %for.inc655, %for.end628
  %346 = load i32, ptr %i631, align 4, !tbaa !13
  %347 = load i32, ptr %outer_limit, align 4, !tbaa !13
  %cmp633 = icmp slt i32 %346, %347
  br i1 %cmp633, label %for.body636, label %for.cond.cleanup635

for.cond.cleanup635:                              ; preds = %for.cond632
  store i32 135, ptr %cleanup.dest.slot, align 4
  call void @llvm.lifetime.end.p0(ptr %i631) #5
  br label %for.end658

for.body636:                                      ; preds = %for.cond632
  call void @llvm.lifetime.start.p0(ptr %inner_start) #5
  %348 = load i32, ptr %i631, align 4, !tbaa !13
  store i32 %348, ptr %inner_start, align 4, !tbaa !13
  call void @llvm.lifetime.start.p0(ptr %inner_limit) #5
  %349 = load i32, ptr %i631, align 4, !tbaa !13
  %sub637 = sub nsw i32 20, %349
  store i32 %sub637, ptr %inner_limit, align 4, !tbaa !13
  call void @llvm.lifetime.start.p0(ptr %j638) #5
  %350 = load i32, ptr %inner_start, align 4, !tbaa !13
  store i32 %350, ptr %j638, align 4, !tbaa !13
  br label %for.cond639

for.cond639:                                      ; preds = %for.inc651, %for.body636
  %351 = load i32, ptr %j638, align 4, !tbaa !13
  %352 = load i32, ptr %inner_limit, align 4, !tbaa !13
  %cmp640 = icmp slt i32 %351, %352
  br i1 %cmp640, label %for.body643, label %for.cond.cleanup642

for.cond.cleanup642:                              ; preds = %for.cond639
  store i32 138, ptr %cleanup.dest.slot, align 4
  call void @llvm.lifetime.end.p0(ptr %j638) #5
  br label %for.end654

for.body643:                                      ; preds = %for.cond639
  %353 = load i32, ptr %i631, align 4, !tbaa !13
  %354 = load i32, ptr %j638, align 4, !tbaa !13
  %add644 = add nsw i32 %353, %354
  %355 = load i32, ptr %result, align 4, !tbaa !13
  %add645 = add nsw i32 %355, %add644
  store i32 %add645, ptr %result, align 4, !tbaa !13
  %356 = load i32, ptr %sum, align 4, !tbaa !13
  %357 = load i32, ptr %result, align 4, !tbaa !13
  %add646 = add nsw i32 %356, %357
  %rem647 = srem i32 %add646, 11000
  store i32 %rem647, ptr %sum, align 4, !tbaa !13
  %358 = load i32, ptr %i631, align 4, !tbaa !13
  %359 = load i32, ptr %j638, align 4, !tbaa !13
  %mul648 = mul nsw i32 %358, %359
  %rem649 = srem i32 %mul648, 50
  %360 = load i32, ptr %counter, align 4, !tbaa !13
  %add650 = add nsw i32 %360, %rem649
  store i32 %add650, ptr %counter, align 4, !tbaa !13
  br label %for.inc651

for.inc651:                                       ; preds = %for.body643
  %361 = load i32, ptr %j638, align 4, !tbaa !13
  %inc652 = add nsw i32 %361, 1
  store i32 %inc652, ptr %j638, align 4, !tbaa !13
  br label %for.cond639, !llvm.loop !71

for.end654:                                       ; preds = %for.cond.cleanup642
  call void @llvm.lifetime.end.p0(ptr %inner_limit) #5
  call void @llvm.lifetime.end.p0(ptr %inner_start) #5
  br label %for.inc655

for.inc655:                                       ; preds = %for.end654
  %362 = load i32, ptr %i631, align 4, !tbaa !13
  %inc656 = add nsw i32 %362, 1
  store i32 %inc656, ptr %i631, align 4, !tbaa !13
  br label %for.cond632, !llvm.loop !72

for.end658:                                       ; preds = %for.cond.cleanup635
  %363 = load i32, ptr %sum, align 4, !tbaa !13
  %364 = load i32, ptr %result, align 4, !tbaa !13
  %365 = load i32, ptr %counter, align 4, !tbaa !13
  %call659 = call signext i32 (ptr, ...) @printf(ptr noundef @.str, i32 noundef signext %363, i32 noundef signext %364, i32 noundef signext %365)
  %366 = load i32, ptr %sum, align 4, !tbaa !13
  %367 = load i32, ptr %result, align 4, !tbaa !13
  %add660 = add nsw i32 %366, %367
  %368 = load i32, ptr %counter, align 4, !tbaa !13
  %add661 = add nsw i32 %add660, %368
  %rem662 = srem i32 %add661, 256
  store i32 %rem662, ptr %retval, align 4
  store i32 1, ptr %cleanup.dest.slot, align 4
  call void @llvm.lifetime.end.p0(ptr %outer_limit) #5
  call void @llvm.lifetime.end.p0(ptr %start_offset) #5
  call void @llvm.lifetime.end.p0(ptr %w) #5
  call void @llvm.lifetime.end.p0(ptr %outer2) #5
  call void @llvm.lifetime.end.p0(ptr %bound_i) #5
  call void @llvm.lifetime.end.p0(ptr %x) #5
  call void @llvm.lifetime.end.p0(ptr %break_bound) #5
  call void @llvm.lifetime.end.p0(ptr %p) #5
  call void @llvm.lifetime.end.p0(ptr %while_bound) #5
  call void @llvm.lifetime.end.p0(ptr %outer) #5
  call void @llvm.lifetime.end.p0(ptr %outer_bound) #5
  call void @llvm.lifetime.end.p0(ptr %bound_j) #5
  call void @llvm.lifetime.end.p0(ptr %j) #5
  call void @llvm.lifetime.end.p0(ptr %i16) #5
  call void @llvm.lifetime.end.p0(ptr %bound3) #5
  call void @llvm.lifetime.end.p0(ptr %bound2) #5
  call void @llvm.lifetime.end.p0(ptr %bound1) #5
  call void @llvm.lifetime.end.p0(ptr %counter) #5
  call void @llvm.lifetime.end.p0(ptr %result) #5
  call void @llvm.lifetime.end.p0(ptr %sum) #5
  call void @llvm.lifetime.end.p0(ptr %seed) #5
  %369 = load i32, ptr %retval, align 4
  ret i32 %369
}

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(ptr captures(none)) #1

; Function Attrs: inlinehint nounwind willreturn memory(read) uwtable
define available_externally signext i32 @atoi(ptr noundef nonnull %__nptr) #2 {
entry:
  %__nptr.addr = alloca ptr, align 8
  store ptr %__nptr, ptr %__nptr.addr, align 8, !tbaa !18
  %0 = load ptr, ptr %__nptr.addr, align 8, !tbaa !18
  %call = call i64 @strtol(ptr noundef %0, ptr noundef null, i32 noundef signext 10) #5
  %conv = trunc i64 %call to i32
  ret i32 %conv
}

; Function Attrs: nounwind
declare i64 @time(ptr noundef) #3

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(ptr captures(none)) #1

declare signext i32 @printf(ptr noundef, ...) #4

; Function Attrs: nounwind
declare i64 @strtol(ptr noundef, ptr noundef, i32 noundef signext) #3

attributes #0 = { nounwind uwtable "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="generic-rv64" "target-features"="+64bit,+a,+c,+d,+f,+i,+m,+relax,+zaamo,+zalrsc,+zca,+zcd,+zicsr,+zifencei,+zmmul,-b,-e,-experimental-p,-experimental-smpmpmt,-experimental-svukte,-experimental-xqccmt,-experimental-xsfmclic,-experimental-xsfsclic,-experimental-y,-experimental-zibi,-experimental-zicfilp,-experimental-zicfiss,-experimental-zvabd,-experimental-zvbc32e,-experimental-zvdot4a8i,-experimental-zvfbdota32f,-experimental-zvfbfa,-experimental-zvfofp8min,-experimental-zvfqwbdota8f,-experimental-zvfqwdota8f,-experimental-zvfwbdota16bf,-experimental-zvfwdota16bf,-experimental-zvkgs,-experimental-zvqwbdota16i,-experimental-zvqwbdota8i,-experimental-zvqwdota16i,-experimental-zvqwdota8i,-experimental-zvvfmm,-experimental-zvvmm,-experimental-zvvmtls,-experimental-zvvmttls,-experimental-zvzip,-h,-q,-sdext,-sdtrig,-sha,-shcounterenw,-shgatpa,-shlcofideleg,-shtvala,-shvsatpa,-shvstvala,-shvstvecd,-smaia,-smcdeleg,-smcntrpmf,-smcsrind,-smctr,-smdbltrp,-smepmp,-smmpm,-smnpm,-smrnmi,-smstateen,-ssaia,-ssccfg,-ssccptr,-sscofpmf,-sscounterenw,-sscsrind,-ssctr,-ssdbltrp,-ssnpm,-sspm,-ssqosid,-ssstateen,-ssstrict,-sstc,-sstvala,-sstvecd,-ssu64xl,-supm,-svade,-svadu,-svbare,-svinval,-svnapot,-svpbmt,-svrsw60t59b,-svvptc,-v,-xaifet,-xandesbfhcvt,-xandesperf,-xandesvbfhcvt,-xandesvdot,-xandesvpackfph,-xandesvsinth,-xandesvsintload,-xcheriot,-xcvalu,-xcvbi,-xcvbitmanip,-xcvelw,-xcvmac,-xcvmem,-xcvsimd,-xmipscbop,-xmipscmov,-xmipsexectl,-xmipslsp,-xqccmp,-xqci,-xqcia,-xqciac,-xqcibi,-xqcibm,-xqcicli,-xqcicm,-xqcics,-xqcicsr,-xqciint,-xqciio,-xqcilb,-xqcili,-xqcilia,-xqcilo,-xqcilsm,-xqcisim,-xqcisls,-xqcisync,-xsfcease,-xsfmm128t,-xsfmm16t,-xsfmm32a,-xsfmm32a16f,-xsfmm32a32f,-xsfmm32a8f,-xsfmm32a8i,-xsfmm32t,-xsfmm64a64f,-xsfmm64t,-xsfmmbase,-xsfvcp,-xsfvfbfexp16e,-xsfvfexp16e,-xsfvfexp32e,-xsfvfexpa,-xsfvfexpa64e,-xsfvfnrclipxfqf,-xsfvfwmaccqqq,-xsfvqmaccdod,-xsfvqmaccqoq,-xsifivecdiscarddlone,-xsifivecflushdlone,-xsmtvdot,-xsmtvdotii,-xtheadba,-xtheadbb,-xtheadbs,-xtheadcmo,-xtheadcondmov,-xtheadfmemidx,-xtheadmac,-xtheadmemidx,-xtheadmempair,-xtheadsync,-xtheadvdot,-xventanacondops,-xwchc,-za128rs,-za64rs,-zabha,-zacas,-zalasr,-zama16b,-zawrs,-zba,-zbb,-zbc,-zbkb,-zbkc,-zbkx,-zbs,-zcb,-zce,-zcf,-zclsd,-zcmop,-zcmp,-zcmt,-zdinx,-zfa,-zfbfmin,-zfh,-zfhmin,-zfinx,-zhinx,-zhinxmin,-zic64b,-zicbom,-zicbop,-zicboz,-ziccamoa,-ziccamoc,-ziccid,-ziccif,-zicclsm,-ziccrse,-zicntr,-zicond,-zihintntl,-zihintpause,-zihpm,-zilsd,-zimop,-zk,-zkn,-zknd,-zkne,-zknh,-zkr,-zks,-zksed,-zksh,-zkt,-ztso,-zvbb,-zvbc,-zve32f,-zve32x,-zve64d,-zve64f,-zve64x,-zvfbfmin,-zvfbfwma,-zvfh,-zvfhmin,-zvkb,-zvkg,-zvkn,-zvknc,-zvkned,-zvkng,-zvknha,-zvknhb,-zvks,-zvksc,-zvksed,-zvksg,-zvksh,-zvkt,-zvl1024b,-zvl128b,-zvl16384b,-zvl2048b,-zvl256b,-zvl32768b,-zvl32b,-zvl4096b,-zvl512b,-zvl64b,-zvl65536b,-zvl8192b" }
attributes #1 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { inlinehint nounwind willreturn memory(read) uwtable "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="generic-rv64" "target-features"="+64bit,+a,+c,+d,+f,+i,+m,+relax,+zaamo,+zalrsc,+zca,+zcd,+zicsr,+zifencei,+zmmul,-b,-e,-experimental-p,-experimental-smpmpmt,-experimental-svukte,-experimental-xqccmt,-experimental-xsfmclic,-experimental-xsfsclic,-experimental-y,-experimental-zibi,-experimental-zicfilp,-experimental-zicfiss,-experimental-zvabd,-experimental-zvbc32e,-experimental-zvdot4a8i,-experimental-zvfbdota32f,-experimental-zvfbfa,-experimental-zvfofp8min,-experimental-zvfqwbdota8f,-experimental-zvfqwdota8f,-experimental-zvfwbdota16bf,-experimental-zvfwdota16bf,-experimental-zvkgs,-experimental-zvqwbdota16i,-experimental-zvqwbdota8i,-experimental-zvqwdota16i,-experimental-zvqwdota8i,-experimental-zvvfmm,-experimental-zvvmm,-experimental-zvvmtls,-experimental-zvvmttls,-experimental-zvzip,-h,-q,-sdext,-sdtrig,-sha,-shcounterenw,-shgatpa,-shlcofideleg,-shtvala,-shvsatpa,-shvstvala,-shvstvecd,-smaia,-smcdeleg,-smcntrpmf,-smcsrind,-smctr,-smdbltrp,-smepmp,-smmpm,-smnpm,-smrnmi,-smstateen,-ssaia,-ssccfg,-ssccptr,-sscofpmf,-sscounterenw,-sscsrind,-ssctr,-ssdbltrp,-ssnpm,-sspm,-ssqosid,-ssstateen,-ssstrict,-sstc,-sstvala,-sstvecd,-ssu64xl,-supm,-svade,-svadu,-svbare,-svinval,-svnapot,-svpbmt,-svrsw60t59b,-svvptc,-v,-xaifet,-xandesbfhcvt,-xandesperf,-xandesvbfhcvt,-xandesvdot,-xandesvpackfph,-xandesvsinth,-xandesvsintload,-xcheriot,-xcvalu,-xcvbi,-xcvbitmanip,-xcvelw,-xcvmac,-xcvmem,-xcvsimd,-xmipscbop,-xmipscmov,-xmipsexectl,-xmipslsp,-xqccmp,-xqci,-xqcia,-xqciac,-xqcibi,-xqcibm,-xqcicli,-xqcicm,-xqcics,-xqcicsr,-xqciint,-xqciio,-xqcilb,-xqcili,-xqcilia,-xqcilo,-xqcilsm,-xqcisim,-xqcisls,-xqcisync,-xsfcease,-xsfmm128t,-xsfmm16t,-xsfmm32a,-xsfmm32a16f,-xsfmm32a32f,-xsfmm32a8f,-xsfmm32a8i,-xsfmm32t,-xsfmm64a64f,-xsfmm64t,-xsfmmbase,-xsfvcp,-xsfvfbfexp16e,-xsfvfexp16e,-xsfvfexp32e,-xsfvfexpa,-xsfvfexpa64e,-xsfvfnrclipxfqf,-xsfvfwmaccqqq,-xsfvqmaccdod,-xsfvqmaccqoq,-xsifivecdiscarddlone,-xsifivecflushdlone,-xsmtvdot,-xsmtvdotii,-xtheadba,-xtheadbb,-xtheadbs,-xtheadcmo,-xtheadcondmov,-xtheadfmemidx,-xtheadmac,-xtheadmemidx,-xtheadmempair,-xtheadsync,-xtheadvdot,-xventanacondops,-xwchc,-za128rs,-za64rs,-zabha,-zacas,-zalasr,-zama16b,-zawrs,-zba,-zbb,-zbc,-zbkb,-zbkc,-zbkx,-zbs,-zcb,-zce,-zcf,-zclsd,-zcmop,-zcmp,-zcmt,-zdinx,-zfa,-zfbfmin,-zfh,-zfhmin,-zfinx,-zhinx,-zhinxmin,-zic64b,-zicbom,-zicbop,-zicboz,-ziccamoa,-ziccamoc,-ziccid,-ziccif,-zicclsm,-ziccrse,-zicntr,-zicond,-zihintntl,-zihintpause,-zihpm,-zilsd,-zimop,-zk,-zkn,-zknd,-zkne,-zknh,-zkr,-zks,-zksed,-zksh,-zkt,-ztso,-zvbb,-zvbc,-zve32f,-zve32x,-zve64d,-zve64f,-zve64x,-zvfbfmin,-zvfbfwma,-zvfh,-zvfhmin,-zvkb,-zvkg,-zvkn,-zvknc,-zvkned,-zvkng,-zvknha,-zvknhb,-zvks,-zvksc,-zvksed,-zvksg,-zvksh,-zvkt,-zvl1024b,-zvl128b,-zvl16384b,-zvl2048b,-zvl256b,-zvl32768b,-zvl32b,-zvl4096b,-zvl512b,-zvl64b,-zvl65536b,-zvl8192b" }
attributes #3 = { nounwind "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="generic-rv64" "target-features"="+64bit,+a,+c,+d,+f,+i,+m,+relax,+zaamo,+zalrsc,+zca,+zcd,+zicsr,+zifencei,+zmmul,-b,-e,-experimental-p,-experimental-smpmpmt,-experimental-svukte,-experimental-xqccmt,-experimental-xsfmclic,-experimental-xsfsclic,-experimental-y,-experimental-zibi,-experimental-zicfilp,-experimental-zicfiss,-experimental-zvabd,-experimental-zvbc32e,-experimental-zvdot4a8i,-experimental-zvfbdota32f,-experimental-zvfbfa,-experimental-zvfofp8min,-experimental-zvfqwbdota8f,-experimental-zvfqwdota8f,-experimental-zvfwbdota16bf,-experimental-zvfwdota16bf,-experimental-zvkgs,-experimental-zvqwbdota16i,-experimental-zvqwbdota8i,-experimental-zvqwdota16i,-experimental-zvqwdota8i,-experimental-zvvfmm,-experimental-zvvmm,-experimental-zvvmtls,-experimental-zvvmttls,-experimental-zvzip,-h,-q,-sdext,-sdtrig,-sha,-shcounterenw,-shgatpa,-shlcofideleg,-shtvala,-shvsatpa,-shvstvala,-shvstvecd,-smaia,-smcdeleg,-smcntrpmf,-smcsrind,-smctr,-smdbltrp,-smepmp,-smmpm,-smnpm,-smrnmi,-smstateen,-ssaia,-ssccfg,-ssccptr,-sscofpmf,-sscounterenw,-sscsrind,-ssctr,-ssdbltrp,-ssnpm,-sspm,-ssqosid,-ssstateen,-ssstrict,-sstc,-sstvala,-sstvecd,-ssu64xl,-supm,-svade,-svadu,-svbare,-svinval,-svnapot,-svpbmt,-svrsw60t59b,-svvptc,-v,-xaifet,-xandesbfhcvt,-xandesperf,-xandesvbfhcvt,-xandesvdot,-xandesvpackfph,-xandesvsinth,-xandesvsintload,-xcheriot,-xcvalu,-xcvbi,-xcvbitmanip,-xcvelw,-xcvmac,-xcvmem,-xcvsimd,-xmipscbop,-xmipscmov,-xmipsexectl,-xmipslsp,-xqccmp,-xqci,-xqcia,-xqciac,-xqcibi,-xqcibm,-xqcicli,-xqcicm,-xqcics,-xqcicsr,-xqciint,-xqciio,-xqcilb,-xqcili,-xqcilia,-xqcilo,-xqcilsm,-xqcisim,-xqcisls,-xqcisync,-xsfcease,-xsfmm128t,-xsfmm16t,-xsfmm32a,-xsfmm32a16f,-xsfmm32a32f,-xsfmm32a8f,-xsfmm32a8i,-xsfmm32t,-xsfmm64a64f,-xsfmm64t,-xsfmmbase,-xsfvcp,-xsfvfbfexp16e,-xsfvfexp16e,-xsfvfexp32e,-xsfvfexpa,-xsfvfexpa64e,-xsfvfnrclipxfqf,-xsfvfwmaccqqq,-xsfvqmaccdod,-xsfvqmaccqoq,-xsifivecdiscarddlone,-xsifivecflushdlone,-xsmtvdot,-xsmtvdotii,-xtheadba,-xtheadbb,-xtheadbs,-xtheadcmo,-xtheadcondmov,-xtheadfmemidx,-xtheadmac,-xtheadmemidx,-xtheadmempair,-xtheadsync,-xtheadvdot,-xventanacondops,-xwchc,-za128rs,-za64rs,-zabha,-zacas,-zalasr,-zama16b,-zawrs,-zba,-zbb,-zbc,-zbkb,-zbkc,-zbkx,-zbs,-zcb,-zce,-zcf,-zclsd,-zcmop,-zcmp,-zcmt,-zdinx,-zfa,-zfbfmin,-zfh,-zfhmin,-zfinx,-zhinx,-zhinxmin,-zic64b,-zicbom,-zicbop,-zicboz,-ziccamoa,-ziccamoc,-ziccid,-ziccif,-zicclsm,-ziccrse,-zicntr,-zicond,-zihintntl,-zihintpause,-zihpm,-zilsd,-zimop,-zk,-zkn,-zknd,-zkne,-zknh,-zkr,-zks,-zksed,-zksh,-zkt,-ztso,-zvbb,-zvbc,-zve32f,-zve32x,-zve64d,-zve64f,-zve64x,-zvfbfmin,-zvfbfwma,-zvfh,-zvfhmin,-zvkb,-zvkg,-zvkn,-zvknc,-zvkned,-zvkng,-zvknha,-zvknhb,-zvks,-zvksc,-zvksed,-zvksg,-zvksh,-zvkt,-zvl1024b,-zvl128b,-zvl16384b,-zvl2048b,-zvl256b,-zvl32768b,-zvl32b,-zvl4096b,-zvl512b,-zvl64b,-zvl65536b,-zvl8192b" }
attributes #4 = { "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="generic-rv64" "target-features"="+64bit,+a,+c,+d,+f,+i,+m,+relax,+zaamo,+zalrsc,+zca,+zcd,+zicsr,+zifencei,+zmmul,-b,-e,-experimental-p,-experimental-smpmpmt,-experimental-svukte,-experimental-xqccmt,-experimental-xsfmclic,-experimental-xsfsclic,-experimental-y,-experimental-zibi,-experimental-zicfilp,-experimental-zicfiss,-experimental-zvabd,-experimental-zvbc32e,-experimental-zvdot4a8i,-experimental-zvfbdota32f,-experimental-zvfbfa,-experimental-zvfofp8min,-experimental-zvfqwbdota8f,-experimental-zvfqwdota8f,-experimental-zvfwbdota16bf,-experimental-zvfwdota16bf,-experimental-zvkgs,-experimental-zvqwbdota16i,-experimental-zvqwbdota8i,-experimental-zvqwdota16i,-experimental-zvqwdota8i,-experimental-zvvfmm,-experimental-zvvmm,-experimental-zvvmtls,-experimental-zvvmttls,-experimental-zvzip,-h,-q,-sdext,-sdtrig,-sha,-shcounterenw,-shgatpa,-shlcofideleg,-shtvala,-shvsatpa,-shvstvala,-shvstvecd,-smaia,-smcdeleg,-smcntrpmf,-smcsrind,-smctr,-smdbltrp,-smepmp,-smmpm,-smnpm,-smrnmi,-smstateen,-ssaia,-ssccfg,-ssccptr,-sscofpmf,-sscounterenw,-sscsrind,-ssctr,-ssdbltrp,-ssnpm,-sspm,-ssqosid,-ssstateen,-ssstrict,-sstc,-sstvala,-sstvecd,-ssu64xl,-supm,-svade,-svadu,-svbare,-svinval,-svnapot,-svpbmt,-svrsw60t59b,-svvptc,-v,-xaifet,-xandesbfhcvt,-xandesperf,-xandesvbfhcvt,-xandesvdot,-xandesvpackfph,-xandesvsinth,-xandesvsintload,-xcheriot,-xcvalu,-xcvbi,-xcvbitmanip,-xcvelw,-xcvmac,-xcvmem,-xcvsimd,-xmipscbop,-xmipscmov,-xmipsexectl,-xmipslsp,-xqccmp,-xqci,-xqcia,-xqciac,-xqcibi,-xqcibm,-xqcicli,-xqcicm,-xqcics,-xqcicsr,-xqciint,-xqciio,-xqcilb,-xqcili,-xqcilia,-xqcilo,-xqcilsm,-xqcisim,-xqcisls,-xqcisync,-xsfcease,-xsfmm128t,-xsfmm16t,-xsfmm32a,-xsfmm32a16f,-xsfmm32a32f,-xsfmm32a8f,-xsfmm32a8i,-xsfmm32t,-xsfmm64a64f,-xsfmm64t,-xsfmmbase,-xsfvcp,-xsfvfbfexp16e,-xsfvfexp16e,-xsfvfexp32e,-xsfvfexpa,-xsfvfexpa64e,-xsfvfnrclipxfqf,-xsfvfwmaccqqq,-xsfvqmaccdod,-xsfvqmaccqoq,-xsifivecdiscarddlone,-xsifivecflushdlone,-xsmtvdot,-xsmtvdotii,-xtheadba,-xtheadbb,-xtheadbs,-xtheadcmo,-xtheadcondmov,-xtheadfmemidx,-xtheadmac,-xtheadmemidx,-xtheadmempair,-xtheadsync,-xtheadvdot,-xventanacondops,-xwchc,-za128rs,-za64rs,-zabha,-zacas,-zalasr,-zama16b,-zawrs,-zba,-zbb,-zbc,-zbkb,-zbkc,-zbkx,-zbs,-zcb,-zce,-zcf,-zclsd,-zcmop,-zcmp,-zcmt,-zdinx,-zfa,-zfbfmin,-zfh,-zfhmin,-zfinx,-zhinx,-zhinxmin,-zic64b,-zicbom,-zicbop,-zicboz,-ziccamoa,-ziccamoc,-ziccid,-ziccif,-zicclsm,-ziccrse,-zicntr,-zicond,-zihintntl,-zihintpause,-zihpm,-zilsd,-zimop,-zk,-zkn,-zknd,-zkne,-zknh,-zkr,-zks,-zksed,-zksh,-zkt,-ztso,-zvbb,-zvbc,-zve32f,-zve32x,-zve64d,-zve64f,-zve64x,-zvfbfmin,-zvfbfwma,-zvfh,-zvfhmin,-zvkb,-zvkg,-zvkn,-zvknc,-zvkned,-zvkng,-zvknha,-zvknhb,-zvks,-zvksc,-zvksed,-zvksg,-zvksh,-zvkt,-zvl1024b,-zvl128b,-zvl16384b,-zvl2048b,-zvl256b,-zvl32768b,-zvl32b,-zvl4096b,-zvl512b,-zvl64b,-zvl65536b,-zvl8192b" }
attributes #5 = { nounwind }
attributes #6 = { nounwind willreturn memory(read) }

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
!14 = !{!15, !15, i64 0}
!15 = !{!"p2 omnipotent char", !16, i64 0}
!16 = !{!"any p2 pointer", !17, i64 0}
!17 = !{!"any pointer", !11, i64 0}
!18 = !{!19, !19, i64 0}
!19 = !{!"p1 omnipotent char", !17, i64 0}
!20 = distinct !{!20, !21, !22}
!21 = !{!"llvm.loop.mustprogress"}
!22 = !{!"llvm.loop.unroll.disable"}
!23 = distinct !{!23, !21, !22}
!24 = distinct !{!24, !21, !22}
!25 = distinct !{!25, !21, !22}
!26 = distinct !{!26, !21, !22}
!27 = distinct !{!27, !21, !22}
!28 = distinct !{!28, !21, !22}
!29 = distinct !{!29, !21, !22}
!30 = distinct !{!30, !21, !22}
!31 = distinct !{!31, !21, !22}
!32 = distinct !{!32, !21, !22}
!33 = distinct !{!33, !21, !22}
!34 = distinct !{!34, !21, !22}
!35 = distinct !{!35, !21, !22}
!36 = distinct !{!36, !21, !22}
!37 = distinct !{!37, !21, !22}
!38 = distinct !{!38, !21, !22}
!39 = distinct !{!39, !21, !22}
!40 = distinct !{!40, !21, !22}
!41 = distinct !{!41, !21, !22}
!42 = distinct !{!42, !21, !22}
!43 = distinct !{!43, !21, !22}
!44 = distinct !{!44, !21, !22}
!45 = distinct !{!45, !21, !22}
!46 = distinct !{!46, !21, !22}
!47 = distinct !{!47, !21, !22}
!48 = distinct !{!48, !21, !22}
!49 = distinct !{!49, !21, !22}
!50 = distinct !{!50, !21, !22}
!51 = distinct !{!51, !21, !22}
!52 = distinct !{!52, !21, !22}
!53 = distinct !{!53, !21, !22}
!54 = distinct !{!54, !21, !22}
!55 = distinct !{!55, !21, !22}
!56 = distinct !{!56, !21, !22}
!57 = distinct !{!57, !21, !22}
!58 = distinct !{!58, !21, !22}
!59 = distinct !{!59, !21, !22}
!60 = distinct !{!60, !21, !22}
!61 = distinct !{!61, !21, !22}
!62 = distinct !{!62, !21, !22}
!63 = distinct !{!63, !21, !22}
!64 = distinct !{!64, !21, !22}
!65 = distinct !{!65, !21, !22}
!66 = distinct !{!66, !21, !22}
!67 = distinct !{!67, !21, !22}
!68 = distinct !{!68, !21, !22}
!69 = distinct !{!69, !21, !22}
!70 = distinct !{!70, !21, !22}
!71 = distinct !{!71, !21, !22}
!72 = distinct !{!72, !21, !22}
