#!/usr/bin/env ruby

require 'fileutils'
require 'json'
require 'zlib'
require 'pg'
require 'yaml'
require 'English'

class CVEDatabase
  attr_accessor :cve_files

  def initialize
    @download_path = '/tmp/'
    @cve_url_files = []
    @cve_files = []

    set_cve_files
    @pg_conn = PG.connect(self.class.redborder_pg_conn)
    ensure_table
  end

  def self.redborder_pg_conn
    raw = `knife data bag show passwords db_redborder -F json`
    clean = raw.lines.reject { |line| line.start_with?('INFO:') }.join
    databag = JSON.parse(clean)
    {
      dbname: databag['database'],
      user: databag['username'],
      password: databag['pass'],
      host: databag['hostname'],
      port: databag['port'],
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
      puts "Downloading NVD (MITRE) JSON CVEs file #{url}"
      filename = File.basename(url)

      unless download_gz_file_with_retries(url, filename)
        puts "ERROR: Could not download #{filename} after multiple attempts."
        complete_download = false
        break
      end

      system("gunzip -f #{filename}")
      file_json = filename.sub(/\.gz$/, '')

      if File.exist?(file_json)
        system("dos2unix #{file_json}")
        @cve_files.push(file_json)
      else
        puts "ERROR: JSON file #{file_json} missing after unzip."
        complete_download = false
        break
      end
    end

    import_to_postgresql if complete_download
    remove_files
    complete_download
  end

  def download_gz_file_with_retries(url, destination, max_attempts = 3)
    max_attempts.times do |attempt|
      puts "Attempt ##{attempt + 1} to download #{destination}"
      system("curl -k -o #{destination} #{url}")
      curl_status = $CHILD_STATUS.exitstatus

      if curl_status == 0 && File.exist?(destination)
        file_type = `file #{destination}`
        if file_type.include?('gzip compressed data')
          return true
        else
          puts "Downloaded file is not valid gzip (type: #{file_type.strip})"
        end
      else
        puts "curl failed with exit code #{curl_status}"
      end

      sleep 2
    end

    false
  end

  def ensure_table
    # Surpresses the notice message in logs
    @pg_conn.exec('SET client_min_messages TO WARNING;')

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
    puts 'Cleaning up downloaded files...'

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
  begin
    File.delete('/tmp/rb_vulnerability_load_cvedb_last_update')
  rescue Errno::ENOENT
    nil
  end
end

puts 'Cleaning last update log...'
delete_update_log

begin
  start_time = Time.now
  cve_db = CVEDatabase.new
  if cve_db.import_cve_files
    puts 'CVEs imported successfully.'
    create_update_log
  else
    puts 'ERROR: Some CVE files failed to download.'
    exit 1
  end
  puts "Completed in #{Time.now - start_time} seconds."
rescue => e
  puts "ERROR: #{e.message}"
  exit 1
end
