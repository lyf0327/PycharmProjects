#!/usr/bin/env bash
while :
do
    DIR='./hh'
    NUM=$(($(ls -lrt $DIR |wc -l)-1))
    if [ $NUM -gt 5 ]
    then
        FILE=`ls -lrt $DIR|awk 'NR==2 {print $NF}'`
        rm -rf $DIR/$FILE
    fi
done
