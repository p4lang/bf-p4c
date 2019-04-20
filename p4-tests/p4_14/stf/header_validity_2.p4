header_type data_t {
    fields {
        f : 16;
        p : 16;
        q : 16;
        d : 16;
    }
}

header data_t foo;
header data_t bar;

parser start {
    set_metadata(standard_metadata.egress_spec, 0x2);
    extract(foo);
    return select(latest.d) {
        0xdead  : parse_bar;
        default : ingress;
    }
}

parser parse_bar {
    extract(bar);
    return ingress;
}

action noop() { }
action add_bar() { add_header(bar); }

table t1 {
    reads { foo.f : exact; }
    actions {
        add_bar;
        noop;
    }
}

control ingress {
    apply(t1);
}
