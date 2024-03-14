#!/usr/bin/env python3

#
# Clean the source code prior to open-sourcing/publicly releasing
#

import argparse
import os
import shutil
import subprocess
import sys

from pathlib import Path

# Top-level source dirs
SRC_DIRS = ['bf-asm', 'bf-p4c']

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

UNRELEASED_MACROS = ['HAVE_CLOUDBREAK', 'HAVE_FLATROCK']

CPPP_CMD_BASE = [CPPP]
CPPP_CMD_BASE[1:] = ['-U' + x for x in UNRELEASED_MACROS]


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
        elif file.endswith(".c") or file.endswith(".cpp") or \
                file.endswith(".h"):
            tmp_path = path + ".new"
            CPPP_CMD = CPPP_CMD_BASE + [path, tmp_path]
            subprocess.run(CPPP_CMD)
            os.rename(tmp_path, path)


def sed_replace(path, src, dst, include_cmake=False):
    '''
    Perform a replace with sed on all .cpp and .h files, and optionally cmake
    files, within path. The src and dst strings are specified as parameters.
    '''
    print("Replacing '{}' with '{}' in {}".format(src, dst, path))
    cmd = "find " + path + " -name '*.cpp' -or -name '*.h' -or -name '*.def'"
    cmd += " -or -name '*.py' -or -name 'SYNTAX.yaml'"
    if include_cmake:
        cmd += " -or -name CMakeLists.txt"
    cmd += " | xargs sed -i 's/" + src + "/" + dst + "/g'"
    subprocess.run([cmd], shell=True)


def sed_delete(path, del_exp, include_cmake=False):
    '''
    Delete with sed on all .cpp and .h files, and optionally cmake files,
    within path. The delete expression is specified as a parameter.
    '''
    print("Deleting '{}' in {}".format(del_exp, path))
    cmd = "find " + path + " -name '*.cpp' -or -name '*.h' -or -name '*.def'"
    cmd += " -or -name '*.py' -or -name 'SYNTAX.yaml'"
    if include_cmake:
        cmd += " -or -name CMakeLists.txt"
    cmd += " | xargs sed -i '/" + del_exp + "/d'"
    subprocess.run([cmd], shell=True)


for src_dir in SRC_DIRS:
    run_cppp(src_dir)

    # Strip out any remaining references to the macros
    #
    # These occur when the macro is references in a comment, typically
    # in #endif /* HAVE_XYZ */
    sed_re = r'\|'.join(UNRELEASED_MACROS)
    sed_replace(src_dir, sed_re, '')


# =======================================================
# Remove directories/files for unreleased targets
# =======================================================

UNRELEASED_TARGETS = [
        'cloudbreak', 'flatrock', 'tofino3', 't5na', 't5na_program_structure'
    ]

for target in UNRELEASED_TARGETS:
    for path in sorted(Path().rglob(target)):
        print("Deleting tree:", path.as_posix())
        shutil.rmtree(path.as_posix())
    for path in sorted(Path().rglob(target + '.*')):
        print("Deleting file:", path.as_posix())
        path.unlink()

EXTRA_DELETES = [
        'bf-p4c/parde/lowered/lower_flatrock.h',
        'bf-p4c/p4include/t3na.p4',
        'bf-p4c/p4include/tofino3_arch.p4',
        'bf-p4c/p4include/tofino3_base.p4',
        'bf-p4c/p4include/tofino3_specs.p4',
        'bf-p4c/p4include/tofino5arch.p4',
        'bf-p4c/p4include/tofino5.p4',
        'bf-p4c/driver/p4c.tofino3.cfg',
        'bf-p4c/driver/p4c.tofino5.cfg',
    ]
for path in EXTRA_DELETES:
    if os.path.exists(path):
        print('Deleting', path)
        os.unlink(path)

# =======================================================
# Rename files
# =======================================================

# Files to rename
RENAMES = {
    "bf-asm/parser-tofino-jbay-cloudbreak.h": "bf-asm/parser-tofino-jbay.h",
    "bf-asm/parser-tofino-jbay-cloudbreak.cpp":
        "bf-asm/parser-tofino-jbay.cpp",
    }

# Per-directory src string substitutions
SRC_SUBSTITUES = {
    "bf-asm": {
        "parser-tofino-jbay-cloudbreak.h": "parser-tofino-jbay.h",
        "parser-tofino-jbay-cloudbreak.cpp": "parser-tofino-jbay.cpp",
        "PARSER_TOFINO_JBAY_CLOUDBREAK_H_": "PARSER_TOFINO_JBAY_H_",
        },
    "bf-p4c": {
        r"\s*\/\/ \(Tofino5\|Flatrock\) specific$": "",
        r"\s*\/\/ TODO for \(Tofino5\|[Ff]latrock\)$": "",
        },
    }

for src, dst in RENAMES.items():
    if os.path.exists(src):
        print('Renaming:', src, '->', dst)
        os.rename(src, dst)

for path, subs in SRC_SUBSTITUES.items():
    for src, dst in subs.items():
        sed_replace(path, src, dst, True)


# =======================================================
# Delete documentation strings
# =======================================================

# Documentation strings to delete
DOC_STRINGS = ['.*\<\(JIRA\|TOF[35]\)-DOC:.*']

for path in SRC_DIRS:
    for del_str in DOC_STRINGS:
        sed_delete(path, del_str)


# =======================================================
# cmake updates
#  - difficult to precisely target correct lines
# =======================================================

print("Cleaning cmake files")
targets = UNRELEASED_TARGETS + [
        'lower_flatrock', 't5na', 't5na_program_structure'
    ]
for target in targets:
    sed_re = r's/.*[ /]' + target + r'\.\(cpp\|h\|def\).*//'
    for src_dir in SRC_DIRS:
        for path in sorted(Path(src_dir).rglob('CMakeLists.txt')):
            print('Processing', path.as_posix())
            subprocess.run(['sed', '-i', sed_re, path.as_posix()])
