
# Instructions for Barefoot
---------------------------------------------------------------
## Scapy and PTF  ($PKTPY=False)

Our environment is currently running p4lang's ptf:

  `git clone https://github.com/p4lang/ptf.git`

  `cp -rf ptf/src/ptf $SDE_INSTALL/lib/python3.5/site-packages/`

  `ptf/ptf $SDE_INSTALL/bin/`
  

Our environment is currently running Scapy v2.4.5:

  `python3 -m pip install --target=$SDE_INSTALL/lib/python3.5/site-packages scapy==2.4.5`

---------------------------------------------------------------
## Setup VM or Container Environment:

  `mkdir /npb-dp; cd /npb-dp`
  
  copy tarball (npb-to-bf.tgz) into this folder.

  `tar xzf extr-2-intel.tgz`

  `./setup-env.sh`

---------------------------------------------------------------
## Build P4 Program:

The top-level p4-program to be built will reside here:

  `/npb-dp/p4_programs/program-X/src/`

---------------------------------------------------------------
## Run NPB Tests:

### Window 1 (model):

  `$SDE_INSTALL/bin/veth_setup.sh
  `$SDE/run_tofino_model.sh --arch tofino2 -p P4NAME -f /npb-dp/cfg/pltfm_ports/model/tofino2/ports.json`

  #For folded-pipe design, pipes may need to be put into loopback:
  
  `$SDE/run_tofino_model.sh --arch tofino2 -p P4NAME -f /npb-dp/cfg/pltfm_ports/model/tofino2/ports.json --int-port-loop 0xc`
  
### Window 2 (switchd):

  `$SDE/run_switchd.sh --arch tofino2 -p P4NAME`

### Window 3

Run single test:
-----------------
Make note of the testname you need to run (ie. test_mau_1hop_s_e)
and include that with the -s argument below (with .test extension).

  `$SDE/run_p4_tests.sh --arch tofino2 -t ./tests/npb/mau_basic -s test_mau_1hop_s_e.test`

Run sanity regression:
-----------------------

  `$SDE/run_p4_tests.sh --arch tofino2 -t ./tests/PIPELINE/regressions/sanity_PROFILE_barefoot`
