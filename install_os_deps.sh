#! /bin/bash

die () {
    if [ $# -gt 0 ]; then
        echo >&2 "$@"
    fi
    exit 1
}

function version_LT() {
    test "$(echo "$@" | tr " " "\n" | sort -rV | head -n 1)" != "$1";
}

# Determine the type of the Boost library we want to install
boost_lib_type=shared
if [[ $# > 0 ]] && [[ $1 == '--with-boost-static' ]]; then
    boost_lib_type=static
fi

# determine the OS and OS version
os=$(uname -s)
case $os in
    Linux)
        SUDO=sudo
        LDCONFIG=ldconfig
        LDLIB_EXT=so
        if [[ ! -e /etc/os-release ]]; then
            echo "Missing /etc/os-release. Can't identify linux distribution."
            exit 1
        fi
        linux_distro=$(cat /etc/os-release | grep -e "^NAME" | cut -f 2 -d '=' | tr -d "\"")
        nprocs=$(cat /proc/cpuinfo | grep processor | wc -l)
        case $linux_distro in
            Debian*)
                linux_distro="Debian"
                linux_version=$(lsb_release -r -s)
                linux_codename=$(lsb_release -c -s)
                ;;
            Ubuntu)
                linux_version=$(lsb_release -r -s)
                linux_codename=$(lsb_release -c -s)
                ;;
            "Linux Mint")
                linux_distro="Ubuntu" # Linux Mint is like Ubuntu
                linux_version=$(lsb_release -r -s)
                if [[ $linux_version =~ "18" ]] ; then
                    linux_version="16.04"
                elif [[ $linux_version =~ "19" ]]; then
                    linux_version="18.04"
                fi
                linux_codename=$(lsb_release -c -s)
                ;;
            Fedora)
                linux_version=$(cat /etc/os-release | grep -e "^VERSION_ID" | cut -f 2 -d '=' | tr -d "\"")
                linux_codename=$(cat /etc/os-release | grep -e "^ID" | cut -f 2 -d '=' | tr -d "\"")
		# since we install using make install, new packages go to /usr/local
		export PATH=/usr/local/bin:$PATH
		export PKG_CONFIG_PATH=/usr/local/lib/pkgconfig
                ;;
            "CentOS Linux")
                linux_version=$(cat /etc/os-release | grep -e "^VERSION_ID" | cut -f 2 -d '=' | tr -d "\"")
                linux_codename=$(cat /etc/os-release | grep -e "^ID" | cut -f 2 -d '=' | tr -d "\"")
		# since we install using make install, new packages go to /usr/local
		export PATH=/usr/local/bin:$PATH
		export PKG_CONFIG_PATH=/usr/local/lib/pkgconfig
                export LD_LIBRARY_PATH=/usr/local/lib
                ;;
            *)
                echo "Unsupported Linux distribution $linux_distro"
                exit 1
                ;;
            esac
    ;;
    Darwin)
        SUDO=
        LDCONFIG=:
        LDLIB_EXT=dylib
        nprocs=$(sysctl -n hw.physicalcpu)
    ;;
    *)
        echo "Unsuported OS $os"
        exit 1
        ;;
esac

if [[ $os == "Linux" ]]; then
    echo "Detected: $os OS $linux_distro, version $linux_version ($linux_codename)"
else
    echo "Detected: $os"
fi

install_python_packages() {
    pipVersion=$1
    # do not upgrade pip until Ubuntu sorts out their issues
    # If you have already upgraded, do: sudo apt-get remove python-pip python-pip-whl
    # $SUDO pip install --upgrade pip
    $SUDO pip$pipVersion install setuptools || die "Failed to install setuptools packages"
    $SUDO pip$pipVersion install Cython pyinstaller || die "Failed to install pyinstaller and Cython packages"
    $SUDO pip$pipVersion install ply==3.9 || die "Failed to install ply packages"
    $SUDO pip$pipVersion install jsl jsonschema || die "Failed to install jsl packages"
    $SUDO pip$pipVersion install thrift==0.11.0 || die "Failed to install thrift packages"  # need this one instead
    $SUDO pip$pipVersion install packaging || die "Failed to install packaging packages"
    $SUDO pip$pipVersion install pexpect || die "Failed to install pexpect packages"
    $SUDO pip$pipVersion install ipaddr pyyaml scapy || die "Failed to install python packages"
    $SUDO pip$pipVersion install ctypesgen || die "Failed to install python packages"
}

