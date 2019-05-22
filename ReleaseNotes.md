# Release Notes

## Version 8.9.0
The **The Last before the Storm** release

<div>
> We cry out for more, we wonder what's next to the world
> We settle the score, we never look back
> We're the last before the storm...
<div style="text-align: right"> Gamma-Ray </div>
</div>

  * [P4C-333] - Implement shifter support for deparser parameters
  * [P4C-465] - Implement power compiler structured logging
  * [P4C-545] - Parser Match Register Allocation Refactoring
  * [P4C-737] - PTF unexpectedly failing due to TCAM-related parse error
  * [P4C-925] - p4c compilation failure: Select on field from different parent branches is not supported
  * [P4C-1089] - Add support for >64 bit values in context json generation
  * [P4C-1102] - Jbay lower_parser generates extra empty parser state
  * [P4C-1163] - p4c compilation failure: Action bus byte .* used inconsistently for fields
  * [P4C-1243] - Add pragmas and their description as part of the compiler online help (--help-pragma)
  * [P4C-1369] - Intrinsic metadata field names should have P4 specified prefix in context.json
  * [P4C-1380] - p4c usability: Change Stage pragma error to warning
  * [P4C-1384] - p4c compilation failure: To fit hash destinations in less than 4 immediate bytes, we must assign field to a 16b container.
  * [P4C-1442] - ptf test failure: Received 4 extra bytes in packet
  * [P4C-1473] - Type bool is not supported by RegisterAction
  * [P4C-1493] - Copy propagation is not implemented in parsers
  * [P4C-1496] - p4c compilation failure: fabric fails compilation with JBay
  * [P4C-1523] - p4c compilation failure: Hash table column duplicated
  * [P4C-1528] - sde-post-pkg-driver-comb-brig: test.Test failing with error: match_tbl_set_default_entry()/match_tbl_add_entry() got an unexpected keyword argument 'r_index'/'cntr_index'
  * [P4C-1529] - [UCloud] header metadata memory problem
  * [P4C-1530] - switch.p4-16: B0_PROFILE parse_cpu failure
  * [P4C-1533] - SDE8.8.0.137: the egress parser doesn't work
  * [P4C-1540] - Remove the assumption that IR::HashDist objects has to be kept unmodified throughout the backend.
  * [P4C-1544] - Headers added by MAUs cannot be sourced from CLOTs
  * [P4C-1565] - Unable to bridge metadata - too many sources
  * [P4C-1566] - Model logs not shown for all match keys
  * [P4C-1586] - Packet Corruption/CLOT error in 8.7/Tofino2
  * [P4C-1603] - default_entry.p4 compilation fails with /default_entry.p4(244): [--Werror=legacy] error: meter_2.execute: Cannot unify MeterColor_t to bit<2>
  * [P4C-1610] - parser_intr_md.p4 fails with bf-p4c: error: unrecognized arguments: --metadata-overlay=False
  * [P4C-1615] - Deparser Learn Mask Incorrect For Fields Sharing Containers
  * [P4C-1618] - Incorrect CLOT allocation when headers extracted in same state have different validity
  * [P4C-1620] - checksum msb and lsb reversed
  * [P4C-1621] - SDE 8.8.0.476: parser error
  * [P4C-1622] - Customer code failing with "Fields added after PHV allocation"
  * [P4C-1623] - Publish the type of $LPF_SPEC_TYPE and $ENTRY_HIT_STATE fields as "string" instead of "enum"
  * [P4C-1624] - does not have a PHV allocation though it is used in an action
  * [P4C-1628] - Bad dprsr config when a clot is used for intrinsic metadata that is bridged
  * [P4C-1637] - Incorrect CLOT allocation for lookahead
  * [P4C-1640] - p4-16 and ALU warnings
  * [P4C-1641] - No phv record alu_lo
  * [P4C-1644] - parser.log information is out-of-date
  * [P4C-1646] - onos-fabric failing to compile for Tofino2: PHV containers used by both ingress and egress deparser
  * [P4C-1649] - p4c compilation failure: Invalid args to MakeSlice
  * [P4C-1652] - error: Gateway match key not in matching hash column
  * [P4C-1662] - Parser graphs are not created
  * [P4C-1668] - Supporting @pragma stage with two parameters
  * [P4C-1672] - Compiler Bug - Conditional on mux is not an action argument
  * [P4C-1674] - Assembler warning: Conflicting instruction slot usage
  * [P4C-1679] - Very long compilation time for a simple program
  * [P4C-1680] - 8.8: Stateful register error when using a hash
  * [P4C-1682] - resources.json clots empty field list
  * [P4C-1688] - The presence of varbit extract screws up select()
  * [P4C-1695] - Compiler Bug: Checksum field not extracted?
  * [P4C-1698] - lookahead1.p4 fails with PartialHdr
  * [P4C-1714] - Compiler Bug: mirror field does not exist
  * [P4C-1718] - Deparsed mirror header has a lot of holes
  * [P4C-1733] - Splitting of parser states needs to take into account CLOTs-per-state constraint
  * [P4C-1736] - sde-post-pkg-driver-comb-brig: Error while trying to run driver-comb 28, 38, 40 : Error : Segmentation fault
  * [P4C-1739] - pa_alias support for multiple aliased fields
  * [P4C-1745] - bf-switch: UDP validation clobbers UDP state
  * [P4C-1759] - [rel_8_9]: P4 programs meters, exm_direct_1, exm_direct fail compilation with Brig. error: eg_ucast_port: no such field in standard_metadata
  * [P4C-1764] - tofino2: SRV6 tests tests.SRv6EndDX6Test and tests.SRv6EndDT6Test fails with AssertionError: Expected packet was not received on device 0, port 9.


