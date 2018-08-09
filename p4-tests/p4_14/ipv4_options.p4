 /* -*- P4_14 -*- */

#ifdef __TARGET_TOFINO__
#include <tofino/constants.p4>
#include <tofino/intrinsic_metadata.p4>
#include <tofino/primitives.p4>
#else
#error This program is intended to compile for Tofino P4 architecture only
#endif

/*************************************************************************
 ***********************  H E A D E R S  *********************************
 *************************************************************************/
header_type ether_t {
    fields {
        mac_da   : 48;
        mac_sa   : 48;
    }
}

header_type vlan_tag_t {
    fields {
        tpid : 16;
        pri  : 3;
        cfi  : 1;
        vid  : 12;
    }
}

header_type llc_t {
    fields {
        len  : 16;
        dsap : 8;
        ssap : 8;
    }
}

header_type snap_t {
    fields {
        ctrl: 8;
        oui : 24;
    }
}

header_type etherII_t {
    fields {
        etype : 16;
    }
}

header_type mpls_t {
    fields {
        label : 20;
        exp : 3;
        bos : 1;
        ttl : 8;
    }
}
    
header_type ipv4_t {
    fields {
        version : 4;
        ihl : 4;
        diffserv : 8;
        totalLen : 16;
        identification : 16;
        flags : 3;
        fragOffset : 13;
        ttl : 8;
        protocol : 8;
        hdrChecksum : 16;
        srcAddr : 32;
        dstAddr: 32;
    }
}

header_type ipv6_t {
    fields {
        version : 4;
        trafficClass : 8;
        flowLabel : 20;
        payloadLen : 16;
        nextHdr : 8;
        hopLimit : 8;
        srcAddr : 128;
        dstAddr : 128;
    }
}

header_type icmp_t {
    fields {
        typeCode : 16;
        hdrChecksum : 16;
    }
}

header_type tcp_t {
    fields {
        srcPort : 16;
        dstPort : 16;
        seqNo : 32;
        ackNo : 32;
        dataOffset : 4;
        res : 4;
        flags : 8;
        window : 16;
        checksum : 16;
        urgentPtr : 16;
    }
}

header_type udp_t {
    fields {
        srcPort : 16;
        dstPort : 16;
        length_ : 16;
        checksum : 16;
    }
}

#define IPV4_OPTIONS_HEADER_T(bytes, bits)               \
header_type ipv4_options_##bytes##b_t {                 \
    fields { options : bits; }                           \
}

IPV4_OPTIONS_HEADER_T( 4,  32)
IPV4_OPTIONS_HEADER_T( 8,  64)
IPV4_OPTIONS_HEADER_T(12,  96)
IPV4_OPTIONS_HEADER_T(16, 128)
IPV4_OPTIONS_HEADER_T(20, 160)
IPV4_OPTIONS_HEADER_T(24, 192)
IPV4_OPTIONS_HEADER_T(28, 224)
IPV4_OPTIONS_HEADER_T(32, 256)
IPV4_OPTIONS_HEADER_T(36, 288)
IPV4_OPTIONS_HEADER_T(40, 320)

header_type arp_t {
    fields {
        hwType : 16;
        protoType : 16;
        hwAddrLen : 8;
        protoAddrLen : 8;
        opcode : 16;
    }
}

header_type arp_ipv4_t {
    fields {
        srcHwAddr : 48;
        srcProtoAddr : 32;
        dstHwAddr : 48;
        dstProtoAddr : 32;
    }
}

/*************************************************************************
 ***********************  M E T A D A T A  *******************************
 *************************************************************************/

/*************************************************************************
 ***********************  P A R S E R  ***********************************
 *************************************************************************/
#define VLAN_DEPTH 2
#define MPLS_DEPTH 5
header ether_t    ether;
header vlan_tag_t vlan_tag[VLAN_DEPTH];
header llc_t      llc;
header snap_t     snap;
header etherII_t  etherII;
header mpls_t     mpls[MPLS_DEPTH];
header mpls_t     mpls_bos;

