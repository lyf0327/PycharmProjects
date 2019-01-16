#!/usr/bin/env bash
src=$1
dest=$2
port=$3
help(){
    echo "Usage: rsync_to_sgi.sh  <src_dir> <dest_dir> <port>"
    echo "for example:"
    echo "          sh rsync_to_sgi.sh /home/xiaoming /data/ 22435"
}

Rsync(){
    rsync -avzPR --stats -e "ssh -i ~/.ssh/mykey.pri -p ${port}" ${INO_FILE} root@sgissh.samsungcloud.org:${dest}
}
if [ "$1" = "" ]
then
    help
else
    if [[ -f ~/.ssh/mykey.pri ]]
    then
        chmod 644 ~/.ssh/mykey.pri
        cd ${src} &>/dev/null
        if [ $? -eq 0 ]
        then
            [ -e /tmp/fd1 ] || mkfifo /tmp/fd1
            exec 3<>/tmp/fd1
            rm -rf /tmp/fd1
            for ((i=1;i<=3;i++))
            do
              echo >&3
            done
            for INO_FILE in $(ls $src)
            do
                read -u3
                {
                    Rsync
                    echo >&3
                } &
            done
        else
            Rsync
        fi
    else
        echo "please save you private key to the file ~/.ssh/mykey.pri"
    fi
fi

