# 1 "exm_indirect_1.p4"
# 1 "<built-in>" 1
# 1 "<built-in>" 3
# 170 "<built-in>" 3
# 1 "<command line>" 1
# 1 "<built-in>" 2
# 1 "exm_indirect_1.p4" 2
# 17 "exm_indirect_1.p4"
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
# 18 "exm_indirect_1.p4" 2
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
# 19 "exm_indirect_1.p4" 2
# 1 "../../submodules/p4c-tofino/p4c_tofino/target/tofino/p4_lib/tofino/constants.p4" 1
# 20 "exm_indirect_1.p4" 2


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

action hash_action(value) {
    add_to_field(ipv4.ttl, value);
}

action_profile custom_action_3_profile {
    actions {
        nop;
        custom_action_3;
        egress_port;
    }
    size : 1024;
}

action_profile next_hop_ipv4_profile {
    actions {
        nop;
        next_hop_ipv4;
    }

    size : 2048;
}

action_profile next_hop_ipv4_1_profile {
    actions {
        nop;
        next_hop_ipv4;
    }

    size : 2048;
}

action_profile custom_action_1_profile {
    actions {
        nop;
        custom_action_1;
    }
    size : 2048;
}

action_profile custom_action_2_profile {
    actions {
        nop;
        custom_action_2;
    }
    size : 2048;
}

action_profile mod_mac_addr_profile {
    actions {
        nop;
        mod_mac_addr;
    }
    size : 1024;
}

action_profile modify_tcp_dst_port_1_profile {
    actions {
        nop;
        modify_tcp_dst_port_1;
    }
    size : 1024;
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

    action_profile : custom_action_3_profile;

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

    action_profile : next_hop_ipv4_profile;

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

    action_profile : custom_action_1_profile;

    size : 24576;
}

@pragma stage 3
@pragma pack 6
@pragma ways 5

table exm_5ways_6Entries {
    reads {
        ethernet.dstAddr : exact;
    }

    action_profile : custom_action_2_profile;

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

    action_profile : mod_mac_addr_profile;

    size : 36864;
}

@pragma stage 5
@pragma pack 7
@pragma ways 3

table exm_3ways_7Entries {
    reads {
        ipv4.dstAddr : exact;
    }

    action_profile : next_hop_ipv4_1_profile;

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

    action_profile : modify_tcp_dst_port_1_profile;

    size : 32768;
}

@pragma stage 7

table exm_ipv4_routing {
    reads {
        ethernet.dstAddr : exact;
        ethernet.srcAddr : exact;
        ipv4.dstAddr : exact;
        ipv4.srcAddr : exact;
    }

    action_profile : next_hop_profile;

    size : 32768;
}

action_profile next_hop_profile {
    actions {
        nhop_set;
        nop;
    }
size : 4096;
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

    output_width : 64;
}

@pragma stage 8
table ipv4_routing_select {
    reads {
            ipv4.dstAddr: exact;
    }
    action_profile : ecmp_action_profile;
}

@pragma stage 8
table ipv4_routing_select_iter {
    reads {
            ipv4.dstAddr: exact;
    }
    action_profile : ecmp_action_profile_iter;
}

@pragma stage 9
table stat_tbl_indirect_pkt_64bit {
    reads {
        ethernet.dstAddr : exact;
        ethernet.srcAddr : exact;
    }
    actions {
        act;
    }

    size : 2048;
}

@pragma stage 9
table stat_tbl_indirect_pkt_32bit {
    reads {
        ethernet.dstAddr : exact;
        ethernet.srcAddr : exact;
    }
    actions {
        act2;
    }

    size : 2048;
}

@pragma stage 9
table stat_tbl_indirect_pkt_byte_64bit {
    reads {
        ethernet.dstAddr : exact;
        ethernet.srcAddr : exact;
    }
    actions {
        act5;
    }

    size : 2048;
}

@pragma stage 10
table stat_tbl_direct_pkt_64bit {
    reads {
        ethernet.dstAddr : exact;
        ethernet.srcAddr : exact;
    }
    actions {
        act1;
    }

    size : 2048;
}

@pragma stage 10
table stat_tbl_direct_pkt_32bit {
    reads {
        ethernet.dstAddr : exact;
        ethernet.srcAddr : exact;
    }
    actions {
        act4;
    }

    size : 2048;
}

@pragma stage 11
table stat_tbl_direct_pkt_byte_64bit {
    reads {
        ethernet.dstAddr : exact;
        ethernet.srcAddr : exact;
    }
    actions {
        act1;
    }

    size : 2048;
}

@pragma stage 11
table stat_tbl_direct_pkt_byte_32bit {
    reads {
        ethernet.dstAddr : exact;
        ethernet.srcAddr : exact;
    }
    actions {
        act1;
    }

    size : 2048;
}

table stat_tcam_direct_pkt_64bit {
    reads {
        ipv4.dstAddr : lpm;
    }
    actions {
        egr_act1;
    }

    size : 2048;
}

