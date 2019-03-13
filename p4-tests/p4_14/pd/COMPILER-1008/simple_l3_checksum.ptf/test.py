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
Simple PTF test for simple_l3_checksum
"""

# Import standard Pythin modules
import unittest           # Useful if you need unittest decorators
import pdb                # Useful for debugging
import copy               # Almost always needed for test packets
from scapy.all import * # Useful if you want to create your own packets

# Import PTF modules
from ptf import config
from ptf.testutils import *
from ptf.thriftutils import *

# Import common PD and PD Fixed modules (especially types)
import pd_base_tests
from res_pd_rpc.ttypes         import *   # Common PD/PD Fixed Types
from conn_mgr_pd_rpc.ttypes    import *   # Packet Generator API Types
from devport_mgr_pd_rpc.ttypes import *   # Device Port Manager API Types
from knet_mgr_pd_rpc.ttypes    import *   # KNET Driver Interface Types
from mc_pd_rpc.ttypes          import *   # PRE (Multicast) API Types
from mirror_pd_rpc.ttypes      import *   # Mirror (Clone) API Types
from pal_rpc.ttypes            import *   # Platform Abstraction Layer API Types
from pkt_pd_rpc.ttypes         import *   # Simplified Packet DMA API Types
from sd_pd_rpc.ttypes          import *   # Serdes Driver API Types
from tm_api_rpc.ttypes         import *   # Traffic Manager API types


# Change the line below, using the name of your program
from simple_l3_checksum.p4_pd_rpc.ttypes import *  # PD API Types for your program

class TestGroup1(pd_base_tests.ThriftInterfaceDataPlane):
    def __init__(self):
        # Change the line below, using the name of your program
        pd_base_tests.ThriftInterfaceDataPlane.__init__(self, ["simple_l3_checksum"])

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
        #
        self.client.ipv4_acl_set_default_action_discard(
            self.sess_hdl, self.dev_tgt)

        self.client.ipv6_acl_set_default_action_discard(
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
        except:
            print("  Error while cleaning up. ")
            print("  You might need to restart the driver")
        finally:
            print("    Connected to Device %d, Session %d" % (
                self.dev, self.sess_hdl))

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

def create_payload(length, start=0):
    return "".join([chr(x % 256) for x in range(start, start+length)])

class L2_IPv4_TCP_Good(TestGroup1):
    #
    # Send IPv4 packet with L2 Treatment. Checksum must not be changed
    #
    def runTest(self):
        # Test Parameters
        test_port = test_param_get("ingress_port", 0)
        ipv4_dst  = test_param_get("ipv4_dst", "192.168.1.1")
        ipv4_src  = test_param_get("ipv4_src", "192.168.5.31")
        ipv4_opt  = test_param_get("ipv4_opt", 40)
        sport     = test_param_get("sport",    1234)
        dport     = test_param_get("sport",    7)
        pkt_len   = test_param_get("pkt_len",  200)
        verify_checksum = test_param_get("verify_checksum", -1)

        self.entries["ipv4_acl"] = []
        self.entries["ipv4_acl"].append(
            self.client.ipv4_acl_table_add_with_send(
                self.sess_hdl, self.dev_tgt,
                simple_l3_checksum_ipv4_acl_match_spec_t(
                    ipv4Addr_to_i32(ipv4_src), -1,  # ipv4.srcAddr
                    ipv4Addr_to_i32(ipv4_dst), -1,  # ipv4.dstAddr
                    6, -1,                          # ipv4.protocol
                    hex_to_i16(sport), -1,          # l4_lookup.word_1
                    hex_to_i16(dport), -1,          # l4_lookup.word_2
                    1, 1,                           # l4_lookup.first_frag
                    0, verify_checksum),            # ingress_parser_err
                
                0,                                  # Priority
                
                simple_l3_checksum_send_action_spec_t(
                    test_port)
                ))
                    
        self.conn_mgr.complete_operations(self.sess_hdl)
        
        print """Sending TCP Packet Good Checksum for L2 Processing
                 Options: """, repr(ipv4_opt)

        if ipv4_opt == 0 or ipv4_opt == None:
            ip_options = False
        elif isinstance(ipv4_opt, int):
            ip_options=IPOption(create_payload(ipv4_opt))
        elif isinstance(ipv4_opt, IPOption):
            ip_options=ipv4_opt
        else:
            ip_options=IPOption(ipv4_opt)
            
        test_pkt = simple_tcp_packet(eth_dst="00:98:76:54:32:10",
                                     eth_src='00:55:55:55:55:55',
                                     ip_src=ipv4_src,
                                     ip_dst=ipv4_dst,
                                     ip_id=101,
                                     ip_ttl=64,
                                     ip_options=ip_options,
                                     tcp_sport=sport,
                                     tcp_dport=dport,
                                     pktlen=pkt_len)
        exp_pkt = Ether(str(test_pkt))
        
        send_packet(self, test_port, test_pkt)
        print("Expecting the packet to be forwarded to port %d" % test_port)
        verify_packet(self, exp_pkt, test_port)
        print("Packet received of port %d" % test_port)
