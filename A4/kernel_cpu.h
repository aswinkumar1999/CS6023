#include<bits/stdc++.h>
using namespace std;

int process(int x,int y){
  return (x-y>=0?x-y:0);
}

int schedule(int N, int M, int* arrival_times, int* burst_times, int** cores_schedules, int* cs_lengths){
  long int turnaround_time=0;
  vector<int> core(M, 0);
  vector<vector<int>>data(M);
  int last_val=arrival_times[0];
  for (int i=0;i<N;i++){
    if(last_val!=arrival_times[i]){
      vector<int> tmp(M, arrival_times[i]-last_val);
      transform(core.begin(), core.end(),tmp.begin(),core.begin(), process);
      last_val = arrival_times[i];
    }
    int minElementIndex = min_element(core.begin(),core.end()) - core.begin();
    core[minElementIndex]+=burst_times[i];
    turnaround_time+=core[minElementIndex];
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
