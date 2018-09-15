#include <core.p4>
#include <v1model.p4>

struct mirror_meta_t {
    bit<1>  mirror_type;
    bit<10> mirror_dest;
    bit<9>  ingress_port;
}

header ethernet_t {
    bit<48> dstAddr;
    bit<48> srcAddr;
    bit<16> etherType;
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

header to_cpu_t {
    bit<16> mirror_type;
    bit<16> ingress_port;
    bit<16> pkt_length;
}

header vlan_tag_t {
    bit<3>  pcp;
    bit<1>  cfi;
    bit<12> vid;
    bit<16> etherType;
}

struct metadata {
    @name(".mirror_meta") 
    mirror_meta_t mirror_meta;
}

struct headers {
    @name(".cpu_ethernet") 
    ethernet_t                                     cpu_ethernet;
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
    @name(".to_cpu") 
    to_cpu_t                                       to_cpu;
    @name(".vlan_tag") 
    vlan_tag_t[2]                                  vlan_tag;
}

parser ParserImpl(packet_in packet, out headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    bit<112> tmp_1;
    @name(".parse_cpu_ethernet") state parse_cpu_ethernet {
        packet.extract<ethernet_t>(hdr.cpu_ethernet);
        transition select(hdr.cpu_ethernet.etherType) {
            16w0xbf01: parse_to_cpu;
            default: accept;
        }
    }
    @name(".parse_ethernet") state parse_ethernet {
        packet.extract<ethernet_t>(hdr.ethernet);
        transition select(hdr.ethernet.etherType) {
            16w0x8100: parse_vlan_tag;
            16w0x800: parse_ipv4;
            default: accept;
        }
    }
    @name(".parse_ipv4") state parse_ipv4 {
        packet.extract<ipv4_t>(hdr.ipv4);
        transition accept;
    }
    @name(".parse_to_cpu") state parse_to_cpu {
        packet.extract<to_cpu_t>(hdr.to_cpu);
        transition parse_ethernet;
    }
    @name(".parse_vlan_tag") state parse_vlan_tag {
        packet.extract<vlan_tag_t>(hdr.vlan_tag.next);
        transition select(hdr.vlan_tag.last.etherType) {
            16w0x8100: parse_vlan_tag;
            16w0x800: parse_ipv4;
            default: accept;
        }
    }
    @name(".start") state start {
        tmp_1 = packet.lookahead<bit<112>>();
        transition select(tmp_1[15:0]) {
            16w0xbf01: parse_cpu_ethernet;
            default: parse_ethernet;
        }
    }
}

control egress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".NoAction") action NoAction_0() {
    }
    @name(".send_ether") action send_ether_0() {
    }
    @name(".send_to_cpu") action send_to_cpu_0() {
        hdr.cpu_ethernet.setValid();
        hdr.cpu_ethernet.dstAddr = 48w0xffffffffffff;
        hdr.cpu_ethernet.srcAddr = 48w0xaaaaaaaaaaaa;
        hdr.cpu_ethernet.etherType = 16w0xbf01;
        hdr.to_cpu.setValid();
        hdr.to_cpu.mirror_type = (bit<16>)meta.mirror_meta.mirror_type;
        hdr.to_cpu.ingress_port = (bit<16>)meta.mirror_meta.ingress_port;
        hdr.to_cpu.pkt_length = hdr.eg_intr_md.pkt_length;
    }
    @name(".send_rspan") action send_rspan_0(bit<3> pcp, bit<1> cfi, bit<12> vid) {
        hdr.vlan_tag.push_front(1);
        hdr.vlan_tag[0].setValid();
        hdr.vlan_tag[0].setValid();
        hdr.vlan_tag[0].pcp = pcp;
        hdr.vlan_tag[0].cfi = cfi;
        hdr.vlan_tag[0].vid = vid;
        hdr.vlan_tag[0].etherType = hdr.ethernet.etherType;
        hdr.ethernet.etherType = 16w0x8100;
    }
    @name(".mirror_dest") table mirror_dest_1 {
        actions = {
            send_ether_0();
            send_to_cpu_0();
            send_rspan_0();
            @defaultonly NoAction_0();
        }
        key = {
            meta.mirror_meta.mirror_dest: exact @name("mirror_meta.mirror_dest") ;
        }
        default_action = NoAction_0();
    }
    apply {
        if (hdr.eg_intr_md_from_parser_aux.clone_src != 4w0) 
            mirror_dest_1.apply();
    }
}

