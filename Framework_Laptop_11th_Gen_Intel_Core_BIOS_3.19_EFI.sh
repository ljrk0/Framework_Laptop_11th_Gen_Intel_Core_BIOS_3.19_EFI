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

efi_root="efi_root"
package() {
	printf '[+] Placing the EFI updater into root directory "%s"\n' "$efi_root" >&2
	mkdir -p "$efi_root"

	printf '[+] Pulling the 3.19 BIOS update and 15.0.42.2235 CSME\n' >&2
	cp "fw11_3_19_win/isflash.bin" "$efi_root"
	cp "fw11_3_19_win/FWUpdate.bin" "$efi_root"

	printf '[+] Pulling the UEFI FFT and efi/ files from 3.17\n' >&2
	cp "fw11_3_17_efi/H2OFFT-Sx64.efi" "$efi_root"
	cp -r "fw11_3_17_efi/efi/" "$efi_root"

	printf '[+] Creating startup file\n' >&2
	echo 'H2OFFT-Sx64.efi isflash.bin' > "$efi_root/startup.nsh"

	# The flash binary contains another copy of the platform.inf and
	# also instructs the FFT to run the FWUpdLcl tool to update the CSME.
	# *This is the tool that we're missing for updating the CSME*
	printf '[+] Pulling the FWUpdLcl.efi from CSME ST\n' >&2
	cp "CSME System Tools v15.0 r15/FWUpdate/EFI64/FWUpdLcl.efi" "$efi_root"

	printf \
'[+] Note: The CSME SET also contains a Linux ELF updater
[+] which can be used to update the CSME within a running Linux:
[+] 
[+]     "%s/FWUpdate/LINUX64/FWUpdLcl" -F %s/FWUpdate.bin
[+] 
[+] The BIOS/UEFI 3.19 Update still requires H2O FFT though which will
[+] not run without at least a fake FWUpdLcl.efi file.
' "CSME System Tools v15.0 r15" "fw11_3_19_win"
}


download
check
extract
package
