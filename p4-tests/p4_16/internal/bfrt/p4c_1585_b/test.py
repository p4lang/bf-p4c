from bfruntime_base_tests import BfRuntimeTest
from ptf.mask import Mask
from ptf.testutils import send_packet
from ptf.testutils import verify_packet
from ptf.testutils import verify_no_other_packets

class AbstractTest(BfRuntimeTest):
    def setUp(self):
        BfRuntimeTest.setUp(self, 0, 'p4c_1585_b')
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
            self.get_bfrt_info('p4c_1585_b')))
        
        # Set target to all pipes on device self.dev_id.
        self.target = self.Target(device_id = self.dev_id, pipe_id = 0xffff)
        
        self.setupCtrlPlane()
        self.sendPacket()
        self.verifyPackets()
        verify_no_other_packets(self, self.dev_id, timeout=2)

class Test1(AbstractTest):
    def sendPacket(self):
        ig_port = 10
        pkt = b'\x22\x22\x22\x22\x22\x22\x00\x06\x07\x08\x09\x0a\x08\x00\x45\x00\x00\x56\x00\x01\x00\x00\x40\x11\xf9\x42\xc0\xa8\x00\x01\xc0\xa8\x00\x02\x04\xd2\x00\x50\x00\x42\x49\xa8\x00\x01\x02\x03\x04\x05\x06\x07\x08\x09\x0a\x0b\x0c\x0d\x0e\x0f\x10\x11\x12\x13\x14\x15\x16\x17\x18\x19\x1a\x1b\x1c\x1d\x1e\x1f\x20\x21\x22\x23\x24\x25\x26\x27\x28\x29\x2a\x2b\x2c\x2d\x2e\x2f\x30\x31\x32\x33\x34\x35\x36\x37\x38\x39\x00\x00\x00\x00'
        send_packet(self, ig_port, pkt)
    
    def verifyPackets(self):
        eg_port = 10
        exp_pkt = b'\x22\x22\x22\x22\x22\x22\x00\x06\x07\x08\x09\x0a\x08\x00\x45\x00\x00\x56\x00\x01\x00\x00\x40\x11\xf9\x42\xc0\xa8\x00\x01\xc0\xa8\x00\x02\x04\xd2\x00\x50\x00\x42\x49\xa8\x00\x01\x02\x03\x04\x05\x06\x07\x08\x09\x0a\x0b\x0c\x0d\x0e\x0f\x10\x11\x12\x13\x14\x15\x16\x17\x18\x19\x1a\x1b\x1c\x1d\x1e\x1f\x20\x21\x22\x23\x24\x25\x26\x27\x28\x29\x2a\x2b\x2c\x2d\x2e\x2f\x30\x31\x32\x33\x34\x35\x36\x37\x38\x39\x00\x00\x00\x00'
        verify_packet(self, exp_pkt, eg_port)
    
    def runTest(self):
        self.runTestImpl()

