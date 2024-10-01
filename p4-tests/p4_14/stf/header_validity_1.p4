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
    extract(bar);
    return ingress; 
}

action noop() { }
action remove_foo() { remove_header(foo); bypass_egress(); }
action remove_bar() { remove_header(bar); bypass_egress(); }

table t1 {
    reads { foo.f : exact; }
    actions {
        remove_bar;
        noop;
    }
}

table t2 {
    reads { bar.f : exact; }
    actions {
        remove_foo;
        noop;
    }
}

control ingress {
    apply(t1);
    apply(t2);
}
