# 1 "pgrs.p4"
# 1 "<built-in>" 1
# 1 "<built-in>" 3
# 170 "<built-in>" 3
# 1 "<command line>" 1
# 1 "<built-in>" 2
# 1 "pgrs.p4" 2


# 1 "../../submodules/p4c-tofino/p4c_tofino/target/tofino/p4_lib/tofino/constants.p4" 1
# 4 "pgrs.p4" 2
# 1 "../../submodules/p4c-tofino/p4c_tofino/target/tofino/p4_lib/tofino/intrinsic_metadata.p4" 1
# 10 "../../submodules/p4c-tofino/p4c_tofino/target/tofino/p4_lib/tofino/intrinsic_metadata.p4"
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
# 379 "../../submodules/p4c-tofino/p4c_tofino/target/tofino/p4_lib/tofino/intrinsic_metadata.p4"
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
# 422 "../../submodules/p4c-tofino/p4c_tofino/target/tofino/p4_lib/tofino/intrinsic_metadata.p4"
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
# 5 "pgrs.p4" 2
# 1 "../../submodules/p4c-tofino/p4c_tofino/target/tofino/p4_lib/tofino/pktgen_headers.p4" 1








header_type pktgen_generic_header_t {
    fields {
        _pad0 : 3;
        app_id : 3;
        pipe_id : 2;
        key_msb : 8;
        batch_id : 16;

        packet_id : 16;
    }
}
header pktgen_generic_header_t pktgen_generic;

header_type pktgen_timer_header_t {
    fields {
        _pad0 : 3;
        app_id : 3;
        pipe_id : 2;
        _pad1 : 8;
        batch_id : 16;
        packet_id : 16;
    }
}
header pktgen_timer_header_t pktgen_timer;

header_type pktgen_port_down_header_t {
    fields {
        _pad0 : 3;
        app_id : 3;
        pipe_id : 2;
        _pad1 : 15;
        port_num : 9;
        packet_id : 16;
    }
}
header pktgen_port_down_header_t pktgen_port_down;

header_type pktgen_recirc_header_t {
    fields {
        _pad0 : 3;
        app_id : 3;
        pipe_id : 2;
        key : 24;
        packet_id : 16;
    }
}
header pktgen_recirc_header_t pktgen_recirc;
# 6 "pgrs.p4" 2




@pragma pa_alias ingress ig_intr_md.ingress_port ingress_metadata.ingress_port

header_type pktgen_header_t {
    fields {
        id : 8;
    }

}

header pktgen_header_t pgen_header;

parser start {
    extract(pgen_header);
    return select(latest.id) {
        0x00 mask 0x1F: pktgen_port_down;
        0x04 mask 0x1F: pktgen_timer;
        0x08 mask 0x1F: pktgen_recirc;
        0x0C mask 0x1F: pktgen_timer;
        0x10 mask 0x1F: pktgen_timer;
        0x14 mask 0x1F: pktgen_timer;
        0x18 mask 0x1F: pktgen_timer;
        0x1C mask 0x1F: pktgen_timer;
        0x01 mask 0x1F: pktgen_timer;
        0x05 mask 0x1F: pktgen_port_down;
        0x09 mask 0x1F: pktgen_timer;
        0x0D mask 0x1F: pktgen_recirc;
        0x11 mask 0x1F: pktgen_timer;
        0x15 mask 0x1F: pktgen_timer;
        0x19 mask 0x1F: pktgen_timer;
        0x1D mask 0x1F: pktgen_timer;
        0x02 mask 0x1F: pktgen_timer;
        0x06 mask 0x1F: pktgen_timer;
        0x0A mask 0x1F: pktgen_port_down;
        0x0E mask 0x1F: pktgen_timer;
        0x12 mask 0x1F: pktgen_recirc;
        0x16 mask 0x1F: pktgen_timer;
        0x1A mask 0x1F: pktgen_timer;
        0x1E mask 0x1F: pktgen_timer;
        0x03 mask 0x1F: pktgen_timer;
        0x07 mask 0x1F: pktgen_timer;
        0x0B mask 0x1F: pktgen_timer;
        0x0F mask 0x1F: pktgen_port_down;
        0x13 mask 0x1F: pktgen_timer;
        0x17 mask 0x1F: pktgen_recirc;
        0x1B mask 0x1F: pktgen_timer;
        0x1F mask 0x1F: pktgen_timer;
        default: ingress;
    }
}

parser pktgen_timer {
    set_metadata(ig_md.pktgen_type, 0);
    return pktgen_done;
}
parser pktgen_port_down {
    set_metadata(ig_md.pktgen_type, 2);
    return pktgen_done;
}
parser pktgen_recirc {
    set_metadata(ig_md.pktgen_type, 3);
    return pktgen_done;
}
parser pktgen_done {
    return ingress;
}


header_type ig_md_t {
    fields {
        skip_lkups : 1;
        pktgen_port : 1;
        pktgen_type : 2;
        test_recirc : 1;
    }
}
metadata ig_md_t ig_md;

action set_md(eg_port, skip, pktgen_port, test_recirc, mgid1, mgid2) {
    modify_field(ig_intr_md_for_tm.ucast_egress_port, eg_port);
    modify_field(ig_md.skip_lkups, skip);
    modify_field(ig_md.pktgen_port, pktgen_port);
    modify_field(ig_md.test_recirc, test_recirc);
    modify_field(ig_intr_md_for_tm.mcast_grp_a, mgid1);
    modify_field(ig_intr_md_for_tm.mcast_grp_b, mgid2);
}

table port_tbl {
    reads {
        ig_intr_md.ingress_port : exact;
    }
    actions {
        set_md;
    }
    size : 288;
}


action timer_ok() {




}
action timer_nok() {
    modify_field(ig_intr_md_for_tm.ucast_egress_port, 6);
}
table pg_verify_timer {
    reads {
        ig_intr_md.ingress_port : exact;
    }
    actions {
        timer_ok;
        timer_nok;
    }
}

action port_down_ok() {
}
action port_down_nok() {
    modify_field(ig_intr_md_for_tm.ucast_egress_port, 6);
}
table pg_verify_port_down {
    reads {
        ig_intr_md.ingress_port : exact;
    }
    actions {
        port_down_ok;
        port_down_nok;
    }
}

action recirc_ok() {
}
action recirc_nok() {
    modify_field(ig_intr_md_for_tm.ucast_egress_port, 6);
}
table pg_verify_recirc {
    reads {
        ig_intr_md.ingress_port : exact;
    }
    actions {
        recirc_ok;
        recirc_nok;
    }
}

action local_recirc(local_port) {

    recirculate( local_port );

}
table do_local_recirc {
    actions { local_recirc; }
}

control ingress {

        apply(port_tbl);

    if (ig_md.skip_lkups == 0) {
        if (ig_md.pktgen_port == 1) {
            if (ig_md.pktgen_type == 0) {
                apply( pg_verify_timer );
            }
            if (ig_md.pktgen_type == 2) {
                apply( pg_verify_port_down );
            }
            if (ig_md.pktgen_type == 3) {
                apply( pg_verify_recirc );
            }
        }
    } else {
        if (ig_md.test_recirc == 1) {
            apply( do_local_recirc );
        }
    }
}

control egress {
}
