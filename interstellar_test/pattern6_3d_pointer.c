// PATTERN 6: 3D Array Pointer (D3A) - Triple Nested Loops
// Direct and indirect access to pointer-based 3D array

#include <stdio.h>
#include <stdlib.h>

void pattern6_3d_pointer(int *A, int *D3A, int N, int D3_dim1, int D3_dim2, int D3_dim3) {
    for (int i = 0; i < D3_dim1; i++) {
        for (int j = 0; j < D3_dim2; j++) {
            for (int k = 0; k < D3_dim3; k++) {
                // Direct access: D3A[i][j][k] (linearized)
                int idx = i * D3_dim2 * D3_dim3 + j * D3_dim3 + k;
                D3A[idx]++;
                
                // Indirect access: D3A[A[i]][j][k] if within bounds
                if (i < N && A[i] >= 0 && A[i] < D3_dim1) {
                    int idx_i = A[i];
                    int indirect_idx = idx_i * D3_dim2 * D3_dim3 + j * D3_dim3 + k;
                    D3A[indirect_idx]++;
                    int idx_j = A[j] % D3_dim2;
                    indirect_idx = i * D3_dim2 * D3_dim3 + idx_j * D3_dim3 + k;
                    D3A[indirect_idx]++;
                }
            }
        }
    }
}

int main() {
    // Test 1: N = 15, 8x10x12 array
    int N1 = 15;
    int D3_dim1_1 = 8;
    int D3_dim2_1 = 10;
    int D3_dim3_1 = 12;
    int *A1 = (int *)calloc(N1, sizeof(int));
    int *D3A1 = (int *)calloc(D3_dim1_1 * D3_dim2_1 * D3_dim3_1, sizeof(int));
    pattern6_3d_pointer(A1, D3A1, N1, D3_dim1_1, D3_dim2_1, D3_dim3_1);
    free(A1);
    free(D3A1);
    
    // Test 2: N = 20, 10x12x15 array
    int N2 = 20;
    int D3_dim1_2 = 10;
    int D3_dim2_2 = 12;
    int D3_dim3_2 = 15;
    int *A2 = (int *)calloc(N2, sizeof(int));
    int *D3A2 = (int *)calloc(D3_dim1_2 * D3_dim2_2 * D3_dim3_2, sizeof(int));
    pattern6_3d_pointer(A2, D3A2, N2, D3_dim1_2, D3_dim2_2, D3_dim3_2);
    free(A2);
    free(D3A2);
    
    return 0;
}
