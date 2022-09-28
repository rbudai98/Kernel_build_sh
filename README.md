# Kernel_build_sh
Building Nvidia kernel with ADSD3500 drivers

Stepps:

1. Open terminal and clone the bash script with:
 ```condole
 source AGC_Kernel_build.sh
 ```
2. In case there are dependency errors or build errors appearing on terminal just install them and by running the same script the build will continue from the last step that is not functional

3. You can find the generated Image, device tree blobs and modules in the ```build``` directory