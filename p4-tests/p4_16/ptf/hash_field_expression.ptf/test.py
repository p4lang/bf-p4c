import logging
import time

from scapy.all import *

from ptfutils.test_runtime import TestRuntime

logger = logging.getLogger('hash_field_expression')
logger.addHandler(logging.StreamHandler())

class TestPacketIn(Packet):
    name = "TestPacketIn "
    fields_desc = [
        BitField("field1", 0, 32),
        BitField("field2", 0, 32),
        BitField("field3", 0, 32)
    ]


class TestPacketOut(Packet):
    name = "TestPacketOut "
    fields_desc = [
        BitField("result1", 0, 16),
        BitField("result2", 0, 16),
        BitField("result3", 0, 16),
        BitField("result4", 0, 16),
        BitField("result3t", 0, 16),
        BitField("result4t", 0, 16),
        BitField("result5", 0, 16),
        BitField("result6", 0, 16),
        BitField("result5t", 0, 16),
        BitField("result6t", 0, 16),
        BitField("result7", 0, 16),
        BitField("result8", 0, 16),
        BitField("result9", 0, 16),
        BitField("result10", 0, 32),
        BitField("result11", 0, 16),
    ]


ETHER_TYPE_IN = 0x9030
ETHER_TYPE_OUT = 0x9031
bind_layers(Ether, TestPacketIn, type=ETHER_TYPE_IN)
bind_layers(TestPacketIn, Ether)
bind_layers(Ether, TestPacketOut, type=ETHER_TYPE_OUT)
bind_layers(TestPacketOut, Ether)


class Test_HashFieldExpression(TestRuntime):
    def _setTableUp(self, name):
        tbl_builder = self.createTableEntryBuilder(
            "ingress.table" + name, "ingress.action" + name)
        tbl_builder.appendHalfWordKey("hdr.ethernet.ether_type", ETHER_TYPE_IN)
        tbl_builder.commitEntry()

    def runTest(self):
        ingress_port = 1

        self._setTableUp("LocalTable")
        self._setTableUp("DirectExpressionTable")

        in_pkt = Ether()/TestPacketIn(field1=0x12345678 - 10, field2=0x9abcdef - 20, field3=0xce1266af - 30)
        out_pkt = Ether()/TestPacketOut(
            result1=0x1ba4, result2=0x5975,     # -- asymmetric list
            result3=0x5789, result4=0x1558,     # -- local variable asymmetric
            result3t=0x5789, result4t=0x1558,   # -- local variable asymmetric in table
            result5=0x5789, result6=0x1558,     # -- expression asymmetric
            result5t=0x8ca4, result6t=0xf457,   # -- expression asymmetric in table
            result7=0x8ca4, result8=0xf457,     # -- constant variable asymmetric
            result9=0x8ca4,                     # -- concatenation expression
            result10=0x95ee42c8,                # -- in_hash expression
            result11=0x8ca4                     # -- hash in the apply block
        )

        self.sendPacket(ingress_port, in_pkt)
        self.verifyFinalPacket(ingress_port, out_pkt)
