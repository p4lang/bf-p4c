/* -*- P4_14 -*- */

#ifdef __TARGET_TOFINO__
#include <tofino/constants.p4>
#include <tofino/intrinsic_metadata.p4>
#include <tofino/primitives.p4>
#include <tofino/stateful_alu_blackbox.p4>
#else
#error This program is intended to compile for Tofino P4 architecture only
#endif


/*************************************************************************
 ***********************  H E A D E R S  *********************************
 *************************************************************************/
header_type ethernet_t {
    fields {
        dstAddr   : 48;
        srcAddr   : 48;
        etherType : 16;
    }
}

header_type udp_t {
    fields {
        srcPort : 16;
        dstPort : 16;
        length_ : 16 (saturating);
        udpChecksum : 16;
    }
}

header_type ipv4_t {
    fields {
        version        : 4;
        ihl            : 4;
        diffserv       : 8;
        totalLen       : 16;
        identification : 16;
        flags          : 3;
        fragOffset     : 13;
        ttl            : 8;
        protocol       : 8;
        hdrChecksum    : 16;
        srcAddr        : 32;
        dstAddr        : 32;
    }
}

header_type rtp_t {
    fields {
        //version : 2;
        //padding : 1;
        //extension : 1;
        //CSRC_count : 4;
        padding : 8;
        marker : 1;
        payload_type : 7;
        sequence_number : 16;
        padding2 : 32;
        padding3 : 32;
        //timestamp : 16;
        //timestamp2 : 16;
        //SSRC : 32;
    }
}

field_list udp_checksum_list {
    ipv4.srcAddr;
    ipv4.dstAddr;
    udp.srcPort;
    udp.dstPort;

    payload;
}

field_list_calculation udp_checksum {
    input {
        udp_checksum_list;
    }
    algorithm : csum16;
    output_width : 16;
}

calculated_field udp.udpChecksum {
    //verify udp_checksum;
    update udp_checksum if (liveos_metadata.calculate == 1) ;
}


/*************************************************************************
 ***********************  M E T A D A T A  *******************************
 *************************************************************************/
header_type liveos_metadata_t {
    fields {
        calculate : 1;
    }
}

header_type sqn_t {
    fields {
        sqn_number_hi : 16;
        sqn_number_lo : 16;
        index: 16;
    }
}

header_type clean_switch_t {
    fields {
        index: 16;
        forward_state: 8;
        drop_state: 8;
        index_to_update: 8;
        new_stream: 8;
        marker: 1;
        register_to_use: 2;
    }
}


metadata liveos_metadata_t liveos_metadata;
metadata clean_switch_t clean_switch;

/*************************************************************************
 ***********************  P A R S E R  ***********************************
 *************************************************************************/
header ethernet_t       ethernet;
header ipv4_t           ipv4;
header udp_t            udp;
header rtp_t            rtp;


parser start {
    return parse_ethernet;
}

parser parse_ethernet {
    extract(ethernet);
    return select(ethernet.etherType) {
        0x0800 : parse_ipv4;
        default: ingress;
    }
}

#define PROTOCOL_UDP  0x0000511
parser parse_ipv4 {
    extract(ipv4);
    return select(ipv4.fragOffset, ipv4.ihl, ipv4.protocol) {
        PROTOCOL_UDP: parse_udp;
        default: ingress;
    }
}


parser parse_udp {
    extract(udp);
    return ingress;
}


/*************************************************************************
 **************  I N G R E S S   P R O C E S S I N G   *******************
 *************************************************************************/
 counter ipv4_host_stats {
    type   : packets_and_bytes;
    direct : ipv4_host;
}

action send(port) {
    modify_field(ig_intr_md_for_tm.ucast_egress_port, port);
}

action discard() {
    modify_field(ig_intr_md_for_tm.drop_ctl, 1);
}

action multicast(group) {
    modify_field(ig_intr_md_for_tm.mcast_grp_a, group);
}

table ipv4_host {
    reads {
        ipv4.dstAddr : exact;
        udp.dstPort : exact;
        ig_intr_md.ingress_port : exact;
    }
    actions {
        send;
        discard;
        multicast;
    }
    size : 32768;
}


 control ingress {
    if (valid(udp)) {
        apply(ipv4_host);
    }
}


/*************************************************************************
 ****************  E G R E S S   P R O C E S S I N G   *******************
 *************************************************************************/
register forward_reg1 {
width: 16;
instance_count: 8192;
}

register forward_reg2 {
     width: 16;
     instance_count: 8192;
 }

