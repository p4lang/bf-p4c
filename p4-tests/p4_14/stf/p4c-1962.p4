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
#ifndef REG_WIDTH
#define REG_WIDTH 16
#endif

#if (REG_WIDTH != 8) && (REG_WIDTH != 16) && (REG_WIDTH != 32)
#error The only supported REG_WIDTH values are 8, 16 and 32
#endif

header_type h_t {
    fields {
        hi   : REG_WIDTH;
        lo   : REG_WIDTH;
        pad  : 4;
        res  : 4;
    }
}

/*************************************************************************
 ***********************  M E T A D A T A  *******************************
 *************************************************************************/

/*************************************************************************
 ***********************  P A R S E R  ***********************************
 *************************************************************************/
header h_t h;

parser start {
    extract(h);
    return ingress;
}

/*************************************************************************
 **************  I N G R E S S   P R O C E S S I N G   *******************
 *************************************************************************/
register r1 {
    width          : REG_WIDTH;
    instance_count : 1;
}

blackbox stateful_alu b1 {
    reg: r1;
    initial_register_lo_value : 0;

    condition_hi: h.hi < 10;
    condition_lo: h.lo < 10;

    output_predicate: true;
    output_value:     predicate;
    output_dst:       h.res;
}

action do_b1() {
    modify_field(ig_intr_md_for_tm.ucast_egress_port, ig_intr_md.ingress_port);
    b1.execute_stateful_alu(0);
}

table t1 {
    actions { do_b1; }
    default_action: do_b1();
    size : 1;
}

control ingress {
    apply(t1);
}

/*************************************************************************
 ****************  E G R E S S   P R O C E S S I N G   *******************
 *************************************************************************/
control egress {
}

