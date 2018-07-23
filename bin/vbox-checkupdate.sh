#!/bin/bash

# script_name=${0##*/}                               # Basename, or drop /path/to/file
## script=${script_name%%.*}                          # Drop .ext.a.b
## script_path=${0%/*}                                # Dirname, or only /path/to
## script_path=$( [[ -d ${script_path} ]] && cd ${script_path} ; pwd)             # Absolute path
## script_path_name="${script_path}/${script_name}"   # Full path and full filename to $0
## absolute_script_path_name=$( /bin/readlink --canonicalize ${script_path}/${script_name})   # Full absolute path and filename to $0
## absolute_script_path=${absolute_script_path_name%/*}                 # Dirname, or only /path/to, now absolute
## script_basedir=${script_path%/*}                   # basedir, if script_path is .../bin/

current_ver=$( vboxmanage -version )
# 5.2.14r123301
current_ver=${current_ver%%r*}

latest_ver=$( curl -q -s  https://www.virtualbox.org/wiki/Downloads | grep -o 'VirtualBox</a> .* platform packages' | awk '{print $2}' )
latest_ver=$( curl -q -s  http://download.virtualbox.org/virtualbox/LATEST.TXT )

#LatestVirtualBoxVersion=$(wget -qO - http://download.virtualbox.org/virtualbox/LATEST.TXT) 
#wget "http://download.virtualbox.org/virtualbox/${LatestVirtualBoxVersion}/Oracle_VM_VirtualBox_Extension_Pack-${LatestVirtualBoxVersion}.vbox-extpack"
#https://www.virtualbox.org/download/hashes/${LatestVirtualBoxVersion}/SHA256SUMS
#VBoxManage extpack install --replace Oracle_VM_VirtualBox_Extension_Pack-${LatestVirtualBoxVersion}.vbox-extpack

extension_ver=$( vboxmanage list extpacks | awk '$1 ~ /Version:/ {print $2}' )

echo "Current ver: ${current_ver}, latest: ${latest_ver}, extension: ${extension_ver}"

if [[ ${extension_ver} != ${current_ver} ]] ; then
   cat << X

wget "http://download.virtualbox.org/virtualbox/${current_ver}/Oracle_VM_VirtualBox_Extension_Pack-${current_ver}.vbox-extpack"
#https://www.virtualbox.org/download/hashes/${current_ver}/SHA256SUMS
sudo vboxmanage extpack install --replace Oracle_VM_VirtualBox_Extension_Pack-${current_ver}.vbox-extpack

X
fi

