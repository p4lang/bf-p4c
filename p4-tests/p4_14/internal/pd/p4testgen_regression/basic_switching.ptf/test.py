# PTF test for basic_switching
# p4testgen seed: 917483060

import pd_base_tests
from ptf.mask import Mask
from ptf.testutils import send_packet
from ptf.testutils import verify_packet
from ptf.testutils import verify_no_other_packets
from ptf.thriftutils import hex_to_byte
from ptf.thriftutils import hex_to_i16
from ptf.thriftutils import hex_to_i32

from res_pd_rpc.ttypes import DevTarget_t

from basic_switching.p4_pd_rpc.ttypes import *

class AbstractTest(pd_base_tests.ThriftInterfaceDataPlane):
    def __init__(self):
        pd_base_tests.ThriftInterfaceDataPlane.__init__(self, ['basic_switching'])
    
    def setUp(self):
        pd_base_tests.ThriftInterfaceDataPlane.setUp(self)
        self.sess_hdl = self.conn_mgr.client_init()
        self.dev_id = 0;
        self.dev_tgt = DevTarget_t(self.dev_id, hex_to_i16(0xffff))
        self.match_entries = { 'acl': [], 'forward': [], }
        self.profile_members = { }
    
    def resetTable(self, table_name, reset_default):
        for entry in self.match_entries[table_name]:
            getattr(self.client, table_name + '_table_delete')(
                self.sess_hdl, self.dev_id, entry)
        
        if reset_default:
            # Only reset the default entry if the API for doing so exists.
            # (No API is generated for unused tables.)
            method_name = table_name + '_table_reset_default_entry'
            if hasattr(self.client, method_name):
                method = getattr(self.client, method_name)
                if callable(method):
                    method(self.sess_hdl, self.dev_tgt)
    
    def resetActionProfile(self, action_profile_name):
        for entry in self.profile_members[action_profile_name]:
            getattr(self.client, action_profile_name + '_del_member')(
                self.sess_hdl, self.dev_id, entry)
    
    def tearDown(self):
        # Reset tables.
        self.resetTable('acl', True)
        self.resetTable('forward', True)
        
        # End session.
        self.conn_mgr.client_cleanup(self.sess_hdl)
        pd_base_tests.ThriftInterfaceDataPlane.tearDown(self)
    
    def setupCtrlPlane(self):
        pass
    
    def sendPacket(self):
        pass
    
    def verifyPackets(self):
        pass
    
    def runTestImpl(self):
        self.setupCtrlPlane()
        self.conn_mgr.complete_operations(self.sess_hdl)
        self.sendPacket()
        self.verifyPackets()
        verify_no_other_packets(self, self.dev_id, timeout=2)

class Test1(AbstractTest):
    """
    Ingress packet on port 11:
        ethernet =
            dstAddr = 0x81be20cb9a03
            srcAddr = 0xc482a63893a0
            etherType = 0x2d6a
    
    Trace:
        [ Parser ] start
        [ Parser ] _parse_ethernet
        [ Action ] forward <hit> (set_egr)
    No egress: packet dropped.
    """
    
    def setupCtrlPlane(self):
        # Table forward
        match_spec = basic_switching_forward_match_spec_t(
            ethernet_dstAddr = b'\x81\xbe\x20\xcb\x9a\x03',)
        self.match_entries['forward'].append(
            self.client.forward_table_add_with_set_egr(
                self.sess_hdl, self.dev_tgt, match_spec,
                basic_switching_set_egr_action_spec_t(
                    action_egress_spec = hex_to_i16(0x01ff),)))
    
    def sendPacket(self):
        ig_port = 11
        pkt = b'\x81\xbe\x20\xcb\x9a\x03\xc4\x82\xa6\x38\x93\xa0\x2d\x6a\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00'
        send_packet(self, ig_port, pkt)
    
    
    def runTest(self):
        self.runTestImpl()

