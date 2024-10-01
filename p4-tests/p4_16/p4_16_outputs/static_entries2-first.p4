#include <tna.p4>

struct switch_ingress_flags_t {
    bool ipv4_checksum_err;
    bool inner_ipv4_checksum_err;
    bool link_local;
    bool routed;
    bool acl_deny;
    bool racl_deny;
    bool port_vlan_miss;
    bool rmac_hit;
    bool myip;
    bool glean;
    bool storm_control_drop;
    bool qos_policer_drop;
    bool flood_to_multicast_routers;
}

header ethernet_h {
    bit<128> ipv6_dst_addr;
    bit<48>  dst_addr;
    bit<48>  src_addr;
    bit<16>  ether_type;
    bit<16>  range_type;
    bit<16>  lpm_type;
}

struct switch_metadata_t {
    bool ipv4_checksum_error;
}

struct switch_header_t {
    ethernet_h ethernet;
}

parser SwitchIngressParser(packet_in pkt, out switch_header_t hdr, out switch_metadata_t ig_md, out ingress_intrinsic_metadata_t ig_intr_md) {
    state start {
        pkt.extract<ingress_intrinsic_metadata_t>(ig_intr_md);
        pkt.advance(32w64);
        transition parse_ethernet;
    }
    state parse_ethernet {
        pkt.extract<ethernet_h>(hdr.ethernet);
        transition accept;
    }
}

parser SwitchEgressParser(packet_in pkt, out switch_header_t hdr, out switch_metadata_t eg_md, out egress_intrinsic_metadata_t eg_intr_md) {
    state start {
        pkt.extract<egress_intrinsic_metadata_t>(eg_intr_md);
        transition accept;
    }
}

control SwitchIngressDeparser(packet_out pkt, inout switch_header_t hdr, in switch_metadata_t ig_md, in ingress_intrinsic_metadata_for_deparser_t ig_intr_dprsr_md) {
    apply {
        pkt.emit<switch_header_t>(hdr);
    }
}

control SwitchEgressDeparser(packet_out pkt, inout switch_header_t hdr, in switch_metadata_t eg_md, in egress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md) {
    apply {
    }
}

control SwitchIngress(inout switch_header_t hdr, inout switch_metadata_t ig_md, in ingress_intrinsic_metadata_t ig_intr_md, in ingress_intrinsic_metadata_from_parser_t ig_intr_prsr_md, inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md, inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {
    action set_port_and_smac(bit<32> src_addr, bit<9> port) {
        hdr.ethernet.src_addr = (bit<48>)src_addr;
        ig_intr_tm_md.ucast_egress_port = port;
    }
    table forward {
        key = {
            ig_md.ipv4_checksum_error   : ternary @name("ig_md.ipv4_checksum_error") ;
            hdr.ethernet.ether_type     : ternary @name("hdr.ethernet.ether_type") ;
            hdr.ethernet.src_addr[31:24]: ternary @name("hdr.ethernet.src_addr[31:24]") ;
            hdr.ethernet.range_type     : range @name("hdr.ethernet.range_type") ;
        }
        actions = {
            set_port_and_smac();
        }
        const default_action = set_port_and_smac(32w0xff, 9w0x1);
        const entries = {
                        (default, 16w1, 8w255 &&& 8w0xf0, default) : set_port_and_smac(32w0xfa, 9w0x2);

                        (true, 16w2, default, default) : set_port_and_smac(32w0xfb, 9w0x3);

                        (false, 16w3, default, 16w1 .. 16w9) : set_port_and_smac(32w0xfc, 9w0x4);

        }

    }
    apply {
        forward.apply();
    }
}

control SwitchEgress(inout switch_header_t hdr, inout switch_metadata_t eg_md, in egress_intrinsic_metadata_t eg_intr_md, in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr, inout egress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md, inout egress_intrinsic_metadata_for_output_port_t eg_intr_oport_md) {
    apply {
    }
}

Pipeline<switch_header_t, switch_metadata_t, switch_header_t, switch_metadata_t>(SwitchIngressParser(), SwitchIngress(), SwitchIngressDeparser(), SwitchEgressParser(), SwitchEgress(), SwitchEgressDeparser()) pipe0;

Switch<switch_header_t, switch_metadata_t, switch_header_t, switch_metadata_t, _, _, _, _, _, _, _, _, _, _, _, _>(pipe0) main;
