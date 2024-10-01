/* This test is to see if the table format algorithm can appropriately allocate ghost bits and
   match bits on a byte by byte basis.  Essentially make sure that the ghost bits correctly
   coordinate
*/

header_type data_t {
    fields {
        b1 : 8;
        b2 : 8;
        b3 : 8;
        b4 : 8;
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
        data.b4 : exact;
    }
    actions {
        setb_out;
        noop;
    }
}

control ingress {
    apply(test1);
}
