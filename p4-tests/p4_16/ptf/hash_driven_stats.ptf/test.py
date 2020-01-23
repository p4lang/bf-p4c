import ptf.testutils as testutils

from p4.v1 import p4runtime_pb2

from p4runtime_base_tests import P4RuntimeTest

class CounterReadTest(P4RuntimeTest):
    def read_counter(self, name, port):
        req = p4runtime_pb2.ReadRequest()
        req.device_id = self.device_id
        entity = req.entities.add()
        counter_entry = entity.counter_entry
        cid = self.get_counter_id(name)
        counter_entry.counter_id = cid
        counter_entry.index.index = port
        for rep in self.stub.Read(req):
            for entity in rep.entities:
                counter_entry = entity.counter_entry
                if counter_entry.counter_id == cid and counter_entry.index.index == port:
                    return counter_entry.data.byte_count

    def runTest(self):
        ingress_port = self.swports(1)
        egress_port = self.swports(2)

        def get_counts():
            ingress_count = self.read_counter("ingress_port_counter", ingress_port)
            egress_count = self.read_counter("egress_port_counter", egress_port)
            return ingress_count, egress_count

        ingress_count_0, egress_count_0 = get_counts()
        # On HW we observe some extra packets sent before the test, as the ports
        # are being brought-up. To avoid the issue, we only check that the
        # counters are incremented correctly, instead of checking for absolute
        # values.
        # self.assertEqual(ingress_count_0, 0)
        # self.assertEqual(egress_count_0, 0)
        size = 70
        pkt = "\xab" * size
        testutils.send_packet(self, ingress_port, pkt)
        testutils.verify_packet(self, pkt, egress_port)
        ingress_count, egress_count = get_counts()
        print "Ingress Count: ", ingress_count
        print "Egress Count: ", egress_count
        # FIXME: Due to the model adding 4 extra bytes, we update the counters with this value
        # Must check with Sachin to validate this behavior as a check
        # WIP: Working on bytecount adjust to account for additional 16 bytes
        self.assertEqual(ingress_count - ingress_count_0, 74)
        self.assertEqual(egress_count - egress_count_0, 74)
