"""
8012.1Qbh - VN-Tag
This evolved into the 802.1BR standard
"""
# scapy.contrib.description = 8012.1Qbh - VN-Tag
# scapy.contrib.status = loads

from scapy.packet import Packet, bind_layers
from scapy.fields import *
from scapy.layers.l2 import ARP, Ether, Dot1Q, Dot1AD
from scapy.data import ETHER_TYPES
from scapy.layers.inet import IP
from scapy.layers.inet6 import IPv6
from scapy.contrib.mpls import MPLS

class VNTag(Packet):
    name = "802_1Qbh"
    fields_desc = [ BitField("dir",     0, 1),
                    BitField("ptr",     0, 1),
                    BitField("dvif_id", 0, 14),
                    BitField("looped",  0, 1),
                    BitField("rsvd",    0, 1),
                    BitField("version", 0, 2),
                    BitField("svid_id", 0, 12),
                    XShortEnumField("type", 0x0000, ETHER_TYPES)]

    def mysummary(self):
        return self.sprintf("802.1Qbh SVIF_ID %VNTag.svid_id%")

bind_layers(Ether, VNTag,  type=0x8926)

bind_layers(VNTag, Dot1Q,  type=0x8100)
bind_layers(VNTag, Dot1AD, type=0x88a8)
bind_layers(VNTag, IP,     type=0x0800)
bind_layers(VNTag, IPv6,   type=0x86dd)
bind_layers(VNTag, ARP,    type=0x0806)
bind_layers(VNTag, MPLS,   type=0x8847)
