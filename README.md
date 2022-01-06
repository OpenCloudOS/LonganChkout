# tlinux-autotest-offline
tlinux-autotest-offline项目用于内核离线压力测试。

# 原理
本项目基于avocado框架（[https://github.com/avocado-framework/avocado](https://github.com/avocado-framework/avocado)），配套使用avocado测试套件（[https://github.com/avocado-framework-tests/avocado-misc-tests](https://github.com/avocado-framework-tests/avocado-misc-tests)），对内核调度、内存、IO等子系统进行压测。

**快速开始**

```bash
$ cd tlinux_autotest_offline
$ chmod +x runall.sh
$ ./runall.sh -t 60
```

测试分为avocado测试套件以及独立测试，后者可以脱离avocado框架独立运行。目前，前者无法控制测试总时长，后者可以通过加`-t`参数来控制。使用runall脚本串行跑所有测试时，同样通过`-t`参数控制独立测试的时长。

summary输出测试结果PASS、FAIL、SKIP。

如果希望有更详细的log或测试报告，可以使用avocado框架。avocado框架运行测试支持输出多样式测试报告，比如html、json、tap、xml等。

# 环境配置
## avocado框架安装
跑测试用例需要用到avocado框架。本项目使用的avocado框架为93.0。
python版本：3.6
```bash
chmod +x tlinux_autotest_offline/test_env/avocado/93/avocado_install.sh
./tlinux_autotest_offline/test_env/avocado/93/avocado_install.sh
```

## docker服务
测试需要运行docker服务。
### 安装docker
安装docker软件包
```bash
# TencentOS Server 2 安装docker-ce
yum install tlinux-release-docker-ce  && yum install docker-ce
# TencentOS Server 3 安装docker-ce
yum install tencentos-release-docker-ce  && yum install docker-ce
```
运行docker服务
```bash
systemctl start docker
```
使用下面的命令确认docker服务已经启动没有报错
```bash
docker -v
# 或者
docker ps
```
## 数据盘vdb、vdc
机器需要有数据盘vdb、vdc，io读写磁盘测试可能会破坏该盘上的数据。
系统盘vda建议50G以上，数据盘建议各40G以上。

## 文件系统ext4、xfs
内核版本需要支持挂载ext4、xfs文件系统。

# 测试说明

## 测试模式
### 所有测试
这种模式下，请使用`runall.sh`，接受参数t，将指定`stress_test`中所有测试的运行时长，如果不指定，将使用每个测试各自的默认测试时长。此参数不影响`general_test`中的测试。
### 单个测试
使用时请先注意时长，在脚本中固定写死，一般为`test_time`。

## 测试用例说明
测试用例都在文件夹testcases中。按是否基于avocado运行框架分为两部分：
- general_test: avocado框架测试套件。需要基于avocado框架运行。
- stress_test: 独立测试。可以不基于avocado框架运行。

### general_test
- bench：常见benchmark测试。
    - filebench
    - hackbench
    - tbench
    - unixbench
- fs：文件系统测试。
    - xfstest
- io：磁盘io测试。
    - fiotest
- misc：混合测试。
    - ltp
- perf：性能统计测试。
    - perf_basic
    - perf_invalid_flag_test
    - perf_pcp
    - perf_uprobe
- sched：调度测试。
    - cgroup_offline_inheritance_test
    - cgroup_offline_press
    - hackbench
    - offline_cgroup_test
    - proc_offline_illegal_value_test
    - root_task_group_test
    - schbench
    - set_root_task_group
    - task_offline_inheritance_test
    
### stress_test
- io_integration_test：io压测。docker里反复挂载、卸载文件系统，默认持续时间12小时。
    - test_docker_ext4：ext4文件系统。
    - test_docker_xfs：xfs文件系统。
- net：网络压测。
    - docker_performance_test：docker里跑netperf的不同模式，设定baseline，如果没有达到会在日志中输出哪项没有达到预期。
    - kvm_vhost_hotplug_test：kvm子机里进行热插拔测试。
    - kvm_vhost_hotunplug_test：kvm子机里进行热插拔测试。
    - kvm_vhost_netperf_test：kvm子机间跑netperf的不同模式，设定baseline，如果没有达到会在日志中输出哪项没有达到预期。
    - ping_test：kvm子机是否能ping通。
    - sriov_fld_start_test：ipv4打流测试，从Transmitter往Receiver发送流量，需要Receiver有两张网卡。
    - sriov_ipv6_fld_start_test：ipv6打流测试，从Transmitter往Receiver发送流量，需要Receiver有两张网卡、ipv6地址。
- sched_stress_test：调度、内存相关压测。
    - oom_test：内存压测。限制cgroup内存使用，不断申请内存。
    - stress_test：调度压测。测试bt调度算法及cfs调度算法，如果不支持bt调度，测试也不会失败。

**net网络压测特别说明**

可以使用net文件夹下提供的sshpass-1.06-2.tl2.x86_64.rpm，离线安装sshpass
```bash
rpm -Uvh --force --nodeps sshpass-1.06-2.tl2.x86_64.rpm
```
或者在配置好yum源后在线安装
```bash
yum install -y sshpass
```
使用时需要修改测试用例，给出通信双方机器。

## 测试用例运行说明
每个测试用例的起名类似以下规则：
```bash
dirname
    test.sh.data/
        xxx
    test.sh
```
或者
```bash
dirname
    test.py.data/
        xxx
    test.py
```
其中`test.sh`与`test.py`为主要的测试启动脚本。请在运行前确保脚本是可执行的，否则
```bash
chmod +x test.sh
chmod +x test.py
```

- general_test
```bash
avocado run path/xxx.sh
```

- stress_test
```bash
./path/xxx.sh -param1 xx -param2 xx
```

## 测试机器说明
以stress_test为例，可以运行测试的机器参数为：
- io_integration_test：
    - test_docker_ext4：CPU-2 Memory-230M; CPU-4 Memory-480M; CPU-4 Memory-860M; CPU-4 Memory-2.8G; CPU-4 Memory-4.7G
    - test_docker_xfs：CPU-2 Memory-230M; CPU-4 Memory-480M; CPU-4 Memory-860M; CPU-4 Memory-2.8G; CPU-4 Memory-4.7G
- net：
    - docker_performance_test：CPU-4 Memory-8G
    - kvm_vhost_hotplug_test：CPU-4 Memory-1.5G
    - kvm_vhost_hotunplug_test：CPU-4 Memory-1.5G
    - kvm_vhost_netperf_test：CPU-4 Memory-1.5G
    - ping_test：CPU-4 Memory-1.5G
    - sriov_fld_start_test：CPU-2 Memory-8G
    - sriov_ipv6_fld_start_test：CPU-2 Memory-8G
- sched_stress_test：
    - oom_test：CPU-2 Memory-512M
    - stress_test：CPU-2 Memory-512M

## 测试输出样例
每个测试下可能会有一个以result.txt或者result.log结尾的文件。此文件不参与测试，仅作为测试输出样例。
注意：测试时长请以脚本里写的为主。测试输出样例只是**样例**。

## 测试说明
要重复使用测试工具进行测试，请重启机器再进行测试，并确保/dev/vdb和/dev/vdc盘未挂载，且为正常可挂载状态。