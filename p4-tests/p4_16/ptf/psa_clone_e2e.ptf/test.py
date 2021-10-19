
import logging
import time
from ptf import config
from ptf.thriftutils import *
import ptf.testutils as testutils

from p4.v1 import p4runtime_pb2
from p4runtime_base_tests import P4RuntimeTest, autocleanup, stringify, ipv4_to_binary, mac_to_binary
from itertools import chain

class CloneTest(P4RuntimeTest):
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
        port1, port2 = self.swports(5), self.swports(2)
        session = p4runtime_pb2.CloneSessionEntry()
        session.session_id = 10
        replicas = CloneTest.ReplicaMgr(session)
        pkt = testutils.simple_eth_packet(eth_dst="01:02:03:04:05:06",
                                          eth_src="00:00:00:00:00:01")

        exp_pkt = testutils.simple_eth_packet(eth_dst="00:00:00:00:00:04",
                                              eth_src="00:00:00:00:00:0F")

        replicas.append(port1, 5)
        self.create_session(session)
        testutils.send_packet(self, ig_port, pkt)
        testutils.verify_packet(self, exp_pkt, port1)
