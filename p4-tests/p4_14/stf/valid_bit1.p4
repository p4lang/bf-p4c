header_type data_t {
    fields {
        f1 : 32;
        f2 : 32;
        more : 8;
        _pad : 7;
        flag : 1;
    }
}
header_type extra_t {
    fields {
        f3 : 32;
        f4 : 32;
        b3 : 8;
        b4 : 8;
    }
}
header data_t data;
header extra_t extra;

parser start {
    extract(data);
    return select(data.more) {
        0: ingress;
        default: parse_extra;
    }
}
parser parse_extra {
    extract(extra);
    return ingress;
}

action noop() { }
action setflag(port) {
    modify_field(data.flag, extra.valid);
    modify_field(standard_metadata.egress_spec, port);
}

table test1 {
    reads { data.f1 : exact; }
    actions {
        setflag;
        noop;
    }
}

control ingress {
    apply(test1);
}
