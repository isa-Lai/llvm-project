; ModuleID = 'test_backend_input.ll'
source_filename = "patternA_loop_types.c"
target datalayout = "e-m:e-p:64:64-i64:64-i128:128-n32:64-S128"
target triple = "riscv64-unknown-linux-gnu"

@.str = private unnamed_addr constant [46 x i8] c"Final results: sum=%d, result=%d, counter=%d\0A\00", align 1

; Function Attrs: nounwind uwtable
define dso_local signext i32 @main(i32 noundef signext %argc, ptr noundef %argv) #0 {
entry:
  %seed = alloca i32, align 4
  call void @llvm.lifetime.start.p0(ptr %seed) #5
  %cmp = icmp sgt i32 %argc, 1
  br i1 %cmp, label %cond.true, label %cond.false

cond.true:                                        ; preds = %entry
  %arrayidx = getelementptr inbounds ptr, ptr %argv, i64 1
  %0 = load ptr, ptr %arrayidx, align 8, !tbaa !13
  %call = call signext i32 @atoi(ptr noundef %0) #6
  br label %cond.end

cond.false:                                       ; preds = %entry
  %call1 = call i64 @time(ptr noundef null) #5
  %conv = trunc i64 %call1 to i32
  br label %cond.end

cond.end:                                         ; preds = %cond.false, %cond.true
  %cond = phi i32 [ %call, %cond.true ], [ %conv, %cond.false ]
  store volatile i32 %cond, ptr %seed, align 4, !tbaa !16
  %1 = load volatile i32, ptr %seed, align 4, !tbaa !16
  %2 = load volatile i32, ptr %seed, align 4, !tbaa !16
  %rem = srem i32 %2, 100
  %3 = load volatile i32, ptr %seed, align 4, !tbaa !16
  %rem2 = srem i32 %3, 50
  %4 = load volatile i32, ptr %seed, align 4, !tbaa !16
  %rem3 = srem i32 %4, 40
  %add = add nsw i32 80, %rem3
  %5 = load volatile i32, ptr %seed, align 4, !tbaa !16
  %rem4 = srem i32 %5, 30
  %add5 = add nsw i32 50, %rem4
  %6 = load volatile i32, ptr %seed, align 4, !tbaa !16
  %rem6 = srem i32 %6, 20
  %add7 = add nsw i32 10, %rem6
  br label %for.cond

for.cond:                                         ; preds = %for.inc, %cond.end
  %i.0 = phi i32 [ 0, %cond.end ], [ %inc, %for.inc ]
  %result.0 = phi i32 [ %rem, %cond.end ], [ %add15, %for.inc ]
  %sum.0 = phi i32 [ %1, %cond.end ], [ %add11, %for.inc ]
  %cmp8 = icmp slt i32 %i.0, %add
  br i1 %cmp8, label %for.body, label %for.cond.cleanup

for.cond.cleanup:                                 ; preds = %for.cond
  br label %for.end

for.body:                                         ; preds = %for.cond
  %add10 = add nsw i32 %i.0, %result.0
  %add11 = add nsw i32 %sum.0, %add10
  %mul = mul nsw i32 %i.0, 2
  %add12 = add nsw i32 %mul, 3
  %add13 = add nsw i32 %add12, %add11
  %rem14 = srem i32 %add13, 1000
  %add15 = add nsw i32 %result.0, %rem14
  br label %for.inc

for.inc:                                          ; preds = %for.body
  %inc = add nsw i32 %i.0, 1
  br label %for.cond, !llvm.loop !17

for.end:                                          ; preds = %for.cond.cleanup
  br label %while.cond

while.cond:                                       ; preds = %while.body, %for.end
  %i16.0 = phi i32 [ 0, %for.end ], [ %add25, %while.body ]
  %counter.0 = phi i32 [ %rem2, %for.end ], [ %add21, %while.body ]
  %result.1 = phi i32 [ %result.0, %for.end ], [ %add24, %while.body ]
  %cmp17 = icmp slt i32 %i16.0, %add5
  br i1 %cmp17, label %while.body, label %while.end

while.body:                                       ; preds = %while.cond
  %mul19 = mul nsw i32 %i16.0, 3
  %add20 = add nsw i32 %mul19, %result.1
  %add21 = add nsw i32 %counter.0, %add20
  %add22 = add nsw i32 %add21, %sum.0
  %rem23 = srem i32 %add22, 100
  %add24 = add nsw i32 %result.1, %rem23
  %add25 = add nsw i32 %i16.0, 2
  br label %while.cond, !llvm.loop !20

while.end:                                        ; preds = %while.cond
  %rem26 = srem i32 %result.1, 30
  %add27 = add nsw i32 60, %rem26
  br label %do.body

do.body:                                          ; preds = %do.cond, %while.end
  %j.0 = phi i32 [ 0, %while.end ], [ %add34, %do.cond ]
  %counter.1 = phi i32 [ %counter.0, %while.end ], [ %rem33, %do.cond ]
  %sum.1 = phi i32 [ %sum.0, %while.end ], [ %add30, %do.cond ]
  %mul28 = mul nsw i32 %j.0, %j.0
  %add29 = add nsw i32 %sum.1, %mul28
  %add30 = add nsw i32 %add29, %counter.1
  %add31 = add nsw i32 %counter.1, %j.0
  %add32 = add nsw i32 %add31, %result.1
  %rem33 = srem i32 %add32, 200
  %add34 = add nsw i32 %j.0, 3
  br label %do.cond

do.cond:                                          ; preds = %do.body
  %cmp35 = icmp slt i32 %add34, %add27
  br i1 %cmp35, label %do.body, label %do.end, !llvm.loop !21

do.end:                                           ; preds = %do.cond
  %rem37 = srem i32 %rem33, 10
  %add38 = add nsw i32 15, %rem37
  br label %for.cond40

for.cond40:                                       ; preds = %for.inc75, %do.end
  %i39.0 = phi i32 [ 0, %do.end ], [ %add76, %for.inc75 ]
  %counter.2 = phi i32 [ %rem33, %do.end ], [ %counter.3, %for.inc75 ]
  %result.2 = phi i32 [ %result.1, %do.end ], [ %result.4, %for.inc75 ]
  %sum.2 = phi i32 [ %add30, %do.end ], [ %sum.3, %for.inc75 ]
  %cmp41 = icmp slt i32 %i39.0, %add38
  br i1 %cmp41, label %for.body44, label %for.cond.cleanup43

for.cond.cleanup43:                               ; preds = %for.cond40
  br label %for.end77

for.body44:                                       ; preds = %for.cond40
  %rem45 = srem i32 %i39.0, 10
  %add46 = add nsw i32 15, %rem45
  br label %for.cond48

for.cond48:                                       ; preds = %for.inc57, %for.body44
  %j47.0 = phi i32 [ 0, %for.body44 ], [ %inc58, %for.inc57 ]
  %result.3 = phi i32 [ %result.2, %for.body44 ], [ %add55, %for.inc57 ]
  %sum.3 = phi i32 [ %sum.2, %for.body44 ], [ %add56, %for.inc57 ]
  %cmp49 = icmp slt i32 %j47.0, %add46
  br i1 %cmp49, label %for.body52, label %for.cond.cleanup51

for.cond.cleanup51:                               ; preds = %for.cond48
  br label %for.end59

for.body52:                                       ; preds = %for.cond48
  %add53 = add nsw i32 %i39.0, %j47.0
  %add54 = add nsw i32 %add53, %counter.2
  %add55 = add nsw i32 %result.3, %add54
  %add56 = add nsw i32 %sum.3, %add55
  br label %for.inc57

for.inc57:                                        ; preds = %for.body52
  %inc58 = add nsw i32 %j47.0, 1
  br label %for.cond48, !llvm.loop !22

for.end59:                                        ; preds = %for.cond.cleanup51
  br label %for.cond60

for.cond60:                                       ; preds = %for.inc72, %for.end59
  %k.0 = phi i32 [ 0, %for.end59 ], [ %add73, %for.inc72 ]
  %counter.3 = phi i32 [ %counter.2, %for.end59 ], [ %add67, %for.inc72 ]
  %result.4 = phi i32 [ %result.3, %for.end59 ], [ %add71, %for.inc72 ]
  %cmp61 = icmp slt i32 %k.0, 15
  br i1 %cmp61, label %for.body64, label %for.cond.cleanup63

for.cond.cleanup63:                               ; preds = %for.cond60
  br label %for.end74

