#! /bin/bash

set -e
pkg_install=false
if [ $1 == '--install' ]; then
    pkg_install=true
fi

mk_protobuf_from_source() {
    git clone https://github.com/google/protobuf && \
        cd protobuf && \
        git checkout tags/v3.2.0 && \
        git submodule update --init --recursive

    # download gmock and gtest
    curl $curlopts -L -O https://github.com/google/googlemock/archive/release-1.7.0.zip && \
    unzip -q release-1.7.0.zip && \
    mv googlemock-release-1.7.0 gmock && \
    rm -f release-1.7.0.zip
    curl $curlopts -L -O https://github.com/google/googletest/archive/release-1.7.0.zip && \
    unzip -q release-1.7.0.zip && \
    mv googletest-release-1.7.0 gmock/gtest && \
    rm -f release-1.7.0.zip

    # add packaging
    cat > debian.patch <<EOF
diff --git a/cmake/CMakeLists.txt b/cmake/CMakeLists.txt
index df3b201..30aea0b 100644
--- a/cmake/CMakeLists.txt
+++ b/cmake/CMakeLists.txt
@@ -181,3 +181,24 @@ endif (protobuf_BUILD_EXAMPLES)
 if(protobuf_VERBOSE)
     message(STATUS "Protocol Buffers Configuring done")
 endif()
+
+# create a debian package
+set (CPACK_GENERATOR "DEB")
+execute_process (COMMAND uname -m OUTPUT_VARIABLE __machine_arch
+    OUTPUT_STRIP_TRAILING_WHITESPACE
+    RESULT_VARIABLE rc)
+if (\${__machine_arch} STREQUAL "x86_64")
+  set (CPACK_DEBIAN_PACKAGE_ARCHITECTURE "amd64")
+else()
+  set (CPACK_DEBIAN_PACKAGE_ARCHITECTURE "i386")
+endif()
+set (CPACK_PACKAGE_NAME "\${PROJECT_NAME}-dev")
+set (CPACK_PACKAGE_VERSION_MAJOR "\${protobuf_VERSION_MAJOR}")
+set (CPACK_PACKAGE_VERSION_MINOR "\${protobuf_VERSION_MINOR}")
+set (CPACK_PACKAGE_VERSION_PATCH "\${protobuf_VERSION_PATCH}")
+set (CPACK_PACKAGE_VERSION "\${protobuf_VERSION_STRING}")
+set (CPACK_PACKAGE_CONTACT "\${protobuf_CONTACT}")
+set (CPACK_PACKAGE_VENDOR "\${protobuf_CONTACT}")
+set (CPACK_PACKAGE_DESCRIPTION_SUMMARY "Protocol Buffers")
+set (CPACK_PACKAGE_DESCRIPTION "Protocol Buffers")
+include (CPack)
EOF
    git apply debian.patch
    mkdir -p build.cmake && cd build.cmake
    cmake -DCMAKE_INSTALL_PREFIX=/usr/local -DCMAKE_BUILD_TYPE=RELEASE ../cmake
    make -j 4 package
}

arch=$(uname -m)
nprocs=$(cat /proc/cpuinfo | grep processor | wc -l)
builddir=$(mktemp --directory -t protobuf_XXXXXX)
mydir=$(realpath `dirname $0`)
pushd $builddir
mk_protobuf_from_source
if $pkg_install == true; then
    dpkg -i protobuf-dev*.deb
else
    set -x
    cp -r protobuf-dev*.deb ${mydir}/${arch}
    popd
    rm -rf $builddir

    # dpkg-sig --sign builder ${mydir}/${arch}/protobuf-dev*.deb
fi
