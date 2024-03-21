################################################################################
# BAREFOOT NETWORKS CONFIDENTIAL & PROPRIETARY
#
# Copyright (c) 2018-2019 Barefoot Networks, Inc.

# All Rights Reserved.
#
# NOTICE: All information contained herein is, and remains the property of
# Barefoot Networks, Inc. and its suppliers, if any. The intellectual and
# technical concepts contained herein are proprietary to Barefoot Networks,
# Inc.
# and its suppliers and may be covered by U.S. and Foreign Patents, patents in
# process, and are protected by trade secret or copyright law.
# Dissemination of this information or reproduction of this material is
# strictly forbidden unless prior written permission is obtained from
# Barefoot Networks, Inc.
#
# No warranty, explicit or implicit is provided, unless granted under a
# written agreement with Barefoot Networks, Inc.
#
#
###############################################################################


#include ptf
import ptf
import ptf.testutils as utils

#include grpc
import grpc

#include bfrt
import bfrt_grpc.bfruntime_pb2 as bfruntime_pb2
import bfrt_grpc.client as gc
from bfruntime_client_base_tests import BfRuntimeTest

import pd_base_tests

import pdb

#include scapy
import scapy
import scapy.all
import scapy.packet

from ptf import config

#p4 name
p4_name = 'p4c_2549'

#temp parameter
TEMP_MAC1 = '11:33:55:77:99:00'
TEMP_MAC2 = '22:11:22:33:44:55'
TEMP_MAC3 = '33:34:56:78:9a:bc'

#define
DEFAULT_FORWARD_PORT = 0
EXCEPTION_REPORT_PORT = 64
DEFAULT_MAC_ADDR = '00:11:22:33:44:55'

ETHERTYPE_NSH = 35151
IP_PROTOCOLS_ICMP = 1
IP_PROTOCOLS_TCP = 6
IP_PROTOCOLS_UDP = 17
NSH_PROTOCOLS_ETHERNET = 3

swports = []
for device, port, ifname in config["interfaces"]:
    swports.append(port)
    swports.sort()

#nsh define
class NSH(scapy.packet.Packet):
   name = "NshPacket"
   fields_desc = [
         scapy.fields.BitField("version", 0, 2),
         scapy.fields.BitField("oam", 0, 1),
         scapy.fields.BitField("undefined_1", 0, 1),
         scapy.fields.BitField("ttl", 63, 6),
         scapy.fields.BitField("len", 6, 6),
         scapy.fields.BitField("undefined_2", 0, 4),
         scapy.fields.BitField("md_type", 1, 4),
         scapy.fields.BitField("next_protocol", 0, 8),
         scapy.fields.BitField("spi", 1, 24),
         scapy.fields.BitField("si", 255, 8),
         scapy.fields.BitField("context", 0, 128),
         ]

scapy.all.bind_layers(scapy.all.Ether, NSH, type=35151)
scapy.all.bind_layers(NSH, scapy.all.Ether, next_protocol=3)

#general test
class GeneralTest(BfRuntimeTest):
    def setUp(self):
        print('ptf print: func setUp start')

        #init context
        self.client_id = 0
        self.p4_name = p4_name
        self.dev = 0
        self.dev_tgt = gc.Target(device_id=0, pipe_id=0xffff)

        BfRuntimeTest.setUp(self, self.client_id, self.p4_name)
        self.bfrt_info = self.interface.bfrt_info_get(self.p4_name)

        #init table
        self.tbl = {}

        self.tbl['tblIpv4Forward'] = self.bfrt_info.table_get("SwitchIngress.tblIpv4Forward")
        self.tbl['tblIpv4Forward'].info.key_field_annotation_add("ipv4_src", "ipv4")
        self.tbl['tblIpv4Forward'].info.key_field_annotation_add("ipv4_dst", "ipv4")

        self.tableClean()

        print('ptf print: func setUp exit')

    def tableConfig(self):
        pass
        #tblIpv4Forward
        table = self.tbl['tblIpv4Forward']
        table.entry_add(self.dev_tgt,
            [table.make_key([gc.KeyTuple('$MATCH_PRIORITY', 1),
                gc.KeyTuple("ipv4_src", '1.1.0.0', mask= '255.255.0.0'),
                gc.KeyTuple("ipv4_dst", '0.0.0.0', mask= '0.0.0.0'),
                gc.KeyTuple("next_protocol", 0, mask= 0),
                gc.KeyTuple("src_port", low= 0, high= 2**16-1),
                gc.KeyTuple("dst_port", low= 0, high= 2**16-1),
            ])],
            [table.make_data([
                gc.DataTuple('port', swports[1]),
                ], 'SwitchIngress.TransparentForward',
            )])
        table.entry_add(self.dev_tgt,
            [table.make_key([gc.KeyTuple('$MATCH_PRIORITY', 1),
                gc.KeyTuple("ipv4_src", '1.2.3.4', mask= '255.255.255.255'),
                gc.KeyTuple("ipv4_dst", '4.3.2.1', mask= '255.255.255.255'),
                gc.KeyTuple("next_protocol", IP_PROTOCOLS_ICMP, mask= 2**8-1),
                gc.KeyTuple("src_port", low= 0, high= 2**16-1),
                gc.KeyTuple("dst_port", low= 0, high= 2**16-1),
            ])],
            [table.make_data([
                gc.DataTuple('port', swports[7]),
                gc.DataTuple('spi', 1),
                ], 'SwitchIngress.AddNshForward',
            )])


    def tableClean(self):
        for name, tbl in self.tbl.items():
            keys = []
            for (d, k) in tbl.entry_get(self.dev_tgt):
                if k is not None:
                    keys.append(k)
            tbl.entry_del(self.dev_tgt, keys)

    def packetTest(self, name, pktSend, portSend, pktExp, portExp):
        print('ptf print: pkt test: '+name)
        print('ptf print: pkt send port: '+str(portSend))
        print('ptf print: pkt send detail: ')
        print(pktSend.show())
        utils.send_packet(self, portSend, pktSend)
        print('ptf print: pkt exp port: '+str(portExp))
        print('ptf print: pkt exp detail: ')
        print(pktExp.show())
        utils.verify_packet(self, pktExp, portExp)
        print('ptf print: pkt verify correct')


    def runTest(self):
        print('ptf print: func runTest start')

        #config table
        self.tableConfig()

        #test pkt
        name = 'ipv4-icmp to add-nsh'
        pktSend = utils.simple_icmp_packet(eth_src= TEMP_MAC3, eth_dst= TEMP_MAC2,
            ip_src= '1.2.3.4', ip_dst= '4.3.2.1')
        portSend = swports[6]
        pktExp = scapy.all.Ether(src= DEFAULT_MAC_ADDR, dst= DEFAULT_MAC_ADDR)\
            /NSH(ttl= 63, spi= 1, si= 255)/pktSend
        portExp = swports[7]
        self.packetTest(name, pktSend, portSend, pktExp, portExp)

        #verify other pkt
        utils.verify_no_other_packets(self)
        print('ptf print: all pkt drop correct\n')

        print('ptf print: func runTest exit')

    def tearDown(self):
        print('ptf print: func tearDown start')
        self.tableClean()
        BfRuntimeTest.tearDown(self)
        print('ptf print: func tearDown exit')
