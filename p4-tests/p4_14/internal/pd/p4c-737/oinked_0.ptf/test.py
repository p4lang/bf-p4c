# PTF test for oinked_0
# p4testgen seed: 544573259

import pd_base_tests
from ptf.mask import Mask
from ptf.testutils import send_packet
from ptf.testutils import verify_packet
from ptf.testutils import verify_no_other_packets
from ptf.thriftutils import hex_to_byte
from ptf.thriftutils import hex_to_i16
from ptf.thriftutils import hex_to_i32

from res_pd_rpc.ttypes import DevTarget_t

from oinked_0.p4_pd_rpc.ttypes import *

class AbstractTest(pd_base_tests.ThriftInterfaceDataPlane):
    def __init__(self):
        pd_base_tests.ThriftInterfaceDataPlane.__init__(self, ['oinked_0'])
    
    def setUp(self):
        pd_base_tests.ThriftInterfaceDataPlane.setUp(self)
        self.sess_hdl = self.conn_mgr.client_init()
        self.dev_id = 0;
        self.dev_tgt = DevTarget_t(self.dev_id, hex_to_i16(0xffff))
        self.match_entries = { 'perigees': [], 'whooping': [], }
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
        self.resetTable('perigees', True)
        self.resetTable('whooping', True)
        
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
        handiest =
            conjecture = 0xec41141c
            backwoods = 0xf8033b780374
            buddies = 0xb0f0
            gazetteer = 0x135ce6f7e2a363b1
            helmholtzs = 0x9b3f6548a85c
            altimeter = 0xdabf
        refinance =
            garrulous = 0xb4
            pants = 0x49
            manageress = 0x434e
    
    Trace:
        [ Parser ] start
        [ Parser ] parse_handiest
        [ Extract] handiest
        [ Parser ] parse_refinance
        [ Extract] refinance
        [ Parser ] p4_pe_unhandled_select
    No egress: packet dropped.
    """
    
    def setupCtrlPlane(self):
        pass
    
    def sendPacket(self):
        ig_port = 3
        pkt = b'\xec\x41\x14\x1c\xf8\x03\x3b\x78\x03\x74\xb0\xf0\x13\x5c\xe6\xf7\xe2\xa3\x63\xb1\x9b\x3f\x65\x48\xa8\x5c\xda\xbf\xb4\x49\x43\x4e\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00'
        send_packet(self, ig_port, pkt)
    
    
    def runTest(self):
        self.runTestImpl()

class Test2(AbstractTest):
    """
    Ingress packet on port 9:
        handiest =
            conjecture = 0x4f7fd38a
            backwoods = 0x6850ba3e6696
            buddies = 0x8794
            gazetteer = 0x5dd4f25cc8bb51ae
            helmholtzs = 0x4907456fd44a
            altimeter = 0xdabf
        refinance =
            garrulous = 0xc8
            pants = 0x7b
            manageress = 0x1ca1
        carryout =
            ranchings = 0x56f2
            gleefulness = 0x6e955a9d
            grab = 0xef62dcc45f8c
            thrasher = 0x3bbc680e
            furzes = 0x08a0
            atheists = 0x88af06e8a080
    
    Trace:
        [ Parser ] start
        [ Parser ] parse_handiest
        [ Extract] handiest
        [ Parser ] parse_refinance
        [ Extract] refinance
        [ Parser ] parse_carryout
        [ Extract] carryout
        [ Start  ] ingress
        [ Action ] whooping <default> (spillways)
        [ Action ] perigees <default> (spillways)
        [ End    ] ingress
        [ Deparse] handiest
        [ Deparse] refinance
        [ Deparse] carryout
        [ Parser ] start
        [ Parser ] parse_handiest
        [ Extract] handiest
        [ Parser ] parse_refinance
        [ Extract] refinance
        [ Parser ] parse_carryout
        [ Extract] carryout
        [ Start  ] egress
        [ End    ] egress
        [ Deparse] handiest
        [ Deparse] refinance
        [ Deparse] carryout
    
    Egress packet on port 1:
        handiest =
            conjecture = 0x4f7fd38a
            backwoods = 0x6850ba3e6696
            buddies = 0x8794
            gazetteer = 0x5dd4f25cc8bb51ae
            helmholtzs = 0x4907456fd44a
            altimeter = 0xdabf
        refinance =
            garrulous = 0xc8
            pants = 0x7b
            manageress = 0x1ca1
        carryout =
            ranchings = 0x56f2
            gleefulness = 0x6e955a9d
            grab = 0xef62dcc45f8c
            thrasher = 0x3bbc680e
            furzes = 0x08a0
            atheists = 0x88af06e8a080
    """
    
    def setupCtrlPlane(self):
        # Table perigees
        self.client.perigees_set_default_action_spillways(
            self.sess_hdl, self.dev_tgt)
        # Table whooping
        self.client.whooping_set_default_action_spillways(
            self.sess_hdl, self.dev_tgt)
    
    def sendPacket(self):
        ig_port = 9
        pkt = b'\x4f\x7f\xd3\x8a\x68\x50\xba\x3e\x66\x96\x87\x94\x5d\xd4\xf2\x5c\xc8\xbb\x51\xae\x49\x07\x45\x6f\xd4\x4a\xda\xbf\xc8\x7b\x1c\xa1\x56\xf2\x6e\x95\x5a\x9d\xef\x62\xdc\xc4\x5f\x8c\x3b\xbc\x68\x0e\x08\xa0\x88\xaf\x06\xe8\xa0\x80\x00\x00\x00\x00\x00\x00\x00\x00'
        send_packet(self, ig_port, pkt)
    
    def verifyPackets(self):
        eg_port = 1
        exp_pkt = b'\x4f\x7f\xd3\x8a\x68\x50\xba\x3e\x66\x96\x87\x94\x5d\xd4\xf2\x5c\xc8\xbb\x51\xae\x49\x07\x45\x6f\xd4\x4a\xda\xbf\xc8\x7b\x1c\xa1\x56\xf2\x6e\x95\x5a\x9d\xef\x62\xdc\xc4\x5f\x8c\x3b\xbc\x68\x0e\x08\xa0\x88\xaf\x06\xe8\xa0\x80\x00\x00\x00\x00\x00\x00\x00\x00'
        verify_packet(self, exp_pkt, eg_port)
    
    def runTest(self):
        self.runTestImpl()

class Test3(AbstractTest):
    """
    Ingress packet on port 9:
        handiest =
            conjecture = 0x2f4ff45a
            backwoods = 0xee875631e721
            buddies = 0xc74c
            gazetteer = 0x998ae4efebebdc71
            helmholtzs = 0x3de65213d7a6
            altimeter = 0xdabf
        refinance =
            garrulous = 0xdf
            pants = 0x7d
            manageress = 0x1ca1
        carryout =
            ranchings = 0x3ee1
            gleefulness = 0x5c3d2794
            grab = 0x85160c8896f9
            thrasher = 0x91909122
            furzes = 0x8f00
            atheists = 0xe3593603b290
    
    Trace:
        [ Parser ] start
        [ Parser ] parse_handiest
        [ Extract] handiest
        [ Parser ] parse_refinance
        [ Extract] refinance
        [ Parser ] parse_carryout
        [ Extract] carryout
        [ Start  ] ingress
        [ Action ] perigees <default> (expensively)
        [ End    ] ingress
        [ Deparse] handiest
        [ Deparse] refinance
        [ Deparse] carryout
    No egress: packet dropped.
    """
    
    def setupCtrlPlane(self):
        # Table perigees
        self.client.perigees_set_default_action_expensively(
            self.sess_hdl, self.dev_tgt)
    
    def sendPacket(self):
        ig_port = 9
        pkt = b'\x2f\x4f\xf4\x5a\xee\x87\x56\x31\xe7\x21\xc7\x4c\x99\x8a\xe4\xef\xeb\xeb\xdc\x71\x3d\xe6\x52\x13\xd7\xa6\xda\xbf\xdf\x7d\x1c\xa1\x3e\xe1\x5c\x3d\x27\x94\x85\x16\x0c\x88\x96\xf9\x91\x90\x91\x22\x8f\x00\xe3\x59\x36\x03\xb2\x90\x00\x00\x00\x00\x00\x00\x00\x00'
        send_packet(self, ig_port, pkt)
    
    
    def runTest(self):
        self.runTestImpl()

class Test4(AbstractTest):
    """
    Ingress packet on port 6:
        handiest =
            conjecture = 0xd0093321
            backwoods = 0x35871193a586
            buddies = 0x0f45
            gazetteer = 0x074c7df62d7cdf4d
            helmholtzs = 0x717702ddfab5
            altimeter = 0xdfde
        taggers =
            mesons = 0x0ef3
            sinkholes = 0x57f4728143ac
            accommodate = 0xcb6b4969
            hairinesss = 0xd7
            nonsupport = 0xf6108e66
    
    Trace:
        [ Parser ] start
        [ Parser ] parse_handiest
        [ Extract] handiest
        [ Parser ] parse_taggers
        [ Extract] taggers
        [ Parser ] p4_pe_unhandled_select
    No egress: packet dropped.
    """
    
    def setupCtrlPlane(self):
        pass
    
    def sendPacket(self):
        ig_port = 6
        pkt = b'\xd0\x09\x33\x21\x35\x87\x11\x93\xa5\x86\x0f\x45\x07\x4c\x7d\xf6\x2d\x7c\xdf\x4d\x71\x77\x02\xdd\xfa\xb5\xdf\xde\x0e\xf3\x57\xf4\x72\x81\x43\xac\xcb\x6b\x49\x69\xd7\xf6\x10\x8e\x66\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00'
        send_packet(self, ig_port, pkt)
    
    
    def runTest(self):
        self.runTestImpl()

class Test5(AbstractTest):
    """
    Ingress packet on port 10:
        handiest =
            conjecture = 0x6bdbe412
            backwoods = 0x14b8f92a6e42
            buddies = 0x9212
            gazetteer = 0x9bd0e482a908062e
            helmholtzs = 0xbe9cb90cfab9
            altimeter = 0xdfde
        taggers =
            mesons = 0x12b9
            sinkholes = 0xb653833aba02
            accommodate = 0xd6a1f537
            hairinesss = 0x9f
            nonsupport = 0x1853a60b
        noels =
            unaccountably = 0x76f1b5ae
            schedules = 0x7111
            endeavouring = 0x1047
            incorrect = 0x29bd21461483
            sysadmin = 0xf0f887c0
            crosspatch = 0x1fe6
    
    Trace:
        [ Parser ] start
        [ Parser ] parse_handiest
        [ Extract] handiest
        [ Parser ] parse_taggers
        [ Extract] taggers
        [ Parser ] parse_noels
        [ Extract] noels
        [ Parser ] p4_pe_unhandled_select
    No egress: packet dropped.
    """
    
    def setupCtrlPlane(self):
        pass
    
    def sendPacket(self):
        ig_port = 10
        pkt = b'\x6b\xdb\xe4\x12\x14\xb8\xf9\x2a\x6e\x42\x92\x12\x9b\xd0\xe4\x82\xa9\x08\x06\x2e\xbe\x9c\xb9\x0c\xfa\xb9\xdf\xde\x12\xb9\xb6\x53\x83\x3a\xba\x02\xd6\xa1\xf5\x37\x9f\x18\x53\xa6\x0b\x76\xf1\xb5\xae\x71\x11\x10\x47\x29\xbd\x21\x46\x14\x83\xf0\xf8\x87\xc0\x1f\xe6'
        send_packet(self, ig_port, pkt)
    
    
    def runTest(self):
        self.runTestImpl()

class Test6(AbstractTest):
    """
    Ingress packet on port 3:
        handiest =
            conjecture = 0x876fc54b
            backwoods = 0x8416a7da647b
            buddies = 0xc923
            gazetteer = 0x0f8a1740d8fdbcfe
            helmholtzs = 0x72804ca21e17
            altimeter = 0xdfde
        taggers =
            mesons = 0x12b9
            sinkholes = 0x805bbc57d1cf
            accommodate = 0x934e20f7
            hairinesss = 0xd3
            nonsupport = 0xc92b8252
        noels =
            unaccountably = 0xea6e303b
            schedules = 0x88fa
            endeavouring = 0x7f80
            incorrect = 0xc9f21b000596
            sysadmin = 0x9c2c2239
            crosspatch = 0xc778
        motors =
            seawater = 0x40a290d9d45c
            crayon = 0xd9b308dadf75
            quay = 0xe3593f1a
    
    Trace:
        [ Parser ] start
        [ Parser ] parse_handiest
        [ Extract] handiest
        [ Parser ] parse_taggers
        [ Extract] taggers
        [ Parser ] parse_noels
        [ Extract] noels
        [ Parser ] parse_motors
        [ Extract] motors
        [ Parser ] p4_pe_unhandled_select
    No egress: packet dropped.
    """
    
    def setupCtrlPlane(self):
        pass
    
    def sendPacket(self):
        ig_port = 3
        pkt = b'\x87\x6f\xc5\x4b\x84\x16\xa7\xda\x64\x7b\xc9\x23\x0f\x8a\x17\x40\xd8\xfd\xbc\xfe\x72\x80\x4c\xa2\x1e\x17\xdf\xde\x12\xb9\x80\x5b\xbc\x57\xd1\xcf\x93\x4e\x20\xf7\xd3\xc9\x2b\x82\x52\xea\x6e\x30\x3b\x88\xfa\x7f\x80\xc9\xf2\x1b\x00\x05\x96\x9c\x2c\x22\x39\xc7\x78\x40\xa2\x90\xd9\xd4\x5c\xd9\xb3\x08\xda\xdf\x75\xe3\x59\x3f\x1a'
        send_packet(self, ig_port, pkt)
    
    
    def runTest(self):
        self.runTestImpl()

class Test7(AbstractTest):
    """
    Ingress packet on port 14:
        handiest =
            conjecture = 0x546ea09d
            backwoods = 0xebbbbdf3bdc7
            buddies = 0xbe9b
            gazetteer = 0x54392fc32b3c7cad
            helmholtzs = 0x6eb32765847b
            altimeter = 0xdfde
        taggers =
            mesons = 0x12b9
            sinkholes = 0x9d1ee9f4dfe7
            accommodate = 0x56807e4b
            hairinesss = 0x83
            nonsupport = 0x416f76ae
        noels =
            unaccountably = 0x1092c838
            schedules = 0x246b
            endeavouring = 0xdbf1
            incorrect = 0x109da5330314
            sysadmin = 0x3882fb57
            crosspatch = 0x6078
        motors =
            seawater = 0x406d676a8c7e
            crayon = 0x0fd61ead4c62
            quay = 0x315b629c
        refinance =
            garrulous = 0x00
            pants = 0x4b
            manageress = 0x1ca1
        carryout =
            ranchings = 0x766e
            gleefulness = 0xed91dc6d
            grab = 0x1ef5264fbf3a
            thrasher = 0x48f6dac9
            furzes = 0xab44
            atheists = 0x15c25de5296f
    
    Trace:
        [ Parser ] start
        [ Parser ] parse_handiest
        [ Extract] handiest
        [ Parser ] parse_taggers
        [ Extract] taggers
        [ Parser ] parse_noels
        [ Extract] noels
        [ Parser ] parse_motors
        [ Extract] motors
        [ Parser ] parse_refinance
        [ Extract] refinance
        [ Parser ] parse_carryout
        [ Extract] carryout
        [ Start  ] ingress
        [ Action ] perigees <default> (downloads)
        [ End    ] ingress
        [ Deparse] handiest
        [ Deparse] taggers
        [ Deparse] noels
        [ Deparse] motors
        [ Deparse] refinance
        [ Deparse] carryout
    No egress: packet dropped.
    """
    
    def setupCtrlPlane(self):
        # Table perigees
        self.client.perigees_set_default_action_downloads(
            self.sess_hdl, self.dev_tgt,
            oinked_0_downloads_action_spec_t(
                action_ministers = hex_to_byte(0x00),
                action_ungraceful = hex_to_byte(0x01),))
    
    def sendPacket(self):
        ig_port = 14
        pkt = b'\x54\x6e\xa0\x9d\xeb\xbb\xbd\xf3\xbd\xc7\xbe\x9b\x54\x39\x2f\xc3\x2b\x3c\x7c\xad\x6e\xb3\x27\x65\x84\x7b\xdf\xde\x12\xb9\x9d\x1e\xe9\xf4\xdf\xe7\x56\x80\x7e\x4b\x83\x41\x6f\x76\xae\x10\x92\xc8\x38\x24\x6b\xdb\xf1\x10\x9d\xa5\x33\x03\x14\x38\x82\xfb\x57\x60\x78\x40\x6d\x67\x6a\x8c\x7e\x0f\xd6\x1e\xad\x4c\x62\x31\x5b\x62\x9c\x00\x4b\x1c\xa1\x76\x6e\xed\x91\xdc\x6d\x1e\xf5\x26\x4f\xbf\x3a\x48\xf6\xda\xc9\xab\x44\x15\xc2\x5d\xe5\x29\x6f'
        send_packet(self, ig_port, pkt)
    
    
    def runTest(self):
        self.runTestImpl()

class Test8(AbstractTest):
    """
    Ingress packet on port 11:
        handiest =
            conjecture = 0x1fff342c
            backwoods = 0x5f365497e8a0
            buddies = 0x8e8d
            gazetteer = 0xfbbe6c8fadfb126e
            helmholtzs = 0xa20aa6cb4032
            altimeter = 0xdfde
        taggers =
            mesons = 0x12b9
            sinkholes = 0xe400da6e233f
            accommodate = 0xf1e3661b
            hairinesss = 0x40
            nonsupport = 0xd7e02886
        noels =
            unaccountably = 0x9c81b7d0
            schedules = 0xe5d9
            endeavouring = 0xb2ea
            incorrect = 0x994aa039d6c9
            sysadmin = 0xccf98a6a
            crosspatch = 0x52e4
        motors =
            seawater = 0x40008af31980
            crayon = 0x1e5caad5d7f0
            quay = 0x9d942581
        refinance =
            garrulous = 0x00
            pants = 0x0a
            manageress = 0xccd4
    
    Trace:
        [ Parser ] start
        [ Parser ] parse_handiest
        [ Extract] handiest
        [ Parser ] parse_taggers
        [ Extract] taggers
        [ Parser ] parse_noels
        [ Extract] noels
        [ Parser ] parse_motors
        [ Extract] motors
        [ Parser ] parse_refinance
        [ Extract] refinance
        [ Parser ] p4_pe_unhandled_select
    No egress: packet dropped.
    """
    
    def setupCtrlPlane(self):
        pass
    
    def sendPacket(self):
        ig_port = 11
        pkt = b'\x1f\xff\x34\x2c\x5f\x36\x54\x97\xe8\xa0\x8e\x8d\xfb\xbe\x6c\x8f\xad\xfb\x12\x6e\xa2\x0a\xa6\xcb\x40\x32\xdf\xde\x12\xb9\xe4\x00\xda\x6e\x23\x3f\xf1\xe3\x66\x1b\x40\xd7\xe0\x28\x86\x9c\x81\xb7\xd0\xe5\xd9\xb2\xea\x99\x4a\xa0\x39\xd6\xc9\xcc\xf9\x8a\x6a\x52\xe4\x40\x00\x8a\xf3\x19\x80\x1e\x5c\xaa\xd5\xd7\xf0\x9d\x94\x25\x81\x00\x0a\xcc\xd4'
        send_packet(self, ig_port, pkt)
    
    
    def runTest(self):
        self.runTestImpl()

class Test9(AbstractTest):
    """
    Ingress packet on port 5:
        handiest =
            conjecture = 0xf0de26a3
            backwoods = 0xdec1d278463d
            buddies = 0x4859
            gazetteer = 0x09b8b0efa22560eb
            helmholtzs = 0xfa54928e8827
            altimeter = 0xdfde
        taggers =
            mesons = 0x1445
            sinkholes = 0x04e5079ce915
            accommodate = 0x1ab3fcec
            hairinesss = 0xeb
            nonsupport = 0xc6590aae
        refinance =
            garrulous = 0x80
            pants = 0x5b
            manageress = 0xb1fa
    
    Trace:
        [ Parser ] start
        [ Parser ] parse_handiest
        [ Extract] handiest
        [ Parser ] parse_taggers
        [ Extract] taggers
        [ Parser ] parse_refinance
        [ Extract] refinance
        [ Parser ] p4_pe_unhandled_select
    No egress: packet dropped.
    """
    
    def setupCtrlPlane(self):
        pass
    
    def sendPacket(self):
        ig_port = 5
        pkt = b'\xf0\xde\x26\xa3\xde\xc1\xd2\x78\x46\x3d\x48\x59\x09\xb8\xb0\xef\xa2\x25\x60\xeb\xfa\x54\x92\x8e\x88\x27\xdf\xde\x14\x45\x04\xe5\x07\x9c\xe9\x15\x1a\xb3\xfc\xec\xeb\xc6\x59\x0a\xae\x80\x5b\xb1\xfa\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00'
        send_packet(self, ig_port, pkt)
    
    
    def runTest(self):
        self.runTestImpl()

class Test10(AbstractTest):
    """
    Ingress packet on port 0:
        handiest =
            conjecture = 0x30b4df4d
            backwoods = 0x20f22859acf0
            buddies = 0x1436
            gazetteer = 0x36880c8f8b251373
            helmholtzs = 0x55c3ce10fa79
            altimeter = 0xdfde
        taggers =
            mesons = 0x1445
            sinkholes = 0xd27ca135b225
            accommodate = 0xb843d8fd
            hairinesss = 0x67
            nonsupport = 0xfcb0a166
        refinance =
            garrulous = 0xc6
            pants = 0xf7
            manageress = 0x1ca1
        carryout =
            ranchings = 0x5ff0
            gleefulness = 0x57f7f54a
            grab = 0xd27b4a35648f
            thrasher = 0x74ffab02
            furzes = 0x4420
            atheists = 0x74c464293a69
    
    Trace:
        [ Parser ] start
        [ Parser ] parse_handiest
        [ Extract] handiest
        [ Parser ] parse_taggers
        [ Extract] taggers
        [ Parser ] parse_refinance
        [ Extract] refinance
        [ Parser ] parse_carryout
        [ Extract] carryout
        [ Start  ] ingress
        [ Action ] perigees <default> (expensively)
        [ End    ] ingress
        [ Deparse] handiest
        [ Deparse] taggers
        [ Deparse] refinance
        [ Deparse] carryout
    No egress: packet dropped.
    """
    
    def setupCtrlPlane(self):
        # Table perigees
        self.client.perigees_set_default_action_expensively(
            self.sess_hdl, self.dev_tgt)
    
    def sendPacket(self):
        ig_port = 0
        pkt = b'\x30\xb4\xdf\x4d\x20\xf2\x28\x59\xac\xf0\x14\x36\x36\x88\x0c\x8f\x8b\x25\x13\x73\x55\xc3\xce\x10\xfa\x79\xdf\xde\x14\x45\xd2\x7c\xa1\x35\xb2\x25\xb8\x43\xd8\xfd\x67\xfc\xb0\xa1\x66\xc6\xf7\x1c\xa1\x5f\xf0\x57\xf7\xf5\x4a\xd2\x7b\x4a\x35\x64\x8f\x74\xff\xab\x02\x44\x20\x74\xc4\x64\x29\x3a\x69'
        send_packet(self, ig_port, pkt)
    
    
    def runTest(self):
        self.runTestImpl()

class Test11(AbstractTest):
    """
    Ingress packet on port 3:
        handiest =
            conjecture = 0x78df2e40
            backwoods = 0xd88848fd3aa5
            buddies = 0xded4
            gazetteer = 0xb443aa6ccd1bfc28
            helmholtzs = 0xdfd0325bda95
            altimeter = 0x4083
        noels =
            unaccountably = 0x6717b02a
            schedules = 0xe47a
            endeavouring = 0xd70c
            incorrect = 0x8fbd1cfda3bc
            sysadmin = 0xc65e621f
            crosspatch = 0xe770
    
    Trace:
        [ Parser ] start
        [ Parser ] parse_handiest
        [ Extract] handiest
        [ Parser ] parse_noels
        [ Extract] noels
        [ Parser ] p4_pe_unhandled_select
    No egress: packet dropped.
    """
    
    def setupCtrlPlane(self):
        pass
    
    def sendPacket(self):
        ig_port = 3
        pkt = b'\x78\xdf\x2e\x40\xd8\x88\x48\xfd\x3a\xa5\xde\xd4\xb4\x43\xaa\x6c\xcd\x1b\xfc\x28\xdf\xd0\x32\x5b\xda\x95\x40\x83\x67\x17\xb0\x2a\xe4\x7a\xd7\x0c\x8f\xbd\x1c\xfd\xa3\xbc\xc6\x5e\x62\x1f\xe7\x70\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00'
        send_packet(self, ig_port, pkt)
    
    
    def runTest(self):
        self.runTestImpl()

class Test12(AbstractTest):
    """
    Ingress packet on port 10:
        handiest =
            conjecture = 0x0d2a116a
            backwoods = 0x7db2b2a7dbae
            buddies = 0x194f
            gazetteer = 0x35dd83ccfa91923c
            helmholtzs = 0x70c72768365a
            altimeter = 0x4083
        noels =
            unaccountably = 0xf8beead7
            schedules = 0x8bd6
            endeavouring = 0x4dd6
            incorrect = 0x25526a0803eb
            sysadmin = 0x7e092a81
            crosspatch = 0x48f7
        motors =
            seawater = 0x405e2f030f40
            crayon = 0xa4593c1712e5
            quay = 0x61f1f48d
    
    Trace:
        [ Parser ] start
        [ Parser ] parse_handiest
        [ Extract] handiest
        [ Parser ] parse_noels
        [ Extract] noels
        [ Parser ] parse_motors
        [ Extract] motors
        [ Parser ] p4_pe_unhandled_select
    No egress: packet dropped.
    """
    
    def setupCtrlPlane(self):
        pass
    
    def sendPacket(self):
        ig_port = 10
        pkt = b'\x0d\x2a\x11\x6a\x7d\xb2\xb2\xa7\xdb\xae\x19\x4f\x35\xdd\x83\xcc\xfa\x91\x92\x3c\x70\xc7\x27\x68\x36\x5a\x40\x83\xf8\xbe\xea\xd7\x8b\xd6\x4d\xd6\x25\x52\x6a\x08\x03\xeb\x7e\x09\x2a\x81\x48\xf7\x40\x5e\x2f\x03\x0f\x40\xa4\x59\x3c\x17\x12\xe5\x61\xf1\xf4\x8d'
        send_packet(self, ig_port, pkt)
    
    
    def runTest(self):
        self.runTestImpl()

class Test13(AbstractTest):
    """
    Ingress packet on port 9:
        handiest =
            conjecture = 0xe46c6255
            backwoods = 0x431c33620f91
            buddies = 0xfa7e
            gazetteer = 0x4b7b6afd8eacd7b4
            helmholtzs = 0x1210c017ca04
            altimeter = 0x4083
        noels =
            unaccountably = 0x7824dee0
            schedules = 0x34cc
            endeavouring = 0x8847
            incorrect = 0x03efc0018fcd
            sysadmin = 0x6aa53420
            crosspatch = 0x3b7c
        motors =
            seawater = 0x408a78d7b125
            crayon = 0xebf6b6e24126
            quay = 0x7fc7a989
        refinance =
            garrulous = 0x00
            pants = 0x24
            manageress = 0x1ca1
        carryout =
            ranchings = 0xb50f
            gleefulness = 0x19c3ab22
            grab = 0x348f45692417
            thrasher = 0x1e11f433
            furzes = 0x7c44
            atheists = 0xe300ad391549
    
    Trace:
        [ Parser ] start
        [ Parser ] parse_handiest
        [ Extract] handiest
        [ Parser ] parse_noels
        [ Extract] noels
        [ Parser ] parse_motors
        [ Extract] motors
        [ Parser ] parse_refinance
        [ Extract] refinance
        [ Parser ] parse_carryout
        [ Extract] carryout
        [ Start  ] ingress
        [ Action ] whooping <default> (spillways)
        [ Action ] perigees <default> (spillways)
        [ End    ] ingress
        [ Deparse] handiest
        [ Deparse] noels
        [ Deparse] motors
        [ Deparse] refinance
        [ Deparse] carryout
        [ Parser ] start
        [ Parser ] parse_handiest
        [ Extract] handiest
        [ Parser ] parse_noels
        [ Extract] noels
        [ Parser ] parse_motors
        [ Extract] motors
        [ Parser ] parse_refinance
        [ Extract] refinance
        [ Parser ] parse_carryout
        [ Extract] carryout
        [ Start  ] egress
        [ End    ] egress
        [ Deparse] handiest
        [ Deparse] noels
        [ Deparse] motors
        [ Deparse] refinance
        [ Deparse] carryout
    
    Egress packet on port 1:
        handiest =
            conjecture = 0xe46c6255
            backwoods = 0x431c33620f91
            buddies = 0xfa7e
            gazetteer = 0x4b7b6afd8eacd7b4
            helmholtzs = 0x1210c017ca04
            altimeter = 0x4083
        noels =
            unaccountably = 0x7824dee0
            schedules = 0x34cc
            endeavouring = 0x8847
            incorrect = 0x03efc0018fcd
            sysadmin = 0x6aa53420
            crosspatch = 0x3b7c
        motors =
            seawater = 0x408a78d7b125
            crayon = 0xebf6b6e24126
            quay = 0x7fc7a989
        refinance =
            garrulous = 0x00
            pants = 0x24
            manageress = 0x1ca1
        carryout =
            ranchings = 0xb50f
            gleefulness = 0x19c3ab22
            grab = 0x348f45692417
            thrasher = 0x1e11f433
            furzes = 0x7c44
            atheists = 0xe300ad391549
    """
    
    def setupCtrlPlane(self):
        # Table perigees
        self.client.perigees_set_default_action_spillways(
            self.sess_hdl, self.dev_tgt)
        # Table whooping
        self.client.whooping_set_default_action_spillways(
            self.sess_hdl, self.dev_tgt)
    
    def sendPacket(self):
        ig_port = 9
        pkt = b'\xe4\x6c\x62\x55\x43\x1c\x33\x62\x0f\x91\xfa\x7e\x4b\x7b\x6a\xfd\x8e\xac\xd7\xb4\x12\x10\xc0\x17\xca\x04\x40\x83\x78\x24\xde\xe0\x34\xcc\x88\x47\x03\xef\xc0\x01\x8f\xcd\x6a\xa5\x34\x20\x3b\x7c\x40\x8a\x78\xd7\xb1\x25\xeb\xf6\xb6\xe2\x41\x26\x7f\xc7\xa9\x89\x00\x24\x1c\xa1\xb5\x0f\x19\xc3\xab\x22\x34\x8f\x45\x69\x24\x17\x1e\x11\xf4\x33\x7c\x44\xe3\x00\xad\x39\x15\x49'
        send_packet(self, ig_port, pkt)
    
    def verifyPackets(self):
        eg_port = 1
        exp_pkt = b'\xe4\x6c\x62\x55\x43\x1c\x33\x62\x0f\x91\xfa\x7e\x4b\x7b\x6a\xfd\x8e\xac\xd7\xb4\x12\x10\xc0\x17\xca\x04\x40\x83\x78\x24\xde\xe0\x34\xcc\x88\x47\x03\xef\xc0\x01\x8f\xcd\x6a\xa5\x34\x20\x3b\x7c\x40\x8a\x78\xd7\xb1\x25\xeb\xf6\xb6\xe2\x41\x26\x7f\xc7\xa9\x89\x00\x24\x1c\xa1\xb5\x0f\x19\xc3\xab\x22\x34\x8f\x45\x69\x24\x17\x1e\x11\xf4\x33\x7c\x44\xe3\x00\xad\x39\x15\x49'
        verify_packet(self, exp_pkt, eg_port)
    
    def runTest(self):
        self.runTestImpl()

class Test14(AbstractTest):
    """
    Ingress packet on port 7:
        handiest =
            conjecture = 0x8eea6eae
            backwoods = 0x6de98d089ef8
            buddies = 0xfeb5
            gazetteer = 0xa6472ec418762797
            helmholtzs = 0xb25a0a2fa3b2
            altimeter = 0x4083
        noels =
            unaccountably = 0xe093760a
            schedules = 0xdb8b
            endeavouring = 0x374d
            incorrect = 0xb143ffd2aed8
            sysadmin = 0xea5018f4
            crosspatch = 0x0df6
        motors =
            seawater = 0x4019c32b2081
            crayon = 0xe8f540120694
            quay = 0xfb31071d
        refinance =
            garrulous = 0x00
            pants = 0xac
            manageress = 0xeb58
    
    Trace:
        [ Parser ] start
        [ Parser ] parse_handiest
        [ Extract] handiest
        [ Parser ] parse_noels
        [ Extract] noels
        [ Parser ] parse_motors
        [ Extract] motors
        [ Parser ] parse_refinance
        [ Extract] refinance
        [ Parser ] p4_pe_unhandled_select
    No egress: packet dropped.
    """
    
    def setupCtrlPlane(self):
        pass
    
    def sendPacket(self):
        ig_port = 7
        pkt = b'\x8e\xea\x6e\xae\x6d\xe9\x8d\x08\x9e\xf8\xfe\xb5\xa6\x47\x2e\xc4\x18\x76\x27\x97\xb2\x5a\x0a\x2f\xa3\xb2\x40\x83\xe0\x93\x76\x0a\xdb\x8b\x37\x4d\xb1\x43\xff\xd2\xae\xd8\xea\x50\x18\xf4\x0d\xf6\x40\x19\xc3\x2b\x20\x81\xe8\xf5\x40\x12\x06\x94\xfb\x31\x07\x1d\x00\xac\xeb\x58'
        send_packet(self, ig_port, pkt)
    
    
    def runTest(self):
        self.runTestImpl()

class Test15(AbstractTest):
    """
    Ingress packet on port 1:
        handiest =
            conjecture = 0x15abad21
            backwoods = 0xb2ee06bcc266
            buddies = 0xc93f
            gazetteer = 0x3840dd99615a1527
            helmholtzs = 0x96f5787f5756
            altimeter = 0x6496
    
    Trace:
        [ Parser ] start
        [ Parser ] parse_handiest
        [ Extract] handiest
        [ Parser ] p4_pe_unhandled_select
    No egress: packet dropped.
    """
    
    def setupCtrlPlane(self):
        pass
    
    def sendPacket(self):
        ig_port = 1
        pkt = b'\x15\xab\xad\x21\xb2\xee\x06\xbc\xc2\x66\xc9\x3f\x38\x40\xdd\x99\x61\x5a\x15\x27\x96\xf5\x78\x7f\x57\x56\x64\x96\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00'
        send_packet(self, ig_port, pkt)
    
    
    def runTest(self):
        self.runTestImpl()

# Covered 123 of 270 branches (45.6%).
# Note: not all branches may be feasible.
