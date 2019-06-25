#include <core.p4> 
#include <tna.p4>
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
    bit<16> sample1_checksum;
}

header ingress_skip_t {
    bit<64> pad;
}

parser IgParser(packet_in packet, out headers_t hdr, out metadata_t meta,
                  out ingress_intrinsic_metadata_t ig_intr_md) {

    Checksum<bit<16>>(ChecksumAlgorithm_t.CSUM16) sample1_checksum;
    ingress_skip_t skip;
    state start {
        packet.extract(ig_intr_md);
        packet.extract(skip);
        packet.extract(hdr.sample1);
        packet.extract(hdr.sample2);
        sample1_checksum.subtract({hdr.sample1.a, hdr.sample1.b});
        meta.sample1_checksum = sample1_checksum.get();    
        transition accept;
    }
}
control Ingress(inout headers_t hdr, inout metadata_t meta, in ingress_intrinsic_metadata_t ig_intr_md,
        in ingress_intrinsic_metadata_from_parser_t ig_intr_prsr_md,
        inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprsr_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {

  action act(bit<9> port) {ig_intr_tm_md.ucast_egress_port = port;}
  table test {
      actions = { act; }
      key = { hdr.sample1.a: exact; }
      default_action = act(1);
  }
  apply {test.apply();}
}

control IgDeparser(packet_out packet, inout headers_t hdr,in metadata_t meta, in ingress_intrinsic_metadata_for_deparser_t standard_metadata) {
    Checksum<bit<16>>(ChecksumAlgorithm_t.CSUM16) sample1_checksum;
    apply {
        hdr.sample1.csum = sample1_checksum.update({
                                                    hdr.sample1.a,
                                                    hdr.sample1.b,
                                                    hdr.sample2,
                                                    meta.sample1_checksum
                                                    });
        packet.emit(hdr.sample1);
        packet.emit(hdr.sample2);
    }
}
parser EgParser(
    packet_in pkt, 
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

control Egress(
    inout headers_t hdr,
    inout metadata_t md,
    in egress_intrinsic_metadata_t eg_intr_md,
    in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_parser,
    inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
    inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport) {
    apply {} 
}

control EgDeparser(
    packet_out pkt,
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
