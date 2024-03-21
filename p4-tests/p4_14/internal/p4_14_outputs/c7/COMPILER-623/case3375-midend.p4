#include <core.p4>
#include <v1model.p4>

struct egress_metadata_t {
    bit<16> payload_length;
}

struct global_config_metadata_t {
    bit<128> our_ipv6_addr;
}

struct hash_metadata_t {
    bit<16> entropy_hash;
}

struct l3_metadata_t {
    bit<24> nexthop_index;
    bit<24> vrf;
}

struct tunnel_metadata_t {
    bit<5>  ingress_tunnel_type;
    bit<5>  egress_tunnel_type;
    bit<24> tunnel_vni;
    bit<24> tunnel_index;
    bit<16> dst_datacenter_index;
    bit<16> dst_tor_index;
    bit<16> dst_server_index;
    bit<1>  tunnel_terminate;
    bit<1>  tunnel_lookup;
    bit<4>  egress_header_count;
    bit<14> tunnel_smac_index;
    bit<14> tunnel_dmac_index;
    bit<1>  tunnel_if_check;
    bit<8>  inner_ip_proto;
}

header egress_intrinsic_metadata_t {
    bit<7>  _pad0;
    bit<9>  egress_port;
    bit<5>  _pad1;
    bit<19> enq_qdepth;
    bit<6>  _pad2;
    bit<2>  enq_congest_stat;
    bit<32> enq_tstamp;
    bit<5>  _pad3;
    bit<19> deq_qdepth;
    bit<6>  _pad4;
    bit<2>  deq_congest_stat;
    bit<8>  app_pool_congest_stat;
    bit<32> deq_timedelta;
    bit<16> egress_rid;
    bit<7>  _pad5;
    bit<1>  egress_rid_first;
    bit<3>  _pad6;
    bit<5>  egress_qid;
    bit<5>  _pad7;
    bit<3>  egress_cos;
    bit<7>  _pad8;
    bit<1>  deflection_flag;
    bit<16> pkt_length;
}

header egress_intrinsic_metadata_for_mirror_buffer_t {
    bit<6>  _pad1;
    bit<10> egress_mirror_id;
    bit<1>  coalesce_flush;
    bit<7>  coalesce_length;
}

header egress_intrinsic_metadata_for_output_port_t {
    bit<2> _pad1;
    bit<1> capture_tstamp_on_tx;
    bit<1> update_delay_on_tx;
    bit<1> force_tx_error;
    bit<3> drop_ctl;
}

header egress_intrinsic_metadata_from_parser_aux_t {
    bit<48> egress_global_tstamp;
    bit<32> egress_global_ver;
    bit<16> egress_parser_err;
    bit<4>  clone_digest_id;
    bit<4>  clone_src;
    bit<8>  coalesce_sample_count;
}

header ethernet_t {
    bit<48> dstAddr;
    bit<48> srcAddr;
    bit<16> etherType;
}

header icmp_t {
    bit<16> typeCode;
    bit<16> hdrChecksum;
}

header ingress_intrinsic_metadata_t {
    bit<1>  resubmit_flag;
    bit<1>  _pad1;
    bit<2>  _pad2;
    bit<3>  _pad3;
    bit<9>  ingress_port;
    bit<48> ingress_mac_tstamp;
}

header ingress_intrinsic_metadata_for_mirror_buffer_t {
    bit<6>  _pad1;
    bit<10> ingress_mirror_id;
}

header ingress_intrinsic_metadata_for_tm_t {
    bit<7>  _pad1;
    bit<9>  ucast_egress_port;
    bit<3>  drop_ctl;
    bit<1>  bypass_egress;
    bit<1>  deflect_on_drop;
    bit<3>  ingress_cos;
    bit<5>  qid;
    bit<3>  icos_for_copy_to_cpu;
    bit<3>  _pad2;
    bit<1>  copy_to_cpu;
    bit<2>  packet_color;
    bit<1>  disable_ucast_cutthru;
    bit<1>  enable_mcast_cutthru;
    bit<16> mcast_grp_a;
    bit<16> mcast_grp_b;
    bit<3>  _pad3;
    bit<13> level1_mcast_hash;
    bit<3>  _pad4;
    bit<13> level2_mcast_hash;
    bit<16> level1_exclusion_id;
    bit<7>  _pad5;
    bit<9>  level2_exclusion_id;
    bit<16> rid;
}

