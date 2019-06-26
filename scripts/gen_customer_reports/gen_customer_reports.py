#!/usr/bin/env python3

import os
import sys
import argparse
import config
import subprocess
import shutil
from runner import RunCmd
from process_logs import ProcessLog
from datetime import datetime

# Utility functions
def writeblock_to_file(filename, fileblock):
    with open(filename, 'w') as fwrite:
        if fileblock:
            for line in iter(fileblock.readline, b''):
                fwrite.write(line.decode('utf-8'))

def display_log(filename):
    with open(filename, 'r') as fr:
        for line in fr.readlines():
            print(line.strip())

def copy_report(report):
    dest_path = os.path.join(config.MNT_DIR, os.path.basename(report))
    shutil.copy2(report, dest_path) 

# Run ctest
def run_ctest(target, test_suite):
    ctest_target_args = '"^' + target + '/.*' + test_suite + '"'
    ctest_cmd = 'ctest -V -R ' + ctest_target_args
    os.chdir(config.CTEST_PATH)
    print ("Running", ctest_cmd)
    rc = RunCmd(ctest_cmd, config.CTEST_DRIVER_TIMEOUT)
    err_file = os.path.join(config.REF_OUTPUTS_DIR, target + '_' + test_suite + '_error.log')
    out_file = os.path.join(config.REF_OUTPUTS_DIR, target + '_' + test_suite + '_out.log')
    writeblock_to_file(err_file, rc.err)
    writeblock_to_file(out_file, rc.out)

# Process logs
def process_logs(target, test_suite, log_time):
    out_file = os.path.join(config.REF_OUTPUTS_DIR, target + '_' + test_suite + '_out.log')
    report_name = target.capitalize() + '_' + test_suite.capitalize() + '_' + log_time + '.xlsx'
    report = os.path.join(config.REPORTS_DIR, report_name)
    report_tab = target + '_' + test_suite
    print ("Processing", out_file)
    ProcessLog(out_file, report, report_tab)
    print ("Report at", report) 
    copy_report(report)

# Run the ctest for a given test suite (reg ex) and generate excel report
def main():
    # Parse command line arguments
    parser = argparse.ArgumentParser(
        description='Generate customer test reports.')
    parser.add_argument('--target', type=str,
        default=config.TARGET,
        help = 'Target (tofino/tofino2)')
    parser.add_argument('--test_suite', type=str,
        default=config.TEST_SUITE,
        help = 'Customer test suite name')

    args = parser.parse_args()

    print ('='*120)
    ts = datetime.now().strftime('%Y-%m-%d_%H-%M-%S')
    print (ts, ': Running ctest')
    run_ctest(args.target, args.test_suite)
    process_logs(args.target, args.test_suite, ts)
    ts = datetime.now().strftime('%Y-%m-%d_%H-%M-%S')
    print (ts, ': Compileted ctest')
    print ('='*120)

if __name__ == "__main__":
    main()
