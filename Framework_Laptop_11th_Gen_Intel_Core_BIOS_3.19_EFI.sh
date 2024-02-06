#! /bin/sh

dlurl='https://downloads.frame.work/bios'
# This is the 3.17 EFI update containing:
#  * H2OFFT-Sx64.efi: The H2O Firmware Flash Tool for the UEFI Shell x64
#  * hx20_capsule_3.17.bin: The H2O 3.17 BIOS Update
#  * startup.nsh: An autostart script to launch the FFT
#  * efi/: EFI boot files
fw11_3_17_efi='Framework_Laptop_11th_gen_Intel_Core_BIOS_3.17_EFI.zip'
# This is the 3.19 Windows update containing:
#  * H2OFFT-W.exe: The H2O Firmware Flash Tool for Windows
#  * H2OFFT(64).cat,.inf,.sys: The H2O FFT Windows Driver
#  * isflash.bin: The H2O 3.19 BIOS Update
#  * platform.ini: A configuration file for the FFT
#  * FWUpdLcl.exe: The intel CSME Windows Updater
#  * FWUpdate.bin: The intel 15.0.42.2235 CSME Update
#  * misc. files for the installer etc.
fw11_3_19_win='Framework_Laptop_11th_Gen_Intel_Core_BIOS_3.19.exe'
# intel CSME System Tools v15.0.r15
# WARNING: UNTRUSTED SOURCE!
CSME_ST_15_0_r15='CSME System Tools v15.0 r15.rar' 
CSME_ST_15_0_r15_url='https://mega.nz/folder/qdVAyDSB#FLCPaDVIsPYiy2TAUjD7RQ/file/2FUgmLDa'
download() {
	printf '[+] Downloading 3.17 and 3.19 Updates\n' >&2
	test -f "$fw11_3_17_efi" || curl -# -o "$fw11_3_17_efi" "$dlurl/$fw11_3_17_efi"
	test -f "$fw11_3_19_win" || curl -# -o "$fw11_3_19_win" "$dlurl/$fw11_3_19_win"

	if [ ! -f "$CSME_ST_15_0_r15" ]; then
		printf '[+] Download "CSME System Tools v15.0 r15.rar" on your own risk!\n' >&2
		printf '[+] Visit: %s\n' "$CSME_ST_15_0_r15_url" >&2
		printf '[+] ... and press any key to continue' >&2
		read
	fi
}

check() {
	printf '[+] Checking files...\n' >&2
	if ! sha256sum -c 'sha256sum.txt'; then
		printf '[+] Error downloading, please remove files and try again\n' >&2
		exit 1
	fi
}

extract() {
	printf '[+] Extracting Updates and CSME ST\n' >&2
	7za x -aoa -ofw11_3_17_efi "$fw11_3_17_efi"
	7za x -aoa -ofw11_3_19_win "$fw11_3_19_win"
	chmod +w 'fw11_3_19_win/isflash.bin'
	unrar x -o+ "$CSME_ST_15_0_r15"
}

usb_root="usb_root"
esp_root="esp_root"
linux_pkg="linux_pkg"
package() {
	printf '\n' >&2
	printf '[+] 1. Placing the USB EFI updater files into "%s"\n' "$usb_root" >&2
	printf '[+] 2. Placing the ESP updater files into "%s"\n' "$esp_root" >&2
	printf '[+] 3. Placing the Linux updater files into "%s"\n' "$linux_pkg" >&2
	mkdir -p "$usb_root" "$esp_root" "$linux_pkg"

	printf '[+] Pulling the 15.0.42.2235 CSME update\n' >&2
	for dest in "$usb_root" "$esp_root" "$linux_pkg"; do
		cp "fw11_3_19_win/FWUpdate.bin" "$dest"
	done
	printf '[+] Pulling the 3.19 BIOS update\n' >&2
	for dest in "$usb_root" "$esp_root"; do
		cp "fw11_3_19_win/isflash.bin" "$dest"
	done

	printf '[+] Pulling the UEFI FFT from 3.17\n' >&2
	for dest in "$usb_root" "$esp_root"; do
		cp "fw11_3_17_efi/H2OFFT-Sx64.efi" "$dest"
	done

	printf '[+] Pulling the /efi files from 3.17\n' >&2
	cp -r "fw11_3_17_efi/efi/" "$usb_root"

	# The flash binary contains another copy of the platform.inf and
	# also instructs the FFT to run the FWUpdLcl tool to update the CSME.
	# *This is the tool that we're missing for updating the CSME*
	printf '[+] Pulling the FWUpdLcl.efi from CSME ST\n' >&2
	cp "CSME System Tools v15.0 r15/FWUpdate/EFI64/FWUpdLcl.efi" "$usb_root"

	printf '[+] Pulling the FWUpdLcl Linux binary from CSME ST\n' >&2
	cp "CSME System Tools v15.0 r15/FWUpdate/LINUX64/FWUpdLcl" "$linux_pkg"
	chmod +x "$linux_pkg/FWUpdLcl"

	printf '[+] Creating startup files/flash scripts\n' >&2
	printf 'H2OFFT-Sx64.efi isflash.bin' > "$usb_root/startup.nsh"
	printf \
'FS0:
H2OFFT-Sx64.efi isflash.bin\n' > "$esp_root/startup.nsh"
	printf \
'#! /bin/sh
./FWUpdLcl -F FWUpdate.bin\n'> "$linux_pkg/flash.sh"
	chmod +x "$linux_pkg/flash.sh"
}

release() {
	for dir in "$esp_root" "$usb_root" "$linux_pkg"; do
		zip -r "$dir.zip" "$dir"
	done
}


download
check
extract
package
release

printf '\n' >&2
printf \
'Done. CAUTION: All methods use FWUpdLcl.efi or FWUpdLcl (Linux) you downloaded
yourself before. These tools are developed by intel and are required for flashing
the CSME. Unfortunately they are not publicly available. If you do not trust the
distributed binaries, please refrain from flashing the CSME. This can be achieved
by simply replacing the `FWUpdLcl.efi` file with the `H2OFFT-Sx64.efi` file, as
the BIOS/UEFI flash tool simply checks for the presence of `FWUpdLcl.efi`. The
invalid file will allow the BIOS/UEFI update to continue to update to 3.19 while
skipping the CSME update.\n' >&2
