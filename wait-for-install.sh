LOG 2 "waiting for install to complete"
while :; do
	LOG 3 "checking that guests are still running"
	for dom in $(virsh list --all --name | grep ${clustername}.${CLUSTER_DOMAIN}); do
		domid=$(virsh domid $dom)
		if [[ $domid = "-" ]]; then
			LOG 1 "$dom is down (restarting)"
			virsh start $dom
		fi

	done

	status=$(oaitool cluster status --cluster ${clustername})
	if [[ $status = installed ]]; then
		LOG 1 "cluster install complete"
		break
	fi

	sleep 5
done
