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
from p4c_src.driver import BackendDriver

# Search the environment for assets
if os.environ['P4C_BUILD_TYPE'] == "DEVELOPER":
    walle = find_file('bf-asm', 'walle/walle')
    bfas = find_file('bf-asm', 'bfas')
    bflink = find_file('bf-asm', 'bflink')
else:
    walle = find_file(os.environ['P4C_BIN_DIR'], 'walle')
    bfas = find_file(os.environ['P4C_BIN_DIR'], 'bfas')
    bflink = find_file(os.environ['P4C_BIN_DIR'], 'bflink')

class BarefootBackend(BackendDriver):
    def __init__(self, target, argParser):
        BackendDriver.__init__(self, target, argParser)
        # commands
        self.add_command('preprocessor', 'cc')
        self.add_command('compiler',
                         os.path.join(os.environ['P4C_BIN_DIR'], 'p4c-barefoot'))
        self.add_command('assembler', bfas)
        self.add_command('linker', bflink)

        # order of commands
        self.enable_commands(['preprocessor', 'compiler', 'assembler', 'linker'])

        # additional options
        self.add_command_line_options()

    def add_command_line_options(self):
        # BackendDriver.add_command_line_options(self)
        self._argGroup = self._argParser.add_argument_group("Barefoot Networks specific options")
        self._argGroup.add_argument("-s", dest="run_post_compiler",
                                    help="Only run assembler and linker",
                                    action="store_true", default=False)

    def config_preprocessor(self, targetDefine):
        self.add_command_option('preprocessor', "-E -x c")
        self.add_command_option('preprocessor', "-D" + targetDefine)
        self.add_command_option('preprocessor', p4c_version.macro_defs)

    def config_compiler(self, triplet, targetDefine):
        self.add_command_option('compiler', "--nocpp")
        self.add_command_option('compiler', "--target " + triplet)
        self.add_command_option('compiler', "-D" + targetDefine)
        self.add_command_option('compiler', p4c_version.macro_defs)

    def config_assembler(self, targetName):
        self.add_command_option('assembler', "--target " + targetName)

    def config_linker(self, targetName):
        self.add_command_option('linker', "--walle " + walle)
        self.add_command_option('linker', "--target " + targetName)
        self._linkerTargetName = targetName


    def process_command_line_options(self, opts):
        BackendDriver.process_command_line_options(self, opts)

        # process the options related to source file
        output_dir = self._output_directory
        basepath = "{}/{}".format(output_dir, self._source_basename)

        self.add_command_option('preprocessor', "-o")
        self.add_command_option('preprocessor', "{}.p4i".format(basepath))
        self.add_command_option('preprocessor', self._source_filename)

        self.add_command_option('compiler', "-o")
        self.add_command_option('compiler', "{}.bfa".format(basepath))
        self.add_command_option('compiler', "{}.p4i".format(basepath))
        # cleanup after compiler
        self._postCmds['compiler'] = []
        self._postCmds['compiler'].append(["rm -f {}.p4i".format(basepath)])

        if (os.environ['P4C_BUILD_TYPE'] == "DEVELOPER"):
            self.add_command_option('assembler',
                                    "-vvvvl {}/bfas.config.log".format(output_dir))
        self.add_command_option('assembler', "-o {}".format(output_dir))
        self.add_command_option('assembler', "{}.bfa".format(basepath))
        # cleanup after assembler
        if not opts.debug_info:
            self._postCmds['assembler'] = []
            self._postCmds['assembler'].append(["rm -f {}.bfa".format(basepath)])

        self.add_command_option('linker', "-o {}/{}.bin".format(output_dir, self._linkerTargetName))
        self.add_command_option('linker', "{}/*.cfg.json".format(output_dir))
        self.add_command_option('linker', "-b {}".format(self._source_basename))

        src_filename, src_extension = os.path.splitext(self._source_filename)
        # local options
        if opts.run_post_compiler or src_extension == '.bfa':
            self.enable_commands(['assembler', 'linker'])
