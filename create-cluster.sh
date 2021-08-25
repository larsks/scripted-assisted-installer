#!/bin/bash

. ./functions.sh

: ${CLUSTER_DOMAIN:=ocp.virt}
: ${CLUSTER_IMAGE_DIR:=/var/lib/libvirt/images}
: ${CLUSTER_LOGLEVEL:=1}

usage () {
	echo "${0##*/}: usage: ${0##*/} <clustername> <api_vip> <ingress_vip>"
}

while getopts 'vd:i:' ch; do
	case $ch in
	(d)	CLUSTER_DOMAIN=$OPTARG
		;;
	(v)	let CLUSTER_LOGLEVEL++
		;;

	(i)	discovery_image=$OPTARG
		;;

	(\?)	LOG 1 "unknown option: $OPTARG"
		usage >&2
		exit 2
		;;
	esac
done
shift $(( OPTIND - 1 ))

set -e

(( $# == 3 )) || { usage >&2; exit 1; }

clustername=$1
api_vip=$2
ingress_vip=$3

[[ -z ${clustername} ]] && DIE "missing clustername"
[[ -z $api_vip ]] && DIE "missing api_vip"
[[ -z $ingress_vip ]] && DIE "missing ingress_vip"

if [[ -z $discovery_image ]]; then
	discovery_image=$CLUSTER_IMAGE_DIR/discovery_image_${clustername}.iso
fi
LOG 2 "using discovery image $discovery_image"

oaitool cluster status --cluster ${clustername} > /dev/null 2>&1 &&
	DIE "cluster ${clustername} already exists"

oaitool -v cluster create \
	--openshift-version 4.8.2 \
	--base-domain ocp.virt \
	--ssh-public-key ~/id_rsa_redhat.pub \
	--network-type OVNKubernetes \
	${clustername} ||
	DIE "failed to create cluster ${clustername}"

LOG 2 "getting discovery image url"
image_url=$(oaitool -v cluster get-image-url --cluster ${clustername})

LOG 2 "downloading discovery image"
curl -sf -L -o /var/lib/libvirt/images/discovery_image_${clustername}.iso "$image_url"

. ./create-nodes.sh

LOG 2 "waiting for hist discovery to complete"
oaitool -v host wait-for-status --cluster ${clustername} --hosts 3 insufficient

. ./set-hostnames.sh

LOG 2 "waiting for hosts to become ready"
oaitool -v host wait-for-status --cluster ${clustername} known

LOG 2 "waiting for cluster to become ready"
oaitool -v cluster wait-for-status --cluster ${clustername} ready

LOG 2 "setting api and ingress vips"
oaitool cluster set-vips --cluster ${clustername} \
	--api-vip $api_vip --ingress-vip $ingress_vip

LOG 2 "starting cluster install"
oaitool -v cluster install --cluster ${clustername} --start

. ./wait-for-install.sh

LOG 2 "saving kubeconfig to kubeconfig.${clustername}"
oaitool -v cluster get-kubeconfig --cluster ${clustername} > kubeconfig.${clustername}
