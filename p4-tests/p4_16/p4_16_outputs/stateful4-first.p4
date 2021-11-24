#include <tna.p4>

struct metadata {
}

struct pair {
    bit<8> lo;
    bit<8> hi;
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
        packet.extract<ingress_intrinsic_metadata_t>(ig_intr_md);
        packet.extract<ingress_skip_t>(skip);
        packet.extract<data_t>(hdr.data);
        transition accept;
    }
}

control ingress(inout headers hdr, inout metadata meta, in ingress_intrinsic_metadata_t ig_intr_md, in ingress_intrinsic_metadata_from_parser_t ig_intr_prsr_md, inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md, inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {
    Register<pair, bit<16>>(32w65536) accum;
    RegisterAction<pair, bit<16>, bit<8>>(accum) ra_load = {
        void apply(inout pair value) {
            value.lo = hdr.data.b1;
            value.hi = hdr.data.b2;
        }
    };
    RegisterAction<pair, bit<16>, bit<8>>(accum) ra1 = {
        void apply(inout pair value, out bit<8> rv) {
            rv = (bit<8>)(bit<1>)(hdr.data.b1 > value.lo && hdr.data.b1 < value.hi);
        }
    };
    RegisterAction<pair, bit<16>, bit<8>>(accum) ra2 = {
        void apply(inout pair value, out bit<8> rv) {
            rv = (hdr.data.b2 > value.lo && hdr.data.b2 < value.hi ? 8w1 : 8w0);
        }
    };
    action load() {
        ra_load.execute(hdr.data.h1);
    }
    action act1() {
        hdr.data.f2[7:0] = ra1.execute(hdr.data.h1);
    }
    action act2() {
        hdr.data.f2[7:0] = ra2.execute(hdr.data.h1);
    }
    table test1 {
        actions = {
            load();
            act1();
            act2();
            @defaultonly NoAction();
        }
        key = {
            hdr.data.f1: exact @name("hdr.data.f1") ;
        }
        default_action = NoAction();
    }
    apply {
        ig_intr_tm_md.ucast_egress_port = 9w3;
        test1.apply();
    }
}

control ingressDeparser(packet_out packet, inout headers hdr, in metadata meta, in ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprs) {
    apply {
        packet.emit<headers>(hdr);
    }
}

parser egressParser(packet_in packet, out headers hdr, out metadata meta, out egress_intrinsic_metadata_t eg_intr_md) {
    state start {
        packet.extract<egress_intrinsic_metadata_t>(eg_intr_md);
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

Pipeline<headers, metadata, headers, metadata>(ParserImpl(), ingress(), ingressDeparser(), egressParser(), egress(), egressDeparser()) pipe;

Switch<headers, metadata, headers, metadata, _, _, _, _, _, _, _, _, _, _, _, _>(pipe) main;
