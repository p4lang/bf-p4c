
#include <core.p4>
#include <tna.p4>

header data_t {
    bit<8> r1; 
    bit<8> r2; 
    bit<16> r3; 
    bit<8> b1;
    bit<8> b2;
    bit<8> b3;
}

struct metadata {
}

struct headers {
    data_t data;
}

parser ParserI(packet_in b,
               out headers hdr,
               out metadata meta,
               out ingress_intrinsic_metadata_t ig_intr_md) {
    state start {
        b.extract(ig_intr_md);
        b.advance(PORT_METADATA_SIZE);
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



    action set_port(PortId_t port) {
        ig_intr_tm_md.ucast_egress_port = port;
    }

    table set_metadata {
        key = { hdr.data.r1 : ternary; }
        actions = { set_port; }
    }

    action nop() {}

    action act(bit<8> b1) {
        hdr.data.b1 = b1;
    }

    table case1 {
        actions = { act; @defaultonly nop; }
        key = { hdr.data.r1 : ternary;
                hdr.data.r2 : ternary;
                hdr.data.r3 : ternary; }
        
        const entries = {
            (0xff, _, _) : act(0x1);
            (_, 0xff, _) : act(0x2);
            (_, _, 0xffff) : act(0x3);
            (_, _, _) : act(0x4);
        }
        size = 4;
        default_action = nop;
    }


    apply {
        set_metadata.apply();
        case1.apply();
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
        b.extract(eg_intr_md);
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
