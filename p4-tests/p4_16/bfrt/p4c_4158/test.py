# PTF test for p4c_4158
# p4testgen seed: 657421720

from bfruntime_client_base_tests import BfRuntimeTest
from ptf.mask import Mask
from ptf.testutils import send_packet
from ptf.testutils import verify_packet
from ptf.testutils import verify_no_other_packets
import bfrt_grpc.client as gc

class AbstractTest(BfRuntimeTest):
    def setUp(self):
        BfRuntimeTest.setUp(self, 0, 'p4c_4158')
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
        pass
    
    def verifyPackets(self):
        pass
    
    def runTestImpl(self):
        # Get bfrt_info and set it as part of the test.
        self.bfrt_info = self.interface.bfrt_info_get('p4c_4158')
        
        # Set target to all pipes on device self.dev_id.
        self.target = gc.Target(device_id = self.dev_id, pipe_id = 0xffff)
        
        self.setupCtrlPlane()

        table = self.bfrt_info.table_get('Midas')
        table.default_entry_set(
            self.target,
            table.make_data([], 'BigPoint'))

        table2 = self.bfrt_info.table_get('Micro')
        table2.default_entry_set(
            self.target,
            table2.make_data([], 'Boring'))

        self.sendPacket()
        self.verifyPackets()
        verify_no_other_packets(self, self.dev_id, timeout=2)

class Test1(AbstractTest):
    """
    """
    
    def setupCtrlPlane(self):
        pass
    
    def sendPacket(self):
        ig_port = 9
        pkt = b'\x42\x1c\x73\x34\x56\x78\x00\x00\x64\x01\x00\xff\x08\x00\x45\x00\x00\x32\x00\x00\x00\x00\x40\x06\xab\x09\x0a\x01\x03\x0a\xc0\xa8\x02\x0a\x00\x49\x00\x50\x00\x00\x00\x00\x00\x00\x00\x00\x50\x00\x00\x00\xcb\x6b\x00\x00\x00\x01\x02\x03\x04\x05\x06\x07\x08\x09'
        send_packet(self, ig_port, pkt)
    
    def verifyPackets(self):
        eg_port = 10
        exp_pkt = b'\x23\x29\x06\x9f\xd5\x88\x37\x82\x8e\x59\x20\x13\x42\x42\x42\x32\x48\xa5\xa7\x67\x76\xe9\x92\x96\x94\xd4\xe7\x42\x42\x42\xba\x0a\xf8\x29\xc2\x00\x31\x0f\xf9\xed\x73\x56\x68\x50\x22\xf5\xb4\xed\xe7\x89\xaa\xd8\xe5\x25\x61\x6d\x4b\x3c\x43\xdc\x86\xb2\xf4\xd6\xa5\xd4\xcd\x03\xf8\xb1\x59\xc7\x97\x2b\x6f\x86\x77\x05\xa8\x8b\x35\x1d\xbd\x01\xff\x7c'
        verify_packet(self, exp_pkt, eg_port)
    
    def runTest(self):
        self.runTestImpl()

