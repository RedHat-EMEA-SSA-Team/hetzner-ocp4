# Remote execution

In case you want to execute the playbooks on your laptop and install OpenShift at your Hetzner Server. Like this:

```
  ┌───────────────────────────────────┐
  │                                   │
  │ Hetzner Server                 ▲  │
  │                                │  │
  └────────────────────────────────┼──┘
                                   │
                                  SSH
                                   │
  ┌────────────────────────────────┬───┐
  │Local Workstation/Laptop        │   │
  │                                │   │
  │ ┌──────────────────────────────┼─┐ │
  │ │ Ansible runner (Podman)      │ │ │
  │ │                                │ │
  │ │                                │ │
  │ └────────────────────────────────┘ │
  │                                    │
  └────────────────────────────────────┘
```


Just edit `inventory/hosts.yaml` and change `ansible_host` to your Hetzner Server. And strongly recommended to add `artifacts_dir` for example `/root/hetzner-ocp4/` where the artifacts (certifcates, kubeconf) is stored during the installation.

One example:
```yaml
---
all:
  hosts:
    host:
      ansible_host: tester.openshift.pub
      artifacts_dir: /root/hetzner-ocp4/
```
