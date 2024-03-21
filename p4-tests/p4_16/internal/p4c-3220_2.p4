/* -*- P4_16 -*- */

#include <core.p4>
#include <tna.p4>

struct metadata { }

struct value_t {
    bit<8> b1;
    bit<8> b2;
}
/*
typedef bit<8> value_t;
*/

typedef bit<8> index_t;

header data_t {
    bit<8> key;
    value_t wr;
    bit<8> rd;
}

struct headers {
    data_t data;
}

parser ParserImpl(packet_in packet, out headers hdr,
                  out metadata meta,
                  out ingress_intrinsic_metadata_t ig_intr_md) {
    state start {
        value_t tmp;
        packet.extract(ig_intr_md);
        packet.advance(PORT_METADATA_SIZE);
        packet.extract(hdr.data);
        transition accept;
    }
}

control ingress(
    /* User */
    inout headers hdr,
    inout metadata meta,
    /* Intrinsic */
    in    ingress_intrinsic_metadata_t               ig_intr_md,
    in    ingress_intrinsic_metadata_from_parser_t   ig_prsr_md,
    inout ingress_intrinsic_metadata_for_deparser_t  ig_dprsr_md,
    inout ingress_intrinsic_metadata_for_tm_t        ig_tm_md)
{
    Register<value_t, index_t>(256) reg;
    RegisterAction<value_t, index_t, bit<8>>(reg) reg_read1 = {
        void apply(inout value_t register_data, out bit<8> result) {
            result = register_data.b1;
        }
    };
    RegisterAction<value_t, index_t, bit<8>>(reg) reg_read2 = {
        void apply(inout value_t register_data, out bit<8> result) {
            result = register_data.b2;
        }
    };

    action write_action(index_t index) {
        reg.write(index, hdr.data.wr);
    }

    action read_action1(index_t index) {
        hdr.data.rd = reg_read1.execute(index);
    }

    action read_action2(index_t index) {
        hdr.data.rd = reg_read2.execute(index);
    }

    table test_table {
        key = {
            hdr.data.key : exact;
        }
        actions = {
            write_action;
            read_action1;
            read_action2;
        }
        size = 256;
    }

    apply {
        if (hdr.data.isValid()) {
            test_table.apply();
        }
        ig_tm_md.ucast_egress_port = ig_intr_md.ingress_port;
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
    apply {
    }
}

control egressDeparser(packet_out packet, inout headers hdr, in metadata meta,
                       in egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprs) {
    apply {
    }
}

Pipeline(ParserImpl(), ingress(), ingressDeparser(),
         egressParser(), egress(), egressDeparser()) pipe;
Switch(pipe) main;
