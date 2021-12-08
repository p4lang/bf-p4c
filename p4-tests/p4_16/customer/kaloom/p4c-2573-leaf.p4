// TOFINO1_ONLY

#include <core.p4>
#include <tna.p4>

// Test program exceeds Tof1 egress parse depth
@command_line("--disable-parse-max-depth-limit")

typedef bit<48> mac_addr_t;
typedef bit<8> mac_addr_id_t;
typedef bit<16> ethertype_t;
typedef bit<12> vlan_id_t;
typedef bit<32> ipv4_addr_t;
typedef bit<128> ipv6_addr_t;
typedef bit<56> knid_t;
typedef bit<32> port_failover_reg_index_t;
typedef bit<32> ecmp_group_id_t; /* TODO: use 16 bits when compiler is fixed. */

typedef PortId_t port_id_t;
typedef MirrorId_t mirror_id_t;
typedef QueueId_t queue_id_t;

const port_id_t RECIRC_PORT_PIPE_0 = 68;

const bit<8> POSTCARD_VERSION = 0x1;

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
const bit<3> MIRROR_TYPE_NONE = 0;
const bit<3> MIRROR_TYPE_I2I = 1;
const bit<3> MIRROR_TYPE_I2E = 2;
const bit<3> MIRROR_TYPE_E2E = 1;
const bit<3> MIRROR_TYPE_E2I = 2;

/* Fabric metadata */
struct ig_fabric_metadata_t {
    ipv6_addr_t lkp_ipv6_addr; /* Carries key for the lookup in routing_ipv6 and neighbor tables */
    port_id_t cpu_port; /* CPU port ID */
    bit<1> routing_lkp_flag; /* Indicates if routing table lookup should be performed */
    bit<1> l2_ingress_lkp_flag; /* Indicates if l2 ingress table lookup should be performed */
    bit<1> l2_egress_lkp_flag; /* Indicates if l2 egress table lookup should be performed */
    ecmp_group_id_t ecmp_grp_id; /* A key used to lookup in ECMP_groups table */
    mac_addr_id_t neigh_mac; /* Carries mac ID of neighbor MAC address */
    bit<16> flow_hash; /* Hash value of the overlay flow */
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
}

/* Telemetry metadata */
struct eg_tel_metadata_t {
    bit<1> generate_postcard; /* Set to generate a postcard */
    bit<1> watchlist_hit; /* Set when a packet matches a watchlist rule */
}

struct eg_parser_metadata_t {
    bit<8> clone_src;
}
# 14 "core/headers/headers.p4" 2

const ethertype_t ETHERTYPE_IPV6 = 0x86dd;
const ethertype_t ETHERTYPE_IPV4 = 0x0800;
const ethertype_t ETHERTYPE_DP_CTRL = 0x99ff;
const ethertype_t ETHERTYPE_VLAN = 0x8100;
const ethertype_t ETHERTYPE_BF_PKTGEN = 0x9001;

const bit<4> IPV6_VERSION = 0x6;
const bit<4> IPV4_VERSION = 0x4;

const bit<8> UDP_PROTO = 0x11;
const bit<8> TCP_PROTO = 0x6;
const bit<8> HOP_LIMIT = 64;

const bit<16> KNF_UDP_DST_PORT = 0x38C7;
const bit<16> KNF_UDP_SRC_PORT = 0;
const bit<16> UDP_PORT_VXLAN = 4789;
const bit<16> UDP_PORT_TEL_REPORT = 0x7FFF;

const bit<16> ETH_SIZE = 14;
const bit<16> IPV4_SIZE = 20;
const bit<16> IPV6_SIZE = 40;
const bit<16> UDP_SIZE = 8;
const bit<16> KNF_SIZE = 12;
const bit<16> VXLAN_SIZE = 8;
const bit<16> POSTCARD_SIZE = 36;

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

