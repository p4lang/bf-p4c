"""
Custom Scapy protocol to support Extreme NPB CPU-Path packets:

  Ether(type=0x9000) / Fabric() / CPU()
  Ether(type=0x9001) / CPU()

The default ether-type associated with these frames is 0x9000.
However, in the actual (p4 pipeline) implementation, the value
is configurable. If the default value changes, the user will
need to over-ride accordingly.
"""

# scapy.contrib.description = Extreme NPB CPU-Path packets
# scapy.contrib.status = loads

from scapy.packet import Packet, bind_layers
from scapy.fields import *
from scapy.layers.l2 import ARP, Ether, Dot1Q, Dot1AD
from scapy.data import ETHER_TYPES
from scapy.layers.inet import IP
from scapy.layers.inet6 import IPv6
from scapy.contrib.mpls import MPLS
from scapy.contrib.vntag import VNTag
from scapy.contrib.dot1br import Dot1BR


class NpbFabric(Packet):
    name = "NpbFabric"
    fields_desc = [ BitField("reserved",  0, 8),
                    BitField("color",     0, 3),
                    BitField("qos",       0, 5),
                    BitField("reserved2", 0, 8)]

    def mysummary(self):
        return self.sprintf("Extreme Networks NPB CPU-Path Fabric Header")

bind_layers(Ether, NpbFabric, type=0x9000)


class NpbCpu(Packet):
    name = "NpbCpu"
    fields_desc = [ BitField("egress_queue",   0, 5),
                    BitField("tx_bypass",      0, 1),
                    BitField("capture_ts",     0, 1),
                    BitField("reserved",       0, 1),
                    BitField("ingress_port",   0, 16),
                    BitField("port_lag_index", 0, 16),
                    BitField("ingress_bd",     0, 16),
                    BitField("reason_code",    0, 16),
                    XShortEnumField("ether_type", 0x0000, ETHER_TYPES)]

    def mysummary(self):
        return self.sprintf("Extreme Networks NPB CPU-Path CPU Header")

bind_layers(Ether, NpbCpu, type=0x9001)
bind_layers(NpbFabric, NpbCpu)

bind_layers(NpbCpu, VNTag,  ether_type=0x8926)
bind_layers(NpbCpu, Dot1BR, ether_type=0x893f)
bind_layers(NpbCpu, Dot1Q,  ether_type=0x8100)
bind_layers(NpbCpu, Dot1AD, ether_type=0x88a8)
bind_layers(NpbCpu, IP,     ether_type=0x0800)
bind_layers(NpbCpu, IPv6,   ether_type=0x86dd)
bind_layers(NpbCpu, ARP,    ether_type=0x0806)
bind_layers(NpbCpu, MPLS,   ether_type=0x8847)


# class NpbFabricCpu(Packet):
#     name = "NpbFabricCpu"
#     fields_desc = [ BitField("reserved",       0, 8),
#                     BitField("color",          0, 3),
#                     BitField("qos",            0, 5),
#                     BitField("reserved2",      0, 8),
#                     # -------------------------------
#                     BitField("egress_queue",   0, 5),
#                     BitField("tx_bypass",      0, 1),
#                     BitField("capture_ts",     0, 1),
#                     BitField("reserved3",      0, 1),
#                     BitField("ingress_port",   0, 16),
#                     BitField("port_lag_index", 0, 16),
#                     BitField("ingress_bd",     0, 16),
#                     BitField("reason_code",    0, 16),
#                     XShortEnumField("ether_type", 0x0000, ETHER_TYPES)]
# 
#     def mysummary(self):
#         return self.sprintf("Extreme Networks NPB CPU-Path Fabric/CPU Header")
# 
# bind_layers(Ether, NpbFabricCpu, type=0x9000)
# bind_layers(NpbFabricCpu, VNTag,  ether_type=0x8926)
# bind_layers(NpbFabricCpu, Dot1BR, ether_type=0x893f)
# bind_layers(NpbFabricCpu, Dot1Q,  ether_type=0x8100)
# bind_layers(NpbFabricCpu, Dot1AD, ether_type=0x88a8)
# bind_layers(NpbFabricCpu, IP,     ether_type=0x0800)
# bind_layers(NpbFabricCpu, IPv6,   ether_type=0x86dd)
# bind_layers(NpbFabricCpu, ARP,    ether_type=0x0806)
# bind_layers(NpbFabricCpu, MPLS,   ether_type=0x8847)

