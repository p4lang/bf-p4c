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
    bfas = find_file('bf-asm', 'bfas-runner.py')
else:
    bfas = find_file(os.environ['P4C_BIN_DIR'], 'bfas-runner.py')

bfrt_gen = find_file(os.environ['P4C_BIN_DIR'], 'p4c-gen-bfrt-schema')

class BarefootBackend(BackendDriver):
    def __init__(self, target, arch, argParser):
        BackendDriver.__init__(self, target, arch, argParser)
        # commands
        self.add_command('preprocessor', 'cc')
        self.add_command('compiler',
                         os.path.join(os.environ['P4C_BIN_DIR'], 'p4c-barefoot'))
        self.add_command('assembler', bfas)
        self.add_command('bf-rt-verifier', bfrt_gen)

        if os.environ['P4C_BUILD_TYPE'] == "DEVELOPER":
            self.add_command(
                'verifier',
                os.path.join(os.environ['P4C_BIN_DIR'],
                             '../../scripts/validate_context_json'))
            self.add_command(
                'manifest-verifier',
                os.path.join(os.environ['P4C_BIN_DIR'],
                             '../../scripts/validate_manifest'))

        self.add_command('archiver', 'tar')

        # order of commands
        self.enable_commands(['preprocessor', 'compiler', 'assembler'])

        # additional options
        self.add_command_line_options()

    def add_command_line_options(self):
        # BackendDriver.add_command_line_options(self)
        self._argGroup = self._argParser.add_argument_group("Barefoot Networks specific options")
        self._argGroup.add_argument("--create-graphs",
                                    help="Create parse and table flow graphs",
                                    action="store_true", default=False)
        self._argGroup.add_argument("--display-power-budget",
                                    help="Display MAU power summary after compilation.",
                                    action="store_true", default=False)
        self._argGroup.add_argument("--no-link", dest="skip_linker",
                                    help="Run up to linker",
                                    action="store_true", default=False)
        self._argGroup.add_argument("-s", dest="run_post_compiler",
                                    help="Only run assembler",
                                    action="store_true", default=False)
        self._argGroup.add_argument("--archive",
                                    help="Archive all outputs into a single tar.bz2 file",
                                    action="store_true", default=False)
        self._argGroup.add_argument("--bf-rt-schema", action="store",
                                    help="Generate and write BF-RT JSON schema  to the specified file")
        self._argGroup.add_argument("--backward-compatible",
                                    action="store_true", default=False,
                                    help="Set compiler to be backward compatible with p4c-tofino")

        if os.environ['P4C_BUILD_TYPE'] == "DEVELOPER":
            self._argGroup.add_argument("--validate-output", action="store_true", default=False,
                                        help="run context.json validation")
            self._argGroup.add_argument("--validate-manifest", action="store_true", default=False,
                                        help="run manifest validation")

    def config_preprocessor(self, targetDefine):
        self.add_command_option('preprocessor', "-E -x c")
        self.add_command_option('preprocessor', "-D" + targetDefine)
        self.add_command_option('preprocessor', p4c_version.macro_defs)

    def config_compiler(self, target, arch, targetDefine):
        self.add_command_option('compiler', "--nocpp")
        self.add_command_option('compiler', "--target " + target)
        self.add_command_option('compiler', "--arch " + arch)
        self.add_command_option('compiler', "-D" + targetDefine)
        self.add_command_option('compiler', p4c_version.macro_defs)

    def config_assembler(self, targetName):
        self.add_command_option('assembler', "--target " + targetName)

    def process_command_line_options(self, opts):
        BackendDriver.process_command_line_options(self, opts)

        # process the options related to source file
        output_dir = self._output_directory
        basepath = "{}/{}".format(output_dir, self._source_basename)

        self.add_command_option('preprocessor', "-o")
        self.add_command_option('preprocessor', "{}.p4i".format(basepath))
        self.add_command_option('preprocessor', self._source_filename)

        self.add_command_option('compiler', "-o")
        self.add_command_option('compiler', "{}".format(output_dir))
        self.add_command_option('compiler', "{}.p4i".format(basepath))
        # cleanup after compiler
        self._postCmds['compiler'] = []
        self._postCmds['compiler'].append(["rm -f {}.p4i".format(basepath)])

        self.add_command_option('assembler', "--manifest {}/manifest.json".format(output_dir))
        if os.environ['P4C_BUILD_TYPE'] == "DEVELOPER":
            self.add_command_option('assembler',
                                    "-vvvvl {}/bfas.config.log".format(output_dir))

        # cleanup after assembler
        self._postCmds['assembler'] = []
        if not opts.debug_info:
            self._postCmds['assembler'].append(["rm -f {}.bfa".format(basepath)])

        src_filename, src_extension = os.path.splitext(self._source_filename)
        # local options
        if opts.run_post_compiler or src_extension == '.bfa':
            self.enable_commands(['assembler'])
        if opts.skip_linker:
            self.add_command_option('assembler', "--no-bin")

        if opts.create_graphs or opts.archive:
            self.add_command_option('compiler', '--create-graphs')

        if opts.backward_compatible:
            self.add_command_option('compiler', '--backward-compatible')

        if opts.display_power_budget:
            self.add_command_option('compiler', '--display-power-budget')

        if opts.bf_rt_schema is not None:
            self.add_command_option('compiler', '--bf-rt-schema {}'.format(opts.bf_rt_schema))

            self.add_command_option('bf-rt-verifier', opts.bf_rt_schema)
            self._commandsEnabled.append('bf-rt-verifier')

        # Developer only options
        if os.environ['P4C_BUILD_TYPE'] == "DEVELOPER":
            if opts.validate_output:
                self.add_command_option('verifier', "{}/context.json".format(output_dir))
                self._commandsEnabled.append('verifier')
            if opts.validate_manifest:
                self.add_command_option('manifest-verifier', "{}/manifest.json".format(output_dir))
                self._commandsEnabled.append('manifest-verifier')

        # if we need to generate an archive, should be the last command
        if opts.archive:
            root_dir = os.path.dirname(output_dir)
            if root_dir == "": root_dir = "."
            program_name = os.path.basename(basepath)
            program_dir = os.path.basename(output_dir)
            if program_dir != ".":
                self.add_command_option('archiver',
                                        "-cf {}/{}.tar.bz2 -j -C {} {}".format(root_dir,
                                        program_name, root_dir, program_dir))
                self._commandsEnabled.append('archiver')
            else:
                print >> sys.stderr, "Please specify an output directory (using -o) to generate an archive"
