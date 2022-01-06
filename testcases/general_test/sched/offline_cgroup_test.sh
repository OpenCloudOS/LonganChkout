#!/bin/bash
self_dir=$(cd "$(dirname "$0")"; pwd)
script=$(basename "$0")
data_dir=$self_dir/${script}.data/


function autotest_prepare()
{
        make sched_t_thread  > /dev/null 2>&1
        make set_offline > /dev/null 2>&1
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
	else 				#  offline_group # or No start parameters  
		return 0
	fi
}

function autotest_postclean()
{

	rmdir /sys/fs/cgroup/cpu/nonroot_dir_test
	return 0
}

function check_pid_offline()
{
	policy=`cat /proc/$1/sched |grep policy | awk '{print $3}'`

        if [ $policy == "7" ];
        then
                return 0
	else 
		return 1
        fi	

}

function check_offline_file()
{
	if [ -f /sys/fs/cgroup/cpu/cpu.offline ]; then
		return 1
	fi
	
	return 0
}

function basic_set_check()
{
	$data_dir/sched_t_thread &	

	pid=$!

	disown $pid

	echo $pid > /sys/fs/cgroup/cpu/tasks

	$data_dir/set_offline $pid

	if [ $? != 0 ];
        then
		kill -9 $pid
                return 1
        fi

	check_pid_offline $pid # check the task is bt	

	if [ $? != 0 ];
        then
		kill -9 $pid
                return 1
        fi
	
	kill -9 $pid

	return 0
}

function no_para_root_test()
{

	$data_dir/sched_t_thread &	

	pid=$!

	disown $pid

	echo $pid > /sys/fs/cgroup/cpu/tasks

	$data_dir/set_offline $pid

	if [ $? == 0 ];
        then
		kill -9 $pid
                return 1
        fi

	check_pid_offline $pid 	

	if [ $? != 1 ];
        then
		kill -9 $pid
                return 1
        fi

	check_offline_file

	if [ $? == 1 ];
        then
                return 1
        fi

	kill -9 $pid

	return 0

}

function one_para_root_test()
{

	basic_set_check

	if [ $? == 1 ];
        then
                return 1
        fi

	check_offline_file

	if [ $? == 1 ];
        then
                return 1
        fi

	return 0
}

function root_setscheduler_test()
{
	$data_dir/sched_t_thread &	

	pid=$!

	disown $pid

	echo $pid > /sys/fs/cgroup/cpu/tasks

	$data_dir/set_offline $pid

	if [ $? != 0 ];
        then
		kill -9 $pid
                return 1
        fi

	echo 1 > /sys/fs/cgroup/cpu/cpu.offline 2>&1 

	if [ $? == 0 ];
        then
		kill -9 $pid
                return 1
        fi

	kill -9 $pid
	return 0
} 


function no_para_noroot_test()
{
	mkdir -p /sys/fs/cgroup/cpu/nonroot_dir_test

	cat /sys/fs/cgroup/cpu/nonroot_dir_test/cpu.offline > /dev/null 2>&1

	if [ $? != 1 ]
	then
		rmdir /sys/fs/cgroup/cpu/nonroot_dir_test
		return 1
	fi

	$data_dir/sched_t_thread &	

	pid=$!

	disown $pid

	echo $pid > /sys/fs/cgroup/cpu/nonroot_dir_test/tasks

	$data_dir/set_offline $pid

	if [ $? == 1 ];
        then
		kill -9 $pid
		rmdir /sys/fs/cgroup/cpu/nonroot_dir_test
                return 1
        fi

	if [ -f /sys/fs/cgroup/cpu/nonroot_dir_test/cpu.offline ]; then
		rmdir /sys/fs/cgroup/cpu/nonroot_dir_test
		return 1
	fi

	kill -9 $pid
	rmdir /sys/fs/cgroup/cpu/nonroot_dir_test

	return 0

}




function class_para_noroot_test()
{
	mkdir -p /sys/fs/cgroup/cpu/nonroot_dir_test

	cat /sys/fs/cgroup/cpu/nonroot_dir_test/cpu.offline > /dev/null 2>&1

	if [ $? != 1 ]
	then
		rmdir /sys/fs/cgroup/cpu/nonroot_dir_test
		return 1
	fi

	$data_dir/sched_t_thread &	

	pid=$!

	disown $pid

	echo $pid > /sys/fs/cgroup/cpu/nonroot_dir_test/tasks

	$data_dir/set_offline $pid

	if [ $? == 1 ];
        then
		kill -9 $pid
		rmdir /sys/fs/cgroup/cpu/nonroot_dir_test
                return 1
        fi

	check_pid_offline $pid	

	if [ $? != 0 ];
        then
		kill -9 $pid
		rmdir /sys/fs/cgroup/cpu/nonroot_dir_test
                return 1
        fi

	kill -9 $pid
	rmdir /sys/fs/cgroup/cpu/nonroot_dir_test

	return 0
} 

function nonroot_setscheduler_test()
{

	mkdir -p /sys/fs/cgroup/cpu/nonroot_dir_test

	offline=`cat /sys/fs/cgroup/cpu/nonroot_dir_test/cpu.offline`

	if [ $offline != 0 ]
	then
		return 1
	fi

	$data_dir/sched_t_thread &	

	pid=$!

	disown $pid

	echo $pid > /sys/fs/cgroup/cpu/nonroot_dir_test/tasks

	$data_dir/set_offline $pid

	if [ $? == 0 ];
        then
		kill -9 $pid
                return 1
        fi

	echo 1 > /sys/fs/cgroup/cpu/nonroot_dir_test/cpu.offline 2>&1

	if [ $? != 0 ];
        then
		kill -9 $pid
                return 1
        fi

	check_pid_offline $pid	

	if [ $? != 0 ];
        then
		kill -9 $pid
                return 1
        fi


	echo 0 > /sys/fs/cgroup/cpu/nonroot_dir_test/cpu.offline

	if [ $? != 0 ];
        then
		kill -9 $pid
                return 1
        fi

	check_pid_offline $pid	

	if [ $? != 1 ];
        then
		kill -9 $pid
                return 1
        fi

	kill -9 $pid

	return 0
} 

autotest_type_two_cmd_para()
{
	root_setscheduler_test
	if [ $? != 0 ];
        then
		echo "set root offline test failed"
		autotest_postclean
                return 1
        fi

	nonroot_setscheduler_test  

	if [ $? != 0 ];
        then
		echo "non root offline test failed"
		autotest_postclean
                return 1
        fi

	autotest_postclean
	return 0

}

function autotest_type_class_cmd_para()
{
	one_para_root_test

	if [ $? != 0 ];
        then
                return 1
        fi

	class_para_noroot_test

	if [ $? != 0 ];
        then
                return 1
        fi

	return 0
}

function autotest_type_no_cmd_para()
{

	no_para_root_test

	if [ $? != 0 ];
        then
                return 1
        fi

	no_para_noroot_test

	if [ $? != 0 ];
        then
                return 1
        fi

	return 0

}

function autotest_test()
{

	cmdline_check
	type=$?

	case $type in
		2)
			autotest_type_two_cmd_para
			return $?
		;;
		1)
			autotest_type_class_cmd_para
			return $?
		;;
		0)
			autotest_type_no_cmd_para
			return $?
		;;	
	esac
}

function main()
{
	autotest_prepare
	
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

