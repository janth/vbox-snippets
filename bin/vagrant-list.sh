#!/bin/bash

script_name=${0##*/}                               # Basename, or drop /path/to/file
script=${script_name%%.*}                          # Drop .ext.a.b
script_path=${0%/*}                                # Dirname, or only /path/to
script_path=$( [[ -d ${script_path} ]] && cd ${script_path} ; pwd)             # Absolute path
script_path_name="${script_path}/${script_name}"   # Full path and full filename to $0
absolute_script_path_name=$( /bin/readlink --canonicalize ${script_path}/${script_name})   # Full absolute path and filename to $0
absolute_script_path=${absolute_script_path_name%/*}                 # Dirname, or only /path/to, now absolute
script_basedir=${script_path%/*}                   # basedir, if script_path is .../bin/

for d in $( find $HOME -type d -name \.vagrant 2>/dev/null  ) ; do
   for idfile in $d/machines/*/virtualbox/id ; do
      [[ ! -r $idfile ]] && continue
      id=$( cat $idfile )
      vbox=$( vboxmanage list vms | grep -i $id 2>/dev/null | sed -e 's/" .*$//' -e 's/"//' )
      if [[ -z ${vbox} ]] ; then
         echo "${d%/*}: No vbox with id ${id} found"
      else
         echo "${d%/*}: $vbox"
      fi
      grep '[:.]box' ${d%/*}/Vagrantfile
   done
   echo
done

echo -e "\n---\n"
for v in $( find $HOME -type f -name Vagrantfile 2>/dev/null | grep -v '/.vagrant.d/' ) ; do
   grep -H '[:.]box' $v
done

