// PATTERN 4: Struct Indirect Streams
// points[A[i]].x, points[A[i]].y, points[rand()].z

struct Point {
    int x;
    int y;
    int z;
};

void pattern4_struct_indirect(int *A, struct Point *points, int N) {
    // Deterministic pseudo-random state (no libc dependency).
    unsigned state = 0x12345678u;

    for (int i = 0; i < N; i++) {
        // Indirect struct access using A as index
        int idx = A[i];
        if (idx >= 0 && idx < N) {
            points[idx].x += 10;
            points[idx].y += 20;
        }
        
        // Indirect struct access using pseudo-random index.
        state = state * 1664525u + 1013904223u;
        int rand_idx = (int)(state % (unsigned)N);
        points[rand_idx].z += 100;
    }
}
