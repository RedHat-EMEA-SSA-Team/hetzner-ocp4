# How to install OKD

If you prefer to use [OKD](https://docs.okd.io/latest/welcome/index.html) instead of OCP you need to define the following variables inside your cluster.yml

```
image_pull_secret: '{"auths":{"fake":{"auth": "bar"}}}'

openshift_version: 4.5.0-0.okd-2020-10-15-235428
openshift_location: https://github.com/openshift/okd/releases/download/{{ openshift_version }}
coreos_version: 32.20201004.3.0
coreos_download_url: https://builds.coreos.fedoraproject.org/prod/streams/stable/builds/32.20201004.3.0/x86_64/fedora-coreos-32.20201004.3.0-qemu.x86_64.qcow2.xz
coreos_csum_str: 5a4f80e85b66d3c7a0d5789d3f4f65d30a57871b6fe49dc791e490763f1eacdb
```