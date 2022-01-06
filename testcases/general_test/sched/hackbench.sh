#! /bin/bash

self_dir=$(cd "$(dirname "$0")"; pwd)
script=$(basename "$0")
data_dir=$self_dir/${script}.data/

hackbench=$data_dir/hackbench

ulimit -HSn 102400

$hackbench 100 process 100
$hackbench 100 thread 100
$hackbench -pipe 100 process 100
$hackbench -pipe 100 thread 100

exit 0


