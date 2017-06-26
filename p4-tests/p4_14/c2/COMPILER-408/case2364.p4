/*
gcc -E -x c -w -I/tmp/_MEIyzptcq/p4_lib -D__TARGET_TOFINO__ -I/tmp/_MEIyzptcq/p4_hlir/p4_lib /media/psf/Home/trees/bfn/p4examples/cases/002364/p4src/balancer.p4
*/
# 1 "/media/psf/Home/trees/bfn/p4examples/cases/002364/p4src/balancer.p4"
# 1 "<built-in>"
# 1 "<command-line>"
# 1 "/usr/include/stdc-predef.h" 1 3 4
# 1 "<command-line>" 2
# 1 "/media/psf/Home/trees/bfn/p4examples/cases/002364/p4src/balancer.p4"



# 1 "/tmp/_MEIyzptcq/p4_lib/tofino/constants.p4" 1
# 5 "/media/psf/Home/trees/bfn/p4examples/cases/002364/p4src/balancer.p4" 2
# 1 "/tmp/_MEIyzptcq/p4_lib/tofino/intrinsic_metadata.p4" 1
# 10 "/tmp/_MEIyzptcq/p4_lib/tofino/intrinsic_metadata.p4"
header_type ingress_parser_control_signals {
    fields {
        priority : 3;
        _pad1 : 5;
        parser_counter : 8;
    }
}

@pragma not_deparsed ingress
@pragma not_deparsed egress
@pragma pa_intrinsic_header ingress ig_prsr_ctrl
header ingress_parser_control_signals ig_prsr_ctrl;



header_type ingress_intrinsic_metadata_t {
    fields {

        resubmit_flag : 1;


        _pad1 : 1;

        _pad2 : 2;

        _pad3 : 3;

        ingress_port : 9;


        ingress_mac_tstamp : 48;

    }
}

@pragma dont_trim
@pragma not_deparsed ingress
@pragma not_deparsed egress
@pragma pa_intrinsic_header ingress ig_intr_md
@pragma pa_mandatory_intrinsic_field ingress ig_intr_md.ingress_port
header ingress_intrinsic_metadata_t ig_intr_md;



header_type generator_metadata_t {
    fields {

        app_id : 16;

        batch_id: 16;

        instance_id: 16;
    }
}

@pragma not_deparsed ingress
@pragma not_deparsed egress
header generator_metadata_t ig_pg_md;



header_type ingress_intrinsic_metadata_from_parser_aux_t {
    fields {
        ingress_global_tstamp : 48;


        ingress_global_ver : 32;


        ingress_parser_err : 16;

    }
}

@pragma pa_fragment ingress ig_intr_md_from_parser_aux.ingress_parser_err
@pragma pa_atomic ingress ig_intr_md_from_parser_aux.ingress_parser_err
@pragma not_deparsed ingress
@pragma not_deparsed egress
@pragma pa_intrinsic_header ingress ig_intr_md_from_parser_aux
header ingress_intrinsic_metadata_from_parser_aux_t ig_intr_md_from_parser_aux;



header_type ingress_intrinsic_metadata_for_tm_t {
    fields {




        _pad1 : 7;
        ucast_egress_port : 9;




        drop_ctl : 3;




        bypass_egress : 1;

        deflect_on_drop : 1;



        ingress_cos : 3;





        qid : 5;

        icos_for_copy_to_cpu : 3;





        _pad2: 3;

        copy_to_cpu : 1;

        packet_color : 2;



        disable_ucast_cutthru : 1;

        enable_mcast_cutthru : 1;




        mcast_grp_a : 16;





        mcast_grp_b : 16;




        _pad3 : 3;
        level1_mcast_hash : 13;







        _pad4 : 3;
        level2_mcast_hash : 13;







        level1_exclusion_id : 16;





        _pad5 : 7;
        level2_exclusion_id : 9;





        rid : 16;



    }
}

@pragma pa_atomic ingress ig_intr_md_for_tm.ucast_egress_port

@pragma pa_fragment ingress ig_intr_md_for_tm.drop_ctl
@pragma pa_fragment ingress ig_intr_md_for_tm.qid
@pragma pa_fragment ingress ig_intr_md_for_tm._pad2

@pragma pa_atomic ingress ig_intr_md_for_tm.mcast_grp_a
@pragma pa_fragment ingress ig_intr_md_for_tm.mcast_grp_a
@pragma pa_mandatory_intrinsic_field ingress ig_intr_md_for_tm.mcast_grp_a

@pragma pa_atomic ingress ig_intr_md_for_tm.mcast_grp_b
@pragma pa_fragment ingress ig_intr_md_for_tm.mcast_grp_b
@pragma pa_mandatory_intrinsic_field ingress ig_intr_md_for_tm.mcast_grp_b

@pragma pa_atomic ingress ig_intr_md_for_tm.level1_mcast_hash
@pragma pa_fragment ingress ig_intr_md_for_tm._pad3

@pragma pa_atomic ingress ig_intr_md_for_tm.level2_mcast_hash
@pragma pa_fragment ingress ig_intr_md_for_tm._pad4

@pragma pa_atomic ingress ig_intr_md_for_tm.level1_exclusion_id
@pragma pa_fragment ingress ig_intr_md_for_tm.level1_exclusion_id

@pragma pa_atomic ingress ig_intr_md_for_tm.level2_exclusion_id
@pragma pa_fragment ingress ig_intr_md_for_tm._pad5

@pragma pa_atomic ingress ig_intr_md_for_tm.rid
@pragma pa_fragment ingress ig_intr_md_for_tm.rid

@pragma not_deparsed ingress
@pragma not_deparsed egress
@pragma pa_intrinsic_header ingress ig_intr_md_for_tm
@pragma dont_trim
@pragma pa_mandatory_intrinsic_field ingress ig_intr_md_for_tm.drop_ctl
header ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm;


header_type ingress_intrinsic_metadata_for_mirror_buffer_t {
    fields {
        _pad1 : 6;
        ingress_mirror_id : 10;


    }
}

@pragma dont_trim
@pragma pa_intrinsic_header ingress ig_intr_md_for_mb
@pragma pa_atomic ingress ig_intr_md_for_mb.ingress_mirror_id
@pragma pa_mandatory_intrinsic_field ingress ig_intr_md_for_mb.ingress_mirror_id
@pragma not_deparsed ingress
@pragma not_deparsed egress
header ingress_intrinsic_metadata_for_mirror_buffer_t ig_intr_md_for_mb;


header_type egress_intrinsic_metadata_t {
    fields {

        _pad0 : 7;
        egress_port : 9;


        _pad1: 5;
        enq_qdepth : 19;


        _pad2: 6;
        enq_congest_stat : 2;


        enq_tstamp : 32;


        _pad3: 5;
        deq_qdepth : 19;


        _pad4: 6;
        deq_congest_stat : 2;


        app_pool_congest_stat : 8;



        deq_timedelta : 32;


        egress_rid : 16;


        _pad5: 7;
        egress_rid_first : 1;


        _pad6: 3;
        egress_qid : 5;


        _pad7: 5;
        egress_cos : 3;


        _pad8: 7;
        deflection_flag : 1;


        pkt_length : 16;
    }
}

@pragma dont_trim
@pragma not_deparsed ingress
@pragma not_deparsed egress
@pragma pa_intrinsic_header egress eg_intr_md

