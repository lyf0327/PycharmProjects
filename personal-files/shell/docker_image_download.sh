#!/usr/bin/env bash
image=$1
tag=$2
help(){
    echo "Usage: docker_image_download.sh  <image> <tag>"
}
if [[ "$1" == "" ]] || [[ "$1" == "-h" ]]
then
    help
else
    mkdir -p /lyf/images && cd /lyf/images
    ssh -i /sshlogin/FARM-1471-5b25a9a4.cn-north-1.pem 52.80.148.5 "docker pull ${image}:${tag}\
     &&mkdir -p /lyf &&docker save ${image}:${tag} -o /lyf/${image//\//-}.tar"
    scp -i /sshlogin/FARM-1471-5b25a9a4.cn-north-1.pem 52.80.148.5:/lyf/${image//\//-}.tar ./
    docker load -i ${image//\//-}.tar
    docker tag ${image}:${tag} registry.gcloud.srcb.com/${image}:${tag}
    docker push registry.gcloud.srcb.com/${image}:${tag}
    if [ $? -ne 0 ]
    then
        unset http_proxy
        unset https_proxy
        docker push registry.gcloud.srcb.com/${image}:${tag}
    fi
fi

