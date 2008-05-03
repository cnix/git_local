#!ruby

# Required Gems
%w(rubygems syntaxi grit sinatra yaml haml).each {|d| require d}

Syntaxi::wrap_at_column = 120
Syntaxi::line_number_method = 'floating'
layout 'layout.haml'
get "/" do
  Syntaxi::line_number_method = 'none'
  load_config
  load_repos
  haml :index
end

get "/history/:name" do
  @repo = get_repo(params[:name])
  haml :history
end

# TODO: need to figure out how to traverse commits
get "/history/:name/:id" do
  repo = get_repo(params[:name])
  commit = repo.commit(params[:id])
  diff_text = '[code lang="diff"]' + repo.diff(commit.parents[0], commit) + '[/code]'
  @formatted_text = Syntaxi.new(diff_text).process
  haml :diff
end

get "/tree/:name" do
  @tree = get_repo(params[:name]).tree
  haml :tree
end

get "/tree/:name/*" do
  path = request.path_info.gsub("/tree/#{params[:name]}/", '')
  if path.split('/').length >= 2
    new_tree = path.split('/').pop
    @tree = get_repo(params[:name]).tree(new_tree)
    @blob = get_repo(params[:name]).blob(new_tree)
    file_text = '[code lang="ruby"]' + @blob.data + '[/code]'
    @formatted_text = Syntaxi.new(file_text).process
  else
    @tree = get_repo(params[:name]).tree
  end
   
  haml :tree
end

post "/create_repo_path" do
  create_repositories_path(params[:path], params[:username])
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

get '/stylesheet.css' do
  header 'Content-Type' => 'text/css; charset=utf-8'
  sass :stylesheet
end

helpers do

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

  def create_repositories_path(path, username)
    load_config
    Dir.mkdir(path)
    @config_to_create = { 'path' => path, 'username' => username }
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
end