header ingress_intrinsic_metadata_from_parser_aux_t {
    bit<48> ingress_global_tstamp;
    bit<32> ingress_global_ver;
    bit<16> ingress_parser_err;
}

@name("generator_metadata_t") header generator_metadata_t_0 {
    bit<16> app_id;
    bit<16> batch_id;
    bit<16> instance_id;
}

header ingress_parser_control_signals {
    bit<3> priority;
    bit<5> _pad1;
    bit<8> parser_counter;
}

header ipv4_t {
    bit<4>  version;
    bit<4>  ihl;
    bit<8>  diffserv;
    bit<16> totalLen;
    bit<16> identification;
    bit<3>  flags;
    bit<13> fragOffset;
    bit<8>  ttl;
    bit<8>  protocol;
    bit<16> hdrChecksum;
    bit<32> srcAddr;
    bit<32> dstAddr;
}

header ipv6_t {
    bit<4>   version;
    bit<8>   trafficClass;
    bit<20>  flowLabel;
    bit<16>  payloadLen;
    bit<8>   nextHdr;
    bit<8>   hopLimit;
    bit<128> srcAddr;
    bit<32>  dstAddr_first32;
    bit<32>  dstAddr_second32;
    bit<32>  dstAddr_zeroes;
    bit<32>  dstAddr_server;
}

header tcp_t {
    bit<16> srcPort;
    bit<16> dstPort;
    bit<32> seqNo;
    bit<32> ackNo;
    bit<4>  dataOffset;
    bit<4>  res;
    bit<8>  flags;
    bit<16> window;
    bit<16> checksum;
    bit<16> urgentPtr;
}

header udp_t {
    bit<16> srcPort;
    bit<16> dstPort;
    bit<16> length_;
    bit<16> checksum;
}

header vxlan_t {
    bit<8>  flags;
    bit<24> reserved;
    bit<24> vni;
    bit<8>  reserved2;
}

struct metadata {
    @pa_no_init("ingress", "egress_metadata.payload_length") @pa_no_init("egress", "egress_metadata.payload_length") @name(".egress_metadata") 
    egress_metadata_t        egress_metadata;
    @name(".global_config_metadata") 
    global_config_metadata_t global_config_metadata;
    @name(".hash_metadata") 
    hash_metadata_t          hash_metadata;
    @name(".l3_metadata") 
    l3_metadata_t            l3_metadata;
    @name(".tunnel_metadata") 
    tunnel_metadata_t        tunnel_metadata;
}

