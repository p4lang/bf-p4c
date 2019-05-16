#include <t2na.p4>

typedef bit<48> mac_addr_t;
typedef bit<32> ipv4_addr_t;

#define pkt_src_t_size 8

typedef bit<pkt_src_t_size>  pkt_src_t;

const pkt_src_t PKT_SRC_NORMAL = 0;
const pkt_src_t PKT_SRC_CLONE_INGRESS = 64;
const pkt_src_t PKT_SRC_CLONE_EGRESS = 128;

header ethernet_hdr {
  mac_addr_t dst;
  mac_addr_t src;
  bit<16>    etype;
}
header vlan_hdr {
    bit<3> pcp;
    bit<1> cfi;
    bit<12> vid;
    bit<16> etype;
}
header ipv4_hdr {
  bit<4>      version;
  bit<4>      ihl;
  bit<6>      dscp;
  bit<2>      ecn;
  bit<16>     total_len;
  bit<16>     identification;
  bit<1>      unused;
  bit<1>      dont_frag;
  bit<1>      more_frag;
  bit<13>     frag_offset;
  bit<8>      ttl;
  bit<8>      protocol;
  bit<16>     cksum;
  ipv4_addr_t src;
  ipv4_addr_t dst;
}
header tcp_hdr {
  bit<16> src;
  bit<16> dst;
  bit<32> seq_num;
  bit<32> ack_num;
  bit<4>  hlen;
  bit<6>  rsvd;
  bit<1>  urg;
  bit<1>  ack;
  bit<1>  psh;
  bit<1>  rst;
  bit<1>  syn;
  bit<1>  fin;
  bit<16> window;
  bit<16> cksum;
  bit<16> urgent;
}
header udp_hdr {
  bit<16> src;
  bit<16> dst;
  bit<16> hlen;
  bit<16> cksum;
}
header bridged_md_hdr {
  pkt_src_t src;
}

struct headers {
  bridged_md_hdr bridged_meta;
  ethernet_hdr   ethernet;
  vlan_hdr       vlan;
  ipv4_hdr       ipv4;
  tcp_hdr        tcp;
  udp_hdr        udp;
}
struct ing_metadata {
  MirrorId_t mir_sid;
  pkt_src_t  mir_type;
}
struct egr_metadata {
  MirrorId_t mir_sid;
  pkt_src_t  mir_type;
}

parser iPrsr(packet_in packet, out headers hdr, out ing_metadata md,
             out ingress_intrinsic_metadata_t ig_intr_md) {
  state start {
    packet.extract(ig_intr_md);
    packet.advance(128);
    packet.advance(64);
    packet.extract(hdr.ethernet);
    transition select(hdr.ethernet.etype) {
      0x8100 : parse_vlan;
      0x0800 : parse_ipv4;
      default: accept;
    }
  }
  state parse_vlan {
    packet.extract(hdr.vlan);
    transition select(hdr.vlan.etype) {
      0x0800 : parse_ipv4;
      default: accept;
    }
  }
  state parse_ipv4 {
    packet.extract(hdr.ipv4);
    transition select(hdr.ipv4.protocol) {
      6  : parse_tcp;
      17 : parse_udp;
      default : accept;
    }
  }
  state parse_tcp {
    packet.extract(hdr.tcp);
    transition accept;
  }
  state parse_udp {
    packet.extract(hdr.udp);
    transition accept;
  }
}

