# vim:fileencoding=utf-8
require 'rubygems'
require 'bundler'
require 'test/unit'

ENV['TZ']='JST-9'
$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

Bundler.require(:test)

require 'java_bin'

class Test::Unit::TestCase
  READ_UTF8 = (RUBY_VERSION >= '1.9' ? 'rb:utf-8' : 'rb')
  READ_ASCII = (RUBY_VERSION >= '1.9' ? 'rb:ascii' : 'rb')
end
