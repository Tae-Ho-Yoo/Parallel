#include <stdio.h>
#include <stdlib.h>
#include <curand.h>
#include <curand_kernel.h>
#include "utils.h"

#define N_THREADS 16
#define N_BLOCKS 1024

/*** GPU functions ***/
__global__ void init_rand_kernel(curandState *state) {
 int idx = blockIdx.x * blockDim.x + threadIdx.x;
 curand_init(0, idx, 0, &state[idx]);
}

__global__ void random_walk_kernel(float *map, int rows, int cols, int* bx, int* by,
                                   int steps, curandState *state) {
  int tid = threadIdx.x + blockIdx.x * blockDim.x;
  float randval = curand_uniform(&state[tid]);
  int randint = int(randval * (rows * cols));
  int curridx = randint;

  float max_height = map[curridx];

  bx[tid] = curridx % rows;
  by[tid] = curridx / rows;

  for (int i = 0; i < steps; i++){
    int randact = int(randval * 4);

    if (randact == 0){
      if (curridx + 1 < rows * cols){
        curridx++;
      }
    }
    else if (randact == 1){
      if (curridx - 1 > 0){
        curridx--;
      }
    }
    else if (randact == 2){
      if (curridx + rows < rows * cols){
        curridx += rows;
      }
    }
    else if (randact == 3){
      if (curridx - rows > 0){
        curridx -= rows;
      }
    }

    if (map[curridx] > max_height){
      max_height = map[curridx];
      bx[tid] = curridx % rows;
      by[tid] = curridx / rows;
    }
  }
}

__global__ void local_max_kernel(float *map, int rows, int cols, int* bx, int* by,
                                 int steps, curandState *state) {
  int tid = threadIdx.x + blockIdx.x * blockDim.x;
  //TODO: implement local max!
}

__global__ void local_max_restart_kernel(float *map, int rows, int cols, int* bx,
                                         int* by, int steps, curandState *state) {
  int tid = threadIdx.x + blockIdx.x * blockDim.x;
  //TODO: implement local max with restarts!
}

// /*** CPU functions ***/
// curandState* init_rand() {
//   curandState *d_state;
//   cudaMalloc(&d_state, N_BLOCKS * N_THREADS * sizeof(curandState));
//   init_rand_kernel<<<N_BLOCKS, N_THREADS>>>(d_state);
//   return d_state;
// }

float random_walk(float* map, int rows, int cols, int steps) {
  curandState* d_state;
  int *bx, *by;
  int *d_bx, *d_by;
  float* d_map;

  bx = (int *)malloc(N_BLOCKS * N_THREADS  * sizeof(int));
  by = (int *)malloc(N_BLOCKS * N_THREADS  * sizeof(int));

  for (int i = 0; i < N_BLOCKS * N_THREADS; i++){
    bx[i] = i;
    by[i] = i;
  }

  cudaMalloc(&d_state, N_BLOCKS * N_THREADS * sizeof(curandState));
  cudaMalloc(&d_bx, N_BLOCKS * N_THREADS  * sizeof(int));
  cudaMalloc(&d_by, N_BLOCKS * N_THREADS  * sizeof(int));
  cudaMalloc(&d_map, rows * cols * sizeof(int));

  cudaMemcpy(d_bx, bx, N_BLOCKS * N_THREADS  * sizeof(int), cudaMemcpyHostToDevice);
  cudaMemcpy(d_by, by, N_BLOCKS * N_THREADS  * sizeof(int), cudaMemcpyHostToDevice);
  cudaMemcpy(d_map, map, rows * cols * sizeof(float), cudaMemcpyHostToDevice);

  // Before kernel call:
  // Need to allocate memory for above variables and copy data to GPU
  init_rand_kernel<<<N_BLOCKS, N_THREADS>>>(d_state);
  random_walk_kernel<<<N_BLOCKS, N_THREADS>>>(d_map, rows, cols, d_bx, d_by, steps, d_state);

  // After kernel call:
  // Need to copy data back to CPU and find max value

  cudaMemcpy(bx, d_bx, N_BLOCKS * N_THREADS  * sizeof(int), cudaMemcpyDeviceToHost);
  cudaMemcpy(by, d_by, N_BLOCKS * N_THREADS  * sizeof(int), cudaMemcpyDeviceToHost);
  cudaMemcpy(map, d_map, rows * cols * sizeof(float), cudaMemcpyDeviceToHost);

  float max_val = 0;

  for (int i = 0; i < N_BLOCKS * N_THREADS; i++){
    for (int j = 0; j < N_BLOCKS * N_THREADS; j++){
      if (map[rows * by[i] + bx[j]] > max_val){
        max_val = map[rows * by[i] + bx[j]];
        printf("%f\n", max_val);
      }
    }
  }
  
  // Finally: free used GPU and CPU memory

  cudaFree(d_bx);
  cudaFree(d_by);
  cudaFree(d_map);
  cudaFree(d_state);

  free(bx);
  free(by);
  free(map);

  return max_val;
}

// Work on these after finishing random walk
float local_max(float* map, int rows, int cols, int steps);
float local_max_restart(float* map, int rows, int cols, int steps);


int main(int argc, char** argv) {
  if (argc != 2) {
    printf("Usage: %s <map_file> \n", argv[0]);
    return 1;
  }

  float *map;
  int rows, cols;
  read_bin(argv[1], &map, &rows, &cols);

  printf("%d %d\n", rows, cols);

  // As a starting point, try to get it working with a single steps value
  int steps = 1;
  float max_val = random_walk(map, rows, cols, steps);
  printf("Random walk max value: %f\n", max_val);

  return 0;
}
