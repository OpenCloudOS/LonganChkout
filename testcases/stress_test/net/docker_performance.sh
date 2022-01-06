#!/bin/bash

cases_dir=$(cd `dirname $0`;pwd)  #脚本所在目录
tools_dir=$cases_dir/`basename $0`.data/

function usage() {
    cat << EOF
Usage: $0 [-s] [-S] [-c]
    -s: Server's ipv4 address of eth0
    -S: Server's ipv4 address of eth1
    -c: Client's ipv4 address
    -p: Server's password
    -P: Client's password
EOF
}

# Parse arguments
while getopts "s:S:c:p:P:" opt; do
    case $opt in
        s)
            server="$OPTARG"
            ;;
        S)
            server_1="$OPTARG"
            ;;
        c)
            client="$OPTARG"
            ;;
        p)
            server_pwd="$OPTARG"
            ;;
        P)
            client_pwd="$OPTARG"
            ;;
        *)
            usage
            exit 1
            ;;
    esac
done

if [ ! $server ]; then
    echo "Server's ipv4 address of eth0 not exists, see usage -s"
    usage
    exit 1
fi

if [ ! $server_1 ]; then
    echo "Server's ipv4 address of eth1 not exists, see usage -S"
    usage
    exit 1
fi

if [ ! $client ]; then
    echo "client not exists, see usage -c"
    usage
    exit 1
fi

sshpass -p $server_pwd ssh-copy-id -o StrictHostKeyChecking=no -i /root/.ssh/id_rsa.pub root@$server > /dev/null
if [ $? != 0 ]; then
    echo 'sshpass password to server failed'
    exit 1
fi
sshpass -p $client_pwd ssh-copy-id -o StrictHostKeyChecking=no -i /root/.ssh/id_rsa.pub root@$client > /dev/null
if [ $? != 0 ]; then
    echo 'sshpass password to client failed'
    exit 1
fi

scp -r $tools_dir root@$server:/root/ > /dev/null
if [ $? != 0 ]; then
    echo 'scp test tools to server failed'
    exit 1
fi
scp -r $tools_dir root@$client:/root/ > /dev/null
if [ $? != 0 ]; then
    echo 'scp test tools to client failed'
    exit 1
fi

ssh root@$server "killall netserver ; /root/docker_performance.sh.data/netserver" > /dev/null
if [ $? != 0 ]; then
    echo 'ssh to server to kill netserver failed'
    exit 1
fi
echo 'run netperf from '$server' to '$client' start, the result will be recorded in '$cases_dir'/docker_performance_result.txt'
ssh root@$client "/root/docker_performance.sh.data/docker_performance_client.sh \"$server_1\"" > docker_performance_result.txt
if [ $? != 0 ]; then
    echo 'test run netperf in docker failed'
    exit 1
fi
echo 'test run netperf in docker success'
exit 0
