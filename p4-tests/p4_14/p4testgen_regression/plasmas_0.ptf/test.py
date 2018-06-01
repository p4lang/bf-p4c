# PTF test for plasmas_0
# p4testgen seed: 985179246

import pd_base_tests
from ptf.mask import Mask
from ptf.testutils import send_packet
from ptf.testutils import verify_packet
from ptf.testutils import verify_no_other_packets
from ptf.thriftutils import hex_to_byte
from ptf.thriftutils import hex_to_i16
from ptf.thriftutils import hex_to_i32

from res_pd_rpc.ttypes import DevTarget_t

from plasmas_0.p4_pd_rpc.ttypes import *

class AbstractTest(pd_base_tests.ThriftInterfaceDataPlane):
    def __init__(self):
        pd_base_tests.ThriftInterfaceDataPlane.__init__(self, ['plasmas_0'])
    
    def setUp(self):
        pd_base_tests.ThriftInterfaceDataPlane.setUp(self)
        self.sess_hdl = self.conn_mgr.client_init()
        self.dev_id = 0;
        self.dev_tgt = DevTarget_t(self.dev_id, hex_to_i16(0xffff))
        self.match_entries = { 'generalized': [], 'sparkler': [],
                               'thunderhead': [], }
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
        self.resetTable('generalized', True)
        self.resetTable('sparkler', True)
        self.resetTable('thunderhead', True)
        
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
    Ingress packet on port 2:
        incinerating =
            filmmakers = 0xaa
    
    Trace:
        [ Parser ] start
        [ Parser ] _parse_incinerating
        [ Parser ] p4_pe_unhandled_select
    No egress: packet dropped.
    """
    
    def setupCtrlPlane(self):
        pass
    
    def sendPacket(self):
        ig_port = 2
        pkt = b'\xaa\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00'
        send_packet(self, ig_port, pkt)
    
    
    def runTest(self):
        self.runTestImpl()

class Test2(AbstractTest):
    """
    Ingress packet on port 13:
        incinerating =
            filmmakers = 0x08
        tapered =
            fencer = 0xa6a853b1
            stan = 0x1bc1
            uni = 0xeeb6
            armada = 0xb12a
            secretariats = 0x7844
            whiteboards = 0x781b25cc
    
    Trace:
        [ Parser ] start
        [ Parser ] _parse_incinerating
        [ Parser ] _parse_tapered
        [ Action ] sparkler <miss>
    No egress: packet dropped.
    """
    
    def setupCtrlPlane(self):
        pass
    
    def sendPacket(self):
        ig_port = 13
        pkt = b'\x08\xa6\xa8\x53\xb1\x1b\xc1\xee\xb6\xb1\x2a\x78\x44\x78\x1b\x25\xcc\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00'
        send_packet(self, ig_port, pkt)
    
    
    def runTest(self):
        self.runTestImpl()

class Test3(AbstractTest):
    """
    Ingress packet on port 13:
        incinerating =
            filmmakers = 0x08
        tapered =
            fencer = 0xa6a853b1
            stan = 0x1bc1
            uni = 0xeeb6
            armada = 0xb12a
            secretariats = 0x7844
            whiteboards = 0x781b25cc
    
    Trace:
        [ Parser ] start
        [ Parser ] _parse_incinerating
        [ Parser ] _parse_tapered
        [ Action ] sparkler <hit> (modernization)
    No egress: packet dropped.
    """
    
    def setupCtrlPlane(self):
        # Table sparkler
        match_spec = plasmas_0_sparkler_match_spec_t(
            incinerating_valid = 1,)
        self.match_entries['sparkler'].append(
            self.client.sparkler_table_add_with_modernization(
                self.sess_hdl, self.dev_tgt, match_spec))
    
    def sendPacket(self):
        ig_port = 13
        pkt = b'\x08\xa6\xa8\x53\xb1\x1b\xc1\xee\xb6\xb1\x2a\x78\x44\x78\x1b\x25\xcc\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00'
        send_packet(self, ig_port, pkt)
    
    
    def runTest(self):
        self.runTestImpl()

class Test4(AbstractTest):
    """
    Ingress packet on port 13:
        incinerating =
            filmmakers = 0x08
        tapered =
            fencer = 0xa6a853b1
            stan = 0x1bc1
            uni = 0xeeb6
            armada = 0xb12a
            secretariats = 0x7844
            whiteboards = 0x781b25cc
    
    Trace:
        [ Parser ] start
        [ Parser ] _parse_incinerating
        [ Parser ] _parse_tapered
        [ Action ] sparkler <hit> (degeneress)
    No egress: packet dropped.
    """
    
    def setupCtrlPlane(self):
        # Table sparkler
        match_spec = plasmas_0_sparkler_match_spec_t(
            incinerating_valid = 1,)
        self.match_entries['sparkler'].append(
            self.client.sparkler_table_add_with_degeneress(
                self.sess_hdl, self.dev_tgt, match_spec,
                plasmas_0_degeneress_action_spec_t(
                    action_domestications = hex_to_byte(0x00),
                    action_lowbrows = hex_to_byte(0x01),)))
    
    def sendPacket(self):
        ig_port = 13
        pkt = b'\x08\xa6\xa8\x53\xb1\x1b\xc1\xee\xb6\xb1\x2a\x78\x44\x78\x1b\x25\xcc\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00'
        send_packet(self, ig_port, pkt)
    
    
    def runTest(self):
        self.runTestImpl()

# Covered 13 of 22 branches (59.1%).
# Note: not all branches may be feasible.
