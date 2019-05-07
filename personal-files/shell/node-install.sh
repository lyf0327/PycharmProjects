#!/usr/bin/env bash
cd /mnt
mkdir Data_Intelligence_Labfs  Intelligent_Innovation_Labfs  Machine_Learning_Labfs  SAIT_China_Labfs
cd
cat <<EOF >>/etc/fstab
ceph-mon1:6789,ceph-mon2:6789,ceph-mon3:6789,ceph-mon4:6789,ceph-mon5:6789:/ /mnt/Data_Intelligence_Labfs ceph mds_namespace=Data_Intelligence_Labfs,name=admin,secret=AQDeUgJbJgwNMhAAnzeW5LwQSwqMyWs7Zvl5cQ== 0 2
ceph-mon1:6789,ceph-mon2:6789,ceph-mon3:6789,ceph-mon4:6789,ceph-mon5:6789:/ /mnt/Intelligent_Innovation_Labfs ceph mds_namespace=Intelligent_Innovation_Labfs,name=admin,secret=AQDeUgJbJgwNMhAAnzeW5LwQSwqMyWs7Zvl5cQ== 0 2
ceph-mon1:6789,ceph-mon2:6789,ceph-mon3:6789,ceph-mon4:6789,ceph-mon5:6789:/ /mnt/SAIT_China_Labfs ceph mds_namespace=SAIT_China_Labfs,name=admin,secret=AQDeUgJbJgwNMhAAnzeW5LwQSwqMyWs7Zvl5cQ== 0 2
ceph-mon1:6789,ceph-mon2:6789,ceph-mon3:6789,ceph-mon4:6789,ceph-mon5:6789:/ /mnt/Machine_Learning_Labfs ceph mds_namespace=Machine_Learning_Labfs,name=admin,secret=AQDeUgJbJgwNMhAAnzeW5LwQSwqMyWs7Zvl5cQ== 0 2
EOF
mount -a
