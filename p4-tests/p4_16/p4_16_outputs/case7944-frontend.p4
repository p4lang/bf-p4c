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
    headers_t hdr_0;
    local_metadata_t eg_md_0;
    egress_intrinsic_metadata_t eg_intr_md_0;
    state start {
        hdr_0.bridged_meta.setInvalid();
        eg_md_0.mirrored_meta.setInvalid();
        eg_intr_md_0.setInvalid();
        transition eg_parser_start;
    }
    state eg_parser_start {
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
    apply {
        packet.emit<headers_t>(hdr);
    }
}

control egress_control(inout headers_t hdr, inout local_metadata_t eg_md, in egress_intrinsic_metadata_t eg_intr_md, in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr, inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr, inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport) {
    @name(".do_nothing") action do_nothing() {
    }
    apply {
        do_nothing();
    }
}

control egress_deparser(packet_out packet, inout headers_t hdr, in local_metadata_t eg_md, in egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr) {
    apply {
        packet.emit<headers_t>(hdr);
    }
}

Pipeline<headers_t, local_metadata_t, headers_t, local_metadata_t>(ingress_parser(), ingress_control(), ingress_deparser(), egress_parser(), egress_control(), egress_deparser()) pipeline;

Switch<headers_t, local_metadata_t, headers_t, local_metadata_t, _, _, _, _, _, _, _, _, _, _, _, _>(pipeline) main;
