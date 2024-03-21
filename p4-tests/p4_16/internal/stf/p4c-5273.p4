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
#include <t2na.p4>

// headers.p4 -- begin
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
// headers.p4 -- end


// util.p4 -- begin
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
// util.p4 -- end


@pa_auto_init_metadata
@pa_parser_group_monogress
struct metadata_t {
    bit<2> iseop;
    bit<2> test1;
    bool test;
    bit<8> flowid;
    bit<128> dip;
    bit<32> csid;
    bit<8> len;
    bit<14> bum_nh_id;
    bit<1> is_ecmp;
    bit<8> entry_cnt;
    bit<8> mod;
    bit<12> usi;
    bit<1> hw_frr;
    bit<1> is_frr;
    bit<1> sw_frr;
    bit<64> status;
}

struct hw_mc_pair {
    bit<64> tstamp;
    bit<64> status;
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
        //vlan_tag_h vlan_tag = pkt.lookahead<vlan_tag_h>();
        transition select(hdr.ethernet.ether_type) {
            (ETHERTYPE_IPV4) : parse_ipv4;
            (ETHERTYPE_IPV6) : parse_ipv6;
            // (ETHERTYPE_VLAN, ETHERTYPE_VLAN) : parse_qinq;
            (ETHERTYPE_VLAN) : parse_vlan;
            //ETHERTYPE_IPV4 : parse_ipv4;
            //ETHERTYPE_VLAN : parse_vlan;
            default : accept;
        }
    }

    state parse_vlan {
        pkt.extract(hdr.vlan_tag.next);
        //pkt.extract(hdr.vlan_tag[0]);
        //transition select(hdr.vlan_tag[0].ether_type) {
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
        //transition select(hdr.vlan_tag.last.ether_type) {
            // (ETHERTYPE_IPV4) : parse_ipv4;
            // (ETHERTYPE_IPV6) : parse_ipv6;
            // (ETHERTYPE_VLAN) : parse_vlan;
            default : accept;
        }
    }

    state parse_ipv4 {
        pkt.extract(hdr.ipv4);
        transition select(hdr.ipv4.ihl) {
            5 : parse_ipv4_ihl_5;
            6 : parse_ipv4_ihl_6;
            7 : parse_ipv4_ihl_7;
            8 : parse_ipv4_ihl_8;
            9 : parse_ipv4_ihl_9;
            10 : parse_ipv4_ihl_10;
            11 : parse_ipv4_ihl_11;
            12 : parse_ipv4_ihl_12;
            13 : parse_ipv4_ihl_13;
            14 : parse_ipv4_ihl_14;
            15 : parse_ipv4_ihl_15;
            default : accept;
        }
    }

    state parse_ipv4_ihl_5 {
        transition parse_ipv4_proto;
    }

    state parse_ipv4_ihl_6 {
        pkt.extract(hdr.ipv4_option_list[0]);
        transition parse_ipv4_proto;
    }

    state parse_ipv4_ihl_7 {
        pkt.extract(hdr.ipv4_option_list[0]);
        pkt.extract(hdr.ipv4_option_list[1]);
        transition parse_ipv4_proto;
    }

    state parse_ipv4_ihl_8 {
        pkt.extract(hdr.ipv4_option_list[0]);
        pkt.extract(hdr.ipv4_option_list[1]);
        pkt.extract(hdr.ipv4_option_list[2]);
        transition parse_ipv4_proto;
    }

    state parse_ipv4_ihl_9 {
        pkt.extract(hdr.ipv4_option_list[0]);
        pkt.extract(hdr.ipv4_option_list[1]);
        pkt.extract(hdr.ipv4_option_list[2]);
        pkt.extract(hdr.ipv4_option_list[3]);
        transition parse_ipv4_proto;
    }

    state parse_ipv4_ihl_10 {
        pkt.extract(hdr.ipv4_option_list[0]);
        pkt.extract(hdr.ipv4_option_list[1]);
        pkt.extract(hdr.ipv4_option_list[2]);
        pkt.extract(hdr.ipv4_option_list[3]);
        pkt.extract(hdr.ipv4_option_list[4]);
        transition parse_ipv4_proto;
    }

    state parse_ipv4_ihl_11 {
        pkt.extract(hdr.ipv4_option_list[0]);
        pkt.extract(hdr.ipv4_option_list[1]);
        pkt.extract(hdr.ipv4_option_list[2]);
        pkt.extract(hdr.ipv4_option_list[3]);
        pkt.extract(hdr.ipv4_option_list[4]);
        pkt.extract(hdr.ipv4_option_list[5]);
        transition parse_ipv4_proto;
    }

    state parse_ipv4_ihl_12 {
        pkt.extract(hdr.ipv4_option_list[0]);
        pkt.extract(hdr.ipv4_option_list[1]);
        pkt.extract(hdr.ipv4_option_list[2]);
        pkt.extract(hdr.ipv4_option_list[3]);
        pkt.extract(hdr.ipv4_option_list[4]);
        pkt.extract(hdr.ipv4_option_list[5]);
        pkt.extract(hdr.ipv4_option_list[6]);
        transition parse_ipv4_proto;
    }

    state parse_ipv4_ihl_13 {
        pkt.extract(hdr.ipv4_option_list[0]);
        pkt.extract(hdr.ipv4_option_list[1]);
        pkt.extract(hdr.ipv4_option_list[2]);
        pkt.extract(hdr.ipv4_option_list[3]);
        pkt.extract(hdr.ipv4_option_list[4]);
        pkt.extract(hdr.ipv4_option_list[5]);
        pkt.extract(hdr.ipv4_option_list[6]);
        pkt.extract(hdr.ipv4_option_list[7]);
        transition parse_ipv4_proto;
    }

    state parse_ipv4_ihl_14 {
        pkt.extract(hdr.ipv4_option_list[0]);
        pkt.extract(hdr.ipv4_option_list[1]);
        pkt.extract(hdr.ipv4_option_list[2]);
        pkt.extract(hdr.ipv4_option_list[3]);
        pkt.extract(hdr.ipv4_option_list[4]);
        pkt.extract(hdr.ipv4_option_list[5]);
        pkt.extract(hdr.ipv4_option_list[6]);
        pkt.extract(hdr.ipv4_option_list[7]);
        pkt.extract(hdr.ipv4_option_list[8]);
        transition parse_ipv4_proto;
    }

    state parse_ipv4_ihl_15 {
        pkt.extract(hdr.ipv4_option_list[0]);
        pkt.extract(hdr.ipv4_option_list[1]);
        pkt.extract(hdr.ipv4_option_list[2]);
        pkt.extract(hdr.ipv4_option_list[3]);
        pkt.extract(hdr.ipv4_option_list[4]);
        pkt.extract(hdr.ipv4_option_list[5]);
        pkt.extract(hdr.ipv4_option_list[6]);
        pkt.extract(hdr.ipv4_option_list[7]);
        pkt.extract(hdr.ipv4_option_list[8]);
        pkt.extract(hdr.ipv4_option_list[9]);
        transition parse_ipv4_proto;
    }

    state parse_ipv4_proto {
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
        //pkt.emit(hdr.bridged_md); // Ingress only.
        pkt.emit(hdr.ethernet);
        pkt.emit(hdr.vlan_tag);
        //pkt.emit(hdr.arp); // Ingress only.
        //pkt.emit(hdr.ipv4);
        //pkt.emit(hdr.bridged_md);
        //pkt.emit(hdr.fabric_pad);
        pkt.emit(hdr.ipv4);
        pkt.emit(hdr.ipv4_option_list);
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


    Hash<bit<8>>(HashAlgorithm_t.IDENTITY) ecmp_hash;
    ActionProfile(32 * 1024) ecmp_action_profile;
    ActionSelector(ecmp_action_profile,
                   ecmp_hash,
                   SelectorMode_t.FAIR,
                   256,
                   4096) ecmp_selector;


    action set_bum_ecmp_properties(bit<14> nh_id) {
        ig_md.bum_nh_id = nh_id;
        ig_md.is_ecmp = 0;
    }
    action bum_ecmp_miss() {
        ig_md.bum_nh_id = 0;
        ig_md.is_ecmp = 0;
    }

    @ways(6)
    @pragma selector_enable_scramble 0
    table bum_ecmp_member {
        key = {
            ig_md.bum_nh_id : exact @name("ecmp_id");
            ig_md.mod : selector;
        }
        actions = {
            @defaultonly bum_ecmp_miss;
            set_bum_ecmp_properties;
        }
        const default_action = bum_ecmp_miss;
        size = 4096;
        implementation = ecmp_selector;
    }

    Register<bit<8>, bit<4>>(16, 0) mod_reg;
    RegisterAction<bit<8>, bit<4>, bit<8>> (mod_reg) mod_reg_act = {
        void apply(inout bit<8> reg, out bit<8> port){
            port = ig_md.flowid % reg;
        }
    };

    action set_bum_ecmp_id(bit<14> group_id, bit<4> cnt) {
        ig_md.mod = mod_reg_act.execute(cnt);
        ig_md.bum_nh_id = group_id;
    }

    @use_hash_action(1)
    table bum_ecmp_group {
        key = {
            ig_md.bum_nh_id : exact @name("nh_id");
        }
        actions = {
            set_bum_ecmp_id;
        }
        const default_action = set_bum_ecmp_id(0, 3);
        size = 16*1024;
    }

    Register<bit<16>, bit<16>>(65536, 0) port_reg;
    RegisterParam<bit<16>>(1) len;
    RegisterAction<bit<16>, bit<16>, bit<16>> (port_reg) port_reg_act = {
        void apply(inout bit<16> reg, out bit<16> port){
            if (reg == 0) {
                reg = (bit<16>)ig_intr_tm_md.ucast_egress_port;
            }
            port = reg;
        }
    };
    // 要注意不走voq的报文，如组播等
    RegisterAction<bit<16>, bit<16>, bit<16>> (port_reg) port_reg_act2 = {
        void apply(inout bit<16> reg, out bit<16> port){
            // bit<16> temp;
            // if (reg == 0) {
            //     //temp = reg + (bit<16>)ig_intr_tm_md.ucast_egress_port;
            //     port = (bit<16>)ig_intr_tm_md.ucast_egress_port;
            // } else {
            //     //temp = reg + 0;
            //     port = reg;
            //     reg = 0;
            // }
            // port = temp;
            //port = ig_md.flowid << len.read();

        }
    };

    // action build_flow(bit<8> shift) {
    //     ig_intr_tm_md.ucast_egress_port=(bit<9>)port_reg_act.execute(ig_md.flowid);
    //     ig_md.dip = (bit<128>)ig_md.flowid << shift;
    // }
    // action eop_flow() {
    //     ig_intr_tm_md.ucast_egress_port=(bit<9>)port_reg_act2.execute(ig_md.flowid);
    // }

    Hash<bit<16>>(HashAlgorithm_t.IDENTITY) selector_hash;
    // ActionSelector(32768, selector_hash, SelectorMode_t.FAIR) fabric_lag_selector;// 24+7*2

    ActionProfile(16384) action_profile_lag;

    ActionSelector(action_profile_lag,
                   selector_hash,
                   SelectorMode_t.FAIR,
                   4096, // max_group_size
                   16) fabric_lag_selector; //num_groups

    action set_fabric_lag_port(bool port) {
        // ig_intr_tm_md.ucast_egress_port = (bit<9>)port;
        // ig_md.common.dev_port = port;
        // ig_md.iseop = port;
        ig_md.test = port;
    }

    action set() {
        // set_fabric_lag_port(ig_md.iseop >= ig_md.test1);
        set_fabric_lag_port(hdr.ethernet.dst_addr[31:0] == hdr.ipv4.dst_addr[31:0]);
    }

    @pragma selector_enable_scramble 1
    table fabric_lag {
        key = {
            ig_md.iseop : exact;// dst_device can be bfn or fpga as long as they have unique ids.
            ig_md.flowid : selector;
            ig_md.dip : selector;
        }

        actions = {
            NoAction;
            set_fabric_lag_port;
            set;
        }

        const default_action = NoAction;
        size = 128;
        implementation = fabric_lag_selector;
    }

    action set_port_t() {

    }

    action set_port() {
        ig_intr_tm_md.ucast_egress_port = 8;
 hdr.ipv4_option_list[1].setInvalid();
    }

    table port {
        key = {
            ig_md.bum_nh_id : exact;
        }
        actions = {
            NoAction;
            set_port;
            set_port_t;
        }

        default_action = set_port;
    }


       // 4K HW_FRR
    Register<hw_mc_pair, bit<12>>(size=1 << 12, initial_value={0, 0}) hw_usi_reg;
    RegisterAction<hw_mc_pair, bit<12>, bit<64>>(hw_usi_reg) hw_usi_reg_act = {
        void apply(inout hw_mc_pair reg, out bit<64> rv) {
            // 主路径 且 软件frr转发 -> 更新时间戳 状态更新为0
            // if ((bit<32>)ig_md.is_frr == 0 && ig_md.sw_frr == 0) {
                reg.tstamp = (bit<64>)ig_intr_md.ingress_mac_tstamp;
                reg.status = ig_md.status;
                rv = reg.status;
            // }
        }
    };

    action get_hw_frr(){
        ig_md.hw_frr = (bit<1>)hw_usi_reg_act.execute(ig_md.usi);
    }

    table hw_frr {
        //keyless
        actions = {
            get_hw_frr;
        }
        const default_action = get_hw_frr;
    }

    apply {
        //ig_intr_md_for_tm.ucast_egress_port = ig_intr_md.ingress_port;
        ig_md.bum_nh_id = hdr.ethernet.dst_addr[13:0];
        ig_md.flowid = hdr.ethernet.src_addr[7:0];
        // ig_md.iseop = hdr.ethernet.dst_addr[1:0];
        //ig_intr_tm_md.ucast_egress_port = 1;
        // port.apply();
        fabric_lag.apply();

        // bum_ecmp_group.apply();
        // bum_ecmp_member.apply();
        port.apply();

        hw_frr.apply();

        if(ig_md.is_ecmp==1 && ig_md.bum_nh_id==1 && ig_md.hw_frr==1) {
            ig_md.flowid = 0;
        }

        if (ig_md.test) {
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

    // state parse_bridged_md {
    //     pkt.extract(hdr.bridged_md);
    //     pkt.extract(hdr.fabric_pad);
    //     transition parse_ipv4;
    // }

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
        //pkt.emit(hdr);
        //pkt.emit(hdr.bridged_md);
        //pkt.emit(hdr.fabric_pad);
        //pkt.emit(hdr.fabric);
        //pkt.emit(hdr.fake_tag);
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

    // // Create direct counters
    DirectCounter<bit<32>>(CounterType_t.PACKETS_AND_BYTES, true) direct_counter_teop;

    // DirectCounter<bit<32>>(CounterType_t.PACKETS_AND_BYTES) direct_counter;

    Counter<bit<64>,bit<15>>(10, CounterType_t.PACKETS_AND_BYTES) overlay_counter;

    bit<32> a = 32w0;
    bit<32> b = 32w0;

    action nop() { }

    // action hit_src() {
    //     // Call direct counter. Note that no index parameter is required because
    //     // the index is implicitely generated from the entry of the the 
    //     // associated match table.
    //     direct_counter.count();
    // }

    // table count_src {
    //     key = {
    //         hdr.ethernet.src_addr : ternary;
    //     }

    //     actions = {
    //         hit_src;
    //         @defaultonly nop;
    //     }

    //     size = 1024;
    //     const default_action = nop;
    //     // Associate this table with a direct counter
    //     counters = direct_counter;
    // }

    action hit_src_teop() {
        // hdr.ipv4.setInvalid();
        // hdr.ethernet.ether_type = 0xffff;
        // direct_counter_teop.count();
        //hdr.ipv4.ttl.setInvalid();
        //hdr.inner_ipv4.dst_addr = a;
        // a = a + 32w10;
    }

    action ol_count4B() {
        overlay_counter.count(1, sizeInBytes(hdr.ethernet));
    }

    action ol_count() {
        overlay_counter.count(1);
    }

    @stage(2)
    table count_src_teop {
        key = {
            hdr.ethernet.src_addr : ternary;
            // hdr.inner_ipv4.total_len[15:8] : ternary @name("dip_l3class_id");
            // hdr.inner_ipv4.total_len[7:0] : ternary @name("sip_l3class_id");
        }

        actions = {
            // hit_src_teop;
            ol_count;
            ol_count4B;
            @defaultonly nop;
        }

        size = 1024;
        const default_action = nop;
        // Associate this table with a direct counter
        // counters = direct_counter_teop;
    }

    // action add_fabric_fake_tag() {
    //     hdr.fabric.setValid();
    //     hdr.fabric.f1 = 7;
    //     hdr.fabric.f2 = 6;
    //     hdr.fabric.f3 = 5;
    //     hdr.fabric.f4 = 4;
    //     hdr.fabric.f5 = 3;
    //     hdr.fabric.f6 = 2;
    //     hdr.fabric.f7 = 1;
    //     hdr.fake_tag.setValid();
    //     hdr.fake_tag.f1 = eg_intr_md.pkt_length;
    // }

    // action add_fabric() {
    //     hdr.fabric.setValid();
    //     hdr.fabric.f1 = 7;
    //     hdr.fabric.f2 = 6;
    //     hdr.fabric.f3 = 5;
    //     hdr.fabric.f4 = 4;
    //     hdr.fabric.f5 = 3;
    //     hdr.fabric.f6 = 2;
    //     hdr.fabric.f7 = 1;
    // }

    // table pkt_rewrite {
    //     key = {
    //         eg_intr_md.pkt_length : exact;
    //     }

    //     actions = {
    //         add_fabric_fake_tag;
    //         add_fabric;
    //     }

    //     const default_action = add_fabric;
    // }

    // action add_ethernet_header() {
    //     hdr.ethernet.setValid();
    //     hdr.ethernet.src_addr = 48w0;
    //     hdr.ethernet.dst_addr = 48w0;
    //     hdr.ethernet.ether_type = 16w2048;
    // }

    // action add_ipv4_header() {
    //     hdr.ipv4.setValid();
    //     hdr.ipv4.version = 4w4;
    //     hdr.ipv4.ihl = 4w5;
    //     hdr.ipv4.identification = 0;
    //     hdr.ipv4.frag_offset = 0;
    //     hdr.ipv4.diffserv = 0;

    //     hdr.ipv4.flags = 2;//3 bit, 010 表示不能分片
    //     hdr.ipv4.protocol = 17;

    //     // Total length = packet length + 50
    //     // IPv4 (20) + UDP (8) + VXLAN (8)+ Inner Ethernet (14)
    //     hdr.ipv4.total_len = hdr.inner_ipv4.total_len + 16w50;

    //     hdr.ipv4.src_addr = 32w0;
    //     hdr.ipv4.dst_addr = 32w0;
    //     hdr.ipv4.ttl = 64;
    //     hdr.ipv4.diffserv[7:2] = 0;
    // }

    // action add_udp_header() {
    //     hdr.udp.setValid();
    //     hdr.udp.src_port = 16w1234;
    //     hdr.udp.dst_port = 16w4789;
    //     hdr.udp.checksum = 0;//todo calculate
    //     // UDP length = packet length + 30
    //     // UDP (8) + VXLAN (8)+ Inner Ethernet (14)
    //     hdr.udp.hdr_length = hdr.inner_ipv4.total_len + 16w30;
    // }

    // action add_vxlan_header(bit<24> vni) {
    //     hdr.vxlan.setValid();
    //     hdr.vxlan.flags = 8w0x08;
    //     //hdr.vxlan.reserved = 0;
    //     hdr.vxlan.vni = vni;
    //     //hdr.vxlan.reserved2 = 0;
    // }

    // action encap(bit<24> vni) {
    //     add_vxlan_header(vni);
    //     add_udp_header();
    //     add_ipv4_header();
    //     add_ethernet_header();
    // }

    // table encap_vxlan {
    //     // key = {
    //     //     eg_intr_md.pkt_length : exact;
    //     // }

    //     actions = {
    //         encap;
    //     }

    //     const default_action = encap(100);
    // }

    apply {
        //count_src.apply();
        // b =hdr.inner_ipv4.src_addr;

        // a =hdr.inner_ipv4.dst_addr;

        // a = a + b;

        // if (count_src_teop.apply().hit) {
        //     //
        // }

        // hdr.inner_ipv4.dst_addr = a;


        //pkt_rewrite.apply();
        //encap_vxlan.apply();
    }
}

Pipeline(SwitchIngressParser(),
         SwitchIngress(),
         SwitchIngressDeparser(),
         SwitchEgressParser(),
         SwitchEgress(),
         SwitchEgressDeparser()) pipe;

Switch(pipe) main;
