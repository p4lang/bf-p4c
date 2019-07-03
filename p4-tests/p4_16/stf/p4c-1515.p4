#include <core.p4> 
#include <tna.p4>
header sample_h{
    bit<16> a;
    bit<16> b;
    bit<16> c;
    bit<16> csum;
}
header sample2_h{
    bit<16> a;
}

struct headers_t{
    sample_h sample1;
    sample2_h sample2;
    sample2_h sample3;

}

struct metadata_t{
    bit<16> sample1_checksum;
}

header ingress_skip_t {
    bit<64> pad;
}

parser IgParser(packet_in packet, out headers_t hdr, out metadata_t meta,
                  out ingress_intrinsic_metadata_t ig_intr_md) {

    ingress_skip_t skip;
    state start {
        packet.extract(ig_intr_md);
        packet.extract(skip);
        packet.extract(hdr.sample1);
        transition select(hdr.sample1.a) {
            0x1111 : parse_sample_2;
            0x2222 : parse_sample_3;
        }
    }
    state parse_sample_2 {
        packet.extract(hdr.sample2);
        transition accept;
    }
    state parse_sample_3 {
        packet.extract(hdr.sample3);
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
    Checksum() sample1_checksum;
    apply {
        if (hdr.sample2.isValid()) {
            hdr.sample1.csum = sample1_checksum.update({
                                                        hdr.sample1.a,
                                                        hdr.sample1.b,
                                                        hdr.sample1.c,
                                                        hdr.sample2.a
                                                        });
        }
        if (hdr.sample3.isValid()) {
            hdr.sample1.csum = sample1_checksum.update({
                                                        hdr.sample1.a,
                                                        hdr.sample1.b,
                                                        hdr.sample1.c,
                                                        hdr.sample3.a
                                                        });
        }
        packet.emit(hdr.sample1);
        packet.emit(hdr.sample2);
        packet.emit(hdr.sample3);
    }
}
parser EgParser(
    packet_in packet, 
    out headers_t hdr,
    out metadata_t md,
    out egress_intrinsic_metadata_t eg_intr_md) {
    state start {
        packet.extract(eg_intr_md);
        packet.extract(hdr.sample1);
        transition select(hdr.sample1.a) {
            0x1111 : parse_sample_2;
            0x2222 : parse_sample_3;
       }
    }
    state parse_sample_2 {
        packet.extract(hdr.sample2);
        transition accept;
    }   
    state parse_sample_3 {
        packet.extract(hdr.sample3);
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
        pkt.emit(hdr.sample3);
    }
}

Pipeline(IgParser(),
        Ingress(),
        IgDeparser(),
        EgParser(),
        Egress(),
        EgDeparser()) pipe0;

Switch(pipe0) main;

