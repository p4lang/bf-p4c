#include <core.p4>
#include <tofino1_specs.p4>
#include <tofino1_base.p4>
#include <tofino1_arch.p4>

typedef bit<48> mac_addr_t;
typedef bit<8> mac_addr_id_t;
typedef bit<16> ethertype_t;
typedef bit<12> vlan_id_t;
typedef bit<32> ipv4_addr_t;
typedef bit<128> ipv6_addr_t;
typedef bit<56> knid_t;
typedef bit<32> port_failover_reg_index_t;
typedef bit<16> ecmp_group_id_t;
typedef bit<8> logical_port_id_t;
typedef bit<3> ring_id_t;

typedef PortId_t port_id_t;
typedef MirrorId_t mirror_id_t;
typedef QueueId_t queue_id_t;
typedef bit<1> int_rule_id_t;




const port_id_t RECIRC_PORT_PIPE_0 = 68;


const bit<8> POSTCARD_VERSION = 0x3;

/* Drop control codes */
const bit<3> DROP_CTL_UNICAST_MULTICAST_RESUBMIT = 0x1;
const bit<3> DROP_CTL_COPY_TO_CPU = 0x2;
const bit<3> DROP_CTL_MIRRORING = 0x4;
const bit<3> DROP_CTL_ALL = DROP_CTL_UNICAST_MULTICAST_RESUBMIT
                            | DROP_CTL_COPY_TO_CPU
                            | DROP_CTL_MIRRORING;

/* Field in bridged metadata or mirror metadata that identifies if the
 * packet is a mirror.
 */
typedef bit<8> switch_pkt_src_t;
const switch_pkt_src_t SWITCH_PKT_SRC_BRIDGE = 0;
const switch_pkt_src_t SWITCH_PKT_SRC_CLONE_INGRESS = 1;
const switch_pkt_src_t SWITCH_PKT_SRC_CLONE_EGRESS = 3;
const switch_pkt_src_t SWITCH_PKT_SRC_COALESCED = 5;

/* Different types of packet mirroring.
 * In ingress, set ig_intr_md_for_dprsr.mirror_type and in egress,
 * set eg_intr_md_for_dprsr.mirror_type. Since there are two metadata fields,
 * it acceptable to use overlapping IDs for ingress and egress.
 */

typedef bit<3> mirror_type_t;




const mirror_type_t MIRROR_TYPE_NONE = 0;
const mirror_type_t MIRROR_TYPE_I2I = 1;
const mirror_type_t MIRROR_TYPE_I2E = 2;
const mirror_type_t MIRROR_TYPE_E2E = 1;
const mirror_type_t MIRROR_TYPE_E2I = 2;

/* CPU Ring ID enum.
 * 0-3 will be used by passthrough table send to host.
 * RING_ID_EGRESS_CPU_PORT(3) will be shared.
 */
const ring_id_t RING_ID_EGRESS_CPU_PORT = 3;
const ring_id_t RING_ID_L2_INGRESS = 4;
const ring_id_t RING_ID_ROUTING_IPV6 = 5;
const ring_id_t RING_ID_USER_PUNT = 6;
const ring_id_t RING_ID_KVS_MULTICAST = 7;

/* Fabric metadata */
struct ig_fabric_metadata_t {
    ipv6_addr_t lkp_ipv6_addr; /* Carries key for the lookup in routing_ipv6 and neighbor tables */
    port_id_t cpu_port; /* CPU hardware port ID */
    bit<1> routing_lkp_flag; /* Indicates if routing table lookup should be performed */
    bit<1> l2_egress_lkp_flag; /* Indicates if l2 egress table lookup should be performed */
    ecmp_group_id_t ecmp_grp_id; /* A key used to lookup in ECMP_groups table */
    mac_addr_id_t neigh_mac; /* Carries mac ID of neighbor MAC address */
    bit<16> flow_hash; /* Hash value of the overlay flow */
    bit<1> passthrough; /* Indicates if the packet must be sent to CPU as-is */
    bit<1> port_disabled; /* If port is disabled, drop all traffic except LLDP */
    logical_port_id_t logical_port_id; /* Each hardware port in the front panel is assigned a logical port ID. */
    MeterColor_t copp_packet_color; /* Store the color value that is returned by the different COPP-related Meters. */
}

struct eg_fabric_metadata_t {
    bit<1> l2_egress_lkp_flag; /* Indicates if l2 egress table lookup should be performed */
    mac_addr_id_t neigh_mac; /* Carries mac ID of neighbor MAC address */
    port_id_t cpu_port; /* Recalculated in egress, does not need to be bridged. */
    bit<16> flow_hash;
}

struct bridged_fabric_metadata_t {
    @flexible mac_addr_id_t neigh_mac;
    @flexible bit<1> l2_egress_lkp_flag;
    @flexible bit<16> flow_hash;
}

/* Metadata header used in mirror packets. This does not necessarily match
 * the header definition below because the compiler can add padding.
 */
const bit<16> MIRROR_SIZE = 24;

header eg_mirror_metadata_t {
    switch_pkt_src_t src;
    @flexible mirror_id_t session_id;
    @flexible port_id_t ingress_port;
    @flexible port_id_t egress_port;
    @flexible queue_id_t queue_id;
    @flexible bit<19> queue_depth;
    @flexible bit<48> ingress_tstamp;
    @flexible bit<48> egress_tstamp;
    @flexible bit<8> sequence_num;
    // @flexible int_rule_id_t rule_id;
}

/* Telemetry metadata */
struct eg_tel_metadata_t {
    bit<1> generate_postcard; /* Set to generate a postcard */
    bit<1> watchlist_hit; /* Set when a packet matches a watchlist rule */
    // int_rule_id_t rule_id;
    bit<8> seq_num;
}

struct eg_parser_metadata_t {
    bit<8> clone_src;
}
# 14 "core/headers/headers.p4" 2

const ethertype_t ETHERTYPE_IPV6 = 0x86dd;
const ethertype_t ETHERTYPE_IPV4 = 0x0800;
const ethertype_t ETHERTYPE_DP_CTRL = 0x99ff;
const ethertype_t ETHERTYPE_VLAN = 0x8100;
// const ethertype_t ETHERTYPE_QINQ      = 0x88a8;
const ethertype_t ETHERTYPE_BF_PKTGEN = 0x9001;
const ethertype_t ETHERTYPE_MPLS_UNICAST = 0x8847;
const ethertype_t ETHERTYPE_MPLS_MULTICAST = 0x8848;

const bit<4> IPV6_VERSION = 0x6;
const bit<4> IPV4_VERSION = 0x4;
const bit<1> MPLS_BOS_1 = 0x1;

const bit<8> UDP_PROTO = 0x11;
const bit<8> TCP_PROTO = 0x6;
const bit<8> GRE_PROTO = 47;
const bit<8> HOP_LIMIT = 64;

const bit<16> KNF_UDP_DST_PORT = 0x38C7;
const bit<16> KNF_UDP_SRC_PORT = 0;
const bit<16> UDP_PORT_VXLAN = 4789;
const bit<16> UDP_PORT_TEL_REPORT = 0x7FFF;

const bit<16> ETH_SIZE = 14;
const bit<16> VLAN_SIZE = 4;
const bit<16> MPLS_SIZE = 4;
const bit<16> IPV4_SIZE = 20;
const bit<16> IPV6_SIZE = 40;
const bit<16> UDP_SIZE = 8;
const bit<16> KNF_SIZE = 12;
const bit<16> VXLAN_SIZE = 8;
const bit<16> GRE_SIZE = 4;
const bit<16> GRE_KEY_SIZE = 4;
const bit<16> POSTCARD_SIZE = 32;
const bit<16> DP_CTRL_SIZE = 14;
const bit<16> FCS_SIZE = 4; // Ethernet FCS that is included in Tofino's packet length metadata.
const bit<3> PKTGEN_APP_PORT_FAILOVER = 0x2;

header pktgen_ext_header_t {
    bit<48> pad;
    ethertype_t etherType;
}

/* Header definition used for lookahead of ethertype */
header check_ethertype_t {
    bit<96> _pad;
    ethertype_t etherType;
}

/* Header definition used for lookahead of pktgen packets */
header check_pktgen_t {
    bit<3> _pad0;
    bit<2> pipe_id;
    bit<3> app_id;
}

header ethernet_t {
    mac_addr_t dstAddr;
    mac_addr_t srcAddr;
    ethertype_t etherType;
}

header ipv6_t {
    bit<4> version;
    bit<8> trafficClass;
    bit<20> flowLabel;
    bit<16> payloadLen;
    bit<8> nextHdr;
    bit<8> hopLimit;
    ipv6_addr_t srcAddr;
    ipv6_addr_t dstAddr;
}

header ipv4_t {
    bit<4> version;
    bit<4> ihl;
    bit<8> diffserv;
    bit<16> totalLen;
    bit<16> identification;
    bit<3> flags;
    bit<13> fragOffset;
    bit<8> ttl;
    bit<8> protocol;
    bit<16> hdrChecksum;
    ipv4_addr_t srcAddr;
    ipv4_addr_t dstAddr;
}

header ipv4_option_t {
    bit<8> type;
    bit<8> len;
    bit<16> value;
}

/* Carries metadata for packets that are forwarded to/from CPU */
header dp_ctrl_header_t {
    bit<5> _pad0; /* This padding is needed because the ring identifier corresponds
                    * to the 3 lower bits in the first byte of the packet
                    */
    ring_id_t ring_id; /* Ring Identifier */
    bit<72> _pad1; /* 9 Bytes of padding needed to match a regular Ethernet Header size */
    bit<16> port; /* input/output port */
    bit<16> etherType; /* Ethertype of ETHERTYPE_DP_CTRL */
}

header vlan_t {
    bit<3> pcp;
    bit<1> cfi;
    vlan_id_t vlanID;
    ethertype_t etherType;
}

header mpls_t {
    bit<20> label;
    bit<3> exp; /* Experimental. Used for QoS. */
    bit<1> bos; /* Bottom of Label Stack. Last Label has S-bit set 1. */
    bit<8> ttl;
}

header ip46_t { /* Common for both IPv4 and IPv6 */
    bit<4> version;
    bit<4> reserved;
}

header udp_t {
    bit<16> srcPort;
    bit<16> dstPort;
    bit<16> hdrLen;
    bit<16> checksum;
}

header tcp_t {
    bit<16> srcPort;
    bit<16> dstPort;
    bit<32> seqNum;
    bit<32> ackNum;
    bit<4> dataOffset;
    bit<4> reserved;
    bit<8> flags;
    bit<16> window;
    bit<16> checksum;
    bit<16> urgentPtr;
}

header vxlan_t {
    bit<8> flags;
    bit<24> reserved;
    bit<24> vni;
    bit<8> reserved2;
}

header gre_t {
    bit<1> checksumPresent;
    bit<1> routingPresent;
    bit<1> keyPresent;
    bit<1> sequencePresent;
    bit<9> reserved0;
    bit<3> version;
    bit<16> protocolType;
}

header gre_key_t {
    bit<32> key;
}

header knf_t {
    bit<4> version;
    bit<4> pType;
    knid_t knid; /* OEType : 8; IDID : 16; VNI : 32; */
    /* bit<16> hdrMap; */
    bit<16> remoteLagID; /* TODO: this field used to be hdrMap. We need to put
                          * it back when KNF header extensions are supported.
                          */
    bit<1> hdrElided;
    bit<7> reserved;
    bit<8> telSequenceNum;
}

@pa_no_overlay("egress", "hdr.postcard_header.rule_id")
@pa_no_overlay("egress", "hdr.postcard_header.sequence_num")
@pa_no_overlay("egress", "hdr.postcard_header.switch_id")
@pa_no_overlay("egress", "hdr.postcard_header.queue_id")
@pa_no_overlay("egress", "hdr.postcard_header.queue_depth")
header postcard_header_t {
    bit<8> version;
    bit<16> rule_id;
    bit<8> sequence_num;
    bit<64> switch_id;
    bit<16> ingress_port;
    bit<16> egress_port;
    bit<8> queue_id;
    bit<24> queue_depth;
    bit<48> ingress_tstamp;
    bit<48> egress_tstamp;
}
# 19 "leaf.p4" 2
# 1 "core/modules/common.p4" 1
/****************************************************************
 * Copyright (c) Kaloom, 2019
 *
 * This unpublished material is property of Kaloom Inc.
 * All rights reserved.
 * Reproduction or distribution, in whole or in part, is
 * forbidden except by express written permission of Kaloom Inc.
 ****************************************************************/




/* Action used to bypass the egress pipeline and directly forward the packet
 * to output. It is used when there is no more processing required like
 * when control packets are coming from CPU.
 */
control BypassAndExit(inout ingress_intrinsic_metadata_for_tm_t ig_tm_md) {

    action bypass_and_exit() {
        ig_tm_md.bypass_egress = 1;
        exit;
    }

    apply {
        bypass_and_exit();
    }
}
# 20 "leaf.p4" 2
# 1 "core/types.p4" 1
/****************************************************************
 * Copyright (c) Kaloom, 2019
 *
 * This unpublished material is property of Kaloom Inc.
 * All rights reserved.
 * Reproduction or distribution, in whole or in part, is
 * forbidden except by express written permission of Kaloom Inc.
 ****************************************************************/
# 21 "leaf.p4" 2
# 1 "types.p4" 1
/****************************************************************
 * Copyright (c) Kaloom, 2019
 *
 * This unpublished material is property of Kaloom Inc.
 * All rights reserved.
 * Reproduction or distribution, in whole or in part, is
 * forbidden except by express written permission of Kaloom Inc.
 ****************************************************************/







# 1 "/mnt/build/p4c/p4include/tofino1_base.p4" 1
# 17 "types.p4" 2


# 1 "core/types.p4" 1
/****************************************************************
 * Copyright (c) Kaloom, 2019
 *
 * This unpublished material is property of Kaloom Inc.
 * All rights reserved.
 * Reproduction or distribution, in whole or in part, is
 * forbidden except by express written permission of Kaloom Inc.
 ****************************************************************/
# 20 "types.p4" 2
# 1 "core/headers/headers.p4" 1
/****************************************************************
 * Copyright (c) Kaloom, 2019
 *
 * This unpublished material is property of Kaloom Inc.
 * All rights reserved.
 * Reproduction or distribution, in whole or in part, is
 * forbidden except by express written permission of Kaloom Inc.
 ****************************************************************/
# 21 "types.p4" 2

typedef bit<16> nw_id_t;
typedef bit<10> dest_id_t;
typedef bit<7> tunnel_id_t; // KVTEP ID in VxlAN or tunnel interface ID in GRE
typedef bit<7> remote_vtep_id_t;
typedef MulticastGroupId_t mcast_grp_id_t;
typedef bit<16> exclusion_id_t;
typedef bit<7> vrouter_id_t;
typedef bit<8> vrouter_iface_id_t; /* impacts KVTEP_RESERVED_IFACE_ID */
typedef bit<24> vni_t;
typedef bit<9> iface_id_t;
typedef bit<32> lag_failover_reg_index_t;
typedef bit<13> meter_index_t;
typedef bit<16> vrouter_mac_id_t;
typedef bit<8> vrf_id_t;

const bit<2> PKT_TYPE_UNTAGGED = 0;
const bit<2> PKT_TYPE_VLAN = 1;
const bit<2> PKT_TYPE_KNF = 2;
// const bit<2> PKT_TYPE_QINQ = 3;

const bit<2> PORT_TYPE_NONE = 0;
const bit<2> PORT_TYPE_FABRIC = 1;
const bit<2> PORT_TYPE_USER = 2;
const bit<2> PORT_TYPE_KVS = 3;

const bit<32> MCAST_HASH_SIZE = 65536;
const bit<1> MCAST_HASH_BASE = 0;

const bit<2> KTEP_SRC_OTHER = 0; /* user port or vrouter */
const bit<2> KTEP_SRC_LEAF = 1;
const bit<2> KTEP_SRC_KVS = 2;

const bit<2> TUNNEL_PKT_TYPE_RAW = 0;
const bit<2> TUNNEL_PKT_TYPE_VXLAN = 1;
const bit<2> TUNNEL_PKT_TYPE_GRE = 2;

/* Learning digest structures */
typedef bit<3> digest_type_t;
const digest_type_t DIGEST_TYPE_LOCAL_MAC_LEARNING = 1;
const digest_type_t DIGEST_TYPE_KVS_MAC_LEARNING = 2;
const digest_type_t DIGEST_TYPE_KVS_MULTICAST_LEARNING = 3;
const digest_type_t DIGEST_TYPE_REMOTE_VTEP_V4_MAC_LEARNING = 4;
const digest_type_t DIGEST_TYPE_REMOTE_VTEP_V6_MAC_LEARNING = 5;

typedef bit<3> gre_decap_op_t;
const gre_decap_op_t GRE_DECAP_NONE = 0;
const gre_decap_op_t GRE_DECAP_IPV4 = 1;
const gre_decap_op_t GRE_DECAP_IPV4_KEY = 2;
const gre_decap_op_t GRE_DECAP_IPV6 = 3;
const gre_decap_op_t GRE_DECAP_IPV6_KEY = 4;

struct local_mac_learning_digest_t {
    iface_id_t ktep_meta_ingress_iface_id;
    vlan_id_t ktep_meta_ingress_vlan_id;
    nw_id_t ktep_meta_learn_nw_id;
    mac_addr_t inner_ethernet_srcAddr;
}

struct kvs_multicast_learning_digest_t {
    port_id_t ig_intr_md_ingress_port;
    mac_addr_t ethernet_srcAddr;
    ipv6_addr_t ipv6_srcAddr;
}

struct vtep_v4_learning_digest_t {
    mac_addr_t vxlan_inner_ethernet_srcAddr;
    ipv4_addr_t ipv4_srcAddr;
    vrouter_id_t ktep_router_meta_router_id;
    vni_t vxlan_vni;
}

struct vtep_v6_learning_digest_t {
    mac_addr_t vxlan_inner_ethernet_srcAddr;
    ipv6_addr_t ipv6_srcAddr;
    vrouter_id_t ktep_router_meta_router_id;
    vni_t vxlan_vni;
}

/* Port Metadata. Must be 64 bits in tofino1 and 192 in tofino2.
 * Refer: PORT_METADATA_SIZE
 */
struct port_metadata_t {
    logical_port_id_t logical_port_id; // 8b
    bit<2> port_type;
    bit<1> disabled; /* A property for user & fabric ports.
                      * In case of a bad configuration of a port,
                      * all traffic will be disabled except LLDP
                      * packets. Those will be punted to CP/CPU.
                      */
    iface_id_t iface_id; // 9b
}

/* Bridge Metadata */
struct bridged_ktep_metadata_t {
    @flexible vlan_id_t ingress_vlan_id;
    @flexible vlan_id_t egress_vlan_id;
    @flexible bit<1> knf_tunnel_terminated;
    @flexible bit<1> processing_user_pkt;
    @flexible bit<2> egress_pkt_type;
    @flexible bit<1> process_l2;
    @flexible bit<1> process_l3;
    @flexible dest_id_t dest_id;
    @flexible bit<1> received_on_punt_channel;
    @flexible bit<1> is_from_kvs;
    @flexible bit<2> pkt_src;
    @flexible nw_id_t nw_id;
    @flexible bit<1> send_to_kvs;
    @flexible iface_id_t ingress_iface_id;
    @flexible iface_id_t egress_iface_id;
    @flexible bit<16> pkt_length_offset;
}

struct bridged_ktep_router_metadata_t {
    @flexible vrouter_id_t router_id;
    @flexible vrouter_iface_id_t output_iface;
    @flexible vrouter_mac_id_t dst_mac_id;
    @flexible bit<1> process_l2_egress;
    @flexible bit<1> mpls_decap;
}

struct bridged_tunnel_metadata_t {
    @flexible bit<2> egress_pkt_type;
    @flexible bit<1> process_egress;
    @flexible tunnel_id_t tunnel_id;
    @flexible tunnel_id_t remote_vtep_id;
}

struct bridged_tel_metadata_t {
    @flexible bit<1> generate_postcard; /* Set to generate a postcard */
    @flexible bit<1> watchlist_hit; /* Set when a packet matches a watchlist rule */
    // @flexible int_rule_id_t rule_id;
    @flexible bit<8> seq_num;
}

/* User-defined metadata carried over from ingress to egress */
@pa_alias("ingress", "hdr.bridged_md.fabric_meta_neigh_mac", "ig_md.fabric_meta.neigh_mac")
header bridged_metadata_t {
    switch_pkt_src_t src;
    @flexible port_id_t ingress_port;
    @flexible bit<48> ingress_tstamp;
    bridged_fabric_metadata_t fabric_meta;
    bridged_ktep_metadata_t ktep_meta;
    bridged_ktep_router_metadata_t ktep_router_meta;
    bridged_tunnel_metadata_t tunnel_meta;
    bridged_tel_metadata_t tel_metadata;
}

/* Header structure */
@pa_mutually_exclusive("ingress", "hdr.pktgen_port_down.packet_id", "hdr.vlan.etherType")
@pa_mutually_exclusive("ingress", "hdr.pktgen_port_down.packet_id", "hdr.dp_ctrl_hdr.port")
@pa_mutually_exclusive("ingress", "hdr.vlan.etherType", "hdr.dp_ctrl_hdr.port")
@pa_mutually_exclusive("ingress", "hdr.pktgen_ext_header.etherType", "hdr.inner_ipv4.totalLen")
@pa_mutually_exclusive("ingress", "hdr.pktgen_ext_header.etherType", "hdr.inner_ipv6.payloadLen")
@pa_mutually_exclusive("ingress", "hdr.inner_ipv4.totalLen", "hdr.inner_ipv6.payloadLen")
@pa_mutually_exclusive("ingress", "ig_md.ktep_router_meta.pkt_len", "ig_md.fabric_meta.ecmp_grp_id")
struct ingress_header_t {
    bridged_metadata_t bridged_md; // not parsed
    dp_ctrl_header_t dp_ctrl_hdr;
    pktgen_port_down_header_t pktgen_port_down;
    pktgen_ext_header_t pktgen_ext_header;
    ethernet_t ethernet;
    ipv6_t ipv6;
    udp_t udp;
    knf_t knf;
    ethernet_t inner_ethernet;
    vlan_t vlan;
    // vlan_t qinq;
    mpls_t mpls;
    ipv4_t inner_ipv4;
    ipv4_option_t inner_ipv4_option;
    ipv6_t inner_ipv6;
    gre_t gre;
    gre_key_t gre_key;
    udp_t inner_udp;
    tcp_t inner_tcp;
    vxlan_t vxlan;
    ethernet_t vxlan_inner_ethernet;
    ipv4_t tunnel_inner_ipv4;
    ipv6_t tunnel_inner_ipv6;
    udp_t vxlan_inner_udp;
}

@pa_mutually_exclusive("egress", "hdr.inner_ipv4", "hdr.inner_ipv6")
@pa_mutually_exclusive("egress", "hdr.vlan", "hdr.postcard_header")
@pa_mutually_exclusive("egress", "hdr.encap_vxlan", "hdr.postcard_header")
@pa_mutually_exclusive("egress", "hdr.postcard_header", "hdr.inner_ipv4")
@pa_mutually_exclusive("egress", "hdr.postcard_header", "hdr.inner_ipv4_option")
@pa_mutually_exclusive("egress", "hdr.postcard_header", "hdr.inner_ipv6")
@pa_mutually_exclusive("egress", "hdr.postcard_header", "hdr.inner_ethernet")
@pa_mutually_exclusive("egress", "hdr.postcard_header", "hdr.mpls")
@pa_mutually_exclusive("egress", "hdr.postcard_header", "hdr.encap_gre")
@pa_mutually_exclusive("egress", "hdr.postcard_header", "hdr.encap_gre_key")
@pa_mutually_exclusive("egress", "hdr.encap_vlan", "hdr.vlan")
@pa_mutually_exclusive("egress", "hdr.encap_ipv4", "hdr.encap_ipv6")
@pa_mutually_exclusive("egress", "hdr.encap_gre", "hdr.encap_udp")
@pa_mutually_exclusive("egress", "hdr.encap_gre_key", "hdr.encap_udp")
@pa_mutually_exclusive("egress", "hdr.encap_gre", "hdr.encap_vxlan")
@pa_mutually_exclusive("egress", "hdr.encap_gre_key", "hdr.encap_vxlan")
struct egress_header_t {
    bridged_metadata_t bridged_md;
    dp_ctrl_header_t dp_ctrl_hdr; // not parsed
    ethernet_t ethernet;
    ipv6_t ipv6;
    udp_t udp;
    knf_t knf;
    ethernet_t encap_ethernet; // not parsed
    vlan_t encap_vlan; // not parsed
    ipv4_t encap_ipv4; // not parsed
    ipv6_t encap_ipv6; // not parsed
    gre_t encap_gre; // not parsed
    gre_key_t encap_gre_key; // not parsed
    udp_t encap_udp; // not parsed
    vxlan_t encap_vxlan; // not parsed
    postcard_header_t postcard_header; // not parsed
    ethernet_t inner_ethernet;
    vlan_t vlan;
    // vlan_t qinq;
    mpls_t mpls;
    ipv4_t inner_ipv4;
    ipv4_option_t inner_ipv4_option;
    ipv6_t inner_ipv6;
}

struct ig_ktep_port_metadata_t {
    bit<2> port_type;
}

/* KTEP metadata */
/* ig_md.ktep_meta.ingress_port and ig_intr_md.ingress_port are aliased to
 * to avoid PHV allocation issues. The program can't compile without this aliasing
 * while the aliasing generates a compiler warning. Hence the alias is retained
 * at the cost of a warning.
 * Refer Barefoot case:
 * https://support.barefootnetworks.com/hc/en-us/requests/12300
 */
@pa_alias("ingress", "ig_md.ktep_meta.ingress_port", "ig_intr_md.ingress_port")
/* egress_vlan_id and remote_lag_id are mutually exclusive. By using pa_alias,
 * the compiler uses the same memory for both metadata and this allows us to
 * only bridge the egress_vlan_id to transport both metadata.
 */
@pa_alias("ingress", "ig_md.ktep_meta.egress_vlan_id", "ig_md.ktep_meta.remote_lag_id")
struct ig_ktep_metadata_t {
    /* Overlay MAC addresses. These correspond to outer MACs if from user
     * port and inner MACs if from a fabric port
     */
    mac_addr_t src_mac;
    mac_addr_t dst_mac;
    vlan_id_t ingress_vlan_id;
    vlan_id_t egress_vlan_id;
    bit<2> ingress_pkt_type;
    bit<2> egress_pkt_type;
    bit<1> learn; /* Indicates that the source MAC address should be learned */
    bit<1> process_l2; /* Indicates that the packet should be processed in the L2 Table */
    bit<1> process_l3; /* Indicates that the packet should be processed in the L3 Table */
    dest_id_t dest_id; /* ID of destination IP address (Remote leaf or punt IP) */
    bit<1> received_on_punt_channel; /* The punt channel is used to communicate
                                        * with the vRouter control plane services
                                        * via an isolated L2 network.
                                        */
    bit<1> is_from_kvs; /* Indicates that the packet came from a KVS */
    bit<2> pkt_src;
    nw_id_t nw_id; /* Network identifier associated to a KNID for an L2 network */
    nw_id_t learn_nw_id; /* Network identifier to be sent in the learning digest */
    bit<1> send_to_kvs; /* Indicates that the packet will be sent to a KVS */
    port_id_t ingress_port;
    iface_id_t ingress_iface_id; /* Represents port or LAG the packet was received on */
    iface_id_t egress_iface_id; /* Represents port or LAG the packet is sent on */
    bit<1> l2_lkp_flag;
    bit<1> is_icl; /* Identifies a packet that came from ICL which should not go
                    * to vnet_dmac table.
                    */
    iface_id_t remote_lag_id;
    MeterColor_t mcast_pkt_color;
    bit<16> pkt_length_offset; /* Keep track of the bytes that were removed due
                                 * the decapsulation of headers in the ingress
                                 * pipeline.
                                 */
    bit<1> knf_tunnel_terminated; /* Indicates that the KNF tunnel was
                                    * terminated on this leaf and that the KNF
                                    * headers were decapsulated.
                                    */
    bit<1> processing_user_pkt; /* Indicates that a user packet is being
                                  * processed. This can be from a user port or
                                  * from a KNF tunnel that was terminated.
                                  */
}

/* VRouter metadata */
@pa_alias("ingress", "hdr.inner_ipv6.nextHdr", "hdr.inner_ipv4.protocol")
struct ig_ktep_router_metadata_t {
    vrouter_id_t router_id;
    bit<1> is_not_ip; /* Packet is not of types IPV4 or IPv6 */
    ipv6_addr_t dst_ipAddr; /* IPv6 address that represent the IPv4 or IPv6
                             * destination address in the packet. It is used to
                             * lookup in ktep_l3 and ktep_neigh tables.
                             */
    ipv6_addr_t src_ipAddr;
    vrouter_iface_id_t input_iface; /* vRouter's input interface */
    vrouter_iface_id_t output_iface; /* vRouter's output interface */
    vrouter_mac_id_t dst_mac_id; /* Nexthop destination MAC Identifier */
    bit<1> process_l2_egress;
    bit<1> punt; /* Indicates if the packet should be sent on punt channel */
    bit<16> pkt_len; /* Size of IP packet */
    bit<16> mtu_pkt_diff;
    bit<1> neigh_lkp; /* Indicates whether the vrouter neighbor lookup should
                        *  be performed.
                        */
    MeterColor_t meter_color;
    vrf_id_t vrf_id;
    bit<1> mpls_decap;
    gre_decap_op_t gre_decap_op; // GRE decapsulation operation
}

/* Tunnel (VxLAN, GRE) metadata */
struct ig_tunnel_metadata_t {
    bit<2> egress_pkt_type;
    bit<1> process_egress;
    tunnel_id_t tunnel_id;
    remote_vtep_id_t remote_vtep_id;
    bit<1> learn_inner; /* Indicates if we should learn hosts behind VTEP */
}

/* INT metadata */
struct ig_tel_metadata_t {
    bit<16> tel_hash;
    bit<1> generate_postcard; /* Set to generate a postcard */
    bit<1> watchlist_hit; /* Set when a packet matches a watchlist rule */
    int_rule_id_t rule_id;
    bit<8> seq_num;
}

/* Ingress Metadata */
@pa_mutually_exclusive("ingress", "ig_md.ktep_router_meta.dst_ipAddr","ig_md.fabric_meta.lkp_ipv6_addr")
@pa_mutually_exclusive("ingress", "hdr.pktgen_port_down.packet_id", "hdr.vlan.etherType")
@pa_mutually_exclusive("ingress", "hdr.pktgen_port_down.packet_id", "hdr.dp_ctrl_hdr.port")
@pa_mutually_exclusive("ingress", "hdr.vlan.etherType", "hdr.dp_ctrl_hdr.port")
@pa_mutually_exclusive("ingress", "hdr.pktgen_ext_header.etherType", "hdr.inner_ipv4.totalLen")
@pa_mutually_exclusive("ingress", "hdr.pktgen_ext_header.etherType", "hdr.inner_ipv6.payloadLen")
@pa_mutually_exclusive("ingress", "hdr.inner_ipv4.totalLen", "hdr.inner_ipv6.payloadLen")
@pa_mutually_exclusive("ingress", "ig_md.ktep_router_meta.pkt_len", "ig_md.fabric_meta.ecmp_grp_id")
@pa_alias("ingress", "ig_md.ingress_mac_tstamp", "hdr.bridged_md.ingress_tstamp") // 48 bits
struct ingress_metadata_t {
    port_metadata_t port_md;
    ig_fabric_metadata_t fabric_meta;
    ig_ktep_metadata_t ktep_meta;
    ig_tel_metadata_t tel_metadata;
    ig_ktep_router_metadata_t ktep_router_meta;
    ig_tunnel_metadata_t tunnel_meta;
    ig_ktep_port_metadata_t ktep_port_meta;
    local_mac_learning_digest_t local_mac_learning;
    kvs_multicast_learning_digest_t kvs_multicast_learning;
    vtep_v4_learning_digest_t vtep_v4_learning;
    vtep_v6_learning_digest_t vtep_v6_learning;
    bit<48> ingress_mac_tstamp;
    /* Please note that the flag used in egress metadata is ip_options_supported
     * The reason behind using the different flags names for egress and ingress metadata is:
     * https://support.barefootnetworks.com/hc/en-us/requests/11397
     * In the ingress, the requirement is to punt ipv4 packets with unsupported options
     * to the control plane. This means packets with ihl 7 to 15 need to be punted. This flag
     * represents such packets. To be noted is that packets with ihl < 5 are not considered
     * to be valid ipv4 packets and we can have such non-ip packets in the ingress as well.
     * Hence naming all other packets as ip_options_supported would not be apt here.
     */
    bit<1> ip_options_unsupported;
}

@pa_alias("egress", "eg_md.ktep_meta.egress_vlan_id", "eg_md.ktep_meta.remote_lag_id")

/* eg_md.tel_metadata.seq_num hdr.knf.telSequenceNum are aliased to
 * to avoid PHV allocation issues.
 * Refer Barefoot case on why the compiler warning isn't resolved:
 * https://support.barefootnetworks.com/hc/en-us/requests/12300
 */
@pa_alias("egress", "eg_md.tel_metadata.seq_num", "hdr.knf.telSequenceNum")
@pa_no_overlay("egress", "hdr.mpls.label")
struct eg_ktep_metadata_t {
    vlan_id_t ingress_vlan_id;
    vlan_id_t egress_vlan_id;
    bit<16> payload_length;
    bit<2> egress_pkt_type;
    bit<1> process_l2;
    bit<1> process_l3;
    dest_id_t dest_id;
    bit<1> received_on_punt_channel;
    bit<1> is_from_kvs;
    bit<2> pkt_src;
    nw_id_t nw_id;
    bit<1> send_to_kvs;
    iface_id_t ingress_iface_id;
    iface_id_t egress_iface_id;
    iface_id_t remote_lag_id;
    bit<16> pkt_length_offset;
    bit<1> knf_tunnel_terminated;
    bit<1> processing_user_pkt;
}

struct eg_ktep_router_metadata_t {
    vrouter_id_t router_id;
    vrouter_iface_id_t output_iface;
    mac_addr_t src_mac;
    mac_addr_t dst_mac;
    vrouter_mac_id_t dst_mac_id;
    bit<1> process_l2_egress;
    bit<1> mpls_decap;
    MeterColor_t meter_color;
}

struct eg_tunnel_metadata_t {
    bit<2> egress_pkt_type;
    bit<1> process_egress;
    tunnel_id_t tunnel_id;
    remote_vtep_id_t remote_vtep_id;
}

