set -e
set -x

FILE_ZLIB="zlib-1.2.13.zip"
FILE_OPENSSL="openssl-3.0.8.zip"
FILE_BOOST="boost_1_81_0.tar.gz"
PATH_BOOST="boost_1_81_0"
FILE_CURL="curl-7.87.0.zip"
FILE_FMT="fmt-9.1.0.zip"
FILE_GLOG="glog-0.5.0.zip"
PATH_GLOG="glog"
FILE_LEA="lea-1.3.zip"
PATH_LEA="lea-1.3"
FILE_GOOGLETEST="googletest-1.13.0.zip"
PATH_GOOGLETEST="googletest-1.13.0"
FILE_SQLEET="sqleet.zip"
PATH_SQLEET="sqleet"
FILE_RAX="rax.zip"
PATH_RAX="rax"
FILE_PWVERIF="libpwverif.tar"
PATH_PWVERIF="libpwverif"
FILE_PCRE="pcre-8.45.tar.gz"
PATH_PCRE_SRC="pcre-8.45"
FILE_LIGHTTPD="lighttpd-1.4.69.zip"
PATH_LIGHTTPD="lighttpd"

#FILE_PWQUALITY="libpwquality-1.4.5.zip"


BASE_DIR="${PWD}"
OUTPUT_PATH="${BASE_DIR}/third_party/x86_64"

export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/opt/rh/devtoolset-9/root/usr/lib/gcc/x86_64-redhat-linux/9:${OUTPUT_PATH}/lib:${OUTPUT_PATH}/lib64


ARCH_X86=
BUILD_i686=0
if [ "$1" = "32" ]; then
  BUILD_i686=1
  echo "Architecture (x86)"
  OUTPUT_PATH="${BASE_DIR}/third_party/x86"
  ARCH_X86="-m32"
else
  echo "Architecture (x86_64)"
  OUTPUT_PATH="${BASE_DIR}/third_party/x86_64"
fi

# false
if false; then
  BUILD_i686=1
  echo "Architecture (x86)"
  OUTPUT_PATH="${BASE_DIR}/third_party/x86"
  ARCH_X86="-m32"
fi



if [ -d $OUTPUT_PATH ]; then
  echo "remove a directory [$OUTPUT_PATH] (recursively)"
  if false; then
    rm -rf $OUTPUT_PATH
  fi
fi

echo "create a directory [$OUTPUT_PATH]"
mkdir -p $OUTPUT_PATH


flag_zlib=true
flag_fmt=true
flag_boost=true
flag_openssl=true
flag_curl=true
flag_glog=true
flag_lea=true
flag_googletest=true
flag_sqleet=true
flag_rax=true
flag_pwverif=true
flag_pcre=true
flag_lighttpd=true

# zlib
if $flag_zlib; then
  echo "build zlib"
  sleep 1
  if [ -d zlib ]; then
    echo "remove a target directory (recursively)"
    rm -rf zlib
    sleep 1
  fi
  mkdir zlib
  unzip $FILE_ZLIB -d zlib
  cd zlib && CFLAGS="-fPIC ${ARCH_X86}" CXXFLAGS="-fPIC ${ARCH_X86}" ./configure --static --prefix=$OUTPUT_PATH 
  make -j10 && make install
  cd ..

# minizip
  echo "build minizip"
  sleep 1
  cd zlib/contrib/minizip
  gcc -O2 -fPIC ${ARCH_X86} -c ioapi.c mztools.c unzip.c zip.c -I../..
  ar rcs libminizip.a ioapi.o mztools.o unzip.o zip.o
  mkdir -p $OUTPUT_PATH/include/minizip
  mkdir -p $OUTPUT_PATH/lib
  cp -f libminizip.a $OUTPUT_PATH/lib
  cp -f crypt.h ioapi.h mztools.h unzip.h zip.h $OUTPUT_PATH/include/minizip

  cd ../../..

fi



# fmt
if $flag_fmt; then
  echo "build fmt"
  sleep 1
  if [ -d fmt ]; then
    echo "remove a target directory (recursively)"
    rm -rf fmt
    sleep 1
  fi
  mkdir fmt
  unzip $FILE_FMT -d fmt
  if [ -z "$ARCH_X86" ]; then
    cd fmt && cmake -DCMAKE_INSTALL_PREFIX:PATH=$OUTPUT_PATH . && make -j10 && make install && cd ..
  else
    cd fmt && cmake -DCMAKE_INSTALL_PREFIX:PATH=$OUTPUT_PATH -DCMAKE_C_FLAGS="-m32 -fPIC" -DCMAKE_CXX_FLAGS="-m32 -fPIC" -DFMT_TEST=OFF . && make -j10 VERBOSE=1 && make install && cd ..
  fi
