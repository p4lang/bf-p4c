
#include <core.p4>
#include <tna.p4>

header data_t {
    bit<32> read;
    bit<1> x1;
    bit<1> x2;
    bit<1> x3;
    bit<2> y1;
    bit<3> z1;
}

struct local_t {
    bit<1> m1;
    bit<1> m2;
    bit<2> m3;
    bit<3> m4;
}

struct headers {
    data_t data;
}

struct metadata {
    local_t local;
}

parser ParserI(packet_in b,
               out headers hdr,
               out metadata meta,
               out ingress_intrinsic_metadata_t ig_intr_md) {
    state start {
        b.extract(hdr.data);
        transition accept;
    }
}

control IngressP(
        inout headers hdr,
        inout metadata meta,
        in ingress_intrinsic_metadata_t ig_intr_md,
        in ingress_intrinsic_metadata_from_parser_t ig_intr_prsr_md,
        inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {
    action noop() {}

    action set_local(bit<1> p1, bit<1> p2, bit<2> p3, bit<3> p4) {
        meta.local.m1 = p1;
        meta.local.m2 = p2;
        meta.local.m3 = p3;
        meta.local.m4 = p4;
    }

    action set_hdr(bit<9> port) {
        hdr.data.x1 = meta.local.m1;
        hdr.data.x2 = meta.local.m2;
        hdr.data.x3 = meta.local.m2;
        hdr.data.y1 = meta.local.m3;
        hdr.data.z1 = meta.local.m4;
        ig_intr_tm_md.ucast_egress_port = port;
    }

    table first {
        key = {
            hdr.data.read : ternary;
        }
        actions = { set_local; noop; }
    }

    table second {
        key = {
            hdr.data.read : ternary;
        }
        actions = { set_hdr; noop; }
    }

    apply {
        first.apply();
        second.apply();
    }
}

control DeparserI(
        packet_out b,
        inout headers hdr,
        in metadata meta,
        in ingress_intrinsic_metadata_for_deparser_t ig_intr_dprsr_md) {
    apply { b.emit(hdr.data); }
}

parser ParserE(packet_in b,
               out headers hdr,
               out metadata meta,
               out egress_intrinsic_metadata_t eg_intr_md) {
    state start {
        b.extract(hdr.data);
        transition accept;
    }
}

control EgressP(
        inout headers hdr,
        inout metadata meta,
        in egress_intrinsic_metadata_t eg_intr_md,
        in egress_intrinsic_metadata_from_parser_t eg_intr_prsr_md,
        inout egress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md,
        inout egress_intrinsic_metadata_for_output_port_t eg_intr_oport_md) {
    apply { }
}

control DeparserE(packet_out b,
                  inout headers hdr,
                  in metadata meta,
                  in egress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md) {
    apply { b.emit(hdr.data); }
}

Pipeline(ParserI(), IngressP(), DeparserI(), ParserE(), EgressP(), DeparserE()) pipe0;
Switch(pipe0) main;
