#!/usr/bin/env bash
Host=ceph-nodes
Command(){
    ansible $Host -m command -a "$cmd"
}

copy_cephfs(){
    ansible $Host -m copy -a 'src=/var/lib/kubelet/volumeplugins/srcb~cephfs/cephfs dest=/var/lib/kubelet/volumeplugins/srcb~cephfs/cephfs'
}

copy_host(){
    ansible $Host -m copy -a 'src=/etc/hosts dest=/etc/'
}

copy_cephconf(){
    ansible $Host -m copy -a 'src=/etc/ceph/ceph.conf dest=/etc/ceph'
}

help(){
    echo "Usage: ansible_ceph.sh date"
    echo "       ansible_ceph.sh copy <cephfs/hosts/cephconf>"
}

case $1 in
    "command")
        if [ "$1" == "command" ]
        then
            shift 1
            cmd="$*"
        fi
        Command
        ;;
    "copy")
        case $2 in
            cephfs)
                copy_cephfs
                ;;
            hosts)
                 copy_host
                 ;;
            cephconf)
                copy_cephconf
                ;;
            *)
                help
                ;;
        esac

        ;;
    *)
        help
        ;;
esac
