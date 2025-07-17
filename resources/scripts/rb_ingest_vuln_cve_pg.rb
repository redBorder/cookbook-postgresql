#!/usr/bin/env ruby

require 'fileutils'
require 'json'
require 'zlib'
require 'pg'
require 'yaml'

class CVEDatabase
  attr_accessor :cve_files

  def initialize
    @download_path = '/tmp/'
    @cve_url_files = []
    @cve_files = []

    set_cve_files
    @pg_conn = PG.connect(self.class.redborder_pg_conn_info)
    ensure_table
  end

  def self.redborder_pg_conn_info
    config_path = '/var/www/rb-rails/config/database.yml'
    raise "Missing #{config_path}" unless File.exist?(config_path)

    config = YAML.load_file(config_path)
    env = config['production'] || config['development']
    raise 'Missing production or development section in database.yml' unless env

    {
      dbname: env['database'],
      user: env['username'] || 'postgres',
      password: env['password'],
      host: env['host'] || 'localhost',
      port: env['port'] || 5432
    }
  end

  def set_cve_files
    current_year = Time.now.year
    (2002..current_year).each do |year|
      url = "https://nvd.nist.gov/feeds/json/cve/1.1/nvdcve-1.1-#{year}.json.gz"
      @cve_url_files << url
    end
  end

  def import_cve_files
    complete_download = true

    @cve_url_files.each do |url|
      puts "Downloading NVD (MITRE) JSON CVEs file #{url.to_s}"
      filename = File.basename(url)
      puts filename
      puts "curl -k -o #{filename} #{url}"
      system("curl -k -o #{filename} #{url} 2>&1")

      # If file was not downlaoded then we should not do anything
      complete_download = false unless File.exist?(filename)
      break unless complete_download

      system("gunzip -f #{filename}")
      file_json = filename.split('.gz').first
      system("dos2unix #{file_json}")
      @cve_files.push(file_json)
    end

    puts ''
    import_to_postgresql if complete_download
    remove_files
    complete_download
  end

  def ensure_table
    #surpresses the notice message in logs
    @pg_conn.exec("SET client_min_messages TO WARNING;")

    @pg_conn.exec <<~SQL
      CREATE TABLE IF NOT EXISTS cves (
        id SERIAL PRIMARY KEY,
        cve_id TEXT NOT NULL,
        data JSONB NOT NULL
      );
    SQL

    @pg_conn.exec <<~SQL
      CREATE UNIQUE INDEX IF NOT EXISTS idx_cves_cve_id ON cves(cve_id);
    SQL

    @pg_conn.exec <<~SQL
      CREATE INDEX IF NOT EXISTS idx_cves_data_gin ON cves USING gin(data jsonb_path_ops);
    SQL
  end

  def import_to_postgresql
    puts "Importing #{@cve_files.length} CVE JSON files to PostgreSQL..."

    @cve_files.each do |file|
      puts "Processing #{file}"
      content = JSON.parse(File.read(file))
      entries = content['CVE_Items'] || []
      entries.each do |entry|
        cve_id = entry.dig('cve', 'CVE_data_meta', 'ID')
        begin
          @pg_conn.exec_params(
            "INSERT INTO cves (cve_id, data) VALUES ($1, $2)
             ON CONFLICT (cve_id) DO UPDATE SET data = EXCLUDED.data",
            [cve_id, JSON.dump(entry)]
          )
        rescue => e
          puts "Failed to import #{cve_id}: #{e}"
        end
      end
    end
  end

  def remove_files
    puts "Cleaning up downloaded files..."

    # Remove unzipped JSON files
    @cve_files.each do |f|
      File.delete(f) if File.exist?(f)
    end

    # Remove .gz files
    @cve_url_files.each do |url|
      gz_file = File.join(@download_path, File.basename(url))
      File.delete(gz_file) if File.exist?(gz_file)
    end
  end
end

def create_update_log
  File.write('/tmp/rb_vulnerability_load_cvedb_last_update', "#{Time.now}\n")
end

def delete_update_log
  File.delete('/tmp/rb_vulnerability_load_cvedb_last_update') rescue nil
end

puts 'Cleaning last update log...'
delete_update_log

begin
  start_time = Time.now
  cve_db = CVEDatabase.new
  if cve_db.import_cve_files
    puts "CVEs imported successfully."
    create_update_log
  else
    puts "ERROR: Some CVE files failed to download."
    exit 1
  end
  puts "Completed in #{Time.now - start_time} seconds."
rescue => e
  puts "ERROR: #{e.message}"
  exit 1
end