control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".NoAction") action NoAction_1() {
    }
    @name(".NoAction") action NoAction_6() {
    }
    @name(".NoAction") action NoAction_7() {
    }
    bool tmp_2;
    @name(".ipv4_host_stats") direct_counter(CounterType.packets_and_bytes) ipv4_host_stats;
    @name(".acl_drop") action acl_drop_0() {
        mark_to_drop();
    }
    @name(".acl_mirror") action acl_mirror_0(bit<32> mirror_dest) {
        meta.mirror_meta.mirror_type = 1w0;
        meta.mirror_meta.ingress_port = hdr.ig_intr_md.ingress_port;
        meta.mirror_meta.mirror_dest = (bit<10>)mirror_dest;
        clone3<tuple<bit<9>, bit<10>, bit<1>>>(CloneType.I2E, mirror_dest, { meta.mirror_meta.ingress_port, meta.mirror_meta.mirror_dest, meta.mirror_meta.mirror_type });
    }
    @name(".acl_drop_and_mirror") action acl_drop_and_mirror_0(bit<32> mirror_dest) {
        mark_to_drop();
        meta.mirror_meta.mirror_type = 1w0;
        meta.mirror_meta.ingress_port = hdr.ig_intr_md.ingress_port;
        meta.mirror_meta.mirror_dest = (bit<10>)mirror_dest;
        clone3<tuple<bit<9>, bit<10>, bit<1>>>(CloneType.I2E, mirror_dest, { meta.mirror_meta.ingress_port, meta.mirror_meta.mirror_dest, meta.mirror_meta.mirror_type });
    }
    @name(".send") action send_1(bit<9> port) {
        hdr.ig_intr_md_for_tm.ucast_egress_port = port;
    }
    @name(".discard") action discard_1() {
        hdr.ig_intr_md_for_tm.drop_ctl = 3w1;
    }
    @name(".ing_acl") table ing_acl {
        actions = {
            acl_drop_0();
            acl_mirror_0();
            acl_drop_and_mirror_0();
            @defaultonly NoAction_1();
        }
        key = {
            hdr.ig_intr_md.ingress_port: ternary @name("ig_intr_md.ingress_port") ;
            hdr.ethernet.srcAddr       : ternary @name("ethernet.srcAddr") ;
            hdr.ethernet.dstAddr       : ternary @name("ethernet.dstAddr") ;
            hdr.vlan_tag[0].isValid()  : ternary @name("vlan_tag[0].$valid$") ;
            hdr.vlan_tag[0].vid        : ternary @name("vlan_tag[0].vid") ;
            hdr.ipv4.isValid()         : ternary @name("ipv4.$valid$") ;
            hdr.ipv4.srcAddr           : ternary @name("ipv4.srcAddr") ;
            hdr.ipv4.dstAddr           : ternary @name("ipv4.dstAddr") ;
        }
        size = 512;
        default_action = NoAction_1();
    }
    @name(".send") action send_2(bit<9> port) {
        ipv4_host_stats.count();
        hdr.ig_intr_md_for_tm.ucast_egress_port = port;
    }
    @name(".discard") action discard_2() {
        ipv4_host_stats.count();
        hdr.ig_intr_md_for_tm.drop_ctl = 3w1;
    }
    @name(".ipv4_host") table ipv4_host {
        actions = {
            send_2();
            discard_2();
            @defaultonly NoAction_6();
        }
        key = {
            hdr.ipv4.dstAddr: exact @name("ipv4.dstAddr") ;
        }
        size = 32768;
        counters = ipv4_host_stats;
        default_action = NoAction_6();
    }
    @name(".ipv4_lpm") table ipv4_lpm {
        actions = {
            send_1();
            discard_1();
            @defaultonly NoAction_7();
        }
        key = {
            hdr.ipv4.dstAddr: lpm @name("ipv4.dstAddr") ;
        }
        size = 8192;
        default_action = NoAction_7();
    }
    apply {
        if (hdr.ipv4.isValid()) {
            tmp_2 = ipv4_host.apply().hit;
            if (tmp_2) 
                ;
            else 
                ipv4_lpm.apply();
        }
        ing_acl.apply();
    }
}

control DeparserImpl(packet_out packet, in headers hdr) {
    apply {
        packet.emit<ethernet_t>(hdr.cpu_ethernet);
        packet.emit<to_cpu_t>(hdr.to_cpu);
        packet.emit<ethernet_t>(hdr.ethernet);
        packet.emit<vlan_tag_t[2]>(hdr.vlan_tag);
        packet.emit<ipv4_t>(hdr.ipv4);
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

