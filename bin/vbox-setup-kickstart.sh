#!/bin/bash

script_name=${0##*/}                               # Basename, or drop /path/to/file
script=${script_name%%.*}                          # Drop .ext.a.b
script_path=${0%/*}                                # Dirname, or only /path/to
script_path=$( [[ -d ${script_path} ]] && cd ${script_path} ; pwd)             # Absolute path
script_path_name="${script_path}/${script_name}"   # Full path and full filename to $0
readlink=/bin/readlink
[[ $(uname -s) = "Darwin" ]] && readlink=/usr/local/bin/greadlink # brew install coreutils
# https://stackoverflow.com/questions/1055671/how-can-i-get-the-behavior-of-gnus-readlink-f-on-a-mac
# or pwd -P
absolute_script_path_name=$( ${readlink} --canonicalize ${script_path}/${script_name})   # Full absolute path and filename to $0
absolute_script_path=${absolute_script_path_name%/*}                 # Dirname, or only /path/to, now absolute
script_basedir=${script_path%/*}                   # basedir, if script_path is .../bin/

function logg {
   echo "[${script_name}]: $1"
}

tstamp=$( date +'%Y-%m-%d-%H-%M' )

# CONFIG:
pxe_vm=${1:-pxetest$( date +'_%Y-%m-%d-%H-%M' )} # Arg1 or if not default to pxetest
# NOTE: ip of mother-host is 10.0.2.2 /{2..4}
#el7_ks=https://raw.githubusercontent.com/sickbock/el7_kickstart/master/kickstart-el7-netboot-basic-install.cfg
#el7_ks=https://raw.githubusercontent.com/rosshamilton1/cissec/master/centos7-cis.ks
el7_ks=https://raw.githubusercontent.com/janth/vbox-snippets/master/kickstart/centos7-cis.ks
el7_ks=https://raw.githubusercontent.com/janth/vbox-snippets/master/kickstart/centos7-minimal.cfg

# or if starting simple web server with
# python2 -m SimpleHTTPServer 8000
el7_ks=http://10.0.2.2:8000/kickstart/centos7-minimal.cfg
#el7_ks=http://10.0.2.2/kickstart/centos7-minimal.cfg


vbox_base=$( vboxmanage list systemproperties | awk -F: '$1 ~/^Default machine folder/ {print $2}' )
# remove leading whitespace characters
vbox_base="${vbox_base#"${vbox_base%%[![:space:]]*}"}"
# remove trailing whitespace characters
# vbox_base="${vbox_base%"${vbox_base##*[![:space:]]}"}"   

declare -a vbox_dirs=( $HOME/.config/VirtualBox/ $HOME/.VirtualBox/ $HOME/Library/VirtualBox/ )
# Linux: Normally $HOME/VirtualBox
# Mac/OSX/Darwin: $HOME/Library/VirtualBox
# Windows: %USERPROFILE/.VirtualBox ( C:\Users\et2441\.VirtualBox\ )

vbox_dir=
for dir in ${vbox_dirs[*]} ; do
   [[ -r ${dir}/VirtualBox.xml ]] && vbox_dir=${dir}
done

[[ -z ${vbox_dir} ]] && {
   echo "ERROR: Unable to locate VirtualBox directory (the one containing VirtualBox.xml), aborting..."
   echo "(Tried these: ${vbox_dirs[*]})"
   exit 1
}

## # 1) Install VirtualBox, assumed done here...

## # 2) Prepare VBox TFTP:
## NB! Only CentOS 6 and 7 x86_64 (for now...)

# https://gist.github.com/jtyr/816e46c2c5d9345bd6c9

export tftp_dir=${vbox_dir}/TFTP
#export tftp_dir=$HOME/tmp/TEST

# Remove double //
shopt -s extglob
#echo "tftp: ${tftp_dir} -> ${tftp_dir//\/*(\/)//}"
# GNU coreutils realpath/readlink -m 
#realpath -m ${tftp_dir}
#${readlink} -m ${tftp_dir}
tftp_dir=${tftp_dir//\/*(\/)//}

logg "VirtualBox dir is ${vbox_dir}"
logg "TFTP-dir is ${tftp_dir}"
logg "VirtualBox VM base dir is ${vbox_base}"

## # 2.1) Get PXE files from syslinux

   # OSX/Darwin is bsdtar, which doesn't have --transform...
   # tar -xzf - -C ${tftp_dir}/ --transform='s/.*\///' \
   # But bsdtar has -s, which isn't quite the same...

mkdir -p ${tftp_dir}/{pxelinux.cfg,images/centos/{6,7}}
if [[ -r ${tftp_dir}/menu.c32 ]] ; then
   logg "Seems syslinux already in place (${tftp_dir})"
else
   logg "Getting syslinux, extracting to ${tftp_dir}"
   wget --quiet -O - https://www.kernel.org/pub/linux/utils/boot/syslinux/6.xx/syslinux-6.03.tar.gz | \
      tar -xzf - -C ${tftp_dir}/ \
      syslinux-6.03/bios/{core/pxelinux.0,com32/{menu/{menu,vesamenu}.c32,libutil/libutil.c32,elflink/ldlinux/ldlinux.c32,chain/chain.c32,lib/libcom32.c32}}

   ( cd ${tftp_dir} && find syslinux-6.03/ -type f -exec mv -v '{}' . \; && rm -Rf syslinux-6.03 )
fi

# Or you can get these files from already installed system:
# yum install syslinux 
# cp -p /usr/share/syslinux/{pxelinux.0,{menu,vesamenu,chain}.c32} ${tftp_dir}

## # 2.2) Get ramdisk and kernel images
for img_ver in {6..7} ; do
(
   cd ${tftp_dir}/images/centos/${img_ver}/
   logg "Getting CentOS ver ${img_ver} initrd.img and vmlinuz"
   wget --no-clobber --quiet http://mirror.centos.org/centos/${img_ver}/os/x86_64/images/pxeboot/{initrd.img,vmlinuz}
)
done

## # 2.3) Create PXE boot menu

# https://wiki.centos.org/TipsAndTricks/KickStart

logg "Creating PXE boot menu ${tftp_dir}/pxelinux.cfg/default"
cat << E > ${tftp_dir}/pxelinux.cfg/default
# https://wiki.centos.org/HowTos/PXE/PXE_Setup/Menus
# http://www.syslinux.org/wiki/index.php?title=Menu

PROMPT 0
NOESCAPE 0
ALLOWOPTIONS 0
# TIMEOUT 100
ONTIMEOUT local


### TUI
DEFAULT menu.c32

### GUI
#DEFAULT vesamenu.c32
#MENU RESOLUTION 800 600

### GUI
#UI vesamenu.c32
# The splash.png file is a PNG image with resolution of 640x480 px
#MENU BACKGROUND splash.png

MENU TITLE ---===[ Boot Menu ]===---

LABEL local
  MENU DEFAULT
  MENU LABEL ^1. Boot from hard drive
  COM32 chain.c32
  APPEND hd0

LABEL centos6
  MENU LABEL ^2. CentOS 6
  KERNEL images/centos/6/vmlinuz
  APPEND initrd=images/centos/6/initrd.img ks=http://10.0.2.2/kickstart/centos-ks.cfg ip=dhcp ksdevice=eth0 ramdisk_size=10000 ipv6.disable=1 biosdevnames=0 net.ifnames=0 unsupported_hardware text
END

LABEL centos7
  MENU LABEL ^3. CentOS 7
  KERNEL images/centos/7/vmlinuz
  #APPEND initrd=images/centos/6/initrd.img ks=http://10.0.2.2/kickstart/centos-ks.cfg ip=dhcp ksdevice=eth0 ramdisk_size=10000 ipv6.disable=1 biosdevnames=0 net.ifnames=0 unsupported_hardware text
# or, if you can not use a webserver or have not yet created your own Kickstart configuration:
  APPEND initrd=images/centos/7/initrd.img ks=${el7_ks} ramdisk_size=131072 ip=dhcp text ipv6.disable=1 vga=792 vconsole.keymap=no vconsole.font=latarcyrheb-sun16 lang=en_US keymap=no hostname=centos7
END

# Loads pxelinux.cfg/tools
LABEL Tools
  MENU LABEL Tools
  KERNEL menu.c32
  APPEND pxelinux.cfg/tools
END

E

cat << T
PXE boot menu created in ${tftp_dir}/pxelinux.cfg/default

To PXE boot a VBOX called '${pxe_vm}' do this:
cp ${tftp_dir}/pxelinux.0 ${tftp_dir}/${pxe_vm}.pxe
# - or -
ln -s pxelinux.0 ${tftp_dir}/${pxe_vm}.pxe

T

## # 3) Create vbox vm img:
vboxmanage list vms | grep -q "^\"${pxe_vm}\" "
if [[ $? -eq 0 ]] ; then
   logg "VM '${pxe_vm}' already exists, aborting..."
   echo -e "\nMaybe do:\nvboxmanage unregistervm ${pxe_vm} --delete\n"
   exit 1
fi

logg "Creating VirtualBox VM ${pxe_vm}"

# TODO: See also APPEND line in ${tftp_dir}/pxelinux.cfg/default
ram_g=512
ram_g=1024
ram_g=2048
ram_g=1572
vboxmanage createvm --name ${pxe_vm} --ostype RedHat_64 --register
vboxmanage modifyvm ${pxe_vm} --cpus 2 --cpuhotplug on --cpuexecutioncap 40 --paravirtprovider default --memory ${ram_g} --nic1 nat --boot1 net --usb off --audio none
vboxmanage modifyvm ${pxe_vm} --description "Created by ${absolute_script_path_name} run at ${tstamp}\n(C) JTM\r\nfiskebolle"
vboxmanage storagectl ${pxe_vm}  --name SATA --add sata --portcount 1

hdd_name=${vbox_base}/${pxe_vm}/${pxe_vm}_disk0.vdi
vboxmanage list hdds | grep -q ${hdd_name}
if [[ $? -eq 0 ]] ; then
   logg "disk image '${hdd_name}' already exists, aborting..."
   exit 1
fi

disk0_g=20
disk0_g=40
disk0_g=$(( disk0_g * 1024 )) # Convert to MB
vboxmanage createmedium disk  --filename ${hdd_name} --size ${disk0_g} --format VDI  --variant Standard
vboxmanage storageattach ${pxe_vm} --storagectl SATA --port 0 --type hdd --medium ${hdd_name}
#cp -p ${tftp_dir}/pxelinux.0 ${tftp_dir}/${pxe_vm}.pxe
ln -sfv pxelinux.0 ${tftp_dir}/${pxe_vm}.pxe

vboxmanage storagectl ${pxe_vm} --name IDE --add ide
vboxmanage storageattach ${pxe_vm} --storagectl IDE --port 0 --device 0 --type dvddrive --medium "repo/centos/7/isos/x86_64/CentOS-7-x86_64-Minimal-1708.iso"
# vboxmanage modifyvm ${pxe_vm} --boot1 disk

 : << X
vboxmanage list hostonlyifs
Name:            vboxnet0
GUID:            786f6276-656e-4074-8000-0a0027000000
DHCP:            Disabled
IPAddress:       192.168.56.1
NetworkMask:     255.255.255.0
IPV6Address:
IPV6NetworkMaskPrefixLength: 0
HardwareAddress: 0a:00:27:00:00:00
MediumType:      Ethernet
Wireless:        No
Status:          Down
VBoxNetworkName: HostInterfaceNetworking-vboxnet0

vboxmanage hostonlyif create
vboxmanage dhcpserver modify --netname HostInterfaceNetworking-vboxnet0 --ip 192.168.56.2 --netmask 255.255.255.0 --lowerip 192.168.56.50 --upperip 192.168.56.200 --enable

vboxmanage modifyvm puppetest.dev --hostonlyadapter2 vboxnet0
vboxmanage modifyvm puppetest.dev --nic2 hostonly
X
