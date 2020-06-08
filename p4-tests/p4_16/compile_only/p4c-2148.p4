#include <core.p4>
#include <tofino.p4>
#include <tna.p4>       /* TOFINO1_ONLY */

header bridged_header_t {
    bit<8>  bridged_metadata_indicator;
    bit<16> residual_checksum_0;
    bit<16> residual_checksum_1;
    bit<16> residual_checksum_2;
    bit<16> residual_checksum_3;
}

struct compiler_generated_metadata_t {
    bit<10> mirror_id;
    bit<8>  mirror_source;
    bit<8>  resubmit_source;
    bit<4>  clone_src;
    bit<4>  clone_digest_id;
    bit<32> instance_type;
}

struct l4_lookup_t {
    bit<16> word_1;
    bit<16> word_2;
    bit<1>  first_frag;
}

struct meta_t {
    bit<1> ipv4_checksum_update;
    bit<1> ipv4_tcp_checksum_update;
    bit<1> ipv4_udp_checksum_update;
    bit<1> ipv6_tcp_checksum_update;
    bit<1> ipv6_udp_checksum_update;
}

struct standard_metadata_t {
    bit<9>  ingress_port;
    bit<32> packet_length;
    bit<9>  egress_spec;
    bit<9>  egress_port;
    bit<16> egress_instance;
    bit<32> instance_type;
    bit<8>  parser_status;
    bit<8>  parser_error_location;
}

header ethernet_t {
    bit<48> dstAddr;
    bit<48> srcAddr;
    bit<16> etherType;
}

header icmp_t {
    bit<16> typeCode;
    bit<16> checksum;
}

@name("generator_metadata_t") header generator_metadata_t_0 {
    bit<16> app_id;
    bit<16> batch_id;
    bit<16> instance_id;
}

header igmp_t {
    bit<16> typeCode;
    bit<16> checksum;
}

header ipv4_t {
    bit<4>  version;
    bit<4>  ihl;
    bit<8>  diffserv;
    bit<16> totalLen;
    bit<16> identification;
    bit<3>  flags;
    bit<13> fragOffset;
    bit<8>  ttl;
    bit<8>  protocol;
    bit<16> hdrChecksum;
    bit<32> srcAddr;
    bit<32> dstAddr;
}

header option_word_t {
    bit<32> data;
}

header ipv6_t {
    bit<4>   version;
    bit<8>   trafficClass;
    bit<20>  flowLabel;
    bit<16>  payloadLen;
    bit<8>   nextHdr;
    bit<8>   hopLimit;
    bit<128> srcAddr;
    bit<128> dstAddr;
}

header tcp_t {
    bit<16> srcPort;
    bit<16> dstPort;
    bit<32> seqNo;
    bit<32> ackNo;
    bit<4>  dataOffset;
    bit<4>  res;
    bit<8>  flags;
    bit<16> window;
}

header tcp_checksum_t {
    bit<16> checksum;
    bit<16> urgentPtr;
}

header udp_t {
    bit<16> srcPort;
    bit<16> dstPort;
    bit<16> length_;
}

header udp_checksum_t {
    bit<16> checksum;
}

header vlan_tag_t {
    bit<3>  pcp;
    bit<1>  cfi;
    bit<12> vid;
    bit<16> etherType;
}

struct metadata {
    @name(".bridged_header")
    bridged_header_t                            bridged_header;
    @name(".compiler_generated_meta")
    compiler_generated_metadata_t               compiler_generated_meta;
    @name(".eg_intr_md")
    egress_intrinsic_metadata_t                 eg_intr_md;
    @name(".eg_intr_md_for_dprsr")
    egress_intrinsic_metadata_for_deparser_t    eg_intr_md_for_dprsr;
    @name(".eg_intr_md_for_oport")
    egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport;
    @name(".eg_intr_md_from_parser_aux")
    egress_intrinsic_metadata_from_parser_t     eg_intr_md_from_parser_aux;
    @name(".ig_intr_md")
    ingress_intrinsic_metadata_t                ig_intr_md;
    @name(".ig_intr_md_for_tm")
    ingress_intrinsic_metadata_for_tm_t         ig_intr_md_for_tm;
    @name(".ig_intr_md_from_parser_aux")
    ingress_intrinsic_metadata_from_parser_t    ig_intr_md_from_parser_aux;
    @name(".l4_lookup")
    l4_lookup_t                                 l4_lookup;
    @name(".meta")
    meta_t                                      meta;
    @name(".standard_metadata")
    standard_metadata_t                         standard_metadata;
}

struct headers {
    @name(".ethernet")
    ethernet_t     ethernet;
    @name(".icmp")
    icmp_t         icmp;
    @name(".igmp")
    igmp_t         igmp;
    @name(".ipv4")
    ipv4_t         ipv4;
    @name(".ipv4_option_word_1")
    option_word_t  ipv4_option_word_1;
    @name(".ipv4_option_word_10")
    option_word_t  ipv4_option_word_10;
    @name(".ipv4_option_word_2")
    option_word_t  ipv4_option_word_2;
    @name(".ipv4_option_word_3")
    option_word_t  ipv4_option_word_3;
    @name(".ipv4_option_word_4")
    option_word_t  ipv4_option_word_4;
    @name(".ipv4_option_word_5")
    option_word_t  ipv4_option_word_5;
    @name(".ipv4_option_word_6")
    option_word_t  ipv4_option_word_6;
    @name(".ipv4_option_word_7")
    option_word_t  ipv4_option_word_7;
    @name(".ipv4_option_word_8")
    option_word_t  ipv4_option_word_8;
    @name(".ipv4_option_word_9")
    option_word_t  ipv4_option_word_9;
    @name(".ipv6")
    ipv6_t         ipv6;
    @name(".tcp")
    tcp_t          tcp;
    @name(".tcp_checksum_v4")
    tcp_checksum_t tcp_checksum_v4;
    @name(".tcp_checksum_v6")
    tcp_checksum_t tcp_checksum_v6;
    @name(".udp")
    udp_t          udp;
    @name(".udp_checksum_v4")
    udp_checksum_t udp_checksum_v4;
    @name(".udp_checksum_v6")
    udp_checksum_t udp_checksum_v6;
    @name(".vlan_tag")
    vlan_tag_t[2]  vlan_tag;
}

