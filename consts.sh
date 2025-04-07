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
export USE_CHROOT=1

# use extlinux ('extlinux') for loading the kernel
export BOOT_METHOD='extlinux'

export SOURCE_UBOOT='https://github.com/orangepi-xunlong/u-boot-orangepi.git'
export SOURCE_UBOOT_BRANCH='v2022.10-ky'
export SOURCE_KERNEL='https://github.com/orangepi-xunlong/linux-orangepi.git'
export SOURCE_KERNEL_BRANCH='orange-pi-6.6-ky'
export SOURCE_KERNEL_CONFIG='https://raw.githubusercontent.com/orangepi-xunlong/orangepi-build/c5b3b1df7029ddb4adb63d63d0f093c24e0180cf/external/config/kernel/linux-ky-current.config'

# pinned commits (no notice when things change)
export COMMIT_UBOOT='89bff4a7e4cadfb5f130edb1ec44c39bff20a427' # equals v2022.10-ky 28.03.2025
export COMMIT_KERNEL='ae9e974d3e19f460b6397bfe8f0f1417a073ce05' # euqals orange-pi-6.6-ky 28.03.2025
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
