#include <core.p4>
#include <tna.p4>


header ethernet_t {
    bit<48> dst_addr;
    bit<48> src_addr;
    bit<16> eth_type;
}


header proto_t {
    bit<32> fld_a;
    bit<16> fld_b;
}

header proto2_t {
    bit<32> fld_a2;
    bit<32> fld_b2;
}

header proto3_t {
    bit<32> fld_a3;
    bit<16> fld_b3;
    bit<32> fld_c3;
    bit<16> fld_d3;
}

header proto4_t {
    bit<8> fld_a4;
    bit<8> fld_b4;
}

header proto5_t {
    bit<14> fld_a5;
    bit<2>  fld_b5;
}

struct Headers {
    ethernet_t  eth;
    proto_t     prt1;
    proto2_t    prt2;
    proto3_t    prt3;
    proto4_t    prt4;
    proto5_t    prt5;
}

struct user_meta {
    bit<48> meta_fld;
}

struct ingress_metadata_t {
    user_meta mt;
}

struct egress_metadata_t {
} 

parser SwitchIngressParser(packet_in pkt, out Headers hdr, out ingress_metadata_t ig_md, out ingress_intrinsic_metadata_t ig_intr_md) {
    state start {
        pkt.extract(ig_intr_md);
        pkt.advance(PORT_METADATA_SIZE);
        transition parse_eth;
    }

    state parse_eth {
        pkt.extract(hdr.eth);
        transition parse_prt1;
    }

    state parse_prt1 {
        pkt.extract(hdr.prt1);
        transition select(hdr.prt1.fld_a) {
            1           : parse_prt2;
            0           : parse_prt3;
            default     : accept;
        }
    }

    state parse_prt2 {
        pkt.extract(hdr.prt2);
        transition accept;
    }

    state parse_prt3 {
        pkt.extract(hdr.prt3);
        transition select(hdr.prt3.fld_b3) {
            0xffff    : parse_prt4;
            0x0       : parse_prt5;
            default : accept;
        }
    }

    state parse_prt4 {
        pkt.extract(hdr.prt4);
        transition accept;
    }

    state parse_prt5 {
        pkt.extract(hdr.prt5);
        ig_md.mt.meta_fld = (bit<48>) hdr.prt1.fld_b;
        transition accept;
    }
}

control ingress(inout Headers h, inout ingress_metadata_t ig_md, in ingress_intrinsic_metadata_t ig_intr_md, in ingress_intrinsic_metadata_from_parser_t ig_prsr_md, inout ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md, inout ingress_intrinsic_metadata_for_tm_t ig_tm_md) {
    action swap_macs() {
        h.eth.dst_addr = h.eth.src_addr;
        h.eth.src_addr = ig_md.mt.meta_fld;
    }

    apply {
        ig_tm_md.ucast_egress_port = 0;
        if(h.prt5.isValid()) {
            ig_tm_md.ucast_egress_port = 2;
            swap_macs();
        } else if (h.prt4.isValid()) {
            ig_tm_md.ucast_egress_port = 4;
        }
    }
}

control SwitchIngressDeparser(packet_out pkt, inout Headers h, in ingress_metadata_t ig_md, in ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md) {
    apply {
        pkt.emit(h);
    }
}

parser SwitchEgressParser(packet_in pkt, out Headers h, out egress_metadata_t eg_md, out egress_intrinsic_metadata_t eg_intr_md) {
        state start {
            pkt.extract(eg_intr_md);
            pkt.extract(h.eth);
            transition accept;
    }
 }

control SwitchEgress(inout Headers h, inout egress_metadata_t eg_md, in egress_intrinsic_metadata_t eg_intr_md, in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr, inout egress_intrinsic_metadata_for_deparser_t eg_intr_dprs_md, inout egress_intrinsic_metadata_for_output_port_t eg_intr_oport_md) {
    apply {}
}

control SwitchEgressDeparser(packet_out pkt, inout Headers h, in egress_metadata_t eg_md, in egress_intrinsic_metadata_for_deparser_t eg_intr_dprs_md) {
    apply {
        pkt.emit(h);
    }
}

Pipeline(SwitchIngressParser(), ingress(), SwitchIngressDeparser(), SwitchEgressParser(), SwitchEgress(), SwitchEgressDeparser()) pipe;
Switch(pipe) main;
