#!/bin/bash

while [ 1 ]
do
	cat /sys/fs/cgroup/cpu/stress/test/tasks | xargs -i echo {} > /sys/fs/cgroup/cpu/stress/tasks; rmdir /sys/fs/cgroup/cpu/stress/test > /dev/null 2>&1
done
