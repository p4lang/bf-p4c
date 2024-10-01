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
        dest : 48;
        src  : 48;
        type : 16;
    }
}

header_type h1_t {
    fields {
        ig_err   : 16;
        eg_err   : 16;
        len      : 16;
    }
}

header_type padding_t {
    fields {
        padding : 320;  // 40 byte to make minimum 64-byte ethernet frame
    }
}

header_type h2_t {
    fields {
        data  : 512;
    }
}

/*************************************************************************
 ***********************  M E T A D A T A  *******************************
 *************************************************************************/

/*************************************************************************
 ***********************  P A R S E R  ***********************************
 *************************************************************************/
header ethernet_t ethernet;
header h1_t h1;
header padding_t padding;
header h2_t h2;

parser start {
    extract(ethernet);
    return parse_h1;
}

parser parse_h1 {
    extract(h1);
    return parse_padding;
}

parser parse_padding {
    extract(padding);
    return select(h1.ig_err) {
        0x0 : parse_h2;
        default : ingress;
    }    
}

parser parse_h2 {
    extract(h2);
    return ingress;
}

/*************************************************************************
 **************  I N G R E S S   P R O C E S S I N G   *******************
 *************************************************************************/
action send_back() {
    modify_field(h1.ig_err, ig_intr_md_from_parser_aux.ingress_parser_err);
    modify_field(ig_intr_md_for_tm.ucast_egress_port, ig_intr_md.ingress_port);
}

table t1 {
    actions { send_back; }
    default_action: send_back();
    size: 1;
}

control ingress {
    apply(t1);
}

/*************************************************************************
 ****************  E G R E S S   P R O C E S S I N G   *******************
 *************************************************************************/
action fix_length() {
    modify_field(h1.eg_err, eg_intr_md_from_parser_aux.egress_parser_err);
    modify_field(h1.len, eg_intr_md.pkt_length);
}

table t2 {
    actions { fix_length; }
    default_action: fix_length();
    size: 1;
}

control egress {
    apply(t2);
}
