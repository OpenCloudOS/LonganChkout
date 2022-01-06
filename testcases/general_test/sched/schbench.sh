#! /bin/bash

self_dir=$(cd "$(dirname "$0")"; pwd)
script=$(basename "$0")
data_dir=$self_dir/${script}.data/

schbench=$data_dir/schbench

$schbench -m 64 -t 256 -a
$schbench -m 64 -t 256 -p -R -a

exit 0
