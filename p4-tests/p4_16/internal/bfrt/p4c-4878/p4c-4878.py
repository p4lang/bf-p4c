# PTF test for p4c-4878
# p4testgen seed: 'none'

import logging
import itertools

from bfruntime_client_base_tests import BfRuntimeTest
from ptf.mask import Mask
from ptf.testutils import send_packet
from ptf.testutils import verify_packet
from ptf.testutils import verify_no_other_packets
import bfrt_grpc.client as gc

logger = logging.getLogger('p4c-4878')
logger.addHandler(logging.StreamHandler())

class AbstractTest(BfRuntimeTest):
    def setUp(self):
        BfRuntimeTest.setUp(self, 0, 'p4c-4878')
        self.dev_id = 0
        self.table_entries = []
        self.bfrt_info = None
        self.target = None

    def tearDown(self):
        # Reset tables.
        for elt in reversed(self.table_entries):
            test_table = self.bfrt_info.table_get(elt[0])
            test_table.entry_del(self.target, elt[1])
        self.table_entries = []

        # End session.
        BfRuntimeTest.tearDown(self)

    def insertTableEntry(self, table_name, key_fields = None,
            action_name = None, data_fields = []):
        test_table = self.bfrt_info.table_get(table_name)
        key_list = [test_table.make_key(key_fields)]
        data_list = [test_table.make_data(data_fields, action_name)]
        test_table.entry_add(self.target, key_list, data_list)
        self.table_entries.append((table_name, key_list))

    def setupCtrlPlane(self):
        pass

    def sendPacket(self):
        pass

    def verifyPackets(self):
        pass

    def runTestImpl(self):
        # Get bfrt_info and set it as part of the test.
        self.bfrt_info = self.interface.bfrt_info_get('p4c-4878')

        # Set target to all pipes on device self.dev_id.
        self.target = gc.Target(device_id=0, pipe_id=0xffff)

        self.setupCtrlPlane()
        logger.info("Sending Packet ...")
        self.sendPacket()
        logger.info("Verifying Packet ...")
        self.verifyPackets()
        logger.info("Verifying no other packets ...")
        verify_no_other_packets(self, self.dev_id, timeout=2)

PAYLOAD = b'\x00' * 64

# tests first (unique) pipe
class TestPipe0(AbstractTest):
    def setupCtrlPlane(self):
        self.insertTableEntry(
            'Ingress1.t1', [gc.KeyTuple('hdr.payload.x', 0x00)],
            'Ingress1.a1', [],
        )

    def sendPacket(self):
        pkt = b'\x00' + PAYLOAD
        send_packet(self, 8, pkt)

    def verifyPackets(self):
        exp_pkt = b'\x01' + PAYLOAD
        verify_packet(self, exp_pkt, 8)

    def runTest(self):
        self.runTestImpl()

# function to generate tests for second, third and fourth pipes, which are equivalent
def make_test_pipe2(pipe_id, pipe_name):
    port = 8 | (pipe_id << 7)

    class Pipe2TestImpl(AbstractTest):
        def setupCtrlPlane(self):
            self.insertTableEntry(
                f'{pipe_name}.Ingress2.t2', [gc.KeyTuple('hdr.payload.x', 0x00)],
                'Ingress2.a2', [],
            )

        def sendPacket(self):
            pkt = b'\x00' + PAYLOAD
            send_packet(self, port, pkt)

        def verifyPackets(self):
            exp_pkt = b'\x02' + PAYLOAD
            verify_packet(self, exp_pkt, port)

        def runTest(self):
            self.runTestImpl()

    return Pipe2TestImpl

TestPipe1 = make_test_pipe2(pipe_id=1, pipe_name='pipe2a')
TestPipe2 = make_test_pipe2(pipe_id=2, pipe_name='pipe2b')
TestPipe3 = make_test_pipe2(pipe_id=3, pipe_name='pipe2c')

