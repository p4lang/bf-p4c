# Copyright (c) 2015-2017 Barefoot Networks, Inc.

# All Rights Reserved.

# NOTICE: All information contained herein is, and remains the property of
# Barefoot Networks, Inc. and its suppliers, if any. The intellectual and
# technical concepts contained herein are proprietary to Barefoot Networks, Inc.
# and its suppliers and may be covered by U.S. and Foreign Patents, patents in
# process, and are protected by trade secret or copyright law. Dissemination of
# this information or reproduction of this material is strictly forbidden unless
# prior written permission is obtained from Barefoot Networks, Inc.

# No warranty, explicit or implicit is provided, unless granted under a written
# agreement with Barefoot Networks, Inc.
#
# -*- Python -*-

import os
import os.path
import sys
import p4c_src.bfn_version as p4c_version
from p4c_src.util import find_file

# Search the environment for assets
if os.environ['P4C_BUILD_TYPE'] == "DEVELOPER":
    walle = find_file('bf-asm', 'walle/walle')
    bfas = find_file('bf-asm', 'bfas')
    bflink = find_file('bf-asm', 'bflink')
else:
    walle = find_file(os.environ['P4C_BIN_DIR'], 'walle')
    bfas = find_file(os.environ['P4C_BIN_DIR'], 'bfas')
    bflink = find_file(os.environ['P4C_BIN_DIR'], 'bflink')

def get_assembler():
    return bfas

def get_linker():
    return bflink

def config_preprocessor(target, targetDefine, basepath, source_fullname):
    target.add_command_option('preprocessor', "-E -x c")
    target.add_command_option('preprocessor', "-D" + targetDefine)
    target.add_command_option('preprocessor', p4c_version.macro_defs)
    if basepath is not None:
        target.add_command_option('preprocessor', "-o")
        target.add_command_option('preprocessor', "{}.p4i".format(basepath))
        target.add_command_option('preprocessor', source_fullname)

def config_compiler(target, triplet, targetDefine, basepath):
    target.add_command_option('compiler', "--nocpp")
    target.add_command_option('compiler', "--target " + triplet)
    target.add_command_option('compiler', "-D" + targetDefine)
    target.add_command_option('compiler', p4c_version.macro_defs)
    if basepath is not None:
        target.add_command_option('compiler', "-o")
        target.add_command_option('compiler', "{}.bfa".format(basepath))
        target.add_command_option('compiler', "{}.p4i".format(basepath))

def config_assembler(target, targetName, basepath, output_dir):
    if basepath is not None:
        target.add_command_option('assembler', "--target " + targetName)
        if (os.environ['P4C_BUILD_TYPE'] == "DEVELOPER"):
            target.add_command_option('assembler',
                                      "-vvvvl {}/bfas.config.log".format(output_dir))
        target.add_command_option('assembler', "-o {}".format(output_dir))
        target.add_command_option('assembler', "{}.bfa".format(basepath))

def config_linker(target, targetName, basename, output_dir):
    target.add_command_option('linker', "--walle " + walle)
    target.add_command_option('linker', "--target " + targetName)
    if basename is not None:
        target.add_command_option('linker', "-o {}/{}.bin".format(output_dir, targetName))
        target.add_command_option('linker', "{}/*.cfg.json".format(output_dir))
        target.add_command_option('linker', "-b {}".format(basename))
