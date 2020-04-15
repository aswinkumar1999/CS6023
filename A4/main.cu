#include <stdio.h>
#include <cuda.h>
#include "kernel.h"

int main(int argc, char* argv[]){
  int N, M;
  FILE* fp = fopen(argv[1], "r");
  fscanf(fp, "%d %d", &N, &M);

  int *arrival_times, *burst_times;
  int **cores_schedules, *cs_lengths;
  int turnaround_time = 0;
  int i;

  arrival_times = (int*) malloc(N * sizeof(int));
  burst_times = (int*) malloc(N * sizeof(int));
  cores_schedules = (int**) malloc(M * sizeof(int*));
  cs_lengths = (int*) malloc(M * sizeof(int));

  for(i = 0; i < N; i++) {
	fscanf(fp, "%d %d", &arrival_times[i], &burst_times[i]);
  }

  cudaEvent_t start, stop;
  cudaEventCreate(&start);
  cudaEventCreate(&stop);
  float milliseconds = 0;
  cudaEventRecord(start,0);

  turnaround_time = schedule(N, M, arrival_times, burst_times, cores_schedules, cs_lengths);

  cudaDeviceSynchronize();

  cudaEventRecord(stop,0);
  cudaEventSynchronize(stop);
  cudaEventElapsedTime(&milliseconds, start, stop);
  printf("%f\n",milliseconds);

  printf("%d\n", turnaround_time);
  for(int i = 0; i < M; i++){
	for(int j = 0; j < cs_lengths[i]; j++){
	  printf("%d ", cores_schedules[i][j]);
	}
	printf("\n");
  }
}
