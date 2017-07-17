#include "tofino/intrinsic_metadata.p4"

/* Sample P4 program */
header_type hdr1_t {
    fields {
        a_8 : 8;
        b_8 : 8;
        c_8 : 8;
        d_8 : 8;
    }
}

header_type meta_t {
    fields {
        x_8 : 8;
        y_8 : 8;
    }
}

parser start {
    return parse_pkt;
}


parser parse_pkt {
    extract(hdr1);
    set_metadata(meta.x_8, hdr1.a_8);
    return ingress;
}


header hdr1_t hdr1;
metadata meta_t meta;

action do_nothing(){}
action a0(x){ modify_field(meta.x_8, x); }
action a1(a){ modify_field(hdr1.a_8, a); }
action a2(b){ modify_field(hdr1.b_8, b); }
action a3(c){ modify_field(hdr1.c_8, c); }
action a4(y){ modify_field(meta.y_8, y); }
action a5(a){ modify_field(hdr1.a_8, a); }
action a6(b){ modify_field(hdr1.b_8, b); }
action a7(d){ modify_field(hdr1.d_8, d); }


table t0 {
    reads { meta.x_8 : ternary; }
    actions {
         a0;
         do_nothing;
    }
    size : 256;
}

table t1 {
    reads { meta.x_8 : ternary; }
    actions {
         a1;
         do_nothing;
    }
    size : 256;
}

table t2 {
    reads { meta.x_8 : ternary; }
    actions {
         a2;
         do_nothing;
    }
    size : 256;
}

table t3 {
    reads { 
         hdr1.a_8 : ternary; 
         hdr1.b_8 : ternary; 
    }
    actions {
         a3;
         do_nothing;
    }
    size : 256;
}

table t4 {
    reads { 
         hdr1.a_8 : ternary; 
         hdr1.b_8 : ternary; 
    }
    actions {
         a4;
         do_nothing;
    }
    size : 256;
}


table t5 {
    reads { meta.y_8 : ternary; }
    actions {
         a5;
         do_nothing;
    }
    size : 256;
}

table t6 {
    reads { 
         meta.y_8 : ternary; 
         hdr1.c_8 : ternary;
     }
    actions {
         a6;
         do_nothing;
    }
    size : 256;
}

table t7 {
    reads { 
         meta.y_8 : ternary; 
         hdr1.a_8 : ternary;
     }
    actions {
         a7;
         do_nothing;
    }
    size : 256;
}

control ingress {
    apply(t0);
    if (hdr1.valid == 1){
        apply(t1);
        apply(t4);
        apply(t5);
    } else {
        apply(t2);
        apply(t3);
        apply(t6);
    }
    apply(t7);
}

control egress { }