fi


if $flag_boost; then
  set +e
# boost
  echo "build boost"
  sleep 1
  if [ -d $PATH_BOOST ]; then
    echo "remove a target directory (recursively)"
    rm -rf $PATH_BOOST
    sleep 1
  fi
  tar -zxf $FILE_BOOST
  cd $PATH_BOOST
  ./bootstrap.sh --with-libraries=filesystem,iostreams,program_options,regex,system,thread,date_time,random --without-icu --prefix=$OUTPUT_PATH
#./bootstrap.sh --prefix=$OUTPUT_PATH
  ./b2 -j10 define=_GLIBCXX_USE_CXX11_ABI=0 cflags="-fPIC ${ARCH_X86}" cxxflags="-fPIC ${ARCH_X86}" install variant=release link=static threading=multi runtime-link=shared -s NO_BZIP2=1 -s ZLIB_BINARY=z -s ZLIB_INCLUDE=$OUTPUT_PATH/include -s ZLIB_LIBPATH=$OUTPUT_PATH/lib
  cd ..
  set -e
fi


# openssl
if $flag_openssl; then
  echo "build openssl"
  sleep 1
  if [ -d openssl ]; then
    echo "remove a target directory (recursively)"
    rm -rf openssl
    sleep 1
  fi
  mkdir openssl
  unzip $FILE_OPENSSL -d openssl
  cd openssl
  if [ -z "$ARCH_X86" ]; then
    ./config no-shared -fPIC ${ARCH_X86} --prefix=$OUTPUT_PATH --openssldir=$OUTPUT_PATH -I"$OUTPUT_PATH/include" -L"$OUTPUT_PATH/lib" -lz
  else
    ./config no-shared linux-generic32 -fPIC ${ARCH_X86} --prefix=$OUTPUT_PATH --openssldir=$OUTPUT_PATH -I"$OUTPUT_PATH/include" -L"$OUTPUT_PATH/lib" -lz
  fi
  make -j10 && make install_sw
  cd ..
fi

# curl
if $flag_curl; then
  echo "build curl"
  sleep 1
  if [ -d curl ]; then
    echo "remove a target directory (recursively)"
    rm -rf curl
    sleep 1
  fi
  mkdir curl
  unzip $FILE_CURL -d curl
  cd curl
  autoreconf -fi
  ./configure --enable-static --disable-shared --prefix=$OUTPUT_PATH --with-openssl=$OUTPUT_PATH CFLAGS="-fPIC ${ARCH_X86}" CPPFLAGS="-fPIC ${ARCH_X86}"
  make -j10 && make install
  cd ..
fi

# glog
if $flag_glog; then
  if [ -d $PATH_GLOG ]; then
    rm -rf $PATH_GLOG
  fi
  mkdir $PATH_GLOG
  unzip $FILE_GLOG -d $PATH_GLOG
  cd $PATH_GLOG
  if [ -z "$ARCH_X86" ]; then
    cmake -DBUILD_SHARED_LIBS=OFF -DCMAKE_INSTALL_PREFIX:PATH=$OUTPUT_PATH . && make -j10 && make install
  else
    cmake -DBUILD_SHARED_LIBS=OFF -DCMAKE_INSTALL_PREFIX:PATH=$OUTPUT_PATH -DCMAKE_CXX_FLAGS='-m32' . && make -j10 && make install
  fi
  cd ..
fi

# lea
if $flag_lea; then
  echo "build lea"
  sleep 1
  if [ -d $PATH_LEA ]; then
    rm -rf $PATH_LEA
  fi
  mkdir $PATH_LEA
  unzip $FILE_LEA -d $PATH_LEA
  cd $PATH_LEA
  unzip LEA_C_Standalone_src.zip
  make CFLAGS="-O2 -fPIC ${ARCH_X86}" SHARED=FALSE TEST=FALSE lib
  make PREFIX=$OUTPUT_PATH SHARED=FALSE install
  mkdir -p $OUTPUT_PATH/include/lea
  mv $OUTPUT_PATH/include/config.h $OUTPUT_PATH/include/lea
  mv $OUTPUT_PATH/include/lea.h $OUTPUT_PATH/include/lea
  cd ..
fi

# googletest
if $flag_googletest; then
  echo "build googletest"
  sleep 1
  if [ -d $PATH_GOOGLETEST ]; then
    rm -rf $PATH_GOOGLETEST
  fi
  mkdir $PATH_GOOGLETEST
  unzip $FILE_GOOGLETEST -d $PATH_GOOGLETEST
  cd $PATH_GOOGLETEST
