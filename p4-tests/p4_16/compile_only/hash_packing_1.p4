
#include <core.p4>
#include <tna.p4>

#define ETHERTYPE_IPV4 0x0800
#define ETHERTYPE_VLAN 0x8100
#define ETHERTYPE_IPV6 0x86dd

#define IP_PROTOCOLS_ICMP   1
#define IP_PROTOCOLS_IGMP   2
#define IP_PROTOCOLS_TCP    6
#define IP_PROTOCOLS_UDP    17
#define IP_PROTOCOLS_ICMPV6 58

#define MAX_GROUP_SIZE 6000

#if MAX_GROUP_SIZE <= 120
#define HASH_WIDTH 14
#elif MAX_GROUP_SIZE <= 3840
#define HASH_WIDTH 24
#elif MAX_GROUP_SIZE <= 119040
#define HASH_WIDTH 29
#else
#error "Maximum Group Size cannot exceed 119040 members on Tofino"
#endif

enum bit<16> ethertype_t {
    VLAN = 0x8100,
    IPV4 = 0x0800,
    IPV6 = 0x86dd
}

struct ingress_metadata_t {}
struct egress_metadata_t {}

typedef bit<HASH_WIDTH> hash_t;

/*************************************************************************
 ***********************  H E A D E R S  *********************************
 *************************************************************************/
typedef bit<32> ipv4_addr_t;
typedef bit<128> ipv6_addr_t;
typedef bit<48> mac_addr_t;

header ethernet_h {
    mac_addr_t dst_addr;
    mac_addr_t src_addr;
    bit<16> ether_type;
}

header vlan_tag_h {
    bit<3> pcp;
    bit<1> cfi;
    bit<12> vid;
    bit<16> ether_type;
}

header ipv4_h {
    bit<4> version;
    bit<4> ihl;
    bit<8> diffserv;
    bit<16> total_len;
    bit<16> identification;
    bit<3> flags;
    bit<13> frag_offset;
    bit<8> ttl;
    bit<8> protocol;
    bit<16> hdr_checksum;
    ipv4_addr_t src_addr;
    ipv4_addr_t dst_addr;
}

header option_h {
    bit<32> data;
}

header ipv6_h {
    bit<4> version;
    bit<8> traffic_class;
    bit<20> flow_label;
    bit<16> payload_len;
    bit<8> next_hdr;
    bit<8> hop_limit;
    ipv6_addr_t src_addr;
    ipv6_addr_t dst_addr;
}

header tcp_h {
    bit<16> src_port;
    bit<16> dst_port;
    bit<32> seq_no;
    bit<32> ack_no;
    bit<4> data_offset;
    bit<4> res;
    bit<8> flags;
    bit<16> window;
    bit<16> checksum;
    bit<16> urgent_ptr;
}

header udp_h {
    bit<16> src_port;
    bit<16> dst_port;
    bit<16> length;
    bit<16> checksum;
}

header icmp_h {
    bit<8> type;
    bit<8> code;
    bit<16> checksum;
    // ...
}

header igmp_h {
    bit<8> type;
    bit<8> code;
    bit<16> checksum;
    // ...
}

struct header_t {
    ethernet_h ethernet;
    vlan_tag_h[2] vlan_tag;
    ipv4_h ipv4;
    ipv6_h ipv6;
    udp_h udp;
    tcp_h tcp;
    icmp_h icmp;
    igmp_h igmp;
}

/*************************************************************************
 ***********************  P A R S E R  ***********************************
 *************************************************************************/
