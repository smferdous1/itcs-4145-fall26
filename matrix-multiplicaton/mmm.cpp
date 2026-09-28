#include <cstdio>
#include <cstdlib>
#include <vector>
#include <chrono>

// C = A * B, N x N doubles, stored row-major in flat vectors: X[i*N + j]
// usage: ./mmm [N]   (default 1100)

using Mat = std::vector<double>;
static long N = 1100;

#define IDX(i,j) ((long)(i)*N + (j))
#define BODY C[IDX(i,j)] += A[IDX(i,k)] * B[IDX(k,j)]

void ijk(const Mat& A, const Mat& B, Mat& C) {
    for (long i = 0; i < N; i++) for (long j = 0; j < N; j++) for (long k = 0; k < N; k++) BODY;
}
void ikj(const Mat& A, const Mat& B, Mat& C) {
    for (long i = 0; i < N; i++) for (long k = 0; k < N; k++) for (long j = 0; j < N; j++) BODY;
}
void jik(const Mat& A, const Mat& B, Mat& C) {
    for (long j = 0; j < N; j++) for (long i = 0; i < N; i++) for (long k = 0; k < N; k++) BODY;
}
void jki(const Mat& A, const Mat& B, Mat& C) {
    for (long j = 0; j < N; j++) for (long k = 0; k < N; k++) for (long i = 0; i < N; i++) BODY;
}
void kij(const Mat& A, const Mat& B, Mat& C) {
    for (long k = 0; k < N; k++) for (long i = 0; i < N; i++) for (long j = 0; j < N; j++) BODY;
}
void kji(const Mat& A, const Mat& B, Mat& C) {
    for (long k = 0; k < N; k++) for (long j = 0; j < N; j++) for (long i = 0; i < N; i++) BODY;
}

int main(int argc, char** argv) {
    if (argc > 1) N = std::atol(argv[1]);
    std::printf("N = %ld  (%.1f MB per matrix)\n", N, N * N * 8.0 / 1e6);
    Mat A(N*N), B(N*N), C(N*N);
    for (long x = 0; x < N*N; x++) { A[x] = 0.5 + x % 7; B[x] = 1.0 + x % 5; }

    struct { const char* name; void (*f)(const Mat&, const Mat&, Mat&); } orders[] = {
        {"ijk", ijk}, {"ikj", ikj}, {"jik", jik}, {"jki", jki}, {"kij", kij}, {"kji", kji}
    };
    for (auto& o : orders) {
        double best = 1e30;
        for (int r = 0; r < 2; r++) {
            std::fill(C.begin(), C.end(), 0.0);
            auto t0 = std::chrono::steady_clock::now();
            o.f(A, B, C);
            auto t1 = std::chrono::steady_clock::now();
            double ms = std::chrono::duration<double, std::milli>(t1 - t0).count();
            if (ms < best) best = ms;
        }
        double sum = 0;
        for (long x = 0; x < N*N; x += N + 1) sum += C[x];   // checksum
        double gf = 2.0 * N * (double)N * N / (best * 1e6);
        std::printf("%s  %8.0f ms  %5.2f Gflop/s  (check %.6e)\n", o.name, best, gf, sum);
    }
    return 0;
}