// PATTERN 1: Direct Streams on Array A (No stdio version)
// A[i]++, A[i+2]++, A[i*2]++, A[i*3+3]++

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

// Global array for testing constant base address
#define GLOBAL_SIZE 200
int GlobalArray[GLOBAL_SIZE];

void pattern1_global_array(int N) {
    // Initialize global array
    for (int i = 0; i < GLOBAL_SIZE; i++) {
        GlobalArray[i] = 0;
    }
    
    for (int i = 0; i < N && i < GLOBAL_SIZE; i++) {
        // Direct stream: GlobalArray[i] with unit stride, constant base
        GlobalArray[i]++;
        
        // Direct stream: GlobalArray[i+5] with offset, constant base
        if (i + 5 < GLOBAL_SIZE) {
            GlobalArray[i + 5]++;
        }
        
        // Direct stream: GlobalArray[i*2] with stride 8, constant base
        if (i * 2 < GLOBAL_SIZE) {
            GlobalArray[i * 2]++;
        }
    }
}
