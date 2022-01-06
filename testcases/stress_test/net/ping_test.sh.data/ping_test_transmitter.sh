#!/bin/bash

WORKSPACE=$(cd `dirname $0`;pwd)

source $WORKSPACE/config

ping_test()
{
        exist=0
        err=0

        for ((i=0;i<${#vmlist[@]};i++)); do
		ping -c 1 ${eth1iplist[i]} >/dev/null		
                if [ $? != 0 ]; then
			echo "ping ${eth1iplist[i]} failed"
                        exit 1
		else
			echo "ping ${eth1iplist[i]} success"
                fi
        done
}
ping_test
