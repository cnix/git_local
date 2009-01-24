def setup_http_auth
  load_http_auth
  puts "Please enter a username:"
  username = STDIN.gets.chomp!.downcase
  puts "Please enter a password:"
  password = STDIN.gets.chomp!.downcase
  config_to_write = { 'username' => username, 'password' => password }
  File.open('config/http_auth.yml', 'w') do |w|
    YAML.dump(config_to_write, w)
  end
  puts "\nHTTP Authentication will be used with the credentials you supplied"
  rescue "Something went wrong"
end

def create_symlink
  f = '/usr/bin/git_local'
  unless File.exists?(f)
    puts "Please enter your root password..."
    wd = pwd
    sh "sudo ln -s #{wd}/bin/git_local /usr/bin/"
  else
    puts "Your symlink is already up to date"
  end
end

def check_for_pygmentize
  puts "Checking for Pygments..."
  sh "which pygmentize"
  puts "Pygmentize found!"
  rescue => e
  puts "WARNING: Pygments not found - checking for Python easy_install"
  check_for_easy_install
end

def check_for_easy_install
  puts "Checking for Python easy_install"
  sh "which easy_install"
  puts "Found easy_install - attempting to install Pygments..."
  install_pygments
  rescue => e
  puts 'FATAL: Python easy_install cannot be found'
  puts 'Please install python and re-run the setup task'    
end

def install_pygments
  puts "This operation will require your root password"
  sh "sudo easy_install Pygments"
  puts "SUCCESS!! Pygments has been installed on your system"
end

def load_http_auth
  if File.exists?('config/http_auth.yml')
    @credentials = YAML::load(open('config/http_auth.yml'))
  else
    @credentials = {}
  end
end