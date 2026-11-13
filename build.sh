#!/bin/bash
BUILD_START=$(date +"%s")
tcdir=${HOME}/android/TOOLS/GCC

# Fix error '/usr/bin/env: python2: No such file or directory'
mkdir -p ${HOME}/bin
if ! command -v python2 &> /dev/null; then
    ln -sf $(which python3) ${HOME}/bin/python2
fi
export PATH="${HOME}/bin:${PATH}"

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
    Image.gz dtbs || { echo "Build gagal! Menjalankan ulang dengan -j1:"; make -j1 O=out ARCH=arm64 CROSS_COMPILE=aarch64-linux-android- CROSS_COMPILE_ARM32=arm-linux-androideabi- HOSTCFLAGS="-fcommon -Wno-error" KCFLAGS="-Wno-error" Image.gz dtbs; exit 1; }
    
# Generate dt.img baru menggunakan dtbtool.c jika ada di folder anykernel3
if [ -f "anykernel3/dtbtool.c" ]; then
    gcc -o anykernel3/dtbtool anykernel3/dtbtool.c
    DTB_DIR=$(find out/arch/arm64/boot/dts -name "*.dtb" -printf "%h\n" | head -n 1)
    if [ -n "$DTB_DIR" ]; then
        echo "Menjalankan dtbtool pada direktori: $DTB_DIR"
        ./anykernel3/dtbtool -s 2048 -o out/arch/arm64/boot/dt.img -p out/scripts/dtc/ "$DTB_DIR/"
    else
        echo "File .dtb tidak ditemukan di out/arch/arm64/boot/dts!"
    fi
    rm -f anykernel3/dtbtool
fi

cp out/arch/arm64/boot/Image.gz anykernel3/
cp out/arch/arm64/boot/dt.img anykernel3/

echo "Isi folder anykernel3 sebelum di-zip:"
ls -lh anykernel3/

( cd anykernel3; zip -r ../out/A37F_KERNEL_ASU_$(date +%d.%m.%Y).zip * -x 'LICENSE' 'README.md' 'dtbtool.c' )

BUILD_END=$(date +"%s")
DIFF=$(($BUILD_END - $BUILD_START))
echo -e "\e[1;32mBuild completed in $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) seconds.\e[0m"
