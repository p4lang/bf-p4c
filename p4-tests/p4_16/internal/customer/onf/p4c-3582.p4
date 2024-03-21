// Copyright 2020-present Open Networking Foundation
#include <core.p4>
#include <tna.p4>
typedef bit<3> fwd_type_t;
typedef bit<32> next_id_t;
typedef bit<20> mpls_label_t;
typedef bit<48> mac_addr_t;
typedef bit<12> vlan_id_t;
typedef bit<32> ipv4_addr_t;
typedef bit<16> l4_port_t;
typedef bit<32> flow_hash_t;
typedef bit<32> teid_t;
typedef bit<32> far_id_t;
typedef bit<16> pdr_ctr_id_t;
enum bit<2> SpgwDirection {
    UNKNOWN = 0x0,
    UPLINK = 0x1,
    DOWNLINK = 0x2,
    OTHER = 0x3
}
enum bit<8> SpgwInterface {
    UNKNOWN = 0x0,
    ACCESS = 0x1,
    CORE = 0x2,
    FROM_DBUF = 0x3
}
const bit<16> ETHERTYPE_QINQ = 0x88A8;
const bit<16> ETHERTYPE_QINQ_NON_STD = 0x9100;
const bit<16> ETHERTYPE_VLAN = 0x8100;
const bit<16> ETHERTYPE_MPLS = 0x8847;
const bit<16> ETHERTYPE_MPLS_MULTICAST = 0x8848;
const bit<16> ETHERTYPE_IPV4 = 0x0800;
const bit<16> ETHERTYPE_IPV6 = 0x86dd;
const bit<16> ETHERTYPE_ARP = 0x0806;
const bit<16> ETHERTYPE_PPPOED = 0x8863;
const bit<16> ETHERTYPE_PPPOES = 0x8864;
const bit<16> ETHERTYPE_PACKET_OUT = 0xBF01;
const bit<16> ETHERTYPE_CPU_LOOPBACK_INGRESS = 0xBF02;
const bit<16> ETHERTYPE_CPU_LOOPBACK_EGRESS = 0xBF03;
const bit<16> PPPOE_PROTOCOL_IP4 = 0x0021;
const bit<16> PPPOE_PROTOCOL_IP6 = 0x0057;
const bit<16> PPPOE_PROTOCOL_MPLS = 0x0281;
const bit<8> PROTO_ICMP = 1;
const bit<8> PROTO_TCP = 6;
const bit<8> PROTO_UDP = 17;
const bit<8> PROTO_ICMPV6 = 58;
const bit<4> IPV4_MIN_IHL = 5;
const fwd_type_t FWD_BRIDGING = 0;
const fwd_type_t FWD_MPLS = 1;
const fwd_type_t FWD_IPV4_UNICAST = 2;
const fwd_type_t FWD_IPV4_MULTICAST = 3;
const fwd_type_t FWD_IPV6_UNICAST = 4;
const fwd_type_t FWD_IPV6_MULTICAST = 5;
const fwd_type_t FWD_UNKNOWN = 7;
const vlan_id_t DEFAULT_VLAN_ID = 12w4094;
const bit<8> DEFAULT_MPLS_TTL = 64;
const bit<8> DEFAULT_IPV4_TTL = 64;
action nop() {
    NoAction();
}
enum bit<8> BridgedMdType_t {
    INVALID = 0,
    INGRESS_TO_EGRESS = 1,
    EGRESS_MIRROR = 2,
    INGRESS_MIRROR = 3
}
enum bit<3> FabricMirrorType_t {
    INVALID = 0,
    INT_REPORT = 1
}
enum bit<2> CpuLoopbackMode_t {
    DISABLED = 0,
    DIRECT = 1,
    INGRESS = 2
}
const PortId_t RECIRC_PORT_PIPE_0 = 0x44;
const PortId_t RECIRC_PORT_PIPE_1 = 0xC4;
const PortId_t RECIRC_PORT_PIPE_2 = 0x144;
const PortId_t RECIRC_PORT_PIPE_3 = 0x1C4;
const bit<6> INT_DSCP = 0x1;
const bit<4> NPROTO_ETHERNET = 0;
const bit<4> NPROTO_TELEMETRY_DROP_HEADER = 1;
const bit<4> NPROTO_TELEMETRY_SWITCH_LOCAL_HEADER = 2;
const bit<16> REPORT_FIXED_HEADER_BYTES = 12;
const bit<16> DROP_REPORT_HEADER_BYTES = 12;
const bit<16> LOCAL_REPORT_HEADER_BYTES = 16;
const bit<16> REPORT_MIRROR_HEADER_BYTES = 31;
const bit<16> ETH_FCS_LEN = 4;
const MirrorId_t REPORT_MIRROR_SESS_PIPE_0 = 300;
const MirrorId_t REPORT_MIRROR_SESS_PIPE_1 = 301;
const MirrorId_t REPORT_MIRROR_SESS_PIPE_2 = 302;
const MirrorId_t REPORT_MIRROR_SESS_PIPE_3 = 303;
typedef bit<16> flow_report_filter_index_t;
typedef bit<16> drop_report_filter_index_t;
enum bit<2> IntReportType_t {
    NO_REPORT = 0,
    LOCAL = 1,
    DROP = 2,
    QUEUE = 3
}
const bit<8> DROP_REASON_UNSET = 0;
const bit<8> DROP_REASON_UNKNOWN = 128;
const bit<8> DROP_REASON_PORT_VLAN_MAPPING_MISS = 129;
const bit<8> DROP_REASON_ACL_DENY = 130;
const bit<8> DROP_REASON_NEXT_ID_MISS = 131;
const bit<8> DROP_REASON_BRIDGING_MISS = 132;
const bit<8> DROP_REASON_MPLS_MISS = 133;
const bit<8> DROP_REASON_ROUTING_V4_MISS = 134;
const bit<8> DROP_REASON_ROUTING_V6_MISS = 135;
const bit<8> DROP_REASON_EGRESS_NEXT_MISS = 136;
@controller_header("packet_in")
header packet_in_header_t {
    PortId_t ingress_port;
    bit<7> _pad0;
}
@controller_header("packet_out")
header packet_out_header_t {
    PortId_t egress_port;
    CpuLoopbackMode_t cpu_loopback_mode;
    @padding bit<85> pad0;
    bit<16> ether_type;
}
header ethernet_t {
    mac_addr_t dst_addr;
    mac_addr_t src_addr;
}
header eth_type_t {
    bit<16> value;
}
header vlan_tag_t {
    bit<16> eth_type;
    bit<3> pri;
    bit<1> cfi;
    vlan_id_t vlan_id;
}
header mpls_t {
    mpls_label_t label;
    bit<3> tc;
    bit<1> bos;
    bit<8> ttl;
}
header pppoe_t {
    bit<4> version;
    bit<4> type_id;
    bit<8> code;
    bit<16> session_id;
    bit<16> length;
    bit<16> protocol;
}
header ipv4_t {
    bit<4> version;
    bit<4> ihl;
    bit<6> dscp;
    bit<2> ecn;
    bit<16> total_len;
    bit<16> identification;
    bit<3> flags;
    bit<13> frag_offset;
    bit<8> ttl;
    bit<8> protocol;
    bit<16> hdr_checksum;
    bit<32> src_addr;
    bit<32> dst_addr;
}
header ipv6_t {
    bit<4> version;
    bit<8> traffic_class;
    bit<20> flow_label;
    bit<16> payload_len;
    bit<8> next_hdr;
    bit<8> hop_limit;
    bit<128> src_addr;
    bit<128> dst_addr;
}
header tcp_t {
    bit<16> sport;
    bit<16> dport;
    bit<32> seq_no;
    bit<32> ack_no;
    bit<4> data_offset;
    bit<3> res;
    bit<3> ecn;
    bit<6> ctrl;
    bit<16> window;
    bit<16> checksum;
    bit<16> urgent_ptr;
}
header udp_t {
    bit<16> sport;
    bit<16> dport;
    bit<16> len;
    bit<16> checksum;
}
header icmp_t {
    bit<8> icmp_type;
    bit<8> icmp_code;
    bit<16> checksum;
    bit<16> identifier;
    bit<16> sequence_number;
    bit<64> timestamp;
}
header gtpu_t {
    bit<3> version;
    bit<1> pt;
    bit<1> spare;
    bit<1> ex_flag;
    bit<1> seq_flag;
    bit<1> npdu_flag;
    bit<8> msgtype;
    bit<16> msglen;
    teid_t teid;
}
@flexible
struct spgw_bridged_metadata_t {
    l4_port_t inner_l4_sport;
    l4_port_t inner_l4_dport;
    bit<16> ipv4_len_for_encap;
    bool needs_gtpu_encap;
    bool skip_spgw;
    bool skip_egress_pdr_ctr;
    teid_t gtpu_teid;
    ipv4_addr_t gtpu_tunnel_sip;
    ipv4_addr_t gtpu_tunnel_dip;
    l4_port_t gtpu_tunnel_sport;
    pdr_ctr_id_t pdr_ctr_id;
}
struct spgw_ingress_metadata_t {
    bool needs_gtpu_decap;
    bool notify_spgwc;
    far_id_t far_id;
    SpgwInterface src_iface;
}
header report_fixed_header_t {
    bit<4> ver;
    bit<4> nproto;
    bit<1> d;
    bit<1> q;
    bit<1> f;
    bit<15> rsvd;
    bit<6> hw_id;
    bit<32> seq_no;
    bit<32> ig_tstamp;
}
header common_report_header_t {
    bit<32> switch_id;
    bit<16> ig_port;
    bit<16> eg_port;
    bit<8> queue_id;
}
header drop_report_header_t {
    bit<8> drop_reason;
    bit<16> pad;
}
header local_report_header_t {
    bit<24> queue_occupancy;
    bit<32> eg_tstamp;
}
@pa_no_overlay("egress", "fabric_md.int_mirror_md.bmd_type")
@pa_no_overlay("egress", "fabric_md.int_mirror_md.mirror_type")
@pa_no_overlay("egress", "fabric_md.int_mirror_md.switch_id")
@pa_no_overlay("egress", "fabric_md.int_mirror_md.ig_port")
@pa_no_overlay("egress", "fabric_md.int_mirror_md.eg_port")
@pa_no_overlay("egress", "fabric_md.int_mirror_md.queue_id")
@pa_no_overlay("egress", "fabric_md.int_mirror_md.queue_occupancy")
@pa_no_overlay("egress", "fabric_md.int_mirror_md.ig_tstamp")
@pa_no_overlay("egress", "fabric_md.int_mirror_md.eg_tstamp")
@pa_no_overlay("egress", "fabric_md.int_mirror_md.drop_reason")
@pa_no_overlay("egress", "fabric_md.int_mirror_md.ip_eth_type")
@pa_no_overlay("egress", "fabric_md.int_mirror_md.report_type")
@pa_no_overlay("egress", "fabric_md.int_mirror_md.flow_hash")
@pa_no_overlay("egress", "fabric_md.int_mirror_md.strip_gtpu")
header int_mirror_metadata_t {
    BridgedMdType_t bmd_type;
    @padding bit<5> _pad0;
    FabricMirrorType_t mirror_type;
    bit<32> switch_id;
    bit<16> ig_port;
    bit<16> eg_port;
    bit<8> queue_id;
    bit<24> queue_occupancy;
    bit<32> ig_tstamp;
    bit<32> eg_tstamp;
    bit<8> drop_reason;
    bit<16> ip_eth_type;
    @padding bit<6> _pad2;
    IntReportType_t report_type;
    flow_hash_t flow_hash;
    @padding bit<7> _pad3;
    bit<1> strip_gtpu;
}
@flexible
struct int_bridged_metadata_t {
    IntReportType_t report_type;
    MirrorId_t mirror_session_id;
}
struct int_metadata_t {
    bit<32> hop_latency;
    bit<48> timestamp;
}
@flexible
struct bridged_metadata_base_t {
    bool is_multicast;
    fwd_type_t fwd_type;
    PortId_t ig_port;
    vlan_id_t vlan_id;
    mpls_label_t mpls_label;
    bit<8> mpls_ttl;
    bit<48> ig_tstamp;
    bit<16> ip_eth_type;
    bit<8> ip_proto;
    l4_port_t l4_sport;
    l4_port_t l4_dport;
    flow_hash_t flow_hash;
}
header bridged_metadata_t {
    BridgedMdType_t bmd_type;
    bridged_metadata_base_t base;
    spgw_bridged_metadata_t spgw;
    int_bridged_metadata_t int_bmd;
}
@flexible
@pa_auto_init_metadata
struct fabric_ingress_metadata_t {
    bridged_metadata_t bridged;
    bit<32> ipv4_src;
    bit<32> ipv4_dst;
    bool ipv4_checksum_err;
    bool skip_forwarding;
    bool skip_next;
    next_id_t next_id;
    bool inner_ipv4_checksum_err;
    spgw_ingress_metadata_t spgw;
    int_mirror_metadata_t int_mirror_md;
}
header common_egress_metadata_t {
    BridgedMdType_t bmd_type;
    @padding bit<5> _pad;
    FabricMirrorType_t mirror_type;
}
@flexible
@pa_auto_init_metadata
@pa_no_overlay("egress", "fabric_md.mpls_stripped")
struct fabric_egress_metadata_t {
    bridged_metadata_t bridged;
    PortId_t cpu_port;
    bool inner_ipv4_checksum_err;
    bit<1> mpls_stripped;
    int_mirror_metadata_t int_mirror_md;
    int_metadata_t int_md;
}
header fake_ethernet_t {
    @padding bit<48> _pad0;
    @padding bit<48> _pad1;
    bit<16> ether_type;
}
struct parsed_headers_t {
    fake_ethernet_t fake_ethernet;
    ethernet_t ethernet;
    vlan_tag_t vlan_tag;
    eth_type_t eth_type;
    mpls_t mpls;
    ipv4_t ipv4;
    ipv6_t ipv6;
    tcp_t tcp;
    udp_t udp;
    icmp_t icmp;
    ipv4_t outer_ipv4;
    udp_t outer_udp;
    gtpu_t outer_gtpu;
    gtpu_t gtpu;
    ipv4_t inner_ipv4;
    tcp_t inner_tcp;
    udp_t inner_udp;
    icmp_t inner_icmp;
    packet_out_header_t packet_out;
    packet_in_header_t packet_in;
    ethernet_t report_ethernet;
    eth_type_t report_eth_type;
    mpls_t report_mpls;
    ipv4_t report_ipv4;
    udp_t report_udp;
    report_fixed_header_t report_fixed_header;
    common_report_header_t common_report_header;
    local_report_header_t local_report_header;
    drop_report_header_t drop_report_header;
}
parser IntReportMirrorParser (packet_in packet,
    out parsed_headers_t hdr,
    out fabric_egress_metadata_t fabric_md,
    out egress_intrinsic_metadata_t eg_intr_md) {
    state start {
        packet.extract(fabric_md.int_mirror_md);
        fabric_md.bridged.bmd_type = fabric_md.int_mirror_md.bmd_type;
        fabric_md.bridged.base.vlan_id = DEFAULT_VLAN_ID;
        fabric_md.bridged.base.mpls_label = 0;
        fabric_md.bridged.spgw.skip_spgw = true;
        hdr.report_eth_type.value = ETHERTYPE_IPV4;
        hdr.report_ipv4 = {
            4w4,
            4w5,
            INT_DSCP,
            2w0,
            0,
            0,
            0,
            0,
            DEFAULT_IPV4_TTL,
            PROTO_UDP,
            0,
            0,
            0
        };
        hdr.report_fixed_header = {
            0,
            NPROTO_TELEMETRY_SWITCH_LOCAL_HEADER,
            0,
            0,
            1,
            0,
            0,
            0,
            fabric_md.int_mirror_md.ig_tstamp
        };
        hdr.common_report_header = {
            fabric_md.int_mirror_md.switch_id,
            fabric_md.int_mirror_md.ig_port,
            fabric_md.int_mirror_md.eg_port,
            fabric_md.int_mirror_md.queue_id
        };
        hdr.local_report_header = {
            fabric_md.int_mirror_md.queue_occupancy,
            fabric_md.int_mirror_md.eg_tstamp
        };
        hdr.drop_report_header = {
            fabric_md.int_mirror_md.drop_reason,
            0
        };
        transition parse_eth_hdr;
    }
    state parse_eth_hdr {
        packet.extract(hdr.ethernet);
        transition select(packet.lookahead<bit<16>>()) {
            ETHERTYPE_VLAN &&& 0xEFFF: parse_vlan_tag;
            default: check_eth_type;
        }
    }
    state parse_vlan_tag {
        packet.extract(hdr.vlan_tag);
        transition select(packet.lookahead<bit<16>>()) {
            default: check_eth_type;
        }
    }
    state check_eth_type {
        packet.extract(hdr.eth_type);
        transition select(hdr.eth_type.value, fabric_md.int_mirror_md.strip_gtpu) {
            (ETHERTYPE_MPLS, _): strip_mpls;
            (ETHERTYPE_IPV4, 0): accept;
            (ETHERTYPE_IPV4, 1): strip_ipv4_udp_gtpu;
            (ETHERTYPE_IPV6, 0): accept;
            (ETHERTYPE_IPV6, 1): strip_ipv6_udp_gtpu;
            default: reject;
        }
    }
    state strip_mpls {
        fabric_md.mpls_stripped = 1;
        packet.advance(4 * 8);
        transition select(fabric_md.int_mirror_md.strip_gtpu, packet.lookahead<bit<4>>()) {
            (1, 4): strip_ipv4_udp_gtpu;
            (1, 6): strip_ipv6_udp_gtpu;
            (0, _): accept;
            default: reject;
        }
    }
    state strip_ipv4_udp_gtpu {
        packet.advance((20 + 8 + 8) * 8);
        transition accept;
    }
    state strip_ipv6_udp_gtpu {
        packet.advance((40 + 8 + 8) * 8);
        transition accept;
    }
}
parser FabricIngressParser (packet_in packet,
    out parsed_headers_t hdr,
    out fabric_ingress_metadata_t fabric_md,
    out ingress_intrinsic_metadata_t ig_intr_md) {
    Checksum() ipv4_checksum;
    Checksum() inner_ipv4_checksum;
    state start {
        packet.extract(ig_intr_md);
        packet.advance(PORT_METADATA_SIZE);
        fabric_md.bridged.setValid();
        fabric_md.bridged.bmd_type = BridgedMdType_t.INGRESS_TO_EGRESS;
        fabric_md.bridged.base.ig_port = ig_intr_md.ingress_port;
        fabric_md.bridged.base.ig_tstamp = ig_intr_md.ingress_mac_tstamp;
        fabric_md.int_mirror_md.drop_reason = DROP_REASON_UNSET;
        transition check_ethernet;
    }
    state check_ethernet {
        fake_ethernet_t tmp = packet.lookahead<fake_ethernet_t>();
        transition select(tmp.ether_type) {
            ETHERTYPE_CPU_LOOPBACK_INGRESS: parse_fake_ethernet;
            ETHERTYPE_CPU_LOOPBACK_EGRESS: parse_fake_ethernet_and_accept;
            ETHERTYPE_PACKET_OUT: parse_packet_out;
            default: parse_ethernet;
        }
    }
    state parse_fake_ethernet {
        packet.extract(hdr.fake_ethernet);
        transition parse_ethernet;
    }
    state parse_fake_ethernet_and_accept {
        packet.extract(hdr.fake_ethernet);
        transition accept;
    }
    state parse_packet_out {
        packet.extract(hdr.packet_out);
        transition accept;
    }
    state parse_ethernet {
        packet.extract(hdr.ethernet);
        transition select(packet.lookahead<bit<16>>()) {
            ETHERTYPE_QINQ: parse_vlan_tag;
            ETHERTYPE_VLAN &&& 0xEFFF: parse_vlan_tag;
            default: parse_untagged;
        }
    }
    state parse_vlan_tag {
        packet.extract(hdr.vlan_tag);
        fabric_md.bridged.base.vlan_id = hdr.vlan_tag.vlan_id;
        transition select(packet.lookahead<bit<16>>()) {
            default: parse_eth_type;
        }
    }
    state parse_untagged {
        fabric_md.bridged.base.vlan_id = DEFAULT_VLAN_ID;
        transition parse_eth_type;
    }
    state parse_eth_type {
        packet.extract(hdr.eth_type);
        transition select(hdr.eth_type.value) {
            ETHERTYPE_MPLS: parse_mpls;
            ETHERTYPE_IPV4: parse_non_mpls_headers;
            ETHERTYPE_IPV6: parse_non_mpls_headers;
            default: accept;
        }
    }
    state parse_mpls {
        packet.extract(hdr.mpls);
        fabric_md.bridged.base.mpls_label = hdr.mpls.label;
        fabric_md.bridged.base.mpls_ttl = hdr.mpls.ttl;
        transition select(packet.lookahead<bit<4>>()) {
            4: parse_ipv4;
            6: parse_ipv6;
            default: reject;
        }
    }
    state parse_non_mpls_headers {
        fabric_md.bridged.base.mpls_label = 0;
        fabric_md.bridged.base.mpls_ttl = DEFAULT_MPLS_TTL + 1;
        transition select(hdr.eth_type.value) {
            ETHERTYPE_IPV4: parse_ipv4;
            ETHERTYPE_IPV6: parse_ipv6;
            default: accept;
        }
    }
    state parse_ipv4 {
        packet.extract(hdr.ipv4);
        fabric_md.ipv4_src = hdr.ipv4.src_addr;
        fabric_md.ipv4_dst = hdr.ipv4.dst_addr;
        fabric_md.bridged.base.ip_proto = hdr.ipv4.protocol;
        fabric_md.bridged.base.ip_eth_type = ETHERTYPE_IPV4;
        ipv4_checksum.add(hdr.ipv4);
        fabric_md.ipv4_checksum_err = ipv4_checksum.verify();
        transition select(hdr.ipv4.protocol) {
            PROTO_TCP: parse_tcp;
            PROTO_UDP: parse_udp;
            PROTO_ICMP: parse_icmp;
            default: accept;
        }
    }
    state parse_ipv6 {
        packet.extract(hdr.ipv6);
        fabric_md.bridged.base.ip_proto = hdr.ipv6.next_hdr;
        fabric_md.bridged.base.ip_eth_type = ETHERTYPE_IPV6;
        transition select(hdr.ipv6.next_hdr) {
            PROTO_TCP: parse_tcp;
            PROTO_UDP: parse_udp;
            PROTO_ICMPV6: parse_icmp;
            default: accept;
        }
    }
    state parse_tcp {
        packet.extract(hdr.tcp);
        fabric_md.bridged.base.l4_sport = hdr.tcp.sport;
        fabric_md.bridged.base.l4_dport = hdr.tcp.dport;
        transition accept;
    }
    state parse_udp {
        packet.extract(hdr.udp);
        fabric_md.bridged.base.l4_sport = hdr.udp.sport;
        fabric_md.bridged.base.l4_dport = hdr.udp.dport;
        transition select(hdr.udp.dport) {
            2152: parse_gtpu;
            default: accept;
        }
    }
    state parse_icmp {
        packet.extract(hdr.icmp);
        transition accept;
    }
    state parse_gtpu {
        packet.extract(hdr.gtpu);
        fabric_md.int_mirror_md.strip_gtpu = 1;
        transition parse_inner_ipv4;
    }
    state parse_inner_ipv4 {
        packet.extract(hdr.inner_ipv4);
        inner_ipv4_checksum.add(hdr.inner_ipv4);
        fabric_md.inner_ipv4_checksum_err = inner_ipv4_checksum.verify();
        transition select(hdr.inner_ipv4.protocol) {
            PROTO_TCP: parse_inner_tcp;
            PROTO_UDP: parse_inner_udp;
            PROTO_ICMP: parse_inner_icmp;
            default: accept;
        }
    }
    state parse_inner_tcp {
        packet.extract(hdr.inner_tcp);
        fabric_md.bridged.spgw.inner_l4_sport = hdr.inner_tcp.sport;
        fabric_md.bridged.spgw.inner_l4_dport = hdr.inner_tcp.dport;
        transition accept;
    }
    state parse_inner_udp {
        packet.extract(hdr.inner_udp);
        fabric_md.bridged.spgw.inner_l4_sport = hdr.inner_udp.sport;
        fabric_md.bridged.spgw.inner_l4_dport = hdr.inner_udp.dport;
        transition accept;
    }
    state parse_inner_icmp {
        packet.extract(hdr.inner_icmp);
        transition accept;
    }
}
control FabricIngressMirror(
    in parsed_headers_t hdr,
    in fabric_ingress_metadata_t fabric_md,
    in ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr) {
    Mirror() mirror;
    apply {
        if (ig_intr_md_for_dprsr.mirror_type == (bit<3>)FabricMirrorType_t.INT_REPORT) {
            mirror.emit<int_mirror_metadata_t>(fabric_md.bridged.int_bmd.mirror_session_id,
                                               fabric_md.int_mirror_md);
        }
    }
}
control FabricIngressDeparser(packet_out packet,
    inout parsed_headers_t hdr,
    in fabric_ingress_metadata_t fabric_md,
    in ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr) {
    FabricIngressMirror() ingress_mirror;
    apply {
        ingress_mirror.apply(hdr, fabric_md, ig_intr_md_for_dprsr);
        packet.emit(fabric_md.bridged);
        packet.emit(hdr.fake_ethernet);
        packet.emit(hdr.packet_in);
        packet.emit(hdr.ethernet);
        packet.emit(hdr.vlan_tag);
        packet.emit(hdr.eth_type);
        packet.emit(hdr.ipv4);
        packet.emit(hdr.ipv6);
        packet.emit(hdr.tcp);
        packet.emit(hdr.udp);
        packet.emit(hdr.icmp);
        packet.emit(hdr.gtpu);
        packet.emit(hdr.inner_ipv4);
        packet.emit(hdr.inner_tcp);
        packet.emit(hdr.inner_udp);
        packet.emit(hdr.inner_icmp);
    }
}
parser FabricEgressParser (packet_in packet,
    out parsed_headers_t hdr,
    out fabric_egress_metadata_t fabric_md,
    out egress_intrinsic_metadata_t eg_intr_md) {
    Checksum() inner_ipv4_checksum;
    IntReportMirrorParser() int_report_mirror_parser;
    state start {
        packet.extract(eg_intr_md);
        fabric_md.cpu_port = 0;
        common_egress_metadata_t common_eg_md = packet.lookahead<common_egress_metadata_t>();
        transition select(common_eg_md.bmd_type, common_eg_md.mirror_type) {
            (BridgedMdType_t.INGRESS_TO_EGRESS, _): parse_bridged_md;
            (BridgedMdType_t.EGRESS_MIRROR, FabricMirrorType_t.INT_REPORT): parse_int_report_mirror;
            (BridgedMdType_t.INGRESS_MIRROR, FabricMirrorType_t.INT_REPORT): parse_int_report_mirror;
            default: reject;
        }
    }
    state parse_bridged_md {
        packet.extract(fabric_md.bridged);
        transition check_ethernet;
    }
    state parse_int_report_mirror {
        int_report_mirror_parser.apply(packet, hdr, fabric_md, eg_intr_md);
        transition accept;
    }
    state check_ethernet {
        fake_ethernet_t tmp = packet.lookahead<fake_ethernet_t>();
        transition select(tmp.ether_type) {
            ETHERTYPE_CPU_LOOPBACK_INGRESS: set_cpu_loopback_egress;
            ETHERTYPE_CPU_LOOPBACK_EGRESS: reject;
            default: parse_ethernet;
        }
    }
    state set_cpu_loopback_egress {
        hdr.fake_ethernet.setValid();
        hdr.fake_ethernet.ether_type = ETHERTYPE_CPU_LOOPBACK_EGRESS;
        packet.advance(14 * 8);
        transition parse_ethernet;
    }
    state parse_ethernet {
        packet.extract(hdr.ethernet);
        transition select(packet.lookahead<bit<16>>()) {
            ETHERTYPE_VLAN &&& 0xEFFF: parse_vlan_tag;
            default: parse_eth_type;
        }
    }
    state parse_vlan_tag {
        packet.extract(hdr.vlan_tag);
        transition select(packet.lookahead<bit<16>>()) {
            default: parse_eth_type;
        }
    }
    state parse_eth_type {
        packet.extract(hdr.eth_type);
        transition select(hdr.eth_type.value) {
            ETHERTYPE_IPV4: parse_ipv4;
            ETHERTYPE_IPV6: parse_ipv6;
            ETHERTYPE_MPLS: parse_mpls;
            default: accept;
        }
    }
    state parse_mpls {
        packet.extract(hdr.mpls);
        transition select(packet.lookahead<bit<4>>()) {
            4: parse_ipv4;
            6: parse_ipv6;
            default: accept;
        }
    }
    state parse_ipv4 {
        packet.extract(hdr.ipv4);
        transition select(hdr.ipv4.protocol) {
            PROTO_TCP: parse_tcp;
            PROTO_UDP: parse_udp;
            PROTO_ICMP: parse_icmp;
            default: accept;
        }
    }
    state parse_ipv6 {
        packet.extract(hdr.ipv6);
        transition select(hdr.ipv6.next_hdr) {
            PROTO_TCP: parse_tcp;
            PROTO_UDP: parse_udp;
            PROTO_ICMPV6: parse_icmp;
            default: accept;
        }
    }
    state parse_tcp {
        packet.extract(hdr.tcp);
        transition accept;
    }
    state parse_udp {
        packet.extract(hdr.udp);
        transition select(hdr.udp.dport) {
            2152: parse_gtpu;
            default: accept;
        }
    }
    state parse_icmp {
        packet.extract(hdr.icmp);
        transition accept;
    }
    state parse_gtpu {
        packet.extract(hdr.gtpu);
        fabric_md.int_mirror_md.strip_gtpu = 1;
        transition parse_inner_ipv4;
    }
    state parse_inner_ipv4 {
        packet.extract(hdr.inner_ipv4);
        inner_ipv4_checksum.add(hdr.inner_ipv4);
        fabric_md.inner_ipv4_checksum_err = inner_ipv4_checksum.verify();
        transition select(hdr.inner_ipv4.protocol) {
            PROTO_TCP: parse_inner_tcp;
            PROTO_UDP: parse_inner_udp;
            PROTO_ICMP: parse_inner_icmp;
            default: accept;
        }
    }
    state parse_inner_tcp {
        packet.extract(hdr.inner_tcp);
        transition accept;
    }
    state parse_inner_udp {
        packet.extract(hdr.inner_udp);
        transition accept;
    }
    state parse_inner_icmp {
        packet.extract(hdr.inner_icmp);
        transition accept;
    }
}
control FabricEgressMirror(
    in parsed_headers_t hdr,
    in fabric_egress_metadata_t fabric_md,
    in egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr) {
    Mirror() mirror;
    apply {
        if (eg_intr_md_for_dprsr.mirror_type == (bit<3>)FabricMirrorType_t.INT_REPORT) {
            mirror.emit<int_mirror_metadata_t>(fabric_md.bridged.int_bmd.mirror_session_id,
                                               fabric_md.int_mirror_md);
        }
    }
}
control FabricEgressDeparser(packet_out packet,
    inout parsed_headers_t hdr,
    in fabric_egress_metadata_t fabric_md,
    in egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr) {
    Checksum() ipv4_checksum;
    FabricEgressMirror() egress_mirror;
    Checksum() outer_ipv4_checksum;
    Checksum() report_ipv4_checksum;
    apply {
        if (hdr.ipv4.isValid()) {
            hdr.ipv4.hdr_checksum = ipv4_checksum.update({
                hdr.ipv4.version,
                hdr.ipv4.ihl,
                hdr.ipv4.dscp,
                hdr.ipv4.ecn,
                hdr.ipv4.total_len,
                hdr.ipv4.identification,
                hdr.ipv4.flags,
                hdr.ipv4.frag_offset,
                hdr.ipv4.ttl,
                hdr.ipv4.protocol,
                hdr.ipv4.src_addr,
                hdr.ipv4.dst_addr
            });
        }
        if (hdr.outer_ipv4.isValid()) {
            hdr.outer_ipv4.hdr_checksum = outer_ipv4_checksum.update({
                hdr.outer_ipv4.version,
                hdr.outer_ipv4.ihl,
                hdr.outer_ipv4.dscp,
                hdr.outer_ipv4.ecn,
                hdr.outer_ipv4.total_len,
                hdr.outer_ipv4.identification,
                hdr.outer_ipv4.flags,
                hdr.outer_ipv4.frag_offset,
                hdr.outer_ipv4.ttl,
                hdr.outer_ipv4.protocol,
                hdr.outer_ipv4.src_addr,
                hdr.outer_ipv4.dst_addr
            });
        }
        if (hdr.report_ipv4.isValid()) {
            hdr.report_ipv4.hdr_checksum = report_ipv4_checksum.update({
                hdr.report_ipv4.version,
                hdr.report_ipv4.ihl,
                hdr.report_ipv4.dscp,
                hdr.report_ipv4.ecn,
                hdr.report_ipv4.total_len,
                hdr.report_ipv4.identification,
                hdr.report_ipv4.flags,
                hdr.report_ipv4.frag_offset,
                hdr.report_ipv4.ttl,
                hdr.report_ipv4.protocol,
                hdr.report_ipv4.src_addr,
                hdr.report_ipv4.dst_addr
            });
        }
        egress_mirror.apply(hdr, fabric_md, eg_intr_md_for_dprsr);
        packet.emit(hdr.fake_ethernet);
        packet.emit(hdr.packet_in);
        packet.emit(hdr.report_ethernet);
        packet.emit(hdr.report_eth_type);
        packet.emit(hdr.report_mpls);
        packet.emit(hdr.report_ipv4);
        packet.emit(hdr.report_udp);
        packet.emit(hdr.report_fixed_header);
        packet.emit(hdr.common_report_header);
        packet.emit(hdr.local_report_header);
        packet.emit(hdr.drop_report_header);
        packet.emit(hdr.ethernet);
        packet.emit(hdr.vlan_tag);
        packet.emit(hdr.eth_type);
        packet.emit(hdr.mpls);
        packet.emit(hdr.outer_ipv4);
        packet.emit(hdr.outer_udp);
        packet.emit(hdr.outer_gtpu);
        packet.emit(hdr.ipv4);
        packet.emit(hdr.ipv6);
        packet.emit(hdr.tcp);
        packet.emit(hdr.udp);
        packet.emit(hdr.icmp);
        packet.emit(hdr.gtpu);
        packet.emit(hdr.inner_ipv4);
        packet.emit(hdr.inner_tcp);
        packet.emit(hdr.inner_udp);
        packet.emit(hdr.inner_icmp);
    }
}
control PacketIoIngress(inout parsed_headers_t hdr,
                        inout fabric_ingress_metadata_t fabric_md,
                        in ingress_intrinsic_metadata_t ig_intr_md,
                        inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm,
                        inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr) {
    @hidden
    action do_packet_out() {
        ig_intr_md_for_tm.ucast_egress_port = hdr.packet_out.egress_port;
        hdr.packet_out.setInvalid();
        fabric_md.bridged.setInvalid();
        ig_intr_md_for_tm.bypass_egress = 1;
        exit;
    }
    @hidden
    action do_cpu_loopback(bit<16> fake_ether_type) {
        hdr.fake_ethernet.setValid();
        hdr.fake_ethernet.ether_type = fake_ether_type;
        do_packet_out();
    }
    @hidden
    table packet_out_modes {
        key = {
            hdr.packet_out.cpu_loopback_mode: exact;
        }
        actions = {
            do_packet_out;
            do_cpu_loopback;
            @defaultonly nop;
        }
        const default_action = nop();
        size = 3;
        const entries = {
            CpuLoopbackMode_t.DISABLED: do_packet_out();
            CpuLoopbackMode_t.DIRECT: do_cpu_loopback(ETHERTYPE_CPU_LOOPBACK_EGRESS);
            CpuLoopbackMode_t.INGRESS: do_cpu_loopback(ETHERTYPE_CPU_LOOPBACK_INGRESS);
        }
    }
    apply {
        if (hdr.packet_out.isValid()) {
            packet_out_modes.apply();
        } else if (hdr.fake_ethernet.isValid() &&
                       hdr.fake_ethernet.ether_type == ETHERTYPE_CPU_LOOPBACK_EGRESS) {
            ig_intr_md_for_tm.copy_to_cpu = 1;
            ig_intr_md_for_dprsr.drop_ctl = 1;
            ig_intr_md_for_tm.bypass_egress = 1;
            fabric_md.bridged.setInvalid();
            hdr.fake_ethernet.setInvalid();
            hdr.packet_in.setValid();
            hdr.packet_in.ingress_port = ig_intr_md.ingress_port;
            exit;
        }
    }
}
control PacketIoEgress(inout parsed_headers_t hdr,
                       inout fabric_egress_metadata_t fabric_md,
                       in egress_intrinsic_metadata_t eg_intr_md) {
    action set_switch_info(PortId_t cpu_port) {
        fabric_md.cpu_port = cpu_port;
    }
    table switch_info {
        actions = {
            set_switch_info;
            @defaultonly nop;
        }
        default_action = nop;
        const size = 1;
    }
    apply {
        switch_info.apply();
        if (eg_intr_md.egress_port == fabric_md.cpu_port) {
            hdr.packet_in.setValid();
            hdr.packet_in.ingress_port = fabric_md.bridged.base.ig_port;
            hdr.fake_ethernet.setInvalid();
            exit;
        }
    }
}
control Filtering (inout parsed_headers_t hdr,
                   inout fabric_ingress_metadata_t fabric_md,
                   in ingress_intrinsic_metadata_t ig_intr_md) {
    DirectCounter<bit<64>>(CounterType_t.PACKETS_AND_BYTES) ingress_port_vlan_counter;
    action deny() {
        fabric_md.skip_forwarding = true;
        fabric_md.skip_next = true;
        fabric_md.int_mirror_md.drop_reason = DROP_REASON_PORT_VLAN_MAPPING_MISS;
        ingress_port_vlan_counter.count();
    }
    action permit() {
        ingress_port_vlan_counter.count();
    }
    action permit_with_internal_vlan(vlan_id_t vlan_id) {
        fabric_md.bridged.base.vlan_id = vlan_id;
        permit();
    }
    table ingress_port_vlan {
        key = {
            ig_intr_md.ingress_port : exact @name("ig_port");
            hdr.vlan_tag.isValid() : exact @name("vlan_is_valid");
            hdr.vlan_tag.vlan_id : ternary @name("vlan_id");
        }
        actions = {
            deny();
            permit();
            permit_with_internal_vlan();
        }
        const default_action = deny();
        counters = ingress_port_vlan_counter;
        size = 1024;
    }
    DirectCounter<bit<64>>(CounterType_t.PACKETS_AND_BYTES) fwd_classifier_counter;
    action set_forwarding_type(fwd_type_t fwd_type) {
        fabric_md.bridged.base.fwd_type = fwd_type;
        fwd_classifier_counter.count();
    }
    table fwd_classifier {
        key = {
            ig_intr_md.ingress_port : exact @name("ig_port");
            hdr.ethernet.dst_addr : ternary @name("eth_dst");
            hdr.eth_type.value : ternary @name("eth_type");
            fabric_md.bridged.base.ip_eth_type : exact @name("ip_eth_type");
        }
        actions = {
            set_forwarding_type;
        }
        const default_action = set_forwarding_type(FWD_BRIDGING);
        counters = fwd_classifier_counter;
        size = 1024;
    }
    apply {
        ingress_port_vlan.apply();
        fwd_classifier.apply();
    }
}
control Forwarding (inout parsed_headers_t hdr,
                    inout fabric_ingress_metadata_t fabric_md) {
    action int_table_miss(bit<8> drop_reason) {
        fabric_md.int_mirror_md.drop_reason = drop_reason;
    }
    @hidden
    action set_next_id(next_id_t next_id) {
        fabric_md.next_id = next_id;
    }
    DirectCounter<bit<64>>(CounterType_t.PACKETS_AND_BYTES) bridging_counter;
    action set_next_id_bridging(next_id_t next_id) {
        set_next_id(next_id);
        bridging_counter.count();
    }
    table bridging {
        key = {
            fabric_md.bridged.base.vlan_id : exact @name("vlan_id");
            hdr.ethernet.dst_addr : ternary @name("eth_dst");
        }
        actions = {
            set_next_id_bridging;
            @defaultonly int_table_miss;
        }
        const default_action = int_table_miss(DROP_REASON_BRIDGING_MISS);
        counters = bridging_counter;
        size = 1024;
    }
    DirectCounter<bit<64>>(CounterType_t.PACKETS_AND_BYTES) mpls_counter;
    action pop_mpls_and_next(next_id_t next_id) {
        hdr.mpls.setInvalid();
        hdr.eth_type.value = fabric_md.bridged.base.ip_eth_type;
        fabric_md.bridged.base.mpls_label = 0;
        set_next_id(next_id);
        mpls_counter.count();
    }
    table mpls {
        key = {
            fabric_md.bridged.base.mpls_label : exact @name("mpls_label");
        }
        actions = {
            pop_mpls_and_next;
            @defaultonly int_table_miss;
        }
        const default_action = int_table_miss(DROP_REASON_MPLS_MISS);
        counters = mpls_counter;
        size = 1024;
    }
    action set_next_id_routing_v4(next_id_t next_id) {
        set_next_id(next_id);
    }
    action nop_routing_v4() {
    }
    table routing_v4 {
        key = {
            fabric_md.ipv4_dst: lpm @name("ipv4_dst");
        }
        actions = {
            set_next_id_routing_v4;
            nop_routing_v4;
            @defaultonly int_table_miss;
        }
        const default_action = int_table_miss(DROP_REASON_ROUTING_V4_MISS);
        size = 1024;
    }
    action set_next_id_routing_v6(next_id_t next_id) {
        set_next_id(next_id);
    }
    table routing_v6 {
        key = {
            hdr.ipv6.dst_addr: lpm @name("ipv6_dst");
        }
        actions = {
            set_next_id_routing_v6;
            @defaultonly int_table_miss;
        }
        const default_action = int_table_miss(DROP_REASON_ROUTING_V6_MISS);
        size = 1024;
    }
    apply {
        if (fabric_md.bridged.base.fwd_type == FWD_BRIDGING) bridging.apply();
        else if (fabric_md.bridged.base.fwd_type == FWD_MPLS) mpls.apply();
        else if (fabric_md.bridged.base.fwd_type == FWD_IPV4_UNICAST || fabric_md.bridged.base.fwd_type == FWD_IPV4_MULTICAST) routing_v4.apply();
        else if (fabric_md.bridged.base.fwd_type == FWD_IPV6_UNICAST) routing_v6.apply();
    }
}
control Acl (inout parsed_headers_t hdr,
             inout fabric_ingress_metadata_t fabric_md,
             in ingress_intrinsic_metadata_t ig_intr_md,
             inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr,
             inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm) {
    DirectCounter<bit<64>>(CounterType_t.PACKETS_AND_BYTES) acl_counter;
    action set_next_id_acl(next_id_t next_id) {
        fabric_md.next_id = next_id;
        acl_counter.count();
    }
    action punt_to_cpu() {
        ig_intr_md_for_tm.copy_to_cpu = 1;
        ig_intr_md_for_dprsr.drop_ctl = 1;
        fabric_md.skip_next = true;
        acl_counter.count();
    }
    action copy_to_cpu() {
        ig_intr_md_for_tm.copy_to_cpu = 1;
        acl_counter.count();
    }
    action drop() {
        ig_intr_md_for_dprsr.drop_ctl = 1;
        fabric_md.skip_next = true;
        fabric_md.int_mirror_md.drop_reason = DROP_REASON_ACL_DENY;
        acl_counter.count();
    }
    action set_output_port(PortId_t port_num) {
        ig_intr_md_for_tm.ucast_egress_port = port_num;
        fabric_md.skip_next = true;
        acl_counter.count();
    }
    action nop_acl() {
        acl_counter.count();
    }
    table acl {
        key = {
            ig_intr_md.ingress_port : ternary @name("ig_port");
            fabric_md.bridged.base.ip_proto : ternary @name("ip_proto");
            fabric_md.bridged.base.l4_sport : ternary @name("l4_sport");
            fabric_md.bridged.base.l4_dport : ternary @name("l4_dport");
            hdr.ethernet.dst_addr : ternary @name("eth_dst");
            hdr.ethernet.src_addr : ternary @name("eth_src");
            hdr.vlan_tag.vlan_id : ternary @name("vlan_id");
            hdr.eth_type.value : ternary @name("eth_type");
            fabric_md.ipv4_src : ternary @name("ipv4_src");
            fabric_md.ipv4_dst : ternary @name("ipv4_dst");
            hdr.icmp.icmp_type : ternary @name("icmp_type");
            hdr.icmp.icmp_code : ternary @name("icmp_code");
        }
        actions = {
            set_next_id_acl;
            punt_to_cpu;
            copy_to_cpu;
            drop;
            set_output_port;
            nop_acl;
        }
        const default_action = nop_acl();
        size = 1024;
        counters = acl_counter;
    }
    apply {
        acl.apply();
    }
}
control Next (inout parsed_headers_t hdr,
              inout fabric_ingress_metadata_t fabric_md,
              in ingress_intrinsic_metadata_t ig_intr_md,
              inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm) {
    @hidden
    action output(PortId_t port_num) {
        ig_intr_md_for_tm.ucast_egress_port = port_num;
    }
    @hidden
    action rewrite_smac(mac_addr_t smac) {
        hdr.ethernet.src_addr = smac;
    }
    @hidden
    action rewrite_dmac(mac_addr_t dmac) {
        hdr.ethernet.dst_addr = dmac;
    }
    @hidden
    action set_mpls_label(mpls_label_t label) {
        fabric_md.bridged.base.mpls_label = label;
    }
    @hidden
    action routing(PortId_t port_num, mac_addr_t smac, mac_addr_t dmac) {
        rewrite_smac(smac);
        rewrite_dmac(dmac);
        output(port_num);
    }
    @hidden
    action mpls_routing(PortId_t port_num, mac_addr_t smac, mac_addr_t dmac,
                        mpls_label_t label) {
        set_mpls_label(label);
        routing(port_num, smac, dmac);
    }
    DirectCounter<bit<64>>(CounterType_t.PACKETS_AND_BYTES) next_vlan_counter;
    action set_vlan(vlan_id_t vlan_id) {
        fabric_md.bridged.base.vlan_id = vlan_id;
        next_vlan_counter.count();
    }
    table next_vlan {
        key = {
            fabric_md.next_id: exact @name("next_id");
        }
        actions = {
            set_vlan;
            @defaultonly nop;
        }
        const default_action = nop();
        counters = next_vlan_counter;
        size = 1024;
    }
    ActionProfile(32w1024) hashed_profile;
    Hash<bit<16>>(HashAlgorithm_t.CRC16) selector_hash;
    ActionSelector(hashed_profile,
                   selector_hash,
                   SelectorMode_t.FAIR,
                   32w16,
                   1024) hashed_selector;
    DirectCounter<bit<64>>(CounterType_t.PACKETS_AND_BYTES) hashed_counter;
    action output_hashed(PortId_t port_num) {
        output(port_num);
        hashed_counter.count();
    }
    action routing_hashed(PortId_t port_num, mac_addr_t smac, mac_addr_t dmac) {
        routing(port_num, smac, dmac);
        hashed_counter.count();
    }
    action mpls_routing_hashed(PortId_t port_num, mac_addr_t smac, mac_addr_t dmac,
                               mpls_label_t label) {
        mpls_routing(port_num, smac, dmac, label);
        hashed_counter.count();
    }
    table hashed {
        key = {
            fabric_md.next_id : exact @name("next_id");
            fabric_md.bridged.base.flow_hash : selector;
        }
        actions = {
            output_hashed;
            routing_hashed;
            mpls_routing_hashed;
            @defaultonly nop;
        }
        implementation = hashed_selector;
        counters = hashed_counter;
        const default_action = nop();
        size = 1024;
    }
    DirectCounter<bit<64>>(CounterType_t.PACKETS_AND_BYTES) multicast_counter;
    action set_mcast_group_id(MulticastGroupId_t group_id) {
        ig_intr_md_for_tm.mcast_grp_a = group_id;
        fabric_md.bridged.base.is_multicast = true;
        multicast_counter.count();
    }
    table multicast {
        key = {
            fabric_md.next_id: exact @name("next_id");
        }
        actions = {
            set_mcast_group_id;
            @defaultonly nop;
        }
        counters = multicast_counter;
        const default_action = nop();
        size = 1024;
    }
    apply {
        hashed.apply();
        multicast.apply();
        next_vlan.apply();
    }
}
control EgressNextControl (inout parsed_headers_t hdr,
                           inout fabric_egress_metadata_t fabric_md,
                           in egress_intrinsic_metadata_t eg_intr_md,
                           inout egress_intrinsic_metadata_for_deparser_t eg_dprsr_md) {
    @hidden
    action pop_mpls_if_present() {
        hdr.mpls.setInvalid();
        hdr.eth_type.value = fabric_md.bridged.base.ip_eth_type;
    }
    @hidden
    action set_mpls() {
        hdr.mpls.setValid();
        hdr.mpls.label = fabric_md.bridged.base.mpls_label;
        hdr.mpls.tc = 3w0;
        hdr.mpls.bos = 1w1;
        hdr.mpls.ttl = fabric_md.bridged.base.mpls_ttl;
        hdr.eth_type.value = ETHERTYPE_MPLS;
    }
    @hidden
    action push_outer_vlan() {
        hdr.vlan_tag.setValid();
        hdr.vlan_tag.eth_type = ETHERTYPE_VLAN;
        hdr.vlan_tag.vlan_id = fabric_md.bridged.base.vlan_id;
    }
    DirectCounter<bit<64>>(CounterType_t.PACKETS_AND_BYTES) egress_vlan_counter;
    action push_vlan() {
        push_outer_vlan();
        egress_vlan_counter.count();
    }
    action pop_vlan() {
        hdr.vlan_tag.setInvalid();
        egress_vlan_counter.count();
    }
    action drop() {
        eg_dprsr_md.drop_ctl = 1;
        egress_vlan_counter.count();
        fabric_md.int_mirror_md.drop_reason = DROP_REASON_EGRESS_NEXT_MISS;
    }
    action keep_vlan_config() {
        egress_vlan_counter.count();
    }
    table egress_vlan {
        key = {
            fabric_md.bridged.base.vlan_id : exact @name("vlan_id");
            eg_intr_md.egress_port : exact @name("eg_port");
        }
        actions = {
            push_vlan;
            pop_vlan;
            keep_vlan_config;
            @defaultonly drop;
        }
        const default_action = drop();
        counters = egress_vlan_counter;
        size = 1024;
    }
    apply {
        if (fabric_md.bridged.base.is_multicast
             && fabric_md.bridged.base.ig_port == eg_intr_md.egress_port) {
            eg_dprsr_md.drop_ctl = 1;
        }
        if (fabric_md.bridged.base.mpls_label == 0) {
            if (hdr.mpls.isValid()) pop_mpls_if_present();
        } else {
            set_mpls();
        }
            egress_vlan.apply();
        if (hdr.mpls.isValid()) {
            hdr.mpls.ttl = hdr.mpls.ttl - 1;
            if (hdr.mpls.ttl == 0) {
                eg_dprsr_md.drop_ctl = 1;
            }
        } else {
            if (hdr.ipv4.isValid() && fabric_md.bridged.base.fwd_type != FWD_BRIDGING) {
                hdr.ipv4.ttl = hdr.ipv4.ttl - 1;
                if (hdr.ipv4.ttl == 0) {
                    eg_dprsr_md.drop_ctl = 1;
                }
            } else if (hdr.ipv6.isValid() && fabric_md.bridged.base.fwd_type != FWD_BRIDGING) {
                hdr.ipv6.hop_limit = hdr.ipv6.hop_limit - 1;
                if (hdr.ipv6.hop_limit == 0) {
                    eg_dprsr_md.drop_ctl = 1;
                }
            }
        }
    }
}
control Hasher(
    in parsed_headers_t hdr,
    inout fabric_ingress_metadata_t fabric_md) {
    Hash<flow_hash_t>(HashAlgorithm_t.CRC32) ipv4_hasher;
    Hash<flow_hash_t>(HashAlgorithm_t.CRC32) ipv6_hasher;
    Hash<flow_hash_t>(HashAlgorithm_t.CRC32) non_ip_hasher;
    apply {
        if (hdr.ipv4.isValid()) {
            fabric_md.bridged.base.flow_hash = ipv4_hasher.get({
                hdr.ipv4.src_addr,
                hdr.ipv4.dst_addr,
                fabric_md.bridged.base.ip_proto,
                fabric_md.bridged.base.l4_sport,
                fabric_md.bridged.base.l4_dport
            });
        } else if (hdr.ipv6.isValid()) {
            fabric_md.bridged.base.flow_hash = ipv6_hasher.get({
                hdr.ipv6.src_addr,
                hdr.ipv6.dst_addr,
                fabric_md.bridged.base.ip_proto,
                fabric_md.bridged.base.l4_sport,
                fabric_md.bridged.base.l4_dport
            });
        } else {
            fabric_md.bridged.base.flow_hash = non_ip_hasher.get({
                hdr.ethernet.dst_addr,
                hdr.ethernet.src_addr,
                hdr.eth_type.value
            });
        }
    }
}
control DecapGtpu(inout parsed_headers_t hdr,
                  inout fabric_ingress_metadata_t fabric_md) {
    @hidden
    action decap_inner_common() {
        fabric_md.bridged.base.ip_eth_type = ETHERTYPE_IPV4;
        fabric_md.bridged.base.ip_proto = hdr.inner_ipv4.protocol;
        fabric_md.ipv4_src = hdr.inner_ipv4.src_addr;
        fabric_md.ipv4_dst = hdr.inner_ipv4.dst_addr;
        fabric_md.bridged.base.l4_sport = fabric_md.bridged.spgw.inner_l4_sport;
        fabric_md.bridged.base.l4_dport = fabric_md.bridged.spgw.inner_l4_dport;
        hdr.ipv4 = hdr.inner_ipv4;
        hdr.inner_ipv4.setInvalid();
        hdr.gtpu.setInvalid();
    }
    @hidden
    action decap_inner_tcp() {
        decap_inner_common();
        hdr.udp.setInvalid();
        hdr.tcp = hdr.inner_tcp;
        hdr.inner_tcp.setInvalid();
    }
    @hidden
    action decap_inner_udp() {
        decap_inner_common();
        hdr.udp = hdr.inner_udp;
        hdr.inner_udp.setInvalid();
    }
    @hidden
    action decap_inner_icmp() {
        decap_inner_common();
        hdr.udp.setInvalid();
        hdr.icmp = hdr.inner_icmp;
        hdr.inner_icmp.setInvalid();
    }
    @hidden
    action decap_inner_unknown() {
        decap_inner_common();
        hdr.udp.setInvalid();
    }
    @hidden
    table decap_gtpu {
        key = {
            hdr.inner_tcp.isValid() : exact;
            hdr.inner_udp.isValid() : exact;
            hdr.inner_icmp.isValid() : exact;
        }
        actions = {
            decap_inner_tcp;
            decap_inner_udp;
            decap_inner_icmp;
            decap_inner_unknown;
        }
        const default_action = decap_inner_unknown;
        const entries = {
            (true, false, false) : decap_inner_tcp();
            (false, true, false) : decap_inner_udp();
            (false, false, true) : decap_inner_icmp();
        }
        size = 3;
    }
    apply {
        decap_gtpu.apply();
    }
}
control SpgwIngress(
        inout parsed_headers_t hdr,
        inout fabric_ingress_metadata_t fabric_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_tm_md) {
    Counter<bit<64>, bit<16>>(2*2048, CounterType_t.PACKETS_AND_BYTES) pdr_counter;
    DecapGtpu() decap_gtpu_from_dbuf;
    DecapGtpu() decap_gtpu;
    action load_iface(SpgwInterface src_iface) {
        fabric_md.spgw.src_iface = src_iface;
        fabric_md.bridged.spgw.skip_spgw = false;
    }
    action iface_miss() {
        fabric_md.spgw.src_iface = SpgwInterface.UNKNOWN;
        fabric_md.bridged.spgw.skip_spgw = true;
    }
    table interfaces {
        key = {
            hdr.ipv4.dst_addr : lpm @name("ipv4_dst_addr");
            hdr.gtpu.isValid() : exact @name("gtpu_is_valid");
        }
        actions = {
            load_iface;
            @defaultonly iface_miss;
        }
        const default_action = iface_miss();
        const size = 64;
    }
    action load_pdr(pdr_ctr_id_t ctr_id,
                    far_id_t far_id,
                    bool needs_gtpu_decap) {
        fabric_md.spgw.far_id = far_id;
        fabric_md.bridged.spgw.pdr_ctr_id = ctr_id;
        fabric_md.spgw.needs_gtpu_decap = needs_gtpu_decap;
    }
    table downlink_pdrs {
        key = {
            hdr.ipv4.dst_addr : exact @name("ue_addr");
        }
        actions = {
            load_pdr;
        }
        size = 2048;
    }
    table uplink_pdrs {
        key = {
            hdr.ipv4.dst_addr : exact @name("tunnel_ipv4_dst");
            hdr.gtpu.teid : exact @name("teid");
        }
        actions = {
            load_pdr;
        }
        size = 2048;
    }
    action set_qid(bit<5> qid) {
           ig_tm_md.qid = qid;
    }
    table qos_classifier {
       key = {
            hdr.ipv4.src_addr : ternary @name("inet_addr") ;
            hdr.ipv4.dst_addr : ternary @name("ue_addr") ;
            fabric_md.bridged.base.l4_sport : ternary @name("inet_l4_port");
            fabric_md.bridged.base.l4_dport : ternary @name("ue_l4_port") ;
            hdr.ipv4.protocol : ternary @name("ip_proto") ;
       }
       actions = {
           set_qid;
           @defaultonly nop;
       }
       const default_action = nop;
       const size = 128;
    }
    action load_normal_far(bool drop,
                           bool notify_cp) {
        fabric_md.skip_forwarding = drop;
        fabric_md.skip_next = drop;
        ig_tm_md.copy_to_cpu = ((bit<1>)notify_cp) | ig_tm_md.copy_to_cpu;
        fabric_md.bridged.spgw.needs_gtpu_encap = false;
        fabric_md.bridged.spgw.skip_egress_pdr_ctr = false;
    }
    @hidden
    action load_common_far(bool drop,
                           bool notify_cp,
                           l4_port_t tunnel_src_port,
                           ipv4_addr_t tunnel_src_addr,
                           ipv4_addr_t tunnel_dst_addr,
                           teid_t teid) {
        fabric_md.skip_forwarding = drop;
        fabric_md.skip_next = drop;
        ig_tm_md.copy_to_cpu = ((bit<1>)notify_cp) | ig_tm_md.copy_to_cpu;
        fabric_md.bridged.spgw.needs_gtpu_encap = true;
        fabric_md.bridged.spgw.gtpu_teid = teid;
        fabric_md.bridged.spgw.gtpu_tunnel_sport = tunnel_src_port;
        fabric_md.bridged.spgw.gtpu_tunnel_sip = tunnel_src_addr;
        fabric_md.bridged.spgw.gtpu_tunnel_dip = tunnel_dst_addr;
        fabric_md.ipv4_src = tunnel_src_addr;
        fabric_md.ipv4_dst = tunnel_dst_addr;
    }
    action load_tunnel_far(bool drop,
                           bool notify_cp,
                           l4_port_t tunnel_src_port,
                           ipv4_addr_t tunnel_src_addr,
                           ipv4_addr_t tunnel_dst_addr,
                           teid_t teid) {
        load_common_far(drop, notify_cp, tunnel_src_port, tunnel_src_addr,
                        tunnel_dst_addr, teid);
        fabric_md.bridged.spgw.skip_egress_pdr_ctr = false;
    }
    action load_dbuf_far(bool drop,
                         bool notify_cp,
                         l4_port_t tunnel_src_port,
                         ipv4_addr_t tunnel_src_addr,
                         ipv4_addr_t tunnel_dst_addr,
                         teid_t teid) {
        load_common_far(drop, notify_cp, tunnel_src_port, tunnel_src_addr,
                        tunnel_dst_addr, teid);
        fabric_md.bridged.spgw.skip_egress_pdr_ctr = true;
    }
    table fars {
        key = {
            fabric_md.spgw.far_id : exact @name("far_id");
        }
        actions = {
            load_normal_far;
            load_tunnel_far;
            load_dbuf_far;
        }
        const default_action = load_normal_far(true, false);
        size = 2*2048;
    }
    apply {
        if (interfaces.apply().hit) {
            if (fabric_md.spgw.src_iface == SpgwInterface.FROM_DBUF) {
                decap_gtpu_from_dbuf.apply(hdr, fabric_md);
            }
            if (hdr.gtpu.isValid()) {
                uplink_pdrs.apply();
            } else {
                downlink_pdrs.apply();
                qos_classifier.apply();
            }
            if (fabric_md.spgw.src_iface != SpgwInterface.FROM_DBUF) {
                pdr_counter.count(fabric_md.bridged.spgw.pdr_ctr_id);
            }
            if (fabric_md.spgw.needs_gtpu_decap) {
                decap_gtpu.apply(hdr, fabric_md);
            }
            fars.apply();
            fabric_md.bridged.spgw.ipv4_len_for_encap = hdr.ipv4.total_len;
        }
    }
}
control SpgwEgress(
        inout parsed_headers_t hdr,
        inout fabric_egress_metadata_t fabric_md) {
    Counter<bit<64>, bit<16>>(2*2048, CounterType_t.PACKETS_AND_BYTES) pdr_counter;
    bit<16> outer_ipv4_len_additive;
    bit<16> outer_udp_len_additive;
    @hidden
    action _preload_length_additives() {
        outer_ipv4_len_additive = 20 + 8 + 8;
        outer_udp_len_additive = 8 + 8;
    }
    @hidden
    action _gtpu_encap() {
        hdr.outer_ipv4.setValid();
        hdr.outer_ipv4.version = 4;
        hdr.outer_ipv4.ihl = IPV4_MIN_IHL;
        hdr.outer_ipv4.dscp = 0;
        hdr.outer_ipv4.ecn = 0;
        hdr.outer_ipv4.total_len = fabric_md.bridged.spgw.ipv4_len_for_encap + outer_ipv4_len_additive;
        hdr.outer_ipv4.identification = 0x1513;
        hdr.outer_ipv4.flags = 0;
        hdr.outer_ipv4.frag_offset = 0;
        hdr.outer_ipv4.ttl = DEFAULT_IPV4_TTL;
        hdr.outer_ipv4.protocol = PROTO_UDP;
        hdr.outer_ipv4.src_addr = fabric_md.bridged.spgw.gtpu_tunnel_sip;
        hdr.outer_ipv4.dst_addr = fabric_md.bridged.spgw.gtpu_tunnel_dip;
        hdr.outer_ipv4.hdr_checksum = 0;
        hdr.outer_udp.setValid();
        hdr.outer_udp.sport = fabric_md.bridged.spgw.gtpu_tunnel_sport;
        hdr.outer_udp.dport = 2152;
        hdr.outer_udp.len = fabric_md.bridged.spgw.ipv4_len_for_encap + outer_udp_len_additive;
        hdr.outer_udp.checksum = 0;
        hdr.outer_gtpu.setValid();
        hdr.outer_gtpu.version = 0x01;
        hdr.outer_gtpu.pt = 0x01;
        hdr.outer_gtpu.spare = 0;
        hdr.outer_gtpu.ex_flag = 0;
        hdr.outer_gtpu.seq_flag = 0;
        hdr.outer_gtpu.npdu_flag = 0;
        hdr.outer_gtpu.msgtype = 0xff;
        hdr.outer_gtpu.msglen = fabric_md.bridged.spgw.ipv4_len_for_encap;
        hdr.outer_gtpu.teid = fabric_md.bridged.spgw.gtpu_teid;
            fabric_md.int_mirror_md.strip_gtpu = 1;
    }
    @hidden
    table gtpu_encap_if_needed {
        key = {
            fabric_md.bridged.spgw.needs_gtpu_encap : exact;
        }
        actions = {
            _gtpu_encap;
        }
        const entries = {
            true : _gtpu_encap();
        }
        size = 1;
    }
    apply {
        if (!fabric_md.bridged.spgw.skip_spgw) {
            _preload_length_additives();
            gtpu_encap_if_needed.apply();
            if (!fabric_md.bridged.spgw.skip_egress_pdr_ctr) {
                pdr_counter.count(fabric_md.bridged.spgw.pdr_ctr_id);
            }
        }
    }
}
const bit<48> DEFAULT_TIMESTAMP_MASK = 0xffffc0000000;
const bit<32> DEFAULT_HOP_LATENCY_MASK = 0xffffff00;
control FlowReportFilter(
    inout parsed_headers_t hdr,
    inout fabric_egress_metadata_t fabric_md,
    in egress_intrinsic_metadata_t eg_intr_md,
    in egress_intrinsic_metadata_from_parser_t eg_prsr_md,
    inout egress_intrinsic_metadata_for_deparser_t eg_dprsr_md) {
    Hash<bit<16>>(HashAlgorithm_t.CRC16) digester;
    bit<16> digest;
    bit<1> flag;
    @hidden
    Register<flow_report_filter_index_t, bit<16>>(1 << 16, 0) filter1;
    @hidden
    Register<flow_report_filter_index_t, bit<16>>(1 << 16, 0) filter2;
    @reduction_or_group("filter")
    RegisterAction<bit<16>, flow_report_filter_index_t, bit<1>>(filter1) filter_get_and_set1 = {
        void apply(inout bit<16> stored_digest, out bit<1> result) {
            result = stored_digest == digest ? 1w1 : 1w0;
            stored_digest = digest;
        }
    };
    @reduction_or_group("filter")
    RegisterAction<bit<16>, flow_report_filter_index_t, bit<1>>(filter2) filter_get_and_set2 = {
        void apply(inout bit<16> stored_digest, out bit<1> result) {
            result = stored_digest == digest ? 1w1 : 1w0;
            stored_digest = digest;
        }
    };
    apply {
        if (fabric_md.int_mirror_md.report_type == IntReportType_t.LOCAL) {
            digest = digester.get({
                fabric_md.bridged.base.ig_port,
                eg_intr_md.egress_port,
                fabric_md.int_md.hop_latency,
                fabric_md.bridged.base.flow_hash,
                fabric_md.int_md.timestamp
            });
            flag = filter_get_and_set1.execute(fabric_md.bridged.base.flow_hash[31:16]);
            flag = flag | filter_get_and_set2.execute(fabric_md.bridged.base.flow_hash[15:0]);
            if (flag == 1) {
                eg_dprsr_md.mirror_type = (bit<3>)FabricMirrorType_t.INVALID;
            }
        }
    }
}
control DropReportFilter(
    inout parsed_headers_t hdr,
    inout fabric_egress_metadata_t fabric_md,
    inout egress_intrinsic_metadata_for_deparser_t eg_dprsr_md) {
    Hash<bit<16>>(HashAlgorithm_t.CRC16) digester;
    bit<16> digest;
    bit<1> flag;
    @hidden
    Register<drop_report_filter_index_t, bit<16>>(1 << 16, 0) filter1;
    @hidden
    Register<drop_report_filter_index_t, bit<16>>(1 << 16, 0) filter2;
    @reduction_or_group("filter")
    RegisterAction<bit<16>, flow_report_filter_index_t, bit<1>>(filter1) filter_get_and_set1 = {
        void apply(inout bit<16> stored_digest, out bit<1> result) {
            result = stored_digest == digest ? 1w1 : 1w0;
            stored_digest = digest;
        }
    };
    @reduction_or_group("filter")
    RegisterAction<bit<16>, flow_report_filter_index_t, bit<1>>(filter2) filter_get_and_set2 = {
        void apply(inout bit<16> stored_digest, out bit<1> result) {
            result = stored_digest == digest ? 1w1 : 1w0;
            stored_digest = digest;
        }
    };
    apply {
        if (fabric_md.int_mirror_md.report_type == IntReportType_t.DROP) {
            digest = digester.get({
                fabric_md.int_mirror_md.flow_hash,
                fabric_md.int_md.timestamp
            });
            flag = filter_get_and_set1.execute(fabric_md.int_mirror_md.flow_hash[31:16]);
            flag = flag | filter_get_and_set2.execute(fabric_md.int_mirror_md.flow_hash[15:0]);
            if (flag == 1) {
                eg_dprsr_md.drop_ctl = 1;
                exit;
            }
        }
    }
}
control IntIngress (
    inout parsed_headers_t hdr,
    inout fabric_ingress_metadata_t fabric_md,
    in ingress_intrinsic_metadata_t ig_intr_md,
    inout ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md,
    inout ingress_intrinsic_metadata_for_tm_t ig_tm_md) {
    action mark_to_report() {
        fabric_md.bridged.int_bmd.report_type = IntReportType_t.LOCAL;
    }
    table watchlist {
        key = {
            hdr.ipv4.src_addr : ternary @name("ipv4_src");
            hdr.ipv4.dst_addr : ternary @name("ipv4_dst");
            fabric_md.bridged.base.ip_proto : ternary @name("ip_proto");
            fabric_md.bridged.base.l4_sport : range @name("l4_sport");
            fabric_md.bridged.base.l4_dport : range @name("l4_dport");
        }
        actions = {
            mark_to_report;
            @defaultonly nop();
        }
        const default_action = nop();
        const size = 64;
    }
    action report_drop(bit<32> switch_id) {
        fabric_md.bridged.int_bmd.report_type = IntReportType_t.DROP;
        ig_dprsr_md.mirror_type = (bit<3>)FabricMirrorType_t.INT_REPORT;
        fabric_md.int_mirror_md.setValid();
        fabric_md.int_mirror_md.bmd_type = BridgedMdType_t.INGRESS_MIRROR;
        fabric_md.int_mirror_md.mirror_type = FabricMirrorType_t.INT_REPORT;
        fabric_md.int_mirror_md.report_type = IntReportType_t.DROP;
        fabric_md.int_mirror_md.switch_id = switch_id;
        fabric_md.int_mirror_md.ig_port = (bit<16>)ig_intr_md.ingress_port;
        fabric_md.int_mirror_md.ip_eth_type = fabric_md.bridged.base.ip_eth_type;
        fabric_md.int_mirror_md.eg_port = (bit<16>)ig_tm_md.ucast_egress_port;
        fabric_md.int_mirror_md.queue_id = (bit<8>)ig_tm_md.qid;
        fabric_md.int_mirror_md.flow_hash = fabric_md.bridged.base.flow_hash;
    }
    table drop_report {
        key = {
            fabric_md.bridged.int_bmd.report_type: exact @name("int_report_type");
            fabric_md.int_mirror_md.drop_reason[7:7]: exact @name("with_drop_reason");
        }
        actions = {
            report_drop;
            @defaultonly nop;
        }
        const size = 1;
        const default_action = nop();
    }
    @hidden
    action set_mirror_session_id(MirrorId_t sid) {
        fabric_md.bridged.int_bmd.mirror_session_id = sid;
    }
    @hidden
    table mirror_session_id {
        key = {
            ig_intr_md.ingress_port: ternary;
        }
        actions = {
            set_mirror_session_id;
        }
        const size = 4;
        const entries = {
            9w0x000 &&& 0x180: set_mirror_session_id(REPORT_MIRROR_SESS_PIPE_0);
            9w0x080 &&& 0x180: set_mirror_session_id(REPORT_MIRROR_SESS_PIPE_1);
            9w0x100 &&& 0x180: set_mirror_session_id(REPORT_MIRROR_SESS_PIPE_2);
            9w0x180 &&& 0x180: set_mirror_session_id(REPORT_MIRROR_SESS_PIPE_3);
        }
    }
    apply {
        mirror_session_id.apply();
        if (hdr.ipv4.isValid()) {
            watchlist.apply();
            drop_report.apply();
        }
    }
}
control IntEgress (
    inout parsed_headers_t hdr,
    inout fabric_egress_metadata_t fabric_md,
    in egress_intrinsic_metadata_t eg_intr_md,
    in egress_intrinsic_metadata_from_parser_t eg_prsr_md,
    inout egress_intrinsic_metadata_for_deparser_t eg_dprsr_md) {
    FlowReportFilter() flow_report_filter;
    DropReportFilter() drop_report_filter;
    @hidden
    Random<bit<16>>() ip_id_gen;
    @hidden
    Register<bit<32>, bit<6>>(1024) seq_number;
    RegisterAction<bit<32>, bit<6>, bit<32>>(seq_number) get_seq_number = {
        void apply(inout bit<32> reg, out bit<32> rv) {
            reg = reg + 1;
            rv = reg;
        }
    };
    action set_config(bit<32> hop_latency_mask, bit<48> timestamp_mask) {
        fabric_md.int_md.hop_latency = fabric_md.int_md.hop_latency & hop_latency_mask;
        fabric_md.int_md.timestamp = fabric_md.int_md.timestamp & timestamp_mask;
    }
    table config {
        actions = {
            @defaultonly set_config;
        }
        default_action = set_config(DEFAULT_HOP_LATENCY_MASK, DEFAULT_TIMESTAMP_MASK);
        const size = 1;
    }
    @hidden
    action add_report_fixed_header(mac_addr_t src_mac, mac_addr_t mon_mac,
                                   ipv4_addr_t src_ip, ipv4_addr_t mon_ip,
                                   l4_port_t mon_port) {
        hdr.report_ethernet.setValid();
        hdr.report_ethernet.dst_addr = mon_mac;
        hdr.report_ethernet.src_addr = src_mac;
        hdr.report_eth_type.setValid();
        hdr.report_eth_type.value = ETHERTYPE_IPV4;
        hdr.report_ipv4.setValid();
        hdr.report_ipv4.version = 4w4;
        hdr.report_ipv4.ihl = 4w5;
        hdr.report_ipv4.dscp = INT_DSCP;
        hdr.report_ipv4.ecn = 2w0;
        hdr.report_ipv4.flags = 0;
        hdr.report_ipv4.frag_offset = 0;
        hdr.report_ipv4.ttl = DEFAULT_IPV4_TTL;
        hdr.report_ipv4.protocol = PROTO_UDP;
        hdr.report_ipv4.identification = ip_id_gen.get();
        hdr.report_ipv4.src_addr = src_ip;
        hdr.report_ipv4.dst_addr = mon_ip;
        hdr.report_udp.setValid();
        hdr.report_udp.dport = mon_port;
        hdr.report_fixed_header.setValid();
        hdr.report_fixed_header.ver = 0;
        hdr.report_fixed_header.rsvd = 0;
        hdr.report_fixed_header.seq_no = get_seq_number.execute(hdr.report_fixed_header.hw_id);
    }
    action do_local_report_encap(mac_addr_t src_mac, mac_addr_t mon_mac,
                                 ipv4_addr_t src_ip, ipv4_addr_t mon_ip,
                                 l4_port_t mon_port) {
        add_report_fixed_header(src_mac, mon_mac, src_ip, mon_ip, mon_port);
        hdr.report_fixed_header.nproto = NPROTO_TELEMETRY_SWITCH_LOCAL_HEADER;
        hdr.report_fixed_header.f = 1;
        hdr.drop_report_header.setInvalid();
        hdr.report_ipv4.total_len = 20 + 8
                            + REPORT_FIXED_HEADER_BYTES + LOCAL_REPORT_HEADER_BYTES
                            - REPORT_MIRROR_HEADER_BYTES
                            - ETH_FCS_LEN
                            + eg_intr_md.pkt_length;
        hdr.report_udp.len = 8 + REPORT_FIXED_HEADER_BYTES
                             + LOCAL_REPORT_HEADER_BYTES
                             - REPORT_MIRROR_HEADER_BYTES
                             - ETH_FCS_LEN
                             + eg_intr_md.pkt_length;
        hdr.eth_type.value = fabric_md.int_mirror_md.ip_eth_type;
        eg_dprsr_md.mirror_type = (bit<3>)FabricMirrorType_t.INVALID;
    }
    action do_local_report_encap_mpls(mac_addr_t src_mac, mac_addr_t mon_mac,
                                      ipv4_addr_t src_ip, ipv4_addr_t mon_ip,
                                      l4_port_t mon_port, mpls_label_t mon_label) {
        do_local_report_encap(src_mac, mon_mac, src_ip, mon_ip, mon_port);
        hdr.report_eth_type.value = ETHERTYPE_MPLS;
        hdr.report_mpls.setValid();
        hdr.report_mpls.label = mon_label;
        hdr.report_mpls.tc = 0;
        hdr.report_mpls.bos = 1;
        hdr.report_mpls.ttl = DEFAULT_MPLS_TTL;
    }
    action do_drop_report_encap(mac_addr_t src_mac, mac_addr_t mon_mac,
                                 ipv4_addr_t src_ip, ipv4_addr_t mon_ip,
                                 l4_port_t mon_port) {
        add_report_fixed_header(src_mac, mon_mac, src_ip, mon_ip, mon_port);
        hdr.report_fixed_header.nproto = NPROTO_TELEMETRY_DROP_HEADER;
        hdr.report_fixed_header.d = 1;
        hdr.local_report_header.setInvalid();
        hdr.report_ipv4.total_len = 20 + 8
                            + REPORT_FIXED_HEADER_BYTES + DROP_REPORT_HEADER_BYTES
                            - REPORT_MIRROR_HEADER_BYTES
                            - ETH_FCS_LEN
                            + eg_intr_md.pkt_length;
        hdr.report_udp.len = 8 + REPORT_FIXED_HEADER_BYTES
                             + DROP_REPORT_HEADER_BYTES
                             - REPORT_MIRROR_HEADER_BYTES
                             - ETH_FCS_LEN
                             + eg_intr_md.pkt_length;
        hdr.eth_type.value = fabric_md.int_mirror_md.ip_eth_type;
        eg_dprsr_md.mirror_type = (bit<3>)FabricMirrorType_t.INVALID;
    }
    action do_drop_report_encap_mpls(mac_addr_t src_mac, mac_addr_t mon_mac,
                                 ipv4_addr_t src_ip, ipv4_addr_t mon_ip,
                                 l4_port_t mon_port, mpls_label_t mon_label) {
        do_drop_report_encap(src_mac, mon_mac, src_ip, mon_ip, mon_port);
        hdr.report_eth_type.value = ETHERTYPE_MPLS;
        hdr.report_mpls.setValid();
        hdr.report_mpls.label = mon_label;
        hdr.report_mpls.tc = 0;
        hdr.report_mpls.bos = 1;
        hdr.report_mpls.ttl = DEFAULT_MPLS_TTL;
    }
    table report {
        key = {
            fabric_md.bridged.bmd_type: exact @name("bmd_type");
            fabric_md.int_mirror_md.mirror_type: exact @name("mirror_type");
            fabric_md.int_mirror_md.report_type: exact @name("int_report_type");
        }
        actions = {
            do_local_report_encap;
            do_local_report_encap_mpls;
            do_drop_report_encap;
            do_drop_report_encap_mpls;
            @defaultonly nop();
        }
        default_action = nop;
        const size = 6;
    }
    @hidden
    action set_hw_id(bit<6> hw_id) {
        hdr.report_fixed_header.hw_id = hw_id;
    }
    @hidden
    table hw_id {
        key = {
            eg_intr_md.egress_port: ternary;
        }
        actions = {
            set_hw_id;
        }
        const size = 4;
        const entries = {
            9w0x000 &&& 0x180: set_hw_id(0);
            9w0x080 &&& 0x180: set_hw_id(1);
            9w0x100 &&& 0x180: set_hw_id(2);
            9w0x180 &&& 0x180: set_hw_id(3);
        }
    }
    @hidden
    action set_report_metadata(bit<32> switch_id) {
        eg_dprsr_md.mirror_type = (bit<3>)FabricMirrorType_t.INT_REPORT;
        fabric_md.int_mirror_md.bmd_type = BridgedMdType_t.EGRESS_MIRROR;
        fabric_md.int_mirror_md.mirror_type = FabricMirrorType_t.INT_REPORT;
        fabric_md.int_mirror_md.report_type = fabric_md.bridged.int_bmd.report_type;
        fabric_md.int_mirror_md.switch_id = switch_id;
        fabric_md.int_mirror_md.ig_port = (bit<16>)fabric_md.bridged.base.ig_port;
        fabric_md.int_mirror_md.eg_port = (bit<16>)eg_intr_md.egress_port;
        fabric_md.int_mirror_md.queue_id = (bit<8>)eg_intr_md.egress_qid;
        fabric_md.int_mirror_md.queue_occupancy = (bit<24>)eg_intr_md.enq_qdepth;
        fabric_md.int_mirror_md.ig_tstamp = fabric_md.bridged.base.ig_tstamp[31:0];
        fabric_md.int_mirror_md.eg_tstamp = eg_prsr_md.global_tstamp[31:0];
        fabric_md.int_mirror_md.ip_eth_type = fabric_md.bridged.base.ip_eth_type;
        fabric_md.int_mirror_md.flow_hash = fabric_md.bridged.base.flow_hash;
    }
    action report_local(bit<32> switch_id) {
        set_report_metadata(switch_id);
        fabric_md.int_mirror_md.report_type = IntReportType_t.LOCAL;
    }
    action report_drop(bit<32> switch_id) {
        set_report_metadata(switch_id);
        fabric_md.int_mirror_md.report_type = IntReportType_t.DROP;
    }
    table int_metadata {
        key = {
            fabric_md.bridged.int_bmd.report_type: exact @name("int_report_type");
            fabric_md.int_mirror_md.drop_reason[7:7]: exact @name("with_drop_reason");
        }
        actions = {
            report_local;
            report_drop;
            @defaultonly nop();
        }
        const default_action = nop();
        const size = 3;
    }
    apply {
        fabric_md.int_md.hop_latency = eg_prsr_md.global_tstamp[31:0] - fabric_md.bridged.base.ig_tstamp[31:0];
        fabric_md.int_md.timestamp = eg_prsr_md.global_tstamp;
        config.apply();
        hw_id.apply();
        drop_report_filter.apply(hdr, fabric_md, eg_dprsr_md);
        if (report.apply().hit) {
            if (fabric_md.int_mirror_md.strip_gtpu == 1) {
                hdr.report_ipv4.total_len = hdr.report_ipv4.total_len
                    - (20 + 8 + 8);
                hdr.report_udp.len = hdr.report_udp.len
                    - (20 + 8 + 8);
            }
            if (fabric_md.mpls_stripped == 1) {
                hdr.report_ipv4.total_len = hdr.report_ipv4.total_len
                    - 4;
                hdr.report_udp.len = hdr.report_udp.len
                    - 4;
            }
        } else {
            if (int_metadata.apply().hit) {
                flow_report_filter.apply(hdr, fabric_md, eg_intr_md, eg_prsr_md, eg_dprsr_md);
            }
        }
    }
}
control FabricIngress (
    inout parsed_headers_t hdr,
    inout fabric_ingress_metadata_t fabric_md,
    in ingress_intrinsic_metadata_t ig_intr_md,
    in ingress_intrinsic_metadata_from_parser_t ig_prsr_md,
    inout ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md,
    inout ingress_intrinsic_metadata_for_tm_t ig_tm_md) {
    PacketIoIngress() pkt_io_ingress;
    Filtering() filtering;
    Forwarding() forwarding;
    Acl() acl;
    Next() next;
    Hasher() hasher;
    SpgwIngress() spgw;
    IntIngress() int_ingress;
    apply {
        pkt_io_ingress.apply(hdr, fabric_md, ig_intr_md, ig_tm_md, ig_dprsr_md);
        spgw.apply(hdr, fabric_md, ig_tm_md);
        filtering.apply(hdr, fabric_md, ig_intr_md);
        if (!fabric_md.skip_forwarding) {
            forwarding.apply(hdr, fabric_md);
        }
        hasher.apply(hdr, fabric_md);
        acl.apply(hdr, fabric_md, ig_intr_md, ig_dprsr_md, ig_tm_md);
        if (!fabric_md.skip_next) {
            next.apply(hdr, fabric_md, ig_intr_md, ig_tm_md);
        }
        int_ingress.apply(hdr, fabric_md, ig_intr_md, ig_dprsr_md, ig_tm_md);
    }
}
control FabricEgress (
    inout parsed_headers_t hdr,
    inout fabric_egress_metadata_t fabric_md,
    in egress_intrinsic_metadata_t eg_intr_md,
    in egress_intrinsic_metadata_from_parser_t eg_prsr_md,
    inout egress_intrinsic_metadata_for_deparser_t eg_dprsr_md,
    inout egress_intrinsic_metadata_for_output_port_t eg_oport_md) {
    PacketIoEgress() pkt_io_egress;
    EgressNextControl() egress_next;
    SpgwEgress() spgw;
    IntEgress() int_egress;
    apply {
        pkt_io_egress.apply(hdr, fabric_md, eg_intr_md);
        egress_next.apply(hdr, fabric_md, eg_intr_md, eg_dprsr_md);
        spgw.apply(hdr, fabric_md);
        int_egress.apply(hdr, fabric_md, eg_intr_md, eg_prsr_md, eg_dprsr_md);
    }
}
Pipeline(
    FabricIngressParser(),
    FabricIngress(),
    FabricIngressDeparser(),
    FabricEgressParser(),
    FabricEgress(),
    FabricEgressDeparser()
) pipe;
Switch(pipe) main;
