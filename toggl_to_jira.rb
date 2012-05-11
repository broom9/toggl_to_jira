#!/usr/bin/ruby 
require "net/https"
require "uri"
require 'cgi'
require 'rubygems'
require 'active_support/all'
require 'json'
require 'jira4r'
require 'yaml'

CONFIG = YAML.load_file('config.yml') unless defined? CONFIG
CONFIG['start_time'] ||= Time.now.beginning_of_day.iso8601
uri = URI.parse("https://www.toggl.com/api/v6/time_entries.json?start_date=#{CGI.escape(CONFIG['start_time'])}" + 
								(CONFIG['end_time'].blank? ? '' : "&end_date=#{CGI.escape(CONFIG['end_time'])}"))
http = Net::HTTP.new(uri.host, uri.port)
http.use_ssl = true
http.verify_mode = OpenSSL::SSL::VERIFY_NONE

puts "Connecting to toggl starting from #{CONFIG['start_time']}"
request = Net::HTTP::Get.new(uri.request_uri)
request.basic_auth(CONFIG['toggl_key'], "api_token")

response = http.request(request)
begin
	json = JSON.parse(response.body)
	raise unless json['data']
rescue 
	puts "Request to toggl failed"
	puts $! 
	puts response.inspect 
	exit(1) 
end

entries = json['data']
puts "Got #{entries.length} entries from toggl"

puts "Connecting to JIRA"
begin
	logger = Logger.new(STDERR)
	logger.sev_threshold = Logger::WARN
	jira = Jira4R::JiraTool.new(2, CONFIG['jira_url'])
	jira.logger = logger
  # jira.driver.options["protocol.http.ssl_config.verify_mode"] = nil
	jira.login CONFIG['jira_user'], CONFIG['jira_pass']
rescue
	puts "Failed to login to JIRA"
	puts $!
	exit(1)
end
puts "Successfully login to JIRA as #{CONFIG['jira_user']}"


