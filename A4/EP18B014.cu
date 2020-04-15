#include<bits/stdc++.h>
#include<thrust/device_vector.h>
#include<thrust/transform.h>
#include<thrust/extrema.h>
#include<thrust/copy.h>
#include<thrust/functional.h>
using namespace std;
struct process {
 __host__ __device__
 int operator()(const float& x, const float& y) const {
 return (x-y>=0?x-y:0);
 }
};
int schedule(int N, int M, int* arrival_times, int* burst_times, int** cores_schedules, int* cs_lengths){
  // Change turnaround_time to GPU and finally only copy it back Should save 20ms
  long int turnaround_time=0;
  thrust::device_vector<int> core(M, 0);
  vector<vector<int>>data(M);
  int last_val=arrival_times[0];
  for (int i=0;i<N;i++){
    if(last_val!=arrival_times[i]){
      thrust::device_vector<int> tmp(M, arrival_times[i]-last_val);
      thrust::transform(core.begin(), core.end(),tmp.begin(),core.begin(), process());
      last_val = arrival_times[i];
    }
    int minElementIndex = thrust::min_element(core.begin(),core.end()) - core.begin();
    core[minElementIndex]+=burst_times[i];  // Same here
    turnaround_time+=core[minElementIndex]; // These Function take so much time to copy
    data[minElementIndex].push_back(i);
  }

  for (int i=0;i<M;i++){
    cs_lengths[i]=data[i].size();
    cores_schedules[i] =  (int*)malloc(cs_lengths[i] * sizeof(int*));
    for (int j=0;j<cs_lengths[i];j++){
      cores_schedules[i][j] = data[i][j];
    }
  }
  return turnaround_time;
}
