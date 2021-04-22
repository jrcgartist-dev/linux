!/bin/bash

bootstrapper_dialog() {
    DIALOG_RESULT=$(dialog --clear --stdout --backtitle "Arch bootstrapper" --no-shadow "$@" 2>/dev/null)
}

#################
#### Welcome ####
#################
bootstrapper_dialog --title "Welcome" --msgbox "Welcome to Kenny's Arch Linux bootstrapper.\n" 6 60

##############################
#### UEFI / BIOS detection ###
##############################
efivar -l >/dev/null 2>&1

if [[ $? -eq 0 ]]; then
    UEFI_BIOS_text="UEFI detected."
    UEFI_radio="on"
    BIOS_radio="off"
else
    UEFI_BIOS_text="BIOS detected."
    UEFI_radio="off"
    BIOS_radio="on"
fi

bootstrapper_dialog --title "UEFI or BIOS" --radiolist "${UEFI_BIOS_text}\nPress <Enter> to accept." 10 30 2 1 UEFI "$UEFI_radio" 2 BIOS "$BIOS_radio"
[[ $DIALOG_RESULT -eq 1 ]] && UEFI=1 || UEFI=0

#################
#### Prompts ####
#################
bootstrapper_dialog --title "Hostname" --inputbox "Please enter a name for this host.\n" 8 60
hostname="$DIALOG_RESULT"

##########################
#### Password prompts ####
##########################
bootstrapper_dialog --title "Disk encryption" --passwordbox "Please enter a strong passphrase for the full disk encryption.\n" 8 60
encryption_passphrase="$DIALOG_RESULT"

bootstrapper_dialog --title "Root password" --passwordbox "Please enter a strong password for the root user.\n" 8 60
root_password="$DIALOG_RESULT"

#################
#### Warning ####
#################
bootstrapper_dialog --title "WARNING" --msgbox "This script will NUKE /dev/sda from orbit.\nPress <Enter> to continue or <Esc> to cancel.\n" 6 60
[[ $? -ne 0 ]] && (bootstrapper_dialog --title "Cancelled" --msgbox "Script was cancelled at your request." 5 40; exit 0)

##########################
#### reset the screen ####
##########################
reset