struct headers {
    @dont_trim @not_deparsed("ingress") @not_deparsed("egress") @pa_intrinsic_header("egress", "eg_intr_md") @pa_atomic("egress", "eg_intr_md.egress_port") @pa_fragment("egress", "eg_intr_md._pad1") @pa_fragment("egress", "eg_intr_md._pad7") @pa_fragment("egress", "eg_intr_md._pad8") @pa_mandatory_intrinsic_field("egress", "eg_intr_md.egress_port") @pa_mandatory_intrinsic_field("egress", "eg_intr_md.egress_cos") @name(".eg_intr_md") 
    egress_intrinsic_metadata_t                    eg_intr_md;
    @dont_trim @pa_intrinsic_header("egress", "eg_intr_md_for_mb") @pa_atomic("egress", "eg_intr_md_for_mb.egress_mirror_id") @pa_fragment("egress", "eg_intr_md_for_mb.coalesce_flush") @pa_mandatory_intrinsic_field("egress", "eg_intr_md_for_mb.egress_mirror_id") @pa_mandatory_intrinsic_field("egress", "eg_intr_md_for_mb.coalesce_flush") @pa_mandatory_intrinsic_field("egress", "eg_intr_md_for_mb.coalesce_length") @not_deparsed("ingress") @not_deparsed("egress") @name(".eg_intr_md_for_mb") 
    egress_intrinsic_metadata_for_mirror_buffer_t  eg_intr_md_for_mb;
    @dont_trim @pa_mandatory_intrinsic_field("egress", "eg_intr_md_for_oport.drop_ctl") @not_deparsed("ingress") @not_deparsed("egress") @pa_intrinsic_header("egress", "eg_intr_md_for_oport") @name(".eg_intr_md_for_oport") 
    egress_intrinsic_metadata_for_output_port_t    eg_intr_md_for_oport;
    @pa_fragment("egress", "eg_intr_md_from_parser_aux.coalesce_sample_count") @pa_fragment("egress", "eg_intr_md_from_parser_aux.clone_src") @pa_fragment("egress", "eg_intr_md_from_parser_aux.egress_parser_err") @pa_atomic("egress", "eg_intr_md_from_parser_aux.egress_parser_err") @not_deparsed("ingress") @not_deparsed("egress") @pa_intrinsic_header("egress", "eg_intr_md_from_parser_aux") @name(".eg_intr_md_from_parser_aux") 
    egress_intrinsic_metadata_from_parser_aux_t    eg_intr_md_from_parser_aux;
    @name(".ethernet") 
    ethernet_t                                     ethernet;
    @name(".icmp") 
    icmp_t                                         icmp;
    @dont_trim @not_deparsed("ingress") @not_deparsed("egress") @pa_intrinsic_header("ingress", "ig_intr_md") @pa_mandatory_intrinsic_field("ingress", "ig_intr_md.ingress_port") @name(".ig_intr_md") 
    ingress_intrinsic_metadata_t                   ig_intr_md;
    @dont_trim @pa_intrinsic_header("ingress", "ig_intr_md_for_mb") @pa_atomic("ingress", "ig_intr_md_for_mb.ingress_mirror_id") @pa_mandatory_intrinsic_field("ingress", "ig_intr_md_for_mb.ingress_mirror_id") @not_deparsed("ingress") @not_deparsed("egress") @name(".ig_intr_md_for_mb") 
    ingress_intrinsic_metadata_for_mirror_buffer_t ig_intr_md_for_mb;
    @pa_atomic("ingress", "ig_intr_md_for_tm.ucast_egress_port") @pa_fragment("ingress", "ig_intr_md_for_tm.drop_ctl") @pa_fragment("ingress", "ig_intr_md_for_tm.qid") @pa_fragment("ingress", "ig_intr_md_for_tm._pad2") @pa_atomic("ingress", "ig_intr_md_for_tm.mcast_grp_a") @pa_fragment("ingress", "ig_intr_md_for_tm.mcast_grp_a") @pa_mandatory_intrinsic_field("ingress", "ig_intr_md_for_tm.mcast_grp_a") @pa_atomic("ingress", "ig_intr_md_for_tm.mcast_grp_b") @pa_fragment("ingress", "ig_intr_md_for_tm.mcast_grp_b") @pa_mandatory_intrinsic_field("ingress", "ig_intr_md_for_tm.mcast_grp_b") @pa_atomic("ingress", "ig_intr_md_for_tm.level1_mcast_hash") @pa_fragment("ingress", "ig_intr_md_for_tm._pad3") @pa_atomic("ingress", "ig_intr_md_for_tm.level2_mcast_hash") @pa_fragment("ingress", "ig_intr_md_for_tm._pad4") @pa_atomic("ingress", "ig_intr_md_for_tm.level1_exclusion_id") @pa_fragment("ingress", "ig_intr_md_for_tm.level1_exclusion_id") @pa_atomic("ingress", "ig_intr_md_for_tm.level2_exclusion_id") @pa_fragment("ingress", "ig_intr_md_for_tm._pad5") @pa_atomic("ingress", "ig_intr_md_for_tm.rid") @pa_fragment("ingress", "ig_intr_md_for_tm.rid") @not_deparsed("ingress") @not_deparsed("egress") @pa_intrinsic_header("ingress", "ig_intr_md_for_tm") @dont_trim @pa_mandatory_intrinsic_field("ingress", "ig_intr_md_for_tm.drop_ctl") @name(".ig_intr_md_for_tm") 
    ingress_intrinsic_metadata_for_tm_t            ig_intr_md_for_tm;
    @pa_fragment("ingress", "ig_intr_md_from_parser_aux.ingress_parser_err") @pa_atomic("ingress", "ig_intr_md_from_parser_aux.ingress_parser_err") @not_deparsed("ingress") @not_deparsed("egress") @pa_intrinsic_header("ingress", "ig_intr_md_from_parser_aux") @name(".ig_intr_md_from_parser_aux") 
    ingress_intrinsic_metadata_from_parser_aux_t   ig_intr_md_from_parser_aux;
    @not_deparsed("ingress") @not_deparsed("egress") @name(".ig_pg_md") 
    generator_metadata_t_0                         ig_pg_md;
    @not_deparsed("ingress") @not_deparsed("egress") @pa_intrinsic_header("ingress", "ig_prsr_ctrl") @name(".ig_prsr_ctrl") 
    ingress_parser_control_signals                 ig_prsr_ctrl;
    @name(".inner_ethernet") 
    ethernet_t                                     inner_ethernet;
    @name(".inner_icmp") 
    icmp_t                                         inner_icmp;
    @name(".inner_ipv4") 
    ipv4_t                                         inner_ipv4;
    @name(".inner_ipv6") 
    ipv6_t                                         inner_ipv6;
    @name(".inner_tcp") 
    tcp_t                                          inner_tcp;
    @name(".inner_udp") 
    udp_t                                          inner_udp;
    @name(".ipv4") 
    ipv4_t                                         ipv4;
    @name(".ipv6") 
    ipv6_t                                         ipv6;
    @name(".tcp") 
    tcp_t                                          tcp;
    @name(".udp") 
    udp_t                                          udp;
    @name(".vxlan") 
    vxlan_t                                        vxlan;
}

