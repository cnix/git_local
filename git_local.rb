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

# need to figure out how to traverse commits
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

# need to figure out how get routing to allow us to drill deeper into trees
get "/tree/:name" do
  @nested_tree = get_tree/params[:name]
  erb :tree
end

post "/add_repo" do
  load_repos
  set_index
  @repo_to_create = { @repo => {'path' => params[:path], 'name' => params[:name]}}
  yaml_to_write
  File.open('repos.yml', 'w') do |w|
    YAML.dump(yaml_to_write, w)
  end
  redirect '/'
end


private

def yaml_to_write
  if @all_repos == false
    @repo_to_create
  else
    @all_repos.merge(@repo_to_create)
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
  if File.exists?("repos.yml")
    @all_repos = YAML::load(open("repos.yml"))
  else
    @all_repos = {}
  end
end

# This thing will likely change alot once multiple repositories are supported
def current_repo
  load_repos
  @all_repos.each {|key,value| return value.to_s unless value.nil? }
end