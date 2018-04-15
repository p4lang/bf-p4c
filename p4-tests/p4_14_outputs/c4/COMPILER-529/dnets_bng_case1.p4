#include <core.p4>
#include <v1model.p4>

struct ingress_md_t {
    bit<2>  usds;
    bit<1>  cp;
    bit<32> line_id;
    bit<8>  subsc_id;
    bit<2>  meter_result;
}

header cpu_header_t {
    bit<8> device;
    bit<8> reason;
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
    bit<128> dstAddr;
}

header ipv6_t_ds {
    bit<4>   version;
    bit<8>   trafficClass;
    bit<20>  flowLabel;
    bit<16>  payloadLen;
    bit<8>   nextHdr;
    bit<8>   hopLimit;
    bit<128> srcAddr;
    bit<56>  dstAddr_net;
    bit<8>   dstAddr_netrest;
}

@name("ipv6_t_us") header ipv6_t_us_0 {
    bit<4>   version;
    bit<8>   trafficClass;
    bit<20>  flowLabel;
    bit<16>  payloadLen;
    bit<8>   nextHdr;
    bit<8>   hopLimit;
    bit<56>  srcAddr_net;
    bit<8>   srcAddr_netrest;
    bit<128> dstAddr;
}

header mpls_t {
    bit<20> label;
    bit<3>  tc;
    bit<1>  s;
    bit<8>  ttl;
}

header pktgen_generic_header_t {
    bit<3>  _pad0;
    bit<2>  pipe_id;
    bit<3>  app_id;
    bit<8>  key_msb;
    bit<16> batch_id;
    bit<16> packet_id;
}

header pktgen_port_down_header_t {
    bit<3>  _pad0;
    bit<2>  pipe_id;
    bit<3>  app_id;
    bit<15> _pad1;
    bit<9>  port_num;
    bit<16> packet_id;
}

header pktgen_recirc_header_t {
    bit<3>  _pad0;
    bit<2>  pipe_id;
    bit<3>  app_id;
    bit<24> key;
    bit<16> packet_id;
}

header pktgen_timer_header_t {
    bit<3>  _pad0;
    bit<2>  pipe_id;
    bit<3>  app_id;
    bit<8>  _pad1;
    bit<16> batch_id;
    bit<16> packet_id;
}

header pppoe_t {
    bit<4>  version;
    bit<4>  typeID;
    bit<8>  code;
    bit<16> sessionID;
    bit<16> totalLength;
    bit<16> protocol;
}

header vlan_t {
    bit<16> vlanID;
    bit<16> etherType;
}

struct metadata {
    @name(".ingress_md") 
    ingress_md_t ingress_md;
}

