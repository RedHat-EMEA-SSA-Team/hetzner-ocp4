# Add Compute Nodes

Follow this procedure to add to the cluster more worker nodes

## (Optional) Check that the worker ignition have the CA certificate not expirated

Install jq utility and set your cluster name:
```
yum -y install jq
cluster_name="<< your_cluster-name>>"
```

Check the validation of the Certificate of your worker.ign (check the notAfter section)
```
jq '.ignition.security.tls.certificateAuthorities[].source'  /root/hetzner-ocp4/$(cluster_name)/worker.ign | tr -d '"' | sed 's/.*,//' | base64 -d  | openssl x509 -noout -issuer -subject -dates
```

## Add compute nodes to the cluster

Launch the 05-add-compute task with the compute_count desired defined as the extra_vars:
```
ansible-playbook ansible/05-add-compute.yml -e "compute_count=5"
```

## Check the new worker nodes within the cluster

Check the nodes that are all running (the output need to be empty)
```
JSONPATH='{range .items[*]}{@.metadata.name}:{range @.status.conditions[*]}{@.type}={@.status};{end}{end}' && oc get nodes -o jsonpath="$JSONPATH" | grep "Ready=False"
```
