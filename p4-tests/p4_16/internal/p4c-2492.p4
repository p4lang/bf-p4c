// This checks whether CLOT-allocated fields are unnecessarily double-allocated
// to PHVs.

#include <t2na.p4>

header h_t {
  bit<448> clot1; // Expect all 448 bits in CLOT.
  bit<8> b01;
  bit<8> b02;
  bit<440> clot2; // Expect 8 bits in PHV for inter-CLOT gap, 432 bits in CLOT.

  bit<8> b03;
  bit<8> b04;
  bit<8> b05;

  bit<448> clot3; // Expect all 448 bits in CLOT.
  bit<8> b06;
  bit<8> b07;
  bit<440> clot4; // Expect 8 bits in PHV for inter-CLOT gap, 432 bits in CLOT.

  bit<8> b08;
  bit<8> b09;
  bit<8> b10;

  bit<448> clot5; // Expect all 448 bits in CLOT.
  bit<8> b11;
  bit<8> b12;
  bit<440> clot6; // Expect 8 bits in PHV for inter-CLOT gap, 432 bits in CLOT.

  bit<8> b13;
  bit<8> b14;
  bit<8> b15;
  bit<8> b16;
  bit<8> b17;
  bit<8> b18;
  bit<8> b19;
  bit<8> b20;
  bit<8> b21;
  bit<8> b22;
  bit<8> b23;
  bit<8> b24;
  bit<8> b25;
  bit<8> b26;
  bit<8> b27;
  bit<8> b28;
  bit<8> b29;
  bit<8> b30;
  bit<8> b31;
  bit<8> b32;

  bit<16> h01;
  bit<16> h02;
  bit<16> h03;
  bit<16> h04;
  bit<16> h05;
  bit<16> h06;
  bit<16> h07;
  bit<16> h08;
  bit<16> h09;
  bit<16> h10;
  bit<16> h11;
  bit<16> h12;
  bit<16> h13;
  bit<16> h14;
  bit<16> h15;
  bit<16> h16;
  bit<16> h17;
  bit<16> h18;
  bit<16> h19;
  bit<16> h20;
  bit<16> h21;
  bit<16> h22;
  bit<16> h23;
  bit<16> h24;
  bit<16> h25;
  bit<16> h26;
  bit<16> h27;
  bit<16> h28;
  bit<16> h29;
  bit<16> h30;
  bit<16> h31;
  bit<16> h32;
  bit<16> h33;
  bit<16> h34;
  bit<16> h35;
  bit<16> h36;
  bit<16> h37;
  bit<16> h38;
  bit<16> h39;
  bit<16> h40;
  bit<16> h41;
  bit<16> h42;
  bit<16> h43;
  bit<16> h44;
  bit<16> h45;
  bit<16> h46;
  bit<16> h47;
  bit<16> h48;
  bit<16> h49;
  bit<16> h50;
  bit<16> h51;
  bit<16> h52;
  bit<16> h53;
  bit<16> h54;
  bit<16> h55;
  bit<16> h56;
  bit<16> h57;
  bit<16> h58;
  bit<16> h59;
  bit<16> h60;
  bit<16> h61;
  bit<16> h62;
  bit<16> h63;
  bit<16> h64;
  bit<16> h65;
  bit<16> h66;
  bit<16> h67;
  bit<16> h68;
  bit<16> h69;
  bit<16> h70;
  bit<16> h71;
  bit<16> h72;

  bit<32> w01;
  bit<32> w02;
  bit<32> w03;
  bit<32> w04;
  bit<32> w05;
  bit<32> w06;
  bit<32> w07;
  bit<32> w08;
  bit<32> w09;
  bit<32> w10;
  bit<32> w11;
  bit<32> w12;
  bit<32> w13;
  bit<32> w14;
  bit<32> w15;
  bit<32> w16;
  bit<32> w17;
  bit<32> w18;
  bit<32> w19;
  bit<32> w20;
  bit<32> w21;
  bit<32> w22;
  bit<32> w23;
  bit<32> w24;
  bit<32> w25;
  bit<32> w26;
  bit<32> w27;
  bit<32> w28;
  bit<32> w29;
  bit<32> w30;
  bit<32> w31;
  bit<32> w32;
  bit<32> w33;
  bit<32> w34;
  bit<32> w35;
  bit<32> w36;
  bit<32> w37;
  bit<32> w38;
  bit<32> w39;
  bit<32> w40;
  bit<32> w41;
  bit<32> w42;
  bit<32> w43;
  bit<32> w44;
  bit<32> w45;
  bit<32> w46;
  bit<32> w47;
  bit<32> w48;
}

