#include <stdio.h>
#include "kernels.h"

void print_matrix(int* mat, int n) {
    for(int i=0; i<n; i++) {
        for(int j=0; j<n; j++) {
            printf("%d ", mat[i*n + j]);
        }
        printf("\n");
    }
}

bool check_if_transpose(int* mat1, int* mat2, int n) {
    for(int i=0; i<n; i++) {
        for(int j=0; j<n; j++) {
            if(mat1[i*n + j] != mat2[j*n + i])
                return false;
        }
    }
    return true;
}

int main()
{
    long long unsigned N,i,j;
    scanf("%llu", &N);
    int* mathost, * matdev, *resmat;
    mathost = (int*)malloc(N * N * sizeof(int));
    resmat = (int*)malloc(N*N*sizeof(int));
    cudaMalloc(&matdev, N * N * sizeof(int));


    // print_matrix(mathost, N);

    // Initialize lower triangular matrix
    for(i=0; i<N; i++) {
        for(j=0; j<N; j++) {
            if (i>=j)
                mathost[i*N + j] = rand()%9 + 1;
            else
                mathost[i*N + j] = 0;
        }
    }

    // print_matrix(mathost, N);

    cudaMemcpy(matdev, mathost, N * N * sizeof(int),
                cudaMemcpyHostToDevice);

    int griddim = ceil((float)N / 1024);
    dim3 block1(32, 32);
    per_row_kernel <<< griddim, block1 >>> (matdev, N);
    cudaDeviceSynchronize();

    cudaMemcpy(resmat, matdev, N * N * sizeof(int),
	           cudaMemcpyDeviceToHost);


	printf("\n");
    // print_matrix(resmat, N);

    printf("%d\n", check_if_transpose(mathost, resmat, N));

	griddim = ceil((float)N * N / 1024 * 32 * 32);
	dim3 grid1(griddim, 32, 32);
	// per_element_kernel << <grid1, 1024 >> > (matdev, N);
	// cudaDeviceSynchronize();

	// cudaMemcpy(mathost, matdev, N * N * sizeof(int),
	// 	cudaMemcpyDeviceToHost);

	// printf("\n");
    // print_matrix(mathost, N);

	griddim = ceil((float)N * N / 1024 * 32);
	dim3 grid2(griddim, 32);
	dim3 block2(32, 32);
	// per_element_kernel_2D << <grid2, block2 >> > (matdev, N);
	// cudaDeviceSynchronize();

	// cudaMemcpy(mathost, matdev, N * N * sizeof(int),
	// 	cudaMemcpyDeviceToHost);

	// printf("\n");
    // print_matrix(mathost, N);

	// for (i = 0; i < N; i++)
	// {
	// 	for (j = i + 1; j < N; j++)
	// 	{
	// 		int temp = mathost[i * N + j];
	// 		mathost[i * N + j] = mathost[j * N + i];
	// 		mathost[j * N + i] = temp;
	// 	}
	// }

	printf("\n");
    // print_matrix(mathost, N);
}