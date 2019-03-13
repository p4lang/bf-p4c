/** The purpose of this test is to test if the instructions interacting with the fields
 *  contained in multiple containers are at all possible to interact with each other, and
 *  test whether a part of a container can be adjusted.  Specifically this looks at an 8 bit
 *  container case.
 */
header_type hdr_t {
    fields {
        f1 : 32;
        f2 : 32;
        f3 : 32;
        f4 : 32;
        n1 : 4;
        hn1 : 2;
        hn2 : 2;
        n2 : 4;
        hn3 : 2;
        hn4 : 2;
    }
}

header hdr_t hdr;

header_type nibble_meta_t {
    fields {
        hn1 : 2;
        hn2 : 2;
        n1 : 4;
    }
}

metadata nibble_meta_t nibble_meta;

parser start {
    extract(hdr);
    return ingress; 
}

action set_fields(big_field, half_nibble1, half_nibble2) {
    hdr.f4 = big_field;
    hdr.hn1 = half_nibble1;
    hdr.hn2 = half_nibble2;
}

action set_nibble_meta() {
    nibble_meta.hn1 = hdr.hn1;
    nibble_meta.hn2 = hdr.hn2;
}

action back_to_hdr() {
    hdr.hn2 = nibble_meta.hn1;
    hdr.hn4 = nibble_meta.hn2;
}

table set_all {
    reads {
        hdr.f1 : exact;
    }
    actions {
        set_fields;
    }
}

table set_nibbles {
    reads {
        hdr.f2 : exact;
    }
    actions {
        set_nibble_meta;
    }
}

table set_back {
    reads {
        hdr.f3 : exact;
    }
    actions {
        back_to_hdr;
    }
}

control ingress {
    apply(set_all);
    apply(set_nibbles);
    apply(set_back);
}
