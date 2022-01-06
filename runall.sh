#!/bin/bash
# 串行启动所有测试脚本
let test_time=12*60*60
day_start=`date "+%s"`

function usage() {
    cat << EOF
Usage: $0 [-t]
    -t: Test time (second), default 12*60*60
EOF
}

function umount_vdb_vdc() {
    mount_point=`df -T | grep vdb | awk '{print $7}'`
    if [ $mount_point ]; then 
        umount $mount_point > /dev/null
    fi
    mount_point=`df -T | grep vdc | awk '{print $7}'`
    if [ $mount_point ]; then 
        umount $mount_point > /dev/null
    fi

    mount_point=`df -T | grep vdb | awk '{print $7}'`
    if [ $mount_point ]; then 
        umount -fl $mount_point > /dev/null
    fi
    mount_point=`df -T | grep vdc | awk '{print $7}'`
    if [ $mount_point ]; then 
        umount -fl $mount_point > /dev/null
    fi

    sleep 1
}

# Parse arguments
while getopts "t:" opt; do
    case $opt in
        t)
            test_time="$OPTARG"
            ;;
        *)
            usage
            exit 1
            ;;
    esac
done

top_dir=$(cd "$(dirname "$0")"; pwd)
avocado_install_path=$top_dir/test_env/avocado/93/avocado_install.sh
chmod +x $avocado_install_path

avocado_version=`avocado --version`
ret=$?
avocado_version=`echo $avocado_version | awk '{print $2}'`
if [[ $ret -ne 0  ||  $avocado_version != '93.0' ]]; then
    $avocado_install_path
fi

function_test_dir=$top_dir/testcases/general_test
stress_test_dir=$top_dir/testcases/stress_test

log_dir=$top_dir/log_${day_start}
mkdir -p $log_dir

summary_log=$log_dir/summary.log

function reserve_and_del()
{
    if [[ ! $1 ]]; then
        return 0
    fi
    _avocado_log_dir=$(cd "$(dirname "$1")"; pwd) 
    cd $_avocado_log_dir && rm -rf avocado.core.DEBUG id jobdata sysinfo results.xml
    
    test_results=`ls $_avocado_log_dir/test-results`
    for r in $test_results
    do
        cd $_avocado_log_dir/test-results/$r && rm -rf data output remote.log stderr stdout sysinfo whiteboard
    done

    cp -r $_avocado_log_dir $log_dir
    cd -
    rm -rf /var/tmp/* /tmp/*
}

echo "------------------------    TEST START    ------------------------"
echo "Now running the stress test..."
stress_test_type=`ls $stress_test_dir`
for type in $stress_test_type
do
   if [[ $type == "net" ]]; then
       echo "Ignore the net stress test..."
       continue
   fi

   mkdir -p $log_dir/stress_test/$type

   test_items=`ls $stress_test_dir/$type`
   for item in $test_items
   do
       if [[ ${item#*.} != "py" && ${item#*.} != "sh" ]]; then
           continue
       fi
       umount_vdb_vdc
       echo "Stress test is running: "$stress_test_dir/$type/$item
       chmod +x $stress_test_dir/$type/$item
       $stress_test_dir/$type/$item -t $test_time > $log_dir/stress_test/$type/$item".log" 2>&1
       if [[ $? != 0 ]]; then
           echo "FAIL: stress_test/$type/$item" >> $summary_log 2>&1
       else
           echo "PASS: stress_test/$type/$item" >> $summary_log 2>&1
       fi
   done
done

echo "Now running the avocado test test..."
function_test_type=`ls $function_test_dir`
for type in $function_test_type
do
    mkdir -p $log_dir/general_test/$type

    test_items=`ls $function_test_dir/$type`
    for item in $test_items
    do
        if [[ ${item#*.} != "py" && ${item#*.} != "sh" ]]; then
            continue
        fi

        umount_vdb_vdc
        echo "Avocado stress test is running: "$function_test_dir/$type/$item
        chmod +x $function_test_dir/$type/$item

        if [ -f $function_test_dir/$type/$item.data/${item%%.*}.yaml ]; then
            m=$function_test_dir/$type/$item.data/${item%%.*}.yaml
            avocado run -m $m --test-runner=runner -- $function_test_dir/$type/$item > $log_dir/general_test/$type/$item".log" 2>&1
        else
            avocado run --test-runner=runner -- $function_test_dir/$type/$item > $log_dir/general_test/$type/$item".log" 2>&1
        fi        
        job_log=`cat $log_dir/general_test/$type/$item".log" | grep "JOB LOG" | awk '{print $4}'`
        ERROR=`cat $log_dir/general_test/$type/$item".log" | grep RESULTS | awk '{print $7}'`
        FAIL=`cat $log_dir/general_test/$type/$item".log" | grep RESULTS | awk '{print $10}'`

        if [[ $job_log == "" || $ERROR == "" || $FAIL == "" ]]; then
            reserve_and_del $job_log
            echo "SKIP: general_test/$type/$item" >> $summary_log 
            continue
        fi

        if [[ $ERROR -gt 0 ]]; then
            echo "ERROR: general_test/$type/$item" >> $summary_log 
            reserve_and_del $job_log
        elif [[ $FAIL -gt 0 ]]; then
            echo "FAIL: general_test/$type/$item" >> $summary_log 
            reserve_and_del $job_log
        else
            echo "PASS: general_test/$type/$item" >> $summary_log 
            avocado_log_dir=`dirname $job_log`
            rm -rf $avocado_log_dir
        fi

    done
done

echo "------------------------    TEST FINISH    ------------------------"
cat $summary_log