#  cmake -DBUILD_SHARED_LIBS=OFF -DCMAKE_INSTALL_PREFIX:PATH=$OUTPUT_PATH . && make -j10 && make install
  if [ -z "$ARCH_X86" ]; then
    cmake -DBUILD_SHARED_LIBS=OFF -DCMAKE_INSTALL_PREFIX:PATH=$OUTPUT_PATH . && make -j10 && make install
  else
    cmake -DBUILD_SHARED_LIBS=OFF -DCMAKE_INSTALL_PREFIX:PATH=$OUTPUT_PATH -DCMAKE_CXX_FLAGS='-m32' . && make -j10 && make install
  fi
  cd ..
fi

# sqleet
if $flag_sqleet; then
  echo "build sqleet"
  sleep 1
  if [ -d $PATH_SQLEET ]; then
    rm -rf $PATH_SQLEET
  fi
  mkdir $PATH_SQLEET
  unzip $FILE_SQLEET -d $PATH_SQLEET
  cd $PATH_SQLEET
  script/amalgamate.sh <sqleet.c> sqleet_amal.c
  gcc -O2 -fPIC ${ARCH_X86} -c sqleet_amal.c
  ar rcs libsqleet.a sqleet_amal.o
  gcc -O2 ${ARCH_X86} -o sqleet shell.c -L. -lsqleet -ldl -lpthread
  mkdir -p $OUTPUT_PATH/include/sqleet
  mkdir -p $OUTPUT_PATH/lib
  mkdir -p $OUTPUT_PATH/bin
  cp sqleet $OUTPUT_PATH/bin
  cp libsqleet.a $OUTPUT_PATH/lib
  cp sqleet.h sqlite3.h sqlite3ext.h $OUTPUT_PATH/include/sqleet
  cd ..
fi

# rax
if $flag_rax; then
  echo "build rax"
  sleep 1
  if [ -d $PATH_RAX ]; then
    rm -rf $PATH_RAX
  fi
  unzip $FILE_RAX 
  cd $PATH_RAX
  patch -p1 < ./0001-include-stddef.h-for-size_t.patch
  patch -p1 < ./0002-Add-extern-C-block-for-C-use.patch
  patch -p1 < ./0003-Fix-for-const-correctness.patch
  CFLAGS="-fPIC ${ARCH_X86}" gcc -fPIC ${ARCH_X86} -O2 -c rax.c
  ar rcs librax.a rax.o

  mkdir -p $OUTPUT_PATH/include/rax
  mkdir -p $OUTPUT_PATH/lib
  mkdir -p $OUTPUT_PATH/bin
  cp librax.a $OUTPUT_PATH/lib
  cp rax.h rax_malloc.h $OUTPUT_PATH/include/rax
  cd ..
fi

# pwverif (kisa)
if $flag_pwverif; then
  echo "build pwverif"
  sleep 1
  if [ -d $PATH_PWVERIF ]; then
    rm -rf $PATH_PWVERIF
  fi
  mkdir $PATH_PWVERIF
  tar -xf $FILE_PWVERIF -C $PATH_PWVERIF
  cd $PATH_PWVERIF
  gcc -fPIC ${ARCH_X86} -shared -static -c gstring.c  glist.c gtable.c gconfig.c stringutil.c rules.c dictmanger.c pwverifier.c pwanalysis.c
#gcc -shared -static -fPIC ${ARCH_X86} -c gstring.c  glist.c gtable.c gconfig.c stringutil.c rules.c dictmanger.c pwverifier.c pwanalysis.c
#gcc -fPIC ${ARCH_X86} -c gstring.c  glist.c gtable.c gconfig.c stringutil.c rules.c dictmanger.c pwverifier.c pwanalysis.c
  ar rcs libpwverif.a gstring.o  glist.o gtable.o gconfig.o stringutil.o rules.o dictmanger.o pwverifier.o pwanalysis.o

  mkdir -p $OUTPUT_PATH/include/pwverif
  mkdir -p $OUTPUT_PATH/lib
  mkdir -p $OUTPUT_PATH/bin/pwverif
  cp -f libpwverif.a $OUTPUT_PATH/lib
  cp -rf dicts $OUTPUT_PATH/bin/pwverif
  cp -f pconfig.h pheader.h $OUTPUT_PATH/include/pwverif
  cd ..
fi

# pcre
if $flag_pcre; then
  echo "build pcre"
  sleep 1
  if [ -d $PATH_PCRE_SRC ]; then
    rm -rf $PATH_PCRE_SRC
  fi
  tar -xzf $FILE_PCRE
  cd $PATH_PCRE_SRC
  PKG_CONFIG_LIBDIR=$OUTPUT_PATH/lib/pkgconfig CFLAGS="-fPIC ${ARCH_X86}" CXXFLAGS="-fPIC ${ARCH_X86}" ./configure --prefix=$OUTPUT_PATH --enable-utf8 --enable-unicode-properties --enable-static --disable-shared 
  make -j10 && make install
  cd ..
