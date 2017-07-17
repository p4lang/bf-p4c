#include "tofino/intrinsic_metadata.p4"

/* Sample P4 program */
header_type hdr1_t {
    fields {
        a_8 : 8;
        b_16 : 16;
        c_8 : 8;
        d_8 : 8;
    }
}

header_type meta_t {
    fields {
        x_8 : 8;
        y_8 : 8;
        z_8 : 8;
    }
}

parser start {
    return parse_pkt;
}


parser parse_pkt {
    extract(hdr1);
    set_metadata(meta.z_8, 3);
    return ingress;
}


header hdr1_t hdr1;

@pragma pa_mutually_exclusive ingress meta.x_8 meta.z_8
@pragma pa_container ingress meta.x_8 67
@pragma pa_container ingress meta.z_8 67
metadata meta_t meta;

action do_nothing(){}

action blah(x){
    modify_field(hdr1.d_8, x);
}

action a0(x){
    modify_field(meta.x_8, x);
}

action a1(){
    modify_field(hdr1.c_8, 2);
    drop();
}

action a2(x2){
    modify_field(meta.x_8, x2);
}

action inside(y){
    modify_field(hdr1.c_8, 1);
    modify_field(meta.y_8, y);
}


action a3(p, y){
    modify_field(hdr1.a_8, p);
    inside(10);
}

action a4(y2){
    modify_field(hdr1.a_8, 1);
    inside(20);
}

@pragma command_line --metadata-overlay True
table tm1 {
    reads {
         meta.z_8 : ternary;
    }
    actions {
         blah;
         do_nothing;
    }
    size : 256;
}

table t0 {
    reads {
         hdr1.a_8 : ternary;
         hdr1.d_8 : ternary;
    }
    actions {
         a0;
         do_nothing;
    }
    size : 256;
}

table t1 {
    reads {
         hdr1.b_16 : ternary;
    }
    actions {
         a1;
         do_nothing;
    }
    size : 512;
}

table t2 {
    reads {
         hdr1.c_8 : ternary;
    }
    actions {
         a2;
         do_nothing;
    }
    size : 512;
}

table t3 {
    reads {
         hdr1.d_8 : ternary;
         meta.x_8 : exact;
    }
    actions {
         a3;
         a4;
         do_nothing;
    }
    size : 512;
}

control ingress {
    apply(tm1);
    if (hdr1.valid == 1){
        apply(t0);
    } else {
        apply(t1);
    }
    apply(t2);
    apply(t3);
}

control egress { }