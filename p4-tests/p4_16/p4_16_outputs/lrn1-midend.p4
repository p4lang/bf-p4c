#include <tna.p4>

struct tuple_0 {
    bit<8> field;
    bit<8> field_0;
    bit<8> field_1;
    bit<8> field_2;
    bit<8> field_3;
    bit<8> field_4;
    bit<8> field_5;
    bit<8> field_6;
    bit<8> field_7;
    bit<8> field_8;
    bit<8> field_9;
    bit<8> field_10;
    bit<8> field_11;
    bit<8> field_12;
    bit<8> field_13;
    bit<8> field_14;
}
#include <tna.p4>

struct digest_0 {
    bit<48>  dmac;
    bit<48>  smac;
    bit<16>  etype;
    PortId_t port;
}

struct digest_1 {
    PortId_t port;
    bit<16>  etype;
    bit<48>  smac;
    bit<48>  dmac;
}

struct digest_2 {
    bit<8>   protocol;
    PortId_t port;
    bit<48>  dmac;
    bit<48>  smac;
    bit<128> ip6_src;
    bit<128> ip6_dst;
}

struct digest_3 {
    bit<8>   protocol;
    PortId_t port;
    bit<48>  dmac;
    bit<48>  smac;
    bit<32>  ip4_src;
    bit<32>  ip4_dst;
}

struct digest_4 {
    bit<376> f;
}

struct digest_5 {
    bit<1> one_bit;
}

struct digest_6 {
    bool ethernet_valid;
    bool ipv4_valid;
    bool ipv6_valid;
    bool big_valid;
}

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
    bit<4>   version;
    bit<6>   ds;
    bit<2>   ecn;
    bit<20>  flow_label;
    bit<16>  payload_len;
    bit<8>   next_hdr;
    bit<8>   hop_limit;
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

parser iPrsr(packet_in pkt, out headers hdr, out metadata md, out ingress_intrinsic_metadata_t ig_intr_md) {
    state start {
        pkt.extract<ingress_intrinsic_metadata_t>(ig_intr_md);
        pkt.advance(32w64);
        pkt.extract<ethernet_h>(hdr.ethernet);
        transition select(hdr.ethernet.etype) {
            16w0x800: parse_ipv4;
            16w0x86dd: parse_ipv6;
            default: parse_big;
        }
    }
    state parse_ipv4 {
        pkt.extract<ipv4_h>(hdr.ipv4);
        transition accept;
    }
    state parse_ipv6 {
        pkt.extract<ipv6_h>(hdr.ipv6);
        transition accept;
    }
    state parse_big {
        pkt.extract<big_h>(hdr.big);
        transition accept;
    }
}

