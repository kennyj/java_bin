# vim:fileencoding=utf-8
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'test/unit'

class Test::Unit::TestCase
  READ_UTF8 = (RUBY_VERSION >= '1.9' ? 'rb:utf-8' : 'rb')
  READ_ASCII = (RUBY_VERSION >= '1.9' ? 'rb:ascii' : 'rb')
end

require 'rsolr'
require 'mocha/setup'

require 'bundler'
Bundler.require

ENV['TZ']='JST-9'


