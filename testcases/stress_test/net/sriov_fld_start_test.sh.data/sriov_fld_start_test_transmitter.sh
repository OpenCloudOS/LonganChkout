#!/bin/bash

tools_dir=$(cd `dirname $0`;pwd)

eth1_ipv4_addr=$1
eth0_ipv4_addr=$2
password=$3
test_time=$4

$tools_dir/fld -t -T $eth1_ipv4_addr -p 37000 -f 3 -n 1 -s 64
$tools_dir/fld -t -T $eth1_ipv4_addr -p 37001 -f 3 -n 1 -s 10000

#udp flood
$tools_dir/fld -u -T $eth1_ipv4_addr -p 37100 -f 3 -n 1 -s 64

date_sec=`date "+%s"`
date_timeout=$((date_sec+test_time))

while [ 1 ]
do
	if [ $date_sec -gt $date_timeout ]; then
        sshpass -p $password ssh -o StrictHostKeyChecking=no root@$eth0_ipv4_addr $tools_dir/benchmark.sh
		ret=$?
		killall fld
		echo "sriov_fld test finish"
		exit $ret
	fi
	date_sec=`date "+%s"`
	sleep 100
done