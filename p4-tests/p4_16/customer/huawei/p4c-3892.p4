/*******************************************************************************
 * Copyright (c) Huawei Technologies Co., Ltd. 2021-2021. All rights reserved.
 * Descrption: casteni gw main pipeline
 * Author: lihaifeng
 * Create: 2021-02-01
 * Note:
 * History: 2021-02-01 created it;
 *          2021-03-17 refactored it, using control function.
 *          2021-04-10 refactored it, reduced parameters of control.
 *          2021-04-22 added drop counters to statistics drop reason, delete drop_reason control.
 *          2021-06-09 add parser error validation in ingress and egress control.
 ******************************************************************************/

#include <core.p4>
#if __TARGET_TOFINO__ == 2
#include <t2na.p4>
#else
#include <tna.p4>
#endif

//-----------------------------------------------------------------------------
// Protocol Header Definitions
//-----------------------------------------------------------------------------

typedef bit<48> mac_addr_t;
typedef bit<24> casteni_mac_prefix_t;
typedef bit<24> casteni_mac_suffix_t;
typedef bit<8> subeni_mac_prefix_t;
typedef bit<40> subeni_mac_suffix_t;
typedef bit<32> ipv4_addr_t;
typedef bit<128> ipv6_addr_t;
typedef bit<12> vlan_id_t;
typedef bit<16> ether_type_t;
typedef bit<8> ip_protocol_t;
typedef bit<8> pkt_type_t;

header ethernet_h {
    mac_addr_t dst_addr;
    mac_addr_t src_addr;
    bit<16> ether_type;
}

header vlan_tag_h {
    bit<3> pcp; // Priority
    bit<1> cfi;
    vlan_id_t vid; // vlan id
    bit<16> ether_type;
}

header ipv4_h {
    bit<4> version;
    bit<4> ihl;
    bit<8> diffserv;
    bit<16> total_len;
    bit<16> identification;
    bit<1> flags_r;
    bit<1> flags_df;
    bit<1> flags_mf;
    bit<13> frag_offset;
    bit<8> ttl;
    bit<8> protocol;
    bit<16> hdr_checksum;
    ipv4_addr_t src_addr;
    ipv4_addr_t dst_addr;
}

#ifdef SPLIT_IPV4
header ipv4_no_dst_h {
    bit<4> version;
    bit<4> ihl;
    bit<8> diffserv;
    bit<16> total_len;
    bit<16> identification;
    bit<1> flags_r;
    bit<1> flags_df;
    bit<1> flags_mf;
    bit<13> frag_offset;
    bit<8> ttl;
    bit<8> protocol;
    bit<16> hdr_checksum;
    ipv4_addr_t src_addr;
}

header ipv4_dst_h {
    ipv4_addr_t dst_addr;
}
#endif  /* SPLIT_IPV4 */

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

// Address Resolution Protocol -- RFC 6747
header arp_h {
    bit<16> hw_type;
    bit<16> proto_type;
    bit<8> hw_addr_len;
    bit<8> proto_addr_len;
    bit<16> opcode;
    // ...
}

header icmp_h {
    bit<8> type;
    bit<8> code;
    bit<16> hdr_checksum;
}

header igmp_h {
    bit<8> type;
    bit<8> code;
    bit<16> checksum;
    // ...
}

// VXLAN -- RFC 7348
header vxlan_h {
    bit<8> flags;
    bit<24> reserved;
    bit<24> vni;
    bit<8> reserved2;
}

// Generic Protocol Extension for VXLAN -- IETFv4
header vxlan_gpe_h {
    bit<8> flags;
    bit<16> reserved;
    bit<24> vni;
    bit<8> reserved2;
}

// Barefoot Specific Headers, 5 bytes
header fabric_h {
    bit<3> packet_type;
    bit<2> hdr_ver;
    bit<2> pkt_ver;
    bit<1> reserved1;
    bit<3> color;
    bit<5> qos;
    bit<8> dst_dev;
    bit<16> dst_port_or_group;
}

