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

#include <tna.p4>

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

header ipv4_option_h {
    bit<8> type;
    bit<8> length;
    bit<16> value;
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

header hdr_h {
    bit<8> pos;
    bit<8> type;
}

header bridged_h {
    bit<16> f1;
    bit<16> f2;
    bit<16> f3;
    bit<32> f4;
    bit<8> f5;
    bit<8> f6;
    bit<16> f7;
}

header fabric_pad_h {
    bit<3> ext_type;
    bit<1> extend;
    @padding bit<28> pad;
}

header fake_tag_h {
    bit<16> f1;
    bit<16> f2;
}

header fabric_h {
    bit<8> f1;
    bit<8> f2;
    bit<32> f3;
    bit<16> f4;
    bit<16> f5;
    bit<16> f6;
    bit<16> f7;
}

struct header_t {
    bridged_h bridged_md;
    fabric_h fabric;
    fabric_pad_h fabric_pad;
    fake_tag_h fake_tag;
    ethernet_h ethernet;
    vlan_tag_h[2] vlan_tag;
    ipv4_h ipv4;
    ipv4_option_h[10] ipv4_option_list;
    ipv6_h ipv6;
    tcp_h tcp;
    udp_h udp;
    vxlan_h vxlan;
    ethernet_h inner_ethernet;
    ipv4_h inner_ipv4;
    udp_h inner_udp;
    hdr_h[31] myhdr;
    // Add more headers here.
}

struct empty_header_t {}

struct empty_metadata_t {}

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

@pa_auto_init_metadata
@pa_parser_group_monogress
struct metadata_t {
    bit<2> iseop;
    bit<2> test1;
    bit<1> test;
    bit<16> flowid;
    bit<5> test2;
    bit<8> dst_port;
    bit<8> drop_reason;
    bit<1> bypass_meter;
    bit<8> mc_ttl_thr;
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
        transition select(hdr.ethernet.ether_type) {
            (ETHERTYPE_IPV4) : parse_ipv4;
            (ETHERTYPE_IPV6) : parse_ipv6;
            (ETHERTYPE_VLAN) : parse_vlan;
            default : accept;
        }
    }

    state parse_vlan {
        pkt.extract(hdr.vlan_tag.next);
        transition select(hdr.vlan_tag.last.ether_type) {
            (ETHERTYPE_IPV4) : parse_ipv4;
            (ETHERTYPE_IPV6) : parse_ipv6;
            (ETHERTYPE_VLAN) : parse_vlan;
            default : accept;
        }
    }

    state parse_qinq {
        //pkt.extract(hdr.vlan_tag.next);
        pkt.extract(hdr.vlan_tag[0]);
        pkt.extract(hdr.vlan_tag[1]);
        transition select(hdr.vlan_tag[1].ether_type) {
            default : accept;
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

}

// ---------------------------------------------------------------------------
// Ingress Deparser
// ---------------------------------------------------------------------------
control SwitchIngressDeparser(
        packet_out pkt,
        inout header_t hdr,
        in metadata_t ig_md,
        in ingress_intrinsic_metadata_for_deparser_t ig_intr_dprsr_md) {
    apply {
        pkt.emit(hdr.ethernet);
        pkt.emit(hdr.vlan_tag);
        pkt.emit(hdr.ipv4);
        pkt.emit(hdr.ipv6);
    }
}

control SwitchIngress(
        inout header_t hdr,
        inout metadata_t ig_md,
        in ingress_intrinsic_metadata_t ig_intr_md,
        in ingress_intrinsic_metadata_from_parser_t ig_intr_prsr_md,
        inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprsr_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {

    Register<bit<16>, bit<16>>(65536, 0) port_reg;
    RegisterAction<bit<16>, bit<16>, bit<16>> (port_reg) port_reg_act = {
        void apply(inout bit<16> reg, out bit<16> port){
            if (reg == 0) {
                reg = (bit<16>)ig_intr_tm_md.ucast_egress_port;
            }
            port = reg;
        }
    };
    RegisterAction<bit<16>, bit<16>, bit<16>> (port_reg) port_reg_act2 = {
        void apply(inout bit<16> reg, out bit<16> port){
            bit<16> temp;
            if (reg == 0) {
                port = (bit<16>)ig_intr_tm_md.ucast_egress_port;
            } else {
                port = reg;
                reg = 0;
            }
            port = temp;
        }
    };

    action build_flow() {
        ig_intr_tm_md.ucast_egress_port=(bit<9>)port_reg_act.execute(ig_md.flowid);
    }
    action eop_flow() {
        ig_intr_tm_md.ucast_egress_port=(bit<9>)port_reg_act2.execute(ig_md.flowid);
    }

    table test {
        key = {
            ig_md.iseop : exact;
        }
        actions = {
            build_flow;
            eop_flow;
        }
    }
    Hash<bit<16>>(HashAlgorithm_t.IDENTITY) selector_hash;

    ActionProfile(16384) action_profile_lag;

    ActionSelector(action_profile_lag,
                   selector_hash,
                   SelectorMode_t.FAIR,
                   4096, // max_group_size
                   16) fabric_lag_selector; //num_groups

    action set_fabric_lag_port(PortId_t port) {
        ig_intr_tm_md.ucast_egress_port = port;
    }

    @pragma selector_enable_scramble 1
    table fabric_lag {
        key = {
            ig_md.iseop : exact;// dst_device can be bfn or fpga as long as they have unique ids.
            ig_md.flowid : selector;
        }

        actions = {
            NoAction;
            set_fabric_lag_port;
        }

        const default_action = NoAction;
        size = 128;
        implementation = fabric_lag_selector;
    }

    action set_icos(bit<3> icos) {
        ig_intr_tm_md.ingress_cos = icos;
    }
    action set_queue(QueueId_t qid) {
        ig_intr_tm_md.qid = qid;
    }
    action set_icos_and_queue(bit<3> icos, QueueId_t qid) {
        ig_intr_tm_md.ingress_cos = icos;
        ig_intr_tm_md.qid = qid;
    }
    @stage(6)
    table traffic_class_78 {
        key = {
            ig_md.flowid : exact;
        }
        actions = {
            NoAction;
            set_queue;
            set_icos_and_queue;
        }
        size = 32;
        default_action = NoAction;
    }
    @stage(6)
    table traffic_class_710 {
        key = {
            ig_md.flowid : exact;
        }
        actions = {
            NoAction;
            set_queue;
            set_icos_and_queue;
        }
        size = 32;
        default_action = NoAction;
    }
    table high_priority_queue {
        key = {
            ig_md.flowid : exact;
        }
        actions = {
            NoAction;
            set_queue;
            set_icos_and_queue;
        }
        size = 32;
        default_action = NoAction;
    }

    action set_port_t() {

    }

    action set_port(bit<9> port) {
        ig_intr_tm_md.ucast_egress_port = port;
    }

    table port {
        key = {
            ig_md.iseop : exact;
        }
        actions = {
            NoAction;
            set_port;
            set_port_t;
        }

        default_action = set_port(8);
    }

    @use_hash_action(1)
    table hash {
        key = {
            hdr.vlan_tag[1].pcp : exact;
            hdr.ethernet.dst_addr[4:0] : exact;
        }
        actions = {
            set_port;
        }

        default_action = set_port(8);
        size = 256;
    }

    table hash2 {
        key = {
            hdr.vlan_tag[0].pcp : exact;
            hdr.ethernet.dst_addr[8:4] : exact;
        }
        actions = {
            set_port;
        }

        default_action = set_port(8);
        size = 256;
    }



    action set_filter() {
        ig_md.drop_reason = 255;
        ig_md.bypass_meter = 1;
    }

    table mc_filter {
        key = {
            ig_md.dst_port : exact @name("dst_port");
            ig_intr_tm_md.ucast_egress_port : exact @name("dev_port");
        }

        actions = {
            set_filter;
            @defaultonly NoAction;
        }

        const default_action = NoAction();
        size = 1024;
    }

    Register<bit<8>, bit<8>>(256, 0) mc_ttl_reg;
    RegisterAction<bit<8>, bit<8>, bit<8>>(mc_ttl_reg) mc_ttl_reg_act = {
        void apply(inout bit<8> reg, out bit<8> rv) {
            if (ig_md.dst_port < reg) {
                rv = 255;
            }
            reg = 255;
        }
    };

    action ttl_drop() {
        ig_md.drop_reason = mc_ttl_reg_act.execute(ig_md.mc_ttl_thr);
    }
    @stage(4)
    table ttl_thr_check {
        /* keyless */
        actions = {
            ttl_drop;
        }

        const default_action = ttl_drop;
    }


    action bypass_meter() {
        ig_md.bypass_meter = 1;
    }

    table check_dst_port {
        // keyless
        actions = {
            bypass_meter;
        }
        default_action = bypass_meter();
    }


    apply {
        ig_md.iseop = hdr.ethernet.dst_addr[1:0];

        port.apply();

        if ((ig_md.test1 == 0) && (ig_md.test == 1)) {
            hash.apply();
        } else if ((ig_md.test1 == 0) && (ig_md.test == 1)) {
            hash2.apply();
        }

        fabric_lag.apply();

        switch(high_priority_queue.apply().action_run) {
            NoAction : {
                if (ig_intr_tm_md.ucast_egress_port[8:7] == 1) {
                    traffic_class_78.apply();
                } else if (ig_intr_tm_md.ucast_egress_port[8:7] == 0) {
                    traffic_class_710.apply();
                }
            }
        }


       if (ig_md.dst_port == 255) {
           check_dst_port.apply();
       } else {
           switch (mc_filter.apply().action_run) {
              NoAction : {
                  ttl_thr_check.apply();
              }
           }
       }

        if (ig_md.test == 1) {
            ig_md.iseop = hdr.ethernet.dst_addr[1:0];
        }
    }
}

// ---------------------------------------------------------------------------
// Egress parser
// ---------------------------------------------------------------------------
parser SwitchEgressParser(
        packet_in pkt,
        out header_t hdr,
        out empty_metadata_t eg_md,
        out egress_intrinsic_metadata_t eg_intr_md) {

    TofinoEgressParser() tofino_parser;

    state start {
        tofino_parser.apply(pkt, eg_intr_md);
        transition parse_ethernet;
    }

    state parse_ethernet {
        pkt.extract(hdr.inner_ethernet);
        transition select (hdr.inner_ethernet.ether_type) {
            ETHERTYPE_IPV4 : parse_ipv4;
            default : accept;
        }
    }

    state parse_ipv4 {
        pkt.extract(hdr.inner_ipv4);
        transition select(hdr.inner_ipv4.protocol, hdr.inner_ipv4.ihl, hdr.inner_ipv4.frag_offset) {
            (17, 5, 0) : parse_udp;
            default : accept;
        }
    }

    state parse_udp {
        pkt.extract(hdr.inner_udp);
        transition accept;
    }
}


// ---------------------------------------------------------------------------
// Egress Deparser
// ---------------------------------------------------------------------------
control SwitchEgressDeparser(
        packet_out pkt,
        inout header_t hdr,
        in empty_metadata_t eg_md,
        in egress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md) {
    apply {
        pkt.emit(hdr.ethernet);
        pkt.emit(hdr.ipv4);
        pkt.emit(hdr.udp);
        pkt.emit(hdr.vxlan);
        pkt.emit(hdr.inner_ethernet);
        pkt.emit(hdr.inner_ipv4);
        pkt.emit(hdr.inner_udp);
    }
}

control SwitchEgress(
        inout header_t hdr,
        inout empty_metadata_t eg_md,
        in egress_intrinsic_metadata_t eg_intr_md,
        in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr,
        inout egress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md,
        inout egress_intrinsic_metadata_for_output_port_t eg_intr_oport_md) {
    apply {
    }
}

Pipeline(SwitchIngressParser(),
         SwitchIngress(),
         SwitchIngressDeparser(),
         SwitchEgressParser(),
         SwitchEgress(),
         SwitchEgressDeparser()) pipe;

Switch(pipe) main;
