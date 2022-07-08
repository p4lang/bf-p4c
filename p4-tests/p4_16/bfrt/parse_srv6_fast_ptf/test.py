# PTF test for parse_srv6_fast
# p4testgen seed: '1000'

import logging
import itertools

from bfruntime_client_base_tests import BfRuntimeTest
from ptf.mask import Mask
from ptf.testutils import send_packet
from ptf.testutils import verify_packet
from ptf.testutils import verify_no_other_packets
import bfrt_grpc.client as gc

logger = logging.getLogger('parse_srv6_fast_ptf')
logger.addHandler(logging.StreamHandler())

class AbstractTest(BfRuntimeTest):
    def setUp(self):
        BfRuntimeTest.setUp(self, 0, 'parse_srv6_fast_ptf')
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

    def setupCtrlPlane(self):
        pass

    def sendPacket(self):
        pass

    def verifyPackets(self):
        pass

    def runTestImpl(self):
        # Get bfrt_info and set it as part of the test.
        self.bfrt_info = self.interface.bfrt_info_get('parse_srv6_fast_ptf')

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
    # Date generated: 2022-06-14-13:04:39.890
    # Current statement coverage: 0.64
    '''
    ingress_parser: [Parser] ingress_parser
    [State] start
    [Extract] ingress_intrinsic_metadata.resubmit_flag; = 0b0
    [Extract] ingress_intrinsic_metadata._pad1; = "Taint"
    [Extract] ingress_intrinsic_metadata.packet_version; = "Taint"
    [Extract] ingress_intrinsic_metadata._pad2; = "Taint"
    [Extract] ingress_intrinsic_metadata.ingress_port; = 0b0_0000_0000
    [Extract] ingress_intrinsic_metadata.ingress_mac_tstamp; = "Taint"
    [Extract] ingress_intrinsic_metadata.*valid; = 1;
    [Event]: Extract Condition: p4t*zombie.const.0.*packetLen_bits >= 64;
    [Event]: Advance Condition: p4t*zombie.const.0.*packetLen_bits >= 64;
    [Extract] hdr.ethernet.daddr; = 0x0000_0000_0000
    [Extract] hdr.ethernet.saddr; = 0x0000_0000_0000
    [Extract] hdr.ethernet.type; = 0x86dd
    [Extract] hdr.ethernet.*valid; = 1;
    [Event]: Extract Condition: p4t*zombie.const.0.*packetLen_bits >= 112;
    [State] parse_ipv6
    [Extract] hdr.ipv6.version; = 0x0
    [Extract] hdr.ipv6.dscp; = 0b00_0000
    [Extract] hdr.ipv6.ecn; = 0b00
    [Extract] hdr.ipv6.flowlabel; = 0x0_0000
    [Extract] hdr.ipv6.payload_len; = 0x0000
    [Extract] hdr.ipv6.nexthdr; = 0x2b
    [Extract] hdr.ipv6.hoplimit; = 0x00
    [Extract] hdr.ipv6.saddr; = 0x0000_0000_0000_0000_0000_0000_0000_0000
    [Extract] hdr.ipv6.daddr; = 0x0000_0000_0000_0000_0000_0000_0000_0000
    [Extract] hdr.ipv6.*valid; = 1;
    [Event]: Extract Condition: p4t*zombie.const.0.*packetLen_bits >= 432;
    [State] parse_ipv6_routing_header
    [Extract] hdr.ipv6_routing_hdr.nexthdr; = 0x00
    [Extract] hdr.ipv6_routing_hdr.length; = 0x00
    [Extract] hdr.ipv6_routing_hdr.type; = 0x04
    [Extract] hdr.ipv6_routing_hdr.segments_left; = 0x01
    [Extract] hdr.ipv6_routing_hdr.*valid; = 1;
    [Event]: Extract Condition: p4t*zombie.const.0.*packetLen_bits >= 464;
    [State] parse_srv6_srh
    [Extract] hdr.srv6_srh.last_entry; = 0x00
    [Extract] hdr.srv6_srh.flags; = 0x00
    [Extract] hdr.srv6_srh.tag; = 0x0000
    [Extract] hdr.srv6_srh.*valid; = 1;
    [Event]: Extract Condition: p4t*zombie.const.0.*packetLen_bits >= 496;
    [State] parse_srv6_sid_first_1
    [Extract] hdr.srv6_sid.0.sid; = 0xe063_6761_df05_9336_cd1d_5bb3_c447_4680
    [Extract] hdr.srv6_sid.0.*valid; = 1;
    [Event]: Extract Condition: p4t*zombie.const.0.*packetLen_bits >= 624;
    [State] parse_ipv6_nexthdr
    [State] accept
    [Event]: Table Branch: ingress_mau.forward Chosen action: ingress_mau.send_to
    [Expression]: Invalid emit: hdr.bridged_metadata.*valid;:  = 0;
    [Emit] hdr.ethernet.daddr; = 0x0000_0000_0000
    [Emit] hdr.ethernet.saddr; = 0x0000_0000_0000
    [Emit] hdr.ethernet.type; = 0x86dd
    [Emit] hdr.ethernet.*valid; = 1;
    [Emit] hdr.ipv6.version; = 0x0
    [Emit] hdr.ipv6.dscp; = 0b00_0000
    [Emit] hdr.ipv6.ecn; = 0b00
    [Emit] hdr.ipv6.flowlabel; = 0x0_0000
    [Emit] hdr.ipv6.payload_len; = 0x0000
    [Emit] hdr.ipv6.nexthdr; = 0x2b
    [Emit] hdr.ipv6.hoplimit; = 0x00
    [Emit] hdr.ipv6.saddr; = 0x0000_0000_0000_0000_0000_0000_0000_0000
    [Emit] hdr.ipv6.daddr; = 0x0000_0000_0000_0000_0000_0000_0000_0000
    [Emit] hdr.ipv6.*valid; = 1;
    [Emit] hdr.ipv6_routing_hdr.nexthdr; = 0x00
    [Emit] hdr.ipv6_routing_hdr.length; = 0x00
    [Emit] hdr.ipv6_routing_hdr.type; = 0x04
    [Emit] hdr.ipv6_routing_hdr.segments_left; = 0x01
    [Emit] hdr.ipv6_routing_hdr.*valid; = 1;
    [Emit] hdr.srv6_srh.last_entry; = 0x00
    [Emit] hdr.srv6_srh.flags; = 0x00
    [Emit] hdr.srv6_srh.tag; = 0x0000
    [Emit] hdr.srv6_srh.*valid; = 1;
    [Emit] hdr.srv6_sid.0.sid; = 0xe063_6761_df05_9336_cd1d_5bb3_c447_4680
    [Emit] hdr.srv6_sid.0.*valid; = 1;
    [Expression]: Invalid emit: hdr.srv6_sid.1.*valid;:  = 0;
    [Expression]: Invalid emit: hdr.srv6_sid.2.*valid;:  = 0;
    [Expression]: Invalid emit: hdr.srv6_sid.3.*valid;:  = 0;
    [Expression]: If Statement: 511 == p4t*zombie.const.0.ingress_mau.forward_param_ingress_mau.send_to0 || 1 == 0; = 1;
    [Event]: Packet marked dropped.
    '''

    def setupCtrlPlane(self):
        # Table ingress_mau.forward
        self.insertTableEntry(
            'ingress_mau.forward',
            [
                gc.KeyTuple('ingress_intrinsic_metadata.ingress_port', 0x0),
                gc.KeyTuple('ingress_metadata.srv6_current_sid', 0xe0636761df059336cd1d5bb3c4474680),
            ],
            'ingress_mau.send_to',
            [
                gc.DataTuple('port', 0x1ff),
            ]
        )

    def sendPacket(self):
        ig_port = 0
        pkt = b'\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x86\xdd\x00\x00\x00\x00\x00\x00\x2b\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x04\x01\x00\x00\x00\x00\xe0\x63\x67\x61\xdf\x05\x93\x36\xcd\x1d\x5b\xb3\xc4\x47\x46\x80\x36\xd9\x3a\xcb\x04\x1d\x23\x38\x9b\x11\x2e\xe9\x02\xf5\x72\x5b\x69\xc9\xbd\x09\x95\x24\x28\x7d\x2d\x93\xfb\x4a\x81\x39\xe7\x51\xde\x4f\x6d\xe3\xc8\x03\x92\x7e\xa5\x30\x2a\xac\xac\x98\xd4\xd6\xe5\x91\x0a\xbe\xd1\x81\x89\xc4\x87\x58\xee\x09\xf8\x0b\x10\xa3\xe4\x79\xeb\x57\x94\xba\x55\x9e\x10\xc9\xc2\x4a\x59\x43\xd0\x29\x56\x6f\x06\xd1\x3a\xbe\x7b\xe3\x21\xcb\xb6\x66\xfe\x9c\xc6\xfe\x41\x22\xb2\x33\x71\x4e\xbc\xc3\x02\xa7\x8b\x50\x2b\x21\x95\xb3\xec\x50\x95\x00\xfc\x78\xaa\x74\xcf\x6c\x3d\xed\x4e\x85\x76\x73\xd5\xea\xc1\x6c\x9c\xdb\xb2\xaf\xbd\x4e\xec\xca\xc1\x9d\x39\x0b\x4a\x98\x37\xda\xb6\x61\x63\xab\x9c\xde\xc7\x85\xea\x8f\x15\xb3\x14\x14\xe6\x74\x01\xbf\x1b\x37\x08\xf1\x0d\xee\xc2\x85\xf6\x3e\xf5\x88\x93\xb1\x1c\xc0\x56\x09\xe6\x5e\x77\xb4\x75\x07\x2b\x57\x2a\xb3\x1f\x6a\xd5\xf0\x1b\xb7\x96\x16\x47\x18\x3a\xe3\xbf\x47\x5a\xed\x09\x10\xa1\xbd\x83\x5c\x91\x9c\xf1\xb5\xc1\xe2\x76\x69\x7a\xce\x55\x9d\xf5\x77\xfd\xa7\x37\x84\x0d\x31\x1f\x77\x43\x12\x4b\xb6\xb1\x8d\xda\xba\xe7\xc5\x4e\x67\x6a\xa8\x72\xdb\x08\x2a\x5c\x16\x74\xf5\xa9\x47\x8b\x44\x49\x32\x41\x7b\x99\x47\x98\xcd\x4b\x87\x3b\x2b\xc1\x1f\xd9\xd2\xb8\x34\x15\x3e\x44\xfc\x18\x9c\xb8\x4d\x6b\x99\xd5\x4b\x0c\x64\xaf\xf3\x3d\xa2\x61\x6d\xa0\x08\x0b\x26\xec\xb1\x7a\xa2\x85\x6f\xec\xde\xf4\xf1\x0e\x69\x3f\x16\xb3\xee\xdc\xf6\x0e\x6d\x42\x20\xab\x98\xe2\xb2\xb3\xfa\xc0\xb1\x7e\x15\x8b\xd8\x36\x06\x81\x81\x7b\xa6\x3a\x9f\x0b\x4e\x57\xd6\x43\xde\x89\xc7\x25\xeb\x1b\xc2\x93\x1e\x12\xe3\x6c\x8a\xbf\xbb\x03\xdf\x94\xdc\x8c\x5c\x20\xea\x8c\xd5\x6a\xad\xe1\x32\x32\xf8\x58\x02\x76\x7e\xa1\xfe\xd6\xf2\xce\x0b\x4f\x77\x18\x9e\x59\xd4\x3e\xc6\x95\x08\x69\xd9\x15\x39\x80\x42\x6f\xff\x67\x76\x23\xbb\x38\x8b\x79\x09\x28\x8f\x49\xc8\x15\x55\x24\xab\x32\x05\xd7\x52\xd3\x56\x5a\xdd\x03\xcd\x80\xed\x43\x6c\x32\xfd\xe7\xec\xd7\x39\xe1\xd2\x68\x34\x05\xf0\x00\x20\x6f\x86\x0e\x4b\x33\x1e\xa5\x7f\xb3\xa6\xe7\xa7\x0e\x09\x9d\x49\x0d\x84\x66\x4e\xf5\x19\x88\x42\xa9\x13\xf7\x29\xda\x44\x24\x0d\x12\x23\xeb\x27\xbb\xf1\x65\xb7\x80\xf7\xb1\x24\x9b\x69\x7a\x25\x17\x57\xf3\x7f\x49\x83\x2a\x6e\x0d\x21\x02\x69\xd4\x07\xe1\x4d\x0d\x88\xfa\x3f\x00\x61\xee\x5d\xe0\x5a\xd0\xf2\xc9\x44\x80\x43\xf2\xc0\xea\xf1\x58\xdf\x78\xf8\xdb\x07\x60\xd8\x62\x39\x45\x51\xf4\xce\xcb\x31\x8e\xaa\x61\xe1\xd3\x4c\x6c\x41\x03\x66\x1e\xde\xb8\xe9\x86\x2c\xad\x31\xc2\x45\x79\x70\xfa\x9a\xbd\x32\x57\x1b\xe2\xb9\x73\x97\x63\xe7\x05\x57\x5d\xb2\x3c\x25\x0c\xd4\x73\x0a\x8c\x24\x44\xdb\x56\x0c\xd6\xe4\x81\xd7\x86\x12\x4e\x46\xdd\x23\x04\x0a\x18\xe0\xd0\x78\x4e\x23\x1c\xc4\x3b\xd6\x67\x1e\x27\x2b\xfd\x22\x34\x0c\x11\xa6\xaf\x73\xa8\xd3\x7c\xa8\xc0\x87\x24\x83\x26\x52\xc6\x16\xef\x91\xea\xb4\x9b\x0c\x3f\x60\x37\x4f\x07\x41\x02\x40\x1e\x01\xc2\xb7\x99\xa8\x4a\xdf\x81\xfb\xfc\x14\x3b\x64\x6e\xd4\xb3\x13\x91\xb8\xc6\xee\x78\x38\xa8\xb0\x03\x57\xd8\x96\x6d\xf0\xa6\x09\xe7\x49\x2d\x57\x65\x1d\x16\xa7\xfa\xd7\xcd\x98\xf7\x2c\xd8\x90\x3a\x88\x10\x32\x9c\x4c\x9b\x46\x98\x67\x04\xcc\x7d\x8c\x3c\xaa\x9b\x5a\x40\x74\x0a\xaf\xc6\x85\x66\x0a\x63\xd2\x53\x72\x86\xf5\x4f\x18\x34\xdf\x36\xc6\xc4\x8b\x70\xe1\xd0\x88\x34\x61\xd9\x5f\x6d\x4e\xa5\x0c\x8e\x71\x83\x90\x6e\xda\x74\x59\xa2\x51\xd3\x63\xd0\xc5\x69\xb0\x05\x96\x6c\x43\x5a\x5e\x50\xd7\xc2\x0a\xcc\x24\x04\x4c\xba\xe4\x98\xbd\xb0\x62\x11\xe3\x1c\x1a\x82\xed\x45\x5e\xcc\x81\x3d\x0e\x75\x17\xab\x30\xf1\xff\x47\x48\x5c\x9b\x88\xe8\x2f\xe0\x7f\x2f\x10\x43\xdd\x14\x32\x7a\xa1\x44\xee\x9b\x35\x80\x12\x25\x19\x15\x5e\x14\xdd\x27\x47\xc1\x96\x98\x3c\xf8\xf4\x36\x79\x23\x27\xda\xa5\xaf\x16\xd6\x24\x32\x59\x82\x1f\xca\x50\xb6\x3a\x55\xf4\xdc\xfe\x8c\xec\x82\xa2\x02\x85\xcf\xe0\xb7\xbb\xfb\x92\x6a\x91\x24\x31\x32\x54\x80\x28\x12\x4b\xfa\xf4\xdd\xbc\xe4\xf8\xa6\xff\x60\xae\xc7\x65\xaf\x3d\xc7\x5d\x37\xa0\x6b\x84\xce\x81\x7f\x88\x39\x97\x07\xfa\x9c\x20\x06\x87\xda\x53\xfc\x1d\xff\xf4\xe1\x91\x6c\xae\x11\xac\x0c\xfb\x9e\xef\xaf\xbb\xe4\x31\x1b\x85\xba\x90\xb1'
        send_packet(self, ig_port, pkt)

    def verifyPackets(self):
        pass

    def runTest(self):
        self.runTestImpl()

