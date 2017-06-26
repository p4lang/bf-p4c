# 1 "meters.p4"
# 1 "<built-in>" 1
# 1 "<built-in>" 3
# 170 "<built-in>" 3
# 1 "<command line>" 1
# 1 "<built-in>" 2
# 1 "meters.p4" 2
# 17 "meters.p4"
# 1 "./tofino.p4" 1
# 38 "./tofino.p4"
header_type intrinsic_metadata_t {
    fields {

        ingress_port : 9;
        packet_length : 16;

        eg_ucast_port : 32;
        eg_queue : 6;
        eg_mcast_group1 : 16;
        eg_mcast_group2 : 16;
        copy_to_cpu : 1;
        cos_for_copy_to_cpu : 3;
        egress_port : 32;
        egress_instance : 16;
        instance_type : 2;
        parser_status : 8;
        parser_error_location : 8;


        global_version_num : 32;
        ingress_global_timestamp : 48;
        egress_global_timestamp : 48;
        ingress_mac_timestamp : 48;



        mcast_hash1 : 13;
        mcast_hash2 : 13;
        deflect_on_drop : 1;
        meter1 : 3;
        meter2 : 3;
        enq_qdepth : 19;
        enq_congest_stat : 2;
        enq_timestamp : 32;
        deq_qdepth : 19;
        deq_congest_stat : 2;
        deq_timedelta : 32;

    }
}

metadata intrinsic_metadata_t intrinsic_metadata;
# 18 "meters.p4" 2
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
# 19 "meters.p4" 2
# 1 "../../submodules/p4c-tofino/p4c_tofino/target/tofino/p4_lib/tofino/constants.p4" 1
# 20 "meters.p4" 2
# 1 "../../submodules/p4c-tofino/p4c_tofino/target/tofino/p4_lib/tofino/lpf_blackbox.p4" 1


blackbox_type lpf {

    attribute filter_input {


        type: bit<0>;
    }

    attribute direct {


        type: table;
        optional;
    }

    attribute static {


        type: table;
        optional;
    }

    attribute instance_count {

        type: int;
        optional;
    }
# 48 "../../submodules/p4c-tofino/p4c_tofino/target/tofino/p4_lib/tofino/lpf_blackbox.p4"
    method execute (out bit<0> destination, optional in int index){
        reads {filter_input}
    }
}
# 21 "meters.p4" 2


header_type ethernet_t {
    fields {
        dstAddr : 48;
        srcAddr : 48;
        etherType : 16;
    }
}

