# PTF test for faecess_0
# p4testgen seed: 1007500836

import pd_base_tests
from ptf.mask import Mask
from ptf.testutils import send_packet
from ptf.testutils import verify_packet
from ptf.testutils import verify_no_other_packets
from ptf.thriftutils import hex_to_byte
from ptf.thriftutils import hex_to_i16
from ptf.thriftutils import hex_to_i32

from res_pd_rpc.ttypes import DevTarget_t

from faecess_0.p4_pd_rpc.ttypes import *

class AbstractTest(pd_base_tests.ThriftInterfaceDataPlane):
    def __init__(self):
        pd_base_tests.ThriftInterfaceDataPlane.__init__(self, ['faecess_0'])
    
    def setUp(self):
        pd_base_tests.ThriftInterfaceDataPlane.setUp(self)
        self.sess_hdl = self.conn_mgr.client_init()
        self.dev_id = 0;
        self.dev_tgt = DevTarget_t(self.dev_id, hex_to_i16(0xffff))
        self.match_entries = { 'bernhardt': [], 'kennel': [], 'plats': [], }
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
        self.resetTable('bernhardt', True)
        self.resetTable('kennel', True)
        self.resetTable('plats', True)
        
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
    Ingress packet on port 7:
        syndicalism =
            causeless = 0xe4
            ergs = 0xe2
            andromeda = 0xb15e
            lumberers = 0x47a3e8ed
        cryogenic =
            fraternize = 0xc5533fc2
            obamas = 0x7becfc18
            pillion = 0x8c68
            appalled = 0xfb
            reservoirs = 0x5a442c3a7838
            gabriel = 0x0784d9f1
    
    Trace:
        [ Parser ] start
        [ Parser ] _parse_syndicalism
        [ Parser ] _parse_cryogenic
        [ Action ] kennel <default> (throttling)
        [ Action ] bernhardt <default> (dyslexic)
    
    Egress packet on port 1:
        syndicalism =
            causeless = 0xe4
            ergs = 0x06
            andromeda = 0xb15e
            lumberers = 0x47a3e8ed
        cryogenic =
            fraternize = 0xc5533fc2
            obamas = 0x7becfc18
            pillion = 0x8c68
            appalled = 0x70
            reservoirs = 0x000020800006
            gabriel = 0x0784d9f1
    """
    
    def setupCtrlPlane(self):
        # Table bernhardt
        self.client.bernhardt_set_default_action_dyslexic(
            self.sess_hdl, self.dev_tgt)
        # Table kennel
        self.client.kennel_set_default_action_throttling(
            self.sess_hdl, self.dev_tgt)
    
    def sendPacket(self):
        ig_port = 7
        pkt = b'\xe4\xe2\xb1\x5e\x47\xa3\xe8\xed\xc5\x53\x3f\xc2\x7b\xec\xfc\x18\x8c\x68\xfb\x5a\x44\x2c\x3a\x78\x38\x07\x84\xd9\xf1\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00'
        send_packet(self, ig_port, pkt)
    
    def verifyPackets(self):
        eg_port = 1
        exp_pkt = b'\xe4\x06\xb1\x5e\x47\xa3\xe8\xed\xc5\x53\x3f\xc2\x7b\xec\xfc\x18\x8c\x68\x70\x00\x00\x20\x80\x00\x06\x07\x84\xd9\xf1\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00'
        verify_packet(self, exp_pkt, eg_port)
    
    def runTest(self):
        self.runTestImpl()

class Test2(AbstractTest):
    """
    Ingress packet on port 12:
        syndicalism =
            causeless = 0x77
            ergs = 0x85
            andromeda = 0x8bb9
            lumberers = 0xd5436607
        cryogenic =
            fraternize = 0xc5981342
            obamas = 0x70037461
            pillion = 0x9461
            appalled = 0x79
            reservoirs = 0x20dbc9896a74
            gabriel = 0xee8491b9
    
    Trace:
        [ Parser ] start
        [ Parser ] _parse_syndicalism
        [ Parser ] _parse_cryogenic
        [ Action ] kennel <default> (throttling)
        [ Action ] bernhardt <default> (upchucking)
    
    Egress packet on port 1:
        syndicalism =
            causeless = 0x77
            ergs = 0x85
            andromeda = 0x8bb9
            lumberers = 0xd5436607
        cryogenic =
            fraternize = 0xc5981342
            obamas = 0x70037461
            pillion = 0x9461
            appalled = 0x77
            reservoirs = 0x00003e81ed26
            gabriel = 0xee8491b9
    """
    
    def setupCtrlPlane(self):
        # Table bernhardt
        self.client.bernhardt_set_default_action_upchucking(
            self.sess_hdl, self.dev_tgt,
            faecess_0_upchucking_action_spec_t(
                action_mastiffs = hex_to_byte(0x00),))
        # Table kennel
        self.client.kennel_set_default_action_throttling(
            self.sess_hdl, self.dev_tgt)
    
    def sendPacket(self):
        ig_port = 12
        pkt = b'\x77\x85\x8b\xb9\xd5\x43\x66\x07\xc5\x98\x13\x42\x70\x03\x74\x61\x94\x61\x79\x20\xdb\xc9\x89\x6a\x74\xee\x84\x91\xb9\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00'
        send_packet(self, ig_port, pkt)
    
    def verifyPackets(self):
        eg_port = 1
        exp_pkt = b'\x77\x85\x8b\xb9\xd5\x43\x66\x07\xc5\x98\x13\x42\x70\x03\x74\x61\x94\x61\x77\x00\x00\x3e\x81\xed\x26\xee\x84\x91\xb9\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00'
        verify_packet(self, exp_pkt, eg_port)
    
    def runTest(self):
        self.runTestImpl()

class Test3(AbstractTest):
    """
    Ingress packet on port 1:
        syndicalism =
            causeless = 0xcd
            ergs = 0xd9
            andromeda = 0x2e4b
            lumberers = 0x665a3f59
        cryogenic =
            fraternize = 0xc5f6fb66
            obamas = 0x9293bd3c
            pillion = 0xbb2d
            appalled = 0x30
            reservoirs = 0xedb4f9e9f5cf
            gabriel = 0xc45288ec
    
    Trace:
        [ Parser ] start
        [ Parser ] _parse_syndicalism
        [ Parser ] _parse_cryogenic
        [ Action ] kennel <default> (throttling)
        [ Action ] bernhardt <default> (throttling)
    
    Egress packet on port 1:
        syndicalism =
            causeless = 0xcd
            ergs = 0xd9
            andromeda = 0x2e4b
            lumberers = 0x665a3f59
        cryogenic =
            fraternize = 0xc5f6fb66
            obamas = 0x9293bd3c
            pillion = 0xbb2d
            appalled = 0x30
            reservoirs = 0xedb4f9e9f5cf
            gabriel = 0xc45288ec
    """
    
    def setupCtrlPlane(self):
        # Table bernhardt
        self.client.bernhardt_set_default_action_throttling(
            self.sess_hdl, self.dev_tgt)
        # Table kennel
        self.client.kennel_set_default_action_throttling(
            self.sess_hdl, self.dev_tgt)
    
    def sendPacket(self):
        ig_port = 1
        pkt = b'\xcd\xd9\x2e\x4b\x66\x5a\x3f\x59\xc5\xf6\xfb\x66\x92\x93\xbd\x3c\xbb\x2d\x30\xed\xb4\xf9\xe9\xf5\xcf\xc4\x52\x88\xec\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00'
        send_packet(self, ig_port, pkt)
    
    def verifyPackets(self):
        eg_port = 1
        exp_pkt = b'\xcd\xd9\x2e\x4b\x66\x5a\x3f\x59\xc5\xf6\xfb\x66\x92\x93\xbd\x3c\xbb\x2d\x30\xed\xb4\xf9\xe9\xf5\xcf\xc4\x52\x88\xec\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00'
        verify_packet(self, exp_pkt, eg_port)
    
    def runTest(self):
        self.runTestImpl()

class Test4(AbstractTest):
    """
    Ingress packet on port 8:
        syndicalism =
            causeless = 0xf7
            ergs = 0x95
            andromeda = 0xad3f
            lumberers = 0xdef22050
    
    Trace:
        [ Parser ] start
        [ Parser ] _parse_syndicalism
        [ Parser ] p4_pe_unhandled_select
    No egress: packet dropped.
    """
    
    def setupCtrlPlane(self):
        pass
    
    def sendPacket(self):
        ig_port = 8
        pkt = b'\xf7\x95\xad\x3f\xde\xf2\x20\x50\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00'
        send_packet(self, ig_port, pkt)
    
    
    def runTest(self):
        self.runTestImpl()

# Covered 15 of 28 branches (53.6%).
# Note: not all branches may be feasible.
