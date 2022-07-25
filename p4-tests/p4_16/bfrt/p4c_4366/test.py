# PTF test for p4c_4366

from bfruntime_client_base_tests import BfRuntimeTest
from ptf.mask import Mask
from ptf.testutils import send_packet
from ptf.testutils import verify_packet
from ptf.testutils import verify_no_other_packets
import bfrt_grpc.client as gc

class P4C4366Test(BfRuntimeTest):
    def setUp(self):
        BfRuntimeTest.setUp(self, 0, 'p4c_4366')
        self.dev_id = 0
        self.table_entries = []
        self.bfrt_info = None
    
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
        ig_port = 1
        pkt = b'\x01\x02\x03\x04\x55\x06\x00\x00\x64\x01\x00\xff\x08\x00\x45\x00\x00\x32\x00\x00\x00\x00\x40\x06\xab\x09\x0a\x01\x03\x0a\xc0\xa8\x02\x0a\x00\x49\x00\x50\x00\x00\x00\x00\x00\x00\x00\x00\x50\x00\x00\x00\xcb\x6b\x00\x00\x00\x01\x02\x03\x04\x05\x06\x07\x08\x09'
        send_packet(self, ig_port, pkt)
    
    def verifyPackets(self):
        eg_port = 1
        exp_pkt = b'\x01\x02\x03\x04\x55\x06\x00\x00\x64\x01\x00\xff\x08\x00\x45\x00\x00\x32\x00\x00\x00\x00\x40\x06\xab\x09\x0a\x01\x03\x0a\xc0\xa8\x02\x0a\x00\x49\x00\x50\x00\x00\x00\x00\x00\x00\x00\x00\x50\x00\x00\x00\xcb\x6b\x00\x00\x00\x01\x02\x03\x04\x05\x06\x07\x08\x09'
        verify_packet(self, exp_pkt, eg_port)
    
    def runTestImpl(self):
        # Get bfrt_info and set it as part of the test.
        self.bfrt_info = self.interface.bfrt_info_get('p4c_4366')
        
        # Set target to all pipes on device self.dev_id.
        self.target = gc.Target(device_id = self.dev_id, pipe_id = 0xffff)
        
        self.setupCtrlPlane()

        table = self.bfrt_info.table_get('forward')
        key_list = []
        data_list = []
        key_list.append(table.make_key(
            [gc.KeyTuple('hdr.ethernet.dst_addr & 0x1f', 0x6),
             gc.KeyTuple('hdr.ethernet.dst_addr & 0xf000', 0x5000),
             gc.KeyTuple('ig_intr_md.ingress_port', 1)]))
        data_list.append(table.make_data([gc.DataTuple('port', 1)],
                                                    "SwitchIngress.hit"))
        table.entry_add(self.target, key_list, data_list)

        self.sendPacket()
        self.verifyPackets()
        verify_no_other_packets(self, self.dev_id, timeout=2)
    
    def runTest(self):
        self.runTestImpl()

