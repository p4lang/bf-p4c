# PTF test for P4C_1021_1
# p4testgen seed: 719381966

import pd_base_tests
from ptf.mask import Mask
from ptf.testutils import send_packet
from ptf.testutils import verify_packet
from ptf.testutils import verify_no_other_packets
from ptf.thriftutils import hex_to_byte
from ptf.thriftutils import hex_to_i16
from ptf.thriftutils import hex_to_i32

from res_pd_rpc.ttypes import DevTarget_t

from P4C_1021_1.p4_pd_rpc.ttypes import *

class AbstractTest(pd_base_tests.ThriftInterfaceDataPlane):
    def __init__(self):
        pd_base_tests.ThriftInterfaceDataPlane.__init__(self, ['P4C_1021_1'])
    
    def setUp(self):
        pd_base_tests.ThriftInterfaceDataPlane.setUp(self)
        self.sess_hdl = self.conn_mgr.client_init()
        self.dev_id = 0;
        self.dev_tgt = DevTarget_t(self.dev_id, hex_to_i16(0xffff))
        self.match_entries = { 'euphemism': [], 'nassau': [], }
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
        self.resetTable('euphemism', True)
        self.resetTable('nassau', True)
        
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

class Test2(AbstractTest):
    """
    Ingress packet on port 10:
        bolt =
            desalinized = 0x6b3d
            tammi = 0x4e664d81c697
            expeditiousnesss = 0x75b4
            scopess = 0xc1a0
            claibornes = 0x6f30
            decadencys = 0x17455cd3
        jeannette =
            ornately = 0x4f2b
            windscreen = 0x0b2f1b9be728173f
            cafes = 0x5399fffe
    
    Trace:
        [ Parser ] start
        [ Parser ] parse_bolt
        [ Extract] bolt
        [ Parser ] parse_jeannette
        [ Extract] jeannette
        [ Parser ] p4_pe_checksum
        [ Start  ] ingress
        [ Action ] nassau <default> (buttercups)
        [ Action ] euphemism <hit> (unscathed)
        [ End    ] ingress
        [ Deparse] bolt
        [ Deparse] jeannette
        [ Parser ] start
        [ Parser ] parse_bolt
        [ Extract] bolt
        [ Parser ] parse_jeannette
        [ Extract] jeannette
        [ Start  ] egress
        [ End    ] egress
        [ Deparse] bolt
        [ Deparse] jeannette
    
    Egress packet on port 1:
        bolt =
            desalinized = 0x5718
            tammi = 0x4e664d81c697
            expeditiousnesss = 0x75b4
            scopess = 0xc1a0
            claibornes = 0x428a
            decadencys = 0x6adf5cd1
        jeannette =
            ornately = 0x4f2b
            windscreen = 0x0b2f1b9be728173f
            cafes = 0x5399fffe
    """
    
    def setupCtrlPlane(self):
        # Table euphemism
        match_spec = P4C_1021_1_euphemism_match_spec_t(
            jeannette_valid = 1,
            jeannette_cafes = hex_to_i32(0x5399fffe),)
        self.match_entries['euphemism'].append(
            self.client.euphemism_table_add_with_unscathed(
                self.sess_hdl, self.dev_tgt, match_spec,
                P4C_1021_1_unscathed_action_spec_t(
                    action_concertos = hex_to_byte(0x00),)))
        # Table nassau
        self.client.nassau_set_default_action_buttercups(
            self.sess_hdl, self.dev_tgt)
    
    def sendPacket(self):
        ig_port = 10
        pkt = b'\x6b\x3d\x4e\x66\x4d\x81\xc6\x97\x75\xb4\xc1\xa0\x6f\x30\x17\x45\x5c\xd3\x4f\x2b\x0b\x2f\x1b\x9b\xe7\x28\x17\x3f\x53\x99\xff\xfe\xdf\xe8\xb6\x1c\xb3\xb6\xdf\x6f\x0b\xa0\x27\xb6\x53\x8e\xd4\x8c\x2d\x4c\xd9\x82\x1f\x08\xc6\x55\x54\xa4\xdb\xfa\xa9\x63\x94\xd6'
        send_packet(self, ig_port, pkt)
    
    def verifyPackets(self):
        eg_port = 1
        exp_pkt = b'\x57\x18\x4e\x66\x4d\x81\xc6\x97\x75\xb4\xc1\xa0\x42\x8a\x6a\xdf\x5c\xd1\x4f\x2b\x0b\x2f\x1b\x9b\xe7\x28\x17\x3f\x53\x99\xff\xfe\xdf\xe8\xb6\x1c\xb3\xb6\xdf\x6f\x0b\xa0\x27\xb6\x53\x8e\xd4\x8c\x2d\x4c\xd9\x82\x1f\x08\xc6\x55\x54\xa4\xdb\xfa\xa9\x63\x94\xd6'
        verify_packet(self, exp_pkt, eg_port)
    
    def runTest(self):
        self.runTestImpl()

