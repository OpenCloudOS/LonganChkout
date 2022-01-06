#!/bin/bash

WORKSPACE=$(cd `dirname $0`;pwd)

source $WORKSPACE/config

check_nic_exist()
{
	vm_name=$1
	mac=$2
	xml=

	xml=`virsh dumpxml $vm_name |grep $mac`
	if [ $? == 0 ]; then
		return 1
	fi
	return 0
}

plug_nic()
{
	vm_name=$1
	mac=$2

	virsh attach-interface $vm_name --type bridge --source br1 --model virtio --mac $mac
        if [ $? != 0 ]; then
		echo "plug failed"
                return 1
        fi
	return 0
}
unplug_nic()
{
        vm_name=$1
        mac=$2

	virsh detach-interface $vm_name --type bridge --mac $mac
        if [ $? != 0 ]; then
                echo "unplug failed"
                return 1
        fi
        return 0
}

hotunplug()
{
	exist=0
	err=0

	for ((i=0;i<${#vmlist[@]};i++)); do
		echo "${vmlist[i]}"
		echo "${maclist[i]}"
   		check_nic_exist "${vmlist[i]}" "${maclist[i]}"
		if [ $? == 0 ]; then
			echo "hotpunlug vm ${vmlist[i]} not existing nic ${maclist[i]}"
			continue
		fi
	done


	echo "unplug nic"
	for ((i=0;i<${#vmlist[@]};i++)); do
		unplug_nic "${vmlist[i]}" "${maclist[i]}"
		if [ $? != 0 ]; then
			echo "hotunplug vm ${vmlist[i]} nic ${maclist[i]} failed"
			#exit 1
		fi
		check_nic_exist "${vmlist[i]}" "${maclist[i]}"
		if [ $? == 0 ]; then
			echo "unplug ${vmlist[i]} ${maclist[i]} success "
		fi
	done
}
hotunplug
