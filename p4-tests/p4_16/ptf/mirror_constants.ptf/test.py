import logging
import time

from scapy.all import *

from ptfutils.test_runtime import TestRuntime

logger = logging.getLogger('mirror_constants')
logger.addHandler(logging.StreamHandler())

class TestPacket(Packet):
    name = "TestPacket "
    fields_desc = [
        BitField("field1", 255, 8),
        BitField("field2", 127, 16),
        BitField("field4", 63, 32),
        BitField("fixed", 0, 32)
    ]

ETHER_TYPE_TEST = 0x309
bind_layers(Ether, TestPacket, type=ETHER_TYPE_TEST)
bind_layers(TestPacket, Ether)

class Test_MirrorConstants(TestRuntime):
    def runTest(self):
        ingress_port = 0
        self.registerIngressMirrorSession(1, ingress_port, len(Ether()) + 2 * len(TestPacket()) + 1)

        in_pkt = Ether()/TestPacket()
        out_pkt = Ether()/TestPacket(field1 = 9, field2 = 147, field4 = 103, fixed = 144)
        mirrored_pkt = Ether()/TestPacket(field1 = 1, field2 = 2, field4 = 3, fixed = 91)

        self.sendPacket(ingress_port, in_pkt)
        self.verifyPacket(ingress_port, out_pkt)
        self.verifyPacket(ingress_port, mirrored_pkt)
        self.verifyNoOtherPackets()

