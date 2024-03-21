# PTF test for p4c_873
# p4testgen seed: 897326269

from bfruntime_base_tests import BfRuntimeTest
from ptf.mask import Mask
from ptf.testutils import send_packet
from ptf.testutils import verify_packet
from ptf.testutils import verify_no_other_packets

class AbstractTest(BfRuntimeTest):
    def setUp(self):
        BfRuntimeTest.setUp(self, 0, 'p4c_873')
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
            self.get_bfrt_info('p4c_873')))

        # Set target to all pipes on device self.dev_id.
        self.target = self.Target(device_id = self.dev_id, pipe_id = 0xffff)

        self.setupCtrlPlane()
        self.sendPacket()
        self.verifyPackets()
        verify_no_other_packets(self, self.dev_id, timeout=2)

class Test1(AbstractTest):
    """
    Ingress packet on port 8:
        ig_intr_md.resubmit_flag = 0b0
        ig_intr_md._pad1 = 0b0
        ig_intr_md.packet_version = 0b11
        ig_intr_md._pad2 = 0b000
        ig_intr_md.ingress_port = 0b0_0000_1000
        ig_intr_md.ingress_mac_tstamp = 0xf07f_3d41_888c
        hdr.data.f1 = 0xa9bb_5e3c
        hdr.data.f2 = 0x1019_c0c0
        hdr.data.h1 = 0xcf7d
        hdr.data.b1 = 0x19
        hdr.data.b2 = 0x3c
    
    Trace:
        [ Start     ] ingress parser
        [ Parser    ] ingress$ingress::$$entry_point
        [ Parser    ] ingress$ingress::$$ingress_tna_entry_point
        [ Parser    ] ingress$ingress::$$ingress_metadata
        [ Extract   ] ig_intr_md.resubmit_flag
        [ Extract   ] ig_intr_md._pad1
        [ Extract   ] ig_intr_md.packet_version
        [ Extract   ] ig_intr_md._pad2
        [ Extract   ] ig_intr_md.ingress_port
        [ Extract   ] ig_intr_md.ingress_mac_tstamp
        [ Parser    ] ingress$ingress::$$check_resubmit
        [ Parser    ] ingress$ingress::$$phase0
        [ Parser    ] ingress$ingress::$$skip_to_packet
        [ Parser    ] ingress$ingress::start
        [ Extract   ] hdr.data.f1
        [ Extract   ] hdr.data.f2
        [ Extract   ] hdr.data.h1
        [ Extract   ] hdr.data.b1
        [ Extract   ] hdr.data.b2
        [ End       ] ingress parser
        [ Start     ] ingress MAU
        [ Action    ] tbl_act <default> (act)
        [ End       ] ingress MAU
        [ Start     ] ingress deparser
        [ Deparse   ] compiler_generated_meta.^bridged_metadata.^bridged_metadata_indicator
        [ Deparse   ] hdr.data.f1
        [ Deparse   ] hdr.data.f2
        [ Deparse   ] hdr.data.h1
        [ Deparse   ] hdr.data.b1
        [ Deparse   ] hdr.data.b2
        [ End       ] ingress deparser
        [ Start     ] egress parser
        [ Parser    ] egress$egress::$$entry_point
        [ Parser    ] egress$egress::$$egress_tna_entry_point
        [ Parser    ] egress$egress::$$egress_metadata
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
        [ Parser    ] egress$egress::$$check_mirrored
        [ Parser    ] egress$egress::$$bridged_metadata
        [ Extract   ] compiler_generated_meta.^bridged_metadata.^bridged_metadata_indicator
        [ Parser    ] egress$egress::start
        [ Extract   ] hdr.data.f1
        [ Extract   ] hdr.data.f2
        [ Extract   ] hdr.data.h1
        [ Extract   ] hdr.data.b1
        [ Extract   ] hdr.data.b2
        [ End       ] egress parser
        [ Start     ] egress MAU
        [ End       ] egress MAU
        [ Start     ] egress deparser
        [ Deparse   ] hdr.data.f1
        [ Deparse   ] hdr.data.f2
        [ Deparse   ] hdr.data.h1
        [ Deparse   ] hdr.data.b1
        [ Deparse   ] hdr.data.b2
        [ End       ] egress deparser
    
    Egress packet on port 10:
        hdr.data.f1 = 0xa9bb_5e3c
        hdr.data.f2 = 0x1019_c0c0
        hdr.data.h1 = 0x00ff
        hdr.data.b1 = 0x19
        hdr.data.b2 = 0x3c
    """

    def setupCtrlPlane(self):
        pass

    def sendPacket(self):
        ig_port = 8
        pkt = b'\xa9\xbb\x5e\x3c\x10\x19\xc0\xc0\xcf\x7d\x19\x3c\x89\x7a\x96\x3d\xae\xb4\xb0\xca\x82\x22\xec\x2c\xb7\x8a\xdf\x9b\x97\x92\x3a\xb2\x37\x10\x54\x84\x4b\xa8\xea\x2e\x42\x09\x16\x30\xc4\x4a\xab\xf8\xcc\x6d\xa8\x91\x67\x72\xa3\xa0\xce\x19\xf0\xe0\xfe\x62\x8d\xfb'
        send_packet(self, ig_port, pkt)

    def verifyPackets(self):
        eg_port = 10
        exp_pkt = b'\xa9\xbb\x5e\x3c\x10\x19\xc0\xc0\x00\xff\x19\x3c\x89\x7a\x96\x3d\xae\xb4\xb0\xca\x82\x22\xec\x2c\xb7\x8a\xdf\x9b\x97\x92\x3a\xb2\x37\x10\x54\x84\x4b\xa8\xea\x2e\x42\x09\x16\x30\xc4\x4a\xab\xf8\xcc\x6d\xa8\x91\x67\x72\xa3\xa0\xce\x19\xf0\xe0\xfe\x62\x8d\xfb'
        verify_packet(self, exp_pkt, eg_port)

    def runTest(self):
        self.runTestImpl()

# Covered 114 of 250 branches (45.6%).
# Note: not all branches may be feasible.