header_type vlan_tag_t {
    fields {
        pri : 3;
        cfi : 1;
        vlan_id : 12;
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

header_type udp_t {
    fields {
        srcPort : 16;
        dstPort : 16;
        hdr_length : 16;
        checksum : 16;
    }
}

parser start {
    return parse_ethernet;
}

header ethernet_t ethernet;

parser parse_ethernet {
    extract(ethernet);
    return select(latest.etherType) {
        0x8100 : parse_vlan_tag;
        0x800 : parse_ipv4;
        0x86dd : parse_ipv6;
        default: ingress;
    }
}




header ipv4_t ipv4;
header ipv6_t ipv6;

parser parse_ipv4 {
    extract(ipv4);
    return select(latest.fragOffset, latest.protocol) {
        6 : parse_tcp;
        17 : parse_udp;
        default: ingress;
    }
}

parser parse_ipv6 {
    extract(ipv6);
    return select(latest.nextHdr) {
        6 : parse_tcp;
        17 : parse_udp;
        default : ingress;
    }
}

header vlan_tag_t vlan_tag;

parser parse_vlan_tag {
    extract(vlan_tag);
    return select(latest.etherType) {
        0x800 : parse_ipv4;
        default : ingress;
    }
}

header tcp_t tcp;

parser parse_tcp {
    extract(tcp);
    return ingress;
}

header udp_t udp;

parser parse_udp {
    extract(udp);
    return ingress;
}

header_type routing_metadata_t {
    fields {
        drop: 1;
    }
}

metadata routing_metadata_t routing_metadata;

field_list ipv4_field_list {
    ipv4.version;
    ipv4.ihl;
    ipv4.diffserv;
    ipv4.totalLen;
    ipv4.identification;
    ipv4.flags;
    ipv4.fragOffset;
    ipv4.ttl;
    ipv4.protocol;
    ipv4.srcAddr;
    ipv4.dstAddr;
}

field_list_calculation ipv4_chksum_calc {
    input {
        ipv4_field_list;
    }
    algorithm : csum16;
    output_width: 16;
}

calculated_field ipv4.hdrChecksum {
    update ipv4_chksum_calc;
}

action nop() {
}

action hop(ttl, egress_port) {
    add_to_field(ttl, -1);
    modify_field(ig_intr_md_for_tm.ucast_egress_port, egress_port);
}

action next_hop_ipv4(egress_port ,srcmac, dstmac) {
    hop(ipv4.ttl, egress_port);
    modify_field(ethernet.srcAddr, srcmac);
    modify_field(ethernet.dstAddr, dstmac);
}


action next_hop_ipv6(egress_port ,srcmac, dstmac) {
    hop(ipv6.hopLimit, egress_port);
    modify_field(ethernet.srcAddr, srcmac);
    modify_field(ethernet.dstAddr, dstmac);
}

meter meter_0 {
    type : bytes;
    static : meter_tbl;
    result : ipv4.diffserv;
    instance_count : 500;
}

meter meter_1 {
    type : bytes;
    direct : meter_tbl_direct;
    result : ipv4.diffserv;
}


@pragma meter_pre_color_aware_per_flow_enable 1
meter meter_2 {
    type : bytes;
    static : meter_tbl_color_aware_indirect;
    result : ipv4.diffserv;
    pre_color : ipv4.diffserv;
    instance_count : 500;
}

meter meter_3 {
    type : bytes;
    direct : meter_tbl_color_aware_direct;
    result : ipv4.diffserv;
    pre_color : ipv4.diffserv;
}

blackbox lpf meter_lpf {
    filter_input : ipv4.srcAddr;
    instance_count : 500;
}


blackbox lpf meter_lpf_tcam {
   filter_input : ipv4.srcAddr;
   static : match_tbl_tcam_lpf;
   instance_count : 500;
}

blackbox lpf meter_lpf_direct {
    filter_input : ipv4.srcAddr;
    direct : match_tbl_lpf_direct;
}

blackbox lpf meter_lpf_tcam_direct {
    filter_input : ipv4.srcAddr;
    direct : match_tbl_tcam_lpf_direct;
}

action meter_action (egress_port, srcmac, dstmac, idx) {
    next_hop_ipv4(egress_port, srcmac, dstmac);
    execute_meter(meter_0, idx, ipv4.diffserv);
}

action meter_action_color_aware (egress_port, srcmac, dstmac, idx) {
    next_hop_ipv4(egress_port, srcmac, dstmac);
    execute_meter(meter_2, idx, ipv4.diffserv, ipv4.diffserv);
}

action count_color(color_idx) {
    count(colorCntr, color_idx);
}

action next_hop_ipv4_lpf(egress_port ,srcmac, dstmac, lpf_idx) {
    hop(ipv4.ttl, egress_port);
    modify_field(ethernet.srcAddr, srcmac);
    modify_field(ethernet.dstAddr, dstmac);
    meter_lpf.execute(ipv4.srcAddr, lpf_idx);
}

action next_hop_ipv4_direct_lpf(egress_port ,srcmac, dstmac) {
    hop(ipv4.ttl, egress_port);
    modify_field(ethernet.srcAddr, srcmac);
    modify_field(ethernet.dstAddr, dstmac);
    meter_lpf_direct.execute(ipv4.srcAddr);
}

action next_hop_ipv4_lpf_tcam(egress_port ,srcmac, dstmac, lpf_idx) {
    hop(ipv4.ttl, egress_port);
    modify_field(ethernet.srcAddr, srcmac);
    modify_field(ethernet.dstAddr, dstmac);
    meter_lpf_tcam.execute(ipv4.srcAddr, lpf_idx);
}

action next_hop_ipv4_lpf_direct_tcam(egress_port ,srcmac, dstmac) {
    hop(ipv4.ttl, egress_port);
    modify_field(ethernet.srcAddr, srcmac);
    modify_field(ethernet.dstAddr, dstmac);
    meter_lpf_tcam_direct.execute(ipv4.srcAddr);
}

counter colorCntr {
    type : packets;
    static : color_match;
    instance_count : 100;
}

@pragma command_line --placement pragma
@pragma command_line --no-dead-code-elimination
@pragma stage 1
table meter_tbl {
    reads {
        ipv4.dstAddr : exact;
    }
    actions {
        nop;
        meter_action;
    }
}

@pragma stage 0
table meter_tbl_direct {
    reads {
        ipv4.dstAddr : exact;
        ipv4.srcAddr : exact;
    }
    actions {
        nop;
        next_hop_ipv4;
    }
}

@pragma stage 2
table meter_tbl_color_aware_indirect {
    reads {
        ipv4.dstAddr : exact;
        ipv4.srcAddr : exact;
    }
    actions {
        nop;
        meter_action_color_aware;
    }
}


@pragma stage 3
table meter_tbl_color_aware_direct {
    reads {
        ipv4.dstAddr : exact;
        ipv4.srcAddr : exact;
    }
    actions {
        next_hop_ipv4;
    }
    default_action : nop();
}

@pragma stage 4
table match_tbl_lpf {
    reads {
        ipv4.dstAddr : exact;
        ipv4.srcAddr : exact;
    }
    actions {
        next_hop_ipv4_lpf;
    }
    default_action : nop();
}

@pragma stage 4
table match_tbl_tcam_lpf {
    reads {
        ipv4.dstAddr : ternary;
        ipv4.srcAddr : ternary;
    }
    actions {
        next_hop_ipv4_lpf_tcam;
    }
    default_action : nop();
}


@pragma stage 5
table match_tbl_lpf_direct {
    reads {
        ipv4.dstAddr : exact;
        ipv4.srcAddr : exact;
    }
    actions {
        next_hop_ipv4_direct_lpf;
    }
    default_action : nop();
}

@pragma stage 5
table match_tbl_tcam_lpf_direct {
    reads {
        ipv4.dstAddr : ternary;
        ipv4.srcAddr : ternary;
    }
    actions {
        next_hop_ipv4_lpf_direct_tcam;
    }
    default_action : nop();
}


@pragma stage 11
table color_match {
    reads {
        ethernet.dstAddr: exact;
        ipv4.diffserv: exact;
    }
    actions {
        count_color;
    }
    size : 256;
}



control ingress {





    apply(meter_tbl_direct);
    apply(meter_tbl);
    apply(meter_tbl_color_aware_indirect);
    apply(meter_tbl_color_aware_direct);
    apply(match_tbl_lpf);
    apply(match_tbl_tcam_lpf);
    apply(match_tbl_lpf_direct);
    apply(match_tbl_tcam_lpf_direct);
    apply(color_match);
}

control egress {

}
