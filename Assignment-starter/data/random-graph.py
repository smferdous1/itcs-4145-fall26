#!/usr/bin/env python3
"""Generate an undirected Erdos-Renyi graph for the C++ graph reader."""

import argparse
from pathlib import Path

import networkx as nx


def write_matrix_market(graph: nx.Graph, output: Path) -> None:
    """Write each edge once, using one-based lower-triangle coordinates."""
    output.parent.mkdir(parents=True, exist_ok=True)
    with output.open("w", encoding="utf-8", buffering=1024 * 1024) as stream:
        stream.write("%%MatrixMarket matrix coordinate pattern symmetric\n")
        stream.write("% Undirected Erdos-Renyi graph generated with NetworkX.\n")
        vertices = graph.number_of_nodes()
        stream.write(f"{vertices} {vertices} {graph.number_of_edges()}\n")
        # readGraph() retains entries only when the row is greater than the column.
        for u, v in graph.edges():
            stream.write(f"{max(u, v) + 1} {min(u, v) + 1}\n")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--vertices", type=int, default=1_000_000,
        help="number of vertices (default: 1000000)",
    )
    parser.add_argument(
        "--average-degree", type=float, default=10.0,
        help="expected average degree (default: 10)",
    )
    parser.add_argument(
        "--seed", type=int, default=42,
        help="random seed for reproducible generation (default: 42)",
    )
    parser.add_argument(
        "--output", type=Path,
        default=Path(__file__).resolve().with_name("random-graph.mtx"),
        help="output file (default: random-graph.mtx beside this script)",
    )
    args = parser.parse_args()

    if args.vertices < 1:
        parser.error("--vertices must be at least 1")
    if not 0 <= args.average_degree <= args.vertices - 1:
        parser.error("--average-degree must be between 0 and vertices - 1")

    # E[degree] = p * (n - 1); the defaults give about 5 million edges.
    probability = args.average_degree / (args.vertices - 1) if args.vertices > 1 else 0.0
    print(
        f"Generating {args.vertices:,} vertices with p={probability:.8g} "
        f"and expected average degree {args.average_degree:g}...",
        flush=True,
    )
    # The fast generator is suitable for sparse graphs at this scale.
    graph = nx.fast_gnp_random_graph(
        args.vertices, probability, seed=args.seed, directed=False,
    )
    print(f"Writing {graph.number_of_edges():,} edges to {args.output}...", flush=True)
    write_matrix_market(graph, args.output)
    print("Done.")


if __name__ == "__main__":
    main()
