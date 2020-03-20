# How to use prerelease

Add to `cluster.yml`:

```
# reference to OpenShift version
openshift_version: 4.4.0-0.nightly-2020-02-13-180133
openshift_install_command: "/opt/openshift-install-{{ openshift_version }}/openshift-install"
# dev-pre:
# https://mirror.openshift.com/pub/openshift-v4/clients/ocp-dev-preview
openshift_location: "https://mirror.openshift.com/pub/openshift-v4/clients/ocp-dev-preview"

# reference to coreos qcow file
coreos_version: 44.81.202002161330-0
# curl -L -O https://releases-rhcos-art.cloud.privileged.psi.redhat.com/storage/releases/rhcos-4.4/44.81.202002161330-0/x86_64/rhcos-44.81.202002161330-0-qemu.x86_64.qcow2.gz
coreos_download_url: "https://releases-rhcos-art.cloud.privileged.psi.redhat.com/storage/releases/rhcos-4.4/44.81.202002161330-0/x86_64/rhcos-44.81.202002161330-0-qemu.x86_64.qcow2.gz"
# How to get the checksum:
#  ansible -m stat -a 'path=/var/lib/libvirt/images/rhcos-4.3.0.qcow2' localhost  | grep checksum
coreos_checksum: "5f2ab3ac96d8134b9010740699465ff0fd99abff"
coreos_image_location: /var/lib/libvirt/images/rhcos-{{ coreos_version }}.qcow2 
```