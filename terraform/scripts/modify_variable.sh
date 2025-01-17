#!/bin/bash

#script logging to modify_variable.log file
test x$1 = x$'\x00' && shift || { set -o pipefail ; ( exec 2>&1 ; $0 $'\x00' "$@" ) | tee -a modify_variable.log ; exit $? ; }

. ./modify_variable.config &>/dev/null
[ -z ${IMAGE_NAME+x} ] && echo "Variable IMAGE_NAME is not set. Exiting.." 1>&2 && exit 1
[ -z ${FLAVOR_NAME+x} ] && echo "Variable FLAVOR_NAME is not set. Exiting.." 1>&2 && exit 1
[ -z ${SHARE_NAME+x} ] && echo "Variable SHARE_NAME is not set. Exiting.." 1>&2 && exit 1
[ -z ${SHARE_SIZE+x} ] && echo "Variable SHARE_SIZE is not set. Exiting.." 1>&2 && exit 1
[ -z ${VM_BASE_NAME+x} ] && echo "Variable VM_BASE_NAME is not set. Exiting.." 1>&2 && exit 1
[ -z ${vm_floating_ip_cidr+x} ] && echo "Variable vm_floating_ip_cidr is not set. Exiting.." 1>&2 && exit 1
[ -z ${vsc_floating_ip_cidr+x} ] && echo "Variable vsc_floating_ip_cidr is not set. Exiting.." 1>&2 && exit 1

[ -z ${OS_CLOUD+x} ] && echo "Variable OS_CLOUD is not set. Using openstack as a value." && export OS_CLOUD=openstack

openstack catalog list &>/dev/null
[ $? -ne 0 ] && echo "Unable to list openstack catalog. Exiting.." 1>&2 && exit 1

openstack image show "$IMAGE_NAME" &>/dev/null
[ $? -ne 0 ] && echo "Unable to locate image $IMAGE_NAME. Exiting.." 1>&2 && exit 1
image_id="$(openstack image show "$IMAGE_NAME" -c id -f value)"
	echo "Image id: $image_id. (Image name: $IMAGE_NAME)"
	echo "Flavor name: $FLAVOR_NAME."
root_fs_volume_size="$(openstack flavor show $FLAVOR_NAME -f value -c disk)"
	echo "Root FS volume size based on flavor disk size: $root_fs_volume_size."
vm_network_id="$(openstack network list -f value -c ID -c Name|grep '_vm'|cut -d ' ' -f1)" && \
	echo "VM network id: $vm_network_id."
vm_subnet_id="$(openstack network list -c Subnets -c Name|grep '_vm'|awk '{print $4}')" && \
	echo "VM subnet id: $vm_subnet_id."
nfs_network_id="$(openstack network list -f value -c ID -c Name|grep '_nfs'|cut -d ' ' -f1)" && \
	echo "NFS network id: $nfs_network_id."
nfs_subnet_id="$(openstack network list -c Subnets -c Name|grep '_nfs'|awk '{print $4}')" && \
	echo "NFS subnet id: $nfs_subnet_id."
vsc_network_id="$(openstack network list -f value -c ID -c Name|grep '_vsc'|cut -d ' ' -f1)" && \
	echo "VSC network id: $vsc_network_id."
vsc_subnet_id="$(openstack network list -c Subnets -c Name|grep '_vsc'|awk '{print $4}')" && \
	echo "VSC subnet id: $vsc_subnet_id."

access_key="$(openstack keypair list -c Name -f value|head -1)"
[ -z "$access_key" ] && echo "Unable to find ssh access key. Exiting.." 1>&2 && exit 1
echo "Using first ssh access key \"$access_key\"."

while read line
do
	ip="$(echo "$line"|awk '{print $2}')"
	ip_id="$(echo "$line"|awk '{print $1}')"
	python3 -c "import ipaddress; ip = ipaddress.ip_address('$(echo "$ip")') in ipaddress.ip_network('$(echo "$vm_floating_ip_cidr")'); \
		print (ip);"|grep "True" &>/dev/null && export floating_ip_id="$ip_id" && export floating_ip="$ip" && \
		break
done < <(openstack floating ip list -f value -c "Floating IP Address" -c ID -c "Port"|grep None)
[ -z "$floating_ip_id" ] && echo "Unable to find floating ip address. Exiting.." 1>&2 && exit 1
echo "Using floating ip id: $floating_ip_id. (floating ip: $floating_ip)"
while read line
do
        ip="$(echo "$line"|awk '{print $1}')"
	python3 -c "import ipaddress; ip = ipaddress.ip_address('$(echo "$ip")') in ipaddress.ip_network('$(echo "$vsc_floating_ip_cidr")'); \
		print (ip);"|grep "True" &>/dev/null && export vsc_floating_ip="$ip" && \
		break
