#################################################################################
# BAREFOOT NETWORKS CONFIDENTIAL & PROPRIETARY
#
# Copyright (c) 2018-2019 Barefoot Networks, Inc.

# All Rights Reserved.
#
# NOTICE: All information contained herein is, and remains the property of
# Barefoot Networks, Inc. and its suppliers, if any. The intellectual and
# technical concepts contained herein are proprietary to Barefoot Networks,
# Inc.
# and its suppliers and may be covered by U.S. and Foreign Patents, patents in
# process, and are protected by trade secret or copyright law.
# Dissemination of this information or reproduction of this material is
# strictly forbidden unless prior written permission is obtained from
# Barefoot Networks, Inc.
#
# No warranty, explicit or implicit is provided, unless granted under a
# written agreement with Barefoot Networks, Inc.
#
# Milad Sharif (msharif@barefootnetworks.com)
#
###############################################################################

import logging
import sys
import os
import random
import re
#from pprint import pprint

#sys.path.append('$SDE/pkgsrc/ptf-modules/ptf/src/ptf')
if 'vagrant' in os.environ['HOME']:
	sys.path.append('/home/vagrant/barefoot/bf-sde-8.9.0/pkgsrc/ptf-modules/ptf/src/ptf')
else: # docker
	sys.path.append('/bf-sde/pkgsrc/ptf-modules/ptf/src/ptf')

import scapy
from scapy.layers.l2 import *
from scapy.layers.inet import *

from ptf import config, mask
from ptf.thriftutils import *
import ptf.testutils as testutils
from bfruntime_client_base_tests import BfRuntimeTest
import bfrt_grpc.bfruntime_pb2 as bfruntime_pb2
import bfrt_grpc.client as gc
import google.rpc.code_pb2 as code_pb2
from functools import partial

from enum import Enum

from struct import pack
from struct import unpack

from test_mau_tb_tbl_wrap import *
from test_mau_tb_pkt_gen import *

#############################################

logger = logging.getLogger('Test')
if not len(logger.handlers):
	logger.addHandler(logging.StreamHandler())

#############################################
# NPF Stuff
import yaml

sys.path.append('/npb-dp/tools/npf')
#import npf
#from npf_hdr_stacks import HdrStacks

#############################################

swports = []
for device, port, ifname in config["interfaces"]:
	swports.append(port)
	swports.sort()

if swports == []:
	swports = range(9)

def port_to_pipe(port):
	local_port = port & 0x7F
	assert(local_port < 72)
	pipe = (port >> 7) & 0x3
	assert(port == ((pipe << 7) | local_port))
	return pipe

swports_0 = []
swports_1 = []
swports_2 = []
swports_3 = []
# the following method categorizes the ports in ports.json file as belonging to either of the pipes (0, 1, 2, 3)
for port in swports:
	pipe = port_to_pipe(port)
	if pipe == 0:
		swports_0.append(port)
	elif pipe == 1:
		swports_1.append(port)
	elif pipe == 2:
		swports_2.append(port)
	elif pipe == 3:
		swports_3.append(port)

print 'swports:', swports;
print 'swports_0:', swports_0;
print 'swports_1:', swports_1;
print 'swports_2:', swports_2;
print 'swports_3:', swports_3;