class Test2(AbstractTest):
    """
    Ingress packet on port 5:
        ethernet =
            dstAddr = 0xc49d08fe92b1
            srcAddr = 0x73111cf1d7e5
            etherType = 0xe0bb
    
    Trace:
        [ Parser ] start
        [ Parser ] _parse_ethernet
        [ Action ] forward <hit> (set_egr)
        [ Action ] acl <hit> (_drop)
    No egress: packet dropped.
    """
    
    def setupCtrlPlane(self):
        # Table acl
        match_spec = basic_switching_acl_match_spec_t(
            ethernet_dstAddr = b'\xc4\x9d\x08\xfe\x92\xb1',
            ethernet_dstAddr_mask = b'\xff\xff\xff\xff\xff\xff',
            ethernet_srcAddr = b'\x73\x11\x1c\xf1\xd7\xe5',
            ethernet_srcAddr_mask = b'\xff\xff\xff\xff\xff\xff',)
        self.match_entries['acl'].append(
            self.client.acl_table_add_with__drop(
                self.sess_hdl, self.dev_tgt, match_spec, 0))
        # Table forward
        match_spec = basic_switching_forward_match_spec_t(
            ethernet_dstAddr = b'\xc4\x9d\x08\xfe\x92\xb1',)
        self.match_entries['forward'].append(
            self.client.forward_table_add_with_set_egr(
                self.sess_hdl, self.dev_tgt, match_spec,
                basic_switching_set_egr_action_spec_t(
                    action_egress_spec = hex_to_i16(0x000b),)))
    
    def sendPacket(self):
        ig_port = 5
        pkt = b'\xc4\x9d\x08\xfe\x92\xb1\x73\x11\x1c\xf1\xd7\xe5\xe0\xbb\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00'
        send_packet(self, ig_port, pkt)
    
    
    def runTest(self):
        self.runTestImpl()

class Test3(AbstractTest):
    """
    Ingress packet on port 3:
        ethernet =
            dstAddr = 0x5248ae9d69a0
            srcAddr = 0x973694fe208f
            etherType = 0x28c6
    
    Trace:
        [ Parser ] start
        [ Parser ] _parse_ethernet
        [ Action ] forward <hit> (set_egr)
        [ Action ] acl <hit> (nop)
    
    Egress packet on port 64:
        ethernet =
            dstAddr = 0x5248ae9d69a0
            srcAddr = 0x973694fe208f
            etherType = 0x28c6
    """
    
    def setupCtrlPlane(self):
        # Table acl
        match_spec = basic_switching_acl_match_spec_t(
            ethernet_dstAddr = b'\x52\x48\xae\x9d\x69\xa0',
            ethernet_dstAddr_mask = b'\xff\xff\xff\xff\xff\xff',
            ethernet_srcAddr = b'\x97\x36\x94\xfe\x20\x8f',
            ethernet_srcAddr_mask = b'\xff\xff\xff\xff\xff\xff',)
        self.match_entries['acl'].append(
            self.client.acl_table_add_with_nop(
                self.sess_hdl, self.dev_tgt, match_spec, 0))
        # Table forward
        match_spec = basic_switching_forward_match_spec_t(
            ethernet_dstAddr = b'\x52\x48\xae\x9d\x69\xa0',)
        self.match_entries['forward'].append(
            self.client.forward_table_add_with_set_egr(
                self.sess_hdl, self.dev_tgt, match_spec,
                basic_switching_set_egr_action_spec_t(
                    action_egress_spec = hex_to_i16(0x0040),)))
    
    def sendPacket(self):
        ig_port = 3
        pkt = b'\x52\x48\xae\x9d\x69\xa0\x97\x36\x94\xfe\x20\x8f\x28\xc6\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00'
        send_packet(self, ig_port, pkt)
    
    def verifyPackets(self):
        eg_port = 64
        exp_pkt = b'\x52\x48\xae\x9d\x69\xa0\x97\x36\x94\xfe\x20\x8f\x28\xc6\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00'
        verify_packet(self, exp_pkt, eg_port)
    
    def runTest(self):
        self.runTestImpl()

