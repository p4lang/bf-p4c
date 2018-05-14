error {
    NoError,
    PacketTooShort,
    NoMatch,
    StackOutOfBounds,
    HeaderTooShort,
    ParserTimeout
}

extern packet_in {
    void extract<T>(out T hdr);
    void extract<T>(out T variableSizeHeader, in bit<32> variableFieldSizeInBits);
    T lookahead<T>();
    void advance(in bit<32> sizeInBits);
    bit<32> length();
}

extern packet_out {
    void emit<T>(in T hdr);
}

extern void verify(in bool check, in error toSignal);
match_kind {
    exact,
    ternary,
    lpm
}
#include <tofino.p4>
#include <tna.p4>

typedef bit<48> mac_addr_t;
typedef bit<32> ipv4_addr_t;
typedef bit<128> ipv6_addr_t;
header ethernet_h {
    mac_addr_t dst_addr;
    mac_addr_t src_addr;
    bit<16>    ether_type;
}

header ipv4_h {
    bit<4>      version;
    bit<4>      ihl;
    bit<8>      diffserv;
    bit<16>     total_len;
    bit<16>     identification;
    bit<3>      flags;
    bit<13>     frag_offset;
    bit<8>      ttl;
    bit<8>      protocol;
    bit<16>     hdr_checksum;
    ipv4_addr_t src_addr;
    ipv4_addr_t dst_addr;
}

header ipv6_h {
    bit<4>      version;
    bit<8>      traffic_class;
    bit<20>     flow_label;
    bit<16>     payload_len;
    bit<8>      next_hdr;
    bit<8>      hop_limit;
    ipv6_addr_t src_addr;
    ipv6_addr_t dst_addr;
}

header tcp_h {
    bit<16> src_port;
    bit<16> dst_port;
    bit<32> seq_no;
    bit<32> ack_no;
    bit<4>  data_offset;
    bit<4>  res;
    bit<8>  flags;
    bit<16> window;
    bit<16> checksum;
    bit<16> urgent_ptr;
}

header udp_h {
    bit<16> src_port;
    bit<16> dst_port;
    bit<16> hdr_lenght;
    bit<16> checksum;
}

typedef bit<16> switch_nexthop_t;
struct switch_header_t {
    ethernet_h ethernet;
    ipv4_h     ipv4;
    tcp_h      tcp;
    udp_h      udp;
}

struct switch_metadata_t {
    bool checksum_err;
}

parser SwitchIngressParser(packet_in pkt, out switch_header_t hdr, out switch_metadata_t ig_md, out ingress_intrinsic_metadata_t ig_intr_md) {
    bool tmp_1;
    @name("SwitchIngressParser.ipv4_checksum") Checksum<bit<16>>(HashAlgorithm_t.CSUM16) ipv4_checksum;
    state start {
        pkt.extract<ingress_intrinsic_metadata_t>(ig_intr_md);
        transition select(ig_intr_md.resubmit_flag) {
            1w0: parse_port_metadata;
            1w1: reject;
        }
    }
    state parse_port_metadata {
        pkt.advance(32w64);
        pkt.extract<ethernet_h>(hdr.ethernet);
        transition select(hdr.ethernet.ether_type) {
            16w0x800: parse_ipv4;
            default: reject;
        }
    }
    state parse_ipv4 {
        pkt.extract<ipv4_h>(hdr.ipv4);
        ipv4_checksum.add<ipv4_h>(hdr.ipv4);
        tmp_1 = ipv4_checksum.verify();
        ig_md.checksum_err = tmp_1;
        transition select(hdr.ipv4.protocol) {
            8w6: parse_tcp;
            8w17: parse_udp;
            default: accept;
        }
    }
    state parse_udp {
        pkt.extract<udp_h>(hdr.udp);
        transition accept;
    }
    state parse_tcp {
        pkt.extract<tcp_h>(hdr.tcp);
        transition accept;
    }
}

control SwitchIngressDeparser(packet_out pkt, inout switch_header_t hdr, in switch_metadata_t ig_md, in ingress_intrinsic_metadata_for_deparser_t ig_intr_dprsr_md) {
    bit<16> tmp_2;
    @name("SwitchIngressDeparser.ipv4_checksum") Checksum<bit<16>>(HashAlgorithm_t.CSUM16) ipv4_checksum_2;
    apply {
        tmp_2 = ipv4_checksum_2.update<tuple<bit<4>, bit<4>, bit<8>, bit<16>, bit<16>, bit<3>, bit<13>, bit<8>, bit<8>, bit<32>, bit<32>>>({ hdr.ipv4.version, hdr.ipv4.ihl, hdr.ipv4.diffserv, hdr.ipv4.total_len, hdr.ipv4.identification, hdr.ipv4.flags, hdr.ipv4.frag_offset, hdr.ipv4.ttl, hdr.ipv4.protocol, hdr.ipv4.src_addr, hdr.ipv4.dst_addr });
        hdr.ipv4.hdr_checksum = tmp_2;
        pkt.emit<ethernet_h>(hdr.ethernet);
        pkt.emit<ipv4_h>(hdr.ipv4);
        pkt.emit<udp_h>(hdr.udp);
        pkt.emit<tcp_h>(hdr.tcp);
    }
}