for.body64:                                       ; preds = %for.cond60
  %mul65 = mul nsw i32 %k.0, 2
  %add66 = add nsw i32 %mul65, %result.4
  %add67 = add nsw i32 %counter.3, %add66
  %mul68 = mul nsw i32 %i39.0, %k.0
  %add69 = add nsw i32 %mul68, %sum.3
  %rem70 = srem i32 %add69, 500
  %add71 = add nsw i32 %result.4, %rem70
  br label %for.inc72

for.inc72:                                        ; preds = %for.body64
  %add73 = add nsw i32 %k.0, 3
  br label %for.cond60, !llvm.loop !23

for.end74:                                        ; preds = %for.cond.cleanup63
  br label %for.inc75

for.inc75:                                        ; preds = %for.end74
  %add76 = add nsw i32 %i39.0, 2
  br label %for.cond40, !llvm.loop !24

for.end77:                                        ; preds = %for.cond.cleanup43
  br label %for.cond79

for.cond79:                                       ; preds = %for.inc117, %for.end77
  %i78.0 = phi i32 [ 0, %for.end77 ], [ %add118, %for.inc117 ]
  %counter.4 = phi i32 [ %counter.2, %for.end77 ], [ %counter.5, %for.inc117 ]
  %result.5 = phi i32 [ %result.2, %for.end77 ], [ %result.6, %for.inc117 ]
  %sum.4 = phi i32 [ %sum.2, %for.end77 ], [ %sum.5, %for.inc117 ]
  %cmp80 = icmp slt i32 %i78.0, 10
  br i1 %cmp80, label %for.body83, label %for.cond.cleanup82

for.cond.cleanup82:                               ; preds = %for.cond79
  br label %for.end119

for.body83:                                       ; preds = %for.cond79
  %rem85 = srem i32 %i78.0, 5
  %add86 = add nsw i32 8, %rem85
  br label %for.cond88

for.cond88:                                       ; preds = %for.inc114, %for.body83
  %j87.0 = phi i32 [ 0, %for.body83 ], [ %add115, %for.inc114 ]
  %counter.5 = phi i32 [ %counter.4, %for.body83 ], [ %counter.6, %for.inc114 ]
  %result.6 = phi i32 [ %result.5, %for.body83 ], [ %result.7, %for.inc114 ]
  %sum.5 = phi i32 [ %sum.4, %for.body83 ], [ %sum.6, %for.inc114 ]
  %cmp89 = icmp slt i32 %j87.0, %add86
  br i1 %cmp89, label %for.body92, label %for.cond.cleanup91

for.cond.cleanup91:                               ; preds = %for.cond88
  br label %for.end116

for.body92:                                       ; preds = %for.cond88
  br label %for.cond94

for.cond94:                                       ; preds = %for.inc111, %for.body92
  %k93.0 = phi i32 [ 0, %for.body92 ], [ %add112, %for.inc111 ]
  %counter.6 = phi i32 [ %counter.5, %for.body92 ], [ %add110, %for.inc111 ]
  %result.7 = phi i32 [ %result.6, %for.body92 ], [ %add105, %for.inc111 ]
  %sum.6 = phi i32 [ %sum.5, %for.body92 ], [ %rem108, %for.inc111 ]
  %cmp95 = icmp slt i32 %k93.0, 10
  br i1 %cmp95, label %for.body98, label %for.cond.cleanup97

for.cond.cleanup97:                               ; preds = %for.cond94
  br label %for.end113

for.body98:                                       ; preds = %for.cond94
  %mul99 = mul nsw i32 %i78.0, 100
  %mul100 = mul nsw i32 %j87.0, 10
  %add101 = add nsw i32 %mul99, %mul100
  %add102 = add nsw i32 %add101, %k93.0
  %rem103 = srem i32 %sum.6, 37
  %add104 = add nsw i32 %add102, %rem103
  %add105 = add nsw i32 %result.7, %add104
  %add106 = add nsw i32 %sum.6, %add105
  %add107 = add nsw i32 %add106, %counter.6
  %rem108 = srem i32 %add107, 10000
  %rem109 = srem i32 %add105, 13
  %add110 = add nsw i32 %counter.6, %rem109
  br label %for.inc111

for.inc111:                                       ; preds = %for.body98
  %add112 = add nsw i32 %k93.0, 3
  br label %for.cond94, !llvm.loop !25

for.end113:                                       ; preds = %for.cond.cleanup97
  br label %for.inc114

for.inc114:                                       ; preds = %for.end113
  %add115 = add nsw i32 %j87.0, 2
  br label %for.cond88, !llvm.loop !26

for.end116:                                       ; preds = %for.cond.cleanup91
  br label %for.inc117

for.inc117:                                       ; preds = %for.end116
  %add118 = add nsw i32 %i78.0, 1
  br label %for.cond79, !llvm.loop !27

for.end119:                                       ; preds = %for.cond.cleanup82
  %rem120 = srem i32 %sum.4, 8
  %add121 = add nsw i32 12, %rem120
  br label %while.cond122

while.cond122:                                    ; preds = %for.end141, %for.end119
  %outer.0 = phi i32 [ 0, %for.end119 ], [ %add142, %for.end141 ]
  %counter.7 = phi i32 [ %counter.4, %for.end119 ], [ %counter.8, %for.end141 ]
  %result.8 = phi i32 [ %result.5, %for.end119 ], [ %result.9, %for.end141 ]
  %sum.7 = phi i32 [ %sum.4, %for.end119 ], [ %sum.8, %for.end141 ]
  %cmp123 = icmp slt i32 %outer.0, %add121
  br i1 %cmp123, label %while.body125, label %while.end143

while.body125:                                    ; preds = %while.cond122
  %rem126 = srem i32 %outer.0, 8
  %add127 = add nsw i32 10, %rem126
  br label %for.cond128

for.cond128:                                      ; preds = %for.inc139, %while.body125
  %inner.0 = phi i32 [ 0, %while.body125 ], [ %add140, %for.inc139 ]
  %counter.8 = phi i32 [ %counter.7, %while.body125 ], [ %rem138, %for.inc139 ]
  %result.9 = phi i32 [ %result.8, %while.body125 ], [ %add134, %for.inc139 ]
  %sum.8 = phi i32 [ %sum.7, %while.body125 ], [ %add135, %for.inc139 ]
  %cmp129 = icmp slt i32 %inner.0, %add127
  br i1 %cmp129, label %for.body132, label %for.cond.cleanup131

for.cond.cleanup131:                              ; preds = %for.cond128
  br label %for.end141

for.body132:                                      ; preds = %for.cond128
  %mul133 = mul nsw i32 %outer.0, %inner.0
  %add134 = add nsw i32 %result.9, %mul133
  %add135 = add nsw i32 %sum.8, %add134
  %add136 = add nsw i32 %counter.8, %outer.0
  %add137 = add nsw i32 %add136, %inner.0
  %rem138 = srem i32 %add137, 500
  br label %for.inc139

for.inc139:                                       ; preds = %for.body132
  %add140 = add nsw i32 %inner.0, 2
  br label %for.cond128, !llvm.loop !28

for.end141:                                       ; preds = %for.cond.cleanup131
  %add142 = add nsw i32 %outer.0, 4
  br label %while.cond122, !llvm.loop !29

while.end143:                                     ; preds = %while.cond122
  br label %do.body144

do.body144:                                       ; preds = %do.cond158, %while.end143
  %p.0 = phi i32 [ 0, %while.end143 ], [ %inc157, %do.cond158 ]
  %result.10 = phi i32 [ %result.8, %while.end143 ], [ %result.11, %do.cond158 ]
  %sum.9 = phi i32 [ %sum.7, %while.end143 ], [ %sum.10, %do.cond158 ]
  br label %while.cond145

while.cond145:                                    ; preds = %while.body148, %do.body144
  %q.0 = phi i32 [ 0, %do.body144 ], [ %inc155, %while.body148 ]
  %result.11 = phi i32 [ %result.10, %do.body144 ], [ %add152, %while.body148 ]
  %sum.10 = phi i32 [ %sum.9, %do.body144 ], [ %rem154, %while.body148 ]
  %cmp146 = icmp slt i32 %q.0, 10
  br i1 %cmp146, label %while.body148, label %while.end156

while.body148:                                    ; preds = %while.cond145
  %mul149 = mul nsw i32 %p.0, %q.0
  %add150 = add nsw i32 %mul149, %p.0
  %add151 = add nsw i32 %add150, %q.0
  %add152 = add nsw i32 %result.11, %add151
  %add153 = add nsw i32 %sum.10, %add152
  %rem154 = srem i32 %add153, 1000
  %inc155 = add nsw i32 %q.0, 1
  br label %while.cond145, !llvm.loop !30

