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
      postgres_ips = node['redborder']['cluster_info']
        .select { |m, _| node['redborder']['managers_per_services']['postgresql'].include?(m) }
        .map    { |_, v| v['ipaddress_sync'] }

      postgres_ips.first
    end
  end
end
