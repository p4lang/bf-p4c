#include <core.p4>
#if __TARGET_TOFINO__ == 2
#include <t2na.p4>
#elif __TARGET_TOFINO__ == 1
#include <tna.p4>
#endif 
header sample_h{
    bit<16> a;
    bit<16> b;
    bit<16> c;
    bit<16> csum;
}

struct headers_t{
    sample_h sample1;
    sample_h sample2;
}

struct metadata_t{
    bit<1> zeros_as_one_en;
    bit<1> no_zeros_as_one_en;
    bit<16> meta_residual;
    bool meta_verify;
}

parser IgParser(packet_in packet,
                out headers_t hdr,
                out metadata_t meta,
                out ingress_intrinsic_metadata_t ig_intr_md) {

    Checksum() sample1_verification;
    state start {
        packet.extract(ig_intr_md);
        packet.advance(PORT_METADATA_SIZE);
        transition parse_sample;
    }
    state parse_sample {
        packet.extract(hdr.sample1);
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
    action set_zeros_as_ones() {
        meta.zeros_as_one_en = 1;
        meta.no_zeros_as_one_en = 0;
    }
    action set_no_zeros_as_ones() {
        meta.zeros_as_one_en = 0;
        meta.no_zeros_as_one_en = 1;
    }
    table test {
        key = { hdr.sample1.a : exact;}
        actions = { act; }
        default_action = act();
    }
    table test_zeros_as_ones {
        key = { hdr.sample1.a : exact;}
        actions = {set_zeros_as_ones;
                   set_no_zeros_as_ones;}
    }
    apply {
       test.apply();
       test_zeros_as_ones.apply();
    }
}

control IgDeparser(packet_out packet,
                   inout headers_t hdr,
                   in metadata_t meta,
                   in ingress_intrinsic_metadata_for_deparser_t standard_metadata) {

    Checksum() sample1_checksum_zeros_as_ones;
    Checksum() sample1_checksum;
    apply {
        // update adds up to ffff
        if (meta.zeros_as_one_en == 1) {
            hdr.sample1.csum = sample1_checksum_zeros_as_ones.update({hdr.sample1.a,
                                                                      hdr.sample1.b,
                                                                      hdr.sample2}, true);
        }
        if (meta.no_zeros_as_one_en == 1) {
            hdr.sample1.csum = sample1_checksum.update({hdr.sample1.a,
                                                        hdr.sample1.b,
                                                        hdr.sample2});
        }
        packet.emit(hdr.sample1);
        packet.emit(hdr.sample2);
    }
}

parser EgParser(packet_in pkt,
                out headers_t hdr,
                out metadata_t md,
                out egress_intrinsic_metadata_t eg_intr_md) {

    state start {
        pkt.extract(eg_intr_md);
        pkt.extract(hdr.sample1);
        pkt.extract(hdr.sample2);
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

control EgDeparser(packet_out pkt,
                   inout headers_t hdr,
                   in metadata_t md,
                   in egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr) {

    apply {
        pkt.emit(hdr.sample1);
        pkt.emit(hdr.sample2);
    }
}

Pipeline(IgParser(),
        Ingress(),
        IgDeparser(),
        EgParser(),
        Egress(),
        EgDeparser()) pipe0;

Switch(pipe0) main;
