// PatternC: Array-bounded indirect streams (A[B[i]] gather).
// Covers the two factors that decide whether the compiler can emit a non-zero
// StreamSize on the indirect descriptor:
//
//   Kernel                          Target array bound     Loop bound
//   ------------------------------  ---------------------  ---------------
//   gather_bounded_known_bound      static (globals)       static  (N)
//   gather_unbounded_known_bound    unknown (ptr params)   static  (N)
//   gather_unbounded_runtime_bound  unknown (ptr params)   runtime (n param)
//
// Expected indirect-descriptor emission (ElementSize, StreamSize):
//   1. gather_bounded_known_bound     -> (4, N * 4 = 4096): allocation visible
//   2. gather_unbounded_known_bound   -> (4, 0): pointer base has no static size
//   3. gather_unbounded_runtime_bound -> (4, 0) plus a Link-carried loop End
//      (EL=1) because the trip count is a runtime argument
//
// Note: a file-scope `int A[];` would NOT test "unknown size" - it is a
// tentative definition the compiler completes to one element, so the analysis
// would see a 4-byte allocation. Unknown-size cases must use pointer params.

#define N 1024

int A[N];          // Target array - gather source (statically sized)
int B[N];          // Index array - source of indices
int Out[N];        // Output array - gather destination

//----------------------------------------------------------------------
// Case 1: bounded arrays + statically-known loop bound.
// A's footprint is visible to the analysis -> StreamSize = N * 4 = 4096.
//----------------------------------------------------------------------
void gather_bounded_known_bound(void) {
  for (int i = 0; i < N; i++) {
    // A[B[i]] is an indirect stream with base @A and target array size
    // = N * sizeof(int) = 4096 bytes; B[i] is a direct stream of indices.
    Out[i] = A[B[i]];
  }
}

//----------------------------------------------------------------------
// Case 2: pointer-parameter arrays (allocation size unknown) + statically-
// known loop bound. StreamSize must degrade to 0 (= unknown) while the
// loop End stays a constant (EL=0) - isolating the array-bound factor.
//----------------------------------------------------------------------
void gather_unbounded_known_bound(int *a, int *b, int *out) {
  for (int i = 0; i < N; i++) {
    out[i] = a[b[i]];
  }
}

//----------------------------------------------------------------------
// Case 3: pointer-parameter arrays AND a runtime loop bound. StreamSize
// stays 0 and the loop End becomes link-carried (EL=1) - isolating the
// loop-bound factor on top of case 2.
//----------------------------------------------------------------------
void gather_unbounded_runtime_bound(int *a, int *b, int *out, int n) {
  for (int i = 0; i < n; i++) {
    out[i] = a[b[i]];
  }
}
