import ptf
import os
from ptf import config
import ptf.testutils as testutils

from p4 import p4runtime_pb2

from base_test import P4RuntimeTest, stringify

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
        ingress_port = self.swports(3)
        ingress_port_hex = stringify(ingress_port, 2)  # port is 9-bit so 2-byte
        testutils.send_packet(self, ingress_port, payload)
        packet_in = self.get_packet_in()
        self.assertEqual(packet_in.payload, payload)
        ingress_port = None
        for metadata in packet_in.metadata:
            if metadata.metadata_id == 1:
                ingress_port = metadata.value
                break
        self.assertEqual(ingress_port, ingress_port_hex)

#@testutils.disabled
class PacketOutTest(P4RuntimeTest):
    def runTest(self):
        port = 3
        port_hex = stringify(port, 2)
        payload = 'a' * 20
        packet_out = p4runtime_pb2.PacketOut()
        packet_out.payload = payload
        egress_port = packet_out.metadata.add()
        egress_port.metadata_id = 1  # egress_port
        egress_port.value = port_hex
        submit_to_ingress = packet_out.metadata.add()
        submit_to_ingress.metadata_id = 2
        submit_to_ingress.value = "\x00"  # _padding0

        self.send_packet_out(packet_out)

        testutils.verify_packet(self, payload, port)
        testutils.verify_no_other_packets(self)
