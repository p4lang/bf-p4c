import ptf
import os
from ptf import config
import ptf.testutils as testutils

from p4 import p4runtime_pb2
from p4.tmp import p4config_pb2
from p4.config import p4info_pb2
import google.protobuf.text_format

from base_test import P4RuntimeTest

#@testutils.disabled
class PacketInTest(P4RuntimeTest):
    def runTest(self):
        req = p4runtime_pb2.WriteRequest()
        req.device_id = self.device_id
        update = req.updates.add()
        update.type = p4runtime_pb2.Update.INSERT
        table_entry = update.entity.table_entry
        table_entry.table_id = self.get_table_id("table0")
        self.set_action_entry(table_entry, "send_to_cpu", [])
        response = self.stub.Write(req)

        payload = 'a' * 64
        testutils.send_packet(self, 3, payload)
        packet_in = self.get_packet_in()
        self.assertEqual(packet_in.payload, payload)
        ingress_port = None
        for metadata in packet_in.metadata:
            if metadata.metadata_id == 1:
                ingress_port = metadata.value
                break
        self.assertEqual(ingress_port, "\x00\x03")

#@testutils.disabled
class PacketOutTest(P4RuntimeTest):
    def runTest(self):
        payload = 'a' * 20
        packet_out = p4runtime_pb2.PacketOut()
        packet_out.payload = payload
        egress_port = packet_out.metadata.add()
        egress_port.metadata_id = 1  # egress_port
        egress_port.value = "\x00\x03"
        submit_to_ingress = packet_out.metadata.add()
        submit_to_ingress.metadata_id = 2
        submit_to_ingress.value = "\x00"  # _padding0

        self.send_packet_out(packet_out)

        testutils.verify_packet(self, payload, 3)
        testutils.verify_no_other_packets(self)
