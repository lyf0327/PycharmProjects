#!/bin/bash
src=/mnt3/sonatype-work/nexus/storage/dcog/
des=/nexus/nexus/sonatype-work/nexus/storage/dcog
usr=root
ip1=54.222.192.109
ip2=
cd ${src}
#/usr/bin/inotifywait -mrq --format  '%Xe %w%f' -e modify,create,delete,attrib,close_write,move ./ | while read file 
/usr/bin/inotifywait -mrq --format  '%Xe %w%f' -e close_write,move ./ | while read file
do
        INO_EVENT=$(echo $file | awk '{print $1}')
        INO_FILE=$(echo $file | awk '{print $2}')
        INO_FILE1=$(echo $INO_FILE |cut -b 2-)
        echo "-------------------------------$(date)------------------------------------"
        echo $file
#       if [[ $INO_EVENT =~ 'CREATE' ]] || [[ $INO_EVENT =~ 'MODIFY' ]] || [[ $INO_EVENT =~ 'CLOSE_WRITE' ]] || [[ $INO_EVENT =~ 'MOVED_TO' ]]
        if [[ $INO_EVENT =~ 'MOVED_TO' ]]
        then
                echo 'MOVED_TO'
                echo ${usr}@${ip1}:${des}${INO_FILE1}
                udr -d 150 rsync -avzPR --stats  ${INO_FILE} ${usr}@${ip1}:${des}
#               if [[ $? != 0 ]]
#               then
#                       udr -d 150 rsync -avzR --stats --progress ${INO_FILE} ${usr}@${ip1}:${des}
#               fi
        fi
        if [[ $INO_EVENT =~ 'CLOSE_WRITE' ]]
        then
                echo 'CLOSE_WRITE'
                echo ${INO_FILE}
        fi
done

