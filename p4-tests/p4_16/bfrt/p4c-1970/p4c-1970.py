# PTF test for p4c-1970
# p4testgen seed: 1000

import logging
import itertools

from bfruntime_client_base_tests import BfRuntimeTest
from ptf.mask import Mask
from ptf.testutils import send_packet
from ptf.testutils import verify_packet
from ptf.testutils import verify_no_other_packets
import bfrt_grpc.client as gc

logger = logging.getLogger('p4c-1970')
logger.addHandler(logging.StreamHandler())

class AbstractTest(BfRuntimeTest):
    def setUp(self):
        BfRuntimeTest.setUp(self, 0, 'p4c-1970')
        self.dev_id = 0
        self.table_entries = []
        self.bfrt_info = None
        self.target = None

    def tearDown(self):
        # Reset tables.
        for elt in reversed(self.table_entries):
            test_table = self.bfrt_info.table_get(elt[0])
            test_table.entry_del(self.target, elt[1])
        self.table_entries = []

        # End session.
        BfRuntimeTest.tearDown(self)

    def insertTableEntry(self, table_name, key_fields = None,
            action_name = None, data_fields = []):
        test_table = self.bfrt_info.table_get(table_name)
        key_list = [test_table.make_key(key_fields)]
        data_list = [test_table.make_data(data_fields, action_name)]
        test_table.entry_add(self.target, key_list, data_list)
        self.table_entries.append((table_name, key_list))

    def overrideDefaultEntry(self, table_name, action_name = None, data_fields = []):
        test_table = self.bfrt_info.table_get(table_name)
        data = test_table.make_data(data_fields, action_name)
        test_table.default_entry_set(self.target, data)

    def setupCtrlPlane(self):
        pass

    def sendPacket(self):
        pass

    def verifyPackets(self):
        pass

    def runTestImpl(self):
        # Get bfrt_info and set it as part of the test.
        self.bfrt_info = self.interface.bfrt_info_get('p4c-1970')

        # Set target to all pipes on device self.dev_id.
        self.target = gc.Target(device_id=0, pipe_id=0xffff)

        self.setupCtrlPlane()
        logger.info("Sending Packet ...")
        self.sendPacket()
        logger.info("Verifying Packet ...")
        self.verifyPackets()
        logger.info("Verifying no other packets ...")
        verify_no_other_packets(self, self.dev_id, timeout=2)

