# How to use PCI(e) passthrough (disks, gpu,..)


## Enable `intel_iommu=on`

Adjust `/etc/default/grub`, addd `intel_iommu=on` to `GRUB_CMDLINE_LINUX`

Example `/etc/default/grub`
```
GRUB_TIMEOUT=5
GRUB_DISTRIBUTOR="$(sed 's, release .*$,,g' /etc/system-release)"
GRUB_DEFAULT=saved
GRUB_DISABLE_SUBMENU=true
GRUB_TERMINAL_OUTPUT="console"
GRUB_CMDLINE_LINUX="crashkernel=auto resume=UUID=79ee11ae-6bcd-4785-9087-30e46ded4abf rhgb quiet intel_iommu=on"
GRUB_DISABLE_RECOVERY="true"
GRUB_ENABLE_BLSCFG=true
````

Run 
```bash
grub2-mkconfig -o /boot/grub2/grub.cfg
```

##  Configure vfio

```bash

$ lspci -nn | grep -E -i '(nvidia|ssd)'
03:00.0 3D controller [0302]: NVIDIA Corporation GK110GL [Tesla K20Xm] [10de:1021] (rev a1)
05:00.0 Non-Volatile memory controller [0108]: Intel Corporation PCIe Data Center SSD [8086:0953] (rev 01)
82:00.0 Non-Volatile memory controller [0108]: Intel Corporation PCIe Data Center SSD [8086:0953] (rev 01)
83:00.0 Non-Volatile memory controller [0108]: Intel Corporation PCIe Data Center SSD [8086:0953] (rev 01)

$ vi /etc/modprobe.d/vfio.conf

# create new : for [ids=***], specify [vendor-ID:device-ID]
options vfio-pci ids=8086:0953,10de:1021

$ echo 'vfio-pci' > /etc/modules-load.d/vfio-pci.conf

```

## Reboot 

```bash
$ reboot -h now
```


## Attach disk to domain/VM


```
$ virst start storm4-compute-0

# Find pci device: 03:00.0
$ virsh nodedev-list | grep -E '(03|05|82|83)_00_0'
pci_0000_03_00_0
pci_0000_05_00_0
pci_0000_82_00_0
pci_0000_83_00_0

$ virsh nodedev-list | grep -E '(03|05|82|83)_00_0' | xargs -n1 virsh nodedev-detach 

$ cat - >storm6-compute-0.pci <<EOF
<hostdev mode='subsystem' type='pci' managed='no'>
  <driver name='vfio'/>
  <source>
    <address domain='0x0000' bus='0x05' slot='0x00' function='0x0'/>
  </source>
</hostdev>
EOF

$ cat -  >storm6-compute-1.pci <<EOF
<hostdev mode='subsystem' type='pci' managed='no'>
  <driver name='vfio'/>
  <source>
    <address domain='0x0000' bus='0x82' slot='0x00' function='0x0'/>
  </source>
</hostdev>
EOF

$ cat -  >storm6-compute-2.pci <<EOF
<hostdev mode='subsystem' type='pci' managed='no'>
  <driver name='vfio'/>
  <source>
    <address domain='0x0000' bus='0x83' slot='0x00' function='0x0'/>
  </source>
</hostdev>
EOF

# Takes a while...
$ virsh attach-device --persistent storm6-compute-0 storm6-compute-0.pci
$ virsh attach-device --persistent storm6-compute-1 storm6-compute-1.pci
$ virsh attach-device --persistent storm6-compute-2 storm6-compute-2.pci


# GPU to node 0
$ cat -  >storm6-compute-0-gpu.pci <<EOF
<hostdev mode='subsystem' type='pci' managed='no'>
  <driver name='vfio'/>
  <source>
    <address domain='0x0000' bus='0x03' slot='0x00' function='0x0'/>
  </source>
</hostdev>
EOF

$ virsh attach-device --persistent storm6-compute-0 storm6-compute-0-gpu.pci

```