// CPU header, 11 bytes
header cpu_h {
    bit<5> egress_queue;
    bit<1> tx_bypass;
    bit<2> reserved;
    bit<16> ingress_port;
    bit<16> port_lag_index;
    bit<16> ingress_bd;
    bit<16> reason_code; // Also used as a 16-bit bypass flag.
    bit<16> ether_type;
}

header timestamp_h {
    bit<48> timestamp;
}

// ----------------------------------------------------------------------------
// Common table sizes
//-----------------------------------------------------------------------------

const bit<32> LAG_TABLE_SIZE = 16;
const bit<32> LAG_GROUP_TABLE_SIZE = 64;
const bit<32> LAG_MAX_MEMBERS_PER_GROUP = 64;
const bit<32> LAG_SELECTOR_TABLE_SIZE = 4096;

// ----------------------------------------------------------------------------
// Common types
//-----------------------------------------------------------------------------
typedef bit<32> uint32_t;
typedef bit<16> uint16_t;
typedef bit<8> uint8_t;

typedef PortId_t port_t;
const port_t PORT_INVALID = 9w0x1ff;
typedef bit<7> port_padding_t;

typedef QueueId_t qid_t;

typedef bit<4> port_destack_index_t;
typedef bit<4> port_lag_index_t;
const port_lag_index_t SWITCH_FLOOD = 0xF;

typedef int<16> ecmp_hash_int_t;
typedef bit<16> ecmp_hash_int_mid_t;
typedef bit<8> ecmp_hash_t;
typedef bit<20> ecmp_group_t;
typedef bit<18> ecmp_member_t;

typedef bit<24> vxlan_id_t;
typedef bit<16> mtu_t;
typedef bit<12> dst_ipv4_id_t;

typedef bit<16> cpu_reason_t;
const cpu_reason_t CPU_REASON_PTP = 8;

typedef bit<3> drop_ctl_t;
const drop_ctl_t DROP_CTL_DISABLE_UNI_MULTCAST_RESUB = 1 << 0;
const drop_ctl_t DROP_CTL_DISABLE_COPY_TO_CPU = 1 << 1;
const drop_ctl_t DROP_CTL_DISABLE_MIRRORING = 1 << 2;

typedef bit<4> nexttier_type_t;
const nexttier_type_t NEXTTIER_TYPE_NONE = 0;
const nexttier_type_t NEXTTIER_TYPE_PIPELINE = 1;
const nexttier_type_t NEXTTIER_TYPE_SWITCH = 2;

const bit<1> BYPASS_EGRESS_ENABLE = 1;

typedef bit<32> cpu_meter_index_t;
typedef bit<32> mirror_meter_index_t;

struct vtep_ip_value_set_t {
    bit<16> vtep_ip_prefix;
    bit<16> vtep_ip_subfix;
}

typedef bit<3> ecmp_backend_miss_t;
const ecmp_backend_miss_t ECMP_BACKEND_MISS = 0;
const ecmp_backend_miss_t ECMP_BACKEND_HIT = 1;

typedef bit<2> pkt_cnt_t;
const pkt_cnt_t PKT_CNT_ALL = 0;
const pkt_cnt_t PKT_CNT_NORMAL_PKT = 1;
const pkt_cnt_t PKT_CNT_CPU_PKT = 2;

typedef bit<4> proto_cnt_t;
const proto_cnt_t L3_PROTO_CNT_UNKNOW = 0;
const proto_cnt_t L3_PROTO_CNT_IPV4_NO_OPTIONS = 1;
const proto_cnt_t L3_PROTO_CNT_IPV4_OPTIONS = 2;
const proto_cnt_t L3_PROTO_CNT_IPV6 = 3;
const proto_cnt_t L3_PROTO_CNT_ARP = 4;
const proto_cnt_t L3_PROTO_CNT_LACP = 5;
const proto_cnt_t L3_PROTO_CNT_LLDP = 6;

