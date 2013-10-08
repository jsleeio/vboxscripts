#!/bin/sh

# John Slee <john@slee.id.au> Wed 25 Sep 2013 13:53:48 MYT

cvm=$HOME/bin/create-linux-vm.sh
test -x $cvm || exit 1
vmtop="$HOME/VirtualBox VMs"

vmbase="$1"
if test -z "$vmbase" ; then
	echo "$0: base VM name must be specified"
	exit 2
fi

nodes=2
asmdisks=3

clustervdi="$vmtop/clustervdi/$vmbase"
mkdir -p "$clustervdi" || ( echo "$0: can't create cluster storage directory"; exit 3 )
for asmnum in $(seq 1 $asmdisks) ; do
	echo "$0: creating ASM disk #$asmnum"
	VBoxManage createhd --filename "$clustervdi/asm$asmnum.vdi" --size 2048 --variant Fixed
	VBoxManage modifyhd "$clustervdi/asm$asmnum.vdi" --type shareable
done

for nodenum in $(seq 1 $nodes) ; do
	vmname="${vmbase}${nodenum}"
	echo "$0: creating VM $vmname"
	# create the base VM
	$cvm $vmname
	# Oracle RAC needs a cluster interconnect network, so add one
	VBoxManage modifyvm $vmname --nic2 intnet --nictype2 82540EM --intnet1 rac
	# attach the shared disks to be used for Oracle ASM
	for asmnum in $(seq 1 $asmdisks) ; do
		echo "$0: attaching ASM disk #$asmnum"
		VBoxManage storageattach $vmname --type hdd --storagectl sata0 --port $((2+asmnum)) --medium "$clustervdi/asm$asmnum.vdi"
	done
done
