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
Simple PTF test for simple_l3_mirror
"""
import pdb                # This is optional, but useful for debugging
import pd_base_tests

from ptf import config
from ptf.testutils import *
from ptf.thriftutils import *

# Change the line below, using the name of your program
from simple_l3_mirror.p4_pd_rpc.ttypes import *
from res_pd_rpc.ttypes import *
from mirror_pd_rpc.ttypes import *

#
# This class below is not a test, but it provides a common configuration that
# can be used by multiple other tests, subclassed from it.
# This particular class espablishes baseline configuration similar to what
# the test in simple_l3 is doing
#
class TestGroup1(pd_base_tests.ThriftInterfaceDataPlane):
    def __init__(self):
        # Change the line below, using the name of your program
        pd_base_tests.ThriftInterfaceDataPlane.__init__(self, ["simple_l3_mirror"])

    # The setUp() method is used to prepare the test fixture. Typically
    # you would use it to establich connection to the Thrift server.
    #
    # You can also put the initial device configuration there. However,
    # if during this process an error is encountered, it will be considered
    # as a test error (meaning the test is incorrect),
    # rather than a test failure
    def setUp(self):
        pd_base_tests.ThriftInterfaceDataPlane.setUp(self)

        # Uncomment the line below if you need to debug anything in your test
        # It will drop you into Python debugger
        #pdb.set_trace()

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
        self.client.ipv4_lpm_set_default_action_send(
            self.sess_hdl, self.dev_tgt,
            simple_l3_mirror_send_action_spec_t(64))

        # Initialize tables

        self.entries["ipv4_host"] = []

        # 192.168.1.1 -> PORT 1
        self.entries["ipv4_host"].append(
            self.client.ipv4_host_table_add_with_send(
                self.sess_hdl, self.dev_tgt,
                simple_l3_mirror_ipv4_host_match_spec_t(
                    ipv4Addr_to_i32("192.168.1.1")),
                simple_l3_mirror_send_action_spec_t(1)))

        # 192.168.1.2 -> PORT 2
        self.entries["ipv4_host"].append(
            self.client.ipv4_host_table_add_with_send(
                self.sess_hdl, self.dev_tgt,
                simple_l3_mirror_ipv4_host_match_spec_t(
                    ipv4Addr_to_i32("192.168.1.2")),
                simple_l3_mirror_send_action_spec_t(2)))

        # 192.168.1.3 -> DISCARD
        self.entries["ipv4_host"].append(
            self.client.ipv4_host_table_add_with_discard(
                self.sess_hdl, self.dev_tgt,
                simple_l3_mirror_ipv4_host_match_spec_t(
                    ipv4Addr_to_i32("192.168.1.3"))))

        # 192.168.1.254 -> PORT 64 (CPU)
        self.entries["ipv4_host"].append(
            self.client.ipv4_host_table_add_with_send(
                self.sess_hdl, self.dev_tgt,
                simple_l3_mirror_ipv4_host_match_spec_t(
                    ipv4Addr_to_i32("192.168.1.254")),
                simple_l3_mirror_send_action_spec_t(64)))

        # ipv4_lpm

        self.entries["ipv4_lpm"] = []

        # 192.168.1.0/24 -> PORT 64 (CPU)
        self.entries["ipv4_lpm"].append(
            self.client.ipv4_lpm_table_add_with_send(
                self.sess_hdl, self.dev_tgt,
                simple_l3_mirror_ipv4_lpm_match_spec_t(
                    ipv4Addr_to_i32("192.168.1.0"), 24),
                simple_l3_mirror_send_action_spec_t(64)))

        # 192.168.0.0/16 -> DISCARD
        self.entries["ipv4_lpm"].append(
            self.client.ipv4_lpm_table_add_with_discard(
                self.sess_hdl, self.dev_tgt,
                simple_l3_mirror_ipv4_lpm_match_spec_t(
                    ipv4Addr_to_i32("192.168.0.0"), 16)))

        # DEFAULT (0.0.0.0/0) -> PORT 64 (CPU)
        self.entries["ipv4_lpm"].append(
            self.client.ipv4_lpm_table_add_with_send(
                self.sess_hdl, self.dev_tgt,
                simple_l3_mirror_ipv4_lpm_match_spec_t(
                    ipv4Addr_to_i32("0.0.0.0"), 0),
                simple_l3_mirror_send_action_spec_t(64)))

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


# This is also not a real test class. What it does, instead, it adds more
# configuration on top of what TestGroup1 does. That's where you can add
# mirroring configration.

class TestGroupMirror(TestGroup1):
    def setUp(self):
        # Let TestGroup1 to do the basic setup
        TestGroup1.setUp(self)

        ########## And now -- mirroring! #################

        # Uncomment the line below if you need to debug anything in your test
        # It will drop you into Python debugger
        #pdb.set_trace()

        #
        # We will set up the CPU mirror session to limit the packet length
        # to 256 bytes. However, there are some caveats:
        #    1) Up to 256 bytes will go from TM into the egress pipeline.
        #       However, some of these bytes will contain the mirror header.
        #       For the current program that's 6 bytes.
        #    2) Those 256 bytes don't include 4 bytes of FCS added by the MAC.
        #    3) Since we are going to put additional encapsulation (Ethernet
        #       plus ToCpu header) on top, the egress packet size will be
        #       different. Oh, and do not forget 4 bytes of CRC (FCS) added by
        #       the MAC. It will be equal to:
        #       (<max_pkt_len> - <mirror header>) + (Ethernet + ToCpu) + FCS =
        #       (256 - 6) + (12+2 + 6) + 4 = 274 bytes.
        # Not 256, but close!
        #
        self.max_pkt_len_cpu=256
        self.max_pkt_len_cpu_out = self.max_pkt_len_cpu - 6
        self.mirror_sessions=[]

        # Mirror destination 5 -- copy to CPU
        self.mirror.mirror_session_create(
            self.sess_hdl, self.dev_tgt,
            MirrorSessionInfo_t(
                mir_type=MirrorType_e.PD_MIRROR_TYPE_NORM,
                direction=Direction_e.PD_DIR_BOTH,
                mir_id=5,
                egr_port=64, egr_port_v=True,
                max_pkt_len=self.max_pkt_len_cpu))
        self.mirror_sessions.append(5)

        self.entries["mirror_dest"] = []

        self.entries["mirror_dest"].append(
            self.client.mirror_dest_table_add_with_send_to_cpu(
                self.sess_hdl, self.dev_tgt,
                simple_l3_mirror_mirror_dest_match_spec_t(5)))

        # Mirror Destination 7 -- RSPAN on port 3 with VLAN ID 17 and Priority 3
        self.mirror.mirror_session_create(
            self.sess_hdl, self.dev_tgt,
            MirrorSessionInfo_t(
                mir_type=MirrorType_e.PD_MIRROR_TYPE_NORM,
                direction=Direction_e.PD_DIR_BOTH,
                mir_id=7,
                egr_port=3, egr_port_v=True,
                max_pkt_len=16384))
        self.mirror_sessions.append(7)

        self.entries["mirror_dest"].append(
            self.client.mirror_dest_table_add_with_send_rspan(
                self.sess_hdl, self.dev_tgt,
                simple_l3_mirror_mirror_dest_match_spec_t(7),
                simple_l3_mirror_send_rspan_action_spec_t(
                    action_pcp=3, action_cfi=0, action_vid=17)))

        # Use Mirror Destination 5 for all packets ingressing on port 1
        self.entries["ing_acl"] = []

        self.entries["ing_acl"].append(
            self.client.ing_acl_table_add_with_acl_mirror(
                self.sess_hdl, self.dev_tgt,
                simple_l3_mirror_ing_acl_match_spec_t(
                    ig_intr_md_ingress_port=1, ig_intr_md_ingress_port_mask=-1,
                    ethernet_srcAddr=macAddr_to_string("00:00:00:00:00:00"),
                    ethernet_srcAddr_mask=macAddr_to_string("00:00:00:00:00:00"),
                    ethernet_dstAddr=macAddr_to_string("00:00:00:00:00:00"),
                    ethernet_dstAddr_mask=macAddr_to_string("00:00:00:00:00:00"),
                    vlan_tag_0__valid=0, vlan_tag_0__valid_mask=0,
                    vlan_tag_0__vid=0,   vlan_tag_0__vid_mask=0,
                    ipv4_valid=0,        ipv4_valid_mask=0,
                    ipv4_srcAddr=0,      ipv4_srcAddr_mask=0,
                    ipv4_dstAddr=0,      ipv4_dstAddr_mask=0),
                1,
            simple_l3_mirror_acl_mirror_action_spec_t(5)))

        # Use Mirror Destination 7 for all packets ingressing on port 2
        self.entries["ing_acl"].append(
            self.client.ing_acl_table_add_with_acl_mirror(
                self.sess_hdl, self.dev_tgt,
                simple_l3_mirror_ing_acl_match_spec_t(
                    ig_intr_md_ingress_port=2, ig_intr_md_ingress_port_mask=-1,
                    ethernet_srcAddr=macAddr_to_string("00:00:00:00:00:00"),
                    ethernet_srcAddr_mask=macAddr_to_string("00:00:00:00:00:00"),
                    ethernet_dstAddr=macAddr_to_string("00:00:00:00:00:00"),
                    ethernet_dstAddr_mask=macAddr_to_string("00:00:00:00:00:00"),
                    vlan_tag_0__valid=0, vlan_tag_0__valid_mask=0,
                    vlan_tag_0__vid=0,   vlan_tag_0__vid_mask=0,
                    ipv4_valid=0,        ipv4_valid_mask=0,
                    ipv4_srcAddr=0,      ipv4_srcAddr_mask=0,
                    ipv4_dstAddr=0,      ipv4_dstAddr_mask=0),
                1,
                simple_l3_mirror_acl_mirror_action_spec_t(7)))

        # Always make sure the programming gets dow to the HW
        self.conn_mgr.complete_operations(self.sess_hdl)
        print

    def tearDown(self):
        print("  Clearing Mirror Sessions")
        for mir_sess in self.mirror_sessions:
            self.mirror.mirror_session_delete(
                self.sess_hdl, self.dev_tgt, mir_sess)
        # calling the base class tearDown closes the session, and thus
        # must be called after cleaning up the mirror session
        TestGroup1.tearDown(self)

#
# Individual tests can now be subclassed from TestGroup1 or TestGroupMirror
#

############################################################################
################# I N D I V I D U A L    T E S T S #########################
############################################################################

#
# This is the same test as in simple_l3. It is there as an example and
# also to check that everything works.
#
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
        # Uncomment the line below if you need to debug anything in your test
        # It will drop you into Python debugger
        #pdb.set_trace()

        # Test Parameters
        ipv4_dst     = "192.168.1.1"
        ingress_port = 0
        egress_port  = 1

        print("Sending packet with IPv4 DST ADDR=%s into port %d" %
              (ipv4_dst, ingress_port))
        pkt = simple_tcp_packet(eth_dst="00:98:76:54:32:10",
                                eth_src='00:55:55:55:55:55',
                                ip_dst=ipv4_dst,
                                ip_id=101,
                                ip_ttl=64,
                                ip_ihl=5)
        send_packet(self, ingress_port, pkt)
        print("Expecting the packet to be forwarded to port %d" % egress_port)
        verify_packet(self, pkt, egress_port)
        print("Packet received of port %d" % egress_port)

# ATTENTION:
# ----------
# ToCpu Header Definition (it must match simple_l3_mirror.p4). If you modified
# the header or the ethertype, you need change this definition as well.
class ToCpu(Packet):
    name = "to_cpu header from simple_l3_mirror.p4"
    fields_desc = [ ShortEnumField("mirror_type",  0,
                                   { 0: "Ingress", 1: "Egress"}),
                    ShortField("ingress_port", 0),
                    ShortField("pkt_length",   0)
    ]

bind_layers(Ether, ToCpu, type=0xBF01)
bind_layers(ToCpu, Ether)

#
# Mirroring Test Cpu 1
# Write a test that injects a packet and verifies that a packet with the proper
# ToCpu header (and the new ethernet header) was sent to the CPU port (64)
#
class MirrorTestCpu1(TestGroupMirror):
    def runTest(self):
        # Test Parameters
        ipv4_dst     = "192.168.1.2"
        ingress_port = 1
        egress_port  = 2
        cpu_port     = 64

        print("Sending packet with IPv4 DST ADDR=%s into port %d" %
              (ipv4_dst, ingress_port))
        pkt = simple_tcp_packet(eth_dst="00:98:76:54:32:10",
                                eth_src='00:55:55:55:55:55',
                                ip_dst=ipv4_dst,
                                ip_id=101,
                                ip_ttl=64,
                                ip_ihl=5)
        send_packet(self, ingress_port, pkt)
        print("Expecting the packet to be forwarded to port %d" % egress_port)
        verify_packet(self, pkt, egress_port)
        print("Packet received on port %d" % egress_port)

        #
        # ToCpu.pkt_length includes 4 bytes of FCS, len(pkt) does not.
        #
        cpu_pkt = (
            Ether(dst="FF:FF:FF:FF:FF:FF", src="AA:AA:AA:AA:AA:AA") /
            ToCpu(mirror_type="Ingress",
                  ingress_port=ingress_port,
                  pkt_length=len(pkt)+4) /
            pkt)

        print("Expecting mirrored packet with 'to_cpu' header on port %d" % cpu_port)
        verify_packet(self, cpu_pkt, cpu_port)
        print("Mirrored packet received on port %d" % cpu_port)

#
# Mirroring Test Cpu 2
# Write a test that injects a packet and verifies that a packet with the proper
# ToCpu header (and the new ethernet header) was sent to the CPU port (64)
# In addition we need to see that the packet got trimmed
class MirrorTestCpu2(TestGroupMirror):
    def runTest(self):
        # Test Parameters
        ipv4_dst     = "192.168.1.2"
        ingress_port = 1
        egress_port  = 2
        cpu_port     = 64

        print("Sending packet with IPv4 DST ADDR=%s into port %d" %
              (ipv4_dst, ingress_port))
        pkt = simple_tcp_packet(eth_dst="00:98:76:54:32:10",
                                eth_src='00:55:55:55:55:55',
                                ip_dst=ipv4_dst,
                                ip_id=101,
                                ip_ttl=64,
                                ip_ihl=5,
                                pktlen=1500)
        send_packet(self, ingress_port, pkt)
        print("Expecting the packet to be forwarded to port %d" % egress_port)
        verify_packet(self, pkt, egress_port)
        print("Packet received on port %d" % egress_port)

        cpu_pkt_len = min(len(pkt), self.max_pkt_len_cpu_out)
        #
        # ToCpu.pkt_length includes 4 bytes of FCS, cpu_pkt_len does not.
        #
        cpu_pkt = (
            Ether(dst="FF:FF:FF:FF:FF:FF", src="AA:AA:AA:AA:AA:AA") /
            ToCpu(mirror_type="Ingress",
                  ingress_port=ingress_port,
                  pkt_length=cpu_pkt_len+4) /
                  str(pkt)[0:cpu_pkt_len])

        print("Expecting mirrored packet with 'to_cpu' header on port %d" % cpu_port)
        verify_packet(self, cpu_pkt, cpu_port)
        print("Mirrored packet received on port %d" % cpu_port)

#
# Mirroring Test RSPAN 1
# Write a test that injects a packet and verifies that a packet with the proper
# RSPAN modifications was sent out
#
class MirrorTestRspan1(TestGroupMirror):
    def runTest(self):
        # Test Parameters
        ipv4_dst     = "192.168.1.1"
        ingress_port = 2
        egress_port  = 1
        rspan_port   = 3
        pktlen       = 100

        print("Sending packet with IPv4 DST ADDR=%s into port %d" %
              (ipv4_dst, ingress_port))
        pkt = simple_tcp_packet(eth_dst="00:98:76:54:32:10",
                                eth_src='00:55:55:55:55:55',
                                ip_dst=ipv4_dst,
                                ip_id=101,
                                ip_ttl=64,
                                ip_ihl=5,
                                pktlen=pktlen)
        send_packet(self, ingress_port, pkt)
        print("Expecting the packet to be forwarded to port %d" % egress_port)
        verify_packet(self, pkt, egress_port)
        print("Packet received on port %d" % egress_port)

        rspan_pkt = simple_tcp_packet(eth_dst="00:98:76:54:32:10",
                                      eth_src='00:55:55:55:55:55',
                                      dl_vlan_enable=True,
                                      vlan_vid=17,
                                      vlan_pcp=3,
                                      ip_dst=ipv4_dst,
                                      ip_id=101,
                                      ip_ttl=64,
                                      ip_ihl=5,
                                      pktlen=pktlen+4)

        print("Expecting mirrored packet with 'to_cpu' header on port %d" % rspan_port)
        verify_packet(self, rspan_pkt, rspan_port)
        print("Mirrored packet received on port %d" % rspan_port)
