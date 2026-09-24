#include<iostream>
#include<chrono>
#include<vector>
#include<string>

int main(int argc, char *argv[]) {

  long long n = std::stoi(argv[1]); 
  
  std::cout <<"number of elements: "<<n<<std::endl;
  std::vector<double> a; 
  std::vector<double> b; 
  std::vector<double> c; 
  
  a.resize(n);
  b.resize(n);
  c.resize(n);
  
  for(auto i=0;i<n;i++){
    a[i] = i; 
    b[i] = i+1;
  }
  for(auto i=0;i<n;i++) {
    c[i] = a[i] + b[i]; 
  }
  /* 
  for(int i=0;i<n;i++) {
    std::cout<<c[i]<<std::endl; 
  }
  */
  return 0;
}

