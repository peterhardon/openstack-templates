module "vm_with_pf_rules_with_ssh_access" {
  source   = "../modules/vm_with_pf_rules_with_ssh_access"

  vm_name              = "_VM_BASE_NAME_"
  floating_ip_id       = "_FLOATING_IP_ID_"
  vm_network_id        = "_VM_NETWORK_ID_"
  vm_subnet_id         = "_VM_SUBNET_ID_"
  access_key           = "_ACCESS_KEY_"
  image_id             = "_IMAGE_ID_"
  flavor_name          = "_FLAVOR_NAME_"
  ssh_forwarded_port   = "_SSH_FORWARDED_PORT1_"
  root_fs_volume_size  = "_ROOT_FS_VOLUME_SIZE_"
}

module "vm_with_pf_rules_with_ssh_access_with_nginx" {
  source   = "../modules/vm_with_pf_rules_with_ssh_access_with_nginx"

  vm_name              = "_VM_BASE_NAME_-nginx"
  floating_ip_id       = "_FLOATING_IP_ID_"
  vm_network_id        = "_VM_NETWORK_ID_"
  vm_subnet_id         = "_VM_SUBNET_ID_"
  access_key           = "_ACCESS_KEY_"
  image_id             = "_IMAGE_ID_"
  flavor_name          = "_FLAVOR_NAME_"
  ssh_forwarded_port   = "_SSH_FORWARDED_PORT2_"
  http_forwarded_port  = "_HTTP_FORWARDED_PORT_"
  ansible_playbook_url = "https://raw.githubusercontent.com/hpcugent/openstack-templates/master/heat/playbooks/install_nginx.yaml"
  root_fs_volume_size  = "_ROOT_FS_VOLUME_SIZE_"
}

module "vm_with_pf_rules_with_ssh_access_with_vsc_net" {
  source   = "../modules/vm_with_pf_rules_with_ssh_access_with_vsc_net"

  vm_name              = "_VM_BASE_NAME_-vsc_net"
  floating_ip_id       = "_FLOATING_IP_ID_"
  vsc_floating_ip      = "_VSC_FLOATING_IP_"
  vm_network_id        = "_VM_NETWORK_ID_"
  vm_subnet_id         = "_VM_SUBNET_ID_"
  vsc_network_id       = "_VSC_NETWORK_ID_"
  vsc_subnet_id        = "_VSC_SUBNET_ID_"
  access_key           = "_ACCESS_KEY_"
  image_id             = "_IMAGE_ID_"
  flavor_name          = "_FLAVOR_NAME_"
  ssh_forwarded_port   = "_SSH_FORWARDED_PORT3_"
  root_fs_volume_size  = "_ROOT_FS_VOLUME_SIZE_"
}

module "vm_with_pf_rules_with_ssh_access_with_nfs_share" {
  source   = "../modules/vm_with_pf_rules_with_ssh_access_with_nfs_share"

  vm_name              = "_VM_BASE_NAME_-nfs_share"
  floating_ip_id       = "_FLOATING_IP_ID_"
  vm_network_id        = "_VM_NETWORK_ID_"
  vm_subnet_id         = "_VM_SUBNET_ID_"
  nfs_network_id       = "_NFS_NETWORK_ID_"
  nfs_subnet_id        = "_NFS_SUBNET_ID_"
  access_key           = "_ACCESS_KEY_"
  image_id             = "_IMAGE_ID_"
  flavor_name          = "_FLAVOR_NAME_"
  ssh_forwarded_port   = "_SSH_FORWARDED_PORT4_"
  share_name           = "_SHARE_NAME_"
  share_size           = "_SHARE_SIZE_"
  root_fs_volume_size  = "_ROOT_FS_VOLUME_SIZE_"
}

