# vim:fileencoding=utf-8
require 'helper'

case ENV['JavaBin']
when 'pure'
then
  require 'java_bin/pure'
else
  require 'java_bin/ext'
end

class TestJavaBin < Test::Unit::TestCase

  private
  def write_v_int(i, output)
    while ((i & ~0x7F) != 0) 
      output.putc(((i & 0x7f) | 0x80))
      # i >>>= 7
      i = (i >> 7) # TODO 論理シフト
    end 
    output.putc(i)
  end

  public
  def setup
    @parser = JavaBin.parser.new
  end

  def test_valid_version
    assert @parser.parse([1, 1].pack("C*"))
  end
  def test_invalid_version
    assert_raise { @parser.parse([2].pack("C*")) }
  end

  def test_javabin_dat
    result = @parser.parse(open("fixtures/javabin.dat", "r:utf-8").read)
    assert result['response']['docs'][0]['features'].include?('eaiou with umlauts: ëäïöü')
    assert_equal result['response']['docs'][1]['incubationdate_dt'], Time.local(2006, 1, 17, 9, 0, 0)
    assert_equal result['response']['docs'][1]['score'], 0.5030758380889893 
  end

  def test_null
    assert_nil @parser.parse([1, 0].pack("C*"))
  end

  def test_true
    assert @parser.parse([1, 1].pack("C*"))
  end

  def test_false
    assert !@parser.parse([1, 2].pack("C*"))
  end

  def test_byte
    assert_equal  1, @parser.parse([1, 3, 0x01].pack("C*"))
    assert_equal -1, @parser.parse([1, 3, 0xff].pack("C*"))
    assert_equal -2, @parser.parse([1, 3, 0xfe].pack("C*"))
  end

  def test_short
    assert_equal  1, @parser.parse([1, 4, 0x00, 0x01].pack("C*"))
    assert_equal -1, @parser.parse([1, 4, 0xff, 0xff].pack("C*"))
    assert_equal -2, @parser.parse([1, 4, 0xff, 0xfe].pack("C*"))
  end

  def test_double
    assert_equal -1.0, @parser.parse([1, 5, -1.0].pack("C2G"))
  end

  def test_int
    assert_equal  1, @parser.parse([1, 6, 0x00, 0x00, 0x00, 0x01].pack("C*"))
    assert_equal -1, @parser.parse([1, 6, 0xff, 0xff, 0xff, 0xff].pack("C*"))
    assert_equal -2, @parser.parse([1, 6, 0xff, 0xff, 0xff, 0xfe].pack("C*"))
  end

  def test_long
    assert_equal  1, @parser.parse([1, 7, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01].pack("C*"))
    assert_equal -1, @parser.parse([1, 7, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff].pack("C*"))
    assert_equal -2, @parser.parse([1, 7, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xfe].pack("C*"))
  end

  def test_float
    assert_equal -1.0, @parser.parse([1, 8, -1.0].pack("C2g"))
  end

  def test_date
    t = Time.now
    x = (t.to_f * 1000).to_i
    x = [x].pack("q").unpack("C*").reverse
    assert_equal t.to_i, @parser.parse(([1, 9] + x).pack("C*")).to_i
  end

  def test_map
    assert_equal({0 => 0, 1 => 1}, @parser.parse([1, 10, 2, 3, 0, 3, 0, 3, 1, 3, 1].pack("C*")))
  end

  def test_solrdoc
    arr = [1, 11] + [(5 << 5) | 2] + [(1 << 5) | 1] + "a".unpack("C*") + [3, 8] + [(1 << 5) | 1] + "b".unpack("C*") + [3, 9]
    assert_equal({"a" => 8, "b" => 9}, @parser.parse(arr.pack("C*")))
  end

  def test_solrdoclst
    arr = [1, 12] + [(4 << 5) | 3, 3, 3, 3, 4, 3, 5] + [(4 << 5) | 0]
    assert_equal({'numFound' => 3, 'start' => 4, 'maxScore' => 5, 'docs' => []}, @parser.parse(arr.pack("C*")))
  end

  def test_bytearr
    array = [0, 1, 0xff]
    assert_equal array, @parser.parse([1, 13, array.size, *array].pack("C*"))
  end

  def test_iterator
    assert_equal([0, 127, nil, true], @parser.parse([1, 14, 3, 0, 3, 127, 0, 1,15].pack("C*")))
  end

#  def test_term
#  end

  def test_string
    assert_equal "あい", @parser.parse(([1, (1 << 5) | 2] + "あい".unpack("C*")).pack("C*"))
  end

  def test_long_string
    flunk("not implemented yet.")
  end

  def test_sint
    flunk("not implemented yet.")
  end

  def test_slong
    flunk("not implemented yet.")
  end

  def test_arr
    assert_equal [3, 4], @parser.parse([1, (4 << 5) | 2, 3, 3, 3, 4].pack("C*"))
  end

  def test_ordered_map
    arr = [1, (5 << 5) | 2] + [(1 << 5) | 1] + "a".unpack("C*") + [3, 8] + [(1 << 5) | 1] + "b".unpack("C*") + [3, 9]
    assert_equal({"a" => 8, "b" => 9}, @parser.parse(arr.pack("C*")))
  end

#  def test_named_lst
#  end

  def test_extern_string
    arr = [1, (5 << 5) | 2] +
          [(1 << 5) | 1] + "a".unpack("C*") +
          [(7 << 5) | 0] + [(1 << 5) | 3] + "あいa".unpack("C*") +
          [(1 << 5) | 1] + "b".unpack("C*") +
          [(7 << 5) | 1]
    assert_equal({"a" => "あいa", "b" => "あいa"}, @parser.parse(arr.pack("C*")))
  end

end
