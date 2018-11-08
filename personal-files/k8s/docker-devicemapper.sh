#!/usr/bin/env bash
Device=/dev/sda3
systemctl stop docker
export http_proxy=socks://109.105.32.32:7070
export https_proxy=socks://109.105.32.32:7070
yum -y install device-mapper-persistent-data lvm2
pvcreate ${Device}
vgcreate docker ${Device}
lvcreate --wipesignatures y -n thinpool docker -l 95%VG
lvcreate --wipesignatures y -n thinpoolmeta docker -l 1%VG
lvconvert -y --zero n -c 512K --thinpool docker/thinpool --poolmetadata docker/thinpoolmeta

cat <<EOF >/etc/lvm/profile/docker-thinpool.profile
activation {
  thin_pool_autoextend_threshold=80
  thin_pool_autoextend_percent=20
}
EOF

lvchange --metadataprofile docker-thinpool docker/thinpool
mkdir /var/lib/docker.bk
mv /var/lib/docker/* /var/lib/docker.bk
str=$(cat /usr/lib/systemd/system/docker.service|grep ExecStart)
#sed -i "s%$str%ExecStart=/usr/bin/dockerd  --storage-driver=devicemapper --storage-opt=dm.thinpooldev=/dev/mapper/docker-thinpool --storage-opt dm.use_deferred_removal=true --bip=${FLANNEL_SUBNET}%g" /usr/lib/systemd/system/docker.service
sed -i "s%$str%ExecStart=/usr/bin/dockerd  --storage-driver=devicemapper --storage-opt=dm.thinpooldev=/dev/mapper/docker-thinpool --storage-opt dm.use_deferred_removal=true%g" /usr/lib/systemd/system/docker.service
systemctl daemon-reload
systemctl start docker




