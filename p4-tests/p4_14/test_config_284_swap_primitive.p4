header_type ethernet_t {
    fields {
        dstAddr : 48;
        srcAddr : 48;
        etherType : 16;
    }
}

parser start {
    return parse_ethernet;
}

parser parse_ethernet {
    extract(ethernet);
    return ingress;
}

header ethernet_t ethernet;


action do_nothing(){}

action action_0(ap){
    swap(ethernet.dstAddr, ethernet.srcAddr);
}

table table_0 {
    reads {
        ethernet.etherType : ternary;
    }
    actions {
        do_nothing;
        action_0;
    }
}

control ingress {
    apply(table_0);
}