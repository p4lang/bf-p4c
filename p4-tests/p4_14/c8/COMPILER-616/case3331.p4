header_type ingress_md_t {
    fields {
 usds : 2;
 cp : 1;
 line_id : 32;
 subsc_id : 8;
        pppoe_ip_packet_len : 16;

 meter_result : 2;

    }
}

metadata ingress_md_t ingress_md;


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
header cpu_header_t cpu_header;

parser start {
    return parse_ethernet_outer;
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
 0x0021: parse_ipv4;

 0x0057: parse_ipv6;

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
    set_metadata(ingress_md.pppoe_ip_packet_len, ipv4.totalLen);
    return ingress;
}


header ipv6_t ipv6;

parser parse_ipv6 {
    extract(ipv6);
    set_metadata(ingress_md.pppoe_ip_packet_len, ipv6.payloadLen);
    return ingress;
}

#include "tofino/intrinsic_metadata.p4"
#include "tofino/constants.p4"
action _nop() { }






table t_usds {
    reads {
        ethernet_outer.dstAddr : exact;

        ig_intr_md.ingress_port : exact;



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







    modify_field(ingress_md.usds, 0x1);
}
table t_line_map {
    reads {

        ig_intr_md.ingress_port : exact;



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

    modify_field(ig_intr_md_for_tm.ucast_egress_port, cp_port);



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
    max_size : 4096;
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
        ipv4.srcAddr : lpm;
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
        ipv6.srcAddr : lpm;
    }
    actions {
        _drop;
        a_antispoof_ipv4v6_pass;
    }
    max_size : 4096;
}





table t_us_routev4 {
    reads {
        vlan_service.vlanID : exact;



        ipv4.dstAddr : lpm;

    }
    actions {
        _drop;
        a_us_routev4v6;
    }
    max_size : 256;
}

action a_us_routev4v6(out_port, mpls_label, via_hwaddr) {
    remove_header(vlan_service);

    modify_field(ig_intr_md_for_tm.ucast_egress_port, out_port);



    modify_field(mpls0.label, mpls_label);
    modify_field(mpls0.s, 1);
    modify_field(ethernet_outer.dstAddr, via_hwaddr);



}





table t_us_routev6 {
    reads {
        vlan_service.vlanID : exact;



        ipv6.dstAddr : lpm;
    }
    actions {
        _drop;
        a_us_routev4v6;
    }
    max_size : 256;
}
table t_ds_routev4 {
    reads {



        ipv4.dstAddr : lpm;
    }
    actions {
        _drop;
        a_ds_route_pushstack;
    }
    max_size : 256;
}

action a_ds_route_pushstack(mpls0_label, mpls1_label, subsc_vid, service_vid,
                                pppoe_session_id, out_port, inner_cpe_mac, lawf_int, ctr_bucket) {

    modify_field(mpls0.label, mpls0_label);
    modify_field(mpls0.s, 0);

    modify_field(mpls0.tc, 0);
    modify_field(mpls0.ttl, 0);

    add_header(mpls1);
    modify_field(mpls1.label, mpls1_label);
    modify_field(mpls1.s, 1);

    modify_field(mpls1.tc, 0);
    modify_field(mpls1.ttl, 0);


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

    modify_field(pppoe.code, 0);
    modify_field(pppoe.protocol, 0);
    modify_field(pppoe.totalLength, ingress_md.pppoe_ip_packet_len);
    modify_field(pppoe.sessionID, pppoe_session_id);



    modify_field(ig_intr_md_for_tm.ucast_egress_port, out_port);



    count(ctr_ds_subsc, ctr_bucket);
    execute_meter(mtr_ds_subsc, ctr_bucket, ingress_md.meter_result);

}





table t_ds_routev6 {
    reads {



        ipv6.dstAddr : lpm;
    }
    actions {
        _drop;
        a_ds_route_pushstack;
    }
    max_size : 256;
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
table t_us_srcmac {
    reads {

        ig_intr_md_for_tm.ucast_egress_port : exact;



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




table t_ds_pppoe_aftermath_v4 {
    actions {
        a_ds_pppoe_aftermath_v4;
    }
}

action a_ds_pppoe_aftermath_v4() {
    modify_field(pppoe.protocol, 0x0021);

    add_to_field(pppoe.totalLength, 2);
}





table t_ds_pppoe_aftermath_v6 {
    actions {
        a_ds_pppoe_aftermath_v6;
    }
}

action a_ds_pppoe_aftermath_v6() {
    modify_field(pppoe.protocol, 0x0057);

    add_to_field(pppoe.totalLength, 0x2a);
}






table t_ds_srcmac {
    reads {

        ig_intr_md_for_tm.ucast_egress_port : exact;



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
                apply(t_us_routev4);

            } else if (valid(ipv6)) {
                apply(t_antispoof_ipv6);
                apply(t_us_routev6);

            }
        }
    } else if (ingress_md.usds == 0x0) {
        if (valid(ipv4)) {
            apply(t_ds_routev4);
            apply(t_ds_pppoe_aftermath_v4);

        } else if (valid(ipv6)) {
            apply(t_ds_routev6);
            apply(t_ds_pppoe_aftermath_v6);

        }

        apply(t_meter_action);

    }
}


control egress {
    if (ingress_md.cp == 0) {
        if (ingress_md.usds == 0x1) {
            apply(t_us_srcmac);
        } else {
            apply(t_ds_srcmac);
        }
    }
}
