letsencrypt-cloudflare
=========

Configure OpenShift, create ignition config and copy to webserver (static root)

Requirements
------------

- variables
    - cluster_name
    - public_domain
    - image_pull_secret
    - ssh_public_key

Role Variables
--------------

| variable | describtion  | example | default | 
|---|---|---|---|
|ign_openshift_install_dir|||`/root/{{ cluster_name }}-install`|
|ign_certificates_path|||`{{ playbook_dir }}/../certificate/{{ cluster_name }}.{{ public_domain }}/`|
|ign_http_root|||`/var/www/html/`|
|ign_terraform_workdir|||`/root/terraform`|


Dependencies
------------

TBD

Example Playbook
----------------

If you like to play arround localy:
```
#!/usr/bin/env ansible-playbook
---
- hosts: localhost
  connection: local
  gather_facts: no
  vars_files:
  - ../cluster.yml
  roles:
    - role: ign
      ign_openshift_install_dir: "/tmp/cluster-install-dir"
      ssh_public_key: "ssh-rsa AAAAB3NzaC1yc2E....kUsrMrgV0SHiqvEeDHvC1M48vw== rbohne@redhat.com"
      ign_http_root: "/tmp/"
      ign_terraform_workdir: "/tmp/terraform"

```


Author Information
------------------


