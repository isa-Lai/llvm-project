// PATTERN 8: Fixed-size 3D Array (D3B[][10][10]) - Triple Nested
// Direct and indirect access to fixed-size 3D array

#include <stdio.h>
#include <stdlib.h>

void pattern8_3d_fixed(int *A, int D3B[][10][10], int N) {
    int D3B_dim1 = 10;  // Fixed size
    for (int i = 0; i < D3B_dim1; i++) {
        for (int j = 0; j < 10; j++) {
            for (int k = 0; k < 10; k++) {
                // Direct access: D3B[i][j][k]
                D3B[i][j][k]++;
                
                // Indirect access: D3B[A[i] % 10][j][k]
                if (i < N) {
                    int idx_i = A[i] % D3B_dim1;
                    D3B[idx_i][j][k]++;
                    int idx_j = A[j] % 10;
                    D3B[i][idx_j][k]++;
                    int idx_k = A[k] % 10;
                    D3B[i][j][idx_k]++;
                }
                
                // Indirect with rand: D3B[rand() % 10][j][k]
                int rand_i = rand() % D3B_dim1;
                D3B[rand_i][j][k]++;
                int rand_j = rand() % 10;
                D3B[i][rand_j][k]++;
                int rand_k = rand() % 10;
                D3B[i][j][rand_k]++;
            }
        }
    }
}

int main() {
    // Test 1: N = 50
    int N1 = 50;
    int *A1 = (int *)calloc(N1, sizeof(int));
    int (*D3B1)[10][10] = calloc(10, sizeof(*D3B1));
    pattern8_3d_fixed(A1, D3B1, N1);
    free(A1);
    free(D3B1);
    
    // Test 2: N = 100
    int N2 = 100;
    int *A2 = (int *)calloc(N2, sizeof(int));
    int (*D3B2)[10][10] = calloc(10, sizeof(*D3B2));
    pattern8_3d_fixed(A2, D3B2, N2);
    free(A2);
    free(D3B2);
    
    return 0;
}
