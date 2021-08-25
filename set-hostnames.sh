for node in {0..2}; do
	hostname=ctrl${node}.${clustername}.${CLUSTER_DOMAIN}
	macaddr=$(virsh domiflist $hostname | awk '/vnet/ {print $5}')
	LOG 2 "setting hostname for $hostname ($macaddr)"

	hostid=$(oaitool host find --cluster ${clustername} -m mac=$macaddr | awk '{print $1}')
	[[ -z $hostid ]] && DIE "failed to find host with mac address $macaddr"

	LOG 3 "found host id $hostid for mac address $macaddr"
	oaitool host --cluster ${clustername} set-name $hostid $hostname
done


