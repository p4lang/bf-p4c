#include <tna.p4>

struct metadata {
}

header data_t {
    bit<32> f1;
    bit<32> f2;
    bit<16> h1;
    bit<8>  b1;
    bit<8>  b2;
}

struct headers {
    data_t data;
}

header ingress_skip_t {
    bit<64> pad;
}

parser ParserImpl(packet_in packet, out headers hdr, out metadata meta, out ingress_intrinsic_metadata_t ig_intr_md) {
    ingress_skip_t skip;
    state start {
        packet.extract(ig_intr_md);
        packet.extract(skip);
        packet.extract(hdr.data);
        transition accept;
    }
}

control ingress(inout headers hdr, inout metadata meta, in ingress_intrinsic_metadata_t ig_intr_md, in ingress_intrinsic_metadata_from_parser_t ig_intr_prsr_md, inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md, inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {
    Register<bit<16>, bit<16>>(1) accum;
    MathUnit<bit<16>>(false, 1, -6, { 0, 0, 0, 0, 0, 0, 0, 0, 64, 81, 100, 121, 144, 169, 196, 225 }) square;
    RegisterAction<bit<16>, bit<1>, bit<16>>(accum) run = {
        void apply(inout bit<16> value, out bit<16> rv) {
            value = square.execute(hdr.data.h1);
            rv = value;
        }
    };
    action noop() {
    }
    action do_run() {
        hdr.data.h1 = run.execute(0);
    }
    table test1 {
        actions = {
            noop;
            do_run;
        }
        key = {
            hdr.data.f1: exact;
        }
    }
    apply {
        ig_intr_tm_md.ucast_egress_port = 3;
        test1.apply();
    }
}

control ingressDeparser(packet_out packet, inout headers hdr, in metadata meta, in ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprs) {
    apply {
        packet.emit(hdr);
    }
}

parser egressParser(packet_in packet, out headers hdr, out metadata meta, out egress_intrinsic_metadata_t eg_intr_md) {
    state start {
        packet.extract(eg_intr_md);
        transition accept;
    }
}

control egress(inout headers hdr, inout metadata meta, in egress_intrinsic_metadata_t eg_intr_md, in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr, inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprs, inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport) {
    apply {
    }
}

control egressDeparser(packet_out packet, inout headers hdr, in metadata meta, in egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprs) {
    apply {
    }
}

Pipeline(ParserImpl(), ingress(), ingressDeparser(), egressParser(), egress(), egressDeparser()) pipe;

Switch(pipe) main;
