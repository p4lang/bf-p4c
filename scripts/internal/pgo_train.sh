#! /bin/bash
set -e

builddir=$1

# Representative workload for PGO (taken from p4-tests/internal/benchmarks/benchmark-references.json):

$builddir/p4c/bf-p4c -Xp4c=--disable-power-check p4-tests/internal/benchmarks/../p4_16/customer/arista/obfuscated-default.p4 &
$builddir/p4c/bf-p4c -Xp4c=--disable-power-check --target tofino2 p4-tests/internal/benchmarks/../p4_16/customer/arista/obfuscated-msee_tofino2.p4 &
$builddir/p4c/bf-p4c --target tofino2 -Xp4c=--disable-power-check p4-tests/internal/benchmarks/../p4_16/customer/extreme/npb-master-ptf/src/pgm_sp_npb_vcpFw_top.p4 &
$builddir/p4c/bf-p4c --target tofino2 -Xp4c=--disable-power-check p4-tests/internal/benchmarks/../p4_16/customer/extreme/npb-multi-prog/src/pgm_mp_npb_top.p4 &
$builddir/p4c/bf-p4c --target tofino2 -Xp4c=--disable-power-check p4-tests/internal/benchmarks/../p4_16/customer/extreme/npb-folded-pipe/src/pgm_fp_npb_dedup_dtel_vcpFw_top.p4 &
$builddir/p4c/bf-p4c --target tofino2 -Xp4c=--disable-power-check -I p4-tests/internal/benchmarks/../p4_16/switch_16/p4src/shared/ p4-tests/internal/benchmarks/../p4_16/switch_16/p4src/switch-tofino2/switch_tofino2_y7.p4 &
$builddir/p4c/bf-p4c --target tofino2 -Xp4c=--disable-power-check -I p4-tests/internal/benchmarks/../p4_16/switch_16/p4src/shared/ p4-tests/internal/benchmarks/../p4_16/switch_16/p4src/switch-tofino2/switch_tofino2_y8.p4 &

wait
