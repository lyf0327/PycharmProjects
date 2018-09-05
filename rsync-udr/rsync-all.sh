#!/bin/bash
src=/opt/nysa/downloads
des=/rsync-s3
usr=root
ip1=52.82.42.11
ip2=
cd ${src}
[ -e /tmp/fd1 ] || mkfifo /tmp/fd1
exec 3<>/tmp/fd1
rm -rf /tmp/fd1
for ((i=1;i<=3;i++))
do
      echo >&3
done

#/usr/bin/inotifywait -mrq --format  '%Xe %w%f' -e modify,create,delete,attrib,close_write,move ./ | while read file
/usr/bin/inotifywait -mrq --format  '%Xe %w%f' -e close_write ./ | while read file
do
        read -u3
        {
        INO_EVENT=$(echo $file | awk '{print $1}')
        INO_FILE=$(echo $file | awk '{print $2}')
        INO_FILE1=$(echo $INO_FILE |cut -b 2-)
        echo "-------------------------------$(date)------------------------------------">>/var/log/rsync-udr
        echo $file
#        if [[ $INO_EVENT =~ 'CREATE' ]] || [[ $INO_EVENT =~ 'MODIFY' ]] || [[ $INO_EVENT =~ 'CLOSE_WRITE' ]] || [[ $INO_EVENT =~ 'MOVED_TO' ]]
        if [[ $INO_EVENT =~ 'CLOSE_WRITE' ]]
        then
                echo "${INO_EVENT}">>/var/log/rsync-udr
                echo ${usr}@${ip1}:${des}${INO_FILE1}>>/var/log/rsync-udr
                udr -d 150 rsync -avzPR --stats  ${INO_FILE} ${usr}@${ip1}:${des} &>>/var/log/rsync-udr

#               if [[ $? != 0 ]]
#               then
#                       udr -d 150 rsync -avzR --stats --progress ${INO_FILE} ${usr}@${ip1}:${des}
#               fi
        fi
        echo >&3
        }&
done
