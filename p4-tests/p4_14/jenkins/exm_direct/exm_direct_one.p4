# 1 "exm_direct.p4"
# 1 "<built-in>" 1
# 1 "<built-in>" 3
# 170 "<built-in>" 3
# 1 "<command line>" 1
# 1 "<built-in>" 2
# 1 "exm_direct.p4" 2
# 17 "exm_direct.p4"
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
# 18 "exm_direct.p4" 2
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
# 19 "exm_direct.p4" 2
# 1 "../../submodules/p4c-tofino/p4c_tofino/target/tofino/p4_lib/tofino/constants.p4" 1
# 20 "exm_direct.p4" 2


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

action egress_port(egress_port) {
    modify_field(ig_intr_md_for_tm.ucast_egress_port, egress_port);
}

action hop(ttl, egress_port) {
    add_to_field(ttl, -1);
    modify_field(ig_intr_md_for_tm.ucast_egress_port, egress_port);
}

action hop_ipv4(egress_port ) {
    hop(ipv4.ttl, egress_port);


}

action drop_ipv4 () {
    drop();
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

action ig_drop() {

    add_to_field(ipv4.ttl, -1);
    modify_field(ig_intr_md_for_tm.ucast_egress_port, 1);
}

action mod_mac_addr(egress_port, srcmac, dstmac) {
    modify_field(ig_intr_md_for_tm.ucast_egress_port, egress_port);
    modify_field(ethernet.srcAddr, srcmac);
    modify_field(ethernet.dstAddr, dstmac);
}

action udp_hdr_add (egress_port) {
    modify_field(ig_intr_md_for_tm.ucast_egress_port, egress_port);
    add_header(udp);
    modify_field(ipv4.protocol, 17);
    add_to_field(ipv4.totalLen, 8);
}

action tcp_hdr_rm (egress_port) {
    modify_field(ig_intr_md_for_tm.ucast_egress_port, egress_port);
    remove_header(tcp);
    modify_field(ipv4.protocol, 0);


}

action modify_tcp_dst_port(dstPort) {
    modify_field(tcp.dstPort, dstPort);
}

action modify_tcp_dst_port_1(dstPort, egress_port) {
    modify_field(tcp.dstPort, dstPort);
    modify_field(ig_intr_md_for_tm.ucast_egress_port, egress_port);
}

action custom_action_1(egress_port, ipAddr, dstAddr, tcpPort)
{
    modify_field(ig_intr_md_for_tm.ucast_egress_port, egress_port);
    modify_field(ipv4.srcAddr, ipAddr);
    modify_field(ethernet.dstAddr, dstAddr);
    modify_field(tcp.dstPort, tcpPort);
}

action custom_action_2(egress_port, ipAddr, tcpPort)
{
    modify_field(ipv4.srcAddr, ipAddr);
    modify_field(tcp.dstPort, tcpPort);
    hop(ipv4.ttl, egress_port);
}

action custom_action_3(egress_port, dstAddr, dstIp)
{
    modify_field(ipv4.dstAddr, dstIp);
    modify_field(ethernet.dstAddr, dstAddr);
    hop(ipv4.ttl, egress_port);
}

action custom_action_4(egress_port, dstPort, srcPort)
{
    modify_field(tcp.dstPort, dstPort);
    modify_field(tcp.srcPort, srcPort);
    modify_field(ig_intr_md_for_tm.ucast_egress_port, egress_port);
}

action custom_action_5(dstPort, srcPort)
{
    modify_field(tcp.dstPort, dstPort);
    modify_field(tcp.srcPort, srcPort);
}

action switching_action_1(egress_port )
{
    modify_field(ig_intr_md_for_tm.ucast_egress_port, egress_port);

}

action nhop_set(egress_port ,srcmac, dstmac) {
    hop(ipv4.ttl, egress_port);
    modify_field(ethernet.srcAddr, srcmac);
    modify_field(ethernet.dstAddr, dstmac);
}

action nhop_set_1(port) {
    modify_field(ig_intr_md_for_tm.ucast_egress_port, port);
}

@pragma command_line --placement pragma
@pragma command_line --no-dead-code-elimination
@pragma stage 0
@pragma pack 5
@pragma ways 5

table exm_5ways_5Entries {
    reads {
        ipv4.dstAddr : exact;
        ipv4.srcAddr : exact;
        tcp.srcPort : exact;
    }
    actions {
        nop;
        custom_action_3;
    }

    size : 25600;
}

@pragma stage 1
@pragma pack 5
@pragma ways 6

table exm_6ways_5Entries {
    reads {
        ethernet.dstAddr : exact;
        ipv4.dstAddr : exact;
        tcp.dstPort : exact;
    }
    actions {
        nop;
        next_hop_ipv4;
    }
    size : 30720;
}

@pragma stage 2
@pragma pack 6
@pragma ways 4

table exm_4ways_6Entries {
    reads {
        ethernet.dstAddr : exact;
        ethernet.srcAddr : exact;
    }
    actions {
        nop;
        custom_action_1;
    }
    size : 24576;
}

@pragma stage 3
@pragma pack 6
@pragma ways 5

table exm_5ways_6Entries {
    reads {
        ethernet.dstAddr : exact;
    }
    actions {
        nop;
        custom_action_2;
    }
    size : 30720;
}

@pragma stage 4
@pragma pack 6
@pragma ways 6

table exm_6ways_6Entries {
    reads {
        ethernet.dstAddr : exact;
        tcp.srcPort : exact;
    }
    actions {
        nop;
        mod_mac_addr;
    }
    size : 36864;
}

@pragma stage 5
@pragma pack 7
@pragma ways 3

table exm_3ways_7Entries {
    reads {
        ipv4.dstAddr : exact;
    }
    actions {
        nop;
        next_hop_ipv4;
    }
    size : 21504;
}

@pragma stage 6
@pragma pack 8
@pragma ways 4

table exm_4ways_8Entries {
    reads {
        ipv4.dstAddr : exact;
        ipv4.srcAddr : exact;
    }
    actions {
        nop;
        modify_tcp_dst_port_1;
    }
    size : 32768;
}

field_list ecmp_hash_fields {
    ipv4.srcAddr;
    ipv4.dstAddr;
    ipv4.identification;
    ipv4.protocol;
}

field_list_calculation ecmp_hash {
    input {
        ecmp_hash_fields;
    }



    algorithm : random;

    output_width : 72;
}

@pragma stage 7
@pragma selector_max_group_size 119040

table tcp_port_select {
    reads {
            ipv4.dstAddr: lpm;
    }
    action_profile : tcp_port_action_profile;
    size : 512;
}

action_profile tcp_port_action_profile {
    actions {
        tcp_port_modify;
        nop;
    }
    size : 131072;

    dynamic_action_selection : ecmp_selector;
}

action_selector ecmp_selector {
    selection_key : ecmp_hash;

    selection_mode : resilient;
}

@pragma stage 8

@pragma selector_max_group_size 100
table tcp_port_select_exm {
    reads {
            ipv4.dstAddr: exact;
    }
    action_profile : tcp_port_action_profile_exm;
    size : 512;
}

action_profile tcp_port_action_profile_exm {
    actions {
        tcp_port_modify;
        nop;
    }

    size : 2048;
    dynamic_action_selection : fair_selector;
}

action_selector fair_selector {
    selection_key : ecmp_hash;

    selection_mode : non_resilient;
}

action tcp_port_modify(sPort, port) {
    modify_field(tcp.srcPort, sPort);
    modify_field(ig_intr_md_for_tm.ucast_egress_port, port);
}

@pragma immediate 1
@pragma stage 9
@pragma include_idletime 1
@pragma idletime_precision 2
table idle_tcam_2 {
    reads {
        ipv4.dstAddr : lpm;
    }
    actions {
      nop;
      hop_ipv4;
    }
    size : 512;
    support_timeout: true;
}

@pragma immediate 1
@pragma stage 9
@pragma include_idletime 1
@pragma idletime_precision 6
table idle_tcam_6 {
    reads {
        ipv4.dstAddr : lpm;
    }
    actions {
      nop;
      hop_ipv4;
    }
    size : 512;
    support_timeout: true;
}

@pragma immediate 1
@pragma stage 9
@pragma include_idletime 1
@pragma idletime_precision 3
@pragma idletime_per_flow_idletime 0
table idle_tcam_3d {
    reads {
        ipv4.dstAddr : lpm;
    }
    actions {
      nop;
      hop_ipv4;
    }
    size : 512;
    support_timeout: true;
}

@pragma immediate 1
@pragma stage 9
@pragma include_idletime 1
@pragma idletime_precision 6
@pragma idletime_per_flow_idletime 0
table idle_tcam_6d {
    reads {
        ipv4.dstAddr : lpm;
    }
    actions {
      nop;
      hop_ipv4;
    }
    size : 512;
    support_timeout: true;
}

@pragma stage 9
@pragma pack 1
@pragma ways 4
table exm_movereg {
    reads {
        ipv4.dstAddr : exact;
    }
    actions {
        nop;
        next_hop_ipv4;
    }
    size : 4096;
}

counter exm_cnt {
    type : packets;
    direct : exm_movereg;
}

@pragma immediate 1
@pragma stage 10
@pragma include_idletime 1
@pragma idletime_precision 1
table idle_tcam_1 {
    reads {
        ipv4.dstAddr : lpm;
    }
    actions {
      nop;
      hop_ipv4;
    }
    size : 512;
    support_timeout: true;
}

@pragma immediate 1
@pragma stage 10
@pragma include_idletime 1
@pragma idletime_precision 2
table idle_2 {
    reads {
        ipv4.dstAddr : exact;
    }
    actions {
      nop;
      hop_ipv4;
    }
    size : 1024;
    support_timeout: true;
}

@pragma immediate 1
@pragma stage 10
@pragma include_idletime 1
@pragma idletime_precision 3
table idle_3 {
    reads {
        ipv4.dstAddr : exact;
    }
    actions {
      nop;
      hop_ipv4;
    }
    size : 1024;
    support_timeout: true;
}

@pragma immediate 1
@pragma stage 10
@pragma include_idletime 1
@pragma idletime_precision 6
table idle_6 {
    reads {
        ipv4.dstAddr : exact;
    }
    actions {
      nop;
      hop_ipv4;
    }
    size : 1024;
    support_timeout: true;
}

@pragma immediate 1
@pragma stage 11
@pragma include_idletime 1
@pragma idletime_precision 3
table idle_tcam_3 {
    reads {
        ipv4.dstAddr : lpm;
    }
    actions {
      nop;
      hop_ipv4;
    }
    size : 12288;
    support_timeout: true;
}



control ingress {





    apply(exm_5ways_5Entries);
    apply(exm_6ways_5Entries);
    apply(exm_4ways_6Entries);
    apply(exm_5ways_6Entries);
    apply(exm_6ways_6Entries);
    apply(exm_3ways_7Entries);
    apply(exm_4ways_8Entries);

    apply(tcp_port_select);

    apply(tcp_port_select_exm);

    apply(idle_tcam_2);
    apply(idle_tcam_6);
    apply(idle_tcam_3d);
    apply(idle_tcam_6d);
    apply(exm_movereg);

    apply(idle_tcam_1);
    apply(idle_2);
    apply(idle_3);
    apply(idle_6);

    apply(idle_tcam_3);
}

action eg_drop() {
    modify_field(ig_intr_md_for_tm.ucast_egress_port, 0);
    modify_field(intrinsic_metadata.egress_port, 0);
}

action permit() {
}

table egress_acl {
    reads {
        routing_metadata.drop: ternary;
    }
    actions {
        permit;
        eg_drop;
    }
}

control egress {

}
