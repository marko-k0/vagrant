#!/bin/sh

source ./admin-openrc.sh

mkdir -p /tmp/images

wget -P /tmp/images http://download.cirros-cloud.net/0.3.4/cirros-0.3.4-x86_64-disk.img
#wget -P /tmp/images http://cloud.centos.org/centos/7/images/CentOS-7-x86_64-GenericCloud.qcow2

glance image-create --name "cirros-0.3.4-x86_64" --file /tmp/images/cirros-0.3.4-x86_64-disk.img \
     --disk-format qcow2 --container-format bare --visibility public --progress

#glance image-create --name 'CentOS 7' --disk-format qcow2 --container-format bare --is-public true \
#  --copy-from http://cloud.centos.org/centos/7/images/CentOS-7-x86_64-GenericCloud.qcow2

glance image-list

#openstack endpoint delete $(openstack endpoint show -c id -f value compute)
#openstack endpoint create --publicurl="http://controller:8774/v2/%(tenant_id)s" --internalurl="http://controller:8774/v2/%(tenant_id)s" --adminurl="http://controller:8774/v2/%(tenant_id)s" --region RegionOne compute