const proto_cnt_t L4_PROTO_CNT_UNKNOW = 0;
const proto_cnt_t L4_PROTO_CNT_IPV4_FRAG = 1;
const proto_cnt_t L4_PROTO_CNT_TCP = 2;
const proto_cnt_t L4_PROTO_CNT_ICMP = 3;
const proto_cnt_t L4_PROTO_CNT_IGMP = 4;
const proto_cnt_t L4_PROTO_CNT_UDP = 5;
const proto_cnt_t L4_PROTO_CNT_VXLAN = 6;

typedef bit<8> err_reason_t;
const err_reason_t ERR_REASON_UNKNOW_ERR = 0;
const err_reason_t ERR_REASON_CASTENI_MAC_PREFIX_ERR = 1;
const err_reason_t ERR_REASON_MODULUS_COMPUTING_MISS = 2;
const err_reason_t ERR_REASON_LAG_MISS = 3;

typedef bit<8> drop_reason_t;
const drop_reason_t DROP_REASON_UNKNOWN = 0;
const drop_reason_t DROP_REASON_UNSUPPORTED_ETHERTYPE = 1;
const drop_reason_t DROP_REASON_UNSUPPORTED_FRAG_OFFSET = 2;
const drop_reason_t DROP_REASON_UNSUPPORTED_INNER_VLAN_PROTO = 3;
const drop_reason_t DROP_REASON_UNSUPPORTTED_UNDERLAY_IPV6 = 4;
const drop_reason_t DROP_REASON_SRC_MAC_ZERO = 5;
const drop_reason_t DROP_REASON_SRC_MAC_MULTICAST = 6;
const drop_reason_t DROP_REASON_DST_MAC_ZERO = 7;
const drop_reason_t DROP_REASON_SRC_IP_ZERO = 8;
const drop_reason_t DROP_REASON_DST_IP_ZERO = 9;
const drop_reason_t DROP_REASON_ETHERNET_MISS = 10;
const drop_reason_t DROP_REASON_SAME_MAC_CHECK = 11;
const drop_reason_t DROP_REASON_IP_VERSION_INVALID = 12;
const drop_reason_t DROP_REASON_IP_TTL_ZERO = 13;
const drop_reason_t DROP_REASON_IP_SRC_MULTICAST = 14;
const drop_reason_t DROP_REASON_IP_SRC_LOOPBACK = 15;
const drop_reason_t DROP_REASON_IP_MISS = 16;
const drop_reason_t DROP_REASON_IP_IHL_INVALID = 17;
const drop_reason_t DROP_REASON_IP_INVALID_CHECKSUM = 18;
const drop_reason_t DROP_REASON_MTU_CHECK_FAIL = 19;

