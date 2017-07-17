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
action set_egr() {
    modify_field(ig_intr_md_for_tm.ucast_egress_port, 1);
}

table forward {
    actions { set_egr; }
    default_action: set_egr();
    size : 1;
}

control ingress {
    apply(forward);
}

/*************************************************************************
 ****************  E G R E S S   P R O C E S S I N G   *******************
 *************************************************************************/
action do_length() {
    add(ethernet.etherType, eg_intr_md.pkt_length, 10);
}

table adjust_length {
    actions { do_length; }
    default_action : do_length();
    size : 1;
}

control egress {
    apply(adjust_length);
}


