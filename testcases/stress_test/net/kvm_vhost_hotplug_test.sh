#!/bin/bash

cases_dir=$(cd `dirname $0`;pwd)  #脚本所在目录
tools_dir=$cases_dir/`basename $0`.data/

function usage() {
    cat << EOF

Usage: $0 [-c] [-i]
    -c: Config of kvm, absolute path is necessary, with a template as below,
            vmlist=()
            maclist=()
            iplist=()
            eth1iplist=()
            TIMEOUT=
        e.g., 
            vmlist=(kvm_1_name kvm_2_name)
            maclist=(mac_1_addr mac_2_addr)
            iplist=(ip_1_addr ip_2_addr)
            eth1iplist=(eth1_1_ipaddr eth1_2_ipaddr)
            TIMEOUT=300
        e.g. 2,
            vmlist=(vhost_vm1 vhost_vm2 vhost_vm3)
            maclist=(13:45:00:bc:9a:12 13:45:00:bc:9a:13 13:45:00:bc:9a:14)
            iplist=(192.168.1.101 192.168.1.102 192.168.1.103)
            eth1iplist=(192.168.1.101 192.168.1.102 192.168.1.103)
            TIMEOUT=300
        warn: there is none space on both sides of '='
    -i: Kvm's IP

EOF
}

function check_config() {
    config_file=$1

    while read line
    do
        eval $line
    done < $config_file
    
    if [ ! $vmlist ]; then
        echo "invalid vmlist"
        exit 1
    fi
    # echo vmlist=${vmlist[@]}

    if [ ! $maclist ]; then
        echo "invalid maclist"
        exit 1
    fi
    # echo maclist=${maclist[@]}

    if [ ! $iplist ]; then
        echo "invalid iplist"
        exit 1
    fi
    # echo iplist=${iplist[@]}

    if [ ! $eth1iplist ]; then
        echo "invalid eth1iplist"
        exit 1
    fi
    # echo eth1iplist=${eth1iplist[@]}

    if [ ! $TIMEOUT ]; then
        echo "invalid TIMEOUT"
        exit 1
    fi
    # echo TIMEOUT=${TIMEOUT[@]}

}

# Parse arguments
while getopts "c:i:" opt; do
    case $opt in
        c)
            config="$OPTARG"
            ;;
        i)
            ip="$OPTARG"
            ;;
        *)
            usage
            exit 1
            ;;
    esac
done

if [ ! $config ]; then
    echo "config not exists, see usage -c"
    usage
    exit 1
fi

if [ ! $ip ]; then
    echo "kvm's ip not exists, see usage -i"
    usage
    exit 1
fi

check_config $config

cp $config $tools_dir/config
scp -r $tools_dir $ip:/root/
ssh root@$ip "/root/kvm_vhost_hotplug_test.sh.data/kvm_vhost_hotplug_test.sh"