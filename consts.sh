#!/usr/bin/sh
export CROSS_COMPILE='riscv64-linux-gnu-'
export ARCH='riscv'
PWD="$(pwd)"
NPROC="$(nproc)"
export PWD
export NPROC

export ROOT_FS='archriscv-2024-09-22.tar.zst'
export ROOT_FS_DL="https://archriscv.felixc.at/images/${ROOT_FS}"

# select 'upstream'
export KERNEL='upstream'

# Device Tree:
export DEVICE_TREE=sun20i-d1-lichee-rv-dock

# folder to mount rootfs
export MNT="${PWD}/mnt"
# folder to store compiled artifacts
export OUT_DIR="${PWD}/output"

# run as root
export SUDO='sudo'

# use arch-chroot?
export USE_CHROOT=1 # REQUIRED for initramfs generation

# enable systemd networkd, resolved and timesyncd?
export SETUP_LAN=1 # requires chroot
if [ "${USE_CHROOT}" = 0 ]; then
    export SETUP_LAN=0
fi

# use extlinux ('extlinux') for loading the kernel
export BOOT_METHOD='extlinux'

export SOURCE_UBOOT='https://github.com/orangepi-xunlong/u-boot-orangepi.git'
export SOURCE_UBOOT_BRANCH='v2022.10-ky'
export SOURCE_KERNEL='https://github.com/orangepi-xunlong/linux-orangepi.git'
export SOURCE_KERNEL_BRANCH='orange-pi-6.6-ky'
export SOURCE_KERNEL_CONFIG='https://raw.githubusercontent.com/orangepi-xunlong/orangepi-build/c5b3b1df7029ddb4adb63d63d0f093c24e0180cf/external/config/kernel/linux-ky-current.config'
export SOURCE_FIRMWARE_ESOS='https://gitee.com/bianbu-linux/buildroot-ext/raw/k1-bl-v2.1.y/board/spacemit/k1/target_overlay/lib/firmware/esos.elf' # md5: c32d991090d43247b9bce0a3422f76ce

# pinned commits (no notice when things change)
export COMMIT_UBOOT='89bff4a7e4cadfb5f130edb1ec44c39bff20a427'  # equals v2022.10-ky 28.03.2025
export COMMIT_KERNEL='ae9e974d3e19f460b6397bfe8f0f1417a073ce05' # equals orange-pi-6.6-ky 28.03.2025
# use this (set to something != 0) to override the check
export IGNORE_COMMITS=0

export DEBUG='n'

check_deps() {
    if ! pacman -Qi "${1}" >/dev/null; then
        echo "Please install '${1}'"
        exit 1
    fi
}

if [ -n "${CI_BUILD}" ]; then
    export USE_CHROOT=0
fi
