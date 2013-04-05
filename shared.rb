require 'rubygems'
require 'active_support/all'
require 'json'
require 'yaml'
require 'net/http'
require 'net/https'

# Credit goes to http://www.metachunk.com/blog/adding-osx-keychain-support-ruby-app
def get_keychain_password(key)
  password = nil
  begin
    cmd = "security 2>&1 >/dev/null find-internet-password -gs #{key}"
    password = $1 if `#{cmd}` =~ /^password: "(.*)"$/
  rescue
    password
  end
end

def load_config
	config = YAML.load_file(File.expand_path(File.dirname(__FILE__)) + '/config.yml') 
	config['start_time'] ||= Time.now.beginning_of_day.iso8601
	config['start_time'] = config['start_time'].days.ago.iso8601 if config['start_time'].is_a?(Fixnum)
	if config['jira_pass'].blank?
		config['jira_pass'] = get_keychain_password(config['jira_url'].sub(/http(s)?:\/\//, ''))
    # puts "Got JIRA password from keychain as #{config['jira_pass']}"
	end
	return config
end

def toggl_get(url, config)
	uri = URI.parse(url)
	http = Net::HTTP.new(uri.host, uri.port)
	http.use_ssl = true
	http.verify_mode = OpenSSL::SSL::VERIFY_NONE

	puts "Connecting to toggl #{url}"
	request = Net::HTTP::Get.new(uri.request_uri)
	request.basic_auth(config['toggl_key'], "api_token")

	response = http.request(request)
	begin
		json = JSON.parse(response.body)
		raise unless json
	rescue 
		puts "Request to toggl failed"
		puts $! 
		puts response.inspect 
		exit(1) 
	end

	return json
end

def toggl_post(url, body, config)
	begin
		Curl::Easy.http_post(url, body.to_json) do |curl|
			curl.headers['Content-Type'] = 'application/json'
			curl.http_auth_types = :basic
			curl.username = config['toggl_key']
			curl.password = "api_token"
			# curl.verbose = true
		end
	rescue 
		puts "Request to toggl failed"
		puts $! 
	end
end

def toggl_put(url, body, config)
	begin
		Curl::Easy.http_put(url, body.to_json) do |curl|
			curl.headers['Content-Type'] = 'application/json'
			curl.http_auth_types = :basic
			curl.username = config['toggl_key']
			curl.password = "api_token"
			# curl.verbose = true
		end
	rescue 
		puts "Request to toggl failed"
		puts $! 
	end
end
