#include <core.p4>
#include <tna.p4>
header sample_h {
    bit<16> a;
    bit<16> b;
    bit<16> c;
    bit<16> csum;
}
struct headers_t {
    sample_h type;
    sample_h exclusive;
    sample_h sample1;
    sample_h sample2;
}

struct metadata_t {
}

parser IgParser(packet_in packet,
                out headers_t hdr,
                out metadata_t meta,
                out ingress_intrinsic_metadata_t ig_intr_md) {
    state start {
        packet.extract(ig_intr_md);
        packet.advance(PORT_METADATA_SIZE);
	packet.extract(hdr.type);
	transition select(hdr.type.a) {
            0x8888 : parse_sample_1;
            0x4444 : parse_not_so_exclusive;
        }
    }
    state parse_not_so_exclusive {
        packet.extract(hdr.exclusive);
	transition accept;
    }
    state parse_sample_1 {
        packet.extract(hdr.sample1);
        transition select(hdr.sample1.a) {
            0x1111 : parse_sample_2;
        }
    }
    state parse_sample_2 {
        packet.extract(hdr.sample2);
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

    action add_sample_1() {
        hdr.sample1.setValid();
        hdr.sample1.a = 0x2222;
        hdr.sample1.b = 0x1111;
	hdr.sample1.c = 0x0000;
    }

    apply{
        act();
        if (hdr.exclusive.isValid()) {
            add_sample_1();
        }
    }
}

control IgDeparser(packet_out packet,
                   inout headers_t hdr,
                   in metadata_t meta,
                   in ingress_intrinsic_metadata_for_deparser_t standard_metadata) {
    Checksum() sample1_checksum;
    apply {
        hdr.sample1.csum = sample1_checksum.update({hdr.sample1.a, hdr.sample2});
	packet.emit(hdr.type);
        packet.emit(hdr.sample1);
        packet.emit(hdr.sample2);
	packet.emit(hdr.exclusive);
    }

}

parser EgParser(packet_in packet,
                out headers_t hdr,
                out metadata_t md,
                out egress_intrinsic_metadata_t eg_intr_md) {
    state start {
        packet.extract(eg_intr_md);
	packet.extract(hdr.type);
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

    apply {packet.emit(hdr.type);}
}

Pipeline(IgParser(),
        Ingress(),
        IgDeparser(),
        EgParser(),
        Egress(),
        EgDeparser()) pipe0;

Switch(pipe0) main;
