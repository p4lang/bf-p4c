import ptf.testutils as testutils

from p4.v1 import p4runtime_pb2

from p4runtime_base_tests import P4RuntimeTest, autocleanup, mac_to_binary
from p4runtime_base_tests import stringify, P4RuntimeMissingStreamMsgException

import time
import binascii

class IdleTimeoutTest(P4RuntimeTest):
    def setUp(self):
        P4RuntimeTest.setUp(self)
        self.counter_name = "pkt_counters"
        self.counter_id = self.get_direct_counter_id(self.counter_name)

    def check_counter(self, table_entry, expected):
        req = p4runtime_pb2.ReadRequest()
        req.device_id = self.device_id
        entity = req.entities.add()
        counter_entry = entity.direct_counter_entry
        counter_entry.table_entry.CopyFrom(table_entry)
        count = 0
        for rep in self.stub.Read(req):
            for entity in rep.entities:
                counter_entry = entity.direct_counter_entry
                count = counter_entry.data.packet_count
        self.assertEqual(count, expected)

class IdleTimeoutNotification(IdleTimeoutTest):
    @autocleanup
    def runTest(self):
        smac = "aa:bb:cc:dd:ee:ff"
        self.send_request_add_entry_to_action(
            "smac", [self.Exact("h.ethernet.smac", mac_to_binary(smac))], "nop", [],
            timeout_ms=1000)
        self.get_idle_timeout_notification(timeout=3)
        # another notification is expected after the TTL expires again
        self.get_idle_timeout_notification(timeout=3)

class IdleTimeoutModifyTTL(IdleTimeoutTest):
    @autocleanup
    def runTest(self):
        smac = "aa:bb:cc:dd:ee:ff"
        self.send_request_add_entry_to_action(
            "smac", [self.Exact("h.ethernet.smac", mac_to_binary(smac))], "nop", [],
            timeout_ms=100000)  # 100s

        time.sleep(1)

        req = self.get_new_write_request()
        self.push_update_add_entry_to_action(
            req, "smac", [self.Exact("h.ethernet.smac", mac_to_binary(smac))], "nop", [],
            timeout_ms=2000)
        req.updates[-1].type = p4runtime_pb2.Update.MODIFY
        self.write_request(req, store=False)

        self.get_idle_timeout_notification(timeout=3)

class IdleTimeoutTimeSinceLastHit(IdleTimeoutTest):
    @autocleanup
    def runTest(self):
        smac = "aa:bb:cc:dd:ee:ff"
        wreq = self.get_new_write_request()
        self.push_update_add_entry_to_action(
            wreq, "smac", [self.Exact("h.ethernet.smac", mac_to_binary(smac))], "nop", [],
            timeout_ms=100000)
        self.write_request(wreq)

        pkt = testutils.simple_tcp_packet(eth_src=smac)
        testutils.send_packet(self, self.swports(1), pkt)
        testutils.verify_packet(self, pkt, self.swports(1))

        self.check_counter(wreq.updates[-1].entity.table_entry, 1)

        time.sleep(2)

        rreq = p4runtime_pb2.ReadRequest()
        rreq.device_id = self.device_id
        entity = rreq.entities.add()
        entity.CopyFrom(wreq.updates[-1].entity)
        entity.table_entry.time_since_last_hit.elapsed_ns = 0
        for rep in self.stub.Read(rreq):
            for entity in rep.entities:
                timeout_ns = entity.table_entry.idle_timeout_ns
                timeout_ms = timeout_ns / 1000000
                self.assertEqual(timeout_ms, 100000)
                elapsed_ns = entity.table_entry.time_since_last_hit.elapsed_ns
                elapsed_ms = elapsed_ns / 1000000
                self.assertGreater(elapsed_ms, 1000)
                self.assertLess(elapsed_ms, 3000)

class DigestTest(P4RuntimeTest):
    def setUp(self):
        P4RuntimeTest.setUp(self)
        self.digest_name = "L2_digest"
        self.digest_id = self.get_digest_id(self.digest_name)

    def ack(self, list_id):
        self.send_digest_ack(self.digest_id, list_id)

    def check_digest_data(self, data, smac, port):
        self.assertTrue(data.HasField("struct"))
        self.assertEqual(len(data.struct.members), 2)
        self.assertEqual(data.struct.members[0].bitstring, smac)
        self.assertEqual(data.struct.members[1].bitstring, port)

class DigestNotificationAndAck(DigestTest):
    @autocleanup
    def runTest(self):
        smac = "aa:bb:cc:dd:ee:ff"
        port = self.swports(1)
        self.send_request_config_digest(
            self.digest_name,
            max_timeout_ns=100 * 1000 * 1000,  # 100ms
            max_list_size=1,
            ack_timeout_ns=100 * 1000 * 1000 * 1000)  # 100s

        pkt = testutils.simple_tcp_packet(eth_src=smac)
        testutils.send_packet(self, port, pkt)
        testutils.verify_packet(self, pkt, port)

        digest = self.get_digest_notification(timeout=1)
        self.assertEqual(digest.digest_id, self.digest_id)
        self.assertEqual(len(digest.data), 1)
        self.check_digest_data(digest.data[0], binascii.unhexlify(smac.replace(':', '')), stringify(port, 2))

        testutils.send_packet(self, port, pkt)
        testutils.verify_packet(self, pkt, port)

        # we didn't send an ack yet so no new notification
        with self.assertRaises(P4RuntimeMissingStreamMsgException):
            self.get_digest_notification(timeout=2)

        self.ack(digest.list_id)

        testutils.send_packet(self, port, pkt)
        testutils.verify_packet(self, pkt, port)

        digest = self.get_digest_notification(timeout=1)
        self.assertEqual(digest.digest_id, self.digest_id)
        self.assertEqual(len(digest.data), 1)
