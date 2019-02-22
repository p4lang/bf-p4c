# Copyright (c) 2015-2019 Barefoot Networks, Inc.

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

def checkEnv():
    """
    return the top source directory, or None if can not determine it.
    """
    top_src_dir = None
    if os.environ['P4C_BUILD_TYPE'] == "DEVELOPER":
        top_src_dir = os.path.join(os.path.dirname(__file__), '..', '..','..')
        scripts_dir = os.path.join(top_src_dir, 'scripts')
        if not os.path.isdir(scripts_dir):
            # we are building out of the source directory, so we need to get the source dir
            # from the cmake cache
            cache_file = os.path.join(os.environ['P4C_BIN_DIR'], '..', 'CMakeCache.txt')
            if not os.path.isfile(cache_file):
                # This is a funny setup, where we can't find our configuration, so we should
                # not run anything depending on scripts
                return None
            with open(cache_file) as cmake_cache:
                src_dir_pattern = re.compile(r'BFN_P4C_SOURCE_DIR:STATIC=(.*)$')
                for line in cmake_cache:
                    res = src_dir_pattern.match(line)
                    if res:
                        top_src_dir = res.group(1)
                        break
        if os.path.isdir(top_src_dir):
            return top_src_dir

    return None

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

        self.runVerifiers = False
        top_src_dir = checkEnv()
        if top_src_dir:
            scripts_dir = os.path.join(top_src_dir, 'scripts')
            if os.path.isdir(scripts_dir):
                self.add_command('verifier', os.path.join(scripts_dir, 'validate_output.sh'))
                self.add_command('manifest-verifier', os.path.join(scripts_dir, 'validate_manifest'))
                self.runVerifiers = True

        # order of commands
        self.enable_commands(['preprocessor', 'compiler', 'assembler',
                              'summary_logging'])

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
        self._argGroup.add_argument("--archive", nargs='?',
                                    help="Archive all outputs into a single tar.bz2 file.\n" + \
                                    "Note: it can not be the argument before source file" + \
                                    " without specifying the archive name!",
                                    const="__default__", default=None)
        self._argGroup.add_argument("--bf-rt-schema", action="store",
                                    help="Generate and write BF-RT JSON schema  to the specified file")
        self._argGroup.add_argument("--backward-compatible",
                                    action="store_true", default=False,
                                    help="Set compiler to be backward compatible with p4c-tofino")
        self._argGroup.add_argument("--skip-compilation",
                                    action="store", help="Skip compiling pipes whose name contains one of the"
                                                         "'pipeX' substring")
        self._argGroup.add_argument("--disable-egress-latency-padding",
                                    action="store_true", help="Disables adding match"
                                    " dependent stages to the egress pipeline to "
                                    " achieve minimum required latency")

        self._argGroup.add_argument("--parser-timing-reports",
                                    help="Generate parser timing reports",
                                    action="store_true", default=False)
        self._argGroup.add_argument("--parser-bandwidth-opt",
                                    help="Perform parser bandwidth optimization",
                                    action="store_true", default=False)

        self._argGroup.add_argument("--ir-to-json", default=None,
                                    help="Dump the IR after midend to JSON in the specified file.")
        self._argGroup.add_argument("--verbose",
                                    action="store", default=0, type=int, choices=[0, 1, 2, 3],
                                    help="Set compiler logging verbosity level: 0=OFF, 1=SUMMARY, 2=INFO, 3=DEBUG")
        self._argGroup.add_argument("--Wdisable", action="store", default=None, type=str,
                                    help="Disable a compiler diagnostic, or disable all warnings "
                                    "if no diagnostic is specified.")
        self._argGroup.add_argument("--Werror", action="store", default=None, type=str,
                                    help="Report an error for a compiler diagnostic, or treat all "
                                    "warnings as errors if no diagnostic is specified.")
        self._argGroup.add_argument("--p4runtime-force-std-externs",
                                    action="store_true", default=False,
                                    help="Generate P4Info file using standard extern messages"
                                    " instead of Tofino-specific ones, for a P4 program written"
                                    " for a Tofino-specific arch")

        if os.environ['P4C_BUILD_TYPE'] == "DEVELOPER":
            self._argGroup.add_argument("--validate-output", action="store_true", default=False,
                                        help="run context.json validation")
            self._argGroup.add_argument("--validate-manifest", action="store_true", default=False,
                                        help="run manifest validation")

    def config_preprocessor(self, targetDefine):
        self.add_command_option('preprocessor', "-E -x assembler-with-cpp")
        self.add_command_option('preprocessor', "-D" + targetDefine)
        self.add_command_option('preprocessor', p4c_version.macro_defs)

    def config_compiler(self, targetDefine):
        self.add_command_option('compiler', "--nocpp")
        self.add_command_option('compiler', "-D" + targetDefine)
        self.add_command_option('compiler', p4c_version.macro_defs)

    def config_assembler(self, targetName):
        self._targetName = targetName
        self._no_link = False
        self._multi_parsers = False

    def process_command_line_options(self, opts):
        BackendDriver.process_command_line_options(self, opts)

        self.checkVersionTargetArch(opts.target, opts.language, opts.arch)

        # process the options related to source file
        if self._output_directory == '.':
            # if no output directory set, set it to <filename.target>
            self._output_directory = "{}.{}".format(self._source_basename, self._target)
        output_dir = self._output_directory
        basepath = "{}/{}".format(output_dir, self._source_basename)

        self.add_command_option('preprocessor', "-o")
        self.add_command_option('preprocessor', "{}.p4pp".format(basepath))
        self.add_command_option('preprocessor', self._source_filename)

        self.add_command_option('compiler', "--target " + self._target)
        self.add_command_option('compiler', "--arch " + self._arch)
        self.add_command_option('compiler', "-o")
        self.add_command_option('compiler', "{}".format(output_dir))
        self.add_command_option('compiler', "{}.p4pp".format(basepath))
        # cleanup after compiler
        if not opts.debug_info:
            self._postCmds['compiler'] = []
            self._postCmds['compiler'].append(["rm -f {}.p4pp".format(basepath)])

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

        if opts.backward_compatible or opts.language == 'p4-14':
            self.add_command_option('compiler', '--backward-compatible')

        if opts.parser_timing_reports:
            self.add_command_option('compiler', '--parser-timing-reports')

        if opts.parser_bandwidth_opt:
            self.add_command_option('compiler', '--parser-bandwidth-opt')

        self.skip_compilation = []
        if opts.skip_compilation:
            self.add_command_option('compiler', '--skip-compilation={}'.format(opts.skip_compilation))
            self.skip_compilation = opts.skip_compilation.split(',')

        if opts.display_power_budget:
            self.add_command_option('compiler', '--display-power-budget')

        if opts.ir_to_json is not None:
            self.add_command_option('compiler', '--toJSON {}'.format(opts.ir_to_json))
        self._ir_to_json = opts.ir_to_json

        if opts.disable_egress_latency_padding:
            self.add_command_option('assembler', '--disable-egress-latency-padding')

        if opts.Wdisable is not None:
            self.add_command_option('compiler', '--Wdisable={}'.format(opts.Wdisable))
        if opts.Werror is not None:
            self.add_command_option('compiler', '--Werror={}'.format(opts.Werror))

        if opts.verbose > 0:
            ta_logging = "table_placement:3,table_summary:1"
            phv_verbosity = str(2 * opts.verbose - 1)
            pa_logging = "allocate_phv:" + phv_verbosity + ",utils:3"
            parde_verbosity = str(2 * opts.verbose - 1)
            p2_verbosity = str(2 * opts.verbose)
            parde_logging = "extract_parser:" + parde_verbosity + \
                            ",checksum:" + parde_verbosity + \
                            ",allocate_parser_checksum.h:" + p2_verbosity + \
                            ",lower_parser:" + p2_verbosity + \
                            ",resolve_computed:" + parde_verbosity
            bridge_logging = "bridged_metadata_packing:1"
            self.add_command_option('compiler', '--verbose -T{},{},{},{}'.format(ta_logging,
                                                                                 pa_logging,
                                                                                 parde_logging,
                                                                                 bridge_logging))
        if opts.bf_rt_schema is not None:
            self.add_command_option('compiler', '--bf-rt-schema {}'.format(opts.bf_rt_schema))

            self.add_command_option('bf-rt-verifier', opts.bf_rt_schema)
            self._commandsEnabled.append('bf-rt-verifier')

        if opts.p4runtime_force_std_externs:
            self.add_command_option('compiler', '--p4runtime-force-std-externs')

        if opts.verbose > 0:
            log_scripts_dir = os.environ['P4C_BIN_DIR']
            top_src_dir = checkEnv()
            if top_src_dir:
                # dev environment
                log_scripts_dir = os.path.join(top_src_dir, 'compiler_interfaces')
            if os.path.exists(os.path.join(log_scripts_dir, 'p4c-build-logs')):
                self.add_command('summary_logging', os.path.join(log_scripts_dir, 'p4c-build-logs'))
                self._commandsEnabled.append('summary_logging')

        # Developer only options
        if os.environ['P4C_BUILD_TYPE'] == "DEVELOPER":
            if self.runVerifiers:
                if 'assembler' in self._commandsEnabled:
                    self._commandsEnabled.append('verifier')
                if 'compiler' in self._commandsEnabled:
                    # always validate the manifest if opts.validate_manifest or self.runVerifiers:
                    self.add_command_option('manifest-verifier', "{}/manifest.json".format(output_dir))
                    self._commandsEnabled.append('manifest-verifier')

        # if we need to generate an archive, should be the last command
        if opts.archive is not None:
            self.add_command('archiver', 'tar')
            root_dir = os.path.dirname(output_dir)
            if root_dir == "": root_dir = "."
            if opts.archive == "__default__":
                program_name = os.path.basename(basepath)
            else:
                program_name = opts.archive
            program_dir = os.path.basename(output_dir)
            if program_dir != ".":
                self.add_command_option('archiver',
                                        "-jcf {}/{}.tar.bz2 --exclude=\"*.bin\" -C {} {}".format(root_dir,
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

        if self._dry_run:
            print 'parse manifest:', manifest_filename
            self._pipes = [ { 'context': '{}/pipe/context.json'.format(self._output_directory),
                              'resources': '{}/pipe/resources.json'.format(self._output_directory),
                              'pipe_dir': '{}/pipe'.format(self._output_directory)
            } ]
            return 0

        # compilation failed and there is no manifest. An error should have been printed,
        # so we simply exit here
        if not os.path.isfile(manifest_filename):
            self.exitWithError(None)


        with open(manifest_filename, "rb") as json_file:
            try:
                self._manifest = json.load(json_file)
            except:
                error_msg = "ERROR: Input file '" + manifest_filename + \
                    "' could not be decoded as JSON.\n"
                self.exitWithError(error_msg)
            if (type(self._manifest) is not dict or "programs" not in self._manifest):
                error_msg = "ERROR: Input file '" + manifest_filename + \
                    "' does not appear to be valid manifest JSON.\n"
                self.exitWithError(error_msg)

        self._pipes = []
        schema_version = self._manifest['schema_version']
        pipe_name_label = 'pipe_name'
        if schema_version == "1.0.0": pipe_name_label = 'pipe'

        programs = self._manifest['programs']
        if len(programs) > 1:
            error_msg = "{} currently supports a single program".format(self._targetName.title())
            self.exitWithError(error_msg)
        for prog in programs:
            p4_version = prog['p4_version']
            if (type(prog) is not dict or "contexts" not in prog):
                error_msg = "ERROR: Input file '" + manifest_filename + \
                                 "' does not contain valid program contexts.\n"
                self.exitWithError(error_msg)
            for ctxt in prog["contexts"]:
                self._pipes.append({})
                pipe_id = ctxt['pipe']
                self._pipes[pipe_id]['pipe_name'] = ctxt['pipe_name']
                self._pipes[pipe_id]['context'] = os.path.join(self._output_directory,
                                                               ctxt['path'])
                if p4_version == 'p4-14':
                    self._pipes[pipe_id]['pipe_dir'] = self._output_directory
                else:
                    self._pipes[pipe_id]['pipe_dir'] = os.path.join(self._output_directory,
                                                                    ctxt['pipe_name'])
            for res in prog['p4i']:
                pipe_id = res['pipe']
                res_file = os.path.join(self._output_directory, res['path'])
                self._pipes[pipe_id]['resources'] = res_file

    def updateCompilerFlags(self, jsonFile):
        """
        Set the compile_command in the manifest or context.json
        """
        if self._dry_run or not os.path.exists(jsonFile):
            return

        jsonTree = None
        with open(jsonFile, "r") as json_file:
            try:
                jsonTree = json.load(json_file)
                jsonTree['compile_command'] = ' '.join(sys.argv)
            except:
                self.exitWithError(None)

        if jsonTree is not None:
            with open(jsonFile, "w") as new_file:
                json.dump(jsonTree, new_file, indent=2, separators=(',', ': '))

    def exitWithError(self, error_msg):
        """
        Function to be called when compilation ends in error.
        """
        try:
            manifest_json = os.path.join(self._output_directory, 'manifest.json')
            jsonTree = None
            with open(manifest_json, 'r') as json_file:
                jsonTree = json.load(json_file)
                jsonTree['compilation_succeeded'] = False
            if jsonTree is not None:
                with open(jsonFile, "w") as new_file:
                    json.dump(jsonTree, new_file, indent=2, separators=(',', ': '))
        except:
            pass
        finally:
            if error_msg is not None:
                print >> sys.stderr, str(error_msg)
            sys.exit(1)

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

        if self._multi_parsers:
            self.add_command_option('assembler', "--multi-parsers")

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
            error_msg = "{}: command not found".format(cmd[0])
            self.exitWithError(error_msg)
        rc = self.runCmd(command, cmd)
        if rc != 0:
            error_msg = "failed command {}".format(command)
            self.exitWithError(error_msg)

    def checkVersionTargetArch(self, target, language, arch):
        if language == "p4-14" and arch == 'default':
            self._arch = "v1model"
            self.backend = target + '-' + 'v1model'
        elif language == "p4-16" and arch == 'default':
            self._arch = "tna"
            self.backend = target + '-' + 'tna'
        elif language == "p4-14" and arch != "v1model":
            print >> sys.stderr, \
                    "Ignored --arch={}, v1model is the only supported architecture " \
                    "for p4-14".format(self._arch)
            self._arch = "v1model"
            self.backend = target + '-' + 'v1model'

    def run(self):
        """
        Override the parent run, in order to insert manifest parsing.
        """
        run_assembler = 'assembler' in self._commandsEnabled
        run_archiver = 'archiver' in self._commandsEnabled
        run_compiler = 'compiler' in self._commandsEnabled
        run_verifier = 'verifier' in self._commandsEnabled
        run_summary_logs = 'summary_logging' in self._commandsEnabled

        # run the preprocessor, compiler, and verifiers (manifest, context schema, and bf-rt)
        self.disable_commands(['assembler', 'archiver', 'verifier',
                               'summary_logging'])

        rc = BackendDriver.run(self)
        # Error codes defined in p4c-barefoot.cpp:main
        if rc > 1:  # Invocation or program error. Can't recover anything from this, exit
            return rc

        # ir_to_json exits early, serializing only the IR
        if self._ir_to_json is not None:
            return 0

        # collect all the command line arguments that were passed to the driver
        # the reason we implement this here, is because the backend will not know
        # what arguments were added by the driver, and filtering them requires keeping
        # both sources in sync.
        if run_compiler:  # if compiler doesn't run, there is no manifest
            self.updateCompilerFlags(os.path.join(self._output_directory, 'manifest.json'))

        # we ran the compiler, now we need to parse the manifest and run the assembler
        # for each P4-16 pipe
        if run_assembler:
            self.parseManifest()
            # We need to make a copy of the list to get a copy of any additional parameters
            # that were added on the command line (-Xassembler)
            self._saved_assembler_params = list(self._commands['assembler'])
            unique_table_offset = 0
            for pipe in self._pipes:
                if 'pipe_name' in pipe and pipe['pipe_name'] in self.skip_compilation:
                    continue
                self.runAssembler(pipe['pipe_dir'], unique_table_offset)
                # Although we the context.json schema has an optional compile_command and
                # we could add it here, it is a potential performance penalty to re-write
                # a large context.json file. So we don't!
                # self.updateCompilerFlags(os.path.join(pipe_dir, 'context.json'))
                if run_verifier:
                    # Clear verifier options
                    del self._commands['verifier'] [1:]
                    self.add_command_option('verifier', "-c {}".format(pipe['context']))
                    if pipe.get('resources', False):
                        self.add_command_option('verifier', "-r {}".format(pipe['resources']))
                        # need to add phv.json to the set of resources in the manifest!!
                        # For now, since it is always generated, we piggyback on context.
                        phvJson=pipe['context'].replace('context', 'phv')
                        self.add_command_option('verifier', "-p {}".format(phvJson))
                    self.checkAndRunCmd('verifier')
                unique_table_offset += 1

                if run_summary_logs:
                    if pipe.get('context', False):  # context.json is required
                        try:
                            self.add_command_option('summary_logging', "{}".format(pipe['context']))
                            if pipe.get('resources', False):
                                self.add_command_option('summary_logging', "-r {}".format(pipe['resources']))
                            self.add_command_option('summary_logging', "-o {}".format(pipe['pipe_dir']))
                            self.add_command_option('summary_logging', "--disable-phv-json")
                            self.checkAndRunCmd('summary_logging')
                        except:
                            pass

        # run the archiver if one has been set
        if run_archiver:
            self.checkAndRunCmd('archiver')

        # We've successfully reached this point, but the compilation may have failed
        return rc