struct headers {
    @name(".cpu_header") 
    cpu_header_t                                   cpu_header;
    @dont_trim @not_deparsed("ingress") @not_deparsed("egress") @pa_intrinsic_header("egress", "eg_intr_md") @pa_atomic("egress", "eg_intr_md.egress_port") @pa_fragment("egress", "eg_intr_md._pad1") @pa_fragment("egress", "eg_intr_md._pad7") @pa_fragment("egress", "eg_intr_md._pad8") @pa_mandatory_intrinsic_field("egress", "eg_intr_md.egress_port") @pa_mandatory_intrinsic_field("egress", "eg_intr_md.egress_cos") @name(".eg_intr_md") 
    egress_intrinsic_metadata_t                    eg_intr_md;
    @dont_trim @pa_intrinsic_header("egress", "eg_intr_md_for_mb") @pa_atomic("egress", "eg_intr_md_for_mb.egress_mirror_id") @pa_fragment("egress", "eg_intr_md_for_mb.coalesce_flush") @pa_mandatory_intrinsic_field("egress", "eg_intr_md_for_mb.egress_mirror_id") @pa_mandatory_intrinsic_field("egress", "eg_intr_md_for_mb.coalesce_flush") @pa_mandatory_intrinsic_field("egress", "eg_intr_md_for_mb.coalesce_length") @not_deparsed("ingress") @not_deparsed("egress") @name(".eg_intr_md_for_mb") 
    egress_intrinsic_metadata_for_mirror_buffer_t  eg_intr_md_for_mb;
    @dont_trim @pa_mandatory_intrinsic_field("egress", "eg_intr_md_for_oport.drop_ctl") @not_deparsed("ingress") @not_deparsed("egress") @pa_intrinsic_header("egress", "eg_intr_md_for_oport") @name(".eg_intr_md_for_oport") 
    egress_intrinsic_metadata_for_output_port_t    eg_intr_md_for_oport;
    @pa_fragment("egress", "eg_intr_md_from_parser_aux.coalesce_sample_count") @pa_fragment("egress", "eg_intr_md_from_parser_aux.clone_src") @pa_fragment("egress", "eg_intr_md_from_parser_aux.egress_parser_err") @pa_atomic("egress", "eg_intr_md_from_parser_aux.egress_parser_err") @not_deparsed("ingress") @not_deparsed("egress") @pa_intrinsic_header("egress", "eg_intr_md_from_parser_aux") @name(".eg_intr_md_from_parser_aux") 
    egress_intrinsic_metadata_from_parser_aux_t    eg_intr_md_from_parser_aux;
    @name(".ethernet_inner") 
    ethernet_t                                     ethernet_inner;
    @name(".ethernet_outer") 
    ethernet_t                                     ethernet_outer;
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
    @name(".ipv4") 
    ipv4_t                                         ipv4;
    @name(".ipv6") 
    ipv6_t                                         ipv6;
    @name(".ipv6_ds") 
    ipv6_t_ds                                      ipv6_ds;
    @name(".ipv6_us") 
    ipv6_t_us_0                                    ipv6_us;
    @name(".mpls0") 
    mpls_t                                         mpls0;
    @name(".mpls1") 
    mpls_t                                         mpls1;
    @name(".pktgen_generic") 
    pktgen_generic_header_t                        pktgen_generic;
    @name(".pktgen_port_down") 
    pktgen_port_down_header_t                      pktgen_port_down;
    @name(".pktgen_recirc") 
    pktgen_recirc_header_t                         pktgen_recirc;
    @name(".pktgen_timer") 
    pktgen_timer_header_t                          pktgen_timer;
    @name(".pppoe") 
    pppoe_t                                        pppoe;
    @name(".vlan_service") 
    vlan_t                                         vlan_service;
    @name(".vlan_subsc") 
    vlan_t                                         vlan_subsc;
}
#include <tofino/stateful_alu.p4>

parser ParserImpl(packet_in packet, out headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".parse_cpu_header") state parse_cpu_header {
        packet.extract(hdr.cpu_header);
        transition parse_ethernet_outer;
    }
    @name(".parse_ethernet_inner") state parse_ethernet_inner {
        packet.extract(hdr.ethernet_inner);
        transition select(hdr.ethernet_inner.etherType) {
            16w0x8100: parse_vlan_subsc;
            default: accept;
        }
    }
    @name(".parse_ethernet_outer") state parse_ethernet_outer {
        packet.extract(hdr.ethernet_outer);
        transition select(hdr.ethernet_outer.etherType) {
            16w0x8847: parse_mpls0;
            default: accept;
        }
    }
    @name(".parse_ip") state parse_ip {
        transition select((packet.lookahead<bit<4>>())[3:0]) {
            4w4: parse_ipv4;
            4w6: parse_ipv6;
            default: accept;
        }
    }
    @name(".parse_ipv4") state parse_ipv4 {
        packet.extract(hdr.ipv4);
        transition accept;
    }
    @name(".parse_ipv6") state parse_ipv6 {
        packet.extract(hdr.ipv6);
        transition accept;
    }
    @name(".parse_mpls0") state parse_mpls0 {
        packet.extract(hdr.mpls0);
        transition select(hdr.mpls0.s) {
            1w1: parse_ip;
            default: parse_mpls1;
        }
    }
    @name(".parse_mpls1") state parse_mpls1 {
        packet.extract(hdr.mpls1);
        transition select(hdr.mpls1.s) {
            1w1: parse_ethernet_inner;
            default: accept;
        }
    }
    @name(".parse_pppoe") state parse_pppoe {
        packet.extract(hdr.pppoe);
        transition select(hdr.pppoe.protocol) {
            16w0x21: parse_ip;
            16w0x57: parse_ip;
            default: accept;
        }
    }
    @name(".parse_vlan_service") state parse_vlan_service {
        packet.extract(hdr.vlan_service);
        transition select(hdr.vlan_service.etherType) {
            16w0x8863: parse_pppoe;
            16w0x8864: parse_pppoe;
            default: accept;
        }
    }
    @name(".parse_vlan_subsc") state parse_vlan_subsc {
        packet.extract(hdr.vlan_subsc);
        transition select(hdr.vlan_subsc.etherType) {
            16w0x8100: parse_vlan_service;
            16w0x8863: parse_pppoe;
            16w0x8864: parse_pppoe;
            default: accept;
        }
    }
    @name(".start") state start {
        transition select((packet.lookahead<bit<1>>())[0:0]) {
            1w0: parse_cpu_header;
            default: parse_ethernet_outer;
        }
    }
}