while.end156:                                     ; preds = %while.cond145
  %inc157 = add nsw i32 %p.0, 1
  br label %do.cond158

do.cond158:                                       ; preds = %while.end156
  %cmp159 = icmp slt i32 %inc157, 20
  br i1 %cmp159, label %do.body144, label %do.end161, !llvm.loop !31

do.end161:                                        ; preds = %do.cond158
  br label %for.cond163

for.cond163:                                      ; preds = %for.inc181, %do.end161
  %i162.0 = phi i32 [ 0, %do.end161 ], [ %inc182, %for.inc181 ]
  %counter.9 = phi i32 [ %counter.7, %do.end161 ], [ %add170, %for.inc181 ]
  %result.12 = phi i32 [ %result.11, %do.end161 ], [ %add173, %for.inc181 ]
  %sum.11 = phi i32 [ %sum.10, %do.end161 ], [ %rem175, %for.inc181 ]
  %cmp164 = icmp slt i32 %i162.0, 30
  br i1 %cmp164, label %for.body167, label %for.cond.cleanup166

for.cond.cleanup166:                              ; preds = %for.cond163
  br label %for.end183

for.body167:                                      ; preds = %for.cond163
  br label %do.body168

do.body168:                                       ; preds = %do.cond177, %for.body167
  %m.0 = phi i32 [ 0, %for.body167 ], [ %inc176, %do.cond177 ]
  %counter.10 = phi i32 [ %counter.9, %for.body167 ], [ %add170, %do.cond177 ]
  %result.13 = phi i32 [ %result.12, %for.body167 ], [ %add173, %do.cond177 ]
  %sum.12 = phi i32 [ %sum.11, %for.body167 ], [ %rem175, %do.cond177 ]
  %add169 = add nsw i32 %i162.0, %m.0
  %add170 = add nsw i32 %counter.10, %add169
  %mul171 = mul nsw i32 %i162.0, %m.0
  %mul172 = mul nsw i32 %mul171, %m.0
  %add173 = add nsw i32 %result.13, %mul172
  %add174 = add nsw i32 %sum.12, %add173
  %rem175 = srem i32 %add174, 2000
  %inc176 = add nsw i32 %m.0, 1
  br label %do.cond177

do.cond177:                                       ; preds = %do.body168
  %cmp178 = icmp slt i32 %inc176, 8
  br i1 %cmp178, label %do.body168, label %do.end180, !llvm.loop !32

do.end180:                                        ; preds = %do.cond177
  br label %for.inc181

for.inc181:                                       ; preds = %do.end180
  %inc182 = add nsw i32 %i162.0, 1
  br label %for.cond163, !llvm.loop !33

for.end183:                                       ; preds = %for.cond.cleanup166
  br label %for.cond185

for.cond185:                                      ; preds = %for.inc211, %for.end183
  %i184.0 = phi i32 [ 0, %for.end183 ], [ %inc212, %for.inc211 ]
  %counter.11 = phi i32 [ %counter.9, %for.end183 ], [ %counter.12, %for.inc211 ]
  %result.14 = phi i32 [ %result.12, %for.end183 ], [ %result.15, %for.inc211 ]
  %sum.13 = phi i32 [ %sum.11, %for.end183 ], [ %sum.14, %for.inc211 ]
  %cmp186 = icmp slt i32 %i184.0, 10
  br i1 %cmp186, label %for.body189, label %for.cond.cleanup188

for.cond.cleanup188:                              ; preds = %for.cond185
  br label %for.end213

for.body189:                                      ; preds = %for.cond185
  br label %while.cond191

while.cond191:                                    ; preds = %do.end208, %for.body189
  %j190.0 = phi i32 [ 0, %for.body189 ], [ %inc209, %do.end208 ]
  %counter.12 = phi i32 [ %counter.11, %for.body189 ], [ %rem203, %do.end208 ]
  %result.15 = phi i32 [ %result.14, %for.body189 ], [ %add199, %do.end208 ]
  %sum.14 = phi i32 [ %sum.13, %for.body189 ], [ %add201, %do.end208 ]
  %cmp192 = icmp slt i32 %j190.0, 10
  br i1 %cmp192, label %while.body194, label %while.end210

while.body194:                                    ; preds = %while.cond191
  br label %do.body196

do.body196:                                       ; preds = %do.cond205, %while.body194
  %k195.0 = phi i32 [ 0, %while.body194 ], [ %inc204, %do.cond205 ]
  %counter.13 = phi i32 [ %counter.12, %while.body194 ], [ %rem203, %do.cond205 ]
  %result.16 = phi i32 [ %result.15, %while.body194 ], [ %add199, %do.cond205 ]
  %sum.15 = phi i32 [ %sum.14, %while.body194 ], [ %add201, %do.cond205 ]
  %add197 = add nsw i32 %i184.0, %j190.0
  %add198 = add nsw i32 %add197, %k195.0
  %add199 = add nsw i32 %result.16, %add198
  %mul200 = mul nsw i32 %add199, %add199
  %add201 = add nsw i32 %sum.15, %mul200
  %add202 = add nsw i32 %counter.13, %add199
  %rem203 = srem i32 %add202, 300
  %inc204 = add nsw i32 %k195.0, 1
  br label %do.cond205

do.cond205:                                       ; preds = %do.body196
  %cmp206 = icmp slt i32 %inc204, 5
  br i1 %cmp206, label %do.body196, label %do.end208, !llvm.loop !34

do.end208:                                        ; preds = %do.cond205
  %inc209 = add nsw i32 %j190.0, 1
  br label %while.cond191, !llvm.loop !35

while.end210:                                     ; preds = %while.cond191
  br label %for.inc211

for.inc211:                                       ; preds = %while.end210
  %inc212 = add nsw i32 %i184.0, 1
  br label %for.cond185, !llvm.loop !36

for.end213:                                       ; preds = %for.cond.cleanup188
  br label %for.cond215

for.cond215:                                      ; preds = %for.inc268, %for.end213
  %i214.0 = phi i32 [ 0, %for.end213 ], [ %inc269, %for.inc268 ]
  %counter.14 = phi i32 [ %counter.11, %for.end213 ], [ %counter.15, %for.inc268 ]
  %result.17 = phi i32 [ %result.14, %for.end213 ], [ %result.20, %for.inc268 ]
  %sum.16 = phi i32 [ %sum.13, %for.end213 ], [ %sum.18, %for.inc268 ]
  %cmp216 = icmp slt i32 %i214.0, 15
  br i1 %cmp216, label %for.body219, label %for.cond.cleanup218

for.cond.cleanup218:                              ; preds = %for.cond215
  br label %for.end270

for.body219:                                      ; preds = %for.cond215
  %rem221 = srem i32 %i214.0, 10
  %add222 = add nsw i32 15, %rem221
  br label %for.cond224

for.cond224:                                      ; preds = %for.inc233, %for.body219
  %j223.0 = phi i32 [ 0, %for.body219 ], [ %add234, %for.inc233 ]
  %result.18 = phi i32 [ %result.17, %for.body219 ], [ %add230, %for.inc233 ]
  %sum.17 = phi i32 [ %sum.16, %for.body219 ], [ %rem232, %for.inc233 ]
  %cmp225 = icmp slt i32 %j223.0, %add222
  br i1 %cmp225, label %for.body228, label %for.cond.cleanup227

for.cond.cleanup227:                              ; preds = %for.cond224
  br label %for.end235

for.body228:                                      ; preds = %for.cond224
  %mul229 = mul nsw i32 %i214.0, %j223.0
  %add230 = add nsw i32 %result.18, %mul229
  %add231 = add nsw i32 %sum.17, %add230
  %rem232 = srem i32 %add231, 5000
  br label %for.inc233

for.inc233:                                       ; preds = %for.body228
  %add234 = add nsw i32 %j223.0, 5
  br label %for.cond224, !llvm.loop !37

for.end235:                                       ; preds = %for.cond.cleanup227
  br label %for.cond237

for.cond237:                                      ; preds = %for.inc248, %for.end235
  %k236.0 = phi i32 [ 0, %for.end235 ], [ %add249, %for.inc248 ]
  %counter.15 = phi i32 [ %counter.14, %for.end235 ], [ %add243, %for.inc248 ]
  %result.19 = phi i32 [ %result.18, %for.end235 ], [ %add247, %for.inc248 ]
  %cmp238 = icmp slt i32 %k236.0, 25
  br i1 %cmp238, label %for.body241, label %for.cond.cleanup240

