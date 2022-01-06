#!/bin/bash

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

mkdir -p /sys/fs/cgroup/memory/test
mkdir -p /sys/fs/cgroup/memory/test/test1
#mkdir -p /sys/fs/cgroup/memory/test/test2

echo 2097152 > /sys/fs/cgroup/memory/test/memory.limit_in_bytes

echo 1048576 > /sys/fs/cgroup/memory/test/test1/memory.limit_in_bytes
#echo 1048576 > /sys/fs/cgroup/memory/test/test2/memory.limit_in_bytes

$data_dir/malloc &
pid=$!
echo $pid > /sys/fs/cgroup/memory/test/tasks
$data_dir/malloc &
pid=$!
echo $pid > /sys/fs/cgroup/memory/test/test1/tasks

day_start=`date "+%s"`
day_end=$((day_start+test_time))
echo "test time:$test_time"

while [ 1 ]
do
    sleep 1
    $data_dir/malloc &
    pid=$!
    echo $pid > /sys/fs/cgroup/memory/test/tasks
    $data_dir/malloc &
    pid=$!
    echo $pid > /sys/fs/cgroup/memory/test/test1/tasks

    mkdir -p /sys/fs/cgroup/memory/test/test2
    rmdir /sys/fs/cgroup/memory/test/test2

    day_now=`date "+%s"`
    if [ $day_now -gt $day_end ]; then
        echo "oom test finish"
        exit 0
    fi
done
