// #include "tofino/intrinsic_metadata.p4"

header_type one_byte_t {
    fields {
        a : 8;
    }
}

header_type hdr_stack_t {
   fields {
        a : 8;
        b : 8;
        c : 16;
        d : 32;
   }
}


header one_byte_t one;
header hdr_stack_t hdr_stack_[3];

parser start {
   return oneb;
}

parser oneb {
   extract(one);
   return stck;
}

parser stck {
   extract(hdr_stack_[next]);
   return select(latest.b) {
       0 : stck;
       1 : ingress;
       default : ingress;
   }
}

action do_nothing(){}

action action_0(){
    add(one.a, one.a, 1);
}

action push_3(){ push(hdr_stack_, 3); }
action push_2(){ push(hdr_stack_, 2); }
action pop_2(){ pop(hdr_stack_, 2); }
action pop_1(){ pop(hdr_stack_, 1); }

table table_i0 {
    reads {
        one.a : ternary;
    }
    actions {
        do_nothing;
        action_0;
        push_3;
        push_2;
        pop_2;
        pop_1;
    }
    size : 512;
}

control ingress {
    apply(table_i0);
}