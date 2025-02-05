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

    # Queries Serf members to find the master node's IP.
    def find_master_ip_from_serf
      serf_output = `serf members`
      master_ip = serf_output.lines.find do |line|
        line.include?('alive') && line.include?('postgresql=ready')
      end
      master_ip ? master_ip.split[1].split(':')[0] : nil
    end

    # Updates the hosts file with the master PostgreSQL node's IP.
    def update_hosts_file(hosts_file, master_ip)
      return if ::File.readlines(hosts_file).grep(/#{master_ip}\s+master\.postgresql\.service/).any?

      hosts_content = ::File.read(hosts_file).lines.reject { |line| line.include?('postgresql') }
      hosts_content << "#{master_ip} master.postgresql.service\n"
      ::File.open(hosts_file, 'w') { |file| file.puts hosts_content }
    end

    # Returns the file path where the last registered virtual IP is stored.
    def virtual_ip_file
      '/etc/redborder/pg_virtual_ip_registered.txt'
    end

    # Reads the last registered virtual IP from the file.
    def last_registered_virtual_ip
      return unless ::File.exist?(virtual_ip_file)

      ::File.read(virtual_ip_file).strip
    end

    # Checks if the current virtual IP has changed from the last registered virtual IP.
    def virtual_ip_changed?(current_ip)
      last_registered_virtual_ip != current_ip
    end
  end
end
