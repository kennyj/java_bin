# vim:fileencoding=utf-8

require File.dirname(__FILE__) + '/../lib/java_bin.rb'
require 'stringio'

describe JavaBin do
  context "#unmarshalを利用する時" do
#    it "1byte目が2ならバージョンチェックエラーになる" do
#      Proc.new {
#        JavaBin.unmarshal(StringIO.new([2].pack("C")))
#      }.should raise_error
#    end
#
#    it "MAP構造を渡すと、Hashが返ってくる" do
#      result = JavaBin.unmarshal(StringIO.new(([1] + [(5 << 5) | 1] + [(1 << 5) | 1] + "a".unpack("C*") + [JavaBin::BYTE, 123]).pack("C*")))
#      result.should == {"a" => 123}
#    end
#
#    it "テストデータで正しい値が取得できる" do
#      javabin_data = JavaBin.unmarshal(open("../fixtures/javabin.dat", "r:utf-8").read)
#      javabin_data['response']['docs'][0]['features'].include?('eaiou with umlauts: ëäïöü').should be_true
#      javabin_data['response']['docs'][1]['incubationdate_dt'].should == Time.local(2006, 1, 17, 9, 0, 0)
#      javabin_data['response']['docs'][1]['score'].should == 0.5030758380889893 
#    end
#  end

#  context "#check_versionを利用する時" do
#    it "1を渡すと、trueが返ってくる" do
#      JavaBin.check_version(1).should be_true
#    end
#  
#    it "2を渡すと、例外が発生する" do
#      Proc.new { JavaBin.check_version(2) }.should raise_error
#    end
#  
#    it "文字列を渡すと、例外が発生する" do
#      Proc.new { JavaBin.check_version("a") }.should raise_error
#    end
#  
#    it "3.14を渡すと、例外が発生する" do
#      Proc.new { JavaBin.check_version(3.14) }.should raise_error
#    end
#  
#    it "nilを渡すと、例外が発生する" do
#      Proc.new { JavaBin.check_version(nil) }.should raise_error
#    end
#  end
end

describe JavaBin::Reader do

#  def write_v_int(i, output)
#    while ((i & ~0x7F) != 0) 
#      output.putc(((i & 0x7f) | 0x80))
#      # i >>>= 7
#      i = (i >> 7) # TODO 論理シフト
#    end 
#    output.putc(i)
#  end

  before do
    @reader = JavaBin::Reader.new('dummy')
    def @reader.set_sio(sio)
      sio.pos = 0
      @input = sio.bytes.to_a
      @current = 0
    end
  end

  context "#read_v_intを利用する時" do
    it "#write_v_intで書き込んだ値が返ってくる" do
      [1, 500, 7000, 65536, 4294967295, 0].each do |i|
        sio = StringIO.new
        write_v_int(i, sio)
        @reader.set_sio(sio)
        @reader.send(:read_v_int).should == i
      end
    end
  end

  context "#read_sizeを利用する時" do
    it "0をかえす" do
      @reader.set_sio(StringIO.new([(1 << 5) | 0].pack("C")))
      @reader.send :read_val
      @reader.send(:read_size).should == 0
    end
    it "100をかえす" do
      pending
    end
  end

  context "#read_valを利用する時" do
