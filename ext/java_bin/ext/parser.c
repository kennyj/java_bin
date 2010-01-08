#include <endian.h>
#include <byteswap.h>
#include <sys/types.h>

#include <ruby.h>
#include <ruby/encoding.h>

/*
 * javabin constants
 */
#define  NULL_MARK    0
#define  BOOL_TRUE    1
#define  BOOL_FALSE   2
#define  BYTE         3
#define  SHORT        4
#define  DOUBLE       5
#define  INT          6
#define  LONG         7
#define  FLOAT        8
#define  DATE         9
#define  MAP         10
#define  SOLRDOC     11
#define  SOLRDOCLST  12
#define  BYTEARR     13
#define  ITERATOR    14
#define  END         15
/*#define  TAG_AND_LEN     (1U << 5)*/
#define  STR             (1U << 5)
#define  SINT            (2U << 5)
#define  SLONG           (3U << 5)
#define  ARR             (4U << 5)
#define  ORDERED_MAP     (5U << 5)
#define  NAMED_LST       (6U << 5)
#define  EXTERN_STRING   (7U << 5)

/* HINT. 終端判定用オブジェクト */
#define END_OBJ ((int) NULL)

/* HINT. 先に計算しておく(unsignedなので論理シフト) */
#define  SHIFTED_STR             (STR >> 5)
#define  SHIFTED_ARR             (ARR >> 5)
#define  SHIFTED_EXTERN_STRING   (EXTERN_STRING >> 5)
#define  SHIFTED_ORDERED_MAP     (ORDERED_MAP >> 5)
#define  SHIFTED_NAMED_LST       (NAMED_LST >> 5)
#define  SHIFTED_SINT            (SINT >> 5)
#define  SHIFTED_SLONG           (SLONG >> 5)

static VALUE rb_cJavaBinReader;
static ID    rb_idAt; // Time#at用
static rb_encoding* rb_encUtf8;

/*
 * macros
 */
#define _getbyte(ptr)          (ptr->data[ptr->current++])
#define _skipbytes(ptr, x)     ((ptr->current) += (x))
#define _utf8_string(str, len) (rb_enc_str_new(str, len, rb_encUtf8))
#define _readnumeric(ptr, c) \
  ({ u_int8_t* p; \
     p = (void*)&c; \
     memcpy(p, &ptr->data[ptr->current], sizeof(c)); \
     _skipbytes(ptr, sizeof(c)); c; \
   })

/*
 * 参照文字列情報保持用
 */
typedef struct extern_string {
  int offset;
  int len;
} _EXTERN_STRING_INFO;

/*
 * 読込処理データ保持構造体
 */
typedef struct java_bin_reader {
  unsigned char* data;
  int            data_len;
  int            current;
  unsigned char  tag_byte;

  /* 外部文字列用 TODO ちゃんとする */
  _EXTERN_STRING_INFO cache[256]; 
  int                 cache_index;
  int                 last_string_offset;
  int                 last_string_len;

} JAVA_BIN_READER;

/*
 * javabinフォーマット読み込み関数群
 */

static int32_t JavaBinReader_read_v_int(JAVA_BIN_READER* ptr) {
  unsigned char byte;
  int32_t result;
  int shift;
  byte = _getbyte(ptr);
  result = byte & 0x7f;
  for(shift = 7; (byte & 0x80) != 0; shift += 7) {
    byte = _getbyte(ptr);
    result |= (((int32_t)(byte & 0x7f)) << shift);
  }
  return result;
}

static int64_t JavaBinReader_read_v_long(JAVA_BIN_READER* ptr) {
  unsigned char byte;
  int64_t result;
  int shift;
  byte = _getbyte(ptr);
  result = byte & 0x7f;
  for(shift = 7; (byte & 0x80) != 0; shift += 7) {
    byte = _getbyte(ptr);
    result |= (((int64_t)(byte & 0x7f)) << shift);
  }
  return result;
}

static int JavaBinReader_read_size(JAVA_BIN_READER* ptr) {
  int size;
  size = (ptr->tag_byte & 0x1f);
  if (size == 0x1f) {
    size += JavaBinReader_read_v_int(ptr);
  }
  return size;
}

static VALUE JavaBinReader_read_small_int(JAVA_BIN_READER* ptr) {
  int32_t result;
  result = ptr->tag_byte & 0x0f;
  if ((ptr->tag_byte & 0x10) != 0) {
    result = ((JavaBinReader_read_v_int(ptr) << 4) | result);
  }
  return INT2NUM(result);
}