@pragma pa_atomic egress eg_intr_md.egress_port
@pragma pa_fragment egress eg_intr_md._pad1
@pragma pa_fragment egress eg_intr_md._pad7
@pragma pa_fragment egress eg_intr_md._pad8
@pragma pa_mandatory_intrinsic_field egress eg_intr_md.egress_port
@pragma pa_mandatory_intrinsic_field egress eg_intr_md.egress_cos

header egress_intrinsic_metadata_t eg_intr_md;


header_type egress_intrinsic_metadata_from_parser_aux_t {
    fields {
        egress_global_tstamp : 48;


        egress_global_ver : 32;


        egress_parser_err : 16;



        clone_src : 8;



        coalesce_sample_count : 8;


    }
}

@pragma pa_fragment egress eg_intr_md_from_parser_aux.coalesce_sample_count
@pragma pa_fragment egress eg_intr_md_from_parser_aux.clone_src
@pragma pa_fragment egress eg_intr_md_from_parser_aux.egress_parser_err
@pragma pa_atomic egress eg_intr_md_from_parser_aux.egress_parser_err
@pragma not_deparsed ingress
@pragma not_deparsed egress
@pragma pa_intrinsic_header egress eg_intr_md_from_parser_aux
header egress_intrinsic_metadata_from_parser_aux_t eg_intr_md_from_parser_aux;
# 379 "/tmp/_MEIyzptcq/p4_lib/tofino/intrinsic_metadata.p4"
header_type egress_intrinsic_metadata_for_mirror_buffer_t {
    fields {
        _pad1 : 6;
        egress_mirror_id : 10;


        coalesce_flush: 1;
        coalesce_length: 7;


    }
}

@pragma dont_trim
@pragma pa_intrinsic_header egress eg_intr_md_for_mb
@pragma pa_atomic egress eg_intr_md_for_mb.egress_mirror_id
@pragma pa_fragment egress eg_intr_md_for_mb.coalesce_flush
@pragma pa_mandatory_intrinsic_field egress eg_intr_md_for_mb.egress_mirror_id
@pragma pa_mandatory_intrinsic_field egress eg_intr_md_for_mb.coalesce_flush
@pragma pa_mandatory_intrinsic_field egress eg_intr_md_for_mb.coalesce_length
@pragma not_deparsed ingress
@pragma not_deparsed egress
header egress_intrinsic_metadata_for_mirror_buffer_t eg_intr_md_for_mb;



header_type egress_intrinsic_metadata_for_output_port_t {
    fields {

        _pad1 : 2;
        capture_tstamp_on_tx : 1;


        update_delay_on_tx : 1;
# 422 "/tmp/_MEIyzptcq/p4_lib/tofino/intrinsic_metadata.p4"
        force_tx_error : 1;

        drop_ctl : 3;







    }
}

@pragma dont_trim
@pragma pa_mandatory_intrinsic_field egress eg_intr_md_for_oport.drop_ctl
@pragma not_deparsed ingress
@pragma not_deparsed egress
@pragma pa_intrinsic_header egress eg_intr_md_for_oport
header egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport;
# 6 "/media/psf/Home/trees/bfn/p4examples/cases/002364/p4src/balancer.p4" 2
# 1 "/tmp/_MEIyzptcq/p4_lib/tofino/primitives.p4" 1
# 10 "/tmp/_MEIyzptcq/p4_lib/tofino/primitives.p4"
action deflect_on_drop(enable_dod) {
    modify_field(ig_intr_md_for_tm.deflect_on_drop, enable_dod);
}
# 7 "/media/psf/Home/trees/bfn/p4examples/cases/002364/p4src/balancer.p4" 2
# 1 "/tmp/_MEIyzptcq/p4_lib/tofino/pktgen_headers.p4" 1
# 9 "/tmp/_MEIyzptcq/p4_lib/tofino/pktgen_headers.p4"
header_type pktgen_generic_header_t {
    fields {
        _pad0 : 3;
        pipe_id : 2;
        app_id : 3;
        key_msb : 8;
        batch_id : 16;

        packet_id : 16;
    }
}
header pktgen_generic_header_t pktgen_generic;

header_type pktgen_timer_header_t {
    fields {
        _pad0 : 3;
        pipe_id : 2;
        app_id : 3;
        _pad1 : 8;
        batch_id : 16;
        packet_id : 16;
    }
}
header pktgen_timer_header_t pktgen_timer;

header_type pktgen_port_down_header_t {
    fields {
        _pad0 : 3;
        pipe_id : 2;
        app_id : 3;
        _pad1 : 15;
        port_num : 9;
        packet_id : 16;
    }
}
header pktgen_port_down_header_t pktgen_port_down;

header_type pktgen_recirc_header_t {
    fields {
        _pad0 : 3;
        pipe_id : 2;
        app_id : 3;
        key : 24;
        packet_id : 16;
    }
}
header pktgen_recirc_header_t pktgen_recirc;
# 8 "/media/psf/Home/trees/bfn/p4examples/cases/002364/p4src/balancer.p4" 2
# 1 "/tmp/_MEIyzptcq/p4_lib/tofino/stateful_alu_blackbox.p4" 1


blackbox_type stateful_alu {

    attribute reg {

        type: register;
    }

    attribute selector_binding {

        type: table;
        optional;
    }

    attribute initial_register_lo_value {



        type: int;
        optional;
    }

    attribute initial_register_hi_value {



        type: int;
        optional;
    }

    attribute condition_hi {




        type: expression;
        expression_local_variables {register_lo, register_hi}
        optional;
    }

    attribute condition_lo {




        type: expression;
        expression_local_variables {register_lo, register_hi}
        optional;
    }


    attribute update_lo_1_predicate {

        type: expression;
        expression_local_variables {condition_lo, condition_hi}
        optional;
    }

    attribute update_lo_1_value {
# 81 "/tmp/_MEIyzptcq/p4_lib/tofino/stateful_alu_blackbox.p4"
        type: expression;
        expression_local_variables {register_lo, register_hi,
                                    set_bit, set_bitc, clr_bit, clr_bitc, read_bit, read_bitc}
        optional;
    }

    attribute update_lo_2_predicate {

        type: expression;
        expression_local_variables {condition_lo, condition_hi}
        optional;
    }

    attribute update_lo_2_value {

        type: expression;
        expression_local_variables {register_lo, register_hi, math_unit}
        optional;
    }

    attribute update_hi_1_predicate {

        type: expression;
        expression_local_variables {condition_lo, condition_hi}
        optional;
    }

    attribute update_hi_1_value {

        type: expression;
        expression_local_variables {register_lo, register_hi}
        optional;
    }

    attribute update_hi_2_predicate {

        type: expression;
        expression_local_variables {condition_lo, condition_hi}
        optional;
    }

    attribute update_hi_2_value {

        type: expression;
        expression_local_variables {register_lo, register_hi}
        optional;
    }

    attribute output_predicate {




        type: expression;
        expression_local_variables {condition_lo, condition_hi}
        optional;
    }

    attribute output_value {







        type: expression;
        expression_local_variables {alu_lo, alu_hi, register_lo, register_hi, predicate, combined_predicate}
        optional;
    }

    attribute output_dst {

        type: bit<0>;
        optional;
    }

    attribute math_unit_input {



        type: expression;
        expression_local_variables {register_lo, register_hi}
        optional;
    }
    attribute math_unit_output_scale {




        type: int;
        optional;
    }
    attribute math_unit_exponent_shift {






        type: int;
        optional;
    }
    attribute math_unit_exponent_invert {




        type: string;
        optional;
    }

    attribute math_unit_lookup_table {







        type: string;
        optional;
    }

    attribute reduction_or_group {
# 214 "/tmp/_MEIyzptcq/p4_lib/tofino/stateful_alu_blackbox.p4"
        type: string;
        optional;
    }

    attribute stateful_logging_mode {
# 228 "/tmp/_MEIyzptcq/p4_lib/tofino/stateful_alu_blackbox.p4"
        type: string;
        optional;
    }
# 246 "/tmp/_MEIyzptcq/p4_lib/tofino/stateful_alu_blackbox.p4"
    method execute_stateful_alu(optional in bit<0> index){
        reads {condition_hi, condition_lo,
               update_lo_1_predicate, update_lo_1_value,
               update_lo_2_predicate, update_lo_2_value,
               update_hi_1_predicate, update_hi_1_value,
               update_hi_2_predicate, update_hi_2_value,
               math_unit_input}
        writes {output_dst}
    }

    method execute_stateful_alu_from_hash(in field_list_calculation hash_field_list){
        reads {condition_hi, condition_lo,
               update_lo_1_predicate, update_lo_1_value,
               update_lo_2_predicate, update_lo_2_value,
               update_hi_1_predicate, update_hi_1_value,
               update_hi_2_predicate, update_hi_2_value,
               math_unit_input}
        writes {output_dst}
    }

    method execute_stateful_log(){
        reads {condition_hi, condition_lo,
               update_lo_1_predicate, update_lo_1_value,
               update_lo_2_predicate, update_lo_2_value,
               update_hi_1_predicate, update_hi_1_value,
               update_hi_2_predicate, update_hi_2_value,
               math_unit_input}
    }
}
# 9 "/media/psf/Home/trees/bfn/p4examples/cases/002364/p4src/balancer.p4" 2


