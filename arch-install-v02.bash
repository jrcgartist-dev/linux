#!/bin/bash

LMV=1
hostname=arch
user_name=kobe24
root_password=password
user_password=password
DISK=/dev/sda
DISK_EFI=/dev/sda1
DISK_MNT=/dev/sda2
TIMEZONE=America/Sao_Paulo
LANGUAGE=en_US.UTF-8
GRUBDIR=/mnt/boot/EFI
GNOME=1
AUR_PACK=true
PACKAGES_AUR_INSTALL=true
PACKAGES_AUR_COMMAND=paru


echo "Update System Clock"
timedatectl set-ntp true

sleep 5

echo "###########################################################################"
echo "Partition"
echo "###########################################################################"

echo "Zapping disk"
sgdisk --zap-all $DISK

swapoff --all
umount --recursive /mnt
lvremove --force system/root
lvremove --force system/swap
vgremove --force system

echo "Creating EFI Partition"
if [[ $LMV -eq 1 ]]; then
    printf "n\n1\n\n+512M\nef00\nw\ny\n" | gdisk $DISK
    yes | mkfs.fat -F32 "${DISK_EFI}"
else
    printf "n\n1\n\n+512M\nef00\nw\ny\n" | gdisk $DISK
   yes | mkfs.fat -F32 "${DISK_EFI}"
fi

echo "Creating Main Partition"
if [[ $LMV -eq 1 ]]; then
    printf "n\n2\n\n\n8e00\nw\ny\n"| gdisk /dev/sda
else
    printf "n\n2\n\n\n8300\nw\ny\n"| gdisk /dev/sda
   yes | mkfs.fat -F32 "${DISK_MNT}"
fi

echo "###########################################################################"
echo "Partition - END"
echo "###########################################################################"

sleep 5

echo "###########################################################################"
echo "Setting up LVM - START"
echo "###########################################################################"

echo "Setting up LVM"
pvcreate --dataalignment 1m "${DISK_MNT}"
vgcreate vg00 "${DISK_MNT}"
lvcreate -L 10G vg00 -n lv_root
lvcreate -l +100%FREE vg00 -n lv_home
modprobe dm_mod
vgscan
vgchange -ay
sleep 5

echo "Creating file systems on top of logical volumes"
yes | mkfs.ext4 /dev/vg00/lv_root
yes | mkfs.ext4 /dev/vg00/lv_home

echo "###########################################################################"
echo "Setting up LVM - END"
echo "###########################################################################"

sleep 5

echo "###########################################################################"
echo "Mounting - START"
echo "###########################################################################"

mount /dev/vg00/lv_root /mnt
mkdir /mnt/{home,etc}
mkdir -p $GRUBDIR
mount "${DISK_EFI}" $GRUBDIR
mount /dev/vg00/lv_home /mnt/home

echo "###########################################################################"
echo "Mounting - END"
echo "###########################################################################"

sleep 5

echo "###########################################################################"
echo "Create the /etc/fstab file - START"
echo "###########################################################################"

genfstab -U -p /mnt >> /mnt/etc/fstab

echo "###########################################################################"
echo "Create the /etc/fstab file - END"
echo "###########################################################################"

sleep 5


echo "###########################################################################"
echo "###########################################################################"
echo "Install Arch Linux"
echo "###########################################################################"
echo "###########################################################################"



pacstrap -i /mnt base base-devel

arch-chroot /mnt
