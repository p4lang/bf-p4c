# PTF test for p4c_1585
# p4testgen seed: 657421720

from bfruntime_base_tests import BfRuntimeTest
from ptf.mask import Mask
from ptf.testutils import send_packet
from ptf.testutils import verify_packet
from ptf.testutils import verify_no_other_packets

class AbstractTest(BfRuntimeTest):
    def setUp(self):
        BfRuntimeTest.setUp(self, 0, 'p4c_1585')
        self.dev_id = 0
        self.table_entries = []
    
    def tearDown(self):
        # Reset tables.
        for elt in reversed(self.table_entries):
            self.delete_table_entry(self.target, elt[0], elt[1])
        self.table_entries = []
        
        # End session.
        BfRuntimeTest.tearDown(self)
    
    def insertTableEntry(self, table_name, key_fields = None,
            action_name = None, data_fields = []):
        self.table_entries.append((table_name, key_fields))
        self.insert_table_entry(self.target, table_name, key_fields,
            action_name, data_fields)
    
    def setupCtrlPlane(self):
        pass
    
    def sendPacket(self):
        pass
    
    def verifyPackets(self):
        pass
    
    def runTestImpl(self):
        # Get bfrt_info and set it as part of the test.
        self.set_bfrt_info(self.parse_bfrt_info(
            self.get_bfrt_info('p4c_1585')))
        
        # Set target to all pipes on device self.dev_id.
        self.target = self.Target(device_id = self.dev_id, pipe_id = 0xffff)
        
        self.setupCtrlPlane()
        self.sendPacket()
        self.verifyPackets()
        verify_no_other_packets(self, self.dev_id, timeout=2)

