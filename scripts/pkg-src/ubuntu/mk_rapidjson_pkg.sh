#! /bin/bash

set -e

function build_rapidjson_from_source() {
    # ARG: rapidjson version
    local rj_ver=$1
    local nprocs=$(cat /proc/cpuinfo | grep processor | wc -l)
    local builddir=$(mktemp --directory -t rjson_XXXXXX)
    cd $builddir
    # add packaging info
    cat > rj.patch <<EOF
diff --git a/CMakeLists.txt b/CMakeLists.txt
index ceda71b1..21acee18 100644
--- a/CMakeLists.txt
+++ b/CMakeLists.txt
@@ -171,3 +171,24 @@ INSTALL(FILES
     \${CMAKE_CURRENT_BINARY_DIR}/\${PROJECT_NAME}ConfigVersion.cmake
     DESTINATION "\${CMAKE_INSTALL_DIR}"
     COMPONENT dev)
+
+# create a debian package
+set (CPACK_GENERATOR "DEB")
+set (CPACK_PACKAGE_NAME "\${PROJECT_NAME}-dev")
+set (CPACK_PACKAGE_VERSION_MAJOR \${LIB_MAJOR_VERSION})
+set (CPACK_PACKAGE_VERSION_MINOR \${LIB_MINOR_VERSION})
+set (CPACK_PACKAGE_VERSION_PATCH \${LIB_PATHC_VERSION})
+set (CPACK_PACKAGE_VERSION "\${LIB_VERSION_STRING}")
+set (CPACK_PACKAGE_CONTACT "THL A29 Limited")
+set (CPACK_PACKAGE_VENDOR "THL A29 Limited")
+set (CPACK_PACKAGE_DESCRIPTION_SUMMARY "RapidJSON")
+set (CPACK_PACKAGE_DESCRIPTION "RapidJSON")
+execute_process (COMMAND uname -m OUTPUT_VARIABLE __machine_arch
+    OUTPUT_STRIP_TRAILING_WHITESPACE
+    RESULT_VARIABLE rc)
+if (\${__machine_arch} STREQUAL "x86_64")
+  set (CPACK_DEBIAN_PACKAGE_ARCHITECTURE "amd64")
+else()
+  set (CPACK_DEBIAN_PACKAGE_ARCHITECTURE "i386")
+endif()
+include (CPack)
EOF
    git clone --recursive https://github.com/miloyip/rapidjson.git \
        --branch "v${rj_ver}" && \
        cd rapidjson && \
        git apply ../rj.patch && \
        mkdir build && cd build && \
        cmake .. -DRAPIDJSON_BUILD_DOC=OFF \
              -DRAPIDJSON_BUILD_EXAMPLES=OFF \
              -DRAPIDJSON_BUILD_TESTS=OFF && \
        make -j $nprocs && \
        cpack -G DEB
}



arch=$(uname -m)
nprocs=$(cat /proc/cpuinfo | grep processor | wc -l)
builddir=$(mktemp --directory -t rapidjson_XXXXXX)
mydir=$(realpath `dirname $0`)
pushd $builddir
build_rapidjson_from_source "1.1.0"
set -x
cp -r RapidJSON-dev*.deb ${mydir}/${arch}
popd
rm -rf $builddir

dpkg-sig --sign builder ${mydir}/${arch}/RapidJSON-dev*.deb
