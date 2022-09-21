/*
    Simple program for functions extract_greedy() and lookahead_greedy()
    in the egress parser.

*/


#include <core.p4>
#if __TARGET_TOFINO__ == 3
#include <t3na.p4>
#else
#error Invalid target
#endif


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

struct headers {
    ethernet_t ethernet;
    ipv4_t ipv4;
    ipv6_t ipv6;
    ipv4_t ipv4_inner;
}

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
    bit<24> m3_lookahead;
    metadata1_t m1;
    metadata1_t m2;
    metadata1_t m3;
}

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
            0x64646464 : parse_m2;              // 'dddd'
            0x65656565 : parse_m3;              // 'eeee'
            default: accept;
        }
    }

    state parse_m2 {
        packet.extract(meta.m2);
        transition accept;
    }

    state parse_m3 {
        packet.extract(meta.m3);
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

    action action_m1_long_extract() {
        hdr.ethernet.dstAddr[7:0] = 0x33;
    }
    action action_m1_short_extract() {
        hdr.ethernet.dstAddr[7:0] = 0x22;
    }
    action action_m1_no_extract() {
        hdr.ethernet.dstAddr[7:0] = 0x11;
    }
    action drop() {
        ig_dprsr_md.drop_ctl = 1;
    }

    table check_meta1 {
        key = {
            meta.m1.v0: exact;
            meta.m1.v9: exact;
        }
        actions = {
            action_m1_long_extract;
            action_m1_short_extract;
            action_m1_no_extract;
            NoAction;
        }
        const entries = {
            (0x64646464, 0x64646464): action_m1_long_extract();     // 'dddd'...'dddd'
            (0x64646464, 0x00000000): action_m1_short_extract();    // 'dddd'... incomplete
            (0x65656565, 0x65656565): action_m1_long_extract();     // 'eeee'...'eeee'
            (0x65656565, 0x00000000): action_m1_short_extract();    // 'eeee'... incomplete
            (0x00000000, 0x00000000): action_m1_no_extract();       //  not received
        }
        const default_action = NoAction;
    }

    action action_m2_long_extract() {
        hdr.ethernet.dstAddr[15:8] = 0x33;
    }
    action action_m2_no_extract() {
        hdr.ethernet.dstAddr[15:8] = 0x11;
    }

    table check_meta2 {
        key = {
            meta.m2.v0: exact;
            meta.m2.v9: exact;
        }
        actions = {
            action_m2_long_extract;
            action_m2_no_extract;
        }
        const entries = {
            (0x44444444, 0x44444444): action_m2_long_extract();     // 'DDDD'...'DDDD'
            (0x00000000, 0x00000000): action_m2_no_extract();       //  not received or incomplete
        }
        const default_action = action_m2_no_extract();
    }

    action action_m3_long_extract() {
        hdr.ethernet.dstAddr[23:16] = 0x33;
    }
    action action_m3_short_extract() {
        hdr.ethernet.dstAddr[23:16] = 0x22;
    }
    action action_m3_no_extract() {
        hdr.ethernet.dstAddr[23:16] = 0x11;
    }

    table check_meta3 {
        key = {
            meta.m3.v0: exact;
            meta.m3.v9: exact;
        }
        actions = {
            action_m3_long_extract;
            action_m3_short_extract;
            action_m3_no_extract;
        }
        const entries = {
            (0x45454545, 0x45454545): action_m3_long_extract();     // 'EEEE'...'EEEE'
        }
        const default_action = action_m3_no_extract();
    }

    action action_m3_lookahead() {
        hdr.ethernet.dstAddr[23:16] = 0x44;
    }

    table check_meta3_lookahead {
        key = {
            meta.m3_lookahead: exact;
        }
        actions = {
            action_m3_lookahead;
            NoAction;
        }
        const entries = {
            0x24242400: action_m3_lookahead();
            0x24240000: action_m3_lookahead();
            0x00000000: action_m3_lookahead();
        }
        const default_action = NoAction;
    }

    apply {
        ig_tm_md.ucast_egress_port = ig_intr_md.ingress_port;
        check_ipv4.apply();
        check_meta1.apply();
        check_meta2.apply();
        check_meta3.apply();
        check_meta3_lookahead.apply();
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

    // Parsing of 'm1', the first metadata1_t field.  First 32-bit specifies
    // whether the next metadata1_t field is 'm2' or 'm3'.
    //
    state parse_m1 {
        // Extract as much of the first metadata1_t field following the IPv4
        // header as possible.  Do this while suppressing the PacketTooShort error.
        // Here, we expect to see either 'dddd' or 'eeee' in the first 4 bytes.
        //
        // Table check_meta1 below will hit on whether 'm1' was received partly or not.
        //
        extract_greedy<metadata1_t>(packet, meta.m1);
        transition select(meta.m1.v0) {
            0x64646464 : parse_m2;              // 'dddd'
            0x65656565 : parse_m3;              // 'eeee'
            default: accept;
        }
    }

    state parse_m2 {
        // Extract the second metadata1_t field, 'm2'.  Do not try to extract any
        // bytes if it is incomplete, but suppress the PacketTooShort error.
        //
        // Table check_meta2 below will hit depending on whether 'm2' was received
        // entirely or not.
        //
        extract_greedy(packet, meta.m2);
        transition accept;
    }

    state parse_m3 {
        // Extract the second metadata1_t field, 'm3'.  Expect 'm3' to be received entirely.
        //
        // Note: If only part of 'm3' is received, the packet will be dropped
        //       since the packet.extract() primitive is used.
        //
        packet.extract(meta.m3);
        // extract_greedy(packet, meta.m3);

        // Function lookahead_greedy() can be used in cases where we need to deal with
        // incomplete packets which last byte falls in the lookahead section.
        //
        meta.m3_lookahead = lookahead_greedy<bit<24>>(packet);
        transition accept;
    }
}

control egress(inout headers hdr, inout metadata meta, in egress_intrinsic_metadata_t eg_intr_md,
               in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr,
               inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprs,
               inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport) {
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

    action action_m1_long_extract() {
        hdr.ethernet.dstAddr[7:0] = 0x33;
    }
    action action_m1_short_extract() {
        hdr.ethernet.dstAddr[7:0] = 0x22;
    }
    action action_m1_no_extract() {
        hdr.ethernet.dstAddr[7:0] = 0x11;
    }
    action drop() {
        eg_intr_md_for_dprs.drop_ctl = 1;
    }

    table check_meta1 {
        key = {
            meta.m1.v0: exact;
            meta.m1.v9: exact;
        }
        actions = {
            action_m1_long_extract;
            action_m1_short_extract;
            action_m1_no_extract;
            NoAction;
        }
        const entries = {
            (0x64646464, 0x64646464): action_m1_long_extract();     // 'dddd'...'dddd'
            (0x64646464, 0x00000000): action_m1_short_extract();    // 'dddd'... incomplete
            (0x65656565, 0x65656565): action_m1_long_extract();     // 'eeee'...'eeee'
            (0x65656565, 0x00000000): action_m1_short_extract();    // 'eeee'... incomplete
            (0x00000000, 0x00000000): action_m1_no_extract();       //  not received
        }
        const default_action = NoAction;
    }

    action action_m2_long_extract() {
        hdr.ethernet.dstAddr[15:8] = 0x33;
    }
    action action_m2_no_extract() {
        hdr.ethernet.dstAddr[15:8] = 0x11;
    }

    table check_meta2 {
        key = {
            meta.m2.v0: exact;
            meta.m2.v9: exact;
        }
        actions = {
            action_m2_long_extract;
            action_m2_no_extract;
        }
        const entries = {
            (0x44444444, 0x44444444): action_m2_long_extract();     // 'DDDD'...'DDDD'
            (0x00000000, 0x00000000): action_m2_no_extract();       //  not received or incomplete
        }
        const default_action = action_m2_no_extract();
    }

    action action_m3_long_extract() {
        hdr.ethernet.dstAddr[23:16] = 0x33;
    }
    action action_m3_short_extract() {
        hdr.ethernet.dstAddr[23:16] = 0x22;
    }
    action action_m3_no_extract() {
        hdr.ethernet.dstAddr[23:16] = 0x11;
    }

    table check_meta3 {
        key = {
            meta.m3.v0: exact;
            meta.m3.v9: exact;
        }
        actions = {
            action_m3_long_extract;
            action_m3_short_extract;
            action_m3_no_extract;
        }
        const entries = {
            (0x45454545, 0x45454545): action_m3_long_extract();     // 'EEEE'...'EEEE'
        }
        const default_action = action_m3_no_extract();
    }

    action action_m3_lookahead() {
        hdr.ethernet.dstAddr[23:16] = 0x44;
    }

    table check_meta3_lookahead {
        key = {
            meta.m3_lookahead: exact;
        }
        actions = {
            action_m3_lookahead;
            NoAction;
        }
        const entries = {
            0x24242400: action_m3_lookahead();
            0x24240000: action_m3_lookahead();
            0x00000000: action_m3_lookahead();
        }
        const default_action = NoAction;
    }

    apply {
        check_ipv4.apply();
        check_meta1.apply();
        check_meta2.apply();
        check_meta3.apply();
        check_meta3_lookahead.apply();
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


