/*******************************************************************************
 * BAREFOOT NETWORKS CONFIDENTIAL & PROPRIETARY
 *
 * Copyright (c) 2018-2019 Barefoot Networks, Inc.
 * All Rights Reserved.
 *
 * NOTICE: All information contained herein is, and remains the property of
 * Barefoot Networks, Inc. and its suppliers, if any. The intellectual and
 * technical concepts contained herein are proprietary to Barefoot Networks,
 * Inc.
 * and its suppliers and may be covered by U.S. and Foreign Patents, patents in
 * process, and are protected by trade secret or copyright law.
 * Dissemination of this information or reproduction of this material is
 * strictly forbidden unless prior written permission is obtained from
 * Barefoot Networks, Inc.
 *
 * No warranty, explicit or implicit is provided, unless granted under a
 * written agreement with Barefoot Networks, Inc.
 *
 *
 ******************************************************************************/

#include <tna.p4>
#ifndef _UTIL_
#define _UTIL_

parser TofinoIngressParser(
        packet_in pkt,
        out ingress_intrinsic_metadata_t ig_intr_md) {
    state start {
        pkt.extract(ig_intr_md);
        transition select(ig_intr_md.resubmit_flag) {
            1 : parse_resubmit;
            0 : parse_port_metadata;
        }
    }

    state parse_resubmit {
        // Parse resubmitted packet here.
        transition reject;
    }

    state parse_port_metadata {
#if __TARGET_TOFINO__ == 2
        pkt.advance(192);
#else
        pkt.advance(64);
#endif
        transition accept;
    }
}

parser TofinoEgressParser(
        packet_in pkt,
        out egress_intrinsic_metadata_t eg_intr_md) {
    state start {
        pkt.extract(eg_intr_md);
        transition accept;
    }
}

// Empty egress parser/control blocks
parser EmptyEgressParser<H, M>(
        packet_in pkt,
        out H hdr,
        out M eg_md,
        out egress_intrinsic_metadata_t eg_intr_md) {
    state start {
        transition accept;
    }
}

control EmptyEgressDeparser<H, M>(
        packet_out pkt,
        inout H hdr,
        in M eg_md,
        in egress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md) {
    apply {}
}

control EmptyEgress<H, M>(
        inout H hdr,
        inout M eg_md,
        in egress_intrinsic_metadata_t eg_intr_md,
        in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr,
        inout egress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md,
        inout egress_intrinsic_metadata_for_output_port_t eg_intr_oport_md) {
    apply {}
}

#endif /* _UTIL */

#ifndef _HEADERS_
#define _HEADERS_

typedef bit<48> mac_addr_t;
typedef bit<32> ipv4_addr_t;
typedef bit<128> ipv6_addr_t;
typedef bit<12> vlan_id_t;

typedef bit<16> ether_type_t;
const ether_type_t ETHERTYPE_IPV4 = 16w0x0800;
const ether_type_t ETHERTYPE_ARP = 16w0x0806;
const ether_type_t ETHERTYPE_IPV6 = 16w0x86dd;
const ether_type_t ETHERTYPE_VLAN = 16w0x8100;

typedef bit<8> ip_protocol_t;
const ip_protocol_t IP_PROTOCOLS_ICMP = 1;
const ip_protocol_t IP_PROTOCOLS_TCP = 6;
const ip_protocol_t IP_PROTOCOLS_UDP = 17;

header ethernet_h {
    mac_addr_t dst_addr;
    mac_addr_t src_addr;
    bit<16> ether_type;
}

header vlan_tag_h {
    bit<3> pcp;
    bit<1> cfi;
    vlan_id_t vid;
    bit<16> ether_type;
}

header mpls_h {
    bit<20> label;
    bit<3> exp;
    bit<1> bos;
    bit<8> ttl;
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
    bit<16> hdr_length;
    bit<16> checksum;
}

header icmp_h {
    bit<8> type_;
    bit<8> code;
    bit<16> hdr_checksum;
}

// Address Resolution Protocol -- RFC 6747
header arp_h {
    bit<16> hw_type;
    bit<16> proto_type;
    bit<8> hw_addr_len;
    bit<8> proto_addr_len;
    bit<16> opcode;
    mac_addr_t src_mac_addr;
    ipv4_addr_t src_ip_addr;
    mac_addr_t dst_mac_addr;
    ipv4_addr_t dst_ip_addr;
}

// Segment Routing Extension (SRH) -- IETFv7
header ipv6_srh_h {
    bit<8> next_hdr;
    bit<8> hdr_ext_len;
    bit<8> routing_type;
    bit<8> seg_left;
    bit<8> last_entry;
    bit<8> flags;
    bit<16> tag;
}

// VXLAN -- RFC 7348
header vxlan_h {
    bit<8> flags;
    bit<24> reserved;
    bit<24> vni;
    bit<8> reserved2;
}

