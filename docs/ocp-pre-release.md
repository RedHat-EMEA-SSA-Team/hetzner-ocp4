# How to use prerelease

When using pre-releases check before installation that version match.


Add to `cluster.yml`:

## 4.5 dev preview

```
# reference to OpenShift version
openshift_version: 4.5
# reference to coreos qcow file
coreos_version: 4.5.0-0.nightly-2020-03-18-115438-x86_64-qemu.x86_64
# client versions, oc and openshift-install
openshift_client_version: 4.5-nightly
openshift_location: https://mirror.openshift.com/pub/openshift-v4/clients/ocp-dev-preview/latest-4.5
# How to get the checksum:
#  ansible -m stat -a 'path=/var/lib/libvirt/images/rhcos-4.4.0-rc.1-x86_64-qemu.x86_64.qcow2' localhost  | grep checksum
coreos_checksum: "5e6858e0362b7cd6129bf67ab215a594dde1280f"
```

## 4.4 RC 1

```
# reference to OpenShift version
openshift_version: 4.4
# reference to coreos qcow file
coreos_version: 4.4.0-rc.1-x86_64-qemu.x86_64
# client versions, oc and openshift-install
openshift_client_version: 4.4.0-rc.1
# How to get the checksum:
#  ansible -m stat -a 'path=/var/lib/libvirt/images/rhcos-4.4.0-rc.1-x86_64-qemu.x86_64.qcow2' localhost  | grep checksum
coreos_checksum: "ce3fddeb4d362b917a40fb02ba30dc4da1df695a"
```
