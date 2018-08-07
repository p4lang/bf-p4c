#include <core.p4>
#include <tna.p4>

header data_t {
    bit<32> v;
}

struct headers {
    data_t data;
}

struct metadata { }

parser ParserI(packet_in b,
               out headers hdr,
               out metadata meta,
               out ingress_intrinsic_metadata_t ig_intr_md) {
    state start {
        b.extract(hdr.data);
        transition accept;
    }
}

struct pair {   
    bit<32> first;
    bit<32> second;
}

control IngressP(
        inout headers hdr,
        inout metadata meta,
        in ingress_intrinsic_metadata_t ig_intr_md,
        in ingress_intrinsic_metadata_from_parser_t ig_intr_prsr_md,
        inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {
    // 0 size => direct register
    Register<pair>(0) test_reg_dir;
    RegisterAction<pair, bit<32>>(test_reg_dir) test_reg_dir_action = {
        void apply(inout pair value, out bit<32> read_value){
            read_value = value.second;
            value.first = value.first + 1;
            value.second = value.second + 100;
        }
    };

    action register_action_dir() {
        test_reg_dir_action.execute();
    }

    table reg_match_dir {
        key = {
            hdr.data.v : exact;
        }
        actions = {
            register_action_dir;
        }
        size = 1024;
        registers = test_reg_dir;
    }

    apply {
        reg_match_dir.apply();
        ig_intr_tm_md.bypass_egress = true;
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
