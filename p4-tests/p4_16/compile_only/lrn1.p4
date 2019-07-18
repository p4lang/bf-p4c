#if __TARGET_TOFINO__ == 2
#include <t2na.p4>
#else
#include <tna.p4>
#endif

/* L2 */
struct digest_0 {
  bit<48> dmac;
  bit<48> smac;
  bit<16> etype;
  PortId_t port;
}
/* L2 Variation */
struct digest_1 {
  PortId_t port;
  bit<16> etype;
  bit<48> smac;
  bit<48> dmac;
}
/* V6 Flow */
struct digest_2 {
  bit<8>   protocol;
  PortId_t port;
  bit<48>  dmac;
  bit<48>  smac;
  bit<128> ip6_src;
  bit<128> ip6_dst;
}
/* Flow V4 */
struct digest_3 {
  bit<8>   protocol;
  PortId_t port;
  bit<48>  dmac;
  bit<48>  smac;
  bit<32> ip4_src;
  bit<32> ip4_dst;
}
/* Big field */
struct digest_4 {
  bit<376> f;
}
/* Small field */
struct digest_5 {
  bit<1> one_bit;
}
/* Valid fields */
struct digest_6 {
  bool ethernet_valid;
  bool ipv4_valid;
  bool ipv6_valid;
  bool big_valid;
}
#ifdef P4C_1149_FIXED
/* No field */
struct digest_7 {
}
#endif

struct metadata {
  PortId_t port;
}


