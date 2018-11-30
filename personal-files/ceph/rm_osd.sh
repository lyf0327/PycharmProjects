#!/usr/bin/env bash
help(){
    echo "Usage: rm_osd.sh num/osd.num num/osd.num --yes-i-really-really-mean-it"
}

#if [ "$1" == "" ] || [ "$1" == "-h" ] || [ "$1" == "--help" ]
#then
#    help
#fi

if [ "$1" == "$2" ] && [ "$3" == "--yes-i-really-really-mean-it" ]
then
    OSD=$1
    i=${OSD##*.}
    ceph osd crush remove osd.$i
    ceph osd out osd.$i
    ceph osd rm osd.$i
    ceph auth del osd.$i
else
    help
fi