class Test1(AbstractTest):
    """
    Ingress packet on port 13:
        ig_intr_md.resubmit_flag = 0b0
        ig_intr_md._pad1 = 0b0
        ig_intr_md.packet_version = 0b01
        ig_intr_md._pad2 = 0b000
        ig_intr_md.ingress_port = 0b0_0000_1101
        ig_intr_md.ingress_mac_tstamp = 0x80e8_723a_9db1
        hdr.id1.f1 = 0x2329_069f_d588
        hdr.id1.f2 = 0x3782_8e59_2013
        hdr.id1.f3 = 0x42_4242
        hdr.id2.f1 = 0x3248_a5a7_6776
        hdr.id2.f2 = 0xe992_9694_d4e7
        hdr.id2.f3 = 0x42_4242
        hdr.data.f1 = 0xba
        hdr.data.f2 = 0x0af8_29c2_0031_0ff9_ed73_5668_5022_f5b4_ede7_89aa
    
    Trace:
        [ Start     ] ingress parser
        [ Parser    ] ingress$ingress::$$entry_point
        [ Parser    ] ingress$ingress::start
        [ Extract   ] ig_intr_md.resubmit_flag
        [ Extract   ] ig_intr_md._pad1
        [ Extract   ] ig_intr_md.packet_version
        [ Extract   ] ig_intr_md._pad2
        [ Extract   ] ig_intr_md.ingress_port
        [ Extract   ] ig_intr_md.ingress_mac_tstamp
        [ Extract   ] hdr.id1.f1
        [ Extract   ] hdr.id1.f2
        [ Extract   ] hdr.id1.f3
        [ Parser    ] ingress$ingress::id2
        [ Extract   ] hdr.id2.f1
        [ Extract   ] hdr.id2.f2
        [ Extract   ] hdr.id2.f3
        [ Parser    ] ingress$ingress::sel
        [ Parser    ] ingress$ingress::data
        [ Extract   ] hdr.data.f1
        [ Extract   ] hdr.data.f2
        [ End       ] ingress parser
        [ Start     ] ingress MAU
        [ Action    ] SwitchIngress.t <hit> (SwitchIngress.forward)
        [ End       ] ingress MAU
        [ Start     ] ingress deparser
        [ Deparse   ] hdr.id1.f1
        [ Deparse   ] hdr.id1.f2
        [ Deparse   ] hdr.id1.f3
        [ Deparse   ] hdr.id2.f1
        [ Deparse   ] hdr.id2.f2
        [ Deparse   ] hdr.id2.f3
        [ Deparse   ] hdr.data.f1
        [ Deparse   ] hdr.data.f2
        [ End       ] ingress deparser
        [ Start     ] egress parser
        [ Parser    ] egress$egress::$$entry_point
        [ Parser    ] egress$egress::start
        [ Extract   ] eg_intr_md._pad0
        [ Extract   ] eg_intr_md.egress_port
        [ Extract   ] eg_intr_md._pad1
        [ Extract   ] eg_intr_md.enq_qdepth
        [ Extract   ] eg_intr_md._pad2
        [ Extract   ] eg_intr_md.enq_congest_stat
        [ Extract   ] eg_intr_md._pad3
        [ Extract   ] eg_intr_md.enq_tstamp
        [ Extract   ] eg_intr_md._pad4
        [ Extract   ] eg_intr_md.deq_qdepth
        [ Extract   ] eg_intr_md._pad5
        [ Extract   ] eg_intr_md.deq_congest_stat
        [ Extract   ] eg_intr_md.app_pool_congest_stat
        [ Extract   ] eg_intr_md._pad6
        [ Extract   ] eg_intr_md.deq_timedelta
        [ Extract   ] eg_intr_md.egress_rid
        [ Extract   ] eg_intr_md._pad7
        [ Extract   ] eg_intr_md.egress_rid_first
        [ Extract   ] eg_intr_md._pad8
        [ Extract   ] eg_intr_md.egress_qid
        [ Extract   ] eg_intr_md._pad9
        [ Extract   ] eg_intr_md.egress_cos
        [ Extract   ] eg_intr_md._pad10
        [ Extract   ] eg_intr_md.deflection_flag
        [ Extract   ] eg_intr_md.pkt_length
        [ End       ] egress parser
        [ Start     ] egress MAU
        [ End       ] egress MAU
        [ Start     ] egress deparser
        [ End       ] egress deparser
    
    Egress packet on port 10:
        
    """
    
    def setupCtrlPlane(self):
        # Table SwitchIngress.t
        self.insertTableEntry(
            'SwitchIngress.t',
            [self.KeyField('hdr.data.f1', b'\xba'),],
            'SwitchIngress.forward',
            [])
    
    def sendPacket(self):
        ig_port = 13
        pkt = b'\x23\x29\x06\x9f\xd5\x88\x37\x82\x8e\x59\x20\x13\x42\x42\x42\x32\x48\xa5\xa7\x67\x76\xe9\x92\x96\x94\xd4\xe7\x42\x42\x42\xba\x0a\xf8\x29\xc2\x00\x31\x0f\xf9\xed\x73\x56\x68\x50\x22\xf5\xb4\xed\xe7\x89\xaa\xd8\xe5\x25\x61\x6d\x4b\x3c\x43\xdc\x86\xb2\xf4\xd6\xa5\xd4\xcd\x03\xf8\xb1\x59\xc7\x97\x2b\x6f\x86\x77\x05\xa8\x8b\x35\x1d\xbd\x01\xff\x7c'
        send_packet(self, ig_port, pkt)
    
    def verifyPackets(self):
        eg_port = 10
        exp_pkt = b'\x23\x29\x06\x9f\xd5\x88\x37\x82\x8e\x59\x20\x13\x42\x42\x42\x32\x48\xa5\xa7\x67\x76\xe9\x92\x96\x94\xd4\xe7\x42\x42\x42\xba\x0a\xf8\x29\xc2\x00\x31\x0f\xf9\xed\x73\x56\x68\x50\x22\xf5\xb4\xed\xe7\x89\xaa\xd8\xe5\x25\x61\x6d\x4b\x3c\x43\xdc\x86\xb2\xf4\xd6\xa5\xd4\xcd\x03\xf8\xb1\x59\xc7\x97\x2b\x6f\x86\x77\x05\xa8\x8b\x35\x1d\xbd\x01\xff\x7c'
        verify_packet(self, exp_pkt, eg_port)
    
    def runTest(self):
        self.runTestImpl()

