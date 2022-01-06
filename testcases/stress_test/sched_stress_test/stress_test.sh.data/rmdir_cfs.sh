#!/bin/bash

while [ 1 ]
do
	cat /sys/fs/cgroup/cpu/test_cfs/tasks | xargs -i echo {} > /sys/fs/cgroup/cpu/tasks; rmdir /sys/fs/cgroup/cpu/test_cfs
done

