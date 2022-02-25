import logging
import sys
import os
import random
import re
from pprint import pprint

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

# ------------------------------------------------------------------------------
# Load Test configuration file (test.json)

import json
from config import *

f = os.path.join(TEST_JSON_PATH, "test.json")
assert os.path.isfile(f), "ERROR: Test configuration file (%s) not found." %f
print("Loading test configuration file: (%s)" %f)
cfg = json.load(open(f))

# ------------------------------------------------------------------------------
# Resolve which pipes are being tested

p4_program = cfg['p4_devices'][0]['p4_programs'][0]
p4_name  = p4_program['p4_name']
test_pipe_of_interest = int(p4_program['test_pipe_of_interest'])

program_level_test_flag = test_pipe_of_interest == 99
pipeline_level_test_flag = 0 <= int(test_pipe_of_interest) <= 3                       
assert program_level_test_flag or pipeline_level_test_flag, \
        logger.error("Illegal value for test_pipe_of_interest in test.json")

# define per-pipe arrays
iprsr_s             = ["","","",""]
ictl_s              = ["","","",""]
idprsr_s            = ["","","",""]
eprsr_s             = ["","","",""]
ectl_s              = ["","","",""]
edprsr_s            = ["","","",""]
deploy_name_s       = ["","","",""]
params_bool_s       = ["","","",""]
params_int_s        = ["","","",""]
p4_pipeline_name_s  = ["","","",""]
inst_idx_s          = ["","","",""]
pipe_scope_s        = ["","","",""]
folded_flag_s       = ["","","",""]
eg_only_flag_s      = ["","","",""]

# pipes to be tested
ig_pipes = []
eg_pipes = []

# loop through each pipeline present in test.json
for i, pip in enumerate(p4_program['p4_pipelines']):
        
    # populate per-pipe arrays (based on pipe-scope)
    logger.info("Configuration (test.json) pipeline loop iteration %d"
                " (pipe_scope=%s)" %(i, pip['pipe_scope']))
    logger.info("  populating pipe array location %s (pipe_scope[0])"
                %pip['pipe_scope'][0])
    pipe = pip['pipe_scope'][0]
    iprsr_s[pipe] = pip['bfrt_prefixes']['iprsr']
    ictl_s[pipe] = pip['bfrt_prefixes']['ictl']
    idprsr_s[pipe] = pip['bfrt_prefixes']['idprsr']
    eprsr_s[pipe] = pip['bfrt_prefixes']['eprsr']
    ectl_s[pipe] = pip['bfrt_prefixes']['ectl']
    deploy_name_s[pipe]= pip['deploy_name']
    params_bool_s[pipe]= pip['params_bool']
    params_int_s[pipe]= pip['params_int']
    p4_pipeline_name_s[pipe]= pip['p4_pipeline_name']
    inst_idx_s[pipe]= pip['inst_idx']
    pipe_scope_s[pipe]= pip['pipe_scope']
    folded_flag_s[pipe]= pip['folded_flag']
    eg_only_flag_s[pipe]= pip['eg_only_flag']

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
    
    # configure pipes to be tested
    if pipeline_level_test_flag \
       and (test_pipe_of_interest == int(pip['pipe_scope'][0])):
            
        logger.info("Resolving which pipe(s) are to be tested.")
        logger.info("  pipeline-level test: pipeline of interest = %d"
                    %test_pipe_of_interest)
        ig_pipes.append(pip['pipe_scope'][0])
        eg_pipes = ig_pipes

    elif program_level_test_flag:
        logger.info("Resolving which pipes are to be tested.")
        logger.info("  program-level test: Test all pipelines.")

        if pip['eg_only_flag']:
            eg_pipes.append(pip['pipe_scope'][0])
        else:
            ig_pipes.append(pip['pipe_scope'][0])
        
    #else:  # should never get here


# If no egress-only pipes at all, just set the egr pipe to current pipe_scope
if(len(eg_pipes)==0):
   logger.info("No egress-only pipes detected, setting egr pipes to ing pipes.")
   eg_pipes = ig_pipes

# ------------------------------------------------------------------------------
   
print()
logger.info("Resolved Test Configuration:")
logger.info("-----------------------------------------------------")

if program_level_test_flag:

    logger.info("Test-Type: Program-level")
    logger.info("Deployment Profile: %s" %deploy_name_s)
    logger.info("Top-Level Instance Name: %s" %p4_pipeline_name_s)
    logger.info("Top-Level Instance Index: %s" %inst_idx_s)
    logger.info("Pipe Scope: %s" %pipe_scope_s)
    logger.info("Folded Flag: %s" %folded_flag_s)
    logger.info("Egress-Only Flag: %s" %eg_only_flag_s)
    
    logger.info("BF-RT Prefixes:")
    logger.info("  iprsr_s: %s" %iprsr_s)
    logger.info("  ictl_s: %s" %ictl_s)
    logger.info("  idprsr_s: %s" %idprsr_s)
    logger.info("  eprsr_s: %s" %eprsr_s)
    logger.info("  ectl_s: %s" %ectl_s)
    logger.info("  edprsr_s: %s" %edprsr_s)
    #logger.info("Features:")
    #pprint(params_bool_s)
    #pprint(params_int_s)
    logger.info("Ingress Pipe(s) being tested: %s" %ig_pipes)
    logger.info("Egress Pipe(s) being tested: %s" %eg_pipes)
    
else:
    logger.info("Test-Type: Pipeline-level")
    logger.info("Pipe of interest: %d" %test_pipe_of_interest)
    logger.info("Deployment Profile: %s" %deploy_name_s[test_pipe_of_interest])
    logger.info("Top-Level Instance Name: %s" %p4_pipeline_name_s[test_pipe_of_interest])
    logger.info("Top-Level Instance Index: %s" %inst_idx_s[test_pipe_of_interest])
    logger.info("Pipe Scope: %s" %pipe_scope_s[test_pipe_of_interest])
    logger.info("Folded Flag: %s" %folded_flag_s[test_pipe_of_interest])
    logger.info("Egress-Only Flag: %s" %eg_only_flag_s[test_pipe_of_interest])
    
    logger.info("BF-RT Prefixes:")
    logger.info("  iprsr: %s" %iprsr_s[test_pipe_of_interest])
    logger.info("  ictl: %s" %ictl_s[test_pipe_of_interest])
    logger.info("  idprsr: %s" %idprsr_s[test_pipe_of_interest])
    logger.info("  eprsr: %s" %eprsr_s[test_pipe_of_interest])
    logger.info("  ectl: %s" %ectl_s[test_pipe_of_interest])
    logger.info("  edprsr: %s" %edprsr_s[test_pipe_of_interest])
    #logger.info("Features:")
    #pprint(params_bool_s[test_pipe_of_interest])
    #pprint(params_int_s[test_pipe_of_interest])
    logger.info("Ingress Pipe being tested: %s" %ig_pipes)
    logger.info("Egress Pipe being tested: %s" %eg_pipes)
    

# ------------------------------------------------------------------------------
# Resolve ports

swports = []
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
