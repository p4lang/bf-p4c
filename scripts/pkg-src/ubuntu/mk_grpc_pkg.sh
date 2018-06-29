#! /bin/bash

set -e

mk_grpc_from_source() {
    git clone https://github.com/google/grpc && \
        cd grpc && \
        git checkout tags/v1.3.2 && \
        git submodule update --init --recursive

    # add packaging
    cat > debian.patch <<EOF
diff --git a/src/core/lib/security/credentials/jwt/jwt_verifier.c b/src/core/lib/security/credentials/jwt/jwt_verifier.c
index 0e2a264371..5c1e6a70f7 100644
--- a/src/core/lib/security/credentials/jwt/jwt_verifier.c
+++ b/src/core/lib/security/credentials/jwt/jwt_verifier.c
@@ -493,6 +493,7 @@ static EVP_PKEY *pkey_from_jwk(grpc_exec_ctx *exec_ctx, const grpc_json *json,
     gpr_log(GPR_ERROR, "Could not create rsa key.");
     goto end;
   }
+#if OPENSSL_VERSION_NUMBER < 0x10100005L
   for (key_prop = json->child; key_prop != NULL; key_prop = key_prop->next) {
     if (strcmp(key_prop->key, "n") == 0) {
       rsa->n =
@@ -508,6 +509,28 @@ static EVP_PKEY *pkey_from_jwk(grpc_exec_ctx *exec_ctx, const grpc_json *json,
     gpr_log(GPR_ERROR, "Missing RSA public key field.");
     goto end;
   }
+#else
+  {
+    BIGNUM *bn_n = NULL;
+    BIGNUM *bn_e = NULL;
+    for (key_prop = json->child; key_prop != NULL; key_prop = key_prop->next) {
+      if (strcmp(key_prop->key, "n") == 0) {
+       bn_n =
+          bignum_from_base64(exec_ctx, validate_string_field(key_prop, "n"));
+       if (bn_n == NULL) goto end;
+      } else if (strcmp(key_prop->key, "e") == 0) {
+       bn_e =
+          bignum_from_base64(exec_ctx, validate_string_field(key_prop, "e"));
+       if (bn_e == NULL) goto end;
+      }
+    }
+    RSA_set0_key(rsa, bn_n, bn_e, NULL);
+    if (bn_e == NULL || bn_n == NULL) {
+      gpr_log(GPR_ERROR, "Missing RSA public key field.");
+      goto end;
+    }
+  }
+#endif
   result = EVP_PKEY_new();
   EVP_PKEY_set1_RSA(result, rsa); /* uprefs rsa. */

diff --git a/CMakeLists.txt b/CMakeLists.txt
index 680ee8b..45c36f0 100644
--- a/CMakeLists.txt
+++ b/CMakeLists.txt
@@ -54,16 +54,16 @@ else()
   set(gRPC_INSTALL OFF CACHE BOOL "Generate installation target")
 endif()

-set(gRPC_ZLIB_PROVIDER "module" CACHE STRING "Provider of zlib library")
+set(gRPC_ZLIB_PROVIDER "package" CACHE STRING "Provider of zlib library")
 set_property(CACHE gRPC_ZLIB_PROVIDER PROPERTY STRINGS "module" "package")

 set(gRPC_CARES_PROVIDER "module" CACHE STRING "Provider of c-ares library")
 set_property(CACHE gRPC_CARES_PROVIDER PROPERTY STRINGS "module" "package")

-set(gRPC_SSL_PROVIDER "module" CACHE STRING "Provider of ssl library")
+set(gRPC_SSL_PROVIDER "package" CACHE STRING "Provider of ssl library")
 set_property(CACHE gRPC_SSL_PROVIDER PROPERTY STRINGS "module" "package")

-set(gRPC_PROTOBUF_PROVIDER "module" CACHE STRING "Provider of protobuf library")
+set(gRPC_PROTOBUF_PROVIDER "package" CACHE STRING "Provider of protobuf library")
 set_property(CACHE gRPC_PROTOBUF_PROVIDER PROPERTY STRINGS "module" "package")

 set(gRPC_GFLAGS_PROVIDER "module" CACHE STRING "Provider of gflags library")
@@ -225,6 +225,7 @@ elseif("\${gRPC_SSL_PROVIDER}" STREQUAL "package")
 endif()

 if("\${gRPC_GFLAGS_PROVIDER}" STREQUAL "module")
+  set(REGISTER_INSTALL_PREFIX OFF )
   if(NOT GFLAGS_ROOT_DIR)
     set(GFLAGS_ROOT_DIR \${CMAKE_CURRENT_SOURCE_DIR}/third_party/gflags)
   endif()
@@ -13836,3 +13837,23 @@ foreach(_config gRPCConfig gRPCConfigVersion)
     DESTINATION \${CMAKE_INSTALL_CMAKEDIR}
   )
 endforeach()
+
+# create a debian package
+set (CPACK_GENERATOR "DEB")
+execute_process (COMMAND uname -m OUTPUT_VARIABLE __machine_arch
+  OUTPUT_STRIP_TRAILING_WHITESPACE
+  RESULT_VARIABLE rc)
+if (\${__machine_arch} STREQUAL "x86_64")
+  set (CPACK_DEBIAN_PACKAGE_ARCHITECTURE "amd64")
+else()
+  set (CPACK_DEBIAN_PACKAGE_ARCHITECTURE "i386")
+endif()
+set (CPACK_PACKAGE_NAME "\${PROJECT_NAME}-dev")
+set (CPACK_PACKAGE_FILE_NAME \${CPACK_PACKAGE_NAME}-\${PACKAGE_VERSION}.\${CPACK_DEBIAN_PACKAGE_ARCHITECTURE})
+set (CPACK_PACKAGE_VERSION "\${PACKAGE_VERSION}")
+set (CPACK_PACKAGE_CONTACT "p4c@barefootnetworks.com")
+set (CPACK_PACKAGE_VENDOR "Google")
+set (CPACK_PACKAGE_DESCRIPTION_SUMMARY "An RPC library and framework")
+set (CPACK_PACKAGE_DESCRIPTION "An RPC library and framework")
+set (CPACK_DEBIAN_PACKAGE_DEPENDS "libssl1.0.0, protobuf-dev (>=3.2.0), zlib1g-dev")
+include (CPack)
EOF
    git apply debian.patch
    mkdir -p build.cmake && cd build.cmake
    cmake -DCMAKE_INSTALL_PREFIX=/usr/local -DCMAKE_BUILD_TYPE=RELEASE ..
    make -j $nprocs package
}

arch=$(uname -m)
nprocs=$(cat /proc/cpuinfo | grep processor | wc -l)
builddir=$(mktemp --directory -t grpc_XXXXXX)
mydir=$(realpath `dirname $0`)
pushd $builddir
mk_grpc_from_source
set -x
cp -r grpc-dev*.deb ${mydir}/${arch}
popd
rm -rf $builddir

# dpkg-sig --sign builder ${mydir}/${arch}/grpc-dev*.deb
