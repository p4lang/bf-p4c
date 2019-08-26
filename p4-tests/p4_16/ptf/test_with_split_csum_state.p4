#include <core.p4>
#include <tna.p4>

#define IP_PROTOCOLS_TCP    6
#define IP_PROTOCOLS_UDP    17

typedef bit<48> mac_addr_t;
typedef bit<32> ipv4_addr_t;

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

@pa_container_size("ingress", "hdr.tcp.src_port", 32)
@pa_container_size("ingress", "hdr.tcp.dst_port", 32)
@pa_container_size("ingress", "hdr.tcp.seq_no", 16)
@pa_container_size("ingress", "hdr.tcp.ack_no", 16)
@pa_container_size("ingress", "hdr.tcp.data_offset", 8)
@pa_container_size("ingress", "hdr.tcp.res", 8)
@pa_container_size("ingress", "hdr.tcp.flags", 8)
@pa_container_size("ingress", "hdr.tcp.window", 16)
@pa_container_size("ingress", "hdr.tcp.checksum", 16)
@pa_container_size("ingress", "hdr.tcp.urgent_ptr", 16)
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

struct header_t {
    ethernet_h ethernet;
    ipv4_h ipv4;
    udp_h udp;
    tcp_h tcp;
}

struct metadata_t {
    bit<16> tcp_csum;
    bit<16> udp_csum;
    bit<1>  update_csum;
}


parser IngressParser(
        packet_in pkt,
        out header_t hdr,
        out metadata_t ig_md,
        out ingress_intrinsic_metadata_t ig_intr_md) {

    Checksum() tcp_csum;
    Checksum() udp_csum;

    state start {
        pkt.extract(ig_intr_md);
        transition parse_port_metadata;
    }

    state parse_port_metadata {
        pkt.advance(64);
        transition parse_ethernet;
    }

    state parse_ethernet {
        pkt.extract(hdr.ethernet);
        transition parse_ipv4;
    }

    state parse_ipv4 {
        pkt.extract(hdr.ipv4);

        tcp_csum.subtract({hdr.ipv4.src_addr, hdr.ipv4.dst_addr});
        udp_csum.subtract({hdr.ipv4.src_addr, hdr.ipv4.dst_addr});

        transition select(hdr.ipv4.protocol, hdr.ipv4.frag_offset) {
            (IP_PROTOCOLS_TCP, 0) : parse_tcp;
            (IP_PROTOCOLS_UDP, 0) : parse_udp;
            default : accept;
        }
    }

    state parse_udp {
        pkt.extract(hdr.udp);

        udp_csum.subtract({hdr.udp.checksum});
        udp_csum.subtract({hdr.udp.src_port, hdr.udp.dst_port});
        ig_md.udp_csum = udp_csum.get();

        transition accept;
    }

    state parse_tcp {
        pkt.extract(hdr.tcp);
        tcp_csum.subtract({hdr.tcp.checksum});
        tcp_csum.subtract({hdr.tcp.src_port, hdr.tcp.dst_port});
        ig_md.tcp_csum = tcp_csum.get();

        transition accept;
    }
}
control IngressPipe(
        inout header_t hdr,
        inout metadata_t ig_md,
        in    ingress_intrinsic_metadata_t               ig_intr_md,
        in    ingress_intrinsic_metadata_from_parser_t   ig_prsr_md,
        inout ingress_intrinsic_metadata_for_deparser_t  ig_dprsr_md,
        inout ingress_intrinsic_metadata_for_tm_t        ig_tm_md) {
    apply {
        ig_tm_md.ucast_egress_port = 1;
    }
}

control IngressDeparser(
    packet_out pkt,
    inout header_t hdr,
    in metadata_t ig_md,
    in ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr) {

    Checksum() tcp_csum;
    Checksum() udp_csum;

    apply {
        hdr.tcp.checksum = tcp_csum.update({
                hdr.ipv4.src_addr,
                hdr.ipv4.dst_addr,
                hdr.tcp.src_port,
                hdr.tcp.dst_port,
                ig_md.tcp_csum});

        hdr.udp.checksum = udp_csum.update({
                hdr.ipv4.src_addr,
                hdr.ipv4.dst_addr,
                hdr.udp.src_port,
                hdr.udp.dst_port,
                ig_md.udp_csum});

        pkt.emit(hdr);
    }
}

parser EgressParser(
        packet_in pkt,
        out header_t hdr,
        out metadata_t eg_md,
        out egress_intrinsic_metadata_t eg_intr_md) {

    state start {
        pkt.extract(eg_intr_md);
        transition parse_ethernet;
    }

    state parse_ethernet {
        pkt.extract(hdr.ethernet);
        transition parse_ipv4;
    }

    state parse_ipv4 {
        pkt.extract(hdr.ipv4);
        transition select(hdr.ipv4.protocol, hdr.ipv4.frag_offset) {
            (IP_PROTOCOLS_TCP, 0) : parse_tcp;
            (IP_PROTOCOLS_UDP, 0) : parse_udp;
            default : accept;
        }
    }

    state parse_udp {
        pkt.extract(hdr.udp);
        transition accept; 
    }

    state parse_tcp {
        pkt.extract(hdr.tcp);
        transition accept;
    }
}

control EgressPipe(
        inout header_t hdr,
        inout metadata_t eg_md,
        in    egress_intrinsic_metadata_t eg_intr_md,
        in    egress_intrinsic_metadata_from_parser_t eg_prsr_md,
        inout egress_intrinsic_metadata_for_deparser_t eg_dprsr_md,
        inout egress_intrinsic_metadata_for_output_port_t  eg_oport_md) {
    apply {}
}

control EgressDeparser(
    packet_out pkt,
    inout header_t hdr,
    in metadata_t eg_md,
    in egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr) {

    apply {
        pkt.emit(hdr);
    }
}

Pipeline(IngressParser(), IngressPipe(), IngressDeparser(),
       EgressParser(), EgressPipe(), EgressDeparser()) pipe;

Switch(pipe) main;
