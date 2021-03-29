/* -*- P4_14 -*- */

#include <tofino/constants.p4>
#include <tofino/intrinsic_metadata.p4>
#include <tofino/primitives.p4>

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
        ingress_port : 9;
        mac_addr     : 48;
    }
}
metadata m_t m;

/*************************************************************************
 ***********************  P A R S E R  ***********************************
 *************************************************************************/
header ethernet_t ethernet;

parser start {
    extract(ethernet);
    set_metadata(m.ingress_port, ig_intr_md.ingress_port);
    set_metadata(m.mac_addr, ethernet.dstAddr);
    return ingress;
}

/*************************************************************************
 **************  I N G R E S S   P R O C E S S I N G   *******************
 *************************************************************************/
action swap_mac() {
    modify_field(ig_intr_md_for_tm.ucast_egress_port, m.ingress_port);
    modify_field(ethernet.dstAddr, ethernet.srcAddr);
    modify_field(ethernet.srcAddr, m.mac_addr);
}

table t {
    actions { swap_mac; }
    default_action: swap_mac();
    size : 1;
}

control ingress {
    apply(t);
}

/*************************************************************************
 ****************  E G R E S S   P R O C E S S I N G   *******************
 *************************************************************************/
control egress {
}


