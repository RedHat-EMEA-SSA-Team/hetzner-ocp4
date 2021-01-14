ntp
=========

this add-on adds a NTP MachineConfig to the nodes. Per default it uses the Hetzner NTP Servers

Role Variables
--------------

A description of the settable variables for this role should go here, including any variables that are in defaults/main.yml, vars/main.yml, and any variables that can/should be set via parameters to the role. Any variables that are read from other roles and/or the global scope (ie. hostvars, group vars, etc.) should be mentioned here as well.

Example config
----------------

```
post_install_add_ons:
  - name: 'web-terminal'
    tasks_from: 'post-install.yml'
```

License
-------

Apache 2.0

Author Information
------------------

Jonas Janz