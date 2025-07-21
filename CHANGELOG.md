cookbook-postgresql CHANGELOG
===============

## 0.2.0

  - Luis Blanco
    - [bb2275a] Merge pull request #15 from redBorder/feature/#18850_add_internal_virtual_ips
  - Rafael Gomez
    - [6fd0859] Master node will be the first on the list if vip is not set
    - [19d6ed5] Merge branch 'master' into feature/#18850_add_internal_virtual_ips
    - [6b4e634] Add recursive deletion of PostgreSQL data directory in remove action
    - [d43405b] Remove pg_virtual_ip_registered template file
    - [cf472fb] Remove unused virtual IP handling methods from PostgreSQL helper and configuration files
    - [658788d] Refactor update_postgresql_conf to retrieve master IP internally
    - [a3d8748] Add methods to update PostgreSQL configuration with master node IP
    - [fc699e8] Reintroduce master status check logic in PostgreSQL configuration provider
    - [814c307] Remove PostgreSQL configuration update methods and related logic from helper and config provider
    - [56490f6] Remove postgresql_conf_file attribute and hardcode configuration file path in add action
    - [97e07db] Add postgresql_conf_file attribute and update configuration file handling
    - [14827ec] Refactor sync_if_not_master logic to simplify master node detection
    - [c9aca42] Remove unnecessary nil return for primary_conninfo in PostgreSQL helper
    - [e6ef7d7] Refactor PostgreSQL helper methods for master node detection and configuration updates
    - [d70f144] sync_if_not_master will do it postgresql cookbook
    - [98b76c3] Changing order of virtual_ip_changed? and do not user current_ip variable
    - [a8be1a6] Revert changes
    - [45b41af] Creating helper method to sync from master. Do not register postgresql service in consul always
    - [4e586e2] Remove log info
    - [4891816] Refactor sync_if_not_master
    - [ad58fb4] Do not print logs in check_postgresql_master_status
    - [f2ff35b] Execute sync_if_not_master always
    - [3e272ad] Fix linter
    - [0fcea34] Registering postgresql service in consul each run
    - [6a37fbe] Creating serf tags and refactor code to use helper methods
    - [b76ac0f] Passign master name to rb_sync_from_master.sh instead of master ip
    - [14929c0] Using unless include
    - [7182a5d] Fix linter
    - [e297802] Creating meta tag ipvirtual-internal-postgresql
    - [af1b673] Fix linter
    - [6a640d5] If there is any internal-postgresql add it to /etc/hosts
    - [d56e778] Refactor sync_if_not_master ruby_block to be only one
    - [a311cdc] Fix linter
    - [6a4a4f2] Check if master.postgresql.service is registered or not in /etc/hosts
    - [872821a] Check if master.postgresql.service is registered or not in /etc/hosts
    - [bc15155] Executing rb_sync_from_master.sh
    - [485f412] Removing action restart of redborder-postgresql service in consul registration
    - [bef2d39] Adding consul again
    - [5a5cbcd] Fix linter
    - [73bd50c] Removing virtual ips variable
    - [ebfe2c0] Removing redborder-postgresql service
    - [11d2ccb] Fix linter
    - [7de0b58] removing master.postgresql.service from /etc/hosts if there is no virtual ip registered
    - [d5f0d73] Disable and stop redborder-postgresql if postgres virtual ip is registered
    - [603a47a] Update config.rb
    - [714ad65] Creating postgresql_role serf tag
  - David Vanhoucke
    - [780f6a3] remove code
  - Rafa Gómez
    - [13d7074] Fix linter
    - [e158f55] Overwrite /etc/hosts
    - [9a9b85f] Fix linter
    - [d240f8b] Do not execute sync_if_not_master if there is a vrp registered
    - [d784e8c] Update config.rb

## 0.1.10

  - nilsver
    - [321d0f0] remove flush cache

## 0.1.9

  - Miguel Negrón
    - [26399cc] Add pre and postun to clean the cookbook
    - [f09d70e] Improvement/fix lint (#13)
    - [2314f90] Update README.md
    - [bcb80ae] Update rpm.yml
    - [e545b30] Update metadata.rb
  - nilsver
    - [490325c] Release 0.1.8
  - Miguel Negrón
    - [f09d70e] Improvement/fix lint (#13)
    - [2314f90] Update README.md
    - [bcb80ae] Update rpm.yml
    - [e545b30] Update metadata.rb

## 0.1.8

  - Miguel Negrón
    - [f09d70e] Improvement/fix lint (#13)
    - [2314f90] Update README.md
    - [bcb80ae] Update rpm.yml
    - [e545b30] Update metadata.rb

This file is used to list changes made in each version of the example cookbook.

0.0.1
-----
- [Juan J. Prieto]
  - COMMIT_REF Initial release of cookbook-postgresql

- - -
Check the [Markdown Syntax Guide](http://daringfireball.net/projects/markdown/syntax) for help with Markdown.

The [Github Flavored Markdown page](http://github.github.com/github-flavored-markdown/) describes the differences between markdown on github and standard markdown.