# 1 "/media/psf/Home/trees/bfn/p4examples/cases/002364/p4src/defines.p4" 1
# 12 "/media/psf/Home/trees/bfn/p4examples/cases/002364/p4src/balancer.p4" 2
# 1 "/media/psf/Home/trees/bfn/p4examples/cases/002364/p4src/headers.p4" 1
# 26 "/media/psf/Home/trees/bfn/p4examples/cases/002364/p4src/headers.p4"
header_type ebmeta_t {
 fields {
  _pad1 : 7;
  lanwan_out_port : 9;
  _pad2 : 7;
  dpi_port : 9;
  _pad3 : 7;
  dst_mirror_out : 9;
  _pad4 : 14;
  is_nat : 1;
  is_lan : 1;
  offset_ip1 : 8;
  offset_ip2 : 8;
  offset_mpls : 8;
  offset_payload : 8;
  rss_queue : 8;
  hash1 : 32;
  hash2 : 32;
  port_type : 3;
  _pad5 : 2;
  flow_proto : 3;
  flow_srcPort : 16;
  flow_dstPort : 16;
  port_hash : 16;
 }
}


header_type ecolog_t {
 fields {
  unused : 96;
  etherType : 16;
 }
}

header_type ethernet_t {
 fields {
  dstAddr : 48;
  srcAddr : 48;
  etherType : 16;
 }
}
# 92 "/media/psf/Home/trees/bfn/p4examples/cases/002364/p4src/headers.p4"
header_type ebheader_t {
 fields {
  _pad1 : 7;
  dst_main_out : 9;
  _pad2 : 7;
  dst_main_agg : 9;
  _pad3 : 7;
  dst_mirror_out : 9;
  unused : 8;
  flags_unused_bits : 6;
  is_nat : 1;
  is_lan : 1;
  offset_ip1 : 8;
  offset_ip2 : 8;
  offset_mpls : 8;
  offset_payload : 8;
  ethertype_eb : 8;
  rss_queue : 8;
  hash1 : 32;
  hash2 : 32;
 }
}


header_type slow_proto_t {
 fields {
  subtype : 8;
 }
}

header_type mpls_t {
 fields {
  label : 20;
  tclass : 3;
  bottom : 1;
  ttl : 8;
 }
}

header_type mpls_cw_t {
 fields {
  useless : 32;
 }
}

header_type vlan_t {
 fields {
  prio : 3;
  cfi : 1;
  id : 12;
  etherType : 16;
 }
}

header_type ipv4_t {
 fields {
  version : 4;
  ihl : 4;
  diffserv : 8;
  totalLen : 16;
  identification : 16;
  flags : 3;
  fragOffset : 13;
  ttl : 8;
  protocol : 8;
  hdrChecksum : 16;
  srcAddr : 32;
  dstAddr : 32;
 }
}

header_type tcp_t {
 fields {
  portSrc : 16;
  portDst : 16;
  seqNum: 32;
  ackNum : 32;
  headerLen : 4;
  reserved : 6;
  controlBits : 6;
  window : 16;
  checksum : 16;
  urgentPtr : 16;
 }
}
header_type udp_t {
 fields {
  portSrc : 16;
  portDst : 16;
  len : 16;
  csum : 16;
 }
}
header_type udplite_t {
 fields {
  portSrc : 16;
  portDst : 16;
  ccover : 16;
  csum : 16;
 }
}
header_type sctp_t {
 fields {
  portSrc : 16;
  portDst : 16;
  tag : 32;
  csum : 32;
 }
}
header_type pppoe_t {
 fields {
  version : 4;
  ptype : 4;
  code : 8;
  session : 16;
  payloadLen : 16;
  protocol : 16;
 }
}

header_type ipv6_t {
 fields {
  ver : 4;
  tclass : 8;
  flowl : 20;
  payloadLen : 16;
  nextHeader : 8;
  hopLimit : 8;
  srcAddr : 128;
  dstAddr : 128;
 }
}

metadata ebmeta_t ebmeta;
header ethernet_t outer_ethernet;
header ethernet_t inner_ethernet;
header ebheader_t ebheader;
header ecolog_t ecolog;
header vlan_t outer_vlan[5];
header mpls_t mpls[5];
header mpls_cw_t mpls_cw;
header ipv4_t outer_ipv4;
header ipv4_t inner_ipv4;
header ipv6_t inner_ipv6;
header ipv6_t outer_ipv6;
header tcp_t tcp;
header udp_t udp;
header sctp_t sctp;
header udplite_t udplite;
header pppoe_t pppoe;
header slow_proto_t slow_proto;


header_type skip_4_t { fields { useless : 32; } }
header_type skip_8_t { fields { useless : 64; } }
header_type skip_12_t { fields { useless : 96; } }
header_type skip_16_t { fields { useless : 128; } }
header_type skip_20_t { fields { useless : 160; } }
header_type skip_24_t { fields { useless : 192; } }
header_type skip_28_t { fields { useless : 224; } }
header_type skip_32_t { fields { useless : 256; } }
header_type skip_36_t { fields { useless : 288; } }
header_type skip_40_t { fields { useless : 320; } }
header_type skip_44_t { fields { useless : 352; } }
header_type skip_48_t { fields { useless : 384; } }
header_type skip_52_t { fields { useless : 416; } }
header_type skip_56_t { fields { useless : 448; } }
header_type skip_60_t { fields { useless : 480; } }
header_type skip_64_t { fields { useless : 512; } }

