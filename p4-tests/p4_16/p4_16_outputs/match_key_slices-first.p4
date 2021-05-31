#include <core.p4>
#include <tofino.p4>
#include <tna.p4>

header data_t {
    bit<48> f1;
    bit<48> f2;
    bit<8>  b1;
    bit<8>  b2;
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
        b.extract<ingress_intrinsic_metadata_t>(ig_intr_md);
        b.extract<ingress_skip_t>(skip);
        b.extract<data_t>(hdr.data);
        transition accept;
    }
}

control IngressP(inout headers hdr, inout metadata meta, in ingress_intrinsic_metadata_t ig_intr_md, in ingress_intrinsic_metadata_from_parser_t ig_intr_prsr_md, inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md, inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {
    action setb1(bit<8> b1, bit<9> port) {
        ig_intr_tm_md.ucast_egress_port = port;
        hdr.data.b1 = b1;
    }
    action setb2(bit<8> b2) {
        hdr.data.b2 = b2;
    }
    table slice_it0 {
        key = {
            hdr.data.f1 & 48w0xff00: exact @name("hdr.data.f1") ;
            hdr.data.f2[7:0]       : exact @name("hdr.data.f2[7:0]") ;
        }
        actions = {
            setb1();
        }
        default_action = setb1(8w0x77, 9w0);
    }
    table slice_it1 {
        key = {
            hdr.data.f1 & 48w0xff00ff00ff00: exact @name("hdr.data.f1") ;
            hdr.data.f2[39:32]             : exact @name("hdr.data.f2[39:32]") ;
            hdr.data.f2[23:16]             : exact @name("hdr.data.f2[23:16]") ;
            hdr.data.f2[7:0]               : exact @name("hdr.data.f2[7:0]") ;
        }
        actions = {
            setb2();
        }
        default_action = setb2(8w0x77);
    }
    apply {
        slice_it0.apply();
        slice_it1.apply();
    }
}

control DeparserI(packet_out b, inout headers hdr, in metadata meta, in ingress_intrinsic_metadata_for_deparser_t ig_intr_dprsr_md) {
    apply {
        b.emit<data_t>(hdr.data);
    }
}

parser ParserE(packet_in b, out headers hdr, out metadata meta, out egress_intrinsic_metadata_t eg_intr_md) {
    state start {
        b.extract<egress_intrinsic_metadata_t>(eg_intr_md);
        b.extract<data_t>(hdr.data);
        transition accept;
    }
}

control EgressP(inout headers hdr, inout metadata meta, in egress_intrinsic_metadata_t eg_intr_md, in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr, inout egress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md, inout egress_intrinsic_metadata_for_output_port_t eg_intr_oport_md) {
    apply {
    }
}

control DeparserE(packet_out b, inout headers hdr, in metadata meta, in egress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md) {
    apply {
        b.emit<data_t>(hdr.data);
    }
}

Pipeline<headers, metadata, headers, metadata>(ParserI(), IngressP(), DeparserI(), ParserE(), EgressP(), DeparserE()) pipe0;

Switch<headers, metadata, headers, metadata, _, _, _, _, _, _, _, _, _, _, _, _>(pipe0) main;
