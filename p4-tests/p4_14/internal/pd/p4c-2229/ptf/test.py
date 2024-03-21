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
Simple PTF test for simple_l3_lag_ecmp
"""
import pdb
import pd_base_tests

from ptf import config
from ptf.testutils import *
from ptf.thriftutils import *

# Change the line below, using the name of your program
from simple_l3_lag_ecmp.p4_pd_rpc.ttypes import *
from res_pd_rpc.ttypes import *

# Other useful modules
import random
import sys

class TestGroup1(pd_base_tests.ThriftInterfaceDataPlane):
    def __init__(self):
        # Change the line below, using the name of your program
        pd_base_tests.ThriftInterfaceDataPlane.__init__(self,
                                                        ["simple_l3_lag_ecmp"])

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

        # Initialize tables

        # Initialize packet_num_register (if it is used)
        try:
            init_packet_num = test_param_get("init_packet_num", 0);
            if init_packet_num >= 0:
                self.client.register_write_packet_num(
                    self.sess_hdl, self.dev_tgt, 0, init_packet_num);
        except:
            pass

            # Always make sure the programming gets down to the HW
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
                    exec(delete_func + "(self.sess_hdl, self.dev, entry)")

            print("  Clearing Selector Groups")
            for selector in self.groups.keys():
                delete_func="self.client." + selector + "_del_group"
                for group in self.groups[selector]:
                    exec(delete_func + "(self.sess_hdl, self.dev, group)")

            print("  Clearing Action Profile Members")
            for action_profile in self.members.keys():
                delete_func="self.client." + action_profile + "_del_member"
                for member in self.members[action_profile]:
                    exec(delete_func + "(self.sess_hdl, self.dev, member)")
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

class LagIPv4Random(TestGroup1):
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
        ingress_port = test_param_get("ingress_port", 0)
        pkt_count    = test_param_get("pkt_count", 100)
        egress_ports = test_param_get("egress_ports", [1,2,3])
        nexthop_id   = test_param_get("nexthop_id", 100)

        seed         = test_param_get("seed", 0)
        max_imbalance  = test_param_get("max_imbalance", 10)

        #
        # Program the tables
        #
        self.members["lag_ecmp"]   = []
        self.groups["lag_ecmp"]    = []
        self.entries["nexthop"]    = []
        self.entries["ipv4_lpm"] = []

        lag = self.client.lag_ecmp_create_group(self.sess_hdl, self.dev_tgt,
                                                len(egress_ports))
        self.groups["lag_ecmp"].append(lag)

        for p in egress_ports:
            mbr = self.client.lag_ecmp_add_member_with_send(
                self.sess_hdl, self.dev_tgt,
                simple_l3_lag_ecmp_send_action_spec_t(p))
            self.members["lag_ecmp"].append(mbr)
            self.client.lag_ecmp_add_member_to_group(
                self.sess_hdl, self.dev,
                hex_to_i32(lag), hex_to_i32(mbr))

        self.entries["nexthop"].append(
            self.client.nexthop_add_entry_with_selector(
                self.sess_hdl, self.dev_tgt,
                simple_l3_lag_ecmp_nexthop_match_spec_t(nexthop_id), lag))

        #
        # Use the LAG for the default route, so that we can use random
        # source and destination addresses
        #
        self.entries["ipv4_lpm"].append(
            self.client.ipv4_lpm_table_add_with_set_nexthop(
                self.sess_hdl, self.dev_tgt,
                simple_l3_lag_ecmp_ipv4_lpm_match_spec_t(0, 0),
                simple_l3_lag_ecmp_set_nexthop_action_spec_t(nexthop_id)))
        self.conn_mgr.complete_operations(self.sess_hdl)

        #
        # Send Packets
        random.seed(seed)
        packet_counts = [0] * len(egress_ports)
        for i in range(0, pkt_count * len(egress_ports)):
            dst_ip="%d.%d.%d.%d" % (random.randint(1, 255),
                                    random.randint(1, 255),
                                    random.randint(1, 255),
                                    random.randint(1, 255))
            src_ip="%d.%d.%d.%d" % (random.randint(1, 255),
                                    random.randint(1, 255),
                                    random.randint(1, 255),
                                    random.randint(1, 255))
            tcp = random.randint(0,1)
            sport = random.randint(0, 65535)
            dport = random.randint(0, 65535)

            if tcp == 1:
                proto="TCP"
                pkt = simple_tcp_packet(ip_dst=dst_ip,
                                        ip_src=src_ip,
                                        tcp_sport=sport,
                                        tcp_dport=dport)
            else:
                proto="UDP"
                pkt = simple_udp_packet(ip_dst=dst_ip,
                                        ip_src=src_ip,
                                        udp_sport=sport,
                                        udp_dport=dport)

            send_packet(self, ingress_port, pkt)
            (port_idx, result) = verify_packet_any_port(self, pkt, egress_ports)
            self.assertTrue(port_idx < len(egress_ports))
            packet_counts[port_idx] += 1

            print("{:s} {:>15s}.{:<5d} -> {:>15s}.{:<5d}: {:>3d} {}\r".format(
                proto, src_ip, sport, dst_ip, dport, egress_ports[port_idx],
                packet_counts),
            sys.stdout.flush())

        print
        #
        # Print summary results and check
        #
        total_pkts = 0
        for i in range(0, len(egress_ports)):
            print("Port %3d: %5d packets" % (egress_ports[i], packet_counts[i]))
            total_pkts += packet_counts[i]
        print("Total: %d" % total_pkts)

        self.assertEqual(total_pkts, pkt_count * len(egress_ports))

        max_port_count = max(packet_counts)
        min_port_count = min(packet_counts)
        imbalance = max(pkt_count - min_port_count, max_port_count - pkt_count)
        imbalance_pct = float(imbalance)/pkt_count

        print("Max Imbalance: {}/{} packets ({:%})".format(
            imbalance, pkt_count, imbalance_pct))

        self.assertTrue(imbalance_pct <= max_imbalance)

#
# A simple function to increment an IP address. IP address is in the string
# x.y.z.w form
#
def inc_ip(ipaddr, inc):
    two_32 = 1 << 32
    two_31 = 1 << 31
    # Convert to a signed integer
    i32 = ipv4Addr_to_i32(ipaddr)
    # Convert to unsigned
    if (i32 < 0):
        i32 += two_32
    # Increment
    i32 += inc
    i32 %= two_32
    # Back to signed
    if i32 >= two_31:
        i32 -= two_32
    return i32_to_ipv4Addr(i32)

class LagIPv4Seq(TestGroup1):
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
        ingress_port = test_param_get("ingress_port", 0)
        pkt_count    = test_param_get("pkt_count", 100)
        egress_ports = test_param_get("egress_ports", [1,2,3])
        nexthop_id   = test_param_get("nexthop_id", 100)

        dst_ip       = test_param_get("dst_ip", "192.168.1.1")
        dst_ip_inc   = test_param_get("dst_ip_inc", 1)
        src_ip       = test_param_get("src_ip", "10.0.0.1")
        src_ip_inc   = test_param_get("src_ip_inc", 1)
        sport        = test_param_get("sport", 1024)
        sport_inc    = test_param_get("sport_inc", 1)
        dport        = test_param_get("dport", 1)
        dport_inc    = test_param_get("dport_inc", 1)

        seed         = test_param_get("seed", 0)
        max_imbalance  = test_param_get("max_imbalance", 10)

        #
        # Program the tables
        #
        self.members["lag_ecmp"]   = []
        self.groups["lag_ecmp"]    = []
        self.entries["nexthop"]    = []
        self.entries["ipv4_lpm"] = []

        lag = self.client.lag_ecmp_create_group(self.sess_hdl, self.dev_tgt,
                                                len(egress_ports))
        self.groups["lag_ecmp"].append(lag)

        for p in egress_ports:
            mbr = self.client.lag_ecmp_add_member_with_send(
                self.sess_hdl, self.dev_tgt,
                simple_l3_lag_ecmp_send_action_spec_t(p))
            self.members["lag_ecmp"].append(mbr)
            self.client.lag_ecmp_add_member_to_group(
                self.sess_hdl, self.dev,
                hex_to_i32(lag), hex_to_i32(mbr))

        self.entries["nexthop"].append(
            self.client.nexthop_add_entry_with_selector(
                self.sess_hdl, self.dev_tgt,
                simple_l3_lag_ecmp_nexthop_match_spec_t(nexthop_id), lag))

        #
        # Use the LAG for the default route, so that we can use random
        # source and destination addresses
        #
        self.entries["ipv4_lpm"].append(
            self.client.ipv4_lpm_table_add_with_set_nexthop(
                self.sess_hdl, self.dev_tgt,
                simple_l3_lag_ecmp_ipv4_lpm_match_spec_t(0, 0),
                simple_l3_lag_ecmp_set_nexthop_action_spec_t(nexthop_id)))
        self.conn_mgr.complete_operations(self.sess_hdl)

        #
        # Send Packets
        random.seed(seed)
        packet_counts = [0] * len(egress_ports)
        for i in range(0, pkt_count * len(egress_ports)):
            pkt = simple_tcp_packet(ip_dst=dst_ip,
                                    ip_src=src_ip,
                                    tcp_sport=sport,
                                    tcp_dport=dport)
            send_packet(self, ingress_port, pkt)
            (port_idx, result) = verify_packet_any_port(self, pkt, egress_ports)
            self.assertTrue(port_idx < len(egress_ports))
            packet_counts[port_idx] += 1
            print("{:>15s}.{:<5d} -> {:>15s}.{:<5d}: {:>3d} {}\r".format(
                src_ip, sport, dst_ip, dport, egress_ports[port_idx],
                packet_counts),
            sys.stdout.flush())


            # Increment
            dst_ip = inc_ip(dst_ip, dst_ip_inc)
            src_ip = inc_ip(src_ip, src_ip_inc)
            dport += dport_inc; dport %= 65536
            sport += sport_inc; sport %= 65536

        print

        #
        # Print summary results and check
        #
        total_pkts = 0
        for i in range(0, len(egress_ports)):
            print("Port %3d: %5d packets" % (egress_ports[i], packet_counts[i]))
            total_pkts += packet_counts[i]
        print("Total: %d" % total_pkts)

        self.assertEqual(total_pkts, pkt_count * len(egress_ports))

        max_port_count = max(packet_counts)
        min_port_count = min(packet_counts)
        imbalance = max(pkt_count - min_port_count, max_port_count - pkt_count)
        imbalance_pct = float(imbalance)/pkt_count

        print("Max Imbalance: {}/{} packets ({:%})".format(
            imbalance, pkt_count, imbalance_pct))

        self.assertTrue(imbalance_pct <= max_imbalance)
