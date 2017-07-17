#include "tofino/intrinsic_metadata.p4"

/* Sample P4 program */
header_type one_t {
    fields {
        x : 8;
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

action action_0(p){
    modify_field(one.x, p);
}

action do_nothing(){}

table table_0 {
   reads {
     one.x mask 0x81 : exact;
   }       
   actions {
     action_0;
   }
   default_action: action_0(5);
   size : 4;

}


/* Main control flow */

control ingress {
    apply(table_0);
}
