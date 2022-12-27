letsencrypt
=========

Create  certificates with DNS challenge through Cloudflare, AWS Route53, GCP Cloud DNS or Hetzner

Requirements
------------

- cloudflare account
- matching domain to the certificate ;-)

Role Variables
--------------

| variable | describtion  | example | default |
|---|---|---|---|
| le_dns_provider | DNS provider | `[route53|cloudflare|gcp|azure|hetzner]` |  non **required** |
| le_cloudflare_account_email | Cloudflare Account E-Mail for API authentication | `account@domain.tld`| non **required if provider is cloudflare** |
| le_cloudflare_account_api_token | Cloudflare Global API token for API authentication | `loo...ngiJ`| non **required if provider is cloudflare** |
| le_cloudflare_api_token | Cloudflare API token for API authentication | `loo...ngiJ`| non **required if provider is cloudflare** |
| le_cloudflare_zone | Cloudflare zone in which the entries are created and deleted for the dns challenge | `domain.tld` | non **required if provider is cloudflare** |
| le_aws_access_key | AWS Access key | |  non **required if provider is  route53** |
| le_aws_secret_key | AWS secret key || non **required if provider is  route53** |
| le_aws_zone | AWS route 53 zonename || non **required if provider is  route53** |
| le_gcp_project | GCP DNS projectname || non **required if provider is  gcp** |
| le_gcp_serviceaccount_file | GCP DNS serviceaccount file || non **required if provider is  gcp** |
| le_gcp_managed_zone_name | GCP DNS managed zone name || non **required if provider is  gcp** |
| le_gcp_managed_zone_domain | GCP DNS managed zone domain || non **required if provider is  gcp** |
| le_hetzner_account_api_token | Hetzner API token for API authentication | `jdu...zalU`| non **required if provider is hetzner** |
| le_hetzner_zone | Hetzner zone in which the entries are created and deleted for the dns challenge | `domain.tld` | non **required if provider is hetzner** |
| le_gandi_api_key | Gandi API key for API authentication || non **required if provider is gandi** |
| le_gandi_zone | Gandi zone in which the entries are created and delete for the DNS challenge | `domain.tld` | non **required if provider is gandi** |
| le_public_domain | Use to create SAN certificate: `DNS:*.apps.{{ le_public_domain }},DNS:api.{{ le_public_domain }}` | cluster.domain.tld | non **required** |
| le_certificates_dir | Here the certificates are stored  | `/root/certificates` | `{{ playbook_dir }}../certificate/` |
| le_acme_directory | ACME Directory by default it use staging env because of https://letsencrypt.org/docs/rate-limits/ | `https://acme-v02.api.letsencrypt.org/directory` | `https://acme-staging-v02.api.letsencrypt.org/directory` |

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