parser ParserImpl(packet_in packet, out headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".parse_ethernet") state parse_ethernet {
        packet.extract<ethernet_t>(hdr.ethernet);
        transition select(hdr.ethernet.etherType) {
            16w0x800: parse_ipv4;
            16w0x86dd: parse_ipv6;
            default: accept;
        }
    }
    @name(".parse_icmp") state parse_icmp {
        packet.extract<icmp_t>(hdr.icmp);
        transition accept;
    }
    @name(".parse_inner_ethernet") state parse_inner_ethernet {
        packet.extract<ethernet_t>(hdr.inner_ethernet);
        transition select(hdr.inner_ethernet.etherType) {
            16w0x800: parse_inner_ipv4;
            default: accept;
        }
    }
    @name(".parse_inner_icmp") state parse_inner_icmp {
        packet.extract<icmp_t>(hdr.inner_icmp);
        transition accept;
    }
    @name(".parse_inner_ipv4") state parse_inner_ipv4 {
        packet.extract<ipv4_t>(hdr.inner_ipv4);
        transition select(hdr.inner_ipv4.protocol) {
            8w1: parse_inner_icmp;
            8w6: parse_inner_tcp;
            8w17: parse_inner_udp;
            default: accept;
        }
    }
    @name(".parse_inner_tcp") state parse_inner_tcp {
        packet.extract<tcp_t>(hdr.inner_tcp);
        transition accept;
    }
    @name(".parse_inner_udp") state parse_inner_udp {
        packet.extract<udp_t>(hdr.inner_udp);
        transition accept;
    }
    @name(".parse_ipv4") state parse_ipv4 {
        packet.extract<ipv4_t>(hdr.ipv4);
        transition select(hdr.ipv4.protocol) {
            8w1: parse_icmp;
            8w6: parse_tcp;
            8w17: parse_udp;
            default: accept;
        }
    }
    @name(".parse_ipv6") state parse_ipv6 {
        packet.extract<ipv6_t>(hdr.ipv6);
        transition select(hdr.ipv6.nextHdr) {
            8w17: parse_udp;
            default: accept;
        }
    }
    @name(".parse_tcp") state parse_tcp {
        packet.extract<tcp_t>(hdr.tcp);
        transition accept;
    }
    @name(".parse_udp") state parse_udp {
        packet.extract<udp_t>(hdr.udp);
        transition select(hdr.udp.dstPort) {
            16w4789: parse_vxlan;
            default: accept;
        }
    }
    @name(".parse_vxlan") state parse_vxlan {
        packet.extract<vxlan_t>(hdr.vxlan);
        transition parse_inner_ethernet;
    }
    @name(".start") state start {
        transition parse_ethernet;
    }
}