const drop_reason_t DROP_REASON_PORT_VLAN_MAPPING_MISS = 20;
const drop_reason_t DROP_REASON_TRAFFIC_MANAGER = 21;
const drop_reason_t DROP_REASON_STORM_CONTROL = 22;
const drop_reason_t DROP_REASON_WRED = 23;
const drop_reason_t DROP_REASON_INGRESS_PORT_METER = 24;
const drop_reason_t DROP_REASON_INGRESS_ACL_METER = 25;
const drop_reason_t DROP_REASON_EGRESS_PORT_METER = 26;
const drop_reason_t DROP_REASON_EGRESS_ACL_METER = 27;
const drop_reason_t DROP_REASON_CPU_COLOR_YELLOW = 28;
const drop_reason_t DROP_REASON_CPU_COLOR_RED = 29;
const drop_reason_t DROP_REASON_L2_UNICAST_MISS = 30;
const drop_reason_t DROP_REASON_L2_MULTICAST_MISS = 31;
const drop_reason_t DROP_REASON_L2_BROADCAST_MISS = 32;
const drop_reason_t DROP_REASON_INGRESS_MAPPING_PREROUTE_MISS = 33;
const drop_reason_t DROP_REASON_NON_IP_ROUTER_MAC = 34;
const drop_reason_t DROP_REASON_L3_IPV4_DISABLE = 35;
const drop_reason_t DROP_REASON_L3_IPV6_DISABLE = 36;
const drop_reason_t DROP_REASON_ECMP_GROUP_MISS = 37;
const drop_reason_t DROP_REASON_ECMP_MODULUS_MISS = 38;
const drop_reason_t DROP_REASON_ECMP_BACKEND_MISS = 39;
const drop_reason_t DROP_REASON_ECMP_MEMBER_MISS = 40;
const drop_reason_t DROP_REASON_FIB_ARP_MISS = 41;
const drop_reason_t DROP_REASON_ARP_MISS = 42;
const drop_reason_t DROP_REASON_LAG_MISS = 43;
const drop_reason_t DROP_REASON_ECMP_BACKENDS_NUM_ZERO = 44;
const drop_reason_t DROP_REASON_METER_MIRROR2CPU_COLOR_RED = 45;
const drop_reason_t DROP_REASON_METER_MIRROR2NORMAL_PORT_COLOR_RED = 46;
const drop_reason_t DROP_REASON_UNKOWN_NEXTHOP_PORT_TYPE = 47;
const drop_reason_t DROP_REASON_PARSER_ERROR_NO_TCAM = 48;
const drop_reason_t DROP_REASON_PARSER_ERROR_PARTIAL_HDR = 49;
const drop_reason_t DROP_REASON_PARSER_ERROR_CTR_RANGE = 50;
const drop_reason_t DROP_REASON_PARSER_ERROR_TIMEOUT_USER = 51;
const drop_reason_t DROP_REASON_PARSER_ERROR_TIMEOUT_HW = 52;
const drop_reason_t DROP_REASON_PARSER_ERROR_SRC_EXT = 53;
const drop_reason_t DROP_REASON_PARSER_ERROR_DST_CONT = 54;
const drop_reason_t DROP_REASON_PARSER_ERROR_PHV_OWNER = 55;
const drop_reason_t DROP_REASON_PARSER_ERROR_MULTIWRITE = 56;
const drop_reason_t DROP_REASON_PARSER_ERROR_ARAM_MBE = 57;
const drop_reason_t DROP_REASON_PARSER_ERROR_FCS = 58;
const drop_reason_t DROP_REASON_PARSER_ERROR_CSUM_MBE = 59;

typedef bit<4> port_type_t;
const port_type_t PORT_TYPE_DROP = 0;
const port_type_t PORT_TYPE_CPU = 1;
const port_type_t PORT_TYPE_NORMAL_PORT = 2;
const port_type_t PORT_TYPE_MIRROR_PORT = 4;
const port_type_t PORT_TYPE_MIRROR_CPU = 8;
const port_type_t PORT_TYPE_PORT_MASK = 0x3;

/* if 0b100(4) & 0b11(0x3) = 0, 0b1000(8) & 0b11(0x3) == 0, it is mirror port */

const MirrorType_t MIRROR_TYPE_NONE = 0;
const MirrorType_t MIRROR_TYPE_INGRESS = 1;
const MirrorType_t MIRROR_TYPE_EGRESS = 2;
const MirrorType_t MIRROR_TYPE_BOTH = 3;

const MirrorType_t MIRROR_TYPE_INGRESS_MASK = 0x1;
const MirrorType_t MIRROR_TYPE_EGRESS_MASK = 0x2;

// Bypass flags ---------------------------------------------------------------
typedef bit<8> ingress_bypass_t;
const ingress_bypass_t INGRESS_BYPASS_DESTACK = 8w0x01;
const ingress_bypass_t INGRESS_BYPASS_LAG_GROUP = 8w0x02;
const ingress_bypass_t INGRESS_BYPASS_ECMP = 8w0x03;
const ingress_bypass_t INGRESS_BYPASS_FIB = 8w0x04;
const ingress_bypass_t INGRESS_BYPASS_ARP = 8w0x05;
const ingress_bypass_t INGRESS_BYPASS_METER = 8w0x06;
const ingress_bypass_t INGRESS_BYPASS_STORM_CONTROL = 8w0x07;
const ingress_bypass_t INGRESS_BYPASS_REWRITE = 8w0x08;