parser IngressParser(
        packet_in pkt,
        out header_t hdr,
        out ingress_metadata_t ig_md,
        out ingress_intrinsic_metadata_t ig_intr_md) {
    Checksum<bit<16>>(ChecksumAlgorithm_t.CSUM16) ipv4_checksum;

    state start {
        pkt.extract(ig_intr_md);
        pkt.advance(PORT_METADATA_SIZE);
        transition parse_ethernet;
    }

    state parse_ethernet {
        pkt.extract(hdr.ethernet);
        transition select(hdr.ethernet.ether_type) {
            ETHERTYPE_IPV4 : parse_ipv4;
            ETHERTYPE_IPV6 : parse_ipv6;
            ETHERTYPE_VLAN : parse_vlan;
            default : accept;
        }
    }

    state parse_ipv4 {
        pkt.extract(hdr.ipv4);
        ipv4_checksum.add(hdr.ipv4);
        transition select(hdr.ipv4.ihl) {
            5 : parse_ipv4_no_options;
            //TODO : IPv4 options
            default : accept;
        }
    }

    state parse_ipv4_no_options {
        // ipv4_checksum_err = ipv4_checksum.verify();
        transition select(hdr.ipv4.protocol, hdr.ipv4.flags, hdr.ipv4.frag_offset) {
            (IP_PROTOCOLS_ICMP, 0, 0) : parse_icmp;
            (IP_PROTOCOLS_IGMP, 0, 0) : parse_igmp;
            (IP_PROTOCOLS_TCP, 0, 0) : parse_tcp;
            (IP_PROTOCOLS_UDP, 0, 0) : parse_udp;
            //TODO : IPv4 fragmentation
            default : accept;
        }
    }

    state parse_vlan {
        pkt.extract(hdr.vlan_tag.next);
        transition select(hdr.vlan_tag.last.ether_type) {
            ETHERTYPE_IPV4 : parse_ipv4;
            ETHERTYPE_VLAN : parse_vlan;
            ETHERTYPE_IPV6 : parse_ipv6;
            default : accept;
        }
    }

    state parse_ipv6 {
        pkt.extract(hdr.ipv6);
        transition select(hdr.ipv6.next_hdr) {
            IP_PROTOCOLS_ICMPV6 : parse_icmp;
            IP_PROTOCOLS_TCP : parse_tcp;
            IP_PROTOCOLS_UDP : parse_udp;
            default : accept;
        }
    }

    state parse_udp {
        pkt.extract(hdr.udp);
        transition accept;
    }

    state parse_tcp {
        pkt.extract(hdr.tcp);
        transition accept;
    }

    state parse_icmp {
        pkt.extract(hdr.icmp);
        transition accept;
    }

    state parse_igmp {
        pkt.extract(hdr.igmp);
        transition accept;
    }
}

parser EgressParser(
        packet_in pkt,
        out header_t hdr,
        out egress_metadata_t eg_md,
        out egress_intrinsic_metadata_t eg_intr_md) {

    state start {
        pkt.extract(eg_intr_md);
        transition parse_ethernet;
    }

    state parse_ethernet {
        pkt.extract(hdr.ethernet);
        transition select(hdr.ethernet.ether_type) {
            ETHERTYPE_IPV4 : parse_ipv4;
            ETHERTYPE_IPV6 : parse_ipv6;
            ETHERTYPE_VLAN : parse_vlan;
            default : accept;
        }
    }

    state parse_ipv4 {
        pkt.extract(hdr.ipv4);
        transition select(hdr.ipv4.ihl) {
            5 : parse_ipv4_no_options;
            //TODO : IPv4 options
            default : accept;
        }
    }

    state parse_ipv4_no_options {
        transition select(hdr.ipv4.protocol, hdr.ipv4.flags, hdr.ipv4.frag_offset) {
            //TODO : IPv4 fragmentation
            default : accept;
        }
    }

    state parse_vlan {
        pkt.extract(hdr.vlan_tag.next);
        transition select(hdr.vlan_tag.last.ether_type) {
            ETHERTYPE_IPV4 : parse_ipv4;
            ETHERTYPE_VLAN : parse_vlan;
            ETHERTYPE_IPV6 : parse_ipv6;
            default : accept;
        }
    }

    state parse_ipv6 {
        pkt.extract(hdr.ipv6);
        transition accept;
    }
}

control IngressDeparser(
        packet_out pkt,
        inout header_t hdr,
        in ingress_metadata_t ig_md,
        in ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr) {

    apply {
        pkt.emit(hdr.ethernet);
        pkt.emit(hdr.vlan_tag);
        pkt.emit(hdr.ipv4);
        pkt.emit(hdr.ipv6);
        pkt.emit(hdr.udp); // Ingress only.
        pkt.emit(hdr.tcp); // Ingress only.
        pkt.emit(hdr.icmp); // Ingress only.
        pkt.emit(hdr.igmp); // Ingress only.
    }
}

control EgressDeparser(
        packet_out pkt,
        inout header_t hdr,
        in egress_metadata_t eg_md,
        in egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr) {
    apply {
        pkt.emit(hdr.ethernet);
        pkt.emit(hdr.vlan_tag);
        pkt.emit(hdr.ipv4);
        pkt.emit(hdr.ipv6);
    }
}
/*************************************************************************
 **************  I N G R E S S   P R O C E S S I N G   *******************
 *************************************************************************/
control FIB(in ipv4_addr_t dst_addr,
            out bit<16> nexthop)(
            bit<32> host_table_size,
            bit<32> lpm_table_size) {
    action fib_hit(bit<16> nexthop_index) {
        nexthop = nexthop_index;
    }

    action fib_miss() {}

    table fib {
        key = {
            dst_addr : exact;
        }

        actions = {
            fib_miss;
            fib_hit;
        }

        const default_action = fib_miss;
        size = host_table_size;
    }

    table fib_lpm {
        key = {
            dst_addr : lpm;
        }

        actions = {
            fib_miss;
            fib_hit;
        }

        const default_action = fib_miss;
        size = lpm_table_size;
    }

    apply {
        if (!fib.apply().hit) {
            fib_lpm.apply();
        }
    }
}

