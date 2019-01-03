#include <core.p4>
#include <tofino.p4>
#include <tna.p4>

action do_nothing() {
}
typedef bit<8> inthdr_type_t;
const inthdr_type_t INTHDR_TYPE_BRIDGE = 8w0xfc;
const inthdr_type_t INTHDR_TYPE_CLONE_INGRESS = 8w0xfd;
const inthdr_type_t INTHDR_TYPE_CLONE_EGRESS = 8w0xfe;
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
        ig_md.unknown_pkt_err = 1w0;
        hdr.bridged_meta.hdr_type = 8w0xfc;
        hdr.bridged_meta.setValid();
        packet.extract<ingress_intrinsic_metadata_t>(ig_intr_md);
        packet.advance(32w64);
        transition reject;
    }
    state unknown_packet_err {
        ig_md.unknown_pkt_err = 1w1;
        transition accept;
    }
}

parser eg_parser(packet_in packet, out headers_t hdr, out local_metadata_t eg_md, out egress_intrinsic_metadata_t eg_intr_md) {
    state start {
        eg_md.mirrored_meta.hdr_type = 8w0xfe;
        packet.extract<egress_intrinsic_metadata_t>(eg_intr_md);
        transition reject;
    }
}

parser egress_parser(packet_in packet, out headers_t hdr, out local_metadata_t eg_md, out egress_intrinsic_metadata_t eg_intr_md) {
    eg_parser() _eg_parser;
    state start {
        _eg_parser.apply(packet, hdr, eg_md, eg_intr_md);
        transition accept;
    }
}

control ingress_control(inout headers_t hdr, inout local_metadata_t ig_md, in ingress_intrinsic_metadata_t ig_intr_md, in ingress_intrinsic_metadata_from_parser_t ig_prsr_md, inout ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md, inout ingress_intrinsic_metadata_for_tm_t ig_tm_md) {
    action some_action(bit<1> aFlag, bit<1> anotherFlag, bit<16> a_field, bit<4> next_table_id) {
        hdr.bridged_meta.aFlag = hdr.bridged_meta.aFlag | aFlag;
        hdr.bridged_meta.a_field = a_field;
        hdr.bridged_meta.anotherFlag = hdr.bridged_meta.anotherFlag | anotherFlag;
        hdr.bridged_meta.next_table_id = next_table_id;
    }
    table some_table {
        actions = {
            some_action();
            @defaultonly NoAction();
        }
        default_action = NoAction();
    }
    apply {
        some_table.apply();
    }
}

control ingress_deparser(packet_out packet, inout headers_t hdr, in local_metadata_t ig_md, in ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md) {
    apply {
        packet.emit<headers_t>(hdr);
    }
}

control egress_control(inout headers_t hdr, inout local_metadata_t eg_md, in egress_intrinsic_metadata_t eg_intr_md, in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr, inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr, inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport) {
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

