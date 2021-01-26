# RELEASE NOTES

## 2020-12-28

* **Add support of 3 node compact cluster (Fixed issue #158 )**
* Bump OpenShift version to 4.6.8
* Fixed issue #147 - Add recommended hetzner firewall documentation
* **Add support for add-ons (post_install_add_ons)**
  * Checkout [add-ons.md](add-ons.md) for details.
* Clean DNS provider handling and dependencies managment
* **Added an option to make masters un/schedulable**
* Fixed issue #162 Stop Cluster - Check openshift-4-loadbalancer-demo2.service FAILS
* Fixed issue #156 - podman command in readme.md not showing stats
* Fixed issue #152 Set installconfig.networking.machineNetwork in install-config.yaml
* Do not use kubeconfig directly anymore because of #149
* Fixed issue qemu-img: Unable to initialize gcrypt #160
* Cleanup OS dependencies
  * Cleanup DNS provider dependencies - only install dependencies if needed
  * Cleanup DNS provider dependencies - only install dependencies if needed
  * Add missing package (RHEL8)
  * Remove pip install and use rpm's if possible
* **Remove RHEL 7 support  (fixed issue #153)**
* Fixed issue #146 - BUG in ansible-playbook ansible/setup - failed: iptables: No chain/target/match by that name.
* Introduce openshift_mirror variable - setup your own openshift mirror to get rid of connections problems.

## 2020-11-04

### Bump OpenShift version to 4.6

### SDN plugin defaults to OVNKubernetes

cluster.yaml support sdn_plugin_name variable. Valid values are OVNKubernetes and OpenShiftSDN

### Add Azure DNS Support

```init
dns_provider: [route53|cloudflare|gcp|azure]
# Azure
azure_client_id: client_id
azure_secret: key
azure_subscription_id: subscription_id
azure_tenant: tenant_id
azure_resource_group: dns_zone_resource_group
```

### Add okd4 support

cluster.yml example:
```
image_pull_secret: '{"auths":{"fake":{"auth": "bar"}}}'

openshift_version: 4.5.0-0.okd-2020-10-15-235428
openshift_location: https://github.com/openshift/okd/releases/download/{{ openshift_version }}
coreos_version: 32.20201004.3.0
coreos_download_url: https://builds.coreos.fedoraproject.org/prod/streams/stable/builds/32.20201004.3.0/x86_64/fedora-coreos-32.20201004.3.0-qemu.x86_64.qcow2.xz
coreos_csum_str: 5a4f80e85b66d3c7a0d5789d3f4f65d30a57871b6fe49dc791e490763f1eacdb
```

Thanks to @sandrich for contribution.

### Fixes

 * Fixed #123 useage of letsencrypt_account_email & cloudflare_account_email
 * add mode (0644) for ignition file
 * Update auth_htpasswd example with know password - because of #133
 * Add work-a-round for https://github.com/ansible/ansible/issues/71420
 * Fixed #125 Fresh centos 8.2 -- firewalld reload failed because "FirewallD is
   not running"

## 2020-09-24

### Update
README.md

### Added
docs/auth_passwd.md

images/auth_passwd.png

## 2020-07-30

### Bump OpenShift Version to 4.5.2

### feat(autostart): add autostart option for VMs

Added option `vm_autostart` default (false).

### Added docs/pci-passthrough.md

### Big fixes

 - fix(typo): correctly name identity_providers
 - Cleanup post install tag name use post-install instead of postinstall
 - Use --kubeconfig instead of --config
 - Fixed #116 - LE certificate is not configured after fresh installation.
 - Add daemon_reload to systemctl service installation
 - Update ansible repo for RHEL
 - Update docs/air-gapped.md
 - Add draft tekton pipeline to test hetzner-ocp4

## 2020-07-03

### Use GitHub as a possible IdP

You can now use GitHub as an IdP. In order to configure GitHub you have to add a new [OAuth App](https://github.com/settings/developers).

As a redirectUrl please set
`https://<your_public_domain>/oauth2callback/GitHub`

Be sure to only add one of of `organizations` or `teams` since the `teams` option already includes the information about the specific organizations.

### Add `dns_provider: none`

With `dns_provider: none` the playbooks will not create public dns entries. (It will skip letsencrypt too) Please create public dns entries if you want to access your cluster.

### Add `public_ip` option

Override for public ip entries. defaults to `hostvars['localhost']['ansible_default_ipv4']['address']`.


### Update Centos8

* Configure firewalld
* Fixed host prep (Add missing packages & documentation)

### Bugfixes

* Fix #100 - Compute nodes doesn't join at intallation
* Fix #101 by automating coreos crc
* Fix typos
* Fix(permissions): make all binaries are executable
* fix(sudoer): fix sudoers in cluster-example.yml

### Added some docs:

* [Hetzner & IPI](docs/ipi.md)
* [Disk management (add disk to vm, wipe node)](docs/disk-management.md)

## 2020-04-18

### Use RBAC instead of changing SCC member for NFS provisioner

Instead of
```
oc adm policy add-scc-to-user hostmount-anyuid \
    -n openshift-nfs-provisioner \
    -z nfs-client-provisioner
```
create a role  and a binding:
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: scc-hostmount-anyuid
  namespace: "openshift-nfs-provisioner"
rules:
- apiGroups:
  - security.openshift.io
  resourceNames:
  - hostmount-anyuid
  resources:
  - securitycontextconstraints
  verbs:
  - use
---
kind: RoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: sa-to-scc-hostmount-anyuid
  namespace: "openshift-nfs-provisioner"
subjects:
  - kind: ServiceAccount
    name: nfs-client-provisioner
roleRef:
  kind: Role
  name: scc-hostmount-anyuid
  apiGroup: rbac.authorization.k8s.io
```

## 2020-04-01

### Update air-gapped docs

Add `REGISTRY_COMPATIBILITY_SCHEMA1_ENABLED=true` to air-gapped registry. That solve some skopeo copy problemes.

### Support for disabling automatic Let's Encrypt certificates for apps and api

Add varialbe `letsencrypt_disabled: true` to cluster yaml to disable Let's Encrypt certificates. Variable defaults to true.

### Added release notes doc

Just simple doc to track new features and fixes.