control SwitchIngress(inout switch_header_t hdr, inout switch_metadata_t ig_md, in ingress_intrinsic_metadata_t ig_intr_md, in ingress_intrinsic_metadata_from_parser_t ig_intr_prsr_md, inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprsr_md, inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {
    @name(".NoAction") action NoAction_0() {
    }
    @name(".NoAction") action NoAction_4() {
    }
    @name(".NoAction") action NoAction_5() {
    }
    switch_nexthop_t nexthop_index;
    @name("SwitchIngress.miss_") action miss() {
    }
    @name("SwitchIngress.miss_") action miss_2() {
    }
    @name("SwitchIngress.set_nexthop") action set_nexthop_0(switch_nexthop_t index) {
        nexthop_index = index;
    }
    @name("SwitchIngress.set_nexthop_info") action set_nexthop_info_0(mac_addr_t dmac) {
        hdr.ethernet.dst_addr = dmac;
    }
    @name("SwitchIngress.set_port") action set_port_0(PortId_t port) {
        ig_intr_tm_md.ucast_egress_port = port;
        ig_intr_tm_md.bypass_egress = true;
    }
    @name("SwitchIngress.set_port") action set_port_2(PortId_t port) {
        ig_intr_tm_md.ucast_egress_port = port;
        ig_intr_tm_md.bypass_egress = true;
    }
    @name("SwitchIngress.rewrite_") action rewrite_0(mac_addr_t smac) {
        hdr.ipv4.ttl = hdr.ipv4.ttl + 8w255;
        hdr.ethernet.src_addr = smac;
    }
    @name("SwitchIngress.fib") table fib {
        key = {
            hdr.ipv4.dst_addr: exact @name("hdr.ipv4.dst_addr") ;
        }
        actions = {
            miss();
            set_nexthop_0();
        }
        const default_action = miss();
    }
    @name("SwitchIngress.nexthop") table nexthop {
        key = {
            nexthop_index: exact @name("nexthop_index") ;
        }
        actions = {
            set_nexthop_info_0();
            @defaultonly NoAction_0();
        }
        default_action = NoAction_0();
    }
    @name("SwitchIngress.dmac") table dmac_1 {
        key = {
            hdr.ethernet.dst_addr: exact @name("hdr.ethernet.dst_addr") ;
        }
        actions = {
            set_port_0();
            miss_2();
        }
        const default_action = miss_2();
    }
    @name("SwitchIngress.rewrite") table rewrite_2 {
        key = {
            ig_intr_tm_md.ucast_egress_port: exact @name("ig_intr_tm_md.ucast_egress_port") ;
        }
        actions = {
            rewrite_0();
            @defaultonly NoAction_4();
        }
        default_action = NoAction_4();
    }
    @name("SwitchIngress.acl") table acl {
        key = {
            ig_intr_prsr_md.parser_err: exact @name("ig_intr_prsr_md.parser_err") ;
            ig_md.checksum_err        : exact @name("ig_md.checksum_err") ;
        }
        actions = {
            set_port_2();
            @defaultonly NoAction_5();
        }
        default_action = NoAction_5();
    }
    apply {
        nexthop_index = 16w0;
        fib.apply();
        nexthop.apply();
        dmac_1.apply();
        rewrite_2.apply();
        acl.apply();
    }
}

parser EmptyEgressParser_0(packet_in pkt, out switch_header_t hdr, out switch_metadata_t eg_md, out egress_intrinsic_metadata_t eg_intr_md) {
    state start {
        transition accept;
    }
}

control EmptyEgress_0(inout switch_header_t hdr, inout switch_metadata_t eg_md, in egress_intrinsic_metadata_t eg_intr_md, in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr, inout egress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md, inout egress_intrinsic_metadata_for_output_port_t eg_intr_oport_md) {
    apply {
    }
}

control EmptyEgressDeparser_0(packet_out pkt, inout switch_header_t hdr, in switch_metadata_t eg_md, in egress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md) {
    apply {
    }
}

Switch<switch_header_t, switch_metadata_t, switch_header_t, switch_metadata_t>(SwitchIngressParser(), SwitchIngress(), SwitchIngressDeparser(), EmptyEgressParser_0(), EmptyEgress_0(), EmptyEgressDeparser_0()) main;

