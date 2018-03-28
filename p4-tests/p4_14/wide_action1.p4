// #include "tofino/instrinsic_metadata.p4"

header_type h_t {
    fields {
        read : 32;
        f1 : 32;
        f2 : 32;
        f3 : 32;
        f4 : 32;
        f5 : 32;
        f6 : 32;
    }
}

header h_t h;

parser start {
    extract(h);
    return ingress;
}

action set_wide_action(param1, param2, param3, param4, param5, param6, port) {
    modify_field(h.f1, param1);
    modify_field(h.f2, param2);
    modify_field(h.f3, param3);
    modify_field(h.f4, param4);
    modify_field(h.f5, param5);
    modify_field(h.f6, param6);
    modify_field(standard_metadata.egress_spec, port);
}


table t {
    reads { h.read : ternary; }
    actions { set_wide_action; }
    size : 7168;
}

control ingress {
    apply(t);
}

