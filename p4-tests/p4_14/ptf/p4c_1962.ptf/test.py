# Copyright 2013-present Barefoot Networks, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

"""
Simple PTF test for p4c_1962
"""
import pdb
import pd_base_tests
import ptf

from ptf import config
from ptf.testutils import *
from ptf.thriftutils import *

# Change the line below, using the name of your program
from p4c_1962.p4_pd_rpc.ttypes import *
from res_pd_rpc.ttypes import *

#
# Defining the header format for the tests
#
from scapy.all import *
predicate_fields = [
            BitField("pad", 0, 4),
            BitField("res", 0, 4),
            ]

reg_width = test_param_get("reg_width", 16)
if reg_width == 8:
    field_class = ByteField
elif reg_width == 16:
    field_class = ShortField
elif reg_width == 32:
    field_class == IntField
else:
    assert(reg_width == 8 or reg_width == 16 or reg_width == 32)
    
class H(Packet):
    name = "h_t ({})".format(reg_width)
    fields_desc = [
        field_class("hi", 0),
        field_class("lo", 0)
        ] + predicate_fields
    
def cond_to_predicate(cond_hi, cond_lo):
    shift = (int(cond_hi) << 1) + int(cond_lo)
    return 1 << shift

#
# Base class
#
class TestGroup1(pd_base_tests.ThriftInterfaceDataPlane):
    def __init__(self):
        # Change the line below, using the name of your program
        pd_base_tests.ThriftInterfaceDataPlane.__init__(self, ["p4c_1962"])

    # The setUp() method is used to prepare the test fixture. Typically
    # you would use it to establich connection to the Thrift server.
    #
    # You can also put the initial device configuration there. However,
    # if during this process an error is encountered, it will be considered
    # as a test error (meaning the test is incorrect),
    # rather than a test failure
    def setUp(self):
        pd_base_tests.ThriftInterfaceDataPlane.setUp(self)

        self.sess_hdl = self.conn_mgr.client_init()
        self.dev      = 0
        self.dev_tgt  = DevTarget_t(self.dev, hex_to_i16(0xFFFF))
        # Create a list of all ports available on the device
        self.swports = []
        for (device, port, ifname) in ptf.config['interfaces']:
            self.swports.append(port)
        self.swports.sort()

        print("\n")
        print("Test Setup")
        print("==========")
        print("    Connected to Device %d, Session %d" % (
            self.dev, self.sess_hdl))

        print
        
    # Use tearDown() method to return the DUT to the initial state by cleaning
    # all the configuration and clearing up the connection
    def tearDown(self):
        print("\n")
        print("Test Cleanup:")
        print("=============")
        self.conn_mgr.complete_operations(self.sess_hdl)
        self.conn_mgr.client_cleanup(self.sess_hdl)
        print("    Closed Session %d" % self.sess_hdl)
        pd_base_tests.ThriftInterfaceDataPlane.tearDown(self)

    def testPredicate(self, cond_hi, cond_lo):
        ingress_port = self.swports[test_param_get("ingress_port", 0)]
        egress_port  = self.swports[test_param_get("egress_port", 0)]
        hi_thresh    = test_param_get("hi_thresh", 10) # See program
        lo_thresh    = test_param_get("lo_thresh", 10) # See program          
        payload      = test_param_get("payload",   "A"*64)
        
        print("\n")
        print("Test Run:")
        print("=========")
        
        if cond_hi:
            hi = hi_thresh - 1
        else:
            hi = hi_thresh
        if cond_lo:    
            lo = lo_thresh - 1
        else:
            lo = lo_thresh
            
        print("Sending packet with HI={} and LO={}".format(hi, lo))
        send_pkt = H(hi=hi, lo=lo)/Raw(payload)
        send_packet(self, ingress_port, send_pkt)
        
        print("Expecting the packet with COND_HI={} and COND_LO={} ({})".
              format(cond_hi, cond_lo, cond_to_predicate(cond_hi, cond_lo)))

        exp_pkt = copy.deepcopy(send_pkt)
        exp_pkt[H].res = cond_to_predicate(cond_hi, cond_lo)
        verify_packet(self, exp_pkt, egress_port)
        print("Packet received of port {} with res={}".
              format(egress_port, exp_pkt[H].res))

############################################################################
################# I N D I V I D U A L    T E S T S #########################
############################################################################

class True_True(TestGroup1):
    def runTest(self):
        self.testPredicate(True, True)

class True_False(TestGroup1):
    def runTest(self):
        self.testPredicate(True, False)

class False_True(TestGroup1):
    def runTest(self):
        self.testPredicate(False, True)

class False_False(TestGroup1):
    def runTest(self):
        self.testPredicate(False, False)

        