header skip_4_t skip_4[3];
header skip_8_t skip_8[3];
header skip_12_t skip_12[3];
header skip_16_t skip_16[3];
header skip_20_t skip_20[3];
header skip_24_t skip_24[3];
header skip_28_t skip_28[3];
header skip_32_t skip_32[3];
header skip_36_t skip_36[3];
header skip_40_t skip_40[3];
# 13 "/media/psf/Home/trees/bfn/p4examples/cases/002364/p4src/balancer.p4" 2
# 1 "/media/psf/Home/trees/bfn/p4examples/cases/002364/p4src/parsers.p4" 1
parser start {
 return determine_first_parser;
}

parser determine_first_parser {
 return select(current(96, 8)) {
  0xEC : parse_ecolog;
  0xEB : parse_ebheader;
  default : parse_outer_ethernet;
 }
}

parser parse_ecolog {
 extract(ecolog);
 return ingress;
}

parser parse_ebheader {
 extract(ebheader);
 return parse_fake_ethernet;
}

parser parse_fake_ethernet {
 extract(outer_ethernet);
 return ingress;
}

parser parse_outer_ethernet {
 extract(outer_ethernet);
 return select(outer_ethernet.etherType) {
  0x8100 : parse_outer_vlan;
  0x88A8 : parse_outer_vlan;
  0x9200 : parse_outer_vlan;
  0x9100 : parse_outer_vlan;
  0x8847 : parse_mpls;
  0x8848 : parse_mpls;
  0x0800 : parse_outer_ipv4;
  0x86DD : parse_outer_ipv6;
  0x8864 : parse_pppoe;
  0x8889 : parse_slow;
  default: ingress;
 }
}

parser parse_slow {
 extract(slow_proto);
 return ingress;
}

parser parse_inner_ethernet {
 extract(inner_ethernet);
 return select(inner_ethernet.etherType) {
  0x0800 : parse_outer_ipv4;
  0x86DD : parse_outer_ipv6;
  0x8864 : parse_pppoe;
  default : ingress;
 }
}

parser parse_outer_vlan {
 extract(outer_vlan[next]);
 return select(latest.etherType) {
  0x8100 : parse_outer_vlan;
  0x88A8 : parse_outer_vlan;
  0x9200 : parse_outer_vlan;
  0x9100 : parse_outer_vlan;
  0x8847 : parse_mpls;
  0x8848 : parse_mpls;
  0x0800 : parse_outer_ipv4;
  0x86DD : parse_outer_ipv6;
  0x8864 : parse_pppoe;
  default : ingress;
 }
}

parser parse_mpls {
 extract(mpls[next]);
 return select(latest.bottom) {
  0 : parse_mpls;
  1 : parse_mpls_cw_determine;
  default : ingress;
 }
}

parser parse_mpls_cw_determine {
 return select (current(0, 8)) {
  0x00 : parse_mpls_cw;
  0x45 : cw_try_ipv4;
  0x46 mask 0xFE : cw_try_ipv4;
  0x48 mask 0xF8 : cw_try_ipv4;
  0x60 mask 0xF0 : cw_try_ipv6;
  default : parse_inner_ethernet;
 }
}

parser parse_mpls_cw {
 extract(mpls_cw);
 return select (current(0, 8)) {
  0x45 : cw_try_ipv4;
  0x46 mask 0xFE : cw_try_ipv4;
  0x48 mask 0xF8 : cw_try_ipv4;
  0x60 mask 0xF0 : cw_try_ipv6;
  default : parse_inner_ethernet;
 }
}

parser cw_try_ipv4 {
 return select(current(72, 8)) {
  0x04 : parse_outer_ipv4;
  0x29 : parse_outer_ipv4;
  0x88 : parse_outer_ipv4;
  0x84 : parse_outer_ipv4;
  0x06 : parse_outer_ipv4;
   0x11 : parse_outer_ipv4;
  0x2F : parse_outer_ipv4;
  default : parse_inner_ethernet;
 }
}

parser cw_try_ipv6 {
 return select(current(48, 8)) {
  0x04 : parse_outer_ipv6;
  0x29 : parse_outer_ipv6;
  0x88 : parse_outer_ipv6;
  0x84 : parse_outer_ipv6;
  0x06 : parse_outer_ipv6;
   0x11 : parse_outer_ipv6;
  0x2F : parse_outer_ipv6;
  0 : parse_outer_ipv6;
  43 : parse_outer_ipv6;
  44 : parse_outer_ipv6;
  50 : parse_outer_ipv6;
  51 : parse_outer_ipv6;
  60 : parse_outer_ipv6;
  135 : parse_outer_ipv6;
  59 : parse_outer_ipv6;
  default : parse_inner_ethernet;
 }
}

parser parse_outer_ipv4 {
 extract(outer_ipv4);
 return select(outer_ipv4.ihl) {
  0x6: outer_ipv4_determine_after_skip_4;
  0x7: outer_ipv4_determine_after_skip_8;
  0x8: outer_ipv4_determine_after_skip_12;
  0x9: outer_ipv4_determine_after_skip_16;
  0xA: outer_ipv4_determine_after_skip_20;
  0xB: outer_ipv4_determine_after_skip_24;
  0xC: outer_ipv4_determine_after_skip_28;
  0xD: outer_ipv4_determine_after_skip_32;
  0xE: outer_ipv4_determine_after_skip_36;
  0xF: outer_ipv4_determine_after_skip_40;
  default: outer_ipv4_determine_after;
 }
}

parser parse_outer_ipv6 {
 extract(outer_ipv6);
 return select(outer_ipv6.nextHeader) {
  0x04 : parse_inner_ipv4;
  0x29 : parse_inner_ipv6;
  0x88 : parse_udplite;
  0x84 : parse_sctp;
  0x06 : parse_tcp;
   0x11 : parse_udp;
   default : ingress;
 }
}


parser outer_ipv4_determine_after {
 return select(outer_ipv4.protocol) {
  0x04 : parse_inner_ipv4;
  0x29 : parse_inner_ipv6;
  0x88 : parse_udplite;
  0x84 : parse_sctp;
  0x06 : parse_tcp;
   0x11 : parse_udp;
   default : ingress;
 }
}

parser outer_ipv4_determine_after_skip_4 {
 extract(skip_4[0]);
 return outer_ipv4_determine_after;
}

parser outer_ipv4_determine_after_skip_8 {
 extract(skip_8[0]);
 return outer_ipv4_determine_after;
}

parser outer_ipv4_determine_after_skip_12 {
 extract(skip_12[0]);
 return outer_ipv4_determine_after;
}

parser outer_ipv4_determine_after_skip_16 {
 extract(skip_16[0]);
 return outer_ipv4_determine_after;
}

parser outer_ipv4_determine_after_skip_20 {
 extract(skip_20[0]);
 return outer_ipv4_determine_after;
}

parser outer_ipv4_determine_after_skip_24 {
 extract(skip_24[0]);
 return outer_ipv4_determine_after;
}

parser outer_ipv4_determine_after_skip_28 {
 extract(skip_28[0]);
 return outer_ipv4_determine_after;
}

parser outer_ipv4_determine_after_skip_32 {
 extract(skip_32[0]);
 return outer_ipv4_determine_after;
}

parser outer_ipv4_determine_after_skip_36 {
 extract(skip_36[0]);
 return outer_ipv4_determine_after;
}

parser outer_ipv4_determine_after_skip_40 {
 extract(skip_40[0]);
 return outer_ipv4_determine_after;
}

