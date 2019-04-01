# PTF test for P4C_1021_2
# p4testgen seed: 186824056

import pd_base_tests
from ptf.mask import Mask
from ptf.testutils import send_packet
from ptf.testutils import verify_packet
from ptf.testutils import verify_no_other_packets
from ptf.thriftutils import hex_to_byte
from ptf.thriftutils import hex_to_i16
from ptf.thriftutils import hex_to_i32

from res_pd_rpc.ttypes import DevTarget_t

from P4C_1021_2.p4_pd_rpc.ttypes import *

class AbstractTest(pd_base_tests.ThriftInterfaceDataPlane):
    def __init__(self):
        pd_base_tests.ThriftInterfaceDataPlane.__init__(self, ['P4C_1021_2'])
    
    def setUp(self):
        pd_base_tests.ThriftInterfaceDataPlane.setUp(self)
        self.sess_hdl = self.conn_mgr.client_init()
        self.dev_id = 0;
        self.dev_tgt = DevTarget_t(self.dev_id, hex_to_i16(0xffff))
        self.match_entries = { 'motocrosss': [], 'thousandfold': [],
                               'upbringing': [], }
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
        self.resetTable('motocrosss', True)
        self.resetTable('thousandfold', True)
        self.resetTable('upbringing', True)
        
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

class Test3(AbstractTest):
    """
    Ingress packet on port 15:
        infatuations =
            moiety = 0x99b6
            fundamentally = 0x4869
            brays = 0xbe0e862b881f8d3c
            workaholics = 0x440251907df01e52
            bob = 0x2e00107996c792de
            pleasantry = 0x296f
        vexing =
            edams = 0x1e8b9549
        ciders =
            theories = 0x4036674f76a5a3e2
        minnesotan =
            hackishes = 0x59eec4c5213b07dc
            michiganite = 0x21cb812f
            filibusters = 0x4cfa
            lyres = 0x10af833654822cb4
            enviousness = 0x09c6e90d
        physicists =
            unsearchable = 0xb775
    
    Trace:
        [ Parser ] start
        [ Parser ] parse_infatuations
        [ Extract] infatuations
        [ Parser ] parse_vexing
        [ Extract] vexing
        [ Parser ] parse_ciders
        [ Extract] ciders
        [ Parser ] parse_minnesotan
        [ Extract] minnesotan
        [ Parser ] parse_physicists
        [ Extract] physicists
        [ Start  ] ingress
        [ Action ] thousandfold <default> (multimillionaires)
        [ Action ] motocrosss <default> (multimillionaires)
        [ End    ] ingress
        [ Deparse] infatuations
        [ Deparse] vexing
        [ Deparse] ciders
        [ Deparse] minnesotan
        [ Deparse] physicists
        [ Parser ] start
        [ Parser ] parse_infatuations
        [ Extract] infatuations
        [ Parser ] parse_vexing
        [ Extract] vexing
        [ Parser ] parse_ciders
        [ Extract] ciders
        [ Parser ] parse_minnesotan
        [ Extract] minnesotan
        [ Parser ] parse_physicists
        [ Extract] physicists
        [ Start  ] egress
        [ End    ] egress
        [ Deparse] infatuations
        [ Deparse] vexing
        [ Deparse] ciders
        [ Deparse] minnesotan
        [ Deparse] physicists
    
    Egress packet on port 1:
        infatuations =
            moiety = 0x99b6
            fundamentally = 0x8a1d
            brays = 0xbe0e862b881f8d3c
            workaholics = 0x440251907df01e52
            bob = 0x2e00107996c792de
            pleasantry = 0x296f
        vexing =
            edams = 0x1e8b9549
        ciders =
            theories = 0x4036674f76a5a3e2
        minnesotan =
            hackishes = 0x59eec4c5213b07dc
            michiganite = 0x21cb812f
            filibusters = 0x4cfa
            lyres = 0x10af833654822cb4
            enviousness = 0x09c6e90d
        physicists =
            unsearchable = 0xb775
    """
    
    def setupCtrlPlane(self):
        # Table motocrosss
        self.client.motocrosss_set_default_action_multimillionaires(
            self.sess_hdl, self.dev_tgt)
        # Table thousandfold
        self.client.thousandfold_set_default_action_multimillionaires(
            self.sess_hdl, self.dev_tgt)
    
    def sendPacket(self):
        ig_port = 15
        pkt = b'\x99\xb6\x48\x69\xbe\x0e\x86\x2b\x88\x1f\x8d\x3c\x44\x02\x51\x90\x7d\xf0\x1e\x52\x2e\x00\x10\x79\x96\xc7\x92\xde\x29\x6f\x1e\x8b\x95\x49\x40\x36\x67\x4f\x76\xa5\xa3\xe2\x59\xee\xc4\xc5\x21\x3b\x07\xdc\x21\xcb\x81\x2f\x4c\xfa\x10\xaf\x83\x36\x54\x82\x2c\xb4\x09\xc6\xe9\x0d\xb7\x75'
        send_packet(self, ig_port, pkt)
    
    def verifyPackets(self):
        eg_port = 1
        exp_pkt = b'\x99\xb6\x8a\x1d\xbe\x0e\x86\x2b\x88\x1f\x8d\x3c\x44\x02\x51\x90\x7d\xf0\x1e\x52\x2e\x00\x10\x79\x96\xc7\x92\xde\x29\x6f\x1e\x8b\x95\x49\x40\x36\x67\x4f\x76\xa5\xa3\xe2\x59\xee\xc4\xc5\x21\x3b\x07\xdc\x21\xcb\x81\x2f\x4c\xfa\x10\xaf\x83\x36\x54\x82\x2c\xb4\x09\xc6\xe9\x0d\xb7\x75'
        verify_packet(self, exp_pkt, eg_port)
    
    def runTest(self):
        self.runTestImpl()

