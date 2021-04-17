
#!/bin/env bash

# Country to filter pacman mirrors
COUNTRY=Brazil
# Time zone
TIMEZONE=America/Sao_Paulo
# Where to install Arch
DEVICE=/dev/nvme0n1
# What is the name of the new user?
NEW_USER=kobe24

# Which packages do we want to install in the beginning?
WANTED_PACKAGES=(
    # Command line tools
    bash-completion
    tree
    htop
    atop
    rsync
    lm_sensors # Requirement for mpd py3status module
    imagemagick
    imagemagick-doc
    mediainfo
    ncdu
    wget
    whois
    wol
    xdg-utils
    zip
    # System maintenance
    nvidia
    nvidia-utils
    lib32-nvidia-utils
    nvidia-settings
    smartmontools
    # Audio
    alsa-utils
    alsa-firmware
    pulseaudio
    # Desktop applications
    firefox
    evince
    gimp
    git
    smplayer
    vlc
    zathura
    zathura-pdf-mupdf
    zathura-ps
    # Misc
    aspell-en
    aspell-pt
    macchanger
    # Fonts
    otf-fira-mono
    otf-fira-sans
    otf-font-awesome
    otf-overpass
    ttf-gentium
    ttf-dejavu
    ttf-droid
    ttf-liberation
    ttf-roboto
    ttf-ubuntu-font-family
    ttf-linux-libertine
    noto-fonts
    noto-fonts-emoji
    adobe-source-code-pro-fonts
    adobe-source-sans-pro-fonts
    adobe-source-serif-pro-fonts
    terminus-font
    # Extras
    cpupower
)









echo "Welcome!" && sleep 2

# does full system update
echo "Update the System"
sudo pacman --noconfirm -Syu


echo "###########################################################################"
echo "Partition"
echo "###########################################################################"

echo "NVME0n1"
echo "EFI ef00  SWAP 8200"
cgdisk /dev/nvme0n1

echo "#1.10 Format the partitions"
mkfs.fat -F32 /dev/nvme0n1p1
mkswap /dev/nvme0n1p2
swapon /dev/nvme0n1p2
mkfs.ext4 /dev/nvme0n1p3

echo "###########################################################################"
echo "Mounting the system"
echo "###########################################################################"

mount /dev/nvme0n1p3 /mnt
mkdir -p /mnt/boot/efi
mount /dev/nvme0n1p1 /mnt/boot/efi

sleep 5

echo "Fstab"
mkdir /mnt/etc
genfstab -U /mnt >> /mnt/etc/fstab

sleep 5

echo "###########################################################################"
echo "#2 Installation"
echo "###########################################################################"

echo "#2.1 Select the mirrors"
pacman -S reflector
reflector --verbose --latest 6 --sort rate --save /etc/pacman.d/mirrorlist

echo "Basic package"
pacstrap -i /mnt base

echo "Chroot"
arch-chroot /mnt


echo "#2.2 Install essential packages"
pacman -S --needed base-devel linux linux-firmware linux-headers

echo "Optional packages"
pacman -S --needed nano openssh
systemctl enable sshd
EDITOR=nano

echo "Network packages"
pacman -S --needed networkmanager wpa_supplicant netctl
systemctl enable NetworkManager

echo "# 3.6 Initramfs"
mkinitcpio -P
echo "Patching /etc/mkinitcpio.conf"
echo "Add MODULES=(nvme)"
nano /etc/mkinitcpio.conf
mkinitcpio -p linux

echo "# 3.3 Time zone"
ln -sf /usr/share/zoneinfo/America/Sao_Paulo /etc/localtime
hwclock --systohc


echo "# 3.4 Localization"
nano /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" >> /etc/locale.conf

echo "# 3.5 Network configuration"
echo "jarvis" >> /etc/hostname
echo "127.0.0.1 localhost" >> /etc/hosts
echo "::1       localhost" >> /etc/hosts
echo "127.0.1.1 jarvis.localdomain jarvis" >> /etc/hosts

echo "#3.7 Root password"
passwd
useradd -m -g users -G wheel,storage,power -s /bin/bash kobe24
passwd kobe24

pacman -S --needed sudo
EDITOR=nano visudo


sleep 5

echo "###########################################################################"
echo "#3.8 Boot loader"
echo "###########################################################################"

sudo pacman -S --needed grub efibootmgr dosfstools mtools os-prober
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg
cp /usr/share/locale/en\@quot/LC_MESSAGES/grub.mo /boot/grub/locale/en.mo


exit
umount -a
reboot
