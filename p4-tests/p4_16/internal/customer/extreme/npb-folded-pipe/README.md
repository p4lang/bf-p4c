# Build and Test Instructions for Intel
Disclaimer: The instructions below are provided as a reference
only. Your mileage may vary depending on your host system. We
run in a containerized docker environment running Debian GNU/
Linux 9.13 (stretch).

## Scapy and PTF:

Our environment is currently running p4lang's ptf:

  `git clone https://github.com/p4lang/ptf.git`

  `cp -rf ptf/src/ptf $SDE_INSTALL/lib/python3.5/site-packages/`

  `cp ptf/ptf $SDE_INSTALL/bin/`
  

Our environment is currently running Scapy v2.4.5:

  `python3 -m pip install --target=$SDE_INSTALL/lib/python3.5/site-packages scapy==2.4.5`


## Setup VM or Container Environment:

Explode tarball:

  `tar xzf extr-2-intel.tgz`

Modify paths in tst/config.py for SDE_INSTALL and TEST_JSON if needed.

Copy tst/ports.json to desired location.

Copy scapy modules (env/patches/scapy/*.py ) into your scapy/contrib folder.

patch ptf packet.py:

  `cat env/patches/ptf/packet_patch.py >> $SDE_INSTALL/lib/python3.5/site-packages/ptf/packet.py`

set PKTPY environment variable to False (since we're using scapy):

  `export PKTPY=False`


## .p4pp Build Artifact:

The generated p4-compiler post-processed (.p4pp) artifact is
provided for convenience. It lives at the root folder of the
extracted tarball.


## Build P4 Program:

The top-level p4-program to be built will reside here:

  `src/`

Build program:

  `./build-it program-name`

Example commands for single-pipe, multi-pipe, and folded-pipe designs:

  `./build-it pgm_sp_npb_vcpFw`

  `./build-it pgm_mp_npb_igOnly_npb_igOnly_npb_igOnly_npb_egOnly`

  `./build-it pgm_fp_npb_dedup_dtel_vcpFw`

Build artifacts can be found here:

  `bld/`


## Run NPB Tests:

We include a test.json file in the tarball deliverable
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

### Setup veth interfaces (if needed):

`sudo $SDE_INSTALL/bin/veth_setup.sh`
  
### Invoke tofino-model (Window 1):

`$SDE/run_tofino_model.sh --arch tofino2 -p program-name -c tst/test.json -f tst/ports.json`

Example commands for single-pipe, multi-pipe, and folded-pipe designs:
Note that folded designs may need to put some pipes into loopback mode.

  `$SDE/run_tofino_model.sh --arch tf2 -p pgm_sp_npb_vcpFw -f ./tst/ports.json -c ./tst/test.json`
  
  `$SDE/run_tofino_model.sh --arch tf2 -p pgm_mp_npb_igOnly_npb_igOnly_npb_igOnly_npb_egOnly -f ./tst/ports.json -c ./tst/test.json`
  
  `$SDE/run_tofino_model.sh --arch tf2 -p pgm_fp_npb_dedup_dtel_vcpFw -f ./tst/ports.json -c ./tst/test.json --int-port-loop 0xc`

### Invoke switchd (Window 2):

  `$SDE/run_switchd.sh --arch tofino2 -p program-name -c tst/test.json`

Example commands for single-pipe, multi-pipe, and folded-pipe designs:

  `$SDE/run_switchd.sh --arch tf2 -p pgm_sp_npb_vcpFw -c ./tst/test.json`
  
  `$SDE/run_switchd.sh --arch tf2 -p pgm_mp_npb_igOnly_npb_igOnly_npb_igOnly_npb_egOnly -c ./tst/test.json`
  
  `$SDE/run_switchd.sh --arch tf2 -p pgm_fp_npb_dedup_dtel_vcpFw -c ./tst/test.json`

### Run Test(s) (Window 3):

#### Run all tests:

`cd tst; $SDE/run_p4_tests.sh --arch tf2 -t . -f ./ports.json`

#### Run single test:

Make note of the testname you need to run (ie. test_mau_1hop_s_e) and
include that with the -s argument below. Be sure and add the .test
file extenstion to the testname as well.

  `cd tst; $SDE/run_p4_tests.sh --arch tf2 -t . -f ./ports.json -s test_mau_1hop_s_e.test`
