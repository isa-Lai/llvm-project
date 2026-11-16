// PATTERN 2: Indirect Streams on Array B
// B[A[i]] - using A as index array
// B[rand()] - random indirect access

#include <stdio.h>
#include <stdlib.h>

void pattern2_indirect_streams(int *A, int *B, int N) {
    for (int i = 0; i < N; i++) {
        // Indirect stream: B[A[i]]
        int idx = A[i];
        if (idx >= 0 && idx < N) {
            B[idx]++;
        }
        
        // Indirect stream: B[rand()] - random access pattern
        int rand_idx = rand() % N;
        B[rand_idx]++;
    }
}

int main() {
    // Test 1: N = 50
    int N1 = 50;
    int *A1 = (int *)calloc(N1, sizeof(int));
    int *B1 = (int *)calloc(N1, sizeof(int));
    pattern2_indirect_streams(A1, B1, N1);
    free(A1);
    free(B1);
    
    // Test 2: N = 100
    int N2 = 100;
    int *A2 = (int *)calloc(N2, sizeof(int));
    int *B2 = (int *)calloc(N2, sizeof(int));
    pattern2_indirect_streams(A2, B2, N2);
    free(A2);
    free(B2);
    
    return 0;
}
