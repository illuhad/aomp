## Getting Started

<A NAME="Getting-Started">

The default install location is /opt/rocm/aomp. To run the given examples, for example in /opt/rocm/aomp/examples/openmp do the following:

### Copy the example openmp directory somewhere writable
```
cd /opt/rocm/aomp/examples/
cp -rp openmp /work/tmp/openmp-examples
cd /work/tmp/openmp-examples/vmulsum
```

### Point to the installed AOMP by setting AOMP environment variable
```
export AOMP=/opt/rocm/aomp
```

### Make Instructions
```
make clean
make run
```
Run 'make help' for more details.  

View the OpenMP Examples [README](../examples/openmp) for more information.
