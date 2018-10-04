#include <core.p4>
#include <v1model.p4>

struct md_t {
    bit<16> sport;
    bit<16> dport;
}

struct range_metadata_t {
    bit<16> src_range_index;
    bit<16> dest_range_index;
}

struct routing_metadata_t {
    bit<1>  drop;
    bit<20> learn_meta_1;
    bit<24> learn_meta_2;
    bit<25> learn_meta_3;
    bit<10> learn_meta_4;
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

@command_line("--disable-init-metadata") header ethernet_t {
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
    @name(".md") 
    md_t               md;
    @name(".range_mdata") 
    range_metadata_t   range_mdata;
    @name(".routing_metadata") 
    routing_metadata_t routing_metadata;
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
    @name(".tcp") 
    tcp_t                                          tcp;
    @name(".udp") 
    udp_t                                          udp;
    @name(".vlan_tag") 
    vlan_tag_t                                     vlan_tag;
}

parser ParserImpl(packet_in packet, out headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".parse_ethernet") state parse_ethernet {
        packet.extract(hdr.ethernet);
        transition select(hdr.ethernet.etherType) {
            16w0x8100: parse_vlan_tag;
            16w0x800: parse_ipv4;
            default: accept;
        }
    }
    @name(".parse_ipv4") state parse_ipv4 {
        packet.extract(hdr.ipv4);
        transition select(hdr.ipv4.fragOffset, hdr.ipv4.protocol) {
            (13w0, 8w6): parse_tcp;
            (13w0, 8w17): parse_udp;
            default: accept;
        }
    }
    @name(".parse_tcp") state parse_tcp {
        packet.extract(hdr.tcp);
        meta.md.sport = hdr.tcp.srcPort;
        meta.md.dport = hdr.tcp.dstPort;
        transition accept;
    }
    @name(".parse_udp") state parse_udp {
        packet.extract(hdr.udp);
        meta.md.sport = hdr.udp.srcPort;
        meta.md.dport = hdr.udp.dstPort;
        transition accept;
    }
    @name(".parse_vlan_tag") state parse_vlan_tag {
        packet.extract(hdr.vlan_tag);
        transition select(hdr.vlan_tag.etherType) {
            16w0x800: parse_ipv4;
            default: accept;
        }
    }
    @name(".start") state start {
        transition parse_ethernet;
    }
}

@name(".ecmp_action_profile") @mode("resilient") action_selector(HashAlgorithm.random, 32w1024, 32w64) ecmp_action_profile;

@name(".indirect_action_profile") action_profile(32w1500) indirect_action_profile;

control egress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".nop") action nop() {
    }
    @name(".udp_set_src") action udp_set_src(bit<16> port) {
        hdr.udp.srcPort = port;
    }
    @immediate(1) @stage(0) @name(".eg_udp") table eg_udp {
        actions = {
            nop;
            udp_set_src;
        }
        key = {
            hdr.ethernet.isValid(): exact;
            hdr.ipv4.isValid()    : exact;
            hdr.udp.isValid()     : exact;
            hdr.udp.srcPort       : exact;
        }
    }
    apply {
        eg_udp.apply();
    }
}

@name("learn_1") struct learn_1_0 {
    bit<4>  ihl;
    bit<8>  protocol;
    bit<32> srcAddr;
    bit<48> srcAddr_0;
    bit<48> dstAddr;
    bit<13> fragOffset;
    bit<16> identification;
    bit<20> learn_meta_1;
    bit<10> learn_meta_4;
}

@name("learn_2") struct learn_2_0 {
    bit<4>  ihl;
    bit<16> identification;
    bit<8>  protocol;
    bit<32> srcAddr;
    bit<48> srcAddr_0;
    bit<48> dstAddr;
    bit<13> fragOffset;
    bit<24> learn_meta_2;
    bit<25> learn_meta_3;
}

