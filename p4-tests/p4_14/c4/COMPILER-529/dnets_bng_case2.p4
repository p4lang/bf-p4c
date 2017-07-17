# 1 "dnets_bng.p4"
# 1 "<built-in>" 1
# 1 "<built-in>" 3
# 170 "<built-in>" 3
# 1 "<command line>" 1
# 1 "<built-in>" 2
# 1 "dnets_bng.p4" 2
# 14 "dnets_bng.p4"
# 1 "./headers.p4" 1
# 31 "./headers.p4"
header_type cpu_header_t {
    fields {
        device: 8;
        reason: 8;
    }
}

header_type ethernet_t {
    fields {
        dstAddr : 48;
        srcAddr : 48;
        etherType : 16;
    }
}

header_type mpls_t {
    fields {
 label : 20;
 tc : 3;
 s : 1;
 ttl : 8;
    }
}

header_type vlan_t {
    fields {
        vlanID: 16;
 etherType: 16;
    }
}

header_type pppoe_t {
    fields {
 version : 4;
 typeID : 4;
 code : 8;
 sessionID : 16;
 totalLength : 16;
 protocol : 16;


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
        dstAddr: 32;
    }
}


header_type ipv6_t {
    fields {

        version : 4;

        trafficClass : 8;
        flowLabel : 20;
        payloadLen : 16;
        nextHdr : 8;
        hopLimit : 8;
        srcAddr : 128;
        dstAddr : 128;
    }
}

header_type ipv6_t_us {
    fields {

        version : 4;

        trafficClass : 8;
        flowLabel : 20;
        payloadLen : 16;
        nextHdr : 8;
        hopLimit : 8;
        srcAddr_net : 56;
        srcAddr_netrest : 8;
        dstAddr : 128;
    }
}
header_type ipv6_t_ds {
    fields {

        version : 4;

        trafficClass : 8;
        flowLabel : 20;
        payloadLen : 16;
        nextHdr : 8;
        hopLimit : 8;
        srcAddr : 128;
        dstAddr_net : 56;
        dstAddr_netrest : 8;
    }
}
# 180 "./headers.p4"
header cpu_header_t cpu_header;

parser start {
    return select(current(0, 1)) {
        0 : parse_cpu_header;
        default: parse_ethernet_outer;
    }
}


parser parse_cpu_header {
    extract(cpu_header);
    return parse_ethernet_outer;
}







header ethernet_t ethernet_outer;

parser parse_ethernet_outer {
    extract(ethernet_outer);
    return select(latest.etherType) {
        0x8847 : parse_mpls0;
        default: ingress;
    }
}

header mpls_t mpls0;

parser parse_mpls0 {
    extract(mpls0);
    return select(latest.s) {
 1 : parse_ip;
 default : parse_mpls1;
    }
}

header mpls_t mpls1;

parser parse_mpls1 {
    extract(mpls1);
    return select(latest.s) {
 1 : parse_ethernet_inner;
 default : ingress;
    }
}


header ethernet_t ethernet_inner;

parser parse_ethernet_inner {
    extract(ethernet_inner);
    return select(latest.etherType) {
 0x8100 : parse_vlan_subsc;

        default: ingress;
    }
}

header vlan_t vlan_subsc;
header vlan_t vlan_service;

parser parse_vlan_subsc {
    extract(vlan_subsc);
    return select(latest.etherType) {
 0x8100 : parse_vlan_service;
 0x8863 : parse_pppoe;
 0x8864 : parse_pppoe;
        default: ingress;
    }
}

parser parse_vlan_service {
    extract(vlan_service);
    return select(latest.etherType) {
 0x8863 : parse_pppoe;
 0x8864 : parse_pppoe;
        default: ingress;
    }
}




header pppoe_t pppoe;

parser parse_pppoe {
    extract(pppoe);
    return select(latest.protocol) {
 0x0021: parse_ip;

 0x0057: parse_ip;

 default: ingress;
    }
}

