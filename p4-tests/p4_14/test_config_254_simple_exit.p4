#include "tofino/intrinsic_metadata.p4"

header_type ethernet_t {
    fields {
        dstAddr : 48;
        srcAddr : 48;
        etherType : 16;
    }
}

header ethernet_t ethernet;

parser start {
    return parse_ethernet;
}


parser parse_ethernet {
    extract(ethernet);
    return ingress;
}

action do_nothing(){}

action action_0(){
   exit();
}

action action_1(){
   drop();
}

table table_0 {
    reads {
        ethernet.dstAddr: exact;
    }
    actions {
        action_0;
        action_1;
        do_nothing;
    }
    size : 1024;
}

table table_1 {
    reads { 
       ethernet.dstAddr: exact;
    }
    actions {
       action_1;
       do_nothing;
    }
}

table table_2 {
    reads { 
       ethernet.dstAddr: exact;
    }
    actions {
       action_1;
       do_nothing;  
    }
}

control ingress {
    apply(table_0); 
    apply(table_1);
    apply(table_2);
}