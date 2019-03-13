/* Another ghost test that combines unaligned bits and normal bytes to make sure that ghosting
   can ghost both normal bytes and non-aligned bytes.  Essentially n2 must be guaranteed to be
   ghosted, and sees if the other pieces are ghosted correctly.
*/

header_type data_t {
    fields {
        b1 : 8;
        b2 : 8;
        b3 : 8;
        n1 : 12;
        n2 : 4;
        b_out : 8;
    }
}

header data_t data;

parser start {
    extract(data);
    return ingress;
}

action noop() {}
action setb_out(val, port) {
    modify_field(data.b_out, val);
    modify_field(standard_metadata.egress_spec, port);
}

table test1 {
    reads {
        data.b1 : exact;
        data.b2 : exact;
        data.b3 : exact;
        data.n2 : exact;
    }
    actions {
        setb_out;
        noop;
    }
    size : 16384;
}

control ingress {
    apply(test1);
}
