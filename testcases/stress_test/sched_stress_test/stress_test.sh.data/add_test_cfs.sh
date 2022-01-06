#!/bin/bash
self_dir=$(cd "$(dirname "$0")"; pwd)
#script=$(basename "$0")
#data_dir=$self_dir/${script}.data/

$self_dir/test_03
#		echo $! > /sys/fs/cgroup/cpu/test/tasks
