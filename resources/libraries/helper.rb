module Postgresql
  module Helper
    require 'open3'

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

    def postgres_role
      user = 'rep'
      port = 5432
      db = 'postgres'
      cmd = %(psql -h localhost -U "#{user}" -p #{port} -d "#{db}" -t -A \
      -c "SELECT CASE WHEN pg_is_in_recovery() THEN 'slave' ELSE 'master' END;")
      stdout, _, status = Open3.capture3(cmd)
      return stdout.strip if status.success?

      nil
    end

    def update_hosts_for_master(new_master_ip)
      hosts_file = '/etc/hosts'
      service_name = 'master.postgresql.service'
      new_entry = "#{new_master_ip} #{service_name}"

      begin
        hosts_content = ::File.read(hosts_file).lines.reject { |line| line.include?(service_name) }
        hosts_content << "#{new_entry}\n"
        ::File.open(hosts_file, 'w') { |file| file.puts hosts_content }
      rescue => e
        Chef::Log.error("Error actualizando /etc/hosts: #{e.message}")
      end
    end

    def find_master_ip(is_adding_postgresql)
      cluster_info = node.dig('redborder', 'cluster_info')
      postgresql_managers = node.dig('redborder', 'managers_per_services', 'postgresql')

      if cluster_info && postgresql_managers
        postgres_ips = cluster_info.select { |m, _| postgresql_managers.include?(m) }.map { |_, v| v['ipaddress_sync'] }

        if is_adding_postgresql
          postgres_ips.first
        else
          postgres_ips[1]
        end
      end
    end
  end
end
