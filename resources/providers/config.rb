# Cookbook:: postgresql
# Provider:: config

include Postgresql::Helper

action :add do
  begin
    user = new_resource.user
    postgresql_hosts = new_resource.postgresql_hosts
    routes = local_routes

    dnf_package 'postgresql' do
      action :upgrade
    end

    dnf_package 'postgresql-server' do
      action :upgrade
    end

    execute 'create_user' do
      command '/usr/sbin/useradd -r postgres'
      ignore_failure true
      not_if 'getent passwd postgres'
    end

    unless ::File.exist? '/var/lib/pgsql/data/postgresql.conf'
      Chef::Log.info('Initializing postgresql service')
      execute 'postgresql_initdb' do
        user user
        command 'initdb -D /var/lib/pgsql/data'
        action :run
      end

      template '/var/lib/pgsql/data/postgresql.conf' do
        source 'postgresql.conf.erb'
        owner user
        group user
        mode '0644'
        cookbook 'postgresql'
        notifies :restart, 'service[postgresql]'
      end

      ruby_block 'sync_if_not_master' do
        block do
          master_ip = find_master_ip_from_serf(postgresql_hosts)
          if master_ip
            local_ips = `hostname -I`.split
            unless local_ips.include?(master_ip)
              system("rb_sync_from_master.sh #{master_ip}")
            end
          end
        end
        action :run
      end
    end

    template '/var/lib/pgsql/data/pg_hba.conf' do
      source 'pg_hba.conf.erb'
      owner user
      group user
      mode '0644'
      cookbook 'postgresql'
      variables(routes: routes, user: user)
      notifies :restart, 'service[postgresql]'
    end

    template '/usr/lib/redborder/bin/rb_check_postgresql.sh' do
      source 'rb_check_postgresql.erb'
      owner 'root'
      group 'root'
      mode '0755'
      cookbook 'postgresql'
      retries 2
    end

    ruby_block 'register_postgresql_health_check' do
      block do
        service_id = "postgresql-#{node['hostname']}"
        json_check = {
          'Name' => 'postgresql-health-check',
          'Args' => ['/usr/lib/redborder/bin/rb_check_postgresql.sh'],
          'Interval' => '60s',
          'Timeout' => '10s',
          'Notes' => 'Health check PostgreSQL replication',
          'ServiceID' => service_id
        }.to_json

        system("curl -X PUT http://localhost:8500/v1/agent/check/register -d '#{json_check}' &>/dev/null")
      end
      action :run
    end

    service 'postgresql' do
      service_name 'postgresql'
      ignore_failure true
      supports status: true, reload: true, restart: true, enable: true
      action [:start, :enable]
    end

    Chef::Log.info('PostgreSQL cookbook has been processed')
  rescue => e
    Chef::Log.error(e.message)
  end
end

action :remove do
  begin
    service 'postgresql' do
      service_name 'postgresql'
      ignore_failure true
      supports status: true, enable: true
      action [:stop, :disable]
    end

    dnf_package 'postgresql-server' do
      action :remove
    end

    directory '/var/lib/pgsql' do
      recursive true
      action :delete
      ignore_failure true
    end

    Chef::Log.info('PostgreSQL cookbook has been processed')
  rescue => e
    Chef::Log.error(e.message)
  end
end

action :register do
  begin
    ipaddress = new_resource.ipaddress

    unless node['postgresql']['registered']
      query = {}
      query['ID'] = "postgresql-#{node['hostname']}"
      query['Name'] = 'postgresql'
      query['Address'] = ipaddress
      query['Port'] = 5432
      json_query = Chef::JSONCompat.to_json(query)

      execute 'Register service in consul' do
        command "curl -X PUT http://localhost:8500/v1/agent/service/register -d '#{json_query}' &>/dev/null"
        action :nothing
      end.run_action(:run)

      node.normal['postgresql']['registered'] = true
      Chef::Log.info('Postgresql service has been registered to consul')
    end
  rescue => e
    Chef::Log.error(e.message)
  end
end

action :deregister do
  begin
    if node['postgresql']['registered']
      execute 'Deregister service in consul' do
        command "curl -X PUT http://localhost:8500/v1/agent/service/deregister/postgresql-#{node['hostname']} &>/dev/null"
        action :nothing
      end.run_action(:run)

      node.normal['postgresql']['registered'] = false
      Chef::Log.info('Postgresql service has been deregistered from consul')
    end
  rescue => e
    Chef::Log.error(e.message)
  end
end
