/*******************************************************************************
 * BAREFOOT NETWORKS CONFIDENTIAL & PROPRIETARY
 *
 * Copyright (c) 2019-present Barefoot Networks, Inc.
 *
 * All Rights Reserved.
 *
 * NOTICE: All information contained herein is, and remains the property of
 * Barefoot Networks, Inc. and its suppliers, if any. The intellectual and
 * technical concepts contained herein are proprietary to Barefoot Networks, Inc.
 * and its suppliers and may be covered by U.S. and Foreign Patents, patents in
 * process, and are protected by trade secret or copyright law.  Dissemination of
 * this information or reproduction of this material is strictly forbidden unless
 * prior written permission is obtained from Barefoot Networks, Inc.
 *
 * No warranty, explicit or implicit is provided, unless granted under a written
 * agreement with Barefoot Networks, Inc.
 *
 ******************************************************************************/

#include <tna.p4> /* TOFINO1_ONLY */


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
    // ...
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

struct header_t {
    ethernet_h ethernet;
    vlan_tag_h vlan_tag;
    ipv4_h ipv4;
    ipv6_h ipv6;
    tcp_h tcp;
    udp_h udp;

    // Add more headers here.
}

struct empty_header_t {}

struct empty_metadata_t {}
# 22 "/mnt/metersv2.p4" 2
# 1 "/mnt/p4-tests/p4-programs/internal_p4_16/common/util.p4" 1
/*******************************************************************************
 * BAREFOOT NETWORKS CONFIDENTIAL & PROPRIETARY
 *
 * Copyright (c) 2019-present Barefoot Networks, Inc.
 *
 * All Rights Reserved.
 *
 * NOTICE: All information contained herein is, and remains the property of
 * Barefoot Networks, Inc. and its suppliers, if any. The intellectual and
 * technical concepts contained herein are proprietary to Barefoot Networks, Inc.
 * and its suppliers and may be covered by U.S. and Foreign Patents, patents in
 * process, and are protected by trade secret or copyright law.  Dissemination of
 * this information or reproduction of this material is strictly forbidden unless
 * prior written permission is obtained from Barefoot Networks, Inc.
 *
 * No warranty, explicit or implicit is provided, unless granted under a written
 * agreement with Barefoot Networks, Inc.
 *
 ******************************************************************************/




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
        pkt.advance(PORT_METADATA_SIZE);
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

// Skip egress
control BypassEgress(inout ingress_intrinsic_metadata_for_tm_t ig_tm_md) {

    action set_bypass_egress() {
        ig_tm_md.bypass_egress = 1w1;
    }

    table bypass_egress {
        actions = {
            set_bypass_egress();
        }
        const default_action = set_bypass_egress;
    }

    apply {
        bypass_egress.apply();
    }
}

// Empty egress parser/control blocks
parser EmptyEgressParser(
        packet_in pkt,
        out empty_header_t hdr,
        out empty_metadata_t eg_md,
        out egress_intrinsic_metadata_t eg_intr_md) {
    state start {
        transition accept;
    }
}

control EmptyEgressDeparser(
        packet_out pkt,
        inout empty_header_t hdr,
        in empty_metadata_t eg_md,
        in egress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md) {
    apply {}
}

control EmptyEgress(
        inout empty_header_t hdr,
        inout empty_metadata_t eg_md,
        in egress_intrinsic_metadata_t eg_intr_md,
        in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr,
        inout egress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md,
        inout egress_intrinsic_metadata_for_output_port_t eg_intr_oport_md) {
    apply {}
}
# 23 "/mnt/metersv2.p4" 2

