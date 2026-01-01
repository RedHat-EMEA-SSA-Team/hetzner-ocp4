## Change SSH port on RHEL (firewalld + SELinux + Hetzner Firewall)

This guide describes how to change the SSH daemon port on a **RHEL** host (e.g. a Hetzner bare metal server), including required updates for **firewalld**, **SELinux**, and the **Hetzner Robot Firewall**.

Source: [Issue #292: "Add: How to switch ssh port on RHEL"](https://github.com/RedHat-EMEA-SSA-Team/hetzner-ocp4/issues/292)

### Before you start (avoid locking yourself out)

- **Keep an active root session** open while performing the change (e.g. SSH session + console access).
- **Temporarily allow both ports** (old + new) until you have verified login on the new port.
- **Prefer restricting the firewall rule** (Hetzner and host firewall) to your source IP/CIDR if possible.

In the examples below we use port `1984`. Replace it with the port you prefer.

### 1) Configure `sshd` to listen on the new port

Edit `/etc/ssh/sshd_config` and add an additional `Port` line (keep `22` for now):

```conf
Port 22
Port 1984
```

Validate the config:

```bash
sshd -t
```

### 2) Open the port in the host firewall (firewalld)

```bash
firewall-cmd --zone public --add-port 1984/tcp --permanent
firewall-cmd --reload
```

Verify:

```bash
firewall-cmd --zone public --list-ports
```

### 3) Allow the port in SELinux

Install the SELinux tooling (package name depends on the RHEL major version):

```bash
# RHEL 8/9 commonly use:
dnf install -y policycoreutils-python-utils
```

Add the new SSH port type:

```bash
semanage port -a -t ssh_port_t -p tcp 1984
```

If you get an error that the port already exists, modify instead:

```bash
semanage port -m -t ssh_port_t -p tcp 1984
```

Verify:

```bash
semanage port -l | grep -E '^ssh_port_t'
```

### 4) Allow the port in the Hetzner Firewall (Robot)

If you use the Hetzner Robot Firewall, add a rule to **accept TCP** traffic to destination port `1984` (ideally from your source IP/CIDR).

Important note from this repository’s docs: Hetzner Firewall only supports **IPv4**; for **IPv6** you must rely on the host firewall. See the firewall section in `README.md`.

### 5) Reload `sshd` and verify it is listening

Reload the daemon:

```bash
systemctl reload sshd
```

Verify it is listening on the new port:

```bash
ss -tulpn | grep 1984
```

Example output:

```txt
tcp   LISTEN 0      128           0.0.0.0:1984       0.0.0.0:*    users:(("sshd",pid=1349,fd=3))
tcp   LISTEN 0      128              [::]:1984          [::]:*    users:(("sshd",pid=1349,fd=4))
```

### 6) Test login on the new port

From your workstation:

```bash
ssh -p 1984 root@YOUR_HOSTNAME_OR_IP
```

Optional: configure your local SSH client so you don’t need `-p` every time:

```sshconfig
Host my-hetzner-host
  HostName pluto.openshift.pub
  User root
  Port 1984
```

### 7) Update Ansible inventory (if you run playbooks against the host)

If you changed the SSH port and run this repo’s playbooks remotely, set `ansible_port` for the target host.

Example (`inventory/hosts.yaml`):

```yaml
all:
  hosts:
    host:
      ansible_host: pluto.openshift.pub
      ansible_port: 1984
      ansible_private_key_file: ~/.ssh/id_ed25519
```

### 8) (Optional) Remove port 22 again

Only do this after you have confirmed you can log in using the new port.

- Remove `Port 22` from `sshd_config`
- Remove `22/tcp` from your host firewall and Hetzner Firewall rules
- Reload `sshd` again:

```bash
systemctl reload sshd
```

### Troubleshooting / rollback

- **`sshd -t` fails**: revert your last edit to `/etc/ssh/sshd_config`, then re-run `sshd -t`.
- **SELinux blocks the port**: ensure `semanage port -l | grep ssh_port_t` includes your chosen port.
- **No connectivity from the internet**: ensure both the **host firewall** and **Hetzner Firewall** allow the port (and the correct IP family).
