header_type data_t {
    fields {
        h1 : 16;
        f1 : 64;
    }
}

header_type meta_t {
    fields { 
        f1 : 64;
    }
}

header data_t data;
metadata meta_t meta;

parser start {
    extract(data);
    return select(data.h1)  {
        0xc0de : parse_metadata;
        default : ingress;
    }
}

parser parse_metadata {
    set_metadata(meta.f1, 0xbabedead);
    return ingress;
}

action noop() { }
action setf1(port) {
    modify_field(data.f1, meta.f1);
    modify_field(standard_metadata.egress_spec, port);
}

table test1 {
    reads {
        data.h1 : exact;
    }
    actions {
        setf1;
        noop;
    }
}

control ingress { apply(test1); }
