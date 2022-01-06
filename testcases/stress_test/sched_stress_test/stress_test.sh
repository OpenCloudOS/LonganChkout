#!/bin/bash

# 调度压测

self_dir=$(cd "$(dirname "$0")"; pwd)
script=$(basename "$0")
data_dir=$self_dir/${script}.data

let test_time=3*24*60*60

function usage() {
    cat << EOF
Usage: $0 [-t]
    -t: Test time (second), default 3*24*60*60
EOF
}

# Parse arguments
while getopts "t:" opt; do
    case $opt in
        t)
            test_time="$OPTARG"
            ;;
        *)
            usage
            exit 1
            ;;
    esac
done

echo "data dir:$data_dir"
cpu_num_start=`cat /proc/cgroups | grep "cpuacct" | awk '{print $3}'`
echo "cpu num start:$cpu_num_start"

cfs_dir="/sys/fs/cgroup/cpu/test_cfs"
#if [ -d $cfs_dir ]
#then
#	echo "dir:$cfs_dir exist trying to delete it"
#	cat $cfs_dir/tasks | xargs -i echo {} > /sys/fs/cgroup/cpu/tasks; rmdir $cfs_dir/test
#fi

stress_dir="/sys/fs/cgroup/cpu/stress"
#if [ -d $stress_dir/test ]
#then
#	echo "dir:$stress_dir/test not null trying to delete it"
#	cat $stress_dir/test/tasks | xargs -i echo {} > /sys/fs/cgroup/cpu/tasks; rmdir $stress_dir/test
#fi

function test_clean()
{
    echo "test clean now"
    pkill add_test_bt.sh
    pkill add_test_cfs.sh
    pkill create_bt.sh
    pkill create_cfs.sh
    pkill rmdir_bt.sh
    pkill rmdir_cfs.sh
    pkill test_03
    pkill test_3

    sleep 20

    echo "test clean remove dir"
    if [ -d "$stress_dir/test" ]; then
        echo "dir:$stress_dir/test exist trying to delete it"
        cat $stress_dir/test/tasks | xargs -i echo {} > /sys/fs/cgroup/cpu/tasks; rmdir $stress_dir/test
    fi
    sleep 1
    if [ -d $stress_dir ]; then
        echo "dir:$stress_dir exist trying to delete it"
        cat $stress_dir/tasks | xargs -i echo {} > /sys/fs/cgroup/cpu/tasks; rmdir $stress_dir

        rmdir $stress_dir
    fi
    sleep 1

    if [ -d "$cfs_dir/test" ]; then
	echo "dir:$cfs_dir exist trying to delete it"
        cat $cfs_dir/test/tasks | xargs -i echo {} > /sys/fs/cgroup/cpu/tasks; rmdir $cfs_dir/test
    fi

    sleep 1
    if [ -d $cfs_dir ]; then
	echo "dir:$cfs_dir exist trying to delete it"
        cat $cfs_dir/tasks | xargs -i echo {} > /sys/fs/cgroup/cpu/tasks; rmdir $cfs_dir
   fi
}

function start_cfs_test()
{
    echo "start cfs test now"
    $data_dir/create_cfs.sh > /dev/null 2>&1 &
    $data_dir/rmdir_cfs.sh > /dev/null 2>&1 &

    $data_dir/create_cfs.sh > /dev/null 2>&1 &
    $data_dir/rmdir_cfs.sh > /dev/null 2>&1 &

    $data_dir/create_cfs.sh > /dev/null 2>&1 &
    $data_dir/rmdir_cfs.sh > /dev/null 2>&1 &

    $data_dir/create_cfs.sh > /dev/null 2>&1 &
    $data_dir/rmdir_cfs.sh > /dev/null 2>&1 &

    $data_dir/create_cfs.sh > /dev/null 2>&1 &
    $data_dir/rmdir_cfs.sh > /dev/null 2>&1 &
}

function start_bt_test()
{
    echo "start BT cgroup stress test now"
    $data_dir/create_bt.sh > /dev/null 2>&1 &
    $data_dir/rmdir_bt.sh > /dev/null 2>&1 &

    $data_dir/create_bt.sh > /dev/null 2>&1 &
    $data_dir/rmdir_bt.sh > /dev/null 2>&1 &

    $data_dir/create_bt.sh > /dev/null 2>&1 &
    $data_dir/rmdir_bt.sh > /dev/null 2>&1 &

    $data_dir/create_bt.sh > /dev/null 2>&1 &
    $data_dir/rmdir_bt.sh > /dev/null 2>&1 &

    $data_dir/create_bt.sh > /dev/null 2>&1 &
    $data_dir/rmdir_bt.sh > /dev/null 2>&1 &
}

day_start=`date "+%s"`
day_end=$((day_start+test_time))
echo "test time:$test_time test start:$day_start end:$day_end"


echo "create cfs test dir:$cfs_dir"
mkdir $cfs_dir

echo "checking BT config now"
cat /proc/cmdline  |grep offline_group > /dev/null 2>&1

offline_group=$?
if [ $offline_group == 1 ]
then
    echo "ERROR:offline_group disabled"
    echo "only test cfs"
    start_cfs_test    

    sleep 10
    while [ 1 ]
    do
        day_now=`date "+%s"`
#        echo "check finish..."
#        echo "day now:$day_now day end:$day_end"
        if [ $day_now -gt $day_end ]; then
            echo "test should finish now clean"
            test_clean
            sleep 5
#            cpu_num_end=`cat /proc/cgroups | grep "cpuacct" | awk '{print $3}'`
#            echo "cpu num start:$cpu_num_start, cpu num end:$cpu_num_end"
#            if [ $cpu_num_start -ne $cpu_num_end ]; then
#                echo "cpu num changed after test"
#                echo "test failed"
#                exit 1
#            fi

            echo "test succeed"
            exit 0
        fi
    sleep 100
    done
fi

echo "set offline task use 50% cpu"
list=()
list=`lscpu -e | awk '{if(NR!=1) print $1}'`
for i in $list
do
	cat /proc/offline/cpu$i
	echo 50 > /proc/offline/cpu$i
	cat /proc/offline/cpu$i
done

echo "create bt test dir:$stress_dir"
mkdir $stress_dir

echo "set $stress_dir to offline"
echo 1 > $stress_dir/cpu.offline
echo $$ > $stress_dir/tasks

echo "start CFS & BT stress test now"
start_bt_test
start_cfs_test

sleep 10
while [ 1 ]
do
    day_now=`date "+%s"`
#    echo "check finish..."
#    echo "day now:$day_now day end:$day_end"
    if [ $day_now -gt $day_end ]; then
        echo "test should finish now clean"
        test_clean
        sleep 5
#        cpu_num_end=`cat /proc/cgroups | grep "cpuacct" | awk '{print $3}'`
#        echo "cpu num start:$cpu_num_start, cpu num end:$cpu_num_end"
#        if [ $cpu_num_start -ne $cpu_num_end ]; then
#            echo "cpu num changed after test"
#            echo "test failed"
#            exit 1
#        fi

        echo "stress test succeed"
        exit 0
    fi
    sleep 100
done

