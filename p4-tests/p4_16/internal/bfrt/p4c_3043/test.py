# PTF test for p4c_3043
# p4testgen seed: 657421720

from bfruntime_base_tests import BfRuntimeTest
from ptf.mask import Mask
from ptf.testutils import send_packet
from ptf.testutils import verify_packet
from ptf.testutils import verify_no_other_packets

class AbstractTest(BfRuntimeTest):
    def setUp(self):
        BfRuntimeTest.setUp(self, 0, 'p4c_3043')
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
            self.get_bfrt_info('p4c_3043')))
        
        # Set target to all pipes on device self.dev_id.
        self.target = self.Target(device_id = self.dev_id, pipe_id = 0xffff)
        
        self.setupCtrlPlane()
        self.sendPacket()
        self.verifyPackets()
        verify_no_other_packets(self, self.dev_id, timeout=2)

class Test1(AbstractTest):
    """
    """
    
    def setupCtrlPlane(self):
        pass
    
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