static VALUE JavaBinReader_read_small_long(JAVA_BIN_READER* ptr) {
  int64_t result;
  result = ptr->tag_byte & 0x0f;
  if ((ptr->tag_byte & 0x10) != 0) {
    result = ((JavaBinReader_read_v_long(ptr) << 4) | result);
  }
  return LL2NUM(result);
}

static VALUE JavaBinReader_read_string(JAVA_BIN_READER* ptr) {
  int size;
  int i;

  unsigned char b;

  size = JavaBinReader_read_size(ptr);
  ptr->last_string_offset = ptr->current;
  for (i = 0; i < size; i++) {
    /* HINT. read utf-8 char */
    b = _getbyte(ptr);
    if ((b & 0x80) == 0) {
    } else if ((b & 0xE0) == 0xC0) {
      _skipbytes(ptr, 1);
    } else {
      _skipbytes(ptr, 2);
    } /* TODO 4byte以上のケース? */
  }
  ptr->last_string_len = ptr->current - ptr->last_string_offset;
  return _utf8_string((const char*) &ptr->data[ptr->last_string_offset], ptr->last_string_len); 
}

static VALUE _read_byte(JAVA_BIN_READER* ptr) {
  int8_t c;
  c = _readnumeric(ptr, c);
  return INT2NUM(*((int8_t*)&c));
}
static VALUE _read_short(JAVA_BIN_READER* ptr) {
  u_int16_t c;
  c = _readnumeric(ptr, c);
  c = bswap_16(c); /* TODO cpuによって違うはず */
  return INT2NUM(*((int16_t*)&c));

}
static VALUE _read_int(JAVA_BIN_READER* ptr) {
  u_int32_t c;
  c = _readnumeric(ptr, c);
  c = bswap_32(c);
  return INT2NUM(*((int32_t*)&c));
}
static VALUE _read_long(JAVA_BIN_READER* ptr) {
  u_int64_t c;
  c = _readnumeric(ptr, c);
  c = bswap_64(c);
  return LL2NUM(*((int64_t*)&c));
}

static VALUE _read_date(JAVA_BIN_READER* ptr) {
  u_int64_t c;
  c = _readnumeric(ptr, c);
  c = bswap_64(c);
  return rb_funcall(rb_cTime, rb_idAt, 1, ULL2NUM(*((int64_t*)&c) / 1000));
}

static VALUE _read_float(JAVA_BIN_READER* ptr) {
  u_int32_t c;
  c = _readnumeric(ptr, c);
  c = bswap_32(c);
  return rb_float_new((double)*((float*)&c));
}

static VALUE _read_double(JAVA_BIN_READER* ptr) {
  u_int64_t c;
  c = _readnumeric(ptr, c);
  c = bswap_64(c);
  return rb_float_new(*((double*)&c));
}

