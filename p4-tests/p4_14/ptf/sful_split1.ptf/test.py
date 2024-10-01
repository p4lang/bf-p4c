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
Simple PTF test for sful_split1
"""
import pdb
import pd_base_tests
import ptf

from ptf import config
from ptf.testutils import *
from ptf.thriftutils import *

# Change the line below, using the name of your program
from sful_split1.p4_pd_rpc.ttypes import *
from res_pd_rpc.ttypes import *

#
# Defining the header format for the tests
#
from scapy.all import *
predicate_fields = [
            BitField("idx", 0, 8),
            BitField("op1", 0, 4),
            BitField("op2", 0, 4),
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
        field_class("lo", 0),
        field_class("res", 0)
        ] + predicate_fields
    
#
# Base class
#
class TestGroup1(pd_base_tests.ThriftInterfaceDataPlane):
    def __init__(self):
        # Change the line below, using the name of your program
        pd_base_tests.ThriftInterfaceDataPlane.__init__(self, ["sful_split1"])

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
        self.pipe     = 0
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

    def testLoop(self, op1, op2, idx, v, init, count):
        ingress_port = self.swports[test_param_get("ingress_port", 0)]
        egress_port  = self.swports[test_param_get("egress_port", 0)]
        payload      = test_param_get("payload",   ("A"*64))

        print("Sending {} packets with idx={} op1={} op2={}".format(count, idx, op1, op2))
        for p in range(0,count):
            send_pkt = H(lo=v, idx=idx, op1=op1, op2=op2)/Raw(payload)
            send_packet(self, ingress_port, send_pkt)
            exp_pkt = copy.deepcopy(send_pkt)
            exp_pkt[H].res = init
            verify_packet(self, exp_pkt, egress_port)
            if (op2 < 4):
                init = (init - v) & 0xffff
            elif (op2 >= 8):
                init = (init + v) & 0xffff
            else:
                init = 0

############################################################################
################# I N D I V I D U A L    T E S T S #########################
############################################################################

class Test1(TestGroup1):
    def runTest(self):
        self.testLoop(1, 10, 2, 5, 0, 3)
        self.assertEqual(self.client.register_read_r1(self.sess_hdl, self.dev_tgt, 2, sful_split1_register_flags_t(read_hw_sync = True))[self.pipe], 15)
        self.testLoop(10, 1, 2, 5, 15, 3)

