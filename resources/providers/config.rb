# Cookbook:: postgresql
# Provider:: config

include Postgresql::Helper

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

      master_node = nil

      ruby_block 'find_postgresql_master' do
        block do
          serf_output = `serf members`
          master_node = serf_output.lines.find do |line|
            line.include?('alive') && line.include?('postgresql=ready') && line.include?('leader=ready')
          end
        end
        action :run
      end

      ruby_block 'sync_if_not_master' do
        block do
          if master_node
            master_ip = master_node.split[1].split(':')[0]
            local_ips = `hostname -I`.split

            unless local_ips.include?(master_ip)
              sync_command = "rb_sync_from_master.sh #{master_ip}"
              Chef::Log.info("Master node is: #{master_ip}. Syncing from master...")
              system(sync_command)
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

    service 'postgresql' do
      service_name 'postgresql'
      ignore_failure true
      supports status: true, reload: true, restart: true, enable: true
      action [:start, :enable]
    end

    ruby_block 'check_postgresql_hosts' do
      block do
        hosts_file = '/etc/hosts'
        hosts_content = ::File.read(hosts_file)
    
        unless hosts_content.include?('master.postgresql.service')
          serf_output = `serf members`
          master_node = serf_output.lines.find { |line| line.include?('postgresql_role=master') && line.include?('alive') }
    
          if master_node
            master_ip = master_node.split[1].split(':')[0]
            
            ::File.open(hosts_file, 'a') do |file|
              file.puts "#{master_ip} master.postgresql.service"
            end
            Chef::Log.info("Added #{master_ip} master.postgresql.service to /etc/hosts")
          end
        end
      end
      action :run
    end

    ruby_block 'check_postgresql_master_status' do
      block do
        is_recovery = `sudo -u postgres psql -h 127.0.0.1 -t -c "SELECT pg_is_in_recovery();" 2>/dev/null | tr -d ' \t\n\r'`
        if is_recovery == 'f'
          Chef::Log.info('Node is the PostgreSQL master, updating Serf tag...')
          system('serf tags -set postgresql_role=master')
        else
          Chef::Log.info('Node is a PostgreSQL standby, updating Serf tag...')
          system('serf tags -set postgresql_role=standby')
        end
      end
      action :run
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
