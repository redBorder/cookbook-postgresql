module Postgresql 
  module Helper
    require 'net/ip'
    def local_routes()
      # return all local routes that exist in the system
      routes = []
      Net::IP.routes.each do |r|
        next if routes.include?(r.to_h[:prefix])
        next if r.to_h[:scope].nil? or r.to_h[:scope] != "link"
        routes.push(r.to_h[:prefix])
      end
      routes
    end

  end
end
