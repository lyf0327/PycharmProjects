#!/bin/bash
#use the file to synchronise individual files
#by liyafeng
for file in $(cat file.txt)
do
        udr -d 150 rsync -avzPR $file root@54.222.192.109:/nexus/nexus/sonatype-work/nexus/storage/
done

