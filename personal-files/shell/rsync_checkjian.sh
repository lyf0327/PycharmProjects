#!/bin/bash
#Use the script to check the status of the synchronization.
#by liyafeng

filesizesr=$(ssh 54.209.32.250 "du -sb /mnt3/sonatype-work/nexus/storage/$1")
fsizecolumn=$(echo $filesizesr|awk '{print $2}')
if [ "$fsizecolumn"x = "."x ]
then
	echo "the file is not found in 54.209.32.250." && exit
else
	filesize=$(echo $filesizesr|awk '{print $1}')
fi
filedic=/nexus/nexus/sonatype-work/nexus/storage/$1
[ -e $filedic ]
if [ $? -ne 0 ]
then
	echo "the file has not been backup" && exit
else
	filesize1=$(du -sb $filedic|awk '{print $1}')
	if [ $filesize1 -ge $filesize ]
	then
		echo "the file has been backup successed"  && exit
	else
		for ((i=1;i<=10;i++))
		do
			sleep 1
			filesize2=$(du -sb $filedic|awk '{print $1}')
			c=$(($filesize2*100/$filesize))
			if [ $filesize2 -gt $filesize1 ]
			then
				echo "the file is being backup and has been complete $c%"
				break
			fi
		done
		if [ $filesize2 -eq $filesize1 ]
		then
			echo "the file has been backup failed "
		fi
	fi
fi
			

		
		
		
		
		
		
		
		
		
		
		
	
