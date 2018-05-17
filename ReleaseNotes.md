# Release Notes

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
