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

```bash
export CLUSTERNAME=clustername
export NODE=compute-0
export VM=${CLUSTERNAME}-${NODE}
export RCOS_IMAGE=rhcos-4.4.0.qcow2

virsh destroy ${VM}
oc delete node ${NODE}
qemu-img create -f qcow2 -b ${RCOS_IMAGE} ${VM}.qcow2 120G

virsh start ${VM}

# Run several times (two CSR per node join)
oc get csr | awk '/Pending/ {print $1}' | xargs oc adm certificate approve
```

