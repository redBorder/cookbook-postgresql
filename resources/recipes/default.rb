#
# Cookbook Name:: postgresql
# Recipe:: default
#
# Copyright 2016, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

cookbook_postgresql_config "config" do
  mystring "test"
  action :add
end
