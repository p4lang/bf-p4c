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
       e : 8;
       f : 8;
    }
}

header hdr0_t hdr0;
@pragma pa_mutually_exclusive ingress meta.e meta.f
metadata meta_t meta;


parser start {
   return p_hdr0;
}

parser p_hdr0 {
   extract(hdr0);
   set_metadata(meta.e, 0);
   set_metadata(meta.f, 2);
   return ingress;
}

action do_nothing(){}
action action_0(p){
   modify_field(meta.c, 3);
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
        meta.e : exact;
        meta.f : exact;
    }
    actions {
        do_nothing;
        action_2;
    }
    size : 512;
}

control ingress {
  if (hdr0.valid == 1){
      apply(table_i0);
  } else {
      apply(table_i1);
  }

  if (meta.c == 0){
      apply(table_i2);
  }
}

control egress {
}