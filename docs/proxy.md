# Proxy

Some notes how you can setup a proxy OpenShift 4 cluster with hetzner-ocp4

## Adjust cluster.yml

```
# Important: do not allow network traffic from vm network to public
network_forward_mode: "route"

# Start with openshift 4.2.13 because of some proxy issues.
openshift_version: 4.2.13

# And of course the proxy settings
install_config_proxy:
  httpProxy: http://192.168.50.1:8888/
  httpsProxy: http://192.168.50.1:8888/
  noProxy: host.compute.local,192.168.50.0/24
```

## Create network 

Create only the network, important to setup the proxy:

```
./ansible/02-create-cluster.yml --tags network
```

## Setup proxy on kvm-host

Create host entry for proxy: 
```
echo 192.168.50.1 host.compute.local >> /etc/hosts
```

Install & configure
```
yum install -y tinyproxy
```

Adjust `/etc/tinyproxy/tinyproxy.conf`
```
$ diff -Nuar tinyproxy.conf.original tinyproxy.conf
--- tinyproxy.conf.original     2020-01-16 13:06:20.311374487 +0100
+++ tinyproxy.conf      2020-01-16 13:07:42.134628245 +0100
@@ -27,7 +27,7 @@
 # only one. If this is commented out, tinyproxy will bind to all
 # interfaces present.
 #
-#Listen 192.168.0.1
+Listen 192.168.50.1

 #
 # Bind: This allows you to specify which interface will be used for
@@ -207,6 +207,7 @@
 # The order of the controls are important. All incoming connections are
 # tested against the controls based on order.
 #
+Allow 192.168.50.0/24
 Allow 127.0.0.1

 #
```

Enable & start tinyproxy
```
systemctl enable tinyproxy
systemctl start tinyproxy
systemctl status tinyproxy
```

## Create the cluster
```
./ansible/02-create-cluster.yml
```