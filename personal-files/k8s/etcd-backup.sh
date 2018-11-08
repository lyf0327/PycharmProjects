#!/usr/bin/env bash
#https://coreos.com/etcd/docs/latest/op-guide/recovery.html
export ETCDCTL_API=2
alias etcdctl="etcdctl --endpoint https://109.105.1.253:2379 --ca-file=/etc/etcd/ssl/etcd-ca.pem --cert-file /etc/etcd/ssl/etcd.pem --key-file /etc/etcd/ssl/etcd-key.pem"
date_time=`date +%Y%m%d`
mkdir -p /data/etcd_backup_v2
etcdctl backup --data-dir /var/lib/etcd --backup-dir /data/etcd_backup_v2/member-${date_time}
find /data/etcd_backup_v2/ -mtime +3 -name "member.*" -exec rm -rf {} \;
#for ETCDCTL_API=3
mkdir -p /data/etcd_backup_v3
cp /var/lib/etcd/member/snap/db /data/etcd_backup_v3/${date_time}.db
find /data/etcd_backup_v3/ -mtime +3 -name "*.db" -exec rm -rf {} \;

