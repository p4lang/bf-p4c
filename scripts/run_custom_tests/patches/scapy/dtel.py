# This file is part of Scapy
# Scapy is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 2 of the License, or
# any later version.
#
# Scapy is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Scapy. If not, see <http://www.gnu.org/licenses/>.

# scapy.contrib.description = Network Services Headers (NSH)
# scapy.contrib.status = loads

from scapy.all import bind_layers
from scapy.fields import BitField, ByteField, ByteEnumField
from scapy.fields import ShortField, X3BytesField, XIntField
from scapy.fields import ConditionalField, PacketListField, BitFieldLenField
from scapy.layers.inet import Ether, IP
from scapy.layers.inet6 import IPv6
#from scapy.layers.vxlan import VXLAN
from scapy.packet import Packet
#from scapy.layers.l2 import GRE
#from scapy.contrib.mpls import MPLS

#
# Dtel Support
# ?????
#


class Metadata(Packet):
    name = 'DTEL metadata'
    fields_desc = [XIntField('value', 0)]




class DTEL(Packet):
    """DTEL - Intel Data Telemetry header version 2"""
    name = "DTEL"

    fields_desc = [
	#Main header
        BitField('version', 0, 4),
        BitField('hw_id', 0, 4),
        BitField('seq_number', 0, 24),
        BitField('switch_id', 0, 32),
        BitField('report_length', 0, 16),
        BitField('md_length', 0, 8),
        BitField('d_q_f', 0, 3),
        BitField('reserved', 0, 5),
        BitField('rep_md_bits', 0, 16),
        BitField('domain_specific_id', 0, 16),
        BitField('ds_md_bits', 0, 16),
        BitField('ds_md_status', 0, 16),
	#MetaData1
        BitField('ingress_port', 0, 16),
        BitField('egress_port', 0, 16),
	#MetaData3
        BitField('queue_id', 0, 8),
        BitField('queue_occupancy', 0, 24),
	#MetaData4
        #BitField('pad', 0, 16),
        BitField('ingress_timestamp', 0, 64),#48),
	#MetaData5
        #BitField('pad', 0, 16),
        BitField('egress_timestamp', 0, 64),#48),
    ]


#What needs to be bind? Is there a special Etype or DestPort for Intels Dtel??
#bind_layers(Ether, DTEL, {'type': 0x894F}, type=0x894F)



