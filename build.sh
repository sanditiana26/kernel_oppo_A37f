#!/bin/bash
BUILD_START=$(date +"%s")
tcdir=${HOME}/android/TOOLS/GCC

[ -d "out" ] && rm -rf out && mkdir -p out || mkdir -p out

# Hapus sisa file kernel lama di folder anykernel3 agar tidak bentrok
rm -f anykernel3/Image anykernel3/Image.gz anykernel3/Image.gz-dtb anykernel3/zImage*

export ARCH=arm64
export SUBARCH=arm64
export PATH="$tcdir/los-4.9-64/bin:$tcdir/los-4.9-32/bin:${PATH}"

make O=out ARCH=arm64 cinnamon_a37f_defconfig

make -j$(nproc --all) O=out \
    ARCH=arm64 \
    SUBARCH=arm64 \
    CC="ccache aarch64-linux-android-gcc" \
    CROSS_COMPILE=aarch64-linux-android- \
    CROSS_COMPILE_ARM32=arm-linux-androideabi- \
    HOSTCFLAGS="-fcommon -Wno-error" \
    KCFLAGS="-Wno-error" \
    CONFIG_NO_ERROR_ON_MISMATCH=y \
    CONFIG_DEBUG_SECTION_MISMATCH=y \
    Image.gz dtbs || { echo "Build gagal! Menjalankan ulang dengan -j1 untuk melihat error pasti:"; make -j1 O=out ARCH=arm64 CROSS_COMPILE=aarch64-linux-android- CROSS_COMPILE_ARM32=arm-linux-androideabi- Image.gz dtbs; exit 1; }
