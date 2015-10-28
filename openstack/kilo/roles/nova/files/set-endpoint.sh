#!/bin/sh

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source $DIR/admin-openrc.sh

openstack endpoint delete $(openstack endpoint show -c id -f value compute)
openstack endpoint create --publicurl="http://controller:8774/v2/%(tenant_id)s" --internalurl="http://controller:8774/v2/%(tenant_id)s" --adminurl="http://controller:8774/v2/%(tenant_id)s" --region RegionOne compute
