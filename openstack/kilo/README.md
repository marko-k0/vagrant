# Kilo

## Configuration

Edit `misc/global-vars.yml` file to configure networking appropriate to your libvirt network. Everything should be able to run smoothly if you set all `ext_*` variables so they match first network that is used by Vagrant for internal communication with VM. After that, just run commands in the same sequence as shown below and you should have running OpenStack environment.

```bash
vagrant up controller
vagrant up network
vagrant up compute
```

For access put the right mapping in `/etc/hosts` file, open the browser and enjoy.
