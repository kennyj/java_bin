# vim:fileencoding=utf-8
require 'java_bin/version'

module JavaBin
  def self.parser=(value)
    @parser = value
  end
  def self.parser
    @parser
  end
 
  begin
    require 'java_bin/ext'
  rescue LoadError => e
    require 'java_bin/pure'
  end
end

# monkey patching
require "rsolr_support"
require "solr_ruby_support"