parser parse_ip {


    return select(current(0, 4)) {
        4 : parse_ipv4;

        6 : parse_ipv6;

 default : ingress;
    }
}

header ipv4_t ipv4;

parser parse_ipv4 {
    extract(ipv4);
    return ingress;
}


header ipv6_t ipv6;
header ipv6_t_us ipv6_us;
header ipv6_t_ds ipv6_ds;

parser parse_ipv6 {
    extract(ipv6);
    return ingress;
}
# 15 "dnets_bng.p4" 2


# 1 "../../Barefoot/depot/p4c-tofino/p4c_tofino/target/tofino/p4_lib/tofino/primitives.p4" 1
# 10 "../../Barefoot/depot/p4c-tofino/p4c_tofino/target/tofino/p4_lib/tofino/primitives.p4"
action deflect_on_drop(enable_dod) {
    modify_field(ig_intr_md_for_tm.deflect_on_drop, enable_dod);
}
# 18 "dnets_bng.p4" 2
# 1 "../../Barefoot/depot/p4c-tofino/p4c_tofino/target/tofino/p4_lib/tofino/intrinsic_metadata.p4" 1
# 10 "../../Barefoot/depot/p4c-tofino/p4c_tofino/target/tofino/p4_lib/tofino/intrinsic_metadata.p4"
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



        clone_digest_id : 4;


        clone_src : 4;



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
# 382 "../../Barefoot/depot/p4c-tofino/p4c_tofino/target/tofino/p4_lib/tofino/intrinsic_metadata.p4"
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
# 425 "../../Barefoot/depot/p4c-tofino/p4c_tofino/target/tofino/p4_lib/tofino/intrinsic_metadata.p4"
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
# 19 "dnets_bng.p4" 2
# 1 "../../Barefoot/depot/p4c-tofino/p4c_tofino/target/tofino/p4_lib/tofino/stateful_alu_blackbox.p4" 1


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
# 81 "../../Barefoot/depot/p4c-tofino/p4c_tofino/target/tofino/p4_lib/tofino/stateful_alu_blackbox.p4"
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
# 214 "../../Barefoot/depot/p4c-tofino/p4c_tofino/target/tofino/p4_lib/tofino/stateful_alu_blackbox.p4"
        type: string;
        optional;
    }

    attribute stateful_logging_mode {
# 228 "../../Barefoot/depot/p4c-tofino/p4c_tofino/target/tofino/p4_lib/tofino/stateful_alu_blackbox.p4"
        type: string;
        optional;
    }
# 246 "../../Barefoot/depot/p4c-tofino/p4c_tofino/target/tofino/p4_lib/tofino/stateful_alu_blackbox.p4"
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
# 20 "dnets_bng.p4" 2
# 1 "../../Barefoot/depot/p4c-tofino/p4c_tofino/target/tofino/p4_lib/tofino/pktgen_headers.p4" 1








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
# 21 "dnets_bng.p4" 2
# 31 "dnets_bng.p4"
header_type ingress_md_t {
    fields {
    usds : 2;
    cp : 1;
    line_id : 32;
    subsc_id : 8;

    meter_result : 2;

    }
}

metadata ingress_md_t ingress_md;

action _nop() { }






table t_usds {
 reads {
  ethernet_outer.dstAddr : exact;
  standard_metadata.ingress_port : exact;
  mpls0.label : exact;

 }
 actions {
  a_usds_handle_ds;
  a_usds_handle_us;
  _drop;
 }

 max_size : 256;
}

action a_usds_handle_ds() {
 modify_field(ingress_md.usds, 0x0);
}

action a_usds_handle_us() {
 add_header(vlan_service);



 modify_field(ingress_md.usds, 0x1);
}
# 95 "dnets_bng.p4"
table t_line_map {
 reads {
  standard_metadata.ingress_port : exact;
  mpls0.label : exact;
  mpls1.label : exact;
  vlan_subsc.vlanID : exact;
 }
 actions {
  _drop;
  a_line_map_pass;
 }
 max_size : 4096;
}

