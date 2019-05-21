// Variant of t2na_emulation.p4, which resulted in too many POV bits being used because
// validate_allocation was accounting for ingress and egress bits together.

#include <t2na.p4>

typedef bit<8>  pkt_src_t;
const pkt_src_t PKT_SRC_NORMAL = 0;
const pkt_src_t PKT_SRC_CLONE_INGRESS = 64;
const pkt_src_t PKT_SRC_CLONE_EGRESS = 128;

struct chnl_meta_t {
  bit<1> force_egr_port;
}
header ethernet_hdr {
  bit<48> dst;
  bit<48> src;
  bit<16> etype;
}
header ctrl_hdr {
  // Bytes 0,1
  bit<1> do_resubmit;
  bit<1> do_recirc;
  bit<5> extra_bridged_md;
  bit<9> recirc_port;

  // Byte 2
  bit<3> c2c_cos;
  bit<1> c2c;
  bit<1> mirror_e2e_io_sel;
  bit<1> mirror_i2e_io_sel;
  bit<1> mirror_e2e;
  bit<1> mirror_i2e;

  // Bytes 3,4
  bit<8> mirror_e2e_sid;
  bit<8> mirror_i2e_sid;

  // Bytes 5,6
  bit<1> bypass_egress;
  bit<1> dod;
  bit<2> color;
  bit<1> mc_cut_through;
  bit<3> ingress_cos;
  bit<1> disable_uc_cut_through;
  bit<7> qid;

  // Byte 7
  bit<8> next_hdrs;
}
header trunc_hdr {
  bit<2>  pad;
  bit<14> truncation_size;
}
header afc_hdr {
  bit<1>  qfc;
  bit<9>  port;
  bit<7>  qid;
  bit<15> credit;
}
header bridged_md_hdr {
  pkt_src_t src;
}
header bridged_md_pad_1_hdr {
  bit<8> pad;
}
header bridged_md_pad_2_hdr {
  bit<16> pad;
}
header bridged_md_pad_4_hdr {
  bit<32> pad;
}
header bridged_md_pad_8_hdr {
  bit<64> pad;
}
header bridged_md_pad_16_hdr {
  bit<128> pad;
}

struct headers {
  bridged_md_hdr        bridged_meta;
  ethernet_hdr          ethernet;
  ctrl_hdr              ctrl;
  bridged_md_pad_1_hdr  pad1;
  bridged_md_pad_2_hdr  pad2;
  bridged_md_pad_4_hdr  pad4;
  bridged_md_pad_8_hdr  pad8;
  bridged_md_pad_16_hdr pad16;
  afc_hdr               i_afc;
  afc_hdr               e_afc;
  trunc_hdr             i_trunc;
  trunc_hdr             e_trunc;
}
struct ing_metadata {
  MirrorId_t  mir_sid;
  pkt_src_t   mir_type;
  chnl_meta_t chnl_meta;
  bit<8> lame;
}
struct egr_metadata {
  MirrorId_t mir_sid;
  pkt_src_t  mir_type;
}

header mir_meta_h {
  pkt_src_t  mir_type;
}