struct header_t {
  h_t h;
}

struct metadata_t {
}

parser MyIngressParser(
    packet_in pkt,
    out header_t hdr,
    out metadata_t ig_md,
    out ingress_intrinsic_metadata_t ig_intr_md) {

  state start {
    pkt.extract(ig_intr_md);
    pkt.advance(PORT_METADATA_SIZE);
    pkt.extract(hdr.h);
    transition accept;
  }
}

control MyIngress(
    inout header_t hdr,
    inout metadata_t ig_md,
    in ingress_intrinsic_metadata_t ig_intr_md,
    in ingress_intrinsic_metadata_from_parser_t ig_prsr_md,
    inout ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md,
    inout ingress_intrinsic_metadata_for_tm_t ig_tm_md) {

  action write() {
    hdr.h.b01 = 1;
    hdr.h.b02 = 1;
    hdr.h.b03 = 1;
    hdr.h.b04 = 1;
    hdr.h.b05 = 1;
    hdr.h.b06 = 1;
    hdr.h.b07 = 1;
    hdr.h.b08 = 1;
    hdr.h.b09 = 1;
    hdr.h.b10 = 1;
    hdr.h.b11 = 1;
    hdr.h.b12 = 1;
    hdr.h.b13 = 1;
    hdr.h.b14 = 1;
    hdr.h.b15 = 1;
    hdr.h.b16 = 1;
    hdr.h.b17 = 1;
    hdr.h.b18 = 1;
    hdr.h.b19 = 1;
    hdr.h.b20 = 1;
    hdr.h.b21 = 1;
    hdr.h.b22 = 1;
    hdr.h.b23 = 1;
    hdr.h.b24 = 1;
    hdr.h.b25 = 1;
    hdr.h.b26 = 1;
    hdr.h.b27 = 1;
    hdr.h.b28 = 1;
    hdr.h.b29 = 1;
    hdr.h.b30 = 1;
    hdr.h.b31 = 1;
    hdr.h.b32 = 1;

    hdr.h.h01 = 1;
    hdr.h.h02 = 1;
    hdr.h.h03 = 1;
    hdr.h.h04 = 1;
    hdr.h.h05 = 1;
    hdr.h.h06 = 1;
    hdr.h.h07 = 1;
    hdr.h.h08 = 1;
    hdr.h.h09 = 1;
    hdr.h.h10 = 1;
    hdr.h.h11 = 1;
    hdr.h.h12 = 1;
    hdr.h.h13 = 1;
    hdr.h.h14 = 1;
    hdr.h.h15 = 1;
    hdr.h.h16 = 1;
    hdr.h.h17 = 1;
    hdr.h.h18 = 1;
    hdr.h.h19 = 1;
    hdr.h.h20 = 1;
    hdr.h.h21 = 1;
    hdr.h.h22 = 1;
    hdr.h.h23 = 1;
    hdr.h.h24 = 1;
    hdr.h.h25 = 1;
    hdr.h.h26 = 1;
    hdr.h.h27 = 1;
    hdr.h.h28 = 1;
    hdr.h.h29 = 1;
    hdr.h.h30 = 1;
    hdr.h.h31 = 1;
    hdr.h.h32 = 1;
    hdr.h.h33 = 1;
    hdr.h.h34 = 1;
    hdr.h.h35 = 1;
    hdr.h.h36 = 1;
    hdr.h.h37 = 1;
    hdr.h.h38 = 1;
    hdr.h.h39 = 1;
    hdr.h.h40 = 1;
    hdr.h.h41 = 1;
    hdr.h.h42 = 1;
    hdr.h.h43 = 1;
    hdr.h.h44 = 1;
    hdr.h.h45 = 1;
    hdr.h.h46 = 1;
    hdr.h.h47 = 1;
    hdr.h.h48 = 1;
    hdr.h.h49 = 1;
    hdr.h.h50 = 1;
    hdr.h.h51 = 1;
    hdr.h.h52 = 1;
    hdr.h.h53 = 1;
    hdr.h.h54 = 1;
    hdr.h.h55 = 1;
    hdr.h.h56 = 1;
    hdr.h.h57 = 1;
    hdr.h.h58 = 1;
    hdr.h.h59 = 1;
    hdr.h.h60 = 1;
    hdr.h.h61 = 1;
    hdr.h.h62 = 1;
    hdr.h.h63 = 1;
    hdr.h.h64 = 1;
    hdr.h.h65 = 1;
    hdr.h.h66 = 1;
    hdr.h.h67 = 1;
    hdr.h.h68 = 1;
    hdr.h.h69 = 1;
    hdr.h.h70 = 1;
    hdr.h.h71 = 1;
    hdr.h.h72 = 1;

    hdr.h.w01 = 1;
    hdr.h.w02 = 1;
    hdr.h.w03 = 1;
    hdr.h.w04 = 1;
    hdr.h.w05 = 1;
    hdr.h.w06 = 1;
    hdr.h.w07 = 1;
    hdr.h.w08 = 1;
    hdr.h.w09 = 1;
    hdr.h.w10 = 1;
    hdr.h.w11 = 1;
    hdr.h.w12 = 1;
    hdr.h.w13 = 1;
    hdr.h.w14 = 1;
    hdr.h.w15 = 1;
    hdr.h.w16 = 1;
    hdr.h.w17 = 1;
    hdr.h.w18 = 1;
    hdr.h.w19 = 1;
    hdr.h.w20 = 1;
    hdr.h.w21 = 1;
    hdr.h.w22 = 1;
    hdr.h.w23 = 1;
    hdr.h.w24 = 1;
    hdr.h.w25 = 1;
    hdr.h.w26 = 1;
    hdr.h.w27 = 1;
    hdr.h.w28 = 1;
    hdr.h.w29 = 1;
    hdr.h.w30 = 1;
    hdr.h.w31 = 1;
    hdr.h.w32 = 1;
    hdr.h.w33 = 1;
    hdr.h.w34 = 1;
    hdr.h.w35 = 1;
    hdr.h.w36 = 1;
    hdr.h.w37 = 1;
    hdr.h.w38 = 1;
    hdr.h.w39 = 1;
    hdr.h.w40 = 1;
    hdr.h.w41 = 1;
    hdr.h.w42 = 1;
    hdr.h.w43 = 1;
    hdr.h.w44 = 1;
    hdr.h.w45 = 1;
    hdr.h.w46 = 1;
    hdr.h.w47 = 1;
    hdr.h.w48 = 1;
  }

  table t1 {
    key = {
    }

    actions = {
      write;
    }

    default_action = write;
  }

  apply {
    t1.apply();
  }
}

