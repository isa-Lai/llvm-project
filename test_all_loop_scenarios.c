// Comprehensive test for InterStellar Analysis Pass
// Testing all loop scenarios for start and end values

// Scenario 1: Constant start (non-zero), constant end
void test_const_start_const_end(int *A) {
    for (int i = 1; i < 10; i++) {
        A[i] = i;
    }
}

// Scenario 2: Constant start (zero), constant end
void test_zero_start_const_end(int *A) {
    for (int i = 0; i < 100; i++) {
        A[i] = i * 2;
    }
}

// Scenario 3: Constant start, dynamic end
void test_const_start_dynamic_end(int *A, int N) {
    for (int i = 5; i < N; i++) {
        A[i] = i + 1;
    }
}

// Scenario 4: Dynamic start, constant end
void test_dynamic_start_const_end(int *A, int start) {
    for (int i = start; i < 50; i++) {
        A[i] = i;
    }
}

// Scenario 5: Dynamic start, dynamic end
void test_dynamic_start_dynamic_end(int *A, int start, int end) {
    for (int i = start; i < end; i++) {
        A[i] = i * i;
    }
}

// Scenario 6: Nested loops with constant bounds
void test_nested_const(int *A, int M, int N) {
    for (int i = 0; i < 10; i++) {
        for (int j = 0; j < 20; j++) {
            A[i * 20 + j] = i + j;
        }
    }
}

// Scenario 7: Nested loops with outer loop variable as inner bound (triangular)
void test_nested_triangular(int *A) {
    for (int i = 0; i < 10; i++) {
        for (int j = 0; j < i; j++) {
            A[i * 10 + j] = j;
        }
    }
}
