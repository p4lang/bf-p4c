import ptf.testutils as testutils

from p4.v1 import p4runtime_pb2

from p4runtime_base_tests import P4RuntimeTest, stringify

from itertools import chain

class CloneTest(P4RuntimeTest):
    # TODO(antonin): move to P4RuntimeTest base class if other P4Runtime tests
    # use cloning
    def write_session(self, session, update_type):
        req = p4runtime_pb2.WriteRequest()
        req.device_id = self.device_id
        update = req.updates.add()
        update.type = update_type
        pre_entry = update.entity.packet_replication_engine_entry
        pre_entry.clone_session_entry.CopyFrom(session)
        return self.write_request(req)

    def create_session(self, session):
        return self.write_session(session, p4runtime_pb2.Update.INSERT)

    def modify_session(self, session):
        return self.write_session(session, p4runtime_pb2.Update.MODIFY)

    def delete_session(self, session):
        return self.write_session(session, p4runtime_pb2.Update.DELETE)

    class ReplicaMgr(object):
        def __init__(self, session):
            self.session = session

        def append(self, port, rid):
            r = self.session.replicas.add()
            r.egress_port = port
            r.instance = rid
            return self

        def pop_back(self):
            del self.session.replicas[-1]
            return self

        # generator function to make ReplicaMgr iterable
        def __iter__(self):
            for r in self.session.replicas:
                yield (r.egress_port, r.instance)

    def verify_packets(self, original, replicas, pkt):
        for port, rid in chain([original], replicas):
            exp_pkt = pkt
            exp_pkt = rid.to_bytes(2, 'big') + exp_pkt[2:]
            testutils.verify_packet(self, exp_pkt, port)

    def runTest(self):
        ig_port = self.swports(0)
        port1, port2 = self.swports(1), self.swports(2)
        session = p4runtime_pb2.CloneSessionEntry()
        session.session_id = 10
        replicas = CloneTest.ReplicaMgr(session)
        pkt = b"\x00\x0a" + b"\xab" * 70

        replicas.append(port1, 1)
        self.create_session(session)
        testutils.send_packet(self, ig_port, pkt)
        self.verify_packets((ig_port, 0), replicas, pkt)

        replicas.append(port2, 2)
        self.modify_session(session)
        testutils.send_packet(self, ig_port, pkt)
        self.verify_packets((ig_port, 0), replicas, pkt)

        replicas.pop_back()
        self.modify_session(session)
        testutils.send_packet(self, ig_port, pkt)
        self.verify_packets((ig_port, 0), replicas, pkt)

        self.delete_session(session)
        testutils.send_packet(self, ig_port, pkt)

        self.verify_packets((ig_port, 0), [], pkt)