control egress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".NoAction") action NoAction_0() {
    }
    @name(".NoAction") action NoAction_1() {
    }
    @name(".NoAction") action NoAction_16() {
    }
    @name(".NoAction") action NoAction_17() {
    }
    @name(".NoAction") action NoAction_18() {
    }
    @name(".NoAction") action NoAction_19() {
    }
    @name(".NoAction") action NoAction_20() {
    }
    @name(".encap_udp") action _encap_udp_0() {
        hdr.inner_udp = hdr.udp;
        hdr.udp.setInvalid();
    }
    @name(".encap_tcp") action _encap_tcp_0() {
        hdr.inner_tcp = hdr.tcp;
        hdr.tcp.setInvalid();
    }
    @name(".encap_icmp") action _encap_icmp_0() {
        hdr.inner_icmp = hdr.icmp;
        hdr.icmp.setInvalid();
    }
    @name(".encap_process_inner_common") action _encap_process_inner_common_0() {
        meta.egress_metadata.payload_length = hdr.ipv4.totalLen + 16w30;
        hdr.inner_ethernet = hdr.ethernet;
        hdr.inner_ipv4 = hdr.ipv4;
        hdr.ipv4.setInvalid();
        hdr.vxlan.setValid();
        hdr.vxlan.flags = 8w0x8;
        hdr.vxlan.reserved = 24w0;
        hdr.vxlan.vni = meta.tunnel_metadata.tunnel_vni;
        hdr.vxlan.reserved2 = 8w0;
        hdr.udp.setValid();
        hdr.udp.srcPort = meta.hash_metadata.entropy_hash;
        hdr.udp.dstPort = 16w4789;
        hdr.udp.checksum = 16w0x0;
        hdr.udp.length_ = hdr.ipv4.totalLen + 16w30;
    }
    @name(".insert_ipv6_header") action _insert_ipv6_header_0() {
        hdr.ethernet.etherType = 16w0x86dd;
        hdr.ipv6.setValid();
        hdr.ipv6.version = 4w0x6;
        hdr.ipv6.payloadLen = meta.egress_metadata.payload_length;
        hdr.ipv6.nextHdr = 8w17;
        hdr.ipv6.hopLimit = 8w64;
        hdr.ipv6.dstAddr_zeroes = 32w0x0;
        hdr.ipv6.srcAddr = 128w0x1aa12aa23aa34aa45aa56aa67aa78aa8;
    }
    @name(".encap_write_outer") action _encap_write_outer_0(bit<16> dst_datacenter_index, bit<16> dst_tor_index, bit<16> dst_server_index, bit<24> vni) {
        meta.tunnel_metadata.dst_datacenter_index = dst_datacenter_index;
        meta.tunnel_metadata.dst_tor_index = dst_tor_index;
        meta.tunnel_metadata.dst_server_index = dst_server_index;
        meta.tunnel_metadata.tunnel_vni = vni;
    }
    @name(".set_dst_datacenter") action _set_dst_datacenter_0(bit<32> dst_datacenter_id_32, bit<32> dst_datacenter_id_4) {
        hdr.ipv6.dstAddr_first32 = dst_datacenter_id_32;
        hdr.ipv6.dstAddr_second32 = dst_datacenter_id_4;
    }
    @name(".set_dst_server") action _set_dst_server_0(bit<32> dst_server_ip) {
        hdr.ipv6.dstAddr_server = dst_server_ip;
        hdr.ipv6.dstAddr_second32 = hdr.ipv6.dstAddr_second32 << 28;
    }
    @name(".set_dst_tor") action _set_dst_tor_0(bit<32> dst_tor_id) {
        hdr.ipv6.dstAddr_second32 = hdr.ipv6.dstAddr_second32 + dst_tor_id;
    }
    @name(".encap_inner") table _encap_inner {
        actions = {
            _encap_udp_0();
            _encap_tcp_0();
            _encap_icmp_0();
            @defaultonly NoAction_0();
        }
        key = {
            hdr.udp.isValid() : exact @name("udp.$valid$") ;
            hdr.tcp.isValid() : exact @name("tcp.$valid$") ;
            hdr.icmp.isValid(): exact @name("icmp.$valid$") ;
        }
        size = 3;
        default_action = NoAction_0();
    }
    @name(".encap_inner2") table _encap_inner2 {
        actions = {
            _encap_process_inner_common_0();
            @defaultonly NoAction_1();
        }
        size = 1;
        default_action = NoAction_1();
    }
    @name(".encap_inner3") table _encap_inner3 {
        actions = {
            _insert_ipv6_header_0();
            @defaultonly NoAction_16();
        }
        size = 1;
        default_action = NoAction_16();
    }
    @name(".encap_write_outer") table _encap_write_outer_1 {
        actions = {
            _encap_write_outer_0();
            @defaultonly NoAction_17();
        }
        key = {
            meta.tunnel_metadata.tunnel_index: exact @name("tunnel_metadata.tunnel_index") ;
        }
        size = 1024;
        default_action = NoAction_17();
    }
    @ternary(1) @name(".tunnel_dst_datacenter_rewrite") table _tunnel_dst_datacenter_rewrite {
        actions = {
            _set_dst_datacenter_0();
            @defaultonly NoAction_18();
        }
        key = {
            meta.tunnel_metadata.dst_datacenter_index: exact @name("tunnel_metadata.dst_datacenter_index") ;
        }
        size = 256;
        default_action = NoAction_18();
    }
    @ternary(1) @name(".tunnel_dst_server_rewrite") table _tunnel_dst_server_rewrite {
        actions = {
            _set_dst_server_0();
            @defaultonly NoAction_19();
        }
        key = {
            meta.tunnel_metadata.dst_server_index: exact @name("tunnel_metadata.dst_server_index") ;
        }
        size = 2048;
        default_action = NoAction_19();
    }
    @ternary(1) @name(".tunnel_dst_tor_rewrite") table _tunnel_dst_tor_rewrite {
        actions = {
            _set_dst_tor_0();
            @defaultonly NoAction_20();
        }
        key = {
            meta.tunnel_metadata.dst_tor_index: exact @name("tunnel_metadata.dst_tor_index") ;
        }
        size = 2048;
        default_action = NoAction_20();
    }
    apply {
        if (meta.tunnel_metadata.tunnel_index != 24w0) {
            _encap_inner.apply();
            _encap_inner2.apply();
            _encap_inner3.apply();
            _encap_write_outer_1.apply();
            _tunnel_dst_datacenter_rewrite.apply();
            _tunnel_dst_server_rewrite.apply();
            _tunnel_dst_tor_rewrite.apply();
        }
    }
}