class Test3(AbstractTest):
    """
    Ingress packet on port 10:
        bolt =
            desalinized = 0x6e8c
            tammi = 0xf3fd95f45e08
            expeditiousnesss = 0x5f2e
            scopess = 0x6657
            claibornes = 0x098a
            decadencys = 0x119faca6
        jeannette =
            ornately = 0x4f82
            windscreen = 0x5052e77b5613d253
            cafes = 0x51017bd8
    
    Trace:
        [ Parser ] start
        [ Parser ] parse_bolt
        [ Extract] bolt
        [ Parser ] parse_jeannette
        [ Extract] jeannette
        [ Parser ] p4_pe_checksum
        [ Start  ] ingress
        [ Action ] nassau <default> (buttercups)
        [ Action ] euphemism <hit> (empowerment)
        [ End    ] ingress
        [ Deparse] bolt
        [ Deparse] jeannette
        [ Parser ] start
        [ Parser ] parse_bolt
        [ Extract] bolt
        [ Parser ] parse_jeannette
        [ Extract] jeannette
        [ Start  ] egress
        [ End    ] egress
        [ Deparse] bolt
        [ Deparse] jeannette
    
    Egress packet on port 1:
        bolt =
            desalinized = 0xb5b3
            tammi = 0xf3fd95f45e08
            expeditiousnesss = 0x5f2e
            scopess = 0x6657
            claibornes = 0x098a
            decadencys = 0x119faca6
        jeannette =
            ornately = 0x4f82
            windscreen = 0x5052e77b5613d253
            cafes = 0x51017bd8
    """
    
    def setupCtrlPlane(self):
        # Table euphemism
        match_spec = P4C_1021_1_euphemism_match_spec_t(
            jeannette_valid = 1,
            jeannette_cafes = hex_to_i32(0x51017bd8),)
        self.match_entries['euphemism'].append(
            self.client.euphemism_table_add_with_empowerment(
                self.sess_hdl, self.dev_tgt, match_spec))
        # Table nassau
        self.client.nassau_set_default_action_buttercups(
            self.sess_hdl, self.dev_tgt)
    
    def sendPacket(self):
        ig_port = 10
        pkt = b'\x6e\x8c\xf3\xfd\x95\xf4\x5e\x08\x5f\x2e\x66\x57\x09\x8a\x11\x9f\xac\xa6\x4f\x82\x50\x52\xe7\x7b\x56\x13\xd2\x53\x51\x01\x7b\xd8\x36\xf4\xcc\xf7\x60\x87\x44\x39\xe8\xe3\x98\x09\xa9\xd7\xcb\xfb\x51\x41\xc0\xbc\x05\x20\xdd\xb1\x10\x2b\x47\x0a\x17\xfd\x4f\x3e'
        send_packet(self, ig_port, pkt)
    
    def verifyPackets(self):
        eg_port = 1
        exp_pkt = b'\xb5\xb3\xf3\xfd\x95\xf4\x5e\x08\x5f\x2e\x66\x57\x09\x8a\x11\x9f\xac\xa6\x4f\x82\x50\x52\xe7\x7b\x56\x13\xd2\x53\x51\x01\x7b\xd8\x36\xf4\xcc\xf7\x60\x87\x44\x39\xe8\xe3\x98\x09\xa9\xd7\xcb\xfb\x51\x41\xc0\xbc\x05\x20\xdd\xb1\x10\x2b\x47\x0a\x17\xfd\x4f\x3e'
        verify_packet(self, exp_pkt, eg_port)
    
    def runTest(self):
        self.runTestImpl()

