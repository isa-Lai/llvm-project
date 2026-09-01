// PATTERN A: Multiple Loop Types - Pure Loop Constructs
// Testing various loop constructs: for, while, do-while
// Multi-layer nested loops with calculations only (no arrays)

#include <stdio.h>
#include <stdlib.h>
#include <time.h>

int main(int argc, char *argv[]) {
    // Use argc to prevent optimization
    volatile int seed = (argc > 1) ? atoi(argv[1]) : (int)time(NULL);
    int sum = seed;
    int result = seed % 100;
    int counter = seed % 50;
    
    // Dynamic bounds based on seed
    int bound1 = 80 + (seed % 40);    // 80-120
    int bound2 = 50 + (seed % 30);    // 50-80
    int bound3 = 10 + (seed % 20);    // 10-30
    
    // ===================================================================
    // Loop Type 1: Standard for loop with dynamic bound
    // ===================================================================
    for (int i = 0; i < bound1; i++) {
        sum += i + result;
        result += (i * 2 + 3 + sum) % 1000;
    }
    
    // ===================================================================
    // Loop Type 2: While loop with step size 2
    // ===================================================================
    int i = 0;
    while (i < bound2) {
        counter += i * 3 + result;
        result += (counter + sum) % 100;
        i += 2;  // Step size of 2
    }
    
    // ===================================================================
    // Loop Type 3: Do-while loop with step size 3 and dynamic bound
    // ===================================================================
    int j = 0;
    int bound_j = 60 + (result % 30);  // Dynamic bound 60-90
    do {
        sum = sum + j * j + counter;
        counter = (counter + j + result) % 200;
        j += 3;  // Step size of 3
    } while (j < bound_j);
    
    // ===================================================================
    // Loop Type 4: For loop with multiple inner loops and varying steps
    // ===================================================================
    int outer_bound = 15 + (counter % 10);  // Dynamic outer bound
    for (int i = 0; i < outer_bound; i += 2) {  // Step size of 2
        // First inner loop with dynamic bound
        int inner_bound1 = 15 + (i % 10);
        for (int j = 0; j < inner_bound1; j++) {
            result += i + j + counter;
            sum += result;
        }
        
        // Second inner loop with step size 3
        for (int k = 0; k < 15; k += 3) {  // Step size of 3
            counter += k * 2 + result;
            result += (i * k + sum) % 500;
        }
    }
    
    // ===================================================================
    // Loop Type 5: Triple nested for loops with different step sizes
    // ===================================================================
    for (int i = 0; i < 10; i += 1) {
        int bound_j = 8 + (i % 5);  // Dynamic middle bound
        for (int j = 0; j < bound_j; j += 2) {  // Step size of 2
            for (int k = 0; k < 10; k += 3) {  // Step size of 3
                result += i * 100 + j * 10 + k + sum % 37;
                sum = (sum + result + counter) % 10000;
                counter += (result % 13);
            }
        }
    }
    
    // ===================================================================
    // Loop Type 6: While loop with step 4 and nested for with dynamic bound
    // ===================================================================
    int outer = 0;
    int while_bound = 12 + (sum % 8);  // Dynamic bound
    while (outer < while_bound) {
        int inner_bound = 10 + (outer % 8);  // Dynamic inner bound
        for (int inner = 0; inner < inner_bound; inner += 2) {  // Step size of 2
            result += outer * inner;
            sum += result;
            counter = (counter + outer + inner) % 500;
        }
        outer += 4;  // Step size of 4
    }
    
    // ===================================================================
    // Loop Type 7: Do-while with nested while loop
    // ===================================================================
    int p = 0;
    do {
        int q = 0;
        while (q < 10) {
            result += p * q + p + q;
            sum = (sum + result) % 1000;
            q++;
        }
        p++;
    } while (p < 20);
    
    // ===================================================================
    // Loop Type 8: For loop with nested do-while
    // ===================================================================
    for (int i = 0; i < 30; i++) {
        int m = 0;
        do {
            counter += i + m;
            result += i * m * m;
            sum = (sum + result) % 2000;
            m++;
        } while (m < 8);
    }
    
    // ===================================================================
    // Loop Type 9: Mixed nested loops (for + while + do-while)
    // ===================================================================
    for (int i = 0; i < 10; i++) {
        int j = 0;
        while (j < 10) {
            int k = 0;
            do {
                result += i + j + k;
                sum += result * result;
                counter = (counter + result) % 300;
                k++;
            } while (k < 5);
            j++;
        }
    }
    
    // ===================================================================
    // Loop Type 10: For loop with multiple sequential inner loops, various steps
    // ===================================================================
    for (int i = 0; i < 15; i++) {
        // First nested loop with step 5
        int bound_j = 15 + (i % 10);
        for (int j = 0; j < bound_j; j += 5) {  // Step size of 5
            result += i * j;
            sum = (sum + result) % 5000;
        }
        
        // Second nested loop with step 7
        for (int k = 0; k < 25; k += 7) {  // Step size of 7
            counter += i + k;
            result += (i + k) * (i - k + 10);
        }
        
        // Third nested loop with dynamic bound
        int bound_m = 8 + (counter % 6);
        for (int m = 0; m < bound_m; m += 2) {  // Step size of 2
            sum += i + m;
            result += i * i + m * m;
        }
    }
    
    // ===================================================================
    // Loop Type 11: For loop with step 6, break/continue, dynamic bound
    // ===================================================================
    int break_bound = 50 + (result % 30);  // Dynamic break point
    for (int i = 0; i < 100; i += 6) {  // Step size of 6
        if (i % 3 == 0) continue;
        result += i * 2;
        sum += result;
        if (i > break_bound) break;
        counter++;
    }
    
    // ===================================================================
    // Loop Type 12: While loop with complex nested structure
    // ===================================================================
    int x = 0;
    while (x < 30) {
        int y = 0;
        while (y < 30) {
            result += x * 30 + y;
            sum = (sum + result) % 3000;
            
            // Inner for loop within nested while
            for (int z = 0; z < 5; z++) {
                counter += x + y + z;
                result += x * y * z + 1;
            }
            y++;
        }
        x++;
    }
    
    // ===================================================================
    // Loop Type 13: Four-level nested loops with varying steps
    // ===================================================================
    for (int i = 0; i < 5; i++) {
        int bound_j = 4 + (i % 3);  // Dynamic bound 4-6
        for (int j = 0; j < bound_j; j += 2) {  // Step size of 2
            for (int k = 0; k < 5; k++) {
                for (int m = 0; m < 5; m += 2) {  // Step size of 2
                    result += i * 125 + j * 25 + k * 5 + m;
                    sum = (sum + i + j + k + m) % 4000;
                    counter += result % 100;
                }
            }
        }
    }
    
    // ===================================================================
    // Loop Type 14: For loop with multiple loop counters
    // ===================================================================
    for (int i = 0, j = 100; i < j; i++, j--) {
        result += i + j;
        sum += result;
        counter = (counter + i - j) % 600;
    }
    
    // ===================================================================
    // Loop Type 15: Nested loops with dynamic bounds and step 3
    // ===================================================================
    int bound_i = 15 + (counter % 10);  // Dynamic outer bound
    for (int i = 0; i < bound_i; i += 3) {  // Step size of 3
        int calc_i = i * 7 % 30;
        int bound_j = 12 + (i % 12);  // Dynamic inner bound
        for (int j = 0; j < bound_j; j += 4) {  // Step size of 4
            int calc_j = j * 11 % 30;
            result += calc_i * calc_j;
            sum = (sum + result) % 8000;
            counter += calc_i + calc_j;
        }
    }
    
    // ===================================================================
    // Loop Type 16: Do-while with nested for and while
    // ===================================================================
    int outer2 = 0;
    do {
        for (int mid = 0; mid < 10; mid++) {
            int inner2 = 0;
            while (inner2 < 10) {
                result += outer2 + mid + inner2;
                sum += result;
                counter = (counter + result * result) % 1500;
                inner2++;
            }
        }
        outer2++;
    } while (outer2 < 50);
    
    // ===================================================================
    // Loop Type 17: Five-level nested loops with different steps
    // ===================================================================
    for (int a = 0; a < 3; a++) {
        for (int b = 0; b < 3; b++) {
            int bound_c = 2 + (a % 2);  // Dynamic bound 2-3
            for (int c = 0; c < bound_c; c++) {
                for (int d = 0; d < 3; d++) {
                    for (int e = 0; e < 3; e++) {
                        result += a + b + c + d + e;
                        sum = (sum + result) % 6000;
                        counter += a * b * c * d * e + 1;
                    }
                }
            }
        }
    }
    
    // ===================================================================
    // Loop Type 18: While with nested do-while and for
    // ===================================================================
    int w = 0;
    while (w < 20) {
        int v = 0;
        do {
            for (int u = 0; u < 8; u++) {
                result += (w * v * u + sum) % 1000;
                sum += result % 100 + counter;
                counter = (counter + w + v + u + result) % 2500;
            }
            v++;
        } while (v < 12);
        w++;
    }
    
    // ===================================================================
    // Loop Type 19: Dynamic start value - from computation
    // ===================================================================
    int start_offset = 5 + (counter % 15);  // Dynamic start: 5-20
    for (int i = start_offset; i < 50; i++) {  // Start is runtime-computed
        result += i * 3;
        sum = (sum + result) % 7000;
        counter += i;
    }
    
    // ===================================================================
    // Loop Type 20: Triangular loop - inner start depends on outer variable
    // ===================================================================
    for (int i = 0; i < 10; i++) {
        // Inner loop starts at 'i' (outer loop variable) - classic triangular pattern
        for (int j = i; j < 15; j++) {  // Dynamic start: j = i
            result += i * 10 + j;
            sum = (sum + result) % 9000;
            counter += (i + j) % 100;
        }
    }
    
    // ===================================================================
    // Loop Type 21: Multiple dynamic starts from outer loop
    // ===================================================================
    for (int i = 0; i < 8; i++) {
        int start_k = i * 2;  // Dynamic start computed from outer variable
        for (int k = start_k; k < 30; k += 2) {  // Start varies with i
            result += i * k;
            sum += result;
            counter = (counter + k) % 800;
        }
    }
    
    // ===================================================================
    // Loop Type 22: Nested triangular with both dynamic start and end
    // ===================================================================
    int outer_limit = 12 + (sum % 8);  // Dynamic outer bound
    for (int i = 0; i < outer_limit; i++) {
        int inner_start = i;  // Dynamic start
        int inner_limit = 20 - i;  // Dynamic end
        for (int j = inner_start; j < inner_limit; j++) {
            result += i + j;
            sum = (sum + result) % 11000;
            counter += (i * j) % 50;
        }
    }
    
    // Print results to prevent dead code elimination
    printf("Final results: sum=%d, result=%d, counter=%d\n", sum, result, counter);
    
    return (sum + result + counter) % 256;
}
