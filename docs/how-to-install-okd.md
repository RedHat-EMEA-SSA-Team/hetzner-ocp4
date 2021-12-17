# How to install OKD

If you prefer to use [OKD](https://docs.okd.io/latest/welcome/index.html) instead of OCP you need to define the following variables inside your cluster.yml

```yaml
image_pull_secret: '{"auths":{"fake":{"auth": "bar"}}}'

cluster_name: okd

openshift_version:  4.8.0-0.okd-2021-10-01-221835
openshift_location: https://github.com/openshift/okd/releases/download/{{ openshift_version }}
coreos_version: 34.20210904.3.0
coreos_download_url: https://builds.coreos.fedoraproject.org/prod/streams/stable/builds/{{ coreos_version }}/x86_64/fedora-coreos-{{ coreos_version }}-qemu.x86_64.qcow2.xz
coreos_csum_str: 58e9e841a42944c616925deaa11849881c9cfc47e7d2116bc3c2c9985fea632a

opm_version: "1.19.0"
opm_download_url: "https://github.com/operator-framework/operator-registry/releases/download/v{{ opm_version }}/linux-amd64-opm"
opm_dest: "/opt/operator-registry-{{ opm_version }}/"
```

Instead of the above image_pull_secret, it can also be included the same one that would be required for the Openshift Installation. This would allow for later enablement of CatalogSources redhat-marketplace, redhat-operators and certified-operators.
However, after cluster installation, they must be disabled and enabled again.