/* Egress Metadata */
@pa_no_overlay("egress", "eg_md.mirror.src")
@pa_no_overlay("egress", "eg_md.mirror.session_id")
@pa_no_overlay("egress", "eg_md.mirror.ingress_port")
@pa_no_overlay("egress", "eg_md.mirror.egress_port")
@pa_no_overlay("egress", "eg_md.mirror.queue_id")
@pa_no_overlay("egress", "eg_md.mirror.queue_depth")
@pa_no_overlay("egress", "eg_md.mirror.ingress_tstamp")
@pa_no_overlay("egress", "eg_md.mirror.egress_tstamp")
@pa_no_overlay("egress", "eg_md.mirror.sequence_num")
// @pa_no_overlay("egress", "eg_md.mirror.rule_id")
/* WARNING: For PHV allocation efficiency, each mirror header needs to be overlayed
 * with an egress metadata field of an equal or bigger size.
 * Make sure the list below remains relevant.
 * Check in pa.characterize.log that the compiler is applying the annotations below.
 */
@pa_mutually_exclusive("egress", "eg_md.mirror.src", "eg_md.ktep_meta.ingress_vlan_id") // 8 bits
@pa_mutually_exclusive("egress", "eg_md.mirror.session_id", "eg_md.ktep_meta.dest_id") // 10 bits
@pa_mutually_exclusive("egress", "eg_md.mirror.ingress_port", "eg_md.ingress_port") // 9 bits
@pa_mutually_exclusive("egress", "eg_md.mirror.egress_port", "eg_md.ktep_meta.egress_iface_id") // 9 bits
@pa_mutually_exclusive("egress", "eg_md.mirror.queue_id", "eg_md.tunnel_meta.remote_vtep_id") // 5 bits
@pa_mutually_exclusive("egress", "eg_md.mirror.queue_depth", "eg_md.ktep_router_meta.src_mac") // 19 bits
@pa_mutually_exclusive("egress", "eg_md.mirror.ingress_tstamp", "hdr.bridged_md.ingress_tstamp") // 48 bits
@pa_mutually_exclusive("egress", "eg_md.mirror.egress_tstamp", "eg_md.ktep_router_meta.dst_mac") // 48 bits
@pa_mutually_exclusive("egress", "eg_md.mirror.sequence_num", "eg_md.ktep_meta.nw_id") // 8 bits
struct egress_metadata_t {
    port_id_t ingress_port;
    eg_fabric_metadata_t fabric_meta;
    eg_parser_metadata_t parser_metadata;
    eg_ktep_metadata_t ktep_meta;
    eg_ktep_router_metadata_t ktep_router_meta;
    eg_tunnel_metadata_t tunnel_meta;
    eg_mirror_metadata_t mirror;
    eg_tel_metadata_t tel_metadata;
    /* Please note that the flag used in ingress metadata is ip_options_unsupported
     * https://support.barefootnetworks.com/hc/en-us/requests/11397
     * In the egress, as noted in the barefoot ticket  above, we needed a workaround
     * so that the ipv4 checksum is calculated only for ipv4 packets with supported
     * ip options. This represents ip packets with ihl 5 and 6. These are represented
     * by the below flag.
     */
    bit<1> ip_options_supported;
}
# 22 "leaf.p4" 2
# 1 "parde.p4" 1
/****************************************************************
 * Copyright (c) Kaloom, 2019
 *
 * This unpublished material is property of Kaloom Inc.
 * All rights reserved.
 * Reproduction or distribution, in whole or in part, is
 * forbidden except by express written permission of Kaloom Inc.
 ****************************************************************/




# 1 "core/headers/headers.p4" 1
/****************************************************************
 * Copyright (c) Kaloom, 2019
 *
 * This unpublished material is property of Kaloom Inc.
 * All rights reserved.
 * Reproduction or distribution, in whole or in part, is
 * forbidden except by express written permission of Kaloom Inc.
 ****************************************************************/
# 14 "parde.p4" 2
# 1 "core/types.p4" 1
/****************************************************************
 * Copyright (c) Kaloom, 2019
 *
 * This unpublished material is property of Kaloom Inc.
 * All rights reserved.
 * Reproduction or distribution, in whole or in part, is
 * forbidden except by express written permission of Kaloom Inc.
 ****************************************************************/
# 15 "parde.p4" 2
# 1 "types.p4" 1
/****************************************************************
 * Copyright (c) Kaloom, 2019
 *
 * This unpublished material is property of Kaloom Inc.
 * All rights reserved.
 * Reproduction or distribution, in whole or in part, is
 * forbidden except by express written permission of Kaloom Inc.
 ****************************************************************/
# 16 "parde.p4" 2
# 1 "core/parsers/tofino_parser.p4" 1
/****************************************************************
 * Copyright (c) Kaloom, 2019
 *
 * This unpublished material is property of Kaloom Inc.
 * All rights reserved.
 * Reproduction or distribution, in whole or in part, is
 * forbidden except by express written permission of Kaloom Inc.
 ****************************************************************/




