
header_type ethernet_t {
    fields {
        dstAddr : 48;
        srcAddr : 48;
        etherType : 16;
    }
}

header_type meta_t {
    fields {
        a : 16;
    }
}

header ethernet_t ethernet;
metadata meta_t meta;

parser start {
   return parse_ethernet;
}

parser parse_ethernet {
   extract(ethernet);
   return ingress;
}

action do_nothing(){ }

action action_0(p){
    //modify_field(ethernet.etherType, ethernet.valid);
    //add(ethernet.etherType, ethernet.valid, 1);
}

table table_0 {
    reads {
        ethernet.valid mask 0x1: ternary;
        /* meta.valid : ternary; */
        ethernet : valid;
        ethernet.valid : exact;
        ethernet.etherType : exact;
    }
    actions {
        action_0;
        do_nothing;
    }
    size : 512;
}

control ingress {
    if (valid(ethernet)){
    //if (ethernet.valid == 1){
    apply(table_0);
    }
}