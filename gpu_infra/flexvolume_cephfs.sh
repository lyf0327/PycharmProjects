#!/bin/bash

DEBUG=${CEPHFSDEBUG:-0}
[[ -f /.cephfsdebug ]] && DEBUG=1

d_log='/var/log/flex-volume/cephfs'
if [[ ! -d "${d_log}" ]]; then
        mkdir -p "${d_log}"
        chmod o= "${d_log}"
fi

debug() {
        (( DEBUG )) && echo "$*" >> "${d_log}/debug.log"
#       echo -ne $* >&1
}

# Notes:
#  - Please install "jq" package before using this driver.
usage() {
        err "Invalid usage. Usage: "
        err "\t$0 init"
        err "\t$0 mount <mount dir> <json params>"
        err "\t$0 unmount <mount dir>"
        exit 1
}

err() {
    (( DEBUG )) && echo "${date}:ERROR: $*" >> "${d_log}/debug.log"
        echo -ne $* 1>&2
}

log() {
    (( DEBUG )) && echo "${date}:OUTPUT: $*" >> "${d_log}/debug.log"
        echo -ne $* >&1
}

ismounted() {
        MOUNT=`findmnt -n ${MNTPATH} 2>/dev/null | cut -d' ' -f1`
        if [ "${MOUNT}" == "${MNTPATH}" ]; then
                echo "1"
        else
                echo "0"
        fi
}

