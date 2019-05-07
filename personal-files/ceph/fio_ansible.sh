#!/usr/bin/env bash
for i in randread randwrite
do
    for j in 4k 8k 16k 32k 64k 128k 1M 10M
    do
        ansible fio-nodes -m command -a 'rm -rf /lyf/ceph_test'
        ansible fio-nodes -m shell -a "fio -filename=/lyf/ceph_test -direct=1 -ioengine=sync -iodepth 1 -thread -rw=$i -bs=$j -size=10G -numjobs=10 -runtime=60 -group_reporting -name=mytest >$i-$j.txt"
    done
done


for i in 109.105.1.253 109.105.1.246 109.105.1.176 109.105.1.232
do
        mkdir $i &>/dev/null
        scp $i:~/rand* $i/
done