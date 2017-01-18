// #include "tofino/intrinsic_metadata.p4"

header_type hdr0_t {
    fields {
        a : 16;
        b : 8;
        c : 8;
    }
}

header_type meta_t {
   fields {
      a : 8;  // must be elminated
      w : 8;  // can be eliminated since not referenced
      x : 8;  // cannot be eliminated because used by stateful op
      y : 8;  // must be elminated
      z : 8;  // must be elminated
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

action do_nothing(){ }

action action_0(){
    modify_field(meta.y, 1);
}

action action_1(){
    modify_field(meta.z, 0);
}

action action_2(){
    modify_field(hdr0.a, 1);
    modify_field(meta.a, 0);
}

meter meter_0 {
    type : packets;
    direct : table_0;
    result : meta.x;
}

table table_0 {
    reads {
        hdr0.a : ternary;
    }
    actions {
        action_0;
        action_1;
    }
    size : 512;
}

table table_1 {
    reads {
        hdr0.a : ternary;
    }
    actions {
        action_2;
        do_nothing;
    }
    size : 512;
}

control ingress {
    apply(table_0);
    if (valid(hdr0)){
    apply(table_1); // should be eliminated
    }
}