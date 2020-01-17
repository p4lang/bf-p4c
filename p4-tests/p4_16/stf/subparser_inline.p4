#include <core.p4> 
#include <tna.p4>       /* TOFINO1_ONLY */

header data_h {
    bit<32> a;
    bit<32> b;
    bit<32> c;
    bit<32> d;
}

struct headers_t {
    data_h data;
}

struct metadata_t{

}

header ingress_skip_t {
    bit<64> pad;
}

parser SubParser(packet_in pkt, inout headers_t hdr, out metadata_t meta) {
    @critical
    state start {
        pkt.extract(hdr.data);
        transition accept;
    }
}

parser IgParser(packet_in packet, out headers_t hdr, out metadata_t meta,
                 out ingress_intrinsic_metadata_t ig_intr_md) {
   SubParser() subparser;

   ingress_skip_t skip;
   state start {
       packet.extract(ig_intr_md);
       packet.extract(skip);

       subparser.apply(packet, hdr, meta);

       transition accept;
   }
}
control Ingress(inout headers_t hdr,
                inout metadata_t meta,
                in ingress_intrinsic_metadata_t ig_intr_md,
        in ingress_intrinsic_metadata_from_parser_t ig_intr_prsr_md,
        inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprsr_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {
    action act(bit<9> port) {ig_intr_tm_md.ucast_egress_port = port;}
    table test {
        actions = { act; }
        default_action = act(1);
    }
    apply {test.apply();}
}

control IgDeparser(packet_out packet,
                   inout headers_t hdr,
                   in metadata_t meta,
                   in ingress_intrinsic_metadata_for_deparser_t standard_metadata) {
   apply {
       packet.emit(hdr.data);
   }
}
parser EgParser(
    packet_in packet, 
    out headers_t hdr,
    out metadata_t meta,
    out egress_intrinsic_metadata_t eg_intr_md) {

    SubParser() subparser;

    state start {
        packet.extract(eg_intr_md);

        subparser.apply(packet, hdr, meta);

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
    apply{
        pkt.emit(hdr.data);
    }
}

Pipeline(IgParser(),
       Ingress(),
       IgDeparser(),
       EgParser(),
       Egress(),
       EgDeparser()) pipe0;

Switch(pipe0) main;
