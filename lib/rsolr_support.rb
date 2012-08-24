# RSolr support

if defined? RSolr::Client

  class RSolr::Client
    protected

    def send_and_receive_with_java_bin(path, opts={})
      if opts[:params].nil?
        opts[:params]={}
      end
      opts[:params][:wt] = :javabin

      send_and_receive_without_java_bin(path, opts)
    end

    alias_method :send_and_receive_without_java_bin, :send_and_receive
    alias_method :send_and_receive, :send_and_receive_with_java_bin

    def adapt_response_with_java_bin(request, response)
      data = adapt_response_without_java_bin(request, response)
      data = JavaBin.parser.new.parse(data) if request[:params][:wt] == :javabin
      data
    end

    alias_method :adapt_response_without_java_bin, :adapt_response
    alias_method :adapt_response, :adapt_response_with_java_bin
  end

end

