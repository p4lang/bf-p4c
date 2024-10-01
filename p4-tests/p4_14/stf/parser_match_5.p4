header_type data_t {
    fields {
        k : 8;
        m : 8;
    }
}

header data_t a;
header data_t b;
header data_t c;
header data_t d;

parser start {
    set_metadata(standard_metadata.egress_spec, 0x2);
    extract(a);
    return select(latest.m) {
        0xb : parse_b;
        0xc : parse_c;
    }
}

parser parse_b {
    extract(b);
    return parse_c;
}

parser parse_c {
    extract(c);
    return select(a.k) {
        0xd : parse_d;
        default : ingress;
    }
}

parser parse_d {
    extract(d);
    return ingress;
}

control ingress { }
