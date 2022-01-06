#!/bin/bash
self_dir=$(cd "$(dirname "$0")"; pwd)
script=$(basename "$0")
data_dir=$self_dir/${script}.data/

declare cpupercent;

function autotest_save()
{
	cpupercent=`cat /proc/offline/cpu$1`	
}

function autotest_restore()
{
	echo $cpupercent > /proc/offline/cpu$1
}

function string_input_test()
{

	for((k=0;k<10;k++))
	do
		str=`cat /dev/urandom | head -n 10 | md5sum | head -c $2`
		echo $str > /proc/offline/cpu$1  2>&1
	done
	
	return 0

}

function cmdline_check()
{
        cat /proc/cmdline  |grep offline_class > /dev/null 2>&1
        class=$?

        cat /proc/cmdline  |grep offline_group > /dev/null 2>&1
        group=$?

        if [ $class == 0 -a $group == 0 ];# offline_group offline_class
        then
                return 2
        elif [ $class == 0 -a $group == 1 ];# offline_class only
        then
                return 1
        else                            #  offline_group # or No start parameters  
                return 0
        fi
}

function inter_input_test()
{
        for((i=$2;i<=$3;i++))
        do
                echo $i > /proc/offline/cpu$1  2>&1
                if [ $? -ne $4 ]
                then
                        return 1
                fi
                num=`cat /proc/offline/cpu$1`
                if [ $5 -eq 0 -a $num -ne $i ]
                then
                        return 1
                fi
        done

        return 0

}

function autotest_onetest()
{
	#test [0 100]
	inter_input_test $1 0 100 0 0 
	if [ $? == 1 ]
	then
		return 1
	fi

	#test [-1000,0)	
	inter_input_test $1 -1000 -1 1 1 
	if [ $? == 1 ]
	then
		return 1
	fi

	inter_input_test $1 101 1000 1 1 
	if [ $? == 1 ]
	then
		return 1
	fi

	for((i=1;i<=3;i++))
	do
		string_input_test $1 $i
	done

	return 0
}

function autotest_type_two_cmd_para()
{
	cpunum=`cat /proc/cpuinfo |grep "processor"|wc -l`

        for((j=0;j<$cpunum;j++))
        do
                autotest_save $j
                autotest_onetest $j
                ret=$?
                autotest_restore $j

                if [ $ret == 1 ]
                then
                        return 1
                fi
        done
        return 0
}

function autotest_type_class_cmd_para()
{
	return 0
}

function autotest_type_no_cmd_para()
{
	return 0
}

function autotest_test()
{

	cmdline_check
        type=$?

        case $type in
                2)
                        autotest_type_two_cmd_para
                        return $?
                ;;
                1)
                        autotest_type_class_cmd_para
                        return $?
                ;;
                0)
                        autotest_type_no_cmd_para
                        return $?
                ;;
        esac
	
}


function main()
{
	
	autotest_test

	if [ $? == 0 ]
	then 
		printf "succeed\n" 
		exit 0
	else
		printf "failed\n"  
		exit 1
	fi

}

main

