#!/bin/bash
for f in $(cat time.bei.txt)
do
     file=$(echo $f | awk -F'-2017-' '{print $1}')
      beitime=$(echo $f | awk -F'-2017-' '{print $2}')
      zhutime=$(awk -F'-2017-' -v I=$file '$1==I {print $2}' time.zhu.txt)
      echo "$file  $beitime$zhutime">>record.txt                                                                                                                                 
done


