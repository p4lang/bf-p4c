import ptf.testutils as testutils

from p4.v1 import p4runtime_pb2

from p4runtime_base_tests import P4RuntimeTest, stringify, autocleanup

import logging
logger = logging.getLogger('various_indirect_meters')

class MeterTest(P4RuntimeTest):
    @autocleanup
    def runTest(self):
        port = self.swports(1)
        req = p4runtime_pb2.WriteRequest()
        req.device_id = self.device_id

        meter_config = p4runtime_pb2.MeterConfig()
        meter_config.cir = 0
        meter_config.cburst = 0
        meter_config.pir = 0
        meter_config.pburst = 0

        for mtr, idx in [("ingress.mtr_1", self.swports(1)),
                         ("ingress.mtr_2", 0)]:
            update = req.updates.add()
            update.type = p4runtime_pb2.Update.MODIFY
            meter_entry = update.entity.meter_entry
            meter_entry.meter_id = self.get_meter_id(mtr)
            meter_entry.index.index = idx
            meter_entry.config.CopyFrom(meter_config)
        update = req.updates.add()
        update.type = p4runtime_pb2.Update.MODIFY
        meter_entry = update.entity.meter_entry
        meter_entry.meter_id = self.get_meter_id("ingress.mtr_0")
        meter_entry.index.index = port
        meter_entry.config.CopyFrom(meter_config)
        self.write_request(req, store=False)

        self.send_request_add_entry_to_action(
            "ingress.t_mtr_0",
            [self.Exact("sm.ingress_port", stringify(port, 2))],
            "a_mtr_0", [("idx", stringify(port, 4))])

        pkt = "\xab" * 512
        for i in xrange(50):
            testutils.send_packet(self, port, pkt)

        cnt_green_0 = cnt_green_1 = cnt_green_2 = 0
        for i in xrange(50):
            rcv_pkt = testutils.dp_poll(self, port_number=port, timeout=2)
            self.assertIsInstance(rcv_pkt, self.dataplane.PollSuccess)
            rcv_pkt = rcv_pkt.packet
            if rcv_pkt[0] == '\x01':
                cnt_green_0 += 1
            if rcv_pkt[1] == '\x01':
                cnt_green_1 += 1
            if rcv_pkt[2] == '\x01':
                cnt_green_2 += 1

        logger.info("cnt green 0: {}".format(cnt_green_0))
        logger.info("cnt green 1: {}".format(cnt_green_1))
        logger.info("cnt green 2: {}".format(cnt_green_2))

        self.assertLess(cnt_green_0, 30)
        self.assertLess(cnt_green_1, 30)
        self.assertLess(cnt_green_2, 30)

        testutils.verify_no_other_packets(self)