// Add more ingress bypass flags here.

const ingress_bypass_t INGRESS_BYPASS_ALL = 8w0xff;

typedef bit<8> egress_bypass_t;
const egress_bypass_t EGRESS_BYPASS_DESTACK = 8w0x01;
const egress_bypass_t EGRESS_BYPASS_LAG_GROUP = 8w0x02;
const egress_bypass_t EGRESS_BYPASS_ECMP = 8w0x03;
const egress_bypass_t EGRESS_BYPASS_FIB = 8w0x04;
const egress_bypass_t EGRESS_BYPASS_ARP = 8w0x05;
const egress_bypass_t EGRESS_BYPASS_METER = 8w0x06;
const egress_bypass_t EGRESS_BYPASS_STORM_CONTROL = 8w0x07;
const egress_bypass_t EGRESS_BYPASS_REWRITE = 8w0x08;
const egress_bypass_t EGRESS_BYPASS_MTU = 8w0x09;

// Add more egress bypass flags here.

const egress_bypass_t EGRESS_BYPASS_ALL = 8w0xff;


// PKT ------------------------------------------------------------------------
typedef bit<16> pkt_length_t;

typedef bit<8> pkt_src_t;
typedef pkt_src_t pkt_src_cnt_t;


const pkt_src_t PKT_SRC_NORMAL_INGRESS = 0;
const pkt_src_t PKT_SRC_CPU_INGRESS = 1;
const pkt_src_t PKT_SRC_CLONED_INGRESS = 2;
const pkt_src_t PKT_SRC_CLONED_EGRESS = 3;

const pkt_src_t MIRROR_TYPE2SRC_OFFSET = 1;


const MeterColor_t METER_COLOR_GREEN = MeterColor_t.GREEN;
const MeterColor_t METER_COLOR_YELLOW = MeterColor_t.YELLOW;
const MeterColor_t METER_COLOR_RED = MeterColor_t.RED;

const pkt_type_t PKT_TYPE_UNICAST = 0;
const pkt_type_t PKT_TYPE_MULTICAST = 1;
const pkt_type_t PKT_TYPE_BROADCAST = 2;

typedef bit<2> ip_type_t;
const ip_type_t IP_TYPE_NONE = 0;
const ip_type_t IP_TYPE_IPV4 = 1;
const ip_type_t IP_TYPE_IPV6 = 2;

typedef bit<2> ip_frag_t;
const ip_frag_t IP_FRAG_NON_FRAG = 0b00; // Not fragmented.
const ip_frag_t IP_FRAG_HEAD = 0b10; // First fragment of the fragmented packets.
const ip_frag_t IP_FRAG_NON_HEAD = 0b11; // Fragment with non-zero offset.


// Metering -------------------------------------------------------------------

typedef bit<8> copp_meter_id_t;
typedef bit<32> meter_index_t;
typedef bit<8> mirror_meter_id_t;
typedef bit<8> meter_color_t;

// Learning -------------------------------------------------------------------
typedef bit<1> learning_mode_t;
const learning_mode_t LEARNING_MODE_DISABLED = 0;
const learning_mode_t LEARNING_MODE_LEARN = 1;

struct learning_digest_t {
    port_lag_index_t port_lag_index;
    mac_addr_t src_addr;
}

// Mirroring ------------------------------------------------------------------
// Defined in tofinox.p4, tofino1 bit<10>, tofino2 bit<8>
typedef MirrorId_t mirror_session_t;
const mirror_session_t MIRROR_SESSION_CPU = 250;

// Using same mirror type for both Ingress/Egress to simplify the parser.

// Common metadata used for mirroring.
struct mirror_metadata_t {
    pkt_src_t src;
    port_type_t type;
    mirror_session_t session_id;
    meter_color_t color;
    mirror_meter_index_t meter_index;
    MirrorType_t mirror_type;
    ether_type_t ethernet_bfn;
}

