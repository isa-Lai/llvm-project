// PATTERN 9: Mixed Direct and Indirect Streams
// Combining multiple patterns in single loop

#include <stdio.h>
#include <stdlib.h>

struct Point {
    int x;
    int y;
    int z;
};

void pattern9_mixed(int *A, int *B, struct Point *points, int D2B[][10], int N) {
    for (int i = 0; i < N && i < 10; i++) { // loop issue here 
        // A direct, B indirect through A
        int idx = A[i] % N;
        B[idx] = A[i] + 100;
        
        // Struct direct and indirect
        points[i].x = B[idx];
        points[idx].y = A[i];
        
        // 2D direct and indirect
        for (int j = 0; j < 10; j++) {
            D2B[i][j] = A[i] + j;
            D2B[idx % 10][j] = B[idx] - j;
            D2B[idx % 10][j+1] = B[idx+j] - j;
        }
    }
}

int main() {
    // Test 1: N = 50
    int N1 = 50;
    int *A1 = (int *)calloc(N1, sizeof(int));
    int *B1 = (int *)calloc(N1, sizeof(int));
    struct Point *points1 = (struct Point *)calloc(N1, sizeof(struct Point));
    int (*D2B1)[10] = calloc(10, sizeof(*D2B1));
    pattern9_mixed(A1, B1, points1, D2B1, N1);
    free(A1);
    free(B1);
    free(points1);
    free(D2B1);
    
    // Test 2: N = 100
    int N2 = 100;
    int *A2 = (int *)calloc(N2, sizeof(int));
    int *B2 = (int *)calloc(N2, sizeof(int));
    struct Point *points2 = (struct Point *)calloc(N2, sizeof(struct Point));
    int (*D2B2)[10] = calloc(10, sizeof(*D2B2));
    pattern9_mixed(A2, B2, points2, D2B2, N2);
    free(A2);
    free(B2);
    free(points2);
    free(D2B2);
    
    return 0;
}
