# Disk management examples

## Attach a disk to VM:

```bash
export VM=clustername-compute-0

qemu-img create -f qcow2 /var/lib/libvirt/images/${VM}-disk2.qcow2 50g

virsh attach-disk ${VM} \
  --source /var/lib/libvirt/images/${VM}-disk2.qcow2 \
  --target vdb \
  --persistent \
  --subdriver qcow2 \
  --driver qemu \
  --type disk

```

## Detach a disk from VM

```bash
export VM=clustername-compute-0

virsh detach-disk ${VM} sdb

```

## Wipe to force reinstall the node

First of all, you need to have a login with `cluster-admin` at your cluster.

```bash
cd /var/lib/libvirt/images
ls -l rh*
export CLUSTERNAME=clustername
export NODE=compute-0
export VM=${CLUSTERNAME}-${NODE}
export RCOS_IMAGE=<rhcos-4.4.0.qcow2>

virsh destroy ${VM}
oc delete node ${NODE}
qemu-img create -f qcow2 -b ${RCOS_IMAGE} ${VM}.qcow2 120G

virsh start ${VM}

# Run several times (two CSR per node join)
oc get csr | awk '/Pending/ {print $1}' | xargs oc adm certificate approve
```

You can get the actual `qcow2` for your cluster by
```bash
oc -n openshift-machine-config-operator get configmap/coreos-bootimages -o jsonpath='{.data.stream}' | jq -r '.architectures.x86_64.artifacts.qemu.formats."qcow2.gz".disk.location'
https://rhcos.mirror.openshift.com/art/storage/prod/streams/4.14-9.2/builds/414.92.202402130420-0/x86_64/rhcos-414.92.202402130420-0-qemu.x86_64.qcow2.gz
IMAGE=`oc -n openshift-machine-config-operator get configmap/coreos-bootimages -o jsonpath='{.data.stream}' | jq -r '.architectures.x86_64.artifacts.qemu.formats."qcow2.gz".disk.location'`
gunzip `echo $IMAGE | cut -d/ -f12`
```

Or via openshift-install command:
```bash
$ openshift-install coreos print-stream-json | jq '.architectures.x86_64.artifacts.qemu.formats."qcow2.gz".disk.location'
"https://rhcos.mirror.openshift.com/art/storage/prod/streams/4.14-9.2/builds/414.92.202310210434-0/x86_64/rhcos-414.92.202310210434-0-qemu.x86_64.qcow2.gz"
```

Or via mirror.openshift.pub: https://mirror.openshift.com/pub/openshift-v4/dependencies/rhcos/4.15/4.15.0/rhcos-4.15.0-x86_64-qemu.x86_64.qcow2.gz

