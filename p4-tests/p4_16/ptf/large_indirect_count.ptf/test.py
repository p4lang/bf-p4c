import logging
import time
from ptf import config
from ptf.thriftutils import *
import ptf.testutils as testutils

from p4.v1 import p4runtime_pb2
from p4runtime_base_tests import P4RuntimeTest, autocleanup, stringify, ipv4_to_binary, mac_to_binary

import scapy
logger = logging.getLogger('large_indirect_count')
logger.addHandler(logging.StreamHandler())

# Validate Indirect counter table that are split on Tofino2+ to workaround the 3 row limitation.
# This also validate the tEOP configuration on large table also only available on Tofino2+.
class IndirectCountTest(P4RuntimeTest):
    @autocleanup
    def read_counter(self, cnt_index, gress = 0):
        req = p4runtime_pb2.ReadRequest()
        req.device_id = self.device_id
        entity = req.entities.add()
        counter_entry = entity.counter_entry
        if gress:
            cid = self.get_counter_id("SwitchEgress.cntr")
        else:
            cid = self.get_counter_id("SwitchIngress.cntr")

        counter_entry.counter_id = cid
        counter_entry.index.index = cnt_index
        for rep in self.stub.Read(req):
            for entity in rep.entities:
                counter_entry = entity.counter_entry
                if counter_entry.counter_id == cid and counter_entry.index.index == cnt_index:
                    return counter_entry.data.byte_count

    def runTest(self):
        ig_port = self.swports(1)
        eg_port = self.swports(2)
        dmac = '22:22:22:22:22:22'

        pkt = testutils.simple_tcp_packet(eth_dst=dmac)
        logger.info("Sending packet on port %d", ig_port)
        testutils.send_packet(self, ig_port, pkt)
        logger.info("Packet is expected to get dropped")
        testutils.verify_no_other_packets(self)

        for i in xrange(2048 * 22):
            if i % 1234 != 0:
                continue

            dmac = "00:11:22:33:%02x:%02x" % (i / 256, i % 256)
            cnt_index = i;
            byte_cnt = self.read_counter(cnt_index);
            self.assertEqual(byte_cnt, 0)

            # Create input and expected packets
            eth = Ether(dst=dmac, src='00:11:11:11:11:11', type=0x800)
            ip = IP()
            pkt = eth/ip
            pkt /= ("D" * (100 - len(pkt)))

            exp_pkt = Ether(dst=dmac, src='00:11:11:11:11:11', type=0xffff)
            exp_pkt /= ("D" * (100 - len(ip) - len(exp_pkt)))

            # The packet created above does not include the Ethernet FCS so add an additional
            # four bytes to the expected size to account for it.
            inp_pkt_size = len(pkt) + 4
            exp_pkt_size = len(exp_pkt) + 4

            self.send_request_add_entry_to_action(
                'SwitchIngress.forward',
                [self.Exact("hdr.ethernet.dst_addr", mac_to_binary(dmac))],
                'SwitchIngress.hit',
                [('port', stringify(eg_port, 2)),
                 ('index', stringify(cnt_index, 2))])

            self.send_request_add_entry_to_action(
                'SwitchEgress.forward',
                [self.Exact("hdr.ethernet.dst_addr", mac_to_binary(dmac))],
                'SwitchEgress.hit',
                [('index', stringify(cnt_index, 2))])

            logger.info("Sending packet on port %d with dmac %s", ig_port, dmac)
            testutils.send_packet(self, ig_port, pkt)
            testutils.verify_packets(self, exp_pkt, [eg_port])
            logger.info("Packet is expected to get forwarded to %d and cnt_index %d",
                        eg_port, cnt_index)

            byte_cnt = self.read_counter(cnt_index);
            self.assertEqual(byte_cnt, inp_pkt_size)

            byte_cnt = self.read_counter(cnt_index, 1);
            self.assertEqual(byte_cnt, exp_pkt_size)
