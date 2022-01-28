#!/usr/bin/env python

import os
import sys
import datetime
import yaml
import argparse
import multiprocessing

python_v = (sys.version_info)

curr_dir = os.path.dirname(os.path.abspath(__file__))

import utils
import dependencies

from distutils.version import StrictVersion


# -----------------------------------------------------------------------------

def install_grpc(os_name,
                 os_version,
                 jobs,
                 sde_install,
                 logger=None,
                 log_file=None,
                 resume_build=False,
                 progress_file=None):
    curr_date = datetime.date.today().strftime('%y%m%d')
    curr_time = datetime.datetime.now().strftime('%H%M%S')
    if log_file is None:
        log_file = '%s/grpc_%s_%s.log' % (curr_dir, curr_date, curr_time)

    # Add install lib path to $LD_LIBRARY_PATH
    install_lib = sde_install + "/lib"
    ld_library_path = str(os.environ.get('LD_LIBRARY_PATH') or '')
    if install_lib not in ld_library_path:
        os.environ['LD_LIBRARY_PATH'] = install_lib + \
                                        os.pathsep + \
                                        ld_library_path
    # Add install lib path to $LD_RUN_PATH
    install_lib = sde_install + "/lib"
    ld_run_path = str(os.environ.get('LD_RUN_PATH') or '')
    if install_lib not in ld_run_path:
        os.environ['LD_RUN_PATH'] = install_lib + \
                                    os.pathsep + \
                                    ld_run_path
    if resume_build:
        status = utils.check_progress(progress_file, install_grpc.__name__)
        if status:
            return (True, '\t - Skipping installation of GRPC ...')

    # Get thrift source data from dependencies.yaml
    dp = dependencies.Dependencies('%s/dependencies.yaml' % curr_dir)
    defaults = dp.get_defaults()
    os_defaults = dp.get_defaults(os_name)

    grpc_data = defaults['source_packages']['grpc']
    grpc_ver = None

    if grpc_data.get('version') is not None:
        grpc_ver = grpc_data['version']

    if grpc_ver is None and os_defaults.get('source_packages') is not None:
        os_grpc_data = os_defaults['source_packages'].get('grpc')
        if os_grpc_data is not None:
            grpc_ver = os_grpc_data.get('version')

    if grpc_ver is None and version_deps.get('source_packages') is not None:
        ver_grpc_data = version_deps['source_packages'].get('grpc')
        if ver_grpc_data is not None:
            grpc_ver = ver_grpc_data.get('version')

    if os.path.exists('%s/grpc_protobuf' % curr_dir):
          os.makedirs('%s/grpc_protobuf.old-%s-%s' % (curr_dir,
                                                      curr_date,
                                                      curr_time))
          os.system('mv %s/grpc_protobuf %s/grpc_protobuf.old-%s-%s'
                    % (curr_dir, curr_dir, curr_date, curr_time))
    #check os name and version
    if os.path.exists('/etc/os-release'):
        status = utils.exec_cmd('cat /etc/os-release')
        os_info = status[0].split('\n')
        os_name = [i for i in os_info if i.startswith('NAME=')][0][5:]
        os_name = os_name.replace('"', '').split(' ')[0]
        os_version = [x for x in os_info if "VERSION_ID" in x][0][11:]
        os_version = os_version.replace('"', '')
    else:
        return (False, "Cannot read OS info as /etc/os-release file " + \
                       "doesn't exist, please pass OS info using " + \
                       "--os-detail")

    # Check and uninstall older GRPC and Protobuf version
    line = '\t - Check and uninstall GRPC and Protobuf ... '
    if logger is not None:
        logger.info(line)
    else:
        print (line)
    protobuf_data = grpc_data['protobuf']

    # Extract and Build Protobuf
    line = '\t - Building Protobuf ... '
    if logger is not None:
        logger.info(line)
    else:
        print (line)
    utils.write_to_log(log_file, line)
    protobuf_data = grpc_data['protobuf']
    os.makedirs('%s/grpc_protobuf' % curr_dir)
    os.chdir('%s/grpc_protobuf' % curr_dir)
    cmds = ['%s %s' % (protobuf_data['mode'], protobuf_data['url']),
            'tar xvzf protobuf-cpp-%s.tar.gz' % protobuf_data['version']]
    for cmd in cmds:
        line = '\t\tCOMMAND: [%s]' % cmd
        if logger is not None:
            logger.info(line)
        else:
            print (line)
        utils.write_to_log(log_file, line)
        status = utils.exec_cmd(cmd, log_file)
        if status[2] != 0:
            return (False, 'Failed to extract protobuf, command - ' + \
                           '%s, error - %s' % (cmd, status[1]))
    os.chdir('%s/grpc_protobuf/protobuf-%s' \
             % (curr_dir, protobuf_data['version']))
    
    if python_v.major == 2:

        os.chdir('%s/grpc_protobuf/protobuf-%s' \
                 % (curr_dir, protobuf_data['version']))
        cmds = ['./autogen.sh',
                './configure --prefix=%s' %sde_install,
                'make -j%s' % jobs,
                'make install',
                'sudo ldconfig',
                'sudo -E  pip install protobuf==%s' % protobuf_data['version']]

    if python_v.major == 3:

        os.chdir('%s/grpc_protobuf/protobuf-%s' \
                 % (curr_dir, protobuf_data['version']))
        cmds = ['./autogen.sh',
                './configure --prefix=%s' %sde_install,
                'make -j%s' % jobs,
                'make install',
                'sudo ldconfig',
                'sudo -E python3 -m  pip install protobuf==%s' % protobuf_data['version']]

    for cmd in cmds:
        line = '\t\tCOMMAND: [%s]' % cmd
        if logger is not None:
            logger.info(line)
        else:
            print (line)
        utils.write_to_log(log_file, line)
        status = utils.exec_cmd(cmd, log_file)
        if status[2] != 0:
            return (False, 'Building Protobuf failed, command - ' + \
                           '%s, error - %s' % (cmd, status[1]))


    # Extract and Build GRPC
    line = '\t - Building GRPC ... '
    if logger is not None:
        logger.info(line)
    else:
        print (line)
    utils.write_to_log(log_file, line)
    os.chdir('%s/grpc_protobuf' % curr_dir)
    cmd = '%s %s' % (grpc_data['mode'], grpc_data['url'])
    line = '\t\tCOMMAND: [%s]' % cmd
    if logger is not None:
        logger.info(line)
    else:
        print (line)
    utils.write_to_log(log_file, line)
    status = utils.exec_cmd(cmd, log_file)
    if status[2] != 0:
        return (False, 'Failed to extract GRPC, command - ' + \
                       '%s, error - %s' % (cmd, status[1]))

    if os_name == 'CentOS':
        pkg_config_path = sde_install+'/lib64/pkgconfig:/usr/lib64/pkgconfig:$PKG_CONFIG_PATH'
    else:
        pkg_config_path = sde_install+'/lib/pkgconfig:$PKG_CONFIG_PATH'

    difftoapply="""diff --git a/Makefile b/Makefile
index 02273df..d4b3709 100644
--- a/Makefile
+++ b/Makefile
@@ -238,7 +238,7 @@ DEFINES_counters = NDEBUG

 prefix ?= /usr/local

-PROTOC ?= protoc
+PROTOC ?= """ + sde_install+ """/bin/protoc
 DTRACE ?= dtrace
 CONFIG ?= opt
 # Doing X ?= Y is the same as:
@@ -840,10 +840,10 @@ endif
 LIBS_PROTOBUF = protobuf
 LIBS_PROTOC = protoc protobuf

-HOST_LDLIBS_PROTOC += $(addprefix -l, $(LIBS_PROTOC))
+HOST_LDLIBS_PROTOC += -L""" + sde_install + """/lib $(addprefix -l, $(LIBS_PROTOC))

 ifeq ($(PROTOBUF_PKG_CONFIG),true)
-LDLIBS_PROTOBUF += $(shell $(PKG_CONFIG) --libs-only-l protobuf)
+LDLIBS_PROTOBUF += $(shell $(PKG_CONFIG) --libs protobuf)
 else
 LDLIBS_PROTOBUF += $(addprefix -l, $(LIBS_PROTOBUF))
 endif
"""
    filename = '%s/grpc-makefile-patch1_%s_%s' % (curr_dir, curr_date, curr_time)
    with open(filename,'w') as f:
        f.write(difftoapply)

    line = '\t \t- Patch1 Makefile created ... '
    if logger is not None:
        logger.info(line)
    else:
        print (line)


    diff2toapply= """diff --git a/build.yaml b/build.yaml
diff --git a/build.yaml b/build.yaml
index 62e07f64e4..14dd801abd 100644
--- a/build.yaml
+++ b/build.yaml
@@ -5848,7 +5848,6 @@ configs:
 defaults:
   ares:
     CFLAGS: -Wno-sign-conversion $(if $(subst Darwin,,$(SYSTEM)),,-Wno-shorten-64-to-32)
-      $(if $(subst MINGW32,,$(SYSTEM)),-Wno-invalid-source-encoding,)
     CPPFLAGS: -Ithird_party/cares -Ithird_party/cares/cares -fvisibility=hidden -D_GNU_SOURCE
       $(if $(subst Darwin,,$(SYSTEM)),,-Ithird_party/cares/config_darwin) $(if $(subst
       FreeBSD,,$(SYSTEM)),,-Ithird_party/cares/config_freebsd) $(if $(subst Linux,,$(SYSTEM)),,-Ithird_party/cares/config_linux)
diff --git a/src/core/lib/gpr/log_linux.cc b/src/core/lib/gpr/log_linux.cc
index 561276f0c20..8b597b4cf2f 100644
--- a/src/core/lib/gpr/log_linux.cc
+++ b/src/core/lib/gpr/log_linux.cc
@@ -40,7 +40,7 @@
 #include <time.h>
 #include <unistd.h>

-static long gettid(void) { return syscall(__NR_gettid); }
+static long sys_gettid(void) { return syscall(__NR_gettid); }

 void gpr_log(const char* file, int line, gpr_log_severity severity,
              const char* format, ...) {
@@ -70,7 +70,7 @@ void gpr_default_log(gpr_log_func_args* args) {
   gpr_timespec now = gpr_now(GPR_CLOCK_REALTIME);
   struct tm tm;
   static __thread long tid = 0;
-  if (tid == 0) tid = gettid();
+  if (tid == 0) tid = sys_gettid();

   timer = static_cast<time_t>(now.tv_sec);
   final_slash = strrchr(args->file, '/');
diff --git a/src/core/lib/gpr/log_posix.cc b/src/core/lib/gpr/log_posix.cc
index b6edc14ab6b..2f7c6ce3760 100644
--- a/src/core/lib/gpr/log_posix.cc
+++ b/src/core/lib/gpr/log_posix.cc
@@ -31,7 +31,7 @@
 #include <string.h>
 #include <time.h>

-static intptr_t gettid(void) { return (intptr_t)pthread_self(); }
+static intptr_t sys_gettid(void) { return (intptr_t)pthread_self(); }

 void gpr_log(const char* file, int line, gpr_log_severity severity,
              const char* format, ...) {
@@ -86,7 +86,7 @@ void gpr_default_log(gpr_log_func_args* args) {
   char* prefix;
   gpr_asprintf(&prefix, "%s%s.%09d %7tu %s:%d]",
                gpr_log_severity_string(args->severity), time_buffer,
-               (int)(now.tv_nsec), gettid(), display_file, args->line);
+               (int)(now.tv_nsec), sys_gettid(), display_file, args->line);

   fprintf(stderr, "%-70s %s\\n", prefix, args->message);
   gpr_free(prefix);
diff --git a/src/core/lib/iomgr/ev_epollex_linux.cc b/src/core/lib/iomgr/ev_epollex_linux.cc
index 06a382c556..371bd19aa8 100644
--- a/src/core/lib/iomgr/ev_epollex_linux.cc
+++ b/src/core/lib/iomgr/ev_epollex_linux.cc
@@ -1150,7 +1150,7 @@ static void end_worker(grpc_pollset* pollset, grpc_pollset_worker* worker,
 }

 #ifndef NDEBUG
-static long gettid(void) { return syscall(__NR_gettid); }
+static long sys_gettid(void) { return syscall(__NR_gettid); }
 #endif

 /* pollset->mu lock must be held by the caller before calling this.
@@ -1170,7 +1170,7 @@ static grpc_error* pollset_work(grpc_pollset* pollset,
 #define WORKER_PTR (&worker)
 #endif
 #ifndef NDEBUG
-  WORKER_PTR->originator = gettid();
+  WORKER_PTR->originator = sys_gettid();
 #endif
   if (grpc_polling_trace.enabled()) {
     gpr_log(GPR_INFO,
Submodule third_party/cares/cares contains modified content
diff --git a/third_party/cares/cares/ares_init.c b/third_party/cares/cares/ares_init.c
index f7b700b..22b81de 100644
--- a/third_party/cares/cares/ares_init.c
+++ b/third_party/cares/cares/ares_init.c
@@ -298,7 +298,7 @@ int ares_dup(ares_channel *dest, ares_channel src)
   (*dest)->sock_func_cb_data   = src->sock_func_cb_data;

   strncpy((*dest)->local_dev_name, src->local_dev_name,
-          sizeof(src->local_dev_name));
+          sizeof((*dest)->local_dev_name));
   (*dest)->local_ip4 = src->local_ip4;
   memcpy((*dest)->local_ip6, src->local_ip6, sizeof(src->local_ip6));

diff --git a/third_party/cares/cares/ares_parse_ptr_reply.c b/third_party/cares/cares/ares_parse_ptr_reply.c
index 976a531..04c7a38 100644
--- a/third_party/cares/cares/ares_parse_ptr_reply.c
+++ b/third_party/cares/cares/ares_parse_ptr_reply.c
@@ -124,14 +124,15 @@ int ares_parse_ptr_reply(const unsigned char *abuf, int alen, const void *addr,
           if (hostname)
             ares_free(hostname);
           hostname = rr_data;
-          aliases[aliascnt] = ares_malloc((strlen(rr_data)+1) * sizeof(char));
+          long unsigned int aliases_len = (strlen(rr_data)+1) * sizeof(char);
+          aliases[aliascnt] = ares_malloc(aliases_len);
           if (!aliases[aliascnt])
             {
               ares_free(rr_name);
               status = ARES_ENOMEM;
               break;
             }
-          strncpy(aliases[aliascnt], rr_data, strlen(rr_data)+1);
+          strncpy(aliases[aliascnt], rr_data, aliases_len);
           aliascnt++;
           if (aliascnt >= alias_alloc) {
             char **ptr;
"""
  
    filename2 = '%s/grpc-makefile-patch2_%s_%s' % (curr_dir, curr_date, curr_time)
    with open(filename2,'w') as f:
        f.write(diff2toapply)
    line = '\t \t- Patch2 Makefile created ... '
    if logger is not None:
        logger.info(line)
    else:
        print (line)

    diff3toapply = """
diff --git a/requirements.txt b/requirements.txt
index 6c97824621..2b89a77d83 100644
--- a/requirements.txt
+++ b/requirements.txt
@@ -1,6 +1,6 @@
 # GRPC Python setup requirements
 coverage>=4.0
-cython==0.28.3
+cython==0.29.24
 enum34>=1.0.4
 protobuf>=3.5.0.post1
 six>=1.10
"""
    
    filename3 = '%s/grpc-makefile-patch3_%s_%s' % (curr_dir, curr_date, curr_time)
    with open(filename3,'w') as f:
        f.write(diff3toapply)
    line = '\t \t- Patch3 Makefile created ... '
    if logger is not None:
        logger.info(line)
    else:
        print (line)

    patch_for_u20 = False
    grpc_compilex_args = ""
    if (os_name == 'Ubuntu' and os_version == '20.04') or (os_name == 'Debian' and os_version == '10') or (os_name == 'CentOS' and os_version == '8') or (os_name == 'Debian' and os_version == '11'):
        patch_for_u20 = True
        grpc_compilex_args = "-Wno-error=class-memaccess -Wno-error=ignored-qualifiers -Wno-error=stringop-truncation -Wno-stringop-overflow  -Wno-error=unused-function -Wno-error"
        grpc_flags = "-Wno-error"
    
    os.chdir('%s/grpc_protobuf/grpc' % curr_dir)
    if (os_name == 'CentOS' and os_version == '8') or (os_name == 'Debian' and os_version == '10') or (os_name == 'Ubuntu' and os_version == '20.04') or (os_name == 'Debian' and os_version == '11'):
        cmds = ['git checkout tags/v%s' % grpc_ver,
                'git submodule update --init --recursive',
                'patch < %s' % filename,
                'git apply %s' % filename2 if patch_for_u20 else ":",
                'git apply %s' % filename3 if patch_for_u20 else ":",
                'PKG_CONFIG_PATH=%s make prefix=%s CFLAGS="%s" CXXFLAGS="%s" -j%s' % ( pkg_config_path,
                                                                                       sde_install,
                                                                                       grpc_flags,
                                                                                       grpc_compilex_args,
                                                                                       jobs),
                'PKG_CONFIG_PATH=%s make install prefix=%s CFLAGS="%s" CXXFLAGS="%s" -j%s' % ( pkg_config_path,
                                                                                       sde_install,
                                                                                       grpc_flags,
                                                                                       grpc_compilex_args,
                                                                                       jobs),
                'sudo ldconfig',
                "sudo -E pip install 'coverage>=4.0,<6.0'" if python_v.major == 2 else "sudo -E pip3 install 'coverage>=4.0,<6.0'",
                'sudo -E pip install -r requirements.txt' if python_v.major == 2 else 'sudo -E pip3 install -r requirements.txt',
                'sudo -E pip install .' if python_v.major == 2 else 'sudo -E pip3 install .']

    
    else:
        cmds = ['git checkout tags/v%s' % grpc_ver,
                'git submodule update --init --recursive',
                'patch < %s' % filename,
                'PKG_CONFIG_PATH=%s make prefix=%s -j%s' % ( pkg_config_path, sde_install,
                                                             jobs),
                'make install prefix=%s' % (sde_install),
                'sudo ldconfig',
                "sudo -E pip install 'coverage>=4.0,<6.0'" if python_v.major == 2 else "sudo -E pip3 install 'coverage>=4.0,<6.0'",
                'sudo -E pip install -r requirements.txt' if python_v.major == 2 else 'sudo -E pip3 install -r requirements.txt',
                'sudo -E pip install .' if python_v.major == 2 else 'sudo -E pip3 install .']

    
    


    for cmd in cmds:
        line = '\t\tCOMMAND: [%s]' % cmd
        if logger is not None:
            logger.info(line)
        else:
            print (line)
        utils.write_to_log(log_file, line)
        status = utils.exec_cmd(cmd, log_file)
        if status[2] != 0:
            return (False, 'Building GRPC failed, command - ' + \
                           '%s, error - %s' % (cmd, status[1]))
    if progress_file:
        utils.update_progress(progress_file, install_grpc.__name__)
    return (True, '\tSuccessfully built and installed GRPC')
# -----------------------------------------------------------------------------

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("-os", "--os-name", required=True,
                        help="To be provided to specify the name of the OS")
    parser.add_argument("-ver", "--os-version", required=True,
                        help="To be provided to specify the version of the OS")
    parser.add_argument("-si", "--sde-install", required=True,
                        help="Path to SDE INSTALL")
    parser.add_argument("-j", "--jobs", required=False,
                        help="To be provided to specify the number of jobs for \
                        parallel builds", default=multiprocessing.cpu_count()-1)

    args, unknown = parser.parse_known_args()
    os_name = args.os_name
    os_version = args.os_version
    jobs = args.jobs
    sde_install = args.sde_install

    status = install_grpc(os_name, os_version, jobs, sde_install)
    if True not in status:
        print ('\tERROR: Failed to install GRPC - %s' % status[-1])
        exit(1)
    else:
        print (status[-1])
