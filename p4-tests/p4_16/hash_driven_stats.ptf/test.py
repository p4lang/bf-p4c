import ptf
import os
from ptf import config
import ptf.testutils as testutils

from p4 import p4runtime_pb2

from base_test import P4RuntimeTest

#@testutils.disabled
class CounterReadTest(P4RuntimeTest):
    def read_counter(self, name, port):
        req = p4runtime_pb2.ReadRequest()
        req.device_id = self.device_id
        entity = req.entities.add()
        counter_entry = entity.counter_entry
        cid = self.get_counter_id(name)
        counter_entry.counter_id = cid
        counter_entry.index = port
        for rep in self.stub.Read(req):
            for entity in rep.entities:
                counter_entry = entity.counter_entry
                if counter_entry.counter_id == cid and counter_entry.index == port:
                    return counter_entry.data.byte_count

    def runTest(self):
        ingress_port = self.swports(1)
        egress_port = self.swports(2)

        def get_counts():
            ingress_count = self.read_counter("ingress_port_counter", ingress_port)
            egress_count = self.read_counter("egress_port_counter", egress_port)
            return ingress_count, egress_count

        ingress_count, egress_count = get_counts()
        self.assertEqual(ingress_count, 0)
        self.assertEqual(egress_count, 0)
        size = 70
        pkt = "\xab" * size
        testutils.send_packet(self, ingress_port, pkt)
        testutils.verify_packet(self, pkt, egress_port)
        ingress_count, egress_count = get_counts()
        print "Ingress Count: ", ingress_count
        print "Egress Count: ", egress_count
        #WIP: Working on bytecount adjust to account for additional 16 bytes
        self.assertEqual(ingress_count, 70)
        self.assertEqual(egress_count, 70)
