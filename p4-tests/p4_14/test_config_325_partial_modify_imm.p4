#include "tofino/intrinsic_metadata.p4"

/* Sample P4 program */
header_type one_t {
    fields {
        x : 6;
        y : 2;
    }
}

parser start {
    return parse_one;
}

header one_t one;

parser parse_one {
    extract(one);
    return ingress;
}

action action_0(){
    modify_field(one.x, 0x3f);
}

action do_nothing(){}

table table_0 {
   reads {
     one.x : exact;
     one.y : exact;
   }       
   actions {
     action_0;
     do_nothing;
   }
   size : 256;
}


/* Main control flow */

control ingress {
    apply(table_0);
}
