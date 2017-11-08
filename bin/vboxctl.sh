#!/bin/bash

script_name=${0##*/}                               # Basename, or drop /path/to/file
script=${script_name%%.*}                          # Drop .ext.a.b
script_path=${0%/*}                                # Dirname, or only /path/to
script_path=$( [[ -d ${script_path} ]] && cd ${script_path} ; pwd)             # Absolute path
script_path_name="${script_path}/${script_name}"   # Full path and full filename to $0
absolute_script_path_name=$( /bin/readlink --canonicalize ${script_path}/${script_name})   # Full absolute path and filename to $0
absolute_script_path=${absolute_script_path_name%/*}                 # Dirname, or only /path/to, now absolute
script_basedir=${script_path%/*}                   # basedir, if script_path is .../bin/


# echo "lower case: ${var1,,}"
# echo "upper case: ${var1^^}"
shopt -s nocasematch

if [[ $1 == '' ]] ; then
   vm=${script}
   case ${vm} in
      #win|evry|pc32213) vm=PC32213;;
      win|evry|pc33455b) vm=PC33455b;;
   esac
   vboxmanage list runningvms | grep -q "${vm}"
   if [[ $? -eq 0 ]] ; then
      echo "VM '${vm}' is already running"
      exit
   fi
   vboxmanage list vms | grep -q "${vm}"
   if [[ $? -eq 1 ]] ; then
      echo "VM '${vm}' not defined"
      exit
   fi
   vboxmanage startvm "${vm}"
else
   case $1 in
      reset-net|reset-nett|net|nett|fiksnett|fixnet|fixnett|fix-net|fix-nett)
         vboxmanage controlvm "${vm}" setlinkstate1 off 
         sleep 2 
         vboxmanage controlvm "${vm}" setlinkstate1 on
         ;;
      *) echo "${absolute_script_path_name} ERROR: Unknown arg '$1'"
         ;;
   esac
fi

# now in vbox-reset-net.sh
# vboxmanage controlvm kumichou setlinkstate1 off ; sleep 2 ; vboxmanage controlvm kumichou setlinkstate1 on

# vboxmanage modifyvm "kumichou" --cpuhotplug on
