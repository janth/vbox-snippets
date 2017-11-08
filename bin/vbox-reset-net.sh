#!/bin/bash

vboxmanage controlvm geisha setlinkstate1 off 
sleep 2 
vboxmanage controlvm geisha setlinkstate1 on
