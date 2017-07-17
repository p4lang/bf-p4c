/*
gcc -E -x c -w -I/vagrant/p4factory/submodules/p4c-tofino/p4c_tofino/target/tofino/p4_lib -D__TARGET_TOFINO__ -I/usr/local/lib/python2.7/dist-packages/p4_hlir-0.9.57-py2.7.egg/p4_hlir/p4_lib /vagrant/p4factory/submodules/p4c-tofino/p4c_tofino/../../../programs/srv6/switch.p4
*/
# 1 "/vagrant/p4factory/submodules/p4c-tofino/p4c_tofino/../../../programs/srv6/switch.p4"
# 1 "<built-in>"
# 1 "<command-line>"
# 1 "/usr/include/stdc-predef.h" 1 3 4
# 1 "<command-line>" 2
# 1 "/vagrant/p4factory/submodules/p4c-tofino/p4c_tofino/../../../programs/srv6/switch.p4"
# 25 "/vagrant/p4factory/submodules/p4c-tofino/p4c_tofino/../../../programs/srv6/switch.p4"
# 1 "/vagrant/p4factory/submodules/p4c-tofino/p4c_tofino/target/tofino/p4_lib/tofino/constants.p4" 1
# 26 "/vagrant/p4factory/submodules/p4c-tofino/p4c_tofino/../../../programs/srv6/switch.p4" 2
# 1 "/vagrant/p4factory/submodules/p4c-tofino/p4c_tofino/target/tofino/p4_lib/tofino/intrinsic_metadata.p4" 1
# 10 "/vagrant/p4factory/submodules/p4c-tofino/p4c_tofino/target/tofino/p4_lib/tofino/intrinsic_metadata.p4"
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
# 379 "/vagrant/p4factory/submodules/p4c-tofino/p4c_tofino/target/tofino/p4_lib/tofino/intrinsic_metadata.p4"
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
# 422 "/vagrant/p4factory/submodules/p4c-tofino/p4c_tofino/target/tofino/p4_lib/tofino/intrinsic_metadata.p4"
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
# 27 "/vagrant/p4factory/submodules/p4c-tofino/p4c_tofino/../../../programs/srv6/switch.p4" 2
# 1 "/vagrant/p4factory/submodules/p4c-tofino/p4c_tofino/target/tofino/p4_lib/tofino/primitives.p4" 1
# 10 "/vagrant/p4factory/submodules/p4c-tofino/p4c_tofino/target/tofino/p4_lib/tofino/primitives.p4"
action deflect_on_drop(enable_dod) {
    modify_field(ig_intr_md_for_tm.deflect_on_drop, enable_dod);
}
# 28 "/vagrant/p4factory/submodules/p4c-tofino/p4c_tofino/../../../programs/srv6/switch.p4" 2
# 39 "/vagrant/p4factory/submodules/p4c-tofino/p4c_tofino/../../../programs/srv6/switch.p4"
# 1 "/vagrant/p4factory/submodules/p4c-tofino/p4c_tofino/../../../programs/srv6/parser.p4" 1
# 56 "/vagrant/p4factory/submodules/p4c-tofino/p4c_tofino/../../../programs/srv6/parser.p4"
header_type ethernet_t {
    fields {
        dstAddr : 48;
        srcAddr : 48;
        etherType : 16;
    }
}

header_type vlan_tag_t {
  fields {
    pcp : 3;
    cfi : 1;
    vid : 12;
    etherType : 16;
  }
}

