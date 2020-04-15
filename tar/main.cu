#include <cuda_runtime.h>
#include <cublas_v2.h>
#include <cstdio>
#include <cstdlib>
#include <sys/time.h>
#include <thrust/device_vector.h>
#include <thrust/device_ptr.h>
#include <thrust/device_malloc.h>
#include <thrust/device_free.h>

typedef float Real;

void findMaxAndMinGPU(Real* values, int* min_idx, int n)
{
    Real* d_values;
    cublasHandle_t handle;
    cublasStatus_t stat;
    cudaMalloc((void**) &d_values, sizeof(Real) * n);
    cudaMemcpy(d_values, values, sizeof(Real) * n, cudaMemcpyHostToDevice);
    cublasCreate(&handle);

    // stat = cublasIsamax(handle, n, d_values, 1, max_idx);
    // if (stat != CUBLAS_STATUS_SUCCESS)
    //     printf("Max failed\n");

    stat = cublasIsamin(handle, n, d_values, 1, min_idx);
    if (stat != CUBLAS_STATUS_SUCCESS)
        printf("min failed\n");

    cudaFree(d_values);
    cublasDestroy(handle);
}

__global__ void kernel(float *a){
  printf("%f\n",a[threadIdx.x+6]);
}

int main(void)
{
    const int nvals=6;

    // create a device_ptr
    thrust::device_vector<float> vals_vec;
    // float vals.push_back(nvals];
    vals_vec.push_back(10);
    vals_vec.push_back(12);
    vals_vec.push_back(4);
    vals_vec.push_back(5);
    vals_vec.push_back(6);
    vals_vec.push_back(7);
    int *minIdx = (int *)malloc(sizeof(int));
    float *vals = thrust::raw_pointer_cast(vals_vec.data());
    cublasHandle_t handle;
    cublasStatus_t stat;
    cublasCreate(&handle);
    stat = cublasIsamin(handle, nvals, vals, 1, minIdx);
    if (stat != CUBLAS_STATUS_SUCCESS)
        printf("min failed\n");
    fprintf(stdout, "%d\n", *minIdx-1);
    vals_vec[5]=1;
    stat = cublasIsamin(handle, nvals, vals, 1, minIdx);
    if (stat != CUBLAS_STATUS_SUCCESS)
        printf("min failed\n");
    cublasDestroy(handle);
    fprintf(stdout, "%d\n", *minIdx-1);

    return 0;
}
