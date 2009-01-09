#!ruby

# Required Gems
%w(rubygems syntaxi grit sinatra yaml haml ftools open-uri).each {|d| require d}

Syntaxi::wrap_at_column = 120
Syntaxi::line_number_method = 'floating'
layout 'layout.haml'
get "/" do
  Syntaxi::line_number_method = 'none'
  load_config
  load_repos
  haml :index
end

get "/:name" do
  redirect "/#{params[:name]}/tree/master"
end

get "/:name/commits/:id" do
  @repo = get_repo(params[:name])
  @commits = @repo.commits(params[:id])
  haml :history
end

get "/:name/history/:id" do
  repo = get_repo(params[:name])
  commit = repo.commit(params[:id])
  diff_text = '[code lang="diff"]' + repo.diff(commit.parents[0], commit) + '[/code]'
  @formatted_text = Syntaxi.new(diff_text).process
  haml :diff
end

get "/:name/tree/:id" do
  @repo = get_repo(params[:name])
  @tree = @repo.tree(params[:id])
  haml :tree
end

get "/:name/tree/:id/*" do
  path = request.path_info.gsub("/#{params[:name]}/tree/#{params[:id]}/", '')
  repo = get_repo(params[:name])
  branch = repo.tree(params[:id])
  new_tree = path.split('/')
  @tree = traverse(branch, new_tree)
  #if @tree.class == Grit::Blob
  #  file_text = '[code lang="ruby"]' + @tree.data + '[/code]'
  #  @formatted_text = Syntaxi.new(file_text).process
  #end
  
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
  
  def get_tree_by_name(repo, name)
    #Feed this the repo object and the tree location name. The return is new tree object
    r = repo.tree
    return r./(name)
  end
  
  def traverse(branch, path)
    #Feed this the branch to start from and the path as an array. The return is the tree object at the path
    b = branch.clone
    path.each do |t|
      b = b./t
    end
    return b
  end
  
  def build_crumb(u, branch)
    #THIS SHIT IS BROKEN!
    #This will build you a linked crumb for the path and branch.
    tree = u.gsub("/#{params[:name]}/tree/#{params[:id]}", '')
    path = tree.split('/').pop
    basepath = Array.new
    url = nil
    if tree != nil
      path.each do |p|
        if basepath.empty?
          basepath = p + "/"
          uri = basepath
        else
          basepath << p + "/"
          uri = basepath
        end
        
        if url == nil
          url = "<a href='/#{params[:name]}/tree/#{branch}'>#{p}</a>"
        else
          url = "#{url} / <a href='#{uri}'>#{p}</a>"
        end
      end
    else
     url = "<a href='#{branch}'>#{branch}</a>"
    end
    return url
  end
  
  def build_uri(path, glob)
    #This will build the base path uri for the tree's parent.
    uri = path + '/' + glob
    uri = uri.gsub('//', '/') #This is a hack to remove double slashes caused at the top level of the repo
    return uri
  end

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
    File.makedirs(path) unless Dir.new(path)
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