"""
8012.1BR - Virtual Bridge Port Extenstion (E-Tag)
"""

# scapy.contrib.description = Virtual Bridge Port Extension (8012.1BR)
# scapy.contrib.status = loads

from scapy.packet import Packet, bind_layers
from scapy.fields import *
from scapy.layers.l2 import ARP, Ether, Dot1Q, Dot1AD
from scapy.data import ETHER_TYPES
from scapy.layers.inet import IP
from scapy.layers.inet6 import IPv6
from scapy.contrib.mpls import MPLS

class Dot1BR(Packet):
    name = "802_1BR"
    fields_desc = [ BitField("pcp",      0, 3),
                    BitField("dei",      0, 1),
                    BitField("ing_ecid", 0, 12),
                    BitField("rsvd1",    0, 2),
                    BitField("ecid",     0, 14),
                    XShortField("rsvd2", 0),
                    XShortEnumField("type", 0x0000, ETHER_TYPES)]

    def mysummary(self):
        return self.sprintf("802.1BR E-CID %Dot1BR.ing_ecid%")

bind_layers(Ether,  Dot1BR, type=0x893f)

bind_layers(Dot1BR, Dot1Q,  type=0x8100)
bind_layers(Dot1BR, Dot1AD, type=0x88a8)
bind_layers(Dot1BR, IP,     type=0x0800)
bind_layers(Dot1BR, IPv6,   type=0x86dd)
bind_layers(Dot1BR, ARP,    type=0x0806)
bind_layers(Dot1BR, MPLS,   type=0x8847)

