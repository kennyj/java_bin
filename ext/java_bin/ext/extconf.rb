# vim:fileencoding=utf-8
require 'mkmf'
require 'rbconfig'

unless RUBY_PLATFORM =~ /mswin32/ # Linux
  unless $CFLAGS.gsub!(/ -O[\dsz]?/, ' -O3')
    $CFLAGS << ' -O3'
  end
  if CONFIG['CC'] =~ /gcc/
    $CFLAGS << ' -Wall'
  end
  have_header("byteswap.h")
  have_header("sys/types.h")
else # Windows 
  $CFLAGS.gsub!(/-O2b2xg-/, '/O2b2x')
  $CFLAGS.gsub!(/-MD/, ' /MT')
  $CFLAGS.gsub!(/ -G6/, '')
  $CFLAGS << ' /wd4819' # VC++はUTF-8 BOM無しは駄目なのでここで抑制. gccは逆にBOM付は駄目
end

$CFLAGS << ' -DRUBY_19' if RUBY_VERSION >= '1.9'

have_header("ruby.h")
have_header("ruby/encoding.h")

create_makefile("parser")
