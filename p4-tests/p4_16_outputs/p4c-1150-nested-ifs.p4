#include <core.p4>
#include <tofino.p4>
#include <tna.p4>

typedef bit<48> mac_addr_t;
typedef bit<32> b32;
typedef bit<16> b16;
typedef bit<1> b1;
struct digest_0 {
    bit<48>  dmac;
    bit<48>  smac;
    bit<16>  etype;
    PortId_t port;
}

struct digest_1 {
    bit<48>  dmac;
    bit<48>  smac;
    bit<128> ip6_src;
    bit<128> ip6_dst;
    bit<8>   protocol;
    PortId_t port;
}

struct digest_2 {
    bit<32> f;
}

struct digest_3 {
    bit<376> f;
}

struct digest_4 {
    bit<1> one_bit;
}

struct digest_5 {
}

struct mirror_0 {
}

struct metadata {
    PortId_t   port;
    bit<32>    digest2;
    MirrorId_t session_id;
}

header ethernet_h {
    bit<48> dmac;
    bit<48> smac;
    bit<16> etype;
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

header test1_h {
    bit<376> f;
}

struct headers {
    ethernet_h ethernet;
    ipv6_h     ipv6;
    test1_h    test1;
}

parser iPrsr(packet_in packet, out headers hdr, out metadata meta, out ingress_intrinsic_metadata_t ig_intr_md) {
    state start {
        packet.extract(ig_intr_md);
        packet.advance(PORT_METADATA_SIZE);
        packet.extract(hdr.ethernet);
        transition select(hdr.ethernet.etype) {
            0x86dd: parse_ipv6;
            default: parse_test1;
        }
    }
    state parse_ipv6 {
        packet.extract(hdr.ipv6);
        transition accept;
    }
    state parse_test1 {
        packet.extract(hdr.test1);
        transition accept;
    }
}

control ingress(inout headers hdr, inout metadata md, in ingress_intrinsic_metadata_t ig_intr_md, in ingress_intrinsic_metadata_from_parser_t ig_intr_prsr_md, inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprsr_md, inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {
    Random<bit<32>>() random32;
    action gen_digest_0() {
        ig_intr_dprsr_md.digest_type = 0;
    }
    action gen_digest_1() {
        ig_intr_dprsr_md.digest_type = 1;
    }
    action gen_digest_2() {
        md.digest2 = random32.get();
        ig_intr_dprsr_md.digest_type = 2;
    }
    action gen_digest_3() {
        ig_intr_dprsr_md.digest_type = 3;
    }
    action gen_digest_4() {
        ig_intr_dprsr_md.digest_type = 4;
    }
    action gen_digest_5() {
        ig_intr_dprsr_md.digest_type = 5;
    }
    action gen_digest_6() {
        ig_intr_dprsr_md.digest_type = 6;
    }
    action gen_digest_7() {
        ig_intr_dprsr_md.digest_type = 7;
    }
    table digest_select {
        key = {
            hdr.ethernet.dmac: exact;
        }
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
    }
    action do_set_dest() {
        ig_intr_tm_md.ucast_egress_port = ig_intr_md.ingress_port;
        ig_intr_tm_md.bypass_egress = true;
        md.port = ig_intr_md.ingress_port;
    }
    table set_dest {
        actions = {
            do_set_dest;
        }
        default_action = do_set_dest();
    }
    apply {
        digest_select.apply();
        set_dest.apply();
    }
}

control iDprsr(packet_out packet, inout headers hdr, in metadata md, in ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprs) {
    Mirror() m0;
    Mirror() m1;
    Digest<digest_0>() d0;
    Digest<digest_1>() d1;
    Digest<digest_2>() d2;
    Digest<digest_3>() d3;
    Digest<digest_4>() d4;
    Digest<digest_5>() d5;
    apply {
        if (ig_intr_md_for_dprs.digest_type == 0) {
            d0.pack({ hdr.ethernet.dmac, hdr.ethernet.smac, hdr.ethernet.etype, md.port });
        }
        else 
            if (ig_intr_md_for_dprs.digest_type == 1) {
                d1.pack({ hdr.ethernet.dmac, hdr.ethernet.smac, hdr.ipv6.src, hdr.ipv6.dst, hdr.ipv6.next_hdr, md.port });
            }
            else 
                if (ig_intr_md_for_dprs.digest_type == 2) {
                    d2.pack({ md.digest2 });
                }
                else 
                    if (ig_intr_md_for_dprs.digest_type == 3) {
                        d3.pack({ hdr.test1.f });
                    }
                    else 
                        if (ig_intr_md_for_dprs.digest_type == 4) {
                            digest_4 t = { hdr.ethernet.smac[0:0] };
                            d4.pack(t);
                        }
                        else 
                            if (ig_intr_md_for_dprs.digest_type == 5) {
                                digest_5 t = {  };
                                d5.pack(t);
                            }
        if (ig_intr_md_for_dprs.mirror_type == 0) {
            m0.emit(md.session_id, {  });
        }
        if (ig_intr_md_for_dprs.mirror_type != 0) {
            if (ig_intr_md_for_dprs.mirror_type == 1) {
                m1.emit(md.session_id, {  });
            }
        }
        packet.emit(hdr);
    }
}

parser ePrsr(packet_in packet, out headers hdr, out metadata meta, out egress_intrinsic_metadata_t eg_intr_md) {
    state start {
        transition reject;
    }
}

control egress(inout headers hdr, inout metadata meta, in egress_intrinsic_metadata_t eg_intr_md, in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr, inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprs, inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport) {
    apply {
    }
}

control eDprsr(packet_out packet, inout headers hdr, in metadata meta, in egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprs) {
    apply {
    }
}

Pipeline(iPrsr(), ingress(), iDprsr(), ePrsr(), egress(), eDprsr()) pipe;

Switch(pipe) main;

