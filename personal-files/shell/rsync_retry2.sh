#!/bin/bash
#Use the script to check the status of the synchronization。
#by liyafeng

filesizesr=$(ssh 54.209.32.250 "locate -n2 /mnt3/sonatype-work/nexus/storage/*$1|grep -v attributes|xargs du -sb")
fsizecolumn=$(echo $filesizesr|awk '{print $2}')
if [ "$fsizecolumn"x = "."x ]
then
        filesizesr=$(ssh 54.209.32.250 "updatedb && locate -n2 /mnt3/sonatype-work/nexus/storage/*$1|grep -v attributes|xargs du -sb")
        fsizecolumn=$(echo $filesizesr|awk '{print $2}')
        if [ "$fsizecolumn"x = "."x ]
        then
                echo "$1 is not found in 54.209.32.250." && exit
        else
                filesize=$(echo $filesizesr|awk '{print $1}')
                filedir=$(echo $fsizecolumn|sed -r 's/(\/mnt3\/sonatype-work\/nexus\/storage\/)(.*)/\2/')
        fi
else
        filesize=$(echo $filesizesr|awk '{print $1}')
        filedir=$(echo $fsizecolumn|sed -r 's/(\/mnt3\/sonatype-work\/nexus\/storage\/)(.*)/\2/')
fi

filedic=$(locate -n2 /nexus/nexus/sonatype-work/nexus/storage/*$1|grep -v attributes|sed -n '1p')
if [ "$filedic" = "" ]
then
        updatedb
        filedic=$(locate -n2 /nexus/nexus/sonatype-work/nexus/storage/*$1|grep -v attributes|sed -n '1p')
        if [ "$filedic" = "" ]
        then
                echo "$1 has not been backup" && ssh 54.209.32.250 "cd /mnt3/sonatype-work/nexus/storage/ && udr -d 150 rsync -avzRP $filedir root@54.222.192.109:/nexus/nexus/sonatype-work/nexus/storage/" && echo "$1 has been backup again and successed" &&exit
        else
                filesize1=$(du -sb $filedic|awk '{print $1}')
                filedic2=$(echo $filedic|sed -r 's/(.*)\/.*/\1/')
        fi
else
        filesize1=$(du -sb $filedic|awk '{print $1}')
        filedic2=$(echo $filedic|sed -r 's/(.*)\/.*/\1/')
fi

filedic3=$(echo $1|awk -F'/' '{print $NF}')
cd $filedic2
[ -e $filedic3 ]        
if [ $? -ne 0 ]
then
        echo "$1 has not been backup" ssh 54.209.32.250 "cd /mnt3/sonatype-work/nexus/storage/ && udr -d 150 rsync -avzRP $filedir root@54.222.192.109:/nexus/nexus/sonatype-work/nexus/storage/" && echo "$1 has been backup again and successed" && exit 
else
        if [ $filesize1 -ge $filesize ]
        then
                echo "$filedic has been backup successed"
        else
                for ((i=1;i<=5;i++))
                do
                        sleep 1
                        filesize2=$(du -sb $filedic|awk '{print $1}')
                        c=$(($filesize2*100/$filesize))
                        if [ $filesize2 -gt $filesize1 ]
                        then
                                echo "$filedic is being backup and has been complete $c%"
                                break
                        fi
                done
                if [ $filesize2 -eq $filesize1 ]
                then
                        echo "$filedic has been backup failed " && ssh 54.209.32.250 "cd /mnt3/sonatype-work/nexus/storage/ && udr -d 150 rsync -avzRP $filedir root@54.222.192.109:/nexus/nexus/sonatype-work/nexus/storage/" && echo "$filedic has been backup again and successed"
                fi
        fi
fi
    

