#!/bin/bash
# 在docker中反复挂载、卸载ext4文件系统，持续时间由test_time控制，默认12小时

let test_time=12*60*60

function usage() {
    cat << EOF
Usage: $0 [-t]
    -t: Test time (seconds), 12*60*60 default
EOF
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

date_start=`date "+%s"`
date_end=$((date_start+test_time))

entry=$(cd `dirname $0`;pwd)  #脚本所在目录
tools_dir=$entry/io_integration_test.sh.data/

entry=`dirname $0`
cd $entry
mkdir -p /data/docker-image /data/xfstests-dev
cp -r $tools_dir/ltp /data/xfstests-dev/
cp -r $tools_dir/tlinux-64bit-v2.4.20200929.tar /data/docker-image
cp -r $tools_dir/function-test.sh /data
chmod +x -R /data/function-test.sh /data/xfstests-dev/ltp

cd /data/
systemctl stop docker  > /dev/null

function exit_cmd() 
{
        exit_code=$1
        exit_info=$2
        umount -fl /tmp/ext4

        systemctl restart docker  > /dev/null
        if [ $? -ne 0 ]; then
                echo "systemctl restart docker error"
        fi

        echo $exit_info
        exit $exit_code
}

mountp=`df -h | grep /dev/vdb | awk '{print $6}'`
if mountpoint $mountp && ! umount -fl $mountp
then
	exit_cmd 1 "unable to unmount"
fi
mkfs.ext4 /dev/vdb  > /dev/null
rm -rf /tmp/ext4
mkdir -p /tmp/ext4
mount /dev/vdb /tmp/ext4  > /dev/null
if [[ ! -f /etc/sysconfig/docker ]]; then
        echo "Not Found /etc/sysconfig/docker"
elif ! grep -q "ext4" /etc/sysconfig/docker ; then
        sed -i 's/verification=false/verification=false -g \/tmp\/ext4/' /etc/sysconfig/docker
fi
systemctl restart docker  > /dev/null
docker load -i /data/docker-image/tlinux-64bit-v2.4.20200929.tar  > /dev/null

image_id=506a431b032d # 54d401b4ad77

#test the overlayfs+ext4 environment(different memory)
declare -a docker_run_cmds=(                                    \
        "docker run -d --net=none $image_id /sbin/init"         \
        "docker run -d --net=none --memory=800m --memory-swap=1g $image_id /sbin/init" \
        "docker run -d --net=none --memory=300m --memory-swap=1g $image_id /sbin/init" \
        "docker run -d --net=none --memory=100m --memory-swap=500m $image_id /sbin/init" \
        "docker run -d --net=none --memory=1g --memory-swap=2g $image_id /sbin/init" \
        "docker run -d --net=none --memory-swappiness=0 $image_id /sbin/init" \
        "docker run -d --net=none --memory=800m --memory-swap=1g --memory-swappiness=0 $image_id /sbin/init" \
        "docker run -d --net=none --memory=300m --memory-swap=1g --memory-swappiness=0 $image_id /sbin/init" \
        "docker run -d --net=none --memory=100m --memory-swap=500m --memory-swappiness=0 $image_id /sbin/init" \
        "docker run -d --net=none --memory=1g --memory-swap=2g --memory-swappiness=0 $image_id /sbin/init" \
)

while true
do
        for cmd in "${docker_run_cmds[@]}"
        do
                echo $cmd
                docker_name=`eval $cmd`
                docker_name=${docker_name:0:12}
                echo "$docker_name"
                docker cp /data/xfstests-dev/ltp $docker_name:/data/
                docker cp /data/function-test.sh $docker_name:/data/
                docker exec $docker_name /data/function-test.sh  > /dev/null
                sleep 1
                docker stop $docker_name  > /tmp/docker_stop.log
                if [ $? -ne 0 ]; then
                        echo $? >> /tmp/docker_stop.log
                        cat /tmp/docker_stop.log
                        exit_cmd 1 "docker stop failed"
                fi
                sleep 2
                docker rm $docker_name  > /tmp/docker_rm.log
                if [ $? -ne 0 ]; then
                        echo $? >> /tmp/docker_rm.log
                        cat /tmp/docker_rm.log
                        exit_cmd 1 "docker rm failed"
                fi
                sleep 1
                umount -l /tmp/ext4  > /tmp/umount_ext4.log
                if [ $? -ne 0 ]; then
                        echo $? >> /tmp/umount_ext4.log
                        cat /tmp/umount_ext4.log
                        fuser -mv /tmp/ext4
                        exit_cmd 1 "umount ext4 failed"
                fi
                fsck.ext4 -f -n /dev/vdb  > /tmp/fsck_ext4.log
                if [ $? -ne 0 ]; then
                        echo $? >> /tmp/fsck_ext4.log
                        cat /tmp/fsck_ext4.log
                        exit_cmd 1 "fsck.ext4 find error"
                fi
                mount /dev/vdb /tmp/ext4  > /dev/null
        done

        date_now=`date "+%s"`
        if [ $date_now -gt $date_end ]; then
                exit_cmd 0 "docker ext4 test done, exit now...."
        fi
done