for.cond.cleanup240:                              ; preds = %for.cond237
  br label %for.end250

for.body241:                                      ; preds = %for.cond237
  %add242 = add nsw i32 %i214.0, %k236.0
  %add243 = add nsw i32 %counter.15, %add242
  %add244 = add nsw i32 %i214.0, %k236.0
  %sub = sub nsw i32 %i214.0, %k236.0
  %add245 = add nsw i32 %sub, 10
  %mul246 = mul nsw i32 %add244, %add245
  %add247 = add nsw i32 %result.19, %mul246
  br label %for.inc248

for.inc248:                                       ; preds = %for.body241
  %add249 = add nsw i32 %k236.0, 7
  br label %for.cond237, !llvm.loop !38

for.end250:                                       ; preds = %for.cond.cleanup240
  %rem251 = srem i32 %counter.15, 6
  %add252 = add nsw i32 8, %rem251
  br label %for.cond254

for.cond254:                                      ; preds = %for.inc265, %for.end250
  %m253.0 = phi i32 [ 0, %for.end250 ], [ %add266, %for.inc265 ]
  %result.20 = phi i32 [ %result.19, %for.end250 ], [ %add264, %for.inc265 ]
  %sum.18 = phi i32 [ %sum.17, %for.end250 ], [ %add260, %for.inc265 ]
  %cmp255 = icmp slt i32 %m253.0, %add252
  br i1 %cmp255, label %for.body258, label %for.cond.cleanup257

for.cond.cleanup257:                              ; preds = %for.cond254
  br label %for.end267

for.body258:                                      ; preds = %for.cond254
  %add259 = add nsw i32 %i214.0, %m253.0
  %add260 = add nsw i32 %sum.18, %add259
  %mul261 = mul nsw i32 %i214.0, %i214.0
  %mul262 = mul nsw i32 %m253.0, %m253.0
  %add263 = add nsw i32 %mul261, %mul262
  %add264 = add nsw i32 %result.20, %add263
  br label %for.inc265

for.inc265:                                       ; preds = %for.body258
  %add266 = add nsw i32 %m253.0, 2
  br label %for.cond254, !llvm.loop !39

for.end267:                                       ; preds = %for.cond.cleanup257
  br label %for.inc268

for.inc268:                                       ; preds = %for.end267
  %inc269 = add nsw i32 %i214.0, 1
  br label %for.cond215, !llvm.loop !40

for.end270:                                       ; preds = %for.cond.cleanup218
  %rem271 = srem i32 %result.17, 30
  %add272 = add nsw i32 50, %rem271
  br label %for.cond274

for.cond274:                                      ; preds = %for.inc290, %for.end270
  %i273.0 = phi i32 [ 0, %for.end270 ], [ %add291, %for.inc290 ]
  %counter.16 = phi i32 [ %counter.14, %for.end270 ], [ %counter.17, %for.inc290 ]
  %result.21 = phi i32 [ %result.17, %for.end270 ], [ %result.23, %for.inc290 ]
  %sum.19 = phi i32 [ %sum.16, %for.end270 ], [ %sum.21, %for.inc290 ]
  %cmp275 = icmp slt i32 %i273.0, 100
  br i1 %cmp275, label %for.body278, label %for.cond.cleanup277

for.cond.cleanup277:                              ; preds = %for.cond274
  br label %cleanup

for.body278:                                      ; preds = %for.cond274
  %rem279 = srem i32 %i273.0, 3
  %cmp280 = icmp eq i32 %rem279, 0
  br i1 %cmp280, label %if.then, label %if.end

if.then:                                          ; preds = %for.body278
  br label %for.inc290

if.end:                                           ; preds = %for.body278
  %mul282 = mul nsw i32 %i273.0, 2
  %add283 = add nsw i32 %result.21, %mul282
  %add284 = add nsw i32 %sum.19, %add283
  %cmp285 = icmp sgt i32 %i273.0, %add272
  br i1 %cmp285, label %if.then287, label %if.end288

if.then287:                                       ; preds = %if.end
  br label %cleanup

if.end288:                                        ; preds = %if.end
  %inc289 = add nsw i32 %counter.16, 1
  br label %for.inc290

for.inc290:                                       ; preds = %if.end288, %if.then
  %counter.17 = phi i32 [ %counter.16, %if.then ], [ %inc289, %if.end288 ]
  %result.23 = phi i32 [ %result.21, %if.then ], [ %add283, %if.end288 ]
  %sum.21 = phi i32 [ %sum.19, %if.then ], [ %add284, %if.end288 ]
  %add291 = add nsw i32 %i273.0, 6
  br label %for.cond274, !llvm.loop !41

cleanup:                                          ; preds = %if.then287, %for.cond.cleanup277
  %result.22 = phi i32 [ %add283, %if.then287 ], [ %result.21, %for.cond.cleanup277 ]
  %sum.20 = phi i32 [ %add284, %if.then287 ], [ %sum.19, %for.cond.cleanup277 ]
  br label %for.end292

for.end292:                                       ; preds = %cleanup
  br label %while.cond293

while.cond293:                                    ; preds = %while.end323, %for.end292
  %x.0 = phi i32 [ 0, %for.end292 ], [ %inc324, %while.end323 ]
  %counter.18 = phi i32 [ %counter.16, %for.end292 ], [ %counter.19, %while.end323 ]
  %result.24 = phi i32 [ %result.22, %for.end292 ], [ %result.25, %while.end323 ]
  %sum.22 = phi i32 [ %sum.20, %for.end292 ], [ %sum.23, %while.end323 ]
  %cmp294 = icmp slt i32 %x.0, 30
  br i1 %cmp294, label %while.body296, label %while.end325

while.body296:                                    ; preds = %while.cond293
  br label %while.cond297

while.cond297:                                    ; preds = %for.end321, %while.body296
  %y.0 = phi i32 [ 0, %while.body296 ], [ %inc322, %for.end321 ]
  %counter.19 = phi i32 [ %counter.18, %while.body296 ], [ %counter.20, %for.end321 ]
  %result.25 = phi i32 [ %result.24, %while.body296 ], [ %result.26, %for.end321 ]
  %sum.23 = phi i32 [ %sum.22, %while.body296 ], [ %rem305, %for.end321 ]
  %cmp298 = icmp slt i32 %y.0, 30
  br i1 %cmp298, label %while.body300, label %while.end323

while.body300:                                    ; preds = %while.cond297
  %mul301 = mul nsw i32 %x.0, 30
  %add302 = add nsw i32 %mul301, %y.0
  %add303 = add nsw i32 %result.25, %add302
  %add304 = add nsw i32 %sum.23, %add303
  %rem305 = srem i32 %add304, 3000
  br label %for.cond306

for.cond306:                                      ; preds = %for.inc318, %while.body300
  %z.0 = phi i32 [ 0, %while.body300 ], [ %inc319, %for.inc318 ]
  %counter.20 = phi i32 [ %counter.19, %while.body300 ], [ %add313, %for.inc318 ]
  %result.26 = phi i32 [ %add303, %while.body300 ], [ %add317, %for.inc318 ]
  %cmp307 = icmp slt i32 %z.0, 5
  br i1 %cmp307, label %for.body310, label %for.cond.cleanup309

for.cond.cleanup309:                              ; preds = %for.cond306
  br label %for.end321

for.body310:                                      ; preds = %for.cond306
  %add311 = add nsw i32 %x.0, %y.0
  %add312 = add nsw i32 %add311, %z.0
  %add313 = add nsw i32 %counter.20, %add312
  %mul314 = mul nsw i32 %x.0, %y.0
  %mul315 = mul nsw i32 %mul314, %z.0
  %add316 = add nsw i32 %mul315, 1
  %add317 = add nsw i32 %result.26, %add316
  br label %for.inc318

for.inc318:                                       ; preds = %for.body310
  %inc319 = add nsw i32 %z.0, 1
  br label %for.cond306, !llvm.loop !42

for.end321:                                       ; preds = %for.cond.cleanup309
  %inc322 = add nsw i32 %y.0, 1
  br label %while.cond297, !llvm.loop !43

while.end323:                                     ; preds = %while.cond297
  %inc324 = add nsw i32 %x.0, 1
  br label %while.cond293, !llvm.loop !44

while.end325:                                     ; preds = %while.cond293
  br label %for.cond327

