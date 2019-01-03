#include <core.p4>
#include <v1model.p4>

struct intrinsic_metadata_t {
    bit<9>  ingress_port;
    bit<16> packet_length;
    bit<32> eg_ucast_port;
    bit<6>  eg_queue;
    bit<16> eg_mcast_group1;
    bit<16> eg_mcast_group2;
    bit<1>  copy_to_cpu;
    bit<3>  cos_for_copy_to_cpu;
    bit<32> egress_port;
    bit<16> egress_instance;
    bit<2>  instance_type;
    bit<8>  parser_status;
    bit<8>  parser_error_location;
    bit<32> global_version_num;
    bit<48> ingress_global_timestamp;
    bit<48> egress_global_timestamp;
    bit<48> ingress_mac_timestamp;
    bit<13> mcast_hash1;
    bit<13> mcast_hash2;
    bit<1>  deflect_on_drop;
    bit<3>  meter1;
    bit<3>  meter2;
    bit<19> enq_qdepth;
    bit<2>  enq_congest_stat;
    bit<32> enq_timestamp;
    bit<19> deq_qdepth;
    bit<2>  deq_congest_stat;
    bit<32> deq_timedelta;
}

struct routing_metadata_t {
    bit<1> drop;
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

header tcp_t {
    bit<16> srcPort;
    bit<16> dstPort;
    bit<32> seqNo;
    bit<32> ackNo;
    bit<4>  dataOffset;
    bit<3>  res;
    bit<3>  ecn;
    bit<6>  ctrl;
    bit<16> window;
    bit<16> checksum;
    bit<16> urgentPtr;
}

header udp_t {
    bit<16> srcPort;
    bit<16> dstPort;
    bit<16> hdr_length;
    bit<16> checksum;
}

header vlan_tag_t {
    bit<3>  pri;
    bit<1>  cfi;
    bit<12> vlan_id;
    bit<16> etherType;
}

struct metadata {
    @name(".intrinsic_metadata") 
    intrinsic_metadata_t intrinsic_metadata;
    @name(".routing_metadata") 
    routing_metadata_t   routing_metadata;
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
    @name(".tcp") 
    tcp_t                                          tcp;
    @name(".udp") 
    udp_t                                          udp;
    @name(".vlan_tag") 
    vlan_tag_t                                     vlan_tag;
}
#include <tofino/lpf.p4>

parser ParserImpl(packet_in packet, out headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".parse_ethernet") state parse_ethernet {
        packet.extract<ethernet_t>(hdr.ethernet);
        transition select(hdr.ethernet.etherType) {
            16w0x8100: parse_vlan_tag;
            16w0x800: parse_ipv4;
            16w0x86dd: parse_ipv6;
            default: accept;
        }
    }
    @name(".parse_ipv4") state parse_ipv4 {
        packet.extract<ipv4_t>(hdr.ipv4);
        transition select(hdr.ipv4.fragOffset, hdr.ipv4.protocol) {
            (13w0, 8w6): parse_tcp;
            (13w0, 8w17): parse_udp;
            default: accept;
        }
    }
    @name(".parse_ipv6") state parse_ipv6 {
        packet.extract<ipv6_t>(hdr.ipv6);
        transition select(hdr.ipv6.nextHdr) {
            8w6: parse_tcp;
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
        transition accept;
    }
    @name(".parse_vlan_tag") state parse_vlan_tag {
        packet.extract<vlan_tag_t>(hdr.vlan_tag);
        transition select(hdr.vlan_tag.etherType) {
            16w0x800: parse_ipv4;
            default: accept;
        }
    }
    @name(".start") state start {
        transition parse_ethernet;
    }
}

control egress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}
#include <tofino/p4_14_prim.p4>