class Test1(AbstractTest):
    # Date generated: 2023-02-07-11:20:00.675
    # Current statement coverage: 0.79
    '''
    ImplInParser: [Parser] ImplInParser
    [State] start
    [Event]: Extract: Succeeded
    [Extract] ig_intr_md.resubmit_flag; = 0b0
    [Extract] ig_intr_md._pad1; = 0b0
    [Extract] ig_intr_md.packet_version; = 0b00
    [Extract] ig_intr_md._pad2; = 0b000
    [Extract] ig_intr_md.ingress_port; = 0b0000_0000_1110
    [Extract] ig_intr_md.ingress_mac_tstamp; = "Taint"
    [Event]: Extract Condition: p4t*zombie.const.0.*packetLen_bits >= 64; | Extract Size: 64
    [Event]: Advance Condition: p4t*zombie.const.0.*packetLen_bits >= 64;
    [Event]: Extract: Succeeded
    [Extract] hdr.eth.dstAddr; = 0x0000_0000_0000
    [Extract] hdr.eth.srcAddr; = 0x0000_0000_0000
    [Extract] hdr.eth.etherType; = 0x0000
    [Event]: Extract Condition: p4t*zombie.const.0.*packetLen_bits >= 112; | Extract Size: 112
    [Event]: Extract: Succeeded
    [Extract] hdr.common.currINF; = 0b00
    [Extract] hdr.common.currHF; = 0b0000_0001
    [Extract] hdr.common.value; = 0b0
    [Extract] hdr.common.reserved; = 0b0000_0000
    [Extract] hdr.common.data; = 0x0000_0000
    [Event]: Extract Condition: p4t*zombie.const.0.*packetLen_bits >= 160; | Extract Size: 48
    [State] selected
    [State] final
    [Event]: Extract: Succeeded
    [Extract] hdr.tail.data; = 0x0000
    [Event]: Extract Condition: p4t*zombie.const.0.*packetLen_bits >= 176; | Extract Size: 16
    [State] accept
    [Event]: Control ImplIngress start
    [Expression]: If Statement true: p4t*zombie.const.7.pktVar == 0; = 1;
    [Event]: Control ImplInDeparser start
    [Emit] hdr.eth.dstAddr; = 0x0000_0000_0000
    [Emit] hdr.eth.srcAddr; = 0x0000_0000_0000
    [Emit] hdr.eth.etherType; = 0x0000
    [Emit] hdr.eth.*valid; = 1;
    [Emit] hdr.common.currINF; = 0b00
    [Emit] hdr.common.currHF; = 0b0000_0001
    [Emit] hdr.common.value; = 0b0
    [Emit] hdr.common.reserved; = 0b0000_0000
    [Emit] hdr.common.data; = 0x0000_0000
    [Emit] hdr.common.*valid; = 1;
    [Emit] hdr.tail.data; = 0x0000
    [Emit] hdr.tail.*valid; = 1;
    [Event]: Prepending the emit buffer to the program packet.
    [Expression]: If Statement true: 1 == 1; = 1;
    '''

    def setupCtrlPlane(self):
        pass

    def sendPacket(self):
        ig_port = 14
        pkt = b'\x11\x22\x33\x44\x55\x66\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00\x19\xED\xF0\x9A\x0A\x62\x14\xA0\xFA\xB6\x38\x70\x46\x50\x2F\xAE\xBF\x81\xB5\x0B\xA2\x79\xF6\xA4\x02\xBB\x33\x12\xB8\x0E\xA3\x51\x60\x78\xEA\xEB\x0F\x64\x8A\xE8\x02\xAA\x86\xE4\x2E\xAA\x29\xF9\x78\xAE\xBB\x20\xD3\x2B\x4D\x2D\xD8\xC0\x02\x78\x3D\xA5\x92\xD9\x5B\xA5\xC8\xB1\x02\x12\x58\x73\xCE\xE1\xB7\x04\xA5\x08\x7B\x33\x26\x78\x05\x6E\xB8\x44\x0C\xC7\xA5\xC3\x0B\x2E\x56\x82\x1D\x13\x9F\x04\xB6\xE2\x14\x4B\xC5\xBE\xCF\xA0\x91\x65\xF0\xC1\x4F\x4A\x89\xBF\xD7\xB2\xAB\x38\x2F\x01\x71\xAB\x9B\x22\x20\x42\xAE\xBC\x84\x4E\x0B\x3E\xA0\x05\x01\xBB\x6D\x03\x92\x13\x16\x26\x6D\xF8\x8E\x28\x9E\x02\xAA\xFF\x1F\x9A\x05\xDA\x00\xE7\x79\x7E\xBB\x05\x4E\x15\x7B\xE2\x95\x73\x71\x32\xE0\xF4\xAB\x8D\xD8\xA9\x5C\xD7\xA8\x43\x57\xC4\x03\xCC\xF4\x95\x28\x50\x90\xA8\x41\xC4\x07\x0E\xBD\x50\x64\xDA\xE5\x19\x1A\xDC\xC8\x51\x15\x08\xFC\xB3\x32\xD4\x5F\xF7\xB4\x5C\xA3\xF9\xA0\x92\x09\x0F\x4B\xB4\xE9\x73\xB4\x3D\x9F\x40\x0B\x56\xF2\x7E\xCC\xD0\xFA\xAE\x45\xFB\x66\x27\x3D\x7A\x00\xDE\x0E\x07\x6B\x57\x9E\xA8\x97\x88\x8A\x6A\x59\xAE\xDD\x3E\x99\xA4\xD5\xEE\x5F\x6A\x9C\xDA\xFE\x22\xD2\xF3\xE0\x80\xCD\x15\xFA\xA8\xF4\xE2\xA5\x75\x9E\xD1\x3A\x87\x9C\x11\xD0\x21\x9E\xE7\xAE\x8B\x72\xBE\x58\x99\x58\x05\x6D\x14\xE9\x2E\xA8\x5D\x1E\x0F\x71\x69\xF2\x64\x64\x36\x94\xE8\x1A\x40\xE4\xBE\x12\x7B\xA9\xC5\xC2\xBD\x3A\x35\x03\x59\x2A\x93\x06\xA9\xEF\xD7\x7C\x51\xED\xDA\x0C\x1A\xBC\x3B\xAE\x8D\x24\x2D\x0E\xA0\xDB\x65\xAE\x89\x5C\x58\x20\x17\x69\x0A\x6B\xF2\x28\x03\x7B\x0E\x2D\x36\x5B\x6F\x59'
        send_packet(self, ig_port, pkt)

    def verifyPackets(self):
        eg_port = 0
        exp_pkt = b'\x11\x22\x33\x44\x55\x66\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00\x19\xED\xF0\x9A\x0A\x62\x14\xA0\xFA\xB6\x38\x70\x46\x50\x2F\xAE\xBF\x81\xB5\x0B\xA2\x79\xF6\xA4\x02\xBB\x33\x12\xB8\x0E\xA3\x51\x60\x78\xEA\xEB\x0F\x64\x8A\xE8\x02\xAA\x86\xE4\x2E\xAA\x29\xF9\x78\xAE\xBB\x20\xD3\x2B\x4D\x2D\xD8\xC0\x02\x78\x3D\xA5\x92\xD9\x5B\xA5\xC8\xB1\x02\x12\x58\x73\xCE\xE1\xB7\x04\xA5\x08\x7B\x33\x26\x78\x05\x6E\xB8\x44\x0C\xC7\xA5\xC3\x0B\x2E\x56\x82\x1D\x13\x9F\x04\xB6\xE2\x14\x4B\xC5\xBE\xCF\xA0\x91\x65\xF0\xC1\x4F\x4A\x89\xBF\xD7\xB2\xAB\x38\x2F\x01\x71\xAB\x9B\x22\x20\x42\xAE\xBC\x84\x4E\x0B\x3E\xA0\x05\x01\xBB\x6D\x03\x92\x13\x16\x26\x6D\xF8\x8E\x28\x9E\x02\xAA\xFF\x1F\x9A\x05\xDA\x00\xE7\x79\x7E\xBB\x05\x4E\x15\x7B\xE2\x95\x73\x71\x32\xE0\xF4\xAB\x8D\xD8\xA9\x5C\xD7\xA8\x43\x57\xC4\x03\xCC\xF4\x95\x28\x50\x90\xA8\x41\xC4\x07\x0E\xBD\x50\x64\xDA\xE5\x19\x1A\xDC\xC8\x51\x15\x08\xFC\xB3\x32\xD4\x5F\xF7\xB4\x5C\xA3\xF9\xA0\x92\x09\x0F\x4B\xB4\xE9\x73\xB4\x3D\x9F\x40\x0B\x56\xF2\x7E\xCC\xD0\xFA\xAE\x45\xFB\x66\x27\x3D\x7A\x00\xDE\x0E\x07\x6B\x57\x9E\xA8\x97\x88\x8A\x6A\x59\xAE\xDD\x3E\x99\xA4\xD5\xEE\x5F\x6A\x9C\xDA\xFE\x22\xD2\xF3\xE0\x80\xCD\x15\xFA\xA8\xF4\xE2\xA5\x75\x9E\xD1\x3A\x87\x9C\x11\xD0\x21\x9E\xE7\xAE\x8B\x72\xBE\x58\x99\x58\x05\x6D\x14\xE9\x2E\xA8\x5D\x1E\x0F\x71\x69\xF2\x64\x64\x36\x94\xE8\x1A\x40\xE4\xBE\x12\x7B\xA9\xC5\xC2\xBD\x3A\x35\x03\x59\x2A\x93\x06\xA9\xEF\xD7\x7C\x51\xED\xDA\x0C\x1A\xBC\x3B\xAE\x8D\x24\x2D\x0E\xA0\xDB\x65\xAE\x89\x5C\x58\x20\x17\x69\x0A\x6B\xF2\x28\x03\x7B\x0E\x2D\x36\x5B\x6F\x59'
        exp_pkt = Mask(exp_pkt)
        verify_packet(self, exp_pkt, eg_port)

    def runTest(self):
        self.runTestImpl()
