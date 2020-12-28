# Add-ons (post_install_add_ons)

A cluster can be adapted from the standard installation with add-ons. The aim is to keep hetzner-ocp4 as lean as possible.

Technically, add-ons are simply ansible roles that are dynamically integrated. So you can write your own.

We deliver a few add-ons in the directory `ansible/add-on-role` ready to use or learn how to write your own.

## How to use an add-on

We use the web terminal add-on as an example. (ansible/add-on-roles/web-terminal/)[./ansible/add-on-roles/web-terminal/]

### Create add-ons.yml to enable & configure add on(s)

```bash
cat > add-ons.yml <<EOF
post_install_add_ons:
  - name: 'web-terminal'
    # Default is main.yml
    tasks_from: 'post-install.yml'
EOF
```

Next step simple install your cluster as usual.

## How to create your own add-on

I recommend to use git to store your role and install to hetzner host.

### Create an role & push to github

#### Create emptry role and push to git server
```bash
# Create new git repo on GitHub - don't forget to add license

$ git clone git@github.com:RedHat-EMEA-SSA-Team/hetzner-ocp4-add-on-example.git
$ cd  hetzner-ocp4-add-on-example
$ ansible-galaxy role init --offline hetzner-ocp4-add-on-example
- Role hetzner-ocp4-add-on-example was created successfully

$ mv hetzner-ocp4-add-on-example/* .
$ mv hetzner-ocp4-add-on-example/.travis.yml .
$ rmdir hetzner-ocp4-add-on-example

$ git add .
$ git commit -m 'inital ansible role'
$ git push
```

#### Add content to tasks/main.yml

Here an example of tasks/main.yml

```yaml
---
# tasks file for hetzner-ocp4-add-on-example
- name: Create namespace
  k8s:
    state: present
    kubeconfig: "{{ k8s_kubeconfig }}"
    host: "{{ k8s_host }}"
    ca_cert: "{{ k8s_ca_cert }}"
    client_cert: "{{ k8s_client_cert }}"
    client_key: "{{ k8s_client_key }}"
    definition:
      apiVersion: v1
      kind: Namespace
      metadata:
        name: hetzner-ocp4-add-on-example

- name: Create Deployment
  k8s:
    state: present
    kubeconfig: "{{ k8s_kubeconfig }}"
    host: "{{ k8s_host }}"
    ca_cert: "{{ k8s_ca_cert }}"
    client_cert: "{{ k8s_client_cert }}"
    client_key: "{{ k8s_client_key }}"
    definition:
      apiVersion: apps/v1
      kind: Deployment
      metadata:
        name: busybox
        namespace: hetzner-ocp4-add-on-example
        labels:
          app: busybox
      spec:
        replicas: 3
        selector:
          matchLabels:
            app: busybox
        template:
          metadata:
            labels:
              app: busybox
          spec:
            containers:
            - name: busybox
              image: busybox
              command: [ "/bin/sh", "-c", "while true ; do date; sleep 1; done;" ]

```

Add, commit and push the changes

### Install and configure the role

[Install role wie CLI argument or requirements.yml](https://galaxy.ansible.com/docs/using/installing.html)

```bash
$ ansible-gala xy install git+https://github.com/RedHat-EMEA-SSA-Team/hetzner-ocp4-add-on-example.git
- extracting hetzner-ocp4-add-on-example to /root/.ansible/roles/hetzner-ocp4-add-on-example
- hetzner-ocp4-add-on-example was installed successfully
```

Create add-ons.yml:
```bash
cat > add-ons.yml <<EOF
post_install_add_ons:
  - name: hetzner-ocp4-add-on-example
EOF
```

Next step simple install your cluster as usual.

## How to apply add-on to running cluster or re-apply

Create `add-ons.yaml` as described above.

Run `./ansible/02-create-cluster.yml --tags post-install-add-ons`