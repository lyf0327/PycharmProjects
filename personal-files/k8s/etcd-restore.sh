#!/bin/bash

 ETCDCTL_API=3 etcdctl snapshot restore /tmp/snapshot.db \
  --data-dir=/var/lib/etcd \
  --name=$(hostname) \
  --initial-cluster k8s-master-1=https://109.105.1.253:2380,k8s-master-2=https://109.105.1.254:2380,k8s-m1=https://109.105.30.155:2380,k8s-m2=https://109.105.30.156:2380,k8s-m3=https://109.105.1.209:2380,k8s-n1=https://109.105.30.157:2380,k8s-n2=https://109.105.1.208:2380 \
  --initial-cluster-token etcd-k8s-cluster \
  --initial-advertise-peer-urls https://$(hostname -i):2380