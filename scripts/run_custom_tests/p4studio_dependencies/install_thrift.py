#!/usr/bin/env python

import os
import sys
import datetime
import yaml
import argparse
import multiprocessing

python_v = (sys.version_info)

curr_dir = os.path.dirname(os.path.abspath(__file__))

import dependencies
import utils


# -----------------------------------------------------------------------------


def install_thrift(os_name,
                   os_version,
                   keyword,
                   jobs,
                   logger=None,
                   log_file=None,
                   resume_build=False,
                   progress_file=None,
                   sde_install='/usr/local'):
    curr_date = datetime.date.today().strftime('%y%m%d')
    curr_time = datetime.datetime.now().strftime('%H%M%S')
    if log_file is None:
        log_file = '%s/thrift_%s_%s.log' % (curr_dir, curr_date, curr_time)

    if resume_build:
        status = utils.check_progress(progress_file, install_thrift.__name__)
        if status:
            return (True, '\t - Skipping installation of Thrift ...')

    # Get thrift source data from dependencies.yaml
    dp = dependencies.Dependencies('%s/dependencies.yaml' % curr_dir)
    defaults = dp.get_defaults()
    os_defaults = dp.get_defaults(os_name)
    os_deps = dp.get_os_dependencies(os_name)
    version_deps = os_deps.get(float(os_version))

    line = '\t - Building thrift ... '
    if logger is not None:
        logger.info(line)
    else:
        print ('\t - Building thrift ... ')
    utils.write_to_log(log_file, line)

    thr_data = defaults['source_packages']['thrift']
    thr_ver = None
    if thr_data.get('version') is not None:
        thr_ver = thr_data['version']
    if thr_ver is None and os_defaults.get('source_packages') is not None:
        os_thr_data = os_defaults['source_packages'].get('thrift')
        if os_thr_data is not None:
            thr_ver = os_thr_data.get('version')
    if thr_ver is None and version_deps.get('source_packages') is not None:
        ver_thr_data = version_deps['source_packages'].get('thrift')
        if ver_thr_data is not None:
            thr_ver = ver_thr_data.get('version')

    if os.path.exists('%s/thrift_pkgs/thrift' % curr_dir):
        os.makedirs('%s/thrift_pkgs/thrift.old-%s-%s'
                    % (curr_dir, curr_date, curr_time))
        os.system('mv %s/thrift_pkgs/thrift \
                  %s/thrift_pkgs/thrift.old-%s-%s'
                  % (curr_dir, curr_dir, curr_date, curr_time))
	# Recursively change permissions of thrift directory
        cmd = 'chmod -R a+rwx %s/thrift_pkgs/thrift' % (curr_dir)
        if logger is not None:
            line = '\t\tCOMMAND: [%s]' % cmd
            logger.info(line);
            utils.write_to_log(log_file, line)
        else:
            print('\t\tCOMMAND: [%s]' % cmd)
        status = utils.exec_cmd(cmd, log_file)

    # Extract Thrift
    os.makedirs('%s/thrift_pkgs/thrift' % curr_dir)
    os.chdir('%s/thrift_pkgs/thrift' % curr_dir)
    cmds = ['%s %s/%s/thrift-%s.tar.gz -O thrift-%s.tar.gz' \
            % (thr_data['mode'], thr_data['url'], thr_ver, thr_ver, thr_ver),
            'tar xvzf thrift-%s.tar.gz -C %s/thrift_pkgs/thrift' \
            % (thr_ver, curr_dir)]

    for cmd in cmds:
        line = '\t\tCOMMAND: [%s]' % cmd
        if logger is not None:
            logger.info(line)
        else:
            print ('\t\tCOMMAND: [%s]' % cmd)
        utils.write_to_log(log_file, line)
        status = utils.exec_cmd(cmd, log_file)
        if status[2] != 0:
            return (False, 'Extraction of thrift failed, command - ' + \
                           '%s, error - %s' % (cmd, status[1]))

    # Build Thrift
    if python_v.major == 2: 
        os.chdir('%s/thrift_pkgs/thrift/thrift-%s' % (curr_dir, thr_ver))
        cmds = ['%s/thrift_pkgs/thrift/thrift-%s/configure \
                PY_PREFIX=%s %s --enable-tests=no --prefix=%s --with-boost=%s' \
                % (curr_dir, thr_ver, sde_install, thr_data['flags'], sde_install, sde_install),
                'make -j%s' % jobs,
                'make install',
                'sudo ldconfig',
                'sudo %s -y remove python-thrift' % keyword,
                'sudo -E pip install thrift==%s' % thr_ver]

    if python_v.major == 3:
        if "{}:{}".format(os_name, os_version).lower() in {'ubuntu:20.04', 'debian:11'}:
            python_thrift_package = 'python3-thrift'
        else:
            python_thrift_package = 'python-thrift'

        os.chdir('%s/thrift_pkgs/thrift/thrift-%s' % (curr_dir, thr_ver))
        cmds = ['%s/thrift_pkgs/thrift/thrift-%s/configure \
                PY_PREFIX=%s %s --enable-tests=no --prefix=%s --with-boost=%s' \
                % (curr_dir, thr_ver, sde_install, thr_data['flags'], sde_install, sde_install),
                'make -j%s' % jobs,
                'make install',
                'sudo ldconfig',
                'sudo %s -y remove %s' % (keyword, python_thrift_package),
                'sudo -E python3 -m  pip install thrift==%s' % thr_ver]
		
    for cmd in cmds:
        line = '\t\tCOMMAND: [%s]' % cmd
        if logger is not None:
            logger.info(line)
        else:
            print ('\t\tCOMMAND: [%s]' % cmd)
        utils.write_to_log(log_file, line)
        status = utils.exec_cmd(cmd, log_file)
        if status[2] != 0:
            return (False, 'Building thrift failed with command - ' + \
                           '%s, error - %s' % (cmd, status[1]))
    # Recursively change permissions of thrift directory
    cmd = 'sudo chmod -R a+rwx %s/thrift_pkgs/thrift/thrift-%s' % (curr_dir, thr_ver)
    if logger is not None:
        line = '\t\tCOMMAND: [%s]' % cmd
        logger.info(line);
        utils.write_to_log(log_file, line)
    else:
        print('\t\tCOMMAND: [%s]' % cmd)
    status = utils.exec_cmd(cmd, log_file)


    if progress_file:
        utils.update_progress(progress_file, install_thrift.__name__)
    return (True, '\tSuccessfully built and installed thrift')

# -----------------------------------------------------------------------------

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("-os", "--os-name", required=True,
                        help="To be provided to specify the name of the OS")
    parser.add_argument("-ver", "--os-version", required=True,
                        help="To be provided to specify the version of the OS")
    parser.add_argument("-k", "--keyword", required=True,
                        help="Keyword apt-get or yum needs to be provided")
    parser.add_argument("-j", "--jobs", required=False,
                        help="To be provided to specify the number of jobs for \
                        parallel builds", default=multiprocessing.cpu_count()-1)
    parser.add_argument("-si", "--sde-install", required=True,
                        help="Path to SDE INSTALL")

    args, unknown = parser.parse_known_args()
    os_name = args.os_name
    os_version = args.os_version
    keyword = args.keyword
    jobs = args.jobs

    status = install_thrift(os_name, os_version, keyword, jobs, sde_install=args.sde_install)
    if True not in status:
        print ('\tERROR: Failed to install thrift - %s' % status[-1])
        exit(1)
    else:
        print (status[-1])