parser IngressParserImpl(packet_in pkt, out headers hdr, out metadata meta, out ingress_intrinsic_metadata_t ig_intr_md) {
    Checksum() checksum_10;
    Checksum() checksum_11;
    Checksum() checksum_12;
    Checksum() checksum_13;
    Checksum() checksum_9;
    @name(".parse_first_fragment") state parse_first_fragment {
        meta.l4_lookup.first_frag = 1w1;
        transition accept;
    }
    @name(".parse_icmp") state parse_icmp {
        pkt.extract(hdr.icmp);
        transition parse_first_fragment;
    }
    @name(".parse_igmp") state parse_igmp {
        pkt.extract(hdr.igmp);
        transition parse_first_fragment;
    }
    @name(".parse_ipv4") state parse_ipv4 {
        pkt.extract(hdr.ipv4);
        checksum_10.subtract(hdr.ipv4.srcAddr);
        checksum_10.subtract(hdr.ipv4.dstAddr);
        checksum_10.subtract(8w0);
        checksum_10.subtract(hdr.ipv4.protocol);
        checksum_10.subtract(hdr.ipv4.totalLen);
        checksum_12.subtract(hdr.ipv4.srcAddr);
        checksum_12.subtract(hdr.ipv4.dstAddr);
        checksum_12.subtract(8w0);
        checksum_12.subtract(hdr.ipv4.protocol);
        checksum_12.subtract(hdr.ipv4.totalLen);
        checksum_9.add(hdr.ipv4.version);
        checksum_9.add(hdr.ipv4.ihl);
        checksum_9.add(hdr.ipv4.diffserv);
        checksum_9.add(hdr.ipv4.totalLen);
        checksum_9.add(hdr.ipv4.identification);
        checksum_9.add(hdr.ipv4.flags);
        checksum_9.add(hdr.ipv4.fragOffset);
        checksum_9.add(hdr.ipv4.ttl);
        checksum_9.add(hdr.ipv4.protocol);
        checksum_9.add(hdr.ipv4.srcAddr);
        checksum_9.add(hdr.ipv4.dstAddr);
        checksum_9.add(hdr.ipv4.hdrChecksum);
        transition select(hdr.ipv4.ihl) {
            4w0x5: parse_ipv4_no_options;
            4w0x6: parse_ipv4_options_1;
            4w0x7: parse_ipv4_options_2;
            4w0x8: parse_ipv4_options_3;
            4w0x9: parse_ipv4_options_4;
            4w0xa: parse_ipv4_options_5;
            4w0xb: parse_ipv4_options_6;
            4w0xc: parse_ipv4_options_7;
            4w0xd: parse_ipv4_options_8;
            4w0xe: parse_ipv4_options_9;
            4w0xf: parse_ipv4_options_10;
            4w0x0 &&& 4w0x0: parse_first_fragment;
            default: accept;
        }
    }
    @name(".parse_ipv4_no_options") state parse_ipv4_no_options {
        meta.l4_lookup.word_1 = (pkt.lookahead<bit<16>>())[15:0];
        meta.l4_lookup.word_2 = (pkt.lookahead<bit<32>>())[15:0];
        transition select(hdr.ipv4.fragOffset, hdr.ipv4.protocol) {
            (13w0x0, 8w0x1): parse_icmp;
            (13w0x0, 8w0x2): parse_igmp;
            (13w0x0, 8w0x6): parse_tcp_v4;
            (13w0x0, 8w0x11): parse_udp_v4;
            (13w0x0 &&& 13w0x1fff, 8w0x0 &&& 8w0x0): parse_first_fragment;
            default: accept;
        }
    }
    @name(".parse_ipv4_options_1") state parse_ipv4_options_1 {
        pkt.extract(hdr.ipv4_option_word_1);
        meta.l4_lookup.word_1 = (pkt.lookahead<bit<16>>())[15:0];
        meta.l4_lookup.word_2 = (pkt.lookahead<bit<32>>())[15:0];
        checksum_9.add(hdr.ipv4_option_word_1.data);
        transition select(hdr.ipv4.fragOffset, hdr.ipv4.protocol) {
            (13w0x0, 8w0x1): parse_icmp;
            (13w0x0, 8w0x2): parse_igmp;
            (13w0x0, 8w0x6): parse_tcp_v4;
            (13w0x0, 8w0x11): parse_udp_v4;
            (13w0x0 &&& 13w0x1fff, 8w0x0 &&& 8w0x0): parse_first_fragment;
            default: accept;
        }
    }
    @name(".parse_ipv4_options_10") state parse_ipv4_options_10 {
        pkt.extract(hdr.ipv4_option_word_1);
        pkt.extract(hdr.ipv4_option_word_2);
        pkt.extract(hdr.ipv4_option_word_3);
        pkt.extract(hdr.ipv4_option_word_4);
        pkt.extract(hdr.ipv4_option_word_5);
        pkt.extract(hdr.ipv4_option_word_6);
        pkt.extract(hdr.ipv4_option_word_7);
        pkt.extract(hdr.ipv4_option_word_8);
        pkt.extract(hdr.ipv4_option_word_9);
        pkt.extract(hdr.ipv4_option_word_10);
        meta.l4_lookup.word_1 = (pkt.lookahead<bit<16>>())[15:0];
        meta.l4_lookup.word_2 = (pkt.lookahead<bit<32>>())[15:0];
        checksum_9.add(hdr.ipv4_option_word_1.data);
        checksum_9.add(hdr.ipv4_option_word_2.data);
        checksum_9.add(hdr.ipv4_option_word_3.data);
        checksum_9.add(hdr.ipv4_option_word_4.data);
        checksum_9.add(hdr.ipv4_option_word_5.data);
        checksum_9.add(hdr.ipv4_option_word_6.data);
        checksum_9.add(hdr.ipv4_option_word_7.data);
        checksum_9.add(hdr.ipv4_option_word_8.data);
        checksum_9.add(hdr.ipv4_option_word_9.data);
        checksum_9.add(hdr.ipv4_option_word_10.data);
        transition select(hdr.ipv4.fragOffset, hdr.ipv4.protocol) {
            (13w0x0, 8w0x1): parse_icmp;
            (13w0x0, 8w0x2): parse_igmp;
            (13w0x0, 8w0x6): parse_tcp_v4;
            (13w0x0, 8w0x11): parse_udp_v4;
            (13w0x0 &&& 13w0x1fff, 8w0x0 &&& 8w0x0): parse_first_fragment;
            default: accept;
        }
    }
    @name(".parse_ipv4_options_2") state parse_ipv4_options_2 {
        pkt.extract(hdr.ipv4_option_word_1);
        pkt.extract(hdr.ipv4_option_word_2);
        meta.l4_lookup.word_1 = (pkt.lookahead<bit<16>>())[15:0];
        meta.l4_lookup.word_2 = (pkt.lookahead<bit<32>>())[15:0];
        checksum_9.add(hdr.ipv4_option_word_1.data);
        checksum_9.add(hdr.ipv4_option_word_2.data);
        transition select(hdr.ipv4.fragOffset, hdr.ipv4.protocol) {
            (13w0x0, 8w0x1): parse_icmp;
            (13w0x0, 8w0x2): parse_igmp;
            (13w0x0, 8w0x6): parse_tcp_v4;
            (13w0x0, 8w0x11): parse_udp_v4;
            (13w0x0 &&& 13w0x1fff, 8w0x0 &&& 8w0x0): parse_first_fragment;
            default: accept;
        }
    }
    @name(".parse_ipv4_options_3") state parse_ipv4_options_3 {
        pkt.extract(hdr.ipv4_option_word_1);
        pkt.extract(hdr.ipv4_option_word_2);
        pkt.extract(hdr.ipv4_option_word_3);
        meta.l4_lookup.word_1 = (pkt.lookahead<bit<16>>())[15:0];
        meta.l4_lookup.word_2 = (pkt.lookahead<bit<32>>())[15:0];
        checksum_9.add(hdr.ipv4_option_word_1.data);
        checksum_9.add(hdr.ipv4_option_word_2.data);
        checksum_9.add(hdr.ipv4_option_word_3.data);
        transition select(hdr.ipv4.fragOffset, hdr.ipv4.protocol) {
            (13w0x0, 8w0x1): parse_icmp;
            (13w0x0, 8w0x2): parse_igmp;
            (13w0x0, 8w0x6): parse_tcp_v4;
            (13w0x0, 8w0x11): parse_udp_v4;
            (13w0x0 &&& 13w0x1fff, 8w0x0 &&& 8w0x0): parse_first_fragment;
            default: accept;
        }
    }
    @name(".parse_ipv4_options_4") state parse_ipv4_options_4 {
        pkt.extract(hdr.ipv4_option_word_1);
        pkt.extract(hdr.ipv4_option_word_2);
        pkt.extract(hdr.ipv4_option_word_3);
        pkt.extract(hdr.ipv4_option_word_4);
        meta.l4_lookup.word_1 = (pkt.lookahead<bit<16>>())[15:0];
        meta.l4_lookup.word_2 = (pkt.lookahead<bit<32>>())[15:0];
        checksum_9.add(hdr.ipv4_option_word_1.data);
        checksum_9.add(hdr.ipv4_option_word_2.data);
        checksum_9.add(hdr.ipv4_option_word_3.data);
        checksum_9.add(hdr.ipv4_option_word_4.data);
        transition select(hdr.ipv4.fragOffset, hdr.ipv4.protocol) {
            (13w0x0, 8w0x1): parse_icmp;
            (13w0x0, 8w0x2): parse_igmp;
            (13w0x0, 8w0x6): parse_tcp_v4;
            (13w0x0, 8w0x11): parse_udp_v4;
            (13w0x0 &&& 13w0x1fff, 8w0x0 &&& 8w0x0): parse_first_fragment;
            default: accept;
        }
    }
    @name(".parse_ipv4_options_5") state parse_ipv4_options_5 {
        pkt.extract(hdr.ipv4_option_word_1);
        pkt.extract(hdr.ipv4_option_word_2);
        pkt.extract(hdr.ipv4_option_word_3);
        pkt.extract(hdr.ipv4_option_word_4);
        pkt.extract(hdr.ipv4_option_word_5);
        meta.l4_lookup.word_1 = (pkt.lookahead<bit<16>>())[15:0];
        meta.l4_lookup.word_2 = (pkt.lookahead<bit<32>>())[15:0];
        checksum_9.add(hdr.ipv4_option_word_1.data);
        checksum_9.add(hdr.ipv4_option_word_2.data);
        checksum_9.add(hdr.ipv4_option_word_3.data);
        checksum_9.add(hdr.ipv4_option_word_4.data);
        checksum_9.add(hdr.ipv4_option_word_5.data);
        transition select(hdr.ipv4.fragOffset, hdr.ipv4.protocol) {
            (13w0x0, 8w0x1): parse_icmp;
            (13w0x0, 8w0x2): parse_igmp;
            (13w0x0, 8w0x6): parse_tcp_v4;
            (13w0x0, 8w0x11): parse_udp_v4;
            (13w0x0 &&& 13w0x1fff, 8w0x0 &&& 8w0x0): parse_first_fragment;
            default: accept;
        }
    }
    @name(".parse_ipv4_options_6") state parse_ipv4_options_6 {
        pkt.extract(hdr.ipv4_option_word_1);
        pkt.extract(hdr.ipv4_option_word_2);
        pkt.extract(hdr.ipv4_option_word_3);
        pkt.extract(hdr.ipv4_option_word_4);
        pkt.extract(hdr.ipv4_option_word_5);
        pkt.extract(hdr.ipv4_option_word_6);
        meta.l4_lookup.word_1 = (pkt.lookahead<bit<16>>())[15:0];
        meta.l4_lookup.word_2 = (pkt.lookahead<bit<32>>())[15:0];
        checksum_9.add(hdr.ipv4_option_word_1.data);
        checksum_9.add(hdr.ipv4_option_word_2.data);
        checksum_9.add(hdr.ipv4_option_word_3.data);
        checksum_9.add(hdr.ipv4_option_word_4.data);
        checksum_9.add(hdr.ipv4_option_word_5.data);
        checksum_9.add(hdr.ipv4_option_word_6.data);
        transition select(hdr.ipv4.fragOffset, hdr.ipv4.protocol) {
            (13w0x0, 8w0x1): parse_icmp;
            (13w0x0, 8w0x2): parse_igmp;
            (13w0x0, 8w0x6): parse_tcp_v4;
            (13w0x0, 8w0x11): parse_udp_v4;
            (13w0x0 &&& 13w0x1fff, 8w0x0 &&& 8w0x0): parse_first_fragment;
            default: accept;
        }
    }
    @name(".parse_ipv4_options_7") state parse_ipv4_options_7 {
        pkt.extract(hdr.ipv4_option_word_1);
        pkt.extract(hdr.ipv4_option_word_2);
        pkt.extract(hdr.ipv4_option_word_3);
        pkt.extract(hdr.ipv4_option_word_4);
        pkt.extract(hdr.ipv4_option_word_5);
        pkt.extract(hdr.ipv4_option_word_6);
        pkt.extract(hdr.ipv4_option_word_7);
        meta.l4_lookup.word_1 = (pkt.lookahead<bit<16>>())[15:0];
        meta.l4_lookup.word_2 = (pkt.lookahead<bit<32>>())[15:0];
        checksum_9.add(hdr.ipv4_option_word_1.data);
        checksum_9.add(hdr.ipv4_option_word_2.data);
        checksum_9.add(hdr.ipv4_option_word_3.data);
        checksum_9.add(hdr.ipv4_option_word_4.data);
        checksum_9.add(hdr.ipv4_option_word_5.data);
        checksum_9.add(hdr.ipv4_option_word_6.data);
        checksum_9.add(hdr.ipv4_option_word_7.data);
        transition select(hdr.ipv4.fragOffset, hdr.ipv4.protocol) {
            (13w0x0, 8w0x1): parse_icmp;
            (13w0x0, 8w0x2): parse_igmp;
            (13w0x0, 8w0x6): parse_tcp_v4;
            (13w0x0, 8w0x11): parse_udp_v4;
            (13w0x0 &&& 13w0x1fff, 8w0x0 &&& 8w0x0): parse_first_fragment;
            default: accept;
        }
    }
    @name(".parse_ipv4_options_8") state parse_ipv4_options_8 {
        pkt.extract(hdr.ipv4_option_word_1);
        pkt.extract(hdr.ipv4_option_word_2);
        pkt.extract(hdr.ipv4_option_word_3);
        pkt.extract(hdr.ipv4_option_word_4);
        pkt.extract(hdr.ipv4_option_word_5);
        pkt.extract(hdr.ipv4_option_word_6);
        pkt.extract(hdr.ipv4_option_word_7);
        pkt.extract(hdr.ipv4_option_word_8);
        meta.l4_lookup.word_1 = (pkt.lookahead<bit<16>>())[15:0];
        meta.l4_lookup.word_2 = (pkt.lookahead<bit<32>>())[15:0];
        checksum_9.add(hdr.ipv4_option_word_1.data);
        checksum_9.add(hdr.ipv4_option_word_2.data);
        checksum_9.add(hdr.ipv4_option_word_3.data);
        checksum_9.add(hdr.ipv4_option_word_4.data);
        checksum_9.add(hdr.ipv4_option_word_5.data);
        checksum_9.add(hdr.ipv4_option_word_6.data);
        checksum_9.add(hdr.ipv4_option_word_7.data);
        checksum_9.add(hdr.ipv4_option_word_8.data);
        transition select(hdr.ipv4.fragOffset, hdr.ipv4.protocol) {
            (13w0x0, 8w0x1): parse_icmp;
            (13w0x0, 8w0x2): parse_igmp;
            (13w0x0, 8w0x6): parse_tcp_v4;
            (13w0x0, 8w0x11): parse_udp_v4;
            (13w0x0 &&& 13w0x1fff, 8w0x0 &&& 8w0x0): parse_first_fragment;
            default: accept;
        }
    }
    @name(".parse_ipv4_options_9") state parse_ipv4_options_9 {
        pkt.extract(hdr.ipv4_option_word_1);
        pkt.extract(hdr.ipv4_option_word_2);
        pkt.extract(hdr.ipv4_option_word_3);
        pkt.extract(hdr.ipv4_option_word_4);
        pkt.extract(hdr.ipv4_option_word_5);
        pkt.extract(hdr.ipv4_option_word_6);
        pkt.extract(hdr.ipv4_option_word_7);
        pkt.extract(hdr.ipv4_option_word_8);
        pkt.extract(hdr.ipv4_option_word_9);
        meta.l4_lookup.word_1 = (pkt.lookahead<bit<16>>())[15:0];
        meta.l4_lookup.word_2 = (pkt.lookahead<bit<32>>())[15:0];
        checksum_9.add(hdr.ipv4_option_word_1.data);
        checksum_9.add(hdr.ipv4_option_word_2.data);
        checksum_9.add(hdr.ipv4_option_word_3.data);
        checksum_9.add(hdr.ipv4_option_word_4.data);
        checksum_9.add(hdr.ipv4_option_word_5.data);
        checksum_9.add(hdr.ipv4_option_word_6.data);
        checksum_9.add(hdr.ipv4_option_word_7.data);
        checksum_9.add(hdr.ipv4_option_word_8.data);
        checksum_9.add(hdr.ipv4_option_word_9.data);
        transition select(hdr.ipv4.fragOffset, hdr.ipv4.protocol) {
            (13w0x0, 8w0x1): parse_icmp;
            (13w0x0, 8w0x2): parse_igmp;
            (13w0x0, 8w0x6): parse_tcp_v4;
            (13w0x0, 8w0x11): parse_udp_v4;
            (13w0x0 &&& 13w0x1fff, 8w0x0 &&& 8w0x0): parse_first_fragment;
            default: accept;
        }
    }
    @name(".parse_ipv6") state parse_ipv6 {
        pkt.extract(hdr.ipv6);
        meta.l4_lookup.word_1 = (pkt.lookahead<bit<16>>())[15:0];
        meta.l4_lookup.word_2 = (pkt.lookahead<bit<32>>())[15:0];
        checksum_11.subtract(hdr.ipv6.srcAddr);
        checksum_11.subtract(hdr.ipv6.dstAddr);
        checksum_11.subtract(hdr.ipv6.payloadLen);
        checksum_11.subtract(8w0);
        checksum_11.subtract(hdr.ipv6.nextHdr);
        checksum_13.subtract(hdr.ipv6.srcAddr);
        checksum_13.subtract(hdr.ipv6.dstAddr);
        checksum_13.subtract(hdr.ipv6.payloadLen);
        checksum_13.subtract(8w0);
        checksum_13.subtract(hdr.ipv6.nextHdr);
        transition select(hdr.ipv6.nextHdr) {
            8w0x1: parse_icmp;
            8w0x2: parse_igmp;
            8w0x6: parse_tcp_v6;
            8w0x11: parse_udp_v6;
            8w0x0 &&& 8w0x0: parse_first_fragment;
            default: accept;
        }
    }
    @name(".parse_tcp_v4") state parse_tcp_v4 {
        pkt.extract(hdr.tcp);
        pkt.extract(hdr.tcp_checksum_v4);
        checksum_10.subtract(hdr.tcp.srcPort);
        checksum_10.subtract(hdr.tcp.dstPort);
        checksum_10.subtract(hdr.tcp.seqNo);
        checksum_10.subtract(hdr.tcp.ackNo);
        checksum_10.subtract(hdr.tcp.dataOffset);
        checksum_10.subtract(hdr.tcp.res);
        checksum_10.subtract(hdr.tcp.flags);
        checksum_10.subtract(hdr.tcp.window);
        checksum_11.subtract(hdr.tcp.srcPort);
        checksum_11.subtract(hdr.tcp.dstPort);
        checksum_11.subtract(hdr.tcp.seqNo);
        checksum_11.subtract(hdr.tcp.ackNo);
        checksum_11.subtract(hdr.tcp.dataOffset);
        checksum_11.subtract(hdr.tcp.res);
        checksum_11.subtract(hdr.tcp.flags);
        checksum_11.subtract(hdr.tcp.window);
        checksum_10.subtract(hdr.tcp_checksum_v4.urgentPtr);
        checksum_10.subtract(hdr.tcp_checksum_v4.checksum);
        checksum_10.subtract_all_and_deposit(meta.bridged_header.residual_checksum_0);
        transition parse_first_fragment;
    }
    @name(".parse_tcp_v6") state parse_tcp_v6 {
        pkt.extract(hdr.tcp);
        pkt.extract(hdr.tcp_checksum_v6);
        checksum_10.subtract(hdr.tcp.srcPort);
        checksum_10.subtract(hdr.tcp.dstPort);
        checksum_10.subtract(hdr.tcp.seqNo);
        checksum_10.subtract(hdr.tcp.ackNo);
        checksum_10.subtract(hdr.tcp.dataOffset);
        checksum_10.subtract(hdr.tcp.res);
        checksum_10.subtract(hdr.tcp.flags);
        checksum_10.subtract(hdr.tcp.window);
        checksum_11.subtract(hdr.tcp.srcPort);
        checksum_11.subtract(hdr.tcp.dstPort);
        checksum_11.subtract(hdr.tcp.seqNo);
        checksum_11.subtract(hdr.tcp.ackNo);
        checksum_11.subtract(hdr.tcp.dataOffset);
        checksum_11.subtract(hdr.tcp.res);
        checksum_11.subtract(hdr.tcp.flags);
        checksum_11.subtract(hdr.tcp.window);
        checksum_11.subtract(hdr.tcp_checksum_v6.urgentPtr);
        checksum_11.subtract(hdr.tcp_checksum_v6.checksum);
        checksum_11.subtract_all_and_deposit(meta.bridged_header.residual_checksum_1);
        transition parse_first_fragment;
    }
    @name(".parse_udp_v4") state parse_udp_v4 {
        pkt.extract(hdr.udp);
        pkt.extract(hdr.udp_checksum_v4);
        checksum_12.subtract(hdr.udp.srcPort);
        checksum_12.subtract(hdr.udp.dstPort);
        checksum_13.subtract(hdr.udp.srcPort);
        checksum_13.subtract(hdr.udp.dstPort);
        checksum_12.subtract(hdr.udp_checksum_v4.checksum);
        checksum_12.subtract_all_and_deposit(meta.bridged_header.residual_checksum_2);
        transition parse_first_fragment;
    }
    @name(".parse_udp_v6") state parse_udp_v6 {
        pkt.extract(hdr.udp);
        pkt.extract(hdr.udp_checksum_v6);
        checksum_12.subtract(hdr.udp.srcPort);
        checksum_12.subtract(hdr.udp.dstPort);
        checksum_13.subtract(hdr.udp.srcPort);
        checksum_13.subtract(hdr.udp.dstPort);
        checksum_13.subtract(hdr.udp_checksum_v6.checksum);
        checksum_13.subtract_all_and_deposit(meta.bridged_header.residual_checksum_3);
        transition parse_first_fragment;
    }
    @name(".parse_vlan_tag") state parse_vlan_tag {
        pkt.extract(hdr.vlan_tag.next);
        transition select(hdr.vlan_tag.last.etherType) {
            16w0x8100: parse_vlan_tag;
            16w0x800: parse_ipv4;
            16w0x86dd: parse_ipv6;
            default: accept;
        }
    }
    @name(".start") state __ingress_p4_entry_point {
        pkt.extract(hdr.ethernet);
        transition select(hdr.ethernet.etherType) {
            16w0x8100: parse_vlan_tag;
            16w0x800: parse_ipv4;
            16w0x86dd: parse_ipv6;
            default: accept;
        }
    }
    @name("$skip_to_packet") state __skip_to_packet {
        pkt.advance(32w0);
        transition __ingress_p4_entry_point;
    }
    @name("$phase0") state __phase0 {
        pkt.advance(32w64);
        transition __skip_to_packet;
    }
    @name("$resubmit") state __resubmit {
        transition __ingress_p4_entry_point;
    }
    @name("$check_resubmit") state __check_resubmit {
        transition select(ig_intr_md.resubmit_flag) {
            1w0 &&& 1w1: __phase0;
            1w1 &&& 1w1: __resubmit;
        }
    }
    @name("$ingress_metadata") state __ingress_metadata {
        pkt.extract(ig_intr_md);
        meta.bridged_header.bridged_metadata_indicator = 8w0;
        meta.bridged_header.setValid();
        transition __check_resubmit;
    }
    @name("$ingress_tna_entry_point") state start {
        transition __ingress_metadata;
    }
}

