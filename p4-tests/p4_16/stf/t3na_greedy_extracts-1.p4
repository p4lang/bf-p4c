
#include <core.p4>
#if __TARGET_TOFINO__ == 3
#include <t3na.p4>
#else
#error Invalid target
#endif

// Usual headers.
//
typedef bit<48> macAddr_t;
typedef bit<32> ip4Addr_t;

header ethernet_t {
    macAddr_t dstAddr;
    macAddr_t srcAddr;
    bit<16>   etherType;
}

header ipv4_t {
    bit<4>    version;
    bit<4>    ihl;
    bit<8>    diffserv;
    bit<16>   totalLen;
    bit<16>   identification;
    bit<3>    flags;
    bit<13>   fragOffset;
    bit<8>    ttl;
    bit<8>    protocol;
    bit<16>   hdrChecksum;
    ip4Addr_t srcAddr;
    ip4Addr_t dstAddr;
}

header ipv6_t {
    bit<4>      version;
    bit<8>      trafficClass;
    bit<20>     flowLabel;
    bit<16>     payloadLen;
    bit<8>      nextHdr;
    bit<8>      hopLimit;
    bit<128>    srcAddr;
    bit<128>    dstAddr;
}

header udp_t {
    bit<16> srcPort;
    bit<16> dstPort;
    bit<16> length_;
    bit<16> checksum;
}

header tcp_t {
    bit<16> srcPort;
    bit<16> dstPort;
    bit<32> seqNo;
    bit<32> ackNo;
    bit<4>  dataOffset;
    bit<4>  res;
    bit<8>  flags;
    bit<16> window;
    bit<16> checksum;
    bit<16> urgentPtr;
}

struct headers {
    ethernet_t ethernet;
    ipv4_t ipv4;
    ipv6_t ipv6;
    udp_t  udp;
    tcp_t  tcp;
}

// Metadata that can be received
// in packets.
//
header metadata1_t {
    bit<32> v0;
    bit<32> v1;
    bit<32> v2;
    bit<32> v3;
    bit<32> v4;
    bit<32> v5;
    bit<32> v6;
    bit<32> v7;
    bit<32> v8;
    bit<32> v9;
}

struct metadata {
    metadata1_t m1;
    metadata1_t m2;
}

// Packets supported by this parser:
//      Ether/IPv4/m1/m2
//      Ether/IPv4/m1/m2_greedy
//
// Ether/IPv4/m1/m2:
// (scapy syntax)
//
//               |  14  | 20 |                            40                                       |                                40                                  |
//               |      |    |                            30                      v                |   v                                                                |
//         p_m2 = Ether()/IP()/'dddd'/'dddd'/'dddd'/'dddd'/'dddd'/'dddd'/'dddd'/'dddd'/'dddd'/'dddd'/'DDDD'/'DDDD'/'DDDD'/'DDDD'/'DDDD'/'DDDD'/'DDDD'/'DDDD'/'DDDD'/'DDDD'
//
// Ether/Ipv4/m1/m2_greedy:
//
//  p_m2_greedy = Ether()/IP()/'eeee'/'eeee'/'eeee'/'eeee'/'eeee'/'eeee'/'eeee'/'eeee'/'eeee'/'eeee'/'DDDD'/'DDDD'/'DDDD'/'DDDD'/'DDDD'/'DDDD'/'DDDD'/'DDDD'/'DDDD'/'DDDD'
//

parser ParserImpl(packet_in packet, out headers hdr,
                  out metadata meta,
                  out ingress_intrinsic_metadata_t ig_intr_md) {

    state start {
        packet.extract(ig_intr_md);
        packet.advance(PORT_METADATA_SIZE);
        transition parse_eth;
    }

    state parse_eth {
        packet.extract(hdr.ethernet);
        transition select(hdr.ethernet.etherType) {
            0x800: parse_ipv4;
            default: accept;
        }
    }

    state parse_ipv4 {
        packet.extract(hdr.ipv4);
        transition parse_m1;
    }

    state parse_m1 {
        packet.extract(meta.m1);
        transition select(meta.m1.v0) {
            0x64646464 : parse_m2;            // 'dddd'
            0x65656565 : parse_m2_greedy;     // 'eeee'
            default: accept;
        }
    }

    state parse_m2 {
        packet.extract(meta.m2);
        transition accept;
    }

    state parse_m2_greedy {
        extract_greedy<metadata1_t>(packet, meta.m2);
        transition accept;
    }
}