install_linux_packages() {
    if [[ $linux_distro == "Ubuntu" || $linux_distro == "Debian" ]]; then
        # please keep this list in alphabetical order
        apt_packages="automake autopoint bison cmake curl doxygen ethtool flex g++ git \
                 libcli-dev libedit-dev libeditline-dev libevent-dev \
                 libatomic-ops-dev libjudy-dev \
                 libmoose-perl libnl-route-3-dev libpcap0.8-dev libssl-dev \
                 libtool pkg-config \
                 python2.7 python python3 python-pip python3-pip \
                 rpm texinfo unzip"
        if [[ $linux_distro == "Ubuntu" && $linux_version =~ "18.04" ]]; then
            apt_packages="$apt_packages libboost-all-dev libfl-dev \
                         libjson-c-dev libjsoncpp-dev  rapidjson-dev"
        elif [[ $linux_distro == "Debian" && $linux_version =~ "9.5" ]]; then
            apt_packages="$apt_packages libboost-all-dev \
                          libjson-c-dev libjson-c3 realpath"
        else
            apt_packages="$apt_packages libjson0 libjson0-dev realpath"
        fi

        echo "Need sudo privs to install apt packages"
        $SUDO apt-get update || die "Failed to update apt"
        $SUDO apt-get install -y $apt_packages || \
        die "Failed to install needed packages"
        if [[ $linux_distro == "Ubuntu" && $linux_version =~ "14.04" ]]; then
            $SUDO add-apt-repository -y ppa:ubuntu-toolchain-r/test
            $SUDO apt-get install -y g++-4.9
            $SUDO update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-4.8 10
            $SUDO update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-4.9 20
            $SUDO update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-4.8 10
            $SUDO update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-4.9 20
        fi

        $SUDO apt-get remove -y python-thrift    # remove this broken package in case it was installed
        if [[ ! ($linux_distro == "Ubuntu" && $linux_version =~ "18.04") && \
              ! ($linux_distro == "Debian" && $linux_version =~ "9.5") ]]; then
            install_cmake "3.5.2"
            install_rapidjson "1.1.0"
            install_boost "1.67.0"
        elif [[ $linux_distro == "Debian" && $linux_version =~ "9.5" ]]; then
            install_rapidjson "1.1.0"
        fi
        install_libgc_linux
    fi
    if [[ $linux_distro == "Fedora" || $linux_distro == "CentOS Linux" ]]; then
        # please keep this list in alphabetical order
        yum_packages="automake bison bzip2-devel cmake curl doxygen flex \
                 gcc-c++ git \
                 libcli-devel libedit-devel libevent-devel \
                 gc json-devel Judy-devel \
                 libpcap-devel openssl-devel \
                 libtool pkg-config \
                 python2 python python-devel python-pip python3 python3-devel python3-pip \
                 rapidjson-devel rpm texinfo unzip"
        if [[ $linux_distro == "CentOS Linux" ]]; then
            # python-pip and software collections for newer versions of gcc
            # https://www.softwarecollections.org/en/scls/rhscl/devtoolset-3/
            $SUDO yum install -y epel-release centos-release-scl-rh
        fi
        echo "Need sudo privs to install yum packages"
        $SUDO yum update -y || die "Failed to update apt"
        $SUDO yum install -y $yum_packages || \
            die "Failed to install needed packages"

        if [[ $linux_distro == "CentOS Linux" ]]; then
            gcc_version=$(gcc --version | head -1 | awk '{print $3;}')
            if version_LT $gcc_version "4.9.1" ; then
                $SUDO yum install -y devtoolset-3-gcc-c++
                # use devetoolset gcc
                export PATH=/opt/rh/devtoolset-3/root/usr/bin:/usr/local/bin:$PATH
            fi
        fi
        install_bison "3.0.4"
        install_cmake "3.5.2"
        install_libgc_fed_cent
        install_rapidjson "1.1.0"
        install_boost "1.67.0"
        $SUDO pip install scapy
    fi

    install_python_packages 2
    install_python_packages 3
}

function install_bison() {
    local bison_ver=$1

    local installed_ver=$(yum info bison | grep Version | awk '{ print $3; }')
    if version_LT $installed_ver $bison_ver ; then
        # install a more recent version of bison
        $SUDO yum remove -y bison
        pushd /tmp
        wget https://ftp.gnu.org/gnu/bison/bison-${bison_ver}.tar.gz && \
        tar zxf bison-${bison_ver}.tar.gz && \
        cd bison-${bison_ver} && \
        ./configure && \
        make && $SUDO make install || die "Failed to install bison ${bison_ver}"
        cd /tmp && rm -rf bison-${bison_ver}*
        popd
    else
        echo "Found bison version $installed_ver"
    fi
}

