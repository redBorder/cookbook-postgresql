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

    # Checks if the PostgreSQL instance is the master node.
    def pg_master?
      is_recovery = `sudo -u postgres psql -h 127.0.0.1 -t -c "SELECT pg_is_in_recovery();" 2>/dev/null | tr -d ' \t\n\r'`

      is_recovery == 'f'
    end

    # Queries Serf members to find the master node's IP.
    def find_master_ip_from_serf
      serf_output = `serf members`
      master_ip = serf_output.lines.find do |line|
        line.include?('alive') && line.include?('postgresql_role=master')
      end
      master_ip ? master_ip.split[1].split(':')[0] : nil
    end

    # Fetches the IP address of the master PostgreSQL node.
    def fetch_master_ip(postgresql_vip)
      postgresql_vip['ip'] || find_master_ip_from_serf
    end

    # Updates the hosts file with the master PostgreSQL node's IP.
    def update_hosts_file(hosts_file, master_ip)
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

    # Updates the PostgreSQL configuration file with the master node's IP.
    def update_postgresql_conf(postgresql_conf_file)
      master_ip = find_master_ip_from_serf
      conf_lines = ::File.readlines(postgresql_conf_file)

      updated_lines = conf_lines.map do |line|
        line.strip.start_with?('primary_conninfo') ? line.sub(/host=[^ ]+/, "host=#{master_ip}") : line
      end

      ::File.write(postgresql_conf_file, updated_lines.join)
    end

    # Returns the host from the primary_conninfo line in the PostgreSQL configuration file.
    def postgresql_conf_host(postgresql_conf_file)
      conf_lines = ::File.readlines(postgresql_conf_file)
      primary_conninfo = conf_lines.find { |line| line.strip.start_with?('primary_conninfo') }

      return unless primary_conninfo

      host_part = primary_conninfo.split(' ').find { |part| part.start_with?('\'host=') }
      host_part.split('=')[1]
    end
  end
end