fi


# lighttpd
if $flag_lighttpd; then
  echo "build lighttpd"
  sleep 1
  if [ -d $PATH_LIGHTTPD ]; then
    rm -rf $PATH_LIGHTTPD
  fi
  mkdir $PATH_LIGHTTPD
  unzip $FILE_LIGHTTPD -d $PATH_LIGHTTPD
  mkdir -p $OUTPUT_PATH/bin
  cd $PATH_LIGHTTPD
  ./autogen.sh
  PKG_CONFIG_PATH="${OUTPUT_PATH}/lib/pkgconfig:${OUTPUT_PATH}/lib64/pkgconfig" LDFLAGS="-L${OUTPUT_PATH}/lib -L${OUTPUT_PATH}/lib64" CFLAGS="-fPIC ${ARCH_X86} -I${OUTPUT_PATH}/include" CXXFLAGS="-fPIC ${ARCH_X86} -I${OUTPUT_PATH}/include" CPPFLAGS="-fPIC ${ARCH_X86} -I${OUTPUT_PATH}/include" ./configure --prefix=$OUTPUT_PATH/bin/lighttpd --without-pcre2 
  make && make install
  cd ..
fi

################################################################################################################################################################################################################################
exit

# GTK BUILD DEPENDENCY
FILE_LIBFFI="libffi-3.4.4.zip"
FILE_GLIB="glib-2.49.7.tar.xz"
PATH_GLIB_SRC="glib-2.49.7"
FILE_ATK="atk-2.19.92.tar.xz"
PATH_ATK_SRC="atk-2.19.92"
FILE_PNG="libpng-1.6.39.tar.gz"
PATH_PNG_SRC="libpng-1.6.39"

# libffi
echo "build libpwquality"
sleep 1
if [ -d libffi ]; then
  echo "remove a target directory (recursively)"
  rm -rf libffi
  sleep 1
fi
mkdir libffi
unzip $FILE_LIBFFI -d libffi
cd libffi
./autogen.sh
./configure --enable-static --disable-shared --prefix=$OUTPUT_PATH CFLAGS="-fPIC ${ARCH_X86} -I${OUTPUT_PATH}/include" CPPFLAGS="-fPIC ${ARCH_X86} -I${OUTPUT_PATH}/include" LDFLAGS="-L${OUTPUT_PATH}/lib -L${OUTPUT_PATH}/lib64"
make -j10 && make install
cd ..


# glib
if [ -d $PATH_GLIB_SRC ]; then
  rm -rf $PATH_GLIB_SRC
fi
tar -xf $FILE_GLIB
cd $PATH_GLIB_SRC
PKG_CONFIG_LIBDIR=${OUTPUT_PATH}/lib/pkgconfig CFLAGS="-fPIC ${ARCH_X86}" CXXFLAGS="-fPIC ${ARCH_X86}" ./configure --prefix=${OUTPUT_PATH} --with-pcre=internal --enable-static --disable-shared
make -j10 && make install
cd ..

# atk
if [ -d $PATH_ATK_SRC ]; then
  rm -rf $PATH_ATK_SRC
fi
tar -xf $FILE_ATK
cd $PATH_ATK_SRC
./configure PKG_CONFIG_PATH="${OUTPUT_PATH}/lib/pkgconfig:${OUTPUT_PATH}/lib64/pkgconfig" --disable-shared --enable-static CFLAGS="-fPIC ${ARCH_X86}" CXXFLAGS="-fPIC ${ARCH_X86}" --prefix=${OUTPUT_PATH}
make -j10 && make install
cd ..

# libpng
if [ -d $PATH_PNG_SRC ]; then
  rm -rf $PATH_PNG_SRC
fi
tar -xf $FILE_PNG
cd $PATH_PNG_SRC
PKG_CONFIG_PATH="${OUTPUT_PATH}/lib/pkgconfig:$OUTPUT_PATH}/lib64/pkgconfig" ./configure --enable-static --disable-shared --with-zlib-prefix=${OUTPUT_PATH} LDFLAGS="-L${OUTPUT_PATH}/lib -L${OUTPUT_PATH}/lib64" CFLAGS="-fPIC ${ARCH_X86} -I${OUTPUT_PATH}/include" CXXFLAGS="-fPIC ${ARCH_X86} -I${OUTPUT_PATH}/include" CPPFLAGS="-fPIC ${ARCH_X86} -I${OUTPUT_PATH}/include" --prefix=${OUTPUT_PATH}

make -j10 && make install
cd ..
exit
# END OF GTK BUILD DEPENDENCY
################################################################################################################################################################################################################################
