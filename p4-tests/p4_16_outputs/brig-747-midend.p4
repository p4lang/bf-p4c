#include <core.p4>
#include <tofino.p4>
#include <tna.p4>

typedef bit<48> mac_addr_t;
header ethernet_h {
    mac_addr_t dst_addr;
    mac_addr_t src_addr;
    bit<16>    ether_type;
}

struct switch_header_t {
    ethernet_h ethernet;
}

struct metadata_t {
    bool checksum_err;
}

parser SwitchIngressParser(packet_in pkt, out switch_header_t hdr, out metadata_t ig_md, out ingress_intrinsic_metadata_t ig_intr_md) {
    state start {
        transition accept;
    }
}

control SwitchIngressDeparser(packet_out pkt, inout switch_header_t hdr, in metadata_t ig_md, in ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md) {
    apply {
    }
}

parser SwitchEgressParser(packet_in pkt, out switch_header_t hdr, out metadata_t eg_md, out egress_intrinsic_metadata_t eg_intr_md) {
    ethernet_h ethernet_1;
    ethernet_h tmp_0;
    bit<112> tmp;
    state start {
        pkt.extract<egress_intrinsic_metadata_t>(eg_intr_md);
        tmp = pkt.lookahead<bit<112>>();
        tmp_0.setValid();
        tmp_0.dst_addr = tmp[111:64];
        tmp_0.src_addr = tmp[63:16];
        tmp_0.ether_type = tmp[15:0];
        ethernet_1 = tmp_0;
        transition select(ethernet_1.ether_type) {
            16w0x9001: accept;
            default: accept;
        }
    }
}

control SwitchEgressDeparser(packet_out pkt, inout switch_header_t hdr, in metadata_t eg_md, in egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr) {
    apply {
    }
}

control SwitchIngress(inout switch_header_t hdr, inout metadata_t ig_md, in ingress_intrinsic_metadata_t ig_intr_md, in ingress_intrinsic_metadata_from_parser_t ig_prsr_md, inout ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md, inout ingress_intrinsic_metadata_for_tm_t ig_tm_md) {
    apply {
    }
}

control SwitchEgress(inout switch_header_t hdr, inout metadata_t eg_md, in egress_intrinsic_metadata_t eg_intr_md, in egress_intrinsic_metadata_from_parser_t eg_intr_from_prsr, inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr, inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport) {
    apply {
    }
}

Pipeline<switch_header_t, metadata_t, switch_header_t, metadata_t>(SwitchIngressParser(), SwitchIngress(), SwitchIngressDeparser(), SwitchEgressParser(), SwitchEgress(), SwitchEgressDeparser()) pipe;

Switch<switch_header_t, metadata_t, switch_header_t, metadata_t, _, _, _, _, _, _, _, _, _, _, _, _>(pipe) main;