@pragma stage 11
@pragma use_hash_action 1
table hash_action_exm {
    reads {
        ipv4.ttl : exact;
    }
    actions {
        hash_action;
    }
    default_action : hash_action(1);  // Hmm, frontend doesn't allow negative number in parameter list?
    size : 256;
}

header_type l3_metadata_t {
    fields {
   vrf : 24;
 fib_hit : 1;
 fib_nexthop : 16;
 fib_nexthop_type : 1;
    }
}

metadata l3_metadata_t l3_metadata;

action fib_hit_nexthop(nexthop_index) {
    modify_field(l3_metadata.fib_hit, 1);
    modify_field(l3_metadata.fib_nexthop, nexthop_index);
    modify_field(l3_metadata.fib_nexthop_type, 0);
}

action fib_hit_ecmp(ecmp_index) {
    modify_field(l3_metadata.fib_hit, 1);
    modify_field(l3_metadata.fib_nexthop, ecmp_index);
    modify_field(l3_metadata.fib_nexthop_type, 1);
}

table duplicate_check_exm_immediate_action {
    reads {
        l3_metadata.vrf : exact;
        ipv4.dstAddr : exact;
    }
    actions {
        nop;
        fib_hit_nexthop;
        fib_hit_ecmp;
    }

    size : 2048;
}

action act(idx, egress_port) {
    modify_field(ig_intr_md_for_tm.ucast_egress_port, egress_port);
    count(cntDum, idx);
}

action act1(egress_port) {
    modify_field(ig_intr_md_for_tm.ucast_egress_port, egress_port);
}

action egr_act1(tcp_sport) {
    modify_field(tcp.srcPort, tcp_sport);
}

action act4(egress_port) {
    modify_field(ig_intr_md_for_tm.ucast_egress_port, egress_port);
}

action act2(idx, egress_port) {
    modify_field(ig_intr_md_for_tm.ucast_egress_port, egress_port);
    count(cntDum3, idx);
}

action act5(idx, egress_port) {
    modify_field(ig_intr_md_for_tm.ucast_egress_port, egress_port);
    count(cntDum6, idx);
}

counter cntDum {
    type : packets;
    static : stat_tbl_indirect_pkt_64bit;
    instance_count : 256;
}

counter cntDum3 {
    type : packets;
    static : stat_tbl_indirect_pkt_32bit;
    instance_count : 256;
}

counter cntDum1 {
    type : packets;
    direct : stat_tbl_direct_pkt_64bit;
}

counter cntDum2 {
    type : packets;
    direct : stat_tbl_direct_pkt_32bit;
    min_width : 20;
}

counter cntDum4 {
    type : packets_and_bytes;
    direct : stat_tbl_direct_pkt_byte_64bit;
}

counter cntDum5 {
    type : packets_and_bytes;
    direct : stat_tbl_direct_pkt_byte_32bit;
    min_width : 20;
}

counter cntDum6 {
    type : packets_and_bytes;
    static : stat_tbl_indirect_pkt_byte_64bit;
    instance_count : 256;
}

counter egr_cntDum1 {
    type : packets;
    direct : stat_tcam_direct_pkt_64bit;
}

action_profile ecmp_action_profile {
    actions {
        nop;
        nhop_set_1;
    }
    size : 1024;

    dynamic_action_selection : ecmp_selector;
}

action_profile ecmp_action_profile_iter {
    actions {
        nop;
        nhop_set_1;
    }
    size : 1024;

    dynamic_action_selection : ecmp_selector;
}

action_selector ecmp_selector {
    selection_key : ecmp_hash;

    selection_mode : resilient;
}

action set_ucast_dest(dest) {
    modify_field(ig_intr_md_for_tm.ucast_egress_port, dest);
}

@pragma stage 11
table exm_txn_test {
    reads {
        ig_intr_md.ingress_port : exact;
    }
    actions {
        set_ucast_dest;
    }
    size : 256;
}


control ingress {





    apply(exm_5ways_5Entries);
    apply(exm_6ways_5Entries);
    apply(exm_4ways_6Entries);
    apply(exm_5ways_6Entries);
    apply(exm_6ways_6Entries);
    apply(exm_3ways_7Entries);
    apply(exm_4ways_8Entries);
    apply(exm_ipv4_routing);
    apply(ipv4_routing_select);
    apply(ipv4_routing_select_iter);
    apply(stat_tbl_indirect_pkt_64bit);
    apply(stat_tbl_indirect_pkt_32bit);
    apply(stat_tbl_indirect_pkt_byte_64bit);
    apply(stat_tbl_direct_pkt_64bit);
    apply(stat_tbl_direct_pkt_32bit);
    apply(stat_tbl_direct_pkt_byte_64bit);
    apply(stat_tbl_direct_pkt_byte_32bit);
    apply(hash_action_exm);
    apply(exm_txn_test);
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

action action1() {
    add_to_field(ipv4.ttl, -1);
}

table exm_txn_test1 {
    reads {
        ipv4.dstAddr : exact;
    }
    actions {
        action1;
    }
    size : 4096;
}

control egress {
      apply(stat_tcam_direct_pkt_64bit);
      apply(duplicate_check_exm_immediate_action);
      apply(exm_txn_test1);

}
