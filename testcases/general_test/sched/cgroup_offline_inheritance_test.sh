#!/bin/bash

function autotest_postclean()
{
	rmdir /sys/fs/cgroup/cpu/inheritance_test/test
	rmdir /sys/fs/cgroup/cpu/inheritance_test
}

function autotest_test()
{
	mkdir -p /sys/fs/cgroup/cpu/inheritance_test

	offline=`cat /sys/fs/cgroup/cpu/inheritance_test/cpu.offline`

        if [ $offline != 0 ]
        then
                return 1
        fi

	echo 1 > /sys/fs/cgroup/cpu/inheritance_test/cpu.offline

        if [ $? != 0 ];
        then
                return 1
        fi

	mkdir -p /sys/fs/cgroup/cpu/inheritance_test/test

	offline=`cat /sys/fs/cgroup/cpu/inheritance_test/test/cpu.offline`

        if [ $offline != 1 ]
        then
                return 1
        fi

	return 0

}

function main()
{
	ret=0
	cat /proc/cmdline | grep offline_class > /dev/null 2>&1
	class=$?
	cat /proc/cmdline | grep offline_group > /dev/null 2>&1
	group=$?
	if [ $class != 0 -o $group != 0 ]
	then
		printf "test ok\n"
		return $ret
	fi

	autotest_test

	if [ $? == 0 ]
	then
		printf "test %s\n"  "ok"
		ret=0
	else
		printf "test %s\n"  "err"
		ret=1
	fi
	autotest_postclean

	return $ret
}

main