register save_marker {
    width: 8;
    direct: mcast_mods;
}

blackbox stateful_alu update_save_marker {
    reg: save_marker;
    condition_lo: rtp.marker == 1;
    update_lo_1_predicate: condition_lo;
    update_lo_1_value: 1;
    update_lo_2_predicate: not condition_lo;
    update_lo_2_value: 0;
    output_value: register_lo;
    output_dst: clean_switch.marker;
}

blackbox stateful_alu update_forward_state1 {
    reg: forward_reg1;
    condition_lo: ((register_hi == 1) && (clean_switch.marker == 1));

    update_lo_1_predicate: condition_lo;
    update_lo_1_value: register_lo^0x1;
    output_value: alu_lo;
    output_dst: eg_intr_md_for_oport.drop_ctl;

    update_hi_1_predicate: condition_lo;
    update_hi_1_value: 0;

    initial_register_lo_value: 0;
    initial_register_hi_value: 0;
}

blackbox stateful_alu update_clean_switch_state1 {
     reg: forward_reg2;

     condition_lo: ((register_hi == 1));
     update_hi_1_value: eg_intr_md_for_oport.drop_ctl;

     initial_register_lo_value: 0;
     initial_register_hi_value: 0;

 }

 blackbox stateful_alu update_clean_switch_state2 {
     reg: forward_reg1;

     condition_lo: ((register_hi == 1));
     update_hi_1_value: eg_intr_md_for_oport.drop_ctl;

     initial_register_lo_value: 0;
     initial_register_hi_value: 0;

 }

blackbox stateful_alu update_forward_state2 {
     reg: forward_reg2;
     condition_lo: ((register_hi == 1) && (clean_switch.marker == 1));

     update_lo_1_predicate: condition_lo;
     update_lo_1_value: register_lo^0x1;
     output_value: alu_lo;
     output_dst: eg_intr_md_for_oport.drop_ctl;

     update_hi_1_predicate: condition_lo;
     update_hi_1_value: 0;

     initial_register_lo_value: 0;
     initial_register_hi_value: 0;
 }

action update_state1() {
    update_forward_state1.execute_stateful_alu(clean_switch.index);
    update_clean_switch_state1.execute_stateful_alu(clean_switch.index);
}

action update_state2() {
     update_forward_state2.execute_stateful_alu(clean_switch.index);
     update_clean_switch_state2.execute_stateful_alu(clean_switch.index);
 }

action do_nat(dst_ip, dst_port, dst_mac, src_ip, index, cs_index, register_to_use) {
      modify_field(ipv4.srcAddr,src_ip);
      modify_field(ipv4.dstAddr,dst_ip);
      modify_field(udp.dstPort, dst_port);
      modify_field(ethernet.dstAddr, dst_mac);
      add_to_field(ipv4.ttl, -1);        // Just for fun :)
      //modify_field(liveos_metadata.calculate, 1);
      modify_field(clean_switch.index, cs_index);
      modify_field(clean_switch.register_to_use, register_to_use);
      update_save_marker.execute_stateful_alu();
      modify_field(udp.udpChecksum, 0);
}

action do_nat_no_src(dst_ip, dst_port, dst_mac, index, cs_index, register_to_use) {
      modify_field(ipv4.dstAddr,dst_ip);
      modify_field(udp.dstPort, dst_port);
      modify_field(ethernet.dstAddr, dst_mac);
      add_to_field(ipv4.ttl, -1);        // Just for fun :)
      //modify_field(liveos_metadata.calculate, 1);
      modify_field(clean_switch.index, cs_index);
      modify_field(clean_switch.register_to_use, register_to_use);
      update_save_marker.execute_stateful_alu();
      modify_field(udp.udpChecksum, 0);
}

/* Do not forget to define the most important action: no modifications */
action nop() {
    update_save_marker.execute_stateful_alu();
}

action do_nothing() {

}

/*
 * Define a table that chooses the right modification, based on destination
 * IP address and RID
 */
table mcast_mods {
    reads {
        ipv4.dstAddr          : exact;
        udp.dstPort           : exact;
        eg_intr_md.egress_rid : exact;
    }
    actions {
        do_nat;
        do_nat_no_src;
        nop;
    }
    size : 8192;
}

table no_checksum {
    actions {
        disable_checksum;
    }
}

@pragma stage 2
table update_states_table {
    reads {
        clean_switch.register_to_use : exact;

    }
    actions {
        update_state1;
        update_state2;
    }
}



control egress {
    if (valid(udp)) {
        apply(mcast_mods);
        apply(update_states_table);
    }
}
