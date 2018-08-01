# Release Notes

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