for.cond327:                                      ; preds = %for.inc379, %while.end325
  %i326.0 = phi i32 [ 0, %while.end325 ], [ %inc380, %for.inc379 ]
  %counter.21 = phi i32 [ %counter.18, %while.end325 ], [ %counter.22, %for.inc379 ]
  %result.27 = phi i32 [ %result.24, %while.end325 ], [ %result.28, %for.inc379 ]
  %sum.24 = phi i32 [ %sum.22, %while.end325 ], [ %sum.25, %for.inc379 ]
  %cmp328 = icmp slt i32 %i326.0, 5
  br i1 %cmp328, label %for.body331, label %for.cond.cleanup330

for.cond.cleanup330:                              ; preds = %for.cond327
  br label %for.end382

for.body331:                                      ; preds = %for.cond327
  %rem333 = srem i32 %i326.0, 3
  %add334 = add nsw i32 4, %rem333
  br label %for.cond336

for.cond336:                                      ; preds = %for.inc375, %for.body331
  %j335.0 = phi i32 [ 0, %for.body331 ], [ %add376, %for.inc375 ]
  %counter.22 = phi i32 [ %counter.21, %for.body331 ], [ %counter.23, %for.inc375 ]
  %result.28 = phi i32 [ %result.27, %for.body331 ], [ %result.29, %for.inc375 ]
  %sum.25 = phi i32 [ %sum.24, %for.body331 ], [ %sum.26, %for.inc375 ]
  %cmp337 = icmp slt i32 %j335.0, %add334
  br i1 %cmp337, label %for.body340, label %for.cond.cleanup339

for.cond.cleanup339:                              ; preds = %for.cond336
  br label %for.end378

for.body340:                                      ; preds = %for.cond336
  br label %for.cond342

for.cond342:                                      ; preds = %for.inc371, %for.body340
  %k341.0 = phi i32 [ 0, %for.body340 ], [ %inc372, %for.inc371 ]
  %counter.23 = phi i32 [ %counter.22, %for.body340 ], [ %counter.24, %for.inc371 ]
  %result.29 = phi i32 [ %result.28, %for.body340 ], [ %result.30, %for.inc371 ]
  %sum.26 = phi i32 [ %sum.25, %for.body340 ], [ %sum.27, %for.inc371 ]
  %cmp343 = icmp slt i32 %k341.0, 5
  br i1 %cmp343, label %for.body346, label %for.cond.cleanup345

for.cond.cleanup345:                              ; preds = %for.cond342
  br label %for.end374

for.body346:                                      ; preds = %for.cond342
  br label %for.cond348

for.cond348:                                      ; preds = %for.inc367, %for.body346
  %m347.0 = phi i32 [ 0, %for.body346 ], [ %add368, %for.inc367 ]
  %counter.24 = phi i32 [ %counter.23, %for.body346 ], [ %add366, %for.inc367 ]
  %result.30 = phi i32 [ %result.29, %for.body346 ], [ %add359, %for.inc367 ]
  %sum.27 = phi i32 [ %sum.26, %for.body346 ], [ %rem364, %for.inc367 ]
  %cmp349 = icmp slt i32 %m347.0, 5
  br i1 %cmp349, label %for.body352, label %for.cond.cleanup351

for.cond.cleanup351:                              ; preds = %for.cond348
  br label %for.end370

for.body352:                                      ; preds = %for.cond348
  %mul353 = mul nsw i32 %i326.0, 125
  %mul354 = mul nsw i32 %j335.0, 25
  %add355 = add nsw i32 %mul353, %mul354
  %mul356 = mul nsw i32 %k341.0, 5
  %add357 = add nsw i32 %add355, %mul356
  %add358 = add nsw i32 %add357, %m347.0
  %add359 = add nsw i32 %result.30, %add358
  %add360 = add nsw i32 %sum.27, %i326.0
  %add361 = add nsw i32 %add360, %j335.0
  %add362 = add nsw i32 %add361, %k341.0
  %add363 = add nsw i32 %add362, %m347.0
  %rem364 = srem i32 %add363, 4000
  %rem365 = srem i32 %add359, 100
  %add366 = add nsw i32 %counter.24, %rem365
  br label %for.inc367

for.inc367:                                       ; preds = %for.body352
  %add368 = add nsw i32 %m347.0, 2
  br label %for.cond348, !llvm.loop !45

for.end370:                                       ; preds = %for.cond.cleanup351
  br label %for.inc371

for.inc371:                                       ; preds = %for.end370
  %inc372 = add nsw i32 %k341.0, 1
  br label %for.cond342, !llvm.loop !46

for.end374:                                       ; preds = %for.cond.cleanup345
  br label %for.inc375

for.inc375:                                       ; preds = %for.end374
  %add376 = add nsw i32 %j335.0, 2
  br label %for.cond336, !llvm.loop !47

for.end378:                                       ; preds = %for.cond.cleanup339
  br label %for.inc379

for.inc379:                                       ; preds = %for.end378
  %inc380 = add nsw i32 %i326.0, 1
  br label %for.cond327, !llvm.loop !48

for.end382:                                       ; preds = %for.cond.cleanup330
  br label %for.cond385

for.cond385:                                      ; preds = %for.inc396, %for.end382
  %j384.0 = phi i32 [ 100, %for.end382 ], [ %dec, %for.inc396 ]
  %i383.0 = phi i32 [ 0, %for.end382 ], [ %inc397, %for.inc396 ]
  %counter.25 = phi i32 [ %counter.21, %for.end382 ], [ %rem395, %for.inc396 ]
  %result.31 = phi i32 [ %result.27, %for.end382 ], [ %add391, %for.inc396 ]
  %sum.28 = phi i32 [ %sum.24, %for.end382 ], [ %add392, %for.inc396 ]
  %cmp386 = icmp slt i32 %i383.0, %j384.0
  br i1 %cmp386, label %for.body389, label %for.cond.cleanup388

for.cond.cleanup388:                              ; preds = %for.cond385
  br label %for.end400

for.body389:                                      ; preds = %for.cond385
  %add390 = add nsw i32 %i383.0, %j384.0
  %add391 = add nsw i32 %result.31, %add390
  %add392 = add nsw i32 %sum.28, %add391
  %add393 = add nsw i32 %counter.25, %i383.0
  %sub394 = sub nsw i32 %add393, %j384.0
  %rem395 = srem i32 %sub394, 600
  br label %for.inc396

for.inc396:                                       ; preds = %for.body389
  %inc397 = add nsw i32 %i383.0, 1
  %dec = add nsw i32 %j384.0, -1
  br label %for.cond385, !llvm.loop !49

for.end400:                                       ; preds = %for.cond.cleanup388
  %rem401 = srem i32 %counter.25, 10
  %add402 = add nsw i32 15, %rem401
  br label %for.cond404

for.cond404:                                      ; preds = %for.inc432, %for.end400
  %i403.0 = phi i32 [ 0, %for.end400 ], [ %add433, %for.inc432 ]
  %counter.26 = phi i32 [ %counter.25, %for.end400 ], [ %counter.27, %for.inc432 ]
  %result.32 = phi i32 [ %result.31, %for.end400 ], [ %result.33, %for.inc432 ]
  %sum.29 = phi i32 [ %sum.28, %for.end400 ], [ %sum.30, %for.inc432 ]
  %cmp405 = icmp slt i32 %i403.0, %add402
  br i1 %cmp405, label %for.body408, label %for.cond.cleanup407

for.cond.cleanup407:                              ; preds = %for.cond404
  br label %for.end435

for.body408:                                      ; preds = %for.cond404
  %mul409 = mul nsw i32 %i403.0, 7
  %rem410 = srem i32 %mul409, 30
  %rem412 = srem i32 %i403.0, 12
  %add413 = add nsw i32 12, %rem412
  br label %for.cond415

for.cond415:                                      ; preds = %for.inc428, %for.body408
  %j414.0 = phi i32 [ 0, %for.body408 ], [ %add429, %for.inc428 ]
  %counter.27 = phi i32 [ %counter.26, %for.body408 ], [ %add427, %for.inc428 ]
  %result.33 = phi i32 [ %result.32, %for.body408 ], [ %add423, %for.inc428 ]
  %sum.30 = phi i32 [ %sum.29, %for.body408 ], [ %rem425, %for.inc428 ]
  %cmp416 = icmp slt i32 %j414.0, %add413
  br i1 %cmp416, label %for.body419, label %for.cond.cleanup418

for.cond.cleanup418:                              ; preds = %for.cond415
  br label %for.end431

