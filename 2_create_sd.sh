#!/usr/bin/sh

set -e
# set -x

. ./consts.sh

check_root_fs() {
    if [ ! -f "${ROOT_FS}" ]; then
        wget "${ROOT_FS_DL}"
    fi
}

check_sd_card_is_block_device() {
    _DEVICE=${1}

    if [ -z "${_DEVICE}" ] || [ ! -b "${_DEVICE}" ]; then
        echo "Error: '${_DEVICE}' is empty or not a block device"
        exit 1
    fi
}

check_required_file() {
    if [ ! -f "${1}" ]; then
        echo "Missing file: ${1}, did you compile everything first?"
        exit 1
    fi
}

check_required_folder() {
    if [ ! -d "${1}" ]; then
        echo "Missing directory: ${1}, did you compile everything first?"
        exit 1
    fi
}

probe_partition_separator() {
    _DEVICE=${1}

    [ -b "${_DEVICE}p1" ] && echo 'p' || echo ''
}

DEVICE=${1}

if [ "${USE_CHROOT}" != 0 ]; then
    # check_deps for arch-chroot on non RISC-V host
    for DEP in arch-install-scripts qemu-user-static qemu-user-static-binfmt; do
        check_deps ${DEP}
    done
fi
check_sd_card_is_block_device "${DEVICE}"
check_root_fs
for FILE in bootinfo_sd.bin FSBL.bin u-boot-env-default.bin u-boot-opensbi.itb Image.gz Image; do
    check_required_file "${OUT_DIR}/${FILE}"
done
# shellcheck disable=SC2043
for DIR in modules; do
    check_required_folder "${OUT_DIR}/${DIR}"
done

# format disk
if [ -z "${CI_BUILD}" ]; then
    echo "Formatting ${DEVICE}, this will REMOVE EVERYTHING on it!"
    printf "Continue? (y/N): "
    read -r confirm && [ "${confirm}" = "y" ] || [ "${confirm}" = "Y" ] || exit 1
fi

${SUDO} dd if=/dev/zero of="${DEVICE}" bs=1M count=40
${SUDO} parted -s -a optimal -- "${DEVICE}" mklabel gpt
${SUDO} parted -s -a optimal -- "${DEVICE}" mkpart primary fat32 30MiB 1024MiB
${SUDO} parted -s -a optimal -- "${DEVICE}" mkpart primary ext4 1054MiB 100%
${SUDO} partprobe "${DEVICE}"
PART_IDENTITYFIER=$(probe_partition_separator "${DEVICE}")
${SUDO} mkfs.ext2 -F -L boot "${DEVICE}${PART_IDENTITYFIER}1"
${SUDO} mkfs.ext4 -F -L root "${DEVICE}${PART_IDENTITYFIER}2"

# flash boot things
# https://github.com/orangepi-xunlong/orangepi-build/blob/36a2f27f9b2d064331e4e22ccd384e0d269dbd31/external/config/sources/families/ky.conf#L41C1-L44C86
${SUDO} dd if="${OUT_DIR}/bootinfo_sd.bin" of="${DEVICE}"bs=1024 seek=0
${SUDO} dd if="${OUT_DIR}/FSBL.bin" of="${DEVICE}"bs=1024 seek=256
${SUDO} dd if="${OUT_DIR}/u-boot-env-default.bin" of="${DEVICE}"bs=1024 seek=768
${SUDO} dd if="${OUT_DIR}/u-boot-opensbi.itb" of="${DEVICE}" bs=1024 seek=1664

# mount it
mkdir -p "${MNT}"
${SUDO} mount "${DEVICE}${PART_IDENTITYFIER}2" "${MNT}"
${SUDO} mkdir -p "${MNT}/boot"
${SUDO} mount "${DEVICE}${PART_IDENTITYFIER}1" "${MNT}/boot"

# extract rootfs
${SUDO} tar -xv --zstd -f "${ROOT_FS}" -C "${MNT}"

# install kernel and modules
KERNEL_RELEASE=$(ls output/modules)
${SUDO} cp "${OUT_DIR}/Image.gz" "${OUT_DIR}/Image" "${MNT}/boot/"

${SUDO} mkdir -p "${MNT}/lib/modules"
${SUDO} cp -a "${OUT_DIR}/modules/${KERNEL_RELEASE}" "${MNT}/lib/modules"

${SUDO} rm "${MNT}/lib/modules/${KERNEL_RELEASE}/build"
${SUDO} depmod -a -b "${MNT}" "${KERNEL_RELEASE}"

# install U-Boot
if [ "${BOOT_METHOD}" = 'script' ]; then
    ${SUDO} cp "${OUT_DIR}/boot.scr" "${MNT}/boot/"
elif [ "${BOOT_METHOD}" = 'extlinux' ]; then
    ${SUDO} mkdir -p "${MNT}/boot/extlinux"
    (
        echo "label default
        linux   /Image
        append  earlycon=sbi console=ttyS0,115200 console=ttyS9,115200 console=tty1 root=/dev/mmcblk0p2 rootwait" # not use if `ttyS9` is correct
    ) >extlinux.conf
    ${SUDO} mv extlinux.conf "${MNT}/boot/extlinux/extlinux.conf"
fi
# These are used by OrangePI
# clk_ignore_unused swiotlb=65536 workqueue.default_affinity_scope=system cgroup_enable=cpuset cgroup_memory=1 cgroup_enable=memory swapaccount=1

# fstab
(
    echo '# <device>    <dir>        <type>        <options>            <dump> <pass>
LABEL=boot    /boot        ext2          rw,defaults,noatime  0      1
LABEL=root    /            ext4          rw,defaults,noatime  0      2'
) >fstab
${SUDO} mv fstab "${MNT}/etc/fstab"

# set hostname
echo 'orangepirv2' >hostname
${SUDO} mv hostname "${MNT}/etc/"

# done
if [ "${USE_CHROOT}" != 0 ]; then
    echo ''
    echo 'Done! Now configure your new Archlinux!'
    echo ''
    echo 'You might want to update and install an editor as well as configure any network'
    echo ' -> https://wiki.archlinux.org/title/installation_guide#Configure_the_system'
    echo ''
    ${SUDO} arch-chroot "${MNT}" || true
else
    echo ''
    echo 'Done!'
fi

${SUDO} umount -R "${MNT}"
exit 0
