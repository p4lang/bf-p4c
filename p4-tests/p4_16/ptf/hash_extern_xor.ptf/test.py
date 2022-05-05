import logging
import time

from scapy.all import *

from ptfutils.test_runtime import TestRuntime

logger = logging.getLogger('hash_extern_xor')
logger.addHandler(logging.StreamHandler())


class TestPacketIn(Packet):
    name = "TestPacketIn "
    fields_desc = [
        BitField("field1", 255, 8),
        BitField("field2", 127, 16),
        BitField("field4", 63, 32)
    ]


class TestPacketOut(Packet):
    name = "TestPacketOut "
    fields_desc = [
        BitField("xor8", 0, 8),
        BitField("xor16", 0, 16),
        BitField("xor32", 0, 32)
    ]


ETHER_TYPE_IN = 0x309
ETHER_TYPE_OUT = 0x30a
bind_layers(Ether, TestPacketIn, type=ETHER_TYPE_IN)
bind_layers(TestPacketIn, Ether)
bind_layers(Ether, TestPacketOut, type=ETHER_TYPE_OUT)
bind_layers(TestPacketOut, Ether)


class Test_HashExternXOR(TestRuntime):
    def runTest(self):
        ingress_port = 1

        tbl_builder = self.createTableEntryBuilder(
            "ingress.hashTable8", "ingress.computeHashCode8")
        tbl_builder.appendHalfWordKey("hdr.ethernet.ether_type", ETHER_TYPE_IN)
        tbl_builder.commitEntry()
        tbl_builder = self.createTableEntryBuilder(
            "ingress.hashTable16", "ingress.computeHashCode16")
        tbl_builder.appendHalfWordKey("hdr.ethernet.ether_type", ETHER_TYPE_IN)
        tbl_builder.commitEntry()
        tbl_builder = self.createTableEntryBuilder(
            "ingress.hashTable32", "ingress.computeHashCode32")
        tbl_builder.appendHalfWordKey("hdr.ethernet.ether_type", ETHER_TYPE_IN)
        tbl_builder.commitEntry()

        field1 = 0xaa
        field2 = 0x1234
        field4 = 0xdeadbeef
        literal = 0xaa77
        in_pkt = Ether()/TestPacketIn(field1=field1, field2=field2, field4=field4)

        expected8 = (field1 ^ (field2 >> 8) ^ (field2 & 0xff) ^ (literal >> 8)
                     ^ (literal & 0xff) ^ (field4 >> 24) ^ ((field4 >> 16) & 0xff)
                     ^ ((field4 >> 8) & 0xff) ^ (field4 & 0xff))
        expected16 = (((field1 << 8) | (field2 >> 8)) ^ ((field2 << 8) | (literal >> 8))
                      ^ ((literal << 8) | (field4 >> 24)) ^ ((field4 >> 8) & 0xffff)
                      ^ ((field4 & 0xff) << 8))
        expected32 = (((field1 << 24) | (field2 << 8) | (literal >> 8))
                      ^ (((literal & 0xff) << 24) | (field4 >> 8)) ^ ((field4 & 0xff) << 24))
        out_pkt = Ether()/TestPacketOut(xor8=expected8, xor16=expected16, xor32=expected32)

        self.sendPacket(ingress_port, in_pkt)
        self.verifyPacket(ingress_port, out_pkt)
        self.verifyNoOtherPackets()
