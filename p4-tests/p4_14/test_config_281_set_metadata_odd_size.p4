// #include "tofino/intrinsic_metadata.p4"

header_type hdr0_t {
    fields {
        pre : 1;
        a : 3;
        b : 12;
        c : 32;
        d : 16;
    }
}

header_type meta_t {
   fields {
        a : 3;
   }
}

@pragma pa_container_size ingress hdr0.a 16
header hdr0_t hdr0;
header hdr0_t hdr1;

@pragma pa_container_size ingress meta.a 16
metadata meta_t meta;

parser start {
   return p_hdr0;
}

parser p_hdr0 {
   extract(hdr0);
   set_metadata(meta.a, latest.a);
   return p_hdr1;
}

parser p_hdr1 {
   extract(hdr1);
   return ingress;
}
   
action do_nothing(){}

action action_0() {
   modify_field(hdr0.c, 1);
}

table table_i0 {
    reads {
        hdr0.a : ternary;
        meta.a : exact;
    }
    actions {
        do_nothing;
        action_0;
    }
    size : 512;
}

control ingress {
    apply(table_i0);
}