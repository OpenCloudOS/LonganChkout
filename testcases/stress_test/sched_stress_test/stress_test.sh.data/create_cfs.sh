#!/bin/bash
self_dir=$(cd "$(dirname "$0")"; pwd)

period=100000
quota=50000
while [ 1  ]
do
	dir=/sys/fs/cgroup/cpu/test_cfs
	mkdir $dir
	echo $period > $dir/cpu.cfs_period_us
	echo $quota > $dir/cpu.cfs_quota_us
	let quota=$quota+500
	if [ $quota -gt 100000 ]; then
	    quota=50000
	fi
	echo $$ > $dir/tasks

	$self_dir/add_test_cfs.sh $*
done
