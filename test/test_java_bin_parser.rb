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

  def write_tag(tag, size, output)
    if ((tag & 0xe0) != 0)
      if (size < 0x1f)
        output.putc(tag | size)
      else
 	output.putc(tag | 0x1f)
 	write_v_int(size - 0x1f, output)
      end 
    else
      output.putc(tag)
      write_v_int(size, output)
    end
  end

  def elapsed_time(name, t, &block)
    GC.start
    s = Time.now
    t.times {
      block.call
    }
    e = Time.now
    puts "#{name}#{t} times. elapsed time #{e - s}"
    (e - s)
  end

  public
  def setup
    @parser = JavaBin.parser.new
  end

  def test_valid_version
    assert @parser.parse([1, 1].pack("C*"))
  end
  def test_invalid_version
    assert_raise(RuntimeError) { @parser.parse([2].pack("C*")) }
  end

  def test_javabin_dat
    result = @parser.parse(open("fixtures/javabin.dat", "r:utf-8").read)
    assert result['response']['docs'][0]['features'].include?('eaiou with umlauts: ëäïöü')
    assert_equal result['response']['docs'][1]['incubationdate_dt'], Time.local(2006, 1, 17, 9, 0, 0)
    assert_equal result['response']['docs'][1]['score'], 0.5030758380889893 
  end

  TIMES = 5000
  def test_javabin_parse_and_ruby_eval
    jb = open("fixtures/javabin.dat", "r:utf-8").read
    r  = open("fixtures/ruby.dat", "r:utf-8").read
    puts ""
    r_et  = elapsed_time("ruby eval parse. ", TIMES) { eval(r) }
    jb_et = elapsed_time("javabin parse.   ", TIMES) { @parser.parse(jb) }
    assert (jb_et * 3) < r_et if @parser.is_a? JavaBin::Ext::Parser
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
    assert_equal  1,  @parser.parse([1, 3, 0x01].pack("C*"))
    assert_equal 127, @parser.parse([1, 3, 0x7f].pack("C*"))
    assert_equal -1,  @parser.parse([1, 3, 0xff].pack("C*"))
    assert_equal -2,  @parser.parse([1, 3, 0xfe].pack("C*"))
  end

  def test_short
    assert_equal  1,    @parser.parse([1, 4, 0x00, 0x01].pack("C*"))
    assert_equal 32767, @parser.parse([1, 4, 0x7f, 0xff].pack("C*"))
    assert_equal -1,    @parser.parse([1, 4, 0xff, 0xff].pack("C*"))
    assert_equal -2,    @parser.parse([1, 4, 0xff, 0xfe].pack("C*"))
  end

  def test_double
    assert_equal -1.0, @parser.parse([1, 5, -1.0].pack("C2G"))
  end

  def test_int
    assert_equal  1,         @parser.parse([1, 6, 0x00, 0x00, 0x00, 0x01].pack("C*"))
    assert_equal 2147483647, @parser.parse([1, 6, 0x7f, 0xff, 0xff, 0xff].pack("C*"))
    assert_equal -1,         @parser.parse([1, 6, 0xff, 0xff, 0xff, 0xff].pack("C*"))
    assert_equal -2,         @parser.parse([1, 6, 0xff, 0xff, 0xff, 0xfe].pack("C*"))
  end

  def test_long
    assert_equal  1,                   @parser.parse([1, 7, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01].pack("C*"))
    assert_equal 9223372036854775807 , @parser.parse([1, 7, 0x7f, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff].pack("C*"))
    assert_equal -1,                   @parser.parse([1, 7, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff].pack("C*"))
    assert_equal -2,                   @parser.parse([1, 7, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xfe].pack("C*"))
  end

  def test_float
    assert_equal -1.0, @parser.parse([1, 8, -1.0].pack("C2g"))
  end

  def test_date
    t = Time.now
    x = (t.to_f * 1000).to_i
    x = [x].pack("q").unpack("C*").reverse # TODO endian次第なので修正必要
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

  def test_large_bytearr
    array = [0,1,255] * 100
    sio = StringIO.new
    sio.putc 1 #VERSION
    sio.putc 13 #JavaBin::BYTEARR
    write_v_int(array.size, sio)
    array.each { |e| sio.putc e }
    sio.pos = 0
    assert_equal array, @parser.parse(sio.read) 
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
    str = "0123456789" * 100
    sio = StringIO.new
    sio.putc 1 #VERSION
    write_tag(1 << 5, str.size, sio)
    str.each_byte { |e| sio.putc e }
    sio.pos = 0
    assert_equal str, @parser.parse(sio.read)
  end

  def test_sint
    assert_equal 8, @parser.parse([1, (2 << 5) | 8].pack("C*"))
    # flunk("not implemented yet.")
  end

  def test_slong
    assert_equal 8, @parser.parse([1, (3 << 5) | 8].pack("C*"))
    # flunk("not implemented yet.")
  end

  def test_arr
    assert_equal [3, 4], @parser.parse([1, (4 << 5) | 2, 3, 3, 3, 4].pack("C*"))
  end

  def test_large_arr
    array = [0, 1, 2, 3, 4] * 100
    sio = StringIO.new
    sio.putc 1 #VERSION
    write_tag(4 << 5, array.size, sio)
    array.each { |e| sio.putc 3; sio.putc e }
    sio.pos = 0
    assert_equal array, @parser.parse(sio.read)
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

  LARGE_SIZE = 1000
  def test_long_large_amount_extern_string
    sio = StringIO.new
    sio.putc 1 #VERSION
    write_tag(4 << 5, LARGE_SIZE, sio)
    LARGE_SIZE.times { |i|
      sio.putc((7 << 5) | 0)
      sio.putc((1 << 5) | 1)
      sio.putc("a")
      write_tag((7 << 5), i, sio)
    }
    sio.pos = 0
    assert_equal ['a'] * LARGE_SIZE, @parser.parse(sio.read)
  end

end
