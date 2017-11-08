#!/bin/bash


declare -a vbox_dirs=( $HOME/.config/VirtualBox $HOME/.VirtualBox/ $HOME/Library/VirtualBox/ )
# Linux: Normally $HOME/VirtualBox
# Mac/OSX/Darwin: $HMOE/Library/VirtualBox

vbox_dir=
for dir in ${vbox_dirs[*]} ; do
   [[ -r ${dir}/VirtualBox.xml ]] && vbox_dir=${dir}
done

[[ -z ${vbox_dir} ]] && {
   echo "ERROR: Unable to locate VirtualBox directory (the one containing VirtualBox.xml), aborting..."
   echo "(Tried these: ${vbox_dirs[*]})"
   exit 1
}

cat << X
# https://gist.github.com/jtyr/816e46c2c5d9345bd6c9

mkdir -p ${vbox_dir}/TFTP/{pxelinux.cfg,images/{centos}/{6,7}}

X
