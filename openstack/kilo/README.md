# Kilo

## Configuration

Edit `misc/global-vars.yml` file to configure networking. All `ext_*` variables should be appropriate to your libvirt network (vibr0) that is used by Vagrant for internal communication with VM.

Everything should be able to run smoothly if you set all `ext_*` variables so they match first network that is used by Vagrant for internal communication with VM. After that, just run commands in the same sequence as shown below and you should have running OpenStack environment.

### 3 Nodes

In configuration file set `controller_mgmt_ip: "10.0.0.11"`.

```bash
vagrant up controller
vagrant up network
vagrant up compute
```

### 2 Nodes

In configuration file set `controller_mgmt_ip: "10.0.0.21"` (in general,`network_mgmt_ip` and `controller_mgmt_ip` are the same).

```bash
vagrant up
```

For access put the right mapping in `/etc/hosts` file, open the browser and lunch an instance or two.
