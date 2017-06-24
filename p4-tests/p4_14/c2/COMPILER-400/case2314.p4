/*
gcc -E -x c -w -I/tmp/_MEIXD3jKJ/p4_lib -D__TARGET_TOFINO__ -I/tmp/_MEIXD3jKJ/p4_hlir/p4_lib /media/psf/Home/trees/bfn/p4examples/cases/002314/p4src/balancer.p4
*/
# 1 "/media/psf/Home/trees/bfn/p4examples/cases/002314/p4src/balancer.p4"
# 1 "<built-in>"
# 1 "<command-line>"
# 1 "/usr/include/stdc-predef.h" 1 3 4
# 1 "<command-line>" 2
# 1 "/media/psf/Home/trees/bfn/p4examples/cases/002314/p4src/balancer.p4"

# 1 "/tmp/_MEIXD3jKJ/p4_lib/tofino/constants.p4" 1
# 3 "/media/psf/Home/trees/bfn/p4examples/cases/002314/p4src/balancer.p4" 2
# 1 "/tmp/_MEIXD3jKJ/p4_lib/tofino/intrinsic_metadata.p4" 1
# 10 "/tmp/_MEIXD3jKJ/p4_lib/tofino/intrinsic_metadata.p4"
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
# 379 "/tmp/_MEIXD3jKJ/p4_lib/tofino/intrinsic_metadata.p4"
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
# 422 "/tmp/_MEIXD3jKJ/p4_lib/tofino/intrinsic_metadata.p4"
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
# 4 "/media/psf/Home/trees/bfn/p4examples/cases/002314/p4src/balancer.p4" 2
# 1 "/tmp/_MEIXD3jKJ/p4_lib/tofino/primitives.p4" 1
# 10 "/tmp/_MEIXD3jKJ/p4_lib/tofino/primitives.p4"
action deflect_on_drop(enable_dod) {
    modify_field(ig_intr_md_for_tm.deflect_on_drop, enable_dod);
}
# 5 "/media/psf/Home/trees/bfn/p4examples/cases/002314/p4src/balancer.p4" 2
# 1 "/tmp/_MEIXD3jKJ/p4_lib/tofino/pktgen_headers.p4" 1
# 9 "/tmp/_MEIXD3jKJ/p4_lib/tofino/pktgen_headers.p4"
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
# 6 "/media/psf/Home/trees/bfn/p4examples/cases/002314/p4src/balancer.p4" 2
# 1 "/tmp/_MEIXD3jKJ/p4_lib/tofino/stateful_alu_blackbox.p4" 1


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
# 81 "/tmp/_MEIXD3jKJ/p4_lib/tofino/stateful_alu_blackbox.p4"
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
# 214 "/tmp/_MEIXD3jKJ/p4_lib/tofino/stateful_alu_blackbox.p4"
        type: string;
        optional;
    }

    attribute stateful_logging_mode {
# 228 "/tmp/_MEIXD3jKJ/p4_lib/tofino/stateful_alu_blackbox.p4"
        type: string;
        optional;
    }
# 246 "/tmp/_MEIXD3jKJ/p4_lib/tofino/stateful_alu_blackbox.p4"
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
# 7 "/media/psf/Home/trees/bfn/p4examples/cases/002314/p4src/balancer.p4" 2


# 1 "/media/psf/Home/trees/bfn/p4examples/cases/002314/p4src/defines.p4" 1
# 10 "/media/psf/Home/trees/bfn/p4examples/cases/002314/p4src/balancer.p4" 2
# 1 "/media/psf/Home/trees/bfn/p4examples/cases/002314/p4src/headers.p4" 1
# 24 "/media/psf/Home/trees/bfn/p4examples/cases/002314/p4src/headers.p4"
header_type ebmeta_t {
 fields {
  lanwan_out_port : 8;
  dpi_port : 8;
  dst_mirror_agg : 8;
  dst_mirror_out : 8;
  _pad : 2;
  port_type : 3;
  is_nat : 1;
  is_lan : 1;
  offset_ip1 : 8;
  offset_ip2 : 8;
  offset_mpls : 8;
  offset_payload : 8;
  rss_queue : 8;
  port_hash : 16;
 }
}


