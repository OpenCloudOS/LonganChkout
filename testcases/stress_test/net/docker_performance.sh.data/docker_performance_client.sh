#!/bin/bash

server_1=$1

netperf_type="TCP_STREAM UDP_STREAM TCP_CRR TCP_RR UDP_RR"
test_len="1 512 1024 61440"
target_value=(
25
10
40000
100000
100000
10000
5834
40000
50000
50000
10000
10012
35000
50000
51000
15000
9103
5000
10279
4155
)

function netperf_test
{
	t=$1
	len=$2
	prefix=`echo ${t: -1} | tr '[A-Z]' '[a-z]'`
	i=0
	while((i<8))
	do
		if [ "$t" = "TCP_STREAM" ]; then
			netperf -t "$t" -H $server_1  -- -"$prefix" $len,$len | sed -n 7p | awk '{print $5}' >> /data/netperf_log.txt &
		elif [ "$t" = "UDP_STREAM" ]; then
			netperf -t "$t" -H $server_1  -- -"$prefix" $len,$len | sed -n 6p | awk '{print $6}' >> /data/netperf_log.txt &
		else
			netperf -t "$t" -H $server_1  -- -"$prefix" $len,$len | sed -n 7p | awk '{print $6}' >> /data/netperf_log.txt &
	        fi
		let "i++"
	done

	sleep 15
	echo "$t $len `cat /data/netperf_log.txt | awk '{sum+=$1} END {print sum}'`" >> /data/result.txt
	sleep 1
	rm /data/netperf_log.txt
}

function test_main
{
	len=$1
	for t in $netperf_type
	do
		 netperf_test $t $len
	done
}

function main 
{
	for len in $test_len
	do
		test_main $len
	done
}

function benches
{
	j=0
	while((j<2))
	do
		echo "====================`date`======================" >> /data/result.txt
		main
		let "j++"
		echo $j
	done
}

function average_compare
{
	k=0
	ret=0
	array_len=${#target_value[@]}
	if [ $array_len != 20 ];then
		echo "target length erro: $array_len != 20"
		exit 1
	fi
	
	for len in $test_len
	do
		for ttt in $netperf_type
		do
			average=`cat /data/result.txt | grep "$ttt $len " | sort | awk '{sum+=$3} END {print sum/NR}'`
			average=${average%.*}
			echo "$ttt	$len	$average ${target_value[k]}"
			if (( $average < ${target_value[k]} ));then
				echo "$ttt    $len    $average lower than ${target_value[k]}"
				ret=1
			fi
			let "k++"
		done
	done

	if [ $k != $array_len ];then
		echo "test cases changed to $k != $array_len"
		exit 1
	fi

	if [ $ret != 0 ];then
		exit 1
	fi
}

rm /data/result.txt
rm /data/average.txt
benches
average_compare
cat /data/result.txt
