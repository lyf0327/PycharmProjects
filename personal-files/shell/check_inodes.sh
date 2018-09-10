#!/bin/bash
#check inodes situation

        num=$(df -i|awk '$1!="Filesystem" {print $5}'|sort -rn|awk -F'%' 'NR==1 {print $1}')
        if [ $num -le 80 ]
        then
                echo "OK,inodes max_used $num%"
                exit 0
        elif [ $num -gt 90 ]
        then
                echo "Critical,inodes max_used $num%"
                exit 2
        else
                echo "Warning,inodes max_used $num%"
                exit 1
        fi

    

