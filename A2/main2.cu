#include <stdio.h>
#define min(X, Y) (((X) < (Y)) ? (X) : (Y))

// Kernel Function to Find Sum
__global__ void sumRandC (int* A, int* B, int m, int n, int k=1){
    // Get Id
    unsigned long long int id = ( blockIdx.x*blockDim.y+threadIdx.y)*blockDim.x + threadIdx.x;
    // For Selected threads
    if(id<(m*n)/k){
      for (int i=k*id;i<(k)*(id+1);i++){
        int n_new = i %(n);
        int m_new = i /(n);
        // Add values
        atomicAdd(&B[m_new*(n+1)+n], B[m_new*(n+1)+n_new]);
        atomicAdd(&B[m*(n+1)+n_new],  B[m_new*(n+1)+n_new]);
      }
    }
}

// Define Global Variable - Mini
__device__ int mini;
// Function to Find the Minimum value
__global__ void findMin (int* A, int* B, int m, int n, int k=1){
  // Create Thread ID
  unsigned long long int id = ( blockIdx.x*blockDim.y+threadIdx.y)*blockDim.x + threadIdx.x;
  // Initialise Mini with one element of first row
  if(id==0){
    mini=B[n];
  }
  // For Selected Threads we do Atomic Operation to compute min.
  if(id<(m+n)){
    if(id < m ){
      atomicMin(&mini,B[id*(n+1)+n]);
    }
    if(id>=m){
      atomicMin(&mini,B[m*n+id]);
    }
  }
}
// Kernel Function to Add minimum and update minimum
__global__ void updateMin (int* A, int* B, int m, int n, int k=1){
  // Get Thread ID
  unsigned long long int id = ( blockIdx.x*blockDim.y+threadIdx.y)*blockDim.x + threadIdx.x;
  // Set Last Element from Calculated Minimum
  if(id==0){
    B[m*(n+1)+n]=mini;
  }
  // Add Minimum to everything
  if(id<(m*n)/k){
    for (int i=k*id;i<(k)*(id+1);i++){
      int n_new = i %(n);
      int m_new = i /(n);
      B[m_new*(n+1)+n_new]+=mini;
    }
  }
}

// Helper Function to Print Matrix
void print_matrix(int* mat,int m, int n) {
    for(int i=0; i<m; i++) {
        for(int j=0; j<n; j++) {
            printf("%d ", mat[i*n + j]);
        }
        printf("\n");
    }
}
// CPU Computing Function
void cpu(int *in,int m,int n){
  //Row Computation
  int i,j,sum=0;
  for(i=0; i<m; i++) {
    sum=0;
      for(j=0; j<n; j++) {
              sum+=in[i*(n+1)+j];
      }
    in[i*(n+1)+n]=sum;
  }
  //Column Computation
  for(i=0; i<n; i++) {
    sum=0;
      for(j=0; j<m; j++) {
              sum+=in[j*(n+1)+i];
      }
    in[(n+1)*(m)+i]=sum;
  }
  // Find minimum
  long long int mini=100*max(m,n);
  for(i=0;i<n;i++){
    mini = min(mini,in[((m)*(n+1))+i]);
  }
  for(i=0;i<m;i++){
    mini = min(mini,in[(i)*(n+1)+n]);
  }
  in[(n+1)*(m)+n]=mini;
  // Add Minimum values to everything
  for(i=0; i<m; i++) {
      for(j=0; j<n; j++) {
              in[i*(n+1) + j] += mini;
      }
  }
}
// Helper Function to Check if CPU and GPU Computation are same.
bool check_same(int *C,int *D,int m,int n){
  for(int i=0; i<m*n; i++) {
        if(C[i]!=D[i]){
          printf("%d\t",i );
          printf("%d  %d\n",C[i],D[i]);
          // return false;
      }
  }
  return true;
}
int main()
{
    // Define and Initialize Variables
    long long unsigned M,N,K,i,j;
    scanf("%llu", &M);
    scanf("%llu", &N);
    scanf("%llu", &K);

    int* A_cin, * B_cin, *B_cout;
    int* A_gin, * B_gin, *B_gout;

    A_cin = (int*)malloc(M*N*sizeof(int));
    B_cin = (int*)malloc((M+1)*(N+1)*sizeof(int));
    cudaMalloc(&A_gin, M * N * sizeof(int));
    cudaMalloc(&B_gin, (M+1)*(N+1)*sizeof(int));

    B_cout = (int*)malloc((M+1)*(N+1)*sizeof(int));
    B_gout = (int*)malloc((M+1)*(N+1)*sizeof(int));

    // Initialize B Matrix to Zero
    for(i=0; i<=M; i++) {
        for(j=0; j<=N; j++) {
                B_cin[i*(N+1) + j] = 0;
                B_cout[i*(N+1) + j] = 0;
        }
    }
    printf("\n");
    // Initialize Matrix from Input and Initialize B Matrix
    for(i=0; i<M; i++) {
        for(j=0; j<N; j++) {
                scanf("%d", &A_cin[i*N + j]);
                B_cin[i*(N+1)+j] = A_cin[i*N + j];
                B_cout[i*(N+1)+j] = A_cin[i*N + j];
        }
    }
    // CPU Computation
      // cpu(B_cout,M,N);
    // Copy Matrices
    cudaMemcpy(A_gin, A_cin, M * N * sizeof(int),cudaMemcpyHostToDevice);
    cudaMemcpy(B_gin, B_cin, (M+1) * (N+1) * sizeof(int),cudaMemcpyHostToDevice);
    // Define Parameters
    int blockdim = 1024;
    int griddim = ceil((float)(M*N/K) / blockdim);
    // Launch kernels
    sumRandC <<< griddim, blockdim >>> (A_gin,B_gin,M,N,K);
    cudaDeviceSynchronize();
    findMin <<< griddim, blockdim >>> (A_gin,B_gin,M,N,K);
    cudaDeviceSynchronize();
    updateMin <<< griddim, blockdim >>> (A_gin,B_gin,M,N,K);
    cudaDeviceSynchronize();
    cudaMemcpy(B_gout, B_gin, (M+1) * (N+1) * sizeof(int),cudaMemcpyDeviceToHost);
    // Print Matrix
    print_matrix(B_gout,M+1,N+1);
}
