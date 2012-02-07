# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

require 'pantry/version'

Gem::Specification.new do |s|
  s.name = "pantry"
  s.version = Pantry::VERSION
  s.platform = Gem::Platform::RUBY
  s.authors = ["Mark Ratjens"]
  s.email = ["mark@habanerohq.com"]
  s.homepage = "http://www.habanerohq.com"
  s.summary = %q{A database unload/reload tool with smarts.}

  s.files = `git ls-files`.split("\n")
  s.test_files = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  # add_dependency for rails stuff, probably ActiveRecord

  s.add_development_dependency 'rspec', '~> 2.7'
  s.add_development_dependency 'rspec-rails'
end
