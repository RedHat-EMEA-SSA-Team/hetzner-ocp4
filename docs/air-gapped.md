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

### via Office quay mirror registry

https://docs.openshift.com/container-platform/4.9/installing/installing-mirroring-installation-images.html#mirror-registry

```
./docs/air-gapped/setup-registry.yam

./mirror-registry install \
  --quayHostname host.compute.local:5000 \
  --quayRoot /var/lib/libvirt/images/mirror-registry/quay/ \
  --ssh-key /root/.ssh/id_rsa \
  --sslKey /var/lib/libvirt/images/mirror-registry/certs/registry.key \
  --sslCert /var/lib/libvirt/images/mirror-registry/certs/registry.crt \
  --initPassword r3dh4t\!1
```

### via Docker registry

```
./docs/air-gapped/setup-registry.yaml
```

Check registry
```
$ curl -u admin:r3dh4t\!1 https://host.compute.local:5000/v2/_catalog
{"repositories":[]}
```

Create mirror registry pullsecret
```
podman login --username admin --password r3dh4t\!1 \
  --authfile mirror-registry-pullsecret.json \
  host.compute.local:5000
```


## Download Red Hat pull secret

Download Red Hat pull secret and store it in `redhat-pullsecret.json`

## Mirror images

Merge  mirror-registry-pullsecret.json & redhat-pullsecret.json
```
jq -s '{"auths": ( .[0].auths + .[1].auths ) }' mirror-registry-pullsecret.json redhat-pullsecret.json > pullsecret.json
```

Install oc client
```
./ansible/02-create-cluster.yml --tags download-openshift-artifacts
```

Mirror images:
```
export OCP_RELEASE=$(oc version -o json  --client | jq -r '.releaseClientVersion')
export LOCAL_REGISTRY='host.compute.local:5000'
export LOCAL_REPOSITORY='ocp4/openshift4'
export PRODUCT_REPO='openshift-release-dev'
export LOCAL_SECRET_JSON='pullsecret.json'
export RELEASE_NAME="ocp-release"
export ARCHITECTURE=x86_64
# export REMOVABLE_MEDIA_PATH=<path>

# Try run:

oc adm release mirror \
  --registry-config ${LOCAL_SECRET_JSON} \
  --from quay.io/${PRODUCT_REPO}/${RELEASE_NAME}:${OCP_RELEASE}-${ARCHITECTURE} \
  --to ${LOCAL_REGISTRY}/${LOCAL_REPOSITORY} \
  --to-release-image ${LOCAL_REGISTRY}/${LOCAL_REPOSITORY}:${OCP_RELEASE}-${ARCHITECTURE} \
  --dry-run

oc adm release mirror \
  --registry-config ${LOCAL_SECRET_JSON} \
  --from quay.io/${PRODUCT_REPO}/${RELEASE_NAME}:${OCP_RELEASE}-${ARCHITECTURE} \
  --to ${LOCAL_REGISTRY}/${LOCAL_REPOSITORY} \
  --to-release-image ${LOCAL_REGISTRY}/${LOCAL_REPOSITORY}:${OCP_RELEASE}-${ARCHITECTURE}
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
oc adm release extract -a pullsecret.json --command=openshift-install "${LOCAL_REGISTRY}/${LOCAL_REPOSITORY}:${OCP_RELEASE}-${ARCHITECTURE}"
```

Check openshift-install version:
```
# ./openshift-install version
./openshift-install 4.9.11
built from commit 4ee186bb88bf6aeef8ccffd0b5d4e98e9ddd895f
release image host.compute.local:5000/ocp4/openshift4@sha256:0f72e150329db15279a1aeda1286c9495258a4892bc5bf1bf5bb89942cd432de
release architecture amd64
```

## Update cluster.yml

Add `install_config_additionalTrustBundle` and `install_config_imageContentSources` into cluster.yml.

