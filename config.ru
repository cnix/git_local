require 'rubygems'
require 'sinatra'
 
Sinatra::Application.default_options.merge!(
  :run => false,
  :env => :production
)

if File.exists?('config/http_auth.yml')
  credentials = YAML::load(open('config/http_auth.yml'))
  use Rack::Auth::Basic do |username, password|
    username == credentials['username'] && password == credentials['password']
  end
end
 
require 'git_local.rb'
run Sinatra.application