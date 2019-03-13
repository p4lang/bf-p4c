header_type eth_t {
    fields {
        type : 16;
        foo : 32;
    }
}
header_type v4_t {
    fields {
        foo : 32;
    }
}
header_type v6_t {
    fields {
        foo : 32;
    }
}
header eth_t eth;
header v4_t v4;
header v6_t v6;
parser start {
    extract(eth);
    return select(latest.type) {
        0x8080 : parse_v4;
        0x5050 : parse_v6;
        default : ingress;
    }
}
parser parse_v4 {
    extract(v4);
    return ingress;
}
parser parse_v6 {
    extract(v6);
    return ingress;
}
action noop() { }
action set_port() {
    standard_metadata.egress_spec = 0x2;
}
table test1 {
    reads {
        eth.foo : exact;
    }
    actions {
        set_port;
        noop;
    }
    default_action : noop;
}
action rewrite_eth() {
    modify_field(eth.foo, 0x03030303);
}
table test2 {
    reads {
        v4.foo : ternary;
        v6.foo : ternary;
        v4 : valid;
        v6 : valid;
    }
    actions {
        rewrite_eth;
        noop;
    }
    default_action : noop;
    size : 1024;
}
control ingress {
    apply(test1);
}
control egress {
    apply(test2);
}
