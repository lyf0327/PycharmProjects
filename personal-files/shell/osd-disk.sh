#!/usr/bin/env bash
help(){
        echo "Usage: osd-disk.sh <num1> <num2> <num3> ..."
}
if [[ "$1" == "" ]]
then
        help
fi
for i in $*
do
    LV_ID=$(cat /var/lib/ceph/osd/ceph-$i/fsid)
    VG_ID=$(lvs|grep $LV_ID|awk '{print $2}')
    PV_ID=$(pvs|grep $VG_ID|awk '{print $1}')
    echo "osd.$i ===> $PV_ID"
done
