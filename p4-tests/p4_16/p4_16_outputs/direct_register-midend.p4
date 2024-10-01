#include <tna.p4>

struct tuple_0 {
    bit<8> field;
    bit<8> field_0;
    bit<8> field_1;
    bit<8> field_2;
    bit<8> field_3;
    bit<8> field_4;
    bit<8> field_5;
    bit<8> field_6;
    bit<8> field_7;
    bit<8> field_8;
    bit<8> field_9;
    bit<8> field_10;
    bit<8> field_11;
    bit<8> field_12;
    bit<8> field_13;
    bit<8> field_14;
}
#include <tna.p4>

header data_t {
    bit<32> max_counter;
    bit<8>  v;
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

control IngressP(inout headers hdr, inout metadata meta, in ingress_intrinsic_metadata_t ig_intr_md, in ingress_intrinsic_metadata_from_parser_t ig_intr_prsr_md, inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md, inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {
    @hidden action act() {
        ig_intr_tm_md.ucast_egress_port = ig_intr_md.ingress_port;
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

control DeparserI(packet_out b, inout headers hdr, in metadata meta, in ingress_intrinsic_metadata_for_deparser_t ig_intr_dprsr_md) {
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

parser ParserE(packet_in b, out headers hdr, out metadata meta, out egress_intrinsic_metadata_t eg_intr_md) {
    state start {
        b.extract<data_t>(hdr.data);
        transition accept;
    }
}

control EgressP(inout headers hdr, inout metadata meta, in egress_intrinsic_metadata_t eg_intr_md, in egress_intrinsic_metadata_from_parser_t eg_intr_prsr_md, inout egress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md, inout egress_intrinsic_metadata_for_output_port_t eg_intr_oport_md) {
    @name(".NoAction") action NoAction_0() {
    }
    @name("EgressP.port_pkts_reg") DirectRegister<bit<32>>() port_pkts_reg_0;
    @name("EgressP.port_pkts_alu") DirectRegisterAction<bit<32>, bit<8>>(port_pkts_reg_0) port_pkts_alu_0 = {
        void apply(inout bit<32> value, out bit<8> read_value) {
            if (value < hdr.data.max_counter) {
                value = value + 32w1;
                read_value = 8w0;
            }
            else {
                value = 32w0;
                read_value = 8w1;
            }
        }
    };
    @name("EgressP.execute_port_pkts_alu") action execute_port_pkts_alu() {
        port_pkts_alu_0.execute();
    }
    @name("EgressP.t_port_pkts_alu") table t_port_pkts_alu_0 {
        key = {
            eg_intr_md.egress_port: exact @name("eg_intr_md.egress_port") ;
        }
        actions = {
            execute_port_pkts_alu();
            @defaultonly NoAction_0();
        }
        default_action = NoAction_0();
        registers = port_pkts_reg_0;
    }
    apply {
        t_port_pkts_alu_0.apply();
    }
}

control DeparserE(packet_out b, inout headers hdr, in metadata meta, in egress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md) {
    @hidden action act_1() {
        b.emit<data_t>(hdr.data);
    }
    @hidden table tbl_act_1 {
        actions = {
            act_1();
        }
        const default_action = act_1();
    }
    apply {
        tbl_act_1.apply();
    }
}

Pipeline<headers, metadata, headers, metadata>(ParserI(), IngressP(), DeparserI(), ParserE(), EgressP(), DeparserE()) pipe0;

Switch<headers, metadata, headers, metadata, _, _, _, _, _, _, _, _, _, _, _, _>(pipe0) main;
