/* -*- P4_14 -*- */

header_type my_md_t {
    fields {
        a: 16 (signed);
    }
}
metadata my_md_t my_md;

parser start {
    return parse_ethernet;
}

parser parse_ethernet {
    set_metadata(my_md.a, 0xf123);
    return ingress;
}

action set_qid() { }

table select_q {
    reads {
        my_md.a mask 0x8000 : exact;
    }
    actions { set_qid; }
    default_action: set_qid();
    size : 2;
}

control ingress {
    apply(select_q);
}
