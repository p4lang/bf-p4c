/* A test to see whether if all bits in the match are not 8-bit fields that the ghosting works
   fairly well.  Essentially all n1, n2, and n3 should be ghosted, and one of those should
   be only partially ghosted.
*/

header_type data_t {
    fields {
        x1 : 2;
        n1 : 4;
        x2 : 2;
        x3 : 2;
        n2 : 4;
        x4 : 2;
        x5 : 2;
        n3 : 4;
        x6 : 2;
        b1 : 8;
        b2 : 8;
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
        data.n1 : exact;
        data.n2 : exact;
        data.n3 : exact;
        data.b1 : exact;
        data.b2 : exact;
    }
    actions {
        setb_out;
        noop;
    }
    //size : 16384;
}

control ingress {
    apply(test1);
}
