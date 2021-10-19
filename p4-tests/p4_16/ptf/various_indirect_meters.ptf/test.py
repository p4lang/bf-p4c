import ptf.testutils as testutils

from p4.v1 import p4runtime_pb2

from p4runtime_base_tests import P4RuntimeTest, stringify, autocleanup

import logging
logger = logging.getLogger('p4rt_meters')


def get_meter_config():
    meter_config = p4runtime_pb2.MeterConfig()
    meter_config.cir = 0
    meter_config.cburst = 0
    meter_config.pir = 0
    meter_config.pburst = 0
    return meter_config


class IndirectMeterBase(P4RuntimeTest):
    def setUp(self):
        super(IndirectMeterBase, self).setUp()
        self.port = self.swports(1)

    def send_and_check_cnt(self, idx):
        pkt = "\xab" * 512
        for i in range(50):
            testutils.send_packet(self, self.port, pkt)

        cnt_green = 0
        for i in range(50):
            rcv_pkt = testutils.dp_poll(self, port_number=self.port, timeout=2)
            self.assertIsInstance(rcv_pkt, self.dataplane.PollSuccess)
            rcv_pkt = rcv_pkt.packet
            if rcv_pkt[idx] == '\x01':
                cnt_green += 1

        logger.info("cnt green: {}".format(cnt_green))

        self.assertLess(cnt_green, 30)

        testutils.verify_no_other_packets(self)

    def configure_meter(self, name, idx):
        req = p4runtime_pb2.WriteRequest()
        req.device_id = self.device_id
        update = req.updates.add()
        update.type = p4runtime_pb2.Update.MODIFY
        meter_entry = update.entity.meter_entry
        meter_entry.meter_id = self.get_meter_id(name)
        meter_entry.index.index = idx
        meter_entry.config.CopyFrom(get_meter_config())
        self.write_request(req, store=False)


class IndirectMeterTableEntry(IndirectMeterBase):
    @autocleanup
    def runTest(self):
        self.configure_meter("ingress.mtr_0", self.port)
        self.send_request_add_entry_to_action(
            "ingress.t_mtr_0",
            [self.Exact("sm.ingress_port", stringify(self.port, 2))],
            "a_mtr_0", [("idx", stringify(self.port, 4))])
        self.send_and_check_cnt(0)


class IndirectMeterHashDriven(IndirectMeterBase):
    @autocleanup
    def runTest(self):
        self.configure_meter("ingress.mtr_1", self.port)
        self.send_and_check_cnt(1)


class IndirectMeterConstantIdx(IndirectMeterBase):
    @autocleanup
    def runTest(self):
        self.configure_meter("ingress.mtr_2", 0)
        self.send_and_check_cnt(2)
