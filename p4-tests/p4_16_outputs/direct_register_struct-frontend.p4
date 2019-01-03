#include <core.p4>
#include <tofino.p4>
#include <tna.p4>

header data_t {
    bit<32> v;
}

struct headers {
    data_t data;
}

struct metadata {
}

parser ParserI(packet_in b, out headers hdr, out metadata meta, out ingress_intrinsic_metadata_t ig_intr_md) {
    state start {
        b.extract<data_t>(hdr.data);
        transition accept;
    }
}

struct pair {
    bit<32> first;
    bit<32> second;
}

control IngressP(inout headers hdr, inout metadata meta, in ingress_intrinsic_metadata_t ig_intr_md, in ingress_intrinsic_metadata_from_parser_t ig_intr_prsr_md, inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md, inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {
    @name(".NoAction") action NoAction_0() {
    }
    @name("IngressP.test_reg_dir") DirectRegister<pair>() test_reg_dir_0;
    @name("IngressP.test_reg_dir_action") DirectRegisterAction<pair, bit<32>>(test_reg_dir_0) test_reg_dir_action_0 = {
        void apply(inout pair value, out bit<32> read_value) {
            read_value = value.second;
            value.first = value.first + 32w1;
            value.second = value.second + 32w100;
        }
    };
    @name("IngressP.register_action_dir") action register_action_dir() {
        test_reg_dir_action_0.execute();
    }
    @name("IngressP.reg_match_dir") table reg_match_dir_0 {
        key = {
            hdr.data.v: exact @name("hdr.data.v") ;
        }
        actions = {
            register_action_dir();
            @defaultonly NoAction_0();
        }
        size = 1024;
        registers = test_reg_dir_0;
        default_action = NoAction_0();
    }
    apply {
        reg_match_dir_0.apply();
        ig_intr_tm_md.bypass_egress = true;
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

Pipeline<headers, metadata, headers, metadata>(ParserI(), IngressP(), DeparserI(), ParserE(), EgressP(), DeparserE()) pipe0;

Switch<headers, metadata, headers, metadata, _, _, _, _, _, _, _, _, _, _, _, _>(pipe0) main;

