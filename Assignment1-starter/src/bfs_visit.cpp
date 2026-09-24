#include<iostream>
#include<Assignment1/graph.h>

void bfs_visit(Graph &g, int startVertex, std::vector<bool> &visited) {
    int numVertices = g.getNumberOfVertices();
    std::queue<int> q;
    visited.assign(numVertices, false);
    visited[startVertex] = true;
    q.push(startVertex);

    while (!q.empty()) {
        int currentVertex = q.front();
        q.pop();
        //std::cout << "Visited: " << currentVertex << std::endl;

        // Assuming g has a method to get adjacent vertices
        for(int j=g.IA[currentVertex];j<g.IA[currentVertex+1];j++){
            int neighbor = g.JA[j];
            if (!visited[neighbor]) {
                visited[neighbor] = true;
                q.push(neighbor);
            }
        }
    }
}