class Test4(AbstractTest):
    """
    Ingress packet on port 15:
        ethernet =
            dstAddr = 0xb2c8301cf6ae
            srcAddr = 0x08f1e5f92d22
            etherType = 0xc14f
    
    Trace:
        [ Parser ] start
        [ Parser ] _parse_ethernet
        [ Action ] forward <hit> (set_egr)
        [ Action ] acl <miss>
    
    Egress packet on port 7:
        ethernet =
            dstAddr = 0xb2c8301cf6ae
            srcAddr = 0x08f1e5f92d22
            etherType = 0xc14f
    """
    
    def setupCtrlPlane(self):
        # Table forward
        match_spec = basic_switching_forward_match_spec_t(
            ethernet_dstAddr = b'\xb2\xc8\x30\x1c\xf6\xae',)
        self.match_entries['forward'].append(
            self.client.forward_table_add_with_set_egr(
                self.sess_hdl, self.dev_tgt, match_spec,
                basic_switching_set_egr_action_spec_t(
                    action_egress_spec = hex_to_i16(0x0007),)))
    
    def sendPacket(self):
        ig_port = 15
        pkt = b'\xb2\xc8\x30\x1c\xf6\xae\x08\xf1\xe5\xf9\x2d\x22\xc1\x4f\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00'
        send_packet(self, ig_port, pkt)
    
    def verifyPackets(self):
        eg_port = 7
        exp_pkt = b'\xb2\xc8\x30\x1c\xf6\xae\x08\xf1\xe5\xf9\x2d\x22\xc1\x4f\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00'
        verify_packet(self, exp_pkt, eg_port)
    
    def runTest(self):
        self.runTestImpl()

class Test5(AbstractTest):
    """
    Ingress packet on port 12:
        ethernet =
            dstAddr = 0xfee6a03b8fc8
            srcAddr = 0x81ae92ac867d
            etherType = 0x65f6
    
    Trace:
        [ Parser ] start
        [ Parser ] _parse_ethernet
        [ Action ] forward <hit> (nop)
    No egress: packet dropped.
    """
    
    def setupCtrlPlane(self):
        # Table forward
        match_spec = basic_switching_forward_match_spec_t(
            ethernet_dstAddr = b'\xfe\xe6\xa0\x3b\x8f\xc8',)
        self.match_entries['forward'].append(
            self.client.forward_table_add_with_nop(
                self.sess_hdl, self.dev_tgt, match_spec))
    
    def sendPacket(self):
        ig_port = 12
        pkt = b'\xfe\xe6\xa0\x3b\x8f\xc8\x81\xae\x92\xac\x86\x7d\x65\xf6\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00'
        send_packet(self, ig_port, pkt)
    
    
    def runTest(self):
        self.runTestImpl()

class Test6(AbstractTest):
    """
    Ingress packet on port 6:
        ethernet =
            dstAddr = 0x7da6448fa105
            srcAddr = 0x53b701212efb
            etherType = 0xae2c
    
    Trace:
        [ Parser ] start
        [ Parser ] _parse_ethernet
        [ Action ] forward <miss>
    No egress: packet dropped.
    """
    
    def setupCtrlPlane(self):
        pass
    
    def sendPacket(self):
        ig_port = 6
        pkt = b'\x7d\xa6\x44\x8f\xa1\x05\x53\xb7\x01\x21\x2e\xfb\xae\x2c\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00'
        send_packet(self, ig_port, pkt)
    
    
    def runTest(self):
        self.runTestImpl()

class Test7(AbstractTest):
    """
    Ingress packet on port 8:
        ethernet =
            dstAddr = 0xa8cbafd581e0
            srcAddr = 0xce3108665a3e
            etherType = 0x8100
        vlan =
            pcp = 0b100
            cfi = 0b0
            vid = 0x6e9
            etherType = 0x8657
    
    Trace:
        [ Parser ] start
        [ Parser ] _parse_ethernet
        [ Parser ] _parse_vlan
        [ Action ] forward <hit> (set_egr)
    No egress: packet dropped.
    """
    
    def setupCtrlPlane(self):
        # Table forward
        match_spec = basic_switching_forward_match_spec_t(
            ethernet_dstAddr = b'\xa8\xcb\xaf\xd5\x81\xe0',)
        self.match_entries['forward'].append(
            self.client.forward_table_add_with_set_egr(
                self.sess_hdl, self.dev_tgt, match_spec,
                basic_switching_set_egr_action_spec_t(
                    action_egress_spec = hex_to_i16(0x01ff),)))
    
    def sendPacket(self):
        ig_port = 8
        pkt = b'\xa8\xcb\xaf\xd5\x81\xe0\xce\x31\x08\x66\x5a\x3e\x81\x00\x86\xe9\x86\x57\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00'
        send_packet(self, ig_port, pkt)
    
    
    def runTest(self):
        self.runTestImpl()

