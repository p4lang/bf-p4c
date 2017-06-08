// #include "tofino/intrinsic_metadata.p4"

header_type one_byte_t {
    fields {
        a : 8;
    }
}

header one_byte_t one;

parser start {
   return oneb;
}

parser oneb {
   extract(one);
   return ingress;
}

action do_nothing(){}

action action_0(){
    add(one.a, one.a, 1);
}

table table_i0 {
    reads {
        one.a : ternary;
    }
    actions {
        //do_nothing;
        action_0;
    }
    size : 512;
}

control ingress {
    apply(table_i0);
}