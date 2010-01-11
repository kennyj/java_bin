# vim:fileencoding=utf-8
module JavaBin
  module Ext
    #require 'java_bin/ext/parser'
    require 'parser'
    $DEBUG and warn "Using c extension for JavaBin."
    ::JavaBin.parser = ::JavaBin::Ext::Parser
  end
end
