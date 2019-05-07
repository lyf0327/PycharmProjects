#!/usr/bin/env bash
num=$1
for i in {1..${num}}
do
    Pod=`systemctl status kubelet -l|grep "Orphaned pod"|awk -F\" '{print $2}'|uniq`
    for j in ${Pod}
    do
        rm -rf  /var/lib/kubelet/pods/$j
    done
    sleep 5
done