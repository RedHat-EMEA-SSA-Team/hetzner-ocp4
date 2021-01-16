# How to use hetzner-ocp4-add-on-cluster-entitlement

Add to cluster-add-ons.yml
```
post_install_add_ons:
  - name: cluster-entitlement
    tasks_from: "post-install.yaml"

# Optional if you want to use specific entitlement id
entitlement_id: 7045354189760625103
```

