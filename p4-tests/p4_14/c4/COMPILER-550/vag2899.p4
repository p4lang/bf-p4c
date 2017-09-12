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
        /* dstAddr is split */
        lb_type         : 2;    
        zero_fill       : 1;    
        lb_group        : 3;    
        one_zero_fill   : 2;    
        lb_port         : 8;    
        lower_dmac      : 32;   
        /* The rest is as usual */
        srcAddr         : 48;
        etherType       : 16;
   }
}

/*************************************************************************
 ***********************  M E T A D A T A  *******************************
 *************************************************************************/
header_type metadata_t {
    fields {
        lb_type             : 2;
        zero_fill           : 1;
        lb_group            : 3;
        one_zero_fill       : 2;
        lb_port             : 8;
    }
}
#ifdef VAG_FIX
@pragma pa_container_size ingress meta.lb_port 8
#endif
metadata metadata_t meta;

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
action init_meta() {
    modify_field(meta.lb_type, 0);
    modify_field(meta.zero_fill, 0);
    modify_field(meta.lb_group, 0);
    modify_field(meta.one_zero_fill, 2);
}

table t0 {
    actions {
        init_meta;
    }
    default_action: init_meta();
    size: 1;
}

action set_lb_group(group) {
    modify_field(meta.lb_group, group);
}

table t1 {
    reads {
        ethernet.srcAddr : exact;
    }
    actions {
        set_lb_group;
    }
}

action set_lb_port(port) {
    modify_field(meta.lb_port, port);
}

table t2 {
    reads {
        ethernet.srcAddr : exact;
    }
    actions {
        set_lb_port;
    }
}

action re_encap_and_send(port) {
    modify_field(ethernet.lb_type,       meta.lb_type);
    modify_field(ethernet.zero_fill,     meta.zero_fill);
    modify_field(ethernet.lb_group,      meta.lb_group);
    modify_field(ethernet.one_zero_fill, meta.one_zero_fill);
    modify_field(ethernet.lb_port,       meta.lb_port);
    modify_field(ig_intr_md_for_tm.ucast_egress_port, port);
}

table t3 {
    reads {
        ethernet.etherType : ternary;
    }
    actions {
        re_encap_and_send;
    }
}

control ingress {
    apply(t0);
    apply(t1);
    apply(t2);
    apply(t3);
}

/*************************************************************************
 ****************  E G R E S S   P R O C E S S I N G   *******************
 *************************************************************************/
control egress {
}


