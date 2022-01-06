#!/bin/bash

WORKSPACE=$(cd `dirname $0`;pwd)

source $WORKSPACE/config

ping_test()
{
    ip=$1
    ping $ip >/dev/null 
    if [ $? == 0 ];then
        return 0
    fi
    return 1
}

do_cmd_timeout()
{
    timeout $TIMEOUT ssh -o ConnectTimeout=3 root@$1 "$2"
}

do_cmd()
{
    ssh -o ConnectTimeout=3 root@$1 "$2"
}

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

hotplug()
{
	local exist=0
	local err=0

	echo ${#vmlist[@]}
	for ((i=0;i<${#vmlist[@]};i++)); do
   		check_nic_exist "${vmlist[i]}" "${maclist[i]}"
		if [ $? == 1 ]; then
			echo "hotplug vm ${vmlist[i]} existing nic ${maclist[i]}"
			#exit 1
			continue
		fi
	done

	# plug nic
	echo "plug nic"
	echo $vmlist
	for ((i=0;i<${#vmlist[@]};i++)); do
		plug_nic "${vmlist[i]}" "${maclist[i]}"
		if [ $? != 0 ]; then
			echo "hotplug vm ${vmlist[i]} nic ${maclist[i]} failed"
			continue
		fi
		check_nic_exist "${vmlist[i]}" "${maclist[i]}"
		if [ $? != 0 ]; then
			echo "plug ${vmlist[i]} success ${maclist[i]}"
		fi
	done
}
hotplug
