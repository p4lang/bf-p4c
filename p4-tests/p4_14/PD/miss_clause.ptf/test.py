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
Simple PTF test for miss_clause (default action behavior)
"""
import pdb
import pd_base_tests

from ptf import config
from ptf.testutils import *
from ptf.thriftutils import *

# Change the line below, using the name of your program
from miss_clause.p4_pd_rpc.ttypes import *
from res_pd_rpc.ttypes import *

class Test1(pd_base_tests.ThriftInterfaceDataPlane):
    def __init__(self):
        # Change the line below, using the name of your program
        pd_base_tests.ThriftInterfaceDataPlane.__init__(self, ["miss_clause"])

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

        # Another usefult thing that can be done here is setting the
        # default actions on the tables

        # Always make sure the programming gets dow to the HW
        self.conn_mgr.complete_operations(self.sess_hdl)
        print

    def runTest(self):
         # Test Parameters
        ipv4_dst     = "192.168.1.1"
        ingress_port = 0
        egress_port1  = 6
        real_egress_port = egress_port1 ^ 1

        print "Setting default action on ipv4_host to send(%d)" % egress_port1
        self.client.ipv4_host_set_default_action_send(
            self.sess_hdl, self.dev_tgt,
            miss_clause_send_action_spec_t(egress_port1))
        print "Setting default action on ipv4_lpm to change egress port from %d to %d" % (egress_port1, real_egress_port)
        self.client.ipv4_lpm_set_default_action_odd_even(
            self.sess_hdl, self.dev_tgt)

        # Always make sure the programming gets dow to the HW
        self.conn_mgr.complete_operations(self.sess_hdl)

        print("Sending packet with IPv4 DST ADDR=%s into port %d" %
              (ipv4_dst, ingress_port))
        pkt = simple_tcp_packet(eth_dst="00:98:76:54:32:10",
                                eth_src='00:55:55:55:55:55',
                                ip_dst=ipv4_dst,
                                ip_id=101,
                                ip_ttl=64,
                                ip_ihl=5)
        send_packet(self, ingress_port, pkt)
        print("Expecting the packet to be forwarded to port %d" % real_egress_port)
        verify_packet(self, pkt, real_egress_port)
        print("Packet received of port %d" % real_egress_port)

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
