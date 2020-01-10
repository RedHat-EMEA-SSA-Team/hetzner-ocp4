# Air-gapped / disconnected

Some notes how you can setup a air-gapped / disconnected OpenShift 4 cluster with hetzner-ocp4

## Create network 

Create only the network, important to install and start the mirror registry add 
```
network_forward_mode: "route"
```
into `cluster.yml` and setup the network: 
```
./ansible/02-create-cluster.yml --tags network
```

## Setup mirror registry on kvm-host

Create host entry for image registry mirror: 
```
echo 192.168.50.1 host.compute.local >> /etc/hosts
```

Install & prepare image registry
```
yum -y install podman httpd-tools

mkdir -p /var/lib/libvirt/images/mirror-registry/{auth,certs,data}

openssl req -newkey rsa:4096 -nodes -sha256 \
  -keyout /var/lib/libvirt/images/mirror-registry/certs/domain.key \
  -x509 -days 365 -subj "/CN=host.compute.local" \
  -out /var/lib/libvirt/images/mirror-registry/certs/domain.crt 

cp -v /var/lib/libvirt/images/mirror-registry/certs/domain.crt /etc/pki/ca-trust/source/anchors/
update-ca-trust

htpasswd -bBc /var/lib/libvirt/images/mirror-registry/auth/htpasswd admin r3dh4t\!1
```

Create internal registry service: `/etc/systemd/system/mirror-registry.service`  
**Change REGISTRY_HTTP_ADDR in case you use different network**
```
[Unit]
Description=Mirror registry (mirror-registry)
After=network.target

[Service]
Type=simple
TimeoutStartSec=5m

ExecStartPre=-/usr/bin/podman rm "mirror-registry"
ExecStartPre=/usr/bin/podman pull quay.io/redhat-emea-ssa-team/registry:2
ExecStart=/usr/bin/podman run --name mirror-registry --net host \
  -v /var/lib/libvirt/images/mirror-registry/data:/var/lib/registry:z \
  -v /var/lib/libvirt/images/mirror-registry/auth:/auth:z \
  -e "REGISTRY_AUTH=htpasswd" \
  -e "REGISTRY_HTTP_ADDR=192.168.50.1:5000" \
  -e "REGISTRY_AUTH_HTPASSWD_REALM=registry-realm" \
  -e "REGISTRY_AUTH_HTPASSWD_PATH=/auth/htpasswd" \
  -v /var/lib/libvirt/images/mirror-registry/certs:/certs:z \
  -e REGISTRY_HTTP_TLS_CERTIFICATE=/certs/domain.crt \
  -e REGISTRY_HTTP_TLS_KEY=/certs/domain.key \
  quay.io/redhat-emea-ssa-team/registry:2

ExecReload=-/usr/bin/podman stop "mirror-registry"
ExecReload=-/usr/bin/podman rm "mirror-registry"
ExecStop=-/usr/bin/podman stop "mirror-registry"
Restart=always
RestartSec=30

[Install]
WantedBy=multi-user.target
```

Enable and start mirror registry
```
systemctl enable mirror-registry.service
systemctl start mirror-registry.service
systemctl status mirror-registry.service
```

Check registry
```
$ curl -u admin:r3dh4t\!1 https://host.compute.local:5000/v2/_catalog
{"repositories":[]}
```

Create mirror registry pullsecret
```
podman login --authfile mirror-registry-pullsecret.json host.compute.local:5000
```


## Download Red Hat pull secret

Download Red Hat pull secret and store it in `redhat-pullsecret.json`

## Mirror images

Merge  mirror-registry-pullsecret.json & redhat-pullsecret.json
```
jq -s '{"auths": ( .[0].auths + .[1].auths ) }' mirror-registry-pullsecret.json redhat-pullsecret.json > pullsecret.json
```

Mirror images:
```
export OCP_RELEASE=4.2.0
export LOCAL_REGISTRY='host.compute.local:5000' 
export LOCAL_REPOSITORY='ocp4/openshift4' 
export PRODUCT_REPO='openshift-release-dev' 
export LOCAL_SECRET_JSON='pullsecret.json' 
export RELEASE_NAME="ocp-release" 

oc adm -a ${LOCAL_SECRET_JSON} release mirror \
     --from=quay.io/${PRODUCT_REPO}/${RELEASE_NAME}:${OCP_RELEASE} \
     --to=${LOCAL_REGISTRY}/${LOCAL_REPOSITORY} \
     --to-release-image=${LOCAL_REGISTRY}/${LOCAL_REPOSITORY}:${OCP_RELEASE}
```

Save the output:
```
info: Mirroring completed in 57.1s (81.95MB/s)

Success
Update image:  host.compute.local:5000/ocp4/openshift4:4.2.0
Mirror prefix: host.compute.local:5000/ocp4/openshift4

To use the new mirrored repository to install, add the following section to the install-config.yaml:

imageContentSources:
- mirrors:
  - host.compute.local:5000/ocp4/openshift4
  source: quay.io/openshift-release-dev/ocp-release
- mirrors:
  - host.compute.local:5000/ocp4/openshift4
  source: quay.io/openshift-release-dev/ocp-v4.0-art-dev


To use the new mirrored repository for upgrades, use the following to create an ImageContentSourcePolicy:

apiVersion: operator.openshift.io/v1alpha1
kind: ImageContentSourcePolicy
metadata:
  name: example
spec:
  repositoryDigestMirrors:
  - mirrors:
    - host.compute.local:5000/ocp4/openshift4
    source: quay.io/openshift-release-dev/ocp-release
  - mirrors:
    - host.compute.local:5000/ocp4/openshift4
    source: quay.io/openshift-release-dev/ocp-v4.0-art-dev
```

