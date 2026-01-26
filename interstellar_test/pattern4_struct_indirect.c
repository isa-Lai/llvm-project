// PATTERN 4: Struct Indirect Streams
// points[A[i]].x, points[A[i]].y, points[rand()].z

#include <stdio.h>
#include <stdlib.h>

struct Point {
    int x;
    int y;
    int z;
};

void pattern4_struct_indirect(int *A, struct Point *points, int N) {
    for (int i = 0; i < N; i++) {
        // Indirect struct access using A as index
        int idx = A[i];
        if (idx >= 0 && idx < N) {
            points[idx].x += 10; //pending issue
            points[idx].y += 20;
        }
        
        // Indirect struct access using rand()
        int rand_idx = rand() % N;
        points[rand_idx].z += 100;
    }
}

int main() {
    // Test 1: N = 50
    int N1 = 50;
    int *A1 = (int *)calloc(N1, sizeof(int));
    struct Point *points1 = (struct Point *)calloc(N1, sizeof(struct Point));
    pattern4_struct_indirect(A1, points1, N1);
    free(A1);
    free(points1);
    
    // Test 2: N = 100
    int N2 = 100;
    int *A2 = (int *)calloc(N2, sizeof(int));
    struct Point *points2 = (struct Point *)calloc(N2, sizeof(struct Point));
    pattern4_struct_indirect(A2, points2, N2);
    free(A2);
    free(points2);
    
    return 0;
}