class Test4(AbstractTest):
    """
    Ingress packet on port 4:
        infatuations =
            moiety = 0xf970
            fundamentally = 0x6c87
            brays = 0x91b5db39dd250c97
            workaholics = 0x9dde6bec1772e28b
            bob = 0x67ab242ab4e3c505
            pleasantry = 0x295b
        vexing =
            edams = 0x1e550703
        ciders =
            theories = 0x40de269c128913db
        minnesotan =
            hackishes = 0x59bf5db12458e3fd
            michiganite = 0x8e9d9fd3
            filibusters = 0x4cfa
            lyres = 0x44984614bb544365
            enviousness = 0x0f11e8fc
        physicists =
            unsearchable = 0x48e3
    
    Trace:
        [ Parser ] start
        [ Parser ] parse_infatuations
        [ Extract] infatuations
        [ Parser ] parse_vexing
        [ Extract] vexing
        [ Parser ] parse_ciders
        [ Extract] ciders
        [ Parser ] parse_minnesotan
        [ Extract] minnesotan
        [ Parser ] parse_physicists
        [ Extract] physicists
        [ Start  ] ingress
        [ Action ] thousandfold <default> (multimillionaires)
        [ Action ] motocrosss <default> (multimillionaires)
        [ End    ] ingress
        [ Deparse] infatuations
        [ Deparse] vexing
        [ Deparse] ciders
        [ Deparse] minnesotan
        [ Deparse] physicists
        [ Parser ] start
        [ Parser ] parse_infatuations
        [ Extract] infatuations
        [ Parser ] parse_vexing
        [ Extract] vexing
        [ Parser ] parse_ciders
        [ Extract] ciders
        [ Parser ] parse_minnesotan
        [ Extract] minnesotan
        [ Parser ] parse_physicists
        [ Extract] physicists
        [ Start  ] egress
        [ End    ] egress
        [ Deparse] infatuations
        [ Deparse] vexing
        [ Deparse] ciders
        [ Deparse] minnesotan
        [ Deparse] physicists
    
    Egress packet on port 1:
        infatuations =
            moiety = 0xf970
            fundamentally = 0x4cc9
            brays = 0x91b5db39dd250c97
            workaholics = 0x9dde6bec1772e28b
            bob = 0x67ab242ab4e3c505
            pleasantry = 0x295b
        vexing =
            edams = 0x1e550703
        ciders =
            theories = 0x40de269c128913db
        minnesotan =
            hackishes = 0x59bf5db12458e3fd
            michiganite = 0x8e9d9fd3
            filibusters = 0x4cfa
            lyres = 0x44984614bb544365
            enviousness = 0x0f11e8fc
        physicists =
            unsearchable = 0x48e3
    """
    
    def setupCtrlPlane(self):
        # Table motocrosss
        self.client.motocrosss_set_default_action_multimillionaires(
            self.sess_hdl, self.dev_tgt)
        # Table thousandfold
        self.client.thousandfold_set_default_action_multimillionaires(
            self.sess_hdl, self.dev_tgt)
    
    def sendPacket(self):
        ig_port = 4
        pkt = b'\xf9\x70\x6c\x87\x91\xb5\xdb\x39\xdd\x25\x0c\x97\x9d\xde\x6b\xec\x17\x72\xe2\x8b\x67\xab\x24\x2a\xb4\xe3\xc5\x05\x29\x5b\x1e\x55\x07\x03\x40\xde\x26\x9c\x12\x89\x13\xdb\x59\xbf\x5d\xb1\x24\x58\xe3\xfd\x8e\x9d\x9f\xd3\x4c\xfa\x44\x98\x46\x14\xbb\x54\x43\x65\x0f\x11\xe8\xfc\x48\xe3\x33\xcf\x9e\x48\x64\x46\x2f\x1d\xf8\xda\xd9\x7a\x8d\x02\x4c\xd0\xcc\x66\x23\x71\xb1\x37\x50\x9d\xf8\x64\x89\x19\x48\x89\xa3\x11\xb5\xd3\x25\x86\xb9\x5e\x02\xad\x6d\x90\x0a\xa3\xdf\x95\xda\x28\xb1\x94'
        send_packet(self, ig_port, pkt)
    
    def verifyPackets(self):
        eg_port = 1
        exp_pkt = b'\xf9\x70\x4c\xc9\x91\xb5\xdb\x39\xdd\x25\x0c\x97\x9d\xde\x6b\xec\x17\x72\xe2\x8b\x67\xab\x24\x2a\xb4\xe3\xc5\x05\x29\x5b\x1e\x55\x07\x03\x40\xde\x26\x9c\x12\x89\x13\xdb\x59\xbf\x5d\xb1\x24\x58\xe3\xfd\x8e\x9d\x9f\xd3\x4c\xfa\x44\x98\x46\x14\xbb\x54\x43\x65\x0f\x11\xe8\xfc\x48\xe3\x33\xcf\x9e\x48\x64\x46\x2f\x1d\xf8\xda\xd9\x7a\x8d\x02\x4c\xd0\xcc\x66\x23\x71\xb1\x37\x50\x9d\xf8\x64\x89\x19\x48\x89\xa3\x11\xb5\xd3\x25\x86\xb9\x5e\x02\xad\x6d\x90\x0a\xa3\xdf\x95\xda\x28\xb1\x94'
        verify_packet(self, exp_pkt, eg_port)
    
    def runTest(self):
        self.runTestImpl()

