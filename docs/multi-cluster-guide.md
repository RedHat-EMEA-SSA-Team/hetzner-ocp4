# Multi cluster guide

If you like you can setup more than one cluster paralle with hetzner-ocp4.

The playbooks `03-stop-cluster.yml` and `04-start-cluster.yml` starts and stops all virtual machines. Additionally it stops & disables or start & enable the host load balancer. 

## Create an cluster.yml for every cluster

Create an empty cluster.yml or add all variables there are the some at all clusters.

For example `cluster-demo.yml`
```yaml
# Very import, different cluster_name!
cluster_name: demo

# Change public ip address for every cluster.
# default is hostvars['localhost']['ansible_default_ipv4']['address'] 
listen_address: '<public_ip>'

# Different subnet for every cluster, default 192.168.50.0
vn_subnet: "192.168.51.0"
```

## Now you can use all playbooks 

Add `-e @cluster-demo.yml` to all playbooks:
```
./ansible/02-create-cluster.yml -e @cluster-demo.yml
./ansible/03-stop-cluster.yml -e @cluster-demo.yml
./ansible/04-start-cluster.yml -e @cluster-demo.yml
```