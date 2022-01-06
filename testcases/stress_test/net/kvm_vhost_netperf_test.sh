#!/bin/bash

cases_dir=`dirname $0`
tools_dir=$cases_dir/$0.data/

function usage() {
    cat << EOF

Usage: $0 [-c] [-i]
    -c: Config of kvm, absolute path is necessary, with a template as below,
            vmlist=()
            maclist=()
            iplist=()
            pwdlist=()
            eth1iplist=()
            TIMEOUT=
        e.g., 
            vmlist=(kvm_1_name kvm_2_name kvm_3_name)
            maclist=(mac_1_addr mac_2_addr mac_3_addr)
            iplist=(ip_1_addr ip_2_addr ip_3_addr)
            pwdlist=(ip_1_pwd ip_2_pwd ip_3_pwd)
            eth1iplist=(eth1_1_ipaddr eth1_2_ipaddr eth1_3_ipaddr)
            TIMEOUT=300
        e.g. 2,
            vmlist=(vhost_vm1 vhost_vm2 vhost_vm3)
            maclist=(13:45:00:bc:9a:12 13:45:00:bc:9a:13 13:45:00:bc:9a:14)
            iplist=(192.168.1.101 192.168.1.102 192.168.1.103)
            pwdlist=(pwd pwd pwd)
            eth1iplist=(192.168.1.101 192.168.1.102 192.168.1.103)
            TIMEOUT=300
        warn: there is none space on both sides of '='
    -i: Machine to execute the test.  

    The first ip in vmlist will be the server, and the rest will be clients.
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

    if [ ! $pwdlist ]; then
        echo "invalid pwdlist"
        exit 1
    fi
    # echo pwdlist=${pwdlist[@]}

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
            execute="$OPTARG"
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

if [ ! $execute ]; then
    echo "execute machine not exists, see usage -i"
    usage
    exit 1
fi

check_config $config

cp $config $tools_dir/config
scp -r $tools_dir $execute:/root/
ssh root@$execute "/root/kvm_vhost_netperf_test.sh.data/kvm_vhost_netperf_test.sh"