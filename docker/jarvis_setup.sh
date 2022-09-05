#!/bin/bash -e

echo Running in $(pwd)
echo and docker dir: $(ls docker)

# Packages for jarvis image.
DEV_PKGS="distcc \
          vim \
          gdb \
          telnet \
          ninja-build \
          tmux \
          apache2"

apt install -y ${DEV_PKGS}

# Custom cmake config for Jarvis
cp docker/bf-p4c-preconfig-jarvis.cmake /bfn/bf-p4c-preconfig.cmake

# install VIM highlighter for P4
# based on https://raw.githubusercontent.com/c3m3gyanesh/p4-syntax-highlighter-collection/master/vim/install.sh
# but global
mkdir -p /etc/vim/syntax
mkdir -p /etc/vim/ftdetect
curl -o- -L https://raw.githubusercontent.com/c3m3gyanesh/p4-syntax-highlighter-collection/master/vim/ftdetect/p4.vim > /etc/vim/ftdetect/p4.vim
curl -o- -L https://raw.githubusercontent.com/c3m3gyanesh/p4-syntax-highlighter-collection/master/vim/syntax/p4.vim > /etc/vim/syntax/p4.vim

# install CGDB (newer then in Ubuntu)
CGDB_VERSION=0.8.0
(  # run in subshell to prevent changing workdir & affecting variables
    CGDB_MAKEDEPS="libreadline-dev libncurses-dev texinfo"
    apt install -yy --no-install-recommends $CGDB_MAKEDEPS
    BUILDDIR=$(mktemp -d)
    cd $BUILDDIR
    wget https://cgdb.me/files/cgdb-${CGDB_VERSION}.tar.gz
    tar xavf cgdb-${CGDB_VERSION}.tar.gz
    cd cgdb-${CGDB_VERSION}
    ./configure --prefix=/usr/local
    make
    make install
    cd
    rm -rf $BUILDDIR
    apt remove -yy $CGDB_MAKEDEPS
)

install -D -o root -g root -m 0644 docker/ccache.conf /etc/ccache.conf
install -D -o root -g root -m 0644 \
docker/ccache.conf /usr/local/etc/ccache.conf

# Configure distcc hosts.
install -D -o root -g root -m 0644 docker/distcc_hosts.conf /etc/distcc/hosts

# Create and adjust Apache configuration files at first startup.
/etc/init.d/apache2 start
sed -i $'/Global configuration$/{n;n;a ServerName localhost\\n\n}' /etc/apache2/apache2.conf
install -o root -g root -m 0644 docker/favicon.ico /var/www/html/favicon.ico

# Avoid call to `p4studio app activate` as Jarvis is not used with SDE installation typically
sed -i '/p4studio app activate/d' ~/.bashrc

# Remove the source code directory.
rm -rf /bfn/bf-p4c-compilers

