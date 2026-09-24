#include<Assignment1/bfs.h>
#include<Assignment1/timing.h>


int main(int argc, char *argv[])
{
    if (argc != 2) {
        std::cerr << "Usage: " << argv[0] << " <graph.mtx>" << std::endl;
        return 1;
    }
    std::string filename = argv[1];
    Graph g;
    Timer timer;
    std::cout<<"Reading graph from file: "<<filename<<std::endl;
    timer.start();
    g.readGraph(filename);
    timer.stop();
    std::cout << "Graph reading elapsed time: " << timer.elapsedMilliseconds() << "ms" << std::endl;
    
    std::vector<bool> visited;
    int startVertex = 0; // Starting vertex for BFS
    timer.start();
    bfs_visit(g, startVertex, visited);
    timer.stop();
    std::cout << "BFS elapsed time: " << timer.elapsedMilliseconds() << " ms" << std::endl;

    for(int i = 0; i < visited.size(); ++i) {
        std::cout << "Vertex: " << i << ", Visited: " << visited[i] << std::endl;
    }
    
    return 0;
}    
