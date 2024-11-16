# Cookbook:: postgresql
# Provider:: config

include Postgresql::Helper

action :add do
  begin
    user = new_resource.user
    routes = local_routes()

    begin
      postgresql_vip = data_bag_item('rBglobal', 'ipvirtual-internal-postgresql')
    rescue
      postgresql_vip = {}
    end

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
          unless postgresql_vip['ip']
            serf_output = `serf members`
            master_node = serf_output.lines.find do |line|
              line.include?('alive') && line.include?('postgresql=ready') && line.include?('leader=ready')
            end

            if master_node
              master_ip = master_node.split[1].split(':')[0]
              local_ips = `hostname -I`.split
      
              if local_ips.exclude?(master_ip)
                Chef::Log.info("Master node detected at: #{master_ip}. Syncing from master...")
                sync_command = "rb_sync_from_master.sh #{master_ip}"
                system(sync_command)
              end
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
          master_ip = nil
          if postgresql_vip['ip']
            master_ip = postgresql_vip['ip']
          else
            serf_output = `serf members`
            master_node = serf_output.lines.find { |line| line.include?('postgresql=ready') && line.include?('alive') }
            if master_node
              master_ip = master_node.split[1].split(':')[0]
            end
          end
          if master_ip
            ::File.open(hosts_file, 'a') do |file|
              file.puts "#{master_ip} master.postgresql.service"
            end
            Chef::Log.info("Added #{master_ip} master.postgresql.service to /etc/hosts")
          end
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