parser EgressParserImpl(packet_in pkt, out headers hdr, out metadata meta, out egress_intrinsic_metadata_t eg_intr_md) {
    @name(".parse_first_fragment") state parse_first_fragment {
        meta.l4_lookup.first_frag = 1w1;
        transition accept;
    }
    @name(".parse_icmp") state parse_icmp {
        pkt.extract(hdr.icmp);
        transition parse_first_fragment;
    }
    @name(".parse_igmp") state parse_igmp {
        pkt.extract(hdr.igmp);
        transition parse_first_fragment;
    }
    @name(".parse_ipv4") state parse_ipv4 {
        pkt.extract(hdr.ipv4);
        transition select(hdr.ipv4.ihl) {
            4w0x5: parse_ipv4_no_options;
            4w0x6: parse_ipv4_options_1;
            4w0x7: parse_ipv4_options_2;
            4w0x8: parse_ipv4_options_3;
            4w0x9: parse_ipv4_options_4;
            4w0xa: parse_ipv4_options_5;
            4w0xb: parse_ipv4_options_6;
            4w0xc: parse_ipv4_options_7;
            4w0xd: parse_ipv4_options_8;
            4w0xe: parse_ipv4_options_9;
            4w0xf: parse_ipv4_options_10;
            4w0x0 &&& 4w0x0: parse_first_fragment;
            default: accept;
        }
    }
    @name(".parse_ipv4_no_options") state parse_ipv4_no_options {
        meta.l4_lookup.word_1 = (pkt.lookahead<bit<16>>())[15:0];
        meta.l4_lookup.word_2 = (pkt.lookahead<bit<32>>())[15:0];
        transition select(hdr.ipv4.fragOffset, hdr.ipv4.protocol) {
            (13w0x0, 8w0x1): parse_icmp;
            (13w0x0, 8w0x2): parse_igmp;
            (13w0x0, 8w0x6): parse_tcp_v4;
            (13w0x0, 8w0x11): parse_udp_v4;
            (13w0x0 &&& 13w0x1fff, 8w0x0 &&& 8w0x0): parse_first_fragment;
            default: accept;
        }
    }
    @name(".parse_ipv4_options_1") state parse_ipv4_options_1 {
        pkt.extract(hdr.ipv4_option_word_1);
        meta.l4_lookup.word_1 = (pkt.lookahead<bit<16>>())[15:0];
        meta.l4_lookup.word_2 = (pkt.lookahead<bit<32>>())[15:0];
        transition select(hdr.ipv4.fragOffset, hdr.ipv4.protocol) {
            (13w0x0, 8w0x1): parse_icmp;
            (13w0x0, 8w0x2): parse_igmp;
            (13w0x0, 8w0x6): parse_tcp_v4;
            (13w0x0, 8w0x11): parse_udp_v4;
            (13w0x0 &&& 13w0x1fff, 8w0x0 &&& 8w0x0): parse_first_fragment;
            default: accept;
        }
    }
    @name(".parse_ipv4_options_10") state parse_ipv4_options_10 {
        pkt.extract(hdr.ipv4_option_word_1);
        pkt.extract(hdr.ipv4_option_word_2);
        pkt.extract(hdr.ipv4_option_word_3);
        pkt.extract(hdr.ipv4_option_word_4);
        pkt.extract(hdr.ipv4_option_word_5);
        pkt.extract(hdr.ipv4_option_word_6);
        pkt.extract(hdr.ipv4_option_word_7);
        pkt.extract(hdr.ipv4_option_word_8);
        pkt.extract(hdr.ipv4_option_word_9);
        pkt.extract(hdr.ipv4_option_word_10);
        meta.l4_lookup.word_1 = (pkt.lookahead<bit<16>>())[15:0];
        meta.l4_lookup.word_2 = (pkt.lookahead<bit<32>>())[15:0];
        transition select(hdr.ipv4.fragOffset, hdr.ipv4.protocol) {
            (13w0x0, 8w0x1): parse_icmp;
            (13w0x0, 8w0x2): parse_igmp;
            (13w0x0, 8w0x6): parse_tcp_v4;
            (13w0x0, 8w0x11): parse_udp_v4;
            (13w0x0 &&& 13w0x1fff, 8w0x0 &&& 8w0x0): parse_first_fragment;
            default: accept;
        }
    }
    @name(".parse_ipv4_options_2") state parse_ipv4_options_2 {
        pkt.extract(hdr.ipv4_option_word_1);
        pkt.extract(hdr.ipv4_option_word_2);
        meta.l4_lookup.word_1 = (pkt.lookahead<bit<16>>())[15:0];
        meta.l4_lookup.word_2 = (pkt.lookahead<bit<32>>())[15:0];
        transition select(hdr.ipv4.fragOffset, hdr.ipv4.protocol) {
            (13w0x0, 8w0x1): parse_icmp;
            (13w0x0, 8w0x2): parse_igmp;
            (13w0x0, 8w0x6): parse_tcp_v4;
            (13w0x0, 8w0x11): parse_udp_v4;
            (13w0x0 &&& 13w0x1fff, 8w0x0 &&& 8w0x0): parse_first_fragment;
            default: accept;
        }
    }
    @name(".parse_ipv4_options_3") state parse_ipv4_options_3 {
        pkt.extract(hdr.ipv4_option_word_1);
        pkt.extract(hdr.ipv4_option_word_2);
        pkt.extract(hdr.ipv4_option_word_3);
        meta.l4_lookup.word_1 = (pkt.lookahead<bit<16>>())[15:0];
        meta.l4_lookup.word_2 = (pkt.lookahead<bit<32>>())[15:0];
        transition select(hdr.ipv4.fragOffset, hdr.ipv4.protocol) {
            (13w0x0, 8w0x1): parse_icmp;
            (13w0x0, 8w0x2): parse_igmp;
            (13w0x0, 8w0x6): parse_tcp_v4;
            (13w0x0, 8w0x11): parse_udp_v4;
            (13w0x0 &&& 13w0x1fff, 8w0x0 &&& 8w0x0): parse_first_fragment;
            default: accept;
        }
    }
    @name(".parse_ipv4_options_4") state parse_ipv4_options_4 {
        pkt.extract(hdr.ipv4_option_word_1);
        pkt.extract(hdr.ipv4_option_word_2);
        pkt.extract(hdr.ipv4_option_word_3);
        pkt.extract(hdr.ipv4_option_word_4);
        meta.l4_lookup.word_1 = (pkt.lookahead<bit<16>>())[15:0];
        meta.l4_lookup.word_2 = (pkt.lookahead<bit<32>>())[15:0];
        transition select(hdr.ipv4.fragOffset, hdr.ipv4.protocol) {
            (13w0x0, 8w0x1): parse_icmp;
            (13w0x0, 8w0x2): parse_igmp;
            (13w0x0, 8w0x6): parse_tcp_v4;
            (13w0x0, 8w0x11): parse_udp_v4;
            (13w0x0 &&& 13w0x1fff, 8w0x0 &&& 8w0x0): parse_first_fragment;
            default: accept;
        }
    }
    @name(".parse_ipv4_options_5") state parse_ipv4_options_5 {
        pkt.extract(hdr.ipv4_option_word_1);
        pkt.extract(hdr.ipv4_option_word_2);
        pkt.extract(hdr.ipv4_option_word_3);
        pkt.extract(hdr.ipv4_option_word_4);
        pkt.extract(hdr.ipv4_option_word_5);
        meta.l4_lookup.word_1 = (pkt.lookahead<bit<16>>())[15:0];
        meta.l4_lookup.word_2 = (pkt.lookahead<bit<32>>())[15:0];
        transition select(hdr.ipv4.fragOffset, hdr.ipv4.protocol) {
            (13w0x0, 8w0x1): parse_icmp;
            (13w0x0, 8w0x2): parse_igmp;
            (13w0x0, 8w0x6): parse_tcp_v4;
            (13w0x0, 8w0x11): parse_udp_v4;
            (13w0x0 &&& 13w0x1fff, 8w0x0 &&& 8w0x0): parse_first_fragment;
            default: accept;
        }
    }
    @name(".parse_ipv4_options_6") state parse_ipv4_options_6 {
        pkt.extract(hdr.ipv4_option_word_1);
        pkt.extract(hdr.ipv4_option_word_2);
        pkt.extract(hdr.ipv4_option_word_3);
        pkt.extract(hdr.ipv4_option_word_4);
        pkt.extract(hdr.ipv4_option_word_5);
        pkt.extract(hdr.ipv4_option_word_6);
        meta.l4_lookup.word_1 = (pkt.lookahead<bit<16>>())[15:0];
        meta.l4_lookup.word_2 = (pkt.lookahead<bit<32>>())[15:0];
        transition select(hdr.ipv4.fragOffset, hdr.ipv4.protocol) {
            (13w0x0, 8w0x1): parse_icmp;
            (13w0x0, 8w0x2): parse_igmp;
            (13w0x0, 8w0x6): parse_tcp_v4;
            (13w0x0, 8w0x11): parse_udp_v4;
            (13w0x0 &&& 13w0x1fff, 8w0x0 &&& 8w0x0): parse_first_fragment;
            default: accept;
        }
    }
    @name(".parse_ipv4_options_7") state parse_ipv4_options_7 {
        pkt.extract(hdr.ipv4_option_word_1);
        pkt.extract(hdr.ipv4_option_word_2);
        pkt.extract(hdr.ipv4_option_word_3);
        pkt.extract(hdr.ipv4_option_word_4);
        pkt.extract(hdr.ipv4_option_word_5);
        pkt.extract(hdr.ipv4_option_word_6);
        pkt.extract(hdr.ipv4_option_word_7);
        meta.l4_lookup.word_1 = (pkt.lookahead<bit<16>>())[15:0];
        meta.l4_lookup.word_2 = (pkt.lookahead<bit<32>>())[15:0];
        transition select(hdr.ipv4.fragOffset, hdr.ipv4.protocol) {
            (13w0x0, 8w0x1): parse_icmp;
            (13w0x0, 8w0x2): parse_igmp;
            (13w0x0, 8w0x6): parse_tcp_v4;
            (13w0x0, 8w0x11): parse_udp_v4;
            (13w0x0 &&& 13w0x1fff, 8w0x0 &&& 8w0x0): parse_first_fragment;
            default: accept;
        }
    }
    @name(".parse_ipv4_options_8") state parse_ipv4_options_8 {
        pkt.extract(hdr.ipv4_option_word_1);
        pkt.extract(hdr.ipv4_option_word_2);
        pkt.extract(hdr.ipv4_option_word_3);
        pkt.extract(hdr.ipv4_option_word_4);
        pkt.extract(hdr.ipv4_option_word_5);
        pkt.extract(hdr.ipv4_option_word_6);
        pkt.extract(hdr.ipv4_option_word_7);
        pkt.extract(hdr.ipv4_option_word_8);
        meta.l4_lookup.word_1 = (pkt.lookahead<bit<16>>())[15:0];
        meta.l4_lookup.word_2 = (pkt.lookahead<bit<32>>())[15:0];
        transition select(hdr.ipv4.fragOffset, hdr.ipv4.protocol) {
            (13w0x0, 8w0x1): parse_icmp;
            (13w0x0, 8w0x2): parse_igmp;
            (13w0x0, 8w0x6): parse_tcp_v4;
            (13w0x0, 8w0x11): parse_udp_v4;
            (13w0x0 &&& 13w0x1fff, 8w0x0 &&& 8w0x0): parse_first_fragment;
            default: accept;
        }
    }
    @name(".parse_ipv4_options_9") state parse_ipv4_options_9 {
        pkt.extract(hdr.ipv4_option_word_1);
        pkt.extract(hdr.ipv4_option_word_2);
        pkt.extract(hdr.ipv4_option_word_3);
        pkt.extract(hdr.ipv4_option_word_4);
        pkt.extract(hdr.ipv4_option_word_5);
        pkt.extract(hdr.ipv4_option_word_6);
        pkt.extract(hdr.ipv4_option_word_7);
        pkt.extract(hdr.ipv4_option_word_8);
        pkt.extract(hdr.ipv4_option_word_9);
        meta.l4_lookup.word_1 = (pkt.lookahead<bit<16>>())[15:0];
        meta.l4_lookup.word_2 = (pkt.lookahead<bit<32>>())[15:0];
        transition select(hdr.ipv4.fragOffset, hdr.ipv4.protocol) {
            (13w0x0, 8w0x1): parse_icmp;
            (13w0x0, 8w0x2): parse_igmp;
            (13w0x0, 8w0x6): parse_tcp_v4;
            (13w0x0, 8w0x11): parse_udp_v4;
            (13w0x0 &&& 13w0x1fff, 8w0x0 &&& 8w0x0): parse_first_fragment;
            default: accept;
        }
    }
    @name(".parse_ipv6") state parse_ipv6 {
        pkt.extract(hdr.ipv6);
        meta.l4_lookup.word_1 = (pkt.lookahead<bit<16>>())[15:0];
        meta.l4_lookup.word_2 = (pkt.lookahead<bit<32>>())[15:0];
        transition select(hdr.ipv6.nextHdr) {
            8w0x1: parse_icmp;
            8w0x2: parse_igmp;
            8w0x6: parse_tcp_v6;
            8w0x11: parse_udp_v6;
            8w0x0 &&& 8w0x0: parse_first_fragment;
            default: accept;
        }
    }
    @name(".parse_tcp_v4") state parse_tcp_v4 {
        pkt.extract(hdr.tcp);
        pkt.extract(hdr.tcp_checksum_v4);
        transition parse_first_fragment;
    }
    @name(".parse_tcp_v6") state parse_tcp_v6 {
        pkt.extract(hdr.tcp);
        pkt.extract(hdr.tcp_checksum_v6);
        transition parse_first_fragment;
    }
    @name(".parse_udp_v4") state parse_udp_v4 {
        pkt.extract(hdr.udp);
        pkt.extract(hdr.udp_checksum_v4);
        transition parse_first_fragment;
    }
    @name(".parse_udp_v6") state parse_udp_v6 {
        pkt.extract(hdr.udp);
        pkt.extract(hdr.udp_checksum_v6);
        transition parse_first_fragment;
    }
    @name(".parse_vlan_tag") state parse_vlan_tag {
        pkt.extract(hdr.vlan_tag.next);
        transition select(hdr.vlan_tag.last.etherType) {
            16w0x8100: parse_vlan_tag;
            16w0x800: parse_ipv4;
            16w0x86dd: parse_ipv6;
            default: accept;
        }
    }
    @name(".start") state __egress_p4_entry_point {
        pkt.extract(hdr.ethernet);
        transition select(hdr.ethernet.etherType) {
            16w0x8100: parse_vlan_tag;
            16w0x800: parse_ipv4;
            16w0x86dd: parse_ipv6;
            default: accept;
        }
    }
    @name("$bridged_metadata") state __bridged_metadata {
        pkt.extract(meta.bridged_header);
        transition __egress_p4_entry_point;
    }
    @name("$mirrored") state __mirrored {
        transition __egress_p4_entry_point;
    }
    @name("$check_mirrored") state __check_mirrored {
        transition select(pkt.lookahead<bit<8>>()) {
            8w0 &&& 8w8: __bridged_metadata;
            8w8 &&& 8w8: __mirrored;
        }
    }
    @name("$egress_metadata") state __egress_metadata {
        pkt.extract(eg_intr_md);
        transition __check_mirrored;
    }
    @name("$egress_tna_entry_point") state start {
        transition __egress_metadata;
    }
}

