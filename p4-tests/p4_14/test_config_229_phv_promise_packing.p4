// #include "tofino/intrinsic_metadata.p4"

header_type hdr0_t {
    fields {
        a : 16;
        b : 8;
        c : 8;
    }
}

header_type hdr1_t {
    fields {
        a : 16;
        b : 8;
        c : 8;
   }
}

header_type hdr2_t {
    fields {
        a : 16;
        b : 8;
        c : 8;
   }
}

header_type meta_t {
   fields {
        a : 16;
   }
}

@pragma pa_container_size ingress hdr0.a 32
header hdr0_t hdr0;
header hdr1_t hdr1;
@pragma pa_container_size ingress hdr2.c 32
header hdr2_t hdr2;

//@pragma pa_container_size ingress meta.a 16
metadata meta_t meta;

parser start {
   return p_hdr0;
}

parser p_hdr0 {
   extract(hdr0);
   return p_hdr1;
}

parser p_hdr1 {
   extract(hdr1);
   set_metadata(meta.a, latest.a);
   return p_hdr2;
}

parser p_hdr2 {
   extract(hdr2);
   return ingress;
}
   
action do_nothing(){}

action action_0() {
   modify_field(hdr0.a, hdr2.a);
   modify_field(hdr2.c, hdr1.c);
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