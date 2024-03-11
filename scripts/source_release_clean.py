#!/usr/bin/env python3

#
# Clean the source code prior to open-sourcing/publicly releasing
#

import argparse
import os
import subprocess
import sys

# Top-level source dirs
SRC_DIRS=['bf-asm', 'bf-p4c']

parser = argparse.ArgumentParser(
        description='Clean the source prior to public release')
parser.add_argument('-r', '--root',
                    help='Root directory of the compile source tree')
args = parser.parse_args()

# This script must either be invoked from the top-level directory or with a
# root parameter
if args.root:
    os.chdir(args.root)

# Check for the presence of bf-asm and bf-p4c directorys
subdirs_present = all([os.path.exists(x) for x in SRC_DIRS])

#if not os.path.exists('bf-asm') or not os.path.exists('bf-p4c'):
if not subdirs_present:
    print("Error: '{}' does not appear to be the source tree top-level "
          "directory. Expecting to find subdirectories: "
          "{}.".format(os.getcwd(), SRC_DIRS), file=sys.stderr)
    sys.exit(1)

# Set up paths
CPPP = os.getcwd() + '/scripts/_deps/cppp/cppp'


# =======================================================
# Remove source code corresponding to unreleased hardware
# =======================================================

UNRELEASED_MACROS=['HAVE_CLOUDBREAK', 'HAVE_FLATROCK']

CPPP_CMD_BASE=[CPPP]
CPPP_CMD_BASE[1:] = ['-U' + x for x in UNRELEASED_MACROS]
print(CPPP_CMD_BASE)

def run_cppp(src_dir):
    '''
    Run cppp (c partial preprocessor) on all files in a directory

    Recursively call run_cppp on all subdirectories
    '''
    print("Running cppp on:", src_dir)
    for file in os.listdir(src_dir):
        path = os.path.join(src_dir, file)
        if os.path.isdir(path):
            run_cppp(path)
        elif file.endswith(".c") or file.endswith(".cpp") or file.endswith(".h"):
            tmp_path = path + ".new"
            CPPP_CMD = CPPP_CMD_BASE + [path, tmp_path]
            subprocess.run(CPPP_CMD)
            os.rename(tmp_path, path)

for src_dir in SRC_DIRS:
    run_cppp(src_dir)
