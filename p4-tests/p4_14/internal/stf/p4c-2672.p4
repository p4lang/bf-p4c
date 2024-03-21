/* -*- P4_14 -*- */

#include <tofino/intrinsic_metadata.p4>
#include <tofino/constants.p4>

#define CASE_FIX_1
header_type ethernet_t {
    fields {
        dstAddr : 48;
        srcAddr : 48;
        etherType : 16;
    }
}
header ethernet_t ethernet;

header_type my_header_t {
    fields {
#ifdef CASE_FIX_2
        a: 32;
        b: 32;
        c: 32;
        d: 32;
        e: 32;
#else
        a: 8;
        b: 8;
        c: 8;
        d: 8;
        e: 8;
#endif
    }
}
header my_header_t my_header;

header_type my_md_t {
    fields {
#ifdef CASE_FIX_1
        a: 32;
        b: 32;
        c: 32;
        d: 32;
        e: 32;
#else
        a: 32 (signed);
        b: 32 (signed);
        c: 32 (signed);
        d: 32 (signed);
        e: 32 (signed);
#endif
    }
}
metadata my_md_t my_md;

#define MY_HEADER 0x1234

parser start {
    return parse_ethernet;
}

parser parse_ethernet {
    extract(ethernet);
    return select(latest.etherType) {
        MY_HEADER: parse_my_header;
        default: ingress;
    }
}

parser parse_my_header {
    extract(my_header);
    set_metadata(my_md.a, 0x3c);
    set_metadata(my_md.b, 0xa);
    set_metadata(my_md.c, 0xfffffff1);
    set_metadata(my_md.d, 0xa0);
    set_metadata(my_md.e, 0xfedcba98);
    return ingress;
}

action set_egr(egress_spec) {
    modify_field(ig_intr_md_for_tm.ucast_egress_port, egress_spec);
    bypass_egress();
}

table forward {
    reads {
        ethernet.dstAddr : exact;
    }
    actions {
        set_egr;
    }
    default_action: set_egr(2);
}

action do_test() {
    modify_field_with_shift(my_header.a, my_md.a, 24, 0xff);
    modify_field_with_shift(my_header.b, my_md.b, 24, 0xff);
    modify_field_with_shift(my_header.c, my_md.c, 24, 0xff);
    modify_field_with_shift(my_header.d, my_md.d, 24, 0xff);
    modify_field_with_shift(my_header.e, my_md.e, 24, 0xff);
}

table test {
    actions { do_test; }
    default_action: do_test();
    size: 1;
}

control ingress {
    apply(forward);
    apply(test);
}