control egress(inout headers hdr, inout metadata meta, in egress_intrinsic_metadata_t eg_intr_md, in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_parser_aux, inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr, inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport) {
    apply {
    }
}

control ingress(inout headers hdr, inout metadata meta, in ingress_intrinsic_metadata_t ig_intr_md, in ingress_intrinsic_metadata_from_parser_t ig_intr_md_from_parser_aux, inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr, inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm) {
    @name(".send") action send(bit<9> port) {
        ig_intr_md_for_tm.ucast_egress_port = port;
    }
    @name(".discard") action discard() {
        ig_intr_md_for_dprsr.drop_ctl = 3w1;
    }
    @name(".l3_forward") action l3_forward(bit<48> dmac, bit<48> smac, bit<9> port) {
        hdr.ethernet.dstAddr = dmac;
        hdr.ethernet.srcAddr = smac;
        send(port);
    }
    @name(".l3_forward_v4") action l3_forward_v4(bit<48> dmac, bit<48> smac, bit<9> port) {
        meta.meta.ipv4_checksum_update = 1w1;
        hdr.ipv4.ttl = hdr.ipv4.ttl - 8w1;
        l3_forward(dmac, smac, port);
    }
    @name(".nat_v4") action nat_v4(bit<32> sip, bit<32> dip, bit<8> ttl, bit<9> port) {
        hdr.ipv4.srcAddr = sip;
        hdr.ipv4.dstAddr = dip;
        hdr.ipv4.ttl = ttl;
        send(port);
    }
    @name(".tcp_nat_v4") action tcp_nat_v4(bit<32> sip, bit<32> dip, bit<8> ttl, bit<9> port, bit<16> sport, bit<16> dport) {
        meta.meta.ipv4_checksum_update = 1w1;
        meta.meta.ipv4_tcp_checksum_update = 1w1;
        meta.meta.ipv4_udp_checksum_update = 1w0;
        hdr.tcp.srcPort = sport;
        hdr.tcp.dstPort = dport;
        nat_v4(sip, dip, ttl, port);
    }
    @name(".udp_nat_v4") action udp_nat_v4(bit<32> sip, bit<32> dip, bit<8> ttl, bit<9> port, bit<16> sport, bit<16> dport) {
        meta.meta.ipv4_checksum_update = 1w1;
        meta.meta.ipv4_tcp_checksum_update = 1w0;
        meta.meta.ipv4_udp_checksum_update = 1w1;
        hdr.udp.srcPort = sport;
        hdr.udp.dstPort = dport;
        nat_v4(sip, dip, ttl, port);
    }
    @name(".l3_forward_v6") action l3_forward_v6(bit<48> dmac, bit<48> smac, bit<9> port) {
        l3_forward(dmac, smac, port);
        hdr.ipv6.hopLimit = hdr.ipv6.hopLimit - 8w1;
    }
    @name(".nat_v6") action nat_v6(bit<128> sip, bit<128> dip, bit<8> ttl, bit<9> port) {
        hdr.ipv6.srcAddr = sip;
        hdr.ipv6.dstAddr = dip;
        hdr.ipv6.hopLimit = ttl;
        send(port);
    }
    @name(".tcp_nat_v6") action tcp_nat_v6(bit<128> sip, bit<128> dip, bit<8> ttl, bit<9> port, bit<16> sport, bit<16> dport) {
        meta.meta.ipv6_tcp_checksum_update = 1w1;
        meta.meta.ipv6_udp_checksum_update = 1w0;
        hdr.tcp.srcPort = sport;
        hdr.tcp.dstPort = dport;
        nat_v6(sip, dip, ttl, port);
    }
    @name(".udp_nat_v6") action udp_nat_v6(bit<128> sip, bit<128> dip, bit<8> ttl, bit<9> port, bit<16> sport, bit<16> dport) {
        meta.meta.ipv6_tcp_checksum_update = 1w0;
        meta.meta.ipv6_udp_checksum_update = 1w1;
        hdr.udp.srcPort = sport;
        hdr.udp.dstPort = dport;
        nat_v6(sip, dip, ttl, port);
    }
    @name(".ipv4_acl") table ipv4_acl {
        actions = {
            send();
            discard();
            l3_forward();
            l3_forward_v4();
            nat_v4();
            tcp_nat_v4();
            udp_nat_v4();
            @defaultonly NoAction();
        }
        key = {
            hdr.ipv4.srcAddr                     : ternary;
            hdr.ipv4.dstAddr                     : ternary;
            hdr.ipv4.protocol                    : ternary;
            meta.l4_lookup.word_1                : ternary;
            meta.l4_lookup.word_2                : ternary;
            meta.l4_lookup.first_frag            : ternary;
            ig_intr_md_from_parser_aux.parser_err: ternary;
        }
        size = 1024;
        default_action = NoAction();
    }
    @name(".ipv6_acl") table ipv6_acl {
        actions = {
            send();
            discard();
            l3_forward();
            l3_forward_v6();
            nat_v6();
            tcp_nat_v6();
            udp_nat_v6();
            @defaultonly NoAction();
        }
        key = {
            hdr.ipv6.srcAddr                     : exact;
            hdr.ipv6.dstAddr                     : exact;
            hdr.ipv6.nextHdr                     : exact;
            meta.l4_lookup.word_1                : ternary;
            meta.l4_lookup.word_2                : ternary;
            meta.l4_lookup.first_frag            : ternary;
            ig_intr_md_from_parser_aux.parser_err: ternary;
        }
        size = 1024;
        default_action = NoAction();
    }
    apply {
        if (hdr.ipv4.isValid()) {
            ipv4_acl.apply();
        } else {
            if (hdr.ipv6.isValid()) {
                ipv6_acl.apply();
            }
        }
    }
}

