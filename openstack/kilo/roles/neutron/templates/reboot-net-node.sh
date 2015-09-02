#!/bin/bash

sleep 10

ovs-vsctl add-port br-ex {{ ext_ifce }}
reboot -f