done < <(openstack floating ip list -f value -c "Floating IP Address" -c "Port"|grep None)
[ -z "$vsc_floating_ip" ] && echo "Unable to find VSC floating ip address. Exiting.." 1>&2 && exit 1
echo "Using VSC floating ip: $vsc_floating_ip."

generate_new_free_port () {
        allocated_ports="$(openstack floating ip port forwarding list "$floating_ip_id" -f value -c "External Port"|sort|uniq)"
        for i in $(seq 100)
        do
                port="$(shuf -i 51001-59999 -n 1)"
                echo "$allocated_ports"|grep "$port" &>/dev/null
                [ $? -ne 0 ] && new_port="$port" && break
        done
}
generate_new_free_port && ssh_forwarded_port1="$new_port"
generate_new_free_port && ssh_forwarded_port2="$new_port"
generate_new_free_port && ssh_forwarded_port3="$new_port"
generate_new_free_port && ssh_forwarded_port4="$new_port"
generate_new_free_port && http_forwarded_port="$new_port"
echo "Using ssh forwarded ports: $ssh_forwarded_port1 $ssh_forwarded_port2 $ssh_forwarded_port3 $ssh_forwarded_port4."
echo "Using http forwarded port: $http_forwarded_port."

echo "Modifying ../environment/main.tf file."

verify_variable() {
        #usage: verify_variable "variable to check" "module to comment out if variable is empty"
        variable="$1"
        module_to_comment_out="$2"
        if [ "${!variable}" == "" ]
        then
                echo "WARNING: Missing \$$variable. Commenting out $module_to_comment_out module in ../environment/main.tf file."
                awk "/module.*$module_to_comment_out/,/}/{\$0=\"#\"\$0}1" ../environment/main.tf  > ../environment/main.tf_new
                mv ../environment/main.tf_new ../environment/main.tf
        fi
}

verify_variable "nfs_network_id" "vm_with_pf_rules_with_ssh_access_with_nfs_share"
verify_variable "vsc_network_id" "vm_with_pf_rules_with_ssh_access_with_vsc_net"

sed -i "s/_FLAVOR_NAME_/$FLAVOR_NAME/g" ../environment/main.tf
sed -i "s/_SHARE_NAME_/$SHARE_NAME/g" ../environment/main.tf
sed -i "s/_SHARE_SIZE_/$SHARE_SIZE/g" ../environment/main.tf
sed -i "s/_VM_BASE_NAME_/$VM_BASE_NAME/g" ../environment/main.tf
sed -i "s/_ROOT_FS_VOLUME_SIZE_/$root_fs_volume_size/g" ../environment/main.tf
sed -i "s/_IMAGE_ID_/$image_id/g" ../environment/main.tf
sed -i "s/_VM_NETWORK_ID_/$vm_network_id/g" ../environment/main.tf
sed -i "s/_VM_SUBNET_ID_/$vm_subnet_id/g" ../environment/main.tf
sed -i "s/_NFS_NETWORK_ID_/$nfs_network_id/g" ../environment/main.tf
sed -i "s/_NFS_SUBNET_ID_/$nfs_subnet_id/g" ../environment/main.tf
sed -i "s/_VSC_NETWORK_ID_/$vsc_network_id/g" ../environment/main.tf
sed -i "s/_VSC_SUBNET_ID_/$vsc_subnet_id/g" ../environment/main.tf
sed -i "s/_ACCESS_KEY_/$access_key/g" ../environment/main.tf
sed -i "s/_SSH_FORWARDED_PORT1_/$ssh_forwarded_port1/g" ../environment/main.tf
sed -i "s/_SSH_FORWARDED_PORT2_/$ssh_forwarded_port2/g" ../environment/main.tf
sed -i "s/_SSH_FORWARDED_PORT3_/$ssh_forwarded_port3/g" ../environment/main.tf
sed -i "s/_SSH_FORWARDED_PORT4_/$ssh_forwarded_port4/g" ../environment/main.tf
sed -i "s/_HTTP_FORWARDED_PORT_/$http_forwarded_port/g" ../environment/main.tf
sed -i "s/_FLOATING_IP_ID_/$floating_ip_id/g" ../environment/main.tf
sed -i "s/_VSC_FLOATING_IP_/$vsc_floating_ip/g" ../environment/main.tf

echo "Modifying provider.tf files."
find ../* -name *provider.tf -exec sed -i "s/_OS_CLOUD_/$OS_CLOUD/g" {} \;

echo "SSH commands for VMs access:"
echo "(myvm)           ssh -p $ssh_forwarded_port1 <user>@$floating_ip"
echo "(myvm-nginx)     ssh -p $ssh_forwarded_port2 <user>@$floating_ip"
echo "(myvm-vsc_net)   ssh -p $ssh_forwarded_port3 <user>@$floating_ip"
echo "(myvm-nfs_share) ssh -p $ssh_forwarded_port4 <user>@$floating_ip"