for.body419:                                      ; preds = %for.cond415
  %mul420 = mul nsw i32 %j414.0, 11
  %rem421 = srem i32 %mul420, 30
  %mul422 = mul nsw i32 %rem410, %rem421
  %add423 = add nsw i32 %result.33, %mul422
  %add424 = add nsw i32 %sum.30, %add423
  %rem425 = srem i32 %add424, 8000
  %add426 = add nsw i32 %rem410, %rem421
  %add427 = add nsw i32 %counter.27, %add426
  br label %for.inc428

for.inc428:                                       ; preds = %for.body419
  %add429 = add nsw i32 %j414.0, 4
  br label %for.cond415, !llvm.loop !50

for.end431:                                       ; preds = %for.cond.cleanup418
  br label %for.inc432

for.inc432:                                       ; preds = %for.end431
  %add433 = add nsw i32 %i403.0, 3
  br label %for.cond404, !llvm.loop !51

for.end435:                                       ; preds = %for.cond.cleanup407
  br label %do.body436

do.body436:                                       ; preds = %do.cond460, %for.end435
  %outer2.0 = phi i32 [ 0, %for.end435 ], [ %inc459, %do.cond460 ]
  %counter.28 = phi i32 [ %counter.26, %for.end435 ], [ %counter.29, %do.cond460 ]
  %result.34 = phi i32 [ %result.32, %for.end435 ], [ %result.35, %do.cond460 ]
  %sum.31 = phi i32 [ %sum.29, %for.end435 ], [ %sum.32, %do.cond460 ]
  br label %for.cond437

for.cond437:                                      ; preds = %for.inc455, %do.body436
  %mid.0 = phi i32 [ 0, %do.body436 ], [ %inc456, %for.inc455 ]
  %counter.29 = phi i32 [ %counter.28, %do.body436 ], [ %counter.30, %for.inc455 ]
  %result.35 = phi i32 [ %result.34, %do.body436 ], [ %result.36, %for.inc455 ]
  %sum.32 = phi i32 [ %sum.31, %do.body436 ], [ %sum.33, %for.inc455 ]
  %cmp438 = icmp slt i32 %mid.0, 10
  br i1 %cmp438, label %for.body441, label %for.cond.cleanup440

for.cond.cleanup440:                              ; preds = %for.cond437
  br label %for.end458

for.body441:                                      ; preds = %for.cond437
  br label %while.cond442

while.cond442:                                    ; preds = %while.body445, %for.body441
  %inner2.0 = phi i32 [ 0, %for.body441 ], [ %inc453, %while.body445 ]
  %counter.30 = phi i32 [ %counter.29, %for.body441 ], [ %rem452, %while.body445 ]
  %result.36 = phi i32 [ %result.35, %for.body441 ], [ %add448, %while.body445 ]
  %sum.33 = phi i32 [ %sum.32, %for.body441 ], [ %add449, %while.body445 ]
  %cmp443 = icmp slt i32 %inner2.0, 10
  br i1 %cmp443, label %while.body445, label %while.end454

while.body445:                                    ; preds = %while.cond442
  %add446 = add nsw i32 %outer2.0, %mid.0
  %add447 = add nsw i32 %add446, %inner2.0
  %add448 = add nsw i32 %result.36, %add447
  %add449 = add nsw i32 %sum.33, %add448
  %mul450 = mul nsw i32 %add448, %add448
  %add451 = add nsw i32 %counter.30, %mul450
  %rem452 = srem i32 %add451, 1500
  %inc453 = add nsw i32 %inner2.0, 1
  br label %while.cond442, !llvm.loop !52

while.end454:                                     ; preds = %while.cond442
  br label %for.inc455

for.inc455:                                       ; preds = %while.end454
  %inc456 = add nsw i32 %mid.0, 1
  br label %for.cond437, !llvm.loop !53

for.end458:                                       ; preds = %for.cond.cleanup440
  %inc459 = add nsw i32 %outer2.0, 1
  br label %do.cond460

do.cond460:                                       ; preds = %for.end458
  %cmp461 = icmp slt i32 %inc459, 50
  br i1 %cmp461, label %do.body436, label %do.end463, !llvm.loop !54

do.end463:                                        ; preds = %do.cond460
  br label %for.cond464

for.cond464:                                      ; preds = %for.inc520, %do.end463
  %a.0 = phi i32 [ 0, %do.end463 ], [ %inc521, %for.inc520 ]
  %counter.31 = phi i32 [ %counter.29, %do.end463 ], [ %counter.32, %for.inc520 ]
  %result.37 = phi i32 [ %result.35, %do.end463 ], [ %result.38, %for.inc520 ]
  %sum.34 = phi i32 [ %sum.32, %do.end463 ], [ %sum.35, %for.inc520 ]
  %cmp465 = icmp slt i32 %a.0, 3
  br i1 %cmp465, label %for.body468, label %for.cond.cleanup467

for.cond.cleanup467:                              ; preds = %for.cond464
  br label %for.end523

for.body468:                                      ; preds = %for.cond464
  br label %for.cond469

for.cond469:                                      ; preds = %for.inc516, %for.body468
  %b.0 = phi i32 [ 0, %for.body468 ], [ %inc517, %for.inc516 ]
  %counter.32 = phi i32 [ %counter.31, %for.body468 ], [ %counter.33, %for.inc516 ]
  %result.38 = phi i32 [ %result.37, %for.body468 ], [ %result.39, %for.inc516 ]
  %sum.35 = phi i32 [ %sum.34, %for.body468 ], [ %sum.36, %for.inc516 ]
  %cmp470 = icmp slt i32 %b.0, 3
  br i1 %cmp470, label %for.body473, label %for.cond.cleanup472

for.cond.cleanup472:                              ; preds = %for.cond469
  br label %for.end519

for.body473:                                      ; preds = %for.cond469
  %rem474 = srem i32 %a.0, 2
  %add475 = add nsw i32 2, %rem474
  br label %for.cond476

for.cond476:                                      ; preds = %for.inc512, %for.body473
  %c.0 = phi i32 [ 0, %for.body473 ], [ %inc513, %for.inc512 ]
  %counter.33 = phi i32 [ %counter.32, %for.body473 ], [ %counter.34, %for.inc512 ]
  %result.39 = phi i32 [ %result.38, %for.body473 ], [ %result.40, %for.inc512 ]
  %sum.36 = phi i32 [ %sum.35, %for.body473 ], [ %sum.37, %for.inc512 ]
  %cmp477 = icmp slt i32 %c.0, %add475
  br i1 %cmp477, label %for.body480, label %for.cond.cleanup479

for.cond.cleanup479:                              ; preds = %for.cond476
  br label %for.end515

for.body480:                                      ; preds = %for.cond476
  br label %for.cond481

for.cond481:                                      ; preds = %for.inc508, %for.body480
  %d.0 = phi i32 [ 0, %for.body480 ], [ %inc509, %for.inc508 ]
  %counter.34 = phi i32 [ %counter.33, %for.body480 ], [ %counter.35, %for.inc508 ]
  %result.40 = phi i32 [ %result.39, %for.body480 ], [ %result.41, %for.inc508 ]
  %sum.37 = phi i32 [ %sum.36, %for.body480 ], [ %sum.38, %for.inc508 ]
  %cmp482 = icmp slt i32 %d.0, 3
  br i1 %cmp482, label %for.body485, label %for.cond.cleanup484

for.cond.cleanup484:                              ; preds = %for.cond481
  br label %for.end511

for.body485:                                      ; preds = %for.cond481
  br label %for.cond486

for.cond486:                                      ; preds = %for.inc504, %for.body485
  %e.0 = phi i32 [ 0, %for.body485 ], [ %inc505, %for.inc504 ]
  %counter.35 = phi i32 [ %counter.34, %for.body485 ], [ %add503, %for.inc504 ]
  %result.41 = phi i32 [ %result.40, %for.body485 ], [ %add495, %for.inc504 ]
  %sum.38 = phi i32 [ %sum.37, %for.body485 ], [ %rem497, %for.inc504 ]
  %cmp487 = icmp slt i32 %e.0, 3
  br i1 %cmp487, label %for.body490, label %for.cond.cleanup489

for.cond.cleanup489:                              ; preds = %for.cond486
  br label %for.end507

