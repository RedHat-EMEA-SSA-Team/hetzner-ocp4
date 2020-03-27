# How to use prerelease

When using pre-releases check before installation that version match.


Add to `cluster.yml`:

## 4.5 dev preview

```
# reference to OpenShift version
openshift_version: 4.5.0-0.nightly-2020-03-18-092618
# client versions, oc and openshift-install
openshift_location: "https://mirror.openshift.com/pub/openshift-v4/clients/ocp-dev-preview/{{ openshift_version }}"

# reference to coreos qcow file
coreos_version: 4.5.0-0.nightly-2020-03-18-115438

coreos_download_url: "https://mirror.openshift.com/pub/openshift-v4/dependencies/rhcos/{{ coreos_version.split('.')[:2]|join('.') }}/latest/rhcos-{{coreos_version}}-x86_64-qemu.x86_64.qcow2.gz"
coreos_checksum: "5e6858e0362b7cd6129bf67ab215a594dde1280f"
```

## 4.4 RC 1

```
# reference to OpenShift version
openshift_version: 4.4.0-rc.1

# reference to coreos qcow file
coreos_version: 4.4.0-rc.1

coreos_download_url: "https://mirror.openshift.com/pub/openshift-v4/dependencies/rhcos/{{ coreos_version.split('.')[:2]|join('.') }}/latest/rhcos-{{coreos_version}}-x86_64-qemu.x86_64.qcow2.gz"
coreos_checksum: "ce3fddeb4d362b917a40fb02ba30dc4da1df695a"
```