control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".NoAction") action NoAction_0() {
    }
    @name(".NoAction") action NoAction_5() {
    }
    @name(".NoAction") action NoAction_6() {
    }
    @name(".NoAction") action NoAction_7() {
    }
    bit<32> tmp;
    bit<32> tmp_0;
    bit<32> tmp_1;
    bit<32> tmp_2;
    bit<8> tmp_3;
    bit<8> tmp_4;
    @name(".colorCntr") counter(32w100, CounterType.packets) colorCntr_0;
    @name(".meter_1") direct_meter<bit<8>>(MeterType.bytes) meter_4;
    @name(".meter_3") @pre_color(hdr.ipv4.diffserv) direct_meter<bit<8>>(MeterType.bytes) meter_5;
    @name(".meter_0") meter(32w500, MeterType.bytes) meter_6;
    @meter_pre_color_aware_per_flow_enable(1) @name(".meter_2") meter(32w500, MeterType.bytes) meter_7;
    @name(".meter_lpf") Lpf<bit<32>, bit<32>>(32w500) meter_lpf_0;
    @name(".meter_lpf_direct") DirectLpf<bit<32>>() meter_lpf_direct_0;
    @name(".meter_lpf_tcam") Lpf<bit<32>, bit<32>>(32w500) meter_lpf_tcam_0;
    @name(".meter_lpf_tcam_direct") DirectLpf<bit<32>>() meter_lpf_tcam_direct_0;
    @name(".count_color") action count_color(bit<32> color_idx) {
        colorCntr_0.count(color_idx);
    }
    @name(".next_hop_ipv4_lpf") action next_hop_ipv4_lpf(bit<9> egress_port, bit<48> srcmac, bit<48> dstmac, bit<32> lpf_idx) {
        {
            bit<8> ttl_1 = hdr.ipv4.ttl;
            ttl_1 = ttl_1 + 8w255;
            hdr.ig_intr_md_for_tm.ucast_egress_port = egress_port;
            hdr.ipv4.ttl = ttl_1;
        }
        hdr.ethernet.srcAddr = srcmac;
        hdr.ethernet.dstAddr = dstmac;
        tmp = meter_lpf_0.execute(hdr.ipv4.srcAddr, lpf_idx);
        hdr.ipv4.srcAddr = tmp;
    }
    @name(".nop") action nop() {
    }
    @name(".nop") action nop_0() {
    }
    @name(".nop") action nop_9() {
    }
    @name(".nop") action nop_10() {
    }
    @name(".nop") action nop_11() {
    }
    @name(".nop") action nop_12() {
    }
    @name(".nop") action nop_13() {
    }
    @name(".next_hop_ipv4_direct_lpf") action next_hop_ipv4_direct_lpf(bit<9> egress_port, bit<48> srcmac, bit<48> dstmac) {
        {
            bit<8> ttl_2 = hdr.ipv4.ttl;
            ttl_2 = ttl_2 + 8w255;
            hdr.ig_intr_md_for_tm.ucast_egress_port = egress_port;
            hdr.ipv4.ttl = ttl_2;
        }
        hdr.ethernet.srcAddr = srcmac;
        hdr.ethernet.dstAddr = dstmac;
        tmp_0 = meter_lpf_direct_0.execute(hdr.ipv4.srcAddr);
        hdr.ipv4.srcAddr = tmp_0;
    }
    @name(".next_hop_ipv4_lpf_tcam") action next_hop_ipv4_lpf_tcam(bit<9> egress_port, bit<48> srcmac, bit<48> dstmac, bit<32> lpf_idx) {
        {
            bit<8> ttl_3 = hdr.ipv4.ttl;
            ttl_3 = ttl_3 + 8w255;
            hdr.ig_intr_md_for_tm.ucast_egress_port = egress_port;
            hdr.ipv4.ttl = ttl_3;
        }
        hdr.ethernet.srcAddr = srcmac;
        hdr.ethernet.dstAddr = dstmac;
        tmp_1 = meter_lpf_tcam_0.execute(hdr.ipv4.srcAddr, lpf_idx);
        hdr.ipv4.srcAddr = tmp_1;
    }
    @name(".next_hop_ipv4_lpf_direct_tcam") action next_hop_ipv4_lpf_direct_tcam(bit<9> egress_port, bit<48> srcmac, bit<48> dstmac) {
        {
            bit<8> ttl_4 = hdr.ipv4.ttl;
            ttl_4 = ttl_4 + 8w255;
            hdr.ig_intr_md_for_tm.ucast_egress_port = egress_port;
            hdr.ipv4.ttl = ttl_4;
        }
        hdr.ethernet.srcAddr = srcmac;
        hdr.ethernet.dstAddr = dstmac;
        tmp_2 = meter_lpf_tcam_direct_0.execute(hdr.ipv4.srcAddr);
        hdr.ipv4.srcAddr = tmp_2;
    }
    @name(".meter_action") action meter_action(bit<9> egress_port, bit<48> srcmac, bit<48> dstmac, bit<32> idx) {
        {
            bit<8> ttl_5 = hdr.ipv4.ttl;
            ttl_5 = ttl_5 + 8w255;
            hdr.ig_intr_md_for_tm.ucast_egress_port = egress_port;
            hdr.ipv4.ttl = ttl_5;
        }
        hdr.ethernet.srcAddr = srcmac;
        hdr.ethernet.dstAddr = dstmac;
        meter_6.execute_meter<bit<8>>(idx, hdr.ipv4.diffserv);
    }
    @name(".meter_action_color_aware") action meter_action_color_aware(bit<9> egress_port, bit<48> srcmac, bit<48> dstmac, bit<32> idx) {
        {
            bit<8> ttl_6 = hdr.ipv4.ttl;
            ttl_6 = ttl_6 + 8w255;
            hdr.ig_intr_md_for_tm.ucast_egress_port = egress_port;
            hdr.ipv4.ttl = ttl_6;
        }
        hdr.ethernet.srcAddr = srcmac;
        hdr.ethernet.dstAddr = dstmac;
        tmp_4 = hdr.ipv4.diffserv;
        execute_meter_with_color<meter, bit<32>, bit<8>>(meter_7, idx, tmp_3, tmp_4);
        hdr.ipv4.diffserv = tmp_3;
    }
    @name(".meter_action_color_unaware") action meter_action_color_unaware(bit<9> egress_port, bit<48> srcmac, bit<48> dstmac, bit<32> idx) {
        {
            bit<8> ttl_7 = hdr.ipv4.ttl;
            ttl_7 = ttl_7 + 8w255;
            hdr.ig_intr_md_for_tm.ucast_egress_port = egress_port;
            hdr.ipv4.ttl = ttl_7;
        }
        hdr.ethernet.srcAddr = srcmac;
        hdr.ethernet.dstAddr = dstmac;
        meter_7.execute_meter<bit<8>>(idx, hdr.ipv4.diffserv);
    }
    @stage(11) @name(".color_match") table color_match_0 {
        actions = {
            count_color();
            @defaultonly NoAction_0();
        }
        key = {
            hdr.ethernet.dstAddr: exact @name("ethernet.dstAddr") ;
            hdr.ipv4.diffserv   : exact @name("ipv4.diffserv") ;
        }
        size = 256;
        default_action = NoAction_0();
    }
    @stage(4) @name(".match_tbl_lpf") table match_tbl_lpf_0 {
        actions = {
            next_hop_ipv4_lpf();
            @defaultonly nop();
        }
        key = {
            hdr.ipv4.dstAddr: exact @name("ipv4.dstAddr") ;
            hdr.ipv4.srcAddr: exact @name("ipv4.srcAddr") ;
        }
        default_action = nop();
    }
    @stage(5) @name(".match_tbl_lpf_direct") table match_tbl_lpf_direct_0 {
        actions = {
            next_hop_ipv4_direct_lpf();
            @defaultonly nop_0();
        }
        key = {
            hdr.ipv4.dstAddr: exact @name("ipv4.dstAddr") ;
            hdr.ipv4.srcAddr: exact @name("ipv4.srcAddr") ;
        }
        default_action = nop_0();
    }
    @stage(4) @name(".match_tbl_tcam_lpf") table match_tbl_tcam_lpf_0 {
        actions = {
            next_hop_ipv4_lpf_tcam();
            @defaultonly nop_9();
        }
        key = {
            hdr.ipv4.dstAddr: ternary @name("ipv4.dstAddr") ;
            hdr.ipv4.srcAddr: ternary @name("ipv4.srcAddr") ;
        }
        default_action = nop_9();
    }
    @stage(5) @name(".match_tbl_tcam_lpf_direct") table match_tbl_tcam_lpf_direct_0 {
        actions = {
            next_hop_ipv4_lpf_direct_tcam();
            @defaultonly nop_10();
        }
        key = {
            hdr.ipv4.dstAddr: ternary @name("ipv4.dstAddr") ;
            hdr.ipv4.srcAddr: ternary @name("ipv4.srcAddr") ;
        }
        default_action = nop_10();
    }
    @command_line("--placement", "pragma") @command_line("--no-dead-code-elimination") @stage(1) @name(".meter_tbl") table meter_tbl_0 {
        actions = {
            nop_11();
            meter_action();
            @defaultonly NoAction_5();
        }
        key = {
            hdr.ipv4.dstAddr: exact @name("ipv4.dstAddr") ;
        }
        default_action = NoAction_5();
    }
    @name(".next_hop_ipv4") action next_hop_ipv4(bit<9> egress_port, bit<48> srcmac, bit<48> dstmac) {
        meter_5.read(hdr.ipv4.diffserv);
        {
            bit<8> ttl_16 = hdr.ipv4.ttl;
            ttl_16 = ttl_16 + 8w255;
            hdr.ig_intr_md_for_tm.ucast_egress_port = egress_port;
            hdr.ipv4.ttl = ttl_16;
        }
        hdr.ethernet.srcAddr = srcmac;
        hdr.ethernet.dstAddr = dstmac;
    }
    @stage(3) @name(".meter_tbl_color_aware_direct") table meter_tbl_color_aware_direct_0 {
        actions = {
            next_hop_ipv4();
            @defaultonly nop_12();
        }
        key = {
            hdr.ipv4.dstAddr: exact @name("ipv4.dstAddr") ;
            hdr.ipv4.srcAddr: exact @name("ipv4.srcAddr") ;
        }
        default_action = nop_12();
        meters = meter_5;
    }
    @stage(2) @name(".meter_tbl_color_aware_indirect") table meter_tbl_color_aware_indirect_0 {
        actions = {
            nop_13();
            meter_action_color_aware();
            meter_action_color_unaware();
            @defaultonly NoAction_6();
        }
        key = {
            hdr.ipv4.dstAddr: exact @name("ipv4.dstAddr") ;
            hdr.ipv4.srcAddr: exact @name("ipv4.srcAddr") ;
        }
        default_action = NoAction_6();
    }
    @name(".nop") action nop_14() {
        meter_4.read(hdr.ipv4.diffserv);
    }
    @name(".next_hop_ipv4") action next_hop_ipv4_0(bit<9> egress_port, bit<48> srcmac, bit<48> dstmac) {
        meter_4.read(hdr.ipv4.diffserv);
        {
            bit<8> ttl_17 = hdr.ipv4.ttl;
            ttl_17 = ttl_17 + 8w255;
            hdr.ig_intr_md_for_tm.ucast_egress_port = egress_port;
            hdr.ipv4.ttl = ttl_17;
        }
        hdr.ethernet.srcAddr = srcmac;
        hdr.ethernet.dstAddr = dstmac;
    }
    @stage(0) @name(".meter_tbl_direct") table meter_tbl_direct_0 {
        actions = {
            nop_14();
            next_hop_ipv4_0();
            @defaultonly NoAction_7();
        }
        key = {
            hdr.ipv4.dstAddr: exact @name("ipv4.dstAddr") ;
            hdr.ipv4.srcAddr: exact @name("ipv4.srcAddr") ;
        }
        meters = meter_4;
        default_action = NoAction_7();
    }
    apply {
        meter_tbl_direct_0.apply();
        meter_tbl_0.apply();
        meter_tbl_color_aware_indirect_0.apply();
        meter_tbl_color_aware_direct_0.apply();
        match_tbl_lpf_0.apply();
        match_tbl_tcam_lpf_0.apply();
        match_tbl_lpf_direct_0.apply();
        match_tbl_tcam_lpf_direct_0.apply();
        color_match_0.apply();
    }
}

