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
import json
import re
import p4c_src.bfn_version as p4c_version
from p4c_src.util import find_file, find_bin
from p4c_src.driver import BackendDriver

# Search the environment for assets
if os.environ['P4C_BUILD_TYPE'] == "DEVELOPER":
    bfas = find_file('bf-asm', 'bfas')
else:
    bfas = find_file(os.environ['P4C_BIN_DIR'], 'bfas')

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
            bin_dir = os.path.join(os.environ['P4C_BIN_DIR'], '../../scripts')
            if not os.path.isdir(bin_dir):
                # we are building out of the source directory, so we need to get the source dir
                # from the cmake cache
                src_dir_pattern = re.compile(r'BFN_P4C_SOURCE_DIR:STATIC=(.*)$')
                with open(os.path.join(os.environ['P4C_BIN_DIR'], '../CMakeCache.txt')) as cmake_cache:
                    for line in cmake_cache:
                        res = src_dir_pattern.match(line)
                        if res:
                            src_dir = res.group(1)
                            bin_dir = os.path.join(src_dir, 'scripts')
                            break
                if not os.path.isdir(bin_dir):
                    print >> sys.stderr, "Can not find scripts directory"
                    sys.exit(1)

            self.add_command('verifier', os.path.join(bin_dir, 'validate_context_json'))
            self.add_command('manifest-verifier', os.path.join(bin_dir, 'validate_manifest'))

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
        self.add_command_option('preprocessor', "-E -x assembler-with-cpp")
        self.add_command_option('preprocessor', "-D" + targetDefine)
        self.add_command_option('preprocessor', p4c_version.macro_defs)

    def config_compiler(self, target, arch, targetDefine):
        self.add_command_option('compiler', "--nocpp")
        self.add_command_option('compiler', "--target " + target)
        self.add_command_option('compiler', "--arch " + arch)
        self.add_command_option('compiler', "-D" + targetDefine)
        self.add_command_option('compiler', p4c_version.macro_defs)

    def config_assembler(self, targetName):
        self._targetName = targetName
        self._no_link = False

    def process_command_line_options(self, opts):
        BackendDriver.process_command_line_options(self, opts)

        self.checkVersionTargetArch(opts.language)

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
        if not opts.debug_info:
            self._postCmds['compiler'] = []
            self._postCmds['compiler'].append(["rm -f {}.p4i".format(basepath)])

        # cleanup after assembler
        # self._postCmds['assembler'] = []
        # if not opts.debug_info:
        #     self._postCmds['assembler'].append(["rm -f {}.bfa".format(basepath)])

        src_filename, src_extension = os.path.splitext(self._source_filename)
        # local options
        if opts.run_post_compiler or src_extension == '.bfa':
            self.enable_commands(['assembler'])
        if opts.skip_linker:
            self._no_link = True

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
            # always validate the manifest if opts.validate_manifest:
            self.add_command_option('manifest-verifier', "{}/manifest.json".format(output_dir))
            self._commandsEnabled.append('manifest-verifier')

        # if we need to generate an archive, should be the last command
        if opts.archive:
            self.add_command('archiver', 'tar')
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
                print >> sys.stderr, "Please specify an output directory (using -o) to" + \
                    " generate an archive"

    def parseManifest(self):
        """
        parse the manifest file and return a map of the program pipes
        If dry-run, the manifest does not exist, so we fake one to print at least
        one assembler line if needed.
        """

        manifest_filename = "{}/manifest.json".format(self._output_directory)

        if self._dry_run and not os.path.isfile(manifest_filename):
            print 'parse manifest:', manifest_filename
            self._pipes = { 'pipe': '{}/pipe/context.json'.format(self._output_directory)}
            return 0

        with open(manifest_filename, "rb") as json_file:
            try:
                manifest = json.load(json_file)
            except:
                print >> sys.stderr, "ERROR: Input file '" + manifest_filename + \
                    "' could not be decoded as JSON.\n"
                sys.exit(1)
            if (type(manifest) is not dict or "programs" not in manifest):
                print >> sys.stderr, "ERROR: Input file '" + manifest_filename + \
                    "' does not appear to be valid manifest JSON.\n"
                sys.exit(1)

        self._pipes = {}
        schema_version = manifest['schema_version']
        pipe_name_label = 'pipe_name'
        if schema_version == "1.0.0": pipe_name_label = 'pipe'

        programs = manifest['programs']
        if len(programs) > 1:
            print >> sys.stderr, \
                "{} currently supports a single program".format(self._targetName.title())
            sys.exit(1)
        for prog in programs:
            if (type(prog) is not dict or "contexts" not in prog):
                sys.stderr.write("ERROR: Input file '" + manifest_filename + \
                                 "' does not contain valid program contexts.\n")
                sys.exit(1)
            p4_version=prog["p4_version"]
            for ctxt in prog["contexts"]:
                pipe_name = 'pipe'
                dirname = self._output_directory
                if (p4_version == "p4-16"):
                    pipe_name = ctxt[pipe_name_label]
                    dirname = os.path.join(self._output_directory, pipe_name)
                self._pipes[pipe_name] = dirname

    def runAssembler(self, dirname, unique_table_offset):
        """
        Run an instance of the assembler on the provided directory
        """
        # reset all assembler options to what was passed on cmd line
        # Note that we need to make a copy of the list
        self._commands['assembler'] = list(self._saved_assembler_params)
        # lookup the directory name. For P4-16, it is the output + pipe_name
        if os.environ['P4C_BUILD_TYPE'] == "DEVELOPER":
            self.add_command_option('assembler',
                                    "-vvvvl {}/bfas.config.log".format(dirname))
        # don't generate a binary
        if self._no_link:
            self.add_command_option('assembler', "--no-bin")

        # target name
        self.add_command_option('assembler', "--target " + self._targetName)
        # prepend unique offset to table handle
        self.add_command_option('assembler',
                                "--table-handle-offset{0}".format(unique_table_offset))
        # output dir
        self.add_command_option('assembler', "-o {}".format(dirname))
        # input file
        self.add_command_option('assembler',
                                "{}/{}.bfa".format(dirname, self._source_basename))
        # run
        self.checkAndRunCmd('assembler')

    # this should be in the parent class!!
    def checkAndRunCmd(self, command):
        cmd = self._commands[command]
        if cmd[0].find('/') != 0 and (find_bin(cmd[0]) == None):
            print >> sys.stderr, "{}: command not found".format(cmd[0])
            sys.exit(1)
        rc = self.runCmd(command, cmd)
        if rc != 0:
            print >> sys.stderr, "failed command {}".format(command)
            sys.exit(rc)

    def checkVersionTargetArch(self, language):
        if language == "p4-14" and self._arch != "v1model":
                print >> sys.stderr, "Architecture {} is not supported in p4-14, use v1model".format(self._arch)
                sys.exit(1)

    def run(self):
        """
        Override the parent run, in order to insert manifest parsing.
        """
        run_assembler = 'assembler' in self._commandsEnabled
        run_archiver = 'archiver' in self._commandsEnabled

        # run the preprocessor, compiler, and verifiers (manifest, context schema, and bf-rt)
        self.disable_commands(['assembler', 'archiver'])
        BackendDriver.run(self)

        # we ran the compiler, now we need to parse the manifest and run the assembler
        # for each P4-16 pipe
        if run_assembler:
            self.parseManifest()
            # We need to make a copy of the list to get a copy of any additional parameters
            # that were added on the command line (-Xassembler)
            self._saved_assembler_params = list(self._commands['assembler'])
            unique_table_offset = 0
            for pipe_dir in self._pipes.values():
                self.runAssembler(pipe_dir, unique_table_offset)
                unique_table_offset += 1

        # run the archiver if one has been set
        if run_archiver:
            self.checkAndRunCmd('archiver')
