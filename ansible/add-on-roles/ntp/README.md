# ntp

this add-on adds a NTP MachineConfig to the nodes. Per default it uses the Hetzner NTP Servers

## Role Variables

This addons adds 2 MachineConfigs which will configure chrony to use a specific NTP server.

## Example config

```
ntp_server: ntp.hetzner.de
```

```
post_install_add_ons:
  - name: 'ntp'
    tasks_from: 'post-install.yml'
```

## License

Apache 2.0

## Author Information

Jonas Janz
