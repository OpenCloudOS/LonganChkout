#!/bin/bash

self_dir=$(cd "$(dirname "$0")"; pwd)
script=$(basename "$0")
data_dir=$self_dir/${script}.data/

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

function autotest_test()
{
    for((i=0;i<200;i++))
    do
	#produce a thread
	$data_dir/sched_t_thread &
	pid=$!	

	disown $!

	#set the thread to offline
	$data_dir/set_offline $pid

	#set_offline error	
	if [ $? != 0 ];
	then 
		autotest_clean
		return 1
	fi
	
	#check whether the thread is offline now
	policy=`cat /proc/$pid/sched |grep policy | awk '{print $3}'`

	if [ $policy != 7 ];
	then 
		autotest_clean
		return 1
	fi

	#set back to fair
	$data_dir/set_fair $pid

	if [ $? != 0 ];
        then
		autotest_clean
                return 1
        fi

	policy=`cat /proc/$pid/sched |grep policy | awk '{print $3}'`

        if [ $policy != 0 ];
        then
		autotest_clean
                return 1
        fi
     done
     autotest_clean

     return 0
}

function main()
{
	cat /proc/cmdline | grep offline_class > /dev/null 2>&1
	class=$?
	if [ $class != 0 ]
	then
		printf "succeed\n"
		return 0
	fi

	autotest_prepare

	autotest_clean
	
	autotest_test

	if [ $? == 0 ]
	then 
		printf "succeed\n"
		return 0 
	else
		printf "failed\n"
		return 1
	fi
}

main

