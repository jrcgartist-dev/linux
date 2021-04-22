#!/bin/bash

DISK=/dev/nvme0n1
TIMEZONE=America/Sao_Paulo
LANGUAGE=en_US.UTF-8
GRUBDIR=/mnt/boot/EFI


bootstrapper_dialog() {
    DIALOG_RESULT=$(dialog --clear --stdout --backtitle "Arch bootstrapper" --no-shadow "$@" 2>/dev/null)
}

#################
#### Welcome ####
#################
bootstrapper_dialog --title "Welcome" --msgbox "Welcome to Arch Linux bootstrapper.\n" 6 60

##############################
#### UEFI / BIOS detection ###
##############################

partition_var=0

if [[ $partition_var -eq 0 ]]; then
    LMV_radio="on"
    EXT4_radio="off"
else
    LMV_radio="off"
    EXT4_radio="on"
fi

bootstrapper_dialog --title "LMV or EXT4" --radiolist "\nPress <Enter> to accept." 10 30 2 1 LMV "$LMV_radio" 2 EXT4 "$EXT4_radio"
[[ $DIALOG_RESULT -eq 1 ]] && LMV=1 || LMV=0

#################
#### Prompts ####
#################
bootstrapper_dialog --title "Hostname" --inputbox "Please enter a name for this host.\n" 8 60
hostname="$DIALOG_RESULT"

#################
#### User name ####
#################
bootstrapper_dialog --title "User name" --inputbox "Please enter a name for the USER.\n" 8 60
user_name="$DIALOG_RESULT"

##########################
#### Password prompts ####
##########################
bootstrapper_dialog --title "Root password" --passwordbox "Please enter a strong password for the root user.\n" 8 60
root_password="$DIALOG_RESULT"

bootstrapper_dialog --title "User password" --passwordbox "Please enter a strong password for the user.\n" 8 60
user_password="$DIALOG_RESULT"

#################
#### Warning ####
#################
bootstrapper_dialog --title "WARNING" --msgbox "This script will NUKE /dev/nvme0n1 from orbit.\nPress <Enter> to continue or <Esc> to cancel.\n" 6 60
[[ $? -ne 0 ]] && (bootstrapper_dialog --title "Cancelled" --msgbox "Script was cancelled at your request." 5 40; exit 0)

##########################
#### reset the screen ####
##########################
reset


#########################################
#### Nuke and set up disk partitions ####
#########################################
echo "Zapping disk"
sgdisk --zap-all $DISK

echo "Creating EFI Partition"
if [[ $LMV -eq 1 ]]; then
    printf "n\n1\n\n+512M\nef00\nw\ny\n" | gdisk $DISK
    yes | mkfs.fat -F32 "${DISK}p1"
else
    printf "n\n1\n\n+512M\nef00\nw\ny\n" | gdisk $DISK
   yes | mkfs.fat -F32 "${DISK}p1"
fi

echo "Creating Main Partition"
if [[ $LMV -eq 1 ]]; then
    printf "n\n2\n\n\n8e00\nw\ny\n"| gdisk /dev/sda
else
    printf "n\n2\n\n\n8300\nw\ny\n"| gdisk /dev/sda
   yes | mkfs.fat -F32 "${DISK}p2"
fi

echo "Setting up LVM"
pvcreate --dataalignment 1m "${DISK}p2"
vgcreate vg00 "${DISK}p2"
lvcreate -L 30G vg00 -n lv_root
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
mount "${DISK}p1" $GRUBDIR
mount /dev/vg00/lv_home /mnt/home

yes '' | pacstrap -i /mnt base base-devel

genfstab -U -p /mnt >> /mnt/etc/fstab

###############################
#### Configure base system ####
###############################
arch-chroot /mnt /bin/bash <<EOF

echo "Setting and generating locale"
echo "en_US.UTF-8 UTF-8" > /etc/locale.gen
locale-gen

export LANG=$LANGUAGE
echo "LANG=${LANGUAGE}" >> /etc/locale.conf

echo "Setting time zone"
ln -s /usr/share/zoneinfo/$TIMEZONE /etc/localtime
timedatectl set-timezone $TIMEZONE
hwclock --systohc

echo "Installing network packages"
pacman --noconfirm --needed -S networkmanager wpa_supplicant wireless_tools netctl dialog

echo "Setting network configuration"
echo $hostname > /etc/hostname
echo "127.0.0.1 localhost" >> /etc/hosts
echo "::1       localhost" >> /etc/hosts
echo "127.0.1.1 ${hostname}.localdomain ${hostname}" >> /etc/hosts

echo "Installing main packages"
pacman --noconfirm --needed -S linux linux-firmware linux-headers

echo "Initramfs"
mkinitcpio -P

echo "Install CPU Microde files"
pacman --noconfirm --needed -S amd-ucode

echo "Installing LVM"
pacman --noconfirm --needed -S lvm2

echo "Installing Editor"
pacman --noconfirm --needed -S nano

echo "Installing file systems"
pacman --noconfirm --needed -S btrfs-progs dosfstools exfatprogs e2fsprogs ntfs-3g xfsprogs

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
pacman --noconfirm --needed -S grub efibootmgr dosfstools os-prober mtools
grub-install --target=x86_64-efi --efi-directory=$GRUBDIR --bootloader-id=GRUB

#sed -i 's|^GRUB_CMDLINE_LINUX_DEFAULT.*|GRUB_CMDLINE_LINUX_DEFAULT="nouveau.modeset=0"|' /etc/default/grub
grub-mkconfig -o /boot/grub/grub.cfg
cp /usr/share/locale/en\@quot/LC_MESSAGES/grub.mo /boot/grub/locale/en.mo

echo "Windows Management"
pacman -S --needed xorg-server xorg-xinit

echo "Nvidia Driver"
pacman -S --needed nvidia nvidia-utils nvidia-settings opencl-nvidia
bash -c "echo blacklist nouveau > /etc/modprobe.d/blacklist-nvidia-nouveau.conf"

echo "Gnome"
pacman -S --needed gnome gnome-tweaks
systemctl enable gdm

echo "Enabling systemctls"
systemctl enable NetworkManager
systemctl enable systemd-timesyncd

EOF

printf "\e[1;32mDone! Type exit, umount -a and reboot.\e[0m"








