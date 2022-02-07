# Container-native virtualization
## Check nested  virtualization at kvm-host (intel)

```
cat /sys/module/kvm_intel/parameters/nested
```

## Enable nested virtualization at kvm-host (intel)

Adjust `/etc/modprobe.d/kvm.conf`
```
options kvm_intel nested=1
```
and reboot.

## Options in your cluster.yml to enable nested virtualization

```
# Up to you ;-)
compute_count: 2
compute_vcpu: 8
master_vcpu: 8
# Important:
compute_special_cpu: "<cpu mode='host-passthrough'></cpu>"
master_special_cpu: "<cpu mode='host-passthrough'></cpu>"
```

If you want to use Advanced Cluster Security for Kubernetes you must also set the cpu mode `host-passthrough`. Otherwise, with the default vm settings, the central container will start with the error that the SSE 4.2 instruction set is not available.

## Install CNV via OperatorHub

Follow the public documentation.

## Examples

### Start a VM from a PVC
```
oc create -f - <<EOF
apiVersion: kubevirt.io/v1alpha3
kind: VirtualMachine
metadata:
  labels:
    kubevirt.io/vm: windows
  name: windows
spec:
  running: false
  template:
    metadata:
      labels:
        kubevirt.io/vm: windows
    spec:
      domain:
        devices:
          disks:
          - name: windows
            disk: {}
          interfaces:
          - bridge: {}
            name: default
          - bridge: {}
            name: public
        machine:
          type: ""
        resources:
          requests:
            memory: 8092M
      terminationGracePeriodSeconds: 0
      networks:
      - name: default
        pod: {}
      - multus:
          networkName: extra-network-1
        name: public
      volumes:
      - name: windows
        persistentVolumeClaim:
          claimName: win19
EOF
```
