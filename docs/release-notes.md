# RELEASE NOTES

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