Extract openshift-install command
```
oc adm release extract -a pullsecret.json --command=openshift-install "${LOCAL_REGISTRY}/${LOCAL_REPOSITORY}:${OCP_RELEASE}"
```

## Update cluster.yml

Add install_config_additionalTrustBundle and install_config_imageContentSources into cluster.yml.

```
# Path to extracted openshift-install command
openshift_install_command: "/root/hetzner-ocp4/openshift-install"
install_config_additionalTrustBundle: |
  # Content of /var/lib/libvirt/images/mirror-registry/certs/domain.crt
  -----BEGIN CERTIFICATE-----
  MIIEODCCAyCgAwIBAgIJAJhg5kZKGIs4MA0GCSqGSIb3DQEBCwUAMIGoMQswCQYD
  VQQGEwJERTEQMA4GA1UECAwHQmF2YXJpYTEPMA0GA1UEBwwGTXVuaWNoMRswGQYD
  VQQKDBJNeSBQcml2YXRlIFJvb3QgQ0ExGzAZBgNVBAsMEk15IFByaXZhdGUgUm9v
  dCBDQTEbMBkGA1UEAwwScm9vdGNhLmV4YW1wbGUuY29tMR8wHQYJKoZIhvcNAQkB
  FhBlbWFpbEBkb21haW4udGxkMB4XDTE5MTEyMDA5NDgzMloXDTM5MTExNTA5NDgz
  MlowgagxCzAJBgNVBAYTAkRFMRAwDgYDVQQIDAdCYXZhcmlhMQ8wDQYDVQQHDAZN
  dW5pY2gxGzAZBgNVBAoMEk15IFByaXZhdGUgUm9vdCBDQTEbMBkGA1UECwwSTXkg
  UHJpdmF0ZSBSb290IENBMRswGQYDVQQDDBJyb290Y2EuZXhhbXBsZS5jb20xHzAd
  BgkqhkiG9w0BCQEWEGVtYWlsQGRvbWFpbi50bGQwggEiMA0GCSqGSIb3DQEBAQUA
  A4IBDwAwggEKAoIBAQDaezXIWOyvKZSdeWRw0kurgyXattX5TTOyRE81h8C1+oX7
  Dcj0TPZ+kHrC5IrDgQkBLIJZLNe5zNWy+Jn+HJYwPN5c7nWmynW3ogNo8wvjviPk
  wRIjGbgTrHwViZV+05l09VM1I2dOfn0s0yzIlp8pw9COU2sJecFX2SDtQuIRHeWy
  +MpvtyAIqwublkGx07K430iqOt6mOOTGz7UDRLYADNFt+hPfuLHnodfMDZWKtNAG
  1iLJvlsgTQif6dY+4WoufPjZLSjQ93BSuafQf7H+D6UeaETAp187WtpRTf7WgH3h
  ipcnOXEcZmUeGppQxeI20qXbGjRg8e3/lq8A2Aj/AgMBAAGjYzBhMB0GA1UdDgQW
  BBQeCEiY4wVw6PcvjFHckxiokOSDazAfBgNVHSMEGDAWgBQeCEiY4wVw6PcvjFHc
  kxiokOSDazAPBgNVHRMBAf8EBTADAQH/MA4GA1UdDwEB/wQEAwIBhjANBgkqhkiG
  9w0BAQsFAAOCAQEAU2twrBbWKBODrdoyRNKWoVonDtNfGPjs+Ipz53FolZKPeJHA
  K0Sw/INT+U7/+p/S5lnYUpeRKlNVAeVSFbIvKHoymQF/oqZlRguHqZmmKQw2CMZK
  Gr34bhcbWD/Zn0EEYe9Dd4Lp2sDcvAmt4vPfxyNqNbCN3e1r52bIOvsT0kV5i4cf
  FducaYqL7UFfSUYsmcj0IbvWzgsHpLDWdnNqdMmcQ6GUBupqPAuP5BNxoEBQ/cVP
  OKKLYSijjJN0zXXF8irgvWxLHPU0N6u5ozd3n4FHTW4kLDjSTNTMuypk4jUqQhrJ
  8rnXNwLANMzPzZjnB+m+ruhITAppHIpdGYFSEw==
  -----END CERTIFICATE-----
install_config_imageContentSources:
- mirrors:
  - host.compute.local:5000/ocp4/openshift4
  source: quay.io/openshift-release-dev/ocp-release
- mirrors:
  - host.compute.local:5000/ocp4/openshift4
  source: quay.io/openshift-release-dev/ocp-v4.0-art-dev

image_pull_secret: |
  {"auths":{"host.compute.local:5000":{"auth":"YWRtaW46cjNkaDR0ITE="}}}
```

## Install cluster

```
./ansible/02-create-cluster.yml
```

## Sync Operatorhub

It's difficult with OpenShift 4.2, [official documentation](https://docs.openshift.com/container-platform/4.2/operators/olm-restricted-networks.html)


