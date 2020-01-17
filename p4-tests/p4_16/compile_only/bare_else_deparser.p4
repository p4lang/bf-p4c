#include <tna.p4>

struct mirror_0 {
}

struct metadata {
  MirrorId_t session_id;
}

header ethernet_h {
    bit<48> dmac;
    bit<48> smac;
    bit<16> etype;
}
header ipv6_h {
  bit<4> version;
  bit<6> ds;
  bit<2> ecn;
  bit<20> flow_label;
  bit<16> payload_len;
  bit<8> next_hdr;
  bit<8> hop_limit;
  bit<128> src;
  bit<128> dst;
}

struct headers {
    ethernet_h  ethernet;
    ipv6_h      ipv6;
}

parser iPrsr(packet_in packet, out headers hdr, out metadata meta,
             out ingress_intrinsic_metadata_t ig_intr_md) {
  state start {
    packet.extract(ig_intr_md);
    packet.advance(PORT_METADATA_SIZE);
    packet.extract(hdr.ethernet);
    transition select (hdr.ethernet.etype) {
      0x86DD  : parse_ipv6;
    }
  }
  state parse_ipv6 {
    packet.extract(hdr.ipv6);
    transition accept;
  }
}

control ingress(inout headers hdr, inout metadata md,
                in ingress_intrinsic_metadata_t ig_intr_md,
                in ingress_intrinsic_metadata_from_parser_t ig_intr_prsr_md,
                inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprsr_md,
                inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {

    action send() {
        ig_intr_tm_md.ucast_egress_port = ig_intr_md.ingress_port;
    }
    apply {
        send();
    }
}

control iDprsr(packet_out packet, inout headers hdr, in metadata md,
               in ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprs) {

Mirror() m0;
Mirror() m1;
Mirror() m2;
Resubmit() r0;
Resubmit() r1;
    apply {
       if (ig_intr_md_for_dprs.mirror_type == 1) {
           m2.emit(md.session_id);
       }
       if (ig_intr_md_for_dprs.resubmit_type == 1) {
           r0.emit();
       }
       if (ig_intr_md_for_dprs.mirror_type == 0) {
            m0.emit(md.session_id);
       } else {
            m1.emit(md.session_id);
       }
       
       packet.emit(hdr);
    }
}

parser ePrsr(packet_in packet, out headers hdr, out metadata meta,
             out egress_intrinsic_metadata_t eg_intr_md) {
  state start { transition reject; }
}

control egress(inout headers hdr, inout metadata meta, in egress_intrinsic_metadata_t eg_intr_md,
               in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr,
               inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprs,
               inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport) {
  apply {}
}

control eDprsr(packet_out packet, inout headers hdr, in metadata meta,
               in egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprs) {
  apply {}
}

Pipeline(iPrsr(), ingress(), iDprsr(), ePrsr(), egress(), eDprsr()) pipe;
Switch(pipe) main;
