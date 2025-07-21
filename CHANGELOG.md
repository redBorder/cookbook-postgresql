cookbook-postgresql CHANGELOG
===============

## 0.2.0

  - Rafael Gomez
    - [6b4e634] Add recursive deletion of PostgreSQL data directory in remove action
    - [a3d8748] Add methods to update PostgreSQL configuration with master node IP
    - [fc699e8] Reintroduce master status check logic in PostgreSQL configuration provider
    - [814c307] Remove PostgreSQL configuration update methods and related logic from helper and config provider
    - [56490f6] Remove postgresql_conf_file attribute and hardcode configuration file path in add action
    - [97e07db] Add postgresql_conf_file attribute and update configuration file handling
    - [d70f144] sync_if_not_master will do it postgresql cookbook
    - [f2ff35b] Execute sync_if_not_master always
    - [0fcea34] Registering postgresql service in consul each run
    - [6a37fbe] Creating serf tags and refactor code to use helper methods
    - [b76ac0f] Passign master name to rb_sync_from_master.sh instead of master ip
    - [e297802] Creating meta tag ipvirtual-internal-postgresql
    - [d56e778] Refactor sync_if_not_master ruby_block to be only one
    - [485f412] Removing action restart of redborder-postgresql service in consul registration
    - [7de0b58] removing master.postgresql.service from /etc/hosts if there is no virtual ip registered
    - [d5f0d73] Disable and stop redborder-postgresql if postgres virtual ip is registered
    - [714ad65] Creating postgresql_role serf tag
    - [d240f8b] Do not execute sync_if_not_master if there is a vrp registered

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
