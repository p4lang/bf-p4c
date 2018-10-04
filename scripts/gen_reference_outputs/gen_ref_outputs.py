#! /usr/bin/env python

import os
import sys
import csv
import config
from runner import RunCmd

def writeblock_to_file(filename, fileblock):
    with open(filename, 'w') as fwrite:
        if fileblock and len(fileblock) > 0:
            fwrite.write(fileblock)

def get_test_list():
    try:
        tests = []
        # p4,p4_path,include_path,p4_opts,target,language,arch,skip_opt
        field_names=['p4', 'p4_path', 'include_path', 'p4_opts', 'target', 'language', 'arch', 'skip_opt']
        with open('tests.csv', 'rb') as csvfile:
            test_reader = csv.DictReader(csvfile, fieldnames=field_names)
            for row in test_reader:
                if '# ' not in row['p4']:
                    mTest = config.Test()
                    mTest.p4 = row['p4']
                    mTest.p4_path = row['p4_path']
                    mTest.include_path = row['include_path']
                    mTest.p4_opts = row['p4_opts']
                    mTest.target = row['target']
                    mTest.language = row['language']
                    mTest.arch = row['arch']
                    mTest.skip_opt = row['skip_opt']
                    tests.append(mTest)
        return tests
    except Exception as e:
        print e
        sys.exit(1)

def prep_test_line(mTest, p4c):
    # Check target and arch - generate test_line for Glass only for tofino, p4-14, v1model
    if p4c.name is 'Glass':
        if 'tofino2' in mTest.target or 'p4-16' in mTest.language or 'tna' in mTest.arch:
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
        '"' + os.path.join(config.REF_OUTPUTS_DIR, mTest.p4, p4c.name, mTest.p4) + '"']
    test_line += ', '.join(extra_args) + '], None),\n'
    p4c.testmatrix += test_line
    return p4c

def prep_test_matrix():
    mGlass = config.Glass()
    mP4C = config.P4C()

    # For each test case, prepare a test line in the test matrix
    test_dict = get_test_list()
    for test in test_dict:
        if len(test.p4) > 0:
            for p4c in [mGlass, mP4C]:
                p4c = prep_test_line(test, p4c)

    mGlass.testmatrix += '}\n'
    mP4C.testmatrix += '}\n'

    writeblock_to_file(config.P4C_TEST_MATRIX, mP4C.testmatrix)
    writeblock_to_file(config.GLASS_TEST_MATRIX, mGlass.testmatrix)

def run_test_matrix(p4c, test_cmd):
    rc = RunCmd(test_cmd, config.TEST_DRIVER_TIMEOUT)
    writeblock_to_file(os.path.join(config.REF_OUTPUTS_DIR, \
        p4c + '_test_error.log'), rc.err)
    writeblock_to_file(os.path.join(config.REF_OUTPUTS_DIR, \
        p4c + '_test_out.log'), rc.out)
    print 'Test Summary:\n'
    if rc.out is not None:
        print rc.out + '\n'
    print 'Test Errors:\n'
    if rc.err is not None:
        print rc.err + '\n'
    return rc.return_code

# Generate and run the test matrix for Glass and P4C compilation
# and context.json validation
def main():
    prep_test_matrix()
    print '='*120
    print 'Running Glass tests: '
    print '='*120
    print 'Completed Glass tests: ' + str(run_test_matrix('Glass', \
        config.GLASS_TEST_CMD))
    print '='*120 + '\n\n'
    print '='*120
    print 'Running P4C tests: '
    print '='*120
    print 'Completed P4C tests: ' + str(run_test_matrix('P4C', \
        config.P4C_TEST_CMD))
    print '='*120

if __name__ == "__main__":
    main()
