# PTF test for laymen_0
# p4testgen seed: 964273632

import pd_base_tests
from ptf.mask import Mask
from ptf.testutils import send_packet
from ptf.testutils import verify_packet
from ptf.testutils import verify_no_other_packets
from ptf.thriftutils import hex_to_byte
from ptf.thriftutils import hex_to_i16
from ptf.thriftutils import hex_to_i32

from res_pd_rpc.ttypes import DevTarget_t

from laymen_0.p4_pd_rpc.ttypes import *

class AbstractTest(pd_base_tests.ThriftInterfaceDataPlane):
    def __init__(self):
        pd_base_tests.ThriftInterfaceDataPlane.__init__(self, ['laymen_0'])
    
    def setUp(self):
        pd_base_tests.ThriftInterfaceDataPlane.setUp(self)
        self.sess_hdl = self.conn_mgr.client_init()
        self.dev_id = 0;
        self.dev_tgt = DevTarget_t(self.dev_id, hex_to_i16(0xffff))
        self.match_entries = { 'inconspicuously': [], 'quadrilateral': [], }
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
        self.resetTable('inconspicuously', True)
        self.resetTable('quadrilateral', True)
        
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
    Ingress packet on port 14:
        anchor =
            heiresss = 0xbc93
            bookbindings = 0x4470
            armature = 0x8677
            dishwater = 0xbd7d989f290b
            tagus = 0x1ba8
            studbook = 0x77
    
    Trace:
        [ Parser ] start
        [ Parser ] _parse_anchor
        [ Parser ] p4_pe_unhandled_select
    No egress: packet dropped.
    """
    
    def setupCtrlPlane(self):
        pass
    
    def sendPacket(self):
        ig_port = 14
        pkt = b'\xbc\x93\x44\x70\x86\x77\xbd\x7d\x98\x9f\x29\x0b\x1b\xa8\x77\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00'
        send_packet(self, ig_port, pkt)
    
    
    def runTest(self):
        self.runTestImpl()

class Test2(AbstractTest):
    """
    Ingress packet on port 6:
        anchor =
            heiresss = 0x0ff6
            bookbindings = 0xff06
            armature = 0x6d89
            dishwater = 0x9dc3e7d781f7
            tagus = 0xd99b
            studbook = 0x8f
        connote =
            confucianism = 0xff
            railed = 0x769a5578
            lake = 0x98c5
            startle = 0x1d6c
            deans = 0x406a
            houseboy = 0xcab052ec6a2d
        parasympathetics =
            tappets = 0xa2da
            leonas = 0xc65bb5927d50
    
    Trace:
        [ Parser ] start
        [ Parser ] _parse_anchor
        [ Parser ] _parse_connote
        [ Parser ] _parse_parasympathetics
        [ Action ] quadrilateral <default> (twining)
        [ Action ] inconspicuously <default> (lasses)
    
    Egress packet on port 1:
        anchor =
            heiresss = 0x0ff6
            bookbindings = 0xff06
            armature = 0x6d89
            dishwater = 0x9dc3e7d781f7
            tagus = 0xd99b
            studbook = 0x8f
        connote =
            confucianism = 0xff
            railed = 0x769a5578
            lake = 0xa067
            startle = 0x1d6c
            deans = 0x406a
            houseboy = 0xcab052ec6a2d
        parasympathetics =
            tappets = 0x26ab
            leonas = 0xc65bb5927d50
    """
    
    def setupCtrlPlane(self):
        # Table inconspicuously
        self.client.inconspicuously_set_default_action_lasses(
            self.sess_hdl, self.dev_tgt,
            laymen_0_lasses_action_spec_t(
                action_guess = hex_to_i16(0x83d1),))
        # Table quadrilateral
        self.client.quadrilateral_set_default_action_twining(
            self.sess_hdl, self.dev_tgt)
    
    def sendPacket(self):
        ig_port = 6
        pkt = b'\x0f\xf6\xff\x06\x6d\x89\x9d\xc3\xe7\xd7\x81\xf7\xd9\x9b\x8f\xff\x76\x9a\x55\x78\x98\xc5\x1d\x6c\x40\x6a\xca\xb0\x52\xec\x6a\x2d\xa2\xda\xc6\x5b\xb5\x92\x7d\x50\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00'
        send_packet(self, ig_port, pkt)
    
    def verifyPackets(self):
        eg_port = 1
        exp_pkt = b'\x0f\xf6\xff\x06\x6d\x89\x9d\xc3\xe7\xd7\x81\xf7\xd9\x9b\x8f\xff\x76\x9a\x55\x78\xa0\x67\x1d\x6c\x40\x6a\xca\xb0\x52\xec\x6a\x2d\x26\xab\xc6\x5b\xb5\x92\x7d\x50\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00'
        verify_packet(self, exp_pkt, eg_port)
    
    def runTest(self):
        self.runTestImpl()

class Test3(AbstractTest):
    """
    Ingress packet on port 14:
        anchor =
            heiresss = 0x0ff6
            bookbindings = 0x3750
            armature = 0x00a7
            dishwater = 0x2b5609e47bd7
            tagus = 0x0d5e
            studbook = 0xec
        connote =
            confucianism = 0x8c
            railed = 0x7de62ecd
            lake = 0x1c0d
            startle = 0x6863
            deans = 0x611a
            houseboy = 0x058347582498
        parasympathetics =
            tappets = 0xa2e4
            leonas = 0xaf2c3e716ac1
    
    Trace:
        [ Parser ] start
        [ Parser ] _parse_anchor
        [ Parser ] _parse_connote
        [ Parser ] _parse_parasympathetics
        [ Action ] quadrilateral <default> (twining)
        [ Action ] inconspicuously <default> (twining)
    
    Egress packet on port 1:
        anchor =
            heiresss = 0x0ff6
            bookbindings = 0x3750
            armature = 0x00a7
            dishwater = 0x2b5609e47bd7
            tagus = 0x0d5e
            studbook = 0xec
        connote =
            confucianism = 0x8c
            railed = 0x7de62ecd
            lake = 0x1c0d
            startle = 0x6863
            deans = 0x611a
            houseboy = 0x058347582498
        parasympathetics =
            tappets = 0xa2e4
            leonas = 0xaf2c3e716ac1
    """
    
    def setupCtrlPlane(self):
        # Table inconspicuously
        self.client.inconspicuously_set_default_action_twining(
            self.sess_hdl, self.dev_tgt)
        # Table quadrilateral
        self.client.quadrilateral_set_default_action_twining(
            self.sess_hdl, self.dev_tgt)
    
    def sendPacket(self):
        ig_port = 14
        pkt = b'\x0f\xf6\x37\x50\x00\xa7\x2b\x56\x09\xe4\x7b\xd7\x0d\x5e\xec\x8c\x7d\xe6\x2e\xcd\x1c\x0d\x68\x63\x61\x1a\x05\x83\x47\x58\x24\x98\xa2\xe4\xaf\x2c\x3e\x71\x6a\xc1\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00'
        send_packet(self, ig_port, pkt)
    
    def verifyPackets(self):
        eg_port = 1
        exp_pkt = b'\x0f\xf6\x37\x50\x00\xa7\x2b\x56\x09\xe4\x7b\xd7\x0d\x5e\xec\x8c\x7d\xe6\x2e\xcd\x1c\x0d\x68\x63\x61\x1a\x05\x83\x47\x58\x24\x98\xa2\xe4\xaf\x2c\x3e\x71\x6a\xc1\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00'
        verify_packet(self, exp_pkt, eg_port)
    
    def runTest(self):
        self.runTestImpl()

class Test4(AbstractTest):
    """
    Ingress packet on port 12:
        anchor =
            heiresss = 0x0ff6
            bookbindings = 0xd07e
            armature = 0x5d74
            dishwater = 0x4897278bc432
            tagus = 0x2e38
            studbook = 0x4e
        connote =
            confucianism = 0x5a
            railed = 0x3367581d
            lake = 0xa87e
            startle = 0xcc68
            deans = 0xd8db
            houseboy = 0x5a5dc220d741
    
    Trace:
        [ Parser ] start
        [ Parser ] _parse_anchor
        [ Parser ] _parse_connote
        [ Parser ] p4_pe_unhandled_select
    No egress: packet dropped.
    """
    
    def setupCtrlPlane(self):
        pass
    
    def sendPacket(self):
        ig_port = 12
        pkt = b'\x0f\xf6\xd0\x7e\x5d\x74\x48\x97\x27\x8b\xc4\x32\x2e\x38\x4e\x5a\x33\x67\x58\x1d\xa8\x7e\xcc\x68\xd8\xdb\x5a\x5d\xc2\x20\xd7\x41\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00'
        send_packet(self, ig_port, pkt)
    
    
    def runTest(self):
        self.runTestImpl()

# Covered 15 of 22 branches (68.2%).
# Note: not all branches may be feasible.