class Test7(AbstractTest):
    """
    Ingress packet on port 9:
        infatuations =
            moiety = 0x2a86
            fundamentally = 0xd4d5
            brays = 0x20356d9d5c2a42f0
            workaholics = 0x6538781c59fc06be
            bob = 0x0071c1d0546864ab
            pleasantry = 0x4099
        vexing =
            edams = 0x1e8ce2c8
        ciders =
            theories = 0x40d4896e17310ca1
        physicists =
            unsearchable = 0x64ef
    
    Trace:
        [ Parser ] start
        [ Parser ] parse_infatuations
        [ Extract] infatuations
        [ Parser ] parse_vexing
        [ Extract] vexing
        [ Parser ] parse_ciders
        [ Extract] ciders
        [ Parser ] parse_physicists
        [ Extract] physicists
        [ Start  ] ingress
        [ Action ] thousandfold <default> (multimillionaires)
        [ Action ] motocrosss <default> (multimillionaires)
        [ End    ] ingress
        [ Deparse] infatuations
        [ Deparse] vexing
        [ Deparse] ciders
        [ Deparse] physicists
        [ Parser ] start
        [ Parser ] parse_infatuations
        [ Extract] infatuations
        [ Parser ] parse_vexing
        [ Extract] vexing
        [ Parser ] parse_ciders
        [ Extract] ciders
        [ Parser ] parse_physicists
        [ Extract] physicists
        [ Start  ] egress
        [ End    ] egress
        [ Deparse] infatuations
        [ Deparse] vexing
        [ Deparse] ciders
        [ Deparse] physicists
    
    Egress packet on port 1:
        infatuations =
            moiety = 0x2a86
            fundamentally = 0x1096
            brays = 0x20356d9d5c2a42f0
            workaholics = 0x6538781c59fc06be
            bob = 0x0071c1d0546864ab
            pleasantry = 0x4099
        vexing =
            edams = 0x1e8ce2c8
        ciders =
            theories = 0x40d4896e17310ca1
        physicists =
            unsearchable = 0x64ef
    """
    
    def setupCtrlPlane(self):
        # Table motocrosss
        self.client.motocrosss_set_default_action_multimillionaires(
            self.sess_hdl, self.dev_tgt)
        # Table thousandfold
        self.client.thousandfold_set_default_action_multimillionaires(
            self.sess_hdl, self.dev_tgt)
    
    def sendPacket(self):
        ig_port = 9
        pkt = b'\x2a\x86\xd4\xd5\x20\x35\x6d\x9d\x5c\x2a\x42\xf0\x65\x38\x78\x1c\x59\xfc\x06\xbe\x00\x71\xc1\xd0\x54\x68\x64\xab\x40\x99\x1e\x8c\xe2\xc8\x40\xd4\x89\x6e\x17\x31\x0c\xa1\x64\xef\xda\x05\x0a\xa4\x65\x2d\xfd\x26\x35\xc9\xfa\x8c\x4a\xd3\xfd\x02\x80\x9e\xcb\xd1\x34\xd1\x3c\x85\xfb\x00\x60\xdf\x19\xd2\xc4\x0d\x62'
        send_packet(self, ig_port, pkt)
    
    def verifyPackets(self):
        eg_port = 1
        exp_pkt = b'\x2a\x86\x10\x96\x20\x35\x6d\x9d\x5c\x2a\x42\xf0\x65\x38\x78\x1c\x59\xfc\x06\xbe\x00\x71\xc1\xd0\x54\x68\x64\xab\x40\x99\x1e\x8c\xe2\xc8\x40\xd4\x89\x6e\x17\x31\x0c\xa1\x64\xef\xda\x05\x0a\xa4\x65\x2d\xfd\x26\x35\xc9\xfa\x8c\x4a\xd3\xfd\x02\x80\x9e\xcb\xd1\x34\xd1\x3c\x85\xfb\x00\x60\xdf\x19\xd2\xc4\x0d\x62'
        verify_packet(self, exp_pkt, eg_port)
    
    def runTest(self):
        self.runTestImpl()

