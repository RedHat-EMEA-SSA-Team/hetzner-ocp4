# Proxy

Some notes how you can setup a proxy OpenShift 4 cluster with hetzner-ocp4

## Adjust cluster.yml

```
# Important: do not allow network traffic from vm network to public
network_forward_mode: "route"

# And of course the proxy settings
install_config_proxy:
  httpProxy: http://host.compute.local:3218/
  httpsProxy: http://host.compute.local:3128/
```

## Create network

Create only the network, important to setup the proxy:

```
./ansible/02-create-cluster.yml --tags network
```

## Setup proxy on kvm-host

### Installation
```
dnf install -y squid
```

### Configuration

Get host IP addresses from kvm network:
```bash
$ virsh net-dumpxml demo | grep '<ip'
  <ip address='192.168.50.1' netmask='255.255.255.0'>
  <ip family='ipv6' address='2001:db8:dead:beef:fe::1' prefix='80'>
```

Configure squid, replace IP addresses:
```bash
echo "http_port  192.168.50.1:3128"             >>/etc/squid/squid.conf
echo "http_port [2001:db8:dead:beef:fe::1]:3128" >> /etc/squid/squid.conf
echo "acl localnet src 192.168.50.0/24"         >> /etc/squid/squid.conf
echo "acl localnet src 2001:db8:dead:beef::/64"  >> /etc/squid/squid.conf
```

Enable and start squid
```bash
systemctl enable --now squid
```

### Configure host firewall

```bash
firewall-cmd --zone=libvirt --add-service=squid --permanent
firewall-cmd --reload
```

## Create the cluster

```
./ansible/02-create-cluster.yml
```