# 1 "vxlan_switch.p4"
# 1 "<built-in>"
# 1 "<command-line>"
# 1 "vxlan_switch.p4"
# 24 "vxlan_switch.p4"
# 1 "includes/headers.p4" 1
# 31 "includes/headers.p4"
header_type ethernet_t {
    fields {
        dstAddr : 48;
        srcAddr : 48;
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

        dstAddr_first32 : 32;
        dstAddr_second32 : 32;
        dstAddr_zeroes : 32;
        dstAddr_server : 32;
    }
}


header_type icmp_t {
    fields {
        typeCode : 16;
        hdrChecksum : 16;
    }
}

header_type tcp_t {
    fields {
        srcPort : 16;
        dstPort : 16;
        seqNo : 32;
        ackNo : 32;
        dataOffset : 4;
        res : 4;
        flags : 8;
        window : 16;
        checksum : 16;
        urgentPtr : 16;
    }
}

header_type udp_t {
    fields {
        srcPort : 16;
        dstPort : 16;
        length_ : 16;
        checksum : 16;
    }
}


header_type vxlan_t {
    fields {
        flags : 8;
        reserved : 24;
        vni : 24;
        reserved2 : 8;
    }
}
# 25 "vxlan_switch.p4" 2
# 1 "includes/parser.p4" 1
# 22 "includes/parser.p4"
header ethernet_t ethernet;
header ethernet_t inner_ethernet;

header ipv4_t ipv4;
header ipv4_t inner_ipv4;
header ipv6_t ipv6;
header ipv6_t inner_ipv6;

header tcp_t tcp;
header tcp_t inner_tcp;
header udp_t udp;
header udp_t inner_udp;
header icmp_t icmp;
header icmp_t inner_icmp;

header vxlan_t vxlan;
# 54 "includes/parser.p4"
field_list our_udpv6_checksum_list {
# 64 "includes/parser.p4"
    udp.srcPort;
    udp.dstPort;
    udp.length_;
    payload;
}

field_list_calculation our_udpv6_checksum {
    input {
        our_udpv6_checksum_list;
    }
    algorithm : csum16;
    output_width : 16;
}



parser start {
    return parse_ethernet;
}


parser parse_ethernet {
    extract(ethernet);
    return select(latest.etherType) {
        0x0800 : parse_ipv4;
        0x86dd : parse_ipv6;
        default : ingress;
    }
}


parser parse_ipv4 {
    extract(ipv4);
    return select(latest.protocol) {
        1 : parse_icmp;
        6 : parse_tcp;
        17 : parse_udp;
        default: ingress;
    }
}

parser parse_ipv6 {
    extract(ipv6);
    return select(latest.nextHdr) {
        17 : parse_udp;

        default: ingress;
    }
}


parser parse_icmp {
    extract(icmp);
    return ingress;
}

parser parse_tcp {
    extract(tcp);
    return ingress;
}

parser parse_udp {
    extract(udp);
    return select(latest.dstPort) {
        4789 : parse_vxlan;
        default: ingress;
    }
}


parser parse_vxlan {
    extract(vxlan);
    return parse_inner_ethernet;
}



parser parse_inner_ethernet {
    extract(inner_ethernet);
    return select(latest.etherType) {
        0x0800 : parse_inner_ipv4;
        default: ingress;
    }
}


parser parse_inner_ipv4 {
    extract(inner_ipv4);
    return select(latest.protocol) {
        1 : parse_inner_icmp;
        6 : parse_inner_tcp;
        17 : parse_inner_udp;
        default: ingress;
    }
}


parser parse_inner_icmp {
    extract(inner_icmp);
    return ingress;
}


parser parse_inner_tcp {
    extract(inner_tcp);
    return ingress;
}


parser parse_inner_udp {
    extract(inner_udp);
    return ingress;
}
# 26 "vxlan_switch.p4" 2
# 1 "/home/vgurevich/bf-sde-5.0.1.21/install/share/p4_lib/tofino/intrinsic_metadata.p4" 1
# 10 "/home/vgurevich/bf-sde-5.0.1.21/install/share/p4_lib/tofino/intrinsic_metadata.p4"
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
# 382 "/home/vgurevich/bf-sde-5.0.1.21/install/share/p4_lib/tofino/intrinsic_metadata.p4"
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
# 425 "/home/vgurevich/bf-sde-5.0.1.21/install/share/p4_lib/tofino/intrinsic_metadata.p4"
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
# 27 "vxlan_switch.p4" 2
# 1 "/home/vgurevich/bf-sde-5.0.1.21/install/share/p4_lib/tofino/constants.p4" 1
# 28 "vxlan_switch.p4" 2



