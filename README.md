# vboxscripts

## Overview

Assorted scripts I use on my laptop for creating and managing VMs with VirtualBox.

This was designed for use under OSX, where VirtualBox defaults to putting things
in ```$HOME/VirtualBox VMs```. Likely need to change this path for VirtualBox on
Linux.

## Examples

### Create a single VM:
```
	create-linux-vm.sh foo
```

### Create a cluster for Oracle RAC purposes:
```
	create-linux-rac-vms.sh ractest
```

### Create a cluster for RHEL HA configuration, with quorum disk:
```
	create-linux-cluster-vms.sh foocluster
```
