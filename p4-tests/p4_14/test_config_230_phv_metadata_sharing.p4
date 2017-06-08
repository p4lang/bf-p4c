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
        a_8 : 8;
        b_2 : 2;
        c_2 : 2;
        d_4 : 4;
   }
}

@pragma pa_container_size ingress hdr0.b 8
header hdr0_t hdr0;
header hdr1_t hdr1;
header hdr2_t hdr2;

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
   return p_hdr2;
}

parser p_hdr2 {
   extract(hdr2);
   return ingress;
}
   
action do_nothing(){}

action action_0() {
   modify_field(meta.a_8, 255);
   modify_field(meta.b_2, 1);
   modify_field(meta.c_2, 3);
   modify_field(meta.d_4, 15);
}

action action_1(){
   modify_field(hdr2.c, meta.a_8);
}

table table_i0 {
    reads {
        hdr0.a : ternary;
    }
    actions {
        do_nothing;
        action_0;
    }
    size : 512;
}

table table_i1 {
    reads {
        meta.a_8 : ternary;
        meta.b_2 : exact;
        meta.c_2 : exact;
        meta.d_4 : exact;
    }
    actions {
        do_nothing;
        action_1;
    }
    size : 512;
}

control ingress {
    apply(table_i0);
    apply(table_i1);
}