@pragma pa_fragment ingress ipv4.hdrChecksum
@pragma pa_fragment egress ipv4.hdrChecksum
header ipv4_t     ipv4;
header ipv6_t     ipv6;
header icmp_t     icmp;
header tcp_t      tcp;
header udp_t      udp;
header arp_t      arp;
header arp_ipv4_t arp_ipv4;

#define IPV4_OPTIONS_HEADER(bytes) \
header ipv4_options_##bytes##b_t ipv4_options_##bytes##b

IPV4_OPTIONS_HEADER( 4);
IPV4_OPTIONS_HEADER( 8);
IPV4_OPTIONS_HEADER(12);
IPV4_OPTIONS_HEADER(16);
IPV4_OPTIONS_HEADER(20);
IPV4_OPTIONS_HEADER(24);
IPV4_OPTIONS_HEADER(28);
IPV4_OPTIONS_HEADER(32);
IPV4_OPTIONS_HEADER(36);
IPV4_OPTIONS_HEADER(40);

#define IP_PROTO_ICMP 1
#define IP_PROTO_TCP  6
#define IP_PROTO_UDP 17

#define CHECK_ETHERTYPE current(0, 16)

parser start {
    return parse_ether;
}

parser parse_ether {
    extract(ether);
    return select(CHECK_ETHERTYPE) {
        0x0000 mask 0xFC00 : parse_llc;
        0x0400 mask 0xFE00 : parse_llc;
        0x8100 mask 0xFEFF : parse_vlan_tag;
        0x0800 : parse_ipv4;
        0x0806 : parse_arp;
        0x86DD : parse_ipv6;
        0x8847 : parse_mpls;
        default: parse_etherII;
    }
}

parser parse_vlan_tag {
    extract(vlan_tag[next]);
    return select(CHECK_ETHERTYPE) {
        0x0000 mask 0xFC00 : parse_llc;
        0x0400 mask 0xFE00 : parse_llc;
        0x8100 mask 0xFEFF : parse_vlan_tag;
        0x0800 : parse_ipv4;
        0x0806 : parse_arp;
        0x86DD : parse_ipv6;
        0x8847 : parse_mpls;
        default: parse_etherII;
    }
}

parser parse_llc {
    extract(llc);
    return select(llc.ssap, llc.dsap) {
        0xAAAA, 0xAAAB, 0xABAA, 0xABAB: parse_snap;
        default: ingress;
    }
}

parser parse_snap {
    extract(snap);
    return select(CHECK_ETHERTYPE) {
        0x0800 : parse_ipv4;
        0x0806 : parse_arp;
        0x86DD : parse_ipv6;
        default: parse_etherII;
    }
}

parser parse_etherII {
    extract(etherII);
    return ingress;
}

parser parse_mpls {
    return select(current(23,1)) {
        0: parse_mpls_non_bos;
        1: parse_mpls_bos;
    }
}

parser parse_mpls_non_bos {
    extract(mpls[next]);
    return parse_mpls;
}

parser parse_mpls_bos {
    extract(mpls_bos);
    return select(current(0,4)) {
        4 : parse_pure_ipv4;
        6 : parse_pure_ipv6;
        default : ingress;
    }
}

parser parse_ipv4 {
    extract(etherII);
    return parse_pure_ipv4;
}

