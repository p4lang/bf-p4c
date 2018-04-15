#include <core.p4>
#include <v1model.p4>

header ipv6_srh_segment_t {
    bit<128> sid;
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

header ipv4_option_EOL_t {
    bit<8> value;
}

header ipv4_option_NOP_t {
    bit<8> value;
}

header ipv4_option_addr_ext_t {
    bit<8>  value;
    bit<8>  len;
    bit<32> src_ext;
    bit<32> dst_ext;
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

header ipv6_srh_t {
    bit<8>  nextHdr;
    bit<8>  hdrExtLen;
    bit<8>  routingType;
    bit<8>  segLeft;
    bit<8>  firstSeg;
    bit<16> flags;
    bit<8>  reserved;
}

struct metadata {
}

struct headers {
    @name(".active_segment") 
    ipv6_srh_segment_t                             active_segment;
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
    @header_ordering("ipv4_option_addr_ext", "ipv4_option_NOP", "ipv4_option_EOL") @name(".ipv4_option_EOL") 
    ipv4_option_EOL_t                              ipv4_option_EOL;
    @name(".ipv4_option_NOP") 
    ipv4_option_NOP_t                              ipv4_option_NOP;
    @name(".ipv4_option_addr_ext") 
    ipv4_option_addr_ext_t                         ipv4_option_addr_ext;
    @name(".ipv6") 
    ipv6_t                                         ipv6;
    @name(".ipv6_srh") 
    ipv6_srh_t                                     ipv6_srh;
    @name(".ipv6_srh_seg_list") 
    ipv6_srh_segment_t[9]                          ipv6_srh_seg_list;
}

parser ParserImpl(packet_in packet, out headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    bit<8> tmp_0;
    @name(".parse_ethernet") state parse_ethernet {
        packet.extract<ethernet_t>(hdr.ethernet);
        transition select(hdr.ethernet.etherType) {
            16w0x800: parse_ipv4;
            16w0x86dd: parse_ipv6;
            default: noMatch;
        }
    }
    @name(".parse_ipv4") state parse_ipv4 {
        packet.extract<ipv4_t>(hdr.ipv4);
        hdr.ig_prsr_ctrl.parser_counter = (bit<8>)((hdr.ipv4.ihl << 2) + 4w11);
        transition select(hdr.ipv4.ihl) {
            4w0x5: accept;
            default: parse_ipv4_options;
        }
    }
    @name(".parse_ipv4_option_addr_ext") state parse_ipv4_option_addr_ext {
        packet.extract<ipv4_option_addr_ext_t>(hdr.ipv4_option_addr_ext);
        hdr.ig_prsr_ctrl.parser_counter = hdr.ig_prsr_ctrl.parser_counter + 8w246;
        transition parse_ipv4_options;
    }
    @name(".parse_ipv4_option_eol") state parse_ipv4_option_eol {
        packet.extract<ipv4_option_EOL_t>(hdr.ipv4_option_EOL);
        hdr.ig_prsr_ctrl.parser_counter = hdr.ig_prsr_ctrl.parser_counter + 8w255;
        transition parse_ipv4_options;
    }
    @name(".parse_ipv4_option_nop") state parse_ipv4_option_nop {
        packet.extract<ipv4_option_NOP_t>(hdr.ipv4_option_NOP);
        hdr.ig_prsr_ctrl.parser_counter = hdr.ig_prsr_ctrl.parser_counter + 8w255;
        transition parse_ipv4_options;
    }
    @name(".parse_ipv4_options") state parse_ipv4_options {
        tmp_0 = packet.lookahead<bit<8>>();
        transition select(hdr.ig_prsr_ctrl.parser_counter, tmp_0[7:0]) {
            (8w0x0 &&& 8w0xff, 8w0x0 &&& 8w0x0): accept;
            (8w0x0 &&& 8w0x0, 8w0x0 &&& 8w0xff): parse_ipv4_option_eol;
            (8w0x0 &&& 8w0x0, 8w0x1 &&& 8w0xff): parse_ipv4_option_nop;
            (8w0x0 &&& 8w0x0, 8w0x93 &&& 8w0xff): parse_ipv4_option_addr_ext;
            default: noMatch;
        }
    }
    @name(".parse_ipv6") state parse_ipv6 {
        packet.extract<ipv6_t>(hdr.ipv6);
        transition select(hdr.ipv6.nextHdr) {
            8w43: parse_ipv6_srh;
            default: noMatch;
        }
    }
    @name(".parse_ipv6_srh") state parse_ipv6_srh {
        packet.extract<ipv6_srh_t>(hdr.ipv6_srh);
        hdr.ig_prsr_ctrl.parser_counter = hdr.ipv6_srh.segLeft;
        transition parse_ipv6_srh_seg_list;
    }
    @name(".parse_ipv6_srh_active_segment") state parse_ipv6_srh_active_segment {
        packet.extract<ipv6_srh_segment_t>(hdr.active_segment);
        transition accept;
    }
    @name(".parse_ipv6_srh_seg_list") state parse_ipv6_srh_seg_list {
        transition select(hdr.ig_prsr_ctrl.parser_counter) {
            8w0x0: parse_ipv6_srh_active_segment;
            default: parse_ipv6_srh_segment;
        }
    }
    @name(".parse_ipv6_srh_segment") state parse_ipv6_srh_segment {
        packet.extract<ipv6_srh_segment_t>(hdr.ipv6_srh_seg_list.next);
        hdr.ig_prsr_ctrl.parser_counter = hdr.ig_prsr_ctrl.parser_counter + 8w255;
        transition parse_ipv6_srh_seg_list;
    }
    @name(".start") state start {
        transition parse_ethernet;
    }
    state noMatch {
        verify(false, error.NoMatch);
        transition reject;
    }
}

control egress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".NoAction") action NoAction_0() {
    }
    @name(".NoAction") action NoAction_3() {
    }
    @name(".set_egress_port") action set_egress_port_0(bit<9> egress_port) {
        hdr.ig_intr_md_for_tm.ucast_egress_port = egress_port;
    }
    @name(".rewrite_ipv6_and_set_egress_port") action rewrite_ipv6_and_set_egress_port_0(bit<9> egress_port) {
        hdr.ipv6.dstAddr = hdr.active_segment.sid;
        hdr.ig_intr_md_for_tm.ucast_egress_port = egress_port;
    }
    @name(".ipv4_option_lookup") table ipv4_option_lookup {
        actions = {
            set_egress_port_0();
            @defaultonly NoAction_0();
        }
        key = {
            hdr.ipv4_option_NOP.isValid()     : exact @name("ipv4_option_NOP.$valid$") ;
            hdr.ipv4_option_EOL.isValid()     : exact @name("ipv4_option_EOL.$valid$") ;
            hdr.ipv4_option_addr_ext.isValid(): exact @name("ipv4_option_addr_ext.$valid$") ;
        }
        default_action = NoAction_0();
    }
    @name(".sr_lookup") table sr_lookup {
        actions = {
            rewrite_ipv6_and_set_egress_port_0();
            @defaultonly NoAction_3();
        }
        default_action = NoAction_3();
    }
    apply {
        if (hdr.ipv6_srh.isValid()) 
            sr_lookup.apply();
        if (hdr.ipv4.isValid()) 
            ipv4_option_lookup.apply();
    }
}

