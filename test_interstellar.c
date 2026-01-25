// Simple test case for InterStellar Analysis Pass
// This should detect one direct stream with dynamic base

// void simple_loop(int *A, int N, int M) {
//     for (int i = 1; i < 20; i+=2) {
//         A[i+2] = i + 1;
//     }
// }

// // Test with static array
// int global_array[1000];

// void static_loop(int N) {
//     for (int i = 0; i < N; i++) {
//         global_array[i] = i;
//     }
// }

// // Test with multiple streams
// void multi_stream(int *A, int *B, int N) {
//     for (int i = 0; i < N+2; i+=2) {
//         A[i] = B[i] + 1;
//     }
// }

// // Nested loops
void nested_loops(int *A, int N, int M) {
    for (int i = 0; i < N; i++) {
        for (int j = 0; j < M; j++) {
            A[i * M + j] = 0;
        }
    }
}