class Test4(AbstractTest):
    """
    Ingress packet on port 9:
        bolt =
            desalinized = 0x56ab
            tammi = 0x2ae8892cf486
            expeditiousnesss = 0x4d89
            scopess = 0x8164
            claibornes = 0xdf99
            decadencys = 0x2ec67b34
        jeannette =
            ornately = 0x4f9f
            windscreen = 0x43b8864df7783ac1
            cafes = 0xe246bb8b
    
    Trace:
        [ Parser ] start
        [ Parser ] parse_bolt
        [ Extract] bolt
        [ Parser ] parse_jeannette
        [ Extract] jeannette
        [ Parser ] p4_pe_checksum
        [ Start  ] ingress
        [ Action ] nassau <default> (buttercups)
        [ Action ] euphemism <hit> (buttercups)
        [ End    ] ingress
        [ Deparse] bolt
        [ Deparse] jeannette
        [ Parser ] start
        [ Parser ] parse_bolt
        [ Extract] bolt
        [ Parser ] parse_jeannette
        [ Extract] jeannette
        [ Start  ] egress
        [ End    ] egress
        [ Deparse] bolt
        [ Deparse] jeannette
    
    Egress packet on port 1:
        bolt =
            desalinized = 0x7219
            tammi = 0x2ae8892cf486
            expeditiousnesss = 0x4d89
            scopess = 0x8164
            claibornes = 0xdf99
            decadencys = 0x2ec67b34
        jeannette =
            ornately = 0x4f9f
            windscreen = 0x43b8864df7783ac1
            cafes = 0xe246bb8b
    """
    
    def setupCtrlPlane(self):
        # Table euphemism
        match_spec = P4C_1021_1_euphemism_match_spec_t(
            jeannette_valid = 1,
            jeannette_cafes = hex_to_i32(0xe246bb8b),)
        self.match_entries['euphemism'].append(
            self.client.euphemism_table_add_with_buttercups(
                self.sess_hdl, self.dev_tgt, match_spec))
        # Table nassau
        self.client.nassau_set_default_action_buttercups(
            self.sess_hdl, self.dev_tgt)
    
    def sendPacket(self):
        ig_port = 9
        pkt = b'\x56\xab\x2a\xe8\x89\x2c\xf4\x86\x4d\x89\x81\x64\xdf\x99\x2e\xc6\x7b\x34\x4f\x9f\x43\xb8\x86\x4d\xf7\x78\x3a\xc1\xe2\x46\xbb\x8b\xa0\x52\x21\x2c\x2a\xbb\x82\x8d\xf1\x2b\xcd\xe6\x0b\x84\xa4\x68\x07\xaf\x50\xdb\x10\x11\x78\x09\xed\x5b\x17\x47\xbc\xea\x53\xf8'
        send_packet(self, ig_port, pkt)
    
    def verifyPackets(self):
        eg_port = 1
        exp_pkt = b'\x72\x19\x2a\xe8\x89\x2c\xf4\x86\x4d\x89\x81\x64\xdf\x99\x2e\xc6\x7b\x34\x4f\x9f\x43\xb8\x86\x4d\xf7\x78\x3a\xc1\xe2\x46\xbb\x8b\xa0\x52\x21\x2c\x2a\xbb\x82\x8d\xf1\x2b\xcd\xe6\x0b\x84\xa4\x68\x07\xaf\x50\xdb\x10\x11\x78\x09\xed\x5b\x17\x47\xbc\xea\x53\xf8'
        verify_packet(self, exp_pkt, eg_port)
    
    def runTest(self):
        self.runTestImpl()

class Test5(AbstractTest):
    """
    Ingress packet on port 3:
        bolt =
            desalinized = 0x4b4e
            tammi = 0x96f8cd03c9f4
            expeditiousnesss = 0x7e8b
            scopess = 0x7cb0
            claibornes = 0x32d7
            decadencys = 0x2f4e968e
        jeannette =
            ornately = 0x4ff8
            windscreen = 0x169ce34039456f6a
            cafes = 0x9ff2c93a
    
    Trace:
        [ Parser ] start
        [ Parser ] parse_bolt
        [ Extract] bolt
        [ Parser ] parse_jeannette
        [ Extract] jeannette
        [ Parser ] p4_pe_checksum
        [ Start  ] ingress
        [ Action ] nassau <default> (buttercups)
        [ Action ] euphemism <miss>
        [ End    ] ingress
        [ Deparse] bolt
        [ Deparse] jeannette
        [ Parser ] start
        [ Parser ] parse_bolt
        [ Extract] bolt
        [ Parser ] parse_jeannette
        [ Extract] jeannette
        [ Start  ] egress
        [ End    ] egress
        [ Deparse] bolt
        [ Deparse] jeannette
    
    Egress packet on port 1:
        bolt =
            desalinized = 0xda73
            tammi = 0x96f8cd03c9f4
            expeditiousnesss = 0x7e8b
            scopess = 0x7cb0
            claibornes = 0x32d7
            decadencys = 0x2f4e968e
        jeannette =
            ornately = 0x4ff8
            windscreen = 0x169ce34039456f6a
            cafes = 0x9ff2c93a
    """
    
    def setupCtrlPlane(self):
        # Table nassau
        self.client.nassau_set_default_action_buttercups(
            self.sess_hdl, self.dev_tgt)
    
    def sendPacket(self):
        ig_port = 3
        pkt = b'\x4b\x4e\x96\xf8\xcd\x03\xc9\xf4\x7e\x8b\x7c\xb0\x32\xd7\x2f\x4e\x96\x8e\x4f\xf8\x16\x9c\xe3\x40\x39\x45\x6f\x6a\x9f\xf2\xc9\x3a\x1e\x10\x67\x70\x46\x78\xb4\xaa\xc6\x2e\x4d\xa5\x47\xe6\xed\x68\x5e\xf2\x97\xd6\x0f\x17\x02\x87\x65\xf0\x2a\x62\x6c\x8d\x24\xc7'
        send_packet(self, ig_port, pkt)
    
    def verifyPackets(self):
        eg_port = 1
        exp_pkt = b'\xda\x73\x96\xf8\xcd\x03\xc9\xf4\x7e\x8b\x7c\xb0\x32\xd7\x2f\x4e\x96\x8e\x4f\xf8\x16\x9c\xe3\x40\x39\x45\x6f\x6a\x9f\xf2\xc9\x3a\x1e\x10\x67\x70\x46\x78\xb4\xaa\xc6\x2e\x4d\xa5\x47\xe6\xed\x68\x5e\xf2\x97\xd6\x0f\x17\x02\x87\x65\xf0\x2a\x62\x6c\x8d\x24\xc7'
        verify_packet(self, exp_pkt, eg_port)
    
    def runTest(self):
        self.runTestImpl()

# Covered 77 of 144 branches (53.5%).
# Note: not all branches may be feasible.
