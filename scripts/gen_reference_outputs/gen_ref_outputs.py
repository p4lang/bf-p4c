#! /usr/bin/env python

import os
import sys
import config
from runner import RunCmd

def writeblock_to_file(filename, fileblock):
    with open(filename, 'w') as fwrite:
        if fileblock and len(fileblock) > 0:
            fwrite.write(fileblock)

def get_test_list():
    try:
        with open(config.TEST_FILE, 'r') as fr:
            return fr.read().split('\n')
    except Exception as e:
        print e
        sys.exit(1)

# From the tests.csv file, extract the testname and options
def parse_test(test):
    mTest = config.Test()
    test_contents = test.split(',')
    mTest.path = os.path.dirname(test_contents[0])
    mTest.name = os.path.basename(test_contents[0]).split('.p4')[0]
    if len(test_contents) > 1:
        mTest.opts = test_contents[1]
        if len(test_contents) > 2:
            mTest.timeout = int(test_contents[2])
    return mTest

def prep_test_line(test, p4c):
    mTest = parse_test(test)
    # Add compiler options
    test_line = "\t'" + mTest.name + "': ([" + ', '.join(p4c.args)
    if len(p4c.args) > 0:
        test_line += ', '
    # Add test specific compiler options
    if len(mTest.opts) > 0:
        test_line += mTest.opts + ', '
    # Add filename and output directory 
    extra_args = ['"' + os.path.join(mTest.path, mTest.name + '.p4') + '"', \
        '"-o"', \
        '"' + os.path.join(config.REF_OUTPUTS_DIR, mTest.name, p4c.name) + '"']
    test_line += ', '.join(extra_args) + '], None),\n'
    p4c.testmatrix += test_line
    return p4c

def prep_test_matrix():
    mGlass = config.Glass()
    mP4C = config.P4C()

    # For each test case, prepare a test line in the test matrix
    test_list = get_test_list()
    for test in test_list:
        if len(test) > 0 and '# ' not in test:
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
    print 'Test Summary:\n' + rc.out + '\n'
    print 'Test Errors:\n' + rc.err + '\n'
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