domount() {
        MNTPATH=$1
    debug "domount"
    debug "$1"
    debug "$2"
        MDS=$(echo $2 | jq -r '.mds')
        MONITOR=$(echo $2 | jq -r '.monitors')
        SHARE=$(echo $2 | jq -r '.share')
        if [[ "$SHARE"x == "null"x ]]
        then
                SHARE=/${MNTPATH##*/}
        fi
        TYPE=$(echo $2 | jq -r '.mounttype')
        debug "$TYPE"
        if [[ "$TYPE"x == "null"x ]] || [[ "$TYPE"x == x ]] || [[ "$TYPE"x == "ceph-fuse"x ]]  ; then
            TYPE='mount'
        fi
        debug "$TYPE"
        SIZE=$(echo $2 | jq -r '.size')
        if [[ "$SIZE" == "null" ]] || [[ "$SIZE" == "" ]] ; then
            SIZE=0
        else
            if [ "${SIZE%[a-z]*}" == "" ]
            then
                SIZE=$((500*1073741824))
            else
                if [ "${SIZE: -1}" == "m" ] || [ "${SIZE: -1}" == "M" ]
                then
                    SIZE=$((${SIZE%[a-z]*}*1048576))
                elif [ "${SIZE: -1}" == "g" ] || [ "${SIZE: -1}" == "G" ]
                then
                    SIZE=$((${SIZE%[a-z]*}*1073741824))
                elif [ "${SIZE: -1}" == "t" ] || [ "${SIZE: -1}" == "T" ]
                then
                    SIZE=$((${SIZE%[a-z]*}*1099511627776))
                else
                    err "{ \"status\": \"Failure\", \"message\": \"Failed to mount CephFS share ${SHARE} at ${MNTPATH} due to no keyring\"}"
                    exit 1
                fi
            fi
        fi
        debug "$SIZE"
        RIGHTS=$(echo $2 | jq -r '.rights')
        if [[ "${RIGHTS}" == "null" ]] || [[ "${RIGHTS}" == "" ]] ; then
            RIGHTS='rw'
        fi
        debug "$RIGHTS"
        AUTH_ID=$(echo $2 | jq -r '.authid')
        KEYRING=$(echo $2 | jq -r '.["kubernetes.io/secret/keyring"]')

        # If value of keyring  is null it means secret not present. Try to parse it
        # from an option instead of a secret
        if [[ ${KEYRING} == 'null' ]]; then
                KEYRING=$(echo $2 | jq -r '.keyring')
        fi

        # If keyring is still null, it means there is no keyring. Abort
        if [[ ${KEYRING} == 'null' ]]; then
                err "{ \"status\": \"Failure\", \"message\": \"Failed to mount CephFS share ${SHARE} at ${MNTPATH} due to no keyring\"}"
                exit 1
        fi

        if [ $(ismounted) -eq 1 ] ; then
                log "{\"status\": \"Success\"}"
                exit 0
        fi

        # Ensure only root can read the keyring file
        current_umask=$(umask)
        umask 077
        # Write keyring to file
        KEYRING_PATH="/var/run/cephfs/${AUTH_ID}/ceph.client.${AUTH_ID}.keyring"
        KEYRING_PATH2="/etc/ceph/cephfs/${AUTH_ID}/ceph.client.${AUTH_ID}.keyring"
        mkdir -p "/var/run/cephfs/${AUTH_ID}"
        mkdir -p "/etc/ceph/cephfs/${AUTH_ID}"
        echo $KEYRING  > $KEYRING_PATH
        echo -e "[client.$AUTH_ID]\n\tkey = $KEYRING"  > $KEYRING_PATH2
        umask $current_umask

        # Mount the share with ceph-fuse
        mkdir -p ${MNTPATH} &> /dev/null
        # Expect the conf file to be written in /etc/ceph/ceph.conf     which is where the
        # ceph puppet module installs the file.
        TMPDIR=$(mktemp -d)
    debug "tmp dir is $TMPDIR"
        output=$(mount -t ceph  ${MONITOR}:/ ${TMPDIR} -o mds_namespace=${MDS},name=${AUTH_ID},secretfile=${KEYRING_PATH})
    if [ $? -ne 0 ]; then
       err "{ \"status\": \"Failure\", \"message\": \"Failed to mount CephFS share $MONITOR:/ at ${TMPDIR}:${output}\"}"
       exit 1
    fi

        mkdir -p ${TMPDIR}${SHARE}
        if [ "${SHARE}" != "/" ] && [ "$TYPE"x == "ceph-fuse-add"x ];then
            debug "quota command:"
            debug "setfattr -n ceph.quota.max_bytes -v ${SIZE} ${TMPDIR}${SHARE}"
            setfattr -n ceph.quota.max_bytes -v ${SIZE} ${TMPDIR}${SHARE}
            if [ $? -ne 0 ]; then
                err "{ \"status\": \"Failure\", \"message\": \"Failed to mount CephFS share $MONITOR:/ at ${TMPDIR}\"}"
                exit 1
            fi
        fi
        if [ $? -ne 0 ]; then
           err "{ \"status\": \"Failure\", \"message\": \"Failed to mount CephFS share $MONITOR:/ at ${TMPDIR}\"}"
           exit 1
        fi
    umount ${TMPDIR} && rm -rf ${TMPDIR}
    if [ $? -ne 0 ]; then
        err "{ \"status\": \"Failure\", \"message\": \"Failed to mount CephFS share $MONITOR:/ at ${TMPDIR}\"}"
        exit 1
    fi
    if [[ "$TYPE"x == "mount"x ]];then
        debug "mount command:"
        debug "mount -t ceph  $MONITOR:$SHARE ${MNTPATH} -o mds_namespace=${MDS},name=${AUTH_ID},secretfile=${KEYRING_PATH} -o $RIGHTS"
        output=$(mount -t ceph  $MONITOR:$SHARE ${MNTPATH} -o mds_namespace=${MDS},name=${AUTH_ID},secretfile=${KEYRING_PATH} -o $RIGHTS 2>&1)
        if [ $? -ne 0 ]; then
                err "{ \"status\": \"Failure\", \"message\": \"Failed to mount CephFS share $MONITOR:${SHARE} at ${MNTPATH}: ${output}\"}"
                exit 1
        fi
        log "{\"status\": \"Success\"}"
        exit 0
     elif [[ "$TYPE"x == "ceph-fuse-add"x ]];then
        debug "ceph-fuse command:"
        debug "ceph-fuse -o $RIGHTS ${MNTPATH} --id=${AUTH_ID} --conf=/etc/ceph/ceph.conf --keyring=${KEYRING_PATH2}  --client_mds_namespace=${MDS} --client-mountpoint=${SHARE}"
        output=$(ceph-fuse -o $RIGHTS ${MNTPATH} --id=${AUTH_ID} --conf=/etc/ceph/ceph.conf --keyring=${KEYRING_PATH2} --client_mds_namespace=${MDS} --client-mountpoint=${SHARE} 2>&1)
        if [ $? -ne 0 ]; then
                err "{ \"status\": \"Failure\", \"message\": \"Failed to mount CephFS share $MONITOR:${SHARE} at ${MNTPATH}: ${output}\"}"
                exit 1
        fi
        log "{\"status\": \"Success\"}"
        exit 0
     else
        err "{ \"status\": \"Failure\", \"message\": \"Failed to mount CephFS share $MONITOR:${SHARE} at ${MNTPATH}: ${output}\"}"
        exit 1
     fi
}

unmount() {
    debug "unmount"
    debug "$1"
        MNTPATH=$1
        if [ $(ismounted) -eq 0 ] ; then
                log "{\"status\": \"Success\"}"
                exit 0
        fi

        sync && umount ${MNTPATH} &> /dev/null
        if [ $? -ne 0 ]; then
                err "{ \"status\": \"Failed\", \"message\": \"Failed to unmount volume at ${MNTPATH}\"}"
                exit 1
        fi

        log "{\"status\": \"Success\"}"
        exit 0
}

# provisions a volume
provision(){
    debug "provision() called"
    debug $1
    log "{\"status\": \"Success\"}"
    exit 0
}

# deletes a provisioned volume
delete(){
    debug "delete() called"
    debug $1

        MDS=$(echo $1 | jq -r '.mds')
        MONITOR=$(echo $1 | jq -r '.monitors')
    SHARE=$(echo $1 | jq -r '.share')
        if [[ "$SHARE" == "null" ]]
        then
                SHARE=/$(echo $1 | jq -r '.["srcb.com/pvOrVolumeName"]')
        fi

        AUTH_ID=$(echo $1 | jq -r '.authid')
        KEYRING=$(echo $1 | jq -r '.["kubernetes.io/secret/keyring"]')

        # If value of keyring  is null it means secret not present. Try to parse it
        # from an option instead of a secret
        if [[ ${KEYRING} == 'null' ]]; then
                KEYRING=$(echo $1 | jq -r '.keyring')
        fi

        # If keyring is still null, it means there is no keyring. Abort
        if [[ ${KEYRING} == 'null' ]]; then
                err "{ \"status\": \"Failure\", \"message\": \"Failed to mount CephFS share ${SHARE} at ${MNTPATH} due to no keyring\"}"
                exit 1
        fi

        TMPDIR=$(mktemp -d)
    debug "tmp dir is $TMPDIR"
        output=$(mount -t ceph  ${MONITOR}:/ ${TMPDIR} -o mds_namespace=${MDS},name=${AUTH_ID},secret=${KEYRING})
    if [ $? -ne 0 ]; then
       err "{ \"status\": \"Failure\", \"message\": \"Failed to mount CephFS share $MONITOR:/ at ${TMPDIR}:${output}\"}"
       exit 1
    fi

        rm -rf ${TMPDIR}${SHARE}
        if [ $? -ne 0 ]; then
           err "{ \"status\": \"Failure\", \"message\": \"Failed to mount CephFS share $MONITOR:/ at ${TMPDIR}\"}"
           exit 1
        fi
    umount ${TMPDIR} && rm -rf ${TMPDIR}
    if [ $? -ne 0 ]; then
        err "{ \"status\": \"Failure\", \"message\": \"Failed to mount CephFS share $MONITOR:/ at ${TMPDIR}\"}"
        exit 1
    fi

    log "{\"status\": \"Success\"}"
    exit 0
}

op=$1

if [ "$op" = "init" ]; then
    debug "init"
    # SELinux relabel not supported on a FUSE mount point
        log "{\"status\": \"Success\", \"capabilities\": {\"attach\": false, \"selinuxRelabel\": false}}"
        exit 0
fi

if [ $# -lt 2 ]; then
        usage
fi

shift

case "$op" in
        mount)
                domount $*
                ;;
        unmount)
                unmount $*
                ;;
        provision)
                provision $*
                ;;
        delete)
                delete $*
                ;;
        *)
                log "{ \"status\": \"Not supported\" }"
                exit 0
esac

exit 1