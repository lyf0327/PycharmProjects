#!/bin/bash
#use the script to check mem use
#by liyafeng
memused=$(free -m|awk '/-/ {print $3}')
memtotal=$(free -m|awk '/Mem:/ {print $2}')
lused=$(($memused *100/$memtotal))
if [ $lused -lt 80 ];then
	echo "OK,mem used $lused%"
	exit 0
elif [ $lused -ge 90 ]
then
	echo "Critical,mem used $lused%"
	exit 2
else
	echo "Warning,mem used $lused%"
	exit 1
fi