action a_line_map_pass(line_id, lawf_int) {
 modify_field(ingress_md.line_id, line_id);


}




table t_pppoe_cpdp {
 reads {
  ethernet_inner.dstAddr : exact;
  vlan_service.etherType : exact;
  pppoe.protocol : exact;
 }
 actions {
  _drop;
  a_pppoe_cpdp_to_cp;
  a_pppoe_cpdp_pass_ip;
 }
 max_size : 16;
}

action a_pppoe_cpdp_to_cp(cp_port) {
 modify_field(ingress_md.cp, 1);
 modify_field(standard_metadata.egress_spec, cp_port);
}

action a_pppoe_cpdp_pass_ip(version) {

}





table t_antispoof_mac {
 reads {
  ingress_md.line_id : exact;
  vlan_service.vlanID : exact;
  ethernet_inner.srcAddr : exact;
  pppoe.sessionID : exact;
 }
 actions {
  _drop;
  a_antispoof_mac_pass;
 }
 max_size : 16384;
}

action a_antispoof_mac_pass(subsc_id, lawf_int, ctr_bucket) {
 modify_field(ingress_md.subsc_id, subsc_id);


 count(ctr_us_subsc, ctr_bucket);
}



counter ctr_us_subsc {
 type : packets;
 instance_count : 4096;
}







table t_antispoof_ipv4 {
 reads {
  ingress_md.line_id : exact;
  ingress_md.subsc_id : exact;
  ipv4.srcAddr : exact;
 }
 actions {
  _drop;
  a_antispoof_ipv4v6_pass;
 }
 max_size : 4096;
}

action a_antispoof_ipv4v6_pass() {
 remove_header(pppoe);
 remove_header(vlan_subsc);
 remove_header(ethernet_inner);
 remove_header(mpls1);



}






table t_antispoof_ipv6 {
 reads {
  ingress_md.line_id : exact;
  ingress_md.subsc_id : exact;
  ipv6.srcAddr : exact;
 }
 actions {
  _drop;
  a_antispoof_ipv4v6_pass;
 }
 max_size : 16384;
}





table t_us_routev4 {
 reads {
  vlan_service.vlanID : exact;



  ipv4.dstAddr : exact;

 }
 actions {
  _drop;
  a_us_routev4v6;
 }
 max_size : 256;
}

action a_us_routev4v6(out_port, mpls_label, via_hwaddr) {
 remove_header(vlan_service);
 modify_field(standard_metadata.egress_spec, out_port);
 modify_field(mpls0.label, mpls_label);
 modify_field(mpls0.s, 1);
 modify_field(ethernet_outer.dstAddr, via_hwaddr);



}





table t_us_routev6 {
 reads {
  vlan_service.vlanID : exact;



  ipv6.dstAddr : exact;
 }
 actions {
  _drop;
  a_us_routev4v6;
 }
 max_size : 256;
}







table t_us_srcmac {
 reads {
  standard_metadata.egress_port : exact;
  mpls0.label : exact;
 }
 actions {
  _nop;
  a_us_srcmac;
 }
}

action a_us_srcmac(src_mac) {
 modify_field(ethernet_outer.srcAddr, src_mac);




}





table t_ds_routev4 {
 reads {



  ipv4.dstAddr : exact;
 }
 actions {
  _drop;
  a_ds_route_pushstack;
 }
 max_size : 16384;
}