static VALUE JavaBinReader_read_val(JAVA_BIN_READER* ptr) {
  int size;
  int i;
  VALUE key;
  VALUE value;
  VALUE array;
  VALUE hash;

  ptr->tag_byte = _getbyte(ptr);
  switch (ptr->tag_byte >> 5) { /* unsignedなので論理シフト */
    case SHIFTED_STR:
      return JavaBinReader_read_string(ptr);
    case SHIFTED_ARR:
      size = JavaBinReader_read_size(ptr);
      array = rb_ary_new();
      for (i = 0; i < size; i++) {
        value = JavaBinReader_read_val(ptr);
        rb_ary_push(array, value);
      }
      return array;
    case SHIFTED_EXTERN_STRING:
      size = JavaBinReader_read_size(ptr);
      if(size == 0) {
        /* rubyの文字列 */
        value = JavaBinReader_read_val(ptr);

        /* 外部文字列としてcの文字列を保持 */
        ptr->cache[ptr->cache_index].offset = ptr->last_string_offset;
        ptr->cache[ptr->cache_index].len    = ptr->last_string_len;
        ptr->cache_index ++;

        return value;
      } else {
        return _utf8_string((const char*)&ptr->data[ptr->cache[size - 1].offset], ptr->cache[size - 1].len); 
      }
    case SHIFTED_ORDERED_MAP:
    case SHIFTED_NAMED_LST:
      size = JavaBinReader_read_size(ptr);
      hash = rb_hash_new();
      for (i = 0; i < size; i++) {
        key   = JavaBinReader_read_val(ptr);
        value = JavaBinReader_read_val(ptr);
        rb_hash_aset(hash, key, value);
      }
      return hash;
    case SHIFTED_SINT:
      return JavaBinReader_read_small_int(ptr);
    case SHIFTED_SLONG:
      return JavaBinReader_read_small_long(ptr);
  }

  switch(ptr->tag_byte) {
    case BYTE:
      return _read_byte(ptr);
    case SHORT:
      return _read_short(ptr);
    case DOUBLE:
      return _read_double(ptr);
    case INT:
      return _read_int(ptr);
    case LONG:
      return _read_long(ptr);
    case FLOAT:
      return _read_float(ptr);
    case DATE:
      return _read_date(ptr);
    case BYTEARR:
      size = JavaBinReader_read_v_int(ptr);
      array = rb_ary_new();
      for (i = 0; i < size; i++) {
        rb_ary_push(array, INT2FIX(_getbyte(ptr)));
      }
      return array;
    case NULL_MARK:
      return Qnil;
    case BOOL_TRUE:
      return Qtrue;
    case BOOL_FALSE:
      return Qfalse;
    case MAP:
      size = JavaBinReader_read_v_int(ptr);
      hash = rb_hash_new();
      for (i = 0; i < size; i++) {
        key   = JavaBinReader_read_val(ptr);
        value = JavaBinReader_read_val(ptr);
        rb_hash_aset(hash, key, value);
      }
      return hash;
   case ITERATOR:
      array = rb_ary_new();
      while (1) {
        value = JavaBinReader_read_val(ptr);
        if (value == END_OBJ) {
          break;
        }
        rb_ary_push(array, value);
      }
      return array;
    case END:
      return END_OBJ; 
    case SOLRDOC:
      return JavaBinReader_read_val(ptr);
    case SOLRDOCLST:
      hash = rb_hash_new();
      value = JavaBinReader_read_val(ptr);
      rb_hash_aset(hash, rb_str_new2("numFound"), rb_ary_entry(value, 0));
      rb_hash_aset(hash, rb_str_new2("start"),    rb_ary_entry(value, 1));
      rb_hash_aset(hash, rb_str_new2("maxScore"), rb_ary_entry(value, 2));
      rb_hash_aset(hash, rb_str_new2("docs"),     JavaBinReader_read_val(ptr));
      return hash;
    default:
      rb_raise(rb_eRuntimeError, "JavaBinReader_read_val - unknown tag type");
  }
}

static VALUE JavaBinReader_process(VALUE self, VALUE data) {
  JAVA_BIN_READER* ptr;
  char* ptrData;
  int   dataLen;

  Data_Get_Struct(self, JAVA_BIN_READER, ptr);

  /* 引数処理 */
  SafeStringValue(data);
  ptrData = RSTRING_PTR(data);
  dataLen = RSTRING_LEN(data);

  /* 引数チェック */
  if (ptrData == NULL || dataLen == 0) {
    rb_raise(rb_eRuntimeError, "JavaBinReader_alloc - data is empty.");
  }

  //  ptr->data = (unsigned char*) malloc(dataLen);
  //  if (!ptr->data) {
  //    rb_raise(rb_eRuntimeError, "JavaBinReader_alloc - allocate error");
  //  }
  //  memcpy(ptr->data, ptrData, dataLen);
  ptr->data = (unsigned char*)ptrData;
  ptr->data_len = dataLen;

  ptr->current  = 1;   /* VERSIONをとばした */
  ptr->tag_byte = 0;
  ptr->cache_index = 0; /* TODO ちゃんとする */
 
  return JavaBinReader_read_val(ptr);
}

static VALUE JavaBinReader_init(VALUE self) {
  JAVA_BIN_READER* ptr;

  /* データの初期化 */
  ptr = (JAVA_BIN_READER*) malloc(sizeof(JAVA_BIN_READER));
  if (!ptr) {
    rb_raise(rb_eRuntimeError, "JavaBinReader_alloc - allocate error");
  }
  DATA_PTR(self) = ptr;
 
  return self;
}

static void JavaBinReader_free(JAVA_BIN_READER* ptr) {
  if (ptr) {
    // free(ptr->data);
    free(ptr);
  }
}

static VALUE JavaBinReader_alloc(VALUE klass) {
  return Data_Wrap_Struct(klass, 0, JavaBinReader_free, NULL);
}

void Init_JavaBinReader(void) {
  rb_encUtf8 = rb_utf8_encoding();
  rb_idAt = rb_intern("at");

  /* クラス定義 */
  rb_cJavaBinReader = rb_define_class("JavaBinReader", rb_cObject);
  /* メモリーアロケーター設定 */
  rb_define_alloc_func(rb_cJavaBinReader, JavaBinReader_alloc);
  /* コンストラクタ */
  rb_define_method(rb_cJavaBinReader, "initialize", JavaBinReader_init, 0);
  /* processメソッド*/
  rb_define_method(rb_cJavaBinReader, "process", JavaBinReader_process, 1);
}

