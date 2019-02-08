// This is a negative test to make sure there is a sensible error message
// if a user tries to perform 128-bit arithmetic.
#include <core.p4>
#include <tna.p4>
#include "util.h"

#define ETHERTYPE_IPV4 0x0800
#define ETHERTYPE_IPV6 0x86dd
#define IP_PROTOCOLS_TCP 6
#define IP_PROTOCOLS_UDP 17


struct headers_t {
    ethernet_h ethernet;
    ipv4_h ipv4;
    ipv6_h ipv6;
}

struct metadata_t {
    //bit<16> md;
}

parser SwitchIngressParser(
    packet_in pkt,
    out headers_t hdr,
    out metadata_t ig_md,
    out ingress_intrinsic_metadata_t ig_intr_md) {

    TofinoIngressParser() tofino_parser;

    state start {
        tofino_parser.apply(pkt, ig_intr_md);
        transition parse_ethernet;
    }

    state parse_ethernet {
        pkt.extract(hdr.ethernet);
        transition select(hdr.ethernet.ether_type) {
            ETHERTYPE_IPV4 : parse_ipv4;
            ETHERTYPE_IPV6 : parse_ipv6;
            default : reject;
        }
    }

    state parse_ipv4 {
        pkt.extract(hdr.ipv4);
        transition accept;
    }

    state parse_ipv6 {
        pkt.extract(hdr.ipv6);
        transition accept;
    }
}


control SwitchIngress(
        inout headers_t hdr,
        inout metadata_t ig_md,
        in ingress_intrinsic_metadata_t ig_intr_md,
        in ingress_intrinsic_metadata_from_parser_t ig_intr_prsr_md,
        inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprsr_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {

        action miss_() {}

        action invalid_wide_add() {
            hdr.ipv6.dst_addr = hdr.ipv6.dst_addr + hdr.ipv6.src_addr;
        }

        action set_port(bit<9> p) {
            ig_intr_tm_md.ucast_egress_port = p;
        }

        table t0 {
    	    key = {
    	       hdr.ipv4.isValid() : exact;
             hdr.ipv6.isValid() : exact;
             hdr.ethernet.dst_addr : exact;
    	    }
    	    actions = {
             invalid_wide_add;
             miss_;
          }
          const default_action = miss_();
          size = 4096;
        }

        table t1 {
            key = {
                hdr.ethernet.isValid() : exact;
            }
            actions = {
                set_port;
                miss_;
            }
            const default_action = miss_();
            size = 2;
        }

        apply {
            t0.apply();
            t1.apply();
        }
}


control SwitchIngressDeparser(packet_out pkt,
                              inout headers_t hdr,
                              in metadata_t ig_md,
                              in ingress_intrinsic_metadata_for_deparser_t ig_intr_dprsr_md) {
    apply {
        pkt.emit(hdr);
    }
}

parser SwitchEgressParser(
        packet_in pkt,
        out headers_t hdr,
        out metadata_t eg_md,
        out egress_intrinsic_metadata_t eg_intr_md) {

    TofinoEgressParser() tofino_parser;

    state start {
        tofino_parser.apply(pkt, eg_intr_md);
        transition accept;
    }
}

Pipeline(SwitchIngressParser(),
       SwitchIngress(),
       SwitchIngressDeparser(),
       SwitchEgressParser(),
       EmptyEgress(),
       EmptyEgressDeparser()) pipe0;
Switch(pipe0) main;
