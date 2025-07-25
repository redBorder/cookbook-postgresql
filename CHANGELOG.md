cookbook-postgresql CHANGELOG
===============

## 0.3.0

  - nilsver
    - [338d9d3] fix pg connection
    - [930e278] added retry to handle curl6/7 error
    - [bbfcc77] add script to ingest cve into postgres

## 0.2.1

  - nilsver
    - [930e278] added retry to handle curl6/7 error
    - [89e5f6b] install script
    - [bbfcc77] add script to ingest cve into postgres

## 0.2.0

  - Rafael Gomez
    - [6b4e634] Add recursive deletion of PostgreSQL data directory in remove action
    - [a3d8748] Add methods to update PostgreSQL configuration with master node IP
    - [814c307] Move PostgreSQL configuration update methods and related logic from helper and config provider
    - [f2ff35b] Execute sync_if_not_master always
    - [0fcea34] Registering postgresql service in consul each run
    - [6a37fbe] Creating serf tags
    - [b76ac0f] Passign master name to rb_sync_from_master.sh instead of master ip
    - [e297802] Creating meta tag ipvirtual-internal-postgresql
    - [485f412] Removing redborder-postgresql in consul
    - [7de0b58] removing master.postgresql.service from /etc/hosts if there is no virtual ip registered
    - [d5f0d73] Disable and stop redborder-postgresql if postgres virtual ip is registered

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