parser parse_pure_ipv4 {
    extract(ipv4);
    return select(ipv4.fragOffset, ipv4.ihl, ipv4.protocol) {
        0x501       : parse_icmp;
        0x506       : parse_tcp;
        0x511       : parse_udp;
        0x0000500 mask 0xF00 : ingress;
        0x0000600 mask 0xF00 : parse_ipv4_options_4b;
        0x0000700 mask 0xF00 : parse_ipv4_options_8b;
        0x0000800 mask 0xF00 : parse_ipv4_options_12b;
        0x0000900 mask 0xF00 : parse_ipv4_options_16b;
        0x0000A00 mask 0xF00 : parse_ipv4_options_20b;
        0x0000B00 mask 0xF00 : parse_ipv4_options_24b;
        0x0000C00 mask 0xF00 : parse_ipv4_options_28b;
        0x0000D00 mask 0xF00 : parse_ipv4_options_32b;
        0x0000E00 mask 0xF00 : parse_ipv4_options_36b;
        0x0000F00 mask 0xF00 : parse_ipv4_options_40b;
        default     : ingress; /* Packets with bad ihl < 5 */
    }
}

#define IP_OPTIONS_PARSER(len)                      \
parser parse_ipv4_options_##len##b {                \
    extract(ipv4_options_##len##b);                 \
    return select(ipv4.fragOffset, ipv4.protocol) { \
        IP_PROTO_ICMP : parse_icmp;                 \
        IP_PROTO_TCP  : parse_tcp;                  \
        IP_PROTO_UDP  : parse_udp;                  \
        default       : ingress;                    \
    }                                               \
}

IP_OPTIONS_PARSER(4)
IP_OPTIONS_PARSER(8)
IP_OPTIONS_PARSER(12)
IP_OPTIONS_PARSER(16)
IP_OPTIONS_PARSER(20)
IP_OPTIONS_PARSER(24)
IP_OPTIONS_PARSER(28)
IP_OPTIONS_PARSER(32)
IP_OPTIONS_PARSER(36)
IP_OPTIONS_PARSER(40)

field_list ipv4_checksum_list {
    ipv4.version;
    ipv4.ihl;
    ipv4.diffserv;
    ipv4.totalLen;
    ipv4.identification;
    ipv4.flags;
    ipv4.fragOffset;
    ipv4.ttl;
    ipv4.protocol;
    ipv4.srcAddr;
    ipv4.dstAddr;
    ipv4_options_4b.options;
    ipv4_options_8b.options;
    ipv4_options_12b.options;
    ipv4_options_16b.options;
    ipv4_options_20b.options;
    ipv4_options_24b.options;
    ipv4_options_28b.options;
    ipv4_options_32b.options;
    ipv4_options_40b.options;
}

field_list_calculation ipv4_checksum {
    input {
        ipv4_checksum_list;
    }
    algorithm : csum16;
    output_width : 16;
}

calculated_field ipv4.hdrChecksum  {
    verify ipv4_checksum;
    update ipv4_checksum;
}

parser parse_ipv6 {
    extract(etherII);
    return parse_pure_ipv6;
}

parser parse_pure_ipv6 {
    extract(ipv6);
    return select(ipv6.nextHdr) {
        IP_PROTO_ICMP: parse_icmp;
        IP_PROTO_TCP : parse_tcp;
        IP_PROTO_UDP : parse_udp;
        default      : ingress;
    }
}

parser parse_arp {
    extract(etherII);
    extract(arp);
    return select(arp.hwType, arp.protoType) {
        0x00010800: parse_arp_ipv4;
              default : ingress;
    }
}

#define TERMINAL_PARSER(proto) \
parser parse_##proto { extract(proto); return ingress; }

TERMINAL_PARSER(icmp)
TERMINAL_PARSER(tcp)
TERMINAL_PARSER(udp)
TERMINAL_PARSER(arp_ipv4)


/*************************************************************************
 **************  I N G R E S S   P R O C E S S I N G   *******************
 *************************************************************************/
action show_parser_error() {
    modify_field(ether.mac_da, ig_intr_md_from_parser_aux.ingress_parser_err);
    modify_field(ig_intr_md_for_tm.ucast_egress_port, 0);
}

table show_parser_error {
    actions        { show_parser_error; }
    default_action : show_parser_error();
    size           : 1;
}

control ingress {
    apply(show_parser_error);
}

/*************************************************************************
 ****************  E G R E S S   P R O C E S S I N G   *******************
 *************************************************************************/
control egress {
}

