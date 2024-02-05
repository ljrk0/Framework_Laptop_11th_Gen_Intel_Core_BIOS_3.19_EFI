# Framework 11th Gen Intel BIOS 3.19 & CSME 15.0.42 EFI Updater

This script collects the official 3.19 BIOS and 15.0.42 CSME,
as well as an **untrusted** CSME Updater from intel and repackages
the bundle to flash the firmware on non-Windows systems.

## Usage

Run the packaging script:
```
$ ./Framework_Laptop_11th_Gen_Intel_Core_BIOS_3.19_EFI.sh`
```
It will download and check the files against known signatures,
extract them and package them into the directory `efi_root`.

## Updating the Firmware

### UEFI Shell Method

Move all files from `efi_root` on a FAT formatted USB drive and boot it.
The installer should start automatically and update both the BIOS to 3.19 and the CSME.

If you do not trust the CSME Updater `FWUpdLcl.efi` contained in here,
just overwrite it with any other binary such as the BIOS Updater `H2OFFT-Sx64.efi`.
This will allow the BIOS Update to continue but the CSME Update will be skipped
(the updater only checks for existence of the file).

**Without USB Drive:**  
If you do not have USB drive with you, you can use the EFI System Partition and EFI Shell.

1. Place the files onto your EFI System Partition (ESP)
2. Download and extract an EFI Shell, e.g., from the ArchLinux repos:
   https://archlinux.org/packages/extra/any/edk2-shell/download/
3. Copy the Shell binary to the ESP as well, next to the others:
   ```
   cp usr/share/edk2-shell/x64/Shell_Full.efi /path/to/the/ESP
   ```
4. Add a GRUB2 menu entry for the UEFI Shell, `/etc/grub.d/40_custom` should
   look like this:
   ```
   #!/usr/bin/sh
   exec tail -n +3 $0
   # This file provides an easy way to add custom menu entries.  Simply type the
   # menu entries you want to add after this comment.  Be careful not to change
   # the 'exec tail' line above.
   menuentry "UEFI Shell" {
           insmod part_gpt
           insmod chain
           set root='(hd0,gpt1)'
           chainloader /shellx64.efi
   }
   ```
5. Run `grub2-mkconfig -o /etc/grub2-efi.cfg` and reboot
6. In GRUB, select "UEFI Shell", and use the following commands:
   ```
   Shell> FS0:
   FS0:\> .\shellx64.efi .\isflash.bin
   ```
   This will start the update process.

### Linux Method (CSME Update Only)

The CSME System Tools also contain a `FWUpdLcl` file for Linux which can be run just like that:

```
$ sudo "CSME System Tools v15.0 r15/FWUpdate/LINUX64/FWUpdLcl" -F fw11_3_19_win/FWUpdate.bin
Intel (R) FW Update Version: 15.0.35.1951
Copyright (C) 2005 - 2021, Intel Corporation. All rights reserved.

Checking firmware parameters...

Warning: Do not exit the process or power off the machine before the firmware update process ends.
Sending the update image to FW for verification:  [ COMPLETE ]



FW Update:  [ 100% (/)] Do not Interrupt
```

This won't update the BIOS to 3.19 since this requires a kernel driver such as:
https://github.com/tomreyn/isfl
as well as the H2OFFT-Lx64 binary such as:
https://www.udoo.org/docs-x86/Advanced_Topics/UEFI_update.html