control IngressDeparserImpl(packet_out pkt, inout headers hdr, in metadata meta, in ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr) {
    apply {
        pkt.emit(meta.bridged_header);
        pkt.emit(hdr.ethernet);
        pkt.emit(hdr.vlan_tag);
        pkt.emit(hdr.ipv6);
        pkt.emit(hdr.ipv4);
        pkt.emit(hdr.ipv4_option_word_1);
        pkt.emit(hdr.ipv4_option_word_2);
        pkt.emit(hdr.ipv4_option_word_3);
        pkt.emit(hdr.ipv4_option_word_4);
        pkt.emit(hdr.ipv4_option_word_5);
        pkt.emit(hdr.ipv4_option_word_6);
        pkt.emit(hdr.ipv4_option_word_7);
        pkt.emit(hdr.ipv4_option_word_8);
        pkt.emit(hdr.ipv4_option_word_9);
        pkt.emit(hdr.ipv4_option_word_10);
        pkt.emit(hdr.udp);
        pkt.emit(hdr.udp_checksum_v6);
        pkt.emit(hdr.udp_checksum_v4);
        pkt.emit(hdr.tcp);
        pkt.emit(hdr.tcp_checksum_v6);
        pkt.emit(hdr.tcp_checksum_v4);
        pkt.emit(hdr.igmp);
        pkt.emit(hdr.icmp);
    }
}

