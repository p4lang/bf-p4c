

import socket
import crcmod
from scapy.all import *

GTPmessageType = {
    1: "echo_request",
    2: "echo_response",
    16: "create_pdp_context_req",
    17: "create_pdp_context_res",
    18: "update_pdp_context_req",
    19: "update_pdp_context_resp",
    20: "delete_pdp_context_req",
    21: "delete_pdp_context_res",
    26: "error_indication",
    27: "pdu_notification_req",
    31: "supported_extension_headers_notification",
    254: "end_marker",
    255: "g_pdu"}

GTPmessageType = {1: "echo_request",
                  2: "echo_response",
                  16: "create_pdp_context_req",
                  17: "create_pdp_context_res",
                  18: "update_pdp_context_req",
                  19: "update_pdp_context_resp",
                  20: "delete_pdp_context_req",
                  21: "delete_pdp_context_res",
                  26: "error_indication",
                  27: "pdu_notification_req",
                  31: "supported_extension_headers_notification",
                  254: "end_marker",
                  255: "g_pdu"}

class GTPHeader(Packet):
    name = "GTP Header"
    fields_desc = [BitField("version", 1, 3),
                 BitField("PT", 1, 1),
                 BitField("reserved", 0, 1),
                 BitField("E", 0, 1),
                 BitField("S", 0, 1),
                 BitField("PN", 0, 1),
                 ByteEnumField("gtp_type", None, GTPmessageType),
                 ShortField("length", None),
                 IntField("teid", 0), 
                 IntField("seqnu", 0)]  


class MPLS(Packet):
    name = "MPLS"
    fields_desc = [BitField("label", 0, 20),
                   BitField("cos", 0, 3),
                   BitField("s", 1, 1),
                   ByteField("ttl", 0)]

    def guess_payload_class(self, payload):
        if len(payload) >= 1:
            if not self.s:
                return MPLS
            ip_version = (orb(payload[0]) >> 4) & 0xF
            if ip_version == 4:
                return IP
            elif ip_version == 5:
                return BIER
            elif ip_version == 6:
                return IPv6
            else:
                return Ether
        return Padding

bind_layers(Ether,  MPLS, type=0x8847)
bind_layers(Dot1Q,  MPLS, type=0x8847)
bind_layers(Dot1AD, MPLS, type=0x8847)
bind_layers(MPLS, MPLS, s=0)
bind_layers(IP, GRE, proto=47)
#bind_layers(MPLS, IP,   label=0x08000)  # 0x0800 << 4
#bind_layers(MPLS, IPv6, label=0x86DD0)  # 0x86DD << 4

class TCPTimestamp(Packet):
    name = "TCPTimestamp"
    fields_desc = [ XShortField("Noop", 257),
                    XShortField("Kind", 2058),
                    XIntField("Timestamp",0),
                    XIntField("Echo", 0)
                  ]
class UDPTimestamp(Packet):
    name = "UDPTimestamp"
    fields_desc = [ XIntField("Timestamp",0)]

class L23Payload(Packet):
    name = "L23Payload"
    fields_desc = [ XIntField("Signature",0),
                    XByteField("sig_bot",0),
                    XByteField("engine_id", 0),
                    XIntField("RxTSTMP", 0),
                    XIntField("PGID", 0),
                    XIntField("TSTMP", 0)
                  ]

""" Front Panel traffic, no overheads """
def fp_pkt(s_mac, d_mac, o_vlan, i_vlan, s_ip, d_ip, s_port, d_port, load, mpls, l4type, timestamp_ins, timestamp=0):
    # L2: eth + (vlan/qinq)
    p = Ether(dst=d_mac, src=s_mac)
    if o_vlan:
        p /= Dot1Q(vlan=o_vlan)
    if i_vlan:
        p /= Dot1AD(vlan=i_vlan)
    # L2.5: mpls
    if mpls:
        p /= MPLS(label=mpls)
    # L3: ip4/ip6
    try:
        socket.inet_aton(s_ip)
        p /= IP(src=s_ip, dst=d_ip)
    except:
        p /= IPv6(src=s_ip, dst=d_ip)
    # L4
    pyld = RandString(size=1)._fix()
    if l4type=='tcp':
        if load:
            if timestamp_ins:
                p /= TCP(sport=s_port,dport=d_port, dataofs=8)/TCPTimestamp(Timestamp = timestamp)/Raw(load=load)
            else:
                p /= TCP(sport=s_port,dport=d_port)/Raw(load=load)
        else:
            p /=TCP(sport=s_port,dport=d_port)/Raw(load=pyld)
    elif l4type=='udp':
        if load:
            if timestamp_ins:
                p /= UDP(sport=s_port,dport=d_port)/UDPTimestamp(Timestamp = timestamp)/Raw(load=load)
            else:
                p /= UDP(sport=s_port,dport=d_port)/Raw(load=load)
        else:
            p /= UDP(sport=s_port,dport=d_port)/Raw(load=pyld)
    # assemble!
    return p

