# vim:fileencoding=utf-8
require 'rubygems'
require 'test/unit'

ENV['TZ']='JST-9'
$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'java_bin'

class Test::Unit::TestCase
end
