#include <core.p4>
// This test runs on both Tofino 1 and Tofino 2.
// The combination of having tna.p4 and the TOFINO2_ONLY achieves this.
#if __TARGET_TOFINO__ == 2
#include <t2na.p4>  /* TOFINO2_ONLY */
#else
#include <tna.p4>
#endif

@egress_intrinsic_metadata_opt
struct metadata_t {
}

header EthernetHdr_h {
   bit<24> dmacOui;
   bit<24> dmacStation;
   bit<24> smacOui;
   bit<24> smacStation;
}

struct header_t {
   EthernetHdr_h eth;
}

parser SwitchIngressParser(packet_in pkt, out header_t hdr, out metadata_t meta, out ingress_intrinsic_metadata_t ig_intr_md) {
    state start {
        pkt.extract<ingress_intrinsic_metadata_t>(ig_intr_md);
        pkt.advance(PORT_METADATA_SIZE);
        pkt.extract(hdr.eth);
        transition accept;
    }
}

control SwitchIngressDeparser(packet_out pkt, inout header_t hdr, in metadata_t meta, in ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr) {
    apply {
        pkt.emit(hdr.eth);
    }
}

control ingress(inout header_t hdr, inout metadata_t meta, in ingress_intrinsic_metadata_t ig_intr_md, in ingress_intrinsic_metadata_from_parser_t ig_intr_md_from_prsr, inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr, inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm) {
    apply {
       ig_intr_md_for_tm.ucast_egress_port = ig_intr_md.ingress_port;
    }
}

control egress(inout header_t hdr, inout metadata_t meta, in egress_intrinsic_metadata_t eg_intr_md, in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr, inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr, inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport) {

    action te_action() {
       eg_intr_md_for_dprsr.drop_ctl = 7;
    }

    table te {
       key = {
          eg_intr_md.egress_port : exact ;
          eg_intr_md.pkt_length : exact ;
          hdr.eth.dmacOui : exact;
          hdr.eth.dmacStation : exact;
          hdr.eth.smacOui : exact;
          hdr.eth.smacStation : exact;
       }
       actions = {
          te_action;
       }
       size = 1024;
    }
    apply {
       te.apply();
    }
}

parser SwitchEgressParser(packet_in pkt, out header_t hdr, out metadata_t meta, out egress_intrinsic_metadata_t eg_intr_md) {
    state start {
        pkt.extract(eg_intr_md);
        pkt.extract(hdr.eth);
        transition accept;
    }
}

control SwitchEgressDeparser(packet_out pkt, inout header_t hdr, in metadata_t meta, in egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr) {
    apply {
       pkt.emit(hdr.eth);
    }
}

@name(".pipe") Pipeline<header_t, metadata_t, header_t, metadata_t>(SwitchIngressParser(), ingress(), SwitchIngressDeparser(), SwitchEgressParser(), egress(), SwitchEgressDeparser()) pipe;

@name(".main") Switch<header_t, metadata_t, header_t, metadata_t, _, _, _, _, _, _, _, _, _, _, _, _>(pipe) main;