parser iPrsr(packet_in packet,
             out headers hdr,
             out ing_metadata md,
             out ingress_intrinsic_metadata_t intr_md) {
  state start {
    packet.extract(intr_md);
    md.chnl_meta = port_metadata_unpack<chnl_meta_t>(packet);
    packet.extract(hdr.ethernet);
    md.lame = hdr.ethernet.dst[7:0];
    packet.extract(hdr.ctrl);
    transition select(hdr.ctrl.next_hdrs) {
      0x00 &&& 0xFF : accept;
      0x01 &&& 0x01 : parse_i_afc;
      0x02 &&& 0x02 : parse_e_afc;
      0x04 &&& 0x04 : parse_i_trunc;
      0x08 &&& 0x08 : parse_e_trunc;
    }
  }

  state parse_i_afc {
    packet.extract(hdr.i_afc);
    transition select(hdr.ctrl.next_hdrs) {
      0x02 &&& 0x02 : parse_e_afc;
      0x04 &&& 0x04 : parse_i_trunc;
      0x08 &&& 0x08 : parse_e_trunc;
      0x00 &&& 0xF0 : accept;
    }
  }
  state parse_e_afc {
    packet.extract(hdr.e_afc);
    transition select(hdr.ctrl.next_hdrs) {
      0x04 &&& 0x04 : parse_i_trunc;
      0x08 &&& 0x08 : parse_e_trunc;
      0x00 &&& 0xF0 : accept;
    }
  }
  state parse_i_trunc {
    packet.extract(hdr.i_trunc);
    transition select(hdr.ctrl.next_hdrs) {
      0x08 &&& 0x08 : parse_e_trunc;
      0x00 &&& 0xF0 : accept;
    }
  }
  state parse_e_trunc {
    packet.extract(hdr.e_trunc);
    transition select(hdr.ctrl.next_hdrs) {
      0x00 &&& 0xF0 : accept;
    }
  }
}

