#!/bin/bash
pxe_vm=pxetest
vbox_base=$( vboxmanage list systemproperties | awk -F: '$1 ~/^Default machine folder/ {print $2}' )
## # 3) Create vbox img:

cat << V
vboxmanage createvm --name ${pxe_vm} --ostype RedHat_64 --register
vboxmanage modifyvm ${pxe_vm} --cpus 2 --cpuhotplug on --cpuexecutioncap 40--paravirtprovider default --memory 512 --nic1 nat --boot1 net --usb off --audio none
vboxmanage storagectl ${pxe_vm}  --name SATA --add sata
vboxmanage createmedium disk  --filename ${vbox_base}/${pxe_vm}/${pxe_vm}_disk0.vdi  --size 20480 --format VDI  --variant Standard
vboxmanage storageattach ${pxe_vm} --storagectl SATA --port 1 --type hdd --medium ${vbox_base}/${pxe_vm}/${pxe_vm}_disk0.vdi

V
exit

declare -a vbox_dirs=( $HOME/.config/VirtualBox $HOME/.VirtualBox/ $HOME/Library/VirtualBox/ )
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

export tftp_dir=${vbox_dir}/TFTP
export tftp_dir=$HOME/tmp/TEST

## # 1) Install VirtualBox, assumed done here...

## # 2) Prepare VBox TFTP:
## NB! Only CentOS 6 and 7 x86_64 (for now...)

# https://gist.github.com/jtyr/816e46c2c5d9345bd6c9

export tftp_dir=${vbox_dir}/TFTP
export tftp_dir=$HOME/tmp/TEST

#mkdir -p ${tftp_dir}/{pxelinux.cfg,images/{centos,}/{6,7}}
mkdir -p ${tftp_dir}/{pxelinux.cfg,images/centos/{6,7}}

## # 2.1) Get PXE files from syslinux

   # OSX/Darwin is bsdtar, which doesn't have --transform...
   # tar -xzf - -C ${tftp_dir}/ --transform='s/.*\///' \
   # But bsdtar has -s, which isn't quite the same...

wget -O - https://www.kernel.org/pub/linux/utils/boot/syslinux/6.xx/syslinux-6.03.tar.gz | \
   tar -xzf - -C ${tftp_dir}/ \
   syslinux-6.03/bios/{core/pxelinux.0,com32/{menu/{menu,vesamenu}.c32,libutil/libutil.c32,elflink/ldlinux/ldlinux.c32,chain/chain.c32,lib/libcom32.c32}}

( cd ${tftp_dir} && find syslinux-6.03/ -type f -exec mv -v '{}' . \; && rm -Rf syslinux-6.03 )

# Or you can get these files from already installed system:
# yum install syslinux 
# cp -p /usr/share/syslinux/{pxelinux.0,{menu,vesamenu,chain}.c32} ${tftp_dir}

## # 2.2) Get ramdisk and kernel images
for img_ver in {6..7} ; do
(
   cd ${tftp_dir}/images/centos/${img_ver}/
   wget http://mirror.centos.org/centos/${img_ver}/os/x86_64/images/pxeboot/{initrd.img,vmlinuz}
)
done

## # 2.3) Create PXE boot menu
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
  APPEND initrd=images/centos/7/initrd.img ks=https://github.com/sickbock/el7_kickstart/raw/master/kickstart-el7-netboot-basic-install.cfg ramdisk_size=131072 ip=dhcp lang=en_US keymap=no hostname=centos7
END

# Loads pxelinux.cfg/tools
LABEL Tools
  MENU LABEL Tools
  KERNEL menu.c32
  APPEND pxelinux.cfg/tools
END

E

pxe_vm=pxetest

cat << T
PXE boot menu created in ${tftp_dir}/pxelinux.cfg/default

To PXE boot a VBOX called '${pxe_vm}' do this:
#cp ${tftp_dir}/pxelinux.0/default ${tftp_dir}/${pxe_vm}.pxe
ln -s pxelinux.0 ${tftp_dir}/${pxe_vm}.pxe

T

