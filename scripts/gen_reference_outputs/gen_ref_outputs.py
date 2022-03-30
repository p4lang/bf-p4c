#! /usr/bin/env python3

import os
import sys
import csv
import argparse
import shutil
import config
import database
sys.path.append("..")
from runner import RunCmd
from datetime import datetime

def writeblock_to_file(filename, fileblock):
    with open(filename, 'w') as fwrite:
        if fileblock and len(fileblock) > 0:
            fwrite.write(fileblock)

def get_test_list(tests_csv, out_dir, ts):
    errorCount = 0
    try:
        tests = []
        # p4,p4_path,include_path,p4_opts,target,language,arch,skip_opt
        field_names=['p4', 'p4_path', 'include_path', 'p4_opts', 'target', 'language', 'arch', 'skip_opt']
        with open(tests_csv, 'r') as csvfile:
            test_reader = csv.DictReader(csvfile, fieldnames=field_names)
            for row in test_reader:
                if '# ' not in row['p4']:
                    mTest = config.Test()
                    mTest.p4 = row['p4']
                    mTest.p4_path = os.path.join(config.BF_P4C_PATH, row['p4_path'])
                    if not os.path.exists(mTest.p4_path):
                        print("Can't find file: " + mTest.p4_path)
                        errorCount += 1
                    if len(row['include_path']) > 0:
                        mTest.include_path = os.path.join(config.BF_P4C_PATH, row['include_path'])
                    mTest.p4_opts = row['p4_opts']
                    mTest.target = row['target']
                    mTest.language = row['language']
                    mTest.arch = row['arch']
                    mTest.skip_opt = row['skip_opt']
                    mTest.timestamp = ts
                    mTest.out_path =  os.path.join(out_dir, mTest.p4, mTest.timestamp)
                    tests.append(mTest)
        if errorCount > 0:
            raise Exception("Fatal error(s) encountered, exiting!")
        return tests
    except Exception as e:
        print(e)
        sys.exit(1)

def prep_test_line(mTest, p4c):
    # Check target and arch - generate test_line for Glass only for tofino, p4-14, v1model
    if p4c.name is 'Glass':
        if 'tofino2' in mTest.target or 'tofino3' in mTest.target or 'p4-16' in mTest.language or 'tna' in mTest.arch:
            return p4c
    # Check skip_opt - generate test_line only if not skipped
    if mTest.skip_opt and p4c.name in mTest.skip_opt:
        return p4c
    # Add compiler options
    test_line = "\t'" + mTest.p4 + "': ([" + ', '.join(p4c.args)
    if len(p4c.args) > 0:
        test_line += ', '
    # Add test specific compiler options
    if len(mTest.include_path) > 0:
        test_line += '"-I ' + mTest.include_path + '", '
    if len(mTest.p4_opts) > 0:
        test_line += '"' + mTest.p4_opts + '", '
    # Add P4C specific compiler options
    if p4c.name is not 'Glass':
        test_line += '"--target ' + mTest.target + '", '
        test_line += '"--std ' + mTest.language + '", '
        test_line += '"--arch ' + mTest.arch + '", '
    # Add filename and output directory
    extra_args = ['"' + os.path.join(mTest.p4_path) + '"', \
        '"-o"', \
        '"' + os.path.join(mTest.out_path, p4c.name) + '"']
    test_line += ', '.join(extra_args) + '], None, None),\n'
    p4c.testmatrix += test_line
    return p4c

def prep_test_matrix(tests_csv, out_dir, ts):
    mGlass = config.Glass()
    mP4C = config.P4C()

    # For each test case, prepare a test line in the test matrix
    test_dict = get_test_list(tests_csv, out_dir, ts)
    for test in test_dict:
        if len(test.p4) > 0:
            for p4c in [mGlass, mP4C]:
                p4c = prep_test_line(test, p4c)

    mGlass.testmatrix += '}\n'
    mP4C.testmatrix += '}\n'

    writeblock_to_file(config.P4C_TEST_MATRIX, mP4C.testmatrix)
    writeblock_to_file(config.GLASS_TEST_MATRIX, mGlass.testmatrix)
    return test_dict

