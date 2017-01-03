// #include "tofino/intrinsic_metadata.p4"

header_type hdr0_t {
    fields {
        a : 8;
        b : 32;
//        c : 3;
//        d : 24;
    }
}

header_type meta_t {
   fields {
        a : 32;
        b : 8;
        c : 5;
        d : 3;
   }
}

@pragma pa_container_size ingress hdr0.b 32
header hdr0_t hdr0;

@pragma pa_container_size ingress meta.a 16
metadata meta_t meta;

parser start {
   return p_hdr0;
}

parser p_hdr0 {
   extract(hdr0);
   set_metadata(meta.c, 0);
   return ingress;
}
   
action do_nothing(){}

/*
action action_0(p){
    add(one.a, one.a, 1);
    add(meta.a, meta.a, p);
}
*/

table table_i0 {
    reads {
        hdr0.a : ternary;
        meta.c : exact;
    }
    actions {
        do_nothing;
    }
    size : 512;
}

control ingress {
    apply(table_i0);
}