- name: Create DNS record at TransIP
  uri:
    url: "https://api.transip.nl/v6/domains/{{ transip_zone }}/dns"
    method: DELETE
    headers:
      Authorization: "Bearer {{ transip_token }}"
    body_format: json
    body:
      dnsEntry:
        name: "{{ item }}.{{ cluster_name }}"
        expire: 60
        type: A
        content: "{{ pd_public_ip }}"
    status_code: 204
  with_items:
  - api
  - '*.apps'
  tags:
    - public_dns

