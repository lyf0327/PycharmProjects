#!/bin/bash
for i in randread randwrite
do
    for j in 16k 32k 64k 128k 1M 10M
    do
        fio -filename=/lyf/ceph_test -direct=1 -ioengine=sync -iodepth 1 -thread -rw=$i -bs=$j -size=10G -numjobs=10 -runtime=60 -group_reporting -name=mytest >$i-10g-$j.txt
    done
done