# 1 "tunnel.p4" 1
# 19 "tunnel.p4"
header_type tunnel_metadata_t {
    fields {

        ingress_tunnel_type : 5;
        egress_tunnel_type : 5;
        tunnel_vni : 24;
        tunnel_index : 24;



        dst_datacenter_index : 16;
        dst_tor_index : 16;
        dst_server_index : 16;




        tunnel_terminate : 1;
        tunnel_lookup : 1;
        egress_header_count : 4;
        tunnel_smac_index : 14;
        tunnel_dmac_index : 14;
        tunnel_if_check : 1;
        inner_ip_proto : 8;

    }
}
metadata tunnel_metadata_t tunnel_metadata;




action insert_ipv6_header() {
    modify_field(ethernet.etherType, 0x86dd);
    add_header(ipv6);

    modify_field(ipv6.version, 0x6);


    modify_field(ipv6.payloadLen, egress_metadata.payload_length);
    modify_field(ipv6.nextHdr, 17);
    modify_field(ipv6.hopLimit, 64);



    modify_field(ipv6.dstAddr_zeroes, 0x00000000);
    modify_field(ipv6.srcAddr, 0x1aa12aa23aa34aa45aa56aa67aa78aa8);


}


action insert_vxlan_header(vni) {
    add_header(vxlan);

    modify_field(vxlan.flags, 0x8);
    modify_field(vxlan.reserved, 0);
    modify_field(vxlan.vni, vni);
    modify_field(vxlan.reserved2, 0);
}

action insert_udp_header(proto) {
    add_header(udp);

    modify_field(udp.srcPort, hash_metadata.entropy_hash);
    modify_field(udp.dstPort, 4789);
    modify_field(udp.checksum, 0x0);

}



action encap_process_inner_common() {



    add(egress_metadata.payload_length, ipv4.totalLen, 30);

    copy_header(inner_ethernet, ethernet);
    copy_header(inner_ipv4, ipv4);
    remove_header(ipv4);


    insert_vxlan_header(tunnel_metadata.tunnel_vni);
    insert_udp_header(4789);
    add(udp.length_, ipv4.totalLen, 30);
}





action encap_udp() {
    copy_header(inner_udp, udp);
    remove_header(udp);

}
action encap_tcp() {
    copy_header(inner_tcp, tcp);
    remove_header(tcp);

}
action encap_icmp() {
    copy_header(inner_icmp, icmp);
    remove_header(icmp);

}
table encap_inner {
    reads {
        udp : valid;
        tcp : valid;
        icmp : valid;
    }
    actions {
        encap_udp;
        encap_tcp;
        encap_icmp;
    }
    size : 3;
}
table encap_inner2 {
    actions {
        encap_process_inner_common;
    }
    size : 1;
}
table encap_inner3 {
    actions {
        insert_ipv6_header;
    }
    size : 1;
}




action set_dst_datacenter(dst_datacenter_id_32, dst_datacenter_id_4) {
    modify_field(ipv6.dstAddr_first32, dst_datacenter_id_32);
    modify_field(ipv6.dstAddr_second32, dst_datacenter_id_4);
}
@pragma ternary 1
table tunnel_dst_datacenter_rewrite {
    reads {
        tunnel_metadata.dst_datacenter_index : exact;
    }
    actions {
        set_dst_datacenter;
    }
    size : 256;
}





action set_dst_tor(dst_tor_id) {

    add_to_field(ipv6.dstAddr_second32, dst_tor_id);
}
@pragma ternary 1
table tunnel_dst_tor_rewrite {
    reads {
        tunnel_metadata.dst_tor_index : exact;
    }
    actions {
        set_dst_tor;
    }
    size : 2048;
}
action set_dst_server(dst_server_ip) {
    modify_field(ipv6.dstAddr_server, dst_server_ip);
    shift_left(ipv6.dstAddr_second32, ipv6.dstAddr_second32, 28);
}
@pragma ternary 1
table tunnel_dst_server_rewrite {
    reads {
        tunnel_metadata.dst_server_index : exact;
    }
    actions {
        set_dst_server;
    }
    size : 2048;
}


action encap_write_outer(dst_datacenter_index, dst_tor_index, dst_server_index, vni) {
    modify_field(tunnel_metadata.dst_datacenter_index, dst_datacenter_index);
    modify_field(tunnel_metadata.dst_tor_index, dst_tor_index);
    modify_field(tunnel_metadata.dst_server_index, dst_server_index);
    modify_field(tunnel_metadata.tunnel_vni, vni);
}
table encap_write_outer {
    reads {
        tunnel_metadata.tunnel_index : exact;
    }
    actions {
        encap_write_outer;
    }
    size : 1024;
}



