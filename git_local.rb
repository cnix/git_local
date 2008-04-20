#!ruby
require 'rubygems'
require 'syntaxi'
require 'grit'
require 'sinatra'
require 'yaml'

Syntaxi::wrap_at_column = 120

layout 'layout.erb'

get "/" do
  load_config
  load_repos
  erb :index
end

get "/history/:name" do
  @repo = get_repo(params[:name])
  erb :history
end

# TODO: need to figure out how to traverse commits
get "/history/:name/:id" do
  repo = get_repo(params[:name])
  commit = repo.commit(params[:id])
  diff_text = "[code lang=\"ruby\"]" + repo.diff(commit.parents[0], commit) + "[/code]"
  @formatted_text = Syntaxi.new(diff_text).process
  erb :diff
end

get "/tree/:name" do
  @tree = get_repo(params[:name]).tree
  erb :tree
end

get "/tree/:name/*" do
  path = request.path_info.gsub("/tree/#{params[:name]}/", '')
  if path.split('/').length >= 2
    new_tree = path.split('/').pop
    new_tree.to_s
    @tree = get_repo(params[:name]).tree(new_tree)
  else
    @tree = get_repo(params[:name]).tree
  end
   
  erb :tree
end

post "/create_repo_path" do
  create_repositories_path(params[:path])
  redirect '/'
end

post "/add_repo" do
  load_repos
  set_index
  load_config
  path = @config['path'] + '/' + underscorify(params[:name]) + '.git'
  @repo_to_create = { @repo => {'path' => path, 'name' => params[:name], 'formatted_name' => underscorify(params[:name])}}
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

def get_repo(name)
  load_repos
  @all_repos.each do |key,value|
    if name == value['formatted_name']
      @path = value['path']
    else
      raise "Path Does Not Exist #{@repo.inspect}"
    end
  end
  Grit::Repo.new(@path)
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

def underscorify(params)
  params.gsub(/[^a-z0-9]+/i, '_').downcase
end
