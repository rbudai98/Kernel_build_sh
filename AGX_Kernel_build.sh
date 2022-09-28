#!/usr/bin/env bash
# Nvidia AGX kernel build with Analog Devices ADSD3000 driver 

CURRENT_DIR=$(pwd)
if [ -z "$STEP" ]
then
      echo "Starting build from scratch"
      export STEP=0 > /dev/null
else
      echo "Continuing build"
fi

if (( "${STEP}" < 1 )); then
  mkdir $CURRENT_DIR/src
  mkdir $CURRENT_DIR/build

  export STEP=$((STEP + 1))
fi

BUILD_DIR=$CURRENT_DIR/build
CURRENT_DIR=$CURRENT_DIR/src
echo "Current PATH: ${CURRENT_DIR}"

if (( "${STEP}" < 2 )); then

  echo Downloading AGX Root File System
  cd $CURRENT_DIR && wget https://developer.nvidia.com/embedded/l4t/r34_release_v1.1/sources/public_sources.tbz2 
  export STEP=$((STEP + 1))

fi

if (( "${STEP}" < 3 )); then

  echo Clone ToF SDK
  cd $CURRENT_DIR && git clone https://github.com/analogdevicesinc/ToF.git
  export STEP=$((STEP + 1))
fi

if (( "${STEP}" < 4 )); then

  echo Unpacking Root File System
  mkdir -p ${CURRENT_DIR}/L4T_driver_package && cd ${CURRENT_DIR}/L4T_driver_package
  tar -xvf ${CURRENT_DIR}/public_sources.tbz2 
  export STEP=$((STEP + 1))
fi

if (( "${STEP}" < 5 )); then

  echo Downloading compiler
  cd $CURRENT_DIR && wget http://releases.linaro.org/components/toolchain/binaries/7.5-2019.12/aarch64-linux-gnu/gcc-linaro-7.5.0-2019.12-x86_64_aarch64-linux-gnu.tar.xz
  mkdir $CURRENT_DIR/l4t-gcc && cd $CURRENT_DIR/l4t-gcc && tar -xvf $CURRENT_DIR/gcc-linaro-7.5.0-2019.12-x86_64_aarch64-linux-gnu.tar.xz

  export STEP=$((STEP + 1))
fi

