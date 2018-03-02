#include <core.p4>
#include <tofino.p4>
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

parser ParserI(packet_in b, out headers hdr, out metadata meta, out ingress_intrinsic_metadata_t ig_intr_md) {
    state start {
        b.extract<data_t>(hdr.data);
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
            t2_act();
            noop();
        }
        key = {
            hdr.data.h2: exact @name("hdr.data.h2") ;
        }
        default_action = noop();
    }
    table t3 {
        actions = {
            t3_act();
            noop();
        }
        key = {
            hdr.data.h2: exact @name("hdr.data.h2") ;
        }
        default_action = noop();
    }
    apply {
        if (hdr.data.b2 == 8w0) 
            if (!t2.apply().hit) 
                t3.apply();
        else 
            t3.apply();
    }
}

control IngressP(inout headers hdr, inout metadata meta, in ingress_intrinsic_metadata_t ig_intr_md, in ingress_intrinsic_metadata_from_parser_t ig_intr_prsr_md, inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md, inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {
    @name("inner_multiple") inner_multiple() inner_multiple_inst;
    @name("inner_multiple") inner_multiple() inner_multiple_inst_0;
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
            t1_act();
            noop();
        }
        key = {
            hdr.data.h1: exact @name("hdr.data.h1") ;
        }
        default_action = noop();
    }
    table port_setter {
        actions = {
            set_port();
            noop();
        }
        key = {
            hdr.data.h1: exact @name("hdr.data.h1") ;
            hdr.data.h2: exact @name("hdr.data.h2") ;
        }
        default_action = noop();
    }
    apply {
        if (hdr.data.b1 == 8w0) 
            if (!t1.apply().hit) 
                inner_multiple_inst.apply(hdr, meta, ig_intr_md, ig_intr_prsr_md, ig_intr_tm_md);
        else 
            inner_multiple_inst_0.apply(hdr, meta, ig_intr_md, ig_intr_prsr_md, ig_intr_tm_md);
        port_setter.apply();
    }
}

control DeparserI(packet_out b, inout headers hdr, in metadata meta, in ingress_intrinsic_metadata_for_deparser_t ig_intr_dprsr_md) {
    apply {
        b.emit<data_t>(hdr.data);
    }
}

parser ParserE(packet_in b, out headers hdr, out metadata meta, out egress_intrinsic_metadata_t eg_intr_md) {
    state start {
        b.extract<data_t>(hdr.data);
        transition accept;
    }
}

control EgressP(inout headers hdr, inout metadata meta, in egress_intrinsic_metadata_t eg_intr_md, in egress_intrinsic_metadata_from_parser_t eg_intr_prsr_md, inout egress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md, inout egress_intrinsic_metadata_for_output_port_t eg_intr_oport_md) {
    apply {
    }
}

control DeparserE(packet_out b, inout headers hdr, in metadata meta, in egress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md) {
    apply {
        b.emit<data_t>(hdr.data);
    }
}

Switch<headers, metadata, headers, metadata>(ParserI(), IngressP(), DeparserI(), ParserE(), EgressP(), DeparserE()) main;

