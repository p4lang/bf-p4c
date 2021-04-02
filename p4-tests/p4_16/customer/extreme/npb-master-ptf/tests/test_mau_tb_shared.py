import logging
import sys
import os
import random
import re
#from pprint import pprint

import packet as scapy

from ptf import config
from ptf.thriftutils import *
import ptf.testutils as testutils

from enum import Enum

################################################################################
# Common Functions
################################################################################

g_is_tofino = testutils.test_param_get("arch") == "tofino"
g_is_tofino2 = testutils.test_param_get("arch") == "tofino2"
assert g_is_tofino or g_is_tofino2

if g_is_tofino:
	# Tofino 1 settings!
	TOFINO_1          = True;
	BRIDGING_ENABLE   = False;
	TRANSPORT_ENABLE  = False;
	SFF_SCHD_SIMPLE   = True;
	CPU_ENABLE        = True;
	ETAG_ENABLE       = True;
	VNTAG_ENABLE      = True;
	PROFILE_BETA      = False; # must be set true  for beta release
	SPLIT_EG_PORT_TBL = False; # must be set false for beta release
elif g_is_tofino2:
	# Tofino 2 settings!
	TOFINO_1          = False;
	BRIDGING_ENABLE   = True;
	TRANSPORT_ENABLE  = False;
	SFF_SCHD_SIMPLE   = False;
	CPU_ENABLE        = True;
	ETAG_ENABLE       = True;
	VNTAG_ENABLE      = True;
	PROFILE_BETA      = False; # must be set true  for beta release
	SPLIT_EG_PORT_TBL = True;  # must be set false for beta release

#############################################

class IngressTunnelType(Enum):
	# these must match what is in the p4 code.
	NONE        = 0;
	VXLAN       = 1;
	IPINIP      = 2;
	NSH         = 3;
	NVGRE       = 4;
	GTPC        = 5;
	GTPU        = 6;
	ERSPAN      = 7;
	GRE         = 8;

class EgressTunnelType(Enum):
	# these are arbitrary, and don't need to match anything in the p4 code.
	NONE        = 0;
	IPV4_VXLAN  = 1;
	IPV6_VXLAN  = 2;
	IPV4_IPIP   = 3;
	IPV6_IPIP   = 4;
	NSH         = 5;
	IPV4_NVGRE  = 6;
	IPV6_NVGRE  = 7;
	IPV4_ERSPAN = 8;
	IPV6_ERSPAN = 9;
	IPV4_GRE    = 10;
	IPV6_GRE    = 11;

#######################################

def popcount(x): return bin(x).count('1')
