#include <tna.p4>

header hdr1_t {
    bit<8>  a;
    bit<16> b;
    bit<8>  c;
    bit<48> d;
}

struct headers_t {
    hdr1_t hdr1;
}

struct user_metadata_t {
}

parser NestedParser(packet_in pkt, inout headers_t hdr) {
    state start {
        transition parse_nested;
    }
    state parse_nested {
        pkt.extract<hdr1_t>(hdr.hdr1);
        transition accept;
    }
}

parser InParser(packet_in pkt, out headers_t hdr, out user_metadata_t md, out ingress_intrinsic_metadata_t ig_intr_md) {
    NestedParser() nestedParser;
    state start {
        nestedParser.apply(pkt, hdr);
        transition accept;
    }
}

control SwitchIngress(inout headers_t hdr, inout user_metadata_t md, in ingress_intrinsic_metadata_t ig_intr_md, in ingress_intrinsic_metadata_from_parser_t ig_intr_md_from_prsr, inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprsr_md, inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {
    action set_pkt() {
        hdr.hdr1.d = ig_intr_md_from_prsr.global_tstamp;
    }
    table t1 {
        actions = {
            set_pkt();
            NoAction();
        }
        key = {
            hdr.hdr1.a: ternary @name("hdr.hdr1.a") ;
        }
        size = 512;
        default_action = NoAction();
    }
    apply {
        t1.apply();
    }
}

control SwitchIngressDeparser(packet_out pkt, inout headers_t hdr, in user_metadata_t meta, in ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr) {
    apply {
        pkt.emit<headers_t>(hdr);
    }
}

parser EgParser(packet_in pkt, out headers_t hdr, out user_metadata_t md, out egress_intrinsic_metadata_t ig_intr_md) {
    state start {
        pkt.extract<hdr1_t>(hdr.hdr1);
        transition accept;
    }
}

control SwitchEgress(inout headers_t hdr, inout user_metadata_t md, in egress_intrinsic_metadata_t eg_intr_md, in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_parser, inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr, inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport) {
    apply {
    }
}

control SwitchEgressDeparser(packet_out pkt, inout headers_t hdr, in user_metadata_t md, in egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr) {
    apply {
        pkt.emit<headers_t>(hdr);
    }
}

Pipeline<headers_t, user_metadata_t, headers_t, user_metadata_t>(InParser(), SwitchIngress(), SwitchIngressDeparser(), EgParser(), SwitchEgress(), SwitchEgressDeparser()) pipe0;

Switch<headers_t, user_metadata_t, headers_t, user_metadata_t, _, _, _, _, _, _, _, _, _, _, _, _>(pipe0) main;