function install_libgc_linux() {
    # Download, configure and build GC with large-config
    echo "Build and install libgc"
    curl -o gc-7.4.2.tar.gz https://hboehm.info/gc/gc_source/gc-7.4.2.tar.gz
    tar -xvf gc-7.4.2.tar.gz
    cd gc-7.4.2
    ./autogen.sh && ./configure --enable-large-config --enable-cplusplus --enable-shared
    $SUDO make && $SUDO make install || die "Failed to install libgc"
    $SUDO $LDCONFIG
}

function install_libgc_fed_cent() {
    echo "Checking for and installing the Boehm-Demers-Weiser GC library"
    if ! `pkg-config bdw-gc` || version_LT `pkg-config --modversion bdw-gc` "7.2.0"; then
        tmpdir=$(mktemp -d)
        echo "Using $tmpdir for temporary build files"
        pushd $tmpdir

        git clone git://github.com/ivmai/libatomic_ops.git
        git clone git://github.com/ivmai/bdwgc.git
        cd bdwgc
        git checkout v7.6.6
        ln -s  $tmpdir/libatomic_ops $tmpdir/bdwgc/libatomic_ops
        autoreconf -vif
        automake --add-missing
        ./configure --enable-large-config --disable-debug --disable-dependency-traking --enable-cplusplus
        make -j $nprocs
        $SUDO make install
        cd ..
        rm -rf libatomic_ops bdwgc
        popd
    fi
}

function install_cmake() {
    # ARG: cmake version
    cmake_ver=$1

    if [[ ! -z $(which cmake) ]]; then
        local installed_ver=$(cmake --version | head -1 | cut -f 3 -d " ")
        if ! version_LT $installed_ver $cmake_ver ; then
	    echo "Found cmake version $installed_ver"
            return
        fi
    fi

    if [[ ! ($linux_distro == "Ubuntu" || $linux_distro == "Debian") ]]; then
	cd /tmp
	build_cmake_from_source $cmake_ver 1
        cd /tmp && rm -rf /tmp/cmake-${cmake_ver}*
        return
    fi
    # On Ubuntu we install a package
    $SUDO apt-get install -y cmake=${cmake_ver}
    if [ $? != 0 ]; then
        cd /tmp
	build_cmake_from_source $cmake_ver 0 && \
            cpack -G DEB && \
            $SUDO apt-get remove -y cmake cmake-data && \
            $SUDO dpkg -i cmake-${cmake_ver}-Linux-x86_64.deb || \
                  die "failed to install cmake"
        cd /tmp && rm -rf /tmp/cmake-${cmake_ver}*
    fi
}

function build_cmake_from_source() {
    local cmake_ver=$1
    local install_it=$2
    local cmake_dir=$(echo ${cmake_ver} | cut -f 1-2 -d ".")
    wget http://www.cmake.org/files/v${cmake_dir}/cmake-${cmake_ver}.tar.gz && \
        tar zxvf cmake-${cmake_ver}.tar.gz && \
        cd cmake-${cmake_ver} && \
        mkdir build && \
        cd build && \
        cmake .. -DCMAKE_BUILD_TYPE=release && \
        make -j $nprocs
    if [[ $install_it == 1 ]]; then
	$SUDO make install
    fi
}