header ethernet_h {
    bit<48> dmac;
    bit<48> smac;
    bit<16> etype;
}
header ipv4_h {
  bit<4>  version;
  bit<4>  ihl;
  bit<6>  dscp;
  bit<2>  ecn;
  bit<16> total_len;
  bit<16> identification;
  bit<1>  unused;
  bit<1>  dont_frag;
  bit<1>  more_frag;
  bit<13> frag_offset;
  bit<8>  ttl;
  bit<8>  protocol;
  bit<16> cksum;
  bit<32> src;
  bit<32> dst;
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
header big_h {
  bit<376> f;
}

struct headers {
    ethernet_h ethernet;
    ipv4_h     ipv4;
    ipv6_h     ipv6;
    big_h      big;
}

parser iPrsr(packet_in pkt, out headers hdr, out metadata md,
             out ingress_intrinsic_metadata_t ig_intr_md) {
  state start {
    pkt.extract(ig_intr_md);
#if __TARGET_TOFINO__ == 2
    pkt.advance(128 + 64);
#else
    pkt.advance(64);
#endif
    pkt.extract(hdr.ethernet);
    transition select (hdr.ethernet.etype) {
      0x0800  : parse_ipv4;
      0x86DD  : parse_ipv6;
      default : parse_big;
    }
  }
  state parse_ipv4 {
    pkt.extract(hdr.ipv4);
    transition accept;
  }
  state parse_ipv6 {
    pkt.extract(hdr.ipv6);
    transition accept;
  }
  state parse_big {
    pkt.extract(hdr.big);
    transition accept;
  }
}

control ig(inout headers hdr, inout metadata md,
           in ingress_intrinsic_metadata_t ig_intr_md,
           in ingress_intrinsic_metadata_from_parser_t ig_intr_prsr_md,
           inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprsr_md,
           inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {

  action gen_digest_0() { ig_intr_dprsr_md.digest_type = 0; }
  action gen_digest_1() { ig_intr_dprsr_md.digest_type = 1; }
  action gen_digest_2() { ig_intr_dprsr_md.digest_type = 2; }
  action gen_digest_3() { ig_intr_dprsr_md.digest_type = 3; }
  action gen_digest_4() { ig_intr_dprsr_md.digest_type = 4; }
  action gen_digest_5() { ig_intr_dprsr_md.digest_type = 5; }
  action gen_digest_6() { ig_intr_dprsr_md.digest_type = 6; }
  action gen_digest_7() { ig_intr_dprsr_md.digest_type = 7; }

  table digest_select {
    key = { hdr.ethernet.dmac : exact; }
    actions = {
      gen_digest_0;
      gen_digest_1;
      gen_digest_2;
      gen_digest_3;
      gen_digest_4;
      gen_digest_5;
      gen_digest_6;
      gen_digest_7;
    }
    size = 8;
    const entries = {
      (0) : gen_digest_0();
      (1) : gen_digest_1();
      (2) : gen_digest_2();
      (3) : gen_digest_3();
      (4) : gen_digest_4();
      (5) : gen_digest_5();
      (6) : gen_digest_6();
      (7) : gen_digest_7();
    }
  }

  action do_set_dest() {
    ig_intr_tm_md.ucast_egress_port = ig_intr_md.ingress_port;
    ig_intr_tm_md.bypass_egress = 1w1;
    md.port = ig_intr_md.ingress_port;
  }
  table set_dest {
    actions = { do_set_dest; }
    default_action = do_set_dest();
  }


  apply {
    digest_select.apply();
    set_dest.apply();
  }
}


control iDprsr(packet_out pkt, inout headers hdr, in metadata md,
               in ingress_intrinsic_metadata_for_deparser_t ig_intr_dprsr_md) {
  Digest<digest_0>() d0;
  Digest<digest_1>() d1;
  Digest<digest_2>() d2;
  Digest<digest_3>() d3;
  Digest<digest_4>() d4;
  Digest<digest_5>() d5;
  Digest<digest_6>() d6;
#ifdef P4C_1149_FIXED
  Digest<digest_7>() d7;
#endif
  apply {
    if (ig_intr_dprsr_md.digest_type == 0) {
      digest_0 d = { hdr.ethernet.dmac,
                     hdr.ethernet.smac,
                     hdr.ethernet.etype,
                     md.port };
      d0.pack( d );
    }
    if (ig_intr_dprsr_md.digest_type == 1) {
      digest_1 d = { md.port,
                    hdr.ethernet.etype,
                    hdr.ethernet.smac,
                    hdr.ethernet.dmac };
      d1.pack( d );

    }
    if (ig_intr_dprsr_md.digest_type == 2) {
      digest_2 d = { hdr.ipv6.next_hdr,
                     md.port,
                     hdr.ethernet.dmac,
                     hdr.ethernet.smac,
                     hdr.ipv6.src,
                     hdr.ipv6.dst };
      d2.pack( d );
    }
    if (ig_intr_dprsr_md.digest_type == 3) {
      digest_3 d = { hdr.ipv4.protocol,
                     md.port,
                     hdr.ethernet.dmac,
                     hdr.ethernet.smac,
                     hdr.ipv4.src,
                     hdr.ipv4.dst };
      d3.pack( d );
    }
    if (ig_intr_dprsr_md.digest_type == 4) {
      digest_4 d = { hdr.big.f };
      d4.pack( d );
    }
    if (ig_intr_dprsr_md.digest_type == 5) {
      digest_5 d = { hdr.ethernet.smac[3:3] };
      d5.pack( d );
    }
    if (ig_intr_dprsr_md.digest_type == 6) {
      digest_6 d = { hdr.ethernet.isValid(),
                     hdr.ipv4.isValid(),
                     hdr.ipv6.isValid(),
                     hdr.big.isValid() };
      d6.pack( d );
    }
#ifdef P4C_1149_FIXED
    if (ig_intr_dprsr_md.digest_type == 7) {
      digest_7 d = { };
      d7.pack( d );
    }
#endif
    pkt.emit(hdr);
  }
}

parser ePrsr(packet_in pkt, out headers hdr, out metadata md,
             out egress_intrinsic_metadata_t eg_intr_md) {
  state start { transition reject; }
}

control eg(inout headers hdr, inout metadata md, in egress_intrinsic_metadata_t eg_intr_md,
           in egress_intrinsic_metadata_from_parser_t eg_intr_prsr_md,
           inout egress_intrinsic_metadata_for_deparser_t eg_intr_dprsr_md,
           inout egress_intrinsic_metadata_for_output_port_t eg_intr_eport_md) {
  apply {}
}

control eDprsr(packet_out pkt, inout headers hdr, in metadata md,
               in egress_intrinsic_metadata_for_deparser_t eg_intr_dprsr_md) {
  apply {}
}

Pipeline(iPrsr(), ig(), iDprsr(), ePrsr(), eg(), eDprsr()) pipe;
Switch(pipe) main;
