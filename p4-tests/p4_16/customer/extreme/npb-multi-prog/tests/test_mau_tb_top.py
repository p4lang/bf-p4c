import logging
import sys
import os
import random
import re

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
# Pull-in program and deployment specific details (via test.json)

import json
from pprint import pprint

from config import *
cfile = os.path.join(TEST_JSON_PATH, "test.json")
assert os.path.isfile(cfile), \
    "ERROR: Test configuration file (%s) not found." %cfile

print("Loading Generated Test Configuration File: (%s)" %cfile)
cfg = json.load(open(cfile))

#assert len(cfg['p4_devices'][0]['p4_programs'][0]['p4_pipelines']) == 1, \
#        "ERROR: test.json contains more than one pipeline definition."

p4_name  = cfg['p4_devices'][0]['p4_programs'][0]['p4_name']

iprsr_s    = ["","","",""]
ictl_s     = ["","","",""]
idprsr_s   = ["","","",""]
eprsr_s    = ["","","",""]
ectl_s     = ["","","",""]
edprsr_s   = ["","","",""]
#iprsr_s    = []
#ictl_s     = []
#idprsr_s   = []
#eprsr_s    = []
#ectl_s     = []
#edprsr_s   = []
params_bool_s = []
params_int_s = []
ig_pipes = []
eg_pipes = []
eg_pipes_idx = []
ig_swports = []
eg_swports = []

for pip in cfg['p4_devices'][0]['p4_programs'][0]['p4_pipelines']:
    pipe = pip['pipe_scope'][0]
    #print("pipe = ", pipe)
    iprsr_s[pipe] = pip['bfrt_prefixes']['iprsr']
    ictl_s[pipe] = pip['bfrt_prefixes']['ictl']
    idprsr_s[pipe] = pip['bfrt_prefixes']['idprsr']
    eprsr_s[pipe] = pip['bfrt_prefixes']['eprsr']
    ectl_s[pipe] = pip['bfrt_prefixes']['ectl']
    #edprsr_s[pipe] = pip['bfrt_prefixes']['edprsr']
    #iprsr_s.append(pip['bfrt_prefixes']['iprsr'])
    #ictl_s.append(pip['bfrt_prefixes']['ictl'])
    #idprsr_s.append(pip['bfrt_prefixes']['idprsr'])
    #eprsr_s.append(pip['bfrt_prefixes']['eprsr'])
    #ectl_s.append(pip['bfrt_prefixes']['ectl'])
    #edprsr_s.append(pip['bfrt_prefixes']['edprsr'])
    params_bool_s.append(pip['params_bool'])
    params_int_s.append(pip['params_int'])
    if(not pip['eg_only_flag']):
        ig_pipes.append(pip['pipe_scope'][0])
    else:
        eg_pipes.append(pip['pipe_scope'][0])
        eg_pipes_idx.append(pip['inst_idx'])


    ''' NEED TO WORK ON FOLDED PIPE CONFIG
    if  pip['folded_flag']: 
            #Non Folded pipe
            iprsr_F  = iprsr
            ictl_F   = ictl
            idprsr_F = idprsr
            eprsr_F  = eprsr
            ectl_F   = ectl
            edprsr_F = edprsr
            params_bool_F = params_bool
            params_int_F = params_int
    '''
    ''''
    else:
            print("ERROR: test.json contains an illegal value for top-"
                  "level instance index (%s)" %pip['inst_idx'])
            sys.exit(1)
    '''


#If no egress only pipes then just set the egress pipe to the current pipe_scope
if(len(eg_pipes)==0):
   print("No Egress only pipes detected")
   eg_pipes = ig_pipes
   eg_pipes_idx.append(pip['inst_idx'])
   #params_bool_s = params_bool_s[pip['inst_idx']]
   #params_int_s = params_int_s[pip['inst_idx']]

params_bool = params_bool_s[pip['inst_idx']]
params_int = params_int_s[pip['inst_idx']]

