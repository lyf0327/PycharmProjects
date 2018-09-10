#!/bin/bash
#try to test the port open or closed
#by liyafeng
message=$(echo $(nmap -p $2 $1)|awk '{print $26}')

if [ "$message"x = "open"x ]
then
        echo "Port State:P$2:$message"
        exit 0
else
        echo "Port State:P$2:$message "
        exit 2
fi

 
