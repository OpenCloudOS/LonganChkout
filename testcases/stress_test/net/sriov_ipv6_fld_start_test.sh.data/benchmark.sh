#!/bin/bash

tmp_file=tmp.log

#benchmark data
let bm_cpu_avg_min=50
let bm_cpu_avg_max=80
let bm_mem_free=6000
let bm_rx_pck=500000
let bm_tx_pck=200000
let bm_rx_Mb=2000
let bm_tx_Mb=1800

#real data
let cpu_avg=0
let mem_free=0
let rx_pck=0
let tx_pci=0
let rx_Mb=0
let tx_Mb=0

function dmesg_check()
{
	echo -e "\n@@@@@@@@@@@@@@ dmesg check start @@@@@@@@@@@@@@@@"
	dmesg |grep -Ei "error | bug | warning"
	echo -e "\n\n"
	dmesg -c
	echo -e "@@@@@@@@@@@@@@ dmesg check end @@@@@@@@@@@@@@@@\n"
}

function get_cpu()
{
	top -b -n 1 |grep fld |sort -k 9 -n -r |head -3 > $tmp_file
	echo -e "\ntop:"
	cat $tmp_file
	cpus=`cat $tmp_file |awk '{print $9}' `
	let total=0
	for i in $cpus
	do
		cpu=${i%.*}
		let total+=$cpu
	done
	let cpu_avg=$total/3
}

function get_mem_free()
{
	free -m > $tmp_file
	echo -e "\nfree -m:"
	cat $tmp_file
	free=`cat $tmp_file |sed -n '2p' | awk '{print $4}'`
	let mem_free=$free
}

function get_net()
{
	sar -n DEV 5 2 > $tmp_file
	echo -e "\nsar -n DEV 5 2:"
	cat $tmp_file
	avg=`cat $tmp_file | tail -4 | grep eth1`
	rx_pck=`echo $avg |awk '{print $3}' `
	rx_pck=${rx_pck%.*}
	tx_pck=`echo $avg |awk '{print $4}' `
	tx_pck=${tx_pck%.*}
	rx_KB=`echo $avg |awk '{print $5}' `
	rx_KB=${rx_KB%.*}
	let rx_Kb=$rx_KB*8
	let rx_Mb=$rx_Kb/1000
	tx_KB=`echo $avg |awk '{print $6}' `
	tx_KB=${tx_KB%.*}
	let tx_Kb=$tx_KB*8
	let tx_Mb=$tx_Kb/1000
}

function print_summary()
{
	echo -e "\n************** summary start *************"
	echo cpu_avg $cpu_avg
	echo mem_free $mem_free
	echo rx_pck $rx_pck
	echo tx_pck $tx_pck
	echo rx_Mb $rx_Mb
	echo tx_Mb $tx_Mb
	echo -e "************** summary end *************\n"
}

function bm_check()
{
	ret=0

	echo -e "\n############## Benchmark check start #####################"
	if [[ $cpu_avg -gt $bm_cpu_avg_max ]] || [[ $cpu_avg -lt $bm_cpu_avg_min ]]; then
		echo ATTENTION!!! cpu_avg $cpu_avg expect [$bm_cpu_avg_min $bm_cpu_avg_max]
		ret=1
	fi

	if [[ $mem_free -lt $bm_mem_free ]]; then
		echo ATTENTION!!! mem_free $mem_free expect $bm_mem_free
		ret=1
	fi

	if [[ $rx_pck -lt $bm_rx_pck ]]; then
		echo ATTENTION!!! rx_pck $rx_pck expect $bm_rx_pck
		ret=1
	fi

	if [[ $tx_pck -lt $bm_tx_pck ]]; then
		echo ATTENTION!!! tx_pck $tx_pck expect $bm_tx_pck
		ret=1
	fi

	if [[ $rx_Mb -lt $bm_rx_Mb ]]; then
		echo ATTENTION!!! rx_Mb $rx_Mb expect $bm_rx_Mb
		ret=1
	fi

	if [[ $tx_Mb -lt $bm_tx_Mb ]]; then
		echo ATTENTION!!! tx_Mb $tx_Mb expect $bm_tx_Mb
		ret=1
	fi
	echo -e "############## Benchmark check end #####################\n"

	return $ret
}

dmesg_check
echo -e "\n%%%%%%%%%%% get raw data start%%%%%%%%%%%%%"
get_cpu
get_mem_free
get_net
echo -e "\n%%%%%%%%%%% get raw data end%%%%%%%%%%%%%\n"
print_summary
bm_check
exit $?

