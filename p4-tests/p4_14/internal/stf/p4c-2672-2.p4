/* -*- P4_14 -*- */

#include <tofino/intrinsic_metadata.p4>
#include <tofino/constants.p4>

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
        a: 32;
        b: 32;
        c: 32;
        d: 8;
        e: 8;
    }
}
header my_header_t my_header;

header_type my_md_t {
    fields {
        a: 32 (signed);
        b: 32 (signed);
        c: 32 (signed);
        d: 32 (signed);
        e: 32 (signed);
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
    set_metadata(my_md.a, 0x3abcdef1);
    set_metadata(my_md.b, 0xa6543210);
    set_metadata(my_md.c, 0xffeeddf1);
    set_metadata(my_md.d, 0xa0123456);
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
    modify_field_with_shift(my_header.a, my_md.a, 5, 0xffff);
    modify_field_with_shift(my_header.b, my_md.b, 25, 0xff);
    modify_field_with_shift(my_header.c, my_md.c, 24, 0xff);
    modify_field_with_shift(my_header.d, my_md.d, 32, 0xff);
    modify_field_with_shift(my_header.e, my_md.e, 23, 0xff);
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
