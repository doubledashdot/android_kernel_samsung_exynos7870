#!/bin/bash

set -e

DATE_POSTFIX=$(date +"%Y%m%d")
TIME_POSTFIX=$(date +"%H%M")

# Script dedicado a compilar un custom kernel

SCRIPT_NAME="Kyliz"
SCRIPT_VERSION="v1.2.6 STABLE"

DEVICE_CODENAME="j7velte"
KERNEL_DEFCONFIG="exynos7870-j7velte_defconfig"
BUILD_STATUS="UNOFFICIAL"
BUILD_TYPE="BETA"
KERNEL_NAME="KernelSU"
ARCH="arm64"
DTC_EXT="dtb"
CLANG_VERSION="clang-r353983e"
CLANG_VERSION_STRING="Clang Version 9.0.5"
CLANG_VERSION_DIR="clang-9"
ARM_LINUX_ANDROIDEABI_VERSION="arm-linux-androideabi-"
AARCH64_LINUX_ANDROID_VERSION="aarch64-linux-android-"
AARCH64_LINUX_GNU_VERSION="aarch64-linux-gnu-"

# Fin de Configurancion de Archivos y Herramientas del dispositivo a compilar

show_status() {
    local message="$1"
    local status_type="$2"

    case "$status_type" in
        "STATUS") echo -e "$cyan[ESTADO] $message$nocol";;
        "COMPLETE") echo -e "$green[COMPLETADO] $message$nocol";;
        "WARNING") echo -e "$yellow[ALERTA] $message$nocol";;
        "ERROR") echo -e "$red[ERROR] $message$nocol";;
        *) echo -e "$cyan[STATUS] $message$nocol";;
    esac
}

check_os() {
    local os=$(uname -s)
    if [ "$os" != "Linux" ]; then
        echo -e "$red*** Error: Este script solo es compatible con sistemas operativos Linux. Saliendo. ***$nocol"
        exit 1
    fi
}

validate_environment_variables() {
    show_status "Verificando variables principales..." "STATUS"
    local missing_variables={}

    if [ -z "$DEVICE_CODENAME" ]; then
        missing_variables+={"DEVICE_CODENAME"}
    fi

    if [ -z "$SCRIPT_DIR" ]; then
        missing_variables+={"SCRIPT_DIR"}
    fi

    if [ -z "$DEVICE_CODENAME_DIR" ]; then
        missing_variables+={"DEVICE_CODENAME_DIR"}
    fi

    abort_if_error
    show_status "Variables principales verificadas." "COMPLETE"
}

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
        echo -e "$red*** Error: $message. Saliendo con el código de error $exit_code ***$nocol" 
        exit $exit_code
    fi
}

blue='\033[0;34m'
cyan='\033[0;36m'
yellow='\033[0;33m'
red='\033[0;31m'
purple='\033[0;35m'  
green='\033[0;32m'   
white='\033[1;37m'   
gray='\033[0;37m'   
orange='\033[0;33m'
nocol='\033[0m'

initial_function() {
    echo -e "$purple***********************************************"
    echo "         INICIANDO $SCRIPT_NAME $SCRIPT_VERSION"
    echo -e "***********************************************$nocol"
    check_os
    show_status "Iniciando los procesos..." "STATUS"
    show_status "Creando directorios principales..." "STATUS"
    SCRIPT_DIR="$PWD"
    DEVICE_CODENAME_DIR="$(pwd)"
    BUILD_START=$(date +"%s")
    abort_if_error 
    show_status "Directorios principales creados." "COMPLETE"
}

cleanup_out() {
    show_status "Creando y configurando el directorio de salida..." "STATUS"
    cd $DEVICE_CODENAME_DIR
    sudo mkdir -p out
    sudo chmod -R 777 out
    show_status "Directorio de salida creado y configurado correctamente." "COMPLETE"
}

configure_build() {
    echo -e "$purple***********************************************"
    echo "          PREPARANDO COMPILACION          "
    echo -e "***********************************************$nocol"
    show_status "Iniciando instrucciones del script..." "STATUS"
    show_status "Configurando herramientas del script..." "STATUS"
    cd $DEVICE_CODENAME_DIR
    KERNEL_VERSION="kernelversion"
    ANY_KERNEL3_DIR="$DEVICE_CODENAME_DIR/AnyKernel3/"
    FINAL_KERNEL_ZIP="$KERNEL_NAME-$DEVICE_CODENAME-$BUILD_STATUS-$DATE_POSTFIX-$TIME_POSTFIX-$BUILD_TYPE.zip"
    export CROSS_COMPILE="$KERNEL_TOOLCHAIN_AARCH64"
    export CROSS_COMPILE_ARM32="$KERNEL_TOOLCHAIN_ARM32"
    export ARCH="$ARCH"
    export DTC_EXT="$DTC_EXT"
    export KBUILD_COMPILER_STRING="$CLANG_VERSION_STRING"
    MAKE="./makeparallel"
    abort_if_error
    show_status "Herramientas y Instrucciones configuradas correctamente." "COMPLETE"
}