header mirror_metadata_h {
    pkt_src_t src; // 8
    port_type_t type; // 4
    bit<3> _pad;
    port_t ingress_port; // 9
    ether_type_t ethernet_bfn;
}

// This header is only used inside of our pipeline and will never leave the
// chip. Therefore, we let the compiler decide how to layout the fields by using 
// the @flexible pragma.
@flexible
header ecmp_metadata_h {
    pkt_src_t src;

    port_type_t type; // 4
    port_lag_index_t egress_lag_index; // 4

    port_t ingress_port; // 9
    ecmp_backend_miss_t backend_miss; // 3
    ecmp_group_t group_id; // 20

    ether_type_t ethernet_bfn;


    proto_cnt_t inner_l3_proto_cnt; // 4
    proto_cnt_t inner_l4_proto_cnt; // 4

    ecmp_hash_t backend_index;

    port_type_t mirror_nexthop_type; // 4
    mirror_session_t session_id; // tofino1 10bits, tofino2 8bits

    MirrorType_t egress_mirror_type; // tofino1 3bits, tofino2 4bits

    bit<7> _pad;

}

//-----------------------------------------------------------------------------
// Other Metadata Definitions
//-----------------------------------------------------------------------------
struct ingress_flags_t {
    bit<1> is_ipv4;
    bit<1> ipv4_checksum_err;

    bool port_meter_drop;
    bool bypass_egress;
    bool sending_cpu;

    bool ecmp_group_miss;
    bool err_occured;

    bool is_cpu_pkt;
    // Add more flags here.
}

struct egress_flags_t {
    bool bypass_egress;
    bool port_meter_drop;

    bool ecmp_group_miss;
    bool ecmp_member_miss;
    bool is_vlan;
    bool needed_checksum;

    // Add more flags here.
}

struct lookup_fields_t {
    pkt_type_t pkt_type;

    mac_addr_t outer_dst_mac;
    mac_addr_t outer_src_mac;
    ether_type_t outer_ether_type;

    // _ for ARP request, 2 for ARP reply.
    bit<16> arp_opcode;

    vxlan_id_t vxlan_id;

    mac_addr_t inner_dst_mac;
    mac_addr_t inner_src_mac;
    ether_type_t inner_ether_type;

    ip_type_t inner_ip_type;
    bit<8> inner_ip_proto;
    bit<2> inner_ip_frag;
    bit<128> inner_src_ip;
    bit<128> inner_dst_ip;

    bit<8> inner_tcp_flags;
    bit<16> inner_src_port;
    bit<16> inner_dst_port;
}

struct ingress_metadata_t {
    pkt_src_t src;
    port_type_t nexthop_type; /* egress port type */
    nexttier_type_t nexttier_type;

    port_t port;
    port_t egress_port;
    port_lag_index_t ingress_port_lag_index;
    port_lag_index_t egress_port_lag_index;
    ipv4_addr_t nexthop; // outer nexthop

    ipv4_addr_t vtep_ip;
    ipv4_addr_t cna_vtep_ip;
    ether_type_t ethernet_bfn;

    ingress_bypass_t bypass;

    proto_cnt_t outer_l3_proto_cnt;
    proto_cnt_t outer_l4_proto_cnt;
    proto_cnt_t inner_l3_proto_cnt;
    proto_cnt_t inner_l4_proto_cnt;

    drop_reason_t drop_reason;
    cpu_reason_t cpu_reason;
    err_reason_t err_reason;
    mac_addr_t same_mac;
    meter_color_t cpu_meter_color;
    bit<16> vtep_ip_prefix;
    bit<16> vtep_ip_suffix;
    bool checksum_upd_udp;

    ingress_flags_t flags;
    lookup_fields_t lkp;
}

struct empty_header_t {}

struct empty_metadata_t {}

struct header_t {
    ecmp_metadata_h ecmp_md;
    mirror_metadata_h mirror_md;

