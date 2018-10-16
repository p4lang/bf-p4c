# Release Notes

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
