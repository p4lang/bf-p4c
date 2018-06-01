# PTF test for signets_0
# p4testgen seed: 197779323

import pd_base_tests
from ptf.mask import Mask
from ptf.testutils import send_packet
from ptf.testutils import verify_packet
from ptf.testutils import verify_no_other_packets
from ptf.thriftutils import hex_to_byte
from ptf.thriftutils import hex_to_i16
from ptf.thriftutils import hex_to_i32

from res_pd_rpc.ttypes import DevTarget_t

from signets_0.p4_pd_rpc.ttypes import *

class AbstractTest(pd_base_tests.ThriftInterfaceDataPlane):
    def __init__(self):
        pd_base_tests.ThriftInterfaceDataPlane.__init__(self, ['signets_0'])
    
    def setUp(self):
        pd_base_tests.ThriftInterfaceDataPlane.setUp(self)
        self.sess_hdl = self.conn_mgr.client_init()
        self.dev_id = 0;
        self.dev_tgt = DevTarget_t(self.dev_id, hex_to_i16(0xffff))
        self.match_entries = { 'encrusts': [], 'jarful': [], 'stoic': [], }
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
        self.resetTable('encrusts', True)
        self.resetTable('jarful', True)
        self.resetTable('stoic', True)
        
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
    Ingress packet on port 13:
        inversions =
            tomtits = 0xf7058f24
            statutes = 0x23219132
            animosity = 0x999f
            shortenings = 0x61d2
    
    Trace:
        [ Parser ] start
        [ Parser ] _parse_inversions
        [ Parser ] p4_pe_unhandled_select
    No egress: packet dropped.
    """
    
    def setupCtrlPlane(self):
        pass
    
    def sendPacket(self):
        ig_port = 13
        pkt = b'\xf7\x05\x8f\x24\x23\x21\x91\x32\x99\x9f\x61\xd2\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00'
        send_packet(self, ig_port, pkt)
    
    
    def runTest(self):
        self.runTestImpl()

class Test2(AbstractTest):
    """
    Ingress packet on port 4:
        inversions =
            tomtits = 0x0fabd1a3
            statutes = 0xab1186df
            animosity = 0x3301
            shortenings = 0x933b
        candide =
            dropkick = 0x0ae9
            vending = 0x38c8
        vesiculate =
            coughs = 0x069f510f
    
    Trace:
        [ Parser ] start
        [ Parser ] _parse_inversions
        [ Parser ] _parse_candide
        [ Parser ] _parse_vesiculate
        [ Action ] jarful <hit> (lancer)
        [ Action ] stoic <miss>
    
    Egress packet on port 1:
        inversions =
            tomtits = 0x0fabd1a3
            statutes = 0xab1186df
            animosity = 0x3301
            shortenings = 0x933b
        candide =
            dropkick = 0x0ae9
            vending = 0x38c8
        vesiculate =
            coughs = 0x069f510f
    """
    
    def setupCtrlPlane(self):
        # Table jarful
        match_spec = signets_0_jarful_match_spec_t(
            candide_dropkick = hex_to_i16(0x0ae9),
            candide_dropkick_mask = hex_to_i16(0xffff),
            inversions_statutes_start = hex_to_i32(0xab1186df),
            inversions_statutes_end = hex_to_i32(0xab1186df),
            inversions_animosity_start = hex_to_i16(0x3301),
            inversions_animosity_end = hex_to_i16(0x3301),)
        self.match_entries['jarful'].append(
            self.client.jarful_table_add_with_lancer(
                self.sess_hdl, self.dev_tgt, match_spec, 0))
    
    def sendPacket(self):
        ig_port = 4
        pkt = b'\x0f\xab\xd1\xa3\xab\x11\x86\xdf\x33\x01\x93\x3b\x0a\xe9\x38\xc8\x06\x9f\x51\x0f\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00'
        send_packet(self, ig_port, pkt)
    
    def verifyPackets(self):
        eg_port = 1
        exp_pkt = b'\x0f\xab\xd1\xa3\xab\x11\x86\xdf\x33\x01\x93\x3b\x0a\xe9\x38\xc8\x06\x9f\x51\x0f\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00'
        verify_packet(self, exp_pkt, eg_port)
    
    def runTest(self):
        self.runTestImpl()

class Test3(AbstractTest):
    """
    Ingress packet on port 0:
        inversions =
            tomtits = 0xa1ed3f0e
            statutes = 0xd33f7443
            animosity = 0xc4c2
            shortenings = 0x933b
        candide =
            dropkick = 0x0ae9
            vending = 0xf26c
        vesiculate =
            coughs = 0x84752fbe
    
    Trace:
        [ Parser ] start
        [ Parser ] _parse_inversions
        [ Parser ] _parse_candide
        [ Parser ] _parse_vesiculate
        [ Action ] jarful <hit> (lancer)
        [ Action ] stoic <hit> (matthias)
    
    Egress packet on port 1:
        inversions =
            tomtits = 0x77edf752
            statutes = 0xd33f7443
            animosity = 0xc4c2
            shortenings = 0x4aab
        candide =
            dropkick = 0xf289
            vending = 0xf26c
        vesiculate =
            coughs = 0x84752fbe
    """
    
    def setupCtrlPlane(self):
        # Table jarful
        match_spec = signets_0_jarful_match_spec_t(
            candide_dropkick = hex_to_i16(0x0ae9),
            candide_dropkick_mask = hex_to_i16(0xffff),
            inversions_statutes_start = hex_to_i32(0xd33f7443),
            inversions_statutes_end = hex_to_i32(0xd33f7443),
            inversions_animosity_start = hex_to_i16(0xc4c2),
            inversions_animosity_end = hex_to_i16(0xc4c2),)
        self.match_entries['jarful'].append(
            self.client.jarful_table_add_with_lancer(
                self.sess_hdl, self.dev_tgt, match_spec, 0))
        # Table stoic
        match_spec = signets_0_stoic_match_spec_t(
            candide_valid = 1,
            vesiculate_valid = 1,
            inversions_statutes = hex_to_i32(0xd33f7443),
            inversions_statutes_mask = hex_to_i32(0xffffffff),)
        self.match_entries['stoic'].append(
            self.client.stoic_table_add_with_matthias(
                self.sess_hdl, self.dev_tgt, match_spec, 0))
    
    def sendPacket(self):
        ig_port = 0
        pkt = b'\xa1\xed\x3f\x0e\xd3\x3f\x74\x43\xc4\xc2\x93\x3b\x0a\xe9\xf2\x6c\x84\x75\x2f\xbe\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00'
        send_packet(self, ig_port, pkt)
    
    def verifyPackets(self):
        eg_port = 1
        exp_pkt = b'\x77\xed\xf7\x52\xd3\x3f\x74\x43\xc4\xc2\x4a\xab\xf2\x89\xf2\x6c\x84\x75\x2f\xbe\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00'
        verify_packet(self, exp_pkt, eg_port)
    
    def runTest(self):
        self.runTestImpl()

class Test4(AbstractTest):
    """
    Ingress packet on port 3:
        inversions =
            tomtits = 0xfa6d0a39
            statutes = 0x848502e5
            animosity = 0x3f6b
            shortenings = 0x933b
        candide =
            dropkick = 0x0ae9
            vending = 0xa862
        vesiculate =
            coughs = 0x3d8f2efe
    
    Trace:
        [ Parser ] start
        [ Parser ] _parse_inversions
        [ Parser ] _parse_candide
        [ Parser ] _parse_vesiculate
        [ Action ] jarful <hit> (lancer)
        [ Action ] stoic <hit> (repletenesss)
    No egress: packet dropped.
    """
    
    def setupCtrlPlane(self):
        # Table jarful
        match_spec = signets_0_jarful_match_spec_t(
            candide_dropkick = hex_to_i16(0x0ae9),
            candide_dropkick_mask = hex_to_i16(0xffff),
            inversions_statutes_start = hex_to_i32(0x848502e5),
            inversions_statutes_end = hex_to_i32(0x848502e5),
            inversions_animosity_start = hex_to_i16(0x3f6b),
            inversions_animosity_end = hex_to_i16(0x3f6b),)
        self.match_entries['jarful'].append(
            self.client.jarful_table_add_with_lancer(
                self.sess_hdl, self.dev_tgt, match_spec, 0))
        # Table stoic
        match_spec = signets_0_stoic_match_spec_t(
            candide_valid = 1,
            vesiculate_valid = 1,
            inversions_statutes = hex_to_i32(0x848502e5),
            inversions_statutes_mask = hex_to_i32(0xffffffff),)
        self.match_entries['stoic'].append(
            self.client.stoic_table_add_with_repletenesss(
                self.sess_hdl, self.dev_tgt, match_spec, 0,
                signets_0_repletenesss_action_spec_t(
                    action_stoups = hex_to_byte(0x00),)))
    
    def sendPacket(self):
        ig_port = 3
        pkt = b'\xfa\x6d\x0a\x39\x84\x85\x02\xe5\x3f\x6b\x93\x3b\x0a\xe9\xa8\x62\x3d\x8f\x2e\xfe\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00'
        send_packet(self, ig_port, pkt)
    
    
    def runTest(self):
        self.runTestImpl()

class Test5(AbstractTest):
    """
    Ingress packet on port 0:
        inversions =
            tomtits = 0xd7e539aa
            statutes = 0xbe11c3b9
            animosity = 0x81b7
            shortenings = 0x933b
        candide =
            dropkick = 0x0ae9
            vending = 0xbece
        vesiculate =
            coughs = 0xb8bb3a31
    
    Trace:
        [ Parser ] start
        [ Parser ] _parse_inversions
        [ Parser ] _parse_candide
        [ Parser ] _parse_vesiculate
        [ Action ] jarful <hit> (lancer)
        [ Action ] stoic <hit> (lancer)
    
    Egress packet on port 1:
        inversions =
            tomtits = 0xd7e539aa
            statutes = 0xbe11c3b9
            animosity = 0x81b7
            shortenings = 0x933b
        candide =
            dropkick = 0x0ae9
            vending = 0xbece
        vesiculate =
            coughs = 0xb8bb3a31
    """
    
    def setupCtrlPlane(self):
        # Table jarful
        match_spec = signets_0_jarful_match_spec_t(
            candide_dropkick = hex_to_i16(0x0ae9),
            candide_dropkick_mask = hex_to_i16(0xffff),
            inversions_statutes_start = hex_to_i32(0xbe11c3b9),
            inversions_statutes_end = hex_to_i32(0xbe11c3b9),
            inversions_animosity_start = hex_to_i16(0x81b7),
            inversions_animosity_end = hex_to_i16(0x81b7),)
        self.match_entries['jarful'].append(
            self.client.jarful_table_add_with_lancer(
                self.sess_hdl, self.dev_tgt, match_spec, 0))
        # Table stoic
        match_spec = signets_0_stoic_match_spec_t(
            candide_valid = 1,
            vesiculate_valid = 1,
            inversions_statutes = hex_to_i32(0xbe11c3b9),
            inversions_statutes_mask = hex_to_i32(0xffffffff),)
        self.match_entries['stoic'].append(
            self.client.stoic_table_add_with_lancer(
                self.sess_hdl, self.dev_tgt, match_spec, 0))
    
    def sendPacket(self):
        ig_port = 0
        pkt = b'\xd7\xe5\x39\xaa\xbe\x11\xc3\xb9\x81\xb7\x93\x3b\x0a\xe9\xbe\xce\xb8\xbb\x3a\x31\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00'
        send_packet(self, ig_port, pkt)
    
    def verifyPackets(self):
        eg_port = 1
        exp_pkt = b'\xd7\xe5\x39\xaa\xbe\x11\xc3\xb9\x81\xb7\x93\x3b\x0a\xe9\xbe\xce\xb8\xbb\x3a\x31\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00'
        verify_packet(self, exp_pkt, eg_port)
    
    def runTest(self):
        self.runTestImpl()

class Test6(AbstractTest):
    """
    Ingress packet on port 7:
        inversions =
            tomtits = 0x45a1e213
            statutes = 0x74b8757a
            animosity = 0x4829
            shortenings = 0x933b
        candide =
            dropkick = 0x0ae9
            vending = 0x4228
        vesiculate =
            coughs = 0xbf757f02
    
    Trace:
        [ Parser ] start
        [ Parser ] _parse_inversions
        [ Parser ] _parse_candide
        [ Parser ] _parse_vesiculate
        [ Action ] jarful <hit> (repletenesss)
        [ Action ] stoic <hit> (repletenesss)
    No egress: packet dropped.
    """
    
    def setupCtrlPlane(self):
        # Table jarful
        match_spec = signets_0_jarful_match_spec_t(
            candide_dropkick = hex_to_i16(0x0ae9),
            candide_dropkick_mask = hex_to_i16(0xffff),
            inversions_statutes_start = hex_to_i32(0x74b8757a),
            inversions_statutes_end = hex_to_i32(0x74b8757a),
            inversions_animosity_start = hex_to_i16(0x4829),
            inversions_animosity_end = hex_to_i16(0x4829),)
        self.match_entries['jarful'].append(
            self.client.jarful_table_add_with_repletenesss(
                self.sess_hdl, self.dev_tgt, match_spec, 0,
                signets_0_repletenesss_action_spec_t(
                    action_stoups = hex_to_byte(0x00),)))
        # Table stoic
        match_spec = signets_0_stoic_match_spec_t(
            candide_valid = 0,
            vesiculate_valid = 1,
            inversions_statutes = hex_to_i32(0x74b8757a),
            inversions_statutes_mask = hex_to_i32(0xffffffff),)
        self.match_entries['stoic'].append(
            self.client.stoic_table_add_with_repletenesss(
                self.sess_hdl, self.dev_tgt, match_spec, 0,
                signets_0_repletenesss_action_spec_t(
                    action_stoups = hex_to_byte(0x01),)))
    
    def sendPacket(self):
        ig_port = 7
        pkt = b'\x45\xa1\xe2\x13\x74\xb8\x75\x7a\x48\x29\x93\x3b\x0a\xe9\x42\x28\xbf\x75\x7f\x02\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00'
        send_packet(self, ig_port, pkt)
    
    
    def runTest(self):
        self.runTestImpl()

class Test7(AbstractTest):
    """
    Ingress packet on port 3:
        inversions =
            tomtits = 0xcc429631
            statutes = 0x0f778d00
            animosity = 0x0373
            shortenings = 0x933b
        candide =
            dropkick = 0x0ae9
            vending = 0x3ff4
        vesiculate =
            coughs = 0x8b87be72
    
    Trace:
        [ Parser ] start
        [ Parser ] _parse_inversions
        [ Parser ] _parse_candide
        [ Parser ] _parse_vesiculate
        [ Action ] jarful <hit> (humannesss)
        [ Action ] stoic <miss>
    No egress: packet dropped.
    """
    
    def setupCtrlPlane(self):
        # Table jarful
        match_spec = signets_0_jarful_match_spec_t(
            candide_dropkick = hex_to_i16(0x0ae9),
            candide_dropkick_mask = hex_to_i16(0xffff),
            inversions_statutes_start = hex_to_i32(0x0f778d00),
            inversions_statutes_end = hex_to_i32(0x0f778d00),
            inversions_animosity_start = hex_to_i16(0x0373),
            inversions_animosity_end = hex_to_i16(0x0373),)
        self.match_entries['jarful'].append(
            self.client.jarful_table_add_with_humannesss(
                self.sess_hdl, self.dev_tgt, match_spec, 0,
                signets_0_humannesss_action_spec_t(
                    action_armourers = hex_to_byte(0x00),
                    action_scrimshaws = hex_to_byte(0x00),)))
    
    def sendPacket(self):
        ig_port = 3
        pkt = b'\xcc\x42\x96\x31\x0f\x77\x8d\x00\x03\x73\x93\x3b\x0a\xe9\x3f\xf4\x8b\x87\xbe\x72\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00'
        send_packet(self, ig_port, pkt)
    
    
    def runTest(self):
        self.runTestImpl()

class Test8(AbstractTest):
    """
    Ingress packet on port 10:
        inversions =
            tomtits = 0xbda8309d
            statutes = 0x98039d8b
            animosity = 0xd9fb
            shortenings = 0x933b
        candide =
            dropkick = 0x0ae9
            vending = 0xe0b6
        vesiculate =
            coughs = 0xc9d014d9
    
    Trace:
        [ Parser ] start
        [ Parser ] _parse_inversions
        [ Parser ] _parse_candide
        [ Parser ] _parse_vesiculate
        [ Action ] jarful <miss>
        [ Action ] stoic <hit> (matthias)
    No egress: packet dropped.
    """
    
    def setupCtrlPlane(self):
        # Table stoic
        match_spec = signets_0_stoic_match_spec_t(
            candide_valid = 1,
            vesiculate_valid = 1,
            inversions_statutes = hex_to_i32(0x98039d8b),
            inversions_statutes_mask = hex_to_i32(0xffffffff),)
        self.match_entries['stoic'].append(
            self.client.stoic_table_add_with_matthias(
                self.sess_hdl, self.dev_tgt, match_spec, 0))
    
    def sendPacket(self):
        ig_port = 10
        pkt = b'\xbd\xa8\x30\x9d\x98\x03\x9d\x8b\xd9\xfb\x93\x3b\x0a\xe9\xe0\xb6\xc9\xd0\x14\xd9\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00'
        send_packet(self, ig_port, pkt)
    
    
    def runTest(self):
        self.runTestImpl()

class Test9(AbstractTest):
    """
    Ingress packet on port 7:
        inversions =
            tomtits = 0x1b0426f8
            statutes = 0x3053916c
            animosity = 0x3da5
            shortenings = 0x933b
        candide =
            dropkick = 0x36e4
            vending = 0x3f7b
    
    Trace:
        [ Parser ] start
        [ Parser ] _parse_inversions
        [ Parser ] _parse_candide
        [ Parser ] p4_pe_unhandled_select
    No egress: packet dropped.
    """
    
    def setupCtrlPlane(self):
        pass
    
    def sendPacket(self):
        ig_port = 7
        pkt = b'\x1b\x04\x26\xf8\x30\x53\x91\x6c\x3d\xa5\x93\x3b\x36\xe4\x3f\x7b\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00'
        send_packet(self, ig_port, pkt)
    
    
    def runTest(self):
        self.runTestImpl()

# Covered 27 of 30 branches (90.0%).
# Note: not all branches may be feasible.