control ig(inout headers hdr, inout metadata md, in ingress_intrinsic_metadata_t ig_intr_md, in ingress_intrinsic_metadata_from_parser_t ig_intr_prsr_md, inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprsr_md, inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {
    @name(".NoAction") action NoAction_0() {
    }
    @name("ig.gen_digest_0") action gen_digest_0() {
        ig_intr_dprsr_md.digest_type = 3w0;
    }
    @name("ig.gen_digest_1") action gen_digest_1() {
        ig_intr_dprsr_md.digest_type = 3w1;
    }
    @name("ig.gen_digest_2") action gen_digest_2() {
        ig_intr_dprsr_md.digest_type = 3w2;
    }
    @name("ig.gen_digest_3") action gen_digest_3() {
        ig_intr_dprsr_md.digest_type = 3w3;
    }
    @name("ig.gen_digest_4") action gen_digest_4() {
        ig_intr_dprsr_md.digest_type = 3w4;
    }
    @name("ig.gen_digest_5") action gen_digest_5() {
        ig_intr_dprsr_md.digest_type = 3w5;
    }
    @name("ig.gen_digest_6") action gen_digest_6() {
        ig_intr_dprsr_md.digest_type = 3w6;
    }
    @name("ig.gen_digest_7") action gen_digest_7() {
        ig_intr_dprsr_md.digest_type = 3w7;
    }
    @name("ig.digest_select") table digest_select_0 {
        key = {
            hdr.ethernet.dmac: exact @name("hdr.ethernet.dmac") ;
        }
        actions = {
            gen_digest_0();
            gen_digest_1();
            gen_digest_2();
            gen_digest_3();
            gen_digest_4();
            gen_digest_5();
            gen_digest_6();
            gen_digest_7();
            @defaultonly NoAction_0();
        }
        size = 8;
        const entries = {
                        48w0 : gen_digest_0();

                        48w1 : gen_digest_1();

                        48w2 : gen_digest_2();

                        48w3 : gen_digest_3();

                        48w4 : gen_digest_4();

                        48w5 : gen_digest_5();

                        48w6 : gen_digest_6();

                        48w7 : gen_digest_7();

        }

        default_action = NoAction_0();
    }
    @name("ig.do_set_dest") action do_set_dest() {
        ig_intr_tm_md.ucast_egress_port = ig_intr_md.ingress_port;
        ig_intr_tm_md.bypass_egress = true;
        md.port = ig_intr_md.ingress_port;
    }
    @name("ig.set_dest") table set_dest_0 {
        actions = {
            do_set_dest();
        }
        default_action = do_set_dest();
    }
    apply {
        digest_select_0.apply();
        set_dest_0.apply();
    }
}

control iDprsr(packet_out pkt, inout headers hdr, in metadata md, in ingress_intrinsic_metadata_for_deparser_t ig_intr_dprsr_md) {
    digest_0 d_0;
    digest_1 d_1;
    digest_2 d_2;
    digest_3 d_3;
    digest_4 d_4;
    digest_5 d_5;
    digest_6 d_6;
    @name("iDprsr.d0") Digest<digest_0>() d0_0;
    @name("iDprsr.d1") Digest<digest_1>() d1_0;
    @name("iDprsr.d2") Digest<digest_2>() d2_0;
    @name("iDprsr.d3") Digest<digest_3>() d3_0;
    @name("iDprsr.d4") Digest<digest_4>() d4_0;
    @name("iDprsr.d5") Digest<digest_5>() d5_0;
    @name("iDprsr.d6") Digest<digest_6>() d6_0;
    @hidden action act() {
        d_0.dmac = hdr.ethernet.dmac;
        d_0.smac = hdr.ethernet.smac;
        d_0.etype = hdr.ethernet.etype;
        d_0.port = md.port;
        d0_0.pack(d_0);
    }
    @hidden action act_0() {
        d_1.port = md.port;
        d_1.etype = hdr.ethernet.etype;
        d_1.smac = hdr.ethernet.smac;
        d_1.dmac = hdr.ethernet.dmac;
        d1_0.pack(d_1);
    }
    @hidden action act_1() {
        d_2.protocol = hdr.ipv6.next_hdr;
        d_2.port = md.port;
        d_2.dmac = hdr.ethernet.dmac;
        d_2.smac = hdr.ethernet.smac;
        d_2.ip6_src = hdr.ipv6.src;
        d_2.ip6_dst = hdr.ipv6.dst;
        d2_0.pack(d_2);
    }
    @hidden action act_2() {
        d_3.protocol = hdr.ipv4.protocol;
        d_3.port = md.port;
        d_3.dmac = hdr.ethernet.dmac;
        d_3.smac = hdr.ethernet.smac;
        d_3.ip4_src = hdr.ipv4.src;
        d_3.ip4_dst = hdr.ipv4.dst;
        d3_0.pack(d_3);
    }
    @hidden action act_3() {
        d_4.f = hdr.big.f;
        d4_0.pack(d_4);
    }
    @hidden action act_4() {
        d_5.one_bit = hdr.ethernet.smac[3:3];
        d5_0.pack(d_5);
    }
    @hidden action act_5() {
        d_6.ethernet_valid = hdr.ethernet.isValid();
        d_6.ipv4_valid = hdr.ipv4.isValid();
        d_6.ipv6_valid = hdr.ipv6.isValid();
        d_6.big_valid = hdr.big.isValid();
        d6_0.pack(d_6);
    }
    @hidden action act_6() {
        pkt.emit<ethernet_h>(hdr.ethernet);
        pkt.emit<ipv4_h>(hdr.ipv4);
        pkt.emit<ipv6_h>(hdr.ipv6);
        pkt.emit<big_h>(hdr.big);
    }
    @hidden table tbl_act {
        actions = {
            act();
        }
        const default_action = act();
    }
    @hidden table tbl_act_0 {
        actions = {
            act_0();
        }
        const default_action = act_0();
    }
    @hidden table tbl_act_1 {
        actions = {
            act_1();
        }
        const default_action = act_1();
    }
    @hidden table tbl_act_2 {
        actions = {
            act_2();
        }
        const default_action = act_2();
    }
    @hidden table tbl_act_3 {
        actions = {
            act_3();
        }
        const default_action = act_3();
    }
    @hidden table tbl_act_4 {
        actions = {
            act_4();
        }
        const default_action = act_4();
    }
    @hidden table tbl_act_5 {
        actions = {
            act_5();
        }
        const default_action = act_5();
    }
    @hidden table tbl_act_6 {
        actions = {
            act_6();
        }
        const default_action = act_6();
    }
    apply {
        if (ig_intr_dprsr_md.digest_type == 3w0) {
            tbl_act.apply();
        }
        if (ig_intr_dprsr_md.digest_type == 3w1) {
            tbl_act_0.apply();
        }
        if (ig_intr_dprsr_md.digest_type == 3w2) {
            tbl_act_1.apply();
        }
        if (ig_intr_dprsr_md.digest_type == 3w3) {
            tbl_act_2.apply();
        }
        if (ig_intr_dprsr_md.digest_type == 3w4) {
            tbl_act_3.apply();
        }
        if (ig_intr_dprsr_md.digest_type == 3w5) {
            tbl_act_4.apply();
        }
        if (ig_intr_dprsr_md.digest_type == 3w6) {
            tbl_act_5.apply();
        }
        tbl_act_6.apply();
    }
}

parser ePrsr(packet_in pkt, out headers hdr, out metadata md, out egress_intrinsic_metadata_t eg_intr_md) {
    state start {
        transition reject;
    }
}

control eg(inout headers hdr, inout metadata md, in egress_intrinsic_metadata_t eg_intr_md, in egress_intrinsic_metadata_from_parser_t eg_intr_prsr_md, inout egress_intrinsic_metadata_for_deparser_t eg_intr_dprsr_md, inout egress_intrinsic_metadata_for_output_port_t eg_intr_eport_md) {
    apply {
    }
}

control eDprsr(packet_out pkt, inout headers hdr, in metadata md, in egress_intrinsic_metadata_for_deparser_t eg_intr_dprsr_md) {
    apply {
    }
}

Pipeline<headers, metadata, headers, metadata>(iPrsr(), ig(), iDprsr(), ePrsr(), eg(), eDprsr()) pipe;

Switch<headers, metadata, headers, metadata, _, _, _, _, _, _, _, _, _, _, _, _>(pipe) main;