for.body490:                                      ; preds = %for.cond486
  %add491 = add nsw i32 %a.0, %b.0
  %add492 = add nsw i32 %add491, %c.0
  %add493 = add nsw i32 %add492, %d.0
  %add494 = add nsw i32 %add493, %e.0
  %add495 = add nsw i32 %result.41, %add494
  %add496 = add nsw i32 %sum.38, %add495
  %rem497 = srem i32 %add496, 6000
  %mul498 = mul nsw i32 %a.0, %b.0
  %mul499 = mul nsw i32 %mul498, %c.0
  %mul500 = mul nsw i32 %mul499, %d.0
  %mul501 = mul nsw i32 %mul500, %e.0
  %add502 = add nsw i32 %mul501, 1
  %add503 = add nsw i32 %counter.35, %add502
  br label %for.inc504

for.inc504:                                       ; preds = %for.body490
  %inc505 = add nsw i32 %e.0, 1
  br label %for.cond486, !llvm.loop !55

for.end507:                                       ; preds = %for.cond.cleanup489
  br label %for.inc508

for.inc508:                                       ; preds = %for.end507
  %inc509 = add nsw i32 %d.0, 1
  br label %for.cond481, !llvm.loop !56

for.end511:                                       ; preds = %for.cond.cleanup484
  br label %for.inc512

for.inc512:                                       ; preds = %for.end511
  %inc513 = add nsw i32 %c.0, 1
  br label %for.cond476, !llvm.loop !57

for.end515:                                       ; preds = %for.cond.cleanup479
  br label %for.inc516

for.inc516:                                       ; preds = %for.end515
  %inc517 = add nsw i32 %b.0, 1
  br label %for.cond469, !llvm.loop !58

for.end519:                                       ; preds = %for.cond.cleanup472
  br label %for.inc520

for.inc520:                                       ; preds = %for.end519
  %inc521 = add nsw i32 %a.0, 1
  br label %for.cond464, !llvm.loop !59

for.end523:                                       ; preds = %for.cond.cleanup467
  br label %while.cond524

while.cond524:                                    ; preds = %do.end555, %for.end523
  %w.0 = phi i32 [ 0, %for.end523 ], [ %inc556, %do.end555 ]
  %counter.36 = phi i32 [ %counter.31, %for.end523 ], [ %counter.38, %do.end555 ]
  %result.42 = phi i32 [ %result.37, %for.end523 ], [ %result.44, %do.end555 ]
  %sum.39 = phi i32 [ %sum.34, %for.end523 ], [ %sum.41, %do.end555 ]
  %cmp525 = icmp slt i32 %w.0, 20
  br i1 %cmp525, label %while.body527, label %while.end557

while.body527:                                    ; preds = %while.cond524
  br label %do.body528

do.body528:                                       ; preds = %do.cond552, %while.body527
  %v.0 = phi i32 [ 0, %while.body527 ], [ %inc551, %do.cond552 ]
  %counter.37 = phi i32 [ %counter.36, %while.body527 ], [ %counter.38, %do.cond552 ]
  %result.43 = phi i32 [ %result.42, %while.body527 ], [ %result.44, %do.cond552 ]
  %sum.40 = phi i32 [ %sum.39, %while.body527 ], [ %sum.41, %do.cond552 ]
  br label %for.cond529

for.cond529:                                      ; preds = %for.inc547, %do.body528
  %u.0 = phi i32 [ 0, %do.body528 ], [ %inc548, %for.inc547 ]
  %counter.38 = phi i32 [ %counter.37, %do.body528 ], [ %rem546, %for.inc547 ]
  %result.44 = phi i32 [ %result.43, %do.body528 ], [ %add538, %for.inc547 ]
  %sum.41 = phi i32 [ %sum.40, %do.body528 ], [ %add541, %for.inc547 ]
  %cmp530 = icmp slt i32 %u.0, 8
  br i1 %cmp530, label %for.body533, label %for.cond.cleanup532

for.cond.cleanup532:                              ; preds = %for.cond529
  br label %for.end550

for.body533:                                      ; preds = %for.cond529
  %mul534 = mul nsw i32 %w.0, %v.0
  %mul535 = mul nsw i32 %mul534, %u.0
  %add536 = add nsw i32 %mul535, %sum.41
  %rem537 = srem i32 %add536, 1000
  %add538 = add nsw i32 %result.44, %rem537
  %rem539 = srem i32 %add538, 100
  %add540 = add nsw i32 %rem539, %counter.38
  %add541 = add nsw i32 %sum.41, %add540
  %add542 = add nsw i32 %counter.38, %w.0
  %add543 = add nsw i32 %add542, %v.0
  %add544 = add nsw i32 %add543, %u.0
  %add545 = add nsw i32 %add544, %add538
  %rem546 = srem i32 %add545, 2500
  br label %for.inc547

for.inc547:                                       ; preds = %for.body533
  %inc548 = add nsw i32 %u.0, 1
  br label %for.cond529, !llvm.loop !60

for.end550:                                       ; preds = %for.cond.cleanup532
  %inc551 = add nsw i32 %v.0, 1
  br label %do.cond552

do.cond552:                                       ; preds = %for.end550
  %cmp553 = icmp slt i32 %inc551, 12
  br i1 %cmp553, label %do.body528, label %do.end555, !llvm.loop !61

do.end555:                                        ; preds = %do.cond552
  %inc556 = add nsw i32 %w.0, 1
  br label %while.cond524, !llvm.loop !62

while.end557:                                     ; preds = %while.cond524
  %rem558 = srem i32 %counter.36, 15
  %add559 = add nsw i32 5, %rem558
  br label %for.cond561

for.cond561:                                      ; preds = %for.inc571, %while.end557
  %i560.0 = phi i32 [ %add559, %while.end557 ], [ %inc572, %for.inc571 ]
  %counter.39 = phi i32 [ %counter.36, %while.end557 ], [ %add570, %for.inc571 ]
  %result.45 = phi i32 [ %result.42, %while.end557 ], [ %add567, %for.inc571 ]
  %sum.42 = phi i32 [ %sum.39, %while.end557 ], [ %rem569, %for.inc571 ]
  %cmp562 = icmp slt i32 %i560.0, 50
  br i1 %cmp562, label %for.body565, label %for.cond.cleanup564

for.cond.cleanup564:                              ; preds = %for.cond561
  br label %for.end574

for.body565:                                      ; preds = %for.cond561
  %mul566 = mul nsw i32 %i560.0, 3
  %add567 = add nsw i32 %result.45, %mul566
  %add568 = add nsw i32 %sum.42, %add567
  %rem569 = srem i32 %add568, 7000
  %add570 = add nsw i32 %counter.39, %i560.0
  br label %for.inc571

for.inc571:                                       ; preds = %for.body565
  %inc572 = add nsw i32 %i560.0, 1
  br label %for.cond561, !llvm.loop !63

for.end574:                                       ; preds = %for.cond.cleanup564
  br label %for.cond576

for.cond576:                                      ; preds = %for.inc599, %for.end574
  %i575.0 = phi i32 [ 0, %for.end574 ], [ %inc600, %for.inc599 ]
  %counter.40 = phi i32 [ %counter.39, %for.end574 ], [ %counter.41, %for.inc599 ]
  %result.46 = phi i32 [ %result.45, %for.end574 ], [ %result.47, %for.inc599 ]
  %sum.43 = phi i32 [ %sum.42, %for.end574 ], [ %sum.44, %for.inc599 ]
  %cmp577 = icmp slt i32 %i575.0, 10
  br i1 %cmp577, label %for.body580, label %for.cond.cleanup579

for.cond.cleanup579:                              ; preds = %for.cond576
  br label %for.end602

for.body580:                                      ; preds = %for.cond576
  br label %for.cond582

for.cond582:                                      ; preds = %for.inc595, %for.body580
  %j581.0 = phi i32 [ %i575.0, %for.body580 ], [ %inc596, %for.inc595 ]
  %counter.41 = phi i32 [ %counter.40, %for.body580 ], [ %add594, %for.inc595 ]
  %result.47 = phi i32 [ %result.46, %for.body580 ], [ %add589, %for.inc595 ]
  %sum.44 = phi i32 [ %sum.43, %for.body580 ], [ %rem591, %for.inc595 ]
  %cmp583 = icmp slt i32 %j581.0, 15
  br i1 %cmp583, label %for.body586, label %for.cond.cleanup585

for.cond.cleanup585:                              ; preds = %for.cond582
  br label %for.end598

for.body586:                                      ; preds = %for.cond582
  %mul587 = mul nsw i32 %i575.0, 10
  %add588 = add nsw i32 %mul587, %j581.0
  %add589 = add nsw i32 %result.47, %add588
  %add590 = add nsw i32 %sum.44, %add589
  %rem591 = srem i32 %add590, 9000
  %add592 = add nsw i32 %i575.0, %j581.0
  %rem593 = srem i32 %add592, 100
  %add594 = add nsw i32 %counter.41, %rem593
  br label %for.inc595

