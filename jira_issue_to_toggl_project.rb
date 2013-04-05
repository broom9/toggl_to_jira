#!/usr/bin/ruby 
require File.expand_path(File.dirname(__FILE__)) + '/shared.rb'
require 'curb'

config = load_config()

# Fetch clients
clients = toggl_get("https://www.toggl.com/api/v8/workspaces/#{config["toggl_workspace_id"]}/clients", config)
puts JSON.pretty_generate(clients)

# Fetch existing projects
projects = toggl_get("https://www.toggl.com/api/v8/workspaces/#{config["toggl_workspace_id"]}/projects", config).each{|p| p["jira_key"] = p["name"][/[A-Z]+-\d+/]}
puts JSON.pretty_generate(projects)

# Fetch JIRA issues
issues = JSON.parse(`curl -s -X GET -u #{config['jira_user']}:#{config['jira_pass']} -H 'Content-Type: application/json' #{config['jira_url']}/rest/api/#{config['jira_api_version']}/search?jql=#{CGI.escape(config['jira_sync_jql'])}`)['issues']
puts JSON.pretty_generate(issues)

# Create/update Toggl projects

issues.each do |issue|
	# Find client
	jira_client_name = issue['fields']['customfield_12190'][0]['value'];
	toggl_client = clients.find{|c| c["name"].casecmp(jira_client_name) == 0}
	# Or create a new client
	if !toggl_client && jira_client_name
		puts "Create client #{jira_client_name}"
		toggl_post("https://www.toggl.com/api/v8/clients", {
			"client" => {
				"name" => jira_client_name,
				"wid" => config["toggl_workspace_id"]
			}
		}, config)
		puts "Reload clients"
		clients = toggl_get("https://www.toggl.com/api/v8/workspaces/#{config["toggl_workspace_id"]}/clients", config)
		toggl_client = clients.find{|c| c["name"].casecmp(jira_client_name) == 0}
	end

	existing_project = projects.find{|p| p["jira_key"] == issue["key"]}
	if existing_project
		json_data = 
		{ 
			"project" => {
				"name" => issue['key'] + ", " + issue['fields']['summary'],
				"cid" => toggl_client ? toggl_client["id"] : nil
			}
		}
		puts "#{issue["key"]} Find an existing project, putting #{JSON.pretty_generate(json_data)}"
		toggl_put("https://www.toggl.com/api/v8/projects/#{existing_project["id"]}", json_data, config)
	else
		json_data = 
		{ 
			"project" => {
				"billable" => false,
				"wid" => config['toggl_workspace_id'],
				"name" => issue['key'] + ", " + issue['fields']['summary'],
				"cid" => toggl_client ? toggl_client["id"] : nil,
				"is_private" => false
			}
		}
		puts "#{issue["key"]} Create a new project, posting #{JSON.pretty_generate(json_data)}"
		toggl_post("https://www.toggl.com/api/v8/projects", json_data, config)
	end
end

