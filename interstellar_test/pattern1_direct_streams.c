// PATTERN 1: Direct Streams on Array A
// A[i]++, A[i+2]++, A[i*2]++, A[i*3+3]++

#include <stdio.h>
#include <stdlib.h>

void pattern1_direct_streams(int *A, int N) {
    for (int i = 0; i < N; i++) {
        // Direct stream: A[i] with unit stride
        A[i]++;
        
        // Direct stream: A[i+2] with offset
        if (i + 2 < N) {
            A[i + 2]++;
        }
        
        // Direct stream: A[i*2] with stride 8 (i*2*4 bytes)
        if (i * 2 < N) {
            A[i * 2]++;
        }
        
        // Direct stream: A[i*3+3] with stride 12 and offset 12
        if (i * 3 + 3 < N) {
            A[i * 3 + 3]++;
        }
    }
}

int main() {
    // Test 1: N = 50
    int N1 = 50;
    int *A1 = (int *)calloc(N1, sizeof(int));
    pattern1_direct_streams(A1, N1);
    free(A1);
    
    // Test 2: N = 100
    int N2 = 100;
    int *A2 = (int *)calloc(N2, sizeof(int));
    pattern1_direct_streams(A2, N2);
    free(A2);
    
    return 0;
}
