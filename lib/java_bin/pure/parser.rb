# vim:fileencoding=utf-8

module JavaBin
  module Pure
  NULL       = 0
  BOOL_TRUE  = 1
  BOOL_FALSE = 2
  BYTE       = 3
  SHORT      = 4
  DOUBLE     = 5
  INT        = 6
  LONG       = 7
  FLOAT      = 8
  DATE       = 9
  MAP        = 10
  SOLRDOC    = 11
  SOLRDOCLST = 12
  BYTEARR    = 13
  ITERATOR   = 14
  TERM       = 15 #END = 15

  #TAG_AND_LEN  = (1 << 5)
  STR           = (1 << 5)
  SINT          = (2 << 5)
  SLONG         = (3 << 5)
  ARR           = (4 << 5)
  ORDERED_MAP   = (5 << 5)
  NAMED_LST     = (6 << 5)
  EXTERN_STRING = (7 << 5)

  # TODO 論理シフト
  SHIFTED_STR           = STR >> 5
  SHIFTED_ARR           = ARR >> 5
  SHIFTED_EXTERN_STRING = EXTERN_STRING >> 5
  SHIFTED_ORDERED_MAP   = ORDERED_MAP >> 5
  SHIFTED_NAMED_LST     = NAMED_LST >> 5
  SHIFTED_SINT          = SINT >> 5
  SHIFTED_SLONG         = SLONG >> 5

    class Perser

  VERSION  = 1
  TERM_OBJ = :term_obj

  def self.unmarshal(input)
    array = input.bytes.to_a
    check_version(array[0])
    Reader.new(array).process
  end

  def self.check_version(byte)
    return true if VERSION == byte
    raise "unsupported version #{byte}"
  end

  class Reader
 
    #attr_reader :tag_byte, :input, :current

    def initialize(input)
      @input = input
      @current = 1 # HINT VERSIONをとばす
      @tag_byte = nil
    end

    def process
      read_val
    end

    private
    def getbyte
      ret = @input[@current]
      @current += 1
      ret
    end
    
    def getbytes(size)
      ret = @input[@current...(@current + size)]
      @current += size
      ret
    end
 
    def read_val
      @tag_byte = getbyte
      case (@tag_byte >> 5) # TODO 論理シフト
        when SHIFTED_STR
          return read_chars
        when SHIFTED_ARR
          size = read_size
          array = Array.new(size)
          size.times { |i| array[i] = read_val }
          return array
        when SHIFTED_EXTERN_STRING
          size = read_size
          if size == 0
            str = read_val
            @exts ||= []
            @exts << str
            return str
          else
            return @exts[size - 1].dup
          end
        when SHIFTED_ORDERED_MAP, SHIFTED_NAMED_LST
          size = read_size
          hash = {}
          size.times do
            k = read_val
            v = read_val
            hash[k] = v
          end
          return hash
        when SHIFTED_SINT
          return read_small_int
        when SHIFTED_SLONG
          return read_small_int
      end
  
      case @tag_byte
        when NULL
          return nil
        when BOOL_TRUE
          return true
        when BOOL_FALSE
          return false
        when BYTE
          return getbytes(1).pack("C*").unpack("c")[0]
        when SHORT
          return getbytes(2).reverse.pack("C*").unpack("s")[0]
        when DOUBLE
          return getbytes(8).pack("C*").unpack("G")[0]
        when INT
          return getbytes(4).reverse.pack("C*").unpack("i")[0]
        when LONG
          return getbytes(8).reverse.pack("C*").unpack("q")[0]
        when FLOAT
          return getbytes(4).pack("C*").unpack("g")[0]
        when DATE
          x = getbytes(8).reverse.pack("C*").unpack("q")[0]
          return Time.at(x/1000)
        when MAP
          size = read_v_int
          hash = {}
          size.times do
            k = read_val
            v = read_val
            hash[k] = v
          end
          return hash
        when BYTEARR
          size = read_v_int
          return getbytes(size)
        when ITERATOR
          array = []
          while true
            i = read_val
            break if i == TERM_OBJ
            array << i
          end
          return array
        when TERM
          return TERM_OBJ
        when SOLRDOC
          return read_val
        when SOLRDOCLST
          result = {}
          list = read_val
          result['numFound'] = list[0]
          result['start']    = list[1]
          result['maxScore'] = list[2]
          result['docs'] = read_val
          return result
      end
    end
  
    def read_v_int
      byte = getbyte
      result = byte & 0x7f
      shift = 7
      while (byte & 0x80) != 0
        byte = getbyte
        result |= ((byte & 0x7f) << shift)
        shift += 7
      end
      result 
    end
  
    def read_size
      size = (@tag_byte & 0x1f)
      size += read_v_int if (size == 0x1f)
      size
    end
  
    def read_small_int
      result = @tag_byte & 0x0F
      result = ((read_v_int << 4) | result) if ((@tag_byte & 0x10) != 0)
      result
    end
  
    def read_chars
      size = read_size
      str = ''
      size.times {
        # HINT. read utf-8 char
        b = getbyte
        if ((b & 0x80) == 0)
          str << b
        elsif ((b & 0xE0) != 0xE0)
          str << (((b & 0x1F) << 6) | (getbyte & 0x3F))
        else
          str << (((b & 0x0F) << 12) | ((getbyte & 0x3F) << 6) | (getbyte & 0x3F))
        end
      }
      str.force_encoding('utf-8') if str.respond_to? :force_encoding
      str
    end

  end

end

