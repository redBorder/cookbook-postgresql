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

    def find_master_ip
      cluster_info = node.dig('redborder', 'cluster_info')
      postgresql_managers = node.dig('redborder', 'managers_per_services', 'postgresql')

      if cluster_info && postgresql_managers
        postgres_ips = cluster_info.select { |m, _| postgresql_managers.include?(m) }.map { |_, v| v['ipaddress_sync'] }
        postgres_ips.first
      end
    end
  end
end
