#!/bin/bash

WORKSPACE=$(cd `dirname $0`;pwd)

source $WORKSPACE/config

if [[ ! $iplist || ${#iplist[@]} != '3' ]]; then
	echo 'iplist not exists, the length should be 3'
fi
if [[ ! $pwdlist || ${#pwdlist[@]} != '3' ]]; then
	echo 'pwdlist not exists, the length should be 3'
fi

SERVER="${iplist[0]}"
SERVER_PWD="${pwdlist[0]}"

CLIENT1="${iplist[1]}"
CLIENT1_PWD="${pwdlist[1]}"

CLIENT2="${iplist[2]}"
CLIENT2_PWD="${pwdlist[2]}"

cases=(
'TCP_RR 40 1 279696'
'TCP_RR 40 1024 258447'
'UDP_RR 40 1 293778'
'UDP_RR 40 1024 259490'
'TCP_STREAM 40 1 190076'
'TCP_STREAM 40 512 815892'
'TCP_STREAM 40 1024 1084713'
'TCP_STREAM 40 60000 135391'
'UDP_STREAM 40 1 1456001'
'UDP_STREAM 40 512 1391080'
'UDP_STREAM 40 1472 1391080'
'UDP_STREAM 40 60000 2071217'
'TCP_CRR 40 1 379211'
'TCP_CRR 40 1024 369855'
)

function ping_test()
{
	local ip=$1

	ping -c 1 $ip >/dev/null 
	[ $? == 0 ] && return 0

	return 1
}

function do_cmd_timeout()
{
	local ip=$1
	local usr="root"
	local passwd=$2
	local port=36000

	$WORKSPACE/ssh.exp $ip $usr $passwd $port "$3" 3000
}

function do_scp_timeout()
{
	local ip=$1
	local usr="root"
	local passwd=$2
	local port=36000
	local src_dir=$3
	local dst_dir=$4
	local direction="push"
	local bwlimit=0
	local timeout=-1
	$WORKSPACE/scp.exp $ip $usr $passwd $port $src_dir $dst_dir $direction $bwlimit $timeout
}

function do_scp_pull_timeout()
{
	local ip=$1
	local usr="root"
	local passwd=$2
	local port=36000
	local src_dir=$3
	local dst_dir=$4
	local direction="pull"
	local bwlimit=0
	local timeout=-1
	$WORKSPACE/scp.exp $ip $usr $passwd $port $src_dir $dst_dir $direction $bwlimit $timeout
}

function test_netperf()
{
	local ip=$1
	local pwd=$2
	do_cmd_timeout $ip $pwd "netperf -V" | grep "Netperf version 2.7.1" > /dev/null
	if [ $? == 1 ];then
		echo "check $ip netperf failed"
		exit 1
	else
		echo "check $ip netperf success"
		return 0
	fi 
}

function check_netperf()
{
	ips="$CLIENT1 $CLIENT2 $SERVER"	

	ip_seq=(1 2 0)
	for (( idx=0;idx<${#ip_seq[@]};idx++ )) 
	do
		i=${ip_seq[idx]}
		test_netperf "${iplist[i]}" "${pwdlist[i]}"
	done
}

function check_network()
{
	for i in $iplist
	do
		ping_test $i
		if [ $? == 1 ];then
			echo "check $i ping failed"
		else
			echo "check $i ping success"
		fi
	done
}

function install_netperf()
{
	do_scp_timeout $CLIENT1 $CLIENT1_PWD $WORKSPACE/netperf-src.tar.bz2 /tmp
	do_cmd_timeout $CLIENT1 $CLIENT1_PWD "cd /tmp/;tar xjvf netperf-src.tar.bz2;cd netperf-src;sh autogen.sh;./configure;make install" 

	do_scp_timeout $CLIENT2 $CLIENT2_PWD $WORKSPACE/netperf-src.tar.bz2 /tmp
	do_cmd_timeout $CLIENT2 $CLIENT2_PWD "cd /tmp/;tar xjvf netperf-src.tar.bz2;cd netperf-src;sh autogen.sh;./configure;make install"

	do_scp_timeout $SERVER $SERVER_PWD $WORKSPACE/netperf-src.tar.bz2 /tmp
	do_cmd_timeout $SERVER $SERVER_PWD "cd /tmp/;tar xjvf netperf-src.tar.bz2;cd netperf-src;sh autogen.sh;./configure;make install"
}

function netperf_test()
{
	local cmd=$1	
	local threads=$2

	do_cmd_timeout $SERVER $SERVER_PWD "killall netserver;killall netperf;setsid netserver &" >/dev/null
	do_cmd_timeout $CLIENT1 $CLIENT1_PWD "killall netserver;killall netperf" >/dev/null  
	do_cmd_timeout $CLIENT2 $CLIENT2_PWD "killall netserver;killall netperf" >/dev/null  

	printf "client(%s) excutes %s (%d threads)\n" $CLIENT1  "${cmd}" $threads
	printf "client(%s) excutes %s (%d threads)\n" $CLIENT2  "${cmd}" $threads

	sleep 1
	for ((i=0;i<$threads;i++))
	do
		do_cmd_timeout  $CLIENT1 $CLIENT1_PWD "setsid ${cmd} &"  >/dev/null & 
		do_cmd_timeout  $CLIENT2 $CLIENT2_PWD "setsid ${cmd} &"  >/dev/null &
		sleep 0.1
	done
}

function sample_data()
{
	do_cmd_timeout $SERVER $SERVER_PWD "echo > /tmp/netperf.log.txt" >/dev/null
	for ((i=0;i<5;i++))
	do
		echo "sampling data from $SERVER"
		do_cmd_timeout $SERVER $SERVER_PWD "sar -n DEV 2 1|grep eth0|grep Average|awk '{print \$3,\$5}' >>/tmp/netperf.log.txt" >/dev/null
		sleep 10
	done
	do_scp_pull_timeout $SERVER $SERVER_PWD /tmp/netperf.log.txt /tmp/netperf.log.txt >/dev/null
	echo "collecting data from server:"
	cat /tmp/netperf.log.txt|grep -Ev "^$|[#;]" 
	echo "--------------------------------"
	cat  /tmp/netperf.log.txt|grep -Ev "^$|[#;]" | awk '{a=a+$1;c=c+$2;b++;}END{print a/b,c/b}'
}

function format_data()
{
	local TYPE=$1
	local PACKET_LEN=$2
	local THREADS=$3
	local STAND=$4

	#printf "%dU%dG-vhost(%d队列) " $cpus $mem $queue>>/tmp/result.csv
	echo -e "vhost-4U8G4Q,\c" >> /tmp/result.csv
	echo -e "$TYPE,\c" >>  /tmp/result.csv
	echo -e "$PACKET_LEN,\c"  >>  /tmp/result.csv
	echo -e "$THREADS*2,\c" >> /tmp/result.csv
	result=`cat  /tmp/netperf.log.txt|grep -Ev "^$|[#;]" | awk '{a=a+$1;c=c+$2;b++;}END{print int(c/b)}'`
	echo -e "$result,\c" >> /tmp/result.csv

	result=`cat  /tmp/netperf.log.txt|grep -Ev "^$|[#;]" | awk '{a=a+$1;c=c+$2;b++;}END{print int(a/b)}'`
	echo -e "$result,\c" >> /tmp/result.csv
	echo -e "$STAND,\c" >> /tmp/result.csv
	r=`echo " $result * 10 > $STAND * 9 " |bc -l`
	if [ "$r" == 0 ] ;then 
		echo  "fail" >> /tmp/result.csv
	else
		echo  "pass" >> /tmp/result.csv
	fi
}

function get_machine_info()
{
	ip_seq=(1 2 0)
	for (( idx=0;idx<${#ip_seq[@]};idx++ )) 
	do
		i=${ip_seq[idx]}
		do_cmd_timeout "${iplist[i]}" "${pwdlist[i]}" "cat /proc/cpuinfo |grep MHz|wc -l >/tmp/machine.txt "  >/dev/null		
		do_cmd_timeout "${iplist[i]}" "${pwdlist[i]}" "free -m|grep Mem |awk '{print \$2}'  >>/tmp/machine.txt "  >/dev/null		
		do_cmd_timeout "${iplist[i]}" "${pwdlist[i]}" "ethtool -i eth0 |grep driver|awk '{print \$2}'  >>/tmp/machine.txt "  >/dev/null	
		do_cmd_timeout "${iplist[i]}" "${pwdlist[i]}" "ls -l /sys/class/net/eth0/queues/|grep tx|wc -l  >>/tmp/machine.txt "  >/dev/null
		do_cmd_timeout "${iplist[i]}" "${pwdlist[i]}" "uname -r  >>/tmp/machine.txt "  >/dev/null
		
		do_scp_pull_timeout "${iplist[i]}" "${pwdlist[i]}" /tmp/machine.txt /tmp/machine.txt >/dev/null
		echo "${iplist[i]}""-info:" >> /tmp/result.csv
		echo "cpu,mem(MB),driver,queues,kernel" >> /tmp/result.csv
		for j in `cat  /tmp/machine.txt`
		do
			echo -e "$j,\c" >> /tmp/result.csv
		done
		echo "" >> /tmp/result.csv
	done	
}

trap 'echo "rm /tmp/kvm_vhost_netperf_test!";rm -f /tmp/kvm_vhost_netperf_test; exit' 1 2 3 9 15
if [ -f /tmp/kvm_vhost_netperf_test ];then
	echo "Already in testing..."
	exit 1
else
	touch /tmp/kvm_vhost_netperf_test
fi

#valid netperf version
check_netperf 
sleep 1
check_network

#bakeup old data
mv /tmp/result.csv /tmp/result.old.csv 2>/dev/null
get_machine_info

#init new data
echo "2VM->1VM,type,len,threads,rxkB/s,rxpck/s,baseline(pck/s),result" >> /tmp/result.csv

#run test
for i in "${cases[@]}"; do
    b=($i)
	TYPE=${b[0]}
	THREADS=${b[1]}
	PACKET_LEN=${b[2]}
	STAND=${b[3]}
	((k++));
	if [ $TYPE == TCP_RR -o $TYPE == UDP_RR -o $TYPE == TCP_CRR ];then
	        CMD="netperf -H $SERVER -t $TYPE  -l 120 -- -r $PACKET_LEN,$PACKET_LEN"
	else
        	CMD="netperf -H $SERVER -t  $TYPE -l 120 -- -m $PACKET_LEN"
	fi
	date=`date "+%H:%M:%S"`
	printf "~~~~~~~[$k/${#cases[@]}]~~~~~~run %s~~~[%s]~~~~~~~~~\n"	"$CMD"  $date
        netperf_test "$CMD" $THREADS
	sleep 10
	sample_data
	format_data $TYPE $PACKET_LEN $THREADS $STAND
done 
echo "test result:"
cat /tmp/result.csv
rm -f /tmp/kvm_vhost_netperf_test