```
# Path to extracted openshift-install command
openshift_install_command: "/root/hetzner-ocp4/openshift-install"
install_config_additionalTrustBundle: |
  # Content of /var/lib/libvirt/images/mirror-registry/certs/ca.crt
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

# cat mirror-registry-pullsecret.json | jq -c -r
image_pull_secret: |
  {"auths":{"host.compute.local:5000":{"auth":"YWRtaW46cjNkaDR0ITE="}}}
```

## Install cluster

```
./ansible/02-create-cluster.yml
```

## Sync Operatorhub

Not all operators support disconnected environments: [Red Hat Operators Supported in Disconnected Mode](https://access.redhat.com/articles/4740011)

How to sync operators with OpenShift 4.8: [official documentation](https://docs.openshift.com/container-platform/4.8/operators/admin/olm-restricted-networks.html)


### run index

```
podman run -p50051:50051 \
  --authfile $LOCAL_SECRET_JSON \
  registry.redhat.io/redhat/redhat-operator-index:v4.8
```

### Export names

grpcurl -plaintext localhost:50051 api.Registry/ListPackages > packages.out

## Sync image for `oc debug node/`

```
oc image mirror -a ${LOCAL_SECRET_JSON} \
  registry.redhat.io/rhel7/support-tools:latest \
  ${LOCAL_REGISTRY}/rhel7/support-tools:latest

oc debug node/compute-0 --image=${LOCAL_REGISTRY}/rhel7/support-tools:latest
```


## If `storage_nfs: true`

1) Copy nfs-client-provisioner image
    ```bash
    oc image mirror -a ${LOCAL_SECRET_JSON} \
      quay.io/external_storage/nfs-client-provisioner:latest \
      ${LOCAL_REGISTRY}/${LOCAL_REPOSITORY}:nfs-client-provisioner-latest
    ```

    or with skopoe:
    ```
    skopeo copy \
      --authfile=${LOCAL_SECRET_JSON} \
      docker://quay.io/external_storage/nfs-client-provisioner:latest \
      docker://${LOCAL_REGISTRY}/${LOCAL_REPOSITORY}:nfs-client-provisioner-latest
    ```

2) Patch nfs provisioner deployment
    ```bash
      oc patch -n openshift-nfs-provisioner deployment.apps/nfs-client-provisioner \
        --patch "{\"spec\":{\"template\":{\"spec\":{\"containers\":[{\"name\":\"nfs-client-provisioner\",\"image\":\"${LOCAL_REGISTRY}/${LOCAL_REPOSITORY}:nfs-client-provisioner-latest\"}]}}}}"
    ```


## Sample operator