configure_kernel() {
    echo -e "$purple***********************************************"
    echo "          CONFIGURANDO EL KERNEL          "
    echo -e "***********************************************$nocol"
    cd $DEVICE_CODENAME_DIR
    show_status "Configurando el kernel..." "STATUS"
    make $KERNEL_DEFCONFIG O=out
    show_status "Version del kernel..." "STATUS"
    make $KERNEL_VERSION O=out
    show_status "Se configuro correctamente el kernel." "COMPLETE"    
}

compile_kernel() {
    echo -e "$purple***********************************************"
    echo "             COMPILANDO KERNEL       "
    echo -e "***********************************************$nocol" 
    show_status "Iniciando la compilación del kernel..." "STATUS"
    cd $DEVICE_CODENAME_DIR
    export CC=gcc
    export CROSS_COMPILE=aarch64-linux-gnu-
    make O=out -j$(nproc)
    abort_if_error
}

verify_output_files() {
    echo -e "$purple***********************************************"
    echo "       VERIFICANDO ARCHIVOS DE SALIDA       "
    echo -e "***********************************************$nocol"
    show_status "Verificando archivos de salida..." "STATUS"
    if [ ! -e "$DEVICE_CODENAME_DIR/out/arch/arm64/boot/Image.gz" ] || [ ! -e "$DEVICE_CODENAME_DIR/out/arch/arm64/boot/Image.gz-dtb" ]; then
        echo -e "$red*** Error: Los archivos Image.gz o Image.gz-dtb no se encuentran. Compilación fallida.***$nocol"
        exit 1
    fi
    abort_if_error
    show_status "Archivos de salida verificados correctamente." "COMPLETE"
    echo -e "$green Compilación terminada con éxito.$nocol"
}

create_final_zip() {
    echo -e "$purple***********************************************"
    echo "            CREANDO ZIP FINAL           "
    echo -e "***********************************************$nocol"
    show_status "Creando archivo ZIP final..." "STATUS"
    show_status "Verificando Image.gz & Image.gz-dtb..." "STATUS"
    ls $DEVICE_CODENAME_DIR/out/arch/arm64/boot/Image.gz
    ls $DEVICE_CODENAME_DIR/out/arch/arm64/boot/Image.gz-dtb
    ls $ANY_KERNEL3_DIR
    show_status "Removiendo Archivos Anteriores..." "STATUS"
    sudo rm -rf $ANY_KERNEL3_DIR/Image.gz
    sudo rm -rf $ANY_KERNEL3_DIR/*.zip
    cp $DEVICE_CODENAME_DIR/out/arch/arm64/boot/Image.gz $ANY_KERNEL3_DIR/
    show_status "Image.gz Copiados." "COMPLETE"
    show_status "Comprimiendo ZIP!..." "STATUS"
    cd $ANY_KERNEL3_DIR
    zip -r9 $FINAL_KERNEL_ZIP * -x README $FINAL_KERNEL_ZIP
    rm -rf $DEVICE_CODENAME_DIR/zip/
    mkdir $DEVICE_CODENAME_DIR/zip/
    mv $DEVICE_CODENAME_DIR/AnyKernel3/*.zip $DEVICE_CODENAME_DIR/zip/$FINAL_KERNEL_ZIP
    echo -e "$green**** Archivo FINAL ZIP en $DEVICE_CODENAME_DIR/zip/$FINAL_KERNEL_ZIP ****"
    abort_if_error
    show_status "Archivo ZIP Creado correctamente." "COMPLETE"
}

clean_temp_files() {
    show_status "Borrando archivos temporales..." "STATUS"
    sudo rm -rf $ANY_KERNEL3_DIR/$FINAL_KERNEL_ZIP
    sudo rm -rf $DEVICE_CODENAME_DIR/AnyKernel3/Image.gz
    abort_if_error
    show_status "Archivos temporales borrados correctamente." "COMPLETE"
}

final_function() {
    echo -e "$purple***********************************************"
    echo    "      FINALIZANDO $SCRIPT_NAME $SCRIPT_VERSION      "
    echo -e "***********************************************$nocol"
    show_status "Procesos finalizados. ¡Adiós!" "COMPLETE"
    cd $DEVICE_CODENAME_DIR
    BUILD_END=$(date +"%s")
    DIFF=$(($BUILD_END - $BUILD_START))
    abort_if_error
    echo -e "$green Proceso terminado en $(($DIFF / 60)) minutos(s) y $(($DIFF % 60)) segundos.$nocol"
    echo -e "$green Proceso iniciado en $(date -d @$BUILD_START '+%Y-%m-%d %H:%M:%S').$nocol"
    echo -e "$green Proceso finalizado en $(date '+%Y-%m-%d %H:%M:%S').$nocol"
    exit 1
} 

main() {
    initial_function
    validate_environment_variables
    cleanup_out
    configure_build
    configure_kernel
    compile_kernel
    verify_output_files
    create_final_zip
    clean_temp_files
    final_function
}

main
