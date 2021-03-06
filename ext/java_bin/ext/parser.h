#ifndef _PARSER_H_
#define _PARSER_H_

#include "ruby.h"
#include "byteswap.h"

#if HAVE_SYS_TYPES_H
  #include <sys/types.h>
#endif /* HAVE_SYS_TYPES_H */

#ifdef HAVE_RUBY_ENCODING_H
  #include <ruby/encoding.h>
#endif /* HAVE_RUBY_ENCODING_H */

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
#define END_OBJ (jbp_terminator)

/* HINT. 先に計算しておく(unsignedなので論理シフト) */
#define  SHIFTED_STR             (STR >> 5)
#define  SHIFTED_ARR             (ARR >> 5)
#define  SHIFTED_EXTERN_STRING   (EXTERN_STRING >> 5)
#define  SHIFTED_ORDERED_MAP     (ORDERED_MAP >> 5)
#define  SHIFTED_NAMED_LST       (NAMED_LST >> 5)
#define  SHIFTED_SINT            (SINT >> 5)
#define  SHIFTED_SLONG           (SLONG >> 5)

/*
 * 文字列読み込み用関数の関数ポインタ
 */
typedef VALUE (*PTR_READ_STRING)(void*);

/*
 * 読込処理データ保持構造体
 */
typedef struct java_bin_parser {
  unsigned char* data;
  int            data_len;
  int            current;
  int            version;
  unsigned char  tag_byte;
  PTR_READ_STRING read_string;

  /* 外部文字列用 */
  VALUE*               cache; 
  int                  cache_size;
  int                  cache_index;
} JAVA_BIN_PARSER;

#ifdef HAVE_RUBY_ENCODING_H
  #define _utf8_string(str, len) (rb_enc_str_new(str, len, rb_encUtf8))
#else
  #define _utf8_string(str, len) (rb_str_new(str, len))
#endif

#define _getbyte(ptr)          (ptr->data[ptr->current++])
#define _skipbytes(ptr, x)     ((ptr->current) += (x))
#define _readnumeric(ptr, c) \
  { u_int8_t* p; \
     p = (void*)&c; \
     memcpy(p, &ptr->data[ptr->current], sizeof(c)); \
     _skipbytes(ptr, sizeof(c)); \
  }

#ifndef WORDS_BIGENDIAN
  #if defined _WIN32 && !defined __MINGW32__
    #define _swap_16(o) _byteswap_ushort(o)
    #define _swap_32(o) _byteswap_ulong(o)
    #define _swap_64(o) _byteswap_uint64(o)
  #else
    #define _swap_16(o) bswap_16(o)
    #define _swap_32(o) bswap_32(o)
    #define _swap_64(o) bswap_64(o)
  #endif
#else
  #define _swap_16(o) (o)
  #define _swap_32(o) (o)
  #define _swap_64(o) (o)
#endif

#ifdef _WIN32
  #ifndef RUBY_19
    typedef signed char        int8_t;
    typedef signed short      int16_t;
    typedef signed int        int32_t;
    typedef signed __int64    int64_t;
  #endif
  typedef unsigned char     u_int8_t;
  typedef unsigned short   u_int16_t;
  typedef unsigned int     u_int32_t;
  typedef unsigned __int64 u_int64_t;
#endif

typedef union java_bin_float {
  float     f_value;
  u_int32_t i_value;
} JAVA_BIN_FLOAT;

typedef union java_bin_double {
  double    d_value;
  u_int64_t i_value;
} JAVA_BIN_DOUBLE;

static VALUE JavaBinParser_read_val(JAVA_BIN_PARSER* ptr);

static void JavaBinParser_free(JAVA_BIN_PARSER* ptr);
static void JavaBinParser_mark(JAVA_BIN_PARSER* ptr);
static VALUE JavaBinParser_alloc(VALUE klass);

static VALUE rb_cParser_parse(VALUE self, VALUE data);
static VALUE rb_cParser_initialize(VALUE self);

#endif /* _PARSER_H_ */
