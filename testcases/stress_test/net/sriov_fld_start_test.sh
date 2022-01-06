#!/bin/bash
# 打流测试，从Transmitter往Receiver发送流量
# 需要Receiver有两张网卡
# 持续时间由test_time控制，默认12小时

cases_dir=$(cd `dirname $0`;pwd)  #脚本所在目录
tools_dir=$cases_dir/`basename $0`.data/

function usage() {
    cat << EOF
Usage: $0 [-t] [-p] [-r] [-R] [-P] [-T]
    -t: Transmitter's ipv4 address
    -p: Ssh password of transmitter. 
    -r: Receiver's ipv4 address of eth0
    -R: Receiver's ipv4 address of eth1
    -P: Ssh password of receiver. 
    -T: Test time (second), default 12*60*60
EOF
}

let test_time=12*60*60

# Parse arguments
while getopts "t:r:R:p:P:T:" opt; do
    case $opt in
        t)
            transmitter="$OPTARG"
            ;;
        r)
            eth0_ipv4_addr="$OPTARG"
            ;;
        R)
            eth1_ipv4_addr="$OPTARG"
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

if [ ! $eth1_ipv4_addr ]; then
    echo "eth1_ipv4_addr not exists, see usage -R"
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
ssh root@$transmitter "/root/sriov_fld_start_test.sh.data/sriov_fld_start_test_transmitter.sh \"$eth1_ipv4_addr\" \"$eth0_ipv4_addr\" \"$receiver_passwd\" \"$test_time\" "