class Test8(AbstractTest):
    """
    Ingress packet on port 8:
        ethernet =
            dstAddr = 0xc1850eb495b8
            srcAddr = 0x07de0920873b
            etherType = 0x8100
        vlan =
            pcp = 0b000
            cfi = 0b0
            vid = 0x4ac
            etherType = 0x078b
    
    Trace:
        [ Parser ] start
        [ Parser ] _parse_ethernet
        [ Parser ] _parse_vlan
        [ Action ] forward <hit> (set_egr)
        [ Action ] acl <hit> (nop)
    
    Egress packet on port 14:
        ethernet =
            dstAddr = 0xc1850eb495b8
            srcAddr = 0x07de0920873b
            etherType = 0x8100
        vlan =
            pcp = 0b000
            cfi = 0b0
            vid = 0x4ac
            etherType = 0x078b
    """
    
    def setupCtrlPlane(self):
        # Table acl
        match_spec = basic_switching_acl_match_spec_t(
            ethernet_dstAddr = b'\xc1\x85\x0e\xb4\x95\xb8',
            ethernet_dstAddr_mask = b'\xff\xff\xff\xff\xff\xff',
            ethernet_srcAddr = b'\x07\xde\x09\x20\x87\x3b',
            ethernet_srcAddr_mask = b'\xff\xff\xff\xff\xff\xff',)
        self.match_entries['acl'].append(
            self.client.acl_table_add_with_nop(
                self.sess_hdl, self.dev_tgt, match_spec, 0))
        # Table forward
        match_spec = basic_switching_forward_match_spec_t(
            ethernet_dstAddr = b'\xc1\x85\x0e\xb4\x95\xb8',)
        self.match_entries['forward'].append(
            self.client.forward_table_add_with_set_egr(
                self.sess_hdl, self.dev_tgt, match_spec,
                basic_switching_set_egr_action_spec_t(
                    action_egress_spec = hex_to_i16(0x000e),)))
    
    def sendPacket(self):
        ig_port = 8
        pkt = b'\xc1\x85\x0e\xb4\x95\xb8\x07\xde\x09\x20\x87\x3b\x81\x00\x04\xac\x07\x8b\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00'
        send_packet(self, ig_port, pkt)
    
    def verifyPackets(self):
        eg_port = 14
        exp_pkt = b'\xc1\x85\x0e\xb4\x95\xb8\x07\xde\x09\x20\x87\x3b\x81\x00\x04\xac\x07\x8b\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00'
        verify_packet(self, exp_pkt, eg_port)
    
    def runTest(self):
        self.runTestImpl()

class Test9(AbstractTest):
    """
    Ingress packet on port 1:
        ethernet =
            dstAddr = 0x3c66c9105238
            srcAddr = 0x23f1ee484f55
            etherType = 0x8100
        vlan =
            pcp = 0b001
            cfi = 0b0
            vid = 0x4e1
            etherType = 0x59f1
    
    Trace:
        [ Parser ] start
        [ Parser ] _parse_ethernet
        [ Parser ] _parse_vlan
        [ Action ] forward <hit> (set_egr)
        [ Action ] acl <hit> (_drop)
    No egress: packet dropped.
    """
    
    def setupCtrlPlane(self):
        # Table acl
        match_spec = basic_switching_acl_match_spec_t(
            ethernet_dstAddr = b'\x3c\x66\xc9\x10\x52\x38',
            ethernet_dstAddr_mask = b'\xff\xff\xff\xff\xff\xff',
            ethernet_srcAddr = b'\x23\xf1\xee\x48\x4f\x55',
            ethernet_srcAddr_mask = b'\xff\xff\xff\xff\xff\xff',)
        self.match_entries['acl'].append(
            self.client.acl_table_add_with__drop(
                self.sess_hdl, self.dev_tgt, match_spec, 0))
        # Table forward
        match_spec = basic_switching_forward_match_spec_t(
            ethernet_dstAddr = b'\x3c\x66\xc9\x10\x52\x38',)
        self.match_entries['forward'].append(
            self.client.forward_table_add_with_set_egr(
                self.sess_hdl, self.dev_tgt, match_spec,
                basic_switching_set_egr_action_spec_t(
                    action_egress_spec = hex_to_i16(0x0040),)))
    
    def sendPacket(self):
        ig_port = 1
        pkt = b'\x3c\x66\xc9\x10\x52\x38\x23\xf1\xee\x48\x4f\x55\x81\x00\x24\xe1\x59\xf1\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00'
        send_packet(self, ig_port, pkt)
    
    
    def runTest(self):
        self.runTestImpl()