header_type ethernet_t {
 fields {
  dstAddr : 48;
  srcAddr : 48;
  etherType : 16;
 }
}
# 75 "/media/psf/Home/trees/bfn/p4examples/cases/002314/p4src/headers.p4"
header_type ebheader_t {
 fields {
  unused1 : 16;
  dst_main_agg : 8;
  dst_main_out : 8;
  dst_mirror_agg : 8;
  dst_mirror_out : 8;
  unused2 : 8;
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
  srcPort : 16;
  dstPort : 16;
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
header_type skip_60_t { fields { useless : 384; } }
header_type skip_64_t { fields { useless : 384; } }

header skip_4_t skip_4_i;
header skip_8_t skip_8_i;
header skip_12_t skip_12_i;
header skip_16_t skip_16_i;
header skip_20_t skip_20_i;
header skip_24_t skip_24_i;
header skip_28_t skip_28_i;
header skip_32_t skip_32_i;
header skip_36_t skip_36_i;
header skip_40_t skip_40_i;
header skip_4_t skip_4_o;
header skip_8_t skip_8_o;
header skip_12_t skip_12_o;
header skip_16_t skip_16_o;
header skip_20_t skip_20_o;
header skip_24_t skip_24_o;
header skip_28_t skip_28_o;
header skip_32_t skip_32_o;
header skip_36_t skip_36_o;
header skip_40_t skip_40_o;
# 11 "/media/psf/Home/trees/bfn/p4examples/cases/002314/p4src/balancer.p4" 2
# 1 "/media/psf/Home/trees/bfn/p4examples/cases/002314/p4src/parsers.p4" 1
parser start {
 return determine_first_parser;
}

parser determine_first_parser {
 return select(current(96, 8)) {
  0xEC : ingress;
  0xEB : parse_ebheader;
  default : parse_outer_ethernet;
 }
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
 return ingress;
# 39 "/media/psf/Home/trees/bfn/p4examples/cases/002314/p4src/parsers.p4"
}
# 12 "/media/psf/Home/trees/bfn/p4examples/cases/002314/p4src/balancer.p4" 2
# 1 "/media/psf/Home/trees/bfn/p4examples/cases/002314/p4src/hashes.p4" 1
field_list port_lan_mac_hash {
 outer_ethernet.srcAddr;
}

field_list port_wan_mac_hash {
 outer_ethernet.dstAddr;
}

field_list_calculation port_lan_mac_hash_calc {
 input {
  port_lan_mac_hash;
 }
 algorithm : crc16;
 output_width : 16;
}

field_list_calculation port_wan_mac_hash_calc {
 input {
  port_wan_mac_hash;
 }
 algorithm : crc16;
 output_width : 16;
}
# 13 "/media/psf/Home/trees/bfn/p4examples/cases/002314/p4src/balancer.p4" 2
# 1 "/media/psf/Home/trees/bfn/p4examples/cases/002314/p4src/tables.p4" 1

table determine_port_type {
 reads {

  ig_intr_md.ingress_port : exact;



 }
 actions {
  set_port_type;
  _drop;
 }
}


table determine_nat_lanwan_flag_and_linked_port {
 reads {

  ig_intr_md.ingress_port : exact;



 }
 actions {
  set_nat_lanwan_flag_and_linked_port;
  _nop;
 }
}

table calc_dpi_hash {
 reads {
  ebmeta.port_type : exact;




  ebmeta.is_lan : exact;

 }
 actions {
  calc_dpi_lan_mac_hash;
  calc_dpi_wan_mac_hash;
  _nop;
 }

}

table set_dpi_output {
 reads {
  ebmeta.port_type : exact;
  ebmeta.port_hash : exact;
 }
 actions {
  set_dpi_out_and_queue;
  _nop;
 }
}


table add_ebheader {
 reads {
  ebmeta.port_type : exact;
 }
 actions {
  do_add_ebheader;
  _nop;
 }
}


table remove_ebheader {
 reads {
  ebmeta.port_type : exact;
 }
 actions {
  do_remove_ebheader;
  _nop;
 }
}
# 14 "/media/psf/Home/trees/bfn/p4examples/cases/002314/p4src/balancer.p4" 2
# 1 "/media/psf/Home/trees/bfn/p4examples/cases/002314/p4src/actions.p4" 1
action _nop() { no_op(); }
action _drop() { drop(); }

action set_port_type(port_type) {
 modify_field(ebmeta.port_type, port_type);
}

action set_nat_lanwan_flag_and_linked_port(is_lan, is_nat, linked_port) {
 modify_field(ebmeta.is_lan, is_lan);
 modify_field(ebmeta.is_nat, is_nat);
 modify_field(ebmeta.lanwan_out_port, linked_port);
}

action calc_dpi_lan_mac_hash() {
 modify_field_with_hash_based_offset(ebmeta.port_hash, 0, port_lan_mac_hash_calc, 256);
}

action calc_dpi_wan_mac_hash() {
 modify_field_with_hash_based_offset(ebmeta.port_hash, 0, port_wan_mac_hash_calc, 256);
}

action set_dpi_out_and_queue(port, queue) {

 modify_field(ig_intr_md_for_tm.ucast_egress_port, port);



 modify_field(ebmeta.rss_queue, queue);
}

action do_add_ebheader() {
 add_header(ebheader);
 modify_field(ebheader.ethertype_eb, 0xEB);
 modify_field(ebheader.dst_main_out, ebmeta.lanwan_out_port);
 modify_field(ebheader.is_nat, ebmeta.is_nat);


 modify_field(ebheader.rss_queue, ebmeta.rss_queue);
 modify_field(ebheader.offset_mpls, ebmeta.offset_mpls);
 modify_field(ebheader.offset_payload, ebmeta.offset_payload);
 modify_field(ebheader.offset_ip1, ebmeta.offset_ip1);
 modify_field(ebheader.offset_ip2, ebmeta.offset_ip2);
}

action do_remove_ebheader() {
 modify_field(ebmeta.dst_mirror_agg, ebheader.dst_mirror_agg);
 modify_field(ebmeta.dst_mirror_out, ebheader.dst_mirror_out);
 remove_header(ebheader);
}
# 15 "/media/psf/Home/trees/bfn/p4examples/cases/002314/p4src/balancer.p4" 2


control ingress {

 apply(determine_port_type);


 apply(determine_nat_lanwan_flag_and_linked_port);
 apply(calc_dpi_hash);
 apply(set_dpi_output);



}

control egress {

 apply(add_ebheader);

 apply(remove_ebheader);
}
