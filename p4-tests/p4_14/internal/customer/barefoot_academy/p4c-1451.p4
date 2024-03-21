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

/*************************************************************************
 ***********************  M E T A D A T A  *******************************
 *************************************************************************/
header_type m_t {
    fields {
        f1 : 16;
    }
}
metadata m_t m;

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
field_list l1 {
    ethernet.dstAddr;
    ethernet.srcAddr;
    m.f1;
}

field_list_calculation c1 {
    input { l1; }
    algorithm: crc16;
    output_width: 16;
}

action do_seq(data) {
    modify_field(m.f1, data);
    modify_field_with_hash_based_offset(ethernet.etherType, 0, c1, 0x10000);
    modify_field(ig_intr_md_for_tm.ucast_egress_port, ig_intr_md.ingress_port);
}

table t1 {
    reads {
        ethernet.etherType : exact;
    }
    actions { do_seq; }
}

control ingress {
    apply(t1);
}

/*************************************************************************
 ****************  E G R E S S   P R O C E S S I N G   *******************
 *************************************************************************/
control egress {
}


