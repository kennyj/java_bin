module JavaBin
  module Pure
    require 'java_bin/pure/parser'
    $DEBUG and warn "Using pure for JavaBin."
    ::JavaBin.parser = ::JavaBin::Pure::Parser
  end
end