parser parse_inner_ipv4 {
 extract(inner_ipv4);
 return select(inner_ipv4.ihl) {
  0x6: inner_ipv4_determine_after_skip_4;
  0x7: inner_ipv4_determine_after_skip_8;
  0x8: inner_ipv4_determine_after_skip_12;
  0x9: inner_ipv4_determine_after_skip_16;
  0xA: inner_ipv4_determine_after_skip_20;
  0xB: inner_ipv4_determine_after_skip_24;
  0xC: inner_ipv4_determine_after_skip_28;
  0xD: inner_ipv4_determine_after_skip_32;
  0xE: inner_ipv4_determine_after_skip_36;
  0xF: inner_ipv4_determine_after_skip_40;
  default: inner_ipv4_determine_after;
 }
}

parser inner_ipv4_determine_after {
 return select(inner_ipv4.protocol) {
  0x88 : parse_udplite;
  0x84 : parse_sctp;
  0x06 : parse_tcp;
   0x11 : parse_udp;
   default : ingress;
 }
}

parser parse_inner_ipv6 {
 extract(inner_ipv6);
 return select(inner_ipv6.nextHeader) {
  0x88 : parse_udplite;
  0x84 : parse_sctp;
  0x06 : parse_tcp;
   0x11 : parse_udp;
   default : ingress;
 }
}

parser parse_pppoe {
 extract(pppoe);
 return select (pppoe.protocol) {
  0x0021 : parse_outer_ipv4;
  0x0057 : parse_outer_ipv6;
  default : ingress;
 }
}

parser inner_ipv4_determine_after_skip_4 {
 extract(skip_4[1]);
 return inner_ipv4_determine_after;
}

parser inner_ipv4_determine_after_skip_8 {
 extract(skip_8[1]);
 return inner_ipv4_determine_after;
}

parser inner_ipv4_determine_after_skip_12 {
 extract(skip_12[1]);
 return inner_ipv4_determine_after;
}

parser inner_ipv4_determine_after_skip_16 {
 extract(skip_16[1]);
 return inner_ipv4_determine_after;
}

parser inner_ipv4_determine_after_skip_20 {
 extract(skip_20[1]);
 return inner_ipv4_determine_after;
}

parser inner_ipv4_determine_after_skip_24 {
 extract(skip_24[1]);
 return inner_ipv4_determine_after;
}

parser inner_ipv4_determine_after_skip_28 {
 extract(skip_28[1]);
 return inner_ipv4_determine_after;
}

parser inner_ipv4_determine_after_skip_32 {
 extract(skip_32[1]);
 return inner_ipv4_determine_after;
}

parser inner_ipv4_determine_after_skip_36 {
 extract(skip_36[1]);
 return inner_ipv4_determine_after;
}

parser inner_ipv4_determine_after_skip_40 {
 extract(skip_40[1]);
 return inner_ipv4_determine_after;
}

parser parse_tcp {
 extract(tcp);
 return ingress;
}
parser parse_udp {
 extract(udp);
 return ingress;
}
parser parse_sctp {
 extract(sctp);
 return ingress;
}
parser parse_udplite {
 extract(udplite);
 return ingress;
}
# 14 "/media/psf/Home/trees/bfn/p4examples/cases/002364/p4src/balancer.p4" 2
# 1 "/media/psf/Home/trees/bfn/p4examples/cases/002364/p4src/hashes.p4" 1


field_list list_lan_outer_mac_hash {
 outer_ethernet.srcAddr;
 outer_ethernet.dstAddr;
}
field_list_calculation port_lan_outer_mac_hash {
 input { list_lan_outer_mac_hash; }
 algorithm : crc16; output_width : 16;
}

field_list list_wan_outer_mac_hash {
 outer_ethernet.dstAddr;
 outer_ethernet.srcAddr;
}
field_list_calculation port_wan_outer_mac_hash {
 input { list_wan_outer_mac_hash; }
 algorithm : crc16; output_width : 16;
}

field_list list_lan_inner_mac_hash {
 inner_ethernet.srcAddr;
 inner_ethernet.dstAddr;
}
field_list_calculation port_lan_inner_mac_hash {
 input { list_lan_inner_mac_hash; }
 algorithm : crc16; output_width : 16;
}

field_list list_wan_inner_mac_hash {
 inner_ethernet.dstAddr;
 inner_ethernet.srcAddr;
}
field_list_calculation port_wan_inner_mac_hash {
 input { list_wan_inner_mac_hash; }
 algorithm : crc16; output_width : 16;
}

field_list list_lan_ipv4_nat_hash {
 outer_ipv4.srcAddr;
}
field_list_calculation port_lan_ipv4_nat_hash {
 input { list_lan_ipv4_nat_hash; }
 algorithm : crc16; output_width : 16;
}

field_list list_wan_ipv4_nat_hash {
 outer_ipv4.dstAddr;
}
field_list_calculation port_wan_ipv4_nat_hash {
 input { list_wan_ipv4_nat_hash; }
 algorithm : crc16; output_width : 16;
}

field_list list_lan_ipv4_mag_hash {
 outer_ipv4.srcAddr;
 outer_ipv4.dstAddr;
}
field_list_calculation port_mag_ipv4_mag_hash {
 input { list_lan_ipv4_mag_hash; }
 algorithm : crc16; output_width : 16;
}

field_list list_wan_ipv4_mag_hash {
 outer_ipv4.dstAddr;
 outer_ipv4.srcAddr;
}
field_list_calculation port_wan_ipv4_mag_hash {
 input { list_wan_ipv4_mag_hash; }
 algorithm : crc16; output_width : 16;
}

field_list list_lan_ipv6_nat_hash {
 outer_ipv6.srcAddr;
}
field_list_calculation port_lan_ipv6_nat_hash {
 input { list_lan_ipv6_nat_hash; }
 algorithm : crc16; output_width : 16;
}

field_list list_wan_ipv6_nat_hash {
 outer_ipv6.dstAddr;
}
field_list_calculation port_wan_ipv6_nat_hash {
 input { list_wan_ipv6_nat_hash; }
 algorithm : crc16; output_width : 16;
}

field_list list_lan_ipv6_mag_hash {
 outer_ipv6.srcAddr;
 outer_ipv6.dstAddr;
}
field_list_calculation port_lan_ipv6_mag_hash {
 input { list_lan_ipv6_mag_hash; }
 algorithm : crc16; output_width : 16;
}

field_list list_wan_ipv6_mag_hash {
 outer_ipv6.dstAddr;
 outer_ipv6.srcAddr;
}
field_list_calculation port_wan_ipv6_mag_hash {
 input { list_wan_ipv6_mag_hash; }
 algorithm : crc16; output_width : 16;
}


field_list flow_lan_ip4_hash {
 outer_ipv4.srcAddr;
 outer_ipv4.dstAddr;
 ebmeta.flow_srcPort;
 ebmeta.flow_dstPort;
 ebmeta.flow_proto;
 ebmeta.is_nat;
}

field_list flow_wan_ip4_hash {
 outer_ipv4.dstAddr;
 outer_ipv4.srcAddr;
 ebmeta.flow_dstPort;
 ebmeta.flow_srcPort;
 ebmeta.flow_proto;
 ebmeta.is_nat;
}

field_list flow_lan_ip6_hash {
 outer_ipv6.srcAddr;
 outer_ipv6.dstAddr;
 ebmeta.flow_srcPort;
 ebmeta.flow_dstPort;
 ebmeta.flow_proto;
 ebmeta.is_nat;
}

field_list flow_wan_ip6_hash {
 outer_ipv6.dstAddr;
 outer_ipv6.srcAddr;
 ebmeta.flow_dstPort;
 ebmeta.flow_srcPort;
 ebmeta.flow_proto;
 ebmeta.is_nat;
}

