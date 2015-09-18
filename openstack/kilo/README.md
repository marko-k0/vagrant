# Kilo

## Configuration

Install vagrant-libvirt plugin and set vagrant provider to libvirt.

```bash
vagrant plugin install vagrant-libvirt
export VAGRANT_DEFAULT_PROVIDER=libvirt
```

Edit `misc/global-vars.yml` file to configure networking. All `ext_*` variables should be appropriate to your libvirt network (vibr0) that is used by Vagrant for internal communication with VM.

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
vagrant up controller
vagrant up network
```

For access put the right mapping in `/etc/hosts` file, open the browser and lunch an instance or two.
