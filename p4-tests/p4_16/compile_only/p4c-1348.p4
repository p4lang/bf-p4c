#include <tna.p4>       /* TOFINO1_ONLY */

header data_h {
  bit<32> da;
  bit<32> db;
}

struct headers_t {
  data_h data;
}

header mirror_meta_h {
  bit<8> src;
  bit<8> type;
  bit<16> session_id;
}

struct user_metadata_t {
  bit<8> src;
  bit<8> type;
  bit<10> session_id;
}

parser NestedParser (
    packet_in pkt,
    inout headers_t hdr) {
    state start {
        transition parse_nested;
    }

    state parse_nested {
        pkt.extract(hdr.data);
        transition accept;
    }
}

parser InParser(
    packet_in pkt,
    out headers_t hdr,
    out user_metadata_t md,
    out ingress_intrinsic_metadata_t ig_intr_md) {

    NestedParser() nestedParser;

    state start {
        nestedParser.apply(pkt, hdr);
        transition accept;
    }
}


control SwitchIngress(
    inout headers_t hdr,
    inout user_metadata_t md,
    in ingress_intrinsic_metadata_t ig_intr_md,
    in ingress_intrinsic_metadata_from_parser_t ig_intr_md_from_prsr,
    inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprsr_md,
    inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {

    action m_action(bit<8> src, bit<8> type, bit<10> session_id) {
	md.src = src;
	md.type = type;
	md.session_id = session_id;
    }

    action nop() {
    }
    table t {
        actions = { nop; m_action; }
        key = { hdr.data.db : exact; }
    }
    apply {
        t.apply();
    }
}

control SwitchIngressDeparser(
    packet_out pkt, 
    inout headers_t hdr,
    in user_metadata_t meta,
    in ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr) {
    Mirror() mirror;
    apply {
	if (ig_intr_md_for_dprsr.mirror_type == 3w1) {
	    mirror_meta_h md = {
	        meta.src,
		meta.type,
		(bit<16>)meta.session_id
	    };
	    mirror.emit(meta.session_id, md);
	}
        pkt.emit(hdr);
    }
}

parser EgParser(
    packet_in pkt, 
    out headers_t hdr,
    out user_metadata_t md,
    out egress_intrinsic_metadata_t ig_intr_md) {  
  state start {
    pkt.extract(hdr.data);
    transition accept;
  }
}

control SwitchEgress(
    inout headers_t hdr,
    inout user_metadata_t md,
    in egress_intrinsic_metadata_t eg_intr_md,
    in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_parser,
    inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
    inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport) {
    apply {} 
}

control SwitchEgressDeparser(
    packet_out pkt,
    inout headers_t hdr,
    in user_metadata_t md,
    in egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr) {
    apply {
        pkt.emit(hdr);
    }
}

Pipeline(InParser(), SwitchIngress(), SwitchIngressDeparser(),
        EgParser(), SwitchEgress(), SwitchEgressDeparser()) pipe0;

Switch(pipe0) main;