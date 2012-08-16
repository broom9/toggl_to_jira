#!/usr/bin/ruby 
require File.expand_path(File.dirname(__FILE__)) + '/shared.rb'
require 'curb'

config = load_config()

issue_key = ARGV[0]

if issue_key.blank?
	puts "Need to input an issue key"
	exit 1
end

issue_key = config['default_project'] + "-" + issue_key if issue_key =~ /\d+/

issue = JSON.parse(`curl -v -X GET -u #{config['jira_user']}:#{config['jira_pass']} -H 'Content-Type: application/json' #{config['jira_url']}/rest/api/#{config['jira_api_version']}/issue/#{issue_key}`)

if issue
	json_data = 
	{ 
		"project" => {
			"billable" => false,
			"workspace" => { "id" => config['toggl_workspace_id']},
			"name" => issue['key'] + ", " + issue['fields']['summary']['value'],
			"automatically_calculate_estimated_workhours" => false
		}
	}

	Curl::Easy.http_post("https://www.toggl.com/api/v6/projects.json", json_data.to_json) do |curl|
		curl.headers['Content-Type'] = 'application/json'
		curl.http_auth_types = :basic
		curl.username = config['toggl_key']
		curl.password = "api_token"
		# curl.verbose = true
	end
end