control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".nop") action nop() {
    }
    @name(".set_drange_mdata") action set_drange_mdata(bit<16> index) {
        meta.range_mdata.dest_range_index = index;
    }
    @name(".udp_set_dest") action udp_set_dest(bit<16> port) {
        hdr.udp.dstPort = port;
    }
    @name(".tcp_set_src_dest") action tcp_set_src_dest(bit<16> sport, bit<16> dport) {
        hdr.tcp.srcPort = sport;
        hdr.tcp.dstPort = dport;
    }
    @name(".hop") action hop(inout bit<8> ttl, bit<9> egress_port) {
        ttl = ttl + 8w255;
        hdr.ig_intr_md_for_tm.ucast_egress_port = egress_port;
    }
    @name(".hop_ipv4") action hop_ipv4(bit<9> egress_port) {
        hop(hdr.ipv4.ttl, egress_port);
    }
    @name(".drop_ipv4") action drop_ipv4() {
        mark_to_drop();
    }
    @name(".learn_1") action learn_1(bit<20> learn_meta_1, bit<10> learn_meta_4) {
        digest<learn_1_0>((bit<32>)0, { hdr.ipv4.ihl, hdr.ipv4.protocol, hdr.ipv4.srcAddr, hdr.ethernet.srcAddr, hdr.ethernet.dstAddr, hdr.ipv4.fragOffset, hdr.ipv4.identification, meta.routing_metadata.learn_meta_1, meta.routing_metadata.learn_meta_4 });
        meta.routing_metadata.learn_meta_1 = learn_meta_1;
        meta.routing_metadata.learn_meta_4 = learn_meta_4;
    }
    @name(".learn_2") action learn_2(bit<24> learn_meta_2, bit<25> learn_meta_3) {
        digest<learn_2_0>((bit<32>)0, { hdr.ipv4.ihl, hdr.ipv4.identification, hdr.ipv4.protocol, hdr.ipv4.srcAddr, hdr.ethernet.srcAddr, hdr.ethernet.dstAddr, hdr.ipv4.fragOffset, meta.routing_metadata.learn_meta_2, meta.routing_metadata.learn_meta_3 });
        meta.routing_metadata.learn_meta_2 = learn_meta_2;
        meta.routing_metadata.learn_meta_3 = learn_meta_3;
    }
    @name(".custom_action_1") action custom_action_1(bit<9> egress_port, bit<32> ipAddr, bit<48> dstAddr, bit<16> tcpPort) {
        hdr.ig_intr_md_for_tm.ucast_egress_port = egress_port;
        hdr.ipv4.srcAddr = ipAddr;
        hdr.ethernet.dstAddr = dstAddr;
        hdr.tcp.dstPort = tcpPort;
    }
    @name(".modify_tcp_dst_port_1") action modify_tcp_dst_port_1(bit<16> dstPort, bit<9> egress_port) {
        hdr.tcp.dstPort = dstPort;
        hdr.ig_intr_md_for_tm.ucast_egress_port = egress_port;
    }
    @name(".next_hop_ipv4") action next_hop_ipv4(bit<9> egress_port, bit<48> srcmac, bit<48> dstmac) {
        hop(hdr.ipv4.ttl, egress_port);
        hdr.ethernet.srcAddr = srcmac;
        hdr.ethernet.dstAddr = dstmac;
    }
    @name(".custom_action_2") action custom_action_2(bit<9> egress_port, bit<32> ipAddr, bit<16> tcpPort) {
        hdr.ipv4.srcAddr = ipAddr;
        hdr.tcp.dstPort = tcpPort;
        hop(hdr.ipv4.ttl, egress_port);
    }
    @name(".custom_action_3") action custom_action_3(bit<9> egress_port, bit<48> dstAddr, bit<32> dstIp) {
        hdr.ipv4.dstAddr = dstIp;
        hdr.ethernet.dstAddr = dstAddr;
        hop(hdr.ipv4.ttl, egress_port);
    }
    @name(".nhop_set") action nhop_set(bit<9> port) {
        hdr.ig_intr_md_for_tm.ucast_egress_port = port;
    }
    @name(".hop_ipv4_change_dmac") action hop_ipv4_change_dmac(bit<9> egress_port, bit<48> dstmac) {
        hop(hdr.ipv4.ttl, egress_port);
        hdr.ethernet.dstAddr = dstmac;
    }
    @name(".set_mgid") action set_mgid() {
        hdr.ig_intr_md_for_tm.mcast_grp_a = 16w0xaaaa;
        hdr.ig_intr_md_for_tm.mcast_grp_b = 16w0x5555;
    }
    @name(".clr_mgid") action clr_mgid() {
        hdr.ig_intr_md_for_tm.mcast_grp_a = ~hdr.ig_intr_md_for_tm.mcast_grp_a & hdr.ig_intr_md_for_tm.mcast_grp_a;
        hdr.ig_intr_md_for_tm.mcast_grp_b = ~hdr.ig_intr_md_for_tm.mcast_grp_b & hdr.ig_intr_md_for_tm.mcast_grp_b;
    }
    @name(".set_srange_mdata") action set_srange_mdata(bit<16> index) {
        meta.range_mdata.src_range_index = index;
    }
    @name(".modify_l2") action modify_l2(bit<9> egress_port, bit<48> srcAddr, bit<48> dstAddr, bit<16> tcp_sport, bit<16> tcp_dport) {
        hop(hdr.ipv4.ttl, egress_port);
        hdr.ethernet.srcAddr = srcAddr;
        hdr.ethernet.dstAddr = dstAddr;
        hdr.tcp.dstPort = tcp_dport;
        hdr.tcp.srcPort = tcp_sport;
    }
    @name(".modify_ip_id") action modify_ip_id(bit<9> port, bit<16> id, bit<48> srcAddr, bit<48> dstAddr) {
        hdr.ipv4.identification = id;
        hdr.ig_intr_md_for_tm.ucast_egress_port = port;
        hdr.ethernet.srcAddr = srcAddr;
        hdr.ethernet.dstAddr = dstAddr;
    }
    @name(".mod_mac_adr") action mod_mac_adr(bit<9> egress_port, bit<48> srcmac, bit<48> dstmac) {
        hdr.ig_intr_md_for_tm.ucast_egress_port = egress_port;
        hdr.ethernet.srcAddr = srcmac;
        hdr.ethernet.dstAddr = dstmac;
    }
    @name(".tcp_hdr_rm") action tcp_hdr_rm(bit<9> egress_port) {
        hdr.ig_intr_md_for_tm.ucast_egress_port = egress_port;
        hdr.tcp.setInvalid();
        hdr.ipv4.protocol = 8w0;
    }
    @name(".udp_hdr_add") action udp_hdr_add(bit<9> egress_port) {
        hdr.ig_intr_md_for_tm.ucast_egress_port = egress_port;
        hdr.udp.setValid();
        hdr.ipv4.protocol = 8w17;
        hdr.ipv4.totalLen = hdr.ipv4.totalLen + 16w8;
    }
    @stage(7) @name(".dest_non_overlap_range_table") table dest_non_overlap_range_table {
        actions = {
            nop;
            set_drange_mdata;
        }
        key = {
            hdr.tcp.dstPort: range;
        }
        size = 1024;
    }
    @command_line("--placement", "pragma") @command_line("--no-dead-code-elimination") @immediate(1) @stage(0) @name(".ig_udp") table ig_udp {
        actions = {
            nop;
            udp_set_dest;
        }
        key = {
            hdr.ethernet.isValid(): exact;
            hdr.ipv4.isValid()    : exact;
            hdr.udp.isValid()     : exact;
            hdr.udp.dstPort       : ternary;
        }
    }
    @name(".ig_udp_ternary_valid") table ig_udp_ternary_valid {
        actions = {
            nop;
            udp_set_dest;
            tcp_set_src_dest;
        }
        key = {
            hdr.ethernet.isValid(): exact;
            hdr.ipv4.isValid()    : exact;
            hdr.udp.isValid()     : ternary;
            meta.md.dport         : ternary;
        }
    }
    @immediate(1) @stage(0) @name(".ipv4_routing") table ipv4_routing {
        actions = {
            nop;
            hop_ipv4;
            drop_ipv4;
            learn_1;
            learn_2;
        }
        key = {
            hdr.ipv4.dstAddr: lpm;
        }
        size = 512;
    }
    @immediate(1) @stage(1) @ways(3) @pack(3) @name(".ipv4_routing_exm_ways_3_pack_3") table ipv4_routing_exm_ways_3_pack_3 {
        actions = {
            nop;
            custom_action_1;
        }
        key = {
            hdr.ipv4.dstAddr    : exact;
            hdr.ethernet.dstAddr: exact;
        }
    }
    @immediate(1) @stage(5) @ways(3) @pack(4) @name(".ipv4_routing_exm_ways_3_pack_4_stage_5") table ipv4_routing_exm_ways_3_pack_4_stage_5 {
        actions = {
            nop;
            modify_tcp_dst_port_1;
        }
        key = {
            hdr.ipv4.srcAddr    : exact;
            hdr.ethernet.dstAddr: exact;
            hdr.tcp.dstPort     : exact;
        }
    }
    @immediate(1) @stage(0) @ways(3) @pack(5) @name(".ipv4_routing_exm_ways_3_pack_5") table ipv4_routing_exm_ways_3_pack_5 {
        actions = {
            nop;
            modify_tcp_dst_port_1;
        }
        key = {
            hdr.ipv4.dstAddr: exact;
            hdr.ipv4.srcAddr: exact;
        }
    }
    @immediate(1) @stage(1) @ways(4) @pack(3) @name(".ipv4_routing_exm_ways_4_pack_3_stage_1") table ipv4_routing_exm_ways_4_pack_3_stage_1 {
        actions = {
            nop;
            next_hop_ipv4;
        }
        key = {
            hdr.ipv4.dstAddr: exact;
            hdr.ipv4.srcAddr: exact;
        }
    }
    @stage(6) @ways(4) @pack(4) @name(".ipv4_routing_exm_ways_4_pack_4_stage_6") table ipv4_routing_exm_ways_4_pack_4_stage_6 {
        actions = {
            nop;
            next_hop_ipv4;
        }
        key = {
            hdr.ethernet.srcAddr: exact;
            hdr.ethernet.dstAddr: exact;
            hdr.tcp.srcPort     : exact;
        }
    }
    @stage(8) @ways(4) @pack(5) @name(".ipv4_routing_exm_ways_4_pack_5_stage_8") table ipv4_routing_exm_ways_4_pack_5_stage_8 {
        actions = {
            nop;
            custom_action_2;
        }
        key = {
            hdr.ipv4.srcAddr    : exact;
            hdr.ethernet.dstAddr: exact;
            hdr.tcp.srcPort     : exact;
            hdr.tcp.dstPort     : exact;
        }
    }
    @stage(2) @ways(4) @pack(7) @name(".ipv4_routing_exm_ways_4_pack_7_stage_2") table ipv4_routing_exm_ways_4_pack_7_stage_2 {
        actions = {
            nop;
            custom_action_2;
        }
        key = {
            hdr.ipv4.dstAddr: exact;
            hdr.ipv4.srcAddr: exact;
            hdr.tcp.dstPort : exact;
            hdr.tcp.srcPort : exact;
        }
    }
    @immediate(1) @stage(3) @ways(5) @pack(3) @name(".ipv4_routing_exm_ways_5_pack_3_stage_3") table ipv4_routing_exm_ways_5_pack_3_stage_3 {
        actions = {
            nop;
            next_hop_ipv4;
        }
        key = {
            hdr.ipv4.dstAddr    : exact;
            hdr.ethernet.srcAddr: exact;
        }
    }
    @immediate(1) @stage(7) @ways(5) @pack(4) @name(".ipv4_routing_exm_ways_5_pack_4_stage_7") table ipv4_routing_exm_ways_5_pack_4_stage_7 {
        actions = {
            nop;
            custom_action_3;
        }
        key = {
            hdr.ipv4.dstAddr    : exact;
            hdr.ethernet.srcAddr: exact;
        }
    }
    @immediate(1) @stage(4) @ways(6) @pack(3) @name(".ipv4_routing_exm_ways_6_pack_3_stage_4") table ipv4_routing_exm_ways_6_pack_3_stage_4 {
        actions = {
            nop;
            next_hop_ipv4;
        }
        key = {
            hdr.ipv4.dstAddr    : exact;
            hdr.ethernet.dstAddr: exact;
        }
    }
    @stage(9) @name(".ipv4_routing_select") table ipv4_routing_select {
        actions = {
            nhop_set;
            nop;
        }
        key = {
            hdr.ipv4.dstAddr       : lpm;
            hdr.ipv4.srcAddr       : selector;
            hdr.ipv4.dstAddr       : selector;
            hdr.ipv4.identification: selector;
            hdr.ipv4.protocol      : selector;
        }
        size = 512;
        implementation = ecmp_action_profile;
    }
    @immediate(1) @stage(1) @name(".ipv4_routing_stage_1") table ipv4_routing_stage_1 {
        actions = {
            nop;
            hop_ipv4;
            hop_ipv4_change_dmac;
        }
        key = {
            hdr.ipv4.dstAddr: lpm;
            hdr.ipv4.srcAddr: exact;
        }
        size = 1024;
    }
    @stage(11) @entries_with_ranges(1) @name(".match_range_table") table match_range_table {
        actions = {
            nop;
            hop_ipv4;
        }
        key = {
            meta.range_mdata.src_range_index : ternary;
            meta.range_mdata.dest_range_index: ternary;
            hdr.tcp.srcPort                  : range;
            hdr.tcp.dstPort                  : range;
            hdr.ipv4.dstAddr                 : ternary;
            hdr.ipv4.srcAddr                 : ternary;
        }
        size = 1024;
    }
    @stage(10) @name(".no_key_1") table no_key_1 {
        actions = {
            set_mgid;
        }
    }
    @stage(11) @name(".no_key_2") table no_key_2 {
        actions = {
            clr_mgid;
        }
    }
    @stage(7) @name(".src_non_overlap_range_table") table src_non_overlap_range_table {
        actions = {
            nop;
            set_srange_mdata;
        }
        key = {
            hdr.tcp.srcPort: range;
        }
        size = 1024;
    }
    @immediate(1) @stage(8) @name(".tcam_adt_deep_stage_8") table tcam_adt_deep_stage_8 {
        actions = {
            nop;
            modify_l2;
        }
        key = {
            hdr.ethernet.srcAddr: ternary;
            hdr.ethernet.dstAddr: ternary;
            hdr.ipv4.srcAddr    : ternary;
            hdr.ipv4.dstAddr    : ternary;
        }
        size = 3072;
    }
    @stage(10) @name(".tcam_indirect_action") table tcam_indirect_action {
        actions = {
            nop;
            modify_ip_id;
        }
        key = {
            hdr.ethernet.srcAddr  : ternary;
            hdr.ethernet.dstAddr  : ternary;
            hdr.ethernet.etherType: exact;
            hdr.ipv4.srcAddr      : ternary;
            hdr.ipv4.dstAddr      : ternary;
            hdr.ipv4.protocol     : exact;
            hdr.ipv4.version      : exact;
        }
        size = 2048;
        implementation = indirect_action_profile;
    }
    @stage(5) @name(".tcam_range") table tcam_range {
        actions = {
            nop;
            hop_ipv4;
        }
        key = {
            hdr.ipv4.dstAddr: ternary;
            hdr.tcp.dstPort : range;
        }
        size = 1024;
    }
    @stage(6) @entries_with_ranges(1) @name(".tcam_range_2_fields") table tcam_range_2_fields {
        actions = {
            nop;
            hop_ipv4;
        }
        key = {
            hdr.ipv4.dstAddr: ternary;
            hdr.tcp.dstPort : range;
            hdr.tcp.srcPort : range;
        }
        size = 1024;
    }
    @stage(5) @name(".tcam_range_ternary_valid") table tcam_range_ternary_valid {
        actions = {
            nop;
            hop_ipv4;
        }
        key = {
            hdr.tcp.isValid(): ternary;
            hdr.ipv4.dstAddr : ternary;
            meta.md.dport    : range;
        }
        size = 1024;
    }
    @stage(2) @name(".tcam_tbl_stage_2") table tcam_tbl_stage_2 {
        actions = {
            nop;
            mod_mac_adr;
        }
        key = {
            hdr.ipv4.dstAddr: lpm;
        }
    }
    @immediate(1) @stage(4) @name(".tcp_rm_tbl_stage_4") table tcp_rm_tbl_stage_4 {
        actions = {
            nop;
            tcp_hdr_rm;
        }
        key = {
            hdr.ethernet.srcAddr: ternary;
        }
    }
    @immediate(1) @stage(3) @name(".udp_add_tbl_stage_3") table udp_add_tbl_stage_3 {
        actions = {
            nop;
            udp_hdr_add;
        }
        key = {
            hdr.ethernet.srcAddr: ternary;
        }
    }
    apply {
        ig_udp.apply();
        ig_udp_ternary_valid.apply();
        ipv4_routing.apply();
        ipv4_routing_exm_ways_3_pack_5.apply();
        ipv4_routing_exm_ways_3_pack_3.apply();
        ipv4_routing_exm_ways_4_pack_3_stage_1.apply();
        ipv4_routing_stage_1.apply();
        tcam_tbl_stage_2.apply();
        ipv4_routing_exm_ways_4_pack_7_stage_2.apply();
        ipv4_routing_exm_ways_5_pack_3_stage_3.apply();
        udp_add_tbl_stage_3.apply();
        ipv4_routing_exm_ways_6_pack_3_stage_4.apply();
        tcp_rm_tbl_stage_4.apply();
        ipv4_routing_exm_ways_3_pack_4_stage_5.apply();
        tcam_range.apply();
        tcam_range_ternary_valid.apply();
        ipv4_routing_exm_ways_4_pack_4_stage_6.apply();
        tcam_range_2_fields.apply();
        ipv4_routing_exm_ways_5_pack_4_stage_7.apply();
        src_non_overlap_range_table.apply();
        dest_non_overlap_range_table.apply();
        tcam_adt_deep_stage_8.apply();
        ipv4_routing_exm_ways_4_pack_5_stage_8.apply();
        ipv4_routing_select.apply();
        tcam_indirect_action.apply();
        no_key_1.apply();
        match_range_table.apply();
        no_key_2.apply();
    }
}

control DeparserImpl(packet_out packet, in headers hdr) {
    apply {
        packet.emit(hdr.ethernet);
        packet.emit(hdr.vlan_tag);
        packet.emit(hdr.ipv4);
        packet.emit(hdr.udp);
        packet.emit(hdr.tcp);
    }
}

control verifyChecksum(inout headers hdr, inout metadata meta) {
    apply {
    }
}

control computeChecksum(inout headers hdr, inout metadata meta) {
    apply {
        update_checksum(true, { hdr.ipv4.version, hdr.ipv4.ihl, hdr.ipv4.diffserv, hdr.ipv4.totalLen, hdr.ipv4.identification, hdr.ipv4.flags, hdr.ipv4.fragOffset, hdr.ipv4.ttl, hdr.ipv4.protocol, hdr.ipv4.srcAddr, hdr.ipv4.dstAddr }, hdr.ipv4.hdrChecksum, HashAlgorithm.csum16);
    }
}

V1Switch(ParserImpl(), verifyChecksum(), ingress(), egress(), computeChecksum(), DeparserImpl()) main;

