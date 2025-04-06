#!/usr/bin/sh

set -e
# set -x

. ./consts.sh

clean_dir() {
    _DIR=${1}

    # kind of dangerous ...
    [ "${_DIR}" = '/' ] && exit 1
    rm -rf "${_DIR}" || true
}

pin_commit() {
    _COMMIT=${1}
    _COMMIT_IS=$(git rev-parse HEAD)
    [ "${IGNORE_COMMITS}" != '0' ] || [ "${_COMMIT}" = "${_COMMIT_IS}" ] || (
        echo "Commit mismatch"
        exit 1
    )
}

patch_config() {
    # must be called when inside the `linux` dir
    key="$1"
    val="$2"

    if [ -z "$key" ] || [ -z "$val" ]; then
        exit 1
    fi

    case "$val" in
    'y')
        _OP='--enable'
        ;;
    'n')
        _OP='--disable'
        ;;
    'm')
        _OP='--module'
        ;;
    *)
        echo "Unknown kernel option value '$KERNEL'"
        exit 1
        ;;
    esac

    if [ -z "$_OP" ]; then
        exit 1
    fi

    ./scripts/config --file "../${DIR}-build/.config" "$_OP" "$key"
}

for DEP in riscv64-linux-gnu-gcc swig cpio; do
    check_deps ${DEP}
done

mkdir -p build
mkdir -p "${OUT_DIR}"
cd build

if [ ! -f "${OUT_DIR}/bootinfo_sd.bin" ] || [ ! -f "${OUT_DIR}/FSBL.bin" ] || [ ! -f "${OUT_DIR}/u-boot-env-default.bin" ] || [ ! -f "${OUT_DIR}/u-boot-opensbi.itb" ]; then
    # build U-Boot
    DIR='u-boot-orangepi'
    clean_dir ${DIR}

    git clone --depth 1 "${SOURCE_UBOOT}" -b "${SOURCE_UBOOT_BRANCH}"
    cd ${DIR}
    pin_commit "${COMMIT_UBOOT}"

    make CROSS_COMPILE="${CROSS_COMPILE}" ARCH="${ARCH}" x1_defconfig
    make CROSS_COMPILE="${CROSS_COMPILE}" ARCH="${ARCH}" DEVICE_TREE='x1_orangepi-rv2' -j "${NPROC}"
    cd ..

    # https://github.com/orangepi-xunlong/orangepi-build/blob/36a2f27f9b2d064331e4e22ccd384e0d269dbd31/external/config/sources/families/ky.conf#L41C1-L44C86
    cp ${DIR}/bootinfo_sd.bin "${OUT_DIR}"
    cp ${DIR}/FSBL.bin "${OUT_DIR}"
    cp ${DIR}/u-boot-env-default.bin "${OUT_DIR}"
    cp ${DIR}/u-boot-opensbi.itb "${OUT_DIR}"
fi

if [ ! -f "${OUT_DIR}/Image" ] || [ ! -f "${OUT_DIR}/Image.gz" ]; then
    # build kernel
    DIR='linux-orangepi'
    clean_dir ${DIR}
    clean_dir ${DIR}-build
    clean_dir ${DIR}-modules

    # try not to clone complete linux source tree here!
    git clone --depth 1 "${SOURCE_KERNEL}" -b "${SOURCE_KERNEL_BRANCH}"
    cd ${DIR}
    pin_commit "${COMMIT_KERNEL}"

    # fix kernel version
    touch .scmversion

    case "$KERNEL" in
    'upstream')
        # generate default config
        make ARCH="${ARCH}" O=../${DIR}-build x1_defconfig
        curl "${SOURCE_KERNEL_CONFIG}" -o ../${DIR}-build/.config

        # patch necessary options
        patch_config RTL8852BS n # fails to build
        patch_config RTL8852BE n # fails to build
        patch_config BCMDHD n    # fails to build
        # enable swap
        # patch_config SWAP y # already set
        patch_config ZSWAP y

        # debug options
        if [ $DEBUG = 'y' ]; then
            patch_config DEBUG_INFO y
        fi

        # default anything new
        make ARCH="${ARCH}" O=../${DIR}-build olddefconfig

        ;;

    # 'arch')
    #     # generate default config (and directory)
    #     make ARCH="${ARCH}" O=../linux-build defconfig

    #     # deploy Arch's confi
    #     # TODO keep this up to date automatically somehow
    #     cp ../../6.3.5-arch1.config ../linux-build/.config

    #     # THIS DOESN'T WORK RIGHT NOW
    #     # TODO

    #     # default anything new
    #     make ARCH="${ARCH}" O=../linux-build olddefconfig

    #     ;;

    *)
        echo "Unknown kernel option '$KERNEL'"
        exit 1
        ;;
    esac

    # compile it!
    cd ..
    make CROSS_COMPILE="${CROSS_COMPILE}" ARCH="${ARCH}" -j "${NPROC}" -C ${DIR}-build

    KERNEL_RELEASE=$(make ARCH="${ARCH}" -C ${DIR}-build -s kernelversion)
    echo "compiled kernel version '$KERNEL_RELEASE'"

    cp ${DIR}-build/arch/riscv/boot/Image.gz "${OUT_DIR}"
    cp ${DIR}-build/arch/riscv/boot/Image "${OUT_DIR}"

    # prepare modules
    mkdir ${DIR}-modules
    make ARCH="${ARCH}" INSTALL_MOD_PATH="../${DIR}-modules" KERNELRELEASE="${KERNEL_RELEASE}" -C ${DIR}-build modules_install
    mv ${DIR}-modules/lib/modules "${OUT_DIR}"
fi
