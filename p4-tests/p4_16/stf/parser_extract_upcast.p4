#include <core.p4>
#include <tna.p4>

// headers
header choice_h {
    bit<8> pkt_type;
}

header nvgre_h {
    bit<24> vsid;
    bit<8> flow_id;
}

header vxlan_h {
    bit<8> flags;
    bit<24> reserved;
    bit<24> vni;
    bit<8> reserved2;
}

header tricky_h {
    bit<32> teid;
}

header so_tricky_h {
// adding a junk byte here will only make it easier.
//  bit<8> junk;
    bit<16> teid;
}

typedef bit<32> switch_tunnel_id_t;
struct switch_metadata_t {
    switch_tunnel_id_t tunnel_id;
}

struct switch_header_t {
    choice_h choice;
    vxlan_h vxlan;
    nvgre_h nvgre;
    tricky_h tricky;
    so_tricky_h so_tricky;
}

parser IngressParser(
        packet_in pkt,
        out switch_header_t hdr,
        out switch_metadata_t ig_md,
        out ingress_intrinsic_metadata_t ig_intr_md) {
    state start {
        pkt.extract(ig_intr_md);
        pkt.advance(PORT_METADATA_SIZE);
        transition parse_choice;
    }

    state parse_choice {
        pkt.extract(hdr.choice);
        transition select(hdr.choice.pkt_type) {
            0x01: parse_outer_nvgre;
            0x02: parse_outer_vxlan;
            0x03: parse_tricky;
            0x04: parse_so_tricky;
            default : reject;
        }
    }

    state parse_outer_vxlan {
        pkt.extract(hdr.vxlan);
        ig_md.tunnel_id = (bit<32>)hdr.vxlan.vni;
        transition accept;
    }

    state parse_outer_nvgre {
        pkt.extract(hdr.nvgre);
        ig_md.tunnel_id = (bit<32>)hdr.nvgre.vsid;
        transition accept;
    }

    state parse_tricky {
        pkt.extract(hdr.tricky);
        ig_md.tunnel_id = hdr.tricky.teid;
        transition accept;
    }

    state parse_so_tricky {
        pkt.extract(hdr.so_tricky);
        ig_md.tunnel_id = (bit<32>)hdr.so_tricky.teid;
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

    table test {
        key = {
            ig_md.tunnel_id : exact;
        }

        actions = {
            NoAction;
            forward;
        }
    }

    apply {
        test.apply();
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