control encap_process {
    apply(encap_inner);
    apply(encap_inner2);
    apply(encap_inner3);
    apply(encap_write_outer);

    apply(tunnel_dst_datacenter_rewrite);
    apply(tunnel_dst_server_rewrite);
    apply(tunnel_dst_tor_rewrite);
}
# 245 "tunnel.p4"
action set_vrf(vrf) {
    modify_field(l3_metadata.vrf, vrf);
}
table vni_to_vrf {
    reads {
        vxlan.vni : exact;

    }
    actions {
        set_vrf;
    }
    size : 1024;
}



action decap_common() {
    copy_header(ethernet, inner_ethernet);
    remove_header(inner_ethernet);
    copy_header(ipv4, inner_ipv4);
    remove_header(inner_ipv4);

    remove_header(vxlan);
    remove_header(ipv6);
}

action decap_udp() {
    copy_header(udp, inner_udp);
    remove_header(inner_udp);

}

action decap_tcp() {
    remove_header(udp);
    copy_header(tcp, inner_tcp);
    remove_header(inner_tcp);

}

action decap_icmp() {
    remove_header(udp);
    copy_header(icmp, inner_icmp);
    remove_header(inner_icmp);

}

action decap_unparsed_l4() {
    remove_header(udp);

}

table decap_inner {
    reads {
        udp : valid;
        tcp : valid;
        icmp : valid;
    }
    actions {
        decap_udp;
        decap_tcp;
        decap_icmp;
        decap_unparsed_l4;
    }
    size : 4;
}

table decap_outer {
    actions {
        decap_common;
    }
    size : 1;
}

action tunnel_check_passed() {}

table tunnel_check {
    reads {
        vxlan : valid;
        ipv6.dstAddr_first32 : exact;
        ipv6.dstAddr_second32 : exact;
    }
    actions {
        tunnel_check_passed;
        on_miss;
    }
    size : 2;
}
# 351 "tunnel.p4"
control process_tunnel {
    apply(tunnel_check) {
        tunnel_check_passed {
            apply(vni_to_vrf);
            apply(decap_inner);
            apply(decap_outer);
        }
    }
}


control process_tunnel_encap {
    if (tunnel_metadata.tunnel_index != 0) {
        encap_process();
    }
}



control process_tunnel_id {}
control process_tunnel_decap {}
# 32 "vxlan_switch.p4" 2




action on_miss() {}
header_type hash_metadata_t {
    fields {
        entropy_hash : 16;
    }
}
metadata hash_metadata_t hash_metadata;

header_type l3_metadata_t {
    fields {
        nexthop_index : 24;
        vrf : 24;
    }
}
metadata l3_metadata_t l3_metadata;

header_type egress_metadata_t {
    fields {
        payload_length : 16;
    }
}
@pragma pa_no_init ingress egress_metadata.payload_length
@pragma pa_no_init egress egress_metadata.payload_length
metadata egress_metadata_t egress_metadata;

header_type global_config_metadata_t {
    fields {
        our_ipv6_addr : 128;
    }
}
metadata global_config_metadata_t global_config_metadata;






action _drop() {
    drop();
}



action assign_vrf(vrf) {
    modify_field(l3_metadata.vrf, vrf);
}
table assign_vrf {
    reads {
        ig_intr_md.ingress_port : exact;

    }
    actions {
        assign_vrf;
    }
    size : 1024;
}

action set_nhop_index(nexthop_index) {
    modify_field(l3_metadata.nexthop_index, nexthop_index);
}
action set_nhop_index_with_tunnel(nexthop_index, tunnel_index) {
    modify_field(l3_metadata.nexthop_index, nexthop_index);
    modify_field(tunnel_metadata.tunnel_index, tunnel_index);
}
table nhop_lookup {
    reads {
        ipv4.dstAddr : lpm;
        l3_metadata.vrf : exact;
    }
    actions {
        set_nhop_index;
        set_nhop_index_with_tunnel;
        _drop;
    }
    size : 1024;
}


action set_dmac(dmac, port) {
    modify_field(ethernet.dstAddr, dmac);
    modify_field(ig_intr_md_for_tm.ucast_egress_port, port);
}
table forward {
    reads {
        l3_metadata.nexthop_index : exact;
    }
    actions {
        set_dmac;
        _drop;
    }
    size: 512;
}


control ingress {
    if (valid(ipv4)) {
        apply(assign_vrf);
    }
    else if(valid(vxlan)) {
       process_tunnel();
    }



    apply(nhop_lookup);
    apply(forward);
}

control egress {

    process_tunnel_encap();
}
