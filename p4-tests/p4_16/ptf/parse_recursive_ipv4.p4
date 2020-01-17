#include <core.p4>
#include <tna.p4>       /* TOFINO1_ONLY */

typedef bit<48> mac_addr_t;
typedef bit<32> ipv4_addr_t;

#define ETHERTYPE_IPV4 0x0800

#define IP_PROTOCOLS_IPV4 4
#define IP_PROTOCOLS_TCP  6
#define IP_PROTOCOLS_UDP 17

header ethernet_h {
    mac_addr_t dst_addr;
    mac_addr_t src_addr;
    bit<16> ether_type;
}

header ipv4_h {
    bit<4> version;
    bit<4> ihl;
    bit<8> diffserv;
    bit<16> total_len;
    bit<16> identification;
    bit<3> flags;
    bit<13> frag_offset;
    bit<8> ttl;
    bit<8> protocol;
    bit<16> hdr_checksum;
    ipv4_addr_t src_addr;
    ipv4_addr_t dst_addr;
}

header tcp_h {
    bit<16> src_port;
    bit<16> dst_port;
    bit<32> seq_no;
    bit<32> ack_no;
    bit<4> data_offset;
    bit<4> res;
    bit<8> flags;
    bit<16> window;
    bit<16> checksum;
    bit<16> urgent_ptr;
}

header udp_h {
    bit<16> src_port;
    bit<16> dst_port;
    bit<16> length;
    bit<16> checksum;
}

struct switch_ingress_metadata_t {
    ipv4_addr_t innermost_src_addr;
    ipv4_addr_t innermost_dst_addr;
    bit<8>      innermost_protocol;
    bit<16>     innermost_src_port;
    bit<16>     innermost_dst_port;

    bit<3> pad0;
    bit<13> innermost_hash;
}

struct switch_egress_metadata_t {
}

struct switch_header_t {
    ethernet_h ethernet;
    ipv4_h ipv4;
    tcp_h tcp;
    udp_h udp;
}


parser SwitchIngressParser(
    packet_in pkt,
    out switch_header_t hdr,
    out switch_ingress_metadata_t ig_md,
    out ingress_intrinsic_metadata_t ig_intr_md) {
    
    ipv4_h tmp_ipv4;

    state start {
        pkt.extract(ig_intr_md);
        transition parse_port_metadata;
    }
    
    state parse_port_metadata {
        pkt.advance(PORT_METADATA_SIZE);
        transition parse_ethernet;
    }

    state parse_ethernet {
        pkt.extract(hdr.ethernet);
        transition select(hdr.ethernet.ether_type) {
            ETHERTYPE_IPV4 : check_ipv4;
            default        : accept;
        }
    }

    state check_ipv4 {
        tmp_ipv4 = pkt.lookahead<ipv4_h>();
        transition select(tmp_ipv4.protocol) {
            IP_PROTOCOLS_IPV4 : skip_ipv4; // if this is IP in IP, recurse
            default           : parse_ipv4;
        }
    }

    state skip_ipv4 {
        pkt.advance(hdr.ipv4.minSizeInBits());
        transition check_ipv4;
    }

    state parse_ipv4 {
        pkt.extract(hdr.ipv4);

        // capture latest src/dst/protocol
        ig_md.innermost_src_addr = hdr.ipv4.src_addr;
        ig_md.innermost_dst_addr = hdr.ipv4.dst_addr;
        ig_md.innermost_protocol = hdr.ipv4.protocol;

        transition select(hdr.ipv4.protocol) {
            IP_PROTOCOLS_TCP  : parse_tcp;
            IP_PROTOCOLS_UDP  : parse_udp;
            default         : accept;
        }
    }

    state parse_tcp {
        pkt.extract(hdr.tcp);

        // capture latest src/dst port
        ig_md.innermost_src_port = hdr.tcp.src_port;
        ig_md.innermost_dst_port = hdr.tcp.dst_port;
        
        transition accept;
    }

    state parse_udp {
        pkt.extract(hdr.udp);

        // capture latest src/dst port
        ig_md.innermost_src_port = hdr.udp.src_port;
        ig_md.innermost_dst_port = hdr.udp.dst_port;
        
        transition accept;
    }
}


control SwitchIngressDeparser(
    packet_out pkt,
    inout switch_header_t hdr,
    in switch_ingress_metadata_t ig_md,
    in ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr) {
    apply {
        pkt.emit(hdr);
    }
}

parser SwitchEgressParser(
    packet_in pkt,
    out switch_header_t hdr,
    out switch_egress_metadata_t eg_md,
    out egress_intrinsic_metadata_t eg_intr_md) {

    state start {
        transition accept;
    }
}

control SwitchEgressDeparser(
    packet_out pkt,
    inout switch_header_t hdr,
    in switch_egress_metadata_t eg_md,
    in egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr) {
    apply {
        pkt.emit(hdr);
    }
}

control SwitchIngress(
    inout switch_header_t hdr,
    inout switch_ingress_metadata_t ig_md,
    in ingress_intrinsic_metadata_t ig_intr_md,
    in ingress_intrinsic_metadata_from_parser_t ig_intr_from_prsr,
    inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr,
    inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm) {
    
    apply {
        if (hdr.tcp.isValid() || hdr.udp.isValid()) {
            // send out port 0
            ig_intr_md_for_tm.ucast_egress_port = 0;
            ig_intr_md_for_tm.bypass_egress = 1w1;
            ig_intr_md_for_dprsr.drop_ctl = 0;
        } else {
            // drop
            ig_intr_md_for_dprsr.drop_ctl = 1;
        }
    }
}

control SwitchEgress(
    inout switch_header_t hdr,
    inout switch_egress_metadata_t eg_md,
    in egress_intrinsic_metadata_t eg_intr_md,
    in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr,
    inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
    inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport) {

    apply {
    }
}


Pipeline(SwitchIngressParser(),
    SwitchIngress(),
    SwitchIngressDeparser(),
    SwitchEgressParser(),
    SwitchEgress(),
    SwitchEgressDeparser()) pipe;

Switch(pipe) main;
