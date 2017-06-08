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
        tbl0_tbl1 : 16;
        tbl0_tbl2 : 16;
        tbl0_tbl3 : 16;

        tbl1_tbl2 : 16;
        tbl1_tbl3 : 16;

        tbl2_tbl3 : 16;

        tbl0 : 16;
        tbl1 : 16;
        tbl2 : 16;
        tbl3 : 16;
        tbl4 : 16;
   }
}

header hdr0_t hdr0;
header hdr1_t hdr1;
header hdr2_t hdr2;

metadata meta_t meta;

parser start {
   return p_hdr0;
}

parser p_hdr0 {
   extract(hdr0);
   return select(hdr0.c){
      0 : p_hdr1;
      1 : p_hdr2;
   }

   //return p_hdr1;
}

parser p_hdr1 {
   extract(hdr1);
   return p_hdr2;
}

parser p_hdr2 {
   extract(hdr2);
   return ingress;
}

counter cnt_0 {
   type: packets_and_bytes;
   static: table_i0;
   instance_count: 2048;
}

action do_nothing(){}

action action_0(idx) {
   modify_field(meta.tbl0_tbl1, 1);
   modify_field(meta.tbl0_tbl2, 1);
   modify_field(meta.tbl0_tbl3, 1);
   modify_field(meta.tbl0, 1);
   count(cnt_0, idx);
}

action action_1() {
   modify_field(meta.tbl0_tbl1, 1);
   modify_field(meta.tbl1_tbl2, 1);
   modify_field(meta.tbl1_tbl3, 1);
   modify_field(meta.tbl1, 1);
}

action action_2() {
   modify_field(meta.tbl0_tbl2, 1);
   modify_field(meta.tbl1_tbl2, 1);
   modify_field(meta.tbl2_tbl3, 1);
   modify_field(meta.tbl2, 1);
}

action action_3() {
   modify_field(meta.tbl0_tbl3, 1);
   modify_field(meta.tbl1_tbl3, 1);
   modify_field(meta.tbl2_tbl3, 1);
   modify_field(meta.tbl3, 1);
}

action action_4() {
   modify_field(meta.tbl4, 1);
}


table table_i0 {
    reads {
        hdr0.a : ternary;
        meta.tbl0 : exact;
    }
    actions {
        do_nothing;
        action_0;
    }
    size : 512;
}

table table_i1 {
    reads {
        hdr0.a : ternary;
        meta.tbl1 : exact;
        meta.tbl0_tbl1 : exact;
    }
    actions {
        do_nothing;
        action_1;
    }
    size : 512;
}

table table_i2 {
    reads {
        hdr0.a : ternary;
        meta.tbl2 : exact;
        meta.tbl0_tbl2 : exact;
        meta.tbl1_tbl2 : exact;
    }
    actions {
        do_nothing;
        action_2;
    }
    size : 512;
}

table table_i3 {
    reads {
        hdr0.a : ternary;
        meta.tbl3 : exact;
        meta.tbl0_tbl3 : exact;
        meta.tbl1_tbl3 : exact;
        meta.tbl2_tbl3 : exact;
    }
    actions {
        do_nothing;
        action_3;
    }
    size : 512;
}

table table_i4 {
    reads {
        hdr0.a : ternary;
        hdr1.b : exact;
        meta.tbl4 : exact;
    }
    actions {
        do_nothing;
        action_4;
    }
    size : 512;
}


control ingress {

    if (hdr0.c == 0){
    apply(table_i0);
    apply(table_i1);
    apply(table_i2);
    apply(table_i3);
    } else {
        apply(table_i4);
    }
}