parser TofinoIngressParser(
        packet_in pkt,
        inout ingress_metadata_t ig_md,
        inout ingress_intrinsic_metadata_t ig_intr_md) {
    state start {
        pkt.extract(ig_intr_md);
        ig_md.ingress_mac_tstamp = ig_intr_md.ingress_mac_tstamp;
        transition select(ig_intr_md.resubmit_flag) {
            1 : parse_resubmit;
            0 : parse_port_metadata;
        }
    }

    state parse_resubmit {
        /* Parse resubmitted packet here */
        transition reject;
    }

    state parse_port_metadata {
        ig_md.port_md = port_metadata_unpack<port_metadata_t>(pkt);

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
# 17 "parde.p4" 2
# 1 "core/deparsers/egress_mirror.p4" 1
/****************************************************************
 * Copyright (c) Kaloom, 2019
 *
 * This unpublished material is property of Kaloom Inc.
 * All rights reserved.
 * Reproduction or distribution, in whole or in part, is
 * forbidden except by express written permission of Kaloom Inc.
 ****************************************************************/




/* Egress to Egress Mirroring */
control EgressMirror(
    in egress_metadata_t eg_md,
    in egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr) {

    Mirror() mirror;

    apply {
        if (eg_intr_md_for_dprsr.mirror_type == MIRROR_TYPE_E2E) {
            mirror.emit<eg_mirror_metadata_t>(eg_md.mirror.session_id,
                    eg_md.mirror);
        }
    }
}
# 18 "parde.p4" 2




/* Ingress Parser */
parser SwitchIngressParser(
        packet_in pkt,
        out ingress_header_t hdr,
        out ingress_metadata_t ig_md,
        out ingress_intrinsic_metadata_t ig_intr_md) {

    TofinoIngressParser() tofino_parser;
    Checksum() ipv4_checksum;
    Checksum() tunnel_inner_ipv4_checksum;

    state start {
        /**
          * Most of the metadata initialization
          * is disabled/commented to avoid PHV allocation issues on Tofino2,
          * as recommended by Intel. Only those that are
          * expected to be initialized by the pipeline are initialized here.
          */

        ig_md.fabric_meta.routing_lkp_flag = 0;
        ig_md.fabric_meta.l2_egress_lkp_flag = 0;
        ig_md.ktep_meta.process_l2 = 0;
        ig_md.ktep_meta.send_to_kvs = 0;
        ig_md.ktep_meta.egress_iface_id = 0;
        ig_md.ktep_meta.l2_lkp_flag = 0;
        ig_md.ktep_meta.is_icl = 0;
        ig_md.ktep_meta.remote_lag_id = 0;
        ig_md.ktep_meta.pkt_length_offset = FCS_SIZE;
        ig_md.ktep_meta.knf_tunnel_terminated = 0;
        ig_md.ktep_meta.processing_user_pkt = 0;
        ig_md.ktep_router_meta.router_id = 0;
        ig_md.ktep_router_meta.punt = 0;
        ig_md.ktep_router_meta.gre_decap_op = GRE_DECAP_NONE;


        // Since Tofino1 has more PHVs, we init all metadata
        ig_md.port_md.logical_port_id = 0;
        ig_md.port_md.port_type = 0;
        ig_md.port_md.disabled = 0;
        ig_md.port_md.iface_id = 0;

        ig_md.ktep_meta.learn_nw_id = 0;
        ig_md.fabric_meta.lkp_ipv6_addr = 0;
        ig_md.fabric_meta.ecmp_grp_id = 0;
        ig_md.fabric_meta.neigh_mac = 0;
        ig_md.fabric_meta.flow_hash = 0;
        ig_md.fabric_meta.passthrough = 0;
        ig_md.fabric_meta.port_disabled = 0;
        ig_md.fabric_meta.logical_port_id = 0;
        ig_md.fabric_meta.copp_packet_color = MeterColor_t.GREEN;

        ig_md.ktep_meta.nw_id = 0;
        ig_md.ktep_meta.pkt_src = 0;
        ig_md.ktep_meta.is_from_kvs = 0;
        ig_md.ktep_meta.src_mac = 0;
        ig_md.ktep_meta.dst_mac = 0;
        ig_md.ktep_meta.ingress_vlan_id = 0;
        ig_md.ktep_meta.egress_vlan_id = 0;
        ig_md.ktep_meta.ingress_pkt_type = PKT_TYPE_UNTAGGED;
        ig_md.ktep_meta.egress_pkt_type = 0;
        ig_md.ktep_meta.learn = 0;
        ig_md.ktep_meta.process_l3 = 0;
        ig_md.ktep_meta.dest_id = 0;
        ig_md.ktep_meta.received_on_punt_channel = 0;
        ig_md.ktep_meta.ingress_port = 0;
        ig_md.ktep_meta.ingress_iface_id = 0;
        ig_md.ktep_meta.mcast_pkt_color = MeterColor_t.GREEN;

        ig_md.tel_metadata.tel_hash = 0;
        ig_md.tel_metadata.generate_postcard = 0;
        ig_md.tel_metadata.watchlist_hit = 0;
        ig_md.tel_metadata.rule_id = 0;
        ig_md.tel_metadata.seq_num = 0;

        ig_md.ktep_router_meta.is_not_ip = 0;
        ig_md.ktep_router_meta.dst_ipAddr = 0;
        ig_md.ktep_router_meta.input_iface = 0;
        ig_md.ktep_router_meta.output_iface = 0;
        ig_md.ktep_router_meta.dst_mac_id = 0;
        ig_md.ktep_router_meta.process_l2_egress = 0;
        ig_md.ktep_router_meta.neigh_lkp = 0;
        ig_md.ktep_router_meta.mpls_decap = 0;
        ig_md.ktep_router_meta.vrf_id = 0;

        ig_md.tunnel_meta.egress_pkt_type = 0;
        ig_md.tunnel_meta.process_egress = 0;
        ig_md.tunnel_meta.tunnel_id = 0;
        ig_md.tunnel_meta.remote_vtep_id = 0;
        ig_md.tunnel_meta.learn_inner = 0;

        ig_md.ktep_port_meta.port_type = 0;

        ig_md.local_mac_learning.ktep_meta_ingress_iface_id = 0;
        ig_md.local_mac_learning.ktep_meta_ingress_vlan_id = 0;
        ig_md.local_mac_learning.ktep_meta_learn_nw_id = 0;
        ig_md.local_mac_learning.inner_ethernet_srcAddr = 0;

        ig_md.kvs_multicast_learning.ig_intr_md_ingress_port = 0;
        ig_md.kvs_multicast_learning.ethernet_srcAddr = 0;
        ig_md.kvs_multicast_learning.ipv6_srcAddr = 0;

        ig_md.vtep_v4_learning.vxlan_inner_ethernet_srcAddr = 0;
        ig_md.vtep_v4_learning.ipv4_srcAddr = 0;
        ig_md.vtep_v4_learning.ktep_router_meta_router_id = 0;
        ig_md.vtep_v4_learning.vxlan_vni = 0;

        ig_md.vtep_v6_learning.vxlan_inner_ethernet_srcAddr = 0;
        ig_md.vtep_v6_learning.ipv6_srcAddr = 0;
        ig_md.vtep_v6_learning.ktep_router_meta_router_id = 0;
        ig_md.vtep_v6_learning.vxlan_vni = 0;

        ig_md.ingress_mac_tstamp = 0;
        ig_md.ip_options_unsupported = 0;

        /* Compiler complains even if padding metadata isn't initialized */
        ig_intr_md.resubmit_flag = 0;
        ig_intr_md._pad1 = 0;
        ig_intr_md.packet_version = 0;
        ig_intr_md._pad2 = 0;
        ig_intr_md.ingress_port = 0;
        ig_intr_md.ingress_mac_tstamp = 0;


        tofino_parser.apply(pkt, ig_md, ig_intr_md);

        /* Copy Port Metadata. */
        ig_md.fabric_meta.logical_port_id = ig_md.port_md.logical_port_id;
        ig_md.ktep_port_meta.port_type = ig_md.port_md.port_type;
        ig_md.fabric_meta.port_disabled = ig_md.port_md.disabled;
        ig_md.ktep_meta.ingress_iface_id = ig_md.port_md.iface_id;

        transition select(ig_md.port_md.port_type) {
            PORT_TYPE_USER : parse_user_port;
            default : parse_fabric_port;
        }
    }

    state parse_fabric_port {
        ig_md.fabric_meta.passthrough = 1;
        /* To differentiate between ethernet packets, dp_ctrl packets and
         * pktgen packets we need to lookahead at the ethertype field which
         * starts from bit 96 (2 x 48 bits) and is encoded in 16 bits.
         */
        transition select(pkt.lookahead<bit<112>>()[15:0]) {
            ETHERTYPE_BF_PKTGEN : parse_pktgen_header;
            ETHERTYPE_DP_CTRL : parse_dp_ctrl;
            default : parse_ethernet;
        }
    }

    /* The first 48 bits in pktgen packet contain application-specific fields
     * where 3 bits starting from the 5th bit encode the application identifier.
     * In the following parser state we need to lookahead at app_id field.
     * If its value equals 0x2 then we know it's a port down pktgen packet.
     */
    state parse_pktgen_header {
        check_pktgen_t tmp = pkt.lookahead<check_pktgen_t>();
        transition select(tmp.app_id) {
            PKTGEN_APP_PORT_FAILOVER : parse_pktgen_port_down;
            default : accept;
        }
    }

    /* Pktgen port down packet uses the first 48 bits from the beginning of the
     * packet (which is the position of destination MAC address) to populate
     * the following fields :
     *       _pad0     :  3;
     *       pipe_id   :  2;
     *       app_id    :  3;
     *       _pad1     : 15;
     *       port_num  :  9;
     *       packet_id : 16;
     */
    state parse_pktgen_port_down {
        pkt.extract(hdr.pktgen_port_down);
        transition parse_pktgen_ext_header;
    }

    /* Pktgen extension header is used to fill the bits of the equivalent of
     * source MAC address with '0' so that the etherType is placed in the same
     * position as a regular ethernet packet.
     * Pktgen extension header fields are the following :
     *       pad : 48;
     *       etherType : 16;
     */
    state parse_pktgen_ext_header {
        pkt.extract(hdr.pktgen_ext_header);
        transition accept;
    }

    state parse_dp_ctrl {
        pkt.extract(hdr.dp_ctrl_hdr);
        transition parse_ethernet;
    }

    state parse_ethernet {
        pkt.extract(hdr.ethernet);
        transition select(hdr.ethernet.etherType) {
            ETHERTYPE_IPV6 : parse_ipv6;
            default : accept;
        }
    }

    state parse_ipv6 {
        pkt.extract(hdr.ipv6);
        ig_md.fabric_meta.routing_lkp_flag = 1;
        transition select(hdr.ipv6.nextHdr) {
            UDP_PROTO : parse_udp;
            default : accept;
        }
    }

    state parse_udp {
        pkt.extract(hdr.udp);
        transition select(hdr.udp.dstPort) {
            KNF_UDP_DST_PORT : parse_knf;
            default : accept;
        }
    }

    state parse_knf {
        pkt.extract(hdr.knf);
        ig_md.ktep_meta.ingress_pkt_type = PKT_TYPE_KNF;
        pkt.extract(hdr.inner_ethernet);
        ig_md.ktep_meta.src_mac = hdr.inner_ethernet.srcAddr;
        ig_md.ktep_meta.dst_mac = hdr.inner_ethernet.dstAddr;
        transition select(hdr.inner_ethernet.etherType) {
            ETHERTYPE_MPLS_UNICAST : parse_mpls;
            ETHERTYPE_MPLS_MULTICAST : parse_mpls;
            ETHERTYPE_IPV4 : parse_inner_ipv4;
            ETHERTYPE_IPV6 : parse_inner_ipv6;
            default : accept;
        }
    }

    state parse_user_port {
        ig_md.fabric_meta.passthrough = 0;
        transition parse_inner_ethernet;
    }

    state parse_inner_ethernet {
        pkt.extract(hdr.inner_ethernet);
        ig_md.ktep_meta.src_mac = hdr.inner_ethernet.srcAddr;
        ig_md.ktep_meta.dst_mac = hdr.inner_ethernet.dstAddr;
        transition select(hdr.inner_ethernet.etherType) {
            ETHERTYPE_VLAN : parse_vlan;
            // ETHERTYPE_QINQ : parse_qinq;
            ETHERTYPE_MPLS_UNICAST : parse_mpls;
            ETHERTYPE_MPLS_MULTICAST : parse_mpls;
            ETHERTYPE_IPV4 : parse_inner_ipv4;
            ETHERTYPE_IPV6 : parse_inner_ipv6;
            default : accept;
        }
    }

    state parse_mpls {
        pkt.extract(hdr.mpls);
        transition select(hdr.mpls.bos) {
            MPLS_BOS_1 : guess_mpls_payload; /* Last label in the stack. */
            default : reject;
        }
    }

    state guess_mpls_payload {
        transition select(pkt.lookahead<ip46_t>().version) {
            IPV4_VERSION : parse_inner_ipv4;
            IPV6_VERSION : parse_inner_ipv6;
            default : accept;
        }
    }

    // state parse_qinq {
    //     pkt.extract(hdr.qinq);
    //     ig_md.ktep_meta.ingress_pkt_type = PKT_TYPE_QINQ;
    //     transition select(hdr.qinq.etherType) {
    //         ETHERTYPE_VLAN    : parse_vlan;
    //         default           : accept;
    //     }
    // }

    state parse_vlan {
        pkt.extract(hdr.vlan);
        ig_md.ktep_meta.ingress_vlan_id = hdr.vlan.vlanID;
        ig_md.ktep_meta.ingress_pkt_type = PKT_TYPE_VLAN;
        transition select(hdr.vlan.etherType) {
            ETHERTYPE_MPLS_UNICAST : parse_mpls;
            ETHERTYPE_MPLS_MULTICAST : parse_mpls;
            ETHERTYPE_IPV4 : parse_inner_ipv4;
            ETHERTYPE_IPV6 : parse_inner_ipv6;
            default : accept;
        }
    }

    state parse_inner_ipv4 {
        pkt.extract(hdr.inner_ipv4);
        ipv4_checksum.add(hdr.inner_ipv4);
        /* TODO: ipv4_checksum.verify(); */
        transition select(hdr.inner_ipv4.ihl) {
            5 : parse_inner_ipv4_no_options;
            6 : parse_inner_ipv4_options;
            /* Currently dp only supports ipv4 packets with ihl 5 and 6.
             * The rest 7 to 15 are unsupported. To select 7 to 15, we do the following,
             * Select case does not support range expressions.
             * For example, if we use range, we get the error.
             * Compiler Bug: Invalid select case expression 7 .. 15;
             * 4w0x7 .. 4w0xf : parse_unsupported_ip_options;
             * Using the mask, 4w0x8 &&& 4w0x8 we can select 8 to 15.
             * The right value, 4w0x8 is used as a “mask”, where each bit set to 0 in the
             * mask indicates a “don't care” bit.
             * Currently we dont see a way to select 7 to 15 in one statement.
             * Hence, using two statements to get the expected behavior.
             */
            7 : parse_unsupported_ip_options;
            4w0x8 &&& 4w0x8 : parse_unsupported_ip_options;
            default : accept;
        }
    }

    state parse_inner_ipv4_options {
        pkt.extract(hdr.inner_ipv4_option);
        ipv4_checksum.add(hdr.inner_ipv4_option);
        transition parse_inner_ipv4_no_options;
    }

    state parse_inner_ipv4_no_options {
        transition select(hdr.inner_ipv4.protocol) {
            GRE_PROTO : parse_gre;
            UDP_PROTO : parse_inner_udp;
            TCP_PROTO : parse_inner_tcp;
            default : accept;
        }
    }

    state parse_unsupported_ip_options {
        ig_md.ip_options_unsupported = 1w1;
        transition accept;
    }

    state parse_inner_ipv6 {
        pkt.extract(hdr.inner_ipv6);
        transition select(hdr.inner_ipv6.nextHdr) {
            GRE_PROTO : parse_gre;
            UDP_PROTO : parse_inner_udp;
            TCP_PROTO : parse_inner_tcp;
            default : accept;
        }
    }

    state parse_gre {
        pkt.extract(hdr.gre);
        transition select(hdr.gre.keyPresent) {
            1 : parse_gre_key;
            0 : parse_gre_inner;
        }
    }

    state parse_gre_key {
        pkt.extract(hdr.gre_key);
        transition parse_gre_inner;
    }

    state parse_gre_inner {
        transition select(hdr.gre.protocolType) {
            ETHERTYPE_IPV4 : parse_vxlan_inner_ipv4;
            ETHERTYPE_IPV6 : parse_vxlan_inner_ipv6;
            default : reject;
        }
    }

    state parse_inner_tcp {
        pkt.extract(hdr.inner_tcp);
        transition accept;
    }

    state parse_inner_udp {
        pkt.extract(hdr.inner_udp);
        transition select(hdr.inner_udp.dstPort) {
            UDP_PORT_VXLAN : parse_vxlan;
            default : accept;
        }
    }

    state parse_vxlan {
        pkt.extract(hdr.vxlan);
        transition parse_vxlan_inner_ethernet;
    }

    state parse_vxlan_inner_ethernet {
        pkt.extract(hdr.vxlan_inner_ethernet);
        transition select(hdr.vxlan_inner_ethernet.etherType) {
            ETHERTYPE_IPV6 : parse_vxlan_inner_ipv6;
            ETHERTYPE_IPV4 : parse_vxlan_inner_ipv4;
            default : accept;
        }
    }

    state parse_vxlan_inner_ipv4 {
        pkt.extract(hdr.tunnel_inner_ipv4);
        tunnel_inner_ipv4_checksum.add(hdr.tunnel_inner_ipv4);
        /* TODO: tunnel_inner_ipv4_checksum.verify(); */
        transition accept;
    }

    state parse_vxlan_inner_ipv6 {
        pkt.extract(hdr.tunnel_inner_ipv6);
        transition accept;
    }
}

/* Ingress Deparser */
control SwitchIngressDeparser(
    packet_out pkt,
    inout ingress_header_t hdr,
    in ingress_metadata_t ig_md,
    in ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr) {

    Digest<local_mac_learning_digest_t>() local_mac_learn_digest;
    Digest<kvs_multicast_learning_digest_t>() kvs_multicast_learn_digest;
    Digest<vtep_v4_learning_digest_t>() vtep_learn_v4;
    Digest<vtep_v6_learning_digest_t>() vtep_learn_v6;

    apply {
        /* Unconditional learning.emit is not supported.
         * Therefore, we need to define and check the learning digest type.
         */
        if (ig_intr_md_for_dprsr.digest_type == DIGEST_TYPE_LOCAL_MAC_LEARNING) {
            local_mac_learn_digest.pack({ig_md.ktep_meta.ingress_iface_id,
                               ig_md.ktep_meta.ingress_vlan_id,
                               ig_md.ktep_meta.learn_nw_id,
                               hdr.inner_ethernet.srcAddr});
        }
        if (ig_intr_md_for_dprsr.digest_type == DIGEST_TYPE_KVS_MULTICAST_LEARNING) {
            kvs_multicast_learn_digest.pack({
                            ig_md.ktep_meta.ingress_port,
                            hdr.inner_ethernet.srcAddr,
                            hdr.inner_ipv6.srcAddr});
        }
        if (ig_intr_md_for_dprsr.digest_type == DIGEST_TYPE_REMOTE_VTEP_V4_MAC_LEARNING) {
            vtep_learn_v4.pack({
                            /* TODO: Barefoot need to fix the packing of the learn
                             * message so that VNI does not to be necessarily
                             * at the end to be read properly.
                             */
                            hdr.vxlan_inner_ethernet.srcAddr,
                            hdr.inner_ipv4.srcAddr,
                            ig_md.ktep_router_meta.router_id,
                            hdr.vxlan.vni});
        }
        if (ig_intr_md_for_dprsr.digest_type == DIGEST_TYPE_REMOTE_VTEP_V6_MAC_LEARNING) {
            vtep_learn_v6.pack({
                            hdr.vxlan_inner_ethernet.srcAddr,
                            hdr.inner_ipv6.srcAddr,
                            ig_md.ktep_router_meta.router_id,
                            hdr.vxlan.vni});
        }
        pkt.emit(hdr.bridged_md);
        pkt.emit(hdr.dp_ctrl_hdr);
        pkt.emit(hdr.pktgen_port_down);
        pkt.emit(hdr.pktgen_ext_header);
        pkt.emit(hdr.ethernet);
        pkt.emit(hdr.ipv6);
        pkt.emit(hdr.udp);
        pkt.emit(hdr.knf);
        pkt.emit(hdr.inner_ethernet);
        // pkt.emit(hdr.qinq);
        pkt.emit(hdr.mpls);
        pkt.emit(hdr.inner_ipv4);
        pkt.emit(hdr.inner_ipv4_option);
        pkt.emit(hdr.inner_ipv6);
        pkt.emit(hdr.gre);
        pkt.emit(hdr.gre_key);
        pkt.emit(hdr.inner_udp);
        pkt.emit(hdr.inner_tcp);
        pkt.emit(hdr.vxlan);
        pkt.emit(hdr.vxlan_inner_ethernet);
        pkt.emit(hdr.tunnel_inner_ipv4);
        pkt.emit(hdr.tunnel_inner_ipv6);
    }
}

/* Egress Parser */
parser SwitchEgressParser(
        packet_in pkt,
        out egress_header_t hdr,
        out egress_metadata_t eg_md,
        out egress_intrinsic_metadata_t eg_intr_md) {

    TofinoEgressParser() tofino_parser;

    state start {

        /* Initialize Metadata to Zero */
        eg_md = {
            ingress_port = 0,
            fabric_meta = {
                l2_egress_lkp_flag = 0,
                neigh_mac = 0,
                cpu_port = 0,
                flow_hash = 0
            },
            parser_metadata = {
                clone_src = 0
            },
            ktep_meta = {
                ingress_vlan_id = 0,
                egress_vlan_id = 0,
                payload_length = 0,
                egress_pkt_type = 0,
                process_l2 = 0,
                process_l3 = 0,
                dest_id = 0,
                received_on_punt_channel = 0,
                is_from_kvs = 0,
                pkt_src = 0,
                nw_id = 0,
                send_to_kvs = 0,
                ingress_iface_id = 0,
                egress_iface_id = 0,
                remote_lag_id = 0,
                pkt_length_offset = 0,
                knf_tunnel_terminated = 0,
                processing_user_pkt = 0
            },
            ktep_router_meta = {
                router_id = 0,
                output_iface = 0,
                src_mac = 0,
                dst_mac = 0,
                dst_mac_id = 0,
                process_l2_egress = 0,
                mpls_decap = 0,
                meter_color = MeterColor_t.GREEN
            },
            tunnel_meta = {
                egress_pkt_type = 0,
                process_egress = 0,
                tunnel_id = 0,
                remote_vtep_id = 0
            },
            mirror = {
                src = 0,
                session_id = 0,
                ingress_port = 0,
                egress_port = 0,
                queue_id = 0,
                queue_depth = 0,
                ingress_tstamp = 0,
                egress_tstamp = 0,
                sequence_num = 0
            },
            tel_metadata = {
                generate_postcard = 0,
                watchlist_hit = 0,
                seq_num = 0
            },
            ip_options_supported = 0
        };

        tofino_parser.apply(pkt, eg_intr_md);
        switch_pkt_src_t src = pkt.lookahead<switch_pkt_src_t>();
        eg_md.ip_options_supported = 1w0;
        transition select(src) {
            SWITCH_PKT_SRC_BRIDGE : parse_bridged_metadata;
            SWITCH_PKT_SRC_CLONE_EGRESS : parse_mirrored_packet;
            default : reject;
        }
    }

    state parse_mirrored_packet {
        pkt.extract(eg_md.mirror);
        eg_md.parser_metadata.clone_src = eg_md.mirror.src;
        transition accept;
    }

    state parse_bridged_metadata {
        pkt.extract(hdr.bridged_md);
        /* Copy all bridged metadata fields to eg_md fields */
        eg_md.ingress_port = hdr.bridged_md.ingress_port;
        eg_md.parser_metadata.clone_src = hdr.bridged_md.src;

        /* Fabric Metadata */
        eg_md.fabric_meta.l2_egress_lkp_flag = hdr.bridged_md.fabric_meta.l2_egress_lkp_flag;
        eg_md.fabric_meta.neigh_mac = hdr.bridged_md.fabric_meta.neigh_mac;
        eg_md.fabric_meta.flow_hash = hdr.bridged_md.fabric_meta.flow_hash;

        /* Ktep Metadata */
        eg_md.ktep_meta.ingress_vlan_id = hdr.bridged_md.ktep_meta.ingress_vlan_id;
        eg_md.ktep_meta.egress_vlan_id = hdr.bridged_md.ktep_meta.egress_vlan_id;
        eg_md.ktep_meta.egress_pkt_type = hdr.bridged_md.ktep_meta.egress_pkt_type;
        eg_md.ktep_meta.process_l2 = hdr.bridged_md.ktep_meta.process_l2;
        eg_md.ktep_meta.process_l3 = hdr.bridged_md.ktep_meta.process_l3;
        eg_md.ktep_meta.dest_id = hdr.bridged_md.ktep_meta.dest_id;
        eg_md.ktep_meta.received_on_punt_channel = hdr.bridged_md.ktep_meta.received_on_punt_channel;
        eg_md.ktep_meta.pkt_src = hdr.bridged_md.ktep_meta.pkt_src;
        eg_md.ktep_meta.nw_id = hdr.bridged_md.ktep_meta.nw_id;
        eg_md.ktep_meta.send_to_kvs = hdr.bridged_md.ktep_meta.send_to_kvs;
        eg_md.ktep_meta.is_from_kvs = hdr.bridged_md.ktep_meta.is_from_kvs;
        eg_md.ktep_meta.ingress_iface_id = hdr.bridged_md.ktep_meta.ingress_iface_id;
        eg_md.ktep_meta.egress_iface_id = hdr.bridged_md.ktep_meta.egress_iface_id;
        eg_md.ktep_meta.pkt_length_offset = hdr.bridged_md.ktep_meta.pkt_length_offset;
        eg_md.ktep_meta.knf_tunnel_terminated = hdr.bridged_md.ktep_meta.knf_tunnel_terminated;
        eg_md.ktep_meta.processing_user_pkt = hdr.bridged_md.ktep_meta.processing_user_pkt;

        /* Ktep Router Metadata */
        eg_md.ktep_router_meta.router_id = hdr.bridged_md.ktep_router_meta.router_id;
        eg_md.ktep_router_meta.output_iface = hdr.bridged_md.ktep_router_meta.output_iface;
        eg_md.ktep_router_meta.dst_mac_id = hdr.bridged_md.ktep_router_meta.dst_mac_id;
        eg_md.ktep_router_meta.process_l2_egress = hdr.bridged_md.ktep_router_meta.process_l2_egress;
        eg_md.ktep_router_meta.mpls_decap = hdr.bridged_md.ktep_router_meta.mpls_decap;

        /* Tunnel Metadata */
        eg_md.tunnel_meta.egress_pkt_type = hdr.bridged_md.tunnel_meta.egress_pkt_type;
        eg_md.tunnel_meta.process_egress = hdr.bridged_md.tunnel_meta.process_egress;
        eg_md.tunnel_meta.tunnel_id = hdr.bridged_md.tunnel_meta.tunnel_id;
        eg_md.tunnel_meta.remote_vtep_id = hdr.bridged_md.tunnel_meta.remote_vtep_id;


        /* INT Metadata */
        eg_md.tel_metadata.generate_postcard = hdr.bridged_md.tel_metadata.generate_postcard;
        eg_md.tel_metadata.watchlist_hit = hdr.bridged_md.tel_metadata.watchlist_hit;
        eg_md.tel_metadata.seq_num = hdr.bridged_md.tel_metadata.seq_num;
        // eg_md.tel_metadata.rule_id = hdr.bridged_md.tel_metadata.rule_id;

        transition select(eg_md.ktep_meta.processing_user_pkt) {
            0 : parse_fabric_port;
            1 : parse_user_port;
        }
    }

    state parse_fabric_port {
        transition parse_ethernet;
    }

    state parse_ethernet {
        pkt.extract(hdr.ethernet);
        transition select(hdr.ethernet.etherType) {
            ETHERTYPE_IPV6 : parse_ipv6;
            default : accept;
        }
    }

    state parse_ipv6 {
        pkt.extract(hdr.ipv6);
        transition select(hdr.ipv6.nextHdr) {
            UDP_PROTO : parse_udp;
            default : accept;
        }
    }

    state parse_udp {
        pkt.extract(hdr.udp);
        transition select(hdr.udp.dstPort) {
            KNF_UDP_DST_PORT : parse_knf_inner_ethernet;
            /* Never parse postcard header. */
            UDP_PORT_TEL_REPORT : parse_postcard_header;
            default : accept;
        }
    }

    state parse_postcard_header {
        pkt.extract(hdr.postcard_header);
        transition accept;
    }

    state parse_knf_inner_ethernet {
        pkt.extract(hdr.knf);
        pkt.extract(hdr.inner_ethernet);
        transition select(hdr.inner_ethernet.etherType) {
            // ETHERTYPE_VLAN : parse_vlan;
            ETHERTYPE_MPLS_UNICAST : parse_mpls;
            ETHERTYPE_MPLS_MULTICAST : parse_mpls;
            ETHERTYPE_IPV4 : parse_inner_ipv4;
            ETHERTYPE_IPV6 : parse_inner_ipv6;
            default : accept;
        }
    }

    state parse_user_port {
        transition parse_inner_ethernet;
    }

    state parse_inner_ethernet {
        pkt.extract(hdr.inner_ethernet);
        transition select(hdr.inner_ethernet.etherType) {
            // ETHERTYPE_QINQ : parse_qinq;
            ETHERTYPE_MPLS_UNICAST : parse_mpls;
            ETHERTYPE_MPLS_MULTICAST : parse_mpls;
            ETHERTYPE_IPV4 : parse_inner_ipv4;
            ETHERTYPE_IPV6 : parse_inner_ipv6;
            default : accept;
        }
    }

    state parse_mpls {
        pkt.extract(hdr.mpls);
        transition select(hdr.mpls.bos) {
            MPLS_BOS_1 : guess_mpls_payload; /* Last label in the stack. */
            default : reject;
        }
    }

    state guess_mpls_payload {
        transition select(pkt.lookahead<ip46_t>().version) {
            IPV6_VERSION : parse_inner_ipv6; // Workaround for Intel case 00644749. Line moved up
            IPV4_VERSION : parse_inner_ipv4;
            default : accept;
        }
    }

    // state parse_qinq {
    //     pkt.extract(hdr.qinq);
    //     transition select(hdr.qinq.etherType) {
    //         ETHERTYPE_VLAN    : parse_vlan;
    //         default           : accept;
    //     }
    // }

    state parse_vlan {
        pkt.extract(hdr.vlan);
        transition select(hdr.vlan.etherType) {
            ETHERTYPE_MPLS_UNICAST : parse_mpls;
            ETHERTYPE_MPLS_MULTICAST : parse_mpls;
            ETHERTYPE_IPV4 : parse_inner_ipv4;
            ETHERTYPE_IPV6 : parse_inner_ipv6;
            default : accept;
        }
    }

    state parse_inner_ipv4 {
        pkt.extract(hdr.inner_ipv4);
        transition select(hdr.inner_ipv4.ihl) {
            5 : parse_inner_ipv4_no_options;
            6 : parse_inner_ipv4_options;
            default : accept;
        }
    }

    state parse_inner_ipv4_no_options {
        eg_md.ip_options_supported = 1w1;
        transition accept;
    }

    state parse_inner_ipv4_options {
        eg_md.ip_options_supported = 1w1;
        pkt.extract(hdr.inner_ipv4_option);
        transition accept;
    }

    state parse_inner_ipv6 {
        pkt.extract(hdr.inner_ipv6);
        transition accept;
    }

}

/* Egress Deparser */
control SwitchEgressDeparser(
        packet_out pkt,
        inout egress_header_t hdr,
        in egress_metadata_t eg_md,
        in egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr) {

    EgressMirror() egress_mirror;
    Checksum() ipv4_checksum;
    Checksum() tunnel_inner_ipv4_checksum;

    apply {
        egress_mirror.apply(eg_md, eg_intr_md_for_dprsr);

        /* TODO recalculate tunnel_inner_ipv4 checksum once barefoot comes with a
         * solution to https://support.barefootnetworks.com/hc/en-us/requests/11226
         * if (hdr.tunnel_inner_ipv4.isValid()) {
         *     hdr.tunnel_inner_ipv4.hdrChecksum = tunnel_inner_ipv4_checksum.update({
         *         hdr.tunnel_inner_ipv4.version,
         *         hdr.tunnel_inner_ipv4.ihl,
         *         hdr.tunnel_inner_ipv4.diffserv,
         *         hdr.tunnel_inner_ipv4.totalLen,
         *         hdr.tunnel_inner_ipv4.identification,
         *         hdr.tunnel_inner_ipv4.flags,
         *         hdr.tunnel_inner_ipv4.fragOffset,
         *         hdr.tunnel_inner_ipv4.ttl,
         *         hdr.tunnel_inner_ipv4.protocol,
         *         hdr.tunnel_inner_ipv4.srcAddr,
         *         hdr.tunnel_inner_ipv4.dstAddr,
         *         hdr.inner_ipv4_option.type,
         *         hdr.inner_ipv4_option.len,
         *         hdr.inner_ipv4_option.value});
         * } else if (hdr.inner_ipv4.isValid()) {
         *     hdr.inner_ipv4.hdrChecksum = ipv4_checksum.update({
         *         hdr.inner_ipv4.version,
         *         hdr.inner_ipv4.ihl,
         *         hdr.inner_ipv4.diffserv,
         *         hdr.inner_ipv4.totalLen,
         *         hdr.inner_ipv4.identification,
         *         hdr.inner_ipv4.flags,
         *         hdr.inner_ipv4.fragOffset,
         *         hdr.inner_ipv4.ttl,
         *         hdr.inner_ipv4.protocol,
         *         hdr.inner_ipv4.srcAddr,
         *         hdr.inner_ipv4.dstAddr,
         *         hdr.inner_ipv4_option.type,
         *         hdr.inner_ipv4_option.len,
         *         hdr.inner_ipv4_option.value});
         * }
         */

        /* Update IPv4 Checksum
         * As per barefoot if ipv4_option are invalid, then their values are
         * guaranteed to be 0, so that including them won’t change the checksum value.
         * Considering that, the below is an unconditional checksum which helps to fit the ip options for now.
         * https://support.barefootnetworks.com/hc/en-us/requests/11226
         */
        if(eg_md.ip_options_supported == 1w1) {
            hdr.inner_ipv4.hdrChecksum = ipv4_checksum.update({
                hdr.inner_ipv4.version,
                hdr.inner_ipv4.ihl,
                hdr.inner_ipv4.diffserv,
                hdr.inner_ipv4.totalLen,
                hdr.inner_ipv4.identification,
                hdr.inner_ipv4.flags,
                hdr.inner_ipv4.fragOffset,
                hdr.inner_ipv4.ttl,
                hdr.inner_ipv4.protocol,
                hdr.inner_ipv4.srcAddr,
                hdr.inner_ipv4.dstAddr,
                hdr.inner_ipv4_option.type,
                hdr.inner_ipv4_option.len,
                hdr.inner_ipv4_option.value});
        }

        /* Update VxLAN inner IPv4 Checksum */
        if (hdr.encap_ipv4.isValid()) {
            hdr.encap_ipv4.hdrChecksum = tunnel_inner_ipv4_checksum.update({
                hdr.encap_ipv4.version,
                hdr.encap_ipv4.ihl,
                hdr.encap_ipv4.diffserv,
                hdr.encap_ipv4.totalLen,
                hdr.encap_ipv4.identification,
                hdr.encap_ipv4.flags,
                hdr.encap_ipv4.fragOffset,
                hdr.encap_ipv4.ttl,
                hdr.encap_ipv4.protocol,
                hdr.encap_ipv4.srcAddr,
                hdr.encap_ipv4.dstAddr});
        }

        pkt.emit(hdr.dp_ctrl_hdr);
        pkt.emit(hdr.ethernet);
        pkt.emit(hdr.ipv6);
        pkt.emit(hdr.udp);
        pkt.emit(hdr.knf);
        pkt.emit(hdr.encap_ethernet);
        pkt.emit(hdr.encap_vlan);
        pkt.emit(hdr.encap_ipv4);
        pkt.emit(hdr.encap_ipv6);
        pkt.emit(hdr.encap_gre);
        pkt.emit(hdr.encap_gre_key);
        pkt.emit(hdr.encap_udp);
        pkt.emit(hdr.encap_vxlan);
        pkt.emit(hdr.postcard_header);
        pkt.emit(hdr.inner_ethernet);
        // pkt.emit(hdr.qinq);
        pkt.emit(hdr.vlan);
        pkt.emit(hdr.mpls);
        pkt.emit(hdr.inner_ipv4);
        pkt.emit(hdr.inner_ipv4_option);
        pkt.emit(hdr.inner_ipv6);
    }
}
# 23 "leaf.p4" 2
# 1 "leaf_profile.p4" 1
/****************************************************************
 * Copyright (c) Kaloom, 2019
 *
 * This unpublished material is property of Kaloom Inc.
 * All rights reserved.
 * Reproduction or distribution, in whole or in part, is
 * forbidden except by express written permission of Kaloom Inc.
 ****************************************************************/




# 1 "hw_defs.h" 1
/****************************************************************
 * Copyright (c) Kaloom, 2018
 *
 * This unpublished material is property of Kaloom Inc.
 * All rights reserved.
 * Reproduction or distribution, in whole or in part, is
 * forbidden except by express written permission of Kaloom Inc.
 ****************************************************************/






/* KTEP_HW_L2_TABLE_SIZE is the size of vnet_dmac table */





/* 128 kvteps x 128 remote_vteps */




/* max of 8 bit - vrouter_iface_id_t in P4 */





/* ID of the destination IP address of HOSTDEV */






/* Max LAG group size */


/* GRE Parameters */




/* Port ID used in DP control header when sending and receiving packets to
 * and from the dp0 interface.
 */
# 14 "leaf_profile.p4" 2


const bit<32> L2_INGRESS_TABLE_SIZE = 1024;
const bit<32> PORT_FAILOVER_TABLE_SIZE = 32768;
const bit<32> ROUTING_IPV6_TABLE_SIZE = 2048;
const bit<32> ECMP_GROUPS_TABLE_SIZE = 1024;
const bit<32> ECMP_SELECTION_TABLE_SIZE = 16384;
const bit<32> ECMP_SELECTION_MAX_GROUP_SIZE = 128;
const bit<32> NH_TABLE_SIZE = 512;
const bit<32> L2_EGRESS_TABLE_SIZE = 512;
const bit<32> COPP_METER_SIZE = 256;
const bit<32> COPP_DROP_COUNTERS_SIZE = COPP_METER_SIZE;
const bit<32> COPP_FLOW_TABLE_SIZE = 3;

/* L2 service tables */
const bit<32> VLAN_TO_VNET_MAPPING_TABLE_SIZE = 10240;
const bit<32> L1TP_DROP_STATS_TABLE_SIZE = 512;
const bit<32> VNET_EGRESS_TABLE_SIZE = VLAN_TO_VNET_MAPPING_TABLE_SIZE;
const bit<32> VNET_SMAC_IFACE_TABLE_SIZE = 30720;
const bit<32> VNET_DMAC_TABLE_SIZE = 36864;
const bit<32> EGRESS_PORTS_TABLE_SIZE = 260;
const bit<32> LAG_GROUPS_TABLE_SIZE = 260;
const bit<32> LAG_SELECTION_TABLE_SIZE = 1024;
const bit<32> LAG_SELECTION_MAX_GROUP_SIZE = 4;
const bit<32> KVS_REWRITE_TABLE_SIZE = 128;
const bit<32> REMOTE_LAGS_TABLE_SIZE = 64;
const bit<32> LAG_TO_VLAN_MAPPING_TABLE_SIZE = 8192;
const bit<32> LAG_STATE_TABLE_SIZE = 512;
const bit<32> RID_TABLE_SIZE = 20000;
const bit<32> KNID_TO_MC_GRP_MAPPING_TABLE_SIZE = 11264;
const bit<32> KNF_LEARN_FLAG_TABLE_SIZE = 5;
const bit<32> USER_PUNT_TABLE_SIZE = 128;
const bit<32> KNF_DST_IP_IS_LOCAL_TABLE_SIZE = 128;
const bit<32> KNF_REWRITE_TABLE_SIZE = 128;
const bit<32> LAG_FAILOVER_TABLE_SIZE = 512;

/* L3 service tables */
const bit<32> VROUTER_L3_EXACT_TABLE_SIZE = 23552;
const bit<32> VROUTER_L3_TABLE_SIZE = 14336;
const bit<32> VROUTER_NEIGH_TABLE_SIZE = 8192;
const bit<32> VROUTER_IFACES_TABLE_SIZE = 3072;
const bit<32> PUNT_TUNNEL_STATS_TABLE_SIZE = VROUTER_IFACES_TABLE_SIZE;
const bit<32> VROUTER_LFIB_TABLE_SIZE = 16384;
const bit<32> VROUTER_TABLE_SIZE = 128;

/* L3 service VxLAN tables */
const bit<32> KVTEP_ONETS_TABLE_SIZE = 8192;
const bit<32> KVTEP_ONET_SMAC_TABLE_SIZE = 4096;
const bit<32> KVTEP_REMOTE_VTEPS_TABLE_SIZE = 2048;

/* L3 service GRE tables */
const bit<32> VROUTER_GRE_TUNNEL_TABLE_SIZE = 128;
const bit<32> VROUTER_GRE_ENCAP_TABLE_SIZE = 128;

/* INT */
const bit<32> TEL_FLOW_WATCHLIST_TABLE_SIZE = 1024;

/* Port failover */
const bit<32> port_failover_register_instance_count = 131072;
const bit<32> lag_failover_reg_instance_count = 131072;

/* ACL */
const bit<32> VROUTER_ACL_RULES_TABLE_SIZE = 512;
# 24 "leaf.p4" 2
# 1 "core/modules/port.p4" 1
/****************************************************************
 * Copyright (c) Kaloom, 2019
 *
 * This unpublished material is property of Kaloom Inc.
 * All rights reserved.
 * Reproduction or distribution, in whole or in part, is
 * forbidden except by express written permission of Kaloom Inc.
 ****************************************************************/




# 1 "/mnt/p4-tests/p4_16/customer/kaloom/leaf/core/types.p4" 1
/****************************************************************
 * Copyright (c) Kaloom, 2019
 *
 * This unpublished material is property of Kaloom Inc.
 * All rights reserved.
 * Reproduction or distribution, in whole or in part, is
 * forbidden except by express written permission of Kaloom Inc.
 ****************************************************************/
# 14 "core/modules/port.p4" 2

control L1tpDropStats(
        in ingress_intrinsic_metadata_t ig_intr_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_tm_md,
        inout ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md)(
        bit<32> vnet_drop_table_size) {

    DirectCounter<bit<64>>(CounterType_t.PACKETS_AND_BYTES) rx_drop_cntr;
    // external_counter_t tx_drop_cntr;

    action rx_drop_hit() {
        rx_drop_cntr.count();
    }

    /* Reports packets and bytes counters for packets that were received on a
     * given ingress interface and were marked to be dropped.
     */
    table rx_drop {
        key = {
            ig_intr_md.ingress_port : exact;
        }
        actions = {
            rx_drop_hit;
        }
        size = vnet_drop_table_size;
        counters = rx_drop_cntr;
    }

    // action tx_drop_hit() {
    //     tx_drop_cntr.count();
    // }

    /* Reports packets and bytes counters for packets that were meant to be sent
     * to a given egress interface but were marked to be dropped.
     */
    // table tx_drop {
    //     key = {
    //         ig_tm_md.ucast_egress_port : exact;
    //     }
    //     actions = {
    //         tx_drop_hit;
    //     }
    //     size = vnet_drop_table_size;
    //     counters = tx_drop_cntr;
    // }

    apply {
        if (ig_dprsr_md.drop_ctl == DROP_CTL_ALL) {
            rx_drop.apply();
            /* TODO: Due to compiler issue we had to disable tx_drop table.
             * See KSDF-7589 and analyse the valid scenarios where l1tp
             * tx drop stats should be detected. Identifying these cases will
             * help placing tx_drop table.
             */
            // tx_drop.apply();
        }
    }
}
# 25 "leaf.p4" 2
# 1 "core/modules/l2.p4" 1
/****************************************************************
 * Copyright (c) Kaloom, 2019
 *
 * This unpublished material is property of Kaloom Inc.
 * All rights reserved.
 * Reproduction or distribution, in whole or in part, is
 * forbidden except by express written permission of Kaloom Inc.
 ****************************************************************/




# 1 "/mnt/p4-tests/p4_16/customer/kaloom/leaf/core/types.p4" 1
/****************************************************************
 * Copyright (c) Kaloom, 2019
 *
 * This unpublished material is property of Kaloom Inc.
 * All rights reserved.
 * Reproduction or distribution, in whole or in part, is
 * forbidden except by express written permission of Kaloom Inc.
 ****************************************************************/
# 14 "core/modules/l2.p4" 2





const bit<9> LAG_MSB = 0x180;

/* Generate ECMP hash value that will be used to set UDP source port in
 * encapsulated KNF packets.
 */
control FlowHash(
        inout ingress_header_t hdr,
        inout ingress_metadata_t ig_md)() {


    Hash<bit<16>>(HashAlgorithm_t.CRC16) flow_hash_ipv4;
    Hash<bit<16>>(HashAlgorithm_t.CRC16) flow_hash_ipv6;





    /* FIXME: Could produce strange results when headers are not valid if
     * they are overlayed with other headers.
     */

    /* Hashing for IPv4 packet.
     * This hash is used for ECMP later in the underlay routing.
     */
    action compute_ipv4_hash() {
        ig_md.fabric_meta.flow_hash = flow_hash_ipv4.get({
                ig_md.ktep_meta.ingress_iface_id,
                ig_md.ktep_meta.nw_id,
                // hdr.inner_ethernet.srcAddr,
                // hdr.inner_ethernet.dstAddr,
                hdr.inner_udp.srcPort,
                hdr.inner_udp.dstPort,
                hdr.inner_tcp.srcPort,
                hdr.inner_tcp.dstPort,
                hdr.inner_ipv4.srcAddr,
                hdr.inner_ipv4.dstAddr,
                hdr.inner_ipv4.protocol});
    }

    /* Hashing for IPv6 packet.
     * This hash is used for ECMP later in the underlay routing.
     */
    action compute_ipv6_hash() {
        ig_md.fabric_meta.flow_hash = flow_hash_ipv6.get({
                ig_md.ktep_meta.ingress_iface_id,
                ig_md.ktep_meta.nw_id,
                // hdr.inner_ethernet.srcAddr,
                // hdr.inner_ethernet.dstAddr,
                hdr.inner_udp.srcPort,
                hdr.inner_udp.dstPort,
                hdr.inner_tcp.srcPort,
                hdr.inner_tcp.dstPort,
                hdr.inner_ipv6.srcAddr,
                hdr.inner_ipv6.dstAddr,
                hdr.inner_ipv6.nextHdr});
    }

    apply {
        if (hdr.inner_ipv4.isValid()) {
            compute_ipv4_hash();
        } else if (hdr.inner_ipv6.isValid()) {
            compute_ipv6_hash();
        }
    }
}

control LagMapping(
        inout ingress_header_t hdr,
        inout ingress_metadata_t ig_md)
        (bit<32> lag_to_vlan_mapping_table_size) {

    action lag_to_vlan_mapping_vlan_hit(vlan_id_t vlan_id) {
        ig_md.ktep_meta.egress_vlan_id = vlan_id;
        ig_md.ktep_meta.egress_pkt_type = PKT_TYPE_VLAN;
        ig_md.fabric_meta.routing_lkp_flag = 0; /* Skip underlay routing */
        ig_md.ktep_meta.l2_lkp_flag = 1; /* Perform lag_groups table lookup */
    }

    action lag_to_vlan_mapping_untagged_hit() {
        ig_md.ktep_meta.egress_pkt_type = PKT_TYPE_UNTAGGED;
        ig_md.fabric_meta.routing_lkp_flag = 0; /* Skip underlay routing */
        ig_md.ktep_meta.l2_lkp_flag = 1; /* Perform lag_groups table lookup */
    }

    action lag_to_vlan_mapping_miss() {}

    /* When a KNF packet reaches this table it already has its egress iface/lag
     * ID resolved. It either came with MLAG IP which is mapped to a local lag
     * id in knf_dst_ip_is_local, or it arrived on the ICL which means it had
     * the lag ID (egress_iface_id) in the packet.
     * Since we also have the KNID (nw_id) we don't need to perform a MAC
     * lookup in the vnet_dmac table. We simply set the egress packet type and
     * vlan ID for further l2 processing. Then the packet goes to the lag_groups
     * table and bypasses all the tables in between.
     */
    table lag_to_vlan_mapping {
        key = {
            ig_md.ktep_meta.egress_iface_id : exact;
            ig_md.ktep_meta.nw_id : exact;
        }
        actions = {
            lag_to_vlan_mapping_untagged_hit;
            lag_to_vlan_mapping_vlan_hit;
            lag_to_vlan_mapping_miss;
        }
        default_action = lag_to_vlan_mapping_miss();
        size = lag_to_vlan_mapping_table_size;
    }

    apply {
        lag_to_vlan_mapping.apply();
    }
}

control KnfPackets(
        inout ingress_header_t hdr,
        inout ingress_metadata_t ig_md,
        in ingress_intrinsic_metadata_t ig_intr_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm)
        (bit<32> knids_table_size,
        bit<32> knf_dst_ip_is_local_table_size,
        bit<32> lag_mapping_table_size) {

    LagMapping(lag_mapping_table_size) lag_mapping;

    DirectCounter<bit<64>>(CounterType_t.PACKETS_AND_BYTES) set_nw_id_cntr;
    DirectCounter<bit<32>>(CounterType_t.PACKETS) knf_dst_ip_is_local_cntr;

    action set_remote_lag_id() {
        ig_md.ktep_meta.egress_iface_id = (bit<9>)hdr.knf.remoteLagID;
        ig_md.ktep_meta.is_icl = 1;
    }

    action set_nw_id_(nw_id_t nw_id) {
        set_nw_id_cntr.count();
        ig_md.ktep_meta.nw_id = nw_id;
        ig_md.ktep_meta.learn_nw_id = nw_id;
    }

    action set_punt_nw_id(nw_id_t nw_id) {
        set_nw_id_cntr.count();
        ig_md.ktep_meta.nw_id = nw_id;
        ig_md.ktep_meta.received_on_punt_channel = 1;
    }

    action set_nw_id_miss() {
        set_nw_id_cntr.count();
    }

    table set_nw_id {
        key = {
            hdr.knf.knid : exact;
        }
        actions = {
            set_nw_id_;
            set_punt_nw_id;
            set_nw_id_miss;
        }
        const default_action = set_nw_id_miss;
        size = knids_table_size;
        counters = set_nw_id_cntr;
    }

    /* Remove outer headers */
    action knf_decap() {
        hdr.ethernet.setInvalid();
        hdr.ipv6.setInvalid();
        hdr.udp.setInvalid();
        hdr.knf.setInvalid();

        ig_md.ktep_meta.pkt_length_offset = ig_md.ktep_meta.pkt_length_offset + ETH_SIZE + IPV6_SIZE + UDP_SIZE + KNF_SIZE;
        ig_md.ktep_meta.knf_tunnel_terminated = 1;
        ig_md.ktep_meta.processing_user_pkt = 1;
    }

    /* When the destination IP matches the local hostdev IP, the packet goes
     * through overlay L2 processing.
     */
    action knf_dst_ip_is_local_hit() {
        knf_dst_ip_is_local_cntr.count();
        ig_md.ktep_meta.process_l2 = 1;
        ig_md.ktep_meta.pkt_src = KTEP_SRC_LEAF;
        /* Set passthrough flag to 0 so that if the packet needs to be sent to
         * the host, it will use the dp0 interface and go through egress
         * processing (set KNID, outer MACs, outer IPs, etc).
         */
        ig_md.fabric_meta.passthrough = 0;
        knf_decap();
    }

    /* The destination IP matches the link-local IP of an interface connected to
     * a KVS.
     */
    action knf_dst_ip_is_from_kvs_hit(iface_id_t lag_id) {
        knf_dst_ip_is_local_cntr.count();
        ig_md.ktep_meta.process_l2 = 1;
        ig_md.ktep_meta.learn = 1;
        ig_md.ktep_meta.is_from_kvs = 1;
        ig_md.ktep_meta.ingress_iface_id = lag_id;
        ig_md.ktep_meta.pkt_src = KTEP_SRC_KVS;
        /* Set passthrough flag to 0 so that if the packet needs to be sent to
         * the host, it will use the dp0 interface and go through egress
         * processing (set KNID, outer MACs, outer IPs, etc).
         */
        ig_md.fabric_meta.passthrough = 0;
        knf_decap();
    }

    /* When the destination IP matches a LAG IP that is known to this leaf, we
     * set the corresponding LAG ID as the egress_iface_id which means we can
     * skip vnet_dmac table.
     * The packet will then go to lag_to_vlan_mapping table to identify the
     * egress VLAN ID.
     */
    action knf_dst_ip_is_lag_hit(iface_id_t lag_id) {
        knf_dst_ip_is_local_cntr.count();
        ig_md.ktep_meta.egress_iface_id = lag_id;
        ig_md.ktep_meta.pkt_src = KTEP_SRC_LEAF;
        ig_md.ktep_meta.process_l2 = 0; /* Skip vnet_dmac table lookup */
        ig_md.ktep_meta.l2_lkp_flag = 1; /* Perform lag_groups table lookup */
        knf_decap();
    }

    action knf_dst_ip_is_local_vrouter_hit(vrouter_id_t router_id) {
        knf_dst_ip_is_local_cntr.count();
        ig_md.ktep_router_meta.router_id = router_id;
        ig_md.ktep_meta.process_l2 = 1;
        ig_md.ktep_meta.process_l3 = 1;
        ig_md.ktep_meta.pkt_src = KTEP_SRC_LEAF;
        /* Set passthrough flag to 0 so that if the packet needs to be sent to
         * the host, it will use the dp0 interface and go through egress
         * processing (set KNID, outer MACs, outer IPs, etc).
         */
        ig_md.fabric_meta.passthrough = 0;
        knf_decap();
    }

    /* The destination IP does not match the local hostdev IP. By not setting
     * ktep_meta.process_l2 and ktep_meta.learn to 1, the packet will be treated
     * as an underlay packet.
     */
    action knf_dst_ip_is_local_miss() {
        /* For some reason, the kvs flags sometimes gets garbage values so we set
         * it to zero explicitly here.
         */
        ig_md.ktep_meta.send_to_kvs = 0;
        ig_md.ktep_meta.is_from_kvs = 0;
        knf_dst_ip_is_local_cntr.count();
    }

    /* knf_dst_ip_is_local is used to verify if a KNF packet is destined to this
     * leaf. If not, the packet is a "transitory" KNF packet and it is treated
     * as an underlay packet. If the packet is destined to the leaf's hostdev
     * or the fd06 IP of a KVS, the ingress port does not matter. However, if
     * the packet is coming from a KVS, the destination IP is the link-local
     * address of the ingress port.
     */
    table knf_dst_ip_is_local {
        key = {
            ig_intr_md.ingress_port : ternary;
            hdr.ipv6.dstAddr : exact;
        }
        actions = {
            knf_dst_ip_is_local_hit;
            knf_dst_ip_is_lag_hit;
            knf_dst_ip_is_from_kvs_hit;
            knf_dst_ip_is_local_vrouter_hit;
            knf_dst_ip_is_local_miss;
        }
        const default_action = knf_dst_ip_is_local_miss();
        size = knf_dst_ip_is_local_table_size;
        counters = knf_dst_ip_is_local_cntr;
    }

    apply {
        if (ig_md.ktep_meta.ingress_pkt_type == PKT_TYPE_KNF) {
            /* MLAG-ICL packets */
            if (hdr.knf.remoteLagID != 0) {
                set_remote_lag_id();
            }
            set_nw_id.apply();
            switch(knf_dst_ip_is_local.apply().action_run) {
                knf_dst_ip_is_local_hit:
                knf_dst_ip_is_lag_hit: {
                    lag_mapping.apply(hdr, ig_md);
                }
            }
        }
    }
}

control PuntUserPackets(
        inout ingress_header_t hdr,
        inout ingress_metadata_t ig_md,
        in ingress_intrinsic_metadata_t ig_intr_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm,
        inout ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md)
        (bit<32> user_punt_table_size) {

    Meter<logical_port_id_t>(COPP_METER_SIZE, MeterType_t.BYTES) user_punt_meter;

    action user_punt_hit(port_id_t cpu_port) {
        ig_md.fabric_meta.copp_packet_color = (MeterColor_t)user_punt_meter.execute(ig_md.fabric_meta.logical_port_id);
        hdr.dp_ctrl_hdr.setValid();
        hdr.dp_ctrl_hdr.ring_id = RING_ID_USER_PUNT;
        hdr.dp_ctrl_hdr.etherType = ETHERTYPE_DP_CTRL;
        hdr.dp_ctrl_hdr.port = (bit<16>)ig_intr_md.ingress_port;
        ig_intr_md_for_tm.ucast_egress_port = cpu_port;
        ig_intr_md_for_tm.bypass_egress = 1;
    }

    action user_punt_block_hit() {
        ig_dprsr_md.drop_ctl = DROP_CTL_ALL;
        exit;
    }

    action user_punt_miss() {}

    /* Based on the destination MAC, user_punt table sends user packet to the
     * host CPU. This is needed for LLDP and LACP packets received on a user port.
     */
    table user_punt {
        key = {
            hdr.inner_ethernet.dstAddr : ternary;
            ig_md.fabric_meta.port_disabled : ternary;
        }
        actions = {
            user_punt_hit;
            user_punt_block_hit;
            user_punt_miss;
        }
        const default_action = user_punt_miss();
        size = user_punt_table_size;
    }

    apply {
        user_punt.apply();
    }
}

control LagStateCheck(
        in ingress_metadata_t ig_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm,
        inout ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md)
        (bit<32> lag_state_table_size) {

    DirectCounter<bit<32>>(CounterType_t.PACKETS) lag_state_cntr;

    action lag_state_up() {
        lag_state_cntr.count();
    }

    action lag_state_down() {
        lag_state_cntr.count();
        ig_dprsr_md.drop_ctl = DROP_CTL_ALL;
        /* TODO: Remove exit() primitive action so that the packet will be
         * captured by the drop_stats (l1tp rx and tx drops) table at the end
         * of ingress pipeline.
         */
        exit;
    }

    /* This table filters user traffic arriving on a local LAG while the
     * Lag state is down. All user traffic should be dropped with the exception
     * of LACP traffic which is punted to the host. That's why it is important
     * to apply this table after user_punt block.
     */
    table lag_state {
        key = {
            ig_md.ktep_meta.ingress_iface_id : exact;
        }
        actions = {
            lag_state_down;
            lag_state_up;
        }
        const default_action = lag_state_up;
        size = lag_state_table_size;
        counters = lag_state_cntr;
    }

    apply {
        if (ig_intr_md_for_tm.ucast_egress_port != ig_md.fabric_meta.cpu_port) {
            lag_state.apply();
        }
    }
}

control VnetMapping(
        inout ingress_header_t hdr,
        inout ingress_metadata_t ig_md,
        inout ig_ktep_metadata_t ktep_meta,
        inout digest_type_t digest_type,
        in ingress_intrinsic_metadata_t ig_intr_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm,
        inout ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md)
        (bit<32> vnet_mapping_table_size) {

    Meter<logical_port_id_t>(COPP_METER_SIZE, MeterType_t.BYTES) kvs_meter;
    DirectCounter<bit<64>>(CounterType_t.PACKETS_AND_BYTES) vlan_to_vnet_mapping_cntr;

    /* Get the L2 network ID of the pair {port ID, VLAN ID} and set the ktep
     * metadata so that the packet goes through overlay processing (learning and
     * forwarding).
     */
    action vlan_to_vnet_mapping_hit(nw_id_t nw_id) {
        ig_md.ktep_meta.nw_id = nw_id;
        ig_md.ktep_meta.learn_nw_id = nw_id;
        ig_md.ktep_meta.learn = 1;
        ig_md.ktep_meta.process_l2 = 1;
        ig_md.ktep_meta.src_mac = hdr.inner_ethernet.srcAddr;
        ig_md.ktep_meta.dst_mac = hdr.inner_ethernet.dstAddr;
        vlan_to_vnet_mapping_cntr.count();
    }

    /* {port ID, VLAN ID} not registered to a KNID */
    action vlan_to_vnet_mapping_miss() {
        vlan_to_vnet_mapping_cntr.count();
    }

    /* vlan_to_vnet_mapping table is used to map a {port ID, VLAN ID} pair to a
     * network ID. For user untagged packets : VLAN ID == 0.
     */
    @pragma ways 6
    table vlan_to_vnet_mapping {
        key = {
            ktep_meta.ingress_iface_id : exact;
            /* ktep_meta.ingress_vlan_id metadata is set by the parser */
            ktep_meta.ingress_vlan_id : exact;
        }
        actions = {
            vlan_to_vnet_mapping_hit;
            vlan_to_vnet_mapping_miss;
        }
        const default_action = vlan_to_vnet_mapping_miss;
        size = vnet_mapping_table_size;
        counters = vlan_to_vnet_mapping_cntr;
    }

    /* The IP matches the KVS multicast address so the packet must be sent up
     * to the host CPU.
     */
    action kvs_multicast_hit(port_id_t cpu_port) {
        ig_md.fabric_meta.copp_packet_color = (MeterColor_t)kvs_meter.execute(ig_md.fabric_meta.logical_port_id);
        digest_type = DIGEST_TYPE_KVS_MULTICAST_LEARNING;
        /* Send to Host CPU */
        hdr.dp_ctrl_hdr.setValid();
        hdr.dp_ctrl_hdr.ring_id = RING_ID_KVS_MULTICAST;
        hdr.dp_ctrl_hdr.etherType = ETHERTYPE_DP_CTRL;
        hdr.dp_ctrl_hdr.port = (bit<16>)ig_intr_md.ingress_port;
        ig_intr_md_for_tm.ucast_egress_port = cpu_port;
        ig_intr_md_for_tm.bypass_egress = 1;
    }

    /* Packets that do not match the KVS multicast address are dropped. */
    action kvs_multicast_miss() {
        ig_dprsr_md.drop_ctl = DROP_CTL_ALL;
    }

    /* Check if the packet destination IP is the multicast address used by KVS */
    table kvs_multicast {
        key = {
            hdr.inner_ipv6.dstAddr : exact;
        }
        actions = {
            kvs_multicast_hit;
            kvs_multicast_miss;
        }
        const default_action = kvs_multicast_miss;
        size = 2;
    }

    action remove_vlan_header() {
        hdr.inner_ethernet.etherType = hdr.vlan.etherType;
        hdr.vlan.setInvalid();
        ig_md.ktep_meta.pkt_length_offset = ig_md.ktep_meta.pkt_length_offset + VLAN_SIZE;
    }

    apply {
        if (ig_intr_md_for_tm.ucast_egress_port != ig_md.fabric_meta.cpu_port) {
            /* Apply tables to find which network ID the user packet belongs to */
            if (!vlan_to_vnet_mapping.apply().hit) {
                kvs_multicast.apply();
            } else {
                /* Pop the vlan */
                if (hdr.vlan.isValid()) {
                    remove_vlan_header();
                }
            }
        }
    }
}

control VnetLearning(
        inout ingress_header_t hdr,
        inout ingress_metadata_t ig_md,
        inout digest_type_t digest_type,
        in ingress_intrinsic_metadata_t ig_intr_md)
        (bit<32> vnet_smac_iface_table_size) {

    /* Entry exists. Do nothing */
    action vnet_smac_iface_hit() {}

    /* Entry does not exist. Go to vnet_learn_smac_iface */
    action vnet_smac_iface_miss() {}

    /* vnet_smac_iface table is used to learn the hosts that are connected
     * to a given virtual network on a local user port. It also detects user MAC
     * migration.
     */
    table vnet_smac_iface {
        key = {
            ig_md.ktep_meta.ingress_iface_id : exact;
            ig_md.ktep_meta.nw_id : exact;
            ig_md.ktep_meta.src_mac : exact;
            ig_md.ktep_meta.ingress_vlan_id : exact;
        }
        actions = {
            vnet_smac_iface_hit;
            vnet_smac_iface_miss;
        }
        const default_action = vnet_smac_iface_miss;
        size = vnet_smac_iface_table_size;
        idle_timeout = true;
    }

    /* vnet_learn_smac_user_port action is called upon a vnet_smac_iface_miss
     * when the port is a user port to set the digest type to LOCAL_MAC_LEARNING.
     */
    action vnet_learn_smac_user_port() {
        digest_type = DIGEST_TYPE_LOCAL_MAC_LEARNING;
    }

    apply {
        if (ig_md.ktep_port_meta.port_type != PORT_TYPE_FABRIC) {
            if (!vnet_smac_iface.apply().hit) {
                vnet_learn_smac_user_port();
            }
        }
    }
}

control VnetCPU(
        inout ingress_header_t hdr,
        inout ingress_metadata_t ig_md,
        in ingress_intrinsic_metadata_t ig_intr_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm)
        (bit<32> knf_learn_flag_table_size) {

    BypassAndExit() bypass_and_exit;

    apply {
        if ((ig_intr_md.ingress_port == ig_md.fabric_meta.cpu_port)
                && (ig_intr_md_for_tm.ucast_egress_port != 0x1FF)) {
            bypass_and_exit.apply(ig_intr_md_for_tm);
        }
    }
}

control VnetExclusion(
        inout ingress_header_t hdr,
        inout ingress_metadata_t ig_md,
        in ingress_intrinsic_metadata_t ig_intr_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm)
        (bit<32> vrouter_ifaces_table_size) {

    /* When a packet is coming from a punt channel (has a pknid), set exclusion
     * ID that corresponds to this tunnel to avoid forwarding a copy back to the
     * source (vrouter control plane) in case of broadcast.
     */
    action set_punt_xid(exclusion_id_t xid) {
        ig_intr_md_for_tm.level1_exclusion_id = xid;
    }

    @ternary(1)
    table punt_xid {
        key = {
            hdr.knf.knid : exact;
        }
        actions = {
            set_punt_xid;
        }
        size = vrouter_ifaces_table_size;
    }

    action vrouter_iface_xid_hit(exclusion_id_t xid) {
        ig_intr_md_for_tm.level1_exclusion_id = xid;
    }

    table vrouter_iface_xid {
        key = {
            ig_md.ktep_router_meta.router_id : exact;
            ig_md.ktep_router_meta.output_iface : exact;
        }
        actions = {
            vrouter_iface_xid_hit;
        }
        size = vrouter_ifaces_table_size;
    }

    /* Set L1 exclusion ID to avoid flooding to other remote leafs if packet
     * gets replicated.
     */
    action set_leafs_xid() {
        ig_intr_md_for_tm.level1_exclusion_id = 4097;
    }

    apply {
        /* The L1 exclusion ID will have already been set if the packet comes
         * from a remote VTEP and hit a local KVTEP.
         */
        if (ig_intr_md_for_tm.level1_exclusion_id == 0) {
            if (ig_md.ktep_meta.process_l3 == 1 &&
                    ig_md.ktep_router_meta.process_l2_egress == 1) {
                vrouter_iface_xid.apply();
            } else if (ig_md.ktep_meta.received_on_punt_channel == 1) {
                punt_xid.apply();
            } else if (ig_md.ktep_meta.pkt_src == KTEP_SRC_LEAF) {
                set_leafs_xid();
            }
        }
        /* When a user packet coming from a KVS gets routed in the leaf via
         * the vRouter we need to reset the Multicast L2 exclusion ID
         * because some users in the destination L2 Network can be behind
         * the same KVS the packet came from on the source L2 Network.
         */
        if (ig_md.ktep_meta.process_l3 == 1 &&
                ig_md.ktep_meta.is_from_kvs == 1) {
            ig_intr_md_for_tm.level2_exclusion_id = 0;
        }
    }
}

control VnetDmac(
        inout ingress_header_t hdr,
        inout ingress_metadata_t ig_md,
        inout ig_ktep_metadata_t ktep_meta,
        inout ig_fabric_metadata_t fabric_meta,
        in ingress_intrinsic_metadata_t ig_intr_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm,
        inout ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md)
        (bit<32> vnet_dmac_table_size,
         bit<32> knid_to_mc_grp_mapping_table_size) {

    Meter<nw_id_t>(knid_to_mc_grp_mapping_table_size, MeterType_t.BYTES) mcast_meter;

    /* The destination MAC is known and it belongs to a host connected to a
     * local port with a VLAN ID.
     */
    action vnet_dmac_iface_vlan_hit(iface_id_t iface_id, vlan_id_t vlan_id) {
        ig_md.ktep_meta.egress_vlan_id = vlan_id;
        ig_md.ktep_meta.egress_iface_id = iface_id;
        ig_md.ktep_meta.egress_pkt_type = PKT_TYPE_VLAN;
        ig_md.fabric_meta.routing_lkp_flag = 0; /* Skip underlay routing */
        ig_md.ktep_meta.l2_lkp_flag = 1;
    }

    /* The destination MAC is known and it belongs to a host connected to a
     * local user port with no VLAN.
     */
    action vnet_dmac_iface_untagged_hit(iface_id_t iface_id) {
        ig_md.ktep_meta.egress_iface_id = iface_id;
        ig_md.ktep_meta.egress_pkt_type = PKT_TYPE_UNTAGGED;
        ig_md.fabric_meta.routing_lkp_flag = 0; /* Skip underlay routing */
        ig_md.ktep_meta.l2_lkp_flag = 1;
    }

    /* The destination MAC is known and it belongs to a host connected to a
     * remote leaf.
     */
    action vnet_dmac_remote_leaf_hit(dest_id_t remote_leaf_id) {
        ig_md.ktep_meta.dest_id = remote_leaf_id;
        ig_md.ktep_meta.egress_pkt_type = PKT_TYPE_KNF;
        ig_md.fabric_meta.routing_lkp_flag = 1;
    }

    /* The destination MAC is known and it belongs to local vrouter interface.
     * A KNF header will be added and the packet will be recirculated.
     */
    action vnet_dmac_local_router_hit() {
        ig_md.ktep_meta.egress_pkt_type = PKT_TYPE_KNF;
        ig_md.ktep_meta.dest_id = 1;
        ig_md.fabric_meta.routing_lkp_flag = 0;
        /* Recirculate in current pipe. */
        ig_intr_md_for_tm.ucast_egress_port[8:7] = (bit<2>)(ig_intr_md.ingress_port >> 7);
        ig_intr_md_for_tm.ucast_egress_port[6:0] = (bit<7>)RECIRC_PORT_PIPE_0;
    }

    /* The destination MAC is known and it belongs to a host connected to a
     * remote vtep via a local vrouter. A KNF and a VxLAN headers will be added
     * and the packet will be recirculated.
     */
    action vnet_dmac_remote_vtep_local_router_hit(tunnel_id_t kvtep_id,
            remote_vtep_id_t remote_vtep_id) {
        ig_md.tunnel_meta.tunnel_id = kvtep_id;
        ig_md.tunnel_meta.remote_vtep_id = remote_vtep_id;
        ig_md.tunnel_meta.process_egress = 1;
        ig_md.tunnel_meta.egress_pkt_type = TUNNEL_PKT_TYPE_VXLAN;

        ig_md.ktep_meta.egress_pkt_type = PKT_TYPE_KNF;
        ig_md.ktep_meta.dest_id = 1;

        ig_md.fabric_meta.routing_lkp_flag = 0;
        /* Recirculate in current pipe. */
        ig_intr_md_for_tm.ucast_egress_port[8:7] = (bit<2>)(ig_intr_md.ingress_port >> 7);
        ig_intr_md_for_tm.ucast_egress_port[6:0] = (bit<7>)RECIRC_PORT_PIPE_0;
    }

    /* The destination MAC is known and it belongs to a host connected to a
     * remote vtep via a remote vrouter.
     */
    action vnet_dmac_remote_vtep_remote_router_hit(tunnel_id_t kvtep_id,
            remote_vtep_id_t remote_vtep_id, dest_id_t kvtep_leaf_id) {
        ig_md.tunnel_meta.tunnel_id = kvtep_id;
        ig_md.tunnel_meta.remote_vtep_id = remote_vtep_id;
        ig_md.tunnel_meta.process_egress = 1;
        ig_md.tunnel_meta.egress_pkt_type = TUNNEL_PKT_TYPE_VXLAN;

        ig_md.ktep_meta.egress_pkt_type = PKT_TYPE_KNF;
        ig_md.ktep_meta.dest_id = kvtep_leaf_id;

        ig_md.fabric_meta.routing_lkp_flag = 1;
    }

    /* The destination MAC is not known. Carry on to multicast group ID table */
    action vnet_dmac_miss() {}

    /* vnet_dmac table is used to lookup the overlay destination MAC and find
     * where the host with that address is located in the fabric. The host can
     * be connected to a local port, a remote leaf, a remote vtep, or a vrouter.
     * If not known, the packet will be sent to all local ports and all
     * leafs that are participating on the same virtual network.
     */
    table vnet_dmac {
        key = {
            ktep_meta.nw_id : exact;
            ktep_meta.dst_mac : exact;
        }
        actions = {
            vnet_dmac_iface_vlan_hit;
            vnet_dmac_iface_untagged_hit;
            vnet_dmac_remote_leaf_hit;
            vnet_dmac_local_router_hit;
            vnet_dmac_remote_vtep_local_router_hit;
            vnet_dmac_remote_vtep_remote_router_hit;
            vnet_dmac_miss;
        }
        const default_action = vnet_dmac_miss();
        size = vnet_dmac_table_size;
        idle_timeout = true;
    }

    action vnet_dmac_drop_() {
        ig_dprsr_md.drop_ctl = DROP_CTL_ALL;
        exit;
    }

    /* Drop the packet when it's a KNF packet, not received on the punt channel
     * and the result action from vnet_dmac is to send it to a remote leaf.
     * This avoids a loop in the L2 network.
     */
    action remote_redirect() {
        ig_dprsr_md.drop_ctl = DROP_CTL_ALL;
        exit;
    }

    /* Accept the packet when it's a KNF packet destined to the local Hostdev */
    action local_redirect() {}

    /* Drops the packet if it is being redirected to a remote leaf or accepts
     * them if destinated to local IP.
     * In the future, this table needs to check a flag in the KNF header that
     * says it is a flood, then drops all flooding packets.
     */
    table redirect {
        key = {
            ig_md.ktep_meta.dest_id : exact;
        }
        actions = {
            local_redirect;
            remote_redirect;
        }
        const default_action = remote_redirect;
        const entries = {
            (1) : local_redirect();
        }
        size = 2;
    }

    /* Get multicast group ID for a given network ID */
    action knid_to_mc_grp_mapping_hit(mcast_grp_id_t mcast_grp, nw_id_t meter_index) {
        ig_md.ktep_meta.mcast_pkt_color = (MeterColor_t)mcast_meter.execute(meter_index);
        ig_intr_md_for_tm.mcast_grp_a = mcast_grp;
        ig_md.fabric_meta.routing_lkp_flag = 0; /* Skip underlay processing */
    }

    /* Unknown KNID. Drop the packet */
    action knid_to_mc_grp_mapping_miss() {}

    /* knid_to_mc_grp_mapping maps a network ID to a multicast group.
     * A multicast group ID is used to replicate the packet to local ports and
     * all participating leafs on the same L2 network.
     */
    table knid_to_mc_grp_mapping {
        key = {
            ktep_meta.nw_id : exact;
        }
        actions = {
            knid_to_mc_grp_mapping_hit;
            knid_to_mc_grp_mapping_miss;
        }
        const default_action = knid_to_mc_grp_mapping_miss();
        size = knid_to_mc_grp_mapping_table_size;
    }

    apply {
        switch(vnet_dmac.apply().action_run) {
            /* This would happen when a remote leaf sends a packet within KNF
             * destined to hostdev IP while the inner MAC is behind a local LAG.
             * The remote leaf should use the LAG IP and not the leaf IP and
             * therefore the packet will be dropped.
             */
            vnet_dmac_iface_untagged_hit :
            vnet_dmac_iface_vlan_hit : {
                if ((ig_md.ktep_meta.pkt_src == KTEP_SRC_LEAF) &&
                        (ig_md.ktep_meta.received_on_punt_channel == 0) &&
                        ((ig_md.ktep_meta.egress_iface_id & LAG_MSB) == LAG_MSB)) {
                    vnet_dmac_drop_();
                } else if (ig_md.ktep_meta.egress_iface_id == ig_md.ktep_meta.ingress_iface_id &&
                        ig_md.ktep_meta.egress_vlan_id == ig_md.ktep_meta.ingress_vlan_id &&
                        (ig_intr_md.ingress_port & 0x7F) != RECIRC_PORT_PIPE_0) {
                    /* TODO (ertr): Recirculation port iface ID is set to 0 but
                     * 0 is a valid iface ID. Thus, recirculated packets sent to
                     * iface 0 with no VLAN get dropped. Possible fixes are to
                     * start iface IDs at 1 or to assign an iface ID to the
                     * recirculation ports. See KSDF-23061.
                     */

                    /* This condition is for capturing and dropping unicast
                     * packets that are exiting on the same interface they came
                     * from.
                     */
                    vnet_dmac_drop_();
                }
            }

            vnet_dmac_remote_leaf_hit : {
                /* This would happen when a remote leaf decides to flood and it
                 * happens that the local leaf knows that the packet is on another
                 * remote leaf. It is very likely that the other remote leaf
                 * received the original flood so there is no point in sending the
                 * packet to him.
                 */
                if ((ig_md.ktep_meta.pkt_src == KTEP_SRC_LEAF) &&
                        (ig_md.ktep_meta.received_on_punt_channel == 0)) {
                    redirect.apply();
                }
            }

            vnet_dmac_remote_vtep_remote_router_hit :
            vnet_dmac_remote_vtep_local_router_hit : {
                if ((ig_md.ktep_meta.pkt_src == KTEP_SRC_LEAF) &&
                    (ig_md.ktep_meta.received_on_punt_channel == 0)) {
                    vnet_dmac_drop_();
                }
            }

            vnet_dmac_miss : {
                if (!knid_to_mc_grp_mapping.apply().hit) {
                    vnet_dmac_drop_();
                }
            }

            vnet_dmac_local_router_hit: {
                /* If packets received from a remote leaf are destined
                 * to the vrouter, they ought to be sent to the anycast IP of
                 * the vrouter - then vrouted ID shall be set by
                 * knf_dst_ip_is_local_vrouter_hit.
                 * If it's to the host-dev, router-id won't be set.
                 * So just drop them.
                 */
                 if ((ig_md.ktep_meta.pkt_src == KTEP_SRC_LEAF) &&
                     (ig_md.ktep_router_meta.router_id == 0)) {
                    vnet_dmac_drop_();
                }
            }
        }
    }
}

control DestIDMapping(
        inout ingress_metadata_t ig_md)
        (bit<32> dest_id_to_ip_table_size) {

    action dest_id_to_ip_hit(ipv6_addr_t dest_ip) {
        ig_md.fabric_meta.lkp_ipv6_addr = dest_ip;
    }

    action dest_id_to_ip_miss() {}

    /* Set the underlay lookup IPv6 destination address using the dest_id metadata */
    table dest_id_to_ip {
        key = {
            ig_md.ktep_meta.dest_id : exact;
        }
        actions = {
            dest_id_to_ip_hit;
            dest_id_to_ip_miss;
        }
        const default_action = dest_id_to_ip_miss();
        size = dest_id_to_ip_table_size;
    }

    apply {
        dest_id_to_ip.apply();
    }
}

control LagFailover(
        inout ingress_header_t hdr,
        in ingress_intrinsic_metadata_t ig_intr_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_tm_md,
        inout ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md)(
        bit<32> lag_failover_table_size,
        Register<bit<1>, lag_failover_reg_index_t> lag_failover_reg,
        RegisterAction<bit<1>, lag_failover_reg_index_t, bit<1>> lag_port_down) {

    DirectCounter<bit<32>>(CounterType_t.PACKETS) lag_failover_cntr;

    action lag_failover_go_next_pipe_hit(lag_failover_reg_index_t index,
            port_id_t next_recirc_port, bit<2> next_pipe_id) {
        lag_failover_cntr.count();
        lag_port_down.execute(index);
        hdr.pktgen_port_down.pipe_id = next_pipe_id;
        /* Recirculate the port_down packet to the next pipe. */
        ig_tm_md.ucast_egress_port = next_recirc_port;
        ig_tm_md.bypass_egress = 1;
        exit;
    }

    action lag_failover_last_pipe_hit(lag_failover_reg_index_t index) {
        lag_failover_cntr.count();
        lag_port_down.execute(index);
        /* This is the last pipe so the packet will be dropped. */
        ig_dprsr_md.drop_ctl = DROP_CTL_ALL;
        exit;
    }

    action lag_failover_miss() {
        lag_failover_cntr.count();
    }

    /* This table must be placed in the same stage as lag_groups table as they
     * both have access to the same register.
     */
    @stage(8)
    table lag_failover {
        key = {
            hdr.pktgen_port_down.port_num : exact;
            hdr.pktgen_port_down.pipe_id : exact;
        }
        actions = {
            lag_failover_go_next_pipe_hit;
            lag_failover_last_pipe_hit;
            lag_failover_miss;
        }
        default_action = lag_failover_miss();
        size = lag_failover_table_size;
        counters = lag_failover_cntr;
    }

    apply {
        lag_failover.apply();
    }
}

control VnetEgressIfaces(
        inout ingress_header_t hdr,
        inout ingress_metadata_t ig_md,
        inout ig_ktep_metadata_t ktep_meta,
        in ingress_intrinsic_metadata_t ig_intr_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm,
        inout ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md)(
        bit<32> egress_ports_table_size,
        bit<32> lag_groups_table_size,
        bit<32> lag_selection_table_size,
        bit<32> lag_selection_max_group_size,
        bit<32> remote_lags_table_size,
        Register<bit<1>, lag_failover_reg_index_t> lag_failover_reg) {

    DirectCounter<bit<32>>(CounterType_t.PACKETS) egress_ports_cntr;
    bool local_lag = false;

    Hash<bit<16>>(HashAlgorithm_t.CRC16) selector_hash;
    ActionProfile(lag_selection_table_size) lag_action_profile;
    ActionSelector(lag_action_profile, selector_hash, SelectorMode_t.FAIR,
            lag_failover_reg, lag_selection_max_group_size,
            lag_groups_table_size) lag_selector;


    action kvs_ingress_hit() {
        ig_md.ktep_meta.egress_pkt_type = PKT_TYPE_KNF;
        ig_md.ktep_meta.send_to_kvs = 1;
        ig_md.fabric_meta.l2_egress_lkp_flag = 1;
    }

    action kvs_ingress_miss() {}

    /* Checks if the iface_id corresponts to a KVS then sets the corresponding flags */
    table kvs_ingress {
        key = {
            ig_md.ktep_meta.egress_iface_id: exact;
        }
        actions = {
            kvs_ingress_hit;
            kvs_ingress_miss;
        }
        default_action = kvs_ingress_miss;
        size = lag_groups_table_size;
    }

    action lag_state_egress_up() {}

    action lag_state_egress_down() {
        ig_dprsr_md.drop_ctl = DROP_CTL_ALL;
    }

    /* LAG State table (UP/DOWN) for outgoing packets */
    table lag_state_egress {
        key = {
            ktep_meta.egress_iface_id : exact;
        }
        actions = {
            lag_state_egress_down;
            lag_state_egress_up;
        }
        const default_action = lag_state_egress_up;
        size = lag_groups_table_size;
    }

    action egress_ports_hit(port_id_t port) {
        egress_ports_cntr.count();
        ig_intr_md_for_tm.ucast_egress_port = port;
        ig_md.ktep_meta.process_l2 = 1;
    }

    action egress_ports_miss() {
        egress_ports_cntr.count();
    }

    /* Does the mapping between the logical egress interface ID and its corresponding
     * hardware egress port for the case of regular single ports TPs.
     */
    table egress_ports {
        key = {
            ktep_meta.egress_iface_id : exact;
        }
        actions = {
            egress_ports_hit;
            egress_ports_miss;
        }
        size = egress_ports_table_size;
        const default_action = egress_ports_miss();
        counters = egress_ports_cntr;
    }

    action lag_groups_hit(port_id_t port) {
        ig_intr_md_for_tm.ucast_egress_port = port;
        /* Reset process_l2 to 1 is needed for M-LAG/ICL packets that bypassed
         * vnet_dmac table. The flag will be used in egress for further
         * processing.
         */
        ig_md.ktep_meta.process_l2 = 1;
        local_lag = true;
    }

    /* With LAG, for each egress_iface_id it is possible to have multiple egress
     * hardware ports where only one port will be selected via the lag_selector
     * and the hashing of a list of metadata fields.
     */
    @stage(8)
    table lag_groups {
        key = {
            ktep_meta.egress_iface_id : exact;
            ig_md.fabric_meta.flow_hash : selector;
        }
        actions = {
            lag_groups_hit;
        }
        size = lag_groups_table_size;
        implementation = lag_selector;
    }

    action remote_lags_hit(iface_id_t remote_lag_id) {
        ig_md.ktep_meta.dest_id = 2;
        ig_md.ktep_meta.remote_lag_id = remote_lag_id;
        ig_md.ktep_meta.egress_pkt_type = PKT_TYPE_KNF;
        ig_md.ktep_meta.process_l2 = 1;
        ig_md.fabric_meta.routing_lkp_flag = 0;
        /* Recirculate to the same pipe. */
        ig_intr_md_for_tm.ucast_egress_port[8:7] = (bit<2>)(ig_intr_md.ingress_port >> 7);
        ig_intr_md_for_tm.ucast_egress_port[6:0] = (bit<7>)RECIRC_PORT_PIPE_0;
    }

    action remote_lags_miss() {
        ig_dprsr_md.drop_ctl = DROP_CTL_ALL;
        exit;
    }

    /* In case of a miss in lag_groups table, we send the packet to the
     * corresponding remote lag on the peer leaf via vICL (virtual Inter-Chassis
     * Link) through the fabric. Since this would introduce a dependency with the
     * underlay table and the current pipeline does not allow for extra dependency
     * chain, we decided to use the recirculation path so that the underlay route
     * would be resolved in a second pass of the packet through the pipeline.
     */
     @ternary(1)
    table remote_lags {
        key = {
            ktep_meta.egress_iface_id : exact;
        }
        actions = {
            remote_lags_hit;
            remote_lags_miss;
        }
        size = remote_lags_table_size;
        const default_action = remote_lags_miss();
    }

    action icl_drop() {
        ig_dprsr_md.drop_ctl = DROP_CTL_ALL;
        exit;
    }

    apply {
        kvs_ingress.apply();
        lag_state_egress.apply();

        if (!egress_ports.apply().hit) {
            lag_groups.apply();
            if (!local_lag) {
                /* When M-LAG links are all down, the hw egress_port would be 0
                 * and we will need to send the packet to configured peer leaf.
                 * However if the packet came from the peer leaf it would have
                 * remote LAG ID already set so we would drop it to avoid
                 * ping-pong effect.
                 */
                if (hdr.knf.isValid() && hdr.knf.remoteLagID != 0) {
                    icl_drop();
                } else {
                    remote_lags.apply();
                }
            }
        }
    }
}

/* We re-capture received packets on L2TPs right after the traffic manager in the
 * egress pipeline to be able to report on the packets and bytes dropped by the
 * TM by doing a subtraction against what we have received initially at the
 * beginning of ingress pipeline in vlan_to_vnet_mapping table.
 */
control VnetEgressRxStats(
        inout egress_header_t hdr,
        inout egress_metadata_t eg_md)() {

    DirectCounter<bit<64>>(CounterType_t.PACKETS_AND_BYTES) vnet_rx_stats_cntr;

    action vnet_rx_stats_hit() {
        vnet_rx_stats_cntr.count();
    }

    table vnet_rx_stats {
        key = {
            eg_md.ktep_meta.ingress_iface_id : exact;
            eg_md.ktep_meta.ingress_vlan_id : exact;
        }
        actions = {
            vnet_rx_stats_hit;
        }
        size = VLAN_TO_VNET_MAPPING_TABLE_SIZE;
        counters = vnet_rx_stats_cntr;
    }

    apply {
        vnet_rx_stats.apply();
    }
}

control VnetEgressVLANCntr(
        inout egress_header_t hdr,
        inout egress_metadata_t eg_md,
        inout eg_ktep_metadata_t ktep_meta,
        in egress_intrinsic_metadata_t eg_intr_md,
        inout egress_intrinsic_metadata_for_deparser_t eg_dprsr_md)
        (bit<32> vnet_egress_table_size) {

    DirectCounter<bit<64>>(CounterType_t.PACKETS_AND_BYTES) vnet_egress_cntr;

    /* Push a vlan header */
    action ktep_add_vlan_() {
        hdr.vlan.setValid();
        hdr.vlan.etherType = hdr.inner_ethernet.etherType;
        hdr.inner_ethernet.etherType = ETHERTYPE_VLAN;
        hdr.vlan.vlanID = eg_md.ktep_meta.egress_vlan_id;
        hdr.vlan.pcp = 0;
        hdr.vlan.cfi = 0;
    }

    action ktep_add_vlan_with_encap() {
        hdr.encap_vlan.setValid();
        hdr.encap_vlan.etherType = hdr.encap_ethernet.etherType;
        hdr.encap_ethernet.etherType = ETHERTYPE_VLAN;
        hdr.encap_vlan.vlanID = eg_md.ktep_meta.egress_vlan_id;
        hdr.encap_vlan.pcp = 0;
        hdr.encap_vlan.cfi = 0;
    }

    // action ktep_add_qinq() {
    //     hdr.inner_ethernet.etherType = ETHERTYPE_QINQ;
    //     hdr.qinq.setValid();
    //     hdr.qinq.vlanID = eg_md.ktep_meta.egress_vlan_id;
    //     hdr.qinq.pcp = 0;
    //     hdr.qinq.cfi = 0;
    //     hdr.qinq.etherType = ETHERTYPE_VLAN;
    // }

    // action ktep_remove_qinq() {
    //     hdr.inner_ethernet.etherType = ETHERTYPE_VLAN;
    //     hdr.qinq.setInvalid();
    // }

    // action ktep_set_outer_vlan() {
    //     hdr.qinq.vlanID = eg_md.ktep_meta.egress_vlan_id;
    // }

    /* On miss the packet doesn't need further modifications */
    action ktep_output_pkt_miss() {}

    /* This table is used after decapsulation or for local switching */
    table ktep_output_pkt {
        key = {
            ktep_meta.egress_pkt_type : exact;
            hdr.encap_ethernet.isValid() : exact;
        }
        actions = {
            ktep_add_vlan_;
            ktep_add_vlan_with_encap;
            // ktep_add_qinq;
            // ktep_set_outer_vlan;
            // ktep_remove_qinq;
            ktep_output_pkt_miss;
        }
        const entries = {
            (PKT_TYPE_UNTAGGED, false) : ktep_output_pkt_miss();
            (PKT_TYPE_UNTAGGED, true) : ktep_output_pkt_miss();
            (PKT_TYPE_VLAN, false) : ktep_add_vlan_();
            (PKT_TYPE_VLAN, true) : ktep_add_vlan_with_encap();
            // (PKT_TYPE_KNF, PKT_TYPE_QINQ)  : ktep_add_qinq();
            // (PKT_TYPE_QINQ, PKT_TYPE_VLAN) : ktep_set_outer_vlan();
            // (PKT_TYPE_QINQ, PKT_TYPE_KNF)  : ktep_remove_qinq();
        }
        size = 16;
    }

    action vnet_egress_forward() {
        vnet_egress_cntr.count();
    }

    /* Vnet_egress table is used to capture all L2 service packets exiting the
     * egress pipeline towards a local TP that is either an untagged or a VLAN
     * port. (VLAN ID 0 is used for Untagged).
     */
    table vnet_egress {
        key = {
            ktep_meta.egress_iface_id : exact;
            ktep_meta.egress_vlan_id : exact;
        }
        actions = {
            vnet_egress_forward;
        }
        const default_action = vnet_egress_forward;
        size = vnet_egress_table_size;
        counters = vnet_egress_cntr;
    }

    apply {
        ktep_output_pkt.apply();
        vnet_egress.apply();
    }
}
# 26 "leaf.p4" 2
# 1 "core/modules/l3_tunnel.p4" 1
/****************************************************************
 * Copyright (c) Kaloom, 2019
 *
 * This unpublished material is property of Kaloom Inc.
 * All rights reserved.
 * Reproduction or distribution, in whole or in part, is
 * forbidden except by express written permission of Kaloom Inc.
 ****************************************************************/




# 1 "/mnt/p4-tests/p4_16/customer/kaloom/leaf/core/types.p4" 1
/****************************************************************
 * Copyright (c) Kaloom, 2019
 *
 * This unpublished material is property of Kaloom Inc.
 * All rights reserved.
 * Reproduction or distribution, in whole or in part, is
 * forbidden except by express written permission of Kaloom Inc.
 ****************************************************************/
# 14 "core/modules/l3_tunnel.p4" 2

typedef bit<1> vxlan_encap_type_t;
const vxlan_encap_type_t VXLAN_ENCAP_IPV4 = 0;
const vxlan_encap_type_t VXLAN_ENCAP_IPV6 = 1;

/* kvtep ingress processing is part of the vrouter ingress block */
control OnetMappingAndLearning(
        inout ingress_header_t hdr,
        inout ingress_metadata_t ig_md,
        inout digest_type_t digest_type,
        in ingress_intrinsic_metadata_t ig_intr_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm,
        inout ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md)
        (bit<32> kvtep_onets_table_size,
         bit<32> kvtep_remote_vteps_table_size,
         bit<32> kvtep_onet_smac_table_size) {

    /* Used to keep track of whether the VxLAN encapsulation uses IPv4 or IPv6.
     * It is purposely uninitialized since it is only read if it is written.
     */
    vxlan_encap_type_t vxlan_encap_type;

    DirectCounter<bit<32>>(CounterType_t.PACKETS) kvtep_onets_cntr;
    DirectCounter<bit<32>>(CounterType_t.PACKETS) remote_vtep_v4_cntr;
    DirectCounter<bit<32>>(CounterType_t.PACKETS) onet_smac_cntr;

    action drop() {
        ig_dprsr_md.drop_ctl = DROP_CTL_ALL;
        exit;
    }

    /* Forward to an L2 Overlay Network */
    action kvtep_onets_v4_hit(nw_id_t o_nw_id, bit<1> learn) {
        kvtep_onets_cntr.count();
        ig_md.ktep_meta.nw_id = o_nw_id;
        ig_md.ktep_meta.src_mac = hdr.vxlan_inner_ethernet.srcAddr;
        ig_md.ktep_meta.dst_mac = hdr.vxlan_inner_ethernet.dstAddr;
        ig_md.ktep_meta.process_l3 = 0;
        ig_md.tunnel_meta.process_egress = 1;
        ig_md.tunnel_meta.egress_pkt_type = TUNNEL_PKT_TYPE_RAW;
        ig_md.tunnel_meta.learn_inner = learn;
        vxlan_encap_type = VXLAN_ENCAP_IPV4;

        /* Decap VxLAN encapsulation */
        hdr.inner_ethernet.setInvalid();
        hdr.inner_ipv4.setInvalid();
        hdr.inner_udp.setInvalid();
        hdr.vxlan.setInvalid();

        ig_md.ktep_meta.pkt_length_offset = ig_md.ktep_meta.pkt_length_offset + ETH_SIZE + IPV4_SIZE + UDP_SIZE + VXLAN_SIZE;

    }

    action kvtep_onets_v6_hit(nw_id_t o_nw_id, bit<1> learn) {
        kvtep_onets_cntr.count();
        ig_md.ktep_meta.nw_id = o_nw_id;
        ig_md.ktep_meta.src_mac = hdr.vxlan_inner_ethernet.srcAddr;
        ig_md.ktep_meta.dst_mac = hdr.vxlan_inner_ethernet.dstAddr;
        ig_md.ktep_meta.process_l3 = 0;
        ig_md.tunnel_meta.process_egress = 1;
        ig_md.tunnel_meta.egress_pkt_type = TUNNEL_PKT_TYPE_RAW;
        ig_md.tunnel_meta.learn_inner = learn;
        vxlan_encap_type = VXLAN_ENCAP_IPV6;

        /* Decap VxLAN encapsulation */
        hdr.inner_ethernet.setInvalid();
        hdr.inner_ipv6.setInvalid();
        hdr.inner_udp.setInvalid();
        hdr.vxlan.setInvalid();

        ig_md.ktep_meta.pkt_length_offset = ig_md.ktep_meta.pkt_length_offset + ETH_SIZE + IPV6_SIZE + UDP_SIZE + VXLAN_SIZE;

    }

    action kvtep_onets_miss() {
        kvtep_onets_cntr.count();
    }

    /* Kvtep overlay networks. Each overlay network is identified by a VNI
     * and it is mapped to an OKNID (Overlay Network ID).
     */
    table kvtep_onets {
        key = {
            ig_md.tunnel_meta.tunnel_id : exact;
            ig_md.ktep_router_meta.dst_ipAddr : exact;
            hdr.vxlan.vni : exact;
        }
        actions = {
            kvtep_onets_v4_hit;
            kvtep_onets_v6_hit;
            kvtep_onets_miss;
        }
        const default_action = kvtep_onets_miss;
        size = kvtep_onets_table_size;
        counters = kvtep_onets_cntr;
    }

    action remote_vtep_v4_hit(remote_vtep_id_t remote_vtep_id, exclusion_id_t xid) {
        remote_vtep_v4_cntr.count();
        ig_md.tunnel_meta.remote_vtep_id = remote_vtep_id;
        ig_intr_md_for_tm.level1_exclusion_id = xid;
    }

    action remote_vtep_v4_miss() {
        remote_vtep_v4_cntr.count();
        drop();
    }

    table remote_vtep_v4 {
        key = {
            ig_md.tunnel_meta.tunnel_id : exact;
            hdr.inner_ipv4.srcAddr : exact;
        }
        actions = {
            remote_vtep_v4_hit;
            remote_vtep_v4_miss;
        }
        const default_action = remote_vtep_v4_miss();
        size = kvtep_remote_vteps_table_size;
        counters = remote_vtep_v4_cntr;
    }

    action remote_vtep_v6_hit(remote_vtep_id_t remote_vtep_id, exclusion_id_t xid) {
        ig_md.tunnel_meta.remote_vtep_id = remote_vtep_id;
        ig_intr_md_for_tm.level1_exclusion_id = xid;
    }

    action remote_vtep_v6_miss() {
        drop();
    }

    table remote_vtep_v6 {
        key = {
            ig_md.tunnel_meta.tunnel_id : exact;
            hdr.inner_ipv6.srcAddr : exact;
        }
        actions = {
            remote_vtep_v6_hit;
            remote_vtep_v6_miss;
        }
        const default_action = remote_vtep_v6_miss;
        size = kvtep_remote_vteps_table_size;
    }

    /* Entry already exists. Do nothing */
    action onet_smac_hit() {
        onet_smac_cntr.count();
    }

    /* Entry does not exist. Go to learn_remote_vtep table */
    action onet_smac_miss() {
        onet_smac_cntr.count();
    }

    /* onet_smac table is used to learn hosts who are behind a remote vtep */
    table onet_smac {
        key = {
            ig_md.ktep_meta.nw_id : exact;
            ig_md.tunnel_meta.remote_vtep_id : exact;
            ig_md.ktep_meta.src_mac : exact;
        }
        actions = {
            onet_smac_hit;
            onet_smac_miss;
        }
        const default_action = onet_smac_miss();
        size = kvtep_onet_smac_table_size;
        counters = onet_smac_cntr;
        idle_timeout = true;
    }

    action learn_remote_vtep_v6() {
        digest_type = DIGEST_TYPE_REMOTE_VTEP_V6_MAC_LEARNING;
    }

    action learn_remote_vtep_v4() {
        digest_type = DIGEST_TYPE_REMOTE_VTEP_V4_MAC_LEARNING;
    }

    table learn_remote_vtep {
        key = {
            vxlan_encap_type : exact;
        }
        actions = {
            learn_remote_vtep_v4;
            learn_remote_vtep_v6;
        }
        size = 2;
        const entries = {
            VXLAN_ENCAP_IPV4 : learn_remote_vtep_v4();
            VXLAN_ENCAP_IPV6 : learn_remote_vtep_v6();
        }
    }

    apply {
        switch (kvtep_onets.apply().action_run) {
            kvtep_onets_v4_hit: {
                remote_vtep_v4.apply();
            }
            kvtep_onets_v6_hit : {
                remote_vtep_v6.apply();
            }
        }
        if (ig_md.tunnel_meta.learn_inner == 1) {
            switch (onet_smac.apply().action_run) {
                onet_smac_miss : {
                    learn_remote_vtep.apply();
                }
            }
        }
    }
}

control VRouterEncapTunnel(
        inout egress_header_t hdr,
        inout egress_metadata_t eg_md,
        in egress_intrinsic_metadata_t eg_intr_md,
        inout egress_intrinsic_metadata_for_deparser_t eg_dprsr_md)
        (bit<32> kvtep_encap_vxlan_table_size,
        bit<32> kvtep_rewrite_vxlan_knf_table_size,
        bit<32> kvtep_remotes_table_size,
        bit<32> vrouter_gre_encap_table_size) {

    DirectCounter<bit<32>>(CounterType_t.PACKETS) kvtep_decap_vxlan_cntr;
    bit<16> packet_length_increment;

    action drop() {
        eg_dprsr_md.drop_ctl = DROP_CTL_ALL;
        exit;
    }

    action increment_packet_length() {
        eg_md.ktep_meta.payload_length = eg_md.ktep_meta.payload_length + packet_length_increment;
    }

    /* Add VXLAN IPv6 header for a KNF packet */
    action kvtep_encap_vxlan_knf_v6(ipv6_addr_t kvtep_ip, mac_addr_t kvtep_mac) {
        /* Ethernet */
        hdr.encap_ethernet.setValid();
        hdr.encap_ethernet.dstAddr = kvtep_mac;
        hdr.encap_ethernet.srcAddr = 0;
        hdr.encap_ethernet.etherType = ETHERTYPE_IPV6;

        /* IPv6 */
        hdr.encap_ipv6.setValid();
        hdr.encap_ipv6.version = IPV6_VERSION;
        hdr.encap_ipv6.trafficClass = 0;
        hdr.encap_ipv6.flowLabel = 0;
        hdr.encap_ipv6.nextHdr = UDP_PROTO;
        hdr.encap_ipv6.hopLimit = HOP_LIMIT;
        hdr.encap_ipv6.srcAddr = kvtep_ip;
        hdr.encap_ipv6.payloadLen = eg_md.ktep_meta.payload_length + UDP_SIZE + VXLAN_SIZE;

        /* UDP */
        hdr.encap_udp.setValid();
        hdr.encap_udp.srcPort = 0;
        hdr.encap_udp.dstPort = UDP_PORT_VXLAN;
        hdr.encap_udp.checksum = 0;
        hdr.encap_udp.hdrLen = eg_md.ktep_meta.payload_length + UDP_SIZE + VXLAN_SIZE;

        /* VxLAN */
        hdr.encap_vxlan.setValid();
        hdr.encap_vxlan.flags = 0x08; /* The VNI bit is set to 1 for a valid VNI. */
        hdr.encap_vxlan.reserved = 0;
        hdr.encap_vxlan.reserved2 = 0;

        packet_length_increment = ETH_SIZE + IPV6_SIZE + UDP_SIZE + VXLAN_SIZE;
    }

    action kvtep_encap_vxlan_knf_v4(ipv4_addr_t kvtep_ip, mac_addr_t kvtep_mac) {
        /* Ethernet */
        hdr.encap_ethernet.setValid();
        hdr.encap_ethernet.dstAddr = kvtep_mac;
        hdr.encap_ethernet.srcAddr = 0;
        hdr.encap_ethernet.etherType = ETHERTYPE_IPV4;

        /* IPv4 */
        hdr.encap_ipv4.setValid();
        hdr.encap_ipv4.srcAddr = kvtep_ip;
        hdr.encap_ipv4.version = IPV4_VERSION;
        hdr.encap_ipv4.protocol = UDP_PROTO;
        hdr.encap_ipv4.ttl = HOP_LIMIT;
        hdr.encap_ipv4.ihl = 0x5;
        hdr.encap_ipv4.diffserv = 0x0;
        hdr.encap_ipv4.identification = 0x1;
        hdr.encap_ipv4.flags = 0;
        hdr.encap_ipv4.fragOffset = 0;
        hdr.encap_ipv4.totalLen = eg_md.ktep_meta.payload_length + IPV4_SIZE + UDP_SIZE + VXLAN_SIZE;

        /* UDP */
        hdr.encap_udp.setValid();
        hdr.encap_udp.srcPort = 0;
        hdr.encap_udp.dstPort = UDP_PORT_VXLAN;
        hdr.encap_udp.checksum = 0;
        hdr.encap_udp.hdrLen = eg_md.ktep_meta.payload_length + UDP_SIZE + VXLAN_SIZE;

        /* VxLAN */
        hdr.encap_vxlan.setValid();
        hdr.encap_vxlan.flags = 0x08; /* The VNI bit is set to 1 for a valid VNI. */
        hdr.encap_vxlan.reserved = 0;
        hdr.encap_vxlan.reserved2 = 0;

        packet_length_increment = ETH_SIZE + IPV4_SIZE + UDP_SIZE + VXLAN_SIZE;
    }

    action kvtep_encap_vxlan_knf_miss() {
        drop();
    }

    @ternary(1)
    table kvtep_encap_vxlan_knf {
        key = {
            eg_md.tunnel_meta.tunnel_id : exact;
        }
        actions = {
            kvtep_encap_vxlan_knf_v6;
            kvtep_encap_vxlan_knf_v4;
            kvtep_encap_vxlan_knf_miss;
        }
        const default_action = kvtep_encap_vxlan_knf_miss();
        size = kvtep_encap_vxlan_table_size;
    }

    action kvtep_remotes_hit_v6(vni_t vni, ipv6_addr_t remote_vtep_ip) {
        hdr.encap_ipv6.dstAddr = remote_vtep_ip;
        hdr.encap_vxlan.vni = vni;
        eg_md.tunnel_meta.process_egress = 0;
    }

    action kvtep_remotes_hit_v4(vni_t vni, ipv4_addr_t remote_vtep_ip) {
        hdr.encap_ipv4.dstAddr = remote_vtep_ip;
        hdr.encap_vxlan.vni = vni;
        eg_md.tunnel_meta.process_egress = 0;
    }

    action kvtep_remotes_miss() {
        drop();
    }

    @ternary(1)
    table kvtep_remotes {
        key = {
            eg_md.tunnel_meta.tunnel_id : exact;
            eg_md.tunnel_meta.remote_vtep_id : exact;
            eg_md.ktep_meta.nw_id : exact;
        }
        actions = {
            kvtep_remotes_hit_v6;
            kvtep_remotes_hit_v4;
            kvtep_remotes_miss;
        }
        const default_action = kvtep_remotes_miss();
        size = kvtep_remotes_table_size;
    }

    action gre_encap_v4(ipv4_addr_t sip, ipv4_addr_t dip, bit<1> keyPresent, bit<8> ttl) {
        hdr.encap_gre.setValid();
        hdr.encap_gre.checksumPresent = 0;
        hdr.encap_gre.routingPresent = 0;
        hdr.encap_gre.keyPresent = keyPresent;
        hdr.encap_gre.sequencePresent = 0;
        hdr.encap_gre.reserved0 = 0;
        hdr.encap_gre.version = 0;
        hdr.encap_gre.protocolType = hdr.inner_ethernet.etherType;

        hdr.encap_ipv4.setValid();
        hdr.encap_ipv4.version = 4;
        hdr.encap_ipv4.ihl = 5;
        hdr.encap_ipv4.diffserv = 0;
        hdr.encap_ipv4.identification = 1;
        hdr.encap_ipv4.flags = 0;
        hdr.encap_ipv4.fragOffset = 0;
        hdr.encap_ipv4.ttl = ttl;
        hdr.encap_ipv4.protocol = GRE_PROTO;
        hdr.encap_ipv4.srcAddr = sip;
        hdr.encap_ipv4.dstAddr = dip;

        hdr.inner_ethernet.setInvalid();

        hdr.encap_ethernet.setValid();
        hdr.encap_ethernet.etherType = ETHERTYPE_IPV4;
        /* MAC addresses of encap_ethernet are set by the VRouterEgress control
         * block since GRE packets are always routed.
         */
    }

    action gre_encap_v6(ipv6_addr_t sip, ipv6_addr_t dip, bit<1> keyPresent, bit<8> hopLimit) {
        hdr.encap_gre.setValid();
        hdr.encap_gre.checksumPresent = 0;
        hdr.encap_gre.routingPresent = 0;
        hdr.encap_gre.keyPresent = keyPresent;
        hdr.encap_gre.sequencePresent = 0;
        hdr.encap_gre.reserved0 = 0;
        hdr.encap_gre.version = 0;
        hdr.encap_gre.protocolType = hdr.inner_ethernet.etherType;

        hdr.encap_ipv6.setValid();
        hdr.encap_ipv6.version = 6;
        hdr.encap_ipv6.trafficClass = 0;
        hdr.encap_ipv6.flowLabel = 0;
        hdr.encap_ipv6.nextHdr = GRE_PROTO;
        hdr.encap_ipv6.hopLimit = hopLimit;
        hdr.encap_ipv6.srcAddr = sip;
        hdr.encap_ipv6.dstAddr = dip;

        hdr.inner_ethernet.setInvalid();

        hdr.encap_ethernet.setValid();
        hdr.encap_ethernet.etherType = ETHERTYPE_IPV6;
        /* MAC addresses of encap_ethernet are set by the VRouterEgress control
         * block since GRE packets are always routed.
         */
    }

    action gre_encap_v4_hit(ipv4_addr_t sip, ipv4_addr_t dip, bit<8> ttl) {
        gre_encap_v4(sip, dip, 0, ttl);

        hdr.encap_ipv4.totalLen = eg_md.ktep_meta.payload_length + IPV4_SIZE + GRE_SIZE - ETH_SIZE;
        packet_length_increment = IPV4_SIZE + GRE_SIZE;
    }

    action gre_encap_v4_key_hit(ipv4_addr_t sip, ipv4_addr_t dip, bit<32> key, bit<8> ttl) {
        gre_encap_v4(sip, dip, 1, ttl);
        hdr.encap_gre_key.setValid();
        hdr.encap_gre_key.key = key;

        hdr.encap_ipv4.totalLen = eg_md.ktep_meta.payload_length + IPV4_SIZE + GRE_SIZE + GRE_KEY_SIZE - ETH_SIZE;
        packet_length_increment = IPV4_SIZE + GRE_SIZE + GRE_KEY_SIZE;
    }

    action gre_encap_v6_hit(ipv6_addr_t sip, ipv6_addr_t dip, bit<8> hopLimit) {
        gre_encap_v6(sip, dip, 0, hopLimit);

        hdr.encap_ipv6.payloadLen = eg_md.ktep_meta.payload_length + GRE_SIZE - ETH_SIZE;
        packet_length_increment = IPV6_SIZE + GRE_SIZE;
    }

    action gre_encap_v6_key_hit(ipv6_addr_t sip, ipv6_addr_t dip, bit<32> key, bit<8> hopLimit) {
        gre_encap_v6(sip, dip, 1, hopLimit);
        hdr.encap_gre_key.setValid();
        hdr.encap_gre_key.key = key;

        hdr.encap_ipv6.payloadLen = eg_md.ktep_meta.payload_length + GRE_SIZE + GRE_KEY_SIZE - ETH_SIZE;
        packet_length_increment = IPV6_SIZE + GRE_SIZE + GRE_KEY_SIZE;
    }

    /* This table encapsulates the packet with GRE. Based on the GRE tunnel
     * interface ID, the encapsulation will either be IPv4 or IPv6 and it may or
     * may not have a GRE key.
     */
    table gre_encap {
        key = {
            eg_md.tunnel_meta.tunnel_id : exact;
        }
        actions = {
            gre_encap_v4_hit;
            gre_encap_v4_key_hit;
            gre_encap_v6_hit;
            gre_encap_v6_key_hit;
        }
        size = vrouter_gre_encap_table_size;
    }

    apply {
        if (eg_md.tunnel_meta.process_egress == 1) {
            if (eg_md.tunnel_meta.egress_pkt_type == TUNNEL_PKT_TYPE_VXLAN) {
                kvtep_encap_vxlan_knf.apply();
                kvtep_remotes.apply();
                increment_packet_length();
            } else if (eg_md.tunnel_meta.egress_pkt_type == TUNNEL_PKT_TYPE_GRE) {
                gre_encap.apply();
                increment_packet_length();
            }
        }
    }
}
# 27 "leaf.p4" 2
# 1 "core/modules/l3.p4" 1
/****************************************************************
 * Copyright (c) Kaloom, 2019
 *
 * This unpublished material is property of Kaloom Inc.
 * All rights reserved.
 * Reproduction or distribution, in whole or in part, is
 * forbidden except by express written permission of Kaloom Inc.
 ****************************************************************/




# 1 "/mnt/p4-tests/p4_16/customer/kaloom/leaf/core/types.p4" 1
/****************************************************************
 * Copyright (c) Kaloom, 2019
 *
 * This unpublished material is property of Kaloom Inc.
 * All rights reserved.
 * Reproduction or distribution, in whole or in part, is
 * forbidden except by express written permission of Kaloom Inc.
 ****************************************************************/
# 14 "core/modules/l3.p4" 2

const bit<8> TTL_MASK = 0xff;

control IngressVRouter(
        inout ingress_header_t hdr,
        inout ingress_metadata_t ig_md,
        in ingress_intrinsic_metadata_t ig_intr_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm,
        inout ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md)
        (bit<32> vrouter_l3_exact_table_size,
         bit<32> vrouter_l3_table_size,
         bit<32> vrouter_ifaces_table_size,
         bit<32> vrouter_neigh_table_size,
         bit<32> vrouter_iface_acl_table_size,
         bit<32> vrouter_gre_tunnel_table_size) {

    DirectCounter<bit<32>>(CounterType_t.PACKETS) ktep_neigh_cntr;
    DirectCounter<bit<32>>(CounterType_t.PACKETS) vrouter_mtu_cntr;
    DirectCounter<bit<64>>(CounterType_t.PACKETS_AND_BYTES) vrouter_acl_cntr;
    DirectCounter<bit<64>>(CounterType_t.PACKETS_AND_BYTES) gre_tunnel_cntr;

    /* VxLAN ingress processing */
    OnetMappingAndLearning(KVTEP_ONETS_TABLE_SIZE,
        KVTEP_REMOTE_VTEPS_TABLE_SIZE,
        KVTEP_ONET_SMAC_TABLE_SIZE) onet_mapping_learning;

    action gre_tunnel_hit_v4(vrf_id_t vrf_id) {
        gre_tunnel_cntr.count();

        ig_md.ktep_router_meta.vrf_id = vrf_id;
        ig_md.ktep_router_meta.gre_decap_op = GRE_DECAP_IPV4;
    }

    action gre_tunnel_hit_v4_key(vrf_id_t vrf_id) {
        gre_tunnel_cntr.count();

        ig_md.ktep_router_meta.vrf_id = vrf_id;
        ig_md.ktep_router_meta.gre_decap_op = GRE_DECAP_IPV4_KEY;
    }

    action gre_tunnel_hit_v6(vrf_id_t vrf_id) {
        gre_tunnel_cntr.count();

        ig_md.ktep_router_meta.vrf_id = vrf_id;
        ig_md.ktep_router_meta.gre_decap_op = GRE_DECAP_IPV6;
    }

    action gre_tunnel_hit_v6_key(vrf_id_t vrf_id) {
        gre_tunnel_cntr.count();

        ig_md.ktep_router_meta.vrf_id = vrf_id;
        ig_md.ktep_router_meta.gre_decap_op = GRE_DECAP_IPV6_KEY;
    }

    action gre_tunnel_miss() {}

    /* This table matches GRE packets that are received in a vrouter to check if
     * they hit a GRE tunnel interface. If so, a metadata is set to indicate
     * that the GRE enapsulation should be removed and the inner destination IP
     * is used to do the routing lookup.
     *
     * Since the GRE Key field is optional, an exact match is used on the Key
     * header validity bit and a ternary match is used for the Key itself. When
     * the Key is present, the valid bit is 1 and the Key mask is 0xffff. When
     * the Key is not present, the valid bit is 0 and the mask is 0x0.
     */
    @ignore_table_dependency("SwitchIngress.process_vrouter_mpls_vxlan.vrouter_lfib")
    table gre_tunnel {
        key = {
            ig_md.ktep_router_meta.router_id : exact;
            ig_md.ktep_router_meta.vrf_id : exact;
            ig_md.ktep_router_meta.dst_ipAddr : exact;
            ig_md.ktep_router_meta.src_ipAddr : exact;
            hdr.gre_key.isValid() : exact;
            hdr.gre_key.key : ternary; // Or copy to metadata for exact
        }
        actions = {
            gre_tunnel_hit_v4;
            gre_tunnel_hit_v4_key;
            gre_tunnel_hit_v6;
            gre_tunnel_hit_v6_key;
            @defaultonly gre_tunnel_miss;
        }
        default_action = gre_tunnel_miss;
        counters = gre_tunnel_cntr;
        size = vrouter_gre_tunnel_table_size;
    }

    action gre_tunnel_set_lkp_ip_v4() {
        /* RFC4291 (IPv4-Mapped IPv6 Address). */
        ig_md.ktep_router_meta.dst_ipAddr[127:32] = 0xffff;
        ig_md.ktep_router_meta.dst_ipAddr[31:0] = hdr.tunnel_inner_ipv4.dstAddr;
    }

    action gre_tunnel_set_lkp_ip_v6() {
        ig_md.ktep_router_meta.dst_ipAddr = hdr.tunnel_inner_ipv6.dstAddr;
    }

    /* Route corresponds to a Router's loopback interface. Packet is sent to the
     * control plane via the punt channel.
     */
    action send_to_punt_channel() {
        ig_md.ktep_router_meta.punt = 1;
    }

    /* Route with nexthop. The nexthop IP replaces dst_ipAddr to be used as key
     * of the ktep_neigh table.
     */
    action ktep_route_hit(vrouter_iface_id_t iface, nw_id_t nw_id,
            ipv6_addr_t nexthop) {
        ig_md.ktep_router_meta.dst_ipAddr = nexthop;
        ig_md.ktep_router_meta.output_iface = iface;
        ig_md.ktep_router_meta.neigh_lkp = 1;
        ig_md.ktep_meta.nw_id = nw_id;
    }

    action ktep_push_mpls_route_hit(vrouter_iface_id_t iface, nw_id_t nw_id,
            ipv6_addr_t nexthop, bit<20> label) {
        ig_md.ktep_router_meta.dst_ipAddr = nexthop;
        ig_md.ktep_router_meta.output_iface = iface;
        ig_md.ktep_router_meta.neigh_lkp = 1;
        ig_md.ktep_meta.nw_id = nw_id;
        /* Push MPLS header. */
        hdr.mpls.setValid();
        hdr.inner_ethernet.etherType = ETHERTYPE_MPLS_UNICAST;
        hdr.mpls.label = label;
        hdr.mpls.exp = 0;
        hdr.mpls.bos = 1;
        hdr.mpls.ttl = 255;
    }

    action ktep_route_gre_tunnel(vrouter_iface_id_t iface, nw_id_t nw_id,
            ipv6_addr_t nexthop, bit<7> tunnel_id) {
        ig_md.ktep_router_meta.dst_ipAddr = nexthop;
        ig_md.ktep_router_meta.output_iface = iface;
        ig_md.ktep_router_meta.neigh_lkp = 1;
        ig_md.ktep_meta.nw_id = nw_id;
        ig_md.tunnel_meta.egress_pkt_type = TUNNEL_PKT_TYPE_GRE; // hack for now to fit in 12 stages.
        ig_md.tunnel_meta.tunnel_id = tunnel_id;
        ig_md.tunnel_meta.process_egress = 1;
    }

    /* Route to Directly Connected Network. */
    action ktep_route_dcn_hit(vrouter_iface_id_t iface, nw_id_t nw_id) {
        ig_md.ktep_router_meta.output_iface = iface;
        ig_md.ktep_router_meta.neigh_lkp = 1;
        ig_md.ktep_meta.nw_id = nw_id;
    }

    /* Route that corresponds to a Router's loopback interface.
     * The packet will be sent to the control plane via the punt channel.
     */
    action ktep_route_local_hit() {
        send_to_punt_channel();
        ig_md.ktep_router_meta.neigh_lkp = 0;
    }

    /* Route to blackhole, drop_packet */
    action ktep_route_blackhole_hit() {
        ig_dprsr_md.drop_ctl = DROP_CTL_ALL;
        exit;
    }

    action ktep_route_miss() {
        send_to_punt_channel();
        ig_md.ktep_router_meta.neigh_lkp = 0;
    }

    action ktep_exact_route_miss() {}

    /* Routing table for /128 (IPv6) or /32 (IPv4) entries */
    table ktep_l3_exact {
        key = {
            ig_md.ktep_router_meta.router_id : exact;
            ig_md.ktep_router_meta.vrf_id : exact;
            ig_md.ktep_router_meta.dst_ipAddr : exact;
        }
        actions = {
            ktep_route_hit;
            /* Increases worst case action data leading to a larger table that
             * does not fit on Tofino 1.
             */
            // ktep_route_gre_tunnel;
            ktep_route_dcn_hit;
            ktep_route_local_hit;
            ktep_route_blackhole_hit;
            ktep_exact_route_miss;
        }
        const default_action = ktep_exact_route_miss();
        size = vrouter_l3_exact_table_size;
    }

    /* Routing LPM table. Routers use an 8 bits ID, it isolates logically their
     * respective routing tables.
     */
    @alpm(1)
    table ktep_l3 {
        key = {
            ig_md.ktep_router_meta.router_id : exact;
            ig_md.ktep_router_meta.vrf_id : exact;
            ig_md.ktep_router_meta.dst_ipAddr: lpm;
        }
        actions = {
            ktep_route_hit;
            ktep_push_mpls_route_hit;
            ktep_route_gre_tunnel;
            ktep_route_dcn_hit;
            ktep_route_local_hit;
            ktep_route_blackhole_hit;
            ktep_route_miss;
        }
        const default_action = ktep_route_miss();
        size = vrouter_l3_table_size;
    }

    /* Sets the destination MAC address of the user packet and prepares ktep
     * metadata for the next lookup in the vnet_dmac table.
     */
    action ktep_neigh_hit(mac_addr_t mac, vrouter_mac_id_t mac_id) {
        ktep_neigh_cntr.count();
        ig_md.ktep_meta.dst_mac = mac;
        ig_md.ktep_router_meta.dst_mac_id = mac_id;
        ig_md.ktep_meta.process_l2 = 1;
        ig_md.ktep_router_meta.process_l2_egress = 1;
    }

    /* Send packet to the control plane via the punt channel */
    action ktep_neigh_miss() {
        ktep_neigh_cntr.count();
        send_to_punt_channel();
    }

    /* L3 neighbor table maps the destination IP address to the MAC address.
     * Each interface has its own logical table.
     */
    table ktep_neigh {
        key = {
            ig_md.ktep_router_meta.router_id : exact;
            ig_md.ktep_router_meta.output_iface : exact;
            ig_md.ktep_router_meta.dst_ipAddr : exact;
        }
        actions = {
            ktep_neigh_hit;
            ktep_neigh_miss;
        }
        const default_action = ktep_neigh_miss();
        size = vrouter_neigh_table_size;
        counters = ktep_neigh_cntr;
    }

    action decrement_inner_ipv4_ttl() {
        hdr.inner_ipv4.ttl = hdr.inner_ipv4.ttl - 1;
    }

    action decrement_inner_ipv6_hlim() {
        hdr.inner_ipv6.hopLimit = hdr.inner_ipv6.hopLimit - 1;
    }

    /* When ttl == 0 or ttl == 1, send packet to the control plane via the
     * punt channel.
     */
    action last_hop_punt() {
        send_to_punt_channel();
    }

    /* This table performs the following TTL operations :
     *      Decrement TTL when ttl > 1.
     *      Send packet to remote control plane via punt tunnel when ttl == 1.
     *      Drop the packet when ttl == 0.
     */
    table decrement_user_ttl {
        key = {
            hdr.inner_ipv4.isValid() : exact;
            hdr.inner_ipv6.isValid() : exact;
            hdr.inner_ipv4.ttl : ternary;
            hdr.inner_ipv6.hopLimit : ternary;
        }
        actions = {
            decrement_inner_ipv4_ttl;
            decrement_inner_ipv6_hlim;
            last_hop_punt;
        }
        size = 6;
        /* TODO: Set TCAM priority for static entries */
        const entries = {
            (true, false, 0 & TTL_MASK, _) : last_hop_punt();
            (false, true, _, 0 & TTL_MASK) : last_hop_punt();

            (true, false, 1 & TTL_MASK, _) : last_hop_punt();
            (false, true, _, 1 & TTL_MASK) : last_hop_punt();

            (true, false, _, _) : decrement_inner_ipv4_ttl();
            (false, true, _, _) : decrement_inner_ipv6_hlim();
        }
    }

    action decrement_tunnel_inner_ipv4_ttl() {
        hdr.tunnel_inner_ipv4.ttl = hdr.tunnel_inner_ipv4.ttl - 1;
    }

    action decrement_tunnel_inner_ipv6_hlim() {
        hdr.tunnel_inner_ipv6.hopLimit = hdr.tunnel_inner_ipv6.hopLimit - 1;
    }

    /* This table performs the following TTL operations for GRE packets that
     * will be decapsulated:
     *      Decrement inner TTL when ttl > 1.
     *      Send packet to remote control plane via punt tunnel when inner
     *      ttl == 1.
     *      Drop the packet when inner ttl == 0.
     */
    table decrement_user_ttl_gre {
        key = {
            hdr.tunnel_inner_ipv4.isValid() : exact;
            hdr.tunnel_inner_ipv6.isValid() : exact;
            hdr.tunnel_inner_ipv4.ttl : ternary;
            hdr.tunnel_inner_ipv6.hopLimit : ternary;
        }
        actions = {
            decrement_tunnel_inner_ipv4_ttl;
            decrement_tunnel_inner_ipv6_hlim;
            last_hop_punt;
        }
        size = 6;
        const entries = {
            (true, false, 0 & TTL_MASK, _) : last_hop_punt();
            (false, true, _, 0 & TTL_MASK) : last_hop_punt();

            (true, false, 1 & TTL_MASK, _) : last_hop_punt();
            (false, true, _, 1 & TTL_MASK) : last_hop_punt();

            (true, false, _, _) : decrement_tunnel_inner_ipv4_ttl();
            (false, true, _, _) : decrement_tunnel_inner_ipv6_hlim();
        }
    }

    action vrouter_mtu_hit(bit<16> mtu_size) {
        vrouter_mtu_cntr.count();
        ig_md.ktep_router_meta.mtu_pkt_diff =
            mtu_size - ig_md.ktep_router_meta.pkt_len;
    }

    action vrouter_mtu_miss() {
        vrouter_mtu_cntr.count();
    }

    table vrouter_mtu {
        key = {
            ig_md.ktep_router_meta.router_id : exact;
            ig_md.ktep_router_meta.output_iface : exact;
        }
        actions = {
            vrouter_mtu_hit;
            vrouter_mtu_miss;
        }
        const default_action = vrouter_mtu_miss();
        size = vrouter_ifaces_table_size;
        counters = vrouter_mtu_cntr;
    }

    action vrouter_acl_drop() {
        ig_dprsr_md.drop_ctl = DROP_CTL_ALL;
        vrouter_acl_cntr.count();
        exit;
    }

    action vrouter_acl_fwd() {
        vrouter_acl_cntr.count();
    }

    table vrouter_acl {
        key = {
            ig_md.ktep_router_meta.router_id : exact;
            ig_md.ktep_router_meta.input_iface : exact;
            hdr.inner_ipv6.isValid() : ternary;
            hdr.inner_ipv6.srcAddr : ternary;
            hdr.inner_ipv6.dstAddr : ternary;
            hdr.inner_ipv6.nextHdr : ternary;
            hdr.inner_ipv4.isValid() : ternary;
            hdr.inner_ipv4.srcAddr : ternary;
            hdr.inner_ipv4.dstAddr : ternary;
            hdr.inner_ipv4.protocol : ternary;
            hdr.inner_udp.isValid() : ternary;
            hdr.inner_udp.srcPort : ternary;
            hdr.inner_udp.dstPort : ternary;
            hdr.inner_tcp.isValid() : ternary;
            hdr.inner_tcp.srcPort : ternary;
            hdr.inner_tcp.dstPort : ternary;
        }
        actions = {
            vrouter_acl_drop;
            vrouter_acl_fwd;
        }
        default_action = vrouter_acl_fwd();
        counters = vrouter_acl_cntr;
        size = vrouter_iface_acl_table_size;
    }

    apply {
        if (ig_md.ktep_router_meta.is_not_ip == 0) {
            if (hdr.vxlan.isValid()) {
                /* VxLAN ingress processing */
                onet_mapping_learning.apply(hdr, ig_md, ig_dprsr_md.digest_type,
                    ig_intr_md, ig_intr_md_for_tm, ig_dprsr_md);
            } else if (hdr.gre.isValid()) {
                if (gre_tunnel.apply().hit) {
                    if (hdr.tunnel_inner_ipv4.isValid()) {
                        gre_tunnel_set_lkp_ip_v4();
                    } else {
                        gre_tunnel_set_lkp_ip_v6();
                    }
                }
            }
            /* Some L2 packets arriving from remote vtep will match the vRouter
             * KVtep interface but if they are not vxlan packets they will still
             * have ktep_meta.process_l3 == 1 because of vrouter_ifaces_hit.
             * Those packets should perform l2 services and bypass l3 vrouter
             * tables.
             */
            if ((ig_md.ktep_meta.process_l3 == 1) &&
                    (ig_md.ktep_router_meta.input_iface != 0xff)) {
                /* Process L3 routing if packet misses Vxlan onets mapping or if
                 * it is not destined to KVtep.
                 */
                switch(ktep_l3_exact.apply().action_run) {
                    ktep_exact_route_miss : {
                        ktep_l3.apply();
                    }
                }
                if (ig_md.ktep_router_meta.neigh_lkp == 1) {
                    switch(ktep_neigh.apply().action_run) {
                        ktep_neigh_hit : {
                            if (ig_md.ktep_router_meta.gre_decap_op == GRE_DECAP_NONE) {
                                decrement_user_ttl.apply();
                            } else {
                                decrement_user_ttl_gre.apply();
                            }
                            vrouter_mtu.apply();
                        }
                    }
                }

                vrouter_acl.apply();

            }
        } else if (ig_md.ktep_router_meta.input_iface != 0xff) {
            send_to_punt_channel();
        }
    }
}

control VRouter(
        inout ingress_header_t hdr,
        inout ingress_metadata_t ig_md,
        in ingress_intrinsic_metadata_t ig_intr_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm,
        inout ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md)
        (bit<32> vrouter_ifaces_table_size,
         bit<32> vrouter_lfib_table_size) {

    DirectCounter<bit<32>>(CounterType_t.PACKETS) pre_routing_cntr;
    DirectCounter<bit<64>>(CounterType_t.PACKETS_AND_BYTES) vrouter_ifaces_cntr;
    DirectCounter<bit<32>>(CounterType_t.PACKETS) vrouter_lfib_cntr;

    IngressVRouter(VROUTER_L3_EXACT_TABLE_SIZE,
        VROUTER_L3_TABLE_SIZE,
        VROUTER_IFACES_TABLE_SIZE,
        VROUTER_NEIGH_TABLE_SIZE,
        VROUTER_ACL_RULES_TABLE_SIZE,
        VROUTER_GRE_TUNNEL_TABLE_SIZE) ingress_vrouter;

    action drop_packet() {
        ig_dprsr_md.drop_ctl = DROP_CTL_ALL;
        exit;
    }

    /* Convert IPv4 to IPv6 to use the same LPM table */
    action copy_ipv4_addr_usr() {
        pre_routing_cntr.count();
        /* RFC4291 (IPv4-Mapped IPv6 Address). */
        ig_md.ktep_router_meta.dst_ipAddr[127:32] = 0xffff;
        ig_md.ktep_router_meta.dst_ipAddr[31:0] = hdr.inner_ipv4.dstAddr;
        ig_md.ktep_router_meta.src_ipAddr[127:32] = 0xffff;
        ig_md.ktep_router_meta.src_ipAddr[31:0] = hdr.inner_ipv4.srcAddr;
        /* Only L2 payload is used for MTU calculations (it exclude the L2
         * headers). IPv4 Total Length is the size of the IPv4 payload and
         * IPv4 header.
         */
        ig_md.ktep_router_meta.pkt_len = hdr.inner_ipv4.totalLen;
        ig_md.ktep_router_meta.is_not_ip = 0;
    }

    /* Copy inner_ipv6 address to be used as key in LPM table */
    action copy_inner_ipv6_addr() {
        pre_routing_cntr.count();
        ig_md.ktep_router_meta.dst_ipAddr = hdr.inner_ipv6.dstAddr;
        ig_md.ktep_router_meta.src_ipAddr = hdr.inner_ipv6.srcAddr;
        /* Only L2 payload is used for MTU calculations (it exclude the L2
         * headers). IPv6 Payload Length is the size of the IPv6 payload which
         * does not include the IPv6 header size. Thus, the IPv6 header size
         * must be added.
         */
        ig_md.ktep_router_meta.pkt_len = hdr.inner_ipv6.payloadLen + IPV6_SIZE;
        ig_md.ktep_router_meta.is_not_ip = 0;
    }

    /* Non IP packets that match Router's interface MAC address are sent to
     * the control plane via the punt channel.
     */
    action process_non_ip_pkts() {
        pre_routing_cntr.count();
        ig_md.ktep_router_meta.is_not_ip = 1;
    }

    /* Copy the destination IP address from the user packet into ktep router
     * metadata. Also send non IP packets to remote control plane via punt tunnel.
     */
    table pre_routing {
        key = {
            hdr.inner_ipv4.isValid() : exact;
            hdr.inner_ipv6.isValid() : exact;
        }
        actions = {
            copy_ipv4_addr_usr;
            copy_inner_ipv6_addr;
            process_non_ip_pkts;
        }
        const default_action = process_non_ip_pkts;
        counters = pre_routing_cntr;
        size = 4;
        const entries = {
            (true, false) : copy_ipv4_addr_usr();
            (false, true) : copy_inner_ipv6_addr();
            (false, false) : process_non_ip_pkts();
        }
    }

    action vrouter_ifaces_hit(vrouter_id_t router_id, vrouter_iface_id_t iface,
            dest_id_t punt_id, vrf_id_t vrf_id) {
        vrouter_ifaces_cntr.count();
        ig_md.ktep_meta.dest_id = punt_id;
        ig_md.ktep_meta.process_l3 = 1;
        ig_md.ktep_meta.pkt_src = KTEP_SRC_OTHER;
        ig_md.ktep_router_meta.router_id = router_id;
        ig_md.ktep_router_meta.vrf_id = vrf_id;
        /* in case of vxlan interface kvtep ID is the vrouter ID */
        ig_md.tunnel_meta.tunnel_id = router_id;
        ig_md.ktep_router_meta.input_iface = iface;
    }

    action vrouter_ifaces_miss() {
        vrouter_ifaces_cntr.count();
    }

    /* Filters packets that are sent to the vRouter where L3 processing is
     * performed then the L3 packet reaches L2 processing. Otherwise, the packet
     * will move directly to L2 processing.
     */
    @ternary(1)
    table vrouter_ifaces {
        key = {
            ig_md.ktep_meta.nw_id : exact;
            ig_md.ktep_meta.dst_mac : exact;
        }
        actions = {
            vrouter_ifaces_hit;
            vrouter_ifaces_miss;
        }
        const default_action = vrouter_ifaces_miss;
        size = vrouter_ifaces_table_size;
        counters = vrouter_ifaces_cntr;
    }

    action vrouter_lfib_pop_mpls_hit(vrf_id_t vrf_id) {
        vrouter_lfib_cntr.count();
        ig_md.ktep_router_meta.vrf_id = vrf_id;
        /* The challenging part of MPLS pop action is to have the right payload
         * length when we perform KNF encapsulation.
         * In fact, the packet length provided by tofino (eg_intr_md.pkt_length)
         * is the size of the original packet which includes the MPLS label.
         * An adjustement of MPLS_SIZE needs to be subtracted when computing the
         * payload length for IPv6 and UDP payload length fields.
         */
        ig_md.ktep_router_meta.mpls_decap = 1;
    }

    action vrouter_lfib_miss() {
        vrouter_lfib_cntr.count();
        drop_packet();
    }

    /* Label Forwarding Information Base. */
    table vrouter_lfib {
        key = {
            ig_md.ktep_router_meta.router_id : exact;
            hdr.mpls.label : exact;
        }
        actions = {
            vrouter_lfib_pop_mpls_hit;
            vrouter_lfib_miss;
        }
        const default_action = vrouter_lfib_miss;
        size = vrouter_lfib_table_size;
        counters = vrouter_lfib_cntr;
    }

    /* Drop MPLS packets with TTL = 0 or 1. */
    table mpls_ttl_check {
        key = {
            hdr.mpls.ttl : exact;
        }
        actions = {
            drop_packet;
        }
        const entries = {
            (0) : drop_packet();
            (1) : drop_packet();
        }
        size = 2;
    }

    /* IP packets that has unsupported ip options are sent to
     * the control plane via the punt channel.
     */
    action process_unsupported_ip_options_pkts() {
        ig_md.ktep_router_meta.punt = 1;
    }

    action vrouter_vnet_to_iface_hit(vrouter_iface_id_t iface, dest_id_t punt_id) {
        ig_md.ktep_router_meta.input_iface = iface;
        ig_md.ktep_meta.dest_id = punt_id;
        ig_md.ktep_router_meta.punt = 1;
    }

    action vrouter_vnet_to_iface_miss() {}

    /* This table is used when a packet is received with a VR anycast IP (so it
     * is destined for the VR) but it does not hit the vrouter_ifaces
     * table. In that case, the packet is punted to the vrouter CP. If a remote
     * leaf floods a packet, one replica will be for the anycast Ip which will
     * hit this table and be punted and another replica will be for the leaf IP
     * which will be in turn flooded to local ports only.
     */
    @pragma ways 5
    table vrouter_vnet_to_iface {
        key = {
            ig_md.ktep_router_meta.router_id : exact;
            ig_md.ktep_meta.nw_id : exact;
        }
        actions = {
            vrouter_vnet_to_iface_hit;
            vrouter_vnet_to_iface_miss;
        }
        const default_action = vrouter_vnet_to_iface_miss;
        size = vrouter_ifaces_table_size;
    }

    apply {
        /* L3 processing is performed only for:
         *      1- A user packet that arrived from a server on a user port
         *      (LAG included) or a KVS port.
         *      2- A KNF packet with destination IPv6 is the vRouter Anycast IP
         *      (which means a router_id have been assigned in knf_dst_ip_is_local
         *       table).
         *      3- A packet that was already routed and its destination MAC is a
         *      local vRouter interface so it is getting recirculated.
         *      4 - LAG traffic also may be recirculated. So allow only if process_l2 is true.
         */
        if (ig_md.ktep_router_meta.router_id != 0 ||
                ig_md.ktep_port_meta.port_type == PORT_TYPE_USER ||
                ig_md.ktep_port_meta.port_type == PORT_TYPE_KVS ||
                ((ig_intr_md.ingress_port & 0x7F) == RECIRC_PORT_PIPE_0)
                    && (ig_md.ktep_meta.process_l2 == 1)) {
            pre_routing.apply();
            switch (vrouter_ifaces.apply().action_run) {
                vrouter_ifaces_hit : {
                    if (hdr.mpls.isValid()) {
                        mpls_ttl_check.apply();
                        vrouter_lfib.apply();
                    }
                    if (ig_md.ip_options_unsupported == 1) {
                        process_unsupported_ip_options_pkts();
                    } else {
                        ingress_vrouter.apply(hdr, ig_md, ig_intr_md,
                            ig_intr_md_for_tm, ig_dprsr_md);
                    }
                }
                vrouter_ifaces_miss : {
                    if (ig_md.ktep_meta.received_on_punt_channel == 0) {
                        vrouter_vnet_to_iface.apply();
                    }
                }
            }
        }
    }
}

control VRouterGreDecap(
        inout ingress_header_t hdr,
        inout ingress_metadata_t ig_md) {

    action gre_decap_ipv4() {
        hdr.inner_ethernet.etherType = hdr.gre.protocolType;
        hdr.inner_ipv4.setInvalid();
        hdr.gre.setInvalid();

        /* TODO(ertr): Is it possible for it to have IPv4 Options? */
        ig_md.ktep_meta.pkt_length_offset = ig_md.ktep_meta.pkt_length_offset + IPV4_SIZE + GRE_SIZE;
    }

    action gre_decap_ipv4_key() {
        hdr.inner_ethernet.etherType = hdr.gre.protocolType;
        hdr.inner_ipv4.setInvalid();
        hdr.gre.setInvalid();
        hdr.gre_key.setInvalid();

        /* TODO(ertr): Is it possible for it to have IPv4 Options? */
        ig_md.ktep_meta.pkt_length_offset = ig_md.ktep_meta.pkt_length_offset + IPV4_SIZE + GRE_SIZE + GRE_KEY_SIZE;
    }

    action gre_decap_ipv6() {
        hdr.inner_ethernet.etherType = hdr.gre.protocolType;
        hdr.inner_ipv6.setInvalid();
        hdr.gre.setInvalid();

        ig_md.ktep_meta.pkt_length_offset = ig_md.ktep_meta.pkt_length_offset + IPV6_SIZE + GRE_SIZE;
    }

    action gre_decap_ipv6_key() {
        hdr.inner_ethernet.etherType = hdr.gre.protocolType;
        hdr.inner_ipv6.setInvalid();
        hdr.gre.setInvalid();
        hdr.gre_key.setInvalid();

        ig_md.ktep_meta.pkt_length_offset = ig_md.ktep_meta.pkt_length_offset + IPV6_SIZE + GRE_SIZE + GRE_KEY_SIZE;
    }

    /* This table removes the GRE encapsulation from the packet. This is done in
     * a separate table rather than in the gre_tunnel table directly because it
     * must be deferred to once it has been determined that the packet will not
     * be punted to the vrouter CP.
     */
    table gre_decap {
        key = {
            ig_md.ktep_router_meta.gre_decap_op : exact;
        }
        actions = {
            gre_decap_ipv4;
            gre_decap_ipv4_key;
            gre_decap_ipv6;
            gre_decap_ipv6_key;
            NoAction;
        }
        const default_action = NoAction();
        const entries = {
            GRE_DECAP_IPV4 : gre_decap_ipv4();
            GRE_DECAP_IPV4_KEY : gre_decap_ipv4_key();
            GRE_DECAP_IPV6 : gre_decap_ipv6();
            GRE_DECAP_IPV6_KEY : gre_decap_ipv6_key();
        }
        size = 4;
    }

    apply {
        gre_decap.apply();
    }
}

control VRouterPuntChannel(
        inout ingress_header_t hdr,
        inout ingress_metadata_t ig_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm,
        inout ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md)
        (bit<32> vrouter_ifaces_table_size) {

    DirectCounter<bit<32>>(CounterType_t.PACKETS) prepare_for_punt_tunnel_cntr;
    Meter<meter_index_t>(4096, MeterType_t.BYTES) unicast_punt_meter;

    action drop_packet() {
        ig_dprsr_md.drop_ctl = DROP_CTL_ALL;
        exit;
    }

    action set_punt_data(nw_id_t p_nw_id, ipv6_addr_t punt_ip, meter_index_t index) {
        ig_md.ktep_router_meta.meter_color = (MeterColor_t)unicast_punt_meter.execute(index);
        prepare_for_punt_tunnel_cntr.count();
        ig_md.fabric_meta.lkp_ipv6_addr = punt_ip;
        ig_md.fabric_meta.routing_lkp_flag = 1;
        ig_md.ktep_meta.egress_pkt_type = PKT_TYPE_KNF;
        ig_md.ktep_meta.nw_id = p_nw_id;
        ig_md.ktep_meta.process_l2 = 0;
        /* Setting this flag to 0 causes the packet to bypass the logic which
         * rewrites the MAC addresses. This ensures that the packet reaches
         * the CP vrouter unmodified.
         */
        ig_md.ktep_router_meta.process_l2_egress = 0;
    }

    @ternary(1)
    table prepare_for_punt_tunnel {
        key = {
            ig_md.ktep_router_meta.router_id : exact;
            ig_md.ktep_router_meta.input_iface : exact;
        }
        actions = {
            set_punt_data;
        }
        size = vrouter_ifaces_table_size;
        counters = prepare_for_punt_tunnel_cntr;
    }

    apply {
        switch (prepare_for_punt_tunnel.apply().action_run) {
            set_punt_data : {
                /* On a punt channel we need to receive the original packet,
                 * therefore for packets hitting an MPLS route an MPLS header
                 * would have been pushed. Here we revert it back.
                 * We recognize this case when ktep_router_meta.mpls_decap
                 * is 0. Since as a PE router (no label switching) if it receives
                 * an MPLS packet it would pop the label and MPLS decap would be 1.
                 * When MPLS decap is 0 this means that the MPLS label was
                 * pushed by the PE itself.
                 */
                if (hdr.mpls.isValid() &&
                        ig_md.ktep_router_meta.mpls_decap == 0) {
                    /* Pop MPLS header. */
                    hdr.mpls.setInvalid();
                    if (hdr.inner_ipv4.isValid()) {
                        hdr.inner_ethernet.etherType = ETHERTYPE_IPV4;
                    } else if (hdr.inner_ipv6.isValid()) {
                        hdr.inner_ethernet.etherType = ETHERTYPE_IPV6;
                    }
                }
            }
        }
        if (ig_md.ktep_router_meta.meter_color == MeterColor_t.RED) {
            drop_packet();
        }
    }
}

control VRouterEgress(
        inout egress_header_t hdr,
        inout egress_metadata_t eg_md,
        in egress_intrinsic_metadata_t eg_intr_md,
        inout egress_intrinsic_metadata_for_deparser_t eg_dprsr_md)
        (bit<32> vrouter_ifaces_table_size,
        bit<32> vrouter_neigh_mac_table_size,
        bit<32> vrouter_table_size) {

    DirectCounter<bit<64>>(CounterType_t.PACKETS_AND_BYTES) ktep_router_iface_cntr;

    action ktep_router_iface_set_src_mac(mac_addr_t mac) {
        ktep_router_iface_cntr.count();
        eg_md.ktep_router_meta.src_mac = mac;
    }

    action ktep_router_iface_set_src_mac_miss() {
        ktep_router_iface_cntr.count();
        eg_md.ktep_router_meta.src_mac = 0;
    }

    /* Set the source MAC address of the packet to the MAC address of vRouter's
     * egress interface.
     */
    table ktep_router_iface {
        key = {
            eg_md.ktep_router_meta.router_id : exact;
            eg_md.ktep_router_meta.output_iface : exact;
        }
        actions = {
            ktep_router_iface_set_src_mac;
            ktep_router_iface_set_src_mac_miss;
        }
        default_action = ktep_router_iface_set_src_mac_miss();
        size = vrouter_ifaces_table_size;
        counters = ktep_router_iface_cntr;
    }

    action ktep_router_dst_mac_hit(mac_addr_t dst_mac) {
        eg_md.ktep_router_meta.dst_mac = dst_mac;
    }

    /* Drop the packet. */
    action ktep_router_dst_mac_miss() {
        eg_dprsr_md.drop_ctl = DROP_CTL_ALL;
        exit;
    }

    /* Prepare the destination MAC address of the user packet to be set by next
     * actions in inner_ethernet or vxlan_inner_ethernet depending on the egress
     * packet type.
     */
    table ktep_router_dst_mac {
        key = {
            eg_md.ktep_router_meta.dst_mac_id : exact;
        }
        actions = {
            ktep_router_dst_mac_hit;
            ktep_router_dst_mac_miss;
        }
        default_action = ktep_router_dst_mac_miss();
        size = vrouter_neigh_mac_table_size;
    }

    /* Set the underlay source IPv6 address to the vRouter Anycast DP-IP. */
    action vrouter_knf_rewrite_hit(ipv6_addr_t vrouter_dp_ip) {
        hdr.ipv6.srcAddr = vrouter_dp_ip;
    }

    /* Drop the packet.
     * TODO : enable packet drop when the Redundant vRouter feature is ready.
     */
    action vrouter_knf_rewrite_miss() {
        // eg_dprsr_md.drop_ctl = DROP_CTL_ALL;
        // exit;
    }

    @ternary(1)
    table vrouter_knf_rewrite {
        key = {
            eg_md.ktep_router_meta.router_id : exact;
        }
        actions = {
            vrouter_knf_rewrite_hit;
            vrouter_knf_rewrite_miss;
        }
        default_action = vrouter_knf_rewrite_miss();
        size = vrouter_table_size;
    }

    apply {
        if (eg_md.ktep_router_meta.process_l2_egress == 1) {
            ktep_router_iface.apply();
            ktep_router_dst_mac.apply();
            if (eg_md.tunnel_meta.egress_pkt_type == TUNNEL_PKT_TYPE_GRE) {
                hdr.encap_ethernet.srcAddr = eg_md.ktep_router_meta.src_mac;
                hdr.encap_ethernet.dstAddr = eg_md.ktep_router_meta.dst_mac;
            } else {
                hdr.inner_ethernet.srcAddr = eg_md.ktep_router_meta.src_mac;
                hdr.inner_ethernet.dstAddr = eg_md.ktep_router_meta.dst_mac;
            }
        }
        if (hdr.knf.isValid() && eg_md.ktep_meta.send_to_kvs == 0 &&
                eg_md.ktep_meta.process_l3 == 1) {
            vrouter_knf_rewrite.apply();
        }
    }
}

control L3EgressCntr(
        inout egress_metadata_t eg_md,
        inout eg_ktep_metadata_t ktep_meta)
        (bit<32> punt_tunnel_stats_table_size) {

    DirectCounter<bit<64>>(CounterType_t.PACKETS_AND_BYTES) punt_tunnel_stats_cntr;

    action punt_tunnel_stats_hit() {
        punt_tunnel_stats_cntr.count();
        /* Due To compiler issues we did not find a way to pass the information
         * that if the packet is sent to punt channel it should not be MPLS decapsulated.
         * In fact we have a flag "punt" in ktep_router_meta but it is not bridged.
         * Since the l3_counters block happen right before the MPLS decap block then
         * we can use the hit action that confirms that the packet is about to be
         * sent on the punt channel, and we revert mpls_decap back to 0.
         * Ideally we should not mix MPLS decap handeling with the stats table.
         * This should be fixed by using the "punt" flag when compiler allows it.
         */
        eg_md.ktep_router_meta.mpls_decap = 0;
    }

    action punt_tunnel_stats_miss() {
        punt_tunnel_stats_cntr.count();
    }

    /* Punt_tunnel_stats table is used to capture L3 service packets exiting
     * the egress pipeline towards a vRouter's punt channel.
     */
    @placement_priority(-1)
    @ternary(1)
    table punt_tunnel_stats {
        key = {
            ktep_meta.nw_id : exact;
        }
        actions = {
            punt_tunnel_stats_hit;
            punt_tunnel_stats_miss;
        }
        const default_action = punt_tunnel_stats_miss();
        size = punt_tunnel_stats_table_size;
        counters = punt_tunnel_stats_cntr;
    }

    apply {
        punt_tunnel_stats.apply();
    }
}
# 28 "leaf.p4" 2
# 1 "core/modules/mpls.p4" 1
/****************************************************************
 * Copyright (c) Kaloom, 2020
 *
 * This unpublished material is property of Kaloom Inc.
 * All rights reserved.
 * Reproduction or distribution, in whole or in part, is
 * forbidden except by express written permission of Kaloom Inc.
 ****************************************************************/




# 1 "/mnt/p4-tests/p4_16/customer/kaloom/leaf/core/types.p4" 1
/****************************************************************
 * Copyright (c) Kaloom, 2019
 *
 * This unpublished material is property of Kaloom Inc.
 * All rights reserved.
 * Reproduction or distribution, in whole or in part, is
 * forbidden except by express written permission of Kaloom Inc.
 ****************************************************************/
# 14 "core/modules/mpls.p4" 2

control DecapMPLS(
        inout egress_header_t hdr,
        inout egress_metadata_t eg_md)() {

    apply {
        if (eg_md.ktep_router_meta.mpls_decap == 1 &&
                eg_md.ktep_meta.egress_pkt_type == PKT_TYPE_KNF) {
            /* Pop MPLS header. */
            hdr.mpls.setInvalid();
            if (hdr.knf.isValid()) {
                hdr.udp.hdrLen = hdr.udp.hdrLen - MPLS_SIZE;
                hdr.ipv6.payloadLen = hdr.ipv6.payloadLen - MPLS_SIZE;
                if (hdr.inner_ipv4.isValid()) {
                    hdr.inner_ethernet.etherType = ETHERTYPE_IPV4;
                } else if (hdr.inner_ipv6.isValid()) {
                    hdr.inner_ethernet.etherType = ETHERTYPE_IPV6;
                }
            }
        }
    }
}
# 29 "leaf.p4" 2
# 1 "core/modules/cpu.p4" 1
/****************************************************************
 * Copyright (c) Kaloom, 2019
 *
 * This unpublished material is property of Kaloom Inc.
 * All rights reserved.
 * Reproduction or distribution, in whole or in part, is
 * forbidden except by express written permission of Kaloom Inc.
 ****************************************************************/




# 1 "/mnt/p4-tests/p4_16/customer/kaloom/leaf/core/types.p4" 1
/****************************************************************
 * Copyright (c) Kaloom, 2019
 *
 * This unpublished material is property of Kaloom Inc.
 * All rights reserved.
 * Reproduction or distribution, in whole or in part, is
 * forbidden except by express written permission of Kaloom Inc.
 ****************************************************************/
# 14 "core/modules/cpu.p4" 2

/* Get the CPU port value set by the control plane and Set the Ring ID metadata */
control CPUPort(out port_id_t cpu_port_id) {

    action get_cpu_port_(port_id_t port_id) {
        cpu_port_id = port_id;
    }

    table cpu_port {
        key = {}
        actions = {
            get_cpu_port_;
        }

        /* Setting default action suppresses uninitialized parameter warnings.
         * The default action must be modified by the controller with the correct
         * CPU port ID.
         */
        default_action = get_cpu_port_(0);
        size = 1;
    }

    apply {
        cpu_port.apply();
    }
}

/* Resetting cpu_port in egress pipeline as action data by the host reduces its
 * life range in ingress pipeline and lowers the size of bridged metadata.
 */
control EgressCPUPort(inout egress_metadata_t eg_md) {

    action get_cpu_port_hit(port_id_t cpu_port) {
        eg_md.fabric_meta.cpu_port = cpu_port;
    }

    table get_cpu_port {
        key = {}
        actions = {
            get_cpu_port_hit;
        }
        default_action = get_cpu_port_hit(0);
        size = 1;
    }

    apply {
        get_cpu_port.apply();
    }
}

control EgressCPUPortEncap(
        inout egress_header_t hdr,
        inout egress_metadata_t eg_md,
        in egress_intrinsic_metadata_t eg_intr_md) {

    action dp_ctrl_header_encap() {
        hdr.dp_ctrl_hdr.setValid();
        hdr.dp_ctrl_hdr.ring_id = RING_ID_EGRESS_CPU_PORT;
        hdr.dp_ctrl_hdr.etherType = ETHERTYPE_DP_CTRL;
        hdr.dp_ctrl_hdr.port = 0x1FF;
    }

    apply {
        if (eg_intr_md.egress_port == eg_md.fabric_meta.cpu_port) {
            dp_ctrl_header_encap();
        }
    }
}

@pa_container_size("ingress", "ig_intr_md_for_dprsr.drop_ctl", 8)
@pa_byte_pack("ingress", 2, "ig_intr_md_for_tm.mcast_grp_a.$valid", "hasExited", "ig_intr_md_for_dprsr.drop_ctl.$valid", "ig_intr_md_for_dprsr.drop_ctl")
control CoppRateLimiting(
        in ingress_intrinsic_metadata_t ig_intr_md,
        inout ig_fabric_metadata_t fabric_meta,
        inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm,
        inout ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md)(
        bit<32> copp_drop_table_size) {

    DirectCounter<bit<64>>(CounterType_t.PACKETS_AND_BYTES) copp_drop_cntr;

    /* TODO: The exit from this action needs to be removed
     * for packets to be accounted by the counter for L1TP drops.
     * But this is retained for now as the removal causes
     * new dependencies in MAU resulting in 13 stage requirement.
     */
    action drop_pkt() {
        ig_dprsr_md.drop_ctl = DROP_CTL_ALL;
        copp_drop_cntr.count();
        exit;
    }

    table copp_drop_stats {
        key = {
            fabric_meta.logical_port_id: exact;
        }
        actions = {
            drop_pkt;
        }
        const default_action = drop_pkt;
        size = copp_drop_table_size;
        counters = copp_drop_cntr;
    }

    apply {
        if (fabric_meta.copp_packet_color == MeterColor_t.RED) {
            copp_drop_stats.apply();
        }
    }
}
# 30 "leaf.p4" 2
# 1 "core/modules/fabric.p4" 1
/****************************************************************
 * Copyright (c) Kaloom, 2019
 *
 * This unpublished material is property of Kaloom Inc.
 * All rights reserved.
 * Reproduction or distribution, in whole or in part, is
 * forbidden except by express written permission of Kaloom Inc.
 ****************************************************************/
# 17 "core/modules/fabric.p4"
# 1 "/mnt/p4-tests/p4_16/customer/kaloom/leaf/core/types.p4" 1
/****************************************************************
 * Copyright (c) Kaloom, 2019
 *
 * This unpublished material is property of Kaloom Inc.
 * All rights reserved.
 * Reproduction or distribution, in whole or in part, is
 * forbidden except by express written permission of Kaloom Inc.
 ****************************************************************/
# 18 "core/modules/fabric.p4" 2
# 1 "/mnt/p4-tests/p4_16/customer/kaloom/leaf/core/modules/port_failover.p4" 1
/****************************************************************
 * Copyright (c) Kaloom, 2019
 *
 * This unpublished material is property of Kaloom Inc.
 * All rights reserved.
 * Reproduction or distribution, in whole or in part, is
 * forbidden except by express written permission of Kaloom Inc.
 ****************************************************************/





control PortFailover(
        inout ingress_header_t hdr,
        in ingress_intrinsic_metadata_t ig_intr_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_tm_md,
        inout ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md)(
        bit<32> port_failover_table_size,
        Register<bit<1>, port_failover_reg_index_t> port_failover_reg,
        RegisterAction<bit<1>, port_failover_reg_index_t, bit<1>> port_failover_register_action) {

    action drop_packet() {
        ig_dprsr_md.drop_ctl = DROP_CTL_ALL;
        exit;
    }

    /* Deactivate entry by clearing its bound register in the register array. */
    action port_failover_deactivate_entry(port_failover_reg_index_t index) {
        /* deactivate ecmp member by calling execute_stateful_alu to clear the
         * register.
         */
        port_failover_register_action.execute(index);
    }

    /* Deactivate entry by clearing its bound register in the register array.
     * This action is the last port-to-index pain, recirculate portdown packet to
     * next pipe.
     */
    action port_failover_deactivate_entry_last_member(port_failover_reg_index_t index) {
        /* deactivate ecmp member by calling execute_stateful_alu to clear the
         * register.
         */
        port_failover_register_action.execute(index);
    }

    action port_failover_miss() {
        drop_packet();
    }

    /* Workaround for Barefoot Case #9630 */




    /* Since the port_failover table accesses the register array named
     * "port_failover_reg" that is bound to the ecmp_groups table, both tables must
     * be in the same stage.
     */




    /* port_failover is used to translate port number into a register index that is
     * bound to the ECMP defined by this port number.
     * This table is updated by a callback after each ECMP member addition.
     * "packet_id" is used to disable multiple registers within the same pipe.
     */
    table port_failover {
        key = {
            hdr.pktgen_port_down.port_num : exact;
            hdr.pktgen_port_down.packet_id : exact;
        }
        actions = {
            port_failover_deactivate_entry;
            port_failover_deactivate_entry_last_member;
            port_failover_miss;
        }
        default_action = port_failover_miss();
        size = port_failover_table_size;
    }

    action recirc_failover_pkt(port_id_t recirc_port) {
        /* Set packet_id to 0 to start deactivating entry from the beginning. */
        hdr.pktgen_port_down.packet_id = 0;
        ig_tm_md.ucast_egress_port = recirc_port;
        ig_tm_md.bypass_egress = 1;
        exit;
    }

    action port_failover_recirc_miss() {
        drop_packet();
    }

    /* Recirculate the port down packet to be processed by the other pipes.
     * The last pipe must drop the port down packet.
     */
    table port_failover_recirc {
        key = {
            hdr.pktgen_port_down.pipe_id : exact;
        }
        actions = {
            recirc_failover_pkt;
            port_failover_recirc_miss;
        }
        size = 2;
    }

    /* If one port is shared by multiple ECMP entries, we need to recirculate the
     * portdown packet to the same port after incrementing the instance_id/packet_id
     * to deactivate all entries that has this port as their destination.
     * Thus, this action sets the recirculation port number of the same pipe.
     */
    action recirc_to_same_pipe() {
        /* Add 1 to packet_id to fetch the next entry in failover table. */
        hdr.pktgen_port_down.packet_id = hdr.pktgen_port_down.packet_id + 1;
        ig_tm_md.ucast_egress_port[8:7] = (bit<2>)(ig_intr_md.ingress_port >> 7);
        ig_tm_md.ucast_egress_port[6:0] = (bit<7>)RECIRC_PORT_PIPE_0;
        ig_tm_md.bypass_egress = 1;
        exit;
    }

    apply {
        if (hdr.pktgen_port_down.isValid() && hdr.pktgen_ext_header.isValid()) {
            /* The valid condition wasn't enough for capturing only pktgen packets.
             * lldp packets were matching also this condition.
             * therefore, an extra condition was added to check pktgen ethertype
             * and block lldp packets from matching port failover table.
             * TODO: remove ethertype condition and re-test with lldp packets
             */
            if (hdr.pktgen_ext_header.etherType == ETHERTYPE_BF_PKTGEN) {
                switch(port_failover.apply().action_run) {
                    port_failover_deactivate_entry_last_member : {
                        port_failover_recirc.apply();
                    }
                    /* Using if condition to apply recirc_to_same_pipe did not work.
                     * So it was replaced by this code to apply recirc_to_same_pipe
                     * if the action is not of type
                     * "port_failover_deactivate_entry_last_member". This replaces
                     * the use of isLastMember parameter from the table, but it
                     * requires removing the entry and adding it with new action
                     * type in order to update it.
                     */
                    port_failover_deactivate_entry : {
                        recirc_to_same_pipe();
                    }
                }
            }
        }
    }
}
# 19 "core/modules/fabric.p4" 2

control L2Ingress(
        inout ingress_header_t hdr,
        inout ig_fabric_metadata_t fabric_meta,
        in ingress_intrinsic_metadata_t ig_intr_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_tm_md,
        inout ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md)(
        bit<32> l2_ingress_table_size) {

    Meter<logical_port_id_t>(COPP_METER_SIZE, MeterType_t.BYTES) l2_ingress_meter;

    action l2_ingress_miss() {
        ig_dprsr_md.drop_ctl = DROP_CTL_ALL;
        exit;
    }

    action l2_ingress_send_to_cpu_hit(port_id_t cpu_port) {
        fabric_meta.copp_packet_color = (MeterColor_t)l2_ingress_meter.execute(fabric_meta.logical_port_id);
        hdr.dp_ctrl_hdr.setValid();
        hdr.dp_ctrl_hdr.ring_id = RING_ID_L2_INGRESS;
        hdr.dp_ctrl_hdr.etherType = ETHERTYPE_DP_CTRL;
        hdr.dp_ctrl_hdr.port = (bit<16>)ig_intr_md.ingress_port;
        ig_tm_md.ucast_egress_port = cpu_port;
        fabric_meta.routing_lkp_flag = 0;
        ig_tm_md.bypass_egress = 1;
    }

    /* Receive from the CPU */
    action l2_ingress_process_pcie_cpu_packet() {
        /* Set egress port */
        ig_tm_md.ucast_egress_port = (port_id_t)hdr.dp_ctrl_hdr.port;
        /* Pop dp_ctrl_header */
        hdr.dp_ctrl_hdr.setInvalid();
        fabric_meta.routing_lkp_flag = 0;
    }

    /* Receive from the CPU */
    action l2_ingress_process_host_nic_cpu_packet() {
        /* Set egress port */
        ig_tm_md.ucast_egress_port = (port_id_t)hdr.dp_ctrl_hdr.port;
        /* Pop dp_ctrl_header */
        hdr.dp_ctrl_hdr.setInvalid();
        fabric_meta.routing_lkp_flag = (bit<1>)hdr.knf.isValid();
        fabric_meta.lkp_ipv6_addr = hdr.ipv6.dstAddr;
    }

    /* If a packet hits this action then it will be forwarded to the routing
     * block
     */
    action l2_ingress_router_iface_hit() {
        fabric_meta.lkp_ipv6_addr = hdr.ipv6.dstAddr;
    }

    action l2_ingress_recirc_port_hit() {
        fabric_meta.lkp_ipv6_addr = hdr.ipv6.dstAddr;
    }

    action l2_ingress_block_hit() {
        ig_dprsr_md.drop_ctl = DROP_CTL_ALL;
    }

    /* l2_ingress table classifies incoming packets and forward to the
     * corresponding block. Ternary match is needed so that we can mask the
     * port id for an lldp packet arriving at any port also ternary is needed
     * if we want to mask dest_mac for multicast cases.
     * 0 - The highest priority for CPU/recirc port.
     * 1 - The next priority for LLDP entry for punting to the CPU port
     *     regardless of the incoming port and its state.
     * 2 - The next priority for other entries matching port/mac.
     */
    table l2_ingress {
        key = {
            ig_intr_md.ingress_port : ternary;
            hdr.ethernet.dstAddr : ternary;
            fabric_meta.port_disabled: ternary;
        }
        actions = {
            l2_ingress_router_iface_hit;
            l2_ingress_send_to_cpu_hit;
            l2_ingress_block_hit;
            l2_ingress_process_pcie_cpu_packet;
            l2_ingress_process_host_nic_cpu_packet;
            l2_ingress_recirc_port_hit;
            l2_ingress_miss;
        }
        const default_action = l2_ingress_miss();
        size = l2_ingress_table_size;
    }

    apply {
        l2_ingress.apply();
    }
}

control FabricRouting(
        inout ingress_header_t hdr,
        inout ig_fabric_metadata_t fabric_meta,
        in ingress_intrinsic_metadata_t ig_intr_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_tm_md,
        inout ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md)(
        bit<32> routing_ipv6_table_size,
        bit<32> neighbor_table_size,
        bit<32> ecmp_groups_table_size,
        bit<32> ecmp_selection_table_size,
        bit<32> ecmp_selection_max_group_size,
        Register<bit<1>, port_failover_reg_index_t> port_failover_reg) {

    DirectCounter<bit<32>>(CounterType_t.PACKETS) neighbor_cntr;
    DirectCounter<bit<32>>(CounterType_t.PACKETS) ecmp_groups_cntr;
    Meter<logical_port_id_t>(COPP_METER_SIZE, MeterType_t.BYTES) routing_meter;

    action drop_packet() {
        ig_dprsr_md.drop_ctl = DROP_CTL_ALL;
        exit;
    }

    /* The packet can be sent directly to the destination device and does not need
     * to be sent via another router.
     */
    action routing_dcn_hit() {
        fabric_meta.l2_egress_lkp_flag = 1;
    }

    /* The host is accessible via another router */
    action routing_nh_hit(ipv6_addr_t nexthop_ipv6) {
        fabric_meta.l2_egress_lkp_flag = 1;
        fabric_meta.lkp_ipv6_addr = nexthop_ipv6;
    }

    action routing_to_host(port_id_t cpu_port) {
        fabric_meta.copp_packet_color = (MeterColor_t)routing_meter.execute(fabric_meta.logical_port_id);
        hdr.dp_ctrl_hdr.setValid();
        hdr.dp_ctrl_hdr.ring_id = RING_ID_ROUTING_IPV6;
        hdr.dp_ctrl_hdr.etherType = ETHERTYPE_DP_CTRL;
        hdr.dp_ctrl_hdr.port = (bit<16>)ig_intr_md.ingress_port;
        ig_tm_md.ucast_egress_port = cpu_port;
        ig_tm_md.bypass_egress = 1;
    }

    action routing_ecmp(ecmp_group_id_t ecmp_grp_id) {
        fabric_meta.ecmp_grp_id = ecmp_grp_id;
    }

    action routing_miss() {
        drop_packet();
    }

    /* Routing_ipv6 table performs a lookup on the packet ipv6 destination
     * address. This table allows to differentiate between DCN and NH routes.
     * In case it's a DCN route then it sets fabric_meta.lkp_ipv6_addr to the
     * destination IP in the packet.
     * If it's a NH route then it sets fabric_meta.lkp_ipv6_addr to the IP of
     * the NH.
     * If it's a local IP the packet is sent to Host CPU.
     * If it's an ECMP action, set a flag to resolve nexthop IP using
     * ecmp_groups table
     * In case of a table miss the packet is dropped.
     */
    table routing_ipv6 {
        key = {
            fabric_meta.lkp_ipv6_addr : lpm;
        }
        actions = {
            routing_to_host;
            routing_dcn_hit;
            routing_nh_hit;
            routing_ecmp;
            routing_miss;
        }
        const default_action = routing_miss();
        size = routing_ipv6_table_size;
    }

    /* Sets the destination MAC and the egress port */
    action neighbor_hit(mac_addr_id_t neigh_mac, port_id_t egress_port) {
        neighbor_cntr.count();
        fabric_meta.neigh_mac = neigh_mac;
        ig_tm_md.ucast_egress_port = egress_port;
    }

    action neighbor_miss() {
        neighbor_cntr.count();
        drop_packet();
    }

    /* Neighbor table sets the destination mac and the egress port after
     * performing an exact match (/128) on the IPv6 address resolved in the
     * previous lookup from the routing_ipv6 table.
     */
    table neighbor {
        key = {
            fabric_meta.lkp_ipv6_addr : exact;
        }
        actions = {
            neighbor_hit;
            neighbor_miss;
        }
        const default_action = neighbor_miss();
        size = neighbor_table_size;
        counters = neighbor_cntr;
    }


    Hash<bit<16>>(HashAlgorithm_t.CRC16) selector_hash;




    ActionProfile(ecmp_selection_table_size) ecmp_action_profile;
    ActionSelector(ecmp_action_profile, selector_hash, SelectorMode_t.FAIR,
            port_failover_reg, ecmp_selection_max_group_size,
            ecmp_groups_table_size) ecmp_selector;


    /* The host is accessible via another router */
    action ecmp_routing_nh_hit(ipv6_addr_t nexthop_ipv6) {
        ecmp_groups_cntr.count();
        fabric_meta.l2_egress_lkp_flag = 1;
        fabric_meta.lkp_ipv6_addr = nexthop_ipv6;
    }

    /* Workaround for Barefoot Case #9630 */



    /* Since the port_failover table accesses the register array named
     * "port_failover_reg" that is bound to the ecmp_groups table, both tables must
     * be in the same stage.
     */




    /* ecmp_groups table is used to select one nexthop entry from an ECMP group
     * that is defined for each destination IP.
     * Destimation IP is mapped into an ecmp_group_id using routing_ipv6 table,
     * then this table select one entry from the selected group based on a hashing
     * algorithm defined by a hash calculation algorithm (namely ecmp_hash).
     */
    table ecmp_groups {
        key = {
            fabric_meta.ecmp_grp_id : exact;
# 269 "core/modules/fabric.p4"
            fabric_meta.flow_hash : selector;
            fabric_meta.lkp_ipv6_addr : selector;

        }
        actions = {
            ecmp_routing_nh_hit;
        }
        size = ecmp_groups_table_size;
        implementation = ecmp_selector;
        counters = ecmp_groups_cntr;
    }

    action passthrough_send_to_host(port_id_t cpu_port) {
        hdr.dp_ctrl_hdr.setValid();
        /* We select the ring id from a pool of ring ids (0-3), based on the
         * flow hash. This helps in improving the throughput and also won't
         * cause any packet re-ordering. The ring ids 4-7 are reserved for
         * other send to cpu actions.
         */
        hdr.dp_ctrl_hdr.ring_id[1:0] = (bit<2>)fabric_meta.flow_hash;
        hdr.dp_ctrl_hdr.etherType = ETHERTYPE_DP_CTRL;
        hdr.dp_ctrl_hdr.port = (bit<16>)ig_intr_md.ingress_port;
        ig_tm_md.ucast_egress_port = cpu_port;
        ig_tm_md.bypass_egress = 1;
        exit;
    }

    action passthrough_miss() {}

    /* passthrough table is used to punt packets destined to the CP hostdev IP.
     * These packets are sent on the sw1pXsY interface that corresponds to the
     * ingress port on which the packet was received.
     */
    table passthrough {
        key = {
            fabric_meta.lkp_ipv6_addr : exact;
        }
        actions = {
            passthrough_send_to_host;
            passthrough_miss;
        }
        size = 2;
        default_action = passthrough_miss();
    }

    apply {
        if (fabric_meta.routing_lkp_flag == 1) {
            if (fabric_meta.passthrough == 1) {
                passthrough.apply();
            }
            switch(routing_ipv6.apply().action_run) {
                routing_ecmp : {
                    switch(ecmp_groups.apply().action_run) {
                        ecmp_routing_nh_hit : {
                            neighbor.apply();
                        }
                    }
                }
                routing_dcn_hit :
                routing_nh_hit : {
                    neighbor.apply();
                }
            }
        }
    }
}

/* l2_egress table maps the output port to its MAC address.
 * The source mac of outgoing packets is updated with the resulting MAC addr.
 */
control L2Egress(
        inout egress_header_t hdr,
        inout egress_metadata_t eg_md,
        in egress_intrinsic_metadata_t eg_intr_md,
        inout egress_intrinsic_metadata_for_deparser_t eg_dprsr_md)(
        bit<32> l2_egress_table_size) {

    DirectCounter<bit<32>>(CounterType_t.PACKETS) l2_egress_cntr;

    action l2_egress_hit(mac_addr_t iface_mac) {
        l2_egress_cntr.count();
        hdr.ethernet.srcAddr = iface_mac;
    }

    action l2_egress_miss() {
        l2_egress_cntr.count();
        eg_dprsr_md.drop_ctl = DROP_CTL_ALL;
        exit;
    }

    @ternary(1)
    table l2_egress {
        key = {
            eg_intr_md.egress_port : exact;
        }
        actions = {
            l2_egress_hit;
            l2_egress_miss;
        }
        const default_action = l2_egress_miss();
        size = l2_egress_table_size;
        counters = l2_egress_cntr;
    }

    apply {
        l2_egress.apply();
        if (hdr.bridged_md.ingress_port != eg_md.fabric_meta.cpu_port) {
            /* Do not decrement when packet originates from
             * the host
             */
            hdr.ipv6.hopLimit = hdr.ipv6.hopLimit - 1;
        }
    }
}

control CopyNexthopMAC(
        inout egress_header_t hdr,
        in eg_fabric_metadata_t fabric_meta) (
        bit<32> neighbor_table_size) {

    action set_neigh_mac_hit(mac_addr_t mac_addr) {
        hdr.ethernet.dstAddr = mac_addr;
    }

    action set_neigh_mac_miss() {}

    /* Set_neigh_mac table is used for mapping the Neighbor MAC ID address to its
     * MAC address in the underlay.
     * Today, with the current assumptions like fabric topology and the current hardware
     * and number of ports and links between spines and leaf switches, a MAC neighbors
     * table of 256 entries and a MAC ID of 8 bits is enough.
     * However, if the current assumptions change then we will be able to scale by
     * incresing the MAC ID size and set_neigh_mac table size.
     * Set_neigh_mac table is placed in stage 10, which is almost fully used because
     * of the port_failover and lag_failover tables being also placed in stage 10.
     * Therefore, we are placing the key in the TCAM via the @ternary annotation for
     * most of the tables in stage 10 to leave more SRAM blocks available for scaling.
     */
    @ternary(1)
    table set_neigh_mac {
        key = {
            fabric_meta.neigh_mac : exact;
        }
        actions = {
            set_neigh_mac_hit;
            set_neigh_mac_miss;
        }
        default_action = set_neigh_mac_miss();
        size = neighbor_table_size;
    }

    apply {
        set_neigh_mac.apply();
    }
}

control EgressDrop(
        in egress_header_t hdr,
        inout egress_intrinsic_metadata_for_deparser_t eg_dprsr_md) {

    action drop_packet() {
        eg_dprsr_md.drop_ctl = DROP_CTL_ALL;
        exit;
    }

    apply {
        if (hdr.ipv6.hopLimit == 0) {
            drop_packet();
        }
    }
}
# 31 "leaf.p4" 2
# 1 "core/modules/qos.p4" 1
/****************************************************************
 * Copyright (c) Kaloom, 2020
 *
 * This unpublished material is property of Kaloom Inc.
 * All rights reserved.
 * Reproduction or distribution, in whole or in part, is
 * forbidden except by express written permission of Kaloom Inc.
 ****************************************************************/




typedef bit<3> icos_t;



typedef bit<5> qid_t;


/* Control Plane Policing traffic classification. */
control CoppFlowClassification(
        in ingress_header_t hdr,
        inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm)
        (bit<32> copp_flow_table_size) {

    DirectCounter<bit<32>>(CounterType_t.PACKETS) copp_flow_cntr;

    action copp_flow_hit(icos_t icos, qid_t qid) {
        copp_flow_cntr.count();
        ig_intr_md_for_tm.ingress_cos = icos;
        ig_intr_md_for_tm.qid = qid;
    }

    action copp_flow_miss() {
        copp_flow_cntr.count();
    }

    /* Identify traffic flows that are relevant for CoPP.
     *  1- Base fabric traffic  : KNF header is not valid.
     *  2- Fcn0 control traffic : KNF header is valid and the KNID of fcn0 is
     *  set by the control plane.
     */
    table copp_flow {
        key = {
            hdr.knf.isValid() : ternary;
            hdr.knf.knid : ternary;
        }
        actions = {
            copp_flow_hit;
            copp_flow_miss;
        }
        const default_action = copp_flow_miss();
        size = copp_flow_table_size;
        counters = copp_flow_cntr;
    }

    apply {
        copp_flow.apply();
    }
}
# 32 "leaf.p4" 2
# 1 "core/modules/port_failover.p4" 1
/****************************************************************
 * Copyright (c) Kaloom, 2019
 *
 * This unpublished material is property of Kaloom Inc.
 * All rights reserved.
 * Reproduction or distribution, in whole or in part, is
 * forbidden except by express written permission of Kaloom Inc.
 ****************************************************************/
# 33 "leaf.p4" 2
# 1 "core/modules/replication.p4" 1
/****************************************************************
 * Copyright (c) Kaloom, 2019
 *
 * This unpublished material is property of Kaloom Inc.
 * All rights reserved.
 * Reproduction or distribution, in whole or in part, is
 * forbidden except by express written permission of Kaloom Inc.
 ****************************************************************/




control IngressReplication(
        inout ingress_header_t hdr,
        inout ingress_metadata_t ig_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm,
        inout ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md)() {

    Hash<bit<16>>(HashAlgorithm_t.CRC16) mcast_hash_l1;
    Hash<bit<16>>(HashAlgorithm_t.CRC16) mcast_hash_l2;
    DirectCounter<bit<32>>(CounterType_t.PACKETS) bcast_cntr;

    action compute_level1_hash() {
        ig_intr_md_for_tm.level1_mcast_hash = (bit<13>)mcast_hash_l1.get({
            ig_md.fabric_meta.flow_hash,
            ig_md.ktep_meta.src_mac,
            ig_md.ktep_meta.dst_mac,
            ig_md.ktep_meta.ingress_vlan_id,
            hdr.vlan.etherType});
    }

    action compute_level2_hash() {
        ig_intr_md_for_tm.level2_mcast_hash = (bit<13>)mcast_hash_l2.get({
            ig_md.ktep_meta.src_mac,
            ig_md.ktep_meta.dst_mac});
    }

    action rate_limit_bcast_hit() {
        bcast_cntr.count();
        ig_dprsr_md.drop_ctl = DROP_CTL_ALL;
        exit;
    }

    action rate_limit_unknown_mac_hit() {
        bcast_cntr.count();
        ig_dprsr_md.drop_ctl = DROP_CTL_ALL;
        exit;
    }

    action dont_rate_limit_mcast_hit() {
        bcast_cntr.count();
    }

    /* Depending on the type of BUM traffic to be replicated, this table will
     * rate limit broadcast and unknown MAC traffic to avoid overwhelming the
     * TM/PRE but will not rate limit multicast traffic.
     * Therefore, we also implemented a meter in egress pipeline to rate limit
     * multicast traffic towards the vRouter punt channel.
     */
    table rate_limit_bcast {
        key = {
            ig_md.ktep_meta.mcast_pkt_color : exact;
            ig_md.ktep_meta.dst_mac : ternary;
        }
        actions = {
            rate_limit_bcast_hit;
            rate_limit_unknown_mac_hit;
            dont_rate_limit_mcast_hit;

        }
        // TODO: For some reason the second entry does not get added with the right mask.
        // const entries = {
        //     (MeterColor_t.RED, 0xffffffffffff & 0xffffffffffff) : rate_limit_bcast_hit();
        //     (MeterColor_t.RED, 0x010000000000 & 0x010000000000) : dont_rate_limit_mcast_hit();
        //     (MeterColor_t.RED, _) : rate_limit_unknown_mac_hit();
        // }
        size = 3;
        counters = bcast_cntr;
    }

    apply {
        rate_limit_bcast.apply();
        compute_level1_hash();
        compute_level2_hash();
    }
}

control ReplicatedPackets(
        inout egress_header_t hdr,
        inout egress_metadata_t eg_md,
        in egress_intrinsic_metadata_t eg_intr_md,
        inout egress_intrinsic_metadata_for_deparser_t eg_dprsr_md)
        (bit<32> rid_table_size,
        bit<32> egress_ports_table_size) {

    Meter<meter_index_t>(4096, MeterType_t.BYTES) punt_meter;
    DirectCounter<bit<32>>(CounterType_t.PACKETS) rid_cntr;

    /* Drop replica if it is being sent on the same port with the same vlan. */
    action drop_packet() {
        eg_dprsr_md.drop_ctl = DROP_CTL_ALL;
        exit;
    }

    /* Packet is sent to a local port or a LAG without a vlan tag (untagged) */
    action rid_iface_untagged_hit() {
        rid_cntr.count();
        /* The vland ID used to identify the untagged packets is 0 while 4096
         * is used as its corresponding RID value.
         */
        eg_md.ktep_meta.egress_vlan_id = 0;
    }

    /* Packet is sent to a local port or a LAG with a vlan tag */
    action rid_iface_vlan_hit() {
        rid_cntr.count();
        eg_md.ktep_meta.egress_vlan_id = (bit<12>)eg_intr_md.egress_rid;
        eg_md.ktep_meta.egress_pkt_type = PKT_TYPE_VLAN;
    }

    /* Packet is sent to a remote leaf */
    action rid_remote_leaf_hit(dest_id_t remote_leaf_id) {
        rid_cntr.count();
        eg_md.ktep_meta.dest_id = remote_leaf_id;
        eg_md.ktep_meta.egress_pkt_type = PKT_TYPE_KNF;
        eg_md.fabric_meta.l2_egress_lkp_flag = 1;
    }

    /* Packet is sent to a remote IP on a punt KNID */
    action rid_punt_channel_hit(dest_id_t punt_dest_id, nw_id_t p_nw_id, meter_index_t index) {
        eg_md.ktep_router_meta.meter_color = (MeterColor_t) punt_meter.execute(index);
        eg_md.ktep_meta.nw_id = p_nw_id;
        rid_remote_leaf_hit(punt_dest_id);
    }

    /* Packet is sent to a remote vtep via a local router */
    action rid_remote_vtep_local_router_hit(tunnel_id_t kvtep_id,
            remote_vtep_id_t remote_vtep_id) {
        rid_cntr.count();
        eg_md.tunnel_meta.tunnel_id = kvtep_id;
        eg_md.tunnel_meta.remote_vtep_id = remote_vtep_id;
        eg_md.tunnel_meta.process_egress = 1;
        eg_md.tunnel_meta.egress_pkt_type = TUNNEL_PKT_TYPE_VXLAN;

        eg_md.ktep_meta.dest_id = 1;
        eg_md.ktep_meta.egress_pkt_type = PKT_TYPE_KNF;

        eg_md.fabric_meta.l2_egress_lkp_flag = 0;
    }

    /* Packet is sent to a remote vtep via a remote router */
    action rid_remote_vtep_remote_router_hit(tunnel_id_t kvtep_id,
            remote_vtep_id_t remote_vtep_id, dest_id_t kvtep_leaf_id) {
        rid_cntr.count();
        eg_md.tunnel_meta.tunnel_id = kvtep_id;
        eg_md.tunnel_meta.remote_vtep_id = remote_vtep_id;
        eg_md.tunnel_meta.process_egress = 1;
        eg_md.tunnel_meta.egress_pkt_type = TUNNEL_PKT_TYPE_VXLAN;

        eg_md.ktep_meta.dest_id = kvtep_leaf_id;
        eg_md.ktep_meta.egress_pkt_type = PKT_TYPE_KNF;

        eg_md.fabric_meta.l2_egress_lkp_flag = 1;
    }

    /* Packet is sent to a remote ICL peer leaf */
    action rid_remote_icl_hit(iface_id_t remote_lag_id) {
        rid_cntr.count();
        eg_md.ktep_meta.egress_pkt_type = PKT_TYPE_KNF;
        eg_md.fabric_meta.l2_egress_lkp_flag = 1;
        eg_md.ktep_meta.remote_lag_id = remote_lag_id;
        eg_md.ktep_meta.dest_id = 2;
    }

    /* Unknown RID. Drop packet */
    action rid_miss() {
        rid_cntr.count();
        drop_packet();
    }

    /* The RID table uses the replication ID (RID) to figure out how to modify
     * the packet before sending it out.
     *
     *     RID            Action
     *      0             not a replicated packet
     *    1 - 4095        vlan packet -> vlan_id = rid (add vlan tag if needed)
     *     4096           untagged packet -> remove vlan tag if it exists
     * 4097 - 65535       remote leaf, remote vtep or punt tunnel packet -> RID
     *                    maps to remote IP
     */
    table rid {
        key = {
            eg_intr_md.egress_rid : exact;
        }
        actions = {
            rid_iface_untagged_hit;
            rid_iface_vlan_hit;
            rid_remote_leaf_hit;
            rid_punt_channel_hit;
            rid_remote_icl_hit;
            rid_remote_vtep_local_router_hit;
            rid_remote_vtep_remote_router_hit;
            rid_miss;
        }
        const default_action = rid_miss;
        size = rid_table_size;
        counters = rid_cntr;
    }

    action kvs_egress_hit() {
        eg_md.ktep_meta.egress_pkt_type = PKT_TYPE_KNF;
        eg_md.fabric_meta.l2_egress_lkp_flag = 1;
        eg_md.ktep_meta.send_to_kvs = 1;
    }

    action kvs_egress_miss() {
        eg_md.ktep_meta.egress_pkt_type = PKT_TYPE_UNTAGGED;
    }

    /* Checks if the egress port corresponts to a KVS then sets the corresponding flags */
    table kvs_egress {
        key = {
            eg_intr_md.egress_port : exact;
        }
        actions = {
            kvs_egress_hit;
            kvs_egress_miss;
        }
        const default_action = kvs_egress_miss;
        size = egress_ports_table_size;
    }

    action set_iface_id_hit(iface_id_t iface_id) {
        eg_md.ktep_meta.egress_iface_id = iface_id;
    }

    action set_iface_id_miss() {}

   /* Map the egress port to the egress iface id.
    * BUM packets replicated by the PRE would have the egress_port set
    * but not the iface id. Without iface id, tables like vnet_egress
    * would be missed. This is not catastrophic for the traffic but
    * important information like stats would be missed.
    * This table is an inverse of the egress_ports table.
    */
    table set_egress_iface_id {
        key = {
            eg_intr_md.egress_port: exact;
        }
        actions = {
            set_iface_id_hit;
            set_iface_id_miss;
        }
        size = egress_ports_table_size;
        const default_action = set_iface_id_miss;
    }

    apply {
        if (eg_intr_md.egress_rid != 0) {
            set_egress_iface_id.apply();
            switch (rid.apply().action_run) {
                rid_iface_untagged_hit : {
                    kvs_egress.apply();
                }
                rid_remote_vtep_remote_router_hit :
                rid_remote_vtep_local_router_hit : {
                    if ((eg_md.ktep_meta.pkt_src == KTEP_SRC_LEAF) &&
                            (eg_md.ktep_meta.received_on_punt_channel == 0)) {
                        drop_packet();
                    }
                }
                rid_punt_channel_hit : {
                    /* Packets arriving from the fabric on Hostdev IP sould not
                     * send a replica to the vRouter CP. However, packets arriving
                     * on a user port or a KVS port that need broadcasting must send
                     * a copy to the punt channels.
                     * FIXME: this condition would be much simpler if expressed
                     * with (eg_md.ktep_port_meta.port_type == PORT_TYPE_FABRIC
                     * && eg_md.ktep_router_meta.router_id == 0) but the compiler
                     * reported PHV allocation was not successful.
                     */
                    if (eg_md.ktep_router_meta.router_id == 0 &&
                            eg_md.ktep_meta.knf_tunnel_terminated == 1 &&
                            eg_md.ktep_meta.is_from_kvs == 0) {
                        drop_packet();
                    }
                }
            }
        }
    }
}

control ReplicaCopyMac(
        inout egress_header_t hdr,
        in egress_intrinsic_metadata_t eg_intr_md,
        inout egress_intrinsic_metadata_for_deparser_t eg_dprsr_md)
        (bit<32> nexthop_table_size) {

    action set_nexthop_mac(mac_addr_t nh_mac) {
        hdr.ethernet.dstAddr = nh_mac;
    }

    action nexthop_mac_miss() {
        eg_dprsr_md.drop_ctl = DROP_CTL_ALL;
        exit;
    }

    /* Set the MAC address of the NextHop in the Egress pipeline for replicated
     * packets.
     */
     @ternary(1)
    table nexthop_mac {
        key = {
            eg_intr_md.egress_port : exact;
        }
        actions = {
            set_nexthop_mac;
            nexthop_mac_miss;
        }
        const default_action = nexthop_mac_miss;
        size = nexthop_table_size;
    }

    apply {
        nexthop_mac.apply();
    }
}
# 34 "leaf.p4" 2
# 1 "core/modules/knf_tunnel.p4" 1
/****************************************************************
 * Copyright (c) Kaloom, 2019
 *
 * This unpublished material is property of Kaloom Inc.
 * All rights reserved.
 * Reproduction or distribution, in whole or in part, is
 * forbidden except by express written permission of Kaloom Inc.
 ****************************************************************/




control LocalIfaceDecap(
        inout ingress_header_t hdr,
        inout ingress_metadata_t ig_md) () {

    action vlan_ipv4_hit() {
        hdr.inner_ethernet.etherType = ETHERTYPE_VLAN;
        hdr.vlan.etherType = ETHERTYPE_IPV4;
    }

    action vlan_ipv6_hit() {
        hdr.inner_ethernet.etherType = ETHERTYPE_VLAN;
        hdr.vlan.etherType = ETHERTYPE_IPV6;
    }

    action ipv4_hit() {
        hdr.inner_ethernet.etherType = ETHERTYPE_IPV4;
    }

    action ipv6_hit() {
        hdr.inner_ethernet.etherType = ETHERTYPE_IPV6;
    }

    table mpls_decap_ethertype_update {
        key = {
            hdr.vlan.isValid() : exact;
            hdr.inner_ipv4.isValid() : exact;
            hdr.inner_ipv6.isValid() : exact;
        }
        actions = {
            vlan_ipv4_hit;
            vlan_ipv6_hit;
            ipv4_hit;
            ipv6_hit;
        }
        size = 8;
        const entries = {
            (true, true, false) : vlan_ipv4_hit();
            (true, false, true) : vlan_ipv6_hit();
            (false, true, false) : ipv4_hit();
            (false, false, true) : ipv6_hit();
        }
    }

    apply {
        if (ig_md.ktep_meta.egress_pkt_type != PKT_TYPE_KNF &&
                ig_md.ktep_router_meta.mpls_decap == 1) {
            /* Pop MPLS header. */
            hdr.mpls.setInvalid();
            mpls_decap_ethertype_update.apply();
        }
    }
}

control KnfEncap(
        inout egress_header_t hdr,
        inout egress_metadata_t eg_md,
        in egress_intrinsic_metadata_t eg_intr_md,
        inout egress_intrinsic_metadata_for_deparser_t eg_dprsr_md)() {

    // action ktep_prepare_remove_qinq() {
    //     hdr.udp.hdrLen = hdr.udp.hdrLen - 4;
    //     hdr.ipv6.payloadLen = hdr.ipv6.payloadLen - 4;
    //     eg_md.ktep_meta.payload_length = eg_md.ktep_meta.payload_length - 4;
    // }

    /* Perform KNF encapsulation */
    action knf_encap() {
        hdr.ethernet.setValid();
        hdr.ipv6.setValid();
        hdr.udp.setValid();
        hdr.knf.setValid();
        /* Set ethernet ethertype */
        hdr.ethernet.etherType = ETHERTYPE_IPV6;
        /* Create KNF IPv6 header */
        hdr.ipv6.version = IPV6_VERSION;
        hdr.ipv6.nextHdr = UDP_PROTO;
        hdr.ipv6.hopLimit = HOP_LIMIT;
        /* In case of flow_hash > 16 bit, for e.g in case of 32 bit flow_hash while using
         * custom CRC polynomial, we can't assign to 16 bit srcPort, without casting.
         */
        hdr.udp.srcPort = (bit<16>)eg_md.fabric_meta.flow_hash;
        hdr.udp.dstPort = KNF_UDP_DST_PORT;

        hdr.knf.telSequenceNum = eg_md.tel_metadata.seq_num;

        eg_md.ktep_meta.payload_length = eg_md.ktep_meta.payload_length + UDP_SIZE + KNF_SIZE;
    }

    action adjust_packet_lengths() {
        hdr.ipv6.payloadLen = eg_md.ktep_meta.payload_length;
        hdr.udp.hdrLen = eg_md.ktep_meta.payload_length;
    }

    apply {
        knf_encap();
        adjust_packet_lengths();
        // if (hdr.vlan.isValid() &&
        //         eg_md.ktep_meta.ingress_pkt_type != PKT_TYPE_QINQ) {
        // else if (eg_md.ktep_meta.ingress_pkt_type == PKT_TYPE_QINQ) {
        //     ktep_prepare_remove_qinq();
        // }
    }
}

control KnfRewrite(
        inout egress_header_t hdr,
        inout egress_metadata_t eg_md,
        inout eg_ktep_metadata_t ktep_meta,
        in egress_intrinsic_metadata_t eg_intr_md,
        inout egress_intrinsic_metadata_for_deparser_t eg_dprsr_md)
        (bit<32> knids_table_size,
         bit<32> knf_set_knid_vxlan_table_size,
         bit<32> knf_rewrite_table_size,
         bit<32> kvs_knf_rewrite_table_size,
         bit<32> dest_ipv6_table_size) {

    action knf_set_knid_(knid_t knid) {
        hdr.knf.knid = knid;
    }

    action knf_set_knid_miss() {}

    table knf_set_knid {
        key = {
            ktep_meta.nw_id : exact;
        }
        actions = {
            knf_set_knid_;
            knf_set_knid_miss;
        }
        const default_action = knf_set_knid_miss();
        size = knids_table_size;
    }

    /* This table is used to set v-KNID for VxLAN towards remote VTEP.
     * We can't use knf_set_knid table as "ktep_meta.nw_id" has been
     * used for overlay nw_id (of o-KNID) to deduce VNI.
     * Having both o_nw_id and v_nw_id causes PHV allocation problem.
     * Moreover tunnel_id and v-KNID is one-to-one mapping.
     */
    table knf_set_knid_vxlan {
        key = {
            eg_md.tunnel_meta.tunnel_id : exact;
        }
        actions = {
            knf_set_knid_;
            knf_set_knid_miss;
        }
        const default_action = knf_set_knid_miss();
        size = knf_set_knid_vxlan_table_size;
    }

    action knf_rewrite_(ipv6_addr_t ipv6_src) {
        hdr.ipv6.srcAddr = ipv6_src;
        eg_md.ktep_meta.payload_length = hdr.udp.hdrLen;

        /* Set remote LAG ID. It will only be non-zero in the case where the
         * packet is sent on the ICL.
         */
        hdr.knf.remoteLagID = (bit<16>)eg_md.ktep_meta.remote_lag_id;
    }

    /* Rewrite KNF source IP.
     * The default action should be to set the source IP address of the KNF
     * packet to the hostdev of the leaf. However, in the case of a packet
     * coming from a KVS or a LAG, the source IP will be the KVS/LAG's fabric
     * IP (often referred to as fd06 address).
     *
     * The most significant bit of the OEType indicates whether the packet is
     * being sent on a punt channel. Packets on a punt channel always use the
     * IP address of the leaf as their source even if they come from a LAG or
     * KVS.
     */
    @ternary(1)
    table knf_rewrite {
        key = {
            hdr.knf.knid[55:55] : exact @name("hdr.knf.knid");
            ktep_meta.ingress_iface_id : exact;
        }
        actions = {
            knf_rewrite_;
        }
        size = knf_rewrite_table_size;
    }

    action knf_set_dest_ip_(ipv6_addr_t ip) {
        hdr.ipv6.dstAddr = ip;
    }

    action knf_set_dest_ip_miss() {}

    /* Set the destination IP address to the knf packet using the dest_id metadata */
    /* TODO: Workaround for Barefoot case 7934 @pragma pack 2 && @pragma ways 2 */
    table knf_set_dest_ip {
        key = {
            ktep_meta.dest_id : exact;
        }
        actions = {
            knf_set_dest_ip_;
            knf_set_dest_ip_miss;
        }
        const default_action = knf_set_dest_ip_miss();
        size = dest_ipv6_table_size;
    }

    /* Action for packets being sent to a KVS. In this case, the link-local IP
     * addresses are used.
     */
    action kvs_knf_rewrite_hit(mac_addr_t dst_mac, ipv6_addr_t dst_ip,
            ipv6_addr_t src_ip) {
        hdr.ethernet.dstAddr = dst_mac;
        hdr.ipv6.srcAddr = src_ip;
        hdr.ipv6.dstAddr = dst_ip;
        eg_md.ktep_meta.payload_length = hdr.udp.hdrLen;
        hdr.knf.remoteLagID = 0;
    }

    /* Cannot sent to KVS if the link-local IPs are not known */
    action kvs_knf_rewrite_miss() {
        /* TODO: Ideally, packets that hit this action should be dropped but it
         * does not compile.
         * eg_dprsr_md.drop_ctl = DROP_CTL_ALL;
         */
    }

    table kvs_knf_rewrite {
        key = {
            eg_intr_md.egress_port : exact;
        }
        actions = {
            kvs_knf_rewrite_hit;
            kvs_knf_rewrite_miss;
        }
        const default_action = kvs_knf_rewrite_miss();
        size = kvs_knf_rewrite_table_size;
    }

    apply {
        if (eg_md.tunnel_meta.egress_pkt_type == TUNNEL_PKT_TYPE_VXLAN) {
            knf_set_knid_vxlan.apply();
        } else {
            knf_set_knid.apply();
        }
        if (eg_md.ktep_meta.process_l3 == 1 &&
                hdr.mpls.isValid() &&
                eg_md.ktep_router_meta.mpls_decap == 0) {
            hdr.udp.hdrLen = hdr.udp.hdrLen + MPLS_SIZE;
            hdr.ipv6.payloadLen = hdr.ipv6.payloadLen + MPLS_SIZE;
        }
        if (ktep_meta.send_to_kvs == 1) {
            kvs_knf_rewrite.apply();
        } else {
            knf_rewrite.apply();
            knf_set_dest_ip.apply();
        }
    }
}
# 35 "leaf.p4" 2
# 1 "core/modules/tel_watchlist.p4" 1
/****************************************************************
 * Copyright (c) Kaloom, 2019
 *
 * This unpublished material is property of Kaloom Inc.
 * All rights reserved.
 * Reproduction or distribution, in whole or in part, is
 * forbidden except by express written permission of Kaloom Inc.
 ****************************************************************/




control INTGenerateRandVal(
        inout ingress_metadata_t ig_md) () {

    Random<bit<16>>() rand_val;

    /* Calculates a random hash value to be used in the sampling decision
     * in postcard_watch_sample() action.
     */
    action compute_rand_val() {
        ig_md.tel_metadata.tel_hash = rand_val.get();
    }

    apply {
        compute_rand_val();
    }
}

/* Apply postcard watchlist, on Leaf switches only, to define the traffic that
 * will be monitored.
 */
control Watchlist(
        inout ingress_header_t hdr,
        inout ingress_metadata_t ig_md,
        in ingress_intrinsic_metadata_t ig_intr_md,
        inout ig_ktep_port_metadata_t ktep_port_meta)
        (bit<32> postcard_watchlist_table_size) {

    DirectCounter<bit<32>>(CounterType_t.PACKETS) postcard_watchlist_cntr;

    /* switch.p4 uses 4096 register (1 sram block).
     * However we only need 101 registers to represent all the possibilities
     * between 0 to 100%.
     */
    const bit<32> tel_postcard_reg_instance_count = 101;

    /* Sampling registers are filled by the control plane to represent the
     * possibility of having a hash value lower than x value by setting
     * the register value to: (uint16_t)(0xFFFFLL * (i / 100.0)),
     * where i = 0..100.
     */
    Register<bit<16>, bit<32>>(tel_postcard_reg_instance_count)
        tel_postcard_sample_rate;

    RegisterAction<bit<16>, bit<32>, bit<1>>(tel_postcard_sample_rate)
            tel_postcard_sample_rate_action = {
        void apply(inout bit<16> val, out bit<1> rv) {
            if (ig_md.tel_metadata.tel_hash <= val) {
                rv = 1;
            } else {
                rv = 0;
            }
        }
    };

    /* This action is necessary because the python PD client used in the PTF
     * tests can't set up a register that has index higher than 50.
     */
    action postcard_watch_all(int_rule_id_t rule_id) {
        postcard_watchlist_cntr.count();
        ig_md.tel_metadata.generate_postcard = 1;
        ig_md.tel_metadata.watchlist_hit = 1;
        ig_md.tel_metadata.rule_id = rule_id;
    }

    /* 100% for all packets of matched flow, use postcard_not_watch for 0%.
     * sample_index i keeps percent i.
     */
    action postcard_watch_sample(bit<32> sample_index, int_rule_id_t rule_id) {
        postcard_watchlist_cntr.count();
        /* Execute Register action to update "tel_metadata.generate_postcard" */
        ig_md.tel_metadata.generate_postcard = tel_postcard_sample_rate_action.execute(sample_index);
        ig_md.tel_metadata.watchlist_hit = 1;
        ig_md.tel_metadata.rule_id = rule_id;
    }

    /* Telemetry bit must be explicitly cleared. Otherwise, tel_postcard_e2e_hit
     * gets executed generating postcard continously.
     */
    action postcard_not_watch() {
        postcard_watchlist_cntr.count();
        ig_md.tel_metadata.watchlist_hit = 0;
        ig_md.tel_metadata.generate_postcard = 0;
        ig_md.tel_metadata.rule_id = 0;
    }

    table postcard_watchlist {
        key = {
            ig_intr_md.ingress_port : ternary;
            hdr.inner_ethernet.etherType : ternary;
            hdr.inner_ipv6.isValid() : ternary;
            hdr.inner_ipv6.srcAddr : ternary;
            hdr.inner_ipv6.dstAddr : ternary;
            hdr.inner_ipv6.nextHdr : ternary;
            hdr.inner_ipv4.isValid() : ternary;
            hdr.inner_ipv4.srcAddr : ternary;
            hdr.inner_ipv4.dstAddr : ternary;
            hdr.inner_ipv4.protocol : ternary;
            hdr.inner_udp.isValid() : ternary;
            hdr.inner_udp.srcPort : ternary;
            hdr.inner_udp.dstPort : ternary;
        }
        actions = {
            postcard_watch_all;
            postcard_watch_sample;
            postcard_not_watch;
        }
        const default_action = postcard_not_watch;
        size = postcard_watchlist_table_size;
        counters = postcard_watchlist_cntr;
    }

    action set_knf_telemetry_valid() {
        ig_md.tel_metadata.generate_postcard = 1;
        ig_md.tel_metadata.seq_num = hdr.knf.telSequenceNum;
        /* Setting the rule id to be zero, as the forwarded packet (after hitting the filter)
         * will not have the rule_id and hence will be set explicitly to zero
         */
        // ig_md.tel_metadata.rule_id = 0;
    }

    apply {
        /* Apply watchlist table only on USER and KVS Ports */
        if (ig_md.ktep_port_meta.port_type == PORT_TYPE_USER
                || ig_md.ktep_port_meta.port_type == PORT_TYPE_KVS) {
            postcard_watchlist.apply();
        } else if (ig_md.ktep_port_meta.port_type == PORT_TYPE_FABRIC &&
                (hdr.knf.isValid() || ig_md.ktep_meta.knf_tunnel_terminated == 1) &&
                hdr.knf.telSequenceNum != 0) {
            /* If KNF header is valid or KNF was decapsulated and knf.telSequenceNum
             * is set, then use it as the postcard sequence number, don't
             * generate new number.
             */
            set_knf_telemetry_valid();
        }
    }
}

/* Generate sequence number for telemetry */
control TelGenerateSequenceNum(
        inout egress_header_t hdr,
        inout eg_tel_metadata_t tel_metadata) {

    /* This Register keeps track of the telemetry sequence number. It simply
     * decrements by one every time a sequence number is generated. Zero is an
     * invalid sequence num. Decrement is used (rather than an increment) since
     * matching on -1 is not supported (Barefoot Case #8532).
     */
    const bit<32> tel_sequence_num_register_instance_count = 1;
    Register<bit<8>, bit<1>>(tel_sequence_num_register_instance_count, 0) tel_sequence_num_register;
    RegisterAction<bit<8>, bit<1>, bit<8>>(tel_sequence_num_register) prog_tel_sequence_num = {
        void apply(inout bit<8> val, out bit<8> rv) {
            if (val == 1) {
                val = 0xff;
            } else {
                val = val - 1;
            }
            rv = val;
        }
    };

    action tel_sequence_num() {
        hdr.knf.telSequenceNum = prog_tel_sequence_num.execute(0);
    }

    apply {
        if ((tel_metadata.generate_postcard == 1)
                && (tel_metadata.watchlist_hit == 1)) {
            tel_sequence_num();
        }
    }
}
# 36 "leaf.p4" 2
# 1 "core/modules/tel_postcard.p4" 1
/****************************************************************
 * Copyright (c) Kaloom, 2019
 *
 * This unpublished material is property of Kaloom Inc.
 * All rights reserved.
 * Reproduction or distribution, in whole or in part, is
 * forbidden except by express written permission of Kaloom Inc.
 ****************************************************************/




const mirror_id_t INT_MIRROR_SESSION_ID = 0x1;

/* Perform packet mirroring to be used as postcard report */
control TelE2EMirror(
        inout egress_header_t hdr,
        inout eg_tel_metadata_t tel_metadata,
        inout egress_metadata_t eg_md,
        in egress_intrinsic_metadata_t eg_intr_md,
        in egress_intrinsic_metadata_from_parser_t eg_prsr_md,
        inout egress_intrinsic_metadata_for_deparser_t eg_dprsr_md) {

    action mirror_packet() {
        eg_md.mirror = {
            SWITCH_PKT_SRC_CLONE_EGRESS,
            INT_MIRROR_SESSION_ID,
            eg_md.ingress_port,
            eg_intr_md.egress_port,
            eg_intr_md.egress_qid,
            eg_intr_md.enq_qdepth,
            hdr.bridged_md.ingress_tstamp,
            eg_prsr_md.global_tstamp,
            eg_md.tel_metadata.seq_num
            // tel_metadata.rule_id
        };
    }

    /* TODO: @ignore_table_dependency("tel_postcard_insert") */
    action tel_postcard_e2e() {
        eg_dprsr_md.mirror_type = MIRROR_TYPE_E2E;
        mirror_packet();
    }

    apply {
        if (tel_metadata.generate_postcard == 1) {
            tel_postcard_e2e();
        }
    }
}

/* Add telemetry data to the mirrored packet (report) */
control TelGeneratePostcard(
        inout egress_header_t hdr,
        inout eg_tel_metadata_t tel_metadata,
        in eg_mirror_metadata_t mirror,
        in eg_parser_metadata_t eg_intr_md_from_parser_aux, /* Using this name to match P4-14 code */
        in egress_intrinsic_metadata_t eg_intr_md,
        inout egress_intrinsic_metadata_for_deparser_t eg_dprsr_md) {

    DirectCounter<bit<32>>(CounterType_t.PACKETS) tel_postcard_insert_cntr;

    /* Perform KNF encapsulation */
    action postcard_encap_knf(ipv6_addr_t sip, ipv6_addr_t dip, knid_t knid) {
        hdr.ethernet.setValid();
        hdr.ipv6.setValid();
        hdr.udp.setValid();
        hdr.knf.setValid();

        /* smac/dmac are filled after recirc */
        hdr.ethernet.etherType = ETHERTYPE_IPV6;

        /* Create KNF IPv6 header */
        hdr.ipv6.version = IPV6_VERSION;
        hdr.ipv6.nextHdr = UDP_PROTO;
        hdr.ipv6.hopLimit = HOP_LIMIT;
        hdr.ipv6.srcAddr = sip;
        hdr.ipv6.dstAddr = dip;

        hdr.udp.srcPort = 0; //TODO: (bit<16>)eg_md.fabric_meta.flow_hash;
        hdr.udp.dstPort = KNF_UDP_DST_PORT;
        hdr.udp.checksum = 0;

        hdr.knf.telSequenceNum = 0;
        hdr.knf.reserved = 0;
        hdr.knf.remoteLagID = 0;
        hdr.knf.knid = knid;
    }

    action postcard_encap_inner_ethernet(mac_addr_t dmac, mac_addr_t smac) {
        hdr.encap_ethernet.setValid();
        hdr.encap_ethernet.dstAddr = dmac;
        hdr.encap_ethernet.srcAddr = smac;
    }

    action postcard_encap_inner_ipv6(ipv6_addr_t sip, ipv6_addr_t dip) {
        hdr.encap_ipv6.setValid();
        hdr.encap_ipv6.version = IPV6_VERSION;
        hdr.encap_ipv6.nextHdr = UDP_PROTO;
        hdr.encap_ipv6.hopLimit = HOP_LIMIT;
        hdr.encap_ipv6.flowLabel = 0;
        hdr.encap_ipv6.trafficClass = 0;
        hdr.encap_ipv6.payloadLen = eg_intr_md.pkt_length + UDP_SIZE + POSTCARD_SIZE - (bit<16>)sizeInBytes(mirror) - FCS_SIZE;
        hdr.encap_ipv6.srcAddr = sip;
        hdr.encap_ipv6.dstAddr = dip;

        hdr.encap_ethernet.etherType = ETHERTYPE_IPV6;
        bit<16> outer_pkt_len_adjust = UDP_SIZE + KNF_SIZE + ETH_SIZE + IPV6_SIZE + UDP_SIZE + POSTCARD_SIZE - (bit<16>)sizeInBytes(mirror) - FCS_SIZE;
        hdr.ipv6.payloadLen = eg_intr_md.pkt_length + outer_pkt_len_adjust;
        hdr.udp.hdrLen = eg_intr_md.pkt_length + outer_pkt_len_adjust;
    }

    action postcard_encap_inner_ipv4(ipv4_addr_t sip, ipv4_addr_t dip) {
        hdr.encap_ipv4.setValid();
        hdr.encap_ipv4.version = IPV4_VERSION;
        hdr.encap_ipv4.protocol = UDP_PROTO;
        hdr.encap_ipv4.ttl = HOP_LIMIT;
        hdr.encap_ipv4.ihl = 0x5;
        hdr.encap_ipv4.diffserv = 0x0;
        hdr.encap_ipv4.identification = 0x1;
        hdr.encap_ipv4.flags = 0;
        hdr.encap_ipv4.fragOffset = 0;
        hdr.encap_ipv4.totalLen = eg_intr_md.pkt_length + IPV4_SIZE + UDP_SIZE + POSTCARD_SIZE - (bit<16>)sizeInBytes(mirror) - FCS_SIZE;
        hdr.encap_ipv4.srcAddr = sip;
        hdr.encap_ipv4.dstAddr = dip;

        hdr.encap_ethernet.etherType = ETHERTYPE_IPV4;
        bit<16> outer_pkt_len_adjust = UDP_SIZE + KNF_SIZE + ETH_SIZE + IPV4_SIZE + UDP_SIZE + POSTCARD_SIZE - (bit<16>)sizeInBytes(mirror) - FCS_SIZE;
        hdr.ipv6.payloadLen = eg_intr_md.pkt_length + outer_pkt_len_adjust;
        hdr.udp.hdrLen = eg_intr_md.pkt_length + outer_pkt_len_adjust;
    }

    action postcard_encap_inner_udp(bit<16> udp_dport) {
        hdr.encap_udp.setValid();
        bit<16> pkt_len_adjust = UDP_SIZE + POSTCARD_SIZE - (bit<16>)sizeInBytes(mirror) - FCS_SIZE;
        hdr.encap_udp.srcPort = 0;
        hdr.encap_udp.checksum = 0;
        hdr.encap_udp.dstPort = udp_dport;
        hdr.encap_udp.hdrLen = eg_intr_md.pkt_length + pkt_len_adjust;
    }

    action postcard_encap_postcard_hdr(bit<64> switch_id) {
        hdr.postcard_header.setValid();
        hdr.postcard_header.version = POSTCARD_VERSION;
        hdr.postcard_header.sequence_num = mirror.sequence_num;
        hdr.postcard_header.switch_id = switch_id;
        hdr.postcard_header.ingress_port = (bit<16>)mirror.ingress_port;
        hdr.postcard_header.egress_port = (bit<16>)mirror.egress_port;
        hdr.postcard_header.queue_id = (bit<8>)mirror.queue_id;
        hdr.postcard_header.queue_depth = (bit<24>)mirror.queue_depth;
        hdr.postcard_header.ingress_tstamp = mirror.ingress_tstamp;
        hdr.postcard_header.egress_tstamp = mirror.egress_tstamp;
        // hdr.postcard_header.rule_id = (bit<16>)mirror.rule_id;
        hdr.postcard_header.rule_id = 0;
    }

    action postcard_insert(
            ipv6_addr_t outer_sip, ipv6_addr_t outer_dip,
            knid_t knid,
            mac_addr_t inner_dmac, mac_addr_t inner_smac,
            bit<64> switch_id) {

        tel_postcard_insert_cntr.count();
        postcard_encap_postcard_hdr(switch_id);
        postcard_encap_inner_ethernet(inner_dmac, inner_smac);
        postcard_encap_knf(outer_sip, outer_dip, knid);
    }

    action postcard_encap_v6(
            ipv6_addr_t inner_sip, ipv6_addr_t inner_dip,
            bit<16> udp_dport) {

        postcard_encap_inner_ipv6(inner_sip, inner_dip);
        postcard_encap_inner_udp(udp_dport);
    }

    action postcard_encap_v4(
            ipv4_addr_t inner_sip, ipv4_addr_t inner_dip,
            bit<16> udp_dport) {
        postcard_encap_inner_ipv4(inner_sip, inner_dip);
        postcard_encap_inner_udp(udp_dport);

    }

    action tel_postcard_insert_miss() {
        tel_postcard_insert_cntr.count();
        // drop missed cloned/mirrored packets if no collector is configured.
        // mirroring is used only by INT at the moment.
        eg_dprsr_md.drop_ctl = DROP_CTL_ALL;
        exit;
    }

    /* tel_postcard_insert runs on mirrored packets, tel_postcard_e2e runs on
     * original ones.
     */
    /* TODO: @ignore_table_dependency("tel_postcard_e2e") */
    table tel_postcard_insert {
        key = {
            eg_intr_md_from_parser_aux.clone_src : exact;
        }
        actions = {
            postcard_insert;
            tel_postcard_insert_miss;
        }
        const default_action = tel_postcard_insert_miss();
        size = 3;
        counters = tel_postcard_insert_cntr;
    }

    table tel_postcard_encap {
        key = {
            // TODO: Add collector ID as key, when more are supported
            eg_intr_md_from_parser_aux.clone_src : exact;
        }
        actions = {
            postcard_encap_v6;
            postcard_encap_v4;
            NoAction;
        }
        const default_action = NoAction();
        size = 3;
    }

    apply {
        tel_postcard_insert.apply();
        tel_postcard_encap.apply();
    }
}
# 37 "leaf.p4" 2

const bit<16> MSB_MASK = 0x8000;

control SwitchIngress(
        inout ingress_header_t hdr,
        inout ingress_metadata_t ig_md,
        in ingress_intrinsic_metadata_t ig_intr_md,
        in ingress_intrinsic_metadata_from_parser_t ig_prsr_md,
        inout ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm) {

    /* This register array is bound to ECMP entries, which means that for every ECMP
     * entry there is one bit that associated with it. If this bit is 1, which means
     * that this entry is active and ECMP selector considers this entry as a valid
     * nexthop. Otherwise, ECMP selector considers it as invalid entry and avoids it.
     * TODO: Put register instance count to a smaller value once Barefoot case
     * #8948 gets resolved.
     */
    Register<bit<1>, port_failover_reg_index_t>(port_failover_register_instance_count)
            port_failover_reg;

    /* Clears the bit of the register that is bound to ECMP entry.
     * Mapping port_num into a register index is kept in port_failover table.
     * Port_failover table is populated using a callback function that notifies
     * the control plane each time a new entry is added/deleted into
     * ecmp_groups table and the register index bound to it.
     */
    RegisterAction<bit<1>, port_failover_reg_index_t, bit<1>>(port_failover_reg)
            port_failover_register_action = {
        void apply(inout bit<1> val) {
            val = 0;
        }
    };

    /* LAG link failover register and port down action */
    Register<bit<1>, lag_failover_reg_index_t>(lag_failover_reg_instance_count)
            lag_failover_reg;
    RegisterAction<bit<1>, lag_failover_reg_index_t, bit<1>>(lag_failover_reg)
            lag_port_down = {
        void apply(inout bit<1> value) {
            value = 0;
        }
    };

    /* Underlay */
    CPUPort() cpu_port;
    L2Ingress(L2_INGRESS_TABLE_SIZE) l2_ingress;
    FabricRouting(ROUTING_IPV6_TABLE_SIZE, 256,
            ECMP_GROUPS_TABLE_SIZE, ECMP_SELECTION_TABLE_SIZE,
            ECMP_SELECTION_MAX_GROUP_SIZE, port_failover_reg) fabric_routing;
    PortFailover(PORT_FAILOVER_TABLE_SIZE, port_failover_reg,
            port_failover_register_action) port_failover;
    CoppRateLimiting(COPP_DROP_COUNTERS_SIZE) copp_rate_limiting;
    CoppFlowClassification(COPP_FLOW_TABLE_SIZE) copp_flow_classification;

    /* L2 services */
    FlowHash() compute_flow_hash;
    KnfPackets(11264,
        KNF_DST_IP_IS_LOCAL_TABLE_SIZE,
        LAG_TO_VLAN_MAPPING_TABLE_SIZE) knf_packets;
    PuntUserPackets(USER_PUNT_TABLE_SIZE) user_punt;
    VnetMapping(VLAN_TO_VNET_MAPPING_TABLE_SIZE) vnet_mapping;
    VnetLearning(VNET_SMAC_IFACE_TABLE_SIZE) vnet_learning;
    VnetCPU(KNF_LEARN_FLAG_TABLE_SIZE) vnet_cpu;
    VnetExclusion(VROUTER_IFACES_TABLE_SIZE) vnet_exclusion;
    VnetDmac(VNET_DMAC_TABLE_SIZE,
        KNID_TO_MC_GRP_MAPPING_TABLE_SIZE) vnet_dmac;
    LagStateCheck(LAG_STATE_TABLE_SIZE) lag_state_check;
    VnetEgressIfaces(EGRESS_PORTS_TABLE_SIZE,
            LAG_GROUPS_TABLE_SIZE,
            LAG_SELECTION_TABLE_SIZE,
            LAG_SELECTION_MAX_GROUP_SIZE,
            REMOTE_LAGS_TABLE_SIZE, lag_failover_reg) vnet_egress_ifaces;
    LagFailover(LAG_FAILOVER_TABLE_SIZE, lag_failover_reg,
            lag_port_down) lag_failover;
    L1tpDropStats(L1TP_DROP_STATS_TABLE_SIZE) l1tp_drop_stats;
    DestIDMapping(1024) dest_id_mapping;
    LocalIfaceDecap() local_iface_remove_overhead;
    IngressReplication() ingress_replication;

    /* L3 services */
    VRouter(VROUTER_IFACES_TABLE_SIZE, VROUTER_LFIB_TABLE_SIZE)
            process_vrouter_mpls_vxlan;
    VRouterPuntChannel(VROUTER_IFACES_TABLE_SIZE) prepare_vrouter_punt;
    VRouterGreDecap() vrouter_gre_decap;

    /* INT */
    INTGenerateRandVal() int_gen;
    Watchlist(TEL_FLOW_WATCHLIST_TABLE_SIZE) telemetry_watchlist;

    action add_bridged_md() {
        hdr.bridged_md.setValid();
        hdr.bridged_md.src = SWITCH_PKT_SRC_BRIDGE;
        hdr.bridged_md.ingress_port = ig_intr_md.ingress_port;
        hdr.bridged_md.ingress_tstamp = ig_md.ingress_mac_tstamp;

        /* Fabric Metadata */
        hdr.bridged_md.fabric_meta.l2_egress_lkp_flag = ig_md.fabric_meta.l2_egress_lkp_flag;
        hdr.bridged_md.fabric_meta.flow_hash = ig_md.fabric_meta.flow_hash;

        /* Ktep Metadata */
        hdr.bridged_md.ktep_meta.ingress_vlan_id = ig_md.ktep_meta.ingress_vlan_id;
        hdr.bridged_md.ktep_meta.egress_vlan_id = ig_md.ktep_meta.egress_vlan_id;
        hdr.bridged_md.ktep_meta.egress_pkt_type = ig_md.ktep_meta.egress_pkt_type;
        hdr.bridged_md.ktep_meta.process_l2 = ig_md.ktep_meta.process_l2;
        hdr.bridged_md.ktep_meta.process_l3 = ig_md.ktep_meta.process_l3;
        hdr.bridged_md.ktep_meta.dest_id = ig_md.ktep_meta.dest_id;
        hdr.bridged_md.ktep_meta.received_on_punt_channel = ig_md.ktep_meta.received_on_punt_channel;
        hdr.bridged_md.ktep_meta.pkt_src = ig_md.ktep_meta.pkt_src;
        hdr.bridged_md.ktep_meta.nw_id = ig_md.ktep_meta.nw_id;
        hdr.bridged_md.ktep_meta.send_to_kvs = ig_md.ktep_meta.send_to_kvs;
        hdr.bridged_md.ktep_meta.is_from_kvs = ig_md.ktep_meta.is_from_kvs;
        hdr.bridged_md.ktep_meta.ingress_iface_id = ig_md.ktep_meta.ingress_iface_id;
        hdr.bridged_md.ktep_meta.egress_iface_id = ig_md.ktep_meta.egress_iface_id;
        hdr.bridged_md.ktep_meta.pkt_length_offset = ig_md.ktep_meta.pkt_length_offset;
        hdr.bridged_md.ktep_meta.knf_tunnel_terminated = ig_md.ktep_meta.knf_tunnel_terminated;
        hdr.bridged_md.ktep_meta.processing_user_pkt = ig_md.ktep_meta.processing_user_pkt;

        /* Ktep Router Metadata */
        hdr.bridged_md.ktep_router_meta.router_id = ig_md.ktep_router_meta.router_id;
        hdr.bridged_md.ktep_router_meta.output_iface = ig_md.ktep_router_meta.output_iface;
        hdr.bridged_md.ktep_router_meta.dst_mac_id = ig_md.ktep_router_meta.dst_mac_id;
        hdr.bridged_md.ktep_router_meta.process_l2_egress = ig_md.ktep_router_meta.process_l2_egress;
        hdr.bridged_md.ktep_router_meta.mpls_decap = ig_md.ktep_router_meta.mpls_decap;

        /* KVtep Metadata */
        hdr.bridged_md.tunnel_meta.egress_pkt_type = ig_md.tunnel_meta.egress_pkt_type;
        hdr.bridged_md.tunnel_meta.process_egress = ig_md.tunnel_meta.process_egress;
        hdr.bridged_md.tunnel_meta.tunnel_id = ig_md.tunnel_meta.tunnel_id;
        hdr.bridged_md.tunnel_meta.remote_vtep_id = ig_md.tunnel_meta.remote_vtep_id;

        /* Telemetry Metadata */
        hdr.bridged_md.tel_metadata.generate_postcard = ig_md.tel_metadata.generate_postcard;
        hdr.bridged_md.tel_metadata.watchlist_hit = ig_md.tel_metadata.watchlist_hit;
        // hdr.bridged_md.tel_metadata.rule_id = ig_md.tel_metadata.rule_id;
        hdr.bridged_md.tel_metadata.seq_num = ig_md.tel_metadata.seq_num;
    }

    action init_l2_exclusion_id() {
        ig_intr_md_for_tm.level2_exclusion_id = ig_intr_md.ingress_port & 0x7f;
        ig_intr_md_for_tm.level1_exclusion_id = 0;
    }

    action l2_exclusion_id_offset_hit(bit<9> offset) {
        ig_intr_md_for_tm.level2_exclusion_id = ig_intr_md_for_tm.level2_exclusion_id + offset;
    }

    /* Adds an offset based on the pipe ID to the l2_exclusion_id.
     * The l2_exclusion_id is calculated with the following formula:
     *    l2_exclusion_id = local_ingress_port + offset
     * Where the local_ingress_port is the ingress port without the pipe ID
     * (i.e. ingress_port[6:0]). This is set by the init_l2_exclusion_id action.
     * The offset is calculated with the following formula:
     *    offset = pipe_id * 72
     */
    @ternary(1)
    table l2_exclusion_id_offset {
        key = {
            ig_intr_md.ingress_port[8:7] : exact @name("pipe_id");
        }
        actions = {
            l2_exclusion_id_offset_hit;
        }
        /* TODO: const entries not working for some reason.
         * const entries = {
         *     (0) : l2_exclusion_id_offset_hit(0);
         *     (1) : l2_exclusion_id_offset_hit(72);
         *     (2) : l2_exclusion_id_offset_hit(144);
         *     (3) : l2_exclusion_id_offset_hit(216);
         * }
         */
        size = 4;
    }

    apply {
        if (hdr.dp_ctrl_hdr.isValid()) {
            ig_md.ktep_meta.pkt_length_offset = ig_md.ktep_meta.pkt_length_offset + DP_CTRL_SIZE;
        }

        /* The program does not compile when this is in the parser so
         * we are initialzing this metadata here instead.
         */
        ig_md.ktep_router_meta.process_l2_egress = 0;

        /**
         * This metadata is initialized as a workaround for a bug where if it's initialized in
         * the parser, it doesn't remain 0 in the ingress. (only on tofino2).
         */
        ig_md.ktep_meta.process_l3 = 0;
# 234 "leaf.p4"
        cpu_port.apply(ig_md.fabric_meta.cpu_port);
        compute_flow_hash.apply(hdr, ig_md);
        init_l2_exclusion_id();
        // if (ig_md.ktep_meta.ingress_pkt_type == PKT_TYPE_QINQ) {
        //     ig_md.ktep_meta.ingress_vlan_id = hdr.qinq.vlanID;
        // }

        if (!hdr.pktgen_ext_header.isValid()) {
            if (ig_md.ktep_port_meta.port_type == PORT_TYPE_FABRIC) {
                /* Assign iCoS and QiD for control traffic. */
                copp_flow_classification.apply(hdr, ig_intr_md_for_tm);
            }
            if (ig_md.ktep_port_meta.port_type != PORT_TYPE_USER) {
                l2_ingress.apply(hdr, ig_md.fabric_meta, ig_intr_md,
                        ig_intr_md_for_tm, ig_dprsr_md);

                knf_packets.apply(hdr, ig_md, ig_intr_md, ig_intr_md_for_tm);
            } else {
                ig_md.ktep_meta.processing_user_pkt = 1;
                user_punt.apply(hdr, ig_md, ig_intr_md, ig_intr_md_for_tm, ig_dprsr_md);

                vnet_mapping.apply(hdr, ig_md, ig_md.ktep_meta, ig_dprsr_md.digest_type,
                        ig_intr_md, ig_intr_md_for_tm, ig_dprsr_md);

                lag_state_check.apply(ig_md, ig_intr_md_for_tm, ig_dprsr_md);
            }

            l2_exclusion_id_offset.apply();

            if (ig_md.ktep_meta.learn == 1) {
                vnet_learning.apply(hdr, ig_md, ig_dprsr_md.digest_type,
                        ig_intr_md);
            }
            vnet_cpu.apply(hdr, ig_md, ig_intr_md, ig_intr_md_for_tm);

            process_vrouter_mpls_vxlan.apply(hdr, ig_md, ig_intr_md, ig_intr_md_for_tm, ig_dprsr_md);

            if (hdr.vlan.isValid() && hdr.mpls.isValid() &&
                    ig_md.ktep_router_meta.mpls_decap == 0) {
                hdr.inner_ethernet.etherType = ETHERTYPE_VLAN;
                hdr.vlan.etherType = ETHERTYPE_MPLS_UNICAST;
            }

            if ((ig_md.ktep_router_meta.punt == 1) ||
                    ((ig_md.ktep_router_meta.mtu_pkt_diff & MSB_MASK) != 0)) {
                prepare_vrouter_punt.apply(hdr, ig_md, ig_intr_md_for_tm, ig_dprsr_md);
            } else if (ig_md.ktep_meta.process_l2 == 1 && ig_md.ktep_meta.is_icl == 0) {
                vrouter_gre_decap.apply(hdr, ig_md);

                vnet_exclusion.apply(hdr, ig_md, ig_intr_md, ig_intr_md_for_tm);

                vnet_dmac.apply(hdr, ig_md, ig_md.ktep_meta, ig_md.fabric_meta,
                        ig_intr_md, ig_intr_md_for_tm, ig_dprsr_md);
            }
        }

        /* for pipeline fitting reason, INT ingress processing is starting here. */
        int_gen.apply(ig_md);

        if (!hdr.pktgen_ext_header.isValid()) {
            if (ig_md.ktep_meta.l2_lkp_flag == 1) { /* Local overlay unicast traffic. */
                vnet_egress_ifaces.apply(hdr, ig_md, ig_md.ktep_meta, ig_intr_md,
                        ig_intr_md_for_tm, ig_dprsr_md);
            } else if (ig_intr_md_for_tm.mcast_grp_a != 0) { /* Overlay multicast traffic. */
                ingress_replication.apply(hdr, ig_md, ig_intr_md_for_tm, ig_dprsr_md);
            } else { /* Underlay routing. */
                dest_id_mapping.apply(ig_md);
                fabric_routing.apply(hdr, ig_md.fabric_meta, ig_intr_md,
                        ig_intr_md_for_tm, ig_dprsr_md);
            }
            /* Drop CPU punt traffic when exceeding configured rate limit. */
            copp_rate_limiting.apply(ig_intr_md, ig_md.fabric_meta, ig_intr_md_for_tm,
                    ig_dprsr_md);

            telemetry_watchlist.apply(hdr, ig_md, ig_intr_md, ig_md.ktep_port_meta);

            /* Collect L1 TPs Rx/Tx Drop Stats. */
            l1tp_drop_stats.apply(ig_intr_md, ig_intr_md_for_tm, ig_dprsr_md);

            /* When a packet is about to leave the fabric and sent to a user port
             * we remove the overhead of header encapsulations (KNF, MPLS) in the
             * ingress pipeline to have better TM performance. We are not able to
             * reach line rate for the smallest packet size (64 Bytes) due to the
             * size of the bridged metadata which also adds an overhead consuming
             * TM resources. Also the stages latency (complexity of pipeline
             * processing) has an impact on the outgoing traffic speed when
             * exceeding 256 cycles it adds more delay.
             */
            local_iface_remove_overhead.apply(hdr, ig_md);
        } else {
            lag_failover.apply(hdr, ig_intr_md, ig_intr_md_for_tm, ig_dprsr_md);
            port_failover.apply(hdr, ig_intr_md, ig_intr_md_for_tm, ig_dprsr_md);
        }

        /* Only add bridged metadata if we are NOT bypassing egress pipeline. */
        if (ig_intr_md_for_tm.bypass_egress == 0) {
            add_bridged_md();
        }
    }
}

control SwitchEgress(
        inout egress_header_t hdr,
        inout egress_metadata_t eg_md,
        in egress_intrinsic_metadata_t eg_intr_md,
        in egress_intrinsic_metadata_from_parser_t eg_prsr_md,
        inout egress_intrinsic_metadata_for_deparser_t eg_dprsr_md,
        inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport) {

    /* Hardware Config. */
    EgressCPUPort() egress_cpu_port;

    /* L2 service */
    ReplicatedPackets(RID_TABLE_SIZE, EGRESS_PORTS_TABLE_SIZE) l2_packet_replication;
    KnfEncap() knf_encap;
    KnfRewrite(11264, 128, KNF_REWRITE_TABLE_SIZE,
               KVS_REWRITE_TABLE_SIZE, 1024) knf_rewrite;
    VnetEgressVLANCntr(VNET_EGRESS_TABLE_SIZE) vnet_pkt_cntr_egress;
    VnetEgressRxStats() vnet_eg_rx_stats;

    /* L3 service */
    VRouterEncapTunnel(128,
        128,
        4096,
        VROUTER_GRE_ENCAP_TABLE_SIZE) vxlan_tunnel;
    VRouterEgress(VROUTER_IFACES_TABLE_SIZE, VROUTER_NEIGH_TABLE_SIZE,
        VROUTER_TABLE_SIZE) vrouter_egress;
    L3EgressCntr(PUNT_TUNNEL_STATS_TABLE_SIZE) l3_counters;
    DecapMPLS() pop_mpls;

    /* INT */
    TelGenerateSequenceNum() generate_tel_sequence_number;
    TelE2EMirror() tel_e2e_mirror;
    TelGeneratePostcard() tel_generate_postcard;

    /* Fabric */
    L2Egress(L2_EGRESS_TABLE_SIZE) l2_egress;
    ReplicaCopyMac(NH_TABLE_SIZE) nexthop_mac;
    CopyNexthopMAC(256) copy_nh_mac;
    EgressDrop() egress_drop;
    EgressCPUPortEncap() egress_cpu_port_encap;

    action drop_packet() {
        eg_dprsr_md.drop_ctl = DROP_CTL_ALL;
        exit;
    }

    apply {
        eg_dprsr_md.drop_ctl = 0;

        /* The eg_intr_md.pkt_length holds the size of the packet when it was
         * received in the ingress pipeline. Thus, any headers that were removed
         * are still included. In order to calculate the various length fields
         * correctly when encapsulating, we adjust the length to remove the
         * length of the headers that were removed in the ingress pipeline.
         */
        eg_md.ktep_meta.payload_length = eg_intr_md.pkt_length - eg_md.ktep_meta.pkt_length_offset;

        if (eg_md.parser_metadata.clone_src == SWITCH_PKT_SRC_BRIDGE) {
            egress_cpu_port.apply(eg_md);
            l2_packet_replication.apply(hdr, eg_md, eg_intr_md, eg_dprsr_md);
            egress_cpu_port_encap.apply(hdr, eg_md, eg_intr_md);

            /* Rate limiting multicast traffic towards the punt channel. */
            if (eg_md.ktep_router_meta.meter_color == MeterColor_t.RED) {
                drop_packet();
            }

            vnet_eg_rx_stats.apply(hdr, eg_md);

            if ((eg_md.ktep_meta.process_l2 == 1) ||
                    (eg_md.ktep_meta.process_l3 == 1) ||
                    (eg_md.ktep_meta.is_from_kvs == 1) ||
                    (eg_md.ktep_meta.send_to_kvs == 1)) {
                vxlan_tunnel.apply(hdr, eg_md, eg_intr_md, eg_dprsr_md);

                if (eg_md.ktep_meta.egress_pkt_type == PKT_TYPE_KNF) {
                    knf_encap.apply(hdr, eg_md, eg_intr_md, eg_dprsr_md);
                    knf_rewrite.apply(hdr, eg_md, eg_md.ktep_meta, eg_intr_md, eg_dprsr_md);
                }

                vrouter_egress.apply(hdr, eg_md, eg_intr_md, eg_dprsr_md);

                vnet_pkt_cntr_egress.apply(hdr, eg_md, eg_md.ktep_meta, eg_intr_md, eg_dprsr_md);

                l3_counters.apply(eg_md, eg_md.ktep_meta);
            }

            /* pop_mpls block needs to be placed after l3_counters due to resetting
             * mpls_decap flag (we revert it back to 0) in case of a punt channel
             * (punt_tunnel_stats_hit) so that the control plane would receive
             * the original MPLS packet as is.
             * Note that another MPLS decap is applied in the ingress pipeline
             * when the packet is to be sent to a user port.
             * The following MPLS decap block is for KNF packets to be sent on a
             * fabric port.
             */
            pop_mpls.apply(hdr, eg_md);

            generate_tel_sequence_number.apply(hdr, eg_md.tel_metadata);

            if (eg_md.fabric_meta.l2_egress_lkp_flag == 1) {
                l2_egress.apply(hdr, eg_md, eg_intr_md, eg_dprsr_md);
                if ((eg_intr_md.egress_rid != 0) && (eg_md.ktep_meta.send_to_kvs == 0)) {
                    nexthop_mac.apply(hdr, eg_intr_md, eg_dprsr_md);
                } else {
                    copy_nh_mac.apply(hdr, eg_md.fabric_meta);
                }
                egress_drop.apply(hdr, eg_dprsr_md);
            }
            tel_e2e_mirror.apply(hdr, eg_md.tel_metadata, eg_md,
                    eg_intr_md, eg_prsr_md, eg_dprsr_md);
        } else {
            tel_generate_postcard.apply(hdr, eg_md.tel_metadata, eg_md.mirror,
                    eg_md.parser_metadata, eg_intr_md, eg_dprsr_md);
        }
    }
}

Pipeline(SwitchIngressParser(),
         SwitchIngress(),
         SwitchIngressDeparser(),
         SwitchEgressParser(),
         SwitchEgress(),
         SwitchEgressDeparser()) pipe;

Switch(pipe) main;
