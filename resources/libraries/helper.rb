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
  end
end
