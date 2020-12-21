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

## (Optional) Added specific parameters for the new nodes

Specify the parameters for the new nodes in the cluster.yml
```
compute_count: 5
compute_vcpu: 2
compute_memory_size: 16384
compute_memory_unit: 'MiB'
# qemu-img image size specified.
#   You may use k, M, G, T, P or E suffixe
compute_root_disk_size: '120G'
```

NOTE: if you not specify the parameters this will be use the openshift-4-cluster/defaults/main.yml

## Add compute nodes to the cluster

Launch the 05-add-compute task with the compute_count desired defined as the extra_vars (if is defined in the cluster.yml this will be overwrite this parameter):
```
ansible-playbook ansible/05-add-compute.yml -e "compute_count=5"
```

## Check the new worker nodes within the cluster

Check the nodes that are all running (the output need to be empty)
```
JSONPATH='{range .items[*]}{@.metadata.name}:{range @.status.conditions[*]}{@.type}={@.status};{end}{end}' && oc get nodes -o jsonpath="$JSONPATH" | grep "Ready=False"
```
