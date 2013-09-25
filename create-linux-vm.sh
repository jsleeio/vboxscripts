#!/bin/sh

# John Slee <john@slee.id.au> Wed 25 Sep 2013 13:53:48 MYT

name="$1"
topdir="$HOME/VirtualBox VMs"
vmpath="$topdir/$name"
oshd="$vmpath/${name}_os.vdi"
iso="$HOME/Downloads/iso/oel6.4-x86_64.iso"

if test -z "$name" ; then
	echo "$0: a name must be specified!"
	exit 1
fi

VBoxManage createvm --name "$name" --ostype Oracle_64 --register
VBoxManage modifyvm "$name" --memory 2048 --nic1 hostonly --hostonlyadapter1 vboxnet0 --nictype1 82540EM
VBoxManage createhd --filename "$oshd" --size 8192 --format vdi
VBoxManage storagectl "$name" --name sata0 --add sata --bootable on
VBoxManage storagectl "$name" --name ide0 --add ide --bootable on
VBoxManage storageattach "$name" --type dvddrive --storagectl ide0 --port 1 --device 1 --medium "$iso"
VBoxManage storageattach "$name" --type hdd --storagectl sata0 --medium "$oshd" --port 1
