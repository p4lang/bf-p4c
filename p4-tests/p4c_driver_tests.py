# Test matrix
#  - language versions x architectures x options
#  - language versions: p4-14, p4-16
#  - architectures: v1model, tna, t2na, [psa]
#  - options: -o, -g, --archive, --create-graphs, --validate-*,

tests_dir = os.path.abspath(os.path.dirname(__file__))
p4_14_program = os.path.join(tests_dir, 'p4-programs/internal_p4_14/emulation/emulation.p4')
v1model_program = os.path.join(tests_dir, 'p4_16/ptf/verify_checksum.p4')
p4_16_default = os.path.join(tests_dir, 'p4_16/compile_only/simple_32q.p4')
p4_16_path = os.path.join(tests_dir, 'p4-programs/p4_16_programs')
tna_program = os.path.join(p4_16_path, 'tna_digest/tna_digest.p4')
tna32q_program = os.path.join(p4_16_path, 'tna_32q_2pipe/tna_32q_2pipe.p4')
t2na_program = os.path.join(tests_dir, 'p4_16/ptf/ipv4_checksum.p4')
p4_16_includes_dir = os.path.join(tests_dir, 'p4_16/includes')

# A map of test name to: (compiler args, xfail_msg)
# **** Note *****
#  that when run with -j, tests will run in parallel, so please ensure the output goes to
#  different directories
test_matrix = {
    # Tofino
    'p4_16_noargs': (['-I', p4_16_includes_dir, p4_16_default], None),

    # Preprocessor only
    'p4_preprocessor_only': (['-I', p4_16_includes_dir, '-E', p4_16_default, '-o', 'p4_preprocessor_only'], None),

    # Tofino P4-16
    'p4_16_tna': (['--target', 'tofino', '--arch', 'tna',
                   '-I', p4_16_path, tna_program], None),
    'p4_16_tna_debug': (['--target', 'tofino', '--arch', 'tna', '-g',
                          '-o', 'p4_16_tna_debug', '-I', p4_16_path, tna_program], None),
    'p4_16_tna_verbose': (['--target', 'tofino', '--arch', 'tna', '--verbose', '2',
                          '-o', 'p4_16_tna_verbose', '-I', p4_16_path, tna_program], None),
    'p4_16_tna_parser_timing': (['--target', 'tofino', '--arch', 'tna', '--parser-timing-reports',
                          '-o', 'p4_16_tna_parser_timing', '-I', p4_16_path, tna_program], None),
    'p4_16_tna_graphs': (['--target', 'tofino', '--arch', 'tna', '--create-graphs',
                           '-o', 'p4_16_tna_graphs', '-I', p4_16_path, tna_program], None),
    'p4_16_tna_graphs_debug': (['--target', 'tofino', '--arch', 'tna', '--create-graphs', '-g',
                                 '-o', 'p4_16_tna_graphs_debug',
                                 '-I', p4_16_path, tna_program], None),
    'p4_16_tna_archive': (['--target', 'tofino', '--arch', 'tna', '--archive',
                            '-o', 'p4_16_tna_archive', '-I', p4_16_path, tna_program], None),
    'p4_16_tna_archive_debug': (['--target', 'tofino', '--arch', 'tna',
                                 '--archive', 'p4_16_tna_archive_debug', '-g',
                                 '-o', 'p4_16_tna_archive_debug',
                                 '-I', p4_16_path, tna_program], None),
    'p4_16_tna_archive_arg_last': (['--target', 'tofino', '--arch', 'tna',
                                    '-o', 'p4_16_tna_archive_arg_last',
                                    '-I', p4_16_path,
                                    tna_program, '--archive'], None),
    # Tofino 32q
    'p4_16_t32q': (['--target', 'tofino', '--arch', 'tna',
                    '-I', p4_16_path, tna32q_program], None),
    'p4_16_t32q_debug': (['--target', 'tofino', '--arch', 'tna', '-g',
                          '-o', 'p4_16_t32q_debug', '-I', p4_16_path, tna32q_program], None),
    'p4_16_t32q_graphs': (['--target', 'tofino', '--arch', 'tna', '--create-graphs',
                           '-o', 'p4_16_t32q_graphs', '-I', p4_16_path, tna32q_program], None),
    'p4_16_t32q_graphs_debug': (['--target', 'tofino', '--arch', 'tna', '--create-graphs', '-g',
                                 '-o', 'p4_16_t32q_graphs_debug',
                                 '-I', p4_16_path, tna32q_program], None),
    'p4_16_t32q_archive': (['--target', 'tofino', '--arch', 'tna', '--archive',
                            '-o', 'p4_16_t32q_archive', '-I', p4_16_path, tna32q_program], None),
    'p4_16_t32q_archive_debug': (['--target', 'tofino', '--arch', 'tna',
                                  '--archive', 'p4_16_t32q_archive_debug', '-g',
                                  '-o', 'p4_16_t32q_archive_debug',
                                  '-I', p4_16_path, tna32q_program], None),
    'p4_16_v1model': (['--target', 'tofino', '--arch', 'v1model',
                       '-I', p4_16_path, v1model_program], None),

    # Tofino P4-14
    'p4_14_noargs': (['--std', 'p4-14', '--arch', 'v1model', p4_14_program], None),
    'p4_14_output': (['--std', 'p4-14', '--target', 'tofino', '--arch', 'v1model',
                      '-o', 'p4_14_output', p4_14_program], None),
    'p4_14_debug': (['-g', '--std', 'p4-14', '--target', 'tofino', '--arch', 'v1model',
                     '-o', 'p4_14_debug', p4_14_program], None),
    'p4_14_graphs': (['--create-graphs', '--std', 'p4-14',
                      '--target', 'tofino', '--arch', 'v1model',
                      '-o', 'p4_14_graphs', p4_14_program], None),
    'p4_14_graphs_debug': (['--create-graphs', '-g', '--std', 'p4-14',
                            '--target', 'tofino', '--arch', 'v1model',
                            '-o', 'p4_14_graphs_debug', p4_14_program], None),
    'p4_14_archive': (['--target', 'tofino', '--archive', '--std', 'p4-14',
                       '--target', 'tofino', '--arch', 'v1model',
                       '-o', 'p4_14_archive', p4_14_program], None),
    'p4_14_archgraphs': (['--archive', 'p4_14_archgraphs', '--create-graphs', '--std', 'p4-14',
                          '--target', 'tofino', '--arch', 'v1model', '-o', 'p4_14_archgraphs',
                          p4_14_program], None),
    'p4_14_not_v1': (['--std', 'p4-14', '-o', 'p4_14_not_v1', p4_14_program],
                     'Architecture tna is not supported in p4-14, use v1model'),

    # JBay P4-14 emulation
    'p4_14_jbay': (['--std', 'p4-14',
                    '--target', 'tofino2', '--arch', 'v1model', p4_14_program], None),
    'p4_16_jbay_t2na': (['--target', 'tofino2', '--arch', 't2na', '-I', p4_16_includes_dir, t2na_program], None),
    'p4_16_jbay_v1model': (['--target', 'tofino2', '--arch', 'v1model', v1model_program], None),
    # 'p4_16_jbay_tna': (['--target', 'tofino2', '--arch', 'tna', tna_program], None),

    # Tofino2H
    'tofino2h' : (['--target', 'tofino2h', '--arch', 't2na', '-g', '-I', p4_16_includes_dir, '-o', 'tofino2h', t2na_program], None),
    # Tofino2M
    'tofino2m' : (['--target', 'tofino2m', '--arch', 't2na', '-g', '-I', p4_16_includes_dir, '-o', 'tofino2m', t2na_program], None),
    # Tofino2U
    'tofino2u' : (['--target', 'tofino2u', '--arch', 't2na', '-g', '-I', p4_16_includes_dir, '-o', 'tofino2u', t2na_program], None),
}
