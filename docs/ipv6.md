
## IPv6

Addition of several variables to get to a dual-stack IPv4 and IPv6 network


We are working on one Hetzner machine with KVM virtual machines.
So no consideration for other machines and or networks.

For the clusternetwork used a  "fd02::/48"
and the same for servicenetwork a  'fd03::/112'.




```
  # ipv4 - ipv6 network variable
  # used in ansible/roles/openshift-4-cluster/templates/install-config.yaml.j2

  networking_clusternetwork_cidr_ipv4: "10.128.0.0/14"
  networking_clusternetwork_hostprefix_ipv4: "23"

  networking_clusternetwork_cidr_ipv6: "fd02::/48"
  networking_clusternetwork_hostprefix_ipv6: 64
  ## cluster network host subnetwork prefix must be 64 for IPv6 networks

  networking_servicenetwork_cidr_ipv4: "172.30.0.0/16"
  networking_servicenetwork_cidr_ipv6: 'fd03::/112'

  # vnet_subnetxxxx is calculated in ansible/roles/openshift-4-cluster/tasks/create-network.yml
  networking_machinenetwork_cidr_ipv4: "{{ vn_subnet }}/24"
  networking_machinenetwork_cidr_ipv6: "{{ vn_subnet_ipv6 }}::/80"

```




