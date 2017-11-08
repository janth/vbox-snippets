#!/bin/bash

vbox_basedir=$HOME/VirtualBox
vbox_tftpdir=$HOME/.VirtualBox/TFTP  # Same directory which has the file VirtualBox.xml: https://www.virtualbox.org/manual/UserManual.html#nat-tftp


# Setup for PXE:
 : << X
# Same directory which has the file VirtualBox.xml: https://www.virtualbox.org/manual/UserManual.html#nat-tftp
vbox_tftpdir=$HOME/.VirtualBox/TFTP
mkdir -p ${vbox_tftpdir}/{pxelinux.cfg,images/centos/{6,7}}
cd ${vbox_tftpdir}/

# Get syslinux 6.03 (latest from 2014) PXE boot
wget -O - https://www.kernel.org/pub/linux/utils/boot/syslinux/6.xx/syslinux-6.03.tar.gz | tar -xzf - -C ${vbox_tftpdir}/ --transform='s/.*\///' syslinux-6.03/bios/{core/pxelinux.0,com32/{menu/{menu,vesamenu}.c32,libutil/libutil.c32,elflink/ldlinux/ldlinux.c32,chain/chain.c32,lib/libcom32.c32}}

cd images/centos/7/
wget http://mirror.centos.org/centos/7/os/x86_64/images/pxeboot/{initrd.img,vmlinuz}
cd ../6
wget http://mirror.centos.org/centos/6/os/x86_64/images/pxeboot/{initrd.img,vmlinuz}

cd ../../pxelinux.cfg
vim ${vbox_tftpdir}/pxelinux.cfg/default


X


 : << Z
Kickstart:
https://www.centos.org/docs/5/html/Installation_Guide-en-US/s1-kickstart2-startinginstall.html

https://gist.github.com/ereli/e868fcaeb660e420d7a6

mkfs.msdos -C myfloppy.img 1440
sudo mount -o loop myfloppy.img /media/floppy/
sudo cp kickstart.sys /media/floppy/
sudo umount /media/floppy

ks=floppy:/<path>
ks=hd:fd0:/ks.cfg
ks=cdrom:/ks.cfg

Z

# About nat tuning: https://www.virtualbox.org/manual/UserManual.html#changenat
# For network booting in NAT mode, by default VirtualBox uses a built-in TFTP
# server at the IP address 10.0.2.4. This default behavior should work fine for
# typical remote-booting scenarios. However, it is possible to change the boot
# server IP and the location of the boot image with the following commands:

# VBoxManage modifyvm "VM name" --nattftpserver1 10.0.2.2
# VBoxManage modifyvm "VM name" --nattftpfile1 /srv/tftp/boot/MyPXEBoot.pxe

# -biospxedebug on|off:
# This option enables additional debugging output when using the Intel PXE boot
# ROM. The output will be written to the release log file (Section 12.1.2,
# “Collecting debugging information”.

# -nicbootprio<1-N> <priority>:
# This specifies the order in which NICs are tried for booting over the network
# (using PXE). The priority is an integer in the 0 to 4 range. Priority 1 is
# the highest, priority 4 is low. Priority 0, which is the default unless
# otherwise specified, is the lowest.

# Note that this option only has effect when the Intel PXE boot ROM is used.




cd ${vbox_basedir}

MyVM=testvm

vboxmanage unregistervm ${MyVM} --delete
[[ -d ${MyVM} ]] && rm -rf ${MyVM}
[[ -r ${vbox_tftpdir}/${MyVM} ]] && rm ${vbox_tftpdir}/${MyVM}
ln -s pxelinux.0 ${vbox_tftpdir}/${MyVM}

mkdir ${MyVM}
cd ${MyVM}
hd0=${vbox_basedir}/${MyVM}/${MyVM}_disk0.vdi
vboxmanage createhd --filename ${hd0} --size 1024 # MB
vboxmanage createvm --name ${MyVM} --ostype RedHat_64 --register
vboxmanage modifyvm ${MyVM} \
   --memory 512 \
   --vram=9 \
   --acpi on \
   --ioapic     on          \
   --pae        on          \
   --cpuexecutioncap 40     \
   --nestedpaging on        \
   --largepages   off       \
   --vtxvpid      off        \
   --cpus         2         \
   --rtcuseutc    off       \
   --monitorcount       1   \
   --accelerate3d       off \
   --accelerate2dvideo  off \
   --firmware bios          \
   --chipset  piix3         \
   --mouse    ps2           \
   --keyboard ps2           \
   --uart1    off           \
   --uart2    off           \
   --audio    none          \
   --usb      off           \
   --usbehci  off           \
   --vrde     off           \
   --teleporter off         \
   --nic1 NAT \
   --cableconnected2  off        \
   --nic2 hostonly \
   --hostonlyadapter2 vboxnet0 \
   --nictype2 virtio \
   --nattftpfile1 /pxelinux.0


   # optional second NIC \
   # --nic2 bridged \
   # --bridgeadapter2 enp0s25 

vboxmanage modifyvm ${MyVM} --nictype1 virtio 
# optional second NIC 
# vboxmanage modifyvm ${MyVM} --nictype2 virtio

# to do PXE boot
vboxmanage modifyvm ${MyVM} --boot1 net --boot2 disk --boot3 none --boot4 none 
# or for normal boot:
# vboxmanage modifyvm ${MyVM} --boot1 disk --boot2 net --boot3 dvd --boot4 none

vboxmanage storagectl ${MyVM} --name "SATA Controller" --add sata --controller IntelAHCI 
vboxmanage storageattach ${MyVM} --storagectl "SATA Controller" --port 0 --device 0 --type hdd --medium ${hd0}


## VBoxManage modifyvm          \
##     $machine_name            \
##     --memory 1024            \
##     --vram       5           \
##     --acpi       off         \
##     --ioapic     on          \
##     --pae        off         \
##     --nestedpaging on        \
##     --largepages   off       \
##     --vtxvpid      on        \
##     --cpus         2         \
##     --rtcuseutc    on        \
##     --monitorcount       1   \
##     --accelerate3d       off \
##     --accelerate2dvideo  off \
##     --firmware bios          \
##     --chipset  piix3         \
##     --boot1    dvd           \
##     --boot2    disk          \
##     --boot3    none          \
##     --boot4    none          \
##     --mouse    ps2           \
##     --keyboard ps2           \
##     --uart1    off           \
##     --uart2    off           \
##     --audio    none          \
##     --usb      off           \
##     --usbehci  off           \
##     --vrde     off           \
##     --teleporter off         \
##     # --nictype1         Am79C970A \
##     # --nic2             hostonly  \
##     # --hostonlyadapter2 vboxnet0  \
##     # --nictype2         82540EM   \
##     # --cableconnected2  on        \
## 