typedef bit<16> meter_id_t;
//metedata 
struct metadata_t {
    bit<8> mtr_color;
    bit<9> port;
    bit<1> dir_byt_mtr;
    bit<1> indir_byt_mtr;
    bit<1> dir_pac_mtr;
    bit<1> indir_pac_mtr;
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
        transition parse_ipv4;
    }
    state parse_ipv4{
        pkt.extract(hdr.ipv4);
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
        in ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md) {
    apply {
        pkt.emit(hdr);
    }
}
// ---------------------------------------------------------------------------
// Switch Ingress
// ---------------------------------------------------------------------------
control SwitchIngress(
        inout header_t hdr,
        inout metadata_t ig_md,
        in ingress_intrinsic_metadata_t ig_intr_md,
        in ingress_intrinsic_metadata_from_parser_t ig_prsr_md,
        inout ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_tm_md) {
    //forward table actions
    action hit(PortId_t port) {
        ig_tm_md.ucast_egress_port = port;
        ig_md.port=port;
    }
    action miss(bit<3> drop) {
        ig_dprsr_md.drop_ctl = drop; // Drop packet.
    }
    table forward {
        key = {
            hdr.ethernet.dst_addr : exact;
        }
        actions = {
            hit;
            @defaultonly miss;
        }
        const default_action = miss(0x1);
        size = 1024;
    }
    //Direct byte Meter
    DirectMeter(MeterType_t.BYTES) direct_byt_meter;
    //Direct Packet Meter
    DirectMeter(MeterType_t.PACKETS) direct_pac_meter;
    //Counter for Direct Meter 
    Counter<bit<32>,bit<2>>(5,CounterType_t.PACKETS) dir_mtr_ctr;
    //Actions for direct meters
    action set_direct_byt_mtr() {
        // Execute the Direct byte meter and write the color to ig_md  
        ig_md.mtr_color = direct_byt_meter.execute();
    }
    action set_direct_pac_mtr() {
        // Execute the Direct packet meter and write the color to ig_md  
        ig_md.mtr_color = direct_pac_meter.execute();
    }
    //Direct Byte Meter table with max entries possible
    table direct_byt_meter_tab {
        key = {
            hdr.ethernet.src_addr : exact;
        }

        actions = {
            set_direct_byt_mtr;

        }
        meters = direct_byt_meter;
        size = 33793;
    }
    //Direct packet meter table with max entries possible
    table direct_pac_meter_tab {
        key = {
            hdr.ethernet.src_addr : exact;
        }

        actions = {
            set_direct_pac_mtr;

        }
        meters = direct_pac_meter;
        size = 33793;
    }
    //Indirect byte and packet Meters with max posssible entries 
    Meter<meter_id_t>(35840,MeterType_t.BYTES) indirect_byt_meter;
    Meter<meter_id_t>(35840,MeterType_t.PACKETS) indirect_pac_meter;
    //Counter for Indirect Meters
    Counter<bit<32>,bit<2>>(5,CounterType_t.PACKETS) indir_mtr_ctr;
    //Actions for Indirect Meters
    action set_indir_byt_mtr_idx(meter_id_t meter_idx){
        // Execute the InDirect byte meter and write the color to ig_md  
        ig_md.mtr_color = indirect_byt_meter.execute(meter_idx);
    }
    action set_indir_pac_mtr_idx(meter_id_t meter_idx){
        // Execute the InDirect Packet meter and write the color to ig_md  
        ig_md.mtr_color = indirect_pac_meter.execute(meter_idx);
    }
    //Tables for Indirect Byte and Packet Meters
    table indirect_byt_meter_tab {
        key={
            hdr.ethernet.src_addr : exact;
        }
        actions={
            set_indir_byt_mtr_idx;
        }
        size=35840;
    }
    table indirect_pac_meter_tab {
        key={
            hdr.ethernet.src_addr : exact;
        }
        actions={
            set_indir_pac_mtr_idx;
        }
        size=35840;
    }
    //Action for Test selection table
    action assign_test_select(bit<1> dir_by_mtr, bit<1> ind_by_mtr, bit<1> dir_pac_mtr, bit<1> indir_pac_mtr) {
        ig_md.dir_byt_mtr = dir_by_mtr;
        ig_md.indir_byt_mtr = ind_by_mtr;
        ig_md.dir_pac_mtr = dir_pac_mtr;
        ig_md.indir_pac_mtr = indir_pac_mtr;
    }
    // Test selection table
    table test_select {
        key = { ig_intr_md.ingress_port : exact; }
        actions = { assign_test_select; }
        default_action = assign_test_select(0, 0, 0, 0);
        size = 512;
    }
    apply {
        //Select Test
        test_select.apply();
        // Apply meter counters by test_select table
        if(ig_md.dir_byt_mtr==1){
            direct_byt_meter_tab.apply();
            dir_mtr_ctr.count(ig_md.mtr_color[1:0]);
        }
        else if(ig_md.dir_pac_mtr==1){
            direct_pac_meter_tab.apply();
            dir_mtr_ctr.count(ig_md.mtr_color[1:0]);
        }
         else if(ig_md.indir_byt_mtr==1){
            indirect_byt_meter_tab.apply();
            indir_mtr_ctr.count(ig_md.mtr_color[1:0]);
        }
        else{
            indirect_pac_meter_tab.apply();
            indir_mtr_ctr.count(ig_md.mtr_color[1:0]);
        }
        //Forward the packet to dest port
        forward.apply();
        // Skip egress
        ig_tm_md.bypass_egress = 1w1;
    }
}
////Egress 
Pipeline(SwitchIngressParser(),
         SwitchIngress(),
         SwitchIngressDeparser(),
         EmptyEgressParser(),
         EmptyEgress(),
         EmptyEgressDeparser()) pipe;

Switch(pipe) main;
