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
Simple PTF test for basic_switching.p4
"""

import pd_base_tests

from ptf import config
from ptf.testutils import *
from ptf.thriftutils import *

from basic_switching.p4_pd_rpc.ttypes import *
from res_pd_rpc.ttypes import *

swports = []
for device, port, ifname in config["interfaces"]:
    swports.append(port)
    swports.sort()

if swports == []:
    swports = [0, 4]

def crc16_regular(buff, crc=0, poly=0xa001):
    l = len(buff)
    i = 0
    while i < l:
        ch = ord(buff[i])
        uc = 0
        while uc < 8:
            if (crc & 1) ^ (ch & 1):
                crc = (crc >> 1) ^ poly
            else:
                crc >>= 1
            ch >>= 1
            uc += 1
        i += 1
    return crc

def entropy_hash(pkt, layer='ipv4', ifindex=0):
    buff = ''
    if layer == 'ether':
        buff += str(format(ifindex, '02x')).zfill(4)
        buff += pkt[Ether].src.translate(None, ':')
        buff += pkt[Ether].dst.translate(None, ':')
        buff += str(hex(pkt[Ether].type)[2:]).zfill(4)
    elif layer == 'ipv4':
        buff += socket.inet_aton(pkt[IP].src).encode('hex')
        buff += socket.inet_aton(pkt[IP].dst).encode('hex')
        buff += str(hex(pkt[IP].proto)[2:]).zfill(2)
        if pkt[IP].proto == 6:
            buff += str(hex(pkt[TCP].sport)[2:]).zfill(4)
            buff += str(hex(pkt[TCP].dport)[2:]).zfill(4)
        elif pkt[IP].proto == 17:
            buff += str(hex(pkt[UDP].sport)[2:]).zfill(4)
            buff += str(hex(pkt[UDP].dport)[2:]).zfill(4)
    elif layer == 'ipv6':
        buff += socket.inet_pton(socket.AF_INET6, pkt[IPv6].src).encode('hex')
        buff += socket.inet_pton(socket.AF_INET6, pkt[IPv6].dst).encode('hex')
        buff += str(hex(pkt[IPv6].nh)[2:]).zfill(2)
        if pkt[IPv6].nh == 6:
            buff += str(hex(pkt[TCP].sport)[2:]).zfill(4)
            buff += str(hex(pkt[TCP].dport)[2:]).zfill(4)
        elif pkt[IPv6].nh == 17:
            buff += str(hex(pkt[UDP].sport)[2:]).zfill(4)
            buff += str(hex(pkt[UDP].dport)[2:]).zfill(4)
    else:
        buff = ''
    h = crc16_regular(buff.decode('hex'))
    return h

class L2Test(pd_base_tests.ThriftInterfaceDataPlane):
    def __init__(self):
        pd_base_tests.ThriftInterfaceDataPlane.__init__(self,
                                                        ["basic_switching"])

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

        print("\nConnected to Device %d, Session %d" % (
            self.dev, self.sess_hdl))

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
        ingress_port = swports[0]
        egress_port  = swports[1]
        mac_da       = "00:11:11:11:11:11"

        print("Populating table entries")

        # self.entries dictionary will contain all installed entry handles
        self.entries={}
        self.entries["forward"] = []
        self.entries["forward"].append(
            self.client.forward_table_add_with_set_egr(
                self.sess_hdl, self.dev_tgt,
                basic_switching_forward_match_spec_t(
                    ethernet_dstAddr=macAddr_to_string(mac_da)),
                basic_switching_set_egr_action_spec_t(
                    action_egress_spec=egress_port)))

        print("Table forward: %s => set_egr(%d)" %
              (mac_da, egress_port))

        self.conn_mgr.complete_operations(self.sess_hdl)
        print("Sending packet with DST MAC=%s into port %d" %
              (mac_da, ingress_port))
        pkt = simple_tcp_packet(eth_dst=mac_da,
                                eth_src='00:55:55:55:55:55',
                                ip_dst='10.0.0.1',
                                ip_id=101,
                                ip_ttl=64,
                                ip_ihl=5)
        pkt = simple_udp_packet(
            eth_dst='00:11:11:11:11:11',
            eth_src='00:22:22:22:22:22',
            ip_dst='10.10.10.1',
            ip_src='10.10.10.2',
            ip_id = 105,
            ip_ttl = 64,
            pktlen = 70,
            with_udp_chksum = True)
        udp_sport = entropy_hash(pkt)
        vxlan_pkt = simple_vxlan_packet(
            eth_dst=mac_da,
            eth_src='00:55:55:55:55:55',
            ip_id=0,
            ip_src='1.1.1.3',
            ip_dst='1.1.1.1',
            ip_ttl=64,
            ip_flags=0x2,
            udp_sport=udp_sport,
            with_udp_chksum=False,
            vxlan_vni=0x1234,
            inner_frame=pkt)
        pkt1 = simple_udp_packet(
            eth_dst='00:11:11:11:11:11',
            eth_src='00:22:22:22:22:22',
            # eth_dst='00:11:11:11:11:11',
            # eth_src='00:55:55:55:55:55',
            ip_dst='10.10.10.1',
            ip_src='10.10.10.2',
            ip_id = 105,
            ip_ttl = 64,
            pktlen = 70,
            udp_sport=0x1122,
            # udp_sport=0x4d2,
            with_udp_chksum = True)
        send_packet(self, ingress_port, pkt)
        # send_packet(self, ingress_port, vxlan_pkt)
        print("Expecting packet on port %d" % egress_port)
        verify_packets(self, pkt1, [egress_port])

    # Use this method to return the DUT to the initial state by cleaning
    # all the configuration and clearing up the connection
    def tearDown(self):
        try:
            print("Clearing table entries")
            for table in self.entries.keys():
                delete_func = "self.client." + table + "_table_delete"
                for entry in self.entries[table]:
                    exec delete_func + "(self.sess_hdl, self.dev, entry)"
        except:
            print("Error while cleaning up. ")
            print("You might need to restart the driver")
        finally:
            self.conn_mgr.complete_operations(self.sess_hdl)
            self.conn_mgr.client_cleanup(self.sess_hdl)
            print("Closed Session %d" % self.sess_hdl)
            pd_base_tests.ThriftInterfaceDataPlane.tearDown(self)

