## Hill Climbing on the GPU!

### Getting Started
In addition to CMake and C++11, you will also need CUDA. This is already set up on the lab machines. If you want to install it locally, please look online and send me an email if you run into any issues!

After installing these prerequisites, you should be able to compile the code provided in this repositoy. First, you need to clone this to your machine:

```
git clone git@github.com:BradMcDanel/cps376-assignments.git
cd cps376-assignments/03-hillclimb/
```
Note: if you already cloned the repository for the last assignment, you should be able to simply do `git pull` instead of the two above lines.

Now, we need to set up a `build/` directory for CMake:

```
mkdir build
cd build
```

Inside the build directory we can run CMake to generate a Makefile for the project.
```
cmake ..
```

Additionally, you will need to download the map file, which you can find here: [map.bin](https://drive.google.com/file/d/1DjdhMMye8xgHnDZs8bmbrFxTbdMaHtGl/view?usp=sharing)

Assuming you downloaded `map.bin` to a `data/` directory, then you could run the following:
```
make
./climb ../data/map.bin
./rand
```

The `rand` program is just to get you started with allocating memory and generating random numbers (you do not need to modify it).


### Next Steps
* Make sure you understand what is going on in `rand.cu`.
* Start working on the `random_walk_kernel` function (for a single thread). Then, extend it to multiple threads.
* Finally, finish the other two algorithms.

