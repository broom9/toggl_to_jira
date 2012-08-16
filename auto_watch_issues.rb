#!/usr/bin/ruby 
require File.expand_path(File.dirname(__FILE__)) + '/shared.rb'
require 'cgi'
require 'json'

config = load_config()

issues = JSON.parse(`curl -s -X GET -u #{config['jira_user']}:#{config['jira_pass']} -H 'Content-Type: application/json' #{config['jira_url']}/rest/api/#{config['jira_api_version']}/search?jql=#{CGI.escape(config['auto_watch_jql'])}`)['issues']

issues.each do |issue|
  # Use REST API to add myself to watcher, as there is no such SOAP API in JIRA 4 yet
  `curl -s -X POST -u #{config['jira_user']}:#{config['jira_pass']} -H 'Content-Type: application/json' #{config['jira_url']}/rest/api/#{config['jira_api_version']}/issue/#{issue['key']}/watchers`
end