field_list flow_lan_mac_hash {
 outer_ethernet.srcAddr;
 outer_ethernet.dstAddr;
 ebmeta.is_nat;
}

field_list flow_wan_mac_hash {
 outer_ethernet.dstAddr;
 outer_ethernet.srcAddr;
 ebmeta.is_nat;
}


field_list_calculation flow_lan_ip4_calc1 {
 input {
  flow_lan_ip4_hash;
 }
 algorithm : identity;
 output_width : 32;
}
field_list_calculation flow_lan_ip4_calc2 {
 input {
  flow_lan_ip4_hash;
 }
 algorithm : crc32_msb;
 output_width : 32;
}
field_list_calculation flow_wan_ip4_calc1 {
 input {
  flow_wan_ip4_hash;
 }
 algorithm : identity;
 output_width : 32;
}
field_list_calculation flow_wan_ip4_calc2 {
 input {
  flow_wan_ip4_hash;
 }
 algorithm : crc32_msb;
 output_width : 32;
}


field_list_calculation flow_lan_ip6_calc1 {
 input {
  flow_lan_ip6_hash;
 }
 algorithm : identity;
 output_width : 32;
}
field_list_calculation flow_lan_ip6_calc2 {
 input {
  flow_lan_ip6_hash;
 }
 algorithm : crc32_msb;
 output_width : 32;
}
field_list_calculation flow_wan_ip6_calc1 {
 input {
  flow_wan_ip6_hash;
 }
 algorithm : identity;
 output_width : 32;
}
field_list_calculation flow_wan_ip6_calc2 {
 input {
  flow_wan_ip6_hash;
 }
 algorithm : crc32_msb;
 output_width : 32;
}


field_list_calculation flow_lan_mac_calc1 {
 input {
  flow_lan_mac_hash;
 }
 algorithm : identity;
 output_width : 32;
}
field_list_calculation flow_lan_mac_calc2 {
 input {
  flow_lan_mac_hash;
 }
 algorithm : crc32_msb;
 output_width : 32;
}
field_list_calculation flow_wan_mac_calc1 {
 input {
  flow_wan_mac_hash;
 }
 algorithm : identity;
 output_width : 32;
}
field_list_calculation flow_wan_mac_calc2 {
 input {
  flow_wan_mac_hash;
 }
 algorithm : crc32_msb;
 output_width : 32;
}
# 15 "/media/psf/Home/trees/bfn/p4examples/cases/002364/p4src/balancer.p4" 2
# 1 "/media/psf/Home/trees/bfn/p4examples/cases/002364/p4src/tables.p4" 1



table determine_port_type {
 reads {

  ig_intr_md.ingress_port : exact;



 }
 actions {
  set_port_type;
  _drop;
 }
 default_action: _drop;
 size : 512;
}


table determine_nat_lanwan_flag_and_linked_port {
 reads {

  ig_intr_md.ingress_port : exact;



 }
 actions {
  set_nat_lanwan_flag_and_linked_port;
  _nop;
 }
 default_action : _nop;
 size : 256;
}

table bypass_mode {
 reads {
  ebmeta.port_type : exact;
 }
 actions {
  do_bypass;
  _nop;
 }
 default_action : _nop;
 size : 2;
}

table forward_lacp {
 reads {
  ebmeta.port_type : exact;
  slow_proto : valid;
  slow_proto.subtype : exact;
 }
 actions {
  do_bypass;
  _nop;
 }
 default_action : _nop;
 size : 2;
}

table get_flow_ports {
 reads {
  tcp : valid;
  udp : valid;
  sctp : valid;
  udplite : valid;
 }
 actions {
  set_tcp_flow_data;
  set_udp_flow_data;
  set_sctp_flow_data;
  set_udplite_flow_data;
  _nop;
 }
 default_action : _nop;
 size : 8;
}

table tbl_dpi_lan_outer_mac_hash {
 actions { calc_dpi_lan_outer_mac_hash; }
 default_action : calc_dpi_lan_outer_mac_hash;
}
table tbl_dpi_wan_outer_mac_hash {
 actions { calc_dpi_wan_outer_mac_hash; }
 default_action : calc_dpi_wan_outer_mac_hash;
}
table tbl_dpi_lan_ipv4_nat_hash {
 actions { calc_dpi_lan_ipv4_nat_hash; }
 default_action : calc_dpi_lan_ipv4_nat_hash;
}
table tbl_dpi_lan_ipv6_nat_hash {
 actions { calc_dpi_lan_ipv6_nat_hash; }
 default_action : calc_dpi_lan_ipv6_nat_hash;
}
table tbl_dpi_lan_ipv4_mag_hash {
 actions { calc_dpi_lan_ipv4_mag_hash; }
 default_action : calc_dpi_lan_ipv4_mag_hash;
}
table tbl_dpi_lan_ipv6_mag_hash {
 actions { calc_dpi_lan_ipv6_mag_hash; }
 default_action : calc_dpi_lan_ipv6_mag_hash;
}
table tbl_dpi_wan_ipv4_nat_hash {
 actions { calc_dpi_wan_ipv4_nat_hash; }
 default_action : calc_dpi_wan_ipv4_nat_hash;
}
table tbl_dpi_wan_ipv6_nat_hash {
 actions { calc_dpi_wan_ipv6_nat_hash; }
 default_action : calc_dpi_wan_ipv6_nat_hash;
}
table tbl_dpi_wan_ipv4_mag_hash {
 actions { calc_dpi_wan_ipv4_mag_hash; }
 default_action : calc_dpi_wan_ipv4_mag_hash;
}
table tbl_dpi_wan_ipv6_mag_hash {
 actions { calc_dpi_wan_ipv6_mag_hash; }
 default_action : calc_dpi_wan_ipv6_mag_hash;
}
table tbl_dpi_lan_inner_mac_hash {
 actions { calc_dpi_lan_inner_mac_hash; }
 default_action : calc_dpi_lan_inner_mac_hash;
}
table tbl_dpi_wan_inner_mac_hash {
 actions { calc_dpi_wan_inner_mac_hash; }
 default_action : calc_dpi_wan_inner_mac_hash;
}

table update_byte_counters {
 reads {
  ebmeta.port_type : exact;
 }
 actions {
  do_update_byte_counters;
  _nop;
 }
 default_action : _nop;
 size : 2;
}

table update_packet_counters {
 reads {
  ebmeta.port_type : exact;
 }
 actions {
  do_update_packet_counters;
  _nop;
 }
 default_action : _nop;
 size : 2;
}


