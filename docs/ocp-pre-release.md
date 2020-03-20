# How to use prerelease

Add to `cluster.yml`:

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
