#!/bin/bash
src=/nexus/nexus/sonatype-work/nexus/storage/dcog
cd $src
/usr/bin/inotifywait -mrq --format  '%Xe %w%f' -e move ./ | while read file
do
        INO_EVENT=$(echo $file | awk '{print $1}')
        if [[ $INO_EVENT =~ 'MOVED_TO' ]]
        then
                echo "$(echo $file|awk '{print $2}')-$(date +%F-%T)" >> /root/time.txt
#               echo $file-$(date +%F-%T) >> /root/time.txt
        fi
done

