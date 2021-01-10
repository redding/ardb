# -*- encoding: utf-8 -*-
# frozen_string_literal: true

lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "ardb/version"

Gem::Specification.new do |gem|
  gem.name        = "ardb"
  gem.version     = Ardb::VERSION
  gem.authors     = ["Kelly Redding", "Collin Redding"]
  gem.email       = ["kelly@kellyredding.com", "collin.redding@me.com"]
  gem.summary     = "Activerecord database tools."
  gem.description = "Activerecord database tools."
  gem.homepage    = "http://github.com/redding/ardb"
  gem.license     = "MIT"

  gem.files = `git ls-files`.split($INPUT_RECORD_SEPARATOR)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.required_ruby_version = "~> 2.5"

  gem.add_development_dependency("much-style-guide", ["~> 0.6.0"])
  gem.add_development_dependency("assert",           ["~> 2.19.3"])

  gem.add_dependency("activerecord",  ["> 5.0", "< 7.0"])
  gem.add_dependency("activesupport", ["> 5.0", "< 7.0"])
  gem.add_dependency("much-mixin",    ["~> 0.2.4"])
  gem.add_dependency("scmd",          ["~> 3.0.4"])
end
