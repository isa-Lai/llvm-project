// PATTERN B: 4-Level Nested Loops - Testing Recursive Parent Loop Association
// Demonstrates that streams are correctly associated with loops at various nesting depths
// A[i] - 3 levels up, B[j] - 2 levels up, C[k] - 1 level up, D[m] - current level

#include <stdio.h>
#include <stdlib.h>

void patternB_4level_nesting(int *A, int *B, int *C, int *D, int*E,
                              int N, int M, int P, int Q) {
    for (int i = 0; i < N; i++) {           // Loop 0 (outermost)
        for (int j = 0; j < M; j++) {       // Loop 1 (nested in Loop 0)
            for (int k = 0; k < P; k++) {   // Loop 2 (nested in Loop 1)
                for (int m = 0; m < Q; m++) { // Loop 3 (innermost, nested in Loop 2)
                    // Stream associations:
                    A[i]++;  // Loop 0 variable (3 levels up from innermost)
                    B[j]++;  // Loop 1 variable (2 levels up from innermost)
                    C[k]++;  // Loop 2 variable (1 level up from innermost)
                    D[m]++;  // Loop 3 variable (current level)
                    E[i*M*P*Q+j*P*Q+k*Q+m]++; // Combination access
                }
            }
        }
    }
}

void patternB_4d_array(int A[][10][10][10], int N) {
    // 4-level nested access pattern
    for (int i = 0; i < N; i++) {
        for (int j = 0; j < 10; j++) {
            for (int k = 0; k < 10; k++) {
                for (int m = 0; m < 10; m++) {
                    A[i][j][k][m]++;
                }
            }
        }
    }
}

void patternB_4d_array_pointer(int *A, int N, int M, int P, int Q) {
    // 4-level nested access pattern with pointer and index calculation
    for (int i = 0; i < N; i++) {
        for (int j = 0; j < M; j++) {
            for (int k = 0; k < P; k++) {
                for (int m = 0; m < Q; m++) {
                    A[i*M*P*Q + j*P*Q + k*Q + m]++;
                }
            }
        }
    }
}



int main() {
    // Test: 4x5x6x7 nested structure
    int N = 4;
    int M = 5;
    int P = 6;
    int Q = 7;
    
    int *A = (int *)calloc(N, sizeof(int));
    int *B = (int *)calloc(M, sizeof(int));
    int *C = (int *)calloc(P, sizeof(int));
    int *D = (int *)calloc(Q, sizeof(int));
    int *E = (int *)calloc(N*M*P*Q, sizeof(int));   
    
    patternB_4level_nesting(A, B, C, D, E, N, M, P, Q);
    
    // Verify results
    // A[i] should be incremented M*P*Q times for each i
    printf("A[0] = %d (expected: %d)\n", A[0], M * P * Q);
    
    // B[j] should be incremented N*P*Q times for each j
    printf("B[0] = %d (expected: %d)\n", B[0], N * P * Q);
    
    // C[k] should be incremented N*M*Q times for each k
    printf("C[0] = %d (expected: %d)\n", C[0], N * M * Q);
    
    // D[m] should be incremented N*M*P times for each m
    printf("D[0] = %d (expected: %d)\n", D[0], N * M * P);
    
    free(A);
    free(B);
    free(C);
    free(D);
    free(E);
    
    return 0;
}
