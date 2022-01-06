#!/bin/bash

mkdir /data/fsstress
/data/ltp/fsstress -n 100 -p 50 -v \
				-d /data/fsstress
rm -fr /data/fsstress
