# Cookbook:: postgresql
# Provider:: config

include Postgresql::Helper

begin
  postgresql_vip = data_bag_item('rBglobal', 'ipvirtual-internal-postgresql')
rescue
  postgresql_vip = {}
end

action :add do
  begin
    user = new_resource.user
    routes = local_routes()

    dnf_package 'postgresql' do
      action :upgrade
      flush_cache [:before]
    end

    dnf_package 'postgresql-server' do
      action :upgrade
      flush_cache [:before]
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
          master_ip = fetch_master_ip(postgresql_vip)
          if master_ip
            sync_if_not_master(master_ip)
          else
            Chef::Log.warn('No master IP found; skipping sync.')
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

    service 'postgresql' do
      service_name 'postgresql'
      ignore_failure true
      supports status: true, reload: true, restart: true, enable: true
      action [:start, :enable]
    end

    ruby_block 'check_postgresql_master_status' do
      block do
        is_recovery = `sudo -u postgres psql -h 127.0.0.1 -t -c "SELECT pg_is_in_recovery();" 2>/dev/null | tr -d ' \t\n\r'`
        if is_recovery == 'f'
          system('serf tags -set postgresql_role=master')
        else
          system('serf tags -set postgresql_role=standby')
        end
      end
      action :run
    end

    ruby_block 'check_postgresql_hosts' do
      block do
        hosts_file = '/etc/hosts'
        master_ip = fetch_master_ip(postgresql_vip)
        if master_ip
          update_hosts_file(hosts_file, master_ip)
        else
          Chef::Log.warn('No master IP found for PostgreSQL.')
        end
      end
      action :run
    end
    node.normal['postgresql']['registered'] = false
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
      query['Meta'] = {}
      query['Meta']['ipvirtual-internal-postgresql'] = postgresql_vip['ip'] || ''
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
