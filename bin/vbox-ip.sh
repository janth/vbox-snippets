#!/bin/bash

#for vm in $( vboxmanage list runningvms | awk '{ gsub(/"/, "", $1); print $1}' ) ; do
#for vm in $( vboxmanage list runningvms | sed -e 's/ {.*$//' -e 's/"//g' ) ; do
for vmid in $( vboxmanage list runningvms | sed -e 's/^.*{//' -e 's/}.*$//' ) ; do
   vm_name=$( vboxmanage list runningvms | grep "${vmid}" | sed -e 's/ {.*$//' -e 's/"//g' )
   # vboxmanage guestproperty enumerate 0219177f-fce1-44b8-9144-cacbd9d96425
   IP=$( vboxmanage guestproperty get "${vmid}" "/VirtualBox/GuestInfo/Net/1/V4/IP" | awk '{print $2}' )
   echo "${vm_name} (${vmid}): ${IP}"
done
