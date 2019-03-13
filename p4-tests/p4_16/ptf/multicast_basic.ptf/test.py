import ptf.testutils as testutils

from p4.v1 import p4runtime_pb2

from p4runtime_base_tests import P4RuntimeTest, stringify

class MulticastTest(P4RuntimeTest):
    # TODO(antonin): move to P4RuntimeTest base class if other P4Runtime tests
    # use multicast
    def write_group(self, group, update_type):
        req = p4runtime_pb2.WriteRequest()
        req.device_id = self.device_id
        update = req.updates.add()
        update.type = update_type
        pre_entry = update.entity.packet_replication_engine_entry
        pre_entry.multicast_group_entry.CopyFrom(group)
        return self.write_request(req)

    def create_group(self, group):
        return self.write_group(group, p4runtime_pb2.Update.INSERT)

    def modify_group(self, group):
        return self.write_group(group, p4runtime_pb2.Update.MODIFY)

    def delete_group(self, group):
        return self.write_group(group, p4runtime_pb2.Update.DELETE)

    class ReplicaMgr(object):
        def __init__(self, group):
            self.group = group

        def append(self, port, rid):
            r = self.group.replicas.add()
            r.egress_port = port
            r.instance = rid
            return self

        def pop_back(self):
            del self.group.replicas[-1]
            return self

        # generator function to make ReplicaMgr iterable
        def __iter__(self):
            for r in self.group.replicas:
                yield (r.egress_port, r.instance)

    def verify_mc_packets(self, replicas, pkt):
        for port, rid in replicas:
            exp_pkt = str(pkt)
            exp_pkt = stringify(rid, 2) + exp_pkt[2:]
            testutils.verify_packet(self, exp_pkt, port)

    def runTest(self):
        ig_port = self.swports(0)
        port1, port2, port3 = self.swports(1), self.swports(2), self.swports(3)
        group_id = 10
        group = p4runtime_pb2.MulticastGroupEntry()
        group.multicast_group_id = group_id
        replicas = MulticastTest.ReplicaMgr(group)
        pkt = "\x00\x0a" + "\xab" * 70

        replicas.append(port1, 1).append(port2, 2)
        self.create_group(group)
        testutils.send_packet(self, ig_port, pkt)
        self.verify_mc_packets(replicas, pkt)

        replicas.append(port3, 1)
        self.modify_group(group)
        testutils.send_packet(self, ig_port, pkt)
        self.verify_mc_packets(replicas, pkt)

        replicas.pop_back()
        self.modify_group(group)
        testutils.send_packet(self, ig_port, pkt)
        self.verify_mc_packets(replicas, pkt)

        self.delete_group(group)
        testutils.send_packet(self, ig_port, pkt)

        testutils.verify_no_other_packets(self)