""" NP outbound traffic """
def np_ob_pkt(s_mac, d_mac, o_vlan, i_vlan, s_ip, d_ip, s_port, d_port, load, mpls, fp_port, l4type, timestamp_ins, inner_header):
    # L2: eth + (vlan/qinq)
    p = Ether(dst=d_mac, src=s_mac)
    no_vlan = True
    if o_vlan:
        p /= Dot1Q(vlan=o_vlan, prio=fp_port)
        no_vlan = False
        if i_vlan:
            p /= Dot1AD(vlan=i_vlan)
    if no_vlan:
        p /= Dot1Q(vlan=4095, prio=fp_port)
    # L2.5: mpls
    if mpls:
        p /= MPLS(label=mpls)
    # L3: ip4/ip6
    try:
        socket.inet_aton(s_ip)
        p /= IP(src=s_ip, dst=d_ip)
    except:
        p /= IPv6(src=s_ip, dst=d_ip)
    # L4
    if l4type:
        if l4type =='tcp':
            if timestamp_ins:
                p /= TCP(sport=s_port,dport=d_port, dataofs=8)/TCPTimestamp()/Raw(load=load)
            else:
                p /= TCP(sport=s_port,dport=d_port)/Raw(load=load)
        #elif l4type =='udp':
        #    if timestamp_ins:
        #        p /= UDP(sport=s_port,dport=d_port)/UDPTimestamp()/Raw(load=load)
        #    else:
        #       p /= UDP(sport=s_port,dport=d_port)/Raw(load=load)
        elif l4type =='gre':
            p /= inner_header/Raw(load=load)
        elif l4type == 'gtp':
            p /= UDP(sport=2152,dport=2152)/inner_header/Raw(load=load)
        elif l4type == 'udp':
            p /= UDP(sport=s_port,dport=d_port)/Raw(load=load)
    else:
        p /= Raw(load=load)
    # assemble!
    return p

# def insert_ob_pkt(s_mac, d_mac, o_vlan, i_vlan, s_ip, d_ip, s_port, d_port, load, mpls, fp_port, l4type, timestamp_ins):
#     # L2: eth + (vlan/qinq)
#     p = Ether(dst=d_mac, src=s_mac)
#     if o_vlan:
#         p /= Dot1Q(vlan=o_vlan)
#     if i_vlan:
#         p /= Dot1AD(vlan=i_vlan)
#     # Outbound overhead stack 2 labels, insert ethtype + port
#     # timestamp offset and checksum flags here
#     # ethtype + port
#     if mpls:
#         p /= MPLS(ttl=fp_port, cos=timestamp_ins, label=0x88470)
#     else:
#         try:
#             socket.inet_aton(s_ip)
#             p /= MPLS(ttl=fp_port, cos=timestamp_ins, label=0x08000)
#         except:
#             p /= MPLS(ttl=fp_port, cos=timestamp_ins, label=0x86DD0)
#     p /= MPLS()
#     # L2.5: mpls
#     if mpls:
#         p /= MPLS(label=mpls)
#     # L3: ip4/ip6
#     try:
#         socket.inet_aton(s_ip)
#         p /= IP(src=s_ip, dst=d_ip)
#     except:
#         p /= IPv6(src=s_ip, dst=d_ip)
#     # L4
#     if l4type=='tcp':
#         if timestamp_ins:
#             p /= TCP(sport=s_port,dport=d_port, dataofs=8)/TCPTimestamp()/Raw(load=load)
#         else:
#             p /= TCP(sport=s_port,dport=d_port)/Raw(load=load)
#     elif l4type=='udp':
#         if timestamp_ins:
#             p /= UDP(sport=s_port,dport=d_port)/UDPTimestamp()/Raw(load=load)
#         else:
#             p /= UDP(sport=s_port,dport=d_port)/Raw(load=load)
#     # assemble!
#     return p

