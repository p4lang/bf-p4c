# PTF test for medal_0
# p4testgen seed: 418797308

import pd_base_tests
from ptf.mask import Mask
from ptf.testutils import send_packet
from ptf.testutils import verify_packet
from ptf.testutils import verify_no_other_packets
from ptf.thriftutils import hex_to_byte
from ptf.thriftutils import hex_to_i16
from ptf.thriftutils import hex_to_i32

from res_pd_rpc.ttypes import DevTarget_t

from medal_0.p4_pd_rpc.ttypes import *

class AbstractTest(pd_base_tests.ThriftInterfaceDataPlane):
    def __init__(self):
        pd_base_tests.ThriftInterfaceDataPlane.__init__(self, ['medal_0'])
    
    def setUp(self):
        pd_base_tests.ThriftInterfaceDataPlane.setUp(self)
        self.sess_hdl = self.conn_mgr.client_init()
        self.dev_id = 0;
        self.dev_tgt = DevTarget_t(self.dev_id, hex_to_i16(0xffff))
        self.match_entries = { 'hairdryers': [], 'polymorphous': [], }
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
        self.resetTable('hairdryers', True)
        self.resetTable('polymorphous', True)
        
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
        cragginess =
            nightstick = 0x1508e233
            dreamer = 0x8a
            nitroglycerines = 0xca3c
    
    Trace:
        [ Parser ] start
        [ Parser ] _parse_cragginess
        [ Parser ] p4_pe_unhandled_select
    No egress: packet dropped.
    """
    
    def setupCtrlPlane(self):
        pass
    
    def sendPacket(self):
        ig_port = 11
        pkt = b'\x15\x08\xe2\x33\x8a\xca\x3c\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00'
        send_packet(self, ig_port, pkt)
    
    
    def runTest(self):
        self.runTestImpl()

class Test2(AbstractTest):
    """
    Ingress packet on port 3:
        cragginess =
            nightstick = 0x313e03dd
            dreamer = 0x2e
            nitroglycerines = 0x8e91
        barometric =
            comatose = 0xb5016d6a
            commits = 0x1685a776
            adders = 0x311b
            pictographs = 0xf85d
            succoured = 0x5666
            placekickers = 0x414f
    
    Trace:
        [ Parser ] start
        [ Parser ] _parse_cragginess
        [ Parser ] _parse_barometric
    No egress: packet dropped.
    """
    
    def setupCtrlPlane(self):
        pass
    
    def sendPacket(self):
        ig_port = 3
        pkt = b'\x31\x3e\x03\xdd\x2e\x8e\x91\xb5\x01\x6d\x6a\x16\x85\xa7\x76\x31\x1b\xf8\x5d\x56\x66\x41\x4f\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00'
        send_packet(self, ig_port, pkt)
    
    
    def runTest(self):
        self.runTestImpl()

# Covered 5 of 6 branches (83.3%).
# Note: not all branches may be feasible.