control ingr(inout headers hdr,
             inout ing_metadata md,
             in    ingress_intrinsic_metadata_t              intr_md,
             in    ingress_intrinsic_metadata_from_parser_t  intr_prsr_md,
             inout ingress_intrinsic_metadata_for_deparser_t intr_dprsr_md,
             inout ingress_intrinsic_metadata_for_tm_t       intr_tm_md) {

  action prsr_error() { intr_dprsr_md.drop_ctl = 7; }
  action prsr_no_error() { }
  table check_prsr_error {
    key = { intr_prsr_md.parser_err : exact; }
    actions = { prsr_no_error; prsr_error; }
    const default_action = prsr_error();
    size = 1;
    const entries = {
      (0) : prsr_no_error();
    }
  }

  action dmac_do_mc(MulticastGroupId_t mc_index) {
    intr_tm_md.mcast_grp_a = mc_index;
  }
  action dmac_do_uc(PortId_t egress_port) {
    intr_tm_md.ucast_egress_port = egress_port;
  }
  action dmac_do_uc_mc(PortId_t egress_port, MulticastGroupId_t mc_index) {
    intr_tm_md.ucast_egress_port = egress_port;
    intr_tm_md.mcast_grp_a       = mc_index;
  }
  table dmac {
    key = { hdr.ethernet.dst : exact; }
    actions = {
      dmac_do_mc;
      dmac_do_uc;
      dmac_do_uc_mc;
    }
    size = 4096;
  }

  action set_uc_dest(PortId_t egress_port) {
    intr_tm_md.ucast_egress_port = egress_port;
  }
  action set_mc_dest(MulticastGroupId_t mc_index) {
    intr_tm_md.mcast_grp_a = mc_index;
  }
  action set_ucmc_dest(PortId_t egress_port, MulticastGroupId_t mc_index) {
    set_uc_dest(egress_port);
    set_mc_dest(mc_index);
  }
  table egr_port {
    key = {
      intr_md.ingress_port : exact;
      //hdr.ethernet.dst[7:0] : exact;
      md.lame : exact;
    }
    actions = {
      set_uc_dest;
      set_mc_dest;
      set_ucmc_dest;
    }
    size = 72*8*4;
  }

  action set_ctrl_info() {
    intr_tm_md.bypass_egress = (bool)hdr.ctrl.bypass_egress;
    intr_tm_md.deflect_on_drop = (bool)hdr.ctrl.dod;
    intr_tm_md.ingress_cos = hdr.ctrl.ingress_cos;
    intr_tm_md.qid = hdr.ctrl.qid;
    intr_tm_md.icos_for_copy_to_cpu = hdr.ctrl.c2c_cos;
    intr_tm_md.packet_color = hdr.ctrl.color;
    intr_tm_md.disable_ucast_cutthru = (bool)hdr.ctrl.disable_uc_cut_through;
    intr_tm_md.enable_mcast_cutthru = (bool)hdr.ctrl.mc_cut_through;

  }
  action set_mir_info() {
    intr_dprsr_md.mirror_type = 15;
    intr_dprsr_md.mirror_io_select = hdr.ctrl.mirror_i2e_io_sel;
    md.mir_sid = hdr.ctrl.mirror_i2e_sid;
    md.mir_type = PKT_SRC_CLONE_INGRESS;
  }

  action do_resubmit() {
    intr_dprsr_md.resubmit_type = 7;
  }
  action do_recirc() {
    intr_tm_md.ucast_egress_port = hdr.ctrl.recirc_port;
  }
  action do_afc() {
    intr_dprsr_md.adv_flow_ctl[31:31] = hdr.i_afc.qfc;
    intr_dprsr_md.adv_flow_ctl[30:22] = hdr.i_afc.port;
    intr_dprsr_md.adv_flow_ctl[21:15] = hdr.i_afc.qid;
    intr_dprsr_md.adv_flow_ctl[14:0]  = hdr.i_afc.credit;
  }
  action do_truncation() {
    intr_dprsr_md.mtu_trunc_len = hdr.i_trunc.truncation_size;
  }

  action add_bridged_metadata() {
    hdr.bridged_meta.setValid();
    hdr.bridged_meta.src = PKT_SRC_NORMAL;
  }
  action add_bridged_md_pad1() {
    hdr.pad1.setValid();
    hdr.pad1.pad = 0x11;
  }
  action add_bridged_md_pad2() {
    hdr.pad2.setValid();
    hdr.pad2.pad = 0x2222;
  }
  action add_bridged_md_pad4() {
    hdr.pad4.setValid();
    hdr.pad4.pad = 0x44444444;
  }
  action add_bridged_md_pad8() {
    hdr.pad8.setValid();
    hdr.pad8.pad = 0x8888888888888888;
  }
  action add_bridged_md_pad16() {
    hdr.pad16.setValid();
    hdr.pad16.pad = 0x16161616161616161616161616161616;
  }

  apply {
    /* Set the drop_ctl bits if the packet had a parser error. */
    check_prsr_error.apply();

    /*
     * Tables to select the packet's destination.
     */
    if (hdr.ctrl.do_recirc == 1 && hdr.ctrl.recirc_port != intr_md.ingress_port) {
      /* Recirculation was requested and we have not come from the recirc port,
       * set destination to the recirculation port. */
      do_recirc();
    } else if (md.chnl_meta.force_egr_port == 1) {
      egr_port.apply();
    } else {
      dmac.apply();
    }

    /* Assign the intrinsic metadata requested in the control header. */
    set_ctrl_info();

    /* For non-bypass egress cases add bridged metadata. */
#if 1
    if (hdr.ctrl.bypass_egress == 0) {
#else
    if (!intr_tm_md.bypass_egress) {
#endif
      /* First add the standard one byte. */
      add_bridged_metadata();

      /* Add additional headers to artifically increase the size of the bridged
       * metadata. */
      if (hdr.ctrl.extra_bridged_md & 1 == 1) {
        add_bridged_md_pad1();
      }
      if (hdr.ctrl.extra_bridged_md & 2 == 2) {
        add_bridged_md_pad2();
      }
      if (hdr.ctrl.extra_bridged_md & 4 == 4) {
        add_bridged_md_pad4();
      }
      if (hdr.ctrl.extra_bridged_md & 8 == 8) {
        add_bridged_md_pad8();
      }
      if (hdr.ctrl.extra_bridged_md & 16 == 16) {
        add_bridged_md_pad16();
      }
    }

    if (intr_md.resubmit_flag == 0 && hdr.ctrl.do_resubmit == 1) {
      do_resubmit();
    }
    if (hdr.ctrl.mirror_i2e == 1) {
      set_mir_info();
    }
    if (hdr.i_afc.isValid()) {
      do_afc();
    }
    if (hdr.i_trunc.isValid()) {
      do_truncation();
    }
  }
}



control iDprsr(packet_out packet,
               inout headers hdr,
               in ing_metadata md,
               in ingress_intrinsic_metadata_for_deparser_t intr_md_for_dprsr) {
  Resubmit() resubmit;
  Mirror() mirror;
  apply {
    if (intr_md_for_dprsr.resubmit_type == 7) {
      resubmit.emit();
    }
    if (intr_md_for_dprsr.mirror_type == 15) {
      mirror.emit<mir_meta_h>(md.mir_sid, {md.mir_type});
    }
    packet.emit(hdr);
  }
}

parser ePrsr(packet_in packet,
             out headers hdr,
             out egr_metadata md,
             out egress_intrinsic_metadata_t intr_md) {
  state start {
    packet.extract(intr_md);
    packet.extract(hdr.bridged_meta);
    packet.extract(hdr.ethernet);
    packet.extract(hdr.ctrl);
    transition select(hdr.ctrl.extra_bridged_md +++ hdr.ctrl.next_hdrs) {
      0x0100 &&& 0x1F00 : parse_pad_1;
      0x0200 &&& 0x1F00 : parse_pad_2;
      0x0300 &&& 0x1F00 : parse_pad_3;
      0x0400 &&& 0x1F00 : parse_pad_4;
      0x0500 &&& 0x1F00 : parse_pad_5;
      0x0600 &&& 0x1F00 : parse_pad_6;
      0x0700 &&& 0x1F00 : parse_pad_7;
      0x0800 &&& 0x1F00 : parse_pad_8;
      0x0900 &&& 0x1F00 : parse_pad_9;
      0x0A00 &&& 0x1F00 : parse_pad_10;
      0x0B00 &&& 0x1F00 : parse_pad_11;
      0x0C00 &&& 0x1F00 : parse_pad_12;
      0x0D00 &&& 0x1F00 : parse_pad_13;
      0x0E00 &&& 0x1F00 : parse_pad_14;
      0x0F00 &&& 0x1F00 : parse_pad_15;
      0x1000 &&& 0x1F00 : parse_pad_16;
      0x1100 &&& 0x1F00 : parse_pad_17;
      0x1200 &&& 0x1F00 : parse_pad_18;
      0x1300 &&& 0x1F00 : parse_pad_19;
      0x1400 &&& 0x1F00 : parse_pad_20;
      0x1500 &&& 0x1F00 : parse_pad_21;
      0x1600 &&& 0x1F00 : parse_pad_22;
      0x1700 &&& 0x1F00 : parse_pad_23;
      0x1800 &&& 0x1F00 : parse_pad_24;
      0x1900 &&& 0x1F00 : parse_pad_25;
      0x1A00 &&& 0x1F00 : parse_pad_26;
      0x1B00 &&& 0x1F00 : parse_pad_27;
      0x1C00 &&& 0x1F00 : parse_pad_28;
      0x1D00 &&& 0x1F00 : parse_pad_29;
      0x1E00 &&& 0x1F00 : parse_pad_30;
      0x1F00 &&& 0x1F00 : parse_pad_31;
      0x00 &&& 0xFF : accept;
      0x01 &&& 0x01 : parse_i_afc;
      0x02 &&& 0x02 : parse_e_afc;
      0x04 &&& 0x04 : parse_i_trunc;
      0x08 &&& 0x08 : parse_e_trunc;
    }
  }

  state parse_ctrl_next_hdr {
    transition select(hdr.ctrl.next_hdrs) {
      0x00 &&& 0xFF : accept;
      0x01 &&& 0x01 : parse_i_afc;
      0x02 &&& 0x02 : parse_e_afc;
      0x04 &&& 0x04 : parse_i_trunc;
      0x08 &&& 0x08 : parse_e_trunc;
    }
  }
  state parse_pad_1 {
    packet.extract(hdr.pad1);
    transition parse_ctrl_next_hdr;
  }
  state parse_pad_2 {
    packet.extract(hdr.pad2);
    transition parse_ctrl_next_hdr;
  }
  state parse_pad_3 {
    packet.extract(hdr.pad1);
    packet.extract(hdr.pad2);
    transition parse_ctrl_next_hdr;
  }
  state parse_pad_4 {
    packet.extract(hdr.pad4);
    transition parse_ctrl_next_hdr;
  }
  state parse_pad_5 {
    packet.extract(hdr.pad1);
    packet.extract(hdr.pad4);
    transition parse_ctrl_next_hdr;
  }
  state parse_pad_6 {
    packet.extract(hdr.pad2);
    packet.extract(hdr.pad4);
    transition parse_ctrl_next_hdr;
  }
  state parse_pad_7 {
    packet.extract(hdr.pad1);
    packet.extract(hdr.pad2);
    packet.extract(hdr.pad4);
    transition parse_ctrl_next_hdr;
  }
  state parse_pad_8 {
    packet.extract(hdr.pad8);
    transition parse_ctrl_next_hdr;
  }
  state parse_pad_9 {
    packet.extract(hdr.pad1);
    packet.extract(hdr.pad8);
    transition parse_ctrl_next_hdr;
  }
  state parse_pad_10 {
    packet.extract(hdr.pad2);
    packet.extract(hdr.pad8);
    transition parse_ctrl_next_hdr;
  }
  state parse_pad_11 {
    packet.extract(hdr.pad1);
    packet.extract(hdr.pad2);
    packet.extract(hdr.pad8);
    transition parse_ctrl_next_hdr;
  }
  state parse_pad_12 {
    packet.extract(hdr.pad4);
    packet.extract(hdr.pad8);
    transition parse_ctrl_next_hdr;
  }
  state parse_pad_13 {
    packet.extract(hdr.pad1);
    packet.extract(hdr.pad4);
    packet.extract(hdr.pad8);
    transition parse_ctrl_next_hdr;
  }
  state parse_pad_14 {
    packet.extract(hdr.pad2);
    packet.extract(hdr.pad4);
    packet.extract(hdr.pad8);
    transition parse_ctrl_next_hdr;
  }
  state parse_pad_15 {
    packet.extract(hdr.pad1);
    packet.extract(hdr.pad2);
    packet.extract(hdr.pad4);
    packet.extract(hdr.pad8);
    transition parse_ctrl_next_hdr;
  }
  state parse_pad_16 {
    packet.extract(hdr.pad16);
    transition parse_ctrl_next_hdr;
  }
  state parse_pad_17 {
    packet.extract(hdr.pad1);
    packet.extract(hdr.pad16);
    transition parse_ctrl_next_hdr;
  }
  state parse_pad_18 {
    packet.extract(hdr.pad2);
    packet.extract(hdr.pad16);
    transition parse_ctrl_next_hdr;
  }
  state parse_pad_19 {
    packet.extract(hdr.pad1);
    packet.extract(hdr.pad2);
    packet.extract(hdr.pad16);
    transition parse_ctrl_next_hdr;
  }
  state parse_pad_20 {
    packet.extract(hdr.pad4);
    packet.extract(hdr.pad16);
    transition parse_ctrl_next_hdr;
  }
  state parse_pad_21 {
    packet.extract(hdr.pad1);
    packet.extract(hdr.pad4);
    packet.extract(hdr.pad16);
    transition parse_ctrl_next_hdr;
  }
  state parse_pad_22 {
    packet.extract(hdr.pad2);
    packet.extract(hdr.pad4);
    packet.extract(hdr.pad16);
    transition parse_ctrl_next_hdr;
  }
  state parse_pad_23 {
    packet.extract(hdr.pad1);
    packet.extract(hdr.pad2);
    packet.extract(hdr.pad4);
    packet.extract(hdr.pad16);
    transition parse_ctrl_next_hdr;
  }
  state parse_pad_24 {
    packet.extract(hdr.pad8);
    packet.extract(hdr.pad16);
    transition parse_ctrl_next_hdr;
  }
  state parse_pad_25 {
    packet.extract(hdr.pad1);
    packet.extract(hdr.pad8);
    packet.extract(hdr.pad16);
    transition parse_ctrl_next_hdr;
  }
  state parse_pad_26 {
    packet.extract(hdr.pad2);
    packet.extract(hdr.pad8);
    packet.extract(hdr.pad16);
    transition parse_ctrl_next_hdr;
  }
  state parse_pad_27 {
    packet.extract(hdr.pad1);
    packet.extract(hdr.pad2);
    packet.extract(hdr.pad8);
    packet.extract(hdr.pad16);
    transition parse_ctrl_next_hdr;
  }
  state parse_pad_28 {
    packet.extract(hdr.pad4);
    packet.extract(hdr.pad8);
    packet.extract(hdr.pad16);
    transition parse_ctrl_next_hdr;
  }
  state parse_pad_29 {
    packet.extract(hdr.pad1);
    packet.extract(hdr.pad4);
    packet.extract(hdr.pad8);
    packet.extract(hdr.pad16);
    transition parse_ctrl_next_hdr;
  }
  state parse_pad_30 {
    packet.extract(hdr.pad2);
    packet.extract(hdr.pad4);
    packet.extract(hdr.pad8);
    packet.extract(hdr.pad16);
    transition parse_ctrl_next_hdr;
  }
  state parse_pad_31 {
    packet.extract(hdr.pad1);
    packet.extract(hdr.pad2);
    packet.extract(hdr.pad4);
    packet.extract(hdr.pad8);
    packet.extract(hdr.pad16);
    transition parse_ctrl_next_hdr;
  }

  state parse_i_afc {
    packet.extract(hdr.i_afc);
    transition select(hdr.ctrl.next_hdrs) {
      0x02 &&& 0x02 : parse_e_afc;
      0x04 &&& 0x04 : parse_i_trunc;
      0x08 &&& 0x08 : parse_e_trunc;
      0x00 &&& 0xF0 : accept;
    }
  }
  state parse_e_afc {
    packet.extract(hdr.e_afc);
    transition select(hdr.ctrl.next_hdrs) {
      0x04 &&& 0x04 : parse_i_trunc;
      0x08 &&& 0x08 : parse_e_trunc;
      0x00 &&& 0xF0 : accept;
    }
  }
  state parse_i_trunc {
    packet.extract(hdr.i_trunc);
    transition select(hdr.ctrl.next_hdrs) {
      0x08 &&& 0x08 : parse_e_trunc;
      0x00 &&& 0xF0 : accept;
    }
  }
  state parse_e_trunc {
    packet.extract(hdr.e_trunc);
    transition select(hdr.ctrl.next_hdrs) {
      0x00 &&& 0xF0 : accept;
    }
  }
}

control egr(inout headers hdr,
            inout egr_metadata md,
            in    egress_intrinsic_metadata_t                 intr_md,
            in    egress_intrinsic_metadata_from_parser_t     intr_prsr_md,
            inout egress_intrinsic_metadata_for_deparser_t    intr_dprsr_md,
            inout egress_intrinsic_metadata_for_output_port_t intr_oport_md) {

  action prsr_error() { intr_dprsr_md.drop_ctl = 7; }
  action prsr_no_error() { }
  table check_prsr_error {
    key = { intr_prsr_md.parser_err : exact; }
    actions = { prsr_no_error; prsr_error; }
    const default_action = prsr_error();
    size = 1;
    const entries = {
      (0) : prsr_no_error();
    }
  }

  action set_mir_info() {
    intr_dprsr_md.mirror_type = 15;
    intr_dprsr_md.mirror_io_select = hdr.ctrl.mirror_e2e_io_sel;
    md.mir_sid = hdr.ctrl.mirror_e2e_sid;
    md.mir_type = PKT_SRC_CLONE_EGRESS;
  }
  action do_afc() {
    intr_dprsr_md.adv_flow_ctl[31:31] = hdr.e_afc.qfc;
    intr_dprsr_md.adv_flow_ctl[30:22] = hdr.e_afc.port;
    intr_dprsr_md.adv_flow_ctl[21:15] = hdr.e_afc.qid;
    intr_dprsr_md.adv_flow_ctl[14:0]  = hdr.e_afc.credit;
  }
  action do_truncation() {
    intr_dprsr_md.mtu_trunc_len = hdr.e_trunc.truncation_size;
  }

  action okay() {}
  action not_okay() { intr_dprsr_md.drop_ctl = 7; }
  table validate_extra_bridged_md {
    key = {
      hdr.ctrl.extra_bridged_md : exact;
      hdr.pad16.isValid()       : exact;
      hdr.pad8.isValid()        : exact;
      hdr.pad4.isValid()        : exact;
      hdr.pad2.isValid()        : exact;
      hdr.pad1.isValid()        : exact;
    }
    actions = {
      okay; not_okay;
    }
    const default_action = not_okay();
    const entries = {
      (0, false,false,false,false,false) : okay();
      (1, false,false,false,false, true) : okay();
      (2, false,false,false, true,false) : okay();
      (3, false,false,false, true, true) : okay();
      (4, false,false, true,false,false) : okay();
      (5, false,false, true,false, true) : okay();
      (6, false,false, true, true,false) : okay();
      (7, false,false, true, true, true) : okay();
      (8, false, true,false,false,false) : okay();
      (9, false, true,false,false, true) : okay();
      (10,false, true,false, true,false) : okay();
      (11,false, true,false, true, true) : okay();
      (12,false, true, true,false,false) : okay();
      (13,false, true, true,false, true) : okay();
      (14,false, true, true, true,false) : okay();
      (15,false, true, true, true, true) : okay();
      (16, true,false,false,false,false) : okay();
      (17, true,false,false,false, true) : okay();
      (18, true,false,false, true,false) : okay();
      (19, true,false,false, true, true) : okay();
      (20, true,false, true,false,false) : okay();
      (21, true,false, true,false, true) : okay();
      (22, true,false, true, true,false) : okay();
      (23, true,false, true, true, true) : okay();
      (24, true, true,false,false,false) : okay();
      (25, true, true,false,false, true) : okay();
      (26, true, true,false, true,false) : okay();
      (27, true, true,false, true, true) : okay();
      (28, true, true, true,false,false) : okay();
      (29, true, true, true,false, true) : okay();
      (30, true, true, true, true,false) : okay();
      (31, true, true, true, true, true) : okay();
    }
    size = 32;
  }

  apply {
    check_prsr_error.apply();
    validate_extra_bridged_md.apply();
    if (hdr.bridged_meta.src == PKT_SRC_NORMAL) {
      if (hdr.ctrl.mirror_e2e == 1) {
        set_mir_info();
      }
      if (hdr.e_afc.isValid()) {
        do_afc();
      }
      if (hdr.e_trunc.isValid()) {
        do_truncation();
      }
    } else {
      /* Mirror copies do not get special processing. */
    }
  }
}

control eDprsr(packet_out packet, inout headers hdr, in egr_metadata md,
               in egress_intrinsic_metadata_for_deparser_t intr_md_for_dprsr) {
  Mirror() mirror;
  apply {
    if (intr_md_for_dprsr.mirror_type == 15) {
      mirror.emit<mir_meta_h>(md.mir_sid, {md.mir_type});
    }
    packet.emit(hdr.ethernet);
    packet.emit(hdr.ctrl);
    packet.emit(hdr.i_afc);
    packet.emit(hdr.e_afc);
    packet.emit(hdr.i_trunc);
    packet.emit(hdr.e_trunc);
  }
}

Pipeline(iPrsr(), ingr(), iDprsr(), ePrsr(), egr(), eDprsr()) pipe;
Switch(pipe) main;
