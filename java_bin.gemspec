# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'java_bin/version'

Gem::Specification.new do |s|
  s.date        = "2012-10-10"
  s.name        = "java_bin"
  s.version     = JavaBin::VERSION
  s.authors     = ["kennyj"]
  s.email       = ["kennyj@gmail.com"]
  s.description = "Apache Solr JavaBin format (binary format) implementation for Ruby."
  s.summary     = "Apache Solr JavaBin format implementation for Ruby."
  s.homepage    = "http://github.com/kennyj/java_bin"

  s.files       = `git ls-files`.split($/)
  s.test_files  = `git ls-files -- {test,spec,features}/*`.split("\n")

  s.extensions = ["ext/java_bin/ext/extconf.rb"]
  s.extra_rdoc_files = [ "LICENSE", "README.rdoc" ]
  s.require_paths = ["lib", "ext"]

  s.rubygems_version = "1.8.24"
  s.add_development_dependency(%q<rake-compiler>, [">= 0.8.1"])
  s.add_development_dependency(%q<json>, [">= 1.7.5"])
  s.add_development_dependency(%q<rsolr>, [">= 1.0.8"])
  s.add_development_dependency(%q<mocha>, [">= 0.12.6"])
  s.add_development_dependency(%q<rdoc>, [">= 2.4.2"])
end

