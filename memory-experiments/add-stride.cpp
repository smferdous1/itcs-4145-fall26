#include <cstdio>
#include <vector>
#include <chrono>

constexpr long N = 64L * 1024 * 1024;   // 64M ints = 256 MB

double run(std::vector<int>& arr, int K) {
    auto t0 = std::chrono::steady_clock::now();
    for (long i = 0; i < N; i += K) arr[i] *= 3;
    auto t1 = std::chrono::steady_clock::now();
    return std::chrono::duration<double, std::milli>(t1 - t0).count();
}

int main() {
    std::vector<int> arr(N, 1);          // allocates and touches all pages
    for (int K : {1, 2, 4, 8, 16, 32, 64, 128, 256, 512, 1024}) {
        run(arr, K);                     // warm up
        double a = run(arr, K), b = run(arr, K);
        std::printf("K=%4d  %7.1f ms\n", K, a < b ? a : b);
    }
    return 0;
}