class Test10(AbstractTest):
    """
    Ingress packet on port 4:
        infatuations =
            moiety = 0x9ae9
            fundamentally = 0xddfb
            brays = 0x044a6efe2b24af1b
            workaholics = 0xd07f1679f3c90c83
            bob = 0x5f8dad9b518e3bc3
            pleasantry = 0x57a4
        minnesotan =
            hackishes = 0x74378efb66d9ec92
            michiganite = 0xfd261f8a
            filibusters = 0x4cfa
            lyres = 0x85aa600ecafa5568
            enviousness = 0xc8e18f85
        physicists =
            unsearchable = 0xdf1c
    
    Trace:
        [ Parser ] start
        [ Parser ] parse_infatuations
        [ Extract] infatuations
        [ Parser ] parse_minnesotan
        [ Extract] minnesotan
        [ Parser ] parse_physicists
        [ Extract] physicists
        [ Start  ] ingress
        [ Action ] thousandfold <default> (multimillionaires)
        [ Action ] motocrosss <default> (multimillionaires)
        [ End    ] ingress
        [ Deparse] infatuations
        [ Deparse] minnesotan
        [ Deparse] physicists
        [ Parser ] start
        [ Parser ] parse_infatuations
        [ Extract] infatuations
        [ Parser ] parse_minnesotan
        [ Extract] minnesotan
        [ Parser ] parse_physicists
        [ Extract] physicists
        [ Start  ] egress
        [ End    ] egress
        [ Deparse] infatuations
        [ Deparse] minnesotan
        [ Deparse] physicists
    
    Egress packet on port 1:
        infatuations =
            moiety = 0x9ae9
            fundamentally = 0xffff
            brays = 0x044a6efe2b24af1b
            workaholics = 0xd07f1679f3c90c83
            bob = 0x5f8dad9b518e3bc3
            pleasantry = 0x57a4
        minnesotan =
            hackishes = 0x74378efb66d9ec92
            michiganite = 0xfd261f8a
            filibusters = 0x4cfa
            lyres = 0x85aa600ecafa5568
            enviousness = 0xc8e18f85
        physicists =
            unsearchable = 0xdf1c
    """
    
    def setupCtrlPlane(self):
        # Table motocrosss
        self.client.motocrosss_set_default_action_multimillionaires(
            self.sess_hdl, self.dev_tgt)
        # Table thousandfold
        self.client.thousandfold_set_default_action_multimillionaires(
            self.sess_hdl, self.dev_tgt)
    
    def sendPacket(self):
        ig_port = 4
        pkt = b'\x9a\xe9\xdd\xfb\x04\x4a\x6e\xfe\x2b\x24\xaf\x1b\xd0\x7f\x16\x79\xf3\xc9\x0c\x83\x5f\x8d\xad\x9b\x51\x8e\x3b\xc3\x57\xa4\x74\x37\x8e\xfb\x66\xd9\xec\x92\xfd\x26\x1f\x8a\x4c\xfa\x85\xaa\x60\x0e\xca\xfa\x55\x68\xc8\xe1\x8f\x85\xdf\x1c\x9a\x8a\xe3\x2c\x09\xc8\xbd\xb8\xd0\x7c\x18\xd2\xe7\x1b\xc0\xb9\x22\x35\x17\xda\x7c\xf6\x2c\xb8\x11\xac\x65\xcb\xe8\x7b\x02\xbf\x6b\xa3\xd6\x45\xa9\x7c\xfd\x52\xc8\xf4\xbe\x0f\xbf\x8d\xdb\x49\x63\xd0\x2a\x8a\x6e\xe4\xcf\xfc\xa0\xac'
        send_packet(self, ig_port, pkt)
    
    def verifyPackets(self):
        eg_port = 1
        exp_pkt = b'\x9a\xe9\xff\xff\x04\x4a\x6e\xfe\x2b\x24\xaf\x1b\xd0\x7f\x16\x79\xf3\xc9\x0c\x83\x5f\x8d\xad\x9b\x51\x8e\x3b\xc3\x57\xa4\x74\x37\x8e\xfb\x66\xd9\xec\x92\xfd\x26\x1f\x8a\x4c\xfa\x85\xaa\x60\x0e\xca\xfa\x55\x68\xc8\xe1\x8f\x85\xdf\x1c\x9a\x8a\xe3\x2c\x09\xc8\xbd\xb8\xd0\x7c\x18\xd2\xe7\x1b\xc0\xb9\x22\x35\x17\xda\x7c\xf6\x2c\xb8\x11\xac\x65\xcb\xe8\x7b\x02\xbf\x6b\xa3\xd6\x45\xa9\x7c\xfd\x52\xc8\xf4\xbe\x0f\xbf\x8d\xdb\x49\x63\xd0\x2a\x8a\x6e\xe4\xcf\xfc\xa0\xac'
        verify_packet(self, exp_pkt, eg_port)
    
    def runTest(self):
        self.runTestImpl()

