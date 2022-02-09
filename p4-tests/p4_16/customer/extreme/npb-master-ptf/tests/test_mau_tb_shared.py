import logging
import sys
import os
import random
import re
from pprint import pprint

####### PTF MODULE IMPORTS #######
import ptf
from   ptf.mask import Mask
#from   ptf.testutils import *
import ptf.testutils as testutils
#from   scapy.all     import *
import ptf.packet    as scapy

####### PTF modules for BFRuntime Client Library APIs #######
import grpc
import bfrt_grpc.bfruntime_pb2 as bfruntime_pb2
import bfrt_grpc.client        as gc
from   bfruntime_client_base_tests import BfRuntimeTest

####### PTF modules for Fixed APIs (Thrift) #######
import pd_base_tests
from   ptf.thriftutils import *
from   res_pd_rpc      import * # Common data types
from   mc_pd_rpc       import * # Multicast-specific data types
from   mirror_pd_rpc   import * # Mirror-specific data types

####### Additional imports #######
import pdb # To debug insert pdb.set_trace() anywhere

from enum import Enum

################################################################################
# Common Functions
################################################################################

class PipelineParams():
	g_is_tofino = testutils.test_param_get("arch") == "tofino"
	g_is_tofino2 = testutils.test_param_get("arch") == "tofino2"
	assert g_is_tofino or g_is_tofino2

	if g_is_tofino:
		# Tofino 1 settings!
		TOFINO_1                 = True;
		BRIDGING_ENABLE          = False;
		TRANSPORT_ENABLE         = False;
		SFF_SCHD_SIMPLE          = True;
		CPU_ENABLE               = True;
		ETAG_ENABLE              = True;
		VNTAG_ENABLE             = True;
		CPU_HDR_CONTAINS_EG_PORT = True;
		SPLIT_EG_PORT_TBL        = False;
	elif g_is_tofino2:
		# Tofino 2 settings!
		TOFINO_1                 = False;
		BRIDGING_ENABLE          = True;
		TRANSPORT_ENABLE         = False;
		SFF_SCHD_SIMPLE          = True;
		CPU_ENABLE               = True;
		ETAG_ENABLE              = True;
		VNTAG_ENABLE             = True;
		CPU_HDR_CONTAINS_EG_PORT = True;
		SPLIT_EG_PORT_TBL        = False;

#############################################

class PktSrc(Enum):
	BRIDGED        = 0;
	CLONED_INGRESS = 1;
	CLONED_EGRESS  = 2;
	DEFLECTED      = 3;

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
	VLAN        = 9;
	MPLS        = 10;
	UNSUPPORTED = 11;
	GENEVE      = 12;

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
	IPV4_UDP    = 12;
	IPV6_UDP    = 13;
	DTEL_FLOW_REPORT  = 14;
	DTEL_QUEUE_REPORT = 15;

#######################################

class DtelReportType(Enum):
	NONE            =      0b000;
	FLOW            =      0b001;
	QUEUE           =      0b010;
	DROP            =      0b100;

	SUPPRESS        =     0b1000;
	IFA_CLONE       =    0b10000;
	IFA_EDGE        =   0b100000;
	ETRAP_CHANGE    =  0b1000000;
	ETRAP_HIT       = 0b10000000;

#######################################

def popcount(x): return bin(x).count('1')

