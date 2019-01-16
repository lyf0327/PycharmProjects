#!/usr/bin/env bash
ceph_mon="109.105.1.253 109.105.1.254 109.105.1.246"
ceph_fs=$2
Build(){
    ceph osd pool create ${ceph_fs%f*}_metadata 16
    ceph osd pool create ${ceph_fs%f*}_data 32
    ceph fs new $ceph_fs ${ceph_fs%f*}_metadata ${ceph_fs%f*}_data
}

Rebuild(){
    Rmfs
    ceph osd pool delete ${ceph_fs%f*}_data ${ceph_fs%f*}_data  --yes-i-really-really-mean-it
    ceph osd pool delete ${ceph_fs%f*}_metadata ${ceph_fs%f*}_metadata  --yes-i-really-really-mean-it
    Build
}

Delete(){
    Rmfs
    ceph osd pool delete ${ceph_fs%f*}_data ${ceph_fs%f*}_data  --yes-i-really-really-mean-it
    ceph osd pool delete ${ceph_fs%f*}_metadata ${ceph_fs%f*}_metadata  --yes-i-really-really-mean-it
}

Rmfs(){
    read -p "did you have umount all the $ceph_fs? (yes/no)" myanswer
    if [ "${myanswer}" != "yes" ]
    then
        echo "you must umount all the $ceph_fs"
        exit 1
    fi

    cat <<EOF >./mds_stop.sh
mds_id=\$(ls /var/lib/ceph/mds/)
for i in \$mds_id
do
    systemctl stop ceph-mds@\${i#*-}
done
EOF

    cat <<EOF >./mds_start.sh
mds_id=\$(ls /var/lib/ceph/mds/)
for i in \$mds_id
do
    systemctl start ceph-mds@\${i#*-}
done
EOF
    for i in $ceph_mon
    do
        scp mds_stop.sh $i:/root/
        ssh $i "sh mds_stop.sh"
    done

    ceph fs rm $ceph_fs --yes-i-really-mean-it

    for i in $ceph_mon
    do
        scp mds_start.sh $i:/root/
        ssh $i "sh mds_start.sh"
    done
}

help(){
    echo "Usage: man_fs.sh build <cephfs>"
    echo "       man_fs.sh rebuild <cephfs>"
    echo "       man_fs.sh delete <cephfs>"
}

case $1 in
    "build")
        Build
        ;;
    "rebuild")
        Rebuild
        ;;
    "delete")
        Delete
        ;;
    *)
        help
        ;;
esac




