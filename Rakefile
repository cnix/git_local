require 'rake'
require 'lib/rake_utils'

# desc "Open an irb session preloaded with this library"
# task :console do
#   sh "irb -rubygems -r git_local.rb"
# end

desc "Setup git_local"
task :setup do
  check_for_pygmentize
  puts "\nWould you like to create a symlink in /usr/bin to the git_local command line utility? (y/n)"
  a = STDIN.gets.downcase
  a =~ /n|no/ ? puts("Skipping symlink") : create_symlink
  puts "\n## If you're using Phusion Passenger (or some other server/module that uses Rack)"
  puts "## You can have Basic HTTP Authentication with Rack::Auth"
  puts "\nWould you like to use HTTP Authentication? (y/n)"
  a = STDIN.gets.downcase
  a =~ /n|no/ ? puts("Skipping HTTP Authentication") : setup_http_auth
  puts "\nSetup is now complete!"
end