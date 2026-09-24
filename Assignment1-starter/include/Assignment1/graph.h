#pragma once

#include<iostream>
#include<fstream>
#include<cstdlib>
#include<string>
#include<vector>

class Graph {
    public:
        std::vector<int> IA;
        std::vector<int> JA;
        Graph(int vertices);
        Graph(){};
        void readGraph(std::string filename);
        int getNumberOfVertices(){return numberOfVertices;}
        int getNumberOfEdges(){return numberOfEdges;}
        void setNumberOfVertices(int vertices){
            numberOfVertices = vertices;
        }
        void setNumberOfEdges(int edges){
            numberOfEdges = edges;
        }
        void printGraph();
    private:
        int numberOfVertices;
        int numberOfEdges;
};

inline void Graph::readGraph(std::string fileName){
    
    std::ifstream fileread(fileName.c_str());
    if(fileread.is_open()==false)
    {
        std::cout << "No file named "<<fileName<<std::endl;
        std::exit(1);
    }
    
    //Read the mtx header to determine file type 
    std::string header[6];
    fileread>>header[0]>>header[1]>>header[2]>>header[3]>>header[4];

    std::string weightType = header[3];
    fileread.seekg(0, std::ios::beg); 
    //Ignore header and comments
    while (fileread.peek() == '%') fileread.ignore(2048, '\n');

    int nrow,ncol;
    int nnz;
    fileread >> nrow >> ncol >> nnz;
    std::cout<<"The number of vertices is: "<<nrow<<std::endl;
    std::vector<std::vector<int> > adjList(nrow);

    int u;
    int v;
    int nEdge = 0;
    for(int i=0;i<nnz;i++)
    {
        double weight = 1.0;
        if(weightType.compare("pattern") != 0)
            fileread >> v >> u >> weight;
        else
            fileread >> v >> u;
        v--;
        u--;
        if(u<v)
        {
            adjList[u].push_back(v);
            adjList[v].push_back(u);
            nEdge++;
        }
    }
    setNumberOfEdges(nEdge);
    setNumberOfVertices(nrow);

    IA.resize(nrow + 1);
    JA.resize(2 * nEdge);

    // Second pass. Build the CSR vectors.
    IA[0] = 0;
    int k=0;
    for(int i=0;i<nrow;i++)
    {
        for(int j=0;j<adjList[i].size();j++)
        {
            JA[k] = adjList[i][j];
            k++;
        }
        IA[i+1]= IA[i] + adjList[i].size();
    }


}

inline void Graph::printGraph()
{
   std::cout<<"The number of vertices is: "<<getNumberOfVertices()<<std::endl;
   std::cout<<"The number of edges is: "<<getNumberOfEdges()<<std::endl;

   std::cout<<"The edges are: "<<std::endl;
   for(int i=0;i<getNumberOfVertices();i++)
   {
       for(int j=IA[i];j<IA[i+1];j++)
       {
           std::cout<<i<<" "<<JA[j]<<std::endl;
       }
    }
}
