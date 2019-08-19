letsencrypt-cloudflare
=========

Create letsencrypt certificates with DNS challenge through cloudflare

Requirements
------------

- cloudflare account 
- matching domain to the certificate ;-)

Role Variables
--------------

| variable | type | describtion  | example | default | 
|---|---|---|---|---|
| lc_cloudflare_account_email | string | Cloudflare Account E-Mail for API authentication | `account@domain.tld`| non **required** |
| lc_cloudflare_account_api_token | string | Cloudflare API token for API authentication | `loo...ngiJ`| non **required** |
| lc_cloudflare_zone | string | Cloudflare zone in which the entries are created and deleted for the dns challenge | `domain.tld` | non **required** |
| lc_public_domain | string | Use to create SAN certificate: `DNS:*.apps.{{ lc_public_domain }},DNS:api.{{ lc_public_domain }}` | cluster.domain.tld | non **required** |
| lc_certificates_dir | string | Here the certificates are stored  | `/root/certificates` | `{{ playbook_dir }}../certificate/` |
| lc_acme_directory | string | ACME Directory by default it use staging env because of https://letsencrypt.org/docs/rate-limits/ | `https://acme-v02.api.letsencrypt.org/directory` | `https://acme-staging-v02.api.letsencrypt.org/directory` |



Dependencies
------------

TBD

- openssl_privatekey
    - Either cryptography >= 1.2.3 (older versions might work as well) 
    - Or pyOpenSSL

Example Playbook
----------------

```
- hosts: localhost
  connection: local
  gather_facts: no
  roles:
  - role: letsencrypt-cloudflare
    lc_cloudflare_account_email: ...
    lc_cloudflare_account_api_token: ...
    lc_cloudflare_zone: ...
```

Example in context of hetzner-ocp4

```
#!/usr/bin/env ansible-playbook
---
- hosts: localhost
  connection: local
  gather_facts: no
  vars_files:
  - ../cluster.yml
  roles:
  - role: letsencrypt-cloudflare
    lc_cloudflare_account_email: "{{ cloudflare_account_email }}"
    lc_cloudflare_account_api_token: "{{ cloudflare_account_api_token }}"
    lc_cloudflare_zone: "{{ cloudflare_zone }}"
    lc_public_domain: "{{ cluster_name }}.{{ public_domain }}" 
    # Only set if you really want a production letsencrypt certificate
    #   https://letsencrypt.org/docs/rate-limits/
    # lc_acme_directory: "https://acme-v02.api.letsencrypt.org/directory"

```


Author Information
------------------

Robert Bohne <robert.bohne@redhat.com>
