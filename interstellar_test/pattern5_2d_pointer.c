// PATTERN 5: 2D Array Pointer (D2A) - Nested Loops
// Direct and indirect access to pointer-based 2D array

#include <stdio.h>
#include <stdlib.h>

void pattern5_2d_pointer(int *A, int *D2A, int N, int D2_rows, int D2_cols) {
    for (int i = 0; i < D2_rows; i++) {
        for (int j = 0; j < D2_cols; j++) {
            // Direct access: D2A[i][j] (linearized as D2A[i * D2_cols + j])
            D2A[i * D2_cols + j]++;
            
            // Indirect access: D2A[A[i]][j] if within bounds
            if (i < N) {
                int idx_i = A[i] % D2_rows; //A pending issue
                D2A[idx_i * D2_cols + j]++;
                int idx_j = A[j] % D2_cols;
                D2A[i * D2_cols + idx_j]++;
            }
        }
    }
}

int main() {
    // Test 1: N = 30, 15x20 array
    int N1 = 30;
    int D2_rows1 = 15;
    int D2_cols1 = 20;
    int *A1 = (int *)calloc(N1, sizeof(int));
    int *D2A1 = (int *)calloc(D2_rows1 * D2_cols1, sizeof(int));
    pattern5_2d_pointer(A1, D2A1, N1, D2_rows1, D2_cols1);
    free(A1);
    free(D2A1);
    
    // Test 2: N = 50, 20x30 array
    int N2 = 50;
    int D2_rows2 = 20;
    int D2_cols2 = 30;
    int *A2 = (int *)calloc(N2, sizeof(int));
    int *D2A2 = (int *)calloc(D2_rows2 * D2_cols2, sizeof(int));
    pattern5_2d_pointer(A2, D2A2, N2, D2_rows2, D2_cols2);
    free(A2);
    free(D2A2);
    
    return 0;
}
