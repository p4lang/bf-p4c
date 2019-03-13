/** The purpose of this test is to test if the instructions interacting with the fields
 *  contained in multiple containers are at all possible to interact with each other, and
 *  test whether a part of a container can be adjusted 
 */
header_type hdr_t {
    fields {
        f1 : 32;
        f2 : 32;
        f3 : 32;
        n1 : 4;
        x1 : 6;
        x2 : 6;
        x3 : 6;
        x4 : 6;
        n2 : 4;
    }
}

header hdr_t hdr;

header_type offset_meta_t {
    fields {
        x1 : 6;
        x2 : 6;
    }
}

metadata offset_meta_t offset_meta;

parser start {
    extract(hdr);
    return ingress;
}

action set_offset(off_val1, off_val2) {
    modify_field(offset_meta.x1, off_val1);
    modify_field(offset_meta.x2, off_val2);
}

table offset {
    reads {
        hdr.f1 : exact;
    }
    actions {
        set_offset;
    }
}

action adjust_first() {
    modify_field(hdr.x1, offset_meta.x1);
    modify_field(hdr.x2, offset_meta.x2);
}

action adjust_first_ad(param1, param2) {
    modify_field(hdr.x1, param1);
    modify_field(hdr.x2, param2);
}

table adjust1 {
    reads {
        hdr.f2 : exact;
    }
    actions {
        adjust_first;
        adjust_first_ad;
    }
}

action adjust_second() {
    modify_field(hdr.x3, hdr.x1);
    modify_field(hdr.x4, hdr.x2);
}

table adjust2 {
    reads {
        hdr.f3 : exact;
    }
    actions {
        adjust_second;
    }
}

action setport(port) {
    modify_field(standard_metadata.egress_spec, port);
}

table setting_port {
    actions {
        setport;
    }
    default_action: setport(1);
}

control ingress {
    apply(offset);
    apply(adjust1);
    apply(adjust2);
    apply(setting_port);
}
