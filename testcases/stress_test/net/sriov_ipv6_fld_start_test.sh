#!/bin/bash
# 打流测试，从Transmitter往Receiver发送流量
# 需要Receiver有两张网卡，并有ipv6地址
# 持续时间由test_time控制，默认12小时

cases_dir=$(cd `dirname $0`;pwd)  #脚本所在目录
tools_dir=$cases_dir/`basename $0`.data/

let test_time=12*60*60

function usage() {
    cat << EOF
Usage: $0 [-t] [-p] [-r] [-R] [-e] [-P] [-T]
    -t: Transmitter's ipv4 address
    -p: Ssh password of transmitter. 
    -r: Receiver's ipv4 address of eth0
    -R: Receiver's ipv6 address of eth1
    -e: Receiver's ether of eth1
    -P: Ssh password of receiver.
    -T: Test time (second), default 12*60*60
EOF
}

# Parse arguments
while getopts "t:p:r:R:e:P:T:" opt; do
    case $opt in
        t)
            transmitter="$OPTARG"
            ;;
        r)
            eth0_ipv4_addr="$OPTARG"
            ;;
        R)
            eth1_ipv6_addr="$OPTARG"
            ;;
        e)
            eth1_ether="$OPTARG"
            ;;
        p)
            transmitter_passwd="$OPTARG"
            ;;
        P)
            receiver_passwd="$OPTARG"
            ;;
        T)
            test_time="$OPTARG"
            ;;
        *)
            usage
            exit 1
            ;;
    esac
done

if [ ! $transmitter ]; then
    echo "transmitter not exists, see usage -t"
    usage
    exit 1
fi

if [ ! $eth0_ipv4_addr ]; then
    echo "eth0_ipv4_addr not exists, see usage -r"
    usage
    exit 1
fi

if [ ! $eth1_ipv6_addr ]; then
    echo "eth1_ipv6_addr not exists, see usage -R"
    usage
    exit 1
fi

if [ ! $eth1_ether ]; then
    echo "eth1_ether not exists, see usage -e"
    usage
    exit 1
fi

if [ ! $transmitter_passwd ]; then
    echo "transmitter_passwd not exists, see usage -p"
    usage
    exit 1
fi

if [ ! $receiver_passwd ]; then
    echo "receiver_passwd not exists, see usage -P"
    usage
    exit 1
fi

sshpass -p $transmitter_passwd ssh-copy-id -o StrictHostKeyChecking=no -i /root/.ssh/id_rsa.pub root@$transmitter > /dev/null
if [ $? != 0 ]; then
    echo 'sshpass password to server failed'
    exit 1
fi
sshpass -p $transmitter_passwd ssh-copy-id -o StrictHostKeyChecking=no -i /root/.ssh/id_rsa.pub root@$eth0_ipv4_addr > /dev/null
if [ $? != 0 ]; then
    echo 'sshpass password to receiver failed'
    exit 1
fi

scp -r $tools_dir $transmitter:/root/
scp -r $tools_dir $eth0_ipv4_addr:/root/
ssh root@$transmitter "/root/sriov_ipv6_fld_start_test.sh.data/sriov_ipv6_fld_start_test_transmitter.sh \"$eth1_ipv6_addr\" \"$eth1_ether\" \"$eth0_ipv4_addr\" \"$transmitter_passwd\" \"$test_time\" "

