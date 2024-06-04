# Cookbook:: postgresql
# Recipe:: default
# Copyright:: 2024, redborder
# License:: Affero General Public License, Version 3

cookbook_postgresql_config 'config' do
  mystring 'test'
  action :add
end
