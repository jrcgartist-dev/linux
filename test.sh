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

arch-chroot /mnt /bin/bash


echo "###########################################################################"
echo "Install essential packages"
echo "###########################################################################"

pacman -S --needed linux linux-firmware linux-headers

sleep 2


echo "###########################################################################"
echo "Text Editor packages"
echo "###########################################################################"

pacman -S --needed nano openssh
sleep 2
systemctl enable sshd
sleep 2
EDITOR=nano


echo "###########################################################################"
echo "Network packages"
echo "###########################################################################"

pacman -S --needed networkmanager wpa_supplicant netctl
sleep 2
systemctl enable NetworkManager

echo "###########################################################################"
echo "Initramfs"
echo "###########################################################################"

mkinitcpio -P
echo "Patching /etc/mkinitcpio.conf"
sleep 2
echo "Add MODULES=(nvme)"
echo "Add (lvm2) in between block and filesystems"
sleep 2
nano /etc/mkinitcpio.conf
sleep 2
mkinitcpio -p linux

echo "###########################################################################"
echo "# 3.3 Time zone"
echo "###########################################################################"

sleep 2
echo "Setting time zone"
ln -s /usr/share/zoneinfo/$TIMEZONE /etc/localtime
timedatectl set-timezone $TIMEZONE
hwclock --systohc --utc
systemctl enable systemd-timesyncd


echo "###########################################################################"
echo "# Localization"
echo "###########################################################################"

sleep 2
nano /etc/locale.gen
sleep 2
locale-gen
sleep 2
echo "LANG=en_US.UTF-8" >> /etc/locale.conf
sleep 2

echo "###########################################################################"
echo "# 3.5 Network configuration"
echo "###########################################################################"

sleep 2
echo "Setting network configuration"
echo $hostname > /etc/hostname
echo "127.0.0.1 localhost" >> /etc/hosts
echo "::1       localhost" >> /etc/hosts
echo "127.0.1.1 ${hostname}.localdomain ${hostname}" >> /etc/hosts
sleep 2


echo "###########################################################################"
echo "#3.7 Root password"
echo "###########################################################################"
sleep 2
echo "Setting root password"
echo "root:${root_password}" | chpasswd
sleep 2
echo "Adding new user"
useradd -mg users -G wheel,storage,power -s /bin/bash $user_name
sleep 2
echo "Setting user password"
echo "${user_name}:${user_password}" | chpasswd
sleep 2
echo "Install SUDO"
pacman -S --needed sudo
sleep 2
EDITOR=nano visudo

sleep 5

echo "###########################################################################"
echo "#Others - START"
echo "###########################################################################"

echo "Install CPU Microde files"
pacman --noconfirm --needed -Syu amd-ucode

echo "Installing LVM"
pacman --noconfirm --needed -Syu lvm2

echo "Installing Editor"
pacman --noconfirm --needed -Syu nano

echo "Installing file systems"
pacman --noconfirm --needed -Syu btrfs-progs dosfstools exfatprogs e2fsprogs ntfs-3g xfsprogs

echo "###########################################################################"
echo "#Others - END"
echo "###########################################################################"


echo "###########################################################################"
echo "#3.8 Boot loader"
echo "###########################################################################"

sudo pacman -S --needed grub efibootmgr dosfstools mtools os-prober
sleep 2
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB --recheck
sleep 2
grub-mkconfig -o /boot/grub/grub.cfg
sleep 7
cp /usr/share/locale/en\@quot/LC_MESSAGES/grub.mo /boot/grub/locale/en.mo
sleep 2

echo "###########################################################################"
echo "#Creating SWAP"
echo "###########################################################################"

echo "Swap File"
dd if=/dev/zero of=/swapfile bs=1M count=2048 status=progress
chmod 600 /swapfile
mkswap /swapfile
cp /etc/fstab /etc/fstab.bak
echo '/swapfile none swap sw 0 0' | tee -a /etc/fstab

echo "Exit and umount -a reboot"
