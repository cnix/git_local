# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{git_local}
  s.version = "0.1.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Claude Nix"]
  s.date = %q{2009-01-23}
  s.description = %q{git_local is an application designed to run on your local network that provides easy web based utilities for managing git repositories}
  s.email = %q{claude@seadated.com}
  s.files = ["README.textile", "VERSION.yml", "bin/git_local", "lib/albino.rb"]
  s.has_rdoc = true
  s.homepage = %q{http://github.com/whatman75/git_local}
  s.rdoc_options = ["--inline-source", "--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.1}
  s.summary = %q{Git repository browser for your local network}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
