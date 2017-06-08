// #include "tofino/intrinsic_metadata.p4"

header_type hdr0_t {
    fields {
        a : 16;
        b : 32;
        c : 16;
    }
}

header_type hdr1_t {
    fields {
        a : 16;
   }
}

header_type hdr2_t {
    fields {
        a : 32;
   }
}

header_type meta_t {
   fields {
        a : 16;
   }
}

//@pragma pa_container_size ingress hdr0.a 32
header hdr0_t hdr0;
//@pragma pa_container_size egress hdr1.a 32
header hdr1_t hdr1;
header hdr2_t hdr2;

//@pragma pa_container_size ingress meta.a 16
metadata meta_t meta;

parser start {
   return p_hdr0;
}

parser p_hdr0 {
   extract(hdr0);
   return select (hdr0.a) {
       0 : p_hdr1;
       default : p_hdr2;
   }
}

parser p_hdr1 {
   extract(hdr1);
   set_metadata(meta.a, latest.a);
   return ingress;
}

parser p_hdr2 {
   extract(hdr2);
   set_metadata(meta.a, latest.a);
   return ingress;
}
   
action do_nothing(){}

action action_0() {
   modify_field(hdr0.a, 1);
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