function install_boost() {
    # ARG: boost_version
    # test for ubuntu version, and check if we have a local package

    if [[ ($linux_distro == "Ubuntu" && $linux_version =~ "14.04") || \
              $linux_distro == "Debian" ]]; then
        $SUDO apt-get install -y python-dev libbz2-dev
    fi
    b_ver=$1
    boost_ver=$(echo $b_ver | tr "." "_")

    if [[ $linux_distro == "Ubuntu" ]]; then
        if version_LT "16.0" $linux_version ; then
            boost_libs="libboost-dev libboost-graph-dev libboost-test-dev libboost-program-options-dev libboost-system-dev libboost-filesystem-dev libboost-iostreams-dev libboost-thread-dev"
            $SUDO apt-get install -y ${boost_libs}
	    return
        fi
    fi
    if [[ $linux_distro == "Fedora" && $linux_version =~ "26" ]]; then
	$SUDO yum install -y boost-devel
	return
    fi

    install_pkg=true
    installed_ver="1_0"
    if [ -f /usr/local/include/boost/version.hpp ]; then
        installed_ver=$(grep -m 1 "define BOOST_LIB_VERSION" /usr/local/include/boost/version.hpp | cut -d ' ' -f 3 | cut -d '_' -f 1-2 | tr -d '"')
    fi
    if [ ! -z "$installed_ver" ]; then
        boost_ver_trim=${boost_ver%_0}
        if version_LT $installed_ver $boost_ver_trim ; then
            echo "Installed boost version is not sufficient: $installed_ver, proceeding with installing required boost: $boost_ver_trim"
        else
            echo "Installed boost version is sufficient: $installed_ver"
            if [[ "$boost_lib_type" == "static" ]]; then
                boost_static_io=`find /usr/local/ -name libboost_iostreams.a`
                if [ ! -z $boost_static_io ]; then
                    echo "And static library is available"
                    install_pkg=false
                fi
            else
                install_pkg=false
            fi
        fi
    fi
    if [ $install_pkg = true ]; then
        cd /tmp
        wget http://downloads.sourceforge.net/project/boost/boost/${b_ver}/boost_${boost_ver}.tar.bz2 && \
            tar xvjf ./boost_${boost_ver}.tar.bz2 && \
            cd boost_${boost_ver} && \
            ./bootstrap.sh --prefix=/usr/local && \
            ./b2 -j${nprocs} --build-type=minimal link=${boost_lib_type} \
                 runtime-link=${boost_lib_type} variant=release && \
            $SUDO ./b2 install --build-type=minimal variant=release \
                  link=${boost_lib_type} runtime-link=${boost_lib_type} || \
            die "failed to install boost"
        cd /tmp && rm -rf boost_${boost_ver}
    fi
}

function install_rapidjson() {
    # ARG: rapidjson version
    local rj_ver=$1
    install_it=1

    if ! `pkg-config RapidJSON` || version_LT `pkg-config --modversion RapidJSON` "1.1.0"; then
	if [[ $linux_distro == "Ubuntu" || $linux_distro == "Debian" ]]; then
            $SUDO apt-get install -y rapidjson-dev=${rj_ver}
            if [ $? == 0 ]; then
		echo "Installed package rapidjson-dev=1.1.0"
		return
	    fi
	    install_it=0 # we install a package
	fi
        build_rapidjson_from_source ${rj_ver} $install_it
	if [[ $linux_distro == "Ubuntu" || $linux_distro == "Debian" ]]; then
            $SUDO apt-get remove -y rapidjson-dev
	    $SUDO dpkg -i /tmp/RapidJSON-dev-${rj_ver}-Linux.deb || \
            die "failed to install rapidjson"
        fi
    fi
}

