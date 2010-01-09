module JavaBin
  def self.parser=(value)
    @parser = value
  end
  def self.parser
    @parser
  end
 
  require 'java_bin/version'
#  begin
    require 'java_bin/ext'
#  rescue LoadError
#    require 'java_bin/pure'
#  end
end