""" Calculate the crc32 hash and offset+modulo into target vlan """
def calc_vlan(s_ip, d_ip, s_port, d_port, q_offset, q_max):
    src = [0,0,0,0]
    dst = [0,0,0,0]
    # IPv4
    try:
        print ("{} {} {} {}".format(s_ip, d_ip, type(s_ip), type(d_ip)))
        # for some reason, it occasionally turns up as <class 'scapy.base_classes.Net'>
        # make sure to cast it back to string
        if not(isinstance(s_ip, str)):
            s_ip = str(s_ip)
        if not(isinstance(d_ip, str)):
            d_ip = str(d_ip)  
        src[0] = struct.unpack("!I", socket.inet_aton(s_ip))[0]
        dst[0] = struct.unpack("!I", socket.inet_aton(d_ip))[0]
    except:
    # IPv6
        ip6 = socket.inet_pton(socket.AF_INET6, s_ip)
        src[3], src[2], src[1], src[0] = struct.unpack(">IIII", ip6)
        ip6 = socket.inet_pton(socket.AF_INET6, d_ip)
        dst[3], dst[2], dst[1], dst[0] = struct.unpack(">IIII", ip6)
        
    src[0] = src[0] & 0x7fffffff
    dst[0] = dst[0] & 0x7fffffff
    s_port = s_port & 0x7fff
    d_port = d_port & 0x7fff
    print(hex(src[0]), hex(dst[0]))
    #crc32_func = crcmod.mkCrcFun(0x104c11db7, initCrc=0, xorOut=0x00000000)
    crc32_func = crcmod.mkCrcFun(0x11edc6f41, initCrc=0, xorOut=0x00000000)
    if int(src[0]) > int(dst[0]) or (src[0] == dst[0] and s_port > d_port):
        print("{} {} {} {} {} {} {} {}".format(hex(src[3]), hex(src[2]), hex(src[1]), hex(src[0]), \
                                           hex(dst[3]), hex(dst[2]), hex(dst[1]), hex(dst[0]) ))
        tuples = struct.pack('>IIIIIIIIHH', src[3], dst[3], src[2], dst[2], src[1], dst[1], src[0], dst[0], int(s_port), int(d_port))
        tuplev4 = struct.pack('>IIHH', src[0], dst[0], int(s_port), int(d_port))
    else:
        print("!!!!    SWAP    !!!!")
        print("{} {} {} {} {} {} {} {}".format(hex(dst[3]), hex(dst[2]), hex(dst[1]), hex(dst[0]), \
                                                hex(src[3]), hex(src[2]), hex(src[1]), hex(src[0]) ))
        tuples = struct.pack('>IIIIIIIIHH', dst[3], src[3], dst[2], src[2], dst[1], src[1], dst[0], src[0], int(d_port), int(s_port))
        tuplev4 = struct.pack('>IIHH', dst[0], src[0], int(d_port), int(s_port))
    #print (':'.join(x.encode('hex') for x in tuples))
    print ('{} CRC {} v4 crc:{} {}'.format(hex(q_offset), hex(crc32_func(tuples)), hex(crc32_func(tuplev4)), hex(q_max)))
    crchash = (crc32_func(tuples) & 0xff) 
    mod = crchash % q_max
    final = q_offset + mod
    print('Result after MOD: {} {} offset = {}, final {}'.format(hex(crchash), hex(mod), hex(q_offset), hex(final) ))
    return final

""" NP inbound traffic, inbound overhead (VLAN) inserted """
def np_ib_pk_with_pkt(pkt, fp_port, q_offset, q_max, verify_hash=True, hashValue=255):
    if verify_hash:
        try:
            s_ip = pkt[IP].src
            d_ip = pkt[IP].dst
        except:
            s_ip = pkt[IPv6].src
            d_ip = pkt[IPv6].dst
        try:
            s_port = pkt[TCP].sport
            d_port = pkt[TCP].dport
        except:
            s_port = pkt[UDP].sport
            d_port = pkt[UDP].dport 
        crc32_hash = (calc_vlan(s_ip, d_ip, s_port, d_port, q_offset, q_max)) & 0x7f
    else:
        crc32_hash = hashValue
    print("Final CRC hash = {}".format(hex(crc32_hash)))
    overhead_vlan = crc32_hash
    payload = pkt.getlayer(0).payload
    pkt.getlayer(0).remove_payload()
    pkt[Ether].type = 0x8100
    p = pkt/Dot1Q(vlan=overhead_vlan, prio=(fp_port&0x7))/payload
    return p

