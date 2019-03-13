#include <core.p4>
#include <tofino.p4>

header data_t {
    bit<32> f1;
    bit<32> f2;
    bit<16> h1;
    bit<8>  b1;
    bit<8>  b2;
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

control IngressP(inout headers hdr, inout metadata meta, in ingress_intrinsic_metadata_t ig_intr_md, in ingress_intrinsic_metadata_from_parser_t ig_intr_prsr_md, out ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {
    bit<16> tmp_0;
    @name("NoAction") action NoAction_0() {
    }
    @name("accum") register<bit<16>, bit<10>>(10w1023, 16w0) accum;
    @name("param") stateful_param<bit<16>>(16w0) param_1;
    @name("sful") stateful_alu<bit<16>, bit<10>, bit<16>, bit<16>>(accum, param_1) sful = {
        void instruction(inout bit<16> value, out bit<16> rv) {
            rv = value;
            value = value + (bit<16>)hdr.data.b1;
        }
    };
    @name("addb1") action addb1_0(bit<9> port) {
        ig_intr_tm_md.ucast_egress_port = port;
        tmp_0 = sful.execute(10w1023);
        hdr.data.h1 = tmp_0;
    }
    @name("test1") table test1 {
        actions = {
            addb1_0();
            @defaultonly NoAction_0();
        }
        key = {
            hdr.data.f1: exact @name("hdr.data.f1") ;
        }
        default_action = NoAction_0();
    }
    apply {
        test1.apply();
    }
}

control DeparserI(packet_out b, in headers hdr, in metadata meta) {
    @hidden action act() {
        b.emit<data_t>(hdr.data);
    }
    @hidden table tbl_act {
        actions = {
            act();
        }
        const default_action = act();
    }
    apply {
        tbl_act.apply();
    }
}

parser ParserE(packet_in b, out headers hdr, out metadata meta, out egress_intrinsic_metadata_t eg_intr_md) {
    state start {
        b.extract<data_t>(hdr.data);
        transition accept;
    }
}

control EgressP(inout headers hdr, inout metadata meta, in egress_intrinsic_metadata_t eg_intr_md, in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr) {
    apply {
    }
}

control DeparserE(packet_out b, in headers hdr, in metadata meta) {
    @hidden action act_0() {
        b.emit<data_t>(hdr.data);
    }
    @hidden table tbl_act_0 {
        actions = {
            act_0();
        }
        const default_action = act_0();
    }
    apply {
        tbl_act_0.apply();
    }
}

Switch<headers, metadata, headers, metadata>(ParserI(), IngressP(), DeparserI(), ParserE(), EgressP(), DeparserE()) main;
