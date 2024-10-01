@pragma command_line --decaf

header_type data_t {
    fields {
        k : 16;
        f : 16;
    }
}

header_type tag_t {
    fields {
        k : 16;
        f : 16;
    }
}

header data_t data;
header tag_t tag[3];

parser start {
    set_metadata(standard_metadata.egress_spec, 0x2);
    extract(data);
    return select(latest.f) {
        0x8100 : parse_tag;
        default : ingress;
    }
}

parser parse_tag {
    extract(tag[next]);
    return select(latest.f) {
        0x8100 : parse_tag;
        default : ingress;
    }
}

action push_tag() {
    push(tag, 1);
    modify_field(tag[0].f, data.f);
    modify_field(data.f, 0xbabe);    
}

table t1 {
    reads {
        data.k : exact;
    }
    actions{
    	push_tag;
    }
}

control ingress {
    apply(t1);
}
