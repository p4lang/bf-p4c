# Test matrix
#  - language versions x architectures x options
#  - language versions: p4-14, p4-16
#  - architectures: v1model, tna, t2na, [psa]
#  - options: -o, -g, --archive, --create-graphs, --validate-*,

tests_dir = os.path.abspath(os.path.dirname(__file__))
p4_14_program = os.path.join(tests_dir, 'p4-programs/internal_p4_14/emulation/emulation.p4')
v1model_program = os.path.join(tests_dir, 'p4_16/ptf/verify_checksum.p4')
p4_16_default = os.path.join(tests_dir, 'p4_16/compile_only/simple_32q.p4')
p4_16_lrn1 = os.path.join(tests_dir, 'p4_16/compile_only/lrn1.p4')
p4_16_path = os.path.join(tests_dir, 'p4-programs/p4_16_programs')
tna_program = os.path.join(p4_16_path, 'tna_digest/tna_digest.p4')
tna32q_program = os.path.join(p4_16_path, 'tna_32q_2pipe/tna_32q_2pipe.p4')
t2na_program = os.path.join(tests_dir, 'p4_16/ptf/ipv4_checksum.p4')
p4_16_includes_dir = os.path.join(tests_dir, 'p4_16/includes')
p4c_driver_tests_outputs = os.path.join(tests_dir, 'p4c_driver_tests_outputs')
p4c_3078_program = os.path.join(tests_dir, 'p4_16/compile_only/p4c-3078.p4')
multipipe_program = os.path.join(tests_dir, 'p4_16/compile_only/multipipe.p4')