header_type mpls_t {
    fields {
        label : 20;
        exp : 3;
        bos : 1;
        ttl : 8;
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

header_type ipv6_srh_t {
    fields {
        nextHdr : 8;
        hdrExtLen : 8;
        routingType : 8;
        segLeft : 8;
        firstSeg : 8;
        flags : 8;
        reserved : 16;
    }
}

header_type ipv6_srh_segment_t {
    fields {
        sid : 128;
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

header_type icmp_t {
  fields {
    icmpType: 8;
    code: 8;
    checksum: 16;
  }
}

header_type arp_t {
  fields {
    hwType : 16;
    protoType : 16;
    hwAddrLen : 8;
    protoAddrLen : 8;
    opcode : 16;
    hwSrcAddr : 48;
    protoSrcAddr : 32;
    hwDstAddr : 48;
    protoDstAddr : 32;
  }
}





header ethernet_t ethernet;
header ipv4_t ipv4;
header ipv6_t ipv6;
header icmp_t icmp;
header tcp_t tcp;
header udp_t udp;
header arp_t arp;
header ipv6_srh_t ipv6_srh;
header ipv6_srh_segment_t ipv6_srh_seg_list[5];
header vlan_tag_t vlan_tag[2];
header mpls_t mpls[16];

header ethernet_t inner_ethernet;
header ipv4_t inner_ipv4;
header ipv6_t inner_ipv6;
header ipv6_srh_t inner_ipv6_srh;
header ipv6_srh_segment_t inner_ipv6_srh_seg_list[5];

@pragma pa_alias egress inner_icmp icmp
header icmp_t inner_icmp;
@pragma pa_alias egress inner_tcp tcp
header tcp_t inner_tcp;
@pragma pa_alias egress inner_udp udp
header udp_t inner_udp;





parser start {
    return parse_ethernet;
}

parser parse_ethernet {
    extract(ethernet);
    return select(latest.etherType) {

        0x8100 : parse_vlan;
        0x0806 : parse_arp;
        0x0800 : parse_ipv4;
        0x86dd : parse_ipv6;
        default: ingress;
    }
}

parser parse_vlan {
  extract(vlan_tag[next]);
  return select(latest.etherType) {
    0x8100 : parse_vlan;
    0x0800 : parse_ipv4;
    0x86dd : parse_ipv6;
    default: ingress;
  }
}

parser parse_ipv4 {
  extract(ipv4);
  return select(latest.fragOffset, latest.protocol) {
    1 : parse_icmp;
    6 : parse_tcp;
    17 : parse_udp;
    default: ingress;
  }
}

parser parse_ipv6 {
  extract(ipv6);
  return select(latest.nextHdr) {
    58 : parse_icmp;
    6 : parse_tcp;
    17 : parse_udp;
    43 : parse_ipv6_srh;
    default: ingress;
  }
}

parser parse_tcp {
  extract(tcp);
  return ingress;
}

parser parse_udp {
  extract(udp);
  return select(latest.dstPort) {
    default : ingress;
  }
}

parser parse_icmp {
  extract(icmp);
  return ingress;
}

parser parse_arp {
  extract(arp);
  return ingress;
}

parser parse_ipv6_srh {
  extract(ipv6_srh);
  return select(latest.firstSeg) {
    0 : ingress;
    1 : parse_ipv6_srh_segment_before_sid_1;
    2 : parse_ipv6_srh_segment_before_sid_2;
    3 : parse_ipv6_srh_segment_before_sid_3;
    4 : parse_ipv6_srh_segment_before_sid_4;
  }
}
# 309 "/vagrant/p4factory/submodules/p4c-tofino/p4c_tofino/../../../programs/srv6/parser.p4"
parser parse_ipv6_srh_segment_before_sid_1 { extract(ipv6_srh_seg_list[1]); return select(ipv6_srh.segLeft) { 1 : extract_srh_active_segment_0; default : parse_ipv6_srh_segment_before_sid_0; } } parser extract_srh_active_segment_1 { extract(ipv6_srh_seg_list[1]); set_metadata(sr_metadata.sid, latest.sid); return parse_ipv6_srh_segment_after_sid_0; } parser parse_ipv6_srh_segment_after_sid_1 { extract(ipv6_srh_seg_list[1]); return parse_ipv6_srh_segment_after_sid_0; }
parser parse_ipv6_srh_segment_before_sid_2 { extract(ipv6_srh_seg_list[2]); return select(ipv6_srh.segLeft) { 2 : extract_srh_active_segment_1; default : parse_ipv6_srh_segment_before_sid_1; } } parser extract_srh_active_segment_2 { extract(ipv6_srh_seg_list[2]); set_metadata(sr_metadata.sid, latest.sid); return parse_ipv6_srh_segment_after_sid_1; } parser parse_ipv6_srh_segment_after_sid_2 { extract(ipv6_srh_seg_list[2]); return parse_ipv6_srh_segment_after_sid_1; }
parser parse_ipv6_srh_segment_before_sid_3 { extract(ipv6_srh_seg_list[3]); return select(ipv6_srh.segLeft) { 3 : extract_srh_active_segment_2; default : parse_ipv6_srh_segment_before_sid_2; } } parser extract_srh_active_segment_3 { extract(ipv6_srh_seg_list[3]); set_metadata(sr_metadata.sid, latest.sid); return parse_ipv6_srh_segment_after_sid_2; } parser parse_ipv6_srh_segment_after_sid_3 { extract(ipv6_srh_seg_list[3]); return parse_ipv6_srh_segment_after_sid_2; }
parser parse_ipv6_srh_segment_before_sid_4 { extract(ipv6_srh_seg_list[4]); return select(ipv6_srh.segLeft) { 4 : extract_srh_active_segment_3; default : parse_ipv6_srh_segment_before_sid_3; } } parser extract_srh_active_segment_4 { extract(ipv6_srh_seg_list[4]); set_metadata(sr_metadata.sid, latest.sid); return parse_ipv6_srh_segment_after_sid_3; } parser parse_ipv6_srh_segment_after_sid_4 { extract(ipv6_srh_seg_list[4]); return parse_ipv6_srh_segment_after_sid_3; }

parser parse_ipv6_srh_segment_before_sid_0 {
    extract(ipv6_srh_seg_list[0]);
    return parse_srh_next_hdr;
}

parser extract_srh_active_segment_0 {
    extract(ipv6_srh_seg_list[0]);
    return parse_srh_next_hdr;
}

parser parse_ipv6_srh_segment_after_sid_0 {
    extract(ipv6_srh_seg_list[0]);
    return parse_srh_next_hdr;
}

parser parse_srh_next_hdr {
    return select(ipv6_srh.nextHdr) {
        41 : parse_inner_ipv6;
        4 : parse_inner_ipv4;
        97 : parse_inner_ethernet;
        43 : parse_inner_srh;
        default: ingress;
    }
}

parser parse_inner_ethernet {
    extract(inner_ethernet);
    return select(latest.etherType) {
        0x0800 : parse_inner_ipv4;
        0x86dd : parse_inner_ipv6;
        default: ingress;
    }
}

parser parse_inner_ipv6 {
  extract(inner_ipv6);
  return select(latest.nextHdr) {
    58 : parse_inner_icmp;
    6 : parse_inner_tcp;
    17 : parse_inner_udp;
    default: ingress;
  }
}

parser parse_inner_ipv4 {
  extract(inner_ipv4);
  return select(latest.fragOffset, latest.protocol) {
    1 : parse_inner_icmp;
    6 : parse_inner_tcp;
    17 : parse_inner_udp;
    default: ingress;
  }
}

parser parse_inner_srh {
  extract(inner_ipv6_srh);
  set_metadata(ig_prsr_ctrl.parser_counter, latest.firstSeg);
  return select(latest.firstSeg) {
    0x0 : ingress;
    default : parse_inner_srh_seg_list;
  }
}

parser parse_inner_srh_seg_list {
  extract(inner_ipv6_srh_seg_list[next]);
  return select(ig_prsr_ctrl.parser_counter) {
    0x0 : ingress;
    default : parse_inner_srh_seg_list;
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
# 40 "/vagrant/p4factory/submodules/p4c-tofino/p4c_tofino/../../../programs/srv6/switch.p4" 2
# 1 "/vagrant/p4factory/submodules/p4c-tofino/p4c_tofino/../../../programs/srv6/forwarding.p4" 1
# 30 "/vagrant/p4factory/submodules/p4c-tofino/p4c_tofino/../../../programs/srv6/forwarding.p4"
header_type l3_metadata_t {
  fields {
    version : 4;
    proto : 8;
    l4_sport : 16;
    l4_dport : 16;
    ipv4_da : 32;
    ipv4_sa : 32;
    ipv6_da : 128;
    ipv6_sa : 128;
    flow_label : 16;
    vrf : 16;
    nexthop : 16;
    hash : 16;
  }
}

header_type l2_metadata_t {
  fields {
    mac_sa : 48;
    mac_da : 48;
    bd : 16;
  }
}

header_type tunnel_metadata_t {
  fields {
    index : 16;
  }
}

metadata l2_metadata_t l2_metadata;
metadata l3_metadata_t l3_metadata;
metadata tunnel_metadata_t tunnel_metadata;




table smac {
  reads {
    l2_metadata.bd : exact;
    l2_metadata.mac_sa : exact;
  }
  actions {
    smac_miss;
    smac_hit;
  }
}

action smac_miss() {

}

action smac_hit() {

}






table dmac {
  reads {
    l2_metadata.bd : exact;
    l2_metadata.mac_da : exact;
  }
  actions {
    dmac_hit;
    dmac_miss;
    dmac_redirect;
    dmac_drop;
  }
  support_timeout: true;
}

action dmac_hit(ifindex) {
  modify_field(ingress_metadata.egress_ifindex, ifindex);
}

action dmac_miss() {

}

action dmac_redirect(index) {

}

action dmac_drop() {
  drop();
}




table rmac {
  reads {
    l2_metadata.mac_da : exact;
  }
  actions {
    rmac_hit;
    rmac_miss;
  }
}

action rmac_hit() {
}

action rmac_miss() {
}




table ipv6_fib {
  reads {
    l3_metadata.vrf : exact;
    l3_metadata.ipv6_da : exact;
  }
  actions {
    miss_;
    set_nexthop_index;
  }
}

table ipv6_fib_lpm {
  reads {
    l3_metadata.vrf : exact;
    l3_metadata.ipv6_da : lpm;
  }
  actions {
    set_nexthop_index;
  }
}

table ipv4_fib {
  reads {
    l3_metadata.vrf : exact;
    l3_metadata.ipv4_da : exact;
  }
  actions {
    miss_;
    set_nexthop_index;
  }
}

table ipv4_fib_lpm {
  reads {
    l3_metadata.vrf : exact;
    l3_metadata.ipv4_da : lpm;
  }
  actions {
    set_nexthop_index;
  }
}

action set_nexthop_index(index) {
  modify_field(l3_metadata.nexthop, index);
}

action miss_() {
}




table nexthop {
  reads {
    l3_metadata.nexthop : exact;
  }
  action_profile : l3_action_profile;
}

action_profile l3_action_profile {
  actions {
    set_nexthop_info;
    set_tunnel_info;
  }
  dynamic_action_selection: ecmp_selector;
}

action_selector ecmp_selector {
  selection_key : ecmp_hash;
  selection_mode : fair;
}

action set_nexthop_info(bd, dmac) {
  modify_field(l2_metadata.bd, bd);
  modify_field(l2_metadata.mac_da, dmac);
  modify_field(ethernet.dstAddr, dmac);
  modify_field(tunnel_metadata.index, 0);
}

action set_tunnel_info(bd, dmac, index) {
  modify_field(l2_metadata.bd, bd);
  modify_field(l2_metadata.mac_da, dmac);
  modify_field(tunnel_metadata.index, index);

}




table lag_group {
  reads {
    ingress_metadata.egress_ifindex : exact;
  }
  action_profile: lag_action_profile;
}

action_profile lag_action_profile {
  actions {
    set_lag_miss;
    set_lag_port;
  }
  dynamic_action_selection : lag_selector;
}

action set_lag_port(port) {
    modify_field(ig_intr_md_for_tm.ucast_egress_port, port);
}

action set_lag_miss() {
}

action_selector lag_selector {
  selection_key : lag_hash;
  selection_mode : fair;
}

field_list_calculation lag_hash {
  input {
    lag_hash_fields;
  }

  algorithm : crc16;
  output_width : 14;
}

field_list lag_hash_fields {

  l2_metadata.mac_sa;
  l2_metadata.mac_da;
}




field_list ipv4_hash_fields {
  l3_metadata.ipv4_da;
  l3_metadata.ipv4_sa;
  l3_metadata.proto;
  l3_metadata.l4_sport;
  l3_metadata.l4_dport;
}

field_list ipv6_hash_fields {
  l3_metadata.ipv6_da;
  l3_metadata.ipv6_sa;
  l3_metadata.proto;
  l3_metadata.flow_label;
  l3_metadata.l4_sport;
  l3_metadata.l4_dport;
}

field_list l3_hash_fields {
    l3_metadata.hash;
}

field_list_calculation ipv4_hash {
  input {
    ipv4_hash_fields;
  }
  algorithm : crc16;
  output_width : 16;
}

field_list_calculation ipv6_hash {
  input {
    ipv6_hash_fields;
  }
  algorithm : crc16;
  output_width : 16;
}

field_list_calculation ecmp_hash {
  input {
    l3_hash_fields;
  }
  algorithm : identity;
  output_width : 14;
}

action compute_ipv4_hash() {
    modify_field_with_hash_based_offset(l3_metadata.hash, 0,
                                        ipv4_hash, 65536);
}

action compute_ipv6_hash() {
    modify_field_with_hash_based_offset(l3_metadata.hash, 0,
                                        ipv6_hash, 65536);
}

table compute_hash {
  reads {
    l3_metadata.version : exact;
    ethernet : valid;
  }
  actions {
    compute_ipv4_hash;
    compute_ipv6_hash;
  }
}




control process_l2_forwarding {
  apply(smac);

  apply(dmac);
}




control process_ipv6_fib {
  apply(ipv6_fib) {
    miss_ {
      apply(ipv6_fib_lpm);
    }
  }
}

control process_ipv4_fib {
  apply(ipv4_fib) {
    miss_ {
      apply(ipv4_fib_lpm);
    }
  }
}

control process_l3_forwarding {
  apply(compute_hash);

  if (l3_metadata.version == 4) {
    process_ipv4_fib();
  } else {
    if (l3_metadata.version == 6) {
      process_ipv6_fib();
    }
  }
}
# 41 "/vagrant/p4factory/submodules/p4c-tofino/p4c_tofino/../../../programs/srv6/switch.p4" 2
# 1 "/vagrant/p4factory/submodules/p4c-tofino/p4c_tofino/../../../programs/srv6/port.p4" 1
# 29 "/vagrant/p4factory/submodules/p4c-tofino/p4c_tofino/../../../programs/srv6/port.p4"
table ingress_port_mapping {
  reads {
    ig_intr_md.ingress_port : exact;
  }
  actions {
    set_ifindex;
  }
}

table ingress_port_properties {
  reads {
    ig_intr_md.ingress_port : exact;
  }
  actions {
    set_ingress_port_properties;
  }
}

table port_vlan_mapping {
  reads {
    ingress_metadata.ifindex : exact;
    vlan_tag[0] : valid;
    vlan_tag[0].vid : exact;
    vlan_tag[1] : valid;
    vlan_tag[1].vid : exact;
  }
  actions {
    set_bd_properties;
  }
}

action set_ifindex(ifindex) {
  modify_field(ingress_metadata.ifindex, ifindex);
}

action set_ingress_port_properties() {

}

action set_bd_properties(bd, vrf) {
  modify_field(l3_metadata.vrf, vrf);
  modify_field(l2_metadata.bd, bd);
}




table egress_port_mapping {
  reads {
    eg_intr_md.egress_port : exact;
  }
  actions {
    set_egress_ifindex;
  }
}

action set_egress_ifindex(ifindex) {
  modify_field(egress_metadata.ifindex, ifindex);
}




action remove_vlan_single_tagged() {
  modify_field(ethernet.etherType, vlan_tag[0].etherType);
  remove_header(vlan_tag[0]);
}

action remove_vlan_double_tagged() {
  modify_field(ethernet.etherType, vlan_tag[1].etherType);
  remove_header(vlan_tag[0]);
  remove_header(vlan_tag[1]);
}

table vlan_decap {
  reads {
    vlan_tag[0].valid : ternary;
    vlan_tag[1].valid : ternary;
  }
  actions {
    remove_vlan_single_tagged;
    remove_vlan_double_tagged;
  }
}




table egress_vlan_xlate {
  reads {
    egress_metadata.ifindex: exact;
    l2_metadata.bd : exact;
  }
  actions {
    set_egress_packet_vlan_untagged;
    set_egress_packet_vlan_tagged;
    set_egress_packet_vlan_double_tagged;
  }
}

action set_egress_packet_vlan_double_tagged(s_tag, c_tag) {
    add_header(vlan_tag[1]);
    add_header(vlan_tag[0]);
    modify_field(vlan_tag[1].etherType, ethernet.etherType);
    modify_field(vlan_tag[1].vid, c_tag);
    modify_field(vlan_tag[0].etherType, 0x8100);
    modify_field(vlan_tag[0].vid, s_tag);
    modify_field(ethernet.etherType, 0x9100);
}

action set_egress_packet_vlan_tagged(vlan_id) {
    add_header(vlan_tag[0]);
    modify_field(vlan_tag[0].etherType, ethernet.etherType);
    modify_field(vlan_tag[0].vid, vlan_id);
    modify_field(ethernet.etherType, 0x8100);
}

action set_egress_packet_vlan_untagged() {
}


control process_ingress_port_mapping {
  apply(ingress_port_mapping);

  apply(ingress_port_properties);

  apply(port_vlan_mapping);
}
# 42 "/vagrant/p4factory/submodules/p4c-tofino/p4c_tofino/../../../programs/srv6/switch.p4" 2
# 1 "/vagrant/p4factory/submodules/p4c-tofino/p4c_tofino/../../../programs/srv6/sr.p4" 1
# 30 "/vagrant/p4factory/submodules/p4c-tofino/p4c_tofino/../../../programs/srv6/sr.p4"
header_type sr_metadata_t {
  fields {
    sid : 128;
    proto : 8;
    action_ : 4;
  }
}

metadata sr_metadata_t sr_metadata;






table srv6_local_sid {
  reads {
    ipv6.dstAddr : lpm;
    ipv6_srh.valid : ternary;
    ipv6_srh.segLeft : ternary;
    ipv6_srh.nextHdr : ternary;
  }
  actions {
    drop_;
    transit;
    end;
    end_x;
    end_t;
    end_dx2;
    end_dx4;
    end_dx6;
    end_dt2;
    end_dt4;
    end_dt6;
    end_b6;
    end_b6_encaps;
  }
}

table srv6_transit {
  reads {
    ipv6.dstAddr : lpm;
  }
  actions {
    t;
    t_insert;
    t_encaps;
  }
}

action drop_() {
  drop();
}

action transit() {
}

action t() {

  set_l2_fields(ethernet.srcAddr, ethernet.dstAddr);
  set_l3_fields(
    ipv6.srcAddr, ipv6.dstAddr, ipv6.nextHdr, ipv6.flowLabel);
}

action t_insert(sid) {
  modify_field(sr_metadata.action_, 0x4);
  set_l2_fields(ethernet.srcAddr, ethernet.dstAddr);
  set_l3_fields(ipv6.srcAddr, sid, ipv6.nextHdr, ipv6.flowLabel);
}

action t_encaps(srcAddr, dstAddr, flowLabel) {
  modify_field(sr_metadata.action_, 0x8);
  set_l2_fields(ethernet.srcAddr, ethernet.dstAddr);
  set_l3_fields(srcAddr, dstAddr, 43, flowLabel);
}

action end() {

  set_l2_fields(ethernet.srcAddr, ethernet.dstAddr);
  set_l3_fields(
    ipv6.srcAddr, sr_metadata.sid, ipv6.nextHdr, ipv6.flowLabel);
  add_to_field(ipv6_srh.segLeft, -1);
  modify_field(ipv6.dstAddr, sr_metadata.sid);
}

action end_x(nexthop) {

  modify_field(l3_metadata.nexthop, nexthop);
  modify_field(ingress_metadata.bypass, 0x2);
  add_to_field(ipv6_srh.segLeft, -1);
  modify_field(ipv6.dstAddr, sr_metadata.sid);
}

action end_t() {

}

action end_dx2(ifindex) {
  modify_field(sr_metadata.action_, 0x1);
  modify_field(ingress_metadata.egress_ifindex, ifindex);
  modify_field(ingress_metadata.bypass, 0xF);
}

action end_dx4(nexthop) {
  modify_field(sr_metadata.action_, 0x1);
  modify_field(l3_metadata.nexthop, nexthop);
  modify_field(ingress_metadata.bypass, 0x2);
}

action end_dx6(nexthop) {
  modify_field(sr_metadata.action_, 0x1);
  modify_field(l3_metadata.nexthop, nexthop);
  modify_field(ingress_metadata.bypass, 0x2);
}

action end_dt2(bd) {

  modify_field(sr_metadata.action_, 0x1);
  modify_field(l2_metadata.bd, bd);
  set_l2_fields(inner_ethernet.srcAddr, inner_ethernet.dstAddr);
}

action end_dt4(vrf) {

  modify_field(sr_metadata.action_, 0x1);
  modify_field(l3_metadata.vrf, vrf);
  set_l2_fields(ethernet.srcAddr, ethernet.dstAddr);
  modify_field(l3_metadata.ipv4_sa, inner_ipv4.srcAddr);
  modify_field(l3_metadata.ipv4_da, inner_ipv4.dstAddr);
  modify_field(l3_metadata.proto, inner_ipv4.protocol);
}

action end_dt6(vrf) {

  modify_field(sr_metadata.action_, 0x1);
  modify_field(l3_metadata.vrf, vrf);
  set_l2_fields(ethernet.srcAddr, ethernet.dstAddr);
  set_l3_fields(inner_ipv6.srcAddr, inner_ipv6.dstAddr, inner_ipv6.nextHdr,
      inner_ipv6.flowLabel);
}

action end_b6(sid) {

  modify_field(sr_metadata.action_, 0x4);
  set_l2_fields(ethernet.srcAddr, ethernet.dstAddr);
  set_l3_fields(ipv6.srcAddr, sid, ipv6.nextHdr, ipv6.flowLabel);
  modify_field(ipv6.dstAddr, sid);
}

action end_b6_encaps(sid) {

  modify_field(sr_metadata.action_, 0x8);
  set_l2_fields(ethernet.srcAddr, ethernet.dstAddr);
  set_l3_fields(ipv6.srcAddr, sid, ipv6.nextHdr, ipv6.flowLabel);
  add_to_field(ipv6_srh.segLeft, -1);
  modify_field(ipv6.dstAddr, sr_metadata.sid);
}




action set_l3_fields(srcAddr, dstAddr, proto, flowLabel) {
  modify_field(l3_metadata.ipv6_sa, srcAddr);
  modify_field(l3_metadata.ipv6_da, dstAddr);
  modify_field(l3_metadata.proto, proto);
  modify_field(l3_metadata.flow_label, flowLabel);
}

action set_l2_fields(srcAddr, dstAddr) {
  modify_field(l2_metadata.mac_sa, srcAddr);
  modify_field(l2_metadata.mac_da, dstAddr);
}






table srv6_decap {
  reads {
    sr_metadata.action_ : exact;
    inner_ipv4 : valid;
    inner_ipv6 : valid;
  }
  actions {
    decap_inner_non_ip;
    decap_inner_ipv4;
    decap_inner_ipv6;
    pop_ipv6_srh;
  }
}

action decap_inner_non_ip() {
    copy_header(ethernet, inner_ethernet);
    remove_header(inner_ethernet);
    remove_header(ipv6);
    pop_ipv6_srh();
}

action decap_inner_ipv4() {
    modify_field(ethernet.etherType, 0x0800);
    copy_header(ipv4, inner_ipv4);
    remove_header(inner_ipv4);
    remove_header(ipv6);
    pop_ipv6_srh();
}

action decap_inner_ipv6() {
    modify_field(ethernet.etherType, 0x86dd);
    copy_header(ipv6, inner_ipv6);
    remove_header(inner_ipv6);
    pop_ipv6_srh();
}

action pop_ipv6_srh() {
    remove_header(ipv6_srh);
    remove_header(ipv6_srh_seg_list[0]);
    remove_header(ipv6_srh_seg_list[1]);
    remove_header(ipv6_srh_seg_list[2]);
    remove_header(ipv6_srh_seg_list[3]);
    remove_header(ipv6_srh_seg_list[4]);
}




table tunnel_encap_process_inner {
    reads {
        ipv4 : valid;
        ipv6 : valid;
    }
    actions {
        inner_ipv4_rewrite;
        inner_ipv6_rewrite;
        inner_non_ip_rewrite;
    }
}

table srv6_encap {
  reads {
    tunnel_metadata.index : exact;
  }
  actions {
    srv6_rewrite_1;
    srv6_rewrite_2;
    srv6_rewrite_3;
    srv6_rewrite_4;
    //srv6_rewrite_5;
  }
}

table srv6_rewrite {
  reads {
    tunnel_metadata.index : exact;
  }
  actions {
    set_srv6_seg_list_rewrite;
  }
}

action inner_ipv4_rewrite() {
    copy_header(inner_ipv4, ipv4);
    remove_header(ipv4);
    modify_field(egress_metadata.payload_length, ipv4.totalLen);
}

action inner_ipv6_rewrite() {
    copy_header(inner_ipv6, ipv6);
    remove_header(ipv6);
    add(egress_metadata.payload_length, ipv6.payloadLen, 40);
}

action inner_non_ip_rewrite() {
  copy_header(inner_ethernet, ethernet);
  add(egress_metadata.payload_length, eg_intr_md.pkt_length, -14);
}
# 316 "/vagrant/p4factory/submodules/p4c-tofino/p4c_tofino/../../../programs/srv6/sr.p4"

// This push(5) is not implementable with current compiler parser infrastructure, since requires putting POV bits in 16-bit container, and cannot write (0x1F << wherever constants are) to 16-bit container in one parse state
//action srv6_rewrite_5() { insert_ipv6_header(43); insert_ipv6_srh(sr_metadata.proto); push(ipv6_srh_seg_list, 5); modify_field(ethernet.etherType, 0x86dd); add(ipv6.payloadLen, egress_metadata.payload_length, 88); }

action srv6_rewrite_4() { insert_ipv6_header(43); insert_ipv6_srh(sr_metadata.proto); push(ipv6_srh_seg_list, 4); modify_field(ethernet.etherType, 0x86dd); add(ipv6.payloadLen, egress_metadata.payload_length, 72); }
action srv6_rewrite_3() { insert_ipv6_header(43); insert_ipv6_srh(sr_metadata.proto); push(ipv6_srh_seg_list, 3); modify_field(ethernet.etherType, 0x86dd); add(ipv6.payloadLen, egress_metadata.payload_length, 56); }
action srv6_rewrite_2() { insert_ipv6_header(43); insert_ipv6_srh(sr_metadata.proto); push(ipv6_srh_seg_list, 2); modify_field(ethernet.etherType, 0x86dd); add(ipv6.payloadLen, egress_metadata.payload_length, 40); }
action srv6_rewrite_1() { insert_ipv6_header(43); insert_ipv6_srh(sr_metadata.proto); push(ipv6_srh_seg_list, 1); modify_field(ethernet.etherType, 0x86dd); add(ipv6.payloadLen, egress_metadata.payload_length, 24); }

action set_tunnel_rewrite(smac, dmac, sip, dip) {
  set_l2_addr(smac, dmac);
  set_ipv6_addr(sip, dip);
}

action set_srh_rewrite(srh_len, seg_left) {
  modify_field(ipv6_srh.hdrExtLen, srh_len);
  modify_field(ipv6_srh.segLeft, seg_left);
  modify_field(ipv6_srh.firstSeg, seg_left);
}

action set_srv6_seg_list_rewrite(srh_len, seg_left,
        sid0, sid1, sid2) {
    set_srh_rewrite(srh_len, seg_left);
    modify_field(ipv6_srh_seg_list[0].sid, sid0);
    modify_field(ipv6_srh_seg_list[1].sid, sid1);
    modify_field(ipv6_srh_seg_list[2].sid, sid2);




}




action set_ipv4_addr(srcAddr, dstAddr) {
  modify_field(ipv4.srcAddr, srcAddr);
  modify_field(ipv4.dstAddr, dstAddr);
}

action set_ipv6_addr(srcAddr, dstAddr) {
  modify_field(ipv6.srcAddr, srcAddr);
  modify_field(ipv6.dstAddr, dstAddr);
}

action set_l2_addr(smac, dmac) {
  modify_field(ethernet.srcAddr, smac);
  modify_field(ethernet.dstAddr, dmac);
}

action insert_ipv6_header(proto) {
  add_header(ipv6);
  modify_field(ipv6.version, 0x6);
  modify_field(ipv6.nextHdr, proto);
  modify_field(ipv6.hopLimit, 64);


}

action insert_ipv6_srh(proto) {
  add_header(ipv6_srh);
  modify_field(ipv6_srh.nextHdr, proto);

  modify_field(ipv6_srh.routingType, 0x4);




}






control process_srv6 {
  if (valid(ipv6)) {
    apply(srv6_local_sid) {
      transit {
        apply(srv6_transit);
      }
    }
  }
}

control process_srv6_decap {
  apply(srv6_decap);
}


control process_srv6_encap {
  apply(tunnel_encap_process_inner);
  apply(srv6_encap);
  apply(srv6_rewrite);
}
# 43 "/vagrant/p4factory/submodules/p4c-tofino/p4c_tofino/../../../programs/srv6/switch.p4" 2
# 1 "/vagrant/p4factory/submodules/p4c-tofino/p4c_tofino/../../../programs/srv6/rewrite.p4" 1
# 27 "/vagrant/p4factory/submodules/p4c-tofino/p4c_tofino/../../../programs/srv6/rewrite.p4"
table l3_rewrite {
  reads {
    ipv4 : valid;
    ipv6 : valid;
  }
  actions {
    ipv4_rewrite;
    ipv6_rewrite;
  }
}

action ipv4_rewrite() {
  add_to_field(ipv4.ttl, -1);
}

action ipv6_rewrite() {
  add_to_field(ipv6.hopLimit, -1);
}




table l2_rewrite {
  reads {
    l2_metadata.bd : exact;
  }
  actions {
    smac_rewrite;
  }
}

action smac_rewrite(smac) {
  modify_field(ethernet.srcAddr, smac);
}


control process_rewrite {
  apply(l2_rewrite);

  apply(l3_rewrite);
}
# 44 "/vagrant/p4factory/submodules/p4c-tofino/p4c_tofino/../../../programs/srv6/switch.p4" 2
# 1 "/vagrant/p4factory/submodules/p4c-tofino/p4c_tofino/../../../programs/srv6/validation.p4" 1
# 30 "/vagrant/p4factory/submodules/p4c-tofino/p4c_tofino/../../../programs/srv6/validation.p4"
table validate_ipv4_packet {
  reads {
    ipv4.version : ternary;
    ipv4.ihl: ternary;
    ipv4.ttl : ternary;
    ipv4.srcAddr mask 0xFF000000 : ternary;
  }
  actions {
    malformed_ipv4_packet;
  }
}

table validate_ipv6_packet {
  reads {
    ipv6.version : ternary;
    ipv6.hopLimit : ternary;
    ipv6.srcAddr mask 0xFFFF0000000000000000000000000000 : ternary;
  }
  actions {
    malformed_ipv6_packet;
  }
}

table validate_ethernet {
  reads {
    ethernet.srcAddr : ternary;
    ethernet.dstAddr : ternary;
    vlan_tag[0] : valid;
    vlan_tag[1] : valid;
  }
  actions {
    malformed_ethernet_packet;
  }
}

action malformed_ipv4_packet() {
  drop();
}


action malformed_ipv6_packet() {
  drop();
}

action malformed_ethernet_packet() {
  drop();
}


control process_validate_packet {
# 95 "/vagrant/p4factory/submodules/p4c-tofino/p4c_tofino/../../../programs/srv6/validation.p4"
}
# 45 "/vagrant/p4factory/submodules/p4c-tofino/p4c_tofino/../../../programs/srv6/switch.p4" 2

header_type ingress_metadata_t {
  fields {
    ifindex : 16;
    egress_ifindex : 16;
    bypass : 4;
  }
}

header_type egress_metadata_t {
  fields {
    ifindex : 16;
    payload_length : 16;
  }
}

metadata egress_metadata_t egress_metadata;
metadata ingress_metadata_t ingress_metadata;

control ingress {

  process_ingress_port_mapping();


  process_validate_packet();


  process_srv6();

  apply(rmac) {
    rmac_hit {
      if (((ingress_metadata.bypass & 0x2) == 0)) {
        process_l3_forwarding();
      }
    }
  }

  apply(nexthop);

  if (((ingress_metadata.bypass & 0x1) == 0)) {
    process_l2_forwarding();
  }

  apply(lag_group);


}

control egress {

  apply(egress_port_mapping);


  apply(vlan_decap);


  process_srv6_decap();


  process_rewrite();


  process_srv6_encap();

  apply(egress_vlan_xlate);

}
