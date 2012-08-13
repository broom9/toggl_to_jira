require 'rubygems'
require 'active_support/all'
require 'json'
require 'jira4r'
require 'yaml'

def load_config
	config = YAML.load_file(File.expand_path(File.dirname(__FILE__)) + '/config.yml') 
	config['start_time'] ||= Time.now.beginning_of_day.iso8601
	config['start_time'] = config['start_time'].days.ago.iso8601 if config['start_time'].is_a?(Fixnum)
	return config
end

def connect_jira(config)
	puts "Connecting to JIRA"
	begin
		logger = Logger.new(STDERR)
		logger.sev_threshold = Logger::WARN
		jira = Jira4R::JiraTool.new(2, config['jira_url'])
		jira.logger = logger
		jira.login config['jira_user'], config['jira_pass']
	rescue
		puts "Failed to login to JIRA"
		puts $!
		exit(1)
	end
	puts "Successfully login to JIRA as #{config['jira_user']}"
	return jira
end
