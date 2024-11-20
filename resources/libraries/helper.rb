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
      Chef::Log.info("Updated /etc/hosts with master.postgresql.service pointing to #{master_ip}")
    end

    def sync_if_not_master(master_ip)
      local_ips = `hostname -I`.split
      unless local_ips.include?(master_ip)
        Chef::Log.info("Syncing from master at #{master_ip}...")
        system("rb_sync_from_master.sh #{master_ip}")
      end
    end
  end
end
