#!/bin/bash

self_dir=$(cd "$(dirname "$0")"; pwd)
script=$(basename "$0")
data_dir=$self_dir/${script}.data/


dirlist1="
/sys/fs/cgroup/cpu/press_test1
/sys/fs/cgroup/cpu/press_test1/testdir1/testdir1
/sys/fs/cgroup/cpu/press_test1/testdir1/testdir2
/sys/fs/cgroup/cpu/press_test1/testdir2/testdir1
/sys/fs/cgroup/cpu/press_test1/testdir2/testdir2
/sys/fs/cgroup/cpu/press_test2
/sys/fs/cgroup/cpu/press_test2/testdir1/testdir1
/sys/fs/cgroup/cpu/press_test2/testdir1/testdir2
/sys/fs/cgroup/cpu/press_test2/testdir2/testdir1
/sys/fs/cgroup/cpu/press_test2/testdir2/testdir2
"
dirlist=(
/sys/fs/cgroup/cpu/press_test1
/sys/fs/cgroup/cpu/press_test1/testdir1/testdir1
/sys/fs/cgroup/cpu/press_test1/testdir1/testdir2
/sys/fs/cgroup/cpu/press_test1/testdir2/testdir1
/sys/fs/cgroup/cpu/press_test1/testdir2/testdir2
/sys/fs/cgroup/cpu/press_test2
/sys/fs/cgroup/cpu/press_test2/testdir1/testdir1
/sys/fs/cgroup/cpu/press_test2/testdir1/testdir2
/sys/fs/cgroup/cpu/press_test2/testdir2/testdir1
/sys/fs/cgroup/cpu/press_test2/testdir2/testdir2
)

function autotest_postclean()
{
	pkill sched_t_thread
	sleep 5
	rmdir /sys/fs/cgroup/cpu/inheritance_test/test
	rmdir /sys/fs/cgroup/cpu/inheritance_test
}

function autotest_test()
{
	for str in $dirlist1
	do
		mkdir -p $str
		let offline=$RANDOM%2
		echo "set $str/cpu.offline to $offline"
		echo $offline > $str/cpu.offline
	done

	for((i=1;i<=100;i++))
	do
		let offline=$RANDOM%10
		$data_dir/sched_t_thread &
                pid=$!
                $data_dir/set_offline $pid
		echo $pid >  ${dirlist[$offline]}/tasks
	done

#	autotest_postclean

	return 0

}

function main()
{
	cat /proc/cmdline | grep offline_class > /dev/null 2>&1
        class=$?
        cat /proc/cmdline | grep offline_group > /dev/null 2>&1
        group=$?
        if [ $class != 0 -o $group != 0 ]
        then
                printf "test ok\n"
                return 0
        fi

	autotest_test

	if [ $? == 0 ]
	then 
		printf "test %s\n"  "ok"
		return 0
	else
		printf "test %s\n"  "err"
		return 1
	fi
	# autotest_postclean

}

main

