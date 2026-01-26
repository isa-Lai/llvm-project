// PATTERN 3: Struct Direct Streams
// points[i].x, points[i].y, points[i].z

#include <stdio.h>
#include <stdlib.h>

struct Point {
    int x;
    int y;
    int z;
};

void pattern3_struct_direct(struct Point *points, int N) {
    for (int i = 0; i < N; i++) {
        // Direct struct streams
        points[i].x++;
        points[i].y += 2;
        points[i].z += 3;
    }
}

int main() {
    // Test 1: N = 50
    int N1 = 50;
    struct Point *points1 = (struct Point *)calloc(N1, sizeof(struct Point));
    pattern3_struct_direct(points1, N1);
    free(points1);
    
    // Test 2: N = 100
    int N2 = 100;
    struct Point *points2 = (struct Point *)calloc(N2, sizeof(struct Point));
    pattern3_struct_direct(points2, N2);
    free(points2);
    
    return 0;
}
