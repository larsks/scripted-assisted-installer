#!/bin/bash

. ./functions.sh

: ${CLUSTER_DOMAIN:=ocp.virt}
: ${CLUSTER_LOGLEVEL:=1}

while getopts 'vd:' ch; do
	case $ch in
	(d)	CLUSTER_DOMAIN=$OPTARG
		;;
	(v)	let CLUSTER_LOGLEVEL++
		;;
	esac
done
shift $(( OPTIND - 1 ))

set -e

clustername=$1
[[ -z ${clustername} ]] && DIE "missing cluster name"

LOG 1 "destroying virtual nodes"
for dom in $(virsh list --all --name | grep ${clustername}.${CLUSTER_DOMAIN}); do
	LOG 1 "destroying virtual node $dom"
	virsh destroy $dom
	virsh undefine --remove-all-storage $dom
done

LOG 1 "destroying assisted installer cluster"
oaitool -v cluster delete --cluster ${clustername}
