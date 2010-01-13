# Solr-Ruby support

#  solr-ruby request class hierarchy
#
#  base
#    ping
#    update
#      add_document
#      commit
#      delete
#      modify_document
#      optimize
#    select        => :response_format, :to_hash
#      index_info
#      standard
#        dismax
#      spellcheck
#  
#  solr-ruby response class hierarchy 
#
#  base            => :make_response
#    xml
#      add_document
#      commit
#        optimize
#      delete
#      modify_document
#      ping
#    ruby          => :initialize 
#      index_info
#      select
#      spellcheck
#      standard
#        dismax

if defined? Solr::Request::Base

  class Solr::Request::Select
    def response_format
      :javabin
    end
    def to_hash
      return {:qt => query_type, :wt => 'javabin'}.merge(@select_params)
    end
  end

  class Solr::Response::Base
    def self.make_response(request, raw)
  
      # make sure response format seems sane
      unless [:xml, :ruby, :javabin].include?(request.response_format)
        raise Solr::Exception.new("unknown response format: #{request.response_format}" )
      end
  
      # TODO: Factor out this case... perhaps the request object should provide the response class instead?  Or dynamically align by class name?
      #       Maybe the request itself could have the response handling features that get mixed in with a single general purpose response object?
      
      begin
        klass = eval(request.class.name.sub(/Request/,'Response'))
      rescue NameError
        raise Solr::Exception.new("unknown request type: #{request.class}")
      else
        klass.new(raw)
      end
      
    end
  
  end

  # FIXME. I should create Solr::Response::JavaBin class,
  #        but response class hierarchy doesn't permit it ! (kennyj) 
  class Solr::Response::Ruby < Solr::Response::Base
    def initialize(java_bin_data)
      super
      begin
        #TODO: what about pulling up data/header/response to ResponseBase,
        #      or maybe a new middle class like SelectResponseBase since
        #      all Select queries return this same sort of stuff??
        #      XML (&wt=xml) and Ruby (&wt=ruby) responses contain exactly the same structure.
        #      a goal of solrb is to make it irrelevant which gets used under the hood, 
        #      but favor Ruby responses.
        @data = ::JavaBin.parser.new.parse(java_bin_data)
        @header = @data['responseHeader']
        raise "response should be a hash" unless @data.kind_of? Hash
        raise "response header missing" unless @header.kind_of? Hash
      rescue SyntaxError => e
        raise Solr::Exception.new("invalid java bin data: #{e}")
      end
    end
  end

end

