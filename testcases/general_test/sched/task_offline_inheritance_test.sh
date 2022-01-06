#!/bin/bash

self_dir=$(cd "$(dirname "$0")"; pwd)
script=$(basename "$0")
data_dir=$self_dir/${script}.data/

function autotest_prepare()
{
        make sched_t_thread  > /dev/null 2>&1
        make set_offline > /dev/null 2>&1
        make set_cfs > /dev/null 2>&1
}

function autotest_clean()
{
	pkill sched_t_thread
}

function cmdline_check()
{
        cat /proc/cmdline  |grep offline_class > /dev/null 2>&1
        class=$?

        cat /proc/cmdline  |grep offline_group > /dev/null 2>&1
        group=$?

        if [ $class == 0 -a $group == 0 ];# offline_group offline_class
        then
                return 2
        elif [ $class == 0 -a $group == 1 ];# offline_class only
        then
                return 1
        else                            #  offline_group # or No start parameters  
                return 0
        fi
}


function check_pid_offline()
{
        policy=`cat /proc/$1/sched |grep policy | awk '{print $3}'`

	echo "policy:$policy pid:$1"
        if [ $policy == "7" ];
        then
                return 0
        else
                return 1
        fi
}

function autotest_test()
{

	cmdline_check
	
	type=$?

	if [ $type == 0 ];
	then
		return 0
	fi

	$data_dir/set_offline $$

	check_pid_offline $$

	if [ $? != 0 ];
        then
		autotest_clean
		echo "set $$ to offline failed"
                return 1
        fi
	$data_dir/sched_t_thread &
        pid=$!
	disown $pid
	check_pid_offline $pid
        if [ $? != 0 ];
        then
		kill -9 $pid
		autotest_clean
		echo "change sched_t_thread to offline failed"
                return 1
        fi

	$data_dir/set_cfs $pid
	check_pid_offline $pid

        if [ $? != 1 ];
        then
                kill -9 $pid
		autotest_clean
		echo "change set_cfs to offline check error"
                return 1
        fi

	kill -9 $pid
	autotest_clean
	return 0

}

function main()
{
	autotest_prepare
	autotest_test

	if [ $? == 0 ]
	then 
		printf "succeed\n"
		exit 0
	else
		printf "failed\n"
		exit 1 
	fi

}

main

