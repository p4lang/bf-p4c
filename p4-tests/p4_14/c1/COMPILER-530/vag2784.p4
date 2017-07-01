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
        etherType : 16;
        srcAddr   : 48;
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
action noop() { }

action set_egr(port) {
    modify_field(ig_intr_md_for_tm.ucast_egress_port, port);
}

table t1 {
    reads {
        ethernet.etherType mask 0xFFF : exact;
        ethernet.dstAddr              : exact;
        ethernet.srcAddr              : exact;
    }
    actions {
        noop;
        set_egr;
    }
    size: 4096;
}

table t2 {
    reads {
        ethernet.dstAddr              : exact;
        ethernet.etherType mask 0xFFF : exact;
        ethernet.srcAddr              : exact;
    }
    actions {
        noop;
        set_egr;
    }
    size: 4096;
}

table t3 {
    reads {
        ethernet.dstAddr              : exact;
        ethernet.srcAddr              : exact;
        ethernet.etherType mask 0xFFF : exact;
    }
    actions {
        noop;
        set_egr;
    }
    size: 4096;
}

control ingress {
    apply(t1);
    apply(t2);
    apply(t3);
}

/*************************************************************************
 ****************  E G R E S S   P R O C E S S I N G   *******************
 *************************************************************************/
control egress {
}