class Test10(AbstractTest):
    """
    Ingress packet on port 8:
        ethernet =
            dstAddr = 0x866cff699df0
            srcAddr = 0x51b66a392e7e
            etherType = 0x8100
        vlan =
            pcp = 0b111
            cfi = 0b0
            vid = 0x490
            etherType = 0x2388
    
    Trace:
        [ Parser ] start
        [ Parser ] _parse_ethernet
        [ Parser ] _parse_vlan
        [ Action ] forward <hit> (set_egr)
        [ Action ] acl <miss>
    
    Egress packet on port 12:
        ethernet =
            dstAddr = 0x866cff699df0
            srcAddr = 0x51b66a392e7e
            etherType = 0x8100
        vlan =
            pcp = 0b111
            cfi = 0b0
            vid = 0x490
            etherType = 0x2388
    """
    
    def setupCtrlPlane(self):
        # Table forward
        match_spec = basic_switching_forward_match_spec_t(
            ethernet_dstAddr = b'\x86\x6c\xff\x69\x9d\xf0',)
        self.match_entries['forward'].append(
            self.client.forward_table_add_with_set_egr(
                self.sess_hdl, self.dev_tgt, match_spec,
                basic_switching_set_egr_action_spec_t(
                    action_egress_spec = hex_to_i16(0x000c),)))
    
    def sendPacket(self):
        ig_port = 8
        pkt = b'\x86\x6c\xff\x69\x9d\xf0\x51\xb6\x6a\x39\x2e\x7e\x81\x00\xe4\x90\x23\x88\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00'
        send_packet(self, ig_port, pkt)
    
    def verifyPackets(self):
        eg_port = 12
        exp_pkt = b'\x86\x6c\xff\x69\x9d\xf0\x51\xb6\x6a\x39\x2e\x7e\x81\x00\xe4\x90\x23\x88\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00'
        verify_packet(self, exp_pkt, eg_port)
    
    def runTest(self):
        self.runTestImpl()

class Test11(AbstractTest):
    """
    Ingress packet on port 4:
        ethernet =
            dstAddr = 0xb692cfcf70ff
            srcAddr = 0x8f16dc3d4b63
            etherType = 0x8100
        vlan =
            pcp = 0b010
            cfi = 0b0
            vid = 0xb03
            etherType = 0x59ec
    
    Trace:
        [ Parser ] start
        [ Parser ] _parse_ethernet
        [ Parser ] _parse_vlan
        [ Action ] forward <hit> (nop)
    No egress: packet dropped.
    """
    
    def setupCtrlPlane(self):
        # Table forward
        match_spec = basic_switching_forward_match_spec_t(
            ethernet_dstAddr = b'\xb6\x92\xcf\xcf\x70\xff',)
        self.match_entries['forward'].append(
            self.client.forward_table_add_with_nop(
                self.sess_hdl, self.dev_tgt, match_spec))
    
    def sendPacket(self):
        ig_port = 4
        pkt = b'\xb6\x92\xcf\xcf\x70\xff\x8f\x16\xdc\x3d\x4b\x63\x81\x00\x4b\x03\x59\xec\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00'
        send_packet(self, ig_port, pkt)
    
    
    def runTest(self):
        self.runTestImpl()

class Test12(AbstractTest):
    """
    Ingress packet on port 3:
        ethernet =
            dstAddr = 0xd1e17e1a4085
            srcAddr = 0x92b826e3cef1
            etherType = 0x8100
        vlan =
            pcp = 0b111
            cfi = 0b0
            vid = 0x267
            etherType = 0x2f67
    
    Trace:
        [ Parser ] start
        [ Parser ] _parse_ethernet
        [ Parser ] _parse_vlan
        [ Action ] forward <miss>
    No egress: packet dropped.
    """
    
    def setupCtrlPlane(self):
        pass
    
    def sendPacket(self):
        ig_port = 3
        pkt = b'\xd1\xe1\x7e\x1a\x40\x85\x92\xb8\x26\xe3\xce\xf1\x81\x00\xe2\x67\x2f\x67\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00'
        send_packet(self, ig_port, pkt)
    
    
    def runTest(self):
        self.runTestImpl()

# Covered 19 of 20 branches (95.0%).
# Note: not all branches may be feasible.
