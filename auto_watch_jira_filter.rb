#!/usr/bin/ruby 
require File.expand_path(File.dirname(__FILE__)) + '/shared.rb'

config = load_config()

jira = connect_jira(config)

issues = jira.getIssuesFromFilter(config['watch_filter'])

issues.each do |issue|
  # Use REST API to add myself to watcher, as there is no such SOAP API in JIRA 4 yet
  # puts "curl -X POST -u #{config['jira_user']}:#{config['jira_pass']} -H 'Content-Type: application/json' #{config['jira_url']}/rest/api/#{config['jira_api_version']}/issue/#{issue.key}/watchers"
  `curl -s -X POST -u #{config['jira_user']}:#{config['jira_pass']} -H 'Content-Type: application/json' #{config['jira_url']}/rest/api/#{config['jira_api_version']}/issue/#{issue.key}/watchers`
end

