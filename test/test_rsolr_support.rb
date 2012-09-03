require 'helper'

class TestRSolrSupportTest < Test::Unit::TestCase
  def test_queries_are_performed_with_javabin

    rsolr_connection=mock()
    rsolr_connection.expects(:execute).
            with { |rsolr_client, params|
              assert_equal({:wt => :javabin}, params[:params])
            }.
            returns(:status => 200,
                    :headers => '',
                    :body => open(File.join(File.dirname(__FILE__), '..', 'fixtures', 'javabin2.dat'), READ_ASCII).read)

    RSolr::Connection.expects(:new).returns(rsolr_connection)

    rsolr = RSolr.connect

    assert_equal({"status" => 0,
                  "QTime" => 0,
                  "params" =>
                      {"indent" => "on",
                       "start" => "0",
                       "q" => "*:*\r\n",
                       "wt" => "javabin",
                       "version" => "2.2",
                       "rows" => "100"}}, rsolr.select(:q => 'whatever')['responseHeader'])
  end
end