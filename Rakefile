require 'bundler'
Bundler::GemHelper.install_tasks

require 'rake'
require 'rake/extensiontask'

Rake::ExtensionTask.new do |ext|
  ext.name    = 'parser'
  ext.ext_dir = 'ext/java_bin/ext'
  ext.lib_dir = 'lib/java_bin/ext'
  ext.tmp_dir = 'tmp'
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

task :valgrind => :compile do
  #
  # See:
  # http://blog.flavorjon.es/2009/06/easily-valgrind-gdb-your-ruby-c.html
  #
  def valgrind_errors(what)
    valgrind_cmd="valgrind --log-fd=1 --tool=memcheck --partial-loads-ok=yes --undef-value-errors=no ruby -Ilib:test:ext #{what}"
    puts "Executing: #{valgrind_cmd}"
    output=`#{valgrind_cmd}`
    puts output
    /ERROR SUMMARY: (\d+) ERRORS/i.match(output)[1].to_i
  end

  java_bin_errors = valgrind_errors('test/test_java_bin_parser.rb')

  if java_bin_errors > 0
    abort "Memory leaks are present, please check! (#{java_bin_errors} leaks!)"
  end
end

require 'rdoc/task'
Rake::RDocTask.new do |rdoc|
  require 'java_bin/version'

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "java_bin #{JavaBin::VERSION}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