table tbl_flow_hash_lan_ip4_1 {
 actions { calc_flow_hash_lan_ip4_1; }
 default_action : calc_flow_hash_lan_ip4_1;
}
table tbl_flow_hash_lan_ip4_2 {
 actions { calc_flow_hash_lan_ip4_2; }
 default_action : calc_flow_hash_lan_ip4_2;
}
table tbl_flow_hash_wan_ip4_1 {
 actions { calc_flow_hash_wan_ip4_1; }
 default_action : calc_flow_hash_wan_ip4_1;
}
table tbl_flow_hash_wan_ip4_2 {
 actions { calc_flow_hash_wan_ip4_2; }
 default_action : calc_flow_hash_wan_ip4_2;
}
table tbl_flow_hash_lan_ip6_1 {
 actions { calc_flow_hash_lan_ip6_1; }
 default_action : calc_flow_hash_lan_ip6_1;
}
table tbl_flow_hash_lan_ip6_2 {
 actions { calc_flow_hash_lan_ip6_2; }
 default_action : calc_flow_hash_lan_ip6_2;
}
table tbl_flow_hash_wan_ip6_1 {
 actions { calc_flow_hash_wan_ip6_1; }
 default_action : calc_flow_hash_wan_ip6_1;
}
table tbl_flow_hash_wan_ip6_2 {
 actions { calc_flow_hash_wan_ip6_2; }
 default_action : calc_flow_hash_wan_ip6_2;
}
table tbl_flow_hash_lan_mac_1 {
 actions { calc_flow_hash_lan_mac_1; }
 default_action : calc_flow_hash_lan_mac_1;
}
table tbl_flow_hash_lan_mac_2 {
 actions { calc_flow_hash_lan_mac_2; }
 default_action : calc_flow_hash_lan_mac_2;
}
table tbl_flow_hash_wan_mac_1 {
 actions { calc_flow_hash_wan_mac_1; }
 default_action : calc_flow_hash_wan_mac_1;
}
table tbl_flow_hash_wan_mac_2 {
 actions { calc_flow_hash_wan_mac_2; }
 default_action : calc_flow_hash_wan_mac_2;
}



table set_dpi_output {
 reads {
  ebmeta.port_hash : exact;
 }
 actions {
  set_dpi_out_and_queue;
  _nop;
 }
 default_action : _nop;
 size : 65536;
}


table forward_log {
 reads {
  ebmeta.port_type : exact;
  ecolog : valid;
  ecolog.etherType : exact;
 }
 actions {
  do_forward_log;
  _nop;
 }
 default_action : _nop;
 size : 8;
}

table drop_if_no_ebheader {
 reads {
  ebmeta.port_type : exact;
  ebheader : valid;
 }
 actions {
  _drop;
  _nop;
 }
 default_action : _nop;
 size : 1;
}

table dpi_set_egress_port {
 reads {
  ebmeta.port_type : exact;
 }
 actions {
  dpi_egress_port;
  _nop;
 }
 default_action : _nop;
 size : 2;
}


table add_ebheader {
 reads {
  ebmeta.port_type : exact;
 }
 actions {
  do_add_ebheader;
  _nop;
 }
 default_action : _nop;
 size : 2;
}


table remove_ebheader {
 reads {
  ebmeta.port_type : exact;
 }
 actions {
  do_remove_ebheader;
  _nop;
 }
 default_action : _nop;
 size : 2;
}
# 16 "/media/psf/Home/trees/bfn/p4examples/cases/002364/p4src/balancer.p4" 2
# 1 "/media/psf/Home/trees/bfn/p4examples/cases/002364/p4src/counters.p4" 1


counter per_hash_bytes_ctr {
 type : bytes;
 static : update_byte_counters;
 instance_count : 65536;
}

counter per_hash_packets_ctr {
 type : packets;
 static : update_packet_counters;
 instance_count : 65536;
}
# 17 "/media/psf/Home/trees/bfn/p4examples/cases/002364/p4src/balancer.p4" 2
# 1 "/media/psf/Home/trees/bfn/p4examples/cases/002364/p4src/actions.p4" 1


action _nop() { no_op(); }
action _drop() { drop(); }

action set_port_type(port_type) {
 modify_field(ebmeta.port_type, port_type);
}

action do_forward_log(out_port) {
 modify_field(ebmeta.port_type, 4);
 modify_field(ecolog.etherType, 0x0800);

 modify_field(ig_intr_md_for_tm.ucast_egress_port, out_port);



}

action set_nat_lanwan_flag_and_linked_port(is_lan, is_nat, linked_port) {
 modify_field(ebmeta.is_lan, is_lan);
 modify_field(ebmeta.is_nat, is_nat);
 modify_field(ebmeta.lanwan_out_port, linked_port);
}

action do_bypass() {
 modify_field(ebmeta.port_type, 4);

 modify_field(ig_intr_md_for_tm.ucast_egress_port, ebmeta.lanwan_out_port);



}


action calc_dpi_lan_outer_mac_hash() {
 modify_field_with_hash_based_offset(ebmeta.port_hash, 0, port_lan_outer_mac_hash, 65536);
}
action calc_dpi_wan_outer_mac_hash() {
 modify_field_with_hash_based_offset(ebmeta.port_hash, 0, port_wan_outer_mac_hash, 65536);
}
action calc_dpi_lan_inner_mac_hash() {
 modify_field_with_hash_based_offset(ebmeta.port_hash, 0, port_lan_inner_mac_hash, 65536);
}
action calc_dpi_wan_inner_mac_hash() {
 modify_field_with_hash_based_offset(ebmeta.port_hash, 0, port_wan_inner_mac_hash, 65536);
}
action calc_dpi_lan_ipv4_nat_hash() {
 modify_field_with_hash_based_offset(ebmeta.port_hash, 0, port_lan_ipv4_nat_hash, 65536);
}
action calc_dpi_lan_ipv4_mag_hash() {
 modify_field_with_hash_based_offset(ebmeta.port_hash, 0, port_mag_ipv4_mag_hash, 65536);
}
action calc_dpi_wan_ipv4_nat_hash() {
 modify_field_with_hash_based_offset(ebmeta.port_hash, 0, port_wan_ipv4_nat_hash, 65536);
}
action calc_dpi_wan_ipv4_mag_hash() {
 modify_field_with_hash_based_offset(ebmeta.port_hash, 0, port_wan_ipv4_mag_hash, 65536);
}
action calc_dpi_lan_ipv6_nat_hash() {
 modify_field_with_hash_based_offset(ebmeta.port_hash, 0, port_lan_ipv6_nat_hash, 65536);
}
action calc_dpi_lan_ipv6_mag_hash() {
 modify_field_with_hash_based_offset(ebmeta.port_hash, 0, port_lan_ipv6_mag_hash, 65536);
}
action calc_dpi_wan_ipv6_nat_hash() {
 modify_field_with_hash_based_offset(ebmeta.port_hash, 0, port_wan_ipv6_nat_hash, 65536);
}
action calc_dpi_wan_ipv6_mag_hash() {
 modify_field_with_hash_based_offset(ebmeta.port_hash, 0, port_wan_ipv6_mag_hash, 65536);
}


action do_update_byte_counters() {
    count(per_hash_bytes_ctr, ebmeta.port_hash);
}


action do_update_packet_counters() {
    count(per_hash_packets_ctr, ebmeta.port_hash);
}


action set_tcp_flow_data() {
 modify_field(ebmeta.flow_proto, 1);
 modify_field(ebmeta.flow_srcPort, tcp.portSrc);
 modify_field(ebmeta.flow_dstPort, tcp.portDst);
}

action set_udp_flow_data() {
 modify_field(ebmeta.flow_proto, 2);
 modify_field(ebmeta.flow_srcPort, udp.portSrc);
 modify_field(ebmeta.flow_dstPort, udp.portDst);
}

action set_sctp_flow_data() {
 modify_field(ebmeta.flow_proto, 3);
 modify_field(ebmeta.flow_srcPort, sctp.portSrc);
 modify_field(ebmeta.flow_dstPort, sctp.portDst);
}

action set_udplite_flow_data() {
 modify_field(ebmeta.flow_proto, 4);
 modify_field(ebmeta.flow_srcPort, udplite.portSrc);
 modify_field(ebmeta.flow_dstPort, udplite.portDst);
}