#How do we tell if this is a program test or a pipeline test?
if(len(ig_pipes) == 1):

    print("Pipeline Test Configuration:")
    print("-----------------------------------------------------")
    print("P4_Name: %s" %p4_name)
    print("Deployment Profile: %s" %pip['deploy_name'])
    print("Top-Level Instance Name: %s" %pip['p4_pipeline_name'])
    print("Top-Level Instance Index: %s" %pip['inst_idx'])
    print("Pipe Scope: %s" %pip['pipe_scope'])
    print("Folded Flag: %s" %pip['folded_flag'])
    print("Egress-Only Flag: %s" %pip['eg_only_flag'])
    print("Ingress Pipe(s): %s" %ig_pipes)
    print("Egress Pipe(s): %s" %pip['pipes_eg'])
    print("BF-RT Prefixes:")
    pprint(pip['bfrt_prefixes'])
    #print("Features:")
    #pprint(params_bool)
    #pprint(params_int)

    print ("iprsr", iprsr_s)
    print ("ictl", ictl_s)
    print ("idprsr", idprsr_s)
    print ("eprsr", eprsr_s)
    print ("ectl", ectl_s)
    print ("edprsr", edprsr_s)
    
else:
    print("Program Test Configuration:")
    print("-----------------------------------------------------")
    print("P4_Name: %s" %p4_name)
    print("Deployment Profile: %s" %pip['deploy_name'])
    print("Top-Level Instance Name: %s" %pip['p4_pipeline_name'])
    print("Top-Level Instance Index: %s" %pip['inst_idx'])
    print("Pipe Scope: %s" %pip['pipe_scope'])
    print("Folded Flag: %s" %pip['folded_flag'])
    print("Ingress Pipe(s): %s" %ig_pipes)
    print("Egress Pipe(s): %s" %eg_pipes)
    print("BF-RT Prefixes:")
    pprint(pip['bfrt_prefixes'])
    #print("Features:")
    #pprint(params_bool_s)
    #pprint(params_int_s)
    
    print ("iprsr_s", iprsr_s)
    print ("ictl_s", ictl_s)
    print ("idprsr_s", idprsr_s)
    print ("eprsr_s", eprsr_s)
    print ("ectl_s", ectl_s)
    print ("edprsr_s", edprsr_s)
    
################################################################################

swports = []
recircports = []
for device, port, ifname in config["interfaces"]:
	swports.append(port)
	swports.sort()

if len(swports) == 4:  # HW
    recircports = [1] # pipe[0] on HW
    ig_swports = [swports, [], [], []]
    eg_swports = swports
    
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

    recircports = [1, 129, 257, 385]
    swports1 = swports[:-12]
    swports1 = swports1[::-1] # reverse order so cpu port at end
    swports2 = swports[-12:-8]
    swports2 = swports2[::-1] # reverse order so cpu port at end
    swports3 = swports[-8:-4]
    swports3 = swports3[::-1] # reverse order so cpu port at end
    swports4 = swports[-4:]
    swports4 = swports4[::-1] # reverse order so cpu port at end

    ig_swports = [swports1, swports2, swports3, swports4]

    #Need to reverse order so cpu at end?

    #print("EGPIPES = ", eg_pipes[0])
#This will need more work if we need to support more than 1 Egress port
    if eg_pipes[0] == 0:
        eg_swports = swports[:-12]
    elif  eg_pipes[0] == 1:
        eg_swports = swports[-12:-8]
    elif eg_pipes[0]  == 2:
        eg_swports = swports[-8:-4]
    elif eg_pipes[0] == 3:
        eg_swports = swports[-4:]
    eg_swports = eg_swports[::-1]

#print("EG_PIPES_IDX = ", eg_pipes_idx[0])
ectl = ectl_s[ eg_pipes[0]]
ectl_F = ectl_s[eg_pipes[0]]
#print("ECTL = ", ectl)



#print('ig_swports:', ig_swports)
#print('eg_swports:', eg_swports)
#print('recircports:', recircports)



################################################################################
# Pull in all table names so they can be clean at test startup

BFRT_JSON_PATH = cfg['p4_devices'][0]['p4_programs'][0]['bfrt-config']
bfrt_file = os.path.join(SDE_INSTALL_PATH, BFRT_JSON_PATH)

print("Loading BF-RT File: (%s)" %bfrt_file)
assert os.path.isfile(bfrt_file), \
    "ERROR: BF-RT file (%s) not found." %bfrt_file

bfrt_dict = json.load(open(bfrt_file))


all_tables = []

for btbl in bfrt_dict['tables']:
    #print(btbl['name'])
    all_tables.append(btbl['name'])
