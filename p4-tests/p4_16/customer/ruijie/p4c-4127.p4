#include <t2na.p4> // TOFINO2_ONLY

//-----------------------------------------------------------------------------
// Table sizes.
//-----------------------------------------------------------------------------

//----------------------------------- port -------------------------------------
const bit<32> PORT_TABLE_SIZE = 512;
const bit<32> STROM_CONTROL_TABLE_SIZE = 1024;

//----------------------------------- AP -------------------------------------
const bit<32> HASH_COMPUTE_TABLE_SIZE = 64;
const bit<32> HASH_MODE_TABLE_SIZE = 64;
const bit<32> LAG_TABLE_SIZE = 512;
const bit<32> MC_LAG_MAX_ENTRYS = 5120;
const bit<32> LAG_MAX_ENTRYS = 5120;

//----------------------------------- L2 -------------------------------------
const bit<32> LIF_TABLE_SIZE = 32768;
const bit<32> LIF_PROPERTIES_TABLE_SIZE = 16384;
const bit<32> BACK_LIF_TABLE_SIZE = 512;
const bit<32> EVLAN_FLOOD_TABLE_SIZE = 8192;
const bit<32> LIF_STATS_TABLE_SIZE = 65536;
const bit<32> IP_STATS_TABLE_SIZE = 10240;
//STP
const bit<32> VLAN_STG_TABLE_SIZE = 4096;
const bit<32> STP_PORT_STATE_TABLE_SIZE = 32768;
const bit<32> BACK_STP_PORT_STATE_TABLE_SIZE = 512;

// (port, vlan) <--> BD
const bit<32> PORT_VLAN_TABLE_SIZE = 1024;

// 5K BDs
const bit<32> EVLAN_TABLE_SIZE = 8192;

// 80K MACs
const bit<32> MAC_TABLE_SIZE = 90112;//81920;
const bit<32> BACK_MAC_TABLE_SIZE = 512;

const bit<32> EVLAN_ATTR_SIZE = 8192;
const bit<32> EVLAN_RMAC_SIZE = 1024;
const bit<32> L2LIF_TABLE_SIZE = 16384;
const bit<32> HORIZON_SPLIT_SIZE = 64;
const bit<32> PTAG_ENCAP_SIZE = 32;
//----------------------------------- L3 -------------------------------------
const bit<32> VALIDATION_TABLE_SIZE = 64;
const bit<32> L3IIF_TABLE_SIZE = 16384;
const bit<32> VMAC_TABLE_SIZE = 2048;
const bit<32> VMAC_BACK_TABLE_SIZE = 1024;
// IP Hosts/Routes
const bit<32> IPV4_LPM_TABLE_SIZE = 1024;
const bit<32> IPV6_LPM_TABLE_SIZE = 1024;
const bit<32> IPV4_SIP_LPM_TABLE_SIZE = 512;
const bit<32> IPV6_SIP_LPM_TABLE_SIZE = 512;
const bit<32> IPV4_HOST_TABLE_SIZE = 20480;
const bit<32> IPV6_HOST_TABLE_SIZE = 20480;
// Nexthop
const bit<32> L4_NEXTHOP_TABLE_SIZE = 65536;
const bit<32> OVERLAY_NEXTHOP_TABLE_SIZE = 65536;
const bit<32> UNDERLAY_NEXTHOP_TABLE_SIZE = 65536;
const bit<32> OVERLAY_COUNTER_TABLE_SIZE = 16384;
const bit<32> MTU_CHECK_TABLE_SIZE = 16384;

const bit<32> L2_ENCAP_TABLE_SIZE = 65536;
const bit<32> RID_ATTRIBUTE_TABLE_SIZE = 16384;
const bit<32> MULTICAST_GROUP_SIZE = 32768;
//----------------------------------- ACL -------------------------------------
// Ingress ACLs
const bit<32> INGRESS_IPV4_ACL_TABLE_SIZE = 8192;
const bit<32> INGRESS_IPV6_ACL_TABLE_SIZE = 4096;

// Egress ACLs
const bit<32> EGRESS_IPV4_ACL_TABLE_SIZE = 8192;
const bit<32> EGRESS_IPV6_ACL_TABLE_SIZE = 4096;

//----------------------------------- Tunnel -------------------------------------
const bit<32> VXLAN_TERMINATE_SIZE = 16384;
const bit<32> L4_ENCAP_TABLE_SIZE = 65536;
const bit<32> SET_SMAC_SIZE = 16384;
const bit<32> EVLAN_VNI_MAPING_SIZE = 8192;
const bit<32> GET_REWRITE_INFO_SIZE = 8192;
const bit<32> MPLS_VC_ENCAP_SIZE = 65536;
const bit<32> MPLS_TUNNEL0_TABLE_SIZE = 65536;
const bit<32> MPLS_TUNNEL1_TABLE_SIZE = 16384;
const bit<32> MPLS_TUNNEL2_TABLE_SIZE = 16384;
const bit<32> ILM_TABLE_SIZE = 32768;
const bit<32> ILM3_TABLE_SIZE = 49152;

const bit<32> L3_ENCAP_MAPPING_SIZE = 65536;
const bit<32> SRC_DST_ADDR_SIZE = 4096;//14336
const bit<32> DST_ADDR_SIZE = 13312;//14336;
const bit<32> G_DST_ADDR_SIZE = 2048;//14336;13312


//----------------------------------- qos/tm -------------------------------------

//-----------------------------------  OAM   -------------------------------------
const bit<32> PORT_IPFIX_TABLE_SIZE = 512;
const bit<32> MIRROR_LAG_TABLE_SIZE = 512;

//-----------------------------------------------------------------------------
// Table header.
//-----------------------------------------------------------------------------
# 1 "/mnt/p4c-4127/p4src/shared/headers.p4" 1
/*******************************************************************************
 * BAREFOOT NETWORKS CONFIDENTIAL & PROPRIETARY
 *
 * Copyright (c) 2015-2019 Barefoot Networks, Inc.

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
 ******************************************************************************/

//-----------------------------------------------------------------------------
// Protocol Header Definitions
//-----------------------------------------------------------------------------




typedef bit<48> mac_addr_t;
typedef bit<32> ipv4_addr_t;
typedef bit<128> ipv6_addr_t;
typedef bit<12> vlan_id_t;

@pa_no_overlay("pp_downlink", "ingress", "hdr.ethernet.src_addr")
@pa_container_size("pp_downlink", "egress", "eg_intr_md_for_dprsr.mirror_type", 16)
header ethernet_h {
    mac_addr_t dst_addr;
    mac_addr_t src_addr;
    bit<16> ether_type;
}

@pa_container_size("pp_downlink", "ingress", "hdr.vlan_tag[0].vid", 16)
@pa_container_size("pp_downlink", "ingress", "hdr.vlan_tag[1].vid", 16)
header vlan_tag_h {
    bit<3> pcp;
    bit<1> cfi;
    vlan_id_t vid;
    bit<16> ether_type;
}

@pa_no_overlay("pp_front", "egress", "hdr.br_tag.epcp")
@pa_no_overlay("pp_front", "egress", "hdr.br_tag.edei")
@pa_no_overlay("pp_front", "egress", "hdr.br_tag.ingress_ecid")
@pa_no_overlay("pp_front", "egress", "hdr.br_tag.reserved")
@pa_no_overlay("pp_front", "egress", "hdr.br_tag.grp")
@pa_no_overlay("pp_front", "egress", "hdr.br_tag.ecid")
@pa_no_overlay("pp_front", "egress", "hdr.br_tag.ingress_ecid_ext")
@pa_no_overlay("pp_front", "egress", "hdr.br_tag.ecid_ext")
@pa_no_overlay("pp_front", "egress", "hdr.br_tag.ether_type")
header br_tag_h {
    bit<3> epcp;
    bit<1> edei;
    bit<12> ingress_ecid;
    bit<2> reserved;
    bit<2> grp;
    bit<12> ecid;
    bit<8> ingress_ecid_ext;
    bit<8> ecid_ext;
    bit<16> ether_type;
}

header drop_msg_h {
    bit<16> port;
    bit<16> fqid;
    bit<32> len;
}

header pause_info_h {
    bit<16> code;
    bit<16> time;
}

// @pa_container_size("pp_downlink", "ingress", "hdr.mpls_ig.$stkvalid", 32)
// @pa_container_size("pp_downlink", "egress", "hdr.mpls_eg.$stkvalid", 32)
@pa_container_size("pp_downlink", "egress", "eg_md.qos.FQID", 16)
header mpls_h {
    bit<20> label;
    bit<3> exp;
    bit<1> bos;
    bit<8> ttl;
}

header mpls_lookahead_h {
    bit<20> label1;
    bit<3> exp1;
    bit<1> bos1;
    bit<8> ttl1;

    bit<20> label2;
    bit<3> exp2;
    bit<1> bos2;
    bit<8> ttl2;
}

header cw_h {
    bit<4> diffserv; /* 0 */
    bit<4> flags;
    bit<2> frg;
    bit<6> len;
    bit<16> seq;
}
// @pa_container_size("egress", "hdr.ipv4.$valid", 8) tf1 hdr valid in 32bit phv
//@pa_container_size("pp_downlink", "egress", "hdr.inner_ipv4.ttl", 16)
//@pa_container_size("pp_downlink", "egress", "hdr.inner_ipv4.protocol", 16)
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

// Router Alert IP option -- RFC 2113, RFC 2711
header router_alert_option_h {
    bit<8> type;
    bit<8> length;
    bit<16> value;
}

header ipv4_option_h {
    bit<8> type;
    bit<8> length;
    bit<16> value;
}

@pa_container_size("ingress", "hdr.ipv6.dst_addr", 32, 32, 32, 32)
@pa_container_size("pp_downlink", "ingress", "hdr.ipv6.src_addr", 32, 32, 32, 32)
//@pa_container_size("pp_downlink", "egress", "hdr.inner_ipv6.next_hdr", 16)
//@pa_container_size("pp_downlink", "egress", "hdr.inner_ipv6.hop_limit", 16)
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

@pa_no_overlay("pp_uplink", "egress", "hdr.ipv6_frag.next_hdr")
//@pa_no_overlay("pp_downlink", "ingress", "hdr.ipv6_frag.next_hdr")
//@pa_no_overlay("pp_downlink", "ingress", "hdr.ipv6_frag.$valid")
header ipv6_fragment_h {
    bit<8> next_hdr;
    bit<8> reserved;
    bit<13> frag_offset;
    bit<2> reserved2;
    bit<1> m_flag;
    bit<32> identification;
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

header tcp_udp_lookahead_eg_uplink_h {
    bit<16> src_port;
    bit<16> dst_port;
}

// header icmp_h {
//     bit<8> type;
//     bit<8> code;
//     bit<16> checksum;
//     // ...
// }

header icmp_h {
    bit<16> typeCode;
    bit<16> checksum;
    // ...
}

header igmp_h {
    bit<8> type;
    bit<8> code;
    bit<16> checksum;
    // ...
}

// Address Resolution Protocol -- RFC 6747
header arp_h {
    bit<16> hw_type;
    bit<16> proto_type;
    bit<8> hw_addr_len;
    bit<8> proto_addr_len;
    bit<16> opcode;
    bit<48> sender_mac;
    bit<32> sender_ip;
    bit<48> dst_mac;
    bit<32> dst_ip;
    // ...
}

// RDMA over Converged Ethernet (RoCEv2)
header rocev2_bth_h {
    bit<8> opcodee;
    bit<1> se;
    bit<1> migration_req;
    bit<2> pad_count;
    bit<4> transport_version;
    bit<16> partition_key;
    bit<1> f_res1;
    bit<1> b_res1;
    bit<6> reserved;
    bit<24> dst_qp;
    bit<1> ack_req;
    bit<7> reserved2;
    // ...
}

// Fiber Channel over Ethernet (FCoE)
header fcoe_fc_h {
    bit<4> version;
    bit<100> reserved;
    bit<8> sof; // Start of frame

    bit<8> r_ctl; // Routing control
    bit<24> d_id; // Destination identifier
    bit<8> cs_ctl; // Class specific control
    bit<24> s_id; // Source identifier
    bit<8> type;
    bit<24> f_ctl; // Frame control
    bit<8> seq_id;
    bit<8> df_ctl;
    bit<16> seq_cnt; // Sequence count
    bit<16> ox_id; // Originator exchange id
    bit<16> rx_id; // Responder exchange id
    // ...
}

// Segment Routing Extension (SRH) -- RFC 8754
header ipv6_srh_h {
    bit<8> next_hdr;
    bit<8> hdr_ext_len;
    bit<8> routing_type;
    bit<8> seg_left;
    bit<8> last_entry;
    bit<8> flags;
    bit<16> tag;
}

header srv6_list_h {
    bit<128> sid;
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

// Network Virtualisation using GRE (NVGRE) -- RFC 7637
header nvgre_h {
    bit<24> vsid;
    bit<8> flow_id;
}

// ERSPAN common header for type 2/3
header erspan_h {
    bit<16> version_vlan;
    bit<16> session_id; // include cos_en_t(6) and session_id(10)
}

// ERSPAN Type II -- IETFv3
header erspan_type2_h {
    bit<32> index; // include reserved(12) and index(20)
}

// ERSPAN Type III -- IETFv3
header erspan_type3_h {
    bit<32> timestamp;
    bit<32> ft_d_other;
    /*
    bit<16> sgt;    // Security group tag
    bit<1>  p;
    bit<5> ft;      // Frame type
    bit<6> hw_id;
    bit<1> d;       // Direction
    bit<2> gra;     // Timestamp granularity
    bit<1> o;       // Optional sub-header
    */
}

// ERSPAN platform specific subheader -- IETFv3
header erspan_platform_h {
    bit<6> id;
    bit<58> info;
}

// Generic Network Virtualization Encapsulation (Geneve)
header geneve_h {
    bit<2> version;
    bit<6> opt_len;
    bit<1> oam;
    bit<1> critical;
    bit<6> reserved;
    bit<16> proto_type;
    bit<24> vni;
    bit<8> reserved2;
}

header geneve_option_h {
    bit<16> opt_class;
    bit<8> opt_type;
    bit<3> reserved;
    bit<5> opt_len;
}

// Bidirectional Forwarding Detection (BFD) -- RFC 5880
header bfd_h {
    bit<3> version;
    bit<5> diag;
    bit<8> flags;
    bit<8> detect_multi;
    bit<8> len;
    bit<32> my_discriminator;
    bit<32> your_discriminator;
    bit<32> desired_min_tx_interval;
    bit<32> req_min_rx_interval;
    bit<32> req_min_echo_rx_interval;
}

// Telemetry report header -- version 0.5
// See https://github.com/p4lang/p4-applications/blob/master/docs/telemetry_report_v0_5.pdf
header dtel_report_v05_h {
    bit<4> version;
    bit<4> next_proto;
    bit<3> d_q_f;
    bit<15> reserved;
    bit<6> hw_id;
    bit<32> seq_number;
    bit<32> timestamp;
    bit<32> switch_id;
}

// DTel report base header
header dtel_report_base_h {
    bit<7> pad0;
    bit<9> ingress_port;
    bit<7> pad1;
    bit<9> egress_port;




    bit<1> pad2;
    bit<7> queue_id;

}

// DTel drop report header
header dtel_drop_report_h {
    bit<8> drop_reason;
    bit<16> reserved;
}

// DTel switch local report header
header dtel_switch_local_report_h {
    bit<5> pad3;
    bit<19> queue_occupancy;
    bit<32> timestamp;
}

// Telemetry report header -- version 1.0
// See https://github.com/p4lang/p4-applications/blob/master/docs/telemetry_report_v1_0.pdf
header dtel_report_v10_h {
    bit<4> version;
    bit<4> length;
    bit<3> next_proto;
    bit<6> metadata_bits;
    bit<6> reserved;
    bit<3> d_q_f;
    bit<6> hw_id;
    bit<32> switch_id;
    bit<32> seq_number;
    bit<32> timestamp;
}

// Optional metadata present in the telemetry report.
struct dtel_report_metadata_0 {
    bit<16> ingress_port;
    bit<16> egress_port;
}

struct dtel_report_metadata_2 {
    bit<8> queue_id;
    bit<24> queue_occupancy;
}

struct dtel_report_metadata_3 {
    bit<32> timestamp;
}

struct dtel_report_metadata_4 {
    bit<8> queue_id;
    bit<8> drop_reason;
    bit<16> reserved;
}

header timestamp_h {
    bit<48> timestamp;
}

header fabric_base_lookahead_h {
    bit<6> pkt_type; // switch_pkt_type
    bit<1> is_mirror;
    bit<1> is_mcast;
}

header fabric_base_h {
    bit<6> pkt_type; // switch_pkt_type
    bit<1> is_mirror;
    bit<1> is_mcast;
}

header fabric_qos_h {
    bit<3> tc; // qos.tc
    bit<2> color; // qos.color
    bit<1> chgDSCP_disable; // qos.chgDSCP_disable
    bit<1> BA; // qos.BA
    bit<1> track;
}

@pa_container_size("pp_uplink", "egress", "hdr.fabric_unicast_ext_bfn_igfpga.cpu_reason", 16)
@pa_container_size("pp_uplink", "egress", "hdr.fabric_unicast_ext_bfn_igfpga.nexthop", 16)
header fabric_unicast_ext_bfn_igfpga_h {
    bit<8> flags;
    // bit<1> extend;
    // bit<1> fwd_fail;
    // bit<1> is_ecmp;       
    // bit<1> disable_urpf;    
    // bit<1> glean;
    // bit<1> drop;
    // bit<1> escape_etm;
    // bit<1> svi_flag;

    bit<8> nh_option;
    // bit<3> ext_len;
    // bit<3> service_class;
    // bit<2> nh_level;

    bit<8> cpu_reason;
    bit<8> src_port;
    bit<16> nexthop;
    bit<16> hash;
}

header fabric_unicast_ext_igfpga_bfn_h {
    bit<1> extend;
    bit<1> fwd_fail;
    @padding bit<2> pad;
    bit<1> glean;
    bit<1> drop;
    bit<1> escape_etm;
    bit<1> svi_flag;

    bit<8> var_byte;
    // for ip : fwd_fail_reason  
    // for mpls : php_copy[0:0],opcode[3:0],pad[2:0] 

    // moved to fabric_crsp_h
    // bit<8> cpu_reason;
    // bit<8> src_port;
    // moved to fabric_nexthop_h
    // bit<16> ul_nhid;
    // bit<16> ol_nhid;
}

header fabric_crsp_h {
    bit<8> cpu_reason;
    bit<8> src_port;
}

header fabric_nexthop_h {
    bit<16> ul_nhid;
    bit<16> ol_nhid;
}

header fabric_unicast_dst_encap_h {
    bit<8> flags;
    // bit<1> extend;
    // bit<1> escape_etm;
    // bit<1> is_gleaned;
    // bit<1> flowspec_disable;
    // @padding bit<4> pad;
    bit<8> dst_port;
}

header fabric_unicast_dst_h {
    bit<1> extend;
    bit<7> dst_device;
    bit<8> dst_port;
}

header fabric_unicast_ext_fe_encap_h {
    bit<16> l2_encap;
    bit<16> l3_encap;
    bit<16> hash;
}

header fabric_unicast_ext_fe_h {
    bit<16> l2_encap;
    bit<16> l3_encap;
    bit<16> hash;
}

// for compile error in tofino2
@pa_container_size("pp_fabric", "egress", "hdr.fabric_unicast_ext_fe_2_encap.src_device", 8)
@pa_container_size("pp_fabric", "egress", "hdr.fabric_unicast_ext_fe_2_encap.flags", 8)
@pa_container_size("pp_fabric", "ingress", "hdr.fabric_multicast_src.extend", 8)
@pa_container_size("pp_fabric", "ingress", "hdr.fabric_multicast_src.src_device", 8)
header fabric_unicast_ext_fe_2_encap_h {
    bit<1> pad1;
    bit<7> src_device;
    bit<8> flags;
    // bit<1> is_elephant;
    // bit<1> escape_etm;
    // bit<1> pad2;
    // bit<1> is_gleaned;
    // bit<4> pad3;
}

header fabric_unicast_ext_fe_2_h {
    bit<1> pad1;
    bit<7> src_device;
    bit<1> is_elephant;
    bit<1> escape_etm;
    bit<1> pad2;
    bit<1> is_gleaned;
    bit<4> pad3;
}

//@pa_no_overlay("pp_fabric", "egress", "hdr.fabric_multicast_src.extend")
//@pa_no_overlay("pp_fabric", "egress", "hdr.fabric_multicast_src.src_device")
@pa_no_overlay("pp_fabric", "ingress", "hdr.fabric_multicast_src.extend")
@pa_no_overlay("pp_fabric", "ingress", "hdr.fabric_multicast_src.src_device")
@pa_container_size("pp_fabric", "ingress", "hdr.fabric_multicast_src.extend", 8)
@pa_container_size("pp_fabric", "ingress", "hdr.fabric_multicast_src.src_device", 8)
header fabric_multicast_src_h {
    bit<1> extend;
    bit<7> src_device;
    bit<8> src_port;
}

header fabric_multicast_src_encap_h {
    bit<16> data;
    // bit<1> extend;
    // bit<7> src_device;
    // bit<8> src_port;
}

header fabric_multicast_ext_h {
    @padding bit<11> pad1;
    bit<1> is_gleaned;
    @padding bit<4> pad;
    bit<16> mgid;
    bit<16> hash;
    bit<16> evlan;
}

header fabric_unicast_ext_eg_encap_h {
    bit<16> combine;
    // switch_next_hdr_type_t next_hdr_type;
    // bit<3> pcp;
    // @padding bit<3> pad;
    // bit<8> dst_port;
    bit<16> l2_encap;
    bit<16> ptag_igmod_oif;
    // bit<1> extend_fake;
    // bit<1> ptag_igmod;
    // bit<14> oif;    
    bit<16> pkt_len;
    bit<16> FQID;
}

header fabric_unicast_ext_eg_h {
    // bit<8> flags;
    bit<2> next_hdr_type;
    bit<3> pcp;
    @padding bit<3> pad;
    bit<8> dst_port;
    bit<16> l2_encap;
    bit<1> extend_fake;
    bit<1> ptag_igmod;
    bit<14> oif;
    bit<16> pkt_len;
    bit<16> FQID;
}

header fabric_var_ext_1_16bit_h {
    bit<16> data;
}

@pa_container_size("pp_uplink", "egress", "hdr.fabric_var_ext_2_8bit.data_lo", 16)
header fabric_var_ext_2_8bit_h {
    bit<8> data_hi;
    bit<8> data_lo;
}

header fabric_one_pad_h {
    bit<1> one;
    @padding bit<1> pad;
    bit<14> iif;
}

header fabric_one_pad_3_h {
    bit<2> one;
    bit<14> iif;
}

header fabric_one_pad_7_h {
    bit<2> one;
    bit<14> iif;
}

header pcie_one_pad_h {
    bit<2> one;
    bit<14> iif;
}

header fabric_post_one_pad_h {
    bit<1> l2_flag;
    @padding bit<1> pad;
    bit<14> l2oif;
}

@pa_container_size("pp_uplink", "ingress", "hdr.fabric_eth_ext.l2oif", 16)
header fabric_eth_ext_h {
    bit<16> evlan;
    bit<1> l2_flag;
    @padding bit<1> pad;
    bit<14> l2oif;
}

header fabric_eth_ext_encap_h {
    bit<16> evlan;
    bit<16> data;
    // bit<1> l2_flag;
    // @padding bit<1> pad;
    // bit<14> l2oif;
}

header fabric_cpu_pcie_base_h {
    bit<6> cpu_pkt_type;
    bit<2> fwd_mode;
    bit<5> qid;
    @padding bit<2> pad_qos;
    //bit<2> pad_qos;
    bit<1> track;
}
// for compile error in tofino2 9.5.1 pre
@pa_container_size("pp_fabric", "egress", "hdr.fabric_to_cpu_data.sec_acl_drop", 8)
@pa_container_size("pp_fabric", "egress", "hdr.fabric_to_cpu_data.cpu_reason", 8)
header fabric_to_cpu_data_h {
    bit<1> sec_acl_drop;
    @padding bit<7> pad1;
    bit<8> cpu_reason;
    bit<16> cpu_code;
    @padding bit<16> pad;
    bit<16> evlan;
}

header fabric_from_cpu_data_h {
    @padding bit<32> pad;
    @padding bit<2> pad_2;
    bit<14> oif;
    bit<16> evlan;
}

header fabric_payload_h {
    bit<16> ether_type;
}

header advance_pad112_h {
    bit<48> f1;
    bit<48> f2;
    bit<16> f3;
}

header advance_pad64_h {
    bit<32> f1;
    bit<32> f2;
}

/* by yeweixin */
// header fabric_eth_base_to_cpu_h {
//     bit<6> pkt_type;
//     bit<1> dir;
//     bit<1> sample_flag;
//     @padding bit<3> pad1;
//     bit<5> qid;
// }

// header fabric_eth_base_to_cpu_encap_h {
//     bit<16> data;
//     // bit<6> pkt_type;
//     // bit<1> dir;
//     // bit<1> sample_flag;
//     // @padding bit<3> pad1;
//     // bit<5> qid;    
// }

// header fabric_ipfix_to_cpu_h {
//     @padding bit<2> pad2;
//     bit<14> iif;
//     @padding bit<2> pad3;
//     bit<14> oif;
//     bit<16> cpu_code;
//     bit<16> hash;
// }

// header fabric_trap_to_cpu_eth_h {
//     @padding bit<2> pad_lif;
//     bit<14> iif_oif;
//     bit<8> data_1;
//     bit<8> data_2;
// }

// header fabric_eth_from_cpu_base_h {
//     bit<6> pkt_type;
//     bit<2> fwd_mode;
//     @padding bit<3> pad1;
//     bit<5> qid;
// }

// header fabric_eth_from_cpu_data_h {
//     bit<8> reserved;
//     bit<8> dst_port;
//     bit<16> dst_eport;
//     bit<16> hash;
//     @padding bit<2> pad_iif;
//     bit<14> iif;
// }

header fabric_to_cpu_eth_base_h {
    bit<6> pkt_type;
    bit<1> dir;
    @padding bit<9> pad1;
}

header fabric_to_cpu_eth_data_h {
    bit<16> var_h1;
    // bit<1> extend;
    // @padding bit<1> pad_iif;
    // bit<14> iif;
    bit<16> var_h2;
    // @padding bit<2> pad_oif;
    // bit<14> oif;
    bit<16> var_h3; // hash | trace_counter | cpu_code
    bit<16> var_h4;
    // bit<8> var_8bit_1;          // cpu_reason | drop_reason | sip_flow_classid
    // bit<8> var_8bit_2;          // src_port | pipeline_location | dip_flow_classid
    bit<16> reserved;
}

header fabric_from_cpu_eth_base_h {
    bit<6> pkt_type;
    bit<2> fwd_mode;
    bit<5> qid;
    bit<1> escape_etm;
    @padding bit<1> pad;
    bit<1> track;
}

header fabric_from_cpu_eth_data_h {
    bit<8> dst_port;
    bit<8> src_port;
    bit<16> dst_eport;
    bit<16> src_eport;
    bit<16> hash;
    @padding bit<2> pad_iif;
    bit<14> iif;
}

header fabric_from_cpu_eth_ccm_h {
    @padding bit<7> pipeline_location;
    bit<9> dev_port;
}

header fabric_whole_h {
    bit<112> data;
    bit<16> fabric_unicast_ext_fe_2_encap;
}

header fabric_learning_h {
    bit<48> mac;
}
# 180 "/mnt/p4c-4127/p4src/switch-tofino2/switch_tofino_x1.p4" 2
# 1 "/mnt/p4c-4127/p4src/shared/types.p4" 1
/*******************************************************************************
 * BAREFOOT NETWORKS CONFIDENTIAL & PROPRIETARY
 *
 * Copyright (c) 2015-2019 Barefoot Networks, Inc.

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
 ******************************************************************************/




// ----------------------------------------------------------------------------
// Common protocols/types
//-----------------------------------------------------------------------------
# 42 "/mnt/p4c-4127/p4src/shared/types.p4"
//#define ETHERTYPE_QINQ 0x88A8 // Note: uncomment once ptf/scapy-vxlan are fixed



/* ipv6 option */
# 100 "/mnt/p4c-4127/p4src/shared/types.p4"
// ----------------------------------------------------------------------------
// Common types
//-----------------------------------------------------------------------------
typedef bit<32> switch_uint32_t;
typedef bit<16> switch_uint16_t;
typedef bit<8> switch_uint8_t;

typedef bit<7> switch_device_t;
typedef bit<8> switch_logic_port_t;

typedef PortId_t switch_port_t;
const switch_port_t SWITCH_PORT_INVALID = 9w0x1ff;

const switch_port_t SWITCH_PORT_FRONT_RECIRC = 9w0x1;

typedef QueueId_t switch_qid_t;
const switch_qid_t SWITCH_QID_CPU_TO_CPU = 7;

typedef ReplicationId_t switch_rid_t;
const switch_rid_t SWITCH_RID_DEFAULT = 0xffff;

typedef bit<3> switch_ingress_cos_t;

typedef bit<3> switch_digest_type_t;
const switch_digest_type_t SWITCH_DIGEST_TYPE_INVALID = 0;
const switch_digest_type_t SWITCH_DIGEST_TYPE_MAC_LEARNING = 1;

typedef bit<16> switch_eport_t;
typedef bit<16> switch_eport_label_t;
typedef bit<14> switch_lif_t;
const switch_lif_t SWITCH_FLOOD = 0x3fff;

typedef bit<16> switch_evlan_t;
const switch_evlan_t SWITCH_EVLAN_DEFAULT_VRF = 4097; // evlan allocated for default vrf




typedef bit<14> switch_vrf_t;




typedef bit<16> switch_nexthop_t;
typedef bit<16> switch_outer_nexthop_t;

typedef bit<16> switch_xid_t;
typedef bit<9> switch_yid_t;

typedef bit<16> switch_evlan_classid_t;

typedef bit<16> switch_mtu_t;

typedef bit<8> switch_cpu_reason_t;
const bit<8> SWITCH_CPU_REASON_MTU = 1;
const bit<8> SWITCH_CPU_REASON_V4UC_ROUTE = 2;
const bit<8> SWITCH_CPU_REASON_V6UC_ROUTE = 3;
const bit<8> SWITCH_CPU_REASON_UNKNOWN_V4MC = 4;
const bit<8> SWITCH_CPU_REASON_UNKNOWN_V6MC = 5;
const bit<8> SWITCH_CPU_REASON_C2C = 6;
const bit<8> SWITCH_CPU_REASON_BFD_V4 = 7;
const bit<8> SWITCH_CPU_REASON_BFD_V6 = 8;
const bit<8> SWITCH_CPU_REASON_SBFD_V4 = 9;
const bit<8> SWITCH_CPU_REASON_SBFD_V6 = 10;
const bit<8> SWITCH_CPU_REASON_SBFD_MPLS_V4 = 11;
const bit<8> SWITCH_CPU_REASON_SBFD_MPLS_V6 = 12;
const bit<8> SWITCH_CPU_REASON_IPFIX_SEPC_V4 = 13;
const bit<8> SWITCH_CPU_REASON_IPFIX_SEPC_V6 = 14;

typedef bit<16> switch_hash_t;

typedef bit<8> switch_hash_mode_t;

struct switch_cpu_port_value_set_t {
    bit<16> ether_type;
    bit<9> port;
}

typedef bit<3> switch_pkt_src_t;
const switch_pkt_src_t SWITCH_PKT_SRC_BRIDGED = 0;
const switch_pkt_src_t SWITCH_PKT_SRC_CLONED_INGRESS = 1;
const switch_pkt_src_t SWITCH_PKT_SRC_CLONED_EGRESS = 2;
const switch_pkt_src_t SWITCH_PKT_SRC_DEFLECTED = 3;

typedef bit<5> switch_bridge_type_t;
const switch_bridge_type_t BRIDGE_TYPE_DEFAULT = 0; // DEFAULT
const switch_bridge_type_t BRIDGE_TYPE_FRONT_UPLINK = 0; // front_uplink
const switch_bridge_type_t BRIDGE_TYPE_UPLINK_FABRIC = 1; // uplink-fabric
const switch_bridge_type_t BRIDGE_TYPE_UPLINK_FRONT = 2; // uplink-front
const switch_bridge_type_t BRIDGE_TYPE_FABRIC_DOWNLINK = 3; // fabric-downlink
const switch_bridge_type_t BRIDGE_TYPE_FABRIC_FABRIC = 4; // fabric-pcie, pcie-fabric
const switch_bridge_type_t BRIDGE_TYPE_DOWNLINK_FRONT = 5; // downlink-front
const switch_bridge_type_t BRIDGE_TYPE_FRONT_UPLINK_RECIRC = 6; // uplink-recirc
const switch_bridge_type_t BRIDGE_TYPE_FPGA_DROP = 7; // for fpga drop_msg
const switch_bridge_type_t BRIDGE_TYPE_QOS_RECIRC = 8; // for qos recirc
const switch_bridge_type_t BRIDGE_TYPE_FPGA_PAUSE = 9; // for fpga pause
const switch_bridge_type_t BRIDGE_TYPE_FRONT_FRONT = 10; // front_front
const switch_bridge_type_t BRIDGE_TYPE_FABRIC_FRONT = 11; // fabric_front

typedef bit<6> switch_pkt_type_t;
const switch_pkt_type_t FABRIC_PKT_TYPE_ETH = 0; // ETH, L2VPN, VXLAN L2
const switch_pkt_type_t FABRIC_PKT_TYPE_IPV4 = 1; // IPV4, L3VPN IPV4
const switch_pkt_type_t FABRIC_PKT_TYPE_MPLS = 2; // LSR
const switch_pkt_type_t FABRIC_PKT_TYPE_IPV6 = 3; // IPV6, L3VPN IPV6
const switch_pkt_type_t FABRIC_PKT_TYPE_RESERVED = 4; // reserved
const switch_pkt_type_t FABRIC_PKT_TYPE_RESERVED1 = 5; // reserved1
const switch_pkt_type_t FABRIC_PKT_TYPE_RESERVED2 = 6; // reserved2
const switch_pkt_type_t FABRIC_PKT_TYPE_FPGA_DROP = 7;
const switch_pkt_type_t FABRIC_PKT_TYPE_FPGA_PAUSE = 8;
const switch_pkt_type_t FABRIC_PKT_TYPE_IPFIX_SPEC_V4 = 9;
const switch_pkt_type_t FABRIC_PKT_TYPE_IPFIX_SPEC_V6 = 10;
const switch_pkt_type_t FABRIC_PKT_TYPE_CCM = 11; // CCM
const switch_pkt_type_t FABRIC_PKT_TYPE_BLACK_HOLE = 12; // cpu 0x33 blackhole
const switch_pkt_type_t FABRIC_PKT_TYPE_FE_TRACE = 13;
const switch_pkt_type_t FABRIC_PKT_TYPE_CPU_ETH = 14;
const switch_pkt_type_t FABRIC_PKT_TYPE_CPU_PCIE = 15;
const switch_pkt_type_t FABRIC_PKT_TYPE_EOP = 16;
const switch_pkt_type_t FABRIC_PKT_TYPE_LEARNING = 17;

typedef bit<3> switch_fabric_ext_type_t;
const switch_fabric_ext_type_t FABRIC_EXT_TYPE_TUNNEL_DECAP = 0;
const switch_fabric_ext_type_t FABRIC_EXT_TYPE_L4_ENCAP = 1;
const switch_fabric_ext_type_t FABRIC_EXT_TYPE_L4_NHOP = 2;

typedef bit<2> switch_ext_data_type_t;
const switch_ext_data_type_t SWITCH_TUNNEL_DECAP_TYPE_TUNNEL = 0;
const switch_ext_data_type_t SWITCH_TUNNEL_DECAP_TYPE_OR = 1;

typedef bit<3> switch_bridged_metadata_ext_type_t;
const switch_bridged_metadata_ext_type_t BRIDGED_MD_EXT_TYPE_TUNNEL_DECAP = 0;
const switch_bridged_metadata_ext_type_t BRIDGED_MD_EXT_TYPE_L4_ENCAP = 1;
const switch_bridged_metadata_ext_type_t BRIDGED_MD_EXT_TYPE_SRV6 = 2;
const switch_bridged_metadata_ext_type_t BRIDGED_MD_EXT_TYPE_PADDING_WORD = 3;

typedef bit<2> switch_next_hdr_type_t;
const switch_next_hdr_type_t SWITCH_TUNNEL_NEXT_HDR_TYPE_NONE = 0;
const switch_next_hdr_type_t SWITCH_TUNNEL_NEXT_HDR_TYPE_MPLS = 1;
const switch_next_hdr_type_t SWITCH_TUNNEL_NEXT_HDR_TYPE_IPV4 = 2;
const switch_next_hdr_type_t SWITCH_TUNNEL_NEXT_HDR_TYPE_IPV6 = 3;

typedef bit<3> switch_mpls_vc_encap_opcode_t;
const switch_mpls_vc_encap_opcode_t SWITCH_MPLS_VC_ENCAP_OPCODE_ACTION_MISS = 0;
const switch_mpls_vc_encap_opcode_t SWITCH_MPLS_VC_ENCAP_OPCODE_PUSH_L2 = 1;
const switch_mpls_vc_encap_opcode_t SWITCH_MPLS_VC_ENCAP_OPCODE_PUSH_VC = 2;
const switch_mpls_vc_encap_opcode_t SWITCH_MPLS_VC_ENCAP_OPCODE_SWAP = 3;
const switch_mpls_vc_encap_opcode_t SWITCH_MPLS_VC_ENCAP_OPCODE_SWAP_SELF = 4;

typedef bit<2> switch_mpls_encap0_opcode_t;
const switch_mpls_encap0_opcode_t SWITCH_MPLS_ENCAP0_OPCODE_ACTION_MISS = 0;
const switch_mpls_encap0_opcode_t SWITCH_MPLS_ENCAP0_OPCODE_PUSH = 1;
const switch_mpls_encap0_opcode_t SWITCH_MPLS_ENCAP0_OPCODE_SWAP = 2;
const switch_mpls_encap0_opcode_t SWITCH_MPLS_ENCAP0_OPCODE_SWAP_SELF = 3;

typedef bit<6> switch_cpu_pcie_pkt_type_t;
const switch_cpu_pcie_pkt_type_t CPU_PCIE_PKT_TYPE_CPU_TO_CPU = 0;
const switch_cpu_pcie_pkt_type_t CPU_PCIE_PKT_TYPE_CPU_UC = 1;
const switch_cpu_pcie_pkt_type_t CPU_PCIE_PKT_TYPE_CPU_MC = 2;

typedef bit<2> switch_fwd_mode_t;
const switch_fwd_mode_t FWD_MODE_HW_FWDD = 0;
const switch_fwd_mode_t FWD_MODE_LOCAL = 1;
const switch_fwd_mode_t FWD_MODE_REMOTE = 2;
const switch_fwd_mode_t FWD_MODE_HOP = 3;

typedef bit<6> switch_cpu_eth_encap_id_t;
const switch_cpu_eth_encap_id_t CPU_ETH_ENCAP_INVALID = 0;
const switch_cpu_eth_encap_id_t CPU_ETH_ENCAP_BFD_ETH = 1;
const switch_cpu_eth_encap_id_t CPU_ETH_ENCAP_BFD_IPV4 = 2;
const switch_cpu_eth_encap_id_t CPU_ETH_ENCAP_BFD_IPV6 = 3;
const switch_cpu_eth_encap_id_t CPU_ETH_ENCAP_IPFIX_IG = 4;
const switch_cpu_eth_encap_id_t CPU_ETH_ENCAP_IPFIX_EG = 5;
const switch_cpu_eth_encap_id_t CPU_ETH_ENCAP_IPFIX_SPEC_V4 = 6;
const switch_cpu_eth_encap_id_t CPU_ETH_ENCAP_IPFIX_SPEC_V6 = 7;
const switch_cpu_eth_encap_id_t CPU_ETH_ENCAP_PIPELINE_TRACE = 8;
const switch_cpu_eth_encap_id_t CPU_ETH_ENCAP_PCAP = 9;
const switch_cpu_eth_encap_id_t CPU_ETH_ENCAP_XOFF = 10;
const switch_cpu_eth_encap_id_t CPU_ETH_ENCAP_CCM = 11;
const switch_cpu_eth_encap_id_t CPU_ETH_ENCAP_XON = 12;

typedef bit<2> switch_lkp_pkt_type_t;
const switch_lkp_pkt_type_t FABRIC_PKT_TYPE_UNICAST = 0x01;
const switch_lkp_pkt_type_t FABRIC_PKT_TYPE_MCAST = 0x02;
const switch_lkp_pkt_type_t FABRIC_PKT_TYPE_BROADCAST = 0x03;


typedef bit<8> switch_drop_reason_t;
const switch_drop_reason_t SWITCH_DROP_REASON_UNKNOWN = 0;
const switch_drop_reason_t SWITCH_DROP_REASON_FORWARD = 1;
const switch_drop_reason_t SWITCH_DROP_REASON_PREV_DROP = 2;
const switch_drop_reason_t SWITCH_DROP_REASON_OUTER_SRC_MAC_ZERO = 10;
const switch_drop_reason_t SWITCH_DROP_REASON_OUTER_SRC_MAC_MULTICAST = 11;
const switch_drop_reason_t SWITCH_DROP_REASON_OUTER_DST_MAC_ZERO = 12;
const switch_drop_reason_t SWITCH_DROP_REASON_OUTER_ETHERNET_MISS = 13;
const switch_drop_reason_t SWITCH_DROP_REASON_SRC_MAC_ZERO = 14;
const switch_drop_reason_t SWITCH_DROP_REASON_SRC_MAC_MULTICAST = 15;
const switch_drop_reason_t SWITCH_DROP_REASON_DST_MAC_ZERO = 16;
const switch_drop_reason_t SWITCH_DROP_REASON_OUTER_IP_VERSION_INVALID = 25;
const switch_drop_reason_t SWITCH_DROP_REASON_OUTER_IP_TTL_ZERO = 26;
const switch_drop_reason_t SWITCH_DROP_REASON_OUTER_IP_SRC_MULTICAST = 27;
const switch_drop_reason_t SWITCH_DROP_REASON_OUTER_IP_SRC_LOOPBACK = 28;
const switch_drop_reason_t SWITCH_DROP_REASON_OUTER_IP_MISS = 29;
const switch_drop_reason_t SWITCH_DROP_REASON_OUTER_IP_IHL_INVALID = 30;
const switch_drop_reason_t SWITCH_DROP_REASON_OUTER_IP_INVALID_CHECKSUM = 31;
const switch_drop_reason_t SWITCH_DROP_REASON_IP_VERSION_INVALID = 40;
const switch_drop_reason_t SWITCH_DROP_REASON_IP_TTL_ZERO = 41;
const switch_drop_reason_t SWITCH_DROP_REASON_IP_SRC_MULTICAST = 42;
const switch_drop_reason_t SWITCH_DROP_REASON_IP_SRC_LOOPBACK = 43;
const switch_drop_reason_t SWITCH_DROP_REASON_IP_IHL_INVALID = 44;
const switch_drop_reason_t SWITCH_DROP_REASON_IP_INVALID_CHECKSUM = 45;
const switch_drop_reason_t SWITCH_DROP_REASON_PORT_VLAN_MAPPING_MISS = 55;
const switch_drop_reason_t SWITCH_DROP_REASON_STP_STATE_LEARNING = 56;
const switch_drop_reason_t SWITCH_DROP_REASON_STP_STATE_BLOCKING = 57;
const switch_drop_reason_t SWITCH_DROP_REASON_SAME_IFINDEX = 58;
const switch_drop_reason_t SWITCH_DROP_REASON_MULTICAST_SNOOPING_ENABLED = 59;
const switch_drop_reason_t SWITCH_DROP_REASON_MTU_CHECK_FAIL = 70;
const switch_drop_reason_t SWITCH_DROP_REASON_TRAFFIC_MANAGER = 71;
const switch_drop_reason_t SWITCH_DROP_REASON_STORM_CONTROL = 72;
const switch_drop_reason_t SWITCH_DROP_REASON_WRED = 73;
const switch_drop_reason_t SWITCH_DROP_REASON_INGRESS_PORT_METER = 75;
const switch_drop_reason_t SWITCH_DROP_REASON_INGRESS_ACL_METER = 76;
const switch_drop_reason_t SWITCH_DROP_REASON_EGRESS_PORT_METER = 77;
const switch_drop_reason_t SWITCH_DROP_REASON_EGRESS_ACL_METER = 78;
const switch_drop_reason_t SWITCH_DROP_REASON_ACL_DENY = 80;
const switch_drop_reason_t SWITCH_DROP_REASON_RACL_DENY = 81;
const switch_drop_reason_t SWITCH_DROP_REASON_URPF_CHECK_FAIL = 82;
const switch_drop_reason_t SWITCH_DROP_REASON_IPSG_MISS = 83;
const switch_drop_reason_t SWITCH_DROP_REASON_IFINDEX = 84;
const switch_drop_reason_t SWITCH_DROP_REASON_CPU_COLOR_YELLOW = 85;
const switch_drop_reason_t SWITCH_DROP_REASON_CPU_COLOR_RED = 86;
const switch_drop_reason_t SWITCH_DROP_REASON_STORM_CONTROL_COLOR_YELLOW = 87;
const switch_drop_reason_t SWITCH_DROP_REASON_STORM_CONTROL_COLOR_RED = 88;
const switch_drop_reason_t SWITCH_DROP_REASON_L2_MISS_UNICAST = 89;
const switch_drop_reason_t SWITCH_DROP_REASON_L2_MISS_MULTICAST = 90;
const switch_drop_reason_t SWITCH_DROP_REASON_L2_MISS_BROADCAST = 91;
const switch_drop_reason_t SWITCH_DROP_REASON_EGRESS_ACL_DENY = 92;
const switch_drop_reason_t SWITCH_DROP_REASON_NEXTHOP = 93;
const switch_drop_reason_t SWITCH_DROP_REASON_NON_IP_ROUTER_MAC = 94;
const switch_drop_reason_t SWITCH_DROP_REASON_MLAG_MEMBER = 95;
const switch_drop_reason_t SWITCH_DROP_REASON_L3_IPV4_DISABLE = 99;
const switch_drop_reason_t SWITCH_DROP_REASON_L3_IPV6_DISABLE = 100;
const switch_drop_reason_t SWITCH_DROP_REASON_INGRESS_PFC_WD_DROP = 101;
const switch_drop_reason_t SWITCH_DROP_REASON_EGRESS_PFC_WD_DROP = 102;

/* by lichunfeng */
const switch_drop_reason_t SWITCH_DROP_REASON_MPLS_TERMINATE_ERROR = 103;
const switch_drop_reason_t SWITCH_DROP_REASON_MPLS_POP_ERROR = 104;
const switch_drop_reason_t SWITCH_DROP_REASON_MPLS_TTL_ZERO = 105;

/* wjg */
const switch_drop_reason_t SWITCH_DROP_REASON_SRV6_OAM = 106;
const switch_drop_reason_t SWITCH_DROP_REASON_SRV6_ERROR = 107;


const switch_drop_reason_t SWITCH_DROP_REASON_IPV4_UNICAST_DISABLE = 108;
const switch_drop_reason_t SWITCH_DROP_REASON_IP_MC_CHECK_FAIL = 109;
const switch_drop_reason_t SWITCH_DROP_REASON_IP_DST_ZERO = 110;
const switch_drop_reason_t SWITCH_DROP_REASON_IP_DST_LOOPBACK = 111;
const switch_drop_reason_t SWITCH_DROP_REASON_IP_SRC_E_ADDR = 112;
const switch_drop_reason_t SWITCH_DROP_REASON_IP_SRC_BROADCAST = 113;
const switch_drop_reason_t SWITCH_DROP_REASON_IPV4_FIB_MISS = 114;
const switch_drop_reason_t SWITCH_DROP_REASON_IPV4_NEXTHOP_MISS = 115;
const switch_drop_reason_t SWITCH_DROP_REASON_MC_TTL_FAIL = 116;
const switch_drop_reason_t SWITCH_DROP_REASON_L3_NO_IP = 117;
const switch_drop_reason_t SWITCH_DROP_REASON_IPV4_MULITCSAT_DISABLE = 118;
const switch_drop_reason_t SWITCH_DROP_REASON_RMAC_NOT_HIT = 119;

/* lvlianlin */
const switch_drop_reason_t SWITCH_DROP_REASON_LAG_MISS = 120;
const switch_drop_reason_t SWITCH_DROP_REASON_MPLS_DISABLE = 121;
const switch_drop_reason_t SWITCH_DROP_REASON_INGRESS_LIF_METER = 122;
const switch_drop_reason_t SWITCH_DROP_REASON_EGRESS_LIF_METER = 123;
const switch_drop_reason_t SWITCH_DROP_REASON_HORIZON_SPLIT = 124;
const switch_drop_reason_t SWITCH_DROP_REASON_QINQ = 125;
const switch_drop_reason_t SWITCH_DROP_REASON_FLOWSPEC_DROP = 126;
const switch_drop_reason_t SWITCH_DROP_REASON_FLOWSPEC_COLOR = 127;
const switch_drop_reason_t SWITCH_DROP_REASON_DST_PORT_INVALID = 128;
const switch_drop_reason_t SWITCH_DROP_REASON_STATIC_MAC_MOVE_PKT_DROP = 129;
const switch_drop_reason_t SWITCH_DROP_REASON_INGRESS_QPPB_METER = 130;
const switch_drop_reason_t SWITCH_DROP_REASON_EGRESS_QPPB_METER = 131;
const switch_drop_reason_t SWITCH_DROP_REASON_BLACK_HOLE_DMAC_HIT = 132;
const switch_drop_reason_t SWITCH_DROP_REASON_ETYPE_ZERO = 133;

const switch_drop_reason_t SWITCH_DROP_REASON_IPV6_UNICAST_DISABLE = 134;
const switch_drop_reason_t SWITCH_DROP_REASON_IPV6_MULITCSAT_DISABLE = 135;
const switch_drop_reason_t SWITCH_DROP_REASON_IPV6_FIB_MISS = 136;
const switch_drop_reason_t SWITCH_DROP_REASON_IPV6_NEXTHOP_MISS = 137;

/* by jiangminda */
const switch_drop_reason_t SWITCH_DROP_REASON_ETH_ULNH_ZERO = 140;
const switch_drop_reason_t SWITCH_DROP_REASON_MPLS_ULNH_ZERO = 141;
const switch_drop_reason_t SWITCH_DROP_REASON_ETH_ULNH_MISS = 142;
const switch_drop_reason_t SWITCH_DROP_REASON_MPLS_ULNH_MISS = 143;

/* by liyuhang */
const switch_drop_reason_t SWITCH_DROP_REASON_IG_VLAN_MEMBER_MISS = 144;
const switch_drop_reason_t SWITCH_DROP_REASON_EG_VLAN_MEMBER_MISS = 145;
const switch_drop_reason_t SWITCH_DROP_REASON_IG_MAC_ACL_DENY = 146;
const switch_drop_reason_t SWITCH_DROP_REASON_EG_MAC_ACL_DENY = 147;
const switch_drop_reason_t SWITCH_DROP_REASON_SMAC_MISS_UNFWD = 148;
/* CPP drop reason, by lvlianlin */
typedef bit<3> switch_cpp_drop_reason_t;
const switch_cpp_drop_reason_t SWITCH_DROP_REASON_BLACK_LIST = 1;
const switch_cpp_drop_reason_t SWITCH_DROP_REASON_HOST_ACL = 2;
const switch_cpp_drop_reason_t SWITCH_DROP_REASON_TYPE_METER = 3;
const switch_cpp_drop_reason_t SWITCH_DROP_REASON_QID_METER = 4;
const switch_cpp_drop_reason_t SWITCH_DROP_REASON_PORT_METER = 5;

typedef bit<4> switch_port_type_t;
const switch_port_type_t PORT_TYPE_UNUSED = 0;
const switch_port_type_t PORT_TYPE_FRONT = 1;
const switch_port_type_t PORT_TYPE_FPGA_UPWARD = 2;
const switch_port_type_t PORT_TYPE_FPGA_DOWN = 3;
const switch_port_type_t PORT_TYPE_CPU_ETH = 4;
const switch_port_type_t PORT_TYPE_CPU_PCIE = 5;
const switch_port_type_t PORT_TYPE_FABRIC = 6;
const switch_port_type_t PORT_TYPE_RECIRC = 7;
const switch_port_type_t PORT_TYPE_QOS_RECIRC = 8;

typedef bit<2> switch_ip_type_t;
const switch_ip_type_t SWITCH_IP_TYPE_NONE = 0;
const switch_ip_type_t SWITCH_IP_TYPE_IPV4 = 1;
const switch_ip_type_t SWITCH_IP_TYPE_IPV6 = 2;

typedef bit<2> switch_ip_frag_t;
const switch_ip_frag_t SWITCH_IP_FRAG_NON_FRAG = 0b00; // Not fragmented.
const switch_ip_frag_t SWITCH_IP_FRAG_HEAD = 0b10; // First fragment of the fragmented packets.
const switch_ip_frag_t SWITCH_IP_FRAG_NON_HEAD = 0b11; // Fragment with non-zero offset.

// Bypass flags ---------------------------------------------------------------
typedef bit<16> switch_ingress_bypass_t;
const switch_ingress_bypass_t SWITCH_INGRESS_BYPASS_L2 = 16w0x0001;
const switch_ingress_bypass_t SWITCH_INGRESS_BYPASS_L3 = 16w0x0002;
const switch_ingress_bypass_t SWITCH_INGRESS_BYPASS_ACL = 16w0x0004;
const switch_ingress_bypass_t SWITCH_INGRESS_BYPASS_SYSTEM_ACL = 16w0x0008;
const switch_ingress_bypass_t SWITCH_INGRESS_BYPASS_QOS = 16w0x0010;
const switch_ingress_bypass_t SWITCH_INGRESS_BYPASS_METER = 16w0x0020;
const switch_ingress_bypass_t SWITCH_INGRESS_BYPASS_STORM_CONTROL = 16w0x0040;
const switch_ingress_bypass_t SWITCH_INGRESS_BYPASS_STP = 16w0x0080;
const switch_ingress_bypass_t SWITCH_INGRESS_BYPASS_SMAC = 16w0x0100;
const switch_ingress_bypass_t SWITCH_INGRESS_BYPASS_TUNNEL = 16w0x0200;
// Add more ingress bypass flags here.

const switch_ingress_bypass_t SWITCH_INGRESS_BYPASS_ALL = 16w0xffff;


typedef bit<8> switch_egress_bypass_t;
const switch_egress_bypass_t SWITCH_EGRESS_BYPASS_REWRITE = 8w0x01;
const switch_egress_bypass_t SWITCH_EGRESS_BYPASS_ACL = 8w0x02;
const switch_egress_bypass_t SWITCH_EGRESS_BYPASS_SYSTEM_ACL = 8w0x04;
const switch_egress_bypass_t SWITCH_EGRESS_BYPASS_QOS = 8w0x08;
const switch_egress_bypass_t SWITCH_EGRESS_BYPASS_WRED = 8w0x10;
const switch_egress_bypass_t SWITCH_EGRESS_BYPASS_STP = 8w0x20;
const switch_egress_bypass_t SWITCH_EGRESS_BYPASS_MTU = 8w0x40;
const switch_egress_bypass_t SWITCH_EGRESS_BYPASS_METER = 8w0x80;

// Add more egress bypass flags here.

const switch_egress_bypass_t SWITCH_EGRESS_BYPASS_ALL = 8w0xff;


// STP ------------------------------------------------------------------------
typedef bit<2> switch_stp_state_t;
const switch_stp_state_t SWITCH_STP_STATE_FORWARDING = 0;
const switch_stp_state_t SWITCH_STP_STATE_BLOCKING = 1;
const switch_stp_state_t SWITCH_STP_STATE_LEARNING = 2;

typedef bit<7> switch_stp_group_t;

struct switch_stp_metadata_t {
    bit<12> stp_vid;
    switch_stp_group_t stg;
    switch_stp_state_t state;
}

// PKT ------------------------------------------------------------------------
typedef bit<16> switch_pkt_length_t;

typedef bit<2> switch_pkt_color_t;
const switch_pkt_color_t SWITCH_METER_COLOR_GREEN = 0;
const switch_pkt_color_t SWITCH_METER_COLOR_YELLOW = 1;
const switch_pkt_color_t SWITCH_METER_COLOR_RED = 3;

// HASH ------------------------------------------------------------------------
const switch_hash_mode_t SWITCH_HASH_MODE_NO_IP = 0x00;
const switch_hash_mode_t SWITCH_HASH_MODE_IPV4 = 0x01;
const switch_hash_mode_t SWITCH_HASH_MODE_MPLS = 0x02;
const switch_hash_mode_t SWITCH_HASH_MODE_IPV6 = 0x03;
const switch_hash_mode_t SWITCH_SYM_HASH_MODE_IPV4 = 0x04;
const switch_hash_mode_t SWITCH_SYM_HASH_MODE_IPV6 = 0x05;
const switch_hash_mode_t SWITCH_HASH_MODE_MPLS_EXT = 0x06;
const switch_hash_mode_t SWITCH_HASH_MODE_FRAG_IPV4 = 0x07;
const switch_hash_mode_t SWITCH_HASH_MODE_FRAG_IPV6 = 0x08;

// LOU ------------------------------------------------------------------------

typedef bit<8> switch_l4_port_label_t;

// Metering -------------------------------------------------------------------

typedef bit<8> switch_copp_meter_id_t;


typedef bit<12> switch_meter_index_t;


typedef bit<8> switch_mirror_meter_id_t;

// QoS ------------------------------------------------------------------------
typedef bit<3> switch_qos_trust_mode_t; //2->3->2->3 by sutaomu
const switch_qos_trust_mode_t SWITCH_QOS_UNTRUSTED = 0;
const switch_qos_trust_mode_t SWITCH_QOS_TRUST_DSCP = 1;
const switch_qos_trust_mode_t SWITCH_QOS_TRUST_PCP = 2;
const switch_qos_trust_mode_t SWITCH_QOS_TRUST_EXP = 3; //add by sutaomu
const switch_qos_trust_mode_t SWITCH_QOS_TRUST_PRE = 4;
const switch_qos_trust_mode_t SWITCH_QOS_AUTO_TRUST = 5;

typedef bit<5> switch_qos_group_t;


typedef bit<3> switch_tc_t;
typedef bit<3> switch_cos_t;





@pa_auto_init_metadata
@pa_parser_group_monogress //grep for monogress in phv_allocation log to confirm
// @pa_container_size("pp_front", "ingress", "ig_md.qos.acl_meter_index", 32)  /* for compile sucess */
// @pa_solitary("pp_front", "ingress", "ig_md.qos.meter_mode") // for compile success
@pa_atomic("pp_front", "ingress", "ig_md.policer.slice1.group_classid")// for compile success
@pa_atomic("pp_front", "ingress", "ig_md.policer.slice2.group_classid")// for compile success
@pa_atomic("pp_front", "ingress", "ig_md.policer.slice3.group_classid")// for compile success
struct switch_ingress_qos_metadata_t {
    switch_qid_t qid;
    switch_ingress_cos_t icos; // Ingress only.

    // add more
    bit<3> pcp;
    switch_tc_t tc;
    switch_pkt_color_t color;
    bit<1> chgDSCP_disable; /* by lichunfeng */
    bit<1> BA;
    bit<1> is_pipe;
    bit<3> pipe_tc;
    bit<2> pipe_color;
    bit<1> pcp_chg;
    bit<1> exp_chg;
    bit<1> ippre_chg;
    // bit<1> port_meter_type; // 0 color-blind , 1 color-aware
    // bit<1> lif_meter_type;
    switch_qos_trust_mode_t port_trust_mode;
    switch_qos_trust_mode_t lif_trust_mode;
    bit<14> hqos_meter_index;
    bit<9> qos_meter_index;
    bit<1> queue_meter_flag;
    bit<1> sp_flag;
    bit<14> lif_meter_index;
    bit<14> acl_meter_index;
    bit<8> port_meter_index;
    bit<8> qppb_meter_index;
    bit<1> is_auto_trust;
    switch_pkt_color_t qppb_meter_color;
    switch_pkt_color_t port_meter_color;
    switch_pkt_color_t lif_meter_color;
    switch_pkt_color_t acl_meter_color;
    switch_pkt_color_t cq2xs_sfp_color;
    bit<3> drop_color;
    bit<1> ace_mode;

    bit<5> port_ds;
    bit<5> lif_ds;
    bit<1> mpls_valid;
    bit<1> set_dscp; /* by lvlianlin */
    bit<1> qppb_set_dscp; /* by lvlianlin */
    bit<6> qppb_dscp; /* by lvlianlin */
    bit<1> set_tc;
    bit<1> set_color;
    bit<6> dscp;
    bit<1> car_flag;
    bit<2> qos_pkt_type;
    bit<6> dscp_tmp;
    bit<3> tc_tmp;
    bit<2> color_tmp;
    bool acl_set_tc;
    bool acl_set_color;

    bit<15> drop_fqid1;
    bit<15> drop_fqid2;
    bit<16> FQID;
    bit<32> len_sub1; /* by zhuanghui */
    bit<32> len_sub2;

    // load balance by fqid
    bit<1> fq_dlb_enb;
    bit<1> port_hqos_enb;
    bit<1> lif_hqos_enb;
    bit<12> port_base_qid;
    bit<12> lif_base_qid;

    // for mac acl
    bit<1> mac_set_tc;
    bit<1> mac_set_color;
    bit<1> mac_set_pcp;
    bit<3> mac_tc;
    bit<2> mac_color;
    bit<3> mac_pcp;

    bit<32> q_max; // for ghost test
    bit<32> q_flag;
}

// @pa_container_size("pp_front", "egress", "eg_md.qos.backpush_gap", 32)  /* for compile sucess */
struct switch_egress_qos_metadata_t {
    switch_qid_t qid;
    bit<19> qdepth; // Egress only.
    bit<5> port_ds;
    bit<5> lif_ds;
    bit<3> drop_color;
    switch_pkt_color_t acl_meter_color;
    switch_pkt_color_t qppb_meter_color;
    switch_pkt_color_t port_meter_color;
    switch_pkt_color_t lif_meter_color;
    switch_pkt_color_t color_tmp;
    bit<8> port_meter_index;
    bit<8> qppb_meter_index;
    bit<14> lif_meter_index;
    bit<14> acl_meter_index;
    bit<1> ace_mode;
    switch_tc_t tc;
    switch_pkt_color_t color;
    bit<1> chgDSCP_disable; /* by lichunfeng */
    bit<1> BA;
    bit<1> port_PHB;
    bit<1> lif_PHB;
    bit<1> pcp_chg;
    bit<1> exp_chg;
    bit<1> ippre_chg;
    bit<1> port_hqos_enb;
    bit<1> lif_hqos_enb;
    bit<1> is_short_pipe;
    switch_qos_trust_mode_t trust_mode;
    bit<16> FQID;
    bit<1> is_pipe;
    switch_pkt_color_t storm_control_color;
    bit<1> set_dscp; /* by lvlianlin */
    bit<1> qppb_set_dscp; /* by lvlianlin */
    bit<1> acl_set_dscp; /* by lvlianlin */
    bit<6> dscp;
    bit<6> qppb_dscp;
    bit<6> acl_dscp;
    bit<3> pcp;
    bit<3> ippre;
    bit<12> port_base_qid;
    bit<12> lif_base_qid;
    bit<1> car_flag;

    bit<32> len_sub1; /* by zhuanghui */
    bit<32> len_sub2;
    bit<1> drop_flag;
    bit<16> to_be_sub;
    bit<16> to_be_add;

    bit<1> q_hi_flag;
    bit<1> q_lo_flag;
    bit<32> backpush_gap;
    bit<5> mirror_type;
}
// Tunnel -------------------------------------------------------------------
// typedef bit<8> switch_src_index_t;
// Learning -------------------------------------------------------------------
typedef bit<1> switch_learning_mode_t;
const switch_learning_mode_t SWITCH_LEARNING_MODE_DISABLED = 0;
const switch_learning_mode_t SWITCH_LEARNING_MODE_LEARN = 1;

struct switch_learning_digest_t {
    switch_evlan_t evlan;
    switch_lif_t learning_l2iif;
    mac_addr_t src_addr;
}

struct switch_learning_metadata_t {
    switch_learning_mode_t evlan_mode;
    switch_learning_mode_t port_mode;
}

// lookup
struct switch_lookup_fields_t {
    switch_lkp_pkt_type_t pkt_type;

    mac_addr_t mac_src_addr;
    mac_addr_t mac_dst_addr;
    bit<12> vid;
    bit<8> ip_tos_label;
    bit<8> ip_pkt_len_label;
    bit<8> ip_proto_label;
    bit<16> l4_src_port_label;
    bit<16> l4_dst_port_label;
    bit<16> l4_port_label_16;
    bit<32> l4_port_label_32;
    bit<64> l4_port_label_64;
    bit<16> iif_label;
    bit<16> port_label;

    switch_ip_type_t ip_type;
    bit<1> ip_inner; /* use in process 8, determines whether inner_hdr are used */
    bit<1> ip_options;
    bit<8> ip_proto;
    bit<8> ip_ttl;
    bit<8> tmp_ttl;
    bit<8> ip_tos;
    bit<16> ip_pkt_len;
    bit<8> ipv6_tos;
    bit<8> ipv4_tos;
    bit<2> ip_frag;
    bit<128> ip_src_addr;
    bit<128> ip_dst_addr;

    bit<8> tcp_flags;
    bit<16> l4_src_port;
    bit<16> l4_dst_port;

    bit<16> ipv4_ihl;
    bit<16> pkt_length;
    bit<3> mpls_exp;
    bit<4> version;
    bit<20> flow_label;
}

// Multicast ------------------------------------------------------------------
typedef MulticastGroupId_t switch_mgid_t;

/* by weiyunfeng */
struct switch_ip_mc_metadata_t {
    bool multicast_enable;
    bool multicast_snooping;
}

struct switch_ingress_multicast_metadata_t {
    switch_mgid_t id;
    bit<2> mode;
    /* by weiyunfeng */
    switch_xid_t level1_exclusion_id;
    bit<16> egress_rid;

    switch_ip_mc_metadata_t ipv4;
    switch_ip_mc_metadata_t ipv6;
}


struct switch_egress_multicast_metadata_t {
    switch_mgid_t id;
    bit<2> mode;

    /* by weiyunfeng */
    switch_xid_t level1_exclusion_id;

    switch_ip_mc_metadata_t ipv4;
    switch_ip_mc_metadata_t ipv6;
}

// URPF -----------------------------------------------------------------------
typedef bit<2> switch_urpf_mode_t;
const switch_urpf_mode_t SWITCH_URPF_MODE_NONE = 0;
const switch_urpf_mode_t SWITCH_URPF_MODE_LOOSE = 1;
const switch_urpf_mode_t SWITCH_URPF_MODE_STRICT = 2;

// Mirroring ------------------------------------------------------------------
typedef MirrorId_t switch_mirror_session_t; // Defined in tna.p4
const switch_mirror_session_t SWITCH_MIRROR_SESSION_CPU = 250;

// Using same mirror type for both Ingress/Egress to simplify the parser.
typedef bit<5> switch_mirror_type_t;// length equal to switch_bridge_type_t




// #define SWITCH_MIRROR_TYPE_DTEL_SWITCH_LOCAL 4
// #define SWITCH_MIRROR_TYPE_PCAP 4







// #define SWITCH_MIRROR_TYPE_FRONT_TRACE 11



/* Although strictly speaking deflected packets are not mirrored packets,
 * need a mirror_type codepoint for packet length adjustment.
 * Pick a large value since this is not used by mirror logic.
 */



typedef bit<8> switch_pipeline_location_t;
const switch_pipeline_location_t INGRESS_FRONT = 1;
const switch_pipeline_location_t EGRESS_UPLINK = 2;
const switch_pipeline_location_t INGRESS_UPLINK = 3;
const switch_pipeline_location_t EGRESS_FABRIC = 4;
const switch_pipeline_location_t INGRESS_FE = 5;
const switch_pipeline_location_t EGRESS_FE = 6;
const switch_pipeline_location_t INGRESS_FABRIC = 7;
const switch_pipeline_location_t EGRESS_DOWNLINK = 8;
const switch_pipeline_location_t INGRESS_DOWNLINK = 9;
const switch_pipeline_location_t EGRESS_FRONT = 10;
const switch_pipeline_location_t INGRESS_PCIE = 11;
const switch_pipeline_location_t EGRESS_PCIE = 12;

struct switch_port_metadata_frontpipe_t {
    switch_port_type_t port_type;
    //switch_eport_t eport;
    // switch_logic_port_t src_port;
}

struct switch_port_metadata_uplink_pipe_t {
    switch_port_type_t port_type;
    // bit<1> is_from_fabric_port;
}

struct switch_port_metadata_fabric_pipe_t {
    switch_port_type_t port_type;
    // @padding bit<1> pad;
    bit<7> src_device;
    switch_logic_port_t src_port;
}

struct switch_port_metadata_downlink_pipe_t {
    switch_port_type_t port_type;
    // switch_logic_port_t src_port;
}

//-----------------------------------------------------------------------------
// Other Metadata Definitions
//-----------------------------------------------------------------------------
// Flags
//XXX Force the fields that are XORd to NOT share containers.
//@pa_container_size("ingress", "ig_md.flags.ipv6_mc_check", 32)
struct switch_ingress_flags_t {
    bool ipv4_checksum_err;
    bool inner_ipv4_checksum_err;
    bool link_local;
    bit<1> dmac_miss;
    bool port_meter_drop;
    bool lif_meter_drop;
    bool qppb_meter_drop;
    bool capture_ts;

    bit<1> flowspec_disable;
    bit<1> flowspec_disable_v4;
    bit<1> flowspec_disable_v6;
    bit<1> fwd_fail;
    bit<1> glean;
    bit<1> drop;
    bit<1> is_gleaned;
    bit<1> is_pbr_nhop;
    bit<1> bypass_acl;
    bit<1> is_eth;

    bit<1> escape_etm;
    bit<1> is_elephant; /* 8CQ to 8CQ按照RR轮询均衡 */
    bit<1> is_eop;
    bit<1> port_balance; /* 40XS 按照端口均衡 */
    bit<1> plb_enable; /* 端口均衡开关 */
    bit<1> elb_enable; /* 大象流均衡开关 */
    bit<1> imprv_lb_enable; /* 精进hash开关 */
    bit<1> vlan_member_check; /*vlan成员检查开关*/
    bit<1> ul_bridge;
    bool ext_srv6;
    bool ext_l4_encap;
    bool ext_cpp;
    bool ext_tunnel_decap;
    bool ext_mirror;

    /* by weiyunfeng */
    bool flood_to_multicast_routers;
    bool mrpf;
    bool routed;
    // switch_evlan_t same_ev;
    /* by wenkun */
    bit<1> lag_miss;
    /* by yeweixin */
    bit<1> bfd_fib_myip;
    bit<1> bypass_fabric_lag;
    bit<32> mc_check;
}

struct switch_egress_flags_t {
    bool ipv4_checksum_err;
    bool capture_ts;
    bool port_meter_drop;
    bool lif_meter_drop;
    bool qos_meter_drop;
    bool acl_meter_drop;
    bool qppb_meter_drop;
    bool qosacl_hit;
    // Add more flags here.
    /* by xiachangkai */
    bit<1> dmac_miss;
    bit<1> is_mac_static;
    bit<1> static_mac_move_drop;
    bit<1> glb_learning;
    bit<1> bh_dmac_hit;
    bit<1> horizon_split_drop_reason;
    bool storm_control_drop;
    bit<1> dmac_bypass;
    bit<1> enb_itm;
    bool ext_srv6;
    bool ext_l4_encap;
    bool ext_cpp;
    bool ext_tunnel_decap;
    bool ext_mirror;

    /* by weiyunfeng */
    bool routed;
    bool tunnel_routed;
    // flags for fabric
    // bit<1> fpga_flag;
    bit<1> flowspec_disable;
    bit<1> glean;
    bit<1> drop;
    bit<1> is_pbr_nhop;
    bit<1> bypass_acl;
    bit<1> bypass_sysacl;
    bit<1> is_gleaned;

    bit<1> escape_etm;
    bit<1> is_elephant;
    bit<1> is_eop;
    bit<1> plb_enable;
    bit<1> elb_enable;

    // bit<1> skip_eg_tm;
    bit<2> learning;
    bit<2> learn_en_evlan;
    bit<1> sym_enable;
    /* by yeweixin */
    bit<1> efm_drop;

    bit<1> cpu_pkt;

    bit<1> nd_flag;
}

typedef bit<1> switch_iif_type_t;
const switch_iif_type_t SWITCH_L3_IIF_TYPE = 1;
const switch_iif_type_t SWITCH_L2_IIF_TYPE = 0;

// common info, such as eport, hash
@pa_no_overlay("pp_downlink", "ingress", "ig_intr_md.ingress_port")
//@pa_container_size("pp_downlink", "ingress", "ig_md.tunnel.next_hdr_type", 8)
// @pa_container_size("pp_front", "ingress", "ig_md.common.dst_port", 8)      /* for compile sucess */
// @pa_container_size("pp_front", "ingress", "ig_md.common.eport", 16)        /* for compile sucess */
// @pa_container_size("pp_uplink", "ingress", "ig_md.common.ul_nhid", 16)        /* for unerlay_nexthop size, compile sucess */
@pa_container_size("pp_uplink", "ingress", "ig_md.route.l2_l3oif", 16) /* for unerlay_nexthop size, compile sucess */
@pa_container_size("pp_fabric", "egress", "eg_md.route.l4_l3oif", 16) /* for l4_encap size, compile sucess */
// @pa_atomic("pp_uplink", "ingress", "ig_md.common.egress_eport")        /* for unerlay_nexthop size, compile sucess */
// @pa_container_size("pp_uplink", "ingress", "ig_md.route.overlay_counter_index", 16)        /* for overlay_nexthop size, compile sucess */
// @pa_container_size("pp_uplink", "ingress", "ig_md.common.iif", 16)        /* for smac size, compile sucess */

struct switch_ingress_common_metadata_t {
    bit<16> ether_type; // etherType
    // bit<1> fpga_flag;
    switch_pkt_type_t pkt_type; // switch_pkt_type
    bit<1> is_mirror;
    bit<1> is_mcast;
    switch_device_t dst_device; /* dest LC device */
    switch_logic_port_t dst_port; /* dest front port */
    bit<1> efm_enable;
    bit<6> dst_ecid; // dest externed port
    switch_eport_t eport; /* ingress port/lag index */
    switch_eport_t egress_eport; /* egress port/lag index */
    switch_eport_label_t eport_label; /* eprot label for acl */
    switch_port_type_t port_type; /* ingress port_type */

    switch_bridge_type_t bridge_type;
    bit<10> tmp_sn;
    bit<1> extend;
    bit<1> cpu_direction;
    bit<1> bypass_fpga;
    bit<2> fwd_mode;
    bit<1> track;
    bit<1> is_from_cpu_pcie;

    switch_iif_type_t iif_type;
    switch_lif_t iif;
    switch_lif_t oif;
    switch_lif_t ul_iif;

    bit<16> nexthop;
    bit<16> ul_nhid;
    bit<16> ol_nhid;

    bit<16> l2_encap;
    bit<16> l3_encap;
    bit<16> l4_encap;

    bit<16> pkt_length;

    switch_drop_reason_t drop_reason; /* packet drop reason */
    switch_pipeline_location_t pipeline_location;
    switch_logic_port_t dst_mirror_port;
    bit<16> trace_location_dport;
    bit<16> trace_counter;
    bit<32> trace_32;
    bit<32> timestamp;
    bit<32> timestamp_250ns;

    bool prr_enable;
    switch_port_t dev_port;
    bit<16> prr_sn;
    bit<16> flow_sn;
    bit<4> sbid;
    switch_ingress_bypass_t bypass;
    //add more fields here
    switch_hash_t hash; /* hash value */
    switch_hash_t ap_hash; /* ap hash value */
    switch_hash_t sn; /* sn value */
    switch_hash_mode_t hash_mode; /* hash mode */
    bit<16> udf;
    switch_port_t ingress_port;
    bit<7> src_device;
    switch_logic_port_t src_port;
    bit<8> cpu_reason;
    bit<16> cpu_code;
    bit<16> queue; /* 队列 ID */
    bit<32> tmp_time;
    bit<1> svi_flag;
}

// common info, such as eport, hash
@pa_no_overlay("pp_front", "egress", "eg_md.common.pkt_type")
@pa_no_overlay("pp_front", "egress", "eg_md.common.is_mcast")
// @pa_atomic("pp_uplink", "egress", "eg_md.common.iif")       /* for compile success */
// @pa_atomic("pp_downlink", "egress", "eg_intr_md.egress_rid")
// @pa_atomic("pp_downlink", "egress", "eg_md.common.egress_eport")
// @pa_atomic("pp_downlink", "egress", "eg_md.ebridge.evlan")
// @pa_container_size("pp_downlink", "egress", "eg_md.common.oif", 16)
// @pa_container_size("pp_front", "egress", "eg_md.lkp.ip_proto", 16)
@pa_atomic("pp_fabric", "ingress", "hash_dport_0")
// @pa_container_size("pp_uplink", "egress", "eg_md.qos.qdepth", 32)
struct switch_egress_common_metadata_t {
    bit<16> ether_type; // etherType
    switch_pkt_type_t pkt_type; // switch_pkt_type
    bit<1> is_mirror;
    bit<1> is_mcast;
    switch_cpu_eth_encap_id_t cpu_eth_encap_id;

    switch_device_t dst_device; /* dest LC device */
    switch_logic_port_t dst_port; /* dest front port */
    switch_logic_port_t backpush_dst_port; /* dest front port */
    bit<6> dst_ecid; // dest externed port
    bit<1> efm_enable;
    bit<1> is_from_cpu_pcie;

    switch_port_t ingress_port; /* ingress port */
    switch_port_type_t port_type; /* egress port_type */

    switch_iif_type_t iif_type;
    switch_lif_t iif;
    switch_lif_t oif;
    switch_lif_t ul_iif;
    switch_lif_t learn_iif;
    bit<8> iif_classid;

    switch_eport_t eport; /* ingress port/lag index */
    switch_eport_t egress_eport; /* egress port/lag index */
    switch_eport_label_t eport_label; /* eprot label for acl */
    switch_egress_bypass_t bypass;

    switch_pkt_length_t pkt_length;

    bit<1> extend;
    bit<3> ext_len;

    bit<1> extend_fake;

    bit<3> service_class;

    bit<1> track;

    bit<1> parser_pad;

    switch_drop_reason_t drop_reason; /* packet drop reason */
    switch_drop_reason_t trace_drop_reason;
    switch_pipeline_location_t pipeline_location;
    switch_logic_port_t dst_mirror_port;
    bit<16> trace_location_dport;
    bit<16> trace_counter;
    bit<32> trace_32;
    bit<32> timestamp;

    bit<16> nexthop;
    bit<16> l3_encap;
    bit<16> l2_encap;

    bool ip_opt2_chksum_enable;

    //add more fields here
    switch_hash_t hash; /* hash value */
    switch_hash_mode_t hash_mode; /* hash mode */
    bit<16> udf;
    switch_bridge_type_t bridge_type;
    bit<7> src_device;
    switch_logic_port_t src_port; /* ingress front port */
    bit<8> cpu_reason;
    bit<16> cpu_code;

    bit<6> srv6_tc;
    bit<1> srv6_set_dscp;
    bit<8> dec_ttl;
    bit<16> last_egress_port; /* 上一个SN的出口 */

    bit<16> var_16bit_310;
    bit<1> svi_flag;
}

// Tunneling by jiangminda -----------------------------------------------------------
// Tunnel Type Classify
typedef bit<3> switch_tunnel_type_t;
const switch_tunnel_type_t SWITCH_TUNNEL_TYPE_NONE = 0;
// const switch_tunnel_type_t SWITCH_TUNNEL_TYPE_IPV4 = 1;
// const switch_tunnel_type_t SWITCH_TUNNEL_TYPE_IPV6 = 2;
const switch_tunnel_type_t SWITCH_TUNNEL_TYPE_IP_TUNNEL = 1;//v4 tunnel gre tunnel
const switch_tunnel_type_t SWITCH_TUNNEL_TYPE_IPGRE = 2;
const switch_tunnel_type_t SWITCH_TUNNEL_TYPE_SRV6 = 3;
const switch_tunnel_type_t SWITCH_TUNNEL_TYPE_IPV4_VXLAN = 4;
const switch_tunnel_type_t SWITCH_TUNNEL_TYPE_MPLS = 5;
const switch_tunnel_type_t SWITCH_TUNNEL_TYPE_IPv6GRE = 6;
const switch_tunnel_type_t SWITCH_TUNNEL_TYPE_IPV6_VXLAN = 7;

// Tunnel Inner Packet ---------------------------------------------------------------
typedef bit<4> switch_tunnel_inner_pkt_t;
const switch_tunnel_inner_pkt_t SWITCH_TUNNEL_INNER_PKT_NONE= 0;
const switch_tunnel_inner_pkt_t SWITCH_TUNNEL_INNER_PKT_ETHERNET = 1;
const switch_tunnel_inner_pkt_t SWITCH_TUNNEL_INNER_PKT_IPV4 = 2;
const switch_tunnel_inner_pkt_t SWITCH_TUNNEL_INNER_PKT_IPV6 = 3;
const switch_tunnel_inner_pkt_t SWITCH_TUNNEL_INNER_PKT_IPX = 4;
// const switch_tunnel_inner_pkt_t SWITCH_TUNNEL_INNER_PKT_GRE_IPV4 = 5;
// const switch_tunnel_inner_pkt_t SWITCH_TUNNEL_INNER_PKT_GRE_IPV6 = 6;

// Tunnel Encap Type ----------------------------------------------------------------
typedef bit<4> switch_tunnel_encap_type_t;
const switch_tunnel_encap_type_t SWITCH_TUNNEL_ENCAP_TYPE_NONE = 0;
const switch_tunnel_encap_type_t SWITCH_TUNNEL_ENCAP_TYPE_IPINIP = 1;
const switch_tunnel_encap_type_t SWITCH_TUNNEL_ENCAP_TYPE_MPLS = 2;
const switch_tunnel_encap_type_t SWITCH_TUNNEL_ENCAP_TYPE_ENCAP_SRV6 = 3;
const switch_tunnel_encap_type_t SWITCH_TUNNEL_ENCAP_TYPE_END_INSERT_SRV6 = 4;
const switch_tunnel_encap_type_t SWITCH_TUNNEL_ENCAP_TYPE_IPGRE = 5;
const switch_tunnel_encap_type_t SWITCH_TUNNEL_ENCAP_TYPE_IPV6GRE = 6;
const switch_tunnel_encap_type_t SWITCH_TUNNEL_ENCAP_TYPE_V4_VXLAN = 7;
const switch_tunnel_encap_type_t SWITCH_TUNNEL_ENCAP_TYPE_V6_VXLAN = 8;
const switch_tunnel_encap_type_t SWITCH_TUNNEL_ENCAP_TYPE_H_INSERT_SRV6 = 9;

typedef bit<4> switch_opcode_type_t;
const switch_opcode_type_t SWITCH_MPLS_POP_CONTINUE = 0;
const switch_opcode_type_t SWITCH_MPLS_L2VPN_TER = 1;
const switch_opcode_type_t SWITCH_MPLS_L3VPN_TER = 2;
const switch_opcode_type_t SWITCH_MPLS_POP = 3;
const switch_opcode_type_t SWITCH_MPLS_SWAP = 4;
const switch_opcode_type_t SWITCH_MPLS_SWAP_PUSH = 5;
const switch_opcode_type_t SWITCH_MPLS_SWAP_ENCAP = 6;

typedef bit<3> switch_exp_mode_t;
const switch_exp_mode_t SWITCH_EXP_MODE_MAP = 0;
const switch_exp_mode_t SWITCH_EXP_MODE_SET = 1;
const switch_exp_mode_t SWITCH_EXP_MODE_SWAP_KEEP = 2;


typedef bit<4> switch_srv6_end_type_t;
const switch_srv6_end_type_t SWITCH_SRV6_END_TYPE_NONE = 0;
const switch_srv6_end_type_t SWITCH_SRV6_END_TYPE_END = 1;
const switch_srv6_end_type_t SWITCH_SRV6_END_TYPE_END_X = 2;
const switch_srv6_end_type_t SWITCH_SRV6_END_TYPE_END_T = 3;
const switch_srv6_end_type_t SWITCH_SRV6_END_TYPE_END_DX = 4;
const switch_srv6_end_type_t SWITCH_SRV6_END_TYPE_END_DT = 5;
const switch_srv6_end_type_t SWITCH_SRV6_END_TYPE_END_OP = 6;
const switch_srv6_end_type_t SWITCH_SRV6_END_TYPE_END_B6_ENCAPS = 7;
const switch_srv6_end_type_t SWITCH_SRV6_END_TYPE_END_B6_INSERT = 8;

typedef bit<4> switch_srv6_flavors_t;
const switch_srv6_flavors_t SWITCH_SRV6_FLAVORS_PSP = 1 << 0;
const switch_srv6_flavors_t SWITCH_SRV6_FLAVORS_USP = 1 << 1;
const switch_srv6_flavors_t SWITCH_SRV6_FLAVORS_USD = 1 << 2;
const switch_srv6_flavors_t SWITCH_SRV6_FLAVORS_COC = 1 << 3;


typedef bit<3> switch_netport_group_t;

typedef bit<1> switch_ptag_mod_t;
const switch_ptag_mod_t SWITCH_PTAG_MOD_RAW = 0;
const switch_ptag_mod_t SWITCH_PTAG_MOD_TAGGED = 1;
typedef bit<2> switch_ptag_action_t;
const switch_ptag_action_t VLANTAG_NONE_MODE = 0;
const switch_ptag_action_t VLANTAG_RAW_MODE = 1;
const switch_ptag_action_t VLANTAG_REPLACE_IF_PRESENT = 2;
const switch_ptag_action_t VLANTAG_NOREPLACE_IF_PRESENT = 3;


typedef bit<3> switch_tunnel_tc_t;


typedef bit<11> switch_ip_index_t;

@pa_solitary("ingress", "ig_md.tunnel.tmp_iif")
// @pa_container_size("pp_front", "ingress", "ig_md.tunnel.terminate", 16)
struct switch_ingress_tunnel_metadata_t {
    switch_tunnel_type_t type;
    bit<24> vni;
    // bit<32> hash;
    bool terminate;
    bit<8> ttl;
    // bit<8> ttl_hash;
    // add more
    bit<20> first_label;
    bit<20> second_label;
    bit<20> third_label;
    bit<20> last_label;
    bit<20> entropy_label;
    // switch_pkt_type_t pkt_type;
    switch_drop_reason_t drop_reason;
    switch_tunnel_tc_t exp; /* tc */
    // switch_tunnel_tc_t exp_hash;
    bit<8> label_space;
    bit<1> ttl_copy; /* 0 = NoAction, 1 = copy */
    bool exp_mode;
    bool continue;
    switch_next_hdr_type_t next_hdr_type;
    // bit<1> cw_mode;
    bit<1> bos;
    switch_ptag_mod_t ptag_igmod; /* ig pip ptag mode: 0: RAW, 1: TAGGED */
    switch_ptag_action_t ptag_eg_action;
    bit<16> ptag_tpid;
    vlan_id_t ptag_vid;
    bool mpls_enable;
    bit<8> php_ttl;
    bit<8> tmp_ttl;
    bool php_terminate;
    /* by lichunfeng */
    bit<1> ttl_copy_1;
    bit<1> ttl_copy_2;
    bit<1> ttl_copy_3;
    bit<1> ttl_copy_4;
    bit<8> ttl_1;
    bit<8> ttl_2;
    bit<8> ttl_3;
    bit<8> ttl_4;
    switch_ingress_bypass_t bypass;
    bit<16> l4_encap;
    bool ip_addr_miss;
    bit<4> inner_type;
    bit<4> inner_pkt_parsed;

    bit<4> srv6_end_type;
    switch_srv6_flavors_t srv6_flavors;

    switch_lif_t tmp_iif;
    // bool vxlan_l4_encap_flag;
    // bit<48> dst_addr;
    bit<1> phpcopy;
    bit<4> opcode;
}

struct switch_ingress_ebridge_metadata_t {
    // add more
    switch_lif_t l2iif;
    switch_lif_t l2oif;
    bit<16> learning_l2iif;
    switch_evlan_t evlan;
    /* add more by xiachangkai */
    switch_learning_metadata_t learning;
    switch_evlan_classid_t evlan_classid;
}

struct switch_ingress_route_metadata_t {
    // add more
    /* add by jmd */
    bit<13> vrf;
    /* by yangyi */
    switch_lif_t l3oif;
    switch_lif_t l4_l3oif;
    switch_lif_t l3_l3oif;
    switch_lif_t l2_l3oif;
    bool g_l3mac_enable;
    bit<1> rmac_hit;
    bit<8> sip_l3class_id;
    bit<8> dip_l3class_id;
    bit<14> overlay_counter_index;
    bit<6> nexthop_type;
    bit<2> nexthop_cmd;
    bit<16> mtu_check;
    bool ipv4_unicast_enable;
    bool ipv6_unicast_enable;

    bit<48> ether_dstaddr;
    bit<4> type;

}

typedef bit<4> switch_acl_bypass_t;
const switch_acl_bypass_t SWITCH_ACL_BYPASS_FLOWSPEC = 1<<0;/* VFP, IFP-1, GFP */
const switch_acl_bypass_t SWITCH_ACL_BYPASS_MIRROR = 1<<1;/* VFP, EFP-2 */
const switch_acl_bypass_t SWITCH_ACL_BYPASS_PBR = 1<<1;/* IFP-1 */
const switch_acl_bypass_t SWITCH_ACL_BYPASS_SAMPLE = 1<<2;/* VFP, EFP-2 */
const switch_acl_bypass_t SWITCH_ACL_BYPASS_QOS = 1<<2;/* IFP-1 */
const switch_acl_bypass_t SWITCH_ACL_BYPASS_ACL = 1<<3;/* IFP-1, GFP, EFP-2 */

const switch_acl_bypass_t SWITCH_ACL_BYPASS_1 = 1<<0;
const switch_acl_bypass_t SWITCH_ACL_BYPASS_2 = 1<<1;
const switch_acl_bypass_t SWITCH_ACL_BYPASS_3 = 1<<2;
const switch_acl_bypass_t SWITCH_ACL_BYPASS_4 = 1<<3;


typedef bit<16> switch_acl_classid_t;

struct switch_tmp_cpu_code_t {
    bit<1> set;
    bit<16> cpu_code;
    bit<16> stats_id;
}

struct switch_ingress_policer_slice_t {
    switch_acl_bypass_t group;
    switch_acl_classid_t group_classid;
}

struct switch_egress_policer_slice_t {
    switch_acl_bypass_t group;
    switch_acl_classid_t group_classid;
}

struct switch_policer_pbr_t {
    bit<1> set_dscp;
    bit<6> dscp;
}

struct switch_ingress_policer_metadata_t {
    switch_ingress_policer_slice_t slice1;
    switch_ingress_policer_slice_t slice2;
    switch_ingress_policer_slice_t slice3;
    switch_ingress_policer_slice_t slice4;
    switch_ingress_policer_slice_t slice5;
    switch_ingress_policer_slice_t slice6;
    switch_ingress_policer_slice_t slice7;
    switch_ingress_policer_slice_t slice8;
    switch_acl_bypass_t bypass;
    switch_pkt_color_t meter_color;
    bit<16> meter_id;
    bit<1> drop;
    bit<1> mac_drop;
    bit<1> mirror_enable;
    switch_lif_t iif;
    switch_acl_classid_t group_classid_1;
    switch_acl_classid_t group_classid_2;
    switch_acl_classid_t group_classid_3;
    switch_acl_classid_t group_classid_4;
    switch_acl_classid_t v4_group_classid_1;
    switch_acl_classid_t v4_group_classid_2;
    switch_acl_classid_t v4_group_classid_3;
    switch_acl_classid_t v4_group_classid_4;
    switch_acl_classid_t v6_group_classid_1;
    switch_acl_classid_t v6_group_classid_2;
    switch_acl_classid_t v6_group_classid_3;
    switch_acl_classid_t v6_group_classid_4;

    bit<8> ttl_min;
    bit<8> ttl_dec;
    switch_cpp_drop_reason_t cpp_drop_reason;
}

struct switch_ingress_mirror_metadata_t {
    switch_pkt_src_t src;
    switch_mirror_type_t type;
    switch_mirror_session_t session_id;
    switch_mirror_session_t mirror_id;
    switch_pkt_color_t color;
    bit<1> span_flag;
    bit<1> sample_flag;
    bit<1> pcap_flag;
}

struct switch_ingress_fabric_metadata_t {
    // add more
    switch_cpu_reason_t reason_code;
    switch_cpu_reason_t cpu_reason;
}


typedef bit<128> srv6_sid_t;
struct switch_ingress_srv6_metadata_t {
    srv6_sid_t sid; // seg_list[--SL]
    srv6_sid_t g_sid; // seg_list[SL]
    bit<32> c_sid;
    bit<8> prefixlen; // common prefix length
    bit<2> si; // G-SID index
    bit<1> usp;

    bool srh_terminate;
    bool sl_is_zero;
    bool sl_is_one;
    bit<8> seg_left;
    bit<8> last_entry;
    bit<8> hdr_ext_len;
    bit<1> is_loopback;
    bit<1> coc_flag;
    bit<1> payload_flag;
    bit<2> si_hash;
}



/* add by yeweixin */
typedef bit<16> switch_ipfix_t;
typedef bit<16> switch_ipfix_flow_id_t;
typedef bit<16> switch_ipfix_gap_t;
typedef bit<16> switch_ipfix_random_t;
typedef bit<16> switch_ipfix_random_mask_t;
typedef bit<1> switch_ipfix_random_flag_t;
typedef bit<16> switch_ipfix_count_t;
typedef bit<1> switch_ipfix_sample_flag_t;
typedef bit<10> switch_ipfix_session_t;
typedef bit<1> switch_ipfix_enable_t;
typedef bit<1> switch_ipfix_mode_t;

const switch_pkt_type_t SWITCH_IPFIX_PKT_TYPE_IPV4 = 1;
const switch_pkt_type_t SWITCH_IPFIX_PKT_TYPE_MPLS = 2;
const switch_pkt_type_t SWITCH_IPFIX_PKT_TYPE_IPV6 = 3;

const switch_pkt_type_t CPU_ETH_PKT_TYPE_IPFIX = 1;
const switch_pkt_type_t CPU_ETH_PKT_TYPE_BFD = 2;
const switch_pkt_type_t CPU_ETH_PKT_TYPE_PCAP = 3;
const switch_pkt_type_t CPU_ETH_PKT_TYPE_TRACE = 7;
const switch_pkt_type_t CPU_ETH_PKT_TYPE_IPFIX_SPEC_V4 = 9;
const switch_pkt_type_t CPU_ETH_PKT_TYPE_IPFIX_SPEC_V6 = 10;
const switch_pkt_type_t CPU_ETH_PKT_TYPE_CCM = 11;

struct switch_ipfix_metadata_t{
    switch_bridge_type_t bridge_md_type;
    bool enable;
    switch_pkt_type_t pkt_type;
    switch_ipfix_mode_t mode;
    switch_pkt_src_t src;
    switch_ipfix_flow_id_t flow_id;
    switch_ipfix_gap_t sample_gap;
    switch_ipfix_random_t random_num;
    bit<1> random_flag;
    switch_ipfix_random_mask_t random_mask;
    switch_ipfix_count_t count;
    // switch_ipfix_sample_flag_t ig_sample_flag;
    // switch_ipfix_sample_flag_t eg_sample_flag;
    switch_ipfix_sample_flag_t sample_flag;
    switch_ipfix_sample_flag_t pcap_flag;
    switch_mirror_session_t session_id;
    // bit<16> ether_type;
    bit<16> delta;
    bit<2> fwd_mode;
    bit<6> cpu_eth_encap_pkt_type;
    bit<1> dir;
}

@pa_no_overlay("pp_downlink", "egress", "eg_md.tunnel.ptag_vid")
@pa_no_overlay("pp_downlink", "egress", "eg_md.tunnel.exp")
@pa_no_overlay("pp_downlink", "egress", "eg_md.tunnel.vni")
struct switch_egress_tunnel_metadata_t {
    switch_tunnel_type_t type;
    switch_tunnel_type_t evlan_type;
    bit<1> evlan_rmac_hit;
    switch_tunnel_encap_type_t encap_type;
    bool terminate;
    bit<1> bak_first;
    switch_next_hdr_type_t next_hdr_type;

    // switch_src_index_t src_index;

    bit<8> label_space;
    bit<8> ttl;
    bit<1> ilm;
    // add more
    bit<1> ttl_copy;
    // switch_pkt_type_t pkt_type;
    bit<2> dscp_sel;
    bit<6> inner_dscp;
    bit<8> tc;

    switch_netport_group_t src_netport_group;/* horizon split group,if src = dst,pkt drop*/
    switch_netport_group_t dst_netport_group;
    switch_ptag_mod_t ptag_igmod; /* ig pip ptag mode: 0: RAW, 1: TAGGED */
    switch_ptag_action_t ptag_eg_action; /* eg pip ptag action: 0: RAW, 1: REPLACE  2:NOREPLACE*/
    vlan_id_t ptag_vid;
    bit<16> ptag_tpid;
    bit<16> pw_id;
    bit<8> vc_ttl;
    bit<3> vc_exp;
    bit<3> exp;
    // bit<1> cw_mode;
    bit<1> bos;
    /* by lichunfeng */
    bit<16> ether_type;
    bit<20> first_label;
    bit<20> second_label;
    bit<20> third_label;
    bit<20> last_label;
    switch_drop_reason_t drop_reason;
    switch_egress_bypass_t bypass;
    bit<16> l4_encap;
    bit<24> vni;
    switch_lif_t tmp_l3iif;
    bit<4> srv6_end_type;
    bit<1> l3_encap_mapping_hit;
    bit<16> payload_len;
    bit<8> ip_proto;
    bit<16> gre_ether_type;
    bit<1> qosphb;
    bit<1> phpcopy;
    bit<4> opcode;
    bool vxlan_l4_encap_flag;
    bit<48> dst_addr;
    bool php_terminate;
    bit<8> php_ttl;
    bit<8> tmp_ttl;
    bit<1> is_php;
}

// Checks
/* add by xiachangkai */
struct switch_egress_checks_t {
    switch_lif_t same_if;
    switch_mtu_t mtu;
    // Add more checks here.
}

// @pa_container_size("pp_uplink", "egress", "eg_md.ebridge.l2oif", 16)
struct switch_egress_ebridge_metadata_t {
    // add more
    switch_evlan_t evlan;
    /* add more by xiachangkai */
    switch_egress_checks_t checks;
    switch_evlan_classid_t evlan_classid;
    switch_lif_t l2oif; // egress l2iif
    bool anycast_en;
    bit<15> oif_count_idx;
}

struct switch_egress_route_metadata_t {
    // add more
    /* by yangyi */
    bit<13> vrf;
    bool ipv4_unicast_enable;
    bool ipv6_unicast_enable;

    bit<1> rmac_hit;

    bit<16> pbr_nexthop;
    bit<8> pbr_priority;
    bit<1> pbr_is_ecmp;
    bit<2> pbr_level;

    bit<8> priority;
    bit<1> disable_urpf;
    bit<1> is_ecmp;
    bit<2> level;
    bit<8> priority_check;
    bit<8> sip_l3class_id;
    bit<8> dip_l3class_id;

    bit<8> drop_reason;

    bit<14> mpls_l3_encap_id;
    bit<16> iptunnel_l3_encap_id;
    bit<8> ttl_check;
    switch_lif_t l4_l3oif;
    bit<14> overlay_counter_index;
}

struct switch_egress_policer_metadata_t {
    // add more
    switch_egress_policer_slice_t slice1;
    switch_egress_policer_slice_t slice2;
    switch_egress_policer_slice_t slice3;
    switch_egress_policer_slice_t slice4;
    switch_egress_policer_slice_t slice5;
    switch_egress_policer_slice_t slice6;
    switch_egress_policer_slice_t slice7;
    switch_egress_policer_slice_t slice8;
    switch_policer_pbr_t pbr;
    switch_acl_bypass_t bypass;
    bit<1> drop;
    bit<1> mac_drop;
    bit<14> stats_id;
    bit<14> flowspec_stats_id;
    bit<14> qppb_stats_id;
    switch_pkt_color_t meter_color;
    bit<1> mirror_enable;
    switch_lif_t iif;
    switch_acl_classid_t group_classid_1;
    switch_acl_classid_t group_classid_2;
    switch_acl_classid_t group_classid_3;
    switch_acl_classid_t group_classid_4;
    switch_acl_classid_t v4_group_classid_1;
    switch_acl_classid_t v4_group_classid_2;
    switch_acl_classid_t v4_group_classid_3;
    switch_acl_classid_t v4_group_classid_4;
    switch_acl_classid_t v6_group_classid_1;
    switch_acl_classid_t v6_group_classid_2;
    switch_acl_classid_t v6_group_classid_3;
    switch_acl_classid_t v6_group_classid_4;
}

struct switch_egress_mirror_metadata_t {
    switch_pkt_src_t src;
    switch_mirror_type_t type;
    switch_mirror_session_t session_id;
    switch_mirror_session_t mirror_id;
    switch_pkt_color_t color;
    bit<1> span_flag;
    bit<1> sample_flag;
    bit<2> backpush_flag;
    bit<1> pcap_flag;
}

struct switch_egress_fabric_metadata_t {
    // add more
    switch_cpu_reason_t reason_code;
    switch_cpu_reason_t cpu_reason;
}

// Ingress metadata
struct switch_ingress_metadata_t {
    switch_ingress_common_metadata_t common;
    switch_ingress_flags_t flags;
    switch_lookup_fields_t lkp;
    switch_ingress_ebridge_metadata_t ebridge;
    switch_ingress_route_metadata_t route;
    switch_ingress_multicast_metadata_t multicast;
    switch_ingress_tunnel_metadata_t tunnel;
    switch_ingress_policer_metadata_t policer;
    switch_ingress_mirror_metadata_t mirror;
    switch_ingress_qos_metadata_t qos;
    switch_ingress_fabric_metadata_t fabric;

    switch_ingress_srv6_metadata_t srv6;

    switch_ipfix_metadata_t ipfix;
    switch_stp_metadata_t stp;
}

struct switch_egress_metadata_t {
    switch_egress_common_metadata_t common;
    switch_egress_flags_t flags;
    switch_lookup_fields_t lkp;
    switch_egress_ebridge_metadata_t ebridge;
    switch_egress_route_metadata_t route;
    switch_egress_multicast_metadata_t multicast;
    switch_egress_tunnel_metadata_t tunnel;
    switch_egress_policer_metadata_t policer;
    switch_egress_mirror_metadata_t mirror;
    switch_egress_qos_metadata_t qos;
    switch_egress_fabric_metadata_t fabric;
    switch_ipfix_metadata_t ipfix;
    switch_stp_metadata_t stp;
}

header switch_bridged_metadata_lookahead_h {
    switch_pkt_src_t src; // bit<3>
    switch_bridge_type_t type; // bit<5>
}

header switch_extension_lookahead_h {
    bit<3> ext_type;
    bit<1> extend;
    @padding bit<4> _pad;
}

header switch_bridged_src_h {
    switch_pkt_src_t src; // bit<3>
    switch_bridge_type_t bridge_type; // bit<5>
}

// as same as fabric_base_h
header switch_bridged_metadata_base_h {
    switch_pkt_type_t pkt_type;
    bit<1> is_mirror;
    bit<1> is_mcast;
}

header switch_bridged_metadata_base_encap_h {
    bit<8> data;
}

header switch_bridged_metadata_qos_encap_h {
    bit<8> data;
}

header switch_bridged_metadata_qos_h {
    bit<3> tc;
    bit<2> color;
    bit<1> chgDSCP_disable;
    bit<1> BA;
    bit<1> track;
}

// 13 byte
header switch_bridged_metadata_12_encap_h {
    bit<8> combine;
    // bit<1> extend;
    // bit<1> rmac_hit;
    // bit<1> escape_etm;
    // bit<1> ttl_copy;
    // bit<4> srv6_end_type;

    bit<8> combine2;
    // switch_iif_type_t iif_type;
    // switch_stp_state_t stp_state;
    // bit<1> svi_flag;
    // @padding bit<2> _pad0;
    // bit<3> tunnel_type;

    bit<8> src_port;
    bit<8> drop_reason;

    @padding bit<2> _pad1;
    switch_lif_t iif;
    @padding bit<1> _pad2;
    bit<1> car_flag;
    switch_lif_t ul_iif;

    bit<8> ttl;
    bit<8> label_space;
    bit<16> hash;
    bit<16> evlan;
    bit<16> egress_eport;
    bit<16> udf;
}

// 13 byte
header switch_bridged_metadata_12_h {
    bit<1> extend;
    bit<1> rmac_hit;
    bit<1> escape_etm;
    bit<1> ttl_copy;
    bit<4> srv6_end_type;

    switch_iif_type_t iif_type;
    switch_stp_state_t stp_state;
    bit<1> svi_flag;
    @padding bit<1> _pad0;
    bit<3> tunnel_type;

    bit<8> src_port;
    bit<8> drop_reason;

    @padding bit<2> _pad1;
    switch_lif_t iif;
    @padding bit<1> _pad2;
    bit<1> car_flag;
    switch_lif_t ul_iif;

    bit<8> ttl;
    bit<8> label_space;
    bit<16> hash;
    bit<16> evlan;
    bit<16> egress_eport;
    bit<16> udf;
}

// 14 byte
header switch_bridged_metadata_34_encap_h {
    bit<16> flags;
    // bit<1> extend;
    // bit<1> escape_etm;
    // bit<1> is_elephant;
    // bit<1> phpcopy;
    // bit<4> opcode;
    // bit<1> svi_flag;
    // bit<1> glean;
    // bit<1> drop;
    // bit<1> is_gleaned;
    // bit<1> is_eop;
    // bit<3> pad;

    bit<16> l2_encap;
    bit<16> l3_encap;
    bit<16> hash;

    @padding bit<2> pad;
    bit<14> overlay_counter_index;
    bit<16> cpu_code;

    // moved to fabric_crsp
    // bit<8> cpu_reason;
    // bit<8> src_port;    

    // moved to fabric_var_ext_1_16bit
    // bit<8> dip_l3class_id;
    // bit<8> sip_l3class_id;

    // moved to fabric_one_pad_3
    // @padding bit<2> pad_iif;
    // switch_lif_t iif;    
}

// 14 byte
header switch_bridged_metadata_34_h {
    bit<1> extend;
    bit<1> escape_etm;
    bit<1> is_elephant;
    bit<1> phpcopy;
    bit<4> opcode;
    bit<1> svi_flag;
    bit<1> glean;
    bit<1> drop;
    bit<1> is_gleaned;
    bit<1> is_eop;
    @padding bit<3> pad1;

    bit<16> l2_encap;
    bit<16> l3_encap;
    bit<16> hash;

    @padding bit<2> pad;
    bit<14> overlay_counter_index;
    bit<16> cpu_code;

    bit<8> cpu_reason;
    bit<8> src_port;

    bit<8> dip_l3class_id;
    bit<8> sip_l3class_id;

    @padding bit<2> pad_iif;
    switch_lif_t iif;
}

// 4 byte
@pa_container_size("pp_uplink", "ingress", "hdr.bridged_md_310_encap.pad_cpu_eth_encap_id", 16)
header switch_bridged_metadata_310_encap_h {
    bit<1> extend;
    bit<1> pad_oif;
    switch_lif_t oif;

    switch_cpu_eth_encap_id_t cpu_eth_encap_id;
    @padding bit<10> pad_cpu_eth_encap_id;

    // for below fields, either fabric_crsp_h or fabric_var_ext_1_16bit
    // moved to fabric_crsp_h
    // bit<8> cpu_reason;
    // bit<8> src_port;    
    // moved to fabric_var_ext_1_16bit
    // bit<8> dip_l3class_id;
    // bit<8> sip_l3class_id;    

    // moved to fabric_one_pad_3
    // bit<2> pad_iif;
    // switch_lif_t iif;    
}

// 8 byte
header switch_bridged_metadata_310_h {
    bit<1> extend;
    bit<1> pad_oif;
    switch_lif_t oif;

    switch_cpu_eth_encap_id_t cpu_eth_encap_id;
    @padding bit<10> pad_cpu_eth_encap_id;

    bit<16> var_h1;
    // for bfd
    // bit<8> cpu_reason;
    // bit<8> src_port;    
    // for ipfix_spec
    // bit<8> dip_l3class_id;
    // bit<8> sip_l3class_id;    

    bit<2> pad_iif;
    switch_lif_t iif;
}

// 14 byte
header switch_bridged_metadata_78_h {
    bit<16> combine;
    // bit<1> extend;
    // bit<1> pcp_chg;
    // bit<1> exp_chg;
    // bit<1> ippre_chg;
    // bit<1> is_from_cpu_pcie;
    // bit<1> is_elephant;
    // @padding bit<2> pad;
    // bit<8> dst_port;

    // below fields reuse fabric_unicast_ext_fe
    // bit<16> l2_encap;
    // bit<16> l3_encap;
    // bit<16> hash;

    // below fields reuse fabric_var_ext_1_16bit
    // bit<8> dip_l3class_id;
    // bit<8> sip_l3class_id;

    // below fields use fabric_one_pad_7
    // @padding bit<2> pad_iif;
    // switch_lif_t iif;

    // below fields use bridged_md_78_fqid
    // bit<16> fqid;
}

header switch_bridged_metadata_fqid_h {
    bit<16> fqid;
}

// 14 byte
header switch_bridged_metadata_78_parser_h {
    bit<1> extend;
    bit<1> pcp_chg;
    bit<1> exp_chg;
    bit<1> ippre_chg;
    bit<1> is_from_cpu_pcie;
    bit<1> is_elephant;
    @padding bit<2> pad;
    bit<8> dst_port;

    bit<16> l2_encap;
    bit<16> l3_encap;
    bit<16> hash;

    bit<8> dip_l3class_id;
    bit<8> sip_l3class_id;

    @padding bit<2> pad_iif;
    switch_lif_t iif;

    bit<16> fqid;
}

// 10 byte
header switch_bridged_metadata_74_h {
    @padding bit<64> pad_78;
    bit<16> evlan;
    // below fields use fabric_one_pad_7
    // @padding bit<2> pad_iif;
    // switch_lif_t iif;
}

// 12 byte
header switch_bridged_metadata_74_parser_h {
    @padding bit<64> pad_78;
    bit<16> evlan;
    @padding bit<2> pad_iif;
    switch_lif_t iif;
}

header switch_bridged_metadata_710_h {
    @padding bit<8> pad;
    bit<8> dst_port;
}

// 18 byte
// @pa_container_size("pp_downlink", "ingress", "hdr.bridged_md_910_encap.group_classid_3", 16)  /* for compile sucess */
// @pa_container_size("pp_downlink", "ingress", "hdr.bridged_md_910_encap.combine_16", 16)
header switch_bridged_metadata_910_encap_h {
    bit<16> combine_16;
    // bit<1> drop;
    // bit<2> ip_frag;
    // padding bit<1> pad;
    // switch_acl_bypass_t acl_bypass;
    // bit<8> dst_port;

    @padding bit<2> pad_iif;
    switch_lif_t iif;
    @padding bit<2> pad_oif;
    switch_lif_t oif;
    switch_acl_classid_t group_classid_1;
    switch_acl_classid_t group_classid_2;
    switch_acl_classid_t group_classid_3;
    bit<32> l4_port_label_32;
    bit<16> hash;
    bit<16> evlan;
}

// 18 byte
header switch_bridged_metadata_910_h {
    bit<1> drop;
    bit<2> ip_frag;
    @padding bit<1> pad;
    switch_acl_bypass_t acl_bypass;
    bit<8> dst_port;

    @padding bit<2> pad_iif;
    switch_lif_t iif;
    @padding bit<2> pad_oif;
    switch_lif_t oif;

    switch_acl_classid_t group_classid_1;
    switch_acl_classid_t group_classid_2;
    switch_acl_classid_t group_classid_3;
    bit<32> l4_port_label_32;
    bit<16> hash;
    bit<16> evlan;
}

header switch_bridged_metadata_110_h {
    bit<8> dst_port;
}

header extension_eth_h {
    bit<16> evlan;
    bit<2> pad_oif;
    switch_lif_t l2oif;
}

header extension_tunnel_decap_data_encap_h {
    bit<32> data;
    // bit<3> ext_type;
    // bit<1> extend;
    // @padding bit<4> pad;
    // bit<3> tunnel_type;
    // @padding bit<7> pad2;
    // switch_lif_t ul_iif;
}

@pa_container_size("pp_uplink", "ingress", "hdr.ext_tunnel_decap.tunnel_type", 16)
header extension_tunnel_decap_h {
    bit<3> ext_type;
    bit<1> extend;
    @padding bit<2> pad;
    switch_ext_data_type_t data_type;
    bit<3> tunnel_type;
    @padding bit<7> pad2;
    switch_lif_t ul_iif;
}

header extension_tunnel_decap_pad_h {
    bit<3> ext_type;
    bit<1> extend;
    @padding bit<28> pad;
}

@pa_container_size("pp_uplink", "ingress", "hdr.ext_l4_encap.l4_encap", 32)
header extension_l4_encap_h {
    bit<3> ext_type;
    bit<1> extend;
    @padding bit<4> pad1;
    @padding bit<8> pad2;
    bit<16> l4_encap;
}

header extension_l4_encap_pad_h {
    bit<3> ext_type;
    bit<1> extend;
    @padding bit<28> pad;
}

header extension_l4_nh_h {
    bit<3> ext_type;
    bit<1> extend;
    @padding bit<4> pad1;
    @padding bit<8> pad2;
    bit<16> l4_nh;
}

@pa_container_size("pp_uplink", "egress", "hdr.ext_srv6.nexthop", 16)
header extension_srv6_h {
    bit<3> ext_type;
    bit<1> extend;
    bool bypass_L3;
    bit<2> level;
    bit<1> is_ecmp;
    bit<8> priority;
    bit<16> nexthop;
    bit<8> tc;
    bit<1> set_dscp;
    @padding bit<7> pad;
}

header extension_cpp_h {
    bit<3> ext_type;
    bit<1> extend;
    @padding bit<4> pad1;
    @padding bit<6> pad2;
    bit<1> glean;
    bit<1> drop;
    bit<8> cpu_reason;
    bit<8> src_port;
}


header extension_fake_32bit_h {
    bit<16> data1;
    bit<16> data2;
}

// header extension_mirror_h {
//     bit<3> ext_type;
//     bit<1> extend;
//     @padding bit<2> pad;
//     bit<10> mirror_id;
//     bit<16> cpu_code;
// }

header extension_vlan_tags_h {
    bit<3> ext_type;
    bit<1> extend;
    @padding bit<4> pad;
    @padding bit<12> vid_1;
    bit<12> vid_0;
}

header extension_padding_word_h {
    bit<3> ext_type;
    bit<1> extend;
    @padding bit<28> pad;
}

header eg_fabric_extension_lookahead_h {
    bit<3> ext_type_0;
    bit<1> extend_0;
    bit<28> pad_0;
    bit<3> ext_type_1;
    bit<1> extend_1;
    bit<28> pad_1;
}

header eg_downlink_extension_lookahead_h {
    bit<3> ext_type_0;
    bit<1> extend_0;
    bit<28> pad_0;
    bit<3> ext_type_1;
    bit<1> extend_1;
    bit<28> pad_1;
}

// 14 byte
header switch_port_mirror_metadata_h {
    switch_pkt_src_t src;
    switch_mirror_type_t type;
    // bit<48> timestamp;



    switch_mirror_session_t session_id;
    bit<1> span_flag;
    bit<1> sample_flag;
    switch_lif_t iif;
    bit<2> backpush_flag;
    switch_lif_t oif;
    bit<16> cpu_code;
    bit<16> hash;
    switch_logic_port_t dst_port;
    switch_eport_t dst_eport;
}

header switch_fabric_port_mirror_metadata_h {
    switch_pkt_src_t src;
    switch_mirror_type_t type;
    // bit<48> timestamp;



    switch_mirror_session_t session_id;
    bit<1> span_flag;
    bit<1> sample_flag;
    switch_lif_t iif;
    bit<2> backpush_flag;
    switch_lif_t oif;
    bit<16> cpu_code;
    bit<16> hash;
    switch_logic_port_t fwd_dst_port;
    // parser as fabric_unicast_dst
    // bit<1> pad_dst;
    // bit<7> dst_device;
    // bit<8> dst_port;
}

// 5 byte
header switch_cpu_mirror_metadata_h {
    switch_pkt_src_t src;
    switch_mirror_type_t type;



    switch_mirror_session_t session_id;

    @padding bit<7> pad;
    bit<1> track;

    bit<8> cpu_reason;
}

// Trace Mirror Header -------------------------------------------------------------
// 10 byte
header switch_fabric_trace_mirror_metadata_h {
    switch_pkt_src_t src;
    switch_mirror_type_t type;
    // bit<48> timestamp;



    switch_mirror_session_t session_id;
    bit<16> cpu_code; // cpu_code[15:8] used as pipeline_location, cpu_code[7:0] used as dst_mirror_port
    bit<16> trace_counter;
    switch_drop_reason_t drop_reason;
    bit<16> hash;
}

// 18 byte
header switch_front_ingress_trace_mirror_metadata_plus_h {
    switch_pkt_src_t src;
    switch_mirror_type_t type;
    // bit<48> timestamp;



    switch_mirror_session_t session_id;
    bit<16> cpu_code; // cpu_code[15:8] used as pipeline_location, cpu_code[7:0] used as dst_mirror_port
    bit<16> trace_counter;
    switch_drop_reason_t drop_reason;
    bit<16> hash;

    @padding bit<7> pad_dev_port;
    bit<9> dev_port;
    bit<16> hash_pad;

    bit<32> timestamp;
}

// 18 byte
header switch_front_egress_trace_mirror_metadata_plus_h {
    switch_pkt_src_t src;
    switch_mirror_type_t type;
    // bit<48> timestamp;



    switch_mirror_session_t session_id;
    bit<16> cpu_code; // cpu_code[15:8] used as pipeline_location, cpu_code[7:0] used as dst_mirror_port
    bit<16> trace_counter;
    switch_drop_reason_t drop_reason;
    bit<16> hash;

    @padding bit<13> _pad1;
    bit<19> qdepth;

    bit<32> timestamp;
}

//10 byte
header switch_pipe_trace_mirror_metadata_h {
    switch_pkt_src_t src;
    switch_mirror_type_t type;



    switch_mirror_session_t session_id;
    switch_pipeline_location_t pipeline_location;
    switch_logic_port_t dst_mirror_port;
    bit<16> trace_counter;
    switch_drop_reason_t drop_reason;
    bit<16> hash;
}

// 14 byte
header switch_pipe_trace_mirror_metadata_plus_h {
    switch_pkt_src_t src;
    switch_mirror_type_t type;



    switch_mirror_session_t session_id;
    switch_pipeline_location_t pipeline_location;
    switch_logic_port_t dst_mirror_port;
    bit<16> trace_counter;
    switch_drop_reason_t drop_reason;
    bit<16> hash;
    bit<32> timestamp;
}

// 18 byte
header switch_uplink_ingress_trace_mirror_metadata_plus_h {
    switch_pkt_src_t src;
    switch_mirror_type_t type;



    switch_mirror_session_t session_id;
    // switch_pipeline_location_t pipeline_location;
    // switch_logic_port_t dst_mirror_port;
    // bit<16> trace_counter;
    bit<32> trace_32;
    switch_drop_reason_t drop_reason;
    bit<16> hash;

    @padding bit<7> pad_dev_port;
    bit<9> dev_port;
    // bit<8> pipe_local;
    // bit<8> dst_mir_port; 
    bit<16> hash_pad;

    bit<32> timestamp;
}

// 18 byte
header switch_uplink_egress_trace_mirror_metadata_plus_h {
    switch_pkt_src_t src;
    switch_mirror_type_t type;



    switch_mirror_session_t session_id;
    // switch_pipeline_location_t pipeline_location;
    // switch_logic_port_t dst_mirror_port;
    // bit<16> trace_counter;
    bit<32> trace_32;
    switch_drop_reason_t drop_reason;
    bit<16> hash;

    @padding bit<13> _pad1;
    bit<19> qdepth;

    bit<32> timestamp;
}

// 18 byte
header switch_fabric_ingress_trace_mirror_metadata_plus_h {
    switch_pkt_src_t src;
    switch_mirror_type_t type;



    switch_mirror_session_t session_id;
    switch_pipeline_location_t pipeline_location;
    switch_logic_port_t dst_mirror_port;
    bit<16> trace_counter;
    switch_drop_reason_t drop_reason;
    bit<16> hash;

    @padding bit<7> pad_dev_port;
    bit<9> dev_port;
    bit<16> hash_pad;

    bit<32> timestamp;
}

// 18 byte
header switch_fabric_egress_trace_mirror_metadata_plus_h {
    switch_pkt_src_t src;
    switch_mirror_type_t type;



    switch_mirror_session_t session_id;
    switch_pipeline_location_t pipeline_location;
    switch_logic_port_t dst_mirror_port;
    bit<16> trace_counter;
    switch_drop_reason_t drop_reason;
    bit<16> hash;

    @padding bit<13> _pad1;
    bit<19> qdepth;

    bit<32> timestamp;
}

// 18 byte
header switch_downlink_ingress_trace_mirror_metadata_plus_h {
    switch_pkt_src_t src;
    switch_mirror_type_t type;



    switch_mirror_session_t session_id;
    bit<16> trace_location_dport;
    // switch_pipeline_location_t pipeline_location;
    // switch_logic_port_t dst_mirror_port;
    bit<16> trace_counter;
    switch_drop_reason_t drop_reason;
    bit<16> hash;

    @padding bit<7> pad_dev_port;
    bit<9> dev_port;
    bit<16> hash_pad;

    bit<32> timestamp;
}

// 18 byte
header switch_downlink_egress_trace_mirror_metadata_plus_h {
    switch_pkt_src_t src;
    switch_mirror_type_t type;



    switch_mirror_session_t session_id;
    bit<16> trace_location_dport;
    // switch_pipeline_location_t pipeline_location;
    // switch_logic_port_t dst_mirror_port;
    bit<16> trace_counter;
    switch_drop_reason_t drop_reason;
    bit<16> hash;

    @padding bit<13> _pad1;
    bit<19> qdepth;

    bit<32> timestamp;
}
// ---------------------------------------------------------------------------------

// 9 byte
/* by yeweixin */
header switch_ipfix_mirror_metadata_h {
    switch_pkt_src_t src;
    switch_mirror_type_t type;



    switch_mirror_session_t session_id;
    @padding bit<2> pad_iif;
    switch_lif_t iif;
    @padding bit<2> pad_oif;
    switch_lif_t oif;
    bit<16> hash;
}

// 13 byte
header switch_learning_mirror_metadata_h {
    switch_pkt_src_t src;
    switch_mirror_type_t type;



    switch_mirror_session_t session_id;
    @padding bit<2> _pad2;
    switch_lif_t iif;
    bit<16> evlan;
    bit<48> mac;
}

// 5 byte
header switch_learning_mirror_metadata_parser_h {
    switch_pkt_src_t src;
    switch_mirror_type_t type;



    switch_mirror_session_t session_id;
    @padding bit<2> _pad2;
    switch_lif_t iif;
    bit<16> evlan;
    // below fields used as fabric_learning_h
    // bit<48> mac;
}


// header switch_pcap_mirror_metadata_h {
//     switch_pkt_src_t src;
//     switch_mirror_type_t type;
//     bit<16> cpu_code;
// }

header switch_recirc_h {
    switch_logic_port_t src_port; //bit<8>
    bit<7> pad;
    switch_port_t egress_port; //bit<9>
    switch_eport_t eport; //bit<16>
    bit<16> ether_type;
}

header parser_pad_h {
    bit<1> extend;
    bit<7> data;
}

// @pa_mutually_exclusive("pp_fabric", "ingress", "hdr.ext_l4_encap.ext_type", "hdr.ext_l4_encap_pad.ext_type")
// @pa_mutually_exclusive("pp_fabric", "ingress", "hdr.ext_tunnel_decap.ext_type", "hdr.ext_tunnel_decap_pad.ext_type")
@pa_mutually_exclusive("pp_downlink", "egress", "hdr.ipv4.ttl", "hdr.ipv6.hop_limit") /* for compile sucess */
@pa_mutually_exclusive("pp_downlink", "egress", "hdr.ipv4.protocol", "hdr.ipv6.next_hdr") /* for compile sucess */
@pa_no_overlay("pp_downlink", "egress", "hdr.mpls_vc_eg.label")
@pa_no_overlay("pp_downlink", "egress", "hdr.mpls_vc_eg.ttl")
struct switch_header_t {
    switch_bridged_src_h switch_bridged_src;

    fabric_base_h fabric_base;
    switch_bridged_metadata_base_h bridged_md_base;
    switch_bridged_metadata_base_encap_h bridged_md_base_encap;

    fabric_qos_h fabric_qos;
    switch_bridged_metadata_qos_h bridged_md_qos;
    switch_bridged_metadata_qos_encap_h bridged_md_qos_encap;
    fabric_cpu_pcie_base_h fabric_cpu_pcie_base;

    switch_bridged_metadata_12_encap_h bridged_md_12_encap;
    switch_bridged_metadata_12_h bridged_md_12;
    switch_bridged_metadata_34_encap_h bridged_md_34_encap;
    switch_bridged_metadata_34_h bridged_md_34;
    switch_bridged_metadata_310_encap_h bridged_md_310_encap;
    switch_bridged_metadata_310_h bridged_md_310;
    switch_bridged_metadata_78_h bridged_md_78;
    switch_bridged_metadata_fqid_h bridged_md_78_fqid;
    switch_bridged_metadata_74_h bridged_md_74;
    switch_bridged_metadata_910_encap_h bridged_md_910_encap;
    switch_bridged_metadata_910_h bridged_md_910;
    switch_bridged_metadata_110_h bridged_md_110;

    fabric_unicast_ext_bfn_igfpga_h fabric_unicast_ext_bfn_igfpga; // bfn-igfpga
    fabric_unicast_ext_igfpga_bfn_h fabric_unicast_ext_igfpga_bfn; // igfpga-bfn
    fabric_crsp_h fabric_crsp;
    fabric_nexthop_h fabric_nexthop;

    fabric_unicast_dst_encap_h fabric_unicast_dst_encap; // lc-fe
    fabric_unicast_dst_h fabric_unicast_dst; // fe-lc
    fabric_unicast_ext_fe_encap_h fabric_unicast_ext_fe_encap; // lc-fe
    fabric_unicast_ext_fe_h fabric_unicast_ext_fe; // fe-lc
    fabric_var_ext_1_16bit_h fabric_var_ext_1_16bit; // ig/fe
    fabric_var_ext_2_8bit_h fabric_var_ext_2_8bit; // ig/fe

    fabric_multicast_src_h fabric_multicast_src; // lc-fe
    fabric_multicast_src_encap_h fabric_multicast_src_encap; // lc-fe
    fabric_multicast_ext_h fabric_multicast_ext; // fe-lc

    fabric_unicast_ext_eg_encap_h fabric_unicast_ext_eg_encap; // bfn-egfpga
    fabric_unicast_ext_eg_h fabric_unicast_ext_eg; // egfpga-bfn

    fabric_to_cpu_data_h fabric_to_cpu_data;
    fabric_from_cpu_data_h fabric_from_cpu_data;

    fabric_one_pad_h fabric_one_pad;
    fabric_one_pad_3_h fabric_one_pad_3;
    fabric_one_pad_7_h fabric_one_pad_7;
    pcie_one_pad_h pcie_one_pad;

    fabric_unicast_ext_fe_2_encap_h fabric_unicast_ext_fe_2_encap;
    fabric_unicast_ext_fe_2_h fabric_unicast_ext_fe_2;

    fabric_var_ext_1_16bit_h fabric_post_one_pad_encap;
    fabric_post_one_pad_h fabric_post_one_pad;
    fabric_eth_ext_h fabric_eth_ext;
    fabric_eth_ext_encap_h fabric_eth_ext_encap;

    extension_srv6_h ext_srv6;
    extension_l4_nh_h ext_l4_nh;
    extension_cpp_h ext_cpp;
    extension_l4_encap_h ext_l4_encap;
    extension_l4_encap_pad_h ext_l4_encap_pad;
    extension_tunnel_decap_data_encap_h ext_tunnel_decap_data_encap;
    extension_tunnel_decap_h ext_tunnel_decap; // tunnel decap header placed last
    extension_tunnel_decap_pad_h ext_tunnel_decap_pad; // tunnel decap header placed last
    extension_padding_word_h ext_padding_word; // only for 64B packet padding
    extension_eth_h ext_eth; // place last, no extend mark, only for eth
    extension_fake_32bit_h ext_fake;
    fabric_learning_h fabric_learning;

    ethernet_h ethernet;
    /* by caixiaoxiang */
    switch_recirc_h pri_data;

    fabric_to_cpu_eth_base_h fabric_to_cpu_eth_base;
    fabric_to_cpu_eth_data_h fabric_to_cpu_eth_data;

    fabric_from_cpu_eth_base_h fabric_from_cpu_eth_base;
    fabric_from_cpu_eth_data_h fabric_from_cpu_eth_data;
    fabric_from_cpu_eth_ccm_h fabric_from_cpu_eth_ccm;

    fabric_payload_h fabric_eth_etype;

    timestamp_h timestamp;
    br_tag_h br_tag;
    vlan_tag_h[2] vlan_tag;
    mpls_h[6] mpls_ig;
    mpls_h[4] mpls2_ig;
    mpls_h[9] mpls_eg;
    mpls_h[10] mpls_fabric_ig;
    mpls_h mpls_vc_eg;
    mpls_h mpls_flow_eg;
    drop_msg_h[2] drop_msg; // by zhuanghui
    pause_info_h pause_info; // by zhuanghui
    cw_h cw;
    ipv4_h ipv4;
    ipv4_option_h ipv4_option;
    ipv6_h ipv6;
    ipv6_fragment_h ipv6_frag;
    ipv6_srh_h srv6_srh;
    srv6_list_h[10] srv6_list;
    arp_h arp;
    udp_h udp;
    icmp_h icmp;
    igmp_h igmp;
    tcp_h tcp;
    vxlan_h vxlan;
    gre_h gre;
    nvgre_h nvgre;
    geneve_h geneve;
    erspan_h erspan;
    erspan_type2_h erspan_type2;
    erspan_type3_h erspan_type3;
    erspan_platform_h erspan_platform;
    ethernet_h inner_ethernet;
    vlan_tag_h[2] inner_vlan_tag;
    ipv4_h inner_ipv4;
    ipv4_option_h inner_ipv4_option;
    ipv6_h inner_ipv6;
    ipv6_fragment_h inner_ipv6_frag;
    udp_h inner_udp;
    tcp_h inner_tcp;
    icmp_h inner_icmp;
    advance_pad112_h advance_pad112;
    advance_pad64_h advance_pad64;
}
# 181 "/mnt/p4c-4127/p4src/switch-tofino2/switch_tofino_x1.p4" 2
# 1 "/mnt/p4c-4127/p4src/shared/util.p4" 1
/*******************************************************************************
 * BAREFOOT NETWORKS CONFIDENTIAL & PROPRIETARY
 *
 * Copyright (c) 2015-2019 Barefoot Networks, Inc.

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
 ******************************************************************************/

# 1 "/mnt/p4c-4127/p4src/shared/types.p4" 1
/*******************************************************************************
 * BAREFOOT NETWORKS CONFIDENTIAL & PROPRIETARY
 *
 * Copyright (c) 2015-2019 Barefoot Networks, Inc.

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
 ******************************************************************************/
# 24 "/mnt/p4c-4127/p4src/shared/util.p4" 2

// Bridged metadata fields for Egress pipeline.
action add_ext_tunnel_decap(
        inout switch_header_t hdr,
        inout switch_ingress_metadata_t ig_md) {
    ig_md.common.extend = 1w1;
    hdr.ext_tunnel_decap_data_encap.setValid();
}

action add_ext_l4_encap(
        inout switch_header_t hdr,
        inout switch_ingress_metadata_t ig_md,
        bit<1> extend, bit<16> l4_encap) {
    ig_md.common.extend = 1w1;
    hdr.ext_l4_encap.setValid();
    hdr.ext_l4_encap.ext_type = FABRIC_EXT_TYPE_L4_ENCAP;
    hdr.ext_l4_encap.extend = extend;
    hdr.ext_l4_encap.l4_encap = l4_encap;
}

action add_ext_srv6(
        inout switch_header_t hdr,
        in switch_ingress_metadata_t ig_md,
        bit<1> extend,
        bool bypass_L3,
        bit<2> level,
        bit<1> is_ecmp,
        bit<8> priority,
        bit<16> nexthop,
        bit<1> set_dscp,
        bit<8> tc) {
    hdr.ext_srv6.setValid();
    hdr.ext_srv6.ext_type = BRIDGED_MD_EXT_TYPE_SRV6;
    hdr.ext_srv6.extend = extend;
    hdr.ext_srv6.bypass_L3 = bypass_L3;
    hdr.ext_srv6.level = level;
    hdr.ext_srv6.is_ecmp = is_ecmp;
    hdr.ext_srv6.priority = priority;
    hdr.ext_srv6.nexthop = nexthop;
    hdr.ext_srv6.set_dscp = set_dscp;
    hdr.ext_srv6.tc = tc;
}

action init_bridge_type(
        inout switch_ingress_metadata_t ig_md,
        switch_bridge_type_t bridge_type) {
    ig_md.common.bridge_type = bridge_type;
}

control BridgedMetadata_FRONT(
        inout switch_header_t hdr,
        in switch_ingress_metadata_t ig_md) {

    Hash<bit<8>>(HashAlgorithm_t.IDENTITY) hash_8;
    Hash<bit<8>>(HashAlgorithm_t.IDENTITY) hash_combine;
    Hash<bit<8>>(HashAlgorithm_t.IDENTITY) hash_combine2;
    // Hash<bit<16>>(HashAlgorithm_t.IDENTITY) hash_16;

    action add_bridged_md_uc_base(switch_bridge_type_t bridge_type) {
        hdr.switch_bridged_src.setValid();
        hdr.switch_bridged_src.src = SWITCH_PKT_SRC_BRIDGED;
        hdr.switch_bridged_src.bridge_type = bridge_type;
        hdr.bridged_md_base.setValid();
        hdr.bridged_md_base.pkt_type = ig_md.common.pkt_type;
        hdr.bridged_md_base.is_mirror = 0;
        hdr.bridged_md_base.is_mcast = 0;
    }

    action add_bridged_md_pipe12() {
        add_bridged_md_uc_base(BRIDGE_TYPE_FRONT_UPLINK);
        hdr.bridged_md_qos_encap.setValid();
        hdr.bridged_md_qos_encap.data = hash_8.get({
            ig_md.qos.tc +++
            ig_md.qos.color +++
            ig_md.qos.chgDSCP_disable +++
            ig_md.qos.BA +++
            ig_md.common.track});
        hdr.bridged_md_12_encap.setValid();
        hdr.bridged_md_12_encap.combine = hash_combine.get({
            ig_md.common.extend +++
            ig_md.route.rmac_hit +++
            ig_md.flags.escape_etm +++
            ig_md.tunnel.ttl_copy +++
            ig_md.tunnel.srv6_end_type});
        hdr.bridged_md_12_encap.combine2 = hash_combine2.get({
            ig_md.common.iif_type +++
            ig_md.stp.state +++
            ig_md.common.svi_flag +++
            1w0 +++
            ig_md.tunnel.type
        });
        hdr.bridged_md_12_encap.src_port = ig_md.common.src_port;
        hdr.bridged_md_12_encap.drop_reason = ig_md.common.drop_reason;
        hdr.bridged_md_12_encap.iif = ig_md.common.iif;
        hdr.bridged_md_12_encap.car_flag = ig_md.qos.car_flag;
        // hdr.bridged_md_12_encap.ul_iif = ig_md.common.ul_iif;//assignment in port_to_lif_mapping
        hdr.bridged_md_12_encap.ttl = ig_md.tunnel.ttl;
        hdr.bridged_md_12_encap.label_space = 0;
        hdr.bridged_md_12_encap.hash = ig_md.common.hash[15:0];
        hdr.bridged_md_12_encap.evlan = ig_md.ebridge.evlan;
        hdr.bridged_md_12_encap.egress_eport = ig_md.common.egress_eport;
        hdr.bridged_md_12_encap.udf = ig_md.common.udf[15:0];
    }

    action add_bridged_md_pipe110() {
        add_bridged_md_uc_base(BRIDGE_TYPE_FRONT_FRONT);
        hdr.bridged_md_qos_encap.setValid();
        hdr.bridged_md_qos_encap.data = hash_8.get({
            ig_md.qos.tc +++
            ig_md.qos.color +++
            ig_md.qos.chgDSCP_disable +++
            ig_md.qos.BA +++
            ig_md.common.track});
        hdr.bridged_md_110.setValid();
        hdr.bridged_md_110.dst_port = ig_md.common.dst_port;
    }

    table add_bridged_md {
        key = {
            ig_md.common.bridge_type : exact;
        }
        actions = {
            NoAction;
            add_bridged_md_pipe12;
            add_bridged_md_pipe110;
        }
        const default_action = NoAction;
        size = 8;
        const entries = {
            (BRIDGE_TYPE_DEFAULT) : add_bridged_md_pipe12();
            // (BRIDGE_TYPE_FRONT_UPLINK) : add_bridged_md_pipe12();
            (BRIDGE_TYPE_FRONT_FRONT) : add_bridged_md_pipe110();
        }
    }

    apply {
        add_bridged_md.apply();
    }
}

control BridgedMetadata_extend_FRONT(
        inout switch_header_t hdr,
        in switch_ingress_metadata_t ig_md) {

    Hash<bit<32>>(HashAlgorithm_t.IDENTITY) hash_32;

    action encode_ext_tunnel_decap() {
        hdr.ext_tunnel_decap_data_encap.data = hash_32.get({
            FABRIC_EXT_TYPE_TUNNEL_DECAP +++
            5w0 +++
            ig_md.tunnel.type +++
            7w0 +++
            ig_md.common.ul_iif});
    }

    table fill_ext_tunnel_decap {
        key = {
            hdr.ext_tunnel_decap_data_encap.isValid() : exact;
        }
        actions = {
            NoAction;
            encode_ext_tunnel_decap;
        }
        const default_action = NoAction;
        size = 4;
        // const entries = {
        //     (true) : encode_ext_tunnel_decap();
        //     (false) : NoAction();
        // }        
    }

    action set_srv6_extend_bit() {
        hdr.ext_srv6.extend = 1w1;
    }

    table set_extend_bit {
        key = {
            hdr.ext_tunnel_decap_data_encap.isValid() : exact;
            hdr.ext_srv6.isValid() : exact;
        }
        actions = {
            NoAction;
            set_srv6_extend_bit;
        }
        const default_action = NoAction;
        size = 4;
        const entries = {
            (true, true) : set_srv6_extend_bit();
            (true, false) : NoAction();
        }
    }

    apply {
        fill_ext_tunnel_decap.apply();
        set_extend_bit.apply();
    }
}

control BridgedMetadata_UPLINK(
        inout switch_header_t hdr,
        in switch_ingress_metadata_t ig_md) {

    Hash<bit<16>>(HashAlgorithm_t.IDENTITY) hash_16;
    Hash<bit<14>>(HashAlgorithm_t.IDENTITY) hash_14;

    action add_bridged_md_base_uplink(switch_bridge_type_t bridge_type) {
        hdr.switch_bridged_src.setValid();
        hdr.switch_bridged_src.src = SWITCH_PKT_SRC_BRIDGED;
        hdr.switch_bridged_src.bridge_type = bridge_type;
        // reuse fabric_base
    }

    action add_bridged_md_qos() {
        hdr.fabric_qos.setValid();
        // hdr.fabric_qos.tc = ig_md.qos.tc;
        // hdr.fabric_qos.color = ig_md.qos.color;
        // hdr.fabric_qos.chgDSCP_disable = ig_md.qos.chgDSCP_disable;
        // hdr.fabric_qos.BA = ig_md.qos.BA;
        // hdr.fabric_qos.track = ig_md.common.track;
    }

    action add_bridged_unicast_dst() {
        hdr.fabric_unicast_dst.setValid();
        hdr.fabric_unicast_dst.extend = ig_md.common.extend;
        hdr.fabric_unicast_dst.dst_device = ig_md.common.dst_device;
        hdr.fabric_unicast_dst.dst_port = ig_md.common.dst_port;
    }

    action add_bridged_md_pipe34() {
        add_bridged_md_base_uplink(BRIDGE_TYPE_UPLINK_FABRIC);
        add_bridged_md_qos();
        add_bridged_unicast_dst();
        hdr.bridged_md_34_encap.setValid();
        hdr.bridged_md_34_encap.flags = hash_16.get({
            ig_md.common.extend +++
            ig_md.flags.escape_etm +++
            ig_md.flags.is_elephant +++
            ig_md.tunnel.phpcopy +++
            ig_md.tunnel.opcode +++
            ig_md.common.svi_flag +++
            ig_md.flags.glean +++
            ig_md.flags.drop +++
            ig_md.flags.is_gleaned +++
            ig_md.flags.is_eop +++
            3w0});
        hdr.bridged_md_34_encap.l2_encap = ig_md.common.ul_nhid;
        hdr.bridged_md_34_encap.l3_encap = ig_md.common.ol_nhid;
        hdr.bridged_md_34_encap.hash = ig_md.common.sn[15:0];
        hdr.bridged_md_34_encap.overlay_counter_index = ig_md.route.overlay_counter_index;
        hdr.bridged_md_34_encap.cpu_code = ig_md.common.cpu_code;
        // reuse fabric_crsp
        // hdr.bridged_md_34_encap.cpu_reason = ig_md.common.cpu_reason;
        // hdr.bridged_md_34_encap.src_port = ig_md.common.src_port;
        // reuse fabric_var_ext_1_16bit
        // hdr.bridged_md_34_encap.dip_l3class_id = ig_md.route.dip_l3class_id;
        // hdr.bridged_md_34_encap.sip_l3class_id = ig_md.route.sip_l3class_id;
        // reuse fabric_one_pad_3
        // hdr.bridged_md_34_encap.iif = ig_md.common.iif;        
    }

    action add_ext_eth() {
        // reuse fabric_eth_ext
        // hdr.fabric_eth_ext.l2_flag = 1w0;
        // hdr.ext_eth.setValid();
        // hdr.ext_eth.evlan = ig_md.ebridge.evlan;
        // hdr.ext_eth.l2oif = ig_md.ebridge.l2oif;
    }

    action add_bridged_md_pipe34_eth() {
        add_bridged_md_pipe34();
        add_ext_eth();
    }

    action add_bridged_md_pipe34_mc() {
        add_bridged_md_base_uplink(BRIDGE_TYPE_UPLINK_FABRIC);
        add_bridged_md_qos();
        add_bridged_unicast_dst();
        hdr.bridged_md_34_encap.setValid();
        hdr.bridged_md_34_encap.flags = hash_16.get({
            ig_md.common.extend +++
            ig_md.flags.escape_etm +++
            ig_md.flags.is_elephant +++
            ig_md.tunnel.phpcopy +++
            ig_md.tunnel.opcode +++
            ig_md.common.svi_flag +++
            ig_md.flags.glean +++
            ig_md.flags.drop +++
            ig_md.flags.is_gleaned +++
            ig_md.flags.is_eop +++
            3w0});
        hdr.bridged_md_34_encap.l2_encap = ig_md.common.ul_nhid;
        hdr.bridged_md_34_encap.l3_encap = ig_md.common.ol_nhid;
        hdr.bridged_md_34_encap.hash = 0;
        hdr.bridged_md_34_encap.cpu_code = ig_md.common.cpu_code;
        // reuse fabric_crsp
        // hdr.bridged_md_34_encap.cpu_reason = ig_md.common.cpu_reason;
        // hdr.bridged_md_34_encap.src_port = ig_md.common.src_port;  
        // reuse fabric_var_ext_1_16bit
        // hdr.bridged_md_34_encap.dip_l3class_id = ig_md.route.dip_l3class_id;
        // hdr.bridged_md_34_encap.sip_l3class_id = ig_md.route.sip_l3class_id;
        // reuse fabric_one_pad_3
        // hdr.bridged_md_34_encap.iif = ig_md.common.iif;        
    }

    action add_bridged_md_pipe34_mc_eth() {
        add_bridged_md_pipe34_mc();
        add_ext_eth();
    }

    action add_bridged_md_pipe310_bfd(switch_cpu_eth_encap_id_t cpu_eth_encap_id) {
        add_bridged_md_base_uplink(BRIDGE_TYPE_UPLINK_FRONT);
        add_bridged_md_qos();
        hdr.bridged_md_310_encap.setValid();
        hdr.bridged_md_310_encap.cpu_eth_encap_id = cpu_eth_encap_id;
        // reuse fabric_crsp
        // hdr.bridged_md_310.cpu_reason = ig_md.common.cpu_reason;
        // hdr.bridged_md_310.src_port = ig_md.common.src_port;
        // reuse fabric_one_pad_3
        // hdr.bridged_md_310.iif = ig_md.common.iif;
        hdr.fabric_var_ext_1_16bit.setInvalid();// no need of d(s)ip_l3class_id
    }

    action add_bridged_md_pipe310_bfd_eth() {
        add_bridged_md_pipe310_bfd(CPU_ETH_ENCAP_BFD_ETH);
        hdr.fabric_eth_ext.setInvalid();
    }

    action add_bridged_md_pipe310_bfd_v4() {
        add_bridged_md_pipe310_bfd(CPU_ETH_ENCAP_BFD_IPV4);
    }

    action add_bridged_md_pipe310_bfd_v6() {
        add_bridged_md_pipe310_bfd(CPU_ETH_ENCAP_BFD_IPV6);
    }

    action add_bridged_md_pipe310_ipfix_spec_v4() {
        add_bridged_md_base_uplink(BRIDGE_TYPE_UPLINK_FRONT);
        add_bridged_md_qos();
        hdr.bridged_md_310_encap.setValid();
        hdr.bridged_md_310_encap.oif = hash_14.get({ig_md.route.l2_l3oif});// to evade ig_md.flags.glean evaluation
        // reuse fabric_var_ext_1_16bit
        // hdr.bridged_md_310_encap.dip_l3class_id = ig_md.route.dip_l3class_id;
        // hdr.bridged_md_310_encap.sip_l3class_id = ig_md.route.sip_l3class_id;
        hdr.bridged_md_310_encap.cpu_eth_encap_id = CPU_ETH_ENCAP_IPFIX_SPEC_V4;
        hdr.fabric_crsp.setInvalid();// no need of fabric_crsp
    }

    action add_bridged_md_pipe310_ipfix_spec_v6() {
        add_bridged_md_base_uplink(BRIDGE_TYPE_UPLINK_FRONT);
        add_bridged_md_qos();
        hdr.bridged_md_310_encap.setValid();
        hdr.bridged_md_310_encap.oif = hash_14.get(ig_md.route.l2_l3oif);// to evade ig_md.flags.glean evaluation
        // reuse fabric_var_ext_1_16bit
        // hdr.bridged_md_310_encap.dip_l3class_id = ig_md.route.dip_l3class_id;
        // hdr.bridged_md_310_encap.sip_l3class_id = ig_md.route.sip_l3class_id;
        hdr.bridged_md_310_encap.cpu_eth_encap_id = CPU_ETH_ENCAP_IPFIX_SPEC_V6;
        hdr.fabric_crsp.setInvalid();// no need of fabric_crsp
    }

    table add_bridged_md {
        key = {
            ig_md.common.bridge_type : exact;
            hdr.fabric_base.pkt_type : ternary;
            hdr.fabric_base.is_mcast : exact;
        }
        actions = {
            NoAction;
            add_bridged_md_pipe34;
            add_bridged_md_pipe34_eth;
            add_bridged_md_pipe34_mc;
            add_bridged_md_pipe34_mc_eth;
            add_bridged_md_pipe310_bfd_eth;
            add_bridged_md_pipe310_bfd_v4;
            add_bridged_md_pipe310_bfd_v6;
            add_bridged_md_pipe310_ipfix_spec_v4;
            add_bridged_md_pipe310_ipfix_spec_v6;
        }
        const default_action = NoAction;
        size = 32;
        const entries = {
            // (BRIDGE_TYPE_DEFAULT, FABRIC_PKT_TYPE_ETH, 0) : add_bridged_md_pipe34_eth();
            // (BRIDGE_TYPE_DEFAULT, FABRIC_PKT_TYPE_IPV4, 0) : add_bridged_md_pipe34();
            // (BRIDGE_TYPE_DEFAULT, FABRIC_PKT_TYPE_IPV6, 0) : add_bridged_md_pipe34();
            // (BRIDGE_TYPE_DEFAULT, FABRIC_PKT_TYPE_MPLS, 0) : add_bridged_md_pipe34();
            // (BRIDGE_TYPE_DEFAULT, FABRIC_PKT_TYPE_CPU_ETH, 0) : add_bridged_md_pipe34();
            // (BRIDGE_TYPE_DEFAULT, FABRIC_PKT_TYPE_ETH, 1) : add_bridged_md_pipe34_mc();
            // (BRIDGE_TYPE_DEFAULT, FABRIC_PKT_TYPE_IPV4, 1) : add_bridged_md_pipe34_mc();
            // (BRIDGE_TYPE_DEFAULT, FABRIC_PKT_TYPE_IPV6, 1) : add_bridged_md_pipe34_mc();

            (BRIDGE_TYPE_UPLINK_FABRIC, FABRIC_PKT_TYPE_ETH, 0) : add_bridged_md_pipe34_eth();
            // (BRIDGE_TYPE_UPLINK_FABRIC, FABRIC_PKT_TYPE_IPV4, 0) : add_bridged_md_pipe34();
            // (BRIDGE_TYPE_UPLINK_FABRIC, FABRIC_PKT_TYPE_IPV6, 0) : add_bridged_md_pipe34();
            // (BRIDGE_TYPE_UPLINK_FABRIC, FABRIC_PKT_TYPE_MPLS, 0) : add_bridged_md_pipe34();
            // (BRIDGE_TYPE_UPLINK_FABRIC, FABRIC_PKT_TYPE_CPU_ETH, 0) : add_bridged_md_pipe34();
            (BRIDGE_TYPE_UPLINK_FABRIC, _, 0) : add_bridged_md_pipe34();
            (BRIDGE_TYPE_UPLINK_FABRIC, FABRIC_PKT_TYPE_ETH, 1) : add_bridged_md_pipe34_mc_eth();
            // (BRIDGE_TYPE_UPLINK_FABRIC, FABRIC_PKT_TYPE_IPV4, 1) : add_bridged_md_pipe34_mc();
            // (BRIDGE_TYPE_UPLINK_FABRIC, FABRIC_PKT_TYPE_IPV6, 1) : add_bridged_md_pipe34_mc();
            (BRIDGE_TYPE_UPLINK_FABRIC, _, 1) : add_bridged_md_pipe34_mc();

            (BRIDGE_TYPE_UPLINK_FRONT, FABRIC_PKT_TYPE_IPFIX_SPEC_V4, 0) : add_bridged_md_pipe310_ipfix_spec_v4();
            (BRIDGE_TYPE_UPLINK_FRONT, FABRIC_PKT_TYPE_IPFIX_SPEC_V6, 0) : add_bridged_md_pipe310_ipfix_spec_v6();
            // (BRIDGE_TYPE_UPLINK_FRONT, _, 0) : add_bridged_md_pipe310();
            (BRIDGE_TYPE_UPLINK_FRONT, FABRIC_PKT_TYPE_ETH, 0) : add_bridged_md_pipe310_bfd_eth();
            (BRIDGE_TYPE_UPLINK_FRONT, FABRIC_PKT_TYPE_ETH, 1) : add_bridged_md_pipe310_bfd_eth();
            (BRIDGE_TYPE_UPLINK_FRONT, FABRIC_PKT_TYPE_IPV4, 1) : add_bridged_md_pipe310_bfd_eth();
            (BRIDGE_TYPE_UPLINK_FRONT, FABRIC_PKT_TYPE_IPV6, 1) : add_bridged_md_pipe310_bfd_eth();
            (BRIDGE_TYPE_UPLINK_FRONT, FABRIC_PKT_TYPE_IPV4, 0) : add_bridged_md_pipe310_bfd_v4();
            (BRIDGE_TYPE_UPLINK_FRONT, FABRIC_PKT_TYPE_IPV6, 0) : add_bridged_md_pipe310_bfd_v6();
        }
    }

    apply {
        add_bridged_md.apply();
    }
}

control BridgedMetadata_310_extend(
        inout switch_header_t hdr,
        in switch_ingress_metadata_t ig_md) {

    action clr_extend_for_310() {
        hdr.bridged_md_310_encap.extend = 0;
        hdr.ext_l4_encap.setInvalid();
        hdr.ext_padding_word.setInvalid();
    }

    action set_extend_for_310() {
        hdr.bridged_md_310_encap.extend = 1;
        hdr.ext_l4_encap.setInvalid();
        hdr.ext_padding_word.setInvalid();
    }

    table update_310 {
        key = {
            ig_md.common.bridge_type : exact;
            hdr.ext_tunnel_decap.isValid() : exact;
        }

        actions = {
            NoAction;
            clr_extend_for_310;
            set_extend_for_310;
        }

        const default_action = NoAction;
        size = 8;
        const entries = {
            (BRIDGE_TYPE_UPLINK_FRONT, true) : set_extend_for_310();
            (BRIDGE_TYPE_UPLINK_FRONT, false) : clr_extend_for_310();
        }
    }

    apply {
        update_310.apply();
    }
}

control BridgedMetadata_extend_UPLINK(
        inout switch_header_t hdr,
        in switch_ingress_metadata_t ig_md) {

    action set_l4encap_extend_bit() {
        hdr.ext_l4_encap.extend = 1w1;
    }

    table set_extend_bit {
        key = {
            hdr.ext_tunnel_decap.isValid() : exact;
            hdr.ext_padding_word.isValid() : exact;
            hdr.ext_l4_encap.isValid() : exact;
        }
        actions = {
            NoAction;
            set_l4encap_extend_bit;
        }
        const default_action = NoAction;
        size = 32;
        const entries = {
            (true, false, true) : set_l4encap_extend_bit();
            (false, true, true) : set_l4encap_extend_bit();
        }
    }

    apply {
        set_extend_bit.apply();
    }
}

control BridgedMetadata_FABRIC(
        inout switch_header_t hdr,
        in switch_ingress_metadata_t ig_md) {

    Hash<bit<8>>(HashAlgorithm_t.IDENTITY) hash_8;
    Hash<bit<16>>(HashAlgorithm_t.IDENTITY) hash_16;

    action add_bridged_md_qos() {
        // hdr.bridged_md_qos.setValid();
        // hdr.bridged_md_qos.tc = ig_md.qos.tc;
        // hdr.bridged_md_qos.color = ig_md.qos.color;
        // hdr.bridged_md_qos.chgDSCP_disable = ig_md.qos.chgDSCP_disable;
        // hdr.bridged_md_qos.BA = ig_md.qos.BA;
        // hdr.bridged_md_qos.track = ig_md.common.track;
        hdr.fabric_qos.setValid();
        // hdr.fabric_qos.tc = ig_md.qos.tc;
        // hdr.fabric_qos.color = ig_md.qos.color;
        // hdr.fabric_qos.chgDSCP_disable = ig_md.qos.chgDSCP_disable;
        // hdr.fabric_qos.BA = ig_md.qos.BA;
        hdr.fabric_qos.track = ig_md.common.track;
    }

    action add_bridged_md_pipe78() {
        hdr.switch_bridged_src.setValid();
        hdr.switch_bridged_src.src = SWITCH_PKT_SRC_BRIDGED;
        hdr.switch_bridged_src.bridge_type = BRIDGE_TYPE_FABRIC_DOWNLINK;
        // base use fabric_base
        add_bridged_md_qos();
        hdr.bridged_md_78.setValid();
        hdr.bridged_md_78.combine = hash_16.get({
            ig_md.common.extend +++
            ig_md.qos.pcp_chg +++
            ig_md.qos.exp_chg +++
            ig_md.qos.ippre_chg +++
            ig_md.common.is_from_cpu_pcie +++
            ig_md.flags.is_elephant +++
            2w0 +++
            ig_md.common.dst_port
        });
        // reuse fabric_unicast_ext_fe(uc,6byte)/fabric_multicast_ext(mc,8byte)
        // hdr.bridged_md_78.hash = ig_md.common.hash[15:0];
        // hdr.bridged_md_78.l2_encap = ig_md.common.l2_encap;
        // hdr.bridged_md_78.l3_encap = ig_md.common.l3_encap;
        // reuse fabric_var_ext_1_16bit(uc,2byte)
        // hdr.bridged_md_78.dip_l3class_id = ig_md.route.dip_l3class_id;
        // hdr.bridged_md_78.sip_l3class_id = ig_md.route.sip_l3class_id;
        // reuse fabric_one_pad_7(all,2byte)
        // hdr.bridged_md_78.iif = ig_md.common.iif;
        hdr.bridged_md_78_fqid.setValid();
        hdr.bridged_md_78_fqid.fqid = ig_md.qos.FQID;
    }

    action add_bridged_md_pipe78_uc() {
        add_bridged_md_pipe78();
        hdr.fabric_unicast_ext_fe.hash = ig_md.common.hash[15:0];
    }

    action add_ext_eth() {
        hdr.ext_eth.setValid();
        hdr.ext_eth.evlan = ig_md.ebridge.evlan;
        hdr.ext_eth.l2oif = ig_md.ebridge.l2oif;
    }

    action add_bridged_md_pipe78_uc_eth() {
        add_bridged_md_pipe78_uc();
        add_ext_eth();
    }

    action add_bridged_md_pipe78_uc_padding_22byte() {
        add_bridged_md_pipe78_uc();
        // uc_none_eth need padding 22byte, then pkt.advance(32w176) after header78 in parse_bridged_ipv4/parse_bridged_ipv6/parse_bridged_mpls
        hdr.ethernet.setValid();
        //hdr.vlan_tag[0].setValid();
        //hdr.vlan_tag[1].setValid();
    }

    action add_bridged_md_pipe78_mc() {
        add_bridged_md_pipe78();
        hdr.fabric_multicast_src.setInvalid();
        // hdr.fabric_multicast_ext.setInvalid();//reuse in bridge_md_78
        hdr.fabric_multicast_ext.mgid = 0;
        hdr.fabric_multicast_ext.evlan = 0;//evlan is in ext_eth
        hdr.fabric_multicast_ext.hash = ig_md.common.hash[15:0];//update hash
    }

    action add_bridged_md_pipe78_mc_eth() {
        add_bridged_md_pipe78_mc();
        add_ext_eth();
    }

    action add_bridged_md_pipe78_mc_padding_8byte() {
        add_bridged_md_pipe78_mc();
        // mc_none_eth need padding 8byte, then pkt.advance(32w64) after ethernet in parse_bridged_mcv4/parse_bridged_mcv6
        //hdr.vlan_tag[0].setValid();
        //hdr.vlan_tag[1].setValid();               
    }

    action add_bridged_md_pipe74() {
        hdr.switch_bridged_src.setValid();
        hdr.switch_bridged_src.src = SWITCH_PKT_SRC_BRIDGED;
        hdr.switch_bridged_src.bridge_type = BRIDGE_TYPE_FABRIC_FABRIC;
        // base use fabric_base
  add_bridged_md_qos();
        hdr.bridged_md_74.setValid();
        hdr.bridged_md_74.evlan = ig_md.ebridge.evlan;
        // reuse fabric_one_pad_7
        // hdr.bridged_md_74.iif = ig_md.common.iif;
    }

    action add_bridged_md_pipe710() {
        hdr.switch_bridged_src.setValid();
        hdr.switch_bridged_src.src = SWITCH_PKT_SRC_BRIDGED;
        hdr.switch_bridged_src.bridge_type = BRIDGE_TYPE_FABRIC_FRONT;
        // base use fabric_base
  add_bridged_md_qos();
        // 710 use 78
        hdr.bridged_md_78.setValid();
        hdr.bridged_md_78.combine = hash_16.get({
            ig_md.common.extend +++
            ig_md.qos.pcp_chg +++
            ig_md.qos.exp_chg +++
            ig_md.qos.ippre_chg +++
            ig_md.common.is_from_cpu_pcie +++
            ig_md.flags.is_elephant +++
            2w0 +++
            ig_md.common.dst_port
        });
    }

    table add_bridged_md {
        key = {
            ig_md.common.bridge_type : ternary;
            ig_md.common.pkt_type : ternary;
            ig_md.common.is_mirror : ternary;
            ig_md.common.is_mcast : ternary;
        }
        actions = {
            NoAction;
            add_bridged_md_pipe78_uc_padding_22byte;
            add_bridged_md_pipe78_uc_eth;
            add_bridged_md_pipe78_uc;
            add_bridged_md_pipe78_mc_padding_8byte;
            add_bridged_md_pipe78_mc_eth;
            add_bridged_md_pipe78_mc;
            add_bridged_md_pipe74;
            add_bridged_md_pipe710;
        }
        const default_action = NoAction;
        size = 64;
        const entries = {
            (BRIDGE_TYPE_DEFAULT, FABRIC_PKT_TYPE_ETH, 0, 0) : add_bridged_md_pipe78_uc_eth();// uc eth, cpu uc
            (BRIDGE_TYPE_DEFAULT, FABRIC_PKT_TYPE_IPV4, 0, 0) : add_bridged_md_pipe78_uc_padding_22byte();// uc v4
            (BRIDGE_TYPE_DEFAULT, FABRIC_PKT_TYPE_IPV6, 0, 0) : add_bridged_md_pipe78_uc_padding_22byte();// uc v6
            (BRIDGE_TYPE_DEFAULT, FABRIC_PKT_TYPE_MPLS, 0, 0) : add_bridged_md_pipe78_uc_padding_22byte();// uc mpls
            (BRIDGE_TYPE_DEFAULT, _, 0, 0) : add_bridged_md_pipe78_uc();// uc others: cpu eth, ccm
            (BRIDGE_TYPE_DEFAULT, FABRIC_PKT_TYPE_ETH, 0, 1) : add_bridged_md_pipe78_mc_eth();// mc flood
            (BRIDGE_TYPE_DEFAULT, FABRIC_PKT_TYPE_IPV4, 0, 1) : add_bridged_md_pipe78_mc_padding_8byte();// mcv4
            (BRIDGE_TYPE_DEFAULT, FABRIC_PKT_TYPE_IPV6, 0, 1) : add_bridged_md_pipe78_mc_padding_8byte();// mcv6
            (BRIDGE_TYPE_DEFAULT, _, 0, 1) : add_bridged_md_pipe78_mc();// mc others

            (BRIDGE_TYPE_FABRIC_DOWNLINK, FABRIC_PKT_TYPE_ETH, 0, 0) : add_bridged_md_pipe78_uc_eth();// uc eth, cpu uc
            (BRIDGE_TYPE_FABRIC_DOWNLINK, FABRIC_PKT_TYPE_IPV4, 0, 0) : add_bridged_md_pipe78_uc_padding_22byte();// uc v4
            (BRIDGE_TYPE_FABRIC_DOWNLINK, FABRIC_PKT_TYPE_IPV6, 0, 0) : add_bridged_md_pipe78_uc_padding_22byte();// uc v6
            (BRIDGE_TYPE_FABRIC_DOWNLINK, FABRIC_PKT_TYPE_MPLS, 0, 0) : add_bridged_md_pipe78_uc_padding_22byte();// uc mpls
            (BRIDGE_TYPE_FABRIC_DOWNLINK, _, 0, 0) : add_bridged_md_pipe78_uc();// uc others: cpu eth, ccm
            (BRIDGE_TYPE_FABRIC_DOWNLINK, FABRIC_PKT_TYPE_ETH, 0, 1) : add_bridged_md_pipe78_mc_eth();// mc flood
            (BRIDGE_TYPE_FABRIC_DOWNLINK, FABRIC_PKT_TYPE_IPV4, 0, 1) : add_bridged_md_pipe78_mc_padding_8byte();// mcv4
            (BRIDGE_TYPE_FABRIC_DOWNLINK, FABRIC_PKT_TYPE_IPV6, 0, 1) : add_bridged_md_pipe78_mc_padding_8byte();// mcv6
            (BRIDGE_TYPE_FABRIC_DOWNLINK, _, 0, 1) : add_bridged_md_pipe78_mc();// mc others

            (BRIDGE_TYPE_FABRIC_FABRIC, _, 0, _) : add_bridged_md_pipe74();// cpu flood,  cpu to cpu
            (BRIDGE_TYPE_FABRIC_FRONT, _, 1, 0) : add_bridged_md_pipe710();// mirror
        }
    }

    // action pad_l4encap() {
    //     hdr.ext_l4_encap_pad.setValid();
    //     hdr.ext_l4_encap_pad.ext_type = FABRIC_EXT_TYPE_L4_ENCAP;
    //     hdr.ext_l4_encap_pad.extend = 1;
    // }

    // action pad_tunnel_decap() {
    //     hdr.ext_tunnel_decap_pad.setValid();
    //     hdr.ext_tunnel_decap_pad.ext_type = FABRIC_EXT_TYPE_TUNNEL_DECAP;
    //     hdr.ext_tunnel_decap_pad.extend = 0;
    // }

    // action pad_l4encap_tunnel_decap() {
    //     hdr.ext_l4_encap_pad.setValid();
    //     hdr.ext_l4_encap_pad.ext_type = FABRIC_EXT_TYPE_L4_ENCAP;
    //     hdr.ext_l4_encap_pad.extend = 1;
    //     hdr.ext_tunnel_decap_pad.setValid();
    //     hdr.ext_tunnel_decap_pad.ext_type = FABRIC_EXT_TYPE_TUNNEL_DECAP;
    //     hdr.ext_tunnel_decap_pad.extend = 0;
    // }

    // table pad_extention {
    //     key = {
    //         ig_md.common.bridge_type : exact;
    //         hdr.ext_l4_encap.isValid() : exact;
    //         hdr.ext_tunnel_decap.isValid() : exact;
    //     }
    //     actions = {
    //         NoAction;
    //         pad_l4encap;
    //         pad_tunnel_decap;
    //         pad_l4encap_tunnel_decap;
    //     }
    //     const default_action = NoAction;
    //     size = 8;
    //     const entries = {
    //         (BRIDGE_TYPE_FABRIC_DOWNLINK, false, true) : pad_l4encap();
    //         (BRIDGE_TYPE_FABRIC_DOWNLINK, true, false) : pad_tunnel_decap();
    //         (BRIDGE_TYPE_FABRIC_DOWNLINK, false, false) : pad_l4encap_tunnel_decap();
    //     }
    // }

    apply {
        add_bridged_md.apply();
        // pad_extention.apply();
    }
}

control BridgedTypeInit_DOWNLINK(
        inout switch_header_t hdr,
        inout switch_ingress_metadata_t ig_md) {

    action set_bridge_type(switch_bridge_type_t bridge_type) {
        ig_md.common.bridge_type = bridge_type;
    }

    action ccm_set_bridge_type(switch_bridge_type_t bridge_type) {
        ig_md.common.bridge_type = bridge_type;
        ig_md.common.dst_port = 0;
    }

    @stage(0)
    table bridgeType_init {
        key = {
            hdr.fabric_base.pkt_type : exact;
        }
        actions = {
            set_bridge_type;
            ccm_set_bridge_type;
        }
        const default_action = set_bridge_type(BRIDGE_TYPE_DOWNLINK_FRONT);
        size = 8;
        // const entries = {
        //     (FABRIC_PKT_TYPE_FPGA_DROP) : set_bridge_type(BRIDGE_TYPE_FPGA_DROP);
        //     (FABRIC_PKT_TYPE_FPGA_PAUSE) : set_bridge_type(BRIDGE_TYPE_FPGA_PAUSE);
        //     (FABRIC_PKT_TYPE_CCM) : ccm_set_bridge_type(BRIDGE_TYPE_DOWNLINK_FRONT);
        // }
    }

    apply {
        bridgeType_init.apply();
    }
}

control BridgedMetadata_DOWNLINK(
        inout switch_header_t hdr,
        in switch_ingress_metadata_t ig_md) {

    Hash<bit<16>>(HashAlgorithm_t.IDENTITY) hash_16;
    Hash<bit<8>>(HashAlgorithm_t.IDENTITY) hash_8;

    action add_bridged_src(switch_bridge_type_t bridge_type) {
        hdr.switch_bridged_src.setValid();
        hdr.switch_bridged_src.src = SWITCH_PKT_SRC_BRIDGED;
        hdr.switch_bridged_src.bridge_type = bridge_type;
    }

    action add_bridged_md_pipe910_uc() {
        add_bridged_src(BRIDGE_TYPE_DOWNLINK_FRONT);
        // reuse fabric_base
        // reuse fabric_qos
        hdr.bridged_md_910_encap.setValid();
        hdr.bridged_md_910_encap.combine_16 = hash_16.get({
            ig_md.flags.drop +++
            ig_md.lkp.ip_frag +++
            1w0 +++
            ig_md.policer.bypass +++
            ig_md.common.dst_port});
        hdr.bridged_md_910_encap.iif = ig_md.common.iif;
        hdr.bridged_md_910_encap.oif = ig_md.common.oif;
        hdr.bridged_md_910_encap.hash = ig_md.common.hash[15:0];
        hdr.bridged_md_910_encap.evlan = ig_md.ebridge.evlan;
    }

    action add_bridged_md_pipe910_mc() {
        add_bridged_src(BRIDGE_TYPE_DOWNLINK_FRONT);
        // reuse fabric_base
        // reuse fabric_qos
        hdr.bridged_md_910_encap.setValid();
        hdr.bridged_md_910_encap.combine_16 = hash_16.get({
            ig_md.flags.drop +++
            ig_md.lkp.ip_frag +++
            1w0 +++
            ig_md.policer.bypass +++
            ig_md.common.dst_port});
        hdr.bridged_md_910_encap.iif = ig_md.common.iif;
        hdr.bridged_md_910_encap.oif = ig_md.common.oif;
        hdr.bridged_md_910_encap.hash = ig_md.common.hash[15:0];
        hdr.bridged_md_910_encap.evlan = ig_md.ebridge.evlan;
    }

    action add_bridged_md_pipe910_pause() {
        add_bridged_src(BRIDGE_TYPE_FPGA_PAUSE);
        // reuse fabric_base
        // reuse fabric_qos
        hdr.bridged_md_910_encap.setValid();
        hdr.bridged_md_910_encap.combine_16 = hash_16.get({
            ig_md.flags.drop +++
            ig_md.lkp.ip_frag +++
            1w0 +++
            ig_md.policer.bypass +++
            ig_md.common.dst_port});
        hdr.bridged_md_910_encap.iif = ig_md.common.iif;
        hdr.bridged_md_910_encap.oif = ig_md.common.oif;
        hdr.bridged_md_910_encap.hash = ig_md.common.hash[15:0];
        hdr.bridged_md_910_encap.evlan = ig_md.ebridge.evlan;
    }

    table add_bridged_md {
        key = {
            ig_md.common.bridge_type : exact;
            ig_md.common.is_mirror : ternary;
            ig_md.common.is_mcast : ternary;
        }
        actions = {
            NoAction;
            add_bridged_md_pipe910_uc;
            add_bridged_md_pipe910_mc;
            add_bridged_md_pipe910_pause;
        }
        const default_action = NoAction;
        size = 8;
        const entries = {
            (BRIDGE_TYPE_DOWNLINK_FRONT, 0, 0) : add_bridged_md_pipe910_uc();
            (BRIDGE_TYPE_DOWNLINK_FRONT, 0, 1) : add_bridged_md_pipe910_mc();
            (BRIDGE_TYPE_FPGA_PAUSE, _, _) : add_bridged_md_pipe910_pause();
        }
    }

    apply {
        add_bridged_md.apply();
    }
}

action add_mirror_translate_md(
        inout fabric_base_h bridged_md_base,
        in switch_ingress_metadata_t ig_md) {

    // bridged_md_base.src = SWITCH_PKT_SRC_CLONED_INGRESS;
}
# 182 "/mnt/p4c-4127/p4src/switch-tofino2/switch_tofino_x1.p4" 2
# 1 "/mnt/p4c-4127/p4src/shared/mirror.p4" 1
//-----------------------------------------------------------------------------
// Process for Mirror feature
//
//-----------------------------------------------------------------------------



/*-----------------------------------------------------------------------------
 The called position
 ----------------  ----------  ----------------   ----------------
|ingress:      |  | tm/pre |  |egress:       |   |FPGA:         |
----------------  ----------  ----------------   ----------------
----------------  ----------  ----------------
|ingress:      |  | tm/pre |  |egress:  HERE |
----------------  ----------  ----------------
______________________________________________
                      FE
______________________________________________
----------------  ----------  ----------------    ----------------
|ingress:      |  | tm/pre |  |egress:       |    |FPGA:         |
----------------  ----------  ----------------    ----------------
----------------  ----------  ----------------
|ingress:      |  | tm/pre |  |egress:       |
----------------  ----------  ----------------
 @fuction:  EgressMirrorFabric
 @说明:观察口跨板的镜像的流量，基于session获取观察口port信息，并且封装在fabric头中
       后续还需要在这里做镜像流的car/count以及优先级处理等；
 @param hdr : Parsed headers.
 @param eg_md : Egress metadata fields.
 @param port : Egress port

-----------------------------------------------------------------------------*/
control IgPortMirror(
        in switch_port_t port,
        in switch_pkt_src_t src,
        inout switch_ingress_metadata_t ig_md,
        inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr)(
        switch_uint32_t table_size=256) {

    action set_mirror_id(switch_mirror_session_t mirror_id) {
        ig_md.mirror.mirror_id = mirror_id;
        // ig_md.mirror.span_flag = 1;
    }
    @placement_priority(124)
    table ingress_port_mirror {
        key = {
            ig_md.common.src_port : exact;
        }
        actions = {
            NoAction;
            set_mirror_id;
        }

        const default_action = NoAction;
        size = table_size;
    }

    apply {

        if (ig_md.srv6.is_loopback == 0) {

            ingress_port_mirror.apply();

        }

    }
}
control EgPortMirror(
        in switch_port_t port,
        in switch_pkt_src_t src,
        inout switch_egress_metadata_t eg_md,
        inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr)(
        switch_uint32_t table_size=256) {

    action set_mirror_id(switch_mirror_session_t mirror_id) {
        eg_md.mirror.mirror_id = mirror_id;
    }

    table egress_port_mirror {
        key = {
            eg_md.common.dst_port : exact;
        }
        actions = {
            NoAction;
            set_mirror_id;
        }
        const default_action = NoAction;
        size = table_size;
    }

    apply {
        if (eg_md.common.is_mirror == 0) {
            egress_port_mirror.apply();
        }
    }
}

control IgMirrorLag(
        inout switch_header_t hdr,
        inout switch_ingress_metadata_t ig_md,
        inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr,
        in bit<16> hash) (
        switch_uint32_t mirror_lag_table_size=512
        ){

    Hash<switch_uint16_t>(HashAlgorithm_t.IDENTITY) selector_hash;
    ActionSelector(128, selector_hash, SelectorMode_t.FAIR) mirror_lag_selector;

    action set_local_mirror_session(switch_mirror_session_t sess_id, switch_logic_port_t dst_port) {
        ig_md.mirror.type = 1;
        ig_md.mirror.src = SWITCH_PKT_SRC_CLONED_INGRESS;
        ig_intr_md_for_dprsr.mirror_type = (MirrorType_t) 1;

        ig_md.mirror.session_id = sess_id;
        // ig_md.common.dst_port = dst_port;
        ig_md.common.egress_eport[15:8] = 0;
        ig_md.common.egress_eport[7:0] = dst_port;
        ig_md.mirror.span_flag = 1;
    }

    action set_tran_mirror_session(switch_mirror_session_t sess_id, switch_eport_t eport) {
        ig_md.mirror.type = 1;
        ig_md.mirror.src = SWITCH_PKT_SRC_CLONED_INGRESS;
        ig_intr_md_for_dprsr.mirror_type = (MirrorType_t) 1;

        ig_md.mirror.session_id = sess_id;
        ig_md.common.egress_eport = eport;
        ig_md.mirror.span_flag = 1;
    }

    @ignore_table_dependency("Ig_front.set_ipfix_session_ig.ipfix_set_mirror_session")
    table mirror_lag {
        key = {
            ig_md.mirror.mirror_id : exact;
            hash : selector;
        }

        actions = {
            NoAction;
            set_local_mirror_session;
            set_tran_mirror_session;
        }

        const default_action = NoAction;
        size = mirror_lag_table_size;
        implementation = mirror_lag_selector;
    }

    apply {
        if (ig_md.mirror.color != SWITCH_METER_COLOR_RED) {
            mirror_lag.apply();
        }

    }
}

control EgMirrorLag(
        inout switch_header_t hdr,
        inout switch_egress_metadata_t eg_md,
        inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
        in bit<16> hash) (
        switch_uint32_t mirror_lag_table_size=512
        ) {

    Hash<switch_uint16_t>(HashAlgorithm_t.IDENTITY) selector_hash;
    ActionSelector(128, selector_hash, SelectorMode_t.FAIR) mirror_lag_selector;

    action set_local_mirror_session(switch_mirror_session_t sess_id, switch_logic_port_t dst_port) {
        eg_md.mirror.type = 1;
        eg_md.mirror.src = SWITCH_PKT_SRC_CLONED_EGRESS;
        eg_intr_md_for_dprsr.mirror_type = (MirrorType_t) 1;

        eg_intr_md_for_dprsr.mirror_io_select = 1; // E2E mirroring for Tofino2 & future ASICs

        eg_md.mirror.session_id = sess_id;
        // eg_md.common.dst_port = dst_port;
        eg_md.common.egress_eport[15:8] = 0;
        eg_md.common.egress_eport[7:0] = dst_port;
        eg_md.mirror.span_flag = 1;
    }

    action set_tran_mirror_session(switch_mirror_session_t sess_id, switch_eport_t eport) {
        eg_md.mirror.type = 1;
        eg_md.mirror.src = SWITCH_PKT_SRC_CLONED_EGRESS;
        eg_intr_md_for_dprsr.mirror_type = (MirrorType_t) 1;

        eg_intr_md_for_dprsr.mirror_io_select = 1; // E2E mirroring for Tofino2 & future ASICs

        eg_md.mirror.session_id = sess_id;
        eg_md.common.egress_eport = eport;
        eg_md.mirror.span_flag = 1;
    }

    action clear_span_flag() {
        eg_md.mirror.span_flag = 0;
    }

    table mirror_lag {
        key = {
            eg_md.mirror.mirror_id : exact;
            hash : selector;
        }

        actions = {
            NoAction;
            set_local_mirror_session;
            set_tran_mirror_session;
            clear_span_flag;
        }

        const default_action = clear_span_flag;
        size = mirror_lag_table_size;
        implementation = mirror_lag_selector;
    }

    apply {
        if (eg_md.mirror.color != SWITCH_METER_COLOR_RED) {
            mirror_lag.apply();
        }

    }
}

control Mirror_decision_IG(inout switch_ingress_metadata_t ig_md,
        inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr) {

    action set_ipfix_mirror_sess(switch_mirror_session_t sess_id){
        ig_md.mirror.type = 6;
        ig_md.mirror.src = SWITCH_PKT_SRC_CLONED_INGRESS;
        ig_md.mirror.session_id = sess_id;
        ig_intr_md_for_dprsr.mirror_type = (MirrorType_t) 1;
    }

    @ignore_table_dependency("Ig_front.ingress_mirror_lag.mirror_lag")
    table mirror_decision {
        key = {
            ig_md.mirror.sample_flag : exact;
        }

        actions = {
            set_ipfix_mirror_sess;
        }

        size = 2;
        // const entries = {
        //     (1) : set_ipfix_mirror_sess(sess_id);
        // }
    }

    apply {
        mirror_decision.apply();
    }
}

control Mirror_decision_EG(inout switch_egress_metadata_t eg_md,
        inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr) {

    action set_ipfix_mirror_sess(switch_mirror_session_t sess_id){
        eg_md.mirror.type = 6;
        eg_md.mirror.src = SWITCH_PKT_SRC_CLONED_EGRESS;
        eg_md.mirror.session_id = sess_id;
        eg_intr_md_for_dprsr.mirror_type = (MirrorType_t) 1;

        eg_intr_md_for_dprsr.mirror_io_select = 1; // E2E mirroring for Tofino2 & future ASICs

    }

    action set_backpush_mirror_xoff(switch_mirror_session_t sess_id) {
        eg_md.mirror.type = 8;
        eg_md.mirror.src = SWITCH_PKT_SRC_CLONED_EGRESS;
        eg_md.mirror.session_id = sess_id;
        eg_intr_md_for_dprsr.mirror_type = (MirrorType_t) 1;

        eg_intr_md_for_dprsr.mirror_io_select = 1; // E2E mirroring for Tofino2 & future ASICs

    }

    action set_backpush_mirror_xon(switch_mirror_session_t sess_id) {
        eg_md.mirror.type = 9;
        eg_md.mirror.src = SWITCH_PKT_SRC_CLONED_EGRESS;
        eg_md.mirror.session_id = sess_id;
        eg_intr_md_for_dprsr.mirror_type = (MirrorType_t) 1;

        eg_intr_md_for_dprsr.mirror_io_select = 1; // E2E mirroring for Tofino2 & future ASICs

    }

    action set_ipfix_mirror_sess_on_mirror(switch_mirror_session_t sess_id){
        // eg_md.mirror.src already assigned in parser
        eg_md.mirror.type = 6;
        eg_md.mirror.session_id = sess_id;
        eg_intr_md_for_dprsr.mirror_type = (MirrorType_t) 1;

        eg_intr_md_for_dprsr.mirror_io_select = 1; // E2E mirroring for Tofino2 & future ASICs

        // eg_md.mirror.span_flag = 0;
        eg_md.mirror.sample_flag = 0;
        eg_md.mirror.backpush_flag = 0;
    }

    action set_backpush_mirror_xoff_on_mirror(switch_mirror_session_t sess_id){
        // eg_md.mirror.src already assigned in parser
        eg_md.mirror.type = 8;
        eg_md.mirror.session_id = sess_id;
        eg_intr_md_for_dprsr.mirror_type = (MirrorType_t) 1;

        eg_intr_md_for_dprsr.mirror_io_select = 1; // E2E mirroring for Tofino2 & future ASICs

        // eg_md.mirror.span_flag = 0;
        eg_md.mirror.sample_flag = 0;
        eg_md.mirror.backpush_flag = 0;
    }

    action set_backpush_mirror_xon_on_mirror(switch_mirror_session_t sess_id){
        // eg_md.mirror.src already assigned in parser
        eg_md.mirror.type = 9;
        eg_md.mirror.session_id = sess_id;
        eg_intr_md_for_dprsr.mirror_type = (MirrorType_t) 1;

        eg_intr_md_for_dprsr.mirror_io_select = 1; // E2E mirroring for Tofino2 & future ASICs

        // eg_md.mirror.span_flag = 0;
        eg_md.mirror.sample_flag = 0;
        eg_md.mirror.backpush_flag = 0;
    }

    @ignore_table_dependency("Eg_front.egress_mirror_lag.mirror_lag")
    table mirror_decision {
        key = {
            eg_md.common.is_mirror : exact;
            eg_md.mirror.span_flag : exact;
            eg_md.mirror.sample_flag : exact;
            eg_md.mirror.backpush_flag : exact;
        }

        actions = {
            set_ipfix_mirror_sess;
            set_backpush_mirror_xoff;
            set_backpush_mirror_xon;
            set_ipfix_mirror_sess_on_mirror;
            set_backpush_mirror_xoff_on_mirror;
            set_backpush_mirror_xon_on_mirror;
        }

        size = 32;
        // const entries = {
        //     (0, 0, 1, 0) : set_ipfix_mirror_sess(sess_id);
        //     (0, 0, 1, 1) : set_ipfix_mirror_sess(sess_id);
        //     (0, 0, 1, 2) : set_ipfix_mirror_sess(sess_id);
        //     (0, 0, 0, 1) : set_backpush_mirror_xoff(sess_id);
        //     (0, 0, 0, 2) : set_backpush_mirror_xon(sess_id);
        //     (1, 1, 1, 0) : set_ipfix_mirror_sess_on_mirror(sess_id);
        //     (1, 1, 1, 1) : set_ipfix_mirror_sess_on_mirror(sess_id);
        //     (1, 1, 1, 2) : set_ipfix_mirror_sess_on_mirror(sess_id);
        //     (1, 1, 0, 1) : set_backpush_mirror_xoff_on_mirror(sess_id);
        //     (1, 1, 0, 2) : set_backpush_mirror_xon_on_mirror(sess_id);
        // }
    }

    apply {
        mirror_decision.apply();
    }
}

control Mirror_decision_EG_Fabric(
        inout switch_egress_metadata_t eg_md,
        inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr) {

    action set_ipfix_mirror_sess(switch_mirror_session_t sess_id){
        // eg_md.mirror.src already assigned in parser
        eg_md.mirror.type = 10;
        eg_md.mirror.session_id = sess_id;
        eg_intr_md_for_dprsr.mirror_type = (MirrorType_t) 1;

        eg_intr_md_for_dprsr.mirror_io_select = 1; // E2E mirroring for Tofino2 & future ASICs

        eg_md.mirror.span_flag = 0;
        eg_md.mirror.sample_flag = 0;
        eg_md.mirror.backpush_flag = 0;
    }

    action set_backpush_mirror_xoff(switch_mirror_session_t sess_id){
        // eg_md.mirror.src already assigned in parser
        eg_md.mirror.type = 8;
        eg_md.mirror.session_id = sess_id;
        eg_intr_md_for_dprsr.mirror_type = (MirrorType_t) 1;

        eg_intr_md_for_dprsr.mirror_io_select = 1; // E2E mirroring for Tofino2 & future ASICs

        eg_md.mirror.span_flag = 0;
        eg_md.mirror.sample_flag = 0;
        eg_md.mirror.backpush_flag = 0;
    }

    action set_backpush_mirror_xon(switch_mirror_session_t sess_id){
        // eg_md.mirror.src already assigned in parser
        eg_md.mirror.type = 9;
        eg_md.mirror.session_id = sess_id;
        eg_intr_md_for_dprsr.mirror_type = (MirrorType_t) 1;

        eg_intr_md_for_dprsr.mirror_io_select = 1; // E2E mirroring for Tofino2 & future ASICs

        eg_md.mirror.span_flag = 0;
        eg_md.mirror.sample_flag = 0;
        eg_md.mirror.backpush_flag = 0;
    }

    table mirror_decision {
        key = {
            eg_md.common.is_mirror : exact;
            eg_md.mirror.span_flag : exact;
            eg_md.mirror.sample_flag : exact;
            eg_md.mirror.backpush_flag : exact;
        }
        actions = {
            NoAction;
            set_ipfix_mirror_sess;
            set_backpush_mirror_xoff;
            set_backpush_mirror_xon;
        }

        const default_action = NoAction;
        size = 32;
        // const entries = {
        //     (1, 1, 1, 0) : set_ipfix_mirror_sess(sess_id);
        //     (1, 1, 1, 1) : set_ipfix_mirror_sess(sess_id);
        //     (1, 1, 1, 2) : set_ipfix_mirror_sess(sess_id);
        //     (1, 1, 0, 1) : set_backpush_mirror_xoff(sess_id);
        //     (1, 1, 0, 2) : set_backpush_mirror_xon(sess_id);
        // }
    }

    apply {
        mirror_decision.apply();
    }
}

control MirrorBrTaggedDecap(
        inout switch_header_t hdr,
        inout switch_egress_metadata_t eg_md) (
        switch_uint32_t table_size = 8) {

    action decap_br_tagged() {
        // 802.1br decap
        hdr.ethernet.ether_type = hdr.br_tag.ether_type;
        hdr.br_tag.setInvalid();
    }

    action decap_br_vlan_untag() {
        // 802.1br decap
        hdr.ethernet.ether_type = hdr.vlan_tag[0].ether_type;
        hdr.vlan_tag[0].setInvalid();
        hdr.br_tag.setInvalid();
    }

    table mirror_decap_br_tagged {
        key = {
            hdr.vlan_tag[0].isValid() : exact;
            hdr.vlan_tag[0].vid : exact;
        }

        actions = {
            decap_br_tagged;
            decap_br_vlan_untag;
        }

        const default_action = decap_br_tagged;
        size = table_size;
        const entries = {
            (true, 4095) : decap_br_vlan_untag();
            (true, 1) : decap_br_tagged(); // for complile
        }
    }

    apply {
        if (eg_md.common.is_mirror == 1 && hdr.br_tag.isValid() == true) {
            mirror_decap_br_tagged.apply();
        }
    }
}

control MirrorBrTaggedDecap_fabric(
        inout switch_header_t hdr,
        inout switch_egress_metadata_t eg_md) (
        switch_uint32_t table_size = 8) {

    action decap_br_tagged() {
        // 802.1br decap
        hdr.ethernet.ether_type = hdr.br_tag.ether_type;
        hdr.br_tag.setInvalid();
    }

    action decap_br_vlan_untag() {
        // 802.1br decap
        hdr.ethernet.ether_type = hdr.vlan_tag[0].ether_type;
        hdr.vlan_tag[0].setInvalid();
        hdr.br_tag.setInvalid();
    }

    table mirror_decap_br_tagged {
        key = {
            hdr.vlan_tag[0].isValid() : exact;
            hdr.vlan_tag[0].vid : exact;
        }

        actions = {
            decap_br_tagged;
            decap_br_vlan_untag;
        }

        const default_action = decap_br_tagged;
        size = table_size;
        const entries = {
            (true, 4095) : decap_br_vlan_untag();
            (true, 1) : decap_br_tagged(); // for complile
        }
    }

    apply {
        if (eg_md.common.is_mirror == 1 && hdr.br_tag.isValid() == true) {
            mirror_decap_br_tagged.apply();
        }
    }
}


control EopMirror(
        inout switch_header_t hdr,
        inout switch_egress_metadata_t eg_md,
        in egress_intrinsic_metadata_t eg_intr_md,
        inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr) {

    action set_eop_mirror_session(switch_mirror_session_t sess_id) {
        eg_md.mirror.type = 12;
        eg_md.mirror.src = SWITCH_PKT_SRC_CLONED_EGRESS;
        eg_intr_md_for_dprsr.mirror_type = (MirrorType_t) 1;

        eg_intr_md_for_dprsr.mirror_io_select = 1; // E2E mirroring for Tofino2 & future ASICs

        eg_md.mirror.session_id = sess_id;
    }

    table eop_mirror {
        // keyless
        actions = {
            set_eop_mirror_session;
        }
        size = 1;
    }

    apply {
        if (eg_md.flags.is_eop != 1w0 && eg_intr_md.egress_port != 320) {
            eop_mirror.apply();
        }
    }
}
# 183 "/mnt/p4c-4127/p4src/switch-tofino2/switch_tofino_x1.p4" 2
# 1 "/mnt/p4c-4127/p4src/shared/parde_front.p4" 1
/*******************************************************************************
 * BAREFOOT NETWORKS CONFIDENTIAL & PROPRIETARY
 *
 * Copyright (c) 2015-2019 Barefoot Networks, Inc.
 *
 * NOTICE: All information contained herein is, and remains the property of
 * Barefoot Networks, Inc. and its suppliers, if any. The intellectual and
 * technical concepts contained herein are proprietary to Barefoot Networks,
 * Inc.
 * and its suppliers and may be coverep by U.S. and Foreign Patents, patents in
 * process, and are protected by trade secret or copyright law.
 * Dissemination of this information or reproduction of this material is
 * strictly forbidden unless prior written permission is obtained from
 * Barefoot Networks, Inc.
 *
 * No warranty, explicit or implicit is provided, unless granted under a
 * written agreement with Barefoot Networks, Inc.
 *
 ******************************************************************************/

# 1 "/mnt/p4c-4127/p4src/shared/headers.p4" 1
/*******************************************************************************
 * BAREFOOT NETWORKS CONFIDENTIAL & PROPRIETARY
 *
 * Copyright (c) 2015-2019 Barefoot Networks, Inc.

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
 ******************************************************************************/

//-----------------------------------------------------------------------------
// Protocol Header Definitions
//-----------------------------------------------------------------------------
# 22 "/mnt/p4c-4127/p4src/shared/parde_front.p4" 2
# 1 "/mnt/p4c-4127/p4src/shared/types.p4" 1
/*******************************************************************************
 * BAREFOOT NETWORKS CONFIDENTIAL & PROPRIETARY
 *
 * Copyright (c) 2015-2019 Barefoot Networks, Inc.

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
 ******************************************************************************/
# 23 "/mnt/p4c-4127/p4src/shared/parde_front.p4" 2

//-----------------------------------------------------------------------------
// Segment routing extension header parser
//-----------------------------------------------------------------------------
parser SRHParser(packet_in pkt, inout switch_header_t hdr) {
    state start {

        transition parse_srh;



    }

    state parse_srh {
        //TODO(msharif) : implement SRH parser.
        transition accept;
    }
}

//=============================================================================
// Ingress parser
//=============================================================================
parser IgParser_front(
        packet_in pkt,
        out switch_header_t hdr,
        out switch_ingress_metadata_t ig_md,
        out ingress_intrinsic_metadata_t ig_intr_md) {
    Checksum() ipv4_checksum;
    Checksum() inner_ipv4_checksum;
    value_set<bit<16>>(1) udp_port_vxlan;
    value_set<switch_cpu_port_value_set_t>(1) cpu_port;

    state start {
        pkt.extract(ig_intr_md);
     ig_md.common.pkt_type = FABRIC_PKT_TYPE_ETH;
        ig_md.tunnel.type = SWITCH_TUNNEL_TYPE_NONE;
        ig_md.tunnel.inner_pkt_parsed = SWITCH_TUNNEL_INNER_PKT_NONE;
        // Check for resubmit flag if packet is resubmitted.
        // transition select(ig_intr_md.resubmit_flag) {
        //    1 : parse_resubmit;
        //    0 : parse_port_metadata;
        // }
        transition parse_port_metadata;
    }

    state parse_resubmit {
        // Parse resubmitted packet here.
        transition accept;
    }

    state parse_port_metadata {
        // Parse port metadata produced by ibuf
        switch_port_metadata_frontpipe_t port_md = port_metadata_unpack<switch_port_metadata_frontpipe_t>(pkt);
        ig_md.common.port_type = port_md.port_type;
        ig_md.common.timestamp = ig_intr_md.ingress_mac_tstamp[31:0];
        transition parse_ethernet;
    }

    // state parse_packet {
    //     transition parse_ethernet;
    // }

    state parse_ethernet {
        pkt.extract(hdr.ethernet);
        transition select(hdr.ethernet.ether_type) {
            0x0800 : parse_ipv4;
            0x86dd : parse_ipv6;
            0x8100 : parse_vlan;
            0x8100 : parse_vlan;
            // ETHERTYPE_FCOE : parse_fcoe;
            0x8847 : parse_mpls;
            0x893F : parse_1br;
            /* by yeweixin */
            0x9000 : parse_fabric_eth_cpu;
            /* by caixiaoxiang */

            0x9500 : parse_recirc_packet;

            0x8808 : parse_pause_info;
            default : accept;
        }
    }

    state parse_pause_info {
        pkt.extract(hdr.pause_info);
        transition accept;
    }


    state parse_recirc_packet {
        pkt.extract(hdr.pri_data);
        ig_md.common.src_port = hdr.pri_data.src_port;
        ig_md.common.eport = hdr.pri_data.eport;
        ig_md.srv6.is_loopback = 1;
        transition select(hdr.pri_data.ether_type) {
            0x0800 : parse_ipv4;
            0x86dd : parse_ipv6;
            0x8100 : parse_vlan;
            0x8100 : parse_vlan;
            0x8847 : parse_mpls;
            0x893F : parse_1br;
            /* by yeweixin */
            0x9000 : parse_fabric_eth_cpu;
            default : accept;
        }
    }


    state parse_1br {
        pkt.extract(hdr.br_tag);
        transition select(hdr.br_tag.ether_type) {
            0x0800 : parse_ipv4;
            0x86dd : parse_ipv6;
            0x8100 : parse_vlan;
            0x8100 : parse_vlan;
            //ETHERTYPE_FCOE : parse_fcoe;
            0x8847 : parse_mpls;
            default : accept;
        }
    }

    /* by yeweixin */
    state parse_fabric_eth_cpu {
        pkt.extract(hdr.fabric_from_cpu_eth_base);
        ig_md.common.fwd_mode = hdr.fabric_from_cpu_eth_base.fwd_mode;
        // ig_md.qos.qid = hdr.fabric_from_cpu_eth_base.qid;
        // ig_md.flags.escape_etm = hdr.fabric_from_cpu_eth_base.escape_etm;
        // ig_md.common.track = hdr.fabric_from_cpu_eth_base.track;
        transition select(hdr.fabric_from_cpu_eth_base.pkt_type) {
            FABRIC_PKT_TYPE_CCM : parse_fabric_eth_cpu_ccm;
            default : parse_fabric_eth_cpu_common;
        }
    }

    state parse_fabric_eth_cpu_common {
        pkt.extract(hdr.fabric_from_cpu_eth_data);
        pkt.extract(hdr.fabric_eth_etype);
        ig_md.common.dst_port = hdr.fabric_from_cpu_eth_data.dst_port;
        ig_md.common.src_port = hdr.fabric_from_cpu_eth_data.src_port;
        ig_md.common.egress_eport = hdr.fabric_from_cpu_eth_data.dst_eport;
        ig_md.common.eport = hdr.fabric_from_cpu_eth_data.src_eport;
        ig_md.common.hash = hdr.fabric_from_cpu_eth_data.hash;
        ig_md.common.iif = hdr.fabric_from_cpu_eth_data.iif;
        ig_md.route.g_l3mac_enable = true;
        transition select(hdr.fabric_eth_etype.ether_type) {
            0x0800 : parse_ipv4;
            0x86dd : parse_ipv6;
            0x8100 : parse_vlan;
            0x8100 : parse_vlan;
            default : accept;
        }
    }

    state parse_fabric_eth_cpu_ccm {
        pkt.extract(hdr.fabric_from_cpu_eth_ccm);
        transition accept;
    }

    state parse_ipv4 {
        pkt.extract(hdr.ipv4);
        ipv4_checksum.add(hdr.ipv4);
        // ig_md.lkp.ip_type = SWITCH_IP_TYPE_IPV4;
        ig_md.lkp.ip_pkt_len = hdr.ipv4.total_len;
        ig_md.lkp.ip_proto = hdr.ipv4.protocol;
        ig_md.lkp.version = hdr.ipv4.version;
        ig_md.lkp.ip_ttl = hdr.ipv4.ttl;
        // ig_md.lkp.ip_tos = hdr.ipv4.diffserv;
        ig_md.lkp.ip_src_addr = (bit<128>) hdr.ipv4.src_addr;
        ig_md.lkp.ip_dst_addr = (bit<128>) hdr.ipv4.dst_addr;
        transition select(hdr.ipv4.ihl) {
            5 : parse_ipv4_no_options;
            default : accept;
        }
    }

    state parse_ipv4_no_options {
        ig_md.flags.ipv4_checksum_err = ipv4_checksum.verify();
        transition select(hdr.ipv4.protocol, hdr.ipv4.frag_offset) {
            (1, 0) : parse_icmp;
            (6, 0) : parse_tcp;
            (17, 0) : parse_udp;





            // Do NOT parse the next header if IP packet is fragmented.
            default : accept;
        }
    }

    state parse_vlan {
        pkt.extract(hdr.vlan_tag[0]);
        ig_md.lkp.vid = hdr.vlan_tag[0].vid;
        transition select(hdr.vlan_tag[0].ether_type) {
            0x0800 : parse_ipv4;
            0x8100 : parse_vlan_1;
            0x86dd : parse_ipv6;
            0x8847 : parse_mpls;
            default : accept;
        }
    }

    state parse_vlan_1 {
        pkt.extract(hdr.vlan_tag[1]);
        transition select(hdr.vlan_tag[1].ether_type) {
            0x0800 : parse_ipv4;
            0x86dd : parse_ipv6;
            0x8847 : parse_mpls;
            default : accept;
        }
    }

    state parse_mpls {
        pkt.extract(hdr.mpls_ig[0]);
        mpls_lookahead_h lookahead = pkt.lookahead<mpls_lookahead_h>();
        transition select(hdr.mpls_ig[0].bos, lookahead.bos1, lookahead.bos2) {
            (0x0 &&& 0x1, 0x0 &&& 0x1, 0x0 &&& 0x1): parse_mpls3_or_more;
            (0x0 &&& 0x1, 0x0 &&& 0x1, 0x1 &&& 0x1): parse_mpls2;
            (0x0 &&& 0x1, 0x1 &&& 0x1, 0x0 &&& 0x0): parse_mpls1;
            default : parse_mpls_bos;
        }
    }

    state parse_mpls1 {
        pkt.extract(hdr.mpls_ig[1]);
        transition select(pkt.lookahead<bit<4>>()) {
            0x4 : parse_inner_ipv4;
            0x6 : parse_inner_ipv6;
            default: parse_inner_ethernet;
        }
    }

    state parse_mpls2 {
        pkt.extract(hdr.mpls_ig[1]);
        pkt.extract(hdr.mpls_ig[2]);
        transition select(pkt.lookahead<bit<4>>()) {
            0x4 : parse_inner_ipv4;
            0x6 : parse_inner_ipv6;
            default: parse_inner_ethernet;
        }
    }

    state parse_mpls3_or_more {
        pkt.extract(hdr.mpls_ig[1]);
        pkt.extract(hdr.mpls_ig[2]);
        pkt.extract(hdr.mpls_ig[3]);
        mpls_lookahead_h lookahead = pkt.lookahead<mpls_lookahead_h>();
        transition select(hdr.mpls_ig[3].bos, lookahead.bos1, lookahead.bos2) {
            (0x0 &&& 0x1, 0x0 &&& 0x1, 0x0 &&& 0x1): parse_mpls6_or_more;
            (0x0 &&& 0x1, 0x0 &&& 0x1, 0x1 &&& 0x1): parse_mpls5;
            (0x0 &&& 0x1, 0x1 &&& 0x1, 0x0 &&& 0x0): parse_mpls4;
            default : parse_mpls_bos;
        }
    }

    state parse_mpls4 {
        pkt.extract(hdr.mpls_ig[4]);
        transition select(pkt.lookahead<bit<4>>()) {
            0x4 : parse_inner_ipv4;
            0x6 : parse_inner_ipv6;
            default: parse_inner_ethernet;
        }
    }

    state parse_mpls5 {
        pkt.extract(hdr.mpls_ig[4]);
        pkt.extract(hdr.mpls_ig[5]);
        transition select(pkt.lookahead<bit<4>>()) {
            0x4 : parse_inner_ipv4;
            0x6 : parse_inner_ipv6;
            default: parse_inner_ethernet;
        }
    }

    state parse_mpls6_or_more {
        pkt.extract(hdr.mpls_ig[4]);
        pkt.extract(hdr.mpls_ig[5]);
        pkt.extract(hdr.mpls2_ig[0]);
        mpls_lookahead_h lookahead = pkt.lookahead<mpls_lookahead_h>();
        transition select(hdr.mpls2_ig[0].bos, lookahead.bos1, lookahead.bos2) {
            (0x0 &&& 0x1, 0x0 &&& 0x1, 0x0 &&& 0x1): parse_mpls9_or_more;
            (0x0 &&& 0x1, 0x0 &&& 0x1, 0x1 &&& 0x1): parse_mpls8;
            (0x0 &&& 0x1, 0x1 &&& 0x1, 0x0 &&& 0x0): parse_mpls7;
            default : parse_mpls_bos;
        }
    }

    state parse_mpls7 {
        pkt.extract(hdr.mpls2_ig[1]);
        transition select(pkt.lookahead<bit<4>>()) {
            0x4 : parse_inner_ipv4;
            0x6 : parse_inner_ipv6;
            default: parse_inner_ethernet;
        }
    }

    state parse_mpls8 {
        pkt.extract(hdr.mpls2_ig[1]);
        pkt.extract(hdr.mpls2_ig[2]);
        transition select(pkt.lookahead<bit<4>>()) {
            0x4 : parse_inner_ipv4;
            0x6 : parse_inner_ipv6;
            default: parse_inner_ethernet;
        }
    }

    state parse_mpls9_or_more {
        pkt.extract(hdr.mpls2_ig[1]);
        pkt.extract(hdr.mpls2_ig[2]);
        pkt.extract(hdr.mpls2_ig[3]);
        transition select(hdr.mpls2_ig[3].bos) {
            1 : parse_mpls_bos;
            default : accept;
        }
    }

    state parse_mpls_bos {
        // transition parse_mpls_cw;
        transition select(pkt.lookahead<bit<4>>()) {
            0x4 : parse_inner_ipv4;
            0x6 : parse_inner_ipv6;
            default : parse_inner_ethernet;
        }
    }

    // state parse_mpls_cw {
    //     transition select(pkt.lookahead<bit<4>>()) {
    //         0x0 : parse_cw;
    //         default: accept;
    //     }
    // }

    // state parse_cw {
    //     pkt.extract(hdr.cw);
    //     transition accept;
    // }
# 372 "/mnt/p4c-4127/p4src/shared/parde_front.p4"
    state parse_ipv6 {

        pkt.extract(hdr.ipv6);
        // ig_md.lkp.ip_type = SWITCH_IP_TYPE_IPV6;
        ig_md.lkp.ip_pkt_len = hdr.ipv6.payload_len;
        ig_md.lkp.ip_proto = hdr.ipv6.next_hdr;
        ig_md.lkp.ip_ttl = hdr.ipv6.hop_limit;
        ig_md.lkp.version = hdr.ipv6.version;
        // ig_md.lkp.ip_tos = hdr.ipv6.traffic_class;
        ig_md.lkp.ip_src_addr = hdr.ipv6.src_addr;
        ig_md.lkp.ip_dst_addr = hdr.ipv6.dst_addr;
        ig_md.lkp.flow_label = hdr.ipv6.flow_label;
        transition select(hdr.ipv6.next_hdr) {
            58 : parse_icmp;
            6 : parse_tcp;
            17 : parse_udp;
            //IP_PROTOCOLS_FRAGMENT : parse_ipv6_frag;





            43 : parse_srh;

            default : accept;
        }



    }

    state parse_ipv6_frag {
        pkt.extract(hdr.ipv6_frag);
        transition select(hdr.ipv6_frag.next_hdr, hdr.ipv6_frag.frag_offset) {
            (6, 0) : parse_tcp;
            (17, 0) : parse_udp;
            (58, 0) : parse_icmp;
            default : accept;
        }
    }


    @critical
    state parse_srh {
        pkt.extract(hdr.srv6_srh);
        ig_md.srv6.last_entry = hdr.srv6_srh.last_entry;
        ig_md.srv6.seg_left = hdr.srv6_srh.seg_left;
        ig_md.srv6.hdr_ext_len = hdr.srv6_srh.hdr_ext_len;
        transition parse_srh_segment_0;
    }
# 469 "/mnt/p4c-4127/p4src/shared/parde_front.p4"
state parse_srh_segment_0 { transition select(hdr.srv6_srh.last_entry, hdr.srv6_srh.seg_left) { (0, 1) : set_active_and_parse_srh_next0; (0, 0) : set_active_gsid_and_parse_srh_next0; (0, _) : parse_srh_next_header_0; (_, 1) : set_active_segment_a0; (_, 0) : set_active_g_sid_0; default : parse_srh_segment_b0; } } state parse_srh_segment_b0 { pkt.extract(hdr.srv6_list[0]); transition parse_srh_segment_1; } state set_active_segment_a0 { pkt.extract(hdr.srv6_list[0]); ig_md.srv6.sid = hdr.srv6_list[0].sid; transition parse_srh_segment_1; } state set_active_g_sid_0 { pkt.extract(hdr.srv6_list[0]); ig_md.srv6.g_sid = hdr.srv6_list[0].sid; transition parse_srh_segment_1; } state set_active_gsid_and_parse_srh_next0 { pkt.extract(hdr.srv6_list[0]); ig_md.srv6.g_sid = hdr.srv6_list[0].sid; transition parse_srh_next_header; } state set_active_and_parse_srh_next0 { pkt.extract(hdr.srv6_list[0]); ig_md.srv6.sid = hdr.srv6_list[0].sid; transition parse_srh_next_header; } state parse_srh_next_header_0 { pkt.extract(hdr.srv6_list[0]); transition parse_srh_next_header; }
state parse_srh_segment_1 { transition select(hdr.srv6_srh.last_entry, hdr.srv6_srh.seg_left) { (1, 2) : set_active_and_parse_srh_next1; (1, 1) : set_active_gsid_and_parse_srh_next1; (1, _) : parse_srh_next_header_1; (_, 2) : set_active_segment_a1; (_, 1) : set_active_g_sid_1; default : parse_srh_segment_b1; } } state parse_srh_segment_b1 { pkt.extract(hdr.srv6_list[1]); transition parse_srh_segment_2; } state set_active_segment_a1 { pkt.extract(hdr.srv6_list[1]); ig_md.srv6.sid = hdr.srv6_list[1].sid; transition parse_srh_segment_2; } state set_active_g_sid_1 { pkt.extract(hdr.srv6_list[1]); ig_md.srv6.g_sid = hdr.srv6_list[1].sid; transition parse_srh_segment_2; } state set_active_gsid_and_parse_srh_next1 { pkt.extract(hdr.srv6_list[1]); ig_md.srv6.g_sid = hdr.srv6_list[1].sid; transition parse_srh_next_header; } state set_active_and_parse_srh_next1 { pkt.extract(hdr.srv6_list[1]); ig_md.srv6.sid = hdr.srv6_list[1].sid; transition parse_srh_next_header; } state parse_srh_next_header_1 { pkt.extract(hdr.srv6_list[1]); transition parse_srh_next_header; }
state parse_srh_segment_2 { transition select(hdr.srv6_srh.last_entry, hdr.srv6_srh.seg_left) { (2, 3) : set_active_and_parse_srh_next2; (2, 2) : set_active_gsid_and_parse_srh_next2; (2, _) : parse_srh_next_header_2; (_, 3) : set_active_segment_a2; (_, 2) : set_active_g_sid_2; default : parse_srh_segment_b2; } } state parse_srh_segment_b2 { pkt.extract(hdr.srv6_list[2]); transition parse_srh_segment_3; } state set_active_segment_a2 { pkt.extract(hdr.srv6_list[2]); ig_md.srv6.sid = hdr.srv6_list[2].sid; transition parse_srh_segment_3; } state set_active_g_sid_2 { pkt.extract(hdr.srv6_list[2]); ig_md.srv6.g_sid = hdr.srv6_list[2].sid; transition parse_srh_segment_3; } state set_active_gsid_and_parse_srh_next2 { pkt.extract(hdr.srv6_list[2]); ig_md.srv6.g_sid = hdr.srv6_list[2].sid; transition parse_srh_next_header; } state set_active_and_parse_srh_next2 { pkt.extract(hdr.srv6_list[2]); ig_md.srv6.sid = hdr.srv6_list[2].sid; transition parse_srh_next_header; } state parse_srh_next_header_2 { pkt.extract(hdr.srv6_list[2]); transition parse_srh_next_header; }
state parse_srh_segment_3 { transition select(hdr.srv6_srh.last_entry, hdr.srv6_srh.seg_left) { (3, 4) : set_active_and_parse_srh_next3; (3, 3) : set_active_gsid_and_parse_srh_next3; (3, _) : parse_srh_next_header_3; (_, 4) : set_active_segment_a3; (_, 3) : set_active_g_sid_3; default : parse_srh_segment_b3; } } state parse_srh_segment_b3 { pkt.extract(hdr.srv6_list[3]); transition parse_srh_segment_4; } state set_active_segment_a3 { pkt.extract(hdr.srv6_list[3]); ig_md.srv6.sid = hdr.srv6_list[3].sid; transition parse_srh_segment_4; } state set_active_g_sid_3 { pkt.extract(hdr.srv6_list[3]); ig_md.srv6.g_sid = hdr.srv6_list[3].sid; transition parse_srh_segment_4; } state set_active_gsid_and_parse_srh_next3 { pkt.extract(hdr.srv6_list[3]); ig_md.srv6.g_sid = hdr.srv6_list[3].sid; transition parse_srh_next_header; } state set_active_and_parse_srh_next3 { pkt.extract(hdr.srv6_list[3]); ig_md.srv6.sid = hdr.srv6_list[3].sid; transition parse_srh_next_header; } state parse_srh_next_header_3 { pkt.extract(hdr.srv6_list[3]); transition parse_srh_next_header; }
state parse_srh_segment_4 { transition select(hdr.srv6_srh.last_entry, hdr.srv6_srh.seg_left) { (4, 5) : set_active_and_parse_srh_next4; (4, 4) : set_active_gsid_and_parse_srh_next4; (4, _) : parse_srh_next_header_4; (_, 5) : set_active_segment_a4; (_, 4) : set_active_g_sid_4; default : parse_srh_segment_b4; } } state parse_srh_segment_b4 { pkt.extract(hdr.srv6_list[4]); transition parse_srh_segment_5; } state set_active_segment_a4 { pkt.extract(hdr.srv6_list[4]); ig_md.srv6.sid = hdr.srv6_list[4].sid; transition parse_srh_segment_5; } state set_active_g_sid_4 { pkt.extract(hdr.srv6_list[4]); ig_md.srv6.g_sid = hdr.srv6_list[4].sid; transition parse_srh_segment_5; } state set_active_gsid_and_parse_srh_next4 { pkt.extract(hdr.srv6_list[4]); ig_md.srv6.g_sid = hdr.srv6_list[4].sid; transition parse_srh_next_header; } state set_active_and_parse_srh_next4 { pkt.extract(hdr.srv6_list[4]); ig_md.srv6.sid = hdr.srv6_list[4].sid; transition parse_srh_next_header; } state parse_srh_next_header_4 { pkt.extract(hdr.srv6_list[4]); transition parse_srh_next_header; }
state parse_srh_segment_5 { transition select(hdr.srv6_srh.last_entry, hdr.srv6_srh.seg_left) { (5, 6) : set_active_and_parse_srh_next5; (5, 5) : set_active_gsid_and_parse_srh_next5; (5, _) : parse_srh_next_header_5; (_, 6) : set_active_segment_a5; (_, 5) : set_active_g_sid_5; default : parse_srh_segment_b5; } } state parse_srh_segment_b5 { pkt.extract(hdr.srv6_list[5]); transition parse_srh_segment_6; } state set_active_segment_a5 { pkt.extract(hdr.srv6_list[5]); ig_md.srv6.sid = hdr.srv6_list[5].sid; transition parse_srh_segment_6; } state set_active_g_sid_5 { pkt.extract(hdr.srv6_list[5]); ig_md.srv6.g_sid = hdr.srv6_list[5].sid; transition parse_srh_segment_6; } state set_active_gsid_and_parse_srh_next5 { pkt.extract(hdr.srv6_list[5]); ig_md.srv6.g_sid = hdr.srv6_list[5].sid; transition parse_srh_next_header; } state set_active_and_parse_srh_next5 { pkt.extract(hdr.srv6_list[5]); ig_md.srv6.sid = hdr.srv6_list[5].sid; transition parse_srh_next_header; } state parse_srh_next_header_5 { pkt.extract(hdr.srv6_list[5]); transition parse_srh_next_header; }
state parse_srh_segment_6 { transition select(hdr.srv6_srh.last_entry, hdr.srv6_srh.seg_left) { (6, 7) : set_active_and_parse_srh_next6; (6, 6) : set_active_gsid_and_parse_srh_next6; (6, _) : parse_srh_next_header_6; (_, 7) : set_active_segment_a6; (_, 6) : set_active_g_sid_6; default : parse_srh_segment_b6; } } state parse_srh_segment_b6 { pkt.extract(hdr.srv6_list[6]); transition parse_srh_segment_7; } state set_active_segment_a6 { pkt.extract(hdr.srv6_list[6]); ig_md.srv6.sid = hdr.srv6_list[6].sid; transition parse_srh_segment_7; } state set_active_g_sid_6 { pkt.extract(hdr.srv6_list[6]); ig_md.srv6.g_sid = hdr.srv6_list[6].sid; transition parse_srh_segment_7; } state set_active_gsid_and_parse_srh_next6 { pkt.extract(hdr.srv6_list[6]); ig_md.srv6.g_sid = hdr.srv6_list[6].sid; transition parse_srh_next_header; } state set_active_and_parse_srh_next6 { pkt.extract(hdr.srv6_list[6]); ig_md.srv6.sid = hdr.srv6_list[6].sid; transition parse_srh_next_header; } state parse_srh_next_header_6 { pkt.extract(hdr.srv6_list[6]); transition parse_srh_next_header; }
state parse_srh_segment_7 { transition select(hdr.srv6_srh.last_entry, hdr.srv6_srh.seg_left) { (7, 8) : set_active_and_parse_srh_next7; (7, 7) : set_active_gsid_and_parse_srh_next7; (7, _) : parse_srh_next_header_7; (_, 8) : set_active_segment_a7; (_, 7) : set_active_g_sid_7; default : parse_srh_segment_b7; } } state parse_srh_segment_b7 { pkt.extract(hdr.srv6_list[7]); transition parse_srh_segment_8; } state set_active_segment_a7 { pkt.extract(hdr.srv6_list[7]); ig_md.srv6.sid = hdr.srv6_list[7].sid; transition parse_srh_segment_8; } state set_active_g_sid_7 { pkt.extract(hdr.srv6_list[7]); ig_md.srv6.g_sid = hdr.srv6_list[7].sid; transition parse_srh_segment_8; } state set_active_gsid_and_parse_srh_next7 { pkt.extract(hdr.srv6_list[7]); ig_md.srv6.g_sid = hdr.srv6_list[7].sid; transition parse_srh_next_header; } state set_active_and_parse_srh_next7 { pkt.extract(hdr.srv6_list[7]); ig_md.srv6.sid = hdr.srv6_list[7].sid; transition parse_srh_next_header; } state parse_srh_next_header_7 { pkt.extract(hdr.srv6_list[7]); transition parse_srh_next_header; }
state parse_srh_segment_8 { transition select(hdr.srv6_srh.last_entry, hdr.srv6_srh.seg_left) { (8, 9) : set_active_and_parse_srh_next8; (8, 8) : set_active_gsid_and_parse_srh_next8; (8, _) : parse_srh_next_header_8; (_, 9) : set_active_segment_a8; (_, 8) : set_active_g_sid_8; default : parse_srh_segment_b8; } } state parse_srh_segment_b8 { pkt.extract(hdr.srv6_list[8]); transition parse_srh_segment_9; } state set_active_segment_a8 { pkt.extract(hdr.srv6_list[8]); ig_md.srv6.sid = hdr.srv6_list[8].sid; transition parse_srh_segment_9; } state set_active_g_sid_8 { pkt.extract(hdr.srv6_list[8]); ig_md.srv6.g_sid = hdr.srv6_list[8].sid; transition parse_srh_segment_9; } state set_active_gsid_and_parse_srh_next8 { pkt.extract(hdr.srv6_list[8]); ig_md.srv6.g_sid = hdr.srv6_list[8].sid; transition parse_srh_next_header; } state set_active_and_parse_srh_next8 { pkt.extract(hdr.srv6_list[8]); ig_md.srv6.sid = hdr.srv6_list[8].sid; transition parse_srh_next_header; } state parse_srh_next_header_8 { pkt.extract(hdr.srv6_list[8]); transition parse_srh_next_header; }

    state parse_srh_segment_9 {
        transition select(hdr.srv6_srh.last_entry, hdr.srv6_srh.seg_left) {
            (9, 10) : set_active_and_parse_srh_next9;
            (_, 9) : set_active_g_sid_9;
            default : parse_srh_next_header_9;
        }
    }

    state set_active_and_parse_srh_next9 {
        pkt.extract(hdr.srv6_list[9]);
        ig_md.srv6.sid = hdr.srv6_list[9].sid;
        transition parse_srh_next_header;
    }

    state set_active_g_sid_9 {
        pkt.extract(hdr.srv6_list[9]);
        ig_md.srv6.g_sid = hdr.srv6_list[9].sid;
        transition parse_srh_next_header;
    }

    state parse_srh_next_header_9 {
        pkt.extract(hdr.srv6_list[9]);
        transition parse_srh_next_header;
    }

    state parse_srh_next_header {
        transition accept;
/*
        transition select(hdr.srv6_srh.next_hdr) {
            IP_PROTOCOLS_IPV4     : set_inner_ipv4_mode;
            IP_PROTOCOLS_IPV6     : set_inner_ipv6_mode;
            IP_PROTOCOLS_ETHERNET : set_inner_ethernet_mode;
            default               : accept;
        }
*/
    }

    state set_inner_ipv4_mode {
        // ig_md.tunnel.inner_pkt_parsed = SWITCH_TUNNEL_INNER_PKT_IPV4;
        transition accept;
    }

    state set_inner_ipv6_mode {
        // ig_md.tunnel.inner_pkt_parsed = SWITCH_TUNNEL_INNER_PKT_IPV6;
        transition accept;
    }

    state set_inner_ethernet_mode {
        // ig_md.tunnel.inner_pkt_parsed = SWITCH_TUNNEL_INNER_PKT_ETHER;
        transition accept;
    }


    state parse_udp {
        pkt.extract(hdr.udp);
        ig_md.lkp.l4_src_port = hdr.udp.src_port;
        ig_md.lkp.l4_dst_port = hdr.udp.dst_port;
        transition select(hdr.udp.dst_port) {
            udp_port_vxlan : parse_vxlan;
            // UDP_PORT_ROCEV2 : parse_rocev2;
         default : accept;
     }
    }

    state parse_tcp {
        // pkt.extract(hdr.tcp);
        tcp_h tcp = pkt.lookahead<tcp_h>();
        ig_md.lkp.l4_src_port = tcp.src_port;
        ig_md.lkp.l4_dst_port = tcp.dst_port;
        ig_md.lkp.tcp_flags = tcp.flags;
        transition accept;
    }

    state parse_icmp {
        // pkt.extract(hdr.icmp);
        icmp_h icmp = pkt.lookahead<icmp_h>();
        ig_md.lkp.l4_src_port = icmp.typeCode;
        ig_md.lkp.l4_dst_port = 0;
        transition accept;
    }

//     state parse_rocev2 {
// #ifdef ROCEV2_ACL_ENABLE
//         pkt.extract(hdr.rocev2_bth);
// #endif
//         transition accept;
//     }

//     state parse_fcoe {
// #ifdef FCOE_ACL_ENABLE
//         pkt.extract(hdr.fcoe_fc);
// #endif
//         transition accept;
//     }

    state parse_vxlan {

        pkt.extract(hdr.vxlan);
        transition accept;



    }

    // state parse_inner_ipv4 {
    //     ig_md.tunnel.inner_pkt_parsed = SWITCH_TUNNEL_INNER_PKT_IPV4;
    //     transition accept;
    // }

    // state parse_inner_ipv6 {
    //     ig_md.tunnel.inner_pkt_parsed = SWITCH_TUNNEL_INNER_PKT_IPV6;
    //     transition accept;
    // }

    // state parse_inner_icmp {
    //     pkt.extract(hdr.inner_icmp);
    //     transition accept;
    // }
    state parse_inner_ethernet {
        pkt.extract(hdr.inner_ethernet);
        ig_md.lkp.mac_src_addr = hdr.inner_ethernet.src_addr;
        ig_md.lkp.mac_dst_addr = hdr.inner_ethernet.dst_addr;
        transition select(hdr.inner_ethernet.ether_type) {
            0x0800 : parse_inner_ipv4;
            0x86dd : parse_inner_ipv6;
            default : accept;
        }
    }

    state parse_inner_ipv4 {
        pkt.extract(hdr.inner_ipv4);
        ig_md.lkp.ip_src_addr = (bit<128>)hdr.inner_ipv4.src_addr;
        ig_md.lkp.ip_dst_addr = (bit<128>)hdr.inner_ipv4.dst_addr;
        ig_md.tunnel.inner_pkt_parsed = SWITCH_TUNNEL_INNER_PKT_IPV4;
        ig_md.lkp.ip_proto = hdr.inner_ipv4.protocol;
        transition select(hdr.inner_ipv4.protocol, hdr.inner_ipv4.ihl, hdr.inner_ipv4.flags, hdr.inner_ipv4.frag_offset) {
            (17, 5, 0 &&& 1, 0) : parse_inner_udp;
            (6, 5, 0 &&& 1, 0) : parse_inner_tcp;
            default : accept;
        }
    }

    state parse_inner_ipv6 {
        pkt.extract(hdr.inner_ipv6);
        ig_md.lkp.ip_src_addr = hdr.inner_ipv6.src_addr;
        ig_md.lkp.ip_dst_addr = hdr.inner_ipv6.dst_addr;
        ig_md.tunnel.inner_pkt_parsed = SWITCH_TUNNEL_INNER_PKT_IPV6;
        ig_md.lkp.ip_proto = hdr.inner_ipv6.next_hdr;
        ig_md.lkp.flow_label = hdr.inner_ipv6.flow_label;
        transition select(hdr.inner_ipv6.next_hdr) {
            6 : parse_inner_tcp;
            17 : parse_inner_udp;
            default : accept;
        }
    }

    state parse_inner_udp {
        pkt.extract(hdr.inner_udp);
        ig_md.lkp.l4_src_port = hdr.inner_udp.src_port;
        ig_md.lkp.l4_dst_port = hdr.inner_udp.dst_port;
        transition accept;
    }

    state parse_inner_tcp {
        pkt.extract(hdr.inner_tcp);
        ig_md.lkp.l4_src_port = hdr.inner_tcp.src_port;
        ig_md.lkp.l4_dst_port = hdr.inner_tcp.dst_port;
        transition accept;
    }

    state parse_inner_icmp {
        pkt.extract(hdr.inner_icmp);
        transition accept;
    }

}

//----------------------------------------------------------------------------
// Egress parser
//----------------------------------------------------------------------------
parser EgParser_front(
        packet_in pkt,
        out switch_header_t hdr,
        out switch_egress_metadata_t eg_md,
        out egress_intrinsic_metadata_t eg_intr_md) {

    value_set<switch_cpu_port_value_set_t>(1) cpu_port;

    @critical
    state start {
        pkt.extract(eg_intr_md);
        eg_md.common.pkt_length = eg_intr_md.pkt_length;
        eg_md.qos.qdepth = eg_intr_md.deq_qdepth;
        eg_md.lkp.ip_type = SWITCH_IP_TYPE_NONE;

        switch_bridged_metadata_lookahead_h mirror_md = pkt.lookahead<switch_bridged_metadata_lookahead_h>();
        transition select(mirror_md.src, mirror_md.type) {
            (SWITCH_PKT_SRC_BRIDGED, BRIDGE_TYPE_DOWNLINK_FRONT) : parse_bridged_pkt_910;
            (SWITCH_PKT_SRC_BRIDGED, BRIDGE_TYPE_UPLINK_FRONT) : parse_bridged_pkt_310;
            (SWITCH_PKT_SRC_BRIDGED, BRIDGE_TYPE_FRONT_FRONT) : parse_bridged_pkt_110;
            (SWITCH_PKT_SRC_BRIDGED, BRIDGE_TYPE_FABRIC_FRONT) : parse_bridged_pkt_710;
            (SWITCH_PKT_SRC_BRIDGED, BRIDGE_TYPE_FPGA_PAUSE) : parse_bridged_pkt_910;

            (SWITCH_PKT_SRC_CLONED_INGRESS, 6) : parse_ig_ipfix_mirrored_metadata;
            (SWITCH_PKT_SRC_CLONED_EGRESS, 6) : parse_eg_ipfix_mirrored_metadata;
            (SWITCH_PKT_SRC_CLONED_INGRESS, 10) : parse_ig_ipfix_on_mirrored_metadata;
            (SWITCH_PKT_SRC_CLONED_EGRESS, 10) : parse_eg_ipfix_on_mirrored_metadata;
            (SWITCH_PKT_SRC_CLONED_INGRESS, 7) : parse_pipe_trace_mirrored_metadata;
            (SWITCH_PKT_SRC_CLONED_EGRESS, 7) : parse_pipe_trace_mirrored_metadata;
            (SWITCH_PKT_SRC_CLONED_EGRESS, 8) : parse_xoff_mirrored_metadata;
            (SWITCH_PKT_SRC_CLONED_EGRESS, 9) : parse_xon_mirrored_metadata;
            (SWITCH_PKT_SRC_CLONED_INGRESS, 11) : parse_pcap_mirrored_metadata;
            (SWITCH_PKT_SRC_CLONED_EGRESS, 11) : parse_pcap_mirrored_metadata;
            (_, 1) : parse_port_mirrored_metadata;
            // (_, SWITCH_MIRROR_TYPE_FRONT_TRACE) : parse_front_trace_mirrored_metadata;

        }
    }

    // @critical
    state parse_bridged_pkt_910 {
        pkt.extract(hdr.switch_bridged_src);
        pkt.extract(hdr.bridged_md_base);
        pkt.extract(hdr.bridged_md_qos);
        pkt.extract(hdr.bridged_md_910);
        eg_md.common.pkt_type = hdr.bridged_md_base.pkt_type;
        eg_md.common.is_mirror = hdr.bridged_md_base.is_mirror;
        eg_md.common.is_mcast = hdr.bridged_md_base.is_mcast;
        eg_md.qos.tc = hdr.bridged_md_qos.tc;
        eg_md.qos.color = hdr.bridged_md_qos.color;
        eg_md.qos.chgDSCP_disable = hdr.bridged_md_qos.chgDSCP_disable;
        eg_md.qos.BA = hdr.bridged_md_qos.BA;
        eg_md.common.track = hdr.bridged_md_qos.track;
        eg_md.flags.drop = hdr.bridged_md_910.drop;
        eg_md.lkp.ip_frag = hdr.bridged_md_910.ip_frag;
        eg_md.policer.bypass = hdr.bridged_md_910.acl_bypass;
        eg_md.common.dst_port = hdr.bridged_md_910.dst_port;
        eg_md.common.iif = hdr.bridged_md_910.iif;
        eg_md.common.oif = hdr.bridged_md_910.oif;
        eg_md.policer.slice1.group_classid = hdr.bridged_md_910.group_classid_1;
        eg_md.policer.slice2.group_classid = hdr.bridged_md_910.group_classid_2;
        eg_md.policer.slice3.group_classid = hdr.bridged_md_910.group_classid_3;
        eg_md.lkp.l4_port_label_32 = hdr.bridged_md_910.l4_port_label_32;
        eg_md.common.hash[15:0] = hdr.bridged_md_910.hash;
        eg_md.ebridge.evlan = hdr.bridged_md_910.evlan;

        transition select(eg_md.common.pkt_type) {
            FABRIC_PKT_TYPE_CCM : parse_bridged_pkt_910_ccm;
            default : parse_ethernet;
        }
    }

    state parse_bridged_pkt_910_ccm {
        eg_md.common.cpu_eth_encap_id = CPU_ETH_ENCAP_CCM;
        transition parse_depth_pad;
    }

    state parse_bridged_pkt_310 {
        pkt.extract(hdr.switch_bridged_src);
        pkt.extract(hdr.bridged_md_base);
        pkt.extract(hdr.bridged_md_qos);
        pkt.advance(32w32);// 4 byte
        pkt.extract(hdr.bridged_md_310);
        eg_md.common.pkt_type = hdr.bridged_md_base.pkt_type;
        eg_md.common.is_mirror = hdr.bridged_md_base.is_mirror;
        eg_md.common.is_mcast = hdr.bridged_md_base.is_mcast;
        eg_md.qos.tc = hdr.bridged_md_qos.tc;
        eg_md.qos.color = hdr.bridged_md_qos.color;
        eg_md.qos.chgDSCP_disable = hdr.bridged_md_qos.chgDSCP_disable;
        eg_md.qos.BA = hdr.bridged_md_qos.BA;
        eg_md.common.track = hdr.bridged_md_qos.track;
        eg_md.common.extend = hdr.bridged_md_310.extend;
        eg_md.common.oif = hdr.bridged_md_310.oif;
        eg_md.common.iif = hdr.bridged_md_310.iif;
        eg_md.common.var_16bit_310 = hdr.bridged_md_310.var_h1;
        // eg_md.common.cpu_reason = hdr.bridged_md_310.cpu_reason;
        // eg_md.common.src_port = hdr.bridged_md_310.src_port;        
        // eg_md.route.dip_l3class_id = hdr.bridged_md_310.dip_l3class_id;
        // eg_md.route.sip_l3class_id = hdr.bridged_md_310.sip_l3class_id;
        eg_md.common.cpu_eth_encap_id = hdr.bridged_md_310.cpu_eth_encap_id;
        // eg_md.flags.bypass_acl = 1;
        transition select(eg_md.common.pkt_type, eg_md.common.is_mcast, hdr.bridged_md_310.extend) {
            (FABRIC_PKT_TYPE_ETH, 0, 0) : parse_ethernet_310;
            (FABRIC_PKT_TYPE_ETH, 0, 1) : parse_ethernet_310;
            (FABRIC_PKT_TYPE_IPV4, 1, 0) : parse_ethernet_310; // MICRO(MC) BFD
            (FABRIC_PKT_TYPE_IPV6, 1, 0) : parse_ethernet_310; // MICRO(MC) BFD
            (FABRIC_PKT_TYPE_IPV4, 0, 0) : parse_ipv4_310; // BFD v4
            (FABRIC_PKT_TYPE_IPV6, 0, 0) : parse_ipv6_310; // BFD v6
            (FABRIC_PKT_TYPE_IPFIX_SPEC_V4, 0, 0) : parse_depth_pad; // IPFIX SPEC
            (FABRIC_PKT_TYPE_IPFIX_SPEC_V6, 0, 0) : parse_depth_pad; // IPFIX SPEC               
            (_, _, 1) : parse_extension_tunnel_decap;
            default : parse_depth_pad;
        }
    }

    state parse_extension_tunnel_decap {
        pkt.extract(hdr.ext_tunnel_decap);
        transition select(eg_md.common.pkt_type, eg_md.common.is_mcast) {
            (FABRIC_PKT_TYPE_ETH, 0) : parse_ethernet_310;
            (FABRIC_PKT_TYPE_ETH, 1) : parse_ethernet_310;
            (FABRIC_PKT_TYPE_IPV4, 1) : parse_ethernet_310; // MICRO(MC) BFD
            (FABRIC_PKT_TYPE_IPV6, 1) : parse_ethernet_310; // MICRO(MC) BFD
            (FABRIC_PKT_TYPE_IPV4, 0) : parse_ipv4_310; // BFD v4
            (FABRIC_PKT_TYPE_IPV6, 0) : parse_ipv6_310; // BFD v6              
            default : parse_depth_pad;
        }
    }

    state parse_ethernet_310 {
        pkt.extract(hdr.ethernet);
        transition select(hdr.ethernet.ether_type) {
            0x8100 : parse_vlan_310;
            default : accept;
        }
    }

    state parse_vlan_310 {
        pkt.extract(hdr.vlan_tag[0]);
        transition select(hdr.vlan_tag[0].ether_type) {
            0x8100 : parse_vlan1_310;
            default : accept;
        }
    }

    state parse_vlan1_310 {
        pkt.extract(hdr.vlan_tag[1]);
        transition accept;
    }

    state parse_ipv4_310 {
        pkt.extract(hdr.ipv4);
        transition select(hdr.ipv4.protocol, hdr.ipv4.ihl, hdr.ipv4.frag_offset) {
            (_, 6, _) : parse_ipv4_options;
            (_, 5, _) : accept;
            default : parse_ipv4_options_2;
        }
    }

    state parse_ipv4_options_2_310 {
        eg_md.common.ip_opt2_chksum_enable = true;
        transition accept;
    }

    state parse_ipv4_options_310 {
        pkt.extract(hdr.ipv4_option);
        transition accept;
    }

    state parse_ipv6_310 {
        pkt.extract(hdr.ipv6);
        transition accept;
    }

    // state parse_bridged_end {
    //     transition select(eg_md.common.pkt_type, eg_md.common.is_mcast) {
    //         (FABRIC_PKT_TYPE_ETH, 0) : parse_ethernet;           
    //         (FABRIC_PKT_TYPE_IPV4, 1) : parse_ethernet;          // MICRO(MC) BFD
    //         (FABRIC_PKT_TYPE_IPV6, 1) : parse_ethernet;          // MICRO(MC) BFD
    //         (FABRIC_PKT_TYPE_IPV4, 0) : parse_ipv4;              // BFD
    //         (FABRIC_PKT_TYPE_IPV6, 0) : parse_ipv6;              // BFD
    //         (FABRIC_PKT_TYPE_IPFIX_SPEC_V4, 0) : parse_ipv4;     // IPFIX SPEC
    //         (FABRIC_PKT_TYPE_IPFIX_SPEC_V6, 0) : parse_ipv6;     // IPFIX SPEC
    //         default : accept;
    //     }
    // }

    state parse_bridged_pkt_110 {
        pkt.extract(hdr.switch_bridged_src);
        pkt.extract(hdr.bridged_md_base);
        pkt.extract(hdr.bridged_md_qos);
        pkt.extract(hdr.bridged_md_110);
        eg_md.common.pkt_type = hdr.bridged_md_base.pkt_type;
        eg_md.common.is_mirror = hdr.bridged_md_base.is_mirror;
        eg_md.common.is_mcast = hdr.bridged_md_base.is_mcast;
        eg_md.qos.tc = hdr.bridged_md_qos.tc;
        eg_md.qos.color = hdr.bridged_md_qos.color;
        eg_md.qos.chgDSCP_disable = hdr.bridged_md_qos.chgDSCP_disable;
        eg_md.qos.BA = hdr.bridged_md_qos.BA;
        eg_md.common.track = hdr.bridged_md_qos.track;
        eg_md.common.dst_port = hdr.bridged_md_110.dst_port;
        transition parse_ethernet;
    }

    state parse_bridged_pkt_710 {
        switch_bridged_metadata_710_h bridged_md_710;

        pkt.extract(hdr.switch_bridged_src);
        pkt.extract(hdr.bridged_md_base);
        pkt.extract(hdr.bridged_md_qos);
        pkt.extract(bridged_md_710);
        eg_md.common.pkt_type = hdr.bridged_md_base.pkt_type;
        eg_md.common.is_mirror = hdr.bridged_md_base.is_mirror;
        eg_md.common.is_mcast = hdr.bridged_md_base.is_mcast;
        eg_md.qos.tc = hdr.bridged_md_qos.tc;
        eg_md.qos.color = hdr.bridged_md_qos.color;
        eg_md.qos.chgDSCP_disable = hdr.bridged_md_qos.chgDSCP_disable;
        eg_md.qos.BA = hdr.bridged_md_qos.BA;
        eg_md.common.track = hdr.bridged_md_qos.track;
        eg_md.common.dst_port = bridged_md_710.dst_port;
        transition parse_mirror_ethernet;
    }

    state parse_port_mirrored_metadata {
        switch_port_mirror_metadata_h port_md;
        pkt.extract(port_md);
        eg_md.mirror.src = port_md.src;
        eg_md.mirror.type = port_md.type;
        // eg_md.qos.mirror_type = port_md.type;
        eg_md.mirror.span_flag = port_md.span_flag;
        eg_md.mirror.sample_flag = port_md.sample_flag;
        eg_md.mirror.backpush_flag = port_md.backpush_flag;
        // eg_md.mirror.session_id = port_md.session_id;
        eg_md.common.iif = port_md.iif;
        eg_md.common.oif = port_md.oif;
        eg_md.common.hash = port_md.hash;
        eg_md.common.backpush_dst_port = port_md.dst_port;
        eg_md.common.dst_port = port_md.cpu_code[7:0];
        eg_md.common.is_mirror = 1;
        transition parse_mirror_ethernet;
    }

    state parse_xoff_mirrored_metadata {
        switch_port_mirror_metadata_h port_md;
        pkt.extract(port_md);
        eg_md.mirror.src = port_md.src;
        eg_md.mirror.type = port_md.type;
        //eg_md.qos.mirror_type = port_md.type;
        // eg_md.mirror.span_flag = port_md.span_flag;
        // eg_md.mirror.sample_flag = port_md.sample_flag;
        // eg_md.mirror.session_id = port_md.session_id;
        // eg_md.common.iif = port_md.iif;
        // eg_md.common.oif = port_md.oif;
        // eg_md.common.hash = port_md.hash;
        eg_md.common.backpush_dst_port = port_md.dst_port;
        eg_md.common.dst_port = 0; // avoid backpush encap 1br
        eg_md.common.cpu_eth_encap_id = CPU_ETH_ENCAP_XOFF;
        eg_md.common.is_mirror = 1;
        transition parse_mirror_ethernet;
    }

    state parse_xon_mirrored_metadata {
        switch_port_mirror_metadata_h port_md;
        pkt.extract(port_md);
        eg_md.mirror.src = port_md.src;
        eg_md.mirror.type = port_md.type;
        // eg_md.qos.mirror_type = port_md.type;
        // eg_md.mirror.span_flag = port_md.span_flag;
        // eg_md.mirror.sample_flag = port_md.sample_flag;
        // eg_md.mirror.session_id = port_md.session_id;
        // eg_md.common.iif = port_md.iif;
        // eg_md.common.oif = port_md.oif;
        // eg_md.common.hash = port_md.hash;
        eg_md.common.backpush_dst_port = port_md.dst_port;
        eg_md.common.dst_port = 0; // avoid backpush encap 1br
        eg_md.common.cpu_eth_encap_id = CPU_ETH_ENCAP_XON;
        eg_md.common.is_mirror = 1;
        transition parse_mirror_ethernet;
    }

    state parse_ig_ipfix_mirrored_metadata {
        switch_port_mirror_metadata_h ipfix_md;
        pkt.extract(ipfix_md);
        eg_md.mirror.src = ipfix_md.src;
        eg_md.mirror.type = ipfix_md.type;
        eg_md.common.iif = ipfix_md.iif;
        eg_md.common.oif = ipfix_md.oif;
        eg_md.common.hash = ipfix_md.hash;
        eg_md.common.cpu_eth_encap_id = CPU_ETH_ENCAP_IPFIX_IG;
        eg_md.common.is_mirror = 1;
        transition parse_mirror_ethernet;
    }

    state parse_eg_ipfix_mirrored_metadata {
        switch_port_mirror_metadata_h ipfix_md;
        pkt.extract(ipfix_md);
        eg_md.mirror.src = ipfix_md.src;
        eg_md.mirror.type = ipfix_md.type;
        eg_md.common.iif = ipfix_md.iif;
        eg_md.common.oif = ipfix_md.oif;
        eg_md.common.hash = ipfix_md.hash;
        eg_md.common.cpu_eth_encap_id = CPU_ETH_ENCAP_IPFIX_EG;
        eg_md.common.is_mirror = 1;
        transition parse_mirror_ethernet;
    }

    state parse_ig_ipfix_on_mirrored_metadata {
        switch_port_mirror_metadata_h ipfix_md;
        fabric_whole_h fabric_whole;
        pkt.extract(ipfix_md); // 14 bytes
        pkt.extract(fabric_whole); // 16 bytes
        eg_md.mirror.src = ipfix_md.src;
        eg_md.mirror.type = ipfix_md.type;
        eg_md.common.iif = ipfix_md.iif;
        eg_md.common.oif = ipfix_md.oif;
        eg_md.common.hash = ipfix_md.hash;
        eg_md.common.cpu_eth_encap_id = CPU_ETH_ENCAP_IPFIX_IG;
        eg_md.common.is_mirror = 1;
        transition parse_mirror_ethernet;
    }

    state parse_eg_ipfix_on_mirrored_metadata {
        switch_port_mirror_metadata_h ipfix_md;
        fabric_whole_h fabric_whole;
        pkt.extract(ipfix_md); // 14 bytes
        pkt.extract(fabric_whole); // 16 bytes
        eg_md.mirror.src = ipfix_md.src;
        eg_md.mirror.type = ipfix_md.type;
        eg_md.common.iif = ipfix_md.iif;
        eg_md.common.oif = ipfix_md.oif;
        eg_md.common.hash = ipfix_md.hash;
        eg_md.common.cpu_eth_encap_id = CPU_ETH_ENCAP_IPFIX_EG;
        eg_md.common.is_mirror = 1;
        transition parse_mirror_ethernet;
    }

    state parse_pipe_trace_mirrored_metadata {
        switch_pipe_trace_mirror_metadata_h fabric_trace_md;
        pkt.extract(fabric_trace_md);
        eg_md.mirror.src = fabric_trace_md.src;
        eg_md.mirror.type = fabric_trace_md.type;
        eg_md.common.pipeline_location = fabric_trace_md.pipeline_location;
        eg_md.common.dst_port = fabric_trace_md.dst_mirror_port;
        eg_md.common.trace_counter = fabric_trace_md.trace_counter;
        eg_md.common.drop_reason = fabric_trace_md.drop_reason;
        eg_md.common.hash[15:0] = fabric_trace_md.hash;
        eg_md.common.cpu_eth_encap_id = CPU_ETH_ENCAP_PIPELINE_TRACE;
        eg_md.common.is_mirror = 1;
        // transition accept;
        transition parse_depth_pad;
    }

    state parse_pcap_mirrored_metadata {
        switch_port_mirror_metadata_h pcap_md;
        pkt.extract(pcap_md);
        eg_md.mirror.src = pcap_md.src;
        eg_md.mirror.type = pcap_md.type;
        eg_md.common.iif = pcap_md.iif;
        // eg_md.common.cpu_code = pcap_md.cpu_code;
        eg_md.common.cpu_eth_encap_id = CPU_ETH_ENCAP_PCAP;
        eg_md.common.is_mirror = 1;
        transition parse_mirror_ethernet;
    }

    state parse_mirror_ethernet {
        pkt.extract(hdr.ethernet);
        transition select(hdr.ethernet.ether_type) {
            0x893F : parse_mirror_1br;
            // default : accept;
            default : parse_depth_pad;
        }
    }

    state parse_mirror_1br {
        pkt.extract(hdr.br_tag);
        transition select(hdr.br_tag.ether_type) {
            0x8100 : parse_mirror_1br_vlan;
            default : accept;
        }
    }

    state parse_mirror_1br_vlan {
        pkt.extract(hdr.vlan_tag[0]);
        transition accept;
    }

    state parse_packet {
        transition parse_ethernet;
    }

    state parse_l3vpn_passenger {
        transition select(pkt.lookahead<bit<4>>()) {
            0x4 : parse_ipv4;
            0x6 : parse_ipv6;
            default: accept;
        }
    }

    state parse_ethernet {
        pkt.extract(hdr.ethernet);
        // eg_md.ipfix.ether_type = hdr.ethernet.ether_type;
        vlan_tag_h vlan_tag = pkt.lookahead<vlan_tag_h>();
        transition select(hdr.ethernet.ether_type, vlan_tag.ether_type) {
            (0x0800, _) : parse_ipv4;
            (0x86dd, _) : parse_ipv6;
            (0x8847, _) : parse_mpls;
            (0x8100, 0x8100) : parse_qinq;
            (0x8100, _) : parse_vlan;
            default : accept;
        }
    }

    state parse_ipv4 {
        pkt.extract(hdr.ipv4);
        eg_md.ipfix.pkt_type = SWITCH_IPFIX_PKT_TYPE_IPV4;
        eg_md.lkp.ip_type = SWITCH_IP_TYPE_IPV4;
        eg_md.lkp.ip_src_addr[31:0] = hdr.ipv4.src_addr;
        eg_md.lkp.ip_dst_addr[31:0] = hdr.ipv4.dst_addr;
        eg_md.lkp.ip_proto = hdr.ipv4.protocol;
        // eg_md.lkp.ipv4_tos = hdr.ipv4.diffserv;
        transition select(hdr.ipv4.protocol, hdr.ipv4.ihl, hdr.ipv4.frag_offset) {
            (17, 5, 0) : parse_udp;
            (6, 5, 0) : parse_tcp;
            (1, 5, 0) : parse_icmp;




            (_, 6, _) : parse_ipv4_options;
            (_, 5, _) : accept;
            default : parse_ipv4_options_2;
        }
        // transition accept;
    }

    state parse_ipv4_options_2 {
        eg_md.common.ip_opt2_chksum_enable = true;
        transition accept;
    }

    state parse_ipv4_options {
        pkt.extract(hdr.ipv4_option);
        transition select(hdr.ipv4.protocol, hdr.ipv4.frag_offset) {
            (17, 0) : parse_udp;
            (6, 0) : parse_tcp;
            (1, 0) : parse_icmp;
            default : accept;
        }
    }

    state parse_qinq {
        pkt.extract(hdr.vlan_tag[0]);
        pkt.extract(hdr.vlan_tag[1]);
        eg_md.lkp.vid = hdr.vlan_tag[0].vid;
        transition select(hdr.vlan_tag[1].ether_type) {
            0x0800 : parse_ipv4;
            0x86dd : parse_ipv6;
            0x8847 : parse_mpls;
            default : accept;
        }
    }

    state parse_vlan {
        pkt.extract(hdr.vlan_tag[0]);
        eg_md.lkp.vid = hdr.vlan_tag[0].vid;
        transition select(hdr.vlan_tag[0].ether_type) {
            0x0800 : parse_ipv4;
            0x86dd : parse_ipv6;
            0x8847 : parse_mpls;
            default : accept;
        }
    }

    /* by lichunfeng */
    state parse_mpls {
        pkt.extract(hdr.mpls_vc_eg);
        eg_md.ipfix.pkt_type = SWITCH_IPFIX_PKT_TYPE_MPLS;
        eg_md.tunnel.first_label = hdr.mpls_vc_eg.label;
        // transition accept;
        transition parse_depth_pad;
    }
    // state parse_mpls {
    //     pkt.extract(hdr.mpls_ig.next);
    //     transition select(hdr.mpls_ig.last.bos) {
    //         0 : parse_mpls;
    //         1 : parse_mpls_bos;
    //         default : accept;
    //     }
    // }

    // state parse_mpls_bos {
    //     // transition parse_mpls_cw;
    //     transition accept;
    // }

    // @critical
    state parse_ipv6 {

        pkt.extract(hdr.ipv6);
        eg_md.ipfix.pkt_type = SWITCH_IPFIX_PKT_TYPE_IPV6;
        eg_md.lkp.ip_type = SWITCH_IP_TYPE_IPV6;
        eg_md.lkp.ip_src_addr = hdr.ipv6.src_addr;
        eg_md.lkp.ip_dst_addr = hdr.ipv6.dst_addr;
        eg_md.lkp.ip_proto = hdr.ipv6.next_hdr;
        // eg_md.lkp.ipv6_tos = hdr.ipv6.traffic_class;
        transition select(hdr.ipv6.next_hdr) {
            6 : parse_tcp;
            17 : parse_udp;
            58 : parse_icmp;
            44 : parse_ipv6_frag;




            default : accept;
        }
        // transition accept;



    }

    state parse_ipv6_frag {
        pkt.extract(hdr.ipv6_frag);
        transition select(hdr.ipv6_frag.next_hdr, hdr.ipv6_frag.frag_offset) {
            (6, 0) : parse_tcp;
            (17, 0) : parse_udp;
            (58, 0) : parse_icmp;
            default : accept;
        }
    }

    state parse_udp {
        udp_h udp = pkt.lookahead<udp_h>();
        eg_md.lkp.l4_src_port = udp.src_port;
        eg_md.lkp.l4_dst_port = udp.dst_port;
        eg_md.lkp.tcp_flags = 0;
        transition accept;
    }

    state parse_tcp {
        tcp_h tcp = pkt.lookahead<tcp_h>();
        eg_md.lkp.l4_src_port = tcp.src_port;
        eg_md.lkp.l4_dst_port = tcp.dst_port;
        eg_md.lkp.tcp_flags = tcp.flags;
        transition accept;
    }

    state parse_icmp {
        icmp_h icmp = pkt.lookahead<icmp_h>();
        eg_md.lkp.l4_src_port = icmp.typeCode;
        eg_md.lkp.l4_dst_port = 0;
        eg_md.lkp.tcp_flags = 0;
        transition accept;
    }

    state parse_depth_pad {
        parser_pad_h pad = pkt.lookahead<parser_pad_h>();
        transition select(pad.extend) {
            1 : parse_depth_pad_1;
            default : parse_depth_pad_2;
            // default : accept;
        }
    }

    state parse_depth_pad_1 {
        parser_pad_h pad = pkt.lookahead<parser_pad_h>();
        eg_md.common.parser_pad = 1;
        transition select(pad.extend) {
            1 : parse_depth_pad_2;
            default : parse_depth_pad_3;
        }
    }

    state parse_depth_pad_2 {
        parser_pad_h pad = pkt.lookahead<parser_pad_h>();
        eg_md.common.parser_pad = 1;
        transition select(pad.extend) {
            1 : parse_depth_pad_3;
            default : parse_depth_pad_end;
        }
    }

    state parse_depth_pad_3 {
        parser_pad_h pad = pkt.lookahead<parser_pad_h>();
        eg_md.common.parser_pad = 1;
        transition select(pad.extend) {
            1 : parse_depth_pad_end;
            default : accept;
        }
    }

    state parse_depth_pad_end {
        eg_md.common.parser_pad = 1;
        transition accept;
    }

}


//----------------------------------------------------------------------------
// Mirror packet deparser
//-----------------------------------------------------------------------------
control IgMirror_front(
    inout switch_header_t hdr,
    in switch_ingress_metadata_t ig_md,
    in ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr) {
// Ingress deparser create a copy of the original ingress packet and prepend the prepend the mirror
// header.
    Mirror() mirror;

    apply {

        if (ig_intr_md_for_dprsr.mirror_type == 1) {
            mirror.emit<switch_port_mirror_metadata_h>(
                ig_md.mirror.session_id, {
                ig_md.mirror.src,
                ig_md.mirror.type,



                ig_md.mirror.session_id,
                ig_md.mirror.span_flag,
                ig_md.mirror.sample_flag,
                ig_md.common.ul_iif,
                0,
                ig_md.common.oif,
                ig_md.common.egress_eport,
                ig_md.common.hash[15:0],
                ig_md.common.dst_port,
                ig_md.common.egress_eport
                });
        } else if (ig_intr_md_for_dprsr.mirror_type == 7) {
            mirror.emit<switch_front_ingress_trace_mirror_metadata_plus_h>(
                ig_md.mirror.session_id, {
                ig_md.mirror.src,
                ig_md.mirror.type,



                ig_md.mirror.session_id,
                ig_md.common.egress_eport,
                ig_md.common.trace_counter,
                ig_md.common.dst_port,
                ig_md.common.hash[15:0],

                0,
                ig_md.common.dev_port,
                ig_md.common.hash[15:0],

                ig_md.common.timestamp
                });
        // } else if (ig_intr_md_for_dprsr.mirror_type == SWITCH_MIRROR_TYPE_IPFIX) {
        //     mirror.emit<switch_ipfix_mirror_metadata_h>(ig_md.mirror.session_id, {
        //         ig_md.mirror.src,
        //         ig_md.mirror.type,
        //         0,
        //         ig_md.mirror.session_id,
        //         0,
        //         ig_md.common.ul_iif,
        //         0,
        //         ig_md.common.oif,
        //         ig_md.common.hash});
        // } else if (ig_intr_md_for_dprsr.mirror_type == SWITCH_MIRROR_TYPE_PCAP) {
        //     mirror.emit<switch_pcap_mirror_metadata_h>(ig_md.mirror.session_id, {
        //         ig_md.mirror.src,
        //         ig_md.mirror.type,
        //         ig_md.common.cpu_code});
        }

    }
}

control EgMirror_front(
    inout switch_header_t hdr,
    in switch_egress_metadata_t eg_md,
    in egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr) {
// Egress deparser first construct the output packet and then prepend the mirror header.
    Mirror() mirror;

    apply {

        if (eg_intr_md_for_dprsr.mirror_type == 1) {
            mirror.emit<switch_port_mirror_metadata_h>(eg_md.mirror.session_id, {
                eg_md.mirror.src,
                eg_md.mirror.type,



                eg_md.mirror.session_id,
                eg_md.mirror.span_flag,
                eg_md.mirror.sample_flag,
                eg_md.common.iif,
                eg_md.mirror.backpush_flag,
                eg_md.common.oif,
                eg_md.common.egress_eport,
                eg_md.common.hash[15:0],
                eg_md.common.backpush_dst_port,
                eg_md.common.egress_eport
                });
        } else if (eg_intr_md_for_dprsr.mirror_type == 7) {
            mirror.emit<switch_front_egress_trace_mirror_metadata_plus_h>(eg_md.mirror.session_id, {
                eg_md.mirror.src,
                eg_md.mirror.type,



                eg_md.mirror.session_id,
                eg_md.common.egress_eport,
                eg_md.common.trace_counter,
                eg_md.common.drop_reason,
                eg_md.common.hash[15:0],

                0,
                eg_md.qos.qdepth,

                eg_md.common.timestamp
                });
        }

    }
}

//-----------------------------------------------------------------------------
// Ingress Deparser
//-----------------------------------------------------------------------------
control IgDeparser_front(
    packet_out pkt,
    inout switch_header_t hdr,
    in switch_ingress_metadata_t ig_md,
    in ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr) {

    IgMirror_front() mirror;

    apply {
        mirror.apply(hdr, ig_md, ig_intr_md_for_dprsr);
        // front pipe to inner pipe
        pkt.emit(hdr.switch_bridged_src);
        pkt.emit(hdr.bridged_md_base);
        pkt.emit(hdr.bridged_md_qos_encap);
        pkt.emit(hdr.bridged_md_12_encap); // Ingress only.
        pkt.emit(hdr.bridged_md_110);
        pkt.emit(hdr.ext_srv6);
        pkt.emit(hdr.ext_tunnel_decap_data_encap);
        pkt.emit(hdr.ethernet);
        pkt.emit(hdr.pause_info);

        pkt.emit(hdr.pri_data);

        pkt.emit(hdr.vlan_tag);
        pkt.emit(hdr.mpls_ig);
        pkt.emit(hdr.mpls2_ig);
        // pkt.emit(hdr.cw);
        pkt.emit(hdr.arp); // Ingress only.
        pkt.emit(hdr.ipv4);
        pkt.emit(hdr.ipv6);
        // pkt.emit(hdr.ipv6_frag);
        pkt.emit(hdr.srv6_srh);
        pkt.emit(hdr.srv6_list);
        pkt.emit(hdr.udp);
        pkt.emit(hdr.tcp); // Ingress only.
        pkt.emit(hdr.icmp); // Ingress only.
        pkt.emit(hdr.igmp); // Ingress only.
        pkt.emit(hdr.vxlan);
        pkt.emit(hdr.inner_ethernet);
        pkt.emit(hdr.inner_ipv4);
        pkt.emit(hdr.inner_ipv6);
        pkt.emit(hdr.inner_udp);
        pkt.emit(hdr.inner_tcp);
        pkt.emit(hdr.inner_icmp);
    }
}


//-----------------------------------------------------------------------------
// Egress Deparser
//-----------------------------------------------------------------------------
control EgDeparser_front(
        packet_out pkt,
        inout switch_header_t hdr,
        in switch_egress_metadata_t eg_md,
        in egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr) {

    EgMirror_front() mirror;
    Checksum() ipv4_checksum;
    Checksum() inner_ipv4_checksum;

    apply {
        mirror.apply(hdr, eg_md, eg_intr_md_for_dprsr);


        if (eg_md.common.ip_opt2_chksum_enable) {
            // ihl > 6 don't update checksum
        } else if (hdr.ipv4_option.isValid()) {
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
                hdr.ipv4.dst_addr,
                hdr.ipv4_option.type,
                hdr.ipv4_option.length,
                hdr.ipv4_option.value});
        } else if (hdr.ipv4.isValid()) {
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
        }


        hdr.inner_ipv4.hdr_checksum = inner_ipv4_checksum.update({
            hdr.inner_ipv4.version,
            hdr.inner_ipv4.ihl,
            hdr.inner_ipv4.diffserv,
            hdr.inner_ipv4.total_len,
            hdr.inner_ipv4.identification,
            hdr.inner_ipv4.flags,
            hdr.inner_ipv4.frag_offset,
            hdr.inner_ipv4.ttl,
            hdr.inner_ipv4.protocol,
            hdr.inner_ipv4.src_addr,
            hdr.inner_ipv4.dst_addr});



        pkt.emit(hdr.ethernet);
        //by zhuanghui
        pkt.emit(hdr.pause_info);
        // by yeweixin
        pkt.emit(hdr.fabric_to_cpu_eth_base);
        pkt.emit(hdr.fabric_to_cpu_eth_data);
        pkt.emit(hdr.fabric_eth_etype);
        pkt.emit(hdr.ext_tunnel_decap);

        pkt.emit(hdr.timestamp); // Egress only.
        pkt.emit(hdr.br_tag);
        pkt.emit(hdr.vlan_tag);
        // pkt.emit(hdr.cw);
        pkt.emit(hdr.ipv4);
        pkt.emit(hdr.ipv4_option);
        pkt.emit(hdr.ipv6);
        pkt.emit(hdr.ipv6_frag);
        pkt.emit(hdr.tcp);
        pkt.emit(hdr.udp);
        pkt.emit(hdr.icmp);
        pkt.emit(hdr.vxlan);



        pkt.emit(hdr.erspan); // Egress only.
        pkt.emit(hdr.erspan_type2); // Egress only.
        pkt.emit(hdr.erspan_type3); // Egress only.
        pkt.emit(hdr.erspan_platform); // Egress only.
        pkt.emit(hdr.mpls_eg);
        pkt.emit(hdr.mpls_vc_eg);
        // pkt.emit(hdr.mpls_flow_eg);
        pkt.emit(hdr.inner_ethernet);
        pkt.emit(hdr.inner_vlan_tag);
        pkt.emit(hdr.inner_ipv4);
        pkt.emit(hdr.inner_ipv6);
        pkt.emit(hdr.inner_udp);
        pkt.emit(hdr.inner_tcp);
        pkt.emit(hdr.inner_icmp);
    }
}
# 184 "/mnt/p4c-4127/p4src/switch-tofino2/switch_tofino_x1.p4" 2
# 1 "/mnt/p4c-4127/p4src/shared/parde_uplink.p4" 1
/*******************************************************************************
 * BAREFOOT NETWORKS CONFIDENTIAL & PROPRIETARY
 *
 * Copyright (c) 2015-2019 Barefoot Networks, Inc.
 *
 * NOTICE: All information contained herein is, and remains the property of
 * Barefoot Networks, Inc. and its suppliers, if any. The intellectual and
 * technical concepts contained herein are proprietary to Barefoot Networks,
 * Inc.
 * and its suppliers and may be coverep by U.S. and Foreign Patents, patents in
 * process, and are protected by trade secret or copyright law.
 * Dissemination of this information or reproduction of this material is
 * strictly forbidden unless prior written permission is obtained from
 * Barefoot Networks, Inc.
 *
 * No warranty, explicit or implicit is provided, unless granted under a
 * written agreement with Barefoot Networks, Inc.
 *
 ******************************************************************************/

# 1 "/mnt/p4c-4127/p4src/shared/headers.p4" 1
/*******************************************************************************
 * BAREFOOT NETWORKS CONFIDENTIAL & PROPRIETARY
 *
 * Copyright (c) 2015-2019 Barefoot Networks, Inc.

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
 ******************************************************************************/

//-----------------------------------------------------------------------------
// Protocol Header Definitions
//-----------------------------------------------------------------------------
# 22 "/mnt/p4c-4127/p4src/shared/parde_uplink.p4" 2
# 1 "/mnt/p4c-4127/p4src/shared/types.p4" 1
/*******************************************************************************
 * BAREFOOT NETWORKS CONFIDENTIAL & PROPRIETARY
 *
 * Copyright (c) 2015-2019 Barefoot Networks, Inc.

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
 ******************************************************************************/
# 23 "/mnt/p4c-4127/p4src/shared/parde_uplink.p4" 2

//-----------------------------------------------------------------------------
// Segment routing extension header parser
//-----------------------------------------------------------------------------
parser SRHParser(packet_in pkt, inout switch_header_t hdr) {
    state start {

        transition parse_srh;



    }

    state parse_srh {
        //TODO(msharif) : implement SRH parser.
        transition accept;
    }
}

//=============================================================================
// Ingress parser
//=============================================================================
parser IgParser_uplink(
        packet_in pkt,
        out switch_header_t hdr,
        out switch_ingress_metadata_t ig_md,
        out ingress_intrinsic_metadata_t ig_intr_md) {
    Checksum() ipv4_checksum;
    Checksum() inner_ipv4_checksum;

    state start {
        pkt.extract(ig_intr_md);
        transition parse_port_metadata;
    }

    state parse_resubmit {
        // Parse resubmitted packet here.
        transition accept;
    }

    state parse_port_metadata {
        // Parse port metadata produced by ibuf
        switch_port_metadata_uplink_pipe_t port_md = port_metadata_unpack<switch_port_metadata_uplink_pipe_t>(pkt);
        ig_md.common.port_type = port_md.port_type;
        ig_md.common.timestamp = ig_intr_md.ingress_mac_tstamp[31:0];
        ig_md.common.timestamp_250ns = ig_intr_md.ingress_mac_tstamp[39:8];
        transition select(ig_md.common.port_type) {
            PORT_TYPE_FPGA_UPWARD : parse_fpga_ig_packet;
            PORT_TYPE_RECIRC : parse_fpga_ig_packet;
            PORT_TYPE_QOS_RECIRC : parse_qos_recirc;
            default : accept;
        }
    }

    state parse_qos_recirc {
        pkt.extract(hdr.fabric_base);
        pkt.extract(hdr.fabric_qos);
        fabric_unicast_ext_bfn_igfpga_h lookahead = pkt.lookahead<fabric_unicast_ext_bfn_igfpga_h>();
        ig_md.common.src_port = lookahead.src_port;
        ig_md.flags.bypass_fabric_lag = 1;
        transition accept;
    }

    state parse_fpga_ig_packet {
        ig_md.common.bridge_type = BRIDGE_TYPE_UPLINK_FABRIC;
        fabric_base_lookahead_h lookahead = pkt.lookahead<fabric_base_lookahead_h>();
        transition select(lookahead.is_mcast) {
            0 : parse_fpga_ig_unicast;
            1 : parse_fpga_ig_mcast;
            default : accept;
        }
    }

    state parse_fpga_ig_mcast {
        pkt.extract(hdr.fabric_base);
        pkt.extract(hdr.fabric_qos);
        // ig_md.common.pkt_type = hdr.fabric_base.pkt_type;
        // ig_md.common.is_mirror = hdr.fabric_base.is_mirror;
        // ig_md.common.is_mcast = hdr.fabric_base.is_mcast;
        // ig_md.common.track = hdr.fabric_qos.track;
        transition select(hdr.fabric_base.pkt_type) {
            FABRIC_PKT_TYPE_ETH : parse_fpga_ig_mcast_eth;
            /* by zhangjunjie */
            FABRIC_PKT_TYPE_CCM : parse_fpga_ig_mcast_ccm;
            default : parse_fpga_ig_mcast_ip;
        }
    }

    state parse_fpga_ig_mcast_ip {
        pkt.extract(hdr.fabric_unicast_ext_igfpga_bfn);
        pkt.extract(hdr.fabric_crsp);
        pkt.extract(hdr.fabric_nexthop);
        pkt.extract(hdr.fabric_var_ext_1_16bit);
        pkt.extract(hdr.fabric_one_pad_3);
        // evade compiler bug, assignment in parser
        ig_md.flags.fwd_fail = hdr.fabric_unicast_ext_igfpga_bfn.fwd_fail;
        ig_md.flags.glean = hdr.fabric_unicast_ext_igfpga_bfn.glean;
        ig_md.common.iif = hdr.fabric_one_pad_3.iif;
        transition parse_ethernet;
    }

    state parse_fpga_ig_mcast_eth {
        pkt.extract(hdr.fabric_unicast_ext_igfpga_bfn);
        pkt.extract(hdr.fabric_crsp);
        pkt.extract(hdr.fabric_nexthop);
        pkt.extract(hdr.fabric_var_ext_1_16bit);
        pkt.extract(hdr.fabric_one_pad_3);
        pkt.extract(hdr.fabric_eth_ext);
        // evade compiler bug, assignment in parser
        ig_md.flags.fwd_fail = hdr.fabric_unicast_ext_igfpga_bfn.fwd_fail;
        ig_md.flags.glean = hdr.fabric_unicast_ext_igfpga_bfn.glean;
        ig_md.common.iif = hdr.fabric_one_pad_3.iif;
        transition select(hdr.fabric_unicast_ext_igfpga_bfn.extend) {
            1 : parse_fabric_ig_ext_0;
            default : parse_ethernet;
        }
    }

    /* by zhangjunjie */
    state parse_fpga_ig_mcast_ccm {
        pkt.extract(hdr.fabric_unicast_ext_igfpga_bfn);
        pkt.extract(hdr.fabric_crsp);
        pkt.extract(hdr.fabric_nexthop);
        pkt.extract(hdr.fabric_var_ext_1_16bit);
        pkt.extract(hdr.fabric_one_pad_3);
        pkt.extract(hdr.fabric_from_cpu_eth_ccm);
        transition accept;
    }

    state parse_fpga_ig_unicast {
        pkt.extract(hdr.fabric_base);
        pkt.extract(hdr.fabric_qos);
        // ig_md.common.pkt_type = hdr.fabric_base.pkt_type;
        // ig_md.common.is_mirror = hdr.fabric_base.is_mirror;
        // ig_md.common.is_mcast = hdr.fabric_base.is_mcast;
        // ig_md.common.track = hdr.fabric_qos.track;
        transition select(hdr.fabric_base.pkt_type) {
            FABRIC_PKT_TYPE_ETH : parse_fpga_ig_unicast_eth;
            FABRIC_PKT_TYPE_IPV4 : parse_fpga_ig_unicast_ipv4;
            FABRIC_PKT_TYPE_IPV6 : parse_fpga_ig_unicast_ipv6; // by lichunfeng
            FABRIC_PKT_TYPE_MPLS : parse_fpga_ig_unicast_mpls;
            FABRIC_PKT_TYPE_CPU_ETH : parse_recirc_cpu_eth;
            FABRIC_PKT_TYPE_EOP : parse_recirc_eop;
            FABRIC_PKT_TYPE_CCM : parse_fpga_ig_unicast_ccm;
            FABRIC_PKT_TYPE_IPFIX_SPEC_V4 : parse_fpga_ig_unicast_ipv4;
            FABRIC_PKT_TYPE_IPFIX_SPEC_V6 : parse_fpga_ig_unicast_ipv6;
            default : accept;
        }
    }

    state parse_fpga_ig_unicast_eth {
        pkt.extract(hdr.fabric_unicast_ext_igfpga_bfn);
        pkt.extract(hdr.fabric_crsp);
        pkt.extract(hdr.fabric_nexthop);
        pkt.extract(hdr.fabric_var_ext_1_16bit);
        pkt.extract(hdr.fabric_one_pad_3);
        pkt.extract(hdr.fabric_eth_ext);
        // evade compiler bug, assignment in parser
        ig_md.flags.fwd_fail = hdr.fabric_unicast_ext_igfpga_bfn.fwd_fail;
        ig_md.flags.glean = hdr.fabric_unicast_ext_igfpga_bfn.glean;
        // ig_md.flags.drop = hdr.fabric_unicast_ext_igfpga_bfn.drop;          
        ig_md.common.ul_nhid = hdr.fabric_nexthop.ul_nhid;
        ig_md.common.ol_nhid = hdr.fabric_nexthop.ol_nhid;
        ig_md.common.iif = hdr.fabric_one_pad_3.iif;
        ig_md.common.pkt_length = hdr.fabric_var_ext_1_16bit.data;
        transition select(hdr.fabric_unicast_ext_igfpga_bfn.extend) {
            1 : parse_fabric_ig_ext_0;
            default : parse_ethernet;
        }
    }

    state parse_fpga_ig_unicast_ipv4 {
        pkt.extract(hdr.fabric_unicast_ext_igfpga_bfn);
        pkt.extract(hdr.fabric_crsp);
        pkt.extract(hdr.fabric_nexthop);
        pkt.extract(hdr.fabric_var_ext_1_16bit);
        pkt.extract(hdr.fabric_one_pad_3);
        // evade compiler bug, assignment in parser
        ig_md.flags.fwd_fail = hdr.fabric_unicast_ext_igfpga_bfn.fwd_fail;
        ig_md.flags.glean = hdr.fabric_unicast_ext_igfpga_bfn.glean;
        // ig_md.flags.drop = hdr.fabric_unicast_ext_igfpga_bfn.drop;           
        ig_md.common.ul_nhid = hdr.fabric_nexthop.ul_nhid;
        ig_md.common.ol_nhid = hdr.fabric_nexthop.ol_nhid;
        ig_md.common.iif = hdr.fabric_one_pad_3.iif;
        transition select(hdr.fabric_unicast_ext_igfpga_bfn.extend) {
            1 : parse_fabric_ig_ext_0;
            default : parse_ipv4;
        }
    }

    state parse_fpga_ig_unicast_ipv6 {
        pkt.extract(hdr.fabric_unicast_ext_igfpga_bfn);
        pkt.extract(hdr.fabric_crsp);
        pkt.extract(hdr.fabric_nexthop);
        pkt.extract(hdr.fabric_var_ext_1_16bit);
        pkt.extract(hdr.fabric_one_pad_3);
        // evade compiler bug, assignment in parser
        ig_md.flags.fwd_fail = hdr.fabric_unicast_ext_igfpga_bfn.fwd_fail;
        ig_md.flags.glean = hdr.fabric_unicast_ext_igfpga_bfn.glean;
        // ig_md.flags.drop = hdr.fabric_unicast_ext_igfpga_bfn.drop;           
        ig_md.common.ul_nhid = hdr.fabric_nexthop.ul_nhid;
        ig_md.common.ol_nhid = hdr.fabric_nexthop.ol_nhid;
        ig_md.common.iif = hdr.fabric_one_pad_3.iif;
        transition select(hdr.fabric_unicast_ext_igfpga_bfn.extend) {
            1 : parse_fabric_ig_ext_0;
            default : parse_ipv6;
        }
    }

    state parse_fpga_ig_unicast_mpls {
        pkt.extract(hdr.fabric_unicast_ext_igfpga_bfn);
        pkt.extract(hdr.fabric_crsp);
        pkt.extract(hdr.fabric_nexthop);
        pkt.extract(hdr.fabric_var_ext_1_16bit);
        pkt.extract(hdr.fabric_one_pad_3);
        // evade compiler bug, assignment in parser
        ig_md.flags.fwd_fail = hdr.fabric_unicast_ext_igfpga_bfn.fwd_fail;
        ig_md.flags.glean = hdr.fabric_unicast_ext_igfpga_bfn.glean;
        // ig_md.flags.drop = hdr.fabric_unicast_ext_igfpga_bfn.drop;           
        ig_md.common.ul_nhid = hdr.fabric_nexthop.ul_nhid;
        ig_md.common.ol_nhid = hdr.fabric_nexthop.ol_nhid;
        ig_md.common.pkt_length = hdr.fabric_var_ext_1_16bit.data;
        ig_md.common.iif = hdr.fabric_one_pad_3.iif;
        transition select(hdr.fabric_unicast_ext_igfpga_bfn.extend) {
            1 : parse_fabric_ig_ext_0;
            default : parse_mpls;
        }
    }

    state parse_fabric_ig_ext_0 {
        switch_extension_lookahead_h extension = pkt.lookahead<switch_extension_lookahead_h>();
        ig_md.common.extend = 1w1;
        transition select(extension.ext_type) {
            // FABRIC_EXT_TYPE_L4_NHOP             : parse_extension_l4_nhop;
            FABRIC_EXT_TYPE_L4_ENCAP : parse_extension_l4_encap;
            BRIDGED_MD_EXT_TYPE_TUNNEL_DECAP : parse_extension_tunnel_decap;
            BRIDGED_MD_EXT_TYPE_PADDING_WORD : parse_extension_padding_word;
            default : accept;
        }
    }

    state parse_extension_l4_encap {
        pkt.extract(hdr.ext_l4_encap);
        transition select(hdr.ext_l4_encap.extend) {
            1 : parse_fabric_ig_ext_1;
            default : parse_fabric_uc_end;
        }
    }

    state parse_fabric_ig_ext_1 {
        switch_extension_lookahead_h extension = pkt.lookahead<switch_extension_lookahead_h>();
        transition select(extension.ext_type) {
            BRIDGED_MD_EXT_TYPE_TUNNEL_DECAP : parse_extension_tunnel_decap;
            BRIDGED_MD_EXT_TYPE_PADDING_WORD : parse_extension_padding_word;
            default : accept;
        }
    }

    state parse_extension_tunnel_decap {
        pkt.extract(hdr.ext_tunnel_decap);
        transition select(hdr.ext_tunnel_decap.extend) {
            0 : parse_fabric_uc_end;
            default : accept;
        }
    }

    state parse_extension_padding_word {
        pkt.extract(hdr.ext_padding_word);
        transition select(hdr.ext_padding_word.extend) {
            0 : parse_fabric_uc_end;
            default : accept;
        }
    }

    state parse_fabric_uc_end {
        transition select(hdr.fabric_base.pkt_type, hdr.fabric_base.is_mcast) {
            (FABRIC_PKT_TYPE_ETH, 0) : parse_ethernet;
            (FABRIC_PKT_TYPE_IPV4, 0) : parse_ipv4;
            (FABRIC_PKT_TYPE_IPV6, 0) : parse_ipv6;
            (FABRIC_PKT_TYPE_MPLS, 0) : parse_mpls;
            (_, 1) : parse_ethernet;
            default : accept;
        }
    }

    state parse_recirc_cpu_eth {
        pkt.extract(hdr.fabric_unicast_ext_igfpga_bfn);
        pkt.extract(hdr.fabric_crsp);
        pkt.extract(hdr.fabric_nexthop);
        pkt.extract(hdr.fabric_var_ext_1_16bit);
        pkt.extract(hdr.fabric_one_pad_3);
        ig_md.common.hash[15:0] = hdr.fabric_nexthop.ol_nhid;
        ig_md.common.sn[15:0] = hdr.fabric_nexthop.ol_nhid;
        ig_md.common.iif = hdr.fabric_one_pad_3.iif;
        transition parse_ethernet;
    }

    state parse_recirc_eop {
        pkt.extract(hdr.fabric_unicast_ext_igfpga_bfn);
        pkt.extract(hdr.fabric_crsp);
        pkt.extract(hdr.fabric_nexthop);
        pkt.extract(hdr.fabric_var_ext_1_16bit);
        pkt.extract(hdr.fabric_one_pad_3);
        ig_md.common.sn[15:0] = hdr.fabric_nexthop.ol_nhid;
        ig_md.common.iif = hdr.fabric_one_pad_3.iif;
        transition accept;
    }

    state parse_fpga_ig_unicast_ccm {
        pkt.extract(hdr.fabric_unicast_ext_igfpga_bfn);
        pkt.extract(hdr.fabric_crsp);
        pkt.extract(hdr.fabric_nexthop);
        pkt.extract(hdr.fabric_var_ext_1_16bit);
        pkt.extract(hdr.fabric_one_pad_3);
        pkt.extract(hdr.fabric_from_cpu_eth_ccm);
        transition accept;
    }

    state parse_ethernet {
        pkt.extract(hdr.ethernet);
        ig_md.lkp.mac_src_addr = hdr.ethernet.src_addr;
        ig_md.lkp.mac_dst_addr = hdr.ethernet.dst_addr;
        transition select(hdr.ethernet.ether_type) {
            0x0800 : parse_ipv4;
            0x86dd : parse_ipv6;
            0x8100 : parse_vlan;
            0x0806 : parse_arp;
            // ETHERTYPE_QINQ : parse_vlan;
            // ETHERTYPE_FCOE : parse_fcoe;
            // ETHERTYPE_MPLS : parse_mpls;
            // cpu_port  : parse_cpu;
            default : accept;
        }
    }

    state parse_ipv4 {
        pkt.extract(hdr.ipv4);
        ig_md.lkp.ip_type = SWITCH_IP_TYPE_IPV4;
        ig_md.lkp.ip_pkt_len = hdr.ipv4.total_len;
        ig_md.lkp.ip_src_addr[31:0] = hdr.ipv4.src_addr;
        ig_md.lkp.ip_dst_addr[31:0] = hdr.ipv4.dst_addr;
        ig_md.lkp.ip_proto = hdr.ipv4.protocol;
        ig_md.policer.ttl_dec = hdr.ipv4.ttl;
        ipv4_checksum.add(hdr.ipv4);
        transition select(hdr.ipv4.ihl) {
            5 : parse_ipv4_no_options;
            default : accept;
        }
    }

    state parse_ipv4_no_options {
        ig_md.flags.ipv4_checksum_err = ipv4_checksum.verify();
        transition select(hdr.ipv4.protocol, hdr.ipv4.flags, hdr.ipv4.frag_offset) {
            (1, 0&&&1, 0) : parse_icmp;
            (6, 0&&&1, 0) : parse_tcp;
            (17, 0&&&1, 0) : parse_udp;
            // (IP_PROTOCOLS_IPV4, 0) : parse_ipinip;
            // (IP_PROTOCOLS_IPV6, 0) : parse_ipv6inip;
            // Do NOT parse the next header if IP packet is fragmented.
            default : accept;
        }
        // transition accept;
    }

    state parse_vlan {
        pkt.extract(hdr.vlan_tag.next);
        transition select(hdr.vlan_tag.last.ether_type) {
            0x0800 : parse_ipv4;
            0x8100 : parse_vlan;
            0x86dd : parse_ipv6;
            0x0806 : parse_arp;
            default : accept;
        }
    }

    state parse_arp {
        arp_h arp = pkt.lookahead<arp_h>();
        ig_md.lkp.ip_src_addr[31:0] = arp.sender_ip;
        ig_md.lkp.ip_type = SWITCH_IP_TYPE_IPV4;
        transition accept;
    }

    state parse_mpls {
        pkt.extract(hdr.mpls_ig[0]);
        mpls_lookahead_h lookahead = pkt.lookahead<mpls_lookahead_h>();
        transition select(hdr.mpls_ig[0].bos, lookahead.bos1, lookahead.bos2) {
            (0x0 &&& 0x1, 0x0 &&& 0x1, 0x0 &&& 0x1): parse_mpls3_or_more;
            (0x0 &&& 0x1, 0x0 &&& 0x1, 0x1 &&& 0x1): parse_mpls2;
            (0x0 &&& 0x1, 0x1 &&& 0x1, 0x0 &&& 0x0): parse_mpls1;
            default : parse_mpls_bos;
        }
    }

    state parse_mpls1 {
        pkt.extract(hdr.mpls_ig[1]);
        transition select(pkt.lookahead<bit<4>>()) {
            0x4 : parse_inner_ipv4;
            0x6 : parse_inner_ipv6;
            default: parse_inner_ethernet;
        }
    }

    state parse_mpls2 {
        pkt.extract(hdr.mpls_ig[1]);
        pkt.extract(hdr.mpls_ig[2]);
        transition select(pkt.lookahead<bit<4>>()) {
            0x4 : parse_inner_ipv4;
            0x6 : parse_inner_ipv6;
            default: parse_inner_ethernet;
        }
    }

    state parse_mpls3_or_more {
        pkt.extract(hdr.mpls_ig[1]);
        pkt.extract(hdr.mpls_ig[2]);
        pkt.extract(hdr.mpls_ig[3]);
        mpls_lookahead_h lookahead = pkt.lookahead<mpls_lookahead_h>();
        transition select(hdr.mpls_ig[3].bos, lookahead.bos1, lookahead.bos2) {
            (0x0 &&& 0x1, 0x0 &&& 0x1, 0x0 &&& 0x1): parse_mpls6_or_more;
            (0x0 &&& 0x1, 0x0 &&& 0x1, 0x1 &&& 0x1): parse_mpls5;
            (0x0 &&& 0x1, 0x1 &&& 0x1, 0x0 &&& 0x0): parse_mpls4;
            default : parse_mpls_bos;
        }
    }

    state parse_mpls4 {
        pkt.extract(hdr.mpls_ig[4]);
        transition select(pkt.lookahead<bit<4>>()) {
            0x4 : parse_inner_ipv4;
            0x6 : parse_inner_ipv6;
            default: parse_inner_ethernet;
        }
    }

    state parse_mpls5 {
        pkt.extract(hdr.mpls_ig[4]);
        pkt.extract(hdr.mpls_ig[5]);
        transition select(pkt.lookahead<bit<4>>()) {
            0x4 : parse_inner_ipv4;
            0x6 : parse_inner_ipv6;
            default: parse_inner_ethernet;
        }
    }

    state parse_mpls6_or_more {
        pkt.extract(hdr.mpls_ig[4]);
        pkt.extract(hdr.mpls_ig[5]);
        pkt.extract(hdr.mpls2_ig[0]);
        mpls_lookahead_h lookahead = pkt.lookahead<mpls_lookahead_h>();
        transition select(hdr.mpls2_ig[0].bos, lookahead.bos1, lookahead.bos2) {
            (0x0 &&& 0x1, 0x0 &&& 0x1, 0x0 &&& 0x1): parse_mpls9_or_more;
            (0x0 &&& 0x1, 0x0 &&& 0x1, 0x1 &&& 0x1): parse_mpls8;
            (0x0 &&& 0x1, 0x1 &&& 0x1, 0x0 &&& 0x0): parse_mpls7;
            default : parse_mpls_bos;
        }
    }

    state parse_mpls7 {
        pkt.extract(hdr.mpls2_ig[1]);
        transition select(pkt.lookahead<bit<4>>()) {
            0x4 : parse_inner_ipv4;
            0x6 : parse_inner_ipv6;
            default: parse_inner_ethernet;
        }
    }

    state parse_mpls8 {
        pkt.extract(hdr.mpls2_ig[1]);
        pkt.extract(hdr.mpls2_ig[2]);
        transition select(pkt.lookahead<bit<4>>()) {
            0x4 : parse_inner_ipv4;
            0x6 : parse_inner_ipv6;
            default: parse_inner_ethernet;
        }
    }

    state parse_mpls9_or_more {
        pkt.extract(hdr.mpls2_ig[1]);
        pkt.extract(hdr.mpls2_ig[2]);
        pkt.extract(hdr.mpls2_ig[3]);
        transition select(hdr.mpls2_ig[3].bos) {
            1 : parse_mpls_bos;
            default : accept;
        }
    }

    state parse_mpls_bos {
        transition select(pkt.lookahead<bit<4>>()) {
            0x4 : parse_inner_ipv4;
            0x6 : parse_inner_ipv6;
            default: parse_inner_ethernet;
        }
    }

    state parse_inner_ethernet {
        pkt.extract(hdr.inner_ethernet);
        // ig_md.lkp.mac_src_addr = hdr.inner_ethernet.dst_addr;
        // ig_md.lkp.mac_dst_addr = hdr.inner_ethernet.src_addr;
        transition select(hdr.inner_ethernet.ether_type) {
            0x0800 : parse_inner_ipv4;
            0x86dd : parse_inner_ipv6;
            default : accept;
        }
    }

    state parse_inner_ipv4 {
        pkt.extract(hdr.inner_ipv4);
        ig_md.lkp.ip_src_addr[31:0] = hdr.inner_ipv4.src_addr;
        ig_md.lkp.ip_dst_addr[31:0] = hdr.inner_ipv4.dst_addr;
        ig_md.lkp.ip_proto = hdr.inner_ipv4.protocol;
        transition select(hdr.inner_ipv4.protocol, hdr.inner_ipv4.ihl, hdr.inner_ipv4.flags, hdr.inner_ipv4.frag_offset) {
            (17, 5, 0 &&& 1, 0) : parse_inner_udp;
            (6, 5, 0 &&& 1, 0) : parse_inner_tcp;
            default : accept;
        }
    }

    state parse_inner_ipv6 {
        pkt.extract(hdr.inner_ipv6);
        ig_md.lkp.ip_src_addr = hdr.inner_ipv6.src_addr;
        ig_md.lkp.ip_dst_addr = hdr.inner_ipv6.dst_addr;
        ig_md.lkp.ip_proto = hdr.inner_ipv6.next_hdr;
        ig_md.lkp.flow_label = hdr.inner_ipv6.flow_label;
        transition select(hdr.inner_ipv6.next_hdr) {
            6 : parse_inner_tcp;
            17 : parse_inner_udp;
            default : accept;
        }
    }

    state parse_inner_udp {
        pkt.extract(hdr.inner_udp);
        ig_md.lkp.l4_src_port = hdr.inner_udp.src_port;
        ig_md.lkp.l4_dst_port = hdr.inner_udp.dst_port;
        transition accept;
    }

    state parse_inner_tcp {
        pkt.extract(hdr.inner_tcp);
        ig_md.lkp.l4_src_port = hdr.inner_tcp.src_port;
        ig_md.lkp.l4_dst_port = hdr.inner_tcp.dst_port;
        transition accept;
    }

    state parse_ipv6 {

        pkt.extract(hdr.ipv6);
        ig_md.lkp.ip_type = SWITCH_IP_TYPE_IPV6;
        ig_md.lkp.ip_pkt_len = hdr.ipv6.payload_len;
        ig_md.lkp.ip_src_addr = hdr.ipv6.src_addr;
        ig_md.lkp.ip_dst_addr = hdr.ipv6.dst_addr;
        ig_md.lkp.ip_proto = hdr.ipv6.next_hdr;
        ig_md.lkp.flow_label = hdr.ipv6.flow_label;
        ig_md.policer.ttl_dec = hdr.ipv6.hop_limit;
        transition select(hdr.ipv6.next_hdr) {
            58 : parse_icmp;
            6 : parse_tcp;
            17 : parse_udp;
            // IP_PROTOCOLS_FRAGMENT : parse_ipv6_frag;
            // IP_PROTOCOLS_IPV4 : parse_ipinip;
            // IP_PROTOCOLS_IPV6 : parse_ipv6inip;
            default : accept;
        }
        // transition accept;



    }

    state parse_ipv6_frag {
        pkt.extract(hdr.ipv6_frag);
        transition select(hdr.ipv6_frag.next_hdr, hdr.ipv6_frag.frag_offset) {
            (6, 0) : parse_tcp;
            (17, 0) : parse_udp;
            (58, 0) : parse_icmp;
            default : accept;
        }
    }

    state parse_udp {
        udp_h udp = pkt.lookahead<udp_h>();
        ig_md.lkp.l4_src_port = udp.src_port;
        ig_md.lkp.l4_dst_port = udp.dst_port;
        transition accept;
    }

    state parse_tcp {
        tcp_h tcp = pkt.lookahead<tcp_h>();
        ig_md.lkp.l4_src_port = tcp.src_port;
        ig_md.lkp.l4_dst_port = tcp.dst_port;
        // ig_md.lkp.tcp_flags = tcp.flags;
        transition accept;
    }

    state parse_icmp {
        // pkt.extract(hdr.icmp);
        icmp_h icmp = pkt.lookahead<icmp_h>();
        ig_md.lkp.l4_src_port = icmp.typeCode;
        ig_md.lkp.l4_dst_port = 0;
        transition accept;
    }
}

//----------------------------------------------------------------------------
// Egress parser
//----------------------------------------------------------------------------
parser EgParser_uplink(
        packet_in pkt,
        out switch_header_t hdr,
        out switch_egress_metadata_t eg_md,
        out egress_intrinsic_metadata_t eg_intr_md) {
    Checksum() ipv4_checksum;
    value_set<bit<16>>(1) udp_port_vxlan;
    value_set<switch_cpu_port_value_set_t>(1) cpu_port;

    @critical
    state start {
        pkt.extract(eg_intr_md);
        eg_md.common.pkt_length = eg_intr_md.pkt_length;
        eg_md.qos.qdepth = eg_intr_md.deq_qdepth;
        eg_md.ebridge.checks.same_if = 0X3FFF;

        switch_bridged_metadata_lookahead_h mirror_md = pkt.lookahead<switch_bridged_metadata_lookahead_h>();
        transition select(mirror_md.src, mirror_md.type) {
            (SWITCH_PKT_SRC_BRIDGED, BRIDGE_TYPE_FRONT_UPLINK) : parse_bridged_pkt_12;
            (SWITCH_PKT_SRC_CLONED_EGRESS, 12) : parse_eop_mirrored_metadata;
        }
    }

    state parse_eop_mirrored_metadata {
        switch_port_mirror_metadata_h port_md;
        fabric_base_h fabric_base;
        fabric_qos_h fabric_qos;
        fabric_unicast_ext_fe_encap_h fabric_unicast_ext_fe_encap;
        fabric_var_ext_1_16bit_h fabric_var_ext_1_16bit;
        fabric_one_pad_h fabric_one_pad;
        fabric_unicast_ext_fe_2_encap_h fabric_unicast_ext_fe_2_encap;
        pkt.extract(port_md);
        pkt.extract(fabric_base);
        pkt.extract(fabric_qos);
        // pkt.extract(hdr.fabric_unicast_dst);// fabric_unicast_dst used as vh
        pkt.extract(fabric_var_ext_1_16bit);// fabric_unicast_dst used as vh
        pkt.extract(fabric_unicast_ext_fe_encap);
        // pkt.extract(fabric_var_ext_1_16bit);// 2 byte
        // pkt.extract(fabric_one_pad);// 2 byte
        // pkt.extract(fabric_unicast_ext_fe_2_encap);// 2 byte
        pkt.advance(32w48);// 6 byte

        eg_md.common.pkt_type = FABRIC_PKT_TYPE_EOP;
        // eg_md.common.is_mirror = 0;
        eg_md.common.is_mcast = 0;
        eg_md.qos.tc = fabric_qos.tc;
        eg_md.qos.color = fabric_qos.color;
        eg_md.qos.chgDSCP_disable = fabric_qos.chgDSCP_disable;
        eg_md.qos.BA = fabric_qos.BA;
        eg_md.common.track = fabric_qos.track;
        eg_md.common.egress_eport = fabric_var_ext_1_16bit.data;
        eg_md.common.hash[15:0] = fabric_unicast_ext_fe_encap.hash;
        transition parse_depth_pad;
    }

    state parse_depth_pad {
        parser_pad_h pad = pkt.lookahead<parser_pad_h>();
        transition select(pad.extend) {
            1 : parse_depth_pad_1;
            default : parse_depth_pad_2;
            // default : accept;
        }
    }

    state parse_depth_pad_1 {
        parser_pad_h pad = pkt.lookahead<parser_pad_h>();
        eg_md.common.parser_pad = 1;
        transition select(pad.extend) {
            1 : parse_depth_pad_2;
            default : parse_depth_pad_3;
        }
    }

    state parse_depth_pad_2 {
        parser_pad_h pad = pkt.lookahead<parser_pad_h>();
        eg_md.common.parser_pad = 1;
        transition select(pad.extend) {
            1 : parse_depth_pad_3;
            default : parse_depth_pad_end;
        }
    }

    state parse_depth_pad_3 {
        parser_pad_h pad = pkt.lookahead<parser_pad_h>();
        eg_md.common.parser_pad = 1;
        transition select(pad.extend) {
            1 : parse_depth_pad_end;
            default : accept;
        }
    }

    state parse_depth_pad_end {
        eg_md.common.parser_pad = 1;
        transition accept;
    }

    // @critical
    state parse_bridged_pkt_12 {
        pkt.extract(hdr.switch_bridged_src); //only extract
        pkt.extract(hdr.bridged_md_base);
        pkt.extract(hdr.bridged_md_qos);
        pkt.extract(hdr.bridged_md_12);
        eg_md.common.bridge_type = hdr.switch_bridged_src.bridge_type;
        // eg_md.common.port_type = PORT_TYPE_FPGA_UPWARD;     // egress_port type: to FPGA_UPWARD
        eg_md.common.pkt_type = hdr.bridged_md_base.pkt_type;
        eg_md.common.is_mcast = hdr.bridged_md_base.is_mcast;
        eg_md.qos.tc = hdr.bridged_md_qos.tc;
        eg_md.qos.color = hdr.bridged_md_qos.color;
        eg_md.qos.chgDSCP_disable = hdr.bridged_md_qos.chgDSCP_disable;
        eg_md.qos.BA = hdr.bridged_md_qos.BA;
        eg_md.common.track = hdr.bridged_md_qos.track;
        eg_md.route.rmac_hit = hdr.bridged_md_12.rmac_hit;
        eg_md.flags.escape_etm = hdr.bridged_md_12.escape_etm;
        eg_md.tunnel.ttl_copy = hdr.bridged_md_12.ttl_copy;
        eg_md.tunnel.srv6_end_type = hdr.bridged_md_12.srv6_end_type;
        eg_md.common.iif_type = hdr.bridged_md_12.iif_type;
        eg_md.stp.state = hdr.bridged_md_12.stp_state;
        eg_md.common.svi_flag = hdr.bridged_md_12.svi_flag;
        eg_md.tunnel.type = hdr.bridged_md_12.tunnel_type;
        eg_md.common.src_port = hdr.bridged_md_12.src_port;
        eg_md.common.drop_reason = hdr.bridged_md_12.drop_reason;
        eg_md.common.iif = hdr.bridged_md_12.iif;
        eg_md.policer.iif = hdr.bridged_md_12.iif;
        eg_md.qos.car_flag = hdr.bridged_md_12.car_flag;
        eg_md.common.ul_iif = hdr.bridged_md_12.ul_iif;
        eg_md.tunnel.ttl = hdr.bridged_md_12.ttl;
        eg_md.tunnel.label_space = hdr.bridged_md_12.label_space;
        eg_md.common.hash = hdr.bridged_md_12.hash;
        eg_md.ebridge.evlan = hdr.bridged_md_12.evlan;
        eg_md.common.egress_eport = hdr.bridged_md_12.egress_eport;
        eg_md.common.udf[15:0] = hdr.bridged_md_12.udf;

        switch_extension_lookahead_h extension = pkt.lookahead<switch_extension_lookahead_h>();
        transition select(eg_md.common.pkt_type, hdr.bridged_md_12.extend, extension.ext_type, extension.extend) {
            (_, 1, BRIDGED_MD_EXT_TYPE_SRV6, 1) : parse_extension_srv6_tunnel_decap;
            (_, 1, BRIDGED_MD_EXT_TYPE_SRV6, 0) : parse_extension_srv6;
            (_, 1, BRIDGED_MD_EXT_TYPE_TUNNEL_DECAP, 0) : parse_extension_tunnel_decap;
            // default : parse_uplink_bridged_end;       
            (FABRIC_PKT_TYPE_IPV4, 0, _, _) : parse_ipv4; // 隧道类
         (FABRIC_PKT_TYPE_IPV6, 0, _, _) : parse_ipv6; // 隧道类
            (FABRIC_PKT_TYPE_MPLS, 0, _, _) : parse_mpls; // mpls类
            default : parse_ethernet; // l2隧道类, VXLAN, 普通IP             
        }
    }

    @critical
    state parse_extension_srv6_tunnel_decap {
        pkt.extract(hdr.ext_srv6);
        eg_md.common.srv6_tc = hdr.ext_srv6.tc[7:2];
        eg_md.common.srv6_set_dscp = hdr.ext_srv6.set_dscp;
        pkt.extract(hdr.ext_tunnel_decap);
        eg_md.common.extend = 1w1;
        // transition parse_uplink_bridged_end;    
        transition select(eg_md.common.pkt_type) {
         // FABRIC_PKT_TYPE_IP           : parse_ip;        // deprecated
            FABRIC_PKT_TYPE_IPV4 : parse_ipv4; // 隧道类
         FABRIC_PKT_TYPE_IPV6 : parse_ipv6; // 隧道类
            // FABRIC_PKT_TYPE_MPLS         : parse_mpls;      // mpls类
            default : parse_ethernet; // l2隧道类, VXLAN, 普通IP
        }
    }

    state parse_extension_srv6 {
        pkt.extract(hdr.ext_srv6);
        eg_md.common.srv6_tc = hdr.ext_srv6.tc[7:2];
        eg_md.common.srv6_set_dscp = hdr.ext_srv6.set_dscp;
        // transition parse_uplink_bridged_end;
        transition select(eg_md.common.pkt_type) {
         // FABRIC_PKT_TYPE_IP           : parse_ip;        // deprecated
            FABRIC_PKT_TYPE_IPV4 : parse_ipv4; // 隧道类
         FABRIC_PKT_TYPE_IPV6 : parse_ipv6; // 隧道类
            // FABRIC_PKT_TYPE_MPLS         : parse_mpls;      // mpls类
            default : parse_ethernet; // l2隧道类, VXLAN, 普通IP
        }
    }

    state parse_extension_tunnel_decap {
        pkt.extract(hdr.ext_tunnel_decap);
        eg_md.common.extend = 1w1;
        // transition parse_uplink_bridged_end;
        transition select(eg_md.common.pkt_type) {
         // FABRIC_PKT_TYPE_IP           : parse_ip;        // deprecated
            FABRIC_PKT_TYPE_IPV4 : parse_ipv4; // 隧道类
         FABRIC_PKT_TYPE_IPV6 : parse_ipv6; // 隧道类
            // FABRIC_PKT_TYPE_MPLS         : parse_mpls;      // mpls类
            default : parse_ethernet; // l2隧道类, VXLAN, 普通IP
        }
    }

    state parse_uplink_bridged_end {
        transition select(eg_md.common.pkt_type) {
         // FABRIC_PKT_TYPE_IP           : parse_ip;        // deprecated
            FABRIC_PKT_TYPE_IPV4 : parse_ipv4; // 隧道类
         FABRIC_PKT_TYPE_IPV6 : parse_ipv6; // 隧道类
            FABRIC_PKT_TYPE_MPLS : parse_mpls; // mpls类
            default : parse_ethernet; // l2隧道类, VXLAN, 普通IP
        }
    }

    state parse_ethernet {
        pkt.extract(hdr.ethernet);
        vlan_tag_h vlan_tag = pkt.lookahead<vlan_tag_h>();
        transition select(hdr.ethernet.ether_type, vlan_tag.ether_type) {
            (0x0800, _) : parse_ipv4;
            (0x86dd, _) : parse_ipv6;
            (0x8100, 0x8100) : parse_qinq;
            (0x8100, _) : parse_vlan;
            // (ETHERTYPE_MPLS, _) : parse_mpls;
            default : accept;
        }
    }

    // deprecated
    // state parse_ip {
    //     transition select(pkt.lookahead<bit<4>>()) {
    //         0x4     : parse_ipv4;
    //         0x6     : parse_ipv6;
    //         default : accept;
    //     }
    // }

    state parse_ipv4 {
        pkt.extract(hdr.ipv4);
        ipv4_checksum.add(hdr.ipv4);
        eg_md.lkp.ip_type = SWITCH_IP_TYPE_IPV4;
        eg_md.lkp.ip_proto = hdr.ipv4.protocol;
        transition select(hdr.ipv4.ihl) {
            5 : parse_ipv4_no_options;
            6 : parse_ipv4_options;
            7 : parse_ipv4_options;
            0x8 &&& 0x8 : parse_ipv4_options;
            default : accept;
        }
    }

    state parse_ipv4_options {
        eg_md.lkp.ip_options = 1;
        transition accept;
    }

    state parse_ipv4_no_options {
        eg_md.flags.ipv4_checksum_err = ipv4_checksum.verify();
        transition select(hdr.ipv4.protocol, hdr.ipv4.frag_offset) {
            (1, 0) : parse_icmp;
            (6, 0) : parse_tcp;
            (17, 0) : parse_udp;
            default : accept;
        }
    }

    state parse_vlan {
        pkt.extract(hdr.vlan_tag[0]);
        transition select(hdr.vlan_tag[0].ether_type) {
            0x0800 : parse_ipv4;
            0x86dd : parse_ipv6;
            default : accept;
        }
    }

    state parse_qinq {
        pkt.extract(hdr.vlan_tag[0]);
        pkt.extract(hdr.vlan_tag[1]);
        transition select(hdr.vlan_tag[1].ether_type) {
            0x0800 : parse_ipv4;
            0x86dd : parse_ipv6;
            default : accept;
        }
    }

    // state parse_mpls {
    //     pkt.extract(hdr.mpls_ig[0]);
    //     transition accept;
    // }
    state parse_mpls {
        pkt.extract(hdr.mpls_ig[0]);
        mpls_lookahead_h lookahead = pkt.lookahead<mpls_lookahead_h>();
        transition select(hdr.mpls_ig[0].bos, lookahead.bos1, lookahead.bos2) {
            (0x0 &&& 0x1, 0x0 &&& 0x1, 0x0 &&& 0x1): parse_mpls3;
            (0x0 &&& 0x1, 0x0 &&& 0x1, 0x1 &&& 0x1): parse_mpls2;
            (0x0 &&& 0x1, 0x1 &&& 0x1, 0x0 &&& 0x0): parse_mpls1;
            default : accept;
        }
    }

    state parse_mpls1 {
        pkt.extract(hdr.mpls_ig[1]);
        transition accept;
    }

    state parse_mpls2 {
        pkt.extract(hdr.mpls_ig[1]);
        pkt.extract(hdr.mpls_ig[2]);
        transition accept;
    }

    state parse_mpls3 {
        pkt.extract(hdr.mpls_ig[1]);
        pkt.extract(hdr.mpls_ig[2]);
        pkt.extract(hdr.mpls_ig[3]);
        transition accept;
    }

    // state parse_mpls_bos {
    //     transition parse_l3vpn_passenger;
    // }

    state parse_ipv6 {

        pkt.extract(hdr.ipv6);
        eg_md.lkp.ip_proto = hdr.ipv6.next_hdr;
        eg_md.lkp.flow_label = hdr.ipv6.flow_label;
        eg_md.lkp.ip_type = SWITCH_IP_TYPE_IPV6;
        eg_md.lkp.ip_pkt_len = hdr.ipv6.payload_len;
        transition select(hdr.ipv6.next_hdr) {
            6 : parse_tcp;
            17 : parse_udp;
            58 : parse_icmp;
            0 : parse_ipv6_option;
            44 : parse_ipv6_frag;
            default : accept;
        }



    }

    state parse_ipv6_frag {
        pkt.extract(hdr.ipv6_frag);
        transition select(hdr.ipv6_frag.next_hdr, hdr.ipv6_frag.frag_offset) {
            (6, 0) : parse_tcp;
            (17, 0) : parse_udp;
            (58, 0) : parse_icmp;
            default : accept;
        }
    }

    state parse_ipv6_option {
        eg_md.lkp.ip_options = 1;
        transition accept;
    }

    state parse_udp {
        // pkt.extract(hdr.udp);
        udp_h udp = pkt.lookahead<udp_h>();
        eg_md.lkp.l4_src_port = udp.src_port;
        eg_md.lkp.l4_dst_port = udp.dst_port;
        eg_md.lkp.tcp_flags = 0;
        transition accept;
    }

    state parse_tcp {
        // pkt.extract(hdr.tcp);
        tcp_h tcp = pkt.lookahead<tcp_h>();
        eg_md.lkp.l4_src_port = tcp.src_port;
        eg_md.lkp.l4_dst_port = tcp.dst_port;
        eg_md.lkp.tcp_flags = tcp.flags;
        transition accept;
    }

    state parse_icmp {
        // pkt.extract(hdr.icmp);
        icmp_h icmp = pkt.lookahead<icmp_h>();
        eg_md.lkp.l4_src_port = icmp.typeCode;
        eg_md.lkp.l4_dst_port = 0;
        eg_md.lkp.tcp_flags = 0;
        transition accept;
    }

//     state parse_vxlan {
// #ifdef VXLAN_ENABLE
//         pkt.extract(hdr.vxlan);
//         // transition parse_inner_ethernet;
//         transition accept;
// #else
//         transition accept;
// #endif
//     }
}


//----------------------------------------------------------------------------
// Mirror packet deparser
//-----------------------------------------------------------------------------
control IgMirror_uplink(
    inout switch_header_t hdr,
    in switch_ingress_metadata_t ig_md,
    in ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr) {
// Ingress deparser create a copy of the original ingress packet and prepend the prepend the mirror
// header.
    Mirror() mirror;

    apply {


        if (ig_intr_md_for_dprsr.mirror_type == 7) {
            mirror.emit<switch_uplink_ingress_trace_mirror_metadata_plus_h>(
                ig_md.mirror.session_id,
                {ig_md.mirror.src,
                ig_md.mirror.type,



                ig_md.mirror.session_id,
                //ig_md.common.pipeline_location,
                //ig_md.common.dst_mirror_port,
                //ig_md.common.trace_counter,
                ig_md.common.trace_32,
                ig_md.common.drop_reason,
                ig_md.common.hash[15:0],

                0,
                ig_md.common.dev_port,
                //ig_md.common.pipeline_location,
                //ig_md.common.dst_mirror_port,
                ig_md.common.hash[15:0],

                ig_md.common.timestamp});
        }

    }
}

control EgMirror_uplink(
    inout switch_header_t hdr,
    in switch_egress_metadata_t eg_md,
    in egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr) {
// Egress deparser first construct the output packet and then prepend the mirror header.
    Mirror() mirror;

    apply {


        if (eg_intr_md_for_dprsr.mirror_type == 7) {
            mirror.emit<switch_uplink_egress_trace_mirror_metadata_plus_h>(
                eg_md.mirror.session_id,
                {eg_md.mirror.src,
                eg_md.mirror.type,



                eg_md.mirror.session_id,
                //eg_md.common.pipeline_location,
                //eg_md.common.dst_mirror_port,
                //eg_md.common.trace_counter,
                eg_md.common.trace_32,
                eg_md.common.drop_reason,
                eg_md.common.hash[15:0],

                0,
                eg_md.qos.qdepth,

                eg_md.common.timestamp});
        }
        else if (eg_intr_md_for_dprsr.mirror_type == 1) {
            mirror.emit<switch_learning_mirror_metadata_h>(
                eg_md.mirror.session_id,
                {eg_md.mirror.src,
                eg_md.mirror.type,



                eg_md.mirror.session_id,
                0,
                eg_md.common.learn_iif,
                eg_md.ebridge.evlan,
                hdr.ethernet.src_addr
                });
        }

    }
}

//-----------------------------------------------------------------------------
// Ingress Deparser
//-----------------------------------------------------------------------------
control IgDeparser_uplink(
    packet_out pkt,
    inout switch_header_t hdr,
    in switch_ingress_metadata_t ig_md,
    in ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr) {

    IgMirror_uplink() mirror;
    Checksum() ipv4_checksum;
    Checksum() inner_ipv4_checksum;

    apply {
        mirror.apply(hdr, ig_md, ig_intr_md_for_dprsr);
// #if !defined(IPV4_CSUM_IN_MAU)
//         if (hdr.ipv4_option.isValid()) {
//             hdr.ipv4.hdr_checksum = ipv4_checksum.update({
//                 hdr.ipv4.version,
//                 hdr.ipv4.ihl,
//                 hdr.ipv4.diffserv,
//                 hdr.ipv4.total_len,
//                 hdr.ipv4.identification,
//                 hdr.ipv4.flags,
//                 hdr.ipv4.frag_offset,
//                 hdr.ipv4.ttl,
//                 hdr.ipv4.protocol,
//                 hdr.ipv4.src_addr,
//                 hdr.ipv4.dst_addr,
//                 hdr.ipv4_option.type,
//                 hdr.ipv4_option.length,
//                 hdr.ipv4_option.value});
//         }
//          else
//          if (hdr.ipv4.isValid()) {
//             hdr.ipv4.hdr_checksum = ipv4_checksum.update({
//                 hdr.ipv4.version,
//                 hdr.ipv4.ihl,
//                 hdr.ipv4.diffserv,
//                 hdr.ipv4.total_len,
//                 hdr.ipv4.identification,
//                 hdr.ipv4.flags,
//                 hdr.ipv4.frag_offset,
//                 hdr.ipv4.ttl,
//                 hdr.ipv4.protocol,
//                 hdr.ipv4.src_addr,
//                 hdr.ipv4.dst_addr});
//         }

// #ifdef TUNNEL_ENABLE
//         hdr.inner_ipv4.hdr_checksum = inner_ipv4_checksum.update({
//             hdr.inner_ipv4.version,
//             hdr.inner_ipv4.ihl,
//             hdr.inner_ipv4.diffserv,
//             hdr.inner_ipv4.total_len,
//             hdr.inner_ipv4.identification,
//             hdr.inner_ipv4.flags,
//             hdr.inner_ipv4.frag_offset,
//             hdr.inner_ipv4.ttl,
//             hdr.inner_ipv4.protocol,
//             hdr.inner_ipv4.src_addr,
//             hdr.inner_ipv4.dst_addr});
// #endif /* TUNNEL_ENABLE */
// #endif /* IPV4_CSUM_IN_MAU */

        // inner pipe to inner pipe
        pkt.emit(hdr.switch_bridged_src);
        // pkt.emit(hdr.bridged_md_base);
        pkt.emit(hdr.fabric_base);
        pkt.emit(hdr.fabric_qos);
        pkt.emit(hdr.fabric_unicast_dst);
        pkt.emit(hdr.bridged_md_34_encap);
        // padding 4byte, then pkt.advance(32w32) in parse_bridged_pkt_310        
        pkt.emit(hdr.bridged_md_310_encap);
        pkt.emit(hdr.bridged_md_310_encap);
        pkt.emit(hdr.fabric_crsp);
        pkt.emit(hdr.fabric_var_ext_1_16bit);
        pkt.emit(hdr.fabric_one_pad_3);

        pkt.emit(hdr.ext_l4_encap);
        pkt.emit(hdr.ext_tunnel_decap);
        pkt.emit(hdr.ext_padding_word);
        pkt.emit(hdr.fabric_eth_ext);

        // common hdr
        pkt.emit(hdr.ethernet);
        pkt.emit(hdr.vlan_tag);
        pkt.emit(hdr.mpls_ig);
        pkt.emit(hdr.mpls2_ig);
        // pkt.emit(hdr.cw);
        pkt.emit(hdr.arp); // Ingress only.
        pkt.emit(hdr.ipv4);
        pkt.emit(hdr.ipv6);
        // pkt.emit(hdr.ipv6_frag);
        pkt.emit(hdr.udp);
        pkt.emit(hdr.tcp); // Ingress only.
        pkt.emit(hdr.icmp); // Ingress only.
        pkt.emit(hdr.igmp); // Ingress only.
        pkt.emit(hdr.vxlan);
        pkt.emit(hdr.inner_ethernet);
        pkt.emit(hdr.inner_ipv4);
        pkt.emit(hdr.inner_ipv6);
        pkt.emit(hdr.inner_udp);
        pkt.emit(hdr.inner_tcp);
        pkt.emit(hdr.inner_icmp);
    }
}


//-----------------------------------------------------------------------------
// Egress Deparser
//-----------------------------------------------------------------------------
control EgDeparser_uplink(
        packet_out pkt,
        inout switch_header_t hdr,
        in switch_egress_metadata_t eg_md,
        in egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr) {

    EgMirror_uplink() mirror;
    // Checksum() ipv4_checksum;
    // Checksum() inner_ipv4_checksum;

    apply {
        mirror.apply(hdr, eg_md, eg_intr_md_for_dprsr);

        // fabric headers
        pkt.emit(hdr.fabric_base);
        // for fabric qos
        pkt.emit(hdr.fabric_qos);
        // for fabric unicast igfpga
        pkt.emit(hdr.fabric_unicast_ext_bfn_igfpga);
        // for fabric unicast xxx
        pkt.emit(hdr.fabric_var_ext_1_16bit);
        pkt.emit(hdr.fabric_var_ext_2_8bit);
        // for fabric one pad
        pkt.emit(hdr.fabric_one_pad);
        pkt.emit(hdr.fabric_post_one_pad);
        pkt.emit(hdr.fabric_post_one_pad_encap);
        pkt.emit(hdr.fabric_eth_ext_encap);

        pkt.emit(hdr.ext_l4_encap);
        pkt.emit(hdr.ext_tunnel_decap);
        pkt.emit(hdr.ext_padding_word);

        pkt.emit(hdr.ethernet);
        pkt.emit(hdr.timestamp); // Egress only.
        pkt.emit(hdr.vlan_tag);
        pkt.emit(hdr.ipv4);
        pkt.emit(hdr.ipv6);
        pkt.emit(hdr.ipv6_frag);
        pkt.emit(hdr.srv6_srh);
        pkt.emit(hdr.srv6_list);
        pkt.emit(hdr.udp);
        pkt.emit(hdr.tcp);
        pkt.emit(hdr.icmp);
        pkt.emit(hdr.vxlan);



        pkt.emit(hdr.erspan); // Egress only.
        pkt.emit(hdr.erspan_type2); // Egress only.
        pkt.emit(hdr.erspan_type3); // Egress only.
        pkt.emit(hdr.erspan_platform); // Egress only.
        pkt.emit(hdr.mpls_ig);
        // pkt.emit(hdr.cw);
        pkt.emit(hdr.inner_ethernet);
        pkt.emit(hdr.inner_ipv4);
        pkt.emit(hdr.inner_ipv6);
        pkt.emit(hdr.inner_udp);
        pkt.emit(hdr.inner_tcp);
        pkt.emit(hdr.inner_icmp);
    }
}
# 185 "/mnt/p4c-4127/p4src/switch-tofino2/switch_tofino_x1.p4" 2
# 1 "/mnt/p4c-4127/p4src/shared/parde_fabric.p4" 1
/*******************************************************************************
 * BAREFOOT NETWORKS CONFIDENTIAL & PROPRIETARY
 *
 * Copyright (c) 2015-2019 Barefoot Networks, Inc.
 *
 * NOTICE: All information contained herein is, and remains the property of
 * Barefoot Networks, Inc. and its suppliers, if any. The intellectual and
 * technical concepts contained herein are proprietary to Barefoot Networks,
 * Inc.
 * and its suppliers and may be coverep by U.S. and Foreign Patents, patents in
 * process, and are protected by trade secret or copyright law.
 * Dissemination of this information or reproduction of this material is
 * strictly forbidden unless prior written permission is obtained from
 * Barefoot Networks, Inc.
 *
 * No warranty, explicit or implicit is provided, unless granted under a
 * written agreement with Barefoot Networks, Inc.
 *
 ******************************************************************************/

# 1 "/mnt/p4c-4127/p4src/shared/headers.p4" 1
/*******************************************************************************
 * BAREFOOT NETWORKS CONFIDENTIAL & PROPRIETARY
 *
 * Copyright (c) 2015-2019 Barefoot Networks, Inc.

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
 ******************************************************************************/

//-----------------------------------------------------------------------------
// Protocol Header Definitions
//-----------------------------------------------------------------------------
# 22 "/mnt/p4c-4127/p4src/shared/parde_fabric.p4" 2
# 1 "/mnt/p4c-4127/p4src/shared/types.p4" 1
/*******************************************************************************
 * BAREFOOT NETWORKS CONFIDENTIAL & PROPRIETARY
 *
 * Copyright (c) 2015-2019 Barefoot Networks, Inc.

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
 ******************************************************************************/
# 23 "/mnt/p4c-4127/p4src/shared/parde_fabric.p4" 2

//-----------------------------------------------------------------------------
// Segment routing extension header parser
//-----------------------------------------------------------------------------
parser SRHParser(packet_in pkt, inout switch_header_t hdr) {
    state start {

        transition parse_srh;



    }

    state parse_srh {
        //TODO(msharif) : implement SRH parser.
        transition accept;
    }
}

//=============================================================================
// Ingress parser
//=============================================================================
parser IgParser_fabric(
        packet_in pkt,
        out switch_header_t hdr,
        out switch_ingress_metadata_t ig_md,
        out ingress_intrinsic_metadata_t ig_intr_md) {
    Checksum() ipv4_checksum;
    Checksum() inner_ipv4_checksum;
    value_set<switch_cpu_port_value_set_t>(1) cpu_port;

    state start {
        pkt.extract(ig_intr_md);
        transition parse_port_metadata;
    }

    state parse_resubmit {
        // Parse resubmitted packet here.
        transition accept;
    }

    state parse_port_metadata {
        // Parse port metadata produced by ibuf
        switch_port_metadata_fabric_pipe_t port_md = port_metadata_unpack<switch_port_metadata_fabric_pipe_t>(pkt);
        ig_md.common.port_type = port_md.port_type;
        // ig_md.common.src_device = port_md.src_device;
        ig_md.common.src_port = port_md.src_port;
        ig_md.common.timestamp = ig_intr_md.ingress_mac_tstamp[31:0];
        transition select(ig_md.common.port_type) {
            PORT_TYPE_FABRIC : parse_fabric_packet;
            PORT_TYPE_RECIRC : parse_fabric_packet;
            PORT_TYPE_CPU_PCIE : parse_cpu_pcie;
            default : accept;
        }
    }

    state parse_cpu_pcie {
        pkt.extract(hdr.fabric_cpu_pcie_base);
        pkt.extract(hdr.fabric_unicast_dst);
        pkt.extract(hdr.fabric_from_cpu_data);
        pkt.extract(hdr.fabric_one_pad_7);
        ig_md.common.track = hdr.fabric_cpu_pcie_base.track;
        ig_md.common.dst_port = hdr.fabric_unicast_dst.dst_port;
        ig_md.ebridge.l2oif = hdr.fabric_from_cpu_data.oif;
        ig_md.common.oif = hdr.fabric_from_cpu_data.oif;
        transition select(hdr.fabric_cpu_pcie_base.cpu_pkt_type) {
            (CPU_PCIE_PKT_TYPE_CPU_TO_CPU) : accept;
            default : parse_ethernet;
        }
    }

    state parse_fabric_packet {
        fabric_base_lookahead_h lookahead = pkt.lookahead<fabric_base_lookahead_h>();
        transition select(lookahead.pkt_type, lookahead.is_mcast, lookahead.is_mirror) {
            (_, 0, 0) : parse_fabric_unicast;
            (_, 1, 0) : parse_fabric_mcast;
            (_, _, 1) : parse_fabric_mirror;
            default : accept;
        }
    }

    state parse_fabric_unicast {
        pkt.extract(hdr.fabric_base);
        pkt.extract(hdr.fabric_qos);
        // ig_md.common.pkt_type = hdr.fabric_base.pkt_type;  
        // ig_md.common.is_mirror = hdr.fabric_base.is_mirror;
        // ig_md.common.is_mcast = hdr.fabric_base.is_mcast;             
        // ig_md.common.track = hdr.fabric_qos.track;         
        transition select(hdr.fabric_base.pkt_type) {
            FABRIC_PKT_TYPE_ETH : parse_fabric_unicast_eth;
            FABRIC_PKT_TYPE_IPV4 : parse_fabric_unicast_ipv4;
            FABRIC_PKT_TYPE_IPV6 : parse_fabric_unicast_ipv6;
            FABRIC_PKT_TYPE_MPLS : parse_fabric_unicast_mpls;
            FABRIC_PKT_TYPE_CPU_ETH : parse_fabric_cpu_eth;
            FABRIC_PKT_TYPE_CPU_PCIE : parse_fabric_cpu_pcie;
            FABRIC_PKT_TYPE_EOP : parse_fabric_eop;
            FABRIC_PKT_TYPE_CCM : parse_fabric_unicast_ccm;
            FABRIC_PKT_TYPE_LEARNING : parse_fabric_unicast_learning;
            // FABRIC_PKT_TYPE_MIRROR_TRAN : parse_fabric_mirror;
            default : accept;
        }
    }

    state parse_fabric_mirror {
        pkt.extract(hdr.fabric_base);
        pkt.extract(hdr.fabric_qos);
        // ig_md.common.pkt_type = hdr.fabric_base.pkt_type;  
        // ig_md.common.is_mcast = hdr.fabric_base.is_mcast;
        // ig_md.common.is_mirror = hdr.fabric_base.is_mirror;             
        // ig_md.common.track = hdr.fabric_qos.track; 
        pkt.extract(hdr.fabric_unicast_dst);
        pkt.extract(hdr.fabric_unicast_ext_fe);
        pkt.extract(hdr.fabric_var_ext_1_16bit);
        pkt.extract(hdr.fabric_one_pad_7);
        pkt.extract(hdr.fabric_unicast_ext_fe_2);
        ig_md.common.dst_port = hdr.fabric_unicast_dst.dst_port;
        // ig_md.common.is_mirror = 1;
        transition parse_mirror_ethernet;
    }

    state parse_fabric_cpu_eth {
        pkt.extract(hdr.fabric_unicast_dst);
        pkt.extract(hdr.fabric_unicast_ext_fe);
        pkt.extract(hdr.fabric_var_ext_1_16bit);
        pkt.extract(hdr.fabric_one_pad_7);
        pkt.extract(hdr.fabric_unicast_ext_fe_2);
        ig_md.common.sn = hdr.fabric_unicast_ext_fe.hash;
        ig_md.common.tmp_sn = hdr.fabric_unicast_ext_fe.hash[9:0];
        ig_md.common.src_device = hdr.fabric_unicast_ext_fe_2.src_device;
        ig_md.flags.is_elephant = hdr.fabric_unicast_ext_fe_2.is_elephant;
        ig_md.flags.escape_etm = hdr.fabric_unicast_ext_fe_2.escape_etm;
        ig_md.common.dst_port = hdr.fabric_unicast_dst.dst_port;
        transition parse_ethernet;
    }

    state parse_fabric_cpu_pcie {
        pkt.extract(hdr.fabric_multicast_src);//YES, use src info
        // pkt.extract(hdr.fabric_multicast_ext);//no need to extract
        // pkt.extract(hdr.fabric_one_pad_7);//no need to extract
        transition accept;
    }

    state parse_fabric_eop {
        pkt.extract(hdr.fabric_unicast_dst);
        pkt.extract(hdr.fabric_unicast_ext_fe);
        pkt.extract(hdr.fabric_var_ext_1_16bit);
        pkt.extract(hdr.fabric_one_pad_7);
        pkt.extract(hdr.fabric_unicast_ext_fe_2);
        ig_md.common.sn = hdr.fabric_unicast_ext_fe.hash;
        ig_md.common.tmp_sn = hdr.fabric_unicast_ext_fe.hash[9:0];
        ig_md.common.src_device = hdr.fabric_unicast_ext_fe_2.src_device;
        ig_md.flags.is_elephant = hdr.fabric_unicast_ext_fe_2.is_elephant;
        ig_md.flags.escape_etm = hdr.fabric_unicast_ext_fe_2.escape_etm;
        ig_md.common.dst_port = hdr.fabric_unicast_dst.dst_port;
        transition accept;
    }

    state parse_fabric_unicast_ccm {
        pkt.extract(hdr.fabric_unicast_dst);
        pkt.extract(hdr.fabric_unicast_ext_fe);
        pkt.extract(hdr.fabric_var_ext_1_16bit);
        pkt.extract(hdr.fabric_one_pad_7);
        pkt.extract(hdr.fabric_unicast_ext_fe_2);
        pkt.extract(hdr.fabric_from_cpu_eth_ccm);
        transition accept;
    }

    state parse_fabric_unicast_learning {
        pkt.extract(hdr.fabric_unicast_dst);
        pkt.extract(hdr.fabric_unicast_ext_fe);
        pkt.extract(hdr.fabric_var_ext_1_16bit);
        pkt.extract(hdr.fabric_one_pad_7);
        pkt.extract(hdr.fabric_learning);
        ig_md.lkp.mac_src_addr = hdr.fabric_learning.mac;
        transition accept;
    }

    state parse_fabric_unicast_eth {
        pkt.extract(hdr.fabric_unicast_dst);
        pkt.extract(hdr.fabric_unicast_ext_fe);
        pkt.extract(hdr.fabric_var_ext_1_16bit);
        pkt.extract(hdr.fabric_one_pad_7);
        pkt.extract(hdr.fabric_unicast_ext_fe_2);
        pkt.extract(hdr.fabric_post_one_pad);
        ig_md.common.sn = hdr.fabric_unicast_ext_fe.hash;
        ig_md.common.tmp_sn = hdr.fabric_unicast_ext_fe.hash[9:0];
        ig_md.common.src_device = hdr.fabric_unicast_ext_fe_2.src_device;
        ig_md.flags.is_elephant = hdr.fabric_unicast_ext_fe_2.is_elephant;
        ig_md.flags.escape_etm = hdr.fabric_unicast_ext_fe_2.escape_etm;
        ig_md.common.dst_port = hdr.fabric_unicast_dst.dst_port;
        ig_md.ebridge.l2oif = hdr.fabric_post_one_pad.l2oif;
        ig_md.common.oif = hdr.fabric_post_one_pad.l2oif;
        transition select(hdr.fabric_unicast_dst.extend) {
            1 : parse_fabric_fe_ext_0;
            default : parse_ethernet;
        }
    }

    state parse_fabric_unicast_ipv4 {
        pkt.extract(hdr.fabric_unicast_dst);
        pkt.extract(hdr.fabric_unicast_ext_fe);
        pkt.extract(hdr.fabric_var_ext_1_16bit);
        pkt.extract(hdr.fabric_one_pad_7);
        pkt.extract(hdr.fabric_unicast_ext_fe_2);
        ig_md.common.sn = hdr.fabric_unicast_ext_fe.hash;
        ig_md.common.tmp_sn = hdr.fabric_unicast_ext_fe.hash[9:0];
        ig_md.common.src_device = hdr.fabric_unicast_ext_fe_2.src_device;
        ig_md.flags.is_elephant = hdr.fabric_unicast_ext_fe_2.is_elephant;
        ig_md.flags.escape_etm = hdr.fabric_unicast_ext_fe_2.escape_etm;
        ig_md.common.dst_port = hdr.fabric_unicast_dst.dst_port;
        transition select(hdr.fabric_unicast_dst.extend) {
            1 : parse_fabric_fe_ext_0;
            default : parse_ipv4;
        }
    }

    state parse_fabric_unicast_ipv6 {
        pkt.extract(hdr.fabric_unicast_dst);
        pkt.extract(hdr.fabric_unicast_ext_fe);
        pkt.extract(hdr.fabric_var_ext_1_16bit);
        pkt.extract(hdr.fabric_one_pad_7);
        pkt.extract(hdr.fabric_unicast_ext_fe_2);
        ig_md.common.sn = hdr.fabric_unicast_ext_fe.hash;
        ig_md.common.tmp_sn = hdr.fabric_unicast_ext_fe.hash[9:0];
        ig_md.common.src_device = hdr.fabric_unicast_ext_fe_2.src_device;
        ig_md.flags.is_elephant = hdr.fabric_unicast_ext_fe_2.is_elephant;
        ig_md.flags.escape_etm = hdr.fabric_unicast_ext_fe_2.escape_etm;
        ig_md.common.dst_port = hdr.fabric_unicast_dst.dst_port;
        transition select(hdr.fabric_unicast_dst.extend) {
            1 : parse_fabric_fe_ext_0;
            default : parse_ipv6;
        }
    }

    state parse_fabric_unicast_mpls {
        pkt.extract(hdr.fabric_unicast_dst);
        pkt.extract(hdr.fabric_unicast_ext_fe);
        pkt.extract(hdr.fabric_var_ext_1_16bit);
        pkt.extract(hdr.fabric_one_pad_7);
        pkt.extract(hdr.fabric_unicast_ext_fe_2);
        ig_md.common.sn = hdr.fabric_unicast_ext_fe.hash;
        ig_md.common.tmp_sn = hdr.fabric_unicast_ext_fe.hash[9:0];
        ig_md.common.src_device = hdr.fabric_unicast_ext_fe_2.src_device;
        ig_md.flags.is_elephant = hdr.fabric_unicast_ext_fe_2.is_elephant;
        ig_md.flags.escape_etm = hdr.fabric_unicast_ext_fe_2.escape_etm;
        ig_md.common.dst_port = hdr.fabric_unicast_dst.dst_port;
        transition select(hdr.fabric_unicast_dst.extend) {
            1 : parse_fabric_fe_ext_0;
            default : parse_mpls;
        }
    }

    state parse_fabric_mcast {
        pkt.extract(hdr.fabric_base);
        pkt.extract(hdr.fabric_qos);
        pkt.extract(hdr.fabric_multicast_src);
        pkt.extract(hdr.fabric_multicast_ext);
        pkt.extract(hdr.fabric_one_pad_7);
        // ig_md.common.pkt_type = hdr.fabric_base.pkt_type;
        // ig_md.common.is_mirror = hdr.fabric_base.is_mirror;
        // ig_md.common.is_mcast = hdr.fabric_base.is_mcast;             
        // ig_md.common.track = hdr.fabric_qos.track;        
        /* by zhangjunjie */

            transition select(hdr.fabric_base.pkt_type) {
                FABRIC_PKT_TYPE_CCM : parse_fabric_mcast_ccm;
                default : parse_fabric_fe_ext_hdr;
            }






    }

    /* by zhangjunjie */
    state parse_fabric_mcast_ccm {
        pkt.extract(hdr.fabric_from_cpu_eth_ccm);
        transition accept;
    }

    /* by zhangjunjie */
    state parse_fabric_fe_ext_hdr {
        transition select(hdr.fabric_multicast_src.extend) {
            1 : parse_fabric_fe_ext_0;
            default : parse_ethernet;
        }
    }

    state parse_fabric_fe_ext_0 {
        switch_extension_lookahead_h extension = pkt.lookahead<switch_extension_lookahead_h>();
        ig_md.common.extend = 1w1;
        transition select(extension.ext_type) {
            FABRIC_EXT_TYPE_L4_ENCAP : parse_extension_l4_encap;
            BRIDGED_MD_EXT_TYPE_TUNNEL_DECAP : parse_extension_tunnel_decap;
            BRIDGED_MD_EXT_TYPE_PADDING_WORD : parse_extension_padding_word;
            default : accept;
        }
    }

    state parse_extension_l4_encap {
        pkt.extract(hdr.ext_l4_encap);
        switch_extension_lookahead_h extension = pkt.lookahead<switch_extension_lookahead_h>();
        transition select(hdr.ext_l4_encap.extend, extension.ext_type) {
            (1, BRIDGED_MD_EXT_TYPE_TUNNEL_DECAP) : parse_extension_tunnel_decap;
            default : parse_fabric_uc_end;
        }
    }

    state parse_extension_tunnel_decap {
        pkt.extract(hdr.ext_tunnel_decap);
        transition select(hdr.ext_tunnel_decap.extend) {
            0 : parse_fabric_uc_end;
            default : accept;
        }
    }

    state parse_extension_padding_word {
        pkt.extract(hdr.ext_padding_word);
        transition select(hdr.ext_padding_word.extend) {
            0 : parse_fabric_uc_end;
            default : accept;
        }
    }

    state parse_fabric_uc_end {
        transition select(hdr.fabric_base.pkt_type, hdr.fabric_base.is_mcast) {
            (FABRIC_PKT_TYPE_ETH, 0) : parse_ethernet;
            (FABRIC_PKT_TYPE_IPV4, 0) : parse_ipv4;
            (FABRIC_PKT_TYPE_IPV6, 0) : parse_ipv6;
            (FABRIC_PKT_TYPE_MPLS, 0) : parse_mpls;
            (_, 1) : parse_ethernet;
            default : accept;
        }
    }

    state parse_ethernet {
        pkt.extract(hdr.ethernet);
        ig_md.lkp.mac_src_addr = hdr.ethernet.src_addr;
        ig_md.lkp.mac_dst_addr = hdr.ethernet.dst_addr;
        vlan_tag_h vlan_tag = pkt.lookahead<vlan_tag_h>();
        transition select(hdr.ethernet.ether_type, vlan_tag.ether_type) {
            (0x0800, _) : parse_ipv4;
            (0x86dd, _) : parse_ipv6;
            (0x8100, 0x8100) : parse_qinq;
            (0x8100, _) : parse_vlan;
            // ETHERTYPE_IPV4 : parse_ipv4;
            // ETHERTYPE_IPV6 : parse_ipv6;
            // ETHERTYPE_VLAN : parse_vlan;
            // ETHERTYPE_QINQ : parse_vlan;
            // ETHERTYPE_FCOE : parse_fcoe;
            // ETHERTYPE_MPLS : parse_mpls;
            // cpu_port  : parse_cpu;
            default : accept;
        }
    }

    state parse_mirror_ethernet {
        pkt.extract(hdr.ethernet);
        ig_md.lkp.mac_src_addr = hdr.ethernet.src_addr;
        ig_md.lkp.mac_dst_addr = hdr.ethernet.dst_addr;
        vlan_tag_h vlan_tag = pkt.lookahead<vlan_tag_h>();
        transition select(hdr.ethernet.ether_type, vlan_tag.ether_type) {
            (0x0800, _) : parse_ipv4;
            (0x86dd, _) : parse_ipv6;
            (0x8847, _) : parse_mpls;
            (0x8100, 0x8100) : parse_qinq;
            (0x8100, _) : parse_vlan;
            // ETHERTYPE_IPV4 : parse_ipv4;
            // ETHERTYPE_IPV6 : parse_ipv6;
            // ETHERTYPE_VLAN : parse_vlan;
            // ETHERTYPE_QINQ : parse_vlan;
            // ETHERTYPE_FCOE : parse_fcoe;
            // ETHERTYPE_MPLS : parse_mpls;
            default : accept;
        }
    }

    state parse_ipv4 {
        pkt.extract(hdr.ipv4);
        ig_md.lkp.ip_src_addr[31:0] = hdr.ipv4.src_addr;
        ig_md.lkp.ip_dst_addr[31:0] = hdr.ipv4.dst_addr;
        ig_md.lkp.ip_proto = hdr.ipv4.protocol;
        ig_md.lkp.ip_type = SWITCH_IP_TYPE_IPV4;
        ipv4_checksum.add(hdr.ipv4);
        transition select(hdr.ipv4.ihl) {
            5 : parse_ipv4_no_options;
            default : accept;
        }
    }

    state parse_ipv4_no_options {
        ig_md.flags.ipv4_checksum_err = ipv4_checksum.verify();
        transition select(hdr.ipv4.protocol, hdr.ipv4.flags, hdr.ipv4.frag_offset) {
            (1, 0&&&1, 0) : parse_icmp;
            (6, 0&&&1, 0) : parse_tcp;
            (17, 0&&&1, 0) : parse_udp;
            // (IP_PROTOCOLS_IPV4, 0) : parse_ipinip;
            // (IP_PROTOCOLS_IPV6, 0) : parse_ipv6inip;
            // Do NOT parse the next header if IP packet is fragmented.
            default : accept;
        }
        // transition accept;
    }

    // state parse_ipv4_no_options {
    //     ig_md.flags.ipv4_checksum_err = ipv4_checksum.verify();
    //     transition select(hdr.ipv4.protocol, hdr.ipv4.frag_offset) {
    //         (IP_PROTOCOLS_ICMP, 0) : parse_icmp;
    //         (IP_PROTOCOLS_TCP, 0) : parse_tcp;
    //         (IP_PROTOCOLS_UDP, 0) : parse_udp;
    //         // (IP_PROTOCOLS_IPV4, 0) : parse_ipinip;
    //         // (IP_PROTOCOLS_IPV6, 0) : parse_ipv6inip;
    //         // Do NOT parse the next header if IP packet is fragmented.
    //         default : accept;
    //     }
    // }

    // state parse_vlan {
    //     pkt.extract(hdr.vlan_tag.next);
    //     transition select(hdr.vlan_tag.last.ether_type) {
    //         ETHERTYPE_IPV4 : parse_ipv4;
    //         ETHERTYPE_VLAN : parse_vlan;
    //         ETHERTYPE_IPV6 : parse_ipv6;
    //         default : accept;
    //     }
    // }

    state parse_vlan {
        pkt.extract(hdr.vlan_tag[0]);
        transition select(hdr.vlan_tag[0].ether_type) {
            0x0800 : parse_ipv4;
            0x86dd : parse_ipv6;
            0x8847 : parse_mpls;
            default : accept;
        }
    }

    state parse_qinq {
        pkt.extract(hdr.vlan_tag[0]);
        pkt.extract(hdr.vlan_tag[1]);
        transition select(hdr.vlan_tag[1].ether_type) {
            0x0800 : parse_ipv4;
            0x86dd : parse_ipv6;
            0x8847 : parse_mpls;
            default : accept;
        }
    }

    state parse_mpls {
        // pkt.extract(hdr.mpls_ig.next);
        // transition select(hdr.mpls_ig.last.bos) {
        pkt.extract(hdr.mpls_fabric_ig.next);
        transition select(hdr.mpls_fabric_ig.last.bos) {
            0 : parse_mpls;
            1 : parse_mpls_bos;
            default : accept;
        }
    }

    state parse_mpls_bos {
        transition select(pkt.lookahead<bit<4>>()) {
            0x4 : parse_inner_ipv4;
            0x6 : parse_inner_ipv6;
            default: parse_inner_ethernet;
        }
    }

    state parse_inner_ethernet {
        pkt.extract(hdr.inner_ethernet);
        transition select(hdr.inner_ethernet.ether_type) {
            0x0800 : parse_inner_ipv4;
            0x86dd : parse_inner_ipv6;
            default : accept;
        }
    }

    state parse_inner_ipv4 {
        pkt.extract(hdr.inner_ipv4);
        ig_md.lkp.ip_src_addr[31:0] = hdr.inner_ipv4.src_addr;
        ig_md.lkp.ip_dst_addr[31:0] = hdr.inner_ipv4.dst_addr;
        ig_md.lkp.ip_proto = hdr.inner_ipv4.protocol;
        transition select(hdr.inner_ipv4.protocol, hdr.inner_ipv4.ihl, hdr.inner_ipv4.frag_offset) {
            (17, 5, 0) : parse_inner_udp;
            (6, 5, 0) : parse_inner_tcp;
            default : accept;
        }
    }

    state parse_inner_ipv6 {
        pkt.extract(hdr.inner_ipv6);
        ig_md.lkp.ip_src_addr = hdr.inner_ipv6.src_addr;
        ig_md.lkp.ip_dst_addr = hdr.inner_ipv6.dst_addr;
        ig_md.lkp.ip_proto = hdr.inner_ipv6.next_hdr;
        ig_md.lkp.flow_label = hdr.inner_ipv6.flow_label;
        transition select(hdr.inner_ipv6.next_hdr) {
            6 : parse_inner_tcp;
            17 : parse_inner_udp;
            default : accept;
        }
    }

    state parse_inner_udp {
        pkt.extract(hdr.inner_udp);
        ig_md.lkp.l4_src_port = hdr.inner_udp.src_port;
        ig_md.lkp.l4_dst_port = hdr.inner_udp.dst_port;
        transition accept;
    }

    state parse_inner_tcp {
        pkt.extract(hdr.inner_tcp);
        ig_md.lkp.l4_src_port = hdr.inner_tcp.src_port;
        ig_md.lkp.l4_dst_port = hdr.inner_tcp.dst_port;
        transition accept;
    }

    // state parse_mpls_bos {
    //     transition accept;
    // }

    state parse_ipv6 {

        pkt.extract(hdr.ipv6);
        ig_md.lkp.ip_src_addr = hdr.ipv6.src_addr;
        ig_md.lkp.ip_dst_addr = hdr.ipv6.dst_addr;
        ig_md.lkp.ip_proto = hdr.ipv6.next_hdr;
        ig_md.lkp.flow_label = hdr.ipv6.flow_label;
        ig_md.lkp.ip_type = SWITCH_IP_TYPE_IPV6;
        transition select(hdr.ipv6.next_hdr) {
            58 : parse_icmp;
            6 : parse_tcp;
            17 : parse_udp;
            // IP_PROTOCOLS_IPV4 : parse_ipinip;
            // IP_PROTOCOLS_IPV6 : parse_ipv6inip;
            default : accept;
        }



    }

    state parse_udp {
        pkt.extract(hdr.udp);
        ig_md.lkp.l4_src_port = hdr.udp.src_port;
        ig_md.lkp.l4_dst_port = hdr.udp.dst_port;
        transition accept;
    }

    state parse_tcp {
        pkt.extract(hdr.tcp);
        ig_md.lkp.l4_src_port = hdr.tcp.src_port;
        ig_md.lkp.l4_dst_port = hdr.tcp.dst_port;
        transition accept;
    }

    state parse_icmp {
        pkt.extract(hdr.icmp);
        ig_md.lkp.l4_src_port = hdr.icmp.typeCode;
        ig_md.lkp.l4_dst_port = 0;
        transition accept;
    }

//     state parse_rocev2 {
// #ifdef ROCEV2_ACL_ENABLE
//         pkt.extract(hdr.rocev2_bth);
// #endif
//         transition accept;
//     }

//     state parse_fcoe {
// #ifdef FCOE_ACL_ENABLE
//         pkt.extract(hdr.fcoe_fc);
// #endif
//         transition accept;
//     }

//     state parse_vxlan {
// #ifdef VXLAN_ENABLE
//         pkt.extract(hdr.vxlan);
//         ig_md.tunnel.type = SWITCH_TUNNEL_TYPE_VXLAN;
//         ig_md.tunnel.id = hdr.vxlan.vni;
//         transition parse_inner_ethernet;
// #else
//         transition accept;
// #endif
//     }

    // state parse_ipinip {
    //     transition accept;
    // }

    // state parse_ipv6inip {
    //     transition accept;
    // }
}

//----------------------------------------------------------------------------
// Egress parser
//----------------------------------------------------------------------------
parser EgParser_fabric(
        packet_in pkt,
        out switch_header_t hdr,
        out switch_egress_metadata_t eg_md,
        out egress_intrinsic_metadata_t eg_intr_md) {

    value_set<bit<16>>(1) udp_port_vxlan;
    value_set<switch_cpu_port_value_set_t>(1) cpu_port;

    @critical
    state start {
        pkt.extract(eg_intr_md);
        eg_md.common.pkt_length = eg_intr_md.pkt_length;
        eg_md.qos.qdepth = eg_intr_md.deq_qdepth;
        eg_md.common.dec_ttl = 1;
        eg_md.tunnel.php_ttl = 1;

        switch_bridged_metadata_lookahead_h mirror_md = pkt.lookahead<switch_bridged_metadata_lookahead_h>();
        transition select(mirror_md.src, mirror_md.type) {
            (SWITCH_PKT_SRC_BRIDGED, BRIDGE_TYPE_UPLINK_FABRIC) : parse_bridged_pkt_34;
            (SWITCH_PKT_SRC_BRIDGED, BRIDGE_TYPE_FABRIC_FABRIC) : parse_bridged_pkt_74;
            (SWITCH_PKT_SRC_CLONED_EGRESS, 13) : parse_learning_mirrored_metadata;

            (_, 1) : parse_port_mirrored_metadata;

        }
    }

    state parse_bridged_pkt_74 {
        switch_bridged_metadata_74_parser_h bridged_md_74;
        pkt.extract(hdr.switch_bridged_src);
        pkt.extract(hdr.bridged_md_base);
        pkt.extract(hdr.fabric_qos);
        pkt.extract(bridged_md_74);

        eg_md.common.pkt_type = hdr.bridged_md_base.pkt_type;
        eg_md.common.is_mirror = hdr.bridged_md_base.is_mirror;
        eg_md.common.is_mcast = hdr.bridged_md_base.is_mcast;
        eg_md.common.track = hdr.fabric_qos.track;
        eg_md.ebridge.evlan = bridged_md_74.evlan;
        eg_md.common.iif = bridged_md_74.iif;
        // pkt.advance(32w224);// padding 28B
        transition parse_depth_pad;
    }

    @critical
    state parse_bridged_pkt_34 {
        pkt.extract(hdr.switch_bridged_src);
        pkt.extract(hdr.bridged_md_base);
        pkt.extract(hdr.fabric_qos);
        pkt.extract(hdr.fabric_unicast_dst);
        pkt.extract(hdr.bridged_md_34);
        eg_md.common.pkt_type = hdr.bridged_md_base.pkt_type;
        eg_md.common.is_mirror = hdr.bridged_md_base.is_mirror;
        eg_md.common.is_mcast = hdr.bridged_md_base.is_mcast;
        eg_md.qos.tc = hdr.fabric_qos.tc;
        eg_md.qos.color = hdr.fabric_qos.color;
        eg_md.qos.chgDSCP_disable = hdr.fabric_qos.chgDSCP_disable;
        eg_md.qos.BA = hdr.fabric_qos.BA;
        eg_md.common.track = hdr.fabric_qos.track;
        eg_md.flags.escape_etm = hdr.bridged_md_34.escape_etm;
        eg_md.common.svi_flag = hdr.bridged_md_34.svi_flag;
        eg_md.tunnel.phpcopy = hdr.bridged_md_34.phpcopy;
        eg_md.tunnel.opcode = hdr.bridged_md_34.opcode;
        eg_md.flags.is_elephant = hdr.bridged_md_34.is_elephant;
        eg_md.flags.glean = hdr.bridged_md_34.glean;
        eg_md.flags.drop = hdr.bridged_md_34.drop;
        eg_md.flags.is_gleaned = hdr.bridged_md_34.is_gleaned;
        eg_md.flags.is_eop = hdr.bridged_md_34.is_eop;
        eg_md.common.cpu_code = hdr.bridged_md_34.cpu_code;
        eg_md.common.cpu_reason = hdr.bridged_md_34.cpu_reason;
        eg_md.common.src_port = hdr.bridged_md_34.src_port;
        eg_md.common.l2_encap = hdr.bridged_md_34.l2_encap;
        eg_md.common.l3_encap = hdr.bridged_md_34.l3_encap;
        eg_md.common.hash[15:0] = hdr.bridged_md_34.hash;
        eg_md.route.overlay_counter_index = hdr.bridged_md_34.overlay_counter_index;
        eg_md.common.iif = hdr.bridged_md_34.iif;
        eg_md.route.dip_l3class_id = hdr.bridged_md_34.dip_l3class_id;
        eg_md.route.sip_l3class_id = hdr.bridged_md_34.sip_l3class_id;
        transition select(hdr.bridged_md_34.extend) {
            // 1 : parse_bridged_34_ext_0;
            1 : parse_bridged_34_ext_0_new;
            default : parse_bridged_end;
        }
    }

    state parse_bridged_34_ext_0_new {
        eg_fabric_extension_lookahead_h extension = pkt.lookahead<eg_fabric_extension_lookahead_h>();
        transition select(extension.ext_type_0, extension.extend_0, extension.ext_type_1, extension.extend_1) {
            (BRIDGED_MD_EXT_TYPE_L4_ENCAP, 1, BRIDGED_MD_EXT_TYPE_TUNNEL_DECAP, 0) : parse_extension_l4_encap_tunnel_decap;
            (BRIDGED_MD_EXT_TYPE_L4_ENCAP, 1, BRIDGED_MD_EXT_TYPE_PADDING_WORD, 0) : parse_extension_l4_encap_padding_word;
            (BRIDGED_MD_EXT_TYPE_L4_ENCAP, 0, _, _) : parse_extension_l4_encap_new;
            (BRIDGED_MD_EXT_TYPE_TUNNEL_DECAP, 0, _, _) : parse_extension_tunnel_decap_new;
            (BRIDGED_MD_EXT_TYPE_PADDING_WORD, 0, _, _) : parse_extension_padding_word_new;
        }
    }

    state parse_extension_l4_encap_tunnel_decap {
        pkt.extract(hdr.ext_l4_encap);
        pkt.extract(hdr.ext_tunnel_decap);
        eg_md.tunnel.l4_encap = hdr.ext_l4_encap.l4_encap;
        transition parse_bridged_end;
    }

    state parse_extension_l4_encap_padding_word {
        pkt.extract(hdr.ext_l4_encap);
        pkt.extract(hdr.ext_padding_word);
        eg_md.tunnel.l4_encap = hdr.ext_l4_encap.l4_encap;
        transition parse_bridged_end;
    }

    state parse_extension_l4_encap_new {
        pkt.extract(hdr.ext_l4_encap);
        eg_md.tunnel.l4_encap = hdr.ext_l4_encap.l4_encap;
        transition parse_bridged_end;
    }

    state parse_extension_tunnel_decap_new {
        pkt.extract(hdr.ext_tunnel_decap);
        transition parse_bridged_end;
    }

    state parse_extension_padding_word_new {
        pkt.extract(hdr.ext_padding_word);
        transition parse_bridged_end;
    }

    state parse_bridged_end {
        // pkt.advance(32w112);// padding 14B
        transition select(eg_md.common.pkt_type, eg_md.common.is_mcast) {
            (FABRIC_PKT_TYPE_ETH, 0) : parse_bridged_eth;
            (FABRIC_PKT_TYPE_IPV4, 0) : parse_ipv4;
            (FABRIC_PKT_TYPE_IPV6, 0) : parse_ipv6;
            (FABRIC_PKT_TYPE_MPLS, 0) : parse_mpls;
            (FABRIC_PKT_TYPE_IPV4, 1) : parse_ipmc_eth;
            (FABRIC_PKT_TYPE_IPV6, 1) : parse_ipmc_eth;
            /* by zhangjunjie */
            (FABRIC_PKT_TYPE_CCM, _) : accept;
            (_, 1) : parse_bridged_eth;
        }
    }

    state parse_ipmc_eth {
        pkt.extract(hdr.ethernet);
        eg_md.lkp.mac_src_addr = hdr.ethernet.src_addr;
        vlan_tag_h vlan_tag = pkt.lookahead<vlan_tag_h>();
        transition select(hdr.ethernet.ether_type, vlan_tag.ether_type) {
            (0x0800, _) : parse_ipv4;
            (0x86dd, _) : parse_ipv6;
            (0x8100, 0x8100) : parse_qinq;
            (0x8100, _) : parse_vlan;
            default : parse_depth_pad;
        }
    }

    state parse_bridged_eth {
        pkt.extract(hdr.ext_eth);
        eg_md.ebridge.evlan = hdr.ext_eth.evlan;
        eg_md.ebridge.l2oif = hdr.ext_eth.l2oif;
        pkt.extract(hdr.ethernet);
        eg_md.lkp.mac_src_addr = hdr.ethernet.src_addr;
        vlan_tag_h vlan_tag = pkt.lookahead<vlan_tag_h>();
        transition select(hdr.ethernet.ether_type, vlan_tag.ether_type) {
            (0x0800, _) : parse_ipv4;
            (0x86dd, _) : parse_ipv6;
            (0x8100, 0x8100) : parse_qinq;
            (0x8100, _) : parse_vlan;
            default : parse_depth_pad;
        }
    }

    state parse_port_mirrored_metadata {
        switch_fabric_port_mirror_metadata_h port_md;
        pkt.extract(port_md);
        pkt.extract(hdr.fabric_unicast_dst);
        eg_md.mirror.src = port_md.src;
        eg_md.mirror.type = port_md.type;
        eg_md.mirror.span_flag = port_md.span_flag;
        eg_md.mirror.sample_flag = port_md.sample_flag;
        eg_md.mirror.backpush_flag = port_md.backpush_flag;
        eg_md.common.iif = port_md.iif;
        eg_md.common.oif = port_md.oif;
        eg_md.common.hash = port_md.hash;
        eg_md.common.backpush_dst_port = port_md.fwd_dst_port;
        // eg_md.common.dst_device = port_md.dst_device;
        // eg_md.common.dst_port = port_md.dst_port;
        eg_md.common.is_mirror = 1;
        eg_md.qos.tc = 0;
        eg_md.qos.color = 0;
        transition parse_mirror_ethernet;
    }

    state parse_learning_mirrored_metadata {
        switch_learning_mirror_metadata_parser_h learn_md;
        pkt.extract(learn_md);
        pkt.extract(hdr.fabric_learning);
        eg_md.common.pkt_type = FABRIC_PKT_TYPE_LEARNING;
        eg_md.common.is_mirror = 0;
        eg_md.common.is_mcast = 0;
        eg_md.common.iif = learn_md.iif;
        eg_md.ebridge.evlan = learn_md.evlan;
        transition parse_depth_pad;
    }

    state parse_mirror_ethernet {
        pkt.extract(hdr.ethernet);
        transition select(hdr.ethernet.ether_type) {
            (0x893F) : parse_mirror_1br;
            (0x8100) : parse_mirror_vlan;
            default : parse_depth_pad;
        }
    }

    state parse_mirror_1br {
        pkt.extract(hdr.br_tag);
        transition select(hdr.br_tag.ether_type) {
            (0x8100) : parse_vlan;
            default : parse_depth_pad;
        }
    }

    state parse_mirror_vlan {
        pkt.extract(hdr.vlan_tag[0]);
        transition parse_depth_pad;
    }

    @critical
    state parse_ipv4 {
        pkt.extract(hdr.ipv4);
        eg_md.lkp.ip_src_addr[31:0] = hdr.ipv4.src_addr;
        // eg_md.lkp.ip_dst_addr[31:0] = hdr.ipv4.dst_addr;
        // eg_md.lkp.ip_proto = hdr.ipv4.protocol;
        // eg_md.lkp.ip_type = SWITCH_IP_TYPE_IPV4;
        // eg_md.lkp.ipv4_tos = hdr.ipv4.diffserv;
        transition select(hdr.ipv4.protocol, hdr.ipv4.ihl, hdr.ipv4.frag_offset) {
            (6, 5, 0) : parse_tcp;
            (17, 5, 0) : parse_udp;
            (1, 5, 0) : parse_icmp;




            (_, 6, _) : parse_ipv4_options;
            (_, 5, _) : accept;
            default : parse_ipv4_options_2;
        }
    }

    state parse_ipv4_options_2 {
        eg_md.common.ip_opt2_chksum_enable = true;
        transition accept;
    }

    state parse_ipv4_options {
        pkt.extract(hdr.ipv4_option);
        transition accept;
    }

    state parse_vlan {
        pkt.extract(hdr.vlan_tag[0]);
        eg_md.lkp.vid = hdr.vlan_tag[0].vid;
        transition select(hdr.vlan_tag[0].ether_type) {
            0x0800 : parse_ipv4;
            0x86dd : parse_ipv6;
            default : accept;
        }
    }

    state parse_qinq {
        pkt.extract(hdr.vlan_tag[0]);
        pkt.extract(hdr.vlan_tag[1]);
        eg_md.lkp.vid = hdr.vlan_tag[0].vid;
        transition select(hdr.vlan_tag[1].ether_type) {
            0x0800 : parse_ipv4;
            0x86dd : parse_ipv6;
            default : accept;
        }
    }

    state parse_mpls {
        pkt.extract(hdr.mpls_ig[0]);
        transition select(hdr.mpls_ig[0].bos, pkt.lookahead<bit<4>>()) {
            (0x0 &&& 0x1, 0x0 &&& 0x0) : parse_mpls1;
            (0x1 &&& 0x1, 0x4 &&& 0xF) : parse_inner_ipv4;
            (0x1 &&& 0x1, 0x6 &&& 0xF) : parse_inner_ipv6;
            default : accept;
        }
    }

    state parse_mpls1 {
        pkt.extract(hdr.mpls_ig[1]);
        // transition select(hdr.mpls_ig[1].bos) {
        //     1 : parse_mpls_bos;
        //     default : accept;
        // }
        transition accept;
    }

    // state parse_mpls_bos {
    //     transition parse_l3vpn_passenger;
    // }

    // state parse_l3vpn_passenger {
    //     transition select(pkt.lookahead<bit<4>>()) {
    //         0x4 : parse_inner_ipv4;
    //         0x6 : parse_inner_ipv6;
    //         default: accept;
    //     }
    // }

    // @critical
    state parse_ipv6 {

        pkt.extract(hdr.ipv6);
        eg_md.lkp.ip_src_addr = hdr.ipv6.src_addr;
        // eg_md.lkp.ip_dst_addr = hdr.ipv6.dst_addr;
        // eg_md.lkp.ip_proto = hdr.ipv6.next_hdr;
        //eg_md.lkp.ip_tos = hdr.ipv6.traffic_class;
        // eg_md.lkp.ipv6_tos = hdr.ipv6.traffic_class;
        // eg_md.lkp.ip_type = SWITCH_IP_TYPE_IPV6;
        transition select(hdr.ipv6.next_hdr) {
            6 : parse_tcp;
            17 : parse_udp;
            58 : parse_icmp;
            44 : parse_ipv6_frag;




            default : accept;
        }



    }

    state parse_ipv6_frag {
        pkt.extract(hdr.ipv6_frag);
        transition select(hdr.ipv6_frag.next_hdr, hdr.ipv6_frag.frag_offset) {
            (6, 0) : parse_tcp;
            (17, 0) : parse_udp;
            (58, 0) : parse_icmp;
            default : accept;
        }
    }

    state parse_udp {
        udp_h udp = pkt.lookahead<udp_h>();
        eg_md.lkp.l4_src_port = udp.src_port;
        eg_md.lkp.l4_dst_port = udp.dst_port;
        transition accept;
    }

    state parse_tcp {
        tcp_h tcp = pkt.lookahead<tcp_h>();
        eg_md.lkp.l4_src_port = tcp.src_port;
        eg_md.lkp.l4_dst_port = tcp.dst_port;
        eg_md.lkp.tcp_flags = tcp.flags;
        transition accept;
    }

    state parse_icmp {
        icmp_h icmp = pkt.lookahead<icmp_h>();
        eg_md.lkp.l4_src_port = icmp.typeCode;
        transition accept;
    }


//     state parse_vxlan {
// #ifdef VXLAN_ENABLE
//         pkt.extract(hdr.vxlan);
//         // transition parse_inner_ethernet;
//         transition accept;
// #else
//         transition accept;
// #endif
//     }

//     state parse_inner_ethernet {
//         pkt.extract(hdr.inner_ethernet);
//         transition select(hdr.inner_ethernet.ether_type) {
//             ETHERTYPE_IPV4 : parse_inner_ipv4;
//             ETHERTYPE_IPV6 : parse_inner_ipv6;
//             default : accept;
//         }
//     }

    state parse_inner_ipv4 {
        pkt.extract(hdr.inner_ipv4);
        // eg_md.common.pkt_type = FABRIC_PKT_TYPE_IP_IN_IP;  
        transition accept;
        // pkt.extract(hdr.inner_ipv4);
        // transition select(hdr.inner_ipv4.protocol) {
        //     // IP_PROTOCOLS_TCP : parse_inner_tcp;
        //     IP_PROTOCOLS_UDP : parse_inner_udp;
        //     default : accept;
        // }
    }

    state parse_inner_ipv6 {
        pkt.extract(hdr.inner_ipv6);
        transition accept;
    }

    state parse_depth_pad {
        parser_pad_h pad = pkt.lookahead<parser_pad_h>();
        transition select(pad.extend) {
            1 : parse_depth_pad_1;
            default : parse_depth_pad_2;
            // default : accept;
        }
    }

    state parse_depth_pad_1 {
        parser_pad_h pad = pkt.lookahead<parser_pad_h>();
        eg_md.common.parser_pad = 1;
        transition select(pad.extend) {
            1 : parse_depth_pad_2;
            default : parse_depth_pad_3;
        }
    }

    state parse_depth_pad_2 {
        parser_pad_h pad = pkt.lookahead<parser_pad_h>();
        eg_md.common.parser_pad = 1;
        transition select(pad.extend) {
            1 : parse_depth_pad_3;
            default : parse_depth_pad_end;
        }
    }

    state parse_depth_pad_3 {
        parser_pad_h pad = pkt.lookahead<parser_pad_h>();
        eg_md.common.parser_pad = 1;
        transition select(pad.extend) {
            1 : parse_depth_pad_end;
            default : accept;
        }
    }

    state parse_depth_pad_end {
        eg_md.common.parser_pad = 1;
        transition accept;
    }
//     state parse_inner_udp {
//         pkt.extract(hdr.inner_udp);
//         transition accept;
//     }

//     state parse_inner_tcp {
//         pkt.extract(hdr.inner_tcp);
//         transition accept;
//     }

//     state parse_inner_icmp {
//         pkt.extract(hdr.inner_icmp);
//         transition accept;
//     }
}


//----------------------------------------------------------------------------
// Mirror packet deparser
//-----------------------------------------------------------------------------
control IgMirror_fabric(
    inout switch_header_t hdr,
    in switch_ingress_metadata_t ig_md,
    in ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr) {
// Ingress deparser create a copy of the original ingress packet and prepend the prepend the mirror
// header.
    Mirror() mirror;

    apply {


        if (ig_intr_md_for_dprsr.mirror_type == 7) {
            mirror.emit<switch_fabric_ingress_trace_mirror_metadata_plus_h>(
                ig_md.mirror.session_id,
                {ig_md.mirror.src,
                ig_md.mirror.type,



                ig_md.mirror.session_id,
                ig_md.common.pipeline_location,
                ig_md.common.dst_mirror_port,
                ig_md.common.trace_counter,
                ig_md.common.drop_reason,
                ig_md.common.hash[15:0],

                0,
                ig_md.common.dev_port,
                ig_md.common.hash[15:0],

                ig_md.common.timestamp});
        }

    }
}

control EgMirror_fabric(
    inout switch_header_t hdr,
    in switch_egress_metadata_t eg_md,
    in egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr) {
// Egress deparser first construct the output packet and then prepend the mirror header.
    Mirror() mirror;

    apply {

        /* tran ipfix on mirror , eop mirror */
        if (eg_intr_md_for_dprsr.mirror_type == 1) {
            mirror.emit<switch_port_mirror_metadata_h>(eg_md.mirror.session_id, {
                eg_md.mirror.src,
                eg_md.mirror.type,



                eg_md.mirror.session_id,
                0,
                0,
                eg_md.common.iif,
                0,
                eg_md.common.oif,
                eg_md.common.cpu_code,
                eg_md.common.hash[15:0],
                eg_md.common.backpush_dst_port,
                eg_md.common.egress_eport
                });
        } else if (eg_intr_md_for_dprsr.mirror_type == 7) {
            mirror.emit<switch_fabric_egress_trace_mirror_metadata_plus_h>(
                eg_md.mirror.session_id,
                {eg_md.mirror.src,
                eg_md.mirror.type,



                eg_md.mirror.session_id,
                eg_md.common.pipeline_location,
                eg_md.common.dst_mirror_port,
                eg_md.common.trace_counter,
                eg_md.common.drop_reason,
                eg_md.common.hash[15:0],

                0,
                eg_md.qos.qdepth,

                eg_md.common.timestamp});
        }

    }
}

//-----------------------------------------------------------------------------
// Ingress Deparser
//-----------------------------------------------------------------------------
control IgDeparser_fabric(
    packet_out pkt,
    inout switch_header_t hdr,
    in switch_ingress_metadata_t ig_md,
    in ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr) {

    Digest<switch_learning_digest_t>() digest;
    IgMirror_fabric() mirror;

    apply {
        mirror.apply(hdr, ig_md, ig_intr_md_for_dprsr);
        if (ig_intr_md_for_dprsr.digest_type == SWITCH_DIGEST_TYPE_MAC_LEARNING) {
            digest.pack({ig_md.ebridge.evlan, ig_md.common.iif, ig_md.lkp.mac_src_addr});
        }
        pkt.emit(hdr.switch_bridged_src);
        // pkt.emit(hdr.bridged_md_base_encap);
        pkt.emit(hdr.fabric_base);
        pkt.emit(hdr.fabric_cpu_pcie_base);// only for cpu-to-cpu
        pkt.emit(hdr.fabric_qos);
  pkt.emit(hdr.bridged_md_74);
        pkt.emit(hdr.bridged_md_78);
        pkt.emit(hdr.fabric_unicast_ext_fe);
        pkt.emit(hdr.fabric_var_ext_1_16bit);
        pkt.emit(hdr.fabric_multicast_src);// only for mc loopback & cpu-to-cpu
        pkt.emit(hdr.fabric_multicast_ext);
        pkt.emit(hdr.fabric_one_pad_7);// onepad
        pkt.emit(hdr.bridged_md_78_fqid);
        pkt.emit(hdr.ext_l4_encap);
        pkt.emit(hdr.ext_tunnel_decap);
        pkt.emit(hdr.ext_padding_word);
        pkt.emit(hdr.ext_eth);

        // common hdr
        pkt.emit(hdr.ethernet);
        pkt.emit(hdr.vlan_tag);
        // pkt.emit(hdr.mpls_ig);
        pkt.emit(hdr.mpls_fabric_ig);
        // pkt.emit(hdr.cw);
        pkt.emit(hdr.arp); // Ingress only.
        pkt.emit(hdr.ipv4);
        pkt.emit(hdr.ipv6);
        pkt.emit(hdr.udp);
        pkt.emit(hdr.tcp); // Ingress only.
        pkt.emit(hdr.icmp); // Ingress only.
        pkt.emit(hdr.igmp); // Ingress only.
        pkt.emit(hdr.vxlan);
        pkt.emit(hdr.inner_ethernet);
        pkt.emit(hdr.inner_ipv4);
        pkt.emit(hdr.inner_ipv6);
        pkt.emit(hdr.inner_udp);
        pkt.emit(hdr.inner_tcp);
        pkt.emit(hdr.inner_icmp);
    }
}


//-----------------------------------------------------------------------------
// Egress Deparser
//-----------------------------------------------------------------------------
control EgDeparser_fabric(
        packet_out pkt,
        inout switch_header_t hdr,
        in switch_egress_metadata_t eg_md,
        in egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr) {

    EgMirror_fabric() mirror;
    Checksum() ipv4_checksum;
    Checksum() inner_ipv4_checksum;

    apply {
        mirror.apply(hdr, eg_md, eg_intr_md_for_dprsr);

// #if !defined(IPV4_CSUM_IN_MAU)
        if (eg_md.common.ip_opt2_chksum_enable) {
            // ihl > 6 don't update checksum
        } else if (hdr.ipv4_option.isValid()) {
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
                hdr.ipv4.dst_addr,
                hdr.ipv4_option.type,
                hdr.ipv4_option.length,
                hdr.ipv4_option.value});
        }
        else if (hdr.ipv4.isValid()) {
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
        }

// #ifdef TUNNEL_ENABLE
//         hdr.inner_ipv4.hdr_checksum = inner_ipv4_checksum.update({
//             hdr.inner_ipv4.version,
//             hdr.inner_ipv4.ihl,
//             hdr.inner_ipv4.diffserv,
//             hdr.inner_ipv4.total_len,
//             hdr.inner_ipv4.identification,
//             hdr.inner_ipv4.flags,
//             hdr.inner_ipv4.frag_offset,
//             hdr.inner_ipv4.ttl,
//             hdr.inner_ipv4.protocol,
//             hdr.inner_ipv4.src_addr,
//             hdr.inner_ipv4.dst_addr});
// #endif /* TUNNEL_ENABLE */
// #endif /* IPV4_CSUM_IN_MAU */

        // fabric headers base
        pkt.emit(hdr.fabric_base);
        pkt.emit(hdr.fabric_cpu_pcie_base);
        // for fabric qos
        pkt.emit(hdr.fabric_qos);

        // fabric headers ext
        pkt.emit(hdr.fabric_unicast_dst);
        pkt.emit(hdr.fabric_unicast_ext_fe_encap);
        pkt.emit(hdr.fabric_var_ext_1_16bit);
        // pkt.emit(hdr.fabric_var_ext_2_8bit);  
        // pkt.emit(hdr.fabric_multicast_src);
        pkt.emit(hdr.fabric_multicast_src_encap);
        pkt.emit(hdr.fabric_multicast_ext);
        pkt.emit(hdr.fabric_to_cpu_data);

        // fabric headers one pad
        pkt.emit(hdr.fabric_one_pad);
        pkt.emit(hdr.pcie_one_pad);
        pkt.emit(hdr.fabric_unicast_ext_fe_2_encap);
        pkt.emit(hdr.fabric_post_one_pad);

        pkt.emit(hdr.ext_l4_encap);
        pkt.emit(hdr.ext_tunnel_decap);
        pkt.emit(hdr.ext_padding_word);

        pkt.emit(hdr.fabric_learning);

        pkt.emit(hdr.ethernet);
        pkt.emit(hdr.timestamp); // Egress only.
        pkt.emit(hdr.vlan_tag);
        pkt.emit(hdr.ipv4);
        pkt.emit(hdr.ipv4_option);
        pkt.emit(hdr.ipv6);
        pkt.emit(hdr.ipv6_frag);
        pkt.emit(hdr.udp);
        pkt.emit(hdr.tcp);
        pkt.emit(hdr.icmp);
        // pkt.emit(hdr.vxlan);



        pkt.emit(hdr.erspan); // Egress only.
        pkt.emit(hdr.erspan_type2); // Egress only.
        pkt.emit(hdr.erspan_type3); // Egress only.
        pkt.emit(hdr.erspan_platform); // Egress only.
        pkt.emit(hdr.mpls_ig);
        // pkt.emit(hdr.cw);
        pkt.emit(hdr.inner_ethernet);
        pkt.emit(hdr.inner_ipv4);
        pkt.emit(hdr.inner_ipv6);
        pkt.emit(hdr.inner_udp);
        pkt.emit(hdr.inner_tcp);
        pkt.emit(hdr.inner_icmp);
    }
}
# 186 "/mnt/p4c-4127/p4src/switch-tofino2/switch_tofino_x1.p4" 2
# 1 "/mnt/p4c-4127/p4src/shared/parde_downlink.p4" 1
/*******************************************************************************
 * BAREFOOT NETWORKS CONFIDENTIAL & PROPRIETARY
 *
 * Copyright (c) 2015-2019 Barefoot Networks, Inc.
 *
 * NOTICE: All information contained herein is, and remains the property of
 * Barefoot Networks, Inc. and its suppliers, if any. The intellectual and
 * technical concepts contained herein are proprietary to Barefoot Networks,
 * Inc.
 * and its suppliers and may be coverep by U.S. and Foreign Patents, patents in
 * process, and are protected by trade secret or copyright law.
 * Dissemination of this information or reproduction of this material is
 * strictly forbidden unless prior written permission is obtained from
 * Barefoot Networks, Inc.
 *
 * No warranty, explicit or implicit is provided, unless granted under a
 * written agreement with Barefoot Networks, Inc.
 *
 ******************************************************************************/

# 1 "/mnt/p4c-4127/p4src/shared/headers.p4" 1
/*******************************************************************************
 * BAREFOOT NETWORKS CONFIDENTIAL & PROPRIETARY
 *
 * Copyright (c) 2015-2019 Barefoot Networks, Inc.

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
 ******************************************************************************/

//-----------------------------------------------------------------------------
// Protocol Header Definitions
//-----------------------------------------------------------------------------
# 22 "/mnt/p4c-4127/p4src/shared/parde_downlink.p4" 2
# 1 "/mnt/p4c-4127/p4src/shared/types.p4" 1
/*******************************************************************************
 * BAREFOOT NETWORKS CONFIDENTIAL & PROPRIETARY
 *
 * Copyright (c) 2015-2019 Barefoot Networks, Inc.

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
 ******************************************************************************/
# 23 "/mnt/p4c-4127/p4src/shared/parde_downlink.p4" 2

//-----------------------------------------------------------------------------
// Segment routing extension header parser
//-----------------------------------------------------------------------------
parser SRHParser(packet_in pkt, inout switch_header_t hdr) {
    state start {

        transition parse_srh;



    }

    state parse_srh {
        //TODO(msharif) : implement SRH parser.
        transition accept;
    }
}

//=============================================================================
// Ingress parser
//=============================================================================
parser IgParser_downlink(
        packet_in pkt,
        out switch_header_t hdr,
        out switch_ingress_metadata_t ig_md,
        out ingress_intrinsic_metadata_t ig_intr_md) {
    Checksum() ipv4_checksum;
    Checksum() inner_ipv4_checksum;
    value_set<switch_cpu_port_value_set_t>(1) cpu_port;

    state start {
        pkt.extract(ig_intr_md);
        transition parse_port_metadata;
    }

    state parse_resubmit {
        // Parse resubmitted packet here.
        transition accept;
    }

    state parse_port_metadata {
        // Parse port metadata produced by ibuf
        switch_port_metadata_downlink_pipe_t port_md = port_metadata_unpack<switch_port_metadata_downlink_pipe_t>(pkt);
        ig_md.common.port_type = port_md.port_type;
        ig_md.common.timestamp = ig_intr_md.ingress_mac_tstamp[31:0];
        transition select(ig_md.common.port_type) {
            PORT_TYPE_QOS_RECIRC : parse_drop_msg_before;
            default : parse_fpga_eg_unicast;
        }
    }

    state parse_drop_msg_before {
        pkt.extract(hdr.fabric_base);
        pkt.extract(hdr.fabric_qos);
        // ig_md.common.pkt_type = hdr.fabric_base.pkt_type;
        transition parse_drop_msg;
    }

    state parse_fpga_eg_unicast {
        pkt.extract(hdr.fabric_base);
        // ig_md.common.pkt_type = hdr.fabric_base.pkt_type;
        // ig_md.common.is_mirror = hdr.fabric_base.is_mirror;
        // ig_md.common.is_mcast = hdr.fabric_base.is_mcast;
        pkt.extract(hdr.fabric_qos);
        // ig_md.common.track = hdr.fabric_qos.track;         
        pkt.extract(hdr.fabric_unicast_ext_eg);
        // ig_md.common.oif = hdr.fabric_unicast_ext_eg.oif;
        // ig_md.tunnel.next_hdr_type = hdr.fabric_unicast_ext_eg.next_hdr_type;
        ig_md.common.dst_port = hdr.fabric_unicast_ext_eg.dst_port;
        ig_md.common.l2_encap = hdr.fabric_unicast_ext_eg.l2_encap;
        ig_md.qos.FQID = hdr.fabric_unicast_ext_eg.FQID;
        pkt.extract(hdr.fabric_one_pad);
        // transition parse_fabric_uc_end;
        transition select(hdr.fabric_unicast_ext_eg.extend_fake) {
            (1) : parse_ext_fake;
            default : parse_fabric_uc_end;
        }
    }

    state parse_ext_fake {
        pkt.extract(hdr.ext_fake);
        ig_md.ebridge.evlan = hdr.ext_fake.data1;
        transition parse_fabric_uc_end;
    }

    state parse_fabric_uc_end {
        transition select(hdr.fabric_base.is_mirror, hdr.fabric_base.is_mcast) {
            (0, 0) : parse_fabric_uc_end_uc;
            (0, 1) : parse_fabric_uc_end_mc;
            (1, 0) : parse_ethernet;
            default : accept;
        }
    }

    state parse_fabric_uc_end_uc {
        // is mcast = 0
        transition select(hdr.fabric_base.pkt_type, hdr.fabric_unicast_ext_eg.next_hdr_type) {
            (FABRIC_PKT_TYPE_IPV4, 0) : parse_ipv4;
            (FABRIC_PKT_TYPE_IPV6, 0) : parse_ipv6;
            (FABRIC_PKT_TYPE_MPLS, 0) : parse_mpls;
            (FABRIC_PKT_TYPE_FPGA_DROP, 0) : parse_drop_msg;
            (FABRIC_PKT_TYPE_FPGA_PAUSE, 0) : parse_pause;
            (FABRIC_PKT_TYPE_ETH, 0) : parse_ethernet;
            (FABRIC_PKT_TYPE_CCM, 0) : parse_fpga_eg_ccm;
            // (FABRIC_PKT_TYPE_CPU_ETH, 0) : parse_ethernet;
            (_, SWITCH_TUNNEL_NEXT_HDR_TYPE_MPLS) : parse_mpls;
            (_, SWITCH_TUNNEL_NEXT_HDR_TYPE_IPV4) : parse_ipv4;
            (_, SWITCH_TUNNEL_NEXT_HDR_TYPE_IPV6) : parse_ipv6;
            default : accept;
        }
    }

    state parse_fabric_uc_end_mc {
        // is mcast = 1
        transition select(hdr.fabric_base.pkt_type, hdr.fabric_unicast_ext_eg.next_hdr_type) {
            (FABRIC_PKT_TYPE_ETH, 0) : parse_ethernet;
            (FABRIC_PKT_TYPE_IPV4, 0) : parse_ipv4;
            (FABRIC_PKT_TYPE_IPV6, 0) : parse_ipv6;
            /* by zhangjunjie */
            (FABRIC_PKT_TYPE_CCM, 0) : parse_fpga_eg_ccm;
            (_, 0) : parse_ethernet;
            (_, SWITCH_TUNNEL_NEXT_HDR_TYPE_MPLS) : parse_mpls;
            (_, SWITCH_TUNNEL_NEXT_HDR_TYPE_IPV4) : parse_ipv4;
            (_, SWITCH_TUNNEL_NEXT_HDR_TYPE_IPV6) : parse_ipv6;
            default : parse_ethernet;
        }
    }

    // state parse_fabric_uc_end_2 {
    //     transition select(ig_md.common.is_mcast) {
    //         (0) : parse_ethernet;
    //         default : accept;
    //     }
    // }

    state parse_pause {
        pkt.extract(hdr.ethernet);
        ig_md.qos.tc = 7;
        transition accept;
    }

    state parse_fpga_eg_ccm {
        pkt.extract(hdr.fabric_from_cpu_eth_ccm);
        transition accept;
    }

    state parse_ethernet {
        pkt.extract(hdr.ethernet);
        vlan_tag_h vlan_tag = pkt.lookahead<vlan_tag_h>();
        transition select(hdr.ethernet.ether_type, vlan_tag.ether_type) {
            (0x0800, _) : parse_ipv4;
            (0x86dd, _) : parse_ipv6;
            (0x8100, 0x8100) : parse_qinq;
            (0x8100, _) : parse_vlan;
            // ETHERTYPE_FCOE : parse_fcoe;
            // ETHERTYPE_MPLS : parse_mpls;
            // cpu_port  : parse_cpu;
            default : accept;
        }
    }

    state parse_ipv4 {
        pkt.extract(hdr.ipv4);
        ig_md.lkp.ip_src_addr[31:0] = hdr.ipv4.src_addr;
        ig_md.lkp.ip_dst_addr[31:0] = hdr.ipv4.dst_addr;
        // ig_md.lkp.ip_type = SWITCH_IP_TYPE_IPV4;
        // ig_md.lkp.ip_ttl = hdr.ipv4.ttl;
        ig_md.lkp.ip_proto = hdr.ipv4.protocol;
        ipv4_checksum.add(hdr.ipv4);
        transition select(hdr.ipv4.ihl) {
            5 : parse_ipv4_no_options;
            default : accept;
        }
    }

    state parse_ipv4_no_options {
        ig_md.flags.ipv4_checksum_err = ipv4_checksum.verify();
        transition select(hdr.ipv4.protocol, hdr.ipv4.frag_offset) {
            (1, 0) : parse_icmp;
            (6, 0) : parse_tcp;
            (17, 0) : parse_udp;
            // (IP_PROTOCOLS_IPV4, 0) : parse_ipinip;
            // (IP_PROTOCOLS_IPV6, 0) : parse_ipv6inip;
            // Do NOT parse the next header if IP packet is fragmented.
            default : accept;
        }
    }

    state parse_vlan {
        pkt.extract(hdr.vlan_tag[0]);
        transition select(hdr.vlan_tag[0].ether_type) {
            0x0800 : parse_ipv4;
            0x86dd : parse_ipv6;
            0x8847 : parse_mpls;
            default : accept;
        }
    }

    state parse_qinq {
        pkt.extract(hdr.vlan_tag[0]);
        pkt.extract(hdr.vlan_tag[1]);
        transition select(hdr.vlan_tag[1].ether_type) {
            0x0800 : parse_ipv4;
            0x86dd : parse_ipv6;
            0x8847 : parse_mpls;
            default : accept;
        }
    }

    state parse_drop_msg {
        pkt.extract(hdr.drop_msg[0]);
        ig_md.qos.drop_fqid1 = hdr.drop_msg[0].fqid[14:0];
        transition parse_drop_msg_again;
    }
    state parse_drop_msg_again {
        pkt.extract(hdr.drop_msg[1]);
        ig_md.qos.drop_fqid2 = hdr.drop_msg[1].fqid[14:0];
        transition accept;
    }

    // state parse_mpls {
    //     // pkt.extract(hdr.mpls_ig.next);
    //     // transition select(hdr.mpls_ig.last.bos) {
    //     //     0 : parse_mpls;
    //     //     1 : parse_mpls_bos;
    //     //     default : accept;
    //     // }
    //     transition accept;
    // }

    // state parse_mpls_bos {
    //     transition accept;
    // }

    state parse_mpls {
        pkt.extract(hdr.mpls_ig[0]);
        mpls_lookahead_h lookahead = pkt.lookahead<mpls_lookahead_h>();
        transition select(hdr.mpls_ig[0].bos, lookahead.bos1, lookahead.bos2) {
            (0x0 &&& 0x1, 0x0 &&& 0x1, 0x0 &&& 0x1): parse_mpls3_or_more;
            (0x0 &&& 0x1, 0x0 &&& 0x1, 0x1 &&& 0x1): parse_mpls2;
            (0x0 &&& 0x1, 0x1 &&& 0x1, 0x0 &&& 0x0): parse_mpls1;
            default : parse_mpls_bos;
        }
    }

    state parse_mpls1 {
        pkt.extract(hdr.mpls_ig[1]);
        transition select(pkt.lookahead<bit<4>>()) {
            0x4 : parse_inner_ipv4;
            0x6 : parse_inner_ipv6;
            default: parse_inner_ethernet;
        }
    }

    state parse_mpls2 {
        pkt.extract(hdr.mpls_ig[1]);
        pkt.extract(hdr.mpls_ig[2]);
        transition select(pkt.lookahead<bit<4>>()) {
            0x4 : parse_inner_ipv4;
            0x6 : parse_inner_ipv6;
            default: parse_inner_ethernet;
        }
    }

    state parse_mpls3_or_more {
        pkt.extract(hdr.mpls_ig[1]);
        pkt.extract(hdr.mpls_ig[2]);
        pkt.extract(hdr.mpls_ig[3]);
        mpls_lookahead_h lookahead = pkt.lookahead<mpls_lookahead_h>();
        transition select(hdr.mpls_ig[3].bos, lookahead.bos1, lookahead.bos2) {
            (0x0 &&& 0x1, 0x0 &&& 0x1, 0x0 &&& 0x1): parse_mpls6_or_more;
            (0x0 &&& 0x1, 0x0 &&& 0x1, 0x1 &&& 0x1): parse_mpls5;
            (0x0 &&& 0x1, 0x1 &&& 0x1, 0x0 &&& 0x0): parse_mpls4;
            default : parse_mpls_bos;
        }
    }

    state parse_mpls4 {
        pkt.extract(hdr.mpls_ig[4]);
        transition select(pkt.lookahead<bit<4>>()) {
            0x4 : parse_inner_ipv4;
            0x6 : parse_inner_ipv6;
            default: parse_inner_ethernet;
        }
    }

    state parse_mpls5 {
        pkt.extract(hdr.mpls_ig[4]);
        pkt.extract(hdr.mpls_ig[5]);
        transition select(pkt.lookahead<bit<4>>()) {
            0x4 : parse_inner_ipv4;
            0x6 : parse_inner_ipv6;
            default: parse_inner_ethernet;
        }
    }

    state parse_mpls6_or_more {
        pkt.extract(hdr.mpls_ig[4]);
        pkt.extract(hdr.mpls_ig[5]);
        pkt.extract(hdr.mpls2_ig[0]);
        mpls_lookahead_h lookahead = pkt.lookahead<mpls_lookahead_h>();
        transition select(hdr.mpls2_ig[0].bos, lookahead.bos1, lookahead.bos2) {
            (0x0 &&& 0x1, 0x0 &&& 0x1, 0x0 &&& 0x1): parse_mpls9_or_more;
            (0x0 &&& 0x1, 0x0 &&& 0x1, 0x1 &&& 0x1): parse_mpls8;
            (0x0 &&& 0x1, 0x1 &&& 0x1, 0x0 &&& 0x0): parse_mpls7;
            default : parse_mpls_bos;
        }
    }

    state parse_mpls7 {
        pkt.extract(hdr.mpls2_ig[1]);
        transition select(pkt.lookahead<bit<4>>()) {
            0x4 : parse_inner_ipv4;
            0x6 : parse_inner_ipv6;
            default: parse_inner_ethernet;
        }
    }

    state parse_mpls8 {
        pkt.extract(hdr.mpls2_ig[1]);
        pkt.extract(hdr.mpls2_ig[2]);
        transition select(pkt.lookahead<bit<4>>()) {
            0x4 : parse_inner_ipv4;
            0x6 : parse_inner_ipv6;
            default: parse_inner_ethernet;
        }
    }

    state parse_mpls9_or_more {
        pkt.extract(hdr.mpls2_ig[1]);
        pkt.extract(hdr.mpls2_ig[2]);
        pkt.extract(hdr.mpls2_ig[3]);
        transition select(hdr.mpls2_ig[3].bos) {
            1 : parse_mpls_bos;
            default : accept;
        }
    }

    state parse_mpls_bos {
        // transition parse_mpls_cw;
        transition select(pkt.lookahead<bit<4>>()) {
            0x4 : parse_inner_ipv4;
            0x6 : parse_inner_ipv6;
            default : parse_inner_ethernet;
        }
    }

    state parse_inner_ethernet {
        pkt.extract(hdr.inner_ethernet);
        // ig_md.lkp.mac_src_addr = hdr.inner_ethernet.src_addr;
        // ig_md.lkp.mac_dst_addr = hdr.inner_ethernet.dst_addr;
        transition select(hdr.inner_ethernet.ether_type) {
            0x0800 : parse_inner_ipv4;
            0x86dd : parse_inner_ipv6;
            default : accept;
        }
    }

    state parse_inner_ipv4 {
        pkt.extract(hdr.inner_ipv4);
        ig_md.lkp.ip_src_addr[31:0] = hdr.inner_ipv4.src_addr;
        ig_md.lkp.ip_dst_addr[31:0] = hdr.inner_ipv4.dst_addr;
        transition select(hdr.inner_ipv4.protocol, hdr.inner_ipv4.ihl, hdr.inner_ipv4.flags, hdr.inner_ipv4.frag_offset) {
            (17, 5, 0 &&& 1, 0) : parse_inner_udp;
            (6, 5, 0 &&& 1, 0) : parse_inner_tcp;
            default : accept;
        }
    }

    state parse_inner_ipv6 {
        pkt.extract(hdr.inner_ipv6);
        ig_md.lkp.ip_src_addr = hdr.inner_ipv6.src_addr;
        ig_md.lkp.ip_dst_addr = hdr.inner_ipv6.dst_addr;
        ig_md.lkp.flow_label = hdr.inner_ipv6.flow_label;
        ig_md.lkp.ip_proto = hdr.inner_ipv6.next_hdr;
        transition select(hdr.inner_ipv6.next_hdr) {
            6 : parse_inner_tcp;
            17 : parse_inner_udp;
            default : accept;
        }
    }

    state parse_inner_udp {
        pkt.extract(hdr.inner_udp);
        ig_md.lkp.l4_src_port = hdr.inner_udp.src_port;
        ig_md.lkp.l4_dst_port = hdr.inner_udp.dst_port;
        transition accept;
    }

    state parse_inner_tcp {
        pkt.extract(hdr.inner_tcp);
        ig_md.lkp.l4_src_port = hdr.inner_tcp.src_port;
        ig_md.lkp.l4_dst_port = hdr.inner_tcp.dst_port;
        transition accept;
    }

    state parse_ipv6 {

        pkt.extract(hdr.ipv6);
        // ig_md.lkp.ip_type = SWITCH_IP_TYPE_IPV6;
        // ig_md.lkp.ip_ttl = hdr.ipv6.hop_limit;
        ig_md.lkp.ip_proto = hdr.ipv6.next_hdr;
        ig_md.lkp.ip_src_addr = hdr.ipv6.src_addr;
        ig_md.lkp.ip_dst_addr = hdr.ipv6.dst_addr;
        ig_md.lkp.flow_label = hdr.ipv6.flow_label;
        transition select(hdr.ipv6.next_hdr) {
            58 : parse_icmp;
            6 : parse_tcp;
            17 : parse_udp;
            44 : parse_ipv6_frag;
            // IP_PROTOCOLS_IPV4 : parse_ipinip;
            // IP_PROTOCOLS_IPV6 : parse_ipv6inip;
            default : accept;
        }



    }

    state parse_ipv6_frag {
        pkt.extract(hdr.ipv6_frag);
        transition select(hdr.ipv6_frag.next_hdr, hdr.ipv6_frag.frag_offset) {
            (6, 0) : parse_tcp;
            (17, 0) : parse_udp;
            (58, 0) : parse_icmp;
            default : accept;
        }
    }

    state parse_udp {
        pkt.extract(hdr.udp);
        ig_md.lkp.l4_src_port = hdr.udp.src_port;
        ig_md.lkp.l4_dst_port = hdr.udp.dst_port;
        transition accept;
    }

    state parse_tcp {
        pkt.extract(hdr.tcp);
        ig_md.lkp.l4_src_port = hdr.tcp.src_port;
        ig_md.lkp.l4_dst_port = hdr.tcp.dst_port;
        ig_md.lkp.tcp_flags = hdr.tcp.flags;
        transition accept;
    }

    state parse_icmp {
        pkt.extract(hdr.icmp);
        ig_md.lkp.l4_src_port = hdr.icmp.typeCode;
        ig_md.lkp.l4_dst_port = 0;
        transition accept;
    }

}

//----------------------------------------------------------------------------
// Egress parser
//----------------------------------------------------------------------------
parser EgParser_downlink(
        packet_in pkt,
        out switch_header_t hdr,
        out switch_egress_metadata_t eg_md,
        out egress_intrinsic_metadata_t eg_intr_md) {

    value_set<switch_cpu_port_value_set_t>(1) cpu_port;

    @critical
    state start {
        pkt.extract(eg_intr_md);
        eg_md.common.pkt_length = eg_intr_md.pkt_length;
        eg_md.tunnel.payload_len = eg_intr_md.pkt_length;
        eg_md.qos.qdepth = eg_intr_md.deq_qdepth;

        switch_bridged_metadata_lookahead_h mirror_md = pkt.lookahead<switch_bridged_metadata_lookahead_h>();
        transition select(mirror_md.src, mirror_md.type) {
            (SWITCH_PKT_SRC_BRIDGED, BRIDGE_TYPE_FABRIC_DOWNLINK) : parse_bridged_pkt_78;

            (_, 1) : parse_port_mirrored_metadata;

        }
    }

    state parse_bridged_pkt_78{
        switch_bridged_metadata_78_parser_h bridged_md_78;

        pkt.extract(hdr.switch_bridged_src);
        pkt.extract(hdr.bridged_md_base);
        // pkt.extract(hdr.bridged_md_qos);
        pkt.extract(hdr.fabric_qos);
        pkt.extract(bridged_md_78);

        eg_md.common.bridge_type = hdr.switch_bridged_src.bridge_type;
        eg_md.common.pkt_type = hdr.bridged_md_base.pkt_type;
        eg_md.common.is_mirror = hdr.bridged_md_base.is_mirror;
        eg_md.common.is_mcast = hdr.bridged_md_base.is_mcast;
        eg_md.qos.tc = hdr.fabric_qos.tc;
        eg_md.qos.color = hdr.fabric_qos.color;
        eg_md.qos.chgDSCP_disable = hdr.fabric_qos.chgDSCP_disable;
        eg_md.qos.BA = hdr.fabric_qos.BA;
        eg_md.common.track = hdr.fabric_qos.track;
        eg_md.common.is_from_cpu_pcie = bridged_md_78.is_from_cpu_pcie;
        eg_md.flags.is_elephant = bridged_md_78.is_elephant;
        eg_md.common.dst_port = bridged_md_78.dst_port;
        eg_md.common.l2_encap = bridged_md_78.l2_encap;
        eg_md.common.l3_encap = bridged_md_78.l3_encap;
        eg_md.common.hash[15:0] = bridged_md_78.hash;
        eg_md.qos.FQID[15:0] = bridged_md_78.fqid;
        eg_md.route.dip_l3class_id = bridged_md_78.dip_l3class_id;
        eg_md.route.sip_l3class_id = bridged_md_78.sip_l3class_id;
        eg_md.common.iif = bridged_md_78.iif;
        switch_extension_lookahead_h extension = pkt.lookahead<switch_extension_lookahead_h>();
        transition select(bridged_md_78.extend, extension.ext_type, extension.extend) {
            (1, BRIDGED_MD_EXT_TYPE_L4_ENCAP, 1) : parse_extension_l4_encap_tunnel_decap;
            (1, BRIDGED_MD_EXT_TYPE_L4_ENCAP, 0) : parse_extension_l4_encap_new;
            (1, BRIDGED_MD_EXT_TYPE_TUNNEL_DECAP, _) : parse_extension_tunnel_decap_new;
            (1, BRIDGED_MD_EXT_TYPE_PADDING_WORD, _) : parse_extension_padding_word;
            default : parse_bridged_end;
        }
    }

    state parse_extension_l4_encap_tunnel_decap {
        pkt.extract(hdr.ext_l4_encap);
        pkt.extract(hdr.ext_tunnel_decap);
        eg_md.tunnel.l4_encap = hdr.ext_l4_encap.l4_encap;
        transition select(eg_md.common.pkt_type, eg_md.common.is_mirror, eg_md.common.is_mcast) {
            (FABRIC_PKT_TYPE_ETH, 0, 0) : parse_bridged_eth;
            (FABRIC_PKT_TYPE_IPV4, 0, 0) : parse_bridged_ipv4;
            (FABRIC_PKT_TYPE_IPV6, 0, 0) : parse_bridged_ipv6;
            (FABRIC_PKT_TYPE_MPLS, 0, 0) : parse_bridged_mpls;
            (FABRIC_PKT_TYPE_ETH, 0, 1) : parse_bridged_eth;
            (FABRIC_PKT_TYPE_IPV4, 0, 1) : parse_bridged_mcv4;
            (FABRIC_PKT_TYPE_IPV6, 0, 1) : parse_bridged_mcv6;
            (_, 1, 0) : parse_mirror_ethernet; // tran mirror 
            default : parse_depth_pad;
        }
    }

    state parse_extension_l4_encap_new {
        pkt.extract(hdr.ext_l4_encap);
        eg_md.tunnel.l4_encap = hdr.ext_l4_encap.l4_encap;
        transition select(eg_md.common.pkt_type, eg_md.common.is_mirror, eg_md.common.is_mcast) {
            (FABRIC_PKT_TYPE_ETH, 0, 0) : parse_bridged_eth;
            (FABRIC_PKT_TYPE_IPV4, 0, 0) : parse_bridged_ipv4;
            (FABRIC_PKT_TYPE_IPV6, 0, 0) : parse_bridged_ipv6;
            (FABRIC_PKT_TYPE_MPLS, 0, 0) : parse_bridged_mpls;
            (FABRIC_PKT_TYPE_ETH, 0, 1) : parse_bridged_eth;
            (FABRIC_PKT_TYPE_IPV4, 0, 1) : parse_bridged_mcv4;
            (FABRIC_PKT_TYPE_IPV6, 0, 1) : parse_bridged_mcv6;
            (_, 1, 0) : parse_mirror_ethernet; // tran mirror 
            default : parse_depth_pad;
        }
    }

    state parse_extension_tunnel_decap_new {
        pkt.extract(hdr.ext_tunnel_decap);
        transition select(eg_md.common.pkt_type, eg_md.common.is_mirror, eg_md.common.is_mcast) {
            (FABRIC_PKT_TYPE_ETH, 0, 0) : parse_bridged_eth;
            (FABRIC_PKT_TYPE_IPV4, 0, 0) : parse_bridged_ipv4;
            (FABRIC_PKT_TYPE_IPV6, 0, 0) : parse_bridged_ipv6;
            (FABRIC_PKT_TYPE_MPLS, 0, 0) : parse_bridged_mpls;
            (FABRIC_PKT_TYPE_ETH, 0, 1) : parse_bridged_eth;
            (FABRIC_PKT_TYPE_IPV4, 0, 1) : parse_bridged_mcv4;
            (FABRIC_PKT_TYPE_IPV6, 0, 1) : parse_bridged_mcv6;
            (_, 1, 0) : parse_mirror_ethernet; // tran mirror 
            default : parse_depth_pad;
        }
    }

    state parse_extension_padding_word {
        pkt.extract(hdr.ext_padding_word);
        transition select(eg_md.common.pkt_type, eg_md.common.is_mirror, eg_md.common.is_mcast) {
            (FABRIC_PKT_TYPE_ETH, 0, 0) : parse_bridged_eth;
            (FABRIC_PKT_TYPE_IPV4, 0, 0) : parse_bridged_ipv4;
            (FABRIC_PKT_TYPE_IPV6, 0, 0) : parse_bridged_ipv6;
            (FABRIC_PKT_TYPE_MPLS, 0, 0) : parse_bridged_mpls;
            (FABRIC_PKT_TYPE_ETH, 0, 1) : parse_bridged_eth;
            (FABRIC_PKT_TYPE_IPV4, 0, 1) : parse_bridged_mcv4;
            (FABRIC_PKT_TYPE_IPV6, 0, 1) : parse_bridged_mcv6;
            (_, 1, 0) : parse_mirror_ethernet; // tran mirror 
            default : parse_depth_pad;
        }
    }

    state parse_bridged_end {
        transition select(eg_md.common.pkt_type, eg_md.common.is_mirror, eg_md.common.is_mcast) {
            (FABRIC_PKT_TYPE_CCM, 0, _) : parse_ccm;
            (FABRIC_PKT_TYPE_ETH, 0, 0) : parse_bridged_eth;
            (FABRIC_PKT_TYPE_IPV4, 0, 0) : parse_bridged_ipv4;
            (FABRIC_PKT_TYPE_IPV6, 0, 0) : parse_bridged_ipv6;
            (FABRIC_PKT_TYPE_MPLS, 0, 0) : parse_bridged_mpls;
            (FABRIC_PKT_TYPE_ETH, 0, 1) : parse_bridged_eth;
            (FABRIC_PKT_TYPE_IPV4, 0, 1) : parse_bridged_mcv4;
            (FABRIC_PKT_TYPE_IPV6, 0, 1) : parse_bridged_mcv6;
            (_, 1, 0) : parse_mirror_ethernet; // tran mirror 
            default : parse_depth_pad;
        }
    }

    state parse_bridged_ipv4 {
        //pkt.advance(32w176);//advance fake ethernet, vlan-tag[0,1]
        pkt.extract(hdr.advance_pad112);
        //pkt.extract(hdr.advance_pad64);
        transition parse_ipv4;
    }

    state parse_bridged_ipv6 {
        //pkt.advance(32w176);//advance fake ethernet, vlan-tag[0,1]
        pkt.extract(hdr.advance_pad112);
        //pkt.extract(hdr.advance_pad64);
        transition parse_ipv6;
    }

    state parse_bridged_mpls {
        //pkt.advance(32w176);//advance fake ethernet, vlan-tag[0,1]
        pkt.extract(hdr.advance_pad112);
        //pkt.extract(hdr.advance_pad64);
        transition parse_mpls;
    }

    state parse_bridged_mcv4 {
        pkt.extract(hdr.inner_ethernet);
        //pkt.advance(32w64);//advance fake vlan-tag[0,1]
        //pkt.extract(hdr.advance_pad64);
        transition parse_ipv4;
    }

    state parse_bridged_mcv6 {
        pkt.extract(hdr.inner_ethernet);
        //pkt.advance(32w64);//advance fake vlan-tag[0,1]
        //pkt.extract(hdr.advance_pad64);
        transition parse_ipv6;
    }

    state parse_bridged_eth {
        pkt.extract(hdr.ext_eth);
        eg_md.ebridge.evlan = hdr.ext_eth.evlan;
        eg_md.common.oif = hdr.ext_eth.l2oif;
        // transition parse_ethernet;
        pkt.extract(hdr.inner_ethernet);
        vlan_tag_h vlan_tag = pkt.lookahead<vlan_tag_h>();
        transition select(hdr.inner_ethernet.ether_type, vlan_tag.ether_type) {
            (0x0800, _) : parse_ipv4;
            (0x86dd, _) : parse_ipv6;
            (0x8100, 0x8100) : parse_qinq;
            (0x8100, _) : parse_vlan;
            // default : accept;
            default : parse_depth_pad;
        }
    }

    state parse_port_mirrored_metadata {
        switch_port_mirror_metadata_h port_md;
        pkt.extract(port_md);
        // pkt.extract(hdr.ethernet);
        transition parse_mirror_ethernet;
    }

    state parse_mirror_ethernet {
        pkt.extract(hdr.inner_ethernet);
        vlan_tag_h vlan_tag = pkt.lookahead<vlan_tag_h>();
        transition select(hdr.inner_ethernet.ether_type, vlan_tag.ether_type) {
            (0x0800, _) : parse_ipv4;
            (0x86dd, _) : parse_ipv6;
            (0x8100, 0x8100) : parse_qinq;
            (0x8100, _) : parse_vlan;
            // default : accept;
            default : parse_depth_pad;
        }
    }

    state parse_ccm {
        pkt.extract(hdr.fabric_from_cpu_eth_ccm);
        transition parse_depth_pad;
    }

    state parse_ipv4 {
        pkt.extract(hdr.inner_ipv4);
        eg_md.lkp.ip_type = SWITCH_IP_TYPE_IPV4;
        eg_md.lkp.ip_inner = 1;
        //eg_md.lkp.ip_ttl = hdr.inner_ipv4.ttl;
        eg_md.lkp.ip_src_addr[31:0] = hdr.inner_ipv4.src_addr;
        eg_md.lkp.ip_dst_addr[31:0] = hdr.inner_ipv4.dst_addr;
        eg_md.lkp.ip_proto = hdr.inner_ipv4.protocol;
        eg_md.lkp.ipv4_tos = hdr.inner_ipv4.diffserv;
        transition select(hdr.inner_ipv4.protocol, hdr.inner_ipv4.ihl, hdr.inner_ipv4.frag_offset) {
            (6, 5, 0) : parse_tcp;
            (17, 5, 0) : parse_udp;
            (1, 5, 0) : parse_icmp;
            (_, 6, _) : parse_ipv4_options;
            (_, 5, _) : accept;
            default : parse_ipv4_options_2;
        }
    }

    state parse_ipv4_options_2 {
        eg_md.common.ip_opt2_chksum_enable = true;
        transition accept;
    }

    state parse_ipv4_options {
        pkt.extract(hdr.inner_ipv4_option);
        transition select(hdr.inner_ipv4.protocol, hdr.inner_ipv4.frag_offset) {
            (17, 0) : parse_udp;
            (6, 0) : parse_tcp;
            (1, 0) : parse_icmp;
            default : accept;
        }
    }

    state parse_vlan {
        pkt.extract(hdr.inner_vlan_tag[0]);
        transition select(hdr.inner_vlan_tag[0].ether_type) {
            0x0800 : parse_ipv4;
            0x86dd : parse_ipv6;
            default : parse_depth_pad;
        }
    }

    state parse_qinq {
        pkt.extract(hdr.inner_vlan_tag[0]);
        pkt.extract(hdr.inner_vlan_tag[1]);
        transition select(hdr.inner_vlan_tag[1].ether_type) {
            0x0800 : parse_ipv4;
            0x86dd : parse_ipv6;
            default : parse_depth_pad;
        }
    }
    /* by lichunfeng */
    state parse_mpls {
        pkt.extract(hdr.mpls_vc_eg);
        // transition accept;
        transition parse_depth_pad;
    }

    state parse_ipv6 {

        pkt.extract(hdr.inner_ipv6);
        eg_md.lkp.ip_type = SWITCH_IP_TYPE_IPV6;
        eg_md.lkp.ip_inner = 1;
        //eg_md.lkp.ip_ttl = hdr.inner_ipv6.hop_limit;
        eg_md.lkp.ip_src_addr = hdr.inner_ipv6.src_addr;
        eg_md.lkp.ip_dst_addr = hdr.inner_ipv6.dst_addr;
        eg_md.lkp.ip_proto = hdr.inner_ipv6.next_hdr;
        eg_md.lkp.ipv6_tos = hdr.inner_ipv6.traffic_class;
        transition select(hdr.inner_ipv6.next_hdr) {
            6 : parse_tcp;
            17 : parse_udp;
            58 : parse_icmp;
            //IP_PROTOCOLS_FRAGMENT : parse_ipv6_frag;
            default : accept;
        }
        // transition accept;



    }

    state parse_ipv6_frag {
        pkt.extract(hdr.inner_ipv6_frag);
        transition select(hdr.inner_ipv6_frag.next_hdr, hdr.inner_ipv6_frag.frag_offset) {
            (6, 0) : parse_tcp;
            (17, 0) : parse_udp;
            (58, 0) : parse_icmp;
            default : accept;
        }
    }

    state parse_udp {
        pkt.extract(hdr.inner_udp);
        eg_md.lkp.l4_src_port = hdr.inner_udp.src_port;
        eg_md.lkp.l4_dst_port = hdr.inner_udp.dst_port;
        eg_md.lkp.tcp_flags = 0;
        transition accept;
    }

    state parse_tcp {
        // pkt.extract(hdr.tcp);
        tcp_h tcp = pkt.lookahead<tcp_h>();
        eg_md.lkp.l4_src_port = tcp.src_port;
        eg_md.lkp.l4_dst_port = tcp.dst_port;
        eg_md.lkp.tcp_flags = tcp.flags;
        transition accept;
    }

    state parse_icmp {
        pkt.extract(hdr.inner_icmp);
        eg_md.lkp.l4_src_port = hdr.inner_icmp.typeCode;
        eg_md.lkp.l4_dst_port = 0;
        eg_md.lkp.tcp_flags = 0;
        transition accept;
    }

    state parse_depth_pad {
        parser_pad_h pad = pkt.lookahead<parser_pad_h>();
        transition select(pad.extend) {
            1 : parse_depth_pad_1;
            default : parse_depth_pad_2;
            // default : accept;
        }
    }

    state parse_depth_pad_1 {
        parser_pad_h pad = pkt.lookahead<parser_pad_h>();
        eg_md.common.parser_pad = 1;
        transition select(pad.extend) {
            1 : parse_depth_pad_2;
            default : accept;
        }
    }

    state parse_depth_pad_2 {
        parser_pad_h pad = pkt.lookahead<parser_pad_h>();
        eg_md.common.parser_pad = 1;
        transition select(pad.extend) {
            1 : parse_depth_pad_end;
            default : accept;
        }
    }

    state parse_depth_pad_end {
        eg_md.common.parser_pad = 1;
        transition accept;
    }

//     state parse_vxlan {
// #ifdef VXLAN_ENABLE
//         pkt.extract(hdr.vxlan);
//         transition parse_inner_ethernet;
// #else
//         transition accept;
// #endif
//     }

//     state parse_inner_ethernet {
//         pkt.extract(hdr.inner_ethernet);
//         transition select(hdr.inner_ethernet.ether_type) {
//             ETHERTYPE_IPV4 : parse_inner_ipv4;
//             ETHERTYPE_IPV6 : parse_inner_ipv6;
//             default : accept;
//         }
//     }

//     state parse_inner_tcp {
//         pkt.extract(hdr.inner_tcp);
//         transition accept;
//     }

//     state parse_inner_icmp {
//         pkt.extract(hdr.inner_icmp);
//         transition accept;
//     }
}


//----------------------------------------------------------------------------
// Mirror packet deparser
//-----------------------------------------------------------------------------
control IgMirror_downlink(
    inout switch_header_t hdr,
    in switch_ingress_metadata_t ig_md,
    in ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr) {
// Ingress deparser create a copy of the original ingress packet and prepend the prepend the mirror
// header.
    Mirror() mirror;

    apply {


        if (ig_intr_md_for_dprsr.mirror_type == 7) {
            mirror.emit<switch_downlink_ingress_trace_mirror_metadata_plus_h>(
                ig_md.mirror.session_id,
                {ig_md.mirror.src,
                ig_md.mirror.type,



                ig_md.mirror.session_id,
                ig_md.common.trace_location_dport,
                // ig_md.common.pipeline_location,
                // ig_md.common.dst_mirror_port,
                ig_md.common.trace_counter,
                ig_md.common.drop_reason,
                ig_md.common.hash[15:0],

                0,
                ig_md.common.dev_port,
                ig_md.common.hash[15:0],

                ig_md.common.timestamp});
        }


    }
}

control EgMirror_downlink(
    inout switch_header_t hdr,
    in switch_egress_metadata_t eg_md,
    in egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr) {
// Egress deparser first construct the output packet and then prepend the mirror header.
    Mirror() mirror;

    apply {


        if (eg_intr_md_for_dprsr.mirror_type == 7) {
            mirror.emit<switch_downlink_egress_trace_mirror_metadata_plus_h>(
                eg_md.mirror.session_id,
                {eg_md.mirror.src,
                eg_md.mirror.type,



                eg_md.mirror.session_id,
                eg_md.common.trace_location_dport,
                // eg_md.common.pipeline_location,
                // eg_md.common.dst_mirror_port,
                eg_md.common.trace_counter,
                eg_md.common.drop_reason,
                eg_md.common.hash[15:0],

                0,
                eg_md.qos.qdepth,

                eg_md.common.timestamp});
        }


    }
}

//-----------------------------------------------------------------------------
// Ingress Deparser
//-----------------------------------------------------------------------------
control IgDeparser_downlink(
    packet_out pkt,
    inout switch_header_t hdr,
    in switch_ingress_metadata_t ig_md,
    in ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr) {

    IgMirror_downlink() mirror;

    apply {
        mirror.apply(hdr, ig_md, ig_intr_md_for_dprsr);
        // inner pipe to front pipe
        pkt.emit(hdr.switch_bridged_src);
        pkt.emit(hdr.fabric_base);
        // pkt.emit(hdr.bridged_md_base); // Ingress only.
        pkt.emit(hdr.fabric_qos);
        pkt.emit(hdr.bridged_md_910_encap); // Ingress only.
        // pkt.emit(hdr.ext_mirror);

        // common hdr
        pkt.emit(hdr.ethernet);
        pkt.emit(hdr.vlan_tag);
        pkt.emit(hdr.mpls_ig);
        pkt.emit(hdr.mpls2_ig);
        // pkt.emit(hdr.cw);
        pkt.emit(hdr.arp); // Ingress only.
        pkt.emit(hdr.ipv4);
        pkt.emit(hdr.ipv6);
        pkt.emit(hdr.ipv6_frag);
        pkt.emit(hdr.udp);
        pkt.emit(hdr.tcp); // Ingress only.
        pkt.emit(hdr.icmp); // Ingress only.
        pkt.emit(hdr.igmp); // Ingress only.
        pkt.emit(hdr.vxlan);
        pkt.emit(hdr.inner_ethernet);
        pkt.emit(hdr.inner_ipv4);
        pkt.emit(hdr.inner_ipv6);
        //pkt.emit(hdr.inner_ipv6_frag);
        pkt.emit(hdr.inner_udp);
        pkt.emit(hdr.inner_tcp);
        pkt.emit(hdr.inner_icmp);
    }
}


//-----------------------------------------------------------------------------
// Egress Deparser
//-----------------------------------------------------------------------------
control EgDeparser_downlink(
        packet_out pkt,
        inout switch_header_t hdr,
        in switch_egress_metadata_t eg_md,
        in egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr) {

    EgMirror_downlink() mirror;
    Checksum() ipv4_checksum;
    Checksum() inner_ipv4_checksum;

    apply {
        mirror.apply(hdr, eg_md, eg_intr_md_for_dprsr);


        if (eg_md.common.ip_opt2_chksum_enable) {
            // ihl > 6 don't update checksum
        } else if (hdr.inner_ipv4_option.isValid()) {
            hdr.inner_ipv4.hdr_checksum = ipv4_checksum.update({
                hdr.inner_ipv4.version,
                hdr.inner_ipv4.ihl,
                hdr.inner_ipv4.diffserv,
                hdr.inner_ipv4.total_len,
                hdr.inner_ipv4.identification,
                hdr.inner_ipv4.flags,
                hdr.inner_ipv4.frag_offset,
                hdr.inner_ipv4.ttl,
                hdr.inner_ipv4.protocol,
                hdr.inner_ipv4.src_addr,
                hdr.inner_ipv4.dst_addr,
                hdr.inner_ipv4_option.type,
                hdr.inner_ipv4_option.length,
                hdr.inner_ipv4_option.value});
        } else if (hdr.inner_ipv4.isValid()) {
            hdr.inner_ipv4.hdr_checksum = ipv4_checksum.update({
                hdr.inner_ipv4.version,
                hdr.inner_ipv4.ihl,
                hdr.inner_ipv4.diffserv,
                hdr.inner_ipv4.total_len,
                hdr.inner_ipv4.identification,
                hdr.inner_ipv4.flags,
                hdr.inner_ipv4.frag_offset,
                hdr.inner_ipv4.ttl,
                hdr.inner_ipv4.protocol,
                hdr.inner_ipv4.src_addr,
                hdr.inner_ipv4.dst_addr});
        }

// #ifdef TUNNEL_ENABLE
//     if (hdr.inner_ipv4.isValid()) {
//         hdr.inner_ipv4.hdr_checksum = inner_ipv4_checksum.update({
//             hdr.inner_ipv4.version,
//             hdr.inner_ipv4.ihl,
//             hdr.inner_ipv4.diffserv,
//             hdr.inner_ipv4.total_len,
//             hdr.inner_ipv4.identification,
//             hdr.inner_ipv4.flags,
//             hdr.inner_ipv4.frag_offset,
//             hdr.inner_ipv4.ttl,
//             hdr.inner_ipv4.protocol,
//             hdr.inner_ipv4.src_addr,
//             hdr.inner_ipv4.dst_addr});
//     }
// #endif /* TUNNEL_ENABLE */


        // fabric headers base
        pkt.emit(hdr.fabric_base);
        // for fabric qos
        pkt.emit(hdr.fabric_qos);
        // fabric headers ext
        pkt.emit(hdr.fabric_unicast_ext_eg_encap);
        // mcast reuse fabric_unicast_ext_eg_encap
        // pkt.emit(hdr.fabric_multicast_src);
        // pkt.emit(hdr.fabric_multicast_ext);
        // fabric headers one pad
        pkt.emit(hdr.fabric_one_pad_7);
        pkt.emit(hdr.fabric_post_one_pad);
        pkt.emit(hdr.ext_fake);

        pkt.emit(hdr.ethernet);
        pkt.emit(hdr.timestamp); // Egress only.
        pkt.emit(hdr.vlan_tag);
        // pkt.emit(hdr.cw);
        pkt.emit(hdr.ipv4);
        pkt.emit(hdr.ipv6);
        //pkt.emit(hdr.ipv6_frag);
        pkt.emit(hdr.srv6_srh);
        pkt.emit(hdr.srv6_list);




        pkt.emit(hdr.udp);
        pkt.emit(hdr.vxlan);
        // pkt.emit(hdr.erspan); // Egress only.
        // pkt.emit(hdr.erspan_type2); // Egress only.
        // pkt.emit(hdr.erspan_type3); // Egress only.
        // pkt.emit(hdr.erspan_platform); // Egress only.
        pkt.emit(hdr.mpls_eg);
        pkt.emit(hdr.mpls_vc_eg);
        pkt.emit(hdr.inner_ethernet);
        pkt.emit(hdr.inner_vlan_tag);
        pkt.emit(hdr.inner_ipv4);
        pkt.emit(hdr.inner_ipv4_option);
        pkt.emit(hdr.inner_ipv6);
        //pkt.emit(hdr.inner_ipv6_frag);
        pkt.emit(hdr.inner_udp);
        pkt.emit(hdr.inner_tcp);
        pkt.emit(hdr.inner_icmp);
    }
}
# 187 "/mnt/p4c-4127/p4src/switch-tofino2/switch_tofino_x1.p4" 2
// add here
/* by zhuanghui */
# 1 "/mnt/p4c-4127/p4src/shared/ghost_test.p4" 1
# 190 "/mnt/p4c-4127/p4src/switch-tofino2/switch_tofino_x1.p4" 2
//#include "intf_port_front.p4"
//#include "intf_port_inner.p4"
# 1 "/mnt/p4c-4127/p4src/shared/l2_mac_front.p4" 1
control VlanAttr(
        inout switch_header_t hdr,
        inout switch_ingress_metadata_t ig_md) {

    action add_vlan_tag(bit<12> native_vid){
        hdr.vlan_tag[0].setValid();
        hdr.vlan_tag[0].vid = native_vid;
        hdr.vlan_tag[0].ether_type = hdr.ethernet.ether_type;
        hdr.ethernet.ether_type = 0x8100;
    }

    action set_vlan_tag(bit<12> native_vid){
        hdr.vlan_tag[0].vid = native_vid;
    }

    @stage(1)
    table add_native_vlan{
        key = {
            hdr.vlan_tag[0].isValid() : exact;
            ig_md.common.src_port : exact;
        }

        actions = {
            set_vlan_tag;
            add_vlan_tag;
            NoAction;
        }

        const default_action = NoAction;
        size = 1024; /*单卡最大端口数48*/
    }

    action set_vlan_properties(switch_evlan_t evlan, switch_lif_t lif,
                            switch_iif_type_t iif_type, bool is_enable, bit<1> is_svi) {
        ig_md.ebridge.evlan = evlan;
        ig_md.common.iif = is_enable ? lif : ig_md.common.iif;
        ig_md.common.iif_type = iif_type;
        ig_md.route.g_l3mac_enable = is_enable; /*三层口均开启*/
        ig_md.common.svi_flag = is_svi;
        // ig_md.route.ipv4_unicast_enable = ipv4_unicast_enable;
        // ig_md.route.ipv6_unicast_enable = ipv6_unicast_enable;
    }

    @use_hash_action(1)
    @stage(2)
    table vlan_attr{
        key = {
            hdr.vlan_tag[0].vid : exact;
        }

        actions = {
            set_vlan_properties;
        }

        const default_action = set_vlan_properties(0, 0, SWITCH_L2_IIF_TYPE, false, 0);
        size = 4096;
    }

    apply{
        if (ig_md.lkp.vid == 0){
            add_native_vlan.apply();
        }

        if(ig_md.flags.vlan_member_check == 1 && hdr.vlan_tag[0].isValid()
                && ig_md.common.iif_type == SWITCH_L2_IIF_TYPE){
            vlan_attr.apply();
        }
    }
}

control VlanMemberCheck(
        inout switch_header_t hdr,
        inout switch_ingress_metadata_t ig_md) {

    /* by liyuhang */
    Hash<bit<32>>(HashAlgorithm_t.IDENTITY) hash;

    const bit<32> vlan_membership_size = 1 << 19; //src_port[6:0] + vid => 6 + 12 = 19
    Register<bit<1>, bit<32>>(vlan_membership_size, 0) vlan_membership;
    RegisterAction<bit<1>, bit<32>, bit<1>>(vlan_membership) check_vlan_membership = {
        void apply(inout bit<1> val, out bit<1> rv) {
            rv = ~val;
        }
    };

    action check() {
        bit<32> pv_hash_ = hash.get({ig_md.common.src_port[6:0], hdr.vlan_tag[0].vid});
        ig_md.flags.vlan_member_check = check_vlan_membership.execute(pv_hash_); //vlan check miss时,vlan_member_miss=1
    }

    table vlan_check{
        /* keyless */
        actions = {
            check;
        }

        const default_action = check();
    }

    apply{
        if (ig_md.flags.vlan_member_check == 1){
            vlan_check.apply();
        }
    }
}

control EgressEvlanStats(inout switch_egress_metadata_t eg_md){

    const switch_uint32_t counter_size = 1024*12;
    Counter<bit<64>, bit<14>>(counter_size, CounterType_t.PACKETS_AND_BYTES) evlan_counter;

    action evlan_count(bit<14> index){
        evlan_counter.count(index);
    }

    @stage(10)
    table evlan_stats{
        key = {
            eg_md.lkp.pkt_type : exact;
            eg_md.ebridge.evlan : exact;
        }
        actions = {
            evlan_count;
            NoAction;
        }
        const default_action = NoAction;
        size = 1024*20;
    }

    apply{
        evlan_stats.apply();
    }
}
# 193 "/mnt/p4c-4127/p4src/switch-tofino2/switch_tofino_x1.p4" 2
# 1 "/mnt/p4c-4127/p4src/shared/intf_port.p4" 1
//-----------------------------------------------------------------------------
// pipeline 0 front Ingress port Mapping
//
// @param hdr : Parsed headers.
// @param ingress_port: physics port
// @param eg_md : Egress metadata fields.
// @param port : Egress port.
//
//-----------------------------------------------------------------------------
control IngressPortMapping_front(
        inout switch_header_t hdr,
        in ingress_intrinsic_metadata_t ig_intr_md,
        inout switch_ingress_metadata_t ig_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm // by weiyunfeng
        )(switch_uint32_t port_table_size=512) {

    /* by yeweixin */
    // Random<bit<16>>() random; 

    /* by yeweixin */
    action terminate_cpu_eth_packet() {
        ig_md.common.pkt_type = hdr.fabric_from_cpu_eth_base.pkt_type;
        // ig_md.flags.escape_etm = hdr.fabric_from_cpu_eth_base.escape_etm;
        ig_md.flags.escape_etm = 0;
        ig_md.common.track = hdr.fabric_from_cpu_eth_base.track;
        hdr.ethernet.ether_type = hdr.fabric_eth_etype.ether_type;
        hdr.fabric_from_cpu_eth_base.setInvalid();
        hdr.fabric_from_cpu_eth_data.setInvalid();
        hdr.fabric_eth_etype.setInvalid();
    }

    action ingress_port_front(switch_logic_port_t src_port,
                            switch_port_t egress_port,
                            switch_eport_t eport)
    {
        ig_md.common.src_port = src_port;
        ig_md.common.eport = eport;
        // ig_md.ipfix.random_num = random.get(); /* by yeweixin */
        ig_intr_md_for_tm.ucast_egress_port = egress_port;
    }

    action ingress_port_front_extend(switch_logic_port_t src_port,
                            switch_port_t egress_port,
                            switch_eport_t eport)
    {
        hdr.ethernet.ether_type = hdr.br_tag.ether_type;
        ig_md.common.src_port = src_port;
        ig_md.common.eport = eport;
        // ig_md.ipfix.random_num = random.get(); /* by yeweixin */
        ig_intr_md_for_tm.ucast_egress_port = egress_port;
        // hdr.br_tag.setInvalid();   暂时去掉，mirror可能用到，先用隐性set
    }

    action ingress_port_cpu_eth(switch_logic_port_t lport,
                            switch_port_t egress_port,
                            switch_eport_t eport)
    {
        // ig_md.common.src_port = lport;
        // ig_md.common.eport = eport;  
        ig_intr_md_for_tm.ucast_egress_port = egress_port;
        terminate_cpu_eth_packet();
    }

    /* XXX:only SRv6 needs loopback now */
    action ingress_port_recirc() {
        ig_intr_md_for_tm.ucast_egress_port = hdr.pri_data.egress_port;
        hdr.ethernet.ether_type = hdr.pri_data.ether_type;
        hdr.pri_data.setInvalid();
    }

    table ingress_port_mapping {
        key = {
            ig_intr_md.ingress_port: exact @name("ingress_port");
            hdr.br_tag.isValid() : ternary;
            hdr.br_tag.ecid : ternary;
        }

        actions = {
            ingress_port_front_extend;
            ingress_port_front;
            ingress_port_cpu_eth;
            ingress_port_recirc;
        }
        size = port_table_size;
    }

    action set_lport_properties(
            switch_pkt_color_t color,
            switch_tc_t tc,
            switch_qos_trust_mode_t trust_mode,
            bit<5> ds,
            bit<1> is_auto,
            bit<1> flowspec_disable_v4,
            bit<1> flowspec_disable_v6) {
        // qos
        ig_md.qos.color = color;
        ig_md.qos.tc = tc;
        ig_md.qos.port_trust_mode = trust_mode;
        ig_md.qos.port_ds = ds;
        ig_md.qos.is_auto_trust = is_auto;
        // acl
        ig_md.flags.flowspec_disable_v4 = flowspec_disable_v4;
        ig_md.flags.flowspec_disable_v6 = flowspec_disable_v6;
    }

    Counter<bit<64>, bit<8>>(256, CounterType_t.PACKETS_AND_BYTES) ig_lport_stats;

    //bit<8> count_idx = 0;
    action ip_count(bit<8> counter_id) {
        ig_lport_stats.count(counter_id);
    }

    //@use_hash_action(1)
    table lport_stats {
        key = {
            hdr.ipv4.isValid() : exact;
            hdr.ipv6.isValid() : exact;
            ig_md.common.src_port : exact;
        }

        actions = {
            @defaultonly NoAction;
            ip_count;
        }

        //const default_action = ip_count(0);
        size = 1024;
    }

    table lport_properties {
        key = {
            ig_md.common.src_port : exact;
        }

        actions = {
            NoAction;
            set_lport_properties;
        }

        const default_action = NoAction;
        size = port_table_size;
    }

    apply {
        ingress_port_mapping.apply();
        if (ig_md.common.pkt_type != FABRIC_PKT_TYPE_CCM) {
            lport_properties.apply();
        }
        // lport_stats.apply();
    }
}

control IngressPortStat_front(
        inout switch_header_t hdr,
        inout switch_ingress_metadata_t ig_md
        )(switch_uint32_t port_table_size=512) {

    Counter<bit<64>, bit<8>>(256, CounterType_t.PACKETS_AND_BYTES) ig_lport_stats;

    //bit<8> count_idx = 0;
    action ip_count(bit<8> counter_id) {
        ig_lport_stats.count(counter_id);
    }

    //@use_hash_action(1)
    table lport_stats {
        key = {
            hdr.ipv4.isValid() : exact;
            hdr.ipv6.isValid() : exact;
            ig_md.common.src_port : exact;
        }

        actions = {
            @defaultonly NoAction;
            ip_count;
        }

        //const default_action = ip_count(0);
        size = 1024;
    }

    apply {
        lport_stats.apply();
    }
}

//-----------------------------------------------------------------------------
// pipeline 3 Egress port mapping
//-----------------------------------------------------------------------------
control EgressPortMapping_downlink(
        inout switch_egress_metadata_t eg_md)(
        switch_uint32_t table_size = 512) {

    action set_lport_properties(bit<5> ds, bit<1> phb, bit<1> enb, bit<12> qid) {
        eg_md.qos.port_ds = ds;
        eg_md.qos.port_PHB = phb;
        eg_md.qos.port_hqos_enb = enb;
        eg_md.qos.port_base_qid = qid;
    }
    @stage(2)
    table lport_properties {
        key = {
            eg_md.common.dst_port : exact;
        }
        actions = {
            set_lport_properties;
        }
        size = table_size;
    }

    apply {
        lport_properties.apply();
    }
}

//-----------------------------------------------------------------------------
// Fabric Ingress port mapping
//-----------------------------------------------------------------------------
control LportMapping_Fabric(
        inout switch_ingress_metadata_t ig_md)(
        switch_uint32_t table_size = 512) {

    action set_lport_properties(bit<1> enb, bit<12> qid) {
        ig_md.qos.port_hqos_enb = enb;
        ig_md.qos.port_base_qid = qid;
    }
    table lport_properties {
        key = {
            ig_md.common.dst_port : exact;
        }
        actions = {
            set_lport_properties;
        }
        size = table_size;
    }

    apply {
        lport_properties.apply();
    }
}

//-------------------------------------------------------------------------------------------------
// Storm Control
//
// Monitors incoming traffic and prevents the excessive traffic on a particular interface by
// dropping the traffic. Each port has a single storm control levels for all types of traffic
// (broadcast, multicast, and unicast).
//
// @param ig_md : Ingress metadata fields
// @param pkt_type : One of Unicast, Multicast, or Broadcast packet types.
// @param flag : Indicating whether the packet should get dropped or not.
// @param table_size : Size of the storm control table.
//-------------------------------------------------------------------------------------------------
control StormControl(inout switch_egress_metadata_t eg_md)(
                     switch_uint32_t table_size=1024) {
    // DirectCounter<bit<64>>(CounterType_t.PACKETS_AND_BYTES) storm_control_stats;
    // Counter<bit<64>, bit<16>>(3072, CounterType_t.PACKETS_AND_BYTES) storm_control_stats;
    Meter<bit<10>>(table_size, MeterType_t.BYTES) meter;
    // bit<10> tmp_index;

    // action count(bit<16> stats_id) {
    //     storm_control_stats.count(stats_id);
    // }

    // action drop_and_count(bit<16> stats_id) {
    //     storm_control_stats.count(stats_id);
    // }

    // table stats {
    //     key = {
    //         tmp_index : exact @name("index");
    //         eg_md.qos.storm_control_color: exact;
    //     }

    //     actions = {
    //         @defaultonly NoAction;
    //         count;
    //         drop_and_count;
    //     }

    //     const default_action = NoAction;
    //     size = table_size * 3;
    // }

    action set_meter(bit<10> index) {
        // tmp_index = index;
        eg_md.qos.storm_control_color = (bit<2>) meter.execute(index);
    }

    table storm_control {
        key = {
            eg_md.common.src_port : exact;
            eg_md.lkp.pkt_type : exact @name("pkt_type");
            eg_md.flags.dmac_miss : exact;
            eg_md.common.is_mcast : exact;
        }

        actions = {
            @defaultonly NoAction;
            set_meter;
        }

        const default_action = NoAction;
        size = table_size;
    }

    apply {
        storm_control.apply();
        // stats.apply();
    }
}

//-------------------------------------------------------------------------------------------------
// downlink pipe Dev Port Mapping
//
// port id is set from sda, but no device port.
// this control mapping port id to device port.
//
// @param ig_md : Ingress metadata fields
// @param ig_intr_md_for_tm : Ingress intrinsic metadata fields
//-------------------------------------------------------------------------------------------------
control DevPortMapping_downlink(inout switch_ingress_metadata_t ig_md,
                       inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm)(
                       switch_uint32_t table_size=512) {

    action set_dev_port(switch_port_t dev_port) {
        ig_intr_md_for_tm.ucast_egress_port = dev_port;
    }

    table dev_port_mapping {
        key = {
            ig_md.common.dst_port : exact;
        }

        actions = {
            NoAction;
            set_dev_port;
        }

        const default_action = NoAction;
        size = table_size;
    }

    apply {
        dev_port_mapping.apply();
    }
}
//-----------------------------------------------------------------------------
// 802.1br utag Vlan translation
// 注解：M芯片对于utag的报文会进行泛洪操作，默认utag报文需要指定为4095
// @param hdr : Parsed headers.
// @param eg_md : Egress metadata fields.
//-----------------------------------------------------------------------------
// control BrVlanUtagXlate(inout switch_header_t hdr,
//                   in switch_egress_metadata_t eg_md)(
//                   switch_uint32_t port_table_size=512) {
//     action set_br_vlan_untagged(vlan_id_t vid) {
//         hdr.vlan_tag[0].setValid();
//         hdr.vlan_tag[0].ether_type = hdr.ethernet.ether_type;
//         hdr.vlan_tag[0].cfi = 0;
//         hdr.vlan_tag[0].vid =  vid;
//         hdr.ethernet.ether_type = ETHERTYPE_VLAN;
//     }

//     action set_br_vlan_tagged() {

//     }
//     @stage(2)
//     table br_utag_xlate {
//         key = {
//             eg_md.common.dst_port : exact;
//             hdr.vlan_tag[0].isValid() : exact;
//         }

//         actions = {
//             set_br_vlan_untagged;
//             set_br_vlan_tagged;
//         }

//         const default_action = set_br_vlan_tagged;
//         size = port_table_size;
//     }

//     apply {
//         br_utag_xlate.apply();
//     }
// }

//-----------------------------------------------------------------------------
// 802.1br translation
//
// @param hdr : Parsed headers.
// @param eg_md : Egress metadata fields.
// 
//-----------------------------------------------------------------------------
control BrXlate(inout switch_header_t hdr,
        inout switch_egress_metadata_t eg_md,
        in egress_intrinsic_metadata_t eg_intr_md)(
        switch_uint32_t port_table_size=512) {

    action set_br_untagged() {
    }

    action set_br_vlan_utagged(vlan_id_t vid, bit<12> ecid) {
        // utagged vlan encap
        hdr.vlan_tag[0].setValid();
        hdr.vlan_tag[0].ether_type = hdr.ethernet.ether_type;
        hdr.vlan_tag[0].cfi = 0;
        hdr.vlan_tag[0].vid = vid;

        // 802.1br encap
        hdr.br_tag.setValid();
        hdr.br_tag.ether_type = 0x8100;
        hdr.br_tag.epcp = 0;
        hdr.br_tag.edei = 0;
        hdr.br_tag.ingress_ecid = 0;
        hdr.br_tag.reserved =0;
        hdr.br_tag.grp = 0;
        hdr.br_tag.ecid = ecid;
        hdr.br_tag.ingress_ecid_ext = 0;
        hdr.br_tag.ecid_ext = 0;
        hdr.ethernet.ether_type = 0x893F;
    }

    action set_br_tagged(bit<12> ecid) {
        // 802.1br encap
        hdr.br_tag.setValid();
        hdr.br_tag.ether_type = hdr.ethernet.ether_type;
        hdr.br_tag.epcp = 0;
        hdr.br_tag.edei = 0;
        hdr.br_tag.ingress_ecid = 0;
        hdr.br_tag.reserved =0;
        hdr.br_tag.grp = 0;
        hdr.br_tag.ecid = ecid;
        hdr.br_tag.ingress_ecid_ext = 0;
        hdr.br_tag.ecid_ext = 0;
        hdr.ethernet.ether_type = 0x893F;
    }

    table port_to_br_mapping {
        key = {
            eg_md.common.dst_port : exact;
            hdr.vlan_tag[0].isValid() : exact;
        }

        actions = {
            set_br_untagged;
            set_br_tagged;
            set_br_vlan_utagged;
        }

        size = port_table_size;
    }

    apply {
        port_to_br_mapping.apply();
    }
}

//-----------------------------------------------------------------------------
// Multicast Link Aggregation (MC_LAG) resolution
//-----------------------------------------------------------------------------
control MC_LAG(
    inout switch_egress_metadata_t eg_md)(
    switch_uint32_t mc_lag_table_size=512,
    switch_uint32_t mc_lag_max_entrys=5120) {

    Hash<switch_uint16_t>(HashAlgorithm_t.IDENTITY) selector_hash;
    ActionSelector(mc_lag_max_entrys,
                   selector_hash,
                   SelectorMode_t.FAIR) mc_lag_selector;

    action load_balancing(switch_logic_port_t lport) {
        eg_md.common.dst_port = lport;
    }

    action lag_miss() {
        eg_md.common.dst_port = 249;
    }

    // selector_enable_scramble表示selector为线性配置
    @stage(1)
    @pragma selector_enable_scramble 0
    table mc_lag {
        key = {
            eg_md.common.egress_eport : exact @name("eport");
            eg_md.common.hash : selector;
        }

        actions = {
            load_balancing;
            lag_miss;
        }

        const default_action = lag_miss();
        size = mc_lag_table_size;
        implementation = mc_lag_selector;
    }

    apply {
        if (eg_md.common.egress_eport[15:15] == 1) {
            mc_lag.apply();
        }
    }
}

/* hash pretreatment */
control HASH_PRETREATMENT_Fabric(
        inout switch_ingress_metadata_t ig_md
        )(
        switch_uint32_t lag_table_size=512,
        switch_uint32_t lag_max_entrys=512) {

    bit<16> temp_hash_id;
    Hash<bit<16>>(HashAlgorithm_t.IDENTITY) hash_16_pv;

    action load_balancing(bit<16> hash_id) {
        temp_hash_id = ig_md.common.hash & hash_id;
    }

    table fabric_lag_hash {
        key = {
            ig_md.common.dst_device : exact;
        }

        actions = {
            load_balancing;
        }
        size = lag_table_size;
    }

    action set_hash_reseal() {
        ig_md.common.hash[15 : 0] = hash_16_pv.get(temp_hash_id);
    }

    table hash_reseal{
        key = {
            temp_hash_id : exact;
            ig_md.common.dst_device : exact;
        }
        actions = {
            NoAction;
            set_hash_reseal;
        }
        const default_action = NoAction;
        size = lag_max_entrys;
    }
    apply {
        fabric_lag_hash.apply();
        hash_reseal.apply();
    }
}
# 194 "/mnt/p4c-4127/p4src/switch-tofino2/switch_tofino_x1.p4" 2
# 1 "/mnt/p4c-4127/p4src/shared/lif.p4" 1
//-----------------------------------------------------------------------------
// lif mapping and lif properties
//
// @param hdr : Parsed headers.
// @param ingress_port: physics port
// @param eg_md : Egress metadata fields.
// @param port : Egress port.
//
//-----------------------------------------------------------------------------
control IngressLifMapping(
        inout switch_header_t hdr,
        inout switch_ingress_metadata_t ig_md)(
            switch_uint32_t lif_table_size=32768,
            switch_uint32_t lif_properties_table_size=16384,
            switch_uint32_t back_lif_table_size=512) {

    action set_lif(switch_lif_t lif, bool enable, switch_iif_type_t iif_type) {
        ig_md.common.iif = lif;
        ig_md.common.ul_iif = lif;
        hdr.bridged_md_12_encap.ul_iif = lif;
        ig_md.common.iif_type = iif_type;
        ig_md.route.g_l3mac_enable = enable;
    }

    action miss (){
        ig_md.common.iif_type = SWITCH_L3_IIF_TYPE;
    }

    @placement_priority(127)
    table port_vlan_to_lif_mapping {
        key = {
            ig_md.common.eport : exact;
            hdr.vlan_tag[0].isValid() : exact;
            ig_md.lkp.vid : exact;
        }

        actions = {
            NoAction;
            set_lif;
            // set_cpu_eth_lif;// key = {cpu_eth_eport, false, _}
        }

        const default_action = NoAction;
        size = lif_table_size;
    }

    table back_port_vlan_to_lif_mapping {
        key = {
            ig_md.common.eport : ternary;
            hdr.vlan_tag[0].isValid() : ternary;
            ig_md.lkp.vid : ternary;
        }

        actions = {
            NoAction;
            set_lif;
            // set_cpu_eth_lif;// key = {cpu_eth_eport, false, _}
        }

        const default_action = NoAction;
        size = back_lif_table_size;
    }

    action set_port_to_lif(switch_lif_t lif, bit<1> check_enable) {
        ig_md.common.iif = lif;
        ig_md.common.ul_iif = lif;
        hdr.bridged_md_12_encap.ul_iif = lif;
        ig_md.common.iif_type = SWITCH_L2_IIF_TYPE;
        ig_md.flags.vlan_member_check = check_enable;
    }

    table port_to_lif_mapping{
        key = {
            ig_md.common.src_port : exact;
        }
        actions = {
            set_port_to_lif;
            miss;
        }
        const default_action = miss;
        /*端口目前最大48个口*/
        size = 1024;
    }

    action set_lif_properties(switch_qos_trust_mode_t trust_mode, bit<1> is_auto, bit<5> ds, bit<14> lif_meter_index,
            switch_pkt_color_t color, switch_tc_t tc, bit<1> is_pipe) {
        ig_md.qos.lif_trust_mode = trust_mode;
        ig_md.qos.lif_ds = ds;
        ig_md.qos.lif_meter_index = lif_meter_index;
        ig_md.qos.is_auto_trust = is_auto | ig_md.qos.is_auto_trust;

        ig_md.qos.color_tmp = color;
        ig_md.qos.tc_tmp = tc;
        ig_md.qos.BA = is_pipe;
    }
    @use_hash_action(1)
    table lif_properties {
        key = {
            ig_md.common.ul_iif : exact;
        }
        actions = {
            set_lif_properties;
        }
        const default_action = set_lif_properties(0, 0, 0, 0, 0, 0, 0);
        size = lif_properties_table_size;
    }

    action set_mpls_enb(bool mpls_enable) {
        ig_md.tunnel.mpls_enable = mpls_enable;
    }
    table lif_mpls_enb {
        key = {
            ig_md.common.ul_iif : exact;
        }
        actions = {
            set_mpls_enb;
        }
        const default_action = set_mpls_enb(false);
        size = lif_properties_table_size;
    }

    apply {
        switch(port_vlan_to_lif_mapping.apply().action_run){
            NoAction:{
                switch(back_port_vlan_to_lif_mapping.apply().action_run){
                    NoAction:{
                        port_to_lif_mapping.apply();
                    }
                }
            }
        }

        if (ig_md.common.ul_iif != 0) {
            lif_properties.apply();
        }
        if (ig_md.common.iif_type == SWITCH_L3_IIF_TYPE){
            lif_mpls_enb.apply();
        }
    }
}

control Uplink_lif_properties(
        inout switch_egress_metadata_t eg_md)(
        switch_uint32_t table_size = 16384) {

    action set_lif_properties(bit<5> ds, bit<3> trust) {
        eg_md.qos.lif_ds = ds;
        eg_md.qos.trust_mode = trust;
    }

    @use_hash_action(1)
    table lif_properties {
        key = {
            eg_md.common.iif : exact;
        }
        actions = {
            set_lif_properties;
        }
        const default_action = set_lif_properties(0, 0);
        size = table_size;
    }

    apply {
        lif_properties.apply();
    }
}

control ITM_ENB(
        inout switch_header_t hdr,
        inout switch_egress_metadata_t eg_md)
        (switch_uint32_t table_size = 1024) {

    action set_ul_iif_common() {
        eg_md.common.ul_iif = eg_md.common.iif;
    }

    action set_ul_iif_decap() {
        eg_md.common.ul_iif = hdr.ext_tunnel_decap.ul_iif;
    }

    table set_ul_iif {
        key = {
            hdr.ext_tunnel_decap.isValid() : exact;
        }
        actions = {
            set_ul_iif_common;
            set_ul_iif_decap;
        }
        const entries = {
            (true) : set_ul_iif_decap;
            (false) : set_ul_iif_common;
        }
        size = 4;
    }

    action set_itm_enb(bit<1> enb) {
        eg_md.flags.enb_itm = enb;
    }

    table lif_enb_itm {
        key = {
            eg_md.common.ul_iif : exact;
        }
        actions = {
            set_itm_enb;
            NoAction;
        }
        const default_action = NoAction;
        size = table_size;
    }

    apply {
        set_ul_iif.apply();
        lif_enb_itm.apply();
    }
}

control L2iif_Properties(
        inout switch_ingress_metadata_t ig_md)(
        switch_uint32_t lif_properties_table_size = 16384) {

    action set_l2iif_properties(switch_evlan_t evlan, bool hit_flag) {
        ig_md.ebridge.evlan = hit_flag ? evlan : ig_md.ebridge.evlan;
    }

    /* this table must be after tunnel terminate*/
    @use_hash_action(1)
    table l2iif_properties {
        key = {
            ig_md.common.iif : exact;
        }
        actions = {
            set_l2iif_properties;
        }
        const default_action = set_l2iif_properties(0,false);
        size = lif_properties_table_size;
    }

    apply {
        if(ig_md.common.iif_type == SWITCH_L2_IIF_TYPE) {
            l2iif_properties.apply();
        }
    }
}

control EgressLifMapping(
        inout switch_egress_metadata_t eg_md)
        (switch_uint32_t table_size = 16 * 1024) {

    action set_lif_properties(bit<5> ds, bit<1> phb, bit<1> enb, bit<12> qid, bit<14> lif_meter_index, bit<1> is_pipe) {
        // 当子接口配置超出4K,qid和hqos_enb都�??0
        eg_md.qos.lif_ds = ds;
        eg_md.qos.lif_PHB = phb;
        eg_md.qos.lif_hqos_enb = enb;
        eg_md.qos.lif_base_qid = qid;
        eg_md.qos.lif_meter_index = lif_meter_index;
        eg_md.qos.is_pipe = is_pipe;
    }

    @use_hash_action(1)
    @stage(3)
    table lif_properties {
        key = {
            eg_md.common.oif : exact;
        }
        actions = {
            set_lif_properties;
        }
        const default_action = set_lif_properties(0, 0, 0, 0, 0, 0);
        size = table_size;
    }

    apply {
        lif_properties.apply();
    }
}

control LifMapping_Fabric(
        inout switch_ingress_metadata_t ig_md)
        (switch_uint32_t table_size = 16 * 1024) {

    action set_lif_properties(bit<1> enb, bit<12> qid) {
        ig_md.qos.lif_hqos_enb = enb;
        ig_md.qos.lif_base_qid = qid;
    }
    @use_hash_action(1)
    table lif_properties {
        key = {
            ig_md.common.oif : exact;
        }
        actions = {
            set_lif_properties;
        }
        const default_action = set_lif_properties(0, 0);
        size = table_size;
    }

    apply {
        lif_properties.apply();
    }
}

control L2Port(
        inout switch_egress_metadata_t eg_md)(
        switch_uint32_t l2iif_table_size = 16384) {

    action from_fwd_lif(){
        eg_md.common.learn_iif = eg_md.common.iif;
    }
    action from_ul_lif(){
        eg_md.common.learn_iif = eg_md.common.ul_iif;
    }

    table get_learn_lif{
        key = {
            eg_md.common.svi_flag :exact;
        }

        actions = {
            from_ul_lif;
            from_fwd_lif;
        }
        // const entries = {
        //     (1)  : from_ul_lif;
        //     (0)  : from_fwd_lif;
        // }
    }

    action set_svp_properties(bit<2> ln_md, switch_lif_t l2oif, bit<1> dmac_bypass, bit<8> classid) {
        eg_md.flags.learning = ln_md;
        eg_md.ebridge.l2oif = l2oif;
        eg_md.flags.dmac_bypass = dmac_bypass;
        eg_md.common.iif_classid = classid; /*svi报文在l3properties重新赋值*/
    }

    @use_hash_action(1)
    table l2port {
        key = {
            /* 15 bit,highest bit=0:l2iif 1:l3iif */
            eg_md.common.learn_iif : exact;
        }
        actions = {
            set_svp_properties;
        }
        const default_action = set_svp_properties(0, 0, 0, 0);
        size = l2iif_table_size;
    }

    apply {
        get_learn_lif.apply();
        if(eg_md.common.iif_type == SWITCH_L2_IIF_TYPE || eg_md.common.svi_flag == 1) {
            l2port.apply();
        }
    }
}

control DL2PORT(
        inout switch_egress_metadata_t eg_md)(
        switch_uint32_t dl2port_table_size = 16384){

    action set_l2oif_properties(bit<16> nxthp, bit<1> is_ecmp, bit<2> lvl, bit<8> prrty) {
        eg_md.common.nexthop = nxthp;
        eg_md.route.is_ecmp = is_ecmp;
        eg_md.route.level = lvl;
        eg_md.route.priority_check = prrty |-| eg_md.route.pbr_priority;
    }

    @use_hash_action(1)
    table d_l2port {
        key = {
            eg_md.ebridge.l2oif : exact;
        }
        actions = {
            set_l2oif_properties;
        }
        const default_action = set_l2oif_properties(0, 0, 0, 0);
        size = dl2port_table_size;
    }
    apply {
        d_l2port.apply();
    }
}

control DL2PORT_Ingress(
        inout switch_header_t hdr,
        inout switch_ingress_metadata_t ig_md){

    action set_l2oif_properties(bit<16> dest) {
       ig_md.common.egress_eport = dest;
       ig_md.flags.ul_bridge = 1;
    }

    table d_l2port {
        key = {
            hdr.fabric_eth_ext.l2oif : exact;
        }
        actions = {
            set_l2oif_properties;
            NoAction;
        }
        const default_action = NoAction;
        size = 2048;
    }
    apply {
        if(hdr.fabric_base.is_mcast == 0 && hdr.fabric_base.pkt_type == FABRIC_PKT_TYPE_ETH && ig_md.common.ul_nhid == 0) {
            d_l2port.apply();
        }
    }
}

control L2IntfAttr(
        inout switch_egress_metadata_t eg_md)(
        switch_uint32_t l2oif_attribute_size = 16384,
        switch_uint32_t l2iif_attribute_size = 16384){

    action set_l2iif_properties(switch_netport_group_t ntpt_group, switch_ptag_mod_t ptg_igmd) {
        eg_md.tunnel.src_netport_group = ntpt_group;
        eg_md.tunnel.ptag_igmod = ptg_igmd;
    }

    @use_hash_action(1)
    @stage(1)
    table l2iif_attribute {
        key = {
            eg_md.common.iif : exact;
        }
        actions = {
            set_l2iif_properties;
        }
        const default_action = set_l2iif_properties(0, 0);
        size = l2iif_attribute_size;
    }

    action set_l2oif_attribute(switch_netport_group_t ntpt_group, bit<1> is_ul_bridge) {
        eg_md.tunnel.dst_netport_group = ntpt_group;
        eg_md.common.extend_fake = is_ul_bridge;
    }

    @use_hash_action(1)
    @stage(1)
    table l2oif_attribute {
        key = {
            eg_md.common.oif : exact;
        }
        actions = {
            set_l2oif_attribute;
        }
        const default_action = set_l2oif_attribute(0, 0);
        size = l2oif_attribute_size;
    }

    apply{
        if(eg_md.common.pkt_type == FABRIC_PKT_TYPE_ETH) {
            l2iif_attribute.apply();
        }

        if (eg_md.common.pkt_type == FABRIC_PKT_TYPE_ETH) {
            l2oif_attribute.apply();
        }
    }
}

control IifIPStats(inout switch_header_t hdr, inout switch_ingress_metadata_t ig_md)(
                     switch_uint32_t table_size=65536, switch_uint32_t ip_stat_size=10240) {
    Counter<bit<64>, bit<13>>(8192, CounterType_t.PACKETS_AND_BYTES) iif_stats_ip;

    action count_ip(bit<13> counter_id) {
        iif_stats_ip.count(counter_id);
    }

    table iif_stats_ip_pkt {
        key = {
            ig_md.common.ul_iif : exact;
            hdr.ipv4.isValid() : exact;
            hdr.ipv6.isValid() : exact;
        }

        actions = {
            @defaultonly NoAction;
            count_ip;
        }

        size = ip_stat_size;
    }

    apply {
        iif_stats_ip_pkt.apply();
    }
}

/* Packet statistics based on iif in front_ig */
control IifStats(inout switch_header_t hdr, inout switch_ingress_metadata_t ig_md)(
                     switch_uint32_t table_size=65536, switch_uint32_t ip_stat_size=10240) {
    Counter<bit<64>, bit<14>>(16384, CounterType_t.PACKETS_AND_BYTES) iif_stats_ig;
    Counter<bit<64>, bit<13>>(8192, CounterType_t.PACKETS_AND_BYTES) iif_stats_ip;
    Counter<bit<64>, bit<12>>(4096, CounterType_t.PACKETS_AND_BYTES) iif_base_stats;

    bit<14> count_idx = 0;


    action count_base(bit<12> counter_id) {
        // iif_stats_ig.count(counter_id);
        //count_idx = counter_id;
        iif_base_stats.count(counter_id);
    }

    //@use_hash_action(1)
    @stage(4)
    table iif_base {
        key = {
            ig_md.common.ul_iif : exact;
        }

        actions = {
            count_base;
        }

        //const default_action = count_base(0);
        size = 16384;
    }

    action count(bit<14> counter_id) {
        // iif_stats_ig.count(counter_id);
        count_idx = counter_id;
    }
    // @stage(3)
    @use_hash_action(1)
    table iif_stats {
        key = {
            ig_md.lkp.pkt_type : exact;
            ig_md.common.ul_iif : exact;
        }

        actions = {
            count;
        }

        const default_action = count(0);
        size = table_size;
    }

    action do_count() {
        iif_stats_ig.count(count_idx);
    }

    // @stage(4)
    @placement_priority(127)
    table iif_stats_act {
        // keyless
        actions = {
            do_count;
        }

        const default_action = do_count();
    }

    action count_ip(bit<13> counter_id) {
        iif_stats_ip.count(counter_id);
    }

    // table iif_stats_ip_pkt {
    //     key = {
    //         ig_md.common.ul_iif : exact;
    //         hdr.ipv4.isValid() : exact;
    //         hdr.ipv6.isValid() : exact;
    //     }

    //     actions = {
    //         @defaultonly NoAction;
    //         count_ip;
    //     }

    //     size = ip_stat_size;
    // }

    apply {
        iif_base.apply();
        iif_stats.apply();
        //iif_stats_ig.count(count_idx);
        iif_stats_act.apply();
        // iif_stats_ip_pkt.apply();
    }
}

/* Packet statistics based on iif in front_eg */
control OifStatsCountIdx(inout switch_header_t hdr, inout switch_egress_metadata_t eg_md)(
                     switch_uint32_t table_size=65536) {

    action count(bit<15> counter_id) {
        eg_md.ebridge.oif_count_idx = counter_id;
    }

    @stage(10)
    @use_hash_action(1)
    table oif_stats {
        key = {
            eg_md.lkp.pkt_type : exact;
            eg_md.common.oif: exact;
        }

        actions = {
            count;
        }

        const default_action = count(0);
        size = table_size;
    }

    apply {
        oif_stats.apply();
    }
}

control OifStats(inout switch_header_t hdr, inout switch_egress_metadata_t eg_md)(
                     switch_uint32_t ip_stat_size=10240) {
    Counter<bit<64>, bit<15>>(28672, CounterType_t.PACKETS_AND_BYTES) oif_stats_eg;
    Counter<bit<64>, bit<13>>(8192, CounterType_t.PACKETS_AND_BYTES) oif_stats_ip;

    action count_ip(bit<13> counter_id) {
        oif_stats_ip.count(index = counter_id);
    }

    table oif_stats_ip_pkt {
        key = {
            eg_md.common.oif : exact;
            hdr.ipv4.isValid() : exact;
            hdr.ipv6.isValid() : exact;
        }

        actions = {
            @defaultonly NoAction;
            count_ip;
        }

        size = ip_stat_size;
    }

    Counter<bit<64>, bit<8>>(256, CounterType_t.PACKETS_AND_BYTES) eg_lport_stats;

    action ip_count(bit<8> counter_id) {
        eg_lport_stats.count(index = counter_id);
    }

    //@use_hash_action(1)
    table lport_stats {
        key = {
            hdr.ipv4.isValid() : exact;
            hdr.ipv6.isValid() : exact;
            eg_md.common.dst_port : exact;
        }

        actions = {
            @defaultonly NoAction;
            ip_count;
        }

        //const default_action = ip_count(0);
        size = 1024;
    }

    apply {
        oif_stats_eg.count(index = eg_md.ebridge.oif_count_idx);
        oif_stats_ip_pkt.apply();
        // lport_stats.apply();
    }
}


control EgLportStats(inout switch_header_t hdr, inout switch_egress_metadata_t eg_md)() {

    Counter<bit<64>, bit<8>>(256, CounterType_t.PACKETS_AND_BYTES) eg_lport_stats;

    action ip_count(bit<8> counter_id) {
        eg_lport_stats.count(index = counter_id);
    }

    //@use_hash_action(1)
    table lport_stats {
        key = {
            hdr.ipv4.isValid() : exact;
            hdr.ipv6.isValid() : exact;
            eg_md.common.dst_port : exact;
        }

        actions = {
            @defaultonly NoAction;
            ip_count;
        }

        //const default_action = ip_count(0);
        size = 1024;
    }

    apply {
        lport_stats.apply();
    }
}


control OifBaseStats(inout switch_header_t hdr, inout switch_egress_metadata_t eg_md)(
                     switch_uint32_t table_size=16384) {

    Counter<bit<64>, bit<12>>(4096, CounterType_t.PACKETS_AND_BYTES) oif_base_stats;

    action count_base(bit<12> counter_id) {
        // iif_stats_ig.count(counter_id);
        //count_idx = counter_id;
        oif_base_stats.count(counter_id);
    }

    //@use_hash_action(1)
    table oif_base {
        key = {
            eg_md.common.oif: exact;
        }

        actions = {
            count_base;
        }

        //const default_action = count_base(0);
        size = 16384;
    }

    apply {
        oif_base.apply();
    }
}
# 195 "/mnt/p4c-4127/p4src/switch-tofino2/switch_tofino_x1.p4" 2
# 1 "/mnt/p4c-4127/p4src/shared/hash.p4" 1
//-------------------------------------------------------------------------------------------------
// ECMP/IG IPFIX/IG MIRROR Load balancing
//
// 本模块主要做ECMP, IG IPFIX, IG MIRROR的负载均衡, 包含:
// 二层均衡(纯二层/MPLS内层以太), IP均衡(IPv4/IPv6内外层), MPLS标签均衡(大于10层标签) 
// MPLS报文内层优先用IP均衡, 当前不支持IPinIP.
//
// @param hdr
// @param ig_md
//-------------------------------------------------------------------------------------------------

control IngressHASH_front (
        inout switch_header_t hdr,
        inout switch_ingress_metadata_t ig_md)(
        switch_uint32_t hash_mode_table_size=64,
        switch_uint32_t hash_compute_table_size=64) {

    CRCPolynomial<bit<32>>(32w0x04C11DB7, // polynomial
                           true, // reversed
                           false, // use msb?
                           false, // extended?
                           32w0xFFFFFFFF, // initial shift register value
                           32w0xFFFFFFFF // result xor
                           ) poly_crc32;
    Hash<bit<32>>(HashAlgorithm_t.CUSTOM, poly_crc32) eth_hash;
    Hash<bit<32>>(HashAlgorithm_t.CUSTOM, poly_crc32) ipv4_hash;
    Hash<bit<32>>(HashAlgorithm_t.CUSTOM, poly_crc32) ipv6_hash;
    Hash<bit<32>>(HashAlgorithm_t.CUSTOM, poly_crc32) mpls_hash;

     /* eth hash */
    action compute_eth_hash() {
        ig_md.common.hash = eth_hash.get({hdr.ethernet.dst_addr,
                                          hdr.ethernet.src_addr,
                                          ig_md.lkp.mac_src_addr,
                                          ig_md.lkp.mac_dst_addr,
                                          ig_md.common.udf})[31:16];
    }

    /* ipv4 hash */
    action compute_ipv4_hash() {
        ig_md.common.hash = ipv4_hash.get({ig_md.lkp.ip_src_addr[31:0],
                                           ig_md.lkp.ip_dst_addr[31:0],
                                           ig_md.lkp.ip_proto,
                                           ig_md.lkp.l4_src_port,
                                           ig_md.lkp.l4_dst_port,
                                           ig_md.common.udf})[31:16];
    }

    /* ipv6 hash */
    action compute_ipv6_hash() {
        ig_md.common.hash = ipv6_hash.get({ig_md.lkp.ip_src_addr,
                                           ig_md.lkp.ip_dst_addr,
                                           ig_md.lkp.ip_proto,
                                           ig_md.lkp.flow_label,
                                           ig_md.lkp.l4_src_port,
                                           ig_md.lkp.l4_dst_port,
                                           ig_md.common.udf})[31:16];
    }

    /* labels < 4, use labels + inner ip to compute mpls hash */
    action compute_mpls_hash() {
        ig_md.common.hash = mpls_hash.get({hdr.mpls_ig[0].label,
                                           hdr.mpls_ig[1].label,
                                           hdr.mpls_ig[2].label,
                                           hdr.mpls_ig[3].label,
                                           ig_md.common.udf})[31:16];
    }

    action miss() {}

    action set_hash_mode(switch_hash_mode_t mode, bit<16> udf) {
        ig_md.common.hash_mode = mode;
        ig_md.common.udf = udf;
    }

    table hash_mode_config {
        key = {
            hdr.ipv4.isValid() : exact;
            hdr.ipv6.isValid() : exact;
            hdr.mpls_ig[0].isValid() : exact;
            hdr.inner_ethernet.isValid() : exact;
            hdr.inner_ipv4.isValid() : exact;
            hdr.inner_ipv6.isValid() : exact;
        }

        actions = {
            set_hash_mode;
            NoAction;
        }

        size = hash_mode_table_size;
    }


    /* 内外层ETH和大于10层标签的报文计算哈希值 */
    table no_ip_hash_compute {
        key = {
            ig_md.common.hash_mode : exact;
        }

        actions = {
            compute_eth_hash;
            compute_mpls_hash;
            miss;
        }

        // const entries = {
        //     (SWITCH_HASH_MODE_NO_IP) : compute_eth_hash();
        //     (SWITCH_HASH_MODE_MPLS)  : compute_mpls_hash();
        // }
        const default_action = miss;
        size = hash_mode_table_size;
    }

    /* 内外层IP的报文计算哈希值 */
    table ip_hash_value_compute {
        key = {
            ig_md.common.hash_mode : exact;
        }

        actions = {
            compute_ipv4_hash;
            compute_ipv6_hash;
            miss;
        }

        // const entries = {
        //     (SWITCH_HASH_MODE_IPV4) : compute_ipv4_hash();
        //     (SWITCH_HASH_MODE_IPV6) : compute_ipv6_hash();
        // }

        size = hash_compute_table_size;
    }

    apply {
        hash_mode_config.apply();
        switch(no_ip_hash_compute.apply().action_run) {
            miss:{
                ip_hash_value_compute.apply();
            }
        }
    }
}

//-------------------------------------------------------------------------------------------------
// EG Ipfix/Mirror HASH Load balancing
//
// 本模块主要做 Ipfix, Eg Mirror的负载均衡,包含:
// 二层均衡(纯二层/MPLS内层以太), IP和MPLS均衡在阶段9做.
//
// @param hdr
// @param eg_md
//-------------------------------------------------------------------------------------------------

control EgressHASH_front (
        inout switch_header_t hdr,
        inout switch_egress_metadata_t eg_md)(
        switch_uint32_t hash_compute_table_size=64) {

    CRCPolynomial<bit<16>>(16w0x3D65,
                           true,
                           false,
                           false,
                           16w0x0000,
                           16w0x0000
                           ) poly_crc16;

    Hash<bit<16>>(HashAlgorithm_t.CUSTOM, poly_crc16) no_ip_hash;

    action miss() {}

    /* eth hash */
    action compute_no_ip_hash() {
        eg_md.common.hash = no_ip_hash.get({hdr.ethernet.ether_type,
                                            hdr.ethernet.src_addr,
                                            hdr.ethernet.dst_addr});
    }
    @stage(2)
    table hash_value_compute {
        key = {
            hdr.ipv4.isValid() : exact;
            hdr.ipv6.isValid() : exact;
            hdr.mpls_vc_eg.isValid() : exact;
        }

        actions = {
            compute_no_ip_hash;
            miss;
        }

        const entries = {
            (false, false, false) : compute_no_ip_hash(); /* 不存在外层IP和MPLS标签,计算纯二层以太哈希 */
            (true, false, false) : miss(); /* IPV4报文, 哈希值在阶段9计算 */
            (false, true, false) : miss(); /* IPV6报文, 哈希值在阶段9计算 */
            (false, false, true) : miss(); /* MPLS报文, 哈希值在阶段9计算 */
        }
        size = hash_compute_table_size;
    }

    apply {
        hash_value_compute.apply();
    }
}

//-------------------------------------------------------------------------------------------------
// ECMP IP Load balancing
//
// 本模块主要做ECMP的IP和IP分片报文的负载均衡,其他均衡模块在阶段1完成.
//
// @param hdr
// @param ig_md
//-------------------------------------------------------------------------------------------------

control EgressHASH_uplink (
        inout switch_header_t hdr,
        inout switch_egress_metadata_t eg_md)(
        switch_uint32_t hash_mode_table_size=64) {

    CRCPolynomial<bit<32>>(32w0x04C11DB7, // polynomial
                           true, // reversed
                           false, // use msb?
                           false, // extended?
                           32w0xFFFFFFFF, // initial shift register value
                           32w0xFFFFFFFF // result xor
                           ) poly_crc32;
    Hash<bit<32>>(HashAlgorithm_t.CUSTOM, poly_crc32) ipv4_hash;
    Hash<bit<32>>(HashAlgorithm_t.CUSTOM, poly_crc32) ipv6_hash;
    Hash<bit<32>>(HashAlgorithm_t.CUSTOM, poly_crc32) ipv4_fragment_hash;
    Hash<bit<32>>(HashAlgorithm_t.CUSTOM, poly_crc32) ipv6_fragment_hash;


    /* ipv4 hash */
    action compute_ipv4_hash() {
        eg_md.common.hash = ipv4_hash.get({hdr.ipv4.src_addr,
                                           hdr.ipv4.dst_addr,
                                           hdr.ipv4.protocol,
                                           eg_md.lkp.l4_src_port,
                                           eg_md.lkp.l4_dst_port,
                                           eg_md.common.udf})[31:16];
    }

    /* ipv6 hash */
    action compute_ipv6_hash() {
        eg_md.common.hash = ipv6_hash.get({hdr.ipv6.src_addr,
                                           hdr.ipv6.dst_addr,
                                           hdr.ipv6.next_hdr,
                                           eg_md.lkp.flow_label,
                                           eg_md.lkp.l4_src_port,
                                           eg_md.lkp.l4_dst_port,
                                           eg_md.common.udf})[31:16];
    }

    /* ipv4 fragment hash */
    action compute_ipv4_fragment_hash() {
        eg_md.common.hash = ipv4_fragment_hash.get({hdr.ipv4.src_addr,
                                                    hdr.ipv4.dst_addr,
                                                    hdr.ipv4.protocol,
                                                    eg_md.common.udf})[31:16];
    }

    /* ipv6 fragment hash */
    action compute_ipv6_fragment_hash() {
        eg_md.common.hash = ipv6_fragment_hash.get({hdr.ipv6.src_addr,
                                                    hdr.ipv6.dst_addr,
                                                    hdr.ipv6.next_hdr,
                                                    eg_md.lkp.flow_label,
                                                    eg_md.common.udf})[31:16];
    }

    action compute_ip_hash() {}

    /* 分片报文计算哈希 */
    table ip_hash_fragment_value_compute {
        key = {
            hdr.ipv4.isValid() : exact;
            hdr.ipv6.isValid() : exact;
        }
        actions = {
            compute_ipv4_fragment_hash;
            compute_ipv6_fragment_hash;
        }
        const entries = {
            (true, false) : compute_ipv4_fragment_hash(); /* IPv4分片 */
            (false, true) : compute_ipv6_fragment_hash(); /* IPv6分片 */
        }

        size = hash_mode_table_size;
    }

    /* 外层IP的报文计算哈希值 */
    table ip_hash_value_compute {
        key = {
            hdr.ipv4.isValid() : exact;
            hdr.ipv6.isValid() : exact;
        }
        actions = {
            compute_ipv4_hash;
            compute_ipv6_hash;
        }
        const entries = {
            (true, false) : compute_ipv4_hash(); /* 外层IPV4报文 */
            (false, true) : compute_ipv6_hash(); /* 外层IPV6报文 */
        }

        size = hash_mode_table_size;
    }

    apply {
        if (eg_md.lkp.ip_frag != SWITCH_IP_FRAG_NON_FRAG) {
            ip_hash_fragment_value_compute.apply();
        }
        if (eg_md.lkp.ip_frag == SWITCH_IP_FRAG_NON_FRAG){
            ip_hash_value_compute.apply();
        }
    }
}

//-------------------------------------------------------------------------------------------------
// AP/LC->FE HASH Load balancing
// 
// 本模块主要做AP/LC->FE的负载均衡, 包含:
// 二层均衡(纯二层/MPLS内层以太), IP均衡(IPv4/IPv6内外层), MPLS标签均衡(大于10层标签) 
// MPLS报文内层优先用IP均衡, 当前不支持IPinIP.
//
// @param hdr
// @param ig_md
//-------------------------------------------------------------------------------------------------
control IngressHASH_uplink (
        inout switch_header_t hdr,
        inout switch_ingress_metadata_t ig_md)(
        switch_uint32_t hash_mode_table_size=64,
        switch_uint32_t hash_compute_table_size=64) {

    CRCPolynomial<bit<32>>(32w0x04C11DB7, // polynomial
                           true, // reversed
                           false, // use msb?
                           false, // extended?
                           32w0xFFFFFFFF, // initial shift register value
                           32w0xFFFFFFFF // result xor
                           ) poly16_20;
    Hash<bit<32>>(HashAlgorithm_t.CUSTOM, poly16_20) mpls_hash;
    Hash<bit<32>>(HashAlgorithm_t.CUSTOM, poly16_20) eth_hash;
    Hash<bit<32>>(HashAlgorithm_t.CUSTOM, poly16_20) ipv4_hash;
    Hash<bit<32>>(HashAlgorithm_t.CUSTOM, poly16_20) ipv6_hash;

     /* use eth fields to compute hash */
    action compute_eth_hash() {
        ig_md.common.hash = eth_hash.get({ig_md.lkp.mac_src_addr,
                                          ig_md.lkp.mac_dst_addr,
                                          ig_md.common.udf})[15:0];
    }

    /* use ipv4 fields to compute hash */
    action compute_ipv4_hash() {
        ig_md.common.hash = ipv4_hash.get({ig_md.lkp.ip_src_addr[31:0],
                                           ig_md.lkp.ip_dst_addr[31:0],
                                           ig_md.lkp.ip_proto,
                                           ig_md.lkp.l4_src_port,
                                           ig_md.lkp.l4_dst_port,
                                           ig_md.common.udf})[15:0];
    }

    /* use ipv6 fields to compute hash */
    action compute_ipv6_hash() {
        ig_md.common.hash = ipv6_hash.get({ig_md.lkp.ip_src_addr,
                                           ig_md.lkp.ip_dst_addr,
                                           ig_md.lkp.ip_proto,
                                           ig_md.lkp.l4_src_port,
                                           ig_md.lkp.l4_dst_port,
                                           ig_md.lkp.flow_label,
                                           ig_md.common.udf})[15:0];
    }

    /* use mpls labels to compute hash */
    action compute_mpls_hash() {
        ig_md.common.hash = mpls_hash.get({hdr.mpls_ig[0].label,
                                           hdr.mpls_ig[1].label,
                                           hdr.mpls_ig[2].label,
                                           hdr.mpls_ig[3].label,
                                           ig_md.common.udf})[15:0];
    }

    action set_hash_mode(switch_hash_mode_t mode, bit<16> udf) {
        ig_md.common.hash_mode = mode;
        ig_md.common.udf = udf;
    }

    table hash_mode_config {
        key = {
            hdr.ipv4.isValid() : exact;
            hdr.ipv6.isValid() : exact;
            hdr.mpls_ig[0].isValid() : exact;
            hdr.inner_ethernet.isValid() : exact;
            hdr.inner_ipv4.isValid() : exact;
            hdr.inner_ipv6.isValid() : exact;
        }

        actions = {
            set_hash_mode;
        }

        size = hash_mode_table_size;
    }

    table no_ip_hash_value_compute {
        key = {
            ig_md.common.hash_mode : exact;
        }

        actions = {
            compute_eth_hash;
            compute_mpls_hash;
        }

        // const entries = {
        //     (SWITCH_HASH_MODE_NO_IP) : compute_eth_hash();
        //     (SWITCH_HASH_MODE_MPLS)  : compute_mpls_hash();
        // }

        size = hash_compute_table_size;
    }
    @placement_priority(127)
    table ip_hash_value_compute {
        key = {
            ig_md.common.hash_mode : exact;
        }

        actions = {
            compute_ipv4_hash;
            compute_ipv6_hash;
        }

        // const entries = {
        //     (SWITCH_HASH_MODE_IPV4) : compute_ipv4_hash();
        //     (SWITCH_HASH_MODE_IPV6) : compute_ipv6_hash();
        // }

        size = hash_compute_table_size;
    }

    apply {
        hash_mode_config.apply();
        no_ip_hash_value_compute.apply();
        ip_hash_value_compute.apply();
    }
}

//-------------------------------------------------------------------------------------------------
// LC->下行FPGA HASH Load balancing
// 
// 本模块主要做下行FPGA的负载均衡, 包含:
// 二层均衡(纯二层/MPLS内层以太), IP均衡(IPv4/IPv6内外层), MPLS标签均衡(大于10层标签), IPv4/IPv6分片报文均衡
// MPLS报文内层优先用IP均衡, 当前不支持IPinIP.
//
// @param hdr
// @param ig_md
//-------------------------------------------------------------------------------------------------

control IngressHASH_fabric (
        inout switch_header_t hdr,
        inout switch_ingress_metadata_t ig_md)(
        switch_uint32_t hash_mode_table_size=64,
        switch_uint32_t hash_compute_table_size=64) {

    CRCPolynomial<bit<16>>(16w0x1021, // polynomial crc-16-t10-dif
                           true, // reversed
                           false, // use msb?
                           false, // extended?
                           16w0xffff, // initial shift register value
                           16w0x0000 // result xor
                           ) poly_crc16;
    Hash<bit<16>>(HashAlgorithm_t.CUSTOM, poly_crc16) eth_hash;
    Hash<bit<16>>(HashAlgorithm_t.CUSTOM, poly_crc16) ipv6_hash;
    Hash<bit<16>>(HashAlgorithm_t.CUSTOM, poly_crc16) mpls_hash;
    Hash<bit<16>>(HashAlgorithm_t.CUSTOM, poly_crc16) ipv4_hash;

     /* use eth fields to compute hash */
    action compute_eth_hash() {
        ig_md.common.hash = eth_hash.get({ig_md.lkp.mac_src_addr,
                                          ig_md.lkp.mac_dst_addr});
    }

    /* use ipv4 fields to compute hash */
    action compute_ipv4_hash() {
        ig_md.common.hash = ipv4_hash.get({ig_md.lkp.ip_src_addr[31:0],
                                           ig_md.lkp.ip_dst_addr[31:0],
                                           ig_md.lkp.ip_proto,
                                           ig_md.lkp.l4_src_port,
                                           ig_md.lkp.l4_dst_port});
    }

    /* use ipv6 fields to compute hash */
    action compute_ipv6_hash() {
        ig_md.common.hash = ipv6_hash.get({ig_md.lkp.ip_src_addr,
                                           ig_md.lkp.ip_dst_addr,
                                           ig_md.lkp.ip_proto,
                                           ig_md.lkp.flow_label,
                                           ig_md.lkp.l4_src_port,
                                           ig_md.lkp.l4_dst_port});
    }

    /* use mpls labels to compute hash */
    action compute_mpls_hash() {
        ig_md.common.hash = mpls_hash.get({hdr.mpls_fabric_ig[0].label,
                                           hdr.mpls_fabric_ig[1].label,
                                           hdr.mpls_fabric_ig[2].label,
                                           hdr.mpls_fabric_ig[3].label});
    }

    action miss() {}

    /* 内外层ETH和大于10层标签的报文计算哈希值 */
    table no_ip_hash_value_compute {
        key = {
            hdr.ipv4.isValid() : exact;
            hdr.ipv6.isValid() : exact;
            hdr.mpls_fabric_ig[0].isValid() : exact;
            hdr.inner_ethernet.isValid() : exact;
            hdr.inner_ipv4.isValid() : exact;
            hdr.inner_ipv6.isValid() : exact;
        }

        actions = {
            compute_eth_hash;
            compute_mpls_hash;
            miss;
        }

        const default_action = miss;
        size = hash_mode_table_size;

        // const entries = {
        //     (false, false, true, false, false, false)   : compute_mpls_hash();  /* MPLS大于10层标签 */
        //     (false, false, true, true, false, false)    : compute_eth_hash();   /* MPLS小于10层标签,且内层IP不存在 */
        //     (false, false, false, false, false, false)  : compute_eth_hash();   /* 纯二层报文 */
        // }
    }

    /* 内外层IP的报文计算哈希值 */
    table ip_hash_value_compute {
        key = {
            hdr.ipv4.isValid() : exact;
            hdr.ipv6.isValid() : exact;
            hdr.mpls_fabric_ig[0].isValid() : exact;
            hdr.inner_ipv4.isValid() : exact;
            hdr.inner_ipv6.isValid() : exact;
        }

        actions = {
            compute_ipv4_hash;
            compute_ipv6_hash;
            miss;
        }

        const default_action = miss;
        size = hash_compute_table_size;

        // const entries = {
        //     (true, false, false, false, false) : compute_ipv4_hash();  /* 外层IPV4报文 */
        //     (false, true, false, false, false) : compute_ipv6_hash();  /* 外层IPV6报文 */
        //     (false, false, true, true, false)  : compute_ipv4_hash();  /* MPLS标签小于10层,且内层IPV4存在 */
        //     (false, false, true, false, true)  : compute_ipv6_hash();  /* MPLS标签小于10层,且内层IPV6存在 */
        // }
    }

    apply {
        switch(no_ip_hash_value_compute.apply().action_run) {
            miss:{
                ip_hash_value_compute.apply();
            }
        }
    }
}

//-------------------------------------------------------------------------------------------------
// EG MIRROR Load balancing
//
// 本模块主要做EG MIRROR的负载均衡, 包含:
// IP均衡(IPv4/IPv6内外层), MPLS标签均衡(大于4层标签), 二层均衡当前放在阶段10做.
// MPLS报文内层优先用IP均衡, 阶段9由于只是用于镜像报文的均衡,所以只做了4层标签.
//
// @param hdr
// @param ig_md
//-------------------------------------------------------------------------------------------------

control IngressHASH_downlink (
        inout switch_header_t hdr,
        inout switch_ingress_metadata_t ig_md)(
        switch_uint32_t hash_mode_table_size=64,
        switch_uint32_t hash_compute_table_size=64) {

    CRCPolynomial<bit<16>>(16w0x8BB7,
                           true,
                           false,
                           false,
                           16w0xFFFF,
                           16w0x0000
                           ) poly_crc;
    Hash<bit<16>>(HashAlgorithm_t.CUSTOM, poly_crc) eth_hash;
    Hash<bit<16>>(HashAlgorithm_t.CUSTOM, poly_crc) ipv4_hash;
    Hash<bit<16>>(HashAlgorithm_t.CUSTOM, poly_crc) ipv6_hash;
    Hash<bit<16>>(HashAlgorithm_t.CUSTOM, poly_crc) mpls_hash;

     /* inner mpls eth hash */
    action compute_eth_hash() {
        ig_md.common.hash = eth_hash.get({hdr.inner_ethernet.src_addr,
                                          hdr.inner_ethernet.dst_addr});
    }

    /* ipv4 hash */
    action compute_ipv4_hash() {
        ig_md.common.hash = ipv4_hash.get({ig_md.lkp.ip_src_addr[31:0],
                                           ig_md.lkp.ip_dst_addr[31:0],
                                           ig_md.lkp.l4_src_port,
                                           ig_md.lkp.l4_dst_port});
    }

    /* ipv6 hash */
    action compute_ipv6_hash() {
        ig_md.common.hash = ipv6_hash.get({ig_md.lkp.ip_src_addr,
                                           ig_md.lkp.ip_dst_addr,
                                           ig_md.lkp.flow_label,
                                           ig_md.lkp.l4_src_port,
                                           ig_md.lkp.l4_dst_port});
    }

    /* mpls hash */
    action compute_mpls_hash() {
        ig_md.common.hash = mpls_hash.get({hdr.mpls_ig[0].label,
                                           hdr.mpls_ig[1].label,
                                           hdr.mpls_ig[2].label,
                                           hdr.mpls_ig[3].label});
    }

    action miss() {}

    table no_ip_hash_compute {
        key = {
            hdr.ipv4.isValid() : exact;
            hdr.ipv6.isValid() : exact;
            hdr.mpls_ig[0].isValid() : exact;
            hdr.inner_ethernet.isValid() : exact;
            hdr.inner_ipv4.isValid() : exact;
            hdr.inner_ipv6.isValid() : exact;
        }

        actions = {
            compute_eth_hash;
            compute_mpls_hash;
            miss;
        }

        const default_action = miss;
        size = hash_mode_table_size;

        // const entries = {
        //     (false, false, true, false, false, false)   : compute_mpls_hash();  /* MPLS大于10层标签 */
        //     (false, false, true, true, false, false)    : compute_eth_hash();   /* MPLS小于10层标签,且内层IP不存在 */
        // }
    }

    table ip_hash_value_compute {
        key = {
            hdr.ipv4.isValid() : exact;
            hdr.ipv6.isValid() : exact;
            hdr.inner_ipv4.isValid() : exact;
            hdr.inner_ipv6.isValid() : exact;
        }

        actions = {
            compute_ipv4_hash;
            compute_ipv6_hash;
            miss;
        }

        const default_action = miss;
        size = hash_compute_table_size;

        // const entries = {
        //     (true, false, false, false)               : compute_ipv4_hash();  /* 外层IPV4报文 */
        //     (false, true, false, false)               : compute_ipv6_hash();  /* 外层IPV6报文 */
        //     (false, false, true, false)               : compute_ipv4_hash();  /* MPLS标签小于等于四层,且内层IPV4存在 */
        //     (false, false, false, true)               : compute_ipv6_hash();  /* MPLS标签小于等于四层,且内层IPV6存在 */
        // }
    }

    apply {
        switch(no_ip_hash_compute.apply().action_run) {
            miss:{
                ip_hash_value_compute.apply();
            }
        }
    }
}

//-----------------------------------------------------------------------------
// Link Aggregation (LAG) resolution
//-----------------------------------------------------------------------------
control LAG(
        inout switch_ingress_metadata_t ig_md,
        in bit<16> hash)(
        switch_uint32_t lag_table_size=512,
        switch_uint32_t mc_lag_max_entrys=5120) {

    const bit<32> lag_max_entrys = 5120; /* 128 * 32 or 64 * 64 */
    Hash<switch_uint16_t>(HashAlgorithm_t.IDENTITY) selector_hash;
    ActionSelector(lag_max_entrys,
                   selector_hash,
                   SelectorMode_t.FAIR) lag_selector;

    action load_balancing(switch_logic_port_t port, switch_device_t device) {
        ig_md.common.dst_port = port;
        ig_md.common.dst_device = device;
        ig_md.flags.lag_miss = 0x0; /* lag hit , flag = 0 */
    }

    action lag_miss() {
        ig_md.flags.lag_miss = 0x1; /* lag miss , flag = 1 */
    }

    @pragma selector_enable_scramble 0
    table global_lag {
        key = {
            ig_md.common.egress_eport : exact @name("eport");
            hash : selector;
        }

        actions = {
            load_balancing;
            lag_miss;
        }

        const default_action = lag_miss();
        size = lag_table_size;
        implementation = lag_selector;
    }
    apply {
        if (ig_md.common.egress_eport[15:15] == 1) {
            global_lag.apply();
        } else {
            ig_md.common.dst_device = ig_md.common.egress_eport[14 : 8];
            ig_md.common.dst_port = ig_md.common.egress_eport[7 : 0];
        }
    }
}

//-------------------------------------------------------------------------------------------------
// HASH 精进
//
// 本模块主要做HASH值的精进处理
//
// @param hdr
// @param ig_md
//-------------------------------------------------------------------------------------------------

control HASH_PRETREATMENT(
        inout switch_ingress_metadata_t ig_md
        )(
        switch_uint32_t lag_table_size=512,
        switch_uint32_t lag_max_entrys=512) {

    bit<16> temp_hash_id;
    bit<16> temp_hash_compare_id;
    Hash<bit<16>>(HashAlgorithm_t.IDENTITY) hash_16_pv;

    action load_balancing(bit<16> hash_id) {
        temp_hash_id = ig_md.common.hash & hash_id;
    }

    @stage(3)
    table lag_hash {
        key = {
            ig_md.common.egress_eport : exact @name("eport");
        }

        actions = {
            load_balancing;
        }
        size = lag_table_size;
    }

    action set_hash_compare(bit<16> mbrs) {
        temp_hash_compare_id = mbrs |-| temp_hash_id;
    }

    @stage(4)
    table hash_compare{
        key = {
            ig_md.common.egress_eport : exact @name("eport");
        }
        actions = {
            NoAction;
            set_hash_compare;
        }
        const default_action = NoAction;
        size = lag_table_size;
    }

    action set_new_hash() {
        ig_md.common.ap_hash = hash_16_pv.get(temp_hash_id);
    }

    action set_old_hash() {
        ig_md.common.ap_hash = ig_md.common.hash;
    }

    @stage(5)
    table hash_reseal{
        key = {
            temp_hash_compare_id : exact;
        }
        actions = {
            set_new_hash;
            set_old_hash;
        }
        /* 当前new_hash小于mbrs时执行覆盖hash值操作 */
        size = 256;
    }
    apply {
        if (ig_md.flags.imprv_lb_enable == 1w1) {
            lag_hash.apply();
        }
        if (ig_md.flags.imprv_lb_enable == 1w1) {
            hash_compare.apply();
        }
        hash_reseal.apply();
    }
}

//-------------------------------------------------------------------------------------------------
// uplink Pipe Inner hash offset
// 
// 本模块主要做LC->FE的端口偏移.
// 说明:
// 1、大象流均衡采用目的口偏移方式
// 2、端口均衡、逐流均衡采用源口偏移方式
//
// @param ig_md
//-------------------------------------------------------------------------------------------------

control IngressUplink_InnerHashOffset(
        in switch_header_t hdr,
        inout switch_ingress_metadata_t ig_md)(
        switch_uint32_t hash_switch_table_size=512) {

    /* 大象流均衡 */
    action elb_offset() {
        ig_md.common.hash = ig_md.common.sn + (bit<16>)ig_md.common.dst_port;
    }

    /* 端口均衡 */
    action plb_offset() {
        ig_md.common.hash = (bit<16>)ig_md.common.src_port;
    }

    /* 大象流均衡不做偏移 */
    action elb_no_offset() {
        ig_md.common.hash = ig_md.common.sn;
    }

    table inner_hash_offset {
        key = {
            ig_md.flags.plb_enable : exact;
            ig_md.flags.is_elephant : exact;
        }
        actions = {
            elb_offset;
            plb_offset;
            elb_no_offset;
            NoAction;
        }
        size = hash_switch_table_size;
    }
    apply {
        inner_hash_offset.apply();
    }
}

control IngressUplink_InnerHashOffset_Eop(
        in switch_header_t hdr,
        inout switch_ingress_metadata_t ig_md)(
        switch_uint32_t hash_switch_table_size=512) {

    /* 大象流均衡 */
    action elb_offset() {
        ig_md.common.hash = ig_md.common.sn + (bit<16>)ig_md.common.dst_port;
    }

    /* 大象流均衡不做偏移 */
    action elb_no_offset() {
        ig_md.common.hash = ig_md.common.sn;
    }

    table inner_hash_offset {
        actions = {
            elb_offset;
            elb_no_offset;
        }
        size = 1;
    }
    apply {
        if (hdr.fabric_base.pkt_type == FABRIC_PKT_TYPE_EOP) {
            inner_hash_offset.apply();
        }
    }
}


//-------------------------------------------------------------------------------------------------
// Fabric Pipe Inner hash offset
// 
// 本模块主要做LC->下行FPGA的端口偏移
// 说明:
// 端口均衡、大象流均衡、逐流均衡采用目的口偏移
//
// @param ig_md
//-------------------------------------------------------------------------------------------------

control IngressFabric_InnerHashOffset(
        inout switch_ingress_metadata_t ig_md)(
        switch_uint32_t hash_switch_table_size=512) {

    /* 去掉有phv问题,后续再去 */
    action crc_offset() {
        ig_md.common.sn = ig_md.common.hash + (bit<16>)ig_md.common.dst_port;
    }

    action crc_no_offset() {
        ig_md.common.sn = ig_md.common.hash;
    }

    /* 大象流均衡 */
    action elb_offset() {
        ig_md.common.sn = ig_md.common.sn + (bit<16>)ig_md.common.dst_port;
    }

    /* 端口均衡 */
    action plb_offset() {
        ig_md.common.sn = (bit<16>)ig_md.common.dst_port;
    }

    table inner_hash_offset {
        key = {
            ig_md.flags.plb_enable : exact;
            ig_md.flags.is_elephant : exact;
        }
        actions = {
            plb_offset;
            elb_offset;
            crc_offset;
            crc_no_offset;
        }
        size = hash_switch_table_size;
    }
    apply {
        inner_hash_offset.apply();
    }
}

//-------------------------------------------------------------------------------------------------
// Src-device LKP
//
// 本模块包含：
// 1、本卡device(对上体现为modid)的获取
// 2、大象流均衡开关(8CQ<->8CQ)、端口均衡的开关(40X<->40XS、40XS->8CQ)
// 
// 参数说明:1、当CLI开启大象流均衡, 则is_elephant为1,否则为0
//         2、当CLI开启端口均衡, 且本卡是40XS, 则plb_enable为1,否则为0
//
// @param ig_md
//-------------------------------------------------------------------------------------------------
control SourceLkp_Uplink(
    inout switch_ingress_metadata_t ig_md) {

    action set_src_device(bit<1> plb_enable, bit<1> is_elephant, bit<1> imprv_lb_enable) {
        ig_md.flags.plb_enable = plb_enable; /* port balance 开关 */
        ig_md.flags.is_elephant = is_elephant; /* elephant balance 开关 */
        ig_md.flags.imprv_lb_enable = imprv_lb_enable; /* Improve balance 开关(精进HASH) */
        ig_md.common.tmp_time = 0xffffffff + ig_md.common.timestamp_250ns; /* 用于时间戳翻转处理 */
    }

    table source_device {
        actions = {
            set_src_device;
        }
        size = 1;
    }

    apply {
        source_device.apply();
    }
}

//-------------------------------------------------------------------------------------------------
// Uplink Load Balance Mode 
//
// 本模块主要做负载均衡模式的选择, 包含:
// 8CQ大象流RR轮询均衡、端口映射均衡、普通逐流均衡.只有本卡是8CQ才下发.
//
// @param hdr
// @param ig_md
//-------------------------------------------------------------------------------------------------

control IngressLoadBalanceMode_Uplink (
        inout switch_ingress_metadata_t ig_md,
        inout switch_header_t hdr) {

    /* src_dev & dst_dev == CQ ? 1 : 0 */
    action drr_is_open(bit<1> drr_flag) {
        ig_md.flags.is_elephant = drr_flag;
    }

    action drr_is_close() {
        ig_md.flags.is_elephant = 1w0;
    }

    /* ----------------- 8CQ大象流开关 ---------------- */
    @stage(7)
    table drr_is_enable {
        key = {
            ig_md.common.dst_device : exact;
            ig_md.common.dst_port : exact;
        }
        actions = {
            drr_is_open;
            drr_is_close;
        }

        const default_action = drr_is_close;
        size = 512;
    }

    apply {
        if (hdr.fabric_base.is_mcast == 0 && ig_md.flags.escape_etm == 0 && ig_md.flags.is_elephant == 1) {
            drr_is_enable.apply();
        } else {
            ig_md.flags.is_elephant = 0;
        }
    }
}

//-------------------------------------------------------------------------------------------------
// Uplink Timestamp control
//
// 时间戳翻转处理
//
// @param hdr
// @param ig_md
//-------------------------------------------------------------------------------------------------
struct rr_reg0_metadata_t {
    bit<32> time;
}
control IngressTimeStamp_Uplink (
        inout switch_header_t hdr,
        inout switch_ingress_metadata_t ig_md,
        inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr) {

    Register<rr_reg0_metadata_t, bit<16>>(32w1024, {0}) rr_reg0;
    RegisterAction<rr_reg0_metadata_t, bit<16>, bit<32>>(rr_reg0) rr_reg0_action = {
        void apply(inout rr_reg0_metadata_t value, out bit<32> read_value){
            if (ig_md.common.timestamp_250ns < value.time) {
                read_value = ig_md.common.tmp_time - value.time; /* 时间发生翻转,时间差: 0xffffffff - old_time + timestamp */
            } else {
                read_value = ig_md.common.timestamp_250ns - value.time; /* 时间不翻转,时间差: timestamp - old_time */
            }

            value.time = ig_md.common.timestamp_250ns;
        }
    };

    action compute_time(bit<16> id) {
        ig_md.common.tmp_time = rr_reg0_action.execute(id);
    }

    table timestamp {
        key = {
            ig_md.common.dst_device : exact; /* 目的设备 */
            ig_md.common.dst_port : exact; /* 目的端口 */
            hdr.fabric_qos.tc : exact; /* TC */
        }
        actions = {
            compute_time;
        }
        size = 2048;
    }

    apply {
        if (hdr.fabric_base.is_mcast == 0 && ig_md.flags.escape_etm == 0 && ig_md.flags.is_elephant == 1) {
            timestamp.apply();
        }
    }
}

//-------------------------------------------------------------------------------------------------
// DRR Load Balance 
//
// 本模块主要做DRR负载均衡(每16KB封装一个SN)、小流处理
//
// @param hdr
// @param ig_md
// @param ig_intr_md_for_dprsr
//-------------------------------------------------------------------------------------------------

/* 报文统计结构 */
struct rr_reg1_metadata_t {
    bit<32> time;
    bit<32> buck_cap;
}

/* SN值统计结构 */
struct rr_reg2_metadata_t {
    bit<16> sn;
}

control IngressDRR_Uplink (
        inout switch_header_t hdr,
        inout switch_ingress_metadata_t ig_md,
        inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr) {

    const bit<32> TIME_T = 24*4; /* 时间差，24us = 24*4*250ns*/
    const bit<32> BUCK_SIZE = 256; /* 长度换算成节拍，16k/64=256 */
    const bit<16> SN_SIZE = 767; /* 最大的SN值 -1, 寄存器逻辑所致 */

    /* ----------------------------- 报文长度计数 ------------------------------- */
    Register<rr_reg1_metadata_t, bit<16>>(32w1024, {0, 0}) rr_reg1;
    RegisterAction<rr_reg1_metadata_t, bit<16>, bit<1>>(rr_reg1) rr_reg1_action = {
        void apply(inout rr_reg1_metadata_t value, out bit<1> read_value){
            /*当前报文与该sn内首包时间戳比，大于阈值，表示需要sn需要加1*/
            /*长度节拍超过256需要sn + 1*/
            if ((ig_md.common.tmp_time + value.time > TIME_T) || (value.buck_cap + (bit<32>)ig_md.common.pkt_length) > BUCK_SIZE) {
                value.time = 0; /*时间戳更新*/
                value.buck_cap = (bit<32>)ig_md.common.pkt_length;
                read_value = 1; /* SN需要加1 */
            } else {
                value.time = value.time + ig_md.common.tmp_time;
                value.buck_cap = value.buck_cap + (bit<32>)ig_md.common.pkt_length;
                read_value = 0; /* SN不需要加1 */
            }
        }
    };

    /* ----------------------------- SN值计数 ------------------------------- */
    Register<rr_reg2_metadata_t, bit<16>>(32w1024, {0}) rr_reg2; //时间条件，首包必然触发sn++，因此初始化为0
    RegisterAction<rr_reg2_metadata_t, bit<16>, bit<16>>(rr_reg2) rr_reg2_build_action = {
        void apply(inout rr_reg2_metadata_t value, out bit<16> read_value){
            /* SN + sn增加值 < 最大SN值 ? SN + sn增加值 : 1 */
            /* sn <= 767, 等效于 sn + 1 <= 768*/
            if (value.sn <= SN_SIZE) {
                value.sn = value.sn + 1; /* SN值不需要翻转 */
            } else {
                value.sn = 1; /* SN值需要翻转 */
            }
            read_value = value.sn;
        }
    };

    RegisterAction<rr_reg2_metadata_t, bit<16>, bit<16>>(rr_reg2) rr_reg2_read_action = {
        void apply(inout rr_reg2_metadata_t value, out bit<16> read_value){
            read_value = value.sn;
        }
    };

    /* ----------------------------- 队列映射 & 报文长度统计 ------------------------- */
    action build_queue(bit<16> id) {
        ig_md.flags.is_eop = rr_reg1_action.execute(id);
        ig_md.common.queue = id;
    }

    /* 根据Tc + Device + Port映射队列 */
    @stage(8)
    table queue_builder {
        key = {
            ig_md.common.dst_device : exact; /* 目的设备 */
            ig_md.common.dst_port : exact; /* 目的端口 */
            hdr.fabric_qos.tc : exact; /* TC */
        }
        actions = {
            build_queue;
        }

        size = 2048;
    }

    /* ----------------------------- SN生成器 ------------------------- */
    action build_sn() {
        ig_md.common.sn = rr_reg2_build_action.execute(ig_md.common.queue);
    }

    action read_sn() {
        ig_md.common.sn = rr_reg2_read_action.execute(ig_md.common.queue);
    }

    @stage(9)
    table sn_builder {
        key = {
            ig_md.flags.is_eop : exact; /* EOP标志 */
            ig_md.flags.is_elephant : exact; /* CQ to CQ类型? */
            ig_md.flags.plb_enable : exact; /* src_dev == 40XS? */
        }
        actions = {
            build_sn;
            read_sn;
            NoAction;
        }

        const entries = {
            (1, 1, 0) : build_sn; /* 大象流均衡, SN切换 */
            (0, 1, 0) : read_sn; /* 大象流均衡，SN保持 */
            (0, 0, 1) : NoAction; /* 端口均衡 */
            (0, 0, 0) : NoAction; /* 逐流均衡 */
        }

        size = 512;
    }

    apply {
        /* 队列映射给SN生成器ID -> 统计报文长度给SN加1标识 -> 更新SN值 */
        if (ig_md.flags.is_elephant == 1 && ig_md.flags.drop == 0) {
            queue_builder.apply();
        }
        if (ig_md.flags.drop == 0) {
            sn_builder.apply();
        }
    }
}

/* 计算报文长度 */
control IngressPktlength_Uplink (
        inout switch_header_t hdr,
        inout switch_ingress_metadata_t ig_md)
{
    action get_pktlen(bit<16> len) {
        ig_md.common.pkt_length = ig_md.common.pkt_length + len;
    }

    action get_ipv4_pktlen(bit<16> len) {
        ig_md.common.pkt_length = hdr.ipv4.total_len + len;
    }

    action get_ipv6_pktlen(bit<16> len) {
        ig_md.common.pkt_length = hdr.ipv6.payload_len + len;
    }

    table compute_length {
        key = {
            hdr.fabric_base.pkt_type : exact;
        }
        actions = {
            get_pktlen;
            get_ipv4_pktlen;
            get_ipv6_pktlen;
        }
        /* 报文类型为eth和mpls, 报文长度 = 原始报文长度 + 前导码8B + 帧间隙12B + CRC 4B + 63B（节拍换算）*/
        /* 报文类型为ipv4和ipv6, 报文长度 = 原始报文长度 + IP长度 + 前导码8B + 帧间隙12B + CRC 4B + 63B（节拍换算)*/
        size = 128;
    }

    apply {
        compute_length.apply();
    }
}

/* 计算报文节拍 */
control IngressPktBeat_Uplink (
        inout switch_header_t hdr,
        inout switch_ingress_metadata_t ig_md)
{
    action get_beat() {
        ig_md.common.pkt_length = ig_md.common.pkt_length >> 6;
    }

    table compute_beat {
        actions = {
            get_beat;
        }
        const default_action = get_beat;
        size = 1;
        /* beat = (length + 63)/64, 63在get_length已经补偿，这里只要右移6bit即可*/
    }

    apply {
        compute_beat.apply();
    }
}

//-------------------------------------------------------------------------------------------------
// Fabric Load Balance Mode 
//
// 本模块主要做负载均衡模式的选择, 包含:
// 端口映射均衡、普通逐流均衡
// 
// 参数说明:
// 当CLI开启端口均衡, 且本卡是40XS的时候, plb_enable为1,否则为0.
//
// @param hdr
// @param ig_md
//-------------------------------------------------------------------------------------------------
control IngressLoadBalanceMode_Fabric (
        inout switch_ingress_metadata_t ig_md,
        inout switch_header_t hdr) {

    /* ---------------- 40XS端口均衡开关 ----------------- */
    action port_balance_is_open(bit<1> flag) {
        ig_md.flags.plb_enable = flag; /* dst_dev == 40xs ? 1 : 0 */
    }

    table port_balance_is_enable {
        actions = {
            port_balance_is_open;
        }

        size = 1;
    }

    apply {
        if (hdr.fabric_base.is_mcast == 0 && ig_md.flags.escape_etm == 0) {
            port_balance_is_enable.apply();
        }
    }
}

//-------------------------------------------------------------------------------------------------
// GET PRE SN
//
// 本模块主要用于SN回退
//
// @param hdr
// @param ig_md
//-------------------------------------------------------------------------------------------------

control EgressPreSn_Uplink (
        inout switch_header_t hdr,
        inout switch_egress_metadata_t eg_md) {

    const bit<16> SN_SIZE = 768; /* 最大的SN值 */

    /* sn值减1 */
    action sn_sub_one() {
        eg_md.common.hash = eg_md.common.hash - 16w1;
    }

    /* sn值翻转 */
    action sn_to_max() {
        eg_md.common.hash = SN_SIZE;
    }

    table pre_sn {
        key = {
            eg_md.common.hash : exact; /* SN值 */
        }
        actions = {
            sn_sub_one;
            sn_to_max;
            NoAction;
        }

        const entries = {
            (0) : NoAction; /* SN为0,不做动作 */
            (1) : sn_to_max; /* SN为1时,翻转 */
        }

        const default_action = sn_sub_one;
        size = 128;
    }

    apply {
        if (eg_md.common.pkt_type == FABRIC_PKT_TYPE_EOP) {
            pre_sn.apply();
        }
    }
}
# 196 "/mnt/p4c-4127/p4src/switch-tofino2/switch_tofino_x1.p4" 2
/*by sutaomu*/
# 1 "/mnt/p4c-4127/p4src/shared/qos.p4" 1
/* qos by sutaomu
 * set in port qos properties
 * set in lif qos properties
 * qos map
 * traffic class
 * set out port qos properties
 * set out lif qos properties
 * qos remap
 */

control Decide_trust(
        inout switch_header_t hdr,
        inout switch_ingress_metadata_t ig_md) {

    action set_port_trust_auto(bit<3> trust) {
        ig_md.qos.lif_trust_mode = trust;
        ig_md.qos.lif_ds = ig_md.qos.port_ds;
    }

    action set_lif_trust_auto(bit<3> trust) {
        ig_md.qos.lif_trust_mode = trust;
    }

    action set_trust_by_lif() { }
    action set_trust_by_port() {
        ig_md.qos.lif_trust_mode = ig_md.qos.port_trust_mode;
        ig_md.qos.lif_ds = ig_md.qos.port_ds;
    }
    action set_trust_none() {
        ig_md.qos.lif_trust_mode = SWITCH_QOS_UNTRUSTED;
    }

    @stage(3)
    table set_qos_trust_mode_lif {
        key = {
            hdr.mpls_ig[0].isValid() : exact;
            hdr.ipv4.isValid() : exact;
            hdr.ipv6.isValid() : exact;
            hdr.vlan_tag[0].isValid() : exact;
            ig_md.qos.lif_trust_mode : exact;
        }
        actions = {
            set_port_trust_auto;
            set_lif_trust_auto;
            set_trust_by_lif;
            set_trust_by_port;
            set_trust_none;
            NoAction;
        }
        const default_action = NoAction;
        size = 128;
        // const entries = {
        //     (true, false, false, _, SWITCH_QOS_TRUST_AUTO) : set_trust_by_lif(SWITCH_QOS_TRUST_EXP);
        //     (false, true, false, _, SWITCH_QOS_TRUST_AUTO) : set_trust_by_lif(SWITCH_QOS_TRUST_DSCP);
        //     (false, false, true, _, SWITCH_QOS_TRUST_AUTO) : set_trust_by_lif(SWITCH_QOS_TRUST_DSCP);
        //     (true, false, false, _, SWITCH_QOS_TRUST_EXP) : set_trust_by_lif(SWITCH_QOS_TRUST_EXP);
        //     (false, true, false, _, SWITCH_QOS_TRUST_DSCP) : set_trust_by_lif(SWITCH_QOS_TRUST_DSCP);
        //     (false, false, true, _, SWITCH_QOS_TRUST_DSCP) : set_trust_by_lif(SWITCH_QOS_TRUST_DSCP);
        //     (false, true, false, _, SWITCH_QOS_TRUST_PRE) : set_trust_by_lif(SWITCH_QOS_TRUST_PRE);
        //     (false, false, true, _, SWITCH_QOS_TRUST_PRE) : set_trust_by_lif(SWITCH_QOS_TRUST_PRE);
        //     (_, _, _, true, SWITCH_QOS_TRUST_PCP) : set_trust_by_lif(SWITCH_QOS_TRUST_PCP);
        // }
    }

    @stage(3)
    table set_qos_trust_mode_port {
        key = {
            hdr.mpls_ig[0].isValid() : exact;
            hdr.ipv4.isValid() : exact;
            hdr.ipv6.isValid() : exact;
            hdr.vlan_tag[0].isValid() : exact;
            ig_md.qos.port_trust_mode : exact;
        }
        actions = {
            set_port_trust_auto;
            set_lif_trust_auto;
            set_trust_by_lif;
            set_trust_by_port;
            set_trust_none;
        }
        const default_action = set_trust_none();
        size = 128;
        // const entries = {
        //     (true, false, false, _, SWITCH_QOS_TRUST_AUTO) : set_trust_by_port(SWITCH_QOS_TRUST_EXP);
        //     (false, true, false, _, SWITCH_QOS_TRUST_AUTO) : set_trust_by_port(SWITCH_QOS_TRUST_DSCP);
        //     (false, false, true, _, SWITCH_QOS_TRUST_AUTO) : set_trust_by_port(SWITCH_QOS_TRUST_DSCP);
        //     (true, false, false, _, SWITCH_QOS_TRUST_EXP) : set_trust_by_port(SWITCH_QOS_TRUST_EXP);
        //     (false, true, false, _, SWITCH_QOS_TRUST_DSCP) : set_trust_by_port(SWITCH_QOS_TRUST_DSCP);
        //     (false, false, true, _, SWITCH_QOS_TRUST_DSCP) : set_trust_by_port(SWITCH_QOS_TRUST_DSCP);
        //     (false, true, false, _, SWITCH_QOS_TRUST_PRE) : set_trust_by_port(SWITCH_QOS_TRUST_PRE);
        //     (false, false, true, _, SWITCH_QOS_TRUST_PRE) : set_trust_by_port(SWITCH_QOS_TRUST_PRE);
        //     (_, _, _, true, SWITCH_QOS_TRUST_PCP) : set_trust_by_port(SWITCH_QOS_TRUST_PCP);
        // }
    }
    apply {
        switch(set_qos_trust_mode_lif.apply().action_run) {
            NoAction:{
                set_qos_trust_mode_port.apply();
            }
        }
    }
}

control protocol_diffserv(
        inout switch_header_t hdr,
        inout switch_ingress_metadata_t ig_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm) {

    action set_qid(switch_qid_t qid) {
        ig_intr_md_for_tm.qid = qid;
    }

    table protocol_tc {
        key = {
            hdr.ethernet.isValid() : exact;
            ig_md.common.ether_type : ternary;
            hdr.ethernet.dst_addr : ternary;
        }
        actions = {
            set_qid;
            NoAction;
        }
        size = 128;
        const default_action = NoAction;

    }

    apply {
        if (ig_md.qos.is_auto_trust == 1) {
            protocol_tc.apply();
        }
    }
}

control IngressQoS(
        inout switch_header_t hdr,
        inout switch_ingress_metadata_t ig_md)
        (switch_uint32_t dscp_map_size = 2048,
        switch_uint32_t pcp_map_size = 256,
        switch_uint32_t exp_map_size = 256,
        switch_uint32_t pre_map_size = 256) {

    action set_tc(switch_tc_t tc) {
        ig_md.qos.tc = tc;
        ig_md.qos.BA = 1;
    }

    action set_pkt_color(switch_pkt_color_t color) {
        ig_md.qos.color = color;
        ig_md.qos.BA = 1;
    }

    action set_tc_and_color(switch_tc_t tc, switch_pkt_color_t color) {
        set_tc(tc);
        set_pkt_color(color);
    }

    action dscp_set_tc(switch_tc_t tc) {
        ig_md.qos.tc = tc;
        ig_md.qos.BA = 1;
        ig_md.qos.chgDSCP_disable = 1;
    }

    action dscp_set_pkt_color(switch_pkt_color_t color) {
        ig_md.qos.color = color;
        ig_md.qos.BA = 1;
        ig_md.qos.chgDSCP_disable = 1;
    }

    action dscp_set_tc_and_color(switch_tc_t tc, switch_pkt_color_t color) {
        set_tc(tc);
        set_pkt_color(color);
        ig_md.qos.chgDSCP_disable = 1;
    }
    @stage(4)
    table dscp_tc_map {
        key = {
            ig_md.lkp.ip_tos[7:2] : exact;
            ig_md.qos.lif_ds : exact;
        }
        actions = {
            dscp_set_tc;
            dscp_set_pkt_color;
            dscp_set_tc_and_color;
        }
        size = dscp_map_size;
    }

    @stage(4)
    table ippre_tc_map {
        key = {
            ig_md.lkp.ip_tos[7:5] : exact;
            ig_md.qos.lif_ds : exact;
        }
        actions = {
            set_tc;
            set_pkt_color;
            set_tc_and_color;
        }
        size = pre_map_size;
    }

    @stage(4)
    table pcp_tc_map {
        key = {
            hdr.vlan_tag[0].pcp : exact;
            ig_md.qos.lif_ds : exact;
        }
        actions = {
            set_tc;
            set_pkt_color;
            set_tc_and_color;
        }
        size = pcp_map_size;
    }

    @stage(4)
    table exp_tc_map {
        key = {
            // ig_md.lkp.mpls_exp : exact;
            hdr.mpls_ig[0].exp : exact;
            ig_md.qos.lif_ds : exact;
        }
        actions = {
            set_tc;
            set_pkt_color;
            set_tc_and_color;
        }
        size = exp_map_size;
    }

    action vpn_set_tc_color() {
        ig_md.qos.tc = ig_md.qos.tc_tmp;
        ig_md.qos.color = ig_md.qos.color_tmp;
    }

    @placement_priority(127)
    table vpn_tc_set {
        key = {
            ig_md.qos.BA : exact;
        }
        actions = {
            vpn_set_tc_color;
            NoAction;
        }
        const entries = {
            (0) : NoAction();
            (1) : vpn_set_tc_color();
        }
        size = 16;
    }

    apply {

        if (ig_md.qos.BA == 1) {
            vpn_tc_set.apply();
        } else if(ig_md.qos.BA == 0) {
            if (ig_md.qos.lif_trust_mode == SWITCH_QOS_TRUST_EXP ) {
                exp_tc_map.apply();
            } else if (ig_md.qos.lif_trust_mode == SWITCH_QOS_TRUST_DSCP ) {
                dscp_tc_map.apply();
            } else if (ig_md.qos.lif_trust_mode == SWITCH_QOS_TRUST_PRE ) {
                ippre_tc_map.apply();
            } else if (ig_md.qos.lif_trust_mode == SWITCH_QOS_TRUST_PCP ) {
                pcp_tc_map.apply();
            }
        }

    }
}


control Decide_ds_phb(inout switch_egress_metadata_t eg_md) {

    action set_ds_from_lif() { }
    action set_ds_from_lif_tmp() { }
    action set_ds_from_port() {
        eg_md.qos.lif_ds = eg_md.qos.port_ds;
        eg_md.qos.lif_PHB = eg_md.qos.port_PHB;
    }
    action set_ds_from_port_tmp() {
        eg_md.qos.lif_ds = eg_md.qos.port_ds;
        eg_md.qos.lif_PHB = eg_md.qos.port_PHB;
    }
    table set_final_ds {
        key = {
            eg_md.qos.port_PHB : exact;
            eg_md.qos.lif_PHB : exact;
        }
        actions = {
            set_ds_from_port;
            set_ds_from_lif;
            set_ds_from_port_tmp;
            set_ds_from_lif_tmp;
        }
        size = 16;
        const entries = {
            (0, 0) : set_ds_from_port();
            (1, 0) : set_ds_from_port_tmp();
            (0, 1) : set_ds_from_lif();
            (1, 1) : set_ds_from_lif_tmp();
        }
    }

    apply {
        if (eg_md.qos.is_pipe == 0) {
            set_final_ds.apply();
        }
    }
}


control EgressQoS(
        inout switch_header_t hdr,
        inout switch_egress_metadata_t eg_md)
        (switch_uint32_t table_size = 1024) {

    action set_pcp(bit<3> pcp) {
        eg_md.qos.pcp = pcp;
    }

    table pcp_remap {
        key = {
            eg_md.qos.tc : exact ;
            eg_md.qos.color : exact ;
            eg_md.qos.lif_ds : exact;
        }
        actions = {
            set_pcp;
        }
        size = table_size;
    }

    action set_dscp(bit<6> dscp) {
        eg_md.qos.dscp = dscp;
    }

    table dscp_remap {
        key = {
            eg_md.qos.tc : exact ;
            eg_md.qos.color : exact ;
            eg_md.qos.lif_ds : exact;
        }
        actions = {
            set_dscp;
        }
        size = table_size;
    }

    // action set_ippre(bit<3> ippre) {
    //     eg_md.qos.ippre = ippre;
    // }

    // table ippre_remap {
    //     key = {
    //         eg_md.qos.tc : exact ;
    //         eg_md.qos.color : exact ;
    //         eg_md.qos.final_ds : exact;
    //     }
    //     actions = {
    //         NoAction;
    //         set_ippre;
    //     }
    //     const default_action = NoAction;
    //     size = table_size;
    // }

    action set_exp(bit<3> exp) {
        eg_md.tunnel.exp = exp;
        eg_md.tunnel.qosphb = 1;
    }

    action set_defaultexp(bit<3> exp) {
        eg_md.tunnel.exp = exp;
    }

    table exp_remap {
        key = {
            eg_md.qos.tc : exact ;
            eg_md.qos.color : exact ;
            eg_md.qos.lif_ds : exact;
        }
        actions = {
            set_exp;
        }
        size = table_size;
    }

    table default_exp_remap {
        key = {
            eg_md.qos.tc : exact;
        }
        actions = {
            set_defaultexp;
        }
        const entries = {
            (0) : set_defaultexp(0);
            (1) : set_defaultexp(1);
            (2) : set_defaultexp(2);
            (3) : set_defaultexp(3);
            (4) : set_defaultexp(4);
            (5) : set_defaultexp(5);
            (6) : set_defaultexp(6);
            (7) : set_defaultexp(7);
        }
        size = 16;
    }

    apply {
        if (eg_md.qos.BA == 1 && eg_md.qos.lif_PHB == 1) {
            exp_remap.apply();
            pcp_remap.apply();
            // ippre_remap.apply();
            dscp_remap.apply();
        } else {
            default_exp_remap.apply();
        }
    }
}


control Modify_Hdr_Cos(inout switch_header_t hdr,
                  inout switch_egress_metadata_t eg_md)(
                  switch_uint32_t table_size = 16) {

    action qos_set_inner_v4_dscp() {
        hdr.inner_ipv4.diffserv[7:2] = eg_md.qos.dscp;
    }
    action qos_set_inner_v6_dscp() {
        hdr.inner_ipv6.traffic_class[7:2] = eg_md.qos.dscp;
    }
    action set_mpls_exp() {
        hdr.mpls_vc_eg.exp = eg_md.tunnel.exp;
    }
    // MPLS报文没有解析到IP，可以放一起处理
    table set_cos {
        key = {
            hdr.mpls_vc_eg.isValid() : exact;
            hdr.inner_ipv4.isValid() : exact;
            hdr.inner_ipv6.isValid() :exact;
            eg_md.qos.chgDSCP_disable : exact; //add by lichunfeng
        }
        actions = {
            qos_set_inner_v4_dscp;
            qos_set_inner_v6_dscp;
            set_mpls_exp;

        }
        const entries = {
            (true, false, false, 0) : set_mpls_exp();
            (true, false, false, 1) : set_mpls_exp();
            (false, true, false, 0) : qos_set_inner_v4_dscp();
            (false, false, true, 0) : qos_set_inner_v6_dscp();
        }
        size = 16;
    }

    action set_vlan_pcp() {
        hdr.inner_vlan_tag[0].pcp = eg_md.qos.pcp;
    }
    table set_tag_pcp {
        key = {
            hdr.inner_vlan_tag[0].isValid() : exact;
        }
        actions = {
            NoAction;
            set_vlan_pcp;
        }
        const default_action = NoAction;
        const entries = {
            (true) : set_vlan_pcp();
            (false) : NoAction();
        }
        size = 16;
    }

    apply {

        if (eg_md.qos.BA == 1 && eg_md.qos.lif_PHB == 1 &&
                    eg_md.tunnel.encap_type == SWITCH_TUNNEL_ENCAP_TYPE_NONE) {
            set_cos.apply();
        }

        if (eg_md.qos.BA == 1 && eg_md.qos.lif_PHB == 1 &&
                    eg_md.tunnel.encap_type == SWITCH_TUNNEL_ENCAP_TYPE_NONE) {
            set_tag_pcp.apply();
        }
    }
}

control Queue_SP(
        inout switch_ingress_metadata_t ig_md)
        (switch_uint32_t hqos_size = 32768,
        switch_uint32_t qos_size = 512) {

    action set_sp_flag(bit<1> sp_flag) {
        ig_md.qos.sp_flag = sp_flag;
    }
    table hqos_sp {
        key = {
            ig_md.qos.FQID[14:0] : exact;
        }
        actions = {
            set_sp_flag;
        }
        const default_action = set_sp_flag(0);
        size = hqos_size;
    }
    table qos_sp {
        key = {
            ig_md.qos.FQID[8:0] : exact;
        }
        actions = {
            set_sp_flag;
        }
        const default_action = set_sp_flag(0);
        size = qos_size;
    }

    apply {
        if (ig_md.qos.FQID[15:15] == 1) {
            hqos_sp.apply();
        } else {
            qos_sp.apply();
        }
    }
}

control Service_Class(
        inout switch_header_t hdr,
        inout switch_egress_metadata_t eg_md) {

    action set_v4_sc(switch_tc_t sc) {
        eg_md.common.service_class = sc;
    }
    table v4_sc_map {
        key = {
            hdr.ipv4.diffserv[7:2] : exact;
        }
        actions = {
            NoAction;
            set_v4_sc;
        }
        size = 128;
    }

    action set_v6_sc(switch_tc_t sc) {
        eg_md.common.service_class = sc;
    }
    table v6_sc_map {
        key = {
            hdr.ipv6.traffic_class[7:2] : exact;
        }
        actions = {
            NoAction;
            set_v6_sc;
        }
        size = 128;
    }

    apply{
        if (hdr.ipv4.isValid()) {
            v4_sc_map.apply();
        } else if (hdr.ipv6.isValid()) {
            v6_sc_map.apply();
        }
    }
}

control Get_Tos(
        inout switch_header_t hdr,
        inout switch_egress_metadata_t eg_md) {

    action set_tos_form_v4() {
        eg_md.lkp.ip_tos = hdr.ipv4.diffserv;
    }

    action set_tos_form_v6() {
        eg_md.lkp.ip_tos = hdr.ipv6.traffic_class;
    }
    table v4_v6_tos_map {
        key = {
            hdr.ipv4.isValid() : exact;
            hdr.ipv6.isValid() : exact;
        }
        actions = {
            NoAction;
            set_tos_form_v4;
            set_tos_form_v6;
        }
        size = 2;
        // const entries = {
        //     (true, false) : set_tos_form_v4();
        //     (false, true) : set_tos_form_v6();
        // }
    }
    apply{
        v4_v6_tos_map.apply();
    }
}
control Short_Pipe(
        inout switch_header_t hdr,
        inout switch_egress_metadata_t eg_md) {

    action set_trust(bit<3> trust) {
        eg_md.qos.trust_mode = trust;
    }

    table decide_trust {
        key = {
            eg_md.qos.trust_mode : exact;
            hdr.vlan_tag[0].isValid() : exact;
            hdr.ipv4.isValid() : exact;
            hdr.ipv6.isValid() : exact;
        }
        actions = {
            NoAction;
            set_trust;
        }
        size = 16;
        const entries = {
            (SWITCH_QOS_AUTO_TRUST, true, false, false) : set_trust(SWITCH_QOS_TRUST_PCP);
            (SWITCH_QOS_AUTO_TRUST, true, true, false) : set_trust(SWITCH_QOS_TRUST_PCP);
            (SWITCH_QOS_AUTO_TRUST, true, false, true) : set_trust(SWITCH_QOS_TRUST_PCP);

            (SWITCH_QOS_AUTO_TRUST, false, true, false) : set_trust(SWITCH_QOS_TRUST_DSCP);
            (SWITCH_QOS_AUTO_TRUST, false, false, true) : set_trust(SWITCH_QOS_TRUST_DSCP);

        }
    }

    action set_tc(switch_tc_t tc, bit<2> color) {
        eg_md.qos.tc = tc;
        eg_md.qos.color = color;
    }

    table dscp_tc_map {
        key = {
            eg_md.lkp.ip_tos[7:2] : exact;
            eg_md.qos.lif_ds : exact;
        }
        actions = {
            NoAction;
            set_tc;
        }
        size = 2048;
    }

    table pcp_tc_map {
        key = {
            hdr.vlan_tag[0].pcp : exact;
            eg_md.qos.lif_ds : exact;
        }
        actions = {
            NoAction;
            set_tc;
        }
        size = 512;
    }

    apply{
        decide_trust.apply();
        if (eg_md.qos.trust_mode == SWITCH_QOS_TRUST_DSCP) {
            dscp_tc_map.apply();
        } else if (hdr.vlan_tag[0].isValid() && eg_md.qos.trust_mode == SWITCH_QOS_TRUST_PCP) {
            pcp_tc_map.apply();
        }
    }
}

control Car_Pass_Stats(inout switch_egress_metadata_t eg_md) {

    Counter<bit<64>, bit<8>>(256, CounterType_t.PACKETS_AND_BYTES) car_pass_counter;

    action count() {
        car_pass_counter.count(eg_md.common.src_port);
    }
    table car_pass {
        key = {
            eg_md.qos.qppb_meter_color : exact;
        }
        actions = {
            NoAction;
            count;
        }
        // const entries = {
        //     (SWITCH_METER_COLOR_GREEN) : count();
        //     (SWITCH_METER_COLOR_YELLOW) : count();
        //     (SWITCH_METER_COLOR_RED) : NoAction();
        // }
        size = 4;
    }

    apply {
        car_pass.apply();
    }
}

control Traffic_front(
        inout switch_ingress_metadata_t ig_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm)
        (switch_uint32_t queue_table_size = 64) {

    action set_icos(switch_cos_t icos) {
        ig_intr_md_for_tm.ingress_cos = icos;
    }
    action set_queue(switch_qid_t qid) {
        ig_intr_md_for_tm.qid = qid;
    }
    action set_icos_and_queue(switch_cos_t icos, switch_qid_t qid) {
        set_icos(icos);
        set_queue(qid);
    }
    @stage(9)
    table traffic_class {
        key = {
            ig_md.qos.color : exact ;
            ig_md.qos.tc : exact ;
        }
        actions = {
            set_icos;
            set_queue;
            set_icos_and_queue;
        }
        size = queue_table_size;
    }

    apply{
        if (ig_intr_md_for_tm.qid == 0) {
            traffic_class.apply();
        }
    }
}

control Traffic_uplink(
        inout switch_ingress_metadata_t ig_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm)
        (switch_uint32_t queue_table_size = 64) {

    action set_icos(switch_cos_t icos) {
        ig_intr_md_for_tm.ingress_cos = icos;
    }
    action set_queue(switch_qid_t qid) {
        ig_intr_md_for_tm.qid = qid;
    }
    action set_icos_and_queue(switch_cos_t icos, switch_qid_t qid) {
        set_icos(icos);
        set_queue(qid);
    }
    table traffic_class {
        key = {
            ig_md.flags.is_elephant : exact ;
            ig_md.qos.color : exact ;
            ig_md.qos.tc : exact ;
        }
        actions = {
            set_icos;
            set_queue;
            set_icos_and_queue;
        }
        size = queue_table_size;
    }

    // table meter_queue {
    //     key = {
    //         ig_md.qos.color : exact ;
    //         ig_md.qos.tc : exact ;
    //     }
    //     actions = {
    //         NoAction;
    //         set_queue;
    //     }
    //     size = queue_table_size;
    // }

    apply{
        // if (ig_md.qos.queue_meter_flag == 1) {
        //     meter_queue.apply();
        // } else {
            traffic_class.apply();
        // }
    }
}

control Traffic_uplink_eop(
        in switch_header_t hdr,
        inout switch_ingress_metadata_t ig_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm)
        (switch_uint32_t queue_table_size = 64) {

    action set_icos(switch_cos_t icos) {
        ig_intr_md_for_tm.ingress_cos = icos;
    }
    action set_queue(switch_qid_t qid) {
        ig_intr_md_for_tm.qid = qid;
    }
    action set_icos_and_queue(switch_cos_t icos, switch_qid_t qid) {
        set_icos(icos);
        set_queue(qid);
    }
    table traffic_class {
        key = {
            ig_md.qos.color : exact ;
            ig_md.qos.tc : exact ;
        }
        actions = {
            set_icos;
            set_queue;
            set_icos_and_queue;
        }
        size = queue_table_size;
    }

    apply{
        if (hdr.fabric_base.pkt_type == FABRIC_PKT_TYPE_EOP) {
            traffic_class.apply(); // only elephant eop into qid 10~17
        }
    }
}

control Traffic_downlink(
        inout switch_ingress_metadata_t ig_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm)
        (switch_uint32_t queue_table_size = 64,
        switch_uint32_t port_table_size = 512) {

    action set_icos(switch_cos_t icos) {
        ig_intr_md_for_tm.ingress_cos = icos;
    }
    action set_queue(switch_qid_t qid) {
        ig_intr_md_for_tm.qid = qid;
    }
    action set_icos_and_queue(switch_cos_t icos, switch_qid_t qid) {
        set_icos(icos);
        set_queue(qid);
    }
    table traffic_class {
        key = {
            ig_md.qos.color : exact ;
            ig_md.qos.tc : exact ;
        }
        actions = {
            set_icos;
            set_queue;
            set_icos_and_queue;
        }
        size = queue_table_size;
    }

    table sfp_qid_map {
        key = {
            ig_md.common.dst_port : exact ;
        }
        actions = {
            NoAction;
            set_queue;
        }
        size = port_table_size;
    }

    apply{
        sfp_qid_map.apply();
        traffic_class.apply(); // 48SFP: traffic_class cover sfp_qid for cos6~7
    }
}

control Traffic_fabric(
        inout switch_ingress_metadata_t ig_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm)
        (switch_uint32_t queue_table_size = 512,
        switch_uint32_t port_table_size = 512) {

    action set_icos(switch_cos_t icos) {
        ig_intr_md_for_tm.ingress_cos = icos;
    }
    action set_queue(switch_qid_t qid) {
        ig_intr_md_for_tm.qid = qid;
    }
    action set_icos_and_queue(switch_cos_t icos, switch_qid_t qid) {
        set_icos(icos);
        set_queue(qid);
    }
    table traffic_class {
        key = {
            ig_md.flags.is_elephant : exact;
            ig_md.common.is_mcast : exact;
            ig_md.qos.color : exact;
            ig_md.qos.tc : exact;
        }
        actions = {
            set_icos;
            set_queue;
            set_icos_and_queue;
        }
        size = queue_table_size;
    }

    table sfp_qid_map {
        key = {
            ig_md.common.dst_port : exact ;
        }
        actions = {
            NoAction;
            set_queue;
        }
        size = port_table_size;
    }

    table meter_queue {
        key = {
            ig_md.qos.sp_flag : exact;
            ig_md.qos.color : exact ;
            ig_md.qos.tc : exact ;
        }
        actions = {
            NoAction;
            set_queue;
        }
        size = queue_table_size;
    }

     apply{
        if (ig_md.common.is_mirror == 1) {
            sfp_qid_map.apply(); // sfp mirror into qid 0~5
        } else if (ig_md.qos.queue_meter_flag == 1) {
            meter_queue.apply();
        } else {
            traffic_class.apply();
        }
     }
}
# 198 "/mnt/p4c-4127/p4src/switch-tofino2/switch_tofino_x1.p4" 2
# 1 "/mnt/p4c-4127/p4src/shared/meter.p4" 1
/**
 * port meter
 * 子接口 meter
 */
control In_LifMeter(
        inout switch_header_t hdr,
        inout switch_ingress_metadata_t ig_md)
        (switch_uint32_t lif_table_size = 16 * 1024) {

    Meter<bit<14>>(lif_table_size, MeterType_t.BYTES) meter;

    action drop() {}

    table check_acl_meter {
        key = {
            ig_md.qos.acl_meter_color : exact;
            ig_md.qos.drop_color : exact;
        }
        actions = {
            drop;
            @defaultonly NoAction;
        }
        size = 36;
        const default_action = NoAction();
        const entries = {
            // (SWITCH_METER_COLOR_GREEN , 0b000) : NoAction();
            // (SWITCH_METER_COLOR_YELLOW, 0b000) : NoAction();
            // (SWITCH_METER_COLOR_RED   , 0b000) : NoAction();
            (SWITCH_METER_COLOR_GREEN , 0b001) : drop();
            // (SWITCH_METER_COLOR_YELLOW, 0b001) : NoAction();
            // (SWITCH_METER_COLOR_RED   , 0b001) : NoAction();
            // (SWITCH_METER_COLOR_GREEN , 0b010) : NoAction();
            (SWITCH_METER_COLOR_YELLOW, 0b010) : drop();
            // (SWITCH_METER_COLOR_RED   , 0b010) : NoAction();
            (SWITCH_METER_COLOR_GREEN , 0b011) : drop();
            (SWITCH_METER_COLOR_YELLOW, 0b011) : drop();
            // (SWITCH_METER_COLOR_RED   , 0b011) : NoAction();
            // (SWITCH_METER_COLOR_GREEN , 0b100) : NoAction();
            // (SWITCH_METER_COLOR_YELLOW, 0b100) : NoAction();
            (SWITCH_METER_COLOR_RED , 0b100) : drop();
            (SWITCH_METER_COLOR_GREEN , 0b101) : drop();
            // (SWITCH_METER_COLOR_YELLOW, 0b101) : NoAction();
            (SWITCH_METER_COLOR_RED , 0b101) : drop();
            // (SWITCH_METER_COLOR_GREEN , 0b110) : NoAction();
            (SWITCH_METER_COLOR_YELLOW, 0b110) : drop();
            (SWITCH_METER_COLOR_RED , 0b110) : drop();
            (SWITCH_METER_COLOR_GREEN , 0b111) : drop();
            (SWITCH_METER_COLOR_YELLOW, 0b111) : drop();
            (SWITCH_METER_COLOR_RED , 0b111) : drop();
        }
    }

    action set_color_blind() {
        ig_md.qos.lif_meter_color = (bit<2>) meter.execute(index = ig_md.qos.lif_meter_index);
    }

    table lif_meter {
        key = {
            hdr.ipv4.isValid() : exact;
        }
        actions = {
            set_color_blind;
        }
        size = 2;
    }

    apply {
        if (check_acl_meter.apply().hit) {}
        else if (ig_md.qos.lif_meter_index != 0) {
            lif_meter.apply();
        }
    }
}

control Out_LifMeter(inout switch_header_t hdr,
        inout switch_egress_metadata_t eg_md)
        (switch_uint32_t lif_table_size = 16 * 1024) {

    Meter<bit<14>>(lif_table_size, MeterType_t.BYTES) meter;

    action drop() {}

    table check_acl_meter {
        key = {
            eg_md.qos.acl_meter_color : exact;
            eg_md.qos.drop_color : exact;
        }
        actions = {
            drop;
            @defaultonly NoAction;
        }
        size = 36;
        const default_action = NoAction();
        const entries = {
            // (SWITCH_METER_COLOR_GREEN , 0b000) : NoAction();
            // (SWITCH_METER_COLOR_YELLOW, 0b000) : NoAction();
            // (SWITCH_METER_COLOR_RED   , 0b000) : NoAction();
            (SWITCH_METER_COLOR_GREEN , 0b001) : drop();
            // (SWITCH_METER_COLOR_YELLOW, 0b001) : NoAction();
            // (SWITCH_METER_COLOR_RED   , 0b001) : NoAction();
            // (SWITCH_METER_COLOR_GREEN , 0b010) : NoAction();
            (SWITCH_METER_COLOR_YELLOW, 0b010) : drop();
            // (SWITCH_METER_COLOR_RED   , 0b010) : NoAction();
            (SWITCH_METER_COLOR_GREEN , 0b011) : drop();
            (SWITCH_METER_COLOR_YELLOW, 0b011) : drop();
            // (SWITCH_METER_COLOR_RED   , 0b011) : NoAction();
            // (SWITCH_METER_COLOR_GREEN , 0b100) : NoAction();
            // (SWITCH_METER_COLOR_YELLOW, 0b100) : NoAction();
            (SWITCH_METER_COLOR_RED , 0b100) : drop();
            (SWITCH_METER_COLOR_GREEN , 0b101) : drop();
            // (SWITCH_METER_COLOR_YELLOW, 0b101) : NoAction();
            (SWITCH_METER_COLOR_RED , 0b101) : drop();
            // (SWITCH_METER_COLOR_GREEN , 0b110) : NoAction();
            (SWITCH_METER_COLOR_YELLOW, 0b110) : drop();
            (SWITCH_METER_COLOR_RED , 0b110) : drop();
            (SWITCH_METER_COLOR_GREEN , 0b111) : drop();
            (SWITCH_METER_COLOR_YELLOW, 0b111) : drop();
            (SWITCH_METER_COLOR_RED , 0b111) : drop();
        }
    }

    action set_color_blind() {
        eg_md.qos.lif_meter_color = (bit<2>) meter.execute(index = eg_md.qos.lif_meter_index);
    }
    // @stage(4)
    //@placement_priority(128)
    table lif_meter {
        key = {
            hdr.inner_ipv4.isValid() : exact;
        }
        actions = {
            set_color_blind;
        }
        size = 2;
    }

    apply {
        if (check_acl_meter.apply().hit) {}
        else if (eg_md.qos.lif_meter_index != 0) {
            lif_meter.apply();
        }
    }
}

control In_PortMeter(
        inout switch_header_t hdr,
        inout switch_ingress_metadata_t ig_md)
        (switch_uint32_t table_size = 256) {

    Meter<bit<8>>(table_size, MeterType_t.BYTES) meter;

    action set_color_blind(bit<8> meter_id) {
        ig_md.qos.port_meter_color = (bit<2>) meter.execute(index = meter_id, color = (MeterColor_t)((bit<8>)ig_md.qos.lif_meter_color));
    }
    // action set_color_aware() {
    //     ig_md.qos.color = (bit<2>) meter.execute(ig_md.qos.port_meter_index, (bit<8>)ig_md.qos.color);
    // }
    table meter_index {
        key = {
            ig_md.common.src_port : exact;
        }
        actions = {
            set_color_blind;
            // set_color_aware;
        }
        size = table_size;
    }

    apply {

        if (ig_md.srv6.is_loopback == 0) {

            meter_index.apply();

        }

    }
}

control Out_PortMeter(
        inout switch_header_t hdr,
        inout switch_egress_metadata_t eg_md)
        (switch_uint32_t table_size = 256) {

    Meter<bit<8>>(table_size, MeterType_t.BYTES) meter;

    action set_color_blind(bit<8> meter_id) {
        eg_md.qos.port_meter_color = (bit<2>) meter.execute(index = meter_id, color = (MeterColor_t)((bit<8>)eg_md.qos.lif_meter_color));
    }
    // action set_color_aware() {
    //     eg_md.qos.color_tmp = (bit<2>) meter.execute(eg_md.qos.port_meter_index, (bit<8>)eg_md.qos.color_tmp);
    // }
    table meter_index {
        key = {
            eg_md.common.dst_port : exact;
        }
        actions = {
            set_color_blind;
            // set_color_aware;
        }
        size = table_size;
    }

    apply {
        meter_index.apply();
    }
}

control Out_MirrorPortMeter(
        inout switch_header_t hdr,
        inout switch_egress_metadata_t eg_md)
        (switch_uint32_t table_size = 256) {

    Meter<bit<8>>(table_size, MeterType_t.BYTES) meter;

    action set_color_blind(bit<8> meter_id) {
        eg_md.qos.port_meter_color = (bit<2>) meter.execute(index = meter_id);
    }
    // action set_color_aware() {
    //     eg_md.qos.color_tmp = (bit<2>) meter.execute(eg_md.qos.port_meter_index, (bit<8>)eg_md.qos.color_tmp);
    // }
    table meter_index {
        key = {
            eg_md.common.dst_port : exact;
        }
        actions = {
            set_color_blind;
            // set_color_aware;
        }
        size = table_size;
    }

    apply {
        meter_index.apply();
    }
}

control QueueMeter(
        inout switch_ingress_metadata_t ig_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm)
        (switch_uint32_t hqos_table_size = 16384,
        switch_uint32_t qos_table_size = 512) {

    Meter<bit<14>>(hqos_table_size, MeterType_t.BYTES) hqos_meter1;
    Meter<bit<14>>(hqos_table_size, MeterType_t.BYTES) hqos_meter2;
    Meter<bit<9>>(qos_table_size, MeterType_t.BYTES) qos_meter;

    action set_q_meter_idx() {
        ig_md.qos.hqos_meter_index = ig_md.qos.FQID[13:0];
        ig_md.qos.qos_meter_index = ig_md.qos.FQID[8:0];
    }

    table q_meter_idx_get {
        key = {
            ig_md.qos.FQID[15:14] : exact;
        }
        actions = {
            set_q_meter_idx;
            NoAction;
        }
        const default_action = set_q_meter_idx();
        size = 4;
    }

    action set_hqos_low_color() {
        ig_md.qos.color = (bit<2>) hqos_meter1.execute(index = ig_md.qos.hqos_meter_index);
        ig_md.qos.queue_meter_flag = 1;
    }
    // key下 0b10
    table hqos_car_low {
        key = {
            ig_md.qos.FQID[15:14] : exact;
        }
        actions = {
            set_hqos_low_color;
            NoAction;
        }
        const default_action = NoAction;
        size = 4;
    }

    action set_hqos_high_color() {
        ig_md.qos.color = (bit<2>) hqos_meter2.execute(index = ig_md.qos.hqos_meter_index);
        ig_md.qos.queue_meter_flag = 1;
    }
    // key下 0b11
    // @ignore_table_dependency("Ig_fabric.queue_meter.qos_car")
    table hqos_car_high {
        key = {
            ig_md.qos.FQID[15:14] : exact;
        }
        actions = {
            set_hqos_high_color;
            NoAction;
        }
        const default_action = NoAction;
        size = 4;
    }

    apply {
        q_meter_idx_get.apply();
        hqos_car_low.apply();
        hqos_car_high.apply();
    }
}

control AclMeter_In(
        inout switch_header_t hdr,
        inout switch_ingress_metadata_t ig_md)
        (switch_uint32_t table_size = 16 * 1024) {

    Meter<bit<14>>(table_size, MeterType_t.BYTES) meter;

    action class_mode(bit<14> meter_id) {
        ig_md.qos.acl_meter_index = meter_id;
        // ig_md.qos.acl_meter_color = (bit<2>) meter.execute(meter_id);
    }
    action ace_mode() {
        ig_md.qos.acl_meter_color = (bit<2>) meter.execute(ig_md.qos.acl_meter_index);
    }
    @placement_priority(126)
    table class_meter {
        key = {
            ig_md.qos.acl_meter_index : exact;
            ig_md.common.ul_iif : exact;
        }
        actions = {
            @defaultonly NoAction;
            class_mode;
        }
        size = 20 * 1024;
        const default_action = NoAction();
    }

    table class_meter_back {
        key = {
            ig_md.qos.acl_meter_index : ternary;
            ig_md.common.ul_iif : ternary;
        }
        actions = {
            NoAction;
            class_mode;
        }
        size = 512;
        default_action = class_mode(0);
    }

    // @placement_priority(126)
    @stage(7)
    table ace_meter {
        actions = {
            ace_mode;
        }
        default_action = ace_mode();
    }

    apply {
        if (ig_md.qos.ace_mode == 0) {
            if (!class_meter.apply().hit) {
                class_meter_back.apply();
            }
        }
        ace_meter.apply();
    }
}

// No use
control QppbMeter_In(
        inout switch_header_t hdr,
        inout switch_ingress_metadata_t ig_md)
        (switch_uint32_t table_size = 256) {

    Meter<bit<8>>(table_size, MeterType_t.BYTES) meter;

    action set_color_blind() {
        ig_md.qos.qppb_meter_color = (bit<2>) meter.execute(ig_md.qos.qppb_meter_index);
    }
    // action set_color_aware() {
    //     ig_md.qos.qppb_meter_color = (bit<2>) meter.execute(ig_md.qos.qppb_meter_index,(bit<8>)ig_md.qos.color);
    // }
    table meter_index {
        key = {
            ig_md.qos.qppb_meter_index : exact;
        }
        actions = {
            set_color_blind;
            // set_color_aware;
        }
        size = table_size;

    }

    apply {
        meter_index.apply();
    }
}

// No use
control QppbMeter_Out(
        inout switch_header_t hdr,
        inout switch_egress_metadata_t eg_md)
        (switch_uint32_t table_size = 256) {

    Meter<bit<8>>(table_size, MeterType_t.BYTES) meter;

    action set_color_blind() {
        eg_md.qos.qppb_meter_color = (bit<2>) meter.execute(eg_md.qos.qppb_meter_index);
    }
    // action set_color_aware() {
    //     eg_md.qos.qppb_meter_color = (bit<2>) meter.execute(eg_md.qos.qppb_meter_index,(bit<8>)eg_md.qos.color);
    // }
    // @placement_priority(127)
    table meter_index {
        key = {
            eg_md.qos.qppb_meter_index : exact;
        }
        actions = {
            set_color_blind;
            // set_color_aware;
        }
        size = table_size;
    }

    apply {
        meter_index.apply();
    }
}

/* No use, meter decided in system acl */
control Meter_decide_In(
        inout switch_ingress_metadata_t ig_md,
        inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr) {

    Counter<bit<32>, bit<14>>(16 * 1024, CounterType_t.PACKETS) meter_stats;

    action forward() { }
    action drop() {
        // ig_intr_md_for_dprsr.drop_ctl = 0x1;
        ig_md.qos.car_flag = 1; // will drop in acl_uplink_eg
        meter_stats.count(ig_md.common.ul_iif);
    }
    table meter_result {
        key = {
            // ig_md.qos.port_meter_color : ternary;
            ig_md.qos.lif_meter_color : ternary;
            ig_md.qos.acl_meter_color : ternary;
            ig_md.qos.drop_color : ternary;
        }
        actions = {
            drop;
            forward;
        }
        const default_action = forward();
    }

    apply {
        meter_result.apply();
    }
}

control CQ2XS_SFPMeter_Uplink(
        inout switch_ingress_metadata_t ig_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm) {

    Meter<bit<12>>(4096, MeterType_t.BYTES) meter;

    action set_color_blind(bit<12> index) {
        ig_md.qos.color = (bit<2>) meter.execute(index);
        ig_md.qos.queue_meter_flag = 1;
    }

    table cq2xs_sfp_meter {
        key = {
            ig_md.common.dst_device : exact;
            ig_md.common.dst_port : exact;
            ig_md.qos.tc : exact;
        }
        actions = {
            set_color_blind;
        }
        size = 8192;
    }

    apply {
        cq2xs_sfp_meter.apply();
    }
}

control CQ2XS_SFPMeter_Fabric(
        inout switch_ingress_metadata_t ig_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm) {

    Meter<bit<12>>(4096, MeterType_t.BYTES) meter;

    action set_color_blind(bit<12> index) {
        ig_md.qos.color = (bit<2>) meter.execute(index);
        ig_md.qos.queue_meter_flag = 1;
    }

    table cq2xs_sfp_meter {
        key = {
            ig_md.common.dst_device : exact;
            ig_md.common.dst_port : exact;
            ig_md.qos.tc : exact;
        }
        actions = {
            set_color_blind;
        }
        size = 8192;
    }

    apply {
        cq2xs_sfp_meter.apply();
    }
}
# 199 "/mnt/p4c-4127/p4src/switch-tofino2/switch_tofino_x1.p4" 2
# 1 "/mnt/p4c-4127/p4src/shared/tm.p4" 1
/* TM by zhuanghui */
/* pipline-0-Engress */
/* 子接口+优先级映射*/
/* port+tc map */
control HQoSCount(
        inout switch_header_t hdr,
        inout switch_ingress_metadata_t ig_md)
        (switch_uint32_t table_size = 32768) {

    Counter<bit<64>, bit<15>>(table_size, CounterType_t.PACKETS_AND_BYTES) hqos_normal_counter;

    action hqos_normal_add() {
        hqos_normal_counter.count(hdr.fabric_unicast_ext_eg.FQID[14:0]);
    }
    // @stage(7)
    table hqos_normal_stats {
        key = {
            hdr.fabric_unicast_ext_eg.isValid() : exact;
            hdr.fabric_unicast_ext_eg.FQID[15:15] : exact;
        }
        actions = {
            hqos_normal_add;
        }
        size = 4;
    }

    apply {
        if (ig_md.common.pkt_type != FABRIC_PKT_TYPE_FPGA_DROP && ig_md.common.pkt_type != FABRIC_PKT_TYPE_FPGA_PAUSE) {
            hqos_normal_stats.apply();
        }
    }
}

control QoSCount(
        inout switch_header_t hdr,
        inout switch_ingress_metadata_t ig_md)
        (switch_uint32_t table_size = 512) {

    Counter<bit<64>, bit<9>>(table_size, CounterType_t.PACKETS_AND_BYTES) qos_normal_counter;

    action qos_normal_add(bit<9> qos_id) {
        qos_normal_counter.count(qos_id);
    }
    table qos_normal_stats {
        key = {
            ig_md.common.dst_port : exact;
            ig_md.qos.tc : exact;
        }
        actions = {
            qos_normal_add;
        }
        size = table_size;
    }

    apply {
        if (ig_md.common.pkt_type != FABRIC_PKT_TYPE_FPGA_DROP && ig_md.common.pkt_type != FABRIC_PKT_TYPE_FPGA_PAUSE) {
            qos_normal_stats.apply();
        }
    }
}

struct switch_byte_count_t {
    bit<32> hi;
    bit<32> lo;
}

control IgDropLenSub(inout switch_header_t hdr, inout switch_ingress_metadata_t ig_md) {

    action len_sub() {
        ig_md.qos.len_sub1 = 0xffffffff - hdr.drop_msg[0].len;
        ig_md.qos.len_sub2 = 0xffffffff - hdr.drop_msg[1].len;
    }
    table hqos_drop_len_sub {
        key = {
            hdr.drop_msg[0].isValid() : exact;
            hdr.drop_msg[1].isValid() : exact;
        }
        actions = {
            NoAction;
            len_sub;
        }
        // const entries = {
        //     (true, true) : len_sub();
        //     (false, false) : NoAction();
        // }
        size = 4;
    }
    apply {
        hqos_drop_len_sub.apply();
    }
}

control IgHQoSDropPkt1(
        inout switch_header_t hdr,
        inout switch_ingress_metadata_t ig_md)
        (switch_uint32_t table_size = 32768) {

    Counter<bit<64>, bit<15>>(table_size, CounterType_t.PACKETS) hqos_drop_pkt_reg1;

    action hqos_drop_pkt_add1() {
        hqos_drop_pkt_reg1.count(ig_md.qos.drop_fqid1);
    }
    @stage(0)
    table hqos_drop_pkt_stats1 {
        key = {
            hdr.drop_msg[0].isValid() : exact;
            hdr.drop_msg[0].fqid[15:15] : exact;
        }
        actions = {
            hqos_drop_pkt_add1;
        }
        size = 4;
    }

    apply {
        hqos_drop_pkt_stats1.apply();
    }
}

control IgHQoSDropByte1(
        inout switch_header_t hdr,
        inout switch_ingress_metadata_t ig_md)
        (switch_uint32_t table_size = 32768) {

    Register<switch_byte_count_t, bit<15>>(table_size) hqos_drop_byte_reg1;
    RegisterAction<switch_byte_count_t, bit<15>, bit<1>>(hqos_drop_byte_reg1) hqos_drop_byte_act1 = {
        void apply(inout switch_byte_count_t reg) {
            if (reg.lo > ig_md.qos.len_sub1) {
                reg.hi = reg.hi + 1;
            }
            reg.lo = reg.lo + hdr.drop_msg[0].len;
        }
    };
    action hqos_drop_byte_add1() {
        hqos_drop_byte_act1.execute(ig_md.qos.drop_fqid1);
    }
    // @stage(5)
    table hqos_drop_byte_stats1 {
        key = {
            hdr.drop_msg[0].isValid() : exact;
            hdr.drop_msg[0].fqid[15:15] : exact;
        }
        actions = {
            hqos_drop_byte_add1;
        }
        size = 4;
    }

    apply {
        hqos_drop_byte_stats1.apply();
    }
}

control IgHQoSDropPkt2(
        inout switch_header_t hdr,
        inout switch_ingress_metadata_t ig_md)
        (switch_uint32_t table_size = 32768) {

    Counter<bit<64>, bit<15>>(table_size, CounterType_t.PACKETS) hqos_drop_pkt_reg2;

    action hqos_drop_pkt_add2() {
        hqos_drop_pkt_reg2.count(ig_md.qos.drop_fqid2);
    }
    @stage(0)
    table hqos_drop_pkt_stats2 {
        key = {
            hdr.drop_msg[1].isValid() : exact;
            hdr.drop_msg[1].fqid[15:15] : exact;
        }
        actions = {
            hqos_drop_pkt_add2;
        }
        size = 4;
    }

    apply {
        hqos_drop_pkt_stats2.apply();
    }
}

control IgHQoSDropByte2(
        inout switch_header_t hdr,
        inout switch_ingress_metadata_t ig_md)
        (switch_uint32_t table_size = 32768) {

    Register<switch_byte_count_t, bit<15>>(table_size) hqos_drop_byte_reg2;
    RegisterAction<switch_byte_count_t, bit<15>, bit<1>>(hqos_drop_byte_reg2) hqos_drop_byte_act2 = {
        void apply(inout switch_byte_count_t reg) {
            if (reg.lo > ig_md.qos.len_sub2) {
                reg.hi = reg.hi + 1;
            }
            reg.lo = reg.lo + hdr.drop_msg[1].len;
        }
    };
    action hqos_drop_byte_add2() {
        hqos_drop_byte_act2.execute(ig_md.qos.drop_fqid2);
    }
    // @stage(5)
    table hqos_drop_byte_stats2 {
        key = {
            hdr.drop_msg[1].isValid() : exact;
            hdr.drop_msg[1].fqid[15:15] : exact;
        }
        actions = {
            hqos_drop_byte_add2;
        }
        size = 4;
    }

    apply {
        hqos_drop_byte_stats2.apply();
    }
}

control IgQoSDropCount(
        inout switch_header_t hdr,
        inout switch_ingress_metadata_t ig_md)
        (switch_uint32_t table_size = 512) {

    Counter<bit<64>, bit<9>>(table_size, CounterType_t.PACKETS) qos_drop_pkt_reg1;

    action qos_drop_pkt_add1(bit<9> qos_id) {
        qos_drop_pkt_reg1.count(qos_id);
    }
    table qos_drop_pkt_stats1 {
        key = {
            hdr.drop_msg[0].port : exact;
            hdr.drop_msg[0].fqid[2:0] : exact;
        }
        actions = {
            NoAction;
            qos_drop_pkt_add1;
        }
        const default_action = NoAction;
        size = table_size;
    }

    Register<switch_byte_count_t, bit<9>>(table_size) qos_drop_byte_reg1;
    RegisterAction<switch_byte_count_t, bit<9>, bit<1>>(qos_drop_byte_reg1) qos_drop_byte_act1 = {
        void apply(inout switch_byte_count_t reg) {
            if (reg.lo > ig_md.qos.len_sub1) {
                reg.hi = reg.hi + 1;
            }
            reg.lo = reg.lo + hdr.drop_msg[0].len;
        }
    };
    action qos_drop_byte_add1(bit<9> qos_id) {
        qos_drop_byte_act1.execute(qos_id);
    }
    table qos_drop_byte_stats1 {
        key = {
            hdr.drop_msg[0].port : exact;
            hdr.drop_msg[0].fqid[2:0] : exact;
        }
        actions = {
            NoAction;
            qos_drop_byte_add1;
        }
        const default_action = NoAction;
        size = table_size;
    }

    Counter<bit<64>, bit<9>>(table_size, CounterType_t.PACKETS) qos_drop_pkt_reg2;

    action qos_drop_pkt_add2(bit<9> qos_id) {
        qos_drop_pkt_reg2.count(qos_id);
    }
    table qos_drop_pkt_stats2 {
        key = {
            hdr.drop_msg[1].port : exact;
            hdr.drop_msg[1].fqid[2:0] : exact;
        }
        actions = {
            NoAction;
            qos_drop_pkt_add2;
        }
        const default_action = NoAction;
        size = table_size;
    }

    Register<switch_byte_count_t, bit<9>>(table_size) qos_drop_byte_reg2;
    RegisterAction<switch_byte_count_t, bit<9>, bit<1>>(qos_drop_byte_reg2) qos_drop_byte_act2 = {
        void apply(inout switch_byte_count_t reg) {
            if (reg.lo > ig_md.qos.len_sub2) {
                reg.hi = reg.hi + 1;
            }
            reg.lo = reg.lo + hdr.drop_msg[1].len;
        }
    };
    action qos_drop_byte_add2(bit<9> qos_id) {
        qos_drop_byte_act2.execute(qos_id);
    }
    table qos_drop_byte_stats2 {
        key = {
            hdr.drop_msg[1].port : exact;
            hdr.drop_msg[1].fqid[2:0] : exact;
        }
        actions = {
            NoAction;
            qos_drop_byte_add2;
        }
        const default_action = NoAction;
        size = table_size;
    }

    apply {
        if (hdr.drop_msg[0].isValid()) {
            qos_drop_pkt_stats1.apply();
            qos_drop_byte_stats1.apply();
        }
        if (hdr.drop_msg[1].isValid()) {
            qos_drop_pkt_stats2.apply();
            qos_drop_byte_stats2.apply();
        }
    }
}

control DropMsgRecirc(
    inout switch_header_t hdr,
    inout switch_ingress_metadata_t ig_md,
    in ingress_intrinsic_metadata_t ig_intr_md,
    inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm,
    inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr) {

    action set_msg_recirc(switch_port_t port) {
        ig_intr_md_for_tm.bypass_egress = 1;
        ig_intr_md_for_tm.ucast_egress_port = port;
        ig_md.common.dev_port = port;
        hdr.drop_msg[0].setInvalid();
        hdr.drop_msg[1].setInvalid();
    }

    action set_msg_drop() {
        ig_intr_md_for_dprsr.drop_ctl = 0x1;
    }

    table drop_msg_recirc {
        key = {
            ig_md.common.pkt_type : exact;
            ig_intr_md.ingress_port : exact;
        }
        actions = {
            set_msg_recirc;
            set_msg_drop;
        }
        size = 16;
    }

    apply {
        drop_msg_recirc.apply();
    }
}

control Elephant_set_fqid(
        inout switch_ingress_metadata_t ig_md,
        inout switch_header_t hdr) {

    Hash<bit<16>>(HashAlgorithm_t.IDENTITY) elephant_fqid;

    action set_sbid(bit<4> sbid) {
        ig_md.common.sbid = sbid;
    }

    table dev_to_sbid_mapping {
        key = {
            ig_md.common.src_device : exact;
        }
        actions = {
            set_sbid;
        }
        size = 128;
        const default_action = set_sbid(0);
    }

    action set_elephant_fqid() {
        ig_md.qos.FQID = elephant_fqid.get({2w0 +++ ig_md.common.tmp_sn +++ ig_md.common.sbid});
    }

    table alephant_fqid {
        key = {
            ig_md.flags.is_elephant : exact;
        }
        actions = {
            set_elephant_fqid;
            NoAction;
        }
        size = 2;
        // const entries = {
        //     (1) : set_elephant_fqid;
        //     (0) : NoAction;
        // }
    }

    apply {
        dev_to_sbid_mapping.apply();
        alephant_fqid.apply();
    }
}

control Decide_HQos_Enb(inout switch_header_t hdr, inout switch_egress_metadata_t eg_md) {

    Hash<bit<16>>(HashAlgorithm_t.IDENTITY) lif_fqid;
    Hash<bit<16>>(HashAlgorithm_t.IDENTITY) port_fqid;

    action set_enb_from_lif() {
        eg_md.qos.FQID = lif_fqid.get({eg_md.qos.lif_hqos_enb +++ eg_md.qos.lif_base_qid +++ eg_md.qos.tc});
    }
    action set_enb_from_port() {
        eg_md.qos.FQID = port_fqid.get({eg_md.qos.port_hqos_enb +++ eg_md.qos.port_base_qid +++ eg_md.qos.tc});
    }
    table set_hqos_enb {
        key = {
            eg_md.qos.port_hqos_enb : exact;
            eg_md.qos.lif_hqos_enb : exact;
        }
        actions = {
            set_enb_from_port;
            set_enb_from_lif;
        }
        size = 16;
        // const entries = {
        //     (0, 0) : set_enb_from_port();
        //     (0, 1) : set_enb_from_lif();
        //     (1, 0) : set_enb_from_port();
        //     (1, 1) : set_enb_from_lif();
        // }
    }

    apply {
        if (eg_md.flags.is_elephant == 0) {
            set_hqos_enb.apply();
        }
    }
}

control Decide_HQos_Fabric(inout switch_ingress_metadata_t ig_md) {

    Hash<bit<16>>(HashAlgorithm_t.IDENTITY) lif_fqid;
    Hash<bit<16>>(HashAlgorithm_t.IDENTITY) port_fqid;

    action set_enb_from_lif(bit<1> enb) {
        ig_md.qos.FQID = lif_fqid.get({ig_md.qos.lif_hqos_enb +++ ig_md.qos.lif_base_qid +++ ig_md.qos.tc});
        ig_md.qos.fq_dlb_enb = enb;
    }
    action set_enb_from_port(bit<1> enb) {
        ig_md.qos.FQID = port_fqid.get({ig_md.qos.port_hqos_enb +++ ig_md.qos.port_base_qid +++ ig_md.qos.tc});
        ig_md.qos.fq_dlb_enb = enb;
    }
    table set_hqos_enb {
        key = {
            ig_md.qos.port_hqos_enb : exact;
            ig_md.qos.lif_hqos_enb : exact;
        }
        actions = {
            set_enb_from_port;
            set_enb_from_lif;
        }
        size = 16;
    }

    apply {
        set_hqos_enb.apply();
    }
}

control AdjPktLen(
    inout switch_header_t hdr,
    inout switch_egress_metadata_t eg_md) {

    action sub_byte(bit<16> sub) {
        eg_md.qos.to_be_sub = sub;
    }

    table adj_len {
        key = {
            eg_md.common.pkt_type : ternary;
            hdr.ext_l4_encap.isValid() : exact;
            hdr.ext_tunnel_decap.isValid() : exact;
            eg_md.common.is_from_cpu_pcie : ternary;
            eg_md.common.is_mirror : ternary;
            eg_md.common.is_mcast : ternary;
        }
        actions = {
            NoAction;
            sub_byte;
        }
        const default_action = NoAction;
        // const entries = {
               // CPU pcie
        //     (_, false, false, 1, 0, 0) : sub_byte(4);        
               // FLOOD ETH               
        //     (FABRIC_PKT_TYPE_ETH, false, false, 0, 0, 1) : sub_byte(4); 
        //     (FABRIC_PKT_TYPE_ETH, false, true, 0, 0, 1) : sub_byte(8); 
        //     (FABRIC_PKT_TYPE_ETH, true, false, 0, 0, 1) : sub_byte(8); 
        //     (FABRIC_PKT_TYPE_ETH, true, true, 0, 0, 1) : sub_byte(12); 
                // ETH UC
        //     (FABRIC_PKT_TYPE_ETH, true, true, 0, 0, 0) : sub_byte(16);      // FCS + ext_l4_encap + ext_tunnel_decap + postonepad
        //     (FABRIC_PKT_TYPE_ETH, false, true, 0, 0, 0) : sub_byte(12);     // FCS + ext_tunnel_decap + postonepad
        //     (FABRIC_PKT_TYPE_ETH, true, false, 0, 0, 0) : sub_byte(12);     // FCS + ext_l4_encap + postonepad
        //     (FABRIC_PKT_TYPE_ETH, false, false, 0, 0, 0) : sub_byte(8);     // FCS + postonepad
                // L3 MC 
        //     (FABRIC_PKT_TYPE_IPV4, false, false, _, _, 1) : sub_byte(18);
        //     (FABRIC_PKT_TYPE_IPV4, false, true, _, _, 1) : sub_byte(22);
        //     (FABRIC_PKT_TYPE_IPV6, false, false, _, _, 1) : sub_byte(18);
        //     (FABRIC_PKT_TYPE_IPV6, false, true, _, _, 1) : sub_byte(22);

                // OTHERS
        //     (_, true, true, _, _, _) : sub_byte(14);    // FCS + ext_l4_encap + ext_tunnel_decap
        //     (_, false, true, _, _, _) : sub_byte(10);    // FCS + ext_tunnel_decap
        //     (_, true, false, _, _, _) : sub_byte(10);    // FCS + ext_l4_encap
        //     (_, false, false, _, _, _) : sub_byte(6);   // FCS
        // }
        size = 128;
    }

    action do_sub() {
        eg_md.tunnel.payload_len = eg_md.tunnel.payload_len - eg_md.qos.to_be_sub;
        eg_md.common.pkt_length = eg_md.common.pkt_length - eg_md.qos.to_be_sub;
    }
    table sub_len {
        key = {
            eg_md.common.pkt_type : exact;
        }
        actions = {
            do_sub;
        }
        const default_action = do_sub();
        size = 2;
    }

    apply {
        adj_len.apply();
        sub_len.apply();
    }
}

control CheckPktLen(inout switch_egress_metadata_t eg_md) {

    action add_byte() {
        eg_md.qos.to_be_add = 16w60 |-| eg_md.common.pkt_length;
    }
    table check_64B {
        key = {
            eg_md.common.pkt_type : exact;
        }
        actions = {
            add_byte;
        }
        const default_action = add_byte();
        size = 2;
    }

    apply {
        check_64B.apply();
    }
}

control ITM_Uplink(
    inout switch_ingress_metadata_t ig_md,
    in ingress_intrinsic_metadata_t ig_intr_md,
    inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm)
    (switch_uint32_t itm_size = 256) {

    action set_redirect(switch_port_t port) {
        ig_intr_md_for_tm.ucast_egress_port = port;
        ig_intr_md_for_tm.bypass_egress = 1;
    }

    table itm_redirect {
        key = {
            ig_md.common.src_port : exact;
        }
        actions = {
            set_redirect;
            NoAction;
        }
        size = itm_size;
    }

    apply {
        itm_redirect.apply();
    }
}

control PauseFront(
        inout switch_header_t hdr,
        inout switch_ingress_metadata_t ig_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm) {

    action send_pause_to_fpga(switch_port_t port) {
        ig_intr_md_for_tm.bypass_egress = 1;
        ig_intr_md_for_tm.ucast_egress_port = port;
        ig_md.common.dev_port = port;
        ig_md.qos.tc = 7;
        hdr.ethernet.src_addr[7:0] = ig_md.common.src_port;
    }
    table redirect_pause {
        key = {
            hdr.ethernet.dst_addr : exact;
            hdr.ethernet.ether_type : exact;
            hdr.pause_info.code : exact;
            ig_md.common.src_port : exact;
        }
        actions = {
            NoAction;
            send_pause_to_fpga;
        }
        size = 128;
    }

    apply {

        if (ig_md.srv6.is_loopback == 0) {

            redirect_pause.apply();

        }

    }
}

struct lo_status_t {
    bit<32> limit;
    bit<32> last_hi;
}

control BackpushMirror(
        inout switch_header_t hdr,
        inout switch_egress_metadata_t eg_md,
        inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr)
        (switch_uint32_t table_size = 256) {

    action set_max(bit<32> gap) {
        eg_md.qos.backpush_gap = gap;
    }
    table backpush_max {
        // keyless
        actions = {
            set_max;
        }
        default_action = set_max(0);
        size = 1;
    }

    Register<bit<32>, bit<8>>(table_size) hi_check_reg;
    RegisterAction<bit<32>, bit<8>, bit<1>>(hi_check_reg) hi_check_act = {
        void apply(inout bit<32> reg, out bit<1> rv) {
            if (reg > 0 && (bit<32>)eg_md.qos.qdepth >= reg) {
                rv = 1;
            } else {
                rv = 0;
            }
        }
    };
    action check_hi() {
        eg_md.qos.q_hi_flag = hi_check_act.execute(eg_md.common.dst_port);
    }
    table hi_check {
        key = {
            eg_md.common.is_mirror : exact;
            eg_md.common.dst_port : exact;
        }
        actions = {
            check_hi;
            NoAction;
        }
        const default_action = NoAction;
        size = table_size;
    }

    Register<bit<32>, bit<8>>(table_size) cnt_check_reg;
    RegisterAction<bit<32>, bit<8>, bit<1>>(cnt_check_reg) cnt_check_act = {
        void apply(inout bit<32> reg, out bit<1> rv) {
            if (reg == 0 || reg >= eg_md.qos.backpush_gap) {
                reg = 1;
                rv = 1;
            } else {
                reg = reg + 1;
                rv = 0;
            }
        }
    };
    RegisterAction<bit<32>, bit<8>, bit<1>>(cnt_check_reg) cnt_reset_act = {
        void apply(inout bit<32> reg, out bit<1> rv) {
            reg = 0;
            rv = 0;
        }
    };
    action check_cnt() {
        eg_md.qos.q_hi_flag = cnt_check_act.execute(eg_md.common.dst_port);
    }
    action reset_cnt() {
        eg_md.qos.q_hi_flag = cnt_reset_act.execute(eg_md.common.dst_port);
    }
    table cnt_check {
        key = {
            eg_md.common.is_mirror : exact;
            eg_md.common.dst_port : exact;
            eg_md.qos.q_hi_flag : exact;
        }
        actions = {
            check_cnt;
            reset_cnt;
            NoAction;
        }
        const default_action = NoAction;
        size = table_size;
    }

    Register<lo_status_t, bit<8>>(table_size) lo_check_reg;
    RegisterAction<lo_status_t, bit<8>, bit<1>>(lo_check_reg) lo_check_act = {
        void apply(inout lo_status_t reg, out bit<1> rv) {
            if ((bit<32>)eg_md.qos.qdepth <= reg.limit && reg.last_hi == 1) {
                reg.last_hi = 0;
                rv = 1;
            } else {
                rv = 0;
            }
        }
    };
    RegisterAction<lo_status_t, bit<8>, bit<1>>(lo_check_reg) lo_set_act = {
        void apply(inout lo_status_t reg, out bit<1> rv) {
            reg.last_hi = 1;
            rv = 0;
        }
    };
    action check_lo() {
        eg_md.qos.q_lo_flag = lo_check_act.execute(eg_md.common.dst_port);
    }
    action set_lo() {
        eg_md.qos.q_lo_flag = lo_set_act.execute(eg_md.common.dst_port);
    }
    table lo_check {
        key = {
            eg_md.common.is_mirror : exact;
            eg_md.common.dst_port : exact;
            eg_md.qos.q_hi_flag : exact;
        }
        actions = {
            check_lo;
            set_lo;
            NoAction;
        }
        const default_action = NoAction;
        size = table_size;
    }

    action set_mirror_xoff() {
        eg_md.mirror.backpush_flag = 1;
        eg_md.common.backpush_dst_port = eg_md.common.dst_port;
    }
    action set_mirror_xon() {
        eg_md.mirror.backpush_flag = 2;
        eg_md.common.backpush_dst_port = eg_md.common.dst_port;
    }
    action clear_backpush() {
        eg_md.mirror.backpush_flag = 0;
        eg_md.common.backpush_dst_port = 0;
    }
    table backpush_mirror {
        key = {
            eg_md.qos.q_hi_flag : exact;
            eg_md.qos.q_lo_flag : exact;
        }
        actions = {
            clear_backpush;
            set_mirror_xoff;
            set_mirror_xon;
            NoAction;
        }
        const default_action = clear_backpush;
        size = 8;
    }

    apply {
        backpush_max.apply();
        hi_check.apply();
        cnt_check.apply();
        lo_check.apply();
        backpush_mirror.apply();
    }
}
# 200 "/mnt/p4c-4127/p4src/switch-tofino2/switch_tofino_x1.p4" 2
/* by lvlianlin */
# 1 "/mnt/p4c-4127/p4src/shared/acl_front.p4" 1
//-----------------------------------------------------------------------------
// Front Ingress ACL key.
//-----------------------------------------------------------------------------
# 27 "/mnt/p4c-4127/p4src/shared/acl_front.p4"
//-----------------------------------------------------------------------------
// Front Egress ACL key.
//-----------------------------------------------------------------------------
# 53 "/mnt/p4c-4127/p4src/shared/acl_front.p4"
//-----------------------------------------------------------------------------
// Common Front Ingress ACL actions.
//-----------------------------------------------------------------------------
# 86 "/mnt/p4c-4127/p4src/shared/acl_front.p4"
// Common Front Egress ACL actions.
//-----------------------------------------------------------------------------






control front_eg_ip_frag(in switch_header_t hdr, inout switch_egress_metadata_t eg_md) {

    action set_ip_proto() {
        eg_md.lkp.ip_proto = hdr.ipv6_frag.next_hdr;
    }

    table get_ip_frag {
        // keyless
        actions = {
            set_ip_proto;
        }
        default_action = set_ip_proto();
    }
    apply {
        if (hdr.ipv6_frag.isValid()) {
            get_ip_frag.apply();
        }
    }
}

// control front_ig_acl_key_sel(in switch_header_t hdr,
//                     inout switch_ingress_metadata_t ig_md,
//                     inout switch_ingress_policer_slice_t slice) {

//     action set_v4_group_classid_1() {
//         slice.group_classid = ig_md.policer.v4_group_classid_1;
//     }
//     action set_v4_group_classid_2() {
//         slice.group_classid = ig_md.policer.v4_group_classid_2;
//     }
//     action set_v4_group_classid_3() {
//         slice.group_classid = ig_md.policer.v4_group_classid_3;
//     }
//     action set_v4_group_classid_4() {
//         slice.group_classid = ig_md.policer.v4_group_classid_4;
//     }
//     action set_v6_group_classid_1() {
//         slice.group_classid = ig_md.policer.v6_group_classid_1;
//     }
//     action set_v6_group_classid_2() {
//         slice.group_classid = ig_md.policer.v6_group_classid_2;
//     }
//     action set_v6_group_classid_3() {
//         slice.group_classid = ig_md.policer.v6_group_classid_3;
//     }
//     action set_v6_group_classid_4() {
//         slice.group_classid = ig_md.policer.v6_group_classid_4;
//     }
//     table acl {
//         key = {
//             hdr.ipv4.isValid() : exact;
//             hdr.ipv6.isValid() : exact;
//             slice.group : exact;
//         }
//         actions = {
//             set_v4_group_classid_1;
//             set_v4_group_classid_2;
//             set_v4_group_classid_3;
//             set_v4_group_classid_4;
//             set_v6_group_classid_1;
//             set_v6_group_classid_2;
//             set_v6_group_classid_3;
//             set_v6_group_classid_4;
//         }
//         const entries = {
//             (true, false, SWITCH_ACL_BYPASS_1) : set_v4_group_classid_1();
//             (true, false, SWITCH_ACL_BYPASS_2) : set_v4_group_classid_2();
//             (true, false, SWITCH_ACL_BYPASS_3) : set_v4_group_classid_3();
//             (true, false, SWITCH_ACL_BYPASS_4) : set_v4_group_classid_4();
//             (false, true, SWITCH_ACL_BYPASS_1) : set_v6_group_classid_1();
//             (false, true, SWITCH_ACL_BYPASS_2) : set_v6_group_classid_2();
//             (false, true, SWITCH_ACL_BYPASS_3) : set_v6_group_classid_3();
//             (false, true, SWITCH_ACL_BYPASS_4) : set_v6_group_classid_4();
//         }
//         size = 8;
//     }

//     apply {
//         acl.apply();
//     }
// }

//-----------------------------------------------------------------------------
// Front Ingress Set Flowspec_disable
// ACL匹配前，对相关参数进行预计算
//-----------------------------------------------------------------------------
control front_ig_flowspec_disable (
            in switch_header_t hdr,
            inout switch_ingress_metadata_t ig_md) {

    action set_flowspec_disable_v4() {
        ig_md.flags.flowspec_disable = ig_md.flags.flowspec_disable_v4;
    }
    action set_flowspec_disable_v6() {
        ig_md.flags.flowspec_disable = ig_md.flags.flowspec_disable_v6;
    }
    action set_flowspec_disable() {
        ig_md.flags.flowspec_disable = 1;
    }

    @ignore_table_dependency("Ig_front.tunnel_decap.tunnel_decap")
    table flowspec_disable {
        key = {
            hdr.ipv4.isValid() : exact;
            hdr.ipv6.isValid() : exact;
        }
        actions = {
            set_flowspec_disable_v4;
            set_flowspec_disable_v6;
        }
        size = 5;
        const entries = {
            (true , false) : set_flowspec_disable_v4();
            (false, true ) : set_flowspec_disable_v6();
        }
    }

    apply{
        flowspec_disable.apply();
    }
}

//-----------------------------------------------------------------------------
// Front Ingress ACL Pre-calculated
// ACL匹配前，对相关参数进行预计算
//-----------------------------------------------------------------------------
control front_ig_acl_pre(in switch_header_t hdr,
            inout switch_ingress_metadata_t ig_md) {

    action set_src_port_label(bit<32> label) {
        ig_md.lkp.l4_port_label_32 = label;
    }

    action set_dst_port_label(bit<32> label) {
        ig_md.lkp.l4_port_label_32 = ig_md.lkp.l4_port_label_32 | label;
    }

    @entries_with_ranges(128)
    @placement_priority(127)
    table l4_dst_port {
        key = {
            hdr.ipv4.isValid() : exact;
            hdr.ipv6.isValid() : exact;
            ig_md.lkp.l4_dst_port : range;
        }
        actions = {
            NoAction;
            set_dst_port_label;
        }
        const default_action = NoAction;
        size = 128;
    }

    @entries_with_ranges(128)
    @placement_priority(127)
    table l4_src_port {
        key = {
            hdr.ipv4.isValid() : exact;
            hdr.ipv6.isValid() : exact;
            ig_md.lkp.l4_src_port : range;
        }
        actions = {
            NoAction;
            set_src_port_label;
        }
        const default_action = NoAction;
        size = 128;
    }

    /* get vag classid */
    action set_properties (
            switch_acl_classid_t classid_1,
            switch_acl_classid_t classid_2,
            switch_acl_classid_t classid_3) {
        ig_md.policer.slice1.group_classid = classid_1;
        ig_md.policer.slice2.group_classid = classid_2;
        ig_md.policer.slice3.group_classid = classid_3;
    }
    @placement_priority(127)
    @use_hash_action(1)
    table iif_properties {
        key = {
            hdr.ipv6.isValid() : exact;
            ig_md.common.ul_iif : exact @name("iif");
        }
        actions = {
            set_properties;
        }
        default_action = set_properties(0, 0, 0);
        size = 32 * 1024;
    }

    // action set_group (
    //             switch_acl_bypass_t group1,
    //             switch_acl_bypass_t group2,
    //             switch_acl_bypass_t group3,
    //             switch_acl_bypass_t group4) {
    //     ig_md.policer.slice1.group = group1;
    //     ig_md.policer.slice2.group = group2;
    //     ig_md.policer.slice3.group = group3;
    //     ig_md.policer.slice4.group = group4;
    // }

    // table acl_group {
    //     key = {
    //         hdr.ipv4.isValid() : exact;
    //         hdr.ipv6.isValid() : exact;
    //     }
    //     actions = {
    //         NoAction;
    //         set_group;
    //     }
    //     size = 2;
    //     default_action = NoAction;
    // }

    apply {
        iif_properties.apply();
        l4_src_port.apply();
        l4_dst_port.apply();
        // acl_group.apply();
    }
}

control front_ig_mirror_acl (inout switch_header_t hdr,
                    in switch_acl_classid_t group_classid,
                    inout switch_ingress_metadata_t ig_md,
                    inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr) (
                    switch_uint32_t table_size = 512) {
    Counter<bit<64>, bit<16>>(table_size, CounterType_t.PACKETS) stats;
    Meter<bit<10>>(table_size, MeterType_t.BYTES) meter;
    Random<bit<16>>() random;

    action set_mirror(bit<16> stats_id, bit<10> meter_id,
            switch_mirror_session_t mirror_id) {
        // stats.count(stats_id);
        ig_md.mirror.color = (bit<2>) meter.execute(meter_id);
        ig_md.mirror.mirror_id = mirror_id;
        // ipfix-on-mirror
        // ig_md.mirror.span_flag = 1;
    }
    action set_mirror_and_drop(bit<16> stats_id, bit<10> meter_id,
            switch_mirror_session_t mirror_id) {
        set_mirror(stats_id, meter_id, mirror_id);
        ig_intr_md_for_dprsr.drop_ctl = 0x1;
    }
    action set_pcap_mirror(bit<16> stats_id, bit<10> meter_id,
            switch_mirror_session_t session_id, bit<16> cpu_code) {
        // stats.count(stats_id);
        // ig_md.common.cpu_code = cpu_code;
        ig_md.mirror.color = (bit<2>) meter.execute(meter_id);
        // ig_md.ipfix.session_id = session_id;
        // ipfix-on-mirror
        // ig_md.mirror.mirror_id = 0;
        ig_md.mirror.pcap_flag = 1;
    }
    action set_sample(
            bit<16> stats_id,
            switch_ipfix_flow_id_t flow_id,
            switch_ipfix_mode_t mode, switch_ipfix_gap_t sample_gap,
            switch_ipfix_random_mask_t random_mask,
            switch_mirror_session_t session_id) {
        // stats.count(stats_id);
        ig_md.ipfix.enable = true;
        ig_md.ipfix.random_num = random.get();
        ig_md.ipfix.flow_id = flow_id;
        ig_md.ipfix.mode = mode;
        ig_md.ipfix.sample_gap = sample_gap;
        ig_md.ipfix.random_mask = random_mask;
        // ig_md.ipfix.session_id = session_id;
        // ipfix-on-mirror
        // ig_md.mirror.mirror_id = 0;
    }
    action set_forward(bit<16> stats_id) {
        // stats.count(stats_id);
    }
    action set_track(bit<16> stats_id) {
        // stats.count(stats_id);
        ig_md.common.track = 1;
    }

    @stage(3)
    table acl {
        key = {
            group_classid : ternary @name("group_classid");
            ig_md.common.src_port : ternary @name("src_port");
            ig_md.common.ether_type : ternary @name("etype");
            ig_md.lkp.vid : ternary @name("vid");
            ig_md.lkp.ip_src_addr : ternary @name("ip_src_addr");
            ig_md.lkp.ip_dst_addr : ternary @name("ip_dst_addr");
            ig_md.lkp.ip_proto : ternary @name("ip_proto");
            ig_md.lkp.l4_src_port : ternary @name("l4_src_port");
            ig_md.lkp.l4_dst_port : ternary @name("l4_dst_port");
            ig_md.lkp.l4_port_label_32 : ternary @name("l4_port_label");
            ig_md.lkp.ip_frag : ternary @name("ip_frag");
            hdr.mpls_ig[0].label : ternary @name("mpls_label");
            hdr.mpls_ig[0].isValid() : ternary @name("mpls_isValid");
        }
        actions = {
            set_mirror;
            set_mirror_and_drop;

            set_sample;

            set_pcap_mirror;
            set_forward;
            set_track;
        }
        size = table_size;
    }

    apply {

        if (ig_md.srv6.is_loopback == 0) {

            acl.apply();

        }

    }
}

control front_ig_mac_acl (inout switch_header_t hdr,
                    in switch_acl_classid_t group_classid,
                    inout switch_ingress_metadata_t ig_md) (
                    switch_uint32_t table_size = 1024) {
    Counter<bit<64>, bit<16>>(table_size, CounterType_t.PACKETS) stats;

    action set_qos(bit<16> stats_id, bit<1> drop,
                    bit<14> meter_id, bit<3> drop_color,
                    bit<1> set_qos_tc, switch_tc_t tc,
                    bit<1> set_qos_color, bit<2> color) {
        stats.count(stats_id);
        ig_md.policer.mac_drop = drop;
        ig_md.qos.ace_mode = 1;
        ig_md.qos.acl_meter_index = meter_id;
        ig_md.qos.drop_color = drop_color;
        ig_md.qos.mac_set_tc = set_qos_tc;
        ig_md.qos.mac_tc = tc;
        ig_md.qos.mac_set_color = set_qos_color;
        ig_md.qos.mac_color = color;
    }

    action set_qos_chg_pcp(bit<16> stats_id, bit<1> drop,
                    bit<14> meter_id, bit<3> drop_color,
                    bit<1> set_qos_tc, switch_tc_t tc,
                    bit<1> set_qos_color, bit<2> color,
                    bit<3> pcp) {
        stats.count(stats_id);
        ig_md.policer.mac_drop = drop;
        ig_md.qos.ace_mode = 1;
        ig_md.qos.acl_meter_index = meter_id;
        ig_md.qos.drop_color = drop_color;
        ig_md.qos.mac_set_tc = set_qos_tc;
        ig_md.qos.mac_tc = tc;
        ig_md.qos.mac_set_color = set_qos_color;
        ig_md.qos.mac_color = color;
        hdr.vlan_tag[0].pcp = pcp;
    }

    @ignore_table_dependency("Ig_front.pause_front.redirect_pause")
    @ignore_table_dependency("Ig_front.lif_mapping.add_native_vlan")
    @placement_priority(127)
    @stage(4)
    table acl {
        key = {
            group_classid : ternary @name("group_classid");
            hdr.ethernet.src_addr : ternary @name("smac");
            hdr.ethernet.dst_addr : ternary @name("dmac");
            ig_md.common.ether_type : ternary @name("etype");
            hdr.vlan_tag[0].isValid() : ternary;
            hdr.vlan_tag[0].pcp : ternary @name("out_pcp");
            hdr.vlan_tag[1].isValid() : ternary;
            hdr.vlan_tag[1].pcp : ternary @name("in_pcp");
        }
        actions = {
            set_qos;
            set_qos_chg_pcp;
        }
        size = table_size;
    }

    apply {
        acl.apply();
    }
}

control front_ig_ipv4_acl(inout switch_header_t hdr,
                    in switch_acl_classid_t group_classid,
                    inout switch_ingress_metadata_t ig_md) (
                    switch_uint32_t table_size = 2048) {
    Counter<bit<64>, bit<16>>(table_size, CounterType_t.PACKETS) stats;

    action set_qos(bit<16> stats_id, bit<1> ace_mode, bit<14> meter_id, bit<3> drop_color, bit<1> set_qos_tc, switch_tc_t tc, bit<1> set_qos_color, bit<2> color, bit<1> set_dscp, bit<6> dscp) { stats.count(stats_id); ig_md.qos.ace_mode = ace_mode; ig_md.qos.acl_meter_index = meter_id; ig_md.qos.drop_color = drop_color; ig_md.qos.set_tc = set_qos_tc; ig_md.qos.tc_tmp = tc; ig_md.qos.set_color = set_qos_color; ig_md.qos.color_tmp = color; ig_md.qos.set_dscp = set_dscp; ig_md.qos.dscp = dscp; } action set_qos_no_meter(bit<16> stats_id, bit<1> set_qos_tc, switch_tc_t tc, bit<1> set_qos_color, bit<2> color, bit<1> set_dscp, bit<6> dscp) { stats.count(stats_id); ig_md.qos.set_tc = set_qos_tc; ig_md.qos.tc_tmp = tc; ig_md.qos.set_color = set_qos_color; ig_md.qos.color_tmp = color; ig_md.qos.set_dscp = set_dscp; ig_md.qos.dscp = dscp; }

    @ignore_table_dependency("Ig_front.ipv6_acl.acl")
    // @stage(4)
    @placement_priority(127)
    table acl {
        key = {
            ig_md.lkp.ip_src_addr[31:0] : ternary @name("ip_src_addr"); ig_md.lkp.ip_dst_addr[31:0] : ternary @name("ip_dst_addr"); ig_md.lkp.ip_proto : ternary @name("ip_proto"); hdr.ipv4.diffserv : ternary @name("ip_tos"); ig_md.lkp.ip_frag : ternary @name("ip_frag"); group_classid : ternary @name("group_classid"); ig_md.lkp.vid : ternary @name("vid"); ig_md.lkp.l4_src_port : ternary @name("l4_src_port"); ig_md.lkp.l4_dst_port : ternary @name("l4_dst_port"); ig_md.lkp.l4_port_label_32 : ternary @name("l4_port_label"); ig_md.lkp.tcp_flags[5:0] : ternary @name("tcp_flags");
        }
        actions = {
            set_qos;
            set_qos_no_meter;
        }
        size = table_size;
    }
    apply {
        if (hdr.ipv4.isValid()) {
            acl.apply();
        }
    }
}

control front_ig_ipv6_acl(inout switch_header_t hdr,
                    in switch_acl_classid_t group_classid,
                    inout switch_ingress_metadata_t ig_md) (
                    switch_uint32_t table_size = 1024) {
    Counter<bit<64>, bit<16>>(table_size, CounterType_t.PACKETS) stats;

    action set_qos(bit<16> stats_id, bit<1> ace_mode, bit<14> meter_id, bit<3> drop_color, bit<1> set_qos_tc, switch_tc_t tc, bit<1> set_qos_color, bit<2> color, bit<1> set_dscp, bit<6> dscp) { stats.count(stats_id); ig_md.qos.ace_mode = ace_mode; ig_md.qos.acl_meter_index = meter_id; ig_md.qos.drop_color = drop_color; ig_md.qos.set_tc = set_qos_tc; ig_md.qos.tc_tmp = tc; ig_md.qos.set_color = set_qos_color; ig_md.qos.color_tmp = color; ig_md.qos.set_dscp = set_dscp; ig_md.qos.dscp = dscp; } action set_qos_no_meter(bit<16> stats_id, bit<1> set_qos_tc, switch_tc_t tc, bit<1> set_qos_color, bit<2> color, bit<1> set_dscp, bit<6> dscp) { stats.count(stats_id); ig_md.qos.set_tc = set_qos_tc; ig_md.qos.tc_tmp = tc; ig_md.qos.set_color = set_qos_color; ig_md.qos.color_tmp = color; ig_md.qos.set_dscp = set_dscp; ig_md.qos.dscp = dscp; }

    @ignore_table_dependency("Ig_front.ipv4_acl.acl")
    @placement_priority(127)
    table acl {
        key = {
            ig_md.lkp.ip_src_addr : ternary @name("ip_src_addr"); ig_md.lkp.ip_dst_addr : ternary @name("ip_dst_addr"); ig_md.lkp.ip_proto : ternary @name("ip_proto"); hdr.ipv6.traffic_class : ternary @name("ip_tos"); group_classid : ternary @name("group_classid"); ig_md.lkp.vid : ternary @name("vid"); ig_md.lkp.l4_src_port : ternary @name("l4_src_port"); ig_md.lkp.l4_dst_port : ternary @name("l4_dst_port"); ig_md.lkp.l4_port_label_32 : ternary @name("l4_port_label"); ig_md.lkp.tcp_flags[5:0] : ternary @name("tcp_flags");
        }
        actions = {
            set_qos;
            set_qos_no_meter;
        }
        size = table_size;
    }
    apply {
        if (hdr.ipv6.isValid()) {
            acl.apply();
        }
    }
}

control front_ig_qos_resolve(inout switch_header_t hdr,
                    inout switch_ingress_metadata_t ig_md) {

    action ipv4_dscp() {
        hdr.ipv4.diffserv[7:2] = ig_md.qos.dscp;
        ig_md.qos.chgDSCP_disable = 1;
    }

    action ipv6_dscp() {
        hdr.ipv6.traffic_class[7:2] = ig_md.qos.dscp;
        ig_md.qos.chgDSCP_disable = 1;
    }

    action flag_rewrite() {
        ig_md.qos.chgDSCP_disable = 0;
    }

    @ignore_table_dependency("Ig_front.tunnel_decap.tunnel_decap")
    table dscp_resolve {
        key = {
            ig_md.qos.set_dscp : ternary;
            hdr.ipv4.isValid() : ternary;
            hdr.ipv6.isValid() : ternary;
            ig_md.qos.set_tc : ternary;
            ig_md.qos.set_color : ternary;
            ig_md.qos.mac_set_tc : ternary;
            ig_md.qos.mac_set_color : ternary;
        }
        actions = {
            ipv4_dscp;
            ipv6_dscp;
            flag_rewrite;
        }
        size = 16;
        const entries = {
            (1, true, false, _, _, _, _) : ipv4_dscp();
            (1, false, true, _, _, _, _) : ipv6_dscp();
            (0, _, _, 1, _, _, _) : flag_rewrite();
            (0, _, _, _, 1, _, _) : flag_rewrite();
            (0, _, _, _, _, 1, _) : flag_rewrite();
            (0, _, _, _, _, _, 1) : flag_rewrite();
        }
    }

    action tc_rewrite() {
        ig_md.qos.tc = ig_md.qos.tc_tmp;
        ig_md.qos.BA = 1;
    }
    action mac_tc_rewrite() {
        ig_md.qos.tc = ig_md.qos.mac_tc;
        ig_md.qos.BA = 1;
    }
    action color_rewrite() {
        ig_md.qos.color = ig_md.qos.color_tmp;
        ig_md.qos.BA = 1;
    }
    action mac_color_rewrite() {
        ig_md.qos.color = ig_md.qos.mac_color;
        ig_md.qos.BA = 1;
    }
    action tc_color_rewrite() {
        tc_rewrite();
        color_rewrite();
    }
    action tc_mac_color_rewrite() {
        tc_rewrite();
        mac_color_rewrite();
    }
    action mac_tc_color_rewrite() {
        mac_tc_rewrite();
        color_rewrite();
    }
    action mac_tc_mac_color_rewrite() {
        mac_tc_rewrite();
        mac_color_rewrite();
    }

    table tc_color_resolve {
        key = {
            ig_md.qos.set_tc : exact;
            ig_md.qos.set_color : exact;
            ig_md.qos.mac_set_tc : exact;
            ig_md.qos.mac_set_color : exact;
        }
        actions = {
            NoAction;
            tc_rewrite;
            mac_tc_rewrite;
            color_rewrite;
            mac_color_rewrite;
            tc_color_rewrite;
            tc_mac_color_rewrite;
            mac_tc_color_rewrite;
            mac_tc_mac_color_rewrite;
        }
        size = 16;
        const entries = {
            (1, 1, 1, 1) : tc_color_rewrite();
            (1, 1, 1, 0) : tc_color_rewrite();
            (1, 1, 0, 1) : tc_color_rewrite();
            (1, 1, 0, 0) : tc_color_rewrite();
            (1, 0, 1, 1) : tc_mac_color_rewrite();
            (1, 0, 1, 0) : tc_rewrite();
            (1, 0, 0, 1) : tc_mac_color_rewrite();
            (1, 0, 0, 0) : tc_rewrite();
            (0, 1, 1, 1) : mac_tc_color_rewrite();
            (0, 1, 1, 0) : mac_tc_color_rewrite();
            (0, 1, 0, 1) : color_rewrite();
            (0, 1, 0, 0) : color_rewrite();
            (0, 0, 1, 1) : mac_tc_mac_color_rewrite();
            (0, 0, 1, 0) : mac_tc_rewrite();
            (0, 0, 0, 1) : mac_color_rewrite();
            (0, 0, 0, 0) : NoAction();
        }
    }

    apply {
        dscp_resolve.apply();
        tc_color_resolve.apply();
    }

}

control front_eg_get_bypass(in switch_header_t hdr, inout switch_egress_metadata_t eg_md) {
    action bypass(bit<1> bypass_acl) {
        eg_md.flags.bypass_acl = bypass_acl;
    }
    @placement_priority(127)
    table get_bypass {
        key = {
            eg_md.common.is_mirror : exact;
            hdr.bridged_md_310.isValid() : exact;
        }
        actions = {
            bypass;
        }
        size = 4;
    }
    apply {
        get_bypass.apply();
    }
}
//-----------------------------------------------------------------------------
// Inner ACL Pre-calculated
// ACL匹配前，对相关参数进行预计算
//-----------------------------------------------------------------------------
control front_eg_acl_pre(in switch_header_t hdr,
            inout switch_egress_metadata_t eg_md) (
            switch_uint32_t table_size = 128) {

    front_eg_ip_frag() ip_frag;

    action set_src_port_label(bit<32> label) {
        eg_md.lkp.l4_port_label_32 = label;
    }

    action set_dst_port_label(bit<32> label) {
        eg_md.lkp.l4_port_label_32 = eg_md.lkp.l4_port_label_32 | label;
    }

    @entries_with_ranges(table_size)
    table l4_dst_port {
        key = {
            hdr.ipv4.isValid() : ternary;
            hdr.ipv6.isValid() : ternary;
            eg_md.lkp.l4_dst_port : range;
        }
        actions = {
            NoAction;
            set_dst_port_label;
        }
        const default_action = NoAction;
        size = table_size;
    }

    @entries_with_ranges(table_size)
    table l4_src_port {
        key = {
            hdr.ipv4.isValid() : ternary;
            hdr.ipv6.isValid() : ternary;
            eg_md.lkp.l4_src_port : range;
        }
        actions = {
            NoAction;
            set_src_port_label;
        }
        const default_action = NoAction;
        size = table_size;
    }

    action set_group (
                switch_acl_bypass_t group1,
                switch_acl_bypass_t group2) {
        eg_md.policer.slice1.group = group1;
        eg_md.policer.slice2.group = group2;
    }

    table acl_group {
        key = {
            hdr.ipv4.isValid() : exact;
            hdr.ipv6.isValid() : exact;
        }
        actions = {
            NoAction;
            set_group;
        }
        size = 2;
        default_action = NoAction;
    }

    apply {
        // eg_md.policer.slice1.group = SWITCH_ACL_BYPASS_1;
        // l4_src_port.apply();
        // l4_dst_port.apply();
        ip_frag.apply(hdr, eg_md);
        // acl_group.apply();
    }
}

//-----------------------------------------------------------------------------
// Front Egress Mirror ACL
//-----------------------------------------------------------------------------
control front_eg_mirror_acl(inout switch_header_t hdr,
                    in switch_acl_classid_t group_classid,
                    inout switch_egress_metadata_t eg_md) (
                    switch_uint32_t table_size = 512) {
    Counter<bit<64>, bit<16>>(table_size, CounterType_t.PACKETS) stats;
    Meter<bit<10>>(table_size, MeterType_t.BYTES) meter;
    Random<bit<16>>() random;

    action set_mirror(bit<16> stats_id, bit<10> meter_id,
            switch_mirror_session_t mirror_id) {
        // stats.count(stats_id);
        eg_md.mirror.color = (bit<2>) meter.execute(meter_id);
        eg_md.mirror.mirror_id = mirror_id;
    }
    action set_pcap_mirror(bit<16> stats_id, bit<16> cpu_code, bit<10> meter_id,
            switch_mirror_session_t session_id) {
        // stats.count(stats_id);
        // eg_md.common.cpu_code = cpu_code;
        eg_md.mirror.color = (bit<2>) meter.execute(meter_id);
        eg_md.ipfix.session_id = session_id;
        eg_md.mirror.pcap_flag = 1;
    }
    action set_sample(bit<16> stats_id,
            switch_ipfix_flow_id_t flow_id,
            switch_ipfix_mode_t mode, switch_ipfix_gap_t sample_gap,
            switch_ipfix_random_mask_t random_mask,
            switch_mirror_session_t session_id) {
        // stats.count(stats_id);
        eg_md.ipfix.enable = true;
        eg_md.ipfix.random_num = random.get();
        eg_md.ipfix.flow_id = flow_id;
        eg_md.ipfix.mode = mode;
        eg_md.ipfix.sample_gap = sample_gap;
        eg_md.ipfix.random_mask = random_mask;
        eg_md.ipfix.session_id = session_id;
    }

    // @placement_priority(127)
    table acl {
        key = {
            group_classid : ternary @name("group_classid");
            eg_md.lkp.vid : ternary @name("vid");
            hdr.ipv4.isValid() : ternary;
            hdr.ipv6.isValid() : ternary;
            // eg_md.lkp.ip_type : ternary @name("ip_type");
            eg_md.lkp.ip_src_addr : ternary @name("ip_src_addr");
            eg_md.lkp.ip_dst_addr : ternary @name("ip_dst_addr");
            eg_md.lkp.ip_proto : ternary @name("ip_proto");
            eg_md.lkp.l4_src_port : ternary @name("l4_src_port");
            eg_md.lkp.l4_dst_port : ternary @name("l4_dst_port");
            eg_md.lkp.l4_port_label_32 : ternary @name("l4_port_label");
            // lkp.tcp_flags[5:0] : ternary @name("tcp_flags");
            // lkp.ip_tos : ternary @name("ip_tos");
            eg_md.lkp.ip_frag : ternary @name("ip_frag");
            eg_md.common.track : ternary @name("track");
        }
        actions = {
            set_mirror;

            set_sample;

            set_pcap_mirror;
        }
        size = table_size;
    }

    apply {
        if (eg_md.flags.bypass_acl == 0) {
            acl.apply();
        }
    }
}

control front_eg_mac_acl (inout switch_header_t hdr,
                    in switch_acl_classid_t group_classid,
                    inout switch_egress_metadata_t eg_md) (
                    switch_uint32_t table_size = 1024) {
    Counter<bit<64>, bit<16>>(table_size, CounterType_t.PACKETS) stats;
    Meter<bit<10>>(table_size, MeterType_t.BYTES) meter;

    action set_qos(bit<16> stats_id, bit<1> drop,
                    bit<10> meter_id, bit<3> drop_color) {
        stats.count(stats_id);
        eg_md.policer.mac_drop = drop;
        eg_md.qos.acl_meter_color = (bit<2>)meter.execute(meter_id);
        eg_md.qos.drop_color = drop_color;
    }

    action set_qos_chg_pcp(bit<16> stats_id, bit<1> drop,
                            bit<10> meter_id, bit<3> drop_color,
                            bit<3> pcp) {
        stats.count(stats_id);
        eg_md.policer.mac_drop = drop;
        eg_md.qos.acl_meter_color = (bit<2>)meter.execute(meter_id);
        eg_md.qos.drop_color = drop_color;
        hdr.vlan_tag[0].pcp = pcp;
    }

    // @placement_priority(127)
    @stage(8)
    table acl {
        key = {
            group_classid : ternary @name("group_classid");
            hdr.ethernet.src_addr : ternary @name("smac");
            hdr.ethernet.dst_addr : ternary @name("dmac");
            eg_md.common.ether_type : ternary @name("etype");
            hdr.vlan_tag[0].isValid() : ternary;
            hdr.vlan_tag[0].pcp : ternary @name("out_pcp");
            hdr.vlan_tag[1].isValid() : ternary;
            hdr.vlan_tag[1].pcp : ternary @name("in_pcp");
        }
        actions = {
            set_qos;
            set_qos_chg_pcp;
        }
        size = table_size;
    }

    apply {
        if (eg_md.flags.bypass_acl == 0) {
            acl.apply();
        }
    }
}

//-----------------------------------------------------------------------------
// Front Egress Ipv4 ACL
//-----------------------------------------------------------------------------
control front_eg_ipv4_acl(inout switch_header_t hdr,
                    in switch_acl_classid_t group_classid,
                    inout switch_egress_metadata_t eg_md) (
                    switch_uint32_t table_size = 2048) {
    Counter<bit<64>, bit<16>>(table_size, CounterType_t.PACKETS) stats;
    Meter<bit<10>>(table_size, MeterType_t.BYTES) meter;
    Random<bit<16>>() random;

    action set_acl(bit<16> stats_id, bit<1> set_drop) { stats.count(stats_id); eg_md.flags.drop = set_drop; }

    @ignore_table_dependency("Eg_front.acl.ipv6_acl1.acl")
    // @ignore_table_dependency("Eg_front.acl.ipv6_acl2.acl")
    @stage(2)
    table acl {
        key = {
            eg_md.lkp.ip_src_addr[31:0] : ternary @name("ip_src_addr"); eg_md.lkp.ip_dst_addr[31:0] : ternary @name("ip_dst_addr"); eg_md.lkp.ip_proto : ternary @name("ip_proto"); hdr.ipv4.diffserv : ternary @name("ip_tos"); eg_md.lkp.ip_frag : ternary @name("ip_frag"); eg_md.policer.bypass : ternary @name("bypass"); group_classid : ternary @name("group_classid"); eg_md.lkp.l4_src_port : ternary @name("l4_src_port"); eg_md.lkp.l4_dst_port : ternary @name("l4_dst_port"); eg_md.lkp.l4_port_label_32 : ternary @name("l4_port_label"); eg_md.lkp.tcp_flags[5:0] : ternary @name("tcp_flags");
        }
        actions = {
            set_acl;
        }
        size = table_size;
    }

    apply {
        if (hdr.ipv4.isValid() && eg_md.flags.bypass_acl == 0) {
            acl.apply();
        }
    }
}

//-----------------------------------------------------------------------------
// Front Egress Ipv6 ACL Slice 1
//-----------------------------------------------------------------------------
control front_eg_ipv6_acl(inout switch_header_t hdr,
                    in switch_acl_classid_t group_classid,
                    inout switch_egress_metadata_t eg_md) (
                    switch_uint32_t table_size = 1024) {
    Counter<bit<64>, bit<16>>(table_size, CounterType_t.PACKETS) stats;
    Meter<bit<10>>(table_size, MeterType_t.BYTES) meter;
    Random<bit<16>>() random;

    action set_acl(bit<16> stats_id, bit<1> set_drop) { stats.count(stats_id); eg_md.flags.drop = set_drop; }

    @ignore_table_dependency("Eg_front.acl.ipv4_acl1.acl")
    // @ignore_table_dependency("Eg_front.acl.ipv4_acl2.acl")
    @stage(7)
    table acl {
        key = {
            eg_md.lkp.ip_src_addr : ternary @name("ip_src_addr"); eg_md.lkp.ip_dst_addr : ternary @name("ip_dst_addr"); eg_md.lkp.ip_proto : ternary @name("ip_proto"); hdr.ipv6.traffic_class : ternary @name("ip_tos"); eg_md.policer.bypass : ternary @name("bypass"); group_classid : ternary @name("group_classid"); eg_md.lkp.l4_src_port : ternary @name("l4_src_port"); eg_md.lkp.l4_dst_port : ternary @name("l4_dst_port"); eg_md.lkp.l4_port_label_32 : ternary @name("l4_port_label"); eg_md.lkp.tcp_flags[5:0] : ternary @name("tcp_flags");
        }
        actions = {
            set_acl;
        }
        size = table_size;
    }

    apply {
        if (hdr.ipv6.isValid() && eg_md.flags.bypass_acl == 0) {
            acl.apply();
        }
    }
}

control front_eg_ipv6_acl2(inout switch_header_t hdr,
                    in switch_acl_bypass_t group,
                    in switch_acl_classid_t group_classid,
                    inout switch_egress_metadata_t eg_md) (
                    switch_uint32_t table_size = 1024) {
    Counter<bit<64>, bit<16>>(table_size, CounterType_t.PACKETS) stats;
    Meter<bit<10>>(table_size, MeterType_t.BYTES) meter;
    Random<bit<16>>() random;

    action set_acl(bit<16> stats_id, bit<1> set_drop) { stats.count(stats_id); eg_md.flags.drop = set_drop; }

    @ignore_table_dependency("Eg_front.acl.ipv4_acl1.acl")
    @ignore_table_dependency("Eg_front.acl.ipv4_acl2.acl")
    @stage(8)
    table acl {
        key = {
            eg_md.lkp.ip_src_addr : ternary @name("ip_src_addr"); eg_md.lkp.ip_dst_addr : ternary @name("ip_dst_addr"); eg_md.lkp.ip_proto : ternary @name("ip_proto"); hdr.ipv6.traffic_class : ternary @name("ip_tos"); eg_md.policer.bypass : ternary @name("bypass"); group_classid : ternary @name("group_classid"); eg_md.lkp.l4_src_port : ternary @name("l4_src_port"); eg_md.lkp.l4_dst_port : ternary @name("l4_dst_port"); eg_md.lkp.l4_port_label_32 : ternary @name("l4_port_label"); eg_md.lkp.tcp_flags[5:0] : ternary @name("tcp_flags");
        }
        actions = {
            set_acl;
        }
        size = table_size;
    }

    apply {
        if (hdr.ipv6.isValid() && eg_md.flags.bypass_acl == 0) {
            acl.apply();
        }
    }
}

control front_eg_acl(inout switch_header_t hdr,
                    inout switch_egress_metadata_t eg_md) {

    front_eg_ipv4_acl(2048) ipv4_acl1;
    front_eg_ipv4_acl(2048) ipv4_acl2;
    front_eg_ipv6_acl(1024) ipv6_acl1;
    front_eg_ipv6_acl2(1024) ipv6_acl2;

    apply {
        ipv4_acl1.apply(hdr, eg_md.policer.slice1.group_classid, eg_md);
        //ipv4_acl2.apply(hdr, eg_md.policer.slice1.group, eg_md.policer.slice1.group_classid, eg_md);
        ipv6_acl1.apply(hdr, eg_md.policer.slice1.group_classid, eg_md);
        //ipv6_acl2.apply(hdr, eg_md.policer.slice1.group, eg_md.policer.slice1.group_classid, eg_md);
    }
}


struct switch_counter_t {
    bit<32> hi;
    bit<32> low;
}

//-----------------------------------------------------------------------------
// Front Ingress System ACL
//-----------------------------------------------------------------------------
control FrontIngressSystemAcl(
        inout switch_header_t hdr,
        inout switch_ingress_metadata_t ig_md,
        in ingress_intrinsic_metadata_t ig_intr_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm,
        inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr)(
        switch_uint32_t table_size=512) {

    Counter<bit<64>, bit<16>>(1024, CounterType_t.PACKETS) stats;
    Counter<bit<64>, bit<8>>(256, CounterType_t.PACKETS) port_stats;

    Register<switch_counter_t, bit<8>>(256, {0, 0}) reg_port_counter;
    RegisterAction<switch_counter_t, bit<8>, bit<1>>(reg_port_counter) incr_port_counter = {
        void apply(inout switch_counter_t reg) {
            if (reg.low < (1 << 31) - 1) {
                reg.low = reg.low + 1;
                //rv = reg.low;
            } else {
                reg.hi = reg.hi + 1;
                reg.low = 0;
                //rv = reg.low;
            }
        }
    };

    action soft_drop(bit<16> stats_id, bit<8> drop_reason) {
        ig_md.qos.car_flag = 1; /* 复用 */
        ig_md.common.drop_reason = drop_reason;
    }
    action hard_drop(bit<16> stats_id, bit<8> drop_reason) {
        ig_intr_md_for_dprsr.drop_ctl = 0x1;
        stats.count(stats_id);
        //port_stats.count(ig_md.common.src_port);
        incr_port_counter.execute(ig_md.common.src_port);
        ig_md.common.drop_reason = drop_reason;
    }
    action forward(bit<16> stats_id) {
        stats.count(stats_id);
    }
    @ignore_table_dependency("Ig_front.tunnel_decap.tunnel_decap")
    table system_acl {
        key = {
            // common
            ig_md.common.ul_iif : ternary;
            // ig_md.common.eport: ternary;
            ig_md.common.drop_reason : ternary;
            // ig_md.ebridge.checks.same_if : ternary;
            // ig_md.common.iif : ternary;
            ig_md.tunnel.type : ternary;
            ig_md.tunnel.mpls_enable : ternary;
            ig_md.route.rmac_hit : ternary;
            ig_md.tunnel.terminate : ternary;
            ig_md.tunnel.bos : ternary;
            // ig_md.qos.port_meter_color : ternary; //no use
            ig_md.qos.lif_meter_color : ternary;
            ig_md.qos.acl_meter_color : ternary;
            ig_md.qos.drop_color : ternary;
            ig_md.stp.state : ternary;
            ig_md.flags.vlan_member_check : ternary;
            ig_md.policer.mac_drop : ternary;
        }
        actions = {
            soft_drop;
            hard_drop;
            forward;
        }
        const default_action = forward((bit<16>)SWITCH_DROP_REASON_FORWARD);
        size = table_size;
    }

    apply {
        // if (!INGRESS_BYPASS(SYSTEM_ACL))
        if (ig_md.flags.escape_etm == 0) {
            system_acl.apply();
            // switch(system_acl.apply().action_run) {
            //     // hard_drop: {
            //     //     port_count.apply();
            //     // }
            // }
        }
    }
}

//-----------------------------------------------------------------------------
// Front Ingress System ACL
//-----------------------------------------------------------------------------
control FrontEgressSystemAcl(
        inout switch_header_t hdr,
        inout switch_egress_metadata_t eg_md,
        in egress_intrinsic_metadata_t eg_intr_md,
        inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr)(
        switch_uint32_t table_size=512) {

    OifStats(IP_STATS_TABLE_SIZE) oif_stats;
    EgLportStats() eg_lport_stats;
    OifStatsCountIdx() oif_stats_idx;
    EgressEvlanStats() evlan_stats;
    Counter<bit<64>, bit<16>>(1024, CounterType_t.PACKETS) stats;
    Counter<bit<64>, bit<8>>(256, CounterType_t.PACKETS) port_stats;

    Register<switch_counter_t, bit<8>>(256, {0, 0}) reg_port_counter;
    RegisterAction<switch_counter_t, bit<8>, bit<1>>(reg_port_counter) incr_port_counter = {
        void apply(inout switch_counter_t reg) {
            if (reg.low < (1 << 31) - 1) {
                reg.low = reg.low + 1;
                //rv = reg.low;
            } else {
                reg.hi = reg.hi + 1;
                reg.low = 0;
                //rv = reg.low;
            }
        }
    };

    action drop(bit<16> stats_id, bit<8> drop_reason) {
        eg_intr_md_for_dprsr.drop_ctl = 0x1;
        stats.count(stats_id);
        incr_port_counter.execute(eg_md.common.dst_port);
        eg_md.common.drop_reason = drop_reason;
    }

    action forward(bit<16> stats_id) {
        stats.count(stats_id);
        eg_md.common.drop_reason = 0;
    }

    table system_acl {
        key = {
            eg_md.common.oif : ternary @name("oif");
            // eg_intr_md.egress_port : ternary;
            eg_md.common.dst_port : ternary @name("efm_dport");
            eg_md.common.ether_type : ternary @name("ether_type");
            eg_md.common.is_mirror : ternary @name("is_mirror");
            hdr.bridged_md_310.isValid() : ternary;
            eg_md.flags.drop : ternary;
            // eg_md.flags.efm_drop : ternary;
            hdr.ipv4.isValid() : ternary;
            hdr.ipv4.ttl : ternary;
            hdr.ipv6.isValid() : ternary;
            hdr.ipv6.hop_limit : ternary;
            hdr.mpls_vc_eg.isValid() : ternary;
            hdr.mpls_vc_eg.ttl : ternary; //by lichunfeng
            // hdr.mpls_ig[0].isValid(): ternary;
            // hdr.mpls_ig[0].ttl: ternary;
            eg_md.qos.port_meter_color : ternary;
            eg_md.qos.acl_meter_color : ternary;
            eg_md.qos.drop_color : ternary;
            eg_md.policer.mac_drop : ternary;
            eg_md.common.track : ternary;
        }
        actions = {
            drop;
            forward;
        }
        const default_action = forward((bit<16>)SWITCH_DROP_REASON_FORWARD);
        size = table_size;
    }

    action set_mirror_invalid() {
        eg_md.mirror.type = 0;
        eg_intr_md_for_dprsr.mirror_type = (MirrorType_t) 0;
    }

    @ignore_table_dependency("Eg_front.egress_trace.fabric_egress_trace")
    table mirror_disable {
        key = {
            eg_md.mirror.type : exact;
            // eg_intr_md_for_dprsr.drop_ctl : exact;
        }

        actions = {
            NoAction;
            set_mirror_invalid;
        }

        const default_action = NoAction;
        // const entries = {
        //     (SWITCH_MIRROR_TYPE_PORT, 1) : set_mirror_invalid();
        //     (SWITCH_MIRROR_TYPE_IPFIX, 1) : set_mirror_invalid();
        // }
    }

    apply {
        // if (!EGRESS_BYPASS(SYSTEM_ACL))
        if (eg_md.common.pkt_type != FABRIC_PKT_TYPE_CCM) {
            switch(system_acl.apply().action_run) {
                drop : {
                    mirror_disable.apply();
                    // port_stats.count(eg_md.common.dst_port);
                }
                forward : {
                    if (eg_md.common.cpu_eth_encap_id == 0 && eg_md.common.is_mirror == 0){
                        //oif_stats_idx.apply(hdr, eg_md);
                        oif_stats.apply(hdr, eg_md);
                        evlan_stats.apply(eg_md);
                    }
                    eg_lport_stats.apply(hdr, eg_md);
                }
            }
        }
    }
}
# 202 "/mnt/p4c-4127/p4src/switch-tofino2/switch_tofino_x1.p4" 2
# 1 "/mnt/p4c-4127/p4src/shared/acl_uplink.p4" 1
//-----------------------------------------------------------------------------
// Uplink Egress ACL key.
//-----------------------------------------------------------------------------
# 27 "/mnt/p4c-4127/p4src/shared/acl_uplink.p4"
//-----------------------------------------------------------------------------
// Common Uplink Egress ACL actions.
//-----------------------------------------------------------------------------
# 48 "/mnt/p4c-4127/p4src/shared/acl_uplink.p4"
control uplink_eg_acl_key_sel(in switch_header_t hdr,
                    in switch_acl_bypass_t group,
                    inout switch_acl_classid_t group_classid,
                    inout switch_egress_metadata_t eg_md) {

    action set_group_classid_1() {
        group_classid = eg_md.policer.group_classid_1;
    }
    action set_group_classid_2() {
        group_classid = eg_md.policer.group_classid_2;
    }
    action set_group_classid_3() {
        group_classid = eg_md.policer.group_classid_3;
    }
    action set_group_classid_4() {
        group_classid = eg_md.policer.group_classid_4;
    }
    table acl {
        key = {
            group : exact;
        }
        actions = {
            set_group_classid_1;
            set_group_classid_2;
            set_group_classid_3;
            set_group_classid_4;
        }
        // const entries = {
        //     (SWITCH_ACL_BYPASS_1) : set_group_classid_1();
        //     (SWITCH_ACL_BYPASS_2) : set_group_classid_2();
        //     (SWITCH_ACL_BYPASS_3) : set_group_classid_3();
        //     (SWITCH_ACL_BYPASS_4) : set_group_classid_4();
        // }
        size = 4;
    }

    apply {
        acl.apply();
    }
}

//-----------------------------------------------------------------------------
// Inner ACL Pre-calculated
// ACL匹配前，对相关参数进行预计算
//-----------------------------------------------------------------------------
control uplink_eg_acl_pre(in switch_header_t hdr,
            inout switch_egress_metadata_t eg_md) {

    uplink_eg_acl_key_sel() key_sel2;
    uplink_eg_acl_key_sel() key_sel3;
    uplink_eg_acl_key_sel() key_sel4;
    uplink_eg_acl_key_sel() key_sel5;
    uplink_eg_acl_key_sel() key_sel6;
    uplink_eg_acl_key_sel() key_sel7;

    action set_ip_frag(switch_ip_frag_t ip_frag) {
        eg_md.lkp.ip_frag = ip_frag;
    }

    action set_ip_proto() {
        eg_md.lkp.ip_proto = hdr.ipv6_frag.next_hdr;
        eg_md.lkp.ip_frag = SWITCH_IP_FRAG_HEAD;
    }

    @placement_priority(1)
    table ip_frag {
        key = {
            hdr.ipv6_frag.isValid() : exact;
            hdr.ipv4.isValid() : exact;
            hdr.ipv4.flags : ternary;
            hdr.ipv4.frag_offset : ternary;
        }
        actions = {
            set_ip_frag;
            set_ip_proto;
        }
        size = 8;
        default_action = set_ip_frag(SWITCH_IP_FRAG_NON_FRAG);
        // const entries = {
        //     (true, false, _, _) : set_ip_proto();
        //     (false, true, 0 &&& 1, 0) : set_ip_frag(SWITCH_IP_FRAG_NON_FRAG);
        //     (false, true, 1 &&& 1, 0) : set_ip_frag(SWITCH_IP_FRAG_HEAD);
        //     (false, true, _, _) : set_ip_frag(SWITCH_IP_FRAG_NON_HEAD);
        // }
    }

    action set_properties (
            switch_acl_classid_t classid_1,
            switch_acl_classid_t classid_2,
            switch_acl_classid_t classid_3,
            switch_acl_classid_t classid_4) {
        eg_md.policer.group_classid_1 = eg_md.policer.group_classid_1 | classid_1;
        eg_md.policer.group_classid_2 = eg_md.policer.group_classid_2 | classid_2;
        eg_md.policer.group_classid_3 = eg_md.policer.group_classid_3 | classid_3;
        eg_md.policer.group_classid_4 = eg_md.policer.group_classid_4 | classid_4;
        eg_md.policer.slice1.group_classid = eg_md.policer.slice1.group_classid | classid_1;
    }
    @placement_priority(100)
    @use_hash_action(1)
    table iif_properties {
        key = {
            hdr.ipv6.isValid() : exact;
            eg_md.policer.iif : exact @name("iif");
        }
        actions = {
            set_properties;
        }
        default_action = set_properties(0, 0, 0, 0);
        size = 32 * 1024;
    }


    action set_src_port_label(bit<64> label) {
        eg_md.lkp.l4_port_label_64 = label;
    }

    action set_dst_port_label(bit<64> label) {
        eg_md.lkp.l4_port_label_64 = eg_md.lkp.l4_port_label_64 | label;
    }

    @entries_with_ranges(128)
    table l4_dst_port {
        key = {
            hdr.ipv4.isValid() : exact;
            hdr.ipv6.isValid() : exact;
            eg_md.lkp.l4_dst_port : range;
        }
        actions = {
            NoAction;
            set_dst_port_label;
        }
        const default_action = NoAction;
        size = 128;
    }

    @entries_with_ranges(128)
    table l4_src_port {
        key = {
            hdr.ipv4.isValid() : exact;
            hdr.ipv6.isValid() : exact;
            eg_md.lkp.l4_src_port : range;
        }
        actions = {
            NoAction;
            set_src_port_label;
        }
        const default_action = NoAction;
        size = 128;
    }

    action set_group (
                switch_acl_bypass_t group1,
                switch_acl_bypass_t group2,
                switch_acl_bypass_t group3) {
        eg_md.policer.slice1.group = group1;
        eg_md.policer.slice2.group = group2;
        eg_md.policer.slice3.group = group3;
    }

    table acl_group {
        key = {
            hdr.ipv4.isValid() : exact;
            hdr.ipv6.isValid() : exact;
        }
        actions = {
            NoAction;
            set_group;
        }
        default_action = NoAction;
        size = 4;
    }

    apply {
        l4_src_port.apply();
        l4_dst_port.apply();
        iif_properties.apply();
        ip_frag.apply();
        acl_group.apply();
        key_sel2.apply(hdr, eg_md.policer.slice2.group, eg_md.policer.slice2.group_classid, eg_md);
        key_sel3.apply(hdr, eg_md.policer.slice3.group, eg_md.policer.slice3.group_classid, eg_md);
    }
}

// -----------------------------------------------------------------------------
// Uplink Egress Ipv4 ACL
// -----------------------------------------------------------------------------
control uplink_eg_ipv4_acl1(inout switch_header_t hdr,
                    in switch_acl_bypass_t group,
                    in switch_acl_classid_t group_classid,
                    inout switch_egress_metadata_t eg_md) (
                    switch_uint32_t table_size = 2048) {
    Counter<bit<64>, bit<16>>(table_size, CounterType_t.PACKETS) stats;
    Meter<bit<16>>(table_size, MeterType_t.BYTES) meter;

    action set_pbr(bit<14> stats_id, bit<14> meter_id, bit<1> set_drop, bit<1> set_nexthop, bit<16> nexthop, bit<1> is_ecmp, bit<8> nh_priority, bit<2> level, bit<1> set_dscp, bit<6> dscp) { eg_md.policer.stats_id = stats_id; eg_md.qos.acl_meter_index = meter_id; eg_md.policer.bypass = eg_md.policer.bypass | group; eg_md.policer.drop = eg_md.policer.drop | set_drop; eg_md.qos.set_dscp = set_dscp; eg_md.flags.is_pbr_nhop = set_nexthop; eg_md.route.pbr_nexthop = nexthop; eg_md.route.pbr_is_ecmp = is_ecmp; eg_md.route.pbr_priority = nh_priority; eg_md.route.pbr_level = level; eg_md.qos.dscp = dscp; }

    @ignore_table_dependency("Eg_uplink.acl.ipv6_acl1.acl")
    @ignore_table_dependency("Eg_uplink.acl.ipv6_acl2.acl")
    @ignore_table_dependency("Eg_uplink.acl.ipv6_acl3.acl")
    @stage(3)
    table acl {
        key = {
            hdr.ipv4.src_addr : ternary @name("ip_src_addr"); hdr.ipv4.dst_addr : ternary @name("ip_dst_addr"); eg_md.lkp.ip_proto : ternary @name("ip_proto"); hdr.ipv4.diffserv : ternary @name("ip_tos"); eg_md.lkp.ip_frag : ternary @name("ip_frag"); eg_md.policer.bypass : ternary @name("bypass"); group_classid : ternary @name("group_classid"); eg_md.lkp.l4_src_port : ternary @name("l4_src_port"); eg_md.lkp.l4_dst_port : ternary @name("l4_dst_port"); eg_md.lkp.l4_port_label_64 : ternary @name("l4_port_label"); eg_md.lkp.tcp_flags[5:0] : ternary @name("tcp_flags");
        }
        actions = {
            set_pbr;
        }
        size = table_size;
    }

    apply {
        if (hdr.ipv4.isValid()) {
            acl.apply();
        }
    }
}

control uplink_eg_ipv4_acl2(inout switch_header_t hdr,
                    in switch_acl_bypass_t group,
                    in switch_acl_classid_t group_classid,
                    inout switch_egress_metadata_t eg_md) (
                    switch_uint32_t table_size = 2048) {
    Counter<bit<64>, bit<16>>(table_size, CounterType_t.PACKETS) stats;
    Meter<bit<16>>(table_size, MeterType_t.BYTES) meter;

    action set_pbr(bit<14> stats_id, bit<14> meter_id, bit<1> set_drop, bit<1> set_nexthop, bit<16> nexthop, bit<1> is_ecmp, bit<8> nh_priority, bit<2> level, bit<1> set_dscp, bit<6> dscp) { eg_md.policer.stats_id = stats_id; eg_md.qos.acl_meter_index = meter_id; eg_md.policer.bypass = eg_md.policer.bypass | group; eg_md.policer.drop = eg_md.policer.drop | set_drop; eg_md.qos.set_dscp = set_dscp; eg_md.flags.is_pbr_nhop = set_nexthop; eg_md.route.pbr_nexthop = nexthop; eg_md.route.pbr_is_ecmp = is_ecmp; eg_md.route.pbr_priority = nh_priority; eg_md.route.pbr_level = level; eg_md.qos.dscp = dscp; }

    @ignore_table_dependency("Eg_uplink.acl.ipv6_acl1.acl")
    @ignore_table_dependency("Eg_uplink.acl.ipv6_acl2.acl")
    @ignore_table_dependency("Eg_uplink.acl.ipv6_acl3.acl")
    @stage(7)
    table acl {
        key = {
            hdr.ipv4.src_addr : ternary @name("ip_src_addr"); hdr.ipv4.dst_addr : ternary @name("ip_dst_addr"); eg_md.lkp.ip_proto : ternary @name("ip_proto"); hdr.ipv4.diffserv : ternary @name("ip_tos"); eg_md.lkp.ip_frag : ternary @name("ip_frag"); eg_md.policer.bypass : ternary @name("bypass"); group_classid : ternary @name("group_classid"); eg_md.lkp.l4_src_port : ternary @name("l4_src_port"); eg_md.lkp.l4_dst_port : ternary @name("l4_dst_port"); eg_md.lkp.l4_port_label_64 : ternary @name("l4_port_label"); eg_md.lkp.tcp_flags[5:0] : ternary @name("tcp_flags");
        }
        actions = {
            set_pbr;
        }
        size = table_size;
    }

    apply {
        if (hdr.ipv4.isValid()) {
            acl.apply();
        }
    }
}

control uplink_eg_ipv4_acl3(inout switch_header_t hdr,
                    in switch_acl_bypass_t group,
                    in switch_acl_classid_t group_classid,
                    inout switch_egress_metadata_t eg_md) (
                    switch_uint32_t table_size = 2048) {
    Counter<bit<64>, bit<16>>(table_size, CounterType_t.PACKETS) stats;
    Meter<bit<16>>(table_size, MeterType_t.BYTES) meter;

    action set_pbr(bit<14> stats_id, bit<14> meter_id, bit<1> set_drop, bit<1> set_nexthop, bit<16> nexthop, bit<1> is_ecmp, bit<8> nh_priority, bit<2> level, bit<1> set_dscp, bit<6> dscp) { eg_md.policer.stats_id = stats_id; eg_md.qos.acl_meter_index = meter_id; eg_md.policer.bypass = eg_md.policer.bypass | group; eg_md.policer.drop = eg_md.policer.drop | set_drop; eg_md.qos.set_dscp = set_dscp; eg_md.flags.is_pbr_nhop = set_nexthop; eg_md.route.pbr_nexthop = nexthop; eg_md.route.pbr_is_ecmp = is_ecmp; eg_md.route.pbr_priority = nh_priority; eg_md.route.pbr_level = level; eg_md.qos.dscp = dscp; }

    @ignore_table_dependency("Eg_uplink.acl.ipv6_acl1.acl")
    @ignore_table_dependency("Eg_uplink.acl.ipv6_acl2.acl")
    @ignore_table_dependency("Eg_uplink.acl.ipv6_acl3.acl")
    @stage(8)
    table acl {
        key = {
            hdr.ipv4.src_addr : ternary @name("ip_src_addr"); hdr.ipv4.dst_addr : ternary @name("ip_dst_addr"); eg_md.lkp.ip_proto : ternary @name("ip_proto"); hdr.ipv4.diffserv : ternary @name("ip_tos"); eg_md.lkp.ip_frag : ternary @name("ip_frag"); eg_md.policer.bypass : ternary @name("bypass"); group_classid : ternary @name("group_classid"); eg_md.lkp.l4_src_port : ternary @name("l4_src_port"); eg_md.lkp.l4_dst_port : ternary @name("l4_dst_port"); eg_md.lkp.l4_port_label_64 : ternary @name("l4_port_label"); eg_md.lkp.tcp_flags[5:0] : ternary @name("tcp_flags");
        }
        actions = {
            set_pbr;
        }
        size = table_size;
    }

    apply {
        if (hdr.ipv4.isValid()) {
            acl.apply();
        }
    }
}

//-----------------------------------------------------------------------------
// Uplink Egress Ipv6 ACL
//-----------------------------------------------------------------------------
control uplink_eg_ipv6_acl1(inout switch_header_t hdr,
                    in switch_acl_bypass_t group,
                    in switch_acl_classid_t group_classid,
                    inout switch_egress_metadata_t eg_md) (
                    switch_uint32_t table_size = 1024) {
    Counter<bit<64>, bit<16>>(table_size, CounterType_t.PACKETS) stats;
    Meter<bit<16>>(table_size, MeterType_t.BYTES) meter;

    action set_pbr(bit<14> stats_id, bit<14> meter_id, bit<1> set_drop, bit<1> set_nexthop, bit<16> nexthop, bit<1> is_ecmp, bit<8> nh_priority, bit<2> level, bit<1> set_dscp, bit<6> dscp) { eg_md.policer.stats_id = stats_id; eg_md.qos.acl_meter_index = meter_id; eg_md.policer.bypass = eg_md.policer.bypass | group; eg_md.policer.drop = eg_md.policer.drop | set_drop; eg_md.qos.set_dscp = set_dscp; eg_md.flags.is_pbr_nhop = set_nexthop; eg_md.route.pbr_nexthop = nexthop; eg_md.route.pbr_is_ecmp = is_ecmp; eg_md.route.pbr_priority = nh_priority; eg_md.route.pbr_level = level; eg_md.qos.dscp = dscp; }
    @ignore_table_dependency("Eg_uplink.acl.ipv4_acl1.acl")
    @ignore_table_dependency("Eg_uplink.acl.ipv4_acl2.acl")
    @ignore_table_dependency("Eg_uplink.acl.ipv4_acl3.acl")
    @stage(2)
    table acl {
        key = {
            hdr.ipv6.src_addr : ternary @name("ip_src_addr"); hdr.ipv6.dst_addr : ternary @name("ip_dst_addr"); eg_md.lkp.ip_proto : ternary @name("ip_proto"); hdr.ipv6.traffic_class : ternary @name("ip_tos"); eg_md.policer.bypass : ternary @name("bypass"); group_classid : ternary @name("group_classid"); eg_md.lkp.l4_src_port : ternary @name("l4_src_port"); eg_md.lkp.l4_dst_port : ternary @name("l4_dst_port"); eg_md.lkp.l4_port_label_64 : ternary @name("l4_port_label"); eg_md.lkp.tcp_flags[5:0] : ternary @name("tcp_flags");
        }
        actions = {
            set_pbr;
        }
        size = table_size;
    }
    apply {
        if (hdr.ipv6.isValid()) {
            acl.apply();
        }
    }
}

control uplink_eg_ipv6_acl2(inout switch_header_t hdr,
                    in switch_acl_bypass_t group,
                    in switch_acl_classid_t group_classid,
                    inout switch_egress_metadata_t eg_md) (
                    switch_uint32_t table_size = 1024) {
    Counter<bit<64>, bit<16>>(table_size, CounterType_t.PACKETS) stats;
    Meter<bit<16>>(table_size, MeterType_t.BYTES) meter;

    action set_pbr(bit<14> stats_id, bit<14> meter_id, bit<1> set_drop, bit<1> set_nexthop, bit<16> nexthop, bit<1> is_ecmp, bit<8> nh_priority, bit<2> level, bit<1> set_dscp, bit<6> dscp) { eg_md.policer.stats_id = stats_id; eg_md.qos.acl_meter_index = meter_id; eg_md.policer.bypass = eg_md.policer.bypass | group; eg_md.policer.drop = eg_md.policer.drop | set_drop; eg_md.qos.set_dscp = set_dscp; eg_md.flags.is_pbr_nhop = set_nexthop; eg_md.route.pbr_nexthop = nexthop; eg_md.route.pbr_is_ecmp = is_ecmp; eg_md.route.pbr_priority = nh_priority; eg_md.route.pbr_level = level; eg_md.qos.dscp = dscp; }
    @ignore_table_dependency("Eg_uplink.acl.ipv4_acl1.acl")
    @ignore_table_dependency("Eg_uplink.acl.ipv4_acl2.acl")
    @ignore_table_dependency("Eg_uplink.acl.ipv4_acl3.acl")
    @stage(4)
    table acl {
        key = {
            hdr.ipv6.src_addr : ternary @name("ip_src_addr"); hdr.ipv6.dst_addr : ternary @name("ip_dst_addr"); eg_md.lkp.ip_proto : ternary @name("ip_proto"); hdr.ipv6.traffic_class : ternary @name("ip_tos"); eg_md.policer.bypass : ternary @name("bypass"); group_classid : ternary @name("group_classid"); eg_md.lkp.l4_src_port : ternary @name("l4_src_port"); eg_md.lkp.l4_dst_port : ternary @name("l4_dst_port"); eg_md.lkp.l4_port_label_64 : ternary @name("l4_port_label"); eg_md.lkp.tcp_flags[5:0] : ternary @name("tcp_flags");
        }
        actions = {
            set_pbr;
        }
        size = table_size;
    }
    apply {
        if (hdr.ipv6.isValid()) {
            acl.apply();
        }
    }
}

control uplink_eg_ipv6_acl3(inout switch_header_t hdr,
                    in switch_acl_bypass_t group,
                    in switch_acl_classid_t group_classid,
                    inout switch_egress_metadata_t eg_md) (
                    switch_uint32_t table_size = 1024) {
    Counter<bit<64>, bit<16>>(table_size, CounterType_t.PACKETS) stats;
    Meter<bit<16>>(table_size, MeterType_t.BYTES) meter;

    action set_pbr(bit<14> stats_id, bit<14> meter_id, bit<1> set_drop, bit<1> set_nexthop, bit<16> nexthop, bit<1> is_ecmp, bit<8> nh_priority, bit<2> level, bit<1> set_dscp, bit<6> dscp) { eg_md.policer.stats_id = stats_id; eg_md.qos.acl_meter_index = meter_id; eg_md.policer.bypass = eg_md.policer.bypass | group; eg_md.policer.drop = eg_md.policer.drop | set_drop; eg_md.qos.set_dscp = set_dscp; eg_md.flags.is_pbr_nhop = set_nexthop; eg_md.route.pbr_nexthop = nexthop; eg_md.route.pbr_is_ecmp = is_ecmp; eg_md.route.pbr_priority = nh_priority; eg_md.route.pbr_level = level; eg_md.qos.dscp = dscp; }
    @ignore_table_dependency("Eg_uplink.acl.ipv4_acl1.acl")
    @ignore_table_dependency("Eg_uplink.acl.ipv4_acl2.acl")
    @ignore_table_dependency("Eg_uplink.acl.ipv4_acl3.acl")
    @stage(6)
    table acl {
        key = {
            hdr.ipv6.src_addr : ternary @name("ip_src_addr"); hdr.ipv6.dst_addr : ternary @name("ip_dst_addr"); eg_md.lkp.ip_proto : ternary @name("ip_proto"); hdr.ipv6.traffic_class : ternary @name("ip_tos"); eg_md.policer.bypass : ternary @name("bypass"); group_classid : ternary @name("group_classid"); eg_md.lkp.l4_src_port : ternary @name("l4_src_port"); eg_md.lkp.l4_dst_port : ternary @name("l4_dst_port"); eg_md.lkp.l4_port_label_64 : ternary @name("l4_port_label"); eg_md.lkp.tcp_flags[5:0] : ternary @name("tcp_flags");
        }
        actions = {
            set_pbr;
        }
        size = table_size;
    }
    apply {
        if (hdr.ipv6.isValid()) {
            acl.apply();
        }
    }
}

//-----------------------------------------------------------------------------
// Uplink Egress ACL Action Resolve
//-----------------------------------------------------------------------------
control uplink_eg_action_resolve(inout switch_header_t hdr,
                    inout switch_egress_metadata_t eg_md) (
                    switch_uint32_t stats_size = 9216,
                    switch_uint32_t meter_size = 9216) {

    Counter<bit<64>, bit<14>>(stats_size, CounterType_t.PACKETS) stats;
    Meter<bit<14>>(meter_size, MeterType_t.BYTES) meter;

    action ipv4_dscp() {
        hdr.ipv4.diffserv[7:2] = eg_md.qos.dscp;
        eg_md.qos.chgDSCP_disable = 1;
    }

    action ipv6_dscp() {
        hdr.ipv6.traffic_class[7:2] = eg_md.qos.dscp;
        eg_md.qos.chgDSCP_disable = 1;
    }

    table chg_dscp{
        key = {
            eg_md.qos.set_dscp : exact;
            hdr.ipv4.isValid() : exact;
            hdr.ipv6.isValid() : exact;
        }
        actions = {
            ipv4_dscp;
            ipv6_dscp;
        }
        size = 2;
        // const entries = {
        //     (1, true, false) : ipv4_dscp();
        //     (1, false, true) : ipv6_dscp();
        // }
    }

    action exec_count() {
        stats.count(eg_md.policer.stats_id);
    }
    table count {
        // keyless
        actions = {
            exec_count;
        }
        default_action = exec_count();
    }

    action exec_meter() {
        eg_md.policer.meter_color = (bit<2>)meter.execute(eg_md.qos.acl_meter_index);
    }
    table acl_meter {
        key = {
            eg_md.qos.car_flag : exact;
        }
        actions = {
            NoAction;
            exec_meter;
        }
        size = 2;
        // const entries = {
        //     (0) : exec_meter();
        //     (1) : NoAction();
        // }
    }

    apply {
        chg_dscp.apply();
        count.apply();
        acl_meter.apply();
    }
}

control uplink_eg_acl(inout switch_header_t hdr,
                    inout switch_egress_metadata_t eg_md) {

    uplink_eg_ipv4_acl1(2048) ipv4_acl1;
    uplink_eg_ipv4_acl2(2048) ipv4_acl2;
    uplink_eg_ipv4_acl3(2048) ipv4_acl3;
    uplink_eg_ipv6_acl1(1024) ipv6_acl1;
    uplink_eg_ipv6_acl2(1024) ipv6_acl2;
    uplink_eg_ipv6_acl3(1024) ipv6_acl3;
    uplink_eg_action_resolve(7168, 7168) action_resolve;

    apply {
        ipv6_acl1.apply(hdr, eg_md.policer.slice1.group, eg_md.policer.slice1.group_classid, eg_md);
        ipv4_acl1.apply(hdr, eg_md.policer.slice1.group, eg_md.policer.slice1.group_classid, eg_md);
        ipv6_acl2.apply(hdr, eg_md.policer.slice2.group, eg_md.policer.slice2.group_classid, eg_md);
        ipv6_acl3.apply(hdr, eg_md.policer.slice3.group, eg_md.policer.slice3.group_classid, eg_md);
        ipv4_acl2.apply(hdr, eg_md.policer.slice2.group, eg_md.policer.slice2.group_classid, eg_md);
        // ipv4_acl3.apply(hdr, eg_md.policer.slice3.group, eg_md.policer.slice3.group_classid, eg_md); //for power

        action_resolve.apply(hdr, eg_md);
    }
}

//-----------------------------------------------------------------------------
// Inner Ingress System ACL
//-----------------------------------------------------------------------------
control UplinkIngressSystemAcl(
        inout switch_header_t hdr,
        inout switch_ingress_metadata_t ig_md,
        in ingress_intrinsic_metadata_t ig_intr_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm,
        inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr)(
        switch_uint32_t table_size=512) {

    Counter<bit<64>, bit<16>>(1024, CounterType_t.PACKETS) sys_stats;

    action drop(bit<16> stats_id, bit<8> drop_reason) {
        ig_md.flags.drop = 1;
        sys_stats.count(stats_id);
        ig_md.common.drop_reason = drop_reason;
    }

    action forward(bit<16> stats_id) {
        sys_stats.count(stats_id);
    }
    @placement_priority(127)
    @stage(7)
    table system_acl {
        key = {
            ig_md.common.iif : ternary;
            ig_md.flags.drop : ternary; /* 防止重复计数 */
            ig_md.common.drop_reason : ternary;
            ig_md.route.nexthop_cmd : ternary;
         // ig_md.flags.static_mac_move_drop : ternary;
            ig_md.flags.lag_miss : ternary;
        }

        actions = {
            drop;
            forward;
        }

        const default_action = forward((bit<16>)SWITCH_DROP_REASON_FORWARD);
        size = table_size;
    }

    apply {
        if (ig_md.flags.escape_etm == 0) {
            system_acl.apply();
        }
    }
}

//-----------------------------------------------------------------------------
// Inner Egress System ACL
//-----------------------------------------------------------------------------
control UplinkEgressSystemAcl(
        inout switch_header_t hdr,
        inout switch_egress_metadata_t eg_md,
        in egress_intrinsic_metadata_t eg_intr_md,
        inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr) {

    const switch_uint32_t host_acl_table_size = 512;
    const switch_uint32_t sys_acl_table_size = 512;
    Counter<bit<64>, bit<16>>(host_acl_table_size, CounterType_t.PACKETS) host_stats;
    Counter<bit<64>, bit<16>>(1024, CounterType_t.PACKETS) sys_stats;
    Counter<bit<64>, bit<8>>(256, CounterType_t.PACKETS) port_stats;

    bit<16> etype;

    action set_vlan1_etype() {
        etype = hdr.vlan_tag[1].ether_type;
    }
    action set_vlan0_etype() {
        etype = hdr.vlan_tag[0].ether_type;
    }
    action set_ether_etype() {
        etype = hdr.ethernet.ether_type;
    }
    action set_value(bit<16> etype_value) {
        etype = etype_value;
    }
    @placement_priority(127)
    table get_etype {
        key = {
            hdr.vlan_tag[1].isValid() : exact;
            hdr.vlan_tag[0].isValid() : exact;
            hdr.ethernet.isValid() : exact;
            hdr.ipv4.isValid() : exact;
            hdr.ipv6.isValid() : exact;
            hdr.mpls_ig[0].isValid() : exact;
        }
        actions = {
            set_vlan1_etype;
            set_vlan0_etype;
            set_ether_etype;
            set_value;
        }
        size = 128;
        const entries = {
            ( true, true, true, true, true, true) : set_vlan1_etype();
            ( true, true, true, true, true, false) : set_vlan1_etype();
            ( true, true, true, true, false, true) : set_vlan1_etype();
            ( true, true, true, true, false, false) : set_vlan1_etype();
            ( true, true, true, false, true, true) : set_vlan1_etype();
            ( true, true, true, false, true, false) : set_vlan1_etype();
            ( true, true, true, false, false, true) : set_vlan1_etype();
            ( true, true, true, false, false, false) : set_vlan1_etype();
            ( true, true, false, true, true, true) : set_vlan1_etype();
            ( true, true, false, true, true, false) : set_vlan1_etype();
            ( true, true, false, true, false, true) : set_vlan1_etype();
            ( true, true, false, true, false, false) : set_vlan1_etype();
            ( true, true, false, false, true, true) : set_vlan1_etype();
            ( true, true, false, false, true, false) : set_vlan1_etype();
            ( true, true, false, false, false, true) : set_vlan1_etype();
            ( true, true, false, false, false, false) : set_vlan1_etype();
            ( true, false, true, true, true, true) : set_vlan1_etype();
            ( true, false, true, true, true, false) : set_vlan1_etype();
            ( true, false, true, true, false, true) : set_vlan1_etype();
            ( true, false, true, true, false, false) : set_vlan1_etype();
            ( true, false, true, false, true, true) : set_vlan1_etype();
            ( true, false, true, false, true, false) : set_vlan1_etype();
            ( true, false, true, false, false, true) : set_vlan1_etype();
            ( true, false, true, false, false, false) : set_vlan1_etype();
            ( true, false, false, true, true, true) : set_vlan1_etype();
            ( true, false, false, true, true, false) : set_vlan1_etype();
            ( true, false, false, true, false, true) : set_vlan1_etype();
            ( true, false, false, true, false, false) : set_vlan1_etype();
            ( true, false, false, false, true, true) : set_vlan1_etype();
            ( true, false, false, false, true, false) : set_vlan1_etype();
            ( true, false, false, false, false, true) : set_vlan1_etype();
            ( true, false, false, false, false, false) : set_vlan1_etype();
            (false, true, true, true, true, true) : set_vlan0_etype();
            (false, true, true, true, true, false) : set_vlan0_etype();
            (false, true, true, true, false, true) : set_vlan0_etype();
            (false, true, true, true, false, false) : set_vlan0_etype();
            (false, true, true, false, true, true) : set_vlan0_etype();
            (false, true, true, false, true, false) : set_vlan0_etype();
            (false, true, true, false, false, true) : set_vlan0_etype();
            (false, true, true, false, false, false) : set_vlan0_etype();
            (false, true, false, true, true, true) : set_vlan0_etype();
            (false, true, false, true, true, false) : set_vlan0_etype();
            (false, true, false, true, false, true) : set_vlan0_etype();
            (false, true, false, true, false, false) : set_vlan0_etype();
            (false, true, false, false, true, true) : set_vlan0_etype();
            (false, true, false, false, true, false) : set_vlan0_etype();
            (false, true, false, false, false, true) : set_vlan0_etype();
            (false, true, false, false, false, false) : set_vlan0_etype();
            (false, false, true, true, true, true) : set_ether_etype();
            (false, false, true, true, true, false) : set_ether_etype();
            (false, false, true, true, false, true) : set_ether_etype();
            (false, false, true, true, false, false) : set_ether_etype();
            (false, false, true, false, true, true) : set_ether_etype();
            (false, false, true, false, true, false) : set_ether_etype();
            (false, false, true, false, false, true) : set_ether_etype();
            (false, false, true, false, false, false) : set_ether_etype();
            (false, false, false, true, true, true) : set_value(0x0800);
            (false, false, false, true, true, false) : set_value(0x0800);
            (false, false, false, true, false, true) : set_value(0x0800);
            (false, false, false, true, false, false) : set_value(0x0800);
            (false, false, false, false, true, true) : set_value(0x86dd);
            (false, false, false, false, true, false) : set_value(0x86dd);
            (false, false, false, false, false, true) : set_value(0x8847);
            (false, false, false, false, false, false) : set_value(0);
        }
    }

    action copy_to_cpu(bit<8> reason_code, bit<16> stats_id) {
        eg_md.flags.glean = 1;
        eg_md.common.cpu_reason = reason_code;
        host_stats.count(stats_id);
    }

    action redirect_to_cpu(bit<8> reason_code, bit<16> stats_id) {
        copy_to_cpu(reason_code, stats_id);
        eg_md.flags.drop = 1;
        eg_md.common.drop_reason = 0;
    }

    action set_track(bit<1> track) {
        eg_md.common.track = track;
    }
    @placement_priority(80)
    table host_acl {
        key = {
            eg_md.common.pkt_type : ternary; /* ipfix spec */
            eg_md.common.src_port : ternary; // for EFM
            eg_md.common.iif : ternary @name("iif");
            eg_md.common.iif_classid : ternary @name("iif_classid");
            eg_md.ebridge.evlan_classid : ternary @name("evlan_classid");
            eg_md.route.dip_l3class_id : ternary;
            eg_md.route.rmac_hit : ternary; /* l3_cpp */
            eg_md.stp.state : ternary;
            eg_md.lkp.ip_type : ternary;
            eg_md.lkp.ip_options : ternary; /* 带扩展头 */
            etype : ternary;
            hdr.ethernet.isValid() : ternary;
            hdr.ethernet.dst_addr : ternary;
            hdr.ipv4.isValid() : ternary;
            hdr.ipv4.ttl : ternary;
            // hdr.ipv4.protocol : ternary;
            hdr.ipv4.dst_addr : ternary;
            hdr.ipv6.isValid() : ternary;
            hdr.ipv6.hop_limit : ternary;
            //hdr.ipv6.next_hdr : ternary;
            eg_md.lkp.ip_proto : ternary @name("ip_proto");
            hdr.ipv6.dst_addr : ternary;
            eg_md.lkp.l4_src_port : ternary;
            eg_md.lkp.l4_dst_port : ternary;
            // hdr.icmp.isValid() : ternary;   /* icmp.typeCode和l4_src_port复用 */
            // hdr.icmp.typeCode[15:8] : ternary;
            // hdr.tcp.isValid() : ternary;
            eg_md.lkp.tcp_flags : ternary;
            hdr.mpls_ig[0].isValid() : ternary;
            hdr.mpls_ig[0].label : ternary;
            hdr.mpls_ig[0].ttl : ternary;
            eg_md.tunnel.type : ternary;
            eg_md.tunnel.srv6_end_type : ternary;
        }
        actions = {
            @defaultonly NoAction;
            copy_to_cpu;
            redirect_to_cpu;
            set_track;
        }
        size = host_acl_table_size;
        default_action = NoAction;
    }

    action drop(bit<16> stats_id, bit<8> drop_reason) {
        eg_md.flags.drop = 1;
        sys_stats.count(stats_id);
        eg_md.common.drop_reason = drop_reason;
    }

    action forward(bit<16> stats_id) {
        sys_stats.count(stats_id);
        eg_md.common.drop_reason = 0;
    }

    table system_acl {
        key = {
            eg_md.policer.iif : ternary;
            eg_md.policer.drop : ternary;
            eg_md.policer.meter_color : ternary;
            // eg_md.flags.dmac_miss : ternary;
            eg_md.flags.static_mac_move_drop : ternary;//by xiachangkai 
            eg_md.common.drop_reason : ternary;
            eg_md.qos.storm_control_color : ternary; //by linweilong
            eg_md.qos.car_flag : ternary; //car drop flag from front
            eg_md.ebridge.checks.same_if : ternary;
            eg_md.flags.bh_dmac_hit : ternary;
        }
        actions = {
            drop;
            forward;

        }
        const default_action = forward((bit<16>)(bit<16>)SWITCH_DROP_REASON_FORWARD);
        size = sys_acl_table_size;
    }

    action exec_drop() {
        eg_intr_md_for_dprsr.drop_ctl = 0x1;
    }
    table pkt_drop {
        // keyless
        actions = {
            exec_drop;
        }
        default_action = exec_drop();
    }

    action count() {
        port_stats.count(eg_md.common.src_port);
    }
    table port_count {
        // keyless
        actions = {
            count;
        }
        default_action = count();
    }

    apply {
        // acl_drop_reason = 0;

        get_etype.apply();
        switch(host_acl.apply().action_run) {
            redirect_to_cpu: {}
            default: {
                if (eg_md.flags.escape_etm == 0) {
                    system_acl.apply();
                }
            }
        }
        if (eg_md.flags.drop == 1 && eg_md.flags.glean == 0) {
            pkt_drop.apply();
        }
        if (eg_md.common.drop_reason != 0) {
            port_count.apply();
        }
    }
}

//-----------------------------------------------------------------------------
// Inner Egress System ACL
//-----------------------------------------------------------------------------
control UplinkEgressNdcheck(
        inout switch_header_t hdr,
        inout switch_egress_metadata_t eg_md) {

    /* ND check ICMP_TYPE=133-137 */
    action set_nd_flag() {
        eg_md.flags.nd_flag = 1;
    }
    table nd_check {
        key = {
            hdr.ipv6.isValid(): exact;
            eg_md.lkp.ip_proto : exact;
            eg_md.lkp.l4_src_port[15:8] : exact @name("icmp_type");
        }
        actions = {
            NoAction;
            set_nd_flag;
        }
        size = 1024;
        default_action = NoAction();
        // const entries = {
            // (true, 58, 133) : set_nd_flag();
            // (true, 58, 134) : set_nd_flag();
            // (true, 58, 135) : set_nd_flag();
            // (true, 58, 136) : set_nd_flag();
            // (true, 58, 137) : set_nd_flag();
        // }
    }
    apply {
        nd_check.apply();
    }
}
# 203 "/mnt/p4c-4127/p4src/switch-tofino2/switch_tofino_x1.p4" 2
# 1 "/mnt/p4c-4127/p4src/shared/acl_downlink.p4" 1
//-----------------------------------------------------------------------------
// Downlink Ingress ACL key.
//-----------------------------------------------------------------------------
# 27 "/mnt/p4c-4127/p4src/shared/acl_downlink.p4"
//-----------------------------------------------------------------------------
// Downlink Egress ACL key.
//-----------------------------------------------------------------------------
# 52 "/mnt/p4c-4127/p4src/shared/acl_downlink.p4"
//-----------------------------------------------------------------------------
// Common Downlink Ingress ACL actions.
//-----------------------------------------------------------------------------







control downlink_ig_ip_frag(in switch_header_t hdr, inout switch_ingress_metadata_t ig_md) {

    action set_ip_frag(switch_ip_frag_t ip_frag) {
        ig_md.lkp.ip_frag = ip_frag;
    }

    action set_ip_proto() {
        ig_md.lkp.ip_proto = hdr.ipv6_frag.next_hdr;
    }

    table get_ip_frag {
        key = {
            hdr.ipv6_frag.isValid() : exact;
            hdr.ipv4.isValid() : exact;
            hdr.ipv4.flags : ternary;
            hdr.ipv4.frag_offset : ternary;
        }
        actions = {
            set_ip_frag;
            set_ip_proto;
        }
        size = 8;
        default_action = set_ip_frag(SWITCH_IP_FRAG_NON_FRAG);
        // const entries = {
        //     (true, false, _, _) : set_ip_proto();
        //     (false, true, 0 &&& 1, 0) : set_ip_frag(SWITCH_IP_FRAG_NON_FRAG);
        //     (false, true, 1 &&& 1, 0) : set_ip_frag(SWITCH_IP_FRAG_HEAD);
        //     (false, true, _, _) : set_ip_frag(SWITCH_IP_FRAG_NON_HEAD);
        // }
    }
    apply {
        get_ip_frag.apply();
    }
}

//-----------------------------------------------------------------------------
// Downlink Ingress ACL Pre-calculated
// ACL匹配前，对相关参数进行预计算
//-----------------------------------------------------------------------------
control downlink_ig_acl_pre(inout switch_header_t hdr,
            inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm,
            inout switch_ingress_metadata_t ig_md) (
            switch_uint32_t table_size = 128) {

    downlink_ig_ip_frag() ip_frag;

    action set_properties (
            switch_acl_classid_t classid_1,
            switch_acl_classid_t classid_2,
            switch_acl_classid_t classid_3) {
        hdr.bridged_md_910_encap.group_classid_1 = classid_1;
        hdr.bridged_md_910_encap.group_classid_2 = classid_2;
        hdr.bridged_md_910_encap.group_classid_3 = classid_3;
        ig_md.policer.slice1.group = SWITCH_ACL_BYPASS_1;
    }

    @use_hash_action(1)
    table oif_properties {
        key = {
            hdr.ipv6.isValid() : exact;
            ig_md.common.oif : exact @name("oif");
        }
        actions = {
            set_properties;
        }
        default_action = set_properties(0, 0, 0);
        size = 32 * 1024;
    }

    action set_src_port_label(bit<32> label) {
        hdr.bridged_md_910_encap.l4_port_label_32 = label;
    }

    action set_dst_port_label(bit<32> label) {
        hdr.bridged_md_910_encap.l4_port_label_32 = hdr.bridged_md_910_encap.l4_port_label_32 | label;
    }

    @entries_with_ranges(table_size)
    table l4_dst_port {
        key = {
            hdr.ipv4.isValid() : exact;
            hdr.ipv6.isValid() : exact;
            ig_md.lkp.l4_dst_port : range;
        }
        actions = {
            NoAction;
            set_dst_port_label;
        }
        const default_action = NoAction;
        size = table_size;
    }

    @entries_with_ranges(table_size)
    table l4_src_port {
        key = {
            hdr.ipv4.isValid() : exact;
            hdr.ipv6.isValid() : exact;
            ig_md.lkp.l4_src_port : range;
        }
        actions = {
            NoAction;
            set_src_port_label;
        }
        const default_action = set_src_port_label(0);
        size = table_size;
    }

    apply {
        oif_properties.apply();
        l4_src_port.apply();
        l4_dst_port.apply();
        ip_frag.apply(hdr, ig_md);
    }
}

control downlink_ig_ipv4_acl1(inout switch_header_t hdr,
                    in switch_acl_bypass_t group,
                    in switch_acl_classid_t group_classid,
                    inout switch_ingress_metadata_t ig_md) (
                    switch_uint32_t table_size = 2048) {
    Counter<bit<64>, bit<16>>(table_size, CounterType_t.PACKETS) stats;

    action set_acl(bit<16> stats_id, bool set_drop) { stats.count(stats_id); ig_md.policer.bypass = ig_md.policer.bypass | group; ig_md.flags.drop = (bit<1>)set_drop; }
    // @stage(2)
    table acl {
        key = {
            hdr.ipv4.src_addr : ternary @name("ip_src_addr"); hdr.ipv4.dst_addr : ternary @name("ip_dst_addr"); hdr.ipv4.protocol : ternary @name("ip_proto"); hdr.ipv4.diffserv : ternary @name("ip_tos"); ig_md.lkp.ip_frag : ternary @name("ip_frag"); ig_md.policer.bypass : ternary @name("bypass"); group_classid : ternary @name("group_classid"); ig_md.lkp.l4_src_port : ternary @name("l4_src_port"); ig_md.lkp.l4_dst_port : ternary @name("l4_dst_port"); hdr.bridged_md_910_encap.l4_port_label_32 : ternary @name("l4_port_label"); ig_md.lkp.tcp_flags[5:0] : ternary @name("tcp_flags");
        }
        actions = {
            set_acl;
        }
        size = table_size;
    }
    apply {
        if (hdr.ipv4.isValid()) {
            acl.apply();
        }
    }
}

control downlink_ig_ipv4_acl2(inout switch_header_t hdr,
                    in switch_acl_bypass_t group,
                    in switch_acl_classid_t group_classid,
                    inout switch_ingress_metadata_t ig_md) (
                    switch_uint32_t table_size = 2048) {
    Counter<bit<64>, bit<16>>(table_size, CounterType_t.PACKETS) stats;

    action set_acl(bit<16> stats_id, bool set_drop) { stats.count(stats_id); ig_md.policer.bypass = ig_md.policer.bypass | group; ig_md.flags.drop = (bit<1>)set_drop; }

    // @stage(4)
    table acl {
        key = {
            hdr.ipv4.src_addr : ternary @name("ip_src_addr"); hdr.ipv4.dst_addr : ternary @name("ip_dst_addr"); hdr.ipv4.protocol : ternary @name("ip_proto"); hdr.ipv4.diffserv : ternary @name("ip_tos"); ig_md.lkp.ip_frag : ternary @name("ip_frag"); ig_md.policer.bypass : ternary @name("bypass"); group_classid : ternary @name("group_classid"); ig_md.lkp.l4_src_port : ternary @name("l4_src_port"); ig_md.lkp.l4_dst_port : ternary @name("l4_dst_port"); hdr.bridged_md_910_encap.l4_port_label_32 : ternary @name("l4_port_label"); ig_md.lkp.tcp_flags[5:0] : ternary @name("tcp_flags");
        }
        actions = {
            set_acl;
        }
        size = table_size;
    }
    apply {
        if (hdr.ipv4.isValid()) {
            acl.apply();
        }
    }
}

control downlink_ig_ipv4_acl3(inout switch_header_t hdr,
                    in switch_acl_bypass_t group,
                    in switch_acl_classid_t group_classid,
                    inout switch_ingress_metadata_t ig_md) (
                    switch_uint32_t table_size = 2048) {
    Counter<bit<64>, bit<16>>(table_size, CounterType_t.PACKETS) stats;

    action set_acl(bit<16> stats_id, bool set_drop) { stats.count(stats_id); ig_md.policer.bypass = ig_md.policer.bypass | group; ig_md.flags.drop = (bit<1>)set_drop; }

    // @stage(6)
    table acl {
        key = {
            hdr.ipv4.src_addr : ternary @name("ip_src_addr"); hdr.ipv4.dst_addr : ternary @name("ip_dst_addr"); hdr.ipv4.protocol : ternary @name("ip_proto"); hdr.ipv4.diffserv : ternary @name("ip_tos"); ig_md.lkp.ip_frag : ternary @name("ip_frag"); ig_md.policer.bypass : ternary @name("bypass"); group_classid : ternary @name("group_classid"); ig_md.lkp.l4_src_port : ternary @name("l4_src_port"); ig_md.lkp.l4_dst_port : ternary @name("l4_dst_port"); hdr.bridged_md_910_encap.l4_port_label_32 : ternary @name("l4_port_label"); ig_md.lkp.tcp_flags[5:0] : ternary @name("tcp_flags");
        }
        actions = {
            set_acl;
        }
        size = table_size;
    }
    apply {
        if (hdr.ipv4.isValid()) {
            acl.apply();
        }
    }
}

control downlink_ig_ipv4_acl4(inout switch_header_t hdr,
                    in switch_acl_bypass_t group,
                    in switch_acl_classid_t group_classid,
                    inout switch_ingress_metadata_t ig_md) (
                    switch_uint32_t table_size = 2048) {
    Counter<bit<64>, bit<16>>(table_size, CounterType_t.PACKETS) stats;

    action set_acl(bit<16> stats_id, bool set_drop) { stats.count(stats_id); ig_md.policer.bypass = ig_md.policer.bypass | group; ig_md.flags.drop = (bit<1>)set_drop; }

    // @stage(8)
    table acl {
        key = {
            hdr.ipv4.src_addr : ternary @name("ip_src_addr"); hdr.ipv4.dst_addr : ternary @name("ip_dst_addr"); hdr.ipv4.protocol : ternary @name("ip_proto"); hdr.ipv4.diffserv : ternary @name("ip_tos"); ig_md.lkp.ip_frag : ternary @name("ip_frag"); ig_md.policer.bypass : ternary @name("bypass"); group_classid : ternary @name("group_classid"); ig_md.lkp.l4_src_port : ternary @name("l4_src_port"); ig_md.lkp.l4_dst_port : ternary @name("l4_dst_port"); hdr.bridged_md_910_encap.l4_port_label_32 : ternary @name("l4_port_label"); ig_md.lkp.tcp_flags[5:0] : ternary @name("tcp_flags");
        }
        actions = {
            set_acl;
        }
        size = table_size;
    }
    apply {
        if (hdr.ipv4.isValid()) {
            acl.apply();
        }
    }
}

control downlink_ig_ipv6_acl1(inout switch_header_t hdr,
                    in switch_acl_bypass_t group,
                    in switch_acl_classid_t group_classid,
                    inout switch_ingress_metadata_t ig_md) (
                    switch_uint32_t table_size = 1024) {
    Counter<bit<64>, bit<16>>(table_size, CounterType_t.PACKETS) stats;

    action set_acl(bit<16> stats_id, bool set_drop) { stats.count(stats_id); ig_md.policer.bypass = ig_md.policer.bypass | group; ig_md.flags.drop = (bit<1>)set_drop; }

    // @stage(3)
    table acl {
        key = {
            hdr.ipv6.src_addr : ternary @name("ip_src_addr"); hdr.ipv6.dst_addr : ternary @name("ip_dst_addr"); ig_md.lkp.ip_proto : ternary @name("ip_proto"); hdr.ipv6.traffic_class : ternary @name("ip_tos"); ig_md.policer.bypass : ternary @name("bypass"); group_classid : ternary @name("group_classid"); ig_md.lkp.l4_src_port : ternary @name("l4_src_port"); ig_md.lkp.l4_dst_port : ternary @name("l4_dst_port"); hdr.bridged_md_910_encap.l4_port_label_32 : ternary @name("l4_port_label"); ig_md.lkp.tcp_flags[5:0] : ternary @name("tcp_flags");
        }
        actions = {
            set_acl;
        }
        size = table_size;
    }
    apply {
        if (hdr.ipv6.isValid()) {
            acl.apply();
        }
    }
}

control downlink_ig_ipv6_acl2(inout switch_header_t hdr,
                    in switch_acl_bypass_t group,
                    in switch_acl_classid_t group_classid,
                    inout switch_ingress_metadata_t ig_md) (
                    switch_uint32_t table_size = 1024) {
    Counter<bit<64>, bit<16>>(table_size, CounterType_t.PACKETS) stats;

    action set_acl(bit<16> stats_id, bool set_drop) { stats.count(stats_id); ig_md.policer.bypass = ig_md.policer.bypass | group; ig_md.flags.drop = (bit<1>)set_drop; }

    // @stage(5)
    table acl {
        key = {
            hdr.ipv6.src_addr : ternary @name("ip_src_addr"); hdr.ipv6.dst_addr : ternary @name("ip_dst_addr"); ig_md.lkp.ip_proto : ternary @name("ip_proto"); hdr.ipv6.traffic_class : ternary @name("ip_tos"); ig_md.policer.bypass : ternary @name("bypass"); group_classid : ternary @name("group_classid"); ig_md.lkp.l4_src_port : ternary @name("l4_src_port"); ig_md.lkp.l4_dst_port : ternary @name("l4_dst_port"); hdr.bridged_md_910_encap.l4_port_label_32 : ternary @name("l4_port_label"); ig_md.lkp.tcp_flags[5:0] : ternary @name("tcp_flags");
        }
        actions = {
            set_acl;
        }
        size = table_size;
    }
    apply {
        if (hdr.ipv6.isValid()) {
            acl.apply();
        }
    }
}

control downlink_ig_ipv6_acl3(inout switch_header_t hdr,
                    in switch_acl_bypass_t group,
                    in switch_acl_classid_t group_classid,
                    inout switch_ingress_metadata_t ig_md) (
                    switch_uint32_t table_size = 1024) {
    Counter<bit<64>, bit<16>>(table_size, CounterType_t.PACKETS) stats;

    action set_acl(bit<16> stats_id, bool set_drop) { stats.count(stats_id); ig_md.policer.bypass = ig_md.policer.bypass | group; ig_md.flags.drop = (bit<1>)set_drop; }

    // @stage(7)
    table acl {
        key = {
            hdr.ipv6.src_addr : ternary @name("ip_src_addr"); hdr.ipv6.dst_addr : ternary @name("ip_dst_addr"); ig_md.lkp.ip_proto : ternary @name("ip_proto"); hdr.ipv6.traffic_class : ternary @name("ip_tos"); ig_md.policer.bypass : ternary @name("bypass"); group_classid : ternary @name("group_classid"); ig_md.lkp.l4_src_port : ternary @name("l4_src_port"); ig_md.lkp.l4_dst_port : ternary @name("l4_dst_port"); hdr.bridged_md_910_encap.l4_port_label_32 : ternary @name("l4_port_label"); ig_md.lkp.tcp_flags[5:0] : ternary @name("tcp_flags");
        }
        actions = {
            set_acl;
        }
        size = table_size;
    }
    apply {
        if (hdr.ipv6.isValid()) {
            acl.apply();
        }
    }
}

control downlink_ig_ipv6_acl4(inout switch_header_t hdr,
                    in switch_acl_bypass_t group,
                    in switch_acl_classid_t group_classid,
                    inout switch_ingress_metadata_t ig_md) (
                    switch_uint32_t table_size = 1024) {
    Counter<bit<64>, bit<16>>(table_size, CounterType_t.PACKETS) stats;

    action set_acl(bit<16> stats_id, bool set_drop) { stats.count(stats_id); ig_md.policer.bypass = ig_md.policer.bypass | group; ig_md.flags.drop = (bit<1>)set_drop; }

    // @stage(9)
    table acl {
        key = {
            hdr.ipv6.src_addr : ternary @name("ip_src_addr"); hdr.ipv6.dst_addr : ternary @name("ip_dst_addr"); ig_md.lkp.ip_proto : ternary @name("ip_proto"); hdr.ipv6.traffic_class : ternary @name("ip_tos"); ig_md.policer.bypass : ternary @name("bypass"); group_classid : ternary @name("group_classid"); ig_md.lkp.l4_src_port : ternary @name("l4_src_port"); ig_md.lkp.l4_dst_port : ternary @name("l4_dst_port"); hdr.bridged_md_910_encap.l4_port_label_32 : ternary @name("l4_port_label"); ig_md.lkp.tcp_flags[5:0] : ternary @name("tcp_flags");
        }
        actions = {
            set_acl;
        }
        size = table_size;
    }
    apply {
        if (hdr.ipv6.isValid()) {
            acl.apply();
        }
    }
}

control downlink_eg_inner_ip_frag(in switch_header_t hdr, inout switch_egress_metadata_t eg_md) {
    action set_ip_frag(switch_ip_frag_t ip_frag) {
        eg_md.lkp.ip_frag = ip_frag;
    }

    table get_ip_frag {
        key = {
            hdr.inner_ipv4.isValid() : exact;
            hdr.inner_ipv4.flags : ternary;
            hdr.inner_ipv4.frag_offset : ternary;
        }
        actions = {
            set_ip_frag;
        }
        size = 8;
        default_action = set_ip_frag(SWITCH_IP_FRAG_NON_FRAG);
        // const entries = {
        //     (true, 0 &&& 1, 0) : set_ip_frag(SWITCH_IP_FRAG_NON_FRAG);
        //     (true, 1 &&& 1, 0) : set_ip_frag(SWITCH_IP_FRAG_HEAD);
        //     (true, _, _) : set_ip_frag(SWITCH_IP_FRAG_NON_HEAD);
        // }
    }
    apply {
        get_ip_frag.apply();
    }
}

//-----------------------------------------------------------------------------
// Downlink Egress Pre-calculated
// ACL匹配前，对相关参数进行预计算
//-----------------------------------------------------------------------------
control downlink_eg_acl_pre(in switch_header_t hdr,
                inout switch_egress_metadata_t eg_md) {

    downlink_eg_inner_ip_frag() inner_ip_frag;

    action set_properties(switch_acl_classid_t classid_1) {
        eg_md.policer.group_classid_1 = classid_1;
    }

    @use_hash_action(1)
    table oif_properties {
        key = {
            hdr.inner_ipv6.isValid() : exact;
            eg_md.common.oif : exact @name("oif");
        }
        actions = {
            set_properties;
        }

        const default_action = set_properties(0);
        size = 32 * 1024;
    }

    action set_src_port_label(bit<32> label) {
        eg_md.lkp.l4_port_label_32 = label;
    }

    action set_dst_port_label(bit<32> label) {
        eg_md.lkp.l4_port_label_32 = eg_md.lkp.l4_port_label_32 | label;
    }

    @entries_with_ranges(64)
    table l4_dst_port {
        key = {
            hdr.inner_ipv6.isValid() : exact;
            eg_md.lkp.l4_dst_port : range;
        }
        actions = {
            NoAction;
            set_dst_port_label;
        }
        const default_action = NoAction;
        size = 64;
    }

    @entries_with_ranges(64)
    table l4_src_port {
        key = {
            hdr.inner_ipv6.isValid() : exact;
            eg_md.lkp.l4_src_port : range;
        }
        actions = {
            NoAction;
            set_src_port_label;
        }
        const default_action = NoAction;
        size = 64;
    }

    action bypass() {
        eg_md.flags.bypass_acl = 1;
    }
    table get_bypass {
        key = {
            eg_md.common.pkt_type : exact;
        }
        actions = {
            bypass;
            NoAction;
        }
        const default_action = NoAction;
        // const entries = {
        //     (FABRIC_PKT_TYPE_EOP) : bypass();
        //     (FABRIC_PKT_TYPE_ETH) : NoAction();
        // }
        size = 2;
    }

    apply {
        get_bypass.apply();
        oif_properties.apply();
        l4_src_port.apply();
        l4_dst_port.apply();
        inner_ip_frag.apply(hdr, eg_md);
    }
}


//-----------------------------------------------------------------------------
// Egress QPPB ACL
//-----------------------------------------------------------------------------
control downlink_eg_qppb_acl(inout switch_header_t hdr,
                            inout switch_egress_metadata_t eg_md) (
                            switch_uint32_t qppb_sip_table_size = 4096,
                            switch_uint32_t qppb_dip_table_size = 4096,
                            switch_uint32_t qppb_back_table_size = 512,
                            switch_uint32_t qppb_qos_table_size = 512) {

    Counter<bit<64>, bit<14>>(qppb_sip_table_size + qppb_dip_table_size, CounterType_t.PACKETS_AND_BYTES) flow_stats;
    Counter<bit<64>, bit<16>>(qppb_qos_table_size, CounterType_t.PACKETS) qos_stats;
    Meter<bit<16>>(qppb_qos_table_size, MeterType_t.BYTES) meter;

    /* 统计表 */
    action counter(bit<14> stats_id) {
        eg_md.policer.qppb_stats_id = stats_id;
    }

    table qppb_stats_sip {
        key = {
            hdr.inner_ipv4.isValid() : exact;
            hdr.inner_ipv6.isValid() : exact;
            eg_md.common.dst_port : exact;
            eg_md.route.sip_l3class_id : exact;
        }
        actions = {
            NoAction;
            counter;
        }
        const default_action = NoAction;
        size = qppb_sip_table_size;
    }

    table qppb_stats_dip {
        key = {
            hdr.inner_ipv4.isValid() : exact;
            hdr.inner_ipv6.isValid() : exact;
            eg_md.common.dst_port : exact;
            eg_md.route.dip_l3class_id : exact;
        }
        actions = {
            NoAction;
            counter;
        }
        const default_action = NoAction;
        size = qppb_dip_table_size;
    }

    table qppb_stats_back {
        key = {
            hdr.inner_ipv4.isValid() : exact;
            hdr.inner_ipv6.isValid() : exact;
            eg_md.common.dst_port : ternary;
            eg_md.route.sip_l3class_id : ternary;
            eg_md.route.dip_l3class_id : ternary;
        }
        actions = {
            NoAction;
            counter;
        }
        const default_action = NoAction;
        size = qppb_back_table_size;
    }

    action set_qos(bit<16> stats_id, bit<16> meter_id, bit<1> set_dscp, bit<6> dscp) {
        qos_stats.count(stats_id);
        eg_md.qos.qppb_meter_color = (bit<2>)meter.execute(meter_id);
        eg_md.qos.qppb_set_dscp = set_dscp;
        eg_md.qos.qppb_dscp = dscp;
    }

    table qppb_qos {
        key = {
            eg_md.common.oif : ternary @name("oif");
            eg_md.route.dip_l3class_id : ternary;
            eg_md.route.sip_l3class_id : ternary;
        }
        actions = {
            set_qos;
        }
        size = qppb_qos_table_size;
    }

    action exec_count() {
        flow_stats.count(eg_md.policer.qppb_stats_id);
    }
    table qppb_stats {
        // keyless
        actions = {
            exec_count;
        }
        default_action = exec_count();
    }

    apply {
        qppb_qos.apply();

        if (eg_md.qos.qppb_meter_color == SWITCH_METER_COLOR_RED) {}
        else if (qppb_stats_sip.apply().hit) {}
        else if (qppb_stats_dip.apply().hit) {}
        else {qppb_stats_back.apply();}
        qppb_stats.apply();
    }
}

//-----------------------------------------------------------------------------
// Egress QoS ACL
//-----------------------------------------------------------------------------
control downlink_eg_qos_acl(inout switch_header_t hdr,
                            inout switch_egress_metadata_t eg_md) (
                            switch_uint32_t ipv4_table_size = 1024,
                            switch_uint32_t ipv6_table_size = 512) {
    Counter<bit<64>, bit<16>>(ipv4_table_size, CounterType_t.PACKETS) ipv4_stats;
    Counter<bit<64>, bit<16>>(ipv6_table_size, CounterType_t.PACKETS) ipv6_stats;

    action set_ipv4_qos(bit<16> stats_id, bit<1> ace_mode, bit<14> meter_id, bit<3> drop_color,
            bit<1> set_dscp, bit<6> dscp) {
        ipv4_stats.count(stats_id);
        eg_md.qos.ace_mode = ace_mode;
        eg_md.qos.acl_meter_index = meter_id;
        eg_md.qos.drop_color = drop_color;
        eg_md.qos.acl_set_dscp = set_dscp;
        eg_md.qos.acl_dscp = dscp;
    }

    action set_ipv6_qos(bit<16> stats_id, bit<1> ace_mode, bit<14> meter_id, bit<3> drop_color,
            bit<1> set_dscp, bit<6> dscp) {
        ipv6_stats.count(stats_id);
        eg_md.qos.ace_mode = ace_mode;
        eg_md.qos.acl_meter_index = meter_id;
        eg_md.qos.drop_color = drop_color;
        eg_md.qos.acl_set_dscp = set_dscp;
        eg_md.qos.acl_dscp = dscp;
    }

    @ignore_table_dependency("Eg_downlink.qos_acl.ipv6_acl")
    table ipv4_acl {
        key = {
            hdr.inner_ipv4.src_addr : ternary @name("ip_src_addr"); hdr.inner_ipv4.dst_addr : ternary @name("ip_dst_addr"); hdr.inner_ipv4.protocol : ternary @name("ip_proto"); hdr.inner_ipv4.diffserv : ternary @name("ip_tos"); eg_md.lkp.ip_frag : ternary @name("ip_frag"); eg_md.policer.group_classid_1 : ternary @name("group_classid"); eg_md.lkp.l4_src_port : ternary @name("l4_src_port"); eg_md.lkp.l4_dst_port : ternary @name("l4_dst_port"); eg_md.lkp.l4_port_label_32 : ternary @name("l4_port_label"); eg_md.lkp.tcp_flags[5:0] : ternary @name("tcp_flags");
        }
        actions = {
            set_ipv4_qos;
        }
        size = ipv4_table_size;
    }

    @ignore_table_dependency("Eg_downlink.qos_acl.ipv4_acl")
    table ipv6_acl {
        key = {
            hdr.inner_ipv6.src_addr : ternary @name("ip_src_addr"); hdr.inner_ipv6.dst_addr : ternary @name("ip_dst_addr"); hdr.inner_ipv6.next_hdr : ternary @name("ip_proto"); hdr.inner_ipv6.traffic_class : ternary @name("ip_tos"); eg_md.policer.group_classid_1 : ternary @name("group_classid"); eg_md.lkp.l4_src_port : ternary @name("l4_src_port"); eg_md.lkp.l4_dst_port : ternary @name("l4_dst_port"); eg_md.lkp.l4_port_label_32 : ternary @name("l4_port_label"); eg_md.lkp.tcp_flags[5:0] : ternary @name("tcp_flags");
        }
        actions = {
            set_ipv6_qos;
        }
        size = ipv6_table_size;
    }

    apply {
        if (hdr.inner_ipv4.isValid() && eg_md.flags.bypass_acl == 0) {
            ipv4_acl.apply();
        } else if (hdr.inner_ipv6.isValid() && eg_md.flags.bypass_acl == 0) {
            ipv6_acl.apply();
        }
    }
}

control downlink_eg_acl_resolve(inout switch_header_t hdr,
                            inout switch_egress_metadata_t eg_md) {

    Meter<bit<14>>(16 * 1024, MeterType_t.BYTES) meter;

    action acl_set_inner_v4_dscp() {
        hdr.inner_ipv4.diffserv[7:2] = eg_md.qos.acl_dscp;
        eg_md.tunnel.inner_dscp = eg_md.qos.acl_dscp;
        eg_md.qos.chgDSCP_disable = 1;
    }
    action acl_set_inner_v6_dscp() {
        hdr.inner_ipv6.traffic_class[7:2] = eg_md.qos.acl_dscp;
        eg_md.tunnel.inner_dscp = eg_md.qos.acl_dscp;
        eg_md.qos.chgDSCP_disable = 1;
    }
    action qppb_set_inner_v4_dscp() {
        hdr.inner_ipv4.diffserv[7:2] = eg_md.qos.qppb_dscp;
        eg_md.tunnel.inner_dscp = eg_md.qos.qppb_dscp;
        eg_md.qos.chgDSCP_disable = 1;
    }
    action qppb_set_inner_v6_dscp() {
        hdr.inner_ipv6.traffic_class[7:2] = eg_md.qos.qppb_dscp;
        eg_md.tunnel.inner_dscp = eg_md.qos.qppb_dscp;
        eg_md.qos.chgDSCP_disable = 1;
    }
    table set_dscp {
        key = {
            eg_md.qos.qppb_set_dscp : exact;
            eg_md.qos.acl_set_dscp : exact;
            hdr.inner_ipv4.isValid() : exact;
            hdr.inner_ipv6.isValid() : exact;
        }
        actions = {
            qppb_set_inner_v4_dscp;
            qppb_set_inner_v6_dscp;
            acl_set_inner_v4_dscp;
            acl_set_inner_v6_dscp;
        }
        size = 16;
        const entries = {
            (1, 0, true, false) : qppb_set_inner_v4_dscp();
            (1, 0, false, true) : qppb_set_inner_v6_dscp();
            (1, 1, true, false) : qppb_set_inner_v4_dscp();
            (1, 1, false, true) : qppb_set_inner_v6_dscp();
            (0, 1, true, false) : acl_set_inner_v4_dscp();
            (0, 1, false, true) : acl_set_inner_v6_dscp();
        }
    }

    action class_mode(bit<14> meter_id) {
        eg_md.qos.acl_meter_index = meter_id;
    }
    action ace_mode() {
        eg_md.qos.acl_meter_color = (bit<2>) meter.execute(eg_md.qos.acl_meter_index);
    }
    table class_meter {
        key = {
            eg_md.qos.acl_meter_index : exact;
            eg_md.common.oif : exact;
        }
        actions = {
            @defaultonly NoAction;
            class_mode;
        }
        size = 20 * 1024;
        const default_action = NoAction();
    }

    table class_meter_back {
        key = {
            eg_md.qos.acl_meter_index : ternary;
            eg_md.common.oif : ternary;
        }
        actions = {
            NoAction;
            class_mode;
        }
        size = 512;
        default_action = class_mode(0);
    }

    table ace_meter {
        // keyless
        actions = {
            ace_mode;
        }
        default_action = ace_mode();
    }

    apply {
        set_dscp.apply();
        // if (eg_md.qos.ace_mode == 0) {
        //     if (!class_meter.apply().hit) {
        //         class_meter_back.apply();
        //     }
        // }
        // ace_meter.apply();
    }
}

control DownlinkIngressSystemAcl(
        inout switch_header_t hdr,
        inout switch_ingress_metadata_t ig_md,
        inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr)(
        switch_uint32_t table_size=512) {

    Counter<bit<64>, bit<16>>(1024, CounterType_t.PACKETS) stats;

    action drop(bit<16> stats_id, bit<8> drop_reason) {
        ig_intr_md_for_dprsr.drop_ctl = 0x1;
        stats.count(stats_id);
        ig_md.common.drop_reason = drop_reason;
    }
    action forward(bit<16> stats_id) {
        stats.count(stats_id);
        ig_md.common.drop_reason = 0;
    }
    table system_acl {
        key = {
            ig_md.common.oif : ternary;
            // hdr.drop_msg[0].isValid() : ternary;
            hdr.ethernet.isValid() : ternary;
            hdr.ethernet.src_addr : ternary;
            hdr.ethernet.dst_addr : ternary;
            hdr.ethernet.ether_type : ternary;
            ig_md.stp.state : ternary;
            ig_md.flags.vlan_member_check : ternary;
        }
        actions = {
            drop;
            forward;
        }
        const default_action = forward((bit<16>)SWITCH_DROP_REASON_FORWARD);
        size = table_size;
    }

    apply {
        if (ig_md.common.pkt_type != FABRIC_PKT_TYPE_FPGA_DROP && ig_md.common.pkt_type != FABRIC_PKT_TYPE_CPU_ETH &&
            ig_md.common.pkt_type != FABRIC_PKT_TYPE_CCM) {
            system_acl.apply();
        }
    }
}

control DownlinkEgressSystemAcl(inout switch_egress_metadata_t eg_md,
                inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr) (
                switch_uint32_t table_size=512) {
    Counter<bit<64>, bit<16>>(1024, CounterType_t.PACKETS) stats;
    Counter<bit<64>, bit<8>>(256, CounterType_t.PACKETS) port_stats;

    action drop(bit<16> stats_id, bit<8> drop_reason) {
        eg_intr_md_for_dprsr.drop_ctl = 0x1;
        stats.count(stats_id);
        eg_md.common.drop_reason = drop_reason;
    }

    action forward(bit<16> stats_id) {
        stats.count(stats_id);
    }

    table system_acl {
        key = {
            eg_md.common.oif : ternary;
            eg_md.common.dst_port : ternary;
            eg_md.common.drop_reason : ternary;
            eg_md.qos.lif_meter_color : ternary;
            eg_md.qos.qppb_meter_color : ternary;
            eg_md.qos.acl_meter_color : ternary;
            eg_md.qos.drop_color : ternary;
            eg_md.flags.horizon_split_drop_reason : ternary;
        }
        actions = {
            drop;
            forward;
        }
        const default_action = forward((bit<16>)SWITCH_DROP_REASON_FORWARD);
        size = table_size;
    }

    action count() {
        port_stats.count(eg_md.common.dst_port);
    }
    table port_count {
        // keyless
        actions = {
            count;
        }
        default_action = count();
    }

    apply {
        switch(system_acl.apply().action_run) {
            drop: {
                port_count.apply();
            }
        }
    }

}
# 204 "/mnt/p4c-4127/p4src/switch-tofino2/switch_tofino_x1.p4" 2
# 1 "/mnt/p4c-4127/p4src/shared/acl_fabric.p4" 1
//-----------------------------------------------------------------------------
// Fabric Egress ACL key.
//-----------------------------------------------------------------------------
# 27 "/mnt/p4c-4127/p4src/shared/acl_fabric.p4"
//-----------------------------------------------------------------------------
// Common Fabric Egress ACL actions.
//-----------------------------------------------------------------------------
# 38 "/mnt/p4c-4127/p4src/shared/acl_fabric.p4"
//-----------------------------------------------------------------------------
// Inner ACL Pre-calculated
// ACL匹配前，对相关参数进行预计算
//-----------------------------------------------------------------------------
control fabric_eg_acl_pre(in switch_header_t hdr,
            inout switch_egress_metadata_t eg_md) {

    action set_ip_frag(switch_ip_frag_t ip_frag) {
        eg_md.lkp.ip_frag = ip_frag;
    }
    action set_ipv6_frag_proto() {
        eg_md.lkp.ip_proto = hdr.ipv6_frag.next_hdr;
    }
    action set_ipv6_proto() {
        eg_md.lkp.ip_proto = hdr.ipv6.next_hdr;
    }
    @placement_priority(1)
    table ip_frag {
        key = {
            hdr.ipv6_frag.isValid() : exact;
            hdr.ipv6.isValid() : exact;
            hdr.ipv4.isValid() : exact;
            hdr.ipv4.flags : ternary;
            hdr.ipv4.frag_offset : ternary;
        }
        actions = {
            set_ip_frag;
            set_ipv6_frag_proto;
            set_ipv6_proto;
        }
        size = 8;
        default_action = set_ip_frag(SWITCH_IP_FRAG_NON_FRAG);
        const entries = {
            (true, true, false, _, _) : set_ipv6_frag_proto();
            (false, true, false, _, _) : set_ipv6_proto();
            (false, false, true, 0 &&& 1, 0) : set_ip_frag(SWITCH_IP_FRAG_NON_FRAG);
            (false, false, true, 1 &&& 1, 0) : set_ip_frag(SWITCH_IP_FRAG_HEAD);
            (false, false, true, _, _) : set_ip_frag(SWITCH_IP_FRAG_NON_HEAD);
        }
    }

    action set_properties (
            switch_acl_classid_t classid_1) {
        eg_md.policer.group_classid_1 = classid_1;
    }
    // @placement_priority(100)
    @use_hash_action(1)
    table iif_properties {
        key = {
            hdr.ipv6.isValid() : exact;
            eg_md.common.ul_iif : exact @name("iif");
        }
        actions = {
            set_properties;
        }
        default_action = set_properties(0);
        size = 32 * 1024;
    }


    action set_src_port_label(bit<64> label) {
        eg_md.lkp.l4_port_label_64 = label;
    }

    action set_dst_port_label(bit<64> label) {
        eg_md.lkp.l4_port_label_64 = eg_md.lkp.l4_port_label_64 | label;
    }

    @stage(1)
    @entries_with_ranges(128)
    table l4_dst_port {
        key = {
            hdr.ipv4.isValid() : exact;
            hdr.ipv6.isValid() : exact;
            eg_md.lkp.l4_dst_port : range;
        }
        actions = {
            NoAction;
            set_dst_port_label;
        }
        const default_action = NoAction;
        size = 128;
    }

    @stage(0)
    @entries_with_ranges(128)
    table l4_src_port {
        key = {
            hdr.ipv4.isValid() : exact;
            hdr.ipv6.isValid() : exact;
            eg_md.lkp.l4_src_port : range;
        }
        actions = {
            NoAction;
            set_src_port_label;
        }
        const default_action = NoAction;
        size = 128;
    }

    action get_common_iif() {
        eg_md.common.ul_iif = eg_md.common.iif;
    }
    action get_tunnel_iif() {
        eg_md.common.ul_iif = hdr.ext_tunnel_decap.ul_iif;
    }
    action get_l2_iif(bit<14> iif) {
        eg_md.common.ul_iif = iif;
    }
    table set_tunnel_iif {
        // keyless
        actions = {
            get_tunnel_iif;
        }
        default_action = get_tunnel_iif();
    }

    table set_common_iif {
        // keyless
        actions = {
            get_common_iif;
        }
        default_action = get_common_iif();
    }

    table set_l2_iif {
        key = {
            eg_md.common.src_port : exact @name("src_port");
        }
        actions = {
            get_l2_iif;
        }
        const default_action = get_l2_iif(0);
    }

    apply {
        if (hdr.ext_tunnel_decap.isValid() == true) {
            set_tunnel_iif.apply();
        } else if (eg_md.common.svi_flag == 1) {
            set_l2_iif.apply();
        } else {
            set_common_iif.apply();
        }

        l4_src_port.apply();
        l4_dst_port.apply();
        iif_properties.apply();
        ip_frag.apply();
    }
}


// -----------------------------------------------------------------------------
// Fabric Egress Ipv4 ACL
// -----------------------------------------------------------------------------
control fabric_eg_ipv4_acl(inout switch_header_t hdr,
                    in switch_acl_bypass_t group,
                    in switch_acl_classid_t group_classid,
                    inout switch_egress_metadata_t eg_md) (
                    switch_uint32_t table_size = 2048) {

    action set_acl(bit<14> stats_id, bit<1> set_drop) { eg_md.policer.stats_id = stats_id; eg_md.policer.bypass = eg_md.policer.bypass | group; eg_md.policer.drop = eg_md.policer.drop | set_drop; }

    @ignore_table_dependency("Eg_fabric.acl.ipv6_acl1.acl")
    @ignore_table_dependency("Eg_fabric.acl.ipv6_acl2.acl")
    @ignore_table_dependency("Eg_fabric.acl.ipv6_acl3.acl")
    @ignore_table_dependency("Eg_fabric.acl.ipv6_acl4.acl")
    // @placement_priority(128)
    table acl {
        key = {
            hdr.ipv4.src_addr : ternary @name("ip_src_addr"); hdr.ipv4.dst_addr : ternary @name("ip_dst_addr"); hdr.ipv4.protocol : ternary @name("ip_proto"); hdr.ipv4.diffserv : ternary @name("ip_tos"); eg_md.lkp.ip_frag : ternary @name("ip_frag"); eg_md.policer.bypass : ternary @name("bypass"); group_classid : ternary @name("group_classid"); eg_md.lkp.l4_src_port : ternary @name("l4_src_port"); eg_md.lkp.l4_dst_port : ternary @name("l4_dst_port"); eg_md.lkp.l4_port_label_64 : ternary @name("l4_port_label"); eg_md.lkp.tcp_flags[5:0] : ternary @name("tcp_flags");
        }
        actions = {
            set_acl;
        }
        size = table_size;
    }

    apply {
        if (hdr.ipv4.isValid()) {
            acl.apply();
        }
    }
}


//-----------------------------------------------------------------------------
// Fabric Egress Ipv6 ACL
//-----------------------------------------------------------------------------
control fabric_eg_ipv6_acl(inout switch_header_t hdr,
                    in switch_acl_bypass_t group,
                    in switch_acl_classid_t group_classid,
                    inout switch_egress_metadata_t eg_md) (
                    switch_uint32_t table_size = 1024) {

    action set_acl(bit<14> stats_id, bit<1> set_drop) { eg_md.policer.stats_id = stats_id; eg_md.policer.bypass = eg_md.policer.bypass | group; eg_md.policer.drop = eg_md.policer.drop | set_drop; }

    @ignore_table_dependency("Eg_fabric.acl.ipv4_acl1.acl")
    @ignore_table_dependency("Eg_fabric.acl.ipv4_acl2.acl")
    @ignore_table_dependency("Eg_fabric.acl.ipv4_acl3.acl")
    @ignore_table_dependency("Eg_fabric.acl.ipv4_acl4.acl")
    // @placement_priority(127)
    table acl {
        key = {
            hdr.ipv6.src_addr : ternary @name("ip_src_addr"); hdr.ipv6.dst_addr : ternary @name("ip_dst_addr"); eg_md.lkp.ip_proto : ternary @name("ip_proto"); hdr.ipv6.traffic_class : ternary @name("ip_tos"); eg_md.policer.bypass : ternary @name("bypass"); group_classid : ternary @name("group_classid"); eg_md.lkp.l4_src_port : ternary @name("l4_src_port"); eg_md.lkp.l4_dst_port : ternary @name("l4_dst_port"); eg_md.lkp.l4_port_label_64 : ternary @name("l4_port_label"); eg_md.lkp.tcp_flags[5:0] : ternary @name("tcp_flags");
        }
        actions = {
            set_acl;
        }
        size = table_size;
    }
    apply {
        if (hdr.ipv6.isValid()) {
            acl.apply();
        }
    }
}


control fabric_eg_acl(inout switch_header_t hdr,
                    inout switch_egress_metadata_t eg_md) {

    fabric_eg_ipv4_acl(2048) ipv4_acl1;
    fabric_eg_ipv4_acl(2048) ipv4_acl2;
    fabric_eg_ipv4_acl(2048) ipv4_acl3;
    fabric_eg_ipv4_acl(2048) ipv4_acl4;
    fabric_eg_ipv6_acl(1024) ipv6_acl1;
    fabric_eg_ipv6_acl(1024) ipv6_acl2;
    fabric_eg_ipv6_acl(1024) ipv6_acl3;
    fabric_eg_ipv6_acl(1024) ipv6_acl4;

    apply {
        ipv6_acl1.apply(hdr, SWITCH_ACL_BYPASS_1, eg_md.policer.group_classid_1, eg_md);
        ipv6_acl2.apply(hdr, SWITCH_ACL_BYPASS_1, eg_md.policer.group_classid_1, eg_md);
        ipv6_acl3.apply(hdr, SWITCH_ACL_BYPASS_1, eg_md.policer.group_classid_1, eg_md);
        ipv6_acl4.apply(hdr, SWITCH_ACL_BYPASS_1, eg_md.policer.group_classid_1, eg_md);
        ipv4_acl1.apply(hdr, SWITCH_ACL_BYPASS_1, eg_md.policer.group_classid_1, eg_md);
        ipv4_acl2.apply(hdr, SWITCH_ACL_BYPASS_1, eg_md.policer.group_classid_1, eg_md);
        ipv4_acl3.apply(hdr, SWITCH_ACL_BYPASS_1, eg_md.policer.group_classid_1, eg_md);
        ipv4_acl4.apply(hdr, SWITCH_ACL_BYPASS_1, eg_md.policer.group_classid_1, eg_md);
    }
}

//-----------------------------------------------------------------------------
// Fabric Egress ACL Action Resolve
//-----------------------------------------------------------------------------
control fabric_eg_acl_resolve(inout switch_egress_metadata_t eg_md) (
                    switch_uint32_t stats_size = 12288) {

    Counter<bit<64>, bit<14>>(stats_size, CounterType_t.PACKETS) stats;


    action exec_count() {
        stats.count(eg_md.policer.stats_id);
    }
    table count {
        // keyless
        actions = {
            exec_count;
        }
        default_action = exec_count();
    }

    apply {
        count.apply();
    }
}

control fabric_ip_to_lkp(inout switch_header_t hdr,
                            inout switch_egress_metadata_t eg_md) {

    /* change dscp */
    action ipv4_to_lkp() {
        // eg_md.lkp.ip_src_addr[31:0] = hdr.ipv4.src_addr;
        eg_md.lkp.ip_dst_addr[31:0] = hdr.ipv4.dst_addr;
        // eg_md.lkp.ip_proto = hdr.ipv4.protocol;
        eg_md.lkp.ip_tos = hdr.ipv4.diffserv;
        eg_md.lkp.ip_type = SWITCH_IP_TYPE_IPV4;
    }
    action ipv6_to_lkp() {
        // eg_md.lkp.ip_src_addr = hdr.ipv6.src_addr;
        eg_md.lkp.ip_dst_addr = hdr.ipv6.dst_addr;
        // eg_md.lkp.ip_proto = hdr.ipv6.next_hdr;
        eg_md.lkp.ip_tos = hdr.ipv6.traffic_class;
        eg_md.lkp.ip_type = SWITCH_IP_TYPE_IPV6;
    }
    table ip_to_lkp {
        key = {
            hdr.ipv4.isValid() : exact;
            hdr.ipv6.isValid() : exact;
        }
        actions = {
            ipv4_to_lkp;
            ipv6_to_lkp;
        }
        size = 2;
        // const entries = {
        //     (true, false) : ipv4_to_lkp();
        //     (false, true) : ipv6_to_lkp();
        // }
    }

    apply {
        ip_to_lkp.apply();
    }
}

control check_cpu_pkt(in egress_intrinsic_metadata_t eg_intr_md,
                      inout switch_egress_metadata_t eg_md) {

    action set_cpu_pkt() {
        eg_md.flags.cpu_pkt = 1;
    }
    table check {
        // keyless
        actions = {
            set_cpu_pkt;
        }
        const default_action = set_cpu_pkt();
    }

    apply {
        if (eg_intr_md.egress_port == 320) {
            check.apply();
        }
    }
}


control fabric_eg_qppb_acl(inout switch_header_t hdr,
                            inout switch_egress_metadata_t eg_md) (
                            switch_uint32_t qppb_sip_table_size = 4096,
                            switch_uint32_t qppb_dip_table_size = 4096,
                            switch_uint32_t qppb_back_table_size = 512,
                            switch_uint32_t qppb_qos_table_size = 512) {

    Counter<bit<64>, bit<14>>(qppb_sip_table_size + qppb_dip_table_size, CounterType_t.PACKETS_AND_BYTES) flow_stats;
    Counter<bit<64>, bit<16>>(qppb_qos_table_size, CounterType_t.PACKETS) qos_stats;
    Meter<bit<16>>(qppb_qos_table_size, MeterType_t.BYTES) meter;

    /* 统计表 */
    action counter(bit<14> stats_id) {
        eg_md.policer.qppb_stats_id = stats_id;
    }

    table qppb_stats_sip {
        key = {
            eg_md.lkp.ip_type : exact;
            eg_md.common.src_port : exact;
            eg_md.route.sip_l3class_id : exact;
        }
        actions = {
            NoAction;
            counter;
        }
        const default_action = NoAction;
        size = qppb_sip_table_size;
    }

    table qppb_stats_dip {
        key = {
            eg_md.lkp.ip_type : exact;
            eg_md.common.src_port : exact;
            eg_md.route.dip_l3class_id : exact;
        }
        actions = {
            NoAction;
            counter;
        }
        const default_action = NoAction;
        size = qppb_dip_table_size;
    }

    table qppb_stats_back {
        key = {
            eg_md.lkp.ip_type : exact;
            eg_md.common.src_port : ternary;
            eg_md.route.sip_l3class_id : ternary;
            eg_md.route.dip_l3class_id : ternary;
        }
        actions = {
            NoAction;
            counter;
        }
        const default_action = NoAction;
        size = qppb_back_table_size;
    }

    action set_qos(bit<16> stats_id, bit<16> meter_id, bit<1> set_dscp, bit<6> dscp) {
        qos_stats.count(stats_id);
        eg_md.qos.qppb_meter_color = (bit<2>)meter.execute(meter_id);
        eg_md.qos.qppb_set_dscp = set_dscp;
        eg_md.qos.qppb_dscp = dscp;
    }

    table qppb_qos {
        key = {
            eg_md.common.iif : ternary @name("iif");
            eg_md.route.dip_l3class_id : ternary;
            eg_md.route.sip_l3class_id : ternary;
        }
        actions = {
            set_qos;
        }
        size = qppb_qos_table_size;
    }

    /* change dscp */
    action ipv4_dscp() {
        hdr.ipv4.diffserv[7:2] = eg_md.qos.qppb_dscp;
        // eg_md.qos.chgDSCP_disable = 1;
        hdr.fabric_qos.chgDSCP_disable = 1;
    }
    action ipv6_dscp() {
        hdr.ipv6.traffic_class[7:2] = eg_md.qos.qppb_dscp;
        // eg_md.qos.chgDSCP_disable = 1;
        hdr.fabric_qos.chgDSCP_disable = 1;
    }
    table dscp_resolve {
        key = {
            eg_md.qos.qppb_set_dscp : exact;
            hdr.ipv4.isValid() : exact;
            hdr.ipv6.isValid() : exact;
        }
        actions = {
            ipv4_dscp;
            ipv6_dscp;
        }
        size = 2;
        // const entries = {
        //     (1, true, false) : ipv4_dscp();
        //     (1, false, true) : ipv6_dscp();
        // }
    }

    action exec_count() {
        flow_stats.count(eg_md.policer.qppb_stats_id);
    }
    table qppb_stats {
        // keyless
        actions = {
            exec_count;
        }
        default_action = exec_count();
    }

    apply {
        if (qppb_stats_sip.apply().hit) {}
        else if (qppb_stats_dip.apply().hit) {}
        else {qppb_stats_back.apply();}
        qppb_stats.apply();

        qppb_qos.apply();
        dscp_resolve.apply();
    }
}


control FabricEgressSystemAcl(
                inout switch_header_t hdr,
                inout switch_egress_metadata_t eg_md,
                inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr) (
                switch_uint32_t table_size=512) {
    Counter<bit<64>, bit<16>>(1024, CounterType_t.PACKETS) stats;

    action drop(bit<16> stats_id, bit<8> drop_reason) {
        eg_intr_md_for_dprsr.drop_ctl = 0x1;
        stats.count(stats_id);
        eg_md.common.drop_reason = drop_reason;
    }

    action forward(bit<16> stats_id) {
        stats.count(stats_id);
    }

    table system_acl {
        key = {
            eg_md.common.iif : ternary;
            eg_md.flags.drop : ternary; /* 防止重复计数 */
            eg_md.policer.drop : ternary;
            eg_md.qos.qppb_meter_color : ternary;
            hdr.ipv4.isValid() : ternary;
            hdr.ipv4.ttl : ternary;
            hdr.ipv6.isValid() : ternary;
            hdr.ipv6.hop_limit : ternary;
            hdr.mpls_ig[0].isValid() : ternary;
            hdr.mpls_ig[0].ttl : ternary;
            eg_md.tunnel.php_ttl : ternary;
            eg_md.tunnel.is_php : ternary;
        }
        actions = {
            drop;
            forward;
        }
        const default_action = forward((bit<16>)SWITCH_DROP_REASON_FORWARD);
        size = table_size;
    }

    apply {
        if (eg_md.flags.escape_etm == 0) {
            system_acl.apply();
        }
    }

}
# 205 "/mnt/p4c-4127/p4src/switch-tofino2/switch_tofino_x1.p4" 2
# 1 "/mnt/p4c-4127/p4src/shared/copp.p4" 1
/* 直连网段送CPU */
control cpp_uc_route(inout switch_header_t hdr,
                    inout switch_ingress_metadata_t ig_md) {

    action v4uc_route() {
        ig_md.flags.drop = 1;
        ig_md.flags.glean = 1;
        hdr.fabric_crsp.cpu_reason = SWITCH_CPU_REASON_V4UC_ROUTE;
    }
    action v6uc_route() {
        ig_md.flags.drop = 1;
        ig_md.flags.glean = 1;
        hdr.fabric_crsp.cpu_reason = SWITCH_CPU_REASON_V6UC_ROUTE;
    }
    @placement_priority(127)
    table uc_route {
        key = {
            ig_md.flags.glean : exact;
            ig_md.route.nexthop_cmd : exact;
            hdr.ipv4.isValid() : exact;
            hdr.ipv6.isValid() : exact;
        }
        actions = {
            NoAction;
            v4uc_route;
            v6uc_route;
        }
        size = 4;
        // const entries = {
        //     (0, 2, true, false) : v4uc_route();
        //     (0, 2, false, true) : v6uc_route();
        // }
    }

    apply {
        uc_route.apply();
    }
}

control Ig_uplink_get_ip_lkp(inout switch_header_t hdr,
                    inout switch_ingress_metadata_t ig_md) {
    action get_ipv4() {
        ig_md.lkp.ip_tos = hdr.ipv4.diffserv;
    }
    action get_ipv6() {
        ig_md.lkp.ip_tos = hdr.ipv6.traffic_class;
    }
    table get_lkp {
        key = {
            hdr.ipv4.isValid() : exact;
            hdr.ipv6.isValid() : exact;
        }
        actions = {
            get_ipv4;
            get_ipv6;
        }
        size = 2;
        // const entries = {
        //     ( true, false) : get_ipv4();
        //     (false,  true) : get_ipv6();
        // }
    }

    apply {
        get_lkp.apply();
    }
}

/* 黑白名单 */
control black_white_list (
        inout switch_header_t hdr,
        inout switch_ingress_metadata_t ig_md) {

    Counter<bit<64>, bit<16>>(4096, CounterType_t.PACKETS) stats;
    bit<16> tmp_stats_id;

    action set_cpu_code(bit<16> cpu_code, bit<16> stats_id, bit<8> ttl_min) {
        ig_md.common.cpu_code = cpu_code;
        tmp_stats_id = stats_id;
        ig_md.policer.ttl_min = ttl_min;
    }

    @placement_priority(127)
    table black_only_sport {
        key = {
            hdr.fabric_crsp.src_port : exact @name("src_port");
        }
        actions = {
            set_cpu_code;
            NoAction;
        }
        const default_action = NoAction;
        size = 256;
    }

    @placement_priority(127)
    table black_sport {
        key = {
            hdr.fabric_crsp.cpu_reason : exact @name("cpu_reason");
            hdr.fabric_crsp.src_port : exact @name("src_port");
        }
        actions = {
            set_cpu_code;
            NoAction;
        }
        const default_action = NoAction;
        size = 1024;
    }

    @placement_priority(127)
    table black_iif {
        key = {
            hdr.fabric_crsp.cpu_reason : exact @name("cpu_reason");
            ig_md.common.ul_iif : exact;
        }
        actions = {
            set_cpu_code;
            NoAction;
        }
        const default_action = NoAction;
        size = 4096;
    }

    @placement_priority(127)
    table black_smac {
        key = {
            hdr.fabric_crsp.cpu_reason : exact @name("cpu_reason");
            ig_md.lkp.mac_src_addr : exact;
        }
        actions = {
            set_cpu_code;
            NoAction;
        }
        const default_action = NoAction;
        size = 4096;
    }

    @placement_priority(127)
    table black_sip {
        key = {
            hdr.fabric_crsp.cpu_reason : exact @name("cpu_reason");
            ig_md.lkp.ip_type : exact;
            ig_md.lkp.ip_src_addr : exact;
        }
        actions = {
            set_cpu_code;
            NoAction;
        }
        const default_action = NoAction;
        size = 4096;
    }

    @placement_priority(127)
    table black_iif_smac {
        key = {
            hdr.fabric_crsp.cpu_reason : exact @name("cpu_reason");
            ig_md.common.ul_iif : exact;
            ig_md.lkp.mac_src_addr : exact;
        }
        actions = {
            set_cpu_code;
            NoAction;
        }
        const default_action = NoAction;
        size = 4096;
    }

    @placement_priority(127)
    table black_iif_sip {
        key = {
            hdr.fabric_crsp.cpu_reason : exact @name("cpu_reason");
            ig_md.common.ul_iif : exact;
            ig_md.lkp.ip_type : exact;
            ig_md.lkp.ip_src_addr : exact;
        }
        actions = {
            set_cpu_code;
            NoAction;
        }
        const default_action = NoAction;
        size = 4096;
    }

    @placement_priority(127)
    table white_sip_l4sport {
        key = {
            hdr.fabric_crsp.cpu_reason : exact @name("cpu_reason");
            ig_md.lkp.ip_type : exact;
            ig_md.lkp.ip_src_addr : exact;
            ig_md.lkp.l4_src_port : exact;
        }
        actions = {
            set_cpu_code;
            NoAction;
        }
        const default_action = NoAction;
        size = 1024 * 6;
    }

    @placement_priority(127)
    table white_sip_l4dport {
        key = {
            hdr.fabric_crsp.cpu_reason : exact @name("cpu_reason");
            ig_md.lkp.ip_type : exact;
            ig_md.lkp.ip_src_addr : exact;
            ig_md.lkp.l4_dst_port : exact;
        }
        actions = {
            set_cpu_code;
            NoAction;
        }
        const default_action = NoAction;
        size = 1024 * 6;
    }

    @placement_priority(127)
    table white_sip {
        key = {
            hdr.fabric_crsp.cpu_reason : exact @name("cpu_reason");
            ig_md.lkp.ip_type : exact;
            ig_md.lkp.ip_src_addr : exact;
        }
        actions = {
            set_cpu_code;
            NoAction;
        }
        const default_action = NoAction;
        size = 1024 * 10;
    }

    @placement_priority(127)
    table white_smac {
        key = {
            hdr.fabric_crsp.cpu_reason : exact @name("cpu_reason");
            ig_md.lkp.mac_src_addr : exact;
        }
        actions = {
            set_cpu_code;
            NoAction;
        }
        const default_action = NoAction;
        size = 1024 * 2;
    }

    @placement_priority(127)
    table black_back {
        key = {
            hdr.fabric_crsp.cpu_reason : ternary @name("cpu_reason");
            hdr.fabric_crsp.src_port : ternary @name("src_port");
            ig_md.common.ul_iif : ternary;
            ig_md.lkp.mac_src_addr : ternary;
            ig_md.lkp.ip_type : ternary;
            ig_md.lkp.ip_src_addr : ternary;
            ig_md.lkp.l4_src_port : ternary;
            ig_md.lkp.l4_dst_port : ternary;
        }
        actions = {
            set_cpu_code;
            NoAction;
        }
        const default_action = NoAction;
        size = 512;
    }

    @placement_priority(127)
    table white_back {
        key = {
            hdr.fabric_crsp.cpu_reason : ternary @name("cpu_reason");
            hdr.fabric_crsp.src_port : ternary @name("src_port");
            ig_md.common.ul_iif : ternary;
            ig_md.lkp.mac_src_addr : ternary;
            ig_md.lkp.ip_type : ternary;
            ig_md.lkp.ip_src_addr : ternary;
            ig_md.lkp.l4_src_port : ternary;
            ig_md.lkp.l4_dst_port : ternary;
        }
        actions = {
            set_cpu_code;
            NoAction;
        }
        const default_action = NoAction;
        size = 512;
    }

    action ttl_sub_count() {
        ig_md.policer.ttl_dec = ig_md.policer.ttl_dec |-| ig_md.policer.ttl_min;
        stats.count(tmp_stats_id);
    }
    table set_ttl_dec_and_count {
        // keyless
        actions = {
            ttl_sub_count;
        }
        const default_action = ttl_sub_count;
    }

    // action exec_count() {
    // }
    // table count {
    //     // keyless
    //     actions = {
    //         exec_count;
    //     }
    //     default_action = exec_count();
    // }

    apply {
        tmp_stats_id = 0;

        if (ig_md.flags.glean == 0) {}
        else if (black_only_sport.apply().hit) {}
        else if (black_iif_smac.apply().hit) {}
        else if (black_iif_sip.apply().hit) {}
        else if (black_smac.apply().hit) {}
        else if (black_sip.apply().hit) {}
        else if (black_iif.apply().hit) {}
        else if (black_sport.apply().hit) {}
        // else if (black_back.apply().hit) {}

        if (ig_md.flags.glean == 0) {}
        else if (white_sip_l4sport.apply().hit) {}
        else if (white_sip_l4dport.apply().hit) {}
        else if (white_smac.apply().hit) {}
        else if (white_sip.apply().hit) {}
        else {white_back.apply();}

        set_ttl_dec_and_count.apply();
        // count.apply();
    }

}

control copp (
        inout switch_header_t hdr,
        inout switch_ingress_metadata_t ig_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm) {

    black_white_list() bw_list;

    Meter<bit<16>>(512, MeterType_t.PACKETS) type_meter;
    Meter<bit<3>>(32, MeterType_t.PACKETS) qid_meter;
    Meter<bit<1>>(1, MeterType_t.PACKETS) port_meter;
    Counter<bit<64>, bit<16>>(512, CounterType_t.PACKETS) host_acl_stats;
    bit<2> type_color;
    bit<2> qid_color;
    bit<2> port_color;
    // bit<5> tmp_qid;

    action get_common_iif() {
        ig_md.common.ul_iif = ig_md.common.iif;
    }
    action get_tunnel_iif() {
        ig_md.common.ul_iif = hdr.ext_tunnel_decap.ul_iif;
    }
    table set_ul_iif {
        key = {
            hdr.ext_tunnel_decap.isValid() : exact;
        }
        actions = {
            get_common_iif;
            get_tunnel_iif;
        }
        default_action = get_common_iif();
        // const entries = {
        //     ( true) : get_tunnel_iif();
        //     (false) : get_common_iif();
        // }
    }

    action to_cpu_eth(bit<16> stats_id, bit<16> meter_id, bit<3> tc) {
        host_acl_stats.count(stats_id);
        ig_md.flags.is_gleaned = 1;
        ig_md.qos.tc = tc;
        ig_md.qos.color = 0;
        type_color = (bit<2>)type_meter.execute(meter_id);
    }
    action to_cpu_pcie(bit<16> stats_id, bit<16> meter_id, bit<3> tc) {
        host_acl_stats.count(stats_id);
        ig_md.flags.is_gleaned = 1;
        ig_md.qos.tc = tc;
        ig_md.qos.color = 0;
        type_color = (bit<2>)type_meter.execute(meter_id);
    }
    action no_to_cpu(bit<16> stats_id) {
        host_acl_stats.count(stats_id);
        ig_md.flags.is_gleaned = 1;
        ig_md.flags.glean = 0;
        ig_md.policer.cpp_drop_reason = SWITCH_DROP_REASON_HOST_ACL;
    }
    @stage(7)
    table host_acl {
        key = {
            hdr.fabric_crsp.cpu_reason : ternary @name("cpu_reason");
            ig_md.common.cpu_code : ternary @name("cpu_code");
            ig_md.lkp.ip_type : ternary;
            ig_md.lkp.ip_tos : ternary;
            ig_md.policer.ttl_dec : ternary;
            hdr.fabric_base.is_mcast : ternary;
        }
        actions = {
            to_cpu_eth;
            to_cpu_pcie;
            no_to_cpu;
        }
        size = 512;
        default_action = no_to_cpu(0);
    }

    action to_cpu_eth_pram(switch_port_t egress_port) {
        ig_intr_md_for_tm.ucast_egress_port = egress_port;
        ig_md.common.bridge_type = BRIDGE_TYPE_UPLINK_FRONT;
        ig_md.flags.bypass_fabric_lag = 1;
        ig_md.flags.drop = 1;
        ig_md.flags.is_eth = 1;
    }

    table cpu_eth_pkt {
        key = {
            hdr.fabric_crsp.cpu_reason : exact @name("cpu_reason");
        }
        actions = {
            to_cpu_eth_pram;
        }
        size = 512;
    }

    action copp1_pcie_permit() {
        qid_color = (bit<2>)qid_meter.execute(ig_md.qos.tc);
    }
    action copp1_eth_permit() {}
    action copp1_drop() {
        ig_md.flags.glean = 0;
        ig_md.policer.cpp_drop_reason = SWITCH_DROP_REASON_TYPE_METER;
    }
    table copp1 {
        key = {
            ig_md.flags.glean : exact;
            ig_md.flags.is_eth : exact;
            type_color : exact;
        }
        actions = {
            copp1_pcie_permit;
            copp1_eth_permit;
            copp1_drop;
        }
        size = 8;
        // const entries = {
        //     (1, 0, SWITCH_METER_COLOR_GREEN ) : copp1_pcie_permit();
        //     (1, 0, SWITCH_METER_COLOR_YELLOW) : copp1_pcie_permit();
        //     (1, 0, SWITCH_METER_COLOR_RED   ) : copp1_drop();
        //     (1, 1, SWITCH_METER_COLOR_GREEN ) : copp1_eth_permit();
        //     (1, 1, SWITCH_METER_COLOR_YELLOW) : copp1_eth_permit();
        //     (1, 1, SWITCH_METER_COLOR_RED   ) : copp1_drop();
        // }
    }

    action copp2_permit() {
        port_color = (bit<2>)port_meter.execute(0);
    }
    action copp2_drop() {
        ig_md.flags.glean = 0;
        ig_md.policer.cpp_drop_reason = SWITCH_DROP_REASON_QID_METER;
    }
    table copp2 {
        key = {
            ig_md.flags.glean : exact;
            ig_md.flags.is_eth : exact;
            qid_color : exact;
        }
        actions = {
            copp2_permit;
            copp2_drop;
        }
        size = 8;
        // const entries = {
        //     (1, 0, SWITCH_METER_COLOR_GREEN ) : copp2_permit();
        //     (1, 0, SWITCH_METER_COLOR_YELLOW) : copp2_permit();
        //     (1, 0, SWITCH_METER_COLOR_RED   ) : copp2_drop();
        // }
    }

    action copp3_permit() {}
    action copp3_drop() {
        ig_md.flags.glean = 0;
        ig_md.policer.cpp_drop_reason = SWITCH_DROP_REASON_PORT_METER;
    }
    table copp3 {
        key = {
            ig_md.flags.glean : exact;
            ig_md.flags.is_eth : exact;
            port_color : exact;
        }
        actions = {
            copp3_permit;
            copp3_drop;
        }
        size = 8;
        // const entries = {
        //     (1, 0, SWITCH_METER_COLOR_GREEN ) : copp3_permit();
        //     (1, 0, SWITCH_METER_COLOR_YELLOW) : copp3_permit();
        //     (1, 0, SWITCH_METER_COLOR_RED   ) : copp3_drop();
        // }
    }

    apply {
        type_color = 0;
        qid_color = 0;
        port_color = 0;

        set_ul_iif.apply();
        bw_list.apply(hdr, ig_md);
        if (ig_md.flags.glean == 1) {
            cpu_eth_pkt.apply();
            host_acl.apply();
        }
        copp1.apply();
        copp2.apply();
        copp3.apply();
    }

}

control cpp_counter(inout switch_header_t hdr, inout switch_ingress_metadata_t ig_md) {

    Counter<bit<64>, bit<8>>(256, CounterType_t.PACKETS) type_stats;
    Counter<bit<64>, bit<16>>(512, CounterType_t.PACKETS) udf_stats;

    action exec_type_count() {
        type_stats.count(hdr.fabric_crsp.cpu_reason);
    }
    table type_count {
        // keyless
        actions = {
            exec_type_count;
        }
        default_action = exec_type_count();
    }

    // action exec_udf_count(bit<16> stats_id) {
    //     udf_stats.count(stats_id);
    // }
    // table udf_count {
    //     key = {
    //         ig_md.policer.cpp_drop_reason : ternary;
    //         hdr.fabric_crsp.cpu_reason : ternary @name("cpu_reason");
    //         ig_md.common.cpu_code : ternary @name("cpu_code");
    //         hdr.fabric_crsp.src_port : ternary @name("src_port");
    //     }
    //     actions = {
    //         exec_udf_count;
    //     }
    //     size = 512;
    // }

    apply {
        if (ig_md.flags.is_gleaned == 1 && ig_md.flags.glean == 0) {
            type_count.apply();
        }
        // if (ig_md.flags.is_gleaned == 1) {
        //     udf_count.apply();  //for power
        // }
    }
}

// control cpu_forword (
//         inout switch_header_t hdr,
//         inout switch_ingress_metadata_t ig_md,
//         inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm,
//         inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr) {

//     action redirect_to_eth() {
//         ;
//     }
//     action redirect_to_pcie() {
//         ig_md.flags.bypass_fabric_lag = 1;
//         ig_intr_md_for_tm.ucast_egress_port = 320;
//     }
//     action copy_to_pcie() {
//         ig_intr_md_for_tm.copy_to_cpu = 1;
//     }
//     action hard_drop() {
//         ig_intr_md_for_dprsr.drop_ctl = 0x1;
//     }
//     table cpu_fwd {
//         key = {
//             ig_md.flags.is_gleaned : exact;
//             ig_md.flags.glean : exact;
//             ig_md.flags.drop : exact;
//             ig_md.flags.is_eth : exact;
//         }
//         actions = {
//             redirect_to_eth;
//             redirect_to_pcie;
//             copy_to_pcie;
//             hard_drop;
//         }
//         const entries = {
//             (1, 1, 1, 1) : redirect_to_eth();
//             (1, 1, 1, 0) : redirect_to_pcie();
//             (1, 1, 0, 1) : redirect_to_eth();
//             (1, 1, 0, 0) : copy_to_pcie();
//             (1, 0, 1, 1) : hard_drop();
//             (1, 0, 1, 0) : hard_drop();
//             (0, 0, 1, 1) : hard_drop();
//             (0, 0, 1, 0) : hard_drop();
//         }
//     }

//     apply {
//         cpu_fwd.apply();
//     }
// }

control cpu_stats(inout switch_egress_metadata_t eg_md) {

    Counter<bit<64>, bit<8>>(256, CounterType_t.PACKETS) stats;

    action exec_count() {
        stats.count(eg_md.common.cpu_reason);
    }
    table count {
        // keyless
        actions = {
            exec_count;
        }
        default_action = exec_count();
    }

    apply {
        count.apply();
    }
}
# 206 "/mnt/p4c-4127/p4src/switch-tofino2/switch_tofino_x1.p4" 2

/* by lichunfeng */
# 1 "/mnt/p4c-4127/p4src/shared/l2_mac_downlink.p4" 1
control HorizonSplit(
        inout switch_egress_metadata_t eg_md,
        inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr)(
        switch_uint32_t horizon_split_size = 64){

    action drop(bit<1> reason) {
        eg_md.flags.horizon_split_drop_reason = reason;
        /* bypass all? */
    }

    table horizon_split {
        key = {
            eg_md.tunnel.src_netport_group : exact;
            eg_md.tunnel.dst_netport_group : exact;
        }
        actions = {
            drop;
            NoAction;
        }
        const default_action = NoAction;
        size = horizon_split_size;
    }

    apply{
        if(eg_md.common.pkt_type == FABRIC_PKT_TYPE_ETH) {
            horizon_split.apply();
        }
    }
}

control PW_PTAG_XLATE_LEN(
        inout switch_header_t hdr,
        inout switch_egress_metadata_t eg_md)(
        switch_uint32_t table_ptag_encap_size = 32) {

    action add_p() {
        eg_md.tunnel.payload_len = eg_md.tunnel.payload_len + 16w4;
    }
    action modify_p() {
    }
    action del_p() {
        eg_md.tunnel.payload_len = eg_md.tunnel.payload_len - 16w4;
    }

    table pw_ptag_encap {
        key = {
            hdr.inner_vlan_tag[0].isValid() : exact;
            eg_md.tunnel.ptag_igmod : exact;
            eg_md.tunnel.ptag_eg_action : exact;
        }
        actions = {
            add_p;
            modify_p;
            del_p;
            NoAction;
        }
        default_action = NoAction;
        size = table_ptag_encap_size;
        const entries = {
            (true, 0, VLANTAG_RAW_MODE) : NoAction();
            (true, 0, VLANTAG_REPLACE_IF_PRESENT) : add_p();
            (true, 0, VLANTAG_NOREPLACE_IF_PRESENT) : add_p();
            (false, 0, VLANTAG_RAW_MODE) : NoAction();
            (false, 0, VLANTAG_REPLACE_IF_PRESENT) : add_p();
            (false, 0, VLANTAG_NOREPLACE_IF_PRESENT) : add_p();
            (true, 1, VLANTAG_RAW_MODE) : del_p();
            (true, 1, VLANTAG_REPLACE_IF_PRESENT) : modify_p();
            (true, 1, VLANTAG_NOREPLACE_IF_PRESENT) : NoAction();
        }
    }

    apply {
        pw_ptag_encap.apply();
    }
}

control PW_PTAG_XLATE(
        inout switch_header_t hdr,
        inout switch_egress_metadata_t eg_md)(
        switch_uint32_t table_ptag_encap_size = 32) {

    action add_p() {
        hdr.inner_vlan_tag.push_front(1);
        hdr.inner_vlan_tag[0].setValid();
        hdr.inner_vlan_tag[0].vid = eg_md.tunnel.ptag_vid;
        hdr.inner_vlan_tag[0].ether_type = hdr.inner_ethernet.ether_type;
        hdr.inner_vlan_tag[0].cfi = 0;
        hdr.inner_vlan_tag[0].pcp = eg_md.qos.pcp;
        hdr.inner_ethernet.ether_type = 0x8100;
        eg_md.common.pkt_length = eg_md.common.pkt_length + 16w4;
        //eg_md.tunnel.payload_len = eg_md.tunnel.payload_len + 16w4;
    }
    action modify_p() {
        hdr.inner_vlan_tag[0].vid = eg_md.tunnel.ptag_vid;
        hdr.inner_ethernet.ether_type = 0x8100;
    }
    action del_p() {
        hdr.inner_ethernet.ether_type = hdr.inner_vlan_tag[0].ether_type;
        hdr.inner_vlan_tag.pop_front(1);
        eg_md.common.pkt_length = eg_md.common.pkt_length - 16w4;
        //eg_md.tunnel.payload_len = eg_md.tunnel.payload_len - 16w4;
    }

    table pw_ptag_encap {
        key = {
            hdr.inner_vlan_tag[0].isValid() : exact;
            eg_md.tunnel.ptag_igmod : exact;
            eg_md.tunnel.ptag_eg_action : exact;
        }
        actions = {
            add_p;
            modify_p;
            del_p;
            NoAction;
        }
        default_action = NoAction;
        size = table_ptag_encap_size;
        const entries = {
            (true, 0, VLANTAG_RAW_MODE) : NoAction();
            (true, 0, VLANTAG_REPLACE_IF_PRESENT) : add_p();
            (true, 0, VLANTAG_NOREPLACE_IF_PRESENT) : add_p();
            (false, 0, VLANTAG_RAW_MODE) : NoAction();
            (false, 0, VLANTAG_REPLACE_IF_PRESENT) : add_p();
            (false, 0, VLANTAG_NOREPLACE_IF_PRESENT) : add_p();
            (true, 1, VLANTAG_RAW_MODE) : del_p();
            (true, 1, VLANTAG_REPLACE_IF_PRESENT) : modify_p();
            (true, 1, VLANTAG_NOREPLACE_IF_PRESENT) : NoAction();
        }
    }

    apply {
        pw_ptag_encap.apply();
    }
}

control ACPtagXlate(
        inout switch_header_t hdr,
        inout switch_ingress_metadata_t ig_md) {

    const switch_uint32_t table_ptag_encap_size = 16;

    action add_p() {
        hdr.vlan_tag.push_front(1);
        hdr.vlan_tag[0].setValid();
        hdr.vlan_tag[0].vid = ig_md.tunnel.ptag_vid;
        hdr.vlan_tag[0].ether_type = hdr.ethernet.ether_type;
        hdr.vlan_tag[0].cfi = 0;
        hdr.vlan_tag[0].pcp = ig_md.qos.pcp;
        hdr.ethernet.ether_type = 0x8100;
    }

    action modify_p() {
        hdr.vlan_tag[0].vid = ig_md.tunnel.ptag_vid;
    }

    action del_p() {
        hdr.ethernet.ether_type = hdr.vlan_tag[0].ether_type;
        hdr.vlan_tag.pop_front(1);
    }

    table ac_ptag_xlate {
        key = {
            hdr.vlan_tag[0].isValid() : exact;
            ig_md.tunnel.ptag_igmod : exact;
            ig_md.tunnel.ptag_eg_action : exact;
        }
        actions = {
            add_p;
            modify_p;
            del_p;
            NoAction;
        }
        default_action = NoAction;
        size = table_ptag_encap_size;
        const entries = {
            (true, 0, VLANTAG_RAW_MODE) : NoAction();
            (true, 0, VLANTAG_REPLACE_IF_PRESENT) : add_p();
            (true, 0, VLANTAG_NOREPLACE_IF_PRESENT) : add_p();
            (false, 0, VLANTAG_RAW_MODE) : NoAction();
            (false, 0, VLANTAG_REPLACE_IF_PRESENT) : add_p();
            (false, 0, VLANTAG_NOREPLACE_IF_PRESENT) : add_p();
            (true, 1, VLANTAG_RAW_MODE) : del_p();
            (true, 1, VLANTAG_REPLACE_IF_PRESENT) : modify_p();
            (true, 1, VLANTAG_NOREPLACE_IF_PRESENT) : NoAction();
        }
    }
    apply {
        ac_ptag_xlate.apply();
    }
}

control VlanEgressMemberCheck(
        inout switch_header_t hdr,
        inout switch_ingress_metadata_t ig_md) {

    /* by liyuhang */
    bit<1> check_flag = 0;
    Hash<bit<32>>(HashAlgorithm_t.IDENTITY) hash;
    const bit<32> vlan_membership_size = 1 << 19; //dst_port[6:0] + vid => 7 + 12 = 19
    Register<bit<1>, bit<32>>(vlan_membership_size, 0) vlan_untag_check;
    RegisterAction<bit<1>, bit<32>, bit<1>>(vlan_untag_check) check_vlan_untag_membership = {
        void apply(inout bit<1> val, out bit<1> rv) {
            rv = val;
        }
    };
    //egress vlan member check
    Register<bit<1>, bit<32>>(vlan_membership_size, 0) vlan_membership;
    RegisterAction<bit<1>, bit<32>, bit<1>>(vlan_membership) check_vlan_membership = {
        void apply(inout bit<1> val, out bit<1> rv) {
            rv = ~val;
        }
    };

    action del_vlan_tag() {
        hdr.ethernet.ether_type = hdr.vlan_tag[0].ether_type;
        hdr.vlan_tag.pop_front(1);
    }

    table delete_vlan{
        /* keyless */
        actions = {
            del_vlan_tag;
        }

        const default_action = del_vlan_tag();
    }

    action get_check_enable(bit<1> check_enable){
        check_flag = check_enable;
    }

    table evlan_to_vlan_check {
        key = {
            ig_md.ebridge.evlan : exact;
        }

        actions = {
            get_check_enable;
        }

        const default_action = get_check_enable(0);
        size = 8192;
    }

    action vlan_member_check(){
        ig_md.flags.vlan_member_check = check_vlan_membership.execute(
                hash.get({ig_md.common.dst_port[6:0], hdr.vlan_tag[0].vid}));
    }

    table vlan_check{
        actions = {
            vlan_member_check;
        }

        const default_action = vlan_member_check;
    }

    apply {
        evlan_to_vlan_check.apply();
        if(check_flag == 1 && hdr.vlan_tag[0].isValid()){
            vlan_check.apply();
        }
        if (check_vlan_untag_membership.execute(
                hash.get({ig_md.common.dst_port[6:0], hdr.vlan_tag[0].vid})) == 1 &&
                hdr.vlan_tag[0].isValid()){
            delete_vlan.apply();
        }
    }
}
# 209 "/mnt/p4c-4127/p4src/switch-tofino2/switch_tofino_x1.p4" 2
# 1 "/mnt/p4c-4127/p4src/shared/iptunnel.p4" 1
control IngressIPTunnel(
        inout switch_header_t hdr,
        inout switch_ingress_metadata_t ig_md)(
        switch_uint32_t src_dst_addr_size,
        switch_uint32_t dst_addr_size,
        switch_uint32_t g_dst_addr_size,
        switch_uint32_t src_dst_addr_back_size = 512) {


     action end(switch_srv6_flavors_t srv6_flavors, bit<8> prefixlen) {
        ig_md.tunnel.srv6_end_type = SWITCH_SRV6_END_TYPE_END;
        ig_md.tunnel.srv6_flavors = srv6_flavors;
        ig_md.srv6.prefixlen = prefixlen;
        ig_md.srv6.si = hdr.ipv6.dst_addr[1:0];
    }

    /*
    An instance of the End.X behavior is associated with a set, J, of one
    or more Layer-3 adjacencies.
    S15.   Submit the packet to the IPv6 module for transmission
                to the new destination via a member of J
    */
    action end_x(switch_srv6_flavors_t srv6_flavors, bit<8> prefixlen,
                 bit<16> nexthop, bit<1> is_ecmp, bit<2> level, bit<8> priority) {
        ig_md.flags.ext_srv6 = true;
        ig_md.common.extend = 1;
        add_ext_srv6(hdr, ig_md, 0, true, level, is_ecmp, priority, nexthop, 0, 0);

        ig_md.tunnel.srv6_end_type = SWITCH_SRV6_END_TYPE_END_X;
        ig_md.tunnel.srv6_flavors = srv6_flavors;
        ig_md.srv6.prefixlen = prefixlen;
        ig_md.srv6.si = hdr.ipv6.dst_addr[1:0];
    }

    /*
    S15.1.   Set the packet's associated FIB table to T
    S15.2.   Submit the packet to the egress IPv6 FIB lookup and
              transmission to the new destination
    */
    action end_t(switch_srv6_flavors_t srv6_flavors, bit<8> prefixlen, switch_lif_t l3iif) {
        // XXX same as end() ?
        end(srv6_flavors, prefixlen);
    }

    /* Push a new IPv6 header with its own SRH containing B */
    action end_b6(bit<16> nexthop, bit<1> is_ecmp, bit<2> level, bit<8> priority) {
        ig_md.flags.ext_srv6 = true;
        ig_md.common.extend = 1;
        add_ext_srv6(hdr, ig_md, 0, true, level, is_ecmp, priority, nexthop, 0, 0);
    }

    /* Push a new IPv6 header with its own SRH containing B */
    action end_b6_encaps(bit<16> nexthop, bit<1> is_ecmp, bit<2> level, bit<8> priority,
                                        switch_srv6_flavors_t srv6_flavors, bit<8> prefixlen) {
        end_b6(nexthop, is_ecmp, level, priority);
        ig_md.tunnel.srv6_end_type = SWITCH_SRV6_END_TYPE_END_B6_ENCAPS;
        ig_md.tunnel.srv6_flavors = srv6_flavors;
        ig_md.srv6.prefixlen = prefixlen;
        ig_md.srv6.si = hdr.ipv6.dst_addr[1:0];
    }

    /* excluding the first SID in the SRH of the new IPv6 header. */
    action end_b6_encaps_red(bit<16> nexthop, bit<1> is_ecmp, bit<2> level, bit<8> priority,
                                        switch_srv6_flavors_t srv6_flavors, bit<8> prefixlen) {
        end_b6_encaps(nexthop, is_ecmp, level, priority, srv6_flavors, prefixlen);
    }

    action end_b6_insert(bit<16> nexthop, bit<1> is_ecmp, bit<2> level, bit<8> priority) {
        end_b6(nexthop, is_ecmp, level, priority);
        ig_md.tunnel.srv6_end_type = SWITCH_SRV6_END_TYPE_END_B6_INSERT;
    }

    action end_b6_insert_red(bit<16> nexthop, bit<1> is_ecmp, bit<2> level, bit<8> priority) {
        end_b6_insert(nexthop, is_ecmp, level, priority);
    }
    /* for OAM */
    action end_op() {
        // send to cpu
        ig_md.tunnel.srv6_end_type = SWITCH_SRV6_END_TYPE_END_OP;
    }


    action action_miss() {
        ig_md.tunnel.ip_addr_miss = true;
    }


    action set_terminate_properties(switch_lif_t lif, switch_tunnel_inner_pkt_t inner_type) {
        ig_md.tunnel.tmp_iif = lif;
        /* ctrl plane set inner pkt type which can be terminated! */
        ig_md.tunnel.inner_type = inner_type;
    }

    @stage(4)
    table src_dst_addr {
        key = {
            /* ip tunnel & gre tunnel & vxlan tunnel use this table*/
            ig_md.lkp.ip_src_addr : exact;
            ig_md.lkp.ip_dst_addr : exact;
            ig_md.tunnel.type : exact;
        }
        actions = {
            NoAction;
            set_terminate_properties;
        }
        const default_action = NoAction;
        size = src_dst_addr_size;
    }

    @placement_priority(120)
    table dst_addr {
        key = {
            /* srv6 tunnel and later ip auto tunnel use this table */
            ig_md.lkp.ip_dst_addr : exact;
            ig_md.tunnel.type : exact;
        }
        actions = {
            NoAction;

            end;
            end_x;
            // end_t;
            end_b6_encaps;
            end_b6_encaps_red;
            end_b6_insert;
            end_b6_insert_red;
            end_op;

            // XXX more
        }
        const default_action = NoAction;
        size = dst_addr_size;
    }

    @placement_priority(120)
    table g_dst_addr {
        key = {
            ig_md.lkp.ip_dst_addr[127:2] : exact;
            ig_md.tunnel.type : exact;
        }
        actions = {
            NoAction;

            end;
            end_x;
            end_b6_encaps;
            end_b6_encaps_red;
            end_b6_insert;
            end_b6_insert_red;
            end_op;

            // XXX more
        }
        const default_action = NoAction;
        size = g_dst_addr_size;
    }

    @placement_priority(120)
    table src_dst_addr_back {
        key = {
            /* all tunnel type use this back table*/
            ig_md.lkp.ip_src_addr : ternary;
            ig_md.lkp.ip_dst_addr : ternary;
            ig_md.tunnel.type : ternary;
        }
        actions = {
            action_miss;
            set_terminate_properties;

            end;
            end_x;
            // end_t;
            end_b6_encaps;
            end_b6_encaps_red;
            end_b6_insert;
            end_b6_insert_red;
            end_op;
            // XXX more

        }
        const default_action = action_miss;
        size = src_dst_addr_back_size;
    }

    apply{
        switch(src_dst_addr.apply().action_run) {
            NoAction: {

                switch(dst_addr.apply().action_run) {
                    NoAction:{


                        switch(g_dst_addr.apply().action_run) {
                            NoAction:{

                                src_dst_addr_back.apply();

                            }
                        }


                    }
                }

            }
        }
    }
}

control IPTunnelTerminate(
        inout switch_header_t hdr,
        inout switch_ingress_metadata_t ig_md)(
        switch_uint32_t ip_tunnel_terminate_size=128) {

    action set_terminate_properties() {
        ig_md.tunnel.terminate = true;
        add_ext_tunnel_decap(hdr, ig_md);
        ig_md.common.iif = ig_md.tunnel.tmp_iif;
        ig_md.common.iif_type = SWITCH_L3_IIF_TYPE;
    }

    table ip_tunnel_terminate {
        key = {
            /* IPv4 tunnel & GRE tunnel */
            ig_md.tunnel.type : exact;
            ig_md.tunnel.inner_pkt_parsed : exact;//1：v4   2：v6
            ig_md.tunnel.inner_type : exact;
            ig_md.tunnel.ip_addr_miss : exact;
        }

        actions = {
            set_terminate_properties;
            NoAction;
        }
        size = ip_tunnel_terminate_size;
        const default_action = NoAction;
        const entries = {
            (SWITCH_TUNNEL_TYPE_IP_TUNNEL, SWITCH_TUNNEL_INNER_PKT_IPV4, SWITCH_TUNNEL_INNER_PKT_IPV4, false) : set_terminate_properties();
            (SWITCH_TUNNEL_TYPE_IP_TUNNEL, SWITCH_TUNNEL_INNER_PKT_IPV6, SWITCH_TUNNEL_INNER_PKT_IPV6, false) : set_terminate_properties();
            (SWITCH_TUNNEL_TYPE_IP_TUNNEL, SWITCH_TUNNEL_INNER_PKT_IPV4, SWITCH_TUNNEL_INNER_PKT_IPX, false) : set_terminate_properties();
            (SWITCH_TUNNEL_TYPE_IP_TUNNEL, SWITCH_TUNNEL_INNER_PKT_IPV6, SWITCH_TUNNEL_INNER_PKT_IPX, false) : set_terminate_properties();
            (SWITCH_TUNNEL_TYPE_IPGRE, SWITCH_TUNNEL_INNER_PKT_IPV4, SWITCH_TUNNEL_INNER_PKT_IPV4, false) : set_terminate_properties();
            (SWITCH_TUNNEL_TYPE_IPGRE, SWITCH_TUNNEL_INNER_PKT_IPV6, SWITCH_TUNNEL_INNER_PKT_IPV6, false) : set_terminate_properties();
            (SWITCH_TUNNEL_TYPE_IPGRE, SWITCH_TUNNEL_INNER_PKT_IPV4, SWITCH_TUNNEL_INNER_PKT_IPX, false) : set_terminate_properties();
            (SWITCH_TUNNEL_TYPE_IPGRE, SWITCH_TUNNEL_INNER_PKT_IPV6, SWITCH_TUNNEL_INNER_PKT_IPX, false) : set_terminate_properties();
        }
    }

    apply{



    }
}

control TunnelRewrite(
        inout switch_header_t hdr,
        inout switch_egress_metadata_t eg_md)(
        switch_uint32_t get_rewrite_info_size,
        switch_uint32_t ip_ttl_rewrite_size = 16,
        switch_uint32_t ip_dscp_rewrite_size = 16) {

    bit<8> tmp_ttl = 0;
    action encap_ipv6_info(ipv6_addr_t sip, ipv6_addr_t dip,
                                bit<8> hop_limit,bit<2> dscp_select,
                                bit<6> tc_value) {
        hdr.ipv6.src_addr = sip;
        hdr.ipv6.dst_addr = dip;
        hdr.ipv6.hop_limit = hop_limit;
        tmp_ttl = hop_limit;
        eg_md.tunnel.dscp_sel = dscp_select;
        hdr.ipv6.traffic_class[7:2] = tc_value;
        eg_md.lkp.ip_src_addr = sip;
        eg_md.lkp.ip_dst_addr = dip;
        eg_md.lkp.ipv6_tos[7:2] = tc_value;
    }

    action encap_ipv4_info(ipv4_addr_t sip, ipv4_addr_t dip, bit<8> ttl,
                              bit<2> dscp_select, bit<6> dscp_value) {
        hdr.ipv4.src_addr = sip;
        hdr.ipv4.dst_addr = dip;
        hdr.ipv4.ttl = ttl;
        tmp_ttl = ttl;
        eg_md.tunnel.dscp_sel = dscp_select;
        hdr.ipv4.diffserv[7:2] = dscp_value;
        eg_md.lkp.ip_src_addr[31:0] = sip;
        eg_md.lkp.ip_dst_addr[31:0] = dip;
        eg_md.lkp.ipv4_tos[7:2] = dscp_value;
    }

    table get_rewrite_info {
        key = {
            eg_md.route.iptunnel_l3_encap_id[12:0] : exact;
        }
        actions = {
            encap_ipv4_info;
            encap_ipv6_info;
            NoAction;
        }
        const default_action = NoAction;
        size = get_rewrite_info_size;
    }

    action copy_ipv4_ttl() {
        hdr.ipv4.ttl = eg_md.tunnel.ttl;//内部报文赋值而来
    }

    action copy_ipv6_hop_limit() {
        hdr.ipv6.hop_limit = eg_md.tunnel.ttl;
    }

    @ignore_table_dependency("Eg_downlink.mpls_encap0.mpls_tunnel0_rewrite.mpls_tunnel0_ttl_rewrite")
    table ip_ttl_rewrite {
        key = {
            /* 可以兼容insert SRV6, encap SRV6两种类型 */
            /* ttl=0 : copy,  other value : NoAction*/
            hdr.ipv4.isValid() : exact;
            hdr.ipv6.isValid() : exact;
            tmp_ttl : exact;
        }
        actions = {
            copy_ipv4_ttl;
            copy_ipv6_hop_limit;
            NoAction;
        }
        default_action = NoAction;
        size = ip_ttl_rewrite_size;
    }

    action copy_ipv4_from_pkt() {
        hdr.ipv4.diffserv[7:2] = eg_md.tunnel.inner_dscp;
        eg_md.lkp.ipv4_tos[7:2] = eg_md.tunnel.inner_dscp;
    }

    action copy_ipv4_from_qos() {
        hdr.ipv4.diffserv[7:2] = eg_md.qos.dscp;
        eg_md.lkp.ipv4_tos[7:2] = eg_md.qos.dscp;
    }

    action copy_ipv6_from_pkt() {
        hdr.ipv6.traffic_class[7:2] = eg_md.tunnel.inner_dscp;
        eg_md.lkp.ipv6_tos[7:2] = eg_md.tunnel.inner_dscp;
    }

    action copy_ipv6_from_qos() {
        hdr.ipv6.traffic_class[7:2] = eg_md.qos.dscp;
        eg_md.lkp.ipv6_tos[7:2] = eg_md.qos.dscp;
    }

    @ignore_table_dependency("Eg_downlink.mpls_encap2.mpls_tunnel2_rewrite.mpls_tunnel2_rewrite")
    table ip_dscp_rewrite {
        key = {
            /* 0:set from cpu  1:copy from inner 2:from qos */
            /* insert SRV6：dscp_sel=3, miss this table */
            /* dscp_sel=0: set value in upper get_rewrite_info table */
            eg_md.tunnel.dscp_sel : exact;
            hdr.ipv4.isValid() : exact;
            hdr.ipv6.isValid() : exact;
        }
        actions = {
            NoAction;
            copy_ipv4_from_pkt;
            copy_ipv4_from_qos;
            copy_ipv6_from_pkt;
            copy_ipv6_from_qos;
        }
        const default_action = NoAction;
        size = ip_dscp_rewrite_size;
    }

    apply{

        if (get_rewrite_info.apply().hit){
            ip_ttl_rewrite.apply();
            ip_dscp_rewrite.apply();
        }

    }
}
# 210 "/mnt/p4c-4127/p4src/switch-tofino2/switch_tofino_x1.p4" 2
# 1 "/mnt/p4c-4127/p4src/shared/vxlan.p4" 1
control VxlanTerminate(
        inout switch_header_t hdr,
        inout switch_ingress_metadata_t ig_md)(
        switch_uint32_t vxlan_terminate_table_size,
        switch_uint32_t vxlan_terminate_back_size=512) {

    action set_terminate_properties(bit<16> evlan) {
        ig_md.ebridge.evlan = evlan;
     ig_md.tunnel.terminate = true;
        add_ext_tunnel_decap(hdr, ig_md);
        ig_md.common.iif = ig_md.tunnel.tmp_iif;
        ig_md.common.iif_type = SWITCH_L2_IIF_TYPE;
    }

    table vxlan_terminate {
        key = {
            hdr.vxlan.vni : exact;
            ig_md.tunnel.ip_addr_miss : exact;
        }
        actions = {
            set_terminate_properties;
            NoAction;
        }
        const default_action = NoAction;
        size = vxlan_terminate_table_size;
    }

    table vxlan_terminate_back {
        key = {
            hdr.vxlan.vni : ternary;
            ig_md.tunnel.ip_addr_miss : ternary;
        }
        actions = {
            set_terminate_properties;
            NoAction;
        }
        const default_action = NoAction;
        size = vxlan_terminate_back_size;
    }

    apply{
        switch(vxlan_terminate.apply().action_run) {
            NoAction: {
                vxlan_terminate_back.apply();
            }
        }
    }
}

control L4ENCAP(
        inout switch_header_t hdr,
        inout switch_egress_metadata_t eg_md)(
        switch_uint32_t l4_encap_table_size,
        switch_uint32_t set_smac_table_size){

    action l4_encap_set_ethernet(bit<48> dst_addr, switch_lif_t l3oif, bool l4_encap_flag) {
        eg_md.tunnel.dst_addr = dst_addr;
        eg_md.tunnel.vxlan_l4_encap_flag = l4_encap_flag;
        eg_md.route.l4_l3oif = l3oif;
        // eg_md.route.l4_l3oif = l4_encap_flag ? l3oif : eg_md.route.l4_l3oif;
    }

    @use_hash_action(1)
    @ignore_table_dependency("Eg_fabric.mpls_php_ttl_reset.ttl_reset")
    table l4_encap {
        key = {
            eg_md.tunnel.l4_encap : exact;
        }
        actions = {
            l4_encap_set_ethernet;
        }
        const default_action = l4_encap_set_ethernet(0,0,false);
        size = l4_encap_table_size;
    }

    action set_smac_with_evlan(bit<48> src_addr, bit<16> evlan) {
        hdr.ethernet.setValid();
        hdr.ethernet.dst_addr = eg_md.tunnel.dst_addr;
        hdr.ethernet.src_addr = src_addr;
        eg_md.common.pkt_type = FABRIC_PKT_TYPE_ETH;
        eg_md.ebridge.evlan = evlan;//出口是PW口
    }

    @use_hash_action(1)
    table set_smac {
        key = {
            eg_md.route.l4_l3oif : exact;
        }
        actions = {
            set_smac_with_evlan;
        }
        const default_action = set_smac_with_evlan(0,0);
        size = set_smac_table_size;
    }

    apply {
        l4_encap.apply();
        if(eg_md.tunnel.vxlan_l4_encap_flag == true) {
            set_smac.apply();
        }
    }
}

control EvlanMapVni(
        inout switch_egress_metadata_t eg_md)(
        switch_uint32_t evlan_map_vni_table_size) {

    action evlan_to_vni_map(bit<24> vni, switch_ptag_action_t p_action) {
        eg_md.tunnel.vni = vni;
        eg_md.tunnel.ptag_eg_action = p_action;//RAW MODE
    }

    @ignore_table_dependency("Eg_downlink.mpls_vc_encap.mpls_vc_rewrite")
    @ignore_table_dependency("Eg_downlink.mpls_vc_encap.mpls_vc_label_rewrite")
    @ignore_table_dependency("Eg_downlink.mpls_vc_encap.mpls_vc_ttl_rewrite")
    @use_hash_action(1)
    //@stage(3)
    table evlan_vni_mapping {
        key = {
            eg_md.ebridge.evlan[12:0] : exact;
        }
        actions = {
            evlan_to_vni_map;
        }
        const default_action = evlan_to_vni_map(0,0);
        size = evlan_map_vni_table_size;
    }

    apply {
        if((eg_md.tunnel.encap_type == SWITCH_TUNNEL_ENCAP_TYPE_V4_VXLAN) ||
            (eg_md.tunnel.encap_type == SWITCH_TUNNEL_ENCAP_TYPE_V6_VXLAN)) {
            evlan_vni_mapping.apply();
        }
    }
}
# 211 "/mnt/p4c-4127/p4src/switch-tofino2/switch_tofino_x1.p4" 2
# 1 "/mnt/p4c-4127/p4src/shared/mpls_ILM.p4" 1
/* mpls_ilm by lichunfeng */
/* pipline 0 */
/*nexthop lookup in FPGA, bfn label action：terminate && pop_continue */

control MPLS_ILM0(
        inout switch_header_t hdr,
        inout switch_ingress_metadata_t ig_md) {

    action pop_common(bit<1> copy) {
        ig_md.tunnel.ttl_copy = copy;
        ig_md.tunnel.ttl_copy_1 = copy;
        ig_md.tunnel.ttl_1 = hdr.mpls_ig[0].ttl;
        ig_md.tunnel.exp = hdr.mpls_ig[0].exp;
    }

    action pop1(bit<1> copy) {
        pop_common(copy);
        hdr.mpls_ig.pop_front(1);
        ig_md.tunnel.continue = true;
    }

    action pop2(bit<1> copy) {
        pop_common(copy);
        hdr.mpls_ig.pop_front(2);
        ig_md.tunnel.continue = true;
    }

    action pop3(bit<1> copy) {
        pop_common(copy);
        hdr.mpls_ig.pop_front(3);
        ig_md.tunnel.continue = true;
    }

    action explicit_null_pop(bit<1> copy, bit<1> chgDSCP_disable) {
        pop_common(copy);
        ig_md.tunnel.bos = hdr.mpls_ig[0].bos;
        hdr.mpls_ig.pop_front(1);
        ig_md.tunnel.terminate = true;
        ig_md.tunnel.continue = false;
        //ig_md.tunnel.inner_pkt_parsed = SWITCH_TUNNEL_INNER_PKT_IPX;
        ig_md.qos.chgDSCP_disable = chgDSCP_disable;
    }

    action pop2_terminate(bit<1> copy, bit<1> chgDSCP_disable) {
        pop_common(copy);
        ig_md.tunnel.bos = hdr.mpls_ig[1].bos;
        hdr.mpls_ig.pop_front(2);
        ig_md.tunnel.terminate = true;
        ig_md.tunnel.continue = false;
        //ig_md.tunnel.inner_pkt_parsed = SWITCH_TUNNEL_INNER_PKT_IPX;
        ig_md.qos.chgDSCP_disable = chgDSCP_disable;
    }

    action pop3_terminate(bit<1> copy, bit<1> chgDSCP_disable) {
        pop_common(copy);
        ig_md.tunnel.bos = hdr.mpls_ig[2].bos;
        hdr.mpls_ig.pop_front(3);
        ig_md.tunnel.terminate = true;
        ig_md.tunnel.continue = false;
        //ig_md.tunnel.inner_pkt_parsed = SWITCH_TUNNEL_INNER_PKT_IPX;
        ig_md.qos.chgDSCP_disable = chgDSCP_disable;
    }

    action miss() {
        ig_md.tunnel.ttl_copy_1 = 1w0;
        ig_md.tunnel.ttl_1 = hdr.mpls_ig[0].ttl;
        ig_md.tunnel.exp = hdr.mpls_ig[0].exp;
        ig_md.tunnel.continue = true;
    }

    action drop_reason() {
        ig_md.tunnel.continue = false;
        ig_md.common.drop_reason = SWITCH_DROP_REASON_MPLS_POP_ERROR;
    }

    action special_ttl_process() {
        ig_md.tunnel.continue = false;
    }

    /* 空标签判断 */
    @stage(5)
    table mpls_ilm0 {
         key = {
            hdr.mpls_ig[0].isValid(): ternary;
            hdr.mpls_ig[1].isValid(): ternary;
            hdr.mpls_ig[2].isValid(): ternary;
            hdr.mpls_ig[3].isValid(): ternary;
            hdr.mpls_ig[0].label: ternary;
            hdr.mpls_ig[1].label: ternary;
            hdr.mpls_ig[0].ttl: ternary;
        }

        actions = {
            pop1;
            pop2;
            pop3;
            pop3_terminate;
            pop2_terminate;
            explicit_null_pop;
            drop_reason;
            // special_ttl_process;
            miss;
        }

        const entries = {
            // (true, _, _, _, _, _, 0): special_ttl_process();
            // (true, _, _, _, _, _, 1): special_ttl_process();
            (true, true, true, true, 0, 7, _): pop3(0);
            (true, true, true, false, 0, 7, _): pop3_terminate(0, 0);
            (true, true, false, false, 0, 7, _): drop_reason();
            (true, true, true, true, 2, 7, _): pop3(0);
            (true, true, true, false, 2, 7, _): pop3_terminate(0, 0);
            (true, true, false, false, 2, 7, _): drop_reason();
            (true, true, true, _, 7, _, _): pop2(0);
            (true, true, false, _, 7, _, _): pop2_terminate(0, 0);
            (true, false, false, _, 7, _, _): drop_reason();
            (true, true, _, _, 0, _, _) : pop1(0);
            (true, true, _, _, 2, _, _) : pop1(0);
            (true, false, _, _, 0, _, _) : explicit_null_pop(0, 0);
            (true, false, _, _, 2, _, _) : explicit_null_pop(0, 0);
        }

        const default_action = miss;
        size = 512;
    }

    apply {
        mpls_ilm0.apply();
    }
}

control MPLS_ILM1(
        inout switch_header_t hdr,
        inout switch_ingress_metadata_t ig_md)(
        switch_uint32_t ilm_table_size,
        switch_uint32_t ilm_back_table_size,
        switch_uint32_t pop_table_size) {

    action pop_continue(bit<1> copy, bit<1> chgDSCP_disable) {
        ig_md.tunnel.ttl_copy = copy;
        ig_md.tunnel.ttl_copy_2 = copy;
        ig_md.tunnel.ttl_2 = hdr.mpls_ig[0].ttl;
        ig_md.qos.chgDSCP_disable = chgDSCP_disable;
    }

    action miss_back() {
        ig_md.tunnel.continue = true;
        ig_md.tunnel.ttl_copy_2 = ig_md.tunnel.ttl_copy_1;
        ig_md.tunnel.ttl_2 = ig_md.tunnel.ttl_1;
    }

    action miss() {

    }

    table mpls_ilm1 {
         key = {
            hdr.mpls_ig[0].label: exact;
        }
        actions = {
            pop_continue;
            miss;
        }
        const default_action = miss;
        size = ilm_table_size;
    }

    action pop1() {
        hdr.mpls_ig.pop_front(1);
        ig_md.tunnel.continue = true;
    }

    action pop3() {
        hdr.mpls_ig.pop_front(3);
        ig_md.tunnel.continue = true;
    }

    action pop4() {
        hdr.mpls_ig.pop_front(4);
        ig_md.tunnel.continue = true;
    }

    action pop_terminate() {
        ig_md.tunnel.bos = hdr.mpls_ig[0].bos;
        hdr.mpls_ig.pop_front(1);
        ig_md.tunnel.terminate = true;
        ig_md.tunnel.continue = false;
        //ig_md.tunnel.inner_pkt_parsed = SWITCH_TUNNEL_INNER_PKT_IPX;
    }

    action pop3_terminate() {
        ig_md.tunnel.bos = hdr.mpls_ig[2].bos;
        hdr.mpls_ig.pop_front(3);
        ig_md.tunnel.terminate = true;
        ig_md.tunnel.continue = false;
    }

    action drop_reason() {
        ig_md.tunnel.continue = false;
        ig_md.common.drop_reason = SWITCH_DROP_REASON_MPLS_POP_ERROR;
    }

    table pop_num1 {
        key = {
            hdr.mpls_ig[1].isValid(): exact;
            hdr.mpls_ig[2].isValid(): ternary;
            hdr.mpls_ig[3].isValid(): ternary;
            // hdr.mpls_ig[4].isValid(): ternary;
            // hdr.mpls_ig[0].label: ternary;
            hdr.mpls_ig[1].label: ternary;
            // hdr.mpls_ig[3].label: ternary;
            // hdr.mpls_ig[0].bos: ternary;
        }
        actions = {
            pop1;
            pop3;
            // pop4;
            pop_terminate;
            pop3_terminate;
            drop_reason;
        }

        const entries = {
            (true, true, true, 7) : pop3();
            (true, true, false, 7) : pop3_terminate();
            (true, false, false, 7) : drop_reason();
            (true, _, _, _) : pop1();
            (false, _, _, _) : pop_terminate();
        }

        const default_action = drop_reason;
        size = pop_table_size;
    }

    table ilm1_back {
         key = {
            hdr.mpls_ig[0].label: ternary;
        }
        actions = {
            pop_continue;
            miss_back;
        }
        const default_action = miss_back;
        size = ilm_back_table_size;
    }

    apply {
        if (ig_md.tunnel.continue == true) {
            switch(mpls_ilm1.apply().action_run) {
                pop_continue: {
                    pop_num1.apply();
                }
                miss: {
                    switch(ilm1_back.apply().action_run) {
                        pop_continue: {
                            pop_num1.apply();
                        }
                    }
                }
            }
        }
    }
}

control MPLS_ILM2(
        inout switch_header_t hdr,
        inout switch_ingress_metadata_t ig_md)(
        switch_uint32_t ilm_table_size,
        switch_uint32_t ilm_back_table_size,
        switch_uint32_t pop_table_size) {

    action pop_continue(bit<1> copy, bit<1> chgDSCP_disable) {
        ig_md.tunnel.ttl_copy = copy;
        ig_md.tunnel.ttl_copy_3 = copy;
        ig_md.tunnel.ttl_3 = hdr.mpls_ig[0].ttl;
        ig_md.qos.chgDSCP_disable = chgDSCP_disable;
        // ig_md.tunnel.ttl_1_2 =  ig_md.tunnel.ttl_1 |-|  hdr.mpls_ig[0].ttl;
    }

    action miss_back() {
        ig_md.tunnel.continue = true;
        ig_md.tunnel.ttl_copy_3 = ig_md.tunnel.ttl_copy_2;
        ig_md.tunnel.ttl_3 = ig_md.tunnel.ttl_2;
    }

    action miss() {

    }

    table mpls_ilm2 {
         key = {
            hdr.mpls_ig[0].label: exact;
        }
        actions = {
            pop_continue;
            miss;
        }
        const default_action = miss;
        size = ilm_table_size;
    }

    action pop1() {
        hdr.mpls_ig.pop_front(1);
        ig_md.tunnel.continue = true;
    }

    action pop3() {
        hdr.mpls_ig.pop_front(3);
        ig_md.tunnel.continue = true;
    }

    action pop4() {
        hdr.mpls_ig.pop_front(4);
        ig_md.tunnel.continue = true;
    }

    action pop_terminate() {
        ig_md.tunnel.bos = hdr.mpls_ig[0].bos;
        hdr.mpls_ig.pop_front(1);
        ig_md.tunnel.terminate = true;
        ig_md.tunnel.continue = false;
        //ig_md.tunnel.inner_pkt_parsed = SWITCH_TUNNEL_INNER_PKT_IPX;
    }

    action pop3_terminate() {
        ig_md.tunnel.bos = hdr.mpls_ig[2].bos;
        hdr.mpls_ig.pop_front(3);
        ig_md.tunnel.terminate = true;
        ig_md.tunnel.continue = false;
    }

    action drop_reason() {
        ig_md.tunnel.continue = false;
        ig_md.common.drop_reason = SWITCH_DROP_REASON_MPLS_POP_ERROR;
    }

    table pop_num2 {
        key = {
            hdr.mpls_ig[1].isValid(): exact;
            hdr.mpls_ig[2].isValid(): ternary;
            hdr.mpls_ig[3].isValid(): ternary;
            // hdr.mpls_ig[4].isValid(): ternary;
            // hdr.mpls_ig[0].label: ternary;
            hdr.mpls_ig[1].label: ternary;
            // hdr.mpls_ig[3].label: ternary;
            // hdr.mpls_ig[0].bos: ternary;
        }
        actions = {
            pop1;
            pop3;
            // pop4;
            pop_terminate;
            pop3_terminate;
            drop_reason;
        }

        const entries = {
            (true, true, true, 7) : pop3();
            (true, true, false, 7) : pop3_terminate();
            (true, false, false, 7) : drop_reason();
            (true, _, _, _) : pop1();
            (false, _, _, _) : pop_terminate();
        }

        const default_action = drop_reason;
        size = pop_table_size;
    }

    table ilm2_back {
         key = {
            hdr.mpls_ig[0].label: ternary;
        }
        actions = {
            pop_continue;
            miss_back;
        }
        const default_action = miss_back;
        size = ilm_back_table_size;
    }

    apply {
        if (ig_md.tunnel.continue == true) {
            switch(mpls_ilm2.apply().action_run) {
                pop_continue: {
                    pop_num2.apply();
                }
                miss: {
                    switch(ilm2_back.apply().action_run) {
                        pop_continue: {
                            pop_num2.apply();
                        }
                    }
                }
            }
        }
    }
}

control MPLS_ILM3(
        inout switch_header_t hdr,
        inout switch_ingress_metadata_t ig_md)(
        switch_uint32_t ilm3_table_size,
        switch_uint32_t ilm_back_table_size,
        switch_uint32_t pop_table_size) {


    action pop_continue(bit<1> copy, bit<1> chgDSCP_disable) {
        ig_md.tunnel.ttl_copy = copy;
        ig_md.tunnel.ttl_copy_4 = copy;
        ig_md.tunnel.ttl_4 = hdr.mpls_ig[0].ttl;
        ig_md.qos.chgDSCP_disable = chgDSCP_disable;
        // ig_md.tunnel.ttl_1_3 =  ig_md.tunnel.ttl_1 |-| hdr.mpls_ig[0].ttl;
        // ig_md.tunnel.ttl_2_3 =  ig_md.tunnel.ttl_2 |-| hdr.mpls_ig[0].ttl;
    }

    action pop_terminate_l3(switch_lif_t lif, bit<1> copy, bit<1> chgDSCP_disable) {
        ig_md.tunnel.ttl_copy_4 = copy;
        ig_md.tunnel.ttl_4 = hdr.mpls_ig[0].ttl;
        // ig_md.tunnel.ttl_1_3 =  ig_md.tunnel.ttl_1 |-| hdr.mpls_ig[0].ttl;
        // ig_md.tunnel.ttl_2_3 =  ig_md.tunnel.ttl_2 |-| hdr.mpls_ig[0].ttl;
        add_ext_tunnel_decap(hdr, ig_md);

        ig_md.common.iif = lif;
        ig_md.common.iif_type = SWITCH_L3_IIF_TYPE;
        ig_md.tunnel.continue = false;
        ig_md.tunnel.terminate = true;
        ig_md.tunnel.bos = hdr.mpls_ig[0].bos;
        hdr.mpls_ig.pop_front(1);
        // ig_md.tunnel.inner_pkt_parsed = SWITCH_TUNNEL_INNER_PKT_IPX;
        ig_md.tunnel.ttl_copy = copy;
        ig_md.qos.chgDSCP_disable = chgDSCP_disable;
    }

    action pop_terminate_l2(switch_lif_t lif) {
        ig_md.tunnel.ttl_copy_4 = 1w0;
        ig_md.tunnel.ttl_4 = hdr.mpls_ig[0].ttl;
        // ig_md.tunnel.ttl_1_3 =  ig_md.tunnel.ttl_1 |-| hdr.mpls_ig[0].ttl;
        // ig_md.tunnel.ttl_2_3 =  ig_md.tunnel.ttl_2 |-| hdr.mpls_ig[0].ttl;
        add_ext_tunnel_decap(hdr, ig_md);

        ig_md.common.iif = lif;
        ig_md.common.iif_type = SWITCH_L2_IIF_TYPE;
        // ig_md.tunnel.cw_mode = cw_mode;
        ig_md.tunnel.continue = false;
        ig_md.tunnel.terminate = true;
        ig_md.tunnel.inner_pkt_parsed = SWITCH_TUNNEL_INNER_PKT_ETHERNET;
        ig_md.tunnel.ttl_copy = 1w0;
    }


    action miss_back() {
        ig_md.tunnel.continue = true;
        ig_md.tunnel.ttl_copy_4 = ig_md.tunnel.ttl_copy_3;
        ig_md.tunnel.ttl_4 = ig_md.tunnel.ttl_3;
    }

    action miss() {

    }

    @stage(8)
    table mpls_ilm3 {
         key = {
            hdr.mpls_ig[0].label: exact;
        }
        actions = {
            pop_continue;
            pop_terminate_l3;
            pop_terminate_l2;
            miss;
        }
        const default_action = miss;
        size = ilm3_table_size;
    }

    action pop1() {
        hdr.mpls_ig.pop_front(1);
        ig_md.tunnel.continue = true;
    }

    action pop3() {
        hdr.mpls_ig.pop_front(3);
        ig_md.tunnel.continue = true;
    }

    action pop4() {
        hdr.mpls_ig.pop_front(4);
        ig_md.tunnel.continue = true;
    }

    action pop_terminate() {
        ig_md.tunnel.bos = hdr.mpls_ig[0].bos;
        hdr.mpls_ig.pop_front(1);
        ig_md.tunnel.terminate = true;
        ig_md.tunnel.continue = false;
        //ig_md.tunnel.inner_pkt_parsed = SWITCH_TUNNEL_INNER_PKT_IPX;
    }

    action pop3_terminate() {
        ig_md.tunnel.bos = hdr.mpls_ig[2].bos;
        hdr.mpls_ig.pop_front(3);
        ig_md.tunnel.terminate = true;
        ig_md.tunnel.continue = false;
    }

    action drop_reason() {
        ig_md.tunnel.continue = false;
        ig_md.common.drop_reason = SWITCH_DROP_REASON_MPLS_POP_ERROR;
    }

    table pop_num3 {
        key = {
            hdr.mpls_ig[1].isValid(): exact;
            hdr.mpls_ig[2].isValid(): ternary;
            hdr.mpls_ig[3].isValid(): ternary;
            // hdr.mpls_ig[4].isValid(): ternary;
            // hdr.mpls_ig[0].label: ternary;
            hdr.mpls_ig[1].label: ternary;
            // hdr.mpls_ig[3].label: ternary;
            // hdr.mpls_ig[0].bos: ternary;
        }
        actions = {
            pop1;
            pop3;
            // pop4;
            pop_terminate;
            pop3_terminate;
            drop_reason;
        }

        const entries = {
            (true, true, true, 7) : pop3();
            (true, true, false, 7) : pop3_terminate();
            (true, false, false, 7) : drop_reason();
            (true, _, _, _) : pop1();
            (false, _, _, _) : pop_terminate();
        }

        const default_action = drop_reason;
        size = pop_table_size;
    }

    action l2_pop1() {
        ig_md.tunnel.bos = hdr.mpls_ig[0].bos;
        hdr.mpls_ig.pop_front(1);
    }

    action pop_with_flow_label() {
        ig_md.tunnel.bos = hdr.mpls_ig[1].bos;
        ig_md.tunnel.entropy_label = hdr.mpls_ig[1].label;
        hdr.mpls_ig.pop_front(2);
    }

    table l2_terminate_pop3 {
        key = {
            hdr.mpls_ig[1].isValid(): exact;
        }
        actions = {
            l2_pop1;
            pop_with_flow_label;
        }

        // const entries = {
        //     (true) : pop_with_flow_label();
        //     (false) : l2_pop1();
        // }

        const default_action = l2_pop1;
        size = 2;
    }

    table ilm3_back {
         key = {
            hdr.mpls_ig[0].label: ternary;
        }
        actions = {
            pop_continue;
            pop_terminate_l3;
            pop_terminate_l2;
            miss_back;
        }
        const default_action = miss_back;
        size = ilm_back_table_size;
    }

    apply {
        if (ig_md.tunnel.continue == true) {
            switch(mpls_ilm3.apply().action_run) {
                pop_continue: {
                    pop_num3.apply();
                }
                pop_terminate_l2: {
                    l2_terminate_pop3.apply();
                }
                miss: {
                    switch(ilm3_back.apply().action_run) {
                        pop_continue: {
                            pop_num3.apply();
                        }
                        pop_terminate_l2: {
                            l2_terminate_pop3.apply();
                        }
                    }
                }
            }
        }
    }
}

control IngressMPLS(
        inout switch_header_t hdr,
        inout switch_ingress_metadata_t ig_md)(
        switch_uint32_t ilm_table_size,
        switch_uint32_t ilm3_table_size,
        switch_uint32_t ilm_back_table_size = 512,
        switch_uint32_t pop_table_size = 64) {

    MPLS_ILM0() ilm0;
    MPLS_ILM1(ilm_table_size, ilm_back_table_size, pop_table_size) ilm1;
    MPLS_ILM2(ilm_table_size, ilm_back_table_size, pop_table_size) ilm2;
    MPLS_ILM3(ilm3_table_size, ilm_back_table_size, pop_table_size) ilm3;

    apply {

        if (ig_md.tunnel.mpls_enable == true) {
            ilm0.apply(hdr, ig_md);
            ilm1.apply(hdr, ig_md);
            // ilm2.apply(hdr, ig_md);
            // ilm3.apply(hdr, ig_md);
        }

    }
}

control TTLDecision(
        inout switch_ingress_metadata_t ig_md) {

    // Hash<bit<8>>(HashAlgorithm_t.IDENTITY) hash_ttl1;
    // Hash<bit<8>>(HashAlgorithm_t.IDENTITY) hash_ttl2;
    // Hash<bit<8>>(HashAlgorithm_t.IDENTITY) hash_ttl3;
    // Hash<bit<8>>(HashAlgorithm_t.IDENTITY) hash_ttl4;

     action ttl_set_1() {
         ig_md.tunnel.ttl = ig_md.tunnel.ttl_1;//hash_ttl1.get(ig_md.tunnel.ttl_1);
     }

     action ttl_set_2() {
        ig_md.tunnel.ttl = ig_md.tunnel.ttl_2;//hash_ttl2.get(ig_md.tunnel.ttl_2);
    }

    action ttl_set_3() {
        ig_md.tunnel.ttl = ig_md.tunnel.ttl_3;//hash_ttl3.get(ig_md.tunnel.ttl_3);
    }

    action ttl_set_4() {
        ig_md.tunnel.ttl = ig_md.tunnel.ttl_4;//hash_ttl4.get(ig_md.tunnel.ttl_4);
    }

    table ttl_decision {
        key = {
            ig_md.tunnel.ttl_copy: exact;
            ig_md.tunnel.ttl_copy_1: exact;
            ig_md.tunnel.ttl_copy_2: exact;
            ig_md.tunnel.ttl_copy_3: exact;
            ig_md.tunnel.ttl_copy_4: exact;
        }
        actions = {
            ttl_set_1;
            ttl_set_2;
            ttl_set_3;
            ttl_set_4;
            NoAction;
        }

        const entries = {
            (1, 1, 0, 0, 0) : ttl_set_1();
            (1, 1, 1, 0, 0) : ttl_set_1();
            (1, 1, 1, 1, 0) : ttl_set_1();
            (1, 1, 1, 1, 1) : ttl_set_1();
            (1, 0, 1, 0, 0) : ttl_set_2();
            (1, 0, 1, 1, 0) : ttl_set_2();
            (1, 0, 1, 1, 1) : ttl_set_2();
            (1, 0, 0, 1, 0) : ttl_set_3();
            (1, 0, 0, 1, 1) : ttl_set_3();
            (1, 1, 0, 1, 0) : ttl_set_3();
            (1, 1, 0, 1, 1) : ttl_set_3();
            (1, 0, 0, 0, 1) : ttl_set_4();
            (1, 1, 0, 0, 1) : ttl_set_4();
            (1, 0, 1, 0, 1) : ttl_set_4();
            (1, 1, 1, 0, 1) : ttl_set_4();
        }

        const default_action = NoAction;
        size = 32;
    }

    apply {

        if (ig_md.tunnel.mpls_enable == true) {
            ttl_decision.apply();
        }

    }
}

control MPLS_PHP(
        inout switch_header_t hdr,
        inout switch_egress_metadata_t eg_md)(
        switch_uint32_t php_pop_table_size = 16) {

    // bit<8> dec_ttl=1;

    action pop() {
        eg_md.tunnel.is_php = 1;
        eg_md.tunnel.php_ttl = hdr.mpls_ig[0].ttl |-| eg_md.common.dec_ttl;
        eg_md.tunnel.tmp_ttl = hdr.mpls_ig[0].ttl |-| hdr.mpls_ig[1].ttl;
        //hdr.mpls_ig.pop_front(1);
        hdr.mpls_ig[0].setInvalid();
    }

    action pop_ter_v4() {
        eg_md.tunnel.is_php = 1;
        eg_md.tunnel.php_ttl = hdr.mpls_ig[0].ttl |-| eg_md.common.dec_ttl;
        eg_md.tunnel.tmp_ttl = hdr.mpls_ig[0].ttl |-| hdr.inner_ipv4.ttl;
        eg_md.common.pkt_type = FABRIC_PKT_TYPE_IPV4;
        eg_md.tunnel.php_terminate = true;
        //hdr.mpls_ig.pop_front(1);
        hdr.mpls_ig[0].setInvalid();
    }

    action pop_ter_v6() {
        eg_md.tunnel.is_php = 1;
        eg_md.tunnel.php_ttl = hdr.mpls_ig[0].ttl |-| eg_md.common.dec_ttl;
        eg_md.tunnel.tmp_ttl = hdr.mpls_ig[0].ttl |-| hdr.inner_ipv6.hop_limit;
        eg_md.common.pkt_type = FABRIC_PKT_TYPE_IPV6;
        eg_md.tunnel.php_terminate = true;
        //hdr.mpls_ig.pop_front(1);
        hdr.mpls_ig[0].setInvalid();
    }

    table php_pop {
        key = {
            eg_md.common.pkt_type : exact;
            hdr.mpls_ig[0].isValid(): exact;
            hdr.mpls_ig[1].isValid(): exact;
            hdr.inner_ipv4.isValid(): exact;
            hdr.inner_ipv6.isValid(): exact;
            eg_md.tunnel.opcode : exact;
            eg_md.tunnel.phpcopy : exact;
            // hdr.fabric_var_ext_2_8bit.data_lo[6:3]: exact;
        }
        actions = {
            pop;
            pop_ter_v4;
            pop_ter_v6;
            NoAction;
        }

        const entries = {
            (FABRIC_PKT_TYPE_MPLS, true, true, true, false, SWITCH_MPLS_POP, 0) : pop();
            (FABRIC_PKT_TYPE_MPLS, true, true, false, true, SWITCH_MPLS_POP, 0) : pop();
            (FABRIC_PKT_TYPE_MPLS, true, true, false, false, SWITCH_MPLS_POP, 0) : pop();
            (FABRIC_PKT_TYPE_MPLS, true, false, true, false, SWITCH_MPLS_POP, 0) : pop_ter_v4();
            (FABRIC_PKT_TYPE_MPLS, true, false, false, true, SWITCH_MPLS_POP, 0) : pop_ter_v6();
            (FABRIC_PKT_TYPE_MPLS, true, true, true, false, SWITCH_MPLS_POP, 1) : pop();
            (FABRIC_PKT_TYPE_MPLS, true, true, false, true, SWITCH_MPLS_POP, 1) : pop();
            (FABRIC_PKT_TYPE_MPLS, true, true, false, false, SWITCH_MPLS_POP, 1) : pop();
            (FABRIC_PKT_TYPE_MPLS, true, false, true, false, SWITCH_MPLS_POP, 1) : pop_ter_v4();
            (FABRIC_PKT_TYPE_MPLS, true, false, false, true, SWITCH_MPLS_POP, 1) : pop_ter_v6();
        }
        const default_action = NoAction;
        size = php_pop_table_size;
    }

    apply{

        php_pop.apply();
        // ttl_get_tmpttl.apply();

    }
}

control MPLS_PHP_TTL_RESET(
        inout switch_header_t hdr,
        inout switch_egress_metadata_t eg_md) {

    action rewrite_ipv4_ttl() {
        hdr.inner_ipv4.ttl = eg_md.tunnel.php_ttl;// |-| eg_md.common.dec_ttl;
    }

    action rewrite_ipv6_ttl() {
        hdr.inner_ipv6.hop_limit = eg_md.tunnel.php_ttl;// |-| eg_md.common.dec_ttl;
    }

    action rewrite_mpls_ttl() {
        hdr.mpls_ig[1].ttl = eg_md.tunnel.php_ttl;// |-| eg_md.common.dec_ttl;
    }

    table ttl_reset {
        key = {

            hdr.inner_ipv4.isValid() : exact;
            hdr.inner_ipv6.isValid() : exact;
            eg_md.tunnel.php_terminate : exact;
            hdr.mpls_ig[1].isValid() : exact;
            eg_md.tunnel.tmp_ttl : exact;
            eg_md.tunnel.phpcopy : exact;
            eg_md.tunnel.opcode : exact;
            // hdr.fabric_var_ext_2_8bit.data_lo[7:7] : exact;
            // hdr.fabric_var_ext_2_8bit.data_lo[6:3]: exact;
        }
        actions = {
            rewrite_ipv4_ttl;
            rewrite_ipv6_ttl;
            rewrite_mpls_ttl;
        }

        const entries = {
            (true, false, true, false, 0, 1, SWITCH_MPLS_POP) : rewrite_ipv4_ttl();
            (false, true, true, false, 0, 1, SWITCH_MPLS_POP) : rewrite_ipv6_ttl();
            (true, false, false, true, 0, 1, SWITCH_MPLS_POP) : rewrite_mpls_ttl();
            (false, true, false, true, 0, 1, SWITCH_MPLS_POP) : rewrite_mpls_ttl();
            (false, false, false, true, 0, 1, SWITCH_MPLS_POP) : rewrite_mpls_ttl();
        }

        size = 32;
    }

    apply{

        ttl_reset.apply();

    }
}

control MPLS_OPCODE_CHECK(
        inout switch_header_t hdr,
        inout switch_egress_metadata_t eg_md) {

    action change_opcode(bit<4> opcode) {
        eg_md.tunnel.opcode = opcode;
    }

    table opcode_check {
        key = {
            eg_md.common.l3_encap : exact;
            eg_md.tunnel.l4_encap : exact;
            eg_md.tunnel.opcode : exact;
        }
        actions = {
           change_opcode;
           NoAction;
        }

        // const entries = {
        //     (0, 0, SWITCH_MPLS_SWAP_PUSH) : change_opcode(SWITCH_MPLS_POP);
        //     (0, 0, SWITCH_MPLS_SWAP_ENCAP) : change_opcode(SWITCH_MPLS_POP);
        // }

        const default_action = NoAction;
        size = 32;
    }

    apply{
        opcode_check.apply();
    }

}
# 212 "/mnt/p4c-4127/p4src/switch-tofino2/switch_tofino_x1.p4" 2
# 1 "/mnt/p4c-4127/p4src/shared/mpls_encap.p4" 1

/* by jiangminda */
/* L4 encap properties */
control MPLS_VC_encap(
        inout switch_header_t hdr,
        inout switch_egress_metadata_t eg_md)(
        switch_uint32_t vc_encap_table_size) {

    bit<8> vc_ttl = 0;
    bit<3> vc_exp_mode = 0;
    switch_mpls_vc_encap_opcode_t opcode = 0;

    // action swap(bit<20> label, bit<3> exp, bit<8> ttl, bit<3> exp_mode) {
    //     hdr.mpls_vc_eg.label = label;
    //     hdr.mpls_vc_eg.exp = exp;
    //     hdr.mpls_vc_eg.ttl = ttl;
    //     vc_exp_mode = exp_mode;
    //     vc_ttl = ttl;
    //     label_num = 1;
    //     eg_md.tunnel.encap_type = SWITCH_TUNNEL_ENCAP_TYPE_MPLS;//is useful ?
    // }

    // action swap_to_self(bit<20> label, bit<3> exp, bit<8> ttl, bit<3> exp_mode, bool to_self) {
    //     hdr.mpls_vc_eg.label = to_self? hdr.mpls_vc_eg.label: label;
    //     hdr.mpls_vc_eg.exp = exp;
    //     hdr.mpls_vc_eg.ttl = ttl;
    //     vc_exp_mode = exp_mode;
    //     vc_ttl = ttl;
    // }

    // action swap_to_self(bit<3> exp, bit<8> ttl, bit<3> exp_mode) {
    //     hdr.mpls_vc_eg.exp = exp;
    //     hdr.mpls_vc_eg.ttl = ttl;
    //     vc_exp_mode = exp_mode;
    //     vc_ttl = ttl;
    //     label_num = 1;
    //     eg_md.tunnel.encap_type = SWITCH_TUNNEL_ENCAP_TYPE_MPLS;
    // }

    // action push_vc_label(bit<20> label, bit<3> exp, bit<1> bos,  bit<8> ttl) {
    //     hdr.mpls_vc_eg.setValid();
    //     hdr.mpls_vc_eg.label = label;
    //     hdr.mpls_vc_eg.exp = exp;
    //     hdr.mpls_vc_eg.bos = bos;
    //     hdr.mpls_vc_eg.ttl = ttl;
    // }

    action push_tunnel_label_9(bit<20> label, bit<3> exp, bit<1> bos, bit<8> ttl) {
        hdr.mpls_eg[9 -9].setValid();
        hdr.mpls_eg[9 -9].label = label;
        hdr.mpls_eg[9 -9].exp = exp;
        hdr.mpls_eg[9 -9].bos = bos;
        hdr.mpls_eg[9 -9].ttl = ttl;
    }

    // action push_vc(bit<20> label, bit<3> exp, bit<8> ttl, bit<3> exp_mode) {
    //     push_vc_label(label, exp, 1, ttl);
    //     vc_exp_mode = exp_mode;
    //     vc_ttl = ttl;
    //     eg_md.tunnel.next_hdr_type = SWITCH_TUNNEL_NEXT_HDR_TYPE_MPLS;
    //     eg_md.tunnel.encap_type = SWITCH_TUNNEL_ENCAP_TYPE_MPLS;
    //     // eg_md.common.pkt_length = eg_md.common.pkt_length + 16w4;
    //     label_num = 1;
    // }

    action rewrite_vc_label_common(bit<20> label, bit<3> exp, bit<8> ttl, vlan_id_t p_vd, bit<3> exp_mode,
                                    switch_ptag_action_t p_action, switch_mpls_vc_encap_opcode_t op_code) {
        // push_vc_label(label, exp, bos, ttl);//default push vc label
        push_tunnel_label_9(label, exp, 1, ttl);

        vc_exp_mode = exp_mode;
        vc_ttl = ttl;
        eg_md.tunnel.ptag_vid = p_vd;
        eg_md.tunnel.ptag_eg_action = p_action;
        opcode = op_code;
    }

    @ignore_table_dependency("Eg_downlink.evlan_map_vni.evlan_map_vni")
    @use_hash_action(1)
    //@stage(2)
    table mpls_vc_rewrite {
         key = {
            eg_md.tunnel.l4_encap : exact;
        }
        actions = {
            // swap;
            // swap_to_self;
            // push_vc;
            rewrite_vc_label_common;
            // NoAction;
        }
        const default_action = rewrite_vc_label_common(0,0,0,0,0,0,0);
        size = vc_encap_table_size;
    }

    action rewrite_push_vc_label(){
        hdr.mpls_vc_eg.setValid();
        hdr.mpls_vc_eg.label = hdr.mpls_eg[9 -9].label;
        hdr.mpls_vc_eg.exp = hdr.mpls_eg[9 -9].exp;
        hdr.mpls_vc_eg.bos = hdr.mpls_eg[9 -9].bos;
        hdr.mpls_vc_eg.ttl = hdr.mpls_eg[9 -9].ttl;
        hdr.mpls_eg[9 -9].setInvalid();

        eg_md.common.pkt_length = eg_md.common.pkt_length + 16w4;
        eg_md.tunnel.next_hdr_type = SWITCH_TUNNEL_NEXT_HDR_TYPE_MPLS;
        eg_md.tunnel.encap_type = SWITCH_TUNNEL_ENCAP_TYPE_MPLS;
    }

    action rewrite_swap_label_common() {
        hdr.mpls_vc_eg.exp = hdr.mpls_eg[9 -9].exp;
        hdr.mpls_vc_eg.ttl = hdr.mpls_eg[9 -9].ttl;
        hdr.mpls_eg[9 -9].setInvalid();
        eg_md.tunnel.encap_type = SWITCH_TUNNEL_ENCAP_TYPE_MPLS;
    }

    action rewrite_swap_one_label() {
        hdr.mpls_vc_eg.label = hdr.mpls_eg[9 -9].label;
        rewrite_swap_label_common();
    }

    action rewrite_swap_self_label() {
        rewrite_swap_label_common();
    }

    action delete_push_one_label() {
        hdr.mpls_eg[9 -9].setInvalid();
    }

    @ignore_table_dependency("Eg_downlink.evlan_map_vni.evlan_map_vni")
    table mpls_vc_label_rewrite {
        key = {
            opcode : exact;
        }

        actions = {
            rewrite_push_vc_label;
            rewrite_swap_one_label;
            rewrite_swap_self_label;
            delete_push_one_label;
        }

        const entries = {
            (SWITCH_MPLS_VC_ENCAP_OPCODE_ACTION_MISS) : delete_push_one_label();
            (SWITCH_MPLS_VC_ENCAP_OPCODE_PUSH_L2) : rewrite_push_vc_label();
            (SWITCH_MPLS_VC_ENCAP_OPCODE_PUSH_VC) : rewrite_push_vc_label();
            (SWITCH_MPLS_VC_ENCAP_OPCODE_SWAP) : rewrite_swap_one_label();
            (SWITCH_MPLS_VC_ENCAP_OPCODE_SWAP_SELF) : rewrite_swap_self_label();
        }

        const default_action = delete_push_one_label;
        size = 8;
    }

    action rewrite_mpls_ttl() {
        hdr.mpls_vc_eg.ttl = eg_md.tunnel.ttl;
    }

    @ignore_table_dependency("Eg_downlink.evlan_map_vni.evlan_map_vni")
    table mpls_vc_ttl_rewrite {
        key = {
            vc_ttl : exact;
            opcode : exact;
        }

        actions = {
            rewrite_mpls_ttl;
            NoAction;
        }

        // const entries = {
        //     (0, SWITCH_MPLS_VC_ENCAP_OPCODE_PUSH_L2)   : rewrite_mpls_ttl();
        //     (0, SWITCH_MPLS_VC_ENCAP_OPCODE_PUSH_VC)   : rewrite_mpls_ttl();
        //     (0, SWITCH_MPLS_VC_ENCAP_OPCODE_SWAP)      : rewrite_mpls_ttl();
        //     (0, SWITCH_MPLS_VC_ENCAP_OPCODE_SWAP_SELF) : rewrite_mpls_ttl();
        // }

        const default_action = NoAction;
        size = 16;
    }

    action map_mpls_exp() {
        hdr.mpls_vc_eg.exp = eg_md.tunnel.exp;
    }

    action keep_mpls_swap_exp() {
        hdr.mpls_vc_eg.exp = eg_md.tunnel.vc_exp;
    }

    @ignore_table_dependency("Eg_downlink.mpls_encap0.mpls_tunnel0_rewrite.mpls_tunnel0_label_rewrite")
    table mpls_vc_exp_rewrite {
        key = {
            vc_exp_mode : exact;
            opcode : exact;
            eg_md.tunnel.qosphb : exact; //0/1
        }

        actions = {
            map_mpls_exp;
            keep_mpls_swap_exp;
            NoAction;
        }

        const entries = {
            (SWITCH_EXP_MODE_MAP, SWITCH_MPLS_VC_ENCAP_OPCODE_PUSH_L2, 0) : map_mpls_exp();
            (SWITCH_EXP_MODE_MAP, SWITCH_MPLS_VC_ENCAP_OPCODE_PUSH_L2, 1) : map_mpls_exp();

            (SWITCH_EXP_MODE_MAP, SWITCH_MPLS_VC_ENCAP_OPCODE_PUSH_VC, 0) : map_mpls_exp();
            (SWITCH_EXP_MODE_MAP, SWITCH_MPLS_VC_ENCAP_OPCODE_PUSH_VC, 1) : map_mpls_exp();

            (SWITCH_EXP_MODE_MAP, SWITCH_MPLS_VC_ENCAP_OPCODE_SWAP, 0) : keep_mpls_swap_exp();
            (SWITCH_EXP_MODE_MAP, SWITCH_MPLS_VC_ENCAP_OPCODE_SWAP, 1) : map_mpls_exp();

            (SWITCH_EXP_MODE_MAP, SWITCH_MPLS_VC_ENCAP_OPCODE_SWAP_SELF, 0) : keep_mpls_swap_exp();
            (SWITCH_EXP_MODE_MAP, SWITCH_MPLS_VC_ENCAP_OPCODE_SWAP_SELF, 1) : map_mpls_exp();

            (SWITCH_EXP_MODE_SWAP_KEEP, SWITCH_MPLS_VC_ENCAP_OPCODE_SWAP, 0) : keep_mpls_swap_exp();
            (SWITCH_EXP_MODE_SWAP_KEEP, SWITCH_MPLS_VC_ENCAP_OPCODE_SWAP, 1) : keep_mpls_swap_exp();

            (SWITCH_EXP_MODE_SWAP_KEEP, SWITCH_MPLS_VC_ENCAP_OPCODE_SWAP_SELF, 0) : keep_mpls_swap_exp();
            (SWITCH_EXP_MODE_SWAP_KEEP, SWITCH_MPLS_VC_ENCAP_OPCODE_SWAP_SELF, 1) : keep_mpls_swap_exp();
        }

        const default_action = NoAction;
        size = 16;
    }

    apply {
        mpls_vc_rewrite.apply();
        mpls_vc_label_rewrite.apply();
        mpls_vc_ttl_rewrite.apply();
        mpls_vc_exp_rewrite.apply();
    }
}

control MPLS_tunnel_0_encap(
        inout switch_header_t hdr,
        inout switch_egress_metadata_t eg_md,
        inout switch_egress_tunnel_metadata_t tunnel)(
        switch_uint32_t tunnel0_table_size) {

    bit<8> tunnel_ttl = 0;
    bit<3> tunnel_exp_mode = 0;
    switch_mpls_encap0_opcode_t opcode = 0;

    action push_tunnel_label_1(bit<20> label, bit<3> exp, bit<8> ttl) {
        hdr.mpls_eg[9 -1].setValid();
        hdr.mpls_eg[9 -1].label = label;
        hdr.mpls_eg[9 -1].exp = exp;
        hdr.mpls_eg[9 -1].bos = 0;
        hdr.mpls_eg[9 -1].ttl = ttl;
    }

    action push_tunnel_one_label(bit<20> label0, bit<3> exp0, bit<8> ttl0, bit<3> exp_mode, switch_mpls_encap0_opcode_t op_code, bit<14> l3_encap_id) {
        push_tunnel_label_1(label0, exp0, ttl0);
        tunnel_ttl = ttl0;
        tunnel_exp_mode = exp_mode;
        opcode = op_code;
        eg_md.route.mpls_l3_encap_id = l3_encap_id;
    }

    // action swap(bit<20> label, bit<3> exp, bit<8> ttl, bit<3> exp_mode) {
    //     hdr.mpls_vc_eg.label = label;
    //     hdr.mpls_vc_eg.exp = exp;
    //     hdr.mpls_vc_eg.ttl = ttl;
    //     tunnel_exp_mode = exp_mode;
    //     tunnel_ttl = ttl;
    //     opcode = 1;
    //     eg_md.tunnel.encap_type = SWITCH_TUNNEL_ENCAP_TYPE_MPLS;
    // }

    // action swap_to_self(bit<3> exp, bit<8> ttl, bit<3> exp_mode) {
    //     hdr.mpls_vc_eg.exp = exp;
    //     hdr.mpls_vc_eg.ttl = ttl;
    //     tunnel_exp_mode = exp_mode;
    //     tunnel_ttl = ttl;
    //     opcode = 1;
    //     eg_md.tunnel.encap_type = SWITCH_TUNNEL_ENCAP_TYPE_MPLS;
    // }
    @use_hash_action(1)
    @stage(4)
    //@placement_priority(127)
    table mpls_tunnel0_rewrite {
         key = {
            eg_md.common.l3_encap : exact;
        }
        actions = {
            push_tunnel_one_label;
            // swap;
            // swap_to_self;
            // NoAction;
        }
        const default_action = push_tunnel_one_label(0,0,0,0,0,0);
        size = tunnel0_table_size;
    }

    action rewrite_push_one_label(){
        eg_md.common.pkt_length = eg_md.common.pkt_length + 16w4;
        eg_md.tunnel.next_hdr_type = SWITCH_TUNNEL_NEXT_HDR_TYPE_MPLS;
        eg_md.tunnel.encap_type = SWITCH_TUNNEL_ENCAP_TYPE_MPLS;
    }

    action rewrite_push_one_label_bos(){
        hdr.mpls_eg[9 -1].bos = 1;
        rewrite_push_one_label();
    }

    action rewrite_swap_label_common() {
        hdr.mpls_vc_eg.exp = hdr.mpls_eg[9 -1].exp;
        hdr.mpls_vc_eg.ttl = hdr.mpls_eg[9 -1].ttl;
        hdr.mpls_eg[9 -1].setInvalid();
        eg_md.tunnel.encap_type = SWITCH_TUNNEL_ENCAP_TYPE_MPLS;
    }

    action rewrite_swap_one_label() {
        hdr.mpls_vc_eg.label = hdr.mpls_eg[9 -1].label;
        rewrite_swap_label_common();
    }

    action rewrite_swap_self_label() {
        rewrite_swap_label_common();
    }

    action delete_push_one_label() {
        hdr.mpls_eg[9 -1].setInvalid();
    }

    @ignore_table_dependency("Eg_downlink.mpls_vc_encap.mpls_vc_exp_rewrite")
    table mpls_tunnel0_label_rewrite {
        key = {
            opcode : exact;
            hdr.mpls_vc_eg.isValid() : exact;
        }

        actions = {
            rewrite_push_one_label;
            rewrite_push_one_label_bos;
            rewrite_swap_one_label;
            rewrite_swap_self_label;
            delete_push_one_label;
        }

        const entries = {
            (SWITCH_MPLS_ENCAP0_OPCODE_PUSH, true) : rewrite_push_one_label();
            (SWITCH_MPLS_ENCAP0_OPCODE_SWAP, true) : rewrite_swap_one_label();
            (SWITCH_MPLS_ENCAP0_OPCODE_SWAP_SELF, true) : rewrite_swap_self_label();
            (SWITCH_MPLS_ENCAP0_OPCODE_PUSH, false) : rewrite_push_one_label_bos();
            (SWITCH_MPLS_ENCAP0_OPCODE_SWAP, false) : rewrite_swap_one_label();
            (SWITCH_MPLS_ENCAP0_OPCODE_SWAP_SELF, false) : rewrite_swap_self_label();
        }

        const default_action = delete_push_one_label;
        size = 16;
    }

    action rewrite_mpls_one_ttl() {
        hdr.mpls_eg[9 -1].ttl = hdr.mpls_vc_eg.ttl;
        eg_md.tunnel.ttl = hdr.mpls_vc_eg.ttl;
    }

    action rewrite_mpls_one_no_vc_ttl() {
        hdr.mpls_eg[9 -1].ttl = eg_md.tunnel.ttl;
    }

    action rewrite_swap_mpls_ttl() {
        hdr.mpls_vc_eg.ttl = eg_md.tunnel.ttl;
    }

    @ignore_table_dependency("Eg_downlink.tunnel_rewrite.ip_ttl_rewrite")
    table mpls_tunnel0_ttl_rewrite {
        key = {
            tunnel_ttl : exact;
            opcode : exact;
            hdr.mpls_vc_eg.isValid() : exact;
        }

        actions = {
            rewrite_mpls_one_ttl; /* hdr.mpls_vc_eg.isValid() = true, tunnel_ttl = 0 */
            rewrite_mpls_one_no_vc_ttl;
            rewrite_swap_mpls_ttl;
            NoAction;
        }

        // const entries = {
        //     (0, SWITCH_MPLS_ENCAP0_OPCODE_PUSH, true)      : rewrite_mpls_one_ttl();
        //     (0, SWITCH_MPLS_ENCAP0_OPCODE_SWAP, true)      : rewrite_swap_mpls_ttl();
        //     (0, SWITCH_MPLS_ENCAP0_OPCODE_SWAP_SELF, true) : rewrite_swap_mpls_ttl();
        //     (0, SWITCH_MPLS_ENCAP0_OPCODE_PUSH, false)      : rewrite_mpls_one_no_vc_ttl();
        // }

        const default_action = NoAction;
        size = 32;
    }

    action rewrite_mpls_one_exp() {
        hdr.mpls_eg[9 -1].exp = eg_md.tunnel.exp;
    }

    action rewrite_swap_one_exp() {
        hdr.mpls_vc_eg.exp = eg_md.tunnel.exp;
    }

    action keep_mpls_swap_exp() {
        hdr.mpls_vc_eg.exp = eg_md.tunnel.vc_exp;
    }

    table mpls_tunnel0_exp_rewrite {
        key = {
            tunnel_exp_mode : exact;
            opcode : exact;
            eg_md.tunnel.qosphb : exact; //0/1
        }
        actions = {
            rewrite_mpls_one_exp;//push exp
            rewrite_swap_one_exp;
            keep_mpls_swap_exp;
            NoAction;
        }

        const entries = {
            (SWITCH_EXP_MODE_MAP, SWITCH_MPLS_ENCAP0_OPCODE_PUSH, 0) : rewrite_mpls_one_exp();
            (SWITCH_EXP_MODE_MAP, SWITCH_MPLS_ENCAP0_OPCODE_PUSH, 1) : rewrite_mpls_one_exp();

            (SWITCH_EXP_MODE_MAP, SWITCH_MPLS_ENCAP0_OPCODE_SWAP, 0) : keep_mpls_swap_exp();
            (SWITCH_EXP_MODE_MAP, SWITCH_MPLS_ENCAP0_OPCODE_SWAP, 1) : rewrite_swap_one_exp();

            (SWITCH_EXP_MODE_MAP, SWITCH_MPLS_ENCAP0_OPCODE_SWAP_SELF, 0) : keep_mpls_swap_exp();
            (SWITCH_EXP_MODE_MAP, SWITCH_MPLS_ENCAP0_OPCODE_SWAP_SELF, 1) : rewrite_swap_one_exp();

            (SWITCH_EXP_MODE_SWAP_KEEP, SWITCH_MPLS_ENCAP0_OPCODE_SWAP, 0) : keep_mpls_swap_exp();
            (SWITCH_EXP_MODE_SWAP_KEEP, SWITCH_MPLS_ENCAP0_OPCODE_SWAP, 1) : keep_mpls_swap_exp();

            (SWITCH_EXP_MODE_SWAP_KEEP, SWITCH_MPLS_ENCAP0_OPCODE_SWAP_SELF, 0) : keep_mpls_swap_exp();
            (SWITCH_EXP_MODE_SWAP_KEEP, SWITCH_MPLS_ENCAP0_OPCODE_SWAP_SELF, 1) : keep_mpls_swap_exp();
        }

        const default_action = NoAction;
        size = 32;
    }

   apply {
        mpls_tunnel0_rewrite.apply();
        mpls_tunnel0_label_rewrite.apply();
        mpls_tunnel0_ttl_rewrite.apply();
        mpls_tunnel0_exp_rewrite.apply();
    }
}

control MPLS_tunnel_1_encap(
        inout switch_header_t hdr,
        inout switch_egress_metadata_t eg_md,
        inout switch_egress_tunnel_metadata_t tunnel)(
        switch_uint32_t tunnel1_table_size) {

    bit<8> tunnel_ttl = 0;
    bit<3> tunnel_exp_mode = 0;
    bit<3> tunnel_label_num = 0;

    action push_tunnel_label_2(bit<20> label, bit<3> exp, bit<8> ttl) {
        hdr.mpls_eg[9 -2].setValid();
        hdr.mpls_eg[9 -2].label = label;
        hdr.mpls_eg[9 -2].exp = exp;
        hdr.mpls_eg[9 -2].bos = 0;
        hdr.mpls_eg[9 -2].ttl = ttl;
    }

    action push_tunnel_label_3(bit<20> label, bit<3> exp, bit<8> ttl) {
        hdr.mpls_eg[9 -3].setValid();
        hdr.mpls_eg[9 -3].label = label;
        hdr.mpls_eg[9 -3].exp = exp;
        hdr.mpls_eg[9 -3].bos = 0;
        hdr.mpls_eg[9 -3].ttl = ttl;
    }

    action push_tunnel_label_4(bit<20> label, bit<3> exp, bit<8> ttl) {
        hdr.mpls_eg[9 -4].setValid();
        hdr.mpls_eg[9 -4].label = label;
        hdr.mpls_eg[9 -4].exp = exp;
        hdr.mpls_eg[9 -4].bos = 0;
        hdr.mpls_eg[9 -4].ttl = ttl;
    }

    action push_tunnel_label_5(bit<20> label, bit<3> exp, bit<8> ttl) {
        hdr.mpls_eg[9 -5].setValid();
        hdr.mpls_eg[9 -5].label = label;
        hdr.mpls_eg[9 -5].exp = exp;
        hdr.mpls_eg[9 -5].bos = 0;
        hdr.mpls_eg[9 -5].ttl = ttl;
    }

    // action push_tunnel_one_label(bit<20> label0, bit<3> exp0, bit<8> ttl0, bit<3> exp_mode, bit<14> l3_encap_id) {
    //     push_tunnel_label_2(label0, exp0, ttl0);
    //     tunnel_ttl = ttl0;
    //     tunnel_exp_mode = exp_mode;
    //     tunnel_label_num = 1;
    //     eg_md.route.mpls_l3_encap_id = l3_encap_id;  
 //     eg_md.common.pkt_length = eg_md.common.pkt_length + 16w4;
    // }

    // action push_tunnel_two_labels(bit<20> label0, bit<3> exp0, bit<8> ttl0,
    //                               bit<3> exp_mode, bit<20> label1, bit<16> l3_encap_id) {
    //     push_tunnel_label_2(label0, exp0, ttl0);
    //     push_tunnel_label_3(label1, exp0, ttl0);
    //     tunnel_ttl = ttl0;
    //     tunnel_exp_mode = exp_mode;
    //     tunnel_label_num = 2;
    //     eg_md.route.mpls_l3_encap_id = l3_encap_id;
 //     eg_md.common.pkt_length = eg_md.common.pkt_length + 16w8;
    // }

    action push_tunnel_four_labels(bit<20> label0, bit<3> exp0, bit<8> ttl0, bit<3> exp_mode,
                                   bit<20> label1, bit<20> label2, bit<20> label3, bit<3> label_num) {
        push_tunnel_label_2(label0, exp0, ttl0);
        push_tunnel_label_3(label1, exp0, ttl0);
        push_tunnel_label_4(label2, exp0, ttl0);
        push_tunnel_label_5(label3, exp0, ttl0);
        tunnel_ttl = ttl0;
        tunnel_exp_mode = exp_mode;
        tunnel_label_num = label_num;
        // eg_md.route.mpls_l3_encap_id = l3_encap_id;
     // eg_md.common.pkt_length = eg_md.common.pkt_length + 16w12;
    }

    // action push_tunnel_four_labels(bit<20> label0, bit<3> exp0, bit<8> ttl0,  bit<3> exp_mode,
    //                                bit<20> label1, bit<20> label2, bit<20> label3) {
    //     push_tunnel_label_2(label0, exp0, ttl0);
    //     push_tunnel_label_3(label1, exp0, ttl0);
    //     push_tunnel_label_4(label2, exp0, ttl0);
    //     push_tunnel_label_5(label3, exp0, ttl0);
    //     tunnel_ttl = ttl0;
    //     tunnel_exp_mode = exp_mode;
    //     tunnel_label_num = 4;
    // }

    @use_hash_action(1)
    //@placement_priority(127)
    @stage(6)
    table mpls_tunnel1_rewrite {
         key = {
            eg_md.route.mpls_l3_encap_id : exact;
        }
        actions = {
            // push_tunnel_one_label;
            // push_tunnel_two_labels;
            // push_tunnel_three_labels;
            push_tunnel_four_labels;
            // NoAction;
        }
        const default_action = push_tunnel_four_labels(0,0,0,0,0,0,0,0);
        size = tunnel1_table_size;
    }

    action rewrite_mpls_zero_label() {
        hdr.mpls_eg[9 -2].setInvalid();
        hdr.mpls_eg[9 -3].setInvalid();
        hdr.mpls_eg[9 -4].setInvalid();
        hdr.mpls_eg[9 -5].setInvalid();
    }

    action rewrite_mpls_one_label() {
        hdr.mpls_eg[9 -3].setInvalid();
        hdr.mpls_eg[9 -4].setInvalid();
        hdr.mpls_eg[9 -5].setInvalid();
        eg_md.common.pkt_length = eg_md.common.pkt_length + 16w4;
    }

    action rewrite_mpls_two_label() {
        hdr.mpls_eg[9 -4].setInvalid();
        hdr.mpls_eg[9 -5].setInvalid();
        eg_md.common.pkt_length = eg_md.common.pkt_length + 16w8;
    }

    action rewrite_mpls_three_label() {
        hdr.mpls_eg[9 -5].setInvalid();
        eg_md.common.pkt_length = eg_md.common.pkt_length + 16w12;
    }

    action rewrite_mpls_four_label() {
        eg_md.common.pkt_length = eg_md.common.pkt_length + 16w16;
    }

    table mpls_tunnel1_labels_rewrite {
        key = {
            tunnel_label_num : exact;
        }

        actions = {
            rewrite_mpls_zero_label;
            rewrite_mpls_one_label;
            rewrite_mpls_two_label;
            rewrite_mpls_three_label;
            rewrite_mpls_four_label;
        }

        const entries = {
            (1) : rewrite_mpls_one_label();
            (2) : rewrite_mpls_two_label();
            (3) : rewrite_mpls_three_label();
            (4) : rewrite_mpls_four_label();
        }

        const default_action = rewrite_mpls_zero_label;
        size = 32;
    }

    action rewrite_mpls_one_ttl() {
        hdr.mpls_eg[9 -2].ttl = eg_md.tunnel.ttl;
    }

    action rewrite_mpls_two_ttl() {
        hdr.mpls_eg[9 -2].ttl = eg_md.tunnel.ttl;
        hdr.mpls_eg[9 -3].ttl = eg_md.tunnel.ttl;
    }

    action rewrite_mpls_three_ttl() {
        hdr.mpls_eg[9 -2].ttl = eg_md.tunnel.ttl;
        hdr.mpls_eg[9 -3].ttl = eg_md.tunnel.ttl;
        hdr.mpls_eg[9 -4].ttl = eg_md.tunnel.ttl;
    }

    action rewrite_mpls_four_ttl() {
        hdr.mpls_eg[9 -2].ttl = eg_md.tunnel.ttl;
        hdr.mpls_eg[9 -3].ttl = eg_md.tunnel.ttl;
        hdr.mpls_eg[9 -4].ttl = eg_md.tunnel.ttl;
        hdr.mpls_eg[9 -5].ttl = eg_md.tunnel.ttl;
    }

    table mpls_tunnel1_ttl_rewrite {
        key = {
            tunnel_ttl : exact;
            tunnel_label_num : exact;
        }

        actions = {
            rewrite_mpls_one_ttl;
            rewrite_mpls_two_ttl;
            rewrite_mpls_three_ttl;
            rewrite_mpls_four_ttl;
            NoAction;
        }

        // const entries = {
        //     (0, 1) : rewrite_mpls_one_ttl();
        //     (0, 2) : rewrite_mpls_two_ttl();
        //     (0, 3) : rewrite_mpls_three_ttl();
        //     (0, 4) : rewrite_mpls_four_ttl();
        // }

        const default_action = NoAction;
        size = 32;
    }

    action rewrite_mpls_one_exp() {
        hdr.mpls_eg[9 -2].exp = eg_md.tunnel.exp;
    }

    action rewrite_mpls_two_exp() {
        hdr.mpls_eg[9 -2].exp = eg_md.tunnel.exp;
        hdr.mpls_eg[9 -3].exp = eg_md.tunnel.exp;
    }

    action rewrite_mpls_three_exp() {
        hdr.mpls_eg[9 -2].exp = eg_md.tunnel.exp;
        hdr.mpls_eg[9 -3].exp = eg_md.tunnel.exp;
        hdr.mpls_eg[9 -4].exp = eg_md.tunnel.exp;
    }

    action rewrite_mpls_four_exp() {
        hdr.mpls_eg[9 -2].exp = eg_md.tunnel.exp;
        hdr.mpls_eg[9 -3].exp = eg_md.tunnel.exp;
        hdr.mpls_eg[9 -4].exp = eg_md.tunnel.exp;
        hdr.mpls_eg[9 -5].exp = eg_md.tunnel.exp;
    }

    table mpls_tunnel1_exp_rewrite {
        key = {
            tunnel_exp_mode : exact;
            tunnel_label_num : exact;
        }
        actions = {
            rewrite_mpls_one_exp;
            rewrite_mpls_two_exp;
            rewrite_mpls_three_exp;
            rewrite_mpls_four_exp;
            NoAction;
        }

        // const entries = {
        //     (0, 1) : rewrite_mpls_one_exp();
        //     (0, 2) : rewrite_mpls_two_exp();
        //     (0, 3) : rewrite_mpls_three_exp();
        //     (0, 4) : rewrite_mpls_four_exp();
        // }

        const default_action = NoAction;
        size = 32;
    }

    apply {
        if (eg_md.tunnel.l3_encap_mapping_hit == 0 && eg_md.tunnel.encap_type == SWITCH_TUNNEL_ENCAP_TYPE_MPLS) {
            mpls_tunnel1_rewrite.apply();
        }
        if (eg_md.tunnel.l3_encap_mapping_hit == 0 && eg_md.tunnel.encap_type == SWITCH_TUNNEL_ENCAP_TYPE_MPLS) {
            mpls_tunnel1_labels_rewrite.apply();
            mpls_tunnel1_ttl_rewrite.apply();
            mpls_tunnel1_exp_rewrite.apply();
        }
    }
}

control MPLS_tunnel_2_encap(
        inout switch_header_t hdr,
        inout switch_egress_metadata_t eg_md,
        inout switch_egress_tunnel_metadata_t tunnel)(
        switch_uint32_t tunnel2_table_size) {

   bit<8> tunnel_ttl = 0;
   bit<3> tunnel_exp_mode = 0;
   bit<3> tunnel_label_num = 0;

    action push_tunnel_label_6(bit<20> label, bit<3> exp, bit<8> ttl) {
        hdr.mpls_eg[9 -6].setValid();
        hdr.mpls_eg[9 -6].label = label;
        hdr.mpls_eg[9 -6].exp = exp;
        hdr.mpls_eg[9 -6].bos = 0;
        hdr.mpls_eg[9 -6].ttl = ttl;
    }

    action push_tunnel_label_7(bit<20> label, bit<3> exp, bit<8> ttl) {
        hdr.mpls_eg[9 -7].setValid();
        hdr.mpls_eg[9 -7].label = label;
        hdr.mpls_eg[9 -7].exp = exp;
        hdr.mpls_eg[9 -7].bos = 0;
        hdr.mpls_eg[9 -7].ttl = ttl;
    }

    action push_tunnel_label_8(bit<20> label, bit<3> exp, bit<8> ttl) {
        hdr.mpls_eg[9 -8].setValid();
        hdr.mpls_eg[9 -8].label = label;
        hdr.mpls_eg[9 -8].exp = exp;
        hdr.mpls_eg[9 -8].bos = 0;
        hdr.mpls_eg[9 -8].ttl = ttl;
    }

    action push_tunnel_label_9(bit<20> label, bit<3> exp, bit<8> ttl) {
        hdr.mpls_eg[9 -9].setValid();
        hdr.mpls_eg[9 -9].label = label;
        hdr.mpls_eg[9 -9].exp = exp;
        hdr.mpls_eg[9 -9].bos = 0;
        hdr.mpls_eg[9 -9].ttl = ttl;
    }

    // action push_tunnel_label_10(bit<20> label, bit<3> exp, bit<8> ttl) {
    //     hdr.mpls_eg[EG_MPLS_DEPTH-10].setValid();
    //     hdr.mpls_eg[EG_MPLS_DEPTH-10].label = label;
    //     hdr.mpls_eg[EG_MPLS_DEPTH-10].exp = exp;
    //     hdr.mpls_eg[EG_MPLS_DEPTH-10].bos = 0;
    //     hdr.mpls_eg[EG_MPLS_DEPTH-10].ttl = ttl;
    // }

    // action push_tunnel_one_label(bit<20> label0, bit<3> exp0, bit<8> ttl0, bit<3> exp_mode) {
    //     push_tunnel_label_5(label0, exp0, ttl0);
    //     tunnel_ttl = ttl0;
    //     tunnel_exp_mode = exp_mode;
    //     tunnel_label_num = 1;
    //     eg_md.common.pkt_length = eg_md.common.pkt_length + 16w4;
    // }

    // action push_tunnel_two_labels(bit<20> label0, bit<3> exp0, bit<8> ttl0, bit<3> exp_mode,
    //                               bit<20> label1) {
    //     push_tunnel_label_5(label0, exp0, ttl0);
    //     push_tunnel_label_6(label1, exp0, ttl0);
    //     tunnel_ttl = ttl0;
    //     tunnel_exp_mode = exp_mode;
    //     tunnel_label_num = 2;
    //     eg_md.common.pkt_length = eg_md.common.pkt_length + 16w8;
    // }

    // action push_tunnel_three_labels(bit<20> label0, bit<3> exp0, bit<8> ttl0, bit<3> exp_mode,
    //                                 bit<20> label1, bit<20> label2) {
    //     push_tunnel_label_5(label0, exp0, ttl0);
    //     push_tunnel_label_6(label1, exp0, ttl0);
    //     push_tunnel_label_7(label2, exp0, ttl0);
    //     tunnel_ttl = ttl0;
    //     tunnel_exp_mode = exp_mode;
    //     tunnel_label_num = 3;
    //     eg_md.common.pkt_length = eg_md.common.pkt_length + 16w12;
    // }

    // action push_tunnel_four_labels(bit<20> label0, bit<3> exp0, bit<8> ttl0, bit<3> exp_mode,
    //                                bit<20> label1, bit<20> label2, bit<20> label3) {
    //     push_tunnel_label_5(label0, exp0, ttl0);
    //     push_tunnel_label_6(label1, exp0, ttl0);
    //     push_tunnel_label_7(label2, exp0, ttl0);
    //     push_tunnel_label_8(label3, exp0, ttl0);
    //     tunnel_ttl = ttl0;
    //     tunnel_exp_mode = exp_mode;
    //     tunnel_label_num = 4;
    //     eg_md.common.pkt_length = eg_md.common.pkt_length + 16w16;
    // }

    // action push_tunnel_five_labels(bit<20> label0, bit<3> exp0, bit<8> ttl0, bit<3> exp_mode,
    //                                bit<20> label1, bit<20> label2, bit<20> label3,
    //                                bit<20> label4) {
    //     push_tunnel_label_5(label0, exp0, ttl0);
    //     push_tunnel_label_6(label1, exp0, ttl0);
    //     push_tunnel_label_7(label2, exp0, ttl0);
    //     push_tunnel_label_8(label3, exp0, ttl0);
    //     push_tunnel_label_9(label4, exp0, ttl0);
    //     tunnel_ttl = ttl0;
    //     tunnel_exp_mode = exp_mode;
    //     tunnel_label_num = 5;
    //     eg_md.common.pkt_length = eg_md.common.pkt_length + 16w20;
    // }

    action push_tunnel_four_labels(bit<20> label0, bit<3> exp0, bit<8> ttl0, bit<3> exp_mode,
                                  bit<20> label1, bit<20> label2, bit<20> label3, bit<3> label_num) {
        push_tunnel_label_6(label0, exp0, ttl0);
        push_tunnel_label_7(label1, exp0, ttl0);
        push_tunnel_label_8(label2, exp0, ttl0);
        push_tunnel_label_9(label3, exp0, ttl0);
        // push_tunnel_label_10(label5, exp0, ttl0);
        tunnel_ttl = ttl0;
        tunnel_exp_mode = exp_mode;
        tunnel_label_num = label_num;
    }

    @use_hash_action(1)
    @ignore_table_dependency("Eg_downlink.tunnel_rewrite.ip_dscp_rewrite")
    @placement_priority(127)
    table mpls_tunnel2_rewrite {
        key = {
            eg_md.route.mpls_l3_encap_id : exact;
        }
        actions = {
            // push_tunnel_one_label;
            // push_tunnel_two_labels;
            // push_tunnel_three_labels;
            push_tunnel_four_labels;
            // push_tunnel_five_labels;
            // NoAction;
        }
        const default_action = push_tunnel_four_labels(0,0,0,0,0,0,0,0);
        size = tunnel2_table_size;
    }

    action rewrite_mpls_zero_label() {
        hdr.mpls_eg[9 -6].setInvalid();
        hdr.mpls_eg[9 -7].setInvalid();
        hdr.mpls_eg[9 -8].setInvalid();
        hdr.mpls_eg[9 -9].setInvalid();
    }

    action rewrite_mpls_one_label() {
        hdr.mpls_eg[9 -7].setInvalid();
        hdr.mpls_eg[9 -8].setInvalid();
        hdr.mpls_eg[9 -9].setInvalid();
        eg_md.common.pkt_length = eg_md.common.pkt_length + 16w4;
    }

    action rewrite_mpls_two_label() {
        hdr.mpls_eg[9 -8].setInvalid();
        hdr.mpls_eg[9 -9].setInvalid();
        eg_md.common.pkt_length = eg_md.common.pkt_length + 16w8;
    }

    action rewrite_mpls_three_label() {
        hdr.mpls_eg[9 -9].setInvalid();
        eg_md.common.pkt_length = eg_md.common.pkt_length + 16w12;
    }

    action rewrite_mpls_four_label() {
        eg_md.common.pkt_length = eg_md.common.pkt_length + 16w16;
    }

    // action rewrite_mpls_five_label() {
    //     eg_md.common.pkt_length = eg_md.common.pkt_length + 16w20;
    // }

    table mpls_tunnel2_labels_rewrite {
        key = {
            tunnel_label_num : exact;
        }

        actions = {
            rewrite_mpls_zero_label;
            rewrite_mpls_one_label;
            rewrite_mpls_two_label;
            rewrite_mpls_three_label;
            rewrite_mpls_four_label;
            // rewrite_mpls_five_label;
        }

        // const entries = {
        //     (1) : rewrite_mpls_one_label();
        //     (2) : rewrite_mpls_two_label();
        //     (3) : rewrite_mpls_three_label();
        //     (4) : rewrite_mpls_four_label();
        //     // (5) : rewrite_mpls_five_label();
        // }

        const default_action = rewrite_mpls_zero_label;
        size = 32;
    }

    action rewrite_mpls_one_ttl() {
        hdr.mpls_eg[9 -6].ttl = eg_md.tunnel.ttl;
    }

    action rewrite_mpls_two_ttl() {
        hdr.mpls_eg[9 -6].ttl = eg_md.tunnel.ttl;
        hdr.mpls_eg[9 -7].ttl = eg_md.tunnel.ttl;
    }

    action rewrite_mpls_three_ttl() {
        hdr.mpls_eg[9 -6].ttl = eg_md.tunnel.ttl;
        hdr.mpls_eg[9 -7].ttl = eg_md.tunnel.ttl;
        hdr.mpls_eg[9 -8].ttl = eg_md.tunnel.ttl;
    }

    action rewrite_mpls_four_ttl() {
        hdr.mpls_eg[9 -6].ttl = eg_md.tunnel.ttl;
        hdr.mpls_eg[9 -7].ttl = eg_md.tunnel.ttl;
        hdr.mpls_eg[9 -8].ttl = eg_md.tunnel.ttl;
        hdr.mpls_eg[9 -9].ttl = eg_md.tunnel.ttl;
    }

    // action rewrite_mpls_five_ttl() {
    //     hdr.mpls_eg[EG_MPLS_DEPTH-5].ttl = eg_md.tunnel.ttl;
    //     hdr.mpls_eg[EG_MPLS_DEPTH-6].ttl = eg_md.tunnel.ttl;
    //     hdr.mpls_eg[EG_MPLS_DEPTH-7].ttl = eg_md.tunnel.ttl;
    //     hdr.mpls_eg[EG_MPLS_DEPTH-8].ttl = eg_md.tunnel.ttl;
    //     hdr.mpls_eg[EG_MPLS_DEPTH-9].ttl = eg_md.tunnel.ttl;
    // }

    table mpls_tunnel2_ttl_rewrite {
        key = {
            tunnel_ttl : exact;
            tunnel_label_num : exact;
        }

        actions = {
            rewrite_mpls_one_ttl;
            rewrite_mpls_two_ttl;
            rewrite_mpls_three_ttl;
            rewrite_mpls_four_ttl;
            // rewrite_mpls_five_ttl;
            NoAction;
        }

        // const entries = {
        //     (0, 1) : rewrite_mpls_one_ttl();
        //     (0, 2) : rewrite_mpls_two_ttl();
        //     (0, 3) : rewrite_mpls_three_ttl();
        //     (0, 4) : rewrite_mpls_four_ttl();
        //     // (0, 5) : rewrite_mpls_five_ttl();
        // }

        const default_action = NoAction;
        size = 32;
    }

    action rewrite_mpls_one_exp() {
        hdr.mpls_eg[9 -6].exp = eg_md.tunnel.exp;
    }

    action rewrite_mpls_two_exp() {
        hdr.mpls_eg[9 -6].exp = eg_md.tunnel.exp;
        hdr.mpls_eg[9 -7].exp = eg_md.tunnel.exp;
    }

    action rewrite_mpls_three_exp() {
        hdr.mpls_eg[9 -6].exp = eg_md.tunnel.exp;
        hdr.mpls_eg[9 -7].exp = eg_md.tunnel.exp;
        hdr.mpls_eg[9 -8].exp = eg_md.tunnel.exp;
    }

    action rewrite_mpls_four_exp() {
        hdr.mpls_eg[9 -6].exp = eg_md.tunnel.exp;
        hdr.mpls_eg[9 -7].exp = eg_md.tunnel.exp;
        hdr.mpls_eg[9 -8].exp = eg_md.tunnel.exp;
        hdr.mpls_eg[9 -9].exp = eg_md.tunnel.exp;
    }

    // action rewrite_mpls_five_exp() {
    //     hdr.mpls_eg[EG_MPLS_DEPTH-5].exp = eg_md.tunnel.exp;
    //     hdr.mpls_eg[EG_MPLS_DEPTH-6].exp = eg_md.tunnel.exp;
    //     hdr.mpls_eg[EG_MPLS_DEPTH-7].exp = eg_md.tunnel.exp;
    //     hdr.mpls_eg[EG_MPLS_DEPTH-8].exp = eg_md.tunnel.exp;
    //     hdr.mpls_eg[EG_MPLS_DEPTH-9].exp = eg_md.tunnel.exp;
    // }

    table mpls_tunnel2_exp_rewrite {
        key = {
            tunnel_exp_mode : exact;
            tunnel_label_num : exact;
        }

        actions = {
            rewrite_mpls_one_exp;
            rewrite_mpls_two_exp;
            rewrite_mpls_three_exp;
            rewrite_mpls_four_exp;
            // rewrite_mpls_five_exp;
            NoAction;
        }

        const entries = {
            (0, 1) : rewrite_mpls_one_exp();
            (0, 2) : rewrite_mpls_two_exp();
            (0, 3) : rewrite_mpls_three_exp();
            (0, 4) : rewrite_mpls_four_exp();
            // (0, 5) : rewrite_mpls_five_exp();
        }

        const default_action = NoAction;
        size = 64;
    }

    apply {
        if (eg_md.tunnel.encap_type == SWITCH_TUNNEL_ENCAP_TYPE_MPLS) {
            mpls_tunnel2_rewrite.apply();
        }
        if (eg_md.tunnel.encap_type == SWITCH_TUNNEL_ENCAP_TYPE_MPLS) {
            mpls_tunnel2_labels_rewrite.apply();
            mpls_tunnel2_ttl_rewrite.apply();
            mpls_tunnel2_exp_rewrite.apply();
        }
    }
}

control MPLS_encap0(
        inout switch_header_t hdr,
        inout switch_egress_metadata_t eg_md,
        inout switch_egress_tunnel_metadata_t tunnel)(
        switch_uint32_t tunnel0_table_size) {

    MPLS_tunnel_0_encap(tunnel0_table_size) mpls_tunnel0_rewrite;

    apply {

        mpls_tunnel0_rewrite.apply(hdr, eg_md, tunnel);

    }
}

control MPLS_encap1(
        inout switch_header_t hdr,
        inout switch_egress_metadata_t eg_md,
        inout switch_egress_tunnel_metadata_t tunnel)(
        switch_uint32_t tunnel1_table_size) {

    MPLS_tunnel_1_encap(tunnel1_table_size) mpls_tunnel1_rewrite;

    apply {

        mpls_tunnel1_rewrite.apply(hdr, eg_md, tunnel);

    }
}

control MPLS_encap2(
        inout switch_header_t hdr,
        inout switch_egress_metadata_t eg_md,
        inout switch_egress_tunnel_metadata_t tunnel)(
        switch_uint32_t tunnel2_table_size) {

    MPLS_tunnel_2_encap(tunnel2_table_size) mpls_tunnel2_rewrite;

    apply {

        mpls_tunnel2_rewrite.apply(hdr, eg_md, tunnel);

    }
}
# 213 "/mnt/p4c-4127/p4src/switch-tofino2/switch_tofino_x1.p4" 2
# 1 "/mnt/p4c-4127/p4src/shared/srv6.p4" 1
/**
 * SRv6
 *
 */



control SRv6_VALIDATION(
            in switch_header_t hdr,
            inout switch_ingress_metadata_t ig_md,
            out switch_drop_reason_t drop_reason)(
            switch_uint32_t validation_table_size = 4) {
    bool sl_is_normal;
    bool le_is_normal;

    bit<8> tmp_sl;
    bit<8> tmp_le;

    bit<8> max_LE;

    action malformed_srv6_pkt(bit<8> reason) {
        drop_reason = reason;
    }

    action valid_srv6_pkt() {

    }
    table validate_srv6_srh {
        key = {
            sl_is_normal : exact;
            le_is_normal : exact;
        }
        actions = {
            valid_srv6_pkt;
            malformed_srv6_pkt;
        }
        const default_action = valid_srv6_pkt;
        size = validation_table_size;
    }

    action max_le() {
        max_LE = hdr.srv6_srh.hdr_ext_len >> 1;
    }
    table max_le_cal {
        actions = {
            max_le;
        }
        size = 1;
        default_action = max_le();
    }

    action set_seg_left_zero() {
        ig_md.srv6.sl_is_zero = true;
    }
    action set_seg_left_one() {
        ig_md.srv6.sl_is_one = true;
    }
    table segment_left {
        key = {
            hdr.srv6_srh.seg_left : exact;
        }
        actions = {
            NoAction;
            set_seg_left_zero;
            set_seg_left_one;
        }
        const default_action = NoAction;
        const entries = {
            0 : set_seg_left_zero;
            1 : set_seg_left_one;
        }
    }

    apply {
/*
        sl_is_normal = false;
        le_is_normal = false;

        tmp_sl =  ig_md.srv6.seg_left |-| hdr.srv6_srh.last_entry; //error
        if (tmp_sl == 0 || tmp_sl == 1)
            sl_is_normal = true;

        max_le_cal.apply();
        max_LE = max_LE - 1;
        tmp_le = ig_md.srv6.last_entry |-| max_LE;
        if (tmp_le == 0)
            le_is_normal = true;
*/
        // sl_is_normal = true;
        // le_is_normal = true;
        // switch(validate_srv6_srh.apply().action_run) {
        //     valid_srv6_pkt : {
        //     }
        // }
        segment_left.apply();
    }
}

// SRv6 SID lookup
//
// @param hdr: Parsed headers.
// @param ig_md.srv6.sid: SID pointed by the SL field in the first SRH.
// @param ig_md: Ingress metadata.
control SRv6(inout switch_header_t hdr,
            inout switch_ingress_metadata_t ig_md)(
            switch_uint32_t local_sid_size = 10 * 1024
            ) {


    Hash<bit<32>>(HashAlgorithm_t.IDENTITY) hash_gsid1;


    action drop(bit<8> reason) {
        ig_md.common.drop_reason = reason;
    }

    action srh_terminate() {
        ig_md.srv6.srh_terminate = true;
        ig_md.srv6.payload_flag = 1;
    }

    /* for end/end.x/end.t/end.b6.encaps */
    action segment_left_minus() {
        hdr.srv6_srh.seg_left = hdr.srv6_srh.seg_left - 1;
    }
    action update_segment_left() {
        segment_left_minus();
        hdr.ipv6.dst_addr = ig_md.srv6.sid;
        ig_md.tunnel.srv6_end_type = SWITCH_SRV6_END_TYPE_NONE;
    }

    action psp() {
        update_segment_left();
        srh_terminate();
    }

    action usp() {
        srh_terminate();
        ig_md.srv6.usp = 1;
    }

    action usd() {
        ig_md.tunnel.terminate = true;
    }

    action coc() {
        ig_md.srv6.coc_flag = 1;
    }
    action coc_psp() {
        segment_left_minus();
        srh_terminate();
        coc();
    }
    action coc_with_si_is_zero() {
        segment_left_minus();
        coc();
    }

    table endpoint_behavior_check {
        key = {
            hdr.srv6_srh.isValid() : exact;
            ig_md.tunnel.srv6_end_type : exact;
            ig_md.tunnel.srv6_flavors : ternary;
            ig_md.srv6.sl_is_zero : exact;
            ig_md.srv6.sl_is_one : exact;
            hdr.srv6_srh.next_hdr : ternary;
            hdr.ipv6.next_hdr : ternary;

            ig_md.srv6.si : ternary;

        }
        actions = {
            NoAction;
            drop;
            update_segment_left;
            psp;
            usp;
            usd;

            coc;
            coc_psp;
            coc_with_si_is_zero;

        }
        const default_action = NoAction;
    }


    action sid_0() {
        ig_md.srv6.si_hash = 3;
        ig_md.srv6.c_sid = hash_gsid1.get(ig_md.srv6.sid[31 : 0]);
    }
    action sid_1() {
        ig_md.srv6.si_hash = 0;
        ig_md.srv6.c_sid = ig_md.srv6.g_sid[127 : 96];
    }
    action sid_2() {
        ig_md.srv6.si_hash = 1;
        ig_md.srv6.c_sid = ig_md.srv6.g_sid[95 : 64];
    }
    action sid_3() {
        ig_md.srv6.si_hash = 2;
        ig_md.srv6.c_sid = ig_md.srv6.g_sid[63 : 32];
    }
    /* 32bit c-sid */
    table g_sid_index {
        key = {
            ig_md.srv6.si : exact;
        }
        actions = {
            sid_0;
            sid_1;
            sid_2;
            sid_3;
        }
        size = 4;
        const entries = {
            0 : sid_0;
            1 : sid_1;
            2 : sid_2;
            3 : sid_3;
        }
    }


    apply {
        if (ig_md.tunnel.ip_addr_miss == false) {

            if (hdr.srv6_srh.isValid() && (ig_md.tunnel.srv6_flavors & SWITCH_SRV6_FLAVORS_COC) != 0) {
                g_sid_index.apply();
            }

            endpoint_behavior_check.apply();
        }
    }
}

control SRv6_Post(inout switch_header_t hdr,
            inout switch_ingress_metadata_t ig_md) {

    Hash<bit<32>>(HashAlgorithm_t.IDENTITY) hash_csid;
    Hash<bit<2>>(HashAlgorithm_t.IDENTITY) hash_si;

    action set_payload_le_0() {
        hdr.ipv6.payload_len = hdr.ipv6.payload_len - 24;
    }
    action set_payload_le_1() {
        hdr.ipv6.payload_len = hdr.ipv6.payload_len - 40;
    }
    action set_payload_le_2() {
        hdr.ipv6.payload_len = hdr.ipv6.payload_len - 56;
    }
    action set_payload_le_3() {
        hdr.ipv6.payload_len = hdr.ipv6.payload_len - 72;
    }
    action set_payload_le_4() {
        hdr.ipv6.payload_len = hdr.ipv6.payload_len - 88;
    }
    action set_payload_le_5() {
        hdr.ipv6.payload_len = hdr.ipv6.payload_len - 104;
    }
    action set_payload_le_6() {
        hdr.ipv6.payload_len = hdr.ipv6.payload_len - 120;
    }
    action set_payload_le_7() {
        hdr.ipv6.payload_len = hdr.ipv6.payload_len - 136;
    }
    action set_payload_le_8() {
        hdr.ipv6.payload_len = hdr.ipv6.payload_len - 152;
    }
    action set_payload_le_9() {
        hdr.ipv6.payload_len = hdr.ipv6.payload_len - 168;
    }
    /* payload = payload - (last entry + 1) * 16 - 8 */
    table ipv6_payload {
        key = {
            hdr.srv6_srh.last_entry : exact;
        }
        actions = {
            set_payload_le_0;
            set_payload_le_1;
            set_payload_le_2;
            set_payload_le_3;
            set_payload_le_4;
            set_payload_le_5;
            set_payload_le_6;
            set_payload_le_7;
            set_payload_le_8;
            set_payload_le_9;
        }
        size = 16;
        const entries = {
            0 : set_payload_le_0;
            1 : set_payload_le_1;
            2 : set_payload_le_2;
            3 : set_payload_le_3;
            4 : set_payload_le_4;
            5 : set_payload_le_5;
            6 : set_payload_le_6;
            7 : set_payload_le_7;
            8 : set_payload_le_8;
            9 : set_payload_le_9;
        }
    }


    action prefixlen_8() {
        hdr.ipv6.dst_addr[119 : 88] = hash_csid.get(ig_md.srv6.c_sid);
    }
    action prefixlen_16() {
        hdr.ipv6.dst_addr[111 : 80] = hash_csid.get(ig_md.srv6.c_sid);
    }
    action prefixlen_24() {
        hdr.ipv6.dst_addr[103 : 72] = hash_csid.get(ig_md.srv6.c_sid);
    }
    action prefixlen_32() {
        hdr.ipv6.dst_addr[95 : 64] = hash_csid.get(ig_md.srv6.c_sid);
    }
    action prefixlen_40() {
        hdr.ipv6.dst_addr[87 : 56] = hash_csid.get(ig_md.srv6.c_sid);
    }
    action prefixlen_48() {
        hdr.ipv6.dst_addr[79 : 48] = hash_csid.get(ig_md.srv6.c_sid);
    }
    action prefixlen_56() {
        hdr.ipv6.dst_addr[71 : 40] = hash_csid.get(ig_md.srv6.c_sid);
    }
    action prefixlen_64() {
        hdr.ipv6.dst_addr[63 : 32] = hash_csid.get(ig_md.srv6.c_sid);
    }
    action prefixlen_72() {
        hdr.ipv6.dst_addr[55 : 24] = hash_csid.get(ig_md.srv6.c_sid);
    }
    action prefixlen_80() {
        hdr.ipv6.dst_addr[47 : 16] = hash_csid.get(ig_md.srv6.c_sid);
    }
    action prefixlen_88() {
        hdr.ipv6.dst_addr[39 : 8] = hash_csid.get(ig_md.srv6.c_sid);
    }

    /* Precondition: G-SID 32BIT */
    table prefixlen {
        key = {
            ig_md.srv6.prefixlen : exact;
        }
        actions = {
            NoAction;
            prefixlen_8;
            prefixlen_16;
            prefixlen_24;
            prefixlen_32;
            prefixlen_40;
            prefixlen_48;
            prefixlen_56;
            prefixlen_64;
            prefixlen_72;
            prefixlen_80;
            prefixlen_88;
        }
        const entries = {
            8 : prefixlen_8;
            16 : prefixlen_16;
            24 : prefixlen_24;
            32 : prefixlen_32;
            40 : prefixlen_40;
            48 : prefixlen_48;
            56 : prefixlen_56;
            64 : prefixlen_64;
            72 : prefixlen_72;
            80 : prefixlen_80;
            88 : prefixlen_88;
        }
    }

    action rewrite_si() {
        hdr.ipv6.dst_addr[1 : 0] = hash_si.get(ig_md.srv6.si_hash);
    }
    table si_rewrite {
        actions = {
            rewrite_si;
        }
        const default_action = rewrite_si;
    }


    apply {

        if (ig_md.tunnel.ip_addr_miss == false && ig_md.srv6.coc_flag == 1) {
            prefixlen.apply();
            si_rewrite.apply();
        }

        if (ig_md.tunnel.ip_addr_miss == false && ig_md.srv6.payload_flag == 1) {
            ipv6_payload.apply();
        }
    }
}


control SRv6Sid(inout switch_header_t hdr,
            inout switch_ingress_metadata_t ig_md)(
            switch_uint32_t local_sid_size = 26 * 1024
            ) {
    /*
    S01. When an SRH is processed {
    S02.   If (Segments Left != 0) {
    S03.      Send an ICMP Parameter Problem to the Source Address,
                    Code 0 (Erroneous header field encountered),
                    Pointer set to the Segments Left field.
                    Interrupt packet processing and discard the packet.
    S04.   }
    S05.   Proceed to process the next header in the packet
    S06. }
    */
    action end_dx4(bit<16> nexthop, bit<1> is_ecmp, bit<2> level, bit<8> priority,
                   bit<1> copy, bit<1> set_dscp) {
        ig_md.flags.ext_srv6 = true;
        ig_md.common.extend = 1;
        add_ext_srv6(hdr, ig_md, 0, true, level, is_ecmp, priority, nexthop, set_dscp, ig_md.lkp.ip_tos);

        ig_md.tunnel.ttl_copy = copy;
        ig_md.tunnel.ttl = hdr.ipv6.hop_limit;

        ig_md.tunnel.srv6_end_type = SWITCH_SRV6_END_TYPE_END_DX;
        ig_md.tunnel.terminate = true;
    }

    action end_dx6(bit<16> nexthop, bit<1> is_ecmp, bit<2> level, bit<8> priority,
                   bit<1> copy, bit<1> set_dscp) {
        end_dx4(nexthop, is_ecmp, level, priority, copy, set_dscp);
    }

    /*
    S01. When an SRH is processed {
    S02.   If (Segments Left != 0) {
    S03.      Send an ICMP Parameter Problem to the Source Address,
                    Code 0 (Erroneous header field encountered),
                    Pointer set to the Segments Left field.
                    Interrupt packet processing and discard the packet.
    S04.   }
    S05.   Proceed to process the next header in the packet
    S06. }
    */
    action end_dt4(switch_lif_t lif, bit<1> copy, bit<1> set_dscp) {
        add_ext_tunnel_decap(hdr, ig_md);

        ig_md.flags.ext_srv6 = true;
        ig_md.common.extend = 1;
        add_ext_srv6(hdr, ig_md, 0, false, 0, 0, 0, 0, set_dscp, ig_md.lkp.ip_tos);

        ig_md.common.iif = lif;
        ig_md.common.iif_type = SWITCH_L3_IIF_TYPE;
        ig_md.tunnel.terminate = true;
        ig_md.tunnel.ttl_copy = copy;
        ig_md.tunnel.ttl = hdr.ipv6.hop_limit;

        ig_md.tunnel.srv6_end_type = SWITCH_SRV6_END_TYPE_END_DT;
    }

    action end_dt6(switch_lif_t lif, bit<1> copy, bit<1> set_dscp) {
        end_dt4(lif, copy, set_dscp);
    }

    @stage(9)
    table local_sid {
        key = {
            hdr.ipv6.dst_addr : exact;
        }
        actions = {
            NoAction;
            end_dx4;
            end_dx6;
            end_dt4;
            end_dt6;
        }
        const default_action = NoAction;
        size = local_sid_size;
    }

    table local_sid_fallback {
        key = {
            hdr.ipv6.dst_addr : ternary;
        }
        actions = {
            NoAction;
            end_dx4;
            end_dx6;
            end_dt4;
            end_dt6;
        }
        const default_action = NoAction;
        size = 512;
    }
    apply {

        if(ig_md.route.rmac_hit == 1w1 && ig_md.tunnel.type == SWITCH_TUNNEL_TYPE_SRV6) {
            if (!local_sid.apply().hit) {
                local_sid_fallback.apply();
            }
        }
    }

}

control SRv6Encap(
    inout switch_header_t hdr,
    inout switch_egress_metadata_t eg_md,
    inout switch_egress_tunnel_metadata_t tunnel)(
    switch_uint32_t srv6_rewrite_size = 10 * 1024
    ){

    action insert_srh_header(in bit<8> next_hdr,
                             in bit<8> hdr_ext_len,
                             in bit<8> last_entry,
                             in bit<8> segment_left) {
        hdr.srv6_srh.setValid();
        hdr.srv6_srh.next_hdr = next_hdr;
        hdr.srv6_srh.hdr_ext_len = hdr_ext_len;
        hdr.srv6_srh.routing_type = 0x4;
        hdr.srv6_srh.seg_left = segment_left;
        hdr.srv6_srh.last_entry = last_entry;
        hdr.srv6_srh.flags = 0;
        hdr.srv6_srh.tag = 0;
    }

    action rewrite_srh_0() {
        /* hdr.ipv6.next_hdr = proto; */
    }

    action rewrite_srh_1(bit<8> segment_left, srv6_sid_t s1) {
        // Insert SRH with SID list <S1>.
        hdr.ipv6.payload_len = hdr.ipv6.payload_len + 16w24; /* 8 + 16 * 1 */
        insert_srh_header(hdr.ipv6.next_hdr, 8w2, 8w0, segment_left);
        hdr.ipv6.next_hdr = 43;
        hdr.srv6_list[0].setValid();
        hdr.srv6_list[0].sid = s1;
    }

    action rewrite_srh_2(bit<8> segment_left, srv6_sid_t s1, srv6_sid_t s2) {
        // Insert SRH with SID list <S1, S2>.
        hdr.ipv6.payload_len = hdr.ipv6.payload_len + 16w40; /* 8 + 16 * 2 */
        insert_srh_header(hdr.ipv6.next_hdr, 8w4, 8w1, segment_left);
        hdr.ipv6.next_hdr = 43;
        hdr.srv6_list[0].setValid();
        hdr.srv6_list[1].setValid();
        hdr.srv6_list[0].sid = s1;
        hdr.srv6_list[1].sid = s2;
    }

    action rewrite_srh_3(bit<8> segment_left, srv6_sid_t s1,
                         srv6_sid_t s2, srv6_sid_t s3) {
        // Insert SRH with SID list <S1, S2, S3>.
        hdr.ipv6.payload_len = hdr.ipv6.payload_len + 16w56;
        insert_srh_header(hdr.ipv6.next_hdr, 8w6, 8w2, segment_left);
        hdr.ipv6.next_hdr = 43;
        hdr.srv6_list[0].setValid();
        hdr.srv6_list[1].setValid();
        hdr.srv6_list[2].setValid();
        hdr.srv6_list[0].sid = s1;
        hdr.srv6_list[1].sid = s2;
        hdr.srv6_list[2].sid = s3;
    }

    action rewrite_srh_4(bit<8> segment_left, srv6_sid_t s1, srv6_sid_t s2,
                         srv6_sid_t s3, srv6_sid_t s4) {
        // Insert SRH with SID list <S1, S2, S3, S4>.
        hdr.ipv6.payload_len = hdr.ipv6.payload_len + 16w72;
        insert_srh_header(hdr.ipv6.next_hdr, 8w8, 8w3, segment_left);
        hdr.ipv6.next_hdr = 43;
        hdr.srv6_list[0].setValid();
        hdr.srv6_list[1].setValid();
        hdr.srv6_list[2].setValid();
        hdr.srv6_list[3].setValid();
        hdr.srv6_list[0].sid = s1;
        hdr.srv6_list[1].sid = s2;
        hdr.srv6_list[2].sid = s3;
        hdr.srv6_list[3].sid = s4;
    }

    action rewrite_srh_list_5(srv6_sid_t s1, srv6_sid_t s2, srv6_sid_t s3,
                              srv6_sid_t s4, srv6_sid_t s5) {
        hdr.srv6_list[0].setValid();
        hdr.srv6_list[1].setValid();
        hdr.srv6_list[2].setValid();
        hdr.srv6_list[3].setValid();
        hdr.srv6_list[4].setValid();
        hdr.srv6_list[0].sid = s1;
        hdr.srv6_list[1].sid = s2;
        hdr.srv6_list[2].sid = s3;
        hdr.srv6_list[3].sid = s4;
        hdr.srv6_list[4].sid = s5;
    }

    action rewrite_srh_5(bit<8> segment_left, srv6_sid_t s1, srv6_sid_t s2,
                         srv6_sid_t s3, srv6_sid_t s4, srv6_sid_t s5) {
        // Insert SRH with SID list <S1, S2, S3, S4, S5>.
        hdr.ipv6.payload_len = hdr.ipv6.payload_len + 16w88;
        insert_srh_header(hdr.ipv6.next_hdr, 8w10, 8w4, segment_left);
        hdr.ipv6.next_hdr = 43;
        rewrite_srh_list_5(s1, s2, s3, s4, s5);
    }

    action rewrite_srh_6(bit<8> segment_left, srv6_sid_t s1, srv6_sid_t s2,
                         srv6_sid_t s3, srv6_sid_t s4, srv6_sid_t s5) {
        // Insert SRH with SID list <S1, S2, S3, S4, S5, S6>.
        hdr.ipv6.payload_len = hdr.ipv6.payload_len + 16w104;
        insert_srh_header(hdr.ipv6.next_hdr, 8w12, 8w5, segment_left);
        hdr.ipv6.next_hdr = 43;
        rewrite_srh_list_5(s1, s2, s3, s4, s5);
    }

    action rewrite_srh_7(bit<8> segment_left, srv6_sid_t s1, srv6_sid_t s2,
                         srv6_sid_t s3, srv6_sid_t s4, srv6_sid_t s5) {
        // Insert SRH with SID list <S1, S2, S3, S4, S5, S6, S7>.
        hdr.ipv6.payload_len = hdr.ipv6.payload_len + 16w120;
        insert_srh_header(hdr.ipv6.next_hdr, 8w14, 8w6, segment_left);
        hdr.ipv6.next_hdr = 43;
        rewrite_srh_list_5(s1, s2, s3, s4, s5);
    }

    action rewrite_srh_8(bit<8> segment_left, srv6_sid_t s1, srv6_sid_t s2,
                         srv6_sid_t s3, srv6_sid_t s4, srv6_sid_t s5) {
        // Insert SRH with SID list <S1, S2, S3, S4, S5, S6, S7, S8>.
        hdr.ipv6.payload_len = hdr.ipv6.payload_len + 16w136;
        insert_srh_header(hdr.ipv6.next_hdr, 8w16, 8w7, segment_left);
        hdr.ipv6.next_hdr = 43;
        rewrite_srh_list_5(s1, s2, s3, s4, s5);
    }

    action rewrite_srh_9(bit<8> segment_left, srv6_sid_t s1, srv6_sid_t s2,
                         srv6_sid_t s3, srv6_sid_t s4, srv6_sid_t s5) {
        // Insert SRH with SID list <S1, S2, S3, S4, S5, S6, S7, S8, S9>.
        hdr.ipv6.payload_len = hdr.ipv6.payload_len + 16w152;
        insert_srh_header(hdr.ipv6.next_hdr, 8w18, 8w8, segment_left);
        hdr.ipv6.next_hdr = 43;
        rewrite_srh_list_5(s1, s2, s3, s4, s5);
    }

    action rewrite_srh_10(bit<8> segment_left, srv6_sid_t s1, srv6_sid_t s2,
                         srv6_sid_t s3, srv6_sid_t s4, srv6_sid_t s5) {
        // Insert SRH with SID list <S1, S2, S3, S4, S5, S6, S7, S8, S9, S10>.
        hdr.ipv6.payload_len = hdr.ipv6.payload_len + 16w168;
        insert_srh_header(hdr.ipv6.next_hdr, 8w20, 8w9, segment_left);
        hdr.ipv6.next_hdr = 43;
        rewrite_srh_list_5(s1, s2, s3, s4, s5);
    }

    table srh_rewrite {
        key = {
            eg_md.route.mpls_l3_encap_id : exact;
        }
        actions = {
            @defaultonly NoAction;
            rewrite_srh_0; // No SRH
            rewrite_srh_1; // SRH with 1 segment
            rewrite_srh_2; // SRH with 2 segments
            rewrite_srh_3; // SRH with 3 segments
            rewrite_srh_4; // SRH with 4 segments
            rewrite_srh_5; // SRH with 5 segments
            rewrite_srh_6; // SRH with 6 segments
            rewrite_srh_7; // SRH with 7 segments
            rewrite_srh_8; // SRH with 8 segments
            rewrite_srh_9; // SRH with 9 segments
            rewrite_srh_10; // SRH with 10 segments
        }
        const default_action = NoAction;
        size = srv6_rewrite_size;
    }

    action insert_srh_1(bit<8> segment_left, srv6_sid_t s1) {
        rewrite_srh_2(segment_left + 1, hdr.inner_ipv6.dst_addr, s1);
    }
    action insert_srh_2(bit<8> segment_left, srv6_sid_t s1, srv6_sid_t s2) {
        rewrite_srh_3(segment_left + 1, hdr.inner_ipv6.dst_addr, s1, s2);
    }
    action insert_srh_3(bit<8> segment_left, srv6_sid_t s1,
                        srv6_sid_t s2, srv6_sid_t s3) {
        rewrite_srh_4(segment_left + 1, hdr.inner_ipv6.dst_addr, s1, s2, s3);
    }
    action insert_srh_4(bit<8> segment_left, srv6_sid_t s1,
                        srv6_sid_t s2, srv6_sid_t s3, srv6_sid_t s4) {
        rewrite_srh_5(segment_left + 1, hdr.inner_ipv6.dst_addr, s1, s2, s3, s4);
    }
    action insert_srh_5(bit<8> segment_left, srv6_sid_t s1, srv6_sid_t s2,
                        srv6_sid_t s3, srv6_sid_t s4) {
        rewrite_srh_6(segment_left + 1, hdr.inner_ipv6.dst_addr, s1, s2, s3, s4);
    }
    action insert_srh_6(bit<8> segment_left, srv6_sid_t s1, srv6_sid_t s2,
                        srv6_sid_t s3, srv6_sid_t s4) {
        rewrite_srh_7(segment_left + 1, hdr.inner_ipv6.dst_addr, s1, s2, s3, s4);
    }
    action insert_srh_7(bit<8> segment_left, srv6_sid_t s1, srv6_sid_t s2,
                        srv6_sid_t s3, srv6_sid_t s4) {
        rewrite_srh_8(segment_left + 1, hdr.inner_ipv6.dst_addr, s1, s2, s3, s4);
    }
    action insert_srh_8(bit<8> segment_left, srv6_sid_t s1, srv6_sid_t s2,
                        srv6_sid_t s3, srv6_sid_t s4) {
        rewrite_srh_9(segment_left + 1, hdr.inner_ipv6.dst_addr, s1, s2, s3, s4);
    }
    action insert_srh_9(bit<8> segment_left, srv6_sid_t s1, srv6_sid_t s2,
                        srv6_sid_t s3, srv6_sid_t s4) {
        rewrite_srh_10(segment_left + 1, hdr.inner_ipv6.dst_addr, s1, s2, s3, s4);
    }
    table srh_insert {
        key = {
            eg_md.route.mpls_l3_encap_id : exact;
        }
        actions = {
            NoAction;
            insert_srh_1;
            insert_srh_2;
            insert_srh_3;
            insert_srh_4;
            insert_srh_5;
            insert_srh_6;
            insert_srh_7;
            insert_srh_8;
            insert_srh_9;
        }
        const default_action = NoAction;
        size = srv6_rewrite_size;
    }
# 883 "/mnt/p4c-4127/p4src/shared/srv6.p4"
    action rewrite_srh_6more(srv6_sid_t s6) {
        // Insert SRH with SID list <S1, S2, S3, S4, S5, S6>.
        hdr.srv6_list[5].setValid();
        hdr.srv6_list[5].sid = s6;
    }

    action rewrite_srh_7more(srv6_sid_t s6, srv6_sid_t s7) {
        // Insert SRH with SID list <S1, S2, S3, S4, S5, S6, S7>.
        hdr.srv6_list[5].setValid();
        hdr.srv6_list[6].setValid();
        hdr.srv6_list[5].sid = s6;
        hdr.srv6_list[6].sid = s7;
    }

    action rewrite_srh_8more(srv6_sid_t s6, srv6_sid_t s7, srv6_sid_t s8) {
        // Insert SRH with SID list <S1, S2, S3, S4, S5, S6, S7, S8>.
        hdr.srv6_list[5].setValid();
        hdr.srv6_list[6].setValid();
        hdr.srv6_list[7].setValid();
        hdr.srv6_list[5].sid = s6;
        hdr.srv6_list[6].sid = s7;
        hdr.srv6_list[7].sid = s8;
    }

    action rewrite_srh_9more(srv6_sid_t s6, srv6_sid_t s7, srv6_sid_t s8,
                         srv6_sid_t s9) {
        // Insert SRH with SID list <S1, S2, S3, S4, S5, S6, S7, S8, S9>.
        hdr.srv6_list[5].setValid();
        hdr.srv6_list[6].setValid();
        hdr.srv6_list[7].setValid();
        hdr.srv6_list[8].setValid();
        hdr.srv6_list[5].sid = s6;
        hdr.srv6_list[6].sid = s7;
        hdr.srv6_list[7].sid = s8;
        hdr.srv6_list[8].sid = s9;
    }

    action rewrite_srh_10more(srv6_sid_t s6, srv6_sid_t s7, srv6_sid_t s8,
                         srv6_sid_t s9, srv6_sid_t s10) {
        // Insert SRH with SID list <S1, S2, S3, S4, S5, S6, S7, S8, S9, S10>.
        hdr.srv6_list[5].setValid();
        hdr.srv6_list[6].setValid();
        hdr.srv6_list[7].setValid();
        hdr.srv6_list[8].setValid();
        hdr.srv6_list[9].setValid();
        hdr.srv6_list[5].sid = s6;
        hdr.srv6_list[6].sid = s7;
        hdr.srv6_list[7].sid = s8;
        hdr.srv6_list[8].sid = s9;
        hdr.srv6_list[9].sid = s10;
    }
    table srh_rewrite_continue {
        key = {
            eg_md.route.mpls_l3_encap_id : exact;
        }
        actions = {
            NoAction;
            rewrite_srh_6more; // SRH with 6 segments
            rewrite_srh_7more; // SRH with 7 segments
            rewrite_srh_8more; // SRH with 8 segments
            rewrite_srh_9more; // SRH with 9 segments
            rewrite_srh_10more; // SRH with 10 segments
        }
        const default_action = NoAction;
        size = srv6_rewrite_size;
    }

    action insert_srh_5more(srv6_sid_t s5) {
        rewrite_srh_6more(s5);
    }
    action insert_srh_6more(srv6_sid_t s5, srv6_sid_t s6) {
        rewrite_srh_7more(s5, s6);
    }
    action insert_srh_7more(srv6_sid_t s5, srv6_sid_t s6, srv6_sid_t s7) {
        rewrite_srh_8more(s5, s6, s7);
    }
    action insert_srh_8more(srv6_sid_t s5, srv6_sid_t s6,
                            srv6_sid_t s7, srv6_sid_t s8) {
        rewrite_srh_9more(s5, s6, s7, s8);
    }
    action insert_srh_9more(srv6_sid_t s5, srv6_sid_t s6,
                            srv6_sid_t s7, srv6_sid_t s8, srv6_sid_t s9) {
        rewrite_srh_10more(s5, s6, s7, s8, s9);
    }
    table srh_insert_continue {
        key = {
            eg_md.route.mpls_l3_encap_id : exact;
        }
        actions = {
            NoAction;
            insert_srh_5more;
            insert_srh_6more;
            insert_srh_7more;
            insert_srh_8more;
            insert_srh_9more;
        }
        const default_action = NoAction;
        size = srv6_rewrite_size;
    }
    apply {




        /* H.Insert needs inner ipv6 addr */
        if (eg_md.tunnel.encap_type == SWITCH_TUNNEL_ENCAP_TYPE_H_INSERT_SRV6) {
            srh_insert.apply();
            srh_insert_continue.apply();
        } else if ((eg_md.tunnel.encap_type == SWITCH_TUNNEL_ENCAP_TYPE_END_INSERT_SRV6) ||
                (eg_md.tunnel.encap_type == SWITCH_TUNNEL_ENCAP_TYPE_ENCAP_SRV6)) {
            srh_rewrite.apply();
            srh_rewrite_continue.apply();
        }
    }
}

control SRv6DSCP(
        inout switch_header_t hdr,
        inout switch_egress_metadata_t eg_md)(
        switch_uint32_t dscp_table_size = 4
        ) {
    action copy_dscp_inner_ipv4() {
        hdr.ipv4.diffserv[7:2] = eg_md.common.srv6_tc;
        eg_md.qos.chgDSCP_disable = 1;
    }
    action copy_dscp_inner_ipv6() {
        hdr.ipv6.traffic_class[7:2] = eg_md.common.srv6_tc;
        eg_md.qos.chgDSCP_disable = 1;
    }
    table dscp_rewrite {
        key = {
            hdr.ipv4.isValid() : exact;
            hdr.ipv6.isValid() : exact;
        }

        actions = {
            NoAction;
            copy_dscp_inner_ipv4;
            copy_dscp_inner_ipv6;
        }
        const entries = {
            (true, false) : copy_dscp_inner_ipv4();
            (false, true) : copy_dscp_inner_ipv6();
        }
        const default_action = NoAction;
        size = dscp_table_size;
    }

    apply {
        if (eg_md.common.srv6_set_dscp == 1) {
            dscp_rewrite.apply();
        }
    }
}
# 214 "/mnt/p4c-4127/p4src/switch-tofino2/switch_tofino_x1.p4" 2
# 1 "/mnt/p4c-4127/p4src/shared/tunnel.p4" 1
/* IP Tunnel by jiangminda */
/* pipline 0 */
/* 入口隧道处理 */

// Flow hash calculation.
// Hash<bit<32>>(HashAlgorithm_t.CRC32) tunnel_ip_hash;
// Hash<bit<32>>(HashAlgorithm_t.CRC32) tunnel_mpls_hash;

// action compute_tunnel_ip_hash(in switch_header_t hdr, out bit<32> hash) {
//     hash = tunnel_ip_hash.get({hdr.ipv4.src_addr, hdr.ipv4.dst_addr});
// }

// action compute_tunnel_mpls_hash(in switch_ingress_tunnel_metadata_t tunnel, out bit<32> hash) {
//     hash = tunnel_mpls_hash.get({tunnel.first_label, tunnel.second_label, tunnel.third_label,
//                                 tunnel.last_label, tunnel.entropy_label});
// }


// control Tunnel_Validation(
//         in switch_header_t hdr,
//         inout switch_ingress_metadata_t ig_md)(
//         switch_uint32_t validation_table_size = 64) {

//     MPLS_Validation() mpls_validate;

//     action malformed_ethernet_pkt(bit<8> reason) {
//         ig_md.tunnel.drop_reason = reason;
//     }
//     action valid_unicast_pkt() {

//     }
//     table validate_ethernet {
//         key = {
//             hdr.ethernet.src_addr : ternary;
//             hdr.ethernet.dst_addr : ternary;
//         }
//         actions = {
//             malformed_ethernet_pkt;
//             valid_unicast_pkt;
//         }
//         size = validation_table_size;
//     }

//     action valid_ipv4_pkt() {

//     }
//     action malformed_ipv4_pkt(bit<8> reason) {
//         ig_md.tunnel.drop_reason = reason;
//     }
//     table validate_ipv4 {
//         key = {
//             hdr.ipv4.version                : ternary;
//             hdr.ipv4.ihl                    : ternary;
//             hdr.ipv4.flags                  : ternary;
//             hdr.ipv4.frag_offset            : ternary;
//             hdr.ipv4.ttl                    : ternary;
//             hdr.ipv4.src_addr               : ternary;
//         }
//         actions = {
//             valid_ipv4_pkt;
//             malformed_ipv4_pkt;
//         }
//         size = validation_table_size;
//     }

//    apply {
//         switch(validate_ethernet.apply().action_run) {
//             malformed_ethernet_pkt : {}
//             default : {
//                 if (hdr.ipv4.isValid()) {
//                     validate_ipv4.apply();
//                 }
//                 if (hdr.mpls_ig[0].isValid()) {
//                     mpls_validate.apply(hdr, ig_md);
//                 }
//             }
//         }
//     }
// }

control TunnelType(
        inout switch_header_t hdr,
        inout switch_ingress_metadata_t ig_md)(
        switch_uint32_t set_tunnel_type_size=32) {

    action set_tunnel_type(switch_tunnel_type_t tunnel_type) {
        ig_md.tunnel.type = tunnel_type;
    }

    action miss() {
        ig_md.tunnel.type = SWITCH_TUNNEL_TYPE_NONE;
    }

    table tunnel_type {
        key = {
            hdr.ipv4.isValid() : exact;
            hdr.ipv6.isValid() : exact;
            hdr.gre.isValid() : exact;
            hdr.vxlan.isValid() : exact;
            hdr.mpls_ig[0].isValid() : exact;
            /* SRV6: v6 valid + vxlan Invalid */
            /* VXLAN: v6 valid + vxlan valid */
            ig_md.tunnel.inner_pkt_parsed : exact;
        }
        actions = {
            miss;
            set_tunnel_type;
        }
        const default_action = miss;
        size = set_tunnel_type_size;
    }

    apply{
        tunnel_type.apply();
    }
}

control IgTunnel(
        inout switch_header_t hdr,
        inout switch_ingress_metadata_t ig_md)(
        switch_uint32_t src_dst_addr_size,
        switch_uint32_t dst_addr_size,
        switch_uint32_t g_dst_addr_size,
        switch_uint32_t vxlan_terminate_table_size,
        switch_uint32_t ilm_table_size,
        switch_uint32_t ilm3_table_size){

    IngressMPLS(ilm_table_size, ilm3_table_size) ingress_mpls;
    MPLS_ILM2(ilm_table_size, 512, 64) ilm2;
    MPLS_ILM3(ilm3_table_size, 512, 64) ilm3;
    IngressIPTunnel(src_dst_addr_size, dst_addr_size, g_dst_addr_size) ingress_iptunnel;





    VxlanTerminate(vxlan_terminate_table_size) vxlan_terminate;

    SRv6() srv6;
    SRv6_Post() srv6_post;


    apply {
        if(ig_md.route.rmac_hit == 1w1 && ig_md.tunnel.type != SWITCH_TUNNEL_TYPE_MPLS && ig_md.tunnel.type != SWITCH_TUNNEL_TYPE_NONE) {
            ingress_iptunnel.apply(hdr, ig_md);
        }

        if(ig_md.route.rmac_hit == 1w1) {
            if (ig_md.tunnel.type == SWITCH_TUNNEL_TYPE_MPLS) {
                ingress_mpls.apply(hdr, ig_md);
            } else

            if(ig_md.tunnel.type == SWITCH_TUNNEL_TYPE_SRV6) {
                srv6.apply(hdr, ig_md);
            } else







            if ((ig_md.tunnel.type == SWITCH_TUNNEL_TYPE_IPV4_VXLAN) ||
                    (ig_md.tunnel.type == SWITCH_TUNNEL_TYPE_IPV6_VXLAN)){
                vxlan_terminate.apply(hdr, ig_md);
            }
        }
        // 拆解ilm2/ilm3和srv6，解决stage问题
        if(ig_md.route.rmac_hit == 1w1 && ig_md.tunnel.type == SWITCH_TUNNEL_TYPE_MPLS
                && ig_md.tunnel.mpls_enable == true) {
            ilm2.apply(hdr, ig_md);
        }

        if(ig_md.route.rmac_hit == 1w1 && ig_md.tunnel.type == SWITCH_TUNNEL_TYPE_SRV6) {
            srv6_post.apply(hdr, ig_md);
        }


        if(ig_md.route.rmac_hit == 1w1 && ig_md.tunnel.type == SWITCH_TUNNEL_TYPE_MPLS && ig_md.tunnel.mpls_enable == true) {
            ilm3.apply(hdr, ig_md);
        }


    }
}

control TunnelDecap(
        inout switch_header_t hdr,
        inout switch_ingress_metadata_t ig_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm)(
        switch_uint32_t tunnel_decap_table_size = 512) {

    // action decap_l2vpn_cw_tunnel() {
    //     hdr.ethernet.setInvalid();
    //     hdr.cw.setInvalid();
    //     ig_md.common.pkt_type = FABRIC_PKT_TYPE_ETH;
    //     ig_md.route.rmac_hit = 1w0;
    // }

    action common_decap() {
        hdr.ethernet.setInvalid();
        hdr.vlan_tag[0].setInvalid();
        hdr.vlan_tag[1].setInvalid();
    }


    action decap_l2vpn_tunnel() {
        common_decap();
        ig_md.common.pkt_type = FABRIC_PKT_TYPE_ETH;
        ig_md.route.rmac_hit = 1w0;
    }
    action decap_l3vpn_tunnel(switch_pkt_type_t pkt_type) {
        common_decap();
        ig_md.common.pkt_type = pkt_type;
    }
    action decap_mpls_tunnel() {
        common_decap();
        ig_md.common.pkt_type = FABRIC_PKT_TYPE_MPLS;
    }
# 235 "/mnt/p4c-4127/p4src/shared/tunnel.p4"
    action decap_vxlan_tunnel() {
        ig_md.route.rmac_hit = 1w0;
        hdr.vxlan.setInvalid();
        hdr.udp.setInvalid();
        hdr.ipv4.setInvalid();
        hdr.ipv6.setInvalid();
        common_decap();
        ig_md.common.pkt_type = FABRIC_PKT_TYPE_ETH;
    }

    action remove_srh_header() {
        hdr.srv6_srh.setInvalid();
        hdr.srv6_list[0].setInvalid();
        hdr.srv6_list[1].setInvalid();
        hdr.srv6_list[2].setInvalid();
        hdr.srv6_list[3].setInvalid();
        hdr.srv6_list[4].setInvalid();
        hdr.srv6_list[5].setInvalid();
        hdr.srv6_list[6].setInvalid();
        hdr.srv6_list[7].setInvalid();
        hdr.srv6_list[8].setInvalid();
        hdr.srv6_list[9].setInvalid();
    }

    action decap_srv6_inner_unknown() {
        common_decap();
        hdr.ipv6.setInvalid();
        remove_srh_header();
    }

    action decap_srh() {
        hdr.ipv6.next_hdr = hdr.srv6_srh.next_hdr;

        common_decap();
        remove_srh_header();
        ig_md.common.pkt_type = FABRIC_PKT_TYPE_IPV6;
    }
    action decap_srv6_inner_ethernet() {
        common_decap();
        hdr.ipv6.setInvalid();
        ig_md.common.pkt_type = FABRIC_PKT_TYPE_ETH;
        remove_srh_header();
    }

    action decap_srv6_inner_ip(switch_pkt_type_t pkt_type) {
        common_decap();
        hdr.ipv6.setInvalid();
        ig_md.common.pkt_type = pkt_type;
        remove_srh_header();
    }

    action srv6_usp() {
        hdr.ipv6.next_hdr = hdr.srv6_srh.next_hdr;
        remove_srh_header();
        ig_md.common.pkt_type = FABRIC_PKT_TYPE_IPV6;

        hdr.pri_data.setValid();
        hdr.pri_data.src_port = ig_md.common.src_port;
        hdr.pri_data.egress_port = ig_intr_md_for_tm.ucast_egress_port;
        hdr.pri_data.eport = ig_md.common.eport;
        hdr.pri_data.ether_type = hdr.ethernet.ether_type;

        ig_intr_md_for_tm.ucast_egress_port = SWITCH_PORT_FRONT_RECIRC;
        ig_intr_md_for_tm.bypass_egress = 1;
        hdr.ethernet.ether_type = 0x9500;

        hdr.ext_tunnel_decap_data_encap.setInvalid();
        hdr.ext_srv6.setInvalid();
    }

    @ignore_table_dependency("Ig_front.system_acl.system_acl")
    @ignore_table_dependency("Ig_front.qos_resolve.dscp_resolve")
    @ignore_table_dependency("Ig_front.flowspec_disable.flowspec_disable")
    @stage(10)
    table tunnel_decap {
        key = {

            hdr.srv6_srh.next_hdr : ternary;

            hdr.ipv6.next_hdr : ternary;

            hdr.srv6_srh.isValid() : ternary;
            ig_md.srv6.srh_terminate : ternary;
            ig_md.srv6.usp : ternary;

            ig_md.tunnel.terminate : ternary;
            ig_md.tunnel.type : ternary;
            ig_md.tunnel.inner_pkt_parsed : ternary;
            ig_md.tunnel.mpls_enable : ternary;//no enable,can not terminate
        }
        actions = {
            NoAction;




            decap_vxlan_tunnel;

            decap_mpls_tunnel;
            // decap_l2vpn_cw_tunnel;
            decap_l2vpn_tunnel;
            decap_l3vpn_tunnel;


            decap_srv6_inner_unknown;
            decap_srh;
            decap_srv6_inner_ethernet;
            decap_srv6_inner_ip;
            srv6_usp;

        }
        size = tunnel_decap_table_size;
    }

    apply {

        if(ig_md.route.rmac_hit == 1w1 && ig_md.tunnel.type != SWITCH_TUNNEL_TYPE_NONE) {
            tunnel_decap.apply();
        }

    }
}

/* to deal with ttl after ig pipe 0 termination */
control TTL_REBUILD(
        inout switch_header_t hdr,
        inout switch_egress_metadata_t eg_md)(
        switch_uint16_t ttl_reset_table_size = 16) {

    action rewrite_ipv4_ttl() {
        hdr.ipv4.ttl = eg_md.tunnel.ttl;
    }

    action rewrite_ipv6_ttl() {
        hdr.ipv6.hop_limit = eg_md.tunnel.ttl;
    }

    action rewrite_mpls_ttl() {
        hdr.mpls_ig[0].ttl = eg_md.tunnel.ttl;
    }

    table ttl_reset {
        key = {
            hdr.ipv4.isValid() : exact;
            hdr.ipv6.isValid() : exact;
            eg_md.lkp.tmp_ttl : exact;
            hdr.mpls_ig[0].isValid() : exact;
        }
        actions = {
            rewrite_ipv4_ttl;
            rewrite_ipv6_ttl;
            rewrite_mpls_ttl;
            NoAction;
        }
        const entries = {
            (true, false, 0, false) : rewrite_ipv4_ttl();
            (false, true, 0, false) : rewrite_ipv6_ttl();
            (false, false, 0, true) : rewrite_mpls_ttl();
        }
        const default_action = NoAction;
        size = ttl_reset_table_size;
    }

    apply {
        /* now, for mpls or SRV6 ttl_reset */
        if (eg_md.tunnel.ttl_copy == 1w1) {
            ttl_reset.apply();
        }
    }
}

control GetInnerInfo(
        inout switch_header_t hdr,
        inout switch_egress_metadata_t eg_md) {

    action get_ipv4_info() {
        eg_md.tunnel.ttl = hdr.inner_ipv4.ttl;
        eg_md.tunnel.inner_dscp = hdr.inner_ipv4.diffserv[7:2];
        eg_md.tunnel.ip_proto = 4;
        eg_md.tunnel.gre_ether_type = 0x0800;
        //eg_md.tunnel.payload_len = hdr.inner_ipv4.total_len;
    }

    action get_ipv6_info() {
        eg_md.tunnel.ttl = hdr.inner_ipv6.hop_limit;
        eg_md.tunnel.inner_dscp = hdr.inner_ipv6.traffic_class[7:2];
        eg_md.tunnel.ip_proto = 41;
        eg_md.tunnel.gre_ether_type = 0x86dd;
        //eg_md.tunnel.payload_len = hdr.inner_ipv6.payload_len + 16w40;
    }

    action get_mpls_info() {
        eg_md.tunnel.ttl = hdr.mpls_vc_eg.ttl;
        eg_md.tunnel.vc_exp = hdr.mpls_vc_eg.exp;
    }
    @stage(0)
    table get_inner_info {
        key = {
            hdr.mpls_vc_eg.isValid() : exact;
            hdr.inner_ipv4.isValid() : exact;
            hdr.inner_ipv6.isValid() : exact;
        }
        actions = {
            NoAction;
            get_ipv4_info;
            get_ipv6_info;
            get_mpls_info;
        }
        const default_action = NoAction;
        size = 8;
    }

    apply {
        get_inner_info.apply();
    }
}

control EncapOuter(
        inout switch_header_t hdr,
        inout switch_egress_metadata_t eg_md) {

    action add_ipv4_header() {
        hdr.ipv4.setValid();
        eg_md.lkp.ip_type = SWITCH_IP_TYPE_IPV4;
        eg_md.lkp.ip_inner = 0;
        eg_md.lkp.ipv4_tos = 0;
        hdr.ipv4.version = 4w4;
        hdr.ipv4.ihl = 4w5;
        hdr.ipv4.identification = 0;
        // hdr.ipv4.flags = 0;
        hdr.ipv4.frag_offset = 0;
        hdr.ipv4.diffserv = 0;
        // hdr.ipv4.protocol = proto;
    }
    action add_ipv6_header() {

        hdr.ipv6.setValid();
        eg_md.lkp.ip_type = SWITCH_IP_TYPE_IPV6;
        eg_md.lkp.ip_inner = 0;
        eg_md.lkp.ipv6_tos = 0;
        hdr.ipv6.version = 4w6;
        hdr.ipv6.traffic_class = 0;
        hdr.ipv6.flow_label[19:16] = 4w0;
        hdr.ipv6.flow_label[15:0] = eg_md.common.hash;
        // hdr.ipv6.next_hdr = ip_proto;

    }
# 498 "/mnt/p4c-4127/p4src/shared/tunnel.p4"
    action add_udp_header(bit<16> src_port, bit<16> dst_port) {
        hdr.udp.setValid();
        hdr.udp.src_port = src_port;
        eg_md.lkp.l4_src_port = src_port;
        hdr.udp.dst_port = dst_port;
        eg_md.lkp.l4_dst_port = dst_port;
        hdr.udp.checksum = 0;//todo calculate
        // hdr.udp.length = 0;
    }

    action add_vxlan_header(bit<24> vni) {

        hdr.vxlan.setValid();
        hdr.vxlan.flags = 8w0x08;
        //hdr.vxlan.reserved = 0;
        hdr.vxlan.vni = vni;
        //hdr.vxlan.reserved2 = 0;

    }
# 545 "/mnt/p4c-4127/p4src/shared/tunnel.p4"
    action encap_outer_ipv4_vxlan(bit<16> dst_port) {
        add_ipv4_header();
        hdr.ipv4.flags = 2;//3 bit, 010 表示不能分片
        hdr.ipv4.protocol = 17;
        eg_md.lkp.ip_proto = 17;
        // Total length = packet length + 50
        // IPv4 (20) + UDP (8) + VXLAN (8)+ Inner Ethernet (14)
        // hdr.ipv4.total_len = eg_md.tunnel.payload_len + 16w50;
        // IPv4 (20) + UDP (8) + VXLAN (8)- fabric (14)
        hdr.ipv4.total_len = eg_md.tunnel.payload_len + 16w22;
        add_udp_header(eg_md.common.hash, dst_port);
        //hdr.udp.length = eg_md.tunnel.payload_len + 16w30;
        hdr.udp.length = eg_md.tunnel.payload_len + 16w2;
        add_vxlan_header(eg_md.tunnel.vni);
        eg_md.tunnel.next_hdr_type = SWITCH_TUNNEL_NEXT_HDR_TYPE_IPV4;
        eg_md.common.pkt_length = eg_md.common.pkt_length + 16w36;
    }

    action encap_outer_ipv6_vxlan(bit<16> dst_port) {

        add_ipv6_header();
        //hdr.ipv6.payload_len = eg_md.tunnel.payload_len + 16w30;
        // UDP (8) + VXLAN (8)- fabric (14)
        hdr.ipv6.payload_len = eg_md.tunnel.payload_len + 16w2;
        hdr.ipv6.next_hdr = 17;

        add_udp_header(eg_md.common.hash, dst_port);
        // UDP length = packet length + 30
        // UDP (8) + VXLAN (8)+ Inner Ethernet (14)
        //hdr.udp.length = eg_md.tunnel.payload_len + 16w30;
        // UDP (8) + VXLAN (8)- fabric (14)
        hdr.udp.length = eg_md.tunnel.payload_len + 16w2;

        add_vxlan_header(eg_md.tunnel.vni);
        eg_md.tunnel.next_hdr_type = SWITCH_TUNNEL_NEXT_HDR_TYPE_IPV6;

        eg_md.common.pkt_length = eg_md.common.pkt_length + 16w56;

    }

    table encap_outer {
        key = {
            eg_md.tunnel.encap_type : exact;
        }
        actions = {
            NoAction;




            encap_outer_ipv4_vxlan;
            encap_outer_ipv6_vxlan;
        }
        const default_action = NoAction;
        size = 16;
    }

    apply {
        encap_outer.apply();
    }
}

control L3EncapMapping(
        inout switch_egress_metadata_t eg_md)(
        switch_uint32_t l3_encap_mapping_size) {

    action l3_encap_id_mapping(bit<16> l3_encap_id, switch_tunnel_encap_type_t type, bit<1> l3encap_hit) {
        eg_md.route.iptunnel_l3_encap_id = l3_encap_id;
        eg_md.tunnel.encap_type = type;
        //eg_md.common.pkt_length = eg_md.common.pkt_length + encap_length;
        eg_md.tunnel.l3_encap_mapping_hit = l3encap_hit;
    }

    @stage(1)
    table l3_encap_mapping{
        key = {
            eg_md.common.l3_encap : exact;
        }
        actions = {
            l3_encap_id_mapping;
        }
        const default_action = l3_encap_id_mapping(0, 0, 0);
        size = l3_encap_mapping_size;
    }
    apply {
        l3_encap_mapping.apply();
    }
}

// control L4EncapMapping(
//         inout switch_egress_metadata_t eg_md) {

//     const switch_uint32_t l4_encap_mapping_size = 65536;

//     action l4_encap_id_mapping(switch_tunnel_encap_type_t type, bit<16> encap_length) {
//         /* global and local both 16 bit, directly use global */
//         eg_md.tunnel.encap_type = type;
//         eg_md.common.pkt_length = eg_md.common.pkt_length + encap_length;
//     }
//
//     table l4_encap_mapping{
//         key = {
//             eg_md.tunnel.l4_encap : exact;
//         }
//         actions = {
//             l4_encap_id_mapping;
//         }
//         const default_action = l4_encap_id_mapping(0, 0);
//         size = l4_encap_mapping_size;
//     }
//     apply {
//         l4_encap_mapping.apply();
//     }
// }
# 215 "/mnt/p4c-4127/p4src/switch-tofino2/switch_tofino_x1.p4" 2

/* by yeweixin */
# 1 "/mnt/p4c-4127/p4src/shared/ipfix.p4" 1

control PortIpfix_FrontIg(inout switch_header_t hdr,
        inout switch_ingress_metadata_t ig_md,
        in ingress_intrinsic_metadata_t ig_intr_md)(
        switch_uint32_t port_ipfix_table_size=512
        ) {

    Random<bit<16>>() random;

    action sample_to_cpu(switch_ipfix_flow_id_t flow_id, switch_ipfix_mode_t mode,
            switch_ipfix_gap_t sample_gap, switch_ipfix_random_mask_t random_mask,
            switch_ipfix_session_t session_id) {
        ig_md.ipfix.enable = true;
        ig_md.ipfix.flow_id = flow_id;
        ig_md.ipfix.mode = mode;
        ig_md.ipfix.sample_gap = sample_gap;
        ig_md.ipfix.random_mask = random_mask;
        ig_md.ipfix.random_num = random.get();
    }
    @placement_priority(127)
    table ig_port_to_ipfix_flow {
        key = {
            ig_md.common.src_port : exact;
            // ig_md.ipfix.pkt_type : exact;
            hdr.ipv4.isValid() : exact;
            hdr.ipv6.isValid() : exact;
            hdr.mpls_ig[0].isValid() : exact;
        }

        actions = {
            sample_to_cpu;
        }
        size = port_ipfix_table_size;
    }

    apply{


        if (ig_md.srv6.is_loopback == 0) {

            ig_port_to_ipfix_flow.apply();

        }


    }
}

control PortIpfix_FrontEg(inout switch_header_t hdr,
        in egress_intrinsic_metadata_t eg_intr_md,
        inout switch_egress_metadata_t eg_md) (
        switch_uint32_t port_ipfix_table_size=512
        ){

    Random<bit<16>>() random;

    action sample_to_cpu(switch_ipfix_flow_id_t flow_id, switch_ipfix_mode_t mode,
            switch_ipfix_gap_t sample_gap, switch_ipfix_random_mask_t random_mask,
            switch_ipfix_session_t session_id) {
        eg_md.ipfix.enable = true;
        eg_md.ipfix.flow_id = flow_id;
        eg_md.ipfix.mode = mode;
        eg_md.ipfix.sample_gap = sample_gap;
        eg_md.ipfix.random_mask = random_mask;
        eg_md.ipfix.random_num = random.get();
    }

    table eg_port_to_ipfix_flow {
        key = {
            eg_md.common.dst_port : exact;
            // eg_md.ipfix.pkt_type : exact;
            hdr.ipv4.isValid() : exact;
            hdr.ipv6.isValid() : exact;
            hdr.mpls_vc_eg.isValid() : exact;

        }

        actions = {
            sample_to_cpu;
        }

        size = port_ipfix_table_size;
    }

    apply{

        eg_port_to_ipfix_flow.apply();

    }
}

control SampleToCPU_FrontIg(inout switch_ingress_metadata_t ig_md,
        inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr) {

    action set_sample_mode_random() {
        ig_md.ipfix.random_num = ig_md.ipfix.random_num & ig_md.ipfix.random_mask;
    }

    action set_sample_mode_fixed() {
        ig_md.ipfix.random_num = ig_md.ipfix.sample_gap;
    }

    @placement_priority(127)
    table ipfix_sample_mode {
        key = {
            // ig_md.ipfix.enable : exact;
            ig_md.ipfix.mode: exact;
        }

        actions = {
            set_sample_mode_random;
            set_sample_mode_fixed;
        }

        size = 4;
        default_action = set_sample_mode_random;
        const entries = {
            (0) : set_sample_mode_random();
            (1) : set_sample_mode_fixed();
        }
    }

    action set_delta() {
        ig_md.ipfix.delta = ig_md.ipfix.random_num |-| ig_md.ipfix.sample_gap;
    }

    action modify_invalid_random() {
        ig_md.ipfix.random_num = 1;
     ig_md.ipfix.delta = 0;
    }

    @ignore_table_dependency("Ig_front.ip_valid.ip_calc1")
    @placement_priority(127)
    @stage(3)
    table ipfix_modify_random {
        key = {
            ig_md.ipfix.enable : exact;
            ig_md.ipfix.random_num : exact;
        }

        actions = {
            NoAction;
            set_delta;
            modify_invalid_random;
        }

        size = 32;
        default_action = set_delta;
        // const entries = {
        //     (true, 0) : modify_invalid_random();
        //     (false, 0) : NoAction();
        // }
    }

    const bit<32> ipfix_size = 256;
    Register<switch_ipfix_t, bit<16>>(ipfix_size, 0) sample_count_reg;
    RegisterAction<switch_ipfix_t, bit<16>, switch_ipfix_t> (sample_count_reg) cal_count = {
        void apply(inout switch_ipfix_t reg, out switch_ipfix_t count){
            if(reg < ig_md.ipfix.sample_gap) {
                reg = reg + 1;
                count = reg;
            } else {
                reg = 1;
                count = reg;
            }
        }
    };

    action set_packet_count() {
        ig_md.ipfix.count = cal_count.execute(ig_md.ipfix.flow_id);
    }

    @stage(4)
    table ipfix_packet_count{
        key = {
            ig_md.ipfix.enable: exact;
        }
        actions = {
            NoAction;
            set_packet_count;
        }
        size = 2;
        default_action = NoAction;
        // const entries = {
        //     (true) : set_packet_count();
        //     (false) : NoAction();
        // }
    }

    action set_random_flag(){
        ig_md.ipfix.random_flag = 1;
    }

    action reset_random_flag(){
        ig_md.ipfix.random_flag = 0;
    }

    table ipfix_set_random_flag {
        key = {
            ig_md.ipfix.enable : exact;
            ig_md.ipfix.count :exact;
        }

        actions = {
            set_random_flag;
            reset_random_flag;
            NoAction;
        }

        size = 32;
        default_action = reset_random_flag;
        // const entries = {
        //     (true, 1) : set_random_flag();
        //     (false, 1) : NoAction();
        // }
    }

    Register<switch_ipfix_t, bit<16>>(ipfix_size, 1) check_sample_flag_reg;
    RegisterAction<switch_ipfix_t, bit<16>, bit<1>> (check_sample_flag_reg) set_random = {
        void apply(inout switch_ipfix_t reg, out bit<1> flag){
            reg = ig_md.ipfix.random_num;
            if (reg == 1) {
                flag = 1;
            } else {
                flag = 0;
            }
        }
    };
    RegisterAction<switch_ipfix_t, bit<16>, bit<1>> (check_sample_flag_reg) compare_random = {
        void apply(inout switch_ipfix_t reg, out bit<1> flag){
            if(reg == ig_md.ipfix.count) {
                flag = 1;
            } else {
                flag = 0;
            }
        }
    };

    action set_random_num() {
        ig_md.mirror.sample_flag = set_random.execute(ig_md.ipfix.flow_id);
    }

    action set_flag() {
        ig_md.mirror.sample_flag = compare_random.execute(ig_md.ipfix.flow_id);
    }

    // @placement_priority(-1)
    table ipfix_set_sample_flag {
        key = {
            ig_md.ipfix.enable : exact;
            ig_md.ipfix.random_flag:exact;
        }

        actions = {
            set_random_num;
            set_flag;
            NoAction;
        }

        size = 4;
        default_action = NoAction;
        // const entries = {
        //     (true, 1) : set_random_num();
        //     (true, 0) : set_flag();
        // }
    }

    action calc_random_num() {
        ig_md.ipfix.random_num = ig_md.ipfix.delta;
    }

    @placement_priority(127)
    table ipfix_random_calc {
        key = {
            // ig_md.ipfix.enable : exact;
            ig_md.ipfix.delta : exact;
        }

        actions = {
            calc_random_num;
            NoAction;
        }

        size = 32;
        default_action = calc_random_num;
        // const entries = {
        //     (0) : NoAction();
        //     (1) : calc_random_num();
        //     // (false, 0) : NoAction();
        // }
    }

    apply {

        if(ig_md.ipfix.enable == true) {
            ipfix_sample_mode.apply();
        }
        ipfix_packet_count.apply();
        ipfix_modify_random.apply();
        ipfix_random_calc.apply();
        ipfix_set_random_flag.apply();
        ipfix_set_sample_flag.apply();

    }
}

control SampleToCPU_FrontEg(inout switch_egress_metadata_t eg_md,
        inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr) {

    action set_sample_mode_random() {
        eg_md.ipfix.random_num = eg_md.ipfix.random_num & eg_md.ipfix.random_mask;
    }

    action set_sample_mode_fixed() {
        eg_md.ipfix.random_num = eg_md.ipfix.sample_gap;
    }

    table ipfix_sample_mode {
        key = {
            eg_md.ipfix.enable : exact;
            eg_md.ipfix.mode: exact;
        }

        actions = {
            set_sample_mode_random;
            set_sample_mode_fixed;
        }

        size = 4;
        default_action = set_sample_mode_random;
        // const entries = {
        //     (true, 0) : set_sample_mode_random();
        //     (true, 1) : set_sample_mode_fixed();
        // }
    }

    action set_delta() {
        eg_md.ipfix.delta = eg_md.ipfix.random_num |-| eg_md.ipfix.sample_gap;
    }

    action modify_invalid_random() {
        eg_md.ipfix.random_num = 1;
     eg_md.ipfix.delta = 0;
    }

    table ipfix_modify_random {
        key = {
            eg_md.ipfix.enable : exact;
            eg_md.ipfix.random_num : exact;
        }

        actions = {
            NoAction;
            set_delta;
            modify_invalid_random;
        }

        size = 32;
        default_action = set_delta;
        // const entries = {
        //     (true, 0) : modify_invalid_random();
        //     (false, 0) : NoAction;
        // }
    }

    const bit<32> ipfix_size = 256;
    Register<switch_ipfix_t, bit<16>>(ipfix_size, 0) sample_count_reg;
    RegisterAction<switch_ipfix_t, bit<16>, switch_ipfix_t> (sample_count_reg) cal_count = {
        void apply(inout switch_ipfix_t reg, out switch_ipfix_t count){
            if(reg < eg_md.ipfix.sample_gap) {
                reg = reg + 1;
                count = reg;
            } else {
                reg = 1;
                count = reg;
            }
        }
    };

    action set_packet_count() {
        eg_md.ipfix.count = cal_count.execute(eg_md.ipfix.flow_id);
    }

    table ipfix_packet_count{
        key = {
            eg_md.ipfix.enable: exact;
        }

        actions = {
            NoAction;
            set_packet_count;
        }

        size = 2;
        default_action = NoAction;
        // const entries = {
        //     (true) : set_packet_count();       
        //     (false) : NoAction();     
        // }
    }

    action set_random_flag(){
        eg_md.ipfix.random_flag = 1;
    }

    action reset_random_flag(){
        eg_md.ipfix.random_flag = 0;
    }

    table ipfix_set_random_flag {
        key = {
            eg_md.ipfix.enable : exact;
            eg_md.ipfix.count :exact;
        }

        actions = {
            set_random_flag;
            reset_random_flag;
            NoAction;
        }

        size = 32;
        default_action = reset_random_flag;
        // const entries = {
        //     (true, 1) : set_random_flag();
        //     (false, 1) : NoAction();
        // }
    }

    Register<switch_ipfix_t, bit<16>>(ipfix_size, 1) check_sample_flag_reg;
    RegisterAction<switch_ipfix_t, bit<16>, bit<1>> (check_sample_flag_reg) set_random = {
        void apply(inout switch_ipfix_t reg, out bit<1> flag){
            reg = eg_md.ipfix.random_num;
            if (reg == 1) {
                flag = 1;
            } else {
                flag = 0;
            }
        }
    };
    RegisterAction<switch_ipfix_t, bit<16>, bit<1>> (check_sample_flag_reg) compare_random = {
        void apply(inout switch_ipfix_t reg, out bit<1> flag){
            if(reg == eg_md.ipfix.count) {
                flag = 1;
            } else {
                flag = 0;
            }
        }
    };

    action set_random_num(){
        eg_md.mirror.sample_flag = set_random.execute(eg_md.ipfix.flow_id);
    }

    action set_flag(){
        eg_md.mirror.sample_flag = compare_random.execute(eg_md.ipfix.flow_id);
    }

    action clear_sample_flag(){
        eg_md.mirror.sample_flag = 0;
    }

    table ipfix_set_sample_flag {
        key = {
            eg_md.ipfix.enable : exact;
            eg_md.ipfix.random_flag:exact;
        }

        actions = {
            set_random_num;
            set_flag;
            NoAction;
            clear_sample_flag;
        }

        size = 4;
        default_action = clear_sample_flag;
        const entries = {
            (true, 1) : set_random_num();
            (true, 0) : set_flag();
        }
    }

    action calc_random_num() {
        eg_md.ipfix.random_num = eg_md.ipfix.delta;
    }

    table ipfix_random_calc {
        key = {
            // eg_md.ipfix.enable : exact;
            eg_md.ipfix.delta : exact;
        }

        actions = {
            calc_random_num;
            NoAction;
        }

        size = 32;
        default_action = calc_random_num;
        // const entries = {
        //     (0) : NoAction();
        //     (1) : calc_random_num();
        //     // (false, 0) : NoAction();
        // }
    }

    apply {

        ipfix_sample_mode.apply();
        ipfix_modify_random.apply();
        ipfix_random_calc.apply();
        ipfix_packet_count.apply();
        ipfix_set_random_flag.apply();
        if (eg_md.common.is_mirror == 0) {
            ipfix_set_sample_flag.apply();
        }

    }
}

control CPU_port_mapping(inout switch_header_t hdr,
        inout switch_ingress_metadata_t ig_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm)(
        switch_uint32_t cpu_qos_mapping_table_size=32,
        switch_uint32_t cpu_port_mapping_table_size=512
        ) {

    action terminate_cpu_eth_packet() {
        ig_md.common.pkt_type = hdr.fabric_from_cpu_eth_base.pkt_type;
        ig_md.flags.escape_etm = hdr.fabric_from_cpu_eth_base.escape_etm;
        ig_md.common.track = hdr.fabric_from_cpu_eth_base.track;
        ig_md.common.iif_type = SWITCH_L3_IIF_TYPE;
        hdr.ethernet.ether_type = hdr.fabric_eth_etype.ether_type;
        hdr.fabric_from_cpu_eth_base.setInvalid();
        hdr.fabric_from_cpu_eth_data.setInvalid();
        hdr.fabric_eth_etype.setInvalid();
    }

    action set_cpu_qos(switch_tc_t tc, switch_pkt_color_t color) {
        ig_intr_md_for_tm.qid = (switch_qid_t)hdr.fabric_from_cpu_eth_base.qid;
        ig_md.qos.tc = tc;
        terminate_cpu_eth_packet();
    }

    table cpu_qos_map {
        key = {
            hdr.fabric_from_cpu_eth_base.qid: exact;
        }

        actions = {
            NoAction;
            set_cpu_qos;
        }

        const default_action = NoAction;
        size = cpu_qos_mapping_table_size;
    }

    action set_local_dev_port(switch_port_t dev_port) {
        // terminate_cpu_eth_packet();
        init_bridge_type(ig_md, BRIDGE_TYPE_FRONT_FRONT);
        ig_intr_md_for_tm.ucast_egress_port = dev_port;
        ig_md.common.dev_port = dev_port;
        // ig_md.common.pkt_type = FABRIC_PKT_TYPE_CPU_ETH;
    }

    action set_remote_dev_port(switch_port_t dev_port){
        // terminate_cpu_eth_packet();
        ig_intr_md_for_tm.ucast_egress_port = dev_port;
        ig_md.common.dev_port = dev_port;
        // ig_md.common.pkt_type = FABRIC_PKT_TYPE_CPU_ETH;
    }

    table cpu_eth_port_mapping {
        key = {
            ig_md.common.fwd_mode : exact;
            ig_md.common.dst_port : exact;
        }

        actions = {
            NoAction;
            set_local_dev_port;
            set_remote_dev_port;
        }

        size = cpu_port_mapping_table_size;
        default_action = NoAction;
    }

    apply {
        cpu_qos_map.apply();
        cpu_eth_port_mapping.apply();
    }
}
# 218 "/mnt/p4c-4127/p4src/switch-tofino2/switch_tofino_x1.p4" 2

# 1 "/mnt/p4c-4127/p4src/shared/route_eg_downlink.p4" 1
control L2EncapMapping(
        in switch_header_t hdr,
        in egress_intrinsic_metadata_t eg_intr_md,
        inout switch_egress_metadata_t eg_md,
        inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr) {

    action set_l3oif(switch_lif_t l3oif, bool l3oif_flag, bit<1> extend_fake, vlan_id_t vid) {
        eg_md.common.oif = l3oif_flag ? l3oif : eg_md.common.oif;
        eg_md.common.extend_fake = extend_fake;
        eg_md.tunnel.ptag_vid = vid;
    }

    @use_hash_action(1)
    table l2_encap_to_l3oif {
        key = {
            eg_md.common.l2_encap : exact @name("l2_encap");
        }
        actions = {
            set_l3oif;
        }
        const default_action = set_l3oif(0, false, 0, 0);
        size = L2_ENCAP_TABLE_SIZE;
    }

    Hash<bit<32>>(HashAlgorithm_t.IDENTITY) hash;
    const bit<32> vlan_membership_size = 1 << 19; //dst_port[6:0] + vid => 7 + 12 = 19
    Register<bit<1>, bit<32>>(vlan_membership_size, 0) vlan_untag_check;
    RegisterAction<bit<1>, bit<32>, bit<1>>(vlan_untag_check) check_vlan_untag_membership = {
        void apply(inout bit<1> val, out bit<1> rv) {
            rv = val;
        }
    };

    action del_fake() {
        eg_md.common.extend_fake = 0;
    }
    table del_fake_tag{
        /* keyless */
        actions = {
            del_fake;
        }
        default_action = del_fake();
    }

    action set_ttl(bit<8> ttl_thr) {
        //eg_md.route.ttl_check = ttl_thr |-| eg_md.lkp.ip_ttl;
        eg_md.route.ttl_check = ttl_thr |-| eg_md.tunnel.ttl;
    }
    @stage(3)
    table ipv4_ttl {
        key = {
            eg_md.common.oif : exact @name("oif");
        }

        actions = {
            set_ttl;
        }

        const default_action = set_ttl(0);
        size = L3IIF_TABLE_SIZE;
    }
    @stage(3)
    table ipv6_ttl {
        key = {
            eg_md.common.oif : exact @name("oif");
        }

        actions = {
            set_ttl;
        }

        const default_action = set_ttl(0);
        size = L3IIF_TABLE_SIZE;
    }

    action ttl_drop() {
        eg_md.common.drop_reason = SWITCH_DROP_REASON_MC_TTL_FAIL;
    }

    table ttl_thr_check {
        // keyless
        actions = {
            ttl_drop;
        }
        const default_action = ttl_drop;
    }

    apply {
        if (eg_md.common.l2_encap != 0) {
            l2_encap_to_l3oif.apply();
            if (check_vlan_untag_membership.execute(
                    hash.get({eg_md.common.dst_port[6:0], eg_md.tunnel.ptag_vid})) == 1) {
                del_fake_tag.apply();
            }
        }
        if (eg_md.common.is_mcast == 1) {
            if (hdr.inner_ipv4.isValid()) {
                ipv4_ttl.apply();
            } else if (hdr.inner_ipv6.isValid()) {
                ipv6_ttl.apply();
            }
        }
        if (eg_md.common.is_mcast == 1 && eg_md.route.ttl_check != 0) {
            ttl_thr_check.apply();
        }
    }
}

control RidAttribute(
        in egress_intrinsic_metadata_t eg_intr_md,
        inout switch_egress_metadata_t eg_md) {

    action set_rid_properties(bit<16> l4_encap, bit<16> l3_encap, bit<16> l2_encap,
                                      switch_lif_t l2oif, switch_eport_t egress_eport) {
        /* l3_encap = 0:L2 flood  other:L2VPN flood */
        eg_md.tunnel.l4_encap = l4_encap;//global encap id
        eg_md.common.l3_encap = l3_encap;
        eg_md.common.l2_encap = l2_encap;
        eg_md.common.oif = l2oif; //l2oif or l3oif
        eg_md.common.egress_eport = egress_eport;
        eg_md.common.dst_port = egress_eport[7 : 0];
    }

    @use_hash_action(1)
    @stage(0)
    table rid_attribute {
        key = {
            eg_intr_md.egress_rid[13:0] : exact @name("rid"); // l2oif or l3oif
        }
        actions = {
            set_rid_properties;
        }
        const default_action = set_rid_properties(0, 0, 0, 0, 0);
        size = RID_ATTRIBUTE_TABLE_SIZE;
    }

    apply {
        if (eg_md.common.is_mcast == 1) {
            rid_attribute.apply();
        }
    }
}
# 220 "/mnt/p4c-4127/p4src/switch-tofino2/switch_tofino_x1.p4" 2
# 1 "/mnt/p4c-4127/p4src/shared/route_ig_downlink.p4" 1
control SetEtherType(
    in switch_header_t hdr,
    inout switch_ingress_metadata_t ig_md) {

    action set_ipv4_ethertype() {
        ig_md.common.ether_type = 0x0800;
    }
    action set_ipv6_ethertype() {
        ig_md.common.ether_type = 0x86dd;
    }
    action set_mpls_ethertype() {
        ig_md.common.ether_type = 0x8847;
    }
    table set_ethertype {
        key = {
            hdr.fabric_base.pkt_type : exact;
            ig_md.tunnel.next_hdr_type : exact;
        }
        actions = {
            set_ipv4_ethertype;
            set_ipv6_ethertype;
            set_mpls_ethertype;
        }
        const entries = {
            (FABRIC_PKT_TYPE_IPV4, SWITCH_TUNNEL_NEXT_HDR_TYPE_NONE) : set_ipv4_ethertype();
            (FABRIC_PKT_TYPE_IPV6, SWITCH_TUNNEL_NEXT_HDR_TYPE_NONE) : set_ipv6_ethertype();
            (FABRIC_PKT_TYPE_MPLS, SWITCH_TUNNEL_NEXT_HDR_TYPE_NONE) : set_mpls_ethertype();

            (FABRIC_PKT_TYPE_ETH, SWITCH_TUNNEL_NEXT_HDR_TYPE_MPLS) : set_mpls_ethertype();
            (FABRIC_PKT_TYPE_IPV4, SWITCH_TUNNEL_NEXT_HDR_TYPE_MPLS) : set_mpls_ethertype();
            (FABRIC_PKT_TYPE_IPV6, SWITCH_TUNNEL_NEXT_HDR_TYPE_MPLS) : set_mpls_ethertype();
            (FABRIC_PKT_TYPE_MPLS, SWITCH_TUNNEL_NEXT_HDR_TYPE_MPLS) : set_mpls_ethertype();

            (FABRIC_PKT_TYPE_ETH, SWITCH_TUNNEL_NEXT_HDR_TYPE_IPV4) : set_ipv4_ethertype();
            (FABRIC_PKT_TYPE_ETH, SWITCH_TUNNEL_NEXT_HDR_TYPE_IPV6) : set_ipv6_ethertype();
        }
        size = 16;
    }
    apply {
        set_ethertype.apply();
    }
}

control LocalL2Encap(
        inout switch_header_t hdr,
        inout switch_ingress_metadata_t ig_md) {

    action l2_encap_add_with_vlan() {
        hdr.vlan_tag[0].setValid();
        hdr.vlan_tag[0].ether_type = ig_md.common.ether_type;
        hdr.vlan_tag[0].cfi = 0;
        hdr.vlan_tag[0].vid = ig_md.tunnel.ptag_vid;
        hdr.vlan_tag[0].pcp = ig_md.qos.pcp;
        hdr.ethernet.ether_type = 0x8100;
    }

    action l2_encap_add_ethernet_with_vlan() {
        hdr.ethernet.setValid();
        hdr.vlan_tag[0].setValid();
        hdr.vlan_tag[0].ether_type = ig_md.common.ether_type;
        hdr.vlan_tag[0].cfi = 0;
        hdr.vlan_tag[0].vid = ig_md.tunnel.ptag_vid;
        hdr.vlan_tag[0].pcp = ig_md.qos.pcp;
        hdr.ethernet.dst_addr = ig_md.route.ether_dstaddr;
        hdr.ethernet.ether_type = 0x8100;
    }

    action l2_encap_add_ethernet_without_vlan() {
        hdr.ethernet.setValid();
        hdr.ethernet.dst_addr = ig_md.route.ether_dstaddr;
        hdr.ethernet.ether_type = ig_md.common.ether_type;
    }

    action l2_encap_get_ptag() {

    }

    table l2_encap_action{
        key = {
            ig_md.route.type : exact;
        }
        actions = {
            NoAction;
            l2_encap_add_ethernet_with_vlan;
            l2_encap_add_ethernet_without_vlan;
            l2_encap_add_with_vlan;
            l2_encap_get_ptag;
        }
        const default_action = NoAction;
    }

    action l2_encap_common(bit<4> type, vlan_id_t vid, bit<48> dst_addr, switch_ptag_action_t p_action) {
        ig_md.route.type = type;
        ig_md.tunnel.ptag_vid = vid;
        ig_md.route.ether_dstaddr = dst_addr;
        ig_md.tunnel.ptag_eg_action = p_action;
    }

    @use_hash_action(1)
    table l2_encap{
        key = {
            ig_md.common.l2_encap : exact @name("l2_encap");
        }
        actions = {
            l2_encap_common;
        }
        const default_action = l2_encap_common(0, 0, 0, 0);
        size = L2_ENCAP_TABLE_SIZE;
    }

    action rewrite_smac_act(bit<48> src_addr, bool src_addr_flag, bit<16> evlan_id) {
        hdr.ethernet.setValid();
        hdr.ethernet.src_addr = src_addr_flag ? src_addr : hdr.ethernet.src_addr;
        ig_md.ebridge.evlan = evlan_id;
    }

    @use_hash_action(1)
    table rewrite_smac {
        key = {
            ig_md.common.oif : exact @name("oif");
        }
        actions = {
            rewrite_smac_act;
        }
        const default_action = rewrite_smac_act(0, false, 0);
        size = L3IIF_TABLE_SIZE;
    }

    action ethernet_init_act() {
        hdr.ethernet.src_addr = 48w0;
        hdr.ethernet.dst_addr = 48w0;
        hdr.ethernet.ether_type = 16w0;
    }

    table ethernet_init {
        key = {
            hdr.ethernet.isValid() : exact;
        }
        actions = {
            ethernet_init_act;
            NoAction;
        }
        // const entries = {
        //     (false) : ethernet_init_act();
        //     (true) : NoAction();
        // }
    }

    apply {
        if (ig_md.common.l2_encap != 0) {
            ethernet_init.apply();
        }
        if (ig_md.common.l2_encap != 0) {
            l2_encap.apply();
        }
        l2_encap_action.apply();
        if (ig_md.route.type != 0 && ig_md.route.type != 5) {
            rewrite_smac.apply();
        }
    }
}

control Multicast_Rewrite(
        inout switch_header_t hdr,
        inout switch_ingress_metadata_t ig_md){

    action rewrite_ipv4_multicast() {
        hdr.ethernet.setValid();
        hdr.ethernet.ether_type = 0x0800;
        hdr.ethernet.dst_addr[22:0] = hdr.ipv4.dst_addr[22:0];
        hdr.ethernet.dst_addr[23:23] = 1w0;
        hdr.ethernet.dst_addr[47:24] = 0x01005E;
    }

    action rewrite_ipv6_multicast() {
        hdr.ethernet.setValid();
        hdr.ethernet.ether_type = 0x86dd;
        hdr.ethernet.dst_addr[31:0] = hdr.ipv6.dst_addr[31:0];
        hdr.ethernet.dst_addr[47:32] = 16w0x3333;
    }

    table multicast_rewrite {
        key = {
            ig_md.common.pkt_type : exact;
            ig_md.common.is_mcast : exact;
        }
        actions = {
            rewrite_ipv4_multicast;
            rewrite_ipv6_multicast;
        }
        // const entries = {
        //     (FABRIC_PKT_TYPE_IPV4, 1) : rewrite_ipv4_multicast();
        //     (FABRIC_PKT_TYPE_IPV6, 1) : rewrite_ipv6_multicast();
        // }
    }
    apply{
        multicast_rewrite.apply();
    }
}

control EncapMiss(
        inout switch_header_t hdr,
        inout switch_ingress_metadata_t ig_md) {

    Counter<bit<32>, bit<6>>(64, CounterType_t.PACKETS) stats;

    apply {
        if (ig_md.common.l2_encap != 0 && ig_md.route.type == 0) {
            stats.count(ig_md.common.pkt_type);
        }
    }
}
# 221 "/mnt/p4c-4127/p4src/switch-tofino2/switch_tofino_x1.p4" 2
# 1 "/mnt/p4c-4127/p4src/shared/route_ig_front.p4" 1
control L3Mac(
        in switch_header_t hdr,
        inout switch_ingress_metadata_t ig_md) {

    action l3mac_hit() {
        ig_md.route.rmac_hit = 1w1;
    }
    action l3mac_miss() {
        ig_md.route.rmac_hit = 1w0;
    }

    @placement_priority(127)
    table gmac {
        key = {
            ig_md.route.g_l3mac_enable : exact @name("g_l3mac_enable");
            hdr.ethernet.dst_addr : exact @name("mac_dst_addr");
        }
        actions = {
            l3mac_hit;
            @defaultonly l3mac_miss;
        }
        const default_action = l3mac_miss;
    }

    @placement_priority(127)
    table l3mac_tcam {
        key = {
            ig_md.common.iif : ternary @name("iif");
            hdr.ethernet.dst_addr : ternary @name("mac_dst_addr");
        }
        actions = {
            l3mac_hit;
            @defaultonly l3mac_miss;
        }
        const default_action = l3mac_miss;
        size = VMAC_BACK_TABLE_SIZE;
    }

    @stage(3)
    table l3mac {
        key = {
            ig_md.common.iif : exact @name("iif");
            hdr.ethernet.dst_addr : exact @name("mac_dst_addr");
        }
        actions = {
            l3mac_hit;
            @defaultonly l3mac_miss;
        }
        const default_action = l3mac_miss;
        size = VMAC_TABLE_SIZE;
    }

    action set_iif() {
        ig_md.common.iif = ig_md.common.ul_iif;
        ig_md.common.iif_type = SWITCH_L2_IIF_TYPE;
        ig_md.common.svi_flag = 0;
    }
    table rewrite_lif{
        key = {
            ig_md.route.rmac_hit : exact;
            // ig_md.route.ipv4_unicast_enable     : exact;
            // ig_md.route.ipv6_unicast_enable     : exact;
            // hdr.ipv4.isValid()                  : exact;
            // hdr.ipv6.isValid()                  : exact;
        }
        actions = {
            set_iif;
            NoAction;
        }

        const default_action = set_iif();
        const entries = {
            // (1, true, false, true, false) : NoAction;
            // (1, true, true, true, false) : NoAction;
            // (1, false, true, false, true) : NoAction;
            // (1, true, true, false, true) : NoAction;
            (1) : NoAction;
        }
    }

    apply {
        if(ig_md.common.iif_type == SWITCH_L3_IIF_TYPE) {
            if(!l3mac.apply().hit) {
                if(!l3mac_tcam.apply().hit) {
                    gmac.apply();
                }
            }
        }

        if(ig_md.common.svi_flag == 1){
            rewrite_lif.apply();
        }
    }
}
# 222 "/mnt/p4c-4127/p4src/switch-tofino2/switch_tofino_x1.p4" 2
# 1 "/mnt/p4c-4127/p4src/shared/route_ig_uplink.p4" 1
control Nexthop(
        inout switch_header_t hdr,
        inout switch_ingress_metadata_t ig_md) {

    action set_overlay_nexthop_properties(
                                bit<6> type,
                                bit<16> g_l3_encap,
                                switch_lif_t l3oif,
                                bit<14> counter_index,
                                bit<16> encap_len) {
        ig_md.route.nexthop_type = type;
        ig_md.common.ol_nhid = g_l3_encap; // l3_encap reuse ol_nhid
        ig_md.route.l3_l3oif = l3oif;
        ig_md.common.pkt_length = ig_md.common.pkt_length + encap_len;
        ig_md.route.overlay_counter_index = counter_index;
    }

    @stage(2)
    @use_hash_action(1)
    table overlay_nexthop {
        key = {
            ig_md.common.ol_nhid : exact @name("nhid");
        }
        actions = {
            set_overlay_nexthop_properties;
        }
        const default_action = set_overlay_nexthop_properties(0,0,0,0,0);
        size = OVERLAY_NEXTHOP_TABLE_SIZE;
    }

    action set_underlay_nexthop_properties(
                                bit<6> type,
                                bit<2> cmd,
                                bit<16> dest,
                                bit<16> g_l2_encap_id,
                                switch_lif_t l3oif,
                                bool nh_flag
                                ) {
        ig_md.route.nexthop_type = type;
        ig_md.route.nexthop_cmd = cmd;
        ig_md.common.egress_eport = dest;
        ig_md.common.ul_nhid = nh_flag ? g_l2_encap_id : ig_md.common.ul_nhid; // l2_encap reuse ul_nhid
        ig_md.route.l2_l3oif = l3oif;
    }
    @stage(2)
    @use_hash_action(1)
    table underlay_nexthop {
        key = {
            ig_md.common.ul_nhid : exact @name("nhid");
        }
        actions = {
            set_underlay_nexthop_properties;
        }
        const default_action = set_underlay_nexthop_properties(0,0,0,0,0, false);
        size = UNDERLAY_NEXTHOP_TABLE_SIZE;
    }

    action set_l4_nexthop_properties(bit<16> l4_encap,
                                    bit<16> encap_len,
                                    switch_lif_t l3oif) {
        ig_md.route.l4_l3oif = l3oif;
        ig_md.common.pkt_length = ig_md.common.pkt_length + encap_len;
        hdr.ext_l4_encap.l4_encap = l4_encap;
    }
    @stage(5)
    @use_hash_action(1)
    table L4_nexthop {
        key = {
            hdr.ext_l4_encap.l4_encap : exact @name("nhid");
        }
        actions = {
            set_l4_nexthop_properties;
        }
        const default_action = set_l4_nexthop_properties(0,0,0);
        size = L4_NEXTHOP_TABLE_SIZE;
    }
    apply {
        if(ig_md.common.ul_nhid != 0) {
            underlay_nexthop.apply();
        }

        if(ig_md.common.ol_nhid != 0) {
            overlay_nexthop.apply();
        }

        if (hdr.fabric_base.is_mcast == 0 && hdr.ext_l4_encap.isValid()) {
            L4_nexthop.apply();
        }
    }
}

control FibMiss(
    in switch_header_t hdr,
    inout switch_ingress_metadata_t ig_md) {

    action fib_miss_cnt(switch_drop_reason_t drop_reason) {
        ig_md.common.drop_reason = drop_reason;
    }

    table fib_miss {
        key = {
            hdr.fabric_base.is_mcast : exact;
            hdr.fabric_base.pkt_type : exact;
        }

        actions = {
            fib_miss_cnt;
        }

        const entries = {
            (0, FABRIC_PKT_TYPE_IPV4) : fib_miss_cnt(SWITCH_DROP_REASON_IPV4_FIB_MISS);
            (0, FABRIC_PKT_TYPE_IPV6) : fib_miss_cnt(SWITCH_DROP_REASON_IPV6_FIB_MISS);
            (0, FABRIC_PKT_TYPE_ETH) : fib_miss_cnt(SWITCH_DROP_REASON_ETH_ULNH_ZERO);
            (0, FABRIC_PKT_TYPE_MPLS) : fib_miss_cnt(SWITCH_DROP_REASON_MPLS_ULNH_ZERO);
        }
    }

    apply {
        if (ig_md.common.ul_nhid == 0 && ig_md.route.dip_l3class_id == 0 && ig_md.flags.ul_bridge == 0) {
            fib_miss.apply();
        }
    }
}

control NhopMiss(
    in switch_header_t hdr,
    inout switch_ingress_metadata_t ig_md) {

    action nhop_miss_cnt(switch_drop_reason_t drop_reason) {
        ig_md.common.drop_reason = drop_reason;
    }

    table nhop_miss {
        key = {
            hdr.fabric_base.is_mcast : exact;
            hdr.fabric_base.pkt_type : exact;
        }

        actions = {
            nhop_miss_cnt;
        }

        const entries = {
            (0, FABRIC_PKT_TYPE_IPV4) : nhop_miss_cnt(SWITCH_DROP_REASON_IPV4_NEXTHOP_MISS);
            (0, FABRIC_PKT_TYPE_IPV6) : nhop_miss_cnt(SWITCH_DROP_REASON_IPV6_NEXTHOP_MISS);
            (0, FABRIC_PKT_TYPE_ETH) : nhop_miss_cnt(SWITCH_DROP_REASON_ETH_ULNH_MISS);
            (0, FABRIC_PKT_TYPE_MPLS) : nhop_miss_cnt(SWITCH_DROP_REASON_MPLS_ULNH_MISS);
        }
    }

    apply {
        if (ig_md.common.ul_nhid != 0 && ig_md.route.nexthop_cmd == 0) {
            nhop_miss.apply();
        }
    }
}

control RouteCause(
    inout switch_header_t hdr,
    inout switch_ingress_metadata_t ig_md) {

    Counter<bit<32>, bit<8>>(256, CounterType_t.PACKETS) urpf_counter;

    action urpf_cnt(switch_drop_reason_t drop_reason) {
        ig_md.common.drop_reason = drop_reason;
        urpf_counter.count(hdr.fabric_crsp.src_port);
    }
    action mtu_cnt(switch_drop_reason_t drop_reason) {
        ig_md.common.drop_reason = drop_reason;
    }
    action mtu_cnt_trap(switch_drop_reason_t drop_reason) {
        ig_md.common.drop_reason = drop_reason;
        ig_md.flags.drop = 1;
        ig_md.flags.glean = 1;
        hdr.fabric_crsp.cpu_reason = SWITCH_CPU_REASON_MTU;
    }

    table forward_drop {
        key = {
            hdr.fabric_base.pkt_type : exact;
            ig_md.flags.fwd_fail : exact;
            ig_md.common.hash[7:0] : exact;
            ig_md.flags.glean : exact;
        }

        actions = {
            urpf_cnt;
            mtu_cnt;
            mtu_cnt_trap;
        }

        const entries = {
            (FABRIC_PKT_TYPE_IPV4, 1, 1, 0) : urpf_cnt(SWITCH_DROP_REASON_URPF_CHECK_FAIL);
            (FABRIC_PKT_TYPE_IPV6, 1, 1, 0) : urpf_cnt(SWITCH_DROP_REASON_URPF_CHECK_FAIL);
            (FABRIC_PKT_TYPE_IPV4, 1, 2, 0) : mtu_cnt_trap(SWITCH_DROP_REASON_MTU_CHECK_FAIL);
            (FABRIC_PKT_TYPE_IPV6, 1, 2, 0) : mtu_cnt_trap(SWITCH_DROP_REASON_MTU_CHECK_FAIL);
            (FABRIC_PKT_TYPE_IPV4, 1, 1, 1) : urpf_cnt(SWITCH_DROP_REASON_URPF_CHECK_FAIL);
            (FABRIC_PKT_TYPE_IPV6, 1, 1, 1) : urpf_cnt(SWITCH_DROP_REASON_URPF_CHECK_FAIL);
            (FABRIC_PKT_TYPE_IPV4, 1, 2, 1) : mtu_cnt(SWITCH_DROP_REASON_MTU_CHECK_FAIL);
            (FABRIC_PKT_TYPE_IPV6, 1, 2, 1) : mtu_cnt(SWITCH_DROP_REASON_MTU_CHECK_FAIL);
        }
    }

    apply {
        if (hdr.fabric_base.is_mcast == 0) {
            forward_drop.apply();
        }
    }
}
# 223 "/mnt/p4c-4127/p4src/switch-tofino2/switch_tofino_x1.p4" 2
# 1 "/mnt/p4c-4127/p4src/shared/route_eg_uplink.p4" 1
control L3Properties(
        inout switch_header_t hdr,
        inout switch_egress_metadata_t eg_md){

    action set_l3iif_properties(bit<13> vrf,
                                bit<8> classid,
                                bool ipv4_unicast_enable,
                                bool ipv6_unicast_enable,
                                bool ipv4_multicast_enable,
                                bool ipv6_multicast_enable) {
        eg_md.route.vrf = vrf;
        eg_md.common.iif_classid = classid;
        eg_md.route.ipv4_unicast_enable = ipv4_unicast_enable;
        eg_md.route.ipv6_unicast_enable = ipv6_unicast_enable;
        eg_md.multicast.ipv4.multicast_enable = ipv4_multicast_enable;
        eg_md.multicast.ipv6.multicast_enable = ipv6_multicast_enable;
    }

    /* 三层口属性表 */
    @use_hash_action(1)
    table l3iif {
        key = {
            eg_md.common.iif : exact @name("iif");
        }
        actions = {
            set_l3iif_properties;
        }
        const default_action = set_l3iif_properties(0, 0, false, false, false, false);
        size = L3IIF_TABLE_SIZE;
    }

    apply {
        if(eg_md.common.iif_type == SWITCH_L3_IIF_TYPE) {
            l3iif.apply();
        }
    }
}

control BFNFib(
        in switch_header_t hdr,
        inout switch_egress_metadata_t eg_md) {

    action fib_miss() {

    }

    action fib_hit(
            bit<16> nexthop,
            bit<1> is_ecmp,
            bit<2> level,
            bit<8> priority,
            bit<8> dip_l3class_id){
        eg_md.common.nexthop = nexthop;
        eg_md.route.is_ecmp = is_ecmp;
        eg_md.route.level = level;
        eg_md.route.dip_l3class_id = dip_l3class_id;
        eg_md.route.priority = priority;
        eg_md.route.priority_check = priority |-| eg_md.route.pbr_priority;
    }

    @ignore_table_dependency("Eg_uplink.fib.ipv6_local")
    @ignore_table_dependency("Eg_uplink.fib.ipv6_lpm_back")
    @ignore_table_dependency("Eg_uplink.dl2port.d_l2port")
    table ipv4_lpm_back {
        key = {
            eg_md.route.vrf : exact @name("vrf");
            hdr.ipv4.dst_addr : lpm @name("ip_dst_addr");
        }
        actions = {
            @defaultonly fib_miss;
            fib_hit;
        }
        const default_action = fib_miss;
        size = IPV4_LPM_TABLE_SIZE;
    }

    @ignore_table_dependency("Eg_uplink.fib.ipv4_local")
    @ignore_table_dependency("Eg_uplink.fib.ipv6_lpm_back")
    @ignore_table_dependency("Eg_uplink.dl2port.d_l2port")
    table ipv4_local {
        key = {
            eg_md.route.vrf : exact @name("vrf");
            hdr.ipv4.dst_addr : exact @name("ip_dst_addr");
        }
        actions = {
            @defaultonly fib_miss;
            fib_hit;
        }
        const default_action = fib_miss;
        size = IPV4_HOST_TABLE_SIZE;
    }


    @ignore_table_dependency("Eg_uplink.fib.ipv4_local")
    @ignore_table_dependency("Eg_uplink.fib.ipv4_lpm_back")
    @ignore_table_dependency("Eg_uplink.dl2port.d_l2port")
    table ipv6_local {
        key = {
            eg_md.route.vrf : exact @name("vrf");
            hdr.ipv6.dst_addr : exact @name("ip_dst_addr");
        }
        actions = {
            @defaultonly fib_miss;
            fib_hit;
        }
        const default_action = fib_miss;
        size = IPV6_HOST_TABLE_SIZE;
    }

    /* ipv6[65-128] lpm */
    @ignore_table_dependency("Eg_uplink.fib.ipv4_local")
    @ignore_table_dependency("Eg_uplink.fib.ipv4_lpm_back")
    @ignore_table_dependency("Eg_uplink.dl2port.d_l2port")
    table ipv6_lpm_back {
        key = {
            eg_md.route.vrf : exact @name("vrf");
            hdr.ipv6.dst_addr : lpm @name("ip_dst_addr");
        }
        actions = {
            @defaultonly fib_miss;
            fib_hit;
        }
        const default_action = fib_miss;
        size = IPV6_LPM_TABLE_SIZE;
    }


    action set_nexthop() {
        eg_md.common.nexthop = hdr.ext_srv6.nexthop;
        eg_md.route.is_ecmp = hdr.ext_srv6.is_ecmp;
        eg_md.route.level = hdr.ext_srv6.level;
        eg_md.route.priority = hdr.ext_srv6.priority;
        eg_md.route.priority_check = hdr.ext_srv6.priority |-| eg_md.route.pbr_priority;
    }

    @ignore_table_dependency("Eg_uplink.dl2port.d_l2port")
    table l3_bypass {
        // keyless
        actions = {
            set_nexthop;
        }
        const default_action = set_nexthop;
    }

    action check_fail(switch_drop_reason_t drop_reason) {
        eg_md.common.drop_reason = drop_reason;
    }

    table ip_enable_check {
        key = {
            eg_md.qos.car_flag : exact;
            eg_md.route.rmac_hit : exact;
            eg_md.route.ipv4_unicast_enable : exact;
            eg_md.route.ipv6_unicast_enable : exact;
            hdr.ipv4.isValid() : exact;
            hdr.ipv6.isValid() : exact;
            hdr.mpls_ig[0].isValid() : exact;
        }
        actions = {
            NoAction;
            check_fail;
        }
        const entries = {
            (0, 1, false, true, true, false, false) : check_fail(SWITCH_DROP_REASON_IPV4_UNICAST_DISABLE);
            (0, 1, false, false, true, false, false) : check_fail(SWITCH_DROP_REASON_IPV4_UNICAST_DISABLE);
            (0, 1, true, false, false, true, false) : check_fail(SWITCH_DROP_REASON_IPV6_UNICAST_DISABLE);
            (0, 1, false, false, false, true, false) : check_fail(SWITCH_DROP_REASON_IPV6_UNICAST_DISABLE);
            (0, 0, true, true, true, false, false) : check_fail(SWITCH_DROP_REASON_RMAC_NOT_HIT);
            (0, 0, true, false, true, false, false) : check_fail(SWITCH_DROP_REASON_RMAC_NOT_HIT);
            (0, 0, false, true, true, false, false) : check_fail(SWITCH_DROP_REASON_RMAC_NOT_HIT);
            (0, 0, false, false, true, false, false) : check_fail(SWITCH_DROP_REASON_RMAC_NOT_HIT);
            (0, 0, true, true, false, true, false) : check_fail(SWITCH_DROP_REASON_RMAC_NOT_HIT);
            (0, 0, false, true, false, true, false) : check_fail(SWITCH_DROP_REASON_RMAC_NOT_HIT);
            (0, 0, true, false, false, true, false) : check_fail(SWITCH_DROP_REASON_RMAC_NOT_HIT);
            (0, 0, false, false, false, true, false) : check_fail(SWITCH_DROP_REASON_RMAC_NOT_HIT);

            (0, 0, false, false, false, false, false) : check_fail(SWITCH_DROP_REASON_L3_NO_IP);
            (0, 0, false, true, false, false, false) : check_fail(SWITCH_DROP_REASON_L3_NO_IP);
            (0, 0, true, false, false, false, false) : check_fail(SWITCH_DROP_REASON_L3_NO_IP);
            (0, 0, true, true, false, false, false) : check_fail(SWITCH_DROP_REASON_L3_NO_IP);
            (0, 1, false, false, false, false, false) : check_fail(SWITCH_DROP_REASON_L3_NO_IP);
            (0, 1, false, true, false, false, false) : check_fail(SWITCH_DROP_REASON_L3_NO_IP);
            (0, 1, true, false, false, false, false) : check_fail(SWITCH_DROP_REASON_L3_NO_IP);
            (0, 1, true, true, false, false, false) : check_fail(SWITCH_DROP_REASON_L3_NO_IP);
        }
    }


    apply {

        if (hdr.ext_srv6.isValid() && hdr.ext_srv6.bypass_L3 == true) {
            l3_bypass.apply();
        } else {

            if(eg_md.common.iif_type == SWITCH_L3_IIF_TYPE && eg_md.lkp.pkt_type != FABRIC_PKT_TYPE_MCAST) {
                ip_enable_check.apply();
            }
            if(hdr.ipv4.isValid() && eg_md.route.ipv4_unicast_enable == true && eg_md.route.rmac_hit == 1w1) {
                if(!ipv4_local.apply().hit){
                    ipv4_lpm_back.apply();
                }
            }

            if (hdr.ipv6.isValid() && eg_md.route.ipv6_unicast_enable == true && eg_md.route.rmac_hit == 1w1) {
                if(!ipv6_local.apply().hit){
                    ipv6_lpm_back.apply();
                }
            }


        }

    }
}

control SIPFib(
    in switch_header_t hdr,
    inout switch_egress_metadata_t eg_md) {

    action sip_fib_miss() {
        eg_md.route.disable_urpf = 0;
    }
    action sip_fib_hit() {
        eg_md.route.disable_urpf = 1;
    }

    @ignore_table_dependency("Eg_uplink.sip_fib.ipv6_sip_lpm")
    table ipv4_sip_lpm {
        key = {
            eg_md.route.vrf : exact @name("vrf");
            hdr.ipv4.src_addr : lpm @name("ip_src_addr");
        }
        actions = {
            sip_fib_miss;
            sip_fib_hit;
        }
        const default_action = sip_fib_miss;
        size = IPV4_SIP_LPM_TABLE_SIZE;
    }

    @ignore_table_dependency("Eg_uplink.sip_fib.ipv4_sip_lpm")
    table ipv6_sip_lpm {
        key = {
            eg_md.route.vrf : exact @name("vrf");
            hdr.ipv6.src_addr : lpm @name("ip_src_addr");
        }
        actions = {
            sip_fib_miss;
            sip_fib_hit;
        }
        const default_action = sip_fib_miss;
        size = IPV6_SIP_LPM_TABLE_SIZE;
    }

    apply {
        if(hdr.ipv4.isValid() && eg_md.route.ipv4_unicast_enable == true) {
            ipv4_sip_lpm.apply();
        }

        if (hdr.ipv6.isValid() && eg_md.route.ipv6_unicast_enable == true) {
            ipv6_sip_lpm.apply();
        }

    }
}

control PRICheck(in switch_header_t hdr,
        inout switch_egress_metadata_t eg_md) {

    action set_common() {
        eg_md.common.nexthop = eg_md.route.pbr_nexthop;
        eg_md.route.is_ecmp = eg_md.route.pbr_is_ecmp;
        eg_md.route.level = eg_md.route.pbr_level;
        eg_md.route.priority = eg_md.route.pbr_priority;
        eg_md.flags.is_pbr_nhop = 1;
    }

    @placement_priority(127)
    table priority_check {
        key = {
            eg_md.route.priority_check : exact;
        }
        actions = {
            NoAction;
            set_common;
        }
        const default_action = NoAction;
        const entries = {
            (0) : set_common();
        }
        size = 4;
    }

    apply {
        if(eg_md.route.ipv4_unicast_enable == true || eg_md.route.ipv6_unicast_enable == true) {
            priority_check.apply();
        }
    }
}

control McEnable(
        inout switch_header_t hdr,
        inout switch_egress_metadata_t eg_md){

    action enable_act() {
        eg_md.common.is_mcast = 1;
    }

    action disable_act(switch_drop_reason_t drop_reason) {
        eg_md.common.is_mcast = 1;
        eg_md.common.drop_reason = drop_reason;
    }

    table Mc_enable {
        key = {
            eg_md.qos.car_flag : exact;
            eg_md.multicast.ipv6.multicast_enable : exact;
            eg_md.multicast.ipv4.multicast_enable : exact;
            hdr.ipv4.isValid() : exact;
            hdr.ipv6.isValid() : exact;
        }
        actions = {
            NoAction;
            enable_act;
            disable_act;
        }
        const entries = {
            (0, true, true, true, false) : enable_act();
            (0, true, false, true, false) : disable_act(SWITCH_DROP_REASON_IPV4_MULITCSAT_DISABLE);
            (0, false, true, true, false) : enable_act();
            (0, false, false, true, false) : disable_act(SWITCH_DROP_REASON_IPV4_MULITCSAT_DISABLE);
            (0, true, true, false, true) : enable_act();
            (0, true, false, false, true) : enable_act();
            (0, false, true, false, true) : disable_act(SWITCH_DROP_REASON_IPV6_MULITCSAT_DISABLE);
            (0, false, false, false, true) : disable_act(SWITCH_DROP_REASON_IPV6_MULITCSAT_DISABLE);
        }
    }
    apply{
        if (eg_md.common.iif_type == SWITCH_L3_IIF_TYPE && eg_md.lkp.pkt_type == FABRIC_PKT_TYPE_MCAST) {
            Mc_enable.apply();
        }
    }
}
# 224 "/mnt/p4c-4127/p4src/switch-tofino2/switch_tofino_x1.p4" 2
# 1 "/mnt/p4c-4127/p4src/shared/route_ig_fabric.p4" 1
control L2EncapMapping_Fabric(
        in switch_header_t hdr,
        inout switch_ingress_metadata_t ig_md) {

    action set_l3oif(switch_lif_t l3oif, bool l3oif_flag) {
        ig_md.common.oif = l3oif_flag ? l3oif : ig_md.common.oif;
    }
    @use_hash_action(1)
    table l2_encap_to_l3oif {
        key = {
            ig_md.common.l2_encap : exact @name("l2_encap");
        }
        actions = {
            set_l3oif;
        }
        const default_action = set_l3oif(0, false);
        size = L2_ENCAP_TABLE_SIZE;
    }

    apply {
        if (ig_md.common.l2_encap != 0) {
            l2_encap_to_l3oif.apply();
        }
    }
}

control mgid_copy_to_tm(
        inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm,
        inout switch_ingress_metadata_t ig_md){

    action mgid_copy_tm() {
        ig_intr_md_for_tm.mcast_grp_b = ig_md.multicast.id;
        ig_intr_md_for_tm.level1_exclusion_id = (bit<16>)ig_md.common.iif;
        ig_intr_md_for_tm.level2_mcast_hash = ig_md.common.hash[15:3];
    }

    table mgid_copy {
        // keyless
        actions = {
            mgid_copy_tm;
        }
        const default_action = mgid_copy_tm;
    }

    apply{
        mgid_copy.apply();
    }
}

control MulticastTC(
        inout switch_header_t hdr,
        inout switch_ingress_metadata_t ig_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm){

    action set_tc(bit<9> dev_port, switch_qid_t qid, bool flag, bit<1> flag_2) {
        ig_intr_md_for_tm.ucast_egress_port = dev_port;
        ig_intr_md_for_tm.qid = flag ? qid : ig_intr_md_for_tm.qid;
        ig_intr_md_for_tm.mcast_grp_b = flag ? 0 : ig_intr_md_for_tm.mcast_grp_b;
        ig_intr_md_for_tm.bypass_egress = flag_2 | ig_intr_md_for_tm.bypass_egress;
    }
    @use_hash_action(1)
    table multicast_tc {
        key = {
            ig_md.multicast.id[14:0] : exact @name("mgid");
        }
        actions = {
            set_tc;
        }

        const default_action = set_tc(511, 0, false, 0);
        size = MULTICAST_GROUP_SIZE;
    }
    apply{
        if (ig_md.ebridge.evlan == 0) {
            multicast_tc.apply();
        }
    }
}
# 225 "/mnt/p4c-4127/p4src/switch-tofino2/switch_tofino_x1.p4" 2
# 1 "/mnt/p4c-4127/p4src/shared/route_eg_fabric.p4" 1
control TTL_rewrite(
        inout switch_header_t hdr,
        inout switch_egress_metadata_t eg_md){

    action ipv6_rewrite() {
        hdr.ipv6.hop_limit = hdr.ipv6.hop_limit |-| eg_md.common.dec_ttl;
    }
    action ipv6_rewrite_vxlan() {
        hdr.ipv6.hop_limit = hdr.ipv6.hop_limit |-| eg_md.common.dec_ttl;
        hdr.ethernet.ether_type = 0x86dd;
    }

    action ipv4_rewrite() {
        hdr.ipv4.ttl = hdr.ipv4.ttl |-| eg_md.common.dec_ttl;
    }
    action ipv4_rewrite_vxlan() {
        hdr.ipv4.ttl = hdr.ipv4.ttl |-| eg_md.common.dec_ttl;
        hdr.ethernet.ether_type = 0x0800;
    }

    action mpls0_rewrite() {
        hdr.mpls_ig[0].ttl = hdr.mpls_ig[0].ttl |-| eg_md.common.dec_ttl;
    }

    table rewrite_ttl {
        key = {
            hdr.ipv4.isValid() : exact;
            hdr.ipv6.isValid() : exact;
            hdr.mpls_ig[0].isValid() : exact;
            eg_md.tunnel.vxlan_l4_encap_flag : exact;
        }
        actions = {
            ipv4_rewrite;
            ipv6_rewrite;
            mpls0_rewrite;
            ipv4_rewrite_vxlan;
            ipv6_rewrite_vxlan;
            NoAction;
        }
        const entries = {
            (true, false, false, false) : ipv4_rewrite();
            (false, true, false, false) : ipv6_rewrite();
            (false, false, true, false) : mpls0_rewrite();
            (true, false, false, true) : ipv4_rewrite_vxlan();
            (false, true, false, true) : ipv6_rewrite_vxlan();
        }
        size = 16;
    }
    apply{
        rewrite_ttl.apply();
    }
}

control OverlayCounter(inout switch_egress_metadata_t eg_md){
    Counter<bit<64>,bit<14>>(OVERLAY_COUNTER_TABLE_SIZE, CounterType_t.PACKETS_AND_BYTES) overlay_counter;

    action ol_count() {
        overlay_counter.count(eg_md.route.overlay_counter_index);
    }
    @stage(11)
    table overlay_cnt {
        actions = {
            ol_count;
        }
        default_action = ol_count();
    }

    apply {
        if(eg_md.route.overlay_counter_index != 0) {
            overlay_cnt.apply();
        }
    }
}
# 226 "/mnt/p4c-4127/p4src/switch-tofino2/switch_tofino_x1.p4" 2

/* xiachangkai */
# 1 "/mnt/p4c-4127/p4src/shared/l2_mac_uplink.p4" 1
/* mac by xiachangkai */
/* pipline 2 */
//-----------------------------------------------------------------------------
// Source MAC lookup
//
// @param src_addr : Source MAC address.
// @param eg_md : egress metadata
// @param table_size : Size of SMAC table.
//
// MAC learning
// - Trigger a new MAC learn if MAC address is unknown.
// - Trigger a new MAC learn if MAC address is known but attached to a different interface.
//-----------------------------------------------------------------------------
control GLB_LEARN(inout switch_egress_metadata_t eg_md) {
    action is_learn_execute(bit<1> enable) {
        eg_md.flags.glb_learning = enable;
    }

    table execute_learning {
        actions = {
            is_learn_execute;
        }

        size = 1;
    }

    apply{
        execute_learning.apply();
    }
}

control SMAC(inout switch_header_t hdr,
            inout switch_egress_metadata_t eg_md,
            inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr)
            (switch_uint32_t sram_table_size=81920, switch_uint32_t tcam_table_size=512) {
    // local variables for MAC learning
    bool src_miss;
    switch_lif_t src_move;
    bit<1> learn_flag;

    action smac_miss() {
        src_miss = true;
        src_move = 0;
    }

    action smac_hit(switch_lif_t slif, bit<1> is_static) {
        src_move = eg_md.common.learn_iif ^ slif;
        src_miss = false;
        eg_md.flags.is_mac_static = is_static;
    }
    @stage(1)
    table smac {
        key = {
            eg_md.ebridge.evlan : exact;
            hdr.ethernet.src_addr : exact;
        }

        actions = {
            @defaultonly NoAction;
            smac_hit;
        }

        const default_action = NoAction;
        size = sram_table_size;
        idle_timeout = true;
    }

    table back_smac {
        key = {
            eg_md.ebridge.evlan : ternary;
            hdr.ethernet.src_addr : ternary;
        }

        actions = {
            @defaultonly smac_miss;
            smac_hit;
        }

        const default_action = smac_miss;
        size = tcam_table_size;
        idle_timeout = true;
    }

    Meter<bit<16>>(1, MeterType_t.PACKETS) meter;

    action learn_mirror_disable() {
        eg_md.flags.learning = 0;
    }
    action learn_meter() {
        eg_md.mirror.color = (bit<2>) meter.execute(0);
        eg_md.flags.learning = 1;
    }
    action drop() {
        eg_md.flags.learning = 0;
        eg_md.flags.static_mac_move_drop = 1;//复用
    }

    table learning {
        key = {
            src_miss : exact;
            src_move : ternary;
            eg_md.flags.is_mac_static : exact;
        }
        actions = {
            learn_mirror_disable;
            learn_meter;
            drop;
        }
        const default_action = learn_mirror_disable;
    }

    action set_mirror(switch_mirror_session_t sess_id) {
        eg_intr_md_for_dprsr.mirror_type = (MirrorType_t) 1;

        eg_intr_md_for_dprsr.mirror_io_select = 1; // E2E mirroring for Tofino2 & future ASICs

        eg_md.mirror.type = 13;
        eg_md.mirror.src = SWITCH_PKT_SRC_CLONED_EGRESS;
        eg_md.mirror.session_id = sess_id;
        eg_md.flags.glb_learning = 1;
    }

    action no_mirror() {
        eg_md.flags.glb_learning = 0;
    }

    table learning_mirror {
        key = {
            eg_md.flags.learning : exact;
            eg_md.mirror.color : exact;
        }
        actions = {
            set_mirror;
            no_mirror;
        }
        const default_action = no_mirror;
        size = 2;
    }

    action get_learn(bit<1> learn){
        learn_flag = learn;
    }

    action get_learn_drop(bit<1> learn, bit<8> drop_reason){
        learn_flag = learn;
        eg_md.common.drop_reason = drop_reason;
    }

    table learn_decide{
        key = {
            eg_md.flags.learning : exact;
            eg_md.flags.learn_en_evlan : exact;
            src_miss : exact;
            eg_md.qos.car_flag : exact;
        }
        actions = {
            get_learn_drop;
            get_learn;
            NoAction;
        }

        const default_action = NoAction;
        size = 1024;
    }

    apply {
        if(!smac.apply().hit){
            back_smac.apply();
        }

        learn_decide.apply();

        if (learn_flag == 1 && eg_md.flags.glb_learning == 1 && eg_md.stp.state != SWITCH_STP_STATE_BLOCKING) {

            learning.apply();
            learning_mirror.apply();
        }

    }
}

//-----------------------------------------------------------------------------
// Destination MAC lookup
//
// Performs a lookup on evlan and destination MAC address.
// - Bridge out the packet of the interface in the MAC entry.
// - Flood the packet out of all ports within the ingress evlan.
//
// @param dst_addr : destination MAC address.
// @param eg_md : egess metadata
// @param ig_intr_md_for_tm
// @param table_size : Size of the dmac table.
//-----------------------------------------------------------------------------

control DMAC(inout switch_header_t hdr,
             inout switch_egress_metadata_t eg_md)(
             switch_uint32_t sram_table_size=81920,
             switch_uint32_t tcam_table_size=512) {

    // DirectRegister<bit<1>>() dmac_reg_dir;
    // DirectRegisterAction<bit<1>, bit<1>>(dmac_reg_dir) dmac_reg_dir_action = {
    //     void apply(inout bit<1> val){
    //         val = 1;
    //     }
    // };

    // DirectRegister<bit<1>>() back_dmac_reg_dir;
    // DirectRegisterAction<bit<1>, bit<1>>(back_dmac_reg_dir) back_dmac_reg_dir_action = {
    //     void apply(inout bit<1> val){
    //         val = 1;
    //     }
    // };

    action dmac_miss() {
        // eg_md.common.is_mcast = 1;
        eg_md.ebridge.l2oif = SWITCH_FLOOD;
        eg_md.flags.dmac_miss = 0b1;
        // eg_md.flags.dmac_miss = true;
    }

    action black_hole_dmac_hit() {
        eg_md.flags.bh_dmac_hit = 0b1;
        // dmac_reg_dir_action.execute();
    }

    action dmac_hit(switch_lif_t dlif) {
        eg_md.ebridge.l2oif = dlif;
        eg_md.ebridge.checks.same_if = eg_md.common.iif ^ dlif;
        // dmac_reg_dir_action.execute();
    }

    @stage(3)
    // @placement_priority(-1)
    table dmac {
        key = {
            eg_md.ebridge.evlan : exact;
            hdr.ethernet.dst_addr : exact;
        }

        actions = {
            dmac_hit;
            black_hole_dmac_hit;
            @defaultonly NoAction;
        }

        const default_action = NoAction;
        size = sram_table_size;
        // registers = dmac_reg_dir;
    }

    table back_dmac {
        key = {
            eg_md.ebridge.evlan : ternary;
            hdr.ethernet.dst_addr : ternary;
        }

        actions = {
            dmac_hit;
            black_hole_dmac_hit;
            @defaultonly dmac_miss;
        }

        const default_action = dmac_miss;
        size = tcam_table_size;
        // registers = back_dmac_reg_dir;
    }

    apply {
        if(!dmac.apply().hit){
            back_dmac.apply();
        }
    }
}

control EvlanProcess(
        inout switch_header_t hdr,
        inout switch_egress_metadata_t eg_md)(
        switch_uint32_t evlan_attr_table_size = 8192,
        switch_uint32_t evlan_rmac_size = 512){

    switch_lif_t swap = 0;
    action set_evlan_properties(bit<2> ln_md, switch_lif_t l3iif,
            switch_evlan_classid_t evlan_classid, bool anycast_en, switch_tunnel_type_t evlan_type) {
      // eg_md.flags.learning = eg_md.flags.learning & ln_md;
        eg_md.flags.learn_en_evlan = ln_md;
        eg_md.tunnel.tmp_l3iif = l3iif;
        eg_md.ebridge.evlan_classid = evlan_classid;
        eg_md.ebridge.anycast_en = anycast_en;
        eg_md.tunnel.evlan_type = evlan_type;
        // eg_md.ebridge.evlan[15:15] = 0;
    }

    @stage(0)
    @use_hash_action(1)
    table evlan_attr {
        key = {
            eg_md.ebridge.evlan[12:0] : exact;
        }
        actions = {
            set_evlan_properties;
        }
        const default_action = set_evlan_properties(0, 0, 0, false, 0);
        size = evlan_attr_table_size;
    }

    action rmac_hit() {
        eg_md.route.rmac_hit = 1w1;
        swap = eg_md.common.iif;
        eg_md.common.iif = eg_md.tunnel.tmp_l3iif;
        eg_md.tunnel.tmp_l3iif = swap;
        eg_md.tunnel.evlan_rmac_hit = 1;
        eg_md.common.iif_type = SWITCH_L3_IIF_TYPE;
    }

    @stage(1)
    table evlan_rmac {
        key = {
            eg_md.ebridge.anycast_en : ternary;
            hdr.ethernet.dst_addr : ternary;
        }
        actions = {
            rmac_hit;
            NoAction;
        }
        const default_action = NoAction;
        size = evlan_rmac_size;
    }

    apply {
        evlan_attr.apply();
        if(eg_md.tunnel.tmp_l3iif != 0) {
            evlan_rmac.apply();
        }
    }
}

control ARP_ND_Exchange_Lif(
        inout switch_header_t hdr,
        inout switch_egress_metadata_t eg_md)(
        switch_uint32_t exchange_lif_size = 16){

    switch_lif_t swap = 0;

    action set_ext_tunnel_decap() {
        eg_md.common.extend = 1w1;
        eg_md.common.ext_len = 1;
        hdr.ext_tunnel_decap.setValid();
        hdr.ext_tunnel_decap.ext_type = FABRIC_EXT_TYPE_TUNNEL_DECAP;
        hdr.ext_tunnel_decap.extend = 0;
        hdr.ext_tunnel_decap.tunnel_type = eg_md.tunnel.evlan_type;
        hdr.ext_tunnel_decap.data_type = SWITCH_TUNNEL_DECAP_TYPE_OR;
        hdr.ext_tunnel_decap.ul_iif = eg_md.tunnel.tmp_l3iif;
    }

    action swap_lif_back() {
        swap = eg_md.common.iif; // OR
        eg_md.common.iif = eg_md.tunnel.tmp_l3iif;
        eg_md.tunnel.tmp_l3iif = swap;
        // eg_md.common.iif_type = SWITCH_L2_IIF_TYPE; // todo
        // eg_md.common.nexthop = 0;
        eg_md.flags.drop = 1;
    }

    action swap_svi_lif_back() {
        eg_md.common.iif = eg_md.common.ul_iif;
        eg_md.flags.drop = 1;
    }

    table exchange_lif {
        key = {
            // eg_md.tunnel.evlan_rmac_hit : exact;
            hdr.ext_tunnel_decap.isValid() : exact;
            eg_md.lkp.ip_type : exact;
            eg_md.flags.nd_flag : exact;
            eg_md.common.svi_flag :exact;
        }
        actions = {
            swap_lif_back;
            NoAction;
            set_ext_tunnel_decap;
            swap_svi_lif_back;
        }
        const entries = {
            (false, SWITCH_IP_TYPE_NONE, 0, 0) : swap_lif_back();//  VXLAN AC l3 arp閹躲儲鏋冩惔鏃傜摕 缁楋拷10鐞涳拷
            (false, SWITCH_IP_TYPE_NONE, 0, 1) : swap_svi_lif_back(); //svi arp
            // (0, SWITCH_IP_TYPE_NONE, 1) : both();
            (false, SWITCH_IP_TYPE_IPV4, 0, 0) : set_ext_tunnel_decap();
            // (0, SWITCH_IP_TYPE_IPV4, 1) : both();
            (false, SWITCH_IP_TYPE_IPV6, 0, 0) : set_ext_tunnel_decap();
            (false, SWITCH_IP_TYPE_IPV6, 1, 0) : swap_lif_back();
            (false, SWITCH_IP_TYPE_IPV6, 1, 1) : swap_svi_lif_back();//svi nd
            (true, SWITCH_IP_TYPE_NONE, 0, 0) : swap_lif_back();
            // (1, SWITCH_IP_TYPE_NONE, 1) : swap_lif_back();
            (true, SWITCH_IP_TYPE_IPV4, 0, 0) : NoAction();
            // (1, SWITCH_IP_TYPE_IPV4, 1) : set_ext_tunnel_decap();
            (true, SWITCH_IP_TYPE_IPV6, 0, 0) : NoAction();
            (true, SWITCH_IP_TYPE_IPV6, 1, 0) : swap_lif_back();

        }
        size = exchange_lif_size;
    }

    apply {
        if (eg_md.tunnel.evlan_rmac_hit == 1 || eg_md.common.svi_flag == 1) {
            exchange_lif.apply();
        }
    }
}

control EvlanStats(inout switch_egress_metadata_t eg_md){

    bit<14> evlan_counter_index = 0;
    const switch_uint32_t counter_size = 1024*12; //for power
    Counter<bit<64>, bit<14>>(counter_size, CounterType_t.PACKETS_AND_BYTES) storm_control_drop_counter;
    Counter<bit<64>, bit<14>>(counter_size, CounterType_t.PACKETS_AND_BYTES) evlan_counter;
    Counter<bit<64>, bit<14>>(counter_size, CounterType_t.PACKETS_AND_BYTES) svi_counter;

    action evlan_count(bit<14> index){
        evlan_counter_index = index;
        evlan_counter.count(index);
    }

    table evlan_stats{
        key = {
            eg_md.lkp.pkt_type : exact;
            eg_md.ebridge.evlan : exact;
        }

        actions = {
            evlan_count;
            NoAction;
        }

        const default_action = NoAction;
        size = 1024*20;
    }

    action drop_count(){
        storm_control_drop_counter.count(evlan_counter_index);
    }

    table evlan_drop_stats{
        actions = {
            drop_count;
        }

        const default_action = drop_count;
    }

    action svi_count(bit<14> index){
        svi_counter.count(index);
    }

    table svi_stats{
        key = {
            eg_md.lkp.pkt_type : exact;
            eg_md.common.iif : exact;
        }

        actions = {
            svi_count;
            NoAction;
        }

        const default_action = NoAction;
        size = 1024*20;
    }

    apply{
        evlan_stats.apply();
        svi_stats.apply();

        if(eg_md.qos.storm_control_color == SWITCH_METER_COLOR_RED){
            evlan_drop_stats.apply();
        }
    }
}
# 229 "/mnt/p4c-4127/p4src/switch-tofino2/switch_tofino_x1.p4" 2
# 1 "/mnt/p4c-4127/p4src/shared/stp.p4" 1
control IngressSTP(in switch_header_t hdr, inout switch_ingress_metadata_t ig_md)(
             switch_uint32_t vlan_stg_table_size=4096,
             switch_uint32_t stp_port_state_table_size=32768,
             switch_uint32_t stp_port_state_back_table_size=512) {
    action set_stp_group(switch_stp_group_t group) {
        ig_md.stp.stg = group;
    }

    // @stage(9)
    @use_hash_action(1)
    table vlan_stg {
        key = {
            hdr.vlan_tag[0].vid : exact;
            // ig_md.lkp.vid : exact;
        }

        actions = {
            set_stp_group;
        }

        const default_action = set_stp_group(0);
        size = vlan_stg_table_size;
    }

    action set_stp_state(switch_stp_state_t stp_state) {
        ig_md.stp.state = stp_state;
    }

    @use_hash_action(1)
    table stp_port_state {
        key = {
            ig_md.stp.stg : exact;
            ig_md.common.src_port : exact;
        }

        actions = {
            // @defaultonly NoAction;
            set_stp_state;
        }

        const default_action = set_stp_state(0);
        size = stp_port_state_table_size;
    }

    table back_stp_port_state {
        key = {
            ig_md.stp.stg : exact;
            ig_md.common.src_port : exact;
        }

        actions = {
            @defaultonly NoAction;
            set_stp_state;
        }

        const default_action = NoAction;
        size = stp_port_state_back_table_size;
    }

    apply {
        if (hdr.vlan_tag[0].isValid()) {
            vlan_stg.apply();
        }

        stp_port_state.apply();
        // if(!stp_port_state.apply().hit) {
        //     back_stp_port_state.apply();
        // }

    }
}

control EgressSTP(in switch_header_t hdr, inout switch_ingress_metadata_t ig_md)(
             switch_uint32_t vlan_stg_table_size=4096,
             switch_uint32_t stp_port_state_table_size=32768,
             switch_uint32_t stp_port_state_back_table_size=512) {

    action set_stp_group(switch_stp_group_t group) {
        ig_md.stp.stg = group;
    }

    @use_hash_action(1)
    table vlan_stg {
        key = {
            hdr.vlan_tag[0].vid : exact;
        }

        actions = {
            set_stp_group;
        }

        const default_action = set_stp_group(0);
        size = vlan_stg_table_size;
    }

    action set_stp_state(switch_stp_state_t stp_state) {
        ig_md.stp.state = stp_state;
    }

    @use_hash_action(1)
    table stp_port_state {
        key = {
            ig_md.stp.stg : exact;
            ig_md.common.dst_port : exact;
        }

        actions = {
            // @defaultonly NoAction;
            set_stp_state;
        }

        const default_action = set_stp_state(0);
        size = stp_port_state_table_size;
    }

    table back_stp_port_state {
        key = {
            ig_md.stp.stg : exact;
            ig_md.common.dst_port : exact;
        }

        actions = {
            @defaultonly NoAction;
            set_stp_state;
        }

        const default_action = NoAction;
        size = stp_port_state_back_table_size;
    }

    apply {
        if (hdr.vlan_tag[0].isValid()) {
            vlan_stg.apply();
        }
        stp_port_state.apply();
        // if(!stp_port_state.apply().hit){
        //     back_stp_port_state.apply();
        // }

    }
}
# 230 "/mnt/p4c-4127/p4src/switch-tofino2/switch_tofino_x1.p4" 2

# 1 "/mnt/p4c-4127/p4src/shared/validation_front.p4" 1
control IngressPktValidation_front(
            inout switch_header_t hdr,
            inout switch_ingress_metadata_t ig_md)(
            switch_uint32_t validation_table_size = 64){

    SRv6_VALIDATION() srv6_validate;

    action malformed_pkt(bit<8> reason) {
        ig_md.common.drop_reason = reason;
    }

    action valid_unicast_pkt() {
        ig_md.lkp.pkt_type = FABRIC_PKT_TYPE_UNICAST;
    }

    action valid_multicast_pkt() {
        ig_md.lkp.pkt_type = FABRIC_PKT_TYPE_MCAST;
    }

    action valid_broadcast_pkt() {
        ig_md.lkp.pkt_type = FABRIC_PKT_TYPE_BROADCAST;
    }

    table validate_pkt_type {
        key = {
            hdr.ethernet.src_addr : ternary;
            hdr.ethernet.dst_addr : ternary;
        }

        actions = {
            malformed_pkt;
            valid_unicast_pkt;
            valid_multicast_pkt;
            valid_broadcast_pkt;
        }

        size = validation_table_size;
        /* const entries = {
            (_, _) : malformed_pkt(SWITCH_DROP_SRC_MAC_MULTICAST);
            (0, _) : malformed_pkt(SWITCH_DROP_SRC_MAC_ZERO);
            (_, 0) : malformed_pkt(SWITCH_DROP_DST_MAC_ZERO);
        } */
    }
    // ip_tos for qos
    action valid_ipv4_pkt(bit<2> ip_frag) {
        ig_md.lkp.ip_frag = ip_frag;
        ig_md.lkp.ipv4_ihl = (bit<16>)hdr.ipv4.ihl;
        ig_md.lkp.ip_tos = hdr.ipv4.diffserv; // used by qos
    }

    action valid_ipv6_pkt() {
        ig_md.lkp.ip_tos = hdr.ipv6.traffic_class; // used by qos
    }
    table validate_ip_pkt {
        key = {
            hdr.ipv4.isValid() : ternary;
            hdr.ipv6.isValid() : ternary;
            ig_md.flags.ipv4_checksum_err : ternary;
            ig_md.lkp.version : ternary;
            hdr.ipv4.ihl : ternary;
            hdr.ipv4.flags : ternary;
            hdr.ipv4.frag_offset : ternary;
            ig_md.lkp.ip_ttl : ternary;
            ig_md.lkp.ip_src_addr : ternary;
            ig_md.lkp.ip_dst_addr : ternary;
        }
        actions = {
            valid_ipv4_pkt;
            valid_ipv6_pkt;
            malformed_pkt;
        }

        size = VALIDATION_TABLE_SIZE;
        const default_action = malformed_pkt(SWITCH_DROP_REASON_IP_VERSION_INVALID);
    }

    action set_vlan1_etype() {
        ig_md.common.ether_type = hdr.vlan_tag[1].ether_type;
    }
    action set_vlan0_etype() {
        ig_md.common.ether_type = hdr.vlan_tag[0].ether_type;
    }
    action set_fabric_eth_etype() {
        ig_md.common.ether_type = hdr.fabric_eth_etype.ether_type;
    }
    action set_br_tag_etype() {
        ig_md.common.ether_type = hdr.br_tag.ether_type;
    }
    action set_ether_etype() {
        ig_md.common.ether_type = hdr.ethernet.ether_type;
    }
    action set_value(bit<16> etype_value) {
        ig_md.common.ether_type = etype_value;
    }
    table get_etype {
        key = {
            hdr.vlan_tag[1].isValid() : exact;
            hdr.vlan_tag[0].isValid() : exact;
            hdr.fabric_eth_etype.isValid() : exact;
            hdr.br_tag.isValid() : exact;
            hdr.ethernet.isValid() : exact;
        }
        actions = {
            set_vlan1_etype;
            set_vlan0_etype;
            set_fabric_eth_etype;
            set_br_tag_etype;
            set_ether_etype;
            set_value;
        }
        size = 32;
        const entries = {
            ( true, true, true, true, true) : set_vlan1_etype();
            ( true, true, true, true, false) : set_vlan1_etype();
            ( true, true, true, false, true) : set_vlan1_etype();
            ( true, true, true, false, false) : set_vlan1_etype();
            ( true, true, false, true, true) : set_vlan1_etype();
            ( true, true, false, true, false) : set_vlan1_etype();
            ( true, true, false, false, true) : set_vlan1_etype();
            ( true, true, false, false, false) : set_vlan1_etype();
            ( true, false, true, true, true) : set_vlan1_etype();
            ( true, false, true, true, false) : set_vlan1_etype();
            ( true, false, true, false, true) : set_vlan1_etype();
            ( true, false, true, false, false) : set_vlan1_etype();
            ( true, false, false, true, true) : set_vlan1_etype();
            ( true, false, false, true, false) : set_vlan1_etype();
            ( true, false, false, false, true) : set_vlan1_etype();
            ( true, false, false, false, false) : set_vlan1_etype();
            (false, true, true, true, true) : set_vlan0_etype();
            (false, true, true, true, false) : set_vlan0_etype();
            (false, true, true, false, true) : set_vlan0_etype();
            (false, true, true, false, false) : set_vlan0_etype();
            (false, true, false, true, true) : set_vlan0_etype();
            (false, true, false, true, false) : set_vlan0_etype();
            (false, true, false, false, true) : set_vlan0_etype();
            (false, true, false, false, false) : set_vlan0_etype();
            (false, false, true, true, true) : set_fabric_eth_etype();
            (false, false, true, true, false) : set_fabric_eth_etype();
            (false, false, true, false, true) : set_fabric_eth_etype();
            (false, false, true, false, false) : set_fabric_eth_etype();
            (false, false, false, true, true) : set_br_tag_etype();
            (false, false, false, true, false) : set_br_tag_etype();
            (false, false, false, false, true) : set_ether_etype();
            (false, false, false, false, false) : set_value(0);
        }
    }

    action ihl_calc() {
        ig_md.lkp.ipv4_ihl = ig_md.lkp.ipv4_ihl << 2;
    }

    table ip_ihl_calc {
        key = {
            hdr.ipv4.isValid() : exact;
        }
        actions = {
            ihl_calc;
        }
        // const entries = {
        //     true : ihl_calc();
        // }
    }

    apply {
        // ig_md.common.drop_reason = 0;
        get_etype.apply();
        switch(validate_pkt_type.apply().action_run) {
            malformed_pkt : {}
            default : {
                if (hdr.ipv4.isValid() || hdr.ipv6.isValid()) {
                    validate_ip_pkt.apply();
                    ip_ihl_calc.apply();
                }

                    if (hdr.srv6_srh.isValid()) {
                        srv6_validate.apply(hdr, ig_md, ig_md.common.drop_reason);
                    }

            }
        }
    }
}

control IPValidation(
            in switch_header_t hdr,
            inout switch_ingress_metadata_t ig_md)(
            switch_uint32_t validation_table_size = 64){
    action validate_pass() {

    }
    action validate_fail(switch_drop_reason_t reason) {
        ig_md.common.drop_reason = reason;
    }
    @stage(9)
    table ip_validate {
        key = {
            ig_md.common.iif_type : ternary;
            hdr.ethernet.dst_addr : ternary;
            ig_md.lkp.ip_dst_addr : ternary;
            ig_md.lkp.ipv4_ihl : ternary;
            ig_md.flags.mc_check : ternary;
            hdr.ipv4.isValid() : ternary;
            hdr.ipv6.isValid() : ternary;
            ig_md.lkp.pkt_type : ternary;
        }
        actions = {
            validate_pass;
            validate_fail;
        }
        /*
        const entries = {
            (_, _, _, 0, _, true, _, _)                                                                     : validate_fail(SWITCH_DROP_REASON_IP_IHL_INVALID);
            (1, 0x01005e000000 & 0xffffff800000, 0xe0000000 & 0xf0000000, _, 0 & 0x007FFFFF, true,  _, 2)   : validate_pass();
            (1, 0x01005e900001 & 0xffffffffffff, _, _, true, _, 2)                                          : validate_pass();
            (1, _, _, _, true, _, 2)                                                                        : validate_fail(SWITCH_DROP_REASON_IP_MC_CHECK_FAIL);
            (1, 0x333300000000 & 0xffff00000000, 0xff & 0xff, 0 & 0xFFFFFFFF, _, true, 2)                   : validate_pass();
            (1, 0x01005e900001 & 0xffffffffffff, _, _, _, true, 2)                                          : validate_pass();
            (1, _, _, _, _, true, 2)                                                                        : validate_fail(SWITCH_DROP_REASON_IP_MC_CHECK_FAIL);
            (1, _, 0xe0000000 & 0xf0000000, _, true, _, 1)                                                  : validate_fail(SWITCH_DROP_REASON_IP_MC_CHECK_FAIL);
            (1, _, 0xff & 0xff, _, _, true, 1)                                                              : validate_fail(SWITCH_DROP_REASON_IP_MC_CHECK_FAIL);
            (_, _, _, _, _, _, 0 & 3)                                                                       : validate_pass();
            (_, _, _, _, _, _, 1 & 3)                                                                       : validate_pass();
            (_, _, _, _, _, _, 3 & 3)                                                                       : validate_pass();
            (0, _, _, _, _, _, _)                                                                           : validate_pass();
        }
        */
    }

    action ipv4_calc_1() {
        ig_md.lkp.ipv4_ihl = ig_md.lkp.ipv4_ihl - 1;
        ig_md.flags.mc_check = ig_md.lkp.ip_dst_addr[31:0] ^ hdr.ethernet.dst_addr[31:0];
    }
    action ipv6_calc_1() {
        ig_md.flags.mc_check = ig_md.lkp.ip_dst_addr[31:0] ^ hdr.ethernet.dst_addr[31:0];
    }
    @stage(2)
    table ip_calc1 {
        key = {
            hdr.ipv4.isValid() : exact;
            hdr.ipv6.isValid() : exact;
        }
        actions = {
            ipv4_calc_1;
            ipv6_calc_1;
        }
        // const entries = {
        //     (true, false) : ipv4_calc_1();
        //     (false, true) : ipv6_calc_1();
        // }
    }

    action ipv4_calc_2() {
        ig_md.lkp.ipv4_ihl = hdr.ipv4.total_len |-| ig_md.lkp.ipv4_ihl;
    }
    table ipv4_calc2 {
        key = {
            hdr.ipv4.isValid() : exact;
        }
        actions = {
            ipv4_calc_2;
        }
        // const entries = {
        //     true : ipv4_calc_2();
        // }
    }

    apply {
        ip_calc1.apply();
        ipv4_calc2.apply();
        if (hdr.ipv4.isValid() || hdr.ipv6.isValid()) {
            if (ig_md.common.drop_reason == 0) {
                ip_validate.apply();
            }
        }
    }
}

control EgressPktValidation_front(
            in switch_header_t hdr,
            inout switch_egress_metadata_t eg_md)(
            switch_uint32_t validation_table_size = 64){

    action valid_unicast_pkt() {
        eg_md.lkp.pkt_type = FABRIC_PKT_TYPE_UNICAST;
    }

    action valid_multicast_pkt() {
        eg_md.lkp.pkt_type = FABRIC_PKT_TYPE_MCAST;
    }

    action valid_broadcast_pkt() {
        eg_md.lkp.pkt_type = FABRIC_PKT_TYPE_BROADCAST;
    }

    /* Get front egress lkp pkt_type for oif stats*/
    @stage(2)
    table validate_pkt_type {
        key = {
            hdr.ethernet.isValid() : exact;
            hdr.ethernet.dst_addr : ternary;
        }

        actions = {
            valid_unicast_pkt;
            valid_multicast_pkt;
            valid_broadcast_pkt;
        }

        size = validation_table_size;
    }

    action set_vlan1_etype() {
        eg_md.common.ether_type = hdr.vlan_tag[1].ether_type;
        // eg_md.lkp.vid = hdr.vlan_tag[0].vid;
    }
    action set_vlan0_etype() {
        eg_md.common.ether_type = hdr.vlan_tag[0].ether_type;
        // eg_md.lkp.vid = hdr.vlan_tag[0].vid;
    }
    action set_fabric_eth_etype() {
        eg_md.common.ether_type = hdr.fabric_eth_etype.ether_type;
    }
    action set_br_tag_etype() {
        eg_md.common.ether_type = hdr.br_tag.ether_type;
    }
    action set_ether_etype() {
        eg_md.common.ether_type = hdr.ethernet.ether_type;
    }
    action set_value(bit<16> etype_value) {
        eg_md.common.ether_type = etype_value;
    }
    @stage(0)
    table get_etype {
        key = {
            hdr.vlan_tag[1].isValid() : exact;
            hdr.vlan_tag[0].isValid() : exact;
            hdr.fabric_eth_etype.isValid() : exact;
            hdr.br_tag.isValid() : exact;
            hdr.ethernet.isValid() : exact;
        }
        actions = {
            set_vlan1_etype;
            set_vlan0_etype;
            set_fabric_eth_etype;
            set_br_tag_etype;
            set_ether_etype;
            set_value;
        }
        size = 32;
        const entries = {
            ( true, true, true, true, true) : set_vlan1_etype();
            ( true, true, true, true, false) : set_vlan1_etype();
            ( true, true, true, false, true) : set_vlan1_etype();
            ( true, true, true, false, false) : set_vlan1_etype();
            ( true, true, false, true, true) : set_vlan1_etype();
            ( true, true, false, true, false) : set_vlan1_etype();
            ( true, true, false, false, true) : set_vlan1_etype();
            ( true, true, false, false, false) : set_vlan1_etype();
            ( true, false, true, true, true) : set_vlan1_etype();
            ( true, false, true, true, false) : set_vlan1_etype();
            ( true, false, true, false, true) : set_vlan1_etype();
            ( true, false, true, false, false) : set_vlan1_etype();
            ( true, false, false, true, true) : set_vlan1_etype();
            ( true, false, false, true, false) : set_vlan1_etype();
            ( true, false, false, false, true) : set_vlan1_etype();
            ( true, false, false, false, false) : set_vlan1_etype();
            (false, true, true, true, true) : set_vlan0_etype();
            (false, true, true, true, false) : set_vlan0_etype();
            (false, true, true, false, true) : set_vlan0_etype();
            (false, true, true, false, false) : set_vlan0_etype();
            (false, true, false, true, true) : set_vlan0_etype();
            (false, true, false, true, false) : set_vlan0_etype();
            (false, true, false, false, true) : set_vlan0_etype();
            (false, true, false, false, false) : set_vlan0_etype();
            (false, false, true, true, true) : set_fabric_eth_etype();
            (false, false, true, true, false) : set_fabric_eth_etype();
            (false, false, true, false, true) : set_fabric_eth_etype();
            (false, false, true, false, false) : set_fabric_eth_etype();
            (false, false, false, true, true) : set_br_tag_etype();
            (false, false, false, true, false) : set_br_tag_etype();
            (false, false, false, false, true) : set_ether_etype();
            (false, false, false, false, false) : set_value(0);
        }
    }

    apply {
        validate_pkt_type.apply();
        get_etype.apply();
    }
}
# 232 "/mnt/p4c-4127/p4src/switch-tofino2/switch_tofino_x1.p4" 2
# 1 "/mnt/p4c-4127/p4src/shared/validation_inner.p4" 1
/*
 *  decap tunnel inner pkt ==> TODO
 *  no decap tunnel outer pkt ==> in front
 *  normal pkt ==> in front
 */

control EgressPktValid_uplink(
        inout switch_header_t hdr,
        inout switch_egress_metadata_t eg_md) {

    const switch_uint32_t validation_table_size = 64;

    Hash<bit<32>>(HashAlgorithm_t.IDENTITY) hash_dst;

    action malformed_pkt(switch_drop_reason_t reason) {
        eg_md.route.drop_reason = reason;
    }

    action valid_pkt_type_with_learning(switch_lkp_pkt_type_t type) {
        eg_md.lkp.pkt_type = type;
        eg_md.flags.learning[0:0] = 0;
    }

    action valid_pkt_type(switch_lkp_pkt_type_t type) {
        eg_md.lkp.pkt_type = type;
    }

    @stage(1)
    table validate_pkt_type {
        key = {
            hdr.ethernet.isValid() : exact;
            hdr.ethernet.src_addr : ternary;
            hdr.ethernet.dst_addr : ternary;
        }

        actions = {
            malformed_pkt;
            valid_pkt_type;
            valid_pkt_type_with_learning;
        }

        size = validation_table_size;
    }

    action get_ipv4_ttl() {
        eg_md.lkp.tmp_ttl = eg_md.tunnel.ttl |-| hdr.ipv4.ttl;
    }

    action get_ipv6_ttl() {
        /* reserved.  tmp_ttl��ofor srv 6 ttl_rebuild  */
        eg_md.lkp.tmp_ttl = eg_md.tunnel.ttl |-| hdr.ipv6.hop_limit;
    }

    table ip_info {
        key = {
            hdr.ipv4.isValid() : exact;
            hdr.ipv6.isValid() : exact;
        }

        actions = {
            NoAction;
            get_ipv4_ttl;
            get_ipv6_ttl;
        }
        const default_action = NoAction;
        // const entries = {
        //     (true, false) : get_ipv4_ttl();
        //     (false, true) : get_ipv6_ttl();
        // }
    }

    apply {
        switch(validate_pkt_type.apply().action_run) {
            malformed_pkt : {}
            default : {
                // if can not put this table in this control, can take it out
                //for srv6 tunnel terminate(or ip tunnel),ttl copy into inner
                ip_info.apply();
            }
        }
    }
}

control IngressPktValid_uplink(
        inout switch_header_t hdr,
        inout switch_ingress_metadata_t ig_md) {

    const switch_uint32_t validation_table_size = 64;

    action valid_inner_ethernet_pkt() {
        ig_md.lkp.mac_src_addr = hdr.inner_ethernet.src_addr;
        ig_md.lkp.mac_dst_addr = hdr.inner_ethernet.dst_addr;
    }

    table validation_ethernet {
        key = {
            hdr.inner_ethernet.isValid(): exact;
        }
        actions = {
            valid_inner_ethernet_pkt;
            NoAction;
        }

        // const entries = {
        //     (true)   : valid_inner_ethernet_pkt;
        //     (false)  : NoAction;
        // }
        size = validation_table_size;
    }

    apply{
        validation_ethernet.apply();
    }
}

control EgressMirrorPktValidation_fabric(
            in switch_header_t hdr,
            inout switch_egress_metadata_t eg_md)(
            switch_uint32_t validation_table_size = 64){

    action valid_ipv4_pkt() {
        eg_md.common.pkt_type = FABRIC_PKT_TYPE_IPV4;
    }

    action valid_ipv6_pkt() {
        eg_md.common.pkt_type = FABRIC_PKT_TYPE_IPV6;
    }

    action valid_mpls_pkt() {
        eg_md.common.pkt_type = FABRIC_PKT_TYPE_MPLS;
    }

    action valid_eth_pkt() {
        eg_md.common.pkt_type = FABRIC_PKT_TYPE_ETH;
    }

    /* Get front egress lkp pkt_type for oif stats*/
    table validate_pkt_type {
        key = {
            hdr.ethernet.isValid() : ternary;
            hdr.ipv4.isValid() : ternary;
            hdr.ipv6.isValid() : ternary;
            hdr.mpls_ig[0].isValid(): ternary;
        }

        actions = {
            valid_eth_pkt;
            valid_ipv4_pkt;
            valid_ipv6_pkt;
            valid_mpls_pkt;
        }

        const entries = {
            (true, false, false, false) : valid_eth_pkt();
            (true, true, false, false) : valid_ipv4_pkt();
            (true, false, true, false) : valid_ipv6_pkt();
            (true, _, _, true) : valid_mpls_pkt();

        }
        size = validation_table_size;
    }

    apply {
        validate_pkt_type.apply();
    }
}

control IngressPktValid_fabric(
        inout switch_ingress_metadata_t ig_md,
        inout switch_header_t hdr) {

    const switch_uint32_t validation_table_size = 64;

    action valid_inner_ethernet_pkt() {
        ig_md.lkp.mac_src_addr = hdr.inner_ethernet.src_addr;
        ig_md.lkp.mac_dst_addr = hdr.inner_ethernet.dst_addr;
    }

    table validation_ethernet {
        key = {
            hdr.inner_ethernet.isValid(): exact;
        }
        actions = {
            valid_inner_ethernet_pkt;
            NoAction;
        }

        // const entries = {
        //     (true)   : valid_inner_ethernet_pkt;
        //     (false)  : NoAction;
        // }
        size = validation_table_size;
    }

    apply{
        validation_ethernet.apply();
    }
}
# 233 "/mnt/p4c-4127/p4src/switch-tofino2/switch_tofino_x1.p4" 2

# 1 "/mnt/p4c-4127/p4src/shared/fabric.p4" 1
/*
 * Fabric processing for multi-device system
 */

/*****************************************************************************/
/* Ingress fabric header processing                                          */
/*****************************************************************************/
control IngressFabric_uplink(
        inout switch_ingress_metadata_t ig_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm,
        inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr,
        inout switch_header_t hdr) {

    action fabric_qos_decap() {
        ig_md.qos.tc = hdr.fabric_qos.tc;
        ig_md.qos.color = hdr.fabric_qos.color;
        ig_md.qos.chgDSCP_disable = hdr.fabric_qos.chgDSCP_disable;
        ig_md.qos.BA = hdr.fabric_qos.BA;
        ig_md.common.track = hdr.fabric_qos.track;
    }

    action terminate_unicast() {
        fabric_qos_decap();
        // evade compiler bug, assignment in parser
        // ig_md.flags.fwd_fail = hdr.fabric_unicast_ext_igfpga_bfn.fwd_fail;
        // ig_md.flags.glean = hdr.fabric_unicast_ext_igfpga_bfn.glean;
        ig_md.flags.drop = hdr.fabric_unicast_ext_igfpga_bfn.drop;
        ig_md.flags.escape_etm = hdr.fabric_unicast_ext_igfpga_bfn.escape_etm;
        ig_md.common.svi_flag = hdr.fabric_unicast_ext_igfpga_bfn.svi_flag;
        ig_md.common.hash[7:0] = hdr.fabric_unicast_ext_igfpga_bfn.var_byte;
        ig_md.common.src_port = hdr.fabric_crsp.src_port;// hash calc cannot directly use hdr.xxx
    }

    action terminate_unicast_eth() {
        terminate_unicast();
        ig_md.ebridge.evlan = hdr.fabric_eth_ext.evlan;
        // ig_md.flags.learning = hdr.fabric_eth_ext.l2_flag;
        hdr.fabric_var_ext_1_16bit.data = 0;
    }

    action terminate_unicast_ip() {
        terminate_unicast();
        ig_md.route.dip_l3class_id = hdr.fabric_var_ext_1_16bit.data[15:8];
        ig_md.route.sip_l3class_id = hdr.fabric_var_ext_1_16bit.data[7:0];
        // need to keey fabric_var_ext_1_16bit.data as l3class_id
    }

    action terminate_unicast_ipv4() {
        terminate_unicast_ip();
    }

    action terminate_unicast_ipv6() {
        terminate_unicast_ip();
    }

    action terminate_unicast_mpls() {
        terminate_unicast();
        ig_md.tunnel.phpcopy = hdr.fabric_unicast_ext_igfpga_bfn.var_byte[7:7];
        ig_md.tunnel.opcode = hdr.fabric_unicast_ext_igfpga_bfn.var_byte[6:3];
        hdr.fabric_var_ext_1_16bit.data = 0;
    }

    action terminate_multicast() {
        fabric_qos_decap();
        // evade compiler bug, assignment in parser
        // ig_md.flags.glean = hdr.fabric_unicast_ext_igfpga_bfn.glean;
        ig_md.flags.drop = hdr.fabric_unicast_ext_igfpga_bfn.drop;
        ig_md.flags.escape_etm = hdr.fabric_unicast_ext_igfpga_bfn.escape_etm;
        ig_md.common.svi_flag = hdr.fabric_unicast_ext_igfpga_bfn.svi_flag;
        // ig_md.common.hash[7:0] = hdr.fabric_unicast_ext_igfpga_bfn.var_byte;  
        ig_md.common.src_port = hdr.fabric_crsp.src_port;// hash calc cannot directly use hdr.xxx
        hdr.fabric_var_ext_1_16bit.data = 0;
    }

    action terminate_multicast_eth() {
        terminate_multicast();
        ig_md.ebridge.evlan = hdr.fabric_eth_ext.evlan;
        // ig_md.flags.learning = hdr.fabric_eth_ext.l2_flag;
    }

    action terminate_ipfix_spec_v4() {
        terminate_unicast_ip();
        // need to keey fabric_var_ext_1_16bit.data as l3class_id
    }

    action terminate_ipfix_spec_v6() {
        terminate_unicast_ip();
        // need to keey fabric_var_ext_1_16bit.data as l3class_id
    }

    action terminate_recirc_uc() {
        fabric_qos_decap();
        ig_md.flags.escape_etm = hdr.fabric_unicast_ext_igfpga_bfn.escape_etm;
        ig_md.common.dst_device = hdr.fabric_var_ext_1_16bit.data[14:8];
        ig_md.common.dst_port = hdr.fabric_var_ext_1_16bit.data[7:0];
        hdr.fabric_var_ext_1_16bit.data = 0;
    }

    action terminate_eop() {
        fabric_qos_decap();
        ig_md.common.dst_device = hdr.fabric_var_ext_1_16bit.data[14:8];
        ig_md.common.dst_port = hdr.fabric_var_ext_1_16bit.data[7:0];
    }

    action terminate_ccm() {
        fabric_qos_decap();
    }

    table fabric_ingress_decap {
        key = {
            hdr.fabric_base.pkt_type : exact;
            hdr.fabric_base.is_mcast : exact;
        }

        actions = {
            NoAction;
            terminate_unicast_eth;
            terminate_unicast_ipv4;
            terminate_unicast_ipv6;
            terminate_unicast_mpls;
            terminate_ipfix_spec_v4;
            terminate_ipfix_spec_v6;
            terminate_recirc_uc;
            terminate_eop;
            terminate_ccm;
            terminate_multicast;
            terminate_multicast_eth;
        }

        const default_action = NoAction;
        size = 128;
        const entries = {
            (FABRIC_PKT_TYPE_ETH, 0) : terminate_unicast_eth();
            (FABRIC_PKT_TYPE_IPV4, 0) : terminate_unicast_ipv4();
            (FABRIC_PKT_TYPE_IPV6, 0) : terminate_unicast_ipv6();
            (FABRIC_PKT_TYPE_MPLS, 0) : terminate_unicast_mpls();
            (FABRIC_PKT_TYPE_IPFIX_SPEC_V4, 0) : terminate_ipfix_spec_v4();
            (FABRIC_PKT_TYPE_IPFIX_SPEC_V6, 0) : terminate_ipfix_spec_v6();
            (FABRIC_PKT_TYPE_CPU_ETH, 0) : terminate_recirc_uc();
            (FABRIC_PKT_TYPE_EOP, 0) : terminate_eop();
            (FABRIC_PKT_TYPE_CCM, 0) : terminate_ccm();
            /* by zhangjunjie */
            (FABRIC_PKT_TYPE_CCM, 1) : terminate_ccm();
            (FABRIC_PKT_TYPE_IPV4, 1) : terminate_multicast();
            (FABRIC_PKT_TYPE_IPV6, 1) : terminate_multicast();
            (FABRIC_PKT_TYPE_ETH, 1) : terminate_multicast_eth();
        }
    }

    apply {
        // move assignment to parser
        // if (hdr.ext_tunnel_decap.isValid() || hdr.ext_l4_encap.isValid()) {
        //     ig_md.common.extend = 1w1;
        // }
        if (hdr.fabric_base.isValid()) {
            fabric_ingress_decap.apply();
        }
    }
}

control IngressFabric_fabric(
        inout switch_ingress_metadata_t ig_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm,
        inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr,
        inout switch_header_t hdr) {

    Counter<bit<64>, bit<16>>(8, CounterType_t.PACKETS) pcie_tx_stats;

    action fabric_base_decap() {
        ig_md.common.pkt_type = hdr.fabric_base.pkt_type;
        ig_md.common.is_mirror = hdr.fabric_base.is_mirror;
        ig_md.common.is_mcast = hdr.fabric_base.is_mcast;
    }

    action fabric_qos_decap() {
        ig_md.qos.tc = hdr.fabric_qos.tc;
        ig_md.qos.color = hdr.fabric_qos.color;
        ig_md.qos.chgDSCP_disable = hdr.fabric_qos.chgDSCP_disable;
        ig_md.qos.BA = hdr.fabric_qos.BA;
        ig_md.common.track = hdr.fabric_qos.track;
    }

    action terminate_unicast() {
        fabric_base_decap();
        fabric_qos_decap();
        ig_md.common.l2_encap = hdr.fabric_unicast_ext_fe.l2_encap;
        // ig_md.common.l3_encap = hdr.fabric_unicast_ext_fe.l3_encap;// non-ref in ig-fabric
        ig_md.common.iif = hdr.fabric_one_pad_7.iif;
    }

    action terminate_unicast_eth() {
        init_bridge_type(ig_md, BRIDGE_TYPE_FABRIC_DOWNLINK);
        terminate_unicast();
        ig_md.ebridge.evlan = hdr.fabric_var_ext_1_16bit.data;
        // ig_md.ebridge.l2oif = hdr.fabric_post_one_pad.l2oif; // move to parser
        // ig_md.common.oif = hdr.fabric_post_one_pad.l2oif;    // move to parser
        // hdr.fabric_base.setInvalid();
        // hdr.fabric_qos.setInvalid();
        hdr.fabric_unicast_dst.setInvalid();
        // hdr.fabric_unicast_ext_fe.setInvalid();//reuse in bridge_md_78
        // hdr.fabric_var_ext_1_16bit.setInvalid();//reuse in bridge_md_78
        hdr.fabric_var_ext_1_16bit.data = 0;
        // hdr.fabric_one_pad_7.setInvalid();//reuse in bridge_md_78
        // hdr.fabric_post_one_pad.setInvalid();
    }

    action terminate_unicast_ip() {
        init_bridge_type(ig_md, BRIDGE_TYPE_FABRIC_DOWNLINK);
        terminate_unicast();
        // ig_md.route.dip_l3class_id = hdr.fabric_var_ext_1_16bit.data[15:8];// non-ref in ig-fabric
        // ig_md.route.sip_l3class_id = hdr.fabric_var_ext_1_16bit.data[7:0];// non-ref in ig-fabric
        // hdr.fabric_base.setInvalid();
        // hdr.fabric_qos.setInvalid();
        hdr.fabric_unicast_dst.setInvalid();
        // hdr.fabric_unicast_ext_fe.setInvalid();//reuse in bridge_md_78
        // hdr.fabric_var_ext_1_16bit.setInvalid();//reuse in bridge_md_78
        // hdr.fabric_one_pad_7.setInvalid();//reuse in bridge_md_78
    }

    action terminate_unicast_mpls() {
        init_bridge_type(ig_md, BRIDGE_TYPE_FABRIC_DOWNLINK);
        terminate_unicast();
        // hdr.fabric_base.setInvalid();
        // hdr.fabric_qos.setInvalid();
        hdr.fabric_unicast_dst.setInvalid();
        // hdr.fabric_unicast_ext_fe.setInvalid();//reuse in bridge_md_78
        // hdr.fabric_var_ext_1_16bit.setInvalid();//reuse in bridge_md_78
        // hdr.fabric_one_pad_7.setInvalid();//reuse in bridge_md_78
    }

    action terminate_unicast_ipv4() {
        terminate_unicast_ip();
    }

    action terminate_unicast_ipv6() {
        terminate_unicast_ip();
    }

    action terminate_tran_mirror() {
        init_bridge_type(ig_md, BRIDGE_TYPE_FABRIC_FRONT);
        terminate_unicast();
        // hdr.fabric_base.setInvalid();
        // hdr.fabric_qos.setInvalid();
        hdr.fabric_unicast_dst.setInvalid();
        hdr.fabric_unicast_ext_fe.setInvalid();
        hdr.fabric_var_ext_1_16bit.setInvalid();
        hdr.fabric_one_pad_7.setInvalid();
    }

    action terminate_cpu_eth() {
        init_bridge_type(ig_md, BRIDGE_TYPE_FABRIC_DOWNLINK);
        terminate_unicast();
        // hdr.fabric_base.setInvalid();
        // hdr.fabric_qos.setInvalid();
        hdr.fabric_unicast_dst.setInvalid();
        // hdr.fabric_unicast_ext_fe.setInvalid();//reuse in bridge_md_78
        // hdr.fabric_var_ext_1_16bit.setInvalid();//reuse in bridge_md_78
        // hdr.fabric_one_pad_7.setInvalid();//reuse in bridge_md_78
    }

    action terminate_eop() {
        init_bridge_type(ig_md, BRIDGE_TYPE_FABRIC_DOWNLINK);
        terminate_unicast();
        // hdr.fabric_base.setInvalid();
        // hdr.fabric_qos.setInvalid();
        hdr.fabric_unicast_dst.setInvalid();
        // hdr.fabric_unicast_ext_fe.setInvalid();//reuse in bridge_md_78
        // hdr.fabric_var_ext_1_16bit.setInvalid();//reuse in bridge_md_78
        // hdr.fabric_one_pad_7.setInvalid();//reuse in bridge_md_78
    }

    action terminate_cpu_pcie(){
        ig_intr_md_for_dprsr.drop_ctl = 0x1;
        ig_intr_md_for_tm.copy_to_cpu = 1;
        ig_intr_md_for_tm.bypass_egress = 1w1;

        hdr.fabric_cpu_pcie_base.setValid();
        hdr.fabric_cpu_pcie_base.cpu_pkt_type = FABRIC_PKT_TYPE_CPU_PCIE;// use fabric_base.pkt_type when to cpu
        hdr.fabric_cpu_pcie_base.fwd_mode = FWD_MODE_HOP;
        hdr.fabric_cpu_pcie_base.qid = (bit<5>)SWITCH_QID_CPU_TO_CPU;
        //hdr.fabric_cpu_pcie_base.pad_qos = 0;
        hdr.fabric_cpu_pcie_base.track = ig_md.common.track;

        hdr.fabric_multicast_src.src_device = 0;
        hdr.fabric_multicast_src.src_port = ig_md.common.src_port;

        hdr.fabric_base.setInvalid();
        hdr.fabric_qos.setInvalid();
    }

    action terminate_multicast() {
        init_bridge_type(ig_md, BRIDGE_TYPE_FABRIC_DOWNLINK);
        fabric_base_decap();
        fabric_qos_decap();
        // hdr.fabric_base.setInvalid();//leave setInvalid to bridge_md_78 according to mc action
        // hdr.fabric_qos.setInvalid();//leave setInvalid to bridge_md_78 according to mc action
        ig_md.multicast.id = hdr.fabric_multicast_ext.mgid;
        ig_md.ebridge.evlan = hdr.fabric_multicast_ext.evlan;
        ig_md.common.iif = hdr.fabric_one_pad_7.iif;
        // hdr.fabric_multicast_src.setInvalid();//leave setInvalid to bridge_md_78 according to mc action
        // hdr.fabric_multicast_ext.setInvalid();//reuse in bridge_md_78
        // hdr.fabric_one_pad_7.setInvalid();////reuse in bridge_md_78
    }

    action terminate_unicast_ccm() {
        init_bridge_type(ig_md, BRIDGE_TYPE_FABRIC_DOWNLINK);
        fabric_base_decap();
        fabric_qos_decap();
        // hdr.fabric_base.setInvalid();
        // hdr.fabric_qos.setInvalid();
        hdr.fabric_unicast_dst.setInvalid();
        // hdr.fabric_unicast_ext_fe.setInvalid();
        // hdr.fabric_var_ext_1_16bit.setInvalid();    
        // hdr.fabric_one_pad.setInvalid();
    }
    /* by zhangjunjie */
    action terminate_multicast_ccm() {
        init_bridge_type(ig_md, BRIDGE_TYPE_FABRIC_DOWNLINK);
        fabric_base_decap();
        fabric_qos_decap();
        // hdr.fabric_base.setInvalid();//leave setInvalid to bridge_md_78 according to mc action
        // hdr.fabric_qos.setInvalid();//leave setInvalid to bridge_md_78 according to mc action
        ig_md.multicast.id = hdr.fabric_multicast_ext.mgid;
        // hdr.fabric_multicast_src.setInvalid();//leave setInvalid to bridge_md_78 according to mc action
        // hdr.fabric_multicast_ext.setInvalid();//reuse in bridge_md_78
        // hdr.fabric_one_pad_7.setInvalid();////reuse in bridge_md_78
    }

    action terminate_learning() {
        fabric_base_decap();
        fabric_qos_decap();
        ig_md.common.iif = hdr.fabric_one_pad_7.iif;
        ig_md.ebridge.evlan = hdr.fabric_var_ext_1_16bit.data;
        ig_intr_md_for_tm.ucast_egress_port = 511;
        ig_intr_md_for_dprsr.drop_ctl = 0x1;
        ig_intr_md_for_dprsr.digest_type = SWITCH_DIGEST_TYPE_MAC_LEARNING;
    }

    table fabric_ingress_decap {
        key = {
            hdr.fabric_base.pkt_type : ternary;
            hdr.fabric_base.is_mcast : exact;
            hdr.fabric_base.is_mirror : exact;
        }

        actions = {
            NoAction;
            terminate_unicast_eth;
            terminate_unicast_ipv4;
            terminate_unicast_ipv6;
            terminate_unicast_mpls;
            terminate_cpu_pcie;
            terminate_tran_mirror;
            terminate_cpu_eth;
            terminate_multicast;
            terminate_eop;
            terminate_unicast_ccm;
            /* by zhangjunjie */
            terminate_multicast_ccm;
            terminate_learning;
        }

        const default_action = NoAction;
        size = 128;
        const entries = {
            (FABRIC_PKT_TYPE_ETH, 0, 0) : terminate_unicast_eth();
            (FABRIC_PKT_TYPE_IPV4, 0, 0) : terminate_unicast_ipv4();
            (FABRIC_PKT_TYPE_IPV6, 0, 0) : terminate_unicast_ipv6();
            (FABRIC_PKT_TYPE_MPLS, 0, 0) : terminate_unicast_mpls();
            (FABRIC_PKT_TYPE_CPU_PCIE, 0, 0) : terminate_cpu_pcie();
            // (FABRIC_PKT_TYPE_MIRROR_TRAN, 0) : terminate_tran_mirror();
            (FABRIC_PKT_TYPE_CPU_ETH, 0, 0) : terminate_cpu_eth();
            (FABRIC_PKT_TYPE_EOP, 0, 0) : terminate_eop();
            (FABRIC_PKT_TYPE_CCM, 0, 0) : terminate_unicast_ccm();
            /* by zhangjunjie */
            (FABRIC_PKT_TYPE_CCM, 1, 0) : terminate_multicast_ccm();
            (FABRIC_PKT_TYPE_LEARNING, 0, 0) : terminate_learning();
            (_, 1, 0) : terminate_multicast();
            (_, 0, 1) : terminate_tran_mirror();
        }
    }

    action setInvalid_cpu_hdr() {
        hdr.fabric_cpu_pcie_base.setInvalid();
        hdr.fabric_unicast_dst.setInvalid();
        hdr.fabric_from_cpu_data.setInvalid();
        // hdr.fabric_one_pad_7.setInvalid();//reuse in bridge_md_78
    }

    action terminate_cpu_uc() {
        init_bridge_type(ig_md, BRIDGE_TYPE_FABRIC_DOWNLINK);
        ig_md.common.pkt_type = FABRIC_PKT_TYPE_ETH;
        ig_md.common.is_mirror = 0;
        ig_md.common.is_mcast = 0;
        ig_md.ebridge.evlan = hdr.fabric_from_cpu_data.evlan;
        ig_md.common.is_from_cpu_pcie = 1;
  setInvalid_cpu_hdr();
        hdr.fabric_base.setValid();
        hdr.fabric_base.pkt_type = FABRIC_PKT_TYPE_ETH;
        hdr.fabric_base.is_mirror = 0;
        hdr.fabric_base.is_mcast = 0;
        hdr.fabric_unicast_ext_fe.setValid();//reuse in bridge_md_78, padding
        hdr.fabric_var_ext_1_16bit.setValid();//reuse in bridge_md_78, padding
    }

    action terminate_cpu_mc() {
        init_bridge_type(ig_md, BRIDGE_TYPE_FABRIC_FABRIC);
        ig_md.common.pkt_type = FABRIC_PKT_TYPE_ETH;
        ig_md.common.is_mirror = 0;
        ig_md.common.is_mcast = 1;
        ig_md.ebridge.evlan = hdr.fabric_from_cpu_data.evlan;
        ig_md.common.iif = hdr.fabric_one_pad_7.iif;
        ig_md.multicast.id = 0;
        setInvalid_cpu_hdr();
        hdr.fabric_base.setValid();
        hdr.fabric_base.pkt_type = FABRIC_PKT_TYPE_ETH;
        hdr.fabric_base.is_mirror = 0;
        hdr.fabric_base.is_mcast = 1;
    }

    action terminate_cpu_to_cpu() {
        init_bridge_type(ig_md, BRIDGE_TYPE_FABRIC_FABRIC);
        ig_md.common.pkt_type = FABRIC_PKT_TYPE_CPU_PCIE;
        ig_md.common.is_mirror = 0;
        ig_md.common.is_mcast = 0;
        setInvalid_cpu_hdr();
        hdr.fabric_base.setValid();
        hdr.fabric_base.pkt_type = FABRIC_PKT_TYPE_CPU_PCIE;
        hdr.fabric_base.is_mirror = 0;
        hdr.fabric_base.is_mcast = 0;
        // add a fake ethernet header
        //hdr.ethernet.setValid();
        //hdr.ethernet.dst_addr = 0x005544332211;
        //hdr.ethernet.src_addr = 0x000504030201;
        //hdr.ethernet.ether_type = ETHERTYPE_FABRIC;
    }

 action set_drop(){
  ig_intr_md_for_dprsr.drop_ctl = 0x1;
    }

    table pcie_ingress_decap {
        key = {
            hdr.fabric_cpu_pcie_base.cpu_pkt_type: exact;
        }

        actions = {
            set_drop;
            terminate_cpu_uc;
            terminate_cpu_mc;
            terminate_cpu_to_cpu;
        }

        const default_action = set_drop;
        size = 8;
        const entries = {
            (CPU_PCIE_PKT_TYPE_CPU_UC) : terminate_cpu_uc();
            (CPU_PCIE_PKT_TYPE_CPU_MC) : terminate_cpu_mc();
            (CPU_PCIE_PKT_TYPE_CPU_TO_CPU) : terminate_cpu_to_cpu();
        }
    }

    action set_trace_cpu(bit<1> track) {
        ig_md.common.track = track;
    }

    table ingress_trace_filter {
        key = {
            ig_md.common.port_type : ternary @name("port_type");
            hdr.fabric_base.pkt_type : ternary @name("pkt_type");
            hdr.fabric_base.is_mirror : ternary @name("is_mirror");
            hdr.fabric_base.is_mcast : ternary @name("is_mcast");
            // hdr.fabric_cpu_pcie_base.cpu_pkt_type: ternary;            
            // hdr.fabric_cpu_pcie_base.qid: ternary;
            hdr.ethernet.isValid() : ternary @name("eth_valid");
            hdr.ethernet.dst_addr : ternary @name("dmac");
            hdr.ethernet.src_addr : ternary @name("smac");
            hdr.ethernet.ether_type : ternary @name("ether_type");
            hdr.vlan_tag[0].isValid() : ternary @name("vlan_0_valid");
            hdr.vlan_tag[0].vid : ternary @name("vlan_0_vid");
            hdr.vlan_tag[0].ether_type : ternary @name("vlan_0_ether_type");
            ig_md.lkp.ip_src_addr : ternary @name("sip");
            ig_md.lkp.ip_dst_addr : ternary @name("dip");
            ig_md.lkp.ip_proto : ternary @name("ip_proto");
            ig_md.lkp.l4_src_port : ternary @name("l4_sport");
            ig_md.lkp.l4_dst_port : ternary @name("l4_dport");
        }

        actions = {
            NoAction;
            set_trace_cpu;
        }

        const default_action = NoAction;
        size = 32;
    }

    // lkp qos tc from qid
    action set_cpu_qos(switch_tc_t tc, switch_pkt_color_t color) {
        ig_md.qos.tc = tc;
        ig_md.qos.color = color;
        hdr.fabric_qos.tc = tc;
        hdr.fabric_qos.color = color;
        hdr.fabric_qos.chgDSCP_disable = 0;
        hdr.fabric_qos.BA = 0;
        // hdr.fabric_qos.track = 0;
    }

    table cpu_qos_map {
        key = {
            hdr.fabric_cpu_pcie_base.qid: exact;
        }

        actions = {
            NoAction;
            set_cpu_qos;
        }

        const default_action = NoAction;
        size = 32;
    }

    action set_fpga_id(bit<7> dst_device) {
        ig_md.common.dst_device = dst_device;
    }

    action set_egress_port(switch_port_t dev_port) {
        ig_intr_md_for_tm.ucast_egress_port = dev_port;
        ig_md.common.dev_port = dev_port;
    }

    table fabric_ingress_dst_lkp {
        key = {
            ig_md.common.dst_port : exact;
        }

        actions = {
            NoAction;
            set_fpga_id; // for front port 
            set_egress_port; // for fabric port and eth cpu port
        }

        const default_action = NoAction;
        size = 128;
    }

    table fabric_ingress_dst_lkp_mirror {
        key = {
            ig_md.common.dst_port : exact;
        }

        actions = {
            NoAction;
            set_egress_port;
        }

        const default_action = NoAction;
        size = 128;
    }

    table fabric_ingress_dst_lkp_escape_etm {
        // keyless
        actions = {
            set_egress_port;
        }
        size = 1;
    }

    action set_escape_etm(){
        ig_md.flags.escape_etm = 0x1;
    }

    table sbfd_escape_etm {
        key = {
            ig_md.lkp.ip_proto : ternary;
            ig_md.lkp.l4_src_port : ternary;
            ig_md.lkp.l4_dst_port : ternary;
        }
        actions = {
            @defaultonly NoAction;
            set_escape_etm;
        }
        size = 32;
        default_action = NoAction;
    }

    apply {
        // move assignment to parser
        // if (hdr.ext_l4_encap.isValid() || hdr.ext_tunnel_decap.isValid()) {
        //     ig_md.common.extend = 1w1;
        // }

        if (ig_md.common.port_type == PORT_TYPE_FABRIC || ig_md.common.port_type == PORT_TYPE_RECIRC) {
            fabric_ingress_decap.apply();
        } else if (ig_md.common.port_type == PORT_TYPE_CPU_PCIE) {
            cpu_qos_map.apply();
            pcie_ingress_decap.apply();
            pcie_tx_stats.count(0);
        }

        ingress_trace_filter.apply();
        sbfd_escape_etm.apply();
        if (ig_md.flags.escape_etm == 1w0 && ig_md.common.is_mirror == 1w0) {
            fabric_ingress_dst_lkp.apply();
        } else if (ig_md.flags.escape_etm == 1w0 && ig_md.common.is_mirror == 1w1) {
            fabric_ingress_dst_lkp_mirror.apply();
        } else {
            fabric_ingress_dst_lkp_escape_etm.apply();
        }
    }
}

control IngressFabric_downlink(
        inout switch_ingress_metadata_t ig_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm,
        inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr,
        inout switch_header_t hdr) {

    action fabric_base_decap() {
        ig_md.common.pkt_type = hdr.fabric_base.pkt_type;
        ig_md.common.is_mirror = hdr.fabric_base.is_mirror;
        ig_md.common.is_mcast = hdr.fabric_base.is_mcast;
    }

    action fabric_qos_decap() {
        ig_md.qos.tc = hdr.fabric_qos.tc;
        ig_md.qos.color = hdr.fabric_qos.color;
        ig_md.qos.chgDSCP_disable = hdr.fabric_qos.chgDSCP_disable;
        ig_md.qos.BA = hdr.fabric_qos.BA;
        ig_md.common.track = hdr.fabric_qos.track;
    }

    action terminate_unicast() {
        fabric_base_decap();
        fabric_qos_decap();
        ig_md.qos.pcp = hdr.fabric_unicast_ext_eg.pcp;
        ig_md.tunnel.next_hdr_type = hdr.fabric_unicast_ext_eg.next_hdr_type;
        // ig_md.common.dst_port = hdr.fabric_unicast_ext_eg.dst_port;
        // ig_md.common.l2_encap = hdr.fabric_unicast_ext_eg.l2_encap;
        ig_md.tunnel.ptag_igmod = hdr.fabric_unicast_ext_eg.ptag_igmod;
        ig_md.common.oif = hdr.fabric_unicast_ext_eg.oif;
        ig_md.common.iif = hdr.fabric_one_pad.iif;
    }

    action terminate_multicast() {
        fabric_base_decap();
        fabric_qos_decap();
        ig_md.qos.pcp = hdr.fabric_unicast_ext_eg.pcp;
        ig_md.tunnel.next_hdr_type = hdr.fabric_unicast_ext_eg.next_hdr_type;
        // ig_md.common.dst_port = hdr.fabric_unicast_ext_eg.dst_port;
        // ig_md.common.l2_encap = hdr.fabric_unicast_ext_eg.l2_encap;
        ig_md.tunnel.ptag_igmod = hdr.fabric_unicast_ext_eg.ptag_igmod;
        ig_md.common.oif = hdr.fabric_unicast_ext_eg.oif;
        ig_md.common.iif = hdr.fabric_one_pad.iif;
    }

    table fabric_ingress_decap {
        key = {
            hdr.fabric_base.is_mcast : exact;
        }

        actions = {
            NoAction;
            terminate_unicast;
            terminate_multicast;
        }

        const default_action = NoAction;
        size = 2;
        // const entries = {
        //     (0) : terminate_unicast();
        //     (1) : terminate_multicast();
        // }
    }

    apply {
        fabric_ingress_decap.apply();
    }
}

/*****************************************************************************/
/* Fabric SN generator                                                       */
/*****************************************************************************/
control Fabric_selector_sn(
    inout switch_ingress_metadata_t ig_md) {

    const bit<16> max_prr_sn = 128;
    const bit<32> prr_sn_size = 10;
    Register<bit<16>, bit<16>>(prr_sn_size, 0) reg_prr_sn;
    RegisterAction<bit<16>, bit<16>, bit<16>>(reg_prr_sn) gen_prr_sn = {
        void apply(inout bit<16> reg, out bit<16> rv) {
            if (reg < max_prr_sn) {
                reg = reg + 1;
                rv = reg;
            } else {
                reg = 1;
                rv = reg;
            }
        }
    };

    action use_prr_sn() {
        ig_md.common.hash[15:0] = gen_prr_sn.execute(0);
    }

    table packet_round_robin {
        key = {
            ig_md.common.prr_enable : exact;
        }
        actions = {
            NoAction;
            use_prr_sn;
        }
        size = 2;
        const entries = {
            (true) : use_prr_sn();
            (false) : NoAction();
        }
    }

    action set_prr_enable(bool enable) {
        ig_md.common.prr_enable = enable;
    }

    table check_prr_enable {
        // keyless
        actions = {
            set_prr_enable;
        }

        size = 1;
    }

    apply {
        check_prr_enable.apply();
        packet_round_robin.apply();
    }
}

control FabricLag_Common_IGFPGA(
    in switch_header_t hdr,
    inout switch_ingress_metadata_t ig_md,
    out switch_port_t egress_port) {
    Hash<switch_uint8_t>(HashAlgorithm_t.IDENTITY) selector_hash;
    ActionSelector(128, selector_hash, SelectorMode_t.FAIR) fabric_lag_selector;// 24+7*2

    action set_fabric_lag_port(switch_port_t port) {
        egress_port = port;
        ig_md.common.dev_port = port;
    }

    @pragma selector_enable_scramble 0
    @stage(3)
    table fabric_lag {
        key = {
            ig_md.common.dst_device : exact;
            ig_md.common.hash : selector;
        }

        actions = {
            NoAction;
            set_fabric_lag_port;
        }

        const default_action = NoAction;
        size = 128;
        implementation = fabric_lag_selector;
    }

    apply {
        fabric_lag.apply();
    }
}

/*****************************************************************************/
/* Fabric LAG resolution                                                     */
/*****************************************************************************/
control FabricLag(
    in switch_header_t hdr,
    inout switch_ingress_metadata_t ig_md,
    inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm,
    inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr) {
    Hash<switch_uint8_t>(HashAlgorithm_t.IDENTITY) selector_hash;
    ActionSelector(128, selector_hash, SelectorMode_t.FAIR) fabric_lag_selector;// 24+7*2

    action set_fabric_lag_port(switch_port_t port) {
        ig_intr_md_for_tm.ucast_egress_port = port;
        ig_md.common.dev_port = port;
    }

    @pragma selector_enable_scramble 0
    table fabric_lag {
        key = {
            ig_md.common.dst_device : exact;
            ig_md.common.hash : selector;
        }

        actions = {
            NoAction;
            set_fabric_lag_port;
        }

        const default_action = NoAction;
        size = 128;
        implementation = fabric_lag_selector;
    }

    action redirect_to_eth() {
        ;
    }
    action redirect_to_pcie() {
        // ig_md.flags.bypass_fabric_lag = 1;
        ig_intr_md_for_tm.ucast_egress_port = 320;
    }
    action copy_to_pcie() {
        ig_intr_md_for_tm.copy_to_cpu = 1;
    }
    action hard_drop() {
        ig_intr_md_for_dprsr.drop_ctl = 0x1;
    }
    table cpu_fwd {
        key = {
            ig_md.flags.is_gleaned : exact;
            ig_md.flags.glean : exact;
            ig_md.flags.drop : exact;
            ig_md.flags.is_eth : exact;
        }
        actions = {
            redirect_to_eth;
            redirect_to_pcie;
            copy_to_pcie;
            hard_drop;
        }
        const entries = {
            (1, 1, 1, 1) : redirect_to_eth();
            (1, 1, 1, 0) : redirect_to_pcie();
            (1, 1, 0, 1) : redirect_to_eth();
            (1, 1, 0, 0) : copy_to_pcie();
            (1, 0, 1, 1) : hard_drop();
            (1, 0, 1, 0) : hard_drop();
            (0, 0, 1, 1) : hard_drop();
            (0, 0, 1, 0) : hard_drop();
        }
    }

    apply {
        switch(cpu_fwd.apply().action_run) {
            redirect_to_pcie : {}
            default : {
                if (ig_md.flags.bypass_fabric_lag == 0) {
                    fabric_lag.apply();
                }
            }
        }

    }
}

/*****************************************************************************/
/* Fabric LAG resolution                                                     */
/*****************************************************************************/
control FabricLag_IGFPGA(
    in switch_header_t hdr,
    inout switch_ingress_metadata_t ig_md,
    in bit<16> hash,
    out switch_port_t egress_port) {
    Hash<switch_uint8_t>(HashAlgorithm_t.IDENTITY) selector_hash;
    ActionSelector(128, selector_hash, SelectorMode_t.FAIR) fabric_lag_selector;// 24+7*2

    action set_fabric_lag_port(switch_port_t port) {
        egress_port = port;
        ig_md.common.dev_port = port;
        ig_md.route.rmac_hit = 1w1;
    }

    @pragma selector_enable_scramble 0
    table fabric_lag {
        key = {
            ig_md.common.dst_device : exact;
            hash : selector;
        }

        actions = {
            NoAction;
            set_fabric_lag_port;
        }

        const default_action = NoAction;
        size = 128;
        implementation = fabric_lag_selector;
    }

    apply {
        fabric_lag.apply();
    }
}

/*****************************************************************************/
/* Fabric LAG resolution                                                     */
/*****************************************************************************/
control FabricLag_PCIE(
    in switch_header_t hdr,
    inout switch_ingress_metadata_t ig_md,
    in bit<16> hash,
    out switch_port_t egress_port) {
    Hash<switch_uint8_t>(HashAlgorithm_t.IDENTITY) selector_hash;
    ActionSelector(128, selector_hash, SelectorMode_t.FAIR) fabric_lag_selector;// 24+7*2

    action set_fabric_lag_port(switch_port_t port) {
        egress_port = port;
        ig_md.common.dev_port = port;
    }

    @pragma selector_enable_scramble 0
    table fabric_lag {
        key = {
            ig_md.common.dst_device : exact;
            hash : selector;
        }

        actions = {
            NoAction;
            set_fabric_lag_port;
        }

        const default_action = NoAction;
        size = 128;
        implementation = fabric_lag_selector;
    }

    apply {
        fabric_lag.apply();
    }
}

/*****************************************************************************/
/* Fabric LAG resolution                                                     */
/*****************************************************************************/
control FabricDLBLag(
    in switch_header_t hdr,
    inout switch_ingress_metadata_t ig_md,
    in bit<16> hash,
    out switch_port_t egress_port) {
    Hash<switch_uint16_t>(HashAlgorithm_t.IDENTITY) selector_hash;
    ActionSelector(128, selector_hash, SelectorMode_t.FAIR) fabric_lag_selector;// 24+7*2

    action set_fabric_lag_port(switch_port_t port) {
        egress_port = port;
        ig_md.common.dev_port = port;
    }

    @pragma selector_enable_scramble 0
    table fabric_lag {
        key = {
            ig_md.common.dst_device : exact;
            hash : selector;
        }

        actions = {
            NoAction;
            set_fabric_lag_port;
        }

        const default_action = NoAction;
        size = 128;
        implementation = fabric_lag_selector;
    }

    apply {
        fabric_lag.apply();
    }
}

control FabricDLBLag_Elephant(
    in switch_header_t hdr,
    inout switch_ingress_metadata_t ig_md,
    in bit<16> fqid,
    out switch_port_t egress_port) {
    Hash<switch_uint16_t>(HashAlgorithm_t.IDENTITY) selector_hash;
    ActionSelector(128, selector_hash, SelectorMode_t.FAIR) fabric_lag_selector;// 24+7*2

    action set_fabric_lag_port(switch_port_t port) {
        egress_port = port;
        ig_md.common.dev_port = port;
    }

    @pragma selector_enable_scramble 0
    table fabric_lag {
        key = {
            ig_md.common.dst_device : exact;
            fqid : selector;
        }

        actions = {
            NoAction;
            set_fabric_lag_port;
        }

        const default_action = NoAction;
        size = 128;
        implementation = fabric_lag_selector;
    }

    apply {
        fabric_lag.apply();
    }
}

control FabricCCM_front(
    in switch_header_t hdr,
    inout switch_ingress_metadata_t ig_md,
    out switch_port_t egress_port) {

    action set_fabric_ccm_port() {
        egress_port = hdr.fabric_from_cpu_eth_ccm.dev_port;
        ig_md.common.dev_port = hdr.fabric_from_cpu_eth_ccm.dev_port;
    }

    table fabric_ccm {
        key = {
            hdr.fabric_from_cpu_eth_ccm.isValid() : exact @name("ccm_is_valid");
            hdr.fabric_from_cpu_eth_base.pkt_type : exact @name("pkt_type");
        }

        actions = {
            NoAction;
            set_fabric_ccm_port;
        }

        const default_action = NoAction;
        size = 8;
    }

    apply {
        fabric_ccm.apply();
    }
}

control FabricCCM_uplink(
    in switch_header_t hdr,
    inout switch_ingress_metadata_t ig_md,
    out switch_port_t egress_port) {

    action set_fabric_ccm_port() {
        egress_port = hdr.fabric_from_cpu_eth_ccm.dev_port;
        ig_md.common.dev_port = hdr.fabric_from_cpu_eth_ccm.dev_port;
    }

    table fabric_ccm {
        key = {
            hdr.fabric_from_cpu_eth_ccm.isValid() : exact @name("ccm_is_valid");
            hdr.fabric_base.pkt_type : exact @name("pkt_type");
        }

        actions = {
            NoAction;
            set_fabric_ccm_port;
        }

        const default_action = NoAction;
        size = 8;
    }

    apply {
        fabric_ccm.apply();
    }
}

control FabricCCM_fabric(
    in switch_header_t hdr,
    inout switch_ingress_metadata_t ig_md,
    out switch_port_t egress_port,
    inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm) {

    action set_fabric_ccm_port() {
        egress_port = hdr.fabric_from_cpu_eth_ccm.dev_port;
        ig_md.common.dev_port = hdr.fabric_from_cpu_eth_ccm.dev_port;
    }

    action set_drop() {
        ig_intr_md_for_tm.ucast_egress_port = SWITCH_PORT_INVALID;
    }

    table fabric_ccm {
        key = {
            hdr.fabric_from_cpu_eth_ccm.isValid() : exact @name("ccm_is_valid");
            ig_md.common.pkt_type : exact @name("pkt_type");
            ig_md.common.is_mcast : exact @name("is_mcast");
        }

        actions = {
            NoAction;
            set_fabric_ccm_port;
            set_drop;
        }

        const default_action = NoAction;
        size = 8;
    }

    apply {
        fabric_ccm.apply();
    }
}

control FabricCCM_downlink(
    in switch_header_t hdr,
    inout switch_ingress_metadata_t ig_md,
    out switch_port_t egress_port) {

    action set_fabric_ccm_port() {
        egress_port = hdr.fabric_from_cpu_eth_ccm.dev_port;
        ig_md.common.dev_port = hdr.fabric_from_cpu_eth_ccm.dev_port;
    }

    table fabric_ccm {
        key = {
            hdr.fabric_from_cpu_eth_ccm.isValid() : exact @name("ccm_is_valid");
            ig_md.common.pkt_type : exact @name("pkt_type");
        }

        actions = {
            NoAction;
            set_fabric_ccm_port;
        }

        const default_action = NoAction;
        size = 8;
    }

    apply {
        fabric_ccm.apply();
    }
}

control CCM_Queue(inout switch_header_t hdr,
        inout switch_ingress_metadata_t ig_md)
        (switch_uint32_t queue_table_size = 32) {

    action set_ccm_qos(switch_tc_t tc, switch_pkt_color_t color) {
        ig_md.qos.tc = tc;
        ig_md.qos.color = color;
    }
    // @ignore_table_dependency("Ig_front.qos_resolve.tc_resolve")
    table ccm_qos_map {
        key = {
            hdr.fabric_from_cpu_eth_base.qid: exact @name("qid");
            hdr.fabric_from_cpu_eth_ccm.isValid() : exact @name("ccm_is_valid");
        }

        actions = {
            NoAction;
            set_ccm_qos;
        }

        const default_action = NoAction;
        size = queue_table_size;
    }

    apply {
        ccm_qos_map.apply();
    }
}

control CCM_Dev_Port_Mapping(
        in switch_header_t hdr,
        inout switch_egress_metadata_t eg_md
        )(switch_uint32_t table_size = 512) {

    action set_dst_port(switch_logic_port_t dst_port) {
        eg_md.common.dst_port = dst_port;
    }

    table ccm_dev_port_map_dst_port{
        key = {
            eg_md.common.pkt_type : exact @name("pkt_type");
            hdr.fabric_from_cpu_eth_ccm.isValid() : exact @name("ccm_is_valid");
            hdr.fabric_from_cpu_eth_ccm.dev_port : exact @name("dev_port");
        }
        actions = {
            NoAction;
            set_dst_port;
        }
        const default_action = NoAction;
        size = table_size;
    }
    apply {
        ccm_dev_port_map_dst_port.apply();
    }
}

/* by zhangjunjie */
control CCM_rid_drop(
        in egress_intrinsic_metadata_t eg_intr_md,
        inout switch_egress_metadata_t eg_md,
        inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr) {

    action drop_by_rid() {
        eg_intr_md_for_dprsr.drop_ctl = 0x1;
    }

    action forward() {
    }

    table rid_attribute {
        key = {
            eg_md.common.pkt_type : exact @name("pkt_type");
            eg_md.common.is_mcast : exact @name("is_mcast");
            eg_intr_md.egress_rid[13:0] : exact @name("rid");
        }
        actions = {
            NoAction;
            drop_by_rid;
            forward;
        }
        const default_action = NoAction;
        size = 32;
    }

    apply {

        rid_attribute.apply();

    }
}

/*****************************************************************************/
/* Fabric rewrite actions                                                    */
/*****************************************************************************/
action fabric_base_uc_encap(
        inout switch_header_t hdr,
        switch_pkt_type_t pkt_type) {
        hdr.fabric_base.setValid();
        hdr.fabric_base.pkt_type = pkt_type;
        hdr.fabric_base.is_mirror = 0;
        hdr.fabric_base.is_mcast = 0;
}

action fabric_base_mc_encap(
        inout switch_header_t hdr,
        switch_pkt_type_t pkt_type) {
        hdr.fabric_base.setValid();
        hdr.fabric_base.pkt_type = pkt_type;
        hdr.fabric_base.is_mirror = 0;
        hdr.fabric_base.is_mcast = 1;
}

action fabric_base_mirror_encap(
        inout switch_header_t hdr,
        switch_pkt_type_t pkt_type) {
        hdr.fabric_base.setValid();
        hdr.fabric_base.pkt_type = pkt_type;
        hdr.fabric_base.is_mirror = 1;
        hdr.fabric_base.is_mcast = 0;
}

control Extension_Tunnel_Decap(
        inout switch_header_t hdr,
        inout switch_egress_metadata_t eg_md){

    action ext_len_word_1(){
        eg_md.common.ext_len = 1;
    }

    table extension_tunnel_decap{
        key = {
            hdr.ext_tunnel_decap.isValid() : exact;
        }
        actions = {
            ext_len_word_1;
            NoAction;
        }
        size = 2;
        // const entries = {
        //     (true) : ext_len_word_1();
        //     (false) : NoAction();
        // }
    }

    apply {
        extension_tunnel_decap.apply();
    }
}

control FabricRewritePadding(
        inout switch_header_t hdr,
        inout switch_egress_metadata_t eg_md,
        in egress_intrinsic_metadata_t eg_intr_md) {

    action padding_one_word() {
        eg_md.common.extend = 1;
        eg_md.common.ext_len = 1;
        hdr.ext_padding_word.setValid();
        hdr.ext_padding_word.ext_type = BRIDGED_MD_EXT_TYPE_PADDING_WORD;
        hdr.ext_padding_word.extend = 0;
    }

    table fabric_rewrite_padding {
        key = {
            eg_intr_md.pkt_length : exact;
            hdr.vlan_tag[0].isValid() : exact;
            hdr.vlan_tag[1].isValid() : exact;
            eg_md.common.pkt_type : exact;
        }

        actions = {
            NoAction;
            padding_one_word;
        }

        const default_action = NoAction;
        size = 128;
        const entries = {
            (64, true, false, FABRIC_PKT_TYPE_ETH) : padding_one_word();//base uc
            (65, true, false, FABRIC_PKT_TYPE_ETH) : padding_one_word();//base uc
            (66, true, false, FABRIC_PKT_TYPE_ETH) : padding_one_word();//base uc
            (67, true, false, FABRIC_PKT_TYPE_ETH) : padding_one_word();//base uc
            (64, true, false, FABRIC_PKT_TYPE_MPLS) : padding_one_word();//mpls lsr
            (65, true, false, FABRIC_PKT_TYPE_MPLS) : padding_one_word();//mpls lsr
            (66, true, false, FABRIC_PKT_TYPE_MPLS) : padding_one_word();//mpls lsr
            (67, true, false, FABRIC_PKT_TYPE_MPLS) : padding_one_word();//mpls lsr
            (68, true, true, FABRIC_PKT_TYPE_ETH) : padding_one_word();//base uc
            (69, true, true, FABRIC_PKT_TYPE_ETH) : padding_one_word();//base uc
            (70, true, true, FABRIC_PKT_TYPE_ETH) : padding_one_word();//base uc
            (71, true, true, FABRIC_PKT_TYPE_ETH) : padding_one_word();//base uc
            (68, true, true, FABRIC_PKT_TYPE_MPLS) : padding_one_word();//mpls lsr
            (69, true, true, FABRIC_PKT_TYPE_MPLS) : padding_one_word();//mpls lsr
            (70, true, true, FABRIC_PKT_TYPE_MPLS) : padding_one_word();//mpls lsr
            (71, true, true, FABRIC_PKT_TYPE_MPLS) : padding_one_word();//mpls lsr
        }
    }

    apply {
        if (eg_md.common.is_mcast == 0 && eg_md.route.rmac_hit == 1 && hdr.ext_tunnel_decap.isValid() == false) {
            fabric_rewrite_padding.apply();
        }
    }
}

control FabricRewrite_uplink(
        inout switch_header_t hdr,
        inout switch_egress_metadata_t eg_md,
        in egress_intrinsic_metadata_t eg_intr_md) {

    Hash<bit<8>>(HashAlgorithm_t.IDENTITY) hash_flags_pv;
    Hash<bit<8>>(HashAlgorithm_t.IDENTITY) hash_nh_option_pv;
    Hash<bit<16>>(HashAlgorithm_t.IDENTITY) hash_16_pv;

    action fabric_qos_encap() {
        hdr.fabric_qos.setValid();
        hdr.fabric_qos.tc = eg_md.qos.tc;
        hdr.fabric_qos.color = eg_md.qos.color;
        hdr.fabric_qos.chgDSCP_disable = eg_md.qos.chgDSCP_disable;
        hdr.fabric_qos.BA = eg_md.qos.BA;
        hdr.fabric_qos.track = eg_md.common.track;
    }

    action fabric_unicast(switch_pkt_type_t pkt_type) {
        // base
        fabric_base_uc_encap(hdr, pkt_type);
        // qos
        fabric_qos_encap();
        // fabric_unicast_ext_bfn_igfpga
        hdr.fabric_unicast_ext_bfn_igfpga.setValid();
        hdr.fabric_unicast_ext_bfn_igfpga.flags = hash_flags_pv.get({
            eg_md.common.extend +++
            1w0 +++
            eg_md.route.is_ecmp +++
            eg_md.route.disable_urpf +++
            eg_md.flags.glean +++
            eg_md.flags.drop +++
            eg_md.flags.escape_etm +++
            eg_md.common.svi_flag});
        hdr.fabric_unicast_ext_bfn_igfpga.nh_option = hash_nh_option_pv.get({
            eg_md.common.ext_len +++
            eg_md.common.service_class +++
            eg_md.route.level});
        hdr.fabric_unicast_ext_bfn_igfpga.cpu_reason = eg_md.common.cpu_reason;
        hdr.fabric_unicast_ext_bfn_igfpga.src_port = eg_md.common.src_port;
        hdr.fabric_unicast_ext_bfn_igfpga.nexthop = eg_md.common.nexthop;
        hdr.fabric_unicast_ext_bfn_igfpga.hash = eg_md.common.hash[15:0];
        // one pad
        hdr.fabric_one_pad.setValid();
        hdr.fabric_one_pad.one = 1w1;
        hdr.fabric_one_pad.iif = eg_md.common.iif;
    }

    action fabric_unicast_eth() {
        fabric_unicast(FABRIC_PKT_TYPE_ETH);
        // fabric_var_ext_1_16bit
        hdr.fabric_var_ext_1_16bit.setValid();
        // eth ext
        hdr.fabric_eth_ext_encap.setValid();
        hdr.fabric_eth_ext_encap.evlan = eg_md.ebridge.evlan;
        hdr.fabric_eth_ext_encap.data = (bit<16>)eg_md.ebridge.l2oif;
        // hdr.fabric_eth_ext_encap.data = hash_16_pv.get({
        //     eg_md.flags.learning +++ 
        //     1w0 +++
        //     eg_md.ebridge.l2oif});
    }

    action fabric_unicast_ipv4() {
        fabric_unicast(FABRIC_PKT_TYPE_IPV4);
        // fabric_var_ext_2_8bit
        hdr.fabric_var_ext_2_8bit.setValid();
        hdr.fabric_var_ext_2_8bit.data_hi = eg_md.route.dip_l3class_id;
        hdr.fabric_var_ext_2_8bit.data_lo = eg_md.route.priority;
        // overlap with ethernet
        hdr.ethernet.setInvalid();
        hdr.vlan_tag[0].setInvalid();
        hdr.vlan_tag[1].setInvalid();
    }

    action fabric_unicast_ipv6() {
        fabric_unicast(FABRIC_PKT_TYPE_IPV6);
        // fabric_var_ext_2_8bit
        hdr.fabric_var_ext_2_8bit.setValid();
        hdr.fabric_var_ext_2_8bit.data_hi = eg_md.route.dip_l3class_id;
        hdr.fabric_var_ext_2_8bit.data_lo = eg_md.route.priority;
        // overlap with ethernet
        hdr.ethernet.setInvalid();
        hdr.vlan_tag[0].setInvalid();
        hdr.vlan_tag[1].setInvalid();
    }

    action fabric_unicast_mpls() {
        fabric_unicast(FABRIC_PKT_TYPE_MPLS);
        // fabric_var_ext_1_16bit
        hdr.fabric_var_ext_1_16bit.setValid();
        hdr.fabric_var_ext_1_16bit.data = 0;
        // overlap with ethernet
        hdr.ethernet.setInvalid();
    }

    action fabric_ipfix_spec_v4() {
        fabric_unicast(FABRIC_PKT_TYPE_IPFIX_SPEC_V4);
        // fabric_var_ext_2_8bit
        hdr.fabric_var_ext_2_8bit.setValid();
        hdr.fabric_var_ext_2_8bit.data_hi = eg_md.route.dip_l3class_id;
        hdr.fabric_var_ext_2_8bit.data_lo = eg_md.route.priority;
        // overlap with ethernet
        hdr.ethernet.setInvalid();
        hdr.vlan_tag[0].setInvalid();
    }

    action fabric_ipfix_spec_v6() {
        fabric_unicast(FABRIC_PKT_TYPE_IPFIX_SPEC_V6);
        // fabric_var_ext_2_8bit
        hdr.fabric_var_ext_2_8bit.setValid();
        hdr.fabric_var_ext_2_8bit.data_hi = eg_md.route.dip_l3class_id;
        hdr.fabric_var_ext_2_8bit.data_lo = eg_md.route.priority;
        // overlap with ethernet
        hdr.ethernet.setInvalid();
        hdr.vlan_tag[0].setInvalid();
    }

    action fabric_multicast_rewrite(switch_pkt_type_t pkt_type) {
        // base
        fabric_base_mc_encap(hdr, pkt_type);
        // qos
        fabric_qos_encap();
        // fabric_unicast_ext_bfn_igfpga
        hdr.fabric_unicast_ext_bfn_igfpga.setValid();
        hdr.fabric_unicast_ext_bfn_igfpga.flags = hash_flags_pv.get({
            eg_md.common.extend +++
            1w0 +++
            eg_md.route.is_ecmp +++
            eg_md.route.disable_urpf +++
            eg_md.flags.glean +++
            eg_md.flags.drop +++
            eg_md.flags.escape_etm +++
            eg_md.common.svi_flag});
        hdr.fabric_unicast_ext_bfn_igfpga.nh_option = hash_nh_option_pv.get({
            eg_md.common.ext_len +++
            eg_md.common.service_class +++
            eg_md.route.level});
        hdr.fabric_unicast_ext_bfn_igfpga.cpu_reason = eg_md.common.cpu_reason;
        hdr.fabric_unicast_ext_bfn_igfpga.src_port = eg_md.common.src_port;
        hdr.fabric_unicast_ext_bfn_igfpga.nexthop = eg_md.common.nexthop;
        hdr.fabric_unicast_ext_bfn_igfpga.hash = eg_md.common.hash[15:0];
        // fabric_var_ext_1_16bit
        hdr.fabric_var_ext_1_16bit.setValid();
        // one pad
        hdr.fabric_one_pad.setValid();
        hdr.fabric_one_pad.one = 1w1;
        hdr.fabric_one_pad.iif = eg_md.common.iif;
    }

    action fabric_multicast_eth() {
        fabric_multicast_rewrite(FABRIC_PKT_TYPE_ETH);
        // eth ext
        hdr.fabric_eth_ext_encap.setValid();
        hdr.fabric_eth_ext_encap.evlan = eg_md.ebridge.evlan;
        hdr.fabric_eth_ext_encap.data = (bit<16>)eg_md.ebridge.l2oif;
        // hdr.fabric_eth_ext_encap.data = hash_16_pv.get({
        //     eg_md.flags.learning +++ 
        //     1w0 +++
        //     eg_md.ebridge.l2oif});        
    }

    action fabric_multicast_ipv4() {
        fabric_multicast_rewrite(FABRIC_PKT_TYPE_IPV4);
        // keep vlan tag for mcast packet until mc fwd
        // hdr.vlan_tag[0].setInvalid();
        // hdr.vlan_tag[1].setInvalid();
        // hdr.ethernet.ether_type = ETHERTYPE_IPV4;
    }

    action fabric_multicast_ipv6() {
        fabric_multicast_rewrite(FABRIC_PKT_TYPE_IPV6);
        // keep vlan tag for mcast packet until mc fwd
        // hdr.vlan_tag[0].setInvalid();
        // hdr.vlan_tag[1].setInvalid();
        // hdr.ethernet.ether_type = ETHERTYPE_IPV6;
    }

    action fabric_recirc_uc() {
        fabric_base_uc_encap(hdr, eg_md.common.pkt_type);
        fabric_qos_encap();
        hdr.fabric_unicast_ext_bfn_igfpga.setValid();
        hdr.fabric_unicast_ext_bfn_igfpga.flags = 0;
        hdr.fabric_unicast_ext_bfn_igfpga.nh_option = 0;
        hdr.fabric_unicast_ext_bfn_igfpga.cpu_reason = 0;
        hdr.fabric_unicast_ext_bfn_igfpga.src_port = 0;
        hdr.fabric_unicast_ext_bfn_igfpga.nexthop = 0;
        hdr.fabric_unicast_ext_bfn_igfpga.hash = eg_md.common.hash[15:0];
        hdr.fabric_var_ext_1_16bit.setValid();
        hdr.fabric_var_ext_1_16bit.data = eg_md.common.egress_eport;
        hdr.fabric_one_pad.setValid();
        hdr.fabric_one_pad.one = 1w1;
        hdr.fabric_one_pad.iif = eg_md.common.iif;
    }

    action fabric_eop_rewrite() {
        fabric_base_uc_encap(hdr, eg_md.common.pkt_type);
        fabric_qos_encap();
        hdr.fabric_unicast_ext_bfn_igfpga.setValid();
        hdr.fabric_unicast_ext_bfn_igfpga.flags = 0;
        hdr.fabric_unicast_ext_bfn_igfpga.nh_option = 0;
        hdr.fabric_unicast_ext_bfn_igfpga.cpu_reason = 0;
        hdr.fabric_unicast_ext_bfn_igfpga.src_port = 0;
        hdr.fabric_unicast_ext_bfn_igfpga.nexthop = 0;
        hdr.fabric_unicast_ext_bfn_igfpga.hash = eg_md.common.hash[15:0];
        hdr.fabric_var_ext_1_16bit.setValid();
        hdr.fabric_var_ext_1_16bit.data = eg_md.common.egress_eport;
        hdr.fabric_one_pad.setValid();
        hdr.fabric_one_pad.one = 1w1;
        hdr.fabric_one_pad.iif = eg_md.common.iif;
    }

    action fabric_unicast_ccm() {
        fabric_base_uc_encap(hdr, eg_md.common.pkt_type);
        fabric_qos_encap();
        hdr.fabric_unicast_ext_bfn_igfpga.setValid();
        hdr.fabric_var_ext_1_16bit.setValid();
        hdr.fabric_one_pad.setValid();
        hdr.fabric_one_pad.one = 1w1;
        hdr.ethernet.setInvalid();
    }

    /* by zhangjunjie */
    action fabric_multicast_ccm() {
        fabric_base_mc_encap(hdr, eg_md.common.pkt_type);
        fabric_qos_encap();
        hdr.fabric_unicast_ext_bfn_igfpga.setValid();
        hdr.fabric_var_ext_1_16bit.setValid();
        hdr.fabric_one_pad.setValid();
        hdr.fabric_one_pad.one = 1w1;
        hdr.ethernet.setInvalid();
    }
    @stage(11)
    table fabric_rewrite {
        key = {
            eg_md.common.pkt_type : ternary;
            eg_md.common.is_mcast : ternary;
            eg_md.route.rmac_hit : ternary;
            hdr.ipv4.isValid(): ternary;
            hdr.ipv6.isValid(): ternary;
            eg_md.lkp.pkt_type : ternary;
            eg_md.flags.dmac_miss : ternary;
            eg_md.flags.nd_flag : ternary;
        }

        actions = {
            NoAction;
            fabric_unicast_eth;
            fabric_unicast_ipv4;
            fabric_unicast_ipv6;
            fabric_unicast_mpls;
            fabric_ipfix_spec_v4;
            fabric_ipfix_spec_v6;
            fabric_multicast_eth;
            fabric_multicast_ipv4;
            fabric_multicast_ipv6;
            fabric_recirc_uc;
            fabric_eop_rewrite;
            fabric_unicast_ccm;
            /* by zhangjunjie */
            fabric_multicast_ccm;
        }

        const default_action = NoAction;
        size = 128;
        // TODO, Move to SDK CONFIG
        const entries = {
            (FABRIC_PKT_TYPE_ETH, 1, _, true, false, FABRIC_PKT_TYPE_MCAST, _ , _) : fabric_multicast_ipv4();// ipmc v4
            (FABRIC_PKT_TYPE_ETH, 1, _, false, true, FABRIC_PKT_TYPE_MCAST, _ , _) : fabric_multicast_ipv6();// ipmc v6
            (FABRIC_PKT_TYPE_ETH, 0, 1, true, false, _, _ , _) : fabric_unicast_ipv4();//base uc, vxlan l3 decap
            (FABRIC_PKT_TYPE_ETH, 0, 1, false, true, _, _ , 0) : fabric_unicast_ipv6();//base uc, vxlan l3 decap
            (FABRIC_PKT_TYPE_ETH, 0, 1, false, true, _, _ , 1) : fabric_unicast_eth();//nd 
            (FABRIC_PKT_TYPE_ETH, 0, 1, false, false, _, _ , _) : fabric_unicast_eth();//arp
            (FABRIC_PKT_TYPE_IPV4, 0, 1, _, _, _, _ , _) : fabric_unicast_ipv4();//l3vpn decap
            (FABRIC_PKT_TYPE_IPV6, 0, 1, _, _, _, _ , _) : fabric_unicast_ipv6();//l3vpn decap
            (FABRIC_PKT_TYPE_MPLS, 0, 1, _, _, _, _ , _) : fabric_unicast_mpls();//mpls lsr
            (FABRIC_PKT_TYPE_ETH, 0, 0, _, _, _, 1 , _) : fabric_multicast_eth();//l2vpn bc & mc,  arp
            (FABRIC_PKT_TYPE_ETH, 0, 0, _, _, _, 0 , _) : fabric_unicast_eth();//base l2, l2vpn decap, vxlan l2 decap, uc arp
            (FABRIC_PKT_TYPE_IPFIX_SPEC_V4, 0, 1, _, _, _, _ , _) : fabric_ipfix_spec_v4();
            (FABRIC_PKT_TYPE_IPFIX_SPEC_V6, 0, 1, _, _, _, _ , _) : fabric_ipfix_spec_v6();
            (FABRIC_PKT_TYPE_CPU_ETH, 0, 0, _, _, _, _ , _) : fabric_recirc_uc();
            (FABRIC_PKT_TYPE_EOP, 0, 0, _, _, _, _ , _) : fabric_eop_rewrite();
            (FABRIC_PKT_TYPE_CCM, 0, 0, _, _, _, _, _) : fabric_unicast_ccm();
            /* by zhangjunjie */
            (FABRIC_PKT_TYPE_CCM, 1, 0, _, _, _, _, _) : fabric_multicast_ccm();
            //(_, 1, 0, _, _, _) : fabric_multicast_eth();// l2vpn bc
        }
    }

    // action ext_len_word_1() {
    //     eg_md.common.ext_len = 1;
    // }

    // @placement_priority(127)
    // table header_ext_len {
    //     key = {
    //         hdr.ext_tunnel_decap.isValid() : exact;
    //     }

    //     actions = {
    //         NoAction;
    //         ext_len_word_1;
    //     }

    //     const default_action = NoAction;
    //     size = 2;
    //     const entries = {
    //         (true) : ext_len_word_1();
    //     }
    // }

    apply {
        // header_ext_len.apply();
        fabric_rewrite.apply();
    }
}

control FabricSourceLkp(
    inout switch_egress_metadata_t eg_md) {

    action set_src_device(bit<7> src_device) {
        eg_md.common.src_device = src_device;
    }

    table fabric_source_device {
        // keyless
        actions = {
            set_src_device;
        }

        size = 1;
    }

    apply {
        fabric_source_device.apply();
    }
}

control CheckExtend_fabric(
        inout switch_header_t hdr,
        inout switch_egress_metadata_t eg_md) {

    action set_extend_bit() {
        eg_md.common.extend = 1w1;
    }

    table check_extend {
        // keyless
        actions = {
            set_extend_bit;
        }

        const default_action = set_extend_bit();
    }

    apply {
        if (hdr.ext_l4_encap.isValid() || hdr.ext_tunnel_decap.isValid() || hdr.ext_padding_word.isValid()) {
            check_extend.apply();
        }
    }
}

control FabricRewrite_fabric(
        inout switch_header_t hdr,
        inout switch_egress_metadata_t eg_md,
        in egress_intrinsic_metadata_t eg_intr_md) {

    Hash<bit<8>>(HashAlgorithm_t.IDENTITY) hash_flags_pv;
    Hash<bit<16>>(HashAlgorithm_t.IDENTITY) hash_16_pv;

    action fabric_unicast_ext_fe_2_encap() {
        hdr.fabric_unicast_ext_fe_2_encap.setValid();
        hdr.fabric_unicast_ext_fe_2_encap.src_device = eg_md.common.src_device;
        hdr.fabric_unicast_ext_fe_2_encap.flags = hash_flags_pv.get({
            eg_md.flags.is_elephant +++
            eg_md.flags.escape_etm +++
            1w0 +++
            eg_md.flags.is_gleaned +++
            4w0
        });
    }

    action fabric_unicast() {
        fabric_base_uc_encap(hdr, eg_md.common.pkt_type);
        // fabric_qos_encap();
        // reuse header from bridged
        // hdr.fabric_unicast_dst.setValid();
        // hdr.fabric_unicast_dst_encap.extend = eg_md.common.extend;
        // hdr.fabric_unicast_dst_encap.dst_device = eg_md.common.dst_device;
        // hdr.fabric_unicast_dst_encap.dst_port = eg_md.common.dst_port;
        hdr.fabric_unicast_ext_fe_encap.setValid();
        hdr.fabric_unicast_ext_fe_encap.l2_encap = eg_md.common.l2_encap;
        hdr.fabric_unicast_ext_fe_encap.l3_encap = eg_md.common.l3_encap;
        hdr.fabric_unicast_ext_fe_encap.hash = eg_md.common.hash[15:0];
        hdr.fabric_one_pad.setValid();
        hdr.fabric_one_pad.one = 1w1;
        hdr.fabric_one_pad.iif = eg_md.common.iif;
        fabric_unicast_ext_fe_2_encap();
    }

    action fabric_unicast_eth() {
        fabric_unicast();
        hdr.fabric_var_ext_1_16bit.setValid();
        hdr.fabric_var_ext_1_16bit.data = eg_md.ebridge.evlan;
        hdr.fabric_post_one_pad.setValid();
        hdr.fabric_post_one_pad.l2oif = eg_md.ebridge.l2oif;
    }

    action fabric_unicast_ip() {
        fabric_unicast();
        hdr.fabric_var_ext_1_16bit.setValid();
        hdr.fabric_var_ext_1_16bit.data[15:8] = eg_md.route.dip_l3class_id;
        hdr.fabric_var_ext_1_16bit.data[7:0] = eg_md.route.sip_l3class_id;
    }

    action fabric_unicast_ipv4() {
        fabric_unicast_ip();
    }

    action fabric_unicast_ipv6() {
        fabric_unicast_ip();
    }

    action fabric_unicast_mpls() {
        fabric_unicast();
        hdr.fabric_var_ext_1_16bit.setValid();
    }

    action fabric_mirror() {
        fabric_base_mirror_encap(hdr, eg_md.common.pkt_type);
        hdr.fabric_qos.setValid();
        hdr.fabric_qos.tc = 0;
        hdr.fabric_qos.color = SWITCH_METER_COLOR_RED;
        hdr.fabric_qos.chgDSCP_disable = 0;
        hdr.fabric_qos.BA = 0;
        hdr.fabric_qos.track = 0;
        // reuse header from bridged
        // hdr.fabric_unicast_dst.setValid();
        // hdr.fabric_unicast_dst_encap.extend = eg_md.common.extend;
        // hdr.fabric_unicast_dst_encap.dst_device = eg_md.common.dst_device;
        // hdr.fabric_unicast_dst_encap.dst_port = eg_md.common.dst_port;      
        hdr.fabric_unicast_ext_fe_encap.setValid();
        hdr.fabric_unicast_ext_fe_encap.l2_encap = 0;
        hdr.fabric_unicast_ext_fe_encap.l3_encap = 0;
        hdr.fabric_unicast_ext_fe_encap.hash = 0;
        hdr.fabric_var_ext_1_16bit.setValid();
        hdr.fabric_var_ext_1_16bit.data = 0;
        hdr.fabric_one_pad.setValid();
        hdr.fabric_one_pad.one = 1w1;
        hdr.fabric_one_pad.iif = eg_md.common.iif;
        fabric_unicast_ext_fe_2_encap();
    }

    action fabric_cpu_eth() {
        fabric_base_uc_encap(hdr, eg_md.common.pkt_type);
        // fabric_qos_encap();
        // reuse header from bridged
        // hdr.fabric_unicast_dst.setValid();
        // hdr.fabric_unicast_dst_encap.extend = eg_md.common.extend;
        // hdr.fabric_unicast_dst_encap.dst_device = eg_md.common.dst_device;
        // hdr.fabric_unicast_dst_encap.dst_port = eg_md.common.dst_port;
        hdr.fabric_unicast_ext_fe_encap.setValid();
        hdr.fabric_unicast_ext_fe_encap.hash = 0;
        hdr.fabric_var_ext_1_16bit.setValid();
        hdr.fabric_var_ext_1_16bit.data = 0;
        hdr.fabric_one_pad.setValid();
        hdr.fabric_one_pad.one = 1w1;
        hdr.fabric_one_pad.iif = eg_md.common.iif;
        fabric_unicast_ext_fe_2_encap();
    }

    action fabric_eop_rewrite() {
        fabric_base_uc_encap(hdr, eg_md.common.pkt_type);
        // fabric_qos_encap();
        // reuse header from bridged
        // hdr.fabric_unicast_dst.setValid();
        hdr.fabric_unicast_dst.extend = 0;
        hdr.fabric_unicast_ext_fe_encap.setValid();
        hdr.fabric_unicast_ext_fe_encap.l2_encap = 0;
        hdr.fabric_unicast_ext_fe_encap.l3_encap = 0;
        hdr.fabric_unicast_ext_fe_encap.hash = eg_md.common.hash[15:0];
        hdr.fabric_var_ext_1_16bit.setValid();
        hdr.fabric_var_ext_1_16bit.data = 0;
        hdr.fabric_one_pad.setValid();
        hdr.fabric_one_pad.one = 1w1;
        hdr.fabric_one_pad.iif = 0;
        hdr.fabric_unicast_ext_fe_2_encap.setValid();
        hdr.fabric_unicast_ext_fe_2_encap.src_device = eg_md.common.src_device;
        hdr.fabric_unicast_ext_fe_2_encap.flags = 0x80;
        // hdr.fabric_unicast_ext_fe_2_encap.flags = hash_flags_pv.get({
        //     eg_md.flags.is_elephant +++
        //     eg_md.flags.escape_etm +++
        //     1w0 +++
        //     eg_md.flags.is_gleaned +++
        //     4w0
        // });
    }

    action fabric_cpu_pcie() {
        fabric_base_uc_encap(hdr, eg_md.common.pkt_type);
        // fabric_qos_encap();
        // hdr.fabric_multicast_src.setValid();
        // hdr.fabric_multicast_src.extend = 0;
        // hdr.fabric_multicast_src.src_device = 0;
        // hdr.fabric_multicast_src.src_port = 0;
        hdr.fabric_multicast_src_encap.setValid();
        hdr.fabric_multicast_src_encap.data = 0;
        hdr.fabric_multicast_ext.setValid();
        hdr.fabric_one_pad.setValid();
        hdr.fabric_one_pad.one = 1w1;
        hdr.fabric_one_pad.iif = eg_md.common.iif;
        // remove the fake ethernet header
        hdr.ethernet.setInvalid();
    }

    action fabric_multicast_rewrite() {
        hdr.fabric_unicast_dst.setInvalid();
        fabric_base_mc_encap(hdr, eg_md.common.pkt_type);
        // fabric_qos_encap();
        // hdr.fabric_multicast_src.setValid();
        // hdr.fabric_multicast_src.extend = eg_md.common.extend;
        // hdr.fabric_multicast_src.src_device = eg_md.common.src_device;
        // hdr.fabric_multicast_src.src_port = eg_md.common.src_port;
        hdr.fabric_multicast_src_encap.setValid();
        hdr.fabric_multicast_src_encap.data = hash_16_pv.get({
            eg_md.common.extend +++
            eg_md.common.src_device +++
            eg_md.common.src_port
        });
        hdr.fabric_multicast_ext.setValid();
        hdr.fabric_multicast_ext.is_gleaned = eg_md.flags.is_gleaned;
        hdr.fabric_multicast_ext.mgid = 0;
        hdr.fabric_multicast_ext.hash = 0;
        hdr.fabric_multicast_ext.evlan = eg_md.ebridge.evlan;
        hdr.fabric_one_pad.setValid();
        hdr.fabric_one_pad.one = 1w1;
        hdr.fabric_one_pad.iif = eg_md.common.iif;
    }

    action fabric_unicast_ccm() {
        fabric_base_uc_encap(hdr, eg_md.common.pkt_type);
        // fabric_qos_encap();
        // reuse header from bridged
        // hdr.fabric_unicast_dst.setValid();
        // hdr.fabric_unicast_dst_encap.extend = eg_md.common.extend;
        // hdr.fabric_unicast_dst_encap.dst_device = eg_md.common.dst_device;
        // hdr.fabric_unicast_dst_encap.dst_port = eg_md.common.dst_port;
        hdr.fabric_unicast_ext_fe_encap.setValid();
        hdr.fabric_unicast_ext_fe_encap.hash = 0;
        hdr.fabric_var_ext_1_16bit.setValid();
        hdr.fabric_var_ext_1_16bit.data = 0;
        hdr.fabric_one_pad.setValid();
        hdr.fabric_one_pad.one = 1w1;
        hdr.fabric_one_pad.iif = eg_md.common.iif;
        fabric_unicast_ext_fe_2_encap();
    }

    // /* by zhangjunjie */
    // action fabric_multicast_ccm() {
    //     hdr.fabric_unicast_dst.setInvalid();
    //     fabric_base_mc_encap(hdr, eg_md.common.pkt_type);
    //     hdr.fabric_multicast_src_encap.setValid();
    //     hdr.fabric_multicast_ext.setValid();
    //     hdr.fabric_multicast_ext.is_gleaned = 0;
    //     hdr.fabric_multicast_ext.mgid = 0;
    //     hdr.fabric_multicast_ext.hash = 0;
    //     hdr.fabric_multicast_ext.evlan = 0;
    //     hdr.fabric_one_pad.setValid();
    //     hdr.fabric_one_pad.one = 1w1;
    //     hdr.fabric_one_pad.iif = eg_md.common.iif;
    // }

    action fabric_learning() {
        fabric_base_uc_encap(hdr, eg_md.common.pkt_type);
        hdr.fabric_qos.setValid();
        hdr.fabric_qos.tc = 0;
        hdr.fabric_qos.color = SWITCH_METER_COLOR_RED;
        hdr.fabric_qos.chgDSCP_disable = 0;
        hdr.fabric_qos.BA = 0;
        hdr.fabric_qos.track = 0;
        hdr.fabric_unicast_dst.setValid();
        hdr.fabric_unicast_dst.extend = 0;
        hdr.fabric_unicast_dst.dst_device = 0;
        hdr.fabric_unicast_dst.dst_port = 0;
        hdr.fabric_unicast_ext_fe_encap.setValid();
        hdr.fabric_unicast_ext_fe_encap.l2_encap = 0;
        hdr.fabric_unicast_ext_fe_encap.l3_encap = 0;
        hdr.fabric_unicast_ext_fe_encap.hash = 0;
        hdr.fabric_var_ext_1_16bit.setValid();
        hdr.fabric_var_ext_1_16bit.data = eg_md.ebridge.evlan;
        hdr.fabric_one_pad.setValid();
        hdr.fabric_one_pad.one = 1w1;
        hdr.fabric_one_pad.iif = eg_md.common.iif;
    }

    table fabric_rewrite {
        key = {
            eg_md.common.pkt_type : ternary;
            eg_md.common.is_mcast : ternary;
            eg_md.common.is_mirror : ternary;
        }

        actions = {
            NoAction;
            fabric_unicast_eth;
            fabric_unicast_ipv4;
            fabric_unicast_ipv6;
            fabric_unicast_mpls;
            fabric_mirror;
            fabric_cpu_eth;
            fabric_cpu_pcie;
            fabric_multicast_rewrite;
            fabric_eop_rewrite;
            fabric_unicast_ccm;
            // /* by zhangjunjie */
            // fabric_multicast_ccm;
            fabric_learning;
        }

        const default_action = NoAction;
        size = 128;
        const entries = {
            (FABRIC_PKT_TYPE_ETH, 0, 0) : fabric_unicast_eth();
            (FABRIC_PKT_TYPE_IPV4, 0, 0) : fabric_unicast_ipv4();
            (FABRIC_PKT_TYPE_IPV6, 0, 0) : fabric_unicast_ipv6();
            (FABRIC_PKT_TYPE_MPLS, 0, 0) : fabric_unicast_mpls();
            // (FABRIC_PKT_TYPE_MIRROR_TRAN, 0) : fabric_mirror();
            (FABRIC_PKT_TYPE_CPU_ETH, 0, 0) : fabric_cpu_eth();
            (FABRIC_PKT_TYPE_CPU_PCIE, 0, 0) : fabric_cpu_pcie();
            (FABRIC_PKT_TYPE_EOP, 0, 0) : fabric_eop_rewrite();
            // /* by zhangjunjie */
            // (FABRIC_PKT_TYPE_CCM, 1, 0) : fabric_multicast_ccm();
            (_, 1, 0) : fabric_multicast_rewrite();
            (_, 0, 1) : fabric_mirror();
            (FABRIC_PKT_TYPE_CCM, 0, 0) : fabric_unicast_ccm();
            (FABRIC_PKT_TYPE_LEARNING, 0, 0) : fabric_learning();
        }
    }

    action terminate_padding_word_for_l4_encap() {
        hdr.ext_padding_word.setInvalid();
        hdr.ext_l4_encap.extend = 1w0;
    }

    table rewrite_extend {
        // keyless
        actions = {
            terminate_padding_word_for_l4_encap;
        }

        const default_action = terminate_padding_word_for_l4_encap();
    }

    apply {
        fabric_rewrite.apply();
        if (hdr.ext_padding_word.isValid() && hdr.ext_l4_encap.isValid()) {
            rewrite_extend.apply();
        }
    }
}


control FabricRewrite_fabric_cpu(
        inout switch_header_t hdr,
        inout switch_egress_metadata_t eg_md,
        in egress_intrinsic_metadata_t eg_intr_md) {

    Hash<bit<16>>(HashAlgorithm_t.IDENTITY) hash_16_pv;
    Counter<bit<64>, bit<16>>(128, CounterType_t.PACKETS) to_pcie_stats;
    Counter<bit<64>, bit<16>>(2, CounterType_t.PACKETS) to_pcie_all_stats;

    action cpu_pcie_rewrite() {
        hdr.fabric_qos.setInvalid();
        hdr.fabric_unicast_dst.setInvalid();
        hdr.fabric_cpu_pcie_base.setValid();
        hdr.fabric_cpu_pcie_base.cpu_pkt_type = eg_md.common.pkt_type;// use fabric_base.pkt_type when to cpu
        hdr.fabric_cpu_pcie_base.fwd_mode = 0;
        hdr.fabric_cpu_pcie_base.qid = 0;// TODO: SRC DATA FROM CPP
        //hdr.fabric_cpu_pcie_base.pad_qos = 0;
        hdr.fabric_cpu_pcie_base.track = eg_md.common.track;
        // hdr.fabric_multicast_src.setValid();
        // hdr.fabric_multicast_src.extend = eg_md.common.extend;
        // hdr.fabric_multicast_src.src_device = eg_md.common.src_device;
        // hdr.fabric_multicast_src.src_port = eg_md.common.src_port;
        hdr.fabric_multicast_src_encap.setValid();
        hdr.fabric_multicast_src_encap.data = hash_16_pv.get({
            eg_md.common.extend +++
            eg_md.common.src_device +++
            eg_md.common.src_port
        });
        hdr.fabric_to_cpu_data.setValid();
        hdr.fabric_to_cpu_data.sec_acl_drop = eg_md.policer.drop;
        hdr.fabric_to_cpu_data.cpu_reason = eg_md.common.cpu_reason;
        hdr.fabric_to_cpu_data.cpu_code = eg_md.common.cpu_code;
        hdr.fabric_to_cpu_data.evlan = eg_md.ebridge.evlan;
        hdr.pcie_one_pad.setValid();
        hdr.pcie_one_pad.one = 3;
        hdr.pcie_one_pad.iif = eg_md.common.iif;
    }

    action fabric_eth_to_pcie() {
        cpu_pcie_rewrite();
        to_pcie_stats.count(1);
    }

    action fabric_ipv4_to_pcie(mac_addr_t dmac, mac_addr_t smac) {
        cpu_pcie_rewrite();
        hdr.ethernet.setValid();
        hdr.ethernet.dst_addr = dmac;
        hdr.ethernet.src_addr = smac;
        hdr.ethernet.ether_type = 0x0800;
        to_pcie_stats.count(2);
    }

    action fabric_ipv6_to_pcie(mac_addr_t dmac, mac_addr_t smac) {
        cpu_pcie_rewrite();
        hdr.ethernet.setValid();
        hdr.ethernet.dst_addr = dmac;
        hdr.ethernet.src_addr = smac;
        hdr.ethernet.ether_type = 0x86dd;
        to_pcie_stats.count(3);
    }

    action fabric_mpls_to_pcie(mac_addr_t dmac, mac_addr_t smac) {
        cpu_pcie_rewrite();
        hdr.ethernet.setValid();
        hdr.ethernet.dst_addr = dmac;
        hdr.ethernet.src_addr = smac;
        hdr.ethernet.ether_type = 0x8847;
        to_pcie_stats.count(4);
    }

 action fabric_ipmcv4_to_pcie() {
        cpu_pcie_rewrite();
        to_pcie_stats.count(5);
    }

 action fabric_ipmcv6_to_pcie() {
        cpu_pcie_rewrite();
        to_pcie_stats.count(6);
    }

 action fabric_mc_eth_to_pcie() {
        cpu_pcie_rewrite();
        to_pcie_stats.count(7);
    }

    table cpu_rewrite {
        key = {
            eg_md.common.pkt_type : ternary;
   eg_md.common.is_mcast : exact;
        }

        actions = {
            NoAction;
            fabric_eth_to_pcie; // FABRIC_PKT_TYPE_ETH    [FABRIC_PKT_TYPE_ETH,0]
            fabric_ipv4_to_pcie; // FABRIC_PKT_TYPE_IPV4   [FABRIC_PKT_TYPE_IPV4,0]
            fabric_ipv6_to_pcie; // FABRIC_PKT_TYPE_IPV6   [FABRIC_PKT_TYPE_IPV6,0]
            fabric_mpls_to_pcie; // FABRIC_PKT_TYPE_MPLS   [FABRIC_PKT_TYPE_MPLS,0]
   fabric_ipmcv4_to_pcie; // FABRIC_PKT_TYPE_IPV4   [FABRIC_PKT_TYPE_IPV4,1]
            fabric_ipmcv6_to_pcie; // FABRIC_PKT_TYPE_IPV6   [FABRIC_PKT_TYPE_IPV6,1]
   fabric_mc_eth_to_pcie; // l2vpn bc               [_,1]
        }

        const default_action = NoAction;
        size = 32;
    }

 action set_extend_bit() {
        eg_md.common.extend = 1;
        hdr.ext_l4_encap.setInvalid();
        hdr.ext_padding_word.setInvalid();
    }

 action clr_extend_bit() {
        eg_md.common.extend = 0;
        hdr.ext_l4_encap.setInvalid();
        hdr.ext_padding_word.setInvalid();
    }

    table pcie_extend_bit {
        key = {
            hdr.ext_tunnel_decap.isValid() : exact;
        }

        actions = {
            NoAction;
            clr_extend_bit;
            set_extend_bit;
        }

        const default_action = clr_extend_bit;
        size = 8;
        // const entries = {
        //     (false) : clr_extend_bit();
        //     (true) : set_extend_bit();
        // }           
    }

    apply {
        pcie_extend_bit.apply();
        cpu_rewrite.apply();
        to_pcie_all_stats.count(0);
    }
}

control FabricRewriteExtension_downlink(
        inout switch_header_t hdr,
        inout switch_egress_metadata_t eg_md,
        in egress_intrinsic_metadata_t eg_intr_md) {

    action rewrite_extend() {
        hdr.ext_fake.setValid();
        hdr.ext_fake.data1 = eg_md.ebridge.evlan;
    }

    table fabric_rewrite_extension {
        key = {
            eg_md.common.extend_fake : exact;
        }

        actions = {
            NoAction;
            rewrite_extend;
        }

        size = 2;
        // const entries = {
        //     (0) : NoAction();
        //     (1) : rewrite_extend();
        // }
    }

    apply {
        fabric_rewrite_extension.apply();
    }
}

control FabricRewrite_downlink(
        inout switch_header_t hdr,
        inout switch_egress_metadata_t eg_md,
        in egress_intrinsic_metadata_t eg_intr_md) {

    Hash<bit<16>>(HashAlgorithm_t.IDENTITY) hash_combine_pv;
    Hash<bit<16>>(HashAlgorithm_t.IDENTITY) hash_16_pv;

    // action fabric_qos_encap() {
    //     hdr.fabric_qos.setValid();
    //     hdr.fabric_qos.tc = eg_md.qos.tc;
    //     hdr.fabric_qos.color = eg_md.qos.color;
    //     hdr.fabric_qos.chgDSCP_disable = eg_md.qos.chgDSCP_disable;
    //     hdr.fabric_qos.BA = eg_md.qos.BA;
    //     hdr.fabric_qos.track = eg_md.common.track;
    // }

    action fabric_unicast_rewrite() {
        fabric_base_uc_encap(hdr, eg_md.common.pkt_type);
        // fabric_qos_encap();
        hdr.fabric_unicast_ext_eg_encap.setValid();
        hdr.fabric_unicast_ext_eg_encap.combine = hash_combine_pv.get({
            eg_md.tunnel.next_hdr_type +++
            eg_md.qos.pcp +++
            eg_md.flags.is_elephant +++
            2w0 +++
            eg_md.common.dst_port});
        hdr.fabric_unicast_ext_eg_encap.l2_encap = eg_md.common.l2_encap;
        hdr.fabric_unicast_ext_eg_encap.ptag_igmod_oif = hash_16_pv.get({
            eg_md.common.extend_fake +++
            eg_md.tunnel.ptag_igmod +++
            eg_md.common.oif});
        // hdr.fabric_unicast_ext_eg_encap.pkt_len = eg_md.common.pkt_length + eg_md.qos.to_be_add;
        hdr.fabric_unicast_ext_eg_encap.FQID = eg_md.qos.FQID;
        hdr.fabric_one_pad_7.setValid();
        hdr.fabric_one_pad_7.one = 2w3;
        hdr.fabric_one_pad_7.iif = eg_md.common.iif;
    }

    action fabric_mcast_rewrite() {
        fabric_base_mc_encap(hdr, eg_md.common.pkt_type);
        // fabric_qos_encap();
        hdr.fabric_unicast_ext_eg_encap.setValid();
        hdr.fabric_unicast_ext_eg_encap.combine = hash_combine_pv.get({
            eg_md.tunnel.next_hdr_type +++
            eg_md.qos.pcp +++
            eg_md.flags.is_elephant +++
            2w0 +++
            eg_md.common.dst_port});
        hdr.fabric_unicast_ext_eg_encap.l2_encap = eg_md.common.l2_encap;
        hdr.fabric_unicast_ext_eg_encap.ptag_igmod_oif = hash_16_pv.get({
            eg_md.common.extend_fake +++
            eg_md.tunnel.ptag_igmod +++
            eg_md.common.oif});
        // hdr.fabric_unicast_ext_eg_encap.pkt_len = eg_md.common.pkt_length + eg_md.qos.to_be_add;
        hdr.fabric_unicast_ext_eg_encap.FQID = eg_md.qos.FQID;
        hdr.fabric_one_pad_7.setValid();
        hdr.fabric_one_pad_7.one = 2w3;
        hdr.fabric_one_pad_7.iif = eg_md.common.iif;
    }

    action fabric_mcast_rewrite_ipv4() {
        fabric_mcast_rewrite();
        hdr.inner_ethernet.setInvalid();
    }

    action fabric_mcast_rewrite_ipv6() {
        fabric_mcast_rewrite();
        hdr.inner_ethernet.setInvalid();
    }

    table fabric_rewrite {
        key = {
            eg_md.common.pkt_type : ternary;
            eg_md.common.is_mirror : exact;
            eg_md.common.is_mcast : exact;
        }

        actions = {
            NoAction;
            fabric_unicast_rewrite;
            fabric_mcast_rewrite;
            fabric_mcast_rewrite_ipv4;
            fabric_mcast_rewrite_ipv6;
            // fabric_mirror_rewrite;
        }

        const default_action = NoAction;
        size = 8;
        // const entries = {
        //     (_, 0, 0) : fabric_unicast_rewrite();
        //     (FABRIC_PKT_TYPE_IPV4, 0, 1) : fabric_mcast_rewrite_ipv4();
        //     (FABRIC_PKT_TYPE_IPV6, 0, 1) : fabric_mcast_rewrite_ipv6();
        //     (_, 0, 1) : fabric_mcast_rewrite();
        //     // (_, 1, 0) : fabric_mirror_rewrite();
        // }
    }

    action uliif_2_iif() {
        eg_md.common.iif = hdr.ext_tunnel_decap.ul_iif;
        hdr.ext_tunnel_decap.setInvalid();
    }

    table merge_iif {
        // keyless
        actions = {
            uliif_2_iif;
        }

        const default_action = uliif_2_iif();
    }

    apply {
        if (hdr.ext_tunnel_decap.isValid() && hdr.ext_tunnel_decap.ul_iif != 0) {
            merge_iif.apply();
        }
        fabric_rewrite.apply();
    }
}

control FabricRewrite_cpu_eth(
        inout switch_header_t hdr,
        inout switch_egress_metadata_t eg_md,
        in egress_intrinsic_metadata_t eg_intr_md) {

    Hash<bit<16>>(HashAlgorithm_t.IDENTITY) hash_h1_pv;
    Meter<bit<8>>(256, MeterType_t.BYTES) meter;

    // fake-eth/cpu-bfd/ip/data
    action encap_bfd(bit<48> dst_addr, bit<48> src_addr) {
        hdr.ethernet.setValid();
        hdr.ethernet.ether_type = 0x9000;
        hdr.ethernet.dst_addr = dst_addr;
        hdr.ethernet.src_addr = src_addr;

        hdr.fabric_to_cpu_eth_base.setValid();
        hdr.fabric_to_cpu_eth_base.pkt_type = CPU_ETH_PKT_TYPE_BFD;
        hdr.fabric_to_cpu_eth_base.dir = 0;

        hdr.fabric_to_cpu_eth_data.setValid();
        hdr.fabric_to_cpu_eth_data.var_h1 = hash_h1_pv.get({
            eg_md.common.extend +++
            1w0 +++
            eg_md.common.iif
        });
        // hdr.fabric_to_cpu_eth_data.extend = eg_md.common.extend;        
        // hdr.fabric_to_cpu_eth_data.iif = eg_md.common.iif;
        hdr.fabric_to_cpu_eth_data.var_h2 = 0;
        hdr.fabric_to_cpu_eth_data.var_h3 = 0;
        hdr.fabric_to_cpu_eth_data.var_h4 = eg_md.common.var_16bit_310; // cpu_reason + src_port
        // hdr.fabric_to_cpu_eth_data.var_8bit_1 = eg_md.common.cpu_reason;
        // hdr.fabric_to_cpu_eth_data.var_8bit_2 = eg_md.common.src_port;
        hdr.fabric_to_cpu_eth_data.reserved = 0;
    }

    // fake-eth/cpu-bfd/ipv4/data
    action encap_bfd_v4(bit<48> dst_addr, bit<48> src_addr) {
        encap_bfd(dst_addr, src_addr);
        hdr.fabric_eth_etype.setValid();
        hdr.fabric_eth_etype.ether_type = 0x0800;
    }

    // fake-eth/cpu-bfd/ipv6/data
    action encap_bfd_v6(bit<48> dst_addr, bit<48> src_addr) {
        encap_bfd(dst_addr, src_addr);
        hdr.fabric_eth_etype.setValid();
        hdr.fabric_eth_etype.ether_type = 0x86dd;
    }

    // eth/cpu-bfd/data
    action encap_bfd_mcast() {
        hdr.fabric_to_cpu_eth_base.setValid();
        hdr.fabric_to_cpu_eth_base.pkt_type = CPU_ETH_PKT_TYPE_BFD;
        hdr.fabric_to_cpu_eth_base.dir = 0;

        hdr.fabric_to_cpu_eth_data.setValid();
        hdr.fabric_to_cpu_eth_data.var_h1 = (bit<16>)eg_md.common.iif;
        // hdr.fabric_to_cpu_eth_data.extend = 0;
        // hdr.fabric_to_cpu_eth_data.iif = eg_md.common.iif;
        hdr.fabric_to_cpu_eth_data.var_h2 = 0;
        hdr.fabric_to_cpu_eth_data.var_h3 = 0;
        hdr.fabric_to_cpu_eth_data.var_h4 = eg_md.common.var_16bit_310; // cpu_reason + src_port
        // hdr.fabric_to_cpu_eth_data.var_8bit_1 = eg_md.common.cpu_reason;
        // hdr.fabric_to_cpu_eth_data.var_8bit_2 = eg_md.common.src_port;
        hdr.fabric_to_cpu_eth_data.reserved = 0;

        hdr.fabric_eth_etype.setValid();
        hdr.fabric_eth_etype.ether_type = hdr.ethernet.ether_type;
        hdr.ethernet.ether_type = 0x9000;
    }

    // fake-eth/cpu-ipfix-spec/ip/data
    action encap_ipfix_spec(switch_pkt_type_t pkt_type, bit<48> dst_addr, bit<48> src_addr) {
        hdr.ethernet.setValid();
        hdr.ethernet.ether_type = 0x9000;
        hdr.ethernet.dst_addr = dst_addr;
        hdr.ethernet.src_addr = src_addr;

        hdr.fabric_to_cpu_eth_base.setValid();
        hdr.fabric_to_cpu_eth_base.pkt_type = pkt_type;
        hdr.fabric_to_cpu_eth_base.dir = 0;

        hdr.fabric_to_cpu_eth_data.setValid();
        hdr.fabric_to_cpu_eth_data.var_h1 = 0;
        // hdr.fabric_to_cpu_eth_data.extend = 0;
        // hdr.fabric_to_cpu_eth_data.iif = 0;
        hdr.fabric_to_cpu_eth_data.var_h2 = (bit<16>)eg_md.common.oif;
        // hdr.fabric_to_cpu_eth_data.oif = eg_md.common.oif;
        hdr.fabric_to_cpu_eth_data.var_h3 = 0;
        hdr.fabric_to_cpu_eth_data.var_h4 = eg_md.common.var_16bit_310; // dip_l3class_id + sip_l3class_id
        // hdr.fabric_to_cpu_eth_data.var_8bit_1 = eg_md.route.dip_l3class_id;
        // hdr.fabric_to_cpu_eth_data.var_8bit_2 = eg_md.route.sip_l3class_id;
        hdr.fabric_to_cpu_eth_data.reserved = 0;
    }

    // fake-eth/cpu-ipfix-spec/ipv4/data
    action encap_ipfix_spec_v4(bit<48> dst_addr, bit<48> src_addr) {
        encap_ipfix_spec(CPU_ETH_PKT_TYPE_IPFIX_SPEC_V4, dst_addr, src_addr);
        hdr.fabric_eth_etype.setValid();
        hdr.fabric_eth_etype.ether_type = 0x0800;
    }

    // fake-eth/cpu-ipfix-spec/ipv6/data
    action encap_ipfix_spec_v6(bit<48> dst_addr, bit<48> src_addr) {
        encap_ipfix_spec(CPU_ETH_PKT_TYPE_IPFIX_SPEC_V6, dst_addr, src_addr);
        hdr.fabric_eth_etype.setValid();
        hdr.fabric_eth_etype.ether_type = 0x86dd;
    }

    // eth/cpu-ipfix/data
    action encap_ig_ipfix_cpu_header(){
        hdr.fabric_to_cpu_eth_base.setValid();
        hdr.fabric_to_cpu_eth_base.pkt_type = CPU_ETH_PKT_TYPE_IPFIX;
        hdr.fabric_to_cpu_eth_base.dir = 0;

        hdr.fabric_to_cpu_eth_data.setValid();
        hdr.fabric_to_cpu_eth_data.var_h1 = (bit<16>)eg_md.common.iif;
        // hdr.fabric_to_cpu_eth_data.extend = 0;
        // hdr.fabric_to_cpu_eth_data.iif = eg_md.common.iif;
        hdr.fabric_to_cpu_eth_data.var_h2 = 0;
        hdr.fabric_to_cpu_eth_data.var_h3 = eg_md.common.hash;
        hdr.fabric_to_cpu_eth_data.var_h4 = 0;
        hdr.fabric_to_cpu_eth_data.reserved = 0;

        hdr.fabric_eth_etype.setValid();
        hdr.fabric_eth_etype.ether_type = hdr.ethernet.ether_type;
        hdr.ethernet.ether_type = 0x9000;
    }

    // eth/cpu-ipfix/data
    action encap_eg_ipfix_cpu_header() {
        hdr.fabric_to_cpu_eth_base.setValid();
        hdr.fabric_to_cpu_eth_base.pkt_type = CPU_ETH_PKT_TYPE_IPFIX;
        hdr.fabric_to_cpu_eth_base.dir = 1;

        hdr.fabric_to_cpu_eth_data.setValid();
        hdr.fabric_to_cpu_eth_data.var_h1 = (bit<16>)eg_md.common.iif;
        // hdr.fabric_to_cpu_eth_data.extend = 0;
        // hdr.fabric_to_cpu_eth_data.iif = eg_md.common.iif;
        hdr.fabric_to_cpu_eth_data.var_h2 = (bit<16>)eg_md.common.oif;
        // hdr.fabric_to_cpu_eth_data.oif = eg_md.common.oif;
        hdr.fabric_to_cpu_eth_data.var_h3 = eg_md.common.hash;
        hdr.fabric_to_cpu_eth_data.var_h4 = 0;
        hdr.fabric_to_cpu_eth_data.reserved = 0;

        hdr.fabric_eth_etype.setValid();
        hdr.fabric_eth_etype.ether_type = hdr.ethernet.ether_type;
        hdr.ethernet.ether_type = 0x9000;
    }

    // eth/cpu-pcap/data
    action encap_pcap() {
        hdr.fabric_to_cpu_eth_base.setValid();
        hdr.fabric_to_cpu_eth_base.pkt_type = CPU_ETH_PKT_TYPE_PCAP;
        hdr.fabric_to_cpu_eth_base.dir = 0;

        hdr.fabric_to_cpu_eth_data.setValid();
        hdr.fabric_to_cpu_eth_data.var_h1 = (bit<16>)eg_md.common.iif;
        // hdr.fabric_to_cpu_eth_data.extend = 0;
        // hdr.fabric_to_cpu_eth_data.iif = eg_md.common.iif;
        hdr.fabric_to_cpu_eth_data.var_h2 = 0;
        hdr.fabric_to_cpu_eth_data.var_h3 = 0;
        hdr.fabric_to_cpu_eth_data.var_h4[15:8] = eg_md.common.pipeline_location;
        hdr.fabric_to_cpu_eth_data.var_h4[7:0] = 0;
        hdr.fabric_to_cpu_eth_data.reserved = 0;

        hdr.fabric_eth_etype.setValid();
        hdr.fabric_eth_etype.ether_type = hdr.ethernet.ether_type;
        hdr.ethernet.ether_type = 0x9000;
    }

    // fake-eth/cpu-trace/fabric/data
    action encap_packet_trace(bit<48> dst_addr, bit<48> src_addr) {
        hdr.ethernet.setValid();
        hdr.ethernet.ether_type = 0x9000;
        hdr.ethernet.dst_addr = dst_addr;
        hdr.ethernet.src_addr = src_addr;

        hdr.fabric_to_cpu_eth_base.setValid();
        hdr.fabric_to_cpu_eth_base.pkt_type = CPU_ETH_PKT_TYPE_TRACE;
        hdr.fabric_to_cpu_eth_base.dir = 0;

        hdr.fabric_to_cpu_eth_data.setValid();
        hdr.fabric_to_cpu_eth_data.var_h1 = 0;
        // hdr.fabric_to_cpu_eth_data.extend = 0;
        // hdr.fabric_to_cpu_eth_data.iif = 0;
        hdr.fabric_to_cpu_eth_data.var_h2 = 0;
        hdr.fabric_to_cpu_eth_data.var_h3 = eg_md.common.trace_counter;
        hdr.fabric_to_cpu_eth_data.var_h4[15:8] = eg_md.common.pipeline_location;
        hdr.fabric_to_cpu_eth_data.var_h4[7:0] = eg_md.common.drop_reason;
        hdr.fabric_to_cpu_eth_data.reserved = eg_md.common.hash[15:0];

        hdr.fabric_eth_etype.setValid();
        hdr.fabric_eth_etype.ether_type = 0x9001;
    }

    // eth/pause
    action encap_pause(bit<16> pause_time){
        hdr.ethernet.dst_addr = 0x0180C2000001;
        hdr.ethernet.src_addr[7:0] = eg_md.common.backpush_dst_port;
        hdr.ethernet.ether_type = 0x8808;
        hdr.pause_info.setValid();
        hdr.pause_info.code = 0x1;
        hdr.pause_info.time = pause_time;
    }

    // fake-eth/cpu-trace/fabric/data
    action encap_packet_ccm(bit<48> dst_addr, bit<48> src_addr) {
        hdr.ethernet.setValid();
        hdr.ethernet.ether_type = 0x9000;
        hdr.ethernet.dst_addr = dst_addr;
        hdr.ethernet.src_addr = src_addr;

        hdr.fabric_to_cpu_eth_base.setValid();
        hdr.fabric_to_cpu_eth_base.pkt_type = CPU_ETH_PKT_TYPE_CCM;
        hdr.fabric_to_cpu_eth_base.dir = 0;

        hdr.fabric_to_cpu_eth_data.setValid();
        hdr.fabric_to_cpu_eth_data.var_h1 = 0;
        hdr.fabric_to_cpu_eth_data.var_h2 = 0;
        hdr.fabric_to_cpu_eth_data.var_h3 = 0;
        hdr.fabric_to_cpu_eth_data.var_h4 = 0;
        hdr.fabric_to_cpu_eth_data.reserved = 0;

        hdr.fabric_eth_etype.setValid();
        hdr.fabric_eth_etype.ether_type = 0x9001;
    }

    table cpu_eth_rewrite {
        key = {
            eg_md.common.cpu_eth_encap_id : exact;
        }

        actions = {
            NoAction;
            encap_bfd_v4;
            encap_bfd_v6;
            encap_bfd_mcast;
            encap_ipfix_spec_v4;
            encap_ipfix_spec_v6;
            encap_ig_ipfix_cpu_header;
            encap_eg_ipfix_cpu_header;
            encap_pcap;
            encap_packet_trace;
            encap_pause;
            encap_packet_ccm;
        }

        const default_action = NoAction;
        size = 32;
        // const entries = {
        //     (CPU_ETH_ENCAP_BFD_IPV4) : encap_bfd_v4(dst_addr, src_addr);
        //     (CPU_ETH_ENCAP_BFD_IPV6) : encap_bfd_v6(dst_addr, src_addr);
        //     (CPU_ETH_ENCAP_BFD_ETH) : encap_bfd_mcast();
        //     (CPU_ETH_ENCAP_IPFIX_SPEC_V4) : encap_ipfix_spec_v4(dst_addr, src_addr);
        //     (CPU_ETH_ENCAP_IPFIX_SPEC_V6) : encap_ipfix_spec_v6(dst_addr, src_addr);
        //     (CPU_ETH_ENCAP_IPFIX_IG) : encap_ig_ipfix_cpu_header();
        //     (CPU_ETH_ENCAP_IPFIX_EG) : encap_eg_ipfix_cpu_header();            
        //     (CPU_ETH_ENCAP_PCAP) : encap_pcap();           
        //     (CPU_ETH_ENCAP_PIPELINE_TRACE) : encap_packet_trace(dst_addr, src_addr);
        //     (CPU_ETH_ENCAP_CCM) : encap_packet_ccm(dst_addr, src_addr);
        //     (CPU_ETH_ENCAP_XOFF) : encap_pause(pause_time);
        //     (CPU_ETH_ENCAP_XON) : encap_pause(0);
        // }
    }

    action set_color_blind(bit<8> meter_id) {
        eg_md.qos.port_meter_color = (bit<2>) meter.execute(index = meter_id);
    }

    table trace_meter_index {
        key = {
            eg_md.common.pipeline_location : ternary;
            eg_md.common.drop_reason : ternary;
        }

        actions = {
            set_color_blind;
        }

        size = 256;
    }

    apply {
        cpu_eth_rewrite.apply();
        trace_meter_index.apply();
    }
}
# 235 "/mnt/p4c-4127/p4src/switch-tofino2/switch_tofino_x1.p4" 2
# 1 "/mnt/p4c-4127/p4src/shared/trace.p4" 1
/*
 * Pipeline Trace processing for multi-device system
 */

struct switch_trace_counter_t {
    bit<32> hi;
    bit<32> low;
}

control IngressTrace_front(
        in ingress_intrinsic_metadata_t ig_intr_md,
        in ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm,
        inout switch_header_t hdr,
        inout switch_ingress_metadata_t ig_md,
        inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr) {

    const bit<32> trace_reg_size = 10;
    Register<switch_trace_counter_t, bit<16>>(trace_reg_size, {0, 0}) reg_trace_counter;
    RegisterAction<switch_trace_counter_t, bit<16>, bit<32>>(reg_trace_counter) incr_trace_counter = {
        void apply(inout switch_trace_counter_t reg, out bit<32> rv) {
            if (reg.low < (1 << 31) - 1) {
                reg.low = reg.low + 1;
                rv = reg.low;
            } else {
                reg.hi = reg.hi + 1;
                reg.low = 0;
                rv = reg.low;
            }
        }
    };

    action only_counter(bit<16> reg_id) {
        ig_md.common.trace_counter = (bit<16>)incr_trace_counter.execute(reg_id);
    }

    action trace_to_mirror(bit<16> reg_id, switch_mirror_session_t sess_id, switch_logic_port_t dst_mirror_port) {
        ig_md.mirror.src = SWITCH_PKT_SRC_CLONED_INGRESS;
        ig_md.mirror.type = 7;
        ig_md.mirror.session_id = sess_id;
        // ig_md.common.dst_mirror_port = dst_mirror_port;
        ig_md.common.egress_eport[15:8] = INGRESS_FRONT;// egress_eport[15:8] used as pipeline_location
        ig_md.common.egress_eport[7:0] = dst_mirror_port;// egress_eport[7:0] used as dst_mirror_port
        // ig_md.common.pipeline_location = INGRESS_FRONT;
        ig_intr_md_for_dprsr.mirror_type = 7;
        ig_md.common.trace_counter = (bit<16>)incr_trace_counter.execute(reg_id);
    }

    @ignore_table_dependency("Ig_front.mirror_decision.mirror_decision")
    @ignore_table_dependency("Ig_front.system_acl.system_acl")
    table fabric_ingress_trace {
        key = {
            ig_md.common.track : exact @name("track");
            ig_md.mirror.span_flag : ternary @name("span_flag"); // set 0&&&f to avoid overwriting span
            ig_md.mirror.sample_flag : ternary@name("sample_flag"); // set 0&&&f to avoid overwriting sample
            ig_md.common.pkt_type : ternary @name("pkt_type");
            ig_md.common.is_mirror : ternary @name("is_mirror");
            ig_md.common.is_mcast : ternary @name("is_mcast");
            ig_md.qos.tc : ternary @name("tc");
            ig_md.common.iif : ternary @name("iif");
            ig_md.common.drop_reason : ternary @name("drop_reason");
            // ig_intr_md_for_tm.ucast_egress_port : ternary @name("egress_port");
        }
        actions = {
            NoAction;
            only_counter;
            trace_to_mirror;
        }

        const default_action = NoAction;
        size = 32;
    }

    action set_pcap_mirror_sess(switch_mirror_session_t sess_id){
        ig_md.mirror.type = 11;
        ig_md.mirror.src = SWITCH_PKT_SRC_CLONED_INGRESS;
        ig_md.mirror.session_id = sess_id;
        ig_intr_md_for_dprsr.mirror_type = (MirrorType_t) 1;
    }

    @ignore_table_dependency("Ig_front.mirror_decision.mirror_decision")
    @ignore_table_dependency("Ig_front.system_acl.system_acl")
    table mirror_pcap {
        key = {
            ig_md.mirror.pcap_flag: exact;
            ig_md.mirror.color: exact;
        }

        actions = {
            NoAction;
            set_pcap_mirror_sess;
        }

        const default_action = NoAction;
        size = 8;
        // const entries = {
        //     (1, SWITCH_METER_COLOR_GREEN) : set_pcap_mirror_sess(sess_id);
        //     (1, SWITCH_METER_COLOR_RED) : NoAction();
        // }
    }

    apply {
        // fabric_ingress_trace.apply();
        switch(fabric_ingress_trace.apply().action_run) {
            NoAction: {
                mirror_pcap.apply();
            }
        }
    }
}

control IngressTrace_uplink(
        in ingress_intrinsic_metadata_t ig_intr_md,
        in ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm,
        inout switch_header_t hdr,
        inout switch_ingress_metadata_t ig_md,
        inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr) {

    const bit<32> trace_reg_size = 10;
    Register<switch_trace_counter_t, bit<16>>(trace_reg_size, {0, 0}) reg_trace_counter;
    RegisterAction<switch_trace_counter_t, bit<16>, bit<32>>(reg_trace_counter) incr_trace_counter = {
        void apply(inout switch_trace_counter_t reg, out bit<32> rv) {
            if (reg.low < (1 << 31) - 1) {
                reg.low = reg.low + 1;
                rv = reg.low;
            } else {
                reg.hi = reg.hi + 1;
                reg.low = 0;
                rv = reg.low;
            }
        }
    };

    action only_counter(bit<16> reg_id) {
        ig_md.common.trace_counter = (bit<16>)incr_trace_counter.execute(reg_id);
    }

    action trace_to_mirror(bit<16> reg_id, switch_mirror_session_t sess_id, switch_logic_port_t dst_mirror_port) {
        ig_md.mirror.src = SWITCH_PKT_SRC_CLONED_INGRESS;
        ig_md.mirror.type = 7;
        ig_md.mirror.session_id = sess_id;
        //ig_md.common.dst_mirror_port = dst_mirror_port;
        //ig_md.common.pipeline_location = INGRESS_UPLINK;
        ig_intr_md_for_dprsr.mirror_type = 7;
        //ig_md.common.trace_counter = (bit<16>)incr_trace_counter.execute(reg_id);
        ig_md.common.trace_32[31:24] = INGRESS_UPLINK;
        ig_md.common.trace_32[23:16] = dst_mirror_port;
        ig_md.common.trace_32[15:0] = (bit<16>)incr_trace_counter.execute(reg_id);
    }

    @stage(11)
    table fabric_ingress_trace {
        key = {
            ig_md.common.track : ternary @name("track");
            hdr.fabric_base.pkt_type : ternary @name("pkt_type");
            hdr.fabric_base.is_mirror : ternary @name("is_mirror");
            hdr.fabric_base.is_mcast : ternary @name("is_mcast");
            ig_md.qos.tc : ternary @name("tc");
            ig_md.flags.drop : ternary @name("drop");
            ig_md.flags.glean : ternary @name("glean");
            ig_md.common.drop_reason : ternary @name("drop_reason");
            ig_md.common.iif : ternary @name("iif");
            ig_md.common.src_port : ternary @name("src_port");
            ig_md.route.l2_l3oif : ternary @name("ul_oif");
            // ig_intr_md_for_tm.ucast_egress_port : ternary @name("egress_port");
        }
        actions = {
            NoAction;
            only_counter;
            trace_to_mirror;
        }

        const default_action = NoAction;
        size = 32;
    }

    apply {
        if (hdr.fabric_base.isValid()) {
            fabric_ingress_trace.apply();
        }
    }
}

control IngressTrace_fabric(
        in ingress_intrinsic_metadata_t ig_intr_md,
        in ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm,
        inout switch_header_t hdr,
        inout switch_ingress_metadata_t ig_md,
        inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr) {

    const bit<32> trace_reg_size = 10;
    Register<switch_trace_counter_t, bit<16>>(trace_reg_size, {0, 0}) reg_trace_counter;
    RegisterAction<switch_trace_counter_t, bit<16>, bit<32>>(reg_trace_counter) incr_trace_counter = {
        void apply(inout switch_trace_counter_t reg, out bit<32> rv) {
            if (reg.low < (1 << 31) - 1) {
                reg.low = reg.low + 1;
                rv = reg.low;
            } else {
                reg.hi = reg.hi + 1;
                reg.low = 0;
                rv = reg.low;
            }
        }
    };

    action only_counter(bit<16> reg_id) {
        ig_md.common.trace_counter = (bit<16>)incr_trace_counter.execute(reg_id);
    }

    action trace_to_mirror(bit<16> reg_id, switch_mirror_session_t sess_id, switch_logic_port_t dst_mirror_port) {
        ig_md.mirror.src = SWITCH_PKT_SRC_CLONED_INGRESS;
        ig_md.mirror.type = 7;
        ig_md.mirror.session_id = sess_id;
        ig_md.common.dst_mirror_port = dst_mirror_port;
        ig_md.common.pipeline_location = INGRESS_FABRIC;
        ig_intr_md_for_dprsr.mirror_type = 7;
        ig_md.common.trace_counter = (bit<16>)incr_trace_counter.execute(reg_id);
    }

    action pcie_trace_to_mirror(bit<16> reg_id, switch_mirror_session_t sess_id, switch_logic_port_t dst_mirror_port) {
        ig_md.mirror.src = SWITCH_PKT_SRC_CLONED_INGRESS;
        ig_md.mirror.type = 7;
        ig_md.mirror.session_id = sess_id;
        ig_md.common.dst_mirror_port = dst_mirror_port;
        ig_md.common.pipeline_location = INGRESS_PCIE;
        ig_intr_md_for_dprsr.mirror_type = 7;
        ig_md.common.trace_counter = (bit<16>)incr_trace_counter.execute(reg_id);
    }

    @stage(11)
    table fabric_ingress_trace {
        key = {
            ig_md.common.track : ternary @name("track");
            ig_md.common.port_type : ternary @name("port_type");
            hdr.fabric_base.pkt_type : ternary @name("pkt_type");
            hdr.fabric_base.is_mirror : ternary @name("is_mirror");
            hdr.fabric_base.is_mcast : ternary @name("is_mcast");
            ig_md.qos.tc : ternary @name("tc");
            // ig_md.flags.drop : ternary @name("drop");
            // ig_md.common.drop_reason : ternary @name("drop_reason");            
            hdr.fabric_one_pad_7.iif : ternary @name("iif");
            ig_md.common.oif : ternary @name("oif");
            ig_md.common.dst_port : ternary @name("dst_port");
            ig_intr_md_for_tm.ucast_egress_port : ternary @name("egress_port");
        }
        actions = {
            NoAction;
            only_counter;
            trace_to_mirror;
            pcie_trace_to_mirror;
        }

        const default_action = NoAction;
        size = 32;
    }

    apply {
         fabric_ingress_trace.apply();
    }
}

control IngressTrace_downlink(
        in ingress_intrinsic_metadata_t ig_intr_md,
        in ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm,
        inout switch_header_t hdr,
        inout switch_ingress_metadata_t ig_md,
        inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr) {

    const bit<32> trace_reg_size = 10;
    Register<switch_trace_counter_t, bit<16>>(trace_reg_size, {0, 0}) reg_trace_counter;
    RegisterAction<switch_trace_counter_t, bit<16>, bit<32>>(reg_trace_counter) incr_trace_counter = {
        void apply(inout switch_trace_counter_t reg, out bit<32> rv) {
            if (reg.low < (1 << 31) - 1) {
                reg.low = reg.low + 1;
                rv = reg.low;
            } else {
                reg.hi = reg.hi + 1;
                reg.low = 0;
                rv = reg.low;
            }
        }
    };

    action only_counter(bit<16> reg_id) {
        ig_md.common.trace_counter = (bit<16>)incr_trace_counter.execute(reg_id);
    }

    action trace_to_mirror(bit<16> reg_id, switch_mirror_session_t sess_id, switch_logic_port_t dst_mirror_port) {
        ig_md.mirror.src = SWITCH_PKT_SRC_CLONED_INGRESS;
        ig_md.mirror.type = 7;
        ig_md.mirror.session_id = sess_id;
        ig_intr_md_for_dprsr.mirror_type = 7;
        ig_md.common.trace_location_dport[15:8] = INGRESS_DOWNLINK;
        ig_md.common.trace_location_dport[7:0] = dst_mirror_port;
        ig_md.common.trace_counter = (bit<16>)incr_trace_counter.execute(reg_id);
    }

    @stage(11)
    table fabric_ingress_trace {
        key = {
            ig_md.common.track : exact @name("track");
            hdr.fabric_base.pkt_type : ternary @name("pkt_type");
            hdr.fabric_base.is_mirror : ternary @name("is_mirror");
            hdr.fabric_base.is_mcast : ternary @name("is_mcast");
            ig_md.qos.tc : ternary @name("tc");
            ig_md.common.iif : ternary @name("iif");
            ig_md.common.oif : ternary @name("oif");
            ig_md.common.dst_port : ternary @name("dst_port");
            ig_md.qos.FQID : ternary @name("fqid");
            ig_intr_md_for_tm.ucast_egress_port : ternary @name("egress_port");
        }
        actions = {
            NoAction;
            only_counter;
            trace_to_mirror;
        }

        const default_action = NoAction;
        size = 32;
    }

    apply {
         fabric_ingress_trace.apply();
    }
}

control EgressTrace_uplink(
        in egress_intrinsic_metadata_from_parser_t eg_intr_from_prsr,
        in egress_intrinsic_metadata_t eg_intr_md,
        inout switch_egress_metadata_t eg_md,
        inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr) {

    const bit<32> trace_reg_size = 10;
    Register<switch_trace_counter_t, bit<16>>(trace_reg_size, {0, 0}) reg_trace_counter;
    RegisterAction<switch_trace_counter_t, bit<16>, bit<32>>(reg_trace_counter) incr_trace_counter = {
        void apply(inout switch_trace_counter_t reg, out bit<32> rv) {
            if (reg.low < (1 << 31) - 1) {
                reg.low = reg.low + 1;
                rv = reg.low;
            } else {
                reg.hi = reg.hi + 1;
                reg.low = 0;
                rv = reg.low;
            }
        }
    };

    action only_counter(bit<16> reg_id) {
        eg_md.common.trace_counter = (bit<16>)incr_trace_counter.execute(reg_id);//for power
    }

    action trace_to_mirror(bit<16> reg_id, switch_mirror_session_t sess_id, switch_logic_port_t dst_mirror_port) {
        eg_md.mirror.src = SWITCH_PKT_SRC_CLONED_EGRESS;
        eg_md.mirror.type = 7;
        eg_md.mirror.session_id = sess_id;
        //eg_md.common.dst_mirror_port = dst_mirror_port;
        //eg_md.common.pipeline_location = EGRESS_UPLINK;
        eg_md.common.trace_32[31:24] = EGRESS_UPLINK;
        eg_md.common.trace_32[23:16] = dst_mirror_port;
        eg_md.common.trace_32[15:0] = (bit<16>)incr_trace_counter.execute(reg_id);
        eg_intr_md_for_dprsr.mirror_type = 7;

        eg_intr_md_for_dprsr.mirror_io_select = 1; // E2E mirroring for Tofino2 & future ASICs

        //eg_md.common.trace_counter = (bit<16>)incr_trace_counter.execute(reg_id);//for power
        eg_md.common.timestamp = eg_intr_from_prsr.global_tstamp[31:0];
    }

    table fabric_egress_trace {
        key = {
            eg_md.common.track : ternary @name("track");
            eg_md.common.pkt_type : ternary @name("pkt_type");
            eg_md.common.is_mirror : ternary @name("is_mirror");
            eg_md.common.is_mcast : ternary @name("is_mcast");
            eg_md.qos.tc : ternary @name("tc");
            eg_md.common.src_port : ternary @name("src_port");
            eg_md.common.iif : ternary @name("iif");
            eg_md.flags.drop : ternary @name("drop");
            eg_md.flags.glean : ternary @name("glean");
            eg_md.common.drop_reason : ternary @name("drop_reason");
            eg_md.flags.glb_learning : ternary @name("learning");
            eg_intr_md.egress_port : ternary @name("egress_port");
        }
        actions = {
            NoAction;
            only_counter;
            trace_to_mirror;
        }

        const default_action = NoAction;
        size = 32;
    }

    apply {
        fabric_egress_trace.apply();
    }
}

control EgressTrace_fabric(
        in egress_intrinsic_metadata_from_parser_t eg_intr_from_prsr,
        in egress_intrinsic_metadata_t eg_intr_md,
        inout switch_egress_metadata_t eg_md,
        inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr) {

    const bit<32> trace_reg_size = 10;
    Register<switch_trace_counter_t, bit<16>>(trace_reg_size, {0, 0}) reg_trace_counter;
    RegisterAction<switch_trace_counter_t, bit<16>, bit<32>>(reg_trace_counter) incr_trace_counter = {
        void apply(inout switch_trace_counter_t reg, out bit<32> rv) {
            if (reg.low < (1 << 31) - 1) {
                reg.low = reg.low + 1;
                rv = reg.low;
            } else {
                reg.hi = reg.hi + 1;
                reg.low = 0;
                rv = reg.low;
            }
        }
    };

    action only_counter(bit<16> reg_id) {
        eg_md.common.trace_counter = (bit<16>)incr_trace_counter.execute(reg_id);
    }

    action trace_to_mirror(bit<16> reg_id, switch_mirror_session_t sess_id, switch_logic_port_t dst_mirror_port) {
        eg_md.mirror.src = SWITCH_PKT_SRC_CLONED_EGRESS;
        eg_md.mirror.type = 7;
        eg_md.mirror.session_id = sess_id;
        eg_md.common.dst_mirror_port = dst_mirror_port;
        eg_md.common.pipeline_location = EGRESS_FABRIC;
        eg_intr_md_for_dprsr.mirror_type = 7;

        eg_intr_md_for_dprsr.mirror_io_select = 1; // E2E mirroring for Tofino2 & future ASICs

        eg_md.common.trace_counter = (bit<16>)incr_trace_counter.execute(reg_id);
        eg_md.common.timestamp = eg_intr_from_prsr.global_tstamp[31:0];
    }

    action pcie_trace_to_mirror(bit<16> reg_id, switch_mirror_session_t sess_id, switch_logic_port_t dst_mirror_port) {
        eg_md.mirror.src = SWITCH_PKT_SRC_CLONED_EGRESS;
        eg_md.mirror.type = 7;
        eg_md.mirror.session_id = sess_id;
        eg_md.common.dst_mirror_port = dst_mirror_port;
        eg_md.common.pipeline_location = EGRESS_PCIE;
        eg_intr_md_for_dprsr.mirror_type = 7;

        eg_intr_md_for_dprsr.mirror_io_select = 1; // E2E mirroring for Tofino2 & future ASICs

        eg_md.common.trace_counter = (bit<16>)incr_trace_counter.execute(reg_id);
        eg_md.common.timestamp = eg_intr_from_prsr.global_tstamp[31:0];
    }

    // copy2cpu: is_gleaned 1, glean 0 
    // redirect2cpu: is_gleaned 1, glean 1
    // none-cpu: is_gleaned 0, glean 0
    @stage(11)
    table fabric_egress_trace {
        key = {
            eg_md.common.track : exact @name("track");
            eg_md.common.pkt_type : ternary @name("pkt_type");
            eg_md.common.is_mirror : ternary @name("is_mirror");
            eg_md.common.is_mcast : ternary @name("is_mcast");
            eg_md.qos.tc : ternary @name("tc");
            eg_md.flags.is_gleaned : ternary @name("is_gleaned");
            eg_md.flags.is_elephant : ternary @name("is_elephant");
            eg_md.flags.glean : ternary @name("glean");
            eg_md.flags.drop : ternary @name("drop");
            eg_md.flags.is_eop : ternary @name("is_eop"); // use is_eop to avoid overwriting eop-mirror
            eg_md.common.drop_reason : ternary @name("drop_reason");
            eg_md.common.iif : ternary @name("iif");
            eg_md.common.src_port : ternary @name("src_port");
            eg_intr_md.egress_port : ternary @name("egress_port");
        }
        actions = {
            NoAction;
            only_counter;
            trace_to_mirror;
            pcie_trace_to_mirror;
        }

        const default_action = NoAction;
        size = 32;
    }

    apply {
         fabric_egress_trace.apply();
    }
}

control EgressTrace_downlink(
        in egress_intrinsic_metadata_from_parser_t eg_intr_from_prsr,
        in egress_intrinsic_metadata_t eg_intr_md,
        inout switch_egress_metadata_t eg_md,
        inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr) {

    const bit<32> trace_reg_size = 10;
    Register<switch_trace_counter_t, bit<16>>(trace_reg_size, {0, 0}) reg_trace_counter;
    RegisterAction<switch_trace_counter_t, bit<16>, bit<32>>(reg_trace_counter) incr_trace_counter = {
        void apply(inout switch_trace_counter_t reg, out bit<32> rv) {
            if (reg.low < (1 << 31) - 1) {
                reg.low = reg.low + 1;
                rv = reg.low;
            } else {
                reg.hi = reg.hi + 1;
                reg.low = 0;
                rv = reg.low;
            }
        }
    };

    action only_counter(bit<16> reg_id) {
        eg_md.common.trace_counter = (bit<16>)incr_trace_counter.execute(reg_id);
    }

    action trace_to_mirror(bit<16> reg_id, switch_mirror_session_t sess_id, switch_logic_port_t dst_mirror_port) {
        eg_md.mirror.src = SWITCH_PKT_SRC_CLONED_EGRESS;
        eg_md.mirror.type = 7;
        eg_md.mirror.session_id = sess_id;
        eg_intr_md_for_dprsr.mirror_type = 7;

        eg_intr_md_for_dprsr.mirror_io_select = 1; // E2E mirroring for Tofino2 & future ASICs

        eg_md.common.trace_location_dport[15:8] = EGRESS_DOWNLINK;
        eg_md.common.trace_location_dport[7:0] = dst_mirror_port;
        eg_md.common.trace_counter = (bit<16>)incr_trace_counter.execute(reg_id);
        eg_md.common.timestamp = eg_intr_from_prsr.global_tstamp[31:0];
    }

    @stage(11)
    @ignore_table_dependency("Eg_downlink.l2_encap_mapping.ttl_thr_check")
    @ignore_table_dependency("Eg_downlink.sysacl.system_acl")
    table fabric_egress_trace {
        key = {
            eg_md.common.track : exact @name("track");
            eg_md.common.pkt_type : ternary @name("pkt_type");
            eg_md.common.is_mirror : ternary @name("is_mirror");
            eg_md.common.is_mcast : ternary @name("is_mcast");
            eg_md.qos.tc : ternary @name("tc");
            eg_md.common.iif : ternary @name("iif");
            eg_md.common.oif : ternary @name("oif");
            eg_md.common.drop_reason : ternary @name("drop_reason");
            eg_md.common.dst_port : ternary @name("dst_port");
            eg_md.qos.FQID : ternary @name("fqid");
            eg_intr_md.egress_port : ternary @name("egress_port");
        }
        actions = {
            NoAction;
            only_counter;
            trace_to_mirror;
        }

        const default_action = NoAction;
        size = 32;
    }

    apply {
         fabric_egress_trace.apply();
    }
}

control EgressTrace_front(
        in egress_intrinsic_metadata_from_parser_t eg_intr_from_prsr,
        inout switch_egress_metadata_t eg_md,
        inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr) {

    const bit<32> trace_reg_size = 10;
    Register<switch_trace_counter_t, bit<16>>(trace_reg_size, {0, 0}) reg_trace_counter;
    RegisterAction<switch_trace_counter_t, bit<16>, bit<32>>(reg_trace_counter) incr_trace_counter = {
        void apply(inout switch_trace_counter_t reg, out bit<32> rv) {
            if (reg.low < (1 << 31) - 1) {
                reg.low = reg.low + 1;
                rv = reg.low;
            } else {
                reg.hi = reg.hi + 1;
                reg.low = 0;
                rv = reg.low;
            }
        }
    };

    action only_counter(bit<16> reg_id) {
        eg_md.common.trace_counter = (bit<16>)incr_trace_counter.execute(reg_id);
    }

    action trace_to_mirror(bit<16> reg_id, switch_mirror_session_t sess_id, switch_logic_port_t dst_mirror_port) {
        eg_md.mirror.src = SWITCH_PKT_SRC_CLONED_EGRESS;
        eg_md.mirror.type = 7;
        eg_md.mirror.session_id = sess_id;
        // eg_md.common.dst_mirror_port = dst_mirror_port;
        eg_md.common.egress_eport[15:8] = EGRESS_FRONT;// cpu_code[15:8] used as pipeline_location
        eg_md.common.egress_eport[7:0] = dst_mirror_port;// cpu_code[7:0] used as dst_mirror_port
        // eg_md.common.pipeline_location = EGRESS_FRONT;
        eg_intr_md_for_dprsr.mirror_type = 7;

        eg_intr_md_for_dprsr.mirror_io_select = 1; // E2E mirroring for Tofino2 & future ASICs

        eg_md.common.trace_counter = (bit<16>)incr_trace_counter.execute(reg_id);
        eg_md.common.timestamp = eg_intr_from_prsr.global_tstamp[31:0];
    }

    @ignore_table_dependency("Eg_front.system_acl.mirror_disable")
    @ignore_table_dependency("Eg_front.system_acl.system_acl")
    @stage(11)
    table fabric_egress_trace {
        key = {
            eg_md.common.track : ternary @name("track");
            eg_md.common.pkt_type : ternary @name("pkt_type");
            eg_md.common.is_mirror : ternary @name("is_mirror");
            eg_md.common.is_mcast : ternary @name("is_mcast");
            eg_md.qos.tc : ternary @name("tc");
            eg_md.mirror.span_flag : ternary @name("span_flag"); // set 0&&&f to avoid overwriting span
            eg_md.mirror.sample_flag : ternary@name("sample_flag"); // set 0&&&f to avoid overwriting sample
            eg_md.flags.drop : ternary @name("drop");
            eg_md.common.drop_reason : ternary @name("drop_reason");
            eg_md.common.iif : ternary @name("iif");
            eg_md.common.oif : ternary @name("oif");
            eg_md.common.dst_port : ternary @name("dst_port");
        }
        actions = {
            NoAction;
            only_counter;
            trace_to_mirror;
        }

        const default_action = NoAction;
        size = 32;
    }

    action set_pcap_mirror_sess(switch_mirror_session_t sess_id){
        eg_md.mirror.type = 11;
        eg_md.mirror.src = SWITCH_PKT_SRC_CLONED_EGRESS;
        eg_md.mirror.session_id = sess_id;
        eg_intr_md_for_dprsr.mirror_type = (MirrorType_t) 1;

        eg_intr_md_for_dprsr.mirror_io_select = 1; // E2E mirroring for Tofino2 & future ASICs

    }

    @ignore_table_dependency("Eg_front.system_acl.mirror_disable")
    @ignore_table_dependency("Eg_front.system_acl.system_acl")
    table mirror_pcap {
        key = {
            eg_md.mirror.pcap_flag: exact;
            eg_md.mirror.color: exact;
        }

        actions = {
            NoAction;
            set_pcap_mirror_sess;
        }

        const default_action = NoAction;
        size = 8;
        // const entries = {
        //     (1, SWITCH_METER_COLOR_GREEN) : set_pcap_mirror_sess(sess_id);
        //     (1, SWITCH_METER_COLOR_RED) : NoAction();
        // }
    }

    apply {
        // fabric_egress_trace.apply();
        switch(fabric_egress_trace.apply().action_run) {
            NoAction: {
                mirror_pcap.apply();
            }
        }
    }
}
# 236 "/mnt/p4c-4127/p4src/switch-tofino2/switch_tofino_x1.p4" 2

# 1 "/mnt/p4c-4127/p4src/switch-tofino2/pipeline_downlink.p4" 1
control Ig_downlink(
        inout switch_header_t hdr,
        inout switch_ingress_metadata_t ig_md,
        in ingress_intrinsic_metadata_t ig_intr_md,
        in ingress_intrinsic_metadata_from_parser_t ig_intr_from_prsr,
        inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr,
        inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm) {

    IngressFabric_downlink() ig_fabric;
    Traffic_downlink() traffic_class;
    /*by liyuhang*/
    VlanEgressMemberCheck() vlan_member_check;
    /* by zhuanghui */
    HQoSCount() hqos_count;
    QoSCount() qos_count;
    IgDropLenSub() ig_drop_sub;
    IgHQoSDropPkt1() ig_hqos_drop_pkt1;
    IgHQoSDropPkt2() ig_hqos_drop_pkt2;
    IgHQoSDropByte1() ig_hqos_drop_byte1;
    IgHQoSDropByte2() ig_hqos_drop_byte2;
    IgQoSDropCount() ig_qos_drop_count;
    DropMsgRecirc() drop_msg_redirect;

    SetEtherType() set_ethertype;
    LocalL2Encap() l2_encap;
    Multicast_Rewrite() multicast_rewrite;
    ACPtagXlate() ac_ptag_xlate;
    /* by lvlianlin */
    downlink_ig_acl_pre() acl_pre;
    downlink_ig_ipv6_acl1() ipv6_acl1;
    downlink_ig_ipv6_acl2() ipv6_acl2;
    downlink_ig_ipv6_acl3() ipv6_acl3;
    downlink_ig_ipv6_acl4() ipv6_acl4;
    downlink_ig_ipv4_acl1() ipv4_acl1;
    downlink_ig_ipv4_acl2() ipv4_acl2;
    downlink_ig_ipv4_acl3() ipv4_acl3;
    downlink_ig_ipv4_acl4() ipv4_acl4;
    DownlinkIngressSystemAcl() system_acl;

    DevPortMapping_downlink() dev_port_mapping;
    EgressSTP(VLAN_STG_TABLE_SIZE, STP_PORT_STATE_TABLE_SIZE, BACK_STP_PORT_STATE_TABLE_SIZE) stp;
    FabricCCM_downlink() fabric_ccm;
    BridgedMetadata_DOWNLINK() bridged_md_downlink;
    BridgedTypeInit_DOWNLINK() bridgetype_init;
    IngressTrace_downlink() ingress_trace;
    IngressHASH_downlink(HASH_MODE_TABLE_SIZE, HASH_COMPUTE_TABLE_SIZE) hash;
    /* system acl还未添加 */
    apply {
        bridgetype_init.apply(hdr, ig_md);

        ig_fabric.apply(ig_md, ig_intr_md_for_tm, ig_intr_md_for_dprsr, hdr);
        set_ethertype.apply(hdr, ig_md);
        acl_pre.apply(hdr, ig_intr_md_for_tm, ig_md);
        ipv4_acl1.apply(hdr, ig_md.policer.slice1.group, hdr.bridged_md_910_encap.group_classid_1, ig_md);
        ipv6_acl1.apply(hdr, ig_md.policer.slice1.group, hdr.bridged_md_910_encap.group_classid_1, ig_md);
        ipv4_acl2.apply(hdr, ig_md.policer.slice1.group, hdr.bridged_md_910_encap.group_classid_1, ig_md);
        ipv6_acl2.apply(hdr, ig_md.policer.slice1.group, hdr.bridged_md_910_encap.group_classid_1, ig_md);
        ipv4_acl3.apply(hdr, ig_md.policer.slice1.group, hdr.bridged_md_910_encap.group_classid_1, ig_md);
        ipv6_acl3.apply(hdr, ig_md.policer.slice1.group, hdr.bridged_md_910_encap.group_classid_1, ig_md);
        ipv4_acl4.apply(hdr, ig_md.policer.slice1.group, hdr.bridged_md_910_encap.group_classid_1, ig_md);
        ipv6_acl4.apply(hdr, ig_md.policer.slice1.group, hdr.bridged_md_910_encap.group_classid_1, ig_md);
        hash.apply(hdr, ig_md);
        traffic_class.apply(ig_md,ig_intr_md_for_tm);
        multicast_rewrite.apply(hdr, ig_md);
        l2_encap.apply(hdr, ig_md);
        stp.apply(hdr, ig_md);
        EncapMiss.apply(hdr, ig_md);
        /* by zhuanghui */
        qos_count.apply(hdr, ig_md);
        hqos_count.apply(hdr, ig_md);
        ig_drop_sub.apply(hdr, ig_md);
        ig_qos_drop_count.apply(hdr, ig_md);
        ig_hqos_drop_pkt1.apply(hdr, ig_md);
        ig_hqos_drop_pkt2.apply(hdr, ig_md);
        ig_hqos_drop_byte1.apply(hdr, ig_md);
        ig_hqos_drop_byte2.apply(hdr, ig_md);
        drop_msg_redirect.apply(hdr, ig_md, ig_intr_md, ig_intr_md_for_tm, ig_intr_md_for_dprsr);

        dev_port_mapping.apply(ig_md, ig_intr_md_for_tm);
        fabric_ccm.apply(hdr, ig_md, ig_intr_md_for_tm.ucast_egress_port);
        ac_ptag_xlate.apply(hdr, ig_md);
        vlan_member_check.apply(hdr, ig_md);
        system_acl.apply(hdr, ig_md, ig_intr_md_for_dprsr);

        if (ig_intr_md_for_tm.bypass_egress == 1w0) {
            bridged_md_downlink.apply(hdr, ig_md);
        }
        ingress_trace.apply(ig_intr_md, ig_intr_md_for_tm, hdr, ig_md, ig_intr_md_for_dprsr);
    }
}

control Eg_downlink(
        inout switch_header_t hdr,
        inout switch_egress_metadata_t eg_md,
        in egress_intrinsic_metadata_t eg_intr_md,
        in egress_intrinsic_metadata_from_parser_t eg_intr_from_prsr,
        inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
        inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport) {
    RidAttribute() rid_attribute;
    EvlanMapVni(EVLAN_VNI_MAPING_SIZE) evlan_map_vni;

    L2IntfAttr(L2LIF_TABLE_SIZE, L2LIF_TABLE_SIZE) l2_intf_attr;
    HorizonSplit(HORIZON_SPLIT_SIZE) horizon_split;
    GetInnerInfo() get_inner_info;
    EncapOuter() encap_outer;
    MPLS_VC_encap(MPLS_VC_ENCAP_SIZE) mpls_vc_encap;
    TunnelRewrite(GET_REWRITE_INFO_SIZE) tunnel_rewrite;
    MPLS_encap0(MPLS_TUNNEL0_TABLE_SIZE) mpls_encap0;
    MPLS_encap1(MPLS_TUNNEL1_TABLE_SIZE) mpls_encap1;
    MPLS_encap2(MPLS_TUNNEL2_TABLE_SIZE) mpls_encap2;
    L2EncapMapping() l2_encap_mapping;
    L3EncapMapping(L3_ENCAP_MAPPING_SIZE) l3_encap_mapping;
    // L4EncapMapping() l4_encap_mapping;
    PW_PTAG_XLATE(PTAG_ENCAP_SIZE) pw_ptag_xlate;
    PW_PTAG_XLATE_LEN(PTAG_ENCAP_SIZE) pw_ptag_xlate_len;
    /* by zhangjunjie */
    CCM_rid_drop() ccm_rid_drop;
    CCM_Dev_Port_Mapping() ccm_dev_port_mapping;
    EgressPortMapping_downlink(PORT_TABLE_SIZE) egress_port_mapping;
    EgressLifMapping(L2LIF_TABLE_SIZE) lif_mapping;
    Decide_ds_phb() decide_ds_phb;
    Decide_HQos_Enb() decide_hqos_enb;
    EgressQoS() qos;
    Modify_Hdr_Cos() modify_cos;
    downlink_eg_qppb_acl() qppb;
    // Dscp_decide() dscp_decide;
    downlink_eg_acl_pre() acl_pre;
    downlink_eg_qos_acl() qos_acl;
    downlink_eg_acl_resolve() acl_resolve;
    Out_LifMeter() lif_meter;
    //Out_PortMeter() port_meter;

    DownlinkEgressSystemAcl() sysacl;
    FabricRewrite_downlink() fabric_rewrite;
    FabricRewriteExtension_downlink() fabric_rewrite_ext;
    MC_LAG() mc_lag;

    /* by zhuanghui */
    AdjPktLen() adj_len;
    CheckPktLen() check_len;
    EgressTrace_downlink() egress_trace;
    // AdjTagFake() adj_tag_fake;

    OifBaseStats() oif_base_stats;

    apply {
        adj_len.apply(hdr, eg_md);

        rid_attribute.apply(eg_intr_md, eg_md);
        l2_intf_attr.apply(eg_md);
        horizon_split.apply(eg_md, eg_intr_md_for_dprsr);

        l3_encap_mapping.apply(eg_md);
        get_inner_info.apply(hdr, eg_md);
        l2_encap_mapping.apply(hdr, eg_intr_md, eg_md, eg_intr_md_for_dprsr);

        if (eg_md.common.is_mcast == 1) {
            mc_lag.apply(eg_md);
        }
        /* by zhangjunjie */
        ccm_rid_drop.apply(eg_intr_md, eg_md, eg_intr_md_for_dprsr);
        ccm_dev_port_mapping.apply(hdr, eg_md);
        egress_port_mapping.apply(eg_md);
        lif_mapping.apply(eg_md);

        /* qos remap must before ip/mpls encap */
        decide_ds_phb.apply(eg_md);
        decide_hqos_enb.apply(hdr, eg_md);
        qos.apply(hdr, eg_md);

        mpls_vc_encap.apply(hdr, eg_md);

        evlan_map_vni.apply(eg_md);

        acl_pre.apply(hdr, eg_md);
        qos_acl.apply(hdr, eg_md);
        qppb.apply(hdr, eg_md);
        acl_resolve.apply(hdr, eg_md);
        mpls_encap0.apply(hdr, eg_md, eg_md.tunnel);

        // lif_meter must before port_meter
        lif_meter.apply(hdr, eg_md);
        pw_ptag_xlate_len.apply(hdr, eg_md);

        encap_outer.apply(hdr, eg_md);
            mpls_encap1.apply(hdr, eg_md, eg_md.tunnel);

        pw_ptag_xlate.apply(hdr, eg_md);

        if (eg_md.tunnel.l3_encap_mapping_hit == 1) {
            tunnel_rewrite.apply(hdr, eg_md);
        }

        mpls_encap2.apply(hdr, eg_md, eg_md.tunnel);

        modify_cos.apply(hdr, eg_md);
        sysacl.apply(eg_md, eg_intr_md_for_dprsr);

        check_len.apply(eg_md);

        fabric_rewrite_ext.apply(hdr, eg_md, eg_intr_md);
        fabric_rewrite.apply(hdr, eg_md, eg_intr_md);

        egress_trace.apply(eg_intr_from_prsr, eg_intr_md, eg_md, eg_intr_md_for_dprsr);

        oif_base_stats.apply(hdr, eg_md);
    }
}
# 238 "/mnt/p4c-4127/p4src/switch-tofino2/switch_tofino_x1.p4" 2

Pipeline(IgParser_downlink(),
         Ig_downlink(),
         IgDeparser_downlink(),
         EgParser_downlink(),
         Eg_downlink(),
         EgDeparser_downlink()) pp_downlink;

//Switch(pp_front, pp_uplink, pp_fabric, pp_downlink) main;
Switch(pp_downlink) main;
