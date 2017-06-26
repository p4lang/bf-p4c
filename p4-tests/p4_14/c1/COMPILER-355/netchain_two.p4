# 1 "netchain.p4"
# 1 "<built-in>" 1
# 1 "<built-in>" 3
# 170 "<built-in>" 3
# 1 "<command line>" 1
# 1 "<built-in>" 2
# 1 "netchain.p4" 2
# 17 "netchain.p4"
# 1 "./routing.p4" 1
# 17 "./routing.p4"
# 1 "./includes/headers.p4" 1
# 17 "./includes/headers.p4"
header_type ethernet_t {
    fields {
        dstAddr : 48;
        srcAddr : 48;
        etherType : 16;
    }
}
header ethernet_t ethernet;

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
header ipv4_t ipv4;

header_type tcp_t {
    fields {
        srcPort : 16;
        dstPort : 16;
        seqNo : 32;
        ackNo : 32;
        dataOffset : 4;
        res : 3;
        ecn : 3;
        ctrl : 6;
        window : 16;
        checksum : 16;
        urgentPtr : 16;
    }
}
header tcp_t tcp;

header_type udp_t {
    fields {
        srcPort : 16;
        dstPort : 16;
        hdr_length : 16;
        checksum : 16;
    }
}
header udp_t udp;

header_type netchain_hdr_t {
    fields {
        op : 8;
        key : 64;
        seq : 32;
    }
}

@pragma pa_atomic ingress netchain_hdr.seq
header netchain_hdr_t netchain_hdr;

header_type netchain_val_t {
    fields {
        val1 : 32;
        val2 : 32;
    }
}

@pragma pa_atomic ingress netchain_value.val1
@pragma pa_atomic ingress netchain_value.val2
header netchain_val_t netchain_value;

header_type user_metadata_t {
    fields {
        key_exist : 1;
        write_valid : 1;
        seq_index : 16;
        val_index1 : 16;
        val_index2 : 16;
    }
}
metadata user_metadata_t md;
# 18 "./routing.p4" 2
# 1 "./includes/parser.p4" 1
# 17 "./includes/parser.p4"
parser start {
    return parse_ethernet;
}

parser parse_ethernet {
    extract(ethernet);
    return select(latest.etherType) {
        0x0800 : parse_ipv4;
    }
}

parser parse_ipv4 {
    extract(ipv4);
    return select(latest.protocol) {
        6 : parse_tcp;
        17: parse_udp;
    }
}

parser parse_tcp {
    extract(tcp);
    return ingress;
}

parser parse_udp {
    extract(udp);
    return select(latest.dstPort) {
        8888 : parse_netchain;
        default: ingress;
    }
}

parser parse_netchain {
    extract(netchain_hdr);
    return select(latest.op) {
        1 : parse_netchain_val;
        default: ingress;
    }
}

parser parse_netchain_val {
    extract(netchain_value);
    return ingress;
}
# 19 "./routing.p4" 2
# 1 "/Users/mike/Barefoot/depot/p4c-tofino/p4c_tofino/target/tofino/p4_lib/tofino/intrinsic_metadata.p4" 1
# 10 "/Users/mike/Barefoot/depot/p4c-tofino/p4c_tofino/target/tofino/p4_lib/tofino/intrinsic_metadata.p4"
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
# 379 "/Users/mike/Barefoot/depot/p4c-tofino/p4c_tofino/target/tofino/p4_lib/tofino/intrinsic_metadata.p4"
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
# 422 "/Users/mike/Barefoot/depot/p4c-tofino/p4c_tofino/target/tofino/p4_lib/tofino/intrinsic_metadata.p4"
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
# 20 "./routing.p4" 2

action set_egress(egress_spec) {
    modify_field(ig_intr_md_for_tm.ucast_egress_port, egress_spec);
}

table ipv4_routing {
    reads {
        ipv4.dstAddr : lpm;
    }
    actions {
        set_egress;
        _no_op;
    }
    size : 512;
}

action _no_op() {
    no_op();
}

action _drop() {
    drop();
}
# 18 "netchain.p4" 2
# 1 "/Users/mike/Barefoot/depot/p4c-tofino/p4c_tofino/target/tofino/p4_lib/tofino/stateful_alu_blackbox.p4" 1


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
# 81 "/Users/mike/Barefoot/depot/p4c-tofino/p4c_tofino/target/tofino/p4_lib/tofino/stateful_alu_blackbox.p4"
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
# 214 "/Users/mike/Barefoot/depot/p4c-tofino/p4c_tofino/target/tofino/p4_lib/tofino/stateful_alu_blackbox.p4"
        type: string;
        optional;
    }

    attribute stateful_logging_mode {
# 228 "/Users/mike/Barefoot/depot/p4c-tofino/p4c_tofino/target/tofino/p4_lib/tofino/stateful_alu_blackbox.p4"
        type: string;
        optional;
    }
# 246 "/Users/mike/Barefoot/depot/p4c-tofino/p4c_tofino/target/tofino/p4_lib/tofino/stateful_alu_blackbox.p4"
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
# 19 "netchain.p4" 2

action get_index(seq_idx, val_idx1, val_idx2) {
    modify_field(md.seq_index, seq_idx);
    modify_field(md.val_index1, val_idx1);
    modify_field(md.val_index2, val_idx2);
    modify_field(md.key_exist, 1);
}

table netchain_index {
    reads {
        netchain_hdr.key : exact;
    }
    actions {
        get_index;
    }
    size: 65536;
}

register seq_register {
    width: 32;
    instance_count: 65536;
}

blackbox stateful_alu seq_alu {
    reg: seq_register;
    condition_lo : netchain_hdr.seq > register_lo;
    update_lo_1_predicate : condition_lo;
    update_lo_1_value : netchain_hdr.seq;

    output_value: combined_predicate;
    output_dst: md.write_valid;
}

action run_seq_alu() {
    seq_alu.execute_stateful_alu(md.seq_index);
}

table netchain_seq_check {
    actions {
        run_seq_alu;
    }
    size: 1;
}

register value_register_1 {
    width: 32;
    instance_count: 65536;
}

register value_register_2 {
    width: 32;
    instance_count: 65536;
}

blackbox stateful_alu value_alu_1 {
    reg: value_register_1;
    condition_lo : md.write_valid == 1;
    update_lo_1_predicate : condition_lo;
    update_lo_1_value : netchain_value.val1;

    output_value: alu_lo;
    output_dst: netchain_value.val1;
}

blackbox stateful_alu value_alu_2 {
    reg: value_register_2;
    condition_lo : md.write_valid == 1;
    update_lo_1_predicate : condition_lo;
    update_lo_1_value : netchain_value.val2;

    output_value: alu_lo;
    output_dst: netchain_value.val2;
}

action run_value_alu_1() {
    value_alu_1.execute_stateful_alu(md.val_index1);
}

action run_value_alu_2() {
    value_alu_2.execute_stateful_alu(md.val_index2);
}

table netchain_value_1 {
    actions {
        run_value_alu_1;
    }
    size : 1;
}

table netchain_value_2 {
    actions {
        run_value_alu_2;
    }
    size : 1;
}

control ingress {

    if(valid(netchain_hdr)) {
        apply(netchain_index);
        if(md.key_exist == 1) {
            if(netchain_hdr.op == 1) {
                apply(netchain_seq_check);
            }
            apply(netchain_value_1);
            apply(netchain_value_2);
        }
    }

    apply(ipv4_routing);
}

control egress {

}
