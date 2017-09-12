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
header one_t two;

parser parse_one {
    extract(one);
    return parse_two;
}

parser parse_two {
    extract(two);
    return ingress;
}

action action_0(p){
    modify_field(one.x, p);
}

action action_1(p){
    modify_field(two.x, p);
}

action do_nothing(){}

table table_0 {
   reads {
     one.x : exact;
   }       
   actions {
     action_0;
   }
   default_action: action_0(5);
   size : 256;

}

table table_1 {
   reads {
     two.x : exact;
   }       
   actions {
     action_1;
   }
   default_action: action_1(7);
   size : 256;

}


/* Main control flow */

control ingress {
    if (valid(one) and valid(two)){
        apply(table_0);
    }

    if (one.valid == 1 and two.valid == 1){
        apply(table_1);
    }

}
