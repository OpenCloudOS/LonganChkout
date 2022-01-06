#!/bin/bash

tools_dir=$(cd `dirname $0`;pwd)

eth1_ipv6_addr=$1
eth1_ether=$2
eth0_ipv4_addr=$3
password=$4
test_time=$5

#tcp syn flood
$tools_dir/fld -t6 -T $eth1_ipv6_addr -p 38000 -f 3 -n 1 -s 64 -M $eth1_ether -i eth1
$tools_dir/fld -t6 -T $eth1_ipv6_addr -p 38001 -f 3 -n 1 -s 10000 -M $eth1_ether -i eth1

#udp flood
$tools_dir/fld -u6 -T $eth1_ipv6_addr -p 38100 -f 3 -n 1 -s 64 -M $eth1_ether -i eth1

date_sec=`date "+%s"`
date_timeout=$((date_sec+test_time))

while [ 1 ]
do
	if [ $date_sec -gt $date_timeout ]; then
        sshpass -p $password ssh -o StrictHostKeyChecking=no root@$eth0_ipv4_addr sh $tools_dir/benchmark.sh
		ret=$?
		killall fld
		echo "sriov_ipv6_fld test finish"
		exit $ret
	fi
	date_sec=`date "+%s"`
	sleep 100
done

