# OpenShift Pipeline to test hetzner-ocp4

## Build ansible ubi

```
podman build -t quay.io/redhat-emea-ssa-team/hetzner-ocp4-pipeline:latest .
podman push quay.io/redhat-emea-ssa-team/hetzner-ocp4-pipeline:latest

```

## Create `hetzner-ocp4-pipeline` secret
```
oc create secret generic hetzner-ocp4-pipeline\
  --from-file=ssh-privatekey=~/.ssh/id_rsa \
  --from-file=gcp_service_account.json=~/gcp_service_account.json \
  --from-file=cluster.yml=cluster.yml \
  --from-file=aws-cluster.yml=aws-cluster.yml \
  --from-file=gcp-cluster.yml=gcp-cluster.yml \
  --from-file=cloudflare-cluster.yml=cloudflare-cluster.yml
```

### Examples
#### cluster.yml
```yaml
cloudflare_account_email: info@example.com
letsencrypt_directory: "https://acme-staging-v02.api.letsencrypt.org/directory"

auth_htpasswd:
  - admin:$apr1$fwtOSKTC$CeS86bGLeuXcStFvl/3Ky/
  - local:$apr1$81BkJ4dI$XGcaDat/h529tjbf4SNH//

storage_nfs: true

cluster_role_bindings:
  - cluster_role: sudoers
    name: foobar
  - cluster_role: cluster-admin
    name: admin

image_pull_secret: |-
  {"auths":{"cloud.openshift.com":{"auth":"....

# Hetzner informations (for role provision-hetzner)
hetzner_hostname: "hostnmae"
hetzner_webservice_username: "xxxx"
hetzner_webservice_password: "xxxxx"
hetzner_image: "/root/.oldroot/nfs/install/../images/CentOS-76-64-minimal.tar.gz"
hetzner_ip: "178.63.99.94"

hetzner_disk1: sda
hetzner_disk2: sdb
```
#### aws-cluster.yml
```yaml
cluster_name: test
public_domain: aws.ci.example.com
dns_provider: route53

aws_access_key: xxx
aws_secret_key: xxx
aws_zone: aws.ci.example.com
```
#### gcp-cluster.yml
```yaml
cluster_name: test
public_domain: gcp.ci.example.com
dns_provider: gcp

gcp_project: 'project'
gcp_managed_zone_name: 'gcp-ci-example-com'
gcp_managed_zone_domain: 'gcp.ci.example.com.'
gcp_serviceaccount_file: /root/gcp_service_account.json
```
#### cloudflare-cluster.yml
```yaml
cluster_name: test
public_domain: cf.ci.example.com
dns_provider: cloudflare

cloudflare_account_email: info@example.com
cloudflare_account_api_token: xxxxx
cloudflare_zone: example.com
```


## Install pipeline

```
oc create -f pipeline/tasks/

oc create -f - <<EOF
apiVersion: tekton.dev/v1alpha1
kind: PipelineResource
metadata:
  name: hetzner-ocp4-pipeline
spec:
  type: git
  params:
    - name: url
      value: https://github.com/rbo/hetzner-ocp4.git
    - name: revision
      value: pipeline
EOF

oc create -f - <<EOF
apiVersion: tekton.dev/v1alpha1
kind: PipelineResource
metadata:
  name: hetzner-ocp4-master
spec:
  type: git
  params:
    - name: url
      value: https://github.com/rbo/hetzner-ocp4.git
    - name: revision
      value: master
EOF

oc create -f - <<EOF
apiVersion: tekton.dev/v1alpha1
kind: PipelineResource
metadata:
  name: hetzner-ocp4-dev
spec:
  type: git
  params:
    - name: url
      value: https://github.com/rbo/hetzner-ocp4.git
    - name: revision
      value: dev
EOF

oc apply -f pipeline/
```



## Resources

* Parameters don't work via WebUI  -> Works with 4.3 & 0.9.1 Pipelines
* Missing repo info at pipelineruns
* Triggers works
    https://github.com/tektoncd/triggers#background
    no auth!
    https://github.com/tektoncd/triggers/tree/master/examples
    oc expose svc/el-listener
* timeout
  https://github.com/tektoncd/pipeline/blob/master/docs/pipelineruns.md#syntax

