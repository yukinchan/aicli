#!/bin/sh

NIC=br-ex
IP=$(awk -F 'relocateip=' '{sub(/ .*$/, "", $2); print $2}' /proc/cmdline)
NETMASK=$(awk -F 'relocatenetmask=' '{sub(/ .*$/, "", $2); print $2}' /proc/cmdline)

grep -q $IP /etc/NetworkManager/system-connections/* && exit 0

connection=$(nmcli -t -f NAME,DEVICE c s -a | grep $NIC | grep -v ovs-port | grep -v ovs-if | cut -d: -f1)
nmcli connection modify "$connection" +ipv4.addresses $IP/$NETMASK ipv4.method auto
ip addr add $IP/$NETMASK dev $NIC
[ -d /run/nodeip-configuration ] || mkdir -p /run/nodeip-configuration
echo $IP > /run/nodeip-configuration/ipv4
echo $IP > /run/nodeip-configuration/primary-ip
echo -e "[Service]\nEnvironment=\"KUBELET_NODE_IP=$IP\" \"KUBELET_NODE_IPS=$IP\"" > /etc/systemd/system/kubelet.service.d/20-nodenet.conf
echo -e "[Service]\nEnvironment=\"CONTAINER_STREAM_ADDRESS=$IP\"" > /etc/systemd/system/crio.service.d/20-nodenet.conf
