#!/bin/bash

test -n "$1" && sleep $1 || sleep 10

ovs-vsctl add-port br-ex {{ ext_ifce }}
reboot -f
