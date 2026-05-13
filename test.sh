#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ISO_DIR="$SCRIPT_DIR/out"
TEST_IMG="/tmp/test_$$.img"
IMG_SIZE="20G"
CORES=8
RAM="8G"

# 查找最新构建的 ISO
ISO=$(find "$ISO_DIR" -maxdepth 1 -name "archlinux-*.iso" -printf '%T@ %p\n' 2>/dev/null | sort -rn | head -1 | cut -d' ' -f2-)
if [ -z "$ISO" ]; then
    echo "未找到 ISO，请先运行 sudo ./build.sh 构建"
    exit 1
fi

# 查找 OVMF
OVMF_CODE=$(find /usr/share/edk2 /usr/share/ovmf /usr/share/qemu -name 'OVMF_CODE*' -not -name '*.secboot.*' -print -quit 2>/dev/null || true)
OVMF_VARS_TEMPLATE=$(find /usr/share/edk2 /usr/share/ovmf /usr/share/qemu -name 'OVMF_VARS*' -print -quit 2>/dev/null || true)
OVMF_VARS="/tmp/ovmf_vars_$$.fd"

if [ -z "$OVMF_CODE" ]; then
    echo "未找到 OVMF 固件，请安装 edk2-ovmf"
    exit 1
fi

cleanup() {
    echo ""
    echo "清理: 删除 $TEST_IMG"
    rm -f "$TEST_IMG" "$OVMF_VARS"
    echo "完成。"
}
trap cleanup EXIT

# 创建磁盘镜像
echo "创建 $TEST_IMG ($IMG_SIZE)..."
qemu-img create -f qcow2 "$TEST_IMG" "$IMG_SIZE"

# 复制可变 OVMF 固件
if [ -n "$OVMF_VARS_TEMPLATE" ]; then
    cp "$OVMF_VARS_TEMPLATE" "$OVMF_VARS"
fi

echo "启动 QEMU..."
echo "  ISO:   $ISO"
echo "  磁盘:  $TEST_IMG"
echo "  CPU:   $CORES 核"
echo "  内存:  $RAM"
echo "  固件:  UEFI"

qemu-system-x86_64 \
    -enable-kvm \
    -machine q35 \
    -smp "$CORES" \
    -m "$RAM" \
    -cpu host \
    -drive if=pflash,format=raw,readonly=on,file="$OVMF_CODE" \
    ${OVMF_VARS:+ -drive if=pflash,format=raw,file="$OVMF_VARS"} \
    -cdrom "$ISO" \
    -drive file="$TEST_IMG",format=qcow2,if=virtio \
    -device virtio-vga-gl \
    -display gtk,gl=on \
    -device virtio-keyboard-pci \
    -device virtio-mouse-pci \
    -nic user,model=virtio-net-pci \
    -device intel-hda \
    -device hda-duplex \
    -usb \
    -device usb-tablet
