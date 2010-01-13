# RSolr support

if defined? RSolr::Client

  class RSolr::Client
    protected
  
    def map_params(params)
      params ||= {}
      {:wt=>:javabin}.merge(params)
    end
  
    def adapt_response_with_java_bin(connection_response)
      data = adapt_response_without_java_bin(connection_response)
      data = JavaBin.parser.new.parse(data) if data.raw[:params][:wt] == :javabin
      data
    end

    alias_method :adapt_response_without_java_bin, :adapt_response
    alias_method :adapt_response, :adapt_response_with_java_bin
  end

end