control DeparserImpl(packet_out packet, in headers hdr) {
    apply {
        packet.emit<ethernet_t>(hdr.ethernet);
        packet.emit<ipv6_t>(hdr.ipv6);
        packet.emit<ipv6_srh_t>(hdr.ipv6_srh);
        packet.emit<ipv6_srh_segment_t>(hdr.ipv6_srh_seg_list[0]);
        packet.emit<ipv6_srh_segment_t>(hdr.ipv6_srh_seg_list[1]);
        packet.emit<ipv6_srh_segment_t>(hdr.ipv6_srh_seg_list[2]);
        packet.emit<ipv6_srh_segment_t>(hdr.ipv6_srh_seg_list[3]);
        packet.emit<ipv6_srh_segment_t>(hdr.ipv6_srh_seg_list[4]);
        packet.emit<ipv6_srh_segment_t>(hdr.ipv6_srh_seg_list[5]);
        packet.emit<ipv6_srh_segment_t>(hdr.ipv6_srh_seg_list[6]);
        packet.emit<ipv6_srh_segment_t>(hdr.ipv6_srh_seg_list[7]);
        packet.emit<ipv6_srh_segment_t>(hdr.ipv6_srh_seg_list[8]);
        packet.emit<ipv6_srh_segment_t>(hdr.active_segment);
        packet.emit<ipv4_t>(hdr.ipv4);
        packet.emit<ipv4_option_EOL_t>(hdr.ipv4_option_EOL);
        packet.emit<ipv4_option_NOP_t>(hdr.ipv4_option_NOP);
        packet.emit<ipv4_option_addr_ext_t>(hdr.ipv4_option_addr_ext);
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

