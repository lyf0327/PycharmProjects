#!/usr/bin/env bash
#!/bin/bash
unset http_proxy
unset https_proxy
kubectl get pods --all-namespaces |grep Terminating|grep -w "0/1"|awk '{ system("kubectl delete pod "$2" -n "$1" --grace-period=0 --force") }'
kubectl get pods --field-selector=status.phase=Failed --all-namespaces |awk '{ system("kubectl delete pod "$2" -n "$1) }'