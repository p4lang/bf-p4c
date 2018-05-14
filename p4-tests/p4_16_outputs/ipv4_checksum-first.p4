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
action NoAction() {
}
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

parser TofinoIngressParser(packet_in pkt, out ingress_intrinsic_metadata_t ig_intr_md) {
    state start {
        pkt.extract<ingress_intrinsic_metadata_t>(ig_intr_md);
        transition select(ig_intr_md.resubmit_flag) {
            1w1: parse_resubmit;
            1w0: parse_port_metadata;
        }
    }
    state parse_resubmit {
        transition reject;
    }
    state parse_port_metadata {
        pkt.advance(32w64);
        transition accept;
    }
}

parser TofinoEgressParser(packet_in pkt, out egress_intrinsic_metadata_t eg_intr_md) {
    state start {
        pkt.extract<egress_intrinsic_metadata_t>(eg_intr_md);
        transition accept;
    }
}

parser EmptyEgressParser<H, M>(packet_in pkt, out H hdr, out M eg_md, out egress_intrinsic_metadata_t eg_intr_md) {
    state start {
        transition accept;
    }
}

control EmptyEgressDeparser<H, M>(packet_out pkt, inout H hdr, in M eg_md, in egress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md) {
    apply {
    }
}

control EmptyEgress<H, M>(inout H hdr, inout M eg_md, in egress_intrinsic_metadata_t eg_intr_md, in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr, inout egress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md, inout egress_intrinsic_metadata_for_output_port_t eg_intr_oport_md) {
    apply {
    }
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
    Checksum<bit<16>>(HashAlgorithm_t.CSUM16) ipv4_checksum;
    state start {
        pkt.extract<ingress_intrinsic_metadata_t>(ig_intr_md);
        transition select(ig_intr_md.resubmit_flag) {
            1w0: parse_port_metadata;
            1w1: reject;
        }
    }
    state parse_port_metadata {
        pkt.advance(32w64);
        transition parse_ethernet;
    }
    state parse_ethernet {
        pkt.extract<ethernet_h>(hdr.ethernet);
        transition select(hdr.ethernet.ether_type) {
            16w0x800: parse_ipv4;
            default: reject;
        }
    }
    state parse_ipv4 {
        pkt.extract<ipv4_h>(hdr.ipv4);
        ipv4_checksum.add<ipv4_h>(hdr.ipv4);
        ig_md.checksum_err = ipv4_checksum.verify();
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
    Checksum<bit<16>>(HashAlgorithm_t.CSUM16) ipv4_checksum;
    apply {
        hdr.ipv4.hdr_checksum = ipv4_checksum.update<tuple<bit<4>, bit<4>, bit<8>, bit<16>, bit<16>, bit<3>, bit<13>, bit<8>, bit<8>, bit<32>, bit<32>>>({ hdr.ipv4.version, hdr.ipv4.ihl, hdr.ipv4.diffserv, hdr.ipv4.total_len, hdr.ipv4.identification, hdr.ipv4.flags, hdr.ipv4.frag_offset, hdr.ipv4.ttl, hdr.ipv4.protocol, hdr.ipv4.src_addr, hdr.ipv4.dst_addr });
        pkt.emit<ethernet_h>(hdr.ethernet);
        pkt.emit<ipv4_h>(hdr.ipv4);
        pkt.emit<udp_h>(hdr.udp);
        pkt.emit<tcp_h>(hdr.tcp);
    }
}

control SwitchIngress(inout switch_header_t hdr, inout switch_metadata_t ig_md, in ingress_intrinsic_metadata_t ig_intr_md, in ingress_intrinsic_metadata_from_parser_t ig_intr_prsr_md, inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprsr_md, inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {
    switch_nexthop_t nexthop_index;
    action miss_() {
    }
    action drop() {
        ig_intr_dprsr_md.drop_ctl = 3w0x7;
    }
    action set_nexthop(switch_nexthop_t index) {
        nexthop_index = index;
    }
    action set_nexthop_info(mac_addr_t dmac) {
        hdr.ethernet.dst_addr = dmac;
    }
    action set_port(PortId_t port) {
        ig_intr_tm_md.ucast_egress_port = port;
        ig_intr_tm_md.bypass_egress = true;
    }
    action rewrite_(mac_addr_t smac) {
        hdr.ipv4.ttl = hdr.ipv4.ttl + 8w255;
        hdr.ethernet.src_addr = smac;
    }
    table fib {
        key = {
            hdr.ipv4.dst_addr: exact @name("hdr.ipv4.dst_addr") ;
        }
        actions = {
            miss_();
            set_nexthop();
        }
        const default_action = miss_();
    }
    table nexthop {
        key = {
            nexthop_index: exact @name("nexthop_index") ;
        }
        actions = {
            set_nexthop_info();
            @defaultonly NoAction();
        }
        default_action = NoAction();
    }
    table dmac {
        key = {
            hdr.ethernet.dst_addr: exact @name("hdr.ethernet.dst_addr") ;
        }
        actions = {
            set_port();
            miss_();
        }
        const default_action = miss_();
    }
    table rewrite {
        key = {
            ig_intr_tm_md.ucast_egress_port: exact @name("ig_intr_tm_md.ucast_egress_port") ;
        }
        actions = {
            rewrite_();
            @defaultonly NoAction();
        }
        default_action = NoAction();
    }
    table acl {
        key = {
            ig_intr_prsr_md.parser_err: exact @name("ig_intr_prsr_md.parser_err") ;
            ig_md.checksum_err        : exact @name("ig_md.checksum_err") ;
        }
        actions = {
            set_port();
            @defaultonly NoAction();
        }
        default_action = NoAction();
    }
    apply {
        nexthop_index = 16w0;
        fib.apply();
        nexthop.apply();
        dmac.apply();
        rewrite.apply();
        acl.apply();
    }
}

Switch<switch_header_t, switch_metadata_t, switch_header_t, switch_metadata_t>(SwitchIngressParser(), SwitchIngress(), SwitchIngressDeparser(), EmptyEgressParser<switch_header_t, switch_metadata_t>(), EmptyEgress<switch_header_t, switch_metadata_t>(), EmptyEgressDeparser<switch_header_t, switch_metadata_t>()) main;

