#ifndef _KERNELS_H_
#define _KERNELS_H_

__global__ void per_row_kernel(int *in, int N){
  unsigned long long int id = ( blockIdx.x*blockDim.y+threadIdx.y)*blockDim.x + threadIdx.x;
    if(id < N){
        for(unsigned long long int i=0;i<id;i++){
          in[id+i*N] = in[id*N+i];
          in[id*N+i] = 0;
        }
    }
  }
__global__ void per_element_kernel(int *in, int N){
  unsigned long long int id = (blockIdx.z*gridDim.y*gridDim.x*blockDim.x)+((blockIdx.y*gridDim.x+blockIdx.x)*blockDim.x)+ threadIdx.x;
    if(id < N*N){
        if( (id % N) > (int)(id/N)){
          in[id] = in[ N*(id % N) + (int)(id/N)];
          in[ N*(id % N) + (int)(id/N)] = 0;
        }
    }
  }


__global__ void per_element_kernel_2D(int *in, int N){
  unsigned long long int id = ((blockIdx.y*gridDim.x+blockIdx.x)*(blockDim.x*blockDim.y))+(threadIdx.y*blockDim.x+threadIdx.x);
    if(id < N*N){
        if( (id % N) > (int)(id/N)){
          in[id] = in[ N*(id % N) + (int)(id/N)];
          in[ N*(id % N) + (int)(id/N)] = 0;
        }
    }
}


#endif
