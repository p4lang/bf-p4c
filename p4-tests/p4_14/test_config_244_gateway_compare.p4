header_type hdr0_t {
    fields {
        a : 16;
        b : 8;
        c : 8;
    }
}

header_type meta_t {
    fields {
       w : 16;
       x : 16;
       y : 16;
       z : 16;
       a : 2;
       b : 4;
       c : 2;
       d : 8;
    }
}

header hdr0_t hdr0;
metadata meta_t meta;


parser start {
   return p_hdr0;
}

parser p_hdr0 {
   extract(hdr0);
   return ingress;
}

action do_nothing(){}
action action_0(p){
   modify_field(meta.w, 1);
   modify_field(meta.x, 2);
   modify_field(meta.a, 1);
   modify_field(meta.b, 15);
   modify_field(meta.c, 3);
   modify_field(meta.d, p);
}
action action_1(p){
   add(meta.y, meta.w, meta.x);
   bit_xor(meta.z, meta.w, meta.x);
}
action action_2(p){
   modify_field(hdr0.a, meta.z);
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
        hdr0.a : ternary;
    }
    actions {
        do_nothing;
        action_1;
    }
    size : 1024;
}

table table_i2 {
    reads {
        meta.y : ternary;
        meta.z : exact;
    }
    actions {
        do_nothing;
        action_2;
    }
    size : 512;
}

control ingress {
  if (hdr0.valid == 1 or valid(hdr0)){
  //if (hdr0.valid == 1 or hdr0.valid == 1){
      apply(table_i0);
  }

  if (meta.a == meta.c){
      apply(table_i1);
  }

  if (meta.c == 0){
      apply(table_i2);
  }
}

control egress {
}