    ethernet_h ethernet;

    fabric_h fabric;
    cpu_h cpu;

    vlan_tag_h[2] vlan_tag;
    ipv4_h ipv4;




    arp_h arp;
    udp_h udp;
    tcp_h tcp;
    icmp_h icmp;
    igmp_h igmp;

    vxlan_h vxlan;

    ethernet_h inner_ethernet;
    vlan_tag_h[2] inner_vlan_tag;
    arp_h inner_arp;
    ipv4_h inner_ipv4;
    ipv4_option_h[10] inner_ipv4_options;
    ipv6_h inner_ipv6;
    udp_h inner_udp;
    tcp_h inner_tcp;
    icmp_h inner_icmp;
    igmp_h inner_igmp;
}

# 1 "../../p4c-3892/include/util.p4" 1
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
# 24 "../../p4c-3892/casteni_gw.p4" 2

# 1 "../../p4c-3892/include/parde.p4" 1
//=============================================================================
// Ingress parser
//=============================================================================
parser SwitchIngressParser(
        packet_in pkt,
        out header_t hdr,
        out ingress_metadata_t ig_md,
        out ingress_intrinsic_metadata_t ig_intr_md) {
    Checksum() ipv4_checksum;
    value_set<vtep_ip_value_set_t>(1) vtep_ip;

    state start {
        /* init ig_md to eliminate the warning "out parameter ig_md may be uninitialized",
           since p4-16 does not specify the default value of metadata */
# 29 "../../p4c-3892/include/parde.p4"
        ig_md = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0, false,
            {0, 0, false, false, false, false, false, false}, // ingress flag
            {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0} // lookup_field
        };

        pkt.extract(ig_intr_md);
        hdr.ecmp_md.setValid();
        ig_md.egress_port = PORT_INVALID;
        ig_md.port = ig_intr_md.ingress_port;

        /* Check for resubmit flag if packet is resubmitted. */
        transition select(ig_intr_md.resubmit_flag) {
            1 : parse_resubmit;
            default : parse_port_metadata;
        }
    }

    state parse_resubmit {
        /* Parse resubmitted packet here. */
        transition reject;
    }

    state parse_port_metadata {
        pkt.advance(PORT_METADATA_SIZE);
        transition parse_ethernet;
    }

    state parse_ethernet {
        pkt.extract(hdr.ethernet);

        ig_md.lkp.outer_src_mac = hdr.ethernet.src_addr;
        ig_md.lkp.outer_dst_mac = hdr.ethernet.dst_addr;

        transition select(hdr.ethernet.ether_type, ig_intr_md.ingress_port) {
            (0x0800, _) : parse_ipv4;
            default : accept;
        }
    }

#ifdef SPLIT_IPV4
    state parse_ipv4 {
        pkt.extract(hdr.ipv4_no_dst);
        ig_md.flags.is_ipv4 = 1;
        ipv4_checksum.add(hdr.ipv4_no_dst);
        transition select(hdr.ipv4_no_dst.ihl) {
            5  : parse_ipv4_no_options;
            default : parse_ipv4_options;
        }
    }

    state parse_ipv4_options {
        pkt.extract(hdr.ipv4_dst);
        ig_md.outer_l3_proto_cnt = L3_PROTO_CNT_IPV4_OPTIONS; 
        transition accept;
    }

    state parse_ipv4_no_options {
        pkt.extract(hdr.ipv4_dst);
        ipv4_checksum.add(hdr.ipv4_dst);
        ig_md.outer_l3_proto_cnt = L3_PROTO_CNT_IPV4_NO_OPTIONS; 
        ig_md.flags.ipv4_checksum_err = (bit<1>) ipv4_checksum.verify();
        
        transition select(hdr.ipv4_no_dst.protocol, hdr.ipv4_no_dst.flags_mf, hdr.ipv4_no_dst.frag_offset) {
            (IP_PROTOCOLS_UDP, 0, 0)  : parse_vxlan_vtepip;
            default                   : accept;
        }
    }

    state parse_vxlan_vtepip {
        transition select((bit<16>)hdr.ipv4_dst.dst_addr[15:0], (bit<16>)hdr.ipv4_dst.dst_addr[31:16]) { 
            vtep_ip : parse_udp;
	        default    : parse_normal_udp;
	    }
    }

