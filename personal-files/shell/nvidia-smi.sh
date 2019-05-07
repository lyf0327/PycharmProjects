#!/usr/bin/env bash
unset http_proxy
unset HTTP_PROXY
[[ ! -f /usr/bin/nvidia-smi ]] && echo "nothing" &&exit 1
/usr/bin/nvidia-smi|sed -n 'N;$d;P;D'>./.abc.txt
/usr/bin/python /common-data/bin/.nvidia-smi.py|sed '1d'>./.def.txt
for i in $(for j in `grep -w 'Off' ./.abc.txt|awk '{print $7}'`; do grep -w $j ./.def.txt|awk '{print $2}'; done)
do
    grep -w $i ./.def.txt|egrep -v 'Off|Default'>>./abc.txt
done
echo '+-----------------------------------------------------------------------------+'>>./.abc.txt
cat ./.abc.txt
rm-rf ./.abc.txt ./.def.txt