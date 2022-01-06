#!/bin/bash
self_dir=$(cd "$(dirname "$0")"; pwd)

cpu=50
while [ 1 ]
do
	list=()
        list=`lscpu -e | awk '{if($NR!=1) print $1}'`
	for i in $list
	do
		echo $cpu > /proc/offline/cpu$i
	done
	let cpu=$cpu+5
	if [ $cpu -gt 100 ]; then
		let cpu=50	
	fi
	dir=/sys/fs/cgroup/cpu/stress/test
	mkdir $dir
	echo 1 > $dir/cpu.offline
	echo $$ > $dir/tasks

	$self_dir/add_test_bt.sh $*
done
