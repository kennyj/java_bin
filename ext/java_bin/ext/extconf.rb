# come from flori-json thk!
require 'mkmf'
require 'rbconfig'

unless $CFLAGS.gsub!(/ -O[\dsz]?/, ' -O3')
  $CFLAGS << ' -O3'
end
if CONFIG['CC'] =~ /gcc/
  $CFLAGS << ' -Wall'
  #unless $CFLAGS.gsub!(/ -O[\dsz]?/, ' -O0 -ggdb')
  #  $CFLAGS << ' -O0 -ggdb'
  #end
end

if RUBY_VERSION >= '1.9'
  $CFLAGS << ' -DRUBY_19'
end

have_header("endian.h")
have_header("byteswap.h")
have_header("sys/types.h")

have_header("ruby/encoding.h")

create_makefile("parser")
