# Assignment1

Build and run the BFS level test from the repository root:

```sh
cmake -S . -B build
cmake --build build --target test_bfs
./build/app/test_bfs data/test.mtx
```

The test starts BFS at vertex `0` and prints each vertex's level. A level of
`-1` means the vertex is unreachable from the starting vertex.

The test also reports elapsed BFS time in milliseconds using the `Timer` class
in `include/Assignment1/timing.h`:

```cpp
#include <Assignment1/timing.h>

Timer timer;
timer.start();
bfs_level(g, startVertex, visited);
timer.stop();
std::cout << timer.elapsedMilliseconds() << " ms\n";
```

Use `elapsedSeconds()` for seconds. Construction starts the timer automatically.
Calling `start()` resets the measurement; `stop()` saves the end time.
The BFS measurement includes its internal
`Visited:` output, but excludes reading the graph and printing the final levels.

Generate an undirected Erdos-Renyi random graph with 1,000,000 vertices:

```sh
python3 -m pip install networkx
python3 data/random-graph.py
```

This writes `data/random-graph.mtx` in the format accepted by the C++ graph
reader. The default expected average degree is 10 (about 5,000,000 edges), with
edge probability `p = 10 / (1000000 - 1)` and random seed 42. The graph is held
in memory by NetworkX; edges are written directly without creating a matrix.
Use `--average-degree`, `--vertices`, `--seed`, and `--output` to change these
settings, for example:

```sh
python3 data/random-graph.py --vertices 1000 --average-degree 4 --output data/small-random.mtx
./build/app/test_bfs data/small-random.mtx
```
