// Include All Libraries

#include<bits/stdc++.h>

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

  fstream file;
  int *m,*n,*p;
  int *database;
  int *row,*col,*val;
  // opening file
  file.open(argv[1]);
  // Allocate Unified Memory -- accessible from CPU or GPU
  cudaMallocManaged(&m,sizeof(int));
  cudaMallocManaged(&n,sizeof(int));
  cudaMallocManaged(&p,sizeof(int));
  // Get Value of M,N;
  file>>m[0]>>n[0];
  // Allocate Arrays for Database
  cudaMallocManaged(&database,(m[0])*(n[0])*sizeof(int));
  // Get Database Value;
  for(int i=0;i<(*m)*(*n);i++){
    file>>database[i];
  }
  //Get Instructions Values
  file>>*p;
  string inp[p[0]],temp;
  getline(file,temp);
  for(int i=0;i<*p;i++){
    getline(file,inp[i]);
  }

  // Print instruction values
  //cout<<"\n";
  //cout<<"\n";
  //cout<<m[0]<<" "<<n[0]<<"\n";
  for(int i=0;i<(*m)*(*n);i++){
      if(i!=0 && i%*n==0){
        //cout<<"\n";
      }
      //cout<<database[i]<<" ";
  }
  //cout<<"\n";
  //cout<<*p<<"\n";
  // for(int i=0;i<*p;i++){
  //   //cout<<i<<" "<<inp[i]<<"\n";
  // }
  //cout<<"\n";

  // Generate Instruction Table
  vector<ins_tab> tab;
  // Recurse through the string;
// Tokenise String

//Loop through strings
#pragma omp parallel
#pragma omp for
  for(int i=0;i<*p;i++){
    // God Functions to save me so much time , Also the Reason why Python is <3
    // Remove C , U and other strings
    inp[i].erase(std::remove(inp[i].begin(), inp[i].end(), 'U'), inp[i].end());
    inp[i].erase(std::remove(inp[i].begin(), inp[i].end(), 'C'), inp[i].end());
    map<char, char> rs = { {'+', '1'}, {'-', '0'} }; char r;
    replace_if(inp[i].begin(), inp[i].end(), [&](char c){ return (rs.find(c) != rs.end())&& (r = rs[c]); }, r);
    // Returns first token
    int t = inp[i].length();
    // declaring character array
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

     // for (auto i = ps.begin(); i != ps.end(); ++i)
         //cout << *i << " ";

    //cout<<"\n";
    // Currently having ps ( processed string )
    // ps[0] = which column
    // ps[1] = column value
    // ps[2] = how many instruction

// Loop through Possible Rows
    //cout<<ps[1]<<"\n";
    for(int j=0;j<m[0];j++){
      //cout<<j<<"\t";
      int row_val = ps[1];
      //cout<<row_val<<"\t"<<database[ps[0]+j*n[0]]<<"\t";
      if(database[ps[0]-1+j*n[0]]==row_val){
            // Row is j
// // Loop through Instructions
            for (int k=1;k<=ps[2];k++){

              //cout<<" "<<j<<" "<<ps[3*(k)]<<" "<< ( ps[3*k+2]==1 ? ps[3*k+1] : -1 * ps[3*k+1] ) ;
              tab.push_back({j,ps[3*(k)],ps[3*k+2]? ps[3*k+1] : -1 * ps[3*k+1] });
            }
        }
      //cout<<"\n";
      }
      //cout<<"\n";
  }

  // Print Instrcution Table
  int s = tab.size();
  for (int i=0;i<s;i++)
    {
        // Accessing structure members using their
        // names.
        cout << tab[i].row << ", " << tab[i].col << ", "<< tab[i].val<< endl;
    }

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

  // // Do Instructions as per Instruction Table;

  // int s = tab.size();
  // for (int i=0;i<s;i++)
  //   {
  //       // Accessing structure members using their names.
  //       database[n[0]*tab[i].row+tab[i].col-1]+=tab[i].val;
  //   }
  // for (auto i = ps.begin(); i != ps.end(); ++i)
  //     //cout << *i << " ";
  for(int i=0;i<(*m)*(*n);i++){
      if(i!=0 && i%*n==0){
        cout<<"\n";
      }
      cout<<database[i]<<" ";
  }
  //cout<<"\n";
// }
  return 0;
}
