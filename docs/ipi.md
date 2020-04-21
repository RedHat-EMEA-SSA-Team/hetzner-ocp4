# Hetzner OCP IPI - Libvirt provider

# Disclaimer
This environment has been created for the sole purpose of providing an easy to deploy and consume a Red Hat OpenShift Container Platform 4 environment *as a sandpit*.

NOTE: libvirt support is not enabled by default because libvirt is development only and it is not supported.

Use it at your own please and risk!

# Install Instructions

Our instructions are based on the CentOS Root Server as provided by https://www.hetzner.com/ , please feel free to adapt it to the needs of your preferred hosting provider. We are happy to get pull requests for an updated documentation, which makes consuming this setup easy also for other hosting providers.

**These instructions are for running CentOS and 'root' machines which is setup following [Hetzner CentOS](docs/hetzner.md) documentation. You might have to modify commands if running on another Linux distro.  Feel free to provided instructions for providers.**

**NOTE: If you are running on other environments than bare metal servers from Hetzner, check if there is specific instruction under Infra providers list and then jump to section [Initialize tools](https://github.com/RedHat-EMEA-SSA-Team/hetzner-ocp4#initialize-tools)   

** Supported root server operating systems: **
- CentOS 8
- RHEL 8 - How to install RHEL8: https://keithtenzer.com/2019/10/24/how-to-create-a-rhel-8-image-for-hetzner-root-servers/

## Infra providers
* [Hetzner CentOS](docs/hetzner.md)

# OpenShift Libvirt Platform Customization

The following options are available when using libvirt:
```
platform.libvirt.network.if - the network bridge attached to the libvirt network (tt0 by default)
```
#### Example

An example install-config.yaml is shown below. This configuration has been modified to show the customization that is possible via the install config.

```
apiVersion: v1
baseDomain: example.com
...
platform:
  libvirt:
    URI: qemu+tcp://192.168.122.1/system
    network:
      if: mybridge0
pullSecret: '{"auths": ...}'
sshKey: ssh-ed25519 AAAA...
```
# Libvirt Setup
It's expected that you will create and destroy clusters often in the course of development. These steps only need to be run once.

## Before you begin, install the build dependencies.
```
yum install gcc-c++ libvirt-devel tar git -y
wget https://dl.google.com/go/go1.14.2.linux-amd64.tar.gz
tar -C /usr/local -xzf go1.14.2.linux-amd64.tar.gz
export PATH=$PATH:/usr/local/go/bin
echo "export PATH=$PATH:/usr/local/go/bin" >> /root/.bashrc
```

## Install and Enable Libvirt

First, enable and start firewalld, We dont want to expose libvirt to the internet.
```
systemctl enable --now firewalld
```

### Enabling Advanced Virtualization Repository 
```
dnf module disable virt -y
```
#### In case of Centos 8
```
cat > /etc/yum.repos.d/CentOS-Virt.repo << EOF
[Advanced_Virt]
name=CentOS-$releasever - Advanced Virt 
baseurl=http://mirror.centos.org/centos/\$releasever/virt/x86_64/advanced-virtualization/
gpgcheck=0
enabled=1
EOF
```
#### In case of RHEL8
```
subscription-manager repos --enable advanced-virt-for-rhel-8-x86_64-rpms
```
### Installing Virtualization Packages
```
yum groupinstall "Virtualization Host" -y
yum install virt-install libguestfs-tools swtpm swtpm-tools @container-tools -y
systemctl enable libvirtd-tcp.socket
```

Libvirt creates a bridged connection to the host machine, but in order for the network bridge to work IP forwarding needs to be enabled. The following command will tell you if forwarding is enabled:

```
sysctl net.ipv4.ip_forward
```

If the command output is:
```
net.ipv4.ip_forward = 0
```

then forwarding is disabled and proceed with the rest of this section. If IP forwarding is enabled then skip the rest of this section.

To enable IP forwarding :
```
firewall-cmd --add-masquerade --permanent
firewall-cmd --reload
```

## Configure libvirt to accept TCP connections

The Kubernetes cluster-api components drive deployment of worker machines. The libvirt cluster-api provider will run inside the local cluster, and will need to connect back to the libvirt instance on the host machine to deploy workers.

In order for this to work, you'll need to enable TCP connections for libvirt.

### Configure libvirtd.conf
To do this, first modify your /etc/libvirt/libvirtd.conf and set the following:
```
auth_tcp="none"
```
Next, start libvirtd-tcp:
```
systemctl start libvirtd-tcp.socket
```

## Firewall

On RHEL8, the bridges used by the VMs are already isolated in their own zones, so we only need to allow traffic on the libvirt port:

```
firewall-cmd --zone=libvirt --add-service=libvirt --permanent
firewall-cmd --zone=libvirt --add-service=http --permanent
firewall-cmd --zone=libvirt --add-service=https --permanent
firewall-cmd --zone=libvirt --add-service=dns --permanent
firewall-cmd --reload
```

# Pick a domain and cluster Name

In this example, we'll set the base domain to **openshift.cool**  and the cluster name to **ocp**.

# Set up DNS overlay

This step allows installer and users to resolve cluster-internal hostnames from your host.

1. Tell NetworkManager to use dnsmasq:

```
yum install dnsmasq
echo -e "[main]\ndns=dnsmasq" | sudo tee /etc/NetworkManager/conf.d/openshift.conf
```

2. Tell dnsmasq to use your cluster.

```
echo listen-address=127.0.0.1 > /etc/NetworkManager/dnsmasq.d/openshift.conf
echo bind-interfaces >> /etc/NetworkManager/dnsmasq.d/openshift.conf
echo server=8.8.8.8 >> /etc/NetworkManager/dnsmasq.d/openshift.conf
echo address=/apps.ocp.openshift.cool/192.168.126.1 >> /etc/NetworkManager/dnsmasq.d/openshift.conf
```

3. Reload NetworkManager to pick up the dns configuration change: 

```
systemctl reload NetworkManager
```

# Set up the LoadBalancer

There isn't a load balancer on libvirt. 

### Deploying a local loadbalancer using podman

PS: It will not update automatically in case of adding more nodes either using manual or machine sets methods.

- 1x bootstrap
- 3x Master 
- 3x Workers

```
firewall-cmd --add-service=http --permanent
firewall-cmd --add-service=https --permanent
firewall-cmd --reload

/usr/bin/podman run -d --name loadbalancer --net host \
    -e API="bootstrap=192.168.126.10:6443,master-0=192.168.126.11:6443,master-1=192.168.126.12:6443,master-2=192.168.126.13:6443" \
    -e API_LISTEN="0.0.0.0:6443" \
    -e INGRESS_HTTP="worker-0=192.168.126.51:80,worker-1=192.168.126.52:80,worker-2=192.168.126.53:80" \
    -e INGRESS_HTTP_LISTEN="0.0.0.0:80" \
    -e INGRESS_HTTPS="worker-0=192.168.126.51:443,worker-1=192.168.126.52:443,worker-2=192.168.126.53:443" \
    -e INGRESS_HTTPS_LISTEN="0.0.0.0:443" \
    -e MACHINE_CONFIG_SERVER="bootstrap=192.168.126.10:22623,master-0=192.168.126.10:22623,master-1=192.168.126.11:22623,master-2=192.168.126.12:22623" \
    -e MACHINE_CONFIG_SERVER_LISTEN="127.0.0.1:22623" \
    quay.io/redhat-emea-ssa-team/openshift-4-loadbalancer
```

# Build the openshift-installer

```
mkdir -p /root/go/src/github.com/openshift/
cd /root/go/src/github.com/openshift/ 
git clone https://github.com/openshift/installer
cd installer 
```

### In case of Openshift-Installer Version 4.3

```
git checkout release-4.3
```

### In case of  Openshift-Installer Version 4.4

```
git checkout release-4.4
```

## Bulding the installer

```
sed -i 's/local_only = true/local_only = false/' /root/go/src/github.com/openshift/installer/data/data/libvirt/main.tf
TAGS=libvirt hack/build.sh
mkdir /root/bin
cp -rf /root/go/src/github.com/openshift/installer/bin/openshift-install /root/bin/
```

# Run the installer

With libvirt configured, you can proceed with the usual quick-start.

## Creating the installation configuration file

Prerequisites: Obtain the OpenShift Container Platform installation program and the pull secret for your cluster.

### Create the install-config.yaml file.

```
openshift-install create install-config --dir=ocp
```

Edit the install-config.yaml and increase the master and worker replicas from 1 to 3
You can also change the underlay IP range by changing the machineNetwork cidr.

### In case of using the OCP 4.3 installer
```
export OPENSHIFT_INSTALL_RELEASE_IMAGE_OVERRIDE=quay.io/openshift-release-dev/ocp-release:4.3.12-x86_64
openshift-install create cluster --dir=ocp
```

### In case of using the OCP 4.4 installer
```
export OPENSHIFT_INSTALL_RELEASE_IMAGE_OVERRIDE=quay.io/openshift-release-dev/ocp-release:4.4.0-rc.9-x86_64
openshift-install create cluster --dir=ocp
```

# Cleanup

To remove resources associated with your cluster, run:

```
openshift-install destroy cluster
```


# External Access to your cluster

That is the easy part, Add the following DNS records into your domain.

```
api.<clustername>.<domainname> IN A <hetzner_IP>
*.apps.<clustername>.<domainname> IN A <hetzner_IP>
```

### For example:

```
api.ocp.openshift.cool IN A 46.4.71.10
*.apps.ocp.openshift.cool IN A 46.4.71.10
```

```
nslookup api.ocp.openshift.cool
Server:		10.38.5.26
Address:	10.38.5.26#53

Non-authoritative answer:
Name:	api.ocp.openshift.cool
Address: 46.4.71.10
```

```
nslookup demoapp.apps.ocp.openshift.cool
Server:		10.38.5.26
Address:	10.38.5.26#53

Non-authoritative answer:
Name:	demoapp.apps.ocp.openshift.cool
Address: 46.4.71.10

```
