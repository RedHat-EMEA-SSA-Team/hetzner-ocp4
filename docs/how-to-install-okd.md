# How to install OKD

If you prefer to use [OKD](https://docs.okd.io/latest/welcome/index.html) instead of OCP you need to define the following variables inside your cluster.yml

```yaml
image_pull_secret: '{"auths":{"fake":{"auth": "bar"}}}'

cluster_name: okd

openshift_version: 4.7.0-0.okd-2021-07-03-190901
openshift_location: "https://github.com/openshift/okd/releases/download/{{ openshift_version }}"
coreos_version: 34.20210611.3.0
coreos_download_url: "https://builds.coreos.fedoraproject.org/prod/streams/stable/builds/{{ coreos_version }}/x86_64/fedora-coreos-{{ coreos_version }}-qemu.x86_64.qcow2.xz"
coreos_csum_str: 9a362a7b13e213d8fb01d4c371c3f99893e6a418a60eff650b734c9683f1b06f


opm_version: "1.17.4"
opm_download_url: "https://github.com/operator-framework/operator-registry/releases/download/v{{ opm_version }}/linux-amd64-opm"
opm_dest: "/opt/operator-registry-{{ opm_version }}/"
```