## Version 8.8.0
The **Home run** release

  * [P4C-190] - Reset checksum header fields that are removed
  * [P4C-282] - bitmasked-set instruction with 2 or 3 operands is broken
  * [P4C-438] - Error message about missing default parameter value is not clear
  * [P4C-564] - Parser bandwidth
  * [P4C-682] - Need better error message that connects to the source code
  * [P4C-723] - Analysis of Removal and Add Headers for Live Overlay
  * [P4C-760] - stateful selector with unwanted output can corrupt action data
  * [P4C-832] - Poorly specified error
  * [P4C-858] - Reorganize P4-test structure
  * [P4C-881] - Support varbit in the parser
  * [P4C-1021] - Incorrect checksum calculations
  * [P4C-1049] - mod_field_conditionally compilation fails with /mod_field_conditionally.p4(130): error: : conditional assignment not supported modify_field_conditionally(ethernet.srcAddr, cond, value);
  * [P4C-1082] - CLOTs represented in compiler artefacts (context.json or resources.json)
  * [P4C-1116] - Meter execution result encoding
  * [P4C-1124] - Color-blind/color-aware meters in TNA
  * [P4C-1139] - Static entries are not working when an action parameter type is specified by typedef
  * [P4C-1162] - p4c compilation failure: terminate called after throwing an instance of 'std::out_of_range'
  * [P4C-1252] - Support for pragma force_immediate
  * [P4C-1255] - Support for pragma max_actions
  * [P4C-1300] - error: no more that 2 clots per state
  * [P4C-1308] - Invoking hash calculations
  * [P4C-1311] - if() statement with '++' operation: condition too complex
  * [P4C-1313] - Compiler Bug: field equality comparison misaligned in gateway
  * [P4C-1314] - RegisterAction can't find variable declaration in the enclosing scope
  * [P4C-1340] - Add support for publishing multiple phase0 table instances in bf-rt and context json if there are multiple parser instances in the P4
  * [P4C-1388] - p4c compilation failure: syntax error, unexpected
  * [P4C-1392] - p4c compilation failure: Tofino only supports 1-bit checksum update condition in the deparser
  * [P4C-1406] - p4c must fail: Table cannot match on multiple fields using lpm match type
  * [P4C-1409] - Stash support
  * [P4C-1413] - Conditional checksum update fails if condition has a boolean type
  * [P4C-1414] - Hash algorithm is ignored for Checksum extern.
  * [P4C-1429] - Compiler bug: recursion failure
  * [P4C-1433] - support obfuscation of P4 code only
  * [P4C-1449] - p4-16 Program corrupting the packet!
  * [P4C-1450] - Sequential execution with register (SALU) blackboxes
  * [P4C-1451] - Compiler Bug: unexpected field .do_seq:data
  * [P4C-1458] - Assembler error: "Ran out of constant output slots"
  * [P4C-1463] - Incorrect Parser programming
  * [P4C-1467] - P4-16: Hash algorithm and compiler bug
  * [P4C-1470] - LocalCopyProp pass of midend might remove fields that are used in RegisterAction
  * [P4C-1471] - Attached p4 is failing with "error: conflicting predicate output use in MAU::StatefulAlu ingress.array1"
  * [P4C-1479] - constrain the number of stages for table placement
  * [P4C-1481] - Support for always run
  * [P4C-1482] - Action data packing
  * [P4C-1487] - Table eliminated for unknown reason
  * [P4C-1500] - Incorrect parser setup for Tofino2
  * [P4C-1507] - Brig compilation failures with GCC7
  * [P4C-1509] - Incorrect TCP Checksum in dyn_hash.p4
  * [P4C-1512] - PHV allocation creates a container action impossible within a Tofino ALU
  * [P4C-1520] - switch.p4-16: Tofino2 MTS build failure
  * [P4C-1521] - Compilation failure while compiling mau_test on Jbay with error: DH0 not accessable in input xbar
  * [P4C-1524] - switch.p4-16: 32Q switch compile failure due to pa_alias
  * [P4C-1548] - error: in RegisterAction
  * [P4C-1549] - switch.p4-16: Table utilization very low for some tables
  * [P4C-1554] - BRIG doesn't like setValid for a header passed to a global action
  * [P4C-1557] - error: action instruction slot in use elsewhere
  * [P4C-1560] - error: DB0 not accessable in input xbar
  * [P4C-1563] - Compiler warning question
  * [P4C-1571] - Stateful action selector compilation error
  * [P4C-1575] - crash when dumping parser timing reports
  * [P4C-1578] - tna_pvs_multi_states test test.SharedPvsTest test fails with tna_pvs_multi_states/test.py", line 96, in runTest assert(0) AssertionError
  * [P4C-1584] - placement=pragma is still not ignored by bf-p4c compiler.
  * [P4C-1588] - Compiler Bug: Exiting with SIGSEGV
  * [P4C-1589] - Compiler crashes on metadata extraction
  * [P4C-1606] - Iterator.p4 fails compilation with iterator.p4(89) action d(x,y,i) {error: Ingress field is bridged, but not deparsed: 12:ingress::__phase0_data.x<16> ^0 ^N[0..15]b bridge


## Version 8.7.0
The **Quickie** release

New Features
  - Support the Serializer extern in TNA
  - Support programming parsers separately in TNA.
  - Introduce a pass to determine potential overlays, assuming movement of fields into dark containers
  - wide-bit arithmetic support
  - Support for Tofino2 variants

Bug fixes
  - Immediates for action instruction operands are placed in disallowed bytes on action bus
  - Brig fails with unhandled expression for a valid gateway condition.
  - Signed/unsigned warnings for P4_14
  - Spurious warnings about uninitialized uses.
  - Gateway match key .* not in matching hash column
  - Large metadata set in parser not set properly.
  - Invalid table merge
  - Spurious warnings about conflicting actions on non-mutually-exclusive tables when the actions are mutually exclusive
  - Primitive register read not correctly converted in instruction selection
  - extern RegisterAction does not have method matching this call
  - Front-end inlining does not work correctly for controls that are applied multiple times.
  - ActionPhvConstraints allows misalignment in the action_conflict_3 test case
  - Error: condition too complex
  - basic_ipv4 test test.TestLearning fails with learn_meta_2 == digest_entry.routing_metadata_learn_meta_2
  - RegisterAction can't find variable declaration in the enclosing scope
  - Incorrect warning about SALU code translated from P4_14
  - modify_field_with_hash_based_offset outputs zero instead of hash value
  - Tofino2: Model asserting when trying to mirror a packet
  - Group dominator cannot be a node that reads the field
  - Conflicting alloc in the action data xbar between .* and .* at byte .*
  - elim_emit_headers does not handle control block parameter.
  - PHV allocation was not successful (DC_BASIC_PROFILE on switch master)
  - Incorrect match_nibble_s1q0_enable config with smoke_large_tbls on jbay
  - Flexible packing must fold in alignment constraints due to assignments in the parser
  - Total size of containers used for POV allocation is 144b, greater than the allowed limit of 128b.

Improvements
  - Support Boolean in bridged metadata
  - Global copy prop and constant prop in the Tofino backend
  - Lower casts in the midend
  - program compiles for a very long time in PHV Analysis
  - AssignmentStatement: Cannot unify bit<7> to int<7>
  - output the parser timing to a log file
  - Unify glass and brig tests
  - More aggressive packing of POV bits
  - Support for deparser zero optimization for p4.16 programs without  a pragma

## Version 8.6.0
The **Should have been** release


## Version 8.5.0-pr.2
The **Get to par** release

New features
  - Proxy hash table support
  - MinMaxAction -- support for 128-bit registers (JBay)
  - Configure empty MAU pipe

PHV
  - Bridged metadata packing
  - Digest constraints

Parser/Deparser
  - Extract large constant metadata

Primitives and pragmas
  - Pragma container_size enforced when slicing
  - Pragma pa_no_init with live range shrinking
  - Pragma field_list_field_slice (slicing in P4-14) support

Tofino 2
  - Ghost thread support and fixes
  - CLOT checksum
  - Disable metatada initialization for dark and mocha containers

Notable bug fixes
  - Fix pipeline timing latency issues
  - p4i visualization fixes
  - phase0 names consistent with context.json


## Version 8.5.0-pr.1
**Slicing and dicing** release

New features
  - Better error messages and warnings cleanup
  - Allow Selector Groups Larger than 120
  - Add support for ValueSet in TNA P4Info & BF-RT JSON
  - decaf: a deparser optimization of copy assigned fields
  - Ensure minimum required egress latency is maintained for Tofino
  - Generate context.json on assembler errors
  - Use compiler-interfaces repository for JSON schemas

Assembler
  - Static entries support for ternary and range match
  - Set the values for default selector mask and default selector value

MAU
  - Fix get functions on attached tables for Sram tables
  - hash_action allocation
  - Add saturating support
  - Disable unused cmp alus in stateful alus
  - Mix dleft in exact/ternary tables
  - Action data bus allocation for meters
  - Support @reduction_or_group annotation on stateful alu

PHV
  - Fix mocha/dark PHV allocation and handling of conditional constraints
  - Live range shrinking pass with metadata initialization
  - Add MAU constraints to slicing to prevent long-running loop
  - Bridged metadata packing improvements and Metadata slice list slicing

Parser/Deparser
  - Collect "no_co_pack" constraint from deparser
  - Initialize metadata fields in parser

Primitives
  - Support resubmit.emit() with no parameters

Tofino2
  - Change MirrorId_t to bit<8> and QueueId_t to bit<7>
  - Implement D-left and LearnAction
  - Fix CLOT 3-byte gap constraint

Notable bug fixes
  - Simplify comparisons of comparisons in CanonGatewayExpr
  - Fix conditional checksum update
  - Fix eg_intr_md.pkt_length translation
  - Generate phase0 annotation for TNA programs
  - Fixes for pgrs test
  - Adjust egress packet length for mirrored packet
  - Do no error out in Python driver if we run with -E

## Version 8.5.0-pr.0
The **Share the Tofino P4 love** release

New features
  - Added a new extern for serializer
  - Hash action tables
  - Support the Advanced Flow Control For TM metadata

Assembler
  - Add a how_referenced to the assembly language

MAU
  - Format in gateway to determine payload locations
  - Limit hash dist address allocation to 23 bits
  - Infer stack/fifo control plane use
  - Avoid duplicating RegisterActions used by multiple actions/tables
  - Program meter_rng_enable for color-based meters
  - Multiple range fields in a single TCAM table
  - Infer @stage for gateways from dependent tables
  - Fix for row_action_nxtable_bus_drive register

Parser/Deparser
  - Fix JBay deparser checksum
  - Parser match byte used multiple times

PHV

Primitives, Pragmas and Misc
  - `--skip-compilation` flag
  - Architecture configuration to the manifest file
  - Add `--ir-to-json` option to driver

Notable bug fixes
  - Fix partition action handle generation
  - Salu min/max index output fixes


## Version 8.4.0
The **Grunt work** release

New features
  - Support for hash calculation library
  - Reduction OR
  - Support for conditional checksum update
  - Buggy 32-bit support
  - Add schema validation for context.json and manifest.json
  - Generate reference outputs for p4i

Assembler
  - Additional sateful asm options
  - Standardize assembly calls for Counters/Meters/Stateful ALUs/Selectors
  - Add support for condition tables in context.json
  - Generate ghost bit info in context.json
  - Add hash primitives along with new 'hash_inputs' node in context.json

MAU
  - Explicit calculation for a wide match table
  - Correct calculation of number of overlay bits in a transaction
  - Support for meter blackbox
  - Table flow graph and visualization
  - hash_dist register setup type/enable consistency
  - Save static entries in the backend table with modified names
  - Add node reachability maps to table flow graph
  - Allow sharing on the action bus between tables
  - Build an immediate dominator map from the table flow graph
  - TNA direct register fixes

Parser/Deparser
  - Enhance parser match register allocation to allow packing

PHV
  - Propagation of dependency chains to inner placement groups
  - Disable metadata initialization for mirror_type, digest_type, and resubmit_type
  - Add metadata live range pass
  - Improvements to analyses required by speculative live range shrinking
  - Slicing optimizations

Primitives, Pragmas and Misc
  - Add support for @dynamic_table_key_masks pragma
  - Allow disabling of PHV allocation related pragmas using --disable-pragma
  - Add file logging support using --verbose option

Notable bug fixes
  - Avoid looping in CanonGatewayExpression
  - Generate correct json tree for alpm preclassifier action primitive
  - Fix live range output for PHVs
  - Allow mirror type check for non zero value
  - Fix table dependency graph and live range overlay
  - Fix hash collision
  - Stateful ALU backend bug fixes
  - Calculate LRT params after table placement
  - Fix zero padding in ternary match pack format

## Version 8.3.0-beta.2
The **Quick shadow** release

Bug fixes
  - fix primitive node generation in context.json
  - fix canonical gateway expression simplification


## Version 8.3-aplha.1
The **Shadow** release

New features
    - Compiler/Assembler/Infra support for 32Q
    - support for Fedora 18

BF-RT
    - idle timeout
    - port metadata (aka phase0)

MAU
    - stateful divmod support
    - reduction or for stateful alu
    - unspecified but used stateful_alu attributes
    - table placement decision logging

PHV
    - allow slices on match key fields
    - better allocation of SALU operands
    - conditional constraints
    - allocation for L3_HEAVY_INT_LEAF_PROFILE

Parser/Deparser
    - ipv4 checksum verification with options
    - parser lookahead for pvs

Primitives, Pragmas and Misc
    - fixes to keyless tables cjson for driver
    - correct field info for ranges with mask
    - @calculated_field_update_location
    - @residual_checksum_parser_update_location

Bug Fixes
    - deparser checksum entry byte mask/swap
    - Allow looking up PHV Field objects by external name
    - put log files in the right per-pipe subdirectory
    - alignment for --ununsed-- fields in context.json
    - gateway merge not respecting some control dependencies
    - actionbus adjacent alignment check
    - digest type fitting issues
    - BF-RT generation for direct registers
    - IXBar fixes for Stateful Tables

Tofino2
    - pmarb bubble width control regs
    - ghost thread framework for JNA

## Version 8.2.1-alpha.1
The **Hidden** release

New features
  - Add power estimation check
  - add `--backward-compatible` flag to allow read & write on egress_intrinsics
  - PHV bubble generation config
  - Deparse Zero Optimization
JBay
  - support for multistage fifo
  - mirror metadata
  - asm support for deparser constants
  - Ghost thread support
  - Support 34 bit stateful registerfile
BF-RT support
  - TTL data field
  - stateful registers
  - color-aware meters
  - LPF and WRED
Table placement
  - multiple rounds for allocation of memories
  - optimizations: wide rams, packing, gateways
  - action_bus allocation management
  - generate random hash seed
  - table dependency graph optimizations
PHVs
  - better bridged metadata packing
  - various constraints: no-pack, alignment, etc
  - ActionPhvConstraints check
  - actionbus adjacent alignment
  - heuristics tuning
Primitives and pragmas
  - @packet_entry annotation on start_egress state
Bug fixes
  - clone id assignment
  - various checksum improvements
  - support for egress_rid metadata
  - input byte mask for LPF/WRED meters
  - parser priority update
  - fixed parser lookahead for pvs
  - dleft table/hardware learning

## Version 8.2.0-alpha.1
The **Green Dot** release

Compiler support for all non-INT profiles, released as part of SDE 8.2
- P4-16 improvements
  - improved BF-RT support
  - TNA/JNA/Stratum refactoring and cleanup
  - improved handling of architectures (--arch flags)
  - clone/mirror, resubmit, digest ID assignment optimizations
- Parser/deparser
  - improved match register allocation
  - checksum units: initialization, deparser config, crc gen, residuals
  - parser counter loop unrolling
  - checksum verification outputs steal extractors
- PHVs
  - bridged metadata packing optimizations
  - sliced fields support
  - constraints, constraints: alignment, packing (or rather not!)
  - JBay: support for Mocha containers and Dark PHV privatization
  - tuning heuristics for allocation
- MAU
  - SALU operands
  - gateways optimizations
  - JBay: support for Meter ALU Group Delay
  - allow Meter ALU to access data through the hash pathway
  - JBay: support multiple outputs from register actions
  - JBay: placement of DLeftHashTables
  - Meter pre-color
  - JBay: single-stage hw learning
  - action data allocation optimizations
  - 5 pack capabilities to RAM line
  - multiple rounds of allocation for memories
  - wide-action support (compiler and assembler)
  - refactoring of action bus allocation
- Primitives and pragmas
  - support for `lrt_scale` and `lrt_threshold` pragmas
  - `disable_atomic_modify` pragma
  - `random_seed` pragma
  - `idle_timeout` support
  - `max_loop_depth` pragma
  - `invalidate_digest` P4_14 primitive
- Visualization
  - support for creating compiler archives
  - more logging support

Countless (~150) bugs mercilessly squashed.

## Version 8.1.0-alpha.1
The MSDC release

The compiler supports the switch MSDC profile. Notable additions:
- P4-16 Tofino architectures
  - defined: TNA, TNA32q, TNA16q, JNA
  - various PSA support
- P4Runtime
  - support for BF-RT JSON generation
- PHV allocation
  - metadata initialization
  - PHV/TPHV Privatization for read-only fields
  - bridge metadata support
  - initial Dark and Mocha PHV support
  - implement transactional allocation
  - PHV logging refactoring to expain reasons for failures
  - clot allocation to PHV
- Tables
  - action data bus optimizations
  - input xbar optimizations
  - home/overflow bus setup for wide action tables
  - stateful alu: stack and FIFO support
  - moved IMEM allocation in the compiler
  - min-width on direct counters
- Primitives support
  - random number generation
  - _from_hash and _with_or meter/counter primitives
  - bypass_egress primitive
- Parser
  - support for Parser Value Set (PVS)
  - improved match register allocation
  - support for parser checksum (with clots)
- Visualization support
- Support for create-graphs option
- Various pragmas (P4_14)
