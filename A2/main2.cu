#include <stdio.h>
#define min(X, Y) (((X) < (Y)) ? (X) : (Y))


__global__ void sumRandC (int* A, int* B, int m, int n, int k=1){
    unsigned long long int id = ( blockIdx.x*blockDim.y+threadIdx.y)*blockDim.x + threadIdx.x;
    // printf("%d\n",id);
    if(id<(m*n)/k){
      // printf("True");
      for (int i=k*id;i<(k)*(id+1);i++){
        // printf("%d\t",i);
        int n_new = i %(n);
        int m_new = i /(n);
        // printf("%d\t",m_new);
        // printf("%d\t",n_new);
        // Add values
        atomicAdd(&B[m_new*(n+1)+n], B[m_new*(n+1)+n_new]);
        atomicAdd(&B[m*(n+1)+n_new],  B[m_new*(n+1)+n_new]);
      }
    }
}
__device__ int mini;
__global__ void findMin (int* A, int* B, int m, int n, int k=1){
  unsigned long long int id = ( blockIdx.x*blockDim.y+threadIdx.y)*blockDim.x + threadIdx.x;
  if(id==0){
    mini=B[n];
  }
  if(id<(m+n)){
    if(id < m ){
      atomicMin(&mini,B[id*(n+1)+n]);
    }
    if(id>=m){
      atomicMin(&mini,B[m*n+id]);
    }
}
  if(id==0){
    B[m*(n+1)+n]=mini;
  }
}

__global__ void updameMin (int* A, int* B, int m, int n, int k=1){
  unsigned long long int id = ( blockIdx.x*blockDim.y+threadIdx.y)*blockDim.x + threadIdx.x;
  if(id<(m*n)/k){
    for (int i=k*id;i<(k)*(id+1);i++){
      int n_new = i %(n);
      int m_new = i /(n);
      B[m_new*(n+1)+n_new]+=mini;
    }
  }
}

void print_matrix(int* mat,int m, int n) {
    for(int i=0; i<m; i++) {
        for(int j=0; j<n; j++) {
            printf("%d ", mat[i*n + j]);
        }
        printf("\n");
    }
}

void cpu(int *in,int m,int n){
  //Row
  int i,j,sum=0;
  for(i=0; i<m; i++) {
    sum=0;
      for(j=0; j<n; j++) {
              sum+=in[i*(n+1)+j];
      }
    in[i*(n+1)+n]=sum;
  }
  //Column
  for(i=0; i<n; i++) {
    sum=0;
      for(j=0; j<m; j++) {
              sum+=in[j*(n+1)+i];
      }
    in[(n+1)*(m)+i]=sum;

  }
  // Find min
  long long int mini=100*max(m,n);

  for(i=0;i<n;i++){
    // printf("%d\t",in[((m)*(n+1))+i] );
    mini = min(mini,in[((m)*(n+1))+i]);
    // printf("%d\n", mini);
  }
  for(i=0;i<m;i++){
      // printf("%d\t",in[(i)*(n+1)+n]);
    mini = min(mini,in[(i)*(n+1)+n]);
    // printf("%d\n", mini);
  }
  in[(n+1)*(m)+n]=mini;
  // Add Min
  for(i=0; i<m; i++) {
      for(j=0; j<n; j++) {
              in[i*(n+1) + j] += mini;
      }
  }

}
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

    // print_matrix(mathost, N);
    for(i=0; i<=M; i++) {
        for(j=0; j<=N; j++) {
                B_cin[i*(N+1) + j] = 0;
                B_cout[i*(N+1) + j] = 0;
        }
    }
    printf("\n");
    // Initialize lower triangular matrix
    for(i=0; i<M; i++) {
        for(j=0; j<N; j++) {
                scanf("%llu", &A_cin[i*N + j]);
                B_cin[i*(N+1)+j] = A_cin[i*N + j];
                B_cout[i*(N+1)+j] = A_cin[i*N + j];
        }
    }

    cpu(B_cout,M,N);


    cudaMemcpy(A_gin, A_cin, M * N * sizeof(int),cudaMemcpyHostToDevice);
    cudaMemcpy(B_gin, B_cin, (M+1) * (N+1) * sizeof(int),cudaMemcpyHostToDevice);


    sumRandC <<< 1000, 32 >>> (A_gin,B_gin,M,N,5);
    cudaDeviceSynchronize();
    findMin <<< 1000, 32 >>> (A_gin,B_gin,M,N,1);
    cudaDeviceSynchronize();
    updameMin <<< 1000, 32 >>> (A_gin,B_gin,M,N,1);
    cudaDeviceSynchronize();
    cudaMemcpy(B_gout, B_gin, (M+1) * (N+1) * sizeof(int),cudaMemcpyDeviceToHost);

    // printf("\n");
    // print_matrix(B_cin,M+1,N+1);
    // printf("\n");
    // print_matrix(B_gout,M+1,N+1);
    // printf("\n");
    // print_matrix(B_cout,M+1,N+1);

    printf("%d\n", check_same(B_gout,B_cout,M+1,N+1));
    //


    printf("\n");
}
