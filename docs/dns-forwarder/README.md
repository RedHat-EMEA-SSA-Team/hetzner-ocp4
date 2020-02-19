# Setup DNS forwarder

We provided some playbooks to setup 2 dns vm's
```
# Create
./docs/dns-forwarder/dns-create.yml 

# Destroy
./docs/dns-forwarder/dns-destroy.yml 
```

# Adjust openshift
```
oc apply -f - <<EOF 
apiVersion: operator.openshift.io/v1
kind: DNS
metadata:
  name: default
spec:
  servers:
  - forwardPlugin:
      upstreams:
      - "192.168.55.2"
      - "192.168.55.3"
    name: my-custom-dns
    zones:
    - example.com
EOF
```