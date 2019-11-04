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
Simple PTF test for simple_l3
"""
import pdb
import pd_base_tests

from ptf import config
from ptf.testutils import *
from ptf.thriftutils import *

# Change the line below, using the name of your program
from case5577.p4_pd_rpc.ttypes import *
from mirror_pd_rpc.ttypes import *
from res_pd_rpc.ttypes import *

class TestGroup1(pd_base_tests.ThriftInterfaceDataPlane):
    def __init__(self):
        # Change the line below, using the name of your program
        pd_base_tests.ThriftInterfaceDataPlane.__init__(self, ["case5577"])

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

        print("\n")
        print("Test Setup")
        print("==========")
        print("    Connected to Device %d, Session %d" % (
            self.dev, self.sess_hdl))

        #
        # This is an optional default setup that is used by the teardown()
        # method.es
        # Every time you add an entry to a table "t" append its handle to
        # self.entries["t"].
        # Every time you add a member to an action profile "p" append
        # its handle to self.members["p"]
        # Every time you create a new group in action selector "s", append
        # its handle to self.groups["s"]
        self.entries={}
        self.groups={}
        self.members={}

        # Another useful thing that can be done here is setting the
        # default actions on the tables
        self.client.set_output_set_default_action_set_output(
            self.sess_hdl, self.dev_tgt)

        self.client.clone_set_default_action_clone(
            self.sess_hdl, self.dev_tgt)

        # Program the mirror destination 1 (as per program)
        mirror_session = MirrorSessionInfo_t(
            mir_id=1,
            direction=Direction_e.PD_DIR_EGRESS,
            mir_type=MirrorType_e.PD_MIRROR_TYPE_NORM,
            egr_port=3, egr_port_v=1,
            max_pkt_len=9216)
        self.mirror.mirror_session_create(self.sess_hdl, self.dev_tgt, mirror_session)
        
        # Always make sure the programming gets dow to the HW
        self.conn_mgr.complete_operations(self.sess_hdl)
        print
        
    # Use tearDown() method to return the DUT to the initial state by cleaning
    # all the configuration and clearing up the connection
    def tearDown(self):
        print("\n")
        print("Test Cleanup:")
        print("=============")
        try:
            print("  Clearing Table Entries")
            for table in self.entries.keys():
                delete_func = "self.client." + table + "_table_delete"
                for entry in self.entries[table]:
                    exec delete_func + "(self.sess_hdl, self.dev, entry)"

            print("  Clearing Selector Groups")
            for selector in self.groups.keys():
                delete_func="self.client" + selector + "_del_group"
                for group in self.groups[selector]:
                    exec delete_func + "(self.sess_hdl, self.dev, group)"

            print("  Clearing Action Profile Members")
            for action_profile in self.members.keys():
                delete_func="self.client" + action_profile + "del_member"
                for member in self.members[actoin_profile]:
                    exec delete_func + "(self.sess_hdl, self.dev, member)"
        except:
            print("  Error while cleaning up. ")
            print("  You might need to restart the driver")
        finally:
            self.conn_mgr.complete_operations(self.sess_hdl)
            self.conn_mgr.client_cleanup(self.sess_hdl)
            print("  Closed Session %d" % self.sess_hdl)
            pd_base_tests.ThriftInterfaceDataPlane.tearDown(self)

#
# Individual tests can now be subclassed from TestGroup1
#

############################################################################
################# I N D I V I D U A L    T E S T S #########################
############################################################################

from scapy.all import *

class Test1(TestGroup1):
    # This method represents the test itself. Typically you would want to
    # configure the device (e.g. by populating the tables), send some
    # traffic and check the results.
    #
    # For more flexible checks, you can import unittest module and use
    # the provided methods, such as unittest.assertEqual()
    #
    # Do not enclose the code into try/except/finally -- this is done by
    # the framework itself
    def runTest(self):
        # Test Parameters
        ipv4_dst     = "192.168.1.1"
        ingress_port = 0
        egress_port  = 3
        
        print("Sending packet with IPv4 DST ADDR=%s into port %d" %
              (ipv4_dst, ingress_port))

        pkt = (Ether(dst="00:98:76:54:32:10", src="00:55:55:55:55:55") /
               IP(dst="192.168.1.1", src="192.168.1.2") /
               TCP(sport=1234, dport=80) /
               "My Test Payload")
        test_pkt = Ether(str(pkt))
        
        send_packet(self, ingress_port, test_pkt)
        print("Expecting the packet to be forwarded to port %d" % egress_port)
        verify_packet(self, test_pkt, egress_port)
        print("Packet received of port %d" % egress_port)
        

