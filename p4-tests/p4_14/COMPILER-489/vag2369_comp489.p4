/* -*- P4_14 -*- */

#ifdef __TARGET_TOFINO__
#include <tofino/constants.p4>
#include <tofino/intrinsic_metadata.p4>
#include <tofino/primitives.p4>
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

/*************************************************************************
 ***********************  M E T A D A T A  *******************************
 *************************************************************************/
header_type meta_t {
    fields {
        hash : 16;
    }
}
metadata meta_t meta; 
/*************************************************************************
 ***********************  P A R S E R  ***********************************
 *************************************************************************/
header ethernet_t ethernet;

parser start {
    extract(ethernet);
    return ingress;
}

/*************************************************************************
 **************  I N G R E S S   P R O C E S S I N G   *******************
 *************************************************************************/
action noop() {}

field_list hash_list {
    ethernet.dstAddr;
    ethernet.srcAddr;
}

field_list_calculation hash_calc {
    input         { hash_list; }
    algorithm:    crc16;
    output_width: 16;
}

action do_hash() {
    modify_field_with_hash_based_offset(meta.hash, 0, hash_calc, 0x10000);
}

table calculate_hash {
    actions { do_hash; }
    default_action : do_hash();
    size : 1;
}

counter c1p {
    type           : packets;
    static         : count_packets;
    instance_count : 65536;
}

action update_c1p() {
//    modify_field(ethernet.dstAddr, 0xFFFFFFFFFFFF);
    count(c1p, meta.hash);
}

@pragma use_hash_action 0
table count_packets {
    reads {
        ig_intr_md.ingress_port mask 1 : exact;
    }
    actions { update_c1p; noop; }
    //default_action: update_c1p();
    size : 2;
}

action do_forward() {
    modify_field(ig_intr_md_for_tm.ucast_egress_port, 0);
}

table forward {
    actions { do_forward; }
    default_action : do_forward();
    size : 1;
}

control ingress {
    apply(calculate_hash);
    apply(count_packets);
    apply(forward);
}

/*************************************************************************
 ****************  E G R E S S   P R O C E S S I N G   *******************
 *************************************************************************/
control egress {
}