action calc_flow_hash_wan_mac_1() {
 modify_field_with_hash_based_offset(ebmeta.hash1, 0, flow_wan_mac_calc1, 4294967296);
}
action calc_flow_hash_wan_mac_2() {
 modify_field_with_hash_based_offset(ebmeta.hash2, 0, flow_wan_mac_calc2, 4294967296);
}

action calc_flow_hash_lan_mac_1() {
 modify_field_with_hash_based_offset(ebmeta.hash1, 0, flow_lan_mac_calc1, 4294967296);
}
action calc_flow_hash_lan_mac_2() {
 modify_field_with_hash_based_offset(ebmeta.hash2, 0, flow_lan_mac_calc2, 4294967296);
}

action calc_flow_hash_wan_ip4_1() {
 modify_field_with_hash_based_offset(ebmeta.hash1, 0, flow_wan_ip4_calc1, 4294967296);
}
action calc_flow_hash_wan_ip4_2() {
 modify_field_with_hash_based_offset(ebmeta.hash2, 0, flow_wan_ip4_calc2, 4294967296);
}

action calc_flow_hash_lan_ip4_1() {
 modify_field_with_hash_based_offset(ebmeta.hash1, 0, flow_lan_ip4_calc1, 4294967296);
}
action calc_flow_hash_lan_ip4_2() {
 modify_field_with_hash_based_offset(ebmeta.hash2, 0, flow_lan_ip4_calc2, 4294967296);
}

action calc_flow_hash_wan_ip6_1() {
 modify_field_with_hash_based_offset(ebmeta.hash1, 0, flow_wan_ip6_calc1, 4294967296);
}
action calc_flow_hash_wan_ip6_2() {
 modify_field_with_hash_based_offset(ebmeta.hash2, 0, flow_wan_ip6_calc2, 4294967296);
}

action calc_flow_hash_lan_ip6_1() {
 modify_field_with_hash_based_offset(ebmeta.hash1, 0, flow_lan_ip6_calc1, 4294967296);
}
action calc_flow_hash_lan_ip6_2() {
 modify_field_with_hash_based_offset(ebmeta.hash2, 0, flow_lan_ip6_calc2, 4294967296);
}

action set_dpi_out_and_queue(port, queue) {

 modify_field(ig_intr_md_for_tm.ucast_egress_port, port);



 modify_field(ebmeta.rss_queue, queue);
}

action dpi_egress_port() {

 modify_field(ig_intr_md_for_tm.ucast_egress_port, ebheader.dst_main_out);



}

action do_add_ebheader() {
 add_header(ebheader);
 modify_field(ebheader.ethertype_eb, 0xEB);
 modify_field(ebheader.dst_main_out, ebmeta.lanwan_out_port);
 modify_field(ebheader.is_nat, ebmeta.is_nat);
 modify_field(ebheader.is_lan, ebmeta.is_lan);
 modify_field(ebheader.rss_queue, ebmeta.rss_queue);
 modify_field(ebheader.offset_mpls, ebmeta.offset_mpls);
 modify_field(ebheader.offset_payload, ebmeta.offset_payload);
 modify_field(ebheader.offset_ip1, ebmeta.offset_ip1);
 modify_field(ebheader.offset_ip2, ebmeta.offset_ip2);
 modify_field(ebheader.hash1, ebmeta.hash1);
 modify_field(ebheader.hash2, ebmeta.hash2);
}

action do_remove_ebheader() {

 modify_field(ebmeta.dst_mirror_out, ebheader.dst_mirror_out);
 remove_header(ebheader);
}
# 18 "/media/psf/Home/trees/bfn/p4examples/cases/002364/p4src/balancer.p4" 2
# 1 "/media/psf/Home/trees/bfn/p4examples/cases/002364/p4src/controls.p4" 1


control update_counters {
 apply(update_byte_counters);
 apply(update_packet_counters);
}

control calculate_flow_hashes {
 apply(get_flow_ports);
    if (ebmeta.port_type == 1) {
        if (valid(outer_ipv4)) {
            apply(tbl_flow_hash_lan_ip4_1);
            apply(tbl_flow_hash_lan_ip4_2);
        } else {
            if (valid(outer_ipv6)) {
                apply(tbl_flow_hash_lan_ip6_1);
                apply(tbl_flow_hash_lan_ip6_2);
            } else {
                apply(tbl_flow_hash_lan_mac_1);
                apply(tbl_flow_hash_lan_mac_2);
            }
        }
    }
    if (ebmeta.port_type == 2) {
        if (valid(outer_ipv4)) {
            apply(tbl_flow_hash_wan_ip4_1);
            apply(tbl_flow_hash_wan_ip4_2);
        } else {
            if (valid(outer_ipv6)) {
                apply(tbl_flow_hash_wan_ip6_1);
                apply(tbl_flow_hash_wan_ip6_2);
            } else {
                apply(tbl_flow_hash_wan_mac_1);
                apply(tbl_flow_hash_wan_mac_2);
            }
        }
    }
}

control calculate_dpi_hashes {
 if (ebmeta.port_type == 1) {
  if (ebmeta.is_nat == 1) {
   if (valid(outer_ipv4)) {
    apply(tbl_dpi_lan_ipv4_nat_hash);
   } else {
    if (valid(outer_ipv6)) {
     apply(tbl_dpi_lan_ipv6_nat_hash);
    } else {
     if (valid(inner_ethernet)) {
      apply(tbl_dpi_lan_inner_mac_hash);
     } else {
      apply(tbl_dpi_lan_outer_mac_hash);
     }
    }
   }
  } else {
   if (valid(outer_ipv4)) {
    apply(tbl_dpi_lan_ipv4_mag_hash);
   } else {
    if (valid(outer_ipv6)) {
     apply(tbl_dpi_lan_ipv6_mag_hash);
    } else {
     if (valid(inner_ethernet)) {
      apply(tbl_dpi_lan_inner_mac_hash);
     } else {
      apply(tbl_dpi_lan_outer_mac_hash);
     }
    }
   }
  }
 }

 if (ebmeta.port_type == 2) {
  if (ebmeta.is_nat == 1) {
   if (valid(outer_ipv4)) {
    apply(tbl_dpi_wan_ipv4_nat_hash);
   } else {
    if (valid(outer_ipv6)) {
     apply(tbl_dpi_wan_ipv6_nat_hash);
    } else {
     if (valid(inner_ethernet)) {
      apply(tbl_dpi_wan_inner_mac_hash);
     } else {
      apply(tbl_dpi_wan_outer_mac_hash);
     }
    }
   }
  } else {
   if (valid(outer_ipv4)) {
    apply(tbl_dpi_wan_ipv4_mag_hash);
   } else {
    if (valid(outer_ipv6)) {
     apply(tbl_dpi_wan_ipv6_mag_hash);
    } else {
     if (valid(inner_ethernet)) {
      apply(tbl_dpi_wan_inner_mac_hash);
     } else {
      apply(tbl_dpi_wan_outer_mac_hash);
     }
    }
   }
  }
 }
}
# 19 "/media/psf/Home/trees/bfn/p4examples/cases/002364/p4src/balancer.p4" 2


control ingress {

 apply(determine_port_type);


 apply(determine_nat_lanwan_flag_and_linked_port);
 apply(bypass_mode);
 apply(forward_lacp);
 calculate_dpi_hashes();
 calculate_flow_hashes();
 update_counters();
 apply(set_dpi_output);


 apply(forward_log);
 apply(drop_if_no_ebheader);
 apply(dpi_set_egress_port);
}

control egress {

 apply(add_ebheader);

 apply(remove_ebheader);
}
