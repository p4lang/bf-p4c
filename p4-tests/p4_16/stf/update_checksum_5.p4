#include <t2na.p4>

header choice_t {
    bit <8> c;
}
header data_t {
    bit<16> f1;
    bit<16>  f2;
    bit<16> f3;
    bit<16> csum1;
}

struct metadata_t {
}

struct headers_t {
    choice_t choice;
    data_t data;
    data_t data1;
}

parser IgParser(packet_in packet,
                out headers_t hdr,
                out metadata_t meta,
                out ingress_intrinsic_metadata_t ig_intr_md) {
    state start {
        packet.extract(ig_intr_md);
        packet.advance(PORT_METADATA_SIZE);
        packet.extract(hdr.choice);
        transition select(hdr.choice.c) {
            0xa : parse_data0;
            0xb : parse_data1;
        }
    }
    state parse_data0 {
        packet.extract(hdr.data);
        transition accept;
    }
    state parse_data1 {
        packet.extract(hdr.data1);
        packet.extract(hdr.data);
        transition accept;
    }
}

control Ingress(inout headers_t hdr,
                inout metadata_t meta,
                in ingress_intrinsic_metadata_t ig_intr_md,
                in ingress_intrinsic_metadata_from_parser_t ig_intr_prsr_md,
                inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprsr_md,
                inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {

    action act() {
        ig_intr_tm_md.ucast_egress_port = 1;
    }
    apply{
        act();
    }
}

control IgDeparser(packet_out packet,
                   inout headers_t hdr,
                   in metadata_t meta,
                   in ingress_intrinsic_metadata_for_deparser_t standard_metadata) {
    Checksum() checksum_0;
    apply {
        hdr.data.csum1 = checksum_0.update({ hdr.data.f1, hdr.data.f2, hdr.data.f3});
        packet.emit(hdr.choice);
        packet.emit(hdr.data1); 
        packet.emit(hdr.data);
    }
}

parser EgParser(packet_in packet,
                out headers_t hdr,
                out metadata_t md,
                out egress_intrinsic_metadata_t eg_intr_md) {

    state start {
        packet.extract(eg_intr_md);
        packet.extract(hdr.choice);
        transition select(hdr.choice.c) {
            0xa : parse_data0;
            0xb : parse_data1;
        }
    }
    state parse_data0 {
        packet.extract(hdr.data);
        transition accept;
    }
    state parse_data1 {
        packet.extract(hdr.data1);
        packet.extract(hdr.data);
        transition accept;
    }
}

control Egress(inout headers_t hdr,
               inout metadata_t md,
               in egress_intrinsic_metadata_t eg_intr_md,
               in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_parser,
               inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
               inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport) {
    apply {}
}

control EgDeparser(packet_out packet,
                   inout headers_t hdr,
                   in metadata_t md,
                   in egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr) {
    Checksum() checksum_0;
    Checksum() checksum_1;
    apply {
        packet.emit(hdr.choice);
        packet.emit(hdr.data1);
        packet.emit(hdr.data);
    }
}

Pipeline(IgParser(),
        Ingress(),
        IgDeparser(),
        EgParser(),
        Egress(),
        EgDeparser()) pipe0;

Switch(pipe0) main;