for.inc595:                                       ; preds = %for.body586
  %inc596 = add nsw i32 %j581.0, 1
  br label %for.cond582, !llvm.loop !64

for.end598:                                       ; preds = %for.cond.cleanup585
  br label %for.inc599

for.inc599:                                       ; preds = %for.end598
  %inc600 = add nsw i32 %i575.0, 1
  br label %for.cond576, !llvm.loop !65

for.end602:                                       ; preds = %for.cond.cleanup579
  br label %for.cond604

for.cond604:                                      ; preds = %for.inc625, %for.end602
  %i603.0 = phi i32 [ 0, %for.end602 ], [ %inc626, %for.inc625 ]
  %counter.42 = phi i32 [ %counter.40, %for.end602 ], [ %counter.43, %for.inc625 ]
  %result.48 = phi i32 [ %result.46, %for.end602 ], [ %result.49, %for.inc625 ]
  %sum.45 = phi i32 [ %sum.43, %for.end602 ], [ %sum.46, %for.inc625 ]
  %cmp605 = icmp slt i32 %i603.0, 8
  br i1 %cmp605, label %for.body608, label %for.cond.cleanup607

for.cond.cleanup607:                              ; preds = %for.cond604
  br label %for.end628

for.body608:                                      ; preds = %for.cond604
  %mul609 = mul nsw i32 %i603.0, 2
  br label %for.cond611

for.cond611:                                      ; preds = %for.inc621, %for.body608
  %k610.0 = phi i32 [ %mul609, %for.body608 ], [ %add622, %for.inc621 ]
  %counter.43 = phi i32 [ %counter.42, %for.body608 ], [ %rem620, %for.inc621 ]
  %result.49 = phi i32 [ %result.48, %for.body608 ], [ %add617, %for.inc621 ]
  %sum.46 = phi i32 [ %sum.45, %for.body608 ], [ %add618, %for.inc621 ]
  %cmp612 = icmp slt i32 %k610.0, 30
  br i1 %cmp612, label %for.body615, label %for.cond.cleanup614

for.cond.cleanup614:                              ; preds = %for.cond611
  br label %for.end624

for.body615:                                      ; preds = %for.cond611
  %mul616 = mul nsw i32 %i603.0, %k610.0
  %add617 = add nsw i32 %result.49, %mul616
  %add618 = add nsw i32 %sum.46, %add617
  %add619 = add nsw i32 %counter.43, %k610.0
  %rem620 = srem i32 %add619, 800
  br label %for.inc621

for.inc621:                                       ; preds = %for.body615
  %add622 = add nsw i32 %k610.0, 2
  br label %for.cond611, !llvm.loop !66

for.end624:                                       ; preds = %for.cond.cleanup614
  br label %for.inc625

for.inc625:                                       ; preds = %for.end624
  %inc626 = add nsw i32 %i603.0, 1
  br label %for.cond604, !llvm.loop !67

for.end628:                                       ; preds = %for.cond.cleanup607
  %rem629 = srem i32 %sum.45, 8
  %add630 = add nsw i32 12, %rem629
  br label %for.cond632

for.cond632:                                      ; preds = %for.inc655, %for.end628
  %counter.44 = phi i32 [ %counter.42, %for.end628 ], [ %counter.45, %for.inc655 ]
  %result.50 = phi i32 [ %result.48, %for.end628 ], [ %result.51, %for.inc655 ]
  %sum.47 = phi i32 [ %sum.45, %for.end628 ], [ %sum.48, %for.inc655 ]
  %i631.0 = phi i32 [ 0, %for.end628 ], [ %inc656, %for.inc655 ]
  %cmp633 = icmp slt i32 %i631.0, %add630
  br i1 %cmp633, label %for.body636, label %for.cond.cleanup635

for.cond.cleanup635:                              ; preds = %for.cond632
  br label %for.end658

for.body636:                                      ; preds = %for.cond632
  %sub637 = sub nsw i32 20, %i631.0
  br label %for.cond639

for.cond639:                                      ; preds = %for.inc651, %for.body636
  %counter.45 = phi i32 [ %counter.44, %for.body636 ], [ %add650, %for.inc651 ]
  %result.51 = phi i32 [ %result.50, %for.body636 ], [ %add645, %for.inc651 ]
  %sum.48 = phi i32 [ %sum.47, %for.body636 ], [ %rem647, %for.inc651 ]
  %j638.0 = phi i32 [ %i631.0, %for.body636 ], [ %inc652, %for.inc651 ]
  %cmp640 = icmp slt i32 %j638.0, %sub637
  br i1 %cmp640, label %for.body643, label %for.cond.cleanup642

for.cond.cleanup642:                              ; preds = %for.cond639
  br label %for.end654

for.body643:                                      ; preds = %for.cond639
  %add644 = add nsw i32 %i631.0, %j638.0
  %add645 = add nsw i32 %result.51, %add644
  %add646 = add nsw i32 %sum.48, %add645
  %rem647 = srem i32 %add646, 11000
  %mul648 = mul nsw i32 %i631.0, %j638.0
  %rem649 = srem i32 %mul648, 50
  %add650 = add nsw i32 %counter.45, %rem649
  br label %for.inc651

for.inc651:                                       ; preds = %for.body643
  %inc652 = add nsw i32 %j638.0, 1
  br label %for.cond639, !llvm.loop !68

for.end654:                                       ; preds = %for.cond.cleanup642
  br label %for.inc655

for.inc655:                                       ; preds = %for.end654
  %inc656 = add nsw i32 %i631.0, 1
  br label %for.cond632, !llvm.loop !69

for.end658:                                       ; preds = %for.cond.cleanup635
  %call659 = call signext i32 (ptr, ...) @printf(ptr noundef @.str, i32 noundef signext %sum.47, i32 noundef signext %result.50, i32 noundef signext %counter.44)
  %add660 = add nsw i32 %sum.47, %result.50
  %add661 = add nsw i32 %add660, %counter.44
  %rem662 = srem i32 %add661, 256
  call void @llvm.lifetime.end.p0(ptr %seed) #5
  ret i32 %rem662
}

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(ptr captures(none)) #1

; Function Attrs: inlinehint nounwind willreturn memory(read) uwtable
define available_externally signext i32 @atoi(ptr noundef nonnull %__nptr) #2 {
entry:
  %call = call i64 @strtol(ptr noundef %__nptr, ptr noundef null, i32 noundef signext 10) #5
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
!13 = !{!14, !14, i64 0}
!14 = !{!"p1 omnipotent char", !15, i64 0}
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
!31 = distinct !{!31, !18, !19}
!32 = distinct !{!32, !18, !19}
!33 = distinct !{!33, !18, !19}
!34 = distinct !{!34, !18, !19}
!35 = distinct !{!35, !18, !19}
!36 = distinct !{!36, !18, !19}
!37 = distinct !{!37, !18, !19}
!38 = distinct !{!38, !18, !19}
!39 = distinct !{!39, !18, !19}
!40 = distinct !{!40, !18, !19}
!41 = distinct !{!41, !18, !19}
!42 = distinct !{!42, !18, !19}
!43 = distinct !{!43, !18, !19}
!44 = distinct !{!44, !18, !19}
!45 = distinct !{!45, !18, !19}
!46 = distinct !{!46, !18, !19}
!47 = distinct !{!47, !18, !19}
!48 = distinct !{!48, !18, !19}
!49 = distinct !{!49, !18, !19}
!50 = distinct !{!50, !18, !19}
!51 = distinct !{!51, !18, !19}
!52 = distinct !{!52, !18, !19}
!53 = distinct !{!53, !18, !19}
!54 = distinct !{!54, !18, !19}
!55 = distinct !{!55, !18, !19}
!56 = distinct !{!56, !18, !19}
!57 = distinct !{!57, !18, !19}
!58 = distinct !{!58, !18, !19}
!59 = distinct !{!59, !18, !19}
!60 = distinct !{!60, !18, !19}
!61 = distinct !{!61, !18, !19}
!62 = distinct !{!62, !18, !19}
!63 = distinct !{!63, !18, !19}
!64 = distinct !{!64, !18, !19}
!65 = distinct !{!65, !18, !19}
!66 = distinct !{!66, !18, !19}
!67 = distinct !{!67, !18, !19}
!68 = distinct !{!68, !18, !19}
!69 = distinct !{!69, !18, !19}