control egress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".a_ds_pppoe_aftermath_v4") action a_ds_pppoe_aftermath_v4() {
        hdr.pppoe.totalLength = hdr.ipv4.totalLen + 16w65531;
        hdr.pppoe.protocol = 16w0x21;
    }
    @name(".a_ds_pppoe_aftermath_v6") action a_ds_pppoe_aftermath_v6() {
        hdr.pppoe.totalLength = hdr.ipv6.payloadLen + 16w65528;
        hdr.pppoe.protocol = 16w0x57;
    }
    @name("._drop") action _drop() {
        meta.ingress_md.usds = 2w0x2;
        mark_to_drop();
    }
    @name(".a_ds_srcmac") action a_ds_srcmac(bit<48> outer_src_mac, bit<48> outer_dst_mac, bit<48> inner_src_mac) {
        hdr.ethernet_outer.srcAddr = outer_src_mac;
        hdr.ethernet_outer.dstAddr = outer_dst_mac;
        hdr.ethernet_inner.srcAddr = inner_src_mac;
    }
    @name("._nop") action _nop() {
    }
    @name(".a_us_srcmac") action a_us_srcmac(bit<48> src_mac) {
        hdr.ethernet_outer.srcAddr = src_mac;
    }
    @name(".t_ds_pppoe_aftermath_v4") table t_ds_pppoe_aftermath_v4 {
        actions = {
            a_ds_pppoe_aftermath_v4;
        }
    }
    @name(".t_ds_pppoe_aftermath_v6") table t_ds_pppoe_aftermath_v6 {
        actions = {
            a_ds_pppoe_aftermath_v6;
        }
    }
    @name(".t_ds_srcmac") table t_ds_srcmac {
        actions = {
            _drop;
            a_ds_srcmac;
        }
        key = {
            standard_metadata.egress_port: exact;
            hdr.mpls0.label              : exact;
        }
        max_size = 256;
    }
    @name(".t_us_srcmac") table t_us_srcmac {
        actions = {
            _nop;
            a_us_srcmac;
        }
        key = {
            standard_metadata.egress_port: exact;
            hdr.mpls0.label              : exact;
        }
    }
    apply {
        if (meta.ingress_md.cp == 1w0) {
            if (meta.ingress_md.usds == 2w0x1) {
                t_us_srcmac.apply();
            }
            else {
                if (hdr.ipv4.isValid()) {
                    t_ds_pppoe_aftermath_v4.apply();
                }
                else {
                    t_ds_pppoe_aftermath_v6.apply();
                }
                t_ds_srcmac.apply();
            }
        }
    }
}