Documentation: [Using Samples Operator imagestreams with alternate or mirrored registries](https://docs.openshift.com/container-platform/4.9/openshift_images/samples-operator-alt-registry.html#installation-restricted-network-samples_samples-operator-alt-registry)

Warning: Sync all examples takes a while!

**Remember: A lot of examples need a git repo to, don't forget to sync those!**
To get an repo overview: `oc get is -n openshift -o json | jq -r '.items[].spec.tags[].annotations.sampleRepo' | sort -u`

```
# Get a list
# oc get is -n openshift -o json | jq -r '.items[].spec.tags[].from.name' | grep registry.redhat.io

export IMAGES="registry.redhat.io/3scale-amp21/apicast-gateway:1.4-2
registry.redhat.io/3scale-amp22/apicast-gateway:1.8
registry.redhat.io/3scale-amp23/apicast-gateway
registry.redhat.io/3scale-amp24/apicast-gateway
registry.redhat.io/3scale-amp25/apicast-gateway
registry.redhat.io/3scale-amp26/apicast-gateway
registry.redhat.io/fuse7/fuse-apicurito:1.2
registry.redhat.io/fuse7/fuse-apicurito:1.3
registry.redhat.io/fuse7/fuse-apicurito:1.4
registry.redhat.io/dotnet/dotnet-21-rhel7:2.1
registry.redhat.io/dotnet/dotnet-22-rhel7:2.2
registry.redhat.io/dotnet/dotnet-30-rhel7:3.0
registry.redhat.io/dotnet/dotnet-21-runtime-rhel7:2.1
registry.redhat.io/dotnet/dotnet-22-runtime-rhel7:2.2
registry.redhat.io/dotnet/dotnet-30-runtime-rhel7:3.0
registry.redhat.io/jboss-eap-7-tech-preview/eap-cd-openshift:12.0
registry.redhat.io/jboss-eap-7-tech-preview/eap-cd-openshift:13.0
registry.redhat.io/jboss-eap-7-tech-preview/eap-cd-openshift:14.0
registry.redhat.io/jboss-eap-7-tech-preview/eap-cd-openshift:15.0
registry.redhat.io/jboss-eap-7-tech-preview/eap-cd-openshift:16.0
registry.redhat.io/jboss-eap-7-tech-preview/eap-cd-openshift-rhel8:17.0
registry.redhat.io/jboss-eap-7-tech-preview/eap-cd-openshift-rhel8:latest
registry.redhat.io/jboss-fuse-6/fis-java-openshift:1.0
registry.redhat.io/jboss-fuse-6/fis-java-openshift:2.0
registry.redhat.io/jboss-fuse-6/fis-karaf-openshift:1.0
registry.redhat.io/jboss-fuse-6/fis-karaf-openshift:2.0
registry.redhat.io/fuse7/fuse-apicurito-generator:1.2
registry.redhat.io/fuse7/fuse-apicurito-generator:1.3
registry.redhat.io/fuse7/fuse-apicurito-generator:1.4
registry.redhat.io/fuse7/fuse-console:1.0
registry.redhat.io/fuse7/fuse-console:1.1
registry.redhat.io/fuse7/fuse-console:1.2
registry.redhat.io/fuse7/fuse-console:1.3
registry.redhat.io/fuse7/fuse-console:1.4
registry.redhat.io/fuse7/fuse-eap-openshift:1.0
registry.redhat.io/fuse7/fuse-eap-openshift:1.1
registry.redhat.io/fuse7/fuse-eap-openshift:1.2
registry.redhat.io/fuse7/fuse-eap-openshift:1.3
registry.redhat.io/fuse7/fuse-eap-openshift:1.4
registry.redhat.io/fuse7/fuse-java-openshift:1.0
registry.redhat.io/fuse7/fuse-java-openshift:1.1
registry.redhat.io/fuse7/fuse-java-openshift:1.2
registry.redhat.io/fuse7/fuse-java-openshift:1.3
registry.redhat.io/fuse7/fuse-java-openshift:1.4
registry.redhat.io/fuse7/fuse-karaf-openshift:1.0
registry.redhat.io/fuse7/fuse-karaf-openshift:1.1
registry.redhat.io/fuse7/fuse-karaf-openshift:1.2
registry.redhat.io/fuse7/fuse-karaf-openshift:1.3
registry.redhat.io/fuse7/fuse-karaf-openshift:1.4
registry.redhat.io/devtools/go-toolset-rhel7:1.11.5
registry.redhat.io/rhscl/httpd-24-rhel7
registry.redhat.io/openjdk/openjdk-11-rhel7:latest
registry.redhat.io/redhat-openjdk-18/openjdk18-openshift:latest
registry.redhat.io/jboss-amq-6/amq62-openshift:1.1
registry.redhat.io/jboss-amq-6/amq62-openshift:1.2
registry.redhat.io/jboss-amq-6/amq62-openshift:1.3
registry.redhat.io/jboss-amq-6/amq62-openshift:1.4
registry.redhat.io/jboss-amq-6/amq62-openshift:1.5
registry.redhat.io/jboss-amq-6/amq62-openshift:1.6
registry.redhat.io/jboss-amq-6/amq62-openshift:1.7
registry.redhat.io/jboss-amq-6/amq63-openshift:1.0
registry.redhat.io/jboss-amq-6/amq63-openshift:1.1
registry.redhat.io/jboss-amq-6/amq63-openshift:1.2
registry.redhat.io/jboss-amq-6/amq63-openshift:1.3
registry.redhat.io/jboss-amq-6/amq63-openshift:1.4
registry.redhat.io/jboss-datagrid-6/datagrid65-client-openshift:1.0
registry.redhat.io/jboss-datagrid-6/datagrid65-client-openshift:1.1
registry.redhat.io/jboss-datagrid-6/datagrid65-openshift:1.2
registry.redhat.io/jboss-datagrid-6/datagrid65-openshift:1.3
registry.redhat.io/jboss-datagrid-6/datagrid65-openshift:1.4
registry.redhat.io/jboss-datagrid-6/datagrid65-openshift:1.5
registry.redhat.io/jboss-datagrid-6/datagrid65-openshift:1.6
registry.redhat.io/jboss-datagrid-7/datagrid71-client-openshift:1.0
registry.redhat.io/jboss-datagrid-7/datagrid71-openshift:1.0
registry.redhat.io/jboss-datagrid-7/datagrid71-openshift:1.1
registry.redhat.io/jboss-datagrid-7/datagrid71-openshift:1.2
registry.redhat.io/jboss-datagrid-7/datagrid71-openshift:1.3
registry.redhat.io/jboss-datagrid-7/datagrid72-openshift:1.0
registry.redhat.io/jboss-datagrid-7/datagrid72-openshift:1.1
registry.redhat.io/jboss-datagrid-7/datagrid72-openshift:1.2
registry.redhat.io/jboss-datagrid-7/datagrid73-openshift:1.0
registry.redhat.io/jboss-datagrid-7/datagrid73-openshift:1.1
registry.redhat.io/jboss-datavirt-6/datavirt64-driver-openshift:1.0
registry.redhat.io/jboss-datavirt-6/datavirt64-driver-openshift:1.1
registry.redhat.io/jboss-datavirt-6/datavirt64-driver-openshift:1.2
registry.redhat.io/jboss-datavirt-6/datavirt64-driver-openshift:1.3
registry.redhat.io/jboss-datavirt-6/datavirt64-driver-openshift:1.4
registry.redhat.io/jboss-datavirt-6/datavirt64-driver-openshift:1.5
registry.redhat.io/jboss-datavirt-6/datavirt64-driver-openshift:1.6
registry.redhat.io/jboss-datavirt-6/datavirt64-driver-openshift:1.7
registry.redhat.io/jboss-datavirt-6/datavirt64-openshift:1.0
registry.redhat.io/jboss-datavirt-6/datavirt64-openshift:1.1
registry.redhat.io/jboss-datavirt-6/datavirt64-openshift:1.2
registry.redhat.io/jboss-datavirt-6/datavirt64-openshift:1.3
registry.redhat.io/jboss-datavirt-6/datavirt64-openshift:1.4
registry.redhat.io/jboss-datavirt-6/datavirt64-openshift:1.5
registry.redhat.io/jboss-datavirt-6/datavirt64-openshift:1.6
registry.redhat.io/jboss-datavirt-6/datavirt64-openshift:1.7
registry.redhat.io/jboss-decisionserver-6/decisionserver64-openshift:1.0
registry.redhat.io/jboss-decisionserver-6/decisionserver64-openshift:1.1
registry.redhat.io/jboss-decisionserver-6/decisionserver64-openshift:1.2
registry.redhat.io/jboss-decisionserver-6/decisionserver64-openshift:1.3
registry.redhat.io/jboss-decisionserver-6/decisionserver64-openshift:1.4
registry.redhat.io/jboss-decisionserver-6/decisionserver64-openshift:1.5
registry.redhat.io/jboss-decisionserver-6/decisionserver64-openshift:1.6
registry.redhat.io/jboss-eap-6/eap64-openshift:1.1
registry.redhat.io/jboss-eap-6/eap64-openshift:1.2
registry.redhat.io/jboss-eap-6/eap64-openshift:1.3
registry.redhat.io/jboss-eap-6/eap64-openshift:1.4
registry.redhat.io/jboss-eap-6/eap64-openshift:1.5
registry.redhat.io/jboss-eap-6/eap64-openshift:1.6
registry.redhat.io/jboss-eap-6/eap64-openshift:1.7
registry.redhat.io/jboss-eap-6/eap64-openshift:1.8
registry.redhat.io/jboss-eap-6/eap64-openshift:1.9
registry.redhat.io/jboss-eap-6/eap64-openshift:latest
registry.redhat.io/jboss-eap-7/eap70-openshift:1.3
registry.redhat.io/jboss-eap-7/eap70-openshift:1.4
registry.redhat.io/jboss-eap-7/eap70-openshift:1.5
registry.redhat.io/jboss-eap-7/eap70-openshift:1.6
registry.redhat.io/jboss-eap-7/eap70-openshift:1.7
registry.redhat.io/jboss-eap-7/eap71-openshift:1.1
registry.redhat.io/jboss-eap-7/eap71-openshift:1.2
registry.redhat.io/jboss-eap-7/eap71-openshift:1.3
registry.redhat.io/jboss-eap-7/eap71-openshift:1.4
registry.redhat.io/jboss-eap-7/eap71-openshift:latest
registry.redhat.io/jboss-eap-7/eap72-openshift:1.0
registry.redhat.io/jboss-eap-7/eap72-openshift:1.1
registry.redhat.io/jboss-eap-7/eap72-openshift:latest
registry.redhat.io/fuse7/fuse-console:1.0
registry.redhat.io/fuse7/fuse-eap-openshift:1.0
registry.redhat.io/fuse7/fuse-java-openshift:1.0
registry.redhat.io/fuse7/fuse-karaf-openshift:1.0
registry.redhat.io/jboss-processserver-6/processserver64-openshift:1.0
registry.redhat.io/jboss-processserver-6/processserver64-openshift:1.1
registry.redhat.io/jboss-processserver-6/processserver64-openshift:1.2
registry.redhat.io/jboss-processserver-6/processserver64-openshift:1.3
registry.redhat.io/jboss-processserver-6/processserver64-openshift:1.4
registry.redhat.io/jboss-processserver-6/processserver64-openshift:1.5
registry.redhat.io/jboss-processserver-6/processserver64-openshift:1.6
registry.redhat.io/jboss-webserver-3/webserver30-tomcat7-openshift:1.1
registry.redhat.io/jboss-webserver-3/webserver30-tomcat7-openshift:1.2
registry.redhat.io/jboss-webserver-3/webserver30-tomcat7-openshift:1.3
registry.redhat.io/jboss-webserver-3/webserver30-tomcat8-openshift:1.1
registry.redhat.io/jboss-webserver-3/webserver30-tomcat8-openshift:1.2
registry.redhat.io/jboss-webserver-3/webserver30-tomcat8-openshift:1.3
registry.redhat.io/jboss-webserver-3/webserver31-tomcat7-openshift:1.0
registry.redhat.io/jboss-webserver-3/webserver31-tomcat7-openshift:1.1
registry.redhat.io/jboss-webserver-3/webserver31-tomcat7-openshift:1.2
registry.redhat.io/jboss-webserver-3/webserver31-tomcat7-openshift:1.3
registry.redhat.io/jboss-webserver-3/webserver31-tomcat7-openshift:1.4
registry.redhat.io/jboss-webserver-3/webserver31-tomcat8-openshift:1.0
registry.redhat.io/jboss-webserver-3/webserver31-tomcat8-openshift:1.1
registry.redhat.io/jboss-webserver-3/webserver31-tomcat8-openshift:1.2
registry.redhat.io/jboss-webserver-3/webserver31-tomcat8-openshift:1.3
registry.redhat.io/jboss-webserver-3/webserver31-tomcat8-openshift:1.4
registry.redhat.io/jboss-webserver-5/webserver50-tomcat9-openshift:1.0
registry.redhat.io/jboss-webserver-5/webserver50-tomcat9-openshift:1.1
registry.redhat.io/jboss-webserver-5/webserver50-tomcat9-openshift:1.2
registry.redhat.io/jboss-webserver-5/webserver50-tomcat9-openshift:latest
registry.redhat.io/rhscl/mariadb-102-rhel7:latest
registry.redhat.io/rhoar-nodejs-tech-preview/rhoar-nodejs-10-webapp
registry.redhat.io/rhscl/mongodb-32-rhel7:latest
registry.redhat.io/rhscl/mongodb-34-rhel7:latest
registry.redhat.io/rhscl/mongodb-36-rhel7:latest
registry.redhat.io/rhscl/mysql-57-rhel7:latest
registry.redhat.io/rhscl/mysql-80-rhel7:latest
registry.redhat.io/rhscl/nginx-110-rhel7:latest
registry.redhat.io/rhscl/nginx-112-rhel7:latest
registry.redhat.io/rhoar-nodejs/nodejs-10
registry.redhat.io/rhscl/nodejs-10-rhel7
registry.redhat.io/rhscl/nodejs-8-rhel7:latest
registry.redhat.io/rhoar-nodejs/nodejs-8
registry.redhat.io/openjdk/openjdk-11-rhel7:1.0
registry.redhat.io/rhscl/perl-524-rhel7:latest
registry.redhat.io/rhscl/perl-526-rhel7:latest
registry.redhat.io/rhscl/php-70-rhel7:latest
registry.redhat.io/rhscl/php-71-rhel7:latest
registry.redhat.io/rhscl/php-72-rhel7:latest
registry.redhat.io/rhscl/postgresql-10-rhel7:latest
registry.redhat.io/rhscl/postgresql-96-rhel7:latest
registry.redhat.io/rhscl/python-27-rhel7:latest
registry.redhat.io/rhscl/python-35-rhel7:latest
registry.redhat.io/rhscl/python-36-rhel7:latest
registry.redhat.io/redhat-openjdk-18/openjdk18-openshift:1.0
registry.redhat.io/redhat-openjdk-18/openjdk18-openshift:1.1
registry.redhat.io/redhat-openjdk-18/openjdk18-openshift:1.2
registry.redhat.io/redhat-openjdk-18/openjdk18-openshift:1.3
registry.redhat.io/redhat-openjdk-18/openjdk18-openshift:1.4
registry.redhat.io/redhat-openjdk-18/openjdk18-openshift:1.5
registry.redhat.io/redhat-sso-7/sso70-openshift:1.3
registry.redhat.io/redhat-sso-7/sso70-openshift:1.4
registry.redhat.io/redhat-sso-7/sso71-openshift:1.0
registry.redhat.io/redhat-sso-7/sso71-openshift:1.1
registry.redhat.io/redhat-sso-7/sso71-openshift:1.2
registry.redhat.io/redhat-sso-7/sso71-openshift:1.3
registry.redhat.io/redhat-sso-7/sso72-openshift:1.0
registry.redhat.io/redhat-sso-7/sso72-openshift:1.1
registry.redhat.io/redhat-sso-7/sso72-openshift:1.2
registry.redhat.io/redhat-sso-7/sso72-openshift:1.3
registry.redhat.io/redhat-sso-7/sso72-openshift:1.4
registry.redhat.io/redhat-sso-7/sso73-openshift:1.0
registry.redhat.io/redhat-sso-7/sso73-openshift:1.0
registry.redhat.io/rhscl/redis-32-rhel7:latest
registry.redhat.io/rhdm-7/rhdm74-decisioncentral-openshift:1.0
registry.redhat.io/rhdm-7/rhdm74-decisioncentral-openshift:1.1
registry.redhat.io/rhdm-7/rhdm74-kieserver-openshift:1.0
registry.redhat.io/rhdm-7/rhdm74-kieserver-openshift:1.1
registry.redhat.io/rhdm-7-tech-preview/rhdm74-optaweb-employee-rostering-openshift:1.0
registry.redhat.io/rhdm-7-tech-preview/rhdm74-optaweb-employee-rostering-openshift:1.1
registry.redhat.io/rhpam-7/rhpam74-businesscentral-monitoring-openshift:1.0
registry.redhat.io/rhpam-7/rhpam74-businesscentral-monitoring-openshift:1.1
registry.redhat.io/rhpam-7/rhpam74-businesscentral-openshift:1.0
registry.redhat.io/rhpam-7/rhpam74-businesscentral-openshift:1.1
registry.redhat.io/rhpam-7/rhpam74-kieserver-openshift:1.0
registry.redhat.io/rhpam-7/rhpam74-kieserver-openshift:1.1
registry.redhat.io/rhpam-7/rhpam74-smartrouter-openshift:1.0
registry.redhat.io/rhpam-7/rhpam74-smartrouter-openshift:1.1
registry.redhat.io/rhscl/ruby-23-rhel7:latest
registry.redhat.io/rhscl/ruby-24-rhel7:latest
registry.redhat.io/rhscl/ruby-25-rhel7:latest"


for i in $IMAGES ; do
  oc image mirror -a ${LOCAL_SECRET_JSON} \
  $i \
  ${LOCAL_REGISTRY}/${i//registry.redhat.io\/}
done;

oc create configmap registry-config --from-file=${LOCAL_REGISTRY/:/..}=/var/lib/libvirt/images/mirror-registry/certs/ca.crt -n openshift-config

oc patch image.config.openshift.io/cluster --patch '{"spec":{"additionalTrustedCA":{"name":"registry-config"}}}' --type=merge

oc patch configs.samples.operator.openshift.io/cluster \
  -n openshift-cluster-samples-operator \
  --patch "{\"spec\":{\"samplesRegistry\":\"${LOCAL_REGISTRY}\"}}" \
  --type=merge

```

### How to skip imagestreams

```
oc patch configs.samples.operator.openshift.io/cluster \
  -n openshift-cluster-samples-operator \
  --patch '{"spec":{"skippedImagestreams":["jenkins-agent-maven","jboss-datagrid72-openshift","jenkins-agent-nodejs","jenkins","nodejs"]}}'  \
  --type=merge
```

Maybe checkout the missing imagestreams bevor: `oc describe configs.samples.operator.openshift.io/cluster`


### How to upgrade your cluster

Official documentation: [Updating a restricted network cluster](https://docs.openshift.com/container-platform/latest/updating/updating-restricted-network-cluster.html)

```yaml
export OCP_RELEASE= <<<< TARGET RELEASE >>>>>
export LOCAL_REGISTRY='host.compute.local:5000'
export LOCAL_REPOSITORY='ocp4/openshift4'
export PRODUCT_REPO='openshift-release-dev'
export LOCAL_SECRET_JSON='pullsecret.json'
export RELEASE_NAME="ocp-release"
export ARCHITECTURE=x86_64

# Mirror new release
oc adm -a ${LOCAL_SECRET_JSON} release mirror \
  --from=quay.io/${PRODUCT_REPO}/${RELEASE_NAME}:${OCP_RELEASE}-${ARCHITECTURE} \
  --to=${LOCAL_REGISTRY}/${LOCAL_REPOSITORY} \
  --to-release-image=${LOCAL_REGISTRY}/${LOCAL_REPOSITORY}:${OCP_RELEASE}-${ARCHITECTURE}

# Get release digest

export DIGEST="$(oc adm release info quay.io/openshift-release-dev/ocp-release:${OCP_RELEASE}-${ARCHITECTURE} | sed -n 's/Pull From: .*@//p')"

export DIGEST_ALGO="${DIGEST%%:*}"
export DIGEST_ENCODED="${DIGEST#*:}"

export SIGNATURE_BASE64=$(curl -s "https://mirror.openshift.com/pub/openshift-v4/signatures/openshift/release/${DIGEST_ALGO}=${DIGEST_ENCODED}/signature-1" | base64 -w0 && echo)

oc apply -f - <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: release-image-${OCP_RELEASE}
  namespace: openshift-config-managed
  labels:
    release.openshift.io/verification-signatures: ""
binaryData:
  ${DIGEST_ALGO}-${DIGEST_ENCODED}: ${SIGNATURE_BASE64}
EOF

# Start upgrade
oc adm upgrade \
  --allow-explicit-upgrade \
  --to-image=${LOCAL_REGISTRY}/${LOCAL_REPOSITORY}@${DIGEST}

```
