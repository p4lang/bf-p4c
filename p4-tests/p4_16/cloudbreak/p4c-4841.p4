/*
    Simple program to track unsupported feature associated to partial header extractions
    as described in p4c-3513.  Described in p4c-4841.
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

struct headers {
    ethernet_t ethernet;
    ipv4_t ipv4;
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
        extract_greedy<metadata1_t>(packet, meta.m1);

        // hdr.ipv4.protocol is extracted using packet.extract() while meta.m1.v0 is
        // extracted using extract_greedy().  Mixing the two types of pkt_hdr_err_proc
        // flags in a select() statement is not supported yet.
        transition select(hdr.ipv4.protocol, meta.m1.v0) {
            (0x800, 0x64646464) : parse_m2;              // 'dddd'
            (0x800, 0x65656565) : parse_m3;              // 'eeee'
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
    apply {
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