control FIBv6(in ipv6_addr_t dst_addr,
              out bit<16> nexthop)(
              bit<32> host_table_size,
              bit<32> lpm_table_size) {
    action fib_hit(bit<16> nexthop_index) {
        nexthop = nexthop_index;
    }

    action fib_miss() {}

    table fib {
        key = {
            dst_addr : exact;
        }

        actions = {
            fib_miss;
            fib_hit;
        }

        const default_action = fib_miss;
        size = host_table_size;
    }

    table fib_lpm {
        key = {
            dst_addr : lpm;
        }

        actions = {
            fib_miss;
            fib_hit;
        }

        const default_action = fib_miss;
        size = lpm_table_size;
    }

    apply {
        if (!fib.apply().hit) {
            fib_lpm.apply();
        }
    }
}


control RandomHash(inout hash_t hash) {
    Random<bit<32>>() rnd1;
    apply {
        hash = (hash_t) rnd1.get();
    }
}

control IpHash(inout hash_t hash, in header_t hdr) {
    Hash<bit<32>>(HashAlgorithm_t.CRC32) hash1;

    apply {
        if (hdr.ipv4.isValid()) {
            hash = (hash_t) hash1.get({hdr.ipv4.src_addr, hdr.ipv4.dst_addr, hdr.ipv4.protocol});
        } else if (hdr.ipv6.isValid()) {
            //TODO
        }
    }
}

control RoundRobinHash(inout hash_t hash) {
    apply{
        //TODO
    }
}

control Ingress(
        inout header_t hdr,
        inout ingress_metadata_t ig_md,
        in ingress_intrinsic_metadata_t ig_intr_md,
        in ingress_intrinsic_metadata_from_parser_t ig_intr_from_prsr,
        inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr,
        inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm) {

    FIB(host_table_size=131072, lpm_table_size=12288) ipv4;
    FIBv6(host_table_size=32768, lpm_table_size=4096) ipv6;
    RandomHash() hash_calc;

    bit<16> nexthop_id;
    hash_t hash;
    Hash<hash_t>(HashAlgorithm_t.IDENTITY) selector_hash;
    ActionSelector(1024, selector_hash, SelectorMode_t.FAIR) lag_ecmp_selector;

    action send(PortId_t port) {
        ig_intr_md_for_tm.ucast_egress_port = port;
        //TODO Bypass ttl/hop_limir rewrite.
    }

    action discard() { ig_intr_md_for_dprsr.drop_ctl = 0x1; }

    action switch_(mac_addr_t smac, mac_addr_t dmac, PortId_t port) {
        hdr.ethernet.src_addr = smac;
        hdr.ethernet.dst_addr = dmac;
        ig_intr_md_for_tm.ucast_egress_port = port;
    }

    table nexthop {
        key = {
            nexthop_id : exact;
            hash : selector;
        }

        actions = {
            send;
            discard;
            switch_;
        }

        size = 32768;
        implementation = lag_ecmp_selector;
    }

    apply {
        nexthop_id = 0;
        if (hdr.ipv4.isValid() && (hdr.ipv4.ttl & 0xFE != 0)) {
            ipv4.apply(hdr.ipv4.dst_addr, nexthop_id);
        } else if (hdr.ipv6.isValid() && (hdr.ipv6.hop_limit & 0xFE != 0)) {
            ipv6.apply(hdr.ipv6.dst_addr, nexthop_id);
        }

        hash_calc.apply(hash);
        nexthop.apply();
    }
}

control Egress(
        inout header_t hdr,
        inout egress_metadata_t eg_md,
        in egress_intrinsic_metadata_t eg_intr_md,
        in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr,
        inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
        inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport) {

    action decrement_ttl() {
        hdr.ipv4.ttl = hdr.ipv4.ttl - 1;
    }

    action decrement_hop_limit() {
        hdr.ipv4.ttl = hdr.ipv6.hop_limit - 1;
    }

    apply {
        if (hdr.ipv4.isValid()) {
            decrement_ttl();
        } else if (hdr.ipv6.isValid()) {
            decrement_hop_limit();
        }
    }
}

Pipeline(IngressParser(),
         Ingress(),
         IngressDeparser(),
         EgressParser(),
         Egress(),
         EgressDeparser()) pipe;

Switch(pipe) main;


