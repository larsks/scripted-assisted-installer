EXENAME=${0##*/}

LOG() {
	local msglevel=$1
	shift
	(( msglevel > CLUSTER_LOGLEVEL )) && return
	echo "${EXENAME}: $*" >&2
}

DIE() {
	LOG 0 "ERROR: $1"
	exit ${2:-1}
}
