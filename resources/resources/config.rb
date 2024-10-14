# Cookbook:: postgresql
# Resource:: config

actions :add, :remove, :register, :deregister
default_action :add

attribute :user, kind_of: String, default: 'postgres'
attribute :postgresql_port, kind_of: Integer, default: 5432
attribute :cdomain, kind_of: String, default: 'redborder.cluster'
attribute :ipaddress, kind_of: String, default: '127.0.0.1'
attribute :virtual_ips, kind_of: Hash, default: {}
