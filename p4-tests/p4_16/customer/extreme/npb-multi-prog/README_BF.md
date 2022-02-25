
# Build and Test Instructions for Intel
---------------------------------------------------------------
## Disclaimer: The instructions below are provided as a
reference only. Your mileage may vary depending on your host
system. We run in a containerized docker environment running
Debian GNU/Linux 9.13 (stretch).

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

## We include a test.json file in the tarball deliverable
(in tst/). This file represents a modified program.conf file
with updated information that our tests use (ie. pipe_scope).
The values in this file may be different than the values the
p4-compiler generates by default. If possible, tofino-model
and switchd should use this test.json as their conf file.
This can be specified via the -c argument to the Intel
run_tofino_model.sh and run_switchd.sh helper scripts.
Another alternative would be to modify the p4-compiler
generated program conf file so its information matches
what's in test.json.

All test related files reside here:

  `tst/`

Paths below for test.json and ports.json reference this
this folder. If you need full-paths to where you extracted
the tarball, then modify the below commands accordingly.

### Window 1 (tofino-model):

  `sudo $SDE_INSTALL/bin/veth_setup.sh`
  
  `$SDE/run_tofino_model.sh --arch tofino2 -p program-name -c tst/test.json -f tst/ports.json`

ie:

  `$SDE/run_tofino_model.sh --arch tofino2 -p pgm_sp_npb_vcpFw -c tst/test.json -f /ports.json`


For folded-pipe design, pipes may need to be put into loopback. ie:
  
  `$SDE/run_tofino_model.sh --arch tofino2 -p program-name -c tst/test.json -f tst/ports.json --int-port-loop 0xc`

ie:

  `$SDE/run_tofino_model.sh --arch tofino2 -p pgm_sp_npb_vcpFw -c tst/test.json -f tst/ports.json --int-port-loop 0xc`


### Window 2 (switchd):

  `$SDE/run_switchd.sh --arch tofino2 -p program-name -c tst/test.json`

ie:

  `$SDE/run_switchd.sh --arch tofino2 -p pgm_sp_npb_vcpFw -c tst/test.json`


### Window 3

Run single test:
-----------------
Make note of the testname you need to run (ie. test_mau_1hop_s_e)
and include that with the -s argument below (with .test extension).

  `cd tst; $SDE/run_p4_tests.sh --arch tofino2 -t . -s test_mau_1hop_s_e.test`

Run all tests:
-----------------------

  `cd tst; $SDE/run_p4_tests.sh --arch tofino2 -t .`
