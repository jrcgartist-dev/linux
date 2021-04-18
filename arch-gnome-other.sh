#!/bin/env bash

echo "###########################################################################"
echo "#Xorg"
echo "###########################################################################"

pacman -S --needed xorg xorg-server-devel

echo "Enabling multilib repo"
echo "Uncomment multilib"
sleep 2
nano /etc/pacman.conf
sleep 2
pacman -S --needed nvidia nvidia-utils nvidia-settings opencl-nvidia lib32-nvidia-utils
sleep 2
sudo bash -c "echo blacklist nouveau > /etc/modprobe.d/blacklist-nvidia-nouveau.conf"
sleep 2
echo "MODULES=(nvidia nvidia_modeset nvidia_uvm nvidia_drm)"
sleep 2
nano /etc/mkinitcpio.conf
sleep 5
xrandr --listproviders

sleep 5

echo "###########################################################################"
echo "#Gnome"
echo "###########################################################################"

pacman -S --needed gnome gnome-tweaks
systemctl enable gdm