/* Carries metadata for packets that are forwarded to/from CPU */
header dp_ctrl_header_t {
    bit<5> _pad0; /* This padding is needed because the ring identifier corresponds
                    * to the 3 lower bits in the first byte of the packet
                    */
    bit<3> ring_id; /* Ring Identifier */
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

header knf_t {
    bit<4> version;
    bit<4> pType;
    knid_t knid; /* OEType : 8; IDID : 16; VNI : 32; */
    /* bit<16> hdrMap; */
    bit<16> remoteLagID; /* TODO: this field used to be hdrMap. We need to put
                          * it back when KNF header extensions are supported.
                          */
    bit<1> hdrElided;
    bit<1> doNotLearn;
    bit<6> reserved;
    bit<8> telSequenceNum;
}

header postcard_header_t {
    bit<8> version;
    bit<16> reserved;
    bit<8> sequence_num;
    bit<64> switch_id;
    bit<16> ingress_port;
    bit<16> egress_port;
    bit<8> queue_id;
    bit<24> queue_depth;
    bit<64> ingress_tstamp;
    bit<64> egress_tstamp;
}
# 14 "leaf.p4" 2
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
control BypassAndExit(out ingress_intrinsic_metadata_for_tm_t ig_tm_md) {

    action bypass_and_exit() {
        ig_tm_md.bypass_egress = 1;
        exit;
    }

    apply {
        bypass_and_exit();
    }
}
# 15 "leaf.p4" 2
# 1 "core/types.p4" 1
/****************************************************************
 * Copyright (c) Kaloom, 2019
 *
 * This unpublished material is property of Kaloom Inc.
 * All rights reserved.
 * Reproduction or distribution, in whole or in part, is
 * forbidden except by express written permission of Kaloom Inc.
 ****************************************************************/
# 16 "leaf.p4" 2
# 1 "types.p4" 1
/****************************************************************
 * Copyright (c) Kaloom, 2019
 *
 * This unpublished material is property of Kaloom Inc.
 * All rights reserved.
 * Reproduction or distribution, in whole or in part, is
 * forbidden except by express written permission of Kaloom Inc.
 ****************************************************************/




# 1 "/home/parallels/bf-sde-9.1.0.19-pr/install/share/p4c/p4include/tofino.p4" 1
/*
 * Copyright (c) 2015-2019 Barefoot Networks, Inc.
 *
 * All Rights Reserved.

 * NOTICE: All information contained herein is, and remains the property of
 * Barefoot Networks, Inc. and its suppliers, if any. The intellectual and
 * technical concepts contained herein are proprietary to Barefoot Networks, Inc.
 * and its suppliers and may be covered by U.S. and Foreign Patents, patents in
 * process, and are protected by trade secret or copyright law. Dissemination of
 * this information or reproduction of this material is strictly forbidden unless
 * prior written permission is obtained from Barefoot Networks, Inc.

 * No warranty, explicit or implicit is provided, unless granted under a written
 * agreement with Barefoot Networks, Inc.
 *
 */
# 14 "types.p4" 2

# 1 "core/types.p4" 1
/****************************************************************
 * Copyright (c) Kaloom, 2019
 *
 * This unpublished material is property of Kaloom Inc.
 * All rights reserved.
 * Reproduction or distribution, in whole or in part, is
 * forbidden except by express written permission of Kaloom Inc.
 ****************************************************************/
# 16 "types.p4" 2
# 1 "core/headers/headers.p4" 1
/****************************************************************
 * Copyright (c) Kaloom, 2019
 *
 * This unpublished material is property of Kaloom Inc.
 * All rights reserved.
 * Reproduction or distribution, in whole or in part, is
 * forbidden except by express written permission of Kaloom Inc.
 ****************************************************************/
# 17 "types.p4" 2

typedef bit<16> nw_id_t;
typedef bit<10> dest_id_t;
typedef bit<7> kvtep_id_t;
typedef MulticastGroupId_t mcast_grp_id_t;
typedef bit<16> exclusion_id_t;
typedef bit<7> vrouter_id_t;
typedef bit<6> vrouter_iface_id_t;
typedef bit<24> vni_t;
typedef bit<9> iface_id_t;
typedef bit<32> lag_failover_reg_index_t;

const bit<2> PKT_TYPE_UNTAGGED = 0;
const bit<2> PKT_TYPE_VLAN = 1;
const bit<2> PKT_TYPE_KNF = 2;

const bit<2> PORT_TYPE_NONE = 0;
const bit<2> PORT_TYPE_FABRIC = 1;
const bit<2> PORT_TYPE_USER = 2;
const bit<2> PORT_TYPE_KVS = 3;

const bit<32> MCAST_HASH_SIZE = 65536;
const bit<1> MCAST_HASH_BASE = 0;

const bit<2> KTEP_SRC_OTHER = 0; /* user port or vrouter */
const bit<2> KTEP_SRC_LEAF = 1;
const bit<2> KTEP_SRC_KVS = 2;

const bit<2> KVTEP_PKT_TYPE_VXLAN = 1;
const bit<2> KVTEP_PKT_TYPE_RAW = 0;

/* Learning digest structures */
typedef bit<3> digest_type_t;
const digest_type_t DIGEST_TYPE_REMOTE_MAC_LEARNING = 0;
const digest_type_t DIGEST_TYPE_LOCAL_MAC_LEARNING = 1;
const digest_type_t DIGEST_TYPE_KVS_MAC_LEARNING = 2;
const digest_type_t DIGEST_TYPE_KVS_MULTICAST_LEARNING = 3;
const digest_type_t DIGEST_TYPE_REMOTE_VTEP_V4_MAC_LEARNING = 4;
const digest_type_t DIGEST_TYPE_REMOTE_VTEP_V6_MAC_LEARNING = 5;

struct remote_mac_learning_digest_t {
    mac_addr_t inner_ethernet_srcAddr;
    nw_id_t ktep_meta_learn_nw_id;
    ipv6_addr_t ipv6_srcAddr;
}

struct local_mac_learning_digest_t {
    port_id_t ig_intr_md_ingress_port;
    vlan_id_t ktep_meta_ingress_vlan_id;
    nw_id_t ktep_meta_learn_nw_id;
    mac_addr_t ethernet_srcAddr;
    mac_addr_t inner_ethernet_srcAddr;
    bit<1> isKNF;
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

/* Port Metadata. Must be 64 bits */
@pa_atomic("ingress", "ig_md.ktep_meta.ingress_iface_id")
header port_metadata_t {
    bit<2> port_type;
    bit<1> l2_ingress_lkp;
    iface_id_t iface_id;
    bit<52> pad0;
}

/* Bridge Metadata */
struct bridged_ktep_metadata_t {
    @flexible vlan_id_t egress_vlan_id;
    @flexible bit<2> ingress_pkt_type;
    @flexible bit<2> egress_pkt_type;
    @flexible bit<1> process_l2;
    @flexible bit<1> process_l3;
    @flexible bit<10> dest_id;
    @flexible bit<1> received_on_punt_channel;
    @flexible bit<1> is_from_kvs;
    @flexible bit<2> pkt_src;
    @flexible nw_id_t nw_id;
    @flexible bit<1> send_to_kvs;
    @flexible iface_id_t ingress_iface_id;
    @flexible iface_id_t egress_iface_id;
}

struct bridged_ktep_router_metadata_t {
    @flexible vrouter_id_t router_id;
    @flexible vrouter_iface_id_t output_iface;
    @flexible mac_addr_t dst_mac;
    @flexible bit<1> process_l2_egress;
}

struct bridged_kvtep_metadata_t {
    @flexible bit<2> egress_pkt_type;
    @flexible bit<1> process_egress;
    @flexible kvtep_id_t kvtep_id;
    @flexible kvtep_id_t remote_vtep_id;
}

struct bridged_ktep_port_metadata_t {
    @flexible bit<2> port_type;
}

struct bridged_tel_metadata_t {
    @flexible bit<1> generate_postcard; /* Set to generate a postcard */
    @flexible bit<1> watchlist_hit; /* Set when a packet matches a watchlist rule */
}

/* User-defined metadata carried over from ingress to egress */
@pa_alias("ingress", "hdr.bridged_md.fabric_meta_neigh_mac", "ig_md.fabric_meta.neigh_mac")
header bridged_metadata_t {
    switch_pkt_src_t src;
    @flexible port_id_t ingress_port;
    @flexible bit<48> ingress_tstamp;
    bridged_fabric_metadata_t fabric_meta;
    bridged_ktep_port_metadata_t ktep_port_meta;
    bridged_ktep_metadata_t ktep_meta;
    bridged_ktep_router_metadata_t ktep_router_meta;
    bridged_kvtep_metadata_t kvtep_meta;
    bridged_tel_metadata_t tel_metadata;
}

/* Header structure */
struct header_t {
    bridged_metadata_t bridged_md;
    dp_ctrl_header_t dp_ctrl_hdr;
    pktgen_port_down_header_t pktgen_port_down;
    pktgen_ext_header_t pktgen_ext_header;
    ethernet_t ethernet;
    ipv6_t ipv6;
    udp_t udp;
    tcp_t tcp;
    knf_t knf;
    postcard_header_t postcard_header;
    ethernet_t inner_ethernet;
    vlan_t vlan;
    ipv4_t ipv4;
    ipv6_t inner_ipv6;
    udp_t inner_udp;
    udp_t udpv4;
    vxlan_t vxlan;
    ethernet_t vxlan_inner_ethernet;
    ipv4_t vxlan_inner_ipv4;
    ipv6_t vxlan_inner_ipv6;
    udp_t vxlan_inner_udp;
}

struct ig_ktep_port_metadata_t {
    bit<2> port_type;
}

struct eg_ktep_port_metadata_t {
    bit<2> port_type;
}

/* KTEP metadata */
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
    bit<1> is_knf_udp_port; /* A UDP packet that uses KNF destination port is not
                              * necessarily a KNF packet. After looking up port type
                              * we set packet type to KNF if it is coming from a fabric port.
                              */
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
    bit<1> lag_lkp_flag;
    bit<1> is_icl; /* Identifies a packet that came from ICL which should not go
                    * to vnet_dmac table.
                    */
    iface_id_t remote_lag_id;
    bit<16> flow_hash;
}

/* VRouter metadata */
struct ig_ktep_router_metadata_t {
    vrouter_id_t router_id;
    bit<1> is_not_ip; /* Packet is not of types IPV4 or IPv6 */
    ipv6_addr_t dst_ipAddr; /* IPv6 address that represent the IPv4 or IPv6
                             * destination address in the packet. It is used to
                             * lookup in ktep_l3 and ktep_neigh tables.
                             */
    vrouter_iface_id_t input_iface; /* vRouter's input interface */
    vrouter_iface_id_t output_iface; /* vRouter's output interface */
    mac_addr_t dst_mac; /* Nexthop destination MAC address */
    bit<1> process_l2_egress;
    bit<1> punt; /* Indicates if the packet should be sent on punt channel */
    bit<16> pkt_len; /* Size of IP packet */
    bit<16> mtu_pkt_diff;
    bit<1> neigh_lkp; /* Indicates whether the vrouter neighbor lookup should
                        *  be performed.
                        */
}

/* KVTEP metadata */
struct ig_kvtep_metadata_t {
    bit<2> egress_pkt_type;
    bit<1> process_egress;
    kvtep_id_t kvtep_id;
    kvtep_id_t remote_vtep_id;
    bit<1> learn_inner; /* Indicates if we should learn hosts behind VTEP */
}

/* INT metadata */
struct ig_tel_metadata_t {
    bit<16> tel_hash;
    bit<1> generate_postcard; /* Set to generate a postcard */
    bit<1> watchlist_hit; /* Set when a packet matches a watchlist rule */
}

/* Ingress Metadata */
@pa_mutually_exclusive("ingress", "ig_md.ktep_router_meta.dst_ipAddr","ig_md.fabric_meta.lkp_ipv6_addr")
/* Moving telemetry watchlist table from egress to ingress shuffles the PHVs and
 * the compiler decided to overlay ig_md.ktep_meta.is_knf_udp_port with
 * ig_intr_md_for_tm.bypass_egress and then with ig_intr_md_for_dprsr.drop_ctl
 * causing most of ptf tests to fail (those receiving a KNF packet).
 */
@pa_no_overlay("ingress", "ig_md.ktep_meta.is_knf_udp_port")
struct ingress_metadata_t {
    port_id_t ingress_port;
    port_metadata_t port_md;
    ig_fabric_metadata_t fabric_meta;
    ig_ktep_metadata_t ktep_meta;
    ig_tel_metadata_t tel_metadata;
    ig_ktep_router_metadata_t ktep_router_meta;
    ig_kvtep_metadata_t kvtep_meta;
    ig_ktep_port_metadata_t ktep_port_meta;
    remote_mac_learning_digest_t remote_mac_learning;
    local_mac_learning_digest_t local_mac_learning;
    kvs_multicast_learning_digest_t kvs_multicast_learning;
    vtep_v4_learning_digest_t vtep_v4_learning;
    vtep_v6_learning_digest_t vtep_v6_learning;
}

@pa_alias("egress", "eg_md.ktep_meta.egress_vlan_id", "eg_md.ktep_meta.remote_lag_id")
@pa_atomic("egress", "eg_md.ktep_meta.ingress_iface_id")
struct eg_ktep_metadata_t {
    vlan_id_t egress_vlan_id;
    ethertype_t vlan_etherType;
    bit<16> payload_length;
    bit<2> ingress_pkt_type;
    bit<2> egress_pkt_type;
    bit<1> process_l2;
    bit<1> process_l3;
    bit<10> dest_id;
    bit<1> received_on_punt_channel;
    bit<1> is_from_kvs;
    bit<2> pkt_src;
    nw_id_t nw_id;
    bit<1> send_to_kvs;
    iface_id_t ingress_iface_id;
    iface_id_t egress_iface_id;
    iface_id_t remote_lag_id;
}

struct eg_ktep_router_metadata_t {
    vrouter_id_t router_id;
    vrouter_iface_id_t output_iface;
    mac_addr_t src_mac;
    mac_addr_t dst_mac;
    bit<1> process_l2_egress;
}

struct eg_kvtep_metadata_t {
    bit<2> egress_pkt_type;
    bit<1> process_egress;
    kvtep_id_t kvtep_id;
    kvtep_id_t remote_vtep_id;
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
/* WARNING: For PHV allocation efficiency, each mirror header needs to be overlayed
 * with an egress metadata field of an equal or bigger size.
 * Make sure the list below remains relevant.
 * Check in pa.characterize.log that the compiler is applying the annotations below.
 */
@pa_mutually_exclusive("egress", "eg_md.mirror.session_id", "eg_md.ktep_meta.dest_id") // 10 bits
@pa_mutually_exclusive("egress", "eg_md.mirror.ingress_port", "eg_md.ingress_port") // 9 bits
@pa_mutually_exclusive("egress", "eg_md.mirror.egress_port", "eg_md.ktep_meta.egress_iface_id") // 9 bits
@pa_mutually_exclusive("egress", "eg_md.mirror.queue_id", "eg_md.kvtep_meta.remote_vtep_id") // 5 bits
@pa_mutually_exclusive("egress", "eg_md.mirror.queue_depth", "eg_md.fabric_meta.neigh_mac") // 19 bits
@pa_mutually_exclusive("egress", "eg_md.mirror.ingress_tstamp", "hdr.bridged_md.ingress_tstamp") // 48 bits
@pa_mutually_exclusive("egress", "eg_md.mirror.egress_tstamp", "eg_md.ktep_router_meta.dst_mac") // 48 bits
@pa_mutually_exclusive("egress", "eg_md.mirror.sequence_num", "eg_md.ktep_meta.nw_id") // 8 bits
struct egress_metadata_t {
    port_id_t ingress_port;
    eg_fabric_metadata_t fabric_meta;
    eg_parser_metadata_t parser_metadata;
    eg_ktep_metadata_t ktep_meta;
    eg_ktep_router_metadata_t ktep_router_meta;
    eg_kvtep_metadata_t kvtep_meta;
    eg_mirror_metadata_t mirror;
    eg_tel_metadata_t tel_metadata;
    eg_ktep_port_metadata_t ktep_port_meta;
}
# 17 "leaf.p4" 2
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
        out ingress_metadata_t ig_md,
        out ingress_intrinsic_metadata_t ig_intr_md) {
    state start {
        pkt.extract(ig_intr_md);
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
        pkt.extract(ig_md.port_md);
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
        #if __TARGET_TOFINO__ == 1
            if (eg_intr_md_for_dprsr.mirror_type == MIRROR_TYPE_E2E) {
        #elif __TARGET_TOFINO__ >= 2
            if (eg_intr_md_for_dprsr.mirror_type == (bit<4>) MIRROR_TYPE_E2E) {
        #endif
            mirror.emit<eg_mirror_metadata_t>(eg_md.mirror.session_id,
                    eg_md.mirror);
        }
    }
}
# 18 "parde.p4" 2

/* Ingress Parser */
parser SwitchIngressParser(
        packet_in pkt,
        out header_t hdr,
        out ingress_metadata_t ig_md,
        out ingress_intrinsic_metadata_t ig_intr_md) {

    TofinoIngressParser() tofino_parser;
    Checksum() ipv4_checksum;
    Checksum() vxlan_inner_ipv4_checksum;

    state start {
        tofino_parser.apply(pkt, ig_md, ig_intr_md);

        ig_md.ktep_port_meta.port_type = ig_md.port_md.port_type;
        ig_md.fabric_meta.l2_ingress_lkp_flag = ig_md.port_md.l2_ingress_lkp;
        ig_md.ktep_meta.ingress_iface_id = ig_md.port_md.iface_id;

        /* Initialize Metadata to Zero */
        ig_md.fabric_meta.routing_lkp_flag = 0;
        ig_md.fabric_meta.l2_egress_lkp_flag = 0;
        ig_md.ktep_meta.ingress_vlan_id = 0;
        ig_md.ktep_meta.egress_vlan_id = 0;
        ig_md.ktep_meta.pkt_src = 0;
        ig_md.ktep_meta.process_l3 = 0;
        ig_md.ktep_meta.is_knf_udp_port = 0;
        ig_md.ktep_meta.received_on_punt_channel = 0;
        ig_md.ktep_meta.learn = 0;
        ig_md.ktep_meta.is_icl = 0;
        ig_md.ktep_meta.process_l2 = 0;
        ig_md.ktep_meta.is_from_kvs = 0;
        ig_md.ktep_meta.send_to_kvs = 0;
        ig_md.ktep_meta.lag_lkp_flag = 0;
        ig_md.ktep_meta.ingress_pkt_type = PKT_TYPE_UNTAGGED;

        ig_md.ktep_router_meta.punt = 0;
        ig_md.ktep_router_meta.mtu_pkt_diff = 0;

        ig_md.kvtep_meta.process_egress = 0;

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
            ETHERTYPE_VLAN : parse_vlan;
            ETHERTYPE_IPV4 : parse_ipv4;
            ETHERTYPE_IPV6 : parse_ipv6;
            default : accept;
        }
    }

    state parse_vlan {
        pkt.extract(hdr.vlan);
        ig_md.ktep_meta.ingress_vlan_id = hdr.vlan.vlanID;
        ig_md.ktep_meta.ingress_pkt_type = PKT_TYPE_VLAN;
        transition select(hdr.vlan.etherType) {
            ETHERTYPE_IPV4 : parse_ipv4;
            ETHERTYPE_IPV6 : parse_user_ipv6;
            default : accept;
        }
    }

    /* If user packet is IPv6 we need to parse and validate ipv6 header so that if
     * the packet is encapsulated in a KNF packet we copy IPV6 headers to the inner
     * packet and overwrite the outer IPv6 header with remote leaf IP
     */
    state parse_user_ipv6 {
        pkt.extract(hdr.ipv6);
        transition select(hdr.ipv6.nextHdr) {
            UDP_PROTO : parse_user_udp;
            default : accept;
        }
    }

    state parse_user_udp {
        pkt.extract(hdr.udp);
        transition select(hdr.udp.dstPort) {
            UDP_PORT_VXLAN : parse_vxlan;
            default : accept;
        }
    }

    state parse_ipv6 {
        pkt.extract(hdr.ipv6);
        ig_md.fabric_meta.routing_lkp_flag = 1;
        transition select(hdr.ipv6.nextHdr) {
            UDP_PROTO : parse_udp;
            TCP_PROTO : parse_tcp;
            default : accept;
        }
    }

    state parse_udp {
        pkt.extract(hdr.udp);
        transition select(hdr.udp.dstPort) {
            KNF_UDP_DST_PORT : parse_knf_inner_ethernet;
            UDP_PORT_VXLAN : parse_vxlan;
            default : accept;
        }
    }

    state parse_tcp {
        pkt.extract(hdr.tcp);
        transition accept;
    }

    state parse_knf_inner_ethernet {
        pkt.extract(hdr.knf);
        pkt.extract(hdr.inner_ethernet);
        ig_md.ktep_meta.is_knf_udp_port = 1;
        transition select(hdr.inner_ethernet.etherType) {
            ETHERTYPE_IPV4 : parse_ipv4;
            ETHERTYPE_IPV6 : parse_inner_ipv6;
            default : accept;
        }
    }

    state parse_ipv4 {
        pkt.extract(hdr.ipv4);
        ipv4_checksum.add(hdr.ipv4);
        /* TODO: ipv4_checksum.verify(); */
        transition select(hdr.ipv4.protocol) {
            UDP_PROTO : parse_udpv4;
            TCP_PROTO : parse_tcp;
            default : accept;
        }
    }

    state parse_udpv4 {
        pkt.extract(hdr.udpv4);
        transition select(hdr.udpv4.dstPort) {
            UDP_PORT_VXLAN : parse_vxlan;
            default : accept;
        }
    }

    state parse_inner_ipv6 {
        pkt.extract(hdr.inner_ipv6);
        transition select(hdr.inner_ipv6.nextHdr) {
            UDP_PROTO : parse_inner_udp;
            default : accept;
        }
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
        transition parse_vxlan_inner_ether;
    }

    state parse_vxlan_inner_ether {
        pkt.extract(hdr.vxlan_inner_ethernet);
        transition select(hdr.vxlan_inner_ethernet.etherType) {
            ETHERTYPE_IPV6 : parse_vxlan_inner_ipv6;
            ETHERTYPE_IPV4 : parse_vxlan_inner_ipv4;
            default : accept;
        }
    }

    state parse_vxlan_inner_ipv4 {
        pkt.extract(hdr.vxlan_inner_ipv4);
        vxlan_inner_ipv4_checksum.add(hdr.vxlan_inner_ipv4);
        /* TODO: vxlan_inner_ipv4_checksum.verify(); */
        transition accept;
    }

    state parse_vxlan_inner_ipv6 {
        pkt.extract(hdr.vxlan_inner_ipv6);
        transition select(hdr.vxlan_inner_ipv6.nextHdr) {
            UDP_PROTO : parse_vxlan_inner_udp;
            default : accept;
        }
    }

    state parse_vxlan_inner_udp {
        pkt.extract(hdr.vxlan_inner_udp);
        transition accept;
    }
}

/* Ingress Deparser */
control SwitchIngressDeparser(
    packet_out pkt,
    inout header_t hdr,
    in ingress_metadata_t ig_md,
    in ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr) {

    Digest<remote_mac_learning_digest_t>() remote_mac_learn_digest;
    Digest<local_mac_learning_digest_t>() local_mac_learn_digest;
    Digest<kvs_multicast_learning_digest_t>() kvs_multicast_learn_digest;
    Digest<vtep_v4_learning_digest_t>() vtep_learn_v4;
    Digest<vtep_v6_learning_digest_t>() vtep_learn_v6;

    apply {
        /* Unconditional learning.emit is not supported.
         * Therefore, we need to define and check the learning digest type.
         */
        if (ig_intr_md_for_dprsr.digest_type == DIGEST_TYPE_REMOTE_MAC_LEARNING) {
            remote_mac_learn_digest.pack({hdr.inner_ethernet.srcAddr,
                                ig_md.ktep_meta.learn_nw_id,
                                hdr.ipv6.srcAddr});
        }

        if (ig_intr_md_for_dprsr.digest_type == DIGEST_TYPE_LOCAL_MAC_LEARNING) {
            local_mac_learn_digest.pack({ig_md.ktep_meta.ingress_port,
                                /* TODO: replace ig_md.ktep_meta.ingress_port by
                                 * ig_md.ktep_meta.ingress_iface_id.
                                 */
                               ig_md.ktep_meta.ingress_vlan_id,
                               ig_md.ktep_meta.learn_nw_id,
                               hdr.ethernet.srcAddr,
                               hdr.inner_ethernet.srcAddr,
                               ig_md.ktep_meta.is_from_kvs});
        }

        if (ig_intr_md_for_dprsr.digest_type == DIGEST_TYPE_KVS_MULTICAST_LEARNING) {
            kvs_multicast_learn_digest.pack({
                            ig_md.ktep_meta.ingress_port,
                            hdr.ethernet.srcAddr,
                            hdr.ipv6.srcAddr});
        }
        if (ig_intr_md_for_dprsr.digest_type == DIGEST_TYPE_REMOTE_VTEP_V4_MAC_LEARNING) {
            vtep_learn_v4.pack({
                            /* TODO: Barefoot need to fix the packing of the learn
                             * message so that VNI does not to be necessarily
                             * at the end to be read properly.
                             */
                            hdr.vxlan_inner_ethernet.srcAddr,
                            hdr.ipv4.srcAddr,
                            ig_md.ktep_router_meta.router_id,
                            hdr.vxlan.vni});
        }
        if (ig_intr_md_for_dprsr.digest_type == DIGEST_TYPE_REMOTE_VTEP_V6_MAC_LEARNING) {
            vtep_learn_v6.pack({
                            hdr.vxlan_inner_ethernet.srcAddr,
                            hdr.ipv6.srcAddr,
                            ig_md.ktep_router_meta.router_id,
                            hdr.vxlan.vni});
        }
        pkt.emit(hdr.bridged_md);
        pkt.emit(hdr.dp_ctrl_hdr);
        pkt.emit(hdr.pktgen_port_down);
        pkt.emit(hdr.pktgen_ext_header);
        pkt.emit(hdr.ethernet);
        pkt.emit(hdr.vlan);
        pkt.emit(hdr.ipv6);
        pkt.emit(hdr.udp);
        pkt.emit(hdr.knf);
        pkt.emit(hdr.inner_ethernet);
        pkt.emit(hdr.ipv4);
        pkt.emit(hdr.udpv4);
        pkt.emit(hdr.tcp);
        pkt.emit(hdr.inner_ipv6);
        pkt.emit(hdr.inner_udp);
        pkt.emit(hdr.vxlan);
        pkt.emit(hdr.vxlan_inner_ethernet);
        pkt.emit(hdr.vxlan_inner_ipv4);
        pkt.emit(hdr.vxlan_inner_ipv6);
        pkt.emit(hdr.vxlan_inner_udp);
    }
}

/* Egress Parser */
parser SwitchEgressParser(
        packet_in pkt,
        out header_t hdr,
        out egress_metadata_t eg_md,
        out egress_intrinsic_metadata_t eg_intr_md) {

    TofinoEgressParser() tofino_parser;

    state start {
        tofino_parser.apply(pkt, eg_intr_md);
        switch_pkt_src_t src = pkt.lookahead<switch_pkt_src_t>();
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

        /* Ktep Port Metadata */
        eg_md.ktep_port_meta.port_type = hdr.bridged_md.ktep_port_meta.port_type;

        /* Ktep Metadata */
        eg_md.ktep_meta.egress_vlan_id = hdr.bridged_md.ktep_meta.egress_vlan_id;
        eg_md.ktep_meta.ingress_pkt_type = hdr.bridged_md.ktep_meta.ingress_pkt_type;
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

        /* Ktep Router Metadata */
        eg_md.ktep_router_meta.router_id = hdr.bridged_md.ktep_router_meta.router_id;
        eg_md.ktep_router_meta.output_iface = hdr.bridged_md.ktep_router_meta.output_iface;
        eg_md.ktep_router_meta.dst_mac = hdr.bridged_md.ktep_router_meta.dst_mac;
        eg_md.ktep_router_meta.process_l2_egress = hdr.bridged_md.ktep_router_meta.process_l2_egress;

        /* KVtep Metadata */
        eg_md.kvtep_meta.egress_pkt_type = hdr.bridged_md.kvtep_meta.egress_pkt_type;
        eg_md.kvtep_meta.process_egress = hdr.bridged_md.kvtep_meta.process_egress;
        eg_md.kvtep_meta.kvtep_id = hdr.bridged_md.kvtep_meta.kvtep_id;
        eg_md.kvtep_meta.remote_vtep_id = hdr.bridged_md.kvtep_meta.remote_vtep_id;

        /* INT Metadata */
        eg_md.tel_metadata.generate_postcard = hdr.bridged_md.tel_metadata.generate_postcard;
        eg_md.tel_metadata.watchlist_hit = hdr.bridged_md.tel_metadata.watchlist_hit;

        transition parse_ethernet;
    }

    state parse_ethernet {
        pkt.extract(hdr.ethernet);
        transition select(hdr.ethernet.etherType) {
            ETHERTYPE_VLAN : parse_vlan;
            ETHERTYPE_IPV4 : parse_ipv4;
            ETHERTYPE_IPV6 : parse_ipv6;
            default : accept;
        }
    }

    state parse_vlan {
        pkt.extract(hdr.vlan);
        transition select(hdr.vlan.etherType) {
            ETHERTYPE_IPV4 : parse_ipv4;
            ETHERTYPE_IPV6 : parse_user_ipv6;
            default : accept;
        }
    }

    /* If user packet is IPv6 we need to parse and validate ipv6 header so that if
     * the packet is encapsulated in a KNF packet we copy IPV6 headers to the inner
     * packet and overwrite the outer IPv6 header with remote leaf IP
     */
    state parse_user_ipv6 {
        pkt.extract(hdr.ipv6);
        transition select(hdr.ipv6.nextHdr) {
            UDP_PROTO : parse_user_udp;
            default : accept;
        }
    }

    state parse_user_udp {
        pkt.extract(hdr.udp);
        transition select(hdr.udp.dstPort) {
            UDP_PORT_VXLAN : parse_vxlan;
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
            UDP_PORT_VXLAN : parse_vxlan;
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
            ETHERTYPE_IPV4 : parse_ipv4;
            ETHERTYPE_IPV6 : parse_inner_ipv6;
            default : accept;
        }
    }

    state parse_ipv4 {
        pkt.extract(hdr.ipv4);
        transition select(hdr.ipv4.protocol) {
            UDP_PROTO : parse_udpv4;
            default : accept;
        }
    }

    state parse_udpv4 {
        pkt.extract(hdr.udpv4);
        transition select(hdr.udpv4.dstPort) {
            UDP_PORT_VXLAN : parse_vxlan;
            default : accept;
        }
    }

    state parse_inner_ipv6 {
        pkt.extract(hdr.inner_ipv6);
        transition select(hdr.inner_ipv6.nextHdr) {
            UDP_PROTO : parse_inner_udp;
            default : accept;
        }
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
        transition parse_vxlan_inner_ether;
    }

    state parse_vxlan_inner_ether {
        pkt.extract(hdr.vxlan_inner_ethernet);
        transition select(hdr.vxlan_inner_ethernet.etherType) {
            ETHERTYPE_IPV6 : parse_vxlan_inner_ipv6;
            ETHERTYPE_IPV4 : parse_vxlan_inner_ipv4;
            default : accept;
        }
    }

    state parse_vxlan_inner_ipv4 {
        pkt.extract(hdr.vxlan_inner_ipv4);
        transition accept;
    }

    state parse_vxlan_inner_ipv6 {
        pkt.extract(hdr.vxlan_inner_ipv6);
        transition select(hdr.vxlan_inner_ipv6.nextHdr) {
            UDP_PROTO : parse_vxlan_inner_udp;
            default : accept;
        }
    }

    state parse_vxlan_inner_udp {
        pkt.extract(hdr.vxlan_inner_udp);
        transition accept;
    }

}

/* Egress Deparser */
control SwitchEgressDeparser(
        packet_out pkt,
        inout header_t hdr,
        in egress_metadata_t eg_md,
        in egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr) {

    EgressMirror() egress_mirror;
    Checksum() ipv4_checksum;
    Checksum() vxlan_inner_ipv4_checksum;

    apply {
        egress_mirror.apply(eg_md, eg_intr_md_for_dprsr);

        /* Update IPv4 Checksum */
        hdr.ipv4.hdrChecksum = ipv4_checksum.update({
            hdr.ipv4.version,
            hdr.ipv4.ihl,
            hdr.ipv4.diffserv,
            hdr.ipv4.totalLen,
            hdr.ipv4.identification,
            hdr.ipv4.flags,
            hdr.ipv4.fragOffset,
            hdr.ipv4.ttl,
            hdr.ipv4.protocol,
            hdr.ipv4.srcAddr,
            hdr.ipv4.dstAddr});

        /* Update VxLAN inner IPv4 Checksum */
        hdr.vxlan_inner_ipv4.hdrChecksum = vxlan_inner_ipv4_checksum.update({
            hdr.vxlan_inner_ipv4.version,
            hdr.vxlan_inner_ipv4.ihl,
            hdr.vxlan_inner_ipv4.diffserv,
            hdr.vxlan_inner_ipv4.totalLen,
            hdr.vxlan_inner_ipv4.identification,
            hdr.vxlan_inner_ipv4.flags,
            hdr.vxlan_inner_ipv4.fragOffset,
            hdr.vxlan_inner_ipv4.ttl,
            hdr.vxlan_inner_ipv4.protocol,
            hdr.vxlan_inner_ipv4.srcAddr,
            hdr.vxlan_inner_ipv4.dstAddr});

        pkt.emit(hdr.dp_ctrl_hdr);
        pkt.emit(hdr.ethernet);
        pkt.emit(hdr.vlan);
        pkt.emit(hdr.ipv6);
        pkt.emit(hdr.udp);
        pkt.emit(hdr.knf);
        pkt.emit(hdr.postcard_header);
        pkt.emit(hdr.inner_ethernet);
        pkt.emit(hdr.ipv4);
        pkt.emit(hdr.udpv4);
        pkt.emit(hdr.inner_ipv6);
        pkt.emit(hdr.inner_udp);
        pkt.emit(hdr.vxlan);
        pkt.emit(hdr.vxlan_inner_ethernet);
        pkt.emit(hdr.vxlan_inner_ipv4);
        pkt.emit(hdr.vxlan_inner_ipv6);
        pkt.emit(hdr.vxlan_inner_udp);
    }
}
# 18 "leaf.p4" 2
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



/* TODO: merge vnet_smac tables into one big table */



/* 128 kvteps x 128 remote_vteps */
# 33 "hw_defs.h"
/* ID of the destination IP address of HOSTDEV */






/* Max LAG group size */
# 14 "leaf_profile.p4" 2


const bit<32> L2_INGRESS_TABLE_SIZE = 1024;
const bit<32> PORT_FAILOVER_TABLE_SIZE = 32768;
const bit<32> ROUTING_IPV6_TABLE_SIZE = 2048;
const bit<32> ECMP_GROUPS_TABLE_SIZE = 1024;
const bit<32> ECMP_SELECTION_TABLE_SIZE = 16384;
const bit<32> ECMP_SELECTION_MAX_GROUP_SIZE = 128;
const bit<32> NH_TABLE_SIZE = 512;
const bit<32> L2_EGRESS_TABLE_SIZE = 512;

/* L2 service tables */
const bit<32> INGRESS_PORT_PROPERTIES_TABLE_SIZE = 265;
const bit<32> VLAN_TO_VNET_MAPPING_TABLE_SIZE = 6001;
const bit<32> VNET_EGRESS_TABLE_SIZE = VLAN_TO_VNET_MAPPING_TABLE_SIZE;
const bit<32> VNET_SMAC_REMOTE_TABLE_SIZE = 501;
const bit<32> VNET_SMAC_LOCAL_PORT_TABLE_SIZE = 30720;
const bit<32> VNET_DMAC_TABLE_SIZE = 24576;
const bit<32> EGRESS_PORTS_TABLE_SIZE = 260;
const bit<32> LAG_GROUPS_TABLE_SIZE = 260;
const bit<32> LAG_SELECTION_TABLE_SIZE = 1024;
const bit<32> LAG_SELECTION_MAX_GROUP_SIZE = 4;
const bit<32> KVS_REWRITE_TABLE_SIZE = 128;
const bit<32> REMOTE_LAGS_TABLE_SIZE = 64;
const bit<32> LAG_TO_VLAN_MAPPING_TABLE_SIZE = 8192;
const bit<32> LAG_STATE_TABLE_SIZE = 512;
const bit<32> RID_TABLE_SIZE = 20000;
const bit<32> KNID_TO_MC_GRP_MAPPING_TABLE_SIZE = 10000;
const bit<32> KNF_LEARN_FLAG_TABLE_SIZE = 5;
const bit<32> USER_PUNT_TABLE_SIZE = 128;
const bit<32> KNF_DST_IP_IS_LOCAL_TABLE_SIZE = 128;
const bit<32> KNF_REWRITE_TABLE_SIZE = 128;
const bit<32> LAG_FAILOVER_TABLE_SIZE = 512;

/* L3 service tables */
const bit<32> VROUTER_L3_EXACT_TABLE_SIZE = 23552;
const bit<32> VROUTER_L3_TABLE_SIZE = 14336;
const bit<32> VROUTER_NEIGH_TABLE_SIZE = 4096;
const bit<32> VROUTER_IFACES_TABLE_SIZE = 2048;
const bit<32> PUNT_TUNNEL_STATS_TABLE_SIZE = 256;

/* L3 service VxLAN tables */
const bit<32> KVTEP_ONETS_TABLE_SIZE = 8192;
const bit<32> KVTEP_ONET_SMAC_TABLE_SIZE = 4096;
const bit<32> KVTEP_REMOTE_VTEPS_TABLE_SIZE = 2048;

/* INT */
const bit<32> TEL_FLOW_WATCHLIST_TABLE_SIZE = 1024;

/* Port failover */
const bit<32> port_failover_register_instance_count = 131072;
const bit<32> lag_failover_reg_instance_count = 131072;
# 19 "leaf.p4" 2
# 1 "core/modules/port.p4" 1
/****************************************************************
 * Copyright (c) Kaloom, 2019
 *
 * This unpublished material is property of Kaloom Inc.
 * All rights reserved.
 * Reproduction or distribution, in whole or in part, is
 * forbidden except by express written permission of Kaloom Inc.
 ****************************************************************/




# 1 "./core/types.p4" 1
/****************************************************************
 * Copyright (c) Kaloom, 2019
 *
 * This unpublished material is property of Kaloom Inc.
 * All rights reserved.
 * Reproduction or distribution, in whole or in part, is
 * forbidden except by express written permission of Kaloom Inc.
 ****************************************************************/
# 14 "core/modules/port.p4" 2

control IngressPortProperties(
        inout header_t hdr,
        inout ingress_metadata_t ig_md,
        in ingress_intrinsic_metadata_t ig_intr_md)
        (bit<32> ingress_port_properties_table_size) {

    action recirc_port_properties() {
        ig_md.fabric_meta.lkp_ipv6_addr = hdr.ipv6.dstAddr;
    }

    apply {
        if ((ig_intr_md.ingress_port & 0x7f) == RECIRC_PORT_PIPE_0) {
            recirc_port_properties();
        }
    }
}
# 20 "leaf.p4" 2
# 1 "core/modules/l2.p4" 1
/****************************************************************
 * Copyright (c) Kaloom, 2019
 *
 * This unpublished material is property of Kaloom Inc.
 * All rights reserved.
 * Reproduction or distribution, in whole or in part, is
 * forbidden except by express written permission of Kaloom Inc.
 ****************************************************************/




# 1 "./core/types.p4" 1
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
        inout header_t hdr,
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
                hdr.udpv4.srcPort,
                hdr.udpv4.dstPort,
                hdr.tcp.srcPort,
                hdr.tcp.dstPort,
                hdr.ipv4.srcAddr,
                hdr.ipv4.dstAddr,
                hdr.ipv4.protocol});
    }

    /* Hashing for IPv6 packet.
     * This hash is used for ECMP later in the underlay routing.
     */
    action compute_ipv6_hash() {
        ig_md.fabric_meta.flow_hash = flow_hash_ipv6.get({
                hdr.udp.srcPort,
                hdr.udp.dstPort,
                hdr.tcp.srcPort,
                hdr.tcp.dstPort,
                hdr.ipv6.srcAddr,
                hdr.ipv6.dstAddr,
                hdr.ipv6.nextHdr});
    }

    apply {
        if (hdr.ipv4.isValid()) {
            compute_ipv4_hash();
        } else if (hdr.ipv6.isValid()) {
            compute_ipv6_hash();
        }
    }
}