class Test13(AbstractTest):
    """
    Ingress packet on port 8:
        infatuations =
            moiety = 0x14ef
            fundamentally = 0x84ca
            brays = 0xd50fe58e16ef571a
            workaholics = 0x7c2f93d6d45707b7
            bob = 0x304b23ae41641055
            pleasantry = 0x3ef5
        ciders =
            theories = 0xd829afc779a107a9
        minnesotan =
            hackishes = 0x591902fded9b102b
            michiganite = 0x7b91dd99
            filibusters = 0x4cfa
            lyres = 0xca17c1b097fcfe54
            enviousness = 0x5eb40bea
        physicists =
            unsearchable = 0xe9d8
    
    Trace:
        [ Parser ] start
        [ Parser ] parse_infatuations
        [ Extract] infatuations
        [ Parser ] parse_ciders
        [ Extract] ciders
        [ Parser ] parse_minnesotan
        [ Extract] minnesotan
        [ Parser ] parse_physicists
        [ Extract] physicists
        [ Start  ] ingress
        [ Action ] thousandfold <default> (multimillionaires)
        [ Action ] motocrosss <default> (multimillionaires)
        [ End    ] ingress
        [ Deparse] infatuations
        [ Deparse] ciders
        [ Deparse] minnesotan
        [ Deparse] physicists
        [ Parser ] start
        [ Parser ] parse_infatuations
        [ Extract] infatuations
        [ Parser ] parse_ciders
        [ Extract] ciders
        [ Parser ] parse_minnesotan
        [ Extract] minnesotan
        [ Parser ] parse_physicists
        [ Extract] physicists
        [ Start  ] egress
        [ End    ] egress
        [ Deparse] infatuations
        [ Deparse] ciders
        [ Deparse] minnesotan
        [ Deparse] physicists
    
    Egress packet on port 1:
        infatuations =
            moiety = 0x14ef
            fundamentally = 0xf6c3
            brays = 0xd50fe58e16ef571a
            workaholics = 0x7c2f93d6d45707b7
            bob = 0x304b23ae41641055
            pleasantry = 0x3ef5
        ciders =
            theories = 0xd829afc779a107a9
        minnesotan =
            hackishes = 0x591902fded9b102b
            michiganite = 0x7b91dd99
            filibusters = 0x4cfa
            lyres = 0xca17c1b097fcfe54
            enviousness = 0x5eb40bea
        physicists =
            unsearchable = 0xe9d8
    """
    
    def setupCtrlPlane(self):
        # Table motocrosss
        self.client.motocrosss_set_default_action_multimillionaires(
            self.sess_hdl, self.dev_tgt)
        # Table thousandfold
        self.client.thousandfold_set_default_action_multimillionaires(
            self.sess_hdl, self.dev_tgt)
    
    def sendPacket(self):
        ig_port = 8
        pkt = b'\x14\xef\x84\xca\xd5\x0f\xe5\x8e\x16\xef\x57\x1a\x7c\x2f\x93\xd6\xd4\x57\x07\xb7\x30\x4b\x23\xae\x41\x64\x10\x55\x3e\xf5\xd8\x29\xaf\xc7\x79\xa1\x07\xa9\x59\x19\x02\xfd\xed\x9b\x10\x2b\x7b\x91\xdd\x99\x4c\xfa\xca\x17\xc1\xb0\x97\xfc\xfe\x54\x5e\xb4\x0b\xea\xe9\xd8'
        send_packet(self, ig_port, pkt)
    
    def verifyPackets(self):
        eg_port = 1
        exp_pkt = b'\x14\xef\xf6\xc3\xd5\x0f\xe5\x8e\x16\xef\x57\x1a\x7c\x2f\x93\xd6\xd4\x57\x07\xb7\x30\x4b\x23\xae\x41\x64\x10\x55\x3e\xf5\xd8\x29\xaf\xc7\x79\xa1\x07\xa9\x59\x19\x02\xfd\xed\x9b\x10\x2b\x7b\x91\xdd\x99\x4c\xfa\xca\x17\xc1\xb0\x97\xfc\xfe\x54\x5e\xb4\x0b\xea\xe9\xd8'
        verify_packet(self, exp_pkt, eg_port)
    
    def runTest(self):
        self.runTestImpl()

