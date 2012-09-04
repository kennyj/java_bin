require 'rubygems'
require 'rake'
require 'rake/extensiontask'

Rake::ExtensionTask.new do |ext|
  ext.name = 'parser'                # indicate the name of the extension.
  ext.ext_dir = 'ext/java_bin/ext'         # search for 'hello_world' inside it.
  ext.lib_dir = 'lib/java_bin/ext'              # put binaries into this folder.
  ext.tmp_dir = 'tmp'                     # temporary folder used during compilation.
end

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "java_bin"
    gem.summary = %Q{Apache Solr JavaBin format implementation for Ruby.}
    gem.description = %Q{Apache Solr JavaBin format (binary format) implementation for Ruby.}
    gem.email = "kennyj@gmail.com"
    gem.homepage = "http://github.com/kennyj/java_bin"
    gem.authors = ["kennyj"]
    gem.require_paths = ["lib", "ext"]
    # gem is a Gem::Specification... see http://www.rubygems.org/read/chapter/20 for additional settings
  end
  Jeweler::RubygemsDotOrgTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'test' << 'ext'
  test.pattern = 'test/**/test_*.rb'
  test.verbose = true
end

begin
  require 'rcov/rcovtask'
  Rcov::RcovTask.new do |test|
    test.libs << 'test'
    test.pattern = 'test/**/test_*.rb'
    test.verbose = true
  end
rescue LoadError
  task :rcov do
    abort "RCov is not available. In order to run rcov, you must: sudo gem install spicycode-rcov"
  end
end

task :test => :compile

task :default => :test

require 'rdoc/task'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "java_bin #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
