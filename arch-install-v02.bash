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

#########################################
#### Nuke and set up disk partitions ####
#########################################
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

######################
#### Install Arch ####
######################

mount /dev/vg00/lv_root /mnt
mkdir /mnt/{home,etc}
mkdir -p $GRUBDIR
mount "${DISK_EFI}" $GRUBDIR
mount /dev/vg00/lv_home /mnt/home

yes '' | pacstrap -i /mnt base base-devel

mkdir -p /mnt/etc/
genfstab -U -p /mnt >> /mnt/etc/fstab

###############################
#### Configure base system ####
###############################
arch-chroot /mnt /bin/bash

echo "Setting and generating locale"
echo "en_US.UTF-8 UTF-8" > /etc/locale.gen
locale-gen

export LANG=$LANGUAGE
echo "LANG=${LANGUAGE}" >> /etc/locale.conf

echo "Setting time zone"
ln -s /usr/share/zoneinfo/$TIMEZONE /etc/localtime
timedatectl set-timezone $TIMEZONE
hwclock --systohc --utc

echo "Installing main packages"
pacman --noconfirm --needed -Syu linux linux-firmware linux-headers

echo "Installing network packages"
pacman --noconfirm --needed -Syu networkmanager wpa_supplicant wireless_tools netctl dialog

echo "Setting network configuration"
echo $hostname > /etc/hostname
echo "127.0.0.1 localhost" >> /etc/hosts
echo "::1       localhost" >> /etc/hosts
echo "127.0.1.1 ${hostname}.localdomain ${hostname}" >> /etc/hosts

echo "Initramfs"
mkinitcpio -P

echo "Install CPU Microde files"
pacman --noconfirm --needed -Syu amd-ucode

echo "Installing LVM"
pacman --noconfirm --needed -Syu lvm2

echo "Installing Editor"
pacman --noconfirm --needed -Syu nano

echo "Installing file systems"
pacman --noconfirm --needed -Syu btrfs-progs dosfstools exfatprogs e2fsprogs ntfs-3g xfsprogs

echo "Generating initramfs"
sed -i 's/^HOOKS.*/HOOKS="base udev autodetect modconf block lvm2 filesystems keyboard fsck"/' /etc/mkinitcpio.conf
mkinitcpio -p linux

echo "Setting root password"
echo "root:${root_password}" | chpasswd

echo "Adding new user"
useradd -mg users -G wheel,storage,power -s /bin/bash $user_name

echo "Setting user password"
echo "${user_name}:${user_password}" | chpasswd
EDITOR=nano visudo

echo "Installing Grub boot loader"
pacman --noconfirm --needed -Syu grub efibootmgr dosfstools os-prober mtools
grub-install --target=x86_64-efi --efi-directory=$GRUBDIR --bootloader-id=GRUB

#sed -i 's|^GRUB_CMDLINE_LINUX_DEFAULT.*|GRUB_CMDLINE_LINUX_DEFAULT="nouveau.modeset=0"|' /etc/default/grub
grub-mkconfig -o /boot/grub/grub.cfg
cp /usr/share/locale/en\@quot/LC_MESSAGES/grub.mo /boot/grub/locale/en.mo

echo "Swap File"
dd if=/dev/zero of=/swapfile bs=1M count=2048 status=progress
chmod 600 /swapfile
mkswap /swapfile
cp /etc/fstab /etc/fstab.bak
echo '/swapfile none swap sw 0 0' | tee -a /etc/fstab

echo "Enabling systemctls"
systemctl enable NetworkManager
systemctl enable systemd-timesyncd




printf "\e[1;32mDone! Type exit, umount -a and reboot.\e[0m"