control EgressDeparserImpl(packet_out pkt, inout headers hdr, in metadata meta, in egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr) {
    Checksum() checksum_4;
    Checksum() checksum_5;
    Checksum() checksum_6;
    Checksum() checksum_7;
    Checksum() checksum_8;
    apply {
        if (meta.meta.ipv4_checksum_update == 1w1) {
            hdr.ipv4.hdrChecksum = checksum_4.update({ hdr.ipv4.version, hdr.ipv4.ihl, hdr.ipv4.diffserv, hdr.ipv4.totalLen, hdr.ipv4.identification, hdr.ipv4.flags, hdr.ipv4.fragOffset, hdr.ipv4.ttl, hdr.ipv4.protocol, hdr.ipv4.srcAddr, hdr.ipv4.dstAddr, hdr.ipv4_option_word_1.data, hdr.ipv4_option_word_2.data, hdr.ipv4_option_word_3.data, hdr.ipv4_option_word_4.data, hdr.ipv4_option_word_5.data, hdr.ipv4_option_word_6.data, hdr.ipv4_option_word_7.data, hdr.ipv4_option_word_8.data, hdr.ipv4_option_word_9.data, hdr.ipv4_option_word_10.data });
        }
        hdr.tcp_checksum_v4.checksum = checksum_5.update({ hdr.ipv4.srcAddr, hdr.ipv4.dstAddr, 8w0, hdr.ipv4.protocol, hdr.ipv4.totalLen, hdr.tcp.srcPort, hdr.tcp.dstPort, hdr.tcp.seqNo, hdr.tcp.ackNo, hdr.tcp.dataOffset, hdr.tcp.res, hdr.tcp.flags, hdr.tcp.window, hdr.tcp_checksum_v4.urgentPtr, meta.bridged_header.residual_checksum_0 });
        hdr.tcp_checksum_v6.checksum = checksum_6.update({ hdr.ipv6.srcAddr, hdr.ipv6.dstAddr, hdr.ipv6.payloadLen, 8w0, hdr.ipv6.nextHdr, hdr.tcp.srcPort, hdr.tcp.dstPort, hdr.tcp.seqNo, hdr.tcp.ackNo, hdr.tcp.dataOffset, hdr.tcp.res, hdr.tcp.flags, hdr.tcp.window, hdr.tcp_checksum_v6.urgentPtr, meta.bridged_header.residual_checksum_1 });
        hdr.udp_checksum_v4.checksum = checksum_7.update({ hdr.ipv4.srcAddr, hdr.ipv4.dstAddr, 8w0, hdr.ipv4.protocol, hdr.ipv4.totalLen, hdr.udp.srcPort, hdr.udp.dstPort, meta.bridged_header.residual_checksum_2 });
        hdr.udp_checksum_v6.checksum = checksum_8.update({ hdr.ipv6.srcAddr, hdr.ipv6.dstAddr, hdr.ipv6.payloadLen, 8w0, hdr.ipv6.nextHdr, hdr.udp.srcPort, hdr.udp.dstPort, meta.bridged_header.residual_checksum_3 });
        pkt.emit(hdr.ethernet);
        pkt.emit(hdr.vlan_tag);
        pkt.emit(hdr.ipv6);
        pkt.emit(hdr.ipv4);
        pkt.emit(hdr.ipv4_option_word_1);
        pkt.emit(hdr.ipv4_option_word_2);
        pkt.emit(hdr.ipv4_option_word_3);
        pkt.emit(hdr.ipv4_option_word_4);
        pkt.emit(hdr.ipv4_option_word_5);
        pkt.emit(hdr.ipv4_option_word_6);
        pkt.emit(hdr.ipv4_option_word_7);
        pkt.emit(hdr.ipv4_option_word_8);
        pkt.emit(hdr.ipv4_option_word_9);
        pkt.emit(hdr.ipv4_option_word_10);
        pkt.emit(hdr.udp);
        pkt.emit(hdr.udp_checksum_v6);
        pkt.emit(hdr.udp_checksum_v4);
        pkt.emit(hdr.tcp);
        pkt.emit(hdr.tcp_checksum_v6);
        pkt.emit(hdr.tcp_checksum_v4);
        pkt.emit(hdr.igmp);
        pkt.emit(hdr.icmp);
    }
}

Pipeline(IngressParserImpl(), ingress(), IngressDeparserImpl(), EgressParserImpl(), egress(), EgressDeparserImpl()) pipe;

Switch(pipe) main;