# A map of test name to: (compiler args, xfail_msg, files to check for (non)existence,
# ref_src_json, ref_prg_conf, expected string in stdout)
# **** Note *****
#  that when run with -j, tests will run in parallel, so please ensure the output goes to
#  different directories
test_matrix = {
    # Tofino
    'p4_16_noargs': (['-I', p4_16_includes_dir, p4_16_default], None, [
            '!pipe/logs/phv_allocation_0.log', '!pipe/logs/phv_allocation_summary_0.log',
            '!pipe/logs/phv_allocation_history_0.log' ]),  # no phv alloc logs produced

    # Preprocessor only
    'p4_preprocessor_only': (['-I', p4_16_includes_dir, '-E', p4_16_default, '-o', 'p4_preprocessor_only'], None, None),

    # Default program name
    'default_program_name': (['--target', 'tofino', '--arch', 'tna', '-o', 'default_program_name',
                              '-I', p4_16_includes_dir, p4c_3078_program],
                             None,
                             ['p4c-3078.conf', 'pipe/p4c-3078.bfa']),
    # Explicit program name
    'explicit_program_name': (['--target', 'tofino', '--arch', 'tna', '-o', 'explicit_program_name',
                               '--program-name', 'foo_bar_p4c_3078',
                               '-I', p4_16_includes_dir, p4c_3078_program],
                              None,
                              ['foo_bar_p4c_3078.conf', 'pipe/foo_bar_p4c_3078.bfa']),

    # Tofino P4-16
    'p4_16_tna': (['--target', 'tofino', '--arch', 'tna',
                   '-I', p4_16_path, tna_program], None, None),
    'p4_16_tna_debug': (['--target', 'tofino', '--arch', 'tna', '-g',
                          '-o', 'p4_16_tna_debug', '-I', p4_16_path, tna_program], None, None),
    'p4_16_tna_verbose': (['--target', 'tofino', '--arch', 'tna', '--verbose', '2',
                          '-o', 'p4_16_tna_verbose', '-I', p4_16_path, tna_program], None, [
                          'pipe/logs/phv_allocation_0.log', 'pipe/logs/phv_allocation_summary_0.log',
                          'pipe/logs/phv_allocation_history_0.log' ]),
    'p4_16_tna_parser_timing': (['--target', 'tofino', '--arch', 'tna', '--parser-timing-reports',
                          '-o', 'p4_16_tna_parser_timing', '-I', p4_16_path, tna_program], None, None),
    'p4_16_tna_graphs': (['--target', 'tofino', '--arch', 'tna', '--create-graphs',
                           '-o', 'p4_16_tna_graphs', '-I', p4_16_path, tna_program], None, None),
    'p4_16_tna_graphs_debug': (['--target', 'tofino', '--arch', 'tna', '--create-graphs', '-g',
                                 '-o', 'p4_16_tna_graphs_debug',
                                 '-I', p4_16_path, tna_program], None, None),
    # FIXME: remove disabling of parser min/max depth limits (P4C-4170)
    'p4_16_tna_archive': (['--target', 'tofino', '--arch', 'tna', '--archive',
                            '-o', 'p4_16_tna_archive', '-I', p4_16_path,
                            '-Xp4c="--disable-parse-depth-limit"', tna_program], None, None),
    'p4_16_tna_archive_debug': (['--target', 'tofino', '--arch', 'tna',
                                 '--archive', 'p4_16_tna_archive_debug', '-g',
                                 '-o', 'p4_16_tna_archive_debug',
                                 '-I', p4_16_path, tna_program], None, None),
    'p4_16_tna_archive_arg_last': (['--target', 'tofino', '--arch', 'tna',
                                    '-o', 'p4_16_tna_archive_arg_last',
                                    '-I', p4_16_path,
                                    tna_program, '--archive'], None, None),
    'p4_16_tna_archive_source': (['--target', 'tofino', '--arch', 'tna', '--archive',
                                  '--archive-source', '-o', 'p4_16_tna_archive_source',
                                  '-I', p4_16_path, tna_program], None, None),
    'lrn1': (['--target', 'tofino', '--arch', 'tna', '-o', 'lrn1', p4_16_lrn1],
                                  "PHV allocation was not successful", None),

    # Tofino 32q
    'p4_16_t32q': (['--target', 'tofino', '--arch', 'tna',
                    '-I', p4_16_path, tna32q_program], None, None),
    'p4_16_t32q_verbose': (['--target', 'tofino', '--arch', 'tna', '--verbose', '3',
                    '-o', 'p4_16_t32q_verbose', '-I', p4_16_path, tna32q_program], None, [
                        'pipeline_profile_a/logs/phv_allocation_0.log',
                        'pipeline_profile_a/logs/phv_allocation_summary_0.log',
                        'pipeline_profile_a/logs/phv_allocation_history_0.log',
                        'pipeline_profile_b/logs/phv_allocation_2.log',
                        'pipeline_profile_b/logs/phv_allocation_summary_2.log',
                        'pipeline_profile_b/logs/phv_allocation_history_2.log']),
    'p4_16_t32q_debug': (['--target', 'tofino', '--arch', 'tna', '-g',
                          '-o', 'p4_16_t32q_debug', '-I', p4_16_path, tna32q_program], None, None),
    'p4_16_t32q_graphs': (['--target', 'tofino', '--arch', 'tna', '--create-graphs',
                           '-o', 'p4_16_t32q_graphs', '-I', p4_16_path, tna32q_program], None, None),
    'p4_16_t32q_graphs_debug': (['--target', 'tofino', '--arch', 'tna', '--create-graphs', '-g',
                                 '-o', 'p4_16_t32q_graphs_debug',
                                 '-I', p4_16_path, tna32q_program], None, None),
    'p4_16_t32q_archive': (['--target', 'tofino', '--arch', 'tna', '--archive',
                            '-o', 'p4_16_t32q_archive', '-I', p4_16_path, tna32q_program], None, None),
    'p4_16_t32q_archive_debug': (['--target', 'tofino', '--arch', 'tna',
                                  '--archive', 'p4_16_t32q_archive_debug', '-g',
                                  '-o', 'p4_16_t32q_archive_debug',
                                  '-I', p4_16_path, tna32q_program], None, None),
    'p4_16_v1model': (['--target', 'tofino', '--arch', 'v1model',
                       '-I', p4_16_path, v1model_program], None, None),

    # Tofino P4-14
    'p4_14_noargs': (['--std', 'p4-14', '--arch', 'v1model', p4_14_program], None, None),
    'p4_14_output': (['--std', 'p4-14', '--target', 'tofino', '--arch', 'v1model',
                      '-o', 'p4_14_output', p4_14_program], None, None),
    'p4_14_debug': (['-g', '--std', 'p4-14', '--target', 'tofino', '--arch', 'v1model',
                     '-o', 'p4_14_debug', p4_14_program], None, None),
    'p4_14_verbose': (['-g', '--std', 'p4-14', '--target', 'tofino', '--arch', 'v1model',
                       '--verbose', '2', '-o', 'p4_14_verbose', p4_14_program], None, None),
    'p4_14_graphs': (['--create-graphs', '--std', 'p4-14',
                      '--target', 'tofino', '--arch', 'v1model',
                      '-o', 'p4_14_graphs', p4_14_program], None, None),
    'p4_14_graphs_debug': (['--create-graphs', '-g', '--std', 'p4-14',
                            '--target', 'tofino', '--arch', 'v1model',
                            '-o', 'p4_14_graphs_debug', p4_14_program], None, None),
    'p4_14_archive': (['--target', 'tofino', '--archive', '--std', 'p4-14',
                       '--target', 'tofino', '--arch', 'v1model',
                       '-o', 'p4_14_archive', p4_14_program], None, None),
    'p4_14_archgraphs': (['--archive', 'p4_14_archgraphs', '--create-graphs', '--std', 'p4-14',
                          '--target', 'tofino', '--arch', 'v1model', '-o', 'p4_14_archgraphs',
                          p4_14_program], None, None),
    'p4_14_not_v1': (['--std', 'p4-14', '-o', 'p4_14_not_v1', p4_14_program],
                     'Architecture tna is not supported in p4-14, use v1model', None),

    # JBay P4-14 emulation
    'p4_14_jbay': (['--std', 'p4-14',
                    '--target', 'tofino2', '--arch', 'v1model', p4_14_program], None, None),
    'p4_16_jbay_t2na': (['--target', 'tofino2', '--arch', 't2na', '-I', p4_16_includes_dir, t2na_program], None, None),
    'p4_16_jbay_t2na_too_few_stages': (['--target', 'tofino2', '--arch', 't2na', '-I', p4_16_includes_dir,
                                        '-o', 'override_too_few', '--num-stages-override', '3', t2na_program],
                                        'tofino2 supports up to 3 stages, using 4', None),
    'p4_16_jbay_t2na_too_many_stages': (['--target', 'tofino2', '--arch', 't2na', '-I', p4_16_includes_dir,
                                         '-o', 'override_too_many', '--num-stages-override', '30', t2na_program],
                                         'Trying to override mau stages count to 30 but device is capped to 20', None),
    'p4_16_jbay_v1model': (['--target', 'tofino2', '--arch', 'v1model', v1model_program], None, None),

    # Precleaner tests
    # Uses folder structure created in test_p4c_driver.py to test out precleaner.
    # p4c_3078_program is used here since any correct p4 program can be used and this one is already used.
    'skip_precleaner_test': (['--target', 'tofino', '--arch', 'tna', '-o', 'skip_precleaner_test', '--skip-precleaner',
                              '-I', p4_16_includes_dir, p4c_3078_program], None, ['bfrt.json', 'manifest.json', 'p4c-3078.conf',
                              'test.conf', 'test.p4pp', 'logs/test.log', 'graphs/test.dot', 'test.bin', 'frontend-ir.json', 'source.json']),
    'precleaner_test': (['--target', 'tofino', '--arch', 'tna', '-o', 'precleaner_test',
                        '-I', p4_16_includes_dir, p4c_3078_program],
                        None, ['bfrt.json', 'manifest.json', 'p4c-3078.conf',
                        '!test.conf', '!test.p4pp', '!logs/test.log', '!graphs/test.dot', '!test.bin', '!frontend-ir.json', '!source.json']),

    # 'p4_16_jbay_tna': (['--target', 'tofino2', '--arch', 'tna', tna_program], None, None),

    # tofino2* tests fail with "resources.json schema validation failed"
    # Tofino2H
    # 'tofino2h' : (['--target', 'tofino2h', '--arch', 't2na', '-g', '-I', p4_16_includes_dir, '-o', 'tofino2h', t2na_program], None, None),
    # Tofino2M
    # 'tofino2m' : (['--target', 'tofino2m', '--arch', 't2na', '-g', '-I', p4_16_includes_dir, '-o', 'tofino2m', t2na_program], None, None),
    # Tofino2U
    # 'tofino2u' : (['--target', 'tofino2u', '--arch', 't2na', '-g', '-I', p4_16_includes_dir, '-o', 'tofino2u', t2na_program], None, None),

    # Invocation tests
    'disable_warnings': (['--target', 'tofino', '--arch', 'tna', '-I', p4_16_path, tna_program,
                          '--Wdisable', '-o', 'wdisable'], None, None),
    'warnings_to_errors': (['--target', 'tofino', '--arch', 'tna', '-I', p4_16_path, tna_program, '--Werror', '-o', 'werror'],
                            "error: out parameter 'ig_md' may be uninitialized when 'SwitchIngressParser' terminates", None),
    # Following test checks whether compiler can deal with comma separated list of values
    'some_warnings_to_errors': (['--target', 'tofino', '--arch', 'tna', '-I', p4_16_path, tna_program, '--Werror=unused,uninitialized_out_param'],
                            "error: out parameter 'ig_md' may be uninitialized when 'SwitchIngressParser' terminates", None),
    # Test checks if --help-warnings does not crash with new warning types
    'help_warnings': (['--help-warnings'], None, None, None, None, "These are supported warning types for --Werror and --Wdisable:"),

    # source.json regression tests
    # If needed, use "test_p4c_driver.py --gen-src-json" to (re)generate reference source jsons
    'source.json: p4-tests/p4-programs/p4_16_programs/tna_lpm_match' :
        (['--target', 'tofino', '--arch', 'tna', '-o', 'p4-tests_p4-programs_p4_16_programs_tna_lpm_match_source.json', '-I', p4_16_path,
        os.path.join(p4_16_path, 'tna_lpm_match/tna_lpm_match.p4'), '-g'], None, None,
        os.path.join(p4c_driver_tests_outputs, 'p4-tests_p4-programs_p4_16_programs_tna_lpm_match_source.json')),
    'source.json: p4-tests/p4-programs/p4_16_programs/bri_handle' :
        (['--target', 'tofino', '--arch', 'tna', '-o', 'p4-tests_p4-programs_p4_16_programs_bri_handle_source.json', '-I', p4_16_path,
        os.path.join(p4_16_path, 'bri_handle/bri_handle.p4'), '-g'], None, None,
        os.path.join(p4c_driver_tests_outputs, 'p4-tests_p4-programs_p4_16_programs_bri_handle_source.json')),
    'source.json: p4-tests/p4-programs/p4_16_programs/tna_timestamp' :
        (['--target', 'tofino', '--arch', 'tna', '-o', 'p4-tests_p4-programs_p4_16_programs_tna_timestamp_source.json', '-I', p4_16_path,
        os.path.join(p4_16_path, 'tna_timestamp/tna_timestamp.p4'), '-g'], None, None,
        os.path.join(p4c_driver_tests_outputs, 'p4-tests_p4-programs_p4_16_programs_tna_timestamp_source.json')),
    'source.json: p4-tests/p4-programs/p4_16_programs/tna_bridged_md' :
        (['--target', 'tofino', '--arch', 'tna', '-o', 'p4-tests_p4-programs_p4_16_programs_tna_bridged_md_source.json', '-I', p4_16_path,
        os.path.join(p4_16_path, 'tna_bridged_md/tna_bridged_md.p4'), '-g'], None, None,
        os.path.join(p4c_driver_tests_outputs, 'p4-tests_p4-programs_p4_16_programs_tna_bridged_md_source.json')),
    'source.json: p4-tests/p4-programs/p4_16_programs/tna_pvs' :
        (['--target', 'tofino', '--arch', 'tna', '-o', 'p4-tests_p4-programs_p4_16_programs_tna_pvs_source.json', '-I', p4_16_path,
        os.path.join(p4_16_path, 'tna_pvs/tna_pvs.p4'), '-g'], None, None,
        os.path.join(p4c_driver_tests_outputs, 'p4-tests_p4-programs_p4_16_programs_tna_pvs_source.json')),
    'source.json: p4-tests/p4-programs/p4_16_programs/tna_register' :
        (['--target', 'tofino', '--arch', 'tna', '-o', 'p4-tests_p4-programs_p4_16_programs_tna_register_source.json', '-I', p4_16_path,
        os.path.join(p4_16_path, 'tna_register/tna_register.p4'), '-g'], None, None,
        os.path.join(p4c_driver_tests_outputs, 'p4-tests_p4-programs_p4_16_programs_tna_register_source.json')),
    'source.json: p4-tests/p4-programs/p4_16_programs/tna_meter_lpf_wred' :
        (['--target', 'tofino', '--arch', 'tna', '-o', 'p4-tests_p4-programs_p4_16_programs_tna_meter_lpf_wred_source.json', '-I', p4_16_path,
        os.path.join(p4_16_path, 'tna_meter_lpf_wred/tna_meter_lpf_wred.p4'), '-g'], None, None,
        os.path.join(p4c_driver_tests_outputs, 'p4-tests_p4-programs_p4_16_programs_tna_meter_lpf_wred_source.json')),
    'source.json: p4-tests/p4-programs/p4_16_programs/tna_dkm' :
        (['--target', 'tofino', '--arch', 'tna', '-o', 'p4-tests_p4-programs_p4_16_programs_tna_dkm_source.json', '-I', p4_16_path,
        os.path.join(p4_16_path, 'tna_dkm/tna_dkm.p4'), '-g'], None, None,
        os.path.join(p4c_driver_tests_outputs, 'p4-tests_p4-programs_p4_16_programs_tna_dkm_source.json')),
    'source.json: p4-tests/p4-programs/p4_16_programs/tna_32q_multiprogram/program_b' :
        (['--target', 'tofino', '--arch', 'tna', '-o', 'p4-tests_p4-programs_p4_16_programs_tna_32q_multiprogram_program_b_source.json', '-I', p4_16_path,
        os.path.join(p4_16_path, 'tna_32q_multiprogram/program_b/tna_32q_multiprogram_b.p4'), '-g'], None, None,
        os.path.join(p4c_driver_tests_outputs, 'p4-tests_p4-programs_p4_16_programs_tna_32q_multiprogram_program_b_source.json')),
    'source.json: p4-tests/p4-programs/p4_16_programs/tna_32q_multiprogram/program_a' :
        (['--target', 'tofino', '--arch', 'tna', '-o', 'p4-tests_p4-programs_p4_16_programs_tna_32q_multiprogram_program_a_source.json', '-I', p4_16_path,
        os.path.join(p4_16_path, 'tna_32q_multiprogram/program_a/tna_32q_multiprogram_a.p4'), '-g'], None, None,
        os.path.join(p4c_driver_tests_outputs, 'p4-tests_p4-programs_p4_16_programs_tna_32q_multiprogram_program_a_source.json')),
    'source.json: p4-tests/p4-programs/p4_16_programs/tna_random' :
        (['--target', 'tofino', '--arch', 'tna', '-o', 'p4-tests_p4-programs_p4_16_programs_tna_random_source.json', '-I', p4_16_path,
        os.path.join(p4_16_path, 'tna_random/tna_random.p4'), '-g'], None, None,
        os.path.join(p4c_driver_tests_outputs, 'p4-tests_p4-programs_p4_16_programs_tna_random_source.json')),
    'source.json: p4-tests/p4-programs/p4_16_programs/tna_digest' :
        (['--target', 'tofino', '--arch', 'tna', '-o', 'p4-tests_p4-programs_p4_16_programs_tna_digest_source.json', '-I', p4_16_path,
        os.path.join(p4_16_path, 'tna_digest/tna_digest.p4'), '-g'], None, None,
        os.path.join(p4c_driver_tests_outputs, 'p4-tests_p4-programs_p4_16_programs_tna_digest_source.json')),
    'source.json: p4-tests/p4-programs/p4_16_programs/tna_multicast' :
        (['--target', 'tofino', '--arch', 'tna', '-o', 'p4-tests_p4-programs_p4_16_programs_tna_multicast_source.json', '-I', p4_16_path,
        os.path.join(p4_16_path, 'tna_multicast/tna_multicast.p4'), '-g'], None, None,
        os.path.join(p4c_driver_tests_outputs, 'p4-tests_p4-programs_p4_16_programs_tna_multicast_source.json')),
    'source.json: p4-tests/p4-programs/p4_16_programs/tna_port_metadata_extern' :
        (['--target', 'tofino', '--arch', 'tna', '-o', 'p4-tests_p4-programs_p4_16_programs_tna_port_metadata_extern_source.json', '-I', p4_16_path,
        os.path.join(p4_16_path, 'tna_port_metadata_extern/tna_port_metadata_extern.p4'), '-g'], None, None,
        os.path.join(p4c_driver_tests_outputs, 'p4-tests_p4-programs_p4_16_programs_tna_port_metadata_extern_source.json')),
    'source.json: p4-tests/p4-programs/p4_16_programs/tna_pktgen' :
        (['--target', 'tofino', '--arch', 'tna', '-o', 'p4-tests_p4-programs_p4_16_programs_tna_pktgen_source.json', '-I', p4_16_path,
        os.path.join(p4_16_path, 'tna_pktgen/tna_pktgen.p4'), '-g'], None, None,
        os.path.join(p4c_driver_tests_outputs, 'p4-tests_p4-programs_p4_16_programs_tna_pktgen_source.json')),
    'source.json: p4-tests/p4-programs/p4_16_programs/bri_with_pdfixed_thrift' :
        (['--target', 'tofino', '--arch', 'tna', '-o', 'p4-tests_p4-programs_p4_16_programs_bri_with_pdfixed_thrift_source.json', '-I', p4_16_path,
        os.path.join(p4_16_path, 'bri_with_pdfixed_thrift/bri_with_pdfixed_thrift.p4'), '-g'], None, None,
        os.path.join(p4c_driver_tests_outputs, 'p4-tests_p4-programs_p4_16_programs_bri_with_pdfixed_thrift_source.json')),
    'source.json: p4-tests/p4-programs/p4_16_programs/tna_custom_hash' :
        (['--target', 'tofino', '--arch', 'tna', '-o', 'p4-tests_p4-programs_p4_16_programs_tna_custom_hash_source.json', '-I', p4_16_path,
        os.path.join(p4_16_path, 'tna_custom_hash/tna_custom_hash.p4'), '-g'], None, None,
        os.path.join(p4c_driver_tests_outputs, 'p4-tests_p4-programs_p4_16_programs_tna_custom_hash_source.json')),
    'source.json: p4-tests/p4-programs/p4_16_programs/tna_proxy_hash' :
        (['--target', 'tofino', '--arch', 'tna', '-o', 'p4-tests_p4-programs_p4_16_programs_tna_proxy_hash_source.json', '-I', p4_16_path,
        os.path.join(p4_16_path, 'tna_proxy_hash/tna_proxy_hash.p4'), '-g'], None, None,
        os.path.join(p4c_driver_tests_outputs, 'p4-tests_p4-programs_p4_16_programs_tna_proxy_hash_source.json')),
    'source.json: p4-tests/p4-programs/p4_16_programs/tna_exact_match' :
        (['--target', 'tofino', '--arch', 'tna', '-o', 'p4-tests_p4-programs_p4_16_programs_tna_exact_match_source.json', '-I', p4_16_path,
        os.path.join(p4_16_path, 'tna_exact_match/tna_exact_match.p4'), '-g'], None, None,
        os.path.join(p4c_driver_tests_outputs, 'p4-tests_p4-programs_p4_16_programs_tna_exact_match_source.json')),
    'source.json: p4-tests/p4-programs/p4_16_programs/tna_dyn_hashing' :
        (['--target', 'tofino', '--arch', 'tna', '-o', 'p4-tests_p4-programs_p4_16_programs_tna_dyn_hashing_source.json', '-I', p4_16_path,
        os.path.join(p4_16_path, 'tna_dyn_hashing/tna_dyn_hashing.p4'), '-g'], None, None,
        os.path.join(p4c_driver_tests_outputs, 'p4-tests_p4-programs_p4_16_programs_tna_dyn_hashing_source.json')),
    'source.json: p4-tests/p4-programs/p4_16_programs/tna_action_profile' :
        (['--target', 'tofino', '--arch', 'tna', '-o', 'p4-tests_p4-programs_p4_16_programs_tna_action_profile_source.json', '-I', p4_16_path,
        os.path.join(p4_16_path, 'tna_action_profile/tna_action_profile.p4'), '-g'], None, None,
        os.path.join(p4c_driver_tests_outputs, 'p4-tests_p4-programs_p4_16_programs_tna_action_profile_source.json')),
    'source.json: p4-tests/p4-programs/p4_16_programs/tna_symmetric_hash' :
        (['--target', 'tofino', '--arch', 'tna', '-o', 'p4-tests_p4-programs_p4_16_programs_tna_symmetric_hash_source.json', '-I', p4_16_path,
        os.path.join(p4_16_path, 'tna_symmetric_hash/tna_symmetric_hash.p4'), '-g'], None, None,
        os.path.join(p4c_driver_tests_outputs, 'p4-tests_p4-programs_p4_16_programs_tna_symmetric_hash_source.json')),
    'source.json: p4-tests/p4-programs/p4_16_programs/tna_idletimeout' :
        (['--target', 'tofino', '--arch', 'tna', '-o', 'p4-tests_p4-programs_p4_16_programs_tna_idletimeout_source.json', '-I', p4_16_path,
        os.path.join(p4_16_path, 'tna_idletimeout/tna_idletimeout.p4'), '-g'], None, None,
        os.path.join(p4c_driver_tests_outputs, 'p4-tests_p4-programs_p4_16_programs_tna_idletimeout_source.json')),
    'source.json: p4-tests/p4-programs/p4_16_programs/tna_port_metadata' :
        (['--target', 'tofino', '--arch', 'tna', '-o', 'p4-tests_p4-programs_p4_16_programs_tna_port_metadata_source.json', '-I', p4_16_path,
        os.path.join(p4_16_path, 'tna_port_metadata/tna_port_metadata.p4'), '-g'], None, None,
        os.path.join(p4c_driver_tests_outputs, 'p4-tests_p4-programs_p4_16_programs_tna_port_metadata_source.json')),
    'source.json: p4-tests/p4-programs/p4_16_programs/tna_meter_bytecount_adjust' :
        (['--target', 'tofino', '--arch', 'tna', '-o', 'p4-tests_p4-programs_p4_16_programs_tna_meter_bytecount_adjust_source.json', '-I', p4_16_path,
        os.path.join(p4_16_path, 'tna_meter_bytecount_adjust/tna_meter_bytecount_adjust.p4'), '-g'], None, None,
        os.path.join(p4c_driver_tests_outputs, 'p4-tests_p4-programs_p4_16_programs_tna_meter_bytecount_adjust_source.json')),
    'source.json: p4-tests/p4-programs/p4_16_programs/tna_ternary_match' :
        (['--target', 'tofino', '--arch', 'tna', '-o', 'p4-tests_p4-programs_p4_16_programs_tna_ternary_match_source.json', '-I', p4_16_path,
        os.path.join(p4_16_path, 'tna_ternary_match/tna_ternary_match.p4'), '-g'], None, None,
        os.path.join(p4c_driver_tests_outputs, 'p4-tests_p4-programs_p4_16_programs_tna_ternary_match_source.json')),
    'source.json: p4-tests/p4-programs/p4_16_programs/tna_snapshot' :
        (['--target', 'tofino', '--arch', 'tna', '-o', 'p4-tests_p4-programs_p4_16_programs_tna_snapshot_source.json', '-I', p4_16_path,
        os.path.join(p4_16_path, 'tna_snapshot/tna_snapshot.p4'), '-g'], None, None,
        os.path.join(p4c_driver_tests_outputs, 'p4-tests_p4-programs_p4_16_programs_tna_snapshot_source.json')),
    'source.json: p4-tests/p4-programs/p4_16_programs/tna_field_slice' :
        (['--target', 'tofino', '--arch', 'tna', '-o', 'p4-tests_p4-programs_p4_16_programs_tna_field_slice_source.json', '-I', p4_16_path,
        os.path.join(p4_16_path, 'tna_field_slice/tna_field_slice.p4'), '-g'], None, None,
        os.path.join(p4c_driver_tests_outputs, 'p4-tests_p4-programs_p4_16_programs_tna_field_slice_source.json')),
    'source.json: p4-tests/p4-programs/p4_16_programs/tna_action_selector' :
        (['--target', 'tofino', '--arch', 'tna', '-o', 'p4-tests_p4-programs_p4_16_programs_tna_action_selector_source.json', '-I', p4_16_path,
        os.path.join(p4_16_path, 'tna_action_selector/tna_action_selector.p4'), '-g'], None, None,
        os.path.join(p4c_driver_tests_outputs, 'p4-tests_p4-programs_p4_16_programs_tna_action_selector_source.json')),
    'source.json: p4-tests/p4-programs/p4_16_programs/tna_ports' :
        (['--target', 'tofino', '--arch', 'tna', '-o', 'p4-tests_p4-programs_p4_16_programs_tna_ports_source.json', '-I', p4_16_path,
        os.path.join(p4_16_path, 'tna_ports/tna_ports.p4'), '-g'], None, None,
        os.path.join(p4c_driver_tests_outputs, 'p4-tests_p4-programs_p4_16_programs_tna_ports_source.json')),
    'source.json: p4-tests/p4-programs/p4_16_programs/tna_32q_2pipe' :
        (['--target', 'tofino', '--arch', 'tna', '-o', 'p4-tests_p4-programs_p4_16_programs_tna_32q_2pipe_source.json', '-I', p4_16_path,
        os.path.join(p4_16_path, 'tna_32q_2pipe/tna_32q_2pipe.p4'), '-g'], None, None,
        os.path.join(p4c_driver_tests_outputs, 'p4-tests_p4-programs_p4_16_programs_tna_32q_2pipe_source.json')),
    'source.json: p4-tests/p4-programs/p4_16_programs/tna_counter' :
        (['--target', 'tofino', '--arch', 'tna', '-o', 'p4-tests_p4-programs_p4_16_programs_tna_counter_source.json', '-I', p4_16_path,
        os.path.join(p4_16_path, 'tna_counter/tna_counter.p4'), '-g'], None, None,
        os.path.join(p4c_driver_tests_outputs, 'p4-tests_p4-programs_p4_16_programs_tna_counter_source.json')),
    'source.json: p4-tests/p4-programs/p4_16_programs/tna_resubmit' :
        (['--target', 'tofino', '--arch', 'tna', '-o', 'p4-tests_p4-programs_p4_16_programs_tna_resubmit_source.json', '-I', p4_16_path,
        os.path.join(p4_16_path, 'tna_resubmit/tna_resubmit.p4'), '-g'], None, None,
        os.path.join(p4c_driver_tests_outputs, 'p4-tests_p4-programs_p4_16_programs_tna_resubmit_source.json')),
    'source.json: p4-tests/p4-programs/p4_16_programs/tna_operations' :
        (['--target', 'tofino', '--arch', 'tna', '-o', 'p4-tests_p4-programs_p4_16_programs_tna_operations_source.json', '-I', p4_16_path,
        os.path.join(p4_16_path, 'tna_operations/tna_operations.p4'), '-g'], None, None,
        os.path.join(p4c_driver_tests_outputs, 'p4-tests_p4-programs_p4_16_programs_tna_operations_source.json')),
    'source.json: p4-tests/p4-programs/p4_16_programs/tna_mirror' :
        (['--target', 'tofino', '--arch', 'tna', '-o', 'p4-tests_p4-programs_p4_16_programs_tna_mirror_source.json', '-I', p4_16_path,
        os.path.join(p4_16_path, 'tna_mirror/tna_mirror.p4'), '-g'], None, None,
        os.path.join(p4c_driver_tests_outputs, 'p4-tests_p4-programs_p4_16_programs_tna_mirror_source.json')),
    'source.json: p4-tests/p4-programs/p4_16_programs/tna_checksum' :
        (['--target', 'tofino', '--arch', 'tna', '-o', 'p4-tests_p4-programs_p4_16_programs_tna_checksum_source.json', '-I', p4_16_path,
        os.path.join(p4_16_path, 'tna_checksum/tna_checksum.p4'), '-g'], None, None,
        os.path.join(p4c_driver_tests_outputs, 'p4-tests_p4-programs_p4_16_programs_tna_checksum_source.json')),
    'source.json: p4-tests/p4-programs/p4_16_programs/tna_range_match' :
        (['--target', 'tofino', '--arch', 'tna', '-o', 'p4-tests_p4-programs_p4_16_programs_tna_range_match_source.json', '-I', p4_16_path,
        os.path.join(p4_16_path, 'tna_range_match/tna_range_match.p4'), '-g'], None, None,
        os.path.join(p4c_driver_tests_outputs, 'p4-tests_p4-programs_p4_16_programs_tna_range_match_source.json')),

    # .conf regression tests
    # If needed, use "test_p4c_driver.py --gen-prg-conf" to (re)generate reference program conf
    'conf_tofino_pipes1: p4-tests/p4_16/compile_only/multipipe.p4' :
        (['--target', 'tofino', '--arch', 'tna', '-o', 'tofino_pipes1', '-DPIPES=1', '-I', p4_16_path,
        multipipe_program, '-g'], None, None, None,
        os.path.join(p4c_driver_tests_outputs, 'p4-tests_p4_16_compile_only_multipipe_tofino_pipes1.conf')),
    'conf_tofino_pipes2: p4-tests/p4_16/compile_only/multipipe.p4' :
        (['--target', 'tofino', '--arch', 'tna', '-o', 'tofino_pipes2', '-DPIPES=2', '-I', p4_16_path,
        multipipe_program, '-g'], None, None, None,
        os.path.join(p4c_driver_tests_outputs, 'p4-tests_p4_16_compile_only_multipipe_tofino_pipes2.conf')),
    'conf_tofino_pipes4: p4-tests/p4_16/compile_only/multipipe.p4' :
        (['--target', 'tofino', '--arch', 'tna', '-o', 'tofino_pipes4', '-DPIPES=4', '-I', p4_16_path,
        multipipe_program, '-g'], None, None, None,
        os.path.join(p4c_driver_tests_outputs, 'p4-tests_p4_16_compile_only_multipipe_tofino_pipes4.conf')),
    'conf_tofino2_pipes1: p4-tests/p4_16/compile_only/multipipe.p4' :
        (['--target', 'tofino2', '--arch', 't2na', '-o', 'tofino2_pipes1', '-DPIPES=1', '-I', p4_16_path,
        multipipe_program, '-g'], None, None, None,
        os.path.join(p4c_driver_tests_outputs, 'p4-tests_p4_16_compile_only_multipipe_tofino2_pipes1.conf')),
    'conf_tofino2_pipes2: p4-tests/p4_16/compile_only/multipipe.p4' :
        (['--target', 'tofino2', '--arch', 't2na', '-o', 'tofino2_pipes2', '-DPIPES=2', '-I', p4_16_path,
        multipipe_program, '-g'], None, None, None,
        os.path.join(p4c_driver_tests_outputs, 'p4-tests_p4_16_compile_only_multipipe_tofino2_pipes2.conf')),
    'conf_tofino2_pipes4: p4-tests/p4_16/compile_only/multipipe.p4' :
        (['--target', 'tofino2', '--arch', 't2na', '-o', 'tofino2_pipes4', '-DPIPES=4', '-I', p4_16_path,
        multipipe_program, '-g'], None, None, None,
        os.path.join(p4c_driver_tests_outputs, 'p4-tests_p4_16_compile_only_multipipe_tofino2_pipes4.conf')),
}