control DeparserImpl(packet_out packet, in headers hdr) {
    apply {
        packet.emit<ethernet_t>(hdr.ethernet);
        packet.emit<ipv6_t>(hdr.ipv6);
        packet.emit<vlan_tag_t>(hdr.vlan_tag);
        packet.emit<ipv4_t>(hdr.ipv4);
        packet.emit<udp_t>(hdr.udp);
        packet.emit<tcp_t>(hdr.tcp);
    }
}

control verifyChecksum(inout headers hdr, inout metadata meta) {
    apply {
    }
}

control computeChecksum(inout headers hdr, inout metadata meta) {
    apply {
        update_checksum<tuple<bit<4>, bit<4>, bit<8>, bit<16>, bit<16>, bit<3>, bit<13>, bit<8>, bit<8>, bit<32>, bit<32>>, bit<16>>(true, { hdr.ipv4.version, hdr.ipv4.ihl, hdr.ipv4.diffserv, hdr.ipv4.totalLen, hdr.ipv4.identification, hdr.ipv4.flags, hdr.ipv4.fragOffset, hdr.ipv4.ttl, hdr.ipv4.protocol, hdr.ipv4.srcAddr, hdr.ipv4.dstAddr }, hdr.ipv4.hdrChecksum, HashAlgorithm.csum16);
    }
}

V1Switch<headers, metadata>(ParserImpl(), verifyChecksum(), ingress(), egress(), computeChecksum(), DeparserImpl()) main;

