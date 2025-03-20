---

Framework now publishes the appropriate binaries themselves, so there's no need for this anymore.

---

# Framework 11th Gen Intel BIOS 3.19 & CSME 15.0.42 EFI Updater

This script collects the official 3.19 BIOS and 15.0.42 CSME,
as well as an **untrusted** CSME Updater from intel and repackages
the bundle to flash the firmware on non-Windows systems.
You can skip the CSME update if you do not trust those files.

## Usage

Run the packaging script:
```
$ ./Framework_Laptop_11th_Gen_Intel_Core_BIOS_3.19_EFI.sh`
```
It will download and check the files against known signatures,
extract them and package them into the three directories:

1. `usb_root`: Copy these files on a FAT formatted USB drive and boot it (UEFI Method \#1)
2. `esp_root`: Copy these files onto your ESP and flash through the Shell (UEFI Method \#2)
3. `linux_pkg`: Run the CSME Linux updater (Linux Updater Method, no BIOS update!)

## Updating the Firmware

**Warning:**
As mentioned earlier, the updater, by defaults, runs untrusted binaries to update the CSME.
Do so at your own risk.
You can skip running the CSME update by stubbing the `FWUpdLcl.efi` as explained below.

### UEFI Method \#1: USB Drive

1. Move all files from `usb_root` on a FAT formatted USB drive and boot it.
2. The installer should start automatically and update both the BIOS to 3.19 and the CSME.

**Optionally skip CSME update:**
If you do not trust the CSME Updater `FWUpdLcl.efi` contained in here,
just overwrite it with any other binary such as the BIOS Updater `H2OFFT-Sx64.efi`.
This will allow the BIOS Update to continue but the CSME Update will be skipped
(the updater only checks for existence of the file).

**Without USB Drive:** If you do not have USB drive with you,
you can use the EFI System Partition and EFI Shell as shown in the next method.

### UEFI Method \#2: ESP

1. Place the files from `efi_root` onto your EFI System Partition (ESP)
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
6. In GRUB, select "UEFI Shell", and first change to the File System 0 volume `FS0` (the ESP),
   then run the H2O Flash Tool:
   ```
   Shell> FS0:
   FS0:\> .\H2OFFT-Sx64.efi .\isflash.bin
   ```
   This will start the update process.

**Optionally skip CSME update:**
As above, you can skip the CSME update by replacing the `FWUpdLc.efi`.

### Linux Method (CSME Update Only)

The CSME System Tools also contain a `FWUpdLcl` file for Linux which can be run from a running system
and can be found in the `linux_pkg` directory. Run the `flash.sh` script:

```$ sudo ./flash.sh
Intel (R) FW Update Version: 15.0.35.1951
Copyright (C) 2005 - 2021, Intel Corporation. All rights reserved.

Checking firmware parameters...

Warning: Do not exit the process or power off the machine before the firmware update process ends.
Sending the update image to FW for verification:  [ COMPLETE ]



FW Update:  [ 100% (/)] Do not Interrupt
```

**Note:**
This won't update the BIOS to 3.19 since this would require a Linux H2O BIOS (H2OFFT-Lx64) updater.
While this exists from 3rd party sites, it's not included here:
https://www.udoo.org/docs-x86/Advanced_Topics/UEFI_update.html
For the updater to work, additionally a kernel driver is required:
https://github.com/tomreyn/isfl