action a_ds_route_pushstack(mpls0_label, mpls1_label, subsc_vid, service_vid,
    pppoe_session_id, out_port, inner_cpe_mac, lawf_int, ctr_bucket) {

 modify_field(mpls0.label, mpls0_label);
 modify_field(mpls0.s, 0);
 add_header(mpls1);
 modify_field(mpls1.label, mpls1_label);
 modify_field(mpls1.s, 1);

 add_header(ethernet_inner);
 modify_field(ethernet_inner.dstAddr, inner_cpe_mac);
 modify_field(ethernet_inner.etherType, 0x8100);
 add_header(vlan_subsc);
 modify_field(vlan_subsc.vlanID, subsc_vid);
 modify_field(vlan_subsc.etherType, 0x8100);
 add_header(vlan_service);
 modify_field(vlan_service.vlanID, service_vid);
 modify_field(vlan_service.etherType, 0x8864);
 add_header(pppoe);
 modify_field(pppoe.version, 1);
 modify_field(pppoe.typeID, 1);

 modify_field(pppoe.sessionID, pppoe_session_id);
 modify_field(standard_metadata.egress_spec, out_port);
 count(ctr_ds_subsc, ctr_bucket);
 execute_meter(mtr_ds_subsc, ctr_bucket, ingress_md.meter_result);

}







table t_ds_routev6 {
 reads {
  mpls0.label : exact;



  ipv6.dstAddr : exact;
 }
 actions {
  _drop;
  a_ds_route_pushstack;
 }
 max_size : 16384;
}






counter ctr_ds_subsc {
 type : packets;
 instance_count : 4096;
}






meter mtr_ds_subsc {
 type : bytes;
 instance_count : 4096;

}






table t_meter_action {
 reads {
  ingress_md.meter_result : exact;

 }
 actions {
  _drop;
  a_meter_action_pass;
 }
 max_size : 16;
}

action a_meter_action_pass() {

}
# 413 "dnets_bng.p4"
table t_ds_pppoe_aftermath_v4 {
 actions {
  a_ds_pppoe_aftermath_v4;
 }
}

action a_ds_pppoe_aftermath_v4() {
 add(pppoe.totalLength, ipv4.totalLen, -5);
 modify_field(pppoe.protocol, 0x0021);
}





table t_ds_pppoe_aftermath_v6 {
 actions {
  a_ds_pppoe_aftermath_v6;
 }
}

action a_ds_pppoe_aftermath_v6() {
 add(pppoe.totalLength, ipv6.payloadLen, -8);
 modify_field(pppoe.protocol, 0x0057);
}






table t_ds_srcmac {
 reads {
  standard_metadata.egress_port : exact;
  mpls0.label : exact;


 }
 actions {
  _drop;
  a_ds_srcmac;
 }
 max_size : 256;
}

action a_ds_srcmac(outer_src_mac, outer_dst_mac, inner_src_mac) {

 modify_field(ethernet_outer.srcAddr, outer_src_mac);
 modify_field(ethernet_outer.dstAddr, outer_dst_mac);
 modify_field(ethernet_inner.srcAddr, inner_src_mac);
}




action _drop() {
 modify_field(ingress_md.usds, 0x2);
 drop();
}

control ingress {
 apply(t_usds);
 if (ingress_md.usds == 0x1 and valid(pppoe)) {
  apply(t_line_map);
  apply(t_pppoe_cpdp);
  if (ingress_md.cp == 0) {
   apply(t_antispoof_mac);
   if (valid(ipv4)) {
    apply(t_antispoof_ipv4);
    if (ingress_md.usds == 0x1) apply(t_us_routev4);

   } else if (valid(ipv6)) {
    apply(t_antispoof_ipv6);
    if (ingress_md.usds == 0x1) apply(t_us_routev6);

   }
  }
 } else if (ingress_md.usds == 0x0) {
  if (valid(ipv4)) {
   apply(t_ds_routev4);

  } else if (valid(ipv6)) {
   apply(t_ds_routev6);

  }

  apply(t_meter_action);

 }
}




control egress {
 if (ingress_md.cp == 0) {
  if (ingress_md.usds == 0x1) {
   apply(t_us_srcmac);
  } else {
   if (valid(ipv4)) apply(t_ds_pppoe_aftermath_v4);

   else apply(t_ds_pppoe_aftermath_v6);

   apply(t_ds_srcmac);
  }
 }
}
