#include <core.p4>
#if __TARGET_TOFINO__ >= 2
#include <t2na.p4>
#elif __TARGET_TOFINO__ == 1
#include <tna.p4>
#endif
header sample_h {
    bit<4> a;
    bit<4> b;
    bit<4> c;
    bit<4> d;
    bit<4> e;
    bit<4> f;
    bit<16> csum;
}
struct headers_t {
    sample_h sample1;
    sample_h sample2;
    sample_h sample3;
}

struct metadata_t {
    bit<5> aa;
}

parser IgParser(packet_in packet,
                out headers_t hdr,
                out metadata_t meta,
                out ingress_intrinsic_metadata_t ig_intr_md) {
    state start {
        packet.extract(ig_intr_md);
        packet.advance(PORT_METADATA_SIZE);
        packet.extract(hdr.sample1);
        meta.aa = 5;
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
    Checksum() sample1_checksum;
    apply {
        hdr.sample1.csum = sample1_checksum.update({hdr.sample1.a,
                                                    hdr.sample1.b,
                                                    hdr.sample1.c,
                                                    hdr.sample1.f,
                                                    hdr.sample1.e,
                                                    hdr.sample1.d
                                                   });
        packet.emit(hdr.sample1);
    }

}

parser EgParser(packet_in packet,
                out headers_t hdr,
                out metadata_t md,
                out egress_intrinsic_metadata_t eg_intr_md) {
    state start {
        packet.extract(eg_intr_md);
        packet.extract(hdr.sample1);
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

    apply {
        packet.emit(hdr.sample1);
    }
}

Pipeline(IgParser(),
        Ingress(),
        IgDeparser(),
        EgParser(),
        Egress(),
        EgDeparser()) pipe0;

Switch(pipe0) main;
