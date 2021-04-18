#!/bin/env bash

echo "###########################################################################"
echo "Install essential packages"
echo "###########################################################################"

pacman -S --needed base-devel linux linux-firmware linux-headers

sleep 2

echo "###########################################################################"
echo "Optional packages"
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
sleep 2
nano /etc/mkinitcpio.conf
sleep 2
mkinitcpio -p linux

echo "###########################################################################"
echo "# 3.3 Time zone"
echo "###########################################################################"

sleep 2
ln -sf /usr/share/zoneinfo/America/Sao_Paulo /etc/localtime
sleep 2
hwclock --systohc
sleep 2
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
echo "jarvis" >> /etc/hostname
sleep 2
echo "127.0.0.1 localhost" >> /etc/hosts
sleep 2
echo "::1       localhost" >> /etc/hosts
sleep 2
echo "127.0.1.1 jarvis.localdomain jarvis" >> /etc/hosts
sleep 2


echo "###########################################################################"
echo "#3.7 Root password"
echo "###########################################################################"

echo "Root Password"
sleep 2
passwd
sleep 2
echo "Create user"
sleep 2
useradd -m -g users -G wheel,storage,power kobe24
sleep 2
echo "User password"
sleep 2
passwd kobe24
sleep 2

echo "Install SUDO"
pacman -S --needed sudo
sleep 2
EDITOR=nano visudo

sleep 5

echo "###########################################################################"
echo "#3.8 Boot loader"
echo "###########################################################################"

sudo pacman -S --needed grub efibootmgr dosfstools mtools os-prober amd-ucode
sleep 2
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB
sleep 2
grub-mkconfig -o /boot/grub/grub.cfg
sleep 7
cp /usr/share/locale/en\@quot/LC_MESSAGES/grub.mo /boot/grub/locale/en.mo
sleep 2


echo "Exit and umount -a reboot"