control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".ctr_ds_subsc") counter(32w8192, CounterType.packets) ctr_ds_subsc;
    @name(".ctr_us_subsc") counter(32w8192, CounterType.packets) ctr_us_subsc;
    @name(".mtr_ds_subsc") meter(32w8192, MeterType.bytes) mtr_ds_subsc;
    @name("._drop") action _drop() {
        meta.ingress_md.usds = 2w0x2;
        mark_to_drop();
    }
    @name(".a_antispoof_ipv4v6_pass") action a_antispoof_ipv4v6_pass() {
        hdr.pppoe.setInvalid();
        hdr.vlan_subsc.setInvalid();
        hdr.ethernet_inner.setInvalid();
        hdr.mpls1.setInvalid();
    }
    @name(".a_antispoof_mac_pass") action a_antispoof_mac_pass(bit<8> subsc_id, bit<8> lawf_int, bit<32> ctr_bucket) {
        meta.ingress_md.subsc_id = subsc_id;
        ctr_us_subsc.count((bit<32>)ctr_bucket);
    }
    @name(".a_ds_route_pushstack") action a_ds_route_pushstack(bit<20> mpls0_label, bit<20> mpls1_label, bit<16> subsc_vid, bit<16> service_vid, bit<16> pppoe_session_id, bit<9> out_port, bit<48> inner_cpe_mac, bit<8> lawf_int, bit<32> ctr_bucket) {
        hdr.mpls0.label = mpls0_label;
        hdr.mpls0.s = 1w0;
        hdr.mpls1.setValid();
        hdr.mpls1.label = mpls1_label;
        hdr.mpls1.s = 1w1;
        hdr.ethernet_inner.setValid();
        hdr.ethernet_inner.dstAddr = inner_cpe_mac;
        hdr.ethernet_inner.etherType = 16w0x8100;
        hdr.vlan_subsc.setValid();
        hdr.vlan_subsc.vlanID = subsc_vid;
        hdr.vlan_subsc.etherType = 16w0x8100;
        hdr.vlan_service.setValid();
        hdr.vlan_service.vlanID = service_vid;
        hdr.vlan_service.etherType = 16w0x8864;
        hdr.pppoe.setValid();
        hdr.pppoe.version = 4w1;
        hdr.pppoe.typeID = 4w1;
        hdr.pppoe.sessionID = pppoe_session_id;
        standard_metadata.egress_spec = out_port;
        ctr_ds_subsc.count((bit<32>)ctr_bucket);
        mtr_ds_subsc.execute_meter((bit<32>)ctr_bucket, meta.ingress_md.meter_result);
    }
    @name(".a_line_map_pass") action a_line_map_pass(bit<32> line_id, bit<8> lawf_int) {
        meta.ingress_md.line_id = line_id;
    }
    @name(".a_meter_action_pass") action a_meter_action_pass() {
    }
    @name(".a_pppoe_cpdp_to_cp") action a_pppoe_cpdp_to_cp(bit<9> cp_port) {
        meta.ingress_md.cp = 1w1;
        standard_metadata.egress_spec = cp_port;
    }
    @name(".a_pppoe_cpdp_pass_ip") action a_pppoe_cpdp_pass_ip(bit<8> version) {
    }
    @name(".a_us_routev4v6") action a_us_routev4v6(bit<9> out_port, bit<20> mpls_label, bit<48> via_hwaddr) {
        hdr.vlan_service.setInvalid();
        standard_metadata.egress_spec = out_port;
        hdr.mpls0.label = mpls_label;
        hdr.mpls0.s = 1w1;
        hdr.ethernet_outer.dstAddr = via_hwaddr;
    }
    @name(".a_usds_handle_ds") action a_usds_handle_ds() {
        meta.ingress_md.usds = 2w0x0;
    }
    @name(".a_usds_handle_us") action a_usds_handle_us() {
        hdr.vlan_service.setValid();
        meta.ingress_md.usds = 2w0x1;
    }
    @name(".t_antispoof_ipv4") table t_antispoof_ipv4 {
        actions = {
            _drop;
            a_antispoof_ipv4v6_pass;
        }
        key = {
            meta.ingress_md.line_id : exact;
            meta.ingress_md.subsc_id: exact;
            hdr.ipv4.srcAddr        : exact;
        }
        max_size = 8192;
    }
    @name(".t_antispoof_ipv6") table t_antispoof_ipv6 {
        actions = {
            _drop;
            a_antispoof_ipv4v6_pass;
        }
        key = {
            meta.ingress_md.line_id : exact;
            meta.ingress_md.subsc_id: exact;
            hdr.ipv6.srcAddr        : exact;
        }
        max_size = 16384;
    }
    @name(".t_antispoof_mac") table t_antispoof_mac {
        actions = {
            _drop;
            a_antispoof_mac_pass;
        }
        key = {
            meta.ingress_md.line_id   : exact;
            hdr.vlan_service.vlanID   : exact;
            hdr.ethernet_inner.srcAddr: exact;
            hdr.pppoe.sessionID       : exact;
        }
        max_size = 16384;
    }
    @name(".t_ds_routev4") table t_ds_routev4 {
        actions = {
            _drop;
            a_ds_route_pushstack;
        }
        key = {
            hdr.ipv4.dstAddr: exact;
        }
        max_size = 16384;
    }
    @name(".t_ds_routev6") table t_ds_routev6 {
        actions = {
            _drop;
            a_ds_route_pushstack;
        }
        key = {
            hdr.mpls0.label : exact;
            hdr.ipv6.dstAddr: exact;
        }
        max_size = 16384;
    }
    @name(".t_line_map") table t_line_map {
        actions = {
            _drop;
            a_line_map_pass;
        }
        key = {
            standard_metadata.ingress_port: exact;
            hdr.mpls0.label               : exact;
            hdr.mpls1.label               : exact;
            hdr.vlan_subsc.vlanID         : exact;
        }
        max_size = 8192;
    }
    @name(".t_meter_action") table t_meter_action {
        actions = {
            _drop;
            a_meter_action_pass;
        }
        key = {
            meta.ingress_md.meter_result: exact;
        }
        max_size = 16;
    }
    @name(".t_pppoe_cpdp") table t_pppoe_cpdp {
        actions = {
            _drop;
            a_pppoe_cpdp_to_cp;
            a_pppoe_cpdp_pass_ip;
        }
        key = {
            hdr.ethernet_inner.dstAddr: exact;
            hdr.vlan_service.etherType: exact;
            hdr.pppoe.protocol        : exact;
        }
        max_size = 16;
    }
    @name(".t_us_routev4") table t_us_routev4 {
        actions = {
            _drop;
            a_us_routev4v6;
        }
        key = {
            hdr.vlan_service.vlanID: exact;
            hdr.ipv4.dstAddr       : exact;
        }
        max_size = 256;
    }
    @name(".t_us_routev6") table t_us_routev6 {
        actions = {
            _drop;
            a_us_routev4v6;
        }
        key = {
            hdr.vlan_service.vlanID: exact;
            hdr.ipv6.dstAddr       : exact;
        }
        max_size = 256;
    }
    @name(".t_usds") table t_usds {
        actions = {
            a_usds_handle_ds;
            a_usds_handle_us;
            _drop;
        }
        key = {
            hdr.ethernet_outer.dstAddr    : exact;
            standard_metadata.ingress_port: exact;
            hdr.mpls0.label               : exact;
        }
        max_size = 256;
    }
    apply {
        t_usds.apply();
        if (meta.ingress_md.usds == 2w0x1 && hdr.pppoe.isValid()) {
            t_line_map.apply();
            t_pppoe_cpdp.apply();
            if (meta.ingress_md.cp == 1w0) {
                t_antispoof_mac.apply();
                if (hdr.ipv4.isValid()) {
                    t_antispoof_ipv4.apply();
                    if (meta.ingress_md.usds == 2w0x1) {
                        t_us_routev4.apply();
                    }
                }
                else {
                    if (hdr.ipv6.isValid()) {
                        t_antispoof_ipv6.apply();
                        if (meta.ingress_md.usds == 2w0x1) {
                            t_us_routev6.apply();
                        }
                    }
                }
            }
        }
        else {
            if (meta.ingress_md.usds == 2w0x0) {
                if (hdr.ipv4.isValid()) {
                    t_ds_routev4.apply();
                }
                else {
                    if (hdr.ipv6.isValid()) {
                        t_ds_routev6.apply();
                    }
                }
                t_meter_action.apply();
            }
        }
    }
}

control DeparserImpl(packet_out packet, in headers hdr) {
    apply {
        packet.emit(hdr.cpu_header);
        packet.emit(hdr.ethernet_outer);
        packet.emit(hdr.mpls0);
        packet.emit(hdr.mpls1);
        packet.emit(hdr.ethernet_inner);
        packet.emit(hdr.vlan_subsc);
        packet.emit(hdr.vlan_service);
        packet.emit(hdr.pppoe);
        packet.emit(hdr.ipv6);
        packet.emit(hdr.ipv4);
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

V1Switch(ParserImpl(), verifyChecksum(), ingress(), egress(), computeChecksum(), DeparserImpl()) main;

