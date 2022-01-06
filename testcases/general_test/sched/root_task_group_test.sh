#!/bin/bash
function autotest_prepare()
{
	make sched_t_thread  > /dev/null 2>&1
	make set_offline > /dev/null 2>&1 
	make set_fair > /dev/null 2>&1 
}

function autotest_clean()
{
	pkill sched_t_thread > /dev/null 2>&1 
}

function cmdline_offline_class_test()
{
	cat /proc/cmdline  |grep offline_class > /dev/null 2>&1
	return $?
}

function cmdline_offline_group_test()
{
	cat /proc/cmdline  |grep offline_group > /dev/null 2>&1
	return $?
}

function cpu_offline_file_test()
{
	ls /sys/fs/cgroup/cpu/cpu.offline > /dev/null 2>&1
	
	if [ $? -ne 0 ]
	then 
		return 1
	else
		return 0
	fi
}

# inter_input_test start end input_err read_value
function inter_input_test()
{
	for((i=$1;i<=$2;i++))
        do
                echo $i > /sys/fs/cgroup/cpu/cpu.offline  2>&1
                if [ $? -ne $3 ]
                then
                        return 1
                fi
                num=`cat /sys/fs/cgroup/cpu/cpu.offline`
                if [ $num -ne $4 ]
                then
                        return 1
                fi
        done

	return 0

}

function string_input_presstest()
{
        for((k=0;k<100;k++))
        do
                str=`cat /dev/urandom | head -n 10 | md5sum | head -c $1`
                echo $str > /sys/fs/cgroup/cpu/cpu.offline  2>&1
        done
}

function autotest_test()
{

	cmdline_offline_class_test
	cmdline=$?
	if [ $cmdline -ne 0 ]
	then
		echo "offline_class is needed"
		return 1
	fi

	cmdline_offline_group_test
	cmdline=$?
	if [ $cmdline -ne 0 ]
	then
		echo "offline_group is needed"
		return 1
	fi

	cpu_offline_file_test
	file=$?
	if [ $file -ne 0 ]
	then
		echo "cpu.offline not found"
		return 1
	fi

	inter_input_test -10000 -1 1 0 
	if [ $? -eq 1 ]
	then
		autotest_clean
		return 1
	fi
	   
	inter_input_test 0 0 1 0 
	if [ $? -eq 1 ]
	then
		autotest_clean
		return 1
	fi

	inter_input_test 1 10000 1 0
	if [ $? -eq 1 ]
	then
		autotest_clean
		return 1
	fi

	for((i=1;i<=30;i++))
        do
                string_input_presstest $i
        done
	autotest_clean

	return 0
}

function main()
{

	autotest_prepare

	autotest_clean
	
	autotest_test

	if [ $? == 0 ]
	then 
		printf "succeed\n" 
	else
		printf "failed\n"

	fi

}

main