control KnfType(inout header_t hdr,
                inout ingress_metadata_t ig_md)() {

    action set_type_knf() {
        ig_md.ktep_meta.ingress_pkt_type = PKT_TYPE_KNF;
        ig_md.ktep_meta.src_mac = hdr.inner_ethernet.srcAddr;
        ig_md.ktep_meta.dst_mac = hdr.inner_ethernet.dstAddr;
    }

    apply {
        if (ig_md.ktep_meta.is_knf_udp_port == 1) {
            set_type_knf();
        }
    }
}

control KnfPackets(
        inout header_t hdr,
        inout ingress_metadata_t ig_md,
        in ingress_intrinsic_metadata_t ig_intr_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm)
        (bit<32> knids_table_size,
         bit<32>knf_dst_ip_is_local_table_size) {

    DirectCounter<bit<32>>(CounterType_t.PACKETS) set_nw_id_cntr;
    DirectCounter<bit<32>>(CounterType_t.PACKETS) knf_dst_ip_is_local_cntr;

    action set_nw_id_(nw_id_t nw_id) {
        set_nw_id_cntr.count();
        ig_md.ktep_meta.learn = 1;
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

    /* When the destination IP matches the local hostdev IP, the packet goes
     * through overlay L2 processing.
     */
    action knf_dst_ip_is_local_hit() {
        knf_dst_ip_is_local_cntr.count();
        ig_md.ktep_meta.process_l2 = 1;
        ig_md.ktep_meta.pkt_src = KTEP_SRC_LEAF;
    }

    /* The destination IP matches the link-local IP of an interface connected to
     * a KVS.
     */
    action knf_dst_ip_is_from_kvs_hit(iface_id_t lag_id) {
        knf_dst_ip_is_local_cntr.count();
        ig_md.ktep_meta.process_l2 = 1;
        ig_md.ktep_meta.is_from_kvs = 1;
        ig_md.ktep_meta.ingress_iface_id = lag_id;
        ig_md.ktep_meta.pkt_src = KTEP_SRC_KVS;
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
        ig_md.ktep_meta.lag_lkp_flag = 1; /* Perform lag_groups table lookup */
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
            knf_dst_ip_is_local_miss;
        }
        const default_action = knf_dst_ip_is_local_miss();
        size = knf_dst_ip_is_local_table_size;
        counters = knf_dst_ip_is_local_cntr;
    }

    apply {
        if (ig_md.ktep_meta.ingress_pkt_type == PKT_TYPE_KNF) {
            if (ig_intr_md.ingress_port == ig_md.fabric_meta.cpu_port) {
                set_nw_id.apply();
            } else {
                switch(knf_dst_ip_is_local.apply().action_run) {
                    knf_dst_ip_is_local_hit :
                    knf_dst_ip_is_lag_hit :
                    knf_dst_ip_is_from_kvs_hit : {
                        set_nw_id.apply();
                    }
                }
            }
        }
    }
}