function build_rapidjson_from_source() {
    # ARG: rapidjson version
    local rj_ver=$1
    local install_it=$2
    local builddir=$(mktemp --directory -t rjson_XXXXXX)
    cd $builddir
    # add packaging info
    cat > rj.patch <<EOF
diff --git a/CMakeLists.txt b/CMakeLists.txt
index ceda71b1..21acee18 100644
--- a/CMakeLists.txt
+++ b/CMakeLists.txt
@@ -171,3 +171,18 @@ INSTALL(FILES
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
+set (CPACK_DEBIAN_PACKAGE_ARCHITECTURE "amd64")
+include (CPack)
+
EOF
    git clone https://github.com/miloyip/rapidjson.git \
        --branch "v${rj_ver}" && \
        cd rapidjson && \
        git apply ../rj.patch && \
        mkdir build && cd build && \
        cmake .. -DRAPIDJSON_BUILD_DOC=OFF \
              -DRAPIDJSON_BUILD_EXAMPLES=OFF \
              -DRAPIDJSON_BUILD_TESTS=OFF && \
        make -j $nprocs  || die "Failed to build rapidjson"
        if [[ $install_it == 1 ]] ; then
	    $SUDO make install  || die "Failed to install rapidjson"
	else
            cpack -G DEB && cp RapidJSON-dev-${rj_ver}-Linux.deb /tmp
	fi
        cd /tmp && \
        rm -rf $builddir
}

install_macos_packages() {
    # check for brew and install if not available
    if [ -z $(which brew) ]; then
	xcode-select --install
        /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
    fi

    brew_packages="autoconf automake bison bdw-gc boost ccache cmake coreutils doxygen dpkg flex gcc5 git graphviz libtool openssl pkg-config python rapidjson"
    # libedit-dev libeditline-dev libevent-dev libjudy-dev libjson0 libjson0-dev libmoose-perl libnl-route-3-dev libpcap0.8-dev
    brew install $brew_packages || die "Failed to install brew packages"
    # force to use the newer installed bison
    brew link --force bison
    # brew installs python and pip with suffix 2
    ln -sf /usr/local/bin/python2.7 /usr/local/bin/python
    ln -sf /usr/local/bin/pip2 /usr/local/bin/pip
    install_python_packages
    pip install scapy pyyaml ipaddr
}

function install_protobuf() {
    tmpdir=$(mktemp -d)
    echo "Checking for and installing protobuf"
    if ! `pkg-config protobuf` || version_LT `pkg-config --modversion protobuf` "3.0.0"; then
        if [[ $linux_distro == "Ubuntu" || $linux_distro == "Debian" ]]; then
            rc=$($SUDO apt-get install -y protobuf-dev=3.2.0 grpc-dev=1.3.2)
            if [ $? == 0 ]; then
                $SUDO pip install protobuf grpcio || die "Failed to install python grpc packages"
                return
            fi
        fi

        # Couldn't find a package so install from source
        echo "Using $tmpdir for temporary build files"
        pushd $tmpdir
        git clone https://github.com/google/protobuf
        cd protobuf
        git checkout tags/v3.2.0
        git submodule update --init --recursive
        ./autogen.sh && \
        ./configure && \
        make -j $nprocs && \
        $SUDO make install && \
        $SUDO $LDCONFIG || \
            die "Failed to install protobuf"
        cd ../
        /bin/rm -rf protobuf
        PI_clean_before_rebuild=true
        popd # tmpdir
    fi

    echo "Checking for and installing grpc"
    if ! `pkg-config grpc++` || version_LT `pkg-config --modversion grpc++` "1.3.0"; then
        pushd $tmpdir
        git clone https://github.com/google/grpc.git
        cd grpc
        git checkout tags/v1.3.2
        git submodule update --init --recursive
        # openssl 1.1.0 has changed the visibility of struct fields so we need to patch the RSA code
        if ! version_LT `pkg-config --modversion openssl` "1.1.0"; then
            cat > openssl-1.1.0.patch <<EOF
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

EOF
            git apply openssl-1.1.0.patch
        fi
        # gcc-7 gives errors
        make -j $nprocs CFLAGS="-Wno-error --std=c99" && \
        $SUDO make install && \
        $SUDO $LDCONFIG || \
                die "Failed to install grpc"
        cd ../
        /bin/rm -rf grpc
        PI_clean_before_rebuild=true
        popd # tmpdir
    fi
    gcc_version=$(gcc -v |& tail -1 | awk '{print $3;}')
    grpcio_version=""
    if [ $gcc_version == "4.9.2" ]; then
        grpcio_version="==1.7.0"
    fi
    $SUDO pip install protobuf grpcio${grpcio_version} || die "Failed to install python grpc packages"

    echo "Removing $tmpdir"
    rm -rf $tmpdir
}

function install_z3() {
    Z3='z3-4.8.7-x64-ubuntu-16.04'
    Z3_ZIP="${Z3}.zip"
    cd /tmp
    curl -L --noproxy "*" \
      https://artifacts-bxdsw.sc.intel.com/repository/generic/third-party/"${Z3_ZIP}" -o "${Z3_ZIP}"
    unzip "${Z3_ZIP}"

    cd "${Z3}"
    $SUDO cp bin/libz3.a /usr/local/lib/
    $SUDO cp bin/libz3.so /usr/local/lib/
    $SUDO cp bin/z3 /usr/local/bin/
    $SUDO cp include/*.h /usr/local/include/

    cd /tmp
    rm -rf "${Z3}" "${Z3_ZIP}"
}

# the main routine
case $os in
    Linux)
        p4c_apt_server_available=false
        p4c_server=compiler-svr4.sc.intel.com
        # check that we are on the Barefoot intranet and can access the package server.
        nc -z $p4c_server 22 > /dev/null 2>&1
        if [[ $? == 0 && $linux_distro == "Ubuntu" && $linux_version =~ "16.04" ]]; then
            p4c_apt_server_available=true
            echo "Found compiler server for prebuilt packages"
            p4c_list=${p4c_server}-p4c.list
            if [[ ! -e /etc/apt/sources.list.d/${p4c_list} ]]; then
                echo "deb https://${p4c_server}/apt/ubuntu/ ${linux_codename} main" >/tmp/${p4c_list}
                $SUDO mv /tmp/${p4c_list} /etc/apt/sources.list.d/
                wget -O - http://$p4c_server/apt/p4c.gpg.key | sudo apt-key add -
                $SUDO apt-get update
            fi
        fi
        install_linux_packages
        install_protobuf
        install_z3
    ;;
    Darwin)
        install_macos_packages
        install_protobuf
        install_z3
    ;;
    *)
        echo "Unsuported OS $os"
        exit 1
        ;;
esac
