#include <core.p4> 
#include <tna.p4>       /* TOFINO1_ONLY */

header sample_h{
    bit<16> a;
    bit<16> b;
    bit<16> c;
    bit<16> csum1;
    bit<16> csum2;
}

struct headers_t{
   sample_h sample;

}

struct metadata_t{
 bool csum1;
 bool csum2;
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
        packet.extract(hdr.sample);
        
        transition accept;
    }
}
control Ingress(inout headers_t hdr, inout metadata_t meta, in ingress_intrinsic_metadata_t ig_intr_md,
        in ingress_intrinsic_metadata_from_parser_t ig_intr_prsr_md,
        inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprsr_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {
   action act1() {
      ig_intr_tm_md.ucast_egress_port = 2;
      meta.csum1 = true;
      meta.csum2 = true;
   }

   table test {
      actions = { act1;NoAction; }
      key = { hdr.sample.a: exact; }
      default_action = act1();
   }

   apply {
      test.apply();
    }
}

control IgDeparser(packet_out packet, inout headers_t hdr,in metadata_t meta, in ingress_intrinsic_metadata_for_deparser_t standard_metadata) {
    Checksum() deparser_checksum1;
    Checksum() deparser_checksum2;
    apply {
        if(meta.csum1) {
	    hdr.sample.csum1 = deparser_checksum1.update({hdr.sample.a, hdr.sample.b, hdr.sample.c, hdr.sample.csum1 });
 	}
	if(!meta.csum2) {
	    hdr.sample.csum2 = deparser_checksum2.update({hdr.sample.a, hdr.sample.b, hdr.sample.c, hdr.sample.csum2 });
 	}
        packet.emit(hdr.sample);
    }
}
parser EgParser(
    packet_in pkt, 
    out headers_t hdr,
    out metadata_t md,
    out egress_intrinsic_metadata_t eg_intr_md) {
	state start {
        pkt.extract(eg_intr_md);
        pkt.extract(hdr.sample);
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
	    pkt.emit(hdr.sample);
	}
}

Pipeline(IgParser(),
        Ingress(),
        IgDeparser(),
        EgParser(),
        Egress(),
        EgDeparser()) pipe0;

Switch(pipe0) main;
