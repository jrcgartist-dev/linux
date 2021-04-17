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
    qbittorrent
)

echo "Part 2!" && sleep 2

su
cd /root

echo "AMD UCODE"
pacman -S --needed amd-ucode

echo "AMD UCODE"
pacman -S --needed xorg-server xorg-server-devel

echo "Enabling multilib repo"
echo "Uncomment multilib"
nano /etc/pacman.conf

pacman -S --needed nvidia nvidia-settings nvidia-utils lib32-nvidia-utils
sudo bash -c "echo blacklist nouveau > /etc/modprobe.d/blacklist-nvidia-nouveau.conf"
echo "MODULES=(nvidia)"
nano /etc/mkinitcpio.conf

sleep 5

echo "###########################################################################"
echo "#Gnome"
echo "###########################################################################"

pacman -S --needed gnome gnome-tweaks
systemctl enable gdm

