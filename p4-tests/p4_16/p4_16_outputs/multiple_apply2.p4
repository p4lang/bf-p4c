#include <tna.p4>

header data_t {
    bit<16> h1;
    bit<16> h2;
    bit<16> h3;
    bit<8>  b1;
    bit<8>  b2;
    bit<8>  b3;
    bit<8>  b4;
    bit<8>  b5;
}

struct metadata {
}

struct headers {
    data_t data;
}

header ingress_skip_t {
    bit<64> pad;
}

parser ParserI(packet_in b, out headers hdr, out metadata meta, out ingress_intrinsic_metadata_t ig_intr_md) {
    ingress_skip_t skip;
    state start {
        b.extract(ig_intr_md);
        b.extract(skip);
        b.extract(hdr.data);
        transition accept;
    }
}

control inner_multiple(inout headers hdr, inout metadata meta, in ingress_intrinsic_metadata_t ig_intr_md, in ingress_intrinsic_metadata_from_parser_t ig_intr_prsr_md, inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {
    action noop() {
    }
    action t2_act(bit<8> b4) {
        hdr.data.b4 = b4;
    }
    action t3_act(bit<8> b5) {
        hdr.data.b5 = b5;
    }
    table t2 {
        actions = {
            t2_act;
            noop;
        }
        key = {
            hdr.data.h2: exact;
        }
        default_action = noop;
    }
    table t3 {
        actions = {
            t3_act;
            noop;
        }
        key = {
            hdr.data.h2: exact;
        }
        default_action = noop;
    }
    apply {
        if (hdr.data.b2 == 0) {
            if (!t2.apply().hit) {
                t3.apply();
            }
        }
        else {
            t3.apply();
        }
    }
}

control IngressP(inout headers hdr, inout metadata meta, in ingress_intrinsic_metadata_t ig_intr_md, in ingress_intrinsic_metadata_from_parser_t ig_intr_prsr_md, inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md, inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {
    action noop() {
    }
    action set_port(bit<9> port) {
        ig_intr_tm_md.ucast_egress_port = port;
    }
    action t1_act(bit<8> b3) {
        hdr.data.b3 = b3;
    }
    action t2_act(bit<8> b4) {
        hdr.data.b4 = b4;
    }
    table t1 {
        actions = {
            t1_act;
            noop;
        }
        key = {
            hdr.data.h1: exact;
        }
        default_action = noop;
    }
    table port_setter {
        actions = {
            set_port;
            noop;
        }
        key = {
            hdr.data.h1: exact;
            hdr.data.h2: exact;
        }
        default_action = noop;
    }
    apply {
        if (hdr.data.b1 == 0) {
            if (!t1.apply().hit) {
                inner_multiple.apply(hdr, meta, ig_intr_md, ig_intr_prsr_md, ig_intr_tm_md);
            }
        }
        else {
            inner_multiple.apply(hdr, meta, ig_intr_md, ig_intr_prsr_md, ig_intr_tm_md);
        }
        port_setter.apply();
    }
}

control DeparserI(packet_out b, inout headers hdr, in metadata meta, in ingress_intrinsic_metadata_for_deparser_t ig_intr_dprsr_md) {
    apply {
        b.emit(hdr.data);
    }
}

parser ParserE(packet_in b, out headers hdr, out metadata meta, out egress_intrinsic_metadata_t eg_intr_md) {
    state start {
        b.extract(eg_intr_md);
        b.extract(hdr.data);
        transition accept;
    }
}

control EgressP(inout headers hdr, inout metadata meta, in egress_intrinsic_metadata_t eg_intr_md, in egress_intrinsic_metadata_from_parser_t eg_intr_prsr_md, inout egress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md, inout egress_intrinsic_metadata_for_output_port_t eg_intr_oport_md) {
    apply {
    }
}

control DeparserE(packet_out b, inout headers hdr, in metadata meta, in egress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md) {
    apply {
        b.emit(hdr.data);
    }
}

Pipeline(ParserI(), IngressP(), DeparserI(), ParserE(), EgressP(), DeparserE()) pipe0;

Switch(pipe0) main;
