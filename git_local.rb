#!ruby
require 'rubygems'
require 'syntaxi'
require 'grit'
require 'sinatra'
require 'yaml'

Syntaxi::wrap_at_column = 120

layout 'layout.erb'

get "/" do
  load_repos
  erb :index
end

get "/history" do
  @repo = get_repo
  erb :history
end

# TODO: need to figure out how to traverse commits
get "/history/:id" do
  repo = get_repo
  commit = repo.commit(params[:id])
  diff_text = "[code lang=\"ruby\"]" + repo.diff(commit.parents[0], commit) + "[/code]"
  @formatted_text = Syntaxi.new(diff_text).process
  erb :diff
end

get "/tree" do
  @tree = get_tree
  erb :tree
end

# TODO: Figure out how to get routing to allow us to drill deeper into trees
get "/tree/:name" do
  @nested_tree = get_tree/params[:name]
  erb :tree
end

get "/admin" do
  load_config
  erb :admin
end

post "/create_repo_path" do
  create_repositories_path(params[:path])
  redirect '/admin'
end

post "/add_repo" do
  load_repos
  set_index
  load_config
  path = @config['path'] + '/' + underscorify(params[:name]) + '.git'
  @repo_to_create = { @repo => {'path' => path, 'name' => params[:name]}}
  yaml_to_write
  File.open('config/repos.yml', 'w') do |w|
    YAML.dump(yaml_to_write, w)
  end
  init_new_git(path)
  redirect '/'
end

private

def init_new_git(path)
  Grit::Repo.init_bare(path)
end

def yaml_to_write
  if @all_repos == false
    @repo_to_create
  else
    @all_repos.merge(@repo_to_create)
  end
end

# TODO: refactor above and below methods
def config_to_write
  if @config == false
    @config_to_create
  else
    @config.merge(@config_to_create)
  end
end

def load_config
  if File.exists?("config/config.yml")
    @config = YAML::load(open("config/config.yml"))
  else
    @config = {}
  end
end

def create_repositories_path(path)
  load_config
  Dir.mkdir(path)
  @config_to_create = { 'path' => path }
  config_to_write
  File.open('config/config.yml', 'w') do |w|
    YAML.dump(config_to_write, w)
  end
end

def set_index
  if @all_repos == false
    @repo = 'repository_1'
  else
    @repo = 'repository_' + (@all_repos.size + 1).to_s
  end
end

def get_repo
  Grit::Repo.new(current_repo)
end

def get_tree
  Grit::Repo.new(current_repo).tree
end

def load_repos
  if File.exists?("config/repos.yml")
    @all_repos = YAML::load(open("config/repos.yml"))
  else
    @all_repos = {}
  end
end

def all_repos_path
  config = YAML::load(open("config/config.yml"))
  config.each {|key,value| return value.to_s unless value.nil? }
end

# This thing will likely change alot once multiple repositories are supported
def current_repo
  load_repos
  @all_repos.each {|key,value| return value.to_s unless value.nil? }
end

def underscorify(params)
  params.gsub(/[^a-z0-9]+/i, '_').downcase
end
