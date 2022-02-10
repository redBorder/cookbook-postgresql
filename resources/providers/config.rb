
# Cookbook Name:: postgresql
#
# Provider:: config
#

include Postgresql::Helper

action :add do
  begin

    user = new_resource.user
    postgresql_port = new_resource.postgresql_port
    cdomain = new_resource.cdomain
    routes = local_routes()

    yum_package "postgresql" do
      action :upgrade
      flush_cache [:before]
    end

    yum_package "postgresql-server" do
      action :upgrade
      flush_cache [:before]
    end

    yum_package "redborder-postgresql" do
      action :upgrade
      flush_cache [:before]
    end

    user user do
      action :create
      system true
    end

    unless ::File.exist? "/var/lib/pgsql/data/postgresql.conf"
        Chef::Log.info("Initializing postgresql service")
        execute 'postgresql_initdb' do
            user user
            command 'initdb -D /var/lib/pgsql/data'
            action :run
        end	
    end

    template "/var/lib/pgsql/data/postgresql.conf" do
      source "postgresql.conf.erb"
      owner user
      group user
      mode 0644
      cookbook "postgresql"
      notifies :restart, "service[postgresql]"
    end

    template "/var/lib/pgsql/data/pg_hba.conf" do
      source "pg_hba.conf.erb"
      owner user
      group user
      mode 0644
      cookbook "postgresql"
      variables(:routes => routes, :user => user)
      notifies :restart, "service[postgresql]"
    end

    service "postgresql" do
      service_name "postgresql"
      ignore_failure true
      supports :status => true, :reload => true, :restart => true, :enable => true
      action [:start, :enable]
    end

    service "redborder-postgresql" do
      service_name "redborder-postgresql"
      ignore_failure true
      supports :status => true, :reload => true, :restart => true, :enable => true
      action [:start, :enable]
    end

     Chef::Log.info("PostgreSQL cookbook has been processed")
  rescue => e
    Chef::Log.error(e.message)
  end
end

action :remove do
  begin
    
    service "postgresql" do
      service_name "postgresql"
      ignore_failure true
      supports :status => true, :enable => true
      action [:stop, :disable]
    end

    yum_package "postgresql-server" do
      action :remove
    end

    Chef::Log.info("PostgreSQL cookbook has been processed")
  rescue => e
    Chef::Log.error(e.message)
  end
end

action :register do
  begin
    if !node["postgresql"]["registered"]
      query = {}
      query["ID"] = "postgresql-#{node["hostname"]}"
      query["Name"] = "postgresql"
      query["Address"] = "#{node["ipaddress"]}"
      query["Port"] = 5432
      json_query = Chef::JSONCompat.to_json(query)

      execute 'Register service in consul' do
         command "curl -X PUT http://localhost:8500/v1/agent/service/register -d '#{json_query}' &>/dev/null"
         action :nothing
         notifies :restart, "service[redborder-postgresql]"
      end.run_action(:run)

      node.set["postgresql"]["registered"] = true
      Chef::Log.info("Postgresql service has been registered to consul")
    end
  rescue => e
    Chef::Log.error(e.message)
  end
end

action :deregister do
  begin
    if node["postgresql"]["registered"]
      execute 'Deregister service in consul' do
        command "curl -X PUT http://localhost:8500/v1/agent/service/deregister/postgresql-#{node["hostname"]} &>/dev/null"
        action :nothing
      end.run_action(:run)

      node.set["postgresql"]["registered"] = false
      Chef::Log.info("Postgresql service has been deregistered from consul")
    end
  rescue => e
    Chef::Log.error(e.message)
  end
end