control ingress(
    inout headers hdr,
    inout metadata meta,
    in    ingress_intrinsic_metadata_t               ig_intr_md,
    in    ingress_intrinsic_metadata_from_parser_t   ig_prsr_md,
    inout ingress_intrinsic_metadata_for_deparser_t  ig_dprsr_md,
    inout ingress_intrinsic_metadata_for_tm_t        ig_tm_md)
{

    action drop() {
        ig_dprsr_md.drop_ctl = 1;
    }

    // action packet_too_short_err() {
    //     hdr.ethernet.dstAddr = 0xee00ff00ee00;
    //     hdr.ethernet.srcAddr = 0xff00ee00ff00;
    // }

    action fcs_err() {
        exit;
    }

    table check_parser_errs {
        key = {
            ig_prsr_md.parser_err: exact;
        }
        actions = {
            // packet_too_short_err;
            fcs_err;
            NoAction;
        }
        const entries = {
            // (PARSER_ERROR_PARTIAL_HDR): packet_too_short_err();
            (PARSER_ERROR_FCS) : fcs_err();
            (PARSER_ERROR_OK): NoAction();
        }
        const default_action = NoAction;
    }

    action ipv4_update() {
        hdr.ipv4.dstAddr = hdr.ipv4.srcAddr;
    }

    table check_ipv4 {
        key = {
            hdr.ipv4.dstAddr: exact;
            hdr.ipv4.srcAddr: exact;
        }
        actions = {
            ipv4_update;
            NoAction;
        }
    }

    action action_m1_set_extract_value(bit<8>value) {
        hdr.ethernet.dstAddr[7:0] = value;
    }
    action action_m1_default() {
        action_m1_set_extract_value(0xcc);
    }

    table check_meta1 {
        key = {
            meta.m1.v0: exact;
        }
        actions = {
            action_m1_set_extract_value;
            action_m1_default;
        }
        const entries = {
            0x64646464: action_m1_set_extract_value(0x64);    // 'dddd'
            0x65656565: action_m1_set_extract_value(0x65);    // 'eeee'
        }
        const default_action = action_m1_default;
    }

    action action_m2_set_extract_value(bit<8>value) {
        hdr.ethernet.dstAddr[15:8] = value;
    }
    action action_m2_default() {
        action_m2_set_extract_value(0x88);
    }

    table check_meta2 {
        key = {
            meta.m2.v0: exact;
            meta.m2.v1: exact;
            meta.m2.v2: exact;
            meta.m2.v3: exact;
        }
        actions = {
            action_m2_set_extract_value;
            action_m2_default;
        }
        const entries = {
            (0x44444444, 0x44444444, 0x44444444, 0x44444444): action_m2_set_extract_value(0x44);
            (0x44444444, 0x44444444, 0x44444444, 0x00000000): action_m2_set_extract_value(0x33);
            (0x44444444, 0x44444444, 0x00000000, 0x00000000): action_m2_set_extract_value(0x22);
            (0x44444444, 0x00000000, 0x00000000, 0x00000000): action_m2_set_extract_value(0x11);
            (0x00000000, 0x00000000, 0x00000000, 0x00000000): action_m2_set_extract_value(0x00);
        }
        const default_action = action_m2_default();
    }

    apply {
        ig_tm_md.ucast_egress_port = ig_intr_md.ingress_port;
        check_parser_errs.apply();
        check_ipv4.apply();
        check_meta1.apply();
        check_meta2.apply();
    }
}

control ingressDeparser(packet_out packet, inout headers hdr, in metadata meta,
                        in ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprs) {
    apply {
        packet.emit(hdr);
    }
}

parser egressParser(packet_in packet, out headers hdr, out metadata meta,
                    out egress_intrinsic_metadata_t eg_intr_md) {
    state start {
        packet.extract(eg_intr_md);
        transition accept;
    }
}

control egress(inout headers hdr, inout metadata meta, in egress_intrinsic_metadata_t eg_intr_md,
               in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr,
               inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprs,
               inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport) {
    apply {
    }
}

control egressDeparser(packet_out packet, inout headers hdr, in metadata meta,
                       in egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprs) {
    apply {
    }
}

Pipeline(ParserImpl(), ingress(), ingressDeparser(),
         egressParser(), egress(), egressDeparser()) pipe;

Switch(pipe) main;


