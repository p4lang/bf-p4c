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
Simple PTF test for decaf_10
"""
import pdb
import pd_base_tests

from ptf import config
from ptf.testutils import *
from ptf.thriftutils import *

# Change the line below, using the name of your program
from decaf_10.p4_pd_rpc.ttypes import *
from res_pd_rpc.ttypes import *

# Import Mirror API Data types separately
from mirror_pd_rpc.ttypes import *

# Import Scapy to create packets easily
from scapy.all import *

class TestGroup1(pd_base_tests.ThriftInterfaceDataPlane):
    def __init__(self):
        # Change the line below, using the name of your program
        pd_base_tests.ThriftInterfaceDataPlane.__init__(self, ["decaf_10"])

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
        # method.
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
        self.client.push_vlan_set_default_action_push_vlan(
            self.sess_hdl, self.dev_tgt)

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

            print("  Clearing Mirror Sessions")
            for mir_sess in self.mirror_sessions:
                self.mirror.mirror_session_delete(
                    self.sess_hdl, self.dev_tgt, mir_sess)

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
        test_port  = test_param_get("test_port",  default=64)
        max_len    = test_param_get("max_len",    default=9216)
        pkt_len    = test_param_get("pkt_len",    default=100)
       
        #
        # Program the tables
        #
        self.client.set_output_set_default_action_set_output(
            self.sess_hdl, self.dev_tgt,
            decaf_10_set_output_action_spec_t(test_port))

        self.conn_mgr.complete_operations(self.sess_hdl)
        
        print "Sending Untagged %d-byte L2 packet into port %d" % (pkt_len, test_port)
        header  = Ether(dst="11:22:33:44:55:66", src="00:01:02:03:04:05")
        payload = "".join([chr(x % 256) for x in xrange(pkt_len - len(header))])

        send_pkt = header/payload
        send_pkt[Ether].type = 0xABCD
        
        exp_pkt_1 = header/Dot1Q(vlan=pkt_len+4, type=send_pkt[Ether].type)/payload # Adjust for the CRC

        send_packet(self, test_port, send_pkt)
        
        print """Expecting the packet to be forwarded to port %d
                 with the length %d in VLAN tag""" % (test_port, pkt_len+4)
        verify_packet(self, exp_pkt_1, test_port)

        print "Done"
