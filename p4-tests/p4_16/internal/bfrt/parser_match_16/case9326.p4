/*
 * Copyright 2019-present Ronald van der Pol <Ronald.vanderPol@rvdp.org>
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

typedef bit<9> port_t;

#include <core.p4>
#include <tna.p4>

typedef bit<48> ether_addr_t;
typedef bit<16> ethertype_t;

#define ETHERTYPE_IPV4                  0x0800
#define ETHERTYPE_ARP                   0x0806
#define ETHERTYPE_CTAG                  0x8100
#define ETHERTYPE_IPV6                  0x86DD
#define ETHERTYPE_MPLS                  0x8847
#define ETHERTYPE_MPLS_UPSTREAM         0x8848
#define ETHERTYPE_STAG                  0x88A8
#define ETHERTYPE_LLDP                  0x88CC
#define ETHERTYPE_LOCAL_EXPERIMENTAL_1  0x88B5
#define ETHERTYPE_LOCAL_EXPERIMENTAL_2  0x88B6

header ethernet_h {
    ether_addr_t daddr;
    ether_addr_t saddr;
    ethertype_t  type;
}

header vlan_h {
    bit<3>      pcp;    // Priority Code Point (section 6.9.3)
    bit<1>      dei;    // Drop Eligible Indicator (section 6.9.3)
    bit<12>     vid;
    ethertype_t type;
}


#define PROTO_IPV4              4       /* IPv4 encapsulation */
#define PROTO_TCP               6       /* Transmission Control */
#define PROTO_UDP               17      /* User Datagram */
#define PROTO_IPV6              41      /* IPv6 encapsulation */

typedef bit<32> ipv4_addr_t;

header ipv4_h {
    bit<4> version;
    bit<4> ihl;
    bit<8> ds;
    bit<16> tot_length;
    bit<16> id;
    bit<3> flags;
    bit<13> frag_offset;
    bit<8> ttl;
    bit<8> protocol;
    bit<16> cksum;
    ipv4_addr_t saddr;
    ipv4_addr_t daddr;
}

typedef bit<128> ipv6_addr_t;

header ipv6_h {
    bit<4> version;
    bit<6> dscp;
    bit<2> ecn;
    bit<20> flowlabel;
    bit<16> payload_len;
    bit<8> nexthdr;
    bit<8> hoplimit;
    ipv6_addr_t saddr;
    ipv6_addr_t daddr;
}

// RFC 8200, section 4, IPv6 Extension Headers
header ipv6_ext_hdr_h {
    bit<8> nexthdr;
    bit<8> length;
}

// RFC 8200, section 4.2, Options
header ipv6_options_h {
    bit<8> type;
    bit<8> length;
}

// RFC 8200, section 4.4, Routing Header
header ipv6_routing_hdr_h {
    bit<8> type;
    bit<8> segments_left;
}

// RFC 8200, section 4.5, Fragment Header
header ipv6_fragment_hdr_h {
    bit<13> fragment_offset;
    bit<2> reserved;
    bit<1> more_fragments;
    bit<32> id;
}

header udp_h {
    bit<16> src_port;
    bit<16> dst_port;
    bit<16> length;
    bit<16> cksum;
}

/* INT shim header for TCP/UDP */
header intl4_shim_h {
    bit<8>  int_type;       /* INT header type */
    bit<8>  rsvd1;          /* Reserved */
    bit<8>  len;            /* Total length of INT Metadata, INT Stack */
                            /* and Shim Header in 4-byte words */
    bit<6>  dscp;           /* Original IP DSCP value (optional) */
    bit<2>  rsvd2;          /* Reserved */
}

/* INT header */
/* 16 instruction bits are defined in four 4b fields to allow concurrent */
/* lookups of the bits without listing 2^16 combinations */
header int_header_h {
    bit<4>  ver;                        /* Version (1 for this version) */
    bit<2>  rep;                        /* Replication requested */
    bit<1>  c;                          /* Copy */
    bit<1>  e;                          /* Max Hop Count exceeded */
    bit<1>  m;                          /* MTU exceeded */
    bit<7>  rsvd1;                      /* Reserved */
    bit<3>  rsvd2;                      /* Reserved */
    bit<5>  hop_metadata_len;           /* Per-hop Metadata Length */
                                        /* in 4-byte words */
    bit<8>  remaining_hop_cnt;          /* Remaining Hop Count */
    bit<4>  instruction_mask_0003;      /* Instruction bitmap bits 0-3 */
    bit<4>  instruction_mask_0407;      /* Instruction bitmap bits 4-7 */
    bit<4>  instruction_mask_0811;      /* Instruction bitmap bits 8-11 */
    bit<4>  instruction_mask_1215;      /* Instruction bitmap bits 12-15 */
    bit<16> rsvd3;                      /* Reserved */
}

/* INT meta-value headers - different header for each value type */
header int_switch_id_h {
    bit<32> switch_id;
}

header int_level1_port_ids_h {
    bit<16> ingress_port_id;
    bit<16> egress_port_id;
}

