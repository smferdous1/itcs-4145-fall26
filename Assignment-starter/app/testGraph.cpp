#include<iostream>
#include<Assignment1/graph.h>

int main(int argc, char *argv[])
{
    std::string filename = argv[1];
    Graph g;
    std::cout<<"Reading graph from file: "<<filename<<std::endl;
    g.readGraph(filename);
    g.printGraph();
    return 0;
}