
# Build and Test Instructions for Intel
---------------------------------------------------------------
## Scapy and PTF  ($PKTPY=False)

Our environment is currently running p4lang's ptf:

  `git clone https://github.com/p4lang/ptf.git`

  `cp -rf ptf/src/ptf $SDE_INSTALL/lib/python3.5/site-packages/`

  `cp ptf/ptf $SDE_INSTALL/bin/`
  

Our environment is currently running Scapy v2.4.5:

  `python3 -m pip install --target=$SDE_INSTALL/lib/python3.5/site-packages scapy==2.4.5`

---------------------------------------------------------------
## Setup VM or Container Environment:

  Explode tarball:
  `tar xzf extr-2-intel.tgz`

  Modify paths in tst/config.py for SDE_INSTALL and TEST_JSON if needed.

  Copy tst/ports.json to desired location if needed.

  Copy scapy modules (env/patches/scapy/*.py ) into your scapy/contrib folder.

  patch ptf packet.py:
  `cat env/patches/ptf/packet_patch.py >> $SDE_INSTALL/lib/python3.5/site-packages/ptf/packet.py`

  set PKTPY environment variable to False:
    `export PKTPY=False`

---------------------------------------------------------------
## .p4pp Build Artifact:

The .p4pp generated file lives at the root folder of the
extracted tarball.

---------------------------------------------------------------
## Build P4 Program:

The top-level p4-program to be built will reside here:

  `src/`

Build program:

  `./build-it program-name`

ie:

  `./build-it pgm_sp_npb_vcpFw`

Build artifacts can be found here:

  `bld/`

---------------------------------------------------------------
## Run NPB Tests:

All test related files reside here:

  `tst/`

### Window 1 (tofino-model):

  `sudo $SDE_INSTALL/bin/veth_setup.sh`
  
  `$SDE/run_tofino_model.sh --arch tofino2 -p program-name -f /your/path/ports.json`

ie:

  `$SDE/run_tofino_model.sh --arch tofino2 -p pgm_sp_npb_vcpFw -f /your/path/ports.json`


For folded-pipe design, pipes may need to be put into loopback. ie:
  
  `$SDE/run_tofino_model.sh --arch tofino2 -p program-name -f /your/path/ports.json --int-port-loop 0xc`

ie:

  `$SDE/run_tofino_model.sh --arch tofino2 -p pgm_sp_npb_vcpFw -f /your/path/ports.json --int-port-loop 0xc`


### Window 2 (switchd):

  `$SDE/run_switchd.sh --arch tofino2 -p program-name`

ie:

  `$SDE/run_switchd.sh --arch tofino2 -p pgm_sp_npb_vcpFw`


### Window 3

Run single test:
-----------------
Make note of the testname you need to run (ie. test_mau_1hop_s_e)
and include that with the -s argument below (with .test extension).


  `cd $NPB_DP/tst; $SDE/run_p4_tests.sh --arch tofino2 -t . -s test_mau_1hop_s_e.test`

Run regression:
-----------------------

  `cd $NPB_DP/tst; $SDE/run_p4_tests.sh --arch tofino2 -t .`