header int_hop_latency_h {
    bit<32> hop_latency;
}

header int_q_occupancy_h {
    bit<8>  q_id;
    bit<24> q_occupancy;
}

header int_ingress_tstamp_h {
    bit<32> ingress_tstamp;
}

header int_egress_tstamp_h {
    bit<32> egress_tstamp;
}

header int_level2_port_ids_h {
    bit<32> ingress_port_id;
    bit<32> egress_port_id;
}

header int_egress_port_tx_util_h {
    bit<32> egress_port_tx_util;
}

header int_b_occupancy_h {
    bit<8>  b_id;
    bit<24> b_occupancy;
}

header bridged_metadata_h {
}

struct ingress_metadata_t {
    bit<6> dscp;
}

struct headers_t {
    bridged_metadata_h bridged_metadata;
    ethernet_h ethernet;
    ipv4_h ipv4;
    ipv6_h ipv6;
    udp_h udp;
    intl4_shim_h intl4_shim;
}

parser ingress_parser(
        packet_in pkt,
        out headers_t hdr,
        out ingress_metadata_t ingress_metadata,
        out ingress_intrinsic_metadata_t
            ingress_intrinsic_metadata)
{
    state start {
        pkt.extract(ingress_intrinsic_metadata);
        pkt.advance(PORT_METADATA_SIZE);
        transition parse_ethernet;
    }

    state parse_ethernet {
        pkt.extract(hdr.ethernet);
        transition select(hdr.ethernet.type) {
            ETHERTYPE_IPV4: parse_ipv4;
            ETHERTYPE_IPV6: parse_ipv6;
            default: reject;
        }
    }

    state parse_ipv4 {
        pkt.extract(hdr.ipv4);
        transition accept;
    }

    state parse_ipv6 {
        pkt.extract(hdr.ipv6);
        ingress_metadata.dscp = hdr.ipv6.dscp;
        transition select(hdr.ipv6.nexthdr) {
            PROTO_UDP: parse_ipv6_udp;
            default: accept;
        }
    }

    state parse_ipv6_udp {
        pkt.extract(hdr.udp);
        transition select(hdr.ipv6.dscp) {
            // IPv6_DSCP_INT: parse_intl4_shim;
            0x17: parse_intl4_shim;
            default: foobar;
        }
    }

    state parse_intl4_shim {
        pkt.extract(hdr.intl4_shim);
        transition accept;
    }

    state foobar {
        transition accept;
    }
}

control ingress_control(
        inout headers_t hdr,
        inout ingress_metadata_t ingress_metadata,
        in ingress_intrinsic_metadata_t ingress_intrinsic_metadata,
        in ingress_intrinsic_metadata_from_parser_t
            ingress_intrinsic_metadata_from_parser,
        inout ingress_intrinsic_metadata_for_deparser_t
            ingress_intrinsic_metadata_for_deparser,
        inout ingress_intrinsic_metadata_for_tm_t
            ingress_intrinsic_metadata_for_tm)
{
    action send_to(port_t port) {
        ingress_intrinsic_metadata_for_tm.ucast_egress_port = port;
    }

    table forward {
        key = {
            ingress_intrinsic_metadata.ingress_port: exact;
        }
        actions = {
            send_to;
        }
        size = 32;
    }

    apply {
        forward.apply();
    }
}

control ingress_deparser(
        packet_out pkt,
        inout headers_t hdr,
        in ingress_metadata_t ingress_metadata,
        in ingress_intrinsic_metadata_for_deparser_t
            ingress_intrinsic_metadata_for_deparser)
{
    apply {
        pkt.emit(hdr);
    }
}

struct egress_metadata_t {
}

parser egress_parser(
        packet_in pkt,
        out headers_t hdr,
        out egress_metadata_t egress_metadata,
        out egress_intrinsic_metadata_t egress_intrinsic_metadata)
{
    state start {
        pkt.extract(egress_intrinsic_metadata);
        transition accept;
    }
}

control egress_control(
        inout headers_t hdr,
        inout egress_metadata_t egress_metadata,
        in egress_intrinsic_metadata_t egress_intrinsic_metadata,
        in egress_intrinsic_metadata_from_parser_t
            egress_intrinsic_metadata_from_parser,
        inout egress_intrinsic_metadata_for_deparser_t
            egress_intrinsic_metadata_for_deparser,
        inout egress_intrinsic_metadata_for_output_port_t
            egress_intrinsic_metadata_for_output_port)
{
    apply {}
}

control egress_deparser(
        packet_out pkt,
        inout headers_t hdr,
        in egress_metadata_t egress_metadata,
        in egress_intrinsic_metadata_for_deparser_t
            egress_intrinsic_metadata_for_deparser)
{
    apply {}
}

Pipeline(
    ingress_parser(),
    ingress_control(),
    ingress_deparser(),
    egress_parser(),
    egress_control(),
    egress_deparser()
) pipe;

Switch(pipe) main;