#    it "0を渡すと、nilが返り、tag_byteはNULLになる" do
#      @reader.set_sio(StringIO.new([JavaBin::NULL].pack("C")))
#      @reader.send(:read_val).should be_nil
#    end
#
#    it "1を渡すと、trueが返り、tag_byteはBOOL_TRUEになる" do
#      @reader.set_sio(StringIO.new([JavaBin::BOOL_TRUE].pack("C")))
#      @reader.send(:read_val).should be_true
#    end
#
#    it "2を渡すと、falseが返り、tag_byteはBOOL_FALSEになる" do
#      @reader.set_sio(StringIO.new([JavaBin::BOOL_FALSE].pack("C")))
#      @reader.send(:read_val).should be_false
#    end
#
#    it "3を渡すと、tag_byteはBYTEになる" do
#      @reader.set_sio(StringIO.new([JavaBin::BYTE, -1].pack("C*")))
#      @reader.send(:read_val).should == -1
#    end
#
#    it "4を渡すと、tag_byteはSHORTになる" do
#      @reader.set_sio(StringIO.new([JavaBin::SHORT, 0xff, 0xfe].pack("C*")))
#      @reader.send(:read_val).should == -2
#    end
#
#    it "5を渡すと、tag_byteはDOUBLEになる" do
#      @reader.set_sio(StringIO.new([JavaBin::DOUBLE, -1.0].pack("CG")))
#      @reader.send(:read_val).should == -1.0
#    end
#
#    it "6を渡すと、tag_byteはINTになる" do
#      @reader.set_sio(StringIO.new([JavaBin::INT, 0xff, 0xff, 0xff, 0xfe].pack("C*")))
#      @reader.send(:read_val).should == -2
#    end
#
#    it "7を渡すと、tag_byteはLONGになる" do
#      @reader.set_sio(StringIO.new([JavaBin::LONG, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xfe].pack("C*"))) 
#      @reader.send(:read_val).should == -2
#    end
#
#    it "7を渡すと、tag_byteはFLOATになる" do
#      @reader.set_sio(StringIO.new([JavaBin::FLOAT, -1.0].pack("Cg")))
#      @reader.send(:read_val).should == -1.0
#    end
#
#    it "9を渡すと、tag_byteはDATEになる" do
#      t = Time.now
#      x = (t.to_f * 1000).to_i
#      x = [x].pack("q").unpack("C*").reverse
#      @reader.set_sio(StringIO.new(([JavaBin::DATE] + x).pack("C*")))
#      @reader.send(:read_val).to_i.should == t.to_i
#    end
#
#    it "10を渡すと、tag_byteはMAPになる" do
#      sio = StringIO.new([
#                    JavaBin::MAP,
#                    2,
#                    JavaBin::BYTE, 0,
#                    JavaBin::BYTE, 0,
#                    JavaBin::BYTE, 1, 
#                    JavaBin::BYTE, 1
#                    ].pack("C*"))
#      @reader.set_sio(sio)
#      @reader.send(:read_val).should == {0 => 0, 1 => 1}
#    end
#
#    it "11を渡すと、tag_byteはSOLRDOCになる" do
#      arr = [JavaBin::SOLRDOC] + [(5 << 5) | 2] + [(1 << 5) | 1] + "a".unpack("C*") + [JavaBin::BYTE, 8] + [(1 << 5) | 1] + "b".unpack("C*") + [JavaBin::BYTE, 9]
#      @reader.set_sio(StringIO.new(arr.pack("C*")))
#      @reader.send(:read_val).should == {"a" => 8, "b" => 9} 
#    end
#
#    it "12を渡すと、tag_byteはSOLRDOCLSTになる" do
#      arr = [JavaBin::SOLRDOCLST] + [(4 << 5) | 3, JavaBin::BYTE, 3, JavaBin::BYTE, 4, JavaBin::BYTE, 5] + [(4 << 5) | 0]
#      @reader.set_sio(StringIO.new(arr.pack("C*")))
#      @reader.send(:read_val).should == {'numFound' => 3, 'start' => 4, 'maxScore' => 5, 'docs' => []} 
#    end
#
#    it "13を渡すと、tag_byteはBYTEARRになる" do
#      array = [0,1, 255]
#      @reader.set_sio(StringIO.new([JavaBin::BYTEARR, array.size, *array].pack("C*")))
#      @reader.send(:read_val).should == array
#    end
#
#    it "13と大きなサイズのバイナリを渡すと、tag_byteはBYTEARRになる" do
#      array = [0,1,255] * 100
#      sio = StringIO.new
#      sio.putc JavaBin::BYTEARR
#      write_v_int(array.size, sio)
#      array.each { |e| sio.putc e }
#      sio.pos = 0
#      @reader.set_sio(sio)
#      @reader.send(:read_val).should == array
#    end
#
#    it "14を渡すと、配列が返ってくる" do
#      @reader.set_sio(StringIO.new([JavaBin::ITERATOR,
#                                       JavaBin::BYTE, 0,
#                                       JavaBin::BYTE, 127,
#                                       JavaBin::NULL,
#                                       JavaBin::BOOL_TRUE,
#                                       JavaBin::TERM].pack("C*")))
#      @reader.send(:read_val).should == [0, 127, nil, true]
#    end
#
#    it "15を渡すと、tag_byteはTERMになる" do
#      @reader.set_sio(StringIO.new([JavaBin::TERM].pack("C")))
#      @reader.send(:read_val).should == :term_obj
#    end
#
#    it "1 << 5を渡すと、tag_byteはSTRになる" do
#      sio = StringIO.new(([(1 << 5) | 2] + "あい".unpack("C*")).pack("C*"))
#      @reader.set_sio(sio)
#      @reader.send(:read_val).should == "あい"
#    end
#
#    it "1 << 5と長い文字列を渡すと、tag_byteはSTRになる" do
#      pending
#    end
#
#    it "2 << 5を渡すと" do
#      pending
#    end
#
#    it "3 << 5を渡すと" do
#      pending "long/intの違い大丈夫か？"
#    end
#
#    it "4 << 5を渡すと、tag_byteはARRになる" do
#      sio = StringIO.new([(4 << 5) | 2, JavaBin::BYTE, 3, JavaBin::BYTE, 4].pack("C*"))
#      @reader.set_sio(sio)
#      @reader.send(:read_val).should == [3, 4]      
#    end
# 
#    it "4 << 5と大きな配列を渡すと、tag_byteはARRになる" do
#      pending
#    end
#
#    it "5 << 5を渡すと、tag_byteはORDERED_MAPになる" do
#      arr = [(5 << 5) | 2] + [(1 << 5) | 1] + "a".unpack("C*") + [JavaBin::BYTE, 8] + [(1 << 5) | 1] + "b".unpack("C*") + [JavaBin::BYTE, 9]
#      @reader.set_sio(StringIO.new(arr.pack("C*")))
#      @reader.send(:read_val).should == {"a" => 8, "b" => 9}
#    end
#
#    it "7 << 5を渡すと、tag_byteはEXTERN_STRINGになる" do
#      sio = StringIO.new(([(7 << 5) | 0] + [(1 << 5) | 3] + "あいa".unpack("C*") + [(7 << 5) | 1]).pack("C*"))
#      @reader.set_sio(sio)
#      @reader.send(:read_val).should == "あいa"
#      @reader.send(:read_val).should == "あいa"
#    end
  end

end