control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".NoAction") action NoAction_21() {
    }
    @name(".NoAction") action NoAction_22() {
    }
    @name(".NoAction") action NoAction_23() {
    }
    @name(".NoAction") action NoAction_24() {
    }
    @name(".NoAction") action NoAction_25() {
    }
    @name(".NoAction") action NoAction_26() {
    }
    @name(".NoAction") action NoAction_27() {
    }
    @name(".assign_vrf") action assign_vrf_0(bit<24> vrf) {
        meta.l3_metadata.vrf = vrf;
    }
    @name(".set_dmac") action set_dmac_0(bit<48> dmac, bit<9> port) {
        hdr.ethernet.dstAddr = dmac;
        hdr.ig_intr_md_for_tm.ucast_egress_port = port;
    }
    @name("._drop") action _drop_0() {
        mark_to_drop();
    }
    @name("._drop") action _drop_2() {
        mark_to_drop();
    }
    @name(".set_nhop_index") action set_nhop_index_0(bit<24> nexthop_index) {
        meta.l3_metadata.nexthop_index = nexthop_index;
    }
    @name(".set_nhop_index_with_tunnel") action set_nhop_index_with_tunnel_0(bit<24> nexthop_index, bit<24> tunnel_index) {
        meta.l3_metadata.nexthop_index = nexthop_index;
        meta.tunnel_metadata.tunnel_index = tunnel_index;
    }
    @name(".assign_vrf") table assign_vrf_1 {
        actions = {
            assign_vrf_0();
            @defaultonly NoAction_21();
        }
        key = {
            hdr.ig_intr_md.ingress_port: exact @name("ig_intr_md.ingress_port") ;
        }
        size = 1024;
        default_action = NoAction_21();
    }
    @name(".forward") table forward {
        actions = {
            set_dmac_0();
            _drop_0();
            @defaultonly NoAction_22();
        }
        key = {
            meta.l3_metadata.nexthop_index: exact @name("l3_metadata.nexthop_index") ;
        }
        size = 512;
        default_action = NoAction_22();
    }
    @name(".nhop_lookup") table nhop_lookup {
        actions = {
            set_nhop_index_0();
            set_nhop_index_with_tunnel_0();
            _drop_2();
            @defaultonly NoAction_23();
        }
        key = {
            hdr.ipv4.dstAddr    : lpm @name("ipv4.dstAddr") ;
            meta.l3_metadata.vrf: exact @name("l3_metadata.vrf") ;
        }
        size = 1024;
        default_action = NoAction_23();
    }
    @name(".decap_udp") action _decap_udp() {
        hdr.udp = hdr.inner_udp;
        hdr.inner_udp.setInvalid();
    }
    @name(".decap_tcp") action _decap_tcp() {
        hdr.udp.setInvalid();
        hdr.tcp = hdr.inner_tcp;
        hdr.inner_tcp.setInvalid();
    }
    @name(".decap_icmp") action _decap_icmp() {
        hdr.udp.setInvalid();
        hdr.icmp = hdr.inner_icmp;
        hdr.inner_icmp.setInvalid();
    }
    @name(".decap_unparsed_l4") action _decap_unparsed_l4() {
        hdr.udp.setInvalid();
    }
    @name(".decap_common") action _decap_common() {
        hdr.ethernet = hdr.inner_ethernet;
        hdr.inner_ethernet.setInvalid();
        hdr.ipv4 = hdr.inner_ipv4;
        hdr.inner_ipv4.setInvalid();
        hdr.vxlan.setInvalid();
        hdr.ipv6.setInvalid();
    }
    @name(".tunnel_check_passed") action _tunnel_check_passed() {
    }
    @name(".on_miss") action _on_miss() {
    }
    @name(".set_vrf") action _set_vrf(bit<24> vrf) {
        meta.l3_metadata.vrf = vrf;
    }
    @name(".decap_inner") table _decap_inner_0 {
        actions = {
            _decap_udp();
            _decap_tcp();
            _decap_icmp();
            _decap_unparsed_l4();
            @defaultonly NoAction_24();
        }
        key = {
            hdr.udp.isValid() : exact @name("udp.$valid$") ;
            hdr.tcp.isValid() : exact @name("tcp.$valid$") ;
            hdr.icmp.isValid(): exact @name("icmp.$valid$") ;
        }
        size = 4;
        default_action = NoAction_24();
    }
    @name(".decap_outer") table _decap_outer_0 {
        actions = {
            _decap_common();
            @defaultonly NoAction_25();
        }
        size = 1;
        default_action = NoAction_25();
    }
    @name(".tunnel_check") table _tunnel_check_0 {
        actions = {
            _tunnel_check_passed();
            _on_miss();
            @defaultonly NoAction_26();
        }
        key = {
            hdr.vxlan.isValid()      : exact @name("vxlan.$valid$") ;
            hdr.ipv6.dstAddr_first32 : exact @name("ipv6.dstAddr_first32") ;
            hdr.ipv6.dstAddr_second32: exact @name("ipv6.dstAddr_second32") ;
        }
        size = 2;
        default_action = NoAction_26();
    }
    @name(".vni_to_vrf") table _vni_to_vrf_0 {
        actions = {
            _set_vrf();
            @defaultonly NoAction_27();
        }
        key = {
            hdr.vxlan.vni: exact @name("vxlan.vni") ;
        }
        size = 1024;
        default_action = NoAction_27();
    }
    apply {
        if (hdr.ipv4.isValid()) 
            assign_vrf_1.apply();
        else 
            if (hdr.vxlan.isValid()) 
                switch (_tunnel_check_0.apply().action_run) {
                    _tunnel_check_passed: {
                        _vni_to_vrf_0.apply();
                        _decap_inner_0.apply();
                        _decap_outer_0.apply();
                    }
                }

        nhop_lookup.apply();
        forward.apply();
    }
}

control DeparserImpl(packet_out packet, in headers hdr) {
    apply {
        packet.emit<ethernet_t>(hdr.ethernet);
        packet.emit<ipv6_t>(hdr.ipv6);
        packet.emit<ipv4_t>(hdr.ipv4);
        packet.emit<udp_t>(hdr.udp);
        packet.emit<vxlan_t>(hdr.vxlan);
        packet.emit<ethernet_t>(hdr.inner_ethernet);
        packet.emit<ipv4_t>(hdr.inner_ipv4);
        packet.emit<udp_t>(hdr.inner_udp);
        packet.emit<tcp_t>(hdr.inner_tcp);
        packet.emit<icmp_t>(hdr.inner_icmp);
        packet.emit<tcp_t>(hdr.tcp);
        packet.emit<icmp_t>(hdr.icmp);
    }
}

control verifyChecksum(inout headers hdr, inout metadata meta) {
    apply {
    }
}

control computeChecksum(inout headers hdr, inout metadata meta) {
    apply {
    }
}

V1Switch<headers, metadata>(ParserImpl(), verifyChecksum(), ingress(), egress(), computeChecksum(), DeparserImpl()) main;

