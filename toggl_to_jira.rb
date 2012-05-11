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

IMPORTED_FILE = File.expand_path(File.dirname(__FILE__)) + "/imported.yml"
imported = (YAML.load_file(IMPORTED_FILE) rescue [])

puts "Connecting to JIRA"
begin
	logger = Logger.new(STDERR)
	logger.sev_threshold = Logger::WARN
	jira = Jira4R::JiraTool.new(2, CONFIG['jira_url'])
	jira.logger = logger
	jira.login CONFIG['jira_user'], CONFIG['jira_pass']
rescue
	puts "Failed to login to JIRA"
	puts $!
	exit(1)
end
puts "Successfully login to JIRA as #{CONFIG['jira_user']}"

entries.each do |entry|
	id = entry['id']
	start = Time.iso8601(entry['start'])
	duration = entry['duration'].to_i
	desc = entry['description']
	desc += " #{entry['project']['name']}" if entry['project'] and entry['project']['name']
	jira_key = $1 if desc =~ /([A-Z]+-\d+)/

	if imported.include?(id)
		puts "Entry '#{desc}' is skipped as it was already imported"
	elsif entry['duration'].to_i < 0
		puts "Entry '#{desc}' is skipped as it's still running"
	elsif entry['duration'].to_i == 0
		puts "Entry '#{desc}' is skipped as its duration is zero"
	elsif jira_key.blank?
		puts "Entry '#{desc}' is skipped as it doesn't have a JIRA ticket key"
	else
		remoteWorklog = Jira4R::V2::RemoteWorklog.new
		remoteWorklog.comment = "#{desc} , generated from toggl_to_jira script"
		remoteWorklog.startDate = start
		remoteWorklog.timeSpent = "#{(duration / 60.0).round}m"
		puts "Adding worklog #{remoteWorklog.timeSpent.rjust(4)} from #{remoteWorklog.startDate.localtime.strftime('%b %e, %l:%M %p')} to ticket #{jira_key}"
		begin
			jira.addWorklogAndAutoAdjustRemainingEstimate(jira_key, remoteWorklog)
			imported.push id
			File.open(IMPORTED_FILE, "w") {|f| f.write(imported.to_yaml) }
		rescue SOAP::Error => error
			STDERR.puts "Error: " + error
		end
	end
end