def np_ib_pkt(s_mac, d_mac, o_vlan, i_vlan, s_ip, d_ip, s_port, d_port, load, mpls, fp_port, l4type, q_offset, q_max):
    crc32_hash = (calc_vlan(s_ip, d_ip, s_port, d_port, q_offset, q_max)) & 0x7f
    overhead_vlan =  crc32_hash
    print("Final CRC hash = {} overheadvlan {}".format(hex(crc32_hash), hex(overhead_vlan)))
    # L2: eth + (vlan/qinq)
    p = Ether(dst=d_mac, src=s_mac)
    # inserted vlan for queue routing
    p /= Dot1Q(vlan=overhead_vlan, prio=(fp_port&0x7))
    if o_vlan:
        p /= Dot1Q(vlan=o_vlan)
    if i_vlan:
        p /= Dot1AD(vlan=i_vlan)
   
    # L2.5: mpls
    if mpls:
        p /= MPLS(label=mpls)
    # L3: ip4/ip6
    try:
        socket.inet_aton(s_ip)
        p /= IP(src=s_ip, dst=d_ip)
    except:
        p /= IPv6(src=s_ip, dst=d_ip)
    # L4
    if l4type=='tcp':
        p /= TCP(sport=s_port,dport=d_port)/Raw(load=load)
    elif l4type=='udp':
        p /= UDP(sport=s_port,dport=d_port)/Raw(load=load)
    # assemble!
    return p

#
# Helper functions for Tofino. We could've put them into a separate file, but
# that would complicate shipping. If their number grows, we'll do something
#
def to_devport(pipe, port):
    """
    Convert a (pipe, port) combination into a 9-bit (devport) number
    NOTE: For now this is a Tofino-specific method
    """
    return pipe << 7 | port

def to_pipeport(dp):
    """
    Convert a physical 9-bit (devport) number into (pipe, port) pair
    NOTE: For now this is a Tofino-specific method
    """
    return (dp >> 7, dp & 0x7F)

def devport_to_mcport(dp):
    """
    Convert a physical 9-bit (devport) number to the index that is used by 
    MC APIs (for bitmaps mostly)
    NOTE: For now this is a Tofino-specific method
    """
    (pipe, port) = to_pipeport(dp)
    return pipe * 72 + port

def mcport_to_devport(mcport):
    """
    Convert a MC port index (mcport) to devport
    NOTE: For now this is a Tofino-specific method
    """
    return to_devport(mcport / 72, mcport % 72)

def devports_to_mcbitmap(devport_list):
    """
    Convert a list of devports into a Tofino-specific MC bitmap
    """
    bit_map = [0] * ((288 + 7) / 8)
    for dp in devport_list:
        mc_port = devport_to_mcport(dp)
        bit_map[mc_port / 8] |= (1 << (mc_port % 8))
    return bytes_to_string(bit_map)

def mcbitmap_to_devports(mc_bitmap):
    """
    Convert a MC bitmap of mcports to a list of devports
    """
    bit_map = string_to_bytes(mc_bitmap)
    devport_list = []
    for i in range(0, len(bit_map)):
        for j in range(0, 8):
            if bit_map[i] & (1 << j) != 0:
                devport_list.append(mcport_to_devport(i * 8 + j))
    return devport_list

def lags_to_mcbitmap(lag_list):
    """
    Convert a list of LAG indices to a MC bitmap
    """
    bit_map = [0] * ((256 + 7) / 8)
    for lag in lag_list:
        bit_map[lag / 8] |= (1 << (lag % 8))
    return bytes_to_string(bit_map)
    
def mcbitmap_to_lags(mc_bitmap):
    """
    Convert an MC bitmap into a list of LAG indices
    """
    bit_map = string_to_bytes(mc_bitmap)
    lag_list = []
    for i in range(0, len(bit_map)):
        for j in range(0, 8):
            if bit_map[i] & (1 << j) != 0:
                devport_list.append(i * 8 + j)
    return lag_list

