#include "tofino/intrinsic_metadata.p4"
#include "tofino/constants.p4"


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

header_type mpls_t {
    fields {
        label : 20;
        exp : 3;
        bos : 1;
        ttl : 8;
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

header_type icmp_t {
    fields {
        typeCode : 16;
        hdrChecksum : 16;
    }
}

header_type gre_t {
    fields {
        C : 1;
        R : 1;
        K : 1;
        S : 1;
        s : 1;
        recurse : 3;
        flags : 5;
        ver : 3;
        proto : 16;
    }
}

header_type nvgre_t {
    fields {
        tni : 24;
        flow_id : 8;
    }
}

header_type roce_header_t {
    fields {
        ib_grh : 320;
        ib_bth : 96;
    }
}

header_type fcoe_header_t {
    fields {
        version : 4;
        type_ : 4;
        sof : 8;
        rsvd1 : 32;
        ts_upper : 32;
        ts_lower : 32;
        size_ : 32;
        eof : 8;
        rsvd2 : 24;
    }
}

header_type trill_t {
    fields {
        version : 2;
        reserved : 2;
        multiDestination : 1;
        optLength : 5;
        hopCount : 6;
        egressRbridge : 16;
        ingressRbridge : 16;
    }
}

header_type vntag_t {
    fields {
        direction : 1;
        pointer : 1;
        destVif : 14;
        looped : 1;
        reserved : 1;
        version : 2;
        srcVif : 12;
    }
}

header_type nsh_t {
    fields {
        oam : 1;
        context : 1;
        flags : 6;
        reserved : 8;
        protoType: 16;
        spath : 24;
        sindex : 8;
    }
}

header_type nsh_context_t {
    fields {
        network_platform : 32;
        network_shared : 32;
        service_platform : 32;
        service_shared : 32;
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
        0x0800 : parse_ipv4;
        0x9100 : parse_qinq; 0x8847 : parse_mpls; 0x86dd : parse_ipv6; 0x0806 : parse_arp_rarp; 0x894f : parse_nsh; 0x8915 : parse_roce; 0x8906 : parse_fcoe; 0x22f3 : parse_trill; 0x8926 : parse_vntag; 0x88cc : parse_set_prio_high; 0x8809 : parse_set_prio_high;

        default : ingress;
    }
}

header ipv4_t ipv4;

parser parse_ipv4 {
    extract(ipv4);
    return select(latest.fragOffset, latest.protocol) {
        6 : parse_tcp;
        17 : parse_udp;
        0x8847 : parse_mpls; 0x86dd : parse_ipv6; 0x0806 : parse_arp_rarp; 0x894f : parse_nsh; 0x8915 : parse_roce; 0x8906 : parse_fcoe; 0x22f3 : parse_trill; 0x8926 : parse_vntag; 0x88cc : parse_set_prio_high; 0x8809 : parse_set_prio_high;
        default: ingress;
    }
}

header vlan_tag_t vlan_tag;
header vlan_tag_t vlan_tag_1;

parser parse_vlan_tag {
    extract(vlan_tag);
    return select(latest.etherType) {
        0x0800 : parse_ipv4;
        0x8847 : parse_mpls; 0x86dd : parse_ipv6; 0x0806 : parse_arp_rarp; 0x894f : parse_nsh; 0x8915 : parse_roce; 0x8906 : parse_fcoe; 0x22f3 : parse_trill; 0x8926 : parse_vntag; 0x88cc : parse_set_prio_high; 0x8809 : parse_set_prio_high;
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

parser parse_qinq {
    extract(vlan_tag);
    return select(latest.etherType) {
        0x8100 : parse_qinq_vlan;
        0x8847 : parse_mpls; 0x86dd : parse_ipv6; 0x0806 : parse_arp_rarp; 0x894f : parse_nsh; 0x8915 : parse_roce; 0x8906 : parse_fcoe; 0x22f3 : parse_trill; 0x8926 : parse_vntag; 0x88cc : parse_set_prio_high; 0x8809 : parse_set_prio_high;
        default : ingress;
    }
}

parser parse_qinq_vlan {
    extract(vlan_tag_1);
    return select(latest.etherType) {
        0x0800 : parse_ipv4;
        0x8847 : parse_mpls; 0x86dd : parse_ipv6; 0x0806 : parse_arp_rarp; 0x894f : parse_nsh; 0x8915 : parse_roce; 0x8906 : parse_fcoe; 0x22f3 : parse_trill; 0x8926 : parse_vntag; 0x88cc : parse_set_prio_high; 0x8809 : parse_set_prio_high;
        default : ingress;
    }
}

parser parse_set_prio_med {
    set_metadata(ig_prsr_ctrl.priority, 3);
    return ingress;
}

parser parse_set_prio_high {
    set_metadata(ig_prsr_ctrl.priority, 5);
    return ingress;
}


parser parse_arp_rarp {
    return parse_set_prio_med;
}

header mpls_t mpls[3];

parser parse_mpls {
    extract(mpls[next]);
    return select(latest.bos) {
        0 : parse_mpls;
        1 : parse_mpls_bos;
        default: ingress;
    }
}

parser parse_mpls_bos {
    return select(current(0, 4)) {
        0x4 : parse_mpls_inner_ipv4;
        0x6 : parse_mpls_inner_ipv6;
        default: parse_eompls;
    }
}

parser parse_mpls_inner_ipv4 {
    set_metadata(l2_metadata.ingress_tunnel_type, 6);
    return parse_inner_ipv4;
}

parser parse_mpls_inner_ipv6 {
    set_metadata(l2_metadata.ingress_tunnel_type, 6);
    return parse_inner_ipv6;
}

parser parse_eompls {
    set_metadata(l2_metadata.ingress_tunnel_type, 6);
    return parse_inner_ethernet;
}

header ethernet_t inner_ethernet;

parser parse_inner_ethernet {
    extract(inner_ethernet);
    set_metadata(l2_metadata.lkp_mac_sa, latest.srcAddr);
    set_metadata(l2_metadata.lkp_mac_da, latest.dstAddr);
    return select(latest.etherType) {
        0x0800 : parse_inner_ipv4;
        0x86dd : parse_inner_ipv6;
        default: ingress;
    }
}


header ipv4_t inner_ipv4;

parser parse_inner_ipv4 {
    extract(inner_ipv4);
    set_metadata(l3_metadata.lkp_ip_proto, latest.protocol);
    set_metadata(l3_metadata.lkp_ip_ttl, latest.ttl);
    return select(latest.fragOffset, latest.ihl, latest.protocol) {
        0x501 : parse_inner_icmp;
        0x506 : parse_inner_tcp;
        0x511 : parse_inner_udp;
        default: ingress;
    }
}

header icmp_t inner_icmp;

parser parse_inner_icmp {
    extract(inner_icmp);
    set_metadata(l3_metadata.lkp_l4_sport, latest.typeCode);
    return ingress;
}

header tcp_t inner_tcp;

parser parse_inner_tcp {
    extract(inner_tcp);
    set_metadata(l3_metadata.lkp_l4_sport, latest.srcPort);
    set_metadata(l3_metadata.lkp_l4_dport, latest.dstPort);
    return ingress;
}

header udp_t inner_udp;

parser parse_inner_udp {
    extract(inner_udp);
    set_metadata(l3_metadata.lkp_l4_sport, latest.srcPort);
    set_metadata(l3_metadata.lkp_l4_dport, latest.dstPort);
    return ingress;
}

header gre_t gre;

parser parse_gre {
    extract(gre);
    return select(latest.C, latest.R, latest.K, latest.S, latest.s,
                  latest.recurse, latest.flags, latest.ver, latest.proto) {
        0x20006558 : parse_nvgre;
        0x0800 : parse_gre_ipv4;
        0x86dd : parse_gre_ipv6;
        default: ingress;
    }
}

header nvgre_t nvgre;

parser parse_nvgre {
    extract(nvgre);
    set_metadata(l2_metadata.ingress_tunnel_type,
                 5);
    set_metadata(l2_metadata.tunnel_vni, latest.tni);
    return parse_inner_ethernet;
}

parser parse_gre_ipv4 {
    set_metadata(l2_metadata.ingress_tunnel_type, 2);
    return parse_inner_ipv4;
}

parser parse_gre_ipv6 {
    set_metadata(l2_metadata.ingress_tunnel_type, 2);
    return parse_inner_ipv6;
}

header ipv6_t ipv6;

parser parse_ipv6 {
    extract(ipv6);
    return select(latest.nextHdr) {
        58 : parse_icmp;
        6 : parse_tcp;
        4 : parse_ipv4_in_ip;
        17 : parse_udp;
        47 : parse_gre;
        41 : parse_ipv6_in_ip;
        88 : parse_set_prio_med;
        89 : parse_set_prio_med;
        103 : parse_set_prio_med;
        112 : parse_set_prio_med;

        default: ingress;
    }
}

header icmp_t icmp;

parser parse_icmp {
    extract(icmp);
    set_metadata(l3_metadata.lkp_outer_l4_sport, latest.typeCode);
    return select(latest.typeCode) {

        0x8200 mask 0xfe00 : parse_set_prio_med;
        0x8400 mask 0xfc00 : parse_set_prio_med;
        0x8800 mask 0xff00 : parse_set_prio_med;
        default: ingress;
    }
}

parser parse_ipv4_in_ip {
    set_metadata(l2_metadata.ingress_tunnel_type,
                 3);
    return parse_inner_ipv4;
}

parser parse_ipv6_in_ip {
    set_metadata(l2_metadata.ingress_tunnel_type,
                 3);
    return parse_inner_ipv6;
}

header ipv6_t inner_ipv6;

parser parse_inner_ipv6 {
    extract(inner_ipv6);
    set_metadata(l3_metadata.lkp_ipv6_sa, latest.srcAddr);
    set_metadata(l3_metadata.lkp_ipv6_da, latest.dstAddr);
    set_metadata(l3_metadata.lkp_ip_proto, latest.nextHdr);
    set_metadata(l3_metadata.lkp_ip_ttl, latest.hopLimit);
    return select(latest.nextHdr) {
        58 : parse_inner_icmp;
        6 : parse_inner_tcp;
        17 : parse_inner_udp;
        default: ingress;
    }
}

header roce_header_t roce;

parser parse_roce {
    extract(roce);
    return ingress;
}

header fcoe_header_t fcoe;

parser parse_fcoe {
    extract(fcoe);
    return ingress;
}

header trill_t trill;

parser parse_trill {
    extract(trill);
    return parse_inner_ethernet;
}

header vntag_t vntag;

parser parse_vntag {
    extract(vntag);
    return parse_inner_ethernet;
}

header nsh_t nsh;
header nsh_context_t nsh_context;

parser parse_nsh {
    extract(nsh);
    extract(nsh_context);
    return select(nsh.protoType) {
        0x0800 : parse_inner_ipv4;
        0x86dd : parse_inner_ipv6;
        0x6558 : parse_inner_ethernet;
        default : ingress;
    }
}


header_type ingress_metadata_t {
    fields {
        vlan_id : 16;
        ingress_port : 9;
        egress_port : 9;
    }
}
metadata ingress_metadata_t ingress_metadata;

header_type l2_metadata_t {
    fields {
        lkp_mac_sa : 48;
        lkp_mac_da : 48;
        l2_src_miss : 1;
        l2_src_hit : 1;
        port_vlan_mapping_miss : 1;
        dst_override : 1;
        inter_stage : 32;
        inter_stage_dummy : 8;
        dummy_exm_key : 750;
        dummy_tcam_key : 40;
        ingress_tunnel_type : 32;
        tunnel_vni : 32;
        dummy_tcam_meta: 32;
    }
}

metadata l2_metadata_t l2_metadata;

header_type l3_metadata_t {
    fields {
        lkp_ip_type : 2;
        lkp_ip_version : 4;
        lkp_ip_proto : 8;
        lkp_dscp : 8;
        lkp_ip_ttl : 8;
        lkp_l4_sport : 16;
        lkp_l4_dport : 16;
        lkp_outer_l4_sport : 16;
        lkp_outer_l4_dport : 16;
        lkp_ipv6_sa : 128;
        lkp_ipv6_da : 128;
    }
}

metadata l3_metadata_t l3_metadata;



action nop() {
}

action do_nothing(){}


action set_meta0() {
    modify_field(l2_metadata.inter_stage, 0x1);
}
action stage_drop() {
    drop();
}

@pragma command_line --no-dead-code-elimination
table tbl_stage0 {
    reads {
        ethernet : valid;
    }
    actions {
        nop;
        set_meta0;
    }
    size: 2;
}

action set_meta1() {
    modify_field(l2_metadata.inter_stage, 0x2);
}

table tbl_stage1{
    reads {
        l2_metadata.inter_stage: ternary;
        l2_metadata.inter_stage_dummy: ternary;
    }
    actions {
        nop;
        set_meta1;
    }
    size: 12288;
}

action set_meta2() {
    modify_field(l2_metadata.inter_stage, 0x3);
}

table tbl_stage2{
    reads {
        l2_metadata.inter_stage: exact;
        l2_metadata.inter_stage_dummy: exact;
    }
    actions {
        nop;
        set_meta2;
    }
    size: 180000;
}

action set_meta3() {
    modify_field(l2_metadata.inter_stage, 0x4);
}

table tbl_stage3{
    reads {
        l2_metadata.inter_stage: ternary;
        l2_metadata.inter_stage_dummy: ternary;
    }
    actions {
        nop;
        set_meta3;
    }
    size: 12288;
}

action set_meta4() {
    modify_field(l2_metadata.inter_stage, 0x5);
}

table tbl_stage4{
    reads {
        l2_metadata.inter_stage: exact;
        l2_metadata.inter_stage_dummy: exact;
    }
    actions {
        nop;
        set_meta4;
    }
    size: 26000;
}

action set_meta5() {
    modify_field(l2_metadata.inter_stage, 0x6);
}

table tbl_stage5{
    reads {
        l2_metadata.inter_stage: ternary;
        l2_metadata.inter_stage_dummy: ternary;
    }
    actions {
        nop;
        set_meta5;
    }
    size: 12288;
}

action set_meta6() {
    modify_field(l2_metadata.inter_stage, 0x7);
}

table tbl_stage6{
    reads {
        l2_metadata.inter_stage: exact;
        l2_metadata.inter_stage_dummy: exact;
    }
    actions {
        nop;
        set_meta6;
    }
    size: 26000;
}

action set_meta7() {
    modify_field(l2_metadata.inter_stage, 0x8);
}

table tbl_stage7 {
    reads {
        l2_metadata.inter_stage: ternary;
        l2_metadata.inter_stage_dummy: ternary;
    }
    actions {
        nop;
        set_meta7;
    }
    size: 12288;
}

action set_meta8() {
    modify_field(l2_metadata.inter_stage, 0x9);
}

table tbl_stage8{
    reads {
        l2_metadata.inter_stage: exact;
        l2_metadata.inter_stage_dummy: exact;
    }
    actions {
        nop;
        set_meta8;
    }
    size: 26000;
}

action set_meta9() {
    modify_field(l2_metadata.inter_stage, 0xa);
}

table tbl_stage9{
    reads {
        l2_metadata.inter_stage: ternary;
        l2_metadata.inter_stage_dummy: ternary;
    }
    actions {
        nop;
        set_meta9;
    }
    size: 12288;
}

action set_meta10() {
    modify_field(l2_metadata.inter_stage, 0xb);
}

table tbl_stage10{
    reads {
        l2_metadata.inter_stage: exact;
        l2_metadata.inter_stage_dummy: exact;
    }
    actions {
        nop;
        set_meta10;
        stage_drop;
    }
    size: 26000;
}

action set_tbl_tcam_meta() {
   modify_field(l2_metadata.dummy_tcam_meta, 0x1234);
}

@pragma stage 0
table tbl_tcam_0{
    reads {
        l2_metadata.dummy_tcam_key: ternary;
    }
    actions {
        nop;
        do_nothing;
        set_tbl_tcam_meta;
    }
    size: 8000;
}

@pragma stage 2
table tbl_tcam_2{
    reads {
        l2_metadata.dummy_tcam_key: ternary;
    }
    actions {
        nop;
        do_nothing;
        set_tbl_tcam_meta;
    }
    size: 12288;
}

@pragma stage 3
table tbl_tcam_3{
    reads {
        l2_metadata.dummy_tcam_key: ternary;
    }
    actions {
        nop;
        do_nothing;
        set_tbl_tcam_meta;
    }
    size: 12288;
}


@pragma stage 5
table tbl_tcam_5{
    reads {
        l2_metadata.dummy_tcam_key: ternary;
    }
    actions {
        nop;
        do_nothing;
        set_tbl_tcam_meta;
    }
    size: 12288;
}

@pragma stage 7
table tbl_tcam_7{
    reads {
        l2_metadata.dummy_tcam_key: ternary;
    }
    actions {
        nop;
        do_nothing;
        set_tbl_tcam_meta;
    }
    size: 12288;
}

@pragma stage 9
table tbl_tcam_9{
    reads {
        l2_metadata.dummy_tcam_key: ternary;
    }
    actions {
        nop;
        do_nothing;
        set_tbl_tcam_meta;
    }
    size: 12288;
}

@pragma stage 11
table tbl_tcam_11{
    reads {
        l2_metadata.dummy_tcam_key: ternary;
    }
    actions {
        nop;
        do_nothing;
        set_tbl_tcam_meta;
    }
    size: 12288;
}






action set_ing_port_prop(exclusion_id, port) {
    modify_field(ig_intr_md_for_tm.level2_exclusion_id, exclusion_id);
    modify_field(ingress_metadata.ingress_port, port);
}

table ing_port_prop {
    reads {
        ig_intr_md.ingress_port : exact;
    }
    actions {
        set_ing_port_prop;
    }
    size : 512;
}

control process_ingress_port_properties {
    apply(ing_port_prop);
}





action set_ing_vlan(vid, ingress_rid) {
    modify_field(ingress_metadata.vlan_id, vid);
    modify_field(ig_intr_md_for_tm.rid, ingress_rid);
}

action port_vlan_miss() {
    drop();
}

@pragma ways 5
@pragma pack 8
table port_vlan_mapping {
    reads {
        ig_intr_md.ingress_port : exact;
        vlan_tag : valid;
        vlan_tag.vlan_id : exact;
    }

    actions {
        set_ing_vlan;
        port_vlan_miss;
    }

    size : 106000;
}





action def_vlan_miss() {
   drop();
}

action set_def_vlan(vid, ingress_rid) {
    modify_field(ingress_metadata.vlan_id, vid);
    modify_field(ig_intr_md_for_tm.rid, ingress_rid);
}

table def_vlan_mapping {
    reads {
        ig_intr_md.ingress_port : exact;
    }

    actions {
        set_def_vlan;
        def_vlan_miss;
    }

    size : 512;
}






action dmac_hit(port) {
    modify_field(ingress_metadata.egress_port, port);
    modify_field(ig_intr_md_for_tm.ucast_egress_port, port);
}

action dmac_mcast_hit(mc_index) {
    modify_field(ig_intr_md_for_tm.mcast_grp_b, mc_index);
}

action dmac_miss() {
    modify_field(ingress_metadata.egress_port, 65535);
    modify_field(ig_intr_md_for_tm.ucast_egress_port, 65535);
}

action dmac_drop() {
    drop();
}

@pragma ways 5
@pragma pack 8
table dmac {
    reads {
        ingress_metadata.vlan_id : exact;
        ethernet.dstAddr : exact;
    }
    actions {
        nop;
        dmac_hit;
        dmac_mcast_hit;
        dmac_miss;
        dmac_drop;
    }
    size : 4000;
    support_timeout: true;
}




action smac_miss() {
    modify_field(l2_metadata.l2_src_miss, 1);
}

action smac_hit() {
    modify_field(l2_metadata.l2_src_hit, 1);
}

@pragma ways 5
@pragma pack 8
table smac {
    reads {
        ingress_metadata.vlan_id : exact;
        ethernet.srcAddr : exact;
    }
    actions {
        nop;
        smac_miss;
        smac_hit;
    }
    size : 4000;
    support_timeout: true;
}

control process_mac {

    apply(smac);
    apply(dmac);
}




field_list mac_learn_digest {
    ingress_metadata.vlan_id;
    ethernet.srcAddr;
    ig_intr_md.ingress_port;
}

action generate_learn_notify() {
    generate_digest(0, mac_learn_digest);
}

table learn_notify {
    reads {
        l2_metadata.l2_src_miss : exact;
    }
    actions {
        nop;
        generate_learn_notify;
    }
    size : 2;
}

control process_mac_learning {
    apply(learn_notify);
}




action set_bd_flood_mc_index(mc_index) {
    modify_field(ig_intr_md_for_tm.mcast_grp_b, mc_index);
}

@pragma ways 5
@pragma pack 8
table bd_flood {
    reads {
        ingress_metadata.vlan_id : exact;
    }
    actions {
        nop;
        set_bd_flood_mc_index;
    }
    size : 16000;
}

control process_multicast_flooding {
    apply(bd_flood);
}

action ing_port_in_tcp_hdr() {
    modify_field(tcp.srcPort, ingress_metadata.ingress_port);
}

table ing_port_encode {
    reads {
        eg_intr_md.egress_port : exact;
    }
    actions {
        nop;
        ing_port_in_tcp_hdr;
    }
    size : 512;
}


action override_eg_port(port) {
    modify_field(l2_metadata.dst_override, 1);
    modify_field(ingress_metadata.egress_port, port);
    modify_field(ig_intr_md_for_tm.ucast_egress_port, port);
}

table dst_override {
    reads {
        ig_intr_md.ingress_port: exact;
        tcp.dstPort: range;
    }
    actions {
        override_eg_port;
    }
    size : 512;
}




action remove_vlan_single_tagged() {
    modify_field(ethernet.etherType, vlan_tag.etherType);
    remove_header(vlan_tag);
}

@pragma ternary 1
table vlan_decap {
    reads {
        vlan_tag: valid;
    }
    actions {
        nop;
        remove_vlan_single_tagged;
    }
    size: 2;
}

control process_vlan_decap {
    apply(vlan_decap);
}





action set_packet_vlan_tagged(vlan_id) {
    add_header(vlan_tag);
    modify_field(vlan_tag.etherType, ethernet.etherType);
    modify_field(vlan_tag.vlan_id, vlan_id);
    modify_field(ethernet.etherType, 0x8100);
}

action set_packet_vlan_untagged() {
}

table vlan_encap {
    reads {
        eg_intr_md.egress_port: exact;
        ingress_metadata.vlan_id: exact;
    }
    actions {
        set_packet_vlan_untagged;
        set_packet_vlan_tagged;
    }
    size : 150000;
}

control process_vlan_encap {
    apply(vlan_encap);
}


action set_exm_table_meta() {
}

@pragma stage 4
@pragma ways 5
table exm_table0_0{
      reads {
        ethernet.srcAddr : exact;
        ethernet.dstAddr : exact;
        ethernet.etherType : exact;
      }
      actions {
        do_nothing;
        set_exm_table_meta;
      }
      size : 7150;
}

@pragma stage 4
@pragma ways 5
table exm_table0_1{
      reads {
        ethernet.srcAddr : exact;
        ethernet.dstAddr : exact;
        ethernet.etherType : exact;
      }
      actions {
        do_nothing;
        set_exm_table_meta;
      }
      size : 7150;
}

@pragma ways 5
table exm_table3_0{
      reads {
        ethernet.srcAddr : exact;
        ethernet.dstAddr : exact;
        ethernet.etherType : exact;
        l2_metadata.inter_stage: exact;
        l2_metadata.dummy_exm_key: exact;
      }
      actions {
        do_nothing;
        set_exm_table_meta;
      }
      size : 7150;
}

@pragma ways 5
@pragma pack 8
table exm_table3_1{
      reads {
        ethernet.srcAddr : exact;
        ethernet.dstAddr : exact;
        ethernet.etherType : exact;
      }
      actions {
        do_nothing;
        set_exm_table_meta;
      }
      size : 7150;
}

@pragma ways 5
table exm_table4_0{
      reads {
        ethernet.srcAddr : exact;
        ethernet.dstAddr : exact;
        ethernet.etherType : exact;
        l2_metadata.inter_stage: exact;
        l2_metadata.dummy_exm_key: exact;
      }
      actions {
        do_nothing;
        set_exm_table_meta;
      }
      size : 5000;
}

@pragma ways 5
table exm_table4_1{
      reads {
        ethernet.srcAddr : exact;
        ethernet.dstAddr : exact;
        ethernet.etherType : exact;
        l2_metadata.inter_stage: exact;
        l2_metadata.dummy_exm_key: exact;
      }
      actions {
        do_nothing;
        set_exm_table_meta;
      }
      size : 5000;
}

@pragma ways 5
table exm_table5_0{
      reads {
        ethernet.srcAddr : exact;
        ethernet.dstAddr : exact;
        ethernet.etherType : exact;
        l2_metadata.inter_stage: exact;
        l2_metadata.dummy_exm_key: exact;
      }
      actions {
        do_nothing;
        set_exm_table_meta;
      }
      size : 5000;
}

@pragma ways 5
table exm_table5_1{
      reads {
        ethernet.srcAddr : exact;
        ethernet.dstAddr : exact;
        ethernet.etherType : exact;
        l2_metadata.inter_stage: exact;
        l2_metadata.dummy_exm_key: exact;
      }
      actions {
        do_nothing;
        set_exm_table_meta;
      }
      size : 5000;
}

@pragma ways 5
table exm_table6_0{
      reads {
        ethernet.srcAddr : exact;
        ethernet.dstAddr : exact;
        ethernet.etherType : exact;
        l2_metadata.inter_stage: exact;
        l2_metadata.dummy_exm_key: exact;
      }
      actions {
        do_nothing;
        set_exm_table_meta;
      }
      size : 5000;
}

@pragma ways 5
table exm_table6_1{
      reads {
        ethernet.srcAddr : exact;
        ethernet.dstAddr : exact;
        ethernet.etherType : exact;
        l2_metadata.inter_stage: exact;
        l2_metadata.dummy_exm_key: exact;
      }
      actions {
        do_nothing;
        set_exm_table_meta;
      }
      size : 5000;
}

@pragma ways 5
table exm_table7_0{
      reads {
        ethernet.srcAddr : exact;
        ethernet.dstAddr : exact;
        ethernet.etherType : exact;
        l2_metadata.inter_stage: exact;
        l2_metadata.dummy_exm_key: exact;
      }
      actions {
        do_nothing;
        set_exm_table_meta;
      }
      size : 5000;
}

@pragma ways 5
table exm_table7_1{
      reads {
        ethernet.srcAddr : exact;
        ethernet.dstAddr : exact;
        ethernet.etherType : exact;
        l2_metadata.inter_stage: exact;
        l2_metadata.dummy_exm_key: exact;
      }
      actions {
        do_nothing;
        set_exm_table_meta;
      }
      size : 5000;
}

@pragma ways 5
table exm_table8_0{
      reads {
        ethernet.srcAddr : exact;
        ethernet.dstAddr : exact;
        ethernet.etherType : exact;
        l2_metadata.inter_stage: exact;
        l2_metadata.dummy_exm_key: exact;
      }
      actions {
        do_nothing;
        set_exm_table_meta;
      }
      size : 5000;
}

@pragma ways 5
table exm_table8_1{
      reads {
        ethernet.srcAddr : exact;
        ethernet.dstAddr : exact;
        ethernet.etherType : exact;
        l2_metadata.inter_stage: exact;
        l2_metadata.dummy_exm_key: exact;
      }
      actions {
        do_nothing;
        set_exm_table_meta;
      }
      size : 5000;
}

@pragma ways 5
table exm_table9_0{
      reads {
        ethernet.srcAddr : exact;
        ethernet.dstAddr : exact;
        ethernet.etherType : exact;
        l2_metadata.inter_stage: exact;
        l2_metadata.dummy_exm_key: exact;
      }
      actions {
        do_nothing;
        set_exm_table_meta;
      }
      size : 5000;
}

@pragma ways 5
table exm_table9_1{
      reads {
        ethernet.srcAddr : exact;
        ethernet.dstAddr : exact;
        ethernet.etherType : exact;
        l2_metadata.inter_stage: exact;
        l2_metadata.dummy_exm_key: exact;
      }
      actions {
        do_nothing;
        set_exm_table_meta;
      }
      size : 5000;
}

@pragma ways 5
table exm_table10_0{
      reads {
        ethernet.srcAddr : exact;
        ethernet.dstAddr : exact;
        ethernet.etherType : exact;
        l2_metadata.inter_stage: exact;
        l2_metadata.dummy_exm_key: exact;
      }
      actions {
        do_nothing;
        set_exm_table_meta;
      }
      size : 5000;
}

@pragma ways 5
table exm_table10_1{
      reads {
        ethernet.srcAddr : exact;
        ethernet.dstAddr : exact;
        ethernet.etherType : exact;
        l2_metadata.inter_stage: exact;
        l2_metadata.dummy_exm_key: exact;
      }
      actions {
        do_nothing;
        set_exm_table_meta;
      }
      size : 5000;
}



control ingress {
    process_ingress_port_properties();

    apply(dst_override);





    apply(tbl_tcam_0);


    apply(tbl_stage0);
    apply(tbl_stage1);

    if (l2_metadata.dst_override == 0) {

        if (vlan_tag.vlan_id != 0) {
            apply(port_vlan_mapping);
        } else {
            apply(def_vlan_mapping);
        }



        apply(tbl_tcam_2);



        process_mac();
        if (ingress_metadata.egress_port == 65535) {

            process_multicast_flooding();
        }
        if (ingress_metadata.vlan_id != 0) {
            process_mac_learning();
        }
    }
    apply(tbl_stage2);



    apply(tbl_tcam_3);
    apply(exm_table0_0);
    apply(exm_table0_1);
    apply(exm_table3_0);
    apply(exm_table3_1);


    apply(tbl_stage3);



    apply(exm_table4_0);
    apply(exm_table4_1);


    apply(tbl_stage4);



    apply(tbl_tcam_5);
    apply(exm_table5_0);
    apply(exm_table5_1);


    apply(tbl_stage5);



    apply(exm_table6_0);
    apply(exm_table6_1);


    apply(tbl_stage6);



    apply(tbl_tcam_7);
    apply(exm_table7_0);
    apply(exm_table7_1);


    apply(tbl_stage7);



    apply(exm_table8_0);
    apply(exm_table8_1);


    apply(tbl_stage8);



    apply(tbl_tcam_9);
    apply(exm_table9_0);
    apply(exm_table9_1);


    apply(tbl_stage9);



    apply(exm_table10_0);
    apply(exm_table10_1);


    apply(tbl_stage10);



    apply(tbl_tcam_11);



}

control egress {

    if (l2_metadata.dst_override == 0) {

        process_vlan_decap();

        process_vlan_encap();
    }


    apply(ing_port_encode);
}