control ingr(inout headers hdr, inout ing_metadata md,
             in ingress_intrinsic_metadata_t ig_intr_md,
             in ingress_intrinsic_metadata_from_parser_t ig_intr_prsr_md,
             inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprsr_md,
             inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {
  action dmac_miss(MulticastGroupId_t mc_index) {
    ig_intr_tm_md.mcast_grp_a = mc_index;
  }
  action dmac_uc_hit(PortId_t egress_port) {
    ig_intr_tm_md.ucast_egress_port = egress_port;
  }
  action dmac_mc_hit(MulticastGroupId_t mc_index) {
    ig_intr_tm_md.mcast_grp_a          = mc_index;
    ig_intr_tm_md.enable_mcast_cutthru = true;
  }
  action dmac_uc_mc_hit(PortId_t egress_port, MulticastGroupId_t mc_index) {
    ig_intr_tm_md.ucast_egress_port    = egress_port;
    ig_intr_tm_md.mcast_grp_a          = mc_index;
    ig_intr_tm_md.enable_mcast_cutthru = true;
  }
  table dmac {
    key = { hdr.ethernet.dst : exact; }
    actions = {
      dmac_miss;
      dmac_uc_hit;
      dmac_mc_hit;
      dmac_uc_mc_hit;
    }
    size = 4096;
  }

  action qos_miss() {
    ig_intr_tm_md.ingress_cos = 0;
    ig_intr_tm_md.qid = 0;
  }

  action qos_hit_eg_bypass_no_mirror(QueueId_t qid, bit<2> color) {
    ig_intr_tm_md.ingress_cos = 1;
    ig_intr_tm_md.qid = qid;
    ig_intr_tm_md.bypass_egress = true;
    ig_intr_tm_md.packet_color = color;
  }

  action qos_hit_no_eg_bypass_no_mirror(QueueId_t qid, bit<2> color) {
    ig_intr_tm_md.ingress_cos = 1;
    ig_intr_tm_md.qid = qid;
    ig_intr_tm_md.packet_color = color;
  }

  action qos_hit_eg_bypass_i2e_mirror(QueueId_t qid, MirrorId_t mirror_id) {
    ig_intr_tm_md.ingress_cos = 1;
    ig_intr_tm_md.qid = qid;
    ig_intr_tm_md.bypass_egress = true;
    ig_intr_dprsr_md.mirror_type = 15;
    ig_intr_dprsr_md.mirror_io_select = 0;
    md.mir_sid = mirror_id;
    md.mir_type = PKT_SRC_CLONE_INGRESS;
  }

  action qos_hit_eg_bypass_i2e_mirror_post_dprsr(QueueId_t qid, MirrorId_t mirror_id) {
    ig_intr_tm_md.ingress_cos = 1;
    ig_intr_tm_md.qid = qid;
    ig_intr_tm_md.bypass_egress = true;
    ig_intr_dprsr_md.mirror_type = 15;
    ig_intr_dprsr_md.mirror_io_select = 1;
    md.mir_sid = mirror_id;
    md.mir_type = PKT_SRC_CLONE_INGRESS;
  }

  table ingress_qos {
    key = {
      hdr.vlan.isValid() : exact;
      hdr.vlan.vid : exact;
    }
    actions = {
        qos_miss;
        qos_hit_eg_bypass_i2e_mirror;
        qos_hit_eg_bypass_i2e_mirror_post_dprsr;
        qos_hit_eg_bypass_no_mirror;
        qos_hit_no_eg_bypass_no_mirror;
    }
    size = 8192;
  }

  action do_resubmit() {
    ig_intr_dprsr_md.resubmit_type = 7;
  }
  action do_deflect_on_drop() {
    ig_intr_tm_md.deflect_on_drop = true;
  }
  
  action do_recirc() {
    ig_intr_tm_md.ucast_egress_port = 6;
  }
  table recirc {
    actions = { do_recirc; }
    default_action = do_recirc();
  }

  action add_bridged_metadata() {
    hdr.bridged_meta.setValid();
    hdr.bridged_meta.src = PKT_SRC_NORMAL;
  }

  apply {
    dmac.apply();
    ingress_qos.apply();
    if (ig_intr_tm_md.bypass_egress != true) {
      add_bridged_metadata();
    }
#ifndef SINGLE_STAGE
    if (hdr.vlan.isValid() == true) {
      if (ig_intr_md.resubmit_flag == 0 && hdr.vlan.pcp == 1) {
        do_resubmit();
      } else if (hdr.vlan.pcp == 2) {
        do_deflect_on_drop();
      } else if (hdr.vlan.pcp == 3) {
        recirc.apply();
      } 
    }
#endif
  }
}



control iDprsr(packet_out packet, inout headers hdr, in ing_metadata md,
               in ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprs) {
  Resubmit() resubmit;
  Mirror() mirror;
  apply {
    if (ig_intr_md_for_dprs.resubmit_type == 7) {
      // resubmit.emit();
    }
    if (ig_intr_md_for_dprs.mirror_type == 15) {
      mirror.emit(md.mir_sid, {md.mir_type});
    }
    packet.emit(hdr);
  }
}

parser ePrsr(packet_in packet, out headers hdr, out egr_metadata md,
             out egress_intrinsic_metadata_t eg_intr_md) {
  state start {
    packet.extract(eg_intr_md);
    pkt_src_t s = packet.lookahead<pkt_src_t>();
    transition select(s) {
      PKT_SRC_CLONE_INGRESS : parse_i2e_mirror;
      PKT_SRC_CLONE_EGRESS  : parse_e2e_mirror;
      default : parse_normal;
    }
  }

  state parse_normal {
    packet.extract(hdr.bridged_meta);
    packet.extract(hdr.ethernet);
    transition select(hdr.ethernet.etype) {
      0x8100 : parse_vlan;
      default: accept;
    }
  }
  state parse_vlan {
    packet.extract(hdr.vlan);
    transition accept;
  }

  state parse_i2e_mirror {
    packet.advance( pkt_src_t_size );
    packet.extract(hdr.ethernet);
    transition select(hdr.ethernet.etype) {
      0x8100 : parse_vlan;
      default: accept;
    }
  }
  state parse_e2e_mirror {
    packet.advance( pkt_src_t_size );
    packet.extract(hdr.ethernet);
    transition select(hdr.ethernet.etype) {
      0x8100 : parse_vlan;
      default: accept;
    }
  }
}

control egr(inout headers hdr, inout egr_metadata md, in egress_intrinsic_metadata_t eg_intr_md,
            in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr,
            inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprs,
            inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport) {

  action qos_hit_e2e_mirror(MirrorId_t mirror_id) {
    eg_intr_md_for_dprs.mirror_type = 15;
    eg_intr_md_for_dprs.mirror_io_select = 1;
    md.mir_sid = mirror_id;
    md.mir_type = PKT_SRC_CLONE_EGRESS;
  }

  action qos_hit_e2e_mirror_pre_dprsr(MirrorId_t mirror_id) {
    eg_intr_md_for_dprs.mirror_type = 15;
    eg_intr_md_for_dprs.mirror_io_select = 0;
    md.mir_sid = mirror_id;
    md.mir_type = PKT_SRC_CLONE_EGRESS;
  }

  table egress_qos {
    key = {
      hdr.vlan.isValid() : exact;
      hdr.vlan.vid : exact;
    }
    actions = {
        qos_hit_e2e_mirror;
        qos_hit_e2e_mirror_pre_dprsr;
    }
    size = 8192;
  }

  apply {
    if (md.mir_type == PKT_SRC_NORMAL) {
      egress_qos.apply();
    }
  }
}

control eDprsr(packet_out packet, inout headers hdr, in egr_metadata md,
               in egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprs) {
  Mirror() mirror;
  apply {
    if (eg_intr_md_for_dprs.mirror_type == 15) {
      mirror.emit(md.mir_sid, {md.mir_type});
    }
    packet.emit(hdr.ethernet);
    packet.emit(hdr.vlan);
  }
}

Pipeline(iPrsr(), ingr(), iDprsr(), ePrsr(), egr(), eDprsr()) pipe;
Switch(pipe) main;