def run_test_matrix(p4c, test_cmd):
    failed = []
    rc = RunCmd(test_cmd, config.TEST_DRIVER_TIMEOUT)
    writeblock_to_file(os.path.join(config.REF_OUTPUTS_DIR, \
        p4c + '_test_error.log'), rc.err.decode('utf-8'))
    writeblock_to_file(os.path.join(config.REF_OUTPUTS_DIR, \
        p4c + '_test_out.log'), rc.out.decode('utf-8'))
    print('Test Summary:\n')
    if rc.out is not None:
        lines = rc.out.decode('utf-8').split('\n')
        for line in lines[-10:]:
            print(line + '\n')
            failed.append(line.strip())
    print('Test Errors:\n')
    if rc.err is not None:
        print(rc.err.decode('utf-8') + '\n')
    return rc.return_code, failed

def process_metrics(tests, metrics_db, metrics_outdir, ts, update, failed):
    final_result = 0
    db_curr = database.copy_metrics(tests, metrics_outdir, ts)
    db_master = metrics_db.extract_metrics()
    results = None
    if update:
        print ('Updating metrics in database')
        results = database.test_and_update_metrics(metrics_db, db_curr, db_master)
    else:
        print ('Analyzing metrics in the current run')
        results = database.test_and_report_metrics(db_curr, db_master)
    for test, metrics_result in results.items():
        test_result = metrics_result
        if test in failed:
            test_result = 'FAIL'
        if test_result is 'FAIL':
            final_result -= 1
        print(test, test_result)
    return final_result

def find_file(path, filename):
    for root, dirs, files in os.walk(path):
        if filename in files:
            return True
    return False

def remove_empty_directories(tests):
    mGlass = config.Glass()
    mP4C = config.P4C()
    for mTest in tests:
        for p4c in [mGlass, mP4C]:
            if mTest.skip_opt and p4c.name in mTest.skip_opt:
                continue
            # Check for manifest.json if out_dir exists:
            out_dir = os.path.join(mTest.out_path, p4c.name)
            if os.path.isdir(out_dir):
                is_p4i_outputs = find_file(out_dir, 'manifest.json')
                if not is_p4i_outputs:
                    print('Compilation not successful, removing', out_dir)
                    shutil.rmtree(out_dir)

# Generate and run the test matrix for Glass and P4C compilation
# and context.json validation
def main():
    # Parse command line arguments
    parser = argparse.ArgumentParser(
        description='Generate reference outputs for p4i and metrics.')
    parser.add_argument('--tests_csv', type=str,
        default=config.TEST_FILE,
        help = 'Testcase listing')
    parser.add_argument('--out_dir', type=str,
        default=config.REF_OUTPUTS_DIR,
        help = 'Directory in which to store generated tests and test output.')
    parser.add_argument('--process_metrics', action='store_true',
        help='Process metrics and store the metrics.json generated for the current run with the timestamp')
    parser.add_argument('--update_metrics', action='store_true',
        help='Update metrics to the current database')
    parser.add_argument('--commit_sha', type=str,
        default=config.COMMIT_SHA,
        help = 'COMMIT SHA of the current run')

    args = parser.parse_args()
    if args.process_metrics:
        config.COMMIT_SHA = args.commit_sha

    # Setting timestamp for this run
    ts = datetime.now().strftime('%Y-%m-%d_%H-%M-%S')

    tests = prep_test_matrix(args.tests_csv, args.out_dir, ts)
    print('='*120)
    print('Running Glass tests: ')
    print('='*120)
    glass_res, glass_failed = run_test_matrix('Glass', config.GLASS_TEST_CMD)
    print('Completed Glass tests: ' + str(glass_res))
    print('='*120 + '\n\n')
    print('='*120)
    print('Running P4C tests: ')
    print('='*120)
    p4c_res, p4c_failed = run_test_matrix('P4C', config.P4C_TEST_CMD)
    print('Completed P4C tests: ' + str(p4c_res))
    print('='*120)
    remove_empty_directories(tests)
    if args.process_metrics:
        metrics_db = database.metricstable()
        result = process_metrics(tests, metrics_db, args.out_dir, ts, args.update_metrics, p4c_failed)
        if result < 0:
            sys.exit(1)

if __name__ == "__main__":
    main()