class Test16(AbstractTest):
    """
    Ingress packet on port 4:
        infatuations =
            moiety = 0x452b
            fundamentally = 0xf36e
            brays = 0xdda8c5f36a89255d
            workaholics = 0x356bb8b3c2924adb
            bob = 0x63c4b24512ec66df
            pleasantry = 0x58c8
        ciders =
            theories = 0xd846cabab5dab946
        physicists =
            unsearchable = 0x6400
    
    Trace:
        [ Parser ] start
        [ Parser ] parse_infatuations
        [ Extract] infatuations
        [ Parser ] parse_ciders
        [ Extract] ciders
        [ Parser ] parse_physicists
        [ Extract] physicists
        [ Start  ] ingress
        [ Action ] thousandfold <default> (multimillionaires)
        [ Action ] motocrosss <default> (multimillionaires)
        [ End    ] ingress
        [ Deparse] infatuations
        [ Deparse] ciders
        [ Deparse] physicists
        [ Parser ] start
        [ Parser ] parse_infatuations
        [ Extract] infatuations
        [ Parser ] parse_ciders
        [ Extract] ciders
        [ Parser ] parse_physicists
        [ Extract] physicists
        [ Start  ] egress
        [ End    ] egress
        [ Deparse] infatuations
        [ Deparse] ciders
        [ Deparse] physicists
    
    Egress packet on port 1:
        infatuations =
            moiety = 0x452b
            fundamentally = 0xeddc
            brays = 0xdda8c5f36a89255d
            workaholics = 0x356bb8b3c2924adb
            bob = 0x63c4b24512ec66df
            pleasantry = 0x58c8
        ciders =
            theories = 0xd846cabab5dab946
        physicists =
            unsearchable = 0x6400
    """
    
    def setupCtrlPlane(self):
        # Table motocrosss
        self.client.motocrosss_set_default_action_multimillionaires(
            self.sess_hdl, self.dev_tgt)
        # Table thousandfold
        self.client.thousandfold_set_default_action_multimillionaires(
            self.sess_hdl, self.dev_tgt)
    
    def sendPacket(self):
        ig_port = 4
        pkt = b'\x45\x2b\xf3\x6e\xdd\xa8\xc5\xf3\x6a\x89\x25\x5d\x35\x6b\xb8\xb3\xc2\x92\x4a\xdb\x63\xc4\xb2\x45\x12\xec\x66\xdf\x58\xc8\xd8\x46\xca\xba\xb5\xda\xb9\x46\x64\x00\x3a\x6c\x6a\xd0\x63\xf8\x7b\xf8\x09\x1b\xd4\x8c\x14\x8e\xfa\xe2\xa0\x78\xb8\x3f\x38\xc7\xc8\x7c\x0d\x72\x81\xc8\xd5\x3b\xbb\x90\x5c\xed\xbc\x89\x73\xbe\xdb\x1a\x93\x1e\xfa\x1c\xda\x43\xe8\x0c\x2c\x7f\x01\xe1\x4a\xb5\xf1\xa7'
        send_packet(self, ig_port, pkt)
    
    def verifyPackets(self):
        eg_port = 1
        exp_pkt = b'\x45\x2b\xed\xdc\xdd\xa8\xc5\xf3\x6a\x89\x25\x5d\x35\x6b\xb8\xb3\xc2\x92\x4a\xdb\x63\xc4\xb2\x45\x12\xec\x66\xdf\x58\xc8\xd8\x46\xca\xba\xb5\xda\xb9\x46\x64\x00\x3a\x6c\x6a\xd0\x63\xf8\x7b\xf8\x09\x1b\xd4\x8c\x14\x8e\xfa\xe2\xa0\x78\xb8\x3f\x38\xc7\xc8\x7c\x0d\x72\x81\xc8\xd5\x3b\xbb\x90\x5c\xed\xbc\x89\x73\xbe\xdb\x1a\x93\x1e\xfa\x1c\xda\x43\xe8\x0c\x2c\x7f\x01\xe1\x4a\xb5\xf1\xa7'
        verify_packet(self, exp_pkt, eg_port)
    
    def runTest(self):
        self.runTestImpl()

# Covered 236 of 398 branches (59.3%).
# Note: not all branches may be feasible.
