import logging
import sys
import os
import random
import re
#from pprint import pprint

##sys.path.append('/usr/local/lib/python3.5/dist-packages/ptf')        
#sys.path.append('/bf-sde/install/lib/python3.5/site-packages/ptf')

####### PTF MODULE IMPORTS #######
import ptf
from   ptf.mask import Mask
from   ptf import config
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

from struct import pack
from struct import unpack

#############################################

logger = logging.getLogger('Test')
if not len(logger.handlers):
	logger.addHandler(logging.StreamHandler())

################################################################################
# Pull-in program and deployment specific details

import json
from pprint import pprint

BF_P4C_PATH = os.path.abspath(os.path.dirname(__file__)).replace('/p4c/extensions/p4_tests/p4_16/customer/extreme/npb-master-ptf/tests', '')
cfile = os.path.join(BF_P4C_PATH, "p4-tests/p4_16/customer/extreme/npb-master-ptf/tests/test.json")
assert os.path.isfile(cfile), \
    "ERROR: Test configuration file (%s) not found." %cfile

print("Loading Generated Test Configuration File: (%s)" %cfile)
cfg = json.load(open(cfile))

assert len(cfg['p4_devices'][0]['p4_programs'][0]['p4_pipelines']) == 1, \
        "ERROR: test.json contains more than one pipeline definition."

p4_name  = cfg['p4_devices'][0]['p4_programs'][0]['p4_name']
pip      = cfg['p4_devices'][0]['p4_programs'][0]['p4_pipelines'][0]
iprsr    = pip['bfrt_prefixes']['iprsr']
ictl     = pip['bfrt_prefixes']['ictl']
idprsr   = pip['bfrt_prefixes']['idprsr']
eprsr    = pip['bfrt_prefixes']['eprsr']
ectl     = pip['bfrt_prefixes']['ectl']
edprsr   = pip['bfrt_prefixes']['edprsr']
deploy_features = pip['deploy_features']

print("Test Configuration:")
print("-----------------------------------------------------")
print("P4_Name: %s" %p4_name)
print("Deployment Profile: %s" %pip['deploy_name'])
print("Top-Level Instance Name: %s" %pip['p4_pipeline_name'])
print("Top-Level Instance Index: %s" %pip['inst_idx'])
print("Pipe Scope: %s" %pip['pipe_scope'])
print("Folded Flag: %s" %pip['folded_flag'])
print("BF-RT Prefixes:")
pprint(pip['bfrt_prefixes'])
print("Features:")
pprint(deploy_features)

################################################################################

swports = []
recircports = []
for device, port, ifname in config["interfaces"]:
	swports.append(port)
	swports.sort()
# 
# if swports == []:
# 	swports = range(9)
# 
# def port_to_pipe(port):
# 	local_port = port & 0x7F
# 	assert(local_port < 72)
# 	pipe = (port >> 7) & 0x3
# 	assert(port == ((pipe << 7) | local_port))
# 	return pipe
# 
# swports_0 = []
# swports_1 = []
# swports_2 = []
# swports_3 = []
# # the following categorizes the ports in ports.json based on pipe (0, 1, 2, 3)
# for port in swports:
# 	pipe = port_to_pipe(port)
# 	if pipe == 0:
# 		swports_0.append(port)
# 	elif pipe == 1:
# 		swports_1.append(port)
# 	elif pipe == 2:
# 		swports_2.append(port)
# 	elif pipe == 3:
# 		swports_3.append(port)
# 
# print('swports:', swports)
# print('swports_0:', swports_0)
# print('swports_1:', swports_1)
# print('swports_2:', swports_2)
# print('swports_3:', swports_3)

if len(swports) == 4:  # hw
    pass  # just use swports loaded from ports.json
else:            
    # Create a swports array based on pipe
    # Currently this is being carved up as follows for tofino model simultations:
    #
    # swports = [2, 48, 50, 52, 54, 152, 154, 156, 158, 304, 306, 308, 310, 408, 410, 412, 414]
    #
    # pipe[0]:  swports = [ 54,  52,  50,  48, 2]
    # pipe[1]:  swports = [158, 156, 154, 152   ]
    # pipe[2]:  swports = [310, 308, 306, 304   ]
    # pipe[3]:  swports = [414, 412, 410, 408   ]            
    if pip['pipe_scope'][0] == 0:
        swports = swports[:-12]
        recircports = [1]
    elif pip['pipe_scope'][0] == 1:
        swports = swports[-12:-8]
        recircports = [129]
    elif pip['pipe_scope'][0] == 2:
        swports = swports[-8:-4]
        recircports = [257]
    elif pip['pipe_scope'][0] == 3:
        swports = swports[-4:]
        recircports = [385]
    swports = swports[::-1] # reverse order so cpu port at end

print('swports:', swports)
print('recircports:', recircports)

################################################################################
