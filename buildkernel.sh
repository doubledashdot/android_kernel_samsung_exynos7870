#!/bin/bash

set -e

DATE_POSTFIX=$(date +"%Y%m%d")
TIME_POSTFIX=$(date +"%H%M")

DEVICE_CODENAME="j7velte"
PLATFORM_DEFCONFIG="exynos7870_defconfig"
DEVICE_DEFCONFIG="$DEVICE_CODENAME.config"
KERNEL_NAME="not"
ARCH="arm64"
DTC_EXT="dtb"

get_file_name() {
    local url="$1"
    local file_name
    file_name=$(basename "$url")
    echo "$file_name"
}

abort_if_error() {
    local exit_code=$?
    if [ $exit_code -ne 0 ]; then
        local message="$1"
        echo -e "$red*** Error: $message $exit_code ***$nocol" 
        exit $exit_code
    fi
}

red='\033[0;31m'
purple='\033[0;35m'
green='\033[0;32m'
nocol='\033[0m'

initial_function() {
    SCRIPT_DIR="$PWD"
    DEVICE_CODENAME_DIR="$(pwd)"
    BUILD_START=$(date +"%s")
    abort_if_error 
}

cleanup_out() {
    cd $DEVICE_CODENAME_DIR
    sudo mkdir -p out
}

configure_build() {
    cd $DEVICE_CODENAME_DIR
    KERNEL_VERSION="kernelversion"
    ANY_KERNEL3_DIR="$DEVICE_CODENAME_DIR/AnyKernel3/"
    FINAL_KERNEL_ZIP="$KERNEL_NAME-$DEVICE_CODENAME-$DATE_POSTFIX.zip"
    export CROSS_COMPILE="$KERNEL_TOOLCHAIN_AARCH64"
    export CROSS_COMPILE_ARM32="$KERNEL_TOOLCHAIN_ARM32"
    export ARCH="$ARCH"
    export DTC_EXT="$DTC_EXT"
    export ANDROID_MAJOR_VERSION="q"
    MAKE="./makeparallel"
    abort_if_error
}

configure_kernel() {
    cd $DEVICE_CODENAME_DIR
    make $PLATFORM_DEFCONFIG $DEVICE_DEFCONFIG O=out
    echo -e "$purple**************$nocol"
    make $KERNEL_VERSION O=out
    echo -e "$purple**************$nocol"
}

compile_kernel() {
    cd $DEVICE_CODENAME_DIR
    export CC=$(pwd)/linaro/bin/aarch64-linux-gnu-gcc
    export CROSS_COMPILE=$(pwd)/linaro/bin/aarch64-linux-gnu-
    make O=out -j$(nproc)
    abort_if_error
}

verify_output_files() {
    if [ ! -e "$DEVICE_CODENAME_DIR/out/arch/arm64/boot/Image" ]; then
        exit 1
    fi
    abort_if_error
}

create_final_zip() {
    echo -e "$purple***********************************************$nocol"
    ls $DEVICE_CODENAME_DIR/out/arch/arm64/boot/Image
    ls $ANY_KERNEL3_DIR
    rm -rf $ANY_KERNEL3_DIR/Image
    rm -rf $ANY_KERNEL3_DIR/dtb.img
    rm -rf $ANY_KERNEL3_DIR/*.zip
    cp $DEVICE_CODENAME_DIR/out/arch/arm64/boot/Image $ANY_KERNEL3_DIR/
    cp $DEVICE_CODENAME_DIR/out/arch/arm64/boot/dtb.img $ANY_KERNEL3_DIR/dtb.img
    cd $ANY_KERNEL3_DIR
    zip -r9 $FINAL_KERNEL_ZIP * -x README $FINAL_KERNEL_ZIP
    rm -rf $DEVICE_CODENAME_DIR/zip/
    mkdir $DEVICE_CODENAME_DIR/zip/
    mv $DEVICE_CODENAME_DIR/AnyKernel3/*.zip $DEVICE_CODENAME_DIR/zip/$FINAL_KERNEL_ZIP
    cp $DEVICE_CODENAME_DIR/out/arch/arm64/boot/Image $DEVICE_CODENAME_DIR/zip/kernel
    cp $DEVICE_CODENAME_DIR/out/arch/arm64/boot/dtb.img $DEVICE_CODENAME_DIR/zip/extra
    echo -e "$green**** FINAL ZIP in $DEVICE_CODENAME_DIR/zip/$FINAL_KERNEL_ZIP ****"
    abort_if_error
}

final_function() {
    cd $DEVICE_CODENAME_DIR
    echo -e "$purple***********************************************$nocol"
    BUILD_END=$(date +"%s")
    DIFF=$(($BUILD_END - $BUILD_START))
    abort_if_error
    echo -e "$green Build took $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) second(s).$nocol"
    exit 1
} 

main() {
    initial_function
    cleanup_out
    configure_build
    configure_kernel
    compile_kernel
    verify_output_files
    create_final_zip
    final_function
}

main
