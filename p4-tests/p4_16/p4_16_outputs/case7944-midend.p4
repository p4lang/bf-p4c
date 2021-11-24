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

typedef bit<8> inthdr_type_t;
header mirror_meta_hdr_t {
    inthdr_type_t hdr_type;
    bit<16>       pad0;
}

header bridged_meta_hdr_t {
    inthdr_type_t hdr_type;
    bit<1>        aFlag;
    bit<1>        anotherFlag;
    bit<4>        next_table_id;
    bit<2>        pad1;
    bit<16>       a_field;
    bit<16>       another_field;
}

struct local_metadata_t {
    bit<1>            unknown_pkt_err;
    bit<1>            do_clone;
    bit<6>            pad0;
    mirror_meta_hdr_t mirrored_meta;
}

struct headers_t {
    bridged_meta_hdr_t bridged_meta;
}

parser ingress_parser(packet_in packet, out headers_t hdr, out local_metadata_t ig_md, out ingress_intrinsic_metadata_t ig_intr_md) {
    state start {
        hdr.bridged_meta.setValid();
        packet.extract<ingress_intrinsic_metadata_t>(ig_intr_md);
        packet.advance(32w64);
        transition reject;
    }
}

parser egress_parser(packet_in packet, out headers_t hdr, out local_metadata_t eg_md, out egress_intrinsic_metadata_t eg_intr_md) {
    bridged_meta_hdr_t hdr_0_bridged_meta;
    mirror_meta_hdr_t eg_md_0_mirrored_meta;
    egress_intrinsic_metadata_t eg_intr_md_0;
    state start {
        hdr_0_bridged_meta.setInvalid();
        eg_md_0_mirrored_meta.setInvalid();
        eg_intr_md_0.setInvalid();
        packet.extract<egress_intrinsic_metadata_t>(eg_intr_md_0);
        transition reject;
    }
}

control ingress_control(inout headers_t hdr, inout local_metadata_t ig_md, in ingress_intrinsic_metadata_t ig_intr_md, in ingress_intrinsic_metadata_from_parser_t ig_prsr_md, inout ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md, inout ingress_intrinsic_metadata_for_tm_t ig_tm_md) {
    @name(".NoAction") action NoAction_0() {
    }
    @name("ingress_control.some_action") action some_action(bit<1> aFlag, bit<1> anotherFlag, bit<16> a_field, bit<4> next_table_id) {
        hdr.bridged_meta.aFlag = hdr.bridged_meta.aFlag | aFlag;
        hdr.bridged_meta.a_field = a_field;
        hdr.bridged_meta.anotherFlag = hdr.bridged_meta.anotherFlag | anotherFlag;
        hdr.bridged_meta.next_table_id = next_table_id;
    }
    @name("ingress_control.some_table") table some_table_0 {
        actions = {
            some_action();
            @defaultonly NoAction_0();
        }
        default_action = NoAction_0();
    }
    apply {
        some_table_0.apply();
    }
}

control ingress_deparser(packet_out packet, inout headers_t hdr, in local_metadata_t ig_md, in ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md) {
    @hidden action act() {
        packet.emit<bridged_meta_hdr_t>(hdr.bridged_meta);
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

control egress_control(inout headers_t hdr, inout local_metadata_t eg_md, in egress_intrinsic_metadata_t eg_intr_md, in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr, inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr, inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport) {
    @name(".do_nothing") action do_nothing() {
    }
    @hidden table tbl_do_nothing {
        actions = {
            do_nothing();
        }
        const default_action = do_nothing();
    }
    apply {
        tbl_do_nothing.apply();
    }
}

control egress_deparser(packet_out packet, inout headers_t hdr, in local_metadata_t eg_md, in egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr) {
    @hidden action act_0() {
        packet.emit<bridged_meta_hdr_t>(hdr.bridged_meta);
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

Pipeline<headers_t, local_metadata_t, headers_t, local_metadata_t>(ingress_parser(), ingress_control(), ingress_deparser(), egress_parser(), egress_control(), egress_deparser()) pipeline;

Switch<headers_t, local_metadata_t, headers_t, local_metadata_t, _, _, _, _, _, _, _, _, _, _, _, _>(pipeline) main;
