#!/bin/sh

# John Slee <john@slee.id.au> Wed 25 Sep 2013 13:53:48 MYT

nodes=4
cvm=$HOME/bin/create-linux-vm.sh
test -x $cvm || exit 1
vmtop="$HOME/VirtualBox VMs"

vmbase="$1"
if test -z "$vmbase" ; then
	echo "$0: base VM name must be specified"
	exit 2
fi

log() {
	echo "log: $*" 1>&2
}

sata_nextport_new() {
	vm="$1"
	next="$(VBoxManage showvminfo "$vm" --machinereadable | sed -n 's/"//g; s/^sata0-\([[:digit:]]*\)-0=none/\1/p' | awk '$1 > 1' | head -1)"
	log "NEXT PORT (NEW METHOD) FOR VM $vm IS $next"
	echo $next
}

sata_nextport_old() {
	vm="$1"
	last="$(VBoxManage showvminfo "$vm" --machinereadable \
		| sed -n 's/^"SATA Controller-\([[:digit:]]*\)-0"=.*/\1/p' \
		| tail -1)"
	next="$((last+1))"
	log "NEXT PORT (OLD METHOD) FOR VM $vm IS $next"
	echo $next
}

sata_nextport() {
	if VBoxManage showvminfo "$vm" --machinereadable | grep -q 'SATA Controller' ; then
		next="$(sata_nextport_old $*)"
	else
		if VBoxManage showvminfo "$vm" --machinereadable | grep -q 'sata0-' ; then
			next="$(sata_nextport_new $*)"
		else
			log "FATAL: don't know how to interpret your VBoxManage showvminfo, giving up"
			exit 1
		fi
	fi
	if test "$next" == "" ; then
		log "FATAL: unable to get next free SATA port ID, giving up"
		exit 1
	fi
	echo $next
}

create_and_attach_shared_disks() {
	directory="$1"
	shift
	vmbase="$1"
	shift
	name="$1"
	shift
	size="$1"
	shift
	count="$1"
	shift
	for num in $(seq 1 $count) ; do
		vdi="$directory/${vmbase}_${name}-${num}.vdi"
		log "CREATE SHARED DISK $vdi"
		VBoxManage createhd --filename "$vdi" --size "$size" --variant Fixed \
			&& VBoxManage modifyhd "$vdi" --type shareable
		for vm in $* ; do
			nextport=$(sata_nextport "$vm")
			log "ATTACH SHARED DISK $vdi TO $vm PORT $nextport"
			VBoxManage storageattach "$vm" --type hdd --storagectl sata0 \
				--port "$nextport" --medium "$vdi"
		done
	done
}

vmnames() {
	base="$1"	
	count="$2"
	for num in $(seq 1 "$2") ; do
		log "LIST VM NAME $1$num"
		echo "$1$num"
	done
}

clustervdi="$vmtop/clustervdi/$vmbase"
mkdir -p "$clustervdi" || ( echo "$0: can't create cluster storage directory"; exit 3 )

all_vmnames="$(vmnames "$vmbase" "$nodes")"

for vmname in $all_vmnames ; do
	log "CREATE VM $vmname"
	# create the base VM
	$cvm $vmname
	# Need a cluster interconnect network, so add one
	log "MODIFY VM ADD NIC rac"
	VBoxManage modifyvm $vmname --nic2 intnet --nictype2 82540EM --intnet1 rac
done

create_and_attach_shared_disks "$clustervdi" "$vmbase" clu_quorum 128 1 $all_vmnames
create_and_attach_shared_disks "$clustervdi" "$vmbase" clu_app    128 2 $all_vmnames
create_and_attach_shared_disks "$clustervdi" "$vmbase" clu_data   128 3 $all_vmnames
