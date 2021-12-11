#include <core.p4>
#include <tna.p4>

// headers
header ipv6_h {
    bit<128> dst_addr;
    bit<32>  tunnel_id;
}

header tunnel_data_h {
    bit<8> pad;
    bit<8> qfi;
    bit<16> teid0;
    bit<16> teid1;
}

typedef bit<32> switch_tunnel_id_t;
struct switch_metadata_t {
    switch_tunnel_id_t tunnel_id;
}

struct switch_header_t {
    ipv6_h ipv6;
    tunnel_data_h tunnel_data;
}

parser IngressParser(
        packet_in pkt,
        out switch_header_t hdr,
        out switch_metadata_t ig_md,
        out ingress_intrinsic_metadata_t ig_intr_md) {
    state start {
        pkt.extract(ig_intr_md);
        pkt.advance(PORT_METADATA_SIZE);
        transition parse_ipv6;
    }

    state parse_ipv6 {
        pkt.extract(hdr.ipv6);
        pkt.extract(hdr.tunnel_data);
        transition accept;
    }
}

control IngressDeparser(packet_out pkt,
                        inout switch_header_t hdr,
                        in switch_metadata_t ig_md,
                        in ingress_intrinsic_metadata_for_deparser_t ig_intr_dprsr_md) {
    apply {
        pkt.emit(hdr);
    }
}

control Ingress(
        inout switch_header_t hdr,
        inout switch_metadata_t ig_md,
        in ingress_intrinsic_metadata_t ig_intr_md,
        in ingress_intrinsic_metadata_from_parser_t ig_intr_prsr_md,
        inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {

    action forward(PortId_t port) {
        ig_intr_tm_md.ucast_egress_port = port;
    }
    action parse_80() {
        forward(2);
        hdr.tunnel_data.qfi  = hdr.ipv6.dst_addr[47:40];
        // teid0 = dst_addr[39:24]
        funnel_shift_right(hdr.tunnel_data.teid0[15:0], hdr.ipv6.dst_addr[47:32], hdr.ipv6.dst_addr[31:16], 8);
        // [23:8]
        funnel_shift_right(hdr.tunnel_data.teid1[15:0], hdr.ipv6.dst_addr[31:16], hdr.ipv6.dst_addr[15:0], 8);
    }
    action parse_72() {
        forward(2);
        hdr.tunnel_data.qfi   = hdr.ipv6.dst_addr[55:48];
        hdr.tunnel_data.teid0 = hdr.ipv6.dst_addr[47:32];
        hdr.tunnel_data.teid1 = hdr.ipv6.dst_addr[31:16];
    }
    action parse_64() {
        forward(2);
        hdr.tunnel_data.qfi  = hdr.ipv6.dst_addr[63:56];
        funnel_shift_right(hdr.tunnel_data.teid0[15:0], hdr.ipv6.dst_addr[63:48], hdr.ipv6.dst_addr[47:32], 8);
        funnel_shift_right(hdr.tunnel_data.teid1[15:0], hdr.ipv6.dst_addr[47:32], hdr.ipv6.dst_addr[31:16], 8);

    }
    action parse_56() {
        forward(2);
        hdr.tunnel_data.qfi   = hdr.ipv6.dst_addr[71:64];
        hdr.tunnel_data.teid0 = hdr.ipv6.dst_addr[63:48];
        hdr.tunnel_data.teid1 = hdr.ipv6.dst_addr[47:32];
    }

    table rewrite_tunnel_data {
        key = {
            hdr.ipv6.tunnel_id : exact;
        }

        actions = {
            parse_56;
            parse_64;
            parse_72;
            parse_80;
        }
    }

    apply {
        rewrite_tunnel_data.apply();
    }
}

parser EgressParser(packet_in packet,
                        out switch_header_t hdr,
                        out switch_metadata_t meta,
                        out egress_intrinsic_metadata_t eg_intr_md) {
    state start {
        packet.extract(eg_intr_md);
        transition accept;
    }
}

control EgressP(
        inout switch_header_t hdr,
        inout switch_metadata_t meta,
        in egress_intrinsic_metadata_t eg_intr_md,
        in egress_intrinsic_metadata_from_parser_t eg_intr_prsr_md,
        inout egress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md,
        inout egress_intrinsic_metadata_for_output_port_t eg_intr_oport_md) {
    apply { }
}

control DeparserE(packet_out packet,
                           inout switch_header_t hdr,
                           in switch_metadata_t meta,
                           in egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr) {
    apply { }
}

Pipeline(IngressParser(),
       Ingress(),
       IngressDeparser(),
       EgressParser(),
       EgressP(),
       DeparserE()) pipe0;
Switch(pipe0) main;
