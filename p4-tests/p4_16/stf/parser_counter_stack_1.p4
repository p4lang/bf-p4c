#include "t2na.p4"

struct metadata {
}

header data_t {
    bit<16> f;
}

struct headers {
    data_t data;
}

parser ParserImpl(packet_in pkt,
                  out headers hdr,
                  out metadata meta,
                  out ingress_intrinsic_metadata_t ig_intr_md) {
    ParserCounter() pctr;

    state start {
        pkt.extract(ig_intr_md);
        pkt.advance(PORT_METADATA_SIZE);

        pctr.set(pkt.lookahead<bit<8>>());  // load total option length
        pkt.advance(8);
        transition next_option;
    }

    @dont_unroll
    state next_option {
        transition select(pctr.is_zero()) {
            true : accept;
            default : next_option_part2;
        }
    }

    state next_option_part2 {
        bit<8> tlv_type = pkt.lookahead<bit<8>>();
        transition select(tlv_type) {
            0x88: parse_tlv;
            default: skip_tlv;
        }
    }

    state parse_tlv {
        pkt.advance(16);
        pkt.extract(hdr.data);
        pctr.decrement(4);
        transition next_option;
    }

    state skip_tlv {
        pctr.push(pkt.lookahead<bit<16>>()[7:0], true);  // load length
        transition skip_tlv_loop;
    }

    state skip_tlv_loop {
        pkt.advance(8);
        pctr.decrement(1);
        transition select(pctr.is_zero()) {
            true: skip_tlv_done;
            false: skip_tlv_loop;
        }
    }

    state skip_tlv_done {
        pctr.pop();
        transition next_option;
    }
}

control ingress(inout headers hdr, inout metadata meta,
                in ingress_intrinsic_metadata_t ig_intr_md,
                in ingress_intrinsic_metadata_from_parser_t ig_intr_prsr_md,
                inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md,
                inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {
    apply {
        ig_intr_tm_md.ucast_egress_port = 2;
    }
}

control ingressDeparser(packet_out packet, inout headers hdr, in metadata meta,
                        in ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprs) {
    apply {
        packet.emit(hdr);
    }
}

parser egressParser(packet_in packet, out headers hdr, out metadata meta,
                    out egress_intrinsic_metadata_t eg_intr_md) {
    state start {
        packet.extract(eg_intr_md);
        transition accept;
    }
}

control egress(inout headers hdr, inout metadata meta, in egress_intrinsic_metadata_t eg_intr_md,
               in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr,
               inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprs,
               inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport) {
    apply { }
}

control egressDeparser(packet_out packet, inout headers hdr, in metadata meta,
                       in egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprs) {
    apply { }
}

Pipeline(ParserImpl(), ingress(), ingressDeparser(), egressParser(), egress(), egressDeparser()) pipe;

Switch(pipe) main;
