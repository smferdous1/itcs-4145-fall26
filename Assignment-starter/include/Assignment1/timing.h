#pragma once

#include <chrono>

class Timer {
public:
    Timer() {
        start();
    }

    // Start a new measurement, replacing any previous measurement.
    void start() {
        start_time = Clock::now();
        end_time = start_time;
        running = true;
    }

    // Save the end time. Repeated calls preserve the completed measurement.
    void stop() {
        if (running) {
            end_time = Clock::now();
            running = false;
        }
    }

    // Return live elapsed time while running, or the saved result after stop().
    double elapsedSeconds() const {
        const auto end = running ? Clock::now() : end_time;
        return std::chrono::duration<double>(end - start_time).count();
    }

    double elapsedMilliseconds() const {
        return elapsedSeconds() * 1000.0;
    }

private:
    // A monotonic clock measures elapsed time independently of clock changes.
    using Clock = std::chrono::steady_clock;
    Clock::time_point start_time{};
    Clock::time_point end_time{};
    bool running = false;
};