// Generic Routing Encapsulation (GRE) -- RFC 1701
header gre_h {
    bit<1> C;
    bit<1> R;
    bit<1> K;
    bit<1> S;
    bit<1> s;
    bit<3> recurse;
    bit<5> flags;
    bit<3> version;
    bit<16> proto;
}

header msg_t {
    bit<32> sw_ip;
    bit<32> sw_port;
    bit<48> timestamp;
    bit<32> number;
    bit<16> sw_dir;
}
header data_t {
    bit<224> user_data;
}

struct header_t {
    ethernet_h ethernet;
    vlan_tag_h vlan_tag;
    arp_h arp;
    ipv4_h ipv4;
    ipv6_h ipv6;
    tcp_h tcp;
    udp_h udp;
    //icmp_h icmp;
    data_t data;
    msg_t msg;

    // Add more headers here.
}


parser SimplePacketParser(packet_in pkt, inout header_t hdr) {
    state start { // parse Ethernet
        pkt.extract(hdr.ethernet);
        transition select(hdr.ethernet.ether_type) {
            ETHERTYPE_IPV4 : parse_ipv4;
            ETHERTYPE_IPV6 : parse_ipv6;
            default : reject;
        }
    }

    state parse_ipv4 {
        pkt.extract(hdr.ipv4);
        transition select(hdr.ipv4.protocol) {
            IP_PROTOCOLS_TCP : parse_tcp;
            IP_PROTOCOLS_UDP : parse_udp;
            default : accept;
        }
    }

    state parse_ipv6 {
        pkt.extract(hdr.ipv6);
        transition select(hdr.ipv6.next_hdr) {
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
}

#endif /* _HEADERS_ */

struct metadata_t {
    bit<32> timestamp;
    mac_addr_t src_mac;
    mac_addr_t dst_mac;
    ipv4_addr_t p4_ip;
    ipv4_addr_t sw_ip;
    ipv4_addr_t report_ip;
    bit<32> rate;
    bit<32> sw_port;
    PortId_t report_port;
    bit<16> sw_dir;
    bit<32> res;
}

// ---------------------------------------------------------------------------
// Ingress parser
// ---------------------------------------------------------------------------
parser SwitchIngressParser(
        packet_in pkt,
        out header_t hdr,
        out metadata_t ig_md,
        out ingress_intrinsic_metadata_t ig_intr_md) {

    TofinoIngressParser() tofino_parser;

    state start {
        tofino_parser.apply(pkt, ig_intr_md);
        transition parse_ethernet;
    }

    state parse_ethernet {
        pkt.extract(hdr.ethernet);
        transition select (hdr.ethernet.ether_type) {
            ETHERTYPE_IPV4 : parse_ipv4;
            //ETHERTYPE_ARP: parse_arp;
            default : reject;
        }
    }

     state parse_arp {
	    pkt.extract(hdr.arp);
	    transition accept;
    }

    state parse_ipv4 {
        pkt.extract(hdr.ipv4);
        transition select(hdr.ipv4.total_len) {
            0x0 &&& 0xffc0 : accept;
            default : parse_data;
        }
    //    transition accept;
    }

    state parse_data {
	pkt.extract(hdr.data);
        transition accept;
    }
}

// ---------------------------------------------------------------------------
// Egress parser
// ---------------------------------------------------------------------------
parser SwitchEgressParser(
        packet_in pkt,
        out header_t hdr,
        out metadata_t eg_md,
        out egress_intrinsic_metadata_t eg_intr_md) {

    TofinoEgressParser() tofino_parser;

    state start {
        tofino_parser.apply(pkt, eg_intr_md);
        transition accept;
    }
}

// ---------------------------------------------------------------------------
// Ingress Deparser
// ---------------------------------------------------------------------------
control SwitchIngressDeparser(
        packet_out pkt,
        inout header_t hdr,
        in metadata_t ig_md,
        in ingress_intrinsic_metadata_for_deparser_t ig_intr_dprsr_md) {

    Checksum() ipv4_checksum;
    apply {
        hdr.ipv4.hdr_checksum = ipv4_checksum.update({
            hdr.ipv4.version,
            hdr.ipv4.ihl,
            hdr.ipv4.diffserv,
            hdr.ipv4.total_len,
            hdr.ipv4.identification,
            hdr.ipv4.flags,
            hdr.ipv4.frag_offset,
            hdr.ipv4.ttl,
            hdr.ipv4.protocol,
            hdr.ipv4.src_addr,
            hdr.ipv4.dst_addr});
        pkt.emit(hdr);
    }
}

control SwitchIngress(
        inout header_t hdr,
        inout metadata_t ig_md,
        in ingress_intrinsic_metadata_t ig_intr_md,
        in ingress_intrinsic_metadata_from_parser_t ig_intr_prsr_md,
        inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprsr_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {

    bit<32> number;
    bit<32> res;

    Register<bit<32>,PortId_t>(256) counter;
    RegisterAction<bit<32>, PortId_t,bit<32>>(counter) counter_write = {
         void apply(inout bit<32> value,out bit<32> rv){
            value = value + (bit<32>)hdr.ipv4.total_len;
        }
    };
    RegisterAction<bit<32>, PortId_t,bit<32>>(counter) counter_read = {
         void apply(inout bit<32> value,out bit<32> rv){
            rv = value;
            value = 0;
        }
    };


    Register<bit<32>,PortId_t>(256) timestamp;
    RegisterAction<bit<32>, PortId_t,bit<32>>(timestamp) timestamp_up = {
	 void apply(inout bit<32> value,out bit<32> rv){
	    if(ig_md.timestamp - value > 32w15 || value - ig_md.timestamp > 32w15){
            value = ig_md.timestamp;
            rv = 1;
	    }
	    else {
            rv = 1;
	    }
	}
    };

    action nop() {
    }

    action proto_exec() {
        ig_intr_tm_md.ucast_egress_port = ig_md.report_port;

        hdr.ethernet.setInvalid();
        hdr.ipv4.setInvalid();
        hdr.udp.setInvalid();
        hdr.tcp.setInvalid();
        //hdr.icmp.setInvalid();
        hdr.data.setInvalid();

        hdr.ethernet.setValid();
        hdr.ethernet.src_addr=ig_md.src_mac;
        hdr.ethernet.dst_addr=ig_md.dst_mac;
        hdr.ethernet.ether_type=ETHERTYPE_IPV4;

        hdr.ipv4.setValid();
        hdr.ipv4.version = 4;
        hdr.ipv4.ihl = 5;
        hdr.ipv4.diffserv = 0;
        hdr.ipv4.total_len = 48;
        hdr.ipv4.identification = (bit<16>)ig_md.timestamp;
        hdr.ipv4.flags = 2;
        //hdr.ipv4.frag_offset = 0;
        hdr.ipv4.ttl = 64;
        hdr.ipv4.protocol=IP_PROTOCOLS_UDP;
        hdr.ipv4.src_addr = ig_md.p4_ip;
        hdr.ipv4.dst_addr = ig_md.report_ip;

        hdr.udp.setValid();
        hdr.udp.src_port=0x3000;
        hdr.udp.dst_port=10000;
        hdr.udp.hdr_length=28;

        hdr.msg.setValid();
        hdr.msg.number = number;
        hdr.msg.sw_ip = ig_md.sw_ip;
        hdr.msg.sw_port = ig_md.sw_port;
        hdr.msg.sw_dir = ig_md.sw_dir;
        hdr.msg.timestamp = ig_intr_md.ingress_mac_tstamp;
    }

    table proto_match {
        //key = {
         //   ig_intr_md.ingress_port : exact;
        //}
        actions = {
            proto_exec;
        }
        size = 1;
        const default_action = proto_exec;
    }

    action conf_action(mac_addr_t src_mac,mac_addr_t dst_mac,ipv4_addr_t p4_ip,ipv4_addr_t sw_ip,
			bit<32> sw_port,bit<16> sw_dir,ipv4_addr_t report_ip,PortId_t report_port,
			bit<32> rate){
        ig_md.src_mac = src_mac;
        ig_md.dst_mac = dst_mac;
        ig_md.p4_ip = p4_ip;
        ig_md.sw_ip = sw_ip;
        ig_md.report_ip = report_ip;
        ig_md.rate = rate;
        ig_md.sw_port = sw_port;
        ig_md.report_port = report_port;
        ig_md.sw_dir = sw_dir;
    }

    table conf_tbl {
        key = {
            ig_intr_md.ingress_port : exact;
        }
        actions = {
            conf_action;
            nop;
        }
        size = 256;
        const default_action = nop;
    }
    
    apply{
        ig_md.timestamp = ig_intr_md.ingress_mac_tstamp[47:16];
        conf_tbl.apply();
        res = 1;
        res = timestamp_up.execute(ig_intr_md.ingress_port);
        if(res == 0){
            number = counter_read.execute(ig_intr_md.ingress_port);
            proto_match.apply();
        }else{
            counter_write.execute(ig_intr_md.ingress_port);
            ig_intr_dprsr_md.drop_ctl = 0x1; // Drop packet.
        }

        //	ig_intr_tm_md.copy_to_cpu = true;
    }
}

Pipeline(SwitchIngressParser(),
         SwitchIngress(),
         SwitchIngressDeparser(),
         SwitchEgressParser(),
         EmptyEgress<header_t, metadata_t>(),
         EmptyEgressDeparser<header_t, metadata_t>()) pipe;

Switch(pipe) main;