control LagMapping(
        inout header_t hdr,
        inout ingress_metadata_t ig_md)
        (bit<32> lag_to_vlan_mapping_table_size) {

    action lag_to_vlan_mapping_vlan_hit(vlan_id_t vlan_id) {
        ig_md.ktep_meta.egress_vlan_id = vlan_id;
        ig_md.ktep_meta.egress_pkt_type = PKT_TYPE_VLAN;
        ig_md.fabric_meta.routing_lkp_flag = 0; /* Skip underlay routing */
        ig_md.ktep_meta.lag_lkp_flag = 1; /* Perform lag_groups table lookup */
    }

    action lag_to_vlan_mapping_untagged_hit() {
        ig_md.ktep_meta.egress_pkt_type = PKT_TYPE_UNTAGGED;
        ig_md.fabric_meta.routing_lkp_flag = 0; /* Skip underlay routing */
        ig_md.ktep_meta.lag_lkp_flag = 1; /* Perform lag_groups table lookup */
    }

    action lag_to_vlan_mapping_miss() {
    }

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

control PuntUserPackets(
        inout header_t hdr,
        inout ingress_metadata_t ig_md,
        in ingress_intrinsic_metadata_t ig_intr_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm)
        (bit<32> user_punt_table_size) {

    action user_punt_hit() {
        hdr.dp_ctrl_hdr.setValid();
        hdr.dp_ctrl_hdr.etherType = ETHERTYPE_DP_CTRL;
        hdr.dp_ctrl_hdr.port = (bit<16>)ig_intr_md.ingress_port;
        ig_intr_md_for_tm.ucast_egress_port = ig_md.fabric_meta.cpu_port;
        ig_intr_md_for_tm.bypass_egress = 1;
        exit;
    }

    action user_punt_miss() {}

    /* Based on the destination MAC, user_punt table sends user packet to the
     * host CPU. This is needed for LLDP and LACP packets received on a user port.
     */
    table user_punt {
        key = {
            hdr.ethernet.dstAddr : exact;
        }
        actions = {
            user_punt_hit;
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
        in ig_ktep_metadata_t ktep_meta,
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
        ig_intr_md_for_tm.bypass_egress = 1;
        exit;
    }

    /* This table filters user traffic arriving on a local LAG while the
     * Lag state is down. All user traffic should be dropped with the exception
     * of LACP traffic which is punted to the host. That's why it is important
     * to apply this table after user_punt block.
     */
    table lag_state {
        key = {
            ktep_meta.ingress_iface_id : exact;
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
        lag_state.apply();
    }
}

control VnetMapping(
        inout header_t hdr,
        inout ingress_metadata_t ig_md,
        inout ig_ktep_metadata_t ktep_meta,
        inout digest_type_t digest_type,
        in ingress_intrinsic_metadata_t ig_intr_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm,
        inout ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md)
        (bit<32> vnet_mapping_table_size) {

    DirectCounter<bit<64>>(CounterType_t.PACKETS_AND_BYTES) vlan_to_vnet_mapping_cntr;
    DirectCounter<bit<32>>(CounterType_t.PACKETS) kvs_multicast_cntr;

    /* Get the L2 network ID of the pair {port ID, VLAN ID} and set the ktep
     * metadata so that the packet goes through overlay processing (learning and
     * forwarding).
     */
    action vlan_to_vnet_mapping_hit(nw_id_t nw_id) {
        ig_md.ktep_meta.nw_id = nw_id;
        ig_md.ktep_meta.learn_nw_id = nw_id;
        ig_md.ktep_meta.learn = 1;
        ig_md.ktep_meta.process_l2 = 1;
        ig_md.ktep_meta.src_mac = hdr.ethernet.srcAddr;
        ig_md.ktep_meta.dst_mac = hdr.ethernet.dstAddr;
        vlan_to_vnet_mapping_cntr.count();
    }

    /* {port ID, VLAN ID} not registered to a KNID */
    action vlan_to_vnet_mapping_miss() {
        vlan_to_vnet_mapping_cntr.count();
    }

    /* vlan_to_vnet_mapping table is used to map a {port ID, VLAN ID} pair to a
     * network ID. For user untagged packets : VLAN ID == 0.
     */
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
    action kvs_multicast_hit() {
        kvs_multicast_cntr.count();
        digest_type = DIGEST_TYPE_KVS_MULTICAST_LEARNING;
        /* Send to Host CPU */
        hdr.dp_ctrl_hdr.setValid();
        hdr.dp_ctrl_hdr.etherType = ETHERTYPE_DP_CTRL;
        hdr.dp_ctrl_hdr.port = (bit<16>)ig_intr_md.ingress_port;
        ig_intr_md_for_tm.ucast_egress_port = ig_md.fabric_meta.cpu_port;
        ig_intr_md_for_tm.bypass_egress = 1;
        exit;
    }

    /* Packets that do not match the KVS multicast address are dropped. */
    action kvs_multicast_miss() {
        kvs_multicast_cntr.count();
        ig_dprsr_md.drop_ctl = DROP_CTL_ALL;
        ig_intr_md_for_tm.bypass_egress = 1;
        exit;
    }

    /* Check if the packet destination IP is the multicast address used by KVS */
    table kvs_multicast {
        key = {
            hdr.ipv6.dstAddr : exact;
        }
        actions = {
            kvs_multicast_hit;
            kvs_multicast_miss;
        }
        const default_action = kvs_multicast_miss;
        size = 2;
        counters = kvs_multicast_cntr;
    }

    apply {
        /* Apply tables to find which network ID the user packet belongs to */
        if (!vlan_to_vnet_mapping.apply().hit) {
            kvs_multicast.apply();
        }
    }
}

control VnetLearning(
        inout header_t hdr,
        inout ingress_metadata_t ig_md,
        inout digest_type_t digest_type,
        in ingress_intrinsic_metadata_t ig_intr_md)
        (bit<32> vnet_smac_remote_table_size,
        bit<32> vnet_smac_local_port_table_size) {

    /* Entry already exists. Do nothing */
    action vnet_smac_remote_hit() {}

    /* Entry does not exist. Go to vnet_learn_smac_fabric_port */
    action vnet_smac_remote_miss() {}

    /* vnet_smac_remote table is used to learn the hosts that are connected to
     * the fcn0 virtual network on a remote leaf (KNF.doNotLearn == 0).
     * The other remote MACs are learned via  DLS (Distributed Learning Service)
     * but are not added into this table (only to vnet_dmac table).
     */
     @ternary(1)
    table vnet_smac_remote {
        key = {
            ig_md.ktep_meta.nw_id : exact;
            ig_md.ktep_meta.src_mac : exact;
            hdr.ipv6.srcAddr : exact;
        }
        actions = {
            vnet_smac_remote_hit;
            @defaultonly vnet_smac_remote_miss;
        }
        const default_action = vnet_smac_remote_miss;
        size = vnet_smac_remote_table_size;
        idle_timeout = true;
    }

    /* vnet_learn_smac_fabric_port action is called upon a vnet_smac_remote_miss
     * when the port is a fabric port to set the digest type to
     * REMOTE_MAC_LEARNING.
     */
    action vnet_learn_smac_fabric_port() {
        digest_type = DIGEST_TYPE_REMOTE_MAC_LEARNING;
    }

    /* Entry exists. Do nothing */
    action vnet_smac_local_port_hit() {}

    /* Entry does not exist. Go to vnet_learn_smac_local_port */
    action vnet_smac_local_port_miss() {}

    /* vnet_smac_local_port table is used to learn the hosts that are connected
     * to a given virtual network on a local user port. It also detects user MAC
     * migration.
     */
    table vnet_smac_local_port {
        key = {
            ig_md.ktep_meta.ingress_iface_id : exact;
            ig_md.ktep_meta.nw_id : exact;
            ig_md.ktep_meta.src_mac : exact;
            ig_md.ktep_meta.ingress_vlan_id : exact;
        }
        actions = {
            vnet_smac_local_port_hit;
            vnet_smac_local_port_miss;
        }
        const default_action = vnet_smac_local_port_miss;
        size = vnet_smac_local_port_table_size;
        idle_timeout = true;
    }

    /* vnet_learn_smac_user_port action is called upon a vnet_smac_local_port_miss
     * when the port is a user port to set the digest type to LOCAL_MAC_LEARNING.
     */
    action vnet_learn_smac_user_port() {
        digest_type = DIGEST_TYPE_LOCAL_MAC_LEARNING;
    }

    apply {
        if (ig_md.ktep_port_meta.port_type == PORT_TYPE_FABRIC) {
            if (!vnet_smac_remote.apply().hit) {
                vnet_learn_smac_fabric_port();
            }
        } else if (ig_md.ktep_port_meta.port_type == PORT_TYPE_USER) {
            if (!vnet_smac_local_port.apply().hit) {
                vnet_learn_smac_user_port();
            }
        }
    }
}

control VnetCPU(
        inout header_t hdr,
        inout ingress_metadata_t ig_md,
        in ingress_intrinsic_metadata_t ig_intr_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm)
        (bit<32> knf_learn_flag_table_size) {

    BypassAndExit() bypass_and_exit;

    action knf_learn_flag_hit() {}

    action knf_learn_flag_miss() {
        hdr.knf.doNotLearn = 1;
    }

    /* knf_learn_flag enables remote learning on configured knids.
     * At present, this applies only to the fcn0 network.
     */
    table knf_learn_flag {
        key = {
            ig_md.ktep_meta.nw_id : exact;
        }
        actions = {
            knf_learn_flag_hit;
            knf_learn_flag_miss;
        }
        const default_action = knf_learn_flag_miss;
        size = knf_learn_flag_table_size;
    }

    apply {
        if (ig_intr_md.ingress_port == ig_md.fabric_meta.cpu_port) {
            knf_learn_flag.apply();
            bypass_and_exit.apply(ig_intr_md_for_tm);
        }
    }
}

control VnetExclusion(
        inout header_t hdr,
        inout ingress_metadata_t ig_md,
        in ingress_intrinsic_metadata_t ig_intr_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm)
        (bit<32> remote_vteps_v6_xid_table_size,
         bit<32> remote_vteps_v4_xid_table_size,
         bit<32> vrouter_ifaces_table_size) {

    action set_vtep_xid(exclusion_id_t xid) {
        ig_intr_md_for_tm.level1_exclusion_id = xid;
    }

    @ternary(1)
    table vtep_v6_xid {
        key = {
            ig_md.kvtep_meta.kvtep_id : exact;
            hdr.ipv6.srcAddr : exact;
        }
        actions = {
            set_vtep_xid;
        }
        size = remote_vteps_v6_xid_table_size;
    }

    @ternary(1)
    table vtep_v4_xid {
        key = {
            ig_md.kvtep_meta.kvtep_id : exact;
            hdr.ipv4.srcAddr : exact;
        }
        actions = {
            set_vtep_xid;
        }
        size = remote_vteps_v4_xid_table_size;
    }

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

    /* Set L1 exclusion ID to avoid flooding to other remote leafs if packet
     * gets replicated.
     */
    action set_leafs_xid() {
        ig_intr_md_for_tm.level1_exclusion_id = 4097;
    }

    apply {
        if ((hdr.vxlan.isValid()) &&
            (ig_md.ktep_meta.ingress_pkt_type != PKT_TYPE_KNF)) {
         if (hdr.ipv4.isValid()) {
                vtep_v4_xid.apply();
         } else {
                vtep_v6_xid.apply();
         }
        } else if (ig_md.ktep_meta.received_on_punt_channel == 1) {
            punt_xid.apply();
        } else if (ig_md.ktep_meta.pkt_src == KTEP_SRC_LEAF) {
            set_leafs_xid();
        }
    }
}

control VnetDmac(
        inout header_t hdr,
        inout ingress_metadata_t ig_md,
        inout ig_ktep_metadata_t ktep_meta,
        inout ig_fabric_metadata_t fabric_meta,
        in ingress_intrinsic_metadata_t ig_intr_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm,
        inout ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md)
        (bit<32> vnet_dmac_table_size,
         bit<32> knid_to_mc_grp_mapping_table_size) {

    Hash<bit<16>>(HashAlgorithm_t.CRC16) mcast_hash_l1;
    Hash<bit<16>>(HashAlgorithm_t.CRC16) mcast_hash_l2;

    /* The destination MAC is known and it belongs to a host connected to a
     * local port with a VLAN ID.
     */
    action vnet_dmac_local_port_vlan_hit(iface_id_t iface_id, vlan_id_t vlan_id) {
        ig_md.ktep_meta.egress_vlan_id = vlan_id;
        ig_md.ktep_meta.egress_iface_id = iface_id;
        ig_md.ktep_meta.egress_pkt_type = PKT_TYPE_VLAN;
        ig_md.fabric_meta.routing_lkp_flag = 0; /* Skip underlay routing */
        ig_md.ktep_meta.lag_lkp_flag = 1;
    }

    /* The destination MAC is known and it belongs to a host connected to a
     * local user port with no VLAN.
     */
    action vnet_dmac_local_port_untagged_hit(iface_id_t iface_id) {
        ig_md.ktep_meta.egress_iface_id = iface_id;
        ig_md.ktep_meta.egress_pkt_type = PKT_TYPE_UNTAGGED;
        ig_md.fabric_meta.routing_lkp_flag = 0; /* Skip underlay routing */
        ig_md.ktep_meta.lag_lkp_flag = 1;
    }

    /* The destination MAC is known and it belongs to a host connected to a
     * remote leaf.
     */
    action vnet_dmac_remote_leaf_hit(dest_id_t remote_leaf_id,
            ipv6_addr_t remote_leaf_ip) {
        ig_md.ktep_meta.dest_id = remote_leaf_id;
        ig_md.ktep_meta.egress_pkt_type = PKT_TYPE_KNF;
        ig_md.fabric_meta.lkp_ipv6_addr = remote_leaf_ip;
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
    action vnet_dmac_remote_vtep_local_router_hit(kvtep_id_t kvtep_id,
            kvtep_id_t remote_vtep_id, nw_id_t kvtep_nw_id) {
        ig_md.kvtep_meta.kvtep_id = kvtep_id;
        ig_md.kvtep_meta.remote_vtep_id = remote_vtep_id;
        ig_md.kvtep_meta.process_egress = 1;
        ig_md.kvtep_meta.egress_pkt_type = KVTEP_PKT_TYPE_VXLAN;

        ig_md.ktep_meta.egress_pkt_type = PKT_TYPE_KNF;
        ig_md.ktep_meta.dest_id = 1;
        ig_md.ktep_meta.nw_id = kvtep_nw_id;

        ig_md.fabric_meta.routing_lkp_flag = 0;
        /* Recirculate in current pipe. */
        ig_intr_md_for_tm.ucast_egress_port[8:7] = (bit<2>)(ig_intr_md.ingress_port >> 7);
        ig_intr_md_for_tm.ucast_egress_port[6:0] = (bit<7>)RECIRC_PORT_PIPE_0;
    }

    /* The destination MAC is known and it belongs to a host connected to a
     * remote vtep via a remote vrouter.
     */
    action vnet_dmac_remote_vtep_remote_router_hit(kvtep_id_t kvtep_id,
            kvtep_id_t remote_vtep_id, ipv6_addr_t kvtep_leaf_ip,
            dest_id_t kvtep_leaf_id, nw_id_t kvtep_nw_id) {
        ig_md.kvtep_meta.kvtep_id = kvtep_id;
        ig_md.kvtep_meta.remote_vtep_id = remote_vtep_id;
        ig_md.kvtep_meta.process_egress = 1;
        ig_md.kvtep_meta.egress_pkt_type = KVTEP_PKT_TYPE_VXLAN;

        ig_md.ktep_meta.egress_pkt_type = PKT_TYPE_KNF;
        ig_md.ktep_meta.dest_id = kvtep_leaf_id;
        ig_md.ktep_meta.nw_id = kvtep_nw_id;

        ig_md.fabric_meta.lkp_ipv6_addr = kvtep_leaf_ip;
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
            vnet_dmac_local_port_vlan_hit;
            vnet_dmac_local_port_untagged_hit;
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
        ig_intr_md_for_tm.bypass_egress = 1;
        exit;
    }

    /* Drop the packet when it's a KNF packet, not received on the punt channel
     * and the result action from vnet_dmac is to send it to a remote leaf.
     * This avoids a loop in the L2 network.
     */
    action remote_redirect() {
        ig_dprsr_md.drop_ctl = DROP_CTL_ALL;
        ig_intr_md_for_tm.bypass_egress = 1;
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
            fabric_meta.lkp_ipv6_addr : exact;
        }
        actions = {
            local_redirect;
            remote_redirect;
        }
        const default_action = remote_redirect;
        size = 2;
    }

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

    /* Get multicast group ID for a given network ID */
    action knid_to_mc_grp_mapping_hit(mcast_grp_id_t mcast_grp) {
        ig_intr_md_for_tm.mcast_grp_a = mcast_grp;
        compute_level1_hash();
        compute_level2_hash();
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
            vnet_dmac_local_port_untagged_hit : {
                if ((ig_md.ktep_meta.pkt_src == KTEP_SRC_LEAF) &&
                        (ig_md.ktep_meta.received_on_punt_channel == 0) &&
                        ((ig_md.ktep_meta.egress_iface_id & LAG_MSB) == LAG_MSB)) {
                    vnet_dmac_drop_();
                }
            }

            vnet_dmac_local_port_vlan_hit : {
                if ((ig_md.ktep_meta.pkt_src == KTEP_SRC_LEAF) &&
                        (ig_md.ktep_meta.received_on_punt_channel == 0) &&
                        ((ig_md.ktep_meta.egress_iface_id & LAG_MSB) == LAG_MSB)) {
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
        }
    }
}

control LagFailover(
        inout header_t hdr,
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
        ig_tm_md.bypass_egress = 1;
        exit;
    }

    action lag_failover_miss() {
        lag_failover_cntr.count();
    }

    /* This table must be placed in the same stage as lag_groups table as they
     * both have access to the same register.
     */
    @stage(9)
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
        inout header_t hdr,
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

    Hash<bit<16>>(HashAlgorithm_t.CRC16) selector_hash;
    ActionProfile(lag_selection_table_size) lag_selector;
    ActionSelector(lag_selector, selector_hash, SelectorMode_t.FAIR,
            lag_failover_reg, lag_selection_max_group_size,
            lag_groups_table_size) lag_selector_sel;


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
        ig_intr_md_for_tm.bypass_egress = 1;
        exit;
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
    }

    action lag_groups_miss() {}

    /* With LAG, for each egress_iface_id it is possible to have multiple egress
     * hardware ports where only one port will be selected via the lag_selector
     * and the hashing of a list of metadata fields.
     */
    @stage(9)
    table lag_groups {
        key = {
            ktep_meta.egress_iface_id : exact;
            ktep_meta.flow_hash : selector;
        }
        actions = {
            lag_groups_hit;
            lag_groups_miss;
        }
        size = lag_groups_table_size;
        implementation = lag_selector_sel;
        const default_action = lag_groups_miss();
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
        ig_intr_md_for_tm.bypass_egress = 1;
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
        ig_intr_md_for_tm.bypass_egress = 1;
        exit;
    }

    apply {
        kvs_ingress.apply();
        lag_state_egress.apply();

        if (!egress_ports.apply().hit) {
            lag_groups.apply();
            if (ig_intr_md_for_tm.ucast_egress_port == 0) {
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

control VnetCopyVlan(
        inout header_t hdr,
        inout egress_metadata_t eg_md)() {

    action copy_vlan() {
        eg_md.ktep_meta.vlan_etherType = hdr.vlan.etherType;
    }

    /* We need to recopy the source vlan_id from the packet to the metadata
     * because ktep_meta.ingress_vlan_id is not bridged from ingress pipeline
     * to egress pipeline otherwise the code wouldn't compile as the metadata
     * wouldn't fit in the PHV-containers.
     */
    apply {
        if (hdr.vlan.isValid()) {
            copy_vlan();
        }
    }
}

control VnetEgressVLANCntr(
        inout header_t hdr,
        inout egress_metadata_t eg_md,
        inout eg_ktep_metadata_t ktep_meta,
        in egress_intrinsic_metadata_t eg_intr_md,
        inout egress_intrinsic_metadata_for_deparser_t eg_dprsr_md)
        (bit<32> vnet_egress_table_size) {

    DirectCounter<bit<64>>(CounterType_t.PACKETS_AND_BYTES) vnet_egress_cntr;

    /* Push a vlan header */
    action ktep_add_vlan_() {
        hdr.vlan.setValid();
        hdr.vlan.etherType = hdr.ethernet.etherType;
        hdr.ethernet.etherType = ETHERTYPE_VLAN;
        hdr.vlan.vlanID = eg_md.ktep_meta.egress_vlan_id;
        hdr.vlan.pcp = 0;
        hdr.vlan.cfi = 0;
    }

    /* Update vlan ID on existing vlan header */
    action ktep_set_vlan_() {
        hdr.vlan.vlanID = eg_md.ktep_meta.egress_vlan_id;
    }

    /* Remove vlan header and copy vlan ethertype to outer ethernet ethertype. */
    action pop_vlan_() {
        hdr.ethernet.etherType = hdr.vlan.etherType;
        hdr.vlan.setInvalid();
    }

    /* On miss the packet doesn't need further modifications */
    action ktep_output_pkt_miss() {}

    /* This table is used after decapsulation or for local switching */
    table ktep_output_pkt {
        key = {
            ktep_meta.ingress_pkt_type : exact;
            ktep_meta.egress_pkt_type : exact;
        }
        actions = {
            pop_vlan_;
            ktep_set_vlan_;
            ktep_add_vlan_;
            ktep_output_pkt_miss;
        }
        const entries = {
            (0, 0) : ktep_output_pkt_miss();
            (1, 0) : pop_vlan_();
            (1, 1) : ktep_set_vlan_();
            (0, 1) : ktep_add_vlan_();
            (2, 1) : ktep_add_vlan_();
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
# 21 "leaf.p4" 2
# 1 "core/modules/l3_vxlan.p4" 1
/****************************************************************
 * Copyright (c) Kaloom, 2019
 *
 * This unpublished material is property of Kaloom Inc.
 * All rights reserved.
 * Reproduction or distribution, in whole or in part, is
 * forbidden except by express written permission of Kaloom Inc.
 ****************************************************************/




# 1 "./core/types.p4" 1
/****************************************************************
 * Copyright (c) Kaloom, 2019
 *
 * This unpublished material is property of Kaloom Inc.
 * All rights reserved.
 * Reproduction or distribution, in whole or in part, is
 * forbidden except by express written permission of Kaloom Inc.
 ****************************************************************/
# 14 "core/modules/l3_vxlan.p4" 2

/* kvtep ingress processing is part of the vrouter ingress block */
control OnetMappingAndLearning(
        inout header_t hdr,
        inout ingress_metadata_t ig_md,
        inout digest_type_t digest_type,
        in ingress_intrinsic_metadata_t ig_intr_md,
        inout ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md)
        (bit<32> kvtep_onets_table_size,
         bit<32> kvtep_remote_vteps_table_size,
         bit<32> kvtep_onet_smac_table_size) {

    DirectCounter<bit<32>>(CounterType_t.PACKETS) kvtep_onets_cntr;
    DirectCounter<bit<32>>(CounterType_t.PACKETS) remote_vtep_v4_cntr;
    DirectCounter<bit<32>>(CounterType_t.PACKETS) onet_smac_cntr;

    action drop() {
        ig_dprsr_md.drop_ctl = DROP_CTL_ALL;
        exit;
    }

    /* Forward to an L2 Overlay Network */
    action kvtep_onets_hit(nw_id_t o_nw_id, bit<1> learn) {
        kvtep_onets_cntr.count();
        ig_md.ktep_meta.nw_id = o_nw_id;
        ig_md.ktep_meta.src_mac = hdr.vxlan_inner_ethernet.srcAddr;
        ig_md.ktep_meta.dst_mac = hdr.vxlan_inner_ethernet.dstAddr;
        ig_md.ktep_meta.process_l3 = 0;
        ig_md.kvtep_meta.process_egress = 1;
        ig_md.kvtep_meta.egress_pkt_type = KVTEP_PKT_TYPE_RAW;
        ig_md.kvtep_meta.learn_inner = learn;
    }

    action kvtep_onets_miss() {
        kvtep_onets_cntr.count();
    }

    /* Kvtep overlay networks. Each overlay network is identified by a VNI
     * and it is mapped to an OKNID (Overlay Network ID).
     */
    table kvtep_onets {
        key = {
            ig_md.kvtep_meta.kvtep_id : exact;
            ig_md.ktep_router_meta.dst_ipAddr : exact;
            hdr.vxlan.vni : exact;
        }
        actions = {
            kvtep_onets_hit;
            kvtep_onets_miss;
        }
        const default_action = kvtep_onets_miss;
        size = kvtep_onets_table_size;
        counters = kvtep_onets_cntr;
    }

    action remote_vtep_v4_hit(kvtep_id_t remote_vtep_id) {
        remote_vtep_v4_cntr.count();
        ig_md.kvtep_meta.remote_vtep_id = remote_vtep_id;
    }

    action remote_vtep_v4_miss() {
        remote_vtep_v4_cntr.count();
        drop();
    }

    table remote_vtep_v4 {
        key = {
            ig_md.kvtep_meta.kvtep_id : exact;
            hdr.ipv4.srcAddr : exact;
        }
        actions = {
            remote_vtep_v4_hit;
            remote_vtep_v4_miss;
        }
        const default_action = remote_vtep_v4_miss();
        size = kvtep_remote_vteps_table_size;
        counters = remote_vtep_v4_cntr;
    }

    action remote_vtep_v6_hit(kvtep_id_t remote_vtep_id) {
        ig_md.kvtep_meta.remote_vtep_id = remote_vtep_id;
    }

    action remote_vtep_v6_miss() {
        drop();
    }

    table remote_vtep_v6 {
        key = {
            ig_md.kvtep_meta.kvtep_id : exact;
            hdr.ipv6.srcAddr : exact;
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
            ig_md.kvtep_meta.remote_vtep_id : exact;
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
            hdr.ipv4.isValid() : exact;
            hdr.ipv6.isValid() : exact;
        }
        actions = {
            learn_remote_vtep_v4;
            learn_remote_vtep_v6;
        }
        size = 4;
        const entries = {
            (true, false) : learn_remote_vtep_v4();
            (false, true) : learn_remote_vtep_v6();
        }
    }

    apply {
        switch (kvtep_onets.apply().action_run) {
            kvtep_onets_hit : {
                if (hdr.ipv4.isValid()) {
                    remote_vtep_v4.apply();
                } else if (hdr.ipv6.isValid()) {
                    remote_vtep_v6.apply();
                }
                if (ig_md.kvtep_meta.learn_inner == 1) {
                    switch (onet_smac.apply().action_run) {
                        onet_smac_miss : {
                            learn_remote_vtep.apply();
                        }
                    }
                }
            }
        }
    }
}

control VxlanTunnel(
        inout header_t hdr,
        inout egress_metadata_t eg_md,
        in egress_intrinsic_metadata_t eg_intr_md,
        inout egress_intrinsic_metadata_for_deparser_t eg_dprsr_md)
        (bit<32> kvtep_encap_vxlan_table_size,
        bit<32> kvtep_rewrite_vxlan_knf_table_size,
        bit<32> kvtep_remotes_table_size) {

    DirectCounter<bit<32>>(CounterType_t.PACKETS) kvtep_decap_vxlan_cntr;

    action drop() {
        eg_dprsr_md.drop_ctl = DROP_CTL_ALL;
        exit;
    }

    action kvtep_copy_hdrs_ipv4() {
        hdr.vxlan_inner_ipv4 = hdr.ipv4;
        hdr.ipv4.setInvalid();
    }

    action kvtep_copy_hdrs_knf_ipv6() {
        hdr.vxlan_inner_ipv6 = hdr.inner_ipv6;
        hdr.inner_ipv6.setInvalid();
    }

    action kvtep_copy_hdrs_knf_ipv6_udp() {
        hdr.vxlan_inner_ipv6 = hdr.inner_ipv6;
        hdr.vxlan_inner_udp = hdr.inner_udp;
        hdr.inner_ipv6.setInvalid();
        hdr.inner_udp.setInvalid();
    }

    action kvtep_copy_hdrs_user_ipv6() {
        hdr.vxlan_inner_ipv6 = hdr.ipv6;
        hdr.ipv6.setInvalid();
    }

    action kvtep_copy_hdrs_user_ipv6_udp() {
        hdr.vxlan_inner_ipv6 = hdr.ipv6;
        hdr.vxlan_inner_udp = hdr.udp;
        hdr.ipv6.setInvalid();
        hdr.udp.setInvalid();
    }

    action kvtep_copy_hdrs_no_op() {}

    table kvtep_copy_hdrs {
        key = {
            hdr.ipv4.isValid() : exact;
            hdr.ipv6.isValid() : exact;
            hdr.inner_ipv6.isValid() : exact;
            hdr.udp.isValid() : exact;
            hdr.inner_udp.isValid() : exact;
            hdr.knf.isValid() : exact;
        }
        actions = {
            kvtep_copy_hdrs_ipv4;
            kvtep_copy_hdrs_user_ipv6;
            kvtep_copy_hdrs_user_ipv6_udp;
            kvtep_copy_hdrs_knf_ipv6;
            kvtep_copy_hdrs_knf_ipv6_udp;
            kvtep_copy_hdrs_no_op;
        }
        const entries = {
            (true, false, false, false, false, false) : kvtep_copy_hdrs_ipv4();
            (true, true, false, true, false, true) : kvtep_copy_hdrs_ipv4();
            (false, true, false, false, false, false) : kvtep_copy_hdrs_user_ipv6();
            (false, true, false, true, false, false) : kvtep_copy_hdrs_user_ipv6_udp();
            (false, true, false, true, false, true) : kvtep_copy_hdrs_no_op();
            (false, true, true, true, false, true) : kvtep_copy_hdrs_knf_ipv6();
            (false, true, true, true, true, true) : kvtep_copy_hdrs_knf_ipv6_udp();
        }
        const default_action = kvtep_copy_hdrs_no_op();
        size = 9;
    }

    /* Add VXLAN IPv6 header for a KNF packet */
    action kvtep_encap_vxlan_knf_v6(ipv6_addr_t kvtep_ip, mac_addr_t kvtep_mac) {
        hdr.vxlan_inner_ethernet = hdr.inner_ethernet;
        hdr.inner_ipv6.setValid();
        hdr.inner_udp.setValid();
        hdr.vxlan.setValid();

        /* Ethernet */
        hdr.inner_ethernet.dstAddr = kvtep_mac;
        hdr.inner_ethernet.srcAddr = 0;
        hdr.inner_ethernet.etherType = ETHERTYPE_IPV6;

        /* IPv6 */
        hdr.inner_ipv6.version = IPV6_VERSION;
        hdr.inner_ipv6.trafficClass = 0;
        hdr.inner_ipv6.flowLabel = 0;
        hdr.inner_ipv6.nextHdr = UDP_PROTO;
        hdr.inner_ipv6.hopLimit = HOP_LIMIT;
        hdr.inner_ipv6.srcAddr = kvtep_ip;
        hdr.inner_ipv6.payloadLen = eg_md.ktep_meta.payload_length - 4; /* VXLAN_SIZE - KNF_SIZE */

        /* UDP */
        hdr.inner_udp.srcPort = 0;
        hdr.inner_udp.dstPort = UDP_PORT_VXLAN;
        hdr.inner_udp.checksum = 0;
        hdr.inner_udp.hdrLen = eg_md.ktep_meta.payload_length - 4; /* VXLAN_SIZE - KNF_SIZE */

        /* VxLAN */
        hdr.vxlan.flags = 0x08; /* The VNI bit is set to 1 for a valid VNI. */

        /* KNF underlay IP */
        hdr.ipv6.payloadLen = eg_md.ktep_meta.payload_length + 70; /* ETH_SIZE + IPV6_SIZE + UDP_SIZE + VXLAN_SIZE */
        hdr.udp.hdrLen = eg_md.ktep_meta.payload_length + 70; /* ETH_SIZE + IPV6_SIZE + UDP_SIZE + VXLAN_SIZE */
    }

    action kvtep_encap_vxlan_knf_v4(ipv4_addr_t kvtep_ip, mac_addr_t kvtep_mac) {
        hdr.vxlan_inner_ethernet = hdr.inner_ethernet;
        hdr.ipv4.setValid();
        hdr.udpv4.setValid();
        hdr.vxlan.setValid();

        /* Ethernet */
        hdr.inner_ethernet.dstAddr = kvtep_mac;
        hdr.inner_ethernet.srcAddr = 0;
        hdr.inner_ethernet.etherType = ETHERTYPE_IPV4;

        /* IPv4 */
        hdr.ipv4.srcAddr = kvtep_ip;
        hdr.ipv4.version = IPV4_VERSION;
        hdr.ipv4.protocol = UDP_PROTO;
        hdr.ipv4.ttl = HOP_LIMIT;
        hdr.ipv4.ihl = 0x5;
        hdr.ipv4.diffserv = 0x0;
        hdr.ipv4.identification = 0x1;
        hdr.ipv4.flags = 0;
        hdr.ipv4.fragOffset = 0;
        hdr.ipv4.totalLen = eg_md.ktep_meta.payload_length + 16; /* VXLAN_SIZE - KNF_SIZE + IPV4_SIZE */

        /* UDP */
        hdr.udpv4.srcPort = 0;
        hdr.udpv4.dstPort = UDP_PORT_VXLAN;
        hdr.udpv4.checksum = 0;
        hdr.udpv4.hdrLen = eg_md.ktep_meta.payload_length - 4; /* VXLAN_SIZE - KNF_SIZE */

        /* VxLAN */
        hdr.vxlan.flags = 0x08; /* The VNI bit is set to 1 for a valid VNI. */

        /* KNF underlay IP */
        hdr.ipv6.payloadLen = eg_md.ktep_meta.payload_length + 50; /* ETH_SIZE + IPV4_SIZE + UDP_SIZE + VXLAN_SIZE */
        hdr.udp.hdrLen = eg_md.ktep_meta.payload_length + 50; /* ETH_SIZE + IPV4_SIZE + UDP_SIZE + VXLAN_SIZE */
    }

    action kvtep_encap_vxlan_knf_miss() {
        drop();
    }

    @ternary(1)
    table kvtep_encap_vxlan_knf {
        key = {
            eg_md.kvtep_meta.kvtep_id : exact;
        }
        actions = {
            kvtep_encap_vxlan_knf_v6;
            kvtep_encap_vxlan_knf_v4;
            kvtep_encap_vxlan_knf_miss;
        }
        const default_action = kvtep_encap_vxlan_knf_miss();
        size = kvtep_encap_vxlan_table_size;
    }

    action kvtep_rewrite_vxlan_knf_v6(ipv6_addr_t kvtep_ip, mac_addr_t kvtep_mac) {
        hdr.inner_udp.srcPort = 0;
        hdr.inner_udp.checksum = 0;
        hdr.inner_ethernet.dstAddr = kvtep_mac;
        hdr.inner_ipv6.srcAddr = kvtep_ip;
    }

    action kvtep_rewrite_vxlan_knf_v4(ipv4_addr_t kvtep_ip, mac_addr_t kvtep_mac) {
        hdr.inner_ethernet.dstAddr = kvtep_mac;
        hdr.ipv4.srcAddr = kvtep_ip;
        hdr.ipv4.ihl = 0x5;
        hdr.ipv4.identification = 0x1;
        hdr.udpv4.srcPort = 0;
        hdr.udpv4.checksum = 0;
    }

    action kvtep_rewrite_vxlan_knf_miss() {
        drop();
    }

    table kvtep_rewrite_vxlan_knf {
        key = {
            eg_md.kvtep_meta.kvtep_id : exact;
        }
        actions = {
            kvtep_rewrite_vxlan_knf_v6;
            kvtep_rewrite_vxlan_knf_v4;
            kvtep_rewrite_vxlan_knf_miss;
        }
        const default_action = kvtep_rewrite_vxlan_knf_miss();
        size = kvtep_rewrite_vxlan_knf_table_size;
    }

    action kvtep_remotes_hit_v6(vni_t vni, ipv6_addr_t remote_vtep_ip) {
        hdr.inner_ipv6.dstAddr = remote_vtep_ip;
        hdr.vxlan.vni = vni;
        eg_md.kvtep_meta.process_egress = 0;
    }

    action kvtep_remotes_hit_v4(vni_t vni, ipv4_addr_t remote_vtep_ip) {
        hdr.ipv4.dstAddr = remote_vtep_ip;
        hdr.vxlan.vni = vni;
        eg_md.kvtep_meta.process_egress = 0;
    }

    action kvtep_remotes_miss() {
        drop();
    }

    @ternary(1)
    table kvtep_remotes {
        key = {
            eg_md.kvtep_meta.kvtep_id : exact;
            eg_md.kvtep_meta.remote_vtep_id : exact;
        }
        actions = {
            kvtep_remotes_hit_v6;
            kvtep_remotes_hit_v4;
            kvtep_remotes_miss;
        }
        const default_action = kvtep_remotes_miss();
        size = kvtep_remotes_table_size;
    }

    action kvtep_decap_vxlan_() {
        kvtep_decap_vxlan_cntr.count();
        hdr.vxlan.setInvalid();
        hdr.vxlan_inner_ethernet.setInvalid();
    }

    /* Remove IPv4 VXLAN header of a KNF packet */
    action kvtep_decap_vxlan_knf_v4() {
        hdr.inner_ethernet = hdr.vxlan_inner_ethernet;
        hdr.ipv4.setInvalid();
        hdr.udpv4.setInvalid();
        /* ipv4 (20B) + udp (8B) + vxlan (8B) + vxlan_ethernet (14B) = 50B */
        hdr.ipv6.payloadLen = eg_md.ktep_meta.payload_length - 50;
        hdr.udp.hdrLen = eg_md.ktep_meta.payload_length - 50;
        kvtep_decap_vxlan_();
    }

    /* Remove IPv6 VXLAN header of a KNF packet */
    action kvtep_decap_vxlan_knf_v6() {
        hdr.inner_ethernet = hdr.vxlan_inner_ethernet;
        hdr.inner_ipv6.setInvalid();
        hdr.inner_udp.setInvalid();
        /* ipv6 (40B) + udp (8B) + vxlan (8B) + vxlan_ethernet (14B) = 70B */
        hdr.ipv6.payloadLen = eg_md.ktep_meta.payload_length - 70;
        hdr.udp.hdrLen = eg_md.ktep_meta.payload_length - 70;
        kvtep_decap_vxlan_();
    }

    /* Remove VXLAN header of a user IPv4 packet */
    action kvtep_decap_vxlan_user_v4() {
        hdr.ethernet = hdr.vxlan_inner_ethernet;
        hdr.ipv4.setInvalid();
        hdr.udpv4.setInvalid();
        kvtep_decap_vxlan_();
    }

    /* Remove VXLAN header of a user IPv6 packet */
    action kvtep_decap_vxlan_user_v6() {
        hdr.ethernet = hdr.vxlan_inner_ethernet;
        hdr.ipv6.setInvalid();
        hdr.udp.setInvalid();
        kvtep_decap_vxlan_();
    }

    action kvtep_decap_vlan_vxlan_user_v4() {
        hdr.ethernet = hdr.vxlan_inner_ethernet;
        eg_md.ktep_meta.ingress_pkt_type = PKT_TYPE_UNTAGGED;
        hdr.vlan.setInvalid();
        hdr.ipv4.setInvalid();
        hdr.udpv4.setInvalid();
        kvtep_decap_vxlan_();
    }

    action kvtep_decap_vlan_vxlan_user_v6() {
        hdr.ethernet = hdr.vxlan_inner_ethernet;
        eg_md.ktep_meta.ingress_pkt_type = PKT_TYPE_UNTAGGED;
        hdr.vlan.setInvalid();
        hdr.ipv6.setInvalid();
        hdr.udp.setInvalid();
        kvtep_decap_vxlan_();
    }

    action kvtep_decap_vxlan_miss() {
        kvtep_decap_vxlan_cntr.count();
        drop();
    }

    table kvtep_decap_vxlan {
        key = {
            hdr.vlan.isValid() : exact;
            hdr.knf.isValid() : exact;
            hdr.ipv4.isValid() : exact;
            hdr.udpv4.isValid() : exact;
            hdr.ipv6.isValid() : exact;
            hdr.udp.isValid() : exact;
            hdr.inner_ipv6.isValid() : exact;
            hdr.inner_udp.isValid() : exact;
        }
        actions = {
            kvtep_decap_vlan_vxlan_user_v4;
            kvtep_decap_vlan_vxlan_user_v6;
            kvtep_decap_vxlan_user_v4;
            kvtep_decap_vxlan_user_v6;
            kvtep_decap_vxlan_knf_v6;
            kvtep_decap_vxlan_knf_v4;
            kvtep_decap_vxlan_miss;
        }
        const default_action = kvtep_decap_vxlan_miss;
        size = 7;
        counters = kvtep_decap_vxlan_cntr;
        const entries = {
            (false, false, true, true, false, false, false, false) : kvtep_decap_vxlan_user_v4();
            (false, false, false, false, true, true, false, false) : kvtep_decap_vxlan_user_v6();
            (false, true, true, true, true, true, false, false) : kvtep_decap_vxlan_knf_v4();
            (false, true, false, false, true, true, true, true) : kvtep_decap_vxlan_knf_v6();
            (true, false, true, true, false, false, false, false) : kvtep_decap_vlan_vxlan_user_v4();
            (true, false, false, false, true, true, false, false) : kvtep_decap_vlan_vxlan_user_v6();
        }
    }

    action kvtep_copy_inner_vxlan_none() {} /* for ARP */

    action kvtep_copy_inner_vxlan_v4() {
        hdr.ipv4 = hdr.vxlan_inner_ipv4;
        hdr.vxlan_inner_ipv4.setInvalid();
    }

    action kvtep_copy_inner_vxlan_knf_v6() {
        hdr.inner_ipv6 = hdr.vxlan_inner_ipv6;
        hdr.vxlan_inner_ipv6.setInvalid();
    }

    action kvtep_copy_inner_vxlan_knf_udp_v6() {
        hdr.inner_ipv6 = hdr.vxlan_inner_ipv6;
        hdr.inner_udp = hdr.vxlan_inner_udp;
        hdr.vxlan_inner_ipv6.setInvalid();
        hdr.vxlan_inner_udp.setInvalid();
    }

    action kvtep_copy_inner_vxlan_user_v6() {
        hdr.ipv6 = hdr.vxlan_inner_ipv6;
        hdr.vxlan_inner_ipv6.setInvalid();
    }

    action kvtep_copy_inner_vxlan_user_udp_v6() {
        hdr.ipv6 = hdr.vxlan_inner_ipv6;
        hdr.udp = hdr.vxlan_inner_udp;
        hdr.vxlan_inner_ipv6.setInvalid();
        hdr.vxlan_inner_udp.setInvalid();
    }

    table kvtep_copy_inner_vxlan {
        key = {
            hdr.vxlan_inner_ipv4.isValid() : exact;
            hdr.vxlan_inner_ipv6.isValid() : exact;
            hdr.vxlan_inner_udp.isValid() : exact;
            hdr.knf.isValid() : exact;
        }
        actions = {
            kvtep_copy_inner_vxlan_v4;
            kvtep_copy_inner_vxlan_knf_v6;
            kvtep_copy_inner_vxlan_knf_udp_v6;
            kvtep_copy_inner_vxlan_user_v6;
            kvtep_copy_inner_vxlan_user_udp_v6;
            kvtep_copy_inner_vxlan_none;
        }
        const default_action = kvtep_copy_inner_vxlan_none();
        size = 9;
        const entries = {
            (true, false, false, false): kvtep_copy_inner_vxlan_v4();
            (true, false, false, true): kvtep_copy_inner_vxlan_v4();
            (false, true, false, false): kvtep_copy_inner_vxlan_user_v6();
            (false, true, true, false): kvtep_copy_inner_vxlan_user_udp_v6();
            (false, true, false, true): kvtep_copy_inner_vxlan_knf_v6();
            (false, true, true, true): kvtep_copy_inner_vxlan_knf_udp_v6();
            (false, false, false, true): kvtep_copy_inner_vxlan_none();
            (false, false, false, false): kvtep_copy_inner_vxlan_none();
        }
    }

    apply {
        if (eg_md.kvtep_meta.process_egress == 1) {
            if (eg_md.kvtep_meta.egress_pkt_type == KVTEP_PKT_TYPE_VXLAN) {
                if (!hdr.vxlan.isValid()) {
                    kvtep_copy_hdrs.apply();
                    kvtep_encap_vxlan_knf.apply();
                } else {
                    kvtep_rewrite_vxlan_knf.apply();
                }
                kvtep_remotes.apply();
            } else if (eg_md.kvtep_meta.egress_pkt_type == KVTEP_PKT_TYPE_RAW) {
                kvtep_decap_vxlan.apply();
                kvtep_copy_inner_vxlan.apply();
            }
        }
    }
}
# 22 "leaf.p4" 2
# 1 "core/modules/l3.p4" 1
/****************************************************************
 * Copyright (c) Kaloom, 2019
 *
 * This unpublished material is property of Kaloom Inc.
 * All rights reserved.
 * Reproduction or distribution, in whole or in part, is
 * forbidden except by express written permission of Kaloom Inc.
 ****************************************************************/




# 1 "./core/types.p4" 1
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
        inout header_t hdr,
        inout ingress_metadata_t ig_md,
        in ingress_intrinsic_metadata_t ig_intr_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm,
        inout ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md)
        (bit<32> vrouter_l3_exact_table_size,
         bit<32> vrouter_l3_table_size,
         bit<32> vrouter_ifaces_table_size,
         bit<32> vrouter_neigh_table_size) {

    DirectCounter<bit<32>>(CounterType_t.PACKETS) ktep_neigh_cntr;
    DirectCounter<bit<32>>(CounterType_t.PACKETS) vrouter_mtu_cntr;

    /* VxLAN ingress processing */
    OnetMappingAndLearning(KVTEP_ONETS_TABLE_SIZE,
        KVTEP_REMOTE_VTEPS_TABLE_SIZE,
        KVTEP_ONET_SMAC_TABLE_SIZE) onet_mapping_learning;

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

    action ktep_route_miss() {
        send_to_punt_channel();
        ig_md.ktep_router_meta.neigh_lkp = 0;
    }

    action ktep_exact_route_miss() {}

    /* Routing table for /128 (IPv6) or /32 (IPv4) entries */
    table ktep_l3_exact {
        key = {
            ig_md.ktep_router_meta.router_id : exact;
            ig_md.ktep_router_meta.dst_ipAddr: exact;
        }
        actions = {
            ktep_route_hit;
            ktep_route_dcn_hit;
            ktep_route_local_hit;
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
            ig_md.ktep_router_meta.dst_ipAddr: lpm;
        }
        actions = {
            ktep_route_hit;
            ktep_route_dcn_hit;
            ktep_route_local_hit;
            ktep_route_miss;
        }
        const default_action = ktep_route_miss();
        size = vrouter_l3_table_size;
    }

    /* Sets the destination MAC address of the user packet and prepares ktep
     * metadata for the next lookup in the vnet_dmac table.
     */
    action ktep_neigh_hit(mac_addr_t mac) {
        ktep_neigh_cntr.count();
        ig_md.ktep_meta.dst_mac = mac;
        ig_md.ktep_meta.process_l2 = 1;
        ig_md.ktep_router_meta.dst_mac = mac;
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
            ig_md.ktep_router_meta.dst_ipAddr: exact;
        }
        actions = {
            ktep_neigh_hit;
            ktep_neigh_miss;
        }
        const default_action = ktep_neigh_miss();
        size = vrouter_neigh_table_size;
        counters = ktep_neigh_cntr;
    }

    action decrement_ipv4_ttl() {
        hdr.ipv4.ttl = hdr.ipv4.ttl - 1;
    }

    action decrement_ipv6_hl() {
        hdr.ipv6.hopLimit = hdr.ipv6.hopLimit - 1;
    }

    action decrement_inner_ipv6_hl() {
        hdr.inner_ipv6.hopLimit = hdr.inner_ipv6.hopLimit - 1;
    }

    /* When ttl == 1 send packet to the control plane via the punt channel. */
    action last_hop_punt() {
        send_to_punt_channel();
    }

    /* When ttl == 0 then drop the packet. */
    action end_ttl() {
        ig_dprsr_md.drop_ctl = DROP_CTL_ALL;
        ig_intr_md_for_tm.bypass_egress = 1;
        exit;
    }

    /* This table performs the following TTL operations :
     *      Decrement TTL when ttl > 1.
     *      Send packet to remote control plane via punt tunnel when ttl == 1.
     *      Drop the packet when ttl == 0.
     */
    table decrement_user_ttl {
        key = {
            hdr.ipv4.isValid() : exact;
            hdr.ipv6.isValid() : exact;
            hdr.inner_ipv6.isValid() : exact;
            hdr.ipv4.ttl : ternary;
            hdr.ipv6.hopLimit : ternary;
            hdr.inner_ipv6.hopLimit : ternary;
        }
        actions = {
            decrement_ipv4_ttl;
            decrement_ipv6_hl;
            decrement_inner_ipv6_hl;
            last_hop_punt;
            end_ttl;
        }
        size = 20;
        /* TODO: Set TCAM priority for static entries */
        const entries = {
            (true, false, false, 0 & TTL_MASK, _, _) : end_ttl();
            (true, true, false, 0 & TTL_MASK, _, _) : end_ttl();
            (false, true, false, _, 0 & TTL_MASK, _) : end_ttl();
            (false, false, true, _, _, 0 & TTL_MASK) : end_ttl();
            (false, true, true, _, _, 0 & TTL_MASK) : end_ttl();

            (true, false, false, 1 & TTL_MASK, _, _) : last_hop_punt();
            (true, true, false, 1 & TTL_MASK, _, _) : last_hop_punt();
            (false, true, false, _, 1 & TTL_MASK, _) : last_hop_punt();
            (false, false, true, _, _, 1 & TTL_MASK) : last_hop_punt();
            (false, true, true, _, _, 1 & TTL_MASK) : last_hop_punt();

            (true, false, false, _, _, _) : decrement_ipv4_ttl();
            (true, true, false, _, _, _) : decrement_ipv4_ttl();
            (false, true, false, _, _, _) : decrement_ipv6_hl();
            (false, false, true, _, _, _) : decrement_inner_ipv6_hl();
            (false, true, true, _, _, _) : decrement_inner_ipv6_hl();
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

    apply {
        if (ig_md.ktep_router_meta.is_not_ip == 0) {
            /* VxLAN ingress processing */
            onet_mapping_learning.apply(hdr, ig_md, ig_dprsr_md.digest_type,
                ig_intr_md, ig_dprsr_md);
            /* Some L2 packets arriving from remote vtep will match the vRouter
             * KVtep interface but if they are not vxlan packets they will still
             * have ktep_meta.process_l3 == 1 because of vrouter_ifaces_hit.
             * Those packets should perform l2 services and bypass l3 vrouter
             * tables.
             */
            if ((ig_md.ktep_meta.process_l3 == 1) &&
                    (ig_md.ktep_router_meta.input_iface != 0x3F)) {
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
                            decrement_user_ttl.apply();
                            vrouter_mtu.apply();
                        }
                    }
                }
            }
        } else if (ig_md.ktep_router_meta.input_iface != 0x3F) {
            send_to_punt_channel();
        }
    }
}

control VRouter(
        inout header_t hdr,
        inout ingress_metadata_t ig_md,
        in ingress_intrinsic_metadata_t ig_intr_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm,
        inout ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md)
        (bit<32> vrouter_ifaces_table_size) {

    DirectCounter<bit<32>>(CounterType_t.PACKETS) pre_routing_cntr;
    DirectCounter<bit<64>>(CounterType_t.PACKETS_AND_BYTES) vrouter_ifaces_cntr;

    IngressVRouter(VROUTER_L3_EXACT_TABLE_SIZE,
        VROUTER_L3_TABLE_SIZE,
        VROUTER_IFACES_TABLE_SIZE,
        VROUTER_NEIGH_TABLE_SIZE) ingress_vrouter;

    /* Convert IPv4 to IPv6 to use the same LPM table */
    action copy_ipv4_addr_usr() {
        pre_routing_cntr.count();
        /* RFC4291 (IPv4-Mapped IPv6 Address). */
        ig_md.ktep_router_meta.dst_ipAddr[127:32] = 0xffff;
        ig_md.ktep_router_meta.dst_ipAddr[31:0] = hdr.ipv4.dstAddr;
        ig_md.ktep_router_meta.pkt_len = hdr.ipv4.totalLen + ETH_SIZE;
        ig_md.ktep_router_meta.is_not_ip = 0;
    }

    action copy_ipv4_addr_knf() {
        pre_routing_cntr.count();
        /* RFC4291 (IPv4-Mapped IPv6 Address). */
        ig_md.ktep_router_meta.dst_ipAddr[127:32] = 0xffff;
        ig_md.ktep_router_meta.dst_ipAddr[31:0] = hdr.ipv4.dstAddr;
        ig_md.ktep_router_meta.pkt_len = hdr.ipv6.payloadLen + 54; /* ETH_SIZE + IPV6_SIZE */
        ig_md.ktep_router_meta.is_not_ip = 0;
    }

    /* Copy ipv6 address to be used as key in LPM table */
    action copy_ipv6_addr() {
        pre_routing_cntr.count();
        ig_md.ktep_router_meta.dst_ipAddr = hdr.ipv6.dstAddr;
        ig_md.ktep_router_meta.pkt_len = hdr.ipv6.payloadLen + 54; /* ETH_SIZE + IPV6_SIZE */
        ig_md.ktep_router_meta.is_not_ip = 0;
    }

    /* Copy inner_ipv6 address to be used as key in LPM table */
    action copy_inner_ipv6_addr() {
        pre_routing_cntr.count();
        ig_md.ktep_router_meta.dst_ipAddr = hdr.inner_ipv6.dstAddr;
        ig_md.ktep_router_meta.pkt_len = hdr.inner_ipv6.payloadLen + 108; /* 2*(ETH_SIZE + IPV6_SIZE) */
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
            hdr.ipv4.isValid() : exact;
            hdr.ipv6.isValid() : exact;
            hdr.inner_ipv6.isValid() : exact;
        }
        actions = {
            copy_ipv4_addr_usr;
            copy_ipv4_addr_knf;
            copy_ipv6_addr;
            copy_inner_ipv6_addr;
            process_non_ip_pkts;
        }
        const default_action = process_non_ip_pkts;
        counters = pre_routing_cntr;
        size = 6;
        const entries = {
            (true, false, false) : copy_ipv4_addr_usr();
            (true, true, false) : copy_ipv4_addr_knf();
            (false, true, false) : copy_ipv6_addr();
            (false, true, true) : copy_inner_ipv6_addr();
            (false, false, false) : process_non_ip_pkts();
        }
    }

    action vrouter_ifaces_hit(vrouter_id_t router_id, vrouter_iface_id_t iface,
            dest_id_t punt_id) {
        vrouter_ifaces_cntr.count();
        ig_md.ktep_meta.dest_id = punt_id;
        ig_md.ktep_meta.process_l3 = 1;
        ig_md.ktep_meta.pkt_src = KTEP_SRC_OTHER;
        ig_md.ktep_router_meta.router_id = router_id;
        /* in case of vxlan interface kvtep ID is the vrouter ID */
        ig_md.kvtep_meta.kvtep_id = router_id;
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

    apply {
        if (ig_md.ktep_meta.process_l2 == 1) {
            pre_routing.apply();
            switch (vrouter_ifaces.apply().action_run) {
                vrouter_ifaces_hit : {
                    ingress_vrouter.apply(hdr, ig_md, ig_intr_md,
                        ig_intr_md_for_tm, ig_dprsr_md);
                }
            }
        }
    }
}

control VRouterPuntChannel(inout ingress_metadata_t ig_md)
        (bit<32> vrouter_ifaces_table_size) {

    DirectCounter<bit<32>>(CounterType_t.PACKETS) prepare_for_punt_tunnel_cntr;

    action set_punt_data(nw_id_t p_nw_id, ipv6_addr_t punt_ip) {
        prepare_for_punt_tunnel_cntr.count();
        ig_md.fabric_meta.lkp_ipv6_addr = punt_ip;
        ig_md.fabric_meta.routing_lkp_flag = 1;
        ig_md.ktep_meta.egress_pkt_type = PKT_TYPE_KNF;
        ig_md.ktep_meta.nw_id = p_nw_id;
        ig_md.ktep_meta.process_l2 = 0;
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
        prepare_for_punt_tunnel.apply();
    }
}

control VRouterEgress(
        inout header_t hdr,
        inout egress_metadata_t eg_md,
        in egress_intrinsic_metadata_t eg_intr_md,
        inout egress_intrinsic_metadata_for_deparser_t eg_dprsr_md)
        (bit<32> vrouter_ifaces_table_size) {

    DirectCounter<bit<64>>(CounterType_t.PACKETS_AND_BYTES) ktep_router_iface_cntr;

    /* Copy MAC Address of the egress interface to vRouter Metadata */
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
    @ternary(1)
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

    action ktep_l2_egress_process_vxlan() {
        hdr.vxlan_inner_ethernet.dstAddr = eg_md.ktep_router_meta.dst_mac;
        hdr.vxlan_inner_ethernet.srcAddr = eg_md.ktep_router_meta.src_mac;
        /* We need to reset the egress_pkt_type before recirculation in case we
         * have a local overlay vrouter.
         */
        eg_md.kvtep_meta.egress_pkt_type = KVTEP_PKT_TYPE_RAW;
    }

    /* Set source and destination MAC addresses to the inner packet of the KNF
     * packet.
     */
    action ktep_l2_egress_process_knf() {
        hdr.inner_ethernet.dstAddr = eg_md.ktep_router_meta.dst_mac;
        hdr.inner_ethernet.srcAddr = eg_md.ktep_router_meta.src_mac;
    }

    /* Set source and destination MAC addresses to the outer headers of the
     * user packet.
     */
    action ktep_l2_egress_process_user() {
        hdr.ethernet.dstAddr = eg_md.ktep_router_meta.dst_mac;
        hdr.ethernet.srcAddr = eg_md.ktep_router_meta.src_mac;
    }

    apply {
        if (eg_md.ktep_router_meta.process_l2_egress == 1) {
            ktep_router_iface.apply();
            if (eg_md.ktep_meta.egress_pkt_type == PKT_TYPE_KNF) {
                /* TODO: if we manage to swap the bloc ktep router egress before
                 * kvtep egress then this condition and its internal action
                 * should be removed.
                 */
                if (eg_md.kvtep_meta.egress_pkt_type == KVTEP_PKT_TYPE_VXLAN) {
                    ktep_l2_egress_process_vxlan();
                } else {
                    ktep_l2_egress_process_knf();
                }
            } else {
                ktep_l2_egress_process_user();
            }
        }
    }
}

control L3EgressCntr(
        inout eg_ktep_metadata_t ktep_meta)
        (bit<32> punt_tunnel_stats_table_size) {

    DirectCounter<bit<64>>(CounterType_t.PACKETS_AND_BYTES) punt_tunnel_stats_cntr;

    action punt_tunnel_stats_hit() {
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
        }
        const default_action = punt_tunnel_stats_hit();
        size = punt_tunnel_stats_table_size;
        counters = punt_tunnel_stats_cntr;
    }

    apply {
        punt_tunnel_stats.apply();
    }
}
# 23 "leaf.p4" 2
# 1 "core/modules/cpu.p4" 1
/****************************************************************
 * Copyright (c) Kaloom, 2019
 *
 * This unpublished material is property of Kaloom Inc.
 * All rights reserved.
 * Reproduction or distribution, in whole or in part, is
 * forbidden except by express written permission of Kaloom Inc.
 ****************************************************************/




# 1 "./core/types.p4" 1
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
control CPUPort(out port_id_t cpu_port_id, out bit<3> ring_id) {
    /* The register ring_id_counter and the associated RegisterAction are used
     * to loop around the 8 lanes of pcie in a round-robin fashion.
     */
    const bit<32> ring_id_counter_instance_count = 1;
    Register<bit<8>, bit<1>>(ring_id_counter_instance_count, 0) ring_id_counter;
    RegisterAction<bit<8>, bit<1>, bit<3>>(ring_id_counter) generate_ring_id = {
        void apply(inout bit<8> val, out bit<3> rv) {
            if (val < 7) {
                val = val + 1;
            } else {
                val = 0;
            }
            rv = (bit<3>)val;
        }
    };

    // TODO: Is the index argument necessary? Can it be hard-coded?
    action get_cpu_port_(port_id_t port_id, bit<1> index) {
        cpu_port_id = port_id;
        ring_id = generate_ring_id.execute(index);
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
        default_action = get_cpu_port_(0, 0);
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
# 24 "leaf.p4" 2
# 1 "core/modules/fabric.p4" 1
/****************************************************************
 * Copyright (c) Kaloom, 2019
 *
 * This unpublished material is property of Kaloom Inc.
 * All rights reserved.
 * Reproduction or distribution, in whole or in part, is
 * forbidden except by express written permission of Kaloom Inc.
 ****************************************************************/




# 1 "./core/types.p4" 1
/****************************************************************
 * Copyright (c) Kaloom, 2019
 *
 * This unpublished material is property of Kaloom Inc.
 * All rights reserved.
 * Reproduction or distribution, in whole or in part, is
 * forbidden except by express written permission of Kaloom Inc.
 ****************************************************************/
# 14 "core/modules/fabric.p4" 2
# 1 "./core/modules/port_failover.p4" 1
/****************************************************************
 * Copyright (c) Kaloom, 2019
 *
 * This unpublished material is property of Kaloom Inc.
 * All rights reserved.
 * Reproduction or distribution, in whole or in part, is
 * forbidden except by express written permission of Kaloom Inc.
 ****************************************************************/





control PortFailover(
        inout header_t hdr,
        in ingress_intrinsic_metadata_t ig_intr_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_tm_md,
        inout ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md)(
        bit<32> port_failover_table_size,
        Register<bit<1>, port_failover_reg_index_t> port_failover_reg,
        RegisterAction<bit<1>, port_failover_reg_index_t, bit<1>> port_failover_register_action) {

    action drop_packet() {
        ig_dprsr_md.drop_ctl = DROP_CTL_ALL;
        ig_tm_md.bypass_egress = 1;
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
# 15 "core/modules/fabric.p4" 2

control L2Ingress(
        inout header_t hdr,
        inout ig_fabric_metadata_t fabric_meta,
        in ingress_intrinsic_metadata_t ig_intr_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_tm_md,
        inout ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md)(
        bit<32> l2_ingress_table_size) {

    DirectCounter<bit<32>>(CounterType_t.PACKETS) l2_ingress_cntr;

    action l2_ingress_miss() {
        l2_ingress_cntr.count();
        ig_dprsr_md.drop_ctl = DROP_CTL_ALL;
        ig_tm_md.bypass_egress = 1;
        exit;
    }

    action l2_ingress_send_to_cpu_hit() {
        l2_ingress_cntr.count();
        hdr.dp_ctrl_hdr.setValid();
        hdr.dp_ctrl_hdr.etherType = ETHERTYPE_DP_CTRL;
        hdr.dp_ctrl_hdr.port = (bit<16>)ig_intr_md.ingress_port;
        ig_tm_md.ucast_egress_port = fabric_meta.cpu_port;
        /* TODO: The p4-14 code does not bypass_egress - workaround for BF 8844 */
        ig_tm_md.bypass_egress = 1;
        exit;
    }

    /* Receive from the CPU */
    action l2_ingress_process_cpu_packet() {
        l2_ingress_cntr.count();
        /* Set egress port */
        ig_tm_md.ucast_egress_port = (port_id_t)hdr.dp_ctrl_hdr.port;
        /* Pop dp_ctrl_header */
        hdr.dp_ctrl_hdr.setInvalid();
        fabric_meta.routing_lkp_flag = 0;
    }

    /* If a packet hits this action then it will be forwarded to the routing
     * block
     */
    action l2_ingress_router_iface_hit() {
        l2_ingress_cntr.count();
        fabric_meta.lkp_ipv6_addr = hdr.ipv6.dstAddr;
    }

    /* l2_ingress table classifies incoming packets and forward to the
     * corresponding block. Ternary match is needed so that we can mask the
     * port id for an lldp packet arriving at any port also ternary is needed
     * if we want to mask dest_mac for multicast cases.
     */
    table l2_ingress {
        key = {
            ig_intr_md.ingress_port : ternary;
            hdr.ethernet.dstAddr : ternary;
        }
        actions = {
            l2_ingress_router_iface_hit;
            l2_ingress_send_to_cpu_hit;
            l2_ingress_process_cpu_packet;
            l2_ingress_miss;
        }

        const default_action = l2_ingress_miss();
        size = l2_ingress_table_size;
        counters = l2_ingress_cntr;
    }

    apply {
        l2_ingress.apply();
    }
}

control FabricRouting(
        inout header_t hdr,
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

    DirectCounter<bit<32>>(CounterType_t.PACKETS) routing_ipv6_cntr;
    DirectCounter<bit<32>>(CounterType_t.PACKETS) neighbor_cntr;
    DirectCounter<bit<32>>(CounterType_t.PACKETS) ecmp_groups_cntr;

    action drop_packet() {
        ig_dprsr_md.drop_ctl = DROP_CTL_ALL;
        ig_tm_md.bypass_egress = 1;
        exit;
    }

    /* The packet can be sent directly to the destination device and does not need
     * to be sent via another router.
     */
    action routing_dcn_hit() {
        routing_ipv6_cntr.count();
        fabric_meta.l2_egress_lkp_flag = 1;
        fabric_meta.lkp_ipv6_addr = hdr.ipv6.dstAddr;
    }

    /* The host is accessible via another router */
    action routing_nh_hit(ipv6_addr_t nexthop_ipv6) {
        routing_ipv6_cntr.count();
        fabric_meta.l2_egress_lkp_flag = 1;
        fabric_meta.lkp_ipv6_addr = nexthop_ipv6;
    }

    action routing_to_host() {
        routing_ipv6_cntr.count();
        hdr.dp_ctrl_hdr.setValid();
        hdr.dp_ctrl_hdr.etherType = ETHERTYPE_DP_CTRL;
        hdr.dp_ctrl_hdr.port = (bit<16>)ig_intr_md.ingress_port;
        ig_tm_md.ucast_egress_port = fabric_meta.cpu_port;
        /* TODO: The p4-14 code does not bypass_egress - workaround for BF 8844 */
        ig_tm_md.bypass_egress = 1;
        exit;
    }

    action routing_ecmp(ecmp_group_id_t ecmp_grp_id) {
        routing_ipv6_cntr.count();
        fabric_meta.ecmp_grp_id = ecmp_grp_id;
    }

    action routing_miss() {
        routing_ipv6_cntr.count();
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
        counters = routing_ipv6_cntr;
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
    ActionProfile(ecmp_selection_table_size) ecmp_selector;
    ActionSelector(ecmp_selector, selector_hash, SelectorMode_t.FAIR,
            port_failover_reg, ecmp_selection_max_group_size,
            ecmp_groups_table_size) ecmp_selector_sel;


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
            fabric_meta.flow_hash : selector;
        }
        actions = {
            ecmp_routing_nh_hit;
        }
        size = ecmp_groups_table_size;
        implementation = ecmp_selector_sel;
        counters = ecmp_groups_cntr;
    }

    apply {
        if (fabric_meta.routing_lkp_flag == 1) {
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
        inout header_t hdr,
        in egress_intrinsic_metadata_t eg_intr_md,
        inout egress_intrinsic_metadata_for_deparser_t eg_dprsr_md)(
        bit<32> l2_egress_table_size) {

    DirectCounter<bit<32>>(CounterType_t.PACKETS) l2_egress_cntr;

    action l2_egress_hit(mac_addr_t iface_mac) {
        l2_egress_cntr.count();
        hdr.ipv6.hopLimit = hdr.ipv6.hopLimit - 1;
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
    }
}

control CopyNexthopMAC(
        inout header_t hdr,
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
        in header_t hdr,
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
# 25 "leaf.p4" 2
# 1 "core/modules/port_failover.p4" 1
/****************************************************************
 * Copyright (c) Kaloom, 2019
 *
 * This unpublished material is property of Kaloom Inc.
 * All rights reserved.
 * Reproduction or distribution, in whole or in part, is
 * forbidden except by express written permission of Kaloom Inc.
 ****************************************************************/
# 26 "leaf.p4" 2
# 1 "core/modules/replication.p4" 1
/****************************************************************
 * Copyright (c) Kaloom, 2019
 *
 * This unpublished material is property of Kaloom Inc.
 * All rights reserved.
 * Reproduction or distribution, in whole or in part, is
 * forbidden except by express written permission of Kaloom Inc.
 ****************************************************************/




control ReplicatedPackets(
        inout header_t hdr,
        inout egress_metadata_t eg_md,
        in egress_intrinsic_metadata_t eg_intr_md,
        inout egress_intrinsic_metadata_for_deparser_t eg_dprsr_md)
        (bit<32> rid_table_size,
        bit<32> kvs_egress_table_size) {

    DirectCounter<bit<32>>(CounterType_t.PACKETS) rid_cntr;

    /* Drop replica if it is being sent on the same port with the same vlan. */
    action drop_packet() {
        eg_dprsr_md.drop_ctl = DROP_CTL_ALL;
        exit;
    }

    /* Packet is sent to a local port or a LAG without a vlan tag (untagged) */
    action rid_local_port_untagged_hit() {
        rid_cntr.count();
        /* The vland ID used to identify the untagged packets is 0 while 4096
         * is used as its corresponding RID value.
         */
        eg_md.ktep_meta.egress_vlan_id = 0;
    }

    /* Packet is sent to a local port or a LAG with a vlan tag */
    action rid_local_port_vlan_hit() {
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
    action rid_punt_channel_hit(dest_id_t punt_dest_id, nw_id_t p_nw_id) {
        eg_md.ktep_meta.nw_id = p_nw_id;
        rid_remote_leaf_hit(punt_dest_id);
    }

    /* Packet is sent to a remote vtep via a local router */
    action rid_remote_vtep_local_router_hit(kvtep_id_t kvtep_id,
            kvtep_id_t remote_vtep_id, nw_id_t kvtep_nw_id) {
        rid_cntr.count();
        eg_md.kvtep_meta.kvtep_id = kvtep_id;
        eg_md.kvtep_meta.remote_vtep_id = remote_vtep_id;
        eg_md.kvtep_meta.process_egress = 1;
        eg_md.kvtep_meta.egress_pkt_type = KVTEP_PKT_TYPE_VXLAN;

        eg_md.ktep_meta.dest_id = 1;
        eg_md.ktep_meta.nw_id = kvtep_nw_id;
        eg_md.ktep_meta.egress_pkt_type = PKT_TYPE_KNF;

        eg_md.fabric_meta.l2_egress_lkp_flag = 0;
    }

    /* Packet is sent to a remote vtep via a remote router */
    action rid_remote_vtep_remote_router_hit(kvtep_id_t kvtep_id,
            kvtep_id_t remote_vtep_id, nw_id_t kvtep_nw_id,
            dest_id_t kvtep_leaf_id) {
        rid_cntr.count();
        eg_md.kvtep_meta.kvtep_id = kvtep_id;
        eg_md.kvtep_meta.remote_vtep_id = remote_vtep_id;
        eg_md.kvtep_meta.process_egress = 1;
        eg_md.kvtep_meta.egress_pkt_type = KVTEP_PKT_TYPE_VXLAN;

        eg_md.ktep_meta.dest_id = kvtep_leaf_id;
        eg_md.ktep_meta.nw_id = kvtep_nw_id;
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
            rid_local_port_untagged_hit;
            rid_local_port_vlan_hit;
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

    /* Action used to send the replica to the host CPU port */
    action rid_cpu_packet() {
        hdr.dp_ctrl_hdr.setValid();
        hdr.dp_ctrl_hdr.etherType = ETHERTYPE_DP_CTRL;
        hdr.dp_ctrl_hdr.port = (bit<16>)eg_md.ingress_port;
        eg_md.fabric_meta.l2_egress_lkp_flag = 0;
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
        size = kvs_egress_table_size;
    }

    apply {
        if (eg_intr_md.egress_rid != 0) {
            switch (rid.apply().action_run) {
                rid_local_port_untagged_hit: {
                    switch (kvs_egress.apply().action_run) {
                        kvs_egress_hit: {
                            if (eg_md.ingress_port == eg_intr_md.egress_port) {
                                drop_packet();
                            }
                        }
                    }
                }
                rid_remote_leaf_hit : {
                    if (eg_intr_md.egress_port == eg_md.fabric_meta.cpu_port) {
                        rid_cpu_packet();
                    }
                }

                rid_remote_vtep_remote_router_hit :
                rid_remote_vtep_local_router_hit : {
                    if ((eg_md.ktep_meta.pkt_src == KTEP_SRC_LEAF) &&
                            (eg_md.ktep_meta.received_on_punt_channel == 0)) {
                        drop_packet();
                    }
                }
            }
        }
    }
}

control ReplicaCopyMac(
        inout header_t hdr,
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
# 27 "leaf.p4" 2
# 1 "core/modules/knf_tunnel.p4" 1
/****************************************************************
 * Copyright (c) Kaloom, 2019
 *
 * This unpublished material is property of Kaloom Inc.
 * All rights reserved.
 * Reproduction or distribution, in whole or in part, is
 * forbidden except by express written permission of Kaloom Inc.
 ****************************************************************/




control KnfEncap(
        inout header_t hdr,
        inout egress_metadata_t eg_md,
        in egress_intrinsic_metadata_t eg_intr_md,
        inout egress_intrinsic_metadata_for_deparser_t eg_dprsr_md)() {

    /* Copy ethernet only */
    action ktep_copy_hdrs_ether() {
        hdr.inner_ethernet.setValid();
        hdr.inner_ethernet = hdr.ethernet;
    }

    /* Copy ethernet and ipv6 headers */
    action ktep_copy_hdrs_ipv6() {
        hdr.inner_ethernet.setValid();
        hdr.inner_ipv6.setValid();
        hdr.inner_ethernet = hdr.ethernet;
        hdr.inner_ipv6 = hdr.ipv6;
    }

    /* Copy ethernet, ipv6 and udp headers */
    action ktep_copy_hdrs_ipv6_udp() {
        hdr.inner_ethernet.setValid();
        hdr.inner_ipv6.setValid();
        hdr.inner_udp.setValid();
        hdr.inner_ethernet = hdr.ethernet;
        hdr.inner_ipv6 = hdr.ipv6;
        hdr.inner_udp = hdr.udp;
    }

    /* Drop packet when the packet is not correctly formed */
    action ktep_copy_hdrs_drop() {
        eg_dprsr_md.drop_ctl = DROP_CTL_ALL;
        exit;
    }

    /* ktep_copy_hdrs is used to copy outer headers to inner headers to prepare
     * for knf encapsulation.
     * This is needed since it is possible to have parsed the IPv6 and UDP
     * headers of a user packet since the parser must parse these for a KNF
     * packet. In this case, we must explicitly move them to the inner packet.
     */
    table ktep_copy_hdrs {
        key = {
            hdr.ipv6.isValid() : exact;
            hdr.udp.isValid() : exact;
        }
        actions = {
            ktep_copy_hdrs_ether;
            ktep_copy_hdrs_ipv6;
            ktep_copy_hdrs_ipv6_udp;
            ktep_copy_hdrs_drop;
        }
        const entries = {
            (false, false) : ktep_copy_hdrs_ether();
            (true, false) : ktep_copy_hdrs_ipv6();
            (true, true) : ktep_copy_hdrs_ipv6_udp();
        }
        const default_action = ktep_copy_hdrs_drop;
        size = 4;
    }

    /* ktep_remove_vlan is used to remove a vlan header when a packet must be
     * encapsulated.
     */
    action ktep_remove_vlan() {
        /* Copy vlan ethertype from metadata into inner ethernet header.
         * Metadata is used since for some reason, when the vlan ethertype is
         * copied directly from the vlan header, the value is wrong.
         */
        hdr.inner_ethernet.etherType = eg_md.ktep_meta.vlan_etherType;
        hdr.udp.hdrLen = hdr.udp.hdrLen - 4;
        hdr.ipv6.payloadLen = hdr.ipv6.payloadLen - 4;
        eg_md.ktep_meta.payload_length = eg_md.ktep_meta.payload_length - 4;
        hdr.vlan.setInvalid();
    }

    /* Perform KNF encapsulation */
    action knf_encap() {
        hdr.ipv6.setValid();
        hdr.udp.setValid();
        hdr.knf.setValid();
        /* Set ethernet ethertype */
        hdr.ethernet.etherType = ETHERTYPE_IPV6;
        /* Create KNF IPv6 header */
        hdr.ipv6.version = IPV6_VERSION;
        hdr.ipv6.trafficClass = 0;
        hdr.ipv6.flowLabel = 0;
        hdr.ipv6.nextHdr = UDP_PROTO;
        hdr.ipv6.hopLimit = HOP_LIMIT;
        /* Subtract 4 Bytes from the packet length to account for the Ethernet
         * FCS that is included in Tofino's packet length metadata.
         */
        hdr.ipv6.payloadLen = eg_intr_md.pkt_length + 16; /* UDP_SIZE + KNF_SIZE - 4 */

        hdr.udp.srcPort = eg_md.fabric_meta.flow_hash;
        hdr.udp.dstPort = KNF_UDP_DST_PORT;
        hdr.udp.checksum = 0;
        /* Subtract 4 Bytes from the packet length to account for the Ethernet
         * FCS that is included in Tofino's packet length metadata.
         */
        hdr.udp.hdrLen = eg_intr_md.pkt_length + 16; /* UDP_SIZE + KNF_SIZE - 4 */

        eg_md.ktep_meta.payload_length = eg_intr_md.pkt_length + 16; /* UDP_SIZE + KNF_SIZE - 4 */
    }

    apply {
        ktep_copy_hdrs.apply();
        knf_encap();
        if (hdr.vlan.isValid()) {
            ktep_remove_vlan();
        }
    }
}

control KnfDecap(
        inout header_t hdr,
        inout egress_metadata_t eg_md,
        in egress_intrinsic_metadata_t eg_intr_md,
        inout egress_intrinsic_metadata_for_deparser_t eg_dprsr_md)() {

    /* Decapsulate KNF header */
    action knf_decap_() {
        /* Copy headers from inner to outer */
        hdr.ethernet.dstAddr = hdr.inner_ethernet.dstAddr;
        hdr.ethernet.srcAddr = hdr.inner_ethernet.srcAddr;
        hdr.ethernet.etherType = hdr.inner_ethernet.etherType;
        /* Copy inner ipv6 and udp to outer. We assume they exist and will remove
         * them later if they are not needed.
         */
        hdr.ipv6.version = hdr.inner_ipv6.version;
        hdr.ipv6.trafficClass = hdr.inner_ipv6.trafficClass;
        hdr.ipv6.flowLabel = hdr.inner_ipv6.flowLabel;
        hdr.ipv6.payloadLen = hdr.inner_ipv6.payloadLen;
        hdr.ipv6.nextHdr = hdr.inner_ipv6.nextHdr;
        hdr.ipv6.hopLimit = hdr.inner_ipv6.hopLimit;
        hdr.ipv6.srcAddr = hdr.inner_ipv6.srcAddr;
        hdr.ipv6.dstAddr = hdr.inner_ipv6.dstAddr;

        hdr.udp.srcPort = hdr.inner_udp.srcPort;
        hdr.udp.dstPort = hdr.inner_udp.dstPort;
        hdr.udp.hdrLen = hdr.inner_udp.hdrLen;
        hdr.udp.checksum = hdr.inner_udp.checksum;
        /* Remove inner headers */
        hdr.inner_ethernet.setInvalid();
        hdr.inner_ipv6.setInvalid();
        hdr.inner_udp.setInvalid();
        hdr.knf.setInvalid();
    }

    /* Decapsulation of KNF header when the packet has an inner ipv6 header but
     * no inner vlan and no inner udp header.
     */
    action knf_decap_udp() {
        knf_decap_();
        hdr.udp.setInvalid();
    }

    /* Decapsulation of KNF header when the packet has no inner vlan, no inner
     * ipv6 and no inner udp headers.
     */
    action knf_decap_ipv6_udp() {
        knf_decap_();
        hdr.ipv6.setInvalid();
        hdr.udp.setInvalid();
    }

    /* Drop packet in situations that do not make sense such as the presence of
     * a udp header with no ipv6 header.
     */
    action knf_decap_drop() {
        eg_dprsr_md.drop_ctl = DROP_CTL_ALL;
        exit;
    }

    /* knf_decap is used to decapsulate a packet with a KNF header. There are
     * several cases to consider depending on the packet that was parsed.
     * Similarly to encapsulation, it is possible for the parser to parse inner
     * ipv6 and inner udp headers if they are present in the encapsulated user
     * packet. In these cases, we must ensure to not remove the outer ipv6 and
     * udp headers.
     */
    table knf_decap {
        key = {
            hdr.inner_ipv6.isValid() : exact;
            hdr.inner_udp.isValid() : exact;
        }
        actions = {
            knf_decap_;
            knf_decap_udp;
            knf_decap_ipv6_udp;
            knf_decap_drop;
        }
        const entries = {
            (false, false) : knf_decap_ipv6_udp();
            (true, false) : knf_decap_udp();
            (true, true) : knf_decap_();
        }
        const default_action = knf_decap_drop;
        size = 4;
    }

    apply {
        knf_decap.apply();
    }
}

control KnfRewrite(
        inout header_t hdr,
        inout egress_metadata_t eg_md,
        inout eg_ktep_metadata_t ktep_meta,
        in egress_intrinsic_metadata_t eg_intr_md,
        inout egress_intrinsic_metadata_for_deparser_t eg_dprsr_md)
        (bit<32> knids_table_size,
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

    action knf_rewrite_(ipv6_addr_t ipv6_src) {
        hdr.ipv6.srcAddr = ipv6_src;
        eg_md.ktep_meta.payload_length = hdr.udp.hdrLen;
        hdr.knf.doNotLearn = 1;

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
        hdr.knf.doNotLearn = 1;
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
        if ((eg_md.ktep_meta.egress_pkt_type == PKT_TYPE_KNF) &&
                (eg_intr_md.egress_port != eg_md.fabric_meta.cpu_port ||
                eg_md.ktep_meta.process_l3 == 1)) {
            knf_set_knid.apply();
            if (ktep_meta.send_to_kvs == 1) {
                kvs_knf_rewrite.apply();
            } else {
                knf_rewrite.apply();
                knf_set_dest_ip.apply();
            }
        }
    }
}
# 28 "leaf.p4" 2
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
        inout header_t hdr,
        inout ingress_metadata_t ig_md,
        inout ingress_metadata_t ig_intr_md, /* Using this name to match P4-14 code */
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
    action postcard_watch_all() {
        postcard_watchlist_cntr.count();
        ig_md.tel_metadata.generate_postcard = 1;
        ig_md.tel_metadata.watchlist_hit = 1;
    }

    /* 100% for all packets of matched flow, use postcard_not_watch for 0%.
     * sample_index i keeps percent i.
     */
    action postcard_watch_sample(bit<32> sample_index) {
        postcard_watchlist_cntr.count();
        /* Execute Register action to update "tel_metadata.generate_postcard" */
        ig_md.tel_metadata.generate_postcard = tel_postcard_sample_rate_action.execute(sample_index);
        ig_md.tel_metadata.watchlist_hit = 1;
    }

    /* Telemetry bit must be explicitly cleared. Otherwise, tel_postcard_e2e_hit
     * gets executed generating postcard continously.
     */
    action postcard_not_watch() {
        postcard_watchlist_cntr.count();
        ig_md.tel_metadata.watchlist_hit = 0;
        ig_md.tel_metadata.generate_postcard = 0;
    }

    table postcard_watchlist {
        key = {
            ig_intr_md.ingress_port : ternary;
            hdr.ethernet.etherType : ternary;
            hdr.ipv6.isValid() : ternary;
            hdr.ipv6.srcAddr : ternary;
            hdr.ipv6.dstAddr : ternary;
            hdr.ipv6.nextHdr : ternary;
            hdr.ipv4.isValid() : ternary;
            hdr.ipv4.srcAddr : ternary;
            hdr.ipv4.dstAddr : ternary;
            hdr.ipv4.protocol : ternary;
            hdr.udp.isValid() : ternary;
            hdr.udp.srcPort : ternary;
            hdr.udp.dstPort : ternary;
            hdr.udpv4.isValid() : ternary;
            hdr.udpv4.srcPort : ternary;
            hdr.udpv4.dstPort : ternary;
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
    }

    apply {
        /* Apply watchlist table only on USER ports traffic for now.
         * TODO: With the new parser this condition can be updated to add KVS
         * port type.
         */
        if (ig_md.ktep_port_meta.port_type == PORT_TYPE_USER) {
            postcard_watchlist.apply();
        } else if (ig_md.ktep_port_meta.port_type == PORT_TYPE_FABRIC &&
                hdr.knf.isValid() && hdr.knf.telSequenceNum != 0) {
            /* If KNF header is valid and knf.telSequenceNum is set, then use
             * it as the postcard sequence number, don't generate new number.
             */
            set_knf_telemetry_valid();
        }
    }
}

/* Generate sequence number for telemetry */
control TelGenerateSequenceNum(
        inout header_t hdr,
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
# 29 "leaf.p4" 2
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
        inout header_t hdr,
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
            eg_intr_md.deq_qdepth,
            hdr.bridged_md.ingress_tstamp,
            eg_prsr_md.global_tstamp,
            hdr.knf.telSequenceNum
        };
    }

    /* TODO: @ignore_table_dependency("tel_postcard_insert") */
    action tel_postcard_e2e() {
        #if __TARGET_TOFINO__ == 1
            eg_dprsr_md.mirror_type = MIRROR_TYPE_E2E;
        #elif __TARGET_TOFINO__ >= 2
            eg_dprsr_md.mirror_type = (bit<4>) MIRROR_TYPE_E2E;
        #endif
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
        inout header_t hdr,
        inout eg_tel_metadata_t tel_metadata,
        in eg_mirror_metadata_t mirror,
        in eg_parser_metadata_t eg_intr_md_from_parser_aux, /* Using this name to match P4-14 code */
        in egress_intrinsic_metadata_t eg_intr_md) {

    DirectCounter<bit<32>>(CounterType_t.PACKETS) tel_postcard_insert_cntr;

    action tel_mirror_encap(ipv6_addr_t srcip, ipv6_addr_t dstip) {
        hdr.ethernet.setValid();
        hdr.udp.setValid();

        hdr.udp.srcPort = 0;
        hdr.udp.dstPort = UDP_PORT_TEL_REPORT;
        hdr.udp.checksum = 0;
        /* Calculate pkt len = recirculated pkt len + 28B for postcard header */
        const bit<16> pkt_len_adjust = POSTCARD_SIZE + UDP_SIZE - MIRROR_SIZE - 4;
        hdr.udp.hdrLen = eg_intr_md.pkt_length + pkt_len_adjust;
        /* TODO: Verify if we need to add the extra 8 byte of udp length */

        hdr.ipv6.setValid();
        hdr.ipv6.payloadLen = eg_intr_md.pkt_length + pkt_len_adjust;
        hdr.ipv6.version = 0x6;
        hdr.ipv6.nextHdr = UDP_PROTO;
        hdr.ipv6.hopLimit = 64;
        hdr.ipv6.trafficClass = 0;
        hdr.ipv6.flowLabel = 0;

        hdr.ethernet.etherType = ETHERTYPE_IPV6;
        hdr.ipv6.srcAddr = srcip;
        hdr.ipv6.dstAddr = dstip;
        /* smac and dmac must be set after the recirculation. */
    }

    action postcard_insert_common(bit<64> switch_id) {
        hdr.postcard_header.setValid();
        hdr.postcard_header.version = POSTCARD_VERSION;
        hdr.postcard_header.sequence_num = mirror.sequence_num;
        hdr.postcard_header.switch_id = switch_id;
        hdr.postcard_header.ingress_port = (bit<16>)mirror.ingress_port;
        hdr.postcard_header.egress_port = (bit<16>)mirror.egress_port;
        hdr.postcard_header.queue_id = (bit<8>)mirror.queue_id;
        hdr.postcard_header.queue_depth = (bit<24>)mirror.queue_depth;
        hdr.postcard_header.ingress_tstamp = (bit<64>)mirror.ingress_tstamp;
        hdr.postcard_header.egress_tstamp = (bit<64>)mirror.egress_tstamp;
    }

    action postcard_insert(ipv6_addr_t srcip, ipv6_addr_t dstip,
            bit<64> switch_id) {
        tel_postcard_insert_cntr.count();
        tel_mirror_encap(srcip, dstip);
        postcard_insert_common(switch_id);
    }

    action tel_postcard_insert_miss() {
        tel_postcard_insert_cntr.count();
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

    apply {
        tel_postcard_insert.apply();
    }
}
# 30 "leaf.p4" 2

const bit<16> MSB_MASK = 0x8000;

control SwitchIngress(
        inout header_t hdr,
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

    /* L2 services */
    IngressPortProperties(INGRESS_PORT_PROPERTIES_TABLE_SIZE) ingress_port;
    FlowHash() compute_flow_hash;
    KnfType() set_type_knf;
    KnfPackets(10000,
        KNF_DST_IP_IS_LOCAL_TABLE_SIZE) knf_packets;
    PuntUserPackets(USER_PUNT_TABLE_SIZE) user_punt;
    VnetMapping(VLAN_TO_VNET_MAPPING_TABLE_SIZE) vnet_mapping;
    VnetLearning(VNET_SMAC_REMOTE_TABLE_SIZE,
        VNET_SMAC_LOCAL_PORT_TABLE_SIZE) vnet_learning;
    VnetCPU(KNF_LEARN_FLAG_TABLE_SIZE) vnet_cpu;
    VnetExclusion(1001,
        2048,
        VROUTER_IFACES_TABLE_SIZE) vnet_exclusion;
    VnetDmac(VNET_DMAC_TABLE_SIZE,
        KNID_TO_MC_GRP_MAPPING_TABLE_SIZE) vnet_dmac;
    LagStateCheck(LAG_STATE_TABLE_SIZE) lag_state_check;
    LagMapping(LAG_TO_VLAN_MAPPING_TABLE_SIZE) lag_mapping;
    VnetEgressIfaces(EGRESS_PORTS_TABLE_SIZE,
            LAG_GROUPS_TABLE_SIZE,
            LAG_SELECTION_TABLE_SIZE,
            LAG_SELECTION_MAX_GROUP_SIZE,
            REMOTE_LAGS_TABLE_SIZE, lag_failover_reg) vnet_egress_ifaces;
    LagFailover(LAG_FAILOVER_TABLE_SIZE, lag_failover_reg,
            lag_port_down) lag_failover;

    /* L3 services */
    VRouter(VROUTER_IFACES_TABLE_SIZE) process_vrouter_vxlan;
    VRouterPuntChannel(VROUTER_IFACES_TABLE_SIZE) prepare_vrouter_punt;

    /* INT */
    INTGenerateRandVal() int_gen;
    Watchlist(TEL_FLOW_WATCHLIST_TABLE_SIZE) telemetry_watchlist;

    action add_bridged_md() {
        hdr.bridged_md.setValid();
        hdr.bridged_md.src = SWITCH_PKT_SRC_BRIDGE;
        hdr.bridged_md.ingress_port = ig_intr_md.ingress_port;
        hdr.bridged_md.ingress_tstamp = ig_intr_md.ingress_mac_tstamp;

        /* Fabric Metadata */
        hdr.bridged_md.fabric_meta.l2_egress_lkp_flag = ig_md.fabric_meta.l2_egress_lkp_flag;
        hdr.bridged_md.fabric_meta.flow_hash = ig_md.fabric_meta.flow_hash;

        /* Ktep Port Metadata */
        hdr.bridged_md.ktep_port_meta.port_type = ig_md.ktep_port_meta.port_type;

        /* Ktep Metadata */
        hdr.bridged_md.ktep_meta.egress_vlan_id = ig_md.ktep_meta.egress_vlan_id;
        hdr.bridged_md.ktep_meta.ingress_pkt_type = ig_md.ktep_meta.ingress_pkt_type;
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

        /* Ktep Router Metadata */
        hdr.bridged_md.ktep_router_meta.router_id = ig_md.ktep_router_meta.router_id;
        hdr.bridged_md.ktep_router_meta.output_iface = ig_md.ktep_router_meta.output_iface;
        hdr.bridged_md.ktep_router_meta.dst_mac = ig_md.ktep_router_meta.dst_mac;
        hdr.bridged_md.ktep_router_meta.process_l2_egress = ig_md.ktep_router_meta.process_l2_egress;

        /* KVtep Metadata */
        hdr.bridged_md.kvtep_meta.egress_pkt_type = ig_md.kvtep_meta.egress_pkt_type;
        hdr.bridged_md.kvtep_meta.process_egress = ig_md.kvtep_meta.process_egress;
        hdr.bridged_md.kvtep_meta.kvtep_id = ig_md.kvtep_meta.kvtep_id;
        hdr.bridged_md.kvtep_meta.remote_vtep_id = ig_md.kvtep_meta.remote_vtep_id;

        /* Telemetry Metadata */
        hdr.bridged_md.tel_metadata.generate_postcard = ig_md.tel_metadata.generate_postcard;
        hdr.bridged_md.tel_metadata.watchlist_hit = ig_md.tel_metadata.watchlist_hit;
    }

    action set_remote_lag_id() {
        ig_md.ktep_meta.egress_iface_id = (bit<9>)hdr.knf.remoteLagID;
        ig_md.ktep_meta.is_icl = 1;
    }

    action init_l2_exclusion_id() {
        ig_intr_md_for_tm.level2_exclusion_id = ig_intr_md.ingress_port & 0x7f;
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
        /* The program does not compile when this is in the parser so
         * we are initialzing this metadata here instead.
         */
        ig_md.ktep_router_meta.process_l2_egress = 0;

        ingress_port.apply(hdr, ig_md, ig_intr_md);
        cpu_port.apply(ig_md.fabric_meta.cpu_port, hdr.dp_ctrl_hdr.ring_id);
        compute_flow_hash.apply(hdr, ig_md);
        init_l2_exclusion_id();

        if (!hdr.pktgen_ext_header.isValid()) {
            if (ig_md.ktep_port_meta.port_type != PORT_TYPE_USER) {
                /* MLAG-ICL packets */
                if (hdr.knf.isValid() && hdr.knf.remoteLagID != 0) {
                    set_remote_lag_id();
                }

                set_type_knf.apply(hdr, ig_md);

                if (ig_md.fabric_meta.l2_ingress_lkp_flag == 1) {
                    l2_ingress.apply(hdr, ig_md.fabric_meta, ig_intr_md,
                            ig_intr_md_for_tm, ig_dprsr_md);
                }

                knf_packets.apply(hdr, ig_md, ig_intr_md, ig_intr_md_for_tm);
                /* TODO: move lag_mapping table inside the previous control block.
                 * It is currently not possible because of compiler issue.
                 */
                lag_mapping.apply(hdr, ig_md);
            } else {
                user_punt.apply(hdr, ig_md, ig_intr_md, ig_intr_md_for_tm);

                vnet_mapping.apply(hdr, ig_md, ig_md.ktep_meta, ig_dprsr_md.digest_type,
                    ig_intr_md, ig_intr_md_for_tm, ig_dprsr_md);

                lag_state_check.apply(ig_md.ktep_meta, ig_intr_md_for_tm, ig_dprsr_md);
            }

            l2_exclusion_id_offset.apply();

            if (ig_md.ktep_meta.learn == 1 && (!hdr.knf.isValid() ||
                    (hdr.knf.isValid() && (hdr.knf.doNotLearn == 0)))) {
                vnet_learning.apply(hdr, ig_md, ig_dprsr_md.digest_type,
                        ig_intr_md);
            }
            vnet_cpu.apply(hdr, ig_md, ig_intr_md, ig_intr_md_for_tm);

            process_vrouter_vxlan.apply(hdr, ig_md, ig_intr_md, ig_intr_md_for_tm, ig_dprsr_md);

            /* Setting the overlay flow_hash value that will be used in lag_groups
             * selector for traffic distribution towards local LAG members.
             */
            if (hdr.knf.isValid() && (ig_md.ktep_port_meta.port_type != PORT_TYPE_KVS)) {
                ig_md.ktep_meta.flow_hash = hdr.udp.srcPort;
            } else {
                ig_md.ktep_meta.flow_hash = ig_md.fabric_meta.flow_hash;
            }

            if ((ig_md.ktep_router_meta.punt == 1) ||
                    ((ig_md.ktep_router_meta.mtu_pkt_diff & MSB_MASK) != 0)) {
                prepare_vrouter_punt.apply(ig_md);
            } else if (ig_md.ktep_meta.process_l2 == 1 && ig_md.ktep_meta.is_icl == 0) {
                vnet_exclusion.apply(hdr, ig_md, ig_intr_md, ig_intr_md_for_tm);

                vnet_dmac.apply(hdr, ig_md, ig_md.ktep_meta, ig_md.fabric_meta,
                        ig_intr_md, ig_intr_md_for_tm, ig_dprsr_md);
            }
        }

        /* for pipeline fitting reason, INT ingress processing is starting here. */
        int_gen.apply(ig_md);
        if (!hdr.pktgen_ext_header.isValid()) {
            if (ig_md.ktep_meta.lag_lkp_flag == 1) {
                vnet_egress_ifaces.apply(hdr, ig_md, ig_md.ktep_meta, ig_intr_md,
                        ig_intr_md_for_tm, ig_dprsr_md);
            } else {
                fabric_routing.apply(hdr, ig_md.fabric_meta, ig_intr_md,
                        ig_intr_md_for_tm, ig_dprsr_md);
            }
            telemetry_watchlist.apply(hdr, ig_md, ig_md, ig_md.ktep_port_meta);
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
        inout header_t hdr,
        inout egress_metadata_t eg_md,
        in egress_intrinsic_metadata_t eg_intr_md,
        in egress_intrinsic_metadata_from_parser_t eg_prsr_md,
        inout egress_intrinsic_metadata_for_deparser_t eg_dprsr_md,
        inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport) {

    /* Hardware Config. */
    EgressCPUPort() egress_cpu_port;

    /* L2 service */
    VnetCopyVlan() copy_vlan;
    ReplicatedPackets(RID_TABLE_SIZE, EGRESS_PORTS_TABLE_SIZE) l2_packet_replication;
    KnfEncap() knf_encap;
    KnfDecap() knf_decap;
    KnfRewrite(10000, KNF_REWRITE_TABLE_SIZE, KVS_REWRITE_TABLE_SIZE,
        1024) knf_rewrite;
    VnetEgressVLANCntr(VNET_EGRESS_TABLE_SIZE) vnet_pkt_cntr_egress;

    /* L3 service */
    VxlanTunnel(128,
        128,
        4096) vxlan_tunnel;
    VRouterEgress(VROUTER_IFACES_TABLE_SIZE) vrouter_egress;
    L3EgressCntr(PUNT_TUNNEL_STATS_TABLE_SIZE) l3_counters;

    /* INT */
    TelGenerateSequenceNum() generate_tel_sequence_number;
    TelE2EMirror() tel_e2e_mirror;
    TelGeneratePostcard() tel_generate_postcard;

    /* Fabric */
    L2Egress(L2_EGRESS_TABLE_SIZE) l2_egress;
    ReplicaCopyMac(NH_TABLE_SIZE) nexthop_mac;
    CopyNexthopMAC(256) copy_nh_mac;
    EgressDrop() egress_drop;

    apply {
        eg_dprsr_md.drop_ctl = 0;

        if (eg_md.parser_metadata.clone_src == SWITCH_PKT_SRC_BRIDGE) {
            egress_cpu_port.apply(eg_md);
            copy_vlan.apply(hdr, eg_md);
            l2_packet_replication.apply(hdr, eg_md, eg_intr_md, eg_dprsr_md);

            if ((eg_md.ktep_meta.process_l2 == 1) ||
                    (eg_md.ktep_meta.process_l3 == 1) ||
                    (eg_md.ktep_meta.is_from_kvs == 1) ||
                    (eg_md.ktep_meta.send_to_kvs == 1)) {
                if ((eg_md.ktep_meta.ingress_pkt_type != PKT_TYPE_KNF) &&
                        (eg_md.ktep_meta.egress_pkt_type == PKT_TYPE_KNF)) {
                    knf_encap.apply(hdr, eg_md, eg_intr_md, eg_dprsr_md);
                } else if ((eg_md.ktep_meta.ingress_pkt_type == PKT_TYPE_KNF) &&
                        (eg_md.ktep_meta.egress_pkt_type != PKT_TYPE_KNF)) {
                    knf_decap.apply(hdr, eg_md, eg_intr_md, eg_dprsr_md);
                }

                knf_rewrite.apply(hdr, eg_md, eg_md.ktep_meta, eg_intr_md, eg_dprsr_md);

                vxlan_tunnel.apply(hdr, eg_md, eg_intr_md, eg_dprsr_md);

                vrouter_egress.apply(hdr, eg_md, eg_intr_md, eg_dprsr_md);

                vnet_pkt_cntr_egress.apply(hdr, eg_md, eg_md.ktep_meta, eg_intr_md, eg_dprsr_md);

                l3_counters.apply(eg_md.ktep_meta);
            }

            generate_tel_sequence_number.apply(hdr, eg_md.tel_metadata);

            if (eg_md.fabric_meta.l2_egress_lkp_flag == 1) {
                l2_egress.apply(hdr, eg_intr_md, eg_dprsr_md);
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
                    eg_md.parser_metadata, eg_intr_md);
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
