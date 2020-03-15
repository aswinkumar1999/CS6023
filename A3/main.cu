// What happens :
//    CPU -> Get Inputs from File -> Remove Character + Pre-processing
//         -> Make an Instrcution Table -> GPU
//    GPU -> Use Atomics to Add Values
//
// time : < 0.1 sec for 980m
//
// Uses : CUDA : Unified Memory
//        C++  : Vectors , Map , String Functions
//
//

// Include All Libraries
#include <bits/stdc++.h>

using namespace std;

__global__ void add(int n, int *x, int *y,int *val,int *database,int N)
{
  unsigned long long int id = (blockIdx.x*blockDim.y+threadIdx.y)*blockDim.x + threadIdx.x;
  if(id<n){
    atomicAdd(&database[N*x[id]+y[id]-1],val[id]);
  }
}

struct ins_tab{
  int row;
  int col;
  int val;
};

int main(int argc, char** argv){

  fstream file_input,file_output;
  int *m,*n,*p;
  int *database;
  int *row,*col,*val;
  // opening file_input
  file_input.open(argv[1]);
  // Allocate Unified Memory -- accessible from CPU or GPU
  cudaMallocManaged(&m,sizeof(int));
  cudaMallocManaged(&n,sizeof(int));
  cudaMallocManaged(&p,sizeof(int));
  // Get Value of M,N;
  file_input>>m[0]>>n[0];
  // Allocate Arrays for Database
  cudaMallocManaged(&database,(m[0])*(n[0])*sizeof(int));
  // Get Database Value;
  for(int i=0;i<(*m)*(*n);i++){
    file_input>>database[i];
  }
  //Get Instructions Values
  file_input>>*p;
  string inp[p[0]],temp;
  getline(file_input,temp);
  for(int i=0;i<*p;i++){
    getline(file_input,inp[i]);
  }
  file_input.close();

  // Generate Instruction Table
  vector<ins_tab> tab;
  // Recurse through the string;
  // Tokenise String

  //Loop through strings

  for(int i=0;i<*p;i++){
    // God Functions to save me so much time , Also the Reason why Python is <3
    // Remove C , U and other strings
    inp[i].erase(std::remove(inp[i].begin(), inp[i].end(), 'U'), inp[i].end());
    inp[i].erase(std::remove(inp[i].begin(), inp[i].end(), 'C'), inp[i].end());
    // Change + to 1 and - to 0
    map<char, char> rs = { {'+', '1'}, {'-', '0'} }; char r;
    replace_if(inp[i].begin(), inp[i].end(), [&](char c){ return (rs.find(c) != rs.end())&& (r = rs[c]); }, r);
    // Returns first token
    int t = inp[i].length();
    // Declaring character array
    char char_array[t + 1];
    // copying the contents of the  string to char array
    strcpy(char_array, inp[i].c_str());
    // Keep printing tokens while one of the delimiters present in str[].
    char *token = strtok(char_array, " ");
    vector<int> ps;
    while (token != NULL)
    {
      string s = token;
      ps.push_back(stoi(s));
      token = strtok(NULL, " ");
    }
    // Currently having ps ( processed string )
    // ps[0] = which column
    // ps[1] = column value
    // ps[2] = how many instruction

    // Loop through Possible Rows
      for(int j=0;j<m[0];j++){
      int row_val = ps[1]; // column value
      if(database[ps[0]-1+j*n[0]]==row_val){ // if column value matches in a row
      // Row is j
      // Loop through Instructions
            for (int k=1;k<=ps[2];k++){
              tab.push_back({j,ps[3*(k)],ps[3*k+2]? ps[3*k+1] : -1 * ps[3*k+1] });
            }
        }
      }
    }

// Print Instrcution Table -For  Debug
  // for (int i=0;i<s;i++)
  //   {
  //       Accessing structure members using their
  //       names.
  //       cout << tab[i].row << ", " << tab[i].col << ", "<< tab[i].val<< endl;
  //   }

// CPU - Do Instructions as per Instruction Table;

  // int s = tab.size();
  // for (int i=0;i<s;i++)
  //   {
  //       // Accessing structure members using their names.
  //       database[n[0]*tab[i].row+tab[i].col-1]+=tab[i].val;
  //   }
  // for (auto i = ps.begin(); i != ps.end(); ++i)
  //     //cout << *i << " ";

// Transfer instruction table to GPU
 int s = tab.size();
    cudaMallocManaged(&row,s*sizeof(int));
    cudaMallocManaged(&col,s*sizeof(int));
    cudaMallocManaged(&val,s*sizeof(int));

  // Copy arrays
  for (int i=0;i<s;i++)
    {
        row[i]=tab[i].row;
        col[i]=tab[i].col;
        val[i]=tab[i].val;
    }

  // GPU Code

  // Launch kernel on  elements on the GPU
  int blockSize = 512;
  int numBlocks = (s + blockSize - 1) / blockSize;
  add<<<numBlocks, blockSize>>>(s, row, col,val,database,n[0]);
  // Wait for GPU to finish before accessing on host
  cudaDeviceSynchronize();

  // Preare Output file
  file_output.open(argv[2],ios::trunc | ios::out);

  // Print Table out
  for(int i=0;i<(*m)*(*n);i++){
      if(i!=0 && i%*n==0){
        file_output<<"\n";
      }
      file_output<<database[i]<<" ";
  }
  // Added this because Downloading File and Doing diff my_output.txt output.txt
  // Threw me an Error saying the output.txt had an Newline in the end.
  file_output<<"\n";
  // Close File
  file_output.close();
  return 0;
}
