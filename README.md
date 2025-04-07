# Image Builder for Archlinux on a Ky X1 (Spacemit K1) OrangePI RV2
These scripts compile, copy, bake, unpack and flash a [ready](https://wiki.archlinux.org/title/installation_guide#Configure_the_system) to use RISC-V Archlinux.
*With "ready to use" i mean that it boots, you still need to configure everything!*

Based on https://github.com/sehraf/d1-riscv-arch-image-builder

**WORK IN PROGESS**

## Components
- U-Boot based on https://github.com/orangepi-xunlong/u-boot-orangepi.git
- kernel based on https://github.com/orangepi-xunlong/linux-orangepi.git
- RootFS based on https://archriscv.felixc.at (root password is `archriscv`)

## How to build
1. Install requirements: `pacman -Sy riscv64-linux-gnu-gcc swig cpio python3 python-setuptools base-devel bc`
   1. If you want to `chroot` into the RISC-V image, you also need `arch-install-scripts qemu-user-static qemu-user-static-binfmt`
1. Edit `consts.sh` to your needs.
1. Run `1_compile.sh` which compiles everything into the `output` folder.
1. Run `2_create_sd.sh /dev/<device>` to flash everything on the SD card.
1. Configure your Archlinux :rocket:

## Using loop image file instead of a SD card
Simply loop it using `sudo losetup -f -P <file>` and then use `/dev/loopX` as the target device.

## Notes
The second script requires `arch-install-scripts`, `qemu-user-static-bin` (AUR) and `binfmt-qemu-static` (AUR) for an architectural chroot.
If you don't want to use/do this, change `USE_CHROOT` to `0` in `consts.sh`.
*Keep in mind, that this is just a extracted rootfs with **no** configuration. You probably want to update the system, install an editor and take care of network access/ssh*

Some commits are pinned, this means that in the future this script might stop working since often a git HEAD is checked out. This is intentional.

The second script uses `sudo` for root access. Like any random script from a random stranger from the internet, have a look at the code first and use at own risk!

Things are rebuild whenever the corresponding `output/<file>` is missing. For example, the kernel is rebuilt when there is no `Image` file.

# Status
## 07.04.2025
When providing `ky/x1_orangepi-rv2.dtb` (as `x1.dtb`) the console works (`console=ttyS0,115200` is correct). UART5, 8 and 9 are disabled (requires overlays).

Kernel throws a bunch of `kernfs: can not remove 'xyz', no directory` and `refcount_t: underflow; use-after-free.`, then hangs:
```
[   30.045990] rcu: INFO: rcu_preempt detected stalls on CPUs/tasks:
[   30.052194] rcu:     0-...0: (12 GPs behind) idle=57bc/1/0x4000000000000002 softirq=73/73 fqs=2625
[   30.061015] rcu:     3-...0: (0 ticks this GP) idle=b7f4/1/0x4000000000000000 softirq=101/101 fqs=2625
[   30.070205] rcu:     (detected by 4, t=5252 jiffies, g=-827, q=1 ncpus=8)
[   30.076822] Task dump for CPU 0:
[   30.080091] task:swapper/0       state:R  running task     stack:0     pid:0     ppid:0      flags:0x00000008
[   30.090155] Call Trace:
[   30.092620] [<ffffffff80f2e8e2>] __schedule+0x338/0xa90
[   30.097921] [<ffffffff80f2ce38>] default_idle_call+0x24/0xda
[   30.103656] Task dump for CPU 3:
[   30.106914] task:swapper/0       state:R  running task     stack:0     pid:1     ppid:0      flags:0x0000000a
[   30.116974] Call Trace:
[   30.119449] [<ffffffff80f2e8e2>] __schedule+0x338/0xa90
[   30.124751] [<ffffffff806fd0e8>] __devm_reset_control_get+0x42/0x9c
```


## 06.04.2025
Currently it is not fully working. The kernel gets booted, but seems to hang at some point. Console is lost once the kernel switches away from `bootconsole`...

```
[   5.649] switch to partitions #0, OK
[   5.649] mmc0 is current device
[   5.763] Scanning mmc 0:1...
[   5.792] Found /extlinux/extlinux.conf
[   5.792] Retrieving file: /extlinux/extlinux.conf
[   5.829] 1:   default
[   5.829] Retrieving file: /Image
[   8.724] append: earlycon=sbi console=ttyS0,115200 console=ttyS9,115200 console=ttyS8,115200 console=tty0 root=/dev/mmcblk0p2 rootwait
[   8.733] Retrieving file: /dtbs/x1.dtb
[   8.761] ** File not found /dtbs/x1.dtb **
[   8.762] Moving Image from 0x11000000 to 0x200000, end=238c000
[   8.781] ## Flattened Device Tree blob at 7de9a930
[   8.782]    Booting using the fdt blob at 0x7de9a930
[   8.888]    Loading Device Tree to 000000007dd7d000, end 000000007dd8f417 ... OK

Starting kernel ...

[    0.000000] Linux version 6.6.63+ (...) (riscv64-linux-gnu-gcc (GCC) 14.2.0, GNU ld (GNU Binutils) 2.43.1) #1 SMP PREEMPT Tue Apr  1 16:04:57 CEST 2025
[    0.000000] Machine model: ky x1 orangepi-rv2 board
[    0.000000] SBI specification v1.0 detected
[    0.000000] SBI implementation ID=0x1 Version=0x10003
[    0.000000] SBI IPI extension detected
[    0.000000] SBI RFENCE extension detected
[    0.000000] earlycon: sbi0 at I/O port 0x0 (options '')
[    0.000000] printk: bootconsole [sbi0] enabled
[    0.000000] efi: UEFI not found.
[    0.000000] OF: reserved mem: 0x0000000000000000..0x000000000007ffff (512 KiB) nomap non-reusable mmode_resv0@0
[    0.000000] OF: reserved mem: 0x000000007f000000..0x000000007fffffff (16384 KiB) map non-reusable framebuffer@7f000000
[    0.000000] cma: Reserved 16 MiB at 0x000000007e000000 on node -1
[    0.000000] Zone ranges:
[    0.000000]   DMA32    [mem 0x0000000000000000-0x000000007fffffff]
[    0.000000]   Normal   [mem 0x0000000080000000-0x000000017fffffff]
[    0.000000] Movable zone start for each node
[    0.000000] Early memory node ranges
[    0.000000]   node   0: [mem 0x0000000000000000-0x000000000007ffff]
[    0.000000]   node   0: [mem 0x0000000000080000-0x000000007fffffff]
[    0.000000]   node   0: [mem 0x0000000100000000-0x000000017fffffff]
[    0.000000] Initmem setup node 0 [mem 0x0000000000000000-0x000000017fffffff]
[    0.000000] On node 0, zone Normal: 524288 pages in unavailable ranges
[    0.000000] SBI HSM extension detected
[    0.000000] Falling back to deprecated "riscv,isa"
[    0.000000] riscv: base ISA extensions acdfimv
[    0.000000] riscv: ELF capabilities acdfimv
[    0.000000] percpu: Embedded 29 pages/cpu s81784 r8192 d28808 u118784
[    0.000000] pcpu-alloc: s81784 r8192 d28808 u118784 alloc=29*4096
[    0.000000] pcpu-alloc: [0] 0 [0] 1 [0] 2 [0] 3 [0] 4 [0] 5 [0] 6 [0] 7
[    0.000000] Kernel command line: earlycon=sbi console=ttyS0,115200 console=ttyS9,115200 console=ttyS8,115200 console=tty0 root=/dev/mmcblk0p2 rootwait
[    0.000000] Dentry cache hash table entries: 524288 (order: 10, 4194304 bytes, linear)
[    0.000000] Inode-cache hash table entries: 262144 (order: 9, 2097152 bytes, linear)
[    0.000000] Built 1 zonelists, mobility grouping on.  Total pages: 1024000
[    0.000000] mem auto-init: stack:off, heap alloc:off, heap free:off
[    0.000000] software IO TLB: area num 8.
[    0.000000] software IO TLB: mapped [mem 0x0000000079d7d000-0x000000007dd7d000] (64MB)
[    0.000000] Memory: 3954196K/4194304K available (15570K kernel code, 6865K rwdata, 8192K rodata, 2308K init, 596K bss, 223724K reserved, 16384K cma-reserved)
[    0.000000] SLUB: HWalign=64, Order=0-3, MinObjects=0, CPUs=8, Nodes=1
[    0.000000]
[    0.000000] **********************************************************
[    0.000000] **   NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE   **
[    0.000000] **                                                      **
[    0.000000] ** trace_printk() being used. Allocating extra memory.  **
[    0.000000] **                                                      **
[    0.000000] ** This means that this is a DEBUG kernel and it is     **
[    0.000000] ** unsafe for production use.                           **
[    0.000000] **                                                      **
[    0.000000] ** If you see this message and you are not debugging    **
[    0.000000] ** the kernel, report this immediately to your vendor!  **
[    0.000000] **                                                      **
[    0.000000] **   NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE   **
[    0.000000] **********************************************************
[    0.000000] trace event string verifier disabled
[    0.000000] rcu: Preemptible hierarchical RCU implementation.
[    0.000000]  Trampoline variant of Tasks RCU enabled.
[    0.000000]  Tracing variant of Tasks RCU enabled.
[    0.000000] rcu: RCU calculated value of scheduler-enlistment delay is 25 jiffies.
[    0.000000] NR_IRQS: 64, nr_irqs: 64, preallocated irqs: 0
[    0.000000] riscv-intc: 64 local interrupts mapped
[    0.000000] plic: interrupt-controller@e0000000: mapped 159 interrupts with 8 handlers for 16 contexts.
[    0.000000] riscv: providing IPIs using SBI IPI extension
[    0.000000] rcu: srcu_init: Setting srcu_struct sizes based on contention.
[    0.000000] failed to map rcpu registers
[    0.000000] Found CPU without hart ID
[    0.000000] riscv-timer: Invalid hartid for node [] error = [18446744073709551615]
[    0.000000] Failed to initialize '': -19
[    0.000000] clocksource: riscv_clocksource: mask: 0xffffffffffffffff max_cycles: 0x588fe9dc0, max_idle_ns: 440795202592 ns
[    0.000000] sched_clock: 64 bits at 24MHz, resolution 41ns, wraps every 4398046511097ns
[    0.008325] Console: colour dummy device 80x25
[    0.012630] printk: console [tty0] enabled
[    0.016757] printk: bootconsole [sbi0] disabled

```
