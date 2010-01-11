# vim:fileencoding=utf-8

# usage: gem install json
#        gem install solr-ruby 
#        gem install rsolr
#        ruby (-r profile) performance.rb
begin
  require 'rubygems'
  require 'json/ext'
  require 'solr'
  require 'rsolr'
rescue LoadError => e
  raise "load error. please $ sudo gem install json, and $ sudo gem install solr-ruby, and $ sudo gem install rsolr"
end

require File.dirname(__FILE__) + '/../lib/java_bin.rb'

def parse_ruby(input)
  eval(input)
end

def parse_json(input)
  JSON.parse(input)
end

def parse_javabin(input)
  JavaBin.unmarshal(input)
end

TIMES=1000
TARGETS=%w(ruby json)
#TARGETS=%w(ruby json javabin)
#TARGETS=%w(javabin)
 
def test_parse_speed
  TARGETS.each do |wt|
    open("../fixtures/#{wt}.dat", "r:utf-8") do |f| # for 1.9.x
    #open("#{wt}.dat", "rb") do |f| # for 1.8.x
      input = f.read
      #input = StringIO.new(f.read)
      GC.start
      result = nil # for 1.9.x
      method = "parse_#{wt}"
      s = Time.now
      TIMES.times {
        #input.pos = 0
        result = send(method, input)
      }
      e = Time.now
      #if TIMES == 1
        puts "#{TIMES} times parsed by #{wt} format."
        puts input.encoding if input.respond_to?(:encoding)
        puts result
      #end
      puts "elapsed time #{e - s}"
    end
  end
end

def test_solr_ruby
  puts "***** solr-ruby"
  GC.start
  conn = Solr::Connection.new('http://localhost:8983/solr', :autocommit => :on)
  
  s = Time.now
  response = nil
  TIMES.times {
    response = conn.query('software')
  }
  e = Time.now
  
  puts response.data
  puts "elapsed time #{e - s}"
end

CONC = 1
def test_rsolr
  puts "***** rsolr"
  GC.start

  s = Time.now
  array = []
  CONC.times do
    array << Thread.new do 
      rsolr = RSolr.connect # :url=>'http://localhost:8983/solr'
      response = nil
      #rsolr.keep_alive {
        (TIMES/CONC).times {
          #response = JSON.parse(rsolr.select :q=>'software', :wt => :json, :pt => :standard, :fl => "*,score")
          response = rsolr.select :q=>'software', :wt => :json, :pt => :standard, :fl => "*,score"
          #response = rsolr.select :q=>'software', :wt => :javabin, :pt => :standard, :fl => "*,score"
          #response = rsolr.select :q=>'software', :wt => :ruby, :pt => :standard, :fl => "*,score"
        }
      #}
      puts response
    end
  end
  array.each { |t| t.join }
  e = Time.now
  puts "elapsed time #{e - s}"
end

test_parse_speed
#test_solr_ruby
#test_rsolr