control MyIngressDeparser(packet_out pkt,
    inout header_t hdr,
    in metadata_t ig_md,
    in ingress_intrinsic_metadata_for_deparser_t ig_intr_dprsr_md) {

  apply {
    pkt.emit(hdr);
  }
}

parser MyEgressParser(
    packet_in pkt,
    out header_t hdr,
    out metadata_t eg_md,
    out egress_intrinsic_metadata_t eg_intr_md) {

  state start {
    pkt.extract(eg_intr_md);
    transition accept;
  }
}

control MyEgress(
    inout header_t hdr,
    inout metadata_t eg_md,
    in egress_intrinsic_metadata_t eg_intr_md,
    in egress_intrinsic_metadata_from_parser_t eg_prsr_md,
    inout egress_intrinsic_metadata_for_deparser_t eg_dprsr_md,
    inout egress_intrinsic_metadata_for_output_port_t eg_oport_md) {

  apply {
  }
}

control MyEgressDeparser(
    packet_out pkt,
    inout header_t hdr,
    in metadata_t eg_md,
    in egress_intrinsic_metadata_for_deparser_t eg_dprsr_md) {

  apply {
    pkt.emit(hdr);
  }
}

Pipeline(MyIngressParser(),
       MyIngress(),
       MyIngressDeparser(),
       MyEgressParser(),
       MyEgress(),
       MyEgressDeparser()) pipe;

Switch(pipe) main;