#else
    state parse_ipv4 {
        pkt.extract(hdr.ipv4);
        ig_md.flags.is_ipv4 = 1;
        ipv4_checksum.add(hdr.ipv4);
        transition select(hdr.ipv4.ihl) {
            5 : parse_ipv4_no_options;
            default : parse_ipv4_options;
        }
    }

    state parse_ipv4_options {
        ig_md.outer_l3_proto_cnt = L3_PROTO_CNT_IPV4_OPTIONS;
        transition accept;
    }

    state parse_ipv4_no_options {
        ig_md.outer_l3_proto_cnt = L3_PROTO_CNT_IPV4_NO_OPTIONS;
        ig_md.flags.ipv4_checksum_err = (bit<1>) ipv4_checksum.verify();

        transition select(hdr.ipv4.protocol, hdr.ipv4.flags_mf, hdr.ipv4.frag_offset) {
            (17, 0, 0) : parse_vxlan_vtepip;
            default : accept;
        }
    }

    state parse_vxlan_vtepip {
        transition select((bit<16>)hdr.ipv4.dst_addr[15:0], (bit<16>)hdr.ipv4.dst_addr[31:16]) {
            vtep_ip : parse_udp;
                default : parse_normal_udp;
            }
    }
#endif  /* SPLIT_IPV4 */

    state parse_udp {
        pkt.extract(hdr.udp);
        transition select(hdr.udp.dst_port) {
            4789 : parse_vxlan;
         default : parse_normal_udp;
     }
    }

    state parse_vxlan {
        pkt.extract(hdr.vxlan);
        ig_md.outer_l4_proto_cnt = L4_PROTO_CNT_VXLAN;
        ig_md.lkp.vxlan_id = hdr.vxlan.vni;
        transition accept;
    }

    state parse_normal_udp {
        ig_md.outer_l4_proto_cnt = L4_PROTO_CNT_UDP;
        transition accept;
    }
}

//-----------------------------------------------------------------------------
// Ingress Deparser
//-----------------------------------------------------------------------------
control SwitchIngressDeparser(
    packet_out pkt,
    inout header_t hdr,
    in ingress_metadata_t ig_md,
    in ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr) {

    apply {
        pkt.emit(hdr.ethernet);
        pkt.emit(hdr.ipv4);
        pkt.emit(hdr.udp);
        pkt.emit(hdr.vxlan);
    }
}
# 25 "../../p4c-3892/casteni_gw.p4" 2

control SwitchIngress(
        inout header_t hdr,
        inout ingress_metadata_t ig_md,
        in ingress_intrinsic_metadata_t ig_intr_md,
        in ingress_intrinsic_metadata_from_parser_t ig_intr_from_prsr,
        inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr,
        inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm) {

    action nop_() { }

    action checksum_upd_udp(bool update) {
        ig_md.checksum_upd_udp = update;
    }

    table translate {
        key = { hdr.ipv4.src_addr : exact; }
        actions = {
            nop_;
            checksum_upd_udp;
        }

        default_action = nop_;
        size = 128;
    }
# 73 "../../p4c-3892/casteni_gw.p4"
    apply {
#ifdef SPLIT_IPV4
        if (hdr.ipv4_dst.isValid())
            ipv4_hdr_merge();
#endif  /* SPLIT_IPV4 */
        translate.apply();
        ig_intr_md_for_tm.bypass_egress = 1w1;
    }
}


Pipeline(SwitchIngressParser(),
        SwitchIngress(),
        SwitchIngressDeparser(),
        EmptyEgressParser(),
        EmptyEgress(),
        EmptyEgressDeparser()) pipe;

Switch(pipe) main;
