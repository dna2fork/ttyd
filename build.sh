#!/bin/bash
# centos

set -xe
SELF=$(cd `dirname $0`; pwd)

yum install -y doxygen autoconf automake glibc-static openssl-static zlib-static

#rm -rf local ttyd Makefile CMakeCache.txt
rm -rf local/zlib local/libev local/json-c local/libwebsockets local/openssl local/src ttyd Makefile CMakeCache.txt
mkdir -p local
pushd local
cp -r ../3rd src
cd src
#git clone git://github.com/json-c/json-c
#git clone git://github.com/warmcat/libwebsockets -b v2.4-stable
#git clone git://github.com/openssl/openssl -b OpenSSL_1_0_2-stable
#git clone git://github.com/madler/zlib
#git clone git://github.com/enki/libev
cd ..
CMAKE_VERSION=3.11.4
#wget https://cmake.org/files/v3.11/cmake-$CMAKE_VERSION-Linux-x86_64.tar.gz
#tar zxf cmake-$CMAKE_VERSION-Linux-x86_64.tar.gz
#CMAKE=$SELF/local/cmake-$CMAKE_VERSION-Linux-x86_64/bin/cmake
CMAKE=cmake
pushd ./src/zlib
CFLAGS="-fPIC -O3" ./configure --static --prefix=$SELF/local/zlib
make
make install
popd
#pushd ./src/libev
#CFLAGS="-fPIC -O3" ./configure --prefix=$SELF/local/libev
#make
#make install
#sed -i 's|#if __STDC_VERSION__.*|#if 0|' $SELF/local/libev/include/ev.h
#popd
pushd ./src/openssl
./config --prefix=$SELF/local/openssl -fpic --pic no-asm no-ec_nistp_64_gcc_128 no-gmp no-jpake no-krb5 no-libunbound no-md2 no-rc5 no-rfc3779 no-sctp no-shared no-ssl-trace no-ssl2 no-store no-unit-test no-weak-ssl-ciphers no-zlib no-zlib-dynamic
make
make install
popd
pushd ./src/libwebsockets
#$CMAKE -DCMAKE_EXE_LINKER_FLAGS=-static -DCMAKE_VERBOSE_MAKEFILE=ON -DCMAKE_INSTALL_PREFIX=$SELF/local/libwebsockets \
$CMAKE -DCMAKE_VERBOSE_MAKEFILE=ON -DCMAKE_INSTALL_PREFIX=$SELF/local/libwebsockets \
    -DLWS_UNIX_SOCK=ON -DLWS_WITHOUT_TESTAPPS=ON -DLWS_WITH_ZIP_FOPS=ON \
    -DLWS_WITH_ZLIB=ON -DLWS_ZLIB_INCLUDE_DIRS=$SELF/local/zlib/include -DLWS_ZLIB_LIBRARIES=$SELF/local/zlib/lib/libz.a \
    -DOPENSSL_CRYPTO_LIBRARY=$SELF/local/openssl/lib/libcrypto.a -DOPENSSL_SSL_LIBRARY=$SELF/local/openssl/lib/libssl.a -DOPENSSL_INCLUDE_DIR=$SELF/local/openssl/include \
    .
#    -DLWS_WITH_LIBEV=ON -DLWS_LIBEV_INCLUDE_DIRS=$SELF/local/libev/include -DLWS_LIBEV_LIBRARIES=$SELF/local/libev/lib/libev.a \
#sed -i 's|-Werror ||g' CMakeLists.txt
#sed -i 's|APPEND LIB_LIST m|APPEND LIB_LIST m z dl|g' CMakeLists.txt
make
mkdir -p dist
make install
popd
pushd ./src/json-c
bash autogen.sh
./configure --prefix=$SELF/local/json-c
make
mkdir -p dist
make install
popd
popd
export PKG_CONFIG_PATH=$SELF/local/libwebsockets/lib/pkgconfig:$SELF/local/json-c/lib/pkgconfig
$CMAKE -DCMAKE_VERBOSE_MAKEFILE=ON -DCMAKE_EXE_LINKER_FLAGS=-static -DCMAKE_FIND_LIBRARY_SUFFIXES=".a" \
    -DJSON-C_INCLUDE_DIR=$SELF/local/json-c/include/json-c -DJSON-C_LIBRARY=$SELF/local/json-c/lib/libjson-c.a \
    -DLIBWEBSOCKETS_INCLUDE_DIR=$SELF/local/libwebsockets/include -DLIBWEBSOCKETS_LIBRARIES=$SELF/local/libwebsockets/lib/libwebsockets.a -DLIBWEBSOCKETS_LIBRARY_DIRS=$SELF/local/libwebsockets/lib \
    -DOPENSSL_CRYPTO_LIBRARY=$SELF/local/openssl/lib/libcrypto.a -DOPENSSL_SSL_LIBRARY=$SELF/local/openssl/lib/libssl.a -DOPENSSL_INCLUDE_DIR=$SELF/local/openssl/include \
    .
#    -DCMAKE_C_FLAGS=-I$SELF/local/libev/include \
#    -DOPENSSL_CRYPTO_LIBRARY=/usr/lib64/libcrypto.a -DOPENSSL_LIBRARIES=/usr/lib64/libssl.a -DOPENSSL_INCLUDE_DIR=/usr/include \
#sed -i "s|LINK_LIBS util pthread \${OPENSSL_LIBRARIES} \${LIBWEBSOCKETS_LIBRARIES} \${JSON-C_LIBRARY}|LINK_LIBS util pthread \${LIBWEBSOCKETS_LIBRARIES} \${JSON-C_LIBRARY} \${OPENSSL_LIBRARIES} $SELF/local/libev/lib/libev.a $SELF/local/zlib/lib/libz.a m dl|g" CMakeLists.txt
sed -i "s|LINK_LIBS util pthread \${OPENSSL_LIBRARIES} \${LIBWEBSOCKETS_LIBRARIES} \${JSON-C_LIBRARY}|LINK_LIBS util pthread \${LIBWEBSOCKETS_LIBRARIES} \${JSON-C_LIBRARY} \${OPENSSL_LIBRARIES} $SELF/local/zlib/lib/libz.a dl|g" CMakeLists.txt
make
