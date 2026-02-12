// PATTERN 7: Fixed-size 2D Array (D2B[][10]) - Nested Loops
// Direct and indirect access to fixed-size 2D array

#include <stdio.h>
#include <stdlib.h>

void pattern7_2d_fixed(int *A, int D2B[][10], int N) {
    int D2B_rows = 10;  // Fixed size
    for (int i = 0; i < D2B_rows; i++) {
        for (int j = 0; j < 10; j++) {
            // Direct access: D2B[i][j]
            D2B[i][j]++;
            
            // Indirect access: D2B[A[i] % 10][j]
            if (i < N) {
                int idx_i = A[i] % D2B_rows;
                D2B[idx_i][j]++;
                int idx_j = A[j] % 10;
                D2B[i][idx_j]++;
            }
        }
    }
}


void pattern7_2d_fixedB(int *B, int D2B[][10], int N) {
    int D2B_rows = 10;  // Fixed size
    for (int i = 0; i < D2B_rows; i++) {
        for (int j = 0; j < 10; j++) {
            // Direct access: D2B[i][j]
            D2B[i][j]++;
        }
    }
}

int main() {
    // Test 1: N = 50
    int N1 = 50;
    int *A1 = (int *)calloc(N1, sizeof(int));
    int (*D2B1)[10] = calloc(10, sizeof(*D2B1));
    pattern7_2d_fixed(A1, D2B1, N1);
    free(A1);
    free(D2B1);
    
    // Test 2: N = 100
    int N2 = 100;
    int *A2 = (int *)calloc(N2, sizeof(int));
    int (*D2B2)[10] = calloc(10, sizeof(*D2B2));
    pattern7_2d_fixed(A2, D2B2, N2);
    free(A2);
    free(D2B2);
    
    return 0;
}