if (( "${STEP}" < 6 )); then

  echo "Generating soft-links for compilers"
  for entry in "${CURRENT_DIR}/l4t-gcc/gcc-linaro-7.5.0-2019.12-x86_64_aarch64-linux-gnu/bin"/*
  do
    ln -s $entry $(echo $entry | sed -e "s/aarch64-linux-gnu-/aarch64-buildroot-linux-gnu-/")
  done
  export CROSS_COMPILE_AARCH64_PATH=$CURRENT_DIR/l4t-gcc/gcc-linaro-7.5.0-2019.12-x86_64_aarch64-linux-gnu

  export STEP=$((STEP + 1))
fi

if (( "${STEP}" < 7 )); then

  echo Unpacking Kernel files
  cd ${CURRENT_DIR}/L4T_driver_package/Linux_for_Tegra/source/public/
  tar -xvf kernel_src.tbz2
  export STEP=$((STEP + 1))
fi

if (( "${STEP}" < 8 )); then

  echo Copy device-tree
  cp $CURRENT_DIR/ToF/drivers/adsd3500/nvidia/L4T_34_1_1/src/tegra194-p3668-all-p3509-0000.dts ${CURRENT_DIR}/L4T_driver_package/Linux_for_Tegra/source/public/hardware/nvidia/platform/t19x/jakku/kernel-dts/
  export STEP=$((STEP + 1))
fi

if (( "${STEP}" < 9 )); then

  echo Copy driver source files
  cp $CURRENT_DIR/ToF/drivers/adsd3500/nvidia/L4T_34_1_1/src/adsd3500_mode_tbls.h ${CURRENT_DIR}/L4T_driver_package/Linux_for_Tegra/source/public/kernel/nvidia/drivers/media/i2c
  cp $CURRENT_DIR/ToF/drivers/adsd3500/nvidia/L4T_34_1_1/src/adsd3500.c ${CURRENT_DIR}/L4T_driver_package/Linux_for_Tegra/source/public/kernel/nvidia/drivers/media/i2c
  cp $CURRENT_DIR/ToF/drivers/adsd3500/nvidia/L4T_34_1_1/src/adsd3500_regs.h ${CURRENT_DIR}/L4T_driver_package/Linux_for_Tegra/source/public/kernel/nvidia/drivers/media/i2c
  export STEP=$((STEP + 1))
fi

if (( "${STEP}" < 10 )); then

  echo Adding driver object to Makefile
  echo -e "obj-$(CONFIG_VIDEO_ADSD3500) += adsd3500.o" | tee -a ${CURRENT_DIR}/L4T_driver_package/Linux_for_Tegra/source/public/kernel/nvidia/drivers/media/i2c/Makefile > /dev/null
  export STEP=$((STEP + 1))
fi

if (( "${STEP}" < 11 )); then

  echo Adding driver to KConfig
  NR_OF_LINE=$(grep -wn config ${CURRENT_DIR}/L4T_driver_package/Linux_for_Tegra/source/public/kernel/nvidia/drivers/media/i2c/Kconfig | cut -d: -f1 | head -n 1)
  PREV_LINE_NUMBER=$(($NR_OF_LINE-1))
  sed -i "${PREV_LINE_NUMBER} i\config VIDEO_ADSD3500 \ntristate \"Analog Devices ADSD3500 driver\" \ndepends on I2C \&\& VIDEO_V4L2 \&\& VIDEO_V4L2_SUBDEV_API \&\& REGMAP_I2C \nhelp\n  This is a Video4Linux2 sensor\-level driver for \n          Analog Devices ADSD3500 ISP Chip\n\n	  To compile this driver as a module, choose M here\: the module will be called adsd3500. \n" ${CURRENT_DIR}/L4T_driver_package/Linux_for_Tegra/source/public/kernel/nvidia/drivers/media/i2c/Kconfig
  export STEP=$((STEP + 1))
fi

if (( "${STEP}" < 12 )); then

  echo Appending module to defconfig
  echo -e "CONFIG_VIDEO_ADSD3500=m" | tee -a ${CURRENT_DIR}/L4T_driver_package/Linux_for_Tegra/source/public/kernel/kernel-5.10/arch/arm64/configs/defconfig > /dev/null
  export STEP=$((STEP + 1))
fi

if (( "${STEP}" < 13 )); then

  echo Building the kernel
  bash ${CURRENT_DIR}/L4T_driver_package/Linux_for_Tegra/source/public/nvbuild.sh
  echo Builing modules
  cd ${CURRENT_DIR}/L4T_driver_package/Linux_for_Tegra/source/public/kernel/kernel-5.10 && make ARCH=arm64 modules_install INSTALL_MOD_PATH=$BUILD_DIR/
  export STEP=$((STEP + 1))
fi

if (( "${STEP}" < 14 )); then

  echo Moving generated file to build directory
  cd $CURRENT_DIR/../

  # Copy image
  cp $CURRENT_DIR/L4T_driver_package/Linux_for_Tegra/source/public/kernel/kernel-5.10/arch/arm64/boot/Image $BUILD_DIR/
  # COpy device tree
  cd $CURRENT_DIR/L4T_driver_package/Linux_for_Tegra/source/public/kernel/kernel-5.10/arch/arm64/boot/dts/nvidia && tar zcf ${BUILD_DIR}/dtb.tar.gz .
  #Tar modules and copy modules
  cd $BUILD_DIR && tar --owner root --group root -cjf $BUILD_DIR/kernel_supplements.tbz2 $BUILD_DIR/lib/modules 

  cd $CURRENT_DIR/../
  export STEP=$((STEP + 1))
fi
echo -e "########################"
echo -e "########################"
echo -e
echo -e
echo "Build successfull!"
echo -e
echo -e
echo -e "########################"
echo -e "########################"










