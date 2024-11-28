module Postgresql
  module Helper
    def local_routes
      routes = []

      # Ejecuta el comando `ip route` y captura su salida
      ip_route_output = `ip route`
      ip_route_output.each_line do |line|
        next unless line.include?('link')
        # Obtiene el prefijo (por ejemplo, '192.168.1.0/24')
        prefix = line.split[0]
        routes.push(prefix) unless routes.include?(prefix)
      end
      routes
    end

    def sync_from_master
      serf_output = `serf members`
      master_node = serf_output.lines.find do |line|
        line.include?('alive') && line.include?('postgresql_role=master')
      end

      master_name = master_node.split[0]
      master_ip = master_node.split[1].split(':')[0]
      local_ips = `hostname -I`.split

      return if local_ips.include?(master_ip)

      Chef::Log.info("Master node detected at: #{master_name}. Syncing from master...")
      system("rb_sync_from_master.sh #{master_name}")
    end

    def fetch_master_ip(postgresql_vip)
      if postgresql_vip['ip']
        postgresql_vip['ip']
      else
        serf_output = `serf members`
        master_node = serf_output.lines.find do |line|
          line.include?('alive') && line.include?('postgresql_role=master')
        end
        master_node ? master_node.split[1].split(':')[0] : nil
      end
    end

    def update_hosts_file(hosts_file, master_ip)
      hosts_content = ::File.read(hosts_file).lines.reject { |line| line.include?('postgresql') }
      hosts_content << "#{master_ip} master.postgresql.service\n"
      ::File.open(hosts_file, 'w') { |file| file.puts hosts_content }
    end

    def virtual_ip_file
      '/etc/redborder/pg_virtual_ip_registered.txt'
    end

    def last_registered_virtual_ip
      return unless ::File.exist?(virtual_ip_file)

      ::File.read(virtual_ip_file).strip
    end

    def virtual_ip_changed?(current_ip)
      last_registered_virtual_ip != current_ip
    end
  end
end
