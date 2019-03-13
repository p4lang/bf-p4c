# PTF test for centipedes_0
# p4testgen seed: 1001956569

import pd_base_tests
from ptf.mask import Mask
from ptf.testutils import send_packet
from ptf.testutils import verify_packet
from ptf.testutils import verify_no_other_packets
from ptf.thriftutils import hex_to_byte
from ptf.thriftutils import hex_to_i16
from ptf.thriftutils import hex_to_i32

from res_pd_rpc.ttypes import DevTarget_t

from centipedes_0.p4_pd_rpc.ttypes import *

class AbstractTest(pd_base_tests.ThriftInterfaceDataPlane):
    def __init__(self):
        pd_base_tests.ThriftInterfaceDataPlane.__init__(self, ['centipedes_0'])
    
    def setUp(self):
        pd_base_tests.ThriftInterfaceDataPlane.setUp(self)
        self.sess_hdl = self.conn_mgr.client_init()
        self.dev_id = 0;
        self.dev_tgt = DevTarget_t(self.dev_id, hex_to_i16(0xffff))
        self.match_entries = { 'releases': [], 'snifters': [], }
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
        self.resetTable('releases', True)
        self.resetTable('snifters', True)
        
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
    Ingress packet on port 3:
        gingrich =
            catercorner = 0x2c26
            beholder = 0x9f
            dankly = 0xd621e17a
            cupcakes = 0x43521766
            marty = 0x71e743a8
        quakers =
            gewgaws = 0xe1b7
            dinnering = 0xf2011f1e
            slaughterhouses = 0xa4
            chapultepecs = 0xbf13
            inhibits = 0x3cae
            mutinies = 0x03
    
    Trace:
        [ Parser ] start
        [ Parser ] _parse_gingrich
        [ Parser ] _parse_quakers
        [ Parser ] p4_pe_unhandled_select
    No egress: packet dropped.
    """
    
    def setupCtrlPlane(self):
        pass
    
    def sendPacket(self):
        ig_port = 3
        pkt = b'\x2c\x26\x9f\xd6\x21\xe1\x7a\x43\x52\x17\x66\x71\xe7\x43\xa8\xe1\xb7\xf2\x01\x1f\x1e\xa4\xbf\x13\x3c\xae\x03\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00'
        send_packet(self, ig_port, pkt)
    
    
    def runTest(self):
        self.runTestImpl()

class Test2(AbstractTest):
    """
    Ingress packet on port 12:
        gingrich =
            catercorner = 0xaa3e
            beholder = 0x59
            dankly = 0x988c0e2e
            cupcakes = 0xe128669c
            marty = 0x6a01b377
    
    Trace:
        [ Parser ] start
        [ Parser ] _parse_gingrich
        [ Parser ] p4_pe_unhandled_select
    No egress: packet dropped.
    """
    
    def setupCtrlPlane(self):
        pass
    
    def sendPacket(self):
        ig_port = 12
        pkt = b'\xaa\x3e\x59\x98\x8c\x0e\x2e\xe1\x28\x66\x9c\x6a\x01\xb3\x77\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00'
        send_packet(self, ig_port, pkt)
    
    
    def runTest(self):
        self.runTestImpl()

# Covered 6 of 40 branches (15.0%).
# Note